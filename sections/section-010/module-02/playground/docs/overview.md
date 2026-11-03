# Overview: Configure The EventListener (Playground)

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

Paste these once in each new terminal. `send_push` sends the sample push to the Service of an EventListener; pass its name. `show_runs` lists the PipelineRuns of one EventListener.

```sh
send_push() {
  # send_push EVENTLISTENER_NAME
  kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json "http://el-$1.starfleet.svc.cluster.local:8080"
  echo
}
show_runs() {
  kubectl get pipelineruns -n starfleet -l "triggers.tekton.dev/eventlistener=$1" --sort-by=.metadata.creationTimestamp
}
```

## Practice tasks

- Set `replicas: 3` in the EventListener. Then run `kubectl scale deployment el-starfleet-ci -n starfleet --replicas=1` and watch the controller restore the value.
- Add a `nodeSelector` that matches no node. Read the pod events to see why the pods stay `Pending`, and why the old pods keep answering during the rollout.
- Set `serviceType: LoadBalancer` and read the Service. Which column stays `<pending>` on a `kind` cluster, and why?
- Create a standalone `Trigger` with the label `ci: push` and an EventListener that selects it. Send a push with `send_push` and compare `show_runs` for both EventListeners.
- Make the standalone Trigger's template name wrong. Read the log with `tkn eventlistener logs`.
- Print `-o yaml` of the EventListener and compare `status.address.url` with the Service name.
- Read the arguments of the Deployment `tekton-triggers-controller` and find the four timeout flags.
