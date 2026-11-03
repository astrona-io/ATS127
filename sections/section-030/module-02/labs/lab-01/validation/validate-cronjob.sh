#!/usr/bin/env bash
# PASS when the CronJob cleanup-old-runs exists, has a schedule, runs as
# run-cleaner, deletes pipelineruns with a selector that cannot match release
# runs, and limits its Job history.
set -uo pipefail

NS="starfleet"

if ! kubectl -n "$NS" get cronjob cleanup-old-runs >/dev/null 2>&1; then
  echo "FAIL: the CronJob cleanup-old-runs does not exist in $NS." >&2
  exit 1
fi

jp() {
  kubectl -n "$NS" get cronjob cleanup-old-runs -o jsonpath="$1" 2>/dev/null || true
}

schedule="$(jp '{.spec.schedule}')"
account="$(jp '{.spec.jobTemplate.spec.template.spec.serviceAccountName}')"
command_line="$(jp '{.spec.jobTemplate.spec.template.spec.containers[0].command} {.spec.jobTemplate.spec.template.spec.containers[0].args}')"
success_limit="$(jp '{.spec.successfulJobsHistoryLimit}')"
failed_limit="$(jp '{.spec.failedJobsHistoryLimit}')"

if [ -z "$schedule" ]; then
  echo "FAIL: the CronJob has no schedule." >&2
  exit 1
fi
if [ "$account" != "run-cleaner" ]; then
  echo "FAIL: the Job runs as '${account:-default}', not run-cleaner." >&2
  exit 1
fi
if ! printf '%s' "$command_line" | grep -q 'delete' || ! printf '%s' "$command_line" | grep -q 'pipelineruns'; then
  echo "FAIL: the container does not run a delete of pipelineruns. Found: $command_line" >&2
  exit 1
fi
if printf '%s' "$command_line" | grep -q -- '--all'; then
  echo "FAIL: the container uses --all, which also deletes the release run." >&2
  exit 1
fi
if ! printf '%s' "$command_line" | grep -Eq 'purpose!=release|purpose=old-build'; then
  echo "FAIL: the selector must be purpose=old-build or purpose!=release. Found: $command_line" >&2
  exit 1
fi
if [ -z "$success_limit" ] || [ -z "$failed_limit" ]; then
  echo "FAIL: set successfulJobsHistoryLimit and failedJobsHistoryLimit so finished Jobs do not collect." >&2
  exit 1
fi

echo "PASS: the CronJob cleanup-old-runs is defined as required."
exit 0
