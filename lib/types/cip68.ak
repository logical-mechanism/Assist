//// Constants and a datum type for the CIP-68 metadata standard.
////

use aiken/collection/pairs
use aiken/primitive/bytearray

/// (100) Reference Token Prefix
/// https://developers.cardano.org/docs/governance/cardano-improvement-proposals/cip-0068/#222-nft-standard
pub const prefix_100: ByteArray = #"000643b0"

/// (222) Non-Fungible Token Prefix
/// https://developers.cardano.org/docs/governance/cardano-improvement-proposals/cip-0068/#222-nft-standard
pub const prefix_222: ByteArray = #"000de140"

/// (333) Fungible Token Prefix
/// https://developers.cardano.org/docs/governance/cardano-improvement-proposals/cip-0068/#333-ft-standard
pub const prefix_333: ByteArray = #"0014df10"

/// (444) Rich-Fungible Token Prefix
/// https://developers.cardano.org/docs/governance/cardano-improvement-proposals/cip-0068/#333-ft-standard
pub const prefix_444: ByteArray = #"001bc280"

/// The generic CIP68 metadatum type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type CIP68 {
  metadata: Pairs<Data, Data>,
  version: Int,
  extra: Data,
}

/// Attempt to find a data structure by a key inside the cip68 metadatum. If
/// nothing is found then fail.
///
/// ```aiken
/// cip68.get(metadatum, some_key)
/// ```
pub fn get(cip68: CIP68, key: Data) -> Data {
  when pairs.get_first(cip68.metadata, key) is {
    Some(value) -> value
    None -> fail @"Data Structure Not Found"
  }
}

// A fixture shaped like a CIP-68 (222) reference datum.
// Internal only
fn fixture() -> CIP68 {
  let name: Data = #"6e616d65"
  let image: Data = #"696d616765"
  let name_value: Data = #"4c6f676963"
  let image_value: Data = #"697066733a2f2f"
  CIP68 {
    metadata: [Pair(name, name_value), Pair(image, image_value)],
    version: 1,
    extra: #"",
  }
}

test get_finds_first_key() {
  let name: Data = #"6e616d65"
  let expected: Data = #"4c6f676963"
  get(fixture(), name) == expected
}

test get_finds_later_key() {
  let image: Data = #"696d616765"
  let expected: Data = #"697066733a2f2f"
  get(fixture(), image) == expected
}

test get_prefers_first_duplicate() {
  let key: Data = 1
  let first: Data = 2
  let second: Data = 3
  let datum: CIP68 = CIP68 {
    metadata: [Pair(key, first), Pair(key, second)],
    version: 1,
    extra: first,
  }
  get(datum, key) == first
}

test get_missing_key_fails() fail {
  let missing: Data = #"00"
  let found: Data = get(fixture(), missing)
  found == missing
}

test cip68_round_trips_through_data() {
  let datum: Data = fixture()
  expect decoded: CIP68 = datum
  decoded == fixture()
}

test cip68_prefixes_are_four_bytes() {
  and {
    prefix_100 != prefix_222,
    prefix_222 != prefix_333,
    prefix_333 != prefix_444,
    bytearray.length(prefix_100) == 4,
    bytearray.length(prefix_222) == 4,
    bytearray.length(prefix_333) == 4,
    bytearray.length(prefix_444) == 4,
  }
}

/// Return the version of the metadata.
///
/// ```aiken
/// metadatum |> cip68.version
/// ```
pub fn version(metadata: CIP68) -> Int {
  metadata.version
}

/// Return the extra data of the metadata.
///
/// ```aiken
/// metadatum |> cip68.extra
/// ```
pub fn extra(metadata: CIP68) -> Data {
  metadata.extra
}

test version_getter() {
  version(fixture()) == 1
}

test extra_getter() {
  let expected: Data = #""
  extra(fixture()) == expected
}
