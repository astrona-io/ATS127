# Overview: Run CI On Push And Pull Request Events (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, Tekton Triggers and a ready-made push path, but no EventListener. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors in `tekton-pipelines`.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Pipeline `ci-build` | Parameters `repo-url`, `revision`, `branch`; result `summary` = `built <branch> at <revision>` |
  | Pipeline `pr-check` | Parameters `repo-url`, `revision`, `pr-number`; result `summary` = `checked pull request <n> at <revision>` |
  | ServiceAccount `starfleet-triggers` | Bound to `tekton-triggers-eventlistener-roles` and `tekton-triggers-eventlistener-clusterroles` |
  | Secret `github-webhook-secret` | Key `secretToken`, value `lab-only-webhook-secret` (lab only) |
  | TriggerBinding `github-push`, TriggerTemplate `ci-build-run` | Map a push to `ci-build`; `branch` comes from the CEL overlay `branch_name` |
  | Trigger `github-push` | Label `team: starfleet`; `github` interceptor (signature, event type `push`), `cel` interceptor (only `main`, overlay `branch_name`) |
  | Deployment `webhook-client` | `curl`, `openssl` and `jq`, with payloads in `/payloads` |

- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.

## Helpers

Paste these once in each new terminal. `send_signed` signs a payload file in the client pod with the lab secret and sends it with an event type, and prints the response with the `eventID`. `runs_of` lists the PipelineRuns of one event ID. `interceptor_logs` prints the newest lines of the core interceptors' log.

```sh
send_signed() {
  # send_signed EVENT_TYPE PAYLOAD_FILE
  kubectl exec -n starfleet deploy/webhook-client -- bash -c '
    signature="$(openssl dgst -sha256 -hmac lab-only-webhook-secret "$2" | awk "{print \$NF}")"
    curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: $1" \
      -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$2" \
      http://el-starfleet-ci.starfleet.svc.cluster.local:8080
    echo' _ "$1" "$2"
}
runs_of() {
  kubectl get pipelineruns -n starfleet -l "triggers.tekton.dev/triggers-eventid=$1" -L triggers.tekton.dev/trigger
}
interceptor_logs() {
  kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=10
}
```

Use them like this: `send_signed push /payloads/push-main.json`, `runs_of <EVENT_ID>`, `interceptor_logs`.

## Practice tasks

- Give the Trigger `github-pull-request` the label `team: other` and send an opened pull request. What do the core interceptors' log and the EventListener's log show now?
- Create a ServiceAccount `starfleet-pr-runner` with no permissions, set it as `serviceAccountName` of the pull request Trigger, and send an opened pull request. Find the `forbidden` message, then give the ServiceAccount a Role that allows only `create` on `pipelineruns`.
- Add a binding parameter that reads `$(context.eventID)`, add a matching parameter to a copy of the template and the Pipeline, and print the event ID in the run.
- Write a payload for a deleted branch (`"deleted": true`, no `head_commit`) and send it as a push to `main`. Where does it stop, and how would you filter it out earlier?
- Send the same signed pull request twice. How many runs appear, and how would you tell them apart?
- Use `tkn pipelinerun delete --keep` with a label to keep only the newest `pr-check` run.
