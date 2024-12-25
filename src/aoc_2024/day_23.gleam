import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/set
import gleam/string

fn parse(input: String) {
  let edges_list =
    input
    |> string.split("\n")
    |> list.map(string.split(_, "-"))
    |> list.map(fn(x) {
      let assert [a, b] = x
      #(a, b)
    })

  let connected_nodes =
    list.fold(edges_list, dict.new(), fn(acc, x) {
      dict.upsert(acc, x.0, fn(op) {
        case op {
          None -> set.from_list([x.1, x.0])
          Some(v) -> set.insert(v, x.1) |> set.insert(x.0)
        }
      })
      |> dict.upsert(x.1, fn(op) {
        case op {
          None -> set.from_list([x.0, x.1])
          Some(v) -> set.insert(v, x.0) |> set.insert(x.1)
        }
      })
    })
  #(edges_list, connected_nodes)
}

pub fn pt_1(input: String) {
  let #(p_input, dict_set) = parse(input)
  list.filter(p_input, fn(x) {
    case x.1, x.0 {
      "t" <> _, _ -> True
      _, "t" <> _ -> True
      _, _ -> False
    }
  })
  |> list.fold(set.new(), fn(acc, x) {
    let #(a, b) = x
    let assert Ok(a_set) = dict.get(dict_set, a)
    let assert Ok(b_set) = dict.get(dict_set, b)
    let out_list =
      set.intersection(a_set, b_set)
      |> set.delete(a)
      |> set.delete(b)
      |> set.to_list

    case out_list {
      [] -> acc
      _ -> {
        list.fold(out_list, acc, fn(acc1, x) {
          set.from_list([a, b])
          |> set.insert(x)
          |> set.insert(acc1, _)
        })
      }
    }
  })
  |> set.size
}

pub fn pt_2(input: String) {
  let #(_, connected_nodes) = parse(input)
  connected_nodes
  |> dict.to_list
  |> list.fold([], fn(acc, x) {
    let #(key, set_of_connected_nodes) = x

    let added_to_clusters =
      acc
      |> list.flat_map(fn(cluster) {
        case set.is_subset(cluster, set_of_connected_nodes) {
          True -> [cluster, set.insert(cluster, key)]
          False -> [cluster]
        }
      })

    [set.from_list([key]), ..added_to_clusters]
  })
  |> list.map(fn(x) { #(set.size(x), x) })
  |> list.fold(#(0, ""), fn(acc, x) {
    case x.0 > acc.0 {
      True -> #(
        x.0,
        x.1 |> set.to_list |> list.sort(string.compare) |> string.join(","),
      )
      False -> acc
    }
  })
  |> pair.second
}
