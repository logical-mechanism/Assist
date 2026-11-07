//// Property-based tests for `maths/routines`.

use aiken/builtin
use aiken/collection/list
use aiken/fuzz
use aiken/math
use aiken/primitive/bytearray
use maths/constants
use maths/routines

// ## Fuzzers

fn prime() -> Fuzzer<Int> {
  fuzz.one_of([2, 3, 5, 7, 11, 13, 251, 44203, 65537, constants.large_prime])
}

/// A modulus of at least two, small or very large.
fn modulus() -> Fuzzer<Int> {
  fuzz.either3(
    fuzz.int_between(2, 1000),
    prime(),
    fuzz.int_between(2, constants.large_prime),
  )
}

/// A non-negative integer, small or very large.
fn natural() -> Fuzzer<Int> {
  fuzz.either3(
    fuzz.int_between(0, 300),
    fuzz.int_between(0, 1_000_000_000),
    fuzz.int_between(0, constants.large_prime * constants.large_prime),
  )
}

// ## powmod

test prop_powmod_matches_naive_power(
  input via fuzz.tuple3(
    fuzz.int_between(-50, 50),
    fuzz.int_between(0, 30),
    fuzz.int_between(1, 1000),
  ),
) {
  let (n, e, q) = input
  // powmod defines any zeroth power as one, even modulo one
  let expected = if e == 0 {
    1
  } else {
    math.pow(n, e) % q
  }
  routines.powmod(n, e, q) == expected
}

test prop_powmod_matches_builtin_exp_mod(
  input via fuzz.tuple3(
    fuzz.int_between(-1000, constants.large_prime),
    natural(),
    modulus(),
  ),
) {
  let (n, e, q) = input
  routines.powmod(n, e, q) == builtin.exp_mod_integer(n, e, q)
}

test prop_powmod_product_rule(
  input via fuzz.tuple4(
    natural(),
    fuzz.int_between(0, 10_000),
    fuzz.int_between(0, 10_000),
    modulus(),
  ),
) {
  let (n, a, b, q) = input
  routines.powmod(n, a + b, q) == routines.powmod(n, a, q) * routines.powmod(
    n,
    b,
    q,
  ) % q
}

test prop_powmod_fermat_little_theorem(
  input via fuzz.tuple3(prime(), natural(), fuzz.int_between(1, 1000)),
) {
  // n = k * p + r with 0 < r < p is never divisible by p
  let (p, k, r) = input
  let n = k * p + r % p
  if r % p == 0 {
    // r was a multiple of p, nothing to check
    True
  } else {
    routines.powmod(n, p - 1, p) == 1
  }
}

test prop_powmod_out_of_domain_is_zero(
  input via fuzz.tuple3(
    fuzz.int_between(-1000, 1000),
    fuzz.int_between(-1000, 1000),
    fuzz.int_between(-1000, 1000),
  ),
) {
  let (n, e, q) = input
  if e < 0 || q == 0 {
    routines.powmod(n, e, q) == 0
  } else {
    True
  }
}

// ## base_q

test prop_base_q_round_trips(
  input via fuzz.tuple(natural(), fuzz.int_between(2, 300)),
) {
  let (n, q) = input
  list.foldl(routines.base_q(n, q), 0, fn(digit, acc) { acc * q + digit }) == n
}

test prop_base_q_digits_are_canonical(
  input via fuzz.tuple(natural(), fuzz.int_between(2, 300)),
) {
  let (n, q) = input
  let digits = routines.base_q(n, q)
  and {
    list.all(digits, fn(d) { d >= 0 && d < q }),
    // no leading zero, and zero has no digits at all
    when digits is {
      [] -> n == 0
      [first, ..] -> first != 0
    },
    // the expected number of digits
    if n == 0 {
      True
    } else {
      list.length(digits) == math.log(n, q) + 1
    },
  }
}

test prop_base_256_matches_big_endian_bytes(n via natural()) {
  let bytes = bytearray.from_int_big_endian(n, 0)
  routines.base_q(n, 256) == bytearray.foldr(
    bytes,
    [],
    fn(b, acc) { [b, ..acc] },
  )
}

test prop_base_q_rejects_negative_numbers(
  input via fuzz.tuple(
    fuzz.int_between(-1_000_000, -1),
    fuzz.int_between(2, 300),
  ),
) fail {
  let (n, q) = input
  list.length(routines.base_q(n, q)) >= 0
}

test prop_base_q_rejects_bases_below_two(
  // base zero is the documented exception and returns the empty list
  input via fuzz.tuple(
    natural(),
    fuzz.either(fuzz.int_between(-300, -1), fuzz.constant(1)),
  ),
) fail {
  let (n, q) = input
  list.length(routines.base_q(n, q)) >= 0
}
