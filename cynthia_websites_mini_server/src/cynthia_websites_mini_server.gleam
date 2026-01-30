import bungibindies
import bungibindies/bun
import cynthia_websites_mini_client
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/ffi
import gleam/bool
import gleam/javascript/array
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
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
  let args = process.argv() |> array.to_list() |> list.drop(2)
  case args {
    ["pregenerate", ..] | ["static"] -> start()
    ["init", ..] | ["initialise", ..] -> {
      init(args |> list.includes("--force"))
    }
    _ -> {
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
        // Run:
        <> string.concat([
          premixed.text_pink("\trun"),
          " | ",
          premixed.text_pink("pregenerate\n"),
        ])
        <> "\t\t\t\tGenerate a static website\n\n"
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
    }
    [a, ..] ->
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
  }
}

fn get_context() -> site_json.SiteJSON {
  let config = case
    {
      let global_conf_filepath =
        files.path_join([process.cwd(), "/cynthia.toml"])
      let global_conf_filepath_exists = files.file_exist(global_conf_filepath)

      case global_conf_filepath_exists {
        True -> {
          Nil
        }
        // No config was found. Let's look for legacy config or initialise.
        False -> {
          let global_conf_filepath_legacy =
            files.path_join([process.cwd(), "/cynthia-mini.toml"])
          let global_conf_filepath_legacy_exists =
            files.file_exist(global_conf_filepath_legacy)
          case
            global_conf_filepath_legacy_exists,
            simplifile.read(global_conf_filepath_legacy)
          {
            True, Ok(legacy_config) -> {
              console.warn(
                "A legacy config file was found! Cynthia Mini will attempt to auto-convert it on the go and continue.",
              )
              let upgraded_config =
                "# This file was upgraded to the universal Cynthia Config format\n# Do not edit these two variables! They are set by Cynthia to tell it's config format apart.\nconfig.edition=\"mini\"\nconfig.version=4.0\n\n"
                <> legacy_config
              case
                simplifile.write(
                  to: global_conf_filepath,
                  contents: upgraded_config,
                )
              {
                Ok(_) -> {
                  let _ =
                    simplifile.rename(
                      at: global_conf_filepath_legacy,
                      to: global_conf_filepath_legacy <> ".old",
                    )
                  Nil
                }
                Error(_) -> {
                  console.error(
                    "Error: Could not write upgraded config to "
                    <> global_conf_filepath
                    <> ". Please check file permissions.",
                  )
                  process.exit(1)
                }
              }
            }
            True, Error(_) -> {
              console.error(
                "Some error happened while trying to read "
                <> global_conf_filepath_legacy
                <> ".",
              )
              process.exit(1)
            }
            // No config found, and no old config found.
            False, _ -> {
              init()
              get_context()
            }
          }
        }
      }
      let e = "Could not read " <> global_conf_filepath
      let assert Ok(toml) = simplifile.read(global_conf_filepath) as e
      // Call the latest decoder for it and return. If it encounters an older config format it should be able to recognise and convert by itself.
      decodes.vp4p1mini_toml(toml)
    }
  {
    Ok(conf) -> conf
    Error(_) -> {
      process.exit(1)
      panic as "Shouldn't be here."
    }
  }
  let content = {
    todo
  }

  site_json.SiteJSON(config, content)
}

import cynthia_websites_mini_shared/config/v4_1/decodes

pub fn create_html(json: site_json.SiteJSON, path: String) {
  "<!DOCTYPE html>
<html lang='en'>
<!--
  This site is generated by Cynthia Mini " <> cynthia_websites_mini_client.version() <> ", a mostly-static site generator written in Gleam.

  Also see: <https://github.com/CynthiaWebsiteEngine/Mini>
-->

<head>
<title>&lt;&lt;site hosted by Cynthia mini&gt;&gt;</title>
<meta property='og:site_name' content=" <> json.config.global.site_name
  |> ffi.jsonify_string()
  |> result.unwrap("Site name is invalid") <> "/>
<meta property='og:description' content=" <> json.config.global.description
  |> dom.jsonify_string()
  |> result.unwrap("Site description is invalid") <> "/>
" <> case model.cached_jsonld {
    Some(jsonld) ->
      "<script type=\"application/ld+json\">\n" <> jsonld <> "\n</script>"
    None -> " <!--\n\nNo JSON-LD structured data available for this site\n\n-->"
  } <> "
<link rel='shortcut icon' href='./assets/site_icon.png' type='image/x-icon'/>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<script type='module' src='/cynthia_client.mjs'></script>
<style>" <> client_css() <> "</style>
</head>
<body class='h-full w-full'>
  <div id='viewable' class='bg-base-100 w-full h-full min-h-screen will-change-transform'>
  " <> first_view <> "
  </div>
 " <> footer(True, json.config.integrations.git) <> "
</body>
</html>
"
}

fn init(forced: Bool) {
  todo
}
