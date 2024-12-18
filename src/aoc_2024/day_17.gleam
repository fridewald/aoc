import aoc
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import tuple

// thoughts
//
// 2,4 -> bst A % 8 ; combo 4 = A     -> B   reverse ?? check output
// 1,5 -> bxl B xor 5                 -> B   reverse is xor 5
// 7,5 -> cdv A / (2^B)               -> C   reverse C * 2 ^B
// 0,3 -> adv A / (2^3) = A / 8       -> A   reverse A * 8 + {0,7}
// 4,1 -> bxc B xor C                 -> B   reverse is xor C
// 1,6 -> bxl B xor 6                 -> B   reverse is xor 6
// 5,5 -> out B % 8; combo 5 -> B
// 3,0 -> jnz 0
//
//
// jnz 0 b c
// out 0 b = 0 c
// bxl 0, b xor 6, c
// bxc a, b1 xor c, c -> b1 = b xor 6
// adv a* 8 +{0, 7}, b2, c -> b2 = b1 xor c 
// cdv a1, b2, c -> c = a1 / 2^b2 -> a1 = a * 8 + {0, 7}
// bxl a1, b2 xor 5, c1
// bst a1, b3, c1 -> b2  = (a1 % 8) xor 5 -> b3 = b2 xor 5
// jnz a1, b3, c1
// out a1, b3, c1
//
//
// b2 =  (a1 % 8) xor 5
// c = a1 / 2^b2 = a1 / (2^ ((a1 % 8)xor 5)) 
// b = (((a1 % 8) xor 5) xor c) xor 6
//
//
// ((( a1 % 8 ) ^ 5) ^ (a1 // (2<<((a1%8)^5 )) ) ^ 6 )
//
// 0 0 * 8 + 3
//
// 2,4,1,5,7,5,0,3,4,1,1,6,5,5,3,0
//
// 130714702117474
//

pub type Stack {
  Stack(a: Int, b: Int, c: Int)
}

pub type Program {
  Program(
    stack: Stack,
    remaining_instructions: List(#(Int, Int)),
    all_instructions: List(#(Int, Int)),
  )
}

fn parse(input: String) {
  let assert [stacks, instructions_string] = string.split(input, "\n\n")

  let assert [a, b, c] =
    string.split(stacks, "\n")
    |> list.map(fn(x) {
      string.split(x, " ")
      |> list.last
      |> result.unwrap("0")
      |> aoc.unsafe_parse_int
    })
  let stack = Stack(a, b, c)

  let instructions_string = string.replace(instructions_string, "Program: ", "")
  let all_instructions =
    string.split(instructions_string, ",")
    |> list.map(aoc.unsafe_parse_int)
    |> list.sized_chunk(into: 2)
    |> list.filter_map(fn(x) {
      case x {
        [opcode, literal] -> Ok(#(opcode, literal))
        _ -> Error(Nil)
      }
    })

  Program(stack:, remaining_instructions: all_instructions, all_instructions:)
}

pub fn run_program(program) {
  let out = yielder.to_list(do_run_program(program)) |> list.map(tuple.first_2)
  out |> list.reverse |> list.drop(1) |> list.reverse |> string.join(",")
}

// pub fn yield_first_output(program) {
//   todo
// }

pub fn do_run_program(program) {
  let Program(stack:, remaining_instructions:, all_instructions:) = program
  let Stack(a:, b:, c:) = stack
  use <- bool.guard(
    remaining_instructions == [],
    yielder.yield(#("", program), yielder.empty),
  )
  // update remaining_instructions
  let assert [#(opcode, literal), ..remaining_instructions] =
    remaining_instructions
  let program = Program(..program, remaining_instructions:)

  // do operation
  case opcode, literal {
    0, operand -> {
      let a = a / { int.bitwise_shift_left(1, combo(operand, stack)) }
      let stack = Stack(..stack, a:)
      do_run_program(Program(..program, stack:))
    }
    1, operand -> {
      let b = int.bitwise_exclusive_or(b, operand)
      let stack = Stack(..stack, b:)
      do_run_program(Program(..program, stack:))
    }
    2, operand -> {
      let b = combo(operand, stack) % 8
      let stack = Stack(..stack, b:)
      do_run_program(Program(..program, stack:))
    }
    3, _ if a == 0 -> do_run_program(program)
    3, operand -> {
      let remaining_instructions = list.drop(all_instructions, operand)
      do_run_program(Program(..program, remaining_instructions:))
    }
    4, _ -> {
      let b = int.bitwise_exclusive_or(b, c)
      let stack = Stack(..stack, b:)
      do_run_program(Program(..program, stack:))
    }
    5, operand -> {
      let com = combo(operand, stack) % 8
      let out = int.to_string(com)
      use <- yielder.yield(#(out, program))
      // let out = [int.to_string(com), ..out]
      do_run_program(program)
    }
    6, operand -> {
      let b = a / { int.bitwise_shift_left(1, combo(operand, stack)) }
      let stack = Stack(..stack, b:)
      do_run_program(Program(..program, stack:))
    }
    7, operand -> {
      let c = a / { int.bitwise_shift_left(1, combo(operand, stack)) }
      let stack = Stack(..stack, c:)
      do_run_program(Program(..program, stack:))
    }
    _, _ -> panic as "invalid program"
  }
}

fn combo(operand, stack: Stack) {
  case operand {
    x if x >= 0 && x <= 3 -> x
    4 -> stack.a
    5 -> stack.b
    6 -> stack.c
    _ -> panic as "invalid program"
  }
}

pub fn pt_1(input: String) {
  let program = parse(input)
  run_program(program)
}

pub fn pt_2(input: String) {
  let program = parse(input)

  let program =
    Program(..program, stack: Stack(..program.stack, a: 109_020_013_201_563))
  run_program(program)
}
