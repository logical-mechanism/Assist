//// This module contains code to do arithmetic circuit logic on integers.
//// All values are assumed to be positive and p is a prime.
////

// The value must be between [0, p-1]. Sometimes the value is a large negative.
// It takes the value r and keeps adding p until its greater than zero then
// finishes by doing value mod p.
// Internal only
// 
fn do_pos_shift(r: Int, p: Int) -> Int {
  if r < 0 {
    do_pos_shift(r + p, p)
  } else {
    r % p
  }
}

// this can get expensive
test do_pos_shift_test1() {
  let r = -1975180248
  let p: Int = 44203
  do_pos_shift(r, p) == r + 44685 * p
}

test do_pos_shift_test2() {
  let r = -15
  let p: Int = 44203
  do_pos_shift(r, p) == r + 1 * p
}

/// Performs a logical `AND` operation on two integer values within an arithmetic circuit.
///
/// ```aiken
/// circuits.and_(1, 1, p)
/// ```
pub fn and_(x: Int, y: Int, p: Int) -> Int {
  x * y % p
}

// Identity and tests
test identity_and() {
  let p: Int = 44203
  let x: Int = 123
  and_(x, 1, p) == x
}

// Same tests
test same_operands_and() {
  let p: Int = 44203
  let x: Int = 123
  and_(x, x, p) == x * x
}

// Nullification tests
test nullification_and() {
  let p: Int = 44203
  let x: Int = 123
  and_(x, 0, p) == 0
}

// Commutative property test
test commutative_and() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  and_(x, y, p) == and_(y, x, p)
}

// Boundary tests
test boundary_and() {
  let p: Int = 44203
  and {
    and_(0, p - 1, p) == 0,
    and_(p - 1, p - 1, p) == 1,
  }
}

/// Performs a logical `OR` operation on two integer values within an arithmetic circuit..
/// 
/// ```aiken
/// circuits.or_(0, 1, p)
/// ```
pub fn or_(x: Int, y: Int, p: Int) -> Int {
  let r: Int = x + y - x * y
  do_pos_shift(r, p)
}

// Identity and Dominance tests
test identity_or() {
  let p: Int = 44203
  let x: Int = 123
  or_(x, 0, p) == x
}

test dominance_or() {
  let p: Int = 44203
  let x: Int = 123
  or_(x, 1, p) == 1
}

// Commutative property test
test commutative_or() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  or_(x, y, p) == or_(y, x, p)
}

// Boundary tests
test boundary_or() {
  let p: Int = 44203
  or {
    or_(0, p - 1, p) == p - 1,
    or_(p - 1, p - 1, p) == p - 1,
  }
}

// Tests with both operands being the same
test same_operands_or() {
  let p: Int = 44203
  let x: Int = 123
  or_(x, x, p) == x + x - x * x + p
}

/// Performs a logical `NOT` operation on an integer value within an arithmetic circuit.
///
/// ```aiken
/// circuits.not_(1, p)
/// ```
pub fn not_(x: Int, p: Int) -> Int {
  ( p + 1 - x ) % p
}

// Boundary test for maximum value
test not_max() {
  let p: Int = 44203
  not_(p - 1, p) == ( p + 1 - ( p - 1 ) ) % p
}

// Test for inverting the NOT operation
test not_inversion() {
  let p: Int = 44203
  let x: Int = 123
  not_(not_(x, p), p) == x
}

/// Performs a logical `XOR` operation on two integer values within an arithmetic circuit.
///
/// ```aiken
/// circuits.xor_(0, 1, p)
/// ```
pub fn xor_(x: Int, y: Int, p: Int) -> Int {
  let r: Int = x + y - 2 * x * y
  do_pos_shift(r, p)
}

// Commutative property test
test commutative_xor() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  xor_(x, y, p) == xor_(y, x, p)
}

// Test for inverting the XOR operation with the same number
test xor_inversion() {
  let p: Int = 44203
  let x: Int = 123
  xor_(x, x, p) == x + x - 2 * x * x + p
}

/// Performs a logical `NAND` operation on two integer values within an arithmetic circuit.
/// 
/// ```aiken
/// circuits.nand_(1, 1, p)
/// ```
pub fn nand_(x: Int, y: Int, p: Int) -> Int {
  and_(x, y, p) |> not_(p)
}

// Identity and tests
test identity_nand() {
  let p: Int = 44203
  let x: Int = 123
  nand_(x, 1, p) == not_(x, p)
}

// Nullification tests
test nullification_nand() {
  let p: Int = 44203
  let x: Int = 123
  nand_(x, 0, p) == not_(0, p)
}

// Commutative property test
test commutative_nand() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  nand_(x, y, p) == nand_(y, x, p)
}

// Boundary tests
test boundary_nand() {
  let p: Int = 44203
  and {
    nand_(0, p - 1, p) == 1,
    nand_(p - 1, p - 1, p) == 0,
  }
}

/// Performs a logical `NOR` operation on two integer values within an arithmetic circuit.
/// 
/// ```aiken
/// circuits.nor_(0, 0, p)
/// ```
pub fn nor_(x: Int, y: Int, p: Int) -> Int {
  or_(x, y, p) |> not_(p)
}

// Identity and Dominance tests
test identity_nor() {
  let p: Int = 44203
  let x: Int = 123
  nor_(x, 0, p) == not_(x, p)
}

test dominance_nor() {
  let p: Int = 44203
  let x: Int = 123
  nor_(x, 1, p) == not_(1, p)
}

// Commutative property test
test commutative_nor() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  nor_(x, y, p) == nor_(y, x, p)
}

// Boundary tests
test boundary_nor() {
  let p: Int = 44203
  or {
    nor_(0, p - 1, p) == not_(p - 1, p),
    nor_(p - 1, p - 1, p) == not_(p - 1, p),
  }
}

// Tests with both operands being the same
test same_operands_nor() {
  let p: Int = 44203
  let x: Int = 123
  nor_(x, x, p) == not_(x + x - x * x + p, p)
}

/// Performs a logical `XNOR` operation on two integer values within an arithmetic circuit.
/// 
/// ```aiken
/// circuits.xnor_(1, 1, p)
/// ```
pub fn xnor_(x: Int, y: Int, p: Int) -> Int {
  xor_(x, y, p) |> not_(p)
}

// Commutative property test
test commutative_xnor() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  xnor_(x, y, p) == xnor_(y, x, p)
}

// Test for inverting the XOR operation with the same number
test xnor_inversion() {
  let p: Int = 44203
  let x: Int = 123
  xnor_(x, x, p) == not_(x + x - 2 * x * x + p, p)
}

/// Performs a logical implication operation on two integer values within an arithmetic circuit.
/// 
/// ```aiken
/// circuits.imply_(1, 0, p)
/// ```
pub fn imply_(x: Int, y: Int, p: Int) -> Int {
  not_(x, p) |> or_(y, p)
}

// Commutative property test
test no_commutative_imply() {
  let p: Int = 44203
  let x: Int = 123
  let y: Int = 321
  imply_(x, y, p) != imply_(y, x, p)
}

// Boundary tests
test boundary_imply() {
  let p: Int = 44203
  imply_(0, p - 1, p) == 1
}

// An equation can now be built out of the functions
test a_simple_circuit() {
  let p: Int = 44203
  let x: Int = 172
  let y: Int = 256
  // the first statement reduces to 1 = and_(x, y+1, p)
  and {
    ( or_(x, y, p) + not_(x, p) ) % p == ( xor_(x, y, p) + 2 * and_(x, y, p) ) % p,
    1 == and_(x, y + 1, p),
  }
}

test a_moderate_circuit() {
  let p: Int = 44203
  let x: Int = 8860
  let y: Int = 9047
  not_(x, p) == not_(x, y) * not_(x, y)
}
