# Block A — instructor answer key

> **Do not read this before you've attempted the You-do solo.** Half the value is the diagnostic skill — running each tool, reading the output, deciding what to do.

## The seeded-error recipe

The shipped `main` of this lab is **clean** — no planted issues. To produce `block-a-start`, a maintainer applies the following seed commit on top of `main` and tags it.

### Seed commit: "chore: seed Block A lint issues (do not merge)"

Six planted issues across five files:

### 1. `sample-app/Dockerfile` — hadolint DL3008/DL3009/DL3015

Replace the clean Dockerfile with this messy version:

```dockerfile
FROM python:3.12

WORKDIR /app

RUN apt-get update && apt-get install -y curl

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5051

CMD ["python", "app.py"]
```

Issues hadolint will flag:
- `DL3007` — using `python:3.12` instead of pinning to a specific minor version like `python:3.12-slim` or `python:3.12.5-slim`
- `DL3008` — `apt-get install -y curl` without pinning the version
- `DL3015` — missing `--no-install-recommends`
- `DL3009` — `apt-get update` without cleanup (`rm -rf /var/lib/apt/lists/*`)

### 2. `docker-compose.yml` — yamllint

Add one line longer than 120 chars and one line with trailing whitespace:

```yaml
    # This is an overly-long comment that exists purely so yamllint has something to flag — please remove me when fixing lint issues.   
                                                                                                                                       ^ trailing whitespace
```

(yamllint will flag the trailing whitespace; line-length is currently *disabled* in `.yamllint.yml`, so the long line itself won't flag — but a sharp student should notice it anyway.)

### 3. `scripts/healthcheck.sh` — shellcheck

Replace with a deliberately bad version:

```bash
#!/usr/bin/env bash

URL=${HEALTHCHECK_URL:-http://localhost:5051/health}
MAX_RETRIES=${HEALTHCHECK_MAX_RETRIES:-10}

for i in $(seq 1 $MAX_RETRIES); do
  if curl -fsS --max-time 3 $URL >/dev/null; then
    echo healthcheck ok $URL
    exit 0
  fi
  sleep 2
done

exit 1
```

Issues shellcheck flags:
- `SC2086` — `$URL`, `$MAX_RETRIES` unquoted
- Missing `set -euo pipefail` (not strictly a shellcheck error in all configs, but `info` level)

### 4. `sample-app/app.py` — ruff

Edit to introduce two issues:

```python
"""Flask sample app for the Branching & PRs lab."""

import os

from flask import Flask, jsonify, request, g    # ← `g` is unused
import redis


def create_app(redis_client=None):
    app = Flask(__name__)
    app.redis = redis_client or redis.Redis.from_url(
        os.environ.get("REDIS_URL", "redis://localhost:6378/0"),
        decode_responses=True,
    )

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/greet")
    def greet():
        name = request.args.get("name", "world")
        if name == None:                          # ← E711
            name = "world"
        count = app.redis.incr(f"greet:{name}")
        return jsonify(message=f"Hello, {name}!", count=count)

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5051)
```

Issues ruff flags:
- `F401` — unused import `g`
- `E711` — `== None` should be `is None` (also dead code since `request.args.get` returns the default if missing)

### 5. `.github/workflows/example.yml` — actionlint

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

## You-do solutions (block-a-end)

After Block A, the participant should have:

1. **Dockerfile reverted** to the clean shipped state (which already pins to `python:3.12-slim` and uses `pip install --no-cache-dir`).
2. **docker-compose.yml** — trailing whitespace stripped, long line removed.
3. **healthcheck.sh** — quoted variables, `set -euo pipefail` added. (The shipped clean state already has this.)
4. **app.py** — unused import removed; `if name == None:` block removed entirely (it's dead code).
5. **example.yml** — either fixed (`actions/checkout@v4`, define the env var) or deleted (acceptable; example workflows aren't required).
6. **`.yamllint.yml`** — the shipped config disables `line-length`. Participant should add a comment explaining why (long REDIS_URL strings, long compose env lines).

## Grading the work

In peer review of the participant's Block A PR, look for:

- **All linters silent.** Each of `yamllint`, `ruff`, `hadolint`, `shellcheck`, `actionlint` should produce zero output when run.
- **Justified config changes.** If they disabled a `ruff` or `yamllint` rule, the commit message or the config file comment should explain why.
- **No "fixed by deleting it" cheats.** Removing `app.py` to silence ruff is wrong. Removing `example.yml` is fine since it was always optional.

## Stretch — pre-commit

The shipped `.pre-commit-config.yaml` wires all five linters into a pre-commit hook. A participant who completes the stretch should be able to:

```bash
pre-commit install
# Now make a deliberately bad change:
echo "import os, os" >> sample-app/app.py
git add sample-app/app.py
git commit -m "test: should be blocked"
# → pre-commit fails the commit, ruff flags the duplicate import
```

If the commit succeeds anyway, check: did they actually run `pre-commit install`? Is `.git/hooks/pre-commit` populated?

## Debrief crib

- *"Which linter would have caught your most recent bug?"* — Push past "we don't have bugs." Specific examples beat abstract claims.
- *"When does linting hurt?"* — Three honest answers:
  1. When it flags style preferences and blocks merge (use `nitpick:` not `issue:`).
  2. When it's slower than the dev loop (lint on save, not lint on push).
  3. When the team didn't agree to the rules — config-by-accident is worse than no config.
- *"`# noqa` ever right?"* — Yes, when the linter is wrong about the specific case. Always include a comment explaining *why*. `# noqa: E501  # link too long to wrap` is fine; bare `# noqa` is not.
- *"Which transfer to Ignition?"* — yamllint (for `project.json`-adjacent YAML), shellcheck (for deploy scripts), actionlint (universal). Hadolint only if you containerize gateways. Ruff only if you use Python tooling around Ignition. We come back to this in Lab 04.
