import cynthia_websites_mini_client/contenttypes.{PostData}
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/utils
import gleam/bool
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html

fn fetch_post_list(model: Model) {
  model.complete_data
  |> option.to_result(Nil)
  |> result.map(fn(complete) {
    complete.content
    |> list.filter(fn(item) {
      case item.data {
        PostData(..) -> True
        _ -> False
      }
    })
  })
  |> result.unwrap([])
}

pub fn postlist_all(model: Model) {
  fetch_post_list(model)
  |> postlist_to_html
}

pub fn postlist_by_tag(model: Model, card: String) {
  fetch_post_list(model)
  |> list.filter(fn(post) {
    let assert PostData(
      date_published: _date_published,
      date_updated: _date_updated,
      category: _category,
      tags:,
    ): contenttypes.ContentData = post.data
    tags |> list.contains(card)
  })
  |> postlist_to_html
}

pub fn postlist_by_category(model: Model, cat: String) {
  fetch_post_list(model)
  |> list.filter(fn(post) {
    let assert PostData(
      date_published: _date_published,
      date_updated: _date_updated,
      category:,
      tags: _tags,
    ) = post.data
    category == cat
  })
  |> postlist_to_html
}

pub fn postlist_by_search_term(model: Model, search_term: String) {
  let term = search_term |> string.lowercase

  // Get all content, not just posts
  model.complete_data
  |> option.to_result(Nil)
  |> result.map(fn(complete) { complete.content })
  |> result.unwrap([])
  |> list.filter(fn(item) {
    let title_contains =
      item.title
      |> string.lowercase
      |> string.contains(term)

    let description_contains =
      item.description
      |> string.lowercase
      |> string.contains(term)

    let content_contains =
      item.inner_plain
      |> string.lowercase
      |> string.contains(term)

    title_contains || description_contains || content_contains
  })
  |> postlist_to_html
}

fn postlist_to_html(
  posts: List(contenttypes.Content),
) -> element.Element(messages.Msg) {
  let ordered_posts =
    posts
    |> list.sort(fn(post_a: contenttypes.Content, post_b: contenttypes.Content) {
      let a_date = case post_a.data {
        PostData(date_updated:, ..) ->
          utils.whatever_timestamp_to_unix_millis(date_updated)
        // For pages there is no date. Use 0 so they go to the end of the list
        contenttypes.PageData(..) -> 0
      }
      let b_date = case post_b.data {
        PostData(date_updated:, ..) ->
          utils.whatever_timestamp_to_unix_millis(date_updated)
        contenttypes.PageData(..) -> 0
      }
      int.compare(b_date, a_date)
    })

  let postlist =
    ordered_posts
    |> list.map(fn(item) {
      case item.data {
        PostData(
          date_published:,
          date_updated:,
          category: _category,
          tags: _tags,
        ) -> {
          let post = item
          html.li([attribute.class("list-row p-10")], [
            html.a(
              [
                attribute.href(post.permalink),
                attribute.class("post__link"),
              ],
              [
                html.div(
                  [
                    attribute.class(
                      "text-xs uppercase font-semibold opacity-60",
                    ),
                  ],
                  case date_published == date_updated {
                    True -> [html.text(date_published)]
                    False -> [
                      html.text(date_published),
                      html.text(" (updated "),
                      html.text(date_updated),
                      html.text(")"),
                    ]
                  },
                ),
                html.div([attribute.class("text-center text-xl")], [
                  html.text(post.title),
                ]),
                html.blockquote(
                  [
                    attribute.class(
                      "list-col-wrap text-sm border-l-2 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
                    ),
                  ],
                  [pottery.parse_html(post.description, "descr.dj")],
                ),
              ],
            ),
          ])
        }
        contenttypes.PageData(..) -> {
          let page = item
          let postlist = string.starts_with(page.permalink, "!")
          html.li([attribute.class("list-row p-10")], [
            html.a(
              [
                attribute.href(page.permalink),
                attribute.class("post__link"),
              ],
              [
                html.div(
                  [attribute.class("text-center text-xl")],
                  [
                    {
                      bool.guard(
                        postlist,
                        html.div(
                          [
                            attribute.class(
                              "badge badge-secondary badge-outline m-2",
                            ),
                          ],
                          [html.text("post list")],
                        ),
                        fn() {
                          html.div(
                            [attribute.class("badge badge-neutral m-2")],
                            [html.text("page")],
                          )
                        },
                      )
                    },
                    html.text(page.title),
                  ]
                    |> list.reverse(),
                ),
              ],
            ),
            bool.guard(postlist, html.br([]), fn() {
              html.blockquote(
                [
                  attribute.class(
                    "list-col-wrap text-sm border-l-2 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
                  ),
                ],
                [pottery.parse_html(page.description, "descr.dj")],
              )
            }),
          ])
        }
      }
    })
  html.ul(
    [attribute.class("postlist list bg-base-200 rounded-box shadow-md")],
    postlist,
  )
}
