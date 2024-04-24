# Contributing

## What & How Can You Contribute?

### **Feedback**

Contributions in the form of feedback and issues are very much welcome. Whether it may be a suggestion, a bug report, or maybe some questions that you have. It helps in improving Assist over time and these are the best kind of contributions to start with.

Do not hesitate to add to the discussion on open issues you support to show your interest.

### **Documentation**

Any updates, typo fixes, or expansion of the documentation is more than welcome. Please refer to the [online documentation](https://www.logicalmechanism.io/docs/index.html). That can be considered to be the library documentation.

### **Code**

**Getting started**

```bash
git clone https://github.com/logicalmechanism/assist.git
cd assist
aiken check
```

If everything runs fine without any errors you're good to go. If you do run into any errors please contact the project maintainer at `support@logicalmechanism.io`.

Pull requests are welcome, but we do recommend you open an issue to bring any idea to discussion first! Especially if the pull request will end up very large, any significant changes should be discussed up front with the maintainer. This avoids awkward situations where someone puts in a bunch of work to ultimately have the pull request closed due to a potential variety of unforeseen reasons.

**Changelog**

Please add an entry into [CHANGELOG.md](./CHANGELOG.md) when submitting changes. New entries should go into the top `# v0.x.y` section. This let's us keep track of unreleased changes for use in release notes.

Example Contributions: 

```md
# v0.x.y

- some new thing
- fixed or updated something
- something is gone now
```

Once a release is ready `# v0.x.y` gets replaced with a version number, i.e. `# v0.4.0`. Usually the maintainers will handle the section renaming along with creating a new empty `# v0.x.y` section at the top of the changelog. When releasing a new version the version number needs to be updated inside `README.md`, `aiken.toml`, and the `CHANGELOG.md`. Run the command below to do a fresh test and rebuild the docs for the final push.

```bash
rm -fr build docs
aiken check
aiken docs
```

### **Donation**

Want to support with crypto?

- Our Ada address is `addr1q8rdcfvj5a27gmp04q5c4nuly385mseam09y777xa8mjn40ax0z9yaxg2mjj3ctg4uj6ggwsc6nja0kj446w2gv5zcvqjk47zh`
