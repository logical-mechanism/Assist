//// This module contains code to do simple boolean logic on integers.
////

/// Performs a logical AND operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if both are 1, otherwise returns 0.
///
/// ```aiken
/// boolean.and_(1, 1)
/// ```
pub fn and_(x: Int, y: Int) -> Int {
  x * y
}

test zero_zero_add() {
  and_(0, 0) == 0
}

test zero_one_add() {
  and_(0, 1) == 0
}

test one_zero_add() {
  and_(1, 0) == 0
}

test one_one_add() {
  and_(1, 1) == 1
}

/// Performs a logical OR operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if at least one input is 1, otherwise returns 0.
/// 
/// ```aiken
/// boolean.or_(0, 1)
/// ```
pub fn or_(x: Int, y: Int) -> Int {
  if x + y > 0 {
    1
  } else {
    0
  }
}

test zero_zero_or() {
  or_(0, 0) == 0
}

test zero_one_or() {
  or_(0, 1) == 1
}

test one_zero_or() {
  or_(1, 0) == 1
}

test one_one_or() {
  or_(1, 1) == 1
}

/// Performs a logical NOT operation on an integer value.
/// Expects the input as binary (0 or 1) and returns the inverse (1 becomes 0, 0 becomes 1).
///
/// ```aiken
/// boolean.not_(1)
/// ```
pub fn not_(x: Int) -> Int {
  1 - x
}

test zero_not() {
  not_(0) == 1
}

test one_not() {
  not_(1) == 0
}

/// Performs a logical XOR operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if the inputs are different, otherwise returns 0.
///
/// ```aiken
/// boolean.xor_(0, 1)
/// ```
pub fn xor_(x: Int, y: Int) {
  ( x + y ) % 2
}

test zero_zero_xor() {
  xor_(0, 0) == 0
}

test zero_one_xor() {
  xor_(0, 1) == 1
}

test one_zero_xor() {
  xor_(1, 0) == 1
}

test one_one_xor() {
  xor_(1, 1) == 0
}

test complete_set() {
  let a = 1
  let b = 0
  let c = 1
  let d = 1
  let r = and_(a, b)
  let n = not_(c)
  let o = or_(r, n)
  xor_(o, d) == 1
}
