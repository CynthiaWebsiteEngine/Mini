//// # Ownit layout
////
//// Custom layout for Cynthia Mini.
//// Allows to create own templates in Handlebars.
//// 
//// Ownit is a unique layout in the sense that, it does not contain a layout, it's merely a wrap around Handlebars to allow own templates to be used in Cynthia Mini.
//// 
//// ## Writing templates for ownit
//// 
//// Writing templates for ownit can be done in the [Handlebars](https://handlebarsjs.com/) language. 
//// Your template should be stored under `[variables] -> ownit_template` as a `"string"` or as a `{ path = "filename.hbs" }` or `{ url = "some-site.com/name.hbs" }` url.
//// 
//// ### Available context variables:
//// 
//// - `body`: Contains the content body, for example the text from your blog post.
//// etc: More to come!

import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/pottery/oven
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/javascript/array.{type Array}
import gleam/list
import gleam/option.{None}
import gleam/result
import lustre/element.{type Element}

pub fn main(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
  is_post is_post: Bool,
) {
  echo variables
  let #(
    title,
    description,
    site_name,
    category,
    date_modified,
    date_published,
    tags,
  ): #(String, String, String, String, String, String, Array(String)) = case
    is_post
  {
    True -> {
      let assert Ok(title) =
        dict.get(variables, "title")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(description) =
        dict.get(variables, "description_html")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(site_name) =
        dict.get(variables, "global_site_name")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(category) =
        dict.get(variables, "category")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(date_modified) =
        dict.get(variables, "date_modified")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(date_published) =
        dict.get(variables, "date_published")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(tags) =
        dict.get(variables, "tags")
        |> result.unwrap(dynamic.from([]))
        |> decode.run(decode.list(decode.string))
      let tags = tags |> array.from_list
      #(
        title,
        description,
        site_name,
        category,
        date_modified,
        date_published,
        tags,
      )
    }
    False -> {
      let assert Ok(title) =
        dict.get(variables, "title")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(description) =
        dict.get(variables, "description_html")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let assert Ok(site_name) =
        dict.get(variables, "global_site_name")
        |> result.unwrap(dynamic.from(None))
        |> decode.run(decode.string)
      let category = ""
      let date_modified = ""
      let date_published = ""
      let tags = [] |> array.from_list
      #(
        title,
        description,
        site_name,
        category,
        date_modified,
        date_published,
        tags,
      )
    }
  }

  let menu_1_items = {
    dict.get(model.computed_menus, 1)
    |> result.unwrap([])
    |> list.map(fn(item) { [item.name, item.to] |> array.from_list })
    |> array.from_list
  }
  let menu_2_items = {
    dict.get(model.computed_menus, 2)
    |> result.unwrap([])
    |> list.map(fn(item) { [item.name, item.to] |> array.from_list })
    |> array.from_list
  }
  let menu_3_items = {
    dict.get(model.computed_menus, 3)
    |> result.unwrap([])
    |> list.map(fn(item) { [item.name, item.to] |> array.from_list })
    |> array.from_list
  }

  case get_template(model) {
    Ok(template) -> {
      case
        {
          OwnitCtx(
            content: content |> element.to_string(),
            is_post:,
            title:,
            description:,
            site_name:,
            category:,
            date_modified:,
            date_published:,
            tags:,
            menu_1_items:,
            menu_2_items:,
            menu_3_items:,
          )
          |> context_into_template_run(template, _)
        }
      {
        Ok(html_) -> element.unsafe_raw_html("div", "div", [], html_)
        Error(_) ->
          oven.error(
            "Could not parse context into the Handlebars template from the configurated variable at 'ownit_template'.",
            recoverable: True,
          )
      }
    }
    Error(error_message) -> {
      oven.error(error_message, recoverable: False)
    }
  }
}

fn get_template(model: model_type.Model) {
  use template_string_dynamic <- result.try(result.replace_error(
    dict.get(model.other, "config_ownit_template"),
    "An error occurred while loading the Handlebars template from the configurated variable at 'ownit_template'.",
  ))
  use template_string <- result.try(result.replace_error(
    decode.run(template_string_dynamic, decode.string),
    "An error occurred while trying to decode the Handlebars template from the configurated variable at 'ownit_template'.",
  ))
  compile_template_string(template_string)
  |> result.replace_error(
    "Could not compile the Handlebars template from the configurated variable at 'ownit_template'.",
  )
}

/// Context sent into Handlebars template, obviously needs to be generated first. Is translated into an Ecmascript object by FFI.
type OwnitCtx {
  OwnitCtx(
    /// JS: string
    content: String,
    /// JS: boolean
    is_post: Bool,
    /// JS: string
    title: String,
    /// JS: string
    description: String,
    /// JS: string
    site_name: String,
    /// JS: string
    category: String,
    /// JS: string
    date_modified: String,
    /// JS: string
    date_published: String,
    /// JS: string[]
    tags: Array(String),
    /// JS: [string, string][]
    menu_1_items: Array(Array(String)),
    /// JS: [string, string][]
    menu_2_items: Array(Array(String)),
    /// JS: [string, string][]
    menu_3_items: Array(Array(String)),
  )
}

@external(javascript, "./ownit_ffi", "compile_template_string")
fn compile_template_string(in: String) -> Result(CompiledTemplate, Nil)

type CompiledTemplate

@external(javascript, "./ownit_ffi", "context_into_template_run")
fn context_into_template_run(
  template: CompiledTemplate,
  context: OwnitCtx,
) -> Result(String, Nil)
