//// Property-based tests for `types/wallet`.

use aiken/collection/list
use aiken/fuzz
use aiken/primitive/bytearray
use types/wallet.{Wallet}

/// A key hash of the right length about half of the time.
fn key_hash_candidate() -> Fuzzer<ByteArray> {
  fuzz.either3(
    fuzz.bytearray_fixed(28),
    fuzz.constant(#""),
    fuzz.bytearray_between(1, 40),
  )
}

fn wallet_candidate() -> Fuzzer<Wallet> {
  fuzz.map2(
    key_hash_candidate(),
    key_hash_candidate(),
    fn(pkh, sc) { Wallet { pkh, sc } },
  )
}

test prop_is_valid_spec(w via wallet_candidate()) {
  let result = wallet.is_valid(w)
  fuzz.label_when(result, @"valid", @"invalid")
  let sc_length = bytearray.length(w.sc)
  result == (
    bytearray.length(w.pkh) == 28 && ( sc_length == 0 || sc_length == 28 )
  )
}

test prop_to_vks_keeps_every_key_in_order(
  ws via fuzz.list_between(wallet_candidate(), 0, 8),
) {
  let vks = wallet.to_vks(ws)
  and {
    list.length(vks) == list.length(ws),
    list.all(
      list.zip(ws, vks),
      fn(pair) {
        let (w, vk) = pair
        w.pkh == vk
      },
    ),
  }
}
