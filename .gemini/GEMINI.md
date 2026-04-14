# Gemini configuration file

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

### Problem solving patterns and processes

When you're tasked with solving a problem, you MUST fully understand the problem
scope:

- Don't make facts up.
- Ask clarifying questions if needed.
- **Access to information:** When you cannot get access to data or information
  you need, you MUST stop and tell the user.

## Technical stack preferences

- Operating system:
  - **NixOS**: declarative and repeatable configurations.
  - **Debian**: former preferred choice.
