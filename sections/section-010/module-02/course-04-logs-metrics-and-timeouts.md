# Logs, Metrics And Timeouts

A running EventListener has three sources of information: the log of its pod, the metrics it publishes, and the settings of the controller that created it. Each answers a different question. The log tells you what happened to one event. The metrics tell you how many events arrived. The settings tell you why a slow request was cut. This part reads all three in the playground.

## Read the log of the EventListener pod

The EventListener pod writes one log line for each step of an event. Send an event first, then read the log:

<!-- astrona:playground:renew -->

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=20
```

The selector `-l eventlistener=starfleet-ci` reads every pod of the EventListener. With two replicas, add `--prefix` to see which pod wrote each line, because the Service sends each request to one of them. The `tkn` command-line tool reads the same log by name:

```sh
tkn eventlistener logs starfleet-ci -n starfleet -t 20
```

Every line that belongs to an event carries its event ID, the same value as the `eventID` in the response. A value that cannot be read from the payload produces the line `failed to replace JSONPath value for param ...`.

## Change the log level

The log level of the Triggers components comes from the ConfigMap `config-logging-triggers` in `tekton-pipelines`. Read it to see its keys and values:

```sh
kubectl get configmap config-logging-triggers -n tekton-pipelines -o yaml
```

The ConfigMap holds a Zap logger configuration and one level setting per component. Edit a level there when you need more detail, and set it back afterwards, because debug logs include request details.

## Read the metrics

The EventListener Service has a second port, `9000`, for metrics. The pod serves them in Prometheus format at `/metrics`. Read the first lines from the client pod:

```sh
kubectl get service el-starfleet-ci -n starfleet -o jsonpath='{range .spec.ports[*]}{.name}={.port}{"\n"}{end}'
kubectl exec -n starfleet deploy/webhook-client -- curl -sS http://el-starfleet-ci.starfleet.svc.cluster.local:9000/metrics | head -n 10
```

A Prometheus server scrapes this address on a schedule. The ConfigMap `config-observability-triggers` controls what the Triggers components publish.

## Timeouts of the HTTP server

An EventListener answers every accepted request with `202` after it has read the body. Four timeouts of its HTTP server come from the arguments of the Deployment `tekton-triggers-controller`. Print them:

```sh
kubectl get deployment tekton-triggers-controller -n tekton-pipelines -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

The defaults of the Triggers release are `-el-readtimeout` 5 seconds, `-el-writetimeout` 40 seconds, `-el-idletimeout` 120 seconds and `-el-timeouthandler` 30 seconds. They apply to every EventListener that the controller creates, so a change needs an edit of the controller Deployment. A client that sends a large body slowly, or that keeps a connection open without data, meets these limits.

## Payload validation

The EventListener checks that the body of a request is JSON and answers `400` when it is not. The annotation `tekton.dev/payload-validation: "false"` on the EventListener turns this check off, for senders that post a body in another format. Leave it on unless you have a reason, because bindings and CEL expressions read JSON.

You can now find the log of an EventListener, its metrics and the timeouts of its server. The module summary ties the four parts together: the spec and the status, the pod template, the selectors, and the places to look when an event is lost.

## Common pitfalls

> [!WARNING]
> - **Reading the log of one pod when the EventListener has several.** Use the label selector, or add `--prefix`, so you see every replica.
> - **Looking for interceptor errors in the EventListener log.** The core interceptors write their answers to their own log in `tekton-pipelines`.
> - **Leaving a debug log level on.** Debug logs can include request data. Set the level back when you are done.
> - **Changing the timeout flags without a reason.** A slow sender is better fixed at the sender; longer timeouts keep connections and memory busy.
