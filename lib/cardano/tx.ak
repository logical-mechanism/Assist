//// This module incorporates additional code that expands the
//// functionality of the standard library.
////
//// To check for a single signature, use stdlib's
//// `list.has(tx.extra_signatories, vkh)`.
////

use aiken/collection/list
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Script, VerificationKey}
use cardano/addresses
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Input, Output, OutputReference}
// used for testing
use tests/fake_tx

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

/// This counts how many of the verification keys in `vks` have signed the
/// transaction, then checks that the count is at least `minimum`.
///
/// > [!WARNING]
/// > Each element of `vks` is counted separately, so a key listed twice counts
/// > twice. If `vks` can be influenced by a user, deduplicate it first (e.g.
/// > `list.unique`). A `minimum` of zero or less is always satisfied.
///
/// ```aiken
/// tx.verify_multisig(tx.extra_signatories, datum.signers, datum.threshold)
/// ```
pub fn verify_multisig(
  sigs: List<VerificationKeyHash>,
  vks: List<VerificationKeyHash>,
  minimum: Int,
) -> Bool {
  list.count(vks, fn(vk) { list.has(sigs, vk) }) >= minimum
}

test no_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [], 1) == False
}

test zero_threshold_multisig() {
  verify_multisig([], [], 0) == True
}

test bad_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab"], 2) == False
}

test missing_signer_multisig() {
  let sigs: List<VerificationKeyHash> = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab", #"0000"], 2) == False
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
/// information about that input. Returns True or fails.
///
/// ```aiken
/// tx.is_spending_input(tx.inputs, output_reference)
/// ```
pub fn is_spending_input(inputs: List<Input>, out_ref: OutputReference) -> Bool {
  if list.any(inputs, fn(input) { input.output_reference == out_ref }) {
    True
  } else {
    fail @"Input Not Spent"
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

/// Given a set of validator hashes prove that none of them are being spent.
/// An input counts as being spent from a validator when its payment credential
/// is that script, regardless of its stake credential.
///
/// ```aiken
/// tx.not_being_spent_from(not_these_vkhs, tx.inputs)
/// ```
pub fn not_being_spent_from(
  validator_hashes: List<ScriptHash>,
  inputs: List<Input>,
) -> Bool {
  !list.any(
    inputs,
    fn(input) {
      when input.output.address.payment_credential is {
        Script(vh) -> list.has(validator_hashes, vh)
        VerificationKey(_) -> False
      }
    },
  )
}

test nothing_being_spent_from() {
  let inputs: List<Input> = [fake_tx.test_script_input()]
  let vks: List<ScriptHash> = [#""]
  not_being_spent_from(vks, inputs) == True
}

test something_being_spent_from() {
  let inputs: List<Input> = [fake_tx.test_script_input()]
  let vks: List<ScriptHash> = [#"acab"]
  not_being_spent_from(vks, inputs) == False
}

test staked_script_is_being_spent_from() {
  // a stake credential on the script address must not hide the spend
  let input: Input = fake_tx.test_script_input()
  let staked: Input = Input {
    ..input,
    output: Output {
      ..input.output,
      address: addresses.create_script_address(
        #"acab",
        #"00000000000000000000000000000000000000000000000000000000",
      ),
    },
  }
  not_being_spent_from([#"acab"], [staked]) == False
}

test wallet_is_not_a_script() {
  // a wallet whose key hash equals a script hash is not a script input
  not_being_spent_from([#"acab"], [fake_tx.test_input()]) == True
}

/// Calculate the total amount of a token within the set of inputs for the
/// transaction and check if it is at least equal to the provided threshold.
///
/// ```aiken
/// tx.total_token_amount(tx.inputs, datum.pid, datum.tkn, datum.threshold)
/// ```
pub fn total_token_amount(
  inputs: List<Input>,
  pid: PolicyId,
  tkn: AssetName,
  threshold: Int,
) -> Bool {
  list.foldl(
    inputs,
    0,
    fn(input, total) {
      total + assets.quantity_of(input.output.value, pid, tkn)
    },
  ) >= threshold
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

test count_pid_below_threshold() {
  let inputs: List<Input> = fake_tx.test_inputs(3)
  total_token_amount(inputs, #"acab", #"beef", 301) == False
}
