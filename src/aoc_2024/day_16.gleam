import dijkstra.{type Graph, End, Neighbour, Node, Wall}
import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import grid
import tuple
import vector.{type Vector, Down, Left, Right, Up}

pub type Cursor =
  #(Vector, vector.Direction)

pub type Input =
  #(Graph(Cursor), grid.Grid(String), Vector, Vector)

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
                "." | "S" | "E" -> Ok(Neighbour(key: #(pos, next_dir), weight:))
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

pub fn pt_1(input: Input) {
  let #(graph, map, start, end) = input

  {
    let #(distance, predes) = dijkstra.dijkstra(graph, #(start, Right))

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
    let #(distance, predes) =
      dijkstra.dijkstra_all_paths(graph, #(start, Right))

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
