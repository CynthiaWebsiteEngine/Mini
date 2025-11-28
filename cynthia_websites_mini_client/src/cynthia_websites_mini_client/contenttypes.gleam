import gleam/dynamic/decode
import gleam/json

// Content main type ----------------------------------------------------------------------------
/// Type storing all info it parses from files and json metadatas
pub type Content {
  Content(
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    inner_plain: String,
    data: ContentData,
  )
}

pub fn content_decoder() -> decode.Decoder(Content) {
  use filename <- decode.field("filename", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use inner_plain <- decode.field("inner_plain", decode.string)
  use data <- decode.field("data", content_data_decoder())
  decode.success(Content(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain:,
    data:,
  ))
}

pub fn content_decoder_and_merger(
  inner_plain: String,
  filename: String,
) -> decode.Decoder(Content) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use data <- decode.field("data", content_data_decoder())
  decode.success(Content(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain:,
    data:,
  ))
}

pub fn encode_content(content: Content) -> json.Json {
  let Content(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain:,
    data:,
  ) = content
  json.object([
    #("filename", json.string(filename)),
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("layout", json.string(layout)),
    #("permalink", json.string(permalink)),
    #("inner_plain", json.string(inner_plain)),
    #("data", encode_content_data(data)),
  ])
}

pub fn encode_content_for_fs(content: Content) -> json.Json {
  let Content(
    filename: _,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain: _,
    data:,
  ) = content
  json.object([
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("layout", json.string(layout)),
    #("permalink", json.string(permalink)),
    #("data", encode_content_data(data)),
  ])
}

// Content data type ----------------------------------------------------------------------------

pub type ContentData {
  /// Post metadata
  PostData(
    /// Date string: This is decoded as a string, then recoded and decoded again to make sure it complies with ISO 8601.
    /// # Date published
    /// Stores the date on which the post was published.
    date_published: String,
    /// Date string: This is decoded as a string, then recoded and decoded again to make sure it complies with ISO 8601.
    /// # Date updated
    /// Stores the date on which the post was last updated.
    date_updated: String,
    /// Category this post belongs to
    category: String,
    /// Tags that belong to this post
    tags: List(String),
  )
  /// Page metadata
  PageData(
    /// In which menus this page should appear
    in_menus: List(Int),
    /// Hide the block with title and description for a page.
    hide_meta_block: Bool,
  )
}

pub fn content_data_decoder() -> decode.Decoder(ContentData) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "post_data" -> {
      use date_published <- decode.field("date_published", decode.string)
      use date_updated <- decode.field("date_updated", decode.string)
      use category <- decode.field("category", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      decode.success(PostData(date_published:, date_updated:, category:, tags:))
    }
    "page_data" -> {
      use in_menus <- decode.field("in_menus", decode.list(decode.int))
      use hide_meta_block <- decode.optional_field(
        "hide_meta",
        False,
        decode.bool,
      )
      decode.success(PageData(in_menus:, hide_meta_block:))
    }
    _ ->
      decode.failure(
        PostData(date_published: "", date_updated: "", category: "", tags: []),
        "ContentData",
      )
  }
}

pub fn encode_content_data(content_data: ContentData) -> json.Json {
  case content_data {
    PostData(date_published:, date_updated:, category:, tags:) ->
      json.object([
        #("type", json.string("post_data")),
        #("date_published", json.string(date_published)),
        #("date_updated", json.string(date_updated)),
        #("category", json.string(category)),
        #("tags", json.array(tags, json.string)),
      ])
    PageData(in_menus:, hide_meta_block:) ->
      json.object([
        #("type", json.string("page_data")),
        #("in_menus", json.array(in_menus, json.int)),
        #("hide_meta", json.bool(hide_meta_block)),
      ])
  }
}
// End of module.
