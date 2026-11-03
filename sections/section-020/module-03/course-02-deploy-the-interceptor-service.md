# Deploy The Interceptor Service

The playground runs the service from the last part. This part reads how it is built, so you can build your own. It has three objects: a ConfigMap with the code, a Deployment that runs it, and a Service in front.

## The code

The service has one handler. It parses the request, reads `ref` from the event body, and decides:

```python
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

PREFIX = "refs/heads/"


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        request = json.loads(self.rfile.read(length) or b"{}")
        body = json.loads(request.get("body") or "{}")
        ref = body.get("ref", "")
        if ref.startswith(PREFIX):
            response = {"continue": True, "extensions": {"short_branch": ref[len(PREFIX):]}}
        else:
            response = {"continue": False, "status": {"code": 9, "message": "only pushes to a branch are built"}}
        data = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


HTTPServer(("", 8080), Handler).serve_forever()
```

Notice two things. The rule uses the prefix and cuts it off, so a branch such as `feature/shields` keeps its slash. And the service answers every request with `200`, whether it continues or not.

## The objects

The ConfigMap `branch-check-code` holds the script as `server.py`. The Deployment runs the image `python:3.12-alpine` with the command `python /app/server.py` and mounts the ConfigMap at `/app`. The Service `branch-check` exposes port `80` and sends it to container port `8080`. Read them:

<!-- astrona:playground:renew -->

```sh
kubectl get configmap branch-check-code -n starfleet -o yaml
kubectl get deployment,service,pods -n starfleet -l app=branch-check
kubectl logs -n starfleet deploy/branch-check
```

The log of the service shows the two requests from the last part, one line each.

## Change the rule

Edit the script in the ConfigMap, then restart the Deployment, because a pod reads the mounted file at start:

```sh
kubectl edit configmap branch-check-code -n starfleet
kubectl rollout restart deployment/branch-check -n starfleet
kubectl rollout status deployment/branch-check -n starfleet
```

During the restart the Service answers from the old pod until the new one is ready, because the readiness probe checks the port.

## Keep it small

An interceptor sits in the path of every event. A slow or failing service delays or stops every build that uses it. Keep the work short, do not call external systems without a timeout, and run more than one replica when the builds matter.

You can now run an interceptor service. The next part tells the EventListener where it is.

## Common pitfalls

> [!WARNING]
> - **No readiness probe.** The Service then sends events to a pod that is not listening yet.
> - **Editing the ConfigMap and not restarting.** The running pod keeps the old code.
> - **Pulling a large image or installing packages at start.** The pod takes long to be ready, and events fail meanwhile.
