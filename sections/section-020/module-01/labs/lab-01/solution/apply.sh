#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Both faults are in the EventListener: the secretKey and the CEL filter.
kubectl apply -f "$SCRIPT_DIR/eventlistener-starfleet-ci.yaml"
kubectl -n starfleet wait --for=condition=Ready eventlistener/starfleet-ci --timeout=300s
