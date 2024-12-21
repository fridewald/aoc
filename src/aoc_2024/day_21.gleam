import aoc
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import grid
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
      // not working, way to slow and memory intensive
      list.range(1, 25)
      |> list.fold(first_steps, fn(steps, i) {
        io.debug(i)
        robot_step(steps, pad_combi) |> io.debug
      })

    let assert Ok(min_seq) =
      list.map(twenty_5_steps, list.length)
      |> list.reduce(int.min)
    min_seq * row_value
  }
  |> int.sum
}

fn robot_step(steps, pad_combi) {
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
