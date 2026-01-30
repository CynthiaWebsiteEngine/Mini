//           let comment_color_scheme = case dom.get_color_scheme() {
//             "dark" -> "github-dark"
//             _ -> "github-light"
//           }

//           list.append(default, [
//             html.script(
//               [
//                 attribute("async", ""),
//                 attribute("crossorigin", "anonymous"),
//                 attribute("theme", comment_color_scheme),
//                 attribute("issue-term", content.permalink),
//                 attribute("repo", repo),
//                 attribute(
//                   "return-url",
//                    model.path,
//                 ),
//                 attribute.src("https://utteranc.es/client.js"),
//               ],
//               "
// ",
//             ),

pub fn parse_html(inner: String, filename: String) -> Element(messages.Msg) {
  case filename |> string.split(".") |> list.last {
    // Djot is rendered with a custom renderer. After that, it will be direct lustre elements, so no need to wrap it in a unsafe raw html element.
    Ok("dj") | Ok("djot") -> html.div([], djotparse.entry_to_conversion(inner))
    // HTML/SVG is directly pastable into the template.
    Ok("html") | Ok("htm") | Ok("svg") ->
      element.unsafe_raw_html("div", "div", [], inner)
    // Text is wrapped in a <pre> tag. Then it can be pasted into the template.
    //
    Ok("txt") -> html.pre([], [html.text(inner)])
    // Anything else is wrapped in a <pre> tag with a red color. Then it can be pasted into the template. This shows that the file type is not supported.
    _ ->
      html.div([], [
        html.text("Unsupported file type: "),
        html.text(filename),
        html.pre([attribute.class("text-red-500")], [
          html.text(string.inspect(inner)),
        ]),
      ])
  }
}
