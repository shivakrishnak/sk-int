---
layout: default
title: "DevOps - META Patterns"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 9
permalink: /devops-cicd/meta-patterns/
---

# Deployment Decision Framework

🎯 Interview Weight: very high - Decision frameworks demonstrate
staff-level systems thinking about deployments.

---

### 🎯 Model Answer

**30 seconds:**
> Deployment decision framework: a structured approach to choosing
> a deployment strategy based on risk, impact, and reversibility.
> Inputs: change risk (schema change? new dependency? blast radius?),
> traffic characteristics (high volume? mobile users? B2B SLA?),
> rollback complexity (DB migration? stateful?), and observability
> readiness (can you detect a failure in < 5 minutes?). Output:
> deploy strategy (recreate, rolling, blue-green, canary) +
> monitoring duration + rollback trigger conditions.

**3 minutes (Staff):**
> Decision framework - full model:
>
> Step 1 - Classify the change:
> Tier 1 (critical path, high risk): payment processing, auth,
> order service. Requires: canary or blue-green + manual approval.
> Tier 2 (important, medium risk): notification service, search.
> Requires: rolling update + automated post-deploy monitoring.
> Tier 3 (low risk): static content, config-only changes.
> Requires: rolling update, no special monitoring.
>
> Step 2 - Assess DB migration risk:
> No migration: standard rolling update.
> Backward-compatible migration (add column, add index): blue-green safe.
> Breaking migration (remove column, rename): requires expand-contract.
> Must be split into 2 deployments separated by at least 1 release cycle.
>
> Step 3 - Evaluate rollback complexity:
> Easy (stateless service): any strategy works, 2-minute rollback.
> Medium (stateful with config): rolling update, 10-minute rollback.
> Hard (DB migration involved): canary + feature flag. Migration
> rollback must be scripted and tested in staging.
>
> Step 4 - Confirm observability readiness:
> SLOs defined? Alert when error rate > SLO budget burn rate?
> Dashboards available? Deployment marker set?
> Without observability: cannot detect failure. Don't deploy Tier 1/2
> without proper monitoring in place.
>
> Step 5 - Choose strategy and duration:
> Blue-green: zero-downtime, instant rollback, requires 2x infra.
> Canary: gradual, needs metric analysis, best for risk reduction.
> Rolling: simple, slow rollback, good default.
> Feature flag: no deployment risk, rollback = flip flag.
>
> Framework summary:
> High risk + hard rollback + critical path -> blue-green + feature flag.
> High risk + easy rollback + good observability -> canary.
> Medium risk + no DB change -> rolling update.
> Low risk + config change -> rolling update + no special monitoring.

**Blank Mind Recovery:**

**(1) Restate:** "Deployment framework: classify change tier, assess DB migration,
evaluate rollback complexity, confirm observability, then choose strategy."

---

### ⚖️ Comparison Table

| Change Type | Risk | DB Migration | Strategy | Monitoring |
|-------------|------|-------------|---------|------------|
| Config change | Low | None | Rolling | 5 min |
| New feature (flag) | Low | None | Rolling | 5 min |
| API change | Medium | None | Canary | 30 min |
| Payment processing | High | Additive | Blue-green | 60 min |
| Schema rename | Very High | Breaking | Expand-contract | Multi-deploy |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Deployment strategy selection criteria |
| Staff | 10 min | Full decision framework + DB migration risk |
| Principal | 15 min | Organizational deployment governance + risk-based policy |

**[STAFF]** How would you design a deployment decision framework for a team?

> *Why they ask:* Tests systems thinking + ability to codify engineering wisdom.
>
> *Full answer:* "I'd start by classifying services by business criticality:
> what is the blast radius if this service has a 5-minute outage?
> Payment processing -> P1 (user-facing revenue impact).
> Background email sending -> P3 (delayed, not lost).
>
> For each classification level, define: which deployment strategy
> is required, what test gate is required, what monitoring duration
> is required, and what approval is required.
>
> The framework is codified in the CI/CD template: when the team
> creates a new service, they declare its criticality tier in the
> service manifest. The platform automatically applies the right
> deployment strategy.
>
> The hard part is DB migrations. I'd create a migration
> classification: additive-only (safe for rolling/blue-green) vs
> breaking (requires expand-contract over multiple releases).
> This is documented and enforced via Liquibase/Flyway policies.
>
> Review quarterly: look at the DORA metrics. If change failure
> rate increases, the framework needs a stricter gate. If lead
> time increases too much, some gates can be relaxed."
>
> *What separates good from great:* Codifies the framework into
> the platform rather than leaving it as a wiki page nobody reads.

---

---

# CI/CD Maturity Model

🎯 Interview Weight: high - The maturity model helps teams
understand their current state and chart a path forward.

---

### 🎯 Model Answer

**30 seconds:**
> CI/CD maturity model: a framework for assessing and improving
> an organization's continuous integration and delivery practices.
> Levels: Level 1 (ad-hoc: manual, undocumented deployments),
> Level 2 (basic CI: automated builds and tests), Level 3
> (standardized: consistent pipelines, automated deployment to staging),
> Level 4 (optimized: canary/blue-green, automated rollback, DORA tracking),
> Level 5 (elite: full progressive delivery, platform engineering,
> deployment on demand). Most organizations sit at Level 2-3.

**3 minutes (Staff):**
> Maturity model details and application:
>
> Level 1 - Ad Hoc:
> Deployments: SSH to server, git pull, restart service.
> Tests: manual, run when someone remembers.
> Documentation: informal.
> Risk: every deployment is a snowflake event.
> Improvement: version control + automated build + any CI tool.
>
> Level 2 - Basic CI:
> CI: automated build + unit tests on every commit.
> Deploy: still manual or scripted but not fully automated.
> Artifacts: versioned (Docker or JAR).
> Quality: code reviews required.
> Improvement: automate deployment to staging.
>
> Level 3 - Standardized CD:
> All environments deployed automatically from CI.
> Quality gates: coverage thresholds, static analysis.
> Staging = production-like.
> Configuration: environment-specific, version-controlled.
> Improvement: add canary/blue-green, observability, DORA measurement.
>
> Level 4 - Optimized:
> Progressive delivery: canary or blue-green.
> Automated rollback: triggered by metrics.
> DORA metrics: measured and reviewed.
> Platform: shared CI templates, self-service environments.
> Improvement: platform engineering, reduce cognitive load further.
>
> Level 5 - Elite (Platform Engineering):
> Deployment frequency: multiple times per day.
> Lead time: < 1 hour commit-to-production.
> Change failure rate: < 15%.
> MTTR: < 1 hour.
> Platform: self-service, golden paths, IDP with Backstage.
> Engineers focus entirely on business logic.
>
> How to use the maturity model:
> Assess current state honestly.
> Identify the highest-value improvement at the current level.
> Do NOT skip levels: attempting canary before stable CI
> causes more problems.

**Blank Mind Recovery:**

**(1) Restate:** "CI/CD maturity: Level 1 (manual) to Level 5 (platform engineering).
Measure with DORA. Improve one level at a time."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Maturity levels + assessment |
| Staff | 9 min | Maturity roadmap + DORA correlation + prioritization |

---

---

# DevOps Transformation Mental Model

🎯 Interview Weight: very high - Mental models demonstrate
mastery-level understanding transferable to any domain.

---

### 🎯 Model Answer

**30 seconds:**
> DevOps transformation mental model: DevOps is not a tool
> or a role, it is a system optimization. The Three Ways
> (Gene Kim, The Phoenix Project): Flow (fast left-to-right
> delivery), Feedback (amplify right-to-left signals: failures
> caught early), Continuous Learning (experiment + learn + improve).
> The bottleneck is almost never the developers. It is usually:
> handoffs (dev -> ops), batch sizes (large releases), and
> feedback delay (test results days after coding).

**3 minutes (Staff):**
> DevOps transformation - mental model in depth:
>
> The Three Ways:
>
> First Way - Flow:
> See the whole system from commit to production.
> Identify and eliminate handoffs, waiting queues, and
> large batches. Small, frequent deployments reduce flow time.
> Value Stream Mapping: draw the entire commit-to-production
> flow. Identify where work waits (usually: approval queues,
> environment provisioning, manual testing).
>
> Second Way - Feedback:
> Detect and amplify feedback at every stage.
> CI: 5-minute feedback on code quality.
> Staging: same-day feedback on integration issues.
> Production: real-time feedback on business metrics.
> Without feedback loops: problems discovered months after creation.
>
> Third Way - Continuous Learning:
> Safe-to-fail experiments. Blameless post-mortems.
> Share learnings across teams (post-mortem publication).
> Game days (intentionally trigger failures to practice response).
> Chaos engineering (controlled fault injection).
>
> The Constraint Identification Model:
> Theory of Constraints (Eliyahu Goldratt) applied to DevOps:
> The system throughput = the throughput of the bottleneck.
> DevOps improvement: find the bottleneck in commit-to-production.
> If deployment is the bottleneck: automate deployment.
> If testing is the bottleneck: parallelize tests.
> If approval is the bottleneck: risk-based auto-approval.
> Improving non-bottleneck stages = no system-level improvement.
>
> The autonomy-alignment model:
> High autonomy, low alignment: chaos. Teams do their own thing.
> Low autonomy, high alignment: bureaucracy. Nothing moves.
> High autonomy, high alignment: elite performance.
> DevOps enables this via: clear standards (alignment) +
> self-service platforms (autonomy). Teams deploy independently
> within a shared, compliant framework.

**Blank Mind Recovery:**

**(1) Restate:** "DevOps = Three Ways: Flow + Feedback + Continuous Learning.
Find the bottleneck (Theory of Constraints). Autonomy + Alignment."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Three Ways + mental model |
| Staff | 9 min | Theory of Constraints + Value Stream Mapping |
| Principal | 12 min | Organizational transformation + autonomy-alignment model |

**[BEHAVIORAL]** Describe a DevOps transformation you led or contributed to.

> *Why they ask:* Tests ability to apply the theory in practice.
>
> *Strong answer:* "Our team had a 3-week commit-to-production lead time.
> I mapped the value stream: developers finished in 2 days, but
> PRs waited 3 days for reviews (high batching), then waited 2
> more days for the weekly CAB, then waited 5 days for the ops team
> to schedule a deployment window.
>
> 80% of the lead time was waiting, not working.
>
> The bottleneck was the CAB + deployment window. I worked with
> the security team to define standard changes (routine updates
> with CI pass = pre-approved, no CAB). Non-standard changes still
> required CAB. 90% of changes became standard.
>
> We moved from weekly deployments to daily. Lead time dropped
> from 3 weeks to 2 days. Change failure rate improved because
> smaller batch sizes meant smaller blast radius when failures occurred.
>
> Lesson: the bottleneck was never the developers. It was the
> approval process. DevOps is about system optimization, not
> just CI/CD tooling."
>
> *What separates good from great:* Quantified the before/after.
> Applied Theory of Constraints explicitly. Identified the bottleneck
> before proposing a solution.

| Interviewer Type | Emphasis |
|------------------|---------|
| Staff/Principal | Deployment framework + maturity model |
| VP Engineering | DevOps transformation + organizational change |
| Bar Raiser | Three Ways + constraint theory + autonomy-alignment |
