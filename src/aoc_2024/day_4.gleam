import gleam/int
import gleam/list
import matrix.{type Matrix}

pub fn pt_1(input: String) {
  let grid = matrix.parse_string_matrix(input)
  let grid_rows = grid |> list.transpose
  let diag_down = parse_diag_1(grid)
  let diag_up = parse_diag_1(grid |> list.reverse |> list.transpose)

  [grid, grid_rows, diag_down, diag_up]
  |> list.map(find_xmas)
  |> int.sum
}

fn parse_diag_1(grid: Matrix(String)) {
  let diag_down_windows_upper =
    list.index_map(grid, fn(row, i) { list.drop(row, i) })
    |> list.transpose
  let diag_down_windows_lower =
    list.index_map(grid, fn(row, i) { list.take(row, i) })
    |> list.map(list.reverse)
    |> list.transpose

  list.flatten([list.reverse(diag_down_windows_lower), diag_down_windows_upper])
}

fn find_xmas(grid: Matrix(String)) {
  grid
  |> list.map(fn(row) {
    list.window(row, 4)
    |> list.count(fn(window) {
      window == ["X", "M", "A", "S"] || window == ["S", "A", "M", "X"]
    })
  })
  |> int.sum
}

pub fn pt_2(input: String) {
  matrix.parse_string_matrix(input)
  |> list.window(3)
  |> list.map(fn(three_rows) {
    parse_diag_2(three_rows)
    |> list.count(fn(ab) { is_mas(ab.0) && is_mas(ab.1) })
  })
  |> int.sum
}

fn parse_diag_2(three_rows: Matrix(String)) {
  let diag_down =
    three_rows
    |> list.index_map(fn(row, i) { list.drop(row, i) })
    |> list.transpose

  let diag_up =
    three_rows
    |> list.reverse
    |> list.index_map(fn(row, i) { list.drop(row, i) })
    |> list.transpose
  list.zip(diag_down, diag_up)
}

fn is_mas(str: List(String)) {
  str == ["M", "A", "S"] || str == ["S", "A", "M"]
}
