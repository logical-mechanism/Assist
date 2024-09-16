use aiken/crypto
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/scalar.{Scalar}
use aiken/primitive/bytearray

/// Alpha is the generator and beta is the public value. The pair is formed from
/// the relationship g^x = u, where g is the generator and u is the public value.
/// The value x is a secret integer used to create the public value from the 
/// generator.
pub type Register {
  // the generator, #<Bls12_381, G1>
  generator: ByteArray,
  // the public value, #<Bls12_381, G1>
  public_value: ByteArray,
}

/// This simulates randomizing a register. It is used for testing purposes only.
///
/// ```aiken
/// registry.randomize(register, random_scalar)
/// ```
fn randomize(datum: Register, s: Scalar) -> Register {
  // decompress the generator and public value
  let g: G1Element = g1.decompress(datum.generator)
  let u: G1Element = g1.decompress(datum.public_value)
  // now randomize the register elements
  let g_s: G1Element = g1.scale(g, s)
  let u_s: G1Element = g1.scale(u, s)
  // recompress the new randomized elements
  Register { generator: g_s |> g1.compress, public_value: u_s |> g1.compress }
}

test cheapest_hash() {
  // PASS [mem:    805, cpu:    2467639] expensive hash
  // crypto.keccak_256(#"") == #"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
  //
  // PASS [mem:    805, cpu:    1663641] cheap hash
  // crypto.sha3_256(#"") == #"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
  //
  // PASS [mem:    805, cpu:     434990] cheaper hash
  // crypto.sha2_256(#"") == #"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  //
  // PASS [mem:    805, cpu:     351411] cheapest hash
  crypto.blake2b_256(#"") == #"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"
  //
}

/// A bytearray of a value for the challenge c. This process should act like a
/// random oracle providing a large challenge value for the user. The inputs
/// should be compressed g1 elements but they can also be compressed integers.
///
/// ```aiken
/// registry.fiat_shamir_heuristic(g_b, g_r_b, u_b, b)
/// ```
fn fiat_shamir_heuristic(
  // compressed g element
  g_b: ByteArray,
  // compressed g^r element
  g_r_b: ByteArray,
  // compressed g^x element
  u_b: ByteArray,
  // a bound used to create one time transforms
  b: ByteArray,
) -> ByteArray {
  // concat g_b, g_r_b, u_b, and b together then hash the result using the 
  // blake2b_256 hash function as it is the cheapest on chain
  g_b
    |> bytearray.concat(g_r_b)
    |> bytearray.concat(u_b)
    |> bytearray.concat(b)
    |> crypto.blake2b_256()
}

test empty_fiat_shamir_transform() {
  fiat_shamir_heuristic(#"", #"", #"", #"") == #"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"
}

test real_fiat_shamir_transform() {
  fiat_shamir_heuristic(
    #"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
    #"81b223cea171a87feba9b7749a2df7601c5a75ae01155fadc124a2ac49099a514cf1e7d9cdc769dceab14a95bd6cb0bd",
    #"a09d99e02f7200526dc55ef722cc171e7aa14fc732614c02ac58d59d7026a7eb18d8798f6928ea2b513f3a4feb0c94d1",
    #"acab",
  ) == #"8f9409d05727322c9f2d1d0adf817b8d0e3a681977edc9ab866879a4a4f8f5b9"
}

/// A Schnorr proof to prove knowledge of the secret value x without revealing 
/// the value in the process. The proof uses, in multiplicative form, 
/// g^z = g^r * u^c, where z = r + c*x and u = g^x. This function uses the 
/// Fiat-Shamir heuristic for non-interactivity.
///
/// ```aiken
/// registry.prove(datum, z_b, g_r_b, bound)
/// ```
pub fn prove(
  datum: Register,
  z_b: ByteArray,
  g_r_b: ByteArray,
  bound: ByteArray,
) -> Bool {
  //
  // generator element
  let g: G1Element = g1.decompress(datum.generator)
  // public value element
  let u: G1Element = g1.decompress(datum.public_value)
  //
  // the z computation: g^z = g^(r + c * x) = g^r * g^(c * x) = g^r * (g^x)^c
  expect Some(z): Option<Scalar> = scalar.from_bytearray_big_endian(z_b)
  let g_z: G1Element = g1.scale(g, z)
  //
  // the g^r term: off-chain computation, uncompress into an element
  let g_r: G1Element = g1.decompress(g_r_b)
  //
  // use the fiat-shamir heuristic to calculate the challenge then convert it to an integer
  let c_b: ByteArray =
    fiat_shamir_heuristic(datum.generator, g_r_b, datum.public_value, bound)
  expect Some(c): Option<Scalar> = scalar.from_bytearray_big_endian(c_b)
  //
  // the u^c computation: u^c = (g^x)^c = g^(x * c)
  let u_c: G1Element = g1.scale(u, c)
  //
  // check if equation: g^z = g^r * u^c is true
  //
  g_z |> g1.equal(g1.add(g_r, u_c))
}

test valid_schnorr_proof() {
  // some secret x 
  expect Some(x): Option<Scalar> =
    scalar.new(
      42435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // the datum register using the g1 generator and the public value for x
  let datum: Register =
    Register {
      generator: g1.generator |> g1.compress,
      public_value: g1.generator |> g1.scale(x) |> g1.compress,
    }
  // a random number
  expect Some(r): Option<Scalar> =
    scalar.new(
      32435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // the bound, something unique from the tx
  let bound: ByteArray = #"acab"
  // calculate the g^r term
  let g: G1Element = g1.generator
  let g_r: G1Element = g1.scale(g, r)
  let g_r_b: ByteArray = g_r |> g1.compress
  // the challenge number using a fiat shamir transform
  let c_b: ByteArray =
    fiat_shamir_heuristic(datum.generator, g_r_b, datum.public_value, bound)
  expect Some(c): Option<Scalar> = scalar.from_bytearray_big_endian(c_b)
  // the z value
  let z: Scalar = scalar.mul(c, x) |> scalar.add(r)
  let z_b: ByteArray = scalar.to_bytearray_big_endian(z, 0)
  prove(datum, z_b, g_r_b, bound)
}

test randomized_valid_schnorr_proof() {
  // some secret x 
  expect Some(x): Option<Scalar> =
    scalar.new(
      12435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // the datum register using the g1 generator and the public value for x
  let datum: Register =
    Register {
      generator: g1.generator |> g1.compress,
      public_value: g1.generator |> g1.scale(x) |> g1.compress,
    }
  // a random number
  expect Some(r): Option<Scalar> =
    scalar.new(
      32435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // another random number
  expect Some(d): Option<Scalar> =
    scalar.new(
      12435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // rerandomize the a0 register
  let datum_rng: Register = randomize(datum, d)
  // the bound, something unique from the tx
  let bound: ByteArray = #"acabface"
  // calculate the g^r term
  let g: G1Element = datum_rng.generator |> g1.decompress
  let g_r: G1Element = g1.scale(g, r)
  let g_r_b: ByteArray = g_r |> g1.compress
  // the challenge number using a fiat shamir transform
  let c_b: ByteArray =
    fiat_shamir_heuristic(
      datum_rng.generator,
      g_r_b,
      datum_rng.public_value,
      bound,
    )
  expect Some(c): Option<Scalar> = scalar.from_bytearray_big_endian(c_b)
  // the z value
  let z: Scalar = scalar.mul(c, x) |> scalar.add(r)
  let z_b: ByteArray = scalar.to_bytearray_big_endian(z, 0)
  prove(datum_rng, z_b, g_r_b, bound)
}

test invalid_schnorr_proof() fail {
  // some secret x 
  expect Some(x): Option<Scalar> =
    scalar.new(
      42435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // the datum register using the g1 generator and the public value for x
  let datum: Register =
    Register {
      generator: g1.generator |> g1.compress,
      public_value: g1.generator |> g1.scale(x) |> g1.compress,
    }
  // a random number
  expect Some(r): Option<Scalar> =
    scalar.new(
      32435875175126190479447740508185965837690552500527637822603658699938581184513,
    )
  // the bound, something unique from the tx
  let bound: ByteArray = #""
  // calculate the g^r term
  let g: G1Element = g1.generator
  let g_r: G1Element = g1.scale(g, r)
  let g_r_b: ByteArray = g_r |> g1.compress
  // the challenge number using a fiat shamir transform
  let c_b: ByteArray =
    fiat_shamir_heuristic(datum.generator, g_r_b, datum.public_value, bound)
  expect Some(c): Option<Scalar> = scalar.from_bytearray_big_endian(c_b)
  // the bad z value, it assumes the secret is the challenge
  let z: Scalar = scalar.mul(c, c) |> scalar.add(r)
  let z_b: ByteArray = scalar.to_bytearray_big_endian(z, 0)
  prove(datum, z_b, g_r_b, bound)
}
