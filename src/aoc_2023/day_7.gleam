import aoc_2023/day_7_2
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/string

type Input =
  List(#(String, Int))

type Cards =
  dict.Dict(String, Int)

pub fn parse(input: String) -> Input {
  input
  |> string.split("\n")
  |> list.map(fn(x) {
    let assert [key, number] = string.split(x, " ")
    let assert Ok(int_number) = int.parse(number)
    #(key, int_number)
  })
}

pub fn pt_1(input: Input) {
  input
  |> list.map(fn(x) { #(x, parse_cards(x.0)) })
  |> list.sort(compare_hand)
  |> list.zip(list.range(1, list.length(input)))
  |> list.fold(0, fn(acc, x) { acc + { x.1 * x.0.0.1 } })
}

fn compare_hand(
  card_a: #(#(String, Int), Cards),
  card_b: #(#(String, Int), Cards),
) -> order.Order {
  let a = rank(card_a.1)
  let b = rank(card_b.1)

  case a == b {
    True -> {
      compare_card(card_a.0.0, card_b.0.0)
    }
    False ->
      case a < b {
        True -> order.Lt
        False -> order.Gt
      }
  }
}

fn compare_card(card_a: String, card_b: String) -> order.Order {
  let hand_a = card_a |> string.to_graphemes
  let hand_b = card_b |> string.to_graphemes
  list.zip(hand_a, hand_b)
  |> list.fold(order.Eq, fn(last_ord, two_cards) {
    case last_ord {
      order.Eq -> int.compare(rank_card(two_cards.0), rank_card(two_cards.1))
      other -> other
    }
  })
}

fn rank_card(card: String) {
  case card {
    "A" -> 14
    "K" -> 13
    "Q" -> 12
    "J" -> 11
    "T" -> 10
    "9" -> 9
    "8" -> 8
    "7" -> 7
    "6" -> 6
    "5" -> 5
    "4" -> 4
    "3" -> 3
    "2" -> 2
    // "1" -> 1
    _ -> 0
  }
}

fn rank(cards: Cards) {
  case
    is_five(cards),
    is_four(cards),
    is_full_house(cards),
    is_three(cards),
    is_two_pairs(cards),
    is_one_pairs(cards),
    is_high_card(cards)
  {
    True, _, _, _, _, _, _ -> 6
    _, True, _, _, _, _, _ -> 5
    _, _, True, _, _, _, _ -> 4
    _, _, _, True, _, _, _ -> 3
    _, _, _, _, True, _, _ -> 2
    _, _, _, _, _, True, _ -> 1
    _, _, _, _, _, _, _ -> 0
  }
}

fn increment(x) {
  case x {
    Some(i) -> i + 1
    None -> 1
  }
}

fn parse_cards(input: String) -> Cards {
  input
  |> string.to_graphemes
  |> list.fold(dict.new(), fn(dicty, char) {
    dict.upsert(dicty, char, increment)
  })
}

fn is_five(cards_dict: Cards) {
  cards_dict
  |> dict.values
  == [5]
}

fn is_four(cards_dict: dict.Dict(String, Int)) {
  cards_dict
  |> dict.values
  |> list.fold(0, int.max)
  == 4
}

fn is_full_house(cards_dict: dict.Dict(String, Int)) {
  cards_dict
  |> dict.values
  |> list.sort(by: int.compare)
  == [2, 3]
}

fn is_three(cards_dict: dict.Dict(String, Int)) {
  let three =
    cards_dict
    |> dict.values
    |> list.sort(by: int.compare)
  three == [1, 1, 3]
}

fn is_two_pairs(cards_dict: dict.Dict(String, Int)) {
  cards_dict
  |> dict.values
  |> list.sort(by: int.compare)
  == [1, 2, 2]
}

fn is_one_pairs(cards_dict: dict.Dict(String, Int)) {
  cards_dict
  |> dict.values
  |> list.sort(by: int.compare)
  == [1, 1, 1, 2]
}

fn is_high_card(cards_dict: dict.Dict(String, Int)) {
  cards_dict
  |> dict.values
  |> list.sort(by: int.compare)
  == [1, 1, 1, 1, 1]
}

pub fn pt_2(input: Input) {
  input
  |> list.map(fn(x) { #(x, parse_cards(x.0)) })
  |> list.sort(day_7_2.compare_hand)
  |> list.zip(list.range(1, list.length(input)))
  |> list.fold(0, fn(acc, x) { acc + { x.1 * x.0.0.1 } })
}
