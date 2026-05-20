# Lab 03 — GitHub Actions

Day 2, Blocks A through D of the [CI/CD for Ignition Masterclass](https://github.com/mustry-academy/cicd-masterclass).

> Build a CI safety net: run linters that catch problems before they ship, write GitHub Actions workflows from scratch, and understand when to reach for self-hosted runners.

This is the third lab in the course. Like labs 01 and 02, it deliberately stays out of Ignition territory — the sample app is the same Flask + Redis stack you finished lab-02 with. We're adding CI *around* the code, not introducing new code. Ignition-specific deployments arrive in Lab 04.

## Prerequisites

- Completed [Lab 02](https://github.com/mustry-academy/cicd-lab-02-branching-and-prs)
- Pass [`cicd-preflight`](https://github.com/mustry-academy/cicd-preflight)
- A GitHub Personal Access Token with `repo` scope (for Block C — register a self-hosted runner). Generate ahead of class.

## Quick start

```bash
gh repo clone mustry-academy/cicd-lab-03-github-actions
cd cicd-lab-03-github-actions
cp .env.example .env
docker compose up -d
curl http://localhost:5051/health          # → {"status":"ok"}
```

Run the tests locally:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r sample-app/requirements.txt
pytest sample-app/tests -q
```

Run the linters locally (Block A introduces these):

```bash
pip install yamllint==1.35.1 ruff==0.6.9
yamllint -c .yamllint.yml .
ruff check .
# hadolint, actionlint, shellcheck install separately — see exercises/block-a.md
```

The lab also runs in [GitHub Codespaces](https://github.com/features/codespaces) — the [`.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json) preinstalls everything.

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
├── PLAN.md                            ← design doc for this lab
├── docker-compose.yml                 ← Flask + redis dev stack (carried from lab-02)
├── .env.example                       ← copy to .env before running
├── .yamllint.yml                      ← built up during Block A
├── .pre-commit-config.yaml            ← Block A stretch target
├── .github/
│   ├── workflows/
│   │   └── ci.yml                     ← the workflow we build in Block B
│   └── pull_request_template.md
├── exercises/
│   ├── block-a.md                     ← Validation and linters
│   ├── block-b.md                     ← GitHub Actions workflows
│   ├── block-c.md                     ← Self-hosted runners
│   └── block-d.md                     ← Deployment strategy primer
├── docs/                              ← reference reading
│   ├── validation-and-linters.md
│   ├── self-hosted-runners.md
│   └── deployment-strategies.md
├── instructor-notes/                  ← answer keys (read after solo work)
│   ├── block-a-key.md
│   ├── block-b-key.md
│   ├── block-c-key.md
│   └── block-d-key.md
├── scripts/
│   └── healthcheck.sh                 ← subject of the shellcheck demo
├── sample-app/                        ← Flask + redis (same as lab-02)
│   ├── README.md
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── tests/
│       └── test_app.py
└── worksheets/
    └── deployment-strategy-worksheet.md
```

## The Compose stack

Identical to lab-02 — a small Flask app on `:5051` and a redis sidecar on `:6378`. Carried forward verbatim so you're not learning new code; you're adding CI around the code you already know.

> **CI is built from scratch here.** Unlike lab-02 (which deliberately had no CI), this lab adds a `.github/workflows/ci.yml` that you write block-by-block. We do **not** call any reusable workflows — students see what's inside before they call it.

## Licence

Apache 2.0 — see [`LICENSE`](./LICENSE).
