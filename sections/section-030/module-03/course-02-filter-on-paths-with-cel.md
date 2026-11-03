# Filter On Paths With CEL

The `cel` interceptor takes a `filter` expression that must return `true` for the event to continue. This part writes the filter for "a file under `docs/` changed".

## The building blocks

CEL has macros for lists. `exists(item, condition)` is true when at least one item matches, and `all(item, condition)` is true when every item matches. `has(field)` is true when a field is present, and `startsWith` tests a prefix of a string.

A filter for changed documentation looks at every commit and every list:

```
body.commits.exists(c, c.modified.exists(f, f.startsWith('docs/')))
```

Read it from the inside out. `f.startsWith('docs/')` tests one path. The inner `exists` asks whether any modified path of commit `c` passes. The outer `exists` asks whether any commit passes.

New and deleted documentation counts too. Combine the lists with `||`:

```
body.commits.exists(c,
  c.added.exists(f, f.startsWith('docs/')) ||
  c.modified.exists(f, f.startsWith('docs/')) ||
  c.removed.exists(f, f.startsWith('docs/')))
```

## Use it in a Trigger

The expression goes into the `filter` parameter of the `cel` interceptor, after the `github` interceptor has checked the signature and the event type. Combine it with the branch test, using `&&`:

```yaml
- name: only-docs-on-main
  ref:
    name: cel
  params:
    - name: filter
      value: "body.ref == 'refs/heads/main' && body.commits.exists(c, c.modified.exists(f, f.startsWith('docs/')))"
```

A path prefix needs the trailing slash. `startsWith('docs')` also matches a file named `docs-old.txt` or a directory `docs2/`.

## Test an expression before you use it

The `cel` interceptor reports a failing expression only in its log. Read the log after each test:

<!-- astrona:playground:renew -->

```sh
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=10
```

To test an expression without a cluster, you can evaluate it with a CEL tool against the payload file. In the playground, the quickest test is the Trigger itself: send `push-main-docs.json` and `push-main-src.json` and compare which one creates a run.

## Missing fields

If `body.commits` does not exist, the expression has nothing to read and the interceptor stops the event with an error, which you see in the log of the core interceptors. That is the right result for a payload that is not a push with commits. If you want the filter to be explicit, test for the field first:

```
has(body.commits) && body.commits.exists(c, c.modified.exists(f, f.startsWith('docs/')))
```

You can now write a path filter that covers new, changed and deleted files and know why the trailing slash matters.

## Common pitfalls

> [!WARNING]
> - **A prefix without the slash.** `startsWith('docs')` matches more than the directory.
> - **A typo in the path.** `doc/` and `docs/` are different, and the filter silently matches nothing.
> - **Checking only `modified`.** A new documentation file is in `added`.
> - **Putting the filter before the signature check.** Verify the sender first, then evaluate the body.
