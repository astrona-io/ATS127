# Verify GitHub Webhooks With An HMAC Secret

A check on the header `X-GitHub-Event` stops honest mistakes, but not a client that lies. To trust an event, the EventListener needs proof that the body came from the Git server and was not changed on the way. GitHub gives that proof with a signature computed from a secret that only GitHub and your cluster know. This part stores that secret, signs payloads the way GitHub does, and lets the `github` interceptor check every signature.

## How GitHub signs a webhook

When you add a webhook to a GitHub repository, you can set a secret, a random string. For every delivery, GitHub computes an HMAC over the exact bytes of the body. HMAC (hash-based message authentication code) is a hash computed from a message and a secret key; here the hash function is SHA-256. GitHub sends the result in hex in a header:

```text
X-Hub-Signature-256: sha256=<64 hex digits>
```

The receiver computes the same HMAC over the body it got, with its copy of the secret, and compares the two values. If one byte of the body changed, or if the sender did not know the secret, the values differ. The signature proves two things at once: who sent the body, and that the body is unchanged. It does not hide the body; anyone on the path can still read it.

## Store the secret in a Secret

The `github` interceptor reads the shared secret from a Kubernetes Secret in the namespace of the Trigger. In a real setup you generate a long random value and paste the same value into the GitHub webhook settings. The playground uses a fixed value that is only for this lab.

<!-- astrona:playground:renew -->

Save this as `secret-github-webhook-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-webhook-secret
  namespace: starfleet
type: Opaque
stringData:
  secretToken: lab-only-webhook-secret
```

Apply it:

```sh
kubectl apply -f secret-github-webhook-secret.yaml
```

The EventListener pod does not read this Secret. The `github` interceptor runs in the pod of `tekton-triggers-core-interceptors`, and that pod reads the Secret with its own ServiceAccount, which the Triggers release allows to read Secrets in every namespace.

## Reference the secret from the interceptor

The parameter `secretRef` of the `github` interceptor names the Secret and the key inside it. Keep `eventTypes` next to it.

Save this as `eventlistener-starfleet-ci.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-ci
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: github-push
      interceptors:
        - name: verify-github-push
          ref:
            name: github
          params:
            - name: secretRef
              value:
                secretName: github-webhook-secret
                secretKey: secretToken
            - name: eventTypes
              value: ["push"]
      bindings:
        - ref: github-push
      template:
        ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

With `secretRef` set, the interceptor works in this order: it checks the event type, then it requires the header `X-Hub-Signature-256`, reads the Secret, and compares the signature with its own HMAC of the body. Only the SHA-256 header counts; the older `X-Hub-Signature` with SHA-1 is not read. Without `secretRef`, the interceptor skips the signature check completely.

## Sign and send a payload

Do the signing where GitHub would: outside the EventListener, in the `webhook-client` pod. Open a shell in it; the next commands run inside that shell:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Set the secret and the address, compute the signature of the push payload with `openssl`, and send the payload with the signature. `openssl dgst -sha256 -hmac` prints the HMAC as the last field of its output, and `awk '{print $NF}'` keeps only that field:

```sh
WEBHOOK_SECRET='lab-only-webhook-secret'
EL_URL='http://el-starfleet-ci.starfleet.svc.cluster.local:8080'
SIGNATURE="$(openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" /payloads/push-main.json | awk '{print $NF}')"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' -H "X-Hub-Signature-256: sha256=$SIGNATURE" --data-binary @/payloads/push-main.json "$EL_URL"
```

Both `openssl` and `curl` use the same file, so the signed bytes and the sent bytes are the same. That is also why `--data-binary` matters: plain `-d` would strip the line breaks from the file, and the body would no longer match the signature.

Now send the same payload twice more: once without a signature, and once signed with a wrong secret. Then leave the pod's shell:

```sh
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json "$EL_URL"
WRONG_SIGNATURE="$(openssl dgst -sha256 -hmac 'not-the-secret' /payloads/push-main.json | awk '{print $NF}')"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' -H "X-Hub-Signature-256: sha256=$WRONG_SIGNATURE" --data-binary @/payloads/push-main.json "$EL_URL"
exit
```

All three requests got `202`. Back on your machine, count the runs and read the core interceptors' log:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci --sort-by=.metadata.creationTimestamp
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=6
```

Only one new run appeared, from the signed request. In the log, the unsigned request has the message `no X-Hub-Signature-256 header set`, and the one with the wrong secret has `payload signature check failed`. A Secret or key that does not exist would show `error getting secret` instead.

## GitLab and Bitbucket

The other Git interceptors follow the same pattern with their own headers. The `gitlab` interceptor reads the event type from `X-Gitlab-Event` (values such as `Push Hook`) and compares the header `X-Gitlab-Token` with the Secret as a plain token; GitLab sends the token itself, not a signature. The `bitbucket` interceptor reads the event type from `X-Event-Key` (values such as `repo:refs_changed` for Bitbucket Server or `repo:push` for Bitbucket Cloud). For Bitbucket Server it checks an HMAC signature in `X-Hub-Signature`; Bitbucket Cloud sends no signature, so the interceptor can only filter event types. All three take the same `secretRef` and `eventTypes` parameters.

You can now store a webhook secret, reference it from the `github` interceptor, sign a body with HMAC-SHA256, and tell from the log why a request created nothing. Every signed push now starts a build, whichever branch it came from. The open question is how to choose events by their content, such as the branch, and how to give the build cleaner values than the full ref.

## Common pitfalls

> [!WARNING]
> - **A `secretKey` that is not in the Secret.** The interceptor stops every event with `error getting secret`. Compare `kubectl get secret github-webhook-secret -n starfleet -o jsonpath='{.data}'` with the key name.
> - **The Secret in the wrong namespace.** The interceptor reads it from the Trigger's namespace, here `starfleet`.
> - **Signing one body and sending another.** Pretty-printing, `curl -d` or an added newline changes the bytes, and the check fails. Sign the exact bytes you send.
> - **Sending `X-Hub-Signature` only.** The `github` interceptor reads `X-Hub-Signature-256`.
> - **Forgetting `Content-Type: application/json`.** The `github` interceptor refuses form-encoded bodies, which is what `curl -d` sends by default.
> - **Treating the signature as encryption.** It proves the sender and the content; the body itself is readable. Expose an EventListener only over HTTPS.
