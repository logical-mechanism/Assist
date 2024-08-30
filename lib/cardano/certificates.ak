//// This module incorporates code for generating valid certificates,
//// ensuring their correctness. 
////

use aiken/crypto.{ScriptHash}
use cardano/address.{Script}
use cardano/certificate.{
  Certificate, DelegateBlockProduction, DelegateCredential, StakePoolId,
}

/// Creates a credential delegation for changing the location of the stake.
/// This certificate can be used to check if stake is being delegated to
/// a specific pool.
///
/// ```aiken
/// certificates.create_credential_delegation(datum.contract_hash, datum.pool_id)
/// ```
pub fn delegate_credential(sc: ScriptHash, pool_id: StakePoolId) -> Certificate {
  DelegateCredential {
    credential: Script(sc),
    delegate: DelegateBlockProduction { stake_pool: pool_id },
  }
}

test simple_delegate_credential() {
  let cred: Certificate =
    DelegateCredential {
      credential: Script(#""),
      delegate: DelegateBlockProduction { stake_pool: #"" },
    }
  delegate_credential(#"", #"") == cred
}
