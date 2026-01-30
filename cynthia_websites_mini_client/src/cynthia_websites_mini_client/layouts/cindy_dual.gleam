//// Cindy Dual Layout module
////
//// Extension of the default Cindy Simple layout with a secondary menu.

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

/// cindy-dual layout for pages.
///
/// Dict keys:
/// - `content`
pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  let menu = menu_1(model)
  let secondary_menu = menu_2(model)

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
  html.div([attribute.class("break-words")], [
    html.h3(
      [attribute.class("font-bold text-2xl text-center text-base-content")],
      [html.text(title)],
    ),
    element.unsafe_raw_html("aside", "aside", [], description),
  ])
  |> cindy_common(content, menu, _, secondary_menu, variables, model)
}

pub fn post_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  let menu = menu_1(model)
  let secondary_menu = menu_2(model)

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
  html.div([], [
    html.div([], [
      html.h3(
        [attribute.class("font-bold text-2xl text-center text-base-content")],
        [html.text(title)],
      ),
      element.unsafe_raw_html("aside", "aside", [], description),
    ]),
    html.div([attribute.class("grid grid-cols-2 grid-rows-4 gap-2")], [
      // ----------------------
      html.div([], []),
      html.div([], []),
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Published")]),
      html.div([], [
        html.text(
          {
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
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Modified")]),
      html.div([], [
        html.text(
          {
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
      // ----------------------
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Category")]),
      ]),
      html.div([], [
        html.text(
          decode.run(
            result.unwrap(
              dict.get(variables, "category"),
              dynamic.from("unknown"),
            ),
            decode.string,
          )
          |> result.unwrap("unknown"),
        ),
      ]),
    ]),
    html.div([attribute.class("grid grid-cols-1 grid-rows-1 gap-2")], [
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Tags")]),
        html.div(
          [],
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
    ]),
  ])
  |> cindy_common(content, menu, _, secondary_menu, variables, model)
}

fn cindy_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  post_meta: Element(messages.Msg),
  secondary_menu: List(Element(messages.Msg)),
  variables: Dict(String, Dynamic),
  model: model_type.Model,
) {
  let assert Ok(site_name) = {
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(option.None))
    |> decode.run(decode.string)
  }
  let hide_metadata_block =
    decode.run(
      result.unwrap(
        dict.get(variables, "hide_metadata_block"),
        dynamic.from(False),
      ),
      decode.bool,
    )
    |> result.unwrap(False)
  let hide_metadata_block_classonly = case hide_metadata_block {
    True -> " hidden"
    False -> ""
  }
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      html.div(
        [
          attribute.class(
            "grid grid-cols-5 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
          ),
        ],
        [
          // Menu and site name with improved mobile layout
          html.div(
            [
              attribute.class(
                "col-span-5 px-2 py-3 md:p-4 m-0 bg-base-300 backdrop-blur-sm flex flex-col md:flex-row items-center sticky top-0 z-10 shadow-sm gap-2 md:gap-0",
              ),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "w-full md:w-3/12 flex items-center justify-between md:justify-start",
                  ),
                ],
                [
                  html.span(
                    [
                      attribute.class(
                        "text-center font-bold btn btn-ghost text-xl transition-all duration-200 hover:scale-105",
                      ),
                    ],
                    [html.text(site_name)],
                  ),
                  // Mobile menu toggle
                  html.button(
                    [
                      attribute.class(
                        "md:hidden btn btn-ghost btn-sm fa fa-bars",
                      ),
                      attribute.id("cindy_menu_toggle"),
                      event.on_click(messages.CindyToggleMenu1),
                    ],
                    [html.span([attribute.class("i-tabler-menu h-5 w-5")], [])],
                  ),
                ],
              ),
              // Search and menu container for mobile
              html.div(
                [
                  attribute.class(
                    "w-full md:w-9/12 flex-col md:flex-row items-center gap-3 "
                    <> case dict.get(model.other, "cindy menu  1 open") {
                      Ok(_) ->
                        "flex bg-accent backdrop-blur-md p-4 rounded-lg shadow-lg border border-base-300/30 md:bg-transparent md:p-0 md:shadow-none md:border-none"
                      Error(_) -> "hidden md:flex"
                    },
                  ),
                ],
                [
                  // Search with improved mobile styling
                  html.div(
                    [
                      attribute.class(
                        "w-full md:w-4/12 flex items-center justify-center",
                      ),
                    ],
                    [
                      html.div([attribute.class("relative w-full max-w-xs")], [
                        html.div(
                          [
                            attribute.class(
                              "flex items-center h-8 bg-base-200/90 border border-base-300/80 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary focus-within:shadow-md transition-all duration-200 w-full ring-1 ring-inset ring-base-content/10",
                            ),
                          ],
                          [
                            html.span(
                              [attribute.class("pl-3 text-base-content/80")],
                              [
                                html.span(
                                  [attribute.class("i-tabler-search w-4 h-4")],
                                  [],
                                ),
                              ],
                            ),
                            html.input([
                              attribute.class(
                                "w-full py-1.5 px-2 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/70",
                              ),
                              attribute.placeholder("Search..."),
                              attribute.type_("text"),
                              event.on_input(messages.UserSearchTerm),
                            ]),
                          ],
                        ),
                      ]),
                    ],
                  ),
                  // Primary menu with mobile-optimized layout
                  html.div(
                    [
                      attribute.class(
                        "w-full md:w-5/12 flex justify-center md:justify-end",
                      ),
                    ],
                    [
                      html.menu([attribute.class("w-full md:w-auto")], [
                        html.ul(
                          [
                            attribute.id("menu_1_inside"),
                            attribute.class(
                              "menu menu-horizontal flex-col md:flex-row bg-base-200 md:bg-base-200/90 rounded-box shadow-sm w-full md:w-auto divide-y md:divide-y-0 divide-base-300/40",
                            ),
                          ],
                          menu,
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Secondary menu container - Enhanced for mobile
          html.div(
            [
              attribute.class(
                "col-span-5 bg-base-200/95 backdrop-blur-md p-4 shadow-sm overflow-x-auto border-y border-base-300/30",
              ),
              attribute.id("secondary_menu_container"),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "flex flex-wrap md:flex-nowrap justify-start md:justify-center gap-2 min-w-max",
                  ),
                ],
                [
                  html.ul(
                    [
                      attribute.id("menu_2_inside"),
                      attribute.class(
                        "menu menu-horizontal rounded-box gap-2 flex-nowrap bg-base-100/80 p-3 w-full shadow-sm",
                      ),
                    ],
                    secondary_menu,
                  ),
                ],
              ),
            ],
          ),
          // Content - Improved mobile layout
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-7 row-start-3 md:col-span-4 md:row-span-10 md:col-start-2 md:row-start-3 overflow-auto min-h-full p-3 md:p-6",
              ),
            ],
            [
              html.div([attribute.class("max-w-4xl mx-auto space-y-4")], [
                content,
                html.br([]),
              ]),
            ],
          ),
          // Post meta - Enhanced mobile layout
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-4 row-start-9 md:row-span-8 md:col-start-1 md:row-start-3 min-h-full bg-base-200 rounded-br-2xl overflow-auto w-full md:w-fit md:max-w-[20VW] p-4 md:p-3 break-words shadow-inner"
                <> hide_metadata_block_classonly,
              ),
            ],
            [post_meta],
          ),
        ],
      ),
    ]),
  ])
}

/// Primary menu for cindy-dual
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus
  case dict.get(content, 1) {
    Error(_) -> []
    Ok(menu_items) -> {
      list.map(menu_items, fn(this_item) {
        let current_item = case this_item {
          model_type.MenuItem(name:, to: "") ->
            model_type.MenuItem(name:, to: "/")
          _ -> this_item
        }
        html.li([], [
          html.a(
            [
              attribute.class({
                case hash == current_item.to {
                  True -> "menu-active menu-focused active font-medium"
                  False -> "hover:bg-base-300/50 transition-colors duration-200"
                }
              }),
              attribute.href(current_item.to),
            ],
            [html.text(current_item.name)],
          ),
        ])
      })
    }
  }
}

/// Secondary menu for cindy-dual
pub fn menu_2(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus
  case dict.get(content, 2) {
    Error(_) -> []
    Ok(menu_items) -> {
      list.map(menu_items, fn(a) {
        let a = case a {
          model_type.MenuItem(name:, to: "") ->
            model_type.MenuItem(name:, to: "/")
          _ -> a
        }
        html.li([], [
          html.a(
            [
              attribute.class({
                case hash == a.to {
                  True -> "menu-active menu-focused active font-medium"
                  False -> "hover:bg-base-300/50 transition-colors duration-200"
                }
              }),
              attribute.href(a.to),
            ],
            [html.text(a.name)],
          ),
        ])
      })
    }
  }
}
