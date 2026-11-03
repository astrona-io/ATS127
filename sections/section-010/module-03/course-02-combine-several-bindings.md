# Combine Several Bindings

One binding with every parameter works for one Pipeline. With three Pipelines and ten repositories, the same four lines (repository, revision, branch, event) repeat in every binding, and a fix has to be made in all of them. Tekton Triggers lets a Trigger list several bindings and merge their parameters. This part splits one binding into three sources, a `ClusterTriggerBinding`, a `TriggerBinding` and an inline binding, and shows how the Trigger finds each one.

## The three sources

A Trigger lists its bindings under `bindings`. Each item is one of these:

- A reference to a `TriggerBinding` in the namespace of the Trigger: `ref: <name>`.
- A reference to a `ClusterTriggerBinding`, which has no namespace and can be shared by every namespace: `ref: <name>` with `kind: ClusterTriggerBinding`. Without `kind`, the reference means a `TriggerBinding`.
- An inline binding, written directly in the Trigger as `name` and `value`.

The EventListener pod evaluates all of them against the same event and gives the template one merged list of parameters. The template takes the parameters it declares by name.

## Split the debug binding

Split the six parameters of the last part. The `ClusterTriggerBinding` holds what every GitHub Trigger needs. Save this as `clustertriggerbinding-github-common.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: ClusterTriggerBinding
metadata:
  name: github-common
spec:
  params:
    - name: repo
      value: $(body.repository.full_name)
    - name: event
      value: $(header.X-GitHub-Event)
```

Apply it:

```sh
kubectl apply -f clustertriggerbinding-github-common.yaml
```

The `TriggerBinding` holds what belongs to push events. Save this as `triggerbinding-push-commits.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: push-commits
  namespace: starfleet
spec:
  params:
    - name: first-commit
      value: $(body.commits[0].id)
    - name: second-commit
      value: $(body.commits[1].id)
```

Apply it:

```sh
kubectl apply -f triggerbinding-push-commits.yaml
```

## Use all three in one Trigger

The parameters `commits` and `missing` stay in the Trigger itself as inline bindings. Save this as `eventlistener-starfleet-debug.yaml`. It replaces the EventListener of the last part:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-debug
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: show-values
      bindings:
        - ref: github-common
          kind: ClusterTriggerBinding
        - ref: push-commits
        - name: commits
          value: $(body.commits)
        - name: missing
          value: $(body.nothing.here)
      template:
        ref: show-values
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-debug.yaml
kubectl rollout status deployment/el-starfleet-debug -n starfleet
```

Send the same body as before and read the log of the `TaskRun`:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary '{"ref":"refs/heads/main","repository":{"full_name":"starfleet/bridge"},"commits":[{"id":"a1b2c3","modified":["src/main.go"]},{"id":"d4e5f6","modified":["docs/index.md"]}]}' http://el-starfleet-debug.starfleet.svc.cluster.local:8080
tkn taskrun logs --last -n starfleet
```

The log has the same six values as in the last part. Three different objects supplied them, and the template saw one list.

## What each source is for

Use the three sources for different jobs:

| Source | Where it lives | Use it for |
| --- | --- | --- |
| `ClusterTriggerBinding` | Cluster-wide | Values every team reads the same way, such as the repository name and the event type |
| `TriggerBinding` | One namespace | Values that belong to one kind of event or one team |
| Inline binding | Inside the Trigger | A single value that only this Trigger needs |

A `ClusterTriggerBinding` has no namespace, so the EventListener's ServiceAccount needs the right to read cluster-scoped objects. The ClusterRole `tekton-triggers-eventlistener-clusterroles`, bound with a ClusterRoleBinding, gives it that right. Without that binding, a Trigger that refers to a `ClusterTriggerBinding` fails.

You can now merge parameters from three sources and know where each one belongs. All the values so far went into a `TaskRun` that only prints them. The next part creates two objects from one event, and meets the permission that the second one needs.

## Common pitfalls

> [!WARNING]
> - **Forgetting `kind: ClusterTriggerBinding`.** The reference then means a `TriggerBinding` of that name in the namespace, which does not exist, and the Trigger fails.
> - **Defining the same parameter name in two bindings of one Trigger.** Give every name one source, so the value is never ambiguous.
> - **A template parameter that no binding provides.** Without a default, the value stays a literal `$(tt.params.<name>)` or the Trigger fails. Give optional parameters a `default`.
> - **Editing a `ClusterTriggerBinding` that other teams use.** A changed path changes every Trigger that refers to it.
