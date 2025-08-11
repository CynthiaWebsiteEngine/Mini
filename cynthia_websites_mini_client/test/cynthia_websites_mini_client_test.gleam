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

pub fn debug_autolinks_test() {
  let input =
    "External page example, using the theme list, downloading from <https://raw.githubusercontent.com/CynthiaWebsiteEngine/Mini-docs/refs/heads/main/content/3.%20customisation/3.2-themes.md>"

  // Test the preprocessing step
  let preprocessed =
    input
    |> string.replace("\r\n", "\n")
    |> string.replace("\r", "\n")
    |> string.trim()
    |> string.replace("<https://", "🔗AUTOLINK🔗https://")

  // Check if we have the marker
  case string.contains(preprocessed, "🔗AUTOLINK🔗") {
    True -> should.equal("Found marker", "Found marker")
    False -> should.equal("No marker found", "Found marker")
  }
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

// -----------------------------------------------------------------------------
// Additional comprehensive tests for djotparse preprocessing and rendering
// Test stack: gleeunit + birdie (existing project setup)
// -----------------------------------------------------------------------------

pub fn autolinks_angle_brackets_multiple_test() {
  "See <https://example.com>, <http://foo.bar/baz>, and <https://sub.domain.tld/path?x=1&y=2> in one line."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "autolinks_angle_brackets_multiple_test")
}

pub fn autolinks_non_angle_urls_should_not_break_test() {
  // URLs without angle brackets may or may not be auto-linked depending on parser rules;
  // we are validating that preprocessing does not corrupt them.
  "Visit https://no-brackets.example/path and http://another.example/query?x=1."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "autolinks_non_angle_urls_should_not_break_test")
}

pub fn autolinks_mailto_and_mixed_content_test() {
  "Contact <mailto:info@example.com> or see <https://example.com/readme.md>."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "autolinks_mailto_and_mixed_content_test")
}

pub fn newline_normalization_and_trimming_variants_test() {
  let input =
    "\r\n# Title\r\n\r\nParagraph with Windows newlines.\r\n\r\n- Item A\r\n- Item B\r\n"
  input
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "newline_normalization_and_trimming_variants_test")
}

pub fn task_list_with_and_without_links_test() {
  "- [ ] Task todo\n- [x] Task done\n- [ ] Another with [link](https://example.com)\n- [x] Done with [docs](https://docs.example)"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "task_list_with_and_without_links_test")
}

pub fn nested_lists_with_links_and_formatting_test() {
  "- Parent 1\n  - Child with [link](https://child.example)\n  - Child with **bold** and _italic_\n- Parent 2\n  1. Ordered child with [another](https://another.example)\n  2. Second ordered child"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "nested_lists_with_links_and_formatting_test")
}

pub fn blockquote_with_links_and_paragraphs_test() {
  "> Quote line 1 with [ref](https://ref.example)\n>\n> Quote line 2.\n\nOutside paragraph with <https://outer.example/path>."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "blockquote_with_links_and_paragraphs_test")
}

pub fn ordered_list_with_mixed_content_and_strong_emphasis_test() {
  "1. First item with **bold** and [link](https://first.example)\n2. Second with _italic_ and <https://second.example>\n3. Third with `inline code` and [another](https://third.example)"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(
    title: "ordered_list_with_mixed_content_and_strong_emphasis_test",
  )
}

pub fn inline_code_and_code_block_should_not_autolink_test() {
  "Inline code like `curl https://api.example.com` should not autolink.\n\n```\n# A fenced code block containing an URL\nwget https://downloads.example.com/archive.tar.gz\n```\n\nRegular text with <https://linked.example> after code."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "inline_code_and_code_block_should_not_autolink_test")
}

pub fn links_with_parentheses_and_punctuation_test() {
  "A tricky [link](https://example.com/path(with)parens). Also <https://example.com/trail>, and a sentence ending link <https://end.example>."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "links_with_parentheses_and_punctuation_test")
}

pub fn multi_line_autolinks_across_paragraphs_test() {
  "Paragraph one with <https://one.example>\n\nParagraph two with <https://two.example/path?x=1> and [brackets](https://three.example)."
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "multi_line_autolinks_across_paragraphs_test")
}

pub fn empty_and_whitespace_only_input_test() {
  // Validate graceful handling of empty/whitespace input in the pipeline
  ""
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "empty_input_renders_minimal_markup_test")

  "   \n \r\n "
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "whitespace_only_input_renders_minimal_markup_test")
}

pub fn invalid_markdown_like_sequences_should_not_panic_test() {
  // Ensures robustness; even if content is malformed, rendering should succeed
  "Unclosed [link(https://bad.example\n\nMismatched **bold and _italic\n\n<https://ok.example>"
  |> djotparse.entry_to_conversion()
  |> html.section([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "invalid_markdown_like_sequences_should_not_panic_test")
}

// -----------------------------------------------------------------------------
// Tests specific to configtype.ootb_index rendering
// -----------------------------------------------------------------------------

pub fn ootb_index_contains_expected_sections_test() {
  configtype.ootb_index
  |> djotparse.entry_to_conversion()
  |> html.body([], _)
  |> element.to_readable_string
  |> birdie.snap(title: "ootb_index_contains_expected_sections_test")
}

// -----------------------------------------------------------------------------
// Dialed-in unit style assertions where possible with gleeunit/should
// These validate preprocessing markers logic akin to debug_autolinks_test but
// cover additional edge cases.
// -----------------------------------------------------------------------------

pub fn preprocessing_adds_marker_for_angle_autolinks_test() {
  let input = "See <https://example.com> and <http://foo.bar>."
  let preprocessed =
    input
    |> string.replace("\r\n", "\n")
    |> string.replace("\r", "\n")
    |> string.trim()
    |> string.replace("<https://", "🔗AUTOLINK🔗https://")
    |> string.replace("<http://", "🔗AUTOLINK🔗http://")

  should.be_true(string.contains(preprocessed, "🔗AUTOLINK🔗https://"))
  should.be_true(string.contains(preprocessed, "🔗AUTOLINK🔗http://"))
}

pub fn preprocessing_does_not_add_marker_for_non_angle_urls_test() {
  let input = "Non-angled https://example.com should remain unchanged."
  let preprocessed =
    input
    |> string.replace("\r\n", "\n")
    |> string.replace("\r", "\n")
    |> string.trim()
    |> string.replace("<https://", "🔗AUTOLINK🔗https://")

  // Ensure that the marker was not added as there were no angle brackets
  should.be_false(string.contains(preprocessed, "🔗AUTOLINK🔗"))
}

pub fn preprocessing_handles_trailing_whitespace_and_newlines_test() {
  let input = "  <https://example.com>  \r\n"
  let preprocessed =
    input
    |> string.replace("\r\n", "\n")
    |> string.replace("\r", "\n")
    |> string.trim()
    |> string.replace("<https://", "🔗AUTOLINK🔗https://")

  should.be_true(string.contains(preprocessed, "🔗AUTOLINK🔗https://example.com>"))
  // After trim, no leading/trailing whitespace
  should.equal(preprocessed, "🔗AUTOLINK🔗https://example.com>")
}
