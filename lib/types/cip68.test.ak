//// Property-based tests for `types/cip68`.

use aiken/builtin
use aiken/collection/list
use aiken/fuzz
use types/cip68.{CIP68}

// ## Fuzzers

/// Integers, bytes, or lists of them, as found in CIP-68 metadata.
fn small_data() -> Fuzzer<Data> {
  fuzz.either3(
    fuzz.map(
      fuzz.int(),
      fn(n) {
        let d: Data = n
        d
      },
    ),
    fuzz.map(
      fuzz.bytearray_between(0, 32),
      fn(b) {
        let d: Data = b
        d
      },
    ),
    fuzz.map(
      fuzz.list_between(fuzz.bytearray_between(0, 8), 0, 3),
      fn(xs) {
        let d: Data = xs
        d
      },
    ),
  )
}

/// Metadata with unique keys, and one of those keys.
fn metadata_with_key() -> Fuzzer<(Pairs<Data, Data>, Data)> {
  let (keys, key) <- fuzz.and_then(
    fuzz.set_between(fuzz.bytearray_between(0, 16), 1, 8)
      |> fuzz.and_then(
          fn(keys) { fuzz.map(fuzz.one_of(keys), fn(key) { (keys, key) }) },
        ),
  )
  let values <- fuzz.map(
    fuzz.list_between(small_data(), list.length(keys), list.length(keys)),
  )
  let metadata = list.map(
    list.zip(keys, values),
    fn(pair) {
      let (k, v) = pair
      let k: Data = k
      Pair(k, v)
    },
  )
  let key: Data = key
  (metadata, key)
}

fn cip68_datum() -> Fuzzer<CIP68> {
  let (metadata, _) <- fuzz.and_then(metadata_with_key())
  let version <- fuzz.and_then(fuzz.int_between(1, 3))
  let extra <- fuzz.map(fuzz.either(small_data(), fuzz.data()))
  CIP68 { metadata, version, extra }
}

// ## Properties

test prop_get_finds_every_key(
  input via fuzz.tuple(metadata_with_key(), fuzz.int_between(1, 3)),
) {
  let ((metadata, key), version) = input
  let datum = CIP68 { metadata, version, extra: key }
  let expected = list.find_map(
    metadata,
    fn(Pair(k, v)) {
      if k == key {
        Some(v)
      } else {
        None
      }
    },
  )
  Some(cip68.get(datum, key)) == expected
}

test prop_get_fails_for_missing_keys(
  input via fuzz.tuple(metadata_with_key(), fuzz.bytearray_between(17, 32)),
) fail {
  // generated keys are at most 16 bytes, so this key is never present
  let ((metadata, _), missing) = input
  let datum = CIP68 { metadata, version: 1, extra: missing }
  let missing: Data = missing
  cip68.get(datum, missing) == missing
}

test prop_getters_return_fields(datum via cip68_datum()) {
  cip68.version(datum) == datum.version && cip68.extra(datum) == datum.extra
}

test prop_cip68_round_trips_through_data(datum via cip68_datum()) {
  let as_data: Data = datum
  expect decoded: CIP68 = as_data
  decoded == datum
}

test prop_cip68_is_constr_0_with_three_fields(datum via cip68_datum()) {
  // CIP-68 requires `#6.121([metadata, version, extra])`
  let as_data: Data = datum
  let Pair(index, fields) = builtin.un_constr_data(as_data)
  index == 0 && list.length(fields) == 3
}
