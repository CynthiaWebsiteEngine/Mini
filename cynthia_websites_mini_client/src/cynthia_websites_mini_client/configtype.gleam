import cynthia_websites_mini_client/contenttypes.{type Content}
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
    crawlable_context: Bool,
    sitemap: Option(String),
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
    crawlable_context:,
    sitemap:,
  ) = complete_data
  json.object([
    #("global_theme", json.string(global_theme)),
    #("global_theme_dark", json.string(global_theme_dark)),
    #("global_colour", json.string(global_colour)),
    #("global_site_name", json.string(global_site_name)),
    #("global_site_description", json.string(global_site_description)),
    #("git_integration", json.bool(git_integration)),
    #("crawlable_context", json.bool(crawlable_context)),
    #("sitemap", case sitemap {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
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

  use crawlable_context <- decode.optional_field(
    "crawlable_context",
    default_shared_cynthia_config_global_only.crawlable_context,
    decode.bool,
  )
  use sitemap <- decode.optional_field(
    "sitemap",
    default_shared_cynthia_config_global_only.sitemap,
    decode.optional(decode.string),
  )

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
    crawlable_context:,
    sitemap:,
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
    /// [True]
    /// Wether or not to enable git integration for the site.
    git_integration: Bool,
    /// [False]
    /// Wether or not to insert json-ld+context into the HTML
    /// to make the site crawlable by search engines or readable by LLMs.
    crawlable_context: Bool,
    /// [True]
    /// Wether or not to create a sitemap.xml file for the site.
    /// This is useful for search engines to index the site.
    /// This is separate from the crawlable_context setting, as no content needs to be rendered or served for the sitemap.xml file.
    sitemap: Option(String),
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
  crawlable_context: False,
  sitemap: Some("https://example.com"),
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
    crawlable_context: orig.crawlable_context,
    sitemap: orig.sitemap,
    other_vars: orig.other_vars,
    content:,
  )
}

pub const ootb_index = "{#hello-world}
# Hello, World

1. Numbered lists
2. Images: ![Gleam\\'s Lucy
   mascot](https://gleam.run/images/lucy/lucy.svg)

{#the-world-is-big}
## The world is big

{#the-world-is-a-little-smaller}
### The world is a little smaller

{#the-world-is-tiny}
#### The world is tiny

{#the-world-is-tinier}
##### The world is tinier

{#the-world-is-the-tiniest}
###### The world is the tiniest

> Also quote blocks\\!
> \\
> -StrawmelonJuice


A task list:
- [ ] Task 1
- [x] Task 2
- [ ] Task 3

A bullet list:

- Point 1
- Point 2

{.bash}
  ```myfile.bash
  echo \"Code blocks!\"
  // - StrawmelonJuice
  ```

A small table:
| Column 1 | Column 2 |
| -------- | -------- |
| Value 1  | Value 2  |
| [Github](https://github.com)   | [Codeberg](https://codeberg.org) |
|<https://github.com/CynthiaWebsiteEngine/Mini>|<https://github.com/strawmelonjuice/Mini-strawmelonjuice.com>|
"
