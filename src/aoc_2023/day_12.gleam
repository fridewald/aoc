import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/otp/task
import gleam/regex
import gleam/result
import gleam/string

pub type Input =
  List(#(String, List(Int)))

pub fn parse(input: String) -> Input {
  let assert Ok(re) = regex.from_string("[ ,]")
  input
  |> string.split("\n")
  |> list.map(regex.split(re, _))
  |> list.map(fn(line) {
    case line {
      [] -> panic as "bad input"
      [row, ..rest] -> {
        let groups =
          rest
          |> list.map(int.parse)
          |> result.all
          |> result.unwrap([])
        #(row, groups)
      }
    }
  })
}

pub fn pt_1(input: Input) {
  input
  |> list.map(fn(input) {
    task.async(fn() { find_possibilities(input.0, input.1, dict.new()) })
  })
  |> list.map(task.await_forever)
  |> list.map(fn(x) { x.0 })
  |> int.sum
}

type Cache =
  dict.Dict(#(String, List(Int)), Int)

fn find_possibilities(
  row: String,
  groups: List(Int),
  cache: Cache,
) -> #(Int, Cache) {
  // get cache if it exists
  use <- result.lazy_unwrap(
    cache
    |> dict.get(#(row, groups))
    |> result.map(fn(x) { #(x, cache) }),
  )
  // early return
  use <- bool.guard(
    when: groups |> int.sum > row |> string.replace(".", "") |> string.length
      || groups |> list.intersperse(1) |> int.sum > row |> string.length,
    return: #(0, cache),
  )
  let res = case groups {
    // we have used all groups
    [] -> {
      case row |> string.contains("#") {
        // there are still some # so this is no answer
        True -> #(0, cache)
        False -> {
          #(1, cache)
        }
      }
    }
    // setting the group to all possible start places
    [group, ..rest_group] -> {
      case row {
        // groups are not empty but we reached the end of the row
        "" -> #(0, cache)
        "." <> rest_row -> find_possibilities(rest_row, groups, cache)
        "?" <> rest_row -> {
          case can_place_group_under_cursor(row, group) {
            True -> {
              let rest_row_2 = row |> string.drop_left(group + 1)
              let pos_rest_row =
                find_possibilities(rest_row_2, rest_group, cache)
              let res2 = find_possibilities(rest_row, groups, pos_rest_row.1)
              #(res2.0 + pos_rest_row.0, dict.merge(res2.1, pos_rest_row.1))
            }
            False -> find_possibilities(rest_row, groups, cache)
          }
        }
        "#" <> _rest_row ->
          case can_place_group_under_cursor(row, group) {
            True -> {
              find_possibilities(
                row |> string.drop_left(group + 1),
                rest_group,
                cache,
              )
            }
            False -> #(0, cache)
          }
        sym -> {
          panic as "unknown symbole" <> sym
          #(0, cache)
        }
      }
    }
  }
  #(res.0, res.1 |> dict.insert(#(row, groups), res.0))
}

/// can we match a group -> only #? in window  & after window now #
fn can_place_group_under_cursor(row, group) {
  let window = row |> string.slice(0, group)
  let after_window = row |> string.slice(group, 1)

  // the window has the needed size
  window |> string.length == group
  // the window only contains # and ?
  && !{ window |> string.contains(".") }
  // after the window there is either "." or "?"
  && { after_window == "." || after_window == "?" || after_window == "" }
}

pub fn pt_2(input: Input) {
  input
  |> list.map(fn(in) {
    #(
      list.repeat(in.0, 5) |> list.intersperse("?") |> string.join(""),
      list.repeat(in.1, 5) |> list.flatten,
    )
  })
  |> list.fold(0, fn(acc, input) {
    find_possibilities(input.0, input.1, dict.new()).0 + acc
  })
}
