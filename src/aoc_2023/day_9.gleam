import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder as iterator

pub fn parse(input: String) -> List(List(Int)) {
  input
  |> string.split("\n")
  |> list.map(fn(s) {
    string.split(s, " ")
    |> list.map(fn(x) {
      let assert Ok(number) = int.parse(x)
      number
    })
  })
}

pub fn pt_1(input: List(List(Int))) {
  input
  |> list.map(fn(in_1) { do_the_stuff(list.reverse(in_1)) })
  |> result.all
  |> result.unwrap([])
  |> list.map(fn(x) { x.1 })
  |> list.fold(0, fn(a, b) { a + b })
}

fn do_the_stuff(input: List(Int)) {
  iterator.unfold(from: #(input, 0), with: fn(in) {
    case in.0 |> list.all(fn(x) { x == 0 }) {
      True -> iterator.Done
      False -> {
        let assert Ok(first_item) = list.first(in.0)
        let next_row =
          in.0
          |> list.window_by_2
          |> list.map(fn(win) { win.0 - win.1 })
        iterator.Next(element: #(next_row, first_item + in.1), accumulator: #(
          next_row,
          first_item + in.1,
        ))
      }
    }
  })
  |> iterator.last
}

pub fn pt_2(input: List(List(Int))) {
  input
  |> list.map(do_the_stuff(_))
  |> result.all
  |> result.unwrap([])
  |> list.map(fn(x) { x.1 })
  |> list.fold(0, fn(a, b) { a + b })
}
