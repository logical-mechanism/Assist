//// This module includes code to help with transaction signatures.
////
//// All signatures are assumed to be verification keys.

use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{Transaction}
use aiken/transaction/credential.{VerificationKey}

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

/// Check if the list of signatures inside a transaction for a minimum amount
/// of signatures from a list verification keys.
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
