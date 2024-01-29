# Aiken Assist Library

The **Aiken Assist Library** is a collection of specialized Aiken functions designed for smart contracts on Cardano. This library extends the default functionality and provides routines that facilitate quick development.

## Getting Started

To start using the library, follow these steps:

1. Open your `aiken.toml` file.

2. Add the following code to bottom of the `aiken.toml` file:

```toml
[[dependencies]]
name = "logicalmechanism/assist"
version = "v0.4.4"
source = "github"
```

3. Save the `aiken.toml` file.

4. Compile your project by running the command `aiken check` in your project directory.

```bash
rm -fr build || true
aiken check
```

- Stay up to date by updating the version to the newest tag when applicable, i.e. `v0.4.2` -> `v0.4.x`.

## Usage

To use the **Aiken Assist Library** in your project, import the desired submodules into your `.ak` file. For example:

```aiken
use assist/signing
use assist/count
```

Assist modules can be found in the documentation.

## Documentation

You can generate the library's documentation locally by running the command `aiken docs` in your project directory. Alternatively, you can view the [online documentation](https://www.logicalmechanism.io/docs/index.html) for detailed information on the library's functions and usage.

## Contributing

Want to contribute? See [CONTRIBUTING.md](./CONTRIBUTING.md) to know how.

## Contact

For any questions or feedback, please contact the project maintainer at `support@logicalmechanism.io`.

## License

The **Aiken Assist Library** is released under the Apache2 License. See the `LICENSE` file for more details.