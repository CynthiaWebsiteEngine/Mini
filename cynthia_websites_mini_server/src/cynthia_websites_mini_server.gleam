import bungibindies
import bungibindies/bun
import bungibindies/bun/http/serve.{ServeOptions}
import cynthia_websites_mini_client
import cynthia_websites_mini_client/configtype
import cynthia_websites_mini_client/shared/jsonld
import cynthia_websites_mini_client/shared/sitemap
import cynthia_websites_mini_server/config
import cynthia_websites_mini_server/mutable_model_type
import cynthia_websites_mini_server/ssrs
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/web
import gleam/bool
import gleam/int
import gleam/javascript/array
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import javascript/mutable_reference
import plinth/javascript/global
import plinth/node/process
import simplifile

pub fn main() {
  // Check if we are running in Bun
  case bungibindies.runs_in_bun() {
    Ok(_) -> Nil
    Error(_) -> {
      console.log(premixed.text_red(
        "Error: Cynthia Mini needs to run in Bun! Try installing and running it with Bun instead.",
      ))
      process.exit(1)
    }
  }
  case
    bool.or(
      { process.argv() |> array.to_list() |> list.contains("--version") },
      { process.argv() |> array.to_list() |> list.contains("-v") },
    )
  {
    True -> {
      console.log(cynthia_websites_mini_client.version())
      process.exit(0)
    }
    False -> Nil
  }

  console.log(
    premixed.text_green("Hello from Cynthia Mini! ")
    <> "Running in "
    <> premixed.text_bright_orange(process.cwd())
    <> "!",
  )
  use m <- promise.await(mutable_model_type.new())
  case process.argv() |> array.to_list() |> list.drop(2) {
    ["dynamic", ..] | ["host", ..] ->
      dynamic_site_server(m, 60_000) |> promise.resolve
    ["preview", ..] -> dynamic_site_server(m, 20) |> promise.resolve
    ["pregenerate", ..] | ["static"] -> static_site_server(m)
    ["init", ..] | ["initialise", ..] -> {
      config.initcfg()
      |> promise.resolve
    }
    ["man", ..] | ["help", ..] | ["--help", ..] | ["-h", ..] | [] -> {
      case process.argv() |> array.to_list() |> list.drop(2) {
        [] -> console.error("No subcommand given.\n")
        _ -> Nil
      }
      console.log(
        "\nCynthia Website Engine Mini - Creating websites from simple files\n\n"
        <> "Usage:\n"
        <> premixed.text_bright_cyan("\tcynthiaweb-mini")
        <> " "
        <> premixed.text_bright_orange("[command]")
        <> " \n"
        <> "Commands:\n"
        // Init:
        <> string.concat([
          premixed.text_pink("\tinit"),
          " | ",
          premixed.text_pink("initialise\n"),
        ])
        <> "\t\t\t\tInitialise the config file then exit\n\n"
        // Dynamic:
        <> string.concat([
          premixed.text_pink("\tdynamic"),
          " | ",
          premixed.text_pink("host\n"),
        ])
        <> "\t\t\t\tStart a dynamic website server\n\n"
        // Pregenerate:
        <> string.concat([
          premixed.text_pink("\tstatic"),
          " | ",
          premixed.text_pink("pregenerate\n"),
        ])
        <> "\t\t\t\tGenerate a static website\n\n"
        // Preview:
        <> premixed.text_pink("\tpreview\n")
        <> "\t\t\t\tStart a dynamic website server for previewing\n"
        <> "\t\t\t\tthis is the same as dynamic, but with a shorter\n"
        <> "\t\t\t\tinterval for the cache\n\n"
        // Help:
        <> premixed.text_lilac("\thelp")
        <> "\n"
        <> "\t\t\t\tShow this help message\n\n"
        <> "For more information, visit: "
        <> premixed.text_blue(
          "https://cynthiawebsiteengine.github.io/Mini-docs",
        )
        <> ".\n",
      )
      |> promise.resolve
    }
    [a, ..] | [a] ->
      console.error(
        premixed.text_error_red("Unknown subcommand: ")
        <> "´"
        <> premixed.text_bright_orange(a)
        <> "´. Please try with ´"
        <> premixed.text_green("dynamic")
        <> "´ or ´"
        <> premixed.text_green("static")
        <> "´ instead. Or use ´"
        <> premixed.text_purple("help")
        <> "´ to see a list of all subcommands.\n",
      )
      |> promise.resolve
  }
}

fn dynamic_site_server(mutmodel: mutable_model_type.MutableModel, lease: Int) {
  console.info("Cynthia Mini is in dynamic site mode!")
  let model = mutmodel |> mutable_reference.get
  let conf = model.config
  {
    let folder = process.cwd() <> "/assets/cynthia-mini"
    case simplifile.create_directory_all(folder) {
      Ok(..) -> Nil
      Error(e) -> {
        console.error(
          "A problem occurred while creating the ´"
          <> folder
          <> "´ directory: "
          <> premixed.text_error_red(string.inspect(e)),
        )
        process.exit(1)
        panic as "We should not reach here"
      }
    }

    case files.file_exist(process.cwd() <> "/assets/cynthia-mini/README.md") {
      True -> Nil
      False -> {
        case
          simplifile.write(
            process.cwd() <> "/assets/cynthia-mini/README.md",
            "# What does this folder do?\n\r\n\rThis folder holds a few files Cynthia Mini serves to the browser to make sure everything works alright.\n\r\n\rThese are usually checked and downloaded if necessary only during start of the server,\n\rso try not to touch them! If you believe one of the files in here might be faulty, delete it, and restart the server.\n\r\n\rHave a nice day! :)",
          )
        {
          Ok(..) -> Nil
          Error(e) -> {
            console.error(
              "A problem occurred while creating the ´"
              <> process.cwd()
              <> "/assets/cynthia-mini/README.md"
              <> "´ file: "
              <> premixed.text_error_red(string.inspect(e)),
            )
            process.exit(1)
            panic as "We should not reach here"
          }
        }
        Nil
      }
    }
  }
  console.log("Starting server...")
  case
    bun.serve(ServeOptions(
      development: Some(True),
      hostname: conf.server_host,
      port: conf.server_port,
      static_served: ssrs.ssrs(mutmodel),
      handler: web.handle_request(_, mutmodel),
      id: None,
      reuse_port: None,
    ))
  {
    Ok(..) -> {
      console.log(
        "Server started! Running on: "
        <> premixed.text_cyan(
          "http://"
          <> option.unwrap(conf.server_host, "localhost")
          <> ":"
          <> int.to_string(option.unwrap(conf.server_port, 8080))
          <> "/",
        ),
      )
      global.set_interval(lease, fn() {
        mutable_reference.update(mutmodel, fn(model) {
          case model.cached_response {
            None -> model
            Some(..) ->
              // Drops the cached response to keep it updated
              mutable_model_type.MutableModelContent(
                ..model,
                cached_response: None,
              )
          }
        })
      })
    }
    Error(e) -> {
      console.error(
        "A problem occurred while starting the server: "
        <> premixed.text_error_red(string.inspect(e)),
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }

  Nil
}

fn static_site_server(mutmodel: mutable_model_type.MutableModel) {
  console.info("Cynthia Mini is in pregeneration mode!")

  {
    let folder = process.cwd() <> "/assets/cynthia-mini"
    case simplifile.create_directory_all(folder) {
      Ok(..) -> Nil
      Error(e) -> {
        console.error(
          "A problem occurred while creating the ´"
          <> folder
          <> "´ directory: "
          <> premixed.text_error_red(string.inspect(e)),
        )
        process.exit(1)
        panic as "We should not reach here"
      }
    }

    case files.file_exist(process.cwd() <> "/assets/cynthia-mini/README.md") {
      True -> Nil
      False -> {
        case
          simplifile.write(
            process.cwd() <> "/assets/cynthia-mini/README.md",
            "# What does this folder do?\n\r\n\rThis folder holds a few files Cynthia Mini serves to the browser to make sure everything works alright.\n\r\n\rThese are usually checked and downloaded if necessary only during start of the server,\n\rso try not to touch them! If you believe one of the files in here might be faulty, delete it, and restart the server.\n\r\n\rHave a nice day! :)",
          )
        {
          Ok(..) -> Nil
          Error(e) -> {
            console.error(
              "A problem occurred while creating the ´"
              <> process.cwd()
              <> "/assets/cynthia-mini/README.md"
              <> "´ file: "
              <> premixed.text_error_red(string.inspect(e)),
            )
            process.exit(1)
            panic as "We should not reach here"
          }
        }
        Nil
      }
    }
  }

  use complete_data <- promise.await(config.load())

  // Generate JSON representations
  let complete_data_json =
    complete_data |> configtype.encode_complete_data_for_client
  let res_string = complete_data_json |> json.to_string
  let res_jsonld = jsonld.generate_jsonld(complete_data)
  let opt_sitemap = sitemap.generate_sitemap(complete_data)

  // Update the model with all representations
  mutable_reference.update(mutmodel, fn(model) {
    mutable_model_type.MutableModelContent(
      ..model,
      cached_response: Some({ res_string }),
      cached_jsonld: Some({ res_jsonld }),
      cached_sitemap: opt_sitemap,
    )
  })

  let outdir = process.cwd() <> "/out"
  case simplifile.create_directory_all(outdir) {
    Ok(..) -> Nil
    Error(e) -> {
      console.error(
        "A problem occurred while creating the ´out´ directory: "
        <> premixed.text_error_red(string.inspect(e)),
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case simplifile.write(to: outdir <> "/site.json", contents: res_string) {
    Ok(..) -> Nil
    Error(e) -> {
      console.error(
        "A problem occurred while creating the ´site.json´ file: "
        <> premixed.text_error_red(string.inspect(e)),
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case
    simplifile.write(
      to: outdir <> "/index.html",
      contents: ssrs.index_html(mutable_reference.get(mutmodel)),
    )
  {
    Ok(..) -> Nil
    Error(e) -> {
      console.error(
        "A problem occurred while creating the ´index.html´ file: "
        <> premixed.text_error_red(string.inspect(e)),
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case
    simplifile.copy_directory(
      at: process.cwd() <> "/assets/",
      to: outdir <> "/assets/",
    )
  {
    Ok(..) -> Nil
    Error(e) -> {
      console.error(
        "A problem occurred while copying the assets directory: "
        <> premixed.text_error_red(string.inspect(e)),
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case simplifile.is_file(outdir <> "/site.json") {
    Ok(True) -> Nil
    _ -> {
      console.error(
        "An unknown problem occurred while creating the ´site.json´ file.",
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case simplifile.is_file(outdir <> "/index.html") {
    Ok(True) -> Nil
    _ -> {
      console.error(
        "An unknown problem occurred while creating the ´index.html´ file.",
      )
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  case opt_sitemap {
    None -> Nil
    Some(res_sitemap) -> {
      case
        simplifile.write(to: outdir <> "/sitemap.xml", contents: res_sitemap)
      {
        Ok(..) -> Nil
        Error(e) -> {
          console.error(
            "A problem occurred while creating the ´sitemap.xml´ file: "
            <> premixed.text_error_red(string.inspect(e)),
          )
          process.exit(1)
          panic as "We should not reach here"
        }
      }
    }
  }

  console.info(
    premixed.text_ok_green("Site pregeneration complete!")
    <> " Serve files from "
    <> premixed.text_orange(outdir <> "/")
    <> " and you should have a site running!",
  )
  promise.resolve(Nil)
}
