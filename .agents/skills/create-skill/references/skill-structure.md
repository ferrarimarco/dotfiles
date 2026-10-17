# Skill Structure

The format is defined by the
[Agent Skills specification](https://agentskills.io/specification). This file
restates the parts an author needs.

## Directory Layout

```text
<name>/
├── SKILL.md      # Required: frontmatter and instructions
├── scripts/      # Optional: executable code the agent can run
├── references/   # Optional: documentation loaded on demand
├── assets/       # Optional: templates, images, data files
└── ...           # Any additional files or directories
```

- `scripts/`: self-contained programs that document their dependencies, recover
  from the conditions they can (create a missing file, fall back to a default),
  and otherwise fail with a message naming what is wrong and what is valid, so
  the agent does not diagnose a stack trace; every constant such as a timeout or
  a retry count is justified in a comment. `SKILL.md` says for each script
  whether the agent runs it or reads it as reference.
- `references/`: focused documents, one topic per file. Agents load them only
  when needed, so smaller files cost less context. State in `SKILL.md` when each
  file should be read. Give files over about 100 lines a table of contents. When
  a skill spans several variants, such as cloud providers, keep the workflow in
  `SKILL.md` and one reference file per variant.
- `assets/`: static resources such as document or configuration templates,
  diagrams, lookup tables, and schemas.

## Frontmatter

| Field           | Required | Constraints                                                                                                                                                                                                                           |
| --------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`          | Yes      | 1 to 64 characters. Lowercase letters, digits, and hyphens only. No leading, trailing, or consecutive hyphens. Must match the directory name.                                                                                         |
| `description`   | Yes      | 1 to 1,024 characters. States what the skill does and when to use it, with keywords that match the requests it should handle. Not in the first or second person (no "I can", "you can"), since it is injected into the system prompt. |
| `license`       | No       | A license name or the name of a bundled license file.                                                                                                                                                                                 |
| `compatibility` | No       | 1 to 500 characters. Only when the skill has real environment requirements: intended product, system packages, network access.                                                                                                        |
| `metadata`      | No       | A map from string keys to string values for properties outside the specification. Use reasonably unique key names.                                                                                                                    |
| `allowed-tools` | No       | Space-separated list of tools pre-approved to run, for example `Bash(git:*) Read`. Experimental; support varies between agents.                                                                                                       |

Claude's platform also rejects the words `anthropic` and `claude` in `name`, and
XML tags in either field.

## Body Content

The Markdown body after the frontmatter has no format restrictions. Recommended
content:

- step-by-step instructions;
- an output-format template when the result has a fixed shape;
- examples of inputs and their outputs;
- common edge cases.

## Context Budgets

Agents load skills progressively:

- Metadata, about 100 tokens: `name` and `description` are loaded at startup for
  every installed skill.
- Instructions, under about 5,000 tokens: the full `SKILL.md` body is loaded on
  activation. Keep it under 500 lines.
- Resources, as needed: files under `scripts/`, `references/`, and `assets/` are
  loaded only when required.

## File References

Reference other files with paths relative to the skill root, for example
`references/skill-structure.md` or `scripts/extract.py`. Keep references one
level deep from `SKILL.md`; avoid chains of references.

Name MCP tools fully qualified (`Server:tool`): a bare name may not resolve when
several servers are loaded.
