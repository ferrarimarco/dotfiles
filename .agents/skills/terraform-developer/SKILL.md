---
name: terraform-developer
description:
  Develop declarative Terraform configurations. Use when the user asks to
  create, update, or debug Terraform code, Terraform descriptors, Terraform
  resources, Terraform modules.
license: MIT
---

# Terraform Developer

This skill provides expertise in developing Terraform configurations,
descriptors, modules, resources.

## Core Principles

- **Prefer resources over modules**: keep designs simple by using plain
  Terraform resources over modules. Implement `for` and `for_each` loops to
  avoid repetitions.

## Best Practices

- **Terraform dependencies lockfile:** Generate Terraform dependency lock files
  running `terraform init`, and remind the user to do so and commit the lock
  file.
- **Validation and formatting:** Run `terraform validate` and
  `terraform fmt -check` to check for syntax errors and formatting issues. If
  there are formatting issues, run `terraform fmt` to fix them.
- **Resource naming convention:** follow these rules when naming resources.
  - Use lowercase letters and underscores (`_`) to separate words when naming
    resources. Example: `server_vm`, not `server-vm`.
- **Variable definition:** follow these rules when defining variables.
  - If necessary, add a suffix to the variable name that denotes the unit.
    Example: `_gb` for gigabytes.
  - Add a `description` and a `type` when defining Terraform variables.
  - Implement variable `validation` if applicable. If you don't know how to
    validate the variable, ask the user.
- **Outputs definition:**
  - Store outputs in a file named `outputs.tf` within the module or Terraform
    service.
  - Don't pass variables as outputs directly to ensure that they are added to
    the dependency graph.

### Data sources that reference variables

- When you define a variable, prefer initializing a datasource that exercises
  that variable and reference the datasource, instead of referencing the
  variable directly. This helps you validate the variable (in addition to the
  `validation` block in the variable definition), and ensuring that a resource
  referencing the variable actually exists. For example:

  ```terraform
  variable "google_cloud_project_id" {
    description = "Google Cloud project id"
    type        = string
  }

  # Prefer this
  data "google_project" "google_cloud_project" {
    project_id = var.google_cloud_project_id
  }

  resource "google_project_service" "google_cloud_apis_good_example" {
    for_each = toset([
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
    ])

    disable_dependent_services = false
    disable_on_destroy         = false
    project                    = data.google_project.cluster.project_id
    service                    = each.key
  }

  # Over this
  resource "google_project_service" "google_cloud_apis_bad_example" {
    for_each = toset([
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
    ])

    disable_dependent_services = false
    disable_on_destroy         = false
    project                    = var.google_cloud_project_id
    service                    = each.key
  }

  ```
