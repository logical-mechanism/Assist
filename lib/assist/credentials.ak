//// This module incorporates code for generating valid credentials,
//// ensuring their correctness. 
////

use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{
  Credential, Inline, Referenced, Script, ScriptCredential,
}

/// Creates a stake credential from the hex encoding of a stake key.
/// This can be used to find the reward amount from the withdrawals 
/// information inside the transaction of the form Dict<StakeCredential, Int>
///
/// ```aiken
/// credentials.create_stake_credential(datum.contract_hash)
/// ```
pub fn create_stake_credential(
  sc: Hash<Blake2b_224, Script>,
) -> Referenced<Credential> {
  Inline(ScriptCredential(sc))
}

test simple_stake_credential() {
  create_stake_credential(#"") == Inline(ScriptCredential(#""))
}
