use aiken/dict.{Dict}

/// The generic CIP68 metadatum type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type CIP68 {
  metadata: Dict<Data, Data>,
  version: Int,
}

/// Attempt to find a data structure by a key inside the cip68 metadatum. If
/// nothing is found then fail.
///
/// ```aiken
/// cip68.get(datum, some_key)
/// ```
pub fn get(cip68: CIP68, key: Data) -> Data {
  when dict.get(cip68.metadata, key) is {
    Some(thing) -> thing
    None -> fail @"Data Structure Not Found"
  }
}

/// Return the version of the metadata.
///
/// ```aiken
/// datum |> cip68.version
/// ```
pub fn version(metadata: CIP68) -> Int {
  metadata.version
}
