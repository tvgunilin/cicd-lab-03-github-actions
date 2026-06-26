# Lab 03 — GitHub Actions

Day 2, Blocks A through D of the [CI/CD for Ignition Masterclass](https://github.com/mustry-academy/cicd-masterclass).

> Build a CI safety net around a real Ignition project: run linters that catch problems before they ship, write GitHub Actions workflows from scratch, and understand when to reach for self-hosted runners.

This is the third lab in the course. The subject is the same **Ignition project** you
worked on in [Lab 02](https://github.com/mustry-academy/cicd-lab-02-branching-and-prs) — a
Perspective HMI screen (a refrigeration-plant overview) and a couple of Python script
libraries, running on a local gateway you spin up yourself. Lab 02 had you edit those
project files and open PRs **by hand**; this lab makes the checks **automatic**: the
validation you ran manually becomes a required status check no one can merge past.

You don't need deep Ignition experience. The gateway's *administrative* complexity (config,
modules, databases, deploys) is deliberately **abstracted away** — the repo tracks only the
**project files**, and the gateway generates its own config on boot (into a Docker volume we
never commit). How those project files are structured, and how to deploy them properly,
is the subject of [Lab 04](https://github.com/mustry-academy/cicd-lab-04-ignition-file-based-deploy).

## Prerequisites

- Completed [Lab 02](https://github.com/mustry-academy/cicd-lab-02-branching-and-prs)
- Pass [`cicd-preflight`](https://github.com/mustry-academy/cicd-preflight)
- Docker (with the Compose V2 plugin) — ~1.5 GB RAM is plenty for the single gateway
- Python 3.10+ (for the linters: `ign-lint`, `yamllint`)
- A GitHub Personal Access Token with `repo` scope (for Block C — register a self-hosted runner). Generate ahead of class.

## Quick start

```bash
gh repo clone mustry-academy/cicd-lab-03-github-actions
cd cicd-lab-03-github-actions
cp .env.example .env
ops/setup.sh        # boots one Ignition gateway, waits for RUNNING, prints the URL + login
# open http://localhost:8088  → log in with the .env credentials
```

Before opening any PR, run the same checks CI runs — both are gateway-free and finish in
seconds:

```bash
ops/validate.sh                                              # every project file: valid JSON / parseable Python
pip install ign-lint==0.6.1
ign-lint --config rule_config.json --files "projects/**/view.json"   # Ignition-native linting of the Perspective views
```

The other linters Block A introduces (install separately — see `exercises/block-a.md`):

```bash
pip install yamllint==1.35.1
yamllint -c .yamllint.yml .
# actionlint, shellcheck install separately — see exercises/block-a.md
```

Stop the gateway when you're done:

```bash
ops/teardown.sh             # stop (keeps the gateway's data volume)
ops/teardown.sh --volumes   # stop and wipe gateway state for a fresh start
```

## Lab structure

| Block | Topic | Exercise |
|---|---|---|
| A | Validation and linters as your safety net | [`exercises/block-a.md`](./exercises/block-a.md) |
| B | GitHub Actions: workflows, jobs, steps | [`exercises/block-b.md`](./exercises/block-b.md) |
| C | Self-hosted runners: when, why, and how | [`exercises/block-c.md`](./exercises/block-c.md) |
| D | CI/CD pipelines that work; deployment strategy primer | [`exercises/block-d.md`](./exercises/block-d.md) |

## Checkpoints

```bash
git fetch --tags
git checkout block-a-start      # the "seeded broken" starting state
git checkout block-a-end
git checkout block-b-start
git checkout block-b-end
git checkout block-c-start
git checkout block-c-end
```

Block D is discussion + worksheet; no checkpoint tags.

## Repo layout

```
cicd-lab-03-github-actions/
├── README.md
├── docker-compose.yml                 ← one Ignition gateway (named volume + bind-mounted projects/)
├── .env.example                       ← copy to .env before running
├── .gitattributes                     ← LF normalization so Ignition's JSON resources stay clean
├── .yamllint.yml                      ← built up during Block A
├── .pre-commit-config.yaml            ← Block A stretch target
├── rule_config.json                   ← ign-lint rule configuration
├── .github/
│   ├── workflows/
│   │   └── ci.yml                     ← the workflow we build in Block B
│   └── pull_request_template.md
├── ops/
│   ├── setup.sh                       ← boot the gateway and wait for RUNNING
│   ├── scan.sh                        ← push project-file edits to the running gateway
│   ├── teardown.sh                    ← stop the gateway (--volumes to wipe state)
│   └── validate.sh                    ← the PR green/red check (valid JSON + parseable Python)
├── projects/                          ← the Ignition project (bind-mounted into the gateway)
│   └── lab-project/
│       ├── project.json
│       ├── com.inductiveautomation.perspective/   ← the Perspective HMI dashboard + page config
│       └── ignition/script-python/lab/            ← Python scripts (display + util helpers)
├── exercises/                         ← block-a..d
├── docs/                              ← reference reading
├── instructor-notes/                  ← answer keys (read after solo work)
└── worksheets/
    └── deployment-strategy-worksheet.md
```

## The Compose stack

A single Ignition 8.3 gateway. Two things to understand about how it's wired:

- **The gateway's own config and runtime state live in a named volume** (`ignition-data`) that the gateway generates itself on first boot. It never lands in the repo — which is exactly why you never see or touch gateway config in this lab. (That's Lab 04's subject.)
- **Only `./projects` is bind-mounted** from the repo into the gateway. So the project files you (and CI) validate *are* the project files the gateway runs.

```yaml
services:
  ignition:
    image: inductiveautomation/ignition:8.3.6
    ports: ["8088:8088"]
    volumes:
      - ignition-data:/usr/local/bin/ignition/data        # gateway-owned, self-generated, not in git
      - ./projects:/usr/local/bin/ignition/data/projects   # the one thing you edit

volumes:
  ignition-data:
```

> The gateway regenerates a `.resources/` blob store and other operational files inside `projects/` as it runs. Those are gateway-owned churn and are gitignored — if you ever see them in `git status`, your ignore rules are off.

> **CI is built from scratch here.** Lab 02 deliberately shipped no CI — `ops/validate.sh` was something *you* remembered to run. This lab adds a `.github/workflows/ci.yml` that you write block-by-block, turning that validation (plus `ign-lint`) into a check every PR must pass. We do **not** call any reusable workflows — you see what's inside before you call it.

## Licence

Apache 2.0 — see [`LICENSE`](./LICENSE).
