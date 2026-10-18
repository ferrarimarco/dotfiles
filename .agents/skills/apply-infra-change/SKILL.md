---
name: apply-infra-change
description: >-
  Apply a change to a running service or host safely: an infrastructure or
  configuration apply, a version upgrade, a migration, a re-seed, a restore, a
  failover, or a rollback, whether driven by Ansible, Terraform, Nix, Compose,
  or by hand. Use when asked to apply, deploy, upgrade, migrate, restore, or
  roll back a service or host, when a dry-run or check run is about to be
  followed by the real run, or when verifying that such a change took effect.
license: MIT
---

# Apply an Infrastructure Change

Take a change from a reviewed plan to a verified result without damaging live
state along the way. The evidence from each step is what the report carries, not
the exit status of the tool.

## 1. Secure a Pre-Change Copy

Before a change that can damage a service's state (an upgrade across a breaking
release, a re-seed, a migration), run the service's backup job by hand and
record the snapshot it saved, so the copy also exercises the backup and restore
paths (and is encrypted at rest where the backup path encrypts). An ad-hoc
tarball is the fallback where no backup path exists.

## 2. Dry-Run and Review the Predictions

When the tool offers a dry-run or check mode (Ansible `--check --diff`,
`terraform plan`, `docker compose --dry-run up`), run it before the
state-changing run and review the predicted changes for unintended destructive
effects (deletions, teardowns, replacements), not just for errors. Treat an
unexpected destructive prediction as a bug to root-cause before applying.

A Compose stack applied after a gap recreates every container whose image pin
changed since the last run, and an Ansible check run whose pull and `up` are
`command` tasks predicts neither the pull nor the recreation. Before such an
apply, compare each service's pinned image with the image its running container
was created from (`docker inspect --format '{{.Config.Image}}'`) and state which
containers the apply will upgrade, so a change scoped to one service does not
upgrade others unannounced. A string match is conclusive only for digest pins:
with a tag (or `pull_policy: always`), run `docker compose pull` first, then
`docker compose --dry-run up` to see which containers it would recreate.

## 3. Rehearse Recovery Paths on Scratch Targets

A verification of a restore, a migration rollback, or a failover runs against a
copy or a scratch location, never against live state, unless the user asked for
the real operation; an in-place restore run as a rehearsal rolled a live service
back by hours. A dry run of the command proves the command, not the outcome, so
it does not replace the scratch rehearsal.

## 4. Put Detection in Place Before a Fix

When the change fixes a failure that monitoring did not catch, prefer adding or
repairing the check first and confirming it fires on the broken state, then
applying the fix and confirming the check clears. When the fix cannot wait,
reproduce the failure afterwards to exercise the check. A check never exercised
on the real failure is unverified.

## 5. Verify the Resulting State

After the operation completes, verify the actual resulting state with read-only
checks and report the evidence, rather than assuming success from the tool's
exit status.

- A service unit reporting active does not guarantee the service accepts
  requests: verification probes issued right after activation need bounded
  retries.
- An exporter or endpoint answering is not data present: check for the series or
  records its consumers rely on (a metrics exporter can answer scrapes with none
  of the series the alerts use).
- A message bus holding the right retained payloads is not the consumer having
  consumed them: read the consumer's own state store (its registry, its state
  database) before reporting the consumer healthy.
- After a reboot or restart, derive the list of running services from a fresh
  listing and report only what it shows: never carry an earlier "up" forward; a
  service absent from the new listing is a finding to report, not a gap to fill
  from the earlier one.
- A before-and-after difference is reported from a diff of the saved before and
  after outputs, never from counts remembered from different baselines.
- Smoke-test through the consumer's access path: prefer a test that exercises
  the same stack real consumers use (same client software, credentials, and
  network route) over installing ad-hoc tools; for example, a temporary CIFS
  mount with production mount options and the deployed credentials file, rather
  than adding `smbclient` to a host.
