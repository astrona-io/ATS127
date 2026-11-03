# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Custom interceptors

## Scenario

The `starfleet` team wrote a small service, `branch-check`, that lets only pushes to branches through and returns the short branch name. It runs in the namespace `starfleet`. The EventListener `starfleet-ci` calls it as the ClusterInterceptor `branch-check`, but since the setup, no push starts a build.

## Your task

1. Find out why the EventListener cannot use the interceptor, and repair the ClusterInterceptor `branch-check`.
2. Find out why the run would still get no branch, and repair the TriggerBinding `branch-push`.

## Constraints

- Do not change the Deployment, the Service or the ConfigMap of `branch-check`.
- Do not change the EventListener, the TriggerTemplate or the Pipeline.
- Keep the interceptor in the Trigger. Do not remove it.

## Done when

- The ClusterInterceptor `branch-check` points at the Service `branch-check` in `starfleet`.
- A push to `refs/heads/main` creates a `PipelineRun` of `ci-build` with the commit ID of the event and `branch` set to `main`.
- A push to a tag, such as `refs/tags/v1.0.0`, creates no run.
