import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_server/config as config_module
import gleam/javascript/promise
import gleam/option.{type Option, None}
import javascript/mutable_reference

pub type MutableModel =
  mutable_reference.MutableReference(MutableModelContent)

pub fn new() -> promise.Promise(MutableModel) {
  use cfg <- promise.await(config_module.capture_config())
  mutable_reference.new(MutableModelContent(
    cached_response: None,
    cached_jsonld: None,
    cached_sitemap: None,
    config: cfg,
  ))
  |> promise.resolve()
}

pub type MutableModelContent {
  MutableModelContent(
    cached_response: Option(String),
    cached_jsonld: Option(String),
    cached_sitemap: Option(String),
    config: configtype.SharedCynthiaConfigGlobalOnly,
  )
}
