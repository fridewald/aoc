import aoc
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/regexp
import gleam/string
import grid
import vector

// const size_x = 11
// const size_y = 7
const size_x = 101

const size_y = 103

fn parse(input: String) -> List(#(vector.Vector, vector.Vector)) {
  let assert Ok(line) =
    regexp.from_string(
      "p=([\\-]?\\d+),([\\-]?\\d+) v=([\\-]?\\d+),([\\-]?\\d+)",
    )
  input
  |> string.split("\n")
  |> list.map(fn(in) {
    let assert [regexp.Match(content: _, submatches: submatches)] =
      regexp.scan(with: line, content: in)
    let assert Some(submatches) = option.all(submatches)
    let assert [x, y, v_x, v_y] = list.map(submatches, aoc.unsafe_parse_int)
    #(vector.Vector(x, y), vector.Vector(v_x, v_y))
  })
}

pub type Quadrants {
  Quadrants(tl: Int, tr: Int, bl: Int, br: Int)
}

pub fn pt_1(input: String) {
  let n_steps = 100
  let mid_x = { size_x } / 2
  let mid_y = { size_y } / 2

  let size = vector.Vector(size_x, size_y)
  parse(input)
  |> list.map(do_steps(_, size, n_steps))
  |> list.fold(Quadrants(0, 0, 0, 0), fn(acc, robot) {
    case robot {
      vector.Vector(x, y) if x < mid_x && y < mid_y ->
        Quadrants(..acc, tl: acc.tl + 1)
      vector.Vector(x, y) if x < mid_x && y > mid_y ->
        Quadrants(..acc, bl: acc.bl + 1)
      vector.Vector(x, y) if x > mid_x && y < mid_y ->
        Quadrants(..acc, tr: acc.tr + 1)
      vector.Vector(x, y) if x > mid_x && y > mid_y ->
        Quadrants(..acc, br: acc.br + 1)
      _ -> acc
    }
  })
  |> fn(qua) { qua.tl * qua.tr * qua.bl * qua.br }
}

fn do_steps(robot, size: vector.Vector, n_steps) {
  let #(x, v) = robot
  let result_v = vector.add(x, vector.multi(v, n_steps))
  vector.Vector(result_v.x % size.x, result_v.y % size.y)
  |> vector.add(size)
  |> fn(result_v) { vector.Vector(result_v.x % size.x, result_v.y % size.y) }
}

pub fn pt_2(input: String) {
  let size = vector.Vector(size_x, size_y)
  let field = grid.new(size, ".")
  let robots =
    parse(input)
    |> list.map(pair.first)

  show_robots(field, robots)

  list.range(1, 100_000)
  |> list.map_fold(parse(input), fn(input, x) {
    io.println(string.repeat("#", size_x))
    io.println(int.to_string(x))
    let speed = input |> list.map(pair.second)
    let step_on =
      input
      |> list.map(do_steps(_, size, 1))
    show_robots(field, step_on)
    #(list.zip(step_on, speed), x)
  })
  ""
}

fn show_robots(field, robots) {
  list.fold(robots, field, fn(acc, robot) { dict.insert(acc, robot, "x") })
  |> grid.print_grid_string
}
