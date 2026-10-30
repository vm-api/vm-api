# Contributing to VM API

Contributions from all individuals and organizations are welcome: code, tests, documentation, issue triage, and reviews. Follow the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).

## Discuss and submit changes

Use [issues](https://github.com/vm-api/vm-api/issues) for bugs, questions, and proposals. Include reproduction steps, versions, expected behavior, and relevant redacted logs. Discuss API and provider-contract changes before implementation. Report vulnerabilities through [private reporting](https://github.com/vm-api/vm-api/security/advisories/new).

Fork the repository, create a topic branch, and submit a focused PR against `main`. Explain the problem, resulting behavior, compatibility impact, and validation. Include generated CRDs and documentation when applicable. Small, reviewable changes are easier to evaluate. Contributors remain responsible for understanding and validating submitted code, including code produced with tools.

## Developer Certificate of Origin

By signing off a commit you certify the [Developer Certificate of Origin 1.1](https://developercertificate.org/). Read it before signing. Use your own name and an email address matching your commit identity:

```bash
git commit -s -m "Describe the change"
```

The sign-off is a `Signed-off-by` trailer; it is separate from cryptographic commit signing. Sign off every contribution commit. Do not sign for another author or rewrite someone else's commits. If a DCO check reports an error, follow its repair instructions while preserving authorship and coordinate before rewriting a shared branch.

The project uses the DCO rather than requiring an additional project CLA. Installing the DCO GitHub App and requiring its check are repository administration steps; this document alone does not enforce sign-offs.

## Build and validate

Use a Go toolchain compatible with the module declarations and pinned tools. From the repository root:

```bash
make generate
make verify test
make -C controller manager lint test
```

The controller tests launch local API-server and etcd processes using envtest. They do not provision a VM or run a full Kubernetes cluster. API and provider changes should include meaningful regression coverage and describe additional manual testing where needed.

For documentation checks, install `markdownlint-cli` 0.44.0 and `typos` 1.40.0, then run:

```bash
make lint-markdown MDLINT='markdownlint "**/*.md"'
make typos TYPOS=typos
```

The Make targets' default container images currently require private registry access; these overrides work without that access. See the [README](README.md) for module layout and development commands.

## Review and compatibility

Address review comments and keep checks passing. Protected branches require approval and CI; maintainer exceptions must be explained publicly. Changes to API groups, storage versions, defaulting, validation, and provider contracts need explicit compatibility and migration analysis. Do not change the Go dependency floor without evaluating provider consumers. No backport or release-support promise exists until the project publishes one.
