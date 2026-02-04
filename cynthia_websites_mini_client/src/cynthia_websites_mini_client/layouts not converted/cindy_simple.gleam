//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.
//// Focused on simplicity while offering a clean, modern experience.

// Common imports for layouts
import cynthia_websites_mini_client/model_messages
import cynthia_websites_mini_shared/config/site_json
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// cindy layout for pages.
///
/// Dict keys:
/// - `content`
pub fn page_layout(
  from content: Element(model_messages.Msg),
  content item: site_json.Content,
  store model: model_messages.Model,
) -> Element(model_messages.Msg) {
  let title = item.title
  let description = item.description

  html.div([attribute.class("break-words")], [
    html.h3(
      [
        attribute.class(
          "font-bold text-2xl md:text-3xl text-center text-base-content my-3 transition-all",
        ),
      ],
      [html.text(title)],
    ),
    element.unsafe_raw_html(
      "aside",
      "aside",
      [attribute.class("max-w-prose mx-auto")],
      description,
    ),
  ])
  |> cindy_common(item, model)
}

pub fn post_layout(
  from content: Element(model_messages.Msg),
  content item: site_json.Content,
  store model: model_messages.Model,
) -> Element(model_messages.Msg) {
  let menu = menu_1(model)

  let assert site_json.Post(
    title:,
    description:,
    layout:,
    content:,
    date_published:,
    date_updated:,
    category:,
    tags:,
    mastodon_comments:,
  ) = item
  html.div([], [
    html.div([], [
      html.h3(
        [
          attribute.class(
            "font-bold text-2xl md:text-3xl text-center text-base-content my-3 transition-all",
          ),
        ],
        [html.text(title)],
      ),
      element.unsafe_raw_html(
        "aside",
        "aside",
        [attribute.class("max-w-prose mx-auto mb-4")],
        description,
      ),
    ]),
    html.div([attribute.class("grid grid-cols-2 grid-rows-4 gap-3")], [
      // ----------------------
      html.div([], []),
      html.div([], []),
      // ----------------------
      html.b([attribute.class("font-bold text-base-content/80")], [
        html.text("Published"),
      ]),
      html.div([attribute.class("text-base-content/90")], [
        html.text(date_published),
      ]),
      // ----------------------
      html.b([attribute.class("font-bold text-base-content/80")], [
        html.text("Modified"),
      ]),
      html.div([attribute.class("text-base-content/90")], [
        html.text(date_updated),
      ]),
      // ----------------------
      html.div([], [
        html.b([attribute.class("font-bold text-base-content/80")], [
          html.text("Category"),
        ]),
      ]),
      html.div([attribute.class("text-base-content/90")], [
        html.text(category),
      ]),
    ]),
    html.div([attribute.class("grid grid-cols-1 grid-rows-1 gap-2 mt-3")], [
      html.div([], [
        html.b([attribute.class("font-bold text-base-content/80")], [
          html.text("Tags"),
        ]),
        html.div(
          [attribute.class("flex flex-wrap gap-2 mt-2")],
          tags
            |> list.map(string.trim)
            |> list.map(fn(tag) {
              html.a(
                [
                  attribute.class(
                    "btn btn-sm btn-outline btn-primary transition-colors duration-200",
                  ),
                  attribute.href("#!/tag/" <> tag),
                ],
                [html.text(tag)],
              )
            }),
        ),
      ]),
    ]),
  ])
  |> cindy_common(around: content, for: item, model:)
}

fn cindy_common(
  from post_meta: Element(model_messages.Msg),
  around content: String,
  for item: site_json.Content,
  model model: model_messages.Model,
) -> Element(model_messages.Msg) {
  let site_name = model.data.config.global.site_name
  let hide_metadata_block = case item {
    site_json.Page(hide_meta_block:, ..) -> hide_meta_block
    site_json.Post(..) -> False
  }
  let hide_metadata_block_classonly = case hide_metadata_block {
    True -> " hidden"
    False -> ""
  }
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      //   element.text(variables |> string.inspect),
      html.div(
        [
          attribute.class(
            "grid grid-cols-5 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
          ),
        ],
        [
          // Menu and site name - Enhanced mobile layout
          html.div(
            [
              attribute.class(
                "col-span-5 px-2 py-3 md:p-4 m-0 bg-base-300 backdrop-blur-sm flex flex-col md:flex-row items-center shadow-sm sticky top-0 z-10 gap-2 md:gap-0",
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
                      event.on_click(model_messages.CindyMsg(
                        model_messages.ToggleMenu1,
                      )),
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
                  // Search input with improved mobile styling
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
                              event.on_input(model_messages.UserSearchTerm),
                            ]),
                          ],
                        ),
                      ]),
                    ],
                  ),
                  // Menu with mobile-optimized layout and enhanced contrast
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
                          menu_1(model),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Content - Improved mobile spacing
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-7 row-start-2 md:col-span-4 md:row-span-11 md:col-start-2 md:row-start-2 overflow-auto min-h-full p-3 md:p-6 lg:p-8",
              ),
            ],
            [
              html.div(
                [attribute.class("max-w-4xl mx-auto space-y-4 md:space-y-6")],
                [content],
              ),
              html.br([]),
            ],
          ),
          // Post meta - Enhanced mobile layout
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-4 row-start-9 md:row-span-8 md:col-start-1 md:row-start-2 min-h-full bg-base-200 rounded-br-2xl overflow-auto w-full md:w-fit md:max-w-[20VW] p-4 md:p-3 break-words shadow-inner"
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

/// Cindy Simple only has one menu, shown on the top of the page. But we still count it as menu 1.
pub fn menu_1(
  from model: model_messages.Model,
) -> List(Element(model_messages.Msg)) {
  let href = model_messages.href(_, model)
  let current = model.route
  [
    model.menu_items
    |> list.key_filter(1)
    |> list.map(fn(item) {
      html.a(
        [
          attribute.class({
            case current == item.1 {
              True -> "menu-active menu-focused active font-medium"
              False -> "hover:bg-base-300/50 transition-colors duration-200"
            }
          }),
          href(item.1),
        ],
        [html.text(item.0)],
      )
    })
    |> html.li([], _),
  ]
}
