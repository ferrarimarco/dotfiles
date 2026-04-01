# Gemini configuration file

## Rules

### General & Communication

- **Access to information:** When you cannot get access to data or information
  you need, you MUST stop and tell me.
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

### File Format

- When creating or editing text files:
  - Ensure the file ends with a single final newline.
  - Do not add or leave any trailing whitespace on any lines.
  - Strictly match the existing indentation style of the file or project.

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`) or
  modify sensitive credentials without an explicit user directive to do so.
