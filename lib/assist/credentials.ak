// //// This module incorporates code for generating valid credentials,
// //// ensuring their correctness. 
// ////

// use aiken/transaction/credential.{
//   Credential, Inline, Referenced, ScriptCredential,
// }
// use assist/types/hashes.{ValidatorHash}

// /// Creates a stake credential from the hex encoding of a stake key.
// /// This can be used to find the reward amount from the withdrawals 
// /// information inside the transaction of the form `Dict<StakeCredential, Int>`.
// ///
// /// ```aiken
// /// credentials.create_stake_credential(datum.contract_hash)
// /// ```
// pub fn create_stake_credential(sc: ValidatorHash) -> Referenced<Credential> {
//   Inline(ScriptCredential(sc))
// }

// test simple_stake_credential() {
//   create_stake_credential(#"") == Inline(ScriptCredential(#""))
// }
