# Configure The EventListener

An EventListener that works on a laptop often fails in a real cluster. It runs as one pod, so a node restart drops events. Its Service is reachable only inside the cluster. Its pod has no resource limits, and when it misbehaves, nobody knows where to read its log or its metrics. All of this is configuration of the EventListener object itself, not of the Pipeline it starts.

An `EventListener` is the Triggers object that the controller turns into a Deployment and a Service named `el-<name>`. Its `spec` has fields that shape that Deployment and that Service, and fields that choose which Triggers it serves. Its `status` tells you whether the Deployment is available and which address clients use.

Keep one sentence in mind: **you change the EventListener, and the Triggers controller changes the Deployment and the Service to match.** If you edit the Deployment by hand, the controller undoes the edit.

The module has four parts. **Read An EventListener's Spec And Status** names the fields of the object and reads its status. **Replicas, Service Type And Pod Template** shapes the Deployment and the Service with `resources.kubernetesResource`. A graded lab follows it. **Choose Which Triggers An EventListener Serves** uses `namespaceSelector` and `labelSelector`. **Logs, Metrics And Timeouts** shows where an EventListener writes its log, where it exposes metrics, and which timeouts the controller sets.

## Learning objectives

After this module you can:

- Name the fields of the `EventListener` spec and read its `status`, including the address and the `Ready` condition.
- Set the number of replicas, the Service type and the pod template of an EventListener.
- Explain why the Triggers controller owns the Deployment and the Service of an EventListener.
- Select Triggers by namespace and by label, and say which RBAC each choice needs.
- Read the log of an EventListener, find its metrics port and name the timeouts of its HTTP server.

## Before you start

You need Kubernetes basics (Deployments, Services, pods, labels, `kubectl get`, `kubectl logs`) and the basics of Tekton Triggers: an EventListener receives an event, a `TriggerBinding` reads values from it and a `TriggerTemplate` creates a `PipelineRun`.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Namespace `starfleet` | The Pipeline `ci-build`, the Deployment `webhook-client` and the EventListener `starfleet-ci` |
| EventListener `starfleet-ci` | One Trigger `github-push` without interceptors, with its ServiceAccount `starfleet-triggers` and the RBAC from the Triggers release |
| TriggerBinding `github-push` and TriggerTemplate `ci-build-run` | Map a push event to a `PipelineRun` of `ci-build` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
