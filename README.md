# Aiken Assist Library

The **Aiken Assist Library** is a collection of specialized functions for [Aiken](https://github.com/aiken-lang/aiken). This library extends the default functionality of [stdlib](https://github.com/aiken-lang/stdlib) and provides routines that facilitate quick development of smart contracts on Cardano.

## Compatibility

aiken's version | assist's version
---             | ---
`v1.1.5+`       | `>= v0.5.1`
`v1.0.29-alpha` | `== v0.4.11`

Assist library `v0.5.x+` will be Plutus V3+. For Plutus V2 contracts use the `v0.4.11` branch.

## Getting Started

To start using the library, follow these steps:

1. Import the library with the command:

```bash
aiken packages add logical-mechanism/assist --version v0.5.1
```

- Stay up to date by updating the version to the newest tag when applicable, i.e. `v0.5.1` -> `v0.5.x`.

2. Compile your project by running the command `aiken check` in your project directory. If a complete recheck is required then run the command:

```bash
rm -fr build || true
aiken check
```

## Usage

To use the **Aiken Assist Library** in your project, import the desired submodules into your `.ak` file. For example:

```rust
use tx/signing
use types/wallet.{Wallet}
use cardano/prefixes.{database}
```

Please refer to the documentaiton for available Assist modules.

## Documentation

You can generate the library's documentation locally by running the command `aiken docs` in your project directory. Alternatively, you can view the [online documentation](https://www.logicalmechanism.io/docs/index.html) for detailed information on the library's functions and usage.

## Contributing

Want to contribute? See [CONTRIBUTING.md](./CONTRIBUTING.md) to know how.

## Contact

For any questions or feedback, please contact the project maintainer at `support@logicalmechanism.io`.

## License

The **Aiken Assist Library** is released under the Apache2 License. See the `LICENSE` file for more details.
