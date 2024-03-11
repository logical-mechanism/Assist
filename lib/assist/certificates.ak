//// This module incorporates code for generating valid certificates,
//// ensuring their correctness. 
////

use aiken/transaction/certificate.{Certificate, DelegateStaking}
use aiken/transaction/credential.{PoolId}
use aiken/transaction/governance.{DelegateStake}
use assist/credentials
use assist/types/hashes.{ValidatorHash}

/// Creates a credential delegation for changing the location of the stake.
/// This certificate can be used to check if stake is being delegated to
/// a specific pool.
///
/// ```aiken
/// certificates.create_credential_delegation(datum.contract_hash, datum.pool_id)
/// ```
pub fn create_credential_delegation(
  sc: ValidatorHash,
  pool_id: PoolId,
) -> Certificate {
  DelegateStaking(
    credentials.create_stake_credential(sc),
    DelegateStake(pool_id),
  )
}

test simple_credential_delegation() {
  let cred: Certificate =
    DelegateStaking(
      credentials.create_stake_credential(#""),
      DelegateStake(#""),
    )
  create_credential_delegation(#"", #"") == cred
}
