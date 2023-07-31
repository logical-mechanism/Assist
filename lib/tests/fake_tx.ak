//// This is for testing only.
////

use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Spend, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{StakeCredential}
use aiken/transaction/value
use assist/addresses
use assist/credentials

/// A test datum.
pub const test_datum: ByteArray = #"acabbeeffacecafe"

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
pub fn test_inputs(amt: Int) -> List<Input> {
  let input =
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"acab" },
        output_index: 0,
      },
      output: Output {
        address: addresses.create_address(#"acab", #""),
        value: value.from_asset(#"acab", #"beef", 100),
        datum: InlineDatum(#""),
        reference_script: None,
      },
    }
  list.repeat(input, amt)
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

/// A fake list of tx signers
pub fn test_signatories() -> List<ByteArray> {
  [
    #"acab", #"beef", #"face", #"acba", #"befe", #"faec", #"caab", #"ebef",
    #"afce", #"acab00", #"beef00", #"face00", #"acba00", #"befe00", #"faec00",
    #"caab00", #"ebef00", #"afce00", #"acab0011", #"beef0011", #"face0011",
    #"acba0011", #"befe0011", #"faec0011", #"caab0011", #"ebef0011", #"afce0011",
    #"acab99", #"beef99", #"face99", #"acba99", #"befe99", #"faec99", #"caab99",
    #"ebef99", #"afce99", #"acab0099", #"beef0099", #"face0099", #"acba0099",
    #"befe0099", #"faec0099", #"caab0099", #"ebef0099", #"afce0099",
    #"acab001199", #"beef001199", #"face001199", #"acba001199", #"befe001199",
    #"faec001199", #"caab001199", #"ebef001199", #"afce001199",
  ]
}

/// A fake transaction used for testing.
pub fn test_tx() -> Transaction {
  let sc: StakeCredential = credentials.create_stake_credential(#"face")
  let out_ref = test_out_ref()
  let withdrawal =
    dict.new()
      |> dict.insert(key: sc, value: 100, compare: fn(_, _) { Equal })
  let d: DataType = 1
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
      mint: value.to_minted_value(value.zero()),
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
      extra_signatories: test_signatories(),
      redeemers: redeem,
      datums: dict.new(),
      id: TransactionId { hash: #"" },
    }
  tx
}
