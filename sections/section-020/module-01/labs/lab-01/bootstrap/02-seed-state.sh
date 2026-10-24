#!/usr/bin/env bash
# Creates the starting state for ats-127-lab-020-01.
#
# 1. Applies the Pipeline ci-build, the ServiceAccount starfleet-triggers with
#    its RBAC, the TriggerTemplate ci-build-run, the TriggerBinding github-push
#    and the Secret github-webhook-secret.
# 2. Applies the EventListener starfleet-ci (wrong secretKey, CEL filter for
#    master) and waits until it is Ready.
#
# The EventListener is ready but creates no PipelineRun for a signed push to
# main. Finding and fixing both faults is the task.
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

for manifest in pipeline-ci-build rbac-starfleet-triggers triggertemplate-ci-build-run triggerbinding-github-push secret-github-webhook-secret eventlistener-starfleet-ci; do
  apply_with_retry "$MANIFESTS/$manifest.yaml"
done
wait_for_eventlistener_ready starfleet-ci

echo "[lab] Starting state ready."
kubectl -n starfleet get eventlisteners,triggerbindings,triggertemplates,secrets
echo "[lab] A signed push to main creates no PipelineRun. Finding out why is the task."
