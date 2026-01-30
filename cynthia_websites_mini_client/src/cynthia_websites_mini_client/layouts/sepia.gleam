//// Sepia Layout Module
////
//// A classic, book-inspired layout optimized for long-form reading.
//// Features:
//// - Traditional typography with serif fonts
//// - Paper-like textures and warm colors
//// - Comfortable reading width and line height
//// - Subtle ornamental details
//// - Focus on readability and classic aesthetics

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

/// Page layout for the sepia theme
///
/// Creates a classic, book-like layout for regular pages with
/// traditional typography and warm visual elements.
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
            "text-4xl font-serif mb-6 text-primary text-center italic",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [
          attribute.class(
            "text-base-content/80 max-w-2xl mx-auto text-center font-serif text-lg leading-relaxed",
          ),
        ],
        description,
      ),
    ])

  sepia_common(content, menu, page_header, variables)
}

/// Post layout for the sepia theme
///
/// Creates a traditional book-like layout for blog posts with
/// elegant metadata presentation and classic typography.
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
            "text-4xl font-serif mb-6 text-primary text-center italic",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [
          attribute.class(
            "text-base-content/80 max-w-2xl mx-auto text-center font-serif text-lg leading-relaxed mb-8",
          ),
        ],
        description,
      ),
      html.div(
        [
          attribute.class(
            "flex flex-wrap gap-8 justify-center text-base text-base-content/70 font-serif",
          ),
        ],
        [
          html.div([attribute.class("flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-calendar text-primary/70"),
                attribute.aria_hidden(True),
              ],
              [],
            ),
            html.text(
              "Published "
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
          html.div([attribute.class("flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-pencil text-primary/70"),
                attribute.aria_hidden(True),
              ],
              [],
            ),
            html.text(
              "Updated "
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
          html.div([attribute.class("flex items-center gap-2")], [
            html.span(
              [
                attribute.class("i-tabler-folder text-primary/70"),
                attribute.aria_hidden(True),
              ],
              [],
            ),
            html.text(
              "Filed under "
              <> {
                decode.run(
                  result.unwrap(
                    dict.get(variables, "category"),
                    dynamic.from(None),
                  ),
                  decode.string,
                )
              }
              |> result.unwrap("unknown"),
            ),
          ]),
        ],
      ),
      html.div(
        [attribute.class("flex flex-wrap gap-2 justify-center mt-6")],
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
                  "px-3 py-1 text-sm rounded-md bg-base-200 text-base-content/70 hover:bg-base-300 transition-colors duration-200 font-serif italic",
                ),
                attribute.href("#!/tag/" <> tag),
              ],
              [html.text(tag)],
            )
          }),
      ),
    ])

  sepia_common(content, menu, post_header, variables)
}

/// Primary navigation menu generator
///
/// Creates the main site navigation with classic, book-inspired styling.
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus

  case dict.get(content, 1) {
    Error(_) -> []
    Ok(menu_items) -> {
      list.map(menu_items, fn(item) {
        let item = case item {
          model_type.MenuItem(name:, to: "") ->
            model_type.MenuItem(name:, to: "/")
          _ -> item
        }

        html.li([], [
          html.a(
            [
              attribute.class(
                "px-4 py-2 transition-colors duration-200 font-serif "
                <> case hash == item.to {
                  True -> "text-primary italic border-b-2 border-primary/30"
                  False ->
                    "text-base-content/70 hover:text-primary hover:italic"
                },
              ),
              attribute.href(item.to),
            ],
            [html.text(item.name)],
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
fn sepia_common(
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
      attribute.class("min-h-screen flex flex-col bg-base-100"),
      attribute.style(
        "background-image",
        "url('data:image/png;base64,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')",
      ),
    ],
    [
      html.header(
        [
          attribute.class(
            "bg-base-200/80 backdrop-blur-sm border-b border-base-300 sticky top-0 z-10",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("flex items-center justify-between h-20")],
              [
                html.a(
                  [
                    attribute.class(
                      "text-xl font-serif italic text-primary hover:text-primary/80 transition-colors duration-200",
                    ),
                    attribute.href("/"),
                  ],
                  [html.text(site_name)],
                ),
                html.nav([attribute.class("hidden sm:block")], [
                  html.ul(
                    [
                      attribute.id("menu_1_inside"),
                      attribute.class("flex items-center space-x-4"),
                    ],
                    menu,
                  ),
                ]),
                html.div([attribute.class("relative w-48 sm:w-64")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-10 bg-base-300/50 border border-base-300 rounded-md focus-within:border-primary/40 transition-colors duration-200",
                      ),
                    ],
                    [
                      html.input([
                        attribute.class(
                          "w-full py-2 px-4 text-base bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/40 font-serif",
                        ),
                        attribute.placeholder("Search..."),
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
                            [attribute.class("i-tabler-search w-4 h-4")],
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
                  attribute.class("flex flex-wrap gap-2 pb-4"),
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
          html.div([attribute.class("max-w-4xl mx-auto relative")], [
            html.div(
              [
                attribute.class(
                  "absolute -top-12 -left-16 text-8xl font-serif text-primary/10 select-none hidden lg:block",
                ),
              ],
              [
                html.text(
                  case
                    dict.get(variables, "title")
                    |> result.unwrap(dynamic.from(""))
                    |> decode.run(decode.string)
                  {
                    Ok(title) ->
                      case string.first(title) {
                        Ok(first) -> first
                        Error(_) -> "•"
                      }
                    Error(_) -> "•"
                  },
                ),
              ],
            ),
            header,
            html.div(
              [
                attribute.class(
                  "prose max-w-none bg-base-100 p-8 sm:p-12 rounded-lg shadow-md border border-base-300 relative font-serif leading-relaxed",
                ),
              ],
              [
                html.div(
                  [
                    attribute.class(
                      "absolute top-4 left-4 w-8 h-8 border-l-2 border-t-2 border-primary/20",
                    ),
                  ],
                  [],
                ),
                html.div(
                  [
                    attribute.class(
                      "absolute top-4 right-4 w-8 h-8 border-r-2 border-t-2 border-primary/20",
                    ),
                  ],
                  [],
                ),
                html.div(
                  [
                    attribute.class(
                      "absolute bottom-4 left-4 w-8 h-8 border-l-2 border-b-2 border-primary/20",
                    ),
                  ],
                  [],
                ),
                html.div(
                  [
                    attribute.class(
                      "absolute bottom-4 right-4 w-8 h-8 border-r-2 border-b-2 border-primary/20",
                    ),
                  ],
                  [],
                ),
                content,
              ],
            ),
          ]),
        ],
      ),
      html.footer(
        [
          attribute.class(
            "bg-base-200/80 backdrop-blur-sm border-t border-base-300 py-8 mt-auto",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("text-center text-base-content/60 font-serif")],
              [
                html.text("Made with "),
                html.a(
                  [
                    attribute.class(
                      "text-primary hover:text-primary/80 transition-colors duration-200 italic",
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
