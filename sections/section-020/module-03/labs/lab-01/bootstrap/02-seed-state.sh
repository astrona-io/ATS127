#!/usr/bin/env bash
# Creates the starting state for ats-127-lab-020-03.
#
# 1. Applies the Pipeline ci-build, the ServiceAccount starfleet-triggers with
#    its RBAC, the interceptor service branch-check (ConfigMap, Deployment and
#    Service) and waits for it.
# 2. Applies the ClusterInterceptor branch-check with a wrong Service name, the
#    TriggerTemplate ci-build-run and the TriggerBinding branch-push, which
#    reads the wrong extension.
# 3. Applies the EventListener starfleet-ci and waits until it is Ready.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

apply_with_retry() {
  # apply_with_retry FILE: a webhook can refuse the first objects while it starts.
  local attempt
  for attempt in $(seq 1 30); do
    kubectl apply -f "$1" && return 0
    echo "[lab] kubectl apply -f $1 failed (attempt $attempt), retrying in 5s..."
    sleep 5
  done
  return 1
}

wait_for_eventlistener_ready() {
  # wait_for_eventlistener_ready NAME: waits for the Deployment el-NAME and the
  # EventListener's Ready condition.
  local found=""
  for _ in $(seq 1 60); do
    if kubectl -n starfleet get deployment "el-$1" >/dev/null 2>&1; then
      found="yes"
      break
    fi
    sleep 3
  done
  if [ -z "$found" ]; then
    echo "ERROR: the Triggers controller did not create the Deployment el-$1." >&2
    return 1
  fi
  kubectl -n starfleet rollout status "deployment/el-$1" --timeout=300s
  kubectl -n starfleet wait --for=condition=Ready "eventlistener/$1" --timeout=300s
}

for manifest in pipeline-ci-build rbac-starfleet-triggers interceptor-branch-check clusterinterceptor-branch-check triggertemplate-ci-build-run triggerbinding-branch-push eventlistener-starfleet-ci; do
  apply_with_retry "$MANIFESTS/$manifest.yaml"
done
kubectl -n starfleet rollout status deployment/branch-check --timeout=300s
for listener in starfleet-ci; do
  wait_for_eventlistener_ready "$listener"
done

echo "[lab] Starting state ready."
echo "[lab] The ClusterInterceptor points at a Service that does not exist and the binding reads the wrong extension. Repairing both is the task."
