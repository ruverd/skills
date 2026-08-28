# Node: implement (coder subagent)

**Verb:** TDD. Fresh subagent `ruver-fd-coder`. Never the main thread.

Follow [../IMPLEMENTATION.md](../IMPLEMENTATION.md) + [../TDD.md](../TDD.md).

One ticket only. No PR, no merge, no force-push.

UI: reuse DS. No Figma → copy 2–5 recent same-type screens. Record those paths.

Coder does not reopen grill/spec. Different design → `NEEDS_CONTEXT`.

Return:

```text
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
tdd_behaviors: N
red: ...
green: ...
files_changed: [...]
summary: ...
```
