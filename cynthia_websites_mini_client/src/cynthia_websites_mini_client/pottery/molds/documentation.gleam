//// Documentation Layout Module
////
//// A layout inspired by the Rust Book and other documentation websites.
//// Features:
//// - Collapsible sidebar for navigation
//// - Clean typography optimized for reading long-form content
//// - Mobile-responsive design
//// - Multiple theme options (light, dark, sepia, etc.)

import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import houdini
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import odysseus

/// Page layout handler for the Documentation theme
///
/// This function creates the layout structure for regular pages (documentation pages).
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
  let menu = menu_1(model)

  let assert Ok(title) =
    dict.get(variables, "title")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  let page_header =
    html.div([attribute.class("mb-6")], [
      html.div([attribute.class("mb-5")], [
        html.h1(
          [attribute.class("text-2xl font-semibold text-base-content mb-3")],
          [
            element.unsafe_raw_html(
              "span",
              "span",
              [],
              houdini.escape(utils.js_trim(odysseus.unescape(title))),
            ),
          ],
        ),
        element.unsafe_raw_html(
          "div",
          "div",
          [attribute.class("text-sm text-base-content/80 mb-2")],
          description,
        ),
      ]),
    ])

  documentation_common(content, menu, page_header, variables, model)
}

/// Post layout handler for the Documentation theme
///
/// This function creates the layout structure for blog posts/articles.
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
  let menu = menu_1(model)
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  let post_meta =
    html.div([attribute.class("mb-6")], [
      html.div([attribute.class("prose-sm")], [
        html.div([attribute.class("mb-4 pb-4 border-b border-base-300")], [
          html.h2(
            [attribute.class("text-lg font-medium text-base-content mb-2")],
            [html.text("Article Information")],
          ),
          html.div([attribute.class("flex items-center gap-2 mb-2")], [
            html.span(
              [attribute.class("i-tabler-calendar text-base-content/60")],
              [],
            ),
            html.div([attribute.class("text-sm")], [
              html.text(
                "Published: "
                <> {
                  variables
                  |> dict.get("date_published")
                  |> result.unwrap(dynamic.from(None))
                  |> decode.run(decode.string)
                  |> result.unwrap("unknown")
                },
              ),
            ]),
          ]),
          html.div([attribute.class("flex items-center gap-2 mb-2")], [
            html.span(
              [attribute.class("i-tabler-edit text-base-content/60")],
              [],
            ),
            html.div([attribute.class("text-sm")], [
              html.text(
                "Last updated: "
                <> {
                  variables
                  |> dict.get("date_modified")
                  |> result.unwrap(dynamic.from(None))
                  |> decode.run(decode.string)
                  |> result.unwrap("unknown")
                },
              ),
            ]),
          ]),
          html.div([attribute.class("flex items-center gap-2 mb-2")], [
            html.span(
              [attribute.class("i-tabler-folder text-base-content/60")],
              [],
            ),
            html.div([attribute.class("text-sm")], [
              html.text(
                "Category: "
                <> {
                  variables
                  |> dict.get("category")
                  |> result.unwrap(dynamic.from(None))
                  |> decode.run(decode.string)
                  |> result.unwrap("Uncategorized")
                },
              ),
            ]),
          ]),
        ]),
        html.div([attribute.class("mb-4")], [
          html.h3(
            [attribute.class("text-md font-medium text-base-content mb-2")],
            [html.text("Tags")],
          ),
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
                      "inline-block px-2 py-1 text-xs rounded bg-base-200 text-base-content/90 hover:bg-base-300 transition-colors",
                    ),
                    attribute.href("#!/tag/" <> tag),
                  ],
                  [html.text(tag)],
                )
              }),
          ),
        ]),
        html.div([attribute.class("mb-4")], [
          html.h3(
            [attribute.class("text-md font-medium text-base-content mb-2")],
            [html.text("Overview")],
          ),
          element.unsafe_raw_html(
            "div",
            "div",
            [attribute.class("text-sm text-base-content/80")],
            description,
          ),
        ]),
      ]),
    ])

  documentation_common(content, menu, post_meta, variables, model)
}

/// Shared layout structure for both pages and posts
///
/// @param content The main page/post content
/// @param menu List of primary navigation menu elements
/// @param sidebar Content for the sidebar region (varies by page type)
/// @param variables Dictionary containing metadata for the page/post
/// @param model Model with application state
/// @return A complete HTML layout structure
fn documentation_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  sidebar_content: Element(messages.Msg),
  variables: Dict(String, Dynamic),
  model: model_type.Model,
) -> Element(messages.Msg) {
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

  let sidebar_open =
    result.is_ok(dict.get(model.other, "documentation-sidebar-open"))

  html.div(
    [
      attribute.id("content"),
      attribute.class("min-h-screen flex flex-col bg-base-100"),
    ],
    [
      html.header(
        [
          attribute.class(
            "bg-base-200 border-b border-base-300 sticky top-0 z-30 shadow-sm",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6 lg:px-8")], [
            html.div(
              [attribute.class("flex items-center justify-between h-14")],
              [
                html.div([attribute.class("flex items-center gap-3")], [
                  html.button(
                    [
                      attribute.class(
                        "lg:hidden p-1 rounded-md text-base-content/70 hover:bg-base-300/50 fa fa-bars",
                      ),
                      attribute.aria_label("Toggle navigation"),
                      event.on_click(
                        messages.UserOnDocumentationLayoutToggleSidebar,
                      ),
                    ],
                    [html.span([attribute.class("i-tabler-menu h-5 w-5")], [])],
                  ),
                ]),
                html.div([attribute.class("h-full lg:flex-1")], [
                  html.img([
                    attribute.src(
                      utils.phone_home_url() <> "assets/site_icon.png",
                    ),
                    attribute.class("h-full max-w-full max-h-full "),
                  ]),
                ]),
                html.div([attribute.class("flex items-center gap-3")], [
                  html.div([attribute.class("relative hidden sm:block")], [
                    html.div(
                      [
                        attribute.class(
                          "flex items-center h-8 bg-base-100 border border-base-300 rounded-md pl-3 pr-2",
                        ),
                      ],
                      [
                        html.span(
                          [attribute.class("text-base-content/50 mr-2")],
                          [
                            html.span(
                              [attribute.class("i-tabler-search w-4 h-4")],
                              [],
                            ),
                          ],
                        ),
                        html.input([
                          attribute.class(
                            "w-52 bg-transparent border-0 focus:outline-none text-sm text-base-content placeholder-base-content/50",
                          ),
                          attribute.placeholder("Search " <> site_name <> "..."),
                          attribute.type_("text"),
                          event.on_input(messages.UserSearchTerm),
                        ]),
                      ],
                    ),
                  ]),
                  html.button(
                    [
                      attribute.class(
                        "sm:hidden p-1 rounded-md text-base-content/70 hover:bg-base-300/50",
                      ),
                    ],
                    [
                      html.span(
                        [attribute.class("i-tabler-search h-5 w-5")],
                        [],
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ]),
        ],
      ),
      html.div([attribute.class("flex-grow flex overflow-hidden")], [
        html.div(
          [
            attribute.id("documentation-sidebar"),
            attribute.class(
              "bg-base-200 border-r border-base-300 w-72 shrink-0 overflow-y-auto fixed top-14 bottom-0 left-0 z-20 transition-transform duration-300 transform "
              <> case sidebar_open {
                True -> "translate-x-0"
                False -> "-translate-x-full lg:translate-x-0"
              },
            ),
          ],
          [
            html.div([attribute.class("p-4")], [
              html.div([attribute.class("mb-4")], [
                html.h3(
                  [
                    attribute.class(
                      "text-base-content/80 text-xs font-semibold uppercase tracking-wider mb-3",
                    ),
                  ],
                  [html.text(site_name)],
                ),
                html.ul(
                  [
                    attribute.id("menu_1_inside"),
                    attribute.class("menu menu-padding-sm space-y-1"),
                  ],
                  menu,
                ),
              ]),
            ]),
          ],
        ),
        html.div(
          [
            attribute.class(
              "flex-1 overflow-y-auto ml-0 lg:ml-72 min-h-[calc(100vh-3.5rem)]",
            ),
          ],
          [
            html.div(
              [
                attribute.class(
                  "container mx-auto px-4 sm:px-6 py-8 max-w-3xl lg:max-w-4xl overflow-x-hidden",
                ),
              ],
              [
                case is_post {
                  True -> {
                    html.div([], [
                      html.h1(
                        [
                          attribute.class(
                            "text-3xl font-bold text-base-content mb-8 pb-2 border-b border-base-300",
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
                      html.div(
                        [
                          attribute.class(
                            "prose prose-documentation max-w-none mb-8",
                          ),
                        ],
                        [content],
                      ),
                    ])
                  }
                  False -> {
                    html.div([], [
                      sidebar_content,
                      html.div(
                        [
                          attribute.class(
                            "prose prose-documentation max-w-none mb-8",
                          ),
                        ],
                        [content],
                      ),
                    ])
                  }
                },
                // Navigation buttons
                {
                  case dict.get(model.computed_menus, 1) {
                    Ok(menu_items) -> {
                      let #(prev, next) =
                        find_prev_next_links(menu_items, model.path)
                      html.div(
                        [
                          attribute.class(
                            "mt-8 flex justify-between border-t border-base-300 pt-4",
                          ),
                        ],
                        [
                          // Previous button
                          case prev {
                            Some(item) -> {
                              html.a(
                                [
                                  attribute.class(
                                    "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-base-300/50 text-base-content/80 hover:text-base-content",
                                  ),
                                  attribute.href(
                                    utils.phone_home_url() <> "#" <> item.to,
                                  ),
                                ],
                                [
                                  html.span(
                                    [attribute.class("i-tabler-chevron-left")],
                                    [],
                                  ),
                                  html.div([attribute.class("flex flex-col")], [
                                    html.span(
                                      [
                                        attribute.class(
                                          "text-xs text-base-content/60",
                                        ),
                                      ],
                                      [html.text("Previous")],
                                    ),
                                    html.span([], [html.text(item.name)]),
                                  ]),
                                ],
                              )
                            }
                            None -> html.div([], [])
                          },
                          // Next button
                          case next {
                            Some(item) -> {
                              html.a(
                                [
                                  attribute.class(
                                    "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-base-300/50 text-base-content/80 hover:text-base-content",
                                  ),
                                  attribute.href(
                                    utils.phone_home_url() <> "#" <> item.to,
                                  ),
                                ],
                                [
                                  html.div(
                                    [
                                      attribute.class(
                                        "flex flex-col text-right",
                                      ),
                                    ],
                                    [
                                      html.span(
                                        [
                                          attribute.class(
                                            "text-xs text-base-content/60",
                                          ),
                                        ],
                                        [html.text("Next")],
                                      ),
                                      html.span([], [html.text(item.name)]),
                                    ],
                                  ),
                                  html.span(
                                    [attribute.class("i-tabler-chevron-right")],
                                    [],
                                  ),
                                ],
                              )
                            }
                            None -> html.div([], [])
                          },
                        ],
                      )
                    }
                    Error(_) -> html.div([], [])
                  }
                },
              ],
            ),
          ],
        ),
        case is_post {
          True -> {
            html.div(
              [
                attribute.class(
                  "hidden xl:block w-64 shrink-0 border-l border-base-300 bg-base-100 overflow-y-auto fixed top-14 bottom-0 right-0",
                ),
              ],
              [
                html.div([attribute.class("p-4 sticky top-0")], [
                  sidebar_content,
                ]),
              ],
            )
          }
          False -> {
            html.div([], [])
          }
        },
      ]),
      html.footer(
        [
          attribute.class(
            "bg-base-200 border-t border-base-300 py-6 text-center text-sm text-base-content/70",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4")], [
            html.p([], [
              html.text("Built with "),
              html.a(
                [
                  attribute.class("text-primary hover:underline"),
                  attribute.href("https://github.com/CynthiaWebsiteEngine/Mini"),
                ],
                [html.text("Cynthia Mini")],
              ),
              html.text(" using the Documentation layout"),
            ]),
          ]),
        ],
      ),
      case sidebar_open {
        True -> {
          html.div(
            [
              attribute.class(
                "lg:hidden fixed inset-0 bg-base-content/20 z-10 backdrop-blur-sm",
              ),
              event.on_click(messages.UserOnDocumentationLayoutToggleSidebar),
            ],
            [],
          )
        }
        False -> {
          html.div([], [])
        }
      },
    ],
  )
}

/// Primary navigation menu generator for documentation layout
///
/// Creates the main documentation navigation menu.
///
/// @param model Client model containing menus and current path
/// @return List of HTML elements representing menu items
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus

  case dict.get(content, 1) {
    Error(_) -> []
    Ok(menu_items) -> {
      list.map(menu_items, fn(item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = case item.to {
          "" -> model_type.MenuItem(item.name, "/")
          _ -> item
        }
        let model_type.MenuItem(name:, to:) = item
        let is_active = hash == to

        html.li([], [
          html.a(
            [
              attribute.class(case is_active {
                True ->
                  "flex items-center px-3 py-2 rounded-md bg-primary/10 text-primary font-medium"
                False ->
                  "flex items-center px-3 py-2 rounded-md hover:bg-base-300/50 text-base-content/80 hover:text-base-content"
              }),
              attribute.href(utils.phone_home_url() <> "#" <> to),
              event.on_click(messages.UserOnDocumentationLayoutToggleSidebar),
            ],
            [
              html.div([attribute.class("flex items-center gap-2")], [
                html.span(
                  [
                    attribute.class(
                      "i-tabler-file"
                      <> case is_active {
                        True -> " text-primary"
                        False -> " text-base-content/60"
                      },
                    ),
                    attribute.aria_hidden(True),
                  ],
                  [],
                ),
                element.unsafe_raw_html("span", "span", [], name),
              ]),
            ],
          ),
        ])
      })
    }
  }
}

/// Find the previous and next menu items relative to the current path
fn find_prev_next_links(
  menu_items: List(model_type.MenuItem),
  current_path: String,
) -> #(Option(model_type.MenuItem), Option(model_type.MenuItem)) {
  find_prev_next_links_looped(menu_items, current_path, None)
}

fn find_prev_next_links_looped(
  left_menu_items: List(model_type.MenuItem),
  current_path: String,
  last_item: Option(model_type.MenuItem),
) -> #(Option(model_type.MenuItem), Option(model_type.MenuItem)) {
  case left_menu_items, last_item {
    // End of list, nothing found
    [], None -> #(None, None)
    // End of list after finding current, so we know the previous but no next
    [], Some(last) -> #(Some(last), None)
    // Single item with no history
    [current], None -> {
      case current.to == current_path {
        True -> #(None, None)
        False -> #(None, Some(current))
      }
    }
    // Single item with history
    [current], Some(last) -> {
      case current.to == current_path {
        True -> #(Some(last), None)
        False -> #(Some(last), Some(current))
      }
    }
    // Multiple items, no history yet
    [head, ..rest], None -> {
      case head.to == current_path {
        True -> {
          case list.first(rest) {
            Ok(next) -> #(None, Some(next))
            Error(_) -> #(None, None)
          }
        }
        False -> find_prev_next_links_looped(rest, current_path, Some(head))
      }
    }
    // Multiple items with history
    [head, ..rest], Some(last) -> {
      case head.to == current_path {
        True -> {
          case list.first(rest) {
            Ok(next) -> #(Some(last), Some(next))
            Error(_) -> #(Some(last), None)
          }
        }
        False -> find_prev_next_links_looped(rest, current_path, Some(head))
      }
    }
  }
}
