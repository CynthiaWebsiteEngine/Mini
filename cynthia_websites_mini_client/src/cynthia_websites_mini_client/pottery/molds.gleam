// Imports
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/pottery/oven
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Dynamic}
import lustre/element.{type Element}

// Imports from layout modules
import cynthia_websites_mini_client/pottery/molds/cindy_dual
import cynthia_websites_mini_client/pottery/molds/cindy_landing
import cynthia_websites_mini_client/pottery/molds/cindy_simple
import cynthia_websites_mini_client/pottery/molds/documentation
import cynthia_websites_mini_client/pottery/molds/frutiger
import cynthia_websites_mini_client/pottery/molds/github_layout
import cynthia_websites_mini_client/pottery/molds/minimalist
import cynthia_websites_mini_client/pottery/molds/oceanic_layout
import cynthia_websites_mini_client/pottery/molds/ownit
import cynthia_websites_mini_client/pottery/molds/pastels

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
  using model: model_type.Model,
) -> fn(Element(messages.Msg), Dict(String, decode.Dynamic)) ->
  element.Element(messages.Msg) {
  let #(v, is_post) = case theme_type {
    "post" -> #(True, True)
    "page" -> #(True, False)
    _ -> #(False, False)
  }
  // This handles the rare case where content is not a post and not a page, which should be never.
  use <- bool.guard(!v, fn(_, _) {
    oven.error(
      error_message: "Could not determine if this is a post or a page. (Got: '"
        <> theme_type
        <> "'.)",
      recoverable: True,
    )
  })
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
    "documentation" -> {
      // Documentation layout for both pages and posts
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          documentation.page_layout(content, metadata, model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          documentation.post_layout(content, metadata, model)
        }
      }
    }
    "pastels" -> {
      // Pastels layout handles both pages and posts with consistent styling
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) {
          pastels.page_layout(from: content, with: metadata, store: model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) {
          pastels.post_layout(from: content, with: metadata, store: model)
        }
      }
    }
    "frutiger" -> {
      case is_post {
        False -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          frutiger.page_layout(from: content, with: metadata, store: model)
        }
        True -> fn(
          content: Element(messages.Msg),
          metadata: Dict(String, Dynamic),
        ) -> Element(messages.Msg) {
          frutiger.post_layout(from: content, with: metadata, store: model)
        }
      }
    }
    "ownit" -> {
      // Ownit does not split between pages and posts, it is a single layout, split in the template.
      fn(content: Element(messages.Msg), metadata: Dict(String, Dynamic)) -> Element(
        messages.Msg,
      ) {
        ownit.main(
          from: content,
          with: metadata,
          store: model,
          is_post: is_post,
        )
      }
    }
    other -> {
      let f = "Unknown layout name: " <> other
      fn(_, _) -> Element(messages.Msg) { oven.error(f, True) }
    }
  }
}
