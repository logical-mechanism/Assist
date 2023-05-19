//// This module contains code for extracting data from a potential inline 
//// datum found in either an input or output.
////

use aiken/transaction.{InlineDatum, Input, Output}
// for testing only
use tests/fake_tx

/// Find the datum data on an input or error. The data is assumed
/// to be an inline datum.
///
/// ```aiken
/// expect datum: Datum = data.input_datum(this_input)
/// ```
pub fn input_datum(possible_input: Input) -> Data {
  when possible_input.output.datum is {
    InlineDatum(inbound_datum) ->
      inbound_datum
    _ ->
      error @"No Input Datum"
  }
}

// can't test for errors yet
test find_input_datum() {
  let input =
    fake_tx.test_input()
  expect datum: ByteArray =
    input_datum(input)
  datum == fake_tx.test_datum
}

/// Find the datum data on an output or error. The data is assumed
/// to be an inline datum.
///
/// ```aiken
/// expect datum: Datum = data.output_datum(that_output)
/// ```
pub fn output_datum(possible_output: Output) -> Data {
  when possible_output.datum is {
    InlineDatum(outbound_datum) ->
      outbound_datum
    _ ->
      error @"No Output Datum"
  }
}

// can't test for errors yet
test find_output_datum() {
  let output =
    fake_tx.test_output()
  expect datum: ByteArray =
    output_datum(output)
  datum == fake_tx.test_datum
}
