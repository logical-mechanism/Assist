//// This module incorporates code for various mathematical operations.
////

use aiken/bytearray
use aiken/list
use aiken/math

/// Calculate `n` to the power of `e` modulo `q` using the exponentiation by 
/// squaring method. At each multiplication a modulo is calculated, allowing
/// very large `n` and `e` values.
///
/// ```aiken
/// maths.powmod(3, 2, 5)
/// ```
pub fn powmod(n: Int, e: Int, q: Int) -> Int {
  if e < 0 || q == 0 {
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

/// Convert a integer `n` into some base `q`. This method
/// should scale with any integer and any logical base.
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
  bytearray.foldl(self, 0, fn(byte, acc) { acc * 256 + byte })
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
/// and still be used for calculations, pushing the `2^64 - 1` integer boundary
/// to `2^256 - 1`.
///
/// ```aiken
/// maths.from_int(44203)
/// ```
pub fn from_int(self: Int) -> ByteArray {
  let base_256 = base_q(self, 256)
  list.foldr(base_256, #"", fn(n, total) { bytearray.push(total, n) })
}

test odd_from_int() {
  let n = 46118402439
  // odd length get prepended with a zero
  from_int(n) == #"0abcdef987"
}

test empty_from_int() {
  let str = #""
  let n = to_int(str)
  from_int(n) == str
}

test simple_from_int() {
  let str = #"acab"
  let n = to_int(str)
  from_int(n) == str
}

test complex_from_int() {
  let str = #"acabbeeffacecafe"
  let n = to_int(str)
  from_int(n) == str
}

/// Computes greatest common divisor of two numbers.
///
/// ```aiken
/// maths.gcd(20, 15)
/// ```
pub fn gcd(a: Int, b: Int) -> Int {
  when b is {
    0 -> a
    _ -> gcd(b, a % b)
  }
}

test gcd_20_15() {
  gcd(20, 15) == 5
}

test gcd_124_8() {
  gcd(124, 8) == 4
}

test gcd_48_18() {
  gcd(48, 18) == 6
}

test gcd_0_0() {
  gcd(0, 0) == 0
}

/// Calculate the Legendre symbol `(a/p)` using the Euler's criterion.
/// This implementation assumes that 'a' and 'p' are positive integers.
///
/// ```aiken
/// maths.legendre_symbol(10, 19)
/// ```
pub fn legendre_symbol(a: Int, p: Int) -> Int {
  if a % p == 0 {
    0
  } else if powmod(a, ( p - 1 ) / 2, p) == 1 {
    1
  } else {
    -1
  }
}

test ls_2_3() {
  legendre_symbol(2, 3) == -1
}

test ls_7_7() {
  legendre_symbol(7, 7) == 0
}

test ls_7_3() {
  legendre_symbol(7, 3) == 1
}

/// Computes the product of a list of integers.
///
/// ```aiken
/// maths.list_product([1,2,3])
/// ```
pub fn list_product(lst: List<Int>) -> Int {
  list.foldr(lst, 1, fn(n, total) { n * total })
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
  list.foldr(lst, 1, fn(n, total) { total * powmod(g, n, q) }) % q
}

test empty_list_power_mod() {
  list_powmod([], 2, 19) == 1
}

test simple_list_power_mod() {
  list_powmod([1, 2, 3], 2, 19) == 7
}

/// Computes the sum of a list of integers.
///
/// ```aiken
/// maths.list_sum(list_of_integers)
/// ```
pub fn list_sum(lst: List<Int>) -> Int {
  list.foldr(lst, 0, fn(n, total) { total + n })
}

test empty_list_sum() {
  list_sum([]) == 0
}

test simple_list_sum() {
  list_sum([1, 2, 3]) == 6
}

test complex_list_sum() {
  list_sum([1, 2, 3, -3, -2, -1]) == 0
}

/// Decay some starting amount logarithmically until zero. The function evaluates
/// `y = a - log(n)` and when `n >= 2^a` the function equals zero but will return
/// zero whenever the result is less than the scale. This is a great
/// way to reduce some integer amount of something over time by incrementing `n`.
///
/// ```aiken
/// maths.decay(start_amount, lovelace_scaling, datum.current_int)
/// ```
pub fn decay(start_amt: Int, scale: Int, num: Int) -> Int {
  let val = ( start_amt - math.log(num, 2) ) * scale
  if val <= scale {
    0
  } else {
    val
  }
}

test no_decay() {
  decay(18, 1, 0) == 18
}

test small_decay() {
  decay(18, 1, 123) == 12
}

test large_decay() {
  decay(18, 1, 123456) == 2
}

test perfect_decay() {
  decay(18, 1, math.pow(2, 18)) == 0
}

test total_decay() {
  decay(18, 1, 1234567) == 0
}

/// Verify that some integer `n` is greater than the lower bound, `lb`, and
/// less than or equal to the upper bound, `ub`. The function is exclusive
/// for `lb` but inclusive for `lb + 1`.
///
/// ```aiken
/// maths.is_in_range(5, 0, 10)
/// ```
pub fn is_in_range(n: Int, lb: Int, ub: Int) -> Bool {
  n > lb && n <= ub
}

test inclusive_range() {
  is_in_range(0, 0, 10) == False && is_in_range(10, 0, 10) == True
}

test it_is_in_range() {
  is_in_range(123, 0, 1000) == True
}

test it_is_not_in_range() {
  is_in_range(123, 0, 100) == False
}

/// Calculates the ratio of the amount `amt` by a percentage `pct`. This can
/// be used to calculate rough percentages. The function `ratio` is just a 
/// special case of the effective ratio function. 
///
/// ```aiken
/// maths.ratio(123, 40)
/// ```
pub fn ratio(amt: Int, pct: Int) -> Int {
  effective_ratio(amt, pct, 1)
}

test zero_ratio() {
  ratio(0, 1) == 0 && ratio(1, 0) == 0
}

// 2.5%
test simple_ratio() {
  ratio(123, 40) == 3
}

// 25%
test complex_ratio() {
  ratio(125000000, 4) == 31250000
}

/// Calculates the ratio of the amount `amt` multiplied by the scale by the
/// percentage `pct`. The scale allows for finer calculations.
///
/// ```aiken
/// maths.effective_ratio(123456789, 40, 1000) == 3086419725
/// ```
pub fn effective_ratio(amt: Int, pct: Int, scale: Int) -> Int {
  if pct <= 0 {
    0
  } else {
    scale * amt / pct
  }
}

test zero_effective_ratio() {
  and {
    effective_ratio(0, 1, 1) == 0,
    effective_ratio(1, 0, 1) == 0,
    effective_ratio(1, 1, 0) == 0,
  }
}

test simple_effective_ratio() {
  and {
    effective_ratio(123, 40, 1) == 3,
    effective_ratio(123, 40, 10) == 30,
    effective_ratio(123, 40, 100) == 307,
    effective_ratio(123, 40, 1000) == 3075,
    effective_ratio(123, 40, 10000) == 30750,
    effective_ratio(123, 40, 100000) == 307500,
    effective_ratio(123, 40, 1000000) == 3075000,
  }
}

test complex_effective_ratio() {
  effective_ratio(123456789, 40, 1000) == 3086419725
}

/// Find the optimal scaling for a number such that it
/// has three trailing zeros. This should be used in combination
/// with the effective ratio for optimal calculations.
///
/// ```aiken
/// maths.scaling(123, 40)
/// ```
pub fn scaling(amt: Int, pct: Int) -> Int {
  calculate_scale(amt, pct, 1, 3, 0)
}

test simple_scaling() {
  scaling(123, 40) == 1000000
}

test complex_scaling() {
  scaling(123456789, 40) == 1000000
}

test complex_scaling2() {
  scaling(583872739578289, 4) == 100000
}

test even_scaling() {
  scaling(125000000, 4) == 1
}

test never_ending_scaling() {
  // 15 here is the max depth
  scaling(123456789, 39) == math.pow(10, 15)
}

test never_ending_scaling2() {
  // 15 here is the max depth
  scaling(123456789, 13) == math.pow(10, 15)
}

test simple_digit_count() {
  math.log(12345, 10) == 5 - 1
}

test moderate_digit_count() {
  math.log(123456789, 10) == 9 - 1
}

fn calculate_scale(
  amt: Int,
  pct: Int,
  scale: Int,
  bound: Int,
  depth: Int,
) -> Int {
  let er = effective_ratio(amt, pct, scale)
  let max_depth = 15
  // the max depth determines irrationals, largest scaling is then 10^max_depth
  if er == 0 || depth >= max_depth {
    scale
  } else {
    if er % 10 == 0 {
      if count_zeros(er, 0) >= bound {
        scale
      } else {
        calculate_scale(amt, pct, 10 * scale, bound, depth + 1)
      }
    } else {
      calculate_scale(amt, pct, 10 * scale, bound, depth + 1)
    }
  }
}

test simple_calculate_scale() {
  calculate_scale(123, 40, 1, 3, 0) == 1000000
}

test complex_calculate_scale() {
  calculate_scale(123456789, 40, 1, 5, 0) == 100000000
}

test even_calculate_scale() {
  calculate_scale(125000000, 4, 1, 3, 0) == 1
}

test zero_calculate_scale() {
  calculate_scale(0, 4, 1, 3, 0) == 1
}

// count the number of zeros at the end of a number
fn count_zeros(number: Int, counter: Int) -> Int {
  if number % 10 == 0 {
    count_zeros(number / 10, counter + 1)
  } else {
    counter
  }
}

test zero_zeros() {
  count_zeros(3, 0) == 0
}

test one_zeros() {
  count_zeros(30, 0) == 1
}

test three_zeros() {
  count_zeros(3075000, 0) == 3
}
