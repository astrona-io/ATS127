# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** GitLab interceptor and CEL

## Scenario

The `starfleet` team moved a project to GitLab. Its webhook sends the secret token from the Secret `gitlab-webhook-secret` and the event name in the headers. The EventListener `starfleet-ci` has no interceptors: it accepts any request, and its binding `gitlab-push` reads the branch from an extension that nobody adds, so even real pushes start nothing.

## Your task

1. Add the `gitlab` interceptor to the Trigger `gitlab-push`. It must check the token with the Secret `gitlab-webhook-secret` (key `secretToken`) and accept only the event type `Push Hook`.
2. Add a `cel` interceptor after it that lets through only pushes to `refs/heads/main`.
3. Let the same `cel` interceptor add the short branch name as the extension `branch`, so `main` for `refs/heads/main`.

## Constraints

- Do not change the TriggerBinding `gitlab-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build` or the Secret.
- Keep the Trigger name `gitlab-push` and its binding and template.
- The `gitlab` interceptor must come before the `cel` interceptor.

## Done when

- A GitLab push to `main` with the right token creates a `PipelineRun` of `ci-build` with the commit ID, the clone URL and `branch` set to `main`.
- A push with a wrong token, or without a token, creates nothing.
- An event of the type `Merge Request Hook` with the right token creates nothing.
- A push to another branch with the right token creates nothing.
