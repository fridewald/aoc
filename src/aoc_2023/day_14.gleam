import aoc.{type Grid}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
// type Input =
//   #(List(List(String)), Grid)

// pub fn parse(input: String) -> Input {
//   let input_i =
//     input
//     |> string.split("\n")
//     |> list.map(string.to_graphemes)
//   // let n_rows = list.length(input_i)
//   // let n_cols =
//   //   list.first(input_i) |> result.map(list.length) |> result.unwrap(0)

//   #(input_i, aoc.parse_grid(input))
// }

// pub fn pt_1(input: Input) {
//   let input = input.0
//   let n_rows = list.length(input)
//   list.transpose(input)
//   |> list.map(fn(x) {
//     x
//     |> list.scan(#(0, n_rows, index), fn(acc, curser) {
//       case curser {
//         "." -> acc
//         "O" -> #(acc.1 + acc.0, { acc.1 - 1 })
//         "#" -> #(acc.0, n_rows - index - 1)
//         _ -> panic as "unsupported symbol"
//       }
//     })
//   })
//   |> list.map(fn(x) { x.0 })
//   |> int.sum
// }

// pub fn pt_2(input: Input) {
//   // let input = input.1
//   let input_i = input.0
//   let n_rows = list.length(input_i)
//   let n_cols =
//     list.first(input_i) |> result.map(list.length) |> result.unwrap(0)

//   list.transpose(input.0)
//   |> list.map(fn(x) {
//     x
//     |> list.scan(#(n_rows, 0), fn(acc, curser) {
//       case curser {
//         "." -> #(acc.0, acc.1 + 1)
//         "O" -> #(acc.1 + acc.0, { acc.1 - 1 })
//         "#" -> #(acc.0, n_rows - index - 1)
//         _ -> panic as "unsupported symbol"
//       }
//     })
//   })
//   |> list.map(fn(x) { x.0 })
//   |> int.sum
//   // list.range(0, 1_000_000_000 - 1)
//   // list.range(0, 4)
//   // |> list.fold(input, fn(grid, _) {
//   //   // north
//   //   let grid =
//   //     list.range(n_cols)
//   //     |> list.map()
//   //   // west
//   //   //
//   //   // south
//   //   //
//   //   // east
//   //   list.transpose(input)
//   //   |> list.map(fn(x) {
//   //     x
//   //     |> list.index_fold(#(0, n_rows), fn(acc, curser, index) {
//   //       case curser {
//   //         "." -> acc
//   //         "O" -> #(acc.1 + acc.0, { acc.1 - 1 })
//   //         "#" -> #(acc.0, n_rows - index - 1)
//   //         _ -> panic as "unsupported symbol"
//   //       }
//   //     })
//   //   })
//   // })
// }
