//// GitHub Layout Module
////
//// A layout inspired by GitHub's interface design.
//// Features:
//// - Clean, focused design with ample whitespace
//// - Familiar GitHub header and navigation pattern
//// - Repository-style content presentation
//// - GitHub-style sidebar for metadata
//// - Responsive design that works well on all devices

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

// Import to determine the color scheme
import cynthia_websites_mini_client/dom

/// Page layout handler for the GitHub theme
///
/// This function creates the layout structure for regular pages (not blog posts).
///
/// @param content The main page content as an Element
/// @param variables Dictionary containing page metadata
/// @param store Client data store for menus and other data
/// @return A fully constructed page layout
pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Load the primary navigation menu
  let menu = menu_1(model)

  // Extract required metadata
  let assert Ok(title) =
    dict.get(variables, "title")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  // Build the page header, styled like a GitHub repository README header
  let page_header =
    html.div([], [
      html.div([attribute.class("mb-5 border-b border-base-300 pb-3")], [
        html.div([attribute.class("flex items-center gap-2 mb-4")], [
          // Document icon (similar to GitHub repo icon)
          html.span(
            [attribute.class("i-tabler-file-text text-base-content/70 text-xl")],
            [],
          ),
          // Title with GitHub-style heading
          html.h1(
            [attribute.class("text-2xl font-semibold text-base-content")],
            [html.text(title)],
          ),
        ]),
        // Description area with GitHub-style text
        element.unsafe_raw_html(
          "div",
          "div",
          [attribute.class("text-sm text-base-content/70 mb-2")],
          description,
        ),
      ]),
    ])

  // Assemble the complete layout using the common layout function
  github_common(content, menu, page_header, variables, model)
}

/// Post layout handler for the GitHub theme
///
/// This function creates the layout structure for blog posts with a sidebar.
///
/// @param content The main post content as an Element
/// @param variables Dictionary containing post metadata
/// @param store Client data store for menus and other data
/// @return A fully constructed post layout
pub fn post_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Load the primary navigation menu
  let menu = menu_1(model)

  // Extract required metadata
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  // Build the post sidebar content styled like GitHub's repository sidebar
  let post_meta =
    html.div(
      [attribute.id("da-sidebar"), attribute.class("w-full md:sticky md:top-4")],
      [
        // Flex container for About box and Information box (side by side on desktop)
        html.div([attribute.class("flex flex-col md:flex-row md:gap-4 mb-4")], [
          // About section with description
          html.div(
            [
              attribute.class(
                "w-full md:w-1/2 border border-base-300 rounded-md overflow-hidden mb-4 md:mb-0",
              ),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                  ),
                ],
                [html.text("About")],
              ),
              html.div([attribute.class("px-3 py-3 text-sm")], [
                element.unsafe_raw_html("div", "div", [], description),
              ]),
            ],
          ),
          // Post information box
          html.div(
            [
              attribute.class(
                "w-full md:w-1/2 border border-base-300 rounded-md overflow-hidden",
              ),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                  ),
                ],
                [html.text("Information")],
              ),
              html.div([attribute.class("divide-y divide-base-300")], [
                // Published date
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class(
                          "i-tabler-calendar-event text-base-content/60",
                        ),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("text-sm")], [
                      html.text(
                        "Published "
                        <> {
                          variables
                          |> dict.get("date_published")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap("unknown")
                        },
                      ),
                    ]),
                  ],
                ),
                // Last modified date
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class("i-tabler-edit text-base-content/60"),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("text-sm")], [
                      html.text(
                        "Updated "
                        <> {
                          variables
                          |> dict.get("date_modified")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap("unknown")
                        },
                      ),
                    ]),
                  ],
                ),
                // Category - using GitHub-style category badge
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class(
                          "i-tabler-category text-base-content/60",
                        ),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("flex items-center gap-1")], [
                      html.text("Category: "),
                      html.span(
                        [
                          attribute.class(
                            "px-2 py-0.5 text-xs rounded-full font-medium bg-primary/15 text-primary",
                          ),
                        ]
                          |> list.append(
                            case
                              variables
                              |> dict.get("category")
                              |> result.unwrap(dynamic.from(None))
                              |> decode.run(decode.string)
                            {
                              Ok(category) -> [
                                event.on_click(messages.UserNavigateTo(
                                  "!/category/" <> category,
                                )),
                                attribute.class(
                                  "cursor-pointer hover:bg-primary/25",
                                ),
                              ]
                              Error(_) -> [
                                attribute.class(
                                  "cursor-not-allowed text-base-content/50",
                                ),
                              ]
                            },
                          ),
                        [
                          html.text(
                            variables
                            |> dict.get("category")
                            |> result.unwrap(dynamic.from(None))
                            |> decode.run(decode.string)
                            |> result.unwrap("unknown"),
                          ),
                        ],
                      ),
                    ]),
                  ],
                ),
              ]),
            ],
          ),
        ]),
        // Tags section styled like GitHub topic tags
        html.div(
          [
            attribute.class(
              "border border-base-300 rounded-md overflow-hidden mb-4",
            ),
          ],
          [
            // Header for tags section
            html.div(
              [
                attribute.class(
                  "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                ),
              ],
              [html.text("Tags")],
            ),
            // Tags display area with GitHub-style topic tags
            html.div([attribute.class("p-3")], [
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
                        attribute.class(
                          "px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/15 text-primary hover:bg-primary/25",
                        ),
                        attribute.href("#!/tag/" <> tag),
                      ],
                      [html.text(tag)],
                    )
                  }),
              ),
            ]),
          ],
        ),
      ],
    )

  // Assemble the complete layout with sidebar content
  github_common(content, menu, post_meta, variables, model)
}

/// Shared layout structure for both pages and posts
///
/// @param content The main page/post content
/// @param menu List of primary navigation menu elements
/// @param sidebar Sidebar content (post metadata or page header based on type)
/// @param variables Dictionary containing metadata for the page/post
/// @param model Model with application state
/// @return A complete HTML layout structure
fn github_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  sidebar: Element(messages.Msg),
  variables: Dict(String, Dynamic),
  model: model_type.Model,
) -> Element(messages.Msg) {
  let menu_is_open =
    result.is_ok(dict.get(model.other, "github-layout menu open"))
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
      attribute.class("w-full h-full overflow-y-auto bg-base-100"),
    ],
    [
      // GitHub-style header with navigation
      html.div(
        [
          attribute.class(
            "bg-base-100 border-b border-base-300 sticky top-0 z-10",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 lg:px-5")], [
            html.div([attribute.class("flex items-center h-16")], [
              // Left side - site logo, name, and nav
              html.div([attribute.class("flex-1 flex items-center gap-4")], [
                // Logo and site name group
                html.div([attribute.class("flex items-center gap-2 mr-4")], [
                  // GitHub-like icon
                  html.span(
                    [
                      attribute.class(
                        "i-tabler-brand-github text-xl text-base-content",
                      ),
                    ],
                    [],
                  ),
                  html.a(
                    [
                      attribute.class(
                        "font-semibold text-base-content text-lg whitespace-nowrap",
                      ),
                      attribute.href("/"),
                    ],
                    [html.text(site_name)],
                  ),
                ]),
                // Search input - GitHub style with focused border
                html.div(
                  [attribute.class("max-w-lg w-full hidden sm:block mr-4")],
                  [
                    html.div(
                      [
                        attribute.class(
                          "flex items-center h-7 bg-base-200/70 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary",
                        ),
                      ],
                      [
                        html.div(
                          [attribute.class("pl-2 text-base-content/60")],
                          [
                            html.span(
                              [attribute.class("i-tabler-search w-3.5 h-3.5")],
                              [],
                            ),
                          ],
                        ),
                        html.input([
                          attribute.class(
                            "w-full py-0.5 px-2 text-xs bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                          ),
                          attribute.placeholder("Search or jump to..."),
                          attribute.type_("text"),
                          event.on_input(messages.UserSearchTerm),
                        ]),
                      ],
                    ),
                  ],
                ),
                // Navigation menu - with GitHub-style tabs
                html.div([attribute.class("hidden md:block flex-grow")], [
                  html.nav([attribute.class("flex h-full")], [
                    html.ul(
                      [
                        attribute.id("menu_1_inside"),
                        attribute.class("flex items-center h-full"),
                      ],
                      menu,
                    ),
                  ]),
                ]),
              ]),
              // Right side - GitHub-style action buttons
              html.div(
                [
                  attribute.class(
                    "flex items-center gap-2 text-base-content/70",
                  ),
                ],
                [
                  // Mobile menu button with GitHub styling
                  html.div([attribute.class("md:hidden")], [
                    html.button(
                      [
                        attribute.class(
                          "p-1 rounded hover:bg-base-200 border border-transparent hover:border-base-300 fa fa-bars",
                        ),
                        attribute.aria_label("Toggle navigation"),
                        event.on_click(messages.UserOnGitHubLayoutToggleMenu),
                      ],
                      [
                        html.span(
                          [attribute.class("i-tabler-menu h-5 w-5")],
                          [],
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ]),
          ]),
        ],
      ),
      // Mobile navigation drawer - shown only when menu_is_open is true
      case menu_is_open {
        True ->
          html.div(
            [
              attribute.class(
                "md:hidden bg-base-100 border-b border-base-300 shadow-md",
              ),
            ],
            [
              html.div([attribute.class("container mx-auto px-4 py-3")], [
                // Mobile search input
                html.div([attribute.class("mb-3")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-8 bg-base-200/70 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary",
                      ),
                    ],
                    [
                      html.div([attribute.class("pl-3 text-base-content/60")], [
                        html.span(
                          [attribute.class("i-tabler-search w-4 h-4")],
                          [],
                        ),
                      ]),
                      html.input([
                        attribute.class(
                          "w-full py-1.5 px-2 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                        ),
                        attribute.placeholder("Search or jump to..."),
                        attribute.type_("text"),
                        event.on_input(messages.UserSearchTerm),
                      ]),
                      html.div([attribute.class("pr-3 text-xs")], [
                        html.span(
                          [
                            attribute.class(
                              "px-1 py-0.5 border border-base-300 rounded-sm text-xs text-base-content/50",
                            ),
                          ],
                          [html.text("/")],
                        ),
                      ]),
                    ],
                  ),
                ]),
                // Mobile navigation items
                html.nav([], [
                  html.div(
                    [
                      attribute.class(
                        "text-sm font-medium text-base-content/60 mb-2 px-2",
                      ),
                    ],
                    [html.text("Navigation")],
                  ),
                  html.ul(
                    [
                      attribute.id("mobile_menu_items"),
                      attribute.class("flex flex-col space-y-1"),
                    ],
                    // Create mobile menu items directly from the model data
                    // instead of trying to transform the desktop menu elements
                    case dict.get(model.computed_menus, 1) {
                      Error(_) -> []
                      Ok(mobile_menu_items) -> {
                        list.map(mobile_menu_items, fn(item) {
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

                          // Determine if this is the active page
                          let is_active = model.path == item.1

                          html.li([], [
                            html.a(
                              [
                                attribute.class(
                                  "flex items-center px-3 py-2 rounded-md icon"
                                  <> case is_active {
                                    True -> "bg-primary/10 text-primary"
                                    False ->
                                      "hover:bg-base-200 text-base-content/80"
                                  },
                                ),
                                attribute.href(item.1),
                                event.on_click(
                                  messages.UserOnGitHubLayoutToggleMenu,
                                ),
                              ],
                              [
                                html.div(
                                  [attribute.class("flex items-center gap-2")],
                                  [
                                    // Document icon matching GitHub's style
                                    html.span(
                                      [
                                        attribute.class(
                                          "i-tabler-file "
                                          <> case is_active {
                                            True -> " text-primary"
                                            False -> " text-base-content/60"
                                          },
                                        ),
                                        attribute.aria_hidden(True),
                                      ],
                                      [],
                                    ),
                                    html.text(item.0),
                                  ],
                                ),
                              ],
                            ),
                          ])
                        })
                      }
                    },
                  ),
                ]),
              ]),
            ],
          )
        False -> html.div([], [])
      },
      // Main content area with container
      html.main(
        [attribute.class("container mx-auto px-4 lg:px-5 py-6 w-screen")],
        [
          // Different layout for posts vs pages
          case is_post {
            True -> {
              // Post layout: Content with sidebar, similar to GitHub's repo layout
              html.div([attribute.class("flex flex-col md:flex-row md:gap-6")], [
                // Sidebar (1/3 width on desktop) - Put first in DOM for both mobile and desktop
                html.div([attribute.class("w-full md:w-1/3 mb-6 md:mb-0")], [
                  sidebar,
                ]),
                // Main content area (2/3 width on desktop)
                html.div([attribute.class("w-full md:w-2/3")], [
                  // Title section - at the top for posts, styled like a GitHub issue/PR title
                  html.div([attribute.class("mb-6")], [
                    html.h1(
                      [
                        attribute.class(
                          "text-2xl font-semibold text-base-content mb-4",
                        ),
                      ],
                      [
                        html.text(
                          variables
                          |> dict.get("title")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap(""),
                        ),
                      ],
                    ),
                  ]),
                  // Main content styled like GitHub markdown content
                  html.div(
                    [
                      attribute.id("da-content-box"),
                      attribute.class(
                        "border border-base-300 rounded-md overflow-hidden bg-base-100",
                      ),
                    ],
                    [
                      // Content area with proper GitHub-style padding
                      html.div(
                        [
                          attribute.id("da-content"),
                          attribute.class("px-4 py-4 prose max-w-none"),
                        ],
                        [content],
                      ),
                    ],
                  ),
                ]),
              ])
            }
            False -> {
              // Page layout: Simplified, README-style layout with side-by-side layout on desktop
              html.div([attribute.class("flex flex-col md:flex-row md:gap-6")], [
                // Page header from sidebar parameter - displayed in a sidebar column on desktop
                html.div([attribute.class("w-full md:w-1/3 mb-6 md:mb-0")], [
                  sidebar,
                ]),
                // Content column - takes 2/3 width on desktop
                html.div([attribute.class("w-full md:w-2/3")], [
                  // Main content styled like a GitHub README
                  html.div(
                    [
                      attribute.id("da-content-box"),
                      attribute.class(
                        "border border-base-300 rounded-md overflow-hidden bg-base-100",
                      ),
                    ],
                    [
                      html.div(
                        [
                          attribute.id("da-content"),
                          attribute.class("px-4 py-4 prose max-w-none"),
                        ],
                        [content],
                      ),
                    ],
                  ),
                ]),
              ])
            }
          },
        ],
      ),
      // GitHub-style footer
      html.div(
        [attribute.class("border-t border-base-300 bg-base-100 mt-auto py-8")],
        [
          html.div([attribute.class("container mx-auto px-4 lg:px-5")], [
            html.div(
              [
                attribute.class(
                  "flex flex-col md:flex-row items-center justify-between gap-4",
                ),
              ],
              [
                html.div([attribute.class("flex items-center gap-2")], [
                  html.span(
                    [attribute.class("i-tabler-book text-base-content/60")],
                    [],
                  ),
                  html.span([attribute.class("text-sm text-base-content/60")], [
                    html.text(site_name),
                  ]),
                ]),
                html.p([attribute.class("text-xs text-base-content/60")], [
                  html.text("Using "),
                  html.span([attribute.class("text-secondary font-semibold")], [
                    html.text("github-" <> dom.get_color_scheme()),
                  ]),
                  html.text(" theme"),
                ]),
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}

/// Primary navigation menu generator
///
/// Creates the main site navigation menu styled like GitHub's nav tabs.
///
/// @param model Client model containing menus and current path
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
      list.map(menu_items, fn(menu_item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = {
          let model_type.MenuItem(name:, to:) = menu_item
          #(name, to)
        }
        // Handle empty URLs as links to homepage
        let item = case item.1 {
          "" -> #(item.0, "/")
          _ -> item
        }

        // Generate GitHub-style navigation tabs
        html.li([attribute.class("h-full flex items-center")], [
          html.a(
            [
              // Apply refined GitHub-style tab styling with proper hover states
              attribute.class(
                "px-3 h-full flex items-center text-sm font-medium border-b-2 hover:text-base-content "
                <> case hash == item.1 {
                  True -> "border-primary text-base-content"
                  False ->
                    "border-transparent text-base-content/70 hover:border-base-300/60"
                },
              ),
              attribute.href(item.1),
            ],
            [
              html.div([attribute.class("flex items-center gap-1.5")], [
                // Add document icon matching GitHub's style
                html.span(
                  [
                    attribute.class(
                      "i-tabler-file"
                      <> case hash == item.1 {
                        True -> " text-primary"
                        False -> " text-base-content/60"
                      },
                    ),
                    attribute.aria_hidden(True),
                  ],
                  [],
                ),
                html.text(item.0),
              ]),
            ],
          ),
        ])
      })
    }
  }
}
