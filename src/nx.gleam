import gleam/erlang/atom

/// WIP to use nx to solve lin alg
pub type Point(a) {
  Point
}

pub type Tensor(a) {
  Tensor
}

pub type Matrix(a) {
  Matrix
}

@external(erlang, "Elixir.Nx", "tensor")
pub fn tensor_int(args: Int) -> Point(Int)

pub fn tensor_vector_int(args: List(Int)) -> Tensor(Int) {
  let at = atom.create_from_string("u64")
  do_tensor(args, at)
}

@external(erlang, "nx_ffi", "tensor")
fn do_tensor(args: x, format: atom.Atom) -> c

@external(erlang, "Elixir.Nx", "tensor")
pub fn tensor_vector_fload(args: List(Float)) -> Tensor(Float)

@external(erlang, "Elixir.Nx", "tensor")
pub fn tensor_matrix_int(args: List(List(Int))) -> Matrix(Int)

@external(erlang, "Elixir.Nx", "tensor")
pub fn tensor_matrix_float(args: List(List(Float))) -> Matrix(Float)

// @external(erlang, "Elixir.Nx.LinAlg", "solve")
// pub fn solve(matrix: Native, x: Native) -> Native
@external(erlang, "Elixir.Nx.LinAlg", "solve")
pub fn solve(matrix: Matrix(a), x: Tensor(b)) -> Tensor(Float)

pub fn determinant(matrix: Matrix(Int)) -> Float {
  do_determinant(matrix)
  |> to_number
}

@external(erlang, "Elixir.Nx.LinAlg", "determinant")
fn do_determinant(matrix: Matrix(Int)) -> Point(float)

@external(erlang, "Elixir.Nx", "to_number")
pub fn to_number(point: Point(a)) -> Float

@external(erlang, "Elixir.Nx", "to_list")
pub fn to_list(point: Tensor(a)) -> List(Float)

@external(erlang, "Elixir.Nx", "to_list")
pub fn to_list_matrix(point: Matrix(a)) -> List(Float)
