//// This module contains code to accurately count the number of inputs and
//// outputs in a transaction containing an address or a datum.
////

use aiken/transaction.{DatumHash, InlineDatum, Input, Output}
use aiken/transaction/credential.{Address}
use assist/addresses
// for testing only
use tests/fake_tx

/// Verify that the number of inputs with an inline datum or datum hash is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_datum(tx.inputs, 1)
/// ```
pub fn inputs_by_datum(inputs: List<Input>, amount: Int) -> Bool {
  do_inputs_by_datum(inputs, 0) == amount
}

fn do_inputs_by_datum(inputs: List<Input>, counter: Int) -> Int {
  when inputs is {
    [input, ..rest] ->
      when input.output.datum is {
        // the actual datum value isn't important here
        InlineDatum(_) -> do_inputs_by_datum(rest, counter + 1)
        // the actual datum hash isn't important here
        DatumHash(_) -> do_inputs_by_datum(rest, counter + 1)
        // anything else just keep going
        _ -> do_inputs_by_datum(rest, counter)
      }
    // loop the list
    [] -> counter
  }
}

test single_input_datum() {
  let tx = fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 1) == True
}

test single_input_datum_hash() {
  let input = fake_tx.test_input_with_datum_hash()
  inputs_by_datum([input], 1) == True
}

test single_input_with_mixed_datums() {
  let input1 = fake_tx.test_input_with_datum_hash()
  let input2 = fake_tx.test_input()
  inputs_by_datum([input1, input2], 2) == True
}

test not_enough_input_datums() {
  let tx = fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 2) == False
}

test not_enough_input_datum_hashes() {
  let input = fake_tx.test_input_with_datum_hash()
  inputs_by_datum([input], 2) == False
}

/// Verify that the number of inputs from a specific script is equal to the
/// amount intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_addr(tx.inputs, this_addr, 1)
/// ```
pub fn inputs_by_addr(inputs: List<Input>, addr: Address, amount: Int) -> Bool {
  do_inputs_by_addr(inputs, addr, 0) == amount
}

fn do_inputs_by_addr(inputs: List<Input>, addr: Address, counter: Int) -> Int {
  when inputs is {
    [input, ..rest] ->
      // exact address match
      if input.output.address == addr {
        do_inputs_by_addr(rest, addr, counter + 1)
      } else {
        do_inputs_by_addr(rest, addr, counter)
      }
    [] -> counter
  }
}

test single_script_input() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 1) == True
}

test not_enough_inputs_by_addr() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 2) == False
}

test multiple_inputs_by_addr() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"face", #"")
  inputs_by_addr(tx.inputs, addr, 2) == True
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
  do_outputs_by_addr(outputs, addr, 0) == amount
}

fn do_outputs_by_addr(outputs: List<Output>, addr: Address, counter: Int) -> Int {
  when outputs is {
    [output, ..rest] ->
      // exact address match
      if output.address == addr {
        do_outputs_by_addr(rest, addr, counter + 1)
      } else {
        do_outputs_by_addr(rest, addr, counter)
      }
    // loop entire list then return counter
    [] -> counter
  }
}

test single_script_output() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 1) == True
}

test not_enough_outputs_by_addr() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 2) == False
}

test multiple_outputs_by_addr() {
  let tx = fake_tx.test_tx()
  let addr = addresses.create_address(#"face", #"")
  outputs_by_addr(tx.outputs, addr, 2) == True
}

/// Verify that the number of outputs with an inline datum or datum hash is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.outputs_by_datum(tx.outputs, 1)
/// ```
pub fn outputs_by_datum(outputs: List<Output>, amount: Int) -> Bool {
  do_outputs_by_datum(outputs, 0) == amount
}

fn do_outputs_by_datum(outputs: List<Output>, counter: Int) -> Int {
  when outputs is {
    [output, ..rest] ->
      when output.datum is {
        // the actual datum value is not important here
        InlineDatum(_) -> do_outputs_by_datum(rest, counter + 1)
        // the actual datum hash is not important here
        DatumHash(_) -> do_outputs_by_datum(rest, counter + 1)
        // anything else just keep going
        _ -> do_outputs_by_datum(rest, counter)
      }
    // loop entire list then return counter
    [] -> counter
  }
}

test single_output_datum() {
  let tx = fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 1) == True
}

test not_enough_output_datums() {
  let tx = fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 2) == False
}

test single_output_datum_hash() {
  let output = fake_tx.test_output_with_datum_hash()
  outputs_by_datum([output], 1) == True
}

test single_output_with_mixed_datums() {
  let output1 = fake_tx.test_output_with_datum_hash()
  let output2 = fake_tx.test_output()
  outputs_by_datum([output1, output2], 2) == True
}

test not_enough_output_datum_hashes() {
  let output = fake_tx.test_output_with_datum_hash()
  outputs_by_datum([output], 2) == False
}
