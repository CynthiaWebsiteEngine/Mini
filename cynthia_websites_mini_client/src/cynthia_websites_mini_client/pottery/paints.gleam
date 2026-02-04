import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/model_messages.{type Model}
import cynthia_websites_mini_client/ui/themes_generated
import gleam/list
import gleam/option
import gleam/result
import plinth/javascript/console

/// Fetches the corresponding theme and layout to the user's preferred colorscheme
pub fn get_sytheme(model: Model) {
  let theme = case dom.get_color_scheme() {
    "light" -> {
      model.complete_data
      |> option.map(fn(data) { data.global_theme })
      |> option.to_result(Nil)
      |> result.map_error(fn(_) {
        console.error("Error getting light color scheme from database")
      })
      |> result.unwrap(
        configtype.default_shared_cynthia_config_global_only.global_theme,
      )
    }
    "dark" -> {
      model.complete_data
      |> option.map(fn(data) { data.global_theme_dark })
      |> option.to_result(Nil)
      |> result.map_error(fn(_) {
        console.error("Error getting dark color scheme from database")
      })
      |> result.unwrap(
        configtype.default_shared_cynthia_config_global_only.global_theme,
      )
    }
    _ -> panic as "Invalid color scheme"
  }

  themes_generated.themes
  |> list.find(fn(th) { th.name == theme })
}
