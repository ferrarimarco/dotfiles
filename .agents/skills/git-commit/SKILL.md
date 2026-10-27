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

A path whose deletion is already staged matches no pathspec for `git add`: leave
it out of the path list, since the deletion is already in the index. When the
index content may differ from the patch's base (another session is editing the
file), see [Concurrent Sessions](#concurrent-sessions).

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
  Keep hash issue references (`#123`, `owner/repo#123`), footer keywords, and
  lines starting with a word or hyphenated token followed by a colon and a space
  (`Note: ...`, `configured: ...`) out of the body (reword or rewrap them, or
  omit the hash sign): commitlint parses the first match and everything after it
  as the footer and warns about a missing empty line. Validate with the
  repository's commit linter to be sure.

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

### 5. Amend or Reword an Unpushed Commit

An interactive rebase needs a terminal only for its editors. To change an older
unpushed commit without one, record the change as a fixup commit and let a
non-interactive rebase fold it in:

```bash
# Content change: stage it, then
git commit --fixup=<commit>

# Message change: the fixup takes its message from the editor only (-m and -F
# are refused), on a template whose first line is "amend! <old subject>"; the
# editor script keeps that line and replaces the rest with the new message
NEW_MESSAGE=<clean message> GIT_EDITOR='sh -c "{ head -1 \"$1\"; echo; cat \"$NEW_MESSAGE\"; } > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"" sh' \
  git commit --fixup=reword:<commit>

# --autosquash is a no-op without -i in git 2.39; a sequence editor that
# accepts the generated plan as is makes the interactive rebase run without a
# terminal. --autostash carries an uncommitted working tree across (its pop
# can conflict: save the diff first, as the Concurrent Sessions section says);
# --root replaces <commit>^ when the target is the root commit
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash --autostash <commit>^
```

The hooks run when the fixup commit is created (pre-commit on the content,
commit-msg on the `fixup!` or `amend!` subject), not during the rebase, so a
reworded subject still goes through the message validation of the Best Practices
on its own. Verify afterward that `git rev-parse HEAD^{tree}` equals the tree of
the tip immediately before the rebase, fixup commits included (always true when
nothing conflicted), and that `git range-diff <base>..<old tip> <base>..HEAD`
marks only the targeted commit as changed, with `=` on every other row. The
plumbing route (`git commit-tree` on the same trees plus `git update-ref`
guarded by the old tip) also works on a dirty tree, but it runs no hook, so
reserve it for a repository without them.

## Best Practices

- **Propose before executing**: propose the commit split (files per commit) and
  full messages, leaving unrelated in-progress changes out, and wait for
  approval. Give each proposed commit an identifier unique across the
  repositories in the proposal (for example, `H1` and `D1`) so partial approvals
  are unambiguous; when the user reviews commits one at a time, an approval
  covers only the commit under review: create it and stop.
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

- Before a rebase, save the working tree diff outside the repository, and
  afterward verify that the uncommitted changes survived.
- Generated output that a build produces from the working tree includes the
  uncommitted and untracked sources of every session: when the output must
  reflect committed sources only, build it in a temporary worktree checked out
  at the target commit.
- After another session rewrites history, verify your commits before building on
  them: use the reflog to find the commits they replace, and compare patches and
  messages with `git range-diff <old base>..<old tip> <new base>..<new tip>`,
  whose `=` rows mean identical patch, message, and author. When you are the one
  rewriting, state the replaced range and the new tip in your reply, and send
  them to the peers where the harness allows it: their notes and messages carry
  the old hashes.
- Before reporting that a peer's commit introduced a defect, read what that
  commit did to the file (`git diff <commit>^! -- <path>`): a diff of the
  working tree against the tip locates the fix, not the culprit, and an amend
  aimed at the wrong commit rewrites history twice.
- A partial commit that must leave another session's staged changes alone goes
  through a temporary index: set `GIT_INDEX_FILE` on each command that stages
  (`read-tree HEAD`, `apply --cached`, `update-index`) and on the `git commit`
  itself, which then commits that index, runs the hooks, and moves the branch
  without touching the shared index. Never export the variable around
  `git worktree add`, which writes the index it is given. Run the staged numstat
  check against the temporary index before committing, then
  `git reset -- <own paths>` so the shared index matches the new tip for the
  committed paths only; first compare the paths with
  `git diff --cached --name-only` on the shared index, since the reset silently
  unstages a peer's hunks in any path both sessions touch.
- For a file whose index content may differ from the patch's base (another
  session is editing it), prefer the prepared-copy route over a patch: a hunk
  with little context (`--unified=0` applied with `--unidiff-zero`, or a removed
  line that occurs more than once) can land on the wrong line when the index
  content moved, and the result still commits. Validate the staged blob before
  committing (`git show :<path>`, parsed or linted, with `GIT_INDEX_FILE` set
  when staging through a temporary index, or the shared index's blob is what
  gets checked).

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
