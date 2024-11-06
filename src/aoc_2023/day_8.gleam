import gleam/dict.{type Dict}
import gleam/io
import gleam/iterator.{cycle}
import gleam/list
import gleam/result
import gleam/string
import gleam_community/maths/arithmetics

pub type Input {
  Input(
    instruct: String,
    first_node: String,
    maps: Dict(String, #(String, String)),
  )
}

pub fn parse(input: String) -> Input {
  let line_wise = input |> string.split("\n")
  let assert Ok(instruct) = line_wise |> list.first
  let nodes =
    line_wise
    |> list.drop(2)
    |> list.map(fn(line) {
      case
        line
        |> string.replace(",", "")
        |> string.replace("(", "")
        |> string.replace(")", "")
        |> string.split(" ")
      {
        [a, _, b, c] -> #(a, b, c)
        _ -> #("", "", "")
      }
    })

  let assert Ok(first_node) = nodes |> list.first |> result.map(fn(x) { x.0 })

  let maps =
    nodes
    |> list.fold(dict.new(), fn(acc, map) {
      dict.insert(acc, map.0, #(map.1, map.2))
    })
  Input(instruct:, maps:, first_node:)
}

pub fn pt_1(input: Input) {
  let next_instruct = get_next_instruction_function(input.instruct)
  do_step("AAA", input.maps, 1, input.instruct, next_instruct)
  |> result.unwrap(0)
}

fn do_step(
  node: String,
  maps: Dict(String, #(String, String)),
  n_step: Int,
  instructs: String,
  get_next_instruction: fn(String) -> #(String, String),
) {
  let #(next_instruct, remaining_instructs) = get_next_instruction(instructs)
  use next_node <- result.try(
    dict.get(maps, node)
    |> result.map(fn(map) {
      case next_instruct {
        "L" -> map.0
        "R" -> map.1
        _ -> map.0
      }
    }),
  )
  case next_node {
    "ZZZ" -> Ok(n_step)
    _ ->
      do_step(
        next_node,
        maps,
        1 + n_step,
        remaining_instructs,
        get_next_instruction,
      )
  }
}

fn get_next_instruction_function(base_instructions: String) {
  fn(instruct_string: String) {
    case string.first(instruct_string) {
      Ok(cur_inst) -> #(cur_inst, string.drop_left(instruct_string, 1))
      Error(_) -> {
        let cur_inst = string.first(base_instructions) |> result.unwrap("")
        #(cur_inst, string.drop_left(base_instructions, 1))
      }
    }
  }
}

pub fn pt_2_brute_force_is_too_slow(input: Input) {
  let end_with_a_nodes =
    input.maps
    |> dict.keys
    |> list.filter(fn(node) {
      case node |> string.drop_left(2) {
        "A" -> True
        _ -> False
      }
    })
  io.debug(end_with_a_nodes)
  let maps = input.maps
  input.instruct
  |> string.to_graphemes
  |> iterator.from_list
  |> cycle
  |> iterator.try_fold(#(1, end_with_a_nodes), fn(acc, next_instruct) {
    let #(n_step, nodes) = acc
    let next_nodes =
      nodes
      |> list.map(fn(node) {
        let assert Ok(map) = dict.get(maps, node)
        case next_instruct {
          "L" -> map.0
          "R" -> map.1
          _ -> map.0
        }
      })
    let not_end_with_z =
      next_nodes
      |> list.filter(fn(node) { !string.ends_with(node, "Z") })
      |> list.length
    case n_step % 1_000_000 {
      0 -> {
        io.debug(0)
        io.debug(n_step)
        ""
      }
      _ -> ""
    }

    case not_end_with_z {
      0 -> Error(n_step)
      _ -> {
        Ok(#(n_step + 1, next_nodes))
      }
    }
  })
  |> result.unwrap_error(0)
}

type FindLoopAcc {
  NoZ(steps: Int, node: String)
  OneZ(steps: Int, loop_steps: Int, node: String, z_node: String)
  MultipleZ
}

pub fn pt_2(input: Input) {
  let end_with_a_nodes =
    input.maps
    |> dict.keys
    |> list.filter(fn(node) {
      case node |> string.drop_left(2) {
        "A" -> True
        _ -> False
      }
    })

  let maps = input.maps
  let instruct_length = string.length(input.instruct)
  let find_loop = fn(node_1) {
    input.instruct
    |> string.to_graphemes
    |> iterator.from_list
    |> cycle
    |> iterator.try_fold(NoZ(0, node_1), fn(acc, next_instruct) {
      let next_node_fn = fn(node) {
        let assert Ok(map) = dict.get(maps, node)
        case next_instruct {
          "L" -> map.0
          "R" -> map.1
          _ -> map.0
        }
      }
      case acc {
        NoZ(n_step, node) -> {
          let next_node = next_node_fn(node)
          Ok(case
            next_node
            |> string.ends_with("Z")
          {
            True -> OneZ(n_step + 1, 0, next_node, next_node)
            False -> NoZ(n_step + 1, next_node)
          })
        }
        OneZ(n_step, loop_steps, node, z_node) -> {
          let next_node = next_node_fn(node)
          case
            next_node
            |> string.ends_with("Z")
          {
            True -> {
              case
                // loop must be multiple of the list of instructions
                { loop_steps + 1 } % instruct_length == 0,
                // && { n_step + 1 } % instruct_length == 0,
                z_node == next_node
              {
                _, False -> Ok(MultipleZ)
                True, True -> Error(loop_steps + 1)
                False, True ->
                  Ok(OneZ(n_step + 1, loop_steps + 1, next_node, z_node))
              }
            }
            False -> Ok(OneZ(n_step + 1, loop_steps + 1, next_node, z_node))
          }
        }
        MultipleZ -> {
          panic as "we need to do some other algorithm as we found a second z in the loop"
        }
      }
    })
    |> result.unwrap_error(0)
  }

  end_with_a_nodes
  |> list.map(find_loop)
  |> list.reduce(arithmetics.lcm)
}
