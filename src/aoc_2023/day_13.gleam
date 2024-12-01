import gleam/int
import gleam/list
import gleam/string

type Input =
  List(List(String))

pub fn parse(input: String) -> Input {
  input
  |> string.split("\n\n")
  |> list.map(string.split(_, "\n"))
}

pub fn pt_1(input: Input) {
  let row_mirror =
    {
      input
      |> list.map(fn(field) {
        field
        |> list.index_map(find_mirrors(field))
      })
      |> list.flatten
      |> int.sum
    }
    * 100
  let col_mirror =
    input
    |> transpose
    |> list.map(fn(field) {
      field
      |> list.index_map(find_mirrors(field))
    })
    |> list.flatten
    |> int.sum

  row_mirror + col_mirror
}

fn transpose(input: Input) {
  input
  |> list.map(fn(field) {
    field
    |> list.map(string.to_graphemes)
    |> list.transpose
    |> list.map(fn(graphemes) { graphemes |> string.join("") })
  })
}

fn find_mirrors(field) {
  let height = field |> list.length
  fn(_row, i) {
    let window_size = int.min(i, height - i)
    let window_1_start = i - window_size
    let window_1 = field |> list.drop(window_1_start) |> list.take(window_size)
    let window_2 =
      field
      |> list.drop(i)
      |> list.take(window_size)
      |> list.reverse
    case window_1 == window_2 {
      True -> i
      False -> 0
    }
  }
}

fn find_broken_mirrors(field) {
  let height = field |> list.length
  fn(_row, i) {
    let window_size = int.min(i, height - i)
    let window_1_start = i - window_size
    let window_1 =
      field
      |> list.drop(window_1_start)
      |> list.take(window_size)
      |> list.map(fn(x) { x |> string.to_graphemes })
    let window_2 =
      field
      |> list.drop(i)
      |> list.take(window_size)
      |> list.reverse
      |> list.map(fn(x) { x |> string.to_graphemes })

    let n_diff =
      list.zip(window_1, window_2)
      |> list.fold(0, fn(acc, two_rows) {
        acc
        + {
          list.zip(two_rows.0, two_rows.1)
          |> list.fold(0, fn(acc2, ab) {
            case ab.0 != ab.1 {
              True -> acc2 + 1
              False -> acc2
            }
          })
        }
      })

    case n_diff == 1 {
      True -> i
      False -> 0
    }
  }
}

pub fn pt_2(input: Input) {
  let row_mirror =
    {
      input
      |> list.map(fn(field) {
        field
        |> list.index_map(find_broken_mirrors(field))
      })
      |> list.flatten
      |> int.sum
    }
    * 100
  let col_mirror =
    input
    |> transpose
    |> list.map(fn(field) {
      field
      |> list.index_map(find_broken_mirrors(field))
    })
    |> list.flatten
    |> int.sum

  row_mirror + col_mirror
}
