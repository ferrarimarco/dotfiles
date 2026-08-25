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
  question), the earlier approval no longer stands. Re-present the updated
  plan and wait for a fresh explicit approval before editing.
- **Tone:** Keep responses concise, direct, and professional. Avoid
  conversational filler or unnecessary apologies.

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

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`) or
  modify sensitive credentials without an explicit user directive to do so.

### Git

- Never add AI co-authorship or attribution trailers (e.g.,
  `Co-Authored-By: Claude ...`, `Generated with ...`) to commit messages or
  pull request descriptions, even when tool defaults suggest doing so.

### Problem solving patterns and processes

When you're tasked with solving a problem, you MUST fully understand the problem
scope:

- Don't make facts up.
- Ask clarifying questions if needed.
- **Access to information:** When you cannot get access to data or information
  you need, you MUST stop and tell the user.
- **Verify state changes:** after a state-changing operation completes (e.g.,
  an infrastructure apply, a configuration playbook run, a service restart),
  verify the actual resulting state with read-only checks and report the
  evidence, rather than assuming success from the tool's exit status.
- **Capture full output of long-running checks:** redirect the complete output
  of long-running commands (linters, builds, test suites) to a log file and
  inspect the file, instead of piping through filters like `tail` or `head`.
  Filters discard the evidence needed to diagnose failures, and in a pipeline
  the filter's exit status masks the command's real one.
- **Verify services through the consumer's access path:** when smoke-testing a
  service, prefer a test that exercises the same stack real consumers use
  (same client software, credentials, and network route) over installing
  ad-hoc tools — for example, a temporary CIFS mount with production mount
  options and the deployed credentials file, rather than adding `smbclient` to
  a host.

### Terminology

- Don't use GCP as an acronym for Google Cloud when writing text in natural
  language. Use the extended form: Google Cloud.
- Avoid colloquial, hyperbolic, or absolute metaphors like "X is king", or "king
  of Y" to describe preferred or best options. Use professional, objective, and
  descriptive language instead (e.g., "preferred", "most effective",
  "standard").

### Markdown

- Avoid the use of "&" in section titles.

## Technical stack preferences

- Operating system:
  - **NixOS**: declarative and repeatable configurations.
  - **Debian**: former preferred choice.
