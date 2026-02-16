//// Cynthia Mini v4 Config format

import cynthia_websites_mini_shared/config/v4_1
import gleam/string

pub type V4mini {
  V4mini(
    global: V4miniGlobal,
    integrations: V4miniIntegrations,
    posts: V4miniPosts,
  )
}

pub type V4miniGlobal {
  V4miniGlobal(
    theme: String,
    theme_dark: String,
    colour: String,
    site_name: String,
    site_description: String,
  )
}

pub type V4miniIntegrations {
  V4miniIntegrations(git: Bool, sitemap: String, crawlable_context: Bool)
}

pub type V4miniPosts {
  V4miniPosts(comment_repo: String)
}

pub fn upgrade(in: V4mini) -> v4_1.V4p1Mini {
  v4_1.V4p1Mini(
    global: v4_1.V4p1MiniGlobal(
      site_description: in.global.site_description,
      theme: in.global.theme,
      theme_dark: in.global.theme_dark,
      site_name: in.global.site_name,
    ),
    integrations: v4_1.V4p1MiniIntegrations(
      git: in.integrations.git,
      sitemap: in.integrations.sitemap,
      crawlable_context: in.integrations.crawlable_context,
    ),
    posts: v4_1.V4p1MiniPosts(comments: {
      case in.posts.comment_repo |> string.lowercase {
        "" -> v4_1.CommentsDisabled
        "mastodon" -> v4_1.CommentsMastodonStored
        _ -> {
          case in.posts.comment_repo |> string.split_once("/") {
            Ok(#(username, repositoryname)) ->
              v4_1.CommentsGithubStored(username:, repositoryname:)
            _ -> v4_1.CommentsDisabled
          }
        }
      }
    }),
  )
}
