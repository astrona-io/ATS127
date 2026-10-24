# Section 010: Tekton Triggers Architecture And RBAC

Tekton Pipelines runs a Pipeline only when someone creates a `PipelineRun`. A continuous integration (CI) system has to do that by itself: a developer pushes a commit, the Git server sends a webhook, and a build starts. Tekton Triggers is the Tekton project that turns such an HTTP request into Tekton objects. Before you can verify or filter events, you need to know which Triggers objects take part, which pod receives the request, and which permissions that pod needs to create a run.

This section builds that chain step by step. You first install Tekton Triggers on top of Tekton Pipelines and look at what the release adds to the cluster. Then you create an `EventListener` with its own ServiceAccount and the RBAC (role-based access control) that the Triggers release prepares for it, and you see what happens when a binding is missing. Last, you write a `TriggerBinding` and a `TriggerTemplate`, send a push event from a pod inside the cluster, and watch a `PipelineRun` appear with the values from the event.

**Topic covered:** Triggers architecture

## What you will learn

- What Tekton Triggers adds to Tekton Pipelines, and how to install `release.yaml` and `interceptors.yaml` in the right order.
- The Triggers resources: `EventListener`, `Trigger`, `TriggerBinding`, `ClusterTriggerBinding`, `TriggerTemplate`, and the `ClusterInterceptor` objects of the release.
- How the Triggers controller turns an `EventListener` into a Deployment and a Service named `el-<name>`, and how to reach that Service from inside the cluster.
- Why the EventListener needs a ServiceAccount bound to `tekton-triggers-eventlistener-roles` and `tekton-triggers-eventlistener-clusterroles`, and how a missing binding shows up.
- How a `TriggerBinding` reads values from `$(body...)` and `$(header...)`, and how a `TriggerTemplate` uses them as `$(tt.params...)` in a `PipelineRun` with `generateName`.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Turn A Webhook Into A PipelineRun

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, the `tkn` command-line tool, the Pipeline `ci-build` and a webhook client pod in the namespace `starfleet`.

1. Install Tekton Triggers And Meet Its Resources
2. The EventListener, Its ServiceAccount And RBAC
3. TriggerBindings, TriggerTemplates And tt.params, followed by the lab **Create An EventListener For Push Events**
4. Summary

## Section capstone: Repair An EventListener That Starts No Runs

The capstone is one graded scenario that combines the whole module. The `starfleet` team has an EventListener for push events, but no push has started a build yet. Its pod never becomes ready, its Trigger points at a binding of the wrong kind, and the binding reads a field the payload does not have. Find each fault from the EventListener's status and logs, fix it, and prove the fix with a push event that starts a `PipelineRun`. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-127-capstone-010
```
