//// This module incorporates code for generating valid wallet and script 
//// addresses, ensuring their correctness. Empty keys are treated as 
//// intentional, and address subtypes are not combined nor mixed. The key
//// lengths must be valid as these functions will ignore invalid key
//// keys when generating Address types.
////

use aiken/bytearray
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, VerificationKeyCredential,
}
use assist/types/hashes.{PublicKeyHash, ValidatorHash}
use assist/types/wallet.{Wallet}

/// Creates an address from the Wallet type. This should be used primairly for
/// creating an address as the Wallet type has a `is_valid` function that should
/// be used in the same validaiton.
///
/// ```aiken
/// let addr: Address = types.from_wallet(this_wallet)
/// ```
pub fn from_wallet(wallet: Wallet) -> Address {
  create_address(wallet.pkh, wallet.sc)
}

/// Creates a enterprise or base address from the public key hash and stake
/// credential. An empty sc means enterpise address by default. This function
/// assumes proper key lengths for `pkh`.Address types should be generated from
/// the Wallet type so proper length checks are done with the `wallet.is_valid`
/// function located in `types/wallet.ak`.
///
///
/// ```aiken
/// addresses.create_address(datum.wallet.pkh, datum.wallet.sc)
/// ```
pub fn create_address(pkh: PublicKeyHash, sc: PublicKeyHash) -> Address {
  // stake credentials that are empty bytearrays or incorrect length bytearrays
  // should not add to the pkh. This will prevent paitial and invalid addresses
  if or {
    bytearray.is_empty(sc),
    bytearray.length(sc) != 28,
  } {
    credential.from_verification_key(pkh)
  } else {
    credential.from_verification_key(pkh)
      |> credential.with_delegation_key(sc)
  }
}

test enterprise_wallet() {
  let addr: Address =
    Address {
      payment_credential: VerificationKeyCredential(#"acab"),
      stake_credential: None,
    }
  create_address(#"acab", #"") == addr
}

test bad_base_wallet() {
  let addr: Address =
    Address {
      payment_credential: VerificationKeyCredential(#"acab"),
      stake_credential: None,
    }
  create_address(#"acab", #"face") == addr
}

test incorrect_stake_key() {
  let addr: Address =
    Address {
      payment_credential: VerificationKeyCredential(#"acab"),
      stake_credential: Some(Inline(VerificationKeyCredential(#""))),
    }
  create_address(#"acab", #"") != addr
}

test correct_wallet_address() {
  let addr: Address =
    Address {
      payment_credential: VerificationKeyCredential(
        #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
      ),
      stake_credential: Some(
        Inline(
          VerificationKeyCredential(
            #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
          ),
        ),
      ),
    }
  create_address(
    #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
    #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
  ) == addr
}

test script_address_is_not_wallet_address() {
  let addr: Address =
    Address {
      payment_credential: VerificationKeyCredential(
        #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
      ),
      stake_credential: Some(
        Inline(
          VerificationKeyCredential(
            #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
          ),
        ),
      ),
    }
  create_script_address(
    #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
    #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
  ) != addr
}

/// Creates a script address for a smart contract. The type does not mix
/// address types. Staking credentials are assumed to be smart contracts. An 
/// empty stake credential or bad length stake credential is invalid and will
/// be assumed to be not staked. This function assumes proper key lengths for `vkh`.
///
/// ```aiken
/// addresses.create_script_address(datum.script.vkh, datum.script.sc)
/// ```
pub fn create_script_address(vkh: ValidatorHash, sc: ValidatorHash) -> Address {
  // empty bytearrays means dont add the sc to the pkh
  if or {
    bytearray.is_empty(sc),
    bytearray.length(sc) != 28,
  } {
    credential.from_script(vkh)
  } else {
    credential.from_script(vkh)
      |> credential.with_delegation_script(sc)
  }
}

test enterprise_script() {
  let script_addr: Address =
    Address {
      payment_credential: ScriptCredential(#"acab"),
      stake_credential: None,
    }
  create_script_address(#"acab", #"") == script_addr
}

test bad_base_script() {
  let script_addr: Address =
    Address {
      payment_credential: ScriptCredential(#"acab"),
      stake_credential: None,
    }
  create_script_address(#"acab", #"face") == script_addr
}

test incorrect_script_stake_crendential() {
  let script_addr: Address =
    Address {
      payment_credential: ScriptCredential(#"acab"),
      stake_credential: Some(Inline(ScriptCredential(#""))),
    }
  create_script_address(#"acab", #"") != script_addr
}

test correct_script_address() {
  let addr: Address =
    Address {
      payment_credential: ScriptCredential(
        #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
      ),
      stake_credential: Some(
        Inline(
          ScriptCredential(
            #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
          ),
        ),
      ),
    }
  create_script_address(
    #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
    #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
  ) == addr
}

test wallet_address_is_not_script_address() {
  let addr: Address =
    Address {
      payment_credential: ScriptCredential(
        #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
      ),
      stake_credential: Some(
        Inline(
          ScriptCredential(
            #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
          ),
        ),
      ),
    }
  create_address(
    #"de0c6347552dc5e84f5ba1e945c57c1ce3c49b2c2b8ce7c96bcc8de7",
    #"6f124ce78e70688a2c333ada555df1ef0d8bda44143ee4cc13ac2dc1",
  ) != addr
}
