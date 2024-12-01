import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/string

type Input =
  List(#(Int, Int))

pub fn parse(input: String) -> Input {
  let assert Ok(re) = regexp.from_string(" *(\\d*) *(\\d*)")
  input
  |> string.split("\n")
  |> list.map(fn(x) {
    let res = regexp.scan(re, x)
    let assert Ok(regexp.Match(_, [Some(first), Some(second)])) =
      list.first(res)
    let assert Ok(first) = int.parse(first)
    let assert Ok(second) = int.parse(second)
    #(first, second)
  })
}

pub fn pt_1(input: Input) {
  let list1 = input |> list.map(fn(x) { x.0 }) |> list.sort(int.compare)
  let list2 = input |> list.map(fn(x) { x.1 }) |> list.sort(int.compare)

  list.zip(list1, list2)
  |> list.map(fn(x) { int.absolute_value(x.0 - x.1) })
  |> int.sum
}

pub fn pt_2(input: Input) {
  let increment = fn(x) {
    case x {
      Some(i) -> i + 1
      None -> 1
    }
  }
  // count list 2
  let count_dict =
    input
    |> list.map(fn(x) { x.1 })
    |> list.fold(dict.new(), fn(acc_dict, x) {
      dict.upsert(acc_dict, x, increment)
    })

  input
  |> list.map(fn(x) { x.0 })
  |> list.map(fn(x) {
    case dict.get(count_dict, x) {
      Ok(n) -> x * n
      Error(_) -> 0
    }
  })
  |> int.sum
}
