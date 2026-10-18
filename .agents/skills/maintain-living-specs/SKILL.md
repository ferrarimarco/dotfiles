---
name: maintain-living-specs
description: >-
  Keep living design specifications (Markdown) in sync with code changes in the
  repository. Use when code modifications or feature completions occur, so that
  spec status tables and the global specs index reflect the codebase.
license: MIT
---

# Maintain Living Specs

Keep the implementation status tables of living design specifications, and the
specs index, in step with the codebase so the documentation does not drift.

## Core Principles

- **Docs-Code Coexistence:** design specifications live in the repository and
  evolve in lockstep with the codebase.
- **No Drift Allowed:** any change that implements or modifies a feature defined
  in a specification must update both the spec status table and the global
  index, if available.

## Workflows

### 1. Synchronizing Individual Specifications

When code changes are staged or successfully verified:

1. Identify which specification files cover the components being modified.
2. Locate the **Implementation Status** table at the beginning of each relevant
   specification file. If the table is not present, create it.
3. Compare the actual codebase features against the spec's table checklist:
   - If the code is missing or not yet functional: `Missing`.
   - If the code is partially implemented: `Partially Implemented`.
   - If the code is fully operational, styled, and verified in tests:
     `Fully Implemented`.
4. For infrastructure specs, implementation and deployment are distinct states:
   code can be `Fully Implemented` but not yet applied to the real environment.
   The **Status** column tracks implementation only; record pending deployment
   as a caveat in the **Details** column (e.g., "not yet applied", "applied on
   node A; node B not yet run") and remove the caveat once the deployment is
   verified. Do not introduce separate deployment-status values in the Status
   column.
5. Update the row's **Status** column and give precise, objective details in the
   **Details** column (e.g., "MAC BC:24:11:D4:F6:65 declared in Terraform;
   awaiting test verification").

### 2. Synchronizing the Global Index

After individual specifications are updated, synchronize the main specs index if
available:

1. Locate the row matching the updated specification in the specs index file.
2. Update the **Current Implementation Status** column to reflect the overall
   completeness of that specification (e.g., from `Partially Implemented` to
   `Fully Implemented`).
3. Outline high-level progress and what remains outstanding.

## Best Practices

- **Objective Statusing:** Never mark a feature as `Fully Implemented` unless it
  passes all unit and integration tests or builds cleanly in CI.
- **Clean Tables:** keep table formatting aligned, without trailing whitespace
  or vertical separators outside the table.
- **Centralized TODOs:** if the specs index has a centralized future-work /
  todos section, keep all future work items there. Per-spec "Future Work"
  sections must contain only a pointer to the centralized list; when closing or
  adding items, update the central list and keep intra-spec references working
  by converting relative anchors to full cross-file links.
- **Close incidental completions:** a verified change sometimes completes todo
  items tracked elsewhere as a side effect (for example, a rollout that also
  deploys an integration another list was waiting on). Close those items in the
  same synchronization pass and mention them in the commit message, so drift
  does not survive in unrelated lists.
- **Record deferred plans as todos:** when part of an approved plan is put on
  hold, add the deferred work to the centralized todo list in the same
  synchronization pass (with the date and why it is on hold), and close it when
  the deferred work later lands.
