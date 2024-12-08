import gladvent
import gleam/int
import gleam/io
import gleam/result

pub fn main() {
  io.println("Hello from aoc!")
  gladvent.run()
}

pub fn unsafe_parse_int(input: String) {
  input
  |> int.parse
  |> unsafe_unwrap("This is not an integer (" <> input <> ")")
}

pub fn unsafe_unwrap(input: Result(a, b), error: String) {
  input
  |> result.lazy_unwrap(fn() { panic as error })
}
