# Summary

Every accepted event leaves a `PipelineRun`, its `TaskRun` objects and their pods behind, and nothing removes them. A retention rule is a label selector, and it runs by hand or in a CronJob.

## What you learned

The `PipelineRun` is the only object in the chain with no owner, so deleting it removes the rest through garbage collection. The EventListener labels each object with the event ID, the Trigger and the EventListener, and the Pipelines controller adds the Pipeline name.

`kubectl delete pipelineruns -l <selector>` removes runs by label, and `tkn pipelinerun delete --keep` and `--keep-since` remove them by count and by age. A CronJob with a ServiceAccount that has `get`, `list` and `delete` on `pipelineruns` runs the cleanup on a schedule. A label in the TriggerTemplate decides at creation time which runs the rule keeps. The key facts to remember are these:

- List with the selector before you delete with it.
- Delete the `PipelineRun`, not the TaskRuns or pods.
- Give the cleanup account rights on `pipelineruns` only.
- Use a negative selector such as `purpose!=release` so runs without the label are cleaned too.

<!-- astrona:playground:destroy -->
