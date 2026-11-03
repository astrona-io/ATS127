# Delete Runs By Label And By Age

With the labels from the last part you can select runs precisely. This part shows the commands for deleting by label, by count and by age, and the habit that keeps them safe: list first, delete second.

## Delete by label with kubectl

A label selector works on `kubectl get` and on `kubectl delete` in the same way. Always run the `get` first, with the exact selector, and read the list:

```sh
kubectl get pipelineruns -n starfleet -l purpose=old-build
```

Three runs match. When the list is what you expect, delete with the same selector:

<!-- astrona:playground:renew -->

```sh
kubectl delete pipelineruns -n starfleet -l purpose=old-build
```

The `TaskRun` objects and the pods of those runs go away with them. The run `release-1` is still there, because its label has another value:

```sh
kubectl get pipelineruns,taskruns,pods -n starfleet
```

The selector can also be a negation or a set. `-l 'purpose!=release'` selects every run that is not a release, including runs with no `purpose` label at all, and `-l 'purpose in (old-build,nightly)'` selects two values. Quote them, because the shell treats `!` and parentheses specially.

> [!NOTE]
> A selector that matches nothing is not an error for `kubectl delete`; it reports that no resources were found. A selector that matches too much is only caught by the `get` you ran before.

## Delete by count and age with tkn

`kubectl` has no option for "keep the newest five" or "older than a day". The `tkn` command-line tool has both:

```sh
tkn pipelinerun delete --pipeline ci-build --keep 3 -n starfleet
tkn pipelinerun delete --pipeline ci-build --keep-since 1440 -n starfleet
```

The first deletes the runs of the Pipeline `ci-build` except the three newest. The second keeps the runs created within the last 1440 minutes, which is one day, and deletes the older ones. `tkn` asks for confirmation before it deletes; the option `-f` skips the question, which a script needs. The flags can differ between `tkn` releases, so read `tkn pipelinerun delete --help` for the version you run. This course uses 0.46.2.

Because `tkn` selects by Pipeline name, it does not treat a build and a release of the same Pipeline differently. If both use `ci-build`, a `--keep` rule can delete a release run that you wanted to keep. That is the reason to put a label on the run and select with it.

## Age without tkn

You can list runs by age with `kubectl`, which sorts by a field:

```sh
kubectl get pipelineruns -n starfleet --sort-by=.metadata.creationTimestamp
```

Deleting by age with `kubectl` alone needs a script that reads `creationTimestamp` and compares it with a cutoff. Such a script needs a shell and a tool like `jq` in the container that runs it. When you can use only `kubectl`, label-based rules are the simple option: a run is removed because of what it is, not how old it is.

## A safe habit

Treat deletion as two steps for every selector, by hand or in a job:

1. Run the same command with `get` and read the list.
2. Run it with `delete`.

For `tkn`, the confirmation prompt is step one. For a CronJob, there is no second look, so the selector must be narrow and tested by hand first. The next part builds that job.

## Common pitfalls

> [!WARNING]
> - **Deleting without listing first.** A missing quote or a wrong label value deletes the wrong runs.
> - **Using `--keep` on a Pipeline that builds and releases.** Count-based rules do not know which runs matter.
> - **Expecting `kubectl delete` to wait.** The command returns when the objects are marked for deletion. Pods can take a short time to disappear.
