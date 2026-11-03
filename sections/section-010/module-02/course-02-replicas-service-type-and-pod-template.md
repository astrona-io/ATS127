# Replicas, Service Type And Pod Template

One pod, one Service of type `ClusterIP`, no resource limits: that is what an EventListener gets when its `spec` says nothing about it. A node restart then drops events, nothing outside the cluster can reach the Service, and a busy EventListener can use all the memory of its node. The field `resources.kubernetesResource` of the spec changes all three. This part sets replicas, the Service type and the pod template, and checks that the controller applied them.

## What kubernetesResource can set

The field `spec.resources.kubernetesResource` describes the Deployment and the Service in the words of Kubernetes. It has these fields:

- `replicas` is the number of pods. The default is `1`.
- `serviceType` is the type of the Service. The default is `ClusterIP`. `NodePort` and `LoadBalancer` open the Service to clients outside the cluster.
- `servicePort` is the port of the Service. The default is `8080`.
- `spec.template.metadata` sets `labels` and `annotations` on the pod.
- `spec.template.spec` sets `serviceAccountName`, `securityContext`, `nodeSelector`, `tolerations`, `affinity`, `topologySpreadConstraints` and `containers`.

For `containers`, the controller reads only a few fields of the first container: `resources`, `env`, the probes and `securityContext`. You do not name the container or set its image; the controller always runs the EventListener sink image of the installed release.

## Change the EventListener

Run two pods, give the pod a label and ask for memory and CPU limits.

<!-- astrona:playground:renew -->

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
  resources:
    kubernetesResource:
      replicas: 2
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

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

Then check what the controller did:

```sh
kubectl rollout status deployment/el-starfleet-ci -n starfleet
kubectl get deployment el-starfleet-ci -n starfleet
kubectl get pods -n starfleet -l eventlistener=starfleet-ci,team=starfleet
kubectl get deployment el-starfleet-ci -n starfleet -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

The Deployment now has two replicas, both pods carry the label `team=starfleet`, and the container has the requests and limits from the EventListener. The Service routes each new request to one of the two pods.

## Open the Service to the outside

A Service of type `NodePort` opens a port on every node. The playground has no Ingress controller, so this is the simplest way to see the field work. Edit the EventListener with a patch:

```sh
kubectl patch eventlistener starfleet-ci -n starfleet --type merge -p '{"spec":{"resources":{"kubernetesResource":{"serviceType":"NodePort"}}}}'
kubectl get service el-starfleet-ci -n starfleet
```

The `TYPE` column shows `NodePort`, and the `PORT(S)` column shows `8080` followed by the node port that Kubernetes picked and the metrics port `9000`. Patch it back to `ClusterIP` when you are done:

```sh
kubectl patch eventlistener starfleet-ci -n starfleet --type merge -p '{"spec":{"resources":{"kubernetesResource":{"serviceType":"ClusterIP"}}}}'
```

> [!TIP]
> Change the EventListener, then run `kubectl rollout status` on its Deployment. A command that returns before the new pods are ready is the most common reason for a test that fails once and passes on the second try.

## The controller owns the Deployment

Try to scale the Deployment directly:

```sh
kubectl scale deployment el-starfleet-ci -n starfleet --replicas=3
kubectl get deployment el-starfleet-ci -n starfleet
```

The Triggers controller watches the Deployment it created. It sets the replica count back to the value in the EventListener, so after a short time the Deployment shows two replicas again. The EventListener is the source of truth. The same holds for the Service type and for the pod template.

You can now size, label and place the pods of an EventListener and choose how its Service is exposed. Replicas protect against a lost pod, but each pod serves every Trigger of the EventListener. The next question is which Triggers an EventListener should serve in the first place.

## Common pitfalls

> [!WARNING]
> - **Scaling or patching the Deployment.** The controller reverts it. Change `resources.kubernetesResource` in the EventListener.
> - **Naming the container or setting its image.** The controller reads only `resources`, `env`, probes and `securityContext` from the first container. The image comes from the Triggers release.
> - **Setting limits that are too small.** A pod that exceeds its memory limit is killed, and events that arrive during the restart are lost. Check `kubectl get pods` for restarts.
> - **Using `NodePort` or `LoadBalancer` without a signature check.** Anyone who reaches the port can start runs. Add the `github` interceptor with a secret before you open the Service.

## Your mission: Scale And Place An EventListener

You can now set replicas, the Service type and the pod template of an EventListener. The graded lab gives you a plain EventListener and asks you to scale it, label its pods, limit its memory and expose its Service, without breaking the Trigger that starts builds.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-010-02
astrona start ats-127-playground-010-02
```
