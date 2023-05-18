//// This module includes code for verifying transaction signatures.
////
//// All signatures are assumed to be verification keys.

use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{Transaction}
use aiken/transaction/credential.{VerificationKey}
// for testing only
use tests/fake_tx

/// Check if the list of signatures inside a transaction contains the
/// verification key.
///
/// ```aiken
/// signing.verify_sig(context.transaction, wallet_pkh) == True
/// ```
pub fn verify_sig(
  transaction: Transaction,
  vk: Hash<Blake2b_224, VerificationKey>,
) -> Bool {
  list.has(transaction.extra_signatories, vk)
}

test no_signature() {
  let tx =
    fake_tx.test_tx()
  verify_sig(tx, #"") == False
}

test bad_signature() {
  let tx =
    fake_tx.test_tx()
  verify_sig(tx, #"cafe") == False
}

test has_signature() {
  let tx =
    fake_tx.test_tx()
  verify_sig(tx, #"acab") == True
}

/// This counts the number of signatures inside a transaction that are from 
/// the list of signers then checks if its at least the minimum amount.
///
/// ```aiken
/// signing.verify_multisig(tx, lst_of_sigs, sig_threshold) == True
/// ```
pub fn verify_multisig(
  transaction: Transaction,
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  minimum: Int,
) -> Bool {
  // assume greater than or equal
  run_multisig(transaction, vks, 0) >= minimum
}

fn run_multisig(
  transaction: Transaction,
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  counter: Int,
) -> Int {
  // loop who has to sign tx, count how many signatures have signed.
  when vks is {
    [vk, ..rest] ->
      if verify_sig(transaction, vk) == True {
        // signature found
        run_multisig(transaction, rest, counter + 1)
      } else {
        // signature not found
        run_multisig(transaction, rest, counter)
      }
    // At the end of the list return how many signed
    [] ->
      counter
  }
}

test no_multisig() {
  let tx =
    fake_tx.test_tx()
  verify_multisig(tx, [], 1) == False
}

test bad_multisig() {
  let tx =
    fake_tx.test_tx()
  verify_multisig(tx, [#"acab"], 2) == False
}

test has_multisig() {
  let tx =
    fake_tx.test_tx()
  verify_multisig(tx, [#"acab", #"beef"], 2) == True
}
