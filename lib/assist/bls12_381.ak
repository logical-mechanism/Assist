use aiken/builtin
use assist/maths

pub fn g1() -> G1Element {
  builtin.bls12_381_g1_uncompress(
    #"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
  )
}

pub fn g2() -> G2Element {
  builtin.bls12_381_g2_uncompress(
    #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
  )
}

pub fn pkh(sk: Int) -> G1Element {
  builtin.bls12_381_g1_scalar_mul(sk, g1())
}

pub fn message(msg: ByteArray) -> G2Element {
  builtin.bls12_381_g2_hash_to_group(msg, #"acab")
}

pub fn signature(msg: G2Element, sk: Int) -> G2Element {
  builtin.bls12_381_g2_scalar_mul(sk, msg)
}

pub fn verify(msg: G2Element, sig: G2Element, pkh: G1Element) {
  let hash_pubkey_pairing = builtin.bls12_381_miller_loop(pkh, msg)
  let sig_g2base_pairing = builtin.bls12_381_miller_loop(g1(), sig)
  builtin.bls12_381_final_verify(hash_pubkey_pairing, sig_g2base_pairing)
}

test a_good_verify() {
  let m = message(#"acab")
  let sk = 44203
  let pk = pkh(sk)
  let sig = signature(m, sk)
  verify(m, sig, pk) == True
}

pub fn schnorr(
  zb: ByteArray,
  g_r: G1Element,
  cb: ByteArray,
  u: G1Element,
) -> Bool {
  let z: Int = maths.to_int(zb)
  let c: Int = maths.to_int(cb)
  let g: G1Element = g1()
  let g_z: G1Element = builtin.bls12_381_g1_scalar_mul(z, g)
  let u_c: G1Element = builtin.bls12_381_g1_scalar_mul(c, u)
  let rhs: G1Element = builtin.bls12_381_g1_add(g_r, u_c)
  builtin.bls12_381_g1_equal(g_z, rhs)
}

test simple_equation() {
  let r =
    77490303739974054145119935316592548272982739131044458644839550149600493136340
  let g_r: G1Element = builtin.bls12_381_g1_scalar_mul(r, g1())
  let c =
    88500062147277737236137376003874391431206685245040607685717906676919627111610
  let cb = maths.from_int(c)
  let x =
    73267758606470301193940624502170104841068192775372443018163580244558527065642
  let u: G1Element = pkh(x)
  let z = r + c * x
  let zb = maths.from_int(z)
  schnorr(zb, g_r, cb, u)
}
// test get_g1_ele_cbor1() {
//   let test_data_structure: G1Element = g1()
//   builtin.bls12_381_g1_compress(test_data_structure) == #"b247618bc6c1b196e6d7116cfe510acfcb742f946964738c0787090f370663d0d24d136d7953d5a3cf37ce36c2e36532"
// }

// test get_g1_ele_cbor2() {
//   let test_data_structure: G1Element = g1()
//   let x =
//     #"b247618bc6c1b196e6d7116cfe510acfcb742f946964738c0787090f370663d0d24d136d7953d5a3cf37ce36c2e36532"
//   builtin.bls12_381_g1_uncompress(x) == test_data_structure
// }

// /// This is used to prove that the rerandomizing was real.
// pub fn dht(
//   aa: ByteArray,
//   ab: ByteArray,
//   ba: ByteArray,
//   bb: ByteArray,
//   zb: ByteArray,
//   rb: ByteArray,
//   cb: ByteArray,
// ) -> Bool {
//   let a: Int = builtin.bls12_381_g1_uncompress(aa)
//   let b: Int = builtin.bls12_381_g1_uncompress(ab)
//   let a0: Int = builtin.bls12_381_g1_uncompress(ba)
//   let b0: Int = maths.to_int(bb)
//   let q: Int = maths.large_prime
//   and {
//     (maths.powmod(a, z, q) == maths.powmod(a, r, q) * maths.powmod(a0, c, q) % q)?,
//     (maths.powmod(b, z, q) == maths.powmod(b, r, q) * maths.powmod(b0, c, q) % q)?,
//   }
// }
