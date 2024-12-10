import aoc
import gleam/deque
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type File {
  File(size: Int, index: Int)
  Space(size: Int)
  NoopSpace(size: Int)
}

fn parse(in: String) {
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

fn push_back_list(queue: deque.Deque(a), any_list: List(a)) {
  any_list |> list.fold(queue, deque.push_back)
}

fn get_end_file_spilt(
  queue: deque.Deque(File),
  space_size: Int,
) -> Result(#(File, deque.Deque(File)), Nil) {
  do_get_end_file_spilt(queue, [], space_size)
}

fn do_get_end_file_spilt(
  queue: deque.Deque(File),
  end_list: List(File),
  space_size: Int,
) -> Result(#(File, deque.Deque(File)), Nil) {
  // get something from the front
  use #(file, queue) <- result.try(deque.pop_back(queue)// nothing found -> we have to leave the space empty
  )
  case file {
    File(size:, index: _) as front_file if size <= space_size -> {
      let queue =
        queue
        |> deque.push_front(Space(size: space_size - size))
        |> push_back_list(end_list)
      Ok(#(front_file, queue))
    }
    File(size:, index:) -> {
      let file_split = File(size: size - space_size, index:)
      let queue =
        queue
        |> deque.push_back(file_split)
        |> push_back_list(end_list)
      Ok(#(File(size: space_size, index:), queue))
    }
    Space(_) as front_space | NoopSpace(_) as front_space -> {
      do_get_end_file_spilt(queue, [front_space, ..end_list], space_size)
    }
  }
}

fn get_file_from_back_that_fits(
  queue: deque.Deque(File),
  space_size: Int,
) -> Result(#(File, deque.Deque(File)), Nil) {
  do_get_file_from_back_that_fits(queue, [], space_size)
}

fn do_get_file_from_back_that_fits(
  queue: deque.Deque(File),
  end_list: List(File),
  space_size: Int,
) -> Result(#(File, deque.Deque(File)), Nil) {
  // get something from the front
  use #(file, queue) <- result.try(deque.pop_back(queue)// nothing found -> we have to leave the space empty
  )
  case file {
    File(size:, index: _) as front_file if size <= space_size -> {
      let queue =
        queue
        |> deque.push_front(Space(size: space_size - size))
        |> deque.push_back(NoopSpace(size:))
        |> push_back_list(end_list)
      Ok(#(front_file, queue))
    }
    Space(_) as front_space
    | NoopSpace(_) as front_space
    | File(_, _) as front_space -> {
      do_get_file_from_back_that_fits(
        queue,
        [front_space, ..end_list],
        space_size,
      )
    }
  }
}

fn add_files_loop(queue: deque.Deque(File), get_file) {
  do_add_files_loop(queue, [], get_file)
}

fn do_add_files_loop(
  queue: deque.Deque(File),
  out_list: List(File),
  get_file: fn(deque.Deque(File), Int) ->
    Result(#(File, deque.Deque(File)), Nil),
) -> List(File) {
  {
    // get something from the front
    use #(file, queue) <- result.map(
      deque.pop_front(queue)
      // nothing at the front -> we are finished
      |> result.replace_error(list.reverse(out_list)),
    )
    case file {
      File(_, _) as front_file | NoopSpace(_) as front_file ->
        do_add_files_loop(queue, [front_file, ..out_list], get_file)
      Space(size:) if size == 0 -> {
        do_add_files_loop(queue, out_list, get_file)
      }
      Space(size:) as front_space -> {
        case get_file(queue, size) {
          Ok(#(file_for_space, queue)) ->
            do_add_files_loop(queue, [file_for_space, ..out_list], get_file)
          Error(_) ->
            do_add_files_loop(queue, [front_space, ..out_list], get_file)
        }
      }
    }
  }
  |> result.unwrap_both
}

fn checksum(out_list: List(File)) {
  out_list
  |> list.flat_map(fn(x) {
    case x {
      File(size:, index:) -> list.repeat(index, times: size)
      Space(size:) | NoopSpace(size:) -> list.repeat(0, times: size)
    }
  })
  |> list.index_map(fn(x, i) { x * i })
  |> int.sum
}

pub fn pt_1(input: String) {
  let queue = parse(input)
  add_files_loop(queue, get_end_file_spilt)
  |> checksum
}

pub fn pt_2(input: String) {
  let queue = parse(input)
  add_files_loop(queue, get_file_from_back_that_fits)
  |> checksum
}
