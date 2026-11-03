# Secure And Troubleshoot A Custom Interceptor

A custom interceptor decides which events start builds, so it is part of the security of the pipeline. It is also a network service, with network service failures. This part covers transport security and how to find a failure quickly.

## Transport security

Over plain HTTP, anyone who can reach the Service can send it requests, and the EventListener cannot tell a real Service from an impostor. For production, serve the interceptor over HTTPS with a certificate, and put the certificate authority in the `caBundle` field of the ClusterInterceptor. The EventListener then calls the Service over HTTPS and checks its certificate against that bundle.

Also limit who can call the Service. A NetworkPolicy that allows ingress to the interceptor pod only from the EventListener pods keeps other pods out. And limit who can edit the ConfigMap and the ClusterInterceptor, because whoever can edit them controls which events are built.

## Fail closed

If the service is down, the EventListener cannot get an answer, and the event is dropped. That is the safe direction: no answer means no build. Do not design the service so that an error in your own code answers `continue: true`.

## Find the failure

| Symptom | Where to look | Likely cause |
| --- | --- | --- |
| No run for any event, `202` returned | `tkn eventlistener logs`, then the log of the service | The EventListener cannot reach the Service |
| The log of the service has no request lines | `kubectl get endpoints branch-check -n starfleet` | The Service name or port in the ClusterInterceptor is wrong, or no pod is ready |
| Run created, `branch` empty or the event creates no run after the interceptor passes | The EventListener log | The binding reads an extension the service does not return |
| Only tag pushes create nothing | The log of the service | The service stopped them, as designed |
| The interceptor is not found | `kubectl get clusterinterceptor` | The `ref.name` is misspelled |

Read the status of the ClusterInterceptor and the endpoints directly:

```sh
kubectl get clusterinterceptor branch-check -o yaml
kubectl get endpoints branch-check -n starfleet
```

## Test the service without Tekton

Because the contract is plain HTTP, you can call the Service with `curl`, as in the first part of this module. If it answers correctly by hand, the fault is in the registration or in the Trigger, not in the code.

You can now secure a custom interceptor in principle and find its failures by layer: the service, the registration, the Trigger, the binding.

## Common pitfalls

> [!WARNING]
> - **Leaving the interceptor on plain HTTP in production.** Use a certificate and `caBundle`.
> - **An interceptor that fails open.** A bug must stop events, not pass them.
> - **No resource requests and a single replica.** One slow request then delays every event.
