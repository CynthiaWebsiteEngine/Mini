import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import plinth/javascript/console

pub fn error(
  error_message msg: String,
  recoverable recoverable: Bool,
) -> Element(messages.Msg) {
  console.warn("Error page invoked")
  console.error(msg)
  let assert Ok(_) = dom.push_title("Cynthia Mini: Error!")
  html.div(
    [
      attribute.class(
        "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
      ),
    ],
    [
      html.div([attribute.class("card bg-neutral text-neutral-content w-96")], [
        html.div([attribute.class("card-body items-center text-center")], [
          html.h2([attribute.class("card-title")], [
            html.text("An error occurred"),
          ]),
          html.p(
            [
              attribute.class(
                "border-4 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
              ),
            ],
            [html.text(msg)],
          ),
          case recoverable {
            True ->
              html.div([attribute.class("card-actions justify-end")], [
                html.a(
                  [
                    attribute.href("javascript:window.location.reload(1)"),
                    attribute.class("btn btn-neutral-300"),
                  ],
                  [html.text("Refresh")],
                ),
                html.a(
                  [
                    attribute.class("btn btn-ghost"),
                    attribute.href(
                      // You might think "oh no, this isn't activating any lustre messages". Think again.
                      // We WANT to do a fresh page load here. It's an error, so we
                      // can safely assume lustre doesn't know how to get out.
                      "javascript:window.history.back(1);javascript:window.location.reload()",
                    ),
                  ],
                  [html.text("Go back")],
                ),
              ])
            False ->
              html.div([attribute.class("btn btn-neutral-300")], [
                element.text(
                  "If you know the owner of this site, please contact them about this.",
                ),
              ])
          },
        ]),
      ]),
    ],
  )
}
