# Turn A Webhook Into A PipelineRun

A developer pushes a commit to `main`, and nothing happens. The Pipeline exists, the cluster is healthy, and yet no build starts. Somewhere between the Git server and Tekton Pipelines, a request was lost, refused or ignored. To find where, you need to know every object and every pod on the path from the HTTP request to the `PipelineRun`.

Tekton Triggers is that path. An `EventListener` is a Triggers object that runs a small HTTP server in your namespace. The Triggers controller creates a Deployment and a Service named `el-<name>` for it. When a request arrives, the EventListener pod runs each `Trigger`: a `TriggerBinding` reads values from the request, and a `TriggerTemplate` uses them to create a `PipelineRun`.

Keep one sentence in mind: **the EventListener pod creates the PipelineRun with its own ServiceAccount.** Whatever that ServiceAccount may not do, the EventListener cannot do either, and the HTTP response will not tell you.

The module has three parts. **Install Tekton Triggers And Meet Its Resources** installs Triggers on top of Tekton Pipelines and names every object the release adds. **The EventListener, Its ServiceAccount And RBAC** creates the ServiceAccount, binds it to the roles that the release ships, and creates an EventListener whose pod becomes ready. **TriggerBindings, TriggerTemplates And tt.params** maps fields of a push event to the parameters of a `PipelineRun` and sends the first event from a pod inside the cluster. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Install Tekton Triggers v0.37.2 from `release.yaml` and `interceptors.yaml`, and check its Deployments and version.
- Name the Triggers resources (`EventListener`, `Trigger`, `TriggerBinding`, `ClusterTriggerBinding`, `TriggerTemplate`, `ClusterInterceptor`) and say what each one does.
- Find the Deployment, Service and pod that the Triggers controller creates for an EventListener, and read its `Ready` condition.
- Give an EventListener a ServiceAccount with the RBAC from the release, and recognise the symptoms of a missing binding.
- Read event fields with `$(body...)` and `$(header...)`, pass them as `$(tt.params...)`, and create PipelineRuns with `generateName`.

## Before you start

You need Kubernetes basics (namespaces, pods, Services, ServiceAccounts, Roles and RoleBindings, `kubectl apply`, `kubectl logs`, `kubectl exec`) and Tekton Pipelines basics: a `Pipeline` is an ordered set of Tasks, and a `PipelineRun` is one execution of it with its own parameter values.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2: the controllers, the webhooks and the core interceptors |
| Namespace `starfleet` | The Pipeline `ci-build` and the Deployment `webhook-client`. Your Triggers objects go here |
| Pipeline `ci-build` | Takes the parameters `repo-url`, `revision` and `branch`, and reports them in its result `summary` |
| Deployment `webhook-client` | A pod with `curl` and `openssl` and sample GitHub payloads in `/payloads` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
