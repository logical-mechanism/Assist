//// Property-based tests for `cardano/values`.
////
//// Several properties compare a function against an executable copy of its
//// previous (pre stdlib v4) implementation, to show that the refactors kept
//// the behaviour. Others cross-check against stdlib's builtin `Value`.

use aiken/collection/dict
use aiken/collection/list
use aiken/crypto
use aiken/fuzz
use aiken/primitive/bytearray
use aiken/primitive/string
use cardano/assets.{AssetName, Assets, PolicyId}
use cardano/fuzz as cardano
use cardano/value
use cardano/values
use types/cip68
use types/token

// ## Fuzzers

const policy_a: PolicyId =
  #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

const policy_b: PolicyId =
  #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

const policy_c: PolicyId =
  #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

/// A small pool of asset ids, so that independently fuzzed values overlap.
fn asset_id() -> Fuzzer<(PolicyId, AssetName)> {
  fuzz.one_of(
    [
      (assets.ada_policy_id, assets.ada_asset_name),
      (policy_a, #"01"),
      (policy_a, #"02"),
      (policy_b, #"01"),
      (policy_b, #"0203"),
      (policy_c, #""),
    ],
  )
}

fn policy() -> Fuzzer<PolicyId> {
  fuzz.one_of([assets.ada_policy_id, policy_a, policy_b, policy_c])
}

fn assets_with(quantity: Fuzzer<Int>) -> Fuzzer<Assets> {
  let entries <- fuzz.map(
    fuzz.list_between(fuzz.tuple(asset_id(), quantity), 0, 6),
  )
  list.foldl(
    entries,
    assets.zero,
    fn(entry, acc) {
      let ((pid, tkn), amt) = entry
      assets.add(acc, pid, tkn, amt)
    },
  )
}

/// Assets with positive and negative quantities.
fn any_assets() -> Fuzzer<Assets> {
  assets_with(fuzz.int_between(-1000, 1000))
}

/// Assets with strictly positive quantities, like an output value.
fn positive_assets() -> Fuzzer<Assets> {
  assets_with(fuzz.int_between(1, 1000))
}

/// Assets where a quantity of exactly one is common.
fn nft_like_assets() -> Fuzzer<Assets> {
  assets_with(fuzz.either(fuzz.constant(1), fuzz.int_between(-3, 3)))
}

fn nonzero_int() -> Fuzzer<Int> {
  fuzz.either(fuzz.int_between(-1000, -1), fuzz.int_between(1, 1000))
}

/// An output index, half the time small enough to fit in one byte.
fn output_index() -> Fuzzer<Int> {
  fuzz.either(fuzz.int_between(0, 255), fuzz.int_between(256, 70000))
}

/// Two output indexes that are equal about half the time.
fn output_index_pair() -> Fuzzer<(Int, Int)> {
  let i <- fuzz.and_then(output_index())
  let j <- fuzz.map(fuzz.either(fuzz.constant(i), output_index()))
  (i, j)
}

/// Two transaction ids that are equal about half the time.
fn transaction_id_pair() -> Fuzzer<(ByteArray, ByteArray)> {
  let a <- fuzz.and_then(cardano.transaction_id())
  let b <- fuzz.map(fuzz.either(fuzz.constant(a), cardano.transaction_id()))
  (a, b)
}

fn token_prefix() -> Fuzzer<ByteArray> {
  fuzz.one_of(
    [
      #"",
      cip68.prefix_100,
      cip68.prefix_222,
      cip68.prefix_333,
      cip68.prefix_444,
    ],
  )
}

/// A total value and a target derived from it: each asset of the total is
/// kept or dropped, and its quantity nudged by -1, 0 or +1. Sometimes an
/// extra asset is added. This puts many targets right on the boundary.
fn total_and_target() -> Fuzzer<(Assets, Assets)> {
  let total <- fuzz.and_then(any_assets())
  let kept <- fuzz.and_then(fuzz.sublist(assets.flatten(total)))
  let nudged <- fuzz.and_then(
    list.foldr(
      kept,
      fuzz.constant(assets.zero),
      fn(entry, acc) {
        let (pid, tkn, amt) = entry
        let rest <- fuzz.and_then(acc)
        let delta <- fuzz.map(fuzz.int_between(-1, 1))
        assets.add(rest, pid, tkn, amt + delta)
      },
    ),
  )
  let extra <- fuzz.map(fuzz.option(fuzz.tuple(asset_id(), nonzero_int())))
  let target = when extra is {
    Some(((pid, tkn), amt)) -> assets.add(nudged, pid, tkn, amt)
    None -> nudged
  }
  (total, target)
}

// ## Specifications (pre-refactor implementations)

fn contains_spec(total: Assets, target: Assets) -> Bool {
  list.all(
    assets.flatten(target),
    fn(t) {
      let (pid, tkn, amt) = t
      assets.quantity_of(total, pid, tkn) >= amt
    },
  )
}

fn compute_hash_spec(target: Assets) -> ByteArray {
  list.foldl(
    assets.flatten(target),
    #"",
    fn(t, acc) {
      let (pid, tkn, amt) = t
      let hashed_amt = string.from_int(amt)
        |> bytearray.from_string()
        |> crypto.blake2b_256()
      pid
        |> bytearray.concat(tkn)
        |> bytearray.concat(hashed_amt)
        |> bytearray.concat(acc)
        |> crypto.blake2b_256()
    },
  )
}

fn prove_nft_spec(total: Assets, pid: PolicyId) -> Bool {
  let amts: List<Int> = assets.tokens(total, pid) |> dict.values()
  and {
    list.length(amts) == 1,
    list.foldl(amts, 0, fn(n, sum) { n + sum }) == 1,
  }
}

// ## from_token / from_tokens

test prop_from_tokens_round_trips(v via any_assets()) {
  values.from_tokens(token.from_value(v)) == v
}

test prop_from_tokens_sums_duplicates(
  input via fuzz.tuple3(
    asset_id(),
    fuzz.int_between(-1000, 1000),
    fuzz.int_between(-1000, 1000),
  ),
) {
  let ((pid, tkn), a, b) = input
  let tokens = [
    token.Token { pid, tkn, amt: a },
    token.Token { pid, tkn, amt: b },
  ]
  values.from_tokens(tokens) == assets.from_asset(pid, tkn, a + b)
}

test prop_from_token_is_from_asset(
  input via fuzz.tuple(asset_id(), fuzz.int_between(-1000, 1000)),
) {
  let ((pid, tkn), amt) = input
  values.from_token(token.Token { pid, tkn, amt }) == assets.from_asset(
    pid,
    tkn,
    amt,
  )
}

// ## multiply

test prop_multiply_scales_each_quantity(
  input via fuzz.tuple(any_assets(), fuzz.int_between(-50, 50)),
) {
  let (v, n) = input
  let expected = if n == 0 {
    []
  } else {
    list.map(
      assets.flatten(v),
      fn(t) {
        let (pid, tkn, amt) = t
        (pid, tkn, n * amt)
      },
    )
  }
  assets.flatten(values.multiply(v, n)) == expected
}

test prop_multiply_matches_token_reference(
  input via fuzz.tuple(any_assets(), fuzz.int_between(-50, 50)),
) {
  let (v, n) = input
  // the previous implementation went through a list of tokens
  let reference = token.from_value(v)
    |> list.map(token.multiply(_, n))
    |> values.from_tokens()
  values.multiply(v, n) == reference
}

test prop_multiply_composes(
  input via fuzz.tuple3(
    any_assets(),
    fuzz.int_between(-20, 20),
    fuzz.int_between(-20, 20),
  ),
) {
  let (v, a, b) = input
  values.multiply(values.multiply(v, a), b) == values.multiply(v, a * b)
}

test prop_multiply_by_one_is_identity(v via any_assets()) {
  values.multiply(v, 1) == v
}

test prop_multiply_by_minus_one_is_negate(v via any_assets()) {
  values.multiply(v, -1) == assets.negate(v)
}

// ## contains

test prop_contains_matches_spec(input via total_and_target()) {
  let (total, target) = input
  let result = values.contains(total, target)
  fuzz.label_when(result, @"contained", @"not contained")
  result == contains_spec(total, target)
}

test prop_contains_agrees_with_builtin_value(
  input via fuzz.tuple(positive_assets(), positive_assets()),
) {
  let (total, target) = input
  let result = values.contains(total, target)
  fuzz.label_when(result, @"contained", @"not contained")
  result == value.contains(value.from_assets(total), value.from_assets(target))
}

test prop_contains_is_reflexive(v via positive_assets()) {
  values.contains(v, v)
}

test prop_contains_merge(
  input via fuzz.tuple(positive_assets(), positive_assets()),
) {
  let (a, b) = input
  let total = assets.merge(a, b)
  values.contains(total, a) && values.contains(total, b)
}

test prop_contains_one_more_is_not_contained(
  input via fuzz.tuple(positive_assets(), asset_id()),
) {
  let (v, (pid, tkn)) = input
  !values.contains(v, assets.add(v, pid, tkn, 1))
}

test prop_everything_contains_zero(v via any_assets()) {
  values.contains(v, assets.zero)
}

// ## compute_hash

test prop_compute_hash_matches_spec(v via any_assets()) {
  values.compute_hash(v) == compute_hash_spec(v)
}

test prop_compute_hash_shape(v via any_assets()) {
  let h = values.compute_hash(v)
  if assets.is_zero(v) {
    h == #""
  } else {
    bytearray.length(h) == 32
  }
}

test prop_compute_hash_detects_changes(
  input via fuzz.tuple3(any_assets(), asset_id(), nonzero_int()),
) {
  let (v, (pid, tkn), amt) = input
  values.compute_hash(v) != values.compute_hash(assets.add(v, pid, tkn, amt))
}

test prop_compute_hash_ignores_insertion_order(v via any_assets()) {
  let rebuilt = values.from_tokens(list.reverse(token.from_value(v)))
  values.compute_hash(rebuilt) == values.compute_hash(v)
}

// ## unique_token_name

test prop_unique_token_name_is_a_valid_asset_name(
  input via fuzz.tuple4(
    cardano.transaction_id(),
    output_index(),
    token_prefix(),
    fuzz.bytearray_between(0, 20),
  ),
) {
  let (txid, idx, prefix, personal) = input
  let name = values.unique_token_name(txid, idx, prefix, personal)
  // a builtin Value rejects asset names longer than 32 bytes
  let as_value = value.from_assets(assets.from_asset(policy_a, name, 1))
  and {
    bytearray.length(name) == 32,
    bytearray.starts_with(name, prefix),
    value.quantity_of(as_value, policy_a, name) == 1,
  }
}

test prop_unique_token_name_matches_previous_encoding_below_256(
  input via fuzz.tuple4(
    cardano.transaction_id(),
    fuzz.int_between(0, 255),
    token_prefix(),
    fuzz.bytearray_between(0, 20),
  ),
) {
  let (txid, idx, prefix, personal) = input
  // the previous implementation, which halted for idx >= 256
  let previous = prefix
    |> bytearray.concat(bytearray.slice(personal, 0, 14))
    |> bytearray.concat(bytearray.push(txid, idx))
    |> bytearray.slice(0, 31)
  values.unique_token_name(txid, idx, prefix, personal) == previous
}

test prop_unique_token_name_separates_indices(
  input via fuzz.tuple3(
    cardano.transaction_id(),
    output_index_pair(),
    token_prefix(),
  ),
) {
  let (txid, (i, j), prefix) = input
  fuzz.label_when(i == j, @"same index", @"different index")
  fuzz.label_when(i < 256 && j < 256, @"both one byte", @"some multi byte")
  let same_name = values.unique_token_name(txid, i, prefix, #"") == values.unique_token_name(
    txid,
    j,
    prefix,
    #"",
  )
  same_name == ( i == j )
}

test prop_unique_token_name_separates_transactions(
  input via fuzz.tuple3(
    transaction_id_pair(),
    output_index(),
    fuzz.bytearray_between(0, 20),
  ),
) {
  let ((txid_a, txid_b), idx, personal) = input
  fuzz.label_when(txid_a == txid_b, @"same txid", @"different txid")
  let same_name = values.unique_token_name(
    txid_a,
    idx,
    cip68.prefix_222,
    personal,
  ) == values.unique_token_name(txid_b, idx, cip68.prefix_222, personal)
  same_name == ( txid_a == txid_b )
}

test prop_unique_token_name_rejects_negative_indices(
  idx via fuzz.int_between(-70000, -1),
) fail {
  bytearray.length(values.unique_token_name(#"acab", idx, #"", #"")) >= 0
}

// ## prove_nft

test prop_prove_nft_matches_spec(
  input via fuzz.tuple(nft_like_assets(), policy()),
) {
  let (v, pid) = input
  let result = values.prove_nft(v, pid)
  fuzz.label_when(result, @"nft", @"not an nft")
  result == prove_nft_spec(v, pid)
}

test prop_prove_nft_sits_between_stdlib_checks(
  input via fuzz.tuple(nft_like_assets(), policy()),
) {
  let (v, pid) = input
  let strict = assets.has_any_nft_strict(v, pid)
  fuzz.label_when(strict, @"strict nft", @"not strict")
  and {
    // proving an nft implies stdlib sees some nft under the policy
    !values.prove_nft(v, pid) || assets.has_any_nft(v, pid),
    // stdlib's strict check implies we prove an nft
    !strict || values.prove_nft(v, pid),
  }
}
