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
- **Hand work over with its review path:** a step presented for review ends with
  its files in reading order (with their paths linked) and the gates that remain
  (tests, lint, commit proposal, review, push, verification), so the reader
  never has to ask where to look or what comes next.
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
- **Treat a committed symlink as a duplication signal:** a symlink in a
  repository often means two components share a file (an alias or compatibility
  name is the other case: check whether the target lies outside the tree a
  consumer of the link's directory reads). Consumers that read only a subtree
  and keep or resolve links within it (a container build context, an archive)
  see a dangling link when the target lies outside it. In an assessment or
  review, name the link; leave an alias whose target lies inside every
  consumer's tree, and propose removing any other link: first by asking whether
  the two consumers should be one component; otherwise by giving the file one
  owner and having the others reference the owner's path through the tool's
  native mechanism (a named build context, a path relative to the owning
  module).
- **Let the tool report its own requirement:** when a host may lack what a role,
  script, or service needs (a tool or interpreter version), do not record the
  requirement as a constant repeated in variables, comments, and guides; run the
  tool at apply time so its own error fails the run (a script preflight running
  the cheapest command that uses the flags it relies on), and let the runtime
  unit fail with an alert.
- **Upgrade the host that fails a requirement, never patch around it:** a
  package pinned from another release, a binary installed beside the package
  manager, or an option that silences the check (pip's Python requirement) is
  state that drifts from the host's release and a second package manager to
  maintain; move the host to a release that meets the requirement.
- **Propose detection with the change:** a plan for a feature or a fix in a
  project with monitoring names the alerts or probes that would catch the new
  component failing or lingering (a unit failed, a reachability probe, a state
  left on longer than its use), or states which existing rules cover it; a
  component no rule covers is a finding of the plan, not an afterthought.
- **Trim before review and name what is speculative:** before presenting an
  implementation, merge wrappers that exist only to call a one-line script and
  keep descriptions and docstrings to a line; then state which structure exists
  for cases that do not exist yet (an extension point with one implementation)
  and its cost, so the reviewer decides whether it stays.

### File Format

- End text files with a single final newline, strip trailing whitespace, and
  strictly match the file's or project's indentation style.
- **Edit the lines that change, not the file:** rewrite a whole file only when
  it is short or most of it changes; otherwise edit in place to save tokens and
  keep diffs readable.
- **Re-read before editing again after a formatter ran:** formatters rewrap
  prose, pad table cells, and reflow code, invalidating pre-format exact-match
  targets, and re-indent nested blocks after a structural edit, which breaks
  scripted exact-match replacements too. Make all edits first and format once,
  or re-read after formatting (or match ignoring indentation), and match table
  content by name rather than padded cell text.
- **Comments carry the reason, not the instance:** a variable's or default's
  comment says why it exists and what the value means; hostnames, dates,
  incident references, and values the code or the tool already states belong in
  the project's docs or todo items, maintained once. Identifiers a pin needs to
  stay readable (the release tag beside a commit SHA) are the exception.

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
- **Enforce untrusted-branch CI gates from a ref the branch cannot edit:** a
  sanitization step, policy check, or credential gate inside a workflow file
  that runs from a feature branch or `pull_request` merge ref can be modified or
  deleted by the same branch it constrains, and GitHub OIDC's `job_workflow_ref`
  claim on a standalone branch or `pull_request` run resolves to that branch or
  `refs/pull/<N>/merge` rather than the default branch. Run credential gates and
  mint credentials from a workflow definition fixed to a protected ref—such as a
  reusable workflow on the default branch matched by `job_workflow_ref`
  (removing `uses:` forfeits the token), or a target-branch trigger that never
  executes untrusted branch code or hooks with secrets or write tokens—and pin
  merge-blocking policy workflows in repository rulesets so the branch cannot
  replace `uses:` with a passing stub of the same job name. When restoring
  control paths from `<base>` before reading a branch checkout, restore in
  no-overlay mode (`git restore --source=<base> --staged --worktree --`, its
  default, or `git checkout --no-overlay <base> --`) across candidate paths
  present in `<base>` or `HEAD` (`git ls-tree --name-only <base> -- <paths>` and
  `HEAD`, without trailing slashes, skipping the restore when none match), so
  paths added on the branch are removed while absent paths do not abort the
  command.
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
  the commit messages, the repository paths, the paths of the skills whose
  conventions apply, and the logs of the runs that exercised the change, with
  secrets masked and no summary rationalizing the choices). The brief states
  that the review is static and read-only, with no execution of the project's
  toolchain unless the user approved a run, and sets a time limit. A finding is
  closed by the log of a run of the reviewed commit that exercised the code path
  it concerns, not by argument. Skip trivial edits (typos, formatting, version
  bumps, mechanical one-liners). When a change also requires an expensive or
  working-tree-digest-locked evaluation or benchmark, settle design questions,
  draft the full commit message (with a placeholder for what the run adds
  afterward, such as a trailer linking its report), complete the review over
  both the diff and that message, apply fixes, and format before launching the
  evaluation.
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
- **Warn the peer whose apply will carry a defective commit of yours:** when the
  commit carries a known defect or a pending fix, tell the peer which commit and
  when the fix lands, so it applies from the fixed tip or holds the apply.
- **A peer's report that its run carried your change means verify, not
  re-apply:** it is the receiving side of the dirty-tree rule above, so verify
  on the hosts that the change took effect instead of re-applying.
- **Verify push state before reporting it:** `origin/<branch>` reflects only the
  last local fetch or push. Before listing unpushed commits or offering a
  pre-push review, check the remote tip
  (`git ls-remote origin refs/heads/<branch>`, spelling the full ref so
  `refs/for/<branch>` or tags cannot match; a fetch also works) or ask whether
  the user already pushed, and report what the check showed rather than the
  stale ref. A tip that differs is not a tip ahead: after a fetch, compare in
  both directions (`git log --oneline origin/<branch>..HEAD` and the reverse)
  before reporting the branch as ahead, behind, or diverged.
- **Bound CI checkout depth to the commits the diff reads:** in pull-request CI
  jobs that check out the synthetic merge commit (`refs/pull/<N>/merge` in
  GitHub Actions, where `HEAD^1` is the base branch tip and `HEAD^2` is the PR
  head) and only diff files against the base tip, `fetch-depth: 2` and
  `git diff HEAD^1 HEAD` produce the PR's net merge diff without downloading the
  full commit graph that `fetch-depth: 0` (even with `filter: blob:none`)
  transfers on every push. Jobs that walk PR commits (`git log`, commit
  linters), compute `merge-base` (`A...B` or `origin/<base>`), or share the step
  unguarded with multi-commit `push` runs need deeper history, since
  `fetch-depth: 2` grafts `HEAD` after its immediate parents (leaving `HEAD^2`
  parentless on PRs and `HEAD~1` parentless on `push`) and omits
  `origin/<base>`.

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
- **A rejection reason must distinguish the options:** before implementing a
  specification that rejects an alternative, read the vendor's documentation of
  the rejected path and of the chosen one, since both may share the property the
  reason names; raise a reason that fails the check before implementing, not
  after the user asks.
- **Size an alternative only after walking its transitions:** before giving a
  line count or an effort for a variant, enumerate what happens on each
  transition (set, cleared, host reboot, a manual action in between) and label
  an estimate given before that walk as a guess.
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
- **A command substitution expanded before `$?` replaces its value:** in
  `echo "… $(cmd) … $?"` the substitution runs during expansion, so the status
  reported is the substitution's (Zsh and Bash alike); save `rc=$?` on its own
  line first (`status` is read-only in Zsh).
- **Pass explicit non-interactive flags to command-line tools in scripts and
  background tasks:** before scripting or backgrounding CLIs that default to
  opening `$EDITOR`, a pager, or a prompt, verify their non-interactive flags
  from `--help` or the skill reference, and never fall back to a bare invocation
  when a guessed flag fails.
- **Executed Bash scripts open with a shebang and the long-form options:**
  `#!/usr/bin/env bash`, then `set -o errexit`, `set -o nounset`, and
  `set -o pipefail` on separate lines, in every Bash script that runs as its own
  process, including a fragment a builder wraps with its own header (Nix
  `writeShellApplication` prepends the same three options, so the repeat is
  harmless): the file reads and lints as a complete script on its own. A file
  meant to be sourced (a shell profile fragment, a function library) leaves the
  three options out, since they would apply to the shell that sources it (an
  interactive shell then exits on the first failing command).
- **An EXIT trap set inside a function runs without the function's locals:** on
  a normal return and on an `errexit` failure alike, the trap fires after the
  function's scope is gone, so `nounset` fails the trap on the first local it
  reads and the cleanup never runs; only an explicit `exit` inside the function
  still sees them (observed on Bash 5.2 and 5.3). Keep the trap's variables
  global, or run the cleanup and `trap - EXIT` before returning.

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
