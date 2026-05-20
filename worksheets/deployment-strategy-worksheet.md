# Deployment strategy worksheet

Fill this out for **your own team's product** (or, if you don't have one, for a recent Ignition client engagement). Twenty minutes is enough for a rough draft. This doubles as the start of your Day 2 → Day 3 homework — tonight, you'll polish it into a one-page document and PR it to the cohort playground repo.

---

## Your team

- **Product:** _what does your team ship?_
- **Cadence:** _how often do you deploy to production today?_
- **Team size:** _how many people commit code?_

## Current state — be brutally honest

> The point isn't aspiration; it's an accurate baseline. "We SSH in and copy files" is a perfectly good answer if it's true.

- _How does a change actually get from a developer's laptop to production today?_
- _Who runs the deploy? Is it the same person who wrote the change?_
- _What does rollback look like if something goes wrong mid-deploy?_

## Pain points — specific, not abstract

> Name real incidents you've lived through, not generic complaints.

1.
2.
3.

## Target deployment strategy

Circle one (or write your own):

- [ ] Rolling
- [ ] Blue/green
- [ ] Canary
- [ ] Stay where we are (deliberately)
- [ ] Something else: _______

## Why this strategy fits

> Reference at least two of: risk profile, capacity budget, team skill, customer impact, regulatory constraint, observability maturity.

-
-

## Riskiest assumption

> What's the *one thing* that, if it turns out to be wrong, derails the whole migration plan?

- _Assumption:_
- _Why it might be wrong:_
- _How you'd test it cheaply, this week:_

## One small next step — by next Monday

> Concrete. Verb + noun + day. "Investigate blue/green" is not a step. "Pair with Alex on Tuesday to spin up a second gateway VM" is.

- _Action:_
- _Owner:_
- _Day:_

---

## Submission

For the Day 2 → Day 3 homework: polish this into a one-page document (Markdown, ~300–500 words) and open a PR adding it to the cohort playground repo. Use the PR template; tag a peer as reviewer. The deadline is the start of Day 3.
