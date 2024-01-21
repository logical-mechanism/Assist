use assist/types/hashes.{PublicKeyHash}

/// A wallet type for a non-smart contract address.
pub type Wallet {
  pkh: PublicKeyHash,
  sc: PublicKeyHash,
}