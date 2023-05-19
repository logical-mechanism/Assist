//// This module incorporates additional code that expands the
//// functionality of the standard library.
////

use aiken/transaction.{OutputReference, TransactionId}
// used for testing
use tests/fake_tx

/// Create an `OutputReference` from the `TxId#Idx` information. This is useful
/// for building correct output references of specific UTxOs. It can be combined
/// with the `find` module for some very convenient requests.
///
/// ```aiken
/// std.out_ref(that_tx_id, that_tx_idx)
/// ```
pub fn out_ref(tx_id_hash: ByteArray, idx: Int) -> OutputReference {
  let tx_id =
    TransactionId { hash: tx_id_hash }
  OutputReference { transaction_id: tx_id, output_index: idx }
}

test correct_out_ref() {
  let correct_out_ref =
    fake_tx.test_out_ref()
  out_ref(#"acab", 0) == correct_out_ref
}

test bad_out_ref() {
  let correct_out_ref =
    fake_tx.test_out_ref()
  out_ref(#"", 0) != correct_out_ref
}
