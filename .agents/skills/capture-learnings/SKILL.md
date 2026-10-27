---
name: capture-learnings
description: >-
  Distill durable lessons from the current session and saved memories into
  version-controlled agent configuration: global and project AGENTS.md files and
  skills, promoting graduated memories and removing them afterward. Use when the
  user asks to capture learnings, improve agent instructions or skills, promote
  or clean up memories, or invokes `/capture-learnings`.
license: MIT
---

# Capture Learnings

Turn what a session taught into durable, version-controlled instructions. The
output is a set of tightened AGENTS.md files and skills, plus a cleaned-up
memory store; the process is analyze, verify, propose, wait for approval, apply,
then review.

## 1. Resolve the Configuration Layout

Never assume where the dotfiles repository is checked out; resolve it at
invocation time from the global instructions file, which every harness links:

```sh
git -C "$(dirname "$(realpath ~/.agents/AGENTS.md)")" rev-parse --show-toplevel
```

- `~/.agents/AGENTS.md`: global instructions loaded by all agents. Resolve with
  `realpath ~/.agents/AGENTS.md`.
- `~/.claude/CLAUDE.md`: Claude-specific entry point that references
  `~/.agents/AGENTS.md` and holds only rules specific to Claude.
- `<root>/.agents/skills`: one directory per skill, each with a `SKILL.md`.
  `~/.claude/skills` links to it where Claude Code is installed; use
  `realpath ~/.claude/skills` as a cross-check when it exists.
- `<project>/AGENTS.md` and `<project>/.agents/skills`: project-specific rules
  and skills in the repository being worked on, if present. If the project has
  only a `CLAUDE.md` (or `.claude/skills`), treat it as the project file or
  skills directory; if it includes another file, edit the included file.
- Per-project memories: a store the harness manages for the current project, not
  version-controlled and not shared across machines or agents. Locate it from
  the harness's own context rather than by guessing a path; if the harness
  announces no store, treat it as absent. Edit memories at their real
  home-directory location. Claude Code announces the path in its system prompt
  (`~/.claude/projects/<project>/memory/`), with `MEMORY.md` as the index and
  one Markdown file per memory carrying `name`, `description`, and
  `metadata.type` of `user | feedback | project | reference`.

For global configuration, edit only the resolved files inside the dotfiles
checkout. Never replace a symlink with a regular file, and never edit an
unlinked copy under the home directory.

## 2. Mine the Session for Signals

Review the conversation (including this capture run itself) for:

- user corrections, and rejected or interrupted tool calls;
- questions the agent had to ask, mistakes caused by missing, ambiguous, or
  contradictory instructions, and workflow steps or environment quirks learned
  the hard way;
- statements the agent made and corrected later, or disproved during this run
  (an attribution, a count off the wrong listing, a "nothing changed"), with the
  check that would have caught each one first;
- detection and recovery gaps: an incident monitoring missed or caught late, or
  a recovery a runbook step would have shortened (note whether the check existed
  before the fix, since a check added with the fix never saw the real failure);
- test fixtures or CI matrices that never exercise a code path real data uses;
- review gaps in code or document reviews: external reviewer or bot comments the
  agent's review missed, delegated-review findings on the agent's output that
  its self-check missed, and ad-hoc findings not yet covered by existing skills
  or instructions;
- later corrections to rules earlier capture runs wrote (shown in the target
  file's commit history), which are signals about this skill's process as well
  as the target.

Before presenting the plan, route lessons from this run itself (conventions
looked up, rules rewritten after a check, review findings on its output) and any
signal kind that matched no bullet above or no destination in step 5 to this
skill rather than dropping them.

## 3. Review Saved Memories for Promotion

Read the current project's `MEMORY.md` and every memory file it lists. If the
memory directory or `MEMORY.md` does not exist, state that and skip this step.

- **Promote** a memory that encodes a durable rule about how the agent should
  work: typically `feedback` and `user` types, or `project` memories that state
  standing policy rather than point-in-time status.
- **Retire** a memory whose content no longer holds; list it in the plan for
  deletion.
- **Keep** a memory that records project state, incident history, measurements,
  or external references (`reference` type). These are facts, not rules. Also
  keep anything machine-specific.

## 4. Filter for Durability

Propose only changes that generalize beyond the session. Discard:

- one-off facts, or anything derivable from a repository's own code or docs;
- anything already covered by existing instructions, unless the session (or this
  run) failed to apply the covering rule—then the gap is reachability, and the
  fix is adding the check to the step where the agent was working;
- anything the session already captured in a project's knowledge base (guides,
  specifications, todo items): verify it landed where the next change is written
  against (the reference pattern, guide, or convention list), not only inside an
  incident's own section.

Propose uncaptured project-specific lessons for `<project>/.agents/skills`,
`<project>/AGENTS.md`, or project documentation alongside cross-project lessons,
even when the project checkout is on an in-flight branch or pending changelist.
Check the target files' recent history and working tree for capture edits from
concurrent sessions, and reconcile instead of duplicating.

## 5. Route Each Finding

Route each session finding and promoted memory to the first matching destination
in this priority order, never to both a skill and `AGENTS.md`:

1. An existing skill for that task type: `<project>/.agents/skills/*` for a
   repository-specific convention, or `<root>/.agents/skills/*` when it holds
   across repositories, never both. An agent that skipped monitoring the project
   already had is an instruction gap, not a monitoring gap.
2. The project's `AGENTS.md`, for cross-task rules specific to one repository.
3. The global `~/.agents/AGENTS.md`, only for rules that apply across all
   projects and fit its existing sections.
4. A new skill, only when a recurring task type has no home; propose its name
   and description in the plan.
5. `~/.claude/CLAUDE.md`, only for rules specific to Claude Code.
6. The project's operational artifacts (alert rules, runbooks, todo items),
   through the project's pipeline, when the lesson is a check or procedure the
   project should run rather than an agent rule.
7. This skill, when the defect is in how a lesson was captured or routed.

## 6. Verify Each Proposed Rule

- Check any claim about a tool's or module's behavior against its source or
  documentation at the version in use, and name the responsible component.
- Propose a workaround only after checking the tool for a native option.
- Write a tendency as a tendency, with how to check the specific case, never as
  a universal.
- Scope workflow steps with non-trivial token or time cost (such as subagent
  passes) to the cases where they pay off, skipping trivial work.
- Test each rule against its motivating example and the neighboring case the
  next agent meets (a second host behind the same probe, an unloaded unit);
  scope down any rule that silences, deletes, or reports more than its example.
- Keep rules routed to the public dotfiles (`~/.agents/AGENTS.md` and
  `<root>/.agents/skills/*`) generic, omitting internal corporate hostnames,
  URLs, package names, and identifiers.
- Follow the repository's skill conventions (`AGENTS.md`, `README.md`) when
  creating a skill.

## 7. Present the Plan and Wait

The plan presented for approval must list:

- the proposed edits, as one table per target file with three columns: the
  proposed update, its rationale (the session event or memory), and its evidence
  (source file and version read, command run, or "expectation"); each finding
  appears in one file's table only;
- the memories to delete or rewrite afterward, as a table with two columns: the
  action and its rationale.

## 8. Apply the Approved Plan

- Edit in place and prefer tightening over growing: search the target file for
  overlapping or interacting rules, merge or rewrite accreted sections instead
  of appending near-duplicates, and ensure new rules do not contradict existing
  ones. Give unrelated lessons in the same section their own bullet with a bold
  lead, and keep the imperative, concise style of the target file. A net
  line-count reduction is a valid outcome.
- Remove a promoted memory only after its rule is written to the destination
  file, in the same apply step: delete the memory file and its `MEMORY.md` line
  (or rewrite memories that mixed a rule with state to keep only the state and
  note where the rule moved). Leave non-promoted memories untouched.
- Check each repository's working tree before editing, deferring or coordinating
  around uncommitted changes from other sessions.
- Route edits to a project's own files through that repository's validation
  pipeline and commit conventions; dotfiles edits follow the dotfiles flow. Run
  the formatter before review and inspect its diff: a rewrite beyond the edited
  lines (such as a list turned loose by a stray empty line) is a structural
  defect to fix.

After applying a non-trivial change (new rules, rewritten sections, or a new
skill), have a fresh subagent or the harness's code review check the diff across
every edited repository (including runbooks and todo items) against step 6 and
the tool's source or docs at the version in use. Fix its findings before
reporting. Do not commit unless asked.
