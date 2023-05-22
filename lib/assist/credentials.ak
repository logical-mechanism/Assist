//// This module incorporates code for generating valid credentials,
//// ensuring their correctness. 
////

use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/certificate.{Certificate, CredentialDelegation}
use aiken/transaction/credential.{
  Credential, Inline, PoolId, Referenced, Script, ScriptCredential,
}

/// Creates a stake credential from the hex encoding of a stake key.
/// This can be used to find the reward amount from the withdrawals 
/// information inside the transaction of the form Dict<StakeCredential, Int>
///
/// ```aiken
/// credentials.create_stake_credential(datum.stake_contract_hash)
/// ```
pub fn create_stake_credential(
  sc: Hash<Blake2b_224, Script>,
) -> Referenced<Credential> {
  Inline(ScriptCredential(sc))
}

/// Creates a credential delegation for changing the location of the stake.
/// This certificate can be used to check if stake is being delegated to
/// a specific pool.
///
/// ```aiken
/// credentials.create_credential_delegation(datum.stake_contract_hash, datum.pool_id)
/// ```
pub fn create_credential_delegation(
  sc: Hash<Blake2b_224, Script>,
  pool_id: PoolId,
) -> Certificate {
  CredentialDelegation {
    delegator: create_stake_credential(sc),
    delegatee: pool_id,
  }
}
