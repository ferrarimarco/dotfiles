---
name: troubleshoot-host
description:
  Investigate an unresponsive, frozen, or crashed host after recovery. Use when
  a machine stopped responding, froze, kernel-panicked, rebooted unexpectedly,
  or required a manual power cycle, and the user wants to know why and how to
  prevent it.
license: MIT
---

# Troubleshoot an Unresponsive Host

Evidence-first methodology for post-incident investigation of a host that froze,
crashed, or stopped accepting connections. The goal is a defensible timeline and
root-cause hypothesis, with the honest fallback "silent freeze, no precursors"
when the evidence supports nothing stronger.

## 1. Establish the Timeline

- `uptime` and `last -x reboot shutdown` for the recovery boot time.
- `journalctl --list-boots`: the **end timestamp of the previous boot** is the
  last moment the system was alive enough to log.
- Read the tail of the previous boot (`journalctl -b -1 | tail`): an abrupt end
  mid-routine-activity with no shutdown sequence indicates a hard freeze; an
  orderly shutdown sequence indicates something else.
- Narrow the death window using **known periodic activity as a clock**: a timer
  or cron job that fires every N minutes and whose last run appears in the log
  bounds the freeze to within one period.

## 2. Sweep for Precursors

- `journalctl -b -1 -p err` over the whole previous boot; separate chronic noise
  (repeating for days) from anything that first appears near the end.
- Kernel signatures:
  `journalctl -b -1 -k | grep -iE "voltage|throttl|oom|hung|I/O error|BUG|Oops|segfault|reset|disconnect"`.
- Crash persistence: `/sys/fs/pstore/` and `/var/lib/systemd/pstore/`.
- Platform-specific state: on Raspberry Pi, `vcgencmd get_throttled` (sticky
  bits reset on power cycle) and `sudo vclog --msg`; on servers, IPMI/SEL logs;
  on laptops or desktops, EC or ACPI events.
- Storage health: `smartctl -H -A` on every disk; pending or uncorrectable
  sectors are a finding even when unrelated to the incident.

## 3. Use Monitoring History

If the host (or fleet) runs a metrics backend, query the time series leading up
to the death window: temperature, load, memory available, disk I/O. Normal
metrics until the end are themselves evidence: they rule out thermal runaway,
OOM spirals, and load storms. Note when the last scrape happened; it
independently bounds the freeze time.

## 4. Check Recovery-Boot Health

- `dmesg | grep -iE "ext4|xfs|recover|orphan|error"`: journal recovery and
  orphan-inode cleanup confirm an unclean stop; failed recovery is its own
  incident.
- `systemctl --failed` and the service manager's view of workloads (containers,
  timers) after the reboot.
- Confirm the sticky throttle/undervoltage flags are clean post-boot.

## 5. Report Honestly

- State the death window and the evidence for it.
- List what the incident was **not** (thermal, OOM, undervoltage, disk I/O),
  with the checks that rule each out.
- A silent hard freeze at normal load and temperature typically leaves no trace;
  say so rather than forcing a root cause. Likely candidate causes (power
  transient, platform or firmware bug, aging kernel) can be listed as
  hypotheses, clearly labeled.
- Separate **resilience fixes** (hardware watchdog so the host self-recovers;
  see the `systemd-developer` skill) from **root-cause fixes** (kernel or
  firmware updates, hardware replacement), and propose both.
- Record secondary findings surfaced along the way (failing disks, broken units,
  stale exporters) even when unrelated to the incident.
