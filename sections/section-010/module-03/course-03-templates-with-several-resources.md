# Templates With Several Resources

A build rarely stands alone. A team wants a record of which event started which run: a `ConfigMap` with the commit, the author and the event type, next to the `PipelineRun`. A `TriggerTemplate` can list several resource templates, and the EventListener creates all of them for each event. But the EventListener creates them with its own ServiceAccount, and the Triggers release only allows it to create runs. This part adds a second resource to a template, watches it fail for lack of permission, and fixes the RBAC with the smallest rule that works.

## Add a ConfigMap to the template

The template of this part creates the `PipelineRun` first and a `ConfigMap` second. Both use `generateName`, so every event creates new objects. The binding from the first part, `github-push-detail`, supplies the values. The Trigger needs a `pusher` as well, so first save this as `triggerbinding-github-push-record.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-push-record
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

Apply it:

```sh
kubectl apply -f triggerbinding-github-push-record.yaml
```

Then save this as `triggertemplate-ci-build-record.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: ci-build-record
  namespace: starfleet
spec:
  params:
    - name: repo-url
    - name: revision
    - name: branch
    - name: pusher
    - name: event
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: ci-build-run-
      spec:
        pipelineRef:
          name: ci-build
        params:
          - name: repo-url
            value: $(tt.params.repo-url)
          - name: revision
            value: $(tt.params.revision)
          - name: branch
            value: $(tt.params.branch)
    - apiVersion: v1
      kind: ConfigMap
      metadata:
        generateName: event-record-
      data:
        revision: $(tt.params.revision)
        pusher: $(tt.params.pusher)
        event: $(tt.params.event)
```

Apply it:

```sh
kubectl apply -f triggertemplate-ci-build-record.yaml
```

Point the EventListener `starfleet-ci` at the new binding and template. Save this as `eventlistener-starfleet-ci.yaml`:

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
        - ref: github-push-record
      template:
        ref: ci-build-record
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
kubectl rollout status deployment/el-starfleet-ci -n starfleet
```

## Send an event and read what is missing

Send the sample push from the client pod and list both kinds of object by the label of the EventListener:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns,configmaps -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci
tkn eventlistener logs starfleet-ci -n starfleet -t 20
```

The `PipelineRun` exists, but no `ConfigMap` has the label. The log of the EventListener has a line that says the ServiceAccount `starfleet-triggers` cannot create `configmaps`. The release's ClusterRole lets the EventListener create `pipelineruns` and `taskruns` and nothing else. The response was still `202`, because the EventListener answers before it creates anything.

## Grant exactly one right

Give the ServiceAccount the right to create `configmaps` in this namespace, and nothing more. Save this as `role-starfleet-triggers-configmaps.yaml`:

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

Apply it and check the right with `kubectl auth can-i`, which asks the API server on behalf of the ServiceAccount:

```sh
kubectl apply -f role-starfleet-triggers-configmaps.yaml
kubectl auth can-i create configmaps -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
```

The answer is `yes`. Send the same push again and list the objects of the newest event:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns,configmaps -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci
```

Now each event leaves a `PipelineRun` and a `ConfigMap`. Both carry the label `triggers.tekton.dev/triggers-eventid` with the same event ID, so you can pair them. The `ConfigMap` holds `revision`, `pusher` and `event`.

You can now create several kinds of object from one event and grant only the right each kind needs. Each extra resource kind in a template needs its own rule in the RBAC, or the EventListener silently fails to create it.

## Common pitfalls

> [!WARNING]
> - **Granting `*` on `*` to fix a forbidden error.** The EventListener then creates anything in the namespace for any request. Add one verb on one resource.
> - **Reading only the response.** A `202` does not say that every resource was created. Check the objects and the EventListener log.
> - **A fixed `name` in a resource template.** The second event fails because the name exists. Use `generateName`.
> - **Putting a cluster-scoped resource in a template.** A Role in a namespace cannot allow it; it needs a ClusterRole and a ClusterRoleBinding.

## Your mission: Repair A Multi-Resource Template

You can now read values with JSONPath, combine bindings, and give an EventListener exactly the right it needs for each resource. The graded lab gives you a Trigger that starts nothing, because a binding reads a field the payload does not have, and a second resource that the EventListener may not create. You repair both without widening the rights.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-010-03
astrona start ats-127-playground-010-03
```
