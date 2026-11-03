# Which Files Did A Push Change

A filter on paths starts with knowing where the paths are in the payload. This part reads the file lists of a GitHub push event and lists what they can and cannot tell you.

## The commits array

A GitHub push event has a `commits` array with one entry per pushed commit. Each entry has three lists of paths, relative to the repository root:

```json
"commits": [
  {
    "id": "5b2d7e1a9c4f8036b1e5d2a7c9f4083e6b1d5a72",
    "message": "Change docs/status.md",
    "added": [],
    "modified": ["docs/status.md"],
    "removed": []
  }
]
```

| List | Contains |
| --- | --- |
| `added` | Files that the commit created |
| `modified` | Files that the commit changed |
| `removed` | Files that the commit deleted |

A renamed file shows up as one removed path and one added path. The event also has `head_commit`, the newest commit, with the same three lists.

## Read the payloads in the playground

The webhook client holds two payloads with file lists. Print the lists with `jq`, which the client pod has:

```sh
kubectl exec -n starfleet deploy/webhook-client -- jq '.commits[] | {added, modified, removed}' /payloads/push-main-docs.json
kubectl exec -n starfleet deploy/webhook-client -- jq '.commits[] | {added, modified, removed}' /payloads/push-main-src.json
```

The first push changes `docs/status.md`, the second `src/bridge.go`. The plain `push-main.json` has no `commits` at all. Check that too:

```sh
kubectl exec -n starfleet deploy/webhook-client -- jq 'has("commits")' /payloads/push-main.json
```

It prints `false`. A filter must expect that field to be absent.

## What the lists do not tell you

- **Limits.** GitHub limits how many commits it lists in a push event, so a very large push can hide files. Check the limit in the GitHub documentation for the event before you rely on a filter for a release gate.
- **Other providers.** GitLab push events have a `commits` array with the same three lists. Bitbucket uses another structure. A filter written for one provider does not work for another.
- **No content.** The lists contain paths only, not what changed in the file.
- **Branch creation.** A push that creates a branch without new commits has an empty `commits` list.

Because the lists are in the body, a CEL expression can read them as `body.commits[...].modified`. The next part writes the expressions.

You can now find the changed paths in a push payload and name what the lists do not cover.

## Common pitfalls

> [!WARNING]
> - **Reading only `head_commit`.** A push of three commits changes files in all three. Look at every commit in `commits`.
> - **Assuming every push has `commits`.** Some payloads have none, and the expression then fails.
> - **Using a filter for provider A on provider B.** The structure differs.
