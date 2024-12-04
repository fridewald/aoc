import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import grid.{type Grid, Posn}

type Input =
  Grid

pub fn parse(input: String) -> Input {
  let my_simple_grid =
    input
    |> string.split("\n")
    |> list.map(string.to_graphemes)
    |> list.index_map(fn(row, i_y) {
      list.index_map(row, fn(val, i_x) { #(Posn(i_x, i_y), val) })
    })
    |> list.flatten
    |> dict.from_list
  my_simple_grid
}

fn expand(grid: Grid, factor: Int) {
  let max_x =
    grid |> dict.to_list |> list.fold(0, fn(acc, x) { int.max(acc, { x.0 }.x) })
  let max_y =
    grid |> dict.to_list |> list.fold(0, fn(acc, y) { int.max(acc, { y.0 }.y) })
  let expand_cols =
    list.range(0, max_x)
    |> list.scan(0, fn(acc, col) {
      case
        grid
        |> dict.filter(fn(key, _val) { key.x == col })
        |> dict.values
        |> list.all(fn(x) { x == "." })
      {
        True -> acc + factor
        False -> acc
      }
    })
  let expand_rows =
    list.range(0, max_y)
    |> list.scan(0, fn(acc, col) {
      case
        grid
        |> dict.filter(fn(key, _val) { key.y == col })
        |> dict.values
        |> list.all(fn(x) { x == "." })
      {
        True -> acc + factor
        False -> acc
      }
    })
  let expand_dict =
    expand_rows
    |> list.index_map(fn(y, i_y) {
      expand_cols
      |> list.index_map(fn(x, i_x) { #(Posn(i_x, i_y), #(x, y)) })
    })
    |> list.flatten
    |> dict.from_list

  grid
  |> dict.to_list
  |> list.map(fn(key_values) {
    let key = key_values.0
    let value = key_values.1
    let move = expand_dict |> dict.get(key) |> result.unwrap(#(0, 0))
    #(Posn(key.x + move.0, key.y + move.1), value)
  })
  |> dict.from_list
}

pub fn pt_1(input: Input) {
  expand(input, 1)
  |> count_dists
}

pub fn pt_2(input: Input) {
  expand(input, 1_000_000 - 1)
  |> count_dists
}

fn count_dists(grid: Grid) {
  grid
  |> dict.filter(fn(_, val) { val != "." })
  |> dict.to_list
  |> list.combination_pairs
  |> list.fold(0, fn(acc, pair) {
    let dist =
      int.absolute_value({ pair.0.0 }.x - { pair.1.0 }.x)
      + int.absolute_value({ pair.0.0 }.y - { pair.1.0 }.y)

    acc + dist
  })
}
