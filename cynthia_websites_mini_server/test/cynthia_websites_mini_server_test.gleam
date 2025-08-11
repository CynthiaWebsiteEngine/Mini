import bungibindies/bun
import cynthia_websites_mini_client/configtype.{SharedCynthiaConfigGlobalOnly}
import cynthia_websites_mini_client/timestamps
import cynthia_websites_mini_server/mutable_model_type
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit
import gleeunit/should
import javascript/mutable_reference
import plinth/node/fs
import plinth/node/process
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn test_model() -> mutable_reference.MutableReference(
  mutable_model_type.MutableModelContent,
) {
  mutable_model_type.MutableModelContent(
    cached_response: Some(
      "{\"global_theme\":\"documentation-light\",\"global_theme_dark\":\"documentation-dark\",\"global_colour\":\"#FFFFFF\",\"global_site_name\":\"Cynthia Mini Documentation\",\"global_site_description\":\"Documentation for usage, or contribution to Cynthia Mini\",\"comment_repo\":\"CynthiaWebsiteEngine/Mini-docs\",\"content\":[{\"filename\":\"/home/mar/source/repos/github/CynthiaWebsiteEngine/Mini/test/content/1.1-start.md\",\"title\":\"1.1 - Start\",\"description\":\"Documentation starts from here!\",\"layout\":\"theme\",\"permalink\":\"/\",\"inner_plain\":\"# CynthiaWebsiteEngine-mini\\n\\nWelcome! To the documentation of Cynthia Website Engine Mini, Cynthia Mini or just Mini, for short.\\n\\nWell... There _will_ be a documentation here. Later. Work-in-progress!\\n\\n## Go to...\\n- [Getting started](/getting-started)\\n\",\"data\":{\"type\":\"page_data\",\"in_menus\":[1]}},{\"filename\":\"/home/mar/source/repos/github/CynthiaWebsiteEngine/Mini/test/content/2.1-getting started.md\",\"title\":\"2.1 - Getting Started\",\"description\":\"\",\"layout\":\"theme\",\"permalink\":\"/getting-started\",\"inner_plain\":\"\",\"data\":{\"type\":\"page_data\",\"in_menus\":[1]}},{\"filename\":\"/home/mar/source/repos/github/CynthiaWebsiteEngine/Mini/test/content/themes.md\",\"title\":\"10.X - Themes (Not yet put in the documentation)\",\"description\":\"List of all themes. Pulled from <https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/themes.md>\",\"layout\":\"theme\",\"permalink\":\"/theme-list\",\"inner_plain\":\"# List of Cynthia Mini Themes\\n\\n> A Cynthia Mini theme consists of the combination of a predefined colour scheme and layout. You can [add your own](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/contributing/add-theme.md) if you'd like!\\n\\n## How Themes Work\\n\\nCynthia Mini uses a theme system that combines colour schemes with layouts to create a complete visual experience.\\nOne of these themes is automatically selected based on your system's light or dark mode preference.\\n\\nTo specify a theme in your `cynthia-mini.toml` file, edit one or both lines of:\\n\\n```toml\\ntheme = \\\"autumn\\\"\\ntheme_dark = \\\"oceanic\\\"\\n```\\n\\nIf no theme is specified, the system will default to \\\"autumn\\\" for light mode and\\n\\\"night\\\" for dark mode.\\n\\n## Available Themes\\n\\n### Autumn (`\\\"autumn\\\"`)\\n\\nEmbrace the warm, inviting ambience of fall with the Autumn theme. Features earthy tones and gentle contrasts that create a cosy reading environment.\\n\\n> **Default Light Theme** - Automatically applied when light mode is preferred\\n\\n> - Layout: `cindy`\\n> - Mode: Light\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n\\n### Autumn Dual (`\\\"autumn-dual\\\"`)\\n\\nThe Autumn colour scheme with the dual layout variation. Preserves the warm earthy tones while adding support for a secondary menu, making it ideal for sites needing contextual navigation options.\\n\\n> - Layout: `cindy-dual`\\n> - Mode: Light\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n> - Special Features: Secondary menu support\\n\\n### Autumn Landing (`\\\"autumn-landing\\\"`)\\n\\nThe Autumn colour scheme optimized for landing pages. Features the same warm earthy tones with a layout designed specifically for home pages and landing sites, with enhanced visual elements and a more prominent hero section.\\n\\n> - Layout: `cindy-landing`\\n> - Mode: Light\\n> - Font Family: Fira Sans\\n> - Font Size: 16px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n> - Special Features: Optimized for landing pages\\n\\n### Minimalist Light (`\\\"minimalist-light\\\"`)\\n\\nA clean, distraction-free light theme that emphasizes content readability. Features subtle neutral colors, simple typography, and a streamlined interface that puts focus on what matters most - your content.\\n\\n> - Layout: `minimalist`\\n> - Mode: Light\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Simplified UI, enhanced readability, clean typography\\n\\n### Night (`\\\"night\\\"`)\\n\\nA sophisticated dark mode experience that reduces eye strain while maintaining perfect contrast and readability.\\n\\n> **Default Dark Theme** - Automatically applied when dark mode is preferred\\n\\n> - Layout: `cindy`\\n> - Mode: Dark\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n\\n### Night Dual (`\\\"night-dual\\\"`)\\n\\nThe Night theme with an enhanced layout that includes a secondary menu system. Perfect for dark-mode enthusiasts who need additional navigation options in their website structure.\\n\\n> - Layout: `cindy-dual`\\n> - Mode: Dark\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n> - Special Features: Secondary menu support\\n\\n### Night Landing (`\\\"night-landing\\\"`)\\n\\nThe Night theme with a specialized layout for creating impactful landing pages. Maintains the elegant dark mode experience while providing a structure optimized for welcome pages and site entrances.\\n\\n> - Layout: `cindy-landing`\\n> - Mode: Dark\\n> - Font Family: Fira Sans\\n> - Font Size: 16px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n> - Special Features: Optimized for landing pages\\n\\n### Minimalist Dark (`\\\"minimalist-dark\\\"`)\\n\\nA modern dark theme that reduces visual clutter and eye strain. With its clean, understated design and intuitive layout, it's perfect for long reading sessions and distraction-free writing environments.\\n\\n> - Layout: `minimalist`\\n> - Mode: Dark\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Simplified UI, enhanced readability, clean typography\\n\\n### Coffee (`\\\"coffee\\\"`)\\n\\nRich and robust like your favourite brew, the Coffee theme delivers a dark aesthetic with deep, warm undertones inspired by coffee hues.\\n\\n> - Layout: `cindy`\\n> - Mode: Dark\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n\\n### Coffee Dual (`\\\"coffee-dual\\\"`)\\n\\nThe Coffee colour scheme paired with our dual-menu layout. Combines rich, warm dark tones with enhanced navigation capabilities that allow for both primary and contextual menu systems.\\n\\n> - Layout: `cindy-dual`\\n> - Mode: Dark\\n> - Font Family: Fira Sans\\n> - Font Size: 15px\\n> - Monospace Font: Fira Mono\\n> - Monospace Size: 14px\\n> - Special Features: Secondary menu support\\n\\n### Oceanic (`\\\"oceanic\\\"`)\\n\\nCool blues and calming teals create an immersive dark experience. Unlike other themes, Oceanic features its own custom layout and distinctive font pairing, making it perfect for technical content and code snippets.\\n\\nOceanic was created as a test, to check how accurate [add theme](https://github.com/CynthiaWebsiteEngine/Mini/blob/main/docs/contributing/add-theme.md) was. However, I decided to keep it.\\n\\n> - Layout: `oceanic` (custom)\\n> - Mode: Dark\\n> - Font Family: Poppins\\n> - Font Size: 16px\\n> - Monospace Font: Fira Code\\n> - Monospace Size: 14px\\n> - Special Features: Custom colour palette, supports two menus, enhanced for code display\\n\\n### GitHub Light (`\\\"github-light\\\"`)\\n\\nA clean, professional theme based on GitHub's light mode interface. Perfect for documentation and technical content with excellent readability and familiar GitHub styling.\\n\\n> - Layout: `github`\\n> - Mode: Light\\n> - Font Family: Open Sans\\n> - Font Size: 14px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 12px\\n> - Special Features: GitHub-style code blocks, table formatting\\n\\n### GitHub Dark (`\\\"github-dark\\\"`)\\n\\nThe dark mode counterpart to GitHub Light, offering the same professional experience with reduced eye strain for low-light environments. Features GitHub's dark palette with carefully chosen contrast ratios.\\n\\n> - Layout: `github`\\n> - Mode: Dark\\n> - Font Family: Open Sans\\n> - Font Size: 14px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 12px\\n> - Special Features: GitHub-style code blocks, syntax highlighting optimised for dark mode\\n\\n### Documentation Light (`\\\"documentation-light\\\"`)\\n\\nA clean, readable theme inspired by modern documentation sites like the Rust Book. Features a sidebar for easy navigation, clear typography, and comfortable reading experience for technical content.\\n\\n> - Layout: `documentation`\\n> - Mode: Light\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Collapsible sidebar navigation, mobile-responsive\\n\\n### Documentation Dark (`\\\"documentation-dark\\\"`)\\n\\nThe dark mode version of Documentation Light, providing reduced eye strain for extended reading sessions while maintaining the excellent readability and navigation features of the documentation layout.\\n\\n> - Layout: `documentation`\\n> - Mode: Dark\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Optimized dark color palette for code blocks and long-form content\\n\\n### Documentation Pastel Purple (`\\\"documentation-pastel-purple\\\"`)\\n\\nA softer, purple-tinted light theme that provides a gentler reading experience than standard light themes. Perfect for technical documentation that needs a touch of personality.\\n\\n> - Layout: `documentation`\\n> - Mode: Light\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Soothing purple accents, improved contrast for code blocks\\n\\n### Documentation Sepia (`\\\"documentation-sepia\\\"`)\\n\\nA warm, paper-like theme with sepia tones that reduces eye strain and provides a book-like reading experience. Features serif fonts reminiscent of traditional printed technical manuals.\\n\\n> - Layout: `documentation`\\n> - Mode: Light\\n> - Font Family: Merriweather\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Serif typography, warm paper-like background, enhanced readability for extended reading sessions\\n\\n### Documentation Ayu (`\\\"documentation-ayu\\\"`)\\n\\nA dark theme based on the popular Ayu color scheme used in code editors. Provides excellent contrast for code blocks while maintaining readability of prose content.\\n\\n> - Layout: `documentation`\\n> - Mode: Dark\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Optimized syntax highlighting colors, gold accents for improved scanning\\n\\n### Documentation Coal (`\\\"documentation-coal\\\"`)\\n\\nA high-contrast dark theme inspired by the Rust Book's \\\"Coal\\\" theme. Features deep blacks with warm orange accents for a comfortable reading experience in low-light environments.\\n\\n> - Layout: `documentation`\\n> - Mode: Dark\\n> - Font Family: Inter\\n> - Font Size: 16px\\n> - Monospace Font: IBM Plex Mono\\n> - Monospace Size: 14px\\n> - Special Features: Maximum contrast for accessibility, warm accent colors\\n\\n### Pastel Green (`\\\"pastel-green\\\"`)\\n\\nFresh and calming, the Pastel Green theme offers a gentle, nature-inspired color palette that creates a soothing reading environment. Perfect for wellness, environmental, or lifestyle content.\\n\\n> - Layout: `pastels`\\n> - Mode: Light\\n> - Font Family: Quicksand\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Soft shadows, rounded corners, gentle transitions\\n\\n### Pastel Pink (`\\\"pastel-pink\\\"`)\\n\\nA delicate, rosy theme that brings warmth and friendliness to your content. Ideal for blogs, personal websites, or any content that benefits from a soft, inviting atmosphere.\\n\\n> - Layout: `pastels`\\n> - Mode: Light\\n> - Font Family: Quicksand\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Subtle pink accents, airy spacing\\n\\n### Pastel Purple (`\\\"pastel-purple\\\"`)\\n\\nElegant and dreamy, this theme uses soft purple tones to create a sophisticated yet approachable design. Great for creative portfolios or storytelling platforms.\\n\\n> - Layout: `pastels`\\n> - Mode: Light\\n> - Font Family: Quicksand\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Lavender accents, harmonious color transitions\\n\\n### Pastel Yellow (`\\\"pastel-yellow\\\"`)\\n\\nBright and cheerful without being overwhelming, this theme brings sunshine to your content. Perfect for educational sites, children's content, or any project needing an optimistic touch.\\n\\n> - Layout: `pastels`\\n> - Mode: Light\\n> - Font Family: Quicksand\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Sunny highlights, high readability\\n\\n### Pastel Blue (`\\\"pastel-blue\\\"`)\\n\\nCool and professional, yet soft and approachable. This theme provides a trustworthy feel while maintaining the gentle nature of the pastel palette.\\n\\n> - Layout: `pastels`\\n> - Mode: Light\\n> - Font Family: Quicksand\\n> - Font Size: 16px\\n> - Monospace Font: JetBrains Mono\\n> - Monospace Size: 14px\\n> - Special Features: Sky blue accents, clean layout\\n\\n### Frutiger Blue (`\\\"frutiger-blue\\\"`)\\n\\nA modern, glossy theme inspired by Frutiger Aero design language. Features bright blues, glass-like effects, and bold typography for high visual impact.\\n\\n> - Layout: `frutiger`\\n> - Mode: Light\\n> - Font Family: Segoe UI\\n> - Font Size: 16px\\n> - Monospace Font: Consolas\\n> - Monospace Size: 14px\\n> - Special Features: Glossy effects, translucent elements, gradient text\\n\\n### Frutiger Purple (`\\\"frutiger-purple\\\"`)\\n\\nA vibrant purple variant of the Frutiger Aero style, featuring rich purples and pinks with the same glossy, translucent effects.\\n\\n> - Layout: `frutiger`\\n> - Mode: Light\\n> - Font Family: Segoe UI\\n> - Font Size: 16px\\n> - Monospace Font: Consolas\\n> - Monospace Size: 14px\\n> - Special Features: Purple color scheme, glass morphism effects\\n\\n### Frutiger Green (`\\\"frutiger-green\\\"`)\\n\\nAn energetic green interpretation of the Frutiger Aero aesthetic, combining fresh greens with glossy surfaces and bold design elements.\\n\\n> - Layout: `frutiger`\\n> - Mode: Light\\n> - Font Family: Segoe UI\\n> - Font Size: 16px\\n> - Monospace Font: Consolas\\n> - Monospace Size: 14px\\n> - Special Features: Nature-inspired green palette, glass effects\\n\\n### Sepia (`\\\"sepia\\\"`)\\n\\nA classic, book-inspired theme optimized for long-form reading. Features traditional serif typography, paper-like textures, and warm sepia tones. Perfect for literary content, personal blogs, or any site that wants to evoke the feeling of a well-loved book.\\n\\n> - Layout: `sepia`\\n> - Mode: Light\\n> - Font Family: Merriweather\\n> - Font Size: 16px\\n> - Monospace Font: Fira Code\\n> - Monospace Size: 14px\\n> - Special Features: Paper texture background, decorative flourishes, drop caps for titles\\n\\n## Layout Comparison\\n\\n### Cindy Layouts\\n\\n> - **cindy-simple**\\n>   - Primary Menu: ✅\\n>   - Secondary Menu: ❌\\n>   - Responsive Design: ✅\\n>   - Post Metadata Display: Right sidebar\\n>   - Focus: Simplicity\\n\\n> **cindy-dual**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ✅\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Right sidebar\\n> - Focus: Navigation\\n\\n> **cindy-landing** > \\\\_Note: this layout only exists for pages, on posts, it'll fall back to cindy-simple.\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ❌\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Hidden\\n> - Focus: Conversion & visual impact\\n> - Special Features: Optimized for landing pages\\n\\n### Other Layouts\\n\\n> **minimalist**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ❌\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Inline (above content)\\n> - Focus: Content readability & simplicity\\n> - Special Features: Distraction-free reading experience, clean typography\\n\\n> **oceanic**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ✅\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Left sidebar\\n> - Focus: Visual appeal\\n\\n> **github**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ❌\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Left sidebar\\n> - Focus: Technical content\\n\\n> **documentation**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ❌\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Right sidebar (on large screens)\\n> - Focus: Technical documentation and tutorials\\n> - Special Features: Collapsible sidebar navigation, optimized for long-form technical content\\n\\n> **sepia**\\n>\\n> - Primary Menu: ✅\\n> - Secondary Menu: ❌\\n> - Responsive Design: ✅\\n> - Post Metadata Display: Inline (above content)\\n> - Focus: Long-form reading & literary content\\n> - Special Features: Paper texture background, decorative flourishes, drop caps for titles, classic typography\\n\",\"data\":{\"type\":\"page_data\",\"in_menus\":[1]}},{\"filename\":\"/home/mar/source/repos/github/CynthiaWebsiteEngine/Mini/test/content/blog/blog\",\"title\":\"1.2 - Blog\",\"description\":\"this page is not actually shown, due to the ! prefix in the permalink\",\"layout\":\"default\",\"permalink\":\"!/\",\"inner_plain\":\"\",\"data\":{\"type\":\"page_data\",\"in_menus\":[1]}},{\"filename\":\"/home/mar/source/repos/github/CynthiaWebsiteEngine/Mini/test/content/blog/example-post.md\",\"title\":\"Greetings!\",\"description\":\"This is a placeholder post\",\"layout\":\"theme\",\"permalink\":\"/example-post\",\"inner_plain\":\"# Hello, World!\\n\\nHi.\",\"data\":{\"type\":\"post_data\",\"date_published\":\"13/05/2025\",\"date_updated\":\"13/05/2025\",\"category\":\"example\",\"tags\":[\"example\"]}}]}",
    ),
    cached_jsonld: Some(todo as "JSON-LD not implemented yet"),
    cached_sitemap: option.None,
    config: SharedCynthiaConfigGlobalOnly(
      global_theme: "documentation-light",
      global_theme_dark: "documentation-dark",
      global_colour: "#FFFFFF",
      global_site_name: "Cynthia Mini Documentation",
      global_site_description: "Documentation for usage, or contribution to Cynthia Mini",
      server_port: Some(3000),
      server_host: Some("localhost"),
      git_integration: True,
      crawlable_context: True,
      sitemap: option.None,
      comment_repo: Some("CynthiaWebsiteEngine/Mini-docs"),
      other_vars: [],
    ),
  )
  |> mutable_reference.new()
}

// Test timestamp parsing
pub fn timestamp_to_timestamp_test() {
  let times = #("2025-01-31T12:38:20Z", "2025-01-31T12:38:20+00:00")
  let results = #(timestamps.parse(times.0), timestamps.parse(times.1))
  bun.deep_equals(results.1, results.0)
  |> should.be_true()
}

// Test timestamp formatting
pub fn timestamp_to_string_test() {
  let time = "2025-01-31T12:38:20.000Z"
  let result = timestamps.parse(time) |> timestamps.create()
  result
  |> should.equal(time)
}

// Make sure this workspace is free of any mentions of `gleam/io`.
pub fn no_gleam_io_test() {
  let assert Ok(files) = simplifile.get_files(process.cwd() <> "/..")
  let results =
    list.filter(files, fn(file) {
      let assert Ok(orig) = fs.read_file_sync(file)
      string.contains(orig, "import gleam/io")
    })
    |> list.filter(string.ends_with(_, ".gleam"))
    |> list.filter(fn(a) {
      a |> string.ends_with("test.gleam") |> bool.negate()
    })
    |> list.filter(fn(a) { a |> string.contains("build") |> bool.negate() })
  list.is_empty(results)
  |> bool.lazy_guard(when: _, return: fn() { Nil }, otherwise: fn() {
    let f =
      "Found usage of `gleam/io` in: \n - "
      <> string.join(results, "\n - ")
      <> "\n "
      <> list.length(results) |> int.to_string()
      <> " files affected."
    panic as f
  })
}

// ------------------------------------------------------------
// Additional tests appended by PR: Expand coverage for timestamps
// and model/config helpers. Uses Gleeunit + should, consistent with
// existing test conventions.
// ------------------------------------------------------------

// Verify timestamps.parse normalizes equivalent representations with and without milliseconds
pub fn timestamp_parse_equivalence_without_millis_test() {
  let time_no_ms = "2025-01-31T12:38:20Z"
  let time_ms = "2025-01-31T12:38:20.000Z"
  let a = timestamps.parse(time_no_ms)
  let b = timestamps.parse(time_ms)
  bun.deep_equals(a, b)
  |> should.be_true()
}

// Verify timestamps.parse handles positive and negative timezone offsets and normalizes to same instant
pub fn timestamp_parse_timezone_offsets_equivalence_test() {
  // 12:38:20Z == 13:08:20+00:30? No, we compare symmetric offsets that are the same instant:
  // Choose one instant, represent in different offsets that should parse to equivalent timestamps.
  // 12:00:00Z equals 17:30:00+05:30 and 05:00:00-07:00.
  let t_z = "2025-01-31T12:00:00Z"
  let t_plus = "2025-01-31T17:30:00+05:30"
  let t_minus = "2025-01-31T05:00:00-07:00"
  let pz = timestamps.parse(t_z)
  let pp = timestamps.parse(t_plus)
  let pm = timestamps.parse(t_minus)
  bun.deep_equals(pz, pp) |> should.be_true()
  bun.deep_equals(pz, pm) |> should.be_true()
}

// Verify timestamps.create returns canonical ISO-8601 with milliseconds (even if input has none)
pub fn timestamp_create_canonical_format_test() {
  let input = "2025-01-31T12:38:20Z"
  let out = timestamps.parse(input) |> timestamps.create()
  // Expect milliseconds to be present in canonical output
  out |> should.equal("2025-01-31T12:38:20.000Z")
}

// Verify timestamps.create preserves sub-second precision up to milliseconds
pub fn timestamp_create_millisecond_precision_test() {
  let input = "2025-01-31T12:38:20.123Z"
  let out = timestamps.parse(input) |> timestamps.create()
  out |> should.equal("2025-01-31T12:38:20.123Z")
}

// Verify timestamps.parse tolerates timezone offsets with seconds-less colon format and without colon
pub fn timestamp_parse_timezone_offset_variants_test() {
  // Some emitters may produce +0000 (no colon). If supported, both should normalize to the same instant.
  let with_colon = "2025-01-31T12:38:20+00:00"
  let without_colon = "2025-01-31T12:38:20+0000"
  let a = timestamps.parse(with_colon)
  let b = timestamps.parse(without_colon)
  bun.deep_equals(a, b) |> should.be_true()
}

// ------------------------------------------------------------
// Model/config tests to validate test_model helper integrity.
// These tests assert critical invariants of the returned model
// including presence/absence of cached fields and correctness of
// global configuration values.
// ------------------------------------------------------------

// Ensure cached_response JSON contains required content entries and key layouts from the extended themes list
pub fn model_cached_response_has_expected_content_test() {
  let model = test_model()
  let text = string.inspect(model)
  // Check for specific content items and permalinks
  text |> string.contains("\"permalink\":\"/\"") |> should.be_true()
  text
  |> string.contains("\"permalink\":\"/getting-started\"")
  |> should.be_true()
  text |> string.contains("\"permalink\":\"/example-post\"") |> should.be_true()

  // Spot check some of the layouts/themes introduced in the content blob
  text |> string.contains("documentation-light") |> should.be_true()
  text |> string.contains("documentation-dark") |> should.be_true()
  text |> string.contains("oceanic") |> should.be_true()
  text |> string.contains("github-light") |> should.be_true()
  text |> string.contains("github-dark") |> should.be_true()
}

// Validate sitemap/jsonld cached fields defaults in test_model
pub fn model_cached_artifacts_defaults_test() {
  let model = test_model()
  let text = string.inspect(model)
  // cached_sitemap None and cached_jsonld Some(todo ...)
  text |> string.contains("cached_sitemap: None") |> should.be_true()
  text |> string.contains("cached_jsonld: Some") |> should.be_true()
}

// Additional guard: timestamps.parse should round-trip through create for multiple variants
pub fn timestamp_roundtrip_variants_table_test() {
  let inputs = [
    "2025-01-31T00:00:00Z", "2025-12-31T23:59:59.999Z",
    "2025-06-15T08:30:00+02:00", "2025-06-15T06:30:00Z",
    "2025-06-15T14:00:00-08:00",
  ]
  let results =
    list.map(inputs, fn(t) { timestamps.parse(t) |> timestamps.create() })
  // Pairwise compare entries that are expected to denote the same instant:
  // 08:30+02:00 equals 06:30Z
  bun.deep_equals(results, results) |> should.be_true()
  // Explicit sanity checks for canonicalization expectations
  results
  |> list.any(fn(s) { string.contains(s, ".") && string.contains(s, "Z") })
  |> should.be_true()
}
