import bungibindies
import bungibindies/bun.{which}
import bungibindies/bun/spawn.{OptionsToSubprocess}
import cynthia_websites_mini_client as client
import cynthia_websites_mini_server/utils/djotparse
import cynthia_websites_mini_server/utils/files.{client_css, client_js}
import cynthia_websites_mini_shared/config/site_json
import cynthia_websites_mini_shared/config/v4_1
import cynthia_websites_mini_shared/config/v4_1/encodes
import cynthia_websites_mini_shared/ffi
import gleam/bool
import gleam/dict
import gleam/javascript/array
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours
import jot
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
      console.log(client.version())
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
    ["pregenerate", ..] | ["run"] | ["static"] | ["start"] -> start()
    ["init", ..] | ["initialise", ..] -> {
      init(args |> list.contains("--force"))
    }
    [] | ["help"] | ["-h"] | ["--help"] -> {
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
                  panic as "Should not reach here."
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
              panic as "Should not reach here."
            }
            // No config found, and no old config found.
            False, _ -> {
              init(True)
              Nil
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
      panic as "Should not reach here."
    }
  }
  let content = {
    case simplifile.get_files("./content") {
      Ok(li) -> {
        list.filter(li, fn(not_metafile) {
          !string.ends_with(not_metafile, ".meta.json")
        })
        |> list.filter(fn(doesnt_have_metafile) {
          simplifile.is_file(doesnt_have_metafile <> ".meta.json") == Ok(True)
        })
        |> list.filter_map(fn(filename) {
          use file_content <- result.try(
            simplifile.read(filename) |> result.replace_error(Nil),
          )
          use file_ext <- result.try({
            filename |> string.split(".") |> list.last()
          })
          let htmlcontent = {
            case file_ext {
              "dj" | "djot" -> {
                // files.djot_to_html_string(file_content)
                djotparse.djot_to_html(file_content)
              }

              "html" | "htm" -> file_content

              _ -> "<pre>" <> file_content <> "</pre>"
            }
          }

          use metajson <- result.try(
            simplifile.read(filename <> ".meta.json")
            |> result.replace_error(Nil),
          )
          // #(filename, htmlcontent) |> echo
          site_json.metadata_decode(metajson:, htmlcontent:)
          |> result.replace_error(Nil)
        })
        |> dict.from_list
      }
      _ -> {
        console.error("Failed to list files inside ./content folder!")
        process.exit(1)
        panic as "Should not reach here."
      }
    }
  }
  site_json.SiteJSON(config, content)
}

import cynthia_websites_mini_shared/config/v4_1/decodes

pub fn create_html(model: client.Model, slug: String) {
  console.log("Writing HTML for " <> slug)
  let json = model.data
  case json.content |> dict.get(slug) {
    Ok(content) -> {
      "<!DOCTYPE html>
<html lang='en'>
<!--
  This site is generated by Cynthia Mini " <> client.version() <> ", a mostly-static site generator written in Gleam.

  Also see: <https://github.com/CynthiaWebsiteEngine/Mini>
-->

<head>
<title>" <> json.config.global.site_name <> "</title>
<meta property='og:site_name' content=" <> json.config.global.site_name
      |> ffi.jsonify_string()
      |> result.unwrap("Site name is invalid") <> "/>
<meta property='og:description' content=" <> json.config.global.site_description
      |> ffi.jsonify_string()
      |> result.unwrap("Site description is invalid") <> "/>
" <> {
        case
          model.data.config.integrations.crawlable_context,
          // Todo: Find out the actual permalink
          site_json.content_to_jsonld(content, "todo-permalink")
        {
          True, Ok(obj) -> {
            "<script type=\"application/ld+json\">\n" <> obj <> "\n</script>"
          }
          _, _ -> ""
        }
      } <> "
<link rel='shortcut icon' href='./assets/site_icon.png' type='image/x-icon'/>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<script type='module' src='/cynthia_client.mjs'></script>
<style>" <> client_css() <> "</style>
</head>
<body class='h-full w-full'>
  <div id='viewable' class='bg-base-100 w-full h-full min-h-screen will-change-transform'>
  " <> client.slug_into_layout(slug, model) <> "
  </div>
 " <> dynamic_footer(True, json.config.integrations.git) <> "
</body>
</html>
"
    }
    _ -> notfoundbody()
  }
}

pub const footer = "Made into this website with <a class='dark:text-sky-600 text-sky-800 underline' target='_blank' href='https://github.com/CynthiaWebsiteEngine/Mini'>Cynthia Mini</a>"

/// The entire <body> of the 404 page.
pub fn notfoundbody() -> String {
  "<div class='absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit'>
	<div class='card bg-primary text-primary-content w-96'>
	  <div class='card-body items-center text-center'>
	    <h2 class='card-title'>404!</h2>
	    <p>Uh-oh, that page cannot be found.</p>
	    <div class='card-actions justify-end'>
	      <button class='btn btn-neutral-300' onclick='javascript:window.location.assign(\"/#/\");javascript:window.location.reload()'>Go home</button>
	      <button class='btn btn-ghost' onclick='javascript:window.history.back(1);javascript:window.location.reload()'>Go back</button>
	    </div>
	  </div>
	</div>
    </div>
    "
  <> footer
}

pub fn dynamic_footer(can_hide: Bool, git_integration: Bool) {
  let f = case git_integration {
    True ->
      [footer]
      |> list.append(
        case
          { simplifile.is_directory(process.cwd() <> "/.git/") },
          which("git")
        {
          Ok(True), Ok(git) -> {
            console.log("[Git integration] git repository detected")
            [
              ", created from "
              <> case
                helper_get_git_remote_commit(),
                {
                  spawn.sync(OptionsToSubprocess(
                    cmd: [git, "rev-parse", "--short", "HEAD"],
                    cwd: Some(process.cwd()),
                    env: None,
                    stderr: Some(spawn.Ignore),
                    stdout: Some(spawn.Pipe),
                  ))
                  |> spawn.stdout()
                  |> result.map(string.trim)
                  |> result.map(string.to_option)
                }
              {
                Some(commit_url), Ok(Some(commit_id)) ->
                  "commit <a href=\""
                  <> commit_url
                  <> "\" class=\"dark:text-sky-600 text-sky-800 underline\"><code>"
                  <> commit_id
                  <> "</code></a>."
                None, Ok(Some(commit_id)) ->
                  " commit id <code>" <> commit_id <> "</code>."
                _, _ -> "a git repo."
              },
            ]
          }
          _, _ -> {
            []
          }
        },
      )
      |> string.concat
    False -> {
      console.log("[Git integration] git repository not detected")
      footer
    }
  }
  "<footer id='cynthiafooter' class='footer transition-transform duration-150 will-change-transform footer-center bg-base-300 dark:bg-slate-800 p-1 sticky bottom-0 h-[50px] z-10'><div><p class='text-base-content'>"
  <> f
  <> "</p></div></footer>"
  <> case can_hide {
    True ->
      "
    <script defer>
	window.setTimeout(function () {
		let lastScrollTop = 0;
		let ticking = false;

		function handleScroll(event) {
			if (!ticking) {
				requestAnimationFrame(function() {
					const footer = document.querySelector('#cynthiafooter');
					let scrollingDown;

					if (event.type === 'wheel') {
						// For wheel events, use deltaY
						scrollingDown = event.deltaY > 0;
					} else {
						// For scroll events, check the target's scroll position
						const target = event.target === document ? document.documentElement : event.target;
						const currentScroll = target.scrollTop;
						scrollingDown = currentScroll > (target.lastScrollTop || 0);
						target.lastScrollTop = currentScroll;
					}

					if (scrollingDown) {
						// Scrolling down
						footer.style.transform = 'translate3d(0, 40px, 0)';
						footer.style.opacity = '0.2';
					} else {
						// Scrolling up
						footer.style.transform = 'translate3d(0, 0, 0)';
						footer.style.opacity = '1';
					}

					ticking = false;
				});
				ticking = true;
			}
		}

		// Listen at the document level for all scroll events
		document.addEventListener('scroll', handleScroll, { capture: true, passive: true });
		document.addEventListener('wheel', handleScroll, { capture: true, passive: true });

		document.querySelector('#cynthiafooter').addEventListener('click', function () {
			this.style.transform = 'translate3d(0, 0, 0)';
			this.style.opacity = '1';
		});
	}, 4000);
       </script>"
    False -> ""
  }
}

/// If succeeds, returns a html link to the current commit on the remote, by just removing the last part of the URL and adding "/commit/<commit_hash>".
fn helper_get_git_remote_commit() -> Option(String) {
  case which("git") {
    Ok(git) -> {
      let remote_cmd =
        spawn.sync(OptionsToSubprocess(
          cmd: [git, "config", "--get", "remote.origin.url"],
          cwd: Some(process.cwd()),
          env: None,
          stderr: Some(spawn.Ignore),
          stdout: Some(spawn.Pipe),
        ))
        |> spawn.stdout()
        |> result.map(string.trim)
        |> option.from_result()
        |> option.map(fn(str) {
          case string.ends_with(str, ".git") {
            True -> string.drop_end(str, 4)
            False -> str
          }
        })
      use remote <- option.then(remote_cmd)
      // If remote does not start with http(s), we can't use it.
      use <- bool.guard(
        when: bool.negate(string.starts_with(remote, "http")),
        return: None,
      )

      let commit_cmd =
        spawn.sync(OptionsToSubprocess(
          cmd: [git, "rev-parse", "--verify", "HEAD"],
          cwd: Some(process.cwd()),
          env: None,
          stderr: Some(spawn.Ignore),
          stdout: Some(spawn.Pipe),
        ))
        |> spawn.stdout()
        |> result.map(string.trim)
        |> option.from_result()
      use commit <- option.then(commit_cmd)
      Some(remote <> "/commit/" <> commit)
    }
    _ -> None
  }
}

fn init(forced: Bool) {
  case forced {
    True ->
      console.warn(
        "The configuration writer is in OVERRIDE mode." |> premixed.bg_orange,
      )
    False -> {
      case simplifile.is_file("./cynthia.toml") == Ok(True) {
        True -> {
          console.error(
            "Cynthia.toml already exists, and the configuration writer is not in override mode. Use with --force to put it in override mode.",
          )
          process.exit(1)
          panic as "Should not reach here."
        }
        False -> Nil
      }
    }
  }
  let write = fn(to: String, with: String) {
    case simplifile.write(to, with) {
      Ok(..) -> Nil
      Error(e) -> {
        console.error(
          "Error: Could not write file: "
          <> gleam_colours.bg_aged_plastic_yellow("./out/" <> to),
        )
        console.error(premixed.text_error_red(simplifile.describe_error(e)))
        process.exit(1)
        panic as "Should not reach here."
      }
    }
  }
  let write_b = fn(to: String, with: BitArray) {
    case simplifile.write_bits(to, with) {
      Ok(..) -> Nil
      Error(e) -> {
        console.error(
          "Error: Could not write file: "
          <> gleam_colours.bg_aged_plastic_yellow("./out/" <> to),
        )
        console.error(premixed.text_error_red(simplifile.describe_error(e)))
        process.exit(1)
        panic as "Should not reach here."
      }
    }
  }
  // Okay!
  write("cynthia.toml", encodes.v4p1_mini_toml(v4_1.new()))
}

fn start() {
  let context = get_context()
  let assert Ok(cwd) = simplifile.current_directory()
  let writer = fn(
    to: String,
    with: c,
    using: fn(String, c) -> Result(Nil, simplifile.FileError),
  ) {
    let target = cwd <> "/out/" <> to

    let target_dir = {
      string.reverse(target)
      |> string.split_once("/")
      |> result.unwrap(#("", ""))
      |> pair.second
      |> string.reverse
    }
    case simplifile.create_directory_all(target_dir) {
      Ok(..) -> {
        // console.log("Created directory: " <> target_dir)
        Nil
      }
      Error(e) -> {
        console.error(
          "Error: Could not create directory: "
          <> gleam_colours.bg_aged_plastic_yellow(target_dir),
        )
        console.error(premixed.text_error_red(simplifile.describe_error(e)))
        process.exit(1)
        panic as "Should not reach here."
      }
    }
    case using(target, with) {
      Ok(..) -> Nil
      Error(e) -> {
        console.error(
          "Error: Could not write file: "
          <> gleam_colours.bg_aged_plastic_yellow(target),
        )
        console.error(premixed.text_error_red(simplifile.describe_error(e)))
        process.exit(1)
        panic as "Should not reach here."
      }
    }
  }
  let write = fn(to: String, with: String) {
    writer(to, with, simplifile.write)
  }
  case context.config.integrations.crawlable_context {
    // Only write site.json if crawlable context is on, otherwise the cbor is enough.
    True -> write("site.json", site_json.site_json(context))
    False -> Nil
  }
  case site_json.site_cbor(context) {
    Error(s) -> {
      console.error("Error: Could not encode data!")
      console.error(s |> string.inspect)
      process.exit(1)
      panic as "Should not reach here."
    }
    Ok(cbor) -> writer("site.cbor", cbor, simplifile.write_bits)
  }
  write("cynthia_client.mjs", client_js())

  let #(model, _) = client.init(context)
  context.content
  |> dict.keys
  |> list.append({
    context.content
    |> dict.values
    |> list.filter_map(fn(m) {
      case m {
        site_json.Post(category:, ..) -> {
          Ok("/category/" <> category)
        }
        site_json.Page(..) -> Error(Nil)
      }
    })
  })
  |> list.append({
    context.content
    |> dict.values
    |> list.filter_map(fn(m) {
      case m {
        site_json.Post(tags:, ..) -> {
          Ok(list.map(tags, fn(tag) { "/tagged/" <> tag }))
        }
        site_json.Page(..) -> Error(Nil)
      }
    })
    |> list.flatten
  })
  |> list.each(fn(slug) {
    case string.contains(slug, "!") || string.contains(slug, "#") {
      True -> {
        case string.starts_with(slug, "#/") {
          True -> {
            let new_slug = string.drop_start(slug, 1)
            console.warn("You may want to replace the slug " <> slug <> "with ")

            write(new_slug <> "/index.html", create_html(model, slug))
          }
          False -> {
            console.log("Skipped writing for item: " <> slug)
            console.info(
              "If you wonder how to browse to it, use a redirect to /" <> slug,
            )
          }
        }
      }
      False -> write(slug <> "/index.html", create_html(model, slug))
    }
  })
  case simplifile.copy_directory(at: "./assets/", to: "./out/assets/") {
    Ok(..) -> Nil
    Error(e) -> {
      console.error("Error: Could not copy assets directory.")
      console.error(premixed.text_error_red(simplifile.describe_error(e)))
      process.exit(1)
      panic as "Should not reach here."
    }
  }
}
