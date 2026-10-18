---
name: git-commit
description: >-
  Execute Git commit with conventional commit message analysis, intelligent
  staging, and message generation. Use when user asks to commit, amend a commit,
  commit changes, create a Git commit, or mentions /commit.
license: MIT
metadata:
  source: https://github.com/github/awesome-copilot/blob/main/skills/git-commit/SKILL.md
---

# Git Commit with Conventional Commits

Create Conventional Commits (`<type>[optional scope]: <description>`, an
optional body, optional footers) from the actual diff. A breaking change carries
`!` after the type or scope (`feat!: remove deprecated endpoint`) or a
`BREAKING CHANGE:` footer.

## Workflow

### 1. Analyze Diff

Read the staged diff when files are staged, the working tree diff otherwise, and
check `git status --porcelain` for untracked files and changes you did not make.

### 2. Stage Files (if needed)

Stage the exact paths of each commit. Interactive staging (`git add -p`) needs a
terminal. To stage part of a file without one, write the intended content to the
index, or apply a partial patch to it:

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
- **Body**: when needed, keep it concise and explain why the change is made (the
  problem, root cause, or constraint) rather than restating what the diff shows.
  Wrap every line, bullet points included, at 72 characters, and use a bulleted
  list for several distinct but related changes.
- **Footers**: reference issues after an empty line: `Closes #123`, `Refs #456`.
  Keep issue references with a hash sign (`#123`, `owner/repo#123`) and footer
  keywords out of the message body, or write the references without the hash
  sign: the parser reads them as the start of the footer, depending on where the
  lines wrap. Validation is the reliable check.

### 4. Execute Commit

Write a multi-line message without a terminal through a quoted heredoc:

```bash
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
- **Propose before executing**: when asked to commit or amend, propose the
  commit split (files per commit) and the full messages, and wait for approval
  before committing. Leave unrelated in-progress changes out of the proposal.
  Give each proposed commit an identifier that is unique across the repositories
  in the proposal (for example, `H1` and `D1`), so an approval of some commits
  is unambiguous. When the user reviews commits one at a time, an approval
  covers only the commit under review: create it and stop, instead of executing
  the rest of the batch.
- **Stage the exact paths of the approved commit**: never stage a directory
  wholesale when it may contain generated output or another session's work, and
  confirm the staged diff stat matches the proposal before committing. Check it
  with `git diff --staged --numstat --no-renames`: with `diff.renames = copies`
  in the user's gitconfig, copy detection pairs a new generated file with a
  similar file modified in the same change and reports the difference between
  them as deletions.
- **Validate messages before proposing them**: when the repository lints commit
  messages, run each proposed message through that linter, with the repository
  configuration, before presenting the proposal. A lint run after committing
  finds a failure too late, and may only check the last commit of a batch while
  CI checks all the pushed commits. When the linter configuration changes,
  validate all the unpushed commits against it before pushing.
- **Wait for running verification gates**: if approval to commit arrives while a
  verification gate (linter, build, test suite) is still running, execute the
  commit only after the gate passes, and report the gate verdict together with
  the commit result.
- One logical change per commit.

## Concurrent Sessions

Before staging, committing, rebasing, or building generated output, check the
status and the log for changes you did not make, keep them out of your work, and
report them. In particular:

- Before a rebase, save the working tree diff outside the repository, and
  afterward verify that the uncommitted changes survived.
- Generated output that a build produces from the working tree includes the
  uncommitted and untracked sources of every session: when the output must
  reflect committed sources only, build it in a temporary worktree checked out
  at the target commit.
- After another session rewrites history, verify your commits before building on
  them: use the reflog to find the commits they replace, and compare their
  changes and messages.
- A partial commit that must leave another session's staged changes alone goes
  through a temporary index: set `GIT_INDEX_FILE` on each command that stages
  (`read-tree HEAD`, `apply --cached`, `update-index`) and on the `git commit`
  itself, which then commits that index, runs the hooks, and moves the branch
  without touching the shared index. Never export the variable around
  `git worktree add`, which writes the index it is given. Run the staged numstat
  check against the temporary index before committing, then
  `git reset -- <own paths>` so the shared index matches the new tip for the
  committed paths only.

## Git Safety Protocol

- Never update the Git configuration.
- Never skip hooks (`--no-verify`) unless the user asks.
- Never force push to the default branch.
- If a commit fails because of a hook, fix the cause and create a new commit;
  don't amend.
- In a containerized or volume-mounted sandbox, a container running as root may
  change the ownership of Git control files (`.git/config`, `.git/index`). When
  a commit fails with `Permission denied`, run `ls -la .git/` and report the
  ownership to the user so they can restore it (for example with `chown`).
