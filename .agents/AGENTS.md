# AI Agent Instructions

## Rules

### Communication

- **Discovery Phase:** You may autonomously use read-only tools (e.g.,
  searching, reading files, running non-modifying shell commands) to gather
  information without asking for permission or explaining your plan beforehand.
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

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`) or
  modify sensitive credentials without an explicit user directive to do so.
- Pin third-party GitHub Actions to a full commit SHA, with the release in a
  trailing comment (e.g., `uses: owner/action@<sha> # v1.2.3`). Resolve the SHA
  from the release tag instead of writing it from memory.
- Treat identifiers that public infrastructure resolves to a network location
  (for example, Syncthing device IDs, which global discovery maps to a device's
  current public addresses) as private material: keep them out of public
  repositories, even though they grant no authentication. Such identifiers,
  and other personal names, also surface as metric labels and alert
  annotations: private sinks (a local TSDB, a private notification channel)
  may carry them, but committed monitoring artifacts — alert rule
  expressions, dashboards — must stay generic and reference public names
  only.

### Git

- Never add AI co-authorship, attribution, or session-link trailers (e.g.,
  `Co-Authored-By: Claude ...`, `Generated with ...`, `Claude-Session: ...`) to
  commit messages or pull request descriptions, even when tool defaults suggest
  doing so.
- **Propose commits before executing:** when asked to commit, propose the commit
  split (which files go in which commit) and the full commit messages, then wait
  for approval. The `git-commit` skill holds the full procedure.
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
  probes issued right after activation need bounded retries.
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
  write error (for example curl exit code 23) and, under `pipefail`, fails the
  whole pipeline despite the match succeeding. When the pipeline's exit status
  matters, use a consumer that reads the full stream (for example
  `grep <pattern> > /dev/null`).
- **Agent shells run zsh with the user's profile:** zsh does not split unquoted
  variables into words, so a command prefix stored in a variable fails with
  "command not found"; use a function or an array instead. The profile defines
  `diff` as a function that wraps `git diff`; use `command diff` or `cmp` to
  compare files.
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
  not `# 1. Heading` or `## 2.1 Heading`).

### Google Docs

- Use the `TITLE` style for the document title and start top-level sections at
  `HEADING_1` style.
- Preserve the document's native named styles (`NORMAL_TEXT`, `TITLE`,
  `HEADING_1`–`HEADING_3`) by omitting explicit font family, font size, color,
  and paragraph spacing overrides on prose and headings.

## Technical stack preferences

- Operating system:
  - **NixOS**: declarative and repeatable configurations.
  - **Debian**: former preferred choice.
