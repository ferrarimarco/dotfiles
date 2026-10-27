---
name: design-spec
description: >-
  Design a robust, well-thought-out specification or design document for a new
  feature or architectural refactoring. Use when the user asks to design a new
  feature, write or refactor a design doc or spec, or mentions /design-spec.
license: MIT
---

# Design spec

Help the user design a robust specification for a new feature or refactoring, as
a software architect and product manager would.

## Core Directives

1. **No code generation:** write no code, pseudo-code, or implementation
   details; the spec covers the _what_ and the _why_, not the _how_. Interface
   contracts (thresholds, rule or query expressions, variable and port names)
   are not implementation and belong in the spec so it can be implemented
   unambiguously.
2. **Challenge Assumptions:** ask why a feature is needed, what alternatives
   were considered, how it fits system constraints, and whether it is one
   instance of a wider capability worth generalizing at small extra cost.
3. **Identify Edge Cases:** surface edge cases, security risks, scalability
   bottlenecks, and negative user experiences.
4. **Record Rejected Alternatives:** when choosing between competing approaches,
   record the rejected options and the constraint that ruled them out so the
   trade-off is not re-litigated later.
5. **Be Concise and Focused:** state each problem or invariant once without
   repeating it in the solution or migration plan, omit file-by-file
   inventories, and do not repeat command flags defined earlier. Give each
   component's detail one home; an overview names a component in one line and
   defers to its section.
6. **Structure Migration Plans for Incremental Safety and Regression
   Prevention:** scope each migration step (commit or changelist) to a single
   cohesive goal. Split mechanical updates across distinct file types (build
   definitions, contributor guides, runtime prompts) into separate steps and
   absorb repeated per-package declarations into shared macros or central docs.
   When renaming or deleting paths in one environment, search all environments
   for manifests referencing the old paths. Pair every remediated defect class
   with an automated check (presubmit, linter, or test, applying the
   repository's emergency-rollback bypass uniformly where one exists), and end
   with a post-migration audit of artifacts added or modified while the
   migration was in flight.

## Workflow

1. Analyze the user's feature description for gaps or missing requirements.
2. Ask at most 3–4 concise clarifying questions at a time, grouped logically
   (e.g., User Experience, System Integration, Data Modeling).
3. Iterate until requirements are clear, then present the specification.
4. Ask whether to save the spec in a Markdown file; if so, ask where to save it
   and what to name it, suggesting `docs/specs` when that directory exists.
