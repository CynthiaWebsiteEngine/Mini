// Ownit layout FFI module
// Ownit is the only layout that has it's own FFI implementations, since Gleam doesn't have any direct bindings to Handlebars.js
// And well, I'd like to support full Handlebars :shrug:

import Handlebars from "handlebars";
import { Ok, Error } from "../../../../prelude";

export function compile_template_string(template_string: string) {
  try {
    return new Ok(Handlebars.compile(template_string));
  } catch (e) {
    console.error("Error while compiling Handlebars template string:", e);
    return new Error(null);
  }
}

export function context_into_template_run(
  template: HandlebarsTemplateDelegate<any>,
  ctx_record: any,
) {
  const ctx = turn_gleam_record_into_js_object(ctx_record);
  try {
    return new Ok(template(ctx));
  } catch (e) {
    console.error("Error while running Handlebars template with context:", e);
    return new Error(null);
  }
}

interface context {
  body: string;
  is_post: boolean;
  title: string;
  description: string;
  site_name: string;
  category: string;
  date_modified: string;
  date_published: string;
  tags: string[];
  menu_1_items: [string, string][];
  menu_2_items: [string, string][];
  menu_3_items: [string, string][];
}

function turn_gleam_record_into_js_object(record: any): context {
  return {
    body: record.content,
    is_post: record.is_post,
    title: record.title,
    description: record.description,
    site_name: record.site_name,
    category: record.category,
    date_modified: record.date_modified,
    date_published: record.date_published,
    tags: record.tags,
    menu_1_items: record.menu_1_items || [],
    menu_2_items: record.menu_2_items || [],
    menu_3_items: record.menu_3_items || [],
  };
}
