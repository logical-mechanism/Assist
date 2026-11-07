//// Property-based tests for `maths/boolean`. Each gate is checked against
//// Aiken's native boolean operators.

use aiken/fuzz
use maths/boolean

fn bit() -> Fuzzer<Int> {
  fuzz.int_between(0, 1)
}

fn bits() -> Fuzzer<(Int, Int)> {
  fuzz.tuple(bit(), bit())
}

fn to_bool(x: Int) -> Bool {
  x == 1
}

fn from_bool(b: Bool) -> Int {
  if b {
    1
  } else {
    0
  }
}

test prop_and_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.and_(x, y) == from_bool(to_bool(x) && to_bool(y))
}

test prop_or_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.or_(x, y) == from_bool(to_bool(x) || to_bool(y))
}

test prop_not_matches_bool(x via bit()) {
  boolean.not_(x) == from_bool(!to_bool(x))
}

test prop_xor_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.xor_(x, y) == from_bool(to_bool(x) != to_bool(y))
}

test prop_nand_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.nand_(x, y) == from_bool(!(to_bool(x) && to_bool(y)))
}

test prop_nor_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.nor_(x, y) == from_bool(!(to_bool(x) || to_bool(y)))
}

test prop_xnor_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.xnor_(x, y) == from_bool(to_bool(x) == to_bool(y))
}

test prop_imply_matches_bool(input via bits()) {
  let (x, y) = input
  boolean.imply_(x, y) == from_bool(!to_bool(x) || to_bool(y))
}

test prop_de_morgan(input via bits()) {
  let (x, y) = input
  and {
    boolean.not_(boolean.and_(x, y)) == boolean.or_(
      boolean.not_(x),
      boolean.not_(y),
    ),
    boolean.not_(boolean.or_(x, y)) == boolean.and_(
      boolean.not_(x),
      boolean.not_(y),
    ),
  }
}
