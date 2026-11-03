# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Run retention and cleanup

## Scenario

The namespace `starfleet` collects finished runs. Three `PipelineRun` objects, `old-build-1` to `old-build-3`, carry the label `purpose=old-build` and are no longer needed. The run `release-1` carries `purpose=release` and must stay. Nobody cleans up regularly, so the team wants a nightly job.

## Your task

1. Delete the runs labelled `purpose=old-build`. Delete nothing else.
2. Create the ServiceAccount `run-cleaner` in `starfleet`, with a Role and a RoleBinding that let it `get`, `list` and `delete` `pipelineruns` in that namespace and nothing else.
3. Create the CronJob `cleanup-old-runs` in `starfleet`. It runs once a day, as `run-cleaner`, and deletes the runs that are not releases. It keeps a history of one successful and three failed Jobs.

## Constraints

- Do not delete `release-1`, and do not remove its label.
- Do not use a ClusterRole or a ClusterRoleBinding for `run-cleaner`.
- Do not use `--all` in the cleanup command.
- Do not change the EventListener, the Triggers or the Pipelines.

## Done when

- No `PipelineRun` with `purpose=old-build` and none of their `TaskRun` objects exist.
- `release-1` still exists with `purpose=release`.
- `kubectl auth can-i` as `run-cleaner` answers `yes` for `get`, `list` and `delete` on `pipelineruns` in `starfleet`, and `no` for deleting pods, TaskRuns and Secrets, and for deleting `pipelineruns` in the namespace `default`.
- The CronJob has a schedule, runs as `run-cleaner`, and its command deletes `pipelineruns` with the selector `purpose!=release` or `purpose=old-build`.
