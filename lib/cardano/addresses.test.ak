//// Property-based tests for `cardano/addresses`.

use aiken/fuzz
use aiken/primitive/bytearray
use cardano/address.{Inline, Script, VerificationKey}
use cardano/addresses
use types/wallet.{Wallet}

// ## Fuzzers

fn key_hash() -> Fuzzer<ByteArray> {
  fuzz.bytearray_fixed(28)
}

/// A stake credential candidate: empty, valid, or of some wrong length.
fn maybe_stake() -> Fuzzer<ByteArray> {
  fuzz.either3(fuzz.constant(#""), key_hash(), fuzz.bytearray_between(1, 40))
}

fn wrong_length() -> Fuzzer<ByteArray> {
  fuzz.such_that(
    fuzz.bytearray_between(0, 40),
    fn(b) { bytearray.length(b) != 28 },
  )
}

fn valid_wallet() -> Fuzzer<Wallet> {
  fuzz.map2(
    key_hash(),
    fuzz.either(fuzz.constant(#""), key_hash()),
    fn(pkh, sc) { Wallet { pkh, sc } },
  )
}

fn invalid_wallet() -> Fuzzer<Wallet> {
  fuzz.either(
    // a bad payment key hash, any stake
    fuzz.map2(wrong_length(), maybe_stake(), fn(pkh, sc) { Wallet { pkh, sc } }),
    // a good payment key hash, a non-empty stake of the wrong length
    fuzz.map2(
      key_hash(),
      fuzz.such_that(wrong_length(), fn(b) { !bytearray.is_empty(b) }),
      fn(pkh, sc) { Wallet { pkh, sc } },
    ),
  )
}

// ## Properties

test prop_create_address_shape(input via fuzz.tuple(key_hash(), maybe_stake())) {
  let (pkh, sc) = input
  let addr = addresses.create_address(pkh, sc)
  let is_base = bytearray.length(sc) == 28
  fuzz.label_when(is_base, @"base address", @"enterprise address")
  let expected_stake = if is_base {
    Some(Inline(VerificationKey(sc)))
  } else {
    None
  }
  and {
    addr.payment_credential == VerificationKey(pkh),
    addr.stake_credential == expected_stake,
  }
}

test prop_create_script_address_shape(
  input via fuzz.tuple(key_hash(), maybe_stake()),
) {
  let (vkh, sc) = input
  let addr = addresses.create_script_address(vkh, sc)
  let is_base = bytearray.length(sc) == 28
  fuzz.label_when(is_base, @"base address", @"enterprise address")
  let expected_stake = if is_base {
    Some(Inline(Script(sc)))
  } else {
    None
  }
  and {
    addr.payment_credential == Script(vkh),
    addr.stake_credential == expected_stake,
  }
}

test prop_wallet_and_script_addresses_differ(
  input via fuzz.tuple(key_hash(), maybe_stake()),
) {
  let (hash, sc) = input
  addresses.create_address(hash, sc) != addresses.create_script_address(
    hash,
    sc,
  )
}

test prop_from_wallet_accepts_valid_wallets(w via valid_wallet()) {
  addresses.from_wallet(w) == addresses.create_address(w.pkh, w.sc)
}

test prop_from_wallet_rejects_invalid_wallets(w via invalid_wallet()) fail {
  addresses.from_wallet(w).payment_credential == VerificationKey(w.pkh)
}
