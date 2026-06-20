# AI-assisted coding session handover

Last reviewed at session close: 2026-06-21.

Use this prompt to resume work in a new AI-assisted coding session:

```text
Continue work in the docpunct repository.

Read arch/docpunct_arch.md, HOWTO.md, CODEX_TASK.md, TODO.md, and AIHANDOVER.md.
Inspect git status and the current diff before changing anything. Treat the
existing project documents as authoritative for repository state, constraints,
known issues, testing expectations, and remaining work.

First summarize the current repo state, known issues, and the next recommended
step from TODO.md. Then continue from the existing work without discarding
unrelated working-tree changes.

After completing the requested work, propose concrete next steps based on
TODO.md and ask me what I want to do next.

When I say I am finishing or closing the session, update TODO.md as needed and
update this prompt only if its resume instructions or document list changed.
```
