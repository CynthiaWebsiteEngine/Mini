import cynthia_websites_mini_shared/config/v4
import gleam/dynamic/decode
import plinth/javascript/console
import tom

pub fn v4mini_dynamic() -> decode.Decoder(v4.V4mini) {
  use global <- decode.field("global", {
    use theme <- decode.field("theme", decode.string)
    use theme_dark <- decode.field("theme_dark", decode.string)
    use colour <- decode.field("colour", decode.string)
    use site_name <- decode.field("site_name", decode.string)
    use site_description <- decode.field("site_description", decode.string)
    decode.success(v4.V4miniGlobal(
      theme:,
      theme_dark:,
      colour:,
      site_name:,
      site_description:,
    ))
  })
  use integrations <- decode.field("integrations", {
    use git <- decode.field("git", decode.bool)
    use sitemap <- decode.field("sitemap", decode.string)
    use crawlable_context <- decode.field("crawlable_context", decode.bool)
    decode.success(v4.V4miniIntegrations(git:, sitemap:, crawlable_context:))
  })
  use posts <- decode.field("posts", {
    use comment_repo <- decode.field("comment_repo", decode.string)
    decode.success(v4.V4miniPosts(comment_repo:))
  })
  decode.success(v4.V4mini(global:, integrations:, posts:))
}

pub fn v4mini_toml(toml_source: String) -> Result(v4.V4mini, Nil) {
  case tom.parse(toml_source) {
    Ok(toml) -> {
      v4.V4mini(
        global: {
          let theme = tom.get_string(toml, ["global", "theme"]) |> unsafe_unwrap

          v4.V4miniGlobal(
            theme:,
            theme_dark: tom.get_string(toml, ["global", "theme", "dark"])
              |> unsafe_unwrap,
            site_name: tom.get_string(toml, ["global", "site_name"])
              |> unsafe_unwrap,
            site_description: tom.get_string(toml, [
              "global",
              "site_description",
            ])
              |> unsafe_unwrap,
            colour: tom.get_string(toml, ["global", "colour"])
              |> unsafe_unwrap,
          )
        },
        integrations: v4.V4miniIntegrations(
          git: tom.get_bool(toml, [
            "integrations",
            "git",
          ])
            |> unsafe_unwrap,
          sitemap: tom.get_string(toml, [
            "integrations",
            "sitemap",
          ])
            |> unsafe_unwrap,
          crawlable_context: tom.get_bool(toml, [
            "integrations",
            "crawlable_context",
          ])
            |> unsafe_unwrap,
        ),
        posts: v4.V4miniPosts(comment_repo: {
          tom.get_string(toml, [
            "posts",
            "comment_repo",
          ])
          |> unsafe_unwrap
        }),
      )
      |> Ok
    }
    // We don't propogate upwards, we give back a Error value but inform here and then exit upstream.
    Error(_) -> {
      console.log("Could not parse TOML!")
      Error(Nil)
    }
  }
}

fn unsafe_unwrap(v: Result(s, _)) {
  case v {
    Ok(a) -> a
    Error(_) -> {
      let d =
        "Encountered invalid value in legacy config, Cynthia Mini won't try to recover for this in legacy configs."
      console.error(d)
      panic as d
    }
  }
}
