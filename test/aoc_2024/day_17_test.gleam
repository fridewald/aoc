import aoc_2024/day_17
import gleam/yielder
import gleeunit/should

pub fn bst_test() {
  let stack = day_17.Stack(a: 0, b: 0, c: 9)
  let instructions = [#(2, 6)]
  let program =
    day_17.Program(
      stack:,
      remaining_instructions: instructions,
      all_instructions: instructions,
    )

  let assert Ok(#(_, stack)) = day_17.do_run_program(program) |> yielder.last

  should.equal(stack.stack, day_17.Stack(a: 0, b: 1, c: 9))
}

pub fn yielder_test() {
  let y = yielder.from_list([1, 2, 3])
  should.equal(yielder.last(y), Ok(3))
  let y = yielder.append(y, yielder.empty())
  should.equal(yielder.last(y), Ok(3))
}

pub fn out_test() {
  let stack = day_17.Stack(a: 10, b: 0, c: 0)
  let instructions = [#(5, 0), #(5, 1), #(5, 4)]
  let program =
    day_17.Program(
      stack:,
      remaining_instructions: instructions,
      all_instructions: instructions,
    )

  let out = day_17.run_program(program)

  should.equal(out, "0,1,2")
}

pub fn jnz_test() {
  let stack = day_17.Stack(a: 2024, b: 0, c: 0)
  let instructions = [#(0, 1), #(5, 4), #(3, 0)]
  let program =
    day_17.Program(
      stack:,
      remaining_instructions: instructions,
      all_instructions: instructions,
    )

  let out = day_17.run_program(program)

  let assert Ok(#(_, stack)) = day_17.do_run_program(program) |> yielder.last

  should.equal(out, "4,2,5,6,7,7,7,7,3,1,0")
  should.equal(stack.stack, day_17.Stack(a: 0, b: 0, c: 0))
}

pub fn bxl_test() {
  let stack = day_17.Stack(a: 0, b: 29, c: 0)
  let instructions = [#(1, 7)]
  let program =
    day_17.Program(
      stack:,
      remaining_instructions: instructions,
      all_instructions: instructions,
    )

  let assert Ok(#(_, stack)) = day_17.do_run_program(program) |> yielder.last

  should.equal(stack.stack, day_17.Stack(a: 0, b: 26, c: 0))
}

pub fn bxc_test() {
  let stack = day_17.Stack(a: 0, b: 2024, c: 43_690)
  let instructions = [#(4, 0)]
  let program =
    day_17.Program(
      stack:,
      remaining_instructions: instructions,
      all_instructions: instructions,
    )

  let assert Ok(#(_, stack)) = day_17.do_run_program(program) |> yielder.last

  should.equal(stack.stack, day_17.Stack(a: 0, b: 44_354, c: 43_690))
}
