# task-complete-final-answer

- id: `task-complete-final-answer`
- trigger: `final_answer_block`
- intent: prevent ending a turn before calling `task_complete`
- source: recovered from VS Code local chat session state (2026-04-02)

## Hook Message

```text
You were about to complete but a hook blocked you with the following message: "You have not yet marked the task as complete using the task_complete tool. You must call task_complete when done - whether the task involved code changes, answering a question, or any other interaction.

Do NOT repeat or restate your previous response. Pick up where you left off.

If you were planning, stop planning and start implementing. You are not done until you have fully completed the task.

IMPORTANT: Do NOT call task_complete if:
- You have open questions or ambiguities - make good decisions and keep working
- You encountered an error - try to resolve it or find an alternative approach
- There are remaining steps - complete them first

When you ARE done, first provide a brief text summary of what was accomplished, then call task_complete. Both the summary message and the tool call are required.

Keep working autonomously until the task is truly finished, then call task_complete.". Please address this requirement before completing.
```
