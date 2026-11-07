//// This module incorporates code for various minting and burning validations.
////
//// Every function takes the transaction's `mint` field (an `Assets` value)
//// directly, so there is no need to `assets.flatten` it first. stdlib flags
//// flattening as too expensive for on-chain use.
////
//// To read the minted quantity of an asset, use stdlib's
//// `assets.quantity_of(tx.mint, pid, tkn)`.
////

use aiken/collection/dict
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/assets.{AssetName, Assets, PolicyId}
use types/cip68

/// This checks if a specific policy id, token name, and amount exist inside
/// the mint value. It is searching for an exact match. A positive `amt` is a
/// mint and a negative `amt` is a burn. An `Assets` value never holds a zero
/// quantity, so `amt == 0` always returns False.
///
/// ```aiken
/// minting.exact(tx.mint, pid, tkn, 1)
/// ```
pub fn exact(mint: Assets, pid: PolicyId, tkn: AssetName, amt: Int) -> Bool {
  amt != 0 && assets.quantity_of(mint, pid, tkn) == amt
}

test good_exact_mint() {
  let mint: Assets = assets.from_asset(#"acab", #"beef", 1)
    |> assets.merge(assets.from_asset(#"fade", #"cafe", -1))
  exact(mint, #"acab", #"beef", 1) == True
}

test bad_exact_mint() {
  let mint: Assets = assets.from_asset(#"acab", #"beef", 1)
  exact(mint, #"acab", #"face", 1) == False
}

test wrong_amount_exact_mint() {
  let mint: Assets = assets.from_asset(#"acab", #"beef", 2)
  exact(mint, #"acab", #"beef", 1) == False
}

test good_exact_burn() {
  let mint: Assets = assets.from_asset(#"acab", #"beef", 1)
    |> assets.merge(assets.from_asset(#"fade", #"cafe", -1))
  exact(mint, #"fade", #"cafe", -1) == True
}

test bad_exact_burn() {
  let mint: Assets = assets.from_asset(#"acab", #"beef", 1)
    |> assets.merge(assets.from_asset(#"fade", #"cafe", -1))
  exact(mint, #"acab", #"beef", -1) == False
}

test empty_exact_mint() {
  exact(assets.zero, #"", #"", 0) == False
}

/// This checks if some token under a policy id starts with a prefix and has
/// exactly the amount `amt`. Instead of searching for an exact token name
/// match, it checks if the token name has the correct prefix. This works if
/// every token name on the policy id is unique. If found then it returns True
/// else False. Prefixes of any length are supported. An empty prefix matches
/// every token name.
///
/// ```aiken
/// minting.by_prefix(tx.mint, pid, cip68.prefix_222, 1)
/// ```
pub fn by_prefix(
  mint: Assets,
  pid: PolicyId,
  prefix: ByteArray,
  amt: Int,
) -> Bool {
  assets.tokens(mint, pid)
    |> dict.to_pairs()
    |> list.any(
        fn(Pair(tkn, quantity)) {
          quantity == amt && bytearray.starts_with(tkn, prefix)
        },
      )
}

test good_by_prefix_mint() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_222, 1)
  by_prefix(mint, #"acab", cip68.prefix_222, 1) == True
}

test good_by_prefix_mint_with_suffix() {
  let mint: Assets = assets.from_asset(#"acab", #"000de140cafe", 1)
    |> assets.add(#"acab", #"000643b0cafe", 1)
  by_prefix(mint, #"acab", cip68.prefix_222, 1) == True
}

test good_by_prefix_burn() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_222, -1)
  by_prefix(mint, #"acab", cip68.prefix_222, -1) == True
}

test bad_by_prefix_mint() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_333, 1)
  by_prefix(mint, #"acab", cip68.prefix_222, 1) == False
}

test bad_by_prefix_burn() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_333, -1)
  by_prefix(mint, #"acab", cip68.prefix_222, -1) == False
}

test bad_by_prefix_wrong_policy() {
  let mint: Assets = assets.from_asset(#"cafe", cip68.prefix_222, 1)
  by_prefix(mint, #"acab", cip68.prefix_222, 1) == False
}

test empty_by_prefix_mint() {
  by_prefix(assets.zero, #"", #"", 0) == False
}

/// Prove that a transaction is minting something from a specific policy id
/// and token name but the amount does not matter. This is great for lock-n-mint
/// style contracts where some logic just needs to check if a mint is occurring
/// but not the specifics of the amount being minted or burned. If a mint or
/// burn is occurring then it will return True else False.
///
/// ```aiken
/// minting.is_occurring(tx.mint, pid, tkn)
/// ```
pub fn is_occurring(mint: Assets, pid: PolicyId, tkn: AssetName) -> Bool {
  assets.quantity_of(mint, pid, tkn) != 0
}

test tx_is_empty_minting() {
  is_occurring(assets.zero, #"acab", cip68.prefix_222) == False
}

test tx_is_minting() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_222, 1)
  is_occurring(mint, #"acab", cip68.prefix_222) == True
}

test tx_is_burning() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_222, -5)
  is_occurring(mint, #"acab", cip68.prefix_222) == True
}

test tx_is_not_minting() {
  let mint: Assets = assets.from_asset(#"acab", cip68.prefix_222, 1)
  is_occurring(mint, #"acab", cip68.prefix_333) == False
}
