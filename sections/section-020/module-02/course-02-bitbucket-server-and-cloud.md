# Bitbucket Server And Bitbucket Cloud

Bitbucket comes in two products, and the `bitbucket` interceptor treats them differently. Bitbucket Server (also called Data Center) can use a shared secret to prove the origin of a webhook. Bitbucket Cloud cannot be checked with a shared secret by this interceptor. Knowing which one a team uses decides which checks the Trigger can have.

## Bitbucket Server

For Bitbucket Server, the interceptor supports both `secretRef` and `eventTypes`. Server event keys look like `repo:refs_changed`. A Trigger for it:

<!-- astrona:playground:renew -->

```yaml
triggers:
  - name: bitbucket-server-push
    interceptors:
      - ref:
          name: bitbucket
        params:
          - name: secretRef
            value:
              secretName: bitbucket-server-secret
              secretKey: secretToken
          - name: eventTypes
            value:
              - repo:refs_changed
    bindings:
      - ref: bitbucket-push
    template:
      ref: ci-build-run
```

The Secret `bitbucket-server-secret` does not exist in the playground. Create it yourself and read how the EventListener behaves while it is missing:

```sh
kubectl create secret generic bitbucket-server-secret -n starfleet --from-literal=secretToken=lab-only-bitbucket-token
```

## Bitbucket Cloud

For Bitbucket Cloud, the interceptor supports `eventTypes` only. Cloud event keys look like `repo:push`. A Trigger for it has no `secretRef`:

```yaml
interceptors:
  - ref:
      name: bitbucket
    params:
      - name: eventTypes
        value:
          - repo:push
```

Without a secret, anyone who can reach the EventListener can send a valid-looking event. Reduce that risk outside the interceptor: keep the Service inside the cluster behind an Ingress that allows only the source addresses that Bitbucket publishes, or add a CEL filter that checks fields only a real repository has. A filter on a field is a weak check, not proof of origin.

## Compare the three providers

| Provider | Origin check | Event type header value |
| --- | --- | --- |
| GitHub | HMAC signature in `X-Hub-Signature-256` | `push`, `pull_request` |
| GitLab | Token in `X-Gitlab-Token` | `Push Hook`, `Merge Request Hook` |
| Bitbucket Server | `secretRef` | `repo:refs_changed` |
| Bitbucket Cloud | None in the interceptor | `repo:push` |

You can now choose the checks that fit each Bitbucket product and say what remains unchecked on Cloud. The next part leaves the providers' differences behind and turns their payloads into the same parameters.

## Common pitfalls

> [!WARNING]
> - **A `secretRef` on a Cloud Trigger.** Cloud does not support the shared-secret check; use `eventTypes` and other protection.
> - **Treating a filter on a field as authentication.** A sender can write any field.
> - **Server event keys on a Cloud webhook.** `repo:refs_changed` and `repo:push` are different events; use the one the product sends.
