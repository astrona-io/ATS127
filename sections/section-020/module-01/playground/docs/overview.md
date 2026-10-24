# Overview: Verify And Filter Webhooks With Interceptors (Playground)

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
- No Secret yet. The parts use the lab-only webhook secret `lab-only-webhook-secret`.

## Helpers

Paste these once in each new terminal. `send_event` signs a payload file in the client pod with a secret and sends it with an event type; pass an empty secret to send no signature. `show_runs` lists the PipelineRuns of `starfleet-ci`. `interceptor_logs` prints the newest lines of the core interceptors' log.

```sh
send_event() {
  # send_event EVENT_TYPE SECRET PAYLOAD_FILE
  kubectl exec -n starfleet deploy/webhook-client -- bash -c '
    headers=(-H "Content-Type: application/json" -H "X-GitHub-Event: $1")
    if [ -n "$2" ]; then
      signature="$(openssl dgst -sha256 -hmac "$2" "$3" | awk "{print \$NF}")"
      headers+=(-H "X-Hub-Signature-256: sha256=$signature")
    fi
    curl -sS -X POST "${headers[@]}" --data-binary "@$3" http://el-starfleet-ci.starfleet.svc.cluster.local:8080
    echo' _ "$1" "$2" "$3"
}
show_runs() {
  kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci --sort-by=.metadata.creationTimestamp
}
interceptor_logs() {
  kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=10
}
```

Use them like this: `send_event push lab-only-webhook-secret /payloads/push-main.json`, `send_event push "" /payloads/push-main.json`, `show_runs`, `interceptor_logs`.

## Practice tasks

- Before you add any interceptor, send `/payloads/pull-request-opened.json` as a `push` event. Which values does the new run get, and why does the EventListener not complain?
- Set `secretKey` to `token` in the interceptor and send a correctly signed push. Find the message in `interceptor_logs`.
- Sign `/payloads/push-main.json`, but send `/payloads/push-feature.json` with that signature. Which message do you get?
- Write a CEL filter that lets through pushes to `main` and to branches that start with `release-`. Test it with a payload of your own.
- Add an overlay `event` with the expression `header['X-Github-Event'][0]` and read it in the binding. Then try `header['X-GitHub-Event'][0]` and compare. Which spelling of the header name does the map use?
- Swap the order of the `github` and `cel` interceptors and send an unsigned push to `feature-shields`. Which interceptor stops it now?
