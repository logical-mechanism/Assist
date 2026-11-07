//// Property-based tests for `validation/find`.

use aiken/collection/list
use aiken/collection/pairs
use aiken/fuzz
use cardano/address.{Address, Credential, VerificationKey}
use cardano/assets.{Assets}
use cardano/fuzz as cardano
use cardano/transaction.{
  Datum, InlineDatum, Input, NoDatum, Output, Redeemer, ScriptPurpose, Spend,
}
use cardano/values
use validation/find

// ## Fuzzers

const policy: ByteArray =
  #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

/// Three addresses, so that several outputs share one and "first" matters.
fn pooled_address() -> Fuzzer<Address> {
  fuzz.one_of(
    [
      Address {
        payment_credential: VerificationKey(
          #"0000000000000000000000000000000000000000000000000000000a",
        ),
        stake_credential: None,
      },
      Address {
        payment_credential: VerificationKey(
          #"0000000000000000000000000000000000000000000000000000000b",
        ),
        stake_credential: None,
      },
      Address {
        payment_credential: VerificationKey(
          #"0000000000000000000000000000000000000000000000000000000c",
        ),
        stake_credential: None,
      },
    ],
  )
}

/// A value holding lovelace and maybe one or two of a small set of tokens.
fn pooled_value() -> Fuzzer<Assets> {
  let lovelace <- fuzz.and_then(fuzz.int_between(1, 5))
  let tokens <- fuzz.map(
    fuzz.list_between(
      fuzz.tuple(fuzz.one_of([#"01", #"02", #"03"]), fuzz.int_between(1, 2)),
      0,
      2,
    ),
  )
  list.foldl(
    tokens,
    assets.from_lovelace(lovelace),
    fn(t, acc) {
      let (name, amt) = t
      assets.add(acc, policy, name, amt)
    },
  )
}

fn pooled_datum() -> Fuzzer<Datum> {
  fuzz.either3(
    cardano.no_datum(),
    cardano.inline_datum_with(
      fuzz.map(
        fuzz.int_between(0, 9),
        fn(n) {
          let d: Data = n
          d
        },
      ),
    ),
    cardano.datum_hash(),
  )
}

fn pooled_output() -> Fuzzer<Output> {
  cardano.output_with(
    pooled_address(),
    pooled_value(),
    pooled_datum(),
    fuzz.constant(None),
  )
}

fn pooled_input() -> Fuzzer<Input> {
  cardano.input_with(cardano.output_reference(), pooled_output())
}

fn first(xs: List<a>, predicate: fn(a) -> Bool) -> Option<a> {
  xs |> list.filter(predicate) |> list.head()
}

// ## First input

test prop_first_input_index_and_txid(
  inputs via fuzz.list_between(pooled_input(), 1, 8),
) {
  expect Some(head) = list.head(inputs)
  and {
    find.first_input_index(inputs) == head.output_reference.output_index,
    find.first_input_txid(inputs) == head.output_reference.transaction_id,
  }
}

// ## Inputs

test prop_input_by_ref_finds_member(
  input via fuzz.list_with_elem(pooled_input()),
) {
  let (inputs, member) = input
  find.input_by_ref(inputs, member.output_reference).output_reference == member.output_reference
}

test prop_input_by_addr_returns_first_match(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 1, 8),
    pooled_address(),
  ),
) {
  let (inputs, addr) = input
  when first(inputs, fn(i) { i.output.address == addr }) is {
    Some(expected) -> find.input_by_addr(inputs, addr) == expected
    // the failure path is covered by the unit tests
    None -> True
  }
}

test prop_input_by_nft_returns_first_holder(
  input via fuzz.tuple(
    fuzz.list_between(pooled_input(), 1, 8),
    fuzz.one_of([#"01", #"02", #"03"]),
  ),
) {
  let (inputs, name) = input
  when
    first(
      inputs,
      fn(i) { assets.quantity_of(i.output.value, policy, name) == 1 },
    )
  is {
    Some(expected) -> {
      fuzz.label(@"holder found")
      find.input_by_nft(inputs, policy, name) == expected
    }
    None -> {
      fuzz.label(@"no holder")
      True
    }
  }
}

// ## Outputs

test prop_output_by_addr_returns_first_match(
  input via fuzz.tuple(
    fuzz.list_between(pooled_output(), 1, 8),
    pooled_address(),
  ),
) {
  let (outputs, addr) = input
  when first(outputs, fn(o) { o.address == addr }) is {
    Some(expected) -> find.output_by_addr(outputs, addr) == expected
    None -> True
  }
}

test prop_output_by_value_returns_first_container(
  input via fuzz.tuple(fuzz.list_between(pooled_output(), 1, 8), pooled_value()),
) {
  let (outputs, v) = input
  when first(outputs, fn(o) { values.contains(o.value, v) }) is {
    Some(expected) -> {
      fuzz.label(@"container found")
      let found = find.output_by_value(outputs, v)
      found == expected && values.contains(found.value, v)
    }
    None -> {
      fuzz.label(@"no container")
      True
    }
  }
}

test prop_output_by_addr_value_returns_first_match(
  input via fuzz.tuple3(
    fuzz.list_between(pooled_output(), 1, 8),
    pooled_address(),
    pooled_value(),
  ),
) {
  let (outputs, addr, v) = input
  when
    first(outputs, fn(o) { o.address == addr && values.contains(o.value, v) })
  is {
    Some(expected) -> find.output_by_addr_value(outputs, addr, v) == expected
    None -> True
  }
}

test prop_first_output_datum_skips_other_datums(
  outputs via fuzz.list_between(pooled_output(), 1, 8),
) {
  let inline = list.filter_map(
    outputs,
    fn(o) {
      when o.datum is {
        InlineDatum(d) -> Some(d)
        _ -> None
      }
    },
  )
  when inline is {
    [expected, ..] -> find.first_output_datum(outputs) == expected
    [] -> True
  }
}

test prop_output_datum_by_nft_reads_the_holder(
  input via fuzz.tuple3(
    fuzz.list_between(pooled_output(), 0, 8),
    fuzz.int_between(0, 9),
    fuzz.list_between(pooled_output(), 0, 8),
  ),
) {
  // a unique token held by one output with an inline datum
  let (before, n, after) = input
  let datum: Data = n
  let holder = Output {
    address: Address {
      payment_credential: VerificationKey(
        #"0000000000000000000000000000000000000000000000000000000d",
      ),
      stake_credential: None,
    },
    value: assets.from_lovelace(2) |> assets.add(policy, #"ff", 1),
    datum: InlineDatum(datum),
    reference_script: None,
  }
  find.output_datum_by_nft(
    list.concat(before, [holder, ..after]),
    policy,
    #"ff",
  ) == datum
}

// ## Withdrawals and redeemers

fn some_withdrawals() -> Fuzzer<Pairs<Credential, Int>> {
  fuzz.such_that(cardano.withdrawals(), fn(w) { !list.is_empty(w) })
}

test prop_stake_reward_by_sc_finds_each_withdrawal(
  withdrawals via some_withdrawals(),
) {
  list.all(
    withdrawals,
    fn(Pair(credential, amount)) {
      find.stake_reward_by_sc(withdrawals, credential) == amount
    },
  )
}

test prop_redeemer_by_ref_finds_spend_redeemers(
  refs via fuzz.set_between(cardano.output_reference(), 1, 6),
) {
  let redeemers: Pairs<ScriptPurpose, Redeemer> = list.indexed_map(
    refs,
    fn(ix, out_ref) {
      let redeemer: Redeemer = ix
      Pair(Spend(out_ref), redeemer)
    },
  )
  list.all(
    refs,
    fn(out_ref) {
      Some(find.redeemer_by_ref(redeemers, out_ref)) == pairs.get_first(
        redeemers,
        Spend(out_ref),
      )
    },
  )
}

test prop_no_datum_means_no_datum_by_addr(
  input via fuzz.tuple(
    fuzz.list_between(pooled_output(), 0, 8),
    pooled_address(),
  ),
) fail {
  // with every datum removed, a datum can never be found
  let (outputs, addr) = input
  let stripped = list.map(outputs, fn(o) { Output { ..o, datum: NoDatum } })
  find.output_datum_by_addr(stripped, addr) == find.output_datum_by_addr(
    stripped,
    addr,
  )
}
