<img src="docs/assets/vm-api-logo.svg#gh-light-mode-only" alt="VM API logo" width="420">
<img src="docs/assets/vm-api-logo-white.svg#gh-dark-mode-only" alt="VM API logo" width="420">

VM API provides a provider-neutral Kubernetes API for managing virtual machines across infrastructure platforms. It defines portable VM configuration and a generic controller, while infrastructure providers provision and manage the underlying machines.

A `VirtualMachine` describes compute, storage, networking, guest bootstrap, and desired power state. Its `spec.infrastructureRef` identifies a provider-owned resource. The generic controller observes that resource through a shared status contract without importing provider-specific Go types.

## Capabilities

- Declarative VM configuration through Kubernetes custom resources.
- Provider integration through an infrastructure reference and a shared status contract.
- Ownership and deletion coordination between generic and provider resources.
- Provider-reported power state, addresses, identity, metadata, and readiness conditions.
- Generated CRDs with schema validation, defaults, and printer columns.

The current API is `vm-api.io/v1alpha1`. API evolution and provider compatibility are active development areas; see the [roadmap](ROADMAP.md). The API group shown here matches the checked-in types and manifests.

## Community

VM API follows the [CNCF Community Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md). See our [Code of Conduct](CODE_OF_CONDUCT.md) for private reporting guidance.

## Documentation

- [Implementing a provider](docs/implementing-a-provider.md)
- [Development roadmap](ROADMAP.md)
- [Example VirtualMachine](config/samples/virtualmachine.yaml)

## Repository layout

| Directory | Contents |
|---|---|
| [api/v1alpha1](api/v1alpha1/) | API types, scheme registration, and generated deepcopy code |
| [config/crd/bases](config/crd/bases/) | Generated CRD manifests |
| [config/samples](config/samples/) | Example resource manifests |
| [controller](controller/) | Generic controller and its tests |
| [controller/internal/contract](controller/internal/contract/) | Provider status contract |
| [docs](docs/) | Architecture and provider documentation |
| [hack/boilerplate](hack/boilerplate/) | Code generation license headers |

## Development

Use a Go toolchain compatible with the module declarations and pinned development tools. The API and controller are separate Go modules; run their checks independently.

From the repository root:

```bash
make help              # List available targets
make generate          # Generate deepcopy code and CRDs
make build             # Build the API module
make test              # Test the API module
make verify            # Build, lint, and verify generated files
make modules           # Tidy API module dependencies
```

For the controller:

```bash
cd controller
go build ./...
make lint
make test
```

The controller test target installs its Ginkgo and envtest dependencies. Root code-generation and lint tools are installed on demand at pinned versions defined in the [Makefile](Makefile).

The optional `make lint-markdown` and `make typos` targets use container images. Their current defaults require access to a private registry; contributors without that access must supply compatible images through `MDLINT_IMAGE` and `TYPOS_IMAGE`. The build, Go lint, and code-generation checks do not require that registry.

The [CI workflow](.github/workflows/ci.yml) runs the API and controller Go lint targets, Markdown lint, and typo checks for pull requests to `main` and release branches, and pushes to `main`. It installs public tools without private registry credentials. To run the same documentation checks locally with installed tools:

```bash
# Install markdownlint-cli 0.44.0 and typos 1.40.0 first.
make lint-markdown MDLINT='markdownlint "**/*.md"'
make typos TYPOS=typos
```

## Install the API

Install the CRD into a Kubernetes cluster:

```bash
kubectl apply -f config/crd/bases/
```

To manage VMs, install a compatible infrastructure provider and run a manager containing the generic controller. Configure the namespace, image, network, storage, and Secret references for your environment, and create the provider resource referenced by the [sample](config/samples/virtualmachine.yaml) before applying it:

```bash
kubectl apply -f config/samples/virtualmachine.yaml
```

Installing the CRD alone does not provision a VM. Both controllers and the referenced provider resource are required. The sample illustrates the API shape; its catalog and provider references must be adapted to resources supported by your provider.

## Go modules

Import the API types from `github.com/vm-api/vm-api/api/v1alpha1`.
The core controller is a separate module, `github.com/vm-api/vm-api/controller`.
Its local `replace` directive uses the API module from the same checkout.

Go module release versions and Kubernetes API versions are independent. A Go
release tag does not change the served or storage API version. Root module
release tags use `vX.Y.Z`; controller module tags use `controller/vX.Y.Z`.
Before publishing a controller module for external consumers, replace its local
API dependency placeholder with a published API module version: downstream Go
modules do not inherit dependency `replace` directives.

## API scope and compatibility

- **API version:** `v1alpha1` is the current served and storage version. Additional versions and conversion support require an explicit compatibility design.
- **Provider discovery:** `infrastructureRef` contains an API group, kind, and name. The controller resolves the preferred served version through Kubernetes discovery.
- **Provider status:** providers report `providerID`, `powerState`, `addresses`, `providerMetadata`, and the `InfrastructureReady` and `UpToDate` conditions. See the [contract implementation](controller/internal/contract/contract.go).
- **Catalogs:** image and network references require provider-specific resolution. This repository does not currently define companion image or network catalog resources.
- **Accelerators:** sizing profiles can select accelerator-backed instances where supported by the provider. A dedicated portable accelerator field is planned for further design work.
- **Conformance:** a shared conformance suite and explicit provider version compatibility are roadmap items.

The API module keeps its dependency floor low to support a broad range of provider implementations. Evaluate dependency upgrades against provider compatibility rather than coupling them to an individual provider's toolchain.
