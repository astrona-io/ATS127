#!/usr/bin/env bash
# Creates the starting state for ats-127-capstone-030.
#
# 1. Applies both Pipelines, the ServiceAccount starfleet-triggers with its
#    RBAC, the Secret github-webhook-secret, the push binding, template and
#    Trigger, the pull request binding and template, the ServiceAccount
#    starfleet-pr-runner (no permissions) and the pull request Trigger (event
#    type "pull-request", serviceAccountName starfleet-pr-runner).
# 2. Applies the EventListener starfleet-ci (label selector team: starfleet-ci)
#    and waits until it is Ready.
#
# No event starts anything. Finding and fixing the three faults is the task.
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

for manifest in pipeline-ci-build pipeline-pr-check rbac-starfleet-triggers secret-github-webhook-secret \
  triggerbinding-github-push triggertemplate-ci-build-run trigger-github-push \
  triggerbinding-github-pull-request triggertemplate-pr-check-run serviceaccount-starfleet-pr-runner \
  trigger-github-pull-request eventlistener-starfleet-ci; do
  apply_with_retry "$MANIFESTS/$manifest.yaml"
done
wait_for_eventlistener_ready starfleet-ci

echo "[lab] Starting state ready."
kubectl -n starfleet get eventlisteners,triggers,serviceaccounts
echo "[lab] No push and no pull request starts a run. Finding out why is the task."
