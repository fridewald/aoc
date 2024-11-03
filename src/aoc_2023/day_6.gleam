import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Input =
  List(#(Int, Int))

pub fn parse_1(input: String) -> Input {
  let assert [time, distance] =
    input
    |> string.split("\n")
    |> list.map(fn(in) {
      in
      |> string.split(" ")
      |> list.filter(fn(x) { x != "" })
      |> list.drop(1)
      |> list.filter_map(int.parse)
    })
  list.zip(time, distance)
}

pub fn parse_2(input: String) {
  let assert [time, distance] =
    input
    |> string.split("\n")
    |> list.map(fn(in) {
      in
      |> string.split(" ")
      |> list.drop(1)
      |> list.filter(fn(x) { x != "" })
      |> string.join("")
      |> int.parse
      |> result.unwrap(0)
    })
  #(time, distance)
}

pub fn pt_1(input: String) {
  parse_1(input)
  |> list.map(fn(race) {
    let time = race.0
    let min_distance = race.1 + 1
    list.range(0, time)
    |> list.map(fn(button_press) {
      case button_press * { time - button_press } >= min_distance {
        True -> 1
        False -> 0
      }
    })
    |> int.sum
  })
  |> int.product
}

pub fn pt_2(input: String) {
  let race = parse_2(input)
  let time = race.0
  let min_distance = race.1 + 1
  let assert Ok(first_win) =
    list.range(0, time)
    |> list.find(fn(button_press) {
      button_press * { time - button_press } >= min_distance
    })

  time + 1 - { 2 * first_win }
}
