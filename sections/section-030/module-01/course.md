# Run CI On Push And Pull Request Events

A developer opens a pull request against `main`. The team expects a check to run on the head commit of that pull request, and a build to run on `main` after the merge. Instead, the pull request starts nothing, or worse, it starts the release build. Event-driven CI works only when each kind of event reaches the right Pipeline with the right values, and when you can prove which event caused which run.

Tekton Triggers handles this with several `Trigger` objects behind one `EventListener`. Each event runs through every Trigger the EventListener selects. The interceptors of each Trigger decide whether that Trigger acts on the event, its binding reads the fields of that event type, and its template starts its own Pipeline. Every object the EventListener creates carries the ID of the event that caused it.

Keep one sentence in mind: **one event, every selected Trigger, each with its own chain.** A push and a pull request take different paths only because the interceptors of each Trigger let one through and stop the other.

The module has three parts. **GitHub Push And Pull Request Payloads** compares the two payloads and maps the pull request fields to the parameters of the Pipeline `pr-check`. **One EventListener, Several Triggers** turns the Triggers into their own objects, lets the EventListener select them by label, and adds a pull request Trigger next to the push Trigger. A graded lab follows it. **Trace And Clean Up Event-Driven Runs** follows events by their ID through responses, labels and logs, and removes old runs.

## Learning objectives

After this module you can:

- Name the fields of a GitHub `push` and `pull_request` event that a CI system uses, and the pull request actions that should start a check.
- Write a `TriggerBinding` and a `TriggerTemplate` for pull request events.
- Create standalone `Trigger` objects and select them with an EventListener's `labelSelector`.
- Explain how interceptors make each event start only the Trigger meant for it.
- Give a Trigger its own ServiceAccount and the permission to create runs.
- Trace an event by its event ID and clean up event-driven PipelineRuns by label.

## Before you start

You need the basics of Tekton Triggers: an `EventListener` receives events through a Service named `el-<name>`, a `TriggerBinding` reads values with `$(body...)` and `$(extensions...)`, a `TriggerTemplate` creates a `PipelineRun`, and the `github` and `cel` interceptors verify signatures and filter events. You also need to know how to sign a payload with `openssl dgst -sha256 -hmac`.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Pipelines `ci-build` and `pr-check` | In `starfleet`. `ci-build` takes `repo-url`, `revision`, `branch`; `pr-check` takes `repo-url`, `revision`, `pr-number` |
| Trigger `github-push` | A standalone Trigger with the label `team: starfleet`: signature check, filter for `main`, binding `github-push`, template `ci-build-run` |
| ServiceAccount `starfleet-triggers`, Secret `github-webhook-secret` | The EventListener's identity with its RBAC, and the webhook secret `lab-only-webhook-secret` |
| Deployment `webhook-client` | A pod with `curl`, `openssl` and `jq`, and sample GitHub payloads in `/payloads` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

There is no EventListener yet. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
