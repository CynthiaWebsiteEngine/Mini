import cynthia_websites_mini_shared/config/v4_1
import gbor
import gleam/bool
import gleam/json
import gleam/string

pub fn v4p1_mini_json(v4p1_mini: v4_1.V4p1Mini) -> json.Json {
  json.object([
    #(
      "global",
      json.object([
        #("theme", json.string(v4p1_mini.global.theme)),
        #("theme_dark", json.string(v4p1_mini.global.theme_dark)),
        #("site_name", json.string(v4p1_mini.global.site_name)),
        #("site_description", json.string(v4p1_mini.global.site_description)),
      ]),
    ),
    #(
      "integrations",
      json.object([
        #("git", json.bool(v4p1_mini.integrations.git)),
        #("sitemap", json.string(v4p1_mini.integrations.sitemap)),
        #(
          "crawlable_context",
          json.bool(v4p1_mini.integrations.crawlable_context),
        ),
      ]),
    ),
    #("posts", {
      json.object([
        #("comments", case v4p1_mini.posts.comments {
          v4_1.CommentsMastodonStored ->
            json.object([
              #("store", json.string("mastodon")),
            ])
          v4_1.CommentsGithubStored(username:, repositoryname:) ->
            json.object([
              #("store", json.string("github")),
              #("username", json.string(username)),
              #("repositoryname", json.string(repositoryname)),
            ])
          v4_1.CommentsDisabled ->
            json.object([
              #("store", json.string("disabled")),
            ])
        }),
      ])
    }),
  ])
}

pub fn v4p1_mini_cbor(v4p1_mini: v4_1.V4p1Mini) {
  gbor.CBMap([
    #(
      gbor.CBString("global"),
      gbor.CBMap([
        #(gbor.CBString("theme"), gbor.CBString(v4p1_mini.global.theme)),
        #(
          gbor.CBString("theme_dark"),
          gbor.CBString(v4p1_mini.global.theme_dark),
        ),
        #(gbor.CBString("site_name"), gbor.CBString(v4p1_mini.global.site_name)),
        #(
          gbor.CBString("site_description"),
          gbor.CBString(v4p1_mini.global.site_description),
        ),
      ]),
    ),
    #(
      gbor.CBString("integrations"),
      gbor.CBMap([
        #(gbor.CBString("git"), gbor.CBBool(v4p1_mini.integrations.git)),
        #(
          gbor.CBString("sitemap"),
          gbor.CBString(v4p1_mini.integrations.sitemap),
        ),
        #(
          gbor.CBString("crawlable_context"),
          gbor.CBBool(v4p1_mini.integrations.crawlable_context),
        ),
      ]),
    ),
    #(gbor.CBString("posts"), {
      gbor.CBMap([
        #(gbor.CBString("comments"), case v4p1_mini.posts.comments {
          v4_1.CommentsMastodonStored ->
            gbor.CBMap([
              #(gbor.CBString("store"), gbor.CBString("mastodon")),
            ])
          v4_1.CommentsGithubStored(username:, repositoryname:) ->
            gbor.CBMap([
              #(gbor.CBString("store"), gbor.CBString("github")),
              #(gbor.CBString("username"), gbor.CBString(username)),
              #(gbor.CBString("repositoryname"), gbor.CBString(repositoryname)),
            ])
          v4_1.CommentsDisabled ->
            gbor.CBMap([
              #(gbor.CBString("store"), gbor.CBString("disabled")),
            ])
        }),
      ])
    }),
  ])
}

pub fn v4p1_mini_toml(v4p1_mini: v4_1.V4p1Mini) -> String {
  "# Do not edit these variables! They are set by Cynthia to tell it's config format apart.\nconfig.edition=\"mini\"\nconfig.version=4.1\n\n
[global]
# Theme to use for light mode - default themes: autumn, default
# Theme to use for dark mode - default themes: night, default-dark
theme = { default = \""
  <> v4p1_mini.global.theme
  <> "\", dark = \""
  <> v4p1_mini.global.theme_dark
  <> "\" }
# Your website's name, displayed in various places
site_name = \""
  <> v4p1_mini.global.site_name
  <> "\"
# A brief description of your website
site_description = \""
  <> v4p1_mini.global.site_description
  <> "\"

[integrations]
# Enable git integration for the website
# This will allow Cynthia Mini to detect the git repository
# For example linking to the commit hash in the footer
git = "
  <> v4p1_mini.integrations.git |> bool.to_string |> string.lowercase
  <> "

# Enable sitemap generation
# This will generate a sitemap.xml file in the root of the website
#
# You will need to enter the base URL of your website in the sitemap variable below.
# If your homepage is at \"https://example.com/#/\", then the sitemap variable should be set to \"https://example.com\".
# If you do not want to use a sitemap, set this to \"false\", or leave it empty (\"\"), you can also remove the sitemap variable altogether.
sitemap = \""
  <> v4p1_mini.integrations.sitemap
  <> "\"

# Enable crawlable context (JSON-LD injection)
# This will allow search engines to crawl the website, and makes it
# possible for the website to be indexed by search engine and LLMs.
crawlable_context = "
  <> v4p1_mini.integrations.crawlable_context
  |> bool.to_string
  |> string.lowercase
  <> ""
}
