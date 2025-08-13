import birdie
import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/pottery/djotparse
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import lustre/element/html

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn simple_djot_test() {
  "# Hello World\n\nThis is a test paragraph.\n\n- Item 1\n- Item 2"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "simple_djot_test")
}

pub fn djot_with_preprocessing_test() {
  "# Hello World\n\nThis is a test paragraph.\n\n- [ ] Task item\n- [x] Completed task\n\n> This is a blockquote\n\nAnother paragraph."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "djot_with_preprocessing_test")
}

pub fn autolinks_test() {
  "External page example, using the theme list, downloading from <https://raw.githubusercontent.com/CynthiaWebsiteEngine/Mini-docs/refs/heads/main/content/3.%20customisation/3.2-themes.md>"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "autolinks_test")
}

pub fn links_in_preprocessed_items_test() {
  "- [ ] Task with [link](https://example.com)\n- [x] Completed task with [another link](https://test.com)\n\n> Blockquote with [a link](https://blockquote.example)"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "links_in_preprocessed_items_test")
}

pub fn ordered_list_with_links_test() {
  "1. First item with [link](https://first.com)\n2. Second item with [another link](https://second.com)\n3. Third item with **bold** and [link](https://third.com)"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "ordered_list_with_links_test")
}

pub fn ootb_index_rendering_test() {
  configtype.ootb_index
  |> djotparse.entry_to_conversion()
  |> html.body([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "ootb_index_rendering_test")
}
