# VM API Architecture

VM API separates portable virtual machine configuration from infrastructure-specific implementation. Kubernetes users declare a `VirtualMachine`; a provider translates that intent into operations on its platform and publishes the resulting state.

## Components

| Component | Responsibility |
|---|---|
| [VirtualMachine API](../api/v1alpha1/) | Portable compute, storage, network, bootstrap, and power-state configuration |
| [Generic controller](../controller/controllers/virtualmachine/) | Provider-resource adoption, lifecycle coordination, and generic VM status |
| [Provider status contract](../controller/internal/contract/contract.go) | Common fields and conditions read without provider-specific Go imports |
| Infrastructure provider | Platform-specific configuration, provisioning, observation, and cleanup |

The current API group and version are `vm-api.io/v1alpha1`.

## Resource relationship

A generic VM's `spec.infrastructureRef` identifies the API group, kind, and name of a provider resource in the same namespace. Kubernetes discovery supplies the preferred served version. The provider resource carries a `vm-api.io/virtual-machine` annotation naming the generic VM, allowing the controllers to verify the relationship before adoption.

The user or a higher-level controller creates both resources. The generic controller does not create provider resources or write their desired configuration. It establishes an owner reference, observes provider status, and coordinates deletion through a finalizer. The provider controller is responsible for applying desired configuration to the infrastructure and cleaning up its platform resources.

## Provider boundary

The generic core reads a fixed set of status fields: provider identity, power state, addresses, provider metadata, and infrastructure readiness and update conditions. It does not call platform APIs or import provider types. Providers retain their own resource schemas and platform capabilities.

Portable fields describe shared intent. Provider-specific configuration remains on the provider resource. Image, network, storage, and sizing references must resolve in the destination environment; portability of configuration does not imply migration of running machines or their data.

## Versioning and development

The API currently serves `v1alpha1`. Provider contract versioning, conformance, companion catalogs, and additional API versions are tracked in the [roadmap](../ROADMAP.md). Future schema changes require explicit compatibility and upgrade guidance.

See [Implementing a provider](implementing-a-provider.md) for integration requirements. The source and generated manifests in this repository describe the current implementation.
