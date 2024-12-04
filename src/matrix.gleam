import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type Matrix(a) =
  List(List(a))

pub fn rotate_counter_clock_wise(input: Matrix(a)) -> Matrix(a) {
  input
  |> list.transpose
  |> list.reverse
}

pub fn rotate_clock_wise(input: Matrix(a)) -> Matrix(a) {
  input
  |> list.reverse
  |> list.transpose
}

pub fn debug_print_string_matrix(input: Matrix(String)) -> Matrix(String) {
  io.println("=================")
  input
  |> list.map(string.join(_, ""))
  |> string.join("\n")
  |> io.println

  input
}

pub fn debug_print_int_matrix(input: Matrix(Int)) -> Matrix(Int) {
  io.println("=================")
  input
  |> list.map(fn(x) { x |> list.map(int.to_string) |> string.join("") })
  |> string.join("\n")
  |> io.println

  input
}

pub fn parse_string_matrix(input: String) {
  let rows = input |> string.split("\n")
  rows |> list.map(string.split(_, ""))
}

pub fn parse_int_matrix(input: String) {
  let rows = input |> string.split("\n")
  rows |> list.map(string.split(_, ""))
}
