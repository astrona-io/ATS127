# Summary

A push payload lists the files of each commit, and a Trigger can use that list to decide whether an event is its business. Several Triggers on one EventListener turn one event into several runs.

## What you learned

The `commits` array has `added`, `modified` and `removed` lists of paths per commit. A CEL filter reads them with `exists` and `startsWith`, and a path prefix needs a trailing slash. The EventListener runs every Trigger it selects, so one push can create a `ci-build` run and a `docs-check` run, both with the same event ID and different `triggers.tekton.dev/trigger` labels. A Trigger without the selector label never runs.

The opposite rule, build unless only docs changed, negates the path test inside `exists`. Payloads without `commits`, with an empty list or with a merge commit need a test of their own. The key facts to remember are these:

- Look at every commit and every list, not only `head_commit`.
- Write `startsWith('docs/')` with the slash.
- A new Trigger needs the label the EventListener selects on.
- Test each filter with a payload that must pass and one that must stop.

<!-- astrona:playground:destroy -->
