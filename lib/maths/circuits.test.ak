//// Property-based tests for `maths/circuits`.

use aiken/fuzz
use maths/circuits
use maths/constants

/// A handful of primes, from the smallest to the BLS12-381 base field prime.
fn prime() -> Fuzzer<Int> {
  fuzz.one_of([2, 3, 5, 7, 11, 13, 251, 44203, 65537, constants.large_prime])
}

/// A prime and two field elements in `[0, p-1]`.
fn field_elements() -> Fuzzer<(Int, Int, Int)> {
  let p <- fuzz.and_then(prime())
  let x <- fuzz.and_then(fuzz.int_between(0, p - 1))
  let y <- fuzz.map(fuzz.int_between(0, p - 1))
  (p, x, y)
}

/// A prime and two bits.
fn field_bits() -> Fuzzer<(Int, Int, Int)> {
  fuzz.tuple3(prime(), fuzz.int_between(0, 1), fuzz.int_between(0, 1))
}

fn is_reduced(v: Int, p: Int) -> Bool {
  v >= 0 && v < p
}

test prop_results_are_reduced(input via field_elements()) {
  let (p, x, y) = input
  and {
    is_reduced(circuits.and_(x, y, p), p),
    is_reduced(circuits.or_(x, y, p), p),
    is_reduced(circuits.not_(x, p), p),
    is_reduced(circuits.xor_(x, y, p), p),
    is_reduced(circuits.nand_(x, y, p), p),
    is_reduced(circuits.nor_(x, y, p), p),
    is_reduced(circuits.xnor_(x, y, p), p),
    is_reduced(circuits.imply_(x, y, p), p),
  }
}

test prop_symmetric_gates_commute(input via field_elements()) {
  let (p, x, y) = input
  and {
    circuits.and_(x, y, p) == circuits.and_(y, x, p),
    circuits.or_(x, y, p) == circuits.or_(y, x, p),
    circuits.xor_(x, y, p) == circuits.xor_(y, x, p),
    circuits.nand_(x, y, p) == circuits.nand_(y, x, p),
    circuits.nor_(x, y, p) == circuits.nor_(y, x, p),
    circuits.xnor_(x, y, p) == circuits.xnor_(y, x, p),
  }
}

test prop_not_is_an_involution(input via field_elements()) {
  let (p, x, _) = input
  circuits.not_(circuits.not_(x, p), p) == x
}

test prop_identities(input via field_elements()) {
  let (p, x, _) = input
  and {
    circuits.and_(x, 1, p) == x,
    circuits.and_(x, 0, p) == 0,
    circuits.or_(x, 0, p) == x,
    circuits.xor_(x, 0, p) == x,
  }
}

test prop_inclusion_exclusion(input via field_elements()) {
  // or + and = x + y, and xor + 2 * and = x + y, both modulo p
  let (p, x, y) = input
  and {
    ( circuits.or_(x, y, p) + circuits.and_(x, y, p) ) % p == ( x + y ) % p,
    ( circuits.xor_(x, y, p) + 2 * circuits.and_(x, y, p) ) % p == ( x + y ) % p,
  }
}

test prop_bits_behave_like_booleans(input via field_bits()) {
  // restricted to {0, 1}, every gate agrees with plain boolean logic in any
  // prime field
  let (p, x, y) = input
  let a = x == 1
  let b = y == 1
  let bit = fn(v: Bool) {
    if v {
      1
    } else {
      0
    }
  }
  and {
    circuits.and_(x, y, p) == bit(a && b),
    circuits.or_(x, y, p) == bit(a || b),
    circuits.not_(x, p) == bit(!a),
    circuits.xor_(x, y, p) == bit(a != b),
    circuits.nand_(x, y, p) == bit(!(a && b)),
    circuits.nor_(x, y, p) == bit(!(a || b)),
    circuits.xnor_(x, y, p) == bit(a == b),
    circuits.imply_(x, y, p) == bit(!a || b),
  }
}
