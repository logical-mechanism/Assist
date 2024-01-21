use aiken/dict.{Dict}

/// The generic CIP68 metadatum type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type CIP68 {
  metadata: Dict<Data, Data>,
  version: Int,
}
