# Prerequisites

Before starting this lab you should be able to:

- Explain how an EventListener selects Triggers by label.
- Read a CEL filter with `exists` and `startsWith`.
- Read the log of the core interceptors and of the EventListener.
- Find which Trigger created a run from the label `triggers.tekton.dev/trigger`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` with a label selector, the Trigger `github-push`, the Trigger `docs-check`, the TriggerBinding `github-push`, the TriggerTemplates `ci-build-run` and `docs-check-run`, the Pipelines `ci-build`, `pr-check` and `docs-check`, the Secret `github-webhook-secret`, and the Deployment `webhook-client` with payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The webhook secret of the lab is `lab-only-webhook-secret`.
- The payloads `push-main-docs.json` and `push-main-src.json` list the changed files like a GitHub push event.
