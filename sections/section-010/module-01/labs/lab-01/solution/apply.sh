#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unsolved for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The ServiceAccount and both bindings come first, so the EventListener pod
#    can fill its caches as soon as it starts.
kubectl apply -f "$SCRIPT_DIR/serviceaccount-starfleet-triggers.yaml"
kubectl apply -f "$SCRIPT_DIR/rolebinding-starfleet-triggers-eventlistener.yaml"
kubectl apply -f "$SCRIPT_DIR/clusterrolebinding-starfleet-triggers-eventlistener.yaml"

# 2. The binding and the EventListener.
kubectl apply -f "$SCRIPT_DIR/triggerbinding-github-push.yaml"
kubectl apply -f "$SCRIPT_DIR/eventlistener-starfleet-ci.yaml"

# 3. Wait until the controller has created the Deployment and it is Available.
for _ in $(seq 1 60); do
  kubectl -n starfleet get deployment el-starfleet-ci >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n starfleet rollout status deployment/el-starfleet-ci --timeout=300s
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
