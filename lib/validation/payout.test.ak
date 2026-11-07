//// Property-based tests for `validation/payout`.

use aiken/collection/list
use aiken/fuzz
use cardano/address.{Address}
use cardano/assets.{Assets}
use cardano/fuzz as cardano
use cardano/transaction.{NoDatum, Output}
use cardano/values
use validation/payout

// ## Fuzzers

fn any_address() -> Fuzzer<Address> {
  cardano.address_with(
    cardano.credential(),
    fuzz.option(cardano.stake_credential()),
  )
}

fn any_value() -> Fuzzer<Assets> {
  let lovelace <- fuzz.and_then(cardano.lovelace())
  cardano.assets(lovelace)
}

fn output_with(address: Address, value: Assets) -> Output {
  Output { address, value, datum: NoDatum, reference_script: None }
}

fn any_output() -> Fuzzer<Output> {
  cardano.output_with(
    any_address(),
    any_value(),
    fuzz.constant(NoDatum),
    fuzz.constant(None),
  )
}

/// A short list of outputs; payouts only scan them.
fn outputs() -> Fuzzer<List<Output>> {
  fuzz.list_between(any_output(), 0, 5)
}

/// A positive value and a sub-value of it.
fn value_and_part() -> Fuzzer<(Assets, Assets)> {
  let v <- fuzz.and_then(any_value())
  let part <- fuzz.map(
    fuzz.sublist(assets.flatten(v))
      |> fuzz.and_then(
          fn(entries) {
            list.foldr(
              entries,
              fuzz.constant(assets.zero),
              fn(entry, acc) {
                let (pid, tkn, amt) = entry
                let rest <- fuzz.and_then(acc)
                let taken <- fuzz.map(fuzz.int_between(1, amt))
                assets.add(rest, pid, tkn, taken)
              },
            )
          },
        ),
  )
  (v, part)
}

// ## Properties

test prop_exact_finds_a_matching_output(
  input via fuzz.tuple4(outputs(), any_address(), any_value(), outputs()),
) {
  let (before, addr, v, after) = input
  let outputs = list.concat(before, [output_with(addr, v), ..after])
  payout.exact(addr, v, outputs)
}

test prop_exact_spec(
  input via fuzz.tuple3(outputs(), any_address(), any_value()),
) {
  let (outputs, addr, v) = input
  payout.exact(addr, v, outputs) == list.has(
    list.map(outputs, fn(o) { (o.address, o.value) }),
    (addr, v),
  )
}

test prop_exact_implies_at_least(
  input via fuzz.tuple3(outputs(), any_address(), any_value()),
) {
  let (outputs, addr, v) = input
  !payout.exact(addr, v, outputs) || payout.at_least(addr, v, outputs)
}

test prop_at_least_accepts_any_part_of_an_output(
  input via fuzz.tuple4(outputs(), any_address(), value_and_part(), outputs()),
) {
  let (before, addr, (v, part), after) = input
  let outputs = list.concat(before, [output_with(addr, v), ..after])
  payout.at_least(addr, part, outputs)
}

test prop_at_least_spec(
  input via fuzz.tuple3(outputs(), any_address(), any_value()),
) {
  let (outputs, addr, v) = input
  payout.at_least(addr, v, outputs) == list.any(
    outputs,
    fn(o) { o.address == addr && values.contains(o.value, v) },
  )
}

test prop_at_least_rejects_more_than_the_output(
  input via fuzz.tuple3(any_address(), any_value(), outputs()),
) {
  // the only output at the address holds one lovelace too few
  let (addr, v, others) = input
  let elsewhere = list.filter(others, fn(o) { o.address != addr })
  let outputs = [output_with(addr, v), ..elsewhere]
  !payout.at_least(
    addr,
    assets.add(v, assets.ada_policy_id, assets.ada_asset_name, 1),
    outputs,
  )
}
