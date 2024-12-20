import gleam/dict
import gleam/io

pub type Cache(a, b) =
  dict.Dict(a, b)

pub type Memo(a, b) {
  Memo(value: b, cache: Cache(a, b))
}

pub fn create(init_res: b, func: fn(Memo(a, b)) -> c) {
  func(Memo(value: init_res, cache: dict.new()))
}

pub fn memoize(memo: Memo(a, b), key: a, func: fn() -> Memo(a, b)) {
  case dict.get(memo.cache, key) {
    Error(_) -> {
      let Memo(value, memo) = func()
      Memo(value:, cache: dict.insert(memo, key, value))
    }
    Ok(memoized_res) -> Memo(memoized_res, memo.cache)
  }
}

pub fn apply(
  memo: Memo(a, b),
  body: fn(b, Memo(a, b)) -> Memo(a, b),
) -> Memo(a, b) {
  body(memo.value, memo)
}

pub fn unpack(res: Memo(a, b)) {
  res.value
}

// pub fn fold(in: List(a), start: b, fn()){

// }

pub fn main() {
  test_context()
  |> unpack
  |> io.debug
}

fn test_context() {
  use memo <- create(0)
  fib(1000, memo)
}

fn fib(n: Int, memo) {
  use <- memoize(memo, n)
  case n {
    0 | 1 -> Memo(1, memo.cache)
    _ -> {
      use fib1, memo <- apply(fib(n - 1, memo))
      use fib2, memo <- apply(fib(n - 2, memo))
      Memo(..memo, value: fib1 + fib2)
    }
  }
}
