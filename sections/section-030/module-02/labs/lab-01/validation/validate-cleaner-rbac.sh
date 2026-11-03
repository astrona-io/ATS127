#!/usr/bin/env bash
# PASS when the ServiceAccount run-cleaner can list and delete PipelineRuns in
# starfleet, and can do nothing on pods, TaskRuns or in other namespaces.
set -uo pipefail

NS="starfleet"
SA="system:serviceaccount:${NS}:run-cleaner"

if ! kubectl -n "$NS" get serviceaccount run-cleaner >/dev/null 2>&1; then
  echo "FAIL: the ServiceAccount run-cleaner does not exist in $NS." >&2
  exit 1
fi

can() {
  # can VERB RESOURCE NAMESPACE: prints yes or no.
  kubectl auth can-i "$1" "$2" -n "$3" --as="$SA" 2>/dev/null || true
}

for verb in get list delete; do
  if [ "$(can "$verb" pipelineruns "$NS")" != "yes" ]; then
    echo "FAIL: run-cleaner cannot $verb pipelineruns in $NS." >&2
    exit 1
  fi
done

for resource in pods taskruns secrets; do
  if [ "$(can delete "$resource" "$NS")" = "yes" ]; then
    echo "FAIL: run-cleaner can delete $resource in $NS. It only needs pipelineruns." >&2
    exit 1
  fi
done

if [ "$(can delete pipelineruns default)" = "yes" ]; then
  echo "FAIL: run-cleaner can delete pipelineruns outside $NS. Use a Role, not a ClusterRole." >&2
  exit 1
fi

echo "PASS: run-cleaner deletes pipelineruns in $NS and nothing else."
exit 0
