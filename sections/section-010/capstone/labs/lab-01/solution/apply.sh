#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The missing RoleBinding.
kubectl apply -f "$SCRIPT_DIR/rolebinding-starfleet-triggers-eventlistener.yaml"
# 2. The binding reference with kind: ClusterTriggerBinding.
kubectl apply -f "$SCRIPT_DIR/eventlistener-starfleet-ci.yaml"
# 3. The right JSONPath for the commit ID.
kubectl apply -f "$SCRIPT_DIR/clustertriggerbinding-github-push.yaml"

# Start a fresh EventListener pod so it fills its caches with the new rights.
kubectl -n starfleet delete pod -l eventlistener=starfleet-ci --wait=false
kubectl -n starfleet rollout status deployment/el-starfleet-ci --timeout=300s
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
