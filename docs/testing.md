# Testing VM API

## API smoke test on kind

Run from the repository root:

```bash
make test-smoke
```

Prerequisites: Go with automatic toolchain downloads enabled, Python 3 and curl, and a running Docker daemon or Podman machine. Allow network access to download the pinned kind and kubectl tools and node image. The target installs kind and checksum-verified kubectl locally under the ignored tooling directory; it does not replace a system installation. The tested baseline is kind v0.33.0 with Kubernetes and kubectl v1.34.11, with the node image pinned by digest in the [Makefile](../Makefile). This is one smoke-test baseline, not a supported Kubernetes version matrix.

The test creates a uniquely named, single-node cluster with a temporary kubeconfig. It installs the checked-in CRD, waits for its Established condition, verifies namespaced API discovery and resource verbs, and creates and reads a [representative VirtualMachine](../hack/smoke/virtualmachine.yaml). Assertions check persistence of image, network, sizing, and provider references, plus server-side power-state defaulting. It then deletes the VM and cluster. The normal kubeconfig and current context are untouched.

On failure, kind exports diagnostics to `_artifacts/kind-smoke/` before cluster cleanup. CI uploads those logs with seven-day retention. Cluster cleanup runs on success, failure, and catchable interruption; a forcibly terminated process may require manual cleanup of the `vm-api-smoke-*` cluster identified in the logs.

The [CI workflow](../.github/workflows/ci.yml) runs this as `smoke-kind` on pull requests and main-branch pushes. It uses no provider credentials or infrastructure. No core or provider controllers are installed. Fixture references intentionally do not resolve to backing objects: this test checks Kubernetes API registration, admission, defaults, and storage, not reconciliation or VM provisioning.

The smoke test defaults to Docker, as used by CI. To use a running Podman machine locally:

```bash
KIND_EXPERIMENTAL_PROVIDER=podman make test-smoke
```

Override the image with `make test-smoke KIND_NODE_IMAGE=<image>` when investigating Kubernetes compatibility. Alternative node images require separate validation.

## Controller integration tests

```bash
make -C controller test
```

These tests use envtest's API server and etcd, run the generic controller, and exercise it against a stub provider resource. They cover adoption, status, and deletion coordination without creating infrastructure. They remain separate from the kind API smoke test.

## Provider provisioning tests

Provisioning tests belong to each provider's test suite. They must run separately from the credential-free API smoke test and demonstrate actual infrastructure creation, readiness, and deletion.

Before running one, provide:

- A dedicated Kubernetes test cluster with the VM API CRD, core controller, provider CRDs/controller, and required RBAC and webhook configuration.
- Provider infrastructure and scoped credentials. For vSphere this includes an accessible vCenter/test environment, compute capacity, VM images, networks, storage, and any required platform-specific services.
- Valid image, network, instance sizing, and storage references supported by that provider, plus any bootstrap Secrets.
- Quotas or spending limits, timeouts, ownership labels, and cleanup that removes provisioned resources even when a test fails.
- Provider/controller versions, infrastructure versions, and sanitized diagnostic collection sufficient to reproduce failures.

Credentials must stay in an approved secret store. Run credentialed tests only through a trusted, explicitly authorized workflow; never expose infrastructure credentials to unreviewed fork code. The provider test suite should document exact setup and teardown commands for its environment. This repository does not yet supply a provider provisioning test harness.
