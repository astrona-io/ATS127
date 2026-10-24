#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays open for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The shared webhook secret.
kubectl apply -f "$SCRIPT_DIR/secret-github-webhook-secret.yaml"
# 2. The binding reads the short branch name from the CEL overlay.
kubectl apply -f "$SCRIPT_DIR/triggerbinding-github-push.yaml"
# 3. The EventListener with the github and cel interceptors.
kubectl apply -f "$SCRIPT_DIR/eventlistener-starfleet-ci.yaml"
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
