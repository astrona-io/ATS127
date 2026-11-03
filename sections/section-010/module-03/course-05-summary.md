# Summary

A binding copies values out of an event and a template substitutes them into objects. Neither of them checks or computes anything.

## What you learned

A `TriggerBinding` parameter reads an event with `$(body.<path>)` and `$(header.<name>)`. A path can reach a nested field, an array item such as `commits[0]`, or a whole object or array, which arrives as a JSON string. The way to see what a Trigger produced is a debug template that creates a `TaskRun` printing every parameter.

A Trigger can list a `TriggerBinding`, a `ClusterTriggerBinding` (with `kind: ClusterTriggerBinding`) and inline `name` and `value` bindings together. The template receives one merged list. A `ClusterTriggerBinding` needs the ClusterRole `tekton-triggers-eventlistener-clusterroles` to be readable.

A `TriggerTemplate` can create several resources from one event. The EventListener creates them with its own ServiceAccount, so each resource kind in a template needs a rule in the RBAC. A `202` response does not prove that the objects were created.

A template sets `timeouts`, `taskRunTemplate.serviceAccountName`, labels and annotations of the run. A `default` on a template parameter covers a parameter that no binding names. `$(uid)` is one unique string per evaluation. Label values have Kubernetes limits that annotation values do not have. The key facts to remember are these:

- Print the values first, then build the template.
- Each extra resource kind needs its own RBAC rule.
- A default does not replace a path that finds nothing.
- Branch names belong in annotations, not labels.

<!-- astrona:playground:destroy -->
