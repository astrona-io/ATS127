# Choose Which Triggers An EventListener Serves

A team that runs CI for ten repositories does not want ten EventListeners with ten Deployments. It wants one EventListener, and Triggers that other people add to it. Tekton Triggers supports this: a `Trigger` can be its own object, and the EventListener selects Triggers by namespace and by label. This part shows the two selectors, creates a standalone Trigger, and explains the RBAC that a selection across namespaces needs.

## Inline Triggers and standalone Triggers

Until now the Trigger `github-push` was written inside the EventListener, under `spec.triggers`. A standalone `Trigger` is its own object with the same fields: `interceptors`, `bindings` and `template`. An EventListener does not list standalone Triggers by name. It selects them with `namespaceSelector` and `labelSelector`.

- `namespaceSelector.matchNames` is a list of namespace names. The value `"*"` means every namespace. Without a `namespaceSelector`, the EventListener looks in its own namespace only.
- `labelSelector` has `matchLabels` and `matchExpressions`, like the selectors of Deployments. Only Triggers whose labels match are served.

If an EventListener has a selector, the controller adds the matching Triggers to the Triggers written inline. A Trigger that no selector matches never runs.

## Create a standalone Trigger and select it

Save this as `trigger-github-push.yaml`. It carries the label `ci: push` that the selector below uses:

<!-- astrona:playground:renew -->

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: Trigger
metadata:
  name: github-push-standalone
  namespace: starfleet
  labels:
    ci: push
spec:
  bindings:
    - ref: github-push
  template:
    ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f trigger-github-push.yaml
```

Now create a second EventListener that serves only Triggers with that label in the namespace `starfleet`. It uses the same ServiceAccount as the first one. Save this as `eventlistener-starfleet-select.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-select
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  namespaceSelector:
    matchNames:
      - starfleet
  labelSelector:
    matchLabels:
      ci: push
```

Apply it and wait for its Deployment:

```sh
kubectl apply -f eventlistener-starfleet-select.yaml
kubectl rollout status deployment/el-starfleet-select -n starfleet
```

Send a push event to the new Service from the client pod. The EventListener has no interceptors, so the event needs no signature:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-select.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-select
```

The response is `202` with an `eventListener` of `starfleet-select`, and one `PipelineRun` exists with the label `triggers.tekton.dev/eventlistener=starfleet-select`. The standalone Trigger started it, and the EventListener contains no Trigger of its own.

## Change the label and watch the Trigger drop out

Remove the label from the Trigger. The EventListener watches Triggers, so it stops serving this one:

```sh
kubectl label trigger github-push-standalone -n starfleet ci-
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-select.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-select
```

The second request still gets `202`, but the list still holds one run. A Trigger that matches no selector fails without any message in the response. Put the label back with `kubectl label trigger github-push-standalone -n starfleet ci=push`.

## RBAC for Triggers in other namespaces

The EventListener pod reads Trigger, TriggerBinding and TriggerTemplate objects through the Kubernetes API with its ServiceAccount. It reads them in every namespace that the selector names. That is why the RBAC matters:

- For its own namespace, a RoleBinding to the ClusterRole `tekton-triggers-eventlistener-roles` is enough.
- For one other namespace, create a RoleBinding to that ClusterRole in that namespace.
- For `"*"`, bind the same ClusterRole with a ClusterRoleBinding, so the rights apply in every namespace.

The ClusterRole `tekton-triggers-eventlistener-clusterroles` stays bound with a ClusterRoleBinding in all cases, because it covers cluster-scoped objects such as `ClusterTriggerBinding`.

> [!TIP]
> A selector across namespaces gives every team that can create a `Trigger` in those namespaces the right to start runs through this EventListener, with its ServiceAccount. Name only the namespaces you trust.

You can now serve Triggers from standalone objects chosen by namespace and by label, and you know which bindings that choice needs. The last part of this module turns to running an EventListener: where it logs, where it publishes metrics and which timeouts apply.

## Common pitfalls

> [!WARNING]
> - **Forgetting the label on the Trigger.** A Trigger without the label never runs, and the response is still `202`.
> - **Selecting another namespace without a RoleBinding there.** The EventListener cannot read the Trigger, and the Trigger never runs.
> - **Using `"*"` to be safe.** It lets any namespace add Triggers that run with this ServiceAccount.
> - **Expecting an inline Trigger and a selector to be exclusive.** Both are served together.
