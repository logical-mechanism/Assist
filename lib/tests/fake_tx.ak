use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
  TransactionId,
}
use aiken/transaction/value
use assist/addresses

/// A fake input used for testing.
pub fn test_input() -> Input {
  let input =
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"" },
        output_index: 0,
      },
      output: Output {
        address: addresses.create_address(#"acab", #""),
        value: value.from_lovelace(100),
        datum: InlineDatum(#"acabbeeffacecafe"),
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
      datum: InlineDatum(#"acabbeeffacecafe"),
      reference_script: None,
    }
  output
}

/// A fake transaction used for testing.
pub fn test_tx() -> Transaction {
  let tx =
    Transaction {
      inputs: [
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 0,
          },
          output: Output {
            address: addresses.create_address(#"acab", #""),
            value: value.from_lovelace(100),
            datum: InlineDatum(#"acabbeeffacecafe"),
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
          datum: InlineDatum(#"acabbeeffacecafe"),
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
      withdrawals: dict.new(),
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
      redeemers: dict.new(),
      datums: dict.new(),
      id: TransactionId { hash: #"" },
    }
  tx
}
