# Automate Cleanup With A CronJob

A manual cleanup happens when someone remembers it. A CronJob does it on a schedule. The job needs to call the Kubernetes API, so it needs a ServiceAccount, and that ServiceAccount should be allowed to delete runs and nothing else.

## The ServiceAccount and its Role

The cleanup deletes `PipelineRun` objects only. `kubectl delete` with a selector lists the objects and then deletes each one, so the Role needs `get`, `list` and `delete` on `pipelineruns`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: run-cleaner
  namespace: starfleet
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: run-cleaner
  namespace: starfleet
rules:
  - apiGroups: ["tekton.dev"]
    resources: ["pipelineruns"]
    verbs: ["get", "list", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: run-cleaner
  namespace: starfleet
subjects:
  - kind: ServiceAccount
    name: run-cleaner
    namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: run-cleaner
```

There is no rule for pods or TaskRuns. Garbage collection removes those, and it runs in the cluster, not as the ServiceAccount. Check what the account can and cannot do with `kubectl auth can-i`:

```sh
kubectl auth can-i delete pipelineruns -n starfleet --as=system:serviceaccount:starfleet:run-cleaner
kubectl auth can-i delete pods -n starfleet --as=system:serviceaccount:starfleet:run-cleaner
```

The first answers `yes` once the Role and the RoleBinding exist. The second answers `no`.

## The CronJob

The CronJob runs `kubectl` with the label selector from the last part. The container image must contain `kubectl`; the Kubernetes project publishes one as `registry.k8s.io/kubectl`. Pin a version tag that matches your cluster, and check that the tag exists before you use it.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cleanup-old-runs
  namespace: starfleet
spec:
  schedule: "0 3 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: run-cleaner
          restartPolicy: Never
          containers:
            - name: cleanup
              image: registry.k8s.io/kubectl:v1.34.0
              command: ["kubectl"]
              args:
                - delete
                - pipelineruns
                - -n
                - starfleet
                - -l
                - purpose!=release
```

Read the pieces:

| Field | Why |
| --- | --- |
| `schedule` | Standard cron syntax, in the time zone of the controller. This one runs at 03:00 every day |
| `concurrencyPolicy: Forbid` | A new job does not start while the last is still running |
| `successfulJobsHistoryLimit`, `failedJobsHistoryLimit` | The CronJob also leaves Jobs behind. These limits keep it from becoming the next thing to clean up |
| `serviceAccountName` | The account with the Role above |
| `args` | The selector keeps every run labelled `purpose=release` and deletes the rest |

Test the CronJob without waiting for the schedule. Create a Job from it and read the log:

```sh
kubectl create job cleanup-test --from=cronjob/cleanup-old-runs -n starfleet
kubectl logs -n starfleet job/cleanup-test
```

When the Job fails with `forbidden`, the Role or the RoleBinding is wrong. When it deletes nothing, the selector matches nothing. Delete the test Job when you are done.

## Your mission: Clean Up Old Runs

You can now delete runs by label and schedule the deletion. The graded lab gives you a namespace with old runs that need to go and no cleanup job.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-030-02
astrona start ats-127-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **Giving the cleanup account a ClusterRole with `delete` on everything.** A bug in the selector then deletes more than runs.
> - **A selector that also matches runs you keep.** Test it with `get` before the CronJob uses it.
> - **A CronJob in the wrong namespace.** The Role is namespaced, so the job and the runs must be in the same namespace.
> - **No history limits.** Old Jobs and their pods collect in the namespace.
