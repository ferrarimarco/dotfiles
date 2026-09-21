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
memory store; the process is analyze, propose, wait for approval, then apply.

## 1. Resolve the Configuration Layout

Never assume where the dotfiles repository is checked out; resolve it at
invocation time from the global instructions file, which every harness links:

```sh
git -C "$(dirname "$(realpath ~/.agents/AGENTS.md)")" rev-parse --show-toplevel
```

- `~/.agents/AGENTS.md`: global instructions loaded by all agents. Resolve with
  `realpath ~/.agents/AGENTS.md`.
- `~/.claude/CLAUDE.md`: Claude-specific entry point that only references
  `~/.agents/AGENTS.md`. `~/.claude/CLAUDE.md` stays a thin pointer; don't route
  rules into it unless they are specific to Claude.
- `<root>/.agents/skills`: one directory per skill, each with a `SKILL.md`.
  `~/.claude/skills` links to it where Claude Code is installed; use
  `realpath ~/.claude/skills` as a cross-check when it exists.
- `<project>/AGENTS.md`: project-specific rules at the repository root of the
  project being worked on, if present. If the project has only a `CLAUDE.md`,
  treat it as the project file; if it includes another file, edit the included
  file.
- Per-project memories: a store the harness manages for the current project,
  not version-controlled and not shared across machines or agents. Locate it
  from the harness's own context rather than by guessing a path; if the harness
  announces no store, treat it as absent. Edit memories at their real
  home-directory location. Claude Code announces the path in its system prompt
  (`~/.claude/projects/<project>/memory/`), with `MEMORY.md` as the index and
  one Markdown file per memory carrying `name`, `description`, and
  `metadata.type` of `user | feedback | project | reference`.

Edit only the resolved files inside the dotfiles checkout. Never replace a
symlink with a regular file, and never edit an unlinked copy under the home
directory.

## 2. Mine the Session for Signals

Review the conversation for:

- corrections the user made;
- tool calls the user rejected or interrupted;
- questions the agent had to ask that better instructions would have answered;
- mistakes caused by missing, ambiguous, or contradictory instructions;
- workflow steps the agent had to rediscover;
- environment quirks learned the hard way.

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
- anything already covered by existing instructions;
- anything derivable from a repository's own code or documentation.

## 5. Route Each Finding

Apply this priority order to session findings and promoted memories alike:

1. An existing skill, when the lesson is specific to a task type a skill already
   covers (an Ansible lesson goes into `ansible-developer`).
2. The project's `AGENTS.md`, when the lesson is specific to one repository.
3. The global `~/.agents/AGENTS.md`, only for rules that apply to all projects
   and fit its existing sections.
4. A new skill, only when a recurring task type has no home; propose it in the
   plan and, once approved, create the skill.
5. `~/.claude/CLAUDE.md`, only for rules that apply exclusively to Claude Code.

## 6. Present the Plan and Wait

The plan presented for approval must list:

- per-file summaries of the proposed edits, each with the session event or
  memory that motivated it;
- the list of memories to delete or rewrite afterward.

## 7. Apply the Approved Plan

- Edit in place and prefer tightening over growing: update or merge into
  existing rules instead of appending near-duplicates, and rewrite sections that
  have accreted overlapping rules. Keep the imperative, concise style of the
  target file. A net line-count reduction is a valid outcome.
- Remove a promoted memory only after its rule is written to the destination
  file, in the same apply step: delete the memory file and its line in
  `MEMORY.md`. Leave non-promoted memories untouched.
- If a memory mixed a rule with state, rewrite it to hold only the state and
  note where the rule moved.
- Keep the target file's Markdown style: no `---` horizontal rules and no
  trailing punctuation in headings. Memory-file frontmatter delimiters are the
  one permitted use of `---`; general file-format rules are in the global
  `AGENTS.md`.

After applying, do not commit unless asked.
