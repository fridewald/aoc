import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp.{Match}
import gleam/result

pub type Input =
  List(Instruct)

pub type Instruct {
  Multi(a: Int, b: Int)
  Do
  Dont
}

pub fn parse(input: String) -> Input {
  let assert Ok(reg) =
    regexp.from_string("(do\\(\\)|don't\\(\\)|mul\\((\\d{1,3}),(\\d{1,3})\\))")

  regexp.scan(reg, input)
  |> list.map(fn(x) {
    let Match(content, submatches) = x
    use <- result.lazy_unwrap(case content {
      "do()" -> Ok(Do)
      "don't()" -> Ok(Dont)
      _ -> Error("")
    })
    let times =
      submatches
      |> list.filter_map(option.to_result(_, "some_error"))

    case times {
      [_, a, b] -> {
        let assert Ok(a) = int.parse(a)
        let assert Ok(b) = int.parse(b)
        Multi(a, b)
      }
      _ -> panic as "more than three match should not be possible"
    }
  })
}

pub fn pt_1(input: Input) {
  input
  |> list.filter_map(fn(x) {
    case x {
      Do | Dont -> Error(Nil)
      Multi(a, b) -> Ok(#(a, b))
    }
  })
  |> list.fold(0, fn(acc, x) { acc + x.0 * x.1 })
}

pub fn pt_2(input: Input) {
  let res =
    input
    |> list.fold(#(0, True), fn(acc, x) {
      case x {
        Do -> #(acc.0, True)
        Dont -> #(acc.0, False)
        Multi(a, b) if acc.1 -> #(acc.0 + a * b, acc.1)
        _ -> acc
      }
    })
  res.0
}
