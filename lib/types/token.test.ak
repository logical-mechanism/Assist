//// Property-based tests for `types/token`.

use aiken/collection/list
use aiken/fuzz
use cardano/assets.{AssetName, Assets, PolicyId}
use cardano/values
use types/token.{Token, Tokens}

// ## Fuzzers

fn asset_id() -> Fuzzer<(PolicyId, AssetName)> {
  fuzz.one_of(
    [
      (assets.ada_policy_id, assets.ada_asset_name),
      (#"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", #"01"),
      (#"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", #"02"),
      (#"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", #""),
    ],
  )
}

fn token_with(amount: Fuzzer<Int>) -> Fuzzer<Token> {
  fuzz.map2(
    asset_id(),
    amount,
    fn(id, amt) {
      let (pid, tkn) = id
      Token { pid, tkn, amt }
    },
  )
}

fn any_token() -> Fuzzer<Token> {
  token_with(fuzz.int_between(-1000, 1000))
}

fn any_tokens() -> Fuzzer<Tokens> {
  fuzz.list_between(any_token(), 0, 8)
}

fn positive_assets() -> Fuzzer<Assets> {
  let ts <- fuzz.map(
    fuzz.list_between(token_with(fuzz.int_between(1, 1000)), 0, 6),
  )
  values.from_tokens(ts)
}

// ## Properties

test prop_negative_is_an_involution(t via any_token()) {
  token.negative(token.negative(t)) == t
}

test prop_negate_is_pointwise_and_keeps_order(ts via any_tokens()) {
  let negated = token.negate(ts)
  and {
    list.length(negated) == list.length(ts),
    list.all(
      list.zip(ts, negated),
      fn(pair) {
        let (a, b) = pair
        and {
          a.pid == b.pid,
          a.tkn == b.tkn,
          b.amt == -a.amt,
        }
      },
    ),
  }
}

test prop_multiply_composes(
  input via fuzz.tuple3(
    any_token(),
    fuzz.int_between(-100, 100),
    fuzz.int_between(-100, 100),
  ),
) {
  let (t, a, b) = input
  token.multiply(token.multiply(t, a), b) == token.multiply(t, a * b)
}

test prop_divide_undoes_multiply(
  input via fuzz.tuple(any_token(), fuzz.int_between(1, 1000)),
) {
  let (t, n) = input
  token.divide(token.multiply(t, n), n) == t
}

test prop_divide_rounds_towards_negative_infinity(
  input via fuzz.tuple(any_token(), fuzz.int_between(1, 1000)),
) {
  let (t, n) = input
  let q = token.divide(t, n).amt
  q * n <= t.amt && t.amt < ( q + 1 ) * n
}

test prop_divide_rejects_non_positive_divisors(
  input via fuzz.tuple(any_token(), fuzz.int_between(-1000, 0)),
) fail {
  let (t, n) = input
  token.divide(t, n).amt == t.amt
}

test prop_signs_are_exclusive(ts via any_tokens()) {
  let add = token.addition_only(ts)
  let sub = token.subtraction_only(ts)
  fuzz.label_when(add, @"addition only", @"mixed or subtraction")
  and {
    add == list.all(ts, fn(t) { t.amt > 0 }),
    sub == list.all(ts, fn(t) { t.amt < 0 }),
    // only the empty list is both
    !(add && sub) || list.is_empty(ts),
  }
}

test prop_add_tokens_to_value_sums_quantities(
  input via fuzz.tuple(any_tokens(), asset_id()),
) {
  let (ts, (pid, tkn)) = input
  let expected = list.foldl(
    ts,
    0,
    fn(t, sum) {
      if t.pid == pid && t.tkn == tkn {
        sum + t.amt
      } else {
        sum
      }
    },
  )
  assets.quantity_of(token.add_tokens_to_value(assets.zero, ts), pid, tkn) == expected
}

test prop_from_value_lists_assets_in_descending_order(v via positive_assets()) {
  let expected = assets.flatten(v)
    |> list.map(
        fn(t) {
          let (pid, tkn, amt) = t
          Token { pid, tkn, amt }
        },
      )
    |> list.reverse()
  token.from_value(v) == expected
}

test prop_contains_is_reflexive(ts via any_tokens()) {
  token.contains(ts, ts)
}

test prop_contains_any_sublist(
  input via fuzz.tuple(
    any_tokens(),
    fuzz.list_between(fuzz.int_between(0, 1), 0, 8),
  ),
) {
  // keep each token when its flag is 1
  let (ts, flags) = input
  let sub = list.zip(ts, flags)
    |> list.filter_map(
        fn(pair) {
          let (t, keep) = pair
          if keep == 1 {
            Some(t)
          } else {
            None
          }
        },
      )
  token.contains(ts, sub)
}

test prop_contains_agrees_with_values_contains(
  input via fuzz.tuple(positive_assets(), positive_assets()),
) {
  let (total, target) = input
  let result = token.contains(token.from_value(total), token.from_value(target))
  fuzz.label_when(result, @"contained", @"not contained")
  result == values.contains(total, target)
}
