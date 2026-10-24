# Prerequisites

Before starting this capstone you should be able to:

- Create a Secret and reference it from the `github` interceptor with `secretRef`.
- Write a CEL `filter` and CEL `overlays`, and read an overlay in a binding as `$(extensions.<key>)`.
- Sign a payload with `openssl dgst -sha256 -hmac` and send it with `curl`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` without interceptors, its ServiceAccount `starfleet-triggers` with RBAC, the TriggerBinding `github-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own events with new commit IDs: signed and unsigned pushes, a push to another branch, and a `pull_request` event.
