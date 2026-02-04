//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.
//// Focused on simplicity while offering a clean, modern experience.

import gleam/int
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn register() -> Result(Nil, lustre.Error) {
  let component = lustre.simple(init, update, view)
  lustre.register(component, "layout_cindy-simple")
}

// Layout models are always as complete possible, including impossible fields.
// Everything is just filled up with default values on init() and so, if any value
// remains unset, it'll still be possible to read or not read.
type Model {
  Model(title: String, description: String, content_type: ContentType)
}

type ContentType {
  Post
  Page
}

fn init(_) -> Model {
  Model("", "")
}

// UPDATE ----------------------------------------------------------------------

/// Just like our component's `Model`, the `Msg` type is also private to the
/// component and doesn't need to be handled by the parent app. This makes it
/// convenient to use components to encapsulate complex functionality and rich
/// user interaction patterns without complicating the parent app.
///
type Msg {
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserClickedIncrement -> model + 1
    UserClickedDecrement -> model - 1
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)

  html.div([attribute.class("py-4 flex items-center gap-2")], [
    view_button(label: "-", on_click: UserClickedDecrement),
    html.p([attribute.class("flex-1")], [html.text("Count: "), html.text(count)]),
    view_button(label: "+", on_click: UserClickedIncrement),
  ])
}

fn view_button(label label: String, on_click handle_click: msg) -> Element(msg) {
  html.button(
    [
      attribute.class("bg-blue-500 text-white w-12 py-1 rounded"),
      event.on_click(handle_click),
    ],
    [html.text(label)],
  )
}
