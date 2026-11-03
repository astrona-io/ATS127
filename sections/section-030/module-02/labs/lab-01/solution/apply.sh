#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unsolved for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet delete pipelineruns -l purpose=old-build
kubectl apply -f "$SCRIPT_DIR/run-cleaner-rbac.yaml"
kubectl apply -f "$SCRIPT_DIR/cronjob-cleanup-old-runs.yaml"
