//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.
//// Focused on simplicity while offering a clean, modern experience.

import gleam/bool
import gleam/json
import lustre
import lustre/attribute
import lustre/component
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

fn links_attribute_to_model(name: String) {
  component.on_attribute_change(name, fn(value) {
    UpdateModelValueAttribute(name, value) |> Ok
  })
}

pub fn register() -> Result(Nil, lustre.Error) {
  let component =
    lustre.component(init, update, view, [
      links_attribute_to_model("sitename"),
      links_attribute_to_model("title"),
      links_attribute_to_model("description"),
      links_attribute_to_model("content-type"),
      links_attribute_to_model("date-published"),
      links_attribute_to_model("search"),
      links_attribute_to_model("date-updated"),
    ])
  lustre.register(component, "layout-cindy-simple")
}

// Layout models are always as complete possible, including may-be-impossible fields.
// Everything is just filled up with default values on init() and so, if any value
// remains unset, it'll still be possible to read or not read.
type Model {
  Model(
    site_name: String,
    menu_1_out: Bool,
    content_item: ContentItem,
    search: String,
  )
}

type ContentItem {
  ContentItem(
    title: String,
    description: String,
    content_type: ContentType,
    date_published: String,
    date_updated: String,
  )
}

type ContentType {
  Post
  Page
}

fn init(_: a) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      site_name: "",
      menu_1_out: False,
      search: "",
      content_item: ContentItem(
        title: "",
        description: "",
        content_type: Page,
        date_published: "",
        date_updated: "",
      ),
    ),
    effect.none(),
  )
}

type Msg {
  ToggleMenu1
  UpdateModelValueAttribute(String, String)
  SearchBox(String)
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SearchBox(term) -> #(
      Model(..model, search: term),
      event.emit("search", json.string(term)),
    )
    no_effect -> #(
      case no_effect {
        SearchBox(..) -> panic as "Has an effect and so is handled above here."
        UpdateModelValueAttribute("title", value) ->
          Model(
            ..model,
            content_item: ContentItem(..model.content_item, title: value),
          )
        UpdateModelValueAttribute("description", value) ->
          Model(
            ..model,
            content_item: ContentItem(..model.content_item, description: value),
          )
        UpdateModelValueAttribute("sitename", value) ->
          Model(..model, site_name: value)
        UpdateModelValueAttribute("search", value) ->
          Model(..model, search: value)
        UpdateModelValueAttribute("content-type", value) ->
          Model(
            ..model,
            content_item: ContentItem(
              ..model.content_item,
              content_type: case value {
                "post" -> Post
                _ -> Page
              },
            ),
          )
        UpdateModelValueAttribute(a, _) -> {
          let b = "Unhandled UpdateModelValue call for field: " <> a
          panic as b
        }
        ToggleMenu1 -> Model(..model, menu_1_out: bool.negate(model.menu_1_out))
      },
      // Cindy Simple does not have side effects from update in any case.
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  element.fragment([
    html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
      html.span([], [
        html.div(
          [
            attribute.class(
              "grid grid-cols-5 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
            ),
          ],
          [
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
                      [html.text(model.site_name)],
                    ),
                    html.button(
                      [
                        attribute.id("cindy_menu_toggle"),
                        attribute.class(
                          "md:hidden btn btn-ghost btn-sm fa fa-bars",
                        ),
                      ],
                      [
                        html.span(
                          [attribute.class("i-tabler-menu h-5 w-5")],
                          [],
                        ),
                      ],
                    ),
                  ],
                ),
                html.div(
                  [
                    attribute.class(
                      "w-full md:w-9/12 flex-col md:flex-row items-center gap-3 hidden md:flex",
                    ),
                  ],
                  [
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
                                [
                                  attribute.class("pl-3 text-base-content/80"),
                                ],
                                [
                                  html.span(
                                    [
                                      attribute.class("i-tabler-search w-4 h-4"),
                                    ],
                                    [],
                                  ),
                                ],
                              ),
                              html.input([
                                attribute.type_("text"),
                                attribute.placeholder("Search..."),
                                attribute.class(
                                  "w-full py-1.5 px-2 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/70",
                                ),
                              ]),
                            ],
                          ),
                        ]),
                      ],
                    ),
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
                            [
                              component.named_slot("menu1", [], [
                                element.text("No menu items."),
                              ]),
                            ],
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            html.div(
              [
                attribute.class(
                  "col-span-5 row-span-7 row-start-2 md:col-span-4 md:row-span-11 md:col-start-2 md:row-start-2 overflow-auto min-h-full p-3 md:p-6 lg:p-8",
                ),
              ],
              [
                html.div(
                  [
                    attribute.class("max-w-4xl mx-auto space-y-4 md:space-y-6"),
                  ],
                  [
                    html.div([attribute.class("contents")], [
                      component.default_slot([], []),
                    ]),
                  ],
                ),
                html.br([]),
              ],
            ),
            html.div(
              [
                attribute.class(
                  "col-span-5 row-span-4 row-start-9 md:row-span-8 md:col-start-1 md:row-start-2 min-h-full bg-base-200 rounded-br-2xl overflow-auto w-full md:w-fit md:max-w-[20VW] p-4 md:p-3 break-words shadow-inner",
                ),
              ],
              [
                html.div([attribute.class("break-words")], [
                  html.h3(
                    [
                      attribute.class(
                        "font-bold text-2xl md:text-3xl text-center text-base-content my-3 transition-all",
                      ),
                    ],
                    [html.text(" Themes ")],
                  ),
                  html.aside([attribute.class("max-w-prose mx-auto")], [
                    html.text(model.content_item.description),
                  ]),
                ]),
              ],
            ),
          ],
        ),
      ]),
    ]),
  ])
}
