//// This module contains code to do arithmetic circuit logic on integers.
//// All values are assumed to be positive and p is a prime.
////

/// Performs a logical AND operation on two integer values within an arithmetic circuit.
///
/// ```aiken
/// circuits.and_(1, 1, p)
/// ```
pub fn and_(x: Int, y: Int, p: Int) -> Int {
  x * y % p
}

// Identity and tests
test identity_and() {
  let p = 44203
  let x = 123
  and_(x, 1, p) == x
}

// Nullification tests
test nullification_and() {
  let p = 44203
  let x = 123
  and_(x, 0, p) == 0
}

// Commutative property test
test commutative_and() {
  let p = 44203
  let x = 123
  let y = 321
  and_(x, y, p) == and_(y, x, p)
}

// Boundary tests
test boundary_and() {
  let p = 44203
  and {
    and_(0, p - 1, p) == 0,
    and_(p - 1, p - 1, p) == 1,
  }
}

/// Performs a logical OR operation on two integer values within an arithmetic circuit..
/// 
/// ```aiken
/// circuits.or_(0, 1, p)
/// ```
pub fn or_(x: Int, y: Int, p: Int) -> Int {
  let r = x + y - x * y
  if r < 0 {
    r + p
  } else {
    r % p
  }
}

// Identity and Dominance tests
test identity_or() {
  let p = 44203
  let x = 123
  or_(x, 0, p) == x
}

test dominance_or() {
  let p = 44203
  let x = 123
  or_(x, 1, p) == 1
}

// Commutative property test
test commutative_or() {
  let p = 44203
  let x = 123
  let y = 321
  or_(x, y, p) == or_(y, x, p)
}

// Boundary tests
test boundary_or() {
  let p = 44203
  or {
    or_(0, p - 1, p) == p - 1,
    or_(p - 1, p - 1, p) == p - 1,
  }
}

// Tests with both operands being the same
test same_operands_or() {
  let p = 44203
  let x = 123
  or_(x, x, p) == x + x - x * x + p
}

/// Performs a logical NOT operation on an integer value within an arithmetic circuit.
///
/// ```aiken
/// circuits.not_(1, p)
/// ```
pub fn not_(x: Int, p: Int) -> Int {
  ( p + 1 - x ) % p
}

// Boundary test for maximum value
test not_max() {
  let p = 44203
  not_(p - 1, p) == ( p + 1 - ( p - 1 ) ) % p
}

// Test for inverting the NOT operation
test not_inversion() {
  let p = 44203
  let x = 123
  not_(not_(x, p), p) == x
}

/// Performs a logical XOR operation on two integer values within an arithmetic circuit.
///
/// ```aiken
/// circuits.xor_(0, 1, p)
/// ```
pub fn xor_(x: Int, y: Int, p: Int) -> Int {
  let r = x + y - 2 * x * y
  if r < 0 {
    r + p
  } else {
    r % p
  }
}

// Commutative property test
test commutative_xor() {
  let p = 44203
  let x = 123
  let y = 321
  xor_(x, y, p) == xor_(y, x, p)
}

// Test for inverting the XOR operation with the same number
test xor_inversion() {
  let p = 44203
  let x = 123
  xor_(x, x, p) == x + x - 2 * x * x + p
}

// An equation can now be built out of the functions
test a_simple_circuit() {
  let p = 44203
  let x = 172
  let y = 256
  or_(x, y, p) + not_(x, p) == xor_(x, y, p) + 2 * and_(x, y, p)
}
