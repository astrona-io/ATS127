# Solution: Repair A Custom Interceptor

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the ClusterInterceptor points at an existing Service with a ready pod; a push to `main` starts a run with `branch` set to `main`; and a push to a tag starts nothing.

## Step 1: Check each layer

```sh
kubectl get clusterinterceptor branch-check -o yaml
kubectl get deployment,service,endpoints -n starfleet -l app=branch-check
kubectl get service -n starfleet
```

The ClusterInterceptor names a Service `branch-checker`. The Service in the namespace is `branch-check`. Send a push and read the log of the EventListener:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
tkn eventlistener logs starfleet-ci -n starfleet -t 20
kubectl logs -n starfleet deploy/branch-check
```

The log of the service has no request line, because nothing reaches it.

## Step 2: Repair the ClusterInterceptor

Save this as `clusterinterceptor-branch-check.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1alpha1
kind: ClusterInterceptor
metadata:
  name: branch-check
spec:
  clientConfig:
    service:
      name: branch-check
      namespace: starfleet
      port: 80
```

```sh
kubectl apply -f clusterinterceptor-branch-check.yaml
```

Send the push again. The log of the service now has a request line, but the run still does not appear: the log of the EventListener says that the path `extensions.branch` found nothing.

## Step 3: Repair the binding

The service returns `short_branch`. Save the binding with that name as `triggerbinding-branch-push.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: branch-push
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.head_commit.id)
    - name: branch
      value: $(extensions.short_branch)
```

```sh
kubectl apply -f triggerbinding-branch-push.yaml
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet
```

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Rename the Service to `branch-checker` | The Service is not allowed to change, and the grader reads the ClusterInterceptor |
| Remove the interceptor from the Trigger | Tag pushes then start runs, and the extension is gone |
| Change the service code to return `branch` | The ConfigMap is not allowed to change |

## Common mistakes

- Repairing the ClusterInterceptor and stopping when the log of the service shows requests.
- Changing the binding to read `$(body.ref)`. The branch would be `refs/heads/main`.

## Practice on your own

- Break the port in the ClusterInterceptor and compare the symptom with the wrong name.
- Change the rule in the ConfigMap to stop pushes to `main` and restart the Deployment.
