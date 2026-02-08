import gleam/list
import gleam/string
import jot

pub fn djot_to_html(djot djot: String) -> String {
  djot
  |> preprocess_tables
  |> jot.to_html
  |> string.replace("<a ", "<a class=\"text-info underline\"")
}

pub fn preprocess_tables(djot: String) -> String {
  let lines = string.split(djot, on: "\n")
  process_lines(lines, [], False, False, False)
}

fn process_lines(
  lines: List(String),
  acc: List(String),
  in_table: Bool,
  next_is_header: Bool,
  tbody_opened: Bool,
) -> String {
  case lines {
    [] -> string.join(list.reverse(acc), "\n")
    [line, ..rest] -> {
      let is_table_line = string.starts_with(string.trim(line), "|")
      let is_header = case
        line
        |> string.trim
        |> string.split("|")
        |> string.concat
        |> string.trim
        |> string.replace("-", "")
        |> string.trim
      {
        "" -> {
          // Next line has a |----| structure.
          True
        }
        _ -> False
      }
      let tstart =
        "<table class=\"table table-zebra w-full my-4 border border-neutral-content\">"
      case is_header, in_table, is_table_line {
        // Header is above
        True, True, True -> {
          process_lines(rest, ["<tbody>", ..acc], True, True, True)
        }
        // Table starts
        _, False, True -> {
          process_lines(
            rest,
            [
              "\n``` =html\n"
                <> tstart
                <> "\n"
                <> line_to_row(line, next_is_header),
              ..acc
            ],
            True,
            is_header,
            tbody_opened,
          )
        }

        // Table continues
        False, True, True ->
          process_lines(
            rest,
            [line_to_row(line, next_is_header), ..acc],
            True,
            False,
            tbody_opened,
          )

        // Table ends
        _, True, False -> {
          let acc = case tbody_opened {
            // No header was found, paste a <tbody> right after the <table> tag.
            False ->
              list.map(acc, string.replace(_, tstart, tstart <> "<tbody>"))
            True -> acc
          }
          process_lines(
            rest,
            [line, "</tbody></table>\n```\n", ..acc],
            False,
            False,
            True,
          )
        }

        // Normal text
        _, False, False ->
          process_lines(rest, [line, ..acc], False, False, False)
      }
    }
  }
}

fn line_to_row(line: String, as_header: Bool) -> String {
  let cells =
    line
    |> string.trim
    |> string.split("|")

  case as_header {
    True ->
      "<thead class=\"bg-neutral text-neutral-content\"><tr>"
      <> {
        list.map(cells, fn(c) {
          "  <th class=\"px-4 py-2 text-left font-bold\">"
          <> string.trim(c) |> jot.to_html
          <> "</th>"
        })
        |> string.join("\n")
      }
      <> "</tr></thead>"

    False ->
      "<tr>"
      <> {
        list.map(cells, fn(c) {
          "  <td class=\"px-4 py-2 border-t border-neutral-content\">"
          <> string.trim(c) |> jot.to_html
          <> "</td>"
        })
        |> string.join("\n")
      }
      <> "</tr>"
  }
}
