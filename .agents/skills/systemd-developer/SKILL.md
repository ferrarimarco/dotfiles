---
name: systemd-developer
description: >-
  Develop and debug systemd units, timers, sandboxing, and watchdogs. Use when
  creating, updating, or debugging systemd services, timers, unit hardening and
  security directives, state directories, or watchdog configuration, whether the
  units are delivered via Ansible templates, Nix modules, or plain unit files.
license: MIT
---

# systemd Developer

This skill provides expertise in authoring systemd units that are robust across
reboots, properly sandboxed, and debuggable. It applies regardless of the
delivery mechanism (Ansible templates, NixOS modules, plain files).

## Execution Model

- `ExecStartPre` commands run in order before `ExecStart`, but **after** the
  service's execution environment (mount namespace, state directories, users) is
  fully assembled. Setup that the environment depends on cannot be done in
  `ExecStartPre`.
- `StandardOutput=`/`StandardError=` apply to **all** `Exec*` commands, not just
  `ExecStart`. With `StandardOutput=file:`, output from `ExecStartPre` lands in
  the same file and is invisible in the journal; account for this when debugging
  and when the file's content matters (e.g., metrics files).
- `StandardOutput=file:` opens the file and writes from offset zero without
  truncating; `truncate:` (systemd >= 248) and `append:` variants change that
  behavior. Before using a directive, check the **oldest** systemd version in
  the fleet (`systemctl --version`); prefer a portable workaround (e.g., an
  `ExecStartPre` `rm`) with a TODO over a directive that fails to parse on older
  hosts.
- `Type=oneshot` for run-to-completion jobs (usually timer-triggered);
  `Type=simple`/`exec` for daemons. `RemainAfterExit=true` keeps a oneshot
  "active" after success when other units depend on its state.

## Sandboxing and State Directories

- Mount-namespace directives (`ProtectSystem=`, `ReadWritePaths=`,
  `ReadOnlyPaths=`, `ProtectHome=`, `PrivateTmp=`) are assembled **before any
  `Exec*` command runs**. They can never reference a path that an `ExecStartPre`
  is supposed to create: namespace setup fails first with `status=226/NAMESPACE`
  ("Failed to set up mount namespacing: ... No such file or directory").
- Use `RuntimeDirectory=`, `StateDirectory=`, `CacheDirectory=`, and
  `LogsDirectory=` instead of `mkdir` in `ExecStartPre`: systemd creates these
  directories **before** namespace assembly and implicitly marks them writable,
  so they compose correctly with `ProtectSystem=strict`.
- `/run` is tmpfs: `RuntimeDirectory=` content disappears on every reboot.
  Anything that must survive a reboot (virtual environments, caches worth
  keeping, stamp files) belongs in `StateDirectory=` (`/var/lib/<name>`).
- A unit that "works until the first reboot" and then fails permanently is the
  classic symptom of runtime state (in `/run`) being referenced by a directive
  that requires the path to exist.
- `ProtectHome=tmpfs` mounts read-only empty filesystems over home directories:
  tools that write caches under `$HOME` (e.g., pip) degrade gracefully or need
  `CacheDirectory=` plus an environment override.

## Timers

- Prefer timer + service pairs over cron entries: they inherit the unit's
  sandboxing, logging, and dependency handling.
- `OnCalendar=` expressions can be validated with
  `systemd-analyze calendar '<expr>'`.
- Add `Persistent=true` when a missed activation (host powered off) should run
  at the next boot.

## Watchdogs

- **Hardware watchdog** (system-level): `RuntimeWatchdogSec=` in
  `/etc/systemd/system.conf` arms the platform watchdog device; a hard kernel
  freeze then causes an automatic reset instead of requiring a manual power
  cycle. Verify with `systemctl show -p RuntimeWatchdogUSec` and check the
  watchdog device exists (`/dev/watchdog`).
- **Service watchdog** (per-unit): `WatchdogSec=` requires the service to call
  `sd_notify(WATCHDOG=1)` periodically; only add it to programs that actually
  implement the protocol.

## Debugging

- `systemctl cat <unit>` shows the unit as loaded (including drop-ins);
  `systemctl show <unit> -p <Property>` shows effective values.
- `systemd-analyze verify <unit-file>` catches syntax and reference errors;
  `systemd-analyze security <unit>` scores sandboxing coverage.
- Decode `status=2xx` exit codes from the `EXIT_STATUS` table in
  `systemd.exec(5)`: `226/NAMESPACE` means namespace assembly failed (usually a
  missing path in a mount directive), `203/EXEC` a missing or non-executable
  binary, `217/USER` an unknown user.
- For unit forensics use `journalctl -u <unit> -b <boot>`; remember that
  `StandardOutput=file:` redirections hide command output from the journal.
