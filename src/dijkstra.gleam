import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleamy/priority_queue as pq

pub type Node(key) {
  Node(neighbours: List(Neighbour(key)))
  End
  Wall
}

pub type Neighbour(key) {
  Neighbour(key: key, weight: Int)
}

pub type Graph(key) =
  dict.Dict(key, Node(key))

pub fn dijkstra(
  graph: Graph(key),
  start: key,
) -> #(dict.Dict(key, Int), dict.Dict(key, List(key))) {
  let #(distance, #(q_set, q_pq)) = init_dijkstra(graph, start)
  do_dijkstra(graph, distance, dict.new(), q_set, q_pq, False)
  |> result.unwrap_both
}

pub fn dijkstra_all_paths(
  graph: Graph(key),
  start: key,
) -> #(dict.Dict(key, Int), dict.Dict(key, List(key))) {
  let #(distance, #(q_set, q_pq)) = init_dijkstra(graph, start)
  do_dijkstra(graph, distance, dict.new(), q_set, q_pq, True)
  |> result.unwrap_both
}

fn do_dijkstra(
  graph: Graph(key),
  distance,
  predes,
  q_set,
  q_pq,
  all_paths: Bool,
) {
  // while q is not empty
  use #(#(u, u_dist), q_pq) <- result.try(
    pq.pop(q_pq) |> result.replace_error(#(distance, predes)),
  )
  // this value is already handled but still in the pq
  use <- bool.lazy_guard(!set.contains(q_set, u), fn() {
    do_dijkstra(graph, distance, predes, q_set, q_pq, all_paths)
  })
  let q_set = set.drop(q_set, [u])
  let cur_predes = dict.get(predes, u) |> result.unwrap([])
  case dict.get(graph, u) {
    Error(_) -> panic as "init error: node is missing a graph"
    Ok(Wall) -> panic as "we should never reach a wall as current node"
    // found the end
    Ok(End) -> Ok(#(distance, predes))
    Ok(Node(neighbours:)) -> {
      // update distance
      let #(distance, predes, q_pq) =
        neighbours
        |> list.filter(fn(nei) { set.contains(q_set, nei.key) })
        |> list.fold(#(distance, predes, q_pq), fn(acc, nei) {
          let #(distance, predes, q_pq) = acc
          let alt = u_dist + nei.weight
          case dict.get(distance, nei.key) {
            Ok(cur_dist) if alt == cur_dist && all_paths -> {
              let predes_from_other_path =
                dict.get(predes, nei.key) |> result.unwrap([])
              #(
                dict.insert(distance, nei.key, alt),
                predes
                  |> dict.insert(
                    nei.key,
                    list.flatten([[u], predes_from_other_path, cur_predes]),
                  ),
                pq.push(q_pq, #(nei.key, alt)),
              )
            }
            Ok(cur_dist) if alt < cur_dist -> {
              #(
                dict.insert(distance, nei.key, alt),
                predes |> dict.insert(nei.key, [u, ..cur_predes]),
                pq.push(q_pq, #(nei.key, alt)),
              )
            }
            Ok(_) -> acc
            Error(_) -> {
              #(
                dict.insert(distance, nei.key, alt),
                predes |> dict.insert(nei.key, [u, ..cur_predes]),
                pq.push(q_pq, #(nei.key, alt)),
              )
            }
          }
        })
      do_dijkstra(graph, distance, predes, q_set, q_pq, all_paths)
    }
  }
}

fn init_dijkstra(
  graph: Graph(key),
  start: key,
) -> #(dict.Dict(key, Int), #(set.Set(key), pq.Queue(#(key, Int)))) {
  let list_of_keys = dict.keys(graph)
  let set_of_nodes = set.from_list(list_of_keys)
  let distance = dict.from_list([#(start, 0)])
  let pq =
    pq.from_list([#(start, 0)], fn(a, b) {
      case a.1, b.1 {
        a, b -> int.compare(a, b)
      }
    })

  #(distance, #(set_of_nodes, pq))
}
