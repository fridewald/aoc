// import gladvent
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/string_tree

pub type Grid(a) =
  dict.Dict(Posn, a)

pub type GridSized {
  Grid(grid: dict.Dict(Posn, String), size: #(Int, Int))
}

pub type Posn {
  Posn(x: Int, y: Int)
}

pub type Vector =
  Posn

pub fn sub(posn1: Vector, posn2: Vector) -> Vector {
  Posn(posn1.x - posn2.x, posn1.y - posn2.y)
}

pub fn add(posn1: Vector, posn2: Vector) -> Vector {
  Posn(posn1.x + posn2.x, posn1.y + posn2.y)
}

pub fn minus(posn1: Vector) -> Vector {
  Posn(-posn1.x, -posn1.y)
}

pub fn multi(posn: Vector, n: Int) -> Vector {
  Posn(n * posn.x, n * posn.y)
}

// pub fn parse_grid_sized(input: String) -> GridSized {
//   let grid = parse_grid(input)
//   Grid(grid:, size: size(grid))
// }

// pub fn debug_print_grid_sized(grid: GridSized) -> GridSized {
//   let out =
//     grid.grid
//     |> dict.to_list
//     |> list.sort(by: fn(pos1, pos2) {
//       let y_comp = int.compare({ pos1.0 }.y, { pos2.0 }.y)
//       case y_comp {
//         order.Eq -> int.compare({ pos1.0 }.x, { pos2.0 }.x)
//         _ -> y_comp
//       }
//     })
//     |> list.fold(string_tree.new(), fn(acc, x) {
//       let acc = case { x.0 }.x == 0 && { x.0 }.y != 0 {
//         True -> acc |> string_tree.append("\n")
//         False -> acc
//       }
//       acc |> string_tree.append(x.1)
//     })
//     |> string_tree.to_string
//   io.println(out)
//   grid
// }

pub fn parse_grid_typed(
  input: String,
  parser: fn(String) -> Result(a, Nil),
) -> Result(Grid(a), Nil) {
  input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.index_map(fn(row, i_y) {
    list.index_map(row, fn(val, i_x) {
      parser(val) |> result.map(fn(parsed) { #(Posn(i_x, i_y), parsed) })
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
    list.index_map(row, fn(val, i_x) { #(Posn(i_x, i_y), val) })
  })
  |> list.flatten
  |> dict.from_list
}

pub fn order_grid(grid: Grid(a)) -> List(#(Posn, a)) {
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

pub fn inside(grid: Grid(a), posn: Posn) -> Bool {
  dict.has_key(grid, posn)
}
