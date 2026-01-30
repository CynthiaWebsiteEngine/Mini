//// Oceanic Layout Module
////
//// A modern, blue-themed layout with wave-inspired design elements.
//// This layout offers two different presentation styles:
//// - For pages: A clean, full-width layout focusing on content
//// - For posts: A sidebar layout that displays metadata alongside content
////
//// Key design elements:
//// - Wave-inspired gradients and decorative elements
//// - Two-level menu system (primary navigation + contextual secondary navigation)
//// - Responsive design that adapts to different screen sizes
////
//// This module is written to test the docs, it seems to be a
//// good fit for the oceanic theme.

import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Page layout handler for the Oceanic theme
///
/// This function creates the layout structure for regular pages (not blog posts).
/// Pages use a simpler, full-width layout without the metadata sidebar.
///
/// Required metadata keys:
/// - `title`: The page title
/// - `description_html`: HTML description that appears below the title
///
/// @param content The main page content as an Element
/// @param variables Dictionary containing page metadata
/// @param store Client data store for menus and other data
/// @param priority If true, skips loading menus (for initial fast rendering)
/// @return A fully constructed page layout
pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Load the primary navigation menu if not in priority mode
  let menu = menu_1(model)

  // Load the secondary navigation menu if not in priority mode
  let secondary_menu = menu_2(model)

  // Extract required metadata with assertions to ensure it exists
  let assert Ok(title) =
    dict.get(variables, "title")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  // Build the page header with title and description
  let page_header =
    html.div([attribute.class("break-words p-4 relative z-10")], [
      // Top wave decoration - adds visual interest above the title
      html.div(
        [
          attribute.class(
            "absolute top-0 left-0 right-0 h-3 bg-gradient-to-r from-primary via-accent to-secondary opacity-70 rounded-full -z-10",
          ),
        ],
        [],
      ),
      html.h1(
        [
          attribute.class(
            "font-bold text-3xl mb-4 text-base-content relative inline-block",
          ),
        ],
        [
          // Subtle wave underline below the title text
          html.span(
            [
              attribute.class(
                "absolute -bottom-1 left-0 right-0 h-1 bg-gradient-to-r from-primary to-accent rounded-full",
              ),
            ],
            [],
          ),
          html.text(title),
        ],
      ),
      // Description area - uses dangerous-unescaped-html to allow formatted content
      element.unsafe_raw_html("aside", "aside", [], description),
    ])

  // Assemble the complete layout using the common layout function
  oceanic_common(
    content,
    menu,
    // Wrap the header in a div for consistency
    html.div([], [page_header]),
    secondary_menu,
    variables,
  )
}

/// Post layout handler for the Oceanic theme
///
/// This function creates the layout structure for blog posts.
/// Posts use a sidebar layout to display metadata alongside content.
///
/// Required metadata keys:
/// - `title`: The post title
/// - `description_html`: HTML description/excerpt
/// - `date_published`: Publication date (formatted string)
/// - `date_modified`: Last modified date (formatted string)
/// - `category`: Post category name
/// - `tags`: Comma-separated list of tags
///
/// @param content The main post content as an Element
/// @param variables Dictionary containing post metadata
/// @param store Client data store for menus and other data
/// @param priority If true, skips loading menus (for initial fast rendering)
/// @return A fully constructed post layout
pub fn post_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Load the primary navigation menu if not in priority mode
  let menu = menu_1(model)

  // Load the secondary navigation menu if not in priority mode
  let secondary_menu = menu_2(model)

  // Extract required metadata with assertions
  let assert Ok(title) =
    dict.get(variables, "title")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  // Build the post metadata sidebar content
  let post_meta =
    html.div([], [
      // Title and description section
      html.div([attribute.class("mb-6")], [
        html.h1(
          [
            attribute.class(
              "font-bold text-3xl mb-3 text-base-content relative inline-block",
            ),
          ],
          [
            // Small wave decoration under title - visual consistency with page layout
            html.span(
              [
                attribute.class(
                  "absolute -bottom-1 left-0 right-0 h-1 bg-gradient-to-r from-primary to-accent rounded-full",
                ),
              ],
              [],
            ),
            html.text(title),
          ],
        ),
        // Post description/excerpt
        element.unsafe_raw_html("aside", "aside", [], description),
      ]),
      // Post metadata grid - publication details in a styled card
      html.div(
        [
          attribute.class(
            "grid grid-cols-2 gap-3 mb-6 bg-base-200 p-4 rounded-lg border-l-4 border-primary shadow-md",
          ),
        ],
        [
          // Published date - with calendar icon for visual clarity
          html.b([attribute.class("font-bold flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-calendar text-primary"),
                attribute.attribute("aria-hidden", "true"),
              ],
              [],
            ),
            html.text("Published"),
          ]),
          html.div([attribute.class("text-base-content/80")], [
            html.text(
              variables
              |> dict.get("date_published")
              |> result.unwrap(dynamic.from(None))
              |> decode.run(decode.string)
              |> result.unwrap("unknown"),
            ),
          ]),
          // Last modified date - with edit icon
          html.b([attribute.class("font-bold flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-edit text-primary"),
                attribute.attribute("aria-hidden", "true"),
              ],
              [],
            ),
            html.text("Modified"),
          ]),
          html.div([attribute.class("text-base-content/80")], [
            html.text(
              variables
              |> dict.get("date_modified")
              |> result.unwrap(dynamic.from(None))
              |> decode.run(decode.string)
              |> result.unwrap("unknown"),
            ),
          ]),
          // Category - with category icon
          html.b([attribute.class("font-bold flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-category text-primary"),
                attribute.attribute("aria-hidden", "true"),
              ],
              [],
            ),
            html.text("Category"),
          ]),
          html.div([attribute.class("text-base-content/80")], [
            html.text(
              variables
              |> dict.get("category")
              |> result.unwrap(dynamic.from(None))
              |> decode.run(decode.string)
              |> result.unwrap("unknown"),
            ),
          ]),
        ],
      ),
      // Tags section - displayed as clickable buttons with wave decoration
      html.div([attribute.class("mb-8")], [
        html.b(
          [attribute.class("font-bold block mb-2 flex items-center gap-2")],
          [
            html.span(
              [
                attribute.class("i-tabler-tags text-primary"),
                attribute.attribute("aria-hidden", "true"),
              ],
              [],
            ),
            html.text("Tags"),
          ],
        ),
        // Generate tag buttons from comma-separated list
        html.div(
          [attribute.class("flex flex-wrap gap-2")],
          variables
            |> dict.get("tags")
            |> result.unwrap(dynamic.from([]))
            |> decode.run(decode.list(decode.string))
            |> result.unwrap([])
            |> list.map(string.trim)
            |> list.map(fn(tag) {
              html.a(
                [
                  attribute.class("btn btn-sm btn-outline btn-primary"),
                  attribute.href("#!/tag/" <> tag),
                ],
                [html.text(tag)],
              )
            }),
        ),
      ]),
    ])

  // Assemble the complete layout using the common layout function
  oceanic_common(content, menu, post_meta, secondary_menu, variables)
}

/// Shared layout structure for both pages and posts
///
/// This function builds the common structure used by both layout types,
/// handling the differences through parameters and conditional logic.
///
/// @param content The main page/post content
/// @param menu List of primary navigation menu elements
/// @param post_meta For posts: metadata sidebar content, for pages: just the header
/// @param secondary_menu List of secondary navigation menu elements
/// @param variables Dictionary containing metadata for the page/post
/// @return A complete HTML layout structure
fn oceanic_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  post_meta: Element(messages.Msg),
  secondary_menu: List(Element(messages.Msg)),
  variables: Dict(String, Dynamic),
) -> Element(messages.Msg) {
  // Extract site name and determine if this is a post
  let assert Ok(site_name) =
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let is_post =
    {
      dict.get(variables, "content_type")
      |> result.unwrap(dynamic.from(None))
      |> decode.run(decode.string)
    }
    == Ok("post")

  html.div(
    [
      attribute.id("content"),
      attribute.class("w-full h-full overflow-y-auto bg-base-300"),
    ],
    [
      // Top navigation bar with site name and primary menu
      html.div(
        [attribute.class("navbar bg-base-200 mb-4 shadow-lg rounded-b-lg")],
        [
          // Left side - site name/logo that links to homepage
          html.div([attribute.class("navbar-start")], [
            html.a(
              [attribute.class("btn btn-ghost text-xl"), attribute.href("/")],
              [html.text(site_name)],
            ),
          ]),
          // Center - Add search input with oceanic styling
          html.div([attribute.class("navbar-center hidden sm:flex")], [
            html.div([attribute.class("relative w-64")], [
              html.div(
                [
                  attribute.class(
                    "flex items-center h-9 bg-base-300/80 border-b-2 border-primary/30 hover:border-primary/60 focus-within:border-primary w-full rounded-t-md px-2",
                  ),
                ],
                [
                  html.span([attribute.class("text-base-content/60 mr-2")], [
                    html.span([attribute.class("i-tabler-search w-4 h-4")], []),
                  ]),
                  html.input([
                    attribute.class(
                      "w-full py-1 px-1 bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                    ),
                    attribute.placeholder("Search content..."),
                    attribute.type_("text"),
                    event.on_input(messages.UserSearchTerm),
                  ]),
                ],
              ),
            ]),
          ]),
          // Right side - primary menu
          html.div([attribute.class("navbar-end")], [
            html.ul(
              [
                attribute.id("menu_1_inside"),
                // ID target for menu updates
                attribute.class("menu menu-horizontal rounded-box"),
              ],
              menu,
            ),
          ]),
        ],
      ),
      // Mobile search bar (shown only on small screens)
      html.div([attribute.class("px-4 mb-4 sm:hidden")], [
        html.div(
          [
            attribute.class(
              "flex items-center h-9 bg-base-300/80 border-b-2 border-primary/30 hover:border-primary/60 focus-within:border-primary w-full rounded-t-md px-2",
            ),
          ],
          [
            html.span([attribute.class("text-base-content/60 mr-2")], [
              html.span([attribute.class("i-tabler-search w-4 h-4")], []),
            ]),
            html.input([
              attribute.class(
                "w-full py-1 px-1 bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
              ),
              attribute.placeholder("Search content..."),
              attribute.type_("text"),
              event.on_input(messages.UserSearchTerm),
            ]),
          ],
        ),
      ]),
      // Secondary menu container - can be hidden when empty
      // This allows for context-dependent navigation options
      html.div(
        [
          attribute.id("secondary_menu_container"),
          // Target for showing/hiding
          attribute.class(case secondary_menu {
            [] -> "mb-4 hidden"
            // Hide when empty
            _ -> "mb-4"
            // Show when has items
          }),
        ],
        [
          html.div(
            [
              attribute.class(
                "bg-base-300/50 rounded-lg p-2 shadow-sm flex justify-center",
              ),
            ],
            [
              html.ul(
                [
                  attribute.id("menu_2_inside"),
                  // ID target for menu updates
                  attribute.class(
                    "menu menu-horizontal rounded-box gap-2 flex-wrap justify-center",
                  ),
                ],
                secondary_menu,
              ),
            ],
          ),
        ],
      ),
      // Main content container - different layout for pages vs posts
      case is_post {
        True -> {
          // Posts: Two-column layout with metadata sidebar
          html.div([attribute.class("container mx-auto max-w-6xl")], [
            html.div([attribute.class("flex flex-col md:flex-row gap-6")], [
              // Left sidebar with post metadata
              // On mobile: appears above content
              // On desktop: appears to the left of content
              html.div([attribute.class("w-full md:w-1/4")], [
                html.div(
                  [attribute.class("bg-base-200 rounded-lg p-4 sticky top-4")],
                  [post_meta],
                ),
              ]),
              // Main content area - 3/4 width on desktop, full on mobile
              html.div([attribute.class("w-full md:w-3/4")], [
                html.div(
                  [attribute.class("bg-base-100 rounded-lg p-6 shadow-md")],
                  [content],
                ),
              ]),
            ]),
          ])
        }
        False -> {
          // Pages: Full-width layout, simpler presentation
          html.div([attribute.class("container mx-auto max-w-6xl")], [
            html.div([attribute.class("w-full")], [
              html.div(
                [attribute.class("bg-base-100 rounded-lg p-6 shadow-md")],
                [
                  // For pages, post_meta contains just the header content
                  post_meta,
                  content,
                ],
              ),
            ]),
          ])
        }
      },
      html.div(
        [
          attribute.class(
            "mt-8 text-center text-sm text-base-content opacity-75 py-4",
          ),
        ],
        [html.br([])],
        // Empty break for spacing
      ),
    ],
  )
}

/// Primary navigation menu generator
///
/// Creates the main site navigation menu from menu items in level 1.
/// Handles the active state based on current URL hash.
///
/// @param content Dictionary mapping menu levels to lists of menu items
/// @return List of HTML elements representing menu items
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  // Get the current URL hash to identify the active page
  let hash = model.path
  let content = model.computed_menus

  // Extract level 1 menu items (main navigation)
  case dict.get(content, 1) {
    Error(_) -> []
    // Return empty list if no menu items
    Ok(menu_items) -> {
      list.map(menu_items, fn(item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = {
          let model_type.MenuItem(name:, to:) = item
          #(name, to)
        }
        // Handle empty URLs as links to homepage
        let item = case item.1 {
          "" -> #(item.0, "/")
          _ -> item
        }

        // Generate a list item with a properly linked anchor
        html.li([], [
          html.a(
            [
              // Apply "active" class if this is the current page
              attribute.class(case hash == item.1 {
                True -> "active"
                False -> ""
              }),
              attribute.href(item.1),
            ],
            [html.text(item.0)],
          ),
        ])
      })
    }
  }
}

/// Secondary navigation menu generator
///
/// Creates a supplementary navigation menu from menu items in level 2.
/// This menu typically shows context-specific navigation options.
///
/// @param content Dictionary mapping menu levels to lists of menu items
/// @return List of HTML elements representing secondary menu items
pub fn menu_2(from model: model_type.Model) -> List(Element(messages.Msg)) {
  // Get the current URL hash to identify the active page
  let hash = model.path
  let content = model.computed_menus
  // Extract level 2 menu items (secondary navigation)
  case dict.get(content, 2) {
    Error(_) -> []
    // Return empty list if no menu items
    Ok(menu_items) -> {
      list.map(menu_items, fn(item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = {
          let model_type.MenuItem(name:, to:) = item
          #(name, to)
        }
        // Handle empty URLs as links to homepage
        let item = case item.1 {
          "" -> #(item.0, "/")
          _ -> item
        }

        // Generate a list item with a styled button-like anchor
        html.li([], [
          html.a(
            [
              // Apply appropriate button styling based on active state
              attribute.class(case hash == item.1 {
                True -> "active btn btn-sm btn-primary"
                // Filled button for active item
                False -> "btn btn-sm btn-outline btn-primary"
                // Outline button for inactive
              }),
              attribute.href(item.1),
            ],
            [html.text(item.0)],
          ),
        ])
      })
    }
  }
}

/// Generic menu rendering utility
///
/// This is a helper function that can render menu items from any level
/// in a simple list format. Used by other components that need a basic
/// representation of menu items.
///
/// @param items Dictionary of menu items by level
/// @return Flat list of HTML elements representing all menu items
pub fn render_nav_menu(
  items: Dict(Int, List(#(String, String))),
) -> List(Element(messages.Msg)) {
  // Convert the dictionary to a list of entries and flatten
  dict.to_list(items)
  |> list.flat_map(fn(entry) {
    let #(_level, menu_items) = entry

    // Convert each menu item to a list element
    menu_items
    |> list.map(fn(item) {
      let #(url, name) = item
      html.li([], [html.a([attribute.href(url)], [html.text(name)])])
    })
  })
}
