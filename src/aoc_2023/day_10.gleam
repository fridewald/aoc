import gleam/bit_array
import gleam/dict
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{None, Some}
import gleam/queue
import gleam/result
import gleam/string

pub type Grid {
  Nod(id: Int)
  // Start(id: Int, south: Grid, west: Grid, north: Grid, east: Grid)
  Start(id: Int, grid1: #(Grid, Direction), grid2: #(Grid, Direction))
  Seven(id: Int, south: Grid, west: Grid)
  F(id: Int, south: Grid, east: Grid)
  L(id: Int, north: Grid, east: Grid)
  J(id: Int, north: Grid, west: Grid)
  VPipe(id: Int, north: Grid, south: Grid)
  HPipe(id: Int, west: Grid, east: Grid)
}

type Fun {
  Fun(fun: fn() -> Fun)
}

pub type Direction {
  North
  South
  West
  East
}

type GridSimple =
  dict.Dict(Posn, String)

type Posn {
  Posn(x: Int, y: Int)
}

fn wow() {
  iterator.cycle
  let te = Fun(None)
  let te = Fun(Some(te))
  io.debug(te)
}

fn do_zip_3(
  one: List(a),
  other: List(b),
  nother: List(b),
  acc: List(#(a, b, b)),
) -> List(#(a, b, b)) {
  case one, other, nother {
    [first_one, ..rest_one],
      [first_other, ..rest_other],
      [first_nother, ..rest_nother]
    ->
      do_zip_3(rest_one, rest_other, rest_nother, [
        #(first_one, first_other, first_nother),
        ..acc
      ])
    _, _, _ -> list.reverse(acc)
  }
}

pub fn zip_3(list: List(a), other: List(b), nother: List(b)) -> List(#(a, b, b)) {
  do_zip_3(list, other, nother, [])
}

pub fn parse(input: String) -> Grid {
  let my_map = dict.new()
  let my_queue = queue.new()
  let my_vec = <<1>>

  let rows =
    input
    |> string.split("\n")
    |> list.map(fn(x) {
      string.to_graphemes(x)
      |> list.map(fn(y) { option.Some(y) })
      |> list.append([None])
      |> list.prepend(None)
    })
  let length_row = rows |> list.first |> result.unwrap([]) |> list.length
  let outer_none = list.repeat(option.None, times: length_row)
  [outer_none, ..rows]
  |> list.append([outer_none])
  |> list.window(3)
  |> list.map(fn(x) {
    let assert [before, cur, next] = x
    let work = zip_3(before, cur, next)
  })
  wow()
  Start(0, #(Seven(1, south: Nod(2), west: Nod(3)), North), #(Nod(2), North))
}

pub fn pt_1(input: Grid) {
  let assert Start(_, grid1, grid2) = input
  do_step(0, grid1, grid2)
  |> result.map(fn(x) { x.0 })
  |> result.unwrap(Nod(0))
}

fn do_step(count: Int, grid1: #(Grid, Direction), grid2: #(Grid, Direction)) {
  case { grid1.0 }.id == { grid2.0 }.id {
    True -> Ok(grid1)
    False -> {
      let griddy = fn(grid: Grid, direction: Direction) {
        case grid {
          F(_, south, east) -> {
            case direction {
              North -> Ok(#(east, East))
              West -> Ok(#(south, South))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
          }
          HPipe(_, west, east) ->
            case direction {
              East -> Ok(#(east, East))
              West -> Ok(#(west, West))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
          J(_, north, west) ->
            case direction {
              South -> Ok(#(west, West))
              West -> Ok(#(north, North))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
          L(_, north, east) ->
            case direction {
              South -> Ok(#(east, East))
              West -> Ok(#(north, North))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
          Nod(_) -> Error("Stuck at id " <> int.to_string(grid.id))
          Seven(_, south, west) ->
            case direction {
              North -> Ok(#(west, West))
              East -> Ok(#(south, South))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
          Start(_, _, _) -> Error("Stuck at id " <> int.to_string(grid.id))
          VPipe(_, north, south) ->
            case direction {
              North -> Ok(#(north, North))
              South -> Ok(#(south, South))
              _ -> Error("Stuck at id " <> int.to_string(grid.id))
            }
        }
      }
      use next_grid1 <- result.try(griddy(grid1.0, grid1.1))
      use next_grid2 <- result.try(griddy(grid2.0, grid2.1))
      do_step(count + 1, next_grid1, next_grid2)
    }
  }
}

pub fn pt_2(input: Grid) {
  todo as "part 2 not implemented"
}
