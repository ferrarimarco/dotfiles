---
name: git-semantic-committer
description: Use when writing or formatting Git commit messages to enforce Conventional Commits rules, max line lengths, and standard semantic types.
---

# Git Semantic Committer

This skill enforces strict formatting rules for all Git commit messages created in this workspace.

## Rules

- When creating Git commit messages, strictly follow the [Conventional Commits 1.0.0 spec](https://www.conventionalcommits.org/en/v1.0.0/#specification).
- Use standard types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- Write the subject line in the imperative mood (e.g., "feat: add user auth", not "added" or "adds").
- The first line (subject) must not exceed 50 characters.
- Add a blank line after the first line.
- Each line of the commit body after the first must not exceed 72 characters.
