---
layout: default
title: "DevOps - L0 Orientation"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 1
permalink: /devops-cicd/l0-orientation/
---

# DevOps Culture and Principles

🎯 Interview Weight: high - DevOps culture is the foundation
for all CI/CD practices. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> DevOps is a set of practices combining software development (Dev) and
> IT operations (Ops) to shorten the development lifecycle and deliver
> high-quality software continuously. Core principles: CALMS - Culture
> (collaboration over silos), Automation (everything automated),
> Lean (eliminate waste), Measurement (metrics-driven), Sharing
> (knowledge shared across teams). DORA metrics measure DevOps
> effectiveness: deployment frequency, lead time, MTTR, change
> failure rate.

**3 minutes (Senior):**
> DevOps principles in practice:
>
> CALMS framework:
> Culture: Dev and Ops share responsibility for reliability.
> No "throw over the wall" deployments. On-call shared between
> Dev and Ops. Post-mortems are blameless.
> Automation: manual processes are anti-patterns. If done twice,
> automate the third time. Tests, deployments, provisioning,
> security scans - all automated.
> Lean: minimize work in progress. Small, frequent deployments
> are safer than large, infrequent ones. Batch size reduction
> = faster feedback.
> Measurement: DORA metrics as leading indicators.
> Sharing: runbooks, postmortem results, architecture decisions
> are open to all teams.
>
> DORA four key metrics:
> Deployment frequency: how often code is deployed to production.
> Elite: multiple times per day. Poor: weekly or less.
> Lead time for changes: time from code commit to production.
> Elite: < 1 hour. Poor: 1-6 months.
> Mean Time to Recovery (MTTR): time to restore service after
> an incident. Elite: < 1 hour. Poor: 1 week.
> Change failure rate: percentage of deployments causing incidents.
> Elite: 0-15%. Poor: 46-60%.
>
> DevOps anti-patterns:
> "DevOps team": creating a separate team that does deployment
> for developers is just a renamed Ops team. DevOps is a culture,
> not a job title.
> Automation without culture: automated pipelines with manual
> approval gates at every step - the same slow process, now
> with YAML.
> Toolchain focus: teams spending more time on CI/CD tooling
> than on delivering business value.

**Blank Mind Recovery:**

**(1) Restate:** "DevOps: Dev + Ops collaborate. CALMS. DORA metrics
measure effectiveness. Small frequent deployments = lower risk."

**(2) First principles:** "Long delivery cycles = late feedback = costly
bug fixes. Short cycles = fast feedback = cheaper fixes."

**(3) Bridge:** "Like a restaurant that gets feedback from customers
every 5 minutes (DevOps) vs one that reads Yelp reviews monthly (waterfall)."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | CALMS + DORA metrics meaning |
| Senior | 7 min | DORA benchmarks + DevOps anti-patterns |

---

---

# CI/CD Pipeline Overview

🎯 Interview Weight: very high - CI/CD pipeline is the
operational backbone of software delivery.

---

### 🎯 Model Answer

**30 seconds:**
> CI (Continuous Integration): developers merge code frequently,
> triggering automated builds, tests, and quality checks. Fast
> feedback on broken changes. CD (Continuous Delivery): every
> passing build is deployable to production at any time.
> CD (Continuous Deployment): every passing build IS deployed
> automatically to production. Typical pipeline stages: commit ->
> build -> unit test -> integration test -> security scan ->
> package -> deploy to staging -> smoke test -> deploy to production.

**3 minutes (Senior):**
> CI/CD pipeline design:
>
> CI stage (triggered on every commit):
> 1. Checkout code.
> 2. Compile / build.
> 3. Unit tests + code coverage check.
> 4. Static analysis (SonarQube, Checkstyle, SpotBugs).
> 5. Dependency vulnerability scan (Snyk, OWASP Dependency-Check).
> 6. Build Docker image.
> 7. Push to container registry (on main branch).
>
> CD staging stage:
> 8. Deploy to staging environment.
> 9. Integration tests (Testcontainers, external service stubs).
> 10. API contract tests (consumer-driven contracts).
> 11. Performance baseline test.
>
> CD production stage:
> 12. Canary deploy (5% traffic).
> 13. Monitor error rate, latency (1-10 minutes).
> 14. Promote to 100% or rollback.
>
> Fast feedback principle:
> Tests that run in 10 minutes are not fast enough.
> Parallelize test suites. Target: CI passes in < 5 minutes.
> Fail fast: cheapest checks first (compile before integration
> tests, unit tests before E2E).
>
> Pipeline as code:
> All pipeline logic in version control (`Jenkinsfile`,
> `.github/workflows/ci.yml`, `.gitlab-ci.yml`).
> Benefits: version history, peer review of pipeline changes,
> pipeline is code like the application.

**Blank Mind Recovery:**

**(1) Restate:** "CI: integrate + test on every commit.
CD: automated deployment. Pipeline stages: build -> test -> scan -> deploy."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | CI vs CD + pipeline stages |
| Senior | 7 min | Fast feedback + pipeline as code + CD safety |

---

---

# Version Control Strategy

🎯 Interview Weight: medium - Git strategy impacts CI/CD
velocity and collaboration.

---

### 🎯 Model Answer

**30 seconds:**
> Git branching strategies: Trunk-Based Development (small,
> short-lived feature branches merged to trunk/main frequently,
> recommended for DevOps teams), Gitflow (long-lived develop +
> release branches, slower feedback, suitable for scheduled releases),
> GitHub Flow (feature branches + main only, PR-based, simple).
> DORA research: trunk-based development correlates with
> higher deployment frequency and lower MTTR.

**3 minutes (Senior):**
> Branching strategy comparison:
>
> Trunk-Based Development (TBD):
> All developers commit to `main` (or trunk) at least daily.
> Feature flags hide incomplete features in production.
> No long-lived branches -> no merge conflicts at release time.
> Short-lived feature branches (< 2 days) are acceptable.
> Enables CI: every commit is integrated and tested.
> Used by Google, Facebook, Netflix.
>
> Gitflow:
> `main` (production-ready), `develop` (integration),
> `feature/*`, `release/*`, `hotfix/*` branches.
> Good for: multiple software versions in the field
> (e.g., v2.x and v3.x supported simultaneously).
> Problematic for web services: release branches create merge
> conflicts and slow CI cycles.
> Long-lived branches: merging feature/big-feature into develop
> after 2 weeks causes painful conflicts.
>
> GitHub Flow:
> Only `main` and short-lived feature branches.
> PR -> CI passes -> code review -> merge to main -> deploy.
> Simpler than Gitflow. Faster than TBD (PR review step).
> Good for: teams with strong PR review culture, moderate deployment
> frequency (once per day to several times per week).
>
> Monorepo vs polyrepo:
> Monorepo: all services in one repo. Atomic changes across
> services. Consistent tooling. Requires strong CI (only build
> what changed). Google: Blaze/Bazel.
> Polyrepo: each service has its own repo. Easier permissions.
> Cross-service changes require coordination.

**Blank Mind Recovery:**

**(1) Restate:** "Trunk-based: daily commits to main + feature flags.
Gitflow: for multiple versions. GitHub Flow: PR-based, simple."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Trunk-based vs Gitflow |
| Senior | 7 min | Feature flags + monorepo/polyrepo trade-offs |

---

---

# Deployment Landscape and Environments

🎯 Interview Weight: medium - Environment topology is the
foundation of deployment pipeline design.

---

### 🎯 Model Answer

**30 seconds:**
> Standard environment topology: Development (local dev on
> developer machine), CI (ephemeral, created per build),
> Staging/Pre-production (mirrors production, integration testing),
> Production (live user traffic). Some add: UAT (user acceptance
> testing), Canary/Preview (5% production traffic), Performance
> (load testing). Configuration differences between environments
> must be externalized (12-factor app) - never baked into the
> artifact.

**3 minutes (Senior):**
> Environment design principles:
>
> Production parity (12-factor app principle):
> Staging should mirror production: same OS, same DB version,
> same network topology. The closer staging is to production,
> the fewer "works on staging but fails in prod" bugs.
> Anti-pattern: staging with 1/10 of production resources
> misses memory-related bugs, GC behavior, and connection pool
> exhaustion issues.
>
> Ephemeral environments:
> Every PR creates a preview environment (Review Apps in GitLab,
> Environments in Kubernetes). Automatically destroyed when PR
> is closed. Benefits: reviewers can click through changes
> before merging.
> Cost: requires infrastructure automation (Terraform, Helm).
>
> Environment promotion flow:
> Artifact (Docker image) is built ONCE in CI.
> Same image promoted from CI -> Staging -> Production.
> Configuration injected at deploy time (not baked in).
> Anti-pattern: different Docker images for different environments.
> Different images = untested configuration differences.
>
> Configuration management:
> `environment.yaml` per environment (CI, staging, prod).
> Injected via: Kubernetes ConfigMaps, environment variables,
> Vault secrets, parameter store (AWS SSM).
> Sensitive config (DB passwords, API keys) via Vault or
> AWS Secrets Manager. Never in git.

**Blank Mind Recovery:**

**(1) Restate:** "Environments: dev, CI, staging, prod. Same artifact
through all stages. Config injected, not baked in."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Environment topology + promotion flow |
| Senior | 6 min | Production parity + ephemeral environments |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | DORA metrics + CI/CD pipeline stages |
| System Design | Environment topology + promotion strategy |
| Bar Raiser | Trunk-based development + feature flags |
