import gleam/int
import gleam/io
import gleam/list
import gleam/otp/task
import gleam/result
import gleam/string

pub opaque type Input {
  Input(seeds: List(Int), maps: List(SeedMap))
}

pub type SeedMap =
  List(#(Int, Int, Int))

fn seed_decoder(line: String) {
  case line {
    "seeds: " <> rest -> {
      rest
      |> string.trim()
      |> string.split(" ")
      |> list.map(int.parse)
      |> result.all
      |> result.replace_error("int parsing error")
    }
    _ -> Error("wrong line start")
  }
}

fn split_map(maps: List(String)) -> List(Result(SeedMap, String)) {
  case maps {
    [] -> []
    rest -> {
      let split =
        rest
        |> list.drop(1)
        |> list.split_while(fn(row) { !string.contains(row, "map:") })
      let seed_map =
        split.0
        |> list.try_map(fn(row) {
          case row |> string.split(" ") {
            [a, b, c] -> {
              use a_i <- result.try(int.parse(a))
              use b_i <- result.try(int.parse(b))
              use c_i <- result.try(int.parse(c))
              Ok(#(a_i, b_i, c_i))
            }
            _ -> Error(Nil)
          }
          |> result.replace_error("bad mapping")
        })
      [seed_map, ..split_map(split.1)]
    }
  }
}

pub fn parse(input: String) -> Input {
  let input = input |> string.split("\n") |> list.filter(fn(x) { x != "" })
  let decode_result = {
    use seeds <- result.try(
      list.first(input)
      |> result.replace_error("int parsing failed")
      |> result.then(seed_decoder(_)),
    )
    use maps <- result.try(split_map(list.drop(input, 1)) |> result.all)
    Ok(Input(seeds:, maps:))
  }

  decode_result |> result.unwrap(Input(seeds: [], maps: []))
}

fn iterate_mapping(val, rest_maps: List(SeedMap)) {
  case rest_maps {
    [] -> val
    [cur_map, ..rest] -> iterate_mapping(do_mapping(val, cur_map), rest)
  }
}

fn do_mapping(val: Int, mappings: List(#(Int, Int, Int))) {
  mappings
  |> list.find_map(fn(mapping) {
    let dest_start = mapping.0
    let source_start = mapping.1
    let range = mapping.2
    let diff_to_source_start = val - source_start
    case diff_to_source_start < range && diff_to_source_start >= 0 {
      True -> Ok(dest_start + diff_to_source_start)
      False -> Error(Nil)
    }
  })
  |> result.unwrap(val)
}

fn do_check_range(start, index, range, acc_min_soil, maps) {
  let current_seed = start + index
  case index < range {
    False -> acc_min_soil
    True ->
      do_check_range(
        start,
        index + 1,
        range,
        int.min(iterate_mapping(current_seed, maps), acc_min_soil),
        maps,
      )
  }
}

pub fn pt_1(input: Input) {
  let assert Ok(res) =
    input.seeds
    |> list.map(fn(seed) { iterate_mapping(seed, input.maps) })
    |> list.reduce(int.min)
  res
}

pub fn pt_2(input: Input) {
  let assert Ok(firstseed) = input.seeds |> list.first
  let first_soil = iterate_mapping(firstseed, input.maps)
  let assert Ok(Ok(task_output)) =
    input.seeds
    |> list.sized_chunk(2)
    |> list.map(fn(chunk) {
      task.async(fn() {
        case chunk {
          [start, range] -> {
            // io.debug("Start task")
            io.debug("Start range " <> int.to_string(start))
            let cur_soil =
              do_check_range(start, 0, range, first_soil, input.maps)
            Ok(cur_soil)
          }
          _ -> Error(Nil)
        }
      })
    })
    |> list.map(fn(ui) { task.await_forever(ui) })
    |> result.all
    |> result.map(list.reduce(_, int.min))
  task_output
}
