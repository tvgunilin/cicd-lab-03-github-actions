# Block D — instructor answer key

> Block D is a discussion + worksheet block. There's no "correct" deployment strategy; there's a *defensible* one for each team. The answer key gives you reference responses for the three scenarios and a rubric for evaluating the worksheets.

## Reference answers for the We-do scenarios

### Scenario 1 — A factory-floor Ignition gateway running 24/7

**Best fit:** Blue/green.

**Why:**
- Downtime is expensive (production lines are stopped). Rolling doesn't apply — gateways are pets, not cattle.
- Rollback must be instant — you can't "fail forward" on a factory floor.
- Capacity cost is fine — a second gateway is one VM, not 1000.

**Edge cases to surface:**
- Schema migrations on shared historian databases still require care.
- "Switching traffic" between gateways means switching the *HMI clients* — often a manual step that needs operator coordination.
- License costs may double during the deploy window (depends on Inductive Automation's terms).

### Scenario 2 — A SaaS web product, 100k DAU, ten engineers, mature observability

**Best fit:** Canary (or rolling with feature flags).

**Why:**
- High traffic + mature observability = canary is operationally viable.
- Ten engineers can build/maintain the traffic-splitting machinery.
- Risk-bounded shipping is genuinely valuable at this scale.

**Edge cases to surface:**
- If the org *doesn't yet have* feature flags, that's the prerequisite work — not the deployment strategy. Canary without flags is much harder.
- "Canary" can mean different things — by traffic %, by user cohort, by region. Press them.

### Scenario 3 — A nightly batch job that takes 6 hours

**Best fit:** Either blue/green or "atomic switch" — flip the cron to point at the new image at midnight, leave the old image as instant fallback.

**Why:**
- Rolling doesn't apply — only one job runs at a time.
- Canary doesn't really apply either — you'd canary on a *fraction* of input data, which is closer to a "shadow run" pattern than a canary.

**Edge cases to surface:**
- Shadow runs are an underrated pattern for batch jobs — run the new version against last night's data in parallel; compare outputs; diff.
- Idempotency matters more here than for online services — if the job fails halfway, can you restart cleanly?

## Worksheet rubric

The shipped [`worksheets/deployment-strategy-worksheet.md`](../worksheets/deployment-strategy-worksheet.md) has six sections. Strong worksheets have:

| Section | What "good" looks like |
|---|---|
| **Current state** | Brutally honest. "We SSH in and copy files" is a good answer if it's true. Aspirational claims are a smell. |
| **Pain points** | Specific incidents, not abstract complaints. "On 2026-03-15 we lost 4 hours because rollback meant restoring from gateway backup" is real. |
| **Target strategy** | Named: rolling, blue/green, canary, or "stay where we are." Each is acceptable with the right justification. |
| **Why this fits** | Names at least two of: risk profile, capacity budget, team skill, customer impact, regulatory constraint. |
| **Riskiest assumption** | The thing that could derail the migration. Schema migrations, network architecture, who-owns-the-deploy — all common answers. |
| **Next Monday step** | *Concrete*. "Set up a staging gateway" is better than "investigate blue/green." Best: "Pair with Alex on Tuesday to spin up a second gateway VM and document the differences." |

Common mistakes in worksheets:

- **Cargo-culting canary.** Most Ignition shops aren't ready for canary; if a worksheet picks canary, the "next Monday step" should be "build feature-flag infrastructure," not "deploy a canary."
- **Skipping the riskiest-assumption section.** This is the most important section. Push them to fill it.
- **Vague next steps.** "Investigate" and "look into" are not steps. Steps have a verb, a noun, a day.

## Debrief crib

- *"What did your partner spot that you missed?"* — Often: the *current state* section. We're all worse at honest self-assessment than at assessing others. Embrace this.
- *"Where did your partner's choice surprise you?"* — Common surprise: a team that does much less ambitious deploys than the engineers personally would. That's fine; deployment maturity has to match the org's risk appetite.
- *"Is 'we don't deploy continuously' ever right?"* — Yes. Industrial control, regulated medical, defense — there are domains where "we deploy quarterly with a 2-week validation window" is the *right* answer. The CI/CD masterclass still applies; just the cadence is different.

## Homework hand-off

The Day 2 → Day 3 homework (per [`../cicd-masterclass/CURRICULUM.md`](../cicd-masterclass/CURRICULUM.md)) is to write a one-page document describing the team's current and target CI/CD state and PR it to the cohort playground repo. The worksheet **is** that document, plus a bit of polish.

If a participant's worksheet is solid, the homework is editing — not new thinking. If it isn't, this is the time to give them clear feedback so they have a usable starting point tonight.

## Day 2 wrap-up (instructor)

End the day with three short statements:

1. **What we just built.** A CI safety net + the start of a deploy plan. That's 80% of "CI/CD" for most teams.
2. **What's still missing.** Real deploys to a real Ignition gateway. We start tomorrow with the Ignition file structure.
3. **Sleep on this.** The deployment strategy is the most thought-heavy piece of the week. Let it marinate; tomorrow's homework PR is editing, not new thinking.
