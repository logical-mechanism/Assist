//// This module includes code finding aspects of a validating
//// transaction. 
////
//// The amounts are assumed to be exact.

use aiken/dict.{Dict}
use aiken/list
use aiken/transaction.{Input, Output, OutputReference, TransactionId}
use aiken/transaction/credential.{
  Address, Inline, StakeCredential, VerificationKeyCredential,
}
use assist/addresses
use assist/data
// for testing only
use tests/fake_tx

/// Find the first input's output reference index.
/// Output references have the form TxId#Idx, this function
/// extracts the Idx part. If nothing is found then error.
///
/// ```aiken
/// find.first_input_index(tx.inputs)
/// ```
pub fn first_input_index(inputs: List<Input>) -> Int {
  when list.head(inputs) is {
    Some(input) ->
      input.output_reference.output_index
    None ->
      error @"No Index Found"
  }
}

// can't test for errors yet
test find_first_input_index() {
  let inputs =
    fake_tx.test_tx().inputs
  first_input_index(inputs) == 0
}

/// Find the first input's output reference transaction id hash.
/// Output references have the form TxId#Idx, this function
/// extracts the TxId part. If nothing is found then error.
///
/// ```aiken
/// find.first_input_index(tx.inputs)
/// ```
pub fn first_input_ref(inputs: List<Input>) -> ByteArray {
  when list.head(inputs) is {
    Some(input) ->
      input.output_reference.transaction_id.hash
    None ->
      error @"No TxId Found"
  }
}

// can't test for errors yet
test find_first_input_ref() {
  let inputs =
    fake_tx.test_tx().inputs
  first_input_ref(inputs) == #"acab"
}

/// Find an input by its output reference else error. Similar to the builtin
/// function in stdlib but auto errors.
///
/// ```aiken
/// find.input_by_ref(tx.inputs, out_ref)
/// ```
pub fn input_by_ref(inputs: List<Input>, out_ref: OutputReference) -> Input {
  when inputs is {
    [input, ..rest] ->
      if input.output_reference == out_ref {
        input
      } else {
        input_by_ref(rest, out_ref)
      }
    [] ->
      error @"No Input Found"
  }
}

// can't test for errors yet
test find_input_by_ref() {
  let inputs =
    fake_tx.test_tx().inputs
  let out_ref =
    OutputReference {
      transaction_id: TransactionId { hash: #"acab" },
      output_index: 0,
    }
  input_by_ref(inputs, out_ref) == fake_tx.test_input()
}

/// Find the first occurrence of an output by a specific address. If nothing
/// is found then error. The address here is an exact match, pkh and sc.
///
/// ```aiken
/// find.output_by_addr(tx.outputs, your_address)
/// ```
pub fn output_by_addr(outputs: List<Output>, addr: Address) -> Output {
  when outputs is {
    [output, ..rest] ->
      if output.address == addr {
        output
      } else {
        output_by_addr(rest, addr)
      }
    [] ->
      error @"No Output Found"
  }
}

// can't test for errors yet
test find_output_by_addr() {
  let outputs =
    fake_tx.test_tx().outputs
  let addr =
    addresses.create_address(#"acab", #"")
  output_by_addr(outputs, addr) == fake_tx.test_output()
}

/// Find the first occurence of output datum by some address. If nothing is
/// found then error.
///
/// ```aiken
/// expect datum: Datum = find.output_datum_by_addr(tx.outputs, this_address)
/// ```
pub fn output_datum_by_addr(outputs: List<Output>, addr: Address) -> Data {
  let outbound_output =
    output_by_addr(outputs, addr)
  data.output_datum(outbound_output)
}

// can't test for errors yet
test find_output_datum_by_addr() {
  let outputs =
    fake_tx.test_tx().outputs
  let addr =
    addresses.create_address(#"acab", #"")
  expect datum: ByteArray =
    output_datum_by_addr(outputs, addr)
  datum == fake_tx.test_datum
}

/// Find the staking reward amount in loveace for some stake credential.
/// If no rewards are available then error.
///
/// ```aiken
/// find.staking_reward_amount(tx.withdrawals, datum.wallet.sc)
/// ```
pub fn staking_reward_amount(
  withdraws: Dict<StakeCredential, Int>,
  stake_credential: StakeCredential,
) -> Int {
  when dict.get(withdraws, stake_credential) is {
    Some(reward) ->
      reward
    None ->
      error @"No Staking Rewards Available"
  }
}

// can't test for errors yet
test find_staking_reward_amount() {
  let withdrawal =
    fake_tx.test_tx().withdrawals
  let sc =
    Inline(VerificationKeyCredential(#"face"))
  staking_reward_amount(withdrawal, sc) == 100
}
