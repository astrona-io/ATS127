# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The Triggers architecture

## Scenario

The `starfleet` team set up the EventListener `starfleet-ci` last week, with a cluster-wide binding for GitHub push events that the platform team wants every namespace to share. Since then, not one push to `starfleet/bridge` has started a build. The team only knows that the Git server got no errors back.

## Your task

1. Find out why the EventListener `starfleet-ci` in the namespace `starfleet` creates no `PipelineRun`. Start with its `Ready` condition and its pod, then send `/payloads/push-main.json` from the `webhook-client` pod and read the EventListener's log.
2. Fix every fault you find. There is more than one, and each one hides the next.
3. Leave the EventListener in a state where a push event creates a `PipelineRun` of `ci-build` that succeeds.

## Constraints

- Keep the EventListener `starfleet-ci` with the ServiceAccount `starfleet-triggers`, the Trigger `github-push` and the TriggerTemplate `ci-build-run`.
- Use the ClusterTriggerBinding `github-push`. Do not create a namespaced TriggerBinding named `github-push`, and keep its parameters `repo-url`, `revision` and `branch`.
- Give `starfleet-triggers` only the ClusterRoles that the Triggers release ships for EventListeners, never `cluster-admin` or `edit`. It must not be able to delete pods, create Deployments or create ClusterRoleBindings.
- Do not change the Pipeline `ci-build` or the TriggerTemplate `ci-build-run`.

## Done when

- The EventListener `starfleet-ci` uses `starfleet-triggers`, its `Ready` condition is `True`, and the Service `el-starfleet-ci` listens on port `8080`.
- `starfleet-triggers` has a RoleBinding to `tekton-triggers-eventlistener-roles` in `starfleet` and a ClusterRoleBinding to `tekton-triggers-eventlistener-clusterroles`, and no broader rights.
- The Trigger `github-push` references `github-push` with `kind: ClusterTriggerBinding`, and no namespaced TriggerBinding `github-push` exists.
- A push event to `refs/heads/main` with a new commit ID creates a `PipelineRun` of `ci-build` from the Trigger `github-push`, with `revision` = the commit ID, `branch` = `refs/heads/main` and `repo-url` = `https://git.example.com/starfleet/bridge.git`, and that run succeeds.
