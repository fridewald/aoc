import gleam/dict
import gleam/io

pub type Memo(a, b) =
  dict.Dict(a, b)

pub type MemoResult(a, b) {
  MemoResult(result: b, memo: Memo(a, b))
}

pub fn create(func: fn(Memo(a, b)) -> c) {
  func(dict.new())
}

pub fn memoize(memo: Memo(a, b), key: a, func: fn() -> MemoResult(a, b)) {
  case dict.get(memo, key) {
    Error(_) -> {
      let MemoResult(result, memo) = func()
      MemoResult(result:, memo: dict.insert(memo, key, result))
    }
    Ok(memoized_res) -> MemoResult(memoized_res, memo)
  }
}

pub fn apply(
  memo_result: MemoResult(a, b),
  body: fn(b, Memo(a, b)) -> MemoResult(a, b),
) -> MemoResult(a, b) {
  body(memo_result.result, memo_result.memo)
}

pub fn unpack(res: MemoResult(a, b)) {
  res.result
}

pub fn main() {
  test_context()
  |> unpack
  |> io.debug
}

fn test_context() {
  use memo <- create()
  fib(1000, memo)
}

fn fib(n: Int, memo) {
  use <- memoize(memo, n)
  case n {
    0 | 1 -> MemoResult(1, memo)
    _ -> {
      use fib1, memo <- apply(fib(n - 1, memo))
      use fib2, memo <- apply(fib(n - 2, memo))
      MemoResult(fib1 + fib2, memo)
    }
  }
}
