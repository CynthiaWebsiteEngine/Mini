import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages.{type Msg}
import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_client/pageloader/postlistloader
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/contenttypes
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import houdini
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import odysseus

pub fn main(model: Model) -> Element(Msg) {
  case model.complete_data {
    None -> initial_view()
    Some(complete_data) -> {
      let content =
        complete_data.content
        |> list.find(fn(content) { { content.permalink == model.path } })
        |> result.lazy_unwrap(fn() {
          contenttypes.Content(
            filename: "notfound.md",
            title: "Page not found",
            description: model.path,
            layout: "theme",
            permalink: "404",
            inner_plain: "# 404!\n\nThe page you are looking for does not exist.",
            data: contenttypes.PageData([]),
          )
        })
      let content = case model.path {
        "!" <> a -> {
          let #(tit, desc) = case content.filename {
            "notfound.md" -> #(None, None)
            _ -> #(Some(content.title), Some(content.description))
          }
          case a {
            "/category/" <> category -> {
              let title = option.unwrap(tit, "Posts in category: " <> category)
              let description =
                option.unwrap(
                  desc,
                  "A postlist of all posts in the category: " <> category,
                )

              contenttypes.Content(
                title:,
                description:,
                layout: "default",
                permalink: model.path,
                filename: "postlist.html",
                data: contenttypes.PageData([]),
                inner_plain: postlistloader.postlist_by_category(
                  model,
                  category,
                )
                  |> element.to_string,
              )
            }
            "/tag/" <> tag -> {
              let title = option.unwrap(tit, "Posts with tag: " <> tag)
              let description =
                option.unwrap(
                  desc,
                  "A postlist of all posts tagged with " <> tag,
                )
              contenttypes.Content(
                title:,
                description:,
                layout: "default",
                permalink: model.path,
                filename: "postlist.html",
                data: contenttypes.PageData([]),
                inner_plain: postlistloader.postlist_by_tag(model, tag)
                  |> element.to_string,
              )
            }
            "/search/" <> search_term -> {
              let title =
                option.unwrap(tit, "Search results for: " <> search_term)
              let description = option.unwrap(desc, "")
              contenttypes.Content(
                title:,
                description:,
                layout: "default",
                permalink: model.path,
                filename: "postlist.html",
                data: contenttypes.PageData([]),
                inner_plain: postlistloader.postlist_by_search_term(
                  model,
                  search_term,
                )
                  |> element.to_string,
              )
            }
            _ -> {
              let title = option.unwrap(tit, "All posts")
              let description = "A postlist of all posts."
              contenttypes.Content(
                title:,
                description:,
                layout: "default",
                permalink: model.path,
                filename: "postlist.html",
                data: contenttypes.PageData([]),
                inner_plain: postlistloader.postlist_all(model)
                  |> element.to_string,
              )
            }
          }
        }
        _ -> content
      }
      let assert Ok(_) =
        dom.push_title(
          houdini.escape(utils.js_trim(odysseus.unescape(content.title))),
        )
      pottery.render_content(model, content)
    }
  }
}

pub fn initial_view() -> Element(Msg) {
  let assert Ok(_) = dom.push_title("Cynthia Mini: Loading...")
  html.div(
    [
      attribute.class(
        "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
      ),
    ],
    [
      html.div([attribute.class("card bg-primary text-primary-content w-96")], [
        html.div([attribute.class("card-body")], [
          html.h2([attribute.class("card-title")], [html.text("Cynthia Mini")]),
          html.p([], [html.text("Loading the page you want...")]),
          html.div([attribute.class("card-actions justify-end")], [
            html.span([attribute.class("loading loading-bars loading-lg")], []),
          ]),
        ]),
      ]),
    ],
  )
}
