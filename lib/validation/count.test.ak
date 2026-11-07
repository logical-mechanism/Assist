//// Property-based tests for `validation/count`.

use aiken/collection/list
use aiken/fuzz
use cardano/address.{Address, Script, VerificationKey}
use cardano/addresses
use cardano/assets
use cardano/fuzz as cardano
use cardano/transaction.{Datum, Input, NoDatum, Output, OutputReference}
use validation/count

// ## Fuzzers

fn output_at(address: Fuzzer<Address>, datum: Fuzzer<Datum>) -> Fuzzer<Output> {
  cardano.output_with(address, cardano.lovelace(), datum, fuzz.constant(None))
}

fn input_at(address: Fuzzer<Address>, datum: Fuzzer<Datum>) -> Fuzzer<Input> {
  cardano.input_with(cardano.output_reference(), output_at(address, datum))
}

/// Any address with any stake credential.
fn any_address() -> Fuzzer<Address> {
  cardano.address_with(
    cardano.credential(),
    fuzz.option(cardano.stake_credential()),
  )
}

/// Any kind of datum, with a small inline payload to keep generation cheap.
fn any_datum() -> Fuzzer<Datum> {
  fuzz.either3(
    cardano.no_datum(),
    cardano.datum_hash(),
    cardano.inline_datum_with(
      fuzz.map(
        fuzz.bytearray_between(0, 8),
        fn(b) {
          let d: Data = b
          d
        },
      ),
    ),
  )
}

fn any_output() -> Fuzzer<Output> {
  output_at(any_address(), any_datum())
}

fn any_input() -> Fuzzer<Input> {
  input_at(any_address(), any_datum())
}

const this_script: ByteArray =
  #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

const some_out_ref: OutputReference =
  OutputReference {
    transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
    output_index: 0,
  }

const bypass_script: ByteArray =
  #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

/// An address paying to a given script, with any stake credential.
fn script_address(hash: ByteArray) -> Fuzzer<Address> {
  cardano.address_with(
    fuzz.constant(Script(hash)),
    fuzz.option(cardano.stake_credential()),
  )
}

// The kinds of input in a bypass scenario.
type Kind {
  Wallet
  This
  Bypass
  Intruder
}

fn input_of_kind(kind: Kind) -> Fuzzer<Input> {
  when kind is {
    // wallets, with or without a datum
    Wallet ->
      input_at(
        cardano.address_with(
          cardano.verification_key(),
          fuzz.option(cardano.stake_credential()),
        ),
        any_datum(),
      )
    This -> input_at(script_address(this_script), any_datum())
    Bypass -> input_at(script_address(bypass_script), any_datum())
    // some other script, possibly without any datum (allowed since Plutus V3)
    Intruder ->
      input_at(
        cardano.address_with(cardano.script(), fuzz.constant(None)),
        any_datum(),
      )
  }
}

fn inputs_of_kinds(kinds: List<Kind>) -> Fuzzer<List<Input>> {
  list.foldr(
    kinds,
    fuzz.constant([]),
    fn(kind, acc) {
      let rest <- fuzz.and_then(acc)
      let input <- fuzz.map(input_of_kind(kind))
      [input, ..rest]
    },
  )
}

fn bypass_scenario() -> Fuzzer<(List<Kind>, List<Input>)> {
  let kinds <- fuzz.and_then(
    fuzz.list_between(
      fuzz.one_of([Wallet, Wallet, This, This, Bypass, Intruder]),
      0,
      6,
    ),
  )
  let inputs <- fuzz.map(inputs_of_kinds(kinds))
  (kinds, inputs)
}

fn has_datum(datum: Datum) -> Bool {
  datum != NoDatum
}

// ## Datum counts

test prop_inputs_by_datum_counts_datums(
  inputs via fuzz.list_between(any_input(), 0, 8),
) {
  let n = list.length(list.filter(inputs, fn(i) { has_datum(i.output.datum) }))
  count.inputs_by_datum(inputs, n) && !count.inputs_by_datum(inputs, n + 1)
}

test prop_outputs_by_datum_counts_datums(
  outputs via fuzz.list_between(any_output(), 0, 8),
) {
  let n = list.length(list.filter(outputs, fn(o) { has_datum(o.datum) }))
  count.outputs_by_datum(outputs, n) && !count.outputs_by_datum(outputs, n + 1)
}

// ## Script counts

test prop_inputs_by_vkh_counts_scripts(
  inputs via fuzz.list_between(any_input(), 0, 8),
) {
  let wallets = list.count(
    inputs,
    fn(i) {
      when i.output.address.payment_credential is {
        VerificationKey(_) -> True
        Script(_) -> False
      }
    },
  )
  count.inputs_by_vkh(inputs, list.length(inputs) - wallets)
}

test prop_outputs_by_vkh_counts_scripts(
  outputs via fuzz.list_between(any_output(), 0, 8),
) {
  let wallets = list.count(
    outputs,
    fn(o) {
      when o.address.payment_credential is {
        VerificationKey(_) -> True
        Script(_) -> False
      }
    },
  )
  count.outputs_by_vkh(outputs, list.length(outputs) - wallets)
}

// ## Address counts

test prop_inputs_by_addr_counts_exact_matches(
  input via fuzz.tuple4(
    fuzz.list_between(any_input(), 0, 8),
    any_address(),
    fuzz.int_between(0, 5),
    fuzz.list_between(any_input(), 0, 8),
  ),
) {
  let (before, addr, n, after) = input
  // place n inputs at addr in the middle; random addresses never collide
  let at_addr = list.repeat(
    Input {
      output_reference: some_out_ref,
      output: Output {
        address: addr,
        value: assets.zero,
        datum: NoDatum,
        reference_script: None,
      },
    },
    n,
  )
  let inputs = list.concat(before, list.concat(at_addr, after))
  count.inputs_by_addr(inputs, addr, n) && !count.inputs_by_addr(
    inputs,
    addr,
    n + 1,
  )
}

test prop_outputs_by_addr_counts_exact_matches(
  input via fuzz.tuple4(
    fuzz.list_between(any_output(), 0, 8),
    any_address(),
    fuzz.int_between(0, 5),
    fuzz.list_between(any_output(), 0, 8),
  ),
) {
  let (before, addr, n, after) = input
  let at_addr = list.repeat(
    Output {
      address: addr,
      value: assets.zero,
      datum: NoDatum,
      reference_script: None,
    },
    n,
  )
  let outputs = list.concat(before, list.concat(at_addr, after))
  count.outputs_by_addr(outputs, addr, n) && !count.outputs_by_addr(
    outputs,
    addr,
    n + 1,
  )
}

// ## single_input_with_bypass

test prop_single_input_with_bypass_spec(scenario via bypass_scenario()) {
  let (kinds, inputs) = scenario
  let these = list.count(kinds, fn(k) { k == This })
  let intruder = list.has(kinds, Intruder)
  let expected = these == 1 && !intruder
  fuzz.label_when(expected, @"allowed", @"rejected")
  fuzz.label_if(@"has an intruder", intruder)
  count.single_input_with_bypass(
    inputs,
    addresses.create_script_address(this_script, #""),
    [addresses.create_script_address(bypass_script, #"")],
  ) == expected
}

test prop_datumless_intruders_are_caught(
  input via fuzz.tuple3(
    input_of_kind(This),
    fuzz.list_between(input_of_kind(Wallet), 0, 4),
    input_at(
      cardano.address_with(
        cardano.script(),
        fuzz.option(cardano.stake_credential()),
      ),
      cardano.no_datum(),
    ),
  ),
) {
  // regression: script inputs without a datum used to be skipped entirely
  let (this, wallets, intruder) = input
  !count.single_input_with_bypass(
    [this, intruder, ..wallets],
    addresses.create_script_address(this_script, #""),
    [],
  )
}
