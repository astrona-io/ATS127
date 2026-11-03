#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unsolved for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/clusterinterceptor-branch-check.yaml"
kubectl apply -f "$SCRIPT_DIR/triggerbinding-branch-push.yaml"
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
