# Prerequisites

Before starting this lab you should be able to:

- Read the fields of a GitHub `pull_request` event: `action`, `number`, `pull_request.head.sha`, `pull_request.base.ref`.
- Write a `TriggerBinding`, a `TriggerTemplate` and a standalone `Trigger` with the `github` and `cel` interceptors.
- Sign a payload with `openssl dgst -sha256 -hmac` and send it with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the Pipelines `ci-build` and `pr-check`, the ServiceAccount `starfleet-triggers` with its RBAC, the Secret `github-webhook-secret`, the TriggerBinding `github-push`, the TriggerTemplate `ci-build-run`, the Trigger `github-push`, the EventListener `starfleet-ci`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own signed and unsigned events with new commit IDs and pull request numbers.
