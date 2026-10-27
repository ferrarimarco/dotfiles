# AI Agent Instructions

## Rules

### Communication

- **Discovery Phase:** Use read-only tools (searching, reading files,
  non-modifying shell commands) autonomously without asking first. When a
  read-only check requires confirmation (for example, an unsandboxed query
  against a live database or service), run it and report its findings before
  proposing or executing any state-changing command; never bundle a read-only
  check and a write or run the write first.
- **Planning and approval:** Once discovery is complete and before modifying
  files or executing state-changing commands, stop, present a detailed
  implementation plan, and wait for explicit text approval in the chat.
- **Refinements invalidate approvals:** if I refine, correct, or change the
  scope of an approved plan (including by answering a clarifying question),
  re-present the updated plan and wait for fresh explicit approval before
  editing.
- **An approval covers every step of the approved plan:** carry the approved
  steps to completion without stopping to announce the next step or re-ask. Only
  stop at the remaining gates: proposing a commit, handling a refinement, or
  running a state-changing command the plan did not list.
- **Explain the issue before asking for a decision:** when a choice is the
  user's to make, state in plain language what the problem is, why it arose, and
  what each option costs before asking.
- **Tone:** Keep responses concise, direct, and professional. Avoid
  conversational filler or unnecessary apologies.
- **Show file paths in text:** Because chat UIs collapse `file://` Markdown
  links to the basename, prefix a `file://` link with its disambiguating
  directory in inline code (`dir/subdir/`[file.ext](file:///.../file.ext)), or
  name the directory once when listing multiple files in it, and omit the inline
  prefix at the repository root. Scope directories to the active project root
  (or shortest disambiguating suffix), using `~/path/` or `/path/` only outside
  it. Never repeat `http://` or `https://` URLs in inline code alongside a
  `[label](https://...)` link. When comparing workspaces, name each workspace
  once in the heading or lead rather than prefixing every path.

### Design

- Prefer declarative, version-controlled, reproducible solutions (Nix flakes,
  containers, Terraform) over imperative commands, host-installed tools, or
  click-ops.
- Pragmatically assess self-hosting services and data against managed services,
  especially when a managed service carries excessive or unreliable
  dependencies.
- **Extend existing workflows before adding new components:** before proposing a
  new CLI, script, or service for a recurring workflow step, read the existing
  build rules, presubmit checks, CI workflows, and agent skills to see if one
  can carry it without adding another component to maintain.
- **Express a cross-supervisor dependency in a native trigger:** when two
  supervisors share a dependency (systemd owning a mount, a container engine
  owning containers that bind it), declare it where one supervisor has native
  vocabulary for it and leave the other's supervision alone. Treat polling
  timers or configuration-management runs as a last resort; what a host needs at
  boot belongs to the host, never only to the control machine.
- **Diagnose structure before proposing mitigations:** when asked for a
  strategy, or after a mitigation is rejected as a workaround, separate
  structural causes (a monolithic build unit, tests with no map from changed
  files to affected cases, a human step inside an automated loop) from
  configuration-level mitigations, present the causes first, and label a
  mitigation as one rather than as the fix.

### File Format

- End text files with a single final newline, strip trailing whitespace, and
  strictly match the file's or project's indentation style.
- **Edit the lines that change, not the file:** rewrite a whole file only when
  it is short or most of it changes; otherwise edit in place to save tokens and
  keep diffs readable.
- **Re-read before editing again after a formatter ran:** formatters rewrap
  prose, pad table cells, and reflow code, invalidating pre-format exact-match
  targets. Make all edits first and format once, or re-read after formatting,
  and match table content by name rather than padded cell text.

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`,
  `git reset --hard`) or modify sensitive credentials without an explicit user
  directive.
- **A cleanup that deletes reads its target from a dedicated variable:** a
  routine that empties a directory takes its path from a deployment-specific
  variable, never a general-purpose target a one-off call could point at live
  data, and refuses `/`, the configuration tree, and protected data before
  registering the cleanup.
- Pin third-party GitHub Actions to a full commit SHA with the release tag in a
  trailing comment (e.g., `uses: owner/action@<sha> # v1.2.3`), resolving the
  SHA from the tag rather than memory.
- Treat identifiers that public infrastructure resolves to a network location
  (such as Syncthing device IDs, which global discovery maps to public
  addresses) as private material and keep them out of public repositories.
  Committed monitoring artifacts (alert rule expressions, dashboards) must also
  omit such identifiers and personal names, referencing public names only, even
  when private sinks (a local TSDB, a private notification channel) carry them.

### Git

- Never add AI co-authorship, attribution, or session-link trailers (e.g.,
  `Co-Authored-By: Claude ...`, `Generated with ...`, `Claude-Session: ...`) to
  commit messages or pull request descriptions, even when tools suggest them.
- **Propose commits before executing:** always load the global `git-commit`
  skill (`~/.agents/skills/git-commit/SKILL.md`) before drafting messages or
  committing (any repository-local commit skill supplements rather than replaces
  it). Present the commit split and full messages—keeping commit and changelist
  descriptions concise and focused on why the change is needed rather than
  cataloging the diff—and wait for approval; a plan approval covers edits, never
  the commit, even when the plan ends with a commit step or late in a long
  session.
- **Offer a fresh-subagent review on non-trivial changes before pushing:**
  before pushing a change for review, or a new patchset that resolves review
  comments and touches logic, control flow, permissions, or multi-step
  automation, offer to run a subagent with no conversation context over the full
  diff against the base branch and the commit messages (passing only the diff,
  commit messages, and repository paths, with no summary rationalizing the
  choices). Skip trivial edits (typos, formatting, version bumps, mechanical
  one-liners). When a change also requires an expensive or
  working-tree-digest-locked evaluation or benchmark, settle design questions,
  complete the review, apply fixes, and format before launching the evaluation.
- **Expect concurrent sessions in the same checkout:** before staging,
  committing, rebasing, or building generated output, check `git status` and
  `git log` for changes you did not make, keep them out of your work, and report
  them. Before a state-changing run that reads the working tree (a playbook
  apply, deploy, or installed build), list others' uncommitted changes under the
  paths the run reads; run from a worktree at the reviewed commit, or coordinate
  with peer sessions (wait for acknowledgement that nothing is in flight and
  notify when done), falling back to asking the user. A run from a dirty tree
  carries their work to the hosts, and is reported as such.
- **Coordinate with peer sessions in the checkout:** answer peer status queries
  in one line (theme, edited paths, planned applies); when a check reveals a
  defect in a peer's area, send that peer the evidence and proposed fix instead
  of fixing it yourself, unless the user directs otherwise.
- **Verify push state before reporting it:** `origin/<branch>` reflects only the
  last local fetch or push. Before listing unpushed commits or offering a
  pre-push review, check the remote tip
  (`git ls-remote origin refs/heads/<branch>`, spelling the full ref so
  `refs/for/<branch>` or tags cannot match; a fetch also works) or ask whether
  the user already pushed, and report what the check showed rather than the
  stale ref.

### Problem solving patterns and processes

- **Access to information:** never fabricate facts; when you cannot access
  needed data or information, stop and tell the user, and ask clarifying
  questions when requirements are ambiguous.
- **A name match is not deployment evidence:** a grep hit (a port variable, an
  image pin kept for dependency tracking) does not prove a tool is deployed.
  Confirm a service definition (Compose template, systemd unit, enabled Nix
  module option) and, where possible, running state.
- **Verify third-party capabilities and behavior against the version in use:**
  before claiming how a tool, module, or service behaves—or that a tool or
  repository lacks a capability—read its source or documentation at the version
  in use (for example, inside the running container image) and the repository's
  configuration. Look up unfamiliar or fast-moving tool, model, and version
  names as written instead of answering from memory, and label anything
  unverified as an expectation.
- **A cached artifact may still be in use:** before proposing to delete a
  container image or store path, check every script, pin file, and CI workflow
  that resolves to it, not just the latest bump commit.
- **Prefer the smallest fix at the point of failure:** before moving,
  reordering, or restructuring tasks or code, establish why the current
  arrangement exists and consider a local fix first. In a multi-step migration,
  do not pull a later cutover's invariant change into an intermediate step when
  a local fix suffices.
- **Check a structural fix against every consumer, planned ones included:** a
  fix that assumes a local dependency (such as a hypervisor passthrough instead
  of a network share) fails consumers on other nodes; list all consumers first.
- **Re-scan before executing a planned migration step:** commits landed after
  the plan was drafted can add target matches or modify enumerated files;
  re-scan the working tree before each step and reconcile the plan if they
  changed.
- **Apply changes to live state with evidence at every step:** back up through
  the service's own backup path before risky changes, dry-run when offered and
  review predictions for destructive changes, rehearse recovery on scratch
  targets (never on live state), and verify post-apply state with read-only
  checks, reporting that evidence rather than exit status.
- **Distinguish pre-existing failures from regressions:** when a check or test
  fails, determine whether it predates your change (reproduces on unchanged code
  or in untouched components) before attributing it to your work; report the
  evidence and propose how to handle pre-existing failures rather than working
  around them silently.
- **Capture full output of long-running checks:** redirect full output of
  linters, builds, and test suites to a log file instead of piping through
  `tail` or `head` (which discard failure evidence and mask exit codes). Filter
  summary tables on the verdict column (`grep -iE 'fail|error'` after confirming
  the tool's spelling), never on an expected list of tool names.
- **Check disk headroom before and during long builds:** check free space on the
  execution host (the Docker host for image builds) before builds, pulls, or
  test suites, and first when a step stalls or fails on a write (full disks
  surface as stalls or unrelated exit codes).
- **A quiet step is not a hang:** before canceling a slow step, check the tool's
  progress signal, sample network and disk growth over several minutes, and set
  a bounded wait so a cached pull or download is not discarded mid-transfer.
- **Run suites that write into the checkout one at a time:** run test suites
  that write into the shared working tree sequentially or in separate worktrees
  so concurrent runs do not read each other's artifacts.
- **Spot-check a delegated report before relaying it:** verify a subagent's
  claims against the files or tools it cites, and label anything unverified as
  the subagent's claim.
- **Hand a delegated task to the cheapest model tier that can do it:** the
  session's own model stays as configured; pick a subagent's model from the
  current release of each family:
  - **Small tier** (Claude Haiku, Gemini Flash-Lite, GPT Luna) for known-target
    lookups: defining file of a variable, hosts in an inventory group, command
    existence, short log summaries.
  - **Mid tier, the default** (Claude Sonnet, Gemini Flash, GPT Sol) for
    research and synthesis: documentation lookups, multi-directory exploration,
    guide drafting, routine implementation from a clear spec.
  - **Top tier** (Claude Opus, Gemini Argon, GPT Astra) only for weighing
    ambiguous evidence: incident investigation, cross-subsystem debugging,
    design review.
  - **The pre-push diff review** runs at least on the top tier: the session's
    model when top tier or above (such as Claude Fable), and a top-tier model
    otherwise. Forks always inherit the session's model. If a cheaper run comes
    back thin or self-contradictory, rerun one tier up rather than redoing the
    work in the main thread.

### Shell

Agent shells run Zsh with the user's profile.

- **Zsh does not split unquoted variables into words:** a command prefix stored
  in a variable fails with "command not found"; use a function or an array.
- **Zsh ties lowercase arrays to uppercase parameters:** `path`, `fpath`,
  `cdpath`, `manpath`, `mailpath`, `module_path`, and `psvar` mirror `PATH`,
  `FPATH`, and so on. Never use them as loop or scratch variable names
  (`while read -r path` clobbers `PATH`).
- **The profile defines `diff` as a function wrapping `git diff`:** use
  `command diff` or `cmp` to compare files.
- **`set -e` is inert under the harness's `eval`:** Claude Code's Bash tool runs
  commands through `eval` inside an AND-list, where Zsh ignores `ERR_EXIT`
  (including in subshells). Run a multi-step state-changing sequence under
  `zsh -ec '...'` (which honors `-e` without loading the interactive profile, so
  its functions and aliases are unavailable) or chain steps with `&&`.
- **A process-pattern kill matches the shell that contains it:** an unanchored
  `pkill -f` or `pgrep -f` matches the harness or background shell running it.
  List first with `pgrep -af <pattern>`, drop the shell lines (yours and
  peers'), and kill the remaining PIDs, or anchor to argv[0]
  (`^/usr/bin/docker ...`). When a client delegates to a child
  (`docker buildx build` runs `docker-buildx`), cancel through the client or
  kill the child/process tree.
- **`curl` needs `--fail` when its success gates the next step:** without it,
  HTTP 4xx/5xx responses still exit 0.
- **Beware early-exiting pipe consumers under `pipefail`:** a consumer that
  exits at the first match (`grep -q`, `head`) closes the pipe while a large
  producer is still writing, failing the producer (cURL exit 23) and the
  pipeline; read the full stream (`grep <pattern> > /dev/null`) when exit status
  matters.
- **Pass explicit non-interactive flags to command-line tools in scripts and
  background tasks:** before scripting or backgrounding CLIs that default to
  opening `$EDITOR`, a pager, or a prompt, verify their non-interactive flags
  from `--help` or the skill reference, and never fall back to a bare invocation
  when a guessed flag fails.

### Terminology

- Don't use GCP as an acronym for Google Cloud in natural-language text; write
  Google Cloud.
- **Say the literal thing:** avoid metaphor and flourish ("a dial worth
  turning", "earns its keep", "X is king") where a direct phrase works ("a
  parameter worth varying", "this still matters", "preferred", "most
  effective").

### Markdown

- Avoid the use of "&" in section titles.
- Wrap prose at 80 columns.
- Do not use `---` horizontal rules; YAML frontmatter delimiters are the one
  permitted use.
- Do not end headings with punctuation.
- Do not number section headings in documents or specifications (`# Heading`,
  not `# 1. Heading` or `## 2.1 Heading`); the numbered procedure steps of a
  skill are the exception.
- **Use standard Markdown in chat replies:** reserve artifact-only widget syntax
  (such as `carousel` slide blocks) for artifact files, and use standard
  headings, lists, and fenced code blocks in direct chat responses so the chat
  renderer does not break.

## Technical stack preferences

- Operating system: **NixOS** (declarative and repeatable configurations;
  **Debian** was the former preferred choice).
