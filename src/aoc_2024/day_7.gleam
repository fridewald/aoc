import aoc
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn parse(input: String) {
  use row <- list.map(
    input
    |> string.split("\n"),
  )
  case string.split(row, ":") {
    [res, rest] -> #(
      aoc.unsafe_parse_int(res),
      list.map(rest |> string.trim |> string.split(" "), aoc.unsafe_parse_int),
    )
    _ -> panic as "Malformed input"
  }
}

pub opaque type Operation {
  Add
  Multi
  Concat
  Noop
}

pub fn pt_1(input: String) {
  {
    use #(res, row) <- list.map(parse(input))
    let operation_comb = cal_operation_comb(list.length(row), [Add, Multi])

    case find_any_calculation(row, res, operation_comb) {
      True -> res
      False -> 0
    }
  }
  |> int.sum
}

pub fn pt_2(input: String) {
  {
    use #(res, row) <- list.map(parse(input))
    let operation_comb =
      cal_operation_comb(list.length(row), [Add, Multi, Concat])

    case find_any_calculation(row, res, operation_comb) {
      True -> res
      False -> 0
    }
  }
  |> int.sum
}

fn find_any_calculation(
  row: List(Int),
  goal: Int,
  operation_comb: List(List(Operation)),
) -> Bool {
  {
    use operation_list <- list.find_map(operation_comb)
    let assert [first, ..rest] = list.zip(row, operation_list)
    list.try_fold(rest, first, fn(acc, ab) {
      let #(value, operation) = ab
      let next_value = case operation {
        Add -> acc.0 + value
        Multi -> acc.0 * value
        Concat ->
          aoc.unsafe_parse_int(int.to_string(acc.0) <> int.to_string(value))
        _ -> acc.0
      }
      case next_value > goal {
        True -> Error(Nil)
        False -> Ok(#(next_value, Noop))
      }
    })
    |> result.then(fn(x) {
      case x.0 == goal {
        True -> Ok(Nil)
        False -> Error(Nil)
      }
    })
  }
  |> result.is_ok
}

fn cal_operation_comb(size: Int, operations: List(Operation)) {
  do_cal_operation_comb(size, [[]], operations)
}

fn do_cal_operation_comb(
  size: Int,
  out: List(List(Operation)),
  operatiors: List(Operation),
) -> List(List(Operation)) {
  case size {
    0 -> out
    a if a > 0 ->
      do_cal_operation_comb(
        a - 1,
        list.flatten(
          list.map(operatiors, fn(op) { out |> list.map(list.prepend(_, op)) }),
        ),
        operatiors,
      )
    _ -> panic
  }
}
