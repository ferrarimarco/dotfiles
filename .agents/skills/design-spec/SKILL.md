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
   details; the spec covers the _what_ and the _why_, not the _how_. Declarative
   contracts are not implementation: thresholds, rule or query expressions,
   variable and port names, and similar interface-level commitments belong in
   the spec — a spec that omits them cannot be implemented unambiguously.
2. **Challenge Assumptions:** Do not blindly accept what the user proposes.
   Actively challenge their assumptions. Ask why a feature is needed, what
   alternative approaches were considered, and whether it aligns with broader
   system constraints. Ask whether the feature is one consumer of a wider
   capability (a feature for one host versus a service for every host), and
   propose the general framing when its extra cost is small.
3. **Identify Edge Cases:** Proactively point out potential edge cases, security
   risks, scalability bottlenecks, and potential negative user experiences.
4. **Record Rejected Alternatives:** when the user chooses between competing
   approaches, capture the rejected options and the reason for rejection in the
   spec (a lightweight decision record). This prevents re-litigating the same
   trade-off later and preserves the constraint that drove the choice (e.g.,
   "encrypted secrets in a public repository were considered and rejected
   because Git history is immortal").
5. **Be Concise and Focused:** Keep specifications and design documents concise,
   focusing on the most important architectural details. State each problem or
   invariant once without repeating it in the solution or migration plan, omit
   file-by-file inventories, and do not repeat command flags already defined in
   earlier sections. Give each component's detail exactly one home: where the
   document has an overview, it names the component in one line and defers to
   that component's section.
6. **Structure Migration Plans for Incremental Safety and Regression
   Prevention:** When a spec includes a multi-step migration or refactoring
   plan, scope each step (commit or changelist) to a single cohesive goal rather
   than bundling unrelated mechanical changes. When a mechanical update spans
   many packages across distinct file types (build definitions, contributor
   guides, runtime prompts), split each file type into its own step and absorb
   repeated per-package declarations into shared macros or central docs so each
   diff stays small and uniform. When a step renames or deletes paths in one
   environment, search across all environments for manifests referencing the old
   paths so intermediate states do not break. Pair every class of defect the
   migration remediates with an automated check (presubmit, linter, or test) in
   the enforcement step (applying the repository's emergency-rollback bypass
   mechanism uniformly where one exists), and end with a post-migration
   verification step that audits artifacts added or modified while the migration
   was in flight.

## Workflow

1. The user describes a feature.
2. Analyze the description and identify gaps in the logic or missing
   requirements.
3. Ask concise clarifying questions, grouped logically (e.g., User Experience,
   System Integration, Data Modeling), at most 3-4 at a time.
4. Iterate until all requirements are clear and robust, then summarize the final
   design specification.
5. Ask whether to save the spec in a Markdown file. If so, ask where to save it
   and what to name it, suggesting `docs/specs` as the default location when
   that directory exists.
