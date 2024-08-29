use aiken/builtin
use aiken/collection/list
use assist/maths/constants.{large_prime}

/// Calculate `n` to the power of `e` modulo `q` using the exponentiation by 
/// squaring method. At each multiplication a modulo is calculated, allowing
/// very large `n` and `e` values.
///
/// ```aiken
/// maths.powmod(3, 2, 5)
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

/// Convert a integer `n` into some base `q`. This method
/// should scale with any integer and any logical base.
///
/// ```aiken
/// maths.base_q(123, 7)
/// ```
pub fn base_q(n: Int, q: Int) -> List<Int> {
  do_base_q(n, q, [])
}

// Internal only
fn do_base_q(number: Int, base: Int, holder: List<Int>) -> List<Int> {
  // if the number or base is zero return the holder list
  if or {
    number == 0,
    base == 0,
  } {
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

/// Convert a hexadecimal bytearray into its base 10 representation. This
/// only works with even length bytearrays so arbitrary numbers in hexadecimal
/// form will not in general work.
///
/// ```aiken
/// maths.to_int(#"acab")
/// ```
pub fn to_int(self: ByteArray) -> Int {
  builtin.bytearray_to_integer(True, self)
}

test empty_string_to_int() {
  to_int(#"") == 0
}

test string_to_int() {
  to_int(#"acab") == 44203
}

/// Convert a integer into a hexadecimal bytearray. This works for all integers
/// but odd length bytearrays will be prefixed with a zero. This function 
/// combined with the `to_int` function allows a string to represent a number
/// and still be used for calculations, pushing the `2^64 - 1` integer boundary.
///
/// ```aiken
/// maths.from_int(44203)
/// ```
pub fn from_int(self: Int) -> ByteArray {
  builtin.integer_to_bytearray(True, 0, self)
}

test odd_from_int() {
  let n: Int = 46118402439
  // odd length get prepended with a zero
  from_int(n) == #"0abcdef987"
}

test empty_from_int() {
  let str: ByteArray = #""
  let n: Int = to_int(str)
  from_int(n) == str
}

test simple_from_int() {
  let str: ByteArray = #"acab"
  let n: Int = to_int(str)
  from_int(n) == str
}

test complex_from_int() {
  let str: ByteArray = #"acabbeeffacecafe"
  let n: Int = to_int(str)
  from_int(n) == str
}

test from_big_int() {
  let str: ByteArray =
    #"0f69bd90956d98ace782567be7bb23ce2aecf6a525ba451795d21feb13220703b48b295a42cc7a86776cc9ad543f610f"
  let n: Int =
    2372285326153189929528332103442483377705667947278803297593729812983050665252776619156384486056106192189240939340047
  from_int(n) == str
}

test to_big_int() {
  let str: ByteArray =
    #"0f69bd90956d98ace782567be7bb23ce2aecf6a525ba451795d21feb13220703b48b295a42cc7a86776cc9ad543f610f"
  let n: Int =
    2372285326153189929528332103442483377705667947278803297593729812983050665252776619156384486056106192189240939340047
  to_int(str) == n
}
