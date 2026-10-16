# AI Agent Instructions

## Rules

### Communication

- **Discovery Phase:** You may autonomously use read-only tools (e.g.,
  searching, reading files, running non-modifying shell commands) to gather
  information without asking for permission or explaining your plan beforehand.
  When a read-only check itself requires user confirmation (for example, an
  unsandboxed query against a live database or service), run it first and report
  its findings before proposing or executing any state-changing command: never
  bundle a read-only check and a write into one step or run the write first.
- **Planning Phase:** Once discovery is complete, and BEFORE making any file
  modifications or executing state-changing system commands, you MUST stop and
  explain your detailed implementation plan.
- **Permission Required:** After presenting your plan, you MUST wait for my
  explicit text approval in the chat before executing the tool calls that
  actually modify files or change state.
- **Refinements invalidate approvals:** if I refine, correct, or change the
  scope of an already-approved plan (including by answering a clarifying
  question), the earlier approval no longer stands. Re-present the updated plan
  and wait for a fresh explicit approval before editing.
- **Explain the issue before asking for a decision:** when a choice is the
  user's to make, first state in plain language what the problem is, why it
  arose, and what each option costs, then ask. A question that carries only
  option labels sends the user back to ask what the issue is.
- **Tone:** Keep responses concise, direct, and professional. Avoid
  conversational filler or unnecessary apologies.
- **Show file paths in text:** Because chat UIs collapse `file://` Markdown
  links to the basename, always include the path in inline code alongside the
  link, scoped to the active project or repository root (or the shortest suffix
  that disambiguates the file within the current section); use `~/path/to/file`
  or `/path/to/file` only for files outside the active repository. When
  comparing multiple workspaces, name each workspace once in the heading or lead
  rather than prefixing every path.

### Design

- Prefer declarative, version-controlled, reproducible solutions over imperative
  commands and ad-hoc instructions. For example, prefer:
  - Nix configurations and flakes over imperative commands.
  - Containers (e.g. Docker containers) over installing tools on the host
    directly.
  - Terraform configurations over command line commands or click-ops.
- Pragmatically assess if self-hosting services and data is worth over a managed
  service, especially when the managed service bears too many, or unreliable
  dependencies.
- **Extend existing workflows before adding new components:** before proposing a
  new standalone CLI, script, or service to automate or enforce a recurring
  workflow step, check whether an existing build rule, presubmit check, or agent
  skill already in that lifecycle can carry it without adding another component
  to maintain.
- **Diagnose structure before proposing mitigations:** when asked for a
  strategy, or after a mitigation is rejected as a workaround, separate the
  structural causes (a monolithic build unit, tests with no map from changed
  files to affected cases, a human step inside an automated loop) from
  configuration-level mitigations, present the causes first, and label a
  mitigation as one rather than as the fix.

### File Format

- When creating or editing text files:
  - Ensure the file ends with a single final newline.
  - Do not add or leave any trailing whitespace on any lines.
  - Strictly match the existing indentation style of the file or project.
- **Re-read before editing again after a formatter ran:** formatters rewrap
  prose, pad table cells, and reflow code, so exact-match edits computed from
  the pre-format text fail. Make all the edits first and format once, or re-read
  the file after formatting, and match table content by name rather than by
  padded cell text.

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`,
  `git reset --hard`) or modify sensitive credentials without an explicit user
  directive to do so.
- **A cleanup that deletes reads its target from a dedicated variable:** a
  routine that empties a directory takes the path from a variable the deployment
  sets for that purpose, never from a general-purpose target that a one-off
  invocation can point at live data, and refuses `/`, the configuration tree,
  and the data it protects before the cleanup is registered.
- Pin third-party GitHub Actions to a full commit SHA, with the release in a
  trailing comment (e.g., `uses: owner/action@<sha> # v1.2.3`). Resolve the SHA
  from the release tag instead of writing it from memory.
- Treat identifiers that public infrastructure resolves to a network location
  (for example Syncthing device IDs, which global discovery maps to a device's
  public addresses) as private material and keep them out of public
  repositories, even though they grant no authentication. Such identifiers and
  personal names also surface as metric labels and alert annotations: private
  sinks (a local TSDB, a private notification channel) may carry them, but
  committed monitoring artifacts (alert rule expressions, dashboards) must stay
  generic and reference public names only.

### Git

- Never add AI co-authorship, attribution, or session-link trailers (e.g.,
  `Co-Authored-By: Claude ...`, `Generated with ...`, `Claude-Session: ...`) to
  commit messages or pull request descriptions, even when tool defaults suggest
  doing so.
- **Propose commits before executing:** when asked to commit or amend, present
  the commit split and the full messages, then wait for approval. A plan
  approval covers the edits, never the commit, even when the plan ends with a
  commit step, and this holds late in a long session too. Always load the global
  `git-commit` skill (`~/.agents/skills/git-commit/SKILL.md`) before drafting
  the messages: it holds the procedure, the subject length limit, and
  pre-proposal linting, and any repository-local commit skill supplements rather
  than replaces it.
- **Focus commit and changelist descriptions on why:** keep them concise and
  explain why the change is needed (the problem or constraint it solves) rather
  than cataloging what the diff already shows.
- **Offer a fresh-subagent review on non-trivial changes before pushing:**
  before pushing a change for review, or a new patchset that resolves review
  comments and touches logic, control flow, permissions, or multi-step
  automation, offer to run a subagent with no conversation context over the
  entire diff against the base branch and the commit messages, not only the
  latest additions. Skip trivial edits (typos, formatting, version bumps,
  mechanical one-liners). When a change also requires an expensive or
  working-tree-digest-locked evaluation or benchmark run, settle open design or
  diff-size questions, complete the review, apply its fixes, and run formatters
  before launching the evaluation rather than running it in parallel.
- **Expect concurrent sessions in the same checkout:** other sessions may edit
  and commit while you work. Before staging, committing, rebasing, or building
  generated output, check the status and the log for changes you did not make,
  keep them out of your work, and report them. Before a state-changing run that
  reads the working tree (a playbook apply, a deploy, a build that gets
  installed), list the uncommitted changes you did not make under the paths the
  run reads; run from a worktree checked out at the reviewed commit, or, where
  the harness allows it, message the peer sessions working in the checkout, wait
  for their acknowledgement that nothing is in flight, and tell them when the
  run is done; fall back to asking the user when no peer answers. A run from a
  dirty tree carries their work to the hosts, and is reported as such.
- **Coordinate with peer sessions in the checkout:** when a peer asks what you
  are working on, answer in one line with the theme, the paths you edit, and the
  applies you plan; when a check or test reveals a defect in a peer's area, send
  that peer the evidence and the proposed fix instead of fixing it yourself,
  unless the user directs otherwise.
- **Verify push state before reporting it:** a remote-tracking ref
  (`origin/<branch>`) reflects this checkout's last fetch or push, not the
  remote, so a push made from another clone, session, or the web UI is invisible
  to `git log origin/<branch>..`. Before listing unpushed commits or offering a
  pre-push review, read the remote tip
  (`git ls-remote origin refs/heads/<branch>` does so without touching local
  refs; a fetch also works) or ask whether the user already pushed, and report
  what the check showed rather than the stale ref. Spell the full ref: a bare
  branch name is a tail pattern that also matches `refs/for/<branch>` or a tag
  of that name, and a stray ref then reports a tip the branch never had.

### Problem solving patterns and processes

When you're tasked with solving a problem, you MUST fully understand the problem
scope:

- Don't make facts up.
- **A name match is not deployment evidence:** a grep hit on a tool's name (a
  port variable, an image pin kept for dependency tracking) does not show the
  tool is deployed. Before stating that something is in use, confirm a service
  definition (a Compose template, a systemd unit, an enabled Nix module option)
  and, where possible, the running state.
- **A cached artifact may still be in use:** before proposing to delete a
  container image or a store path, find which scripts and pin files resolve to
  it; a local script can read the version a CI workflow file pins rather than
  the one the latest bump commit names.
- **Verify third-party behavior against the version in use:** before
  recommending a change that depends on how a tool, module, or service behaves,
  read its source or documentation at that version (for example, the module file
  inside the container image that runs it). Label what you did not verify as an
  expectation.
- **Prefer the smallest fix at the point of failure:** before proposing to move,
  reorder, or restructure existing tasks or code, establish why the current
  arrangement exists (history, comments, or asking), and consider a local fix
  first.
- Ask clarifying questions if needed.
- **Access to information:** When you cannot get access to data or information
  you need, you MUST stop and tell the user.
- **Re-scan before executing a planned migration step:** commits landed after
  the plan was drafted can add instances of the patterns it targets or modify
  files it enumerates. Before each step, re-scan the working tree against the
  step's target patterns and reconcile the plan if the matches or target files
  changed.
- **Apply changes to live state with evidence at every step:** before a change
  that can damage a service's state, take a copy through the service's own
  backup path; dry-run when the tool offers it and review the predictions for
  deletions, teardowns, and replacements; rehearse restores and rollbacks on a
  scratch copy, never on live state; after the apply, verify with read-only
  checks and report that evidence rather than the exit status.
- **Distinguish pre-existing failures from regressions:** when a dry-run, check,
  or test fails, determine whether the failure predates your change (it
  reproduces on the unchanged code, or your change never touched the failing
  element) before attributing it to your work. Report which case it is with the
  evidence, and propose how to handle a pre-existing failure instead of silently
  working around it.
- **Capture full output of long-running checks:** redirect the complete output
  of long-running commands (linters, builds, test suites) to a log file and
  inspect the file instead of piping through `tail` or `head`: filters discard
  the evidence needed to diagnose failures, and in a pipeline the filter's exit
  status masks the command's real one. When a summary table reports verdicts,
  filter on the verdict column (`grep -iE 'fail|error'`, after confirming the
  spelling the tool prints), never on an expected list of tool names: the tool
  left out of the list is the one that failed.
- **Check disk headroom before and during long builds:** read the free space on
  the host that runs the step (the Docker host for image builds) before an image
  build, a pull, or a test suite, and check it first when a step fails on a
  write or stalls. A full disk surfaces as unrelated symptoms (a tool failing to
  download its database, a version check exiting 128), and a build client was
  observed to stall after BuildKit's metadata write failed on it.
- **A quiet step is not a hang:** before canceling a long-running step, find the
  tool's own progress signal (BuildKit prints byte counters for image pulls, but
  a layer fetched from a registry build cache showed only the periodic step
  marker until it completed), sample network and disk growth over several
  minutes rather than seconds, and set a bounded wait; a canceled download may
  discard the partial transfer.
- **Run suites that write into the checkout one at a time:** when test suites
  install into, or write output under, the shared working tree, run them
  sequentially or each from its own worktree; concurrent runs read each other's
  artifacts and fail on them.
- **Spot-check a delegated report before relaying it:** verify the claims a
  subagent's recommendation rests on against the file or tool it cites, and keep
  what you did not verify labeled as the agent's claim.

### Shell

Agent shells run Zsh with the user's profile.

- **Zsh does not split unquoted variables into words:** a command prefix stored
  in a variable fails with "command not found"; use a function or an array.
- **Zsh ties lowercase arrays to uppercase parameters:** `path`, `fpath`,
  `cdpath`, `manpath`, `mailpath`, `module_path`, and `psvar` mirror `PATH`,
  `FPATH`, and so on. Never use them as loop or scratch variable names:
  `while read -r path` replaces the command search path and every following
  external command fails with "command not found".
- **The profile defines `diff` as a function wrapping `git diff`:** use
  `command diff` or `cmp` to compare files.
- **`set -e` is inert under the harness's `eval`:** Claude Code's Bash tool runs
  the command through `eval` inside an AND-list, where Zsh ignores `ERR_EXIT`,
  and a subshell inherits that. Run a multi-step state-changing sequence as a
  separate process (`zsh -ec '...'`, which honours `-e` but does not load the
  interactive profile, so its functions and aliases are unavailable), or chain
  the steps with `&&`, so a failing step stops the later ones.
- **A process-pattern kill matches the shell that contains it:** an unanchored
  pattern also matches the command line of the shell running the command that
  holds it, so `pkill -f` kills the harness shell, or a background job, and
  `pgrep -f` reports it as a false positive. List first with
  `pgrep -af <pattern>`, drop the shell lines (this session's and peer
  sessions'), and kill the remaining PIDs, or anchor the pattern to argv[0]
  exactly as the listing shows it (`^/usr/bin/docker ...` when the listing shows
  a path). A client that delegates to a child does the work there
  (`docker buildx build` runs `/usr/libexec/docker/cli-plugins/docker-buildx`),
  so kill the child or the process tree, or cancel through the client, rather
  than the parent alone.
- **`curl` needs `--fail` when its success gates the next step:** without it,
  HTTP error responses (404, 500) still exit 0, so
  `curl -X POST ... && echo done` reports success for a request the server
  rejected.
- **Beware early-exiting pipe consumers under `pipefail`:** a consumer that
  exits at the first match (`grep -q`, `head`) closes the pipe while the
  producer is still writing; with large output the producer fails with a write
  error (cURL exit code 23) and, under `pipefail`, fails the whole pipeline
  despite the match succeeding. When the exit status matters, use a consumer
  that reads the full stream (`grep <pattern> > /dev/null`).
- **Pass explicit non-interactive flags to CLI tools in scripts and background
  tasks:** CLIs that create commits, mail reviews, or resolve merges often
  default to opening `$EDITOR`, a pager, or a confirmation prompt. Before
  scripting or backgrounding such a tool, verify its non-interactive flags from
  `--help` or the relevant skill reference, and never fall back to a bare
  invocation when a guessed flag fails.

### Terminology

- Don't use GCP as an acronym for Google Cloud when writing text in natural
  language. Use the extended form: Google Cloud.
- Avoid colloquial, hyperbolic, or absolute metaphors like "X is king", or "king
  of Y" to describe preferred or best options. Use professional, objective, and
  descriptive language instead (e.g., "preferred", "most effective",
  "standard").

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

- Operating system:
  - **NixOS**: declarative and repeatable configurations.
  - **Debian**: former preferred choice.
