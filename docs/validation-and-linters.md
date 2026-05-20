# Validation and linters — cheat sheet

Reference reading for Block A. The point isn't to use every linter; the point is to know which one catches which class of bug, and to install only the ones that earn their place.

## The five tools we install

| Tool | What it catches | Speed | Where it runs |
|---|---|---|---|
| **yamllint** | YAML syntax + style issues | ms | local + CI |
| **hadolint** | Dockerfile anti-patterns and best practices | ms | local + CI |
| **actionlint** | GitHub Actions workflow syntax + expression typing | ms | local + CI |
| **shellcheck** | Bash scripting bugs (the canonical ones, and many subtle ones) | ms | local + CI |
| **ruff** | Python linting (replaces flake8 / pycodestyle / isort / autopep8) | very fast | local + CI |

Plus one validator that isn't really a linter:

| Tool | What it catches |
|---|---|
| **`docker compose config`** | Compose schema validation. Catches "service not defined", port-string typos, malformed environment maps. |

## A mental model

Linters fall into three groups:

**1. Syntax linters.** They verify the file *parses correctly* under the tool's grammar. `yamllint`, `docker compose config`, `actionlint`, `ruff` (in some modes). Cheap, fast, hard to argue with.

**2. Best-practice linters.** They verify the file follows known-good *patterns*. `hadolint` flagging `apt-get install` without `--no-install-recommends` isn't a syntax error — it's a "this Dockerfile will work but will produce bloated images and unreproducible builds" warning. These are the most valuable category; they encode operational wisdom.

**3. Style linters.** They verify the file matches an opinionated *aesthetic*. Some `ruff` rules (line length, quote style, trailing commas) live here. These are useful in a team context — consistency reduces cognitive load — but they're also the most fiddly. You're allowed to disable rules you don't like, *as long as the team agrees*.

When choosing what to enable, start with #1 and #2; treat #3 as opt-in.

## Common findings and what they mean

### yamllint

- `line too long` — your line exceeds the configured limit. Often a false positive for compose env strings; disable with `line-length: disable` in `.yamllint.yml`.
- `trailing spaces` — exactly what it says. Fix by stripping the whitespace.
- `truthy value should be true/false` — YAML's `yes`/`no`/`on`/`off` boolean shorthand; surprisingly often unintentional.

### hadolint

- `DL3008: Pin versions in apt-get install` — `apt-get install -y curl` produces non-reproducible builds. Pin: `apt-get install -y curl=7.88.1-1`. Or accept the warning if you're rebuilding regularly.
- `DL3009: Delete the apt-get lists after installing something` — leftover `/var/lib/apt/lists/` bloats the image. Add `&& rm -rf /var/lib/apt/lists/*` to the same RUN.
- `DL3015: Avoid additional packages` — use `--no-install-recommends`. Standard hygiene.
- `DL3007: Using latest is prone to errors` — pin your base image's tag.

### shellcheck

- `SC2086: Double quote to prevent globbing and word splitting` — the canonical shellcheck finding. `$VAR` should almost always be `"$VAR"` unless you specifically want word-splitting.
- `SC2148: Missing shebang` — add `#!/usr/bin/env bash` at the top.
- `SC2034: VAR appears unused` — exactly what it says.
- `SC2155: Declare and assign separately` — `local x=$(cmd)` masks `cmd`'s exit status. Split into two lines.

### ruff

- `F401: imported but unused` — delete the import.
- `E711: comparison to None should be 'is None'` — use `is None` (None is a singleton).
- `B006: Do not use mutable data structures for argument defaults` — Python's "shared default" footgun.
- `S101: Use of assert` — fine in tests, dangerous in production code (asserts are stripped under `-O`).

### actionlint

- `unknown action` — typo in the action name, or you forgot to pin a version.
- `expression type mismatch` — `${{ steps.foo.outputs.value }}` referenced before `foo` runs; or wrong type in arithmetic.
- `outdated runner image` — `ubuntu-18.04` is gone; use `ubuntu-latest` or a specific current version.

## What about Ignition-specific validators?

There isn't really a public one. Tag exports, `project.json`, `view.json` — none of these have published JSON schemas you can lint against. The closest you get is:

- `python -c "import json; json.load(open('project.json'))"` — at least confirms parseable JSON.
- A diff-based check: did your PR change `project.json` in a way that reasonable review would catch? (See Lab 02's PR-review-style doc.)

We'll wrestle with this in Lab 04 when we look at the Ignition file structure properly. For now, the lesson is: generic linters cover ~80% of what you'd want from a "validate my project" check, and the Ignition-specific 20% needs custom tooling.

## When linting helps and when it doesn't

**Helps when:**

- It catches the same bug every dev would otherwise hit
- It's fast enough to run on save (or pre-commit)
- The config matches your team's reality (not a copy-pasted default)

**Hurts when:**

- It flags style preferences as errors, blocking PRs
- It's slower than the dev cycle (a 90s lint on every save is a productivity drain)
- The config drifts from reality (new rules added upstream that no one in your team agrees with)

The cure for the second category is usually `.yamllint.yml`-style local config, not "disable the linter entirely."

## Further reading

- [yamllint docs](https://yamllint.readthedocs.io/) — full rule reference
- [hadolint rule list](https://github.com/hadolint/hadolint/wiki) — every rule code, its justification, and how to fix
- [shellcheck wiki](https://www.shellcheck.net/wiki/) — the canonical guide; every error code is a learnable lesson
- [ruff rule reference](https://docs.astral.sh/ruff/rules/) — searchable rule list
- [actionlint docs](https://github.com/rhysd/actionlint/blob/main/docs/checks.md) — what it checks and how
