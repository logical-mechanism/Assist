//// This module includes code to help with various value manipulations and comparisons.
//// The prefix for various cip68 tokens are included.
////

use aiken/bytearray
use aiken/dict
use aiken/hash
use aiken/list
use aiken/string
use aiken/transaction/value.{AssetName, PolicyId, Value}

/// CIP68 (100) Reference Token Prefix
pub const prefix_100 =
  #"2831303029"

/// CIP68 (222) Non-Fungible Token Prefix
pub const prefix_222 =
  #"2832323229"

/// CIP68 (333) Fungible Token Prefix
pub const prefix_333 =
  #"2833333329"

/// CIP68 (444) Semi-Fungible Token Prefix
pub const prefix_444 =
  #"2834343429"

/// Multiply some value by `n`. Its just a linear multiplier to the quantity
/// of each token.
///
/// ```aiken
/// values.multiply(bundle_value, bundle_size)
/// ```
pub fn multiply(val: Value, n: Int) -> Value {
  multiply_value(value.zero(), val, n)
}

fn multiply_value(total: Value, add_val: Value, n: Int) -> Value {
  // 4 * v = v + v + v + v 
  if n <= 0 {
    total
  } else {
    // add to total
    multiply_value(value.add(total, add_val), add_val, n - 1)
  }
}

test values_multiply_by_0() {
  let val =
    value.from_lovelace(100)
  let ans =
    value.zero()
  multiply(val, 0) == ans
}

test values_multiply_by_4() {
  let val =
    value.from_lovelace(100)
  let ans =
    value.from_lovelace(400)
  multiply(val, 4) == ans
}

/// Prove that the target value is contained inside another value. Each token
/// inside the target must exist inside the total value. The quantity of each
/// token must be at least the target amount or greater.
///
/// ```aiken
/// values.contain(payment_value, output_value)
/// ```
pub fn contains(target: Value, total: Value) -> Bool {
  let flat: List<(PolicyId, AssetName, Int)> =
    value.flatten(target)
  does_value_exist_in_value(flat, total)
}

fn does_value_exist_in_value(
  flat: List<(PolicyId, AssetName, Int)>,
  total: Value,
) -> Bool {
  when flat is {
    [(pid, tkn, amt), ..rest] ->
      if value.quantity_of(total, pid, tkn) >= amt {
        does_value_exist_in_value(rest, total)
      } else {
        // something is missing
        False
      }
    // found all of them
    [] ->
      True
  }
}

test value_contains_lovelace() {
  let target =
    value.from_lovelace(10)
  let total =
    value.from_lovelace(100)
  contains(target, total) == True
}

test value_contains_tokens() {
  let target =
    value.from_asset(#"acab", #"beef", 10)
  let total =
    value.from_asset(#"acab", #"beef", 40)
  contains(target, total) == True
}

test value_contains_both() {
  let target =
    value.from_lovelace(10)
      |> value.add(value.from_asset(#"acab", #"beef", 2))
      |> value.add(value.from_asset(#"cafe", #"face", 10))
  let total =
    value.from_lovelace(100)
      |> value.add(value.from_asset(#"acab", #"beef", 10))
      |> value.add(value.from_asset(#"cafe", #"face", 40))
      |> value.add(value.from_asset(#"beef", #"face", 40))
      |> value.add(value.from_asset(#"face", #"beef", 40))
  contains(target, total) == True
}

test value_contains_nothing() {
  let target =
    value.from_lovelace(10)
  let total =
    value.from_asset(#"acab", #"beef", 40)
  contains(target, total) == False
}

/// Compute the sha3_256 hash of a value by merklizing the policy id, asset
/// name, and quantity. Empty values return the empty by string.
///
/// ```aiken
/// values.compute_hash(validating_value)
/// ```
pub fn compute_hash(target: Value) -> ByteArray {
  let flat: List<(PolicyId, AssetName, Int)> =
    value.flatten(target)
  compute_hash_helper(flat, #"")
}

fn compute_hash_helper(
  flat: List<(PolicyId, AssetName, Int)>,
  total: ByteArray,
) -> ByteArray {
  when flat is {
    [(pid, tkn, amt), ..rest] -> {
      let hashed_amt =
        int_to_hash(amt)
      let concatted =
        bytearray.concat(pid, tkn)
          |> bytearray.concat(hashed_amt)
          |> bytearray.concat(total)
      let next =
        hash.sha3_256(concatted)
      compute_hash_helper(rest, next)
    }
    [] ->
      total
  }
}

// sha3 256 the integer
fn int_to_hash(num: Int) -> ByteArray {
  hash.sha3_256(bytearray.from_string(string.from_int(num)))
}

test hash_empty_value() {
  let val =
    value.zero()
  compute_hash(val) == #""
}

test hash_lovelace_value() {
  let val =
    value.from_lovelace(100)
  compute_hash(val) == #"93b41836fbabea4f566ccb5aaa6ba4aa7efc92b4401cce01f4766c8e70225824"
}

test hash_large_value() {
  let val =
    value.from_lovelace(100)
      |> value.add(value.from_asset(#"acab", #"beef", 10))
      |> value.add(value.from_asset(#"cafe", #"face", 40))
      |> value.add(value.from_asset(#"beef", #"face", 40))
      |> value.add(value.from_asset(#"face", #"beef", 40))
  compute_hash(val) == #"b22cc86ab71b7aba20615b56f07941aacf5445b9089c2d9ec97164a879e1b6b5"
}

/// Calculate a unique token name from a TxId#Idx and prefix. Can be combined
/// with the find module to create unique token names from the first input
/// utxo inside the transaction.
///
/// ```aiken
/// values.unique_token_name(tx_id, tx_idx, prefix_333)
/// ```
pub fn unique_token_name(
  txid: ByteArray,
  idx: Int,
  prefix: ByteArray,
) -> ByteArray {
  // sha3_256 hash of the tx id
  let txid_hash =
    hash.sha3_256(txid)
  // prefix the txid hash with the index
  let prepend_index =
    bytearray.push(txid_hash, idx)
  // concat the prefix
  let prepend_prefix =
    bytearray.concat(prefix, prepend_index)
  // slice off the first 32
  bytearray.slice(prepend_prefix, 0, 31)
}

test no_prefix_token_name() {
  // the zero becomes the prefix
  unique_token_name(#"", 0, #"") == #"00a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f843"
}

test prefix_222_token_name() {
  let tkn =
    unique_token_name(#"", 0, prefix_222)
  bytearray.take(tkn, 5) == prefix_222
}

test real_token_name() {
  let tkn =
    unique_token_name(
      #"82fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84af4b9b9bddad91f",
      0,
      prefix_100,
    )
  bytearray.length(tkn) == 32
}

/// Proves that inside some value there is a policy id with a single token
/// name with an amount equal to 1. This will show that a value contains an
/// NFT. Should be useful to prove that someone is holding a token.
///
/// ```aiken
/// values.prove_singluar_token(pointer_pid, validating_value)
/// ```
pub fn prove_singular_token(pid: PolicyId, total: Value) {
  let tkns =
    value.tokens(total, pid) |> dict.values()
  let sum =
    list.foldl(tkns, fn(n, total) { n + total }, 0)
  list.and([list.length(tkns) == 1, sum == 1])
}

test prove_nft_from_policy_id() {
  let val =
    value.from_lovelace(100)
      |> value.add(value.from_asset(#"acab", #"beef", 1))
      |> value.add(value.from_asset(#"cafe", #"face", 40))
      |> value.add(value.from_asset(#"beef", #"face", 40))
      |> value.add(value.from_asset(#"face", #"beef", 40))
  prove_singular_token(#"acab", val) == True
}

test too_many_nfts() {
  let val =
    value.from_lovelace(100)
      |> value.add(value.from_asset(#"acab", #"beef", 1))
      |> value.add(value.from_asset(#"acab", #"face", 1))
      |> value.add(value.from_asset(#"beef", #"face", 40))
      |> value.add(value.from_asset(#"face", #"beef", 40))
  prove_singular_token(#"acab", val) == False
}

test missing_nft() {
  let val =
    value.from_lovelace(100)
      |> value.add(value.from_asset(#"acab", #"beef", 10))
      |> value.add(value.from_asset(#"cafe", #"face", 10))
      |> value.add(value.from_asset(#"beef", #"face", 40))
      |> value.add(value.from_asset(#"face", #"beef", 40))
  prove_singular_token(#"acab", val) == False
}
