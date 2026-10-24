# Prerequisites

Before starting this lab you should be able to:

- Read an EventListener with a chain of interceptors.
- Sign a payload with `openssl dgst -sha256 -hmac` and send it with `curl` and the header `X-Hub-Signature-256`.
- Read the log of `tekton-triggers-core-interceptors` in `tekton-pipelines`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` with its ServiceAccount and RBAC, the TriggerBinding `github-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build`, the Secret `github-webhook-secret`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own events: signed and unsigned pushes with new commit IDs, a push to another branch, and a `pull_request` event. Your fix must accept the right ones and refuse the others.
