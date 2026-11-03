# Summary

An EventListener is configured through its own object. The Triggers controller turns that object into a Deployment and a Service named `el-<name>` and keeps them equal to it, so every change goes into the EventListener and never into the Deployment.

## What you learned

The `spec` of an EventListener has a required `serviceAccountName`, inline `triggers`, `triggerGroups`, the selectors `namespaceSelector` and `labelSelector`, `resources` and `cloudEventURI`. Its `status` holds the address that clients use, the generated name `el-<name>` and the conditions `Available` and `Ready`. The label `eventlistener=<name>` finds the Deployment, the Service and the pods.

The field `resources.kubernetesResource` sets `replicas`, `serviceType`, `servicePort` and the pod template: labels, annotations, node selector, tolerations, affinity and, for the first container, resources, environment, probes and security context. The controller reverts any direct change to the Deployment.

Standalone `Trigger` objects are served by an EventListener that selects them by namespace and by label. A selector across namespaces needs a RoleBinding to `tekton-triggers-eventlistener-roles` in every selected namespace, or a ClusterRoleBinding for all of them. A Trigger that matches no selector never runs, and the response is still `202`.

The log of the EventListener pod holds the event ID and the reason a value could not be read. The Service exposes metrics on port `9000`. The controller sets the read, write, idle and handler timeouts of every EventListener. The key facts to remember are these:

- Change the EventListener; the controller owns the Deployment and the Service.
- Read `status` and the label `eventlistener=<name>` before anything else.
- Selectors choose standalone Triggers; the RBAC must follow the selector.
- Interceptor reasons are in the core interceptors' log, not in the EventListener log.

<!-- astrona:playground:destroy -->
