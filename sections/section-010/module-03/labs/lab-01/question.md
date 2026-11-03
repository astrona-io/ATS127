# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Bindings and templates

## Scenario

The `starfleet` team wants every push to leave two objects: a `PipelineRun` of `ci-build` and a `ConfigMap` that records the revision, the pusher and the event type. Since the template got its second resource, pushes start nothing at all. The EventListener `starfleet-ci` is `Ready`, and the platform team has refused to give its ServiceAccount broad rights.

## Your task

1. Find out why a push event creates no `PipelineRun`, and repair the TriggerBinding `github-push`.
2. Find out why the `ConfigMap` cannot be created, and give the ServiceAccount `starfleet-triggers` the right to create `configmaps` in the namespace `starfleet`. Give it that right only.

## Constraints

- Do not change the TriggerTemplate `ci-build-run`, the Pipeline `ci-build` or the EventListener `starfleet-ci`.
- Keep the other paths of the binding as they are.
- Do not bind the ServiceAccount to a broader role, and do not give it any right except creating `configmaps`.

## Done when

- A push event sent to `http://el-starfleet-ci.starfleet.svc.cluster.local:8080` creates a `PipelineRun` of `ci-build` with the commit ID, the clone URL and the ref of the event.
- The same event creates a `ConfigMap` with the label `triggers.tekton.dev/triggers-eventid`, holding the keys `revision`, `pusher` and `event` with the values of the event.
- The ServiceAccount `starfleet-triggers` can create `configmaps` in `starfleet`, and cannot create `secrets` or delete `configmaps`.
