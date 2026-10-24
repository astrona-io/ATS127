# Solution: Create An EventListener For Push Events

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the EventListener `starfleet-ci` uses `starfleet-triggers` and is ready; `starfleet-triggers` is bound to the two Triggers ClusterRoles and has no broader rights; and a push event with a new commit ID creates a `PipelineRun` of `ci-build` with the event's values, which succeeds.

## Step 1: Look at what exists

```sh
kubectl get pipelines,triggertemplates,eventlisteners -n starfleet
kubectl get triggertemplate ci-build-run -n starfleet -o jsonpath='{.spec.params[*].name}{"\n"}'
```

The Pipeline `ci-build` and the TriggerTemplate `ci-build-run` exist; there is no EventListener. The template expects the parameters `repo-url`, `revision` and `branch`, so the binding must set exactly these names.

## Step 2: Create the ServiceAccount and its bindings

Create these first, so the EventListener pod can read the Triggers objects as soon as it starts.

Save this as `serviceaccount-starfleet-triggers.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: starfleet-triggers
  namespace: starfleet
```

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

Save this as `clusterrolebinding-starfleet-triggers-eventlistener.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: starfleet-triggers-eventlistener
subjects:
  - kind: ServiceAccount
    name: starfleet-triggers
    namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-triggers-eventlistener-clusterroles
```

Apply them:

```sh
kubectl apply -f serviceaccount-starfleet-triggers.yaml -f rolebinding-starfleet-triggers-eventlistener.yaml -f clusterrolebinding-starfleet-triggers-eventlistener.yaml
```

Then check the result:

```sh
kubectl auth can-i create pipelineruns.tekton.dev -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
kubectl auth can-i list clustertriggerbindings.triggers.tekton.dev --as=system:serviceaccount:starfleet:starfleet-triggers
kubectl auth can-i delete pods -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
```

The first two answer `yes`, the third `no`.

## Step 3: Create the TriggerBinding

Save this as `triggerbinding-github-push.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-push
  namespace: starfleet
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
kubectl apply -f triggerbinding-github-push.yaml
```

## Step 4: Create the EventListener

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
      template:
        ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

Then check the result. The Triggers controller creates the Deployment `el-starfleet-ci` a moment after the EventListener; if `kubectl wait` says it found nothing, run it again:

```sh
kubectl wait --for=condition=Ready eventlistener/starfleet-ci -n starfleet --timeout=180s
kubectl get service el-starfleet-ci -n starfleet
```

The EventListener is ready, and the Service `el-starfleet-ci` lists the port `8080`.

## Step 5: Send a push event

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
```

The EventListener answers `202` with an `eventID`. Then check the run:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/trigger=github-push
tkn pipelinerun describe --last -n starfleet
```

The new `ci-build-run-` run has `revision` = `4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`, `branch` = `refs/heads/main` and `repo-url` = `https://git.example.com/starfleet/bridge.git`, and it succeeds with the result `summary` = `built refs/heads/main at 4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`. If no run appears, read the EventListener's log with `kubectl logs -n starfleet -l eventlistener=starfleet-ci`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind `starfleet-triggers` to `cluster-admin` or `edit` | The EventListener works, but anyone who can reach the Service can make it create anything. The grader rejects the broad rights |
| Bind only `tekton-triggers-eventlistener-roles` | The pod cannot read ClusterTriggerBindings and ClusterInterceptors, so it never becomes ready |
| Put fixed values in the binding | The run for `push-main.json` looks right, but the grader's push has another commit ID |
| Name the binding parameter `gitrevision` | The template parameter `revision` stays empty, and the run gets the literal text `$(tt.params.revision)` |
| Give the `PipelineRun` in a template a fixed `name` | Only the first event creates a run |

## Common mistakes

- Creating the EventListener before the bindings. The pod is not ready until its caches fill; deleting the pod with `kubectl delete pod -n starfleet -l eventlistener=starfleet-ci` starts a fresh one at once.
- Reading the `202` response as proof. Check for the `PipelineRun`.
- Forgetting `Content-Type: application/json` and sending the body as a form.

## Practice on your own

- Send `/payloads/push-feature.json` and compare the `branch` parameter of the new run.
- Remove the ClusterRoleBinding, delete the EventListener pod, and read the new pod's log.
- Add a second Trigger to the EventListener with an inline binding `branch` = `release` after the `github-push` reference, and count the runs one event creates.
