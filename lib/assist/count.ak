//// This module includes code for counting the number of inputs and outputs 
//// inside a transaction by a specific address.
////
//// The amounts are always assumed to be exact.

use aiken/transaction.{Input, Output}
use aiken/transaction/credential.{Address}
use assist/addresses
// for testing only
use tests/fake_tx

/// Verify that the number of inputs from a specific script is equal the amount
/// intended in the contract. The amount must be exact with the counter.
///
/// ```aiken
/// count.script_inputs(tx.inputs, this_script_addr, 1)
/// ```
pub fn script_inputs(
  inputs: List<Input>,
  script_addr: Address,
  amount: Int,
) -> Bool {
  count_script_inputs(inputs, script_addr, 0) == amount
}

fn count_script_inputs(
  inputs: List<Input>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when inputs is {
    [input, ..rest] ->
      if input.output.address == script_addr {
        count_script_inputs(rest, script_addr, counter + 1)
      } else {
        count_script_inputs(rest, script_addr, counter)
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
  script_inputs(tx.inputs, addr, 1) == True
}

test not_enough_script_inputs() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  script_inputs(tx.inputs, addr, 2) == False
}

test multiple_script_inputs() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"face", #"")
  script_inputs(tx.inputs, addr, 2) == True
}

/// Verify that the number of outputs from a specific script is equal the amount
/// intended in the contract. The amount must be exact with the counter.
///
/// ```aiken
/// count.script_outputs(tx.outputs, this_script_addr, 1)
/// ```
pub fn script_outputs(
  outputs: List<Output>,
  script_addr: Address,
  amount: Int,
) -> Bool {
  count_script_outputs(outputs, script_addr, 0) == amount
}

fn count_script_outputs(
  outputs: List<Output>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when outputs is {
    [output, ..rest] ->
      if output.address == script_addr {
        count_script_outputs(rest, script_addr, counter + 1)
      } else {
        count_script_outputs(rest, script_addr, counter)
      }
    [] ->
      counter
  }
}

test single_script_output() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  script_outputs(tx.outputs, addr, 1) == True
}

test not_enough_script_outputs() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  script_outputs(tx.outputs, addr, 2) == False
}

test multiple_script_outputs() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"face", #"")
  script_outputs(tx.outputs, addr, 2) == True
}
