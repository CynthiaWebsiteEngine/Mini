import cynthia_websites_mini_server/config as config_module
import cynthia_websites_mini_shared/configtype
import gleam/javascript/promise
import gleam/option.{type Option, None}
import javascript/mutable_reference

pub type MutableModel =
  mutable_reference.MutableReference(MutableModelContent)

pub fn new() -> promise.Promise(MutableModel) {
  use a <- promise.await(config_module.capture_config())
  mutable_reference.new(
    MutableModelContent(cached_response: None, config: { a }),
  )
  |> promise.resolve()
}

pub type MutableModelContent {
  MutableModelContent(
    cached_response: Option(String),
    config: configtype.SharedCynthiaConfigGlobalOnly,
  )
}
