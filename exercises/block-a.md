# Block A — Validation and linters as your safety net

**Duration:** ~90 minutes
* 15 min demo
* 15 min we-do
* 30 min you-do
* 15 min debrief
* ~15 min buffer / stretch

## Goal

You should leave this block able to:

- Run **yamllint, shellcheck, actionlint, ign-lint, and `ops/validate.sh`** locally against a real Ignition project
- Read each tool's output and decide whether to fix, configure away, or ignore each finding
- Understand **ign-lint** — an Ignition-native static analyzer that reads your Perspective `view.json` files and the Jython embedded in them, and applies naming, binding, and reference rules
- Add a comment to `.yamllint.yml` to make the linter fit *your* project rather than the other way around
- Explain when CI linting helps and when it gets in the way

## Pre-flight

```bash
git fetch --tags
git checkout block-a-start
```

You're now on a deliberately-broken state with **6 planted issues** scattered across the repo. The instructor will walk you through finding them; you'll fix the rest solo.

The subject is the same single Ignition 8.3.6 gateway you met in Lab 02: a Perspective cold-storage "Overview" HMI plus two Jython script libraries (`lab.display`, `lab.util`). The repo tracks only the project files under `projects/lab-project/` — the gateway generates its own config into a Docker volume we never commit. (Lab 04 goes deep on that file layout; here we only lint it.)

Install the tools you don't have yet. macOS:

```bash
brew install yamllint shellcheck actionlint
pip install ign-lint==0.6.1
```

Linux / Codespaces:

```bash
pip install yamllint==1.35.1 ign-lint==0.6.1
# Then one of: apt install / install from release tarballs
sudo apt-get update && sudo apt-get install -y shellcheck
# actionlint: download from GitHub releases
bash <(curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
```

`ign-lint` needs Python 3.10+. It's a PyPI package (`ign-lint`, CLI `ign-lint`) from the [bw-design-group/ignition-lint](https://github.com/bw-design-group/ignition-lint) project — docs at <https://bw-design-group.github.io/ignition-lint>.

If you'd like to read ahead: [`docs/validation-and-linters.md`](../docs/validation-and-linters.md).

## I do (15 min)

The instructor introduces the safety-net metaphor: every linter is a cheap, fast check that catches a class of bug. The point isn't to use them all; the point is to know which one would have caught yesterday's regression.

Live-demo on the broken `block-a-start` state. For each tool, run it, read the output, fix one finding:

1. `yamllint -c .yamllint.yml docker-compose.yml` — finds the planted YAML issue (trailing whitespace).
2. `ops/validate.sh` — the gateway-free sanity check: every `*.json` under `projects/` is valid JSON, and every `code.py` parses as Python 3. Exit 0 = green, exit 1 = red. This is the same signal the PR check uses.
3. `ign-lint --config rule_config.json --files "projects/**/view.json"` — **the flagship tool of this block.** Ignition-native static analysis: it parses the Perspective `view.json`, walks the component tree, checks naming conventions, binding polling intervals, and the Jython embedded in bindings/scripts. Exits non-zero on findings. Demo it finding the misnamed component.
4. `actionlint` — workflow YAML syntax + expression typing. Run it on the seeded `example.yml` workflow.
5. `shellcheck ops/*.sh` — catches almost every shell scripting bug ever made.

Each tool is a separate command, but they share a shape: one config file, fast feedback, clear rule codes. Spend the most time on **ign-lint** — it's the one that's genuinely Ignition-aware, and the one most of these students have never seen. Open `rule_config.json` and walk the rule list: `NamePatternRule` (components → PascalCase, properties → camelCase, message handlers → kebab-case, custom methods → snake_case), `PollingIntervalRule` (a floor on binding poll rates), `BadComponentReferenceRule` (flags `.getSibling()` / `.getParent()` traversal), `PylintScriptRule`, and the rest. The clean `lab-project` passes ign-lint with **zero** findings — every finding you see is something a maintainer broke on purpose.

## We do (15 min)

Run each tool yourself on the broken state. Together as a class, fix **one** of the **ign-lint** findings — pick the most interesting one. (The instructor will choose live; the misnamed component or the too-fast clock poll both make good demos.)

Don't fix the rest yet — that's the solo exercise.

## You do (30 min)

Fix the remaining planted issues, then make the linter config your own.

1. Run each of `yamllint`, `shellcheck`, `actionlint`, `ign-lint`, and `ops/validate.sh` and capture the findings in `NOTES.local.md` (gitignored). Make a list.
2. Fix every finding. Some take 30 seconds, some need you to understand the Perspective view structure. For each fix, in your notes record: *what the tool flagged*, *why the fix is correct*, and *what category of bug this would catch in production*.
3. Re-run every linter until each one is silent and `ops/validate.sh` exits 0.
4. Open `.yamllint.yml`. Notice we already disabled `line-length` for the project — extend the comment in the file explaining *why*. (Hint: long compose env lines.)
5. Run `ops/validate.sh` one more time. It should exit 0 with no errors.
6. Commit. Your end-state should match `block-a-end`.

> If you're stuck on a specific finding, [`instructor-notes/block-a-key.md`](../instructor-notes/block-a-key.md) has the seeded-error walkthrough. **Don't peek before you've spent at least 5 minutes on the finding yourself** — the diagnostic skill is most of the lesson.

## Stretch challenge `[OPTIONAL]`

Wire the linters into a pre-commit hook so bad commits get blocked locally, before they ever reach CI:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

The repo ships a starter [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) wiring yamllint, shellcheck, actionlint, and ign-lint. Read it. Notice it pins versions — pre-commit doesn't *use* whatever's on your `PATH`; it manages its own toolchain. That's good for reproducibility, slightly opaque on first encounter.

Then deliberately break one file (drop a trailing whitespace into the compose file, rename a Perspective component to snake_case — whatever) and try to commit. Confirm the hook blocks you.

## Debrief (15 min)

- Which of the linters would have caught the most recent real bug your team shipped?
- When does linting hurt instead of help? (Hint: when it flags style preferences as errors, when it's slower than the dev cycle, when its config drifts from the codebase reality.)
- Is suppressing a rule ever the right answer? When?
- ign-lint is brand new to most of you: which of its rules map to a mistake you've actually shipped in a Perspective project? Which feel like overreach? (We come back to the Ignition file structure — `project.json`, view exports, the gateway config volume — in Lab 04.)
