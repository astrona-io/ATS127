# Summary

Each Git provider proves its events in its own way, and the interceptors that ship with Triggers follow that. The Pipeline should not know which provider started it.

## What you learned

GitLab sends the secret token in `X-Gitlab-Token` and the event name in `X-Gitlab-Event`. The `gitlab` interceptor takes a `secretRef` and `eventTypes` such as `Push Hook`. The `bitbucket` interceptor supports a `secretRef` for Bitbucket Server only; Bitbucket Cloud events are filtered by `eventTypes`, such as `repo:push`, without a shared-secret check.

A CEL interceptor after the provider interceptor filters on the branch and writes a short branch name to `extensions`. The binding reads it with `$(extensions.branch)`. The origin check must come first in the chain.

One EventListener can serve several providers with one Trigger per provider. A Trigger whose interceptors stop an event skips only itself. The key facts to remember are these:

- A token is weaker than a signature; protect the transport.
- Bitbucket Cloud has no shared-secret check in the interceptor.
- Order interceptors with the origin check first.
- Use one Secret per provider.

<!-- astrona:playground:destroy -->
