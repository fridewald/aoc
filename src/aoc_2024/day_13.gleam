import aoc
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp.{Match}

fn parse(input: String) {
  let assert Ok(empty_line) = regexp.from_string("\n\n")
  let options = regexp.Options(case_insensitive: False, multi_line: True)
  let assert Ok(claw_maschine) =
    regexp.compile(
      "Button A: X\\+(\\d+), Y\\+(\\d+)\\nButton B: X\\+(\\d+), Y\\+(\\d+)\\nPrize: X=(\\d+), Y=(\\d+)",
      options,
    )
  regexp.split(empty_line, input)
  |> list.filter_map(fn(claw_def) {
    case regexp.scan(claw_maschine, claw_def) {
      [
        Match(
          content: _,
          submatches: [Some(a), Some(b), Some(c), Some(d), Some(x), Some(y)],
        ),
      ] -> {
        let a = aoc.unsafe_parse_int(a)
        let b = aoc.unsafe_parse_int(b)
        let c = aoc.unsafe_parse_int(c)
        let d = aoc.unsafe_parse_int(d)
        let x = aoc.unsafe_parse_int(x)
        let y = aoc.unsafe_parse_int(y)

        Ok(#(#(#(a, b), #(c, d)), #(x, y)))
      }
      _ -> Error(Nil)
    }
  })
}

fn find_claw_presses(input) {
  use #(#(#(a, c), #(b, d)), #(x, y)) <- list.map(input)
  let det = a * d - c * b

  case det == 0 {
    False -> {
      let a = int.to_float(a)
      let b = int.to_float(b)
      let c = int.to_float(c)
      let d = int.to_float(d)
      let x = int.to_float(x)
      let y = int.to_float(y)
      let res_y = { y -. c *. x /. a } /. { d -. c *. b /. a }
      let res_x = { x -. b *. res_y } /. a
      case
        list.all([res_x, res_y], fn(x) {
          let assert Ok(rest) = float.modulo(x, 1.0)
          let rest = float.min(1.0 -. rest, rest)
          float.loosely_equals(rest, 0.0, 5.0e-4)
        })
        && res_x >. 0.0
        && res_y >. 0.0
      {
        True -> {
          res_x *. 3.0 +. res_y
        }
        False -> {
          case
            list.all([res_x, res_y], fn(x) {
              let assert Ok(rest) = float.modulo(x, 1.0)
              let rest = float.min(1.0 -. rest, rest)
              rest <. 0.01
            })
            && res_x >. 0.0
            && res_y >. 0.0
          {
            False -> 0.0
            True -> {
              io.debug(res_x)
              io.debug(res_y)
            }
          }
          0.0
        }
      }
    }
    True -> {
      io.debug(
        "help we have not a single solution more imp would need to be done",
      )
      0.0
    }
  }
}

pub fn pt_1(input: String) {
  let par_input = parse(input)

  find_claw_presses(par_input)
  |> list.map(float.round)
  |> int.sum
}

pub fn pt_2(input: String) {
  let par_input =
    parse(input)
    |> list.map(fn(x) {
      #(x.0, #(x.1.0 + 10_000_000_000_000, x.1.1 + 10_000_000_000_000))
    })

  find_claw_presses(par_input)
  |> list.map(float.round)
  |> int.sum
}
