//// This module contains mathematical routines.
////
//// To convert between integers and big-endian bytearrays, use stdlib's
//// `int.from_bytearray_big_endian` and `bytearray.from_int_big_endian(n, 0)`.
////

use aiken/collection/list
use maths/constants.{large_prime}

/// Calculate `n` to the power of `e` modulo `q` using the exponentiation by
/// squaring method. At each multiplication a modulo is calculated, allowing
/// very large `n` and `e` values. A negative exponent or a zero modulus
/// returns 0, and a zero exponent returns 1.
///
/// > [!TIP]
/// > Newer Plutus V3 protocol versions provide `builtin.exp_mod_integer`,
/// > which is much cheaper. It fails (instead of returning 0) on a zero
/// > modulus, and computes modular inverses for negative exponents.
///
/// ```aiken
/// routines.powmod(3, 2, 5)
/// ```
pub fn powmod(n: Int, e: Int, q: Int) -> Int {
  if or {
    e < 0,
    q == 0,
  } {
    // negative exponents and zero mod here
    // we can't handle this case so call it all zero
    0
  } else if e == 0 {
    // defined to be one, x^0 = 1 if x not zero but
    // when x is zero then you 0^0 = Nan, and one 
    // more validation check to run so to make it
    // cheaper just call it one
    1
  } else if e % 2 == 0 {
    // even case
    powmod(n * n % q, e / 2, q)
  } else {
    // odd case
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

test pow_0_0_1() {
  // sorry math
  powmod(0, 0, 1) == 1
}

test powmod_513_3_7() {
  powmod(513, 3, 7) == 1
}

test powmod_54_123_0() {
  powmod(54, 123, 0) == 0
}

test powmod_54_123_1() {
  powmod(54, 123, 1) == 0
}

test powmod_very_large1() {
  powmod(2, 6298875231651707927, large_prime) == 619257508790463606920652988927719175328304037643924550063346200106231201391121814124765664556886167107742014416823
}

test powmod_very_large2() {
  powmod(11024141354654159834, 6298875231651707927, large_prime) == 1281252237043588814874358657648283885922247063951636571913626407612926025965286114877878077927294143587983649997167
}

test powmod_very_large3() {
  powmod(
    1281252237043588814874358657648283885922247063951636571913626407612926025965286114877878077927294143587983649997167,
    6298875231651707927,
    large_prime,
  ) == 1375787197462284242586537174662214468532791477308429144007255343030157255268351835798245451858532190874833597636080
}

/// Convert a non-negative integer `n` into some base `q`. The digits are
/// returned most significant first. This method should scale with any
/// integer and any logical base. Zero (in any base) and base zero return the
/// empty list. A negative `n`, or a base of one or less (other than zero),
/// fails.
///
/// ```aiken
/// routines.base_q(123, 7)
/// ```
pub fn base_q(n: Int, q: Int) -> List<Int> {
  if q == 0 {
    []
  } else if q < 2 {
    // base one never shrinks the number and negative bases never terminate
    fail @"Invalid Base"
  } else if n < 0 {
    // floor division keeps a negative number negative forever
    fail @"Negative Number"
  } else {
    do_base_q(n, q, [])
  }
}

// Internal only
fn do_base_q(number: Int, base: Int, holder: List<Int>) -> List<Int> {
  // once the number is zero all the digits are in the holder list
  if number == 0 {
    holder
  } else {
    do_base_q(number / base, base, list.push(holder, number % base))
  }
}

test zero_in_base_zero() {
  base_q(0, 0) == []
}

test one_in_base_zero() {
  base_q(1, 0) == []
}

test base_one_fails() fail {
  base_q(10, 1) == []
}

test negative_base_fails() fail {
  base_q(10, -2) == []
}

test negative_number_fails() fail {
  base_q(-1, 2) == []
}

test zero_in_any_base() {
  base_q(0, 10) == []
}

test base_two() {
  base_q(10, 2) == [1, 0, 1, 0]
}

test simple_base_q() {
  base_q(17232, 4) == [1, 0, 0, 3, 1, 1, 0, 0]
}

test to_base_256() {
  base_q(78237623, 256) == [4, 169, 207, 183]
}

test to_base_large() {
  base_q(powmod(2, 15383577435643450949, large_prime), 15) == [
    12, 9, 14, 13, 5, 2, 11, 13, 5, 13, 10, 8, 5, 11, 10, 4, 7, 5, 11, 0, 10, 8,
    8, 8, 11, 6, 13, 3, 4, 14, 11, 10, 0, 12, 10, 11, 10, 0, 11, 8, 2, 3, 8, 13,
    0, 1, 5, 13, 0, 8, 13, 3, 10, 6, 4, 12, 14, 3, 7, 1, 11, 3, 7, 3, 14, 6, 8,
    4, 14, 3, 2, 7, 10, 14, 13, 10, 6, 8, 1, 7, 6, 13, 11, 10, 9, 12, 2, 13, 4,
    5, 14, 8, 5, 13, 3, 12, 12,
  ]
}
