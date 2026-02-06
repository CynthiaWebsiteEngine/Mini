//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.
//// Focused on simplicity while offering a clean, modern experience.

import gleam/bool
import lustre
import lustre/component
import lustre/effect
import lustre/element.{type Element}

fn links_attribute_to_model(name: String) {
  component.on_attribute_change(name, fn(value) {
    UpdateModelValueAttribute(name, value) |> Ok
  })
}

pub fn register() -> Result(Nil, lustre.Error) {
  let component =
    lustre.component(init, update, view, [
      links_attribute_to_model("title"),
      links_attribute_to_model("description"),
      links_attribute_to_model("content-type"),
      links_attribute_to_model("date-published"),
      links_attribute_to_model("date-updated"),
    ])
  lustre.register(component, "layout_cindy-simple")
}

// Layout models are always as complete possible, including may-be-impossible fields.
// Everything is just filled up with default values on init() and so, if any value
// remains unset, it'll still be possible to read or not read.
type Model {
  Model(menu_1_out: Bool, content_item: ContentItem)
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
      menu_1_out: False,
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
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  #(
    case msg {
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

fn view(model: Model) -> Element(Msg) {
  [
    element.text("This layout is for now just flatted."),
    component.named_slot("menu1", [], [element.text("No menu items.")]),
    component.default_slot([], []),
  ]
  |> element.fragment()
}
