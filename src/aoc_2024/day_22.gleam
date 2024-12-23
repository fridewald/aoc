import aoc
import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string

fn parse(input) {
  input
  |> string.split("\n")
  |> list.map(aoc.unsafe_parse_int)
}

// * 64 mix prune
// / 32 mix prune
// * 2048 mix prune
// mix -> secret = number xor secret
// prune -> secret = secret module 16777216
fn round_trip(secret: Int, depth: Int) {
  use <- bool.guard(depth == 0, secret)
  let secret = secret * 64 |> mix(secret) |> prune
  let secret = secret / 32 |> mix(secret) |> prune
  let secret = secret * 2048 |> mix(secret) |> prune
  round_trip(secret, depth - 1)
}

fn mix(number, secret) {
  int.bitwise_exclusive_or(number, secret)
}

fn prune(secret) {
  secret % 16_777_216
}

fn round_trip_counting(secret: Int, depth: Int) {
  do_round_trip_counting(secret, depth, [])
  |> list.reverse
}

fn do_round_trip_counting(secret: Int, depth: Int, out) {
  use <- bool.guard(depth == 0, [secret % 10, ..out])
  let out = [secret % 10, ..out]
  let secret = secret * 64 |> mix(secret) |> prune
  let secret = secret / 32 |> mix(secret) |> prune
  let secret = secret * 2048 |> mix(secret) |> prune
  do_round_trip_counting(secret, depth - 1, out)
}

fn changes(secrets) {
  list.window_by_2(secrets)
  |> list.map(fn(window) { window.1 - window.0 })
}

fn seq_price(changes, secrets) {
  list.zip(list.window(changes, 4), list.drop(secrets, 4))
  |> list.fold(dict.new(), fn(acc, input) {
    let #(change_seq, value) = input
    dict.upsert(acc, change_seq, fn(opt) {
      case opt {
        option.None -> value
        option.Some(x) -> x
      }
    })
  })
}

fn find_max_seq(list_of_seq_dicts) {
  list.fold(list_of_seq_dicts, dict.new(), fn(acc, x) {
    // quite slow but :shrug:
    dict.combine(acc, x, int.add)
  })
  |> dict.to_list
  |> list.fold(#([], 0), fn(acc, x) {
    case x.1 > acc.1 {
      True -> {
        x |> io.debug
      }
      False -> acc
    }
  })
}

pub fn pt_1(input: String) {
  parse(input)
  |> list.map(round_trip(_, 2000))
  |> int.sum
}

// Part 2: #([2, -1, -1, 2], 2123)
// 2123 is too low

pub fn pt_2(input: String) {
  parse(input)
  |> list.map(fn(in) {
    let secrets = round_trip_counting(in, 2000)
    let changes = changes(secrets)
    seq_price(changes, secrets)
  })
  |> find_max_seq
}
