# AI Agent Instructions

@./.agents/AGENTS.md

## Repository rules

### Agent skills

- Skills live in `.agents/skills/<name>/SKILL.md`, one directory per skill.
- When adding a skill, add a one-line entry to the "Agent skills" section of
  `README.md` under the matching category, keeping categories and entries in
  alphabetical order.
- Create only the files in this repository. The setup script symlinks the whole
  skills directory into the home directory, so a new skill needs no linking;
  never create or repair home-directory symlinks manually.
