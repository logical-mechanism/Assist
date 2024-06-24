use aiken/builtin

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
}

/// Attempt to find a data structure by a key inside the cip68 metadatum. If
/// nothing is found then fail.
///
/// ```aiken
/// cip68.get(metadatum, some_key)
/// ```
pub fn get(cip68: CIP68, key: Data) -> Data {
  do_get(cip68.metadata, key)
}

fn do_get(cip68: Pairs<Data, Data>, key: Data) -> Data {
  when cip68 is {
    [] -> fail @"Data Structure Not Found"
    [d, ..ds] ->
      if builtin.fst_pair(d) == key {
        builtin.snd_pair(d)
      } else {
        do_get(ds, key)
      }
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
