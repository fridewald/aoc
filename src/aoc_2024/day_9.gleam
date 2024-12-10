import aoc
import gleam/bool
import gleam/deque
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

fn parse(in: String) {
  in
  |> string.split("")
  |> list.map(aoc.unsafe_parse_int)
  |> deque.from_list
}

pub fn pt_1(input: String) {
  let forward = parse(input)
  add_files_loop(forward)
  |> list.index_map(fn(x, i) { x * i })
  |> int.sum
}

fn add_files_loop(in_list: deque.Deque(Int)) {
  let end_index = { deque.length(in_list) - 1 } / 2
  let assert Ok(#(current_end_file, queue)) =
    case deque.length(in_list) % 2 == 0 {
      False -> deque.pop_back(in_list)
      True -> {
        // pop some space
        use #(_, queue) <- result.try(deque.pop_back(in_list))
        deque.pop_back(queue)
      }
    }
    |> result.map(fn(x) { #(list.repeat(end_index, x.0), x.1) })
  do_add_files_loop(queue, current_end_file, 0, end_index, [])
}

fn do_add_files_loop(
  queue: deque.Deque(Int),
  current_end_file: List(Int),
  file_index: Int,
  end_index: Int,
  out_list: List(Int),
) {
  use <- bool.guard(
    file_index == end_index,
    list.flatten([out_list, current_end_file]),
  )
  {
    use #(file, queue) <- result.try(
      deque.pop_front(queue) |> result.replace_error(out_list),
    )

    // add front file
    let out_list =
      list.flatten([out_list, list.repeat(file_index, times: file)])

    use #(space, queue) <- result.map(
      deque.pop_front(queue) |> result.replace_error(out_list),
    )
    case get_n_end_files(queue, current_end_file, end_index, space) {
      Ok(#(n_end, c_end, end_index, queue)) -> {
        let out_list = list.flatten([out_list, n_end])
        do_add_files_loop(queue, c_end, file_index + 1, end_index, out_list)
      }
      Error(n_end) -> {
        list.flatten([out_list, n_end])
      }
    }
  }
  |> result.unwrap_both
}

fn get_n_end_files(
  queue: deque.Deque(Int),
  current_end_file: List(Int),
  end_index: Int,
  size: Int,
) -> Result(#(List(Int), List(Int), Int, deque.Deque(Int)), List(Int)) {
  let current_end_file_size = list.length(current_end_file)
  case current_end_file_size >= size {
    True ->
      Ok(#(
        list.take(current_end_file, size),
        list.drop(current_end_file, size),
        end_index,
        queue,
      ))
    False -> {
      // pop some space
      use #(_, queue) <- result.try(
        deque.pop_back(queue) |> result.replace_error(current_end_file),
      )
      // get next file
      use #(end_file_size, rest) <- result.try(
        deque.pop_back(queue) |> result.replace_error(current_end_file),
      )
      get_n_end_files(
        rest,
        list.flatten([
          current_end_file,
          list.repeat(end_index - 1, end_file_size),
        ]),
        end_index - 1,
        size,
      )
    }
  }
}

pub fn pt_2(input: String) {
  todo as "not working currently"
  let queue =
    parse_2(input)
    |> io.debug
  add_files_loop_2(queue)
  |> io.debug
  |> list.index_map(fn(x, i) { x * i })
  |> int.sum
}

fn parse_2(in: String) {
  in
  |> string.split("")
  |> list.map(aoc.unsafe_parse_int)
  |> list.index_map(fn(size, index) {
    case index % 2 == 0 {
      True -> File(index: index / 2, size:)
      False -> Space(size:)
    }
  })
  |> deque.from_list
}

pub type File {
  File(size: Int, index: Int)
  Space(size: Int)
}

fn add_files_loop_2(queue: deque.Deque(File)) {
  do_add_files_loop_2(queue, [])
}

fn do_add_files_loop_2(
  queue: deque.Deque(File),
  out_list: List(Int),
) -> List(Int) {
  {
    use #(index, size, queue) <- result.map(
      pop_file_front(queue)
      |> result.map_error(map_error(queue, out_list)),
    )

    // add file to front
    let out_list = list.flatten([out_list, list.repeat(index, times: size)])

    let #(spaces, queue) = get_all_spaces_from_front(queue)
    io.println("###")
    io.debug(spaces)
    let #(queue, out_list) = {
      use #(queue, acc), space: File <- list.fold(spaces, #(queue, out_list))
      let #(add_in_space, queue) =
        get_n_end_files_2(queue, [], [], space.size) |> result.unwrap_both
      #(queue, list.flatten([acc, add_in_space]))
    }
    // io.debug(queue)
    // io.debug(out_list)
    do_add_files_loop_2(queue, out_list)
  }
  |> result.unwrap_both
}

fn map_error(queue, out_list) {
  fn(_) {
    let f_end_list =
      deque.to_list(queue)
      |> list.map(fn(x) {
        case x {
          File(size:, index:) -> list.repeat(index, size)
          Space(size:) -> list.repeat(0, size)
        }
      })
      |> list.flatten
    list.flatten([out_list, f_end_list])
  }
}

fn get_n_end_files_2(
  queue: deque.Deque(File),
  end_list: List(File),
  out_list: List(Int),
  space_size: Int,
) -> Result(#(List(Int), deque.Deque(File)), #(List(Int), deque.Deque(File))) {
  // drop spaces in back
  let #(_, queue) = get_all_spaces_from_back(queue)
  use #(index, file_size, queue) <- result.try(
    pop_file_back(queue)
    |> result.map_error(map_error_2(queue, out_list, end_list, space_size)),
  )
  // io.println("--")
  // io.debug(file_size)
  // io.debug(index)
  case space_size - file_size {
    a if a < 0 -> {
      let #(space_out, queue) = get_all_spaces_from_back(queue)
      let end_list =
        list.flatten([space_out, [File(index:, size: file_size), ..end_list]])
      get_n_end_files_2(queue, end_list, out_list, space_size)
    }
    a if a > 0 -> {
      let out_list = list.flatten([out_list, list.repeat(index, file_size)])
      let #(space_out, queue) = get_all_spaces_from_back(queue)
      let end_list = list.flatten([space_out, [Space(file_size)], end_list])
      get_n_end_files_2(queue, end_list, out_list, space_size - file_size)
    }
    a if a == 0 -> {
      let out_list = list.flatten([out_list, list.repeat(index, file_size)])
      let queue =
        [Space(file_size), ..end_list] |> list.fold(queue, deque.push_back)
      // io.debug("***")
      // io.debug(queue)
      // io.debug(end_list)
      // io.debug(out_list)
      Ok(#(out_list, queue))
    }
    _ -> panic as "bad exhaustivness check"
  }
}

fn map_error_2(queue, out_list, end_list, space_size) {
  fn(_) {
    let f_end_list =
      list.map(end_list, fn(x) {
        case x {
          File(size:, index:) -> list.repeat(index, size)
          Space(size:) -> list.repeat(0, size)
        }
      })
      |> list.flatten

    let queue = end_list |> list.fold(queue, deque.push_back)
    let out_list = list.flatten([out_list, list.repeat(0, space_size)])
    // io.debug("***")
    // io.debug(queue)
    // io.debug(space_size)
    // io.debug(end_list)
    // io.debug(out_list)
    #(out_list, queue)
  }
}

fn get_all_spaces_from_front(
  queue: deque.Deque(File),
) -> #(List(File), deque.Deque(File)) {
  do_get_all_spaces_from_front(queue, [])
}

fn do_get_all_spaces_from_front(
  queue: deque.Deque(File),
  spaces: List(Int),
) -> #(List(File), deque.Deque(File)) {
  case pop_space_front(queue) {
    Ok(#(space, queue)) ->
      do_get_all_spaces_from_front(queue, list.flatten([spaces, [space]]))
    Error(_) -> #(spaces |> list.map(Space), queue)
  }
}

fn get_all_spaces_from_back(
  queue: deque.Deque(File),
) -> #(List(File), deque.Deque(File)) {
  do_get_all_spaces_from_back(queue, [])
}

fn do_get_all_spaces_from_back(
  queue: deque.Deque(File),
  spaces: List(Int),
) -> #(List(File), deque.Deque(File)) {
  case pop_space_back(queue) {
    Ok(#(space, queue)) -> do_get_all_spaces_from_back(queue, [space, ..spaces])
    Error(_) -> #(spaces |> list.map(Space), queue)
  }
}

pub type Where {
  Back
  Front
}

fn pop_space_back(queue: deque.Deque(File)) {
  pop_space(queue, Back)
}

fn pop_space_front(queue: deque.Deque(File)) {
  pop_space(queue, Front)
}

fn pop_file_back(queue: deque.Deque(File)) {
  pop_file(queue, Back)
}

fn pop_file_front(queue: deque.Deque(File)) {
  pop_file(queue, Front)
}

fn pop_space(queue: deque.Deque(File), where: Where) {
  let unpack = fn(x) {
    let #(in_file, queue) = x
    case in_file {
      File(_, _) -> Error(Nil)
      Space(size) -> Ok(#(size, queue))
    }
  }

  case where {
    Back -> deque.pop_back(queue) |> result.then(unpack)
    Front -> deque.pop_front(queue) |> result.then(unpack)
  }
}

fn pop_file(queue: deque.Deque(File), where: Where) {
  let unpack = fn(x) {
    let #(in_file, queue) = x
    case in_file {
      File(size:, index:) -> Ok(#(index, size, queue))
      Space(_) -> Error(Nil)
    }
  }

  case where {
    Back -> deque.pop_back(queue) |> result.then(unpack)
    Front -> deque.pop_front(queue) |> result.then(unpack)
  }
}
