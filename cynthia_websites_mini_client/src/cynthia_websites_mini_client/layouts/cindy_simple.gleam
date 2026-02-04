//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.
//// Focused on simplicity while offering a clean, modern experience.

import lustre
import lustre/component
import lustre/effect
import lustre/element.{type Element}

pub fn register() -> Result(Nil, lustre.Error) {
  let component = lustre.component(init, update, view, [])
  lustre.register(component, "layout_cindy-simple")
}

// Layout models are always as complete possible, including may-be-impossible fields.
// Everything is just filled up with default values on init() and so, if any value
// remains unset, it'll still be possible to read or not read.
type Model {
  Model(
    title: String,
    description: String,
    content_type: ContentType,
    menu_1_out: Bool,
  )
}

type ContentType {
  Post
  Page
}

fn init(_: a) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(title: "", description: "", content_type: Page, menu_1_out: False),
    effect.none(),
  )
}

type Msg {
  ToggleMenu1
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  #(
    case msg {
      ToggleMenu1 -> todo
    },
    effect.none(),
  )
}

fn view(model: Model) -> Element(Msg) {
  component.default_slot([], [])
}
