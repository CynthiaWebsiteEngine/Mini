//// Cindy Landing Layout module
////
//// Special layout optimized for landing pages, derived from Cindy Simple.
//// Post layout remains identical to cindy-simple, but pages get special treatment.

// Common imports for layouts
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/option
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import cynthia_websites_mini_client/pottery/molds/cindy_simple.{menu_1}

/// cindy-landing layout for pages - optimized for landing page experience with:
/// - Full-width hero section with large title
/// - Prominent call-to-action area
/// - Cleaner layout with less distractions
///
/// Dict keys:
/// - `content`
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

  // Special header for landing pages
  let landing_header =
    html.div(
      [
        attribute.class(
          "landing-hero mb-4 md:mb-8 p-4 md:p-6 bg-gradient-to-r from-base-200 to-base-300 rounded-lg shadow-lg",
        ),
      ],
      [
        html.h1(
          [
            attribute.class(
              "font-bold text-3xl md:text-4xl lg:text-5xl text-center text-base-content mb-3 md:mb-4",
            ),
          ],
          [html.text(title)],
        ),
        html.div([attribute.class("max-w-3xl mx-auto")], [
          element.unsafe_raw_html(
            "aside",
            "div",
            [
              attribute.class(
                "text-base md:text-lg text-center text-base-content/80",
              ),
            ],
            description,
          ),
        ]),
      ],
    )

  html.div([attribute.class("break-words")], [landing_header])
  |> landing_common(content, menu, _, variables, model)
}

/// Special common layout for landing pages: 
/// - More focused design
/// - Content centered and emphasized
/// - Full width content area
/// - Optional sidebar removed from view by default
fn landing_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  post_meta: Element(messages.Msg),
  variables: Dict(String, Dynamic),
  model: model_type.Model,
) {
  let assert Ok(site_name) = {
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(option.None))
    |> decode.run(decode.string)
  }
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      html.div(
        [
          attribute.class(
            "grid grid-cols-6 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
          ),
        ],
        [
          // Menu and site name - with adjusted styling for landing pages
          html.div(
            [
              attribute.class(
                "col-span-6 px-2 py-3 md:p-4 m-0 bg-base-300/50 backdrop-blur-sm flex flex-col md:flex-row items-center sticky top-0 z-10 shadow-sm gap-2 md:gap-0",
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
                        "text-center font-bold btn btn-ghost text-xl md:text-2xl transition-all duration-200 hover:scale-105",
                      ),
                    ],
                    [html.text(site_name)],
                  ),
                  // Mobile menu toggle button
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
              // Search bar and menu container for mobile flexibility
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
                  // Search
                  html.div(
                    [
                      attribute.class(
                        "w-full md:w-4/12 flex items-center justify-center",
                      ),
                    ],
                    [
                      html.div(
                        [
                          attribute.class(
                            "relative w-full max-w-xs opacity-80 hover:opacity-100 transition-opacity",
                          ),
                        ],
                        [
                          html.div(
                            [
                              attribute.class(
                                "flex items-center h-8 bg-base-200/70 border border-base-300/60 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary focus-within:shadow-md transition-all duration-200 w-full ring-1 ring-inset ring-base-content/10",
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
                        ],
                      ),
                    ],
                  ),
                  // Menu styled to be more mobile-friendly
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
          // Content - improved mobile layout
          html.div(
            [
              attribute.class(
                "col-span-6 row-span-11 row-start-2 overflow-auto min-h-full p-3 md:p-6 lg:p-8 flex flex-col items-center",
              ),
            ],
            [
              html.div([attribute.class("w-full max-w-5xl px-2 md:px-4")], [
                post_meta,
                content,
              ]),
            ],
          ),
        ],
      ),
    ]),
  ])
}
