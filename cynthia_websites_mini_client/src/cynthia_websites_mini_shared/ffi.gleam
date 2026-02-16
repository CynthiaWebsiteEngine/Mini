import plinth/browser/element as js_element

@external(javascript, "./js_ffi.mjs", "whatever_timestamp_to_unix_millis")
pub fn whatever_timestamp_to_unix_millis(ts: String) -> Int

@external(javascript, "./js_ffi.mjs", "my_own_version")
pub fn version() -> String

/// Get the color scheme of the user's system (media query)
@external(javascript, "./js_ffi.mjs", "get_color_scheme")
pub fn get_color_scheme() -> Bool

/// Set the data attribute of an element
@external(javascript, "./js_ffi.mjs", "set_data")
pub fn set_data(element: js_element.Element, key: String, value: String) -> Nil

/// Set the hash of the window
@external(javascript, "./js_ffi.mjs", "set_hash")
pub fn set_hash(hash: String) -> Nil

/// Get innerhtml of an element
@external(javascript, "./js_ffi.mjs", "get_inner_html")
pub fn get_inner_html(element: js_element.Element) -> String

/// jsonify_string
/// Convert a string to a JSON safe string
@external(javascript, "./js_ffi.mjs", "jsonify_string")
pub fn jsonify_string(str: String) -> Result(String, Nil)

@external(javascript, "./js_ffi.mjs", "destroy_comment_box")
pub fn destroy_comment_box() -> Nil

@external(javascript, "./js_ffi.mjs", "apply_styles_to_comment_box")
pub fn comment_box_forced_styles() -> Nil

@external(javascript, "./js_ffi.mjs", "browse")
pub fn browse(a: String) -> Nil

@external(javascript, "./js_ffi.mjs", "browse_prompt")
pub fn browse_prompt(s: String) -> Nil

import gleam/dynamic.{type Dynamic}
import gleam/javascript/array

@external(javascript, "./js_ffi.mjs", "cbor_to_dyn")
fn ffi_cbor_to_dyn(data: BitArray) -> array.Array(Dynamic)

pub fn cbor_to_dyn(data: BitArray) {
  case ffi_cbor_to_dyn(data) |> array.to_list {
    [dyn] -> Ok(dyn)
    _ -> Error(Nil)
  }
}

@external(javascript, "./js_ffi.mjs", "is_browser")
pub fn is_browser() -> Bool
