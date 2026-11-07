//// Property-based tests for `cardano/minting`.
////
//// The minting helpers used to take `assets.flatten(tx.mint)`. They now take
//// the `Assets` directly. Each property checks the new function against the
//// old flat-list implementation.

use aiken/collection/list
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/assets.{AssetName, Assets, PolicyId}
use cardano/minting
use types/cip68

// ## Fuzzers

const policy_a: PolicyId =
  #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

const policy_b: PolicyId =
  #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

fn policy() -> Fuzzer<PolicyId> {
  fuzz.one_of([policy_a, policy_b])
}

/// Token names drawn from a small pool, mostly CIP-68 shaped.
fn token_name() -> Fuzzer<AssetName> {
  fuzz.one_of(
    [
      #"",
      #"cafe",
      cip68.prefix_100,
      cip68.prefix_222,
      bytearray.concat(cip68.prefix_100, #"cafe"),
      bytearray.concat(cip68.prefix_222, #"cafe"),
      bytearray.concat(cip68.prefix_333, #"cafe"),
    ],
  )
}

/// Mint and burn quantities, biased towards small values so that matches
/// against a fuzzed amount are common.
fn quantity() -> Fuzzer<Int> {
  fuzz.int_between(-3, 3)
}

/// A mint value: positive quantities are mints, negative ones are burns.
fn mint() -> Fuzzer<Assets> {
  let entries <- fuzz.map(
    fuzz.list_between(fuzz.tuple3(policy(), token_name(), quantity()), 0, 6),
  )
  list.foldl(
    entries,
    assets.zero,
    fn(entry, acc) {
      let (pid, tkn, amt) = entry
      assets.add(acc, pid, tkn, amt)
    },
  )
}

/// A mint value and a query. Half of the queries target an asset that is in
/// the mint, with its exact quantity, so that matches are well covered.
fn mint_and_query() -> Fuzzer<(Assets, PolicyId, AssetName, Int)> {
  let m <- fuzz.and_then(mint())
  let flat = assets.flatten(m)
  let random = fuzz.tuple3(policy(), token_name(), quantity())
  let query <- fuzz.map(
    if list.is_empty(flat) {
      random
    } else {
      fuzz.either(fuzz.one_of(flat), random)
    },
  )
  let (pid, tkn, amt) = query
  (m, pid, tkn, amt)
}

// ## Specifications (pre-refactor implementations over flattened values)

fn exact_spec(
  flat: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  tkn: AssetName,
  amt: Int,
) -> Bool {
  list.any(
    flat,
    fn(t) {
      let (p, n, q) = t
      p == pid && n == tkn && q == amt
    },
  )
}

fn by_prefix_spec(
  flat: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  prefix: AssetName,
  amt: Int,
) -> Bool {
  list.any(
    flat,
    fn(t) {
      let (p, n, q) = t
      // all cip68 prefixes have the same length
      p == pid && bytearray.take(n, 4) == prefix && q == amt
    },
  )
}

fn is_occurring_spec(
  flat: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  tkn: AssetName,
) -> Bool {
  list.any(
    flat,
    fn(t) {
      let (p, n, _) = t
      p == pid && n == tkn
    },
  )
}

fn quantity_of_spec(
  flat: List<(PolicyId, AssetName, Int)>,
  pid: PolicyId,
  tkn: AssetName,
) -> Int {
  when
    list.find(
      flat,
      fn(t) {
        let (p, n, _) = t
        p == pid && n == tkn
      },
    )
  is {
    Some((_, _, q)) -> q
    None -> 0
  }
}

// ## Properties

test prop_exact_matches_spec(input via mint_and_query()) {
  let (m, pid, tkn, amt) = input
  let result = minting.exact(m, pid, tkn, amt)
  fuzz.label_when(result, @"exact match", @"no match")
  result == exact_spec(assets.flatten(m), pid, tkn, amt)
}

test prop_by_prefix_matches_spec(
  input via fuzz.tuple(mint_and_query(), fuzz.bool()),
) {
  let ((m, pid, tkn, amt), use_own_prefix) = input
  // a 4-byte prefix, either taken from the queried name or a cip68 one
  let pre = if use_own_prefix && bytearray.length(tkn) >= 4 {
    bytearray.take(tkn, 4)
  } else {
    cip68.prefix_444
  }
  let result = minting.by_prefix(m, pid, pre, amt)
  fuzz.label_when(result, @"prefix match", @"no match")
  result == by_prefix_spec(assets.flatten(m), pid, pre, amt)
}

test prop_by_prefix_accepts_any_prefix_length(
  input via fuzz.tuple3(
    policy(),
    fuzz.bytearray_between(0, 16),
    fuzz.bytearray_between(0, 16),
  ),
) {
  let (pid, pre, suffix) = input
  let m = assets.from_asset(pid, bytearray.concat(pre, suffix), 1)
  minting.by_prefix(m, pid, pre, 1)
}

test prop_is_occurring_matches_spec(input via mint_and_query()) {
  let (m, pid, tkn, _) = input
  let result = minting.is_occurring(m, pid, tkn)
  fuzz.label_when(result, @"occurring", @"not occurring")
  result == is_occurring_spec(assets.flatten(m), pid, tkn)
}

test prop_exact_implies_is_occurring(input via mint_and_query()) {
  let (m, pid, tkn, amt) = input
  !minting.exact(m, pid, tkn, amt) || minting.is_occurring(m, pid, tkn)
}

test prop_exact_implies_by_prefix(input via mint_and_query()) {
  let (m, pid, tkn, amt) = input
  !minting.exact(m, pid, tkn, amt) || minting.by_prefix(
    m,
    pid,
    bytearray.take(tkn, 4),
    amt,
  )
}

test prop_removed_quantity_of_is_stdlib(
  input via fuzz.tuple3(mint(), policy(), token_name()),
) {
  // `minting.quantity_of` was removed in favour of `assets.quantity_of`
  let (m, pid, tkn) = input
  assets.quantity_of(m, pid, tkn) == quantity_of_spec(
    assets.flatten(m),
    pid,
    tkn,
  )
}
