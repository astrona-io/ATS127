# Summary

Interceptors decide which events may become runs. Without them, an EventListener creates a `PipelineRun` from any JSON request, with whatever values the sender chose.

## What you learned

An interceptor runs before the bindings of a Trigger. The EventListener pod calls the interceptors of a Trigger in list order, and each one answers continue or stop. A stop ends that Trigger; a continue can add data under `extensions`, which later interceptors and the binding read as `$(extensions.<key>)`. The body itself never changes. The Triggers release ships the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack`, all served over HTTPS by the Deployment `tekton-triggers-core-interceptors` in `tekton-pipelines`. You can add your own as a `ClusterInterceptor` or a namespaced `Interceptor`.

The EventListener answers `202 Accepted` before the interceptors run, so a rejected event leaves no trace in the response. The core interceptors log each answer at the info level, in lines that start with `Interceptor response is:`, and that log holds the reason: `event type ... is not allowed`, `no X-Hub-Signature-256 header set`, `payload signature check failed`, `error getting secret`, or `expression ... did not return true`.

GitHub signs each webhook with an HMAC-SHA256 over the exact body bytes and a shared secret, and sends it as `X-Hub-Signature-256: sha256=<hex>`. The `github` interceptor checks `X-GitHub-Event` against `eventTypes`, and with `secretRef` it reads the secret from a Secret in the Trigger's namespace and compares the signatures. Without `secretRef` it checks nothing but the event type. The `gitlab` interceptor compares a plain token in `X-Gitlab-Token`, and the `bitbucket` interceptor checks `X-Hub-Signature` for Bitbucket Server.

The `cel` interceptor evaluates a `filter` that must return `true`, and `overlays` that store computed values in `extensions`. Expressions see `body`, `header`, `requestURL` and `extensions`, and can use helpers such as `header.match()`, `.split()` and `.truncate()`. The key facts to remember are these:

- Verify first, filter second: the `github` interceptor with `secretRef` goes before the `cel` interceptor.
- `eventTypes` and CEL filters read what the sender wrote; only the signature proves the sender.
- Sign the exact bytes you send, with `Content-Type: application/json`.
- A `202` response says nothing about the interceptors; read the core interceptors' log and look for the run.

<!-- astrona:playground:destroy -->
