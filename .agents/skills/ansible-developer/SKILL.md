---
name: ansible-developer
description:
  Develop declarative, idempotent Ansible roles, playbooks, and inventories.
  Use when the user asks to create, update, or debug Ansible code, roles,
  playbooks, inventory variables, or when you need to develop Ansible
  automation.
license: MIT
---

# Ansible Developer

This skill provides expertise in developing Ansible roles, playbooks, and
inventories that are idempotent, check-mode friendly, and data-driven.

## Core Principles

- **Data-driven roles:** roles consume inventory data (`host_vars` /
  `group_vars` lists and dictionaries) with defaults that make every task a
  no-op on hosts that do not opt in (`| default([])`). Hosts opt in by
  declaring data, not by conditionals scattered in tasks.
- **Idempotency is the contract:** every task must converge to the declared
  state and report `ok` on a second run. A task that flaps between `changed`
  states on consecutive runs is a bug, even if the end state is correct.
- **Fully qualified collection names:** always use FQCNs
  (`ansible.builtin.copy`, `community.general.parted`, `ansible.posix.mount`).

## Read-Then-Act Pattern for Non-Idempotent Modules

When a module cannot converge reliably (for example, `community.general.zfs`
property handling), do not fight it. Build idempotency explicitly:

1. **Read** actual state with a command task registered under
   `changed_when: false` and `check_mode: false` (so the read also runs in
   check mode).
2. **Act** only on the delta, guarding each state-changing task with a `when`
   comparing desired against actual.
3. For property convergence, compare each property individually
   (`zfs get -H -o value <prop>` versus the declared value) and set only the
   ones that differ.

```yaml
- name: List existing ZFS datasets
  ansible.builtin.command: zfs list -H -o name -t filesystem
  register: zfs_datasets_actual
  changed_when: false
  check_mode: false
  become: true

- name: Create missing ZFS datasets
  ansible.builtin.command: zfs create -p {{ item.name }}
  become: true
  when: item.name not in zfs_datasets_actual.stdout_lines
  with_items: "{{ zfs_datasets | default([]) }}"
```

## Assert, Do Not Automate, Destructive Host State

Some operations are too destructive or device-specific to converge
automatically (disk partitioning of live systems, `zpool create`, RAID
creation). For these:

- Record the creation parameters in inventory as **executable documentation**
  (device paths by stable identifiers such as `/dev/disk/by-id`, creation
  options).
- `ansible.builtin.assert` that the resource exists, with a `fail_msg` that
  contains the exact documented creation command, so creation stays a
  deliberate manual act and the playbook fails loudly instead of guessing.

## Check-Mode Friendliness

Design tasks so `--check --diff` runs cleanly and truthfully, including on
first runs against unconfigured hosts:

- Reads must run in check mode: `check_mode: false` on state-query tasks.
- A later task that depends on a resource an earlier task would have created
  must tolerate its absence in check mode: either scope `failed_when` to
  accept the expected failure only in that case, or validate the **predicted**
  state (derived from data that does exist) instead of skipping the check
  entirely. Prefer predicting over skipping: a skipped verification hides
  drift.
- Verify idempotency and check-mode cleanliness after changes: a real run
  followed by a `--check --diff` run should report no changes.

## Mount Points and Network Filesystems

- When a role pre-creates mount-point directories and also mounts over them,
  set the directory's `owner`/`group` to match what the *mounted* filesystem
  presents (for CIFS, the `uid=`/`gid=` mount options); otherwise the
  ownership task inspects the live mount on later runs and flaps trying to
  chown it.
- For network mounts, include `_netdev` and `nofail` options so hosts boot
  cleanly when the file server is down, and prefer stable DNS names (backed by
  DHCP reservations) over raw addresses in `src`.
- Remember `ansible.posix.mount` keys fstab entries by `path`: changing `src`
  or `opts` for the same path replaces the entry — useful for migrations, but
  review what it replaces.
- Smoke-test a new network share from a consumer host through the real client
  stack: an ephemeral mount using the deployed credentials file and the same
  mount options production will use (then unmount and remove the mount point)
  proves more than a share listing from an ad-hoc client tool, and avoids
  installing extra packages. Even though it is ephemeral, it is a state change:
  get approval first.

## Secrets

- Secrets belong in Ansible Vault (host-, group-, or repo-scoped per the
  project's convention), referenced from configuration via `vault_*`
  variables. Never place secret material in tracked plaintext files or
  templates.
- Write secret-bearing files with `no_log: true`, restrictive `mode` (`0600`),
  and `owner`/`group` set explicitly.
- Agents typically cannot edit encrypted vault files. When a new vaulted
  variable is needed, tell the user the variable name and how to add it
  (e.g., `ansible-vault edit`), then reference it by name.

## Best Practices

- Name every task descriptively; task names are the run's user interface.
- Use `become: true` at task level, not play level, so read-only tasks stay
  unprivileged where possible.
- Keep role variable names prefixed and unambiguous
  (`<role_or_feature>_<what>`), and document expected structure next to
  non-obvious defaults.
- Prefer `systemd` units, timers, and handlers over cron entries and ad-hoc
  restarts; notify handlers from the tasks that change the relevant files.
- When a task list grows beyond one concern, split it into included task files
  (`ansible.builtin.include_tasks`) gated by the data that activates them.
