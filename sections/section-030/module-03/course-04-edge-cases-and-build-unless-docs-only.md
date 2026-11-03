# Edge Cases And Build Unless Docs Only

The documentation rule starts a check when docs change. The opposite rule is just as common: skip the expensive build when only documentation changed. This part writes it and goes through the payloads that surprise a filter.

## Build unless only docs changed

A build is needed when at least one changed path is outside `docs/`. Say it with a negated test inside `exists`:

```
body.commits.exists(c,
  c.added.exists(f, !f.startsWith('docs/')) ||
  c.modified.exists(f, !f.startsWith('docs/')) ||
  c.removed.exists(f, !f.startsWith('docs/')))
```

The expression is true when any path in any list is outside `docs/`. For a push that only touches `docs/status.md` it is false, so the build Trigger stops the event. This is the same information as the documentation filter seen from the other side, which is why the two Triggers together cover every push.

## The payloads that surprise a filter

| Payload | What a filter sees | Result |
| --- | --- | --- |
| No `commits` field | `body.commits` does not exist | The expression fails and the interceptor stops the event |
| `commits` is an empty list | `exists` has nothing to test | `false`, so the event stops |
| A commit with empty lists | Nothing is added, modified or removed | `false` |
| A merge commit | GitHub can list no files for it | `false`, so a filter on paths can skip a merge |
| More commits than GitHub lists | Some commits are not in the payload | The filter sees only part of the push |

The merge commit row deserves attention. If your workflow merges pull requests with merge commits and a rule depends on paths, test with a payload from your own provider, not only with a handmade one.

## Keep filters readable

A long expression in a YAML string is hard to review. Three habits help:

- Put one condition per line in a block scalar (`|`) and join them with `&&`.
- Keep the path prefix in one place, so a rename of the directory is a one-line change.
- Test each Trigger with at least one payload that must pass and one that must stop.

## Decide where the logic lives

A path rule can live in three places: in the CEL filter of a Trigger, as a path filter in the CI service of the Git provider that sends the webhook, or in the Pipeline as a first task that decides to skip work. The filter in the Trigger is the cheapest, because no `PipelineRun` is created at all. Use the Pipeline option when the decision needs the repository itself, for example a diff against the target branch.

You can now write both directions of a path rule and name the payloads that need a test.

## Common pitfalls

> [!WARNING]
> - **Relying on a path filter for a security gate.** A listing limit or a merge commit can hide files.
> - **A negative rule with no positive twin.** If you skip builds for docs, make sure something checks docs.
> - **Only testing with handmade payloads.** Capture one real event from your Git provider and replay it.
