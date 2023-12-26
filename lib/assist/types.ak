//// General data types for smart contracts.
////

use aiken/hash.{Blake2b_224, Hash}
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
