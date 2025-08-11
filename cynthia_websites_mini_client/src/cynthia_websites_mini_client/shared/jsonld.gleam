import cynthia_websites_mini_client
import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/contenttypes
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/pottery
import gleam/list
import gleam/result
import gleam/string
import lustre/element

/// Generates JSON-LD structured data for the website.
pub fn generate_jsonld(cd: configtype.CompleteData) -> String {
  let base_jsonld = "{
    \"@context\": \"https://schema.org\",
    \"@type\": \"Website\",
    \"name\": " <> cd.global_site_name
    |> dom.jsonify_string()
    |> result.unwrap("Site name is invalid") <> ",
    \"description\": " <> cd.global_site_description
    |> dom.jsonify_string()
    |> result.unwrap("Site description is invalid") <> ",
    \"generator\": {
      \"@type\": \"SoftwareApplication\",
      \"name\": \"CynthiaMini Website Engine\",
      \"url\": \"https://github.com/CynthiaWebsiteEngine/Mini-docs\",
      \"version\": \"" <> cynthia_websites_mini_client.version() <> "\"
    },
    \"@graph\": ["

  let content_jsonld =
    cd.content
    |> list.map(fn(c) {
      let title = {
        result.unwrap(dom.jsonify_string(c.title), "Title is invalid")
      }
      let description = {
        pottery.parse_html(c.description, "descr.dj")
        |> element.to_string()
        |> dom.jsonify_string()
        |> result.unwrap("Description is invalid")
      }
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
        ) -> "\n\"datePublished\": \"" <> published <> "\",
           \"dateModified\": \"" <> updated <> "\","
        _ -> ""
      }

      "{
        \"@type\": \"" <> content_type <> "\",
        \"@id\": " <> c.permalink |> dom.jsonify_string() |> result.unwrap("/") <> ",
        \"headline\": " <> title <> ",
        \"description\": " <> description <> "," <> dates <> "
        \"mainEntityOfPage\": {
          \"@type\": \"WebPage\",
          \"@id\": " <> c.permalink
      |> dom.jsonify_string()
      |> result.unwrap("/") <> "
        }
      }"
    })
    |> string.join(",\n")

  base_jsonld <> content_jsonld <> "]}"
}
