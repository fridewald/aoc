import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import grid

fn parse(input: String) {
  grid.parse_grid(input)
}

pub fn pt_1(input: String) {
  let map = parse(input)
  let antennas =
    map
    |> grid.print_grid
    |> dict.filter(fn(_, group) { group != "." })

  let antenna_posns = dict.keys(antennas)
  let size = grid.size(map)

  let antinodes =
    antennas
    |> dict.to_list
    |> list.group(fn(x) { x.1 })
    |> dict.to_list
    |> list.flat_map(fn(group) {
      group.1
      |> list.combination_pairs
      |> list.flat_map(fn(pair) {
        let vec_diff = grid.sub(pair.0.0, pair.1.0)
        // io.debug(pair)
        [grid.add(pair.0.0, vec_diff), grid.add(pair.1.0, grid.minus(vec_diff))]
        // |> io.debug
      })
    })
    |> list.unique
    |> io.debug
    |> list.filter(fn(anti) { grid.inside(map, anti) })
  // !list.contains(antenna_posns, anti) &&

  antinodes
  |> list.map(fn(x) { #(x, "#") })
  |> dict.from_list
  |> dict.combine(map, fn(anti, map) {
    case map {
      "." -> anti
      a -> a
    }
  })
  |> grid.print_grid_string

  antinodes
  |> list.length
}

pub fn pt_2(input: String) {
  let map = parse(input)
  let antennas =
    map
    |> grid.print_grid
    |> dict.filter(fn(_, group) { group != "." })

  let antenna_posns = dict.keys(antennas)
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
        let vec_diff = grid.sub(pair.0.0, pair.1.0)
        list.range(-max_size, max_size)
        |> list.flat_map(fn(multi) {
          let a = grid.add(pair.0.0, grid.multi(vec_diff, multi))
          case grid.inside(map, a) {
            True -> [a]
            False -> []
          }
        })
        // io.debug(pair)
        // |> io.debug
      })
    })
    |> list.unique
    |> io.debug
  // |> list.filter(fn(anti) { grid.inside(map, anti) })
  // !list.contains(antenna_posns, anti) &&

  antinodes
  |> list.map(fn(x) { #(x, "#") })
  |> dict.from_list
  |> dict.combine(map, fn(anti, map) {
    case map {
      "." -> anti
      a -> a
    }
  })
  |> grid.print_grid_string

  antinodes
  |> list.length
}
