use aiken/transaction/value.{AssetName, PolicyId, Value}

/// A token type for a safe single policy id and asset name value.
pub type Token {
  pid: PolicyId,
  tkn: AssetName,
  amt: Int,
}

/// A tokens type for a safe value as a list of Tokens.
pub type Tokens =
  List<Token>

/// Add a Token type to a Value type. This should be a very safe way to
/// increment a value on a UTxO. The other option is having the redeemer be 
/// the general Value type and potentially allow badly formed values to be used.
///
/// ```aiken
/// add_token_to_value(token, this_value)
/// ```
pub fn add_token_to_value(the_value: Value, token: Token) -> Value {
  value.add(the_value, token.pid, token.tkn, token.amt)
}

test add_empty_token_to_value() {
  let zero: Value = value.zero()
  let token: Token = Token { pid: #"", tkn: #"", amt: 0 }
  add_token_to_value(zero, token) == zero
}

test add_ada_token_to_value() {
  let zero: Value = value.zero()
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  add_token_to_value(zero, token) == value.from_lovelace(10)
}

test add_and_subtract_token_to_value() {
  let zero: Value = value.zero()
  let token1: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let token2: Token = Token { pid: #"", tkn: #"", amt: -10 }
  let expected: Value =
    add_token_to_value(zero, token1) |> add_token_to_value(token2)
  expected == zero
}

/// Add a list of Token types to a Value type. This should be a very safe way to
/// increment a value on a UTxO. The other option is having the redeemer be 
/// the general Value type and potentially allow badly formed values to be used.
///
/// ```aiken
/// add_tokens_to_value(redeemer.tokens, this_value)
/// ```
fn add_tokens_to_value(the_value: Value, tokens: Tokens) -> Value {
  when tokens is {
    // take a token and add it to the value
    [tkn, ..rest] ->
      add_token_to_value(the_value, tkn) |> add_tokens_to_value(rest)
    // return the value
    [] -> the_value
  }
}

test add_empty_tokens_to_value() {
  let zero: Value = value.zero()
  let token: Token = Token { pid: #"", tkn: #"", amt: 0 }
  add_tokens_to_value(zero, [token, token, token]) == zero
}

test add_ada_tokens_to_value() {
  let zero: Value = value.zero()
  let token: Token = Token { pid: #"", tkn: #"", amt: 10 }
  add_tokens_to_value(zero, [token, token, token]) == value.from_lovelace(30)
}

test add_and_subtract_tokens_to_value() {
  let zero: Value = value.zero()
  let token1: Token = Token { pid: #"", tkn: #"", amt: 10 }
  let token2: Token = Token { pid: #"", tkn: #"", amt: -10 }
  add_tokens_to_value(zero, [token1, token2]) == zero
}
