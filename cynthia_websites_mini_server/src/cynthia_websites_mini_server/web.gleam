import bungibindies/bun
import bungibindies/bun/bunfile.{type BunFile}
import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/shared/jsonld
import cynthia_websites_mini_client/shared/sitemap
import cynthia_websites_mini_server/config
import cynthia_websites_mini_server/mutable_model_type
import cynthia_websites_mini_server/ssrs
import gleam/dict
import gleam/javascript/array
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import gleamy_lights/console
import gleamy_lights/premixed
import javascript/mutable_reference
import plinth/node/process
import simplifile

pub fn handle_request(
  req: Request,
  mutable_model: mutable_model_type.MutableModel,
) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
    as "Request URI should be valid"
  let path = req_uri.path

  // Ensure JSONs are generated if needed
  use _ <- promise.await(
    case mutable_reference.get(mutable_model).cached_jsonld {
      Some(_) -> promise.resolve(Nil)
      // Cache hit, no need to generate
      None -> generate_jsons(mutable_model) |> promise.map(fn(_) { Nil })
    },
  )

  let assert Some(dynastatic) = ssrs.ssrs(mutable_model)
    as "These routes should always be valid."
  case path {
    "/" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> "(GET)\t"
        <> premixed.text_lightblue("/")
        <> " "
        <> premixed.text_cyan(
          "\t(this means client-side will now start loading a web page)",
        ),
      )
      dynastatic
      |> dict.get("/index.html")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
    "/site.json" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> "(GET)\t"
        <> premixed.text_lightblue("/site.json")
        <> " "
        <> premixed.text_cyan(
          "\t(this means client-side will now start loading content!)",
        ),
      )
      let model = mutable_reference.get(mutable_model)
      let re = case model.cached_response {
        Some(res_string) -> {
          // Cache hit! Return the cached response string so that it can be used in the response body
          res_string |> promise.resolve
        }
        None -> {
          // If there is no cached response, load the complete data from the config file
          // and encode it as JSON
          use res <- promise.map(generate_jsons(mutable_model))
          let res_string: String = res.0

          // Now return the response string promise so that it can be used in the response body
          res_string
        }
      }
      use body <- promise.await(re)
      response.set_body(response.new(), body)
      |> response.set_headers(
        [#("Content-Type", "application/json; charset=utf-8")]
        |> array.from_list(),
      )
      |> response.set_status(200)
      |> promise.resolve
    }
    "/sitemap.xml" -> {
      let model = mutable_reference.get(mutable_model)
      case model.cached_sitemap {
        Some(sitemap_xml) -> {
          console.log(
            premixed.text_ok_green("[ 200 ]\t")
            <> "(GET)\t"
            <> premixed.text_lightblue("/sitemap.xml"),
          )
          response.set_body(response.new(), sitemap_xml)
          |> response.set_headers(
            [#("Content-Type", "application/xml; charset=utf-8")]
            |> array.from_list(),
          )
          |> response.set_status(200)
          |> promise.resolve()
        }
        None -> {
          use _ <- promise.await(generate_jsons(mutable_model))
          let model = mutable_reference.get(mutable_model)

          case model.cached_sitemap {
            Some(sitemap_xml) -> {
              console.log(
                premixed.text_ok_green("[ 200 ]\t")
                <> "(GET)\t"
                <> premixed.text_lightblue("/sitemap.xml"),
              )
              response.set_body(response.new(), sitemap_xml)
              |> response.set_headers(
                [#("Content-Type", "application/xml; charset=utf-8")]
                |> array.from_list(),
              )
              |> response.set_status(200)
              |> promise.resolve()
            }
            None -> {
              console.error(
                premixed.text_error_red("[ 404 ] ")
                <> "(GET)\t"
                <> premixed.text_lightblue("/sitemap.xml"),
              )
              dynastatic
              |> dict.get("/404")
              |> result.unwrap(response.new())
              |> promise.resolve()
            }
          }
        }
      }
    }
    "/assets/" <> f -> {
      let filepath = process.cwd() <> "/assets/" <> f
      case simplifile.is_file(filepath) {
        Ok(True) -> {
          console.log(
            premixed.text_ok_green("[ 200 ]\t")
            <> "(GET)\t"
            <> premixed.text_lightblue("/assets/")
            <> premixed.text_cyan(f),
          )
          filepath
          |> bun.file()
          |> answer_bunrequest_with_file()
        }
        _ -> {
          console.error(
            premixed.text_error_red("[ 404 ] ")
            <> "(GET)\t"
            <> premixed.text_lightblue("/assets/")
            <> premixed.text_cyan(f),
          )
          dynastatic
          |> dict.get("/404")
          |> result.unwrap(response.new())
          |> promise.resolve()
        }
      }
    }
    f -> {
      console.error(
        premixed.text_error_red("[ 404 ] ")
        <> "("
        <> req |> request.method
        <> ")\t"
        <> premixed.text_lightblue(f),
      )
      dynastatic
      |> dict.get("/404")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
  }
}

@external(javascript, "./request_ffi.ts", "get_request_body")
pub fn get_request_body(req: Request) -> Promise(BitArray)

@external(javascript, "./request_ffi.ts", "get_request_body_as_text")
pub fn get_request_body_as_text(req: Request) -> Promise(String)

@external(javascript, "./request_ffi.ts", "answer_bunrequest_with_file")
pub fn answer_bunrequest_with_file(file: BunFile) -> Promise(response.Response)

fn generate_jsons(
  mutable_model: mutable_model_type.MutableModel,
) -> Promise(#(String, String, String)) {
  use complete_data <- promise.await(config.load())
  let complete_data_json =
    complete_data |> configtype.encode_complete_data_for_client
  let res_string = complete_data_json |> json.to_string
  let res_jsonld = jsonld.generate_jsonld(complete_data)
  let opt_sitemap = sitemap.generate_sitemap(complete_data)
  // Add all representations to the model cache
  mutable_reference.update(mutable_model, fn(model) {
    mutable_model_type.MutableModelContent(
      ..model,
      cached_response: Some({ res_string }),
      cached_jsonld: Some({ res_jsonld }),
      cached_sitemap: opt_sitemap,
    )
  })
  #(res_string, res_jsonld, option.unwrap(opt_sitemap, "")) |> promise.resolve
}
