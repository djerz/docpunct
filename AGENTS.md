# AI agent instructions for docpunct

This file is the first document an AI coding assistant should read when
working in this repository. It replaces the older `AIHANDOVER.md` resume
prompt.

## Start every session

1. Run `git status --short` and inspect the current diff before changing
   anything.
2. Read `TODO.md` for current state, known issues, verified tests, and
   remaining work.
3. Read only the additional documents needed for the requested task:
   - General architecture or feature model: `arch/docpunct_arch.md`
   - User-facing feature behavior: `HOWTO.md`
   - Epel/mail work: `arch/epel_arch.md` and `features/epel/HOWTO.md`
   - GPG, pass, or Git Credential Manager work: `features/gpg/HOWTO.md`
   - Original bootstrap task context: `CODEX_TASK.md`
4. Do not start a TODO item until the user explicitly confirms which item to
   work on.

For low-cost resume summaries, prefer `TODO.md` plus this file over rereading
all architecture and HOWTO documents. Open the longer docs only when they are
relevant to the change.

## Repository rules

- Treat `arch/docpunct_arch.md`, feature HOWTOs, `HOWTO.md`, `TODO.md`, and
  this file as authoritative.
- Continue from the existing working tree. Never discard unrelated changes.
- Do not commit secrets, private keys, tokens, mail contents, credentials, or
  machine-specific private data.
- Keep the project KISS: Bash, plain text state, human-readable feature
  scripts, and explicit behavior.
- Every `just` target must have an equivalent `./bin/docpunct` command.
- Feature scripts, when present, use fixed names: `install.sh`, `update.sh`,
  `remove.sh`, and optional `relink.sh`.
- `feature.yml` files must not contain a `name` property.
- Removal must be conservative and must not delete unrelated user data.
- Before removing APT packages, check for shared desktop/system dependencies
  and avoid removal that could cascade into Ubuntu desktop packages.
- Features that invoke Cargo or Rust tools must source `$HOME/.cargo/env`
  themselves before calling those tools.
- Do not run destructive install/remove operations against the user's real
  environment without explicit confirmation.

## Testing expectations

Run tests appropriate to the completed change:

- Shell script changes: `./bin/docpunct shellcheck` or direct host
  `shellcheck` when Docker socket access is unavailable.
- Core behavior changes: `./bin/docpunct test` or at least
  `./bin/docpunct test-smoke`.
- Package/container behavior changes: the matching `test-container`,
  `test-containers`, `test-docker-feature`, or feature-specific lifecycle
  target.
- Documentation-only changes: `git diff --check` is usually sufficient.

Container tests may pull images and run APT/network work inside disposable
containers when needed.

## Session close

When the user says they are finishing or closing the session:

1. Update `TODO.md` with completed work, verification, known blockers, and the
   next recommended step.
2. Update this file only if startup instructions, authoritative document
   routing, or testing expectations changed.
