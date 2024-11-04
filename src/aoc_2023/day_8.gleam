import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string

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
  // io.debug(next_instruct)
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
  // io.debug(next_node)
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

fn get_next_instruction_pub(instruct_string: String, base_instructions: String) {
  case string.first(instruct_string) {
    Ok(cur_inst) -> #(cur_inst, string.drop_left(instruct_string, 1))
    Error(_) -> {
      let cur_inst = string.first(base_instructions) |> result.unwrap("")
      #(cur_inst, string.drop_left(base_instructions, 1))
    }
  }
}

pub fn pt_2(input: Input) {
  // let next_instruct = get_next_instruction_function(input.instruct)
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
  do_step_2(end_with_a_nodes, input.maps, 1, input.instruct, input.instruct)
  |> result.unwrap(0)
}

fn do_step_2(
  nodes: List(String),
  maps: Dict(String, #(String, String)),
  n_step: Int,
  instructs: String,
  init_instructs: String,
) {
  let #(next_instruct, remaining_instructs) =
    get_next_instruction_pub(instructs, init_instructs)
  // io.debug(next_instruct)
  use next_nodes <- result.try(
    nodes
    |> list.map(fn(node) {
      dict.get(maps, node)
      |> result.map(fn(map) {
        case next_instruct {
          "L" -> map.0
          "R" -> map.1
          _ -> map.0
        }
      })
    })
    |> result.all,
  )
  // io.debug(next_nodes)
  let not_end_with_z =
    next_nodes
    |> list.filter(fn(node) {
      case node |> string.drop_left(2) {
        "Z" -> False
        _ -> True
      }
    })
    |> list.length

  // io.debug(not_end_with_z)

  case not_end_with_z {
    3 -> {
      io.debug(n_step)
      io.debug(next_nodes)
      io.debug(not_end_with_z)
      ""
    }
    2 -> {
      io.debug(n_step)
      io.debug(next_nodes)
      io.debug(not_end_with_z)
      ""
    }
    1 -> {
      io.debug(n_step)
      io.debug(next_nodes)
      io.debug(not_end_with_z)
      ""
    }
    _ -> ""
  }
  case not_end_with_z {
    0 -> Ok(n_step)
    _ -> {
      do_step_2(
        next_nodes,
        maps,
        1 + n_step,
        remaining_instructs,
        get_next_instruction,
      )
    }
  }
}
