// import gladvent
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/string_tree
import vector.{type Vector, Vector}

pub type Grid(a) =
  dict.Dict(Vector, a)

pub type GridSized {
  Grid(grid: dict.Dict(Vector, String), size: #(Int, Int))
}

pub fn parse_grid_typed(
  input: String,
  parser: fn(String) -> Result(a, Nil),
) -> Result(Grid(a), Nil) {
  input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.index_map(fn(row, i_y) {
    list.index_map(row, fn(val, i_x) {
      parser(val) |> result.map(fn(parsed) { #(Vector(i_x, i_y), parsed) })
    })
  })
  |> list.flatten
  |> result.all
  |> result.map(dict.from_list)
}

pub fn parse_grid(input: String) -> Grid(String) {
  input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.index_map(fn(row, i_y) {
    list.index_map(row, fn(val, i_x) { #(Vector(i_x, i_y), val) })
  })
  |> list.flatten
  |> dict.from_list
}

pub fn order_grid(grid: Grid(a)) -> List(#(Vector, a)) {
  grid
  |> dict.to_list
  |> list.sort(by: fn(pos1, pos2) {
    let y_comp = int.compare({ pos1.0 }.y, { pos2.0 }.y)
    case y_comp {
      order.Eq -> int.compare({ pos1.0 }.x, { pos2.0 }.x)
      _ -> y_comp
    }
  })
}

pub fn print_grid(grid: Grid(a)) -> Grid(a) {
  let out =
    order_grid(grid)
    |> list.fold(string_tree.new(), fn(acc, x) {
      let acc = case { x.0 }.x == 0 && { x.0 }.y != 0 {
        True -> acc |> string_tree.append("\n")
        False -> acc
      }
      acc |> string_tree.append(string.inspect(x.1))
    })
    |> string_tree.to_string
  io.println(out)
  grid
}

pub fn print_grid_string(grid: Grid(String)) -> Grid(String) {
  let out =
    order_grid(grid)
    |> list.fold(string_tree.new(), fn(acc, x) {
      let acc = case { x.0 }.x == 0 && { x.0 }.y != 0 {
        True -> acc |> string_tree.append("\n")
        False -> acc
      }
      acc |> string_tree.append(x.1)
    })
    |> string_tree.to_string
  io.println(out)
  grid
}

pub fn size(grid: Grid(a)) -> #(Int, Int) {
  let keys =
    grid
    |> dict.keys

  let x_max =
    keys
    |> list.fold(0, fn(acc, key) { int.max(acc, key.x) })
  let y_max =
    keys
    |> list.fold(0, fn(acc, key) { int.max(acc, key.y) })
  #(x_max, y_max)
}

pub fn inside(grid: Grid(a), posn: Vector) -> Bool {
  dict.has_key(grid, posn)
}
