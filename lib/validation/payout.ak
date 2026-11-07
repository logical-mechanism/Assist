//// This module contains code that assists with payout logic. Payout
//// functions are designed to return a boolean value instead of an error.
////

use aiken/collection/list
use cardano/address.{Address}
use cardano/addresses
use cardano/assets.{Assets}
use cardano/transaction.{Output, Transaction}
use cardano/values
// for testing only
use tests/fake_tx

/// Find the first occurrence of an exact output that matches a specific
/// address and value. If nothing is found then return False.
///
/// ```aiken
/// payout.exact(wallet_addr, validating_value, tx.outputs)
/// ```
pub fn exact(
  payout_address: Address,
  payout_value: Assets,
  outputs: List<Output>,
) -> Bool {
  list.any(
    outputs,
    fn(output) {
      and {
        output.address == payout_address,
        output.value == payout_value,
      }
    },
  )
}

test find_exact_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"face", #"")
  let val: Assets = assets.from_lovelace(40)
  exact(addr, val, tx.outputs) == True
}

test missing_exact_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Assets = assets.from_lovelace(40)
  exact(addr, val, tx.outputs) == False
}

test more_than_exact_is_not_exact() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"face", #"")
  let val: Assets = assets.from_lovelace(39)
  exact(addr, val, tx.outputs) == False
}

/// Find the first occurrence of an output that contains at least some specific
/// value at some address. If nothing is found then return False. This function
/// does not search for an exact UTxO match.
///
/// ```aiken
/// payout.at_least(wallet_addr, just_token_value, tx.outputs)
/// ```
pub fn at_least(
  payout_address: Address,
  payout_value: Assets,
  outputs: List<Output>,
) -> Bool {
  list.any(
    outputs,
    fn(output) {
      and {
        output.address == payout_address,
        values.contains(output.value, payout_value),
      }
    },
  )
}

test at_least_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Assets = assets.from_asset(#"acab", #"beef", 40)
  at_least(addr, val, tx.outputs) == True
}

test find_just_enough_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Assets = assets.from_asset(#"acab", #"beef", 20)
  at_least(addr, val, tx.outputs) == True
}

test missing_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Assets = assets.from_asset(#"acab", #"beef", 60)
  at_least(addr, val, tx.outputs) == False
}

test negative_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Assets = assets.from_asset(#"acab", #"beef", -20)
  at_least(addr, val, tx.outputs) == True
}

test right_value_wrong_address_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"cafe", #"")
  let val: Assets = assets.from_lovelace(40)
  at_least(addr, val, tx.outputs) == False
}
