//// Ownit layout
////
//// Custom layout for Cynthia Mini.
//// Allows to create own templates in Handlebars.

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

pub fn main(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
  is_post is_post: bool,
) {
  case dict.get(model.others, "config_ownit_template") {
    Ok(template) -> {
      case decode.run(template, decode.string) {
        Ok(template_string) -> {
          // Handle successful decoding
          todo
        }
        Error(error) -> {
          error_page(
            "An error occurred while decoding the Handles template: " <> error,
          )
        }
      }
    }
    Error(_) ->
      error_page(
        "An error occurred while loading the Handles template from your configuration at 'ownit_template'",
      )
  }
}

pub fn error_page(error_message: String) {
  todo
}
