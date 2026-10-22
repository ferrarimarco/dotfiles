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

Review the conversation for:

- corrections the user made;
- tool calls the user rejected or interrupted;
- questions the agent had to ask that better instructions would have answered;
- mistakes caused by missing, ambiguous, or contradictory instructions;
- workflow steps the agent had to rediscover;
- environment quirks learned the hard way;
- detection and recovery gaps: an incident that monitoring missed or caught
  late, or a recovery that a runbook step would have shortened; note whether the
  check existed before the fix was applied, since a check added together with
  the fix never saw the real failure;
- a test fixture or CI matrix that never exercises a code path the real data
  uses, so CI stays green while real runs fail;
- statements the agent made to the user and corrected later (an attribution, a
  count read off the wrong listing, a "nothing changed"), with the check that
  would have caught each one first;
- review gaps in code or document reviews: comments a human reviewer posted on
  the change or document that the agent's review missed, and findings the agent
  caught ad-hoc that existing skills or instructions do not yet cover;
- later corrections to rules that earlier capture runs wrote (the target file's
  history shows the commit): these are signals about this skill's process as
  well as about the target.

This run is part of the session too. Before presenting the plan, mine the run
itself: conventions it had to look up, rules it rewrote after a check, and
review findings on its output. Route those to this skill. Then run a blind-spot
check: list the kinds of findings the session produced, and treat a kind that
matches no signal above, or has no destination in the routing list, as an edit
to this skill rather than a finding to drop.

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

- one-off facts;
- anything already covered by existing instructions, unless the session
  (including this run) did not apply the covering rule: then the finding is
  about reachability, and the fix is adding the check to the step where the
  agent was working, not discarding it;
- anything derivable from a repository's own code or documentation;
- anything the session already captured in a project's own knowledge base
  (guides, specifications, todo items): verify it landed, instead of
  re-proposing it.

Capture project-routed lessons during the session, in the project's own
knowledge base, while the context is fresh; when a capture run finds uncaptured
project-specific lessons for `<project>/.agents/skills`, `<project>/AGENTS.md`,
or project documentation, propose them in the plan alongside the cross-project
residue rather than skipping them because the project checkout is on an
in-flight branch or has a pending changelist. Concurrent sessions may also run
their own capture: before proposing, check the target files' recent history and
working tree for capture edits from other sessions, and reconcile instead of
duplicating.

## 5. Route Each Finding

Route each session finding and promoted memory to the first matching destination
in this priority order, never to both a skill and `AGENTS.md`:

1. An existing skill, when the lesson is specific to a task type a skill already
   covers (an Ansible lesson goes into the Ansible skill): route to the
   project's skill (`<project>/.agents/skills/*`) when the rule is a convention
   of that repository, or to the global skill (`<root>/.agents/skills/*`) when
   it holds across all repositories, never both. An agent that did not consult
   monitoring the project already had is an instruction gap, not a monitoring
   gap.
2. The project's `AGENTS.md`, when the lesson is a rule for the agent that is
   specific to one repository.
3. The global `~/.agents/AGENTS.md`, only for rules that apply to all projects
   and fit its existing sections.
4. A new skill, only when a recurring task type has no home; propose it in the
   plan and, once approved, create the skill.
5. `~/.claude/CLAUDE.md`, only for rules that apply exclusively to Claude Code.
6. The project's operational artifacts (alert rules, runbooks, todo items),
   through the project's own pipeline, when the lesson is a check or a procedure
   the project should run rather than a rule for the agent.
7. This skill, when the defect is in how a lesson was captured, or when the
   blind-spot check found a kind of lesson it never asks about.

## 6. Verify Each Proposed Rule

A rule outlives the session, so it is held to the standard of a recommendation:

- A rule about a tool's or module's behavior is checked against its
  documentation or source at the version in use, and names the component
  responsible: a wrong attribution sends the next agent to work around the wrong
  layer.
- A workaround is proposed only after checking the tool for a native option that
  covers the case.
- A tendency is written as a tendency, with how to check the specific case,
  never as a universal.
- A workflow step with non-trivial token or time cost (such as a subagent pass)
  is scoped to the cases where it pays off and skipped on trivial work, rather
  than mandated on every run.
- Each rule is applied to its own motivating example, read as the next agent
  would read it, to confirm it gives the right answer there.
- A rule routed to the global dotfiles (`~/.agents/AGENTS.md` and
  `<root>/.agents/skills/*`, which live in a public repository) keeps examples
  and attributions generic and omits internal corporate hostnames, URLs, package
  names, and identifiers from work sessions.
- A new skill follows the repository's skill conventions for naming, body
  layout, and skill-index registration (such as `README.md`), and the plan shows
  its name and description.

## 7. Present the Plan and Wait

The plan presented for approval must list:

- the proposed edits, as one table for each target file with a row for each edit
  and two columns: the proposed update, and its rationale (the session event or
  memory that motivated it);
- the memories to delete or rewrite afterward, as a table with a row for each
  memory and two columns: the action, and its rationale.

## 8. Apply the Approved Plan

- Edit in place and prefer tightening over growing: update or merge into
  existing rules that overlap instead of appending near-duplicates, and rewrite
  sections that have accreted overlapping rules. An unrelated lesson that lands
  in the same section gets its own bullet with a bold lead, since readers scan
  bullet leads. Keep the imperative, concise style of the target file. A net
  line-count reduction is a valid outcome.
- Remove a promoted memory only after its rule is written to the destination
  file, in the same apply step: delete the memory file and its line in
  `MEMORY.md`. Leave non-promoted memories untouched.
- If a memory mixed a rule with state, rewrite it to hold only the state and
  note where the rule moved.
- Before editing any target file, check its repository's working tree: defer or
  coordinate edits to files carrying uncommitted user changes, instead of
  editing into another session's work.
- Route edits to a project's own files through that repository's validation
  pipeline and commit conventions; dotfiles edits follow the dotfiles flow.

After applying a non-trivial change (new rules, rewritten sections, or a new
skill, as opposed to typos or mechanical one-liners), have a reviewer that did
not write the rules read the diff: a fresh subagent given only the diff and the
target files, or the harness's code review. Review every repository the run
edited, the project's runbooks and todo items included, not only the dotfiles: a
runbook carries the same kind of technical claims as a skill. Fix what it finds
before reporting. Do not commit unless asked.
