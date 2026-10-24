# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Interceptors

## Scenario

A security review found that the EventListener `starfleet-ci` of the `starfleet` team builds every JSON request it receives, from any sender and for any branch. The team has set the webhook secret `lab-only-webhook-secret` in the Git server, which now signs every delivery. You must make the EventListener trust only those signed deliveries, and build only pushes to `main`.

## Your task

1. Create the Secret `github-webhook-secret` in `starfleet` with the key `secretToken` and the value `lab-only-webhook-secret`.
2. Add two interceptors to the Trigger `github-push` of the EventListener `starfleet-ci`, in this order:
   - the `github` interceptor, with a `secretRef` to that Secret and key, and the event type `push`;
   - the `cel` interceptor, with a filter that lets through only pushes to `refs/heads/main`, and an overlay `branch_name` that holds the short branch name (`main`).
3. Change the TriggerBinding `github-push` so that `branch` comes from the overlay `branch_name`.
4. Check your work by sending signed and unsigned payloads from the `webhook-client` pod.

## Constraints

- Keep the EventListener `starfleet-ci`, its ServiceAccount `starfleet-triggers`, the Trigger name `github-push`, the TriggerTemplate `ci-build-run` and the Pipeline `ci-build`.
- Keep `repo-url` and `revision` in the TriggerBinding as they are.

## Done when

- The EventListener `starfleet-ci` uses `starfleet-triggers` and its `Ready` condition is `True`.
- The Secret `github-webhook-secret` stores `lab-only-webhook-secret` under `secretToken`, and the Trigger `github-push` runs the `github` interceptor with a `secretRef` to it before the `cel` interceptor.
- A push to `refs/heads/main` with a new commit ID, signed with `lab-only-webhook-secret`, creates a `PipelineRun` of `ci-build` with `revision` = the commit ID and `branch` = `main`, and that run succeeds.
- A push to `main` without a signature, and one signed with another secret, create no `PipelineRun`.
- A correctly signed push to another branch, and a correctly signed event of type `pull_request`, create no `PipelineRun`.
