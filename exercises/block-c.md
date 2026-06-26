# Block C — Self-hosted runners: when, why, and how

**Duration:** ~90 minutes
* 20 min demo
* 25 min we-do
* 25 min you-do
* 15 min debrief
* ~5 min buffer

## Goal

You should leave this block able to:

- Decide whether a given job *needs* a self-hosted runner, or whether GitHub-hosted is fine
- Articulate the **security model** — a runner machine is highly trusted infrastructure
- Register a runner end-to-end (a sandbox one on your laptop, today) and de-register it cleanly
- Route a workflow job to a self-hosted runner via `runs-on: self-hosted` + labels

## Pre-flight

```bash
git fetch --tags
git checkout block-c-start
```

You'll need:

- Docker running locally
- A throwaway GitHub repo (don't use a shared/production repo — see the security discussion)
- A **GitHub Personal Access Token** with `repo` scope. Generate at <https://github.com/settings/tokens>. The token is short-lived in this exercise; revoke it after Block C.

If you'd like to read ahead: [`docs/self-hosted-runners.md`](../docs/self-hosted-runners.md).

## I do (20 min)

The instructor walks the *when* and *why* before the *how*.

**When GitHub-hosted is enough** (which is most of the time): your code builds and tests on a standard image, you're not blocked by network or compliance, you don't need access to local hardware.

**When self-hosted is required:**

1. **Network isolation** — the thing you need to deploy to is behind a firewall (an on-prem Ignition gateway, a PLC network, a private database). GitHub-hosted runners can't reach it.
2. **Compliance / data residency** — auditors require builds run on infrastructure your organization controls.
3. **Real hardware access** — testing against a physical PLC, a USB device, a specific OS configuration.
4. **Cost at very high volume** — sometimes, though usually not for small teams.

**Why it's dangerous:** a runner machine has full access to whatever it can reach on its network. If you connect a self-hosted runner to a public repo and accept PRs from forks, a malicious PR can execute arbitrary code *on your network* by adding a step to the workflow.

> **Rule:** never connect a self-hosted runner to a public repo with fork PRs enabled. If you must, use *ephemeral* runners that destroy themselves after every job, plus require approval for PRs from first-time contributors.

The instructor sketches the architecture: runner = lightweight agent that polls GitHub for assigned jobs, downloads the workflow, executes it, returns logs. There is no inbound network connection from GitHub to the runner — only outbound polling.

## We do (25 min)

Together, register an ephemeral Docker-based runner.

### 1. Generate a registration token

```bash
gh api -X POST "repos/<your-user>/<your-repo>/actions/runners/registration-token" \
  --jq .token
```

Save the output as `RUNNER_TOKEN` (don't commit it):

```bash
export RUNNER_TOKEN="..."     # paste the token here
export GH_REPO_URL="https://github.com/<your-user>/<your-repo>"
```

### 2. Start the runner

We use the well-maintained third-party image `myoung34/docker-github-actions-runner`:

```bash
docker run -d --rm \
  --name lab03-runner \
  -e REPO_URL="$GH_REPO_URL" \
  -e RUNNER_NAME="lab03-$(whoami)" \
  -e RUNNER_TOKEN="$RUNNER_TOKEN" \
  -e RUNNER_WORKDIR=/tmp/runner \
  -e LABELS="self-hosted,local-lab03" \
  -e EPHEMERAL=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  myoung34/github-runner:latest
```

Watch the logs:

```bash
docker logs -f lab03-runner
```

You should see a line like `Listening for Jobs`. The runner now appears in your repo at *Settings → Actions → Runners*.

### 3. Send it a job

Together, add a one-step workflow targeting your new runner:

```yaml
# .github/workflows/self-hosted-smoke.yml
name: Self-hosted smoke
on: [workflow_dispatch]
jobs:
  smoke:
    runs-on: [self-hosted, local-lab03]
    steps:
      - run: echo "Running on $(hostname) — runner is up."
```

Commit, push, then trigger via `gh workflow run self-hosted-smoke.yml`. Watch the job execute in `docker logs -f lab03-runner`.

## You do (25 min)

Now do the whole flow yourself on a clean repo, plus the cleanup.

1. Generate a fresh registration token (the one from We-do may have expired).
2. Start a runner *under a different name* (e.g., `lab03-solo-<your-initials>`) with the label `solo`.
3. Modify the existing lint job from Block B to route to your self-hosted runner: change `runs-on: ubuntu-latest` to `runs-on: [self-hosted, solo]`.
4. Open a PR. Confirm the lint job runs on your local runner (you'll see it in `docker logs`).
5. Read the job logs in the GitHub UI. Notice anything different from GitHub-hosted output? (Hint: your runner doesn't have `shellcheck` preinstalled — you'll get a real error if your workflow assumes it.)
6. Revert the change (`runs-on: ubuntu-latest`) — we want our normal CI back on the shared runners.
7. **De-register the runner cleanly:**
   ```bash
   docker stop lab03-runner    # ephemeral runners auto-cleanup after one job; this kills the polling loop
   ```
   Then in *Settings → Actions → Runners*, confirm the runner has gone offline. If it lingers as "Offline" for more than 30 seconds, remove it manually via the UI.
8. **Revoke your PAT** at <https://github.com/settings/tokens>. The token is one-use for this exercise; don't leave it lying around.

End state matches `block-c-end`.

## Stretch challenge `[OPTIONAL]`

Add a second label to your runner (e.g., `local-mac` or `local-linux`) and route *only* the `validate` job (`ops/validate.sh`) to it (keep `lint` on GitHub-hosted). Use the multi-label `runs-on: [self-hosted, local-mac]` syntax.

Confirm the `validate` job lands on your runner and the `lint` job lands on `ubuntu-latest`. This is the realistic pattern for the labs to come: route the *bits that need on-prem network access* (validating against / deploying to the gateway) to a self-hosted runner, leave everything else on GitHub-hosted.

## Debrief (15 min)

- Looking at your own work: which of your deploys would *require* a self-hosted runner today?
- What guardrails would you put around one? (Hint: ephemeral lifecycle, repo-scope-only, dedicated network segment, no shared secrets.)
- For Ignition specifically: where would the runner sit? On the gateway server itself, or on a separate deploy host? What does each choice imply about access?
- Is the cost of running your own runner worth what it buys you? When is it definitely not?
