#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The label selector of the EventListener.
kubectl apply -f "$SCRIPT_DIR/eventlistener-starfleet-ci.yaml"
# 2. The event type of the pull request Trigger.
kubectl apply -f "$SCRIPT_DIR/trigger-github-pull-request.yaml"
# 3. The permission of the pull request Trigger's ServiceAccount.
kubectl apply -f "$SCRIPT_DIR/rbac-starfleet-pr-runner.yaml"
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
