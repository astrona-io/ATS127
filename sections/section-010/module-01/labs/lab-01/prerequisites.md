# Prerequisites

Before starting this lab you should be able to:

- Read a `TriggerTemplate` and write a `TriggerBinding` with `$(body...)` paths.
- Create a ServiceAccount, a RoleBinding and a ClusterRoleBinding.
- Use `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl exec`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the Pipeline `ci-build`, the TriggerTemplate `ci-build-run`, and the Deployment `webhook-client` with sample payloads in `/payloads`.

## Working rules

- Everything is graded on the **final cluster state**. Leave your objects in place.
- The grader sends its own push event with a new commit ID, so the binding must read the values from the event, not hold fixed values.
