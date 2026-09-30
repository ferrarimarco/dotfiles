---
name: git-commit
description: >-
  Execute Git commit with conventional commit message analysis, intelligent
  staging, and message generation. Use when user asks to commit, commit changes,
  create a Git commit, or mentions /commit. Supports: (1) Auto-detecting type
  and scope from changes, (2) Generating conventional commit messages from diff,
  (3) Interactive commit with optional type/scope/description overrides, (4)
  Intelligent file staging for logical grouping
license: MIT
metadata:
  source: https://github.com/github/awesome-copilot/blob/main/skills/git-commit/SKILL.md
---

# Git Commit with Conventional Commits

## Overview

Create standardized, semantic Git commits using the Conventional Commits
specification. Analyze the actual diff to determine appropriate type, scope, and
message.

## Conventional Commit Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type       | Purpose                        |
| ---------- | ------------------------------ |
| `feat`     | New feature                    |
| `fix`      | Bugfix                         |
| `docs`     | Documentation only             |
| `style`    | Formatting/style (no logic)    |
| `refactor` | Code refactor (no feature/fix) |
| `perf`     | Performance improvement        |
| `test`     | Add/update tests               |
| `build`    | Build system/dependencies      |
| `ci`       | CI/config changes              |
| `chore`    | Maintenance/misc               |
| `revert`   | Revert commit                  |

## Breaking Changes

```text
# Exclamation mark after type/scope
feat!: remove deprecated endpoint

# BREAKING CHANGE footer
feat: allow config to extend other configs

BREAKING CHANGE: `extends` key behavior changed
```

## Workflow

### 1. Analyze Diff

```bash
# If files are staged, use staged diff
git diff --staged

# If nothing staged, use working tree diff
git diff

# Also check status
git status --porcelain
```

### 2. Stage Files (if needed)

If nothing is staged or you want to group changes differently:

```bash
# Stage specific files
git add path/to/file1 path/to/file2

# Stage by pattern
git add *.test.*
git add src/components/*

# Interactive staging
git add -p
```

Interactive staging needs a terminal. To stage part of a file without one, write
the intended content to the index, or apply a partial patch to it:

```bash
# Stage the content of a prepared copy of the file
git update-index --cacheinfo "100644,$(git hash-object -w <copy>),<path>"

# Stage a patch that contains only the hunks to commit
git apply --cached <patch>
```

When generated output is committed together with its sources, regenerate it for
each commit so that every commit is consistent on its own.

**Never commit secrets** (.env, credentials.json, private keys).

### 3. Generate Commit Message

Analyze the diff to determine:

- **Type**: What kind of change is this?
- **Scope**: What area/module is affected?
- **Description**: One-line summary of what changed (present tense, imperative
  mood). The whole subject, including type and scope, must not exceed 50
  characters.

### 4. Execute Commit

```bash
# Single line
git commit -m "<type>[scope]: <description>"

# Multi-line with body/footer
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<optional body>

<optional footer>
EOF
)"
```

### 5. Reword Unpushed Commits

An interactive rebase needs a terminal. To reword unpushed commits without one,
recreate them on the same trees, oldest first, preserving the author and
committer identities and dates:

```bash
# Clean the message: unlike git commit, git commit-tree keeps trailing blank
# lines
git stripspace < <message> > <clean message>

git commit-tree "<commit>^{tree}" -p <new parent> -F <clean message>

# Move the branch only if its tip is still the one you started from
git update-ref refs/heads/<branch> <new tip> <old tip>
```

Before moving the branch, verify that the tree of the new tip is identical to
the tree of the old tip. Afterward, verify that the uncommitted changes
survived.

## Best Practices

- **No AI attribution trailers**: never add `Co-Authored-By: Claude ...`,
  `Generated with ...`, `Claude-Session: ...`, or similar AI attribution or
  session-link trailers to commit messages, even when tool defaults suggest
  doing so.
- **Propose before executing**: when the working tree holds multiple logical
  changes, propose the commit split (files per commit) and the full messages,
  and wait for approval before committing. Leave unrelated in-progress changes
  out of the proposal. Give each proposed commit an identifier that is unique
  across the repositories in the proposal (for example, `H1` and `D1`), so an
  approval of some commits is unambiguous.
- **Validate messages before proposing them**: when the repository lints commit
  messages, run each proposed message through that linter, with the repository
  configuration, before presenting the proposal. A lint run after committing
  finds a failure too late, and may only check the last commit of a batch while
  CI checks all the pushed commits. When the linter configuration changes,
  validate all the unpushed commits against it before pushing.
- **Wait for running verification gates**: if approval to commit arrives while
  a verification gate (linter, build, test suite) is still running, execute the
  commit only after the gate passes, and report the gate verdict together with
  the commit result.
- One logical change per commit
- Present tense: "add" not "added"
- Imperative mood: "fix bug" not "fixes bug"
- Reference issues in a footer after a blank line: `Closes #123`, `Refs #456`.
  Keep issue references with a hash sign (`#123`, `owner/repo#123`) and footer
  keywords out of the message body, or write the references without the hash
  sign: the parser reads them as the start of the footer, depending on where the
  lines wrap. Validation is the reliable check.
- **Strict 50/72 Character Rule**:
  - The commit subject (first line) must not exceed **50 characters**.
  - All subsequent body/footer lines must be wrapped to not exceed **72
    characters**.
- **Use Bulleted Lists for Clarity**: If the commit describes multiple distinct
  but related changes, use a bulleted list in the body. Ensure each bullet point
  is wrapped to 72 characters.

## Git Safety Protocol

- NEVER update Git config
- NEVER run destructive commands (--force, hard reset) without explicit request
- NEVER skip hooks (--no-verify) unless user asks
- NEVER force push to main/master
- If commit fails due to hooks, fix and create NEW commit (don't amend)

## Troubleshooting & Container Permissions

- **Permission Denied on Git Control Files**: In containerized or volume-mounted
  sandboxes (e.g. Docker environments running as root), containers might alter
  ownership of Git control files (such as `.git/config` or `.git/index`) to
  `root`.
- **Resolution**: If Git commits fail with `Permission denied` errors, run
  `ls -la .git/` to check file ownership. Report permissions/ownership issues
  directly to the user so they can restore proper ownership (e.g., using
  `chown`).
