# GitLab And Bitbucket Interceptors

Not every team uses GitHub. A GitLab project sends a different header, a different secret scheme and a different payload. A Bitbucket Server or Bitbucket Cloud repository differs again. The EventListener does not care: it receives JSON. The interceptors care, because each provider proves where an event came from in its own way, and each names its event types in its own way.

The Triggers release ships a `gitlab` and a `bitbucket` ClusterInterceptor next to `github`. They work like the GitHub interceptor: a `secretRef` to check the origin, and `eventTypes` to accept only some events. What changes is the header they read and the fields of the payload that your bindings and CEL expressions use.

Keep one sentence in mind: **the interceptor proves the origin and the event type, and a CEL interceptor after it shapes the data.** Do not put provider-specific paths into the Pipeline; translate them once, in the Trigger.

The module has four parts. **GitLab Token And Event Types** checks the secret token of a GitLab webhook and accepts only push events. **Bitbucket Server And Bitbucket Cloud** shows what each Bitbucket variant supports. **Normalize Provider Payloads With CEL** turns a GitLab push into the same parameters a GitHub push gives. A graded lab follows it. **Several Providers On One EventListener** serves GitHub and GitLab from one EventListener.

## Learning objectives

After this module you can:

- Check the origin of a GitLab webhook with the `gitlab` interceptor and a Secret, and accept only chosen event types.
- Say which Bitbucket variant supports a shared secret and which does not.
- Chain a provider interceptor and a CEL interceptor, and read the result from `extensions` in a binding.
- Map the fields of a GitLab push event to the parameters of the same Pipeline that GitHub pushes use.
- Serve several providers from one EventListener with one Trigger per provider.

## Before you start

You need the basics of interceptors: an interceptor runs before the bindings, and an event that it stops leaves no run while the response is still `202`. You should know the GitHub interceptor and the CEL interceptor.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1 and Tekton Triggers v0.37.2 with the core interceptors |
| Namespace `starfleet` | The Pipeline `ci-build`, the Deployment `webhook-client` and the EventListener `starfleet-ci` |
| EventListener `starfleet-ci` | One Trigger `github-push` without interceptors, with its ServiceAccount `starfleet-triggers` and the RBAC from the Triggers release |
| Secret `gitlab-webhook-secret` | The GitLab token, key `secretToken` |
| `/payloads/gitlab-push-main.json` | A GitLab push event, in the webhook client pod |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
