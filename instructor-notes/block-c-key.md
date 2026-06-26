# Block C — instructor answer key

> Block C is mostly hands-on infrastructure work. The "answer" is "the runner ran a job successfully and was cleaned up." The interesting content is the *security discussion* in the debrief.

## What success looks like

By the end of the You-do, the participant has:

1. Registered a self-hosted runner against their throwaway repo via `docker run`.
2. Modified a CI job to target `runs-on: [self-hosted, solo]`.
3. Confirmed the job executed locally (visible in `docker logs lab03-runner`).
4. Reverted the workflow change so `ubuntu-latest` is back as the default.
5. Stopped the runner container (`docker stop`) and confirmed it's gone from *Settings → Actions → Runners*.
6. Revoked the PAT used during the exercise.

If any of those steps is missing, especially #6, push them to complete it. A lingering PAT is a real security smell, not a procedural detail.

## The runner command, annotated

```bash
docker run -d --rm \                              # detached, auto-clean on exit
  --name lab03-runner \                           # name for `docker logs`/`docker stop`
  -e REPO_URL="$GH_REPO_URL" \                    # which repo the runner serves
  -e RUNNER_NAME="lab03-$(whoami)" \              # appears in the GitHub UI
  -e RUNNER_TOKEN="$RUNNER_TOKEN" \               # registration token (≤1h lifetime)
  -e RUNNER_WORKDIR=/tmp/runner \                 # where the runner stages files
  -e LABELS="self-hosted,local-lab03" \           # used by `runs-on:` matching
  -e EPHEMERAL=true \                             # auto-terminate after one job
  -v /var/run/docker.sock:/var/run/docker.sock \  # so the job can use Docker
  myoung34/github-runner:latest                   # community-maintained image
```

The mounted Docker socket is convenient for the lab but is itself a security trade-off — anything in the runner can use the host's Docker daemon, which is effectively root on the host. In production, prefer DinD (Docker-in-Docker) or rootless Docker over a mounted socket.

## Common stumbles

- **"My runner isn't picking up jobs."** Three checks:
  1. Is the runner running? `docker ps | grep runner`
  2. Does the workflow's `runs-on:` match the runner's labels? `runs-on: [self-hosted, solo]` needs both labels on the runner.
  3. Is the runner online in GitHub? *Settings → Actions → Runners* should show it green.
- **"Registration token expired."** They lifetime is one hour. Regenerate via `gh api -X POST .../runners/registration-token`.
- **"shellcheck not installed on the runner."** Right — the runner image doesn't preinstall it. Either install in the workflow (`sudo apt-get install -y shellcheck`) or `apt-get install` it into a customized runner image. This is a *good thing* for the lesson: GitHub-hosted runners have a lot pre-installed; your runner has only what you put on it.
- **"The runner stopped after one job."** Expected — `EPHEMERAL=true`. The runner is meant to be ephemeral.
- **"Docker logs are full of polling messages."** Normal. Look for the `Running job: <name>` line when the job actually picks up.

## Removing offline runners

If a runner shows as "Offline" in the GitHub UI for more than 30 seconds after `docker stop`:

```bash
gh api -X DELETE "repos/<user>/<repo>/actions/runners/<runner-id>"
```

Where `<runner-id>` comes from:

```bash
gh api "repos/<user>/<repo>/actions/runners" --jq '.runners[] | {id, name, status}'
```

This is rare for ephemeral runners but common for long-lived ones that died unexpectedly.

## Debrief crib

- *"Which of your deploys would require self-hosted?"* — Push for specifics. "Maybe?" is not an answer. "Our gateway is on a private network behind our customer's VPN; GitHub-hosted runners physically can't reach it" is.
- *"What guardrails would you put on a production self-hosted runner?"* — Look for at least three of:
  1. **Ephemeral lifecycle** — destroy after every job
  2. **Repo-scope only** — no org or enterprise scope
  3. **Network-isolated** — its own subnet, only the outbound it needs
  4. **No persistent secrets** — short-lived tokens via OIDC, not stored secrets
  5. **Restricted PR triggers** — require approval for first-time contributors
- *"Where does the runner sit for an Ignition shop?"* — Most realistic: a dedicated build VM (Linux or Windows) that has network access to the gateway server. Less realistic: the runner *on* the gateway server itself (you don't want CI workloads competing with the runtime). We come back to this in Lab 05.
- *"When is self-hosted definitely not worth it?"* — Small teams, public repos, simple builds. The operational cost outweighs the convenience.

## Stretch — multi-label routing

A participant who completed the stretch should have:

- Runner registered with at least two labels (e.g., `self-hosted,local-mac`)
- Workflow with the `validate` job routed to `runs-on: [self-hosted, local-mac]` and the `lint` job staying on `ubuntu-latest`

Verify by watching both jobs run: `validate` in `docker logs`, `lint` in the GitHub UI's normal log view.

If they put *both* jobs on self-hosted, that defeats the lesson. The whole point of labels is selective routing — only the things that need on-prem network access go to self-hosted; everything else stays on GitHub-hosted for free, reliable infrastructure.

## Cleanup script (for instructor convenience)

If multiple participants leave runners around at end of class:

```bash
# List all offline runners in the cohort org
gh api "orgs/mustry-academy-cohort/actions/runners" \
  --jq '.runners[] | select(.status == "offline") | {id, name}'

# Delete by ID
for id in <list of ids>; do
  gh api -X DELETE "orgs/mustry-academy-cohort/actions/runners/$id"
done
```

(Adjust the org name as needed.)
