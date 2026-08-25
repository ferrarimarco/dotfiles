---
name: maintain-living-specs
description:
  Automate the synchronization of living design specifications (Markdown) with
  code changes in the repository. Use when code modifications or feature
  completions occur, to ensure status tables and global indexes remain in
  perfect alignment.
license: MIT
---

# Maintain Living Specs

This skill provides a standardized, automated approach to maintaining **living
design specifications** in the repository, preventing documentation drift by
programmatically synchronizing Markdown status tables with the physical state of
the codebase.

## Core Principles

- **Docs-Code Coexistence:** Design specifications must live in the repository
  under and evolve in lockstep with the codebase.
- **No Drift Allowed:** Any change that implements or modifies a feature defined
  in a specification **MUST** update both the spec status table and the global
  index, if available.

## Workflows

### 1. Status Analysis Workflow

When code changes are staged or successfully verified:

1.  Identify which specification files cover the components being modified.
2.  Locate the **Implementation Status** table at the beginning of each relevant
    specification file. If the table is not present, create it.
3.  Compare the actual codebase features against the spec's table checklist:
    - If the code is missing or not yet functional: `Missing`.
    - If the code is partially implemented: `Partially Implemented`.
    - If the code is fully operational, styled, and verified in tests:
      `Fully Implemented`.
4.  For infrastructure specs, implementation and deployment are distinct
    states: code can be `Fully Implemented` but not yet applied to the real
    environment. The **Status** column tracks implementation only; record
    pending deployment as a caveat in the **Details** column (e.g., "not yet
    applied", "applied on node A; node B not yet run") and remove the caveat
    once the deployment is verified. Do not introduce separate
    deployment-status values in the Status column.

### 2. Synchronizing Individual Specifications

Update each target spec's status table directly:

1.  Locate the target row.
2.  Modify the **Status** column to the new state.
3.  Provide precise, objective details in the **Details** column (e.g., "MAC
    BC:24:11:D4:F6:65 declared in Terraform; awaiting test verification").

### 3. Synchronizing the Global Index

After individual specifications are updated, synchronize the main specs index if
available:

1.  Locate the specs index file.
2.  Locate the row matching the updated specification.
3.  Modify the **Current Implementation Status** column to reflect the overall
    completeness of that specification (e.g., transition the summary description
    from `Partially Implemented` to `Fully Implemented`).
4.  Outline high-level progress and what remains outstanding.

## Best Practices

- **Objective Statusing:** Never mark a feature as `Fully Implemented` unless it
  passes all unit and integration tests or has successfully built in CI.
- **Clean Tables:** Ensure that table borders and Markdown formatting are
  perfectly aligned. Do not use trailing whitespaces or introduce vertical
  separators outside the table.
- **Centralized TODOs:** if the specs index has a centralized future-work /
  TODOs section, keep all future work items there. Per-spec "Future Work"
  sections must contain only a pointer to the centralized list; when closing
  or adding items, update the central list and keep intra-spec references
  working by converting relative anchors to full cross-file links.
