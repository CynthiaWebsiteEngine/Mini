// import cynthia_websites_mini_client/model_messages
// import cynthia_websites_mini_client/pottery/djotparse
// import gleam/list
// import gleam/string
// import plinth/browser/element

// pub fn parse_html(inner: String, filename: String) {
//   case filename |> string.split(".") |> list.last {
//     // Djot is rendered with a custom renderer. After that, it will be direct lustre elements, so no need to wrap it in a unsafe raw html element.
//     Ok("dj") | Ok("djot") -> html.div([], djotparse.entry_to_conversion(inner))
//     // HTML/SVG is directly pastable into the template.
//     Ok("html") | Ok("htm") | Ok("svg") ->
//       element.unsafe_raw_html("div", "div", [], inner)
//     // Text is wrapped in a <pre> tag. Then it can be pasted into the template.
//     //
//     Ok("txt") -> html.pre([], [html.text(inner)])
//     // Anything else is wrapped in a <pre> tag with a red color. Then it can be pasted into the template. This shows that the file type is not supported.
//     _ ->
//       html.div([], [
//         html.text("Unsupported file type: "),
//         html.text(filename),
//         html.pre([attribute.class("text-red-500")], [
//           html.text(string.inspect(inner)),
//         ]),
//       ])
//   }
// }
