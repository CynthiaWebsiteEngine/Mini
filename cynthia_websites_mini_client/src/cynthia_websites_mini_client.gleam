import chilp/widget
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/ffi
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/option.{None}
import gleam/result
import gleam/string
import plinth/browser/location
import plinth/browser/window
import rsvp

pub const version = ffi.version

// IMPORTS ---------------------------------------------------------------------

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

// Modem is a package providing effects and functionality for routing in SPAs.
// This means instead of links taking you to a new page and reloading everything,
// they are intercepted and your `update` function gets told about the new URL.
import modem

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
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
    // Failure is okay, we just don't activate and hope the server served well enough pregenerations.
    _, _ -> Nil
  }

  promise.resolve(Ok(Nil))
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(
    data: site_json.SiteJSON,
    route: Route,
    chilp_model: widget.ChilpDataInYourModel(Msg),
  )
}

type PostFilter {
  ByCategory(String)
  ByTag(String)
  AnyFieldContains(String)
}

type Route {
  Index
  PostsList(PostFilter)
  Content(slug: String)
  NotFound(uri: Uri)
}

fn parse_route(uri: Uri) -> Route {
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

/// We also need a way to turn a Route back into a an `href` attribute that we
/// can then use on `html.a` elements. It is important to keep this function in
/// sync with the parsing, but once you do, all links are guaranteed to work!
///
fn href(route: Route, model: Model) -> Attribute(msg) {
  let url = case route {
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
  }
  attribute.href(url)
}

fn init(appdata: site_json.SiteJSON) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }
  let chilp_model = widget.init(Chilp)
  let effect =
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })
  let model = Model(appdata, route:, chilp_model:)
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
              option.Some(..) -> True
              _ -> False
            }
          }
          _ -> False
        }
      })
      |> list.map(fn(post) {
        let assert site_json.Post(mastodon_comments: option.Some(status), ..) =
          post
        let widget_ =
          widget.new(
            instance: status.instance,
            post_id: status.id,
            chilp_model:,
          )
        widget.force(chilp_model:, on: widget_)
      })
      |> list.shuffle
      |> list.append([effect], _)
      |> effect.batch
    }
  }

  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserNavigatedTo(route: Route)
  Chilp(widget.ChilpMsg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> {
      let model = Model(..model, route:)
      #(model, effect.none())
    }
    Chilp(chilp_msg) -> {
      let #(chilp_model, chilp_effects) =
        widget.update(chilp_msg, model.chilp_model, browse_to)
      #(Model(..model, chilp_model:), chilp_effects)
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

fn view(model: Model) -> Element(Msg) {
  let href = href(_, model)
  html.a([href(Index)], [element.text("house?")])
}
