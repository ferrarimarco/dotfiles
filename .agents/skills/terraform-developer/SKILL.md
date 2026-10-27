---
name: terraform-developer
description: >-
  Develop declarative Terraform configurations. Use when the user asks to
  create, update, or debug Terraform code, Terraform descriptors, Terraform
  resources, Terraform modules, or when you need to develop Terraform code.
license: MIT
---

# Terraform Developer

This skill provides expertise in developing Terraform configurations,
descriptors, modules, resources.

## Core Principles

- **Prefer resources over modules:** Favor simple resources for one-off
  configurations to keep designs flat. Introduce modules only when encapsulating
  complex, highly cohesive infrastructure or when reusability across multiple
  environments or projects is strictly required.
- **Loops over resources and modules:** Prefer `for` and `for_each` loops over
  repetitions.

## Best Practices

- **Discover the repository's Terraform entrypoint first:** before invoking the
  `terraform` binary, check whether the repository runs Terraform through a
  wrapper (a script, Makefile target, or task runner) that owns environment
  setup, backend configuration, variable files, or stack ordering. If one
  exists, use it exclusively — raw `terraform` invocations bypass that setup and
  can corrupt state or apply with missing variables. Do not assume `validate` or
  plan-only paths exist in the wrapper; ask or propose extending the wrapper
  instead of working around it.
- **Surface provider deprecation warnings and ask:** when a plan or apply emits
  a provider deprecation warning (e.g., an inline block superseded by a
  dedicated resource), report it to the user and ask whether to migrate now or
  record it as a tracked todo — do not silently ignore it, and do not migrate
  unprompted. When migrating, follow the provider's indicated replacement (e.g.,
  move an inline `acl` block to the dedicated ACL resource, keeping references
  so dependency ordering is preserved).
- **Review plans for `forces replacement` on stateful resources:** an attribute
  the platform can change in place may still be force-new in the provider, by
  design or by a regression (for example, `bpg/proxmox` 0.93.0 replaced LXC
  containers when a mount point was added), turning a small addition into a
  destroy-and-recreate of a resource that carries state or a bootstrap
  procedure. Never approve such a plan as if it were an update. When replacement
  is unacceptable, fast-forward the live infrastructure imperatively to exactly
  what the provider would render — including ordering details such as slot or
  index numbering, and attributes the provider computes when unset — then run a
  plan and verify it reports no changes (the refresh reconciles the state), and
  record the cause with its upstream issue.
- **An in-place update can still restart the machine:** a plan's "update
  in-place" says nothing about guest restarts. The `bpg/proxmox` VM resource's
  `reboot_after_update` (true by default) reboots the VM through the guest
  agent, or stops and starts it, when Proxmox holds the change for the next
  start, the agent options included, with no word in the plan. Read the
  provider's reboot semantics before promising no restart. With the opt-out,
  only an operation that needs the VM powered off (a disk resize or move) fails;
  a pending change is applied with a warning and waits in the hypervisor, so
  read the apply output and the pending changes afterwards and schedule the
  restart behind a silence.
- **Verify applies in state and in the real infrastructure:** confirm the change
  with a read-only check of the recorded state and of the live target platform;
  a no-op apply does not rewrite a local state file, so file modification times
  are not evidence of what ran.
- **Terraform dependencies lockfile:** Generate and update Terraform dependency
  lockfiles (`.terraform.lock.hcl`) with Terraform and commit the lockfile;
  never hand-edit it. If the infrastructure is shared across operating systems
  or architectures, or when `required_providers` version bounds change and the
  already-locked version still satisfies the new range (`terraform init` does
  not update the lockfile once local-platform hashes are present), run
  `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 ...`
  for every platform tracked in the lockfile.
- **Validation and formatting:** Run `terraform validate` to check for syntax
  errors and issues; after any change to `required_providers` or
  `.terraform.lock.hcl`, run
  `terraform init -backend=false -input=false -lockfile=readonly` and
  `terraform validate` to verify the lockfile. Run `terraform fmt` (or
  `terraform fmt -recursive`) to automatically fix formatting issues.
- **Planning:** Run `terraform plan` after making modifications to verify the
  execution plan matches the intended structural changes.
- **Resource naming:** use lowercase letters and underscores (`server_vm`, not
  `server-vm`), and do not repeat the resource type in the name
  (`resource "aws_route_table" "public"`, not `"public_route_table"`).
- **Variables:** include `description` and `type`, suffix unit-bearing names
  (e.g., `_gb`), and add a `validation` block where applicable (ask the user if
  the validation rule is unclear).
- **Outputs:** place outputs in `outputs.tf` and reference exported resource
  attributes (`value = google_compute_instance.web.id`) rather than passing
  input variables directly, so evaluation waits for resource creation.

### Data sources that reference variables

- When you define a variable, prefer initializing a datasource that exercises
  that variable and reference the datasource, instead of referencing the
  variable directly. This helps you validate the variable (in addition to the
  `validation` block in the variable definition), and ensures that a resource
  referencing the variable actually exists. For example:

  ```terraform
  variable "google_cloud_project_id" {
    description = "Google Cloud project id"
    type        = string
  }

  data "google_project" "google_cloud_project" {
    project_id = var.google_cloud_project_id
  }

  resource "google_project_service" "google_cloud_apis" {
    for_each = toset([
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
    ])

    disable_dependent_services = false
    disable_on_destroy         = false
    project                    = data.google_project.google_cloud_project.project_id
    service                    = each.key
  }
  ```

  Setting `project = var.google_cloud_project_id` on the resource directly is
  the pattern to avoid.
