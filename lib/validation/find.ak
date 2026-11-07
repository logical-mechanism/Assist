//// This module contains code for finding various aspects of
//// a validating transaction. Every function here fails with a descriptive
//// trace when nothing is found. For `Option`-returning lookups see stdlib's
//// `list.find`, `transaction.find_input`, and `pairs.get_first`.
////

use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Address, Credential, Script}
use cardano/addresses
use cardano/assets.{AssetName, Assets, PolicyId}
use cardano/datum
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Redeemer, ScriptPurpose, Spend,
  Transaction,
}
use cardano/values
// for testing only
use tests/fake_tx

/// Find the first input's output reference index.
/// Output references have the form `TxId#Idx`, this function
/// extracts the `Idx` part. If nothing is found then error.
///
/// ```aiken
/// find.first_input_index(tx.inputs)
/// ```
pub fn first_input_index(inputs: List<Input>) -> Int {
  when inputs is {
    [input, ..] -> input.output_reference.output_index
    [] -> fail @"No First Input Index Found"
  }
}

test find_first_input_index() {
  let inputs: List<Input> = fake_tx.test_tx().inputs
  first_input_index(inputs) == 0
}

test cant_find_first_input_index() fail {
  let inputs: List<Input> = []
  // this will fail
  first_input_index(inputs) == 0
}

/// Find the first input's output reference transaction id hash.
/// Output references have the form `TxId#Idx`, this function
/// extracts the `TxId` part. If nothing is found then error.
///
/// ```aiken
/// find.first_input_txid(tx.inputs)
/// ```
pub fn first_input_txid(inputs: List<Input>) -> ByteArray {
  when inputs is {
    [input, ..] -> input.output_reference.transaction_id
    [] -> fail @"No First Input TxId Found"
  }
}

test find_first_input_txid() {
  let inputs: List<Input> = fake_tx.test_tx().inputs
  first_input_txid(inputs) == #"acab"
}

test cant_find_first_input_txid() fail {
  let inputs: List<Input> = []
  // this will fail
  first_input_txid(inputs) == #"acab"
}

/// Find an input by an output reference. If nothing is found then error.
/// Similar to stdlib's `transaction.find_input` but errors instead of
/// returning an `Option`, and to `transaction.resolve_input` but returns the
/// whole `Input` instead of its `Output`.
///
/// ```aiken
/// find.input_by_ref(tx.inputs, out_ref)
/// ```
pub fn input_by_ref(inputs: List<Input>, out_ref: OutputReference) -> Input {
  when transaction.find_input(inputs, out_ref) is {
    Some(input) -> input
    None -> fail @"No Input Found By Output Reference"
  }
}

test find_input_by_ref() {
  let inputs: List<Input> = fake_tx.test_tx().inputs
  let out_ref: OutputReference = OutputReference {
    transaction_id: #"acab",
    output_index: 0,
  }
  input_by_ref(inputs, out_ref) == fake_tx.test_input()
}

test cant_find_input_by_ref() fail {
  let inputs: List<Input> = []
  let out_ref: OutputReference = OutputReference {
    transaction_id: #"acab",
    output_index: 0,
  }
  // this will fail
  input_by_ref(inputs, out_ref) == fake_tx.test_input()
}

/// Find the first occurrence of an input by a specific address. If nothing
/// is found then error. The address here is an exact match, so both the
/// pkh and sc need to be correct.
///
/// ```aiken
/// find.input_by_addr(tx.reference_inputs, ref_addr)
/// ```
pub fn input_by_addr(inputs: List<Input>, addr: Address) -> Input {
  when list.find(inputs, fn(input) { input.output.address == addr }) is {
    Some(input) -> input
    None -> fail @"No Input Found By Address"
  }
}

test find_input_by_addr() {
  let inputs: List<Input> = fake_tx.test_tx().inputs
  let addr: Address = addresses.create_address(#"acab", #"")
  input_by_addr(inputs, addr) == fake_tx.test_input()
}

test cant_find_input_by_addr() fail {
  let inputs: List<Input> = []
  let addr: Address = addresses.create_address(#"acab", #"")
  // this will fail
  input_by_addr(inputs, addr) == fake_tx.test_input()
}

/// Find the first occurrence of an output by a specific address. If nothing
/// is found then error. The address here is an exact match.
///
/// ```aiken
/// find.output_by_addr(tx.outputs, your_address)
/// ```
pub fn output_by_addr(outputs: List<Output>, addr: Address) -> Output {
  when list.find(outputs, fn(output) { output.address == addr }) is {
    Some(output) -> output
    None -> fail @"No Output Found By Address"
  }
}

test find_output_by_addr() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  let addr: Address = addresses.create_address(#"acab", #"")
  output_by_addr(outputs, addr) == fake_tx.test_output()
}

test cant_find_output_by_addr() fail {
  let outputs: List<Output> = []
  let addr: Address = addresses.create_address(#"acab", #"")
  // this will fail
  output_by_addr(outputs, addr) == fake_tx.test_output()
}

/// Find the first output with an inline datum and return the datum.
/// If nothing is found then error. This works great for tx with a
/// single output and datum or where ordering is irrelevant.
///
/// ```aiken
/// find.first_output_datum(tx.outputs)
/// ```
pub fn first_output_datum(outputs: List<Output>) -> Data {
  when
    list.find_map(
      outputs,
      fn(output) {
        when output.datum is {
          InlineDatum(outbound_datum) -> Some(outbound_datum)
          _ -> None
        }
      },
    )
  is {
    Some(outbound_datum) -> outbound_datum
    None -> fail @"No First Output Datum Found"
  }
}

test find_first_output_datum() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  expect datum: ByteArray = first_output_datum(outputs)
  datum == fake_tx.test_datum
}

test find_first_output_datum_skips_no_datum() {
  let outputs: List<Output> = [fake_tx.test_bad_output(), fake_tx.test_output()]
  expect datum: ByteArray = first_output_datum(outputs)
  datum == fake_tx.test_datum
}

test cant_find_first_output_datum() fail {
  let outputs: List<Output> = []
  expect datum: ByteArray = first_output_datum(outputs)
  // this will fail
  datum == fake_tx.test_datum
}

/// Find the first occurrence of output datum by some address. If nothing is
/// found then error.
///
/// ```aiken
/// expect datum: Datum = find.output_datum_by_addr(tx.outputs, this_addr)
/// ```
pub fn output_datum_by_addr(outputs: List<Output>, addr: Address) -> Data {
  let outbound_output: Output = output_by_addr(outputs, addr)
  datum.output_datum(outbound_output)
}

test find_output_datum_by_addr() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  let addr: Address = addresses.create_address(#"acab", #"")
  expect datum: ByteArray = output_datum_by_addr(outputs, addr)
  datum == fake_tx.test_datum
}

test cant_find_output_datum_by_addr() fail {
  let outputs: List<Output> = []
  let addr: Address = addresses.create_address(#"acab", #"")
  expect datum: ByteArray = output_datum_by_addr(outputs, addr)
  // this will fail
  datum == fake_tx.test_datum
}

/// Return the first occurrence of an output that contains at least some specific
/// value at some address. If nothing is found then error. This function
/// does not search for an exact UTxO match.
///
/// ```aiken
/// find.output_by_addr_value(tx.outputs, wallet_addr, just_token_value)
/// ```
pub fn output_by_addr_value(
  outputs: List<Output>,
  addr: Address,
  value: Assets,
) -> Output {
  when
    list.find(
      outputs,
      fn(output) {
        and {
          output.address == addr,
          values.contains(output.value, value),
        }
      },
    )
  is {
    Some(output) -> output
    None -> fail @"No Output Found By Address And Value"
  }
}

test find_output_by_addr_value() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  let addr: Address = addresses.create_address(#"acab", #"")
  let value: Assets = assets.from_asset(#"acab", #"beef", 40)
  output_by_addr_value(outputs, addr, value) == fake_tx.test_output()
}

test find_just_enough_output_by_addr_value() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  let addr: Address = addresses.create_address(#"acab", #"")
  let value: Assets = assets.from_asset(#"acab", #"beef", 20)
  output_by_addr_value(outputs, addr, value) == fake_tx.test_output()
}

test cant_find_output_by_addr_value() fail {
  let outputs: List<Output> = []
  let addr: Address = addresses.create_address(#"acab", #"")
  let value: Assets = assets.from_asset(#"acab", #"beef", 40)
  // this will fail
  output_by_addr_value(outputs, addr, value) == fake_tx.test_output()
}

/// Return the first occurrence of an output that contains at least some specific
/// value. If nothing is found then error. This function
/// does not search for an exact UTxO match.
///
/// ```aiken
/// find.output_by_value(tx.outputs, just_token_value)
/// ```
pub fn output_by_value(outputs: List<Output>, value: Assets) -> Output {
  when
    list.find(outputs, fn(output) { values.contains(output.value, value) })
  is {
    Some(output) -> output
    None -> fail @"No Output Found By Value"
  }
}

test find_output_by_value() {
  let outputs: List<Output> = fake_tx.test_tx().outputs
  let value: Assets = assets.from_asset(#"acab", #"beef", 10)
  output_by_value(outputs, value) == fake_tx.test_output()
}

test cant_find_output_by_value() fail {
  let outputs: List<Output> = []
  let value: Assets = assets.from_asset(#"acab", #"beef", 10)
  // this will fail
  output_by_value(outputs, value) == fake_tx.test_output()
}

/// Find the staking reward amount in lovelace for some stake credential.
/// If no rewards are available then error. This is a great method for
/// checking on-chain staking rewards and withdrawal validation.
///
/// ```aiken
/// find.stake_reward_by_sc(tx.withdrawals, datum.wallet.sc)
/// ```
pub fn stake_reward_by_sc(
  withdraws: Pairs<Credential, Int>,
  stake_credential: Credential,
) -> Int {
  when pairs.get_first(withdraws, stake_credential) is {
    Some(reward) -> reward
    None -> fail @"No Staking Rewards Available"
  }
}

test find_stake_reward_by_sc() {
  let withdrawal: Pairs<Credential, Int> = fake_tx.test_tx().withdrawals
  stake_reward_by_sc(withdrawal, Script(#"acab")) == 100
}

test cant_find_stake_reward_by_sc() fail {
  let withdrawal: Pairs<Credential, Int> = []
  stake_reward_by_sc(withdrawal, Script(#"face")) == 0
}

/// Find a redeemer data by an output reference. This is good for checking
/// if a specific redeemer is being used on some specific UTxO inside
/// the transaction.
///
/// ```aiken
/// find.redeemer_by_ref(tx.redeemers, that_out_ref)
/// ```
pub fn redeemer_by_ref(
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  out_ref: OutputReference,
) -> Data {
  // make sure only the spend purpose here
  when pairs.get_first(redeemers, Spend(out_ref)) is {
    Some(redeemer) -> redeemer
    None -> fail @"No Spend Redeemer Found"
  }
}

test find_redeemer_by_ref() {
  let tx: Transaction = fake_tx.test_tx()
  expect datum: Int = redeemer_by_ref(tx.redeemers, fake_tx.test_out_ref())
  datum == 1
}

test cant_find_redeemer_by_ref() fail {
  let tx: Transaction = fake_tx.test_tx()
  // this will fails
  expect datum: Int = redeemer_by_ref(tx.redeemers, fake_tx.test_bad_out_ref())
  datum == 1
}

/// Find the inline datum on the first output that holds exactly one of a
/// specific token (see `assets.has_nft`). Fails if no output holds the token,
/// or if the first output holding it has no inline datum.
///
/// ```aiken
/// expect datum: Datum = find.output_datum_by_nft(tx.outputs, pid, tkn)
/// ```
pub fn output_datum_by_nft(
  outputs: List<Output>,
  pid: PolicyId,
  tkn: AssetName,
) -> Data {
  when
    list.find(outputs, fn(output) { assets.has_nft(output.value, pid, tkn) })
  is {
    Some(output) ->
      when output.datum is {
        // inline and holding the nft
        InlineDatum(outbound_datum) -> outbound_datum
        _ -> fail @"No Datum On Output"
      }
    None -> fail @"No Datum Found In Outputs"
  }
}

test find_output_datum_by_nft() {
  let outputs: List<Output> = fake_tx.test_bad_outputs()
  expect outcome: ByteArray = output_datum_by_nft(outputs, #"fade", #"cafe")
  outcome == fake_tx.test_datum
}

test cant_find_output_datum_by_nft1() fail {
  let outputs: List<Output> = fake_tx.test_bad_outputs()
  expect outcome: ByteArray = output_datum_by_nft(outputs, #"fadebeef", #"cafe")
  outcome == fake_tx.test_datum
}

test cant_find_output_datum_by_nft2() fail {
  let outputs: List<Output> = fake_tx.test_bad_outputs()
  expect outcome: ByteArray = output_datum_by_nft(outputs, #"fade", #"fade")
  outcome == fake_tx.test_datum
}

/// Find the first input that holds exactly one of a specific token (see
/// `assets.has_nft`). If nothing is found then error.
///
/// ```aiken
/// find.input_by_nft(tx.inputs, pid, tkn)
/// ```
pub fn input_by_nft(inputs: List<Input>, pid: PolicyId, tkn: AssetName) -> Input {
  when
    list.find(
      inputs,
      fn(input) { assets.has_nft(input.output.value, pid, tkn) },
    )
  is {
    Some(input) -> input
    None -> fail @"No Input Found In Inputs"
  }
}

test cant_find_input_by_nft() fail {
  let inputs: List<Input> = fake_tx.test_bad_inputs()
  let input: Input = input_by_nft(inputs, #"acab", #"beef")
  input == fake_tx.test_one_lovelace_input()
}

test can_find_input_by_nft() {
  let inputs: List<Input> = fake_tx.test_bad_inputs()
  let input: Input = input_by_nft(inputs, #"", #"")
  input == fake_tx.test_one_lovelace_input()
}
