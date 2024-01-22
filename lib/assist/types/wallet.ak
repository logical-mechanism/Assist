use aiken/bytearray
use assist/types/hashes.{PublicKeyHash}

/// A wallet type for a non-smart contract address.
pub type Wallet {
  pkh: PublicKeyHash,
  sc: PublicKeyHash,
}

/// Check if a wallet has a bad form and needs to be bypassed.
/// The pkh must be the length 56 hex string and the sc is either empty or
/// it is also a length 56 hex string.
///
/// ```aiken
/// wallet.is_valid(datum.wallet)
/// ```
pub fn is_valid(wallet: Wallet) -> Bool {
  if and {
    // if pkh is 28 then true else false
    bytearray.length(wallet.pkh) == 28,
    // sc is either empty or 28
    or {
      bytearray.is_empty(wallet.sc),
      bytearray.length(wallet.sc) == 28,
    },
  } {
    // wallet is valid
    True
  } else {
    // wallet is not valid
    False
  }
}

test is_valid_pkh() {
  let w: Wallet =
    Wallet {
      pkh: #"abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
      sc: #"",
    }
  is_valid(w)
}

test is_valid_pkh_sc() {
  let w: Wallet =
    Wallet {
      pkh: #"abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
      sc: #"abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
    }
  is_valid(w)
}

test is_invalid_sc() {
  let w: Wallet =
    Wallet {
      pkh: #"abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
      sc: #"abcd89abcdef0123456789abcdef0123456789abcdef01",
    }
  is_valid(w) == False
}

test is_invalid_pkh() {
  let w: Wallet =
    Wallet { pkh: #"abcdef9abcdef0123456789abcdef0123456789abcdef0", sc: #"" }
  is_valid(w) == False
}
