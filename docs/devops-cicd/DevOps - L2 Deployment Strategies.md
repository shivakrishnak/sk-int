---
layout: default
title: "DevOps - L2 Deployment Strategies"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 4
permalink: /devops-cicd/l2-deployment-strategies/
---

# Blue-Green Deployment

🎯 Interview Weight: very high - Blue-green deployment is the
foundational zero-downtime deployment pattern.

---

### 🎯 Model Answer

**30 seconds:**
> Blue-green deployment: two identical environments (blue =
> current production, green = new version). Deploy new version
> to green (offline). Test green. Switch traffic from blue to
> green (DNS update or load balancer switch). Blue becomes the
> standby. Rollback: switch traffic back to blue (seconds).
> Zero downtime. Full environment available for post-deployment
> verification before cutover.

**3 minutes (Senior):**
> Blue-green mechanics and trade-offs:
>
> Traffic switch options:
> DNS: update DNS record to point to green. Slowest (DNS TTL).
> Load balancer: change backend target group from blue to green.
> Fast (<1 second with ELB target group swap).
> Service mesh (Istio): change VirtualService traffic weight.
> Precise (100/0 switch) or gradual (weighted shift).
>
> Database migrations with blue-green:
> The hard part. Both blue and green must run simultaneously
> against the same DB during the switch window.
> Rule: DB migration must be backward compatible (blue reads
> the migrated schema correctly).
> Pattern: expand-contract.
> V1 uses column `name`. V2 uses columns `first_name` + `last_name`.
> Step 1 (deploy green + run migration): add `first_name` and
> `last_name` columns. Copy data. Green uses new columns. Blue
> still uses `name` (still there).
> Step 2 (after blue is decommissioned): remove old `name` column.
>
> Cost and infrastructure:
> Requires 2x infrastructure (blue + green must both be provisioned).
> In cloud: on-demand instances reduce cost (spin down blue after
> the switch, keep warm for 1 week for rollback).
> Kubernetes: two deployments (blue-deployment, green-deployment),
> one service pointing to the active deployment's pods.
>
> Post-switch verification:
> After switching to green: monitor error rates, latency,
> business metrics for 15-30 minutes before decommissioning blue.
> Automated verification: smoke tests against production.

**Blank Mind Recovery:**

**(1) Restate:** "Blue-green: two environments, switch traffic to the new one.
Rollback = switch back. DB must support both versions simultaneously."

---

### ⚖️ Comparison Table

| Strategy | Downtime | Rollback | Cost | Use Case |
|----------|---------|---------|------|---------|
| Blue-green | Zero | Instant | 2x infra | High-traffic services |
| Rolling update | Zero | Slow | 1x infra | Standard services |
| Canary | Zero | Fast | 1.1x infra | High-risk changes |
| Recreate | Brief | Redeploy | 1x infra | Dev/staging only |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Blue-green concept + traffic switch |
| Senior | 8 min | Expand-contract DB migration + Kubernetes implementation |
| Staff | 12 min | Cost optimization + automated verification |

---

---

# Canary and Progressive Rollout

🎯 Interview Weight: very high - Canary deployments are the
production-safe way to validate changes under real traffic.

---

### 🎯 Model Answer

**30 seconds:**
> Canary deployment: gradually shift traffic to the new version,
> starting with a small percentage (1-5%). Monitor error rates,
> latency, and business metrics. If metrics are healthy: increase
> traffic percentage. If metrics degrade: rollback (redirect
> 100% to old version). Progressive rollout: structured stages
> (5% -> 25% -> 50% -> 100%). Gives early warning of production
> issues before full rollout.

**3 minutes (Senior):**
> Canary deployment implementation:
>
> Kubernetes + Istio:
> `DestinationRule` defines subsets: `v1` (old) and `v2` (canary).
> `VirtualService`: traffic weight `v1: 95, v2: 5`.
> Monitor: Prometheus -> Grafana dashboard (error rate per version).
> If canary is healthy after 10 minutes: update weights to 75/25.
> Automated promotion (Argo Rollouts): progressive delivery
> with automated analysis gates.
>
> Argo Rollouts:
> `Rollout` resource replaces `Deployment`.
> Strategy: canary with analysis.
> `steps: - setWeight: 5` (5% traffic)
> `- analysis: ...` (run analysis template)
> `- setWeight: 25` (25% traffic)
> `- analysis: ...`
> `- setWeight: 100` (full rollout)
> Analysis template queries Prometheus: if error rate > 1%,
> pause rollout + alert. Engineer manually promotes or aborts.
>
> Canary metrics to monitor:
> HTTP error rate (4xx, 5xx) per version.
> Request latency (P99) per version.
> Business metrics: checkout conversion rate, payment success rate.
> If new version converts 10% fewer checkouts: rollback even
> if technical metrics are healthy.
>
> Canary limitations:
> Not all traffic is valid canary traffic. Heavy users vs
> new users may behave differently. A canary with 5% of traffic
> may see 5% of light users, not a representative sample.
> Header-based routing: route specific users (internal, beta
> users) to canary for more controlled testing.

**Blank Mind Recovery:**

**(1) Restate:** "Canary: gradually shift traffic, monitor metrics,
promote or rollback. Argo Rollouts automates the progression."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Canary concept + traffic percentages |
| Senior | 8 min | Argo Rollouts + analysis templates + business metrics |
| Staff | 12 min | Header-based routing + automated progressive delivery |

---

---

# Rolling Updates and Rollbacks

🎯 Interview Weight: high - Rolling updates are the default
Kubernetes deployment strategy.

---

### 🎯 Model Answer

**30 seconds:**
> Rolling update: gradually replaces old pods with new pods.
> Old pods are terminated only after new pods are healthy.
> No downtime (some pods run the old version, some the new).
> Kubernetes rolling update: `maxSurge=25%` (extra pods), `maxUnavailable=25%`
> (pods that can be unavailable). Rollback: `kubectl rollout undo
> deployment/my-service`. Reverts to the previous ReplicaSet.

**3 minutes (Senior):**
> Rolling update mechanics:
>
> Kubernetes rolling update algorithm:
> Desired: 4 replicas, maxSurge=1, maxUnavailable=1.
> State: 4 old pods (v1).
> Step 1: create 1 new pod (v2). Total: 5 pods (surge).
> Step 2: when v2 pod is Ready: terminate 1 old pod.
> Step 3: create next v2 pod. When Ready: terminate next old.
> Step 4: repeat until all 4 pods are v2.
> Total time: depends on pod startup time (10-60 seconds typically).
>
> Rollback:
> `kubectl rollout undo deployment/my-service`: reverts to previous.
> `kubectl rollout undo deployment/my-service --to-revision=3`: specific version.
> `kubectl rollout history deployment/my-service`: see history.
> Keep `revisionHistoryLimit: 5` (default 10) to retain 5 previous
> ReplicaSets for rollback.
>
> Rolling update pitfalls:
> Database compatibility: old and new pod versions run simultaneously.
> Same requirement as blue-green: DB migration must be backward compatible.
> minReadySeconds: new pod must be healthy for N seconds before
> the next old pod is terminated. Prevents bad pods from
> looking healthy briefly then failing.
>
> Health check requirements:
> Readiness probe: rolling update only proceeds when new pod
> is Ready. Without readiness probes: Kubernetes assumes pods
> are ready immediately on start - may send traffic to pods
> that are still initializing.

**Blank Mind Recovery:**

**(1) Restate:** "Rolling update: gradually replace old with new pods.
Rollback = undo. DB migrations must be backward compatible during the transition."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Rolling update algorithm + rollback command |
| Senior | 7 min | maxSurge/maxUnavailable + DB compatibility + minReadySeconds |

---

---

# Feature Flags and Dark Launches

🎯 Interview Weight: high - Feature flags enable progressive
feature rollout and decouple deployment from release.

---

### 🎯 Model Answer

**30 seconds:**
> Feature flags: runtime on/off switches for code features.
> Decouples deployment from release: code is deployed to production
> but the feature is disabled until explicitly enabled. Use cases:
> dark launch (test feature with 0% users in production), rollout
> (gradually enable for 1%, 10%, 100% of users), kill switch
> (instantly disable a buggy feature without a deployment), A/B
> testing (different behavior for test vs control groups).

**3 minutes (Senior):**
> Feature flag patterns and implementation:
>
> Types of feature flags:
> Release flag: temporarily enables a new feature for rollout.
> Ops flag: performance or behavior tuning (cache TTL values).
> Permission flag: enable for specific users or tenants.
> Experiment flag: A/B test variation (statistical analysis).
>
> Implementation options:
> LaunchDarkly: SaaS, real-time flag updates (SSE/polling),
> rich targeting rules (user ID, percentage, attributes),
> analytics, audit trail. Enterprise pricing.
> Unleash: self-hosted OSS, same features as LaunchDarkly.
> Spring Cloud Config + custom flags: simple but no real-time
> update (requires restart or config refresh).
> Feature flag in DB: flexible but requires a dashboard.
>
> Dark launch pattern:
> Deploy new payment processing code with flag `NEW_PAYMENT_OFF`.
> In production: 100% of requests go through old code.
> Dual write: new code is called in the background (shadow mode)
> but its result is not returned to the user.
> Compare old vs new results in logs/metrics.
> When results match: flip flag to 100% traffic.
>
> Technical debt of flags:
> Flag lifecycle: create -> rollout -> 100% -> remove flag code.
> Flags older than 3 months should be removed.
> Accumulated flags: tech debt, dead code paths, confusion.
> Track active flags in a dashboard. Set an expiry date.

**Blank Mind Recovery:**

**(1) Restate:** "Feature flags: decouple deployment from release.
Dark launch = test in prod with 0% impact. Kill switch = instant disable."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Feature flag types + rollout pattern |
| Senior | 7 min | Dark launch + LaunchDarkly vs Unleash + flag cleanup |

---

---

# Secret Management and Vault

🎯 Interview Weight: very high - Secrets management is a
critical security requirement. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Secret management: API keys, DB passwords, certificates must
> never be stored in Git or Docker images. Solutions: HashiCorp
> Vault (most feature-rich, self-hosted), AWS Secrets Manager
> (AWS-native), Kubernetes Secrets (encrypted at rest + RBAC),
> External Secrets Operator (syncs external secrets to K8s).
> Dynamic secrets (Vault): short-lived DB credentials generated
> per-service, automatically rotated. Eliminates static passwords.

**3 minutes (Senior):**
> Vault architecture and patterns:
>
> Static secrets:
> Store secret in Vault: `vault kv put secret/db password=secret`.
> Application reads on startup: `vault kv get secret/db`.
> Problem: static secrets can be extracted from memory, logs,
> or from Vault itself. Rotation requires restart.
>
> Dynamic secrets (Vault database engine):
> `vault secrets enable database`
> Configure Vault with DB credentials (admin).
> Application requests credentials: Vault generates a new
> DB user with a 1-hour TTL.
> TTL expires: DB user is automatically revoked.
> Benefits: no shared credentials, automatic rotation,
> each pod has unique credentials (compromise = one pod, not all).
>
> Vault Agent Kubernetes integration:
> Vault Agent sidecar: injects secrets into pod file system.
> Annotation: `vault.hashicorp.com/agent-inject: "true"`.
> `vault.hashicorp.com/agent-inject-secret-db: "secret/db"`.
> Agent writes secret to `/vault/secrets/db`.
> App reads the file at startup. Dynamic secrets: agent
> renews the lease and rewrites the file before expiry.
>
> Secret rotation:
> Dynamic secrets: automatic (TTL-based).
> Static secrets: rotation script in CI/CD (update Vault +
> trigger rolling restart of all pods that use the secret).
> Never accept "we'll rotate it manually when we get around to it."

**Blank Mind Recovery:**

**(1) Restate:** "Secrets: never in Git or Docker. Vault for dynamic
secrets = short-lived credentials per service. ESO for K8s sync."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Secret management options + static vs Vault |
| Senior | 8 min | Dynamic secrets + Vault Agent + rotation |
| Staff | 12 min | Multi-environment secret strategy + audit logging |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Blue-green + canary mechanics |
| Platform/Security | Secret management + Vault dynamic secrets |
| Bar Raiser | Feature flags + dark launch + progressive delivery |
