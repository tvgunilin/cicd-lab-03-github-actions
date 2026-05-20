# Deployment strategies — cheat sheet

Reference reading for Block D. Three strategies, side by side, with honest trade-offs and an Ignition-specific take at the end.

## The scenario

Imagine you're shipping v1.5 of your product. v1.4 is in production. The change is small but irreversible (a schema migration, a new persisted field). Customers are using it right now. How do you ship?

The answer depends on which deployment strategy your team has settled on. There are three popular ones.

## Rolling

Replace instances gradually. At any given moment, some traffic is on v1.4 and some on v1.5. New instances come online; old ones drain and shut down.

```
time →
v1.4: ████████░░░░░░░░    (old, draining)
v1.5: ░░░░████████████    (new, ramping)
```

**Pros**

- No extra capacity needed. You only ever run N instances.
- Smooth user experience if requests are stateless and the version difference is forward-compatible.
- The default in most orchestrators (Kubernetes Deployments, ECS, Nomad).

**Cons**

- Hard to roll back partway through. If you've replaced 50% and the new version is bad, the failed-back path is "deploy v1.4 again" — which is itself a deploy.
- Both versions must coexist for the duration of the rollout. Schema changes need to be forward-and-backward compatible, often with multi-step migration plans.

**Fits when**

- Backend services, stateless requests, forward-compatible schema changes.
- "We ship many small changes per day; the cost of full blue/green per change is too high."

## Blue/green

Two complete environments — *blue* (current) and *green* (new). Deploy to green, smoke-test, then flip traffic from blue to green in one step. Blue stays around for instant rollback.

```
blue (v1.4):  ████████████████  ░░░░░░░░░░░░░░  (kept warm)
green (v1.5): ░░░░░░░░░░  smoke  ████████████████ (switched)
                                ↑ flip
```

**Pros**

- Instant rollback. Flip traffic back to blue if anything goes wrong.
- No version coexistence at the application layer — all green traffic is v1.5.
- Conceptually simple to reason about.

**Cons**

- 2× capacity during deploy. You pay for both environments simultaneously.
- Schema migrations are still tricky — the *database* is usually shared. Plan migrations to be backward-compatible (additive only) so blue can keep running while green deploys.

**Fits when**

- Critical services where rollback speed matters more than capacity cost.
- Releases are infrequent enough that the capacity cost is acceptable.
- Many Ignition deployments — gateways are often pets, and "spin up a second gateway, deploy, switch traffic" is a feasible pattern.

## Canary

Deploy to a small percentage of traffic (1%, then 5%, then 25%, then 100%). Watch metrics at each step. Roll back at any percentage if anything degrades.

```
canary:    ████  ░░░░░░░░░░░░░░░░░░░░░░░░     (1% of traffic)
canary:    ██████████  ░░░░░░░░░░░░░░░░░░░    (5%)
canary:    ████████████████████  ░░░░░░░      (25%)
canary:    ████████████████████████████████   (100% — full rollout)
```

**Pros**

- Catches regressions with real users at limited blast radius.
- Best strategy for risk-bounded shipping at scale.

**Cons**

- Requires traffic-splitting machinery (service mesh, load balancer rules, feature flags). Operationally expensive.
- Slow. A real canary rollout might take hours or days.
- Hard for Ignition specifically — you can't easily send "1% of HMI users" to v1.5. The "users" are often plant operators on a fixed set of clients.

**Fits when**

- High-traffic services with mature observability.
- Engineering teams that already have feature-flag or traffic-splitting infrastructure in place.

## What about Ignition?

Most Ignition shops don't have rolling, blue/green, or canary as a deliberate strategy yet — they have *"backup, copy files over, restart the gateway."* That's not on this list. It's not a strategy; it's a coping mechanism.

The realistic-for-Ignition adoption ladder:

1. **Backup + copy + restart** (today, most shops) → high risk, instant downtime
2. **Backup + scripted deploy + smoke test** → still downtime, but reproducible
3. **Blue/green between two gateways with a network-level switch** → no downtime, instant rollback. Many integrators are here.
4. **Canary at the project level** — deploy to a non-production gateway, soak-test against production data, then swap. Realistic for multi-gateway shops.

The capstone in this masterclass builds toward step 3.

## How to pick

Use this decision tree:

```
Do you have traffic-splitting infrastructure?
├── Yes → Canary is on the table; pick it if rollouts are risky and you have observability.
└── No
    ├── Can you afford 2× capacity during deploys?
    │   ├── Yes → Blue/green. Fast rollback wins for most teams.
    │   └── No → Rolling. Stateless services only; plan schema changes carefully.
```

For Ignition specifically: blue/green at the gateway level is the realistic target for most shops in this cohort. Canary is achievable but requires structural changes most plants aren't ready for.

## What to write in your worksheet

You're filling out [`worksheets/deployment-strategy-worksheet.md`](../worksheets/deployment-strategy-worksheet.md) for your own team. The worksheet asks for:

- **Current state** — what does your deploy *actually* look like today? Be honest, not aspirational.
- **Target state** — which strategy fits your reality and your appetite for change?
- **Riskiest assumption** — what could derail the migration?
- **One small next step** — what would you do *next Monday* to move from current to target?

Keep it short. One page. The point isn't a polished design doc; it's a clear-eyed assessment.
