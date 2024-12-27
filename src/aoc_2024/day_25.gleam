import aoc
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn parse(input: String) {
  let #(looks, keys) =
    input
    |> string.split("\n\n")
    |> list.map(string.split(_, "\n"))
    |> list.map(list.map(_, fn(row) { string.split(row, "") }))
    |> list.partition(fn(g) {
      list.first(g) |> result.then(list.first) == Ok("#")
    })

  let looks_number =
    looks
    |> list.map(fn(look) {
      look
      |> list.transpose
      |> list.map(find_first_index(_, "."))
      |> list.map(aoc.unsafe_unwrap(_, "look with incorrect value"))
      |> list.map(int.subtract(_, 1))
    })
  let keys_number =
    keys
    |> list.map(fn(key) {
      key
      |> list.transpose
      |> list.map(find_first_index(_, "#"))
      |> list.map(aoc.unsafe_unwrap(_, "key with incorrect value"))
      |> list.map(int.subtract(6, _))
    })

  #(looks_number, keys_number)
}

fn find_first_index(row, value) {
  row
  |> list.index_fold(Error(Nil), fn(acc, x, i) {
    case acc, x == value {
      Error(_), True -> Ok(i)
      Ok(_) as found, _ -> found
      _, _ -> Error(Nil)
    }
  })
}

pub fn pt_1(input: String) {
  let #(looks, keys) = parse(input)
  looks
  |> list.map(fn(look) {
    keys
    |> list.filter(fn(key) {
      list.zip(look, key)
      |> list.map(fn(x) { x.0 + x.1 })
      |> list.all(fn(x) { x < 6 })
    })
  })
  |> list.flatten
  |> list.length
}

pub fn pt_2(input: String) {
  todo as "part 2 not implemented"
}
