# Aiken Assist Library

The Aiken Assist Library is a collection of specialized Aiken functions designed for smart contracts on Cardano. This library extends the default functionality and provides routines that facilitate quick development.

## Getting Started

To start using the library, follow these steps:

1. Open your aiken.toml file.

2. Add the following code to the dependency section:

```toml
[[dependencies]]
name = "logicalmechanism/assist"
version = "main"
source = "github"
```

3. Save the aiken.toml file.

4. Compile your project by running the command `aiken check` in your project directory.

- If Aiken can't build `assist` then delete the `build` folder and run aiken check again.

## Usage

To use the Aiken Assist Library in your project, import the desired modules in your code. For example:

```aiken
use assist/signing
use assist/count
```

Make sure to adjust the imports based on the specific modules you need.

## Documentation

You can generate the library's documentation locally by running the command `aiken docs` in your project directory. Alternatively, you can view the [online documentation](https://htmlpreview.github.io/?https://raw.githubusercontent.com/logicalmechanism/assist/main/docs/index.html) for detailed information on the library's functions and usage.

## License

The Aiken Assist Library is released under the Apache2 License. See the `LICENSE` file for more details.

## Contact

For any questions or feedback, please contact the project maintainer at `logical.mechanism@protonmail.com`.