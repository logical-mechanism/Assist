//// General data types for smart contracts.
////

use aiken/dict.{Dict}
use aiken/hash.{Blake2b_224, Blake2b_256, Hash}
use aiken/transaction.{Transaction}
use aiken/transaction/credential.{Script, VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId}

/// The public key hash, vkey, of an wallet address. Expected to be length 56 and
/// is network agnostic. This is a non-smart contract hash. 
pub type PublicKeyHash =
  Hash<Blake2b_224, VerificationKey>

/// The validator hash of a smart contract. Expected to be length 56 and
/// is network agnostic. This is a smart contract hash. 
pub type ValidatorHash =
  Hash<Blake2b_224, Script>

/// The transaction hash. Its the blake2b 256 of a tx body.
pub type TxHash =
  Hash<Blake2b_256, Transaction>

/// A wallet type for a non-smart contract address.
pub type Wallet {
  pkh: PublicKeyHash,
  sc: PublicKeyHash,
}

/// A token type for a safe single policy id and asset name value.
pub type Token {
  pid: PolicyId,
  tkn: AssetName,
  amt: Int,
}

/// The generic CIP68 metadatum type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type CIP68 {
  metadata: Dict<Data, Data>,
  version: Int,
}
