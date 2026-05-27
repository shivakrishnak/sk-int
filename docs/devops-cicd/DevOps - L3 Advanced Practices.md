---
layout: default
title: "DevOps - L3 Advanced Practices"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 5
permalink: /devops-cicd/l3-advanced-practices/
---

# GitOps Workflow and ArgoCD

🎯 Interview Weight: very high - GitOps is the modern standard
for Kubernetes deployments. Expected at senior/staff level.

---

### 🎯 Model Answer

**30 seconds:**
> GitOps: the desired state of your infrastructure and
> applications is declared in Git. A GitOps operator (ArgoCD,
> Flux) continuously reconciles the cluster state to match
> the Git state. Deployment = Git commit. Rollback = Git revert.
> Audit trail = Git history. Two repositories: app code repo
> (triggers CI, produces an image) and config repo (stores
> Kubernetes YAML/Helm values, updated by CI after image build).

**3 minutes (Senior):**
> ArgoCD architecture and patterns:
>
> App of Apps pattern:
> One ArgoCD Application deploys all other Applications.
> Root app: `argocd-apps` repository.
> Each app YAML in the root repo creates a child ArgoCD Application.
> Add a new service: add its app YAML to the root config repo.
> ArgoCD auto-discovers and deploys it.
>
> Sync policies:
> Manual: ArgoCD shows drift, human approves sync.
> Automated: ArgoCD syncs automatically when Git changes.
> `selfHeal: true`: if someone manually modifies Kubernetes
> directly, ArgoCD reverts it to match Git (prevents config drift).
> `prune: true`: delete resources not in Git (prevents zombie
> resources after service removal).
>
> Image update automation:
> CI builds image: `my-service:abc1234`.
> CI updates config repo: edits `values.yaml` to set new image tag.
> ArgoCD detects config repo change: syncs cluster.
> Tools: Argo CD Image Updater, Flux Image Automation,
> or a simple CI step that runs `yq` to update the image tag.
>
> Multi-cluster GitOps:
> One ArgoCD (management cluster) manages multiple target clusters.
> `destination: server: https://prod-cluster-api`.
> `destination: server: https://staging-cluster-api`.
> Same config repo, different values files per environment.
> Promotion: PR to merge staging values to production values.
>
> Secret management with GitOps:
> Don't commit plain secrets to the config repo.
> Options: Sealed Secrets (encrypted secrets, safe to commit),
> External Secrets Operator (SecretStore + ExternalSecret YAMLs
> reference Vault/AWS - safe to commit, actual values never in Git).

**Blank Mind Recovery:**

**(1) Restate:** "GitOps: Git is the source of truth. ArgoCD reconciles
cluster to match Git. selfHeal prevents drift. App of Apps for multiple services."

---

### 💻 Code Example

```yaml
# ArgoCD Application manifest (stored in config repo)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payment-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/config-repo
    targetRevision: main
    path: services/payment-service/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true       # Delete removed resources
      selfHeal: true    # Revert manual changes
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
```

> **Code walkthrough:** This ArgoCD Application continuously watches
> the `services/payment-service/overlays/production` path in the
> config repo. When a CI pipeline updates the image tag in that
> path (via a PR merge to `main`), ArgoCD detects the drift and
> syncs the cluster. `selfHeal: true` prevents config drift from
> kubectl manual edits. `prune: true` ensures deleted manifests
> are also deleted from the cluster, preventing resource accumulation.

---

### ⚖️ Comparison Table

| GitOps Tool | Architecture | Strengths | Weaknesses |
|-------------|-------------|-----------|------------|
| ArgoCD | Pull-based, UI | Rich UI, app of apps | Heavy, complex |
| Flux v2 | Pull-based, modular | Lightweight, composable | Less UI |
| Jenkins X | Push-based hybrid | CI built-in | Complex setup |
| Spinnaker | Push-based | Multi-cloud | Resource-heavy |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | GitOps concept + ArgoCD basics |
| Senior | 9 min | App of Apps + sync policies + secret management |
| Staff | 12 min | Multi-cluster GitOps + promotion workflows |

---

---

# Infrastructure as Code Patterns

🎯 Interview Weight: high - IaC is a core DevOps engineering
skill. Expected at mid/senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Infrastructure as Code: infrastructure (VPCs, databases, clusters,
> load balancers) defined in version-controlled code. Changes:
> code review + CI validation + `terraform plan` (show diff) +
> `terraform apply`. Tools: Terraform (multi-cloud, HCL), Pulumi
> (Python/TypeScript), AWS CDK (CloudFormation via code), Ansible
> (configuration management, less for provisioning). Benefits:
> reproducible environments, documented infrastructure, testable
> changes, rollback via Git revert.

**3 minutes (Senior):**
> Terraform patterns:
>
> Module structure:
> `modules/`: reusable, parameterized Terraform modules.
> `modules/rds/`: RDS instance with standard backup, monitoring.
> `environments/staging/`: calls `module "rds" { source = "../../modules/rds" }`.
> `environments/production/`: same module, different variables.
> DRY principle: one module definition, many environments.
>
> State management:
> Never use local state. Remote state: S3 + DynamoDB (state locking).
> `terraform init` with S3 backend: state is shared across team.
> State lock: prevents two engineers running `apply` simultaneously.
> State file contains sensitive data (DB passwords). Encrypt S3 bucket.
>
> `terraform plan` output in CI:
> CI runs `terraform plan` on every PR.
> Output posted as a PR comment (Atlantis, Terraform Cloud).
> Team reviews diff: "creating 3 resources, modifying 1, destroying 0".
> Senior engineer approves before merging.
>
> Drift detection:
> Schedule `terraform plan` nightly (no apply).
> Alert if plan shows unexpected changes (someone modified infra
> manually outside Terraform).
> This is the GitOps principle applied to infrastructure.
>
> Secrets in Terraform:
> Never commit secrets to `variables.tf`.
> Use `TF_VAR_db_password` environment variable from CI secrets.
> Or: `data "vault_secret" "db" { path = "secret/db" }` to
> read from Vault at apply time.

**Blank Mind Recovery:**

**(1) Restate:** "IaC: infrastructure in code, reviewed, planned, applied.
Terraform: modules + remote state + plan review before apply."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Terraform basics + state management |
| Senior | 8 min | Module patterns + drift detection + Atlantis |
| Staff | 12 min | Multi-cloud IaC + Pulumi vs Terraform + governance |

---

---

# Multi-Environment Pipeline Design

🎯 Interview Weight: high - Multi-environment pipelines are
essential for safe production deployments.

---

### 🎯 Model Answer

**30 seconds:**
> Multi-environment pipeline: code flows through environments
> (dev -> staging -> production) with quality gates between each.
> Each promotion is a deliberate decision: automated (if tests pass)
> or manual (production gate). Environments must be production-like
> to catch real issues in staging. Configuration is environment-specific.
> Artifacts are built once (in CI) and promoted through environments
> unchanged - same Docker image SHA in staging = same in production.

**3 minutes (Senior):**
> Multi-environment pipeline patterns:
>
> Environment progression:
> Development: every commit, no manual approval.
> Staging: every merge to main, automated deployment.
> Production: manual approval gate (product + SRE sign-off),
> scheduled deployment window (Tuesday and Thursday, 10am-3pm).
>
> Configuration per environment:
> Same Docker image SHA. Different config values.
> Kubernetes: different `values-staging.yaml` and `values-prod.yaml`.
> ArgoCD: different `ApplicationSet` with environment-specific values.
> Connection strings, replica counts, resource limits all differ.
>
> Environment drift prevention:
> Staging must be as close to production as possible.
> Same instance types (not microinstances for staging).
> Same third-party integrations (Stripe test mode, not mocked).
> Same data volume (production data snapshot, anonymized).
> Drift: staging passes, production fails because of environment differences.
>
> Approval gates:
> GitHub Environments: `environment: production` with required
> reviewers. Workflow pauses, sends Slack notification, waits
> for approval. Approved in GitHub UI -> deployment continues.
>
> Post-deployment validation:
> Smoke test suite: 10 critical paths (health check, login,
> checkout). Run after every deployment (all environments).
> If smoke tests fail: automatic rollback triggered.

**Blank Mind Recovery:**

**(1) Restate:** "Multi-env: dev -> staging -> prod. Same image, different config.
Staging mirrors production. Manual approval gate for prod."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Environment pipeline design + config management |
| Senior | 8 min | Environment drift + GitHub Environments + post-deploy validation |

---

---

# DevSecOps and Security in Pipelines

🎯 Interview Weight: very high - Security is a primary engineering
concern. DevSecOps knowledge expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> DevSecOps: security checks embedded in the CI/CD pipeline
> rather than at a release gate. Left-shifting security:
> developers get security feedback during development, not
> weeks later in a security review. Key scans: SAST (static
> analysis for code vulnerabilities), SCA (dependency vulnerability
> scan), container image scan (CVEs in OS packages), DAST
> (dynamic scan against running app), IaC scan (Terraform
> misconfigurations). Fail CI on critical findings.

**3 minutes (Senior):**
> Security pipeline tools:
>
> SAST (Static Application Security Testing):
> Checkmarx, Semgrep, SonarQube SAST.
> Scan source code for SQL injection, XSS, hard-coded credentials,
> insecure random, path traversal vulnerabilities.
> Semgrep: rules run in seconds, low false positives.
> SonarQube SAST: integrated with quality gate.
>
> SCA (Software Composition Analysis):
> OWASP Dependency-Check, Snyk, GitHub Dependabot.
> Scans all transitive dependencies (Maven, npm, pip) for
> known CVEs (Common Vulnerabilities and Exposures).
> Fail CI on CVSS >= 9 (critical). Warn on CVSS >= 7 (high).
> Dependabot: auto-creates PRs to upgrade vulnerable dependencies.
>
> Container image scanning:
> Trivy, Snyk Container, AWS ECR image scanning.
> Scans OS packages (glibc, openssl) and language packages in the image.
> Run before push to registry. Block push on critical CVEs.
> Trivy: `trivy image my-service:latest --exit-code 1 --severity CRITICAL`
>
> IaC security scanning:
> Checkov, tfsec, KICS.
> Scan Terraform/Kubernetes YAML for misconfigurations:
> S3 bucket without encryption, security group allowing 0.0.0.0/0 SSH,
> Kubernetes pod running as root.
>
> Secret scanning:
> GitLeaks, TruffleHog, GitHub Secret Scanning.
> Prevent committing API keys, passwords, certificates to Git.
> Run as a pre-commit hook + CI step.
> GitHub Secret Scanning: alerts immediately if a token is
> pushed (and notifies the token issuer).

**Blank Mind Recovery:**

**(1) Restate:** "DevSecOps: SAST + SCA + image scan + IaC scan + secret scan
all in CI pipeline. Fail on critical. Shift security left."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | SAST vs SCA + DevSecOps concept |
| Senior | 9 min | Semgrep + Trivy + Checkov + secret scanning |
| Staff | 12 min | Security pipeline governance + SBOM + supply chain |

---

---

# Observability Integration in CI/CD

🎯 Interview Weight: high - Observability in pipelines closes
the feedback loop between deployment and production health.

---

### 🎯 Model Answer

**30 seconds:**
> Observability in CI/CD: deployments are monitored using the
> three pillars (metrics, logs, traces) to detect whether a
> deployment is healthy. Post-deployment verification: compare
> error rates, latency, and business metrics before and after
> deployment. Automated rollback: if metrics cross a threshold
> after deployment, trigger automatic rollback. Deployment markers:
> annotate dashboards with deployment events to correlate
> performance changes with releases.

**3 minutes (Senior):**
> Observability-driven deployments:
>
> Deployment markers:
> Grafana annotation: mark deployment time on dashboards.
> Prometheus counter: `deployment_events_total{service, version}`.
> When a spike occurs in latency: immediately see that it
> correlates with deployment X.
>
> Progressive delivery with analysis:
> Argo Rollouts AnalysisTemplate:
> Query Prometheus during canary phase.
> `success_rate: sum(rate(http_requests_total{status=~"2..",
> service="payment"}[5m]))
> / sum(rate(http_requests_total{service="payment"}[5m]))`
> If success rate < 99.5% for the canary: pause rollout + alert.
>
> Pre/post deployment smoke tests:
> Synthetic monitoring: Grafana k6 script running 10 critical
> user journeys every minute.
> On deployment: CI runs the smoke test against the new version
> before switching production traffic.
> Post-deployment: monitor smoke test results for 15 minutes.
>
> DORA metrics in CI/CD:
> Deployment frequency: number of successful deployments per day.
> Lead time: time from commit to production deployment.
> Change failure rate: % of deployments causing incidents.
> MTTR: mean time to restore after a failure.
> Dashboard these in Grafana. Trend upward over time.
>
> OpenTelemetry in CI:
> Trace test execution: each test span, dependencies.
> Identify slow tests (test profiling).
> Correlate test failures with specific code paths.

**Blank Mind Recovery:**

**(1) Restate:** "Observability in CD: deploy markers + automated analysis gates
+ smoke tests post-deploy. DORA metrics to track pipeline health."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Deployment markers + post-deploy monitoring |
| Senior | 9 min | Argo Rollouts analysis + DORA metrics |
| Staff | 12 min | Progressive delivery with automated rollback + SLO-based gates |

| Interviewer Type | Emphasis |
|------------------|---------|
| Platform/SRE | GitOps + observability-driven deployments |
| Security | DevSecOps pipeline + secret scanning |
| Bar Raiser | Progressive delivery + DORA metrics + automated rollback |
