import gleam/result
import plinth/browser/document
import plinth/browser/element

pub fn push_title(title: String) -> Result(Nil, String) {
  use title_element <- result.then(
    document.query_selector("title")
    |> result.replace_error("No title element found"),
  )

  let sitetitle =
    {
      use a <- result.try(document.query_selector(
        "head>meta[property='og:site_name']",
      ))
      let b = a |> element.get_attribute("content")
      b
    }
    |> result.map(fn(x) { x <> " — " })
    |> result.unwrap("")
  title_element |> element.set_inner_text(sitetitle <> title)
  Ok(Nil)
}

/// Get the color scheme of the user's system (media query)
@external(javascript, "./dom.ts", "get_color_scheme")
pub fn get_color_scheme() -> String

/// Set the data attribute of an element
@external(javascript, "./dom.ts", "set_data")
pub fn set_data(element: element.Element, key: String, value: String) -> Nil

/// Set the hash of the window
@external(javascript, "./dom.ts", "set_hash")
pub fn set_hash(hash: String) -> Nil

/// Get innerhtml of an element
@external(javascript, "./dom.ts", "get_inner_html")
pub fn get_inner_html(element: element.Element) -> String

/// jsonify_string
/// Convert a string to a JSON safe string
@external(javascript, "./dom.ts", "jsonify_string")
pub fn jsonify_string(str: String) -> Result(String, Nil)
