import gleam/float
import gleam/http
import gleam/http/request.{type Request}
import gleam/javascript/array.{type Array}
import gleam/order
import gleam/string
import gleam/time/timestamp
import plinth/browser/window

pub fn phone_home() -> Request(String) {
  request.new()
  |> request.set_scheme({
    let origin = window.origin()
    case origin {
      "http://" <> _ -> http.Http
      "https://" <> _ -> http.Https
      _ -> http.Https
    }
  })
  |> request.set_host(get_window_host())
}

pub fn phone_home_url() -> String {
  let origin = window.origin()
  let host = get_window_host()

  case origin {
    "http://" <> _ -> "http://" <> host
    "https://" <> _ -> "https://" <> host
    _ -> "https://" <> host
  }
  <> window.pathname()
  |> phone_home_lessener
}

fn phone_home_lessener(in: String) -> String {
  case string.ends_with(in, "//") {
    True -> phone_home_lessener(in |> string.drop_end(1))
    False ->
      case string.ends_with(in, "index.html") {
        True -> phone_home_lessener(in |> string.replace("index.html", ""))
        False ->
          case string.ends_with(in, "index.html/") {
            True -> phone_home_lessener(in |> string.replace("index.html", ""))
            False -> in
          }
      }
  }
}

@external(javascript, "./utils_ffi.ts", "getWindowHost")
pub fn get_window_host() -> String

pub fn now() -> Int {
  let now =
    timestamp.system_time()
    |> timestamp.to_unix_seconds
    |> float.truncate
  now
}

pub fn compare_so_natural(a: String, b: String) -> order.Order {
  case compares(a, b) {
    "eq" -> order.Eq
    "lt" -> order.Lt
    "gt" -> order.Gt
    _ -> panic as "compare_so_natural failed?? This should never happen"
  }
}

@external(javascript, "./utils_ffi.ts", "compares")
fn compares(a: String, b: String) -> String
