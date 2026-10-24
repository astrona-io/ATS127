# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** The Triggers architecture

## Scenario

The `starfleet` team has a Pipeline `ci-build` and a TriggerTemplate `ci-build-run` that creates a `PipelineRun` of it. Nothing calls them yet. The team wants every push to the repository `starfleet/bridge` to start a build, and asks you to build the EventListener for it.

## Your task

1. Create the ServiceAccount `starfleet-triggers` in the namespace `starfleet`.
2. Give it the permissions an EventListener needs, using the ClusterRoles that the Triggers release ships: bind `tekton-triggers-eventlistener-roles` with a RoleBinding in `starfleet`, and `tekton-triggers-eventlistener-clusterroles` with a ClusterRoleBinding.
3. Create the TriggerBinding `github-push` in `starfleet`. From a GitHub push event, it sets `repo-url` to `repository.clone_url`, `revision` to `head_commit.id`, and `branch` to `ref`.
4. Create the EventListener `starfleet-ci` in `starfleet` with the ServiceAccount `starfleet-triggers` and one Trigger named `github-push` that uses the TriggerBinding `github-push` and the TriggerTemplate `ci-build-run`.
5. Send the payload `/payloads/push-main.json` from the `webhook-client` pod to the EventListener and check that a `PipelineRun` of `ci-build` appears and succeeds.

## Constraints

- Do not change the Pipeline `ci-build` or the TriggerTemplate `ci-build-run`.
- Do not give `starfleet-triggers` broader rights, such as `cluster-admin` or `edit`. It must not be able to delete pods, create Deployments or create ClusterRoleBindings.
- Do not use interceptors in this lab: the event has no signature.

## Done when

- The EventListener `starfleet-ci` uses the ServiceAccount `starfleet-triggers`, its `Ready` condition is `True`, and the Service `el-starfleet-ci` listens on port `8080`.
- `starfleet-triggers` is bound to both ClusterRoles named above and has no broader rights.
- A push event to `refs/heads/main` with a new commit ID creates a `PipelineRun` of `ci-build` from the Trigger `github-push`, with `revision` = the commit ID, `branch` = `refs/heads/main` and `repo-url` = `https://git.example.com/starfleet/bridge.git`, and that run succeeds.
