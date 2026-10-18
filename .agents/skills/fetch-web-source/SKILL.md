---
name: fetch-web-source
description: >-
  Fetch documentation or source code for a tool, module, or provider at the
  version in use when the web page does not serve it: a 403 from bot protection,
  a JavaScript-only placeholder such as the Terraform Registry, truncated
  content, or a short link that lands on an interstitial page. Use when asked to
  read the upstream docs, check a module's or provider's source, confirm how a
  tool behaves at a pinned version, or when cURL or a fetch tool fails on a
  documentation site.
license: MIT
---

# Fetch Web Source

Get the authoritative text for a tool at the version in use, from the project's
repository when the documentation site does not serve it, and stop retrying once
the site has shown it will not answer.

## 1. Fetch the Page Once

- A short link from a sharing service may land on an interstitial page; the
  target is usually in the canonical link of the returned page.
- A site behind bot protection answers 403 to cURL and to fetch tools alike.
  Switching user agents or routes rarely helps; move to step 2.
- A documentation site that renders client-side returns a placeholder with no
  content, and some sites truncate long pages. Both mean the page is not the
  source of truth; move to step 2.

## 2. Read the Repository at the Version in Use

Fetch the file from the project's repository at the tag in use instead of
guessing raw URLs. List a directory, then download a file with the same endpoint
on the file path:

```sh
gh api 'repos/<org>/<repo>/contents/<dir>?ref=<tag>'
gh api 'repos/<org>/<repo>/contents/<path>?ref=<tag>' \
  -H 'Accept: application/vnd.github.raw+json'
```

When the placeholder page hides the repository link, the site's JSON API usually
names it. The Terraform Registry does in the `source` field of
`registry.terraform.io/v1/modules/<ns>/<name>/<provider>` and
`/v1/providers/<ns>/<name>`.

Without `gh`, the same endpoints answer cURL. Unauthenticated calls are limited
to 60 requests per hour, enough to list a directory and fetch a few files, and
hitting the limit answers 403 like bot protection does, so count the requests
before blaming the site:

```sh
curl --fail -sS -H 'Accept: application/vnd.github.raw+json' \
  'https://api.github.com/repos/<org>/<repo>/contents/<path>?ref=<tag>'
```

When the API is blocked too, or the project is not on GitHub, a shallow clone of
the tag needs only Git:

```sh
git clone --depth 1 --branch <tag> <repository-url> <scratch-dir>
```

## 3. Ask After Two Failed Routes

Some sites reject every unauthenticated route (web, mobile, API, JSON). After
two failed routes, ask for pasted content or a saved PDF instead of retrying,
and label anything not verified as an expectation.
