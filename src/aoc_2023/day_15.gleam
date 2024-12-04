import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/string

fn parse(input: String) -> List(String) {
  input |> string.trim |> string.split(",")
}

pub fn pt_1(input: String) {
  parse(input)
  |> list.map(hash)
  |> int.sum
}

fn hash(in: String) {
  in
  |> string.to_utf_codepoints
  |> list.map(string.utf_codepoint_to_int)
  |> list.fold(0, fn(acc, x) { { { acc + x } * 17 } % 256 })
}

pub type Operation {
  Equal(label: String, focal: Int)
  Dash(label: String)
}

fn parse_2(input: String) -> List(Operation) {
  let assert Ok(re) = regexp.from_string("=|-")
  use step <- list.map(
    input
    |> string.trim
    |> string.split(","),
  )

  case regexp.split(re, step) {
    [label, ""] -> Dash(label)
    [label, focal] -> {
      let assert Ok(focal) = int.parse(focal)
      Equal(label, focal)
    }
    _ -> panic as "not supported"
  }
}

pub type Facility =
  dict.Dict(Int, Box)

pub type Box {
  Box(counter: Int, box_dict: dict.Dict(String, BoxEntity))
}

pub type BoxEntity {
  BoxEntity(focal: Int, counter: Int)
}

pub fn pt_2(input: String) {
  {
    use box_no, box <- dict.map_values(do_insertion(parse_2(input)))
    dict.to_list(box.box_dict)
    |> list.map(fn(box) { box.1 })
    |> list.sort(fn(entry1, entry2) {
      int.compare(entry1.counter, entry2.counter)
    })
    |> list.map(fn(entry) { entry.focal })
    |> list.index_map(fn(focal, index) {
      { box_no + 1 } * { index + 1 } * focal
    })
    |> int.sum
  }
  |> dict.values
  |> int.sum
}

fn do_insertion(input: List(Operation)) {
  use facility, step <- list.fold(input, dict.new())
  let box_no = hash(step.label)

  use option_box: Option(Box) <- dict.upsert(facility, box_no)
  case option_box {
    option.Some(box) -> {
      case step {
        Equal(label, focal) -> {
          let counter = box.counter + 1
          let box_dict =
            dict.upsert(box.box_dict, label, fn(found) {
              case found {
                option.Some(entry) -> BoxEntity(..entry, focal:)
                option.None -> BoxEntity(counter:, focal:)
              }
            })
          Box(counter:, box_dict:)
        }
        Dash(label) -> Box(..box, box_dict: dict.delete(box.box_dict, label))
      }
    }
    option.None -> {
      case step {
        Equal(label, focal) ->
          Box(
            counter: 1,
            box_dict: dict.new()
              |> dict.insert(label, BoxEntity(focal:, counter: 1)),
          )
        _ -> Box(counter: 0, box_dict: dict.new())
      }
    }
  }
}
