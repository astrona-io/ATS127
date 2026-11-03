#!/usr/bin/env bash
# Creates the starting state for ats-127-lab-030-03.
#
# It installs the build path (Trigger github-push), the Pipeline docs-check,
# the template docs-check-run, and the Trigger docs-check. The Trigger docs-check
# is broken: the task is to repair it.
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

for manifest in pipeline-ci-build pipeline-pr-check pipeline-docs-check rbac-starfleet-triggers secret-github-webhook-secret triggerbinding-github-push triggertemplate-ci-build-run triggertemplate-docs-check-run trigger-github-push trigger-docs-check eventlistener-starfleet-ci; do
  apply_with_retry "$MANIFESTS/$manifest.yaml"
done
for listener in starfleet-ci; do
  wait_for_eventlistener_ready "$listener"
done

echo "[lab] Starting state ready."
echo "[lab] Pushes to main start ci-build. The Trigger docs-check does not start docs-check yet; repairing that is the task."
