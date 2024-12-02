import gleam/int
import gleam/list
import gleam/result
import gleam/string

type Input =
  List(List(Int))

pub fn parse(input: String) -> Input {
  input
  |> string.split("\n")
  |> list.map(fn(x) {
    x
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
    |> result.unwrap([])
  })
}

pub fn pt_1(input: Input) {
  input
  |> list.filter(is_safe)
  |> list.length
}

fn is_safe(line) {
  let distances =
    list.window_by_2(line)
    |> list.map(fn(pair) { pair.0 - pair.1 })

  let decreasing =
    distances
    |> list.all(fn(distance) {
      int.absolute_value(distance) <= 3
      && int.absolute_value(distance) >= 1
      && distance < 0
    })
  let increasing =
    distances
    |> list.all(fn(distance) {
      int.absolute_value(distance) <= 3
      && int.absolute_value(distance) >= 1
      && distance > 0
    })
  decreasing || increasing
}

pub fn pt_2(input: Input) {
  input
  |> list.filter(fn(line) {
    list.range(0, list.length(line))
    |> list.map(list_remove(line, _))
    |> list.filter(is_safe)
    |> list.length
    > 0
  })
  |> list.length
}

fn list_remove(input_list, index) {
  list.flatten([list.take(input_list, index), list.drop(input_list, index + 1)])
}
