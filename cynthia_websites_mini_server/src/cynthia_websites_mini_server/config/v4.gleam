//// Cynthia v4 Config format

import bungibindies/bun
import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/configurable_variables
import cynthia_websites_mini_server/utils/files
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/fetch
import gleam/float
import gleam/http/request
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
import plinth/node/fs
import plinth/node/process
import simplifile
import tom

/// Parses the mini edition format for v4
pub fn parse_mini() -> Promise(
  Result(configtype.SharedCynthiaConfigGlobalOnly, String),
) {
  use str <- promise.try_await(
    fs.read_file_sync(files.path_normalize(process.cwd() <> "/cynthia.toml"))
    |> result.map_error(fn(e) {
      premixed.text_error_red("Error: Could not read cynthia.toml: " <> e)
      process.exit(1)
    })
    |> result.map_error(string.inspect)
    |> promise.resolve(),
  )
  use res <- promise.try_await(
    tom.parse(str) |> result.map_error(string.inspect) |> promise.resolve(),
  )

  use config <- promise.try_await(
    cynthia_config_global_only_exploiter(res)
    |> promise.map(result.map_error(_, string.inspect)),
  )
  promise.resolve(Ok(config))
}

type ConfigTomlDecodeError {
  TomlGetStringError(tom.GetError)
  TomlGetIntError(tom.GetError)
  FieldError(String)
}

fn cynthia_config_global_only_exploiter(
  o: dict.Dict(String, tom.Toml),
) -> Promise(
  Result(configtype.SharedCynthiaConfigGlobalOnly, ConfigTomlDecodeError),
) {
  use global_theme <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "theme"])
        |> result.replace_error(FieldError(
          "config->global.theme does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_theme_dark <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "theme_dark"])
        |> result.replace_error(FieldError(
          "config->global.theme_dark does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_colour <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "colour"])
        |> result.replace_error(FieldError(
          "config->global.colour does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_site_name <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "site_name"])
        |> result.replace_error(FieldError(
          "config->global.site_name does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_site_description <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "site_description"])
        |> result.replace_error(FieldError(
          "config->global.site_description does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  let server_port =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "port"])
        |> result.replace_error(FieldError("config->server.port does not exist")),
      )
      tom.as_int(field)
      |> result.map_error(TomlGetIntError)
    })
  let server_host =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "host"])
        |> result.replace_error(FieldError("config->server.host does not exist")),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    })
  let comment_repo = case
    tom.get(o, ["posts", "comment_repo"]) |> result.map(tom.as_string)
  {
    Ok(Ok(field)) -> {
      Some(field)
    }
    _ -> None
  }
  let git_integration = case
    tom.get(o, ["integrations", "git"]) |> result.map(tom.as_bool)
  {
    Ok(Ok(field)) -> {
      field
    }
    _ -> True
  }
  let sitemap = case
    tom.get(o, ["integrations", "sitemap"]) |> result.map(tom.as_string)
  {
    Ok(Ok(field)) -> {
      case string.lowercase(field) {
        "" -> None
        "false" -> None
        _ -> Some(field)
      }
    }
    _ -> None
  }
  let crawlable_context = case
    tom.get(o, ["integrations", "crawlable_context"]) |> result.map(tom.as_bool)
  {
    Ok(Ok(field)) -> {
      field
    }
    _ -> False
  }
  let other_vars = case result.map(tom.get(o, ["variables"]), tom.as_table) {
    Ok(Ok(d)) ->
      {
        dict.map_values(d, fn(key, unasserted_value) {
          let promise_of_a_somewhat_asserted_value = case unasserted_value {
            tom.InlineTable(inline) -> {
              case inline |> dict.to_list() {
                [#("url", tom.String(url))] -> {
                  let start = bun.nanoseconds()
                  console.log(
                    "Downloading external data ´"
                    <> premixed.text_blue(url)
                    <> "´...",
                  )

                  let assert Ok(req) = request.to(url)
                  use resp <- promise.await(
                    promise.map(fetch.send(req), fn(e) {
                      case e {
                        Ok(v) -> v
                        Error(_) -> {
                          console.error(
                            "There was an error while trying to download '"
                            <> url |> premixed.text_bright_yellow()
                            <> "' to a variable.",
                          )
                          process.exit(1)
                          panic as "We should not reach here."
                        }
                      }
                    }),
                  )
                  use resp <- promise.await(
                    promise.map(fetch.read_bytes_body(resp), fn(e) {
                      case e {
                        Ok(v) -> v
                        Error(_) -> {
                          console.error(
                            "There was an error while trying to download '"
                            <> url |> premixed.text_bright_yellow()
                            <> "' to a variable.",
                          )
                          process.exit(1)
                          panic as "We should not reach here."
                        }
                      }
                    }),
                  )
                  let end = bun.nanoseconds()
                  let duration_ms = { end -. start } /. 1_000_000.0
                  case resp.status {
                    200 -> {
                      console.log(
                        "Downloaded external content ´"
                        <> premixed.text_blue(url)
                        <> "´ in "
                        <> int.to_string(duration_ms |> float.truncate)
                        <> "ms!",
                      )
                      [
                        bit_array.base64_encode(resp.body, True),
                        configurable_variables.var_bitstring,
                      ]
                    }
                    _ -> {
                      console.error(
                        "There was an error while trying to download '"
                        <> url |> premixed.text_bright_yellow()
                        <> "' to a variable.",
                      )
                      process.exit(1)
                      panic as "We should not reach here."
                    }
                  }
                  |> promise.resolve()
                }
                [#("path", tom.String(path))] -> {
                  // let file = bun.file(path)
                  // use content <- promise.await(bunfile.text())
                  // `bunfile.text()` pretends it's infallible but is not. It should return a promised result.
                  //
                  // Also see: https://github.com/strawmelonjuice/bungibindies/issues/2
                  // Also missing: bunfile.bits(), but that is also because the bitarray and byte array transform is scary to me.
                  //
                  // For now, this means we continue using the sync simplifile.read_bits() function,
                  case simplifile.read_bits(path) {
                    Ok(bits) -> [
                      bit_array.base64_encode(bits, True),
                      configurable_variables.var_bitstring,
                    ]
                    Error(_) -> {
                      console.error(
                        "Unable to read file '"
                        <> path |> premixed.text_bright_yellow()
                        <> "' to variable.",
                      )
                      process.exit(1)
                      panic as "Should not reach here."
                    }
                  }
                  |> promise.resolve()
                }
                _ ->
                  [configurable_variables.var_unsupported]
                  |> promise.resolve()
              }
            }
            _ -> {
              case unasserted_value {
                tom.Bool(z) -> [
                  bool.to_string(z),
                  configurable_variables.var_boolean,
                ]
                tom.Date(date) -> [
                  date.year |> int.to_string,
                  date.month |> int.to_string,
                  date.day |> int.to_string,
                  configurable_variables.var_date,
                ]
                tom.DateTime(tom.DateTimeValue(date, time, offset)) -> {
                  case offset {
                    tom.Local -> [
                      int.to_string(date.year),
                      int.to_string(date.month),
                      int.to_string(date.day),
                      int.to_string(time.hour),
                      int.to_string(time.minute),
                      int.to_string(time.second),
                      int.to_string(time.millisecond),
                      configurable_variables.var_datetime,
                    ]
                    _ -> [configurable_variables.var_unsupported]
                  }
                }
                tom.Float(a) -> [
                  float.to_string(a),
                  configurable_variables.var_float,
                ]
                tom.Int(b) -> [int.to_string(b), configurable_variables.var_int]
                tom.String(guitar) -> [
                  guitar,
                  configurable_variables.var_string,
                ]
                tom.Time(time) -> [
                  int.to_string(time.hour),
                  int.to_string(time.minute),
                  int.to_string(time.second),
                  int.to_string(time.millisecond),
                  configurable_variables.var_time,
                ]
                _ -> [configurable_variables.var_unsupported]
              }
              |> promise.resolve()
            }
          }
          use reality <- promise.await(
            promise_of_a_somewhat_asserted_value
            |> promise.map(fn(somewhat_asserted_value) {
              let assert Ok(conclusion) = somewhat_asserted_value |> list.last()
                as "This must be a value, since we just actively set it above."
              conclusion
            }),
          )
          use somewhat_asserted_value <- promise.await(
            promise_of_a_somewhat_asserted_value,
          )
          let expectation =
            configurable_variables.typecontrolled
            |> list.key_find(key)
            |> result.unwrap(reality)
          // Sometimes, reality can be transitioned into expectation
          // --that's a horrible joke.
          let #(reality, expectation, somewhat_asserted_value) = {
            case reality, expectation {
              "bits", "string" -> {
                let assert Ok(b64) = somewhat_asserted_value |> list.first()
                let hopefully_bits = b64 |> bit_array.base16_decode
                case hopefully_bits {
                  Ok(bits) -> {
                    case bits |> bit_array.to_string() {
                      Ok(str) -> #(
                        configurable_variables.var_unsupported,
                        expectation,
                        [str, configurable_variables.var_string],
                      )
                      Error(..) -> #(
                        configurable_variables.var_unsupported,
                        expectation,
                        [configurable_variables.var_unsupported],
                      )
                    }
                  }
                  Error(..) -> {
                    #(configurable_variables.var_unsupported, expectation, [
                      configurable_variables.var_unsupported,
                    ])
                  }
                }
              }
              _, _ -> #(reality, expectation, somewhat_asserted_value)
            }
          }
          let z: Result(List(String), ConfigTomlDecodeError) = case
            reality == configurable_variables.var_unsupported
          {
            True ->
              Error(FieldError(
                "variables->" <> key <> " does not contain a supported value.",
              ))
            False -> {
              { expectation == reality }
              |> bool.guard(Ok(somewhat_asserted_value), fn() {
                Error(FieldError(
                  "variables->"
                  <> key
                  <> " does not contain the expected value. --> Expected: "
                  <> expectation
                  <> ", got: "
                  <> reality,
                ))
              })
            }
          }
          promise.resolve(z)
        })
      }
      |> dict.to_list()
      |> list.map(fn(x) {
        let #(key, promise_of_a_value) = x
        use value <- promise.await(promise_of_a_value)
        promise.resolve(#(key, value))
      })
      |> promise.await_list()
    _ -> promise.resolve([])
  }
  use other_vars <- promise.await(other_vars)
  // A kind of manual result.all()
  let other_vars = case
    list.find_map(other_vars, fn(le) {
      let #(_key, result_of_value): #(
        String,
        Result(List(String), ConfigTomlDecodeError),
      ) = le
      case result_of_value {
        Error(err) -> Ok(err)
        _ -> Error(Nil)
      }
    })
  {
    Ok(pq) -> Error(pq)
    Error(Nil) -> {
      other_vars
      |> list.map(fn(it) {
        let assert Ok(b) = it.1
        #(it.0, b)
      })
      |> Ok
    }
  }

  use other_vars <- promise.try_await(other_vars |> promise.resolve)

  Ok(configtype.SharedCynthiaConfigGlobalOnly(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    git_integration:,
    crawlable_context:,
    sitemap:,
    comment_repo:,
    other_vars:,
  ))
  |> promise.resolve()
}
