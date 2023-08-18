use aiken/bytearray
use aiken/transaction/value
use assist/prefixes

/// This checks if a specific policy id, token name, and amount exist inside
/// the flattened exact value. It is searching for an exact match. If found
/// then it returns True else False.
///
/// ```aiken
/// minting.exact(flatten_mint_value, pid, tkn, 1)
/// ```
pub fn exact(
  flat: List<(ByteArray, ByteArray, Int)>,
  pid: ByteArray,
  tkn: ByteArray,
  amt: Int,
) -> Bool {
  when flat is {
    // loop the minted value
    [(policy, token_name, quantity), ..rest] ->
      if and {
        policy == pid,
        token_name == tkn,
        quantity == amt,
      } == True {
        True
      } else {
        exact(rest, pid, tkn, amt)
      }
    // something wasn't found
    [] -> False
  }
}

test good_exact_mint() {
  let flat =
    value.from_asset(#"acab", #"beef", 1)
      |> value.merge(value.from_asset(#"fade", #"cafe", -1))
      |> value.flatten()
  exact(flat, #"acab", #"beef", 1) == True
}

test bad_exact_mint() {
  let flat = value.from_asset(#"acab", #"beef", 1) |> value.flatten()
  exact(flat, #"acab", #"face", 1) == False
}

test good_exact_burn() {
  let flat =
    value.from_asset(#"acab", #"beef", 1)
      |> value.merge(value.from_asset(#"fade", #"cafe", -1))
      |> value.flatten()
  exact(flat, #"fade", #"cafe", -1) == True
}

test bad_exact_burn() {
  let flat =
    value.from_asset(#"acab", #"beef", 1)
      |> value.merge(value.from_asset(#"fade", #"cafe", -1))
      |> value.flatten()
  exact(flat, #"acab", #"beef", -1) == False
}

test empty_exact_mint() {
  let flat = value.zero() |> value.flatten()
  exact(flat, #"", #"", 0) == False
}

/// This checks if a specific policy id, prefix, and amount exist inside
/// the flattened exact value. Instead of searching for exact match, it
/// checks if the token name has the correct prefix. This works if
/// every token name on the policy id is unique. If found then it returns
/// True else False.
///
/// ```aiken
/// minting.by_prefix(flatten_mint_value, pid, tkn, 1)
/// ```
pub fn by_prefix(
  flat: List<(ByteArray, ByteArray, Int)>,
  pid: ByteArray,
  prefix: ByteArray,
  amt: Int,
) -> Bool {
  when flat is {
    // loop all the value for the flat value
    [(policy, token_name, quantity), ..rest] -> {
      // all cip68 prefixes have the same length
      let p = bytearray.take(token_name, 4)
      if and {
        policy == pid,
        prefix == p,
        quantity == amt,
      } == True {
        True
      } else {
        by_prefix(rest, pid, prefix, amt)
      }
    }
    // something wasn't found
    [] -> False
  }
}

test good_by_prefix_mint() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_222, 1) |> value.flatten()
  by_prefix(flat, #"acab", prefixes.prefix_222, 1) == True
}

test good_by_prefix_burn() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_222, -1) |> value.flatten()
  by_prefix(flat, #"acab", prefixes.prefix_222, -1) == True
}

test bad_by_prefix_mint() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_333, 1) |> value.flatten()
  by_prefix(flat, #"acab", prefixes.prefix_222, 1) == False
}

test bad_by_prefix_burn() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_333, -1) |> value.flatten()
  by_prefix(flat, #"acab", prefixes.prefix_222, -1) == False
}

test empty_by_prefix_mint() {
  let flat = value.zero() |> value.flatten()
  by_prefix(flat, #"", #"", 0) == False
}

/// Prove that a transaction is minting something from a specific policy id 
/// and token name but the amount does not matter. This is great for lock-n-mint
/// style contracts where some logic just needs to check if a mint is occuring
/// but not the specifics of the amount being minted or burned. If a mint is
/// occurring then it will return True else False.
///
/// ```aiken
/// minting.is_occurring(flatten_mint_value, pid, tkn)
/// ```
pub fn is_occurring(
  flat: List<(ByteArray, ByteArray, Int)>,
  pid: ByteArray,
  tkn: ByteArray,
) -> Bool {
  when flat is {
    // loop the minted value
    [(policy, token_name, _), ..rest] ->
      if and {
        policy == pid,
        token_name == tkn,
      } == True {
        True
      } else {
        is_occurring(rest, pid, tkn)
      }
    // something wasn't found
    [] -> False
  }
}

test tx_is_empty_minting() {
  let flat =
    []
  is_occurring(flat, #"acab", prefixes.prefix_222) == False
}

test tx_is_minting() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_222, 1) |> value.flatten()
  is_occurring(flat, #"acab", prefixes.prefix_222) == True
}

test tx_is_not_minting() {
  let flat =
    value.from_asset(#"acab", prefixes.prefix_222, 1) |> value.flatten()
  is_occurring(flat, #"acab", prefixes.prefix_333) == False
}
