import aoc
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import rememo/memo

pub fn parse(input: String) -> List(Int) {
  input
  |> string.split(" ")
  |> list.map(aoc.unsafe_parse_int)
}

pub fn pt_1(input: List(Int)) {
  input
  |> blink(25)
}

fn blink(stones, times) {
  use cache <- memo.create()
  {
    use stone <- list.map(stones)
    do_blink(stone, times, cache)
  }
  |> int.sum
}

fn do_blink(stone, times, cache) {
  use <- memo.memoize(cache, #(stone, times))
  use <- bool.guard(times == 0, 1)
  {
    case do_stone(stone) {
      [a, b] -> do_blink(a, times - 1, cache) + do_blink(b, times - 1, cache)
      [a] -> do_blink(a, times - 1, cache)
      _ -> panic as "what a stone"
    }
  }
}

fn do_stone(stone) {
  let stone_digits = number_of_digits(stone)
  case stone_digits % 2 == 0 {
    True -> {
      let half = stone_digits / 2
      let assert Ok(half_card) = int.power(10, int.to_float(half))
      let half_card = float.round(half_card)
      let begining = stone / half_card
      let end = stone % half_card
      [begining, end]
    }
    False if stone == 0 -> [1]
    False -> [stone * 2024]
  }
}

fn number_of_digits(number) {
  case number {
    number if number >= 10 -> 1 + number_of_digits({ number / 10 })
    number if number < 0 -> number_of_digits(-number)
    _ -> 1
  }
}

pub fn pt_2(input: List(Int)) {
  // todo as "wow"
  input
  |> blink(75)
}
