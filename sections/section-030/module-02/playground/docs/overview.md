# Overview: Run Lifecycle: Retention And Cleanup (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, Tekton Triggers, a working push path and a few runs to clean up. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors in `tekton-pipelines`.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | EventListener `starfleet-ci` | Selects every Trigger with the label `team: starfleet`. Service `el-starfleet-ci`, port 8080 |
  | Trigger `github-push` | Verifies the signature and the event type, lets through only pushes to `main` |
  | TriggerBinding `github-push`, TriggerTemplate `ci-build-run` | Map a push to a PipelineRun of `ci-build`. The template sets no `purpose` label |
  | Pipelines `ci-build` and `pr-check` | Each reports what it received in its result `summary` |
  | PipelineRuns `old-build-1`, `old-build-2`, `old-build-3` | Label `purpose=old-build` |
  | PipelineRun `release-1` | Label `purpose=release` |
  | Deployment `webhook-client` | `curl`, `openssl` and `jq`, with payloads in `/payloads` |

- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.

## Helpers

Paste these once in each new terminal. `send_signed` signs a payload file in the client pod with the lab secret and sends it with an event type. `runs` lists the PipelineRuns with the labels that matter for cleanup.

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
runs() {
  kubectl get pipelineruns -n starfleet -L purpose,triggers.tekton.dev/trigger --sort-by=.metadata.creationTimestamp
}
```

Use them like this: `send_signed push /payloads/push-main.json`, then `runs`.

## Practice tasks

- Delete the runs with `purpose=old-build` and check that `release-1` is still there. Then check that the TaskRuns and pods of the deleted runs are gone.
- Send five pushes to `main` and use `tkn pipelinerun delete --pipeline ci-build --keep 2` to keep the two newest. Which of the seeded runs does the rule remove, and why is that a problem for `release-1`?
- Create the ServiceAccount `run-cleaner` with a Role for `pipelineruns` and test it with `kubectl auth can-i` as the account.
- Create the CronJob `cleanup-old-runs`, start a Job from it with `kubectl create job --from=cronjob/cleanup-old-runs`, and read the log.
- Add `purpose: ci-build` to the TriggerTemplate, send a push, and check which runs carry the label.
- Change the Job selector to `purpose!=release` and compare what it deletes with `purpose=old-build`.
