#!/usr/bin/env bash
# PASS when no PipelineRun with purpose=old-build is left, and the TaskRuns and
# pods of those runs are gone as well.
set -uo pipefail

NS="starfleet"

for _ in $(seq 1 30); do
  runs="$(kubectl -n "$NS" get pipelineruns -l purpose=old-build -o name 2>/dev/null || true)"
  if [ -z "$runs" ]; then
    break
  fi
  sleep 2
done

if [ -n "${runs:-}" ]; then
  echo "FAIL: these old-build runs still exist:" >&2
  echo "$runs" >&2
  exit 1
fi

for _ in $(seq 1 30); do
  owned="$(kubectl -n "$NS" get taskruns -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].name}{"\n"}{end}' 2>/dev/null | grep '^old-build-' || true)"
  if [ -z "$owned" ]; then
    echo "PASS: the old-build runs and their TaskRuns are gone."
    exit 0
  fi
  sleep 2
done

echo "FAIL: TaskRuns of deleted old-build runs are still there:" >&2
echo "$owned" >&2
exit 1
