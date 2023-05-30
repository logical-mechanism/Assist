//// This module contains code to accurately count the number of inputs and
//// outputs in a transaction for a specific address, assuming precise amounts.
////

use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address}
use assist/addresses
// for testing only
use tests/fake_tx

/// Verify that the number of inputs with an inline datum is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_datum(tx.inputs, 1)
/// ```
pub fn inputs_by_datum(inputs: List<Input>, amount: Int) -> Bool {
  count_inputs_by_datum(inputs, 0) == amount
}

fn count_inputs_by_datum(inputs: List<Input>, counter: Int) -> Int {
  when inputs is {
    [input, ..rest] ->
      when input.output.datum is {
        // the actual datum value isn't important here
        InlineDatum(_) ->
          count_inputs_by_datum(rest, counter + 1)
        // only count inline datums
        _ ->
          count_inputs_by_datum(rest, counter)
      }
    // loop the list
    [] ->
      counter
  }
}

test single_input_datum() {
  let tx =
    fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 1) == True
}

test not_enough_input_datums() {
  let tx =
    fake_tx.test_tx()
  inputs_by_datum(tx.inputs, 2) == False
}

/// Verify that the number of inputs from a specific script is equal to the
/// amount intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.inputs_by_addr(tx.inputs, this_addr, 1)
/// ```
pub fn inputs_by_addr(inputs: List<Input>, addr: Address, amount: Int) -> Bool {
  count_inputs_by_addr(inputs, addr, 0) == amount
}

fn count_inputs_by_addr(inputs: List<Input>, addr: Address, counter: Int) -> Int {
  when inputs is {
    [input, ..rest] ->
      // exact address match
      if input.output.address == addr {
        count_inputs_by_addr(rest, addr, counter + 1)
      } else {
        count_inputs_by_addr(rest, addr, counter)
      }
    [] ->
      counter
  }
}

test single_script_input() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 1) == True
}

test not_enough_inputs_by_addr() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  inputs_by_addr(tx.inputs, addr, 2) == False
}

test multiple_inputs_by_addr() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"face", #"")
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
  count_outputs_by_addr(outputs, addr, 0) == amount
}

fn count_outputs_by_addr(
  outputs: List<Output>,
  addr: Address,
  counter: Int,
) -> Int {
  when outputs is {
    [output, ..rest] ->
      // exact address match
      if output.address == addr {
        count_outputs_by_addr(rest, addr, counter + 1)
      } else {
        count_outputs_by_addr(rest, addr, counter)
      }
    // loop entire list then return counter
    [] ->
      counter
  }
}

test single_script_output() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 1) == True
}

test not_enough_outputs_by_addr() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  outputs_by_addr(tx.outputs, addr, 2) == False
}

test multiple_outputs_by_addr() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"face", #"")
  outputs_by_addr(tx.outputs, addr, 2) == True
}

/// Verify that the number of outputs with an inline datum is equal to the
/// number intended in the contract. The amount must be exactly the counter.
///
/// ```aiken
/// count.outputs_by_datum(tx.outputs, 1)
/// ```
pub fn outputs_by_datum(outputs: List<Output>, amount: Int) -> Bool {
  count_outputs_by_datum(outputs, 0) == amount
}

fn count_outputs_by_datum(outputs: List<Output>, counter: Int) -> Int {
  when outputs is {
    [output, ..rest] ->
      when output.datum is {
        // the actual datum value is not important here
        InlineDatum(_) ->
          count_outputs_by_datum(rest, counter + 1)
        // only count inline datums
        _ ->
          count_outputs_by_datum(rest, counter)
      }
    // loop entire list then return counter
    [] ->
      counter
  }
}

test single_output_datum() {
  let tx =
    fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 1) == True
}

test not_enough_output_datums() {
  let tx =
    fake_tx.test_tx()
  outputs_by_datum(tx.outputs, 2) == False
}
