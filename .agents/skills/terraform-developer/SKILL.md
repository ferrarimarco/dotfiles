---
name: terraform-developer
description:
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

- **Terraform dependencies lockfile:** Generate Terraform dependency lockfiles
  running `terraform init`, and remind the user to do so and commit the lock
  file. If the infrastructure is shared across different operating systems or
  architectures, use
  `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 ...` to
  ensure all necessary platforms are covered.
- **Validation and formatting:** Run `terraform validate` to check for syntax
  errors and issues. Run `terraform fmt` (or `terraform fmt -recursive`) to
  automatically fix formatting issues.
- **Planning:** Run `terraform plan` after making modifications to verify the
  execution plan matches the intended structural changes.
- **Resource naming convention:** follow these rules when naming resources.
  - Use lowercase letters and underscores (`_`) to separate words when naming
    resources. Example: `server_vm`, not `server-vm`.
  - Avoid repeating the resource type in the resource name. For example, prefer
    `resource "aws_route_table" "public"` over
    `resource "aws_route_table" "public_route_table"`.
- **Variable definition:** follow these rules when defining variables.
  - If necessary, add a suffix to the variable name that denotes the unit.
    Example: `_gb` for gigabytes.
  - Add a `description` and a `type` when defining Terraform variables.
  - Implement variable `validation` if applicable. If you don't know how to
    validate the variable, ask the user.
- **Outputs definition:**
  - Store outputs in a file named `outputs.tf` within the module or Terraform
    service.
  - Don't pass input variables as outputs directly. To ensure that an output
    isn't evaluated until a resource is fully created, the output must reference
    an exported attribute of the created resource (e.g.,
    `value = google_compute_instance.web.id`).

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
    project                    = data.google_project.google_cloud_project.project_id
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
