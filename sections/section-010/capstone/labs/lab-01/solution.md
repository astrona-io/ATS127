# Solution: Repair An EventListener That Starts No Runs

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the EventListener is ready with its own ServiceAccount; that ServiceAccount has the two Triggers bindings and nothing broader; the Trigger uses the ClusterTriggerBinding `github-push`; and a push event creates a `PipelineRun` of `ci-build` with the event's values, which succeeds.

## Step 1: Read the EventListener and its pod

```sh
kubectl get eventlistener starfleet-ci -n starfleet
kubectl get pods -n starfleet -l eventlistener=starfleet-ci
```

The EventListener is not available, and its pod shows `0/1` ready, maybe with restarts. A pod that never becomes ready usually cannot start its HTTP server. Read its log:

```sh
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=20
```

The log repeats errors that say `system:serviceaccount:starfleet:starfleet-triggers` is forbidden to list resources such as `eventlisteners` and `triggers` in the API group `triggers.tekton.dev` in the namespace `starfleet`. Check which bindings the ServiceAccount has:

```sh
kubectl get rolebindings -n starfleet -o wide
kubectl get clusterrolebindings -o wide | grep starfleet-triggers
```

There is a ClusterRoleBinding to `tekton-triggers-eventlistener-clusterroles`, but no RoleBinding to `tekton-triggers-eventlistener-roles`, which grants the namespaced reads and the `create` on PipelineRuns.

## Step 2: Add the RoleBinding

Save this as `rolebinding-starfleet-triggers-eventlistener.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: starfleet-triggers-eventlistener
  namespace: starfleet
subjects:
  - kind: ServiceAccount
    name: starfleet-triggers
    namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-triggers-eventlistener-roles
```

Apply it:

```sh
kubectl apply -f rolebinding-starfleet-triggers-eventlistener.yaml
```

The pod may be waiting in a restart back-off, so start a fresh one and wait for the EventListener:

```sh
kubectl delete pod -n starfleet -l eventlistener=starfleet-ci
kubectl wait --for=condition=Ready eventlistener/starfleet-ci -n starfleet --timeout=180s
```

## Step 3: Send a push event and read the log

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=10
```

The response is `202`, but no `PipelineRun` appears. The log has an error for the Trigger `github-push`: the EventListener cannot find a `triggerbinding` named `github-push`. Compare with what exists:

```sh
kubectl get triggerbindings -n starfleet
kubectl get clustertriggerbindings
```

There is no namespaced `TriggerBinding`, only the `ClusterTriggerBinding` `github-push`. A binding reference without `kind` means `TriggerBinding`, so the reference needs `kind: ClusterTriggerBinding`.

## Step 4: Name the binding kind

Save this as `eventlistener-starfleet-ci.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-ci
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: github-push
      bindings:
        - ref: github-push
          kind: ClusterTriggerBinding
      template:
        ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

Send the push event again and read the log:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=10
```

Still no run. This time the log says `failed to replace JSONPath value for param revision` with the path `$(body.head_commit.sha)`. The payload has `head_commit.id`, not `head_commit.sha`, and the template parameter `revision` has no default, so the EventListener creates nothing.

## Step 5: Fix the path in the ClusterTriggerBinding

Save this as `clustertriggerbinding-github-push.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: ClusterTriggerBinding
metadata:
  name: github-push
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.head_commit.id)
    - name: branch
      value: $(body.ref)
```

Apply it:

```sh
kubectl apply -f clustertriggerbinding-github-push.yaml
```

## Step 6: Prove it with a push

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
tkn pipelinerun describe --last -n starfleet
```

A new `ci-build-run-` run appears with `revision` = `4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`, `branch` = `refs/heads/main` and `repo-url` = `https://git.example.com/starfleet/bridge.git`, and it succeeds.

## Step 7: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind `starfleet-triggers` to `cluster-admin` or `edit` | The pod becomes ready, but the ServiceAccount can do far more than an EventListener needs. The grader rejects it |
| Create a namespaced `TriggerBinding` named `github-push` | The reference then works without `kind`, but the team keeps two copies of the push fields. The constraints forbid it |
| Give the template parameter `revision` a default | The run starts, but every build gets the default instead of the commit ID |
| Put the commit ID of `push-main.json` into the binding | The grader's push has another commit ID |

## Common mistakes

- Waiting for the old pod after the RoleBinding is added. It may sit in a restart back-off for minutes; delete it.
- Stopping at the `202` response. The EventListener answers before it processes the Trigger.
- Reading only the newest log line. The error for an event carries the event ID from the response; match them.

## Practice on your own

- Use `$(body.after)` instead of `$(body.head_commit.id)` and compare the runs.
- Add a second, inline binding `- name: branch` with `value: main` after the ClusterTriggerBinding, and check which `branch` value wins.
- Remove the ClusterRoleBinding, delete the pod, and compare the log messages with the ones from Step 1.
