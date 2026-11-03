# Register A ClusterInterceptor And Use It

A Service is not an interceptor yet. The `ClusterInterceptor` object gives it a name that a Trigger can use, and tells the Triggers controller how to reach it. Then a Trigger refers to that name like it refers to `github` or `cel`.

## The ClusterInterceptor

The playground has this object:

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

The `clientConfig.service` names the Service, its namespace and its port. A ClusterInterceptor has no namespace of its own, so the namespace of the Service is part of the reference. Without a `caBundle`, the EventListener calls the Service over plain HTTP; this module does that. The controller reads the object and puts the address it will call in `status.address`:

```sh
kubectl get clusterinterceptor branch-check -o yaml
```

## Use it in a Trigger

Save this as `eventlistener-starfleet-ci.yaml`. The custom interceptor is the only interceptor and runs before the binding:

<!-- astrona:playground:renew -->

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
      interceptors:
        - ref:
            name: branch-check
            kind: ClusterInterceptor
      bindings:
        - ref: branch-push
      template:
        ref: ci-build-run
```

The binding reads the extension that the service adds. Save it as `triggerbinding-branch-push.yaml`:

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
kubectl apply -f eventlistener-starfleet-ci.yaml
kubectl rollout status deployment/el-starfleet-ci -n starfleet
```

## Send a branch push and a tag push

A branch push uses the sample payload. For a tag push, change the `ref` of the sample body in the command:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary '{"ref":"refs/tags/v1","repository":{"clone_url":"https://git.example.com/starfleet/bridge.git"},"head_commit":{"id":"4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39"}}' http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet
kubectl logs -n starfleet deploy/branch-check
```

One run exists, with `branch` set to `main`. The log of the service shows both requests. The tag push was stopped by the service, and the response to the client was still `202`.

You can now register a service and call it from a Trigger. Two names must line up: the `ref.name` in the Trigger with the name of the ClusterInterceptor, and the `service.name` in the ClusterInterceptor with the Service. A third must line up too: the extension name the service returns with the one the binding reads.

## Your mission: Repair A Custom Interceptor

You can now run a service, register it, and read its extensions. The graded lab gives you a registered interceptor that nobody can reach and a binding that reads the wrong extension.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-020-03
astrona start ats-127-playground-020-03
```

## Common pitfalls

> [!WARNING]
> - **A `service.name` that does not match the Service.** Every event that uses the interceptor fails.
> - **A binding that reads an extension the service does not return.** The path finds nothing, and the event creates no run.
> - **Forgetting `kind: ClusterInterceptor` in the reference** when a namespaced interceptor of the same name could exist. Name the kind you mean.
