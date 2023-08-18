# v0.3.0

- Upgrade to Aiken 1.14 and Stdlib 1.5, list.and and list.or have been removed.

# v0.2.3

- Added in a function to calculate the total amount of some specific token inside all the transaction inputs. 
- Two new prefixes are now added, callable and database. 
- The 555 prefix is being depreciated and will be removed in v0.2.4.
- Added in a function to check if a mint is occurring inside a transaction.

# v0.2.2

- Added minting functions for exact mints and by_prefix mints. 
- A experimental cip68 prefix has been added to prefixes.

# v0.2.1

- CIP68 prefixes have been fixed. The unique token name function still produces correct names but any length checks needs to be adjusted. New prefix length is now 4.

# v0.1.6

- Does not work with Aiken versions below v1.0.7-alpha Aiken and v1.1.0 Stdlib.

## Changes

- Fake Tx is updated with new `MintedValue` type.
- Value add is now value merge. All Values functions have been updated.

# v0.1.5 and below

- Works with v1.0.6-alpha Aiken and v1.0.0 Stdlib