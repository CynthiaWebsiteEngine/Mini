//// Frutiger Aero Layout Module
////
//// A bold, glossy layout inspired by the Frutiger Aero design style.
//// Features:
//// - Glossy, translucent elements
//// - Sharp contrasts and bold colors
//// - Glass-like effects and gradients
//// - Modern, attention-grabbing design

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

/// Page layout for the frutiger theme
///
/// Creates a bold, glossy layout for regular pages with
/// striking visual elements and glass-like effects.
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
            "text-4xl sm:text-5xl font-bold mb-6 text-base-content text-center bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-accent",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [
          attribute.class(
            "text-base-content/90 max-w-2xl mx-auto text-center text-lg",
          ),
        ],
        description,
      ),
    ])

  frutiger_common(content, menu, page_header, variables)
}

/// Post layout for the frutiger theme
///
/// Creates a bold, modern layout for blog posts with
/// eye-catching metadata display and glossy effects.
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
            "text-4xl sm:text-5xl font-bold mb-6 text-base-content text-center bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-accent",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [
          attribute.class(
            "text-base-content/90 max-w-2xl mx-auto text-center mb-8 text-lg",
          ),
        ],
        description,
      ),
      html.div(
        [
          attribute.class(
            "flex flex-wrap gap-6 justify-center text-base text-base-content/80 bg-base-200/30 backdrop-blur-md p-4 rounded-2xl border border-base-content/10",
          ),
        ],
        [
          html.div([attribute.class("flex items-center gap-2")], [
            html.span([attribute.class("i-tabler-calendar w-5 h-5")], []),
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
          html.div([attribute.class("flex items-center gap-2")], [
            html.span([attribute.class("i-tabler-pencil w-5 h-5")], []),
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
          html.div([attribute.class("flex items-center gap-2")], [
            html.span([attribute.class("i-tabler-folder w-5 h-5")], []),
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
                  "px-4 py-1.5 text-sm rounded-xl bg-base-300/40 backdrop-blur-sm text-base-content/90 hover:bg-base-300/60 transition-all duration-200 border border-base-content/10 shadow-sm hover:shadow-md",
                ),
                attribute.href("#!/tag/" <> tag),
              ],
              [html.text(tag)],
            )
          }),
      ),
    ])

  frutiger_common(content, menu, post_header, variables)
}

/// Primary navigation menu generator
///
/// Creates the main site navigation with glossy, attention-grabbing styling.
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
                "px-4 py-2 rounded-xl transition-all duration-200 backdrop-blur-sm border "
                <> case hash == item.1 {
                  True ->
                    "bg-primary/20 text-primary-content font-bold border-primary/30 shadow-lg shadow-primary/20"
                  False ->
                    "text-base-content/80 hover:bg-base-300/30 border-transparent hover:border-base-content/10"
                },
              ),
              attribute.href(utils.phone_home_url() <> "#" <> item.1),
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
fn frutiger_common(
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
      attribute.class("min-h-screen flex flex-col relative overflow-hidden"),
      attribute.style(
        "background",
        "linear-gradient(135deg, var(--p) / 15%, transparent 45%) fixed,
         linear-gradient(225deg, var(--s) / 15%, transparent 45%) fixed,
         linear-gradient(315deg, var(--a) / 15%, transparent 45%) fixed,
         linear-gradient(45deg, var(--p) / 15%, transparent 45%) fixed,
         radial-gradient(circle at 25% 25%, var(--p) / 20%, transparent 50%) fixed,
         radial-gradient(circle at 75% 75%, var(--s) / 20%, transparent 50%) fixed,
         radial-gradient(circle at 50% 50%, var(--a) / 15%, transparent 55%) fixed,
         var(--b1)",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "absolute inset-0 overflow-hidden pointer-events-none",
          ),
        ],
        [
          html.div(
            [
              attribute.class(
                "absolute -top-32 -left-32 w-96 h-96 rounded-full blur-3xl [animation:float_20s_ease-in-out_infinite] opacity-50 after:absolute after:inset-0 after:rounded-full after:bg-gradient-to-br after:from-primary/40 after:to-transparent after:rotate-45",
              ),
              attribute.style(
                "background",
                "radial-gradient(circle at 30% 30%, var(--p), var(--p-focus) 70%)",
              ),
            ],
            [],
          ),
          html.div(
            [
              attribute.class(
                "absolute -bottom-32 -right-32 w-96 h-96 rounded-full blur-3xl [animation:float-slow_25s_ease-in-out_infinite] opacity-50 after:absolute after:inset-0 after:rounded-full after:bg-gradient-to-tl after:from-secondary/40 after:to-transparent after:rotate-45",
              ),
              attribute.style(
                "background",
                "radial-gradient(circle at 70% 70%, var(--s), var(--s-focus) 70%)",
              ),
            ],
            [],
          ),
          html.div(
            [
              attribute.class(
                "absolute top-1/3 right-1/4 w-64 h-64 rounded-full blur-3xl [animation:float-slower_30s_ease-in-out_infinite] opacity-50 after:absolute after:inset-0 after:rounded-full after:bg-gradient-to-tr after:from-accent/40 after:to-transparent after:rotate-45",
              ),
              attribute.style(
                "background",
                "radial-gradient(circle at 50% 50%, var(--a), var(--a-focus) 70%)",
              ),
            ],
            [],
          ),
          html.div(
            [
              attribute.class(
                "absolute inset-0 opacity-20 mix-blend-overlay [animation:shimmer_8s_ease-in-out_infinite] will-change-transform",
              ),
              attribute.style(
                "background",
                "repeating-linear-gradient(35deg, var(--p), var(--s) 2px, transparent 4px, transparent 8px)",
              ),
            ],
            [],
          ),
        ],
      ),
      html.header(
        [
          attribute.class(
            "bg-base-content/5 bg-opacity-90 sticky top-0 z-10 border-b border-primary/20 after:absolute after:inset-0 after:bg-gradient-to-r after:from-primary/20 after:via-secondary/20 after:to-accent/20 pointer-events-none will-change-transform",
          ),
        ],
        [
          html.div(
            [
              attribute.class(
                "container mx-auto px-4 sm:px-6 relative pointer-events-auto",
              ),
            ],
            [
              html.div(
                [attribute.class("flex items-center justify-between h-20")],
                [
                  html.a(
                    [
                      attribute.class(
                        "text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-accent hover:scale-105 transition-all duration-300",
                      ),
                      attribute.href("/"),
                    ],
                    [html.text(site_name)],
                  ),
                  html.nav([attribute.class("hidden sm:block")], [
                    html.ul(
                      [
                        attribute.id("menu_1_inside"),
                        attribute.class("flex items-center space-x-2"),
                      ],
                      menu,
                    ),
                  ]),
                  html.div([attribute.class("relative w-48 sm:w-64")], [
                    html.div(
                      [
                        attribute.class(
                          "flex items-center h-10 bg-base-content/5 backdrop-blur-sm border border-primary/20 rounded-xl focus-within:border-primary/40 focus-within:shadow-md focus-within:shadow-primary/20 transition-all duration-300 hover:bg-base-content/10",
                        ),
                      ],
                      [
                        html.input([
                          attribute.class(
                            "w-full py-2 px-4 text-base bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/40",
                          ),
                          attribute.placeholder("Search"),
                          attribute.type_("text"),
                          event.on_input(messages.UserSearchTerm),
                        ]),
                        html.span(
                          [
                            attribute.class(
                              "absolute right-3 text-base-content/60",
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
            ],
          ),
        ],
      ),
      html.main(
        [attribute.class("flex-grow container mx-auto px-4 sm:px-6 py-12")],
        [
          html.div([attribute.class("max-w-4xl mx-auto")], [
            header,
            html.div(
              [
                attribute.class(
                  "prose max-w-none rounded-2xl p-8 bg-base-content/5 backdrop-blur-xl shadow-xl ring-1 ring-primary/20 relative overflow-hidden hover:shadow-2xl hover:bg-base-content/10 transition-all duration-300",
                ),
              ],
              [
                html.div(
                  [
                    attribute.class(
                      "absolute -top-1/2 -left-1/2 w-full h-full bg-gradient-to-br from-primary/20 to-transparent [animation:rotate_15s_ease-in-out_infinite] will-change-transform",
                    ),
                  ],
                  [],
                ),
                html.div(
                  [
                    attribute.class(
                      "absolute -bottom-1/2 -right-1/2 w-full h-full bg-gradient-to-tl from-secondary/20 via-accent/10 to-transparent [animation:rotate_45s_linear_infinite_reverse]",
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
            "bg-gradient-to-b from-base-content/5 to-base-content/10 border-t border-primary/20 py-10 mt-auto backdrop-blur-sm relative overflow-hidden",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [
                attribute.class(
                  "text-center text-base text-base-content bg-base-content/5 backdrop-blur-sm p-4 rounded-2xl border border-primary/20 inline-block mx-auto relative overflow-hidden hover:bg-base-content/10 transition-all duration-300",
                ),
              ],
              [
                html.div(
                  [
                    attribute.class(
                      "absolute inset-0 bg-gradient-to-r from-transparent via-primary/20 to-transparent [animation:shimmer_3s_linear_infinite]",
                    ),
                  ],
                  [],
                ),
                html.text("Made with "),
                html.a(
                  [
                    attribute.class(
                      "font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-accent transition-all duration-300",
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
