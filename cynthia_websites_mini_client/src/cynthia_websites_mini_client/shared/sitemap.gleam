import cynthia_websites_mini_client/configtype.{type CompleteData}
import cynthia_websites_mini_client/contenttypes
import cynthia_websites_mini_client/pottery
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute.{attribute}
import lustre/element.{type Element, element}

pub fn generate_sitemap(data: CompleteData) -> option.Option(String) {
  use base_url: String <- option.then(
    option.then(data.sitemap, fn(url) {
      {
        case url |> string.ends_with("/") {
          True -> url
          False -> url <> "/"
        }
        <> "#"
      }
      |> option.Some
    }),
  )

  let all_entries =
    data.content
    |> list.map(fn(post) {
      // We'll get the url, dates, title and description for each post
      let url = base_url <> post.permalink
      let lastmod = case post.data {
        contenttypes.PostData(
          date_published: published,
          date_updated: updated,
          ..,
        ) ->
          // If post has an updated date use that, otherwise use published date
          case updated {
            "" -> published
            // Empty string means no update date
            _ -> updated
            // Use update date if available
          }
        contenttypes.PageData(..) -> ""
        // Pages don't have dates yet
      }
      #(url, lastmod, post.title, post.description)
    })
    |> list.map(fn(entry) {
      // If the entry is the homepage, make it / instead of the base URL
      let #(url, lastmod, title, desc) = entry
      let url = case url {
        "" -> {
          // If the URL is empty, we assume it's the homepage
          base_url <> "/"
        }
        _ -> url
      }
      #(url, lastmod, title, desc)
    })

  // Create the XML using lustre
  let urlset =
    element(
      "urlset",
      [attribute("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")],
      list.map(all_entries, fn(entry) {
        let #(url, lastmod, _title, _desc) = entry
        let mut_elements = [
          element("loc", [], [element.text(url)]),
          element("changefreq", [], [element.text("weekly")]),
          element("priority", [], [element.text("1.0")]),
          // Description and title are not standard in sitemaps, sadly.
        // cdata_into_lustre("title", element.text(title)),
        // cdata_into_lustre("description", pottery.parse_html(desc, "descr.dj")),
        ]
        // Only add lastmod if we have a date
        let elements = case lastmod {
          "" -> mut_elements
          date -> [element("lastmod", [], [element.text(date)]), ..mut_elements]
        }
        element("url", [], elements)
      }),
    )

  // Convert the XML tree to a string
  option.Some(element.to_readable_string(urlset))
}
// fn cdata_into_lustre(
//   element_tag: String,
//   inner: Element(a),
// ) -> element.Element(a) {
//   // Create a CDATA section in Lustre
//   // as a string :
//   // <![CDATA[ ... ]]>
//   element.unsafe_raw_html(
//     "",
//     element_tag,
//     [],
//     "<![CDATA[" <> element.to_string(inner) <> "]]>",
//   )
// }
