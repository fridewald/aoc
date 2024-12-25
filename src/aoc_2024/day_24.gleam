import aoc
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

pub type Operation {
  XOR
  OR
  AND
}

pub type Wire {
  Value(value: Int)
  Equation(operation: Operation, left: String, right: String)
}

fn parse(input: String) {
  let assert [start_state, wires] = string.split(input, "\n\n")
  let start_state =
    start_state
    |> string.split("\n")
    |> list.map(string.split(_, ": "))
    |> list.map(fn(x) {
      let assert [key, value] = x
      #(key, Value(aoc.unsafe_parse_int(value)))
    })
    |> dict.from_list

  let wires =
    wires
    |> string.split("\n")
    |> list.map(string.split(_, " "))
    |> list.map(fn(x) {
      let assert [a, op, b, _, c] = x
      let op = case op {
        "AND" -> AND
        "OR" -> OR
        "XOR" -> XOR
        _ -> panic as "unknown operation"
      }
      #(c, Equation(op, a, b))
    })
    |> dict.from_list

  dict.merge(start_state, wires)
}

fn do_calculation(wire_state, key) {
  use wire <- result.try(dict.get(wire_state, key))
  case wire {
    Value(v) -> Ok(#(wire_state, v))
    Equation(op, a, b) -> {
      use #(wire_state_a, a) <- result.try(do_calculation(wire_state, a))
      use #(wire_state_b, b) <- result.map(do_calculation(wire_state, b))
      let wire_state =
        dict.combine(wire_state_a, wire_state_b, fn(a, b) {
          case a, b {
            Value(a), _ -> Value(a)
            _, Value(b) -> Value(b)
            _, _ -> a
          }
        })
      let result = case op {
        XOR -> int.bitwise_exclusive_or(a, b)
        OR -> int.bitwise_or(a, b)
        AND -> int.bitwise_and(a, b)
      }
      #(wire_state, result)
    }
  }
}

pub fn pt_1(input: String) {
  let wire_state = parse(input)
  let zs =
    dict.keys(wire_state)
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)

  let binary_number_as_list =
    list.map_fold(zs, wire_state, fn(state, wire) {
      do_calculation(state, wire)
      |> aoc.unsafe_unwrap("help")
    })

  binary_number_as_list
  |> pair.second
  |> list.map(int.to_string)
  |> list.reverse
  |> string.join("")
  |> int.base_parse(2)
  |> aoc.unsafe_unwrap("help 2")
}

// z = 0b1011000101111110100111111101010100000011101000

pub fn pt_2(input: String) {
  let parsed_input = parse(input)
  let pa_list = dict.to_list(parsed_input)
  let x =
    pa_list
    |> list.filter(fn(x) { string.starts_with(x.0, "x") })
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.reverse
    |> list.map(fn(x) {
      case pair.second(x) {
        Value(v) -> int.to_string(v)
        _ -> panic as "can't handle equations here"
      }
    })
    |> string.join("")
    |> int.base_parse(2)
    |> aoc.unsafe_unwrap("help x")
    |> io.debug

  let y =
    pa_list
    |> list.filter(fn(x) { string.starts_with(x.0, "y") })
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.reverse
    |> list.map(fn(x) {
      case pair.second(x) {
        Value(v) -> int.to_string(v)
        _ -> panic as "can't handle equations here"
      }
    })
    |> string.join("")
    |> int.base_parse(2)
    |> aoc.unsafe_unwrap("help y")
    |> io.debug

  let z = x + y

  z |> int.to_base2
}
