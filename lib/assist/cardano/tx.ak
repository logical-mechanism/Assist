//// This module incorporates additional code that expands the
//// functionality of the standard library.
////

use aiken/collection/list
use aiken/crypto.{ScriptHash, VerificationKeyHash}
// used for testing
use assist/tests/fake_tx
use cardano/address
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Input, OutputReference}

/// Create an `OutputReference` from the `TxId#Idx` information. This is useful
/// for building correct output references of specific UTxOs. It can be combined
/// with the `find` module for some very convenient requests.
///
/// ```aiken
/// tx.output_reference(that_tx_id, that_tx_idx)
/// ```
pub fn output_reference(tx_id_hash: ByteArray, idx: Int) -> OutputReference {
  OutputReference { transaction_id: tx_id_hash, output_index: idx }
}

test correct_out_ref() {
  let correct_out_ref: OutputReference = fake_tx.test_out_ref()
  output_reference(#"acab", 0) == correct_out_ref
}

test bad_out_ref() {
  let correct_out_ref: OutputReference = fake_tx.test_out_ref()
  output_reference(#"", 0) != correct_out_ref
}

/// Check if the list of signatures inside a transaction contains the
/// verification key.
///
/// ```aiken
/// signing.verify_signature(context.transaction, wallet_pkh)
/// ```
pub fn verify_signature(
  vks: List<VerificationKeyHash>,
  vk: VerificationKeyHash,
) -> Bool {
  list.has(vks, vk)
}

test no_signature() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_signature(sigs, #"") == False
}

test bad_signature() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_signature(sigs, #"cafe") == False
}

test has_signature() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_signature(sigs, #"acab") == True
}

test lots_of_signatures() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  list.all(
    list.map(sigs, fn(n) { verify_signature(sigs, n) }),
    fn(n) { n == True },
  ) == True
}

/// This counts the number of signatures inside a transaction that are from 
/// the list of signers then checks if its at least the minimum amount.
///
/// ```aiken
/// signing.verify_multisig(context.transaction, lst_of_sigs, sig_threshold)
/// ```
pub fn verify_multisig(
  sigs: List<VerificationKeyHash>,
  vks: List<VerificationKeyHash>,
  minimum: Int,
) -> Bool {
  // assume greater than or equal
  do_multisig(sigs, vks, 0) >= minimum
}

// Internal only
fn do_multisig(
  sigs: List<VerificationKeyHash>,
  vks: List<VerificationKeyHash>,
  counter: Int,
) -> Int {
  // loop who has to sign tx, count how many signatures have signed.
  when vks is {
    [vk, ..rest] ->
      if verify_signature(sigs, vk) {
        // signature found
        do_multisig(sigs, rest, counter + 1)
      } else {
        // signature not found
        do_multisig(sigs, rest, counter)
      }
    // At the end of the list return how many signed
    [] -> counter
  }
}

test no_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [], 1) == False
}

test bad_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab"], 2) == False
}

test has_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab", #"beef"], 2) == True
}

test big_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, sigs, 25) == True
}

/// Check if a specific input by output reference is being spent. This is useful
/// when a minting script requires a utxo to be spent but doesn't need any specific
/// information about that input.
///
/// ```aiken
/// tx.is_spending_input(tx.inputs, output_reference)
/// ```
pub fn is_spending_input(inputs: List<Input>, out_ref: OutputReference) -> Bool {
  // loop the inputs and find the output reference
  when inputs is {
    [input, ..rest] ->
      if input.output_reference == out_ref {
        // it is being spent
        True
      } else {
        is_spending_input(rest, out_ref)
      }
    // nothing is found so fail
    [] -> fail @"Input Not Spent"
  }
}

test found_spending_input() {
  let input: Input = fake_tx.test_input()
  let out_ref: OutputReference = output_reference(#"acab", 0)
  is_spending_input([input], out_ref) == True
}

test cant_found_spending_input() fail {
  let input: Input = fake_tx.test_input()
  let out_ref: OutputReference = output_reference(#"", 0)
  is_spending_input([input], out_ref) == False
}

/// Given a set of validator hashes prove that none of them are being spent. Assume
/// every address is not staked and that the is list is complete.
pub fn not_being_spent_from(
  validator_hashes: List<ScriptHash>,
  inputs: List<Input>,
) -> Bool {
  when validator_hashes is {
    [vh, ..vhs] -> {
      // check if validator hash exist as an address inside the set of inputs
      let outcome: Bool =
        list.any(
          inputs,
          // may be cheaper to do ValidatorHash equality then Address equality?
          // either build up the address or break down the address
          fn(input) { input.output.address == address.from_script(vh) },
        )
      // if true then not true else continue to the next validator hash
      if outcome {
        !outcome
      } else {
        not_being_spent_from(vhs, inputs)
      }
    }
    // if nothing ever hit then nothing is being spent
    [] -> True
  }
}

test nothing_being_spent_from() {
  let inputs: List<Input> =
    [fake_tx.test_script_input()]
  let vks: List<ScriptHash> =
    [#""]
  not_being_spent_from(vks, inputs) == True
}

test something_being_spent_from() {
  let inputs: List<Input> =
    [fake_tx.test_script_input()]
  let vks: List<ScriptHash> =
    [#"acab"]
  not_being_spent_from(vks, inputs) == False
}

/// Calculate the total amount of a token within the set of inputs for the 
/// transaction and check if it is at least equal to the provided threshold.
///
/// ```aiken
/// values.total_token_amount(tx.inputs, datum.pid, datum.tkn, datum.threshold)
/// ```
pub fn total_token_amount(
  inputs: List<Input>,
  pid: PolicyId,
  tkn: AssetName,
  threshold: Int,
) -> Bool {
  do_total_token_amount(inputs, pid, tkn, 0) >= threshold
}

fn do_total_token_amount(
  inputs: List<Input>,
  pid: PolicyId,
  tkn: AssetName,
  counter: Int,
) -> Int {
  when inputs is {
    [input, ..rest] -> {
      let amt: Int = assets.quantity_of(input.output.value, pid, tkn)
      do_total_token_amount(rest, pid, tkn, counter + amt)
    }
    [] -> counter
  }
}

test count_pid1() {
  let amt: Int = 1
  let inputs: List<Input> = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", amt * 100)
}

test count_pid2() {
  let amt: Int = 2
  let inputs: List<Input> = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", amt * 100)
}

test count_pid3() {
  let amt: Int = 4
  let inputs: List<Input> = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", amt * 100)
}

test count_pid4() {
  let amt: Int = 8
  let inputs: List<Input> = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", amt * 100)
}

test count_pid5() {
  let amt: Int = 16
  let inputs: List<Input> = fake_tx.test_inputs(amt)
  total_token_amount(inputs, #"acab", #"beef", amt * 100)
}
