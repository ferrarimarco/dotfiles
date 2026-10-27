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

1. Analyze the provided specification for gaps, ambiguities, or contradictions.
2. Ask at most 3–4 concise clarifying questions at a time, grouped logically
   (e.g., Requirements, Data Modeling, Edge Cases).
3. Iterate until requirements are clear and complete, then present the validated
   specification.
4. Ask whether to save the validated spec in a Markdown file (updating the
   existing file or creating a new one; for a new file, ask where to save it and
   what to name it, suggesting `docs/specs` when that directory exists).
