import cynthia_websites_mini_client/configtype
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/option.{type Option}
import plinth/javascript/storage

pub type Model {
  Model(
    /// Where are we
    path: String,
    /// Complete data that makes up the site. This is all that the server serves up.
    complete_data: Option(configtype.CompleteData),
    /// Menu's stored readily  for themes to pick up.
    /// Structure:
    /// Dict(which_menu: Int, List(#(to, from)))
    computed_menus: Dict(Int, List(MenuItem)),
    /// Status
    /// Allows us to trigger the error page from the update function, without the need for more variants of Model.
    ///
    /// Normally this is `Ok(Nil)`
    /// On error this is `Error(error_message: String)`
    status: Result(Nil, String),
    /// Other variables
    /// This stores for example the current search term
    other: Dict(String, dynamic.Dynamic),
    /// Session storage
    sessionstore: storage.Storage,
    /// Ticks
    ticks: Int,
  )
}

pub type MenuItem {
  MenuItem(
    /// The name of the link
    name: String,
    /// The path to the link
    to: String,
  )
}

/// Configurable variable value type 'Time', can be decoded with `time_decoder` in this same module.
pub type Time {
  Time(hours: Int, minutes: Int, seconds: Int, milis: Int)
}

/// Decodes the configurable variable value type 'Time'
pub fn time_decoder() -> decode.Decoder(Time) {
  use hours <- decode.field("hours", decode.int)
  use minutes <- decode.field("minutes", decode.int)
  use seconds <- decode.field("seconds", decode.int)
  use milis <- decode.field("milis", decode.int)
  decode.success(Time(hours:, minutes:, seconds:, milis:))
}
