import cynthia_websites_mini_shared/contenttypes.{type Content}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type CompleteData {
  CompleteData(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    server_port: Option(Int),
    server_host: Option(String),
    comment_repo: Option(String),
    git_integration: Bool,
    other_vars: List(#(String, List(String))),
    content: List(Content),
  )
}

pub fn encode_complete_data_for_client(complete_data: CompleteData) -> json.Json {
  let CompleteData(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port: _,
    server_host: _,
    comment_repo:,
    git_integration:,
    other_vars:,
    content:,
  ) = complete_data
  json.object([
    #("global_theme", json.string(global_theme)),
    #("global_theme_dark", json.string(global_theme_dark)),
    #("global_colour", json.string(global_colour)),
    #("global_site_name", json.string(global_site_name)),
    #("global_site_description", json.string(global_site_description)),
    #("git_integration", json.bool(git_integration)),
    #("comment_repo", case comment_repo {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
    #(
      "configurable_variables",
      json.array(other_vars, fn(item) -> json.Json {
        json.object([#(item.0, json.array(item.1, json.string))])
      }),
    ),
    #("content", json.array(content, contenttypes.encode_content)),
  ])
}

pub fn complete_data_decoder() -> decode.Decoder(CompleteData) {
  use global_theme <- decode.field("global_theme", decode.string)
  use global_theme_dark <- decode.field("global_theme_dark", decode.string)
  use global_colour <- decode.field("global_colour", decode.string)
  use global_site_name <- decode.field("global_site_name", decode.string)
  use git_integration <- decode.optional_field(
    "git_integration",
    default_shared_cynthia_config_global_only.git_integration,
    decode.bool,
  )
  use global_site_description <- decode.field(
    "global_site_description",
    decode.string,
  )
  use server_port <- decode.optional_field(
    "server_port",
    None,
    decode.optional(decode.int),
  )
  use server_host <- decode.optional_field(
    "server_host",
    None,
    decode.optional(decode.string),
  )
  use comment_repo <- decode.field(
    "comment_repo",
    decode.optional(decode.string),
  )
  use content <- decode.field(
    "content",
    decode.list(contenttypes.content_decoder()),
  )
  use other_vars <- decode.field("configurable_variables", {
    decode.list(decode.dict(decode.string, decode.list(decode.string)))
    |> decode.map(list.fold(_, dict.new(), dict.merge))
  })

  let other_vars = dict.to_list(other_vars)

  decode.success(CompleteData(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    comment_repo:,
    git_integration:,
    other_vars:,
    content:,
  ))
}

pub type SharedCynthiaConfigGlobalOnly {
  SharedCynthiaConfigGlobalOnly(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    server_port: Option(Int),
    server_host: Option(String),
    comment_repo: Option(String),
    git_integration: Bool,
    other_vars: List(#(String, List(String))),
  )
}

pub const default_shared_cynthia_config_global_only: SharedCynthiaConfigGlobalOnly = SharedCynthiaConfigGlobalOnly(
  global_theme: "autumn",
  global_theme_dark: "night",
  global_colour: "#FFFFFF",
  global_site_name: "My Site",
  global_site_description: "A big site on a mini Cynthia!",
  server_port: None,
  server_host: None,
  comment_repo: None,
  git_integration: True,
  other_vars: [],
)

pub fn merge(
  orig: SharedCynthiaConfigGlobalOnly,
  content: List(Content),
) -> CompleteData {
  CompleteData(
    global_theme: orig.global_theme,
    global_theme_dark: orig.global_theme_dark,
    global_colour: orig.global_colour,
    global_site_name: orig.global_site_name,
    global_site_description: orig.global_site_description,
    server_port: orig.server_port,
    server_host: orig.server_host,
    comment_repo: orig.comment_repo,
    git_integration: orig.git_integration,
    other_vars: orig.other_vars,
    content:,
  )
}
