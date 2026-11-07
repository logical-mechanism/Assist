//// This module contains code that aids in various value manipulations and
//// comparisons.
////
//// Everything here operates on the stdlib `Assets` type, which is the
//// multi-asset map found on transaction inputs, outputs, and the mint field.
//// stdlib v4 renamed the old `Value` type to `Assets`; the name `Value` now
//// refers to the builtin UPLC value handled by stdlib's `cardano/value`.
////
//// This module used to be called `cardano/value`. It was renamed to
//// `cardano/values` because stdlib v4 now ships its own `cardano/value`.
////

use aiken/collection/dict
use aiken/collection/list
use aiken/crypto
use aiken/primitive/bytearray
use aiken/primitive/string
use cardano/assets.{AssetName, Assets, PolicyId}
use cardano/transaction.{TransactionId}
use types/cip68
use types/token.{Token, Tokens}

/// Creates an `Assets` from a token.
///
/// ```aiken
/// values.from_token(this_token)
/// ```
pub fn from_token(token: Token) -> Assets {
  assets.from_asset(token.pid, token.tkn, token.amt)
}

test token_to_value() {
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let expected: Assets = assets.from_lovelace(10)
  from_token(token) == expected
}

/// Creates an `Assets` from a list of tokens. Quantities of tokens that share
/// a policy id and asset name are summed.
///
/// ```aiken
/// values.from_tokens(redeemer.tokens)
/// ```
pub fn from_tokens(tokens: Tokens) -> Assets {
  token.add_tokens_to_value(assets.zero, tokens)
}

test tokens_to_value() {
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let expected: Assets = assets.from_lovelace(20)
  from_tokens([token, token]) == expected
}

/// Multiply some value by `n`. This is a linear scaling of the quantity of
/// each token. Multiplying by zero returns `assets.zero`.
///
/// > [!TIP]
/// > For the builtin `Value` type, stdlib provides `cardano/value.{scale}`.
///
/// ```aiken
/// values.multiply(bundle_value, bundle_size)
/// ```
pub fn multiply(val: Assets, n: Int) -> Assets {
  if n == 0 {
    assets.zero
  } else {
    // Scaling by a non-zero integer keeps every quantity non-zero and keeps
    // the key ordering, so the result is a valid `Assets` map as-is.
    val
      |> assets.to_pairs()
      |> list.map(
          fn(Pair(pid, tokens)) {
            Pair(pid, dict.map(tokens, fn(_, amt) { n * amt }))
          },
        )
      |> assets.from_ascending_pairs()
  }
}

test values_multiply_by_0() {
  let val: Assets = assets.from_lovelace(100)
  let ans: Assets = assets.zero
  multiply(val, 0) == ans
}

test values_multiply_by_4() {
  let val: Assets = assets.from_lovelace(100)
  let ans: Assets = assets.from_lovelace(400)
  multiply(val, 4) == ans
}

test values_multiply_by_52314523() {
  let val: Assets = assets.from_lovelace(2)
  let ans: Assets = assets.from_lovelace(104629046)
  multiply(val, 52314523) == ans
}

test values_multiply_by_negative() {
  let val: Assets = assets.from_lovelace(2) |> assets.add(#"acab", #"beef", 3)
  let ans: Assets = assets.from_lovelace(-4) |> assets.add(#"acab", #"beef", -6)
  multiply(val, -2) == ans
}

/// Prove that the target value is contained inside another value. Each token
/// inside the target must exist inside the total value. The quantity of each
/// token must be at least the target amount or greater. A negative target
/// quantity is always satisfied.
///
/// > [!TIP]
/// > For the builtin `Value` type, stdlib provides `cardano/value.{contains}`.
/// > That version fails on negative quantities.
///
/// ```aiken
/// values.contains(total_value, target_value)
/// ```
pub fn contains(total: Assets, target: Assets) -> Bool {
  assets.reduce(
    target,
    True,
    fn(pid, tkn, amt, ok) { ok && assets.quantity_of(total, pid, tkn) >= amt },
  )
}

test value_contains_lovelace() {
  let target: Assets = assets.from_lovelace(10)
  let total: Assets = assets.from_lovelace(100)
  contains(total, target) == True
}

test value_contains_tokens() {
  let target: Assets = assets.from_asset(#"acab", #"beef", 10)
  let total: Assets = assets.from_asset(#"acab", #"beef", 40)
  contains(total, target) == True
}

test value_contains_both() {
  let target: Assets = assets.from_lovelace(10)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 2))
    |> assets.merge(assets.from_asset(#"cafe", #"face", 10))
  let total: Assets = assets.from_lovelace(100)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 10))
    |> assets.merge(assets.from_asset(#"cafe", #"face", 40))
    |> assets.merge(assets.from_asset(#"beef", #"face", 40))
    |> assets.merge(assets.from_asset(#"face", #"beef", 40))
  contains(total, target) == True
}

test value_contains_nothing() {
  let target: Assets = assets.from_lovelace(10)
  let total: Assets = assets.from_asset(#"acab", #"beef", 40)
  contains(total, target) == False
}

test value_contains_one_short() {
  let target: Assets = assets.from_asset(#"acab", #"beef", 41)
  let total: Assets = assets.from_asset(#"acab", #"beef", 40)
  contains(total, target) == False
}

test zero_is_always_contained() {
  contains(assets.zero, assets.zero) && contains(
    assets.from_lovelace(1),
    assets.zero,
  )
}

/// Compute the blake2b_256 hash of a value by merklizing the policy id, asset
/// name, and quantity. Empty values return the empty bytearray.
///
/// The assets are folded in ascending policy id and asset name order. Each
/// step computes `blake2b_256(pid ++ tkn ++ blake2b_256(string(amt)) ++ acc)`.
///
/// ```aiken
/// values.compute_hash(validating_value)
/// ```
pub fn compute_hash(target: Assets) -> ByteArray {
  dict.foldl(
    assets.to_dict(target),
    #"",
    fn(pid, tokens, acc) {
      dict.foldl(
        tokens,
        acc,
        fn(tkn, amt, acc) {
          pid
            |> bytearray.concat(tkn)
            |> bytearray.concat(int_to_hash(amt))
            |> bytearray.concat(acc)
            |> crypto.blake2b_256()
        },
      )
    },
  )
}

// Hash the decimal string representation of an integer.
// Internal only
fn int_to_hash(num: Int) -> ByteArray {
  string.from_int(num) |> bytearray.from_string() |> crypto.blake2b_256()
}

test hash_empty_value() {
  let val: Assets = assets.zero
  compute_hash(val) == #""
}

test hash_lovelace_value() {
  let val: Assets = assets.from_lovelace(100)
  compute_hash(val) == #"a0f9d2a93b035c0480612cd839d88c355e134f847d0417256708b0fa8403c652"
}

test hash_large_value() {
  let val: Assets = assets.from_lovelace(100)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 10))
    |> assets.merge(assets.from_asset(#"cafe", #"face", 40))
    |> assets.merge(assets.from_asset(#"beef", #"face", 40))
    |> assets.merge(assets.from_asset(#"face", #"beef", 40))
  compute_hash(val) == #"249b0e98af109a92da4f70c2258b7a01beaeea3a0433f8459c8eaadbd7e7a383"
}

/// Calculate a unique token name from a `TxId#Idx`, a prefix, and a personal
/// tag. Can be combined with the `find` module to create unique token names
/// from the first input utxo inside the transaction.
///
/// The name is `prefix ++ personal[0..15] ++ index ++ txid`, truncated to 32
/// bytes. An index below 256 is encoded as one byte. A larger index is encoded
/// as its minimal big-endian bytes. A negative index fails.
///
/// ```aiken
/// values.unique_token_name(tx_id, tx_idx, cip68.prefix_333, personal_tag)
/// ```
pub fn unique_token_name(
  txid: TransactionId,
  idx: Int,
  prefix: ByteArray,
  personal: ByteArray,
) -> AssetName {
  // prefix the txid with the index
  let prepend_index: ByteArray = if idx < 256 {
    bytearray.push(txid, idx)
  } else {
    bytearray.concat(bytearray.from_int_big_endian(idx, 0), txid)
  }
  // the personal part max length is 15
  let trimmed_personal: ByteArray = bytearray.slice(personal, 0, 14)
  // concat the name
  let prepend_prefix: ByteArray = prefix
    |> bytearray.concat(trimmed_personal)
    |> bytearray.concat(prepend_index)
  // keep the first 32 bytes
  bytearray.slice(prepend_prefix, 0, 31)
}

test no_prefix_token_name() {
  // the zero becomes the prefix
  unique_token_name(#"", 0, #"", #"") == #"00"
}

test prefix_222_token_name() {
  let tkn: AssetName = unique_token_name(#"", 0, cip68.prefix_222, #"")
  // the prefixes all have length 4
  bytearray.take(tkn, 4) == cip68.prefix_222
}

test real_token_name() {
  let tkn: AssetName = unique_token_name(
    #"82fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84af4b9b9bddad91f",
    0,
    cip68.prefix_100,
    #"",
  )
  tkn == #"000643b00082fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84af4b9"
}

test personal_tag_token_name() {
  let tkn: AssetName = unique_token_name(
    #"82fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84af4b9b9bddad91f",
    1,
    cip68.prefix_222,
    #"acab",
  )
  tkn == #"000de140acab0182fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84a"
}

test personal_tag_is_truncated_to_15_bytes() {
  let long_tag: ByteArray = #"0102030405060708090a0b0c0d0e0f1011"
  let tkn: AssetName = unique_token_name(#"", 7, #"", long_tag)
  tkn == #"0102030405060708090a0b0c0d0e0f07"
}

test large_index_token_name() {
  // indexes above 255 no longer halt; they use two (or more) bytes
  let tkn: AssetName = unique_token_name(#"acab", 300, #"", #"")
  tkn == #"012cacab"
}

test negative_index_token_name() fail {
  unique_token_name(#"acab", -1, #"", #"") == #""
}

/// Proves that inside some value there is a policy id with a single token
/// name that has a quantity of 1. Other policies are tolerated. This will
/// show that a value contains an NFT or something that is nft-like. Should be
/// useful to prove that something is holding a token inside a transaction
/// when the token name is assumed to be unique.
///
/// > [!NOTE]
/// > This sits between stdlib's `assets.has_any_nft` (tolerates other names
/// > under the policy) and `assets.has_any_nft_strict` (tolerates nothing
/// > besides Ada).
///
/// ```aiken
/// values.prove_nft(this_value, pid)
/// ```
pub fn prove_nft(total: Assets, pid: PolicyId) -> Bool {
  when assets.tokens(total, pid) |> dict.to_pairs() is {
    [Pair(_, 1)] -> True
    _ -> False
  }
}

test prove_nft_from_policy_id() {
  let val: Assets = assets.from_lovelace(100)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 1))
    |> assets.merge(assets.from_asset(#"cafe", #"face", 40))
    |> assets.merge(assets.from_asset(#"beef", #"face", 40))
    |> assets.merge(assets.from_asset(#"face", #"beef", 40))
  prove_nft(val, #"acab") == True
}

test too_many_nfts() {
  let val: Assets = assets.from_lovelace(100)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 1))
    |> assets.merge(assets.from_asset(#"acab", #"face", 1))
    |> assets.merge(assets.from_asset(#"beef", #"face", 40))
    |> assets.merge(assets.from_asset(#"face", #"beef", 40))
  prove_nft(val, #"acab") == False
}

test missing_nft() {
  let val: Assets = assets.from_lovelace(100)
    |> assets.merge(assets.from_asset(#"acab", #"beef", 10))
    |> assets.merge(assets.from_asset(#"cafe", #"face", 10))
    |> assets.merge(assets.from_asset(#"beef", #"face", 40))
    |> assets.merge(assets.from_asset(#"face", #"beef", 40))
  prove_nft(val, #"acab") == False
}

test negative_nft_is_not_an_nft() {
  // a burn of one token is not holding an nft
  prove_nft(assets.from_asset(#"acab", #"beef", -1), #"acab") == False
}
