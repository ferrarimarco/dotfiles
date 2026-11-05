---
name: validate-spec
description: >-
  Validate a specification (spec), design document, or technical guide to spot
  ambiguities, inconsistencies, and unclear or missing instructions, data,
  information, or requirements. Use when the user asks to validate or review a
  spec, design doc, or technical guide, or mentions /validate-spec.
license: MIT
---

# Validate spec

Help the user validate a specification (spec), design document, or technical
guide to spot ambiguities, inconsistencies, and unclear or missing instructions,
data, information, or requirements, as a software architect and quality
assurance engineer would.

## Core Directives

1. **No implementation code generation:** do not write feature code or
   pseudo-code; focus on validating requirements and documented procedures
   (interface contracts, configuration settings, flags, and file paths belong
   when needed to remove ambiguity).
2. **Spot Ambiguities:** Identify vague terms, undefined behavior, implicit
   assumptions, and unclear requirements.
3. **Check for Completeness:** Ensure all necessary information for
   implementation or execution is present (e.g., data models, API contracts,
   error handling, edge cases). Verify that every topic named in a section
   heading is covered in its body, that every prescribed tool, platform, or
   configurable capability names the concrete setting, flag, or file that
   enables it (or notes that it is built-in default behavior), and that
   cost-control sections pair efficiency tuning with an enforceable spend or
   quota ceiling (and, when credentials and quota or billing live in separate
   accounts or projects, state which carries each). The test: if you had to
   implement or follow the document, would you have all the information you
   need, without making assumptions?
4. **Check for Consistency:** Ensure there are no contradictory requirements.
   Check that mitigations in later sections do not contradict an architecture
   established earlier (such as proposing per-repository runtime variable
   workarounds after establishing centralized template rendering), that distinct
   state or output sinks (such as per-run job summaries versus persistent
   pull-request comments) are not conflated, and that artifacts already
   maintained elsewhere (such as prompts, workflows, configs, or schemas in the
   repository or a companion one) are linked rather than duplicated inline,
   where copies drift.

## Workflow

1. Analyze the provided document for gaps, ambiguities, or contradictions.
2. Ask at most 3–4 concise clarifying questions at a time, grouped logically
   (e.g., Requirements, Data Modeling, Edge Cases).
3. Iterate until requirements are clear and complete, then present the validated
   document.
4. Ask whether to apply or save the validated document (updating the existing
   file or proposing edits in place, or creating a new Markdown file after
   asking where to save it and what to name it, suggesting `docs/specs` for a
   new spec when that directory exists).
