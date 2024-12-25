import aoc
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import grid
import rememo/memo
import vector

// number pad
// +---+---+---+
// | 7 | 8 | 9 |
// +---+---+---+
// | 4 | 5 | 6 |
// +---+---+---+
// | 1 | 2 | 3 |
// +---+---+---+
//     | 0 | A |
//     +---+---+
//
pub type Keypad {
  Up
  Down
  Left
  Right
  Action
}

// pub type Keypad

fn parse(input: String) {
  let number_size = vector.Vector(3, 4)
  let skip_verti_hori = ["70", "7A", "40", "4A", "10", "1A"]
  let skip_hori_verti = ["07", "A7", "04", "A4", "01", "A1"]
  let number_pad =
    "789\n456\n123\nx0A"
    |> grid.parse_grid
  let number_vecs =
    grid.new(number_size, "")
    |> dict.drop([vector.Vector(0, 3)])
    |> dict.keys
  let number_combi =
    list.flat_map(number_vecs, fn(vec_1) {
      list.filter_map(number_vecs, fn(vec_2) {
        let assert Ok(key_1) = dict.get(number_pad, vec_1)
        let assert Ok(key_2) = dict.get(number_pad, vec_2)
        let d_x = vec_2.x - vec_1.x
        let d_y = vec_2.y - vec_1.y
        let hori = case d_x < 0 {
          True -> Left
          False -> Right
        }
        let verti = case d_y < 0 {
          True -> Up
          False -> Down
        }
        case key_1, key_2 {
          _, _ ->
            Ok(#(
              #(key_1, key_2),
              list.unique([
                case list.contains(skip_hori_verti, key_1 <> key_2) {
                  True -> []
                  False ->
                    list.flatten([
                      list.repeat(hori, int.absolute_value(d_x)),
                      list.repeat(verti, int.absolute_value(d_y)),
                      [Action],
                    ])
                },
                case list.contains(skip_verti_hori, key_1 <> key_2) {
                  True -> []
                  False ->
                    list.flatten([
                      list.repeat(verti, int.absolute_value(d_y)),
                      list.repeat(hori, int.absolute_value(d_x)),
                      [Action],
                    ])
                },
              ])
                |> list.filter(fn(x) { !list.is_empty(x) }),
            ))
        }
      })
    })
    |> dict.from_list

  // directional keypad
  //     +---+---+
  //     | ^ | A |
  // +---+---+---+
  // | < | v | > |
  // +---+---+---+
  //
  let keypad_size = vector.Vector(3, 2)
  let skip_verti_hori = [[Left, Up], [Left, Action]]
  let skip_hori_verti = [[Up, Left], [Action, Left]]
  let directional_pad =
    grid.new(keypad_size, Action)
    |> dict.insert(vector.Vector(1, 0), Up)
    |> dict.insert(vector.Vector(0, 1), Left)
    |> dict.insert(vector.Vector(1, 1), Down)
    |> dict.insert(vector.Vector(2, 0), Action)
    |> dict.insert(vector.Vector(2, 1), Right)
    |> dict.drop([vector.Vector(0, 0)])
  let pad_vecs =
    directional_pad
    |> dict.keys

  let pad_combi =
    list.flat_map(pad_vecs, fn(vec_1) {
      list.filter_map(pad_vecs, fn(vec_2) {
        let assert Ok(key_1) = dict.get(directional_pad, vec_1)
        let assert Ok(key_2) = dict.get(directional_pad, vec_2)
        let d_x = vec_2.x - vec_1.x
        let d_y = vec_2.y - vec_1.y
        let hori = case d_x < 0 {
          True -> Left
          False -> Right
        }
        let verti = case d_y < 0 {
          True -> Up
          False -> Down
        }
        Ok(#(
          #(key_1, key_2),
          list.unique([
            case list.contains(skip_hori_verti, [key_1, key_2]) {
              True -> []
              False ->
                list.flatten([
                  list.repeat(hori, int.absolute_value(d_x)),
                  list.repeat(verti, int.absolute_value(d_y)),
                  [Action],
                ])
            },
            case list.contains(skip_verti_hori, [key_1, key_2]) {
              True -> []
              False ->
                list.flatten([
                  list.repeat(verti, int.absolute_value(d_y)),
                  list.repeat(hori, int.absolute_value(d_x)),
                  [Action],
                ])
            },
          ])
            |> list.filter(fn(x) { !list.is_empty(x) }),
        ))
      })
    })
    |> dict.from_list

  let number_list =
    string.split(input, "\n")
    |> list.map(string.split(_, ""))
  #(number_list, number_combi, pad_combi)
}

pub fn pt_1(input: String) {
  let #(number_list, number_combi, pad_combi) = parse(input)
  {
    use row <- list.map(number_list)
    let assert Ok(row_value) =
      row |> list.take(3) |> string.join("") |> int.parse
    let row = ["A", ..row]
    let first_steps =
      list.window_by_2(row)
      |> list.map(dict.get(number_combi, _))
      |> list.map(aoc.unsafe_unwrap(_, "Invalid number combination"))
      |> list.fold([[]], fn(options, x) {
        use item <- list.flat_map(x)
        use option <- list.map(options)
        list.flatten([option, item])
      })

    let third_steps =
      list.range(1, 2)
      |> list.fold(first_steps, fn(steps, _) { robot_step(steps, pad_combi) })

    let assert Ok(min_seq) =
      list.map(third_steps, list.length)
      |> list.reduce(int.min)
    min_seq * row_value
  }
  |> int.sum
}

pub fn pt_2(input: String) {
  use cache <- memo.create()
  let #(number_list, number_combi, pad_combi) = parse(input)
  {
    use row <- list.map(number_list)
    let assert Ok(row_value) =
      row |> list.take(3) |> string.join("") |> int.parse
    let row = ["A", ..row]
    let first_steps =
      list.window_by_2(row)
      |> list.map(dict.get(number_combi, _))
      |> list.map(aoc.unsafe_unwrap(_, "Invalid number combination"))
      |> list.fold([[]], fn(options, x) {
        use item <- list.flat_map(x)
        use option <- list.map(options)
        list.flatten([option, item])
      })

    let twenty_5_steps =
      list.map(first_steps, fn(steps) {
        let steps = [Action, ..steps]
        list.window_by_2(steps)
        |> list.map(robot_step_cascade(_, pad_combi, 25, cache))
        |> int.sum
      })
      |> list_min

    twenty_5_steps * row_value
  }
  |> int.sum
}

fn robot_step(
  steps: List(List(Keypad)),
  pad_combi: dict.Dict(#(Keypad, Keypad), List(List(a))),
) -> List(List(a)) {
  use first_step <- list.flat_map(steps)
  let first_step = [Action, ..first_step]
  let out =
    list.window_by_2(first_step)
    |> list.map(dict.get(pad_combi, _))
    |> list.map(aoc.unsafe_unwrap(_, "Invalid pad combination"))
    |> list.fold([[]], fn(options, x) {
      use item <- list.flat_map(x)
      use option <- list.map(options)
      list.flatten([option, item])
    })

  let assert Ok(min_length) =
    list.map(out, list.length(_))
    |> list.reduce(int.min)

  out
  |> list.filter(fn(x) { list.length(x) == min_length })
}

// directional keypad
//     +---+---+
//     | ^ | A |
// +---+---+---+
// | < | v | > |
// +---+---+---+
//
// A 0         2 9 A
// A <    A    ^  A
// A v<<A >>^A <A >A
// A v<A

fn robot_step_cascade(
  step: #(Keypad, Keypad),
  pad_combi: dict.Dict(#(Keypad, Keypad), List(List(Keypad))),
  depth,
  cache,
) -> Int {
  use <- memo.memoize(cache, #(step, depth))
  use <- bool.guard(depth == 0, 1)
  {
    use list_of_next_steps <- result.map(dict.get(pad_combi, step))
    let out_list =
      list.map(list_of_next_steps, fn(next_steps) {
        let next_steps = [Action, ..next_steps]
        list.window_by_2(next_steps)
        |> list.map(robot_step_cascade(_, pad_combi, depth - 1, cache))
        |> int.sum
      })

    out_list
    |> list_min
  }
  |> aoc.unsafe_unwrap("help")
}

fn list_min(in_list: List(Int)) {
  in_list
  |> list.index_fold(0, fn(acc, x, i) {
    case i {
      0 -> x
      _ -> int.min(acc, x)
    }
  })
}
