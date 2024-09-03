//// This module contains code to do boolean logic on integers.
//// Boolean logic here is the special case of arithmetic circuit logic with p = 2.
////

use maths/circuits

/// Performs a logical `AND` operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if both are 1, otherwise returns 0.
///
/// ```aiken
/// boolean.and_(1, 1)
/// ```
pub fn and_(x: Int, y: Int) -> Int {
  circuits.and_(x, y, 2)
}

test zero_zero_and() {
  and_(0, 0) == 0
}

test zero_one_and() {
  and_(0, 1) == 0
}

test one_zero_and() {
  and_(1, 0) == 0
}

test one_one_and() {
  and_(1, 1) == 1
}

/// Performs a logical `OR` operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if at least one input is 1, otherwise returns 0.
/// 
/// ```aiken
/// boolean.or_(0, 1)
/// ```
pub fn or_(x: Int, y: Int) -> Int {
  circuits.or_(x, y, 2)
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

/// Performs a logical `NOT` operation on an integer value.
/// Expects the input as binary (0 or 1) and returns the inverse (1 becomes 0, 0 becomes 1).
///
/// ```aiken
/// boolean.not_(1)
/// ```
pub fn not_(x: Int) -> Int {
  circuits.not_(x, 2)
}

test zero_not() {
  not_(0) == 1
}

test one_not() {
  not_(1) == 0
}

/// Performs a logical `XOR` operation on two integer values.
/// Expects both inputs as binary (0 or 1) and returns 1 if the inputs are different, otherwise returns 0.
///
/// ```aiken
/// boolean.xor_(0, 1)
/// ```
pub fn xor_(x: Int, y: Int) {
  circuits.xor_(x, y, 2)
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

/// Performs a logical `NAND` operation on two integer values.
/// Returns 1 if at least one input is 0, otherwise returns 0.
/// 
/// ```aiken
/// boolean.nand_(1, 1)
/// ```
pub fn nand_(x: Int, y: Int) -> Int {
  and_(x, y) |> not_()
}

test zero_zero_nand() {
  nand_(0, 0) == 1
}

test zero_one_nand() {
  nand_(0, 1) == 1
}

test one_zero_nand() {
  nand_(1, 0) == 1
}

test one_one_nand() {
  nand_(1, 1) == 0
}

/// Performs a logical `NOR` operation on two integer values.
/// Returns 1 if both inputs are 0, otherwise returns 0.
/// 
/// ```aiken
/// boolean.nor_(0, 0)
/// ```
pub fn nor_(x: Int, y: Int) -> Int {
  or_(x, y) |> not_()
}

test zero_zero_nor() {
  nor_(0, 0) == 1
}

test zero_one_nor() {
  nor_(0, 1) == 0
}

test one_zero_nor() {
  nor_(1, 0) == 0
}

test one_one_nor() {
  nor_(1, 1) == 0
}

/// Performs a logical `XNOR` operation on two integer values.
/// Returns 1 if the inputs are the same, otherwise returns 0.
/// 
/// ```aiken
/// boolean.xnor_(1, 1)
/// ```
pub fn xnor_(x: Int, y: Int) -> Int {
  xor_(x, y) |> not_()
}

test zero_zero_xnor() {
  xnor_(0, 0) == 1
}

test zero_one_xnor() {
  xnor_(0, 1) == 0
}

test one_zero_xnor() {
  xnor_(1, 0) == 0
}

test one_one_xnor() {
  xnor_(1, 1) == 1
}

/// Performs a logical implication operation on two integer values.
/// Returns 1 if the first input is false or both inputs are true, otherwise returns 0.
/// 
/// ```aiken
/// boolean.imply_(1, 0)
/// ```
pub fn imply_(x: Int, y: Int) -> Int {
  not_(x) |> or_(y)
}

test zero_zero_imply() {
  imply_(0, 0) == 1
}

test zero_one_imply() {
  imply_(0, 1) == 1
}

test one_zero_imply() {
  imply_(1, 0) == 0
}

test one_one_imply() {
  imply_(1, 1) == 1
}
