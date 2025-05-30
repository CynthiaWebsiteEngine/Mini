// IMPORTS ---------------------------------------------------------------------

import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages.{
  type Msg, ApiReturnedData, UserNavigateTo,
}
import cynthia_websites_mini_client/model_type.{type Model, Model}
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_client/view
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/configurable_variables
import cynthia_websites_mini_shared/contenttypes
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import houdini
import lustre
import lustre/effect.{type Effect}
import modem
import odysseus
import plinth/browser/window
import plinth/javascript/console
import plinth/javascript/global
import plinth/javascript/storage
import rsvp

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view.main)
  let assert Ok(_) = lustre.start(app, "#viewable", Nil)

  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  console.log("Cynthia Client starting up")
  let effects =
    effect.batch([fetch_all(ApiReturnedData), modem.init(on_url_change)])
  // Using local storage as session storage because session storage doesn't stay long enough
  let assert Ok(session) = storage.local()
  // .. if the local storage is older than 15 minutes though, we clear it
  let val = case storage.get_item(session, "time") {
    Ok(time) -> {
      let now = utils.now()
      let stamp = result.unwrap(int.parse(time), 0)
      let diff = int.subtract(now, stamp) |> int.absolute_value
      let order = int.compare(diff, 900)
      case order {
        order.Eq | order.Gt -> False
        order.Lt -> True
      }
    }
    Error(..) -> {
      False
    }
  }
  case val {
    False -> {
      console.log("Clearing local storage")
      storage.clear(session)
    }
    True -> {
      // Keeping local storage, updating time
      let now = utils.now() |> int.to_string
      case storage.set_item(session, "time", now) {
        Ok(_) -> {
          console.log("Updated local storage time")
        }
        Error(e) -> {
          console.error(
            "Error updating local storage time: " <> string.inspect(e),
          )
        }
      }
    }
  }
  let initial_path = case storage.get_item(session, "last"), window.get_hash() {
    Ok(path), _ -> {
      // We have a last path in local storage. Return it. Hash will be set to it later.
      path
    }
    Error(..), Ok("") | Error(..), Error(..) -> {
      // No last path in local storage, so we set the hash to "/"
      dom.set_hash("/")
      let assert Ok(..) = storage.set_item(session, "last", "/")

      "/"
    }
    Error(..), Ok(f) -> {
      // From the hash, we set the last path in local storage
      let assert Ok(..) = storage.set_item(session, "last", f)
      // and return the hash
      f
    }
  }
  console.log("Initial path: " <> initial_path)
  let model =
    Model(initial_path, None, dict.new(), Ok(Nil), dict.new(), session)

  #(model, effects)
}

// Effect handlers --------------------------------------------------------------
/// On url change: (Obviously) is triggered on url change, this is useful for intercepting the url hash change on in-site-navigation, that Cynthia uses.
fn on_url_change(uri: Uri) -> Msg {
  console.log("URL changed to: " <> uri.to_string(uri))
  let assert Ok(#(_, d)) =
    uri
    |> uri.to_string
    |> string.split_once("#")
  messages.UserNavigateTo(d)
}

/// Fetches data from server side
fn fetch_all(
  on_response handle_response: fn(Result(configtype.CompleteData, rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = utils.phone_home_url() <> "site.json"
  let decoder = configtype.complete_data_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  console.log("Fetching site.json...")
  rsvp.get(url, handler)
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  // Update session storage with the current time
  let now = utils.now() |> int.to_string
  case storage.set_item(model.sessionstore, "time", now) {
    Ok(_) -> {
      Nil
    }
    Error(e) -> {
      console.error(
        "Error updating session storage time: " <> string.inspect(e),
      )
    }
  }
  case msg {
    UserNavigateTo(path) -> {
      dom.set_hash(path)
      let other =
        model.other
        |> dict.delete("search_term")
      case storage.set_item(model.sessionstore, "last", path) {
        Ok(_) -> {
          console.log("Stored last path: " <> path)
        }
        Error(e) -> {
          console.error("Error storing last path: " <> string.inspect(e))
        }
      }
      pottery.destroy_comment_box()
      #(Model(..model, path:, other:), effect.none())
    }
    messages.UserSearchTerm(search_term) -> {
      let path = "!/search/" <> search_term
      let computed_menus = model.computed_menus
      let complete_data = model.complete_data
      let status = model.status
      let other =
        model.other
        |> dict.insert("search_term", dynamic.from(search_term))
      dom.set_hash(path)
      let sessionstore = model.sessionstore
      #(
        Model(
          path:,
          complete_data:,
          computed_menus:,
          status:,
          other:,
          sessionstore:,
        ),
        effect.none(),
      )
    }
    ApiReturnedData(data) -> {
      case data {
        Error(e) -> {
          let error_message =
            "Cynthia Client failed "
            <> case e {
              rsvp.UnhandledResponse(s) ->
                "to handle the server's response: '" <> string.inspect(s) <> "'"
              rsvp.HttpError(_) | rsvp.NetworkError -> "to connect to server."
              rsvp.JsonError(s) ->
                "to decode response: '" <> string.inspect(s) <> "'"
              _ -> " to load this site."
            }
          #(Model(..model, status: Error(error_message)), effect.none())
        }
        Ok(new) -> {
          console.log("Succesfully decoded new data, parsing into model...")
          case new.comment_repo {
            Some(..) ->
              global.set_interval(300, pottery.comment_box_forced_styles)
            None -> global.set_timeout(30_000, fn() { Nil })
          }
          let computed_menus = compute_menus(new.content, model)
          case convert_configurable(new.other_vars) {
            Ok(dict_of_configurables) -> {
              console.log("Succesfully unjsonified configurable variables.")
              // I thought this was already done, but I see what is going on here, still gonna commit. This _should_ be a dynamic, not a fucken string.
              let other = dict.merge(model.other, dict_of_configurables)
              let status = Ok(Nil)
              let complete_data =
                Some(configtype.CompleteData(..new, other_vars: []))
              console.log("Updated model.")
              #(
                Model(..model, complete_data:, computed_menus:, status:, other:),
                effect.none(),
              )
            }
            Error(mess) -> {
              #(Model(..model, status: Error(mess)), effect.none())
            }
          }
        }
      }
    }
    // This also shows pretty well how to store booleans in the model.other dict: Use results.
    messages.UserOnGitHubLayoutToggleMenu -> {
      let other = case dict.get(model.other, "github-layout menu open") {
        Ok(..) -> {
          // is open, so close it
          dict.delete(model.other, "github-layout menu open")
        }
        Error(..) -> {
          // is closed, so open it
          dict.insert(
            model.other,
            "github-layout menu open",
            dynamic.from(None),
          )
        }
      }
      #(Model(..model, other:), effect.none())
    }
    messages.CindyToggleMenu1 -> {
      let other = case dict.get(model.other, "cindy menu  1 open") {
        Ok(..) -> {
          // is open, so close it
          dict.delete(model.other, "cindy menu  1 open")
        }
        Error(..) -> {
          // is closed, so open it
          dict.insert(model.other, "cindy menu  1 open", dynamic.from(None))
        }
      }
      #(Model(..model, other:), effect.none())
    }
    messages.UserOnDocumentationLayoutToggleSidebar -> {
      let other = case dict.get(model.other, "documentation-sidebar-open") {
        Ok(..) -> {
          // is open, so close it
          dict.delete(model.other, "documentation-sidebar-open")
        }
        Error(..) -> {
          // is closed, so open it
          dict.insert(
            model.other,
            "documentation-sidebar-open",
            dynamic.from(None),
          )
        }
      }
      #(Model(..model, other:), effect.none())
    }
  }
}

/// -----------------------------------------------------------------------------------------
/// Helper function to convert configurable variables into `Result(Dict(String,Dynamic))`'s,
/// allowing usage in `model.other`
/// -----------------------------------------------------------------------------------------
fn convert_configurable(from: List(#(String, List(String)))) {
  let defined = configurable_variables.typecontrolled
  let res =
    result.all(
      list.map(from, fn(item) {
        let #(keyname, probable_value): #(String, List(String)) = item
        use found_type <- result.try(
          list.last(probable_value)
          |> result.replace_error(
            "Invalid value at "
            <> keyname
            <> ", something might have gone wrong encoding this value at the server side.",
          ),
        )
        let defined_type = case list.key_find(defined, keyname) {
          Ok(m) -> m
          Error(_) -> found_type
        }
        // Check if a convertible is found
        let might_rewrite_the_story: Result(#(String, List(String)), String) = case
          bool.or(
            bool.and(
              bool.or(
                defined_type == configurable_variables.var_bitstring,
                defined_type == configurable_variables.var_string,
              ),
              bool.or(
                defined_type == configurable_variables.var_bitstring,
                defined_type == configurable_variables.var_string,
              ),
            ),
            bool.and(
              bool.or(
                defined_type == configurable_variables.var_int,
                defined_type == configurable_variables.var_float,
              ),
              bool.or(
                defined_type == configurable_variables.var_int,
                defined_type == configurable_variables.var_float,
              ),
            ),
          ),
          found_type,
          defined_type,
          probable_value
        {
          False, _, _, _ -> {
            // Type is not found to be convertible, return as-is
            Ok(#(found_type, probable_value))
          }
          _, "integer", "float", [intstr, ..] -> {
            use in <- result.try(result.replace_error(
              int.parse(intstr),
              "Could not parse number in " <> keyname,
            ))
            let flstr = in |> int.to_float |> float.to_string
            Ok(#("float", [flstr, "float"]))
          }
          _, "float", "integer", [flstr, ..] -> {
            // This is a convertible something, and the conversion required is from float to integer, we can just do that.
            use fl <- result.try(result.replace_error(
              float.parse(flstr),
              "Could not parse number in " <> keyname,
            ))
            let in = int.to_string(float.truncate(fl))
            Ok(#("integer", [in, "integer"]))
          }
          _, "string", "bits", [text, ..] -> {
            // This is a convertible something, and the conversion required is from string to bitstring, we can just do that.
            Ok(
              #(configurable_variables.var_bitstring, [
                bit_array.base64_encode(bit_array.from_string(text), True),
                configurable_variables.var_bitstring,
              ]),
            )
          }

          _, "bits", "string", [bits64base, ..] -> {
            // This is a convertible something, and the conversion required is from bitstring to string, we can do that if the bitstring is correct.
            use bits <- result.try(result.replace_error(
              bit_array.base64_decode(bits64base),
              "Failed to decode base64 to bitstring for " <> keyname,
            ))
            use str <- result.try(result.replace_error(
              bit_array.to_string(bits),
              "Failed to convert bitstring to string for " <> keyname,
            ))
            Ok(
              #(configurable_variables.var_string, [
                str,
                configurable_variables.var_string,
              ]),
            )
          }
          // For the other kinds, we don't know how to convert, so again, return as-is
          // We won't realistically reach here.
          _, _, _, _ -> Ok(#(found_type, probable_value))
        }

        use might_rewrite_the_story <- result.try(might_rewrite_the_story)
        // and this is why it _might_ rewrite the story
        let #(found_type, probable_value) = might_rewrite_the_story
        use <- bool.guard(
          { found_type != defined_type },
          Error(
            "Expected a "
            <> defined_type
            <> " at "
            <> keyname
            <> " but found a "
            <> found_type
            <> " instead!",
          ),
        )

        // Rename keynames
        let or_keyname = keyname
        let keyname = "config_" <> keyname

        case found_type, probable_value {
          "integer", [num, ..] -> {
            use integer <- result.try(result.replace_error(
              int.parse(num),
              "Could not parse number in " <> or_keyname,
            ))

            Ok(#(keyname, dynamic.from(integer)))
          }

          "float", [num, ..] -> {
            use number <- result.try(result.replace_error(
              float.parse(num),
              "Could not parse number in " <> or_keyname,
            ))

            Ok(#(keyname, dynamic.from(number)))
          }

          "boolean", [wether, ..] -> {
            let b = case wether {
              "True" -> Ok(True)
              "False" -> Ok(False)
              _ -> Error("Could not parse boolean value in " <> or_keyname)
            }
            use b <- result.try(b)
            Ok(#(keyname, dynamic.from(b)))
          }

          "bits", [base64, ..] -> {
            use bits <- result.try(result.replace_error(
              bit_array.base64_decode(base64),
              "Could not decode base64 in " <> or_keyname,
            ))
            Ok(#(keyname, dynamic.from(bits)))
          }

          "string", [text, ..] -> {
            // Strings or base64 strings are easiest, since they're verbatim
            Ok(#(keyname, dynamic.from(text)))
          }

          "datetime", values -> {
            todo
          }

          "date", values -> {
            todo
          }

          "time", values -> {
            use new_values <- result.try(result.replace_error(
              result.all(list.map(values, int.parse)),
              "Could not parse times in " <> or_keyname,
            ))
            case new_values {
              [hours, minutes, seconds, milis] -> {
                let c =
                  dynamic.from(model_type.Time(
                    hours:,
                    minutes:,
                    seconds:,
                    milis:,
                  ))
                Ok(#(keyname, c))
              }
              _ -> Error("Could not parse times in " <> or_keyname)
            }
          }
          _, _ ->
            Error("Could not decode configurable variable '" <> or_keyname)
        }
      }),
    )
  use res <- result.try(res)
  Ok(dict.from_list(res))
}

/// Helper function to compute menus --------------------------------------------------------
fn compute_menus(content: List(contenttypes.Content), model: Model) {
  let menu_s_available =
    content
    |> list.filter_map(fn(alls) {
      case alls.data {
        contenttypes.PageData(soms) -> Ok(soms)
        _ -> Error(Nil)
      }
    })
    |> list.flatten()
    |> list.unique()
    |> list.sort(int.compare)
  add_each_menu(menu_s_available, model.computed_menus, content)
}

// This is actually where the real magic happens
fn add_each_menu(
  next: List(Int),
  gotten: dict.Dict(Int, List(model_type.MenuItem)),
  items: List(contenttypes.Content),
) -> dict.Dict(Int, List(model_type.MenuItem)) {
  case next {
    [] -> gotten
    [current_menu, ..rest] -> {
      let hits: List(model_type.MenuItem) =
        list.filter_map(items, fn(item) -> Result(model_type.MenuItem, Nil) {
          case item.data {
            contenttypes.PageData(m) -> {
              case m |> list.contains(current_menu) {
                True -> {
                  Ok(model_type.MenuItem(name: item.title, to: item.permalink))
                }
                False -> Error(Nil)
              }
            }
            _ -> Error(Nil)
          }
        })
        |> list.sort(fn(itema, itemb) {
          let a = houdini.escape(utils.js_trim(odysseus.unescape(itema.name)))
          let b = houdini.escape(utils.js_trim(odysseus.unescape(itemb.name)))
          utils.compare_so_natural(a, b)
        })
      dict.insert(gotten, current_menu, hits)
      |> add_each_menu(rest, _, items)
    }
  }
}
