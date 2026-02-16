//// Site.json gleam type format and en/decoder.

import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/config/v4_1/decodes
import cynthia_websites_mini_shared/config/v4_1/encodes
import cynthia_websites_mini_shared/ffi
import gbor
import gbor/encode as gbor_encode
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// This is the content of site.json, factually the entire site
/// In v2 this is replaced with CBOR, but the point still stands and interaction does not change.
pub type SiteJSON {
  SiteJSON(
    config: v4_1.V4p1Mini,
    // Slug, or a random number if not set and the content
    content: dict.Dict(String, Content),
  )
}

pub fn site_json(site_json: SiteJSON) -> String {
  let SiteJSON(config:, content:) = site_json
  json.object([
    #("config", encodes.v4p1_mini_json(config)),
    #("content", json.dict(content, fn(string) { string }, content_to_json)),
  ])
  |> json.to_string()
}

pub fn site_cbor(
  site_json: SiteJSON,
) -> Result(BitArray, gbor_encode.EncodeError) {
  let SiteJSON(config:, content:) = site_json
  gbor.CBMap([
    #(gbor.CBString("config"), encodes.v4p1_mini_cbor(config)),
    #(
      gbor.CBString("content"),
      dict.to_list(content)
        |> list.map(fn(item) {
          #(gbor.CBString(item.0), content_to_cbor(item.1))
        })
        |> gbor.CBMap,
    ),
  ])
  |> gbor_encode.to_bit_array
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
          let layout = case
            layout == Some("theme")
            || layout == Some("")
            || layout == Some("site")
          {
            True -> None
            False -> layout
          }
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
          let layout = case
            layout == Some("theme")
            || layout == Some("")
            || layout == Some("site")
          {
            True -> None
            False -> layout
          }
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
        _ -> decode.failure(content_zerodata(), "Content")
      }
    }),
  )
  decode.success(SiteJSON(config:, content:))
}

pub fn site_cbor_decoder(body: BitArray) -> Result(SiteJSON, String) {
  use dyn <- result.try(
    ffi.cbor_to_dyn(body)
    |> result.replace_error("Could not turn CBOR into dynamic JS data."),
  )
  use val <- result.try(
    decode.run(dyn, site_json_decoder()) |> result.map_error(string.inspect),
  )
  Ok(val)
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

pub fn metadata_decode(
  metajson jsonstring: String,
  htmlcontent content: String,
) -> Result(#(String, Content), json.DecodeError) {
  json.parse(
    jsonstring,
    decode.one_of(old_metadata_decoder(content), [metadata_decoder(content)]),
  )
}

fn metadata_decoder(content: String) -> decode.Decoder(#(String, Content)) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- field_or("layout", decode.optional(decode.string), option.None)
  let layout = case
    layout == Some("theme") || layout == Some("") || layout == Some("site")
  {
    True -> None
    False -> layout
  }
  use slug <- decode.field("slug", decode.string)
  use variant <- decode.field("kind", decode.string)
  case variant {
    "page" -> {
      use in_menus <- decode.field("in_menus", decode.list(decode.int))
      use hide_meta_block <- decode.field("hide_meta_block", decode.bool)
      decode.success(#(
        slug,
        Page(
          title:,
          description:,
          layout:,
          content:,
          in_menus:,
          hide_meta_block:,
        ),
      ))
    }
    "post" -> {
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
      decode.success(#(
        slug,
        Post(
          title:,
          description:,
          layout:,
          content:,
          date_published:,
          date_updated:,
          category:,
          tags:,
          mastodon_comments:,
        ),
      ))
    }
    _ -> decode.failure(#("", content_zerodata()), "Content")
  }
}

fn content_zerodata() {
  Page("failure", "failure", option.None, "Failure", [], False)
}

pub fn old_metadata_decoder(
  content: String,
) -> decode.Decoder(#(String, Content)) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- field_or("layout", decode.optional(decode.string), option.None)
  let layout = case
    layout == Some("theme") || layout == Some("") || layout == Some("site")
  {
    True -> None
    False -> layout
  }
  use permalink <- decode.field("permalink", decode.string)
  let slug = {
    case permalink |> string.starts_with("#/") {
      True -> permalink |> string.drop_start(1)
      False ->
        case permalink |> string.starts_with("/#/") {
          True -> permalink |> string.drop_start(1)
          False -> permalink
        }
    }
  }
  use data <- decode.field("data", {
    use variant <- decode.field("type", decode.string)
    case variant {
      "post_data" -> {
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
          category:,
          tags:,
          date_published:,
          date_updated:,
          title:,
          description:,
          layout:,
          content:,
          mastodon_comments:,
        ))
      }
      "page_data" -> {
        use in_menus <- decode.field("in_menus", decode.list(decode.int))
        use hide_meta_block <- decode.optional_field(
          "hide_meta",
          False,
          decode.bool,
        )
        decode.success(Page(
          title:,
          description:,
          layout:,
          content:,
          in_menus:,
          hide_meta_block:,
        ))
      }
      _ -> decode.failure(content_zerodata(), "ContentData")
    }
  })
  decode.success(#(slug, data))
}

pub fn content_to_cbor(content: Content) {
  case content {
    Page(title:, description:, layout:, content:, in_menus:, hide_meta_block:) ->
      gbor.CBMap([
        #(gbor.CBString("type"), gbor.CBString("page")),
        #(gbor.CBString("title"), gbor.CBString(title)),
        #(gbor.CBString("description"), gbor.CBString(description)),
        #(gbor.CBString("layout"), case layout {
          option.None -> gbor.CBNull
          option.Some(value) -> gbor.CBString(value)
        }),
        #(gbor.CBString("content"), gbor.CBString({ content })),
        #(
          gbor.CBString("in_menus"),
          gbor.CBArray(list.map(in_menus, gbor.CBInt)),
        ),
        #(gbor.CBString("hide_meta_block"), gbor.CBBool(hide_meta_block)),
      ])
    Post(
      title:,
      description:,
      layout:,
      content:,
      date_published:,
      date_updated:,
      category:,
      tags:,
      mastodon_comments:,
    ) ->
      gbor.CBMap([
        #(gbor.CBString("type"), gbor.CBString("post")),
        #(gbor.CBString("title"), gbor.CBString(title)),
        #(gbor.CBString("description"), gbor.CBString(description)),
        #(gbor.CBString("layout"), case layout {
          option.None -> gbor.CBNull
          option.Some(value) -> gbor.CBString(value)
        }),
        #(gbor.CBString("content"), gbor.CBString(content)),
        #(gbor.CBString("date_published"), gbor.CBString(date_published)),
        #(gbor.CBString("date_updated"), gbor.CBString(date_updated)),
        #(gbor.CBString("category"), gbor.CBString(category)),
        #(gbor.CBString("tags"), gbor.CBArray(list.map(tags, gbor.CBString))),
        #(gbor.CBString("mastodon_comments"), case mastodon_comments {
          option.None -> gbor.CBNull
          option.Some(value) -> {
            let MastodonStatus(instance:, id:) = value
            gbor.CBMap([
              #(gbor.CBString("instance"), gbor.CBString(instance)),
              #(gbor.CBString("id"), gbor.CBString(id)),
            ])
          }
        }),
      ])
  }
}

pub fn content_to_json(content: Content) -> json.Json {
  case content {
    Page(title:, description:, layout:, content:, in_menus:, hide_meta_block:) ->
      json.object([
        #("type", json.string("page")),
        #("title", json.string(title)),
        #("description", json.string(description)),
        #("layout", case layout {
          option.None -> json.null()
          option.Some(value) -> json.string(value)
        }),
        #("content", json.string(content)),
        #("in_menus", json.array(in_menus, json.int)),
        #("hide_meta_block", json.bool(hide_meta_block)),
      ])
    Post(
      title:,
      description:,
      layout:,
      content:,
      date_published:,
      date_updated:,
      category:,
      tags:,
      mastodon_comments:,
    ) ->
      json.object([
        #("type", json.string("post")),
        #("title", json.string(title)),
        #("description", json.string(description)),
        #("layout", case layout {
          option.None -> json.null()
          option.Some(value) -> json.string(value)
        }),
        #("content", json.string(content)),
        #("date_published", json.string(date_published)),
        #("date_updated", json.string(date_updated)),
        #("category", json.string(category)),
        #("tags", json.array(tags, json.string)),
        #("mastodon_comments", case mastodon_comments {
          option.None -> json.null()
          option.Some(value) -> {
            let MastodonStatus(instance:, id:) = value
            json.object([
              #("instance", json.string(instance)),
              #("id", json.string(id)),
            ])
          }
        }),
      ])
  }
}

pub fn content_to_jsonld(
  content: Content,
  permalink: String,
) -> Result(String, Nil) {
  case content {
    Page(..) -> Error(Nil)
    Post(
      title:,
      description:,
      layout: _,
      content: _,
      date_published:,
      date_updated:,
      category: _,
      tags: _,
      mastodon_comments: _,
    ) ->
      Ok({
        json.object([
          #("@context", json.string("https://schema.org")),
          #("@type", json.string("BlogPosting")),
          #("mainEntityOfPage", {
            json.object([
              #("@type", json.string("WebPage")),
              #("@id", json.string(permalink)),
            ])
          }),
          #("headline", json.string(title)),
          #("description", json.string(description)),
          #("datepublished", json.string(date_published)),
          #("datemodified", json.string(date_updated)),
        ])
        |> json.to_string()
      })
  }
}

/// Mastodon instance and post id to link to for comments.
pub type MastodonStatus {
  MastodonStatus(instance: String, id: String)
}
