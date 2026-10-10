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
- **Tone:** Keep responses concise, direct, and professional. Avoid
  conversational filler or unnecessary apologies.
- **Show file paths in text:** When referencing files in responses, include the
  path as inline code (`~/path/to/file` under the user's home directory, or
  `/path/to/file` otherwise) in the visible text rather than relying solely on
  `file://` Markdown links, because chat UIs collapse `file://` links to the
  basename.

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

### File Format

- When creating or editing text files:
  - Ensure the file ends with a single final newline.
  - Do not add or leave any trailing whitespace on any lines.
  - Strictly match the existing indentation style of the file or project.
- **Minimize diff in suggested edits:** when proposing edits in suggest or
  review mode (such as Google Docs Suggest Mode), target the smallest unique
  word or phrase span around each change rather than replacing whole sentences
  or paragraphs, and keep each replacement within a single formatting run (for
  example, separate a bold prefix from its unbolded body).
- **Re-read before editing again after a formatter ran:** formatters rewrap
  prose, pad table cells, and reflow code, so exact-match edits computed from
  the pre-format text fail. Make all the edits first and format once, or re-read
  the file after formatting, and match table content by name rather than by
  padded cell text.

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`) or
  modify sensitive credentials without an explicit user directive to do so.
- Pin third-party GitHub Actions to a full commit SHA, with the release in a
  trailing comment (e.g., `uses: owner/action@<sha> # v1.2.3`). Resolve the SHA
  from the release tag instead of writing it from memory.
- Treat identifiers that public infrastructure resolves to a network location
  (for example, Syncthing device IDs, which global discovery maps to a device's
  current public addresses) as private material: keep them out of public
  repositories, even though they grant no authentication. Such identifiers, and
  other personal names, also surface as metric labels and alert annotations:
  private sinks (a local TSDB, a private notification channel) may carry them,
  but committed monitoring artifacts — alert rule expressions, dashboards — must
  stay generic and reference public names only.

### Git

- Never add AI co-authorship, attribution, or session-link trailers (e.g.,
  `Co-Authored-By: Claude ...`, `Generated with ...`, `Claude-Session: ...`) to
  commit messages or pull request descriptions, even when tool defaults suggest
  doing so.
- **Propose commits before executing:** when asked to commit or amend, propose
  the commit split (which files go in which commit) and the full commit
  messages, then wait for approval. A plan approval covers the edits, never the
  commit, even when the plan ends with a commit step: present the split and the
  messages and wait, also late in a long session. The `git-commit` skill holds
  the full procedure, including the subject length limit: load it before
  drafting the messages.
- **Focus commit and changelist descriptions on why:** keep commit and
  changelist descriptions concise and focused on why the change is needed (the
  problem or constraint it solves) rather than cataloging what the diff already
  shows.
- **Offer a fresh-subagent review on non-trivial changes before pushing:**
  before pushing a non-trivial change for review — or pushing a new patchset and
  resolving review comments when the change touches logic, control flow,
  permissions, or multi-step automation — offer to run a subagent with no
  conversation context over the entire diff against the base branch and the
  commit messages, not only the latest additions. Skip this for trivial edits
  (typos, formatting, version bumps, or mechanical one-liners) to avoid
  unnecessary token and latency cost.
- **Expect concurrent sessions in the same checkout:** other sessions may edit
  and commit while you work. Before staging, committing, rebasing, or building
  generated output, check the status and the log for changes you did not make,
  keep them out of your work, and report them. Before a rebase, save the working
  tree diff outside the repository, and afterward verify that the uncommitted
  changes survived. Generated output that a build produces from the working tree
  includes the uncommitted and untracked sources of every session: when the
  output must reflect committed sources only, build it in a temporary worktree
  checked out at the target commit. After another session rewrites history,
  verify your commits before building on them: use the reflog to find the
  commits they replace, and compare their changes and messages.

### Problem solving patterns and processes

When you're tasked with solving a problem, you MUST fully understand the problem
scope:

- Don't make facts up.
- **A name match is not deployment evidence:** a grep hit on a tool's name in
  configuration (a port variable, an image pin kept for dependency tracking)
  does not show the tool is deployed. Before stating that something is in use,
  confirm a service definition (a Compose template, a systemd unit, an enabled
  Nix module option) and, where possible, the running state.
- **Verify third-party behavior against the version in use:** before
  recommending a change that depends on how a tool, module, or service behaves,
  read its source or documentation at the version in use (for example, the
  module file inside the container image that runs it). Label what you did not
  verify as an expectation.
- **Prefer the smallest fix at the point of failure:** before proposing to move,
  reorder, or restructure existing tasks or code, establish why the current
  arrangement exists (history, comments, or asking), and consider a local fix
  first.
- Ask clarifying questions if needed.
- **Access to information:** When you cannot get access to data or information
  you need, you MUST stop and tell the user.
- **Dry-run before applying:** when a tool offers a dry-run or check mode (e.g.,
  Ansible `--check --diff`, `terraform plan`), run it before the state-changing
  run and review the predicted changes for unintended destructive effects
  (deletions, teardowns, replacements), not just for errors. Treat an unexpected
  destructive prediction as a bug to root-cause before applying.
- **Distinguish pre-existing failures from regressions:** when a dry-run, check,
  or test fails, determine whether the failure predates your change (e.g., it
  reproduces on the unchanged code, or the failing element is one your change
  never touched) before attributing it to your work. Report which case it is,
  with the evidence, and propose how to handle a pre-existing failure instead of
  silently working around it.
- **Verify state changes:** after a state-changing operation completes (e.g., an
  infrastructure apply, a configuration playbook run, a service restart), verify
  the actual resulting state with read-only checks and report the evidence,
  rather than assuming success from the tool's exit status. A service unit
  reporting active does not guarantee the service accepts requests: verification
  probes issued right after activation need bounded retries. After a reboot or
  restart, derive the list of running services from a fresh listing and report
  only what it shows: never carry an earlier "up" forward; a service absent from
  the new listing is a finding to report, not a gap to fill from the earlier
  one.
- **Capture full output of long-running checks:** redirect the complete output
  of long-running commands (linters, builds, test suites) to a log file and
  inspect the file, instead of piping through filters like `tail` or `head`.
  Filters discard the evidence needed to diagnose failures, and in a pipeline
  the filter's exit status masks the command's real one.
- **`curl` needs `--fail` when its success gates the next step:** without it,
  HTTP error responses (404, 500) still exit 0, so a verification like
  `curl -X POST ... && echo done` reports success for a request the server
  rejected.
- **Beware early-exiting pipe consumers under `pipefail`:** a consumer that
  exits at the first match (`grep -q`, `head`) closes the pipe while the
  producer is still writing; with large output the producer then fails with a
  write error (for example cURL exit code 23) and, under `pipefail`, fails the
  whole pipeline despite the match succeeding. When the pipeline's exit status
  matters, use a consumer that reads the full stream (for example
  `grep <pattern> > /dev/null`).
- **Fetching web pages from the agent shell:** some sites reject every
  unauthenticated route (web, mobile, API, JSON): after two failed routes, ask
  for pasted content or a saved PDF instead of retrying. Short links from
  sharing services may land on an interstitial page; the target is usually in
  the canonical link of the returned page. Sites behind bot protection usually
  answer 403 to cURL and to fetch tools. When a documentation site returns a
  placeholder (JavaScript-only, such as the Terraform Registry) or truncated
  content, fetch the source from the project's repository at the version in use
  instead of guessing raw URLs: list a directory with
  `gh api 'repos/<org>/<repo>/contents/<dir>?ref=<tag>'`, then download a file
  with the same endpoint on the file path and
  `-H 'Accept: application/vnd.github.raw+json'`. When the placeholder page
  hides the repository link, the site's JSON API usually names it (the Terraform
  Registry does in the `source` field of
  `registry.terraform.io/v1/modules/<ns>/<name>/<provider>` and
  `/v1/providers/<ns>/<name>`).
- **Agent shells run Zsh with the user's profile:** Zsh does not split unquoted
  variables into words, so a command prefix stored in a variable fails with
  "command not found"; use a function or an array instead. Zsh also ties the
  lowercase arrays `path`, `fpath`, `cdpath`, `manpath`, `mailpath`,
  `module_path`, and `psvar` to the uppercase scalar parameters (`PATH`,
  `FPATH`, ...), so never use them as loop or scratch variable names:
  `while read -r path` replaces the command search path and every following
  external command fails with "command not found". The profile defines `diff` as
  a function that wraps `git diff`; use `command diff` or `cmp` to compare
  files. `set -e` is inert when the harness runs the command through `eval`
  inside an AND-list (Claude Code's Bash tool does): Zsh ignores `ERR_EXIT` in
  that context, and a subshell inherits it. Run a multi-step state-changing
  sequence as a separate process (`zsh -ec '...'`, which honours `-e` but does
  not load the interactive profile, so its functions and aliases are unavailable
  inside), or chain the steps with `&&`, so a failing step stops the later ones.
- **Verify services through the consumer's access path:** when smoke-testing a
  service, prefer a test that exercises the same stack real consumers use (same
  client software, credentials, and network route) over installing ad-hoc tools
  — for example, a temporary CIFS mount with production mount options and the
  deployed credentials file, rather than adding `smbclient` to a host.

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

### Google Docs

- Use the `TITLE` style for the document title and start top-level sections at
  `HEADING_1` style.
- Preserve the document's native named styles (`NORMAL_TEXT`, `TITLE`,
  `HEADING_1`–`HEADING_3`) by omitting explicit font family, font size, color,
  and paragraph spacing overrides on prose and headings.
- **Insert plain text before applying inline code or emphasis styles:** in
  Google Docs API batch updates, each `insertText` inherits the character style
  of the preceding character, and in Suggest Mode an `updateTextStyle` request
  setting the base font is ignored as a no-op against `NORMAL_TEXT`. When
  inserting paragraphs that mix prose and inline code (`Courier New`), insert
  the full unstyled paragraph text first so it inherits `NORMAL_TEXT`, then
  apply `Courier New` or bold to specific inline spans afterward.

## Technical stack preferences

- Operating system:
  - **NixOS**: declarative and repeatable configurations.
  - **Debian**: former preferred choice.
