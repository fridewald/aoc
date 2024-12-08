import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import grid
import parallel_map
import vector.{type Vector, Vector}

pub type Direction {
  Right
  Left
  Up
  Down
}

pub type Beam =
  #(Direction, Vector)

type Cache =
  set.Set(Beam)

pub fn pt_1(input: String) {
  let map =
    input
    |> grid.parse_grid

  let start_beam = #(Right, Vector(0, 0))
  beam_loop([start_beam], map, set.new() |> set.insert(start_beam))
  |> set.to_list
  |> list.map(fn(x) { x.1 })
  |> list.unique
  |> list.length
}

const v_x = Vector(x: 1, y: 0)

const v_y = Vector(x: 0, y: 1)

fn go_one_step(vec: Vector, dir: Direction) {
  case dir {
    Down -> vector.add(vec, v_y)
    Up -> vector.sub(vec, v_y)
    Left -> vector.sub(vec, v_x)
    Right -> vector.add(vec, v_x)
  }
}

fn beam_loop(beams: List(Beam), map: grid.Grid(String), cache: Cache) -> Cache {
  let next_beams =
    list.flat_map(beams, fn(beam) {
      let dir = beam.0
      let next_pos = go_one_step(beam.1, dir)
      // we are outside of the map ->  no new beams
      let next_field_res = dict.get(map, next_pos) |> result.replace_error([])
      {
        use next_field <- result.map(next_field_res)
        case next_field, dir {
          ".", _ | "-", Left | "-", Right | "|", Up | "|", Down -> [
            #(dir, next_pos),
          ]
          "-", Up | "-", Down -> [#(Left, next_pos), #(Right, next_pos)]
          "|", Left | "|", Right -> [#(Up, next_pos), #(Down, next_pos)]
          "/", Left | "\\", Right -> [#(Down, next_pos)]
          "/", Right | "\\", Left -> [#(Up, next_pos)]
          "/", Down | "\\", Up -> [#(Left, next_pos)]
          "/", Up | "\\", Down -> [#(Right, next_pos)]
          _, _ -> panic as "Unkown symbol"
        }
      }
      |> result.unwrap_both
    })
    // remove beams in cache
    |> list.filter(fn(x) { !set.contains(cache, x) })

  let cache = set.union(cache, set.from_list(next_beams))
  // check again if we have any new beams
  case next_beams {
    [] -> cache
    _ -> beam_loop(next_beams, map, cache)
  }
}

pub fn pt_2(input: String) {
  let map =
    input
    |> grid.parse_grid
  let size = grid.size(map)
  map
  |> dict.keys
  |> list.filter(fn(x) {
    x.x == 0 || x.y == 0 || x.x == size.0 || x.y == size.1
  })
  |> parallel_map.list_pmap(
    fn(start_vec) {
      let start_beam = case start_vec {
        Vector(0, _) -> #(Right, start_vec)
        Vector(x, _) if x == size.0 -> #(Left, start_vec)
        Vector(_, 0) -> #(Down, start_vec)
        Vector(_, y) if y == size.1 -> #(Up, start_vec)
        _ -> panic as "no good start"
      }
      beam_loop([start_beam], map, set.new() |> set.insert(start_beam))
      |> set.to_list
      |> list.map(fn(x) { x.1 })
      |> list.unique
      |> list.length
    },
    parallel_map.MatchSchedulersOnline,
    3000,
  )
  |> result.all
  |> result.unwrap([])
  |> list.fold(0, int.max)
}
