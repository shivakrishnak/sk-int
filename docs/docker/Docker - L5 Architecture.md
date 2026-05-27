---
layout: default
title: "Docker - L5 Architecture"
parent: "Docker and Containers"
nav_order: 7
permalink: /docker/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Container Platform Architecture Strategy](#container-platform-architecture-strategy) | critical |
| 2 | [Container Migration Strategy](#container-migration-strategy) | high |
| 3 | [Container Image Supply Chain Security](#container-image-supply-chain-security) | high |

---

# Container Platform Architecture Strategy

**Interview Weight:** critical - Staff-level question. Tests whether
you can design the container platform (not just use it), including
multi-tenancy, developer experience, and operational governance.

---

### 🎯 Model Answer

**30 seconds:**

> A container platform strategy defines the runtime environment (Kubernetes
> version, CNI, CSI), the developer contract (how teams build, test, push,
> and deploy containers), the operational model (who owns the platform vs
> who uses it), and the governance layer (security policies, resource quotas,
> image supply chain). Platform engineering teams own the platform; product
> engineering teams use it. The contract between them is defined by a set
> of golden path tools and guardrails.

**3 minutes (Senior):**

> Container platform architecture has four dimensions: runtime, developer
> experience, operational governance, and security.
>
> Runtime: Kubernetes is the de facto choice. The decision space is managed
> (EKS, GKE, AKS - let the cloud provider manage the control plane) vs
> self-managed (direct kubelet + etcd management). For most organizations,
> managed Kubernetes reduces operational burden at a cost of less control.
> The CNI (Calico, Cilium) and CSI (EBS, Portworx) choices drive network
> policy and storage capabilities.
>
> Developer experience: the "golden path" is a pre-built, opinionated path
> that makes the right thing easy. For containers: a CI template that builds,
> scans, signs, and pushes an OCI image; a Helm chart or Kustomize base
> that includes all required security contexts; and a deploy command that
> promotes through environments. Teams that deviate from the golden path
> operate without support.
>
> Governance: every production workload goes through the supply chain
> (build -> scan -> sign -> deploy with signature verification). Resource
> quotas per namespace prevent noisy neighbors. NetworkPolicy denies traffic
> by default. Admission controllers enforce security policies at deploy time.
>
> The organizational model: Platform Engineering (SRE) owns the Kubernetes
> cluster, admission policies, and golden path tooling. Product teams own
> their workloads, Dockerfiles, and Helm charts. The platform team's goal
> is to make security and reliability the path of least resistance.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container platform architecture
strategy - the big-picture design of how an organization runs containers."

**(2) First principles:** "A platform is a product. Its customers are
developers. It succeeds when developers can deploy containers without
understanding every security and operational detail underneath."

**(3) Bridge:** "It is like designing a building's infrastructure (plumbing,
electrical, HVAC). The building occupants use power outlets and faucets -
they do not manage the electrical panel. The platform provides the outlets;
developers plug in their applications."

---

### 📘 Concept Explanation

**What it is:**
Container platform architecture strategy is the design of the organizational,
technical, and governance systems that enable an organization to run
containerized workloads reliably, securely, and efficiently at scale.

**The problem it solves:**
Without a platform strategy, each team makes independent decisions about
container configuration, security, and deployment. This leads to inconsistent
security postures, operational inefficiency, and repeated firefighting.

**How it works:**

```
Platform Architecture Layers:

  Developer Contract (Golden Path):
    - CI template: build, scan, sign, push
    - Deployment template: Helm chart or Kustomize
    - Environment promotion: dev -> staging -> prod

  Runtime Layer:
    - Kubernetes (managed: EKS/GKE/AKS)
    - CNI (Cilium preferred: eBPF-based NetworkPolicy)
    - CSI (cloud-native: EBS, GCS, Azure Disk)
    - Service mesh (Istio/Linkerd for mTLS, observability)

  Governance Layer:
    - Admission controllers: Kyverno or Gatekeeper
    - Pod Security Admission: restricted profile
    - Resource quotas per namespace
    - NetworkPolicy: default-deny with allowlist

  Supply Chain:
    - Image signing: Cosign + KMS
    - SBOM: Syft (CycloneDX)
    - Signature verification: admission controller
    - CVE scanning: Trivy in CI + registry continuous
```

**The key insight:**
Platform strategy succeeds when the secure path is also the easy path.
If security controls are burdensome, developers find workarounds. If the
golden path includes all required controls by default, developers get
security without effort.

**When to use Cilium over Calico:**
Cilium uses eBPF for network policies - better performance, better
observability (Hubble), and L7 policies (HTTP path-level policies).
Calico is simpler and more widely supported by legacy Kubernetes versions.

**Alternatives:**
- Nomad: simpler alternative to Kubernetes for pure container scheduling
- OpenShift: Red Hat's enterprise Kubernetes distribution with opinionated
  developer platform built-in
- Tanzu: VMware's Kubernetes platform for enterprise organizations

**First-principles derivation:**
A platform is a force multiplier. One platform engineering team can provide
consistent infrastructure to 50+ product teams. Without a platform, each
product team reinvents the same wheel with different (often incorrect) results.
The platform's ROI is the delta between 50 independent configurations and
one shared, governed configuration.

---

### 💻 Code Example

**Example 1: Golden path CI template (GitHub Actions)**

```yaml
# .github/workflows/build-and-deploy.yml
# Golden path template - teams inherit this
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:

env:
  REGISTRY: ${{ vars.ECR_REGISTRY }}
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # for OIDC -> IRSA
      security-events: write  # for SARIF upload

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.CI_ROLE_ARN }}
          aws-region: us-east-1

      - name: Build image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image (Trivy)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: "1"
          ignore-unfixed: "true"

      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

      - name: Push image
        if: github.ref == 'refs/heads/main'
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

      - name: Sign image (Cosign)
        if: github.ref == 'refs/heads/main'
        env:
          COSIGN_EXPERIMENTAL: "1"
        run: |
          cosign sign --yes \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

> **Code walkthrough:** This golden path template handles the full
> supply chain without any per-team configuration. OIDC authentication
> eliminates long-lived AWS credentials in CI secrets. Trivy blocks
> pushes when CRITICAL CVEs are present. Signing with Cosign uses
> keyless signing (Sigstore) - the signature references the OIDC identity
> of the GitHub Actions workflow, not a static key. Teams copy this
> template and only change the service name.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Container platform strategy means deciding on Kubernetes flavor (EKS,
> GKE), how teams build and deploy images (CI templates), and what security
> policies apply (seccomp, non-root). I understand the golden path concept:
> make the right way the easy way for developers.

*Push deeper:* "The distinction between platform team and product team
is fundamental. Platform team owns the cluster, policies, and CI templates.
Product teams own their Dockerfiles and application configuration. This
division prevents both over-centralization (platform team reviews every
PR) and over-decentralization (every team makes security mistakes
independently)."

---

**Senior / Staff (5+ years):**

> I have designed container platforms for organizations ranging from 20
> to 200 engineers. The key insight from those experiences: the golden path
> must be better than doing it yourself. If the template adds friction, teams
> bypass it. The golden path includes: build caching (BuildKit + registry
> cache = 5x faster builds), scanning with auto-remediation hints, and
> one-command deployment.
>
> For governance at scale: Kyverno policies in audit mode first (no enforcement,
> just logging non-compliant resources) for 4-6 weeks. Use audit data to
> understand the scope of non-compliance. Fix the largest clusters first.
> Then enable enforce mode. This avoids the "big bang enforcement" that
> blocks all deployments on switch-on day.

*Push deeper:* "The network architecture is the hardest platform decision.
A service mesh (Istio) provides automatic mTLS between services, distributed
tracing, and traffic management. But Istio adds 20-30% latency overhead
per hop from sidecar proxies. Cilium's eBPF-based approach achieves
similar observability with 5% overhead. For latency-sensitive inter-service
communication, the CNI choice has a measurable SLA impact."

---

### ⚖️ Comparison Table

| Platform Approach | Control | Complexity | Cost | Use When |
|---|---|---|---|---|
| **Managed K8s (EKS/GKE)** | Low | Low | Medium | Most organizations |
| Self-managed K8s | High | High | Low (ops cost high) | Edge, air-gapped, specific compliance |
| OpenShift | Medium | Medium | High (license) | Enterprise with Red Hat commitment |
| Serverless (ECS Fargate) | Very Low | Very Low | High per unit | Variable load, no K8s expertise |

**The deciding factor:** Managed Kubernetes for teams without dedicated
platform engineering. Self-managed only if compliance or edge requirements
prevent cloud control plane dependency. OpenShift when Red Hat support
is a requirement.

---

### ⚠️ Common Misconceptions

**"Container platform = Kubernetes."**

Kubernetes is the runtime layer. A container platform includes the
golden path CI/CD templates, governance policies, supply chain security,
observability, and the organizational structure (platform team vs
product teams) that makes it all work at scale.

**"All teams should manage their own Kubernetes configuration."**

This creates 50 different security configurations with 50 different
failure modes. A platform team with golden path templates and enforcement
via admission controllers provides consistent security across all teams
without per-team security expertise.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Golden path too complex | Teams bypass it, use raw kubectl | Developer survey + adoption metrics | Simplify; add escape hatch with guardrails |
| Governance big bang | All deployments blocked on enforce day | Admission controller enforce without audit first | Use audit mode 4-6 weeks before enforce |
| No default NetworkPolicy | Compromised pod can reach all services | Network traffic analysis shows unrestricted east-west | Add default-deny + explicit allowlist NetworkPolicies |
| Platform team bottleneck | Product teams wait weeks for platform changes | PR queue backlog | Self-service via templates + GitOps |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Platform team vs product team concept |
| Mid | 5 min | Golden path components, managed vs self-managed |
| Senior | 10 min | Governance layers, golden path design |
| Staff | 15 min | Organizational model, supply chain, CNI/service mesh |

---

**[SENIOR] Q1 - How do you design a developer golden
path for containerized Java services?**

*Why they ask:* Platform design experience.

*Likely follow-up:* "How do you enforce adoption?"

A developer golden path is a pre-built, opinionated set of tools and
templates that represent the standard way to build, deploy, and operate
containerized services.

Components:
1. CI template (GitHub Actions / GitLab CI): build image, scan with Trivy,
   sign with Cosign, push to registry. Teams copy this template and change
   the service name. Zero security decisions required.

2. Dockerfile base template: FROM gcr.io/distroless/java21:nonroot with
   standard JVM flags (MaxRAMPercentage=75, G1GC, GC logging). Teams copy
   and add their COPY app.jar line.

3. Helm chart base: Kubernetes Deployment with all security contexts set
   (runAsNonRoot, readOnlyRootFilesystem, capabilities drop ALL, seccomp).
   Teams inherit the base and override only service-specific values
   (image name, port, resource limits).

4. Local development: docker-compose template with the same base image
   and JVM flags for local parity with production.

Enforcement: Golden path adoption is tracked via Kyverno audit. Teams
using non-standard images or missing security contexts are reported.
Initially: gentle reminder. Later: advisory block (non-blocking) that
explains the gap. Eventually: blocking enforcement with escape hatch
(teams can request an exception with documented rationale).

*What separates good from great:* The escape hatch - the golden path
must have a documented process for legitimate exceptions (legacy apps,
special hardware needs) to prevent the path from being bypassed entirely.

---

**[STAFF] Q2 - ARCHITECTURE: How do you design a
multi-tenant container platform for 50+ teams with
different security and compliance requirements?**

*Why they ask:* Staff-level platform architecture.

*Likely follow-up:* "How do you handle PCI DSS workloads alongside non-regulated?"

Multi-tenancy in Kubernetes has three models: namespace-per-team,
cluster-per-team, and namespace-per-environment with team RBAC.

Namespace-per-team with RBAC (recommended for most):
Each team gets dedicated namespaces (team-a-dev, team-a-staging, team-a-prod).
Namespace-scoped RBAC allows team-a to deploy to team-a-* but not team-b-*.
Resource quotas per namespace prevent one team exhausting cluster resources.
NetworkPolicy with default-deny prevents cross-team traffic.

Cluster-per-team (for regulated workloads):
Teams with PCI DSS, HIPAA, or similar compliance get dedicated clusters.
This provides full kernel isolation (no shared node kernel) and separate
audit logs. Higher cost but required for some compliance frameworks.

Platform governance across all tenants:
- Global admission controller (Kyverno ClusterPolicy) applies to all namespaces
- Cluster-scoped audit logging (CloudTrail, GKE audit logs) for forensics
- Per-namespace Pod Security Admission labels for compliance tiers
- Namespace labels indicating compliance tier: `compliance: pci, baseline, standard`

The compliance tier mapping:
pci-* namespaces: restricted PSA + dedicated node pool + enhanced network logging
hipaa-* namespaces: restricted PSA + encryption at rest + audit log retention 7y
standard-* namespaces: baseline PSA + shared node pool

Multi-cluster management: Argo CD or Flux for GitOps across all clusters.
A single Git repository holds all cluster configurations. Changes propagate
automatically. Provides audit trail (every config change is a git commit).

*What separates good from great:* The compliance tier labeling system - 
one platform with different security profiles per namespace, not separate
platforms. Reduces operational overhead while meeting compliance requirements.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| CTO/Engineering director | Strategy | Platform team ROI, developer experience |
| Platform/SRE | Implementation | Admission controllers, CNI choice, gitops |
| Security officer | Governance | Supply chain, compliance tiers, audit |
| Staff engineer | Architecture | Multi-tenancy models, service mesh trade-offs |

---
---

# Container Migration Strategy

**Interview Weight:** high - Migrating workloads to containers is
a Staff-level concern that requires balancing technical, organizational,
and risk dimensions.

---

### 🎯 Model Answer

**30 seconds:**

> Container migration follows a lift-and-shift -> containerize -> optimize
> progression. Lift-and-shift runs existing JARs in containers with minimal
> changes. Containerize adds proper health checks, non-root users, and
> environment-variable configuration. Optimize refactors for container-
> native operation: horizontal scaling, stateless design, Kubernetes-aware
> health probes. The biggest risk is trying to do all three at once.
> Migrate the operational model incrementally.

**3 minutes (Senior):**

> The migration strategy is driven by risk tolerance and team capability.
> For mature organizations with DevOps experience, a direct containerize +
> Kubernetes deployment is feasible. For organizations new to containers,
> a three-phase progression reduces risk.
>
> Phase 1 - Containerize: package the existing JAR in a container image.
> Use the existing deployment mechanism (EC2, bare metal) but deploy Docker
> containers. This gives the team container experience without Kubernetes
> complexity. Focus on correct Dockerfile practices (non-root, health checks,
> proper signal handling).
>
> Phase 2 - Orchestrate: migrate to Kubernetes. Add Kubernetes-specific
> configuration: startup/liveness/readiness probes, resource limits, horizontal
> pod autoscaler. Applications may need changes for graceful shutdown (Spring
> lifecycle hooks). This is where most incidents occur - understand the
> Kubernetes rolling update mechanism before enabling it on production traffic.
>
> Phase 3 - Optimize: revisit the application architecture for cloud-native
> operation. Eliminate local state (use Redis or the database). Optimize
> the container image (multi-stage, distroless). Add distributed tracing.
> Right-size resource limits based on production data.
>
> The organizational component: container migration requires developers
> to learn new tools (kubectl, Helm) and new mental models (immutable
> infrastructure, stateless services). Training and a supportive platform
> team are as important as the technical migration plan.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container migration strategy -
how to move existing applications to containers without causing incidents."

**(2) First principles:** "Migration risk is proportional to change scope.
Change one thing at a time: first containerize (Dockerfile), then
orchestrate (Kubernetes), then optimize (cloud-native patterns)."

**(3) Bridge:** "Like renovating a house while living in it. You move
one room at a time, ensure the rest of the house is still livable, then
move to the next room."

---

### 📘 Concept Explanation

**What it is:**
Container migration strategy is the plan for moving existing applications
from non-containerized deployments (VMs, bare metal, PaaS) to containerized
environments with minimal risk and disruption.

**The problem it solves:**
Container migration is a complex multi-dimensional change (technical,
operational, organizational). Without a strategy, teams attempt too much
at once and cause production incidents.

**How it works:**

```
Migration Phases:

Phase 1 - Containerize (2-4 weeks):
  - Write Dockerfile (non-root, health check, signal)
  - Run in container locally, verify behavior
  - Push to private registry
  - Deploy container to existing infra (EC2 + Docker)
  - Risk: LOW (no orchestrator change)

Phase 2 - Orchestrate (4-8 weeks):
  - Create Kubernetes Deployment and Service
  - Configure startup/liveness/readiness probes
  - Set resource requests and limits
  - Test rolling updates (graceful shutdown)
  - Deploy to staging -> production
  - Risk: MEDIUM (Kubernetes introduces new failure modes)

Phase 3 - Optimize (ongoing):
  - Multi-stage builds, distroless images
  - Horizontal pod autoscaling
  - Eliminate local state (sessions, files)
  - Distributed tracing, structured logging
  - Right-size based on production metrics
  - Risk: LOW per change (incremental improvements)
```

**The key insight:**
The most common migration failure is attempting Phase 1-3 simultaneously.
The Kubernetes learning curve combined with application changes and operational
changes creates too many simultaneous failure modes.

**When to skip Phase 1:**
Teams with existing Docker + container experience can proceed directly
to Phase 2. Phase 1 is for teams new to containers.

**When to extend Phase 2:**
Applications with complex state management, session-based auth, or
heavy file I/O need application changes before Kubernetes deployment.
Identify these early (in Phase 1) and plan Phase 2 accordingly.

**First-principles derivation:**
Migration is change management. Each phase isolates one set of risks.
Phase 1 isolates containerization risks. Phase 2 isolates orchestration
risks. Phase 3 isolates optimization risks. Isolating risks makes failures
diagnosable and recoverable.

---

### 💻 Code Example

**Example 1: Application readiness checklist for Kubernetes**

```bash
# Pre-Kubernetes readiness assessment

# 1. Signal handling - does the app shut down gracefully?
docker run -d --name test myapp:latest
docker stop -t 10 test  # sends SIGTERM, waits 10s
docker logs test | tail -5
# Should show: "Graceful shutdown complete"
# If shows abrupt cut: signal handling not implemented

# 2. Health endpoint - does an HTTP health check work?
docker run -d -p 8080:8080 myapp:latest
curl http://localhost:8080/actuator/health
# Should return: {"status":"UP"}

# 3. Config via env vars - does the app read from env?
docker run -d \
  -e SPRING_DATASOURCE_URL=jdbc:h2:mem:test \
  myapp:latest
# Should start with H2 in-memory DB

# 4. Non-root - is the app non-root?
docker run -d myapp:latest
docker exec <id> id
# Should show: uid=1000(appuser) not uid=0(root)

# 5. Stateless - no local session state?
# Run 2 instances, make request to each
# Both should serve same response (no server-sticky state)
```

> **Code walkthrough:** This pre-migration checklist validates the four
> Kubernetes requirements: graceful shutdown (Kubernetes sends SIGTERM and
> waits terminationGracePeriodSeconds), HTTP health endpoint (required for
> readiness and liveness probes), environment variable configuration (no
> hardcoded URLs or credentials), and non-root operation (security context).
> Any item that fails is a migration blocker that must be fixed before
> proceeding to Kubernetes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Container migration follows containerize -> Kubernetes -> optimize phases.
> The key checklist: graceful shutdown with SIGTERM, HTTP health endpoints,
> configuration via environment variables, non-root operation.

*Push deeper:* "The most common migration blocker is local session state.
A web application storing user sessions in memory (HttpSession on Tomcat)
breaks when deployed to multiple pods - sessions are not shared between pods.
The fix is externalized session state (Spring Session + Redis) before
Kubernetes migration."

---

**Senior / Staff (5+ years):**

> Migration projects fail when the scope is too large. My approach: pick
> the simplest, least traffic-critical service first. Use it as the migration
> learning exercise. Document what broke, what the fixes were, and what
> the Kubernetes Deployment template looks like. Then apply that template
> to the next service.
>
> For state management: identify all stateful patterns before migration.
> File system use: move to S3. In-memory sessions: externalize to Redis.
> Database connections: ensure the app handles connection pool exhaustion
> gracefully (Kubernetes rolling updates reduce the connection pool while
> both old and new pods are running).

*Push deeper:* "Blue-green deployment vs rolling update: for the first
Kubernetes migration, use blue-green (deploy new version alongside old,
switch traffic via DNS or load balancer). Rolling updates are more efficient
but require the old and new versions to be compatible (API contract,
database schema). For initial migrations, blue-green reduces risk at
the cost of double resources during the switch."

---

### ⚖️ Comparison Table

| Migration Approach | Risk | Complexity | Rollback | Use When |
|---|---|---|---|---|
| **Phased (3 phases)** | Low | Medium | Easy per phase | New to containers |
| Direct to Kubernetes | Medium | High | Complex | Experienced team |
| Strangler Fig pattern | Very Low | High | Easy | Legacy monolith, partial migration |
| Re-platform to managed service | Low | Low | N/A | Stateless services with PaaS fit |

**The deciding factor:** Phased migration for teams without container
experience. Direct migration for teams with Docker experience migrating
to Kubernetes. Strangler Fig for monoliths that need partial migration.

---

### ⚠️ Common Misconceptions

**"Lift-and-shift to containers provides all the benefits."**

Running an application in a container without addressing health checks,
signal handling, and stateless design gives the deployment mechanism of
containers without the operational benefits (rolling updates, auto-healing,
horizontal scaling). Lift-and-shift is Phase 1 of migration, not the goal.

**"Container migration requires rewriting the application."**

Most Spring Boot applications require only configuration changes (add actuator
health endpoints, configure graceful shutdown, externalize session state).
Application logic does not need to change for basic containerization. Rewrites
are needed only for deeply stateful applications that cannot externalize state.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Rolling update causes session loss | Users logged out during deployment | Sessions stored in-memory on pod | Spring Session + Redis before K8s migration |
| DB connection exhaustion on rolling update | DB shows max connections during deployment | Old and new pods both hold connections during rollout | Tune maxPoolSize; use HikariCP connection pool timeout |
| Graceful shutdown not completing | Requests dropped during rolling update | Pod receives SIGTERM, does not drain connections | Enable Spring Boot graceful shutdown; set timeout |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Migration phases overview |
| Mid | 5 min | Pre-migration checklist, common blockers |
| Senior | 10 min | State management, deployment strategy |
| Staff | 14 min | Organizational change, prioritization, rollback strategy |

---

**[SENIOR] Q1 - What are the blockers to running a
Spring Boot application in Kubernetes, and how do
you address each?**

*Why they ask:* Migration planning experience.

*Likely follow-up:* "Which blocker is most commonly missed?"

Four blockers commonly encountered:

1. No graceful shutdown: Spring Boot 2.3+ has built-in graceful shutdown.
   Enable it: spring.lifecycle.timeout-per-shutdown-phase=30s
   This completes in-flight requests before the context closes.
   Pair with terminationGracePeriodSeconds: 60 in Kubernetes.

2. No health endpoints: Spring Boot Actuator provides /actuator/health.
   Enable: management.endpoints.web.exposure.include=health
   Configure separate /health/liveness and /health/readiness.

3. In-memory session state: HttpSession stored in-memory.
   Fix: spring-session-data-redis + Redis cache.
   Configure: spring.session.store-type=redis

4. Hardcoded URLs or credentials: database URL in application.properties.
   Fix: externalize to environment variables or ConfigMaps.
   Spring relaxed binding: SPRING_DATASOURCE_URL env var -> spring.datasource.url

Most commonly missed: database connection pool exhaustion during rolling
updates. When a new pod starts, it opens N connections. Old pod is still
running. If database max_connections = 100 and each pod has pool size 10,
a 10-pod deployment hits the limit during updates when old and new pods
co-exist. Fix: reduce pool size or increase database max connections.

*What separates good from great:* The connection pool exhaustion during
rolling update - a timing issue that only appears during Kubernetes rolling
deploys, not in standalone operation.

---

**[STAFF] Q2 - BEHAVIORAL: Describe a container
migration you led. What was the biggest challenge?**

*Why they ask:* Leadership and real-world complexity.

*Likely follow-up:* "What would you do differently?"

Situation: Led migration of 8 Java microservices from EC2 auto-scaling
groups to Kubernetes. Services handled payment processing. Zero downtime
required. Team had no prior Kubernetes experience.

Task: Design and execute the migration with zero production incidents.

Action:
First: ran all 8 services through a readiness assessment. Found 3 blockers:
(1) 2 services used in-memory sessions, (2) 1 service wrote temp files
to /tmp on the instance, (3) all services used hardcoded database URLs.

Phase 1 (4 weeks): fixed blockers. Migrated sessions to Redis.
Moved temp file writes to a volume. Externalized all configuration.

Phase 2 (8 weeks): containerized each service. Ran on EC2 with Docker
first (no Kubernetes). This gave the team container experience without
Kubernetes complexity. Caught 2 signal handling bugs here.

Phase 3 (4 weeks per service): migrated to Kubernetes. Started with
the lowest-traffic service as the learning service. Used blue-green
deployment (not rolling update) for the first three services. After
the team understood Kubernetes behavior, switched to rolling updates.

Result: 8 services migrated in 16 weeks. Zero production incidents.

What I'd do differently: start the Redis session migration earlier.
It was technically simple but required security review (new infrastructure).
Security review added 2 weeks to Phase 1.

*What separates good from great:* Using the lowest-traffic service as
the learning exercise and blue-green for the first migrations - explicit
risk reduction rather than applying the same approach to all services.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Engineering manager | Organizational | Team training, phased approach, risk |
| Staff engineer | Technical | State management, deployment strategy |
| DevOps | Process | Golden path, readiness checklist |
| Security | Compliance | Baseline checks, supply chain continuity |

---
---

# Container Image Supply Chain Security

**Interview Weight:** high - Supply chain security is a top industry
concern after Solar Winds, Log4Shell, and XZ. Interviewers ask this
to assess whether you understand the full container artifact lifecycle
and can design a tamper-evident delivery pipeline.

---

### 🎯 Model Answer

**30 seconds:**

> Container supply chain security ensures that every image running in
> production was built from known source code by an authorized CI pipeline
> and has not been modified in transit. The technical implementation:
> Cosign signs the OCI image digest using a key managed by KMS. An admission
> controller verifies the signature before allowing the container to start.
> An SBOM (Software Bill of Materials) documents every package in the image
> for CVE correlation. Together: sign, verify, scan, audit.

**3 minutes (Senior):**

> Supply chain attacks target the gap between source code and running
> containers. Solar Winds was a build system compromise. Log4Shell was
> a transitive dependency vulnerability. XZ was a contributor trust issue.
> Container supply chain security addresses all three vectors.
>
> The build system attack (Solar Winds): lock down CI system access.
> Use OIDC for CI-to-registry authentication (no static secrets). Pin
> CI action versions to digest (not tag) to prevent action compromise.
> Build hermetically - dependencies fetched only from approved sources.
>
> The transitive dependency attack (Log4Shell): SBOM generation (Syft) at
> build time creates a manifest of every package in the image. Grype scans
> the SBOM against CVE databases. Store the SBOM in the OCI registry as a
> referrer artifact. When Log4Shell was disclosed, teams with SBOMs identified
> affected images in minutes; teams without SBOMs spent days manually checking.
>
> The image integrity attack: Cosign signs the image digest. The digest is
> the SHA256 hash of the image manifest - any modification changes the digest,
> invalidating the signature. Kubernetes admission controller (Kyverno policy)
> verifies the signature before allowing the container to run. An attacker
> who modifies the image in the registry cannot produce a valid signature
> without the signing key.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container supply chain security -
ensuring only trusted, unmodified images run in production."

**(2) First principles:** "The supply chain is the path from source code
to running container. Every step is an attack surface. Sign the artifact at
each step, verify before executing."

**(3) Bridge:** "Like a pharmaceutical supply chain: the manufacturer (CI)
signs each pill bottle. The pharmacy (registry) stores it securely. The
patient (Kubernetes) verifies the seal before dispensing."

---

### 📘 Concept Explanation

**What it is:**
Container image supply chain security is the set of practices ensuring
that container images in production were built from trusted sources by
authorized pipelines and have not been tampered with in transit.

**The problem it solves:**
Container images bundle application code with OS packages and dependencies.
Compromising the image (via build system attack, registry compromise, or
dependency substitution) can deliver malicious code to production.

**How it works:**

```
Supply Chain Security Pipeline:

  Source Code (Git)
      | signed commits (GPG/SSH)
      v
  CI Build (GitHub Actions / GitLab)
      | hermetic build: no network access
      | pin action versions to digest
      | OIDC auth (no static CI secrets)
      v
  Image Build
      | BuildKit: no secrets in layers
      | multi-stage: minimal final image
      v
  Scan (Trivy)
      | blocks on CRITICAL CVEs
      | --exit-code 1
      v
  SBOM Generation (Syft)
      | CycloneDX JSON format
      | stored as OCI artifact referrer
      v
  Sign (Cosign + KMS)
      | signs the image digest
      | signature stored as OCI referrer
      v
  Registry (ECR / Harbor)
      | stores image + SBOM + signature
      v
  Deploy (Kubernetes)
      | admission controller: verify signature
      | unsigned image = deployment rejected
      v
  Runtime
      | Falco: detect runtime anomalies
```

**The key insight:**
The entire chain must be tamper-evident. A signature on the image provides
integrity. An SBOM provides transparency (what is in the image). Admission
control provides enforcement (only signed images run). Without all three,
the chain has gaps.

**When to implement fully:**
Regulated workloads (PCI DSS, HIPAA), financial services, government.
For smaller teams: start with CI scanning + registry scanning. Add signing
when the team has operational experience with Cosign.

**Alternatives:**
- Notary v2 (Notation): alternative to Cosign for image signing
- SPIFFE/SPIRE: workload identity attestation (complements signing)
- Binary Authorization (GCP): GCP-native admission control with signing

**First-principles derivation:**
Trust is established through verifiable cryptographic evidence, not
assumptions. An unsigned image in a registry has no provenance - it could
have been pushed by anyone with registry write access. A signed image
has a cryptographic link to the identity that produced it (CI pipeline
OIDC identity). This link can be verified independently before execution.

---

### 💻 Code Example

**Example 1: Cosign sign and verify workflow**

```bash
# Sign image with Cosign (keyless - OIDC identity)
# Run in CI after pushing image
cosign sign --yes \
    --rekor-url https://rekor.sigstore.dev \
    myregistry.io/myapp:${GIT_SHA}
# Signature stored as OCI referrer in registry
# Tied to CI runner's OIDC identity

# Verify signature before deployment
cosign verify \
    --certificate-identity-regexp \
        "https://github.com/myorg/myrepo/" \
    --certificate-oidc-issuer \
        "https://token.actions.githubusercontent.com" \
    myregistry.io/myapp:${GIT_SHA}

# Kyverno policy: require valid Cosign signature
# (Applied as ClusterPolicy in Kubernetes)
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-signature
spec:
  validationFailureAction: Enforce
  rules:
  - name: verify-image
    match:
      resources:
        kinds: [Pod]
    verifyImages:
    - imageReferences: ["myregistry.io/*"]
      attestors:
      - entries:
        - keyless:
            subject: "https://github.com/myorg/myrepo/*"
            issuer: >
              https://token.actions.githubusercontent.com
```

> **Code walkthrough:** Cosign keyless signing uses the CI runner's
> OIDC token (GitHub Actions provides one per workflow run) to sign
> the image digest without a static private key. The signature is stored
> in the same registry as an OCI referrer artifact. The Kyverno policy
> verifies that any pod starting from myregistry.io/* has a valid signature
> from a GitHub Actions workflow in myorg/myrepo. Any image pushed without
> going through this CI workflow is blocked from running.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Supply chain security means ensuring images in production came from
> authorized CI and have not been tampered with. Tools: Cosign for signing,
> Trivy for CVE scanning, SBOM for package inventory.

*Push deeper:* "Keyless Cosign signing (Sigstore) is the practical choice
for most teams. It uses the CI system's OIDC identity (GitHub Actions workflow,
GitLab CI job) instead of a static private key. No key management required.
The signature references the exact workflow that built it."

---

**Senior / Staff (5+ years):**

> After Log4Shell, our team added SBOM generation to all CI pipelines.
> When the CVE was disclosed, we ran `grype sbom:sbom.json` against all
> 40 services' SBOMs in 10 minutes. Identified 8 affected services immediately.
> Teams without SBOM spent 2-3 days manually checking.
>
> The full supply chain implementation: CI uses OIDC (no static secrets),
> Cosign signs with keyless (no key management), SBOMs stored as OCI referrers,
> Kyverno enforces signature verification. The attack surface is the OIDC
> issuer (GitHub/GitLab) - compromising the CI provider is the remaining
> attack vector. For critical workloads, add reusable workflow restrictions
> in GitHub so only specific workflows can produce signatures.

*Push deeper:* "SLSA (Supply-chain Levels for Software Artifacts) provides
a maturity framework. Level 1: build is scripted (baseline). Level 2: hosted
CI with provenance attestations. Level 3: hardened build platform (isolated
runners, hermetic builds). Level 4: two-party review. Most organizations
target SLSA Level 2 as the baseline. SLSA Level 3 requires hermetic builds
(no network access during build except to approved artifact registries)."

---

### ⚖️ Comparison Table

| Control | Threat | Tool | Enforcement Point |
|---|---|---|---|
| **Image signing** | Registry tampering | Cosign | Admission controller |
| **SBOM** | Transitive CVE visibility | Syft | CVE scanner (Grype) |
| **CVE scanning** | Known vulnerabilities | Trivy | CI pipeline block |
| **Provenance attestation** | Build system compromise | SLSA + Cosign | Attestation verification |
| **Admission control** | Unauthorized images | Kyverno | Kubernetes API server |

**The deciding factor:** Implement in order of risk reduction per effort.
Start with CI scanning (Trivy), then add SBOM, then Cosign signing with
admission control. Each step adds a layer of tamper evidence.

---

### ⚠️ Common Misconceptions

**"Private registry = secure supply chain."**

A private registry with authentication only prevents unauthorized pushes.
It does not prevent a compromised CI pipeline from pushing a malicious
image. Image signing with admission control enforcement provides the
integrity guarantee: only images built by authorized pipelines can run.

**"SBOM is a compliance checkbox, not operationally useful."**

SBOMs enable rapid CVE impact assessment (as in Log4Shell) and provide
the audit trail required by emerging regulations (US EO 14028, EU Cyber
Resilience Act). The operational benefit - identifying affected images
in minutes vs days - is measurable.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Unsigned image in production | Security audit flags unsigned images | Check cosign verify against all prod images | Add CI signing step; add admission controller |
| SBOM not generated | CVE impact assessment takes days | Registry lacks SBOM referrer artifacts | Add Syft to CI pipeline |
| Cosign key rotation | All signatures invalid after rotation | Admission controller rejects all images | Use keyless (no rotation); or rotate with planned overlap |
| Admission controller blocks emergency deploy | Cannot deploy fix during incident | Cosign verify fails for emergency patch | Add emergency bypass with dual-sign requirement + audit log |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 2 min | Define supply chain security, why it matters |
| Mid | 5 min | Cosign, SBOM, Trivy scanning in pipeline |
| Senior | 10 min | Full pipeline, SLSA levels, admission control |
| Staff | 15 min | Log4Shell response, emergency bypass, SLSA 3 |

---

**[SENIOR] Q1 - How does image signing with Cosign
prevent supply chain attacks?**

*Why they ask:* Supply chain security implementation knowledge.

*Likely follow-up:* "What is keyless signing?"

The attack Cosign prevents: an attacker with write access to the registry
(compromised registry credentials) pushes a modified version of the image
with malicious code. The image name and tag are unchanged. Without signing,
the new image runs in production.

With Cosign:
CI signs the image after building: `cosign sign image@sha256:abc123`.
The signature is stored as an OCI referrer artifact in the registry.
The signature cryptographically binds to the image digest (SHA256 hash
of the image content). Any modification to the image changes the digest,
invalidating the signature.

Kubernetes admission control (Kyverno) verifies the signature before
allowing the pod to start: "Is there a valid Cosign signature from our
CI pipeline for this image digest?" A modified image has no valid
signature -> pod rejected.

Keyless signing (Sigstore):
Instead of a static private key (which requires key management and rotation),
keyless signing uses the CI runner's OIDC token. GitHub Actions provides
an OIDC token per workflow run identifying the workflow, repository, and branch.
Cosign binds the signature to this OIDC identity. No key to manage or rotate.
The verification checks: "Was this signed by a GitHub Actions workflow in
myorg/myrepo?" - tied to the identity, not a stored key.

*What separates good from great:* Understanding that keyless signing uses
OIDC identity (the workflow that ran, not a static key) and that the
signature is stored as an OCI referrer (not a sidecar file) - both details
that show deep Cosign knowledge.

---

**[STAFF] Q2 - BEHAVIORAL: How did your organization
respond to the Log4Shell vulnerability in containerized
services?**

*Why they ask:* Real-world supply chain security response.

*Likely follow-up:* "What did you add to prevent similar delays next time?"

Situation: Log4Shell (CVE-2021-44228) was disclosed December 9, 2021.
The team had 40 containerized Java services. The vulnerability required
identifying which services used log4j2 (directly or transitively) and
deploying patched images.

Task: Assess impact and deploy fixes within 24 hours (CRITICAL CVE SLA).

Action:
Without SBOM (Day 1 approach): manually checking each service's pom.xml.
43 services x 5 minutes each = 3.5 hours to assess scope. Then identify
if log4j2 was a transitive dependency (not directly in pom.xml). This
required running `mvn dependency:tree | grep log4j2` for each service
in the repository. Total assessment: ~8 hours.

Result: 9 of 40 services were affected. Deployed patches to all 9 within
the 24-hour SLA. Close call.

What we added immediately after:
1. Grype scanning in CI: now catches known Log4j CVEs before deploy.
2. Syft SBOM generation: every image now has a CycloneDX SBOM stored
   in the registry as an OCI referrer.
3. SBOM-based impact query script: `for img in $(kubectl get pods -A -o json | jq -r '...|.image'); do grype sbom:$(cosign download sbom $img) --only-fixed; done`
   This scans all running images' SBOMs for fixable CVEs in under 10 minutes.

Next Log4j equivalent: assessment in minutes, not hours.

*What separates good from great:* The specific technical implementation
of SBOM-based rapid impact assessment - not just "we added scanning" but
the operational workflow that runs across all running images.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Security officer | Supply chain | Full pipeline, SLSA levels, audit trail |
| Platform engineer | Implementation | Cosign keyless, Kyverno policy, OCI referrers |
| Staff engineer | Architecture | Emergency bypass, SLSA 3 hermetic builds |
| Engineering manager | Risk management | Log4Shell response speed, SBOM ROI |
