---
name: edit-google-docs
description: >-
  Edit, format, or suggest changes in a Google Doc through the Google Docs API,
  including batch updates and Suggest Mode. Use when the user shares a
  docs.google.com link to change, asks to update, restyle, or propose edits to a
  Google Doc, mentions Suggest Mode, named styles, headings, or inline code in a
  document, or when a batch update inserts text or applies text styles.
license: MIT
---

# Edit Google Docs

Keep a Google Doc's native styling intact and its suggestion diff small while
editing it through the Google Docs API.

## Named Styles

- Use the `TITLE` style for the document title and start top-level sections at
  `HEADING_1` style.
- Preserve the document's native named styles (`NORMAL_TEXT`, `TITLE`,
  `HEADING_1`–`HEADING_3`) by omitting explicit font family, font size, color,
  and paragraph spacing overrides on prose and headings.

## Suggested Edits

When proposing edits in Suggest Mode, target the smallest unique word or phrase
span around each change rather than replacing whole sentences or paragraphs, and
keep each replacement within a single formatting run (for example, separate a
bold prefix from its unbolded body). A reviewer accepts or rejects each
suggestion on its own, so a small span is easier to judge and to accept
partially.

## Inserting Styled Text

Insert plain text at a `NORMAL_TEXT` boundary before applying inline styles. In
batch updates, each `insertText` at index `i` inherits the character style of
`i - 1`, and in Suggest Mode an `updateTextStyle` request resetting the base
font is ignored as a no-op against `NORMAL_TEXT`. Never insert prose at the end
of a `Courier New`, bold, or link run:

1. Anchor the insertion immediately after a `NORMAL_TEXT` character (such as an
   adjacent space, punctuation mark, or prose word).
2. Insert the full unstyled text first so it inherits `NORMAL_TEXT`.
3. Apply `Courier New` or emphasis only to the specific inline spans afterward.
