# Solution: Clean Up Old Runs

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the old-build runs and their TaskRuns are gone; `release-1` is kept; the ServiceAccount `run-cleaner` has the rights on `pipelineruns` and nothing else; and the CronJob is defined as required.

## Step 1: List, then delete the old builds

```sh
kubectl get pipelineruns -n starfleet --show-labels
kubectl get pipelineruns -n starfleet -l purpose=old-build
```

Three runs match. Delete them with the same selector:

```sh
kubectl delete pipelineruns -n starfleet -l purpose=old-build
kubectl get pipelineruns,taskruns -n starfleet
```

`release-1` remains. The TaskRuns and pods of the deleted runs are removed by garbage collection, which can take a moment.

## Step 2: Create the ServiceAccount, the Role and the RoleBinding

Save this as `run-cleaner-rbac.yaml`:

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

```sh
kubectl apply -f run-cleaner-rbac.yaml
kubectl auth can-i delete pipelineruns -n starfleet --as=system:serviceaccount:starfleet:run-cleaner
kubectl auth can-i delete pods -n starfleet --as=system:serviceaccount:starfleet:run-cleaner
```

The first answers `yes`, the second `no`. A Role is namespaced, so the account has no rights in other namespaces.

## Step 3: Create the CronJob

Save this as `cronjob-cleanup-old-runs.yaml`:

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

```sh
kubectl apply -f cronjob-cleanup-old-runs.yaml
kubectl get cronjob -n starfleet
```

The selector `purpose!=release` matches every run that is not a release, including runs without the label. Test the job once by hand if the image is available in your cluster:

```sh
kubectl create job cleanup-test --from=cronjob/cleanup-old-runs -n starfleet
kubectl logs -n starfleet job/cleanup-test
kubectl delete job cleanup-test -n starfleet
```

## Step 4: Check

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

All four checks pass.

## Common mistakes

| Mistake | Effect |
| --- | --- |
| Deleting with `--all` | `release-1` is gone and the release check fails |
| A ClusterRole for the account | The account can delete runs in other namespaces and the RBAC check fails |
| A Role with `pods` in the resources | The account can delete pods and the RBAC check fails |
| No history limits on the CronJob | The CronJob check fails, and finished Jobs would collect in the namespace |
