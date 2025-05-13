// I copied from the examples again to use as boilerplate... See https://github.com/lustre-labs/lustre/blob/main/examples/03-effects/01-http-requests/src/app.gleam for reference until nothing is recognisable.

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
import cynthia_websites_mini_shared/contenttypes
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/effect.{type Effect}
import plinth/browser/window
import plinth/javascript/console
import plinth/javascript/global
import plinth/javascript/storage

import modem
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

  // When we call `rsvp.get` that doesn't immediately make the request. Instead,
  // it returns an effect that we give to the runtime to handle for us.
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
        |> dict.insert("search_term", search_term)
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
          case new.comment_repo {
            Some(..) ->
              global.set_interval(300, pottery.comment_box_forced_styles)
            None -> global.set_timeout(30_000, fn() { Nil })
          }
          let computed_menus = compute_menus(new.content, model)
          let complete_data = Some(new)
          let status = Ok(Nil)

          #(
            Model(..model, complete_data:, computed_menus:, status:),
            effect.none(),
          )
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
          dict.insert(model.other, "github-layout menu open", "")
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
          dict.insert(model.other, "cindy menu  1 open", "")
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
          dict.insert(model.other, "documentation-sidebar-open", "")
        }
      }
      #(Model(..model, other:), effect.none())
    }
  }
}

// Helper function to compute menus --------------------------------------------------------
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
  rest: List(Int),
  gotten: dict.Dict(Int, List(model_type.MenuItem)),
  items: List(contenttypes.Content),
) -> dict.Dict(Int, List(model_type.MenuItem)) {
  case rest {
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
          utils.compare_so_natural(itema.name, itemb.name)
        })
      dict.insert(gotten, current_menu, hits)
      |> add_each_menu(rest, _, items)
    }
  }
}
