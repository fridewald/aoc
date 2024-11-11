import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string

pub type Direction {
  North
  South
  West
  East
}

pub type Grid =
  dict.Dict(Posn, String)

pub type Input =
  #(Grid, Posn, Direction)

pub type Posn {
  Posn(x: Int, y: Int)
}

pub type IO {
  Out
  Inside
}

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
  let assert [start_pos] =
    my_simple_grid
    |> dict.filter(fn(_key, value) { value == "S" })
    |> dict.keys

  #(my_simple_grid, start_pos, determine_start(my_simple_grid, start_pos))
}

fn determine_start(grid: Grid, start: Posn) {
  case
    grid |> dict.get(Posn(..start, x: start.x - 1)),
    grid |> dict.get(Posn(..start, x: start.x + 1)),
    grid |> dict.get(Posn(..start, y: start.y - 1))
  {
    Ok("F"), _, _ | Ok("L"), _, _ | Ok("-"), _, _ -> West

    _, Ok("-"), _ | _, Ok("J"), _ | _, Ok("7"), _ -> East
    _, _, Ok("|") | _, _, Ok("F") | _, Ok("7"), _ -> North
    _, _, _ -> panic as "Grid has only single line -> no loop possible"
  }
}

pub fn pt_1(input: Input) {
  let start = input.1
  let grid = input.0
  let start_direction = input.2
  find_loop(start, grid, start_direction, 0, dict.new())
  |> result.map(fn(x) { dict.size(x.0) / 2 })
  |> result.unwrap(0)
}

fn pos_to_string(pos: Posn) {
  "{x:" <> int.to_string(pos.x) <> ", y:" <> int.to_string(pos.y) <> "}"
}

fn switch_io(in_io: IO) {
  case in_io {
    Out -> Inside
    Inside -> Out
  }
}

pub fn pt_2(input: Input) {
  let start = input.1
  let grid = input.0
  let start_direction = input.2
  io.debug("Start direction:")
  io.debug(start_direction)
  {
    use found_loop_res <- result.try(find_loop(
      start,
      grid,
      start_direction,
      0,
      dict.new(),
    ))
    // get order input
    let loop_dict = found_loop_res.0
    let norm_curvature = found_loop_res.1 / int.absolute_value(found_loop_res.1)
    io.debug("Norm curvature:")
    io.debug(norm_curvature)
    let ord_grid =
      grid
      |> dict.to_list
      |> list.sort(by: fn(pos1, pos2) {
        let y_comp = int.compare({ pos1.0 }.y, { pos2.0 }.y)
        case y_comp {
          order.Eq -> int.compare({ pos1.0 }.x, { pos2.0 }.x)
          _ -> y_comp
        }
      })
    // find start symbol
    let assert Ok(loop_end_direction) = loop_dict |> dict.get(start)
    let start_symbole = case start_direction, loop_end_direction.1 {
      East, East | West, West -> "-"
      North, North | South, South -> "|"
      East, South | North, West -> "L"
      West, South | North, East -> "J"
      West, North | South, East -> "7"
      East, North | South, West -> "F"
      _, _ -> panic as "this start seems to to be of any known type"
    }

    io.debug("Start symbol: " <> start_symbole)

    // count inside points
    ord_grid
    |> list.fold(Ok(#(0, Out)), fn(acc, grid_point) {
      use acc <- result.try(acc)
      let in_io = case grid_point.0 {
        Posn(0, _) -> Out
        _ -> acc.1
      }
      let acc = #(acc.0, in_io)
      // io.debug(grid_point)
      let grid_value = acc.0
      let next_acc = case { loop_dict |> dict.get(grid_point.0) } {
        Ok(point) -> {
          let point = case point {
            #("S", _) -> #(start_symbole, start_direction)
            p -> p
          }
          // io.debug(point)
          // we are on the loop
          // counting from left to right
          // from top to bottom
          // negative curvature:
          // for corners the is a switch in IO if the directions if after the corner vertical
          // positive curvature:
          // for corners the is a switch in IO if the directions if after the corner horizontal
          case point, norm_curvature {
            #("|", _), _ -> #(grid_value, switch_io(in_io))
            #("F", East), 1
            | #("7", South), 1
            | #("L", North), 1
            | #("J", West), 1
            -> {
              #(grid_value, switch_io(in_io))
            }
            #("F", South), -1
            | #("7", West), -1
            | #("L", East), -1
            | #("J", North), -1
            -> {
              #(grid_value, switch_io(in_io))
            }
            #("S", _), _ -> {
              todo as "how to handle S, hard code the symbol"
            }
            #("-", _), _ | _, _ -> acc
          }
        }
        _ -> {
          case in_io {
            Out -> acc
            Inside -> #(acc.0 + 1, in_io)
          }
        }
      }
      // io.debug(next_acc)
      Ok(next_acc)
    })
  }
  |> result.map(fn(x) { x.0 })
  |> result.unwrap(0)
}

type LoopGrid =
  dict.Dict(Posn, #(String, Direction))

fn find_loop(
  pos: Posn,
  grid: Grid,
  direction: Direction,
  curvature: Int,
  loop_dict: LoopGrid,
) {
  let next_pos = case direction {
    East -> Posn(..pos, x: pos.x + 1)
    North -> Posn(..pos, y: pos.y - 1)
    South -> Posn(..pos, y: pos.y + 1)
    West -> Posn(..pos, x: pos.x - 1)
  }
  use grid_val <- result.try(
    dict.get(grid, next_pos) |> result.replace_error("outside of grid"),
  )
  case grid_val {
    // found loop
    "S" ->
      Ok(#(
        loop_dict |> dict.insert(next_pos, #(grid_val, direction)),
        curvature,
      ))
    _ -> {
      use next_dir <- result.try(case grid_val {
        "F" -> {
          case direction {
            North -> Ok(#(East, 1))
            West -> Ok(#(South, -1))
            _ -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
          }
        }
        "-" ->
          case direction {
            East -> Ok(#(East, 0))
            West -> Ok(#(West, 0))
            _ -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
          }
        "J" ->
          case direction {
            South -> Ok(#(West, 1))
            East -> Ok(#(North, -1))
            _ -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
          }
        "L" ->
          case direction {
            South -> Ok(#(East, -1))
            West -> Ok(#(North, 1))
            _ -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
          }
        "." -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
        "7" ->
          case direction {
            North -> Ok(#(West, -1))
            East -> Ok(#(South, 1))
            _ ->
              Error(
                "Stuck at id " <> pos_to_string(next_pos) <> " " <> grid_val,
              )
          }
        "S" -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
        "|" ->
          case direction {
            North -> Ok(#(North, 0))
            South -> Ok(#(South, 0))
            _ -> Error("Stuck at id " <> pos_to_string(next_pos) <> grid_val)
          }
        _ -> Error("Bad Char")
      })
      find_loop(
        next_pos,
        grid,
        next_dir.0,
        curvature + next_dir.1,
        loop_dict |> dict.insert(next_pos, #(grid_val, next_dir.0)),
      )
    }
  }
}
