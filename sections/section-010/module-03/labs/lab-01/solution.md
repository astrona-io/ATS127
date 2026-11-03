# Solution: Repair A Multi-Resource Template

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a push creates a `PipelineRun` with the commit ID, the clone URL and the ref of the event; the same push creates a `ConfigMap` with the three keys; and the ServiceAccount can create `configmaps` and nothing broader.

## Step 1: Send a push and look

Send the sample push and list what it created:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns,configmaps -n starfleet
tkn eventlistener logs starfleet-ci -n starfleet -t 20
```

The response is `202`, but nothing was created. The log of the EventListener says that it could not read a value for the parameter `revision`.

## Step 2: Repair the binding

Read the binding and compare each path with the payload:

```sh
kubectl get triggerbinding github-push -n starfleet -o yaml
kubectl get configmap webhook-payloads -n starfleet -o jsonpath='{.data.push-main\.json}'
```

The binding reads `$(body.head.id)`. A push event has no `head`; the commit is `head_commit.id`. Save the binding with the right path as `triggerbinding-github-push.yaml`:

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
    - name: pusher
      value: $(body.pusher.name)
    - name: event
      value: $(header.X-GitHub-Event)
```

Apply it and send the push again:

```sh
kubectl apply -f triggerbinding-github-push.yaml
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns,configmaps -n starfleet
```

The `PipelineRun` exists now, but there is still no `ConfigMap`.

## Step 3: Grant one right

Read the log again. It says that the ServiceAccount `starfleet-triggers` cannot create `configmaps`. Check it directly:

```sh
kubectl auth can-i create configmaps -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
```

Save a Role with one verb on one resource and bind it to the ServiceAccount, as `role-starfleet-triggers-configmaps.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: starfleet-triggers-configmaps
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: starfleet-triggers-configmaps
  namespace: starfleet
subjects:
  - kind: ServiceAccount
    name: starfleet-triggers
    namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: starfleet-triggers-configmaps
```

Apply it, send the push once more and check both objects:

```sh
kubectl apply -f role-starfleet-triggers-configmaps.yaml
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns,configmaps -n starfleet
kubectl get configmaps -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci -o yaml
```

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind `starfleet-triggers` to `cluster-admin` | The ConfigMap appears, but the grader finds that the ServiceAccount can create secrets |
| Remove the ConfigMap from the template | The template is not allowed to change |
| Remove the `revision` parameter | The `PipelineRun` is invalid without a revision, and the template is not allowed to change |

## Common mistakes

- Fixing the binding and stopping when the `PipelineRun` appears. The `ConfigMap` is checked too.
- Using `verbs: ["*"]`. The right to delete `configmaps` fails the third check.
- Creating the Role in another namespace. The ServiceAccount creates objects in `starfleet`.

## Practice on your own

- Add `labels` with `$(uid)` to both resources and compare the label across them.
- Remove `pusher` from the binding and read the error in the log.
