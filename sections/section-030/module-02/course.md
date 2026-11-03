# Run Lifecycle: Retention And Cleanup

Every event that passes the interceptors leaves a `PipelineRun` behind, and every `PipelineRun` leaves a `TaskRun` and a pod. Nothing removes them. On a busy repository the namespace holds thousands of finished runs within weeks, and the API server, the storage and the output of `kubectl get` all suffer. A team that runs Tekton Triggers in production needs a retention rule.

Keep one sentence in mind: **a run can only be removed by a rule that can tell it apart from the runs you keep, and the rule is a label.** The labels that the EventListener sets, plus labels you add in the TriggerTemplate, are what every cleanup tool selects on.

The module has four parts. **What An Event Leaves Behind** lists the objects and labels of one event. **Delete Runs By Label And By Age** removes runs by hand with `kubectl` and `tkn`. **Automate Cleanup With A CronJob** gives a small ServiceAccount only the rights to delete runs and runs the cleanup on a schedule. A graded lab follows it. **Retention Labels In The Template** puts a purpose on every run when it is created, so that rules can treat builds and releases differently.

## Learning objectives

After this module you can:

- List the objects one accepted event creates and the labels each carries.
- Delete runs by label, by count and by age with `kubectl` and `tkn`.
- Run a cleanup on a schedule with a CronJob and the smallest RBAC that works.
- Mark runs with a retention label in a TriggerTemplate.
- Explain why deleting a `PipelineRun` also removes its `TaskRun` and pods.

## Before you start

You need the basics of the earlier modules: an EventListener, a Trigger, a binding and a template, and the event ID. You also need basic Kubernetes RBAC (Role, RoleBinding, ServiceAccount) and CronJobs.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Namespace `starfleet` | The Pipeline `ci-build`, the EventListener `starfleet-ci`, the Trigger `github-push` and the Deployment `webhook-client` |
| PipelineRuns `old-build-1` to `old-build-3` and `release-1` | Runs with the label `purpose` set to `old-build` or `release` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
