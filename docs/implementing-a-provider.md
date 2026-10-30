# Implementing a VM API Provider

An infrastructure provider reconciles portable `VirtualMachine` intent against a specific platform. It owns the platform integration, exposes a Kubernetes resource for infrastructure-specific configuration, and publishes state through the shared provider contract.

This guide describes integration with the current `vm-api.io/v1alpha1` API and [generic controller](../controller/controllers/virtualmachine/). Provider implementations are separate from this repository.

## Provider status contract

The core reads the following fields through an unstructured Kubernetes object. It does not require your provider's Go types.

| Path | Meaning |
|---|---|
| `status.addresses[]` | Network addresses, with `interface`, `type`, and `address` fields |
| `status.powerState` | Observed platform power state |
| `status.providerID` | Platform-specific machine identifier |
| `status.providerMetadata` | Additional platform metadata as a string map |
| `status.conditions[]` | Kubernetes conditions, including `InfrastructureReady` and `UpToDate` |

See [contract.go](../controller/internal/contract/contract.go) for the field readers. Missing fields are allowed while a provider is converging. Publish conditions that describe infrastructure readiness and whether the requested configuration has been applied.

The core does not read or write the provider resource's spec. It does modify ownership metadata and request deletion of the provider resource as part of VM lifecycle management. The provider controller must implement platform cleanup before allowing its own finalizer to be removed.

## Link the resources

The user or a higher-level controller creates both the generic VM and the provider resource in the same namespace.

1. Set the generic VM's `spec.infrastructureRef` to the provider resource's API group, kind, and name.
2. Set the provider resource's `vm-api.io/virtual-machine` annotation to the generic VM's name.
3. Before modifying platform resources, verify that both objects refer to each other.

The generic controller resolves the provider's preferred served version using Kubernetes discovery. It checks the backlink before adoption and records a controller owner reference on the provider resource. The infrastructure reference is immutable after creation; see the [VirtualMachine types](../api/v1alpha1/virtualmachine_types.go).

A reference alone is not authorization to take control of an unrelated resource. Validate mutual linkage and namespace boundaries, and configure RBAC so only authorized users can establish the relationship. Handle missing or mismatched resources as explicit reconciliation states.

## Resolve desired configuration

Read portable intent from the generic VM and resolve it to platform-specific configuration. Keep provider-only settings on the provider resource, with documented ownership and mutability rules.

A provider may persist resolved configuration into its own spec before acting on it. If using that pattern:

1. Read supported portable fields such as power state, image, and instance sizing.
2. Resolve references and validate platform constraints.
3. Patch only changed provider-owned fields, using optimistic concurrency where needed.
4. Reconcile the platform against the resolved configuration.
5. Report observed state and conditions through the status contract.

Document which fields are controller-managed and which are user-managed. Do not overwrite provider-specific settings merely because they have no portable equivalent. An existing provider may use a different internal reconciliation model while satisfying the same external contract.

## Resolve image and catalog references

Image and network references contain an API group, kind, and name. Define how your provider resolves those references and document the required catalog or platform resources. The core does not implement a universal image or network catalog.

The API validates reference names as DNS subdomains. Raw image strings containing registry paths, tags, or digests may therefore be invalid reference names. Use a supported catalog mapping or an explicitly designed provider-specific field rather than assuming any platform image identifier fits into a Kubernetes object reference.

Similarly, document how sizing profiles, failure domains, storage classes, and guest bootstrap data map to your platform. Report unsupported configurations clearly; do not silently ignore requested behavior.

## Register controllers and schemes

The [generic controller package](../controller/controllers/virtualmachine/) exposes `AddToManager`. A provider can register it on the same controller-runtime manager as its provider controller.

Register both the [generic API scheme](../api/v1alpha1/groupversion_info.go) and your provider's scheme. Add a watch that maps changes to the generic VM back to its provider resource so desired-state updates reach your reconciler promptly.

Configure permissions for the generic VM, its status and finalizers, and the provider resource. The core needs to read provider status, patch ownership metadata, and delete provider resources. Review the checked-in RBAC markers against your actual provider group; do not assume permissions for an existing provider cover a new integration.

The current core uses timed reconciliation for provider states it does not watch directly. Account for asynchronous convergence in both the provider and its tests.

## Platform lifecycle and recovery

Platform operations must tolerate retries and controller restarts. Choose idempotency keys and lookup behavior based on the platform's guarantees. For asynchronous creation or eventually consistent lookups, distinguish a pending operation from a missing resource before creating a replacement.

Use a provider finalizer to complete platform cleanup when the provider object is deleted. The generic controller requests provider deletion and waits for the resource to disappear before completing generic VM deletion. Test failures and restarts throughout this sequence so a partially completed operation does not leak or duplicate infrastructure.

## Testing

Keep unit tests independent of live platform credentials by placing platform calls behind interfaces and injecting test implementations. Use Kubernetes integration tests for object linkage, ownership, status updates, and finalizer behavior. Run separate end-to-end tests against the actual platform.

Cover at least:

- Successful creation, observation, power-state changes, and deletion.
- Missing, mismatched, or conflicting resource relationships.
- Unsupported configuration and failed reference resolution.
- Retried platform calls, asynchronous operations, and controller restarts.
- Concurrent resource updates and cleanup failures.
- Generic and provider status convergence, including readiness conditions.

Use eventual assertions for asynchronous behavior rather than fixed sleeps. The [generic controller tests](../controller/controllers/virtualmachine/virtualmachine_controller_test.go) cover its adoption, status, and deletion behavior and provide a starting point for integration coverage.

## Local integration workflow

1. Install the generic CRD from [config/crd/bases](../config/crd/bases/) and your provider's CRDs.
2. Configure credentials and RBAC appropriate for the test environment.
3. Run a manager with the generic and provider controllers registered.
4. Create a mutually linked pair of generic and provider resources.
5. Observe their status, change supported desired configuration, and verify cleanup on deletion.

If adoption does not complete, inspect the infrastructure reference, backlink annotation, namespace, served API version, ownership, and permissions. Adapt the [sample VM](../config/samples/virtualmachine.yaml) to your provider's resource kinds and catalog entries before applying it.
