# Overview: Turn A Webhook Into A PipelineRun (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines, Tekton Triggers and the `tkn` command-line tool, and gives you a namespace with a Pipeline and a pod that can send webhooks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2**, installed from their release manifests into the namespace `tekton-pipelines`. Tekton Triggers creates Tekton objects, such as PipelineRuns, from HTTP events. Its Deployments are:

  | Deployment | What it does |
  | --- | --- |
  | `tekton-triggers-controller` | Creates a Deployment and a Service named `el-<name>` for each `EventListener` |
  | `tekton-triggers-webhook` | Sets defaults on and validates Triggers objects when they are created |
  | `tekton-triggers-core-interceptors` | Serves the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack` |

- The Pipeline `ci-build` in `starfleet`. It takes the parameters `repo-url`, `revision` and `branch` (no defaults) and writes `built <branch> at <revision>` to its result `summary`. It clones nothing.
- The Deployment `webhook-client` in `starfleet`, with `curl` and `openssl`. It sends requests to the EventListener Service from inside the cluster. Sample GitHub payloads are in `/payloads`: `push-main.json`, `push-feature.json`, `pull-request-opened.json` and `pull-request-closed.json`.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- No EventListener, no ServiceAccount for it, no bindings and no templates. You create them.

## Helpers

Paste these once in each new terminal. `send_push` sends one sample payload as a push event to the EventListener `starfleet-ci`. `show_runs` lists the PipelineRuns that an EventListener created. `el_logs` prints the last lines of the EventListener's log.

```sh
send_push() {
  kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST \
    -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' \
    --data-binary "@/payloads/$1" http://el-starfleet-ci.starfleet.svc.cluster.local:8080
  echo
}
show_runs() {
  kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci
}
el_logs() {
  kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=20
}
```

Use them like this: `send_push push-main.json`, `show_runs`, `el_logs`.

## Practice tasks

- Create the EventListener before its ServiceAccount exists. What does `kubectl get pods -n starfleet -l eventlistener=starfleet-ci` show, and what does `kubectl describe replicaset -n starfleet -l eventlistener=starfleet-ci` say?
- Bind only `tekton-triggers-eventlistener-roles` and leave out the ClusterRoleBinding. Does the EventListener pod become ready? Read its log.
- Add an inline binding to the Trigger, `- name: branch` with `value: main`, after the `github-push` reference. Which value does the next run get for `branch`?
- Give the template parameter `revision` the default `unknown`, then send `{}` as the body. What does the new run receive?
- Change `generateName` in the template to a fixed `name` and send two push events. What does the EventListener's log say about the second one?
- Turn `github-push` into a `ClusterTriggerBinding` and reference it with `kind: ClusterTriggerBinding`. Then remove the `kind` line and send an event.
