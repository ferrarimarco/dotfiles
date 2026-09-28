---
name: create-skill
description: >-
  Create a new agent skill, improve existing ones, and consolidate or remove
  duplicate skills. Use when the user asks to create, add, scaffold, or rework a
  skill, or when a session determines that a recurring task type needs its own
  skill, or when running skill ablation tests (with skill vs without skill), or
  diagnosing why a skill didn't trigger, or when a skill produces wrong output,
  or invokes `/create-skill`.
license: MIT
---

# Create Skill

Author new skills, improve or consolidate existing ones, and diagnose skills
that misfire.

## Principles

- The description decides whether the skill loads; the body decides what
  happens next. Write each for its reader.
- Every line of `SKILL.md` costs context on each activation. Keep the file to
  what the agent must do, push detail to `references/`, and prefer tightening
  over growing: a fix that removes lines is a valid fix.
- One skill per task type; overlapping skills split the trigger and drift apart.
- Skills do not depend on each other by name. When one needs another, describe
  the outcome in words that match the other skill's triggers.
- Generalizable knowledge only. Rules specific to one repository belong in that
  repository's `AGENTS.md`.
- Explain the why instead of issuing commands, and generalize past the test
  cases. All-caps ALWAYS and NEVER, rigid structures, and fixes that only
  satisfy the examples are warning signs: a skill runs across many prompts, and
  a model that understands the reason handles the ones you did not test.
- Verify by behavior, not by reading: run the triggering prompt and compare
  outcomes.

## Skill Creation Process

### 1. Capture Intent

When the conversation already contains the workflow to capture, extract the
tools used, the sequence of steps, the corrections the user made, and the input
and output formats from history first. Then settle four questions with the user:
what the skill enables, which phrases and contexts should trigger it, the
expected output format, and whether test prompts are warranted. Objectively
verifiable outputs benefit from tests; subjective ones usually do not.

### 2. Resolve the Skills Directory

Find where the harness loads skills from and where that location is
version-controlled, since the two may differ. Harnesses read a user skills
directory such as `~/.claude/skills` or `~/.gemini/skills`, and a project may
add its own. When such a directory is a symlink into a dotfiles checkout,
follow it rather than assuming a path:

```sh
git -C "$(realpath ~/.claude/skills)" rev-parse --show-toplevel
```

Create the skill in the version-controlled location, following that
repository's `AGENTS.md` for its conventions and registration rules, and read
two or three existing skills there first to match their style.

### 3. Decide Whether a Skill Is the Right Unit

A skill is warranted for a recurring task type with its own workflow or domain
knowledge (a tool, a technology, a procedure). A single rule that applies across
tasks belongs in an `AGENTS.md` file instead. Before creating a skill, list the
skills directory for an existing skill that already covers the task type and
extend it instead.

### 4. Name the Skill

- Kebab-case, verb-first, describing the task rather than the agent
  (`design-spec`, `troubleshoot-host`, `capture-learnings`), or
  `<technology>-developer` for technology expertise.
- Avoid names that collide with harness built-in commands or with widely
  distributed skills.
- The slash command is the skill name (`/<name>`).

### 5. Write the Skill

Write the description following the Skill Description section below, and the
other frontmatter fields and the body following the Skill Structure section.

### 6. Write Test Prompts

Write two or three realistic prompts, the kind a user would type, with concrete
context such as file names and casual phrasing, and fix the success criteria
for each before running anything. Then run them with the ablation test in
improvement step 4.

## Skill Improvement Process

Repeat steps 1 to 5 until the user is satisfied, the feedback comes back empty,
or further iterations stop producing meaningful change. Every test subagent
must report the skills it loaded and the steps it took, since the parent sees
only its report.

### 1. Reproduce

Capture the exact prompt and the wrong or missing behavior before changing
anything.

### 2. Classify the Failure

- Did not trigger: the description lacks the phrases the user wrote, is too
  generic, or exceeds the length limit; or the frontmatter did not parse (see
  Skill Description). To locate the gap, run eight to ten queries that should
  trigger and as many near misses against fresh subagents and read which ones
  misfire. Near misses share the domain but need something else: for a systemd
  skill, "write a cron entry for the nightly backup" is a near miss, while "my
  backup timer never fires after a reboot" should trigger. Obvious negatives
  test nothing.
- Triggered but wrong: the body is ambiguous, misses a step, or contradicts a
  rule in an `AGENTS.md` file.

### 3. Fix the Smallest Thing

Change only what explains the failure, and prefer removing or tightening lines
over adding them. Read what the test subagents did, not only what they
produced, and remove parts of the skill that send the model on unproductive
work.

### 4. Run an Ablation Test

Launch two fresh subagents in parallel with the same self-contained prompt and
the judging criteria fixed in advance; never a forking subagent, which inherits
the parent context. The baseline invokes no skill when creating, or reads a
pre-edit copy of `SKILL.md` from the scratchpad when improving, so the test
measures the change rather than the skill's existence. Keep the change only if
the new version is better against the criteria in a way you can name. Where the
harness has no subagents, move the skill directory out of the skills tree
temporarily and start a fresh session for each run, since harnesses that
enumerate skills at startup will not notice a mid-session move.

### 5. Bundle Repeated Work

When the test runs independently write the same helper script or repeat the
same multi-step approach, put it once in `scripts/` and point the skill at it.

### 6. Consolidate Duplicates

When two skills share triggers or content, merge into the more general one and
retire the other: delete its directory, reverse its registration steps from
the repository's `AGENTS.md`, and search the remaining skills and instruction
files for references to it, since a stale mention sends the agent to a skill
that no longer exists.

## Skill Description

The description is the only part of the skill loaded before activation, so it
alone decides whether the skill triggers.

- Shape: one sentence on what the skill does, then "Use when" followed by
  concrete triggers: the verbs and phrases users write, file types, situations,
  and `/<name>` when the skill is user-invocable.
- Write it as a `>-` folded block scalar, unquoted, so the multi-line value
  parses as one string.
- Models undertrigger. Make the description a little pushy: name the mentions
  and situations that should activate it even when the user does not ask for it
  by name.
- All "when to use" information belongs here, none in the body.
- Do not restate the body, list its steps, or name other skills.
- Skills are consulted for tasks the model cannot handle in one step. A one-line
  request may not trigger even a perfect description, so test triggering with
  substantive prompts.
- After writing, check that the harness lists the full description. Seeing only
  the title means the frontmatter did not parse.

## Skill Structure

Follow [the structure reference](references/skill-structure.md) for the
directory layout, every frontmatter field and its constraints, body content,
and context budgets.

- Body layout: one H1 with the skill title, a one- or two-sentence purpose
  statement, then H2 sections, numbered for procedures and thematic for bodies
  of expertise.
- Imperative, concise prose and bullet lists.

## References

- [Agent Skills specification](https://agentskills.io/specification)
- [Claude Agent Skills overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Claude Agent Skills best practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Antigravity skills](https://antigravity.google/docs/skills/)
- [Anthropic skills repository](https://github.com/anthropics/skills)
