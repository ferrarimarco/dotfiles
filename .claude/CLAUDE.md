# Claude configuration file

@~/.agents/AGENTS.md

## Claude Code specifics

- The permission classifier can deny an already-approved command without showing
  a prompt. When that happens, offer both remedies: the exact command for the
  user to run with the `!` prefix (one-off), and, when the same class of command
  will recur, a Bash permission rule in the settings or a permission mode change
  so future approvals surface as prompts instead of denials. Never restructure
  the command to slip past the denial.
- Subagents inherit the session model unless the Agent tool call passes `model`.
  Apply the model-tier rule of `~/.agents/AGENTS.md` through that argument:
  `haiku` for the small tier, `sonnet` for the mid tier, `opus` for the top
  tier, and for the pre-push diff review `fable` when the session runs on Fable
  and `opus` otherwise. The `CLAUDE_CODE_SUBAGENT_MODEL` setting supplies the
  mid-tier default when the argument is omitted; it does not reach the built-in
  Explore and Plan agents, so pass the argument to them.
- For a command expected to exceed the Bash tool's two-minute default, pass
  `timeout` (up to ten minutes) or wait on a condition with Monitor; start a
  longer run with `run_in_background` and redirect its output to a log file. A
  foreground call that outlives its timeout was moved to the background with an
  empty output file (observed on Claude Code 2.1.311, not documented; a run that
  outlives its timeout shows it).
- Unlike a background command, a subagent needs no wait: its completion arrives
  as a harness notification, as the Agent and ScheduleWakeup tool descriptions
  state, so never wait on its task output file with a loop that greps for a
  completion marker: the file can stay a stub and the loop outlives the agent
  (observed on Claude Code 2.1.311; `pgrep -af tasks/` lists such loops).
