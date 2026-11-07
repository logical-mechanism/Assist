//// Property-based tests for `types/registry`, the Schnorr proof of knowledge
//// over BLS12-381 G1.

use aiken/crypto/bitwise.{State}
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/scalar.{Scalar}
use aiken/fuzz
use aiken/primitive/bytearray
use types/registry.{Register}

// ## Fuzzers

fn nonzero_scalar() -> Fuzzer<Int> {
  fuzz.int_between(1, scalar.field_prime - 1)
}

/// The material for an honest proof.
type Scenario {
  // the secret
  x: Int,
  // the prover's random nonce
  r: Int,
  // a randomizer for the generator, so the generator is not always g1's
  d: Int,
  // the one-time bound
  bound: ByteArray,
}

fn scenario() -> Fuzzer<Scenario> {
  let x <- fuzz.and_then(nonzero_scalar())
  let r <- fuzz.and_then(nonzero_scalar())
  let d <- fuzz.and_then(nonzero_scalar())
  let bound <- fuzz.map(fuzz.bytearray_between(0, 32))
  Scenario { x, r, d, bound }
}

/// The register `(g, g^x)` for a randomized generator `g = g1^d`.
fn register(s: Scenario) -> Register {
  let g: G1Element = g1.generator |> g1.scale(scalar.from_int(s.d))
  Register {
    generator: g |> g1.compress,
    public_value: g |> g1.scale(scalar.from_int(s.x)) |> g1.compress,
  }
}

/// An honest proof `(z, g^r)` with `z = r + c * x` and the challenge `c`
/// computed with the Fiat-Shamir heuristic.
fn honest_proof(s: Scenario, datum: Register) -> (ByteArray, ByteArray) {
  let g_r_b: ByteArray = datum.generator
    |> g1.decompress
    |> g1.scale(scalar.from_int(s.r))
    |> g1.compress
  let c: State<Scalar> = registry.fiat_shamir_heuristic(
    datum.generator,
    g_r_b,
    datum.public_value,
    s.bound,
  )
    |> scalar.from_bytes
  let z: State<Scalar> = scalar.mul(c, scalar.from_int(s.x))
    |> scalar.add(scalar.from_int(s.r))
  (scalar.to_bytes(z), g_r_b)
}

// ## Properties

test prop_honest_proofs_verify(s via scenario()) {
  let datum = register(s)
  let (z_b, g_r_b) = honest_proof(s, datum)
  registry.prove(datum, z_b, g_r_b, s.bound)
}

test prop_proofs_are_bound_to_their_bound(s via scenario()) fail {
  // replaying a proof under another bound must not verify
  let datum = register(s)
  let (z_b, g_r_b) = honest_proof(s, datum)
  registry.prove(datum, z_b, g_r_b, bytearray.push(s.bound, 0))
}

test prop_proofs_with_the_wrong_secret_fail(s via scenario()) fail {
  let datum = register(s)
  let wrong = Scenario { ..s, x: s.x % ( scalar.field_prime - 1 ) + 1 }
  let (z_b, g_r_b) = honest_proof(wrong, datum)
  registry.prove(datum, z_b, g_r_b, s.bound)
}

test prop_proofs_do_not_transfer_to_other_registers(s via scenario()) fail {
  let datum = register(s)
  let (z_b, g_r_b) = honest_proof(s, datum)
  let other = register(
    Scenario { ..s, d: s.d % ( scalar.field_prime - 1 ) + 1 },
  )
  registry.prove(other, z_b, g_r_b, s.bound)
}

test prop_fiat_shamir_is_a_28_byte_digest(
  input via fuzz.tuple4(
    fuzz.bytearray_between(0, 48),
    fuzz.bytearray_between(0, 48),
    fuzz.bytearray_between(0, 48),
    fuzz.bytearray_between(0, 32),
  ),
) {
  let (g_b, g_r_b, u_b, b) = input
  bytearray.length(registry.fiat_shamir_heuristic(g_b, g_r_b, u_b, b)) == 28
}

test prop_fiat_shamir_depends_on_the_bound(
  input via fuzz.tuple(scenario(), fuzz.bytearray_between(1, 32)),
) {
  let (s, other_bound) = input
  let datum = register(s)
  let (_, g_r_b) = honest_proof(s, datum)
  let c1 = registry.fiat_shamir_heuristic(
    datum.generator,
    g_r_b,
    datum.public_value,
    s.bound,
  )
  let c2 = registry.fiat_shamir_heuristic(
    datum.generator,
    g_r_b,
    datum.public_value,
    bytearray.concat(s.bound, other_bound),
  )
  c1 != c2
}
