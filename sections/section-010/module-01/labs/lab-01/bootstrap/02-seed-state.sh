#!/usr/bin/env bash
# Creates the starting state for ats-127-lab-010-01.
#
# 1. Applies the Pipeline ci-build.
# 2. Applies the TriggerTemplate ci-build-run.
#
# The ServiceAccount, its RBAC, the TriggerBinding and the EventListener are
# the task: this script creates none of them.
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

echo "[lab] Starting state ready."
kubectl -n starfleet get pipelines,triggertemplates
echo "[lab] No EventListener exists yet. Building it is the task."
