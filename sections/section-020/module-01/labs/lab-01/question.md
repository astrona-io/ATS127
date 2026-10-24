# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Interceptors

## Scenario

The `starfleet` team secured its EventListener `starfleet-ci` last week: a GitHub interceptor checks the signature of every push, and a CEL interceptor lets through only the team's main branch. Since that change, no build has started at all, even for correctly signed pushes. The Git server still gets `202` back for every delivery.

## Your task

1. Send the payload `/payloads/push-main.json` from the `webhook-client` pod to `http://el-starfleet-ci.starfleet.svc.cluster.local:8080` as a `push` event, signed with HMAC-SHA256 and the webhook secret `lab-only-webhook-secret` in the header `X-Hub-Signature-256`.
2. Find out why it creates no `PipelineRun`, and fix every fault you find. There is more than one.
3. Leave the EventListener in a state where a signed push to `main` creates a `PipelineRun` of `ci-build` with `branch` = `main`, and where the checks still refuse everything else.

## Constraints

- Keep both interceptors of the Trigger `github-push`: the `github` interceptor with a `secretRef` to the Secret `github-webhook-secret` and the event type `push`, and the `cel` interceptor with its filter and its overlay `branch_name`.
- Do not change the webhook secret value `lab-only-webhook-secret`. The Git server signs with it.
- Do not change the Pipeline `ci-build`, the TriggerTemplate `ci-build-run` or the TriggerBinding `github-push`.

## Done when

- The EventListener `starfleet-ci` uses `starfleet-triggers` and its `Ready` condition is `True`.
- A push to `refs/heads/main` with a new commit ID, signed with `lab-only-webhook-secret`, creates a `PipelineRun` of `ci-build` with `revision` = the commit ID and `branch` = `main`, and that run succeeds.
- A push to `main` without a signature, and one signed with another secret, create no `PipelineRun`.
- A correctly signed push to another branch, and a correctly signed event of type `pull_request`, create no `PipelineRun`.
