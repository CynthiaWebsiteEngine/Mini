import { Result$Ok, Result$Error } from "../../prelude.mjs";
import { decode } from "cborg";
export function get_color_scheme() {
  if (typeof window !== "undefined") {
    // Media queries the preferred color colorscheme

    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      return false;
    }
  }
  // Default always light.
  return true;
}

export function set_data(el, key, val) {
  // Set a data attribute on an element
  el.setAttribute("data-" + key, val);
}

export function set_hash(hash) {
  // Set the hash of the page
  window.location.hash = hash;
}
export function set_to_404(body) {
  document.body.dataset["404"] = "true";
  document.body.classList.value = "bg-base-100 w-full h-full min-h-screen";
  document.body.innerHTML = body;
  document.title = "404 - Page Not Found";
}

export function whatever_timestamp_to_unix_millis(ts) {
  if (typeof ts === "number") {
    // assume it's already unix millis
    return ts;
  } else if (typeof ts === "string") {
    // try to parse as ISO 8601 string
    const parsed = Date.parse(ts);
    if (!isNaN(parsed)) {
      return parsed;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}

export function get_inner_html(el) {
  // Get the innerHTML of an element
  return el.innerHTML;
}

export function apply_styles_to_comment_box() {
  // Apply styles to the comment box
  const comment_box = document.querySelector("div.utterances");
  if (comment_box) {
    comment_box.classList.add("w-full", "h-full");
    const inner_comment_box = comment_box.children[0];
    if (
      inner_comment_box &&
      inner_comment_box.classList.value == "utterances-frame"
    ) {
      inner_comment_box.classList =
        "utterances-frame w-full min-h-[30vh] h-full outline-none focus:outline-none";
    }
  }
}

export function destroy_comment_box() {
  // Destroy the comment box
  const comment_boxes = Array.from(document.querySelectorAll("div.utterances"));
  for (const comment_box of comment_boxes) {
    if (comment_box) {
      // Remove the comment box from the DOM, but keep the element itself not to conflict with the next comment box
      // Define it as a capturing function, since we'll want to run it a few times actually.
      comment_box.innerHTML = "";
      comment_box.removeAttribute("class");
      comment_box.removeAttribute("style");
    }
  }
}

export function jsonify_string(str) {
  // Convert a string to a JSON object
  try {
    return Result$Ok(JSON.stringify(str));
  } catch (e) {
    console.error("Failed to parse JSON string:", e);
    return Result$Error(null);
  }
}

import { version } from "package.json";
// const version = "Version is not available";
export function my_own_version() {
  return version;
}

export function browse_prompt(l) {
  if (window.confirm("Leave this page and go to '" + l + "'?")) {
    browse(l);
  }
}
export function browse(l) {
  window.location.assign(l);
}

export function cbor_to_dyn(data) {
  try {
    return [decode(data.rawBuffer, {})];
  } catch (a) {
    console.error(a);
    return [];
  }
}

export function is_browser() {
  if (typeof window !== "undefined") {
    return true;
  }
  return false;
}
