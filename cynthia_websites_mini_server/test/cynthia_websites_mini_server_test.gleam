import bungibindies/bun
import cynthia_websites_mini_client/timestamps
import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import plinth/node/fs
import plinth/node/process
import simplifile

pub fn main() {
  gleeunit.main()
}

// Test timestamp parsing
pub fn timestamp_to_timestamp_test() {
  let times = #("2025-01-31T12:38:20Z", "2025-01-31T12:38:20+00:00")
  let results = #(timestamps.parse(times.0), timestamps.parse(times.1))
  bun.deep_equals(results.1, results.0)
  |> should.be_true()
}

// Test timestamp formatting
pub fn timestamp_to_string_test() {
  let time = "2025-01-31T12:38:20.000Z"
  let result = timestamps.parse(time) |> timestamps.create()
  result
  |> should.equal(time)
}

// Make sure this workspace is free of any mentions of `gleam/io`.
pub fn no_gleam_io_test() {
  let assert Ok(files) = simplifile.get_files(process.cwd() <> "/..")
  let results =
    list.filter(files, fn(file) {
      let assert Ok(orig) = fs.read_file_sync(file)
      string.contains(orig, "import gleam/io")
    })
    |> list.filter(string.ends_with(_, ".gleam"))
    |> list.filter(fn(a) {
      a |> string.ends_with("test.gleam") |> bool.negate()
    })
    |> list.filter(fn(a) { a |> string.contains("build") |> bool.negate() })
  list.is_empty(results)
  |> bool.lazy_guard(when: _, return: fn() { Nil }, otherwise: fn() {
    let f =
      "Found usage of `gleam/io` in: \n - "
      <> string.join(results, "\n - ")
      <> "\n "
      <> list.length(results) |> int.to_string()
      <> " files affected."
    panic as f
  })
}
