//// This module contains code that aids in various value 
//// manipulations and comparisons.
////

use aiken/bytearray
use aiken/dict
use aiken/hash
use aiken/list
use aiken/string
use aiken/transaction/value.{AssetName, PolicyId, Value}
use assist/prefixes
use assist/types/hashes.{TxHash}
use assist/types/token.{Token, Tokens}

/// Creates a Value type from a token.
///
/// ```aiken
/// values.from_token(this_token)
/// ```
pub fn from_token(token: Token) -> Value {
  value.from_asset(token.pid, token.tkn, token.amt)
}

test token_to_value() {
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let expected: Value = value.from_lovelace(10)
  from_token(token) == expected
}

/// Creates a Value type from a list of tokens.
///
/// ```aiken
/// values.from_tokens(redeemer.tokens)
/// ```
pub fn from_tokens(tokens: Tokens) -> Value {
  do_from_tokens(value.zero(), tokens)
}

test tokens_to_value() {
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let expected: Value = value.from_lovelace(20)
  from_tokens([token, token]) == expected
}

// Internal only
fn do_from_tokens(val: Value, tokens: Tokens) -> Value {
  when tokens is {
    // take a token and add it to the value
    [tkn, ..tkns] ->
      val |> value.add(tkn.pid, tkn.tkn, tkn.amt) |> do_from_tokens(tkns)
    // everything is negative
    [] -> val
  }
}

/// Multiply some value by `n`. This is just a linear scaling to the quantity
/// of each token.
///
/// ```aiken
/// values.multiply(bundle_value, bundle_size)
/// ```
pub fn multiply(val: Value, n: Int) -> Value {
  // convert the Value to Tokens
  let ts: Tokens = token.from_value(val)
  // do the math on the Tokens then map it back to a Value
  do_multiply([], ts, n) |> from_tokens()
}

// Internal only
fn do_multiply(ans: Tokens, ts: Tokens, n: Int) -> Tokens {
  when ts is {
    // take a token and add it to the value
    [tkn, ..tkns] ->
      ans
        |> list.push(Token { pid: tkn.pid, tkn: tkn.tkn, amt: n * tkn.amt })
        |> do_multiply(tkns, n)
    // everything is negative
    [] -> ans
  }
}

test values_multiply_by_0() {
  let val: Value = value.from_lovelace(100)
  let ans: Value = value.zero()
  multiply(val, 0) == ans
}

test values_multiply_by_4() {
  let val: Value = value.from_lovelace(100)
  let ans: Value = value.from_lovelace(400)
  multiply(val, 4) == ans
}

test values_multiply_by_52314523() {
  let val: Value = value.from_lovelace(2)
  let ans: Value = value.from_lovelace(104629046)
  multiply(val, 52314523) == ans
}

/// Prove that the target value is contained inside another value. Each token
/// inside the target must exist inside the total value. The quantity of each
/// token must be at least the target amount or greater.
///
/// ```aiken
/// values.contains(payment_value, output_value)
/// ```
pub fn contains(target: Value, total: Value) -> Bool {
  let flat: List<(PolicyId, AssetName, Int)> = value.flatten(target)
  do_contains(flat, total)
}

// Internal only
fn do_contains(flat: List<(PolicyId, AssetName, Int)>, total: Value) -> Bool {
  when flat is {
    [(pid, tkn, amt), ..rest] ->
      if value.quantity_of(total, pid, tkn) >= amt {
        do_contains(rest, total)
      } else {
        // something is missing
        False
      }
    // found all of them
    [] -> True
  }
}

test value_contains_lovelace() {
  let target: Value = value.from_lovelace(10)
  let total: Value = value.from_lovelace(100)
  contains(target, total) == True
}

test value_contains_tokens() {
  let target: Value = value.from_asset(#"acab", #"beef", 10)
  let total: Value = value.from_asset(#"acab", #"beef", 40)
  contains(target, total) == True
}

test value_contains_both() {
  let target: Value =
    value.from_lovelace(10)
      |> value.merge(value.from_asset(#"acab", #"beef", 2))
      |> value.merge(value.from_asset(#"cafe", #"face", 10))
  let total: Value =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  contains(target, total) == True
}

test value_contains_nothing() {
  let target: Value = value.from_lovelace(10)
  let total: Value = value.from_asset(#"acab", #"beef", 40)
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
  do_compute_hash(flat, #"")
}

// Internal only
fn do_compute_hash(
  flat: List<(PolicyId, AssetName, Int)>,
  total: ByteArray,
) -> ByteArray {
  when flat is {
    [(pid, tkn, amt), ..rest] -> {
      let hashed_amt: ByteArray = int_to_hash(amt)
      let concatted: ByteArray =
        bytearray.concat(pid, tkn)
          |> bytearray.concat(hashed_amt)
          |> bytearray.concat(total)
      let next: ByteArray = hash.sha3_256(concatted)
      do_compute_hash(rest, next)
    }
    [] -> total
  }
}

// Private function to sha3 256 an integer into a bytearray.
// Internal only
fn int_to_hash(num: Int) -> ByteArray {
  string.from_int(num) |> bytearray.from_string() |> hash.sha3_256()
}

test hash_empty_value() {
  let val: Value = value.zero()
  compute_hash(val) == #""
}

test hash_lovelace_value() {
  let val: Value = value.from_lovelace(100)
  compute_hash(val) == #"93b41836fbabea4f566ccb5aaa6ba4aa7efc92b4401cce01f4766c8e70225824"
}

test hash_large_value() {
  let val: Value =
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
pub fn unique_token_name(txid: TxHash, idx: Int, prefix: ByteArray) -> AssetName {
  // sha3_256 hash of the tx id
  let txid_hash: ByteArray = hash.sha3_256(txid)
  // prefix the txid hash with the index
  let prepend_index: ByteArray = bytearray.push(txid_hash, idx)
  // concat the prefix
  let prepend_prefix: ByteArray = bytearray.concat(prefix, prepend_index)
  // slice off the first 32
  bytearray.slice(prepend_prefix, 0, 31)
}

test no_prefix_token_name() {
  // the zero becomes the prefix
  unique_token_name(#"", 0, #"") == #"00a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f843"
}

test prefix_222_token_name() {
  let tkn: AssetName = unique_token_name(#"", 0, prefixes.prefix_222)
  // the prefixes all have length 4
  bytearray.take(tkn, 4) == prefixes.prefix_222
}

test real_token_name() {
  let tkn: AssetName =
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
  let tkns: List<Int> = value.tokens(total, pid) |> dict.values()
  let sum: Int = list.foldl(tkns, 0, fn(n, total) { n + total })
  and {
    // must have only one asset name
    list.length(tkns) == 1,
    sum == 1,
  }
}

test prove_nft_from_policy_id() {
  let val: Value =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_nft(#"acab", val) == True
}

test too_many_nfts() {
  let val: Value =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"acab", #"face", 1))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_nft(#"acab", val) == False
}

test missing_nft() {
  let val: Value =
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
  let val: Value =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 1))
      |> value.merge(value.from_asset(#"cafe", #"face", 40))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_exact_nft(#"acab", #"beef", val) == True
}

test missing_exact_nft() {
  let val: Value =
    value.from_lovelace(100)
      |> value.merge(value.from_asset(#"acab", #"beef", 10))
      |> value.merge(value.from_asset(#"cafe", #"face", 10))
      |> value.merge(value.from_asset(#"beef", #"face", 40))
      |> value.merge(value.from_asset(#"face", #"beef", 40))
  prove_exact_nft(#"acab", #"beef", val) == False
}
