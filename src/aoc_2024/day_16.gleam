import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleamy/priority_queue as pq
import grid
import tuple
import vector.{type Vector, Down, Left, Right, Up}

pub type Node {
  Node(neighbours: List(Neighbour))
  End
  Wall
}

pub type Neighbour {
  Neighbour(cursor: Cursor, weight: Int)
}

pub type Graph =
  dict.Dict(Cursor, Node)

pub type Cursor =
  #(Vector, vector.Direction)

pub type Input =
  #(Graph, grid.Grid(String), Vector, Vector)

pub fn parse(input: String) -> Input {
  let map = grid.parse_grid(input)

  let assert Ok(start) = grid.find(map, "S")
  let assert Ok(end) = grid.find(map, "E")
  let graph =
    map
    |> dict.to_list
    |> list.flat_map(fn(x) {
      let #(cur_pos, value) = x

      use cur_dir <- list.map(vector.all_directions)
      let neighbours = case value {
        "#" -> Wall
        "." | "S" ->
          {
            use next_dir <- list.filter_map(vector.all_directions)
            use <- bool.guard(is_u_turn(cur_dir, next_dir), Error(Nil))
            let pos = vector.add(cur_pos, vector.dir_to_vector(next_dir))
            let weight = calc_weight(cur_dir, next_dir)
            dict.get(map, pos)
            |> result.then(fn(v) {
              case v {
                "#" -> Error(Nil)
                "." | "S" | "E" ->
                  Ok(Neighbour(cursor: #(pos, next_dir), weight:))
                _ -> panic as "unsupported symbol"
              }
            })
          }
          |> Node(neighbours: _)
        "E" -> End
        _ -> panic as "unsupported symbol"
      }
      #(#(cur_pos, cur_dir), neighbours)
    })
    |> dict.from_list
  #(graph, map, start, end)
}

fn is_u_turn(cur_dir, next_dir) {
  case cur_dir, next_dir {
    Left, Right | Right, Left | Up, Down | Down, Up -> True
    _, _ -> False
  }
}

fn calc_weight(cur_dir, next_dir) {
  case cur_dir, next_dir {
    Left, Left | Right, Right | Up, Up | Down, Down -> 1
    _, _ -> 1001
  }
}

fn dijkstra(graph: Graph, start) {
  let #(distance, #(q_set, q_pq)) = init_dijkstra(graph, start)
  do_dijkstra(graph, distance, dict.new(), q_set, q_pq)
  |> result.unwrap_both
}

fn do_dijkstra(graph: Graph, distance, predes, q_set, q_pq) {
  // while q is not empty
  use #(#(u, u_dist), q_pq) <- result.try(
    pq.pop(q_pq) |> result.replace_error(#(distance, predes)),
  )
  // this value is already handled but still in the pq
  use <- bool.lazy_guard(!set.contains(q_set, u), fn() {
    do_dijkstra(graph, distance, predes, q_set, q_pq)
  })
  let q_set = set.drop(q_set, [u])
  let cur_predes = dict.get(predes, u) |> result.unwrap([])
  case dict.get(graph, u) {
    Error(_) -> panic as "init error: node is missing a graph"
    Ok(Wall) -> panic as "we should never reach a wall as current node"
    Ok(End) -> Ok(#(distance, predes))
    Ok(Node(neighbours:)) -> {
      // update distance
      let #(distance, predes, q_pq) =
        neighbours
        |> list.filter(fn(nei) { set.contains(q_set, nei.cursor) })
        |> list.fold(#(distance, predes, q_pq), fn(acc, nei) {
          let #(distance, predes, q_pq) = acc
          let alt = u_dist + nei.weight
          case dict.get(distance, nei.cursor) {
            Ok(cur_dist) if alt == cur_dist -> {
              let predes_from_other_path =
                dict.get(predes, nei.cursor) |> result.unwrap([])
              #(
                dict.insert(distance, nei.cursor, alt),
                predes
                  |> dict.insert(
                    nei.cursor,
                    list.flatten([[u], predes_from_other_path, cur_predes]),
                  ),
                pq.push(q_pq, #(nei.cursor, alt)),
              )
            }
            Ok(cur_dist) if alt < cur_dist -> {
              #(
                dict.insert(distance, nei.cursor, alt),
                predes |> dict.insert(nei.cursor, [u, ..cur_predes]),
                pq.push(q_pq, #(nei.cursor, alt)),
              )
            }
            Ok(_) -> acc
            Error(_) -> {
              #(
                dict.insert(distance, nei.cursor, alt),
                predes |> dict.insert(nei.cursor, [u, ..cur_predes]),
                pq.push(q_pq, #(nei.cursor, alt)),
              )
            }
          }
        })
      do_dijkstra(graph, distance, predes, q_set, q_pq)
    }
  }
}

fn init_dijkstra(
  graph: Graph,
  start: Cursor,
) -> #(dict.Dict(Cursor, Int), #(set.Set(Cursor), pq.Queue(#(Cursor, Int)))) {
  let list_of_cursors = dict.keys(graph)

  let set_of_nodes = set.from_list(list_of_cursors)

  let distance = dict.from_list([#(start, 0)])

  let pq =
    pq.from_list([#(start, 0)], fn(a, b) {
      case a.1, b.1 {
        a, b -> int.compare(a, b)
      }
    })

  #(distance, #(set_of_nodes, pq))
}

pub fn pt_1(input: Input) {
  let #(graph, map, start, end) = input

  {
    let #(distance, predes) = dijkstra(graph, #(start, Right))

    let end_dict =
      distance
      |> dict.filter(fn(key, _) { key.0 == end })

    let assert Ok(dist) = end_dict |> dict.values() |> list.first
    let end_predes =
      end_dict
      |> dict.keys()
      |> list.try_map(dict.get(predes, _))
      |> result.unwrap([])
      |> list.flatten

    list.fold(end_predes, map, fn(map, predes) {
      map |> dict.insert(predes.0, "x")
    })
    dist
  }
}

pub fn pt_2(input: Input) {
  let #(graph, _, start, end) = input

  {
    let #(distance, predes) = dijkstra(graph, #(start, Right))

    {
      distance
      |> dict.filter(fn(key, _) { key.0 == end })
      |> dict.keys()
      |> list.try_map(dict.get(predes, _))
      |> result.unwrap([])
      |> list.flatten
      |> list.map(tuple.first_2)
      |> list.unique
      |> list.length
    }
    // the start
    + 1
  }
}
