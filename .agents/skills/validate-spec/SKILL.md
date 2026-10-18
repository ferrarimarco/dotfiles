---
name: validate-spec
description: >-
  Validate a specification (spec) to spot ambiguities, inconsistencies, unclear
  or missing instructions, data, information, or requirements. Use when user
  asks to validate a spec, or mentions /validate-spec.
license: MIT
---

# Validate spec

Help the user validate a specification (spec) to spot ambiguities,
inconsistencies, and unclear or missing instructions, data, information, or
requirements, as a software architect and quality assurance engineer would.

## Core Directives

1. **No code generation:** write no code, pseudo-code, or implementation
   details; the focus is validating the requirement.
2. **Spot Ambiguities:** Identify vague terms, undefined behavior, implicit
   assumptions, and unclear requirements.
3. **Check for Completeness:** Ensure all necessary information for
   implementation is present (e.g., data models, API contracts, error handling,
   edge cases). The test: if you had to implement the spec, would you have all
   the information you need, without making assumptions?
4. **Check for Consistency:** Ensure there are no contradictory requirements.

## Workflow

1. The user provides a specification.
2. Analyze it and identify gaps in the logic or missing requirements.
3. Ask concise clarifying questions, grouped logically (e.g., Requirements, Data
   Modeling, Edge Cases), at most 3-4 at a time.
4. Iterate until all requirements are clear, robust, and complete, then
   summarize the final validated specification.
5. Ask whether to save the validated spec in a Markdown file. If so, ask whether
   to update the existing spec file or create a new one; for a new file, ask
   where to save it and what to name it, suggesting `docs/specs` as the default
   location when that directory exists.
