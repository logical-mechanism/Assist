//// This module contains code for verifying transaction signatures. 
//// It assumes that all signatures provided are verification keys.
////

use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction/credential.{VerificationKey}
// for testing only
use tests/fake_tx

/// Check if the list of signatures inside a transaction contains the
/// verification key.
///
/// ```aiken
/// signing.verify_sig(context.transaction, wallet_pkh)
/// ```
pub fn verify_sig(
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  vk: Hash<Blake2b_224, VerificationKey>,
) -> Bool {
  list.has(vks, vk)
}

test no_signature() {
  let sigs = fake_tx.test_signatories()
  verify_sig(sigs, #"") == False
}

test bad_signature() {
  let sigs = fake_tx.test_signatories()
  verify_sig(sigs, #"cafe") == False
}

test has_signature() {
  let sigs = fake_tx.test_signatories()
  verify_sig(sigs, #"acab") == True
}

test lots_of_signatures() {
  let sigs = fake_tx.test_signatories()
  list.all(list.map(sigs, fn(n) { verify_sig(sigs, n) }), fn(n) { n == True }) == True
}

/// This counts the number of signatures inside a transaction that are from 
/// the list of signers then checks if its at least the minimum amount.
///
/// ```aiken
/// signing.verify_multisig(context.transaction, lst_of_sigs, sig_threshold)
/// ```
pub fn verify_multisig(
  sigs: List<Hash<Blake2b_224, VerificationKey>>,
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  minimum: Int,
) -> Bool {
  // assume greater than or equal
  run_multisig(sigs, vks, 0) >= minimum
}

fn run_multisig(
  sigs: List<Hash<Blake2b_224, VerificationKey>>,
  vks: List<Hash<Blake2b_224, VerificationKey>>,
  counter: Int,
) -> Int {
  // loop who has to sign tx, count how many signatures have signed.
  when vks is {
    [vk, ..rest] ->
      if verify_sig(sigs, vk) == True {
        // signature found
        run_multisig(sigs, rest, counter + 1)
      } else {
        // signature not found
        run_multisig(sigs, rest, counter)
      }
    // At the end of the list return how many signed
    [] -> counter
  }
}

test no_multisig() {
  let sigs = fake_tx.test_signatories()
  verify_multisig(sigs, [], 1) == False
}

test bad_multisig() {
  let sigs = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab"], 2) == False
}

test has_multisig() {
  let sigs = fake_tx.test_signatories()
  verify_multisig(sigs, [#"acab", #"beef"], 2) == True
}

test big_multisig() {
  let sigs = fake_tx.test_signatories()
  verify_multisig(sigs, sigs, 25) == True
}
