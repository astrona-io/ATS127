# Bindings And Templates In Depth

A push event carries dozens of fields. A `PipelineRun` needs a handful of parameters. Everything between them is the work of bindings and templates, and most failed builds that "look right" trace back to one wrong path, one parameter that came from the wrong place, or one resource that the EventListener was not allowed to create. A short sample of that work is easy. The details decide whether it holds up.

A `TriggerBinding` is a list of parameters whose values are read from the event. A `TriggerTemplate` is a list of objects to create, with `$(tt.params.<name>)` placeholders that the parameters fill. The EventListener pod evaluates the bindings first, then the template, then creates the objects with its ServiceAccount.

Keep one sentence in mind: **a binding only copies, and a template only substitutes.** Neither of them checks, converts or computes anything. If a value needs cutting or testing, an interceptor does it before the binding runs.

The module has four parts. **Read Values With JSONPath** reads nested fields, array items, headers and whole objects, and shows how to see the values a Trigger produced. **Combine Several Bindings** splits parameters over a `TriggerBinding`, a `ClusterTriggerBinding` and inline bindings. **Templates With Several Resources** creates a `PipelineRun` and a `ConfigMap` from one event and shows the RBAC the second resource needs. A graded lab follows it. **PipelineRun Options, Defaults And uid** sets timeouts, labels and annotations from event values and links the objects of one event.

## Learning objectives

After this module you can:

- Read nested fields, array items, headers and whole objects with `$(body...)` and `$(header...)`.
- Print the values a Trigger produced with a debug template that creates a `TaskRun`.
- Combine a `TriggerBinding`, a `ClusterTriggerBinding` and inline bindings in one Trigger.
- Create several resources from one event and grant the EventListener the right to create each kind.
- Set `timeouts`, labels, annotations and `$(uid)` in a `PipelineRun` template, and use defaults for parameters that an event may not carry.

## Before you start

You need the basics of Tekton Triggers: an `EventListener` runs a Trigger for each event, a `TriggerBinding` reads values with `$(body...)`, and a `TriggerTemplate` creates a `PipelineRun` with `generateName`.

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
