import aoc
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string

type Input =
  List(List(String))

pub fn parse(input: String) -> Input {
  input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
}

pub fn pt_1(input: Input) {
  input
  |> aoc.rotate_counter_clock_wise
  |> perform_tilt
  |> eval_score
}

fn eval_score(input: Input) {
  let n_rows = list.length(input)
  input
  |> list.map(fn(x) {
    x
    |> list.index_fold(0, fn(acc, curser, index) {
      case curser {
        "O" -> acc + n_rows - index
        _ -> acc
      }
    })
  })
  |> int.sum
}

pub fn pt_2(input: Input) {
  let start_north = aoc.rotate_counter_clock_wise(input)

  perform_rounds(start_north, dict.new(), 1_000_000_000)
  |> eval_score
}

fn single_round(input) {
  // io.println("=================")
  // north |> aoc.rotate_clock_wise |> debug_pretty_print

  input
  |> perform_tilt
  |> aoc.rotate_clock_wise
  // west
  |> perform_tilt
  |> aoc.rotate_clock_wise
  // south
  |> perform_tilt
  |> aoc.rotate_clock_wise
  // east
  |> perform_tilt
  |> aoc.rotate_clock_wise
}

fn perform_rounds(input: Input, cache: dict.Dict(Input, Int), iterations: Int) {
  // cache idea only after looking on other solutions
  case dict.get(cache, input), iterations {
    _, 0 -> input
    // found cycle
    Ok(iter_of_cycle_start), _ -> {
      let remaining = iterations % { iter_of_cycle_start - iterations }
      io.debug(remaining)
      list.repeat("", remaining)
      |> list.fold(input, fn(north, _) { single_round(north) })
    }
    Error(_), _ -> {
      let res_round = single_round(input)
      perform_rounds(
        res_round,
        dict.insert(cache, input, iterations),
        iterations - 1,
      )
    }
  }
}

// not fast enough without cache
// could most likeliy remove otp here again
fn perform_tilt(input: Input) {
  list.map(input, fn(x) { task.async(fn() { do_perform_tilt(x) }) })
  |> task.try_await_all(1000)
  |> result.all
  |> result.unwrap([])
}

fn do_perform_tilt(x: List(String)) {
  // perform tilting

  list.fold(x, #([], []), fn(acc, curser) {
    let #(out, dots) = acc
    case curser {
      "." -> #(out, [".", ..dots])
      "O" -> #(["O", ..out], dots)
      "#" -> #(list.flatten([["#"], dots, out]), [])
      _ -> panic as "unsupported symbol"
    }
  })
  |> fn(acc) { list.append(acc.1, acc.0) }
  |> list.reverse
}
