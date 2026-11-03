# Summary

A custom interceptor is an HTTP service that follows a fixed contract. The `ClusterInterceptor` object registers it by name, and a Trigger uses it like a core interceptor.

## What you learned

The EventListener sends a POST with `body` (a string), `header`, `extensions`, `interceptor_params` and `context`. The service answers `200` with `continue`, a `status` for a stop and optional `extensions`. A binding reads the extensions as `$(extensions.<name>)`.

The service runs as a Deployment behind a Service. The `ClusterInterceptor` names that Service in `spec.clientConfig.service`, and a `caBundle` turns on HTTPS. A Trigger lists it as an interceptor with `ref.name`. A stopped event still returns `202`.

Failures fall into layers: the service, the registration, the Trigger and the binding. Tracing by layer finds them fast. The key facts to remember are these:

- Parse `body` as a string.
- Answer stops with `continue: false`, not with an HTTP error.
- Three names must line up: the interceptor name, the Service name and the extension name.
- Use HTTPS and a NetworkPolicy outside a lab, and fail closed.

<!-- astrona:playground:destroy -->
