# The Interceptor Contract

An interceptor is defined by what goes in and what comes out. The EventListener sends one HTTP POST per event, and the service answers with JSON. Learn those two shapes and you can write an interceptor in any language.

## The request

The body of the POST is a JSON object. The fields that matter:

- `body` holds the original event body as a string, not as an object. A service must parse it again.
- `header` holds the HTTP headers of the original event. Each header name maps to a list of values.
- `extensions` holds what earlier interceptors in the chain have added.
- `interceptor_params` holds the `params` of the interceptor in the Trigger.
- `context` holds the IDs of the event, the Trigger and the event type.

For a push event, the `body` value is the push JSON written as one string with escaped quotes.

## The response

The service answers with a JSON object:

- `continue` is `true` to let the event go on, `false` to stop it.
- `status` has a `code` and a `message`. It matters when `continue` is `false`. The code is a gRPC code; `9` is `FAILED_PRECONDITION`, which fits "the event does not meet the rule".
- `extensions` is an object of new values. A binding reads them as `$(extensions.<name>)`.

An answer with `continue: true` and extensions looks like this, in the form the EventListener reads it:

```json
{"continue": true, "extensions": {"short_branch": "main"}}
```

An answer that stops the event:

```json
{"continue": false, "status": {"code": 9, "message": "only pushes to a branch are built"}}
```

## Where it sits in the chain

The custom interceptor is one entry in the `interceptors` list of a Trigger, like `github` or `cel`. It runs in its position, sees the extensions of the interceptors before it, and its extensions are visible to the ones after it and to the bindings.

## Call the service by hand

The playground already runs a service that follows the contract. Send it a request from the client pod. The `body` is a string, so its quotes are escaped:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' --data-binary '{"body":"{\"ref\":\"refs/heads/main\"}","header":{},"extensions":{},"interceptor_params":{},"context":{}}' http://branch-check.starfleet.svc.cluster.local:80/
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' --data-binary '{"body":"{\"ref\":\"refs/tags/v1\"}","header":{},"extensions":{},"interceptor_params":{},"context":{}}' http://branch-check.starfleet.svc.cluster.local:80/
```

The first answer continues with `short_branch` set to `main`. The second stops the event.

You can now describe the contract. Nothing here is Tekton-specific except the field names; the next part runs the service that answered.

## Common pitfalls

> [!WARNING]
> - **Treating `body` as an object.** It is a string. Parse it first.
> - **Header names in one letter case.** Look up headers in a way that ignores case, or use the exact name the sender used.
> - **Answering with a plain HTTP error to stop an event.** Answer `200` with `continue: false` and a status. A server error is a failure of the interceptor, not a decision.
