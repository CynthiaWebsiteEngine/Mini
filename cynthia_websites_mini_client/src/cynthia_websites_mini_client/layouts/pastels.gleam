//// Pastels Layout Module
////
//// A soft, soothing layout optimized for pastel color schemes.
//// Features:
//// - Gentle transitions and animations
//// - Soft shadows and rounded corners
//// - Spacious layout with comfortable reading width
//// - Single menu with subtle styling
//// - Clean typography optimized for readability

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

/// Page layout for the pastels theme
///
/// Creates a soft, welcoming layout for regular pages with
/// gentle visual elements and smooth transitions.
pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  let menu = menu_1(model)

  let assert Ok(title) =
    decode.run(
      result.unwrap(dict.get(variables, "title"), dynamic.from(option.None)),
      decode.string,
    )
  let assert Ok(description) =
    decode.run(
      result.unwrap(
        dict.get(variables, "description_html"),
        dynamic.from(option.None),
      ),
      decode.string,
    )

  let page_header =
    html.div([attribute.class("mb-12")], [
      html.h1(
        [
          attribute.class(
            "text-3xl sm:text-4xl font-light mb-4 text-base-content text-center",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [attribute.class("text-base-content/80 max-w-2xl mx-auto text-center")],
        description,
      ),
    ])

  pastels_common(content, menu, page_header, variables)
}

/// Post layout for the pastels theme
///
/// Creates a gentle, focused layout for blog posts with
/// subtle metadata display and smooth transitions.
pub fn post_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  let menu = menu_1(model)

  let assert Ok(title) =
    decode.run(
      result.unwrap(dict.get(variables, "title"), dynamic.from(option.None)),
      decode.string,
    )
  let assert Ok(description) =
    decode.run(
      result.unwrap(
        dict.get(variables, "description_html"),
        dynamic.from(option.None),
      ),
      decode.string,
    )

  let post_header =
    html.div([attribute.class("mb-12")], [
      html.h1(
        [
          attribute.class(
            "text-3xl sm:text-4xl font-light mb-4 text-base-content text-center",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [
          attribute.class(
            "text-base-content/80 max-w-2xl mx-auto text-center mb-6",
          ),
        ],
        description,
      ),
      html.div(
        [
          attribute.class(
            "flex flex-wrap gap-x-8 gap-y-2 justify-center text-sm text-base-content/60",
          ),
        ],
        [
          html.div([attribute.class("flex items-center gap-1.5")], [
            html.span([attribute.class("i-tabler-calendar w-4 h-4")], []),
            html.text(
              "Published: "
              <> {
                decode.run(
                  result.unwrap(
                    dict.get(variables, "date_published"),
                    dynamic.from(None),
                  ),
                  decode.string,
                )
              }
              |> result.unwrap("unknown"),
            ),
          ]),
          html.div([attribute.class("flex items-center gap-1.5")], [
            html.span([attribute.class("i-tabler-pencil w-4 h-4")], []),
            html.text(
              "Updated: "
              <> {
                decode.run(
                  result.unwrap(
                    dict.get(variables, "date_modified"),
                    dynamic.from(None),
                  ),
                  decode.string,
                )
              }
              |> result.unwrap("unknown"),
            ),
          ]),
          html.div([attribute.class("flex items-center gap-1.5")], [
            html.span([attribute.class("i-tabler-folder w-4 h-4")], []),
            html.text(
              decode.run(
                result.unwrap(
                  dict.get(variables, "category"),
                  dynamic.from(None),
                ),
                decode.string,
              )
              |> result.unwrap("unknown"),
            ),
          ]),
        ],
      ),
      html.div(
        [attribute.class("flex flex-wrap gap-2 justify-center mt-4")],
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
                  "px-3 py-1 text-xs rounded-full bg-base-200/50 text-base-content/70 hover:bg-base-300/50 transition-colors duration-200",
                ),
                attribute.href("#!/tag/" <> tag),
              ],
              [html.text(tag)],
            )
          }),
      ),
    ])

  pastels_common(content, menu, post_header, variables)
}

/// Primary navigation menu generator
///
/// Creates the main site navigation with soft, pastel-appropriate styling.
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus

  case dict.get(content, 1) {
    Error(_) -> []
    Ok(menu_items) -> {
      list.map(menu_items, fn(item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = {
          let model_type.MenuItem(name:, to:) = item
          #(name, to)
        }
        let item = case item.1 {
          "" -> #(item.0, "/")
          _ -> item
        }

        html.li([], [
          html.a(
            [
              attribute.class(
                "px-3 py-1 rounded-full transition-colors duration-200 "
                <> case hash == item.1 {
                  True -> "bg-base-300/50 text-base-content font-medium"
                  False -> "text-base-content/70 hover:bg-base-200/50"
                },
              ),
              attribute.href(item.1),
            ],
            [html.text(item.0)],
          ),
        ])
      })
    }
  }
}

/// Common layout structure for both pages and posts
///
/// @param content The main content to display
/// @param menu Navigation menu items
/// @param header Page or post header content
/// @param variables Dictionary with page/post metadata
fn pastels_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  header: Element(messages.Msg),
  variables: Dict(String, Dynamic),
) -> Element(messages.Msg) {
  let assert Ok(site_name) = {
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(option.None))
    |> decode.run(decode.string)
  }

  html.div(
    [
      attribute.id("content"),
      attribute.class(
        "min-h-screen flex flex-col bg-gradient-to-br from-base-100 via-base-200/30 to-base-100",
      ),
    ],
    [
      html.header(
        [
          attribute.class(
            "bg-base-100/80 border-b border-base-content/5 sticky top-0 z-10 backdrop-blur-sm shadow-sm",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("flex items-center justify-between h-16")],
              [
                html.a(
                  [
                    attribute.class(
                      "text-base-content/90 text-lg font-light hover:text-base-content transition-colors duration-200",
                    ),
                    attribute.href("/"),
                  ],
                  [html.text(site_name)],
                ),
                html.nav([attribute.class("hidden sm:block")], [
                  html.ul(
                    [
                      attribute.id("menu_1_inside"),
                      attribute.class("flex items-center space-x-1"),
                    ],
                    menu,
                  ),
                ]),
                html.div([attribute.class("relative w-40 sm:w-48")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-8 bg-base-200/70 border border-base-300/20 rounded-full focus-within:border-base-content/20 transition-all duration-200 hover:bg-base-200/90",
                      ),
                    ],
                    [
                      html.input([
                        attribute.class(
                          "w-full py-1 px-4 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/40",
                        ),
                        attribute.placeholder("Search"),
                        attribute.type_("text"),
                        event.on_input(messages.UserSearchTerm),
                      ]),
                      html.span(
                        [
                          attribute.class(
                            "absolute right-3 text-base-content/40",
                          ),
                        ],
                        [
                          html.span(
                            [attribute.class("i-tabler-search w-3.5 h-3.5")],
                            [],
                          ),
                        ],
                      ),
                    ],
                  ),
                ]),
              ],
            ),
            html.div([attribute.class("sm:hidden mt-2")], [
              html.ul(
                [
                  attribute.id("menu_1_inside_mobile"),
                  attribute.class("flex flex-wrap gap-2 pb-2"),
                ],
                menu,
              ),
            ]),
          ]),
        ],
      ),
      html.main(
        [attribute.class("flex-grow container mx-auto px-4 sm:px-6 py-12")],
        [
          html.div(
            [
              attribute.class("max-w-3xl mx-auto relative"),
              // Add decorative background elements
              attribute.style(
                "background",
                "radial-gradient(circle at top left, var(--p) / 3%, transparent 25%), radial-gradient(circle at bottom right, var(--p) / 3%, transparent 25%)",
              ),
            ],
            [
              header,
              html.div(
                [
                  attribute.class(
                    "prose max-w-none rounded-xl p-6 bg-base-100/80 backdrop-blur-sm shadow-sm ring-1 ring-base-content/5 relative overflow-hidden",
                  ),
                ],
                [
                  // Add subtle decorative corner elements
                  html.div(
                    [
                      attribute.class(
                        "absolute top-0 left-0 w-16 h-16 -translate-x-1/2 -translate-y-1/2 opacity-10",
                      ),
                      attribute.style(
                        "background",
                        "radial-gradient(circle, var(--p) 0%, transparent 70%)",
                      ),
                    ],
                    [],
                  ),
                  html.div(
                    [
                      attribute.class(
                        "absolute bottom-0 right-0 w-16 h-16 translate-x-1/2 translate-y-1/2 opacity-10",
                      ),
                      attribute.style(
                        "background",
                        "radial-gradient(circle, var(--p) 0%, transparent 70%)",
                      ),
                    ],
                    [],
                  ),
                  content,
                ],
              ),
            ],
          ),
        ],
      ),
      html.footer(
        [
          attribute.class(
            "bg-gradient-to-b from-base-200/50 to-base-100 border-t border-base-content/5 py-8 mt-auto",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("text-center text-sm text-base-content/50")],
              [
                html.text("Made with "),
                html.a(
                  [
                    attribute.class(
                      "text-base-content/70 hover:text-base-content",
                    ),
                    attribute.href(
                      "https://github.com/CynthiaWebsiteEngine/Mini",
                    ),
                  ],
                  [html.text("Cynthia Mini")],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}
