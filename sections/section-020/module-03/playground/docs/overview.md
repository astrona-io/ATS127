# Overview: Write A Custom ClusterInterceptor (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, Tekton Triggers and an EventListener that accepts every request. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** in `tekton-pipelines`. The Deployment `tekton-triggers-core-interceptors` serves the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack`; its log holds the reason each time an interceptor stops an event.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | EventListener `starfleet-ci` | One Trigger `github-push`, no interceptors. Service `el-starfleet-ci`, port 8080 |
  | ServiceAccount `starfleet-triggers` | Bound to `tekton-triggers-eventlistener-roles` and `tekton-triggers-eventlistener-clusterroles` |
  | TriggerBinding `github-push` | `repo-url`, `revision` and `branch` (the full ref) from a push |
  | TriggerTemplate `ci-build-run` | Creates a `PipelineRun` of `ci-build` with `generateName: ci-build-run-` |
  | Pipeline `ci-build` | Reports the values it received in its result `summary` |
  | Deployment `webhook-client` | `curl` and `openssl`, with payloads in `/payloads` |

- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.

## Helpers

Paste these once in each new terminal. `call_interceptor` sends a ref to the service directly; pass the ref.

```sh
call_interceptor() {
  # call_interceptor REF
  kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' --data-binary "{\"body\":\"{\\\"ref\\\":\\\"$1\\\"}\",\"header\":{},\"extensions\":{},\"interceptor_params\":{},\"context\":{}}" http://branch-check.starfleet.svc.cluster.local:80/
  echo
}
```

## Practice tasks

- Call the service with `refs/heads/main`, `refs/heads/feature/shields` and `refs/tags/v1`, and compare the answers.
- Use the interceptor in an EventListener with the binding `branch-push` and send the sample push.
- Edit the ConfigMap `branch-check-code` so that it also returns the ref in an extension, restart the Deployment, and read it in a binding.
- Scale the Deployment to zero and send a push. Read what the EventListener log says.
- Point the ClusterInterceptor at port 8081 and read the symptom.
