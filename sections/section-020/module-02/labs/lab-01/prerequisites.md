# Prerequisites

Before starting this lab you should be able to:

- Add an interceptor with `ref` and `params` to a Trigger.
- Check a webhook with a `secretRef` and `eventTypes`.
- Filter and add `extensions` with the `cel` interceptor.
- Send a webhook from the `webhook-client` pod with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors, in the namespace `tekton-pipelines`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- In the namespace `starfleet`: the EventListener `starfleet-ci` with its ServiceAccount and RBAC, the Secret `gitlab-webhook-secret`, the TriggerBinding `gitlab-push`, the TriggerTemplate `ci-build-run`, the Pipeline `ci-build`, and the Deployment `webhook-client` with a sample GitLab push in `/payloads/gitlab-push-main.json`.

## Working rules

- Everything is graded on the **final cluster state**.
- The grader sends its own events with a new commit ID, the header `X-Gitlab-Event` and, when it has one, the header `X-Gitlab-Token`.
