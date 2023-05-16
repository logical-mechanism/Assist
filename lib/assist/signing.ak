//// This module includes code to help with transaction signatures.
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
/// signing.verify_sig(context.transaction, #"acab") == False
/// signing.verify_sig(context.transaction, #"8f7b0ce283a92df9a3b69ac0b8f10d8bc8bcf8fbd1fe72596ee8bd6c") == True
/// ```
pub fn verify_sig(
  transaction: Transaction,
  vk: Hash<Blake2b_224, VerificationKey>,
) -> Bool {
  list.has(transaction.extra_signatories, vk)
}

test no_signature() {
  let tx =
    fake_tx.signature_only_tx()
  verify_sig(tx, #"") == False
}

test bad_signature() {
  let tx =
    fake_tx.signature_only_tx()
  verify_sig(tx, #"cafe") == False
}

test has_signature() {
  let tx =
    fake_tx.signature_only_tx()
  verify_sig(tx, #"acab") == True
}

/// Check if the list of signatures inside a transaction for a minimum amount
/// of signatures from a list verification keys.
///
/// ```aiken
/// signing.verify_multisig(context.transaction, [#"", #"acab"], 0) == False
/// signing.verify_multisig(context.transaction, [#"8f7b0ce283a92df9a3b69ac0b8f10d8bc8bcf8fbd1fe72596ee8bd6c"], 1) == True
/// ```
pub fn verify_multisig(
  transaction: Transaction,
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  minimum: Int,
) -> Bool {
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
    fake_tx.signature_only_tx()
  verify_multisig(tx, [], 1) == False
}

test bad_multisig() {
  let tx =
    fake_tx.signature_only_tx()
  verify_multisig(tx, [#"acab"], 2) == False
}

test has_multisig() {
  let tx =
    fake_tx.signature_only_tx()
  verify_multisig(tx, [#"acab", #"beef"], 2) == True
}
