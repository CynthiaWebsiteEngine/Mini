//// Site.json gleam type format and en/decoder.

import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/config/v4_1/decodes
import gleam/dict
import gleam/dynamic/decode
import gleam/option

/// This is the content of site.json, factually the entire site
pub type SiteJSON {
  SiteJSON(
    config: v4_1.V4p1Mini,
    // Slug, or a random number if not set and the content
    content: dict.Dict(String, Content),
  )
}

pub fn site_json_decoder() -> decode.Decoder(SiteJSON) {
  use config <- decode.field("config", decodes.v4p1_mini_dynamic())
  use content: dict.Dict(String, Content) <- decode.field(
    "content",
    decode.dict(decode.string, {
      use variant <- decode.field("type", decode.string)
      case variant {
        "page" -> {
          use title <- decode.field("title", decode.string)
          use description <- decode.field("description", decode.string)
          use layout <- decode.field("layout", decode.optional(decode.string))
          use content <- decode.field("content", decode.string)
          use in_menus <- decode.field("in_menus", decode.list(decode.int))
          use hide_meta_block <- decode.field("hide_meta_block", decode.bool)
          decode.success(Page(
            title:,
            description:,
            layout:,
            content:,
            in_menus:,
            hide_meta_block:,
          ))
        }
        "post" -> {
          use title <- decode.field("title", decode.string)
          use description <- decode.field("description", decode.string)
          use layout <- decode.field("layout", decode.optional(decode.string))
          use content <- decode.field("content", decode.string)
          use date_published <- decode.field("date_published", decode.string)
          use date_updated <- decode.field("date_updated", decode.string)
          use category <- decode.field("category", decode.string)
          use tags <- decode.field("tags", decode.list(decode.string))
          use mastodon_comments <- field_or(
            field: "mastodon-comments",
            decoder: decode.optional({
              use instance <- decode.field("instance", decode.string)
              use id <- decode.field("id", decode.string)
              decode.success(MastodonStatus(instance:, id:))
            }),
            otherwise: option.None,
          )

          decode.success(Post(
            title:,
            description:,
            layout:,
            content:,
            date_published:,
            date_updated:,
            category:,
            tags:,
            mastodon_comments:,
          ))
        }
        _ ->
          decode.failure(
            Page("failure", "failure", option.None, "Failure", [], False),
            "Content",
          )
      }
    }),
  )
  decode.success(SiteJSON(config:, content:))
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

pub type Content {
  Page(
    /// Page title
    title: String,
    /// Description, converted to HTML beforehand.
    description: String,
    /// Layout or default
    layout: option.Option(String),
    /// Page content, converted to HTML beforehand.
    content: String,
    /// In which menus this page should appear
    in_menus: List(Int),
    /// Hide the block with title and description for a page.
    hide_meta_block: Bool,
  )
  Post(
    /// Page title
    title: String,
    /// Description, converted to HTML beforehand.
    description: String,
    /// Layout or default
    layout: option.Option(String),
    /// Page content, converted to HTML beforehand.
    content: String,
    /// Date string -- But it's unchecked
    /// Stores the date on which the post was published.
    date_published: String,
    /// Date string -- But it's unchecked
    /// # Date updated
    /// Stores the date on which the post was last updated.
    date_updated: String,
    /// Category this post belongs to
    category: String,
    /// Tags that belong to this post
    tags: List(String),
    /// Mastodon instance and post id to link to for comments.
    mastodon_comments: option.Option(MastodonStatus),
  )
}

/// Mastodon instance and post id to link to for comments.
pub type MastodonStatus {
  MastodonStatus(instance: String, id: String)
}
