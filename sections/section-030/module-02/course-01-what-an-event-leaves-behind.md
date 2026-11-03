# What An Event Leaves Behind

Before you can remove runs, you need to know exactly what one event creates and how to select it. This part follows one event and lists everything it leaves in the namespace.

## The chain of objects

One accepted event creates one `PipelineRun` for each resource in the TriggerTemplate. The Tekton Pipelines controller then creates a `TaskRun` for each task in the Pipeline, and the controller of the `TaskRun` creates a pod for it. Each object records its parent in `metadata.ownerReferences`:

| Object | Created by | Owned by |
| --- | --- | --- |
| `PipelineRun` | The EventListener | Nothing |
| `TaskRun` | The Pipelines controller | The `PipelineRun` |
| Pod | The `TaskRun` | The `TaskRun` |

Only the `PipelineRun` has no owner. When you delete it, Kubernetes garbage collection removes the `TaskRun` objects and then the pods. You never delete TaskRuns or pods by hand to clean up, and a cleanup job does not need rights on them.

## The labels

The EventListener adds three labels to every object it creates:

| Label | Value |
| --- | --- |
| `triggers.tekton.dev/eventlistener` | The name of the EventListener |
| `triggers.tekton.dev/trigger` | The name of the Trigger that matched |
| `triggers.tekton.dev/triggers-eventid` | The ID of the event |

The Pipelines controller adds `tekton.dev/pipeline` to the `PipelineRun`, with the name of the Pipeline. These four labels already let you answer most questions: which runs came from one event, from one Trigger, and from one Pipeline.

## Look at the playground

The playground has the Trigger `github-push` and four seeded runs. List the runs with their labels:

```sh
kubectl get pipelineruns -n starfleet --show-labels
```

Each seeded run has a `purpose` label, set to `old-build` or `release`. Send a signed push so that a run from an event exists as well:

<!-- astrona:playground:renew -->

```sh
kubectl exec -n starfleet deploy/webhook-client -- bash -c 'SIGNATURE="$(openssl dgst -sha256 -hmac lab-only-webhook-secret /payloads/push-main.json | awk "{print \$NF}")"; curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: push" -H "X-Hub-Signature-256: sha256=$SIGNATURE" --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080'
```

List the runs again and show only the label columns you care about:

```sh
kubectl get pipelineruns -n starfleet -L purpose,triggers.tekton.dev/trigger,tekton.dev/pipeline
```

The new run has the three labels from the EventListener and the Pipelines controller, and an empty `purpose` column, because the template does not set it yet. The seeded runs have a `purpose` and no trigger label, because they were not created by an event.

Now follow the chain down from one run:

```sh
kubectl get taskruns -n starfleet
kubectl get pods -n starfleet
```

Every `TaskRun` has a `PipelineRun` as its owner, and every pod belongs to a `TaskRun`.

## Why the count matters

A finished run still costs something. The `PipelineRun` and `TaskRun` objects are stored in etcd, the pods stay in the `Completed` state and keep their logs on the node, and every `kubectl get pipelineruns` and every dashboard has to list them all. A namespace with tens of thousands of runs makes list calls slow and can make the API server work harder. Retention keeps the number bounded.

You can now name what one event leaves behind and the labels that select it.

## Common pitfalls

> [!WARNING]
> - **Deleting pods or TaskRuns to clean up.** The `PipelineRun` is the object to delete. The rest follows.
> - **Cleaning up by name patterns.** `generateName` gives random suffixes, so a name tells you little. Select by label.
> - **Assuming a run has a trigger label.** Runs created by hand, or by other tools, do not carry the EventListener labels.
