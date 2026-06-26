# Block A — instructor answer key

> **Do not read this before you've attempted the You-do solo.** Half the value is the diagnostic skill — running each tool, reading the output, deciding what to do.

## The seeded-error recipe

The shipped `main` of this lab is **clean** — no planted issues, and the `lab-project` passes ign-lint with **zero** findings. To produce `block-a-start`, a maintainer applies the following seed commit on top of `main` and tags it.

### Seed commit: "chore: seed Block A lint issues (do not merge)"

Six planted issues across the repo. Two of them (#4, #5) live inside the Perspective view and are caught by **ign-lint**; one (#6) is a Jython-2 statement caught by `ops/validate.sh`.

The Overview view lives at:
`projects/lab-project/com.inductiveautomation.perspective/views/pages/overview/view.json`
The script libraries live at:
`projects/lab-project/ignition/script-python/lab/{display,util}/code.py`

### 1. `docker-compose.yml` — yamllint (trailing whitespace)

Add trailing whitespace to a line in the compose file:

```yaml
    container_name: lab03-ignition   ← trailing spaces here
```

yamllint flags `trailing-spaces`. (line-length is currently *disabled* in `.yamllint.yml`, so the long compose env lines won't flag — that's deliberate and it's the subject of the config sub-task below.)

**Fix:** strip the trailing whitespace.

### 2. `ops/scan.sh` — shellcheck SC2086 (unquoted variable)

In the hot-reload script, leave a shell variable unquoted, e.g.:

```bash
curl -fsS -H "X-Ignition-API-Token: $API_KEY" $GATEWAY_URL/data/...
```

shellcheck flags `SC2086` ("Double quote to prevent globbing and word splitting") on `$GATEWAY_URL`.

**Fix:** quote it — `"$GATEWAY_URL"`.

### 3. `.github/workflows/example.yml` — actionlint

Create this seed file:

```yaml
name: Example workflow
on: workflow_dispatch
jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: echo "${{ env.MISSING_VAR }}"
```

Issues actionlint flags:
- `actions/checkout@v2` is deprecated; should be `@v4`
- `env.MISSING_VAR` is referenced but never defined

**Fix:** either fix it (`actions/checkout@v4`, define the env var) or delete the file (acceptable — example workflows aren't required).

### 4. Overview `view.json` — ign-lint `NamePatternRule` (component in snake_case)

Rename a Perspective component in the Overview view to snake_case. For example, rename the system-status label from `SystemPill` to `system_pill`:

```json
{ "meta": { "name": "system_pill" }, "type": "ia.display.label", ... }
```

ign-lint's `NamePatternRule` requires components to be **PascalCase** and reports a name violation as an **error**. (The root container is named `root` and is exempt.)

Run: `ign-lint --config rule_config.json --files "projects/**/view.json"`

**Fix:** rename the component back to `SystemPill` (PascalCase). Note this is a `meta.name` change in the JSON — if the component is referenced by name elsewhere in the view, those references must match.

### 5. Overview `view.json` — ign-lint `PollingIntervalRule` (poll faster than the floor)

The Overview "Clock" label has an expression binding that legitimately polls at the 1000ms floor (e.g. `now(1000)`). Change it to poll faster than allowed:

```json
"binding": { "type": "expr", "config": { "expression": "now(250)" } }
```

`rule_config.json` sets `PollingIntervalRule` with `minimum_interval = 1000` (ms) for this lab. A 250ms poll is under the floor, so it's flagged.

**Fix:** restore the poll rate to `now(1000)` (or slower). The teaching point: fast polls multiply across a deployed HMI and hammer the gateway.

### 6. `lab/display/code.py` — `ops/validate.sh` (Jython-2 `print` statement)

In `projects/lab-project/ignition/script-python/lab/display/code.py`, introduce a Jython-2-only print statement:

```python
def refresh_overview():
    print "refreshing overview"   # ← Python-2 statement form, not valid Python 3
    ...
```

`ops/validate.sh` parses every `code.py` as Python 3 (gateway-free), and this `print "..."` statement form fails to parse, so the script exits 1 — the red PR signal.

**Fix:** make it a Python-3 call: `print("refreshing overview")` (or remove the debug print).

### Config sub-task: `.yamllint.yml` comment

The shipped `.yamllint.yml` disables `line-length`. The participant should **extend the existing comment** explaining *why* — the compose file has long environment-variable lines (gateway config, connection strings, JVM args) that would otherwise blow past the limit, and wrapping them hurts readability more than it helps.

## You-do solutions (block-a-end)

After Block A, the participant should have:

1. **docker-compose.yml** — trailing whitespace stripped.
2. **ops/scan.sh** — the unquoted variable quoted (`"$GATEWAY_URL"`). (The shipped clean state already quotes its variables.)
3. **example.yml** — either fixed (`actions/checkout@v4`, define the env var) or deleted (acceptable; example workflows aren't required).
4. **Overview `view.json`** — the misnamed component renamed back to PascalCase (`SystemPill`), and the Clock binding restored to `now(1000)` or slower. ign-lint reports zero findings.
5. **lab/display/code.py** — the `print "..."` statement converted to `print(...)` (or removed). `ops/validate.sh` exits 0.
6. **`.yamllint.yml`** — the `line-length` disable comment extended to explain the long compose env lines.

## Grading the work

In peer review of the participant's Block A PR, look for:

- **All linters silent.** Each of `yamllint`, `shellcheck`, `actionlint`, and `ign-lint` should produce zero output, and `ops/validate.sh` should exit 0, when run on the final state.
- **Justified config changes.** If they disabled a `yamllint` or `ign-lint` rule, the commit message or the config file comment should explain why.
- **No "fixed by deleting it" cheats.** Deleting the Clock binding or stripping the component to silence ign-lint is wrong — the component and its poll are legitimate, only the *name* and *interval* were broken. Removing `example.yml` is fine since it was always optional.
- **The view still loads.** Renaming a component is a `view.json` edit; make sure they didn't break the JSON or orphan a reference. `ops/validate.sh` catches malformed JSON; ign-lint's reference rules catch dangling references.

## Stretch — pre-commit

The shipped `.pre-commit-config.yaml` wires yamllint, shellcheck, actionlint, and ign-lint into a pre-commit hook. A participant who completes the stretch should be able to:

```bash
pre-commit install
# Now make a deliberately bad change — rename a component to snake_case:
#   edit projects/lab-project/.../overview/view.json: "name": "SystemPill" → "system_pill"
git add projects/lab-project
git commit -m "test: should be blocked"
# → pre-commit fails the commit, ign-lint flags the NamePatternRule violation
```

If the commit succeeds anyway, check: did they actually run `pre-commit install`? Is `.git/hooks/pre-commit` populated?

## Debrief crib

- *"Which linter would have caught your most recent bug?"* — Push past "we don't have bugs." Specific examples beat abstract claims.
- *"When does linting hurt?"* — Three honest answers:
  1. When it flags style preferences and blocks merge (use `nitpick:` not `issue:`).
  2. When it's slower than the dev loop (lint on save, not lint on push).
  3. When the team didn't agree to the rules — config-by-accident is worse than no config.
- *"Is suppressing a rule ever right?"* — Yes, when the linter is wrong about the specific case. Always include a comment explaining *why*. A targeted, commented suppression is fine; a blanket one is not.
- *"Which ign-lint rules map to bugs you've shipped?"* — The honest ones usually own up to inconsistent component naming and runaway poll rates. `BadComponentReferenceRule` (relative `.getParent()`/`.getSibling()` traversal) tends to provoke the best discussion — it's the thing that silently breaks when a view is restructured. We come back to the Ignition file structure and deploy story in Lab 04.
