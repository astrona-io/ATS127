# Prerequisites

Before starting this lab you should be able to:

- Read the spec and the status of an EventListener.
- Set `resources.kubernetesResource` with replicas, a Service type and a pod template.
- Send a push event from the `webhook-client` pod with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` with its ServiceAccount and RBAC, the TriggerBinding `github-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**.
- The EventListener has no interceptors. The grader sends its own push event with a new commit ID.
