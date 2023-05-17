//// This module includes code for various maths.
////
////

use aiken/bytearray
use aiken/list

/// Calculate `n` to the power of `e` modulo `q` using the exponentiation by 
/// squaring method. At each multiplication a modulo is calculated, allowing
/// very large power mods.
///
/// ```aiken
/// maths.powmod(3, 2, 5)
/// ```
pub fn powmod(n: Int, e: Int, q: Int) -> Int {
  if e < 0 {
    0
  } else if e == 0 {
    1
  } else if e % 2 == 0 {
    powmod(n * n % q, e / 2, q) % q
  } else {
    n * powmod(n * n % q, ( e - 1 ) / 2, q) % q
  }
}

test powmod_3_5_4() {
  powmod(3, 5, 4) == 3
}

test powmod_3__4_3() {
  // negative powers round to zero
  powmod(3, -4, 3) == 0
}

test pow_0_0_0() {
  // sorry math
  powmod(0, 0, 0) == 1
}

test powmod_513_3_7() {
  powmod(513, 3, 7) == 1
}

/// Convert a number `n` in base 10 into some base `q`. This method
/// should scale with any number and any logical base.
///
/// ```aiken
/// maths.base_q(123, 7)
/// ```
pub fn base_q(n: Int, q: Int) -> List<Int> {
  convert_into_base_q(n, q, [])
}

fn convert_into_base_q(number: Int, base: Int, holder: List<Int>) -> List<Int> {
  // if the number or base is zero return the holder list
  if number == 0 || base == 0 {
    holder
  } else {
    convert_into_base_q(number / base, base, list.push(holder, number % base))
  }
}

test zero_in_base_zero() {
  base_q(0, 0) == []
}

test one_in_base_zero() {
  base_q(1, 0) == []
}

test simple_base_q() {
  base_q(17232, 4) == [1, 0, 0, 3, 1, 1, 0, 0]
}

test to_base_256() {
  base_q(78237623, 256) == [4, 169, 207, 183]
}

/// Convert a hexadecimal bytearray into its base 10 representation. This
/// only works with even length bytearrays so arbitrary numbers in hexadecimal
/// form will not in general work.
///
/// ```aiken
/// maths.to_int(#"acab")
/// ```
pub fn to_int(self: ByteArray) -> Int {
  // base 10 value of a hexadecimal number as a bytearray
  bytearray.foldl(self, fn(byte, acc) { acc * 256 + byte }, 0)
}

test empty_string_to_int() {
  to_int(#"") == 0
}

test string_to_int() {
  to_int(#"acab") == 44203
}

// leaving this for potential future work
test string_to_list_of_int() {
  bytearray.foldl(#"acab", fn(byte, acc) { list.push(acc, byte) }, []) == [
    171, 172,
  ]
  // #"acab" == bytearray.foldl(#"acab", flip(list.push), #"")
}

/// Computes greatest common divisor of two numbers.
///
/// ```aiken
/// maths.gcd(20, 15)
/// ```
pub fn gcd(a: Int, b: Int) -> Int {
  when b is {
    0 ->
      a
    _ ->
      gcd(b, a % b)
  }
}

test gcd_20_15() {
  gcd(20, 15) == 5
}

test gcd_124_8() {
  gcd(124, 8) == 4
}

test gcd_0_0() {
  gcd(0, 0) == 0
}

/// Computes the product of a list of integers.
///
/// ```aiken
/// maths.list_product([1,2,3])
/// ```
pub fn list_product(lst: List<Int>) -> Int {
  list.foldr(lst, fn(n, total) { n * total }, 1)
}

test empty_list_product() {
  list_product([]) == 1
}

test simple_list_product() {
  list_product([1, 2, 3]) == 6
}

/// Computes the power mod product of a list of integers.
///
/// ```aiken
/// maths.list_pow_mod([1,2,3], 2, 19)
/// ```
pub fn list_powmod(lst: List<Int>, g: Int, q: Int) -> Int {
  list.foldr(lst, fn(n, total) { total * powmod(g, n, q) }, 1) % q
}

test empty_list_power_mod() {
  list_powmod([], 2, 19) == 1
}

test simple_list_power_mod() {
  list_powmod([1, 2, 3], 2, 19) == 7
}
