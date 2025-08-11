import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/contenttypes
import gleam/list
import gleam/string

/// Generates JSON-LD structured data for the website.
pub fn generate_jsonld(cd: configtype.CompleteData) -> String {
  let base_jsonld = "{
    \"@context\": \"https://schema.org\",
    \"@type\": \"Website\",
    \"name\": \"" <> cd.global_site_name <> "\",
    \"description\": \"" <> cd.global_site_description <> "\",
    \"@graph\": ["

  let content_jsonld =
    cd.content
    |> list.map(fn(c) {
      let content_type = case c.data {
        contenttypes.PostData(..) -> "BlogPosting"
        contenttypes.PageData(..) -> "WebPage"
      }

      let dates = case c.data {
        contenttypes.PostData(
          date_published: published,
          date_updated: updated,
          category: _,
          tags: _,
        ) -> "\"datePublished\": \"" <> published <> "\",
           \"dateModified\": \"" <> updated <> "\","
        _ -> ""
      }

      "{
        \"@type\": \"" <> content_type <> "\",
        \"@id\": \"" <> c.permalink <> "\",
        \"headline\": \"" <> c.title <> "\",
        \"description\": \"" <> c.description <> "\",
        " <> dates <> "
        \"mainEntityOfPage\": {
          \"@type\": \"WebPage\",
          \"@id\": \"" <> c.permalink <> "\"
        }
      }"
    })
    |> string.join(",\n")

  base_jsonld <> content_jsonld <> "]}"
}
