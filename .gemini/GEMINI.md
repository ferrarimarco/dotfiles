# Gemini configuration file

## Rules

### General & Communication

- **Planning Phase:** Before executing any action or gathering information via
  tools, you MUST explain your plan in great detail.
- **Permission Required:** You MUST ask for explicit permission before applying
  any file modifications or executing system commands that change state.
- **Tone:** Keep responses concise, direct, and professional. Avoid
  conversational filler or unnecessary apologies.

### File Format

- When creating or editing text files:
  - Ensure the file ends with a single final newline.
  - Do not add or leave any trailing whitespace on any lines.
  - Strictly match the existing indentation style of the file or project.

### Git

- When creating Git commit messages, strictly follow the
  [Conventional Commits 1.0.0 spec](https://www.conventionalcommits.org/en/v1.0.0/#specification).
- Use standard types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`,
  `chore`.
- Write the subject line in the imperative mood (e.g., "feat: add user auth",
  not "added" or "adds").
- The first line (subject) must not exceed 50 characters.
- Add a blank line after the first line.
- Each line of the commit body after the first must not exceed 72 characters.

### Safety

- Never execute destructive commands (e.g., `rm -rf`, `git push --force`) or
  modify sensitive credentials without an explicit user directive to do so.
