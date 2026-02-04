import chilp/widget/base as chilp_base
import cynthia_websites_mini_shared/config/site_json
import gleam/dict
import gleam/result
import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import plinth/browser/location
import plinth/browser/window

pub type Msg {
  UserNavigatedTo(route: Route)
  Chilp(chilp_base.ChilpMsg)
  UserSearchTerm(String)
}

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
