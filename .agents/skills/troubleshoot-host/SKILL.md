---
name: troubleshoot-host
description: >-
  Investigate host and service incidents: a machine that stopped responding,
  froze, kernel-panicked, rebooted unexpectedly, or required a manual power
  cycle, and running services that misbehave against their configuration or
  their network. Use when the user wants to know why and how to prevent it.
license: MIT
---

# Troubleshoot a Host

Evidence-first methodology for investigating host and service incidents.
Sections 1 to 5 cover post-incident forensics of a host that froze, crashed, or
stopped accepting connections: the goal is a defensible timeline and root-cause
hypothesis, with the honest fallback "silent freeze, no precursors" when the
evidence supports nothing stronger. Section 6 covers live services that run but
misbehave.

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
  `-k` implies the current boot even with `--since`: a search across boots uses
  `journalctl _TRANSPORT=kernel --since <date>` instead, or it silently returns
  one boot's worth.
- Crash persistence: `/sys/fs/pstore/` and `/var/lib/systemd/pstore/`.
- Platform-specific state: on Raspberry Pi, `vcgencmd get_throttled` (sticky
  bits reset on power cycle) and `sudo vclog --msg`; on servers, IPMI/SEL logs;
  on laptops or desktops, EC or ACPI events.
- Storage health: `smartctl -H -A` on every disk; pending or uncorrectable
  sectors are a finding even when unrelated to the incident.

## 3. Use Monitoring History

Start with the alert history: Alertmanager's active alerts and the `ALERTS`
series over the preceding days. An alert that fired before the incident (a SMART
pending-sector alert thirty hours before a disk stopped reading) is the first
lead, and an alert that fired and was not acted on is a finding in itself.

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
- Before rebooting a host whose disk is failing, add `nofail` (and
  `x-systemd.device-timeout=`) to every non-root mount the boot can survive
  without, and plan the rescue boot medium: once the disk is gone, systemd waits
  for the device and fails `local-fs.target` into the emergency shell, which
  nobody reaches on a headless host, and which `sulogin` refuses to open when
  root is locked.
- Separate **resilience fixes** (hardware watchdog so the host self-recovers;
  see the `systemd-developer` skill) from **root-cause fixes** (kernel or
  firmware updates, hardware replacement), and propose both.
- Record secondary findings surfaced along the way (failing disks, broken units,
  stale exporters) even when unrelated to the incident.

## 6. When a Live Service Misbehaves

For a service that is running but behaves contrary to its configuration or its
network:

- **The configuration on disk is not necessarily the configuration in effect.**
  Verify what the process actually loaded through its own API or status
  endpoints (active targets, runtime settings), never by reading files. A
  container that bind-mounts a single file keeps serving the old inode after the
  file is atomically replaced, so hot-reload endpoints "succeed" against stale
  content; only a container restart re-binds the file.
- **Suspect connection tracking after network topology changes.** Moving a
  container between published ports and host networking leaves conntrack entries
  that keep translating live flows to the old container address, which another
  container may inherit; continuous traffic (gossip, keepalives) refreshes the
  entries indefinitely. Get evidence with a packet capture
  (`tcpdump -ni any udp port <port>`: a hop onto a bridge interface betrays the
  stale translation), then delete the entries with `conntrack -D` or starve the
  flow for longer than the UDP stream timeout (120 seconds) by stopping the
  sender.
- **Cluster membership is not data flow.** A distributed system reporting
  healthy peers proves connectivity, not replication: verify with an end-to-end
  payload (a replicated record, a deduplicated notification) before declaring it
  healthy.
- **"Input/output error" in an application log usually points below the
  application:** the backing device, or the server or session of a network
  mount. Read the kernel log for that mount first. A mounted filesystem keeps
  answering `df` and directory listings from cache after its disk has stopped
  responding, so those working is no evidence the disk is fine; a read that
  bypasses the page cache (`dd if=<file> iflag=direct`, or a read of the block
  device) settles it.
- **A USB disk stuck in a reset loop is the diagnosis; capture the evidence,
  then power it off.** After the kernel log and a time-bounded `smartctl`, power
  it off before diagnosing anything else on the host: a disk that resets every
  few seconds leaves udev workers and the USB storage thread in uninterruptible
  wait, which strands sibling devices (a serial dongle never gets its `by-id`
  link) and triggers UAS command aborts on other disks of the same controller,
  the host's root disk included.
