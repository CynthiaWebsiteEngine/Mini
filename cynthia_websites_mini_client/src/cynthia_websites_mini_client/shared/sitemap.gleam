import cynthia_websites_mini_client/configtype.{type CompleteData}
import cynthia_websites_mini_client/contenttypes
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute.{attribute}
import lustre/element.{element}

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

  let post_entries =
    list.filter(data.content, fn(post) {
      case post.data {
        contenttypes.PostData(..) -> True
        contenttypes.PageData(..) -> !string.starts_with(post.permalink, "!")
      }
    })
    |> list.map(fn(post) {
      // We'll get both lastmod date and url for each post
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
      #(url, lastmod)
    })

  // Add homepage with default values since it doesn't have dates
  let all_entries = [#(base_url, ""), ..post_entries]

  // Create the XML using lustre
  let urlset =
    element(
      "urlset",
      [attribute("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")],
      list.map(all_entries, fn(entry) {
        let #(url, lastmod) = entry
        let mut_elements = [
          element("loc", [], [element.text(url)]),
          element("changefreq", [], [element.text("weekly")]),
          element("priority", [], [element.text("1.0")]),
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
