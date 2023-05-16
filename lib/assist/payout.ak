//// This module includes code to help with payout logic.
////

use aiken/transaction.{Output}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use assist/addresses
// for testing only
use tests/fake_tx

/// Find the first occurrence of an exact output that matches a specific
/// address and value. If nothing is found then return False.
///
/// ```aiken
/// payout.find_exact(wallet_addr, validating_value, tx.outputs)
/// ```
pub fn find_exact(
  pay_address: Address,
  pay_value: Value,
  outputs: List<Output>,
) -> Bool {
  when outputs is {
    [output, ..rest] ->
      // exact address and value
      if output.address == pay_address && output.value == pay_value {
        True
      } else {
        find_exact(pay_address, pay_value, rest)
      }
    [] ->
      False
  }
}

test find_exact_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"face", #"")
  let val =
    value.from_lovelace(40)
  find_exact(addr, val, tx.outputs) == True
}

test missing_exact_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  let val =
    value.from_lovelace(40)
  find_exact(addr, val, tx.outputs) == False
}

/// Find the first occurrence of an output that contains at least some specific
/// value at some address. If nothing is found then return False. This function
/// does not search for an exact UTxO match.
///
/// ```aiken
/// payout.find_token(wallet_addr, just_token_value, tx.outputs)
/// ```
pub fn find_token(
  pay_address: Address,
  pay_value: Value,
  outputs: List<Output>,
) -> Bool {
  let flattened_value =
    value.flatten(pay_value)
  when outputs is {
    [output, ..rest] ->
      if
      output.address == pay_address && check_all_assets(
        output.value,
        flattened_value,
      ) == True{
      
        True
      } else {
        find_token(pay_address, pay_value, rest)
      }
    [] ->
      False
  }
}

// given a list of tokens check if at least the quantity is in the value.
fn check_all_assets(
  out_value: Value,
  flattened_value: List<(PolicyId, AssetName, Int)>,
) -> Bool {
  when flattened_value is {
    [(policy, token_name, quantity), ..rest] ->
      if value.quantity_of(out_value, policy, token_name) >= quantity {
        check_all_assets(out_value, rest)
      } else {
        False
      }
    // All the tokens exist
    [] ->
      True
  }
}

test find_token_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  let val =
    value.from_asset(#"acab", #"beef", 40)
  find_token(addr, val, tx.outputs) == True
}

test find_just_enough_token_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  let val =
    value.from_asset(#"acab", #"beef", 20)
  find_token(addr, val, tx.outputs) == True
}

test missing_token_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  let val =
    value.from_asset(#"acab", #"beef", 60)
  find_token(addr, val, tx.outputs) == False
}

/// Find the first occurrence of an output at some address. If nothing is 
/// found then return False. This function does not search by value.
///
/// ```aiken
/// payout.find_cont(that_script_addr, tx.outputs)
/// ```
pub fn find_cont(pay_address: Address, outputs: List<Output>) -> Bool {
  when outputs is {
    [output, ..rest] ->
      if output.address == pay_address {
        True
      } else {
        find_cont(pay_address, rest)
      }
    [] ->
      False
  }
}

test find_cont_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"acab", #"")
  find_cont(addr, tx.outputs) == True
}

test missing_cont_payout() {
  let tx =
    fake_tx.test_tx()
  let addr =
    addresses.create_address(#"cafe", #"")
  find_cont(addr, tx.outputs) == False
}
