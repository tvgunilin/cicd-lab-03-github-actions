# Block B — instructor answer key

> **Do not read this before you've attempted the You-do solo.** Block B is mostly about reading and writing real workflow YAML — the answer key only helps if you've already wrestled with the I-do and We-do.

## Reference end-state workflow

The shipped [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) is the canonical `block-b-end` state. A participant's final state should be **structurally equivalent** — same triggers, same jobs, same step ordering. Cosmetic differences (step names, comment density) are fine.

Key features to verify:

```yaml
on:
  pull_request:
    paths:
      - "sample-app/**"
      - "scripts/**"
      - "docker-compose.yml"
      - ".github/workflows/**"
      - ".yamllint.yml"
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  lint:   # All 5 linters + docker compose config
    runs-on: ubuntu-latest
    steps: [...]

  test:   # pytest with pip caching
    runs-on: ubuntu-latest
    steps: [...]
```

## Grading the work

In peer review of the participant's Block B PR, look for:

### Must-haves

- **`permissions: contents: read`** at the workflow level. If it's missing, that's an `issue:` comment. Default `GITHUB_TOKEN` permissions are too broad.
- **`paths:` filter** on `pull_request`. The point of Part 1 was a docs-only PR being **skipped**. If their docs PR runs the full workflow, the filter isn't right.
- **`pytest` job** that depends on `sample-app/requirements.txt`. Pip caching is a nice-to-have, not required.
- **CI badge** in `README.md`. Often missed; flag with `nitpick:` if missing.
- **Required check** configured in repo settings. Hard to verify in a code review; ask them to screenshot or describe in PR description.

### Common mistakes

- **Hardcoding the secret value.** If someone tested with `echo ${{ secrets.EXAMPLE_SECRET }}` and committed the literal string, that's a real `issue:` — and they should rotate the secret.
- **Path filter too narrow.** `paths: ["sample-app/app.py"]` will skip the workflow when the test file changes. Use directory globs.
- **Path filter too broad.** Just `paths: ["**"]` defeats the purpose — that's the default.
- **Missing setup-python.** Some students try to run `pytest` directly assuming Python is on the path. It is on `ubuntu-latest`, but the version isn't pinned — without `setup-python`, you don't control which version you get.
- **Quoting Python version as `3.12` instead of `"3.12"`.** YAML coerces `3.12` to a float (which becomes `3.1`). Always quote version strings.
- **`runs-on: ubuntu-latest` quoted as `"ubuntu-latest"`.** Not strictly wrong; mention it in the debrief.

### Acceptable variations

- **Job ordering.** Lint-then-test or test-then-lint — both fine. The two jobs don't depend on each other.
- **Linter tool selection.** If they skipped one of the five linters, ask why in review. Acceptable answer: "we don't have shell scripts, so shellcheck is moot." Unacceptable: "I forgot."
- **Custom step names vs. default.** Cosmetic; fine either way.

## Stretch — matrix testing

A participant who completed the stretch should have a `strategy.matrix` that produces two parallel test jobs:

```yaml
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: ["3.11", "3.12"]
```

Verify:
- Two checks show in the PR (`test (3.11)` and `test (3.12)`).
- Both pass.
- `cache: "pip"` is present (the speedup is the point of caching).

If they matrix'd the lint job too, that's overkill — linters don't change behavior across Python versions. Flag with `suggestion: lint runs once; only test benefits from a matrix.`

### The `pull_request_target` discussion

The participant should **not** have implemented anything with `pull_request_target`. They were asked to read about it, not use it. If you see it in their workflow, dig in — they probably copy-pasted from somewhere without understanding the security implication.

## Debrief crib

- *"Where does the workflow run?"* — On an ephemeral runner spun up per job. Each job gets a fresh VM; jobs don't share state unless you use artifacts or caching.
- *"What happens if a step fails midway?"* — By default, subsequent steps in that job are skipped, the job fails, downstream jobs that `needs:` it are skipped. `continue-on-error: true` overrides; useful sparingly.
- *"What about a job failure?"* — Other independent jobs continue. The workflow as a whole fails if any required job fails.
- *"Required check implications?"* — The *people* part is harder than the *tech* part. Discuss: who maintains the CI? When CI is flaky, who fixes it? Required checks are a contract with the team, not just a setting.
- *"First Ignition CI check?"* — Push for specifics. Honest answer is often "the same lint suite we just built, plus `python -c 'json.load(open(project.json))'`." Not glamorous; effective.

## Debugging tips when participants get stuck

- **"Workflow not running on my PR."** Check the `paths:` filter — they probably forgot to put their PR-touched file in the filter list. Or check if they pushed to a branch that isn't the PR source.
- **"setup-python is slow."** Yes, ~20s. Caching helps only on second run. Don't optimize prematurely.
- **"hadolint action failing without output."** The `hadolint/hadolint-action` is quiet on success; loud on failure. If it's not finding the Dockerfile, the `dockerfile:` input is wrong.
- **"shellcheck not found."** They need the apt-get install step. shellcheck isn't on `ubuntu-latest` by default in all images.
