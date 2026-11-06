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
  `ExecStartPre` `rm`) with a todo over a directive that fails to parse on older
  hosts.
- `Type=oneshot` for run-to-completion jobs (usually timer-triggered);
  `Type=simple`/`exec` for daemons. `RemainAfterExit=true` keeps a oneshot
  "active" after success when other units depend on its state.
- More than one `ExecStart=` is only valid with `Type=oneshot`: any other type
  makes systemd refuse the unit ("bad unit file setting").
- `RuntimeMaxSec=` has no effect on `Type=oneshot` services; limit them with
  `TimeoutStartSec=`, which covers all `ExecStart=` commands together (disabled
  by default for `Type=oneshot`).
- Starting or restarting a `Type=oneshot` service blocks until its commands
  complete and reports their failure, while `Type=simple`/`exec` return as soon
  as the process starts. For a timer-triggered job, prefer restarting the timer.
- `ExecStart=` substitutes `$VAR` and `${VAR}` itself, so an `sh -c` body writes
  `$$` for a literal dollar (`$$(systemctl ...)`, `"$$unit"`);
  `systemctl show -p ExecStart` prints the unexpanded line, so the first run's
  journal is the check.
- A finished `Type=oneshot` keeps its invocation ID while the unit stays loaded
  (wanted by an active unit, or `RemainAfterExit=true`; observed on systemd 247
  and 252): an unreferenced oneshot is unloaded once inactive and the ID is
  gone. `systemctl show -p InvocationID --value <unit>` returns that run's ID,
  and `journalctl _SYSTEMD_INVOCATION_ID=<id>` after `journalctl --sync` returns
  its output without the manager's "Starting"/"Finished" lines.

## Dependencies and Triggers

- `[Install] WantedBy=<mount unit>` (the escaped mount path from
  `systemd-escape --path --suffix=mount`) runs a unit on every start of the
  mount: at boot, from a retry, or by `systemctl start`. With
  `RequiresMountsFor=<path>` the unit also requires the mount and orders after
  it, so it never runs while the mount is absent. Wants directories under
  `/etc/systemd/system` apply to the generated fstab mount units too.
- **A failed dependency never shows as `failed`:** it fails the dependent's job
  ("Dependency failed for ...") and leaves the dependent inactive, so a
  failed-unit alert never fires for it; alert on the dependency (an
  expected-mount alert) instead.
- **`Requires=` propagates stops and restarts:** a unit that requires a daemon
  is stopped or restarted whenever that daemon is explicitly stopped or
  restarted (systemd.unit(5)), including by a deployment that rebuilt it; a unit
  holding runtime state that must outlive those restarts (a published export, a
  running job) uses `Wants=` with `After=` and, under NixOS,
  `restartIfChanged = false` so a redeploy of its own definition leaves it
  running too. A timer-driven job that should follow its daemon keeps
  `Requires=`, as the Timers section says.
- **A paced restart loop never samples as `failed`:** a unit whose `Restart=`
  pacing stays under the start rate limit (default 5 starts per 10 s;
  `StartLimitIntervalSec=0` disables it) alternates `activating (auto-restart)`
  and brief runs; its `failed` state lasts only through the manager's transition
  into `activating (auto-restart)`, so `systemctl --failed` and exporters never
  catch it while the journal logs each run's "Failed with result". One that
  trips the limit does stay failed (`systemctl show -p Result` says
  `start-limit-hit`).
- **Alert on the share of time in `activating` to catch the paced loop:**
  average the node exporter's `node_systemd_unit_state{state="activating"}`
  (needs `--collector.systemd`) over a window longer than the longest legitimate
  start (a long `ExecStartPre=`, a `Type=notify` service waiting on a
  dependency), with the threshold above the share one such start reaches.
  Exclude `Type=oneshot` units (`type!="oneshot"`), which are `activating` for
  their whole run (a looping oneshot then goes unseen too), and the
  `user@.service` managers, which on systemd 247 and 252 were observed
  `activating` through logins; confirm with `systemctl status user@<uid>` on the
  version in use.
- systemd never retries a failed mount unit, and `nofail` turns the target's
  requirement into a want and drops the ordering, so the boot reaches
  `remote-fs.target` without it. Retry with a timer whose service runs
  `systemctl start --no-block` on failed mount units: a mount that fails again
  (a CIFS mount against a packet-dropping server exceeds the 90 s default start
  timeout before failing; subsequent attempts during the block fail with "Host
  is down", while a refused connection fails immediately) fails its own unit,
  and a mount that succeeds pulls in the units wanted by it.
  `x-systemd.automount` acts on access only and hands the mount error to the
  accessor (nothing accesses an absent share whose consumers are stopped), while
  a mount that appears without a start job (an NFS `bg` mount completing, a
  manual `mount`) marks the mount unit active without starting units wanted by
  it.

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
  at the next boot. That catch-up run fires right after boot, before the
  service's dependencies are necessarily up: give the service `Requires=` and
  `After=` on the daemon it drives (`docker.service`; `After=` alone orders
  without pulling in) and `RequiresMountsFor=` the paths it uses, or the first
  run after an outage fails on a missing mount. `RequiresMountsFor=` covers only
  mounts systemd manages (fstab entries, `.mount` units): for a path another
  service mounts (a ZFS dataset via `zfs-mount.service`, a mergerfs pool, a
  directory a container populates), add `After=` on that service, or guard the
  run with `ConditionPathIsMountPoint=`.
- A timer fails to start with a generic "Job failed" when the service it
  activates is invalid: verify the service unit, not only the timer.
- **A transient timer elapses within `AccuracySec=`, one minute by default:**
  `systemd-run --on-active=<delay>` fires up to a minute late unless the unit
  gets `--timer-property=AccuracySec=1s`, so a test asserting the delay sees the
  lag (systemd.timer(5)).
- **Cancelling a pending transient run stops the timer and the service:** the
  timer may already have fired and the service be running, so stop both
  (`systemctl stop <unit>.timer <unit>.service`) rather than the timer alone.

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
