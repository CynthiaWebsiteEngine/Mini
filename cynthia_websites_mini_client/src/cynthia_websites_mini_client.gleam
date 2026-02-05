import chilp/widget/base as chilp_base
import cynthia_websites_mini_client/ui/themes_generated
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/ffi
import gleam/dict
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/list
import gleam/option.{None, Some}
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
import plinth/browser/location
import plinth/browser/window
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

pub type PostFilter {
  ByCategory(String)
  ByTag(String)
  AnyFieldContains(String)
  All
}

pub type Route {
  Index
  PostsList(PostFilter)
  Content(slug: String)
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> {
      case location.hash(window.location(window.self())) {
        Error(_) -> Index

        Ok("#!/category/" <> cat) -> PostsList(ByCategory(cat))
        Ok("#!/tag/" <> tag) -> PostsList(ByTag(tag))
        Ok("#!/search/" <> tag) -> PostsList(AnyFieldContains(tag))

        Ok(c) -> {
          let d = "Unhandled hashroute: " <> c
          panic as d
        }
      }
    }
    ["tagged", tag] -> PostsList(ByCategory(tag))
    ["category", cat] -> PostsList(ByTag(cat))
    ["post", slug] | ["page", slug] | ["content", slug] -> Content(slug:)

    _ -> NotFound(uri:)
  }
}

pub fn stringify_route(route: Route, model: Model) {
  case route {
    Index -> "/"
    Content(c) -> {
      dict.get(model.data.content, c)
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
    PostsList(ByCategory(cat)) -> "/category/" <> cat
    PostsList(ByTag(tag)) -> "/tagged/" <> tag
    PostsList(AnyFieldContains(q)) -> "/#!/search/" <> q
    PostsList(All) -> "/#!/"
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
      let assert Ok(_) = ffi.push_title(title)
      elements
    })
  let assert Ok(sitejsonuri) = rsvp.parse_relative_uri("/site.json")
  let assert Ok(req) = request.to(sitejsonuri |> uri.to_string())
  use resp <- promise.try_await(fetch.send(req))
  use resp <- promise.try_await(fetch.read_json_body(resp))
  let result = decode.run(resp.body, site_json.site_json_decoder())
  case resp.status, result {
    200, Ok(sitejson) -> {
      let assert Ok(_) = lustre.start(app, "#viewable", sitejson)
      Nil
    }
    // Failure here is okay, we just don't activate and hope the server served well enough pregenerations.
    _, _ -> Nil
  }

  promise.resolve(Ok(Nil))
}

fn init(appdata: site_json.SiteJSON) -> #(Model, Effect(Msg)) {
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
    |> dict.values
    |> list.shuffle
    |> list.filter(keeping: fn(c) {
      case c {
        site_json.Page(in_menus:, ..) -> {
          !{ in_menus |> list.is_empty }
        }
        site_json.Post(..) -> False
      }
    })
    |> list.map(fn(page) {
      let assert site_json.Page(title:, in_menus:, ..) = page
      list.map(in_menus, fn(menuid) { #(menuid, #(title, route)) })
    })
    |> list.flatten
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
      let model = Model(..model, route: PostsList(AnyFieldContains(term)))
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

fn view(model: Model) -> #(String, Element(Msg)) {
  case model.route {
    Index -> view_content(model, "/")
    PostsList(a) -> view_postlist(model, a)
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
  case dict.get(model.data.content, slug) {
    Error(_) ->
      view_notfound(
        model,
        rsvp.parse_relative_uri(stringify_route(Content(slug), model))
          |> result.unwrap(uri.empty),
      )
    Ok(_) -> todo
  }
}

fn view_postlist(model: Model, filter: PostFilter) {
  todo
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
  let assert Ok(theme) =
    themes_generated.themes
    |> list.find(fn(i) { i.name == item_theme })
    as "Unknown theme set."

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
