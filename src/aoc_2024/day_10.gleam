import aoc
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import grid
import vector

pub fn pt_1(input: String) {
  let map =
    grid.parse_grid_typed(input, int.parse)
    |> aoc.unsafe_unwrap("error")
  let trailheads = dict.filter(map, fn(_, val) { val == 0 })
  list.map(dict.to_list(trailheads), fn(trailhead) {
    get_score_of_trail(map, trailhead)
  })
  |> int.sum
}

fn get_score_of_trail(map: grid.Grid(Int), head: #(vector.Vector, Int)) -> Int {
  do_get_score_of_trail(map, set.from_list([head.0]), head.1)
}

const directions = [
  vector.Vector(1, 0),
  vector.Vector(0, 1),
  vector.Vector(-1, 0),
  vector.Vector(0, -1),
]

fn do_get_score_of_trail(
  map: grid.Grid(Int),
  heads: set.Set(vector.Vector),
  height: Int,
) -> Int {
  use <- bool.guard(height == 9, set.size(heads))
  // next heads
  {
    use head <- list.map(set.to_list(heads))
    directions
    |> list.filter_map(fn(d) {
      let s_vector = vector.add(head, d)
      case dict.get(map, s_vector) {
        Ok(s_value) if s_value == height + 1 -> Ok(s_vector)
        _ -> Error(Nil)
      }
    })
  }
  |> list.flatten
  |> set.from_list
  |> do_get_score_of_trail(map, _, height + 1)
}

pub fn pt_2(input: String) {
  let map =
    grid.parse_grid_typed(input, int.parse)
    |> aoc.unsafe_unwrap("error")
  let trailheads = dict.filter(map, fn(_, val) { val == 0 })
  list.map(dict.to_list(trailheads), fn(trailhead) {
    get_score_of_trail_2(map, trailhead)
  })
  |> int.sum
}

fn get_score_of_trail_2(map: grid.Grid(Int), head: #(vector.Vector, Int)) -> Int {
  do_get_score_of_trail_2(map, dict.from_list([#(head.0, 1)]), head.1)
}

fn do_get_score_of_trail_2(
  map: grid.Grid(Int),
  heads: dict.Dict(vector.Vector, Int),
  height: Int,
) -> Int {
  use <- bool.guard(
    height == 9,
    dict.fold(heads, 0, fn(acc, _k, count) { acc + count }),
  )
  // next heads
  {
    use #(head, count) <- list.map(dict.to_list(heads))
    directions
    |> list.filter_map(fn(d) {
      let s_vector = vector.add(head, d)
      case dict.get(map, s_vector) {
        Ok(s_value) if s_value == height + 1 -> Ok(#(s_vector, count))
        _ -> Error(Nil)
      }
    })
  }
  |> list.fold(dict.new(), fn(acc, new_heads_list) {
    let new_heads = dict.from_list(new_heads_list)
    dict.combine(acc, new_heads, fn(a, b) { a + b })
  })
  |> do_get_score_of_trail_2(map, _, height + 1)
}
