# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Event-driven CI

## Scenario

The `starfleet` team's EventListener `starfleet-ci` builds every signed push to `main` through the standalone Trigger `github-push`. Reviewers now want a check on every pull request against `main` before they merge it. The Pipeline `pr-check` exists, but no event starts it.

## Your task

1. Create the TriggerBinding `github-pull-request` in `starfleet`. From a GitHub `pull_request` event, it sets `repo-url` to `repository.clone_url`, `revision` to `pull_request.head.sha`, and `pr-number` to `number`.
2. Create the TriggerTemplate `pr-check-run` in `starfleet`. It declares `repo-url`, `revision` and `pr-number` and creates a `PipelineRun` of `pr-check` with `generateName: pr-check-run-`, passing all three parameters.
3. Create the standalone Trigger `github-pull-request` in `starfleet` with the label `team: starfleet`. It runs, in this order:
   - the `github` interceptor with a `secretRef` to the key `secretToken` of the Secret `github-webhook-secret` and the event type `pull_request`;
   - a `cel` interceptor that lets through only the actions `opened`, `synchronize` and `reopened` of pull requests whose base branch is `main`;
   then the binding `github-pull-request` and the template `pr-check-run`.
4. Send `/payloads/pull-request-opened.json` and `/payloads/pull-request-closed.json` from the `webhook-client` pod as signed `pull_request` events (secret `lab-only-webhook-secret`) and check the result.

## Constraints

- Do not change the EventListener `starfleet-ci`: it must keep selecting Triggers with the label selector `team: starfleet` and list no inline Triggers.
- Do not change the Trigger `github-push`, its binding or its template. A push to `main` must still start `ci-build`, and only `ci-build`.
- Do not change the Pipelines or the Secret.

## Done when

- The EventListener `starfleet-ci` is `Ready`, selects Triggers with `team: starfleet`, and has no inline Triggers; the Triggers `github-push` and `github-pull-request` both carry that label.
- A signed, opened pull request against `main` with a new head commit and number creates exactly one `PipelineRun`: a run of `pr-check` from the Trigger `github-pull-request` with `revision` = the head commit, `pr-number` = the number and `repo-url` = `https://git.example.com/starfleet/bridge.git`, and that run succeeds.
- A signed, closed pull request, a signed pull request against another base branch, and an unsigned pull request create no `PipelineRun`.
- A signed push to `main` creates exactly one `PipelineRun`, of `ci-build` from the Trigger `github-push`, with `branch` = `main`, and that run succeeds.
