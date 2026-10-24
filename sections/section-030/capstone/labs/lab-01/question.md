# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Event-driven CI

## Scenario

The `starfleet` team moved its CI to standalone Triggers so that each team can add its own. Pushes to `main` should start `ci-build`, and pull requests against `main` should start `pr-check`, created by the restricted ServiceAccount `starfleet-pr-runner`. Since the move, neither pushes nor pull requests start anything, and the Git server sees `202` for every delivery.

## Your task

1. From the `webhook-client` pod, send `/payloads/push-main.json` as a signed `push` event and `/payloads/pull-request-opened.json` as a signed `pull_request` event (secret `lab-only-webhook-secret`) to `http://el-starfleet-ci.starfleet.svc.cluster.local:8080`.
2. Follow each event by its event ID and find out where it stops. Fix every fault you find. There is more than one, and some only show after the one before is fixed.
3. Leave the system in a state where a push to `main` starts `ci-build` and an opened pull request against `main` starts `pr-check`.

## Constraints

- Keep the Triggers `github-push` and `github-pull-request` as standalone objects with the label `team: starfleet`, and keep the EventListener's label selector. Do not add inline Triggers.
- Keep `serviceAccountName: starfleet-pr-runner` on the Trigger `github-pull-request`. Give `starfleet-pr-runner` only what it needs: it must be able to create PipelineRuns in `starfleet`, and must not be able to delete pods, create Deployments or create Secrets.
- Keep the interceptors of both Triggers, the webhook Secret, the bindings, the templates and the Pipelines.

## Done when

- The EventListener `starfleet-ci` is `Ready`, selects Triggers with the label selector `team: starfleet`, and has no inline Triggers; both Triggers carry that label.
- The Trigger `github-pull-request` uses `starfleet-pr-runner`, which can create PipelineRuns in `starfleet` and has no broader rights.
- A signed push to `main` with a new commit ID creates exactly one `PipelineRun`, of `ci-build` from `github-push`, with `branch` = `main`, and that run succeeds.
- A signed, opened pull request against `main` creates exactly one `PipelineRun`, of `pr-check` from `github-pull-request`, with `revision` = the head commit and `pr-number` = the number, and that run succeeds.
- A signed, closed pull request, a signed pull request against another base branch, and an unsigned pull request create no `PipelineRun`.
