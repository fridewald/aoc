import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import grid.{type Grid, type GridSized, type Posn, Grid}
import parallel_map

pub opaque type Dir {
  Up
  Down
  Left
  Right
}

pub fn pt_1(input: String) {
  grid.parse_grid(input)
  |> grid.print_grid
  |> loop_step
}

fn next_pos(pos: grid.Posn, dir: Dir) {
  case dir {
    Down -> grid.Posn(..pos, y: pos.y + 1)
    Up -> grid.Posn(..pos, y: pos.y - 1)
    Left -> grid.Posn(..pos, x: pos.x - 1)
    Right -> grid.Posn(..pos, x: pos.x + 1)
  }
}

fn next_dir(dir: Dir) {
  case dir {
    Down -> Left
    Up -> Right
    Left -> Up
    Right -> Down
  }
}

fn loop_step(in: Grid(String)) {
  {
    use start_curser <- result.map(
      in
      |> dict.to_list
      |> list.find(fn(point) { point.1 == "^" }),
    )
    do_loop_step(in, start_curser.0, Up, set.from_list([start_curser.0]))
  }
  |> result.unwrap(set.new())
  |> set.size
}

fn do_loop_step(
  in: Grid(String),
  curser: Posn,
  dir: Dir,
  pos_set: set.Set(Posn),
) -> set.Set(Posn) {
  let next_p = next_pos(curser, dir)

  {
    use next_value <- result.map(
      in |> dict.get(next_p) |> result.replace_error(pos_set),
    )
    case next_value {
      "#" ->
        do_loop_step(in, curser, next_dir(dir), set.insert(pos_set, curser))
      "." | "^" -> do_loop_step(in, next_p, dir, set.insert(pos_set, next_p))
      _ -> panic as "unsupported key"
    }
  }
  |> result.unwrap_both()
}

pub fn pt_2(input: String) {
  grid.parse_grid(input)
  |> loop_step_2
}

fn loop_step_2(in: Grid(String)) {
  let assert Ok(start_curser) =
    in
    |> dict.to_list
    |> list.find(fn(point) { point.1 == "^" })

  dict.keys(in)
  |> parallel_map.list_pmap(
    fn(pos) {
      let grid_with_obstical = in |> dict.insert(pos, "#")
      do_loop_step_2(grid_with_obstical, start_curser.0, Up, set.new())
    },
    parallel_map.MatchSchedulersOnline,
    1000,
  )
  |> list.map(result.unwrap(_, NoLoop(set.new())))
  |> list.count(fn(loop: Loop) { loop == Loop })
}

pub type Loop {
  NoLoop(set.Set(#(Posn, Dir)))
  Loop
}

fn do_loop_step_2(
  in: Grid(String),
  curser: Posn,
  dir: Dir,
  pos_set: set.Set(#(Posn, Dir)),
) -> Loop {
  let next_curser = next_pos(curser, dir)
  {
    use next_value <- result.map(
      in |> dict.get(next_curser) |> result.replace_error(NoLoop(pos_set)),
    )
    let #(dir, next_curser) = case next_value {
      "#" -> {
        let dir = next_dir(dir)
        #(dir, curser)
      }
      "." | "^" -> {
        #(dir, next_curser)
      }
      _ -> panic as "unsupported key"
    }
    use <- bool.guard(is_loop(pos_set, #(next_curser, dir)), Loop)
    do_loop_step_2(
      in,
      next_curser,
      dir,
      set.insert(pos_set, #(next_curser, dir)),
    )
  }
  |> result.unwrap_both()
}

fn is_loop(loop_set: set.Set(#(Posn, Dir)), next_pos: #(Posn, Dir)) {
  set.contains(loop_set, next_pos)
}
