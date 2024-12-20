import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp.{Match}
import gleam/string
import memores.{Memo}

fn parse(input: String) {
  let assert [pieces_input, design_input] = string.split(input, "\n\n")
  let pieces = string.split(pieces_input, ", ")
  let designs = string.split(design_input, "\n")
  #(pieces, designs)
}

pub fn pt_1(input: String) {
  let #(pieces, designs) = parse(input)
  let re_string = "^(" <> string.join(pieces, "|") <> ")+$"
  let assert Ok(re) = regexp.from_string(re_string)
  list.filter(designs, regexp.check(re, _))
  |> list.length
}

pub fn pt_2(input: String) {
  let #(pieces, designs) = parse(input)
  let pieces_re =
    list.map(pieces, fn(piece) {
      let re_string = "^" <> piece <> "(\\w*)$"
      let assert Ok(re) = regexp.from_string(re_string)
      re
    })
  designs
  |> list.map(fn(des) {
    use memo <- memores.create(0)
    do_tree_regex(des, pieces_re, memo)
    |> memores.unpack
  })
  |> int.sum
}

fn do_tree_regex(rest: String, pieces: List(regexp.Regexp), memo) {
  use <- memores.memoize(memo, rest)
  use <- bool.guard(rest == "", memores.Memo(..memo, value: 1))
  list.filter_map(pieces, fn(piece) {
    case regexp.scan(piece, rest) {
      [Match(_, [Some(rest)])] -> Ok(rest)
      [Match(_, [None])] -> Ok("")
      [_, ..] -> Error(Nil)
      [] -> Error(Nil)
    }
  })
  |> list.fold(Memo(..memo, value: 0), fn(acc, rest) {
    memores.apply(do_tree_regex(rest, pieces, acc), fn(value, memo) {
      memores.Memo(..memo, value: acc.value + value)
    })
  })
}
