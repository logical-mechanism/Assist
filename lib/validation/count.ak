//// This module contains code to accurately count the number of inputs and
//// outputs in a transaction containing an address or a datum.
////

use aiken/collection/list
use cardano/address.{Address, Script, VerificationKey}
use cardano/addresses
use cardano/transaction.{
  DatumHash, InlineDatum, Input, NoDatum, Output, Transaction,
}
// for testing only
use tests/fake_tx

// True when an output carries an inline datum or a datum hash.
// Internal only
fn has_datum(output: Output) -> Bool {
  when output.datum is {
    NoDatum -> False
    InlineDatum(_) -> True
    DatumHash(_) -> True
  }
}

// True when an output is locked by a script payment credential.
// Internal only
fn is_script(output: Output) -> Bool {
  when output.address.payment_credential is {
    Script(_) -> True
    VerificationKey(_) -> False
  }
}

/// Verify that the number of inputs with an inline datum or datum hash is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_datum(tx.inputs, 1)
/// ```
pub fn inputs_by_datum(inputs: List<Input>, amount: Int) -> Bool {
  list.count(inputs, fn(input) { has_datum(input.output) }) == amount
}

test single_input_datum() {
  let tx: Transaction = fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 1) == True
}

test single_input_datum_hash() {
  let input: Input = fake_tx.test_input_with_datum_hash()
  inputs_by_datum([input], 1) == True
}

test single_input_with_mixed_datums() {
  let input1: Input = fake_tx.test_input_with_datum_hash()
  let input2: Input = fake_tx.test_input()
  inputs_by_datum([input1, input2], 2) == True
}

test not_enough_input_datums() {
  let tx: Transaction = fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 2) == False
}

test not_enough_input_datum_hashes() {
  let input: Input = fake_tx.test_input_with_datum_hash()
  inputs_by_datum([input], 2) == False
}

test empty_input_datums() {
  inputs_by_datum([], 0) == True
}

/// Count the number of inputs with a payment credential that is a script.
/// This does not take in an address but is a general count of validator hashes.
///
/// ```aiken
/// count.inputs_by_vkh(tx.inputs, 1)
/// ```
pub fn inputs_by_vkh(inputs: List<Input>, amount: Int) -> Bool {
  list.count(inputs, fn(input) { is_script(input.output) }) == amount
}

test double_vkh_script_input() {
  let this_inputs: List<Input> = fake_tx.test_bad_inputs()
  inputs_by_vkh(this_inputs, 2) == True
}

test no_vkh_script_input() {
  let tx: Transaction = fake_tx.test_tx()
  inputs_by_vkh(tx.inputs, 1) == False
}

/// Count the number of outputs with a payment credential that is a script.
/// This does not take in an address but is a general count of validator hashes.
///
/// ```aiken
/// count.outputs_by_vkh(tx.outputs, 1)
/// ```
pub fn outputs_by_vkh(outputs: List<Output>, amount: Int) -> Bool {
  list.count(outputs, is_script) == amount
}

test single_vkh_script_output() {
  let this_outputs: List<Output> = fake_tx.test_bad_outputs()
  outputs_by_vkh(this_outputs, 1) == True
}

test no_vkh_script_output() {
  let tx: Transaction = fake_tx.test_tx()
  outputs_by_vkh(tx.outputs, 1) == False
}

/// Verify that the number of inputs from a specific script is equal to the
/// amount intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_addr(tx.inputs, this_addr, 1)
/// ```
pub fn inputs_by_addr(inputs: List<Input>, addr: Address, amount: Int) -> Bool {
  list.count(inputs, fn(input) { input.output.address == addr }) == amount
}

test single_script_input() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 1) == True
}

test not_enough_inputs_by_addr() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 2) == False
}

test multiple_inputs_by_addr() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"face", #"")
  inputs_by_addr(tx.inputs, addr, 2) == True
}

test empty_input_addr() {
  let addr: Address = addresses.create_address(#"acab", #"")
  inputs_by_addr([], addr, 0) == True
}

/// Verify that the number of outputs from a specific script is equal the amount
/// intended in the contract. The amount must be exact with the counter.
///
/// ```aiken
/// count.outputs_by_addr(tx.outputs, this_addr, 1)
/// ```
pub fn outputs_by_addr(
  outputs: List<Output>,
  addr: Address,
  amount: Int,
) -> Bool {
  list.count(outputs, fn(output) { output.address == addr }) == amount
}

test single_script_output() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 1) == True
}

test not_enough_outputs_by_addr() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 2) == False
}

test multiple_outputs_by_addr() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"face", #"")
  outputs_by_addr(tx.outputs, addr, 2) == True
}

test empty_output_addr() {
  let addr: Address = addresses.create_address(#"acab", #"")
  outputs_by_addr([], addr, 0) == True
}

/// Verify that the number of outputs with an inline datum or datum hash is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.outputs_by_datum(tx.outputs, 1)
/// ```
pub fn outputs_by_datum(outputs: List<Output>, amount: Int) -> Bool {
  list.count(outputs, has_datum) == amount
}

test single_output_datum() {
  let tx: Transaction = fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 1) == True
}

test not_enough_output_datums() {
  let tx: Transaction = fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 2) == False
}

test single_output_datum_hash() {
  let output: Output = fake_tx.test_output_with_datum_hash()
  outputs_by_datum([output], 1) == True
}

test single_output_with_mixed_datums() {
  let output1 = fake_tx.test_output_with_datum_hash()
  let output2 = fake_tx.test_output()
  outputs_by_datum([output1, output2], 2) == True
}

test not_enough_output_datum_hashes() {
  let output: Output = fake_tx.test_output_with_datum_hash()
  outputs_by_datum([output], 2) == False
}

test empty_output_datums() {
  outputs_by_datum([], 0) == True
}

/// The contract can only be spent by itself or along side some list of known
/// script addresses. Loop all the inputs and count how many are locked by this
/// address's script. Script inputs belonging to any of those addresses are
/// passed over, but any other script input fails the check. Wallet inputs are
/// always allowed. The check passes when exactly one input belongs to this
/// address. This should prevent unregulated contracts from being spent along
/// side this script.
///
/// Addresses are compared by payment credential only, so stake credentials
/// are ignored. Datums are ignored too: since Plutus V3 a script output can be
/// spent without any datum, so the presence of a datum says nothing about
/// whether an input is a script input.
///
/// ```aiken
/// count.single_input_with_bypass(this_tx.inputs, this_addr, [that_addr])
/// ```
///
pub fn single_input_with_bypass(
  inputs: List<Input>,
  this_addr: Address,
  those_addrs: List<Address>,
) -> Bool {
  do_single_input_with_bypass(inputs, 0, this_addr, those_addrs)
}

fn vkh_addr_eq(a: Address, b: Address) -> Bool {
  when a.payment_credential is {
    Script(avkh) ->
      when b.payment_credential is {
        Script(bvkh) -> avkh == bvkh
        _ -> False
      }
    _ -> False
  }
}

test vkh_addr_eq_works1() {
  let a: Address = addresses.create_script_address(#"acab", #"")
  let b: Address = addresses.create_script_address(#"acab", #"")
  vkh_addr_eq(a, b)
}

test vkh_addr_eq_works2() {
  let a: Address = addresses.create_address(#"acab", #"")
  let b: Address = addresses.create_address(#"acab", #"")
  vkh_addr_eq(a, b) == False
}

test vkh_addr_eq_ignores_stake() {
  let a: Address = addresses.create_script_address(
    #"acab",
    #"00000000000000000000000000000000000000000000000000000000",
  )
  let b: Address = addresses.create_script_address(#"acab", #"")
  vkh_addr_eq(a, b)
}

// Internal only
fn do_single_input_with_bypass(
  inputs: List<Input>,
  counter: Int,
  this_addr: Address,
  those_addrs: List<Address>,
) -> Bool {
  when inputs is {
    [input, ..rest] ->
      if !is_script(input.output) {
        // wallet inputs are always fine
        do_single_input_with_bypass(rest, counter, this_addr, those_addrs)
      } else if vkh_addr_eq(input.output.address, this_addr) {
        // count it
        do_single_input_with_bypass(rest, counter + 1, this_addr, those_addrs)
      } else if list.any(
        those_addrs,
        fn(n) { vkh_addr_eq(input.output.address, n) },
      ) {
        // a known script, all good
        do_single_input_with_bypass(rest, counter, this_addr, those_addrs)
      } else {
        // an unknown script is being spent
        False
      }
    // there can be only this address and any amount of those addresses but nothing else
    [] -> counter == 1
  }
}

test single_input_with_no_bypass() {
  let this_inputs: List<Input> = fake_tx.test_bad_inputs()
  let addr1: Address = addresses.create_script_address(#"acab", #"")
  let addr2: Address = addresses.create_script_address(#"cafe", #"acab")
  single_input_with_bypass(this_inputs, addr1, [addr2]) == True
}

test single_input_with_a_bad_bypass() {
  let this_inputs: List<Input> = fake_tx.test_bad_inputs()
  let addr: Address = addresses.create_script_address(#"acab", #"")
  single_input_with_bypass(this_inputs, addr, []) == False
}

test double_input_with_bypass() {
  let input: Input = fake_tx.test_script_input()
  let addr: Address = addresses.create_script_address(#"acab", #"")
  single_input_with_bypass([input, input], addr, []) == False
}

test no_input_with_bypass() {
  let addr: Address = addresses.create_script_address(#"acab", #"")
  single_input_with_bypass([fake_tx.test_input()], addr, []) == False
}

test datumless_script_input_cannot_sneak_past_bypass() {
  // Plutus V3 lets a script output be spent without a datum; it must still
  // be treated as a script input.
  let this: Input = fake_tx.test_script_input()
  let other: Input = fake_tx.test_script_input()
  let sneaky: Input = Input {
    ..other,
    output: Output {
      ..other.output,
      address: addresses.create_script_address(#"beef", #""),
      datum: NoDatum,
    },
  }
  let addr: Address = addresses.create_script_address(#"acab", #"")
  single_input_with_bypass([this, sneaky], addr, []) == False
}

test wallet_input_with_datum_is_fine_for_bypass() {
  let this: Input = fake_tx.test_script_input()
  // test_input is a wallet input that carries an inline datum
  let addr: Address = addresses.create_script_address(#"acab", #"")
  single_input_with_bypass([this, fake_tx.test_input()], addr, []) == True
}
