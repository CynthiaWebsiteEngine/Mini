import fs from "node:fs";
import path from "node:path";
import djot from "@djot/djot";
import { List } from "../../../prelude.mjs";

export function exists(a: string): boolean {
  return fs.existsSync(a);
}

export function path_join(paths: List): string {
  return path.join(...paths.toArray());
}

export function path_normalize(p: string): string {
  return path.normalize(p);
}

export function djot_to_html(dj: string) {
  return (
    djot.renderHTML(djot.parse(dj, { sourcePositions: false }), {
      overrides: {
        heading(node, context) {
          const level = node.level;
          const classes: Record<number, string> = {
            1: "text-4xl font-bold text-accent",
            2: "text-3xl font-bold text-accent",
            3: "text-2xl font-bold text-accent",
            4: "text-xl font-bold text-accent",
            5: "text-lg font-bold text-accent",
            6: "font-bold text-accent",
          };
          return `<h${level}${context.renderAttributes(node)} class="${classes[level] || classes[6]}">${context.renderChildren(node)}</h${level}>`;
        },
        // Todo: Add more https://github.com/CynthiaWebsiteEngine/Mini/blob/main/cynthia_websites_mini_client/src/cynthia_websites_mini_client/pottery/djotparse.gleam overrides.
      },
    }) ?? dj
  );
}
