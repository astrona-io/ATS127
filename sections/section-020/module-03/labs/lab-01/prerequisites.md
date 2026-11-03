# Prerequisites

Before starting this lab you should be able to:

- Describe the request and the response of a custom interceptor.
- Read a `ClusterInterceptor` and find the Service it points at.
- Read the log of an EventListener and of a Deployment.
- Read an extension in a binding with `$(extensions.<name>)`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` with its ServiceAccount and RBAC, the TriggerBinding `branch-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build`, the interceptor service `branch-check` (ConfigMap `branch-check-code`, Deployment and Service), and the Deployment `webhook-client` with sample payloads in `/payloads`.
- The ClusterInterceptor `branch-check`.

## Working rules

- Everything is graded on the **final cluster state**.
- The service returns the extension `short_branch` for a push to a branch and stops everything else.
