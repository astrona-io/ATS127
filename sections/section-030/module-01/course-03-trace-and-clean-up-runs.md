# Trace And Clean Up Event-Driven Runs

With two Triggers, two interceptors each, a binding and a template, an event can stop in many places, and the Git server only ever sees `202 Accepted`. When a developer says "my push did not build", you need a fast way to follow that one event through the system. And because every accepted event leaves a `PipelineRun` behind, the namespace fills up within days unless someone removes old runs. This part follows events by their event ID and cleans up runs by label.

## Follow one event by its ID

The EventListener gives every request an ID, returns it as `eventID` in the response, writes it into its log lines, and sets it as the label `triggers.tekton.dev/triggers-eventid` on every object it creates. Send a signed push and keep the response. The command signs and sends in one shell inside the client pod:

<!-- astrona:playground:renew -->

```sh
kubectl exec -n starfleet deploy/webhook-client -- bash -c 'SIGNATURE="$(openssl dgst -sha256 -hmac lab-only-webhook-secret /payloads/push-main.json | awk "{print \$NF}")"; curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: push" -H "X-Hub-Signature-256: sha256=$SIGNATURE" --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080'
```

Copy the value of `eventID` from the response and use it in place of `<EVENT_ID>`. First find the run that the event created:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/triggers-eventid=<EVENT_ID> -L triggers.tekton.dev/trigger
```

Exactly one run carries this event ID, a `ci-build-run-` run from the Trigger `github-push`. Then find what the EventListener did with the event:

```sh
tkn eventlistener logs starfleet-ci -n starfleet -t 50 | grep <EVENT_ID>
```

`tkn eventlistener logs` prints the logs of the EventListener's pods; `-t` sets the number of lines per pod. The lines with the event ID show the parameters the EventListener resolved (`ResolvedParams`) for the Trigger that created the run. For a Trigger whose interceptor stopped the event, the EventListener writes nothing at the default log level; that answer is in the log of `tekton-triggers-core-interceptors` in `tekton-pipelines`. A binding can also pass the ID into the run itself with `$(context.eventID)`, so the Pipeline can report which event started it.

## Where an event stops

Each place where an event can stop leaves its trace in a different place. Work down this table, from the request to the run:

| Symptom | Where to look | Typical cause |
| --- | --- | --- |
| The request fails or times out | `kubectl get el`, the EventListener pod's log | The pod is not ready: missing RBAC for its ServiceAccount |
| HTTP `400` | The response body | The body is not JSON |
| `202`, no run, no interceptor answers in the core interceptors' log | The EventListener's `labelSelector` and the Triggers' labels | No Trigger was selected |
| `202`, no run, an interceptor answered `Continue:false` | The core interceptors' log | Wrong signature or secret key, event type not allowed, CEL filter false |
| `202`, no run, `failed to replace JSONPath value` | The EventListener's log | A binding path the payload does not have |
| `202`, no run, `forbidden` when creating the run | The EventListener's log | The EventListener's or the Trigger's ServiceAccount may not create PipelineRuns |
| A run exists but fails | `tkn pipelinerun describe` and `tkn pipelinerun logs` | The Pipeline, a missing parameter, a wrong `pipelineRef` |

The response tells you only the first two rows. Everything after `202` happens inside the cluster, so the event ID is what ties the log lines and the run together.

## Clean up event-driven runs

Every push to `main` and every pull request update leaves a `PipelineRun` and its TaskRuns and pods. List the runs that one Trigger created:

```sh
tkn pipelinerun list -n starfleet --label triggers.tekton.dev/trigger=github-push
```

`tkn pipelinerun delete` can keep the newest runs and delete the rest. With `--keep` and `--label` it works on all runs in the namespace that match the label, and `-f` skips the question:

```sh
tkn pipelinerun delete -n starfleet --label triggers.tekton.dev/trigger=github-push --keep 1 -f
tkn pipelinerun list -n starfleet --label triggers.tekton.dev/eventlistener=starfleet-ci
```

Only the newest `github-push` run is left; the `pr-check` runs are untouched, because they carry the label `triggers.tekton.dev/trigger=github-pull-request`. Deleting a `PipelineRun` also deletes its TaskRuns and their pods, which belong to it. To remove every run of one event, delete by its event ID label instead. For regular cleanup, a scheduled job or the separate Tekton Pruner project does the same work without anyone typing commands.

## Exposing the EventListener

So far every request came from a pod inside the cluster, because the Service `el-starfleet-ci` has the type `ClusterIP`. A real Git server sends webhooks from outside. You can set the Service type with `spec.resources.kubernetesResource.serviceType` (`NodePort` or `LoadBalancer`) or put an Ingress in front of the Service, and you can serve HTTPS from the EventListener itself with a certificate. Whatever you choose, keep the signature check: once the address is public, anyone can send it requests. For a quick test from your own machine, `kubectl port-forward -n starfleet svc/el-starfleet-ci 8080:8080` forwards a local port to the Service.

You can now tie a response, a run and the log lines together with the event ID, find the place where an event stopped, and remove old runs by Trigger or by event. With that, you can run push and pull request CI from one EventListener and keep it understandable when it misbehaves.

## Common pitfalls

> [!WARNING]
> - **Searching the EventListener's log for an interceptor's answer.** Interceptor answers are in the log of `tekton-triggers-core-interceptors`.
> - **Matching runs by time.** Several events can arrive at once. Match by the label `triggers.tekton.dev/triggers-eventid`.
> - **`tkn pipelinerun delete --all` without a label.** It deletes every run in the namespace, also runs that no event created.
> - **Expecting `--keep` per Trigger without a label.** Without `--label` or `-p`, `--keep` counts all runs in the namespace.
> - **Exposing the Service without a signature check.** A public address with an open EventListener runs anything anyone sends.
