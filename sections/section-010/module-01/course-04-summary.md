# Summary

Tekton Triggers turns an HTTP request into Tekton objects. It is the part of Tekton that decides when a `PipelineRun` starts, so a push to a repository can start a build without anyone typing a command.

## What you learned

Triggers installs on top of Tekton Pipelines, into the same namespace `tekton-pipelines`, from two manifests of the same release. `release.yaml` brings the custom resources, `tekton-triggers-controller` and `tekton-triggers-webhook`. `interceptors.yaml` brings `tekton-triggers-core-interceptors` and the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack`, and it can be applied only after the Triggers webhook answers. `tkn version` shows the Triggers version next to the Pipelines version.

An `EventListener` is the object that receives events. For each one, the Triggers controller creates a Deployment and a `ClusterIP` Service named `el-<name>` on port 8080, labelled `eventlistener=<name>`. The pod reads Triggers objects and creates runs with the ServiceAccount named in the EventListener. That ServiceAccount needs a RoleBinding to `tekton-triggers-eventlistener-roles` and a ClusterRoleBinding to `tekton-triggers-eventlistener-clusterroles`. Without them, the pod cannot fill its caches, never becomes ready, and logs `forbidden` errors.

Each `Trigger` connects a binding to a template. A `TriggerBinding`, or a cluster-wide `ClusterTriggerBinding` referenced with `kind: ClusterTriggerBinding`, reads values with `$(body...)` and `$(header...)`. A `TriggerTemplate` declares parameters and uses them as `$(tt.params...)` in resource templates. Binding and template parameters match by name, and a `PipelineRun` template uses `generateName` so that every event creates a new run.

The EventListener answers `202 Accepted` with an `eventID` before it processes the Triggers. The created objects carry the labels `triggers.tekton.dev/eventlistener`, `triggers.tekton.dev/trigger` and `triggers.tekton.dev/triggers-eventid`, and the EventListener's log tells you why an event created nothing. The key facts to remember are these:

- The EventListener is the object; `el-<name>` is its Deployment and Service.
- The EventListener's ServiceAccount needs both bindings from the Triggers release.
- `202 Accepted` means the request was received, not that a run was created.
- A binding path that does not resolve, without a default, creates nothing and leaves an error in the EventListener's log.

<!-- astrona:playground:destroy -->
