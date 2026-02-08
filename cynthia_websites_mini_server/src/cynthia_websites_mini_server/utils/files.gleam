@external(javascript, "./files_ffi.ts", "exists")
pub fn file_exist(file: String) -> Bool

@external(javascript, "./files_ffi.ts", "path_join")
pub fn path_join(parts: List(String)) -> String

@external(javascript, "./files_ffi.ts", "path_normalize")
pub fn path_normalize(path: String) -> String

// Not in use. Using Jot instead for now.
@external(javascript, "./files_ffi.ts", "djot_to_html")
fn djot_to_html_string(djot: String) -> String

@external(javascript, "../../client_code_generated_ffi.ts", "client_script")
pub fn client_js() -> String

@external(javascript, "../../client_code_generated_ffi.ts", "client_styles")
pub fn client_css() -> String
