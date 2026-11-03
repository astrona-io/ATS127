# Prerequisites

Before starting this lab you should be able to:

- List and delete Kubernetes objects with a label selector.
- Write a ServiceAccount, a Role and a RoleBinding.
- Check permissions with `kubectl auth can-i --as`.
- Write a CronJob with a schedule and a ServiceAccount.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the push path from the earlier modules (the EventListener `starfleet-ci`, the Trigger `github-push`, the binding, the template and the Pipelines), the Deployment `webhook-client`, and the PipelineRuns `old-build-1`, `old-build-2`, `old-build-3` and `release-1`.

## Working rules

- Everything is graded on the **final cluster state**.
- The CronJob is graded on its definition. The grader does not wait for the schedule.
- The container image of the CronJob is not checked. The Kubernetes project publishes `registry.k8s.io/kubectl`.
