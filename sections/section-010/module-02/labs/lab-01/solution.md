# Solution: Scale And Place An EventListener

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the EventListener asks for two replicas, a `NodePort` Service, the pod label and the limits; two pods are ready with that label and those limits; and the Service is a `NodePort` on port `8080` while a push still creates a `PipelineRun`.

## Step 1: Look at the starting state

Read the EventListener and what the controller created from it:

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o yaml
kubectl get deployment,service,pod -n starfleet -l eventlistener=starfleet-ci
```

The `spec` has no `resources` field, so the Deployment has one replica, the Service has the type `ClusterIP` and the container has no limits.

## Step 2: Add resources.kubernetesResource

All four changes belong under `spec.resources.kubernetesResource`: `replicas`, `serviceType` and the pod template in `spec.template`. Save this as `eventlistener-starfleet-ci.yaml`:

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
  resources:
    kubernetesResource:
      replicas: 2
      serviceType: NodePort
      spec:
        template:
          metadata:
            labels:
              team: starfleet
          spec:
            containers:
              - resources:
                  requests:
                    cpu: 50m
                    memory: 64Mi
                  limits:
                    cpu: 200m
                    memory: 128Mi
```

Apply it and wait for the new pods:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
kubectl rollout status deployment/el-starfleet-ci -n starfleet
```

## Step 3: Check the result

Read the Deployment, the pods and the Service:

```sh
kubectl get deployment el-starfleet-ci -n starfleet
kubectl get pods -n starfleet -l eventlistener=starfleet-ci,team=starfleet
kubectl get pods -n starfleet -l eventlistener=starfleet-ci -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].resources.limits}{"\n"}{end}'
kubectl get service el-starfleet-ci -n starfleet
```

Two pods are ready and carry both labels, each with the limits, and the Service has the type `NodePort`. Then send a push event from the client pod and check that the run appears:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet
```

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `kubectl scale deployment el-starfleet-ci --replicas=2` | The controller sets the replica count back to the value in the EventListener. The grader reads the EventListener |
| `kubectl patch service el-starfleet-ci` to `NodePort` | The controller reverts the Service. Set `serviceType` in the EventListener |
| `kubectl label pods ...` | The label disappears when a pod is replaced. Put it in the pod template |
| Replace the Trigger while editing | The push no longer creates a run, and the last check fails |

## Common mistakes

- Putting `replicas` under `spec.template`. It belongs directly under `kubernetesResource`.
- Giving the container a `name` or an `image`. The controller ignores both.
- Forgetting to wait with `kubectl rollout status`, then testing while the old pod still answers.

## Practice on your own

- Add a `nodeSelector` that matches no node and read why the new pods stay `Pending`. Remove it again.
- Set `servicePort` to `8081`, apply it and read the Service. Check which address clients must now use.
