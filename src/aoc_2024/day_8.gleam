import gleam/dict
import gleam/int
import gleam/list
import grid
import vector

fn parse(input: String) {
  grid.parse_grid(input)
}

pub fn pt_1(input: String) {
  let map = parse(input)
  let antennas =
    map
    |> dict.filter(fn(_, group) { group != "." })

  let antinodes =
    antennas
    |> dict.to_list
    |> list.group(fn(x) { x.1 })
    |> dict.to_list
    |> list.flat_map(fn(group) {
      group.1
      |> list.combination_pairs
      |> list.flat_map(fn(pair) {
        let vec_diff = vector.sub(pair.0.0, pair.1.0)
        [
          vector.add(pair.0.0, vec_diff),
          vector.add(pair.1.0, vector.minus(vec_diff)),
        ]
      })
    })
    |> list.unique
    |> list.filter(fn(anti) { grid.inside(map, anti) })

  antinodes
  |> list.map(fn(x) { #(x, "#") })
  |> dict.from_list
  |> dict.combine(map, fn(anti, map) {
    case map {
      "." -> anti
      a -> a
    }
  })

  antinodes
  |> list.length
}

pub fn pt_2(input: String) {
  let map = parse(input)
  let antennas =
    map
    |> dict.filter(fn(_, group) { group != "." })

  let size = grid.size(map)
  let max_size = int.max(size.0, size.1)

  let antinodes =
    antennas
    |> dict.to_list
    |> list.group(fn(x) { x.1 })
    |> dict.to_list
    |> list.flat_map(fn(group) {
      group.1
      |> list.combination_pairs
      |> list.flat_map(fn(pair) {
        let vec_diff = vector.sub(pair.0.0, pair.1.0)
        list.range(-max_size, max_size)
        |> list.flat_map(fn(multi) {
          let a = vector.add(pair.0.0, vector.multi(vec_diff, multi))
          case grid.inside(map, a) {
            True -> [a]
            False -> []
          }
        })
      })
    })
    |> list.unique

  antinodes
  |> list.map(fn(x) { #(x, "#") })
  |> dict.from_list
  |> dict.combine(map, fn(anti, map) {
    case map {
      "." -> anti
      a -> a
    }
  })

  antinodes
  |> list.length
}
