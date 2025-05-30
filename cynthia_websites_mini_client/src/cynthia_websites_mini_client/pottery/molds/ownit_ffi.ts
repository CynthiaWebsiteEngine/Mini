// Ownit layout FFI module
// Ownit is the only layout that has it's own FFI implementations, since Gleam doesn't have any direct bindings to Handlebars.js
// And well, I'd like to support full Handlebars :shrug:

import Handlebars from "handlebars";
import { Ok, Error } from "../../../../prelude";

export function compile_template_string(template_string: string) {
  try {
    return new Ok(Handlebars.compile(template_string));
  } catch {
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
  } catch {
    return new Error(null);
  }
}

interface context {
  body: string;
}

function turn_gleam_record_into_js_object(record: any): context {
  console.log(record);
  return {
    body: record.content,
  };
}
