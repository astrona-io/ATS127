# Prerequisites

Before starting this capstone you should be able to:

- Read an EventListener's `labelSelector` and the labels of standalone Triggers.
- Read the log of `tekton-triggers-core-interceptors` and the EventListener's log, and match lines to an event ID.
- Explain how a Trigger's `serviceAccountName` changes the identity that creates its runs, and create a Role and a RoleBinding.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci`, the Triggers `github-push` and `github-pull-request` with their bindings and templates, the Pipelines `ci-build` and `pr-check`, the ServiceAccounts `starfleet-triggers` and `starfleet-pr-runner`, the Secret `github-webhook-secret`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own signed and unsigned events with new commit IDs and pull request numbers.
