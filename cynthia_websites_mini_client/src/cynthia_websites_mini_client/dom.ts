export function get_color_scheme() {
  // Media queries the preferred color colorscheme

  if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    return "dark";
  }
  return "light";
}

export function set_data(el: HTMLElement, key: string, val: string) {
  // Set a data attribute on an element
  el.setAttribute("data-" + key, val);
}

export function set_hash(hash: string) {
  // Set the hash of the page
  window.location.hash = hash;
}
export function set_to_404(body: string) {
  document.body.dataset["404"] = "true";
  document.body.classList.value = "bg-base-100 w-full h-full min-h-screen";
  document.body.innerHTML = body;
  document.title = "404 - Page Not Found";
}

export function get_inner_html(el: HTMLElement) {
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
