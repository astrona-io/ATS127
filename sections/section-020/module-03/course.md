# Write A Custom ClusterInterceptor

The core interceptors cover signatures, event types and CEL expressions. Some checks need more: a lookup in an internal system, a rule that is easier to write in a real programming language, or a value that CEL cannot compute. For those, Tekton Triggers lets you write your own interceptor as a small web service and register it as a `ClusterInterceptor`.

A custom interceptor is not a plugin that runs inside the EventListener. It is a separate HTTP service. For each event the EventListener sends it a JSON request with the body, the headers and the earlier extensions, and the service answers with a JSON response: continue or stop, and optionally new extensions. The `ClusterInterceptor` object only tells Triggers which Service to call.

Keep one sentence in mind: **the interceptor is a contract of one request and one response over HTTP, and any language that can serve JSON can implement it.** Every event now depends on that service, so it must be small, fast and fail closed.

The module has four parts. **The Interceptor Contract** shows the request and the response. **Deploy The Interceptor Service** runs a small Python service from a ConfigMap. **Register A ClusterInterceptor And Use It** connects the service to a Trigger and reads its extensions in a binding. A graded lab follows it. **Secure And Troubleshoot A Custom Interceptor** covers TLS, the failure modes and the places to look.

## Learning objectives

After this module you can:

- Describe the request and the response that an EventListener and a custom interceptor exchange.
- Run an interceptor as a Deployment and a Service.
- Register it with a `ClusterInterceptor` and call it from a Trigger.
- Read the extensions it returns in a binding, and explain what a stopped event looks like.
- Name the failures of a custom interceptor and where each one shows up.

## Before you start

You need Kubernetes basics (Deployments, Services, ConfigMaps) and the basics of interceptors: an interceptor runs before the bindings, can stop an event, and can add `extensions`. Reading a short Python script helps but is not required.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Namespace `starfleet` | The Pipeline `ci-build`, the Deployment `webhook-client` and the EventListener `starfleet-ci` |
| Deployment and Service `branch-check` | A Python service built from the ConfigMap `branch-check-code` |
| ClusterInterceptor `branch-check` | Registers that Service |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
