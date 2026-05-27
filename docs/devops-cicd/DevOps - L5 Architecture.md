---
layout: default
title: "DevOps - L5 Architecture"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 7
permalink: /devops-cicd/l5-architecture/
---

# Platform Engineering

🎯 Interview Weight: very high - Platform engineering is the
Staff/Principal-level evolution of DevOps.

---

### 🎯 Model Answer

**30 seconds:**
> Platform engineering: building an Internal Developer Platform
> (IDP) that encapsulates infrastructure complexity, enabling
> application developers to self-serve. The platform team (SRE
> evolution) provides: golden paths (opinionated, tested
> templates), self-service portals (Backstage), CI/CD templates
> (reusable pipelines), and observability stacks. Developers
> do not manage Kubernetes YAML, Terraform, or Jenkins configurations
> directly. They use the platform's abstractions.

**3 minutes (Staff):**
> Platform engineering pillars:
>
> Golden paths:
> The paved road: a set of templates, tools, and practices
> that are pre-approved, pre-integrated, pre-secured.
> New microservice: run `platform create service payment-service`.
> Output: Git repo with Dockerfile, GitHub Actions CI, Helm chart,
> Kubernetes RBAC, monitoring dashboards, alerting rules.
> All production-ready defaults. Developer writes business logic only.
>
> Backstage (CNCF):
> Internal developer portal. Software catalog (all services,
> their owners, runbooks, dashboards, API specs).
> Self-service: create a new service via Backstage Software Template.
> Backstage scaffolds the repo + CI + infrastructure in one workflow.
> Plugins: GitHub, Kubernetes, PagerDuty, Datadog, Vault.
>
> Platform team as a product team:
> Platform team = the internal product team building for developers.
> NPS (Net Promoter Score) for the platform: how satisfied are
> developers with the internal tools?
> Measure: time to first production deployment for a new service.
> Before platform: 2 weeks (manual setup, Jenkins, Terraform).
> After platform: 2 hours (Backstage template + golden path).
>
> Cognitive load reduction:
> John Cutler's "developer tax": every non-product task (infra,
> security, observability setup) is a cognitive tax on developers.
> Platform reduces this tax by moving complexity into the platform.
> Teams can deploy independently without platform team bottleneck.
>
> Platform vs DevOps:
> DevOps: "you build it, you run it." But this led to every team
> reinventing infrastructure.
> Platform engineering: "you use a shared platform, which builds
> and runs common infrastructure for you." Teams still deploy and
> operate their services, but on top of a standard foundation.

**Blank Mind Recovery:**

**(1) Restate:** "Platform engineering: Internal Developer Platform, golden paths,
Backstage self-service. Reduces cognitive load. Teams deploy via platform abstractions."

---

### ⚖️ Comparison Table

| Approach | Setup Time | Cognitive Load | Standardization | Flexibility |
|----------|-----------|---------------|-----------------|-------------|
| DevOps (each team) | High | High | Low | High |
| Platform Engineering | Low (for teams) | Low | High | Medium |
| Traditional Ops | Very high | High | High | Low |
| Serverless PaaS | Very low | Very low | Very high | Low |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Platform engineering concept + Backstage |
| Staff | 10 min | Golden paths + cognitive load + platform as product |
| Principal | 15 min | Platform ROI + organizational model + CNCF ecosystem |

---

---

# CI/CD Architecture at Scale

🎯 Interview Weight: very high - CI/CD at scale is a core
Staff/Principal engineering concern.

---

### 🎯 Model Answer

**30 seconds:**
> CI/CD at scale: when you have 200 microservices, each with
> its own pipeline, you need: monorepo build systems with
> affected-change detection (Nx, Turborepo, Gradle composite
> builds), shared CI pipeline templates (reusable GitHub Actions
> workflows, Jenkins shared libraries), distributed artifact
> caching (Gradle Remote Build Cache, Bazel), multi-cluster
> deployment orchestration (ArgoCD ApplicationSet), and
> self-hosted runners that match production CPU/memory profiles.

**3 minutes (Staff):**
> Scale patterns:
>
> Monorepo at scale:
> Problem: 200 services, change to one -> CI runs all 200 pipelines.
> Solution: change detection.
> Nx (Node.js/TypeScript monorepo): `nx affected --target=test`
> runs tests only for services that have changed code or whose
> dependencies have changed (transitive graph analysis).
> Gradle: `gradle :payment-service:test` runs only for changed module.
> Bazel: hermetic builds + remote cache. Build only what changed.
>
> Self-hosted runners:
> GitHub Actions: GitHub-hosted runners are limited (2 CPU, 7GB RAM).
> Self-hosted: launch EC2 instances as runners on demand.
> Auto-scaling: GitHub Actions Runner Controller (ARC)
> on Kubernetes. Scale runners from 0 to N based on queue depth.
> Right-sized: Java compilation needs fast CPU (c5.4xlarge).
> Integration tests need memory (r5.2xlarge).
>
> Pipeline templating:
> GitHub: reusable workflows (`on: workflow_call`).
> 200 repos each import the same CI workflow from a central repo.
> Update the central workflow: all 200 repos get the update.
> Prevents drift in CI standards.
>
> Deployment orchestration (ArgoCD ApplicationSet):
> 200 services x 3 environments = 600 ArgoCD Applications.
> ApplicationSet: one template generates all applications.
> `{{ .service }}` + `{{ .environment }}` = each application.
> Adding a new service: add one entry to the ApplicationSet config.
>
> Observability at scale:
> Jaeger/Tempo distributed tracing: trace a user request
> across 15 microservices.
> Exemplars: link Prometheus metric spike to a specific trace.
> Debug latency: P99 latency spike -> trace exemplar -> see
> which service is slow (payment-service DB query: 2.3 seconds).

**Blank Mind Recovery:**

**(1) Restate:** "CI/CD at scale: affected builds, reusable pipeline templates,
auto-scaling runners, ArgoCD ApplicationSet for 200 services."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Scale challenges + monorepo affected builds |
| Staff | 10 min | Self-hosted runners + templating + ApplicationSet |
| Principal | 15 min | Bazel + remote build cache + platform ROI |

---

---

# Release Strategy and Governance

🎯 Interview Weight: high - Release governance is a Staff-level
skill for regulated or high-risk environments.

---

### 🎯 Model Answer

**30 seconds:**
> Release strategy at the organizational level: decides who can
> deploy what, when, and with what approvals. Governance:
> change management policies (CAB for high-risk changes),
> deployment windows, risk categories (standard/non-standard),
> and audit trails. Elite performers (DORA research): deploy
> on demand, low failure rate, fast MTTR. Governance should
> enable safe deployment frequency, not block it. Over-governance
> is an anti-pattern (CAB for every CSS change = worse outcomes).

**3 minutes (Staff):**
> Release governance patterns:
>
> Risk-based deployment policies:
> Standard change: pre-approved template. Auto-approved if CI passes.
> No CAB required. Example: routine service update with no schema change.
> Non-standard change: requires human review. Example: database schema change,
> new external integration, security configuration change.
> Emergency change: fast-track process. CISO/CTO approval. Post-incident
> review required.
>
> Deployment freeze periods:
> Seasonal blackouts: no deployments in the 2 weeks before Black Friday.
> Rationale: reduce risk during peak traffic.
> Process: planned releases delivered in the week before the freeze.
> Emergency fixes: emergency change process during freeze.
>
> DORA four keys for governance decisions:
> Deployment frequency (how often): low = over-governed or tech debt.
> Lead time for changes: long = slow approvals or complex pipelines.
> Change failure rate: high = insufficient testing or bad deployment practices.
> MTTR: long = poor observability, missing runbooks, slow incident response.
> Governance should IMPROVE these metrics, not worsen them.
>
> Separation of duties (regulated industries):
> HIPAA/PCI-DSS: engineer who writes code cannot be the same
> person who approves the production deployment.
> Automated: CI validates that PR was approved by a different person
> than the committer. GitOps: production changes require a PR
> reviewed by a different team member.
>
> Release train:
> Fixed release cadence (e.g., every 2 weeks).
> Features ready by Tuesday get included. Features not ready
> wait for the next train. Predictable for stakeholders.

**Blank Mind Recovery:**

**(1) Restate:** "Release governance: risk-based policies (standard vs non-standard),
deployment windows, DORA metrics to evaluate governance effectiveness."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Change management policies + DORA metrics |
| Staff | 10 min | Risk-based governance + separation of duties |
| Principal | 15 min | Governance as enabler + organizational design |

| Interviewer Type | Emphasis |
|------------------|---------|
| Staff/Principal Panel | Platform engineering + scale architecture |
| VP Engineering | Release governance + DORA metrics + org design |
| Bar Raiser | Platform ROI + governance effectiveness |
