//// Minimalist Layout Module
////
//// A clean, distraction-free layout focused on content.
//// - Extremely simplified UI with minimal visual elements
//// - Focus on typography and readability
//// - Single menu with clean, understated styling
//// - Centered content layout with optimal reading width

// Common imports for layouts
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Minimalist page layout
///
/// Creates a clean, focused layout for regular pages with
/// emphasis on readability and minimal distractions.
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
    as "Could not determine title"
  let assert Ok(description) =
    decode.run(
      result.unwrap(
        dict.get(variables, "description_html"),
        dynamic.from(option.None),
      ),
      decode.string,
    )

  let page_header =
    html.div([attribute.class("mb-8")], [
      html.h1(
        [
          attribute.class(
            "text-2xl sm:text-3xl font-light mb-4 text-base-content",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [attribute.class("text-base-content/80 max-w-prose")],
        description,
      ),
    ])

  minimalist_common(content, menu, page_header, variables)
}

/// Minimalist post layout
///
/// Creates a clean layout for blog posts with minimal distractions
/// and subtle metadata display.
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
    html.div([attribute.class("mb-8")], [
      html.h1(
        [
          attribute.class(
            "text-2xl sm:text-3xl font-light mb-3 text-base-content",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "div",
        [attribute.class("text-base-content/80 max-w-prose mb-6")],
        description,
      ),
      html.div(
        [
          attribute.class(
            "flex flex-wrap gap-x-6 gap-y-2 text-sm text-base-content/60 border-t border-base-content/10 pt-3",
          ),
        ],
        [
          html.div([attribute.class("flex items-center gap-1")], [
            html.span([attribute.class("i-tabler-calendar-event w-4 h-4")], []),
            html.text(
              "Published: "
              <> {
                decode.run(
                  result.unwrap(
                    dict.get(variables, "date_published"),
                    dynamic.from("unknown"),
                  ),
                  decode.string,
                )
              }
              |> result.unwrap("unknown"),
            ),
          ]),
          html.div([attribute.class("flex items-center gap-1")], [
            html.span([attribute.class("i-tabler-edit w-4 h-4")], []),
            html.text(
              "Updated: "
              <> {
                decode.run(
                  result.unwrap(
                    dict.get(variables, "date_modified"),
                    dynamic.from("unknown"),
                  ),
                  decode.string,
                )
              }
              |> result.unwrap("unknown"),
            ),
          ]),
          html.div([attribute.class("flex items-center gap-1")], [
            html.span([attribute.class("i-tabler-category w-4 h-4")], []),
            html.text(
              "Category: "
              <> decode.run(
                result.unwrap(
                  dict.get(variables, "category"),
                  dynamic.from("unknown"),
                ),
                decode.string,
              )
              |> result.unwrap("unknown"),
            ),
          ]),
        ],
      ),
      html.div([attribute.class("mt-3")], [
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
                    "px-2 py-1 text-xs text-base-content/70 border border-base-content/10 rounded-full hover:bg-base-200 transition-colors",
                  ),
                  attribute.href("#!/tag/" <> tag),
                ],
                [html.text(tag)],
              )
            }),
        ),
      ]),
    ])

  minimalist_common(content, menu, post_header, variables)
}

/// Common layout structure for both pages and posts
///
/// @param content The main content to display
/// @param menu Navigation menu items
/// @param header Page or post header content (title, description, metadata)
/// @param variables Dictionary with page/post metadata
/// @return Complete layout structure
fn minimalist_common(
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
    ],
    [
      html.header(
        [
          attribute.class(
            "bg-base-100 border-b border-base-content/10 sticky top-0 z-10",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("flex items-center justify-between h-14")],
              [
                html.a(
                  [
                    attribute.class(
                      "text-base-content/90 text-sm font-normal hover:text-base-content transition-colors",
                    ),
                    attribute.href("/"),
                  ],
                  [html.text(site_name)],
                ),
                html.nav([attribute.class("hidden sm:block")], [
                  html.ul(
                    [
                      attribute.id("menu_1_inside"),
                      attribute.class("flex space-x-6"),
                    ],
                    menu,
                  ),
                ]),
                html.div([attribute.class("relative w-36 sm:w-48")], [
                  html.div([attribute.class("flex items-center h-8")], [
                    html.input([
                      attribute.class(
                        "w-full py-1 px-3 text-sm bg-base-100 border border-base-content/10 rounded-full focus:outline-none focus:border-primary/30 transition-colors placeholder-base-content/40",
                      ),
                      attribute.placeholder("Search"),
                      attribute.type_("text"),
                      event.on_input(messages.UserSearchTerm),
                    ]),
                    html.span(
                      [attribute.class("absolute right-3 text-base-content/40")],
                      [
                        html.span(
                          [attribute.class("i-tabler-search w-3.5 h-3.5")],
                          [],
                        ),
                      ],
                    ),
                  ]),
                ]),
              ],
            ),
            html.div([attribute.class("sm:hidden pt-2")], [
              html.ul(
                [
                  attribute.id("menu_1_inside_mobile"),
                  attribute.class("flex flex-wrap gap-4"),
                ],
                menu,
              ),
            ]),
          ]),
        ],
      ),
      html.main(
        [attribute.class("flex-grow container mx-auto px-4 sm:px-6 py-8")],
        [
          html.div([attribute.class("max-w-3xl mx-auto")], [
            header,
            html.div([attribute.class("prose max-w-none")], [content]),
          ]),
        ],
      ),
      html.footer(
        [attribute.class("bg-base-100 border-t border-base-content/10 py-6")],
        [
          html.div([attribute.class("container mx-auto px-4 sm:px-6")], [
            html.div(
              [attribute.class("text-center text-xs text-base-content/50")],
              [
                html.text("Powered by "),
                html.a(
                  [
                    attribute.class("text-primary/70 hover:text-primary"),
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

/// Generate primary menu items
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
                "text-sm "
                <> case hash == item.1 {
                  True -> "text-primary font-medium"
                  False -> "text-base-content/70 hover:text-base-content"
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
