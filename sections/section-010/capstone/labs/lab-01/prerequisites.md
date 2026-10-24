# Prerequisites

Before starting this capstone you should be able to:

- Find the Deployment, Service and pod of an EventListener and read its `Ready` condition and logs.
- Bind the Triggers ClusterRoles to an EventListener's ServiceAccount.
- Reference a `ClusterTriggerBinding` from a Trigger and read `$(body...)` paths against a payload.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the Pipeline `ci-build`, the TriggerTemplate `ci-build-run`, the ServiceAccount `starfleet-triggers`, the EventListener `starfleet-ci`, and the Deployment `webhook-client` with sample payloads in `/payloads`.
- The cluster-scoped ClusterTriggerBinding `github-push`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own push event with a new commit ID.
