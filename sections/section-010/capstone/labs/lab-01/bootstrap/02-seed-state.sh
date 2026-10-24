#!/usr/bin/env bash
# Creates the starting state for ats-127-capstone-010.
#
# 1. Applies the Pipeline ci-build and the TriggerTemplate ci-build-run.
# 2. Applies the ServiceAccount starfleet-triggers with only its
#    ClusterRoleBinding (the RoleBinding is missing).
# 3. Applies the ClusterTriggerBinding github-push (it reads head_commit.sha).
# 4. Applies the EventListener starfleet-ci (its binding reference has no kind)
#    and waits until the controller created the Deployment el-starfleet-ci.
#
# The EventListener pod does not become ready. Finding and fixing the three
# faults is the task.
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

apply_with_retry "$MANIFESTS/pipeline-ci-build.yaml"
apply_with_retry "$MANIFESTS/triggertemplate-ci-build-run.yaml"
apply_with_retry "$MANIFESTS/serviceaccount-starfleet-triggers.yaml"
apply_with_retry "$MANIFESTS/clustertriggerbinding-github-push.yaml"
apply_with_retry "$MANIFESTS/eventlistener-starfleet-ci.yaml"

found=""
for _ in $(seq 1 60); do
  if kubectl -n starfleet get deployment el-starfleet-ci >/dev/null 2>&1; then
    found="yes"
    break
  fi
  sleep 3
done
if [ -z "$found" ]; then
  echo "ERROR: the Triggers controller did not create the Deployment el-starfleet-ci." >&2
  exit 1
fi

echo "[lab] Starting state ready."
kubectl -n starfleet get eventlisteners,deployments,pods
echo "[lab] No push has started a build yet. Finding out why is the task."
