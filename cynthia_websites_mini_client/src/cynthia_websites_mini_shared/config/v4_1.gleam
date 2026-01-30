//// Cynthia v4.1 [external] Config format

pub type V4p1Mini {
  V4p1Mini(
    global: V4p1MiniGlobal,
    integrations: V4p1MiniIntegrations,
    posts: V4p1MiniPosts,
  )
}

pub type V4p1MiniGlobal {
  V4p1MiniGlobal(
    theme: String,
    theme_dark: String,
    site_name: String,
    site_description: String,
  )
}

pub type V4p1MiniIntegrations {
  V4p1MiniIntegrations(git: Bool, sitemap: String, crawlable_context: Bool)
}

pub type V4p1MiniPosts {
  V4p1MiniPosts(comments: V4p1MiniPostsComments)
}

pub type V4p1MiniPostsComments {
  CommentsMastodonStored
  CommentsGithubStored(username: String, repositoryname: String)
  CommentsDisabled
}

pub fn new() -> V4p1Mini {
  V4p1Mini(
    global: V4p1MiniGlobal(
      theme: "autumn",
      theme_dark: "night",
      site_name: "My Site",
      site_description: "A big site on a mini Cynthia!",
    ),
    integrations: V4p1MiniIntegrations(
      git: True,
      sitemap: "",
      crawlable_context: False,
    ),
    posts: V4p1MiniPosts(comments: CommentsDisabled),
  )
}
