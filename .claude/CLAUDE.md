# Claude configuration file

@~/.agents/AGENTS.md

## Claude Code specifics

- The permission classifier can deny an already-approved command without
  showing a prompt. When that happens, offer both remedies: the exact command
  for the user to run with the `!` prefix (one-off), and, when the same class
  of command will recur, a Bash permission rule in the settings or a
  permission mode change so future approvals surface as prompts instead of
  denials. Never restructure the command to slip past the denial.
