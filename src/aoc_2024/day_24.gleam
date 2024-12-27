import aoc
import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

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

// x =  0 11001 01101 00000 01110 11010 10001 11000 10001 11001
// y =  0 11010 11110 11110 00101 00100 11000 10111 10101 01111
// z =  1 10100 01011 11110 10011 11111 01010 10000 00111 01000
// z1 = 1 01100 01100 01110 10100 00000 01010 01111 10111 01000
// -> x9 + y9 is wrong
// swap z09 and nnf
// z =  1 01100 01011 11110 10011 11111 01010 10000 00111 01000
// z2 = 1 01100 01100 01110 10100 00000 01010 10000 00111 01000
// -> x20 + y20 is wrong
// swap("z20", "nhs")
// z =  1 01100 01011 11110 10011 11111 01010 10000 00111 01000
// z3 = 1 01100 01100 01110 10011 11111 01010 10000 00111 01000
// -> z34 is wrong
// z =  1 01100 01011 11110 10011 11111 01010 10000 00111 01000
// z4 = 1 01100 01011 11110 10011 11111 01010 10000 00111 01000
//
// can't see it here but z30 is wrong, there w
// -> swap #("ddn", "kqh"),
fn op_code(op) {
  case op {
    XOR -> 0
    AND -> 1
    OR -> 2
  }
}

fn op_compare(op1, op2) {
  int.compare(op_code(op1), op_code(op2))
}

pub fn pt_2(input: String) {
  let filepath = "./src/aoc_2024/24_sorted.txt"
  let dotfile = "./src/aoc_2024/24_sorted.dot"
  let parsed_input = parse(input)
  let wire_state = parsed_input

  let assert Ok(_) =
    wire_state
    |> dict.to_list
    |> list.sort(fn(a, b) {
      case a.1, b.1 {
        Value(_), Equation(_, _, _) -> order.Lt
        Equation(_, _, _), Value(_) -> order.Gt
        Value(_), Value(_) -> string.compare(a.0, b.0)
        Equation(op1, _, _), Equation(op2, _, _) -> op_compare(op1, op2)
      }
    })
    |> list.map(string.inspect)
    |> string.join("\n")
    |> simplifile.write(to: filepath)

  let assert Ok(_) =
    wire_state
    |> dict.to_list
    |> list.map(fn(x) {
      let #(key, value) = x

      case value {
        Value(_) -> ""
        Equation(op, l, r) ->
          key
          <> "[label=\""
          <> key
          <> " "
          <> string.inspect(op)
          <> "\"];\n"
          <> r
          <> " -> "
          <> key
          <> ";\n"
          <> l
          <> " -> "
          <> key
          <> ";\n"
      }
    })
    |> list.prepend("digraph {\n")
    |> list.append(["}"])
    |> string.join("")
    |> simplifile.write(to: dotfile)

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

  let _z = x + y

  let zs =
    dict.keys(wire_state)
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)

  let swap_pairs = [
    #("z09", "nnf"),
    #("z20", "nhs"),
    #("z34", "wrc"),
    #("ddn", "kqh"),
  ]
  let wire_state =
    list.fold(swap_pairs, wire_state, fn(acc, x) { swap(acc, x.0, x.1) })

  let result =
    swap_pairs
    |> list.flat_map(fn(x) { [x.0, x.1] })
    |> list.sort(string.compare)
    |> string.join(",")

  let binary_number_as_list =
    list.map_fold(zs, wire_state, fn(state, wire) {
      do_calculation(state, wire)
      |> aoc.unsafe_unwrap("help")
    })

  let wire_res =
    binary_number_as_list
    |> pair.second
    |> list.map(int.to_string)
    |> list.reverse
    |> string.join("")

  result <> "--" <> wire_res
}

fn swap(state, key1, key2) {
  {
    use value1 <- result.try(dict.get(state, key1))
    use value2 <- result.map(dict.get(state, key2))
    state
    |> dict.insert(key1, value2)
    |> dict.insert(key2, value1)
  }
  |> result.unwrap(state)
}
