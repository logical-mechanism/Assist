use aiken/transaction.{OutputReference, TransactionId}
// used for testing
use tests/fake_tx

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
