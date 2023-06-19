use aiken/bytearray
use aiken/list
use aiken/transaction/value
use assist/prefixes

/// This checks if a specific policy id, token name, and amount exist inside
/// the flattened exact value. It is searching for an exact match. If found
/// then it returns True else False.
///
pub fn exact(
  flat: List<(ByteArray, ByteArray, Int)>,
  pid: ByteArray,
  tkn: ByteArray,
  amt: Int,
) -> Bool {
  when flat is {
    // loop the minted value
    [(policy, token_name, quantity), ..rest] ->
      if list.and([policy == pid, token_name == tkn, quantity == amt]) == True {
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
/// checks if the token name has the correct prefix. This works because
/// every token name will be unique. If found then it returns True else False.
///
pub fn by_prefix(
  flat: List<(ByteArray, ByteArray, Int)>,
  pid: ByteArray,
  prefix: ByteArray,
  amt: Int,
) -> Bool {
  when flat is {
    [(policy, token_name, quantity), ..rest] -> {
      // all cip68 prefixes have the same length
      let p = bytearray.take(token_name, 4)
      if list.and([policy == pid, prefix == p, quantity == amt]) == True {
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
