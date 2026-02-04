import chilp/widget/base as chilp_base
import cynthia_websites_mini_client/model_messages.{Model}
import cynthia_websites_mini_client/ui/themes_generated
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/ffi
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import rsvp

pub const version = ffi.version

// Model -----------------------------------------------------------------------
type Model =
  model_messages.Model

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

fn init(appdata: site_json.SiteJSON) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> model_messages.parse_route(uri)
    Error(_) -> model_messages.Index
  }
  let chilp_model = chilp_base.init(model_messages.Chilp)
  let effect =
    modem.init(fn(uri) {
      uri
      |> model_messages.parse_route
      |> model_messages.UserNavigatedTo
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
type Msg =
  model_messages.Msg

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    model_messages.UserNavigatedTo(route:) -> {
      let model = Model(..model, route:)
      #(model, effect.none())
    }
    model_messages.Chilp(chilp_msg) -> {
      let #(chilp_model, chilp_effects) =
        chilp_base.update(chilp_msg, model.chilp_model, browse_to)
      #(Model(..model, chilp_model:), chilp_effects)
    }
    model_messages.UserSearchTerm(term) -> {
      let model =
        Model(
          ..model,
          route: model_messages.PostsList(model_messages.AnyFieldContains(term)),
        )
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
        Ok(d) ->
          dispatch(model_messages.UserNavigatedTo(
            d |> model_messages.parse_route,
          ))
        _ -> ffi.browse(url)
      }
    }
    False -> {
      ffi.browse_prompt(url)
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route {
    model_messages.Index -> view_content(model, "/")
    model_messages.PostsList(a) -> view_postlist(model, a)
    model_messages.Content(slug:) -> view_content(model, slug)
    model_messages.NotFound(uri:) -> view_notfound(uri)
  }
}

fn view_notfound(uri: Uri) -> Element(Msg) {
  todo
}

fn view_content(model: Model, slug: String) {
  todo
}

fn view_postlist(model: Model, filter: model_messages.PostFilter) {
  todo
}

fn view_into_layout(
  in: Element(Msg),
  model: Model,
  slug: String,
) -> fn(site_json.Content, Element(Msg), Model) -> Element(Msg) {
  let global_theme = case ffi.get_color_scheme() {
    True -> model.data.config.global.theme
    False -> model.data.config.global.theme_dark
  }
  let item =
    result.unwrap(
      dict.get(model.data.content, slug),
      site_json.Page(
        title: "",
        description: "",
        layout: None,
        content: "",
        in_menus: [],
        hide_meta_block: False,
      ),
    )
  let item_theme =
    item.layout
    |> option.unwrap(global_theme)
  let assert Ok(theme) =
    themes_generated.themes
    |> list.find(fn(i) { i.name == item_theme })
    as "Unknown theme set."

  let component_name = "layout_" <> theme.layout
  // layout_cindy-simple for example, which can then be used from element.element
  todo
}
//           let comment_color_scheme = case dom.get_color_scheme() {
//             "dark" -> "github-dark"
//             _ -> "github-light"
//           }

//           list.append(default, [
//             html.script(
//               [
//                 attribute("async", ""),
//                 attribute("crossorigin", "anonymous"),
//                 attribute("theme", comment_color_scheme),
//                 attribute("issue-term", content.permalink),
//                 attribute("repo", repo),
//                 attribute(
//                   "return-url",
//                    model.path,
//                 ),
//                 attribute.src("https://utteranc.es/client.js"),
//               ],
//               "
// ",
//             ),
