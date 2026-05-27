---
layout: default
title: "Kubernetes - L5 Architecture"
parent: "Kubernetes"
grand_parent: "SK Interview"
nav_order: 8
permalink: /kubernetes/l5-architecture/
---

# Multi-Cluster and Multi-Region Strategy

🎯 Interview Weight: very high - Multi-cluster design is a Staff+
engineering topic. Expected in senior/staff system design interviews.

---

### 🎯 Model Answer

**30 seconds:**
> Multi-cluster Kubernetes runs multiple independent K8s clusters,
> typically for: fault isolation (one cluster fails, others serve),
> geographic distribution (low-latency regional serving), regulatory
> compliance (data must stay in a specific region), or workload
> isolation (prod vs staging, or security boundaries). Each cluster
> is independent - no shared control plane. Cross-cluster service
> discovery and traffic routing require additional tooling:
> Istio multi-cluster, Submariner, or a global load balancer.

**3 minutes (Senior):**
> Multi-cluster deployment models:
>
> Model 1 - Replicated (active/active):
> Same workload deployed to N clusters across N regions.
> Global load balancer (AWS Route53 GeoDNS, Cloudflare) routes
> users to nearest region.
> Benefit: lowest latency + high availability.
> Challenge: data synchronization (database replication lag,
> cache consistency), deployment coordination (deploy to all
> regions without split-brain version mismatch).
>
> Model 2 - Federated (primary/secondary):
> One primary cluster serves traffic. Secondary clusters are
> hot standbys. On primary failure, global DNS switches to
> secondary.
> Benefit: simpler operational model.
> Challenge: failover time (DNS TTL 60s + health check 30s
> = 90 seconds of downtime), data replication lag means
> secondary may be 1-5 minutes behind.
>
> Model 3 - Segmented (environment isolation):
> Dev / staging / prod in separate clusters.
> Benefit: blast radius containment. A broken deploy in staging
> does not affect prod. Different security policies per cluster.
> Challenge: infra cost (3+ clusters), configuration drift
> between environments.
>
> Cross-cluster service discovery options:
> (a) Istio multi-cluster: shared control plane or replicated.
>     Services registered in ServiceEntry. mTLS across clusters.
>     Traffic policy (ROUND_ROBIN, FAILOVER).
> (b) Submariner: connects pod and service CIDRs across clusters
>     via IPSec/Libreswan tunnel. Services become accessible
>     across clusters by their service name.
> (c) Multi-cluster Ingress (GKE): single Ingress resource
>     that routes to pods in multiple GKE clusters. Google's
>     Andromeda load balancer handles routing.
>
> Data tier challenges:
> Global database: CockroachDB, YugabyteDB, Spanner (Google) -
> distributed ACID across regions. Latency: 50-200ms for
> strongly consistent writes across regions.
> Read replicas: regional read replicas for low-latency reads.
> Writes go to primary region (higher latency for non-primary users).

**Blank Mind Recovery:**

**(1) Restate:** "Multiple clusters = fault isolation + regional
serving. Challenges: cross-cluster service discovery and data sync."

---

### ⚖️ Comparison Table

| Model | Availability | Latency | Complexity | Cost | Use Case |
|-------|-------------|---------|-----------|------|----------|
| Single Cluster | ~99.9% | Regional | Low | Low | Startup |
| Active/Active | 99.99%+ | Global | High | High | Global app |
| Primary/Standby | 99.9%+ | Regional | Medium | Medium | DR required |
| Env Isolation | N/A | N/A | Medium | Medium | Compliance/staging |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Active/active vs primary/standby + Istio multi-cluster |
| Staff | 10 min | Data tier challenges + global load balancing |

**[TRADE-OFF] Active/active multi-region vs primary/standby -
when do you choose each?**
`[STAFF]`

*Why they ask:* Architectural judgment - tests understanding
of real cost vs availability trade-offs.

*Likely follow-up:* "How do you handle database writes in active/active?"

Active/active when:
- Global user base requiring <50ms latency in multiple continents.
- SLA > 99.99% (four nines requires multi-region).
- Traffic volume justifies infrastructure cost.
- The application is designed for eventual consistency
  (social feed, product catalog) OR uses a globally distributed
  database (Spanner, CockroachDB) for strong consistency.

Primary/standby when:
- Single geography audience (US only, EU only) - active/active
  adds cost without latency benefit.
- Database is a traditional RDBMS (PostgreSQL, MySQL) - active/active
  writes require global synchronous replication = 100-200ms
  write latency (unacceptable for OLTP).
- Simpler operational model preferred - fewer clusters = fewer
  upgrade cycles, fewer security audits, fewer runbooks.
- RTO > 5 minutes is acceptable - DNS failover + data catch-up.

The hidden cost of active/active: operational complexity.
Two regions = two deployment pipelines, two monitoring setups,
two capacity plans, and the constant vigilance of keeping
both clusters synchronized. Many companies discover their
active/active setup degrades into active/standby because
operators stop synchronizing the second cluster's configuration.
Use active/active only when the latency or availability
requirement is proven, not assumed.

*What separates good from great:* Knowing that database
consistency model (eventual vs strong) is the primary driver
of which active/active pattern is feasible.

---

---

# GitOps with Kubernetes

🎯 Interview Weight: very high - GitOps is the dominant Kubernetes
deployment model. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> GitOps is a continuous delivery model where the desired cluster
> state is stored in Git. A GitOps operator (ArgoCD, Flux)
> watches the Git repository and reconciles the cluster state
> to match. Deployments become Git commits. Benefits: auditability
> (Git blame shows who changed what), rollback is `git revert`,
> and cluster state is always inspectable. The cluster pulls
> from Git rather than CI/CD pushing to the cluster.

**3 minutes (Senior):**
> GitOps architecture:
>
> Repository structure:
> Application repo: application source code + Dockerfile.
> Config repo (separate): Kubernetes manifests or Helm values.
> Separation of concerns: app devs own the app repo. Ops
> owns the config repo. CI writes to the config repo on
> successful build (updates image tag in values.yaml).
>
> ArgoCD workflow:
> 1. Developer pushes code. CI builds image, pushes to registry.
> 2. CI (or a GitHub Action) updates the image tag in the
>    config repo via PR or direct commit.
> 3. ArgoCD detects the config repo change (poll every 3 min
>    or webhook-triggered).
> 4. ArgoCD computes the diff between desired state (Git) and
>    current cluster state.
> 5. ArgoCD applies the diff (`kubectl apply`).
> 6. ArgoCD reports sync status: Synced/OutOfSync.
>
> Rollback in GitOps:
> `git revert <commit>` in the config repo.
> ArgoCD detects the revert, applies the previous manifest.
> No `kubectl rollout undo` needed. Git history is the source
> of truth.
>
> Drift detection:
> If someone runs `kubectl apply` directly (bypassing Git),
> ArgoCD marks the app as OutOfSync. With auto-sync enabled:
> ArgoCD reverts the manual change. This enforces "Git is truth."
>
> Multi-environment strategy:
> Option A: separate branches per environment (main=prod,
> staging=staging). Promotion = merge from staging to main.
> Option B: separate directories per environment
> (`environments/prod/`, `environments/staging/`).
> Option C: Helm charts with separate values files per env.

**Blank Mind Recovery:**

**(1) Restate:** "GitOps: cluster state in Git, operator reconciles.
Deploy = git commit. Rollback = git revert."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | GitOps concept + ArgoCD workflow |
| Senior | 7 min | Config repo structure + drift detection + rollback |
| Staff | 10 min | Multi-env strategy + secrets in GitOps + RBAC for ArgoCD |

**[TRADE-OFF] What is the risk of putting Kubernetes Secrets
in the config repo, and how do you solve it?**
`[SENIOR]`

*Why they ask:* Secrets are a practical blocker for GitOps
adoption. Tests real-world experience.

*Likely follow-up:* "Walk me through Sealed Secrets or External Secrets Operator."

Git repositories are not secure storage for Secrets.
Even private repos: all contributors can read secrets, tokens
can be leaked in PR diffs, and Git history retains secrets
even after "deletion" (must `git filter-branch` or BFG to
truly remove).

Solutions:
(1) Sealed Secrets (Bitnami): `kubeseal` CLI encrypts the Secret
against the cluster's public key. The SealedSecret YAML is safe
to commit (asymmetrically encrypted). The Sealed Secrets controller
in the cluster decrypts it back to a K8s Secret. Risk: if the
cluster's private key is lost, Sealed Secrets cannot be decrypted.
Backup the controller key.

(2) External Secrets Operator (ESO): the Secret's value stays
in AWS Secrets Manager / Vault / GCP Secret Manager. The ExternalSecret
resource (safe to commit) tells ESO where to fetch the value.
ESO creates the K8s Secret at runtime. The config repo never
contains the actual secret value.

(3) Vault Agent Injection: sidecars inject secrets directly
into the pod filesystem from Vault. No K8s Secret is created
at all. The most secure option.

*What separates good from great:* Recommending ESO or Vault
over Sealed Secrets for enterprise setups (centralized secret
rotation, audit logs, TTL enforcement).

---

---

# Platform Engineering on Kubernetes

🎯 Interview Weight: high - Platform engineering is the Staff+
discipline of building K8s-based internal developer platforms.

---

### 🎯 Model Answer

**30 seconds:**
> Platform engineering builds the paved road for development teams
> on Kubernetes: golden paths (standardized templates), self-service
> infrastructure (teams provision namespaces/clusters via APIs),
> guardrails (policies, not gates), and developer experience
> (fast feedback, unified observability). The goal: developers
> deploy to production without knowing Kubernetes internals.
> Tools: Backstage (developer portal), Crossplane (infrastructure
> as Kubernetes resources), ArgoCD/Flux (GitOps), Kyverno/OPA
> (policies).

**3 minutes (Senior):**
> Platform engineering model:
>
> The cognitive load problem:
> Average microservices Kubernetes configuration: Deployment,
> Service, Ingress, HPA, PDB, ServiceAccount, RoleBinding,
> NetworkPolicy, ResourceQuota = 9+ YAML files per service.
> Most developers do not know or want to know Kubernetes.
> Platform engineering abstracts this complexity.
>
> Golden path templates:
> A "golden path" is a pre-configured, best-practice template
> for common service types (REST API, batch job, Kafka consumer).
> Developer supplies: app name, image, environment variables,
> memory limits. Platform generates: all K8s manifests,
> monitoring dashboards, alerting rules, PDBs, HPA.
> Implementation: Helm charts, CUE lang, Kustomize overlays,
> or custom controllers.
>
> Crossplane (infrastructure as K8s custom resources):
> Teams request databases, message brokers, buckets using K8s
> custom resources (e.g., `PostgreSQLInstance` CR).
> Crossplane provider reconciles the CR by calling the cloud
> API (AWS RDS, GCP CloudSQL). The database is provisioned
> without Terraform or cloud console access.
>
> Policy as guardrails (not gates):
> Kyverno policies run as admission webhooks. Examples:
> - Require all pods to have resource limits.
> - Require all images from approved registries.
> - Block `latest` image tag.
> - Require readiness probes.
> Mode: `warn` in dev (logs violation, admits anyway),
> `enforce` in prod (rejects violating resources).
>
> Developer portal (Backstage):
> Centralized catalog of all services, their owners,
> documentation, runbooks, and deployment status.
> Integrates with K8s to show pod health, recent deployments,
> and SLO status. Reduces "what owns this service?" questions.

**Blank Mind Recovery:**

**(1) Restate:** "Platform engineering = abstractions over K8s
so developers deploy without knowing K8s. Golden paths + policies."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Golden path concept + Kyverno policies |
| Staff | 10 min | Crossplane + Backstage + cognitive load reduction |

---

---

# Kubernetes Cost Optimization

🎯 Interview Weight: medium-high - Cost optimization is expected
at staff level in cloud-native organizations.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes cost optimization: right-size pod requests (not
> too high = over-provisioned nodes, not too low = OOMKilled),
> use Spot/Preemptible nodes for batch workloads, enable Cluster
> Autoscaler to scale nodes down when idle, use Vertical Pod
> Autoscaler (VPA) for right-sizing, and identify underutilized
> workloads with Kubecost or cloud-native cost tools.

**3 minutes (Senior):**
> Kubernetes cost drivers:
>
> Overprovisioned pod requests (most common):
> If requests.memory=1Gi but actual usage is 200Mi, the node
> considers 1Gi allocated (unavailable for other pods).
> 10 such pods = 10Gi of memory reserved but only 2Gi used.
> Result: the cluster needs more nodes than necessary.
>
> Recommendations: use Vertical Pod Autoscaler (VPA) in
> `Recommendation` mode. VPA observes actual usage over 7 days
> and recommends requests/limits. Review and apply periodically.
> Do NOT enable VPA `Auto` mode for production - it evicts pods
> to resize them, causing disruptions.
>
> Node utilization:
> Target: 70-80% node CPU and memory utilization.
> Below 50%: too many nodes, wasteful. Above 90%: risk of
> OOMKill during spikes.
> Cluster Autoscaler: removes underutilized nodes automatically.
> Minimum time before scale-down: `--scale-down-delay-after-add=10m`.
>
> Spot / Preemptible nodes:
> AWS Spot Instances: 60-80% cheaper than On-Demand.
> Risk: nodes can be terminated with 2-minute warning.
> Safe for: batch jobs, development, stateless services with
> multiple replicas (losing one replica is acceptable).
> Unsafe for: stateful workloads (databases), services with
> single replica.
> K8s handles Spot termination: Spot termination handler
> DaemonSet detects 2-minute warning, cordons the node,
> drains pods gracefully.
>
> Namespace resource quotas:
> Prevent individual teams from over-consuming shared cluster
> resources. Set CPU/memory quotas per namespace.
> Forces teams to right-size their deployments.

**Blank Mind Recovery:**

**(1) Restate:** "K8s cost: right-size requests, use VPA for
recommendations, Spot nodes for batch, autoscaler to remove idle nodes."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Overprovisioning + VPA recommendations |
| Staff | 8 min | Spot nodes + Cluster Autoscaler + Kubecost |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | GitOps workflow + multi-cluster decision |
| Platform/SRE | Cost optimization + right-sizing |
| Bar Raiser | Platform engineering ROI + staff trade-offs |
