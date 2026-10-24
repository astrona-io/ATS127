# The EventListener, Its ServiceAccount And RBAC

An `EventListener` looks like a small object: a name, a ServiceAccount and a list of Triggers. Behind it, the Triggers controller starts a pod that talks to the Kubernetes API all the time. That pod reads Triggers objects, and it creates PipelineRuns. It does both with the ServiceAccount you name in the EventListener, so the permissions of that ServiceAccount decide whether events turn into runs. This part creates an EventListener, shows what goes wrong without permissions, and fixes it with the RBAC (role-based access control) that the Triggers release prepares.

## Create an EventListener without permissions

Start with the ServiceAccount alone. A ServiceAccount is the identity that a pod uses when it calls the Kubernetes API.

<!-- astrona:playground:renew -->

Save this as `serviceaccount-starfleet-triggers.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: starfleet-triggers
  namespace: starfleet
```

Apply it:

```sh
kubectl apply -f serviceaccount-starfleet-triggers.yaml
```

Now create the EventListener `starfleet-ci`. It has one inline Trigger named `github-push`, which uses the TriggerBinding `github-push` and the TriggerTemplate `ci-build-run`. Those two objects do not exist yet; the Triggers webhook does not check that, and the EventListener reads them only when an event arrives.

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

Then check the result:

```sh
kubectl get eventlistener starfleet-ci -n starfleet
kubectl get deployment,service,pods -n starfleet -l eventlistener=starfleet-ci
```

The Triggers controller created a Deployment and a Service, both named `el-starfleet-ci`, and labelled them `eventlistener=starfleet-ci`. The Service has the type `ClusterIP` and the port `8080`, so it is reachable only from inside the cluster. The pod starts, but it never becomes ready: the `READY` column stays at `0/1`, and the EventListener's `AVAILABLE` column does not turn `True`.

## Read why the pod is not ready

The EventListener pod runs Tekton's `eventlistenersink` program. Before it opens its HTTP server, it starts informers, local caches that list and watch EventListeners, Triggers, TriggerBindings, TriggerTemplates, ClusterTriggerBindings and ClusterInterceptors. Its readiness probe calls `/live` on port 8080, and that path answers only after the caches are filled.

Read the pod's log:

```sh
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=20
```

The log repeats errors that say the ServiceAccount `system:serviceaccount:starfleet:starfleet-triggers` is forbidden to list resources in the API group `triggers.tekton.dev`. The informers cannot fill their caches, so the HTTP server never starts, and the probes fail. Kubernetes may also restart the container when the liveness probe on the same path fails.

You can ask the API server the same question directly. `kubectl auth can-i` with `--as` checks a permission for another identity:

```sh
kubectl auth can-i list eventlisteners.triggers.tekton.dev -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
kubectl auth can-i create pipelineruns.tekton.dev -n starfleet --as=system:serviceaccount:starfleet:starfleet-triggers
```

Both answers are `no`.

## Bind the roles from the Triggers release

The Triggers release ships two ClusterRoles for EventListeners. A ClusterRole is a set of permissions; a RoleBinding grants it in one namespace, and a ClusterRoleBinding grants it in the whole cluster.

| ClusterRole | Bind it with | What it allows |
| --- | --- | --- |
| `tekton-triggers-eventlistener-roles` | A RoleBinding in the EventListener's namespace | Read EventListeners, Triggers, TriggerBindings, TriggerTemplates, Interceptors and ConfigMaps; `create` PipelineRuns and TaskRuns; `impersonate` ServiceAccounts; create Events |
| `tekton-triggers-eventlistener-clusterroles` | A ClusterRoleBinding | Read ClusterTriggerBindings, ClusterInterceptors and Secrets |

The EventListener needs both: the namespaced objects and the run creation come from the first, the cluster-scoped objects from the second.

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

Apply both:

```sh
kubectl apply -f rolebinding-starfleet-triggers-eventlistener.yaml -f clusterrolebinding-starfleet-triggers-eventlistener.yaml
```

The pod retries its lists by itself, but that can take a while. Deleting the pod makes the Deployment start a fresh one at once. Then wait for the EventListener's `Ready` condition, which follows the `Available` condition of its Deployment:

```sh
kubectl delete pod -n starfleet -l eventlistener=starfleet-ci
kubectl wait --for=condition=Ready eventlistener/starfleet-ci -n starfleet --timeout=180s
```

The EventListener is now ready, and both `kubectl auth can-i` questions from before answer `yes`.

## Send the first request

The Service `el-starfleet-ci` is reachable only inside the cluster, so send requests from the `webhook-client` pod in `starfleet`. Its full address is `http://el-starfleet-ci.starfleet.svc.cluster.local:8080`. Send an empty JSON object and print the response headers with `-i`:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -i -X POST -H 'Content-Type: application/json' --data-binary '{}' http://el-starfleet-ci.starfleet.svc.cluster.local:8080
```

The EventListener answers with HTTP status `202 Accepted` and a JSON body with the fields `eventListener`, `namespace`, `eventListenerUID` and `eventID`. Now look for a PipelineRun:

```sh
kubectl get pipelineruns -n starfleet
```

There is none. The EventListener sends the `202` as soon as it has read the request and selected its Triggers; it processes the Triggers after that. Here the TriggerBinding and the TriggerTemplate do not exist, so processing failed, and only the EventListener's log says so. **A `202` means "received", never "a run was created".**

You can now create an EventListener, find its Deployment, Service and pod, and give its ServiceAccount the two bindings it needs. Its pod receives events, but it has nothing to create yet. The open question is how the values of an event reach the parameters of a `PipelineRun`.

## Common pitfalls

> [!WARNING]
> - **No RoleBinding or ClusterRoleBinding.** The EventListener pod never becomes ready, and its log says `forbidden`. Bind both ClusterRoles from the release.
> - **Binding only one of the two ClusterRoles.** The namespaced objects and the cluster-scoped objects need different bindings. With one missing, the pod still cannot fill its caches.
> - **Fixing RBAC with `cluster-admin`.** It works, but anyone who can reach the Service can then make the EventListener create anything. Bind the two roles that the release ships.
> - **Reading `202 Accepted` as success.** The EventListener answers before it runs the Triggers. Check for the PipelineRun and read the EventListener's log.
> - **Calling the EventListener from your machine.** The Service is `ClusterIP`. Send requests from a pod in the cluster, or use `kubectl port-forward` for a quick test.
