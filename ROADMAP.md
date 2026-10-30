# VM API Roadmap

This roadmap describes development priorities for the portable VM API and provider ecosystem. Milestones are ordered by dependency; delivery depends on implementation, review, and validation across providers.

## Current capabilities

The repository includes `vm-api.io/v1alpha1` API types, generated CRDs, a generic controller, and a [provider authoring guide](docs/implementing-a-provider.md). The controller coordinates ownership and deletion of provider resources and reports their lifecycle state through the [provider status contract](controller/internal/contract/contract.go).

## 1. API and provider contract

- Define companion catalog resources, beginning with image references.
- Document field ownership and reference-resolution requirements across providers.
- Specify reference isolation and namespace boundaries.
- Develop a portable accelerator model with input from multiple infrastructure platforms.
- Define provider contract versioning and discovery behavior.

## 2. Provider ecosystem and conformance

- Expand integrations across vSphere, KubeVirt, and cloud VM platforms.
- Validate common behavior against multiple independently implemented providers.
- Develop a shared conformance suite for lifecycle, status, ownership, and failure handling.
- Extend the provider authoring guide with tested integration examples and compatibility guidance.

## 3. VM orchestration

- `VirtualMachineTemplate` and `VirtualMachineSet` for reusable definitions and groups of machines.
- `VirtualMachineService` for service access to VM workloads.
- `VirtualMachineDeployment` for rolling updates and replacement of machines when immutable configuration changes.
- A guest bootstrap provider contract supporting additional initialization methods beyond cloud-init.

These resources are planned capabilities, not currently implemented API types.

## 4. Releases and project operations

- Capability discovery and documented provider support levels.
- Additional API versions with conversion and upgrade procedures.
- Independent core and provider release cadences with a tested compatibility matrix.
- Public contribution, governance, maintainer, and security-response documentation.
- Reproducible releases and installation instructions that work without private infrastructure.

## Scope boundaries

Providers retain responsibility for infrastructure scheduling, high availability, and live migration. VM API does not implement a hypervisor or transfer running VM state and disks between providers. A combined workload model for VMs and Pods requires a separate design.
