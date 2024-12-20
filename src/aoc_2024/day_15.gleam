import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import grid
import vector

fn parse(input: String) {
  let assert [map, movements] = string.split(input, "\n\n")

  let map = grid.parse_grid(map)
  let movements =
    string.replace(movements, "\n", "")
    |> string.split("")
    |> list.map(fn(move) {
      case move {
        ">" -> vector.Right
        "<" -> vector.Left
        "^" -> vector.Up
        "v" -> vector.Down
        _ -> panic as "unsupported char"
      }
    })
  #(map, movements)
}

pub type RoboMove {
  Wall
  Free(pos: vector.Vector)
  BoxMove(pos: vector.Vector, box_pos: vector.Vector)
}

fn find_next_pos(map, pos, move: vector.Direction) {
  let next_pos = vector.add(pos, vector.dir_to_vector(move))
  case dict.get(map, next_pos) {
    Error(_) -> Wall
    Ok(field) -> {
      case field {
        "#" -> Wall
        "." -> Free(next_pos)
        "O" -> {
          case find_next_pos(map, next_pos, move) {
            Free(box_pos) -> BoxMove(pos: next_pos, box_pos:)
            BoxMove(_, box_pos) -> BoxMove(pos: next_pos, box_pos:)
            Wall -> Wall
          }
        }
        c -> panic as { "unsupported char: " <> c }
      }
    }
  }
}

fn checksum(map: grid.Grid(String)) {
  dict.to_list(map)
  |> list.map(fn(entry) {
    let #(vec, field) = entry
    case field {
      "O" | "[" -> {
        vec.y * 100 + vec.x
      }
      _ -> 0
    }
  })
  |> int.sum
}

fn expand(map) {
  {
    dict.to_list(map)
    |> list.flat_map(fn(entry) {
      let #(vec, field) = entry
      case field {
        "#" -> [
          #(vector.Vector(..vec, x: 2 * vec.x), "#"),
          #(vector.Vector(..vec, x: 2 * vec.x + 1), "#"),
        ]
        "." -> [
          #(vector.Vector(..vec, x: 2 * vec.x), "."),
          #(vector.Vector(..vec, x: 2 * vec.x + 1), "."),
        ]
        "@" -> [
          #(vector.Vector(..vec, x: 2 * vec.x), "@"),
          #(vector.Vector(..vec, x: 2 * vec.x + 1), "."),
        ]
        "O" -> [
          #(vector.Vector(..vec, x: 2 * vec.x), "["),
          #(vector.Vector(..vec, x: 2 * vec.x + 1), "]"),
        ]
        c -> panic as { "unsupported char: " <> c }
      }
    })
  }
  |> dict.from_list
}

fn move_single_box(map, robo_pos, move) {
  case find_next_pos(map, robo_pos, move) {
    Wall -> #(map, robo_pos)
    Free(pos) -> {
      let map = dict.insert(map, pos, "@")
      let map = dict.insert(map, robo_pos, ".")
      #(map, pos)
    }
    BoxMove(pos, box_pos) -> {
      let map = dict.insert(map, pos, "@")
      let map = dict.insert(map, robo_pos, ".")
      let map = dict.insert(map, box_pos, "O")
      #(map, pos)
    }
  }
}

fn move_double_horizontal(
  map: grid.Grid(String),
  pos: vector.Vector,
  move: vector.Direction,
) -> Result(
  #(grid.Grid(String), vector.Vector),
  #(grid.Grid(String), vector.Vector),
) {
  let next_pos = vector.add(pos, vector.dir_to_vector(move))
  case dict.get(map, next_pos), dict.get(map, pos) {
    // cant do nothing
    Error(_), _ -> Error(#(map, pos))
    Ok(next_field), Ok(cur_field) -> {
      case next_field {
        "#" -> Error(#(map, pos))
        "." ->
          Ok(#(
            dict.insert(map, next_pos, cur_field) |> dict.insert(pos, "."),
            next_pos,
          ))
        "[" | "]" -> {
          case move_double_horizontal(map, next_pos, move) {
            Error(_) -> Error(#(map, pos))
            Ok(fold_res) ->
              Ok(#(
                dict.insert(fold_res.0, next_pos, cur_field)
                  |> dict.insert(pos, "."),
                next_pos,
              ))
          }
        }
        c -> panic as { "unsupported char: " <> c }
      }
    }
    Ok(_), Error(_) ->
      panic as "you enter from outside the map, that's not good"
  }
}

fn move_double_vertical(
  map: grid.Grid(String),
  pos: vector.Vector,
  move: vector.Direction,
) -> Result(
  #(grid.Grid(String), vector.Vector),
  #(grid.Grid(String), vector.Vector),
) {
  let next_pos = vector.add(pos, vector.dir_to_vector(move))
  case dict.get(map, next_pos), dict.get(map, pos) {
    // cant do nothing
    Error(_), _ -> Error(#(map, pos))
    Ok(next_field), Ok(cur_field) -> {
      case next_field {
        "#" -> Error(#(map, pos))
        "." ->
          Ok(#(
            // move the current field
            dict.insert(map, next_pos, cur_field) |> dict.insert(pos, "."),
            next_pos,
          ))
        "[" as next_field | "]" as next_field -> {
          let vec_of_other_part_of_box = case next_field {
            "[" -> vector.add(next_pos, vector.dir_to_vector(vector.Right))
            "]" -> vector.add(next_pos, vector.dir_to_vector(vector.Left))
            _ ->
              panic as "should be imposible as we just checked the type of the string"
          }
          use #(map_after_move, _) <- result.try(
            move_double_vertical(map, next_pos, move)
            // ugly but hey 🤷🏽
            |> result.replace_error(#(map, pos)),
          )
          case
            move_double_vertical(map_after_move, vec_of_other_part_of_box, move)
          {
            Error(_) -> Error(#(map, pos))
            Ok(#(map, _)) ->
              Ok(#(
                // move the current field
                dict.insert(map, next_pos, cur_field)
                  |> dict.insert(vec_of_other_part_of_box, ".")
                  |> dict.insert(pos, "."),
                next_pos,
              ))
          }
        }
        c -> panic as { "unsupported char: " <> c }
      }
    }
    Ok(_), Error(_) ->
      panic as "you enter from outside the map, that's not good"
  }
}

fn move_double_box(map, robo_pos, move) {
  case move {
    vector.Left | vector.Right -> move_double_horizontal(map, robo_pos, move)
    vector.Down | vector.Up -> move_double_vertical(map, robo_pos, move)
  }
  |> result.unwrap_both
}

fn find_init_robo_pos(map) {
  let assert Ok(#(robo_pos, _)) =
    dict.to_list(map) |> list.find(fn(x) { x.1 == "@" })
  robo_pos
}

pub fn pt_1(input: String) {
  let #(init_map, movements) = parse(input)
  let robo_pos = find_init_robo_pos(init_map)

  {
    use #(map, robo_pos), move <- list.fold(movements, #(init_map, robo_pos))
    move_single_box(map, robo_pos, move)
  }
  |> pair.first
  |> checksum
}

pub fn pt_2(input: String) {
  let #(init_map, movements) = parse(input)
  let init_map = expand(init_map)
  let robo_pos = find_init_robo_pos(init_map)

  {
    use #(map, robo_pos), move <- list.fold(movements, #(init_map, robo_pos))
    let fold_res = move_double_box(map, robo_pos, move)
    fold_res
  }
  |> pair.first
  |> checksum
}
