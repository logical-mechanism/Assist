//// This is for testing only.
////

use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Spend, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{StakeCredential}
use aiken/transaction/value
use assist/addresses
use assist/credentials

/// A test datum.
pub const test_datum: ByteArray =
  #"acabbeeffacecafe"

/// A `Data`data type
pub type DataType =
  Data

/// Creates an `OutputReference`
pub fn test_out_ref() -> OutputReference {
  let out_ref =
    OutputReference {
      transaction_id: TransactionId { hash: #"acab" },
      output_index: 0,
    }
  out_ref
}

/// A fake input used for testing.
pub fn test_input() -> Input {
  let input =
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"acab" },
        output_index: 0,
      },
      output: Output {
        address: addresses.create_address(#"acab", #""),
        value: value.from_lovelace(100),
        datum: InlineDatum(test_datum),
        reference_script: None,
      },
    }
  input
}

/// A fake output used for testing.
pub fn test_output() -> Output {
  let output =
    Output {
      address: addresses.create_address(#"acab", #""),
      value: value.from_asset(#"acab", #"beef", 40),
      datum: InlineDatum(test_datum),
      reference_script: None,
    }
  output
}

/// A fake transaction used for testing.
pub fn test_tx() -> Transaction {
  let sc: StakeCredential =
    credentials.create_stake_credential(#"face")
  let out_ref =
    test_out_ref()
  let withdrawal =
    dict.new()
      |> dict.insert(key: sc, value: 100, compare: fn(_, _) { Equal })
  let d: DataType =
    1
  let redeem =
    dict.new()
      |> dict.insert(key: Spend(out_ref), value: d, compare: fn(_, _) { Equal })
  let tx =
    Transaction {
      inputs: [
        Input {
          output_reference: out_ref,
          output: Output {
            address: addresses.create_address(#"acab", #""),
            value: value.from_lovelace(100),
            datum: InlineDatum(test_datum),
            reference_script: None,
          },
        },
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 1,
          },
          output: Output {
            address: addresses.create_address(#"face", #""),
            value: value.from_lovelace(5),
            datum: NoDatum,
            reference_script: None,
          },
        },
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 1,
          },
          output: Output {
            address: addresses.create_address(#"face", #""),
            value: value.from_lovelace(5),
            datum: NoDatum,
            reference_script: None,
          },
        },
      ],
      reference_inputs: [],
      outputs: [
        Output {
          address: addresses.create_address(#"acab", #""),
          value: value.from_asset(#"acab", #"beef", 40),
          datum: InlineDatum(test_datum),
          reference_script: None,
        },
        Output {
          address: addresses.create_address(#"face", #""),
          value: value.from_lovelace(40),
          datum: NoDatum,
          reference_script: None,
        },
        Output {
          address: addresses.create_address(#"face", #""),
          value: value.from_lovelace(60),
          datum: NoDatum,
          reference_script: None,
        },
      ],
      fee: value.zero(),
      mint: value.zero(),
      certificates: [],
      withdrawals: withdrawal,
      validity_range: Interval {
        lower_bound: IntervalBound {
          bound_type: NegativeInfinity,
          is_inclusive: True,
        },
        upper_bound: IntervalBound {
          bound_type: PositiveInfinity,
          is_inclusive: True,
        },
      },
      extra_signatories: [#"acab", #"beef", #"face"],
      redeemers: redeem,
      datums: dict.new(),
      id: TransactionId { hash: #"" },
    }
  tx
}
