import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import grid
import tuple
import vector.{type Vector, Down, Left, Right, Up}

pub type Region {
  Region(key: String, area: Int, fences: Int)
}

pub type Region2 {
  Region2(key: String, area: Int, fences: dict.Dict(Fence, List(Int)))
}

pub type Fence {
  VerticalFence(pos: Int, dir: vector.Direction)
  HorizontalFance(pos: Int, dir: vector.Direction)
}

fn find_areas(
  pos: List(Vector),
  region: Region,
  grid: grid.Grid(String),
  update_grid: grid.Grid(String),
  regions: List(Region),
) {
  let key = region.key
  case pos, dict.to_list(update_grid) |> list.first {
    [], Error(_) -> [region, ..regions]
    [], Ok(#(next_pos, key)) -> {
      find_areas(
        [next_pos],
        Region(key: key, area: 0, fences: 0),
        grid,
        update_grid,
        [region, ..regions],
      )
    }
    [first_pos, ..pos_res], _ -> {
      let neighbours =
        grid.neighbours(update_grid, first_pos)
        |> list.filter(fn(x) { x.1 == key })
      let fences =
        4
        - {
          grid.neighbours(grid, first_pos) |> list.count(fn(x) { x.1 == key })
        }
      let update_grid = dict.delete(update_grid, first_pos)
      let update_grid =
        list.fold(neighbours, update_grid, fn(grid, nei) {
          dict.delete(grid, nei.0)
        })
      let region =
        Region(..region, area: region.area + 1, fences: region.fences + fences)
      case neighbours {
        [] -> {
          find_areas(pos_res, region, grid, update_grid, regions)
        }
        rest -> {
          find_areas(
            list.flatten([pos_res, list.map(rest, tuple.first_2)]),
            region,
            grid,
            update_grid,
            regions,
          )
        }
      }
    }
  }
}

fn find_areas_2(
  pos: List(Vector),
  region: Region2,
  grid: grid.Grid(String),
  update_grid: grid.Grid(String),
  regions: List(Region2),
) {
  // io.debug(pos)
  let key = region.key
  case pos, dict.to_list(update_grid) |> list.first {
    [], Error(_) -> [region, ..regions]
    [], Ok(#(next_pos, key)) -> {
      find_areas_2(
        [next_pos],
        Region2(key: key, area: 0, fences: dict.new()),
        grid,
        update_grid,
        [region, ..regions],
      )
    }
    [first_pos, ..pos_res], _ -> {
      let neighbours =
        grid.neighbours(update_grid, first_pos)
        |> list.filter(fn(x) { x.1 == key })
      let fences =
        list.filter_map(vector.all_directions, fn(dir) {
          let vec = vector.dir_to_vector(dir)
          let nei_pos = vector.add(first_pos, vec)
          case dict.get(grid, nei_pos), dir {
            Ok(a), dir if a != key && { dir == Left || dir == Right } -> {
              Ok(#(VerticalFence(nei_pos.x, dir), nei_pos.y))
            }
            Ok(a), dir if a != key && { dir == Up || dir == Down } -> {
              Ok(#(HorizontalFance(nei_pos.y, dir), nei_pos.x))
            }
            Error(_), dir if dir == Left || dir == Right -> {
              Ok(#(VerticalFence(nei_pos.x, dir), nei_pos.y))
            }
            Error(_), dir if dir == Up || dir == Down -> {
              Ok(#(HorizontalFance(nei_pos.y, dir), nei_pos.x))
            }
            _, _ -> Error(Nil)
          }
        })
      let update_grid = dict.delete(update_grid, first_pos)
      let update_grid =
        list.fold(neighbours, update_grid, fn(grid, nei) {
          dict.delete(grid, nei.0)
        })
      let region =
        Region2(
          ..region,
          area: region.area + 1,
          fences: list.fold(fences, region.fences, fn(acc, fence) {
            dict.upsert(acc, fence.0, fn(key) {
              case key {
                option.Some(value) -> [fence.1, ..value]
                option.None -> [fence.1]
              }
            })
          }),
        )
      case neighbours {
        [] -> {
          find_areas_2(pos_res, region, grid, update_grid, regions)
        }
        rest -> {
          find_areas_2(
            list.flatten([pos_res, list.map(rest, tuple.first_2)]),
            region,
            grid,
            update_grid,
            regions,
          )
        }
      }
    }
  }
}

fn checksum(regions: List(Region)) {
  list.map(regions, fn(x) { x.area * x.fences })
  |> int.sum
}

pub fn pt_1(input: String) {
  let grid = grid.parse_grid(input)

  let assert Ok(#(pos, key)) =
    dict.to_list(grid)
    |> list.first

  find_areas([pos], Region(key:, area: 0, fences: 0), grid, grid, [])
  |> checksum
}

fn count_fences(regions: List(Region2)) {
  list.map(regions, fn(region) {
    let n_fences =
      {
        use #(_, positions) <- list.map(
          region.fences
          |> dict.to_list,
        )
        let positions = list.sort(positions, int.compare)
        let assert [fi, ..] = positions
        positions
        |> list.fold(#(fi, 1), fn(acc, x) {
          let #(a, out) = acc
          case x - a <= 1 {
            False -> #(x, out + 1)
            True -> #(x, out)
          }
        })
        |> tuple.second_2
      }
      |> int.sum
    Region(key: region.key, area: region.area, fences: n_fences)
  })
}

pub fn pt_2(input: String) {
  let grid = grid.parse_grid(input)

  let assert Ok(#(pos, key)) =
    dict.to_list(grid)
    |> list.first

  find_areas_2(
    [pos],
    Region2(key:, area: 0, fences: dict.new()),
    grid,
    grid,
    [],
  )
  |> count_fences
  |> checksum
}
