// import gladvent
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string_builder

pub type Grid =
  dict.Dict(Posn, String)

pub type Posn {
  Posn(x: Int, y: Int)
}

pub fn main() {
  // gladvent.main()
  io.println("Hello from aoc!")
}

pub fn print_grid(grid: Grid) {
  let out =
    grid
    |> dict.to_list
    |> list.sort(by: fn(pos1, pos2) {
      let y_comp = int.compare({ pos1.0 }.y, { pos2.0 }.y)
      case y_comp {
        order.Eq -> int.compare({ pos1.0 }.x, { pos2.0 }.x)
        _ -> y_comp
      }
    })
    |> list.fold(string_builder.new(), fn(acc, x) {
      let acc = case { x.0 }.x == 0 && { x.0 }.y != 0 {
        True -> acc |> string_builder.append("\n")
        False -> acc
      }
      acc |> string_builder.append(x.1)
    })
    |> string_builder.to_string
  io.println(out)
}
