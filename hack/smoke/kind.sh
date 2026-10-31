#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
kind_bin=${KIND:-kind}
kubectl_bin=${KUBECTL:-kubectl}
node_image=${KIND_NODE_IMAGE:?KIND_NODE_IMAGE must specify a pinned kind node image}
for command in "$kind_bin" "$kubectl_bin" python3; do
    command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done

work_dir=$(mktemp -d)
cluster_name="vm-api-smoke-$(date +%s)-$$"
# Keep the user's kubeconfig and current context untouched.
export KUBECONFIG="$work_dir/kubeconfig"
export KIND_EXPERIMENTAL_PROVIDER=${KIND_EXPERIMENTAL_PROVIDER:-docker}
artifacts_dir=${ARTIFACTS_DIR:-"$root_dir/_artifacts/kind-smoke"}

cleanup() {
    result=$?
    trap - EXIT
    if [[ $result -ne 0 ]]; then
        mkdir -p "$artifacts_dir"
        "$kind_bin" export logs "$artifacts_dir" --name "$cluster_name" || true
        echo "Smoke-test diagnostics: $artifacts_dir" >&2
    fi
    if ! "$kind_bin" delete cluster --name "$cluster_name"; then
        echo "Failed to clean up cluster $cluster_name" >&2
        result=1
    fi
    rm -rf "$work_dir"
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

"$kind_bin" create cluster --name "$cluster_name" --image "$node_image" \
    --kubeconfig "$KUBECONFIG" --wait 180s
"$kubectl_bin" apply -f "$root_dir/config/crd/bases/"
"$kubectl_bin" wait --for=condition=Established --timeout=60s crd/virtualmachines.vm-api.io
"$kubectl_bin" get --raw /apis/vm-api.io/v1alpha1 > "$work_dir/discovery.json"
python3 - "$work_dir/discovery.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as stream:
    discovery = json.load(stream)
assert discovery['groupVersion'] == 'vm-api.io/v1alpha1', discovery
resource = next(r for r in discovery['resources'] if r['name'] == 'virtualmachines')
assert resource['kind'] == 'VirtualMachine' and resource['namespaced'], resource
assert {'create', 'get', 'list', 'delete'} <= set(resource['verbs']), resource
print('PASS: VirtualMachine discovery')
PY
"$kubectl_bin" create namespace vm-api-smoke
"$kubectl_bin" create -n vm-api-smoke -f "$root_dir/hack/smoke/virtualmachine.yaml"
"$kubectl_bin" get virtualmachines.vm-api.io smoke-vm -n vm-api-smoke -o json > "$work_dir/vm.json"
python3 - "$work_dir/vm.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as stream:
    vm = json.load(stream)
assert vm['apiVersion'] == 'vm-api.io/v1alpha1' and vm['kind'] == 'VirtualMachine'
assert vm['metadata']['namespace'] == 'vm-api-smoke' and vm['metadata']['uid']
spec = vm['spec']
assert spec['instanceType']['name'] == 'smoke-small'
assert spec['powerState'] == 'PoweredOn', spec  # Server-side defaulting.
assert spec['bootDisk']['sizeGiB'] == 20
assert spec['bootDisk']['source']['image']['name'] == 'smoke-image'
assert spec['network']['interfaces'][0]['network']['name'] == 'smoke-network'
assert spec['network']['interfaces'][0]['dhcp4'] is True
assert spec['tags']['purpose'] == 'api-smoke'
assert spec['infrastructureRef'] == {
    'apiGroup': 'infrastructure.example.com',
    'kind': 'ExampleVirtualMachine',
    'name': 'smoke-provider-vm',
}
print('PASS: VirtualMachine persisted with representative fields and defaults')
PY
"$kubectl_bin" delete virtualmachines.vm-api.io smoke-vm -n vm-api-smoke --wait=true --timeout=60s
echo 'PASS: kind API smoke test'
