#!/usr/bin/env bun
// Check if running in bun
if (!process.versions.bun) {
  console.error("Cynthia Mini is only meant to be built and ran in Bun.");
  process.exit(1);
}
if (process.argv[2] == "prereqs") {
  // Clearly, we're running in Bun.
  process.exit(0);
}

function help() {
  console.log("To build, run: bun `./build.ts bundle`");
  console.log("To run, run: bun `./build.ts run`");
  console.log("To test, run: bun `./build.ts test`");
  console.log("To check, run: bun `./build.ts check`");
  console.log("To clean, run: bun `./build.ts clean`");
  console.log("To format, run: bun `./build.ts fmt`");
  console.log(
    "To run gleam commands on one or both ends, run: bun `./build.ts [client-|server-]gleam <subcommand>`",
  );
}
let executed = true;
import themeconf from "./themes.json";
import path from "path";
import CleanCSS from "clean-css";
import { readFileSync, writeFileSync } from "fs";
switch (process.argv[2].toLowerCase()) {
  case "clean":
    {
      console.log("Cleaning up...");
      {
        const results: boolean[] = [];
        results.push(
          Bun.spawnSync({
            cmd: ["gleam", "clean"],
            cwd: "./cynthia_websites_mini_client/",
            // stderr: "inherit",
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["gleam", "clean"],
            cwd: "./cynthia_websites_mini_server/",
            // stderr: "inherit",
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["gleam", "clean"],
            cwd: "./cynthia_websites_mini_shared/",
            // stderr: "inherit",
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["rm", "-rf", "./dist"],
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["rm", "-rf", "./node_modules/"],
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: [
              "rm",
              "-rf",
              "./cynthia_websites_mini_server/src/client_code_generated_ffi.ts",
            ],
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["rm", "-rf", "./cynthia_websites_mini_client/prelude.ts"],
          }).success,
        );
        results.push(
          Bun.spawnSync({
            cmd: ["rm", "-rf", "./cynthia_websites_mini_server/prelude.ts"],
          }).success,
        );

        if (results.every((x) => x)) {
          console.log("cleared.");
        } else {
          console.error("cleaning failed, aborting");
          process.exit(1);
        }
      }
    }
    break;
  case "fmt":
    {
      const a = Bun.spawnSync({
        cmd: ["gleam", "format"],
        cwd: "./cynthia_websites_mini_server/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      const b = Bun.spawnSync({
        cmd: ["gleam", "format"],
        cwd: "./cynthia_websites_mini_client/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      if (a && b) {
        console.log("formatting successful.");
      } else {
        console.error("formatting failed, aborting");
        process.exit(1);
      }
    }
    break;
  case "check":
    {
      console.log("Checking code...");
      {
        // Check the code
        console.log("Checking server code:");
        const a = Bun.spawnSync({
          cmd: ["gleam", "check"],
          cwd: "./cynthia_websites_mini_server/",
          stdout: "inherit",
          stderr: "inherit",
        }).success;
        console.log("Checking client code:");
        const b = Bun.spawnSync({
          cmd: ["gleam", "check"],
          cwd: "./cynthia_websites_mini_client/",
          stdout: "inherit",
          stderr: "inherit",
        }).success;
        if (a && b) {
          console.log("checks successful.");
        } else {
          console.error("checks failed, aborting");
          process.exit(1);
        }
      }
    }
    break;
  case "":
    help();
    break;
  default:
    {
      executed = false;
    }
    break;
}
if (executed == true) {
  process.exit(0);
}
{
  // Run 'gleam deps download' on both ends
  let r = [];
  r.push(
    Bun.spawnSync({
      cmd: ["gleam", "deps", "download"],
      cwd: "./cynthia_websites_mini_shared/",
      stdout: "inherit",
      stderr: "inherit",
    }).success,
  );
  r.push(
    Bun.spawnSync({
      cmd: ["gleam", "deps", "download"],
      cwd: "./cynthia_websites_mini_client/",
      stdout: "inherit",
      stderr: "inherit",
    }).success,
  );
  r.push(
    Bun.spawnSync({
      cmd: ["gleam", "deps", "download"],
      cwd: "./cynthia_websites_mini_server/",
      stdout: "inherit",
      stderr: "inherit",
    }).success,
  );
  if (r.every((x) => x)) {
    console.log("Dependencies downloaded.");
  } else {
    console.error("Dependency download failed, aborting");
    process.exit(1);
  }
}
// Create links to the Gleam preludes, so that we can import them in FFI code.
// This is a workaround for the fact that Bun somehow doesn't seem to be respecting TSConfig rootdir paths.
{
  const fo = Bun.file(__dirname + "/cynthia_websites_mini_client/prelude.ts");
  fo.write(`export * from "./build/dev/javascript/prelude.mjs";`);
}
{
  const fo = Bun.file(__dirname + "/cynthia_websites_mini_server/prelude.ts");
  fo.write(`export * from "./build/dev/javascript/prelude.mjs";`);
}
console.log("Checking Bun dependencies...");
Bun.spawnSync({
  cmd: ["bun", "install"],
  stdout: "inherit",
  stderr: "inherit",
});

console.log("Building themes");
const daisyui_themes = [];
let themes_gleam_content = `
// This file is generated by build.ts
// Do not edit it manually.
pub type SharedCynthiaTheme {
  SharedCynthiaTheme(
    name: String,
    fonts: List(String),
    fonts_mono: List(String),
    font_size: Float,
    font_size_mono: Float,
    prevalence: ThemePrevalence,
    daisy_ui_theme_name: String,
    layout: String,
  )
}

pub type ThemePrevalence {
  ThemeDark
  ThemeLight
}

pub const themes = [


`;
for (const theme of themeconf) {
  let prevalence = "ThemeLight";
  if (theme.prevalence === "dark") {
    prevalence = "ThemeDark";
  }
  const daisy_ui_theme_name: string = (() => {
    if (typeof theme.daisyUI === "string") {
      return theme.daisyUI;
    }
    return Object.keys(theme.daisyUI)[0];
  })();
  const font_size = (() => {
    const a = theme["font-size"].toString();
    if (a.includes(".")) {
      return a;
    }
    return `${a}.0`;
  })();
  const font_size_mono = (() => {
    const a = theme["font-size-mono"].toString();
    if (a.includes(".")) {
      return a;
    }
    return `${a}.0`;
  })();
  themes_gleam_content += `
  SharedCynthiaTheme(
    name: "${theme.name}",
    fonts: ${JSON.stringify(theme.fonts)},
    fonts_mono: ${JSON.stringify(theme["fonts-mono"])},
    font_size: ${font_size},
    font_size_mono: ${font_size_mono},
    prevalence: ${prevalence},
    daisy_ui_theme_name: "${daisy_ui_theme_name}",
    layout: "${theme.layout}"
  ),

`;
  daisyui_themes.push(theme.daisyUI);
}
themes_gleam_content += `]
`;
const fo = Bun.file(
  __dirname +
    "/cynthia_websites_mini_shared/src/cynthia_websites_mini_shared/ui/themes_generated.gleam",
);
fo.write(themes_gleam_content);
const tailwindconfig: import("tailwindcss").Config = {
  daisyui: {
    themes: daisyui_themes,
  },
  content: [
    "./cynthia_websites_mini_client/**/*{.gleam,.ts}",
    "./cynthia_websites_mini_server/src/cynthia_websites_mini_server/static_routes.gleam",
    "./cynthia_websites_mini_shared/src/cynthia_websites_mini_shared/ui.gleam",
  ],
  theme: {
    extend: {},
  },
  plugins: [require("daisyui")],
};

console.log("Building and bundling client code...");
{
  const o = Bun.spawnSync({
    cmd: ["gleam", "build"],
    cwd: "./cynthia_websites_mini_client/",
    stderr: "inherit",
  }).success;
  if (o) {
  } else {
    console.error("client build failed, aborting");
    process.exit(1);
  }

  const z = await Bun.file(
    "./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/gleam.ts",
  );
  if (await z.exists()) {
    z.unlink().catch((e) => {
      console.log(
        "Failed to remove ./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/gleam.ts",
      );
      console.error(e);
    });
  }
  await Bun.write(
    "./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/cynthia_websites_mini_client.ts",
    `import { main } from "./cynthia_websites_mini_client.mjs";document.addEventListener("DOMContentLoaded", main());`,
  );
  // Bundle client code to a single file
  await Bun.build({
    entrypoints: [
      "./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/cynthia_websites_mini_client.ts",
    ],
    outdir: "./cynthia_websites_mini_client/build/bundled/",
    minify: {
      whitespace: true,
      syntax: true,
      identifiers: false,
    },
    target: "browser",
  }).catch((e) => {
    console.error(e);
    process.exit(1);
  });
  let css = "/* Something has gone wrong building this CSS. */";

  const postcss = require("postcss");
  const tailwindcss = require("tailwindcss");

  const sourceCSS = `
/* Until I figure out a way to download these to the server reliably, I'm just going to import them from the web. */
@import url('https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css');
@import url('https://fontlay.com/css2?family=Fira+Mono:wght@400;500;700&family=Fira+Sans:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&family=IBM+Plex+Mono:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;1,100;1,200;1,300;1,400;1,500;1,600;1,700&family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&family=JetBrains+Mono:ital,wght@0,100..800;1,100..800&family=Merriweather:ital,opsz,wght@0,18..144,300..900;1,18..144,300..900&family=Noto+Sans:ital,wght@0,100..900;1,100..900&family=Open+Sans:ital,wght@0,300..800;1,300..800&family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&family=Quicksand:wght@300..700&family=Ubuntu:ital,wght@0,300;0,400;0,500;0,700;1,300;1,400;1,500;1,700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;
h1, h2, h3, h4, h5, h6, .text-lg, .text-xl, .text-2xl, .text-3xl, .text-4xl, .text-5xl, .text-6xl {
  font-family: 'Red Hat Display', sans-serif;
}
body, p, a, button, .text-sm, .text-base {
  font-family: 'Quicksand', sans-serif;
}
@layer base {
  ul ul {
    list-style-type: revert;
  }
  li {
    padding-left: 30px;
  }
}

`;
  const config = {
    presets: [tailwindconfig],
  };
  await postcss([tailwindcss(config)])
    .process(sourceCSS, { from: undefined })
    .then((genned_css: { css: string }) => {
      // `css` is a string of the compiled CSS.
      css = genned_css.css;
    })
    .catch((err: any) => {
      console.error(err);
    });
  const client_styles = JSON.stringify(
    new CleanCSS({
      level: 2,
    }).minify(css).styles,
  );

  const client_script = JSON.stringify(
    await Bun.file(
      "./cynthia_websites_mini_client/build/bundled/cynthia_websites_mini_client.js",
    ).text(),
  );
  console.log("Putting client script and styles into server code...");
  Bun.file(
    "./cynthia_websites_mini_server/src/client_code_generated_ffi.ts",
  ).write(
    `export function client_script() { return ${client_script}; }
export function client_styles() { return ${client_styles}; }`,
  );
}
console.log("Building and bundling server code...");
{
  // Compile the server code to JavaScript
  const o = Bun.spawnSync({
    cmd: ["gleam", "build"],
    cwd: "./cynthia_websites_mini_server/",
    stderr: "inherit",
  }).success;
  // Check if the build was successful
  if (o) {
  } else {
    console.error("server build failed, aborting");
    process.exit(1);
  }
  const z = await Bun.file(
    "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/gleam.ts",
  );
  if (await z.exists()) {
    z.unlink().catch((e) => {
      console.log(
        "Failed to remove ./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/gleam.ts",
      );
      console.error(e);
    });
  }
  // Create entry point for the server
  await Bun.write(
    "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
    `import { main } from "./cynthia_websites_mini_server.mjs";main();`,
  );
}
console.log("Prepping code successfully completed.");
switch (process.argv[2].toLowerCase()) {
  case "gleam":
    {
      const argumens = process.argv.slice(3);
      console.log(
        "Running" + (" `gleam " + argumens.join(" ")) + "` on both ends.",
      );
      const a = Bun.spawnSync({
        cmd: ["gleam", ...argumens],
        cwd: "./cynthia_websites_mini_server/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      const b = Bun.spawnSync({
        cmd: ["gleam", ...argumens],
        cwd: "./cynthia_websites_mini_client/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      if (a && b) {
        console.log("gleam command successful.");
      } else {
        console.error("gleam command failed, aborting");
        process.exit(1);
      }
    }
    break;
  case "client-gleam":
    {
      const argumens = process.argv.slice(3);
      console.log(
        "Running" + (" `gleam " + argumens.join(" ")) + "` on client.",
      );
      const b = Bun.spawnSync({
        cmd: ["gleam", ...argumens],
        cwd: "./cynthia_websites_mini_client/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      if (b) {
        console.log("gleam command successful.");
      } else {
        console.error("gleam command failed, aborting");
        process.exit(1);
      }
    }
    break;
  case "server-gleam":
    {
      const argumens = process.argv.slice(3);
      console.log(
        "Running" + (" `gleam " + argumens.join(" ")) + "` on server.",
      );
      const b = Bun.spawnSync({
        cmd: ["gleam", ...argumens],
        cwd: "./cynthia_websites_mini_server/",
        stdout: "inherit",
        stderr: "inherit",
      }).success;
      if (b) {
        console.log("gleam command successful.");
      } else {
        console.error("gleam command failed, aborting");
        process.exit(1);
      }
    }
    break;
  case "bundle":
    {
      const bytecode = process.argv.includes("--bytecode");
      const bcodestring = bytecode ? "bytecode" : "";
      console.log(`Compiling all to single ${bcodestring} package...`);
      {
        // Bundle code to dist
        const s = await Bun.build({
          minify: false,
          target: "bun",
          entrypoints: [
            "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
          ],
          bytecode,
          outdir: "./dist",
          sourcemap: "linked",
        });
        const shebang = `#!/usr/bin/env bun`;
        let bundle = readFileSync(
          "./dist/cynthia_websites_mini_server.js",
        ).toString();
        bundle = shebang + "\n\n" + bundle;
        writeFileSync("./dist/cynthia_websites_mini_server.js", bundle);
        if (s.success) console.log("Bundling completed.");
        else {
          console.error("Bundling failed, aborting\n\n" + s.logs);
          process.exit(1);
        }
      }
    }
    break;
  case "run-cd":
    {
      if (
        process.argv[4] != undefined &&
        process.argv[4].toLowerCase() == "static"
      ) {
        console.info("Static generation, then starting local bun server.");
        if (
          Bun.spawnSync({
            cmd: [
              "bun",
              path.join(
                __dirname,
                "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
              ),
              "static",
            ],
            stdout: "inherit",
            stderr: "inherit",
            stdin: "inherit",
            cwd: process.argv[3],
          }).success
        ) {
          Bun.spawnSync({
            cwd: path.join(process.argv[3], "/out"),
            cmd: ["bunx", "serve"],
            stdout: "inherit",
            stderr: "inherit",
            stdin: "inherit",
          });
        }
      } else {
        console.info("Starting Cynthia Mini as server.");
        Bun.spawnSync({
          cmd: [
            "bun",
            path.join(
              __dirname,
              "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
            ),
            "dynamic",
          ],
          stdout: "inherit",
          stderr: "inherit",
          stdin: "inherit",
          cwd: process.argv[3],
        });
      }
    }
    break;
  case "run":
    {
      console.log("Running server...");
      // Run the server
      Bun.spawnSync({
        cmd: [
          "bun",
          "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
        ],
        stdout: "inherit",
        stderr: "inherit",
        stdin: "inherit",
      });
    }
    break;
  case "test":
    {
      console.log("Running tests...");
      {
        const results: boolean[] = [];
        // Run the tests
        if (
          process.argv[3] != null &&
          !(process.argv[3].toLowerCase() === "client")
        ) {
          console.log("Running tests for server:");
          results.push(
            Bun.spawnSync({
              cmd: ["gleam", "test"],
              cwd: "./cynthia_websites_mini_server/",
              stdout: "inherit",
              stderr: "inherit",
            }).success,
          );
        }
        if (
          process.argv[3] != null &&
          !(process.argv[3].toLowerCase() === "server")
        ) {
          console.log("Running tests for client:");
          results.push(
            Bun.spawnSync({
              cmd: ["gleam", "test"],
              cwd: "./cynthia_websites_mini_client/",
              stdout: "inherit",
              stderr: "inherit",
            }).success,
          );
        }
        if (
          process.argv[3] == null ||
          process.argv[3].toLowerCase() == "both"
        ) {
          console.log("Running tests for both:");
          results.push(
            Bun.spawnSync({
              cmd: ["gleam", "test"],
              cwd: "./cynthia_websites_mini_server/",
              stdout: "inherit",
              stderr: "inherit",
            }).success,
          );
          results.push(
            Bun.spawnSync({
              cmd: ["gleam", "test"],
              cwd: "./cynthia_websites_mini_client/",
              stdout: "inherit",
              stderr: "inherit",
            }).success,
          );
        }
        if (results.every((x) => x)) {
          console.log("test(s) successful.");
        } else {
          console.error("test(s) failed!");
          process.exit(1);
        }
      }
    }
    break;

  default:
    help();
}
process.exit(0);
