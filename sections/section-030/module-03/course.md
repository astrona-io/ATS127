# Path-Filtered And Multi-Pipeline Triggers

A push event does not only say which branch changed. It also lists which files each commit added, modified and removed. That list lets one repository start different pipelines for different changes: a documentation check when `docs/` changed, a build when code changed, and both when a push touched both.

Keep one sentence in mind: **a Trigger decides for itself whether an event is its business, so several Triggers on one EventListener can each start their own Pipeline from the same event.** The filter is a CEL expression over the file lists in the payload, and the fan-out is the EventListener running every Trigger it selects.

The module has four parts. **Which Files Did A Push Change** reads the file lists in a GitHub push payload. **Filter On Paths With CEL** writes the expressions. **Fan Out To Several Pipelines** adds a second Trigger and Pipeline for one event. A graded lab follows it. **Edge Cases And Build Unless Docs Only** covers empty pushes, missing fields and the opposite rule.

## Learning objectives

After this module you can:

- Read the `added`, `modified` and `removed` lists of a push payload.
- Write a CEL filter that matches changes under a path.
- Start two Pipelines from one event with two Triggers.
- Explain what happens to events without a `commits` list.
- Write a rule that builds unless only documentation changed.

## Before you start

You need the earlier modules of this section: a standalone Trigger with a label, an EventListener with a label selector, and the `github` and `cel` interceptors. You should be able to read a short CEL expression.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Namespace `starfleet` | The Pipelines `ci-build` and `docs-check`, the Trigger `github-push`, the templates `ci-build-run` and `docs-check-run`, and the Deployment `webhook-client` |
| Payloads in `/payloads` | `push-main-docs.json` changes `docs/status.md`, `push-main-src.json` changes `src/bridge.go`, `push-main.json` has no file lists |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

The EventListener `starfleet-ci` is in the playground too. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
