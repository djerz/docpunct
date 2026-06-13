# Codex task prompt for implementing docpunct

You are working in the `docpunct` Git repository.

Read these documents first:

- `docpunct_v3.md`
- `HOWTO.md`

Implement the project described there.

Goals:

1. Generate the docpunct framework.
2. Implement `bin/docpunct`.
3. Implement the `justfile` convenience commands.
4. Implement all initial features:
   - core
   - dotfiles
   - debian-cli-packages
   - debian-gui-packages
   - git-credential-manager
   - rust
   - node
   - python-uv
   - neovim
   - neovide
5. Import the initial dotfiles located in ../mydotfiles into the dotfiles feature.
   Requirements:
   - Analyze the contents of ../mydotfiles.
   - Reorganize them into the docpunct dotfiles feature structure.
   - Preserve all existing files and content.
   - Replace hardcoded usernames, home directories, and machine-specific paths with portable alternatives when safe to do so.
   - If a file appears machine-specific, private, or ambiguous, stop and ask for clarification before importing it.
   - Do not silently discard, simplify, or rewrite dotfiles.
6. Before modifying imported dotfiles, explain the proposed changes and ask for confirmation when the change is not obviously safe.
   Examples:
   - removing machine-specific settings
   - replacing hardcoded paths
   - changing shell initialization logic
   - changing editor configuration behavior
7. Do not add secrets, keys, passwords, or private data.
8. Ask for clarification when the specification is ambiguous or when an implementation choice could be destructive.
9. Keep the implementation KISS, human-readable, and easy to modify.
10. Make the work resumable across multiple Codex sessions.

Implementation preferences:

- Use Bash for `bin/docpunct` unless there is a strong reason not to.
- Use fixed feature script names: `install.sh`, `update.sh`, `remove.sh`.
- Feature names come from directory names.
- `feature.yml` must not contain a `name` field.
- Scripts must be executable when present.
- State/log/source/backup directories must be under `~/.cache/docpunct`.
- Use conservative removal behavior.
- Do not remove Neovim or Neovide user configuration, cache, or data directories.
- Make commands idempotent according to the specification.
- Create logs only on error.
- Refuse removing a feature if another installed feature depends on it.

Suggested working method:

1. Inspect the current repository.
2. Summarize what already exists.
3. Propose a small implementation plan.
4. Ask clarifying questions only if needed.
5. Implement the framework in small commits or small logical steps.
6. After each step, run simple syntax checks and safe dry-run style checks where possible.
7. Keep a short progress note in `TODO.md` or similar so another session can continue.

Do not run destructive install/remove operations without asking first.
