// Imports
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Dynamic}
import lustre/element.{type Element}

// Imports from layout modules
import cynthia_websites_mini_client/pottery/molds/cindy_dual
import cynthia_websites_mini_client/pottery/molds/cindy_landing
import cynthia_websites_mini_client/pottery/molds/cindy_simple
import cynthia_websites_mini_client/pottery/molds/github_layout
import cynthia_websites_mini_client/pottery/molds/minimalist
import cynthia_websites_mini_client/pottery/molds/oceanic_layout

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
  using model: model_type.Model,
) -> fn(Element(messages.Msg), Dict(String, decode.Dynamic)) ->
  element.Element(messages.Msg) {
  let is_post = case theme_type {
    "post" -> True
    "page" -> False
    _ -> panic as "Unknown content type"
  }
  case layout {
    // Add your layout handler here!
    "cindy" | "cindy-simple" -> {
      // Cindy shows a different layout for pages and posts.
      // If you want to do same kind of split, you can use the `is_post` variable in a case statement like below.
      //
      // For other types of splits, you can split within the function, where you have access to the content and metadata.
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_simple.page_layout(content, metadata, model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_simple.post_layout(content, metadata, model)
        }
      }
    }
    "cindy-dual" -> {
      // Cindy-dual also shows different layouts for pages and posts
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_dual.page_layout(content, metadata, model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_dual.post_layout(content, metadata, model)
        }
      }
    }
    "cindy-landing" -> {
      // Cindy-landing shows an optimized layout for landing pages
      // Post layout remains identical to cindy-simple
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_landing.page_layout(content, metadata, model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          cindy_simple.post_layout(content, metadata, model)
        }
      }
    }
    "minimalist" -> {
      // Minimalist layout for both pages and posts
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          minimalist.page_layout(from: content, with: metadata, store: model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          minimalist.post_layout(from: content, with: metadata, store: model)
        }
      }
    }
    "oceanic" -> {
      // Oceanic also shows different layouts for pages and posts
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          oceanic_layout.page_layout(content, metadata, model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          oceanic_layout.post_layout(content, metadata, model)
        }
      }
    }
    "github" -> {
      case is_post {
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) {
          github_layout.post_layout(from: content, with: metadata, store: model)
        }
        _ -> fn(content: Element(messages.Msg), metadata: Dict(String, Dynamic)) {
          github_layout.page_layout(from: content, with: metadata, store: model)
        }
      }
    }
    other -> {
      let f = "Unknown layout name: " <> other
      panic as f
    }
  }
}
