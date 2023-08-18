//// This module contains code that aids in various value 
//// manipulations and comparisons.
////

use aiken/bytearray
use aiken/dict
use aiken/hash
use aiken/list
use aiken/string
use aiken/transaction.{Input}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use assist/prefixes
use tests/fake_tx

/// Multiply some value by `n`. This is just a linear scaling to the quantity
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
    multiply_value(value.merge(total, add_val), add_val, n - 1)
  }
}

test values_multiply_by_0() {
  let val = value.from_lovelace(100)
  let ans = value.zero()
  multiply(val, 0) == ans
}

test values_multiply_by_4() {
  let val = value.from_lovelace(100)
  let ans = value.from_lovelace(400)
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
  let flat: List<(PolicyId, AssetName, Int)> = value.flatten(target)
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
    [] -> True
  }
}

test value_contains_lovelace() {
  let target = value.from_lovelace(10)
  let total = value.from_lovelace(100)
  contains(target, total) == True
}

test value_contains_tokens() {
  let target = value.from_asset(#"acab", #"beef", 10)
  let total = value.from_asset(#"acab", #"beef", 40)
  contains(target, total) == True
}

test value_contains_both() {
  let target =
    value.from_lovelace(10)
      |> value.merge(value.from_asset(#"acab", #"beef", 2))
      |> value.merge(value.from_asset(#"cafe", #"face", 10))
  let total =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  contains(target, total) == True
}

test value_contains_nothing() {
  let target = value.from_lovelace(10)
  let total = value.from_asset(#"acab", #"beef", 40)
  contains(target, total) == False
}

/// Compute the sha3_256 hash of a value by merklizing the policy id, asset
/// name, and quantity. Empty values return the empty by string.
///
/// ```aiken
/// values.compute_hash(validating_value)
/// ```
pub fn compute_hash(target: Value) -> ByteArray {
  let flat: List<(PolicyId, AssetName, Int)> = value.flatten(target)
  compute_hash_helper(flat, #"")
}

fn compute_hash_helper(
  flat: List<(PolicyId, AssetName, Int)>,
  total: ByteArray,
) -> ByteArray {
  when flat is {
    [(pid, tkn, amt), ..rest] -> {
      let hashed_amt = int_to_hash(amt)
      let concatted =
        bytearray.concat(pid, tkn)
          |> bytearray.concat(hashed_amt)
          |> bytearray.concat(total)
      let next = hash.sha3_256(concatted)
      compute_hash_helper(rest, next)
    }
    [] -> total
  }
}

// sha3 256 the integer
fn int_to_hash(num: Int) -> ByteArray {
  hash.sha3_256(bytearray.from_string(string.from_int(num)))
}

test hash_empty_value() {
  let val = value.zero()
  compute_hash(val) == #""
}

test hash_lovelace_value() {
  let val = value.from_lovelace(100)
  compute_hash(val) == #"93b41836fbabea4f566ccb5aaa6ba4aa7efc92b4401cce01f4766c8e70225824"
}

test hash_large_value() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  compute_hash(val) == #"b22cc86ab71b7aba20615b56f07941aacf5445b9089c2d9ec97164a879e1b6b5"
}

/// Calculate a unique token name from a `TxId#Idx` and prefix. Can be combined
/// with the `find` module to create unique token names from the first input
/// utxo inside the transaction.
///
/// ```aiken
/// values.unique_token_name(tx_id, tx_idx, prefixes.prefix_333)
/// ```
pub fn unique_token_name(
  txid: ByteArray,
  idx: Int,
  prefix: ByteArray,
) -> ByteArray {
  // sha3_256 hash of the tx id
  let txid_hash = hash.sha3_256(txid)
  // prefix the txid hash with the index
  let prepend_index = bytearray.push(txid_hash, idx)
  // concat the prefix
  let prepend_prefix = bytearray.concat(prefix, prepend_index)
  // slice off the first 32
  bytearray.slice(prepend_prefix, 0, 31)
}

test no_prefix_token_name() {
  // the zero becomes the prefix
  unique_token_name(#"", 0, #"") == #"00a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f843"
}

test prefix_222_token_name() {
  let tkn = unique_token_name(#"", 0, prefixes.prefix_222)
  // the prefixes all have length 4
  bytearray.take(tkn, 4) == prefixes.prefix_222
}

test real_token_name() {
  let tkn =
    unique_token_name(
      #"82fca2f3221cf2d3ef017e8aa76f5c70317df0af32d327c84af4b9b9bddad91f",
      0,
      prefixes.prefix_100,
    )
  bytearray.length(tkn) == 32
}

/// Proves that inside some value there is a policy id with a single token
/// name that has a quantity of 1. This will show that a value contains an
/// NFT or something that is nft-like. Should be useful to prove that
/// something is holding a token inside a transaction when the token name
/// is assumed to be unique.
///
/// ```aiken
/// values.prove_nft(pid, this_value)
/// ```
pub fn prove_nft(pid: PolicyId, total: Value) {
  let tkns = value.tokens(total, pid) |> dict.values()
  let sum = list.foldl(tkns, 0, fn(n, total) { n + total })
  and {
    list.length(tkns) == 1,
    sum == 1,
  }
}

test prove_nft_from_policy_id() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_nft(#"acab", val) == True
}

test too_many_nfts() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"acab", #"face", 1))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_nft(#"acab", val) == False
}

test missing_nft() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 10))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_nft(#"acab", val) == False
}

/// Proves that inside some value there is a policy id with token
/// name that has a quantity of 1. This will show that a value contains an
/// NFT or something that is nft-like. Should be useful to prove that
/// something is holding a token inside a transaction when the policy id and
/// token name is known.
///
/// ```aiken
/// values.prove_exact_nft(pid, tkn, that_value)
/// ```
pub fn prove_exact_nft(
  nft_pid: PolicyId,
  nft_tkn: AssetName,
  total_value: Value,
) -> Bool {
  // exactly 1 token inside a value
  value.quantity_of(total_value, nft_pid, nft_tkn) == 1
}

test prove_exact_nft_from_policy_id() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_exact_nft(#"acab", #"beef", val) == True
}

test missing_exact_nft() {
  let val =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 10))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_exact_nft(#"acab", #"beef", val) == False
}

/// Calculate the total amount of a token within the set of inputs for the 
/// transaction. This function is useful when needing to get a total amount
/// of one token inside a given transaction, like estimating if a threshold
/// has been met.
///
/// ```aiken
/// values.total_token_amount(tx.inputs, datum.pid, datum.tkn, 0)
/// ```
pub fn total_token_amount(
  inputs: List<Input>,
  pid: PolicyId,
  tkn: AssetName,
  counter: Int,
) -> Int {
  when inputs is {
    [input, ..rest] -> {
      let amt = value.quantity_of(input.output.value, pid, tkn)
      total_token_amount(rest, pid, tkn, counter + amt)
    }
    [] -> counter
  }
}

test count_pid1() {
  let amt = 1
  let inputs = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", 0) == amt * 100
}

test count_pid2() {
  let amt = 2
  let inputs = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", 0) == amt * 100
}

test count_pid3() {
  let amt = 4
  let inputs = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", 0) == amt * 100
}

test count_pid4() {
  let amt = 8
  let inputs = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", 0) == amt * 100
}

test count_pid5() {
  let amt = 16
  let inputs = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", 0) == amt * 100
}
