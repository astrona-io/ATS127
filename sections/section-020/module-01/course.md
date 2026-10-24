# Verify And Filter Webhooks With Interceptors

The EventListener of the `starfleet` team creates a build for every JSON request that reaches it. A pod in another namespace can send a made-up push with any commit ID, and the cluster runs it. A push to a feature branch starts the same release build as a push to `main`. Both problems have the same fix in Tekton Triggers: interceptors that look at each event before any binding reads it.

An interceptor is a step in a Trigger that runs before the bindings. It gets the event's body and headers, and it answers in one of two ways: continue, maybe with extra data, or stop. The Triggers release ships its interceptors as `ClusterInterceptor` objects, served by the Deployment `tekton-triggers-core-interceptors`. The `github` interceptor checks signatures and event types; the `cel` interceptor filters events and computes new values with expressions.

Keep one sentence in mind: **an interceptor that stops an event leaves no trace in the HTTP response.** The EventListener answers `202 Accepted` either way, so you prove a check works by the runs it does not create and by the logs.

The module has three parts. **How Interceptors Work** explains the chain of interceptors, the `ClusterInterceptor` objects and where a rejected event shows up. **Verify GitHub Webhooks With An HMAC Secret** stores a shared secret in a Secret, signs a payload the way GitHub does, and lets the `github` interceptor check the signature. **Filter And Enrich Events With CEL** lets only pushes to `main` through and gives the build the short branch name. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain how an EventListener calls interceptors, in which order, and how they pass data through `extensions`.
- Name the ClusterInterceptors of the Triggers release and the headers that the GitHub, GitLab and Bitbucket interceptors read.
- Store a webhook secret in a Secret, reference it with `secretRef`, and sign a payload with HMAC-SHA256 the way GitHub does.
- Restrict a Trigger to event types with `eventTypes`.
- Write a CEL `filter` and CEL `overlays`, and read the overlay values in a binding as `$(extensions.<key>)`.
- Find out why an event created nothing from the core interceptors' log.

## Before you start

You need Kubernetes basics (Secrets, Services, `kubectl apply`, `kubectl logs`, `kubectl exec`) and the basics of Tekton Triggers: an `EventListener` receives events through a Service named `el-<name>`, and each `Trigger` uses a `TriggerBinding` to read values and a `TriggerTemplate` to create a `PipelineRun`.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2, including the Deployment `tekton-triggers-core-interceptors` |
| EventListener `starfleet-ci` | In `starfleet`, with the ServiceAccount `starfleet-triggers` and one Trigger `github-push`, and no interceptors |
| TriggerBinding `github-push`, TriggerTemplate `ci-build-run` | Read `repo-url`, `revision` and `branch` from a push and create a `PipelineRun` of `ci-build` |
| Pipeline `ci-build` | Reports the values it received in its result `summary` |
| Deployment `webhook-client` | A pod with `curl` and `openssl` and sample GitHub payloads in `/payloads` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
