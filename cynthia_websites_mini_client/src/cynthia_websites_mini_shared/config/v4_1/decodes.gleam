import cynthia_websites_mini_shared/config/v4
import cynthia_websites_mini_shared/config/v4/decodes
import cynthia_websites_mini_shared/config/v4_1
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/option
import gleam/result
import gleam/string
import plinth/javascript/console
import tom

pub fn v4p1_mini_dynamic() -> decode.Decoder(v4_1.V4p1Mini) {
  use global <- decode.field("global", {
    use theme <- decode.field("theme", decode.string)
    use theme_dark <- decode.field("theme_dark", decode.string)
    use site_name <- decode.field("site_name", decode.string)
    use site_description <- decode.field("site_description", decode.string)
    decode.success(v4_1.V4p1MiniGlobal(
      theme:,
      theme_dark:,
      site_name:,
      site_description:,
    ))
  })
  use integrations <- decode.field("integrations", {
    use git <- decode.field("git", decode.bool)
    use sitemap <- decode.field("sitemap", decode.string)
    use crawlable_context <- decode.field("crawlable_context", decode.bool)
    decode.success(v4_1.V4p1MiniIntegrations(git:, sitemap:, crawlable_context:))
  })
  use posts <- decode.field("posts", {
    use comments <- decode.field("comments", {
      use comments <- field_or(
        field: "comments",
        decoder: {
          use variant <- decode.field("store", decode.string)
          case variant |> string.lowercase {
            "mastodon" -> decode.success(v4_1.CommentsMastodonStored)
            "github" -> {
              use username <- decode.field("username", decode.string)
              use repositoryname <- decode.field(
                "repositoryname",
                decode.string,
              )
              decode.success(v4_1.CommentsGithubStored(
                username:,
                repositoryname:,
              ))
            }
            "disabled" | "" -> decode.success(v4_1.CommentsDisabled)
            _ ->
              decode.failure(
                v4_1.CommentsDisabled,
                "v4_1.V4p1MiniPostsComments",
              )
          }
        },
        otherwise: v4_1.CommentsDisabled,
      )
      decode.success(comments)
    })
    decode.success(v4_1.V4p1MiniPosts(comments:))
  })
  decode.success(v4_1.V4p1Mini(global:, integrations:, posts:))
}

fn field_or(
  field field: String,
  decoder field_decoder: decode.Decoder(t),
  otherwise default: t,
  next next: fn(t) -> decode.Decoder(final),
) -> decode.Decoder(final) {
  use val <- decode.optional_field(
    field,
    option.None,
    decode.optional(field_decoder),
  )
  next(val |> option.unwrap(default))
}

pub fn vp4p1mini_toml(toml_source: String) {
  case tom.parse(toml_source) {
    Ok(toml) -> {
      let edition =
        tom.get_string(toml, ["edition"]) |> result.map(string.lowercase)
      let version =
        result.or(tom.get_float(toml, ["version"]), {
          tom.get_int(toml, ["version"]) |> result.map(int.to_float)
        })

      case edition, version {
        Ok("mini"), Ok(4.1) -> {
          v4_1.V4p1Mini(
            global: {
              let theme =
                tom.get_string(toml, ["global", "theme", "default"])
                |> result.unwrap({
                  tom.get_string(toml, ["global", "theme"])
                  |> result.unwrap(v4_1.new().global.theme)
                })
              v4_1.V4p1MiniGlobal(
                theme:,
                theme_dark: result.unwrap(
                  tom.get_string(toml, ["global", "theme", "dark"]),
                  theme,
                ),
                site_name: tom.get_string(toml, ["global", "site_name"])
                  |> result.unwrap(v4_1.new().global.site_name),
                site_description: tom.get_string(toml, [
                  "global",
                  "site_description",
                ])
                  |> result.unwrap(v4_1.new().global.site_description),
              )
            },
            integrations: v4_1.V4p1MiniIntegrations(
              git: tom.get_bool(toml, [
                "integrations",
                "git",
              ])
                |> result.unwrap(v4_1.new().integrations.git),
              sitemap: tom.get_string(toml, [
                "integrations",
                "sitemap",
              ])
                |> result.unwrap(v4_1.new().integrations.sitemap),
              crawlable_context: tom.get_bool(toml, [
                "integrations",
                "crawlable_context",
              ])
                |> result.unwrap(v4_1.new().integrations.crawlable_context),
            ),
            posts: v4_1.V4p1MiniPosts(comments: {
              case
                tom.get_string(toml, ["posts", "comments", "store"])
                |> result.unwrap("disabled")
              {
                "mastodon" -> v4_1.CommentsMastodonStored
                "github" -> {
                  case
                    tom.get_string(toml, ["posts", "comments", "username"]),
                    tom.get_string(toml, ["posts", "comments", "repositoryname"])
                  {
                    Ok(username), Ok(repositoryname) ->
                      v4_1.CommentsGithubStored(username:, repositoryname:)
                    _, _ -> v4_1.new().posts.comments
                  }
                }
                _ -> v4_1.CommentsDisabled
              }
            }),
          )
          |> Ok
        }
        Ok("mini"), Ok(4.0) -> {
          decodes.v4mini_toml(toml_source) |> result.map(v4.upgrade)
        }
        Ok(_), Error(_) | Error(_), Ok(_) -> {
          console.error("Unknown combination of edition and version.")
          Error(Nil)
        }
        Error(_), Error(_) -> {
          console.log("Could not parse TOML!")
          Error(Nil)
        }
        Ok(edition), Ok(version) -> {
          console.error(
            "Config version "
            <> version |> float.to_string()
            <> " with edition '"
            <> edition
            <> "' is NOT supported by this version of Cynthia."
            <> "\n  Usually this means one of these options:"
            <> "\n - it was written for a different edition"
            <> "\n - it is invalid"
            <> "\n - or this version of cynthia is too old to understand this file."
            <> case edition == "mini" {
              True ->
                "\n\n\n It seems to be that last option, since the edition it is written for, does match 'mini'."
              False -> ""
            },
          )
          Error(Nil)
        }
      }
    }
    // We don't propogate upwards, we give back a Error value but inform here and then exit upstream.
    Error(_) -> {
      console.log("Could not parse TOML!")
      Error(Nil)
    }
  }
}
