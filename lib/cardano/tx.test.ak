//// Property-based tests for `cardano/tx`.

use aiken/collection/list
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/fuzz
use cardano/address.{Address, Credential, Script, VerificationKey}
use cardano/assets.{Assets}
use cardano/fuzz as cardano
use cardano/transaction.{Input, NoDatum, Output}
use cardano/tx

// ## Fuzzers

/// A set of required signers, the subset that signed, extra unrelated
/// signatures, and a threshold.
fn multisig_scenario() -> Fuzzer<
  (List<VerificationKeyHash>, List<VerificationKeyHash>, Int, Int),
> {
  let signers <- fuzz.and_then(
    fuzz.set_between(cardano.verification_key_hash(), 0, 8),
  )
  let signed <- fuzz.and_then(fuzz.sublist(signers))
  let noise <- fuzz.and_then(
    fuzz.list_between(cardano.verification_key_hash(), 0, 4),
  )
  let threshold <- fuzz.map(fuzz.int_between(0, list.length(signers) + 1))
  (signers, list.concat(noise, signed), list.length(signed), threshold)
}

const script_a: ScriptHash =
  #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

const script_b: ScriptHash =
  #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

const script_c: ScriptHash =
  #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

fn pooled_hash() -> Fuzzer<ByteArray> {
  fuzz.one_of([script_a, script_b, script_c])
}

/// Script or wallet credentials whose hashes come from a small pool, so the
/// same hash shows up as both a script and a wallet key.
fn pooled_credential() -> Fuzzer<Credential> {
  fuzz.either(
    cardano.script_with(pooled_hash()),
    cardano.verification_key_with(pooled_hash()),
  )
}

fn input_at(address: Fuzzer<Address>) -> Fuzzer<Input> {
  cardano.input_with(
    cardano.output_reference(),
    cardano.output_with(
      address,
      cardano.lovelace(),
      cardano.no_datum(),
      fuzz.constant(None),
    ),
  )
}

/// Inputs from pooled credentials, with or without a stake credential.
fn pooled_input() -> Fuzzer<Input> {
  input_at(
    cardano.address_with(
      pooled_credential(),
      fuzz.option(cardano.stake_credential()),
    ),
  )
}

fn with_value(input: Input, value: Assets) -> Input {
  Input { ..input, output: Output { ..input.output, value } }
}

fn without_stake(input: Input) -> Input {
  let address = Address { ..input.output.address, stake_credential: None }
  Input { ..input, output: Output { ..input.output, address } }
}

// ## verify_multisig

test prop_verify_multisig_counts_distinct_signers(s via multisig_scenario()) {
  let (signers, sigs, signed, threshold) = s
  let result = tx.verify_multisig(sigs, signers, threshold)
  fuzz.label_when(result, @"threshold met", @"threshold not met")
  result == ( signed >= threshold )
}

test prop_verify_multisig_ignores_order(s via multisig_scenario()) {
  let (signers, sigs, _, threshold) = s
  tx.verify_multisig(sigs, signers, threshold) == tx.verify_multisig(
    list.reverse(sigs),
    list.reverse(signers),
    threshold,
  )
}

test prop_verify_multisig_more_signatures_never_hurt(
  input via fuzz.tuple(
    multisig_scenario(),
    fuzz.list(cardano.verification_key_hash()),
  ),
) {
  let ((signers, sigs, _, threshold), extra) = input
  !tx.verify_multisig(sigs, signers, threshold) || tx.verify_multisig(
    list.concat(extra, sigs),
    signers,
    threshold,
  )
}

// ## is_spending_input

test prop_is_spending_input_finds_every_input(
  input via fuzz.list_with_elem(pooled_input()),
) {
  let (inputs, spent) = input
  tx.is_spending_input(inputs, spent.output_reference)
}

test prop_is_spending_input_fails_when_missing(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 0, 8),
    cardano.output_reference(),
  ),
) fail {
  let (inputs, out_ref) = input
  tx.is_spending_input(inputs, out_ref)
}

// ## not_being_spent_from

test prop_not_being_spent_from_spec(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 0, 8),
    fuzz.sublist([script_a, script_b, script_c]),
  ),
) {
  let (inputs, hashes) = input
  let spent_scripts = list.filter_map(
    inputs,
    fn(i) {
      when i.output.address.payment_credential is {
        Script(h) -> Some(h)
        VerificationKey(_) -> None
      }
    },
  )
  let result = tx.not_being_spent_from(hashes, inputs)
  fuzz.label_when(result, @"not spent", @"spent")
  result == list.all(hashes, fn(h) { !list.has(spent_scripts, h) })
}

test prop_not_being_spent_from_ignores_stake_credentials(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 0, 8),
    fuzz.sublist([script_a, script_b, script_c]),
  ),
) {
  // regression: a staked script address used to slip past the check
  let (inputs, hashes) = input
  tx.not_being_spent_from(hashes, inputs) == tx.not_being_spent_from(
    hashes,
    list.map(inputs, without_stake),
  )
}

test prop_spending_a_listed_script_is_detected(
  input via fuzz.tuple3(
    fuzz.list_between(pooled_input(), 0, 8),
    input_at(
      cardano.address_with(
        cardano.script_with(pooled_hash()),
        fuzz.option(cardano.stake_credential()),
      ),
    ),
    fuzz.list_between(pooled_input(), 0, 8),
  ),
) {
  let (before, spent, after) = input
  expect Script(hash) = spent.output.address.payment_credential
  let inputs = list.concat(before, [spent, ..after])
  !tx.not_being_spent_from([hash], inputs)
}

// ## total_token_amount

test prop_total_token_amount_threshold(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 0, 8),
    fuzz.list_between(fuzz.int_between(0, 1000), 0, 10),
  ),
) {
  let (templates, quantities) = input
  // give each input some quantity of the token, plus unrelated tokens
  let inputs = list.map(
    list.zip(templates, quantities),
    fn(pair) {
      let (template, quantity) = pair
      let value = assets.from_lovelace(2_000_000)
        |> assets.add(script_a, #"beef", quantity)
        |> assets.add(script_a, #"cafe", 7)
        |> assets.add(script_b, #"beef", 11)
      with_value(template, value)
    },
  )
  let total = list.foldl(
    list.take(quantities, list.length(templates)),
    0,
    fn(q, s) { q + s },
  )
  and {
    tx.total_token_amount(inputs, script_a, #"beef", total),
    !tx.total_token_amount(inputs, script_a, #"beef", total + 1),
  }
}

test prop_total_token_amount_of_nothing(
  inputs via fuzz.list_between(pooled_input(), 0, 8),
) {
  // the pooled inputs only hold lovelace
  and {
    tx.total_token_amount(inputs, script_a, #"beef", 0),
    !tx.total_token_amount(inputs, script_a, #"beef", 1),
    list.all(inputs, fn(i) { i.output.datum == NoDatum }),
  }
}
