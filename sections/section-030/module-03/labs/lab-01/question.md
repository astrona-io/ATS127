# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Path filters and several Triggers

## Scenario

The `starfleet` team builds every push to `main` with the Trigger `github-push`. A second Trigger, `docs-check`, should start the Pipeline `docs-check` when a push changes a file under `docs/`. Since it was added, no push starts a documentation check, although the build still works.

## Your task

Find out why the Trigger `docs-check` never starts a run, and repair it. There is more than one fault.

## Constraints

- Do not change the EventListener, the Trigger `github-push`, the TriggerBinding, the TriggerTemplates or the Pipelines.
- Keep both the `github` and the `cel` interceptor in `docs-check`.
- Do not remove the path filter, and do not make it match every push.

## Done when

- A signed push to `refs/heads/main` that modifies `docs/status.md` creates a `PipelineRun` of `docs-check` with the commit ID of the event and `branch` set to `main`, and also the `PipelineRun` of `ci-build`.
- A signed push to `refs/heads/main` that modifies only `src/bridge.go` creates a `PipelineRun` of `ci-build` and none of `docs-check`.
