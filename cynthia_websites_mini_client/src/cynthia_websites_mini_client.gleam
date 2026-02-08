import chilp/widget/base as chilp_base
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/ffi
import cynthia_websites_mini_shared/themes_generated
import gleam/bool
import gleam/dict
import gleam/fetch
import gleam/float
import gleam/http/request
import gleam/int
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import plinth/browser/document as js_document
import plinth/browser/element as js_element
import plinth/browser/location as js_location
import plinth/browser/window as js_window
import plinth/javascript/console
import rsvp

// MODEL
pub type Model {
  Model(
    data: site_json.SiteJSON,
    route: Route,
    chilp_model: chilp_base.ChilpDataInYourModel(Msg),
    /// This used to be a Dict(Int, #(String, Path)), but
    /// 1. We use routes now.
    /// 2. We want a single item to be able to pop up in multiple menus!
    menu_items: List(#(Int, #(String, Route))),
  )
}

pub type ContentFilter {
  /// Any content coming up for the search term
  AnyFieldContains(String)
  /// All posts that have a certain category
  PostsByCategory(String)
  /// All posts that have a certain tag
  PostsByTag(String)
  /// All posts
  Posts
}

pub type Route {
  Index
  ContentList(ContentFilter)
  Content(slug: String)
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> {
      case ffi.is_browser() {
        True -> {
          case js_location.hash(js_window.location(js_window.self())) {
            Error(_) -> Index

            Ok("!/") -> ContentList(Posts)
            Ok("!/category/" <> cat) -> ContentList(PostsByCategory(cat))
            Ok("!/tag/" <> tag) -> ContentList(PostsByTag(tag))
            Ok("!/search/" <> tag) -> ContentList(AnyFieldContains(tag))

            Ok(c) -> {
              let d = "Unhandled hashroute: " <> c
              panic as d
            }
          }
        }
        False -> {
          Index
        }
      }
    }
    ["tagged", tag] -> ContentList(PostsByCategory(tag))
    ["category", cat] -> ContentList(PostsByTag(cat))
    ["post", slug] | ["page", slug] | ["content", slug] -> Content(slug:)

    _ -> NotFound(uri:)
  }
}

pub fn find_slug(contents: dict.Dict(String, site_json.Content), slug: String) {
  use item <- result.try({
    dict.to_list(contents)
    |> list.find(fn(c) {
      let slug_no_slashes = slug |> string.replace("/", " ") |> string.trim
      let c_no_slashes = c.0 |> string.replace("/", " ") |> string.trim

      c_no_slashes == slug_no_slashes
    })
  })
  Ok(item.1)
}

pub fn stringify_route(route: Route, model: Model) {
  case route {
    Index -> "/"
    Content(c) -> {
      find_slug(model.data.content, c)
      |> result.map(fn(content) {
        case content {
          site_json.Post(..) -> {
            "/post/" <> c
          }
          site_json.Page(..) -> {
            "/page/" <> c
          }
        }
      })
      |> result.unwrap("/content/" <> c)
    }
    NotFound(_) -> "/404"
    ContentList(PostsByCategory(cat)) -> "/category/" <> cat
    ContentList(PostsByTag(tag)) -> "/tagged/" <> tag
    ContentList(AnyFieldContains(q)) -> "/#!/search/" <> q
    ContentList(Posts) -> "/#!/"
  }
}

pub fn href(route: Route, model: Model) -> Attribute(msg) {
  stringify_route(route, model)
  |> attribute.href()
}

pub const version = ffi.version

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app =
    lustre.application(init, update, fn(model) {
      let #(title, elements) = view(model)
      {
        let sitetitle =
          {
            use a <- result.try(js_document.query_selector(
              "head>meta[property='og:site_name']",
            ))
            let b = a |> js_element.get_attribute("content")
            b
          }
          |> result.map(fn(x) { x <> " — " })
          |> result.unwrap("")
        js_document.set_title(sitetitle <> title)
      }
      elements
    })
  let assert Ok(sitejsonuri) = rsvp.parse_relative_uri("/site.cbor")
  let assert Ok(req) = request.to(sitejsonuri |> uri.to_string())
  use resp <- promise.try_await(fetch.send(req))
  use resp <- promise.try_await(fetch.read_bytes_body(resp))
  let result = site_json.site_cbor_decoder(resp.body)
  case resp.status, result {
    200, Ok(sitejson) -> {
      // On bootup, Lustre seems unable to clear #viewable, which we fix here by doing it manually.
      let assert Ok(_) =
        js_document.query_selector("#viewable")
        |> result.map(js_element.set_text_content(_, ""))
        as "Could not clear viewable."
      let assert Ok(_) = lustre.start(app, "#viewable", sitejson)
      Nil
    }
    // Failure here is okay, we just don't activate and hope the server served well enough pregenerations.
    _, Error(what) -> {
      console.log("application failure: " <> what)
      Nil
    }
    _, _ -> Nil
  }

  promise.resolve(Ok(Nil))
}

pub fn init(appdata: site_json.SiteJSON) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }
  let chilp_model = chilp_base.init(Chilp)
  let effect =
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })
  let menu_items = {
    appdata.content
    |> dict.to_list
    |> list.shuffle
    |> list.filter(keeping: fn(c) {
      case c.1 {
        site_json.Page(in_menus:, ..) -> {
          !{ in_menus |> list.is_empty }
        }
        site_json.Post(..) -> False
      }
    })
    |> list.map(fn(item) {
      let assert site_json.Page(title:, in_menus:, ..) = item.1

      list.map(in_menus, fn(menuid) {
        #(
          menuid,
          #(title, case item.0 {
            "/" -> Index
            "/" <> rest -> Content(rest)
            all -> Content(all)
          }),
        )
      })
    })
    |> list.flatten
    |> list.sort(fn(item_1, item_2) { string.compare(item_1.1.0, item_2.1.0) })
    // Sort some specials higher up.
    |> list.sort(fn(item_1, item_2) {
      let specials_1 =
        case item_1.1.0 |> string.lowercase() {
          "home" -> 2.0
          "blog" -> 0.2
          "contact" -> 1.0
          _ -> 0.0
        }
        |> float.add({
          case item_1.1.1 {
            Index -> 1.0
            _ -> 0.0
          }
        })

      let specials_2 =
        case item_2.1.0 |> string.lowercase() {
          "home" -> 2.0
          "blog" -> 0.2
          "contact" -> 1.0
          _ -> 0.0
        }
        |> float.add({
          case item_1.1.1 {
            Index -> 1.0
            _ -> 0.0
          }
        })
      float.compare(specials_1, specials_2)
    })
    |> list.reverse()
  }

  let model = Model(appdata, route:, chilp_model:, menu_items:)
  let effect = case appdata.config.posts.comments {
    v4_1.CommentsGithubStored(..) -> effect
    v4_1.CommentsDisabled -> effect
    // This site uses Chilp! Let's smoothen the UX by prefetching some of the posts in the background!
    v4_1.CommentsMastodonStored -> {
      appdata.content
      |> dict.values
      |> list.shuffle
      |> list.filter(keeping: fn(c) {
        case c {
          site_json.Post(mastodon_comments:, ..) -> {
            case mastodon_comments {
              Some(..) -> True
              _ -> False
            }
          }
          _ -> False
        }
      })
      |> list.map(fn(post) {
        let assert site_json.Post(mastodon_comments: Some(status), ..) = post
        let widget_ =
          chilp_base.new(
            instance: status.instance,
            post_id: status.id,
            chilp_model:,
          )
        chilp_base.force(chilp_model:, on: widget_)
      })
      |> list.shuffle
      |> list.append([effect], _)
      |> effect.batch
    }
  }

  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------
pub type Msg {
  UserNavigatedTo(route: Route)
  Chilp(chilp_base.ChilpMsg)
  UserSearchTerm(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> {
      let model = Model(..model, route:)
      #(model, effect.none())
    }
    Chilp(chilp_msg) -> {
      let #(chilp_model, chilp_effects) =
        chilp_base.update(chilp_msg, model.chilp_model, browse_to)
      #(Model(..model, chilp_model:), chilp_effects)
    }
    UserSearchTerm(term) -> {
      let model = Model(..model, route: ContentList(AnyFieldContains(term)))
      #(model, effect.none())
    }
  }
}

fn browse_to(url: String) {
  use dispatch <- effect.from
  case url |> string.starts_with("/") {
    // Local! Weird that it'd use this function but glad to catch!
    True -> {
      case rsvp.parse_relative_uri(url) {
        Ok(d) -> dispatch(UserNavigatedTo(d |> parse_route))
        _ -> ffi.browse(url)
      }
    }
    False -> {
      ffi.browse_prompt(url)
    }
  }
}

// PostListLoader

/// Returns the content list, except only the Posts
fn fetch_post_list(model: Model) {
  model.data.content
  |> dict.filter(fn(_, content_item) {
    case content_item {
      site_json.Post(..) -> True
      _ -> False
    }
  })
}

/// Fetches post list of all posts
pub fn postlist_all(model model: Model) {
  postlist_to_lustre(fetch_post_list(model), model)
}

/// Filter post list by tag
pub fn postlist_by_tag(model model: Model, tag card: String) {
  postlist_to_lustre(
    dict.filter(fetch_post_list(model), fn(_, content_item) {
      let assert site_json.Post(tags:, ..): site_json.Content = content_item
      tags |> list.contains(card)
    }),
    model,
  )
}

/// Filter post list by category
pub fn postlist_by_category(model model: Model, cat cat: String) {
  postlist_to_lustre(
    dict.filter(fetch_post_list(model), fn(_, content_item) {
      let assert site_json.Post(category:, ..): site_json.Content = content_item

      category == cat
    }),
    model,
  )
}

/// Search content list by search term
pub fn content_list_by_search_term(model model: Model, term search_term: String) {
  let term = search_term |> string.lowercase

  postlist_to_lustre(
    dict.filter(
      // Get all content, not just posts
      model.data.content,
      fn(_, content_item) {
        let title_contains =
          content_item.title
          |> string.lowercase
          |> string.contains(term)
        let description_contains =
          content_item.description
          |> string.lowercase
          |> string.contains(term)
        let content_contains =
          content_item.content
          |> string.lowercase
          |> string.contains(term)
        let category_contains = case content_item {
          site_json.Post(category:, ..) -> {
            category
            |> string.lowercase
            |> string.contains(term)
          }
          _ -> False
        }
        let tags_contain = case content_item {
          site_json.Post(tags:, ..) -> {
            tags
            |> string.join("/")
            |> string.lowercase
            |> string.contains(term)
          }
          _ -> False
        }
        // This last one is kind of a catch-all
        let metadata_contains =
          content_item
          |> site_json.content_to_json
          |> json.to_string
          |> string.contains(search_term)

        title_contains
        || description_contains
        || content_contains
        || category_contains
        || tags_contain
        || metadata_contains
      },
    ),
    model,
  )
}

fn postlist_to_lustre(
  posts: dict.Dict(String, site_json.Content),
  model: Model,
) -> element.Element(Msg) {
  let href = href(_, model)
  let ordered_posts =
    posts
    |> dict.to_list
    |> list.sort(
      fn(
        post_a: #(String, site_json.Content),
        post_b: #(String, site_json.Content),
      ) {
        let a_date = case post_a.1 {
          site_json.Post(date_updated:, ..) ->
            ffi.whatever_timestamp_to_unix_millis(date_updated)
          // For pages there is no date. Use 0 so they go to the end of the list
          _ -> 0
        }
        let b_date = case post_b.1 {
          site_json.Post(date_updated:, ..) ->
            ffi.whatever_timestamp_to_unix_millis(date_updated)
          _ -> 0
        }
        int.compare(b_date, a_date)
      },
    )

  let postlist =
    ordered_posts
    |> list.map(fn(item) {
      case item.1 {
        site_json.Post(date_published:, date_updated:, ..) -> {
          let post = item.1
          html.li([attribute.class("list-row p-10")], [
            html.a(
              [
                href(Content(slug: item.0)),
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
                  [element.unsafe_raw_html("", "span", [], post.description)],
                ),
              ],
            ),
          ])
        }
        site_json.Page(..) -> {
          let page = item.1
          let postlist = string.starts_with(item.0, "!")
          html.li([attribute.class("list-row p-10")], [
            html.a(
              [
                href(Content(slug: item.0)),
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
                [element.unsafe_raw_html("", "span", [], page.description)],
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

pub fn view(model: Model) -> #(String, Element(Msg)) {
  case model.route {
    Index -> view_content(model, "/")
    ContentList(a) -> view_postlist(model, a)
    Content(slug:) -> view_content(model, slug)
    NotFound(uri:) -> view_notfound(model, uri)
  }
}

fn view_notfound(model: Model, uri: Uri) -> #(String, Element(Msg)) {
  #(
    html.div([], [
      html.h1([], [element.text("This page could not be found")]),
      html.p([], [
        element.text(
          "The page at " <> uri |> uri.to_string() <> " could not be found.",
        ),
      ]),
    ]),
    site_json.Page(
      title: "404: Page not found",
      description: "Page could not be found",
      layout: None,
      content: "",
      in_menus: [],
      hide_meta_block: False,
    ),
    "/404",
  )
  |> view_into_layout(model:)
}

fn view_content(model: Model, slug: String) {
  case find_slug(model.data.content, slug) {
    Error(_) ->
      view_notfound(
        model,
        rsvp.parse_relative_uri(stringify_route(Content(slug), model))
          |> result.unwrap(uri.empty),
      )
    Ok(item) -> {
      #(item.content |> element.unsafe_raw_html("", "div", [], _), item, slug)
      |> view_into_layout(model)
    }
  }
}

fn view_postlist(model model: Model, filter filter: ContentFilter) {
  case filter {
    AnyFieldContains(term) -> {
      let slug = "/#!/search/" <> term
      #(
        content_list_by_search_term(model:, term:),
        site_json.Page(
          title: "Search results for: " <> term,
          description: "",
          layout: None,
          content: "",
          in_menus: [],
          hide_meta_block: True,
        ),
        slug,
      )
    }

    PostsByCategory(cat) -> {
      let slug = "/category/" <> cat
      #(
        postlist_by_category(model:, cat:),
        site_json.Page(
          title: "Category: " <> cat,
          description: "",
          layout: None,
          content: "",
          in_menus: [],
          hide_meta_block: True,
        ),
        slug,
      )
    }
    PostsByTag(tag) -> {
      let slug = "/tagged/" <> tag
      #(
        postlist_by_tag(model:, tag:),
        site_json.Page(
          title: "Tagged: " <> tag,
          description: "",
          layout: None,
          content: "",
          in_menus: [],
          hide_meta_block: True,
        ),
        slug,
      )
    }
    Posts -> {
      let slug = "/#!/"
      #(
        postlist_all(model:),
        site_json.Page(
          title: "Posts",
          description: "",
          layout: None,
          content: "",
          in_menus: [],
          hide_meta_block: True,
        ),
        slug,
      )
    }
  }
  |> view_into_layout(model)
}

/// Meant to be used for pregeneration. Allows a single-call override on the route in the model based on a slug string, and returns htmlstring.
pub fn slug_into_layout(slug: String, model: Model) {
  Model(..model, route: parse_route(uri.Uri(..uri.empty, path: slug)))
  |> view()
  |> pair.second
  |> element.to_string
}

fn view_into_layout(
  in: #(Element(Msg), site_json.Content, String),
  model model: Model,
) -> #(String, Element(Msg)) {
  let item = in.1
  let slug = in.2
  let in = in.0
  let global_theme = case ffi.get_color_scheme() {
    True -> model.data.config.global.theme
    False -> model.data.config.global.theme_dark
  }
  let is_post = case item {
    site_json.Post(..) -> True
    _ -> False
  }
  let item_theme =
    item.layout
    |> option.unwrap(global_theme)
  let s = "Unknown theme set: " <> item_theme
  let assert Ok(theme) =
    themes_generated.themes
    |> list.find(fn(i) { i.name == item_theme })
    as s

  let github_comment_color_scheme = case theme.prevalence {
    themes_generated.ThemeDark -> "github-dark"
    themes_generated.ThemeLight -> "github-light"
  }

  // layout_cindy-simple for example, which can then be used from element.element
  let component_name = "layout_" <> theme.layout
  let current = model.route
  let href = href(_, model)

  #(
    item.title,
    element.element(
      // This is where the layout is actually used.
      component_name,
      [
        attribute.attribute("title", item.title),
        attribute.attribute("description", item.description),
        attribute.attribute("data-theme", theme.daisy_ui_theme_name),
      ],
      [
        html.div([component.slot("menu1")], [
          model.menu_items
          |> list.key_filter(1)
          |> list.map(fn(item) {
            html.a(
              [
                attribute.class({
                  case current == item.1 {
                    True -> "menu-active menu-focused active font-medium"
                    False ->
                      "hover:bg-base-300/50 transition-colors duration-200"
                  }
                }),
                href(item.1),
              ],
              [html.text(item.0)],
            )
          })
          |> html.li([], _),
        ]),
        element.fragment([
          in,
          case is_post, model.data.config.posts.comments {
            False, _ | _, v4_1.CommentsDisabled -> element.none()
            True, v4_1.CommentsMastodonStored -> {
              let assert site_json.Post(mastodon_comments:, ..) = item
              case mastodon_comments {
                None -> {
                  element.none()
                }
                Some(mastodonstatus) -> {
                  chilp_base.new(
                    mastodonstatus.instance,
                    mastodonstatus.id,
                    model.chilp_model,
                  )
                  |> chilp_base.show(model.chilp_model)
                }
              }
            }
            True, v4_1.CommentsGithubStored(username:, repositoryname:) -> {
              html.script(
                [
                  attribute.attribute("async", ""),
                  attribute.attribute("crossorigin", "anonymous"),
                  attribute.attribute("theme", github_comment_color_scheme),
                  attribute.attribute("issue-term", slug),
                  attribute.attribute("repo", username <> "/" <> repositoryname),
                  attribute.src("https://utteranc.es/client.js"),
                ],
                "",
              )
            }
          },
        ]),
      ],
    ),
  )
}
