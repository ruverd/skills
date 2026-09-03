# Node: resume

**Verb:** reconcile and continue. No product code.

Follow [../ARGS.md](../ARGS.md).

1. Load developer STATE, delivery STATE, HANDOFF, bus stack.
2. Reconcile git branch / PR / files on disk.
3. If `waiting_user`: treat the current user message as the ASK answer. Log it. Clear waiting. Continue the node that asked.
4. Skip nodes whose outputs already exist and match STATE.
5. Hand off to **deliver**, **mergeable**, **bot_review**, **apply_qa**, or **fix** as STATE says.

Missing STATE → stop. Ask for the ticket or the goal. Do not start a blank job.
