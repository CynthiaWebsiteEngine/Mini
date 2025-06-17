import bungibindies/bun
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/utils/prompts
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/configurable_variables
import cynthia_websites_mini_shared/contenttypes
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/fetch
import gleam/float
import gleam/http/request
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
import plinth/node/fs
import plinth/node/process
import simplifile
import tom

/// # Config.load()
/// Loads the configuration from the `cynthia-mini.toml` file and the content from the `content` directory.
/// Then saves the configuration to the database.
pub fn load() -> Promise(configtype.CompleteData) {
  use global_config <- promise.await(capture_config())
  use content_list <- promise.await(content_getter())
  let content = case content_list {
    Ok(lis) -> lis
    Error(msg) -> {
      console.error("Error: There was an error getting content:\n" <> msg)
      process.exit(1)
      panic as "We should not reach here"
    }
  }

  let complete_data = configtype.merge(global_config, content)
  complete_data
  |> promise.resolve
}

pub fn capture_config() {
  let global_conf_filepath =
    files.path_join([process.cwd(), "/cynthia-mini.toml"])
  let global_conf_filepath_exists = files.file_exist(global_conf_filepath)
  case global_conf_filepath_exists {
    True -> Nil
    False -> {
      dialog_initcfg()
      Nil
    }
  }
  use parse_configtoml_result <- promise.await(parse_configtoml())
  let global_config = case parse_configtoml_result {
    Ok(config) -> config
    Error(why) -> {
      premixed.text_error_red(
        "Error: Could not load cynthia-mini.toml: " <> why,
      )
      |> console.error
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  global_config
  |> promise.resolve()
}

fn parse_configtoml() {
  use str <- promise.try_await(
    fs.read_file_sync(files.path_normalize(
      process.cwd() <> "/cynthia-mini.toml",
    ))
    |> result.map_error(fn(e) {
      premixed.text_error_red("Error: Could not read cynthia-mini.toml: " <> e)
      process.exit(1)
    })
    |> result.map_error(string.inspect)
    |> promise.resolve(),
  )
  use res <- promise.try_await(
    tom.parse(str) |> result.map_error(string.inspect) |> promise.resolve(),
  )

  use config <- promise.try_await(
    cynthia_config_global_only_exploiter(res)
    |> promise.map(result.map_error(_, string.inspect)),
  )
  promise.resolve(Ok(config))
}

type ConfigTomlDecodeError {
  TomlGetStringError(tom.GetError)
  TomlGetIntError(tom.GetError)
  FieldError(String)
}

fn cynthia_config_global_only_exploiter(
  o: dict.Dict(String, tom.Toml),
) -> Promise(
  Result(configtype.SharedCynthiaConfigGlobalOnly, ConfigTomlDecodeError),
) {
  use global_theme <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "theme"])
        |> result.replace_error(FieldError(
          "config->global.theme does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_theme_dark <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "theme_dark"])
        |> result.replace_error(FieldError(
          "config->global.theme_dark does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_colour <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "colour"])
        |> result.replace_error(FieldError(
          "config->global.colour does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_site_name <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "site_name"])
        |> result.replace_error(FieldError(
          "config->global.site_name does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  use global_site_description <- promise.try_await(
    {
      use field <- result.try(
        tom.get(o, ["global", "site_description"])
        |> result.replace_error(FieldError(
          "config->global.site_description does not exist",
        )),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    }
    |> promise.resolve(),
  )
  let server_port =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "port"])
        |> result.replace_error(FieldError("config->server.port does not exist")),
      )
      tom.as_int(field)
      |> result.map_error(TomlGetIntError)
    })
  let server_host =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "host"])
        |> result.replace_error(FieldError("config->server.host does not exist")),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    })
  let comment_repo = case
    tom.get(o, ["posts", "comment_repo"]) |> result.map(tom.as_string)
  {
    Ok(Ok(field)) -> {
      option.Some(field)
    }
    _ -> option.None
  }
  let git_integration = case
    tom.get(o, ["integrations", "git"]) |> result.map(tom.as_bool)
  {
    Ok(Ok(field)) -> {
      field
    }
    _ -> True
  }
  let other_vars = case result.map(tom.get(o, ["variables"]), tom.as_table) {
    Ok(Ok(d)) ->
      {
        dict.map_values(d, fn(key, unasserted_value) {
          let somewhat_asserted_value = case unasserted_value {
            tom.InlineTable(inline) -> {
              case inline |> dict.to_list() {
                [#("url", tom.String(url))] -> {
                  let start = bun.nanoseconds()
                  console.log(
                    "Downloading external data ´"
                    <> premixed.text_blue(url)
                    <> "´...",
                  )

                  let assert Ok(req) = request.to(url)
                  use resp <- promise.await(
                    promise.map(fetch.send(req), fn(e) {
                      case e {
                        Ok(v) -> v
                        Error(_) -> {
                          console.error(
                            "There was an error while trying to download '"
                            <> url |> premixed.text_bright_yellow()
                            <> "' to a variable.",
                          )
                          process.exit(1)
                          panic as "We should not reach here."
                        }
                      }
                    }),
                  )
                  use resp <- promise.await(
                    promise.map(fetch.read_bytes_body(resp), fn(e) {
                      case e {
                        Ok(v) -> v
                        Error(_) -> {
                          console.error(
                            "There was an error while trying to download '"
                            <> url |> premixed.text_bright_yellow()
                            <> "' to a variable.",
                          )
                          process.exit(1)
                          panic as "We should not reach here."
                        }
                      }
                    }),
                  )
                  let end = bun.nanoseconds()
                  let duration_ms = { end -. start } /. 1_000_000.0
                  case resp.status {
                    200 -> {
                      console.log(
                        "Downloaded external content ´"
                        <> premixed.text_blue(url)
                        <> "´ in "
                        <> int.to_string(duration_ms |> float.truncate)
                        <> "ms!",
                      )
                      [
                        bit_array.base64_encode(resp.body, True),
                        configurable_variables.var_bitstring,
                      ]
                    }
                    _ -> {
                      console.error(
                        "There was an error while trying to download '"
                        <> url |> premixed.text_bright_yellow()
                        <> "' to a variable.",
                      )
                      process.exit(1)
                      panic as "We should not reach here."
                    }
                  }
                  |> promise.resolve()
                }
                [#("path", tom.String(path))] -> {
                  // let file = bun.file(path)
                  // use content <- promise.await(bunfile.text())
                  // `bunfile.text()` pretends it's infallible but is not. It should return a promised result. 
                  // 
                  // Also see: https://github.com/strawmelonjuice/bungibindies/issues/2
                  // Also missing: bunfile.bits(), but that is also because the bitarray and byte array transform is scary to me.
                  //
                  // For now, this means we continue using the sync simplifile.read_bits() function, 
                  case simplifile.read_bits(path) {
                    Ok(bits) -> [
                      bit_array.base64_encode(bits, True),
                      configurable_variables.var_bitstring,
                    ]
                    Error(_) -> {
                      console.error(
                        "Unable to read file '"
                        <> path |> premixed.text_bright_yellow()
                        <> "' to variable.",
                      )
                      process.exit(1)
                      panic as "Should not reach here."
                    }
                  }
                  |> promise.resolve()
                }
                _ ->
                  [configurable_variables.var_unsupported]
                  |> promise.resolve()
              }
            }
            _ -> {
              case unasserted_value {
                tom.Bool(z) -> [
                  bool.to_string(z),
                  configurable_variables.var_boolean,
                ]
                tom.Date(date) -> [
                  date.year |> int.to_string,
                  date.month |> int.to_string,
                  date.day |> int.to_string,
                  configurable_variables.var_date,
                ]
                tom.DateTime(tom.DateTimeValue(date, time, offset)) -> {
                  case offset {
                    tom.Local -> [
                      int.to_string(date.year),
                      int.to_string(date.month),
                      int.to_string(date.day),
                      int.to_string(time.hour),
                      int.to_string(time.minute),
                      int.to_string(time.second),
                      int.to_string(time.millisecond),
                      configurable_variables.var_datetime,
                    ]
                    _ -> [configurable_variables.var_unsupported]
                  }
                }
                tom.Float(a) -> [
                  float.to_string(a),
                  configurable_variables.var_float,
                ]
                tom.Int(b) -> [int.to_string(b), configurable_variables.var_int]
                tom.String(guitar) -> [
                  guitar,
                  configurable_variables.var_string,
                ]
                tom.Time(time) -> [
                  int.to_string(time.hour),
                  int.to_string(time.minute),
                  int.to_string(time.second),
                  int.to_string(time.millisecond),
                  configurable_variables.var_time,
                ]
                _ -> [configurable_variables.var_unsupported]
              }
              |> promise.resolve()
            }
          }
          use conclusion <- promise.await(
            somewhat_asserted_value
            |> promise.map(fn(somewhat_asserted_value) {
              let assert Ok(conclusion) = somewhat_asserted_value |> list.last()
                as "This must be a value, since we just actively set it above."
              conclusion
            }),
          )
          use somewhat_asserted_value <- promise.await(somewhat_asserted_value)
          let z: Result(List(String), ConfigTomlDecodeError) = case
            conclusion == configurable_variables.var_unsupported
          {
            True ->
              Error(FieldError(
                "variables->" <> key <> " does not contain a supported value.",
              ))
            False -> {
              {
                {
                  configurable_variables.typecontrolled
                  |> list.key_find(key)
                  |> result.unwrap(conclusion)
                }
                == conclusion
              }
              |> bool.guard(Ok(somewhat_asserted_value), fn() {
                Error(FieldError(
                  "variables->"
                  <> key
                  <> " does not contain the expected value. --> Expected: "
                  <> configurable_variables.typecontrolled
                  |> list.key_find(key)
                  |> result.unwrap(conclusion)
                  <> ", got: "
                  <> conclusion,
                ))
              })
            }
          }
          promise.resolve(z)
        })
      }
      |> dict.to_list()
      |> list.map(fn(x) {
        let #(key, promise_of_a_value) = x
        use value <- promise.await(promise_of_a_value)
        promise.resolve(#(key, value))
      })
      |> promise.await_list()
    _ -> promise.resolve([])
  }
  use other_vars <- promise.await(other_vars)
  // A kind of manual result.all()
  let other_vars = case
    list.find_map(other_vars, fn(le) {
      let #(_key, result_of_value): #(
        String,
        Result(List(String), ConfigTomlDecodeError),
      ) = le
      case result_of_value {
        Error(err) -> Ok(err)
        _ -> Error(Nil)
      }
    })
  {
    Ok(pq) -> Error(pq)
    Error(Nil) -> {
      other_vars
      |> list.map(fn(it) {
        let assert Ok(b) = it.1
        #(it.0, b)
      })
      |> Ok
    }
  }

  use other_vars <- promise.try_await(other_vars |> promise.resolve)

  Ok(configtype.SharedCynthiaConfigGlobalOnly(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    git_integration:,
    comment_repo:,
    other_vars:,
  ))
  |> promise.resolve()
}

fn content_getter() -> promise.Promise(
  Result(List(contenttypes.Content), String),
) {
  let promises: List(Promise(Result(contenttypes.Content, String))) = {
    fn(file) {
      file
      |> string.replace(".meta.json", "")
      |> files.path_normalize()
    }
    |> fn(value) {
      list.map(
        list.filter(
          result.unwrap(
            simplifile.get_files(files.path_join([process.cwd() <> "/content"])),
            [],
          ),
          fn(file) { file |> string.ends_with(".meta.json") },
        ),
        value,
      )
    }
    |> list.map(get_inner_and_meta)
  }
  let content = promise.map(promise.await_list(promises), result.all)
  content
}

fn get_inner_and_meta(
  file: String,
) -> Promise(Result(contenttypes.Content, String)) {
  use meta_json <- promise.try_await(
    simplifile.read(file <> ".meta.json")
    |> result.replace_error(
      "FS error while reading ´" <> file <> ".meta.json´.",
    )
    |> promise.resolve,
  )
  // Sometimes stuff is saved somewhere else, like in a different file path or maybe somewhere on the web, of course Cynthia Mini can still find those files!
  // ...However, we first need to know there is an "external" file somewhere, we do that by checking the 'path' field.
  // The extension before .meta.json is still used to parse the content.
  let possibly_extern =
    json.parse(meta_json, {
      use path <- decode.optional_field("path", "", decode.string)
      decode.success(path)
    })
    |> result.unwrap("")
    |> string.to_option
  use permalink <- promise.try_await(
    json.parse(meta_json, {
      use path <- decode.optional_field("permalink", "", decode.string)
      decode.success(path)
    })
    |> result.replace_error("Could not decode permalink for ´" <> file <> "´")
    |> promise.resolve,
  )

  use inner_plain <- promise.try_await({
    // This case also check if the permalink starts with "!", in which case it is a content list.
    // Content lists will be generated on the client side, and their pre-given content
    // will be discarded, so loading it in from anywhere would be a waste of resources.
    case string.starts_with(permalink, "!"), possibly_extern {
      True, _ -> promise.resolve(Ok(""))
      False, option.None -> {
        promise.resolve(
          simplifile.read(file)
          |> result.replace_error("FS error while reading ´" <> file <> "´."),
        )
      }
      False, option.Some(p) -> get_ext(p)
    }
  })

  let decoder = contenttypes.content_decoder_and_merger(inner_plain, file)
  let metadata =
    json.parse(meta_json, decoder)
    |> result.map_error(fn(e) {
      "Some error decoding metadata for ´"
      <> file |> premixed.text_magenta()
      <> "´: "
      <> string.inspect(e)
    })

  promise.resolve(metadata)
}

/// Gets external content, beit by file path or by http(s) url.
fn get_ext(path: String) -> promise.Promise(Result(String, String)) {
  case string.starts_with(string.lowercase(path), "http") {
    True -> {
      let start = bun.nanoseconds()
      console.log(
        "Downloading external content ´" <> premixed.text_blue(path) <> "´...",
      )

      let assert Ok(req) = request.to(path)
      use resp <- promise.try_await(
        promise.map(fetch.send(req), fn(e) {
          result.replace_error(
            e,
            "Error while downloading external content ´"
              <> path
              <> "´: "
              <> string.inspect(e),
          )
        }),
      )
      use resp <- promise.try_await(
        promise.map(fetch.read_text_body(resp), fn(e) {
          result.replace_error(
            e,
            "Error while reading external content ´"
              <> path
              <> "´: "
              <> string.inspect(e),
          )
        }),
      )
      let end = bun.nanoseconds()
      let duration_ms = { end -. start } /. 1_000_000.0
      case resp.status {
        200 -> {
          console.log(
            "Downloaded external content ´"
            <> premixed.text_blue(path)
            <> "´ in "
            <> int.to_string(duration_ms |> float.truncate)
            <> "ms!",
          )
          Ok(resp.body)
        }
        _ -> {
          Error(
            "Error while downloading external content ´"
            <> path
            <> "´: "
            <> string.inspect(resp.status),
          )
        }
      }
      |> promise.resolve
    }
    False -> {
      // Is a file path
      promise.resolve(
        simplifile.read(path)
        |> result.replace_error(
          "FS error while reading external content file ´" <> path <> "´.",
        ),
      )
    }
  }
}

fn dialog_initcfg() {
  console.log("No Cynthia Mini configuration found...")
  case
    prompts.for_confirmation(
      "CynthiaMini can create \n"
        <> premixed.text_orange(process.cwd() <> "/cynthia-mini.toml")
        <> "\n ...and some sample content.\n"
        <> premixed.text_magenta(
        "Do you want to initialise new config at this location?",
      ),
      True,
    )
  {
    False -> {
      console.error("No Cynthia Mini configuration found... Exiting.")
      process.exit(1)
      panic as "We should not reach here"
    }
    True -> initcfg()
  }
}

pub fn initcfg() {
  console.log("Creating Cynthia Mini configuration...")
  // Check if cynthia-mini.toml exists
  case files.file_exist(process.cwd() <> "/cynthia-mini.toml") {
    True -> {
      console.error(
        "Error: A config already exists in this directory. Please remove it and try again.",
      )
      process.exit(1)
      panic as "We should not reach here"
    }
    False -> Nil
  }
  let assert Ok(_) =
    simplifile.create_directory_all(process.cwd() <> "/content")
  let assert Ok(_) = simplifile.create_directory_all(process.cwd() <> "/assets")
  let _ =
    { process.cwd() <> "/cynthia-mini.toml" }
    |> fs.write_file_sync(
      "[global]
  # Theme to use for light mode - default themes: autumn, default
  theme = \"autumn\"
  # Theme to use for dark mode - default themes: night, default-dark
  theme_dark = \"night\"
  # For some browsers, this will change the colour of UI elements such as the address bar
  # and the status bar on mobile devices.
  # This is a hex colour, e.g. #FFFFFF
  colour = \"#FFFFFF\"
  # Your website's name, displayed in various places
  site_name = \"My Site\"
  # A brief description of your website
  site_description = \"A big site on a mini Cynthia!\"

  [server]
  # Port number for the web server
  port = 8080
  # Host address for the web server
  host = \"localhost\"

  [integrations]
  # Enable git integration for the website
  # This will allow Cynthia Mini to detect the git repository
  # For example linking to the commit hash in the footer
  git = true
 
  [variables]
  # You can define your own variables here, which can be used in templates.

  ## ownit_template
  ## 
  ## Use this to define your own template for the 'ownit' layout.
  ##
  ## The template will be used for the 'ownit' layout, which is used for pages and posts.
  ## You can use the following variables in the template:
  ##  - body: string (The main HTML content)
  ##  - is_post: boolean (True if the current item is a post, false if it's a page)
  ##  - title: string (The title of the page or post)
  ##  - description: string (The description of the page or post)
  ##  - site_name: string (The global site name)
  ##  - category: string (The category of the post, empty for pages)
  ##  - date_modified: string (The last modification date of the post, empty for pages)
  ##  - date_published: string (The publication date of the post, empty for pages)
  ##  - tags: string[] (An array of tags for the post, empty for pages)
  ##  - menu_1_items: [string, string][] (Array of menu items for menu 1, e.g., [[\"Home\", \"/\"], [\"About\", \"/about\"]])
  ##  - menu_2_items: [string, string][] (Array of menu items for menu 2)
  ##  - menu_3_items: [string, string][] (Array of menu items for menu 3)
  ownit_template = \"\"\"
 <div class=\"p-4\">
  <h1 class=\"text-3xl font-bold mb-4\">{{ title }}</h1>
  <nav class=\"mb-4\">
    <p class=\"font-semibold\">Menu:</p>
    <ul class=\"menu bg-base-200 w-56 rounded-box\">
      {{#each menu_1_items}}
        <li><a href=\"{{this.[1]}}\">{{this.[0]}}</a></li>
      {{/each}}
    </ul>
  </nav>
  {{#if is_post}}
  <p class=\"text-sm text-gray-600 mb-2\">
    Published: {{ date_published }}
    {{#if category }} | Category: <span class=\"badge badge-outline\">{{ category }}</span>{{/if}}
  </p>
  {{/if}}
  <div class=\"divider\"></div>
    <div class=\"prose max-w-none my-4\">
      {{{ body }}}
    </div>
    {{#if is_post}}
      {{#if tags}}
      <div class=\"divider\"></div>
      <p class=\"text-sm text-gray-600 mt-2\">Tags:
        {{#each tags}}
          <span class=\"badge badge-secondary badge-outline mr-1\">{{this}}</span>
        {{/each}}
      </p>
      {{/if}}
    {{/if}}
    </div>  
  \"\"\"

  [posts]
  # Enable comments on posts using utteranc.es
  # Format: \"username/repositoryname\"
  #
  # You will need to give the utterances bot access to your repo.
  # See https://github.com/apps/utterances to add the utterances bot to your repo
  comment_repo = \"\"
  ",
    )
    |> result.map_error(fn(e) {
      premixed.text_error_red("Error: Could not write cynthia-mini.toml: " <> e)
      process.exit(1)
    })
  {
    console.log("Downloading default site icon...")
    // Download https://raw.githubusercontent.com/strawmelonjuice/CynthiaWebsiteEngine-mini/refs/heads/main/asset/153916590.png to assets/site_icon.png
    // Ignore any errors, if it fails, it fails.
    let assert Ok(req) =
      request.to(
        "https://raw.githubusercontent.com/strawmelonjuice/CynthiaWebsiteEngine-mini/refs/heads/main/asset/153916590.png",
      )
    use resp <- promise.try_await(fetch.send(req))
    use resp <- promise.try_await(fetch.read_bytes_body(resp))
    case
      simplifile.write_bits(process.cwd() <> "/assets/site_icon.png", resp.body)
    {
      Ok(_) -> Nil
      Error(_) -> {
        console.error("Error: Could not write assets/site_icon.png")
        Nil
      }
    }
    promise.resolve(Ok(Nil))
  }
  {
    console.log("Creating example content...")
    [
      item(
        to: "hangers.md",
        with: contenttypes.Content(
          filename: "hangers.md",
          title: "Hangers",
          description: "An example page about hangers",
          layout: "theme",
          permalink: "/hangers",
          data: contenttypes.PageData(in_menus: [2]),
          inner_plain: "I have no clue. What are hangers again?

This page will only show up if you have a layout with two or more menus available! :)",
        ),
      ),
      ext_item(
        to: "themes.md",
        from: "https://raw.githubusercontent.com/CynthiaWebsiteEngine/Mini-docs/refs/heads/main/content/3.%20Customisation/3.2-themes.md",
        with: contenttypes.Content(
          filename: "themes.md",
          title: "Themes",
          description: "External page example, using the theme list, downloading from <https://raw.githubusercontent.com/CynthiaWebsiteEngine/Mini-docs/refs/heads/main/content/3.%20customisation/3.2-themes.md>",
          layout: "theme",
          permalink: "/themes",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "",
        ),
      ),
      item(
        "index.md",
        contenttypes.Content(
          filename: "",
          title: "Example landing",
          description: "This is an example index page",
          layout: "cindy-landing",
          permalink: "/",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "# Hello, World


  1. Numbered lists
  2. Images: ![Gleam's Lucy mascot](https://gleam.run/images/lucy/lucy.svg)

  ## The world is big

  ### The world is a little smaller

  #### The world is tiny

  ##### The world is tinier

  ###### The world is the tiniest

  > Also quote blocks!
  >
  > -StrawmelonJuice

  ```bash
  echo \"Code blocks!\"
  // - StrawmelonJuice
  ```
  ",
        ),
      ),
      item(
        to: "example-post.md",
        with: contenttypes.Content(
          filename: "",
          title: "An example post!",
          description: "This is an example post",
          layout: "theme",
          permalink: "/example-post",
          data: contenttypes.PostData(
            category: "example",
            date_published: "2021-01-01",
            date_updated: "2021-01-01",
            tags: ["example"],
          ),
          inner_plain: "# Hello, World!\n\nHello! This is an example post, you'll find me at `content/example-post.md`.",
        ),
      ),
      item(
        to: "posts",
        with: contenttypes.Content(
          filename: "posts",
          title: "Posts",
          description: "this page is not actually shown, due to the ! prefix in the permalink",
          layout: "default",
          permalink: "!/",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "",
        ),
      ),
    ]
    |> list.flatten
    |> write_posts_and_pages_to_fs
  }
}

fn item(
  to path: String,
  with content: contenttypes.Content,
) -> List(#(String, String)) {
  let path = files.path_join([process.cwd(), "/content/", path])
  let meta_json =
    content
    |> contenttypes.encode_content_for_fs
    |> json.to_string()
  let meta_path = path <> ".meta.json"
  case string.starts_with(content.permalink, "!") {
    True -> {
      // No content file for post lists.
      [#(meta_path, meta_json)]
    }
    False -> [#(meta_path, meta_json), #(path, content.inner_plain)]
  }
}

fn ext_item(
  to fpath: String,
  from path: String,
  with content: contenttypes.Content,
) -> List(#(String, String)) {
  let meta_json =
    json.object([
      #("path", json.string(path)),
      #("title", json.string(content.title)),
      #("description", json.string(content.description)),
      #("layout", json.string(content.layout)),
      #("permalink", json.string(content.permalink)),
      #("data", contenttypes.encode_content_data(content.data)),
    ])
    |> json.to_string()

  [
    #(
      files.path_join([process.cwd(), "/content/", fpath]) <> ".meta.json",
      meta_json,
    ),
  ]
}

// What? The function name is descriptive!
fn write_posts_and_pages_to_fs(items: List(#(String, String))) -> Nil {
  items
  |> list.each(fn(set) {
    let #(path, content) = set
    path
    |> fs.write_file_sync(content)
  })
}
