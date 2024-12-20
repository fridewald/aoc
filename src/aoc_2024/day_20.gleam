import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import grid
import vector

fn parse(input: String) {
  let map = grid.parse_grid(input)
  let assert [start] =
    dict.to_list(map)
    |> list.filter(fn(x) { x.1 == "S" })
    |> list.map(pair.first)
  let assert [end] =
    dict.to_list(map)
    |> list.filter(fn(x) { x.1 == "E" })
    |> list.map(pair.first)

  let graph =
    dict.map_values(map, fn(key, _) {
      grid.neighbours(map, key)
      |> list.filter_map(fn(x) {
        case x.1 == "." || x.1 == "S" || x.1 == "E" {
          True -> Ok(x.0)
          False -> Error(Nil)
        }
      })
    })

  #(map, graph, start, end)
}

type Graph(key) =
  dict.Dict(key, List(key))

fn bfs(graph: Graph(key), start: key, end: key) {
  do_bfs(graph, start, end, [], set.new())
}

fn do_bfs(
  graph: Graph(key),
  v: key,
  end: key,
  backtrack: List(key),
  visited: set.Set(key),
) {
  let backtrack = [v, ..backtrack]
  let visited = set.insert(visited, v)
  use <- bool.guard(v == end, Ok(backtrack))
  use list_w <- result.try(dict.get(graph, v))
  use w <- list.find_map(list_w)
  use <- bool.guard(set.contains(visited, w), Error(Nil))
  do_bfs(graph, w, end, backtrack, visited)
}

const cheat_vecs = [
  vector.Vector(1, 1),
  vector.Vector(2, 0),
  vector.Vector(1, -1),
  vector.Vector(0, -2),
  vector.Vector(-1, -1),
  vector.Vector(-2, 0),
  vector.Vector(-1, 1),
  vector.Vector(0, 2),
]

fn find_cheat(node, backtrack_dict, cheat_vecs) {
  use cheat_vec <- list.filter_map(cheat_vecs)
  let cheat = vector.add(node, cheat_vec)
  use node_pos <- result.try(dict.get(backtrack_dict, node))
  use back_pos <- result.try(dict.get(backtrack_dict, cheat))
  let steps =
    int.absolute_value(node.x - cheat.x) + int.absolute_value(node.y - cheat.y)
  case back_pos - node_pos {
    dif if dif > steps -> {
      Ok(dif - steps)
    }
    _ -> Error(Nil)
  }
}

pub fn pt_1(input: String) {
  let #(_, graph, start, end) = parse(input)
  let backtrack =
    bfs(graph, start, end)
    |> result.unwrap([])
  let backtrack_dict =
    dict.from_list(
      list.reverse(backtrack)
      |> list.index_map(fn(x, i) { #(x, i) }),
    )

  list.flat_map(backtrack, find_cheat(_, backtrack_dict, cheat_vecs))
  |> list.filter(fn(x) { x >= 100 })
  |> list.length
}

pub fn pt_2(input: String) {
  let #(_, graph, start, end) = parse(input)
  let backtrack =
    bfs(graph, start, end)
    |> result.unwrap([])

  let cheat_vecs =
    list.range(-20, 20)
    |> list.flat_map(fn(x) {
      list.range(-20 + int.absolute_value(x), 20 - int.absolute_value(x))
      |> list.map(fn(y) { vector.Vector(x, y) })
    })
    |> list.unique
  let backtrack_dict =
    dict.from_list(
      list.reverse(backtrack)
      |> list.index_map(fn(x, i) { #(x, i) }),
    )

  list.flat_map(backtrack, find_cheat(_, backtrack_dict, cheat_vecs))
  |> list.filter(fn(x) { x >= 100 })
  |> list.length
}
