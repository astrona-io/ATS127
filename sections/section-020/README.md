# Section 020: Verify And Filter Events With Interceptors

An EventListener without checks creates a `PipelineRun` for every JSON request that reaches its Service. Any pod in the cluster, or anyone who can reach an exposed address, can start builds with any commit ID and any branch. A CI system must accept only events that really come from its Git server, and only the events it cares about: a push to `main`, not a push to every feature branch.

Tekton Triggers does that work with interceptors. An interceptor is a step that runs before the bindings and can reject an event, check it or add data to it. This section first shows how interceptors work: the `ClusterInterceptor` objects, the core interceptors Deployment that serves them, the chain they form, and where a rejected event leaves its trace. Then it verifies GitHub webhooks with a shared secret and an HMAC signature. Last, it filters events and computes new values with CEL expressions.

**Topic covered:** Interceptors

## What you will learn

- What an interceptor is, how the EventListener calls the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack`, and why the response is `202` even when an interceptor rejects the event.
- How GitHub signs a webhook with HMAC-SHA256 in the header `X-Hub-Signature-256`, and how the GitHub interceptor checks it with a Secret through `secretRef`.
- How `eventTypes` filters on the header `X-GitHub-Event`, and how the GitLab and Bitbucket interceptors check their own headers.
- How the CEL interceptor filters events with `filter` and adds values to `extensions` with `overlays`, and how a binding reads them.
- How to chain interceptors, and where to read why an event created nothing.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Verify And Filter Webhooks With Interceptors

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, and an EventListener `starfleet-ci` in `starfleet` that accepts every event, together with its ServiceAccount, binding, template, the Pipeline `ci-build` and the webhook client pod.

1. How Interceptors Work
2. Verify GitHub Webhooks With An HMAC Secret
3. Filter And Enrich Events With CEL, followed by the lab **Repair Signature Checks And A CEL Filter**
4. Summary

## Section capstone: Harden An Open EventListener

The capstone is one graded scenario that combines the whole module. The EventListener of the `starfleet` team accepts every request, signed or not, for every branch. Add a shared secret, a GitHub interceptor that checks signatures and event types, and a CEL interceptor that lets through only pushes to `main` and gives the build the short branch name. Prove it with signed and unsigned events. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-127-capstone-020
```
