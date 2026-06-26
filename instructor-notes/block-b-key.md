# Block B — instructor answer key

> **Do not read this before you've attempted the You-do solo.** Block B is mostly about reading and writing real workflow YAML — the answer key only helps if you've already wrestled with the I-do and We-do.

## Reference end-state workflow

The shipped [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) is the canonical `block-b-end` state. A participant's final state should be **structurally equivalent** — same triggers, same jobs, same step ordering. Cosmetic differences (step names, comment density) are fine.

Key features to verify:

```yaml
on:
  pull_request:
    paths:
      - "projects/**"
      - "ops/**"
      - "docker-compose.yml"
      - ".github/workflows/**"
      - ".yamllint.yml"
      - "rule_config.json"
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  lint:       # yamllint + actionlint + shellcheck + ign-lint + docker compose config
    runs-on: ubuntu-latest
    steps: [...]

  validate:   # ops/validate.sh — every project *.json valid, every code.py parses
    runs-on: ubuntu-latest
    steps: [...]
```

The `validate` job replaces the old pytest job: there is no Flask app, no `Dockerfile`, no `requirements.txt` anymore. The "tests" are now `ops/validate.sh` (the gateway-free green/red signal) plus `ign-lint` in the `lint` job. `ign-lint` (PyPI `ign-lint==0.6.1`, from `bw-design-group/ignition-lint`) is the Ignition-native linter for Perspective `view.json`; it needs Python 3.10+, hence the pinned `setup-python` `"3.12"`.

## Grading the work

In peer review of the participant's Block B PR, look for:

### Must-haves

- **`permissions: contents: read`** at the workflow level. If it's missing, that's an `issue:` comment. Default `GITHUB_TOKEN` permissions are too broad.
- **`paths:` filter** on `pull_request` covering `projects/**`, `ops/**`, and `rule_config.json`. The point of Part 1 was a docs-only PR being **skipped**. If their docs PR runs the full workflow, the filter isn't right.
- **`ign-lint` step** in the `lint` job (`ign-lint --config rule_config.json --files "projects/**/view.json"`) and a **`validate` job** that runs `ops/validate.sh`. Together these replace the old pytest job.
- **CI badge** in `README.md`. Often missed; flag with `nitpick:` if missing.
- **Required check** configured in repo settings — both `lint` and `validate`. Hard to verify in a code review; ask them to screenshot or describe in PR description.

### Common mistakes

- **Hardcoding the secret value.** If someone tested with `echo ${{ secrets.EXAMPLE_SECRET }}` and committed the literal string, that's a real `issue:` — and they should rotate the secret.
- **Path filter too narrow.** `paths: ["projects/lab-project/project.json"]` will skip the workflow when a view changes. Use directory globs like `projects/**`, and remember `rule_config.json` (the ign-lint config) belongs in the list too.
- **Path filter too broad.** Just `paths: ["**"]` defeats the purpose — that's the default.
- **Forgetting Python 3.10+ for `ign-lint`.** `ign-lint` needs Python 3.10 or newer. If they drop `setup-python` or pin an older version, the install or run fails. The reference pins `"3.12"`.
- **Quoting Python version as `3.12` instead of `"3.12"`.** YAML coerces `3.12` to a float (which becomes `3.1`). Always quote version strings.
- **`runs-on: ubuntu-latest` quoted as `"ubuntu-latest"`.** Not strictly wrong; mention it in the debrief.

### Acceptable variations

- **Job ordering.** Lint-then-validate or validate-then-lint — both fine. The two jobs don't depend on each other.
- **Linter tool selection.** If they skipped one of the linters (yamllint, actionlint, shellcheck, ign-lint), ask why in review. Acceptable answer: "we have no shell scripts, so shellcheck is moot." Unacceptable: "I forgot." `ign-lint` and `validate` are not optional — they're the whole point of the overhaul.
- **Custom step names vs. default.** Cosmetic; fine either way.

## Stretch — matrix over views

A participant who completed the stretch should have a `strategy.matrix` that runs `ign-lint` once per view, producing one parallel check per view:

```yaml
  lint-views:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        view:
          - "projects/lab-project/com.inductiveautomation.perspective/views/pages/overview/view.json"
```

The lab project currently ships exactly one view, so a correct answer is a one-entry matrix — that's fine, the pattern is the point. Verify:
- One check shows per matrixed view (e.g. `lint-views (.../overview/view.json)`).
- Each isolates its own pass/fail — the point of the matrix here is *which* view broke, not speed.
- Python is still pinned to `"3.12"` in the matrix job (ign-lint needs 3.10+).

This is genuinely optional. For a small project the single globbed `ign-lint` step is plenty; don't penalize anyone who left the lint job as-is. If they matrixed the `validate` job, that's overkill — `ops/validate.sh` already walks every file in one pass.

### The `pull_request_target` discussion

The participant should **not** have implemented anything with `pull_request_target`. They were asked to read about it, not use it. If you see it in their workflow, dig in — they probably copy-pasted from somewhere without understanding the security implication.

## Debrief crib

- *"Where does the workflow run?"* — On an ephemeral runner spun up per job. Each job gets a fresh VM; jobs don't share state unless you use artifacts or caching.
- *"What happens if a step fails midway?"* — By default, subsequent steps in that job are skipped, the job fails, downstream jobs that `needs:` it are skipped. `continue-on-error: true` overrides; useful sparingly.
- *"What about a job failure?"* — Other independent jobs continue. The workflow as a whole fails if any required job fails.
- *"Required check implications?"* — The *people* part is harder than the *tech* part. Discuss: who maintains the CI? When CI is flaky, who fixes it? Required checks are a contract with the team, not just a setting.
- *"First Ignition CI check?"* — Push for specifics. The honest answer is the one we just built: `ops/validate.sh` (every project `*.json` is valid JSON, every `code.py` parses as Python 3) plus `ign-lint` on the views. Not glamorous; catches the failures that actually break a gateway import.

## Debugging tips when participants get stuck

- **"Workflow not running on my PR."** Check the `paths:` filter — they probably forgot to put their PR-touched file in the filter list. Or check if they pushed to a branch that isn't the PR source.
- **"setup-python is slow."** Yes, ~20s. Don't optimize prematurely.
- **"ign-lint install or run fails."** Almost always a Python version problem — `ign-lint` needs 3.10+. Confirm `setup-python` pins `"3.12"`. Also check the `--files` glob is quoted (`"projects/**/view.json"`) so the shell doesn't expand it before ign-lint sees it.
- **"validate job fails but the views look fine."** `ops/validate.sh` also parses every `code.py` as Python 3 — a syntax error in an event script fails the job even when the JSON is valid. Read the script's output; it names the offending file.
- **"shellcheck not found."** They need the apt-get install step. shellcheck isn't on `ubuntu-latest` by default in all images.
