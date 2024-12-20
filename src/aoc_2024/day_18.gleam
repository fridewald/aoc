import aoc
import dijkstra
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import grid
import vector.{type Vector}

// example
// const size = vector.Vector(7, 7)
// const bytes = 12

const size = vector.Vector(71, 71)

const bytes = 1024

fn parse(input: String) {
  string.split(input, "\n")
  |> list.map(fn(x) {
    case string.split(x, ",") |> list.map(aoc.unsafe_parse_int) {
      [x, y] -> vector.Vector(x, y)
      _ -> panic as "invalid input"
    }
  })
}

fn parse_grid(vecs, size, bytes) {
  dict.merge(
    grid.new(size, "."),
    dict.from_list(list.map(vecs, fn(x) { #(x, "#") }) |> list.take(bytes)),
  )
}

fn make_graph(grid, end) {
  grid
  |> dict.to_list
  |> list.fold(dict.new(), fn(acc, x) {
    let #(pos, value) = x
    use <- bool.guard(value == "#", dict.insert(acc, pos, dijkstra.Wall))
    use <- bool.guard(pos == end, dict.insert(acc, pos, dijkstra.End))

    dict.insert(
      acc,
      pos,
      dijkstra.Node(
        neighbours: list.filter_map(grid.neighbours(grid, pos), fn(nei) {
          case nei.1 == "." {
            True -> Ok(dijkstra.Neighbour(key: nei.0, weight: 1))
            False -> Error(Nil)
          }
        }),
      ),
    )
  })
}

pub fn pt_1(input: String) {
  let fall_vecs = parse(input)
  let end = vector.sub(size, vector.Vector(1, 1))
  let start = vector.Vector(0, 0)

  let fall_grid = parse_grid(fall_vecs, size, bytes)

  let graph: dijkstra.Graph(Vector) = make_graph(fall_grid, end)

  dijkstra.dijkstra(graph, start)
  |> pair.first
  |> dict.get(end)
  |> result.unwrap(0)
}

pub fn pt_2(input: String) {
  let fall_vecs = parse(input)
  let input_size = list.length(fall_vecs)
  let end = vector.sub(size, vector.Vector(1, 1))
  let start = vector.Vector(0, 0)

  let start_bytes = bytes
  {
    use #(bytes, _) <- list.take_while(list.zip(
      list.range(start_bytes, input_size),
      list.drop(fall_vecs, start_bytes),
    ))
    let fall_grid = parse_grid(fall_vecs, size, bytes)

    let graph: dijkstra.Graph(Vector) = make_graph(fall_grid, end)

    dijkstra.dijkstra(graph, start)
    |> pair.first
    |> dict.get(end)
    |> result.is_ok
  }
  |> list.last
  |> aoc.unsafe_unwrap("help")
  |> pair.second
  |> fn(ve) { int.to_string(ve.x) <> "," <> int.to_string(ve.y) }
}
