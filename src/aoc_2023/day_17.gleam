import aoc
import dijkstra.{type Graph, End, Neighbour, Node}
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import grid
import vector

pub type Orientation {
  Horizontal
  Vertical
}

const all_oris = [Horizontal, Vertical]

fn ori_to_vector(ori: Orientation) {
  case ori {
    Horizontal -> vector.Vector(1, 0)
    Vertical -> vector.Vector(0, 1)
  }
}

fn ori_switch(ori: Orientation) {
  case ori {
    Horizontal -> Vertical
    Vertical -> Horizontal
  }
}

fn parse(input: String, step_rang: #(Int, Int)) {
  let assert Ok(map) = grid.parse_grid_typed(input, int.parse)
  let size = grid.size(map)
  let end = vector.Vector(size.0, size.1)
  let graph: Graph(#(vector.Vector, Orientation)) =
    map
    |> dict.to_list
    |> list.flat_map(fn(x) {
      let #(pos, _) = x
      all_oris
      |> list.map(fn(ori) {
        let bas_dir = ori_to_vector(ori)
        let straight_vecs =
          list.range(1, step_rang.1)
          |> list.map(fn(x) { vector.add(pos, vector.multi(bas_dir, x)) })
        let neighbours_on_below =
          get_neighbours_in_straight_line(straight_vecs, map, ori, step_rang.0)
        let straight_vecs =
          list.range(1, step_rang.1)
          |> list.map(fn(x) { vector.add(pos, vector.multi(bas_dir, -x)) })
        let neighbours_on_top =
          get_neighbours_in_straight_line(straight_vecs, map, ori, step_rang.0)
        let straight_neighbours =
          list.flatten([neighbours_on_top, neighbours_on_below])
        case pos == end {
          True -> #(#(pos, ori_switch(ori)), End)
          False -> #(
            #(pos, ori_switch(ori)),
            Node(neighbours: straight_neighbours),
          )
        }
      })
    })
    |> dict.from_list

  #(graph, end)
}

fn get_neighbours_in_straight_line(straight_vecs, map, ori, start) {
  let straight_weights_2 =
    straight_vecs
    |> list.filter_map(fn(x) { dict.get(map, x) })
    |> list.scan(0, fn(acc, x) { x + acc })
  list.zip(straight_vecs, straight_weights_2)
  |> list.map(fn(x) {
    let #(a, b) = x
    Neighbour(key: #(a, ori), weight: b)
  })
  |> list.drop(start - 1)
}

pub fn pt_1(input: String) {
  let #(graph, end) = parse(input, #(1, 3))
  apply_dijkstra(graph, end)
}

pub fn pt_2(input: String) {
  let #(graph, end) = parse(input, #(4, 10))
  apply_dijkstra(graph, end)
}

fn apply_dijkstra(graph, end) {
  let start = #(vector.Vector(-1, -1), Horizontal)
  let start_nodes = [
    Neighbour(key: #(vector.Vector(0, 0), Horizontal), weight: 0),
    Neighbour(key: #(vector.Vector(0, 0), Vertical), weight: 0),
  ]

  let graph = dict.insert(graph, start, Node(neighbours: start_nodes))

  let weights = dijkstra.dijkstra(graph, start) |> pair.first
  let h_weight = dict.get(weights, #(end, Horizontal)) |> result.unwrap(0)
  let v_weight = dict.get(weights, #(end, Vertical)) |> result.unwrap(0)

  int.min(h_weight, v_weight)
}
