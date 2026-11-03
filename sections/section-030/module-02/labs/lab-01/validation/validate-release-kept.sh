#!/usr/bin/env bash
# PASS when the release run is still there and keeps its label.
set -uo pipefail

NS="starfleet"

purpose="$(kubectl -n "$NS" get pipelinerun release-1 -o jsonpath='{.metadata.labels.purpose}' 2>/dev/null || true)"
if [ "$purpose" != "release" ]; then
  echo "FAIL: the PipelineRun release-1 is missing or has lost its label purpose=release." >&2
  exit 1
fi

echo "PASS: release-1 is kept."
exit 0
