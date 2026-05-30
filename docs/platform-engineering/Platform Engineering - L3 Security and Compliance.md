---
layout: default
title: "Platform Engineering - L3 Security and Compliance"
parent: "Platform Engineering"
nav_order: 10
permalink: /platform-engineering/l3-security-and-compliance/
---

# Platform Engineering - L3 Security and Compliance

## Keywords in This File

| # | Keyword | Weight |
|---|---|---|
| 1 | [Policy as Code and Compliance Automation](#policy-as-code-and-compliance-automation) | critical |
| 2 | [Platform Security Model and Supply Chain](#platform-security-model-and-supply-chain) | critical |

---

# Policy as Code and Compliance Automation

---
id: PE-019
title: Policy as Code and Compliance Automation
category: Platform Engineering
difficulty: ★★☆
interview_weight: critical
seniority: senior
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Policy as Code is the practice of expressing compliance and security
> requirements as machine-readable rules that are automatically evaluated
> and enforced - instead of manual checklists, audit spreadsheets, or
> documentation that no one reads before production incidents. In
> Kubernetes-based platforms, this means OPA Gatekeeper or Kyverno
> admission policies that enforce rules at deployment time, not after
> the fact.

**3 minutes (Senior):**
> The traditional compliance model is fundamentally broken: security teams
> write policies in documents, developers read them occasionally, auditors
> check compliance after the fact, and violations are discovered in
> production. Policy as Code inverts this model: policies are written as
> code, evaluated automatically at every deployment, and violations are
> prevented before they reach production.
>
> In a Kubernetes platform, Policy as Code operates at two levels.
> The admission control level (OPA Gatekeeper, Kyverno) evaluates every
> Kubernetes API request against policy rules before the resource is
> written to etcd. If a Deployment lacks resource limits, the admission
> webhook rejects it. If a container runs as root, the admission webhook
> rejects it. These violations never reach the cluster - they are caught
> at the "compiler" stage. The continuous monitoring level (Kyverno Reports,
> OPA Audit mode, Falco) scans existing resources and running containers
> for policy violations, generating compliance reports that can feed into
> SOC2 or ISO27001 audit evidence.
>
> The platform engineering value: policy as code converts "what does the
> policy say?" from a documentation lookup into a code review. Security
> teams can PR against the policy repository. Platform teams can test
> policies in CI before deploying them. Product teams can see exactly
> why their deployment was rejected and fix it without contacting the
> platform team. Compliance evidence is generated continuously by the
> system, not assembled manually before an audit.

**Framework:** POLICIES AS CODE -> ADMISSION ENFORCEMENT ->
CONTINUOUS MONITORING -> AUTOMATED COMPLIANCE EVIDENCE

*Adapting up:* Staff adds: "The organizational challenge: policy as code
requires security teams to write code, or to partner closely with platform
engineers who can. Many security teams are not engineers. The platform
team's role: translate security requirements into admission policies,
provide a contribution workflow for security teams to propose policy
changes via PR, and run the policy testing infrastructure. The platform
team owns the enforcement mechanism; security teams own the policy content."

*Adapting down:* Junior: "Policy as Code means that the security rules
for how software should be deployed are written as code (Rego scripts or
Kyverno YAML), not as documents. When you try to deploy something that
violates a rule - like a container running as root - your deployment is
automatically rejected with an error message explaining why."

**Blank Mind Recovery:**

**(1) Restate:** "Policy as Code and Compliance Automation - enforcing
security and compliance requirements automatically via code."

**(2) First principles:** "Security policies exist because certain configurations
create risk. If the goal is to prevent risky configurations, the most
reliable enforcement is automatic: check every deployment against the rules,
reject violations before they reach production."

**(3) Bridge:** "Think of it like a compiler: when you write code that violates
type rules, the compiler rejects it immediately. Policy as Code is a
'security compiler' for Kubernetes deployments - reject misconfigured
deployments before they ever run."

---

### 📘 Concept Explanation

**What it is:**
Policy as Code is the practice of expressing security, compliance, and
operational requirements as machine-executable rules that are automatically
evaluated against system state. In Kubernetes-based platforms, this is
implemented through: admission controllers (OPA Gatekeeper, Kyverno) that
evaluate policies at deployment time, and continuous compliance monitors
(Falco, Kyverno Reports, OPA Audit) that scan existing workloads.

**The problem it solves:**
Manual policy compliance has three failure modes: policies are not read
before deployment (documentation is not enforcement), policies are
interpreted differently by different engineers, and policy violations are
discovered after production deployment (expensive to fix). Policy as Code
eliminates all three: policies are enforced at deployment time, they are
unambiguous (code has one interpretation), and violations are caught before
production.

**How it works:**

```
POLICY AS CODE ARCHITECTURE

[Git Policy Repository]
  policies/
    security/
      container-root-prevention.yaml
      resource-limits-required.yaml
      no-privileged-containers.yaml
    compliance/
      pci-namespace-isolation.yaml
      hipaa-secret-encryption.yaml
    operations/
      pod-disruption-budget-required.yaml
      image-registry-allowlist.yaml

   PR WORKFLOW:
   Security team proposes new policy via PR
   --> CI runs policy tests (conftest/kyverno test)
   --> Platform team reviews for operational impact
   --> Merge --> ArgoCD deploys to cluster

[Kubernetes API Server]
   Developer applies Deployment YAML
   --> [Admission Webhook: OPA Gatekeeper / Kyverno]
   --> Policy evaluated against request
   --> ALLOW: resource written to etcd
   --> DENY: error returned to developer with explanation

[Continuous Compliance Monitor]
   Kyverno Reports / OPA Audit mode
   --> Scans existing resources on schedule
   --> Flags resources that violate current policies
   --> Generates compliance report
   --> Feeds into audit evidence pipeline

[Compliance Evidence Pipeline]
   Policy evaluation results --> stored in object storage
   Audit report template --> populated from policy results
   SOC2 evidence packet --> assembled automatically
```

**The key insight:**
Compliance evidence that is collected automatically by the system is
more credible and less expensive than compliance evidence assembled
manually by engineers. "Our admission controller enforces this policy
and no deployments in the last 12 months have violated it" is a stronger
audit statement than "we have a policy document that says not to do this."

**OPA Gatekeeper vs. Kyverno:**

OPA Gatekeeper: uses Rego (a purpose-built policy language) for policy
logic. More expressive for complex policies. Steeper learning curve.
Requires learning Rego. CNCF Graduated.

Kyverno: uses YAML for policy rules. Lower learning curve. More limited
expressiveness for complex policies. CNCF Graduated. Better for teams
without Rego expertise.

Recommendation: Kyverno for organizations starting with policy as code
(lower barrier, faster time to value). OPA/Gatekeeper for organizations
with complex policy requirements or existing OPA investment.

**When to use it:**
Any production Kubernetes cluster with multiple teams. Policy as Code
should be applied at cluster creation time, not after the cluster
has been in use - retrofitting policies to existing clusters is
significantly more complex.

---

### 💻 Code Example

**Example 1: BAD vs GOOD - document policy vs. machine policy**

```markdown
# BAD: policy as a document (Security Policy v1.4.pdf)
## Container Security Requirements

Section 3.2: All containers must not run as root user.
Container images must specify a non-root user in the Dockerfile.
Resource limits must be set for all containers.
Privileged containers are prohibited.

[Engineers: please read and follow these requirements before deployment]
```

```yaml
# GOOD: policy as code (Kyverno ClusterPolicy)
# Enforced at admission - not a document, a rule

apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-non-root-containers
  annotations:
    policies.kyverno.io/title: Require Non-Root Containers
    policies.kyverno.io/description: |
      Containers must not run as root. Set runAsNonRoot: true
      or specify a non-root runAsUser in the securityContext.
    policies.kyverno.io/severity: high
    policies.kyverno.io/category: Pod Security
spec:
  validationFailureAction: Enforce  # Enforce = reject violations
  background: true                   # also scan existing resources
  rules:
  - name: require-non-root
    match:
      any:
      - resources:
          kinds: [Pod]
    validate:
      message: |
        Container must not run as root. Add:
        securityContext:
          runAsNonRoot: true
        See: https://platform.company.com/docs/pod-security
      pattern:
        spec:
          containers:
          - securityContext:
              runAsNonRoot: true
```

> **Code walkthrough:** The BAD pattern is a PDF policy that engineers
> are supposed to read and follow. In practice, it is not read before
> deployments, is interpreted differently by different engineers, and
> violations are discovered in security audits or production incidents.
> The GOOD pattern is a Kyverno ClusterPolicy that is evaluated against
> every Pod admission request. Any pod with a root container is rejected
> immediately with an actionable error message and documentation link.
> The policy is tested in CI, reviewed via PR, and deployed via ArgoCD.
> It cannot be "forgotten to follow" - it is enforced by the API server.

**Example 2: OPA Gatekeeper constraint for image registry allowlist**

```rego
# ConstraintTemplate defines the Rego policy logic
package allowedregistries

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  satisfied := [
    allowed |
    allowed := input.parameters.registries[_]
    startswith(container.image, allowed)
  ]
  not any(satisfied)
  msg := sprintf(
    "Container %v uses image %v from a non-approved registry.
    Approved registries: %v",
    [
      container.name,
      container.image,
      input.parameters.registries
    ]
  )
}
```

```yaml
# Constraint: apply the template with specific parameters
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AllowedRegistries
metadata:
  name: prod-registry-allowlist
spec:
  enforcementAction: deny
  parameters:
    registries:
    - "registry.company.com/"
    - "gcr.io/distroless/"
    - "cgr.dev/chainguard/"
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaceSelector:
      matchLabels:
        environment: production
```

> **Code walkthrough:** The OPA Gatekeeper ConstraintTemplate defines
> the Rego logic for checking image registries: for each container,
> check if its image starts with any of the approved registry prefixes.
> If none match, generate a violation with an actionable error message.
> The Constraint applies this policy to all Pods in production namespaces,
> with specific approved registries. Images from unapproved registries
> (public Docker Hub, for example) are rejected at admission. This
> prevents supply chain attacks via untrusted base images in production.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Policy as Code means writing security rules as code (YAML policies or
> Rego scripts) that are automatically enforced when you deploy to
> Kubernetes. If your deployment violates a rule - like using an
> unapproved container image registry or running as root - the deployment
> is rejected with an error message explaining what's wrong and how to fix
> it. This is much more reliable than security checklists that engineers
> have to remember to check manually.

*Push deeper:* "Two main tools in Kubernetes: OPA Gatekeeper uses Rego
language for policies (more powerful, steeper learning curve) and Kyverno
uses YAML (easier to get started). Most teams start with Kyverno for
common policies like 'no root containers' and 'require resource limits'."

---

**Senior / Staff (5+ years):**
> Policy as Code is the infrastructure-as-code approach applied to
> security and compliance. Policies live in a git repository, are reviewed
> via PRs, tested in CI before deployment, and enforced automatically at
> admission time. The organizational value: security requirements become
> auditable, testable, and automatically enforced - not documents that
> are ignored.
>
> The implementation I've found most effective: Kyverno for standard
> policies (no root, resource limits required, image registry allowlist),
> OPA Gatekeeper for complex organizational policies (cross-namespace
> quota enforcement, custom compliance rules). Both run with PodDisruptionBudgets
> and >= 3 replicas to ensure the admission webhook is always available.
> A flaky admission webhook is a cluster reliability incident.

*Push deeper:* "At Staff level: the compliance automation value is most
evident at audit time. SOC2 audit evidence for 'access controls' used
to require 2 weeks of manual evidence gathering. With policy as code and
continuous compliance scanning (Kyverno Reports + OPA Audit mode), we
generate the audit evidence automatically from the policy evaluation
results. Auditors receive a policy-by-policy compliance report with
timestamps and cluster names. Audit preparation time: reduced from 2
weeks to 2 days."

---

### ⚠️ Common Misconceptions

**Misconception: "Policy as Code eliminates the need for security review."**

Policy as Code automates the enforcement of known policies. It does not
discover new threats or evaluate architectural security decisions that
require human judgment. Security reviews are still necessary for new
system designs, data handling decisions, and threat modeling. Policy as
Code handles the "we know this is wrong" category; human review handles
the "is this the right design?" category.

**Misconception: "OPA Gatekeeper and Kyverno are interchangeable."**

Both are CNCF-graduated Kubernetes admission controllers, but they have
different policy expression models. OPA Gatekeeper uses Rego: expressive,
testable, but requires learning a new language. Kyverno uses Kubernetes-
native YAML: lower barrier, but less expressive for complex logic. For
most platform teams, Kyverno covers 90% of policy use cases with less
organizational friction. OPA is justified when you need complex policy
logic that YAML cannot express, or when you already have an OPA investment
(e.g., OPA used for authorization in other systems).

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: Admission webhook high availability failure**

Symptom: all pod scheduling fails across the entire cluster. kubectl
get events shows "failed to call webhook" errors. No new deployments,
no HPA scale-out, no recovery from spot node terminations.

Cause: OPA Gatekeeper or Kyverno pod crashed and the webhook is
configured with `failurePolicy: Fail` (reject all admission requests
if the webhook is unreachable). A single point of failure for the
entire cluster.

Diagnosis:
```bash
kubectl get pods -n gatekeeper-system
# or: kubectl get pods -n kyverno

kubectl describe validatingwebhookconfiguration gatekeeper-validating-webhook-configuration
# Look for: failurePolicy: Fail
# And: check webhook endpoint is reachable
```

Fix: scale policy controller to >= 3 replicas with PodDisruptionBudget;
set `failurePolicy: Ignore` for non-critical policies (production
critical: use `Fail`, but with HA guarantees).

**Failure mode: Policy blocks legitimate deployment**

Symptom: a product team's deployment fails with a policy violation
error. The deployment is valid and should be allowed.

Cause: policy is too broad or has an edge case that was not anticipated.

Diagnosis:
```bash
kubectl describe pod <pod-name> -n <namespace>
# Look for admission webhook rejection reason

# Or test a policy against a manifest without applying
kyverno apply policy.yaml --resource manifest.yaml
```

Fix: update the policy to allow the legitimate case. Follow the PR
review process: policy change requires review from both platform team
(operational impact) and security team (compliance impact).

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions minimum.

---

#### Q1 - How do you roll out new admission policies without breaking existing deployments?

The failure mode: deploy a new policy with `enforcementAction: deny`
and immediately break existing deployments in the cluster that violate
the policy.

**Safe rollout process:**

Phase 1 - Audit mode (no enforcement, 2-4 weeks):
Deploy the policy with `enforcementAction: audit` (Gatekeeper) or
`validationFailureAction: Audit` (Kyverno). This logs violations but
does not block them. Review the audit logs to understand scope.

```bash
# Check Gatekeeper audit results
kubectl get constraintpodstatuses -A | grep violation

# Check Kyverno audit results
kubectl get policyreports -A
```

Phase 2 - Notify violators: communicate the policy to teams with
existing violations. Provide the fix and a migration deadline.

Phase 3 - Warning mode (warnings but not blocking):
Kyverno supports `warn` mode which returns warnings without rejection.
Useful for gradual adoption.

Phase 4 - Enforce mode: switch to `enforcementAction: deny` / 
`validationFailureAction: Enforce`. At this point, all new deployments
are blocked if they violate the policy. Existing deployments that are
already running are not affected (policies apply at admission, not
retroactively to running pods).

*What separates good from great:* Phase 1 (audit mode) is the critical
step that most teams skip in their eagerness to enforce the policy. Skipping
it causes immediate production incidents. The audit-first approach reveals
the real scope of violations before enforcement and prevents the "we
enforced a new policy and 30 teams had CI failures" incident.

---

#### Q2 - How do you test admission policies before deploying to production?

Policy testing is not optional - incorrect policies break production
deployments and require immediate rollback.

**Testing stack:**

Unit tests (Rego/Kyverno):
```bash
# OPA/Conftest - test Rego policies
conftest test deployment.yaml --policy policies/

# Kyverno test
kyverno test policies/ --test-cases test-cases/

# Test case structure (Kyverno):
# Given: manifest that should be rejected
# Then: policy should produce violation
# And: violation message should contain "non-root"
```

Integration tests (in staging cluster):
- Deploy policy to staging with `audit` mode
- Apply known-bad manifests and verify violations are logged
- Apply known-good manifests and verify no violations
- Check that policy controller is healthy after deployment

CI/CD integration:
- Add `kyverno apply` or `conftest test` to CI pipeline
- Run policy tests on every PR that changes policy files
- Run manifest validation on every PR that changes application manifests
  (detect policy violations at PR time, before merge)

*What separates good from great:* Running manifest validation against
current policies in application team CI pipelines. When an application
team PRs a change to their deployment manifests, the CI pipeline runs
`kyverno apply policy.yaml --resource deployment.yaml` and fails the
PR if the manifest violates any policy. This moves policy violation
detection from "deployment failure" to "PR failure" - much earlier and
cheaper to fix.

---

#### Q3 - How do you manage policy exceptions?

Some legitimate deployments will violate security policies. An exception
process is necessary to handle these cases without eroding the policy.

**Exception management framework:**

Step 1 - Require documented justification: exceptions must have a written
justification explaining why the policy cannot be met and what compensating
controls exist.

Step 2 - Time-limited exceptions: exceptions should expire after 30-90
days. This forces periodic review and prevents exceptions from becoming
permanent.

Step 3 - Scoped exceptions: exceptions should be as narrow as possible
(specific namespace, specific workload, specific policy) rather than
broad exemptions.

In Kyverno: use namespace exceptions or resource annotations:
```yaml
# Namespace-level exception (for system namespaces)
apiVersion: kyverno.io/v2alpha1
kind: PolicyException
metadata:
  name: monitoring-exception
  namespace: monitoring
spec:
  exceptions:
  - policyName: require-non-root-containers
    ruleNames:
    - require-non-root
  match:
    any:
    - resources:
        kinds: [Pod]
        namespaces: [monitoring]
        names: [prometheus-*]
```

Step 4 - Exception inventory: maintain a registry of all active
exceptions with owner, justification, expiry date, and compensating
controls. Review quarterly.

*What separates good from great:* The exception process reveals the
policies that are too strict for the organizational context. When more
than 10% of workloads require exceptions for a specific policy, that
policy should be redesigned - either narrowed to apply only where it
makes sense, or the enforcement mechanism changed to allow legitimate
use cases without exceptions.

---

#### Q4 - How do you generate compliance evidence from policy as code?

Compliance evidence from policy as code is one of the most powerful
ROI arguments for the platform team. The evidence generation flow:

**Continuous compliance scanning:**
Both Kyverno (PolicyReport) and OPA Gatekeeper (audit mode) generate
structured reports of policy compliance status across all resources in
the cluster.

```bash
# Kyverno - get compliance status across all namespaces
kubectl get policyreports -A \
  -o custom-columns=\
  'NAMESPACE:.metadata.namespace,\
  PASS:.summary.pass,\
  FAIL:.summary.fail,\
  WARN:.summary.warn'

# Generate compliance evidence report
kubectl get policyreports -A -o json | \
  python3 generate_compliance_report.py \
  --output compliance-evidence-$(date +%Y%m%d).pdf
```

**Evidence categories for common frameworks:**

SOC2 Type II (CC6 - Logical and Physical Access):
- Policy: all containers run as non-root
- Evidence: Kyverno PolicyReport showing 0 violations across all
  production namespaces over the audit period

SOC2 Type II (CC8 - Change Management):
- Policy: all changes via GitOps (ArgoCD), no direct kubectl apply
- Evidence: ArgoCD audit logs + admission webhook logs showing all
  resource changes came from ArgoCD

ISO27001 (A.12.6 - Technical Vulnerability Management):
- Policy: containers use only approved base images from allowlist
- Evidence: Gatekeeper audit showing all production containers use
  approved registries

*What separates good from great:* Building the evidence generation into
the CI/CD pipeline so that compliance reports are generated automatically
on a schedule (e.g., weekly). The platform team does not assemble audit
evidence manually - the evidence is always current and available on
demand. This turns audit preparation from a 2-week manual effort into
pressing "generate report" in the platform dashboard.

---

#### Q5 - How do you handle policy drift between clusters?

In a multi-cluster environment, policy drift occurs when policies are
applied inconsistently across clusters - one cluster has a stricter
image registry policy than another, or a new policy is deployed to
production but not to staging.

**Preventing policy drift:**

GitOps single source of truth: all admission policies live in the
GitOps repository and are applied to all clusters by ArgoCD's
ApplicationSet. Adding a new policy to the repository automatically
deploys it to all clusters.

```yaml
# ArgoCD ApplicationSet - deploy policies to all clusters
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: platform-policies
spec:
  generators:
  - clusters: {}  # all clusters managed by this ArgoCD
  template:
    spec:
      source:
        repoURL: https://github.com/company/platform-policies
        path: policies/
      destination:
        server: "{{server}}"
        namespace: kyverno
```

**Detecting policy drift:**
```bash
# Compare policy status across clusters
for cluster in prod-1 prod-2 staging; do
  echo "Cluster: $cluster"
  kubectl --context=$cluster get clusterpolicies -o name
done
# Manual: compare output
# Automated: policy reconciliation job that alerts on drift
```

*What separates good from great:* Policy drift is the platform security
failure mode that is hardest to detect. A cluster that was not included
in the GitOps ApplicationSet scope silently lacks policies. The mitigation:
periodic cluster inventory checks that verify all clusters are in scope
of the GitOps policy deployment, and policy compliance dashboards that
show cluster-by-cluster compliance status.

---

#### Q6 - What is the difference between preventive and detective controls in policy as code?

Preventive controls (admission enforcement) block violations before they
occur. Detective controls (continuous compliance monitoring) detect
violations that already exist.

**Preventive controls (admission controllers):**
- OPA Gatekeeper with `enforcementAction: deny`
- Kyverno with `validationFailureAction: Enforce`
- Applied to new resource creation and updates
- Cannot retroactively fix existing violations

**Detective controls (continuous monitoring):**
- OPA Gatekeeper audit mode
- Kyverno PolicyReports (background scans)
- Falco (runtime security monitoring)
- Applied to existing resources on a schedule

Why both are needed:
Preventive controls are bypassed by: resources created before the policy
was deployed, resources updated via paths that bypass admission (direct
etcd writes - rare but possible in emergencies), and resources modified
by cluster administrators with admission bypass privileges.

Detective controls catch these gaps. The combination: preventive controls
handle the normal path, detective controls catch the edge cases and
provide continuous audit evidence.

*What separates good from great:* Understanding that in a production
cluster with 3+ years of history, some resources predate the current
policies. Detective controls find these resources. The platform team
should run detective controls from day 1 and address violations as they
are discovered, not just enforce policies on new deployments.

---

#### Q7 - How do you design policies for a multi-tenant platform with different compliance requirements?

Multi-tenant platforms have tenants with different compliance requirements:
a team handling PCI card data needs stricter policies than a team building
internal dashboards.

**Approach: policy tiers with namespace labels**

```yaml
# Namespace tiers
# Standard: base security policies
metadata:
  labels:
    platform.company.com/compliance-tier: standard

# Restricted: PCI/HIPAA requirements
metadata:
  labels:
    platform.company.com/compliance-tier: restricted

# Kyverno policy: apply stricter policies to restricted tier
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restricted-no-hostpath
spec:
  validationFailureAction: Enforce
  rules:
  - name: no-hostpath-in-restricted
    match:
      any:
      - resources:
          kinds: [Pod]
          namespaceSelector:
            matchLabels:
              platform.company.com/compliance-tier: restricted
    validate:
      message: "hostPath volumes are not allowed in restricted namespaces"
      deny:
        conditions:
          any:
          - key: "{{ request.object.spec.volumes[].hostPath | length(@) }}"
            operator: GreaterThan
            value: "0"
```

**Policy inheritance pattern:**
- Base policies: applied to all namespaces (all tenants)
- Standard policies: applied to standard and restricted namespaces
- Restricted policies: applied only to restricted namespaces

This builds a policy hierarchy where each tier inherits the policies
of the tiers below it.

*What separates good from great:* The compliance tier label on namespaces
is also useful as audit metadata - it tags which namespace is in scope
for which compliance framework. Compliance reports can be generated per
tier, showing PCI-scoped namespaces separately from standard namespaces.
This maps directly to what auditors need when they ask for evidence
for PCI compliance specifically.

---

#### Q8 - How do you integrate policy as code with shift-left security?

Shift-left security means detecting policy violations as early in the
development lifecycle as possible - at code review time, not at deployment
time.

**Shift-left integration:**

IDE integration (VSCode + kubectl-validate plugin):
Developers see policy violations as they write Kubernetes YAML, before
committing.

Pre-commit hooks:
```bash
# .pre-commit-config.yaml
repos:
- repo: local
  hooks:
  - id: kyverno-validate
    name: Kyverno Policy Validation
    language: script
    entry: scripts/validate-manifests.sh
    files: \.yaml$
    # Runs: kyverno apply policies/ --resource $file
    # Fails commit if policy violations found
```

CI/CD integration (PR-time validation):
```yaml
# GitHub Actions workflow
- name: Validate Kubernetes manifests
  uses: kyverno/action-cli@v0.1
  with:
    command: apply
    policy: policies/
    resource: manifests/
    fail: true  # fail the CI job on policy violations
```

GitOps PR review:
When a product team PRs a change to their application manifests in the
GitOps repository, the CI pipeline validates the manifests against all
platform policies. Policy violations fail the PR before merge.

*What separates good from great:* Shift-left security changes the
conversation from "your deployment was blocked in production, please fix
it" to "your PR has a policy violation, please fix it before merge."
The production incident is eliminated. The developer gets faster feedback
at the point where fixing is cheapest. The adoption barrier for shift-left:
developers must have the right tools in their IDE and CI - the platform
team must actively set these up, not leave them as optional.

---

#### Q9 - What is Open Policy Agent (OPA) and how does it fit in platform engineering?

OPA is a general-purpose policy engine - it evaluates policies written
in Rego (a declarative query language) against arbitrary JSON/YAML data
and returns policy decisions.

In platform engineering, OPA appears in multiple contexts:

**OPA Gatekeeper (admission control):**
OPA as a Kubernetes admission webhook. Evaluates Kubernetes resources
against Rego policies at admission time. CNCF Graduated.

**OPA for authorization:**
Beyond Kubernetes admission, OPA can be used for API authorization
(who can call which API endpoint), data access control (which data
can this service access), and multi-cloud policy enforcement.

**Conftest (CI/CD policy testing):**
Uses OPA/Rego to validate configuration files (Kubernetes manifests,
Terraform plans, Helm charts, Dockerfile) in CI pipelines, before any
resource is deployed.

```rego
# Conftest policy: validate Terraform plan
# Prevents provisioning unencrypted S3 buckets
package terraform.s3

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.server_side_encryption_configuration
  msg := sprintf(
    "S3 bucket %v must have server-side encryption enabled",
    [resource.name]
  )
}
```

**The platform engineering value of OPA:**
OPA can enforce policies across all infrastructure layers - not just
Kubernetes. A unified OPA policy store can enforce the same data
residency policy in Kubernetes admission, Terraform provisioning,
and API authorization. This "policy everywhere" approach is the mature
evolution of platform security.

*What separates good from great:* Understanding that OPA's value is
not limited to Kubernetes. Organizations that use OPA only for Gatekeeper
are underutilizing it. The full value: a unified policy language (Rego)
applied at every system boundary where policy decisions are made.

---

### ⚖️ Comparison Table

| Approach | When Violations Detected | Enforcement | Compliance Evidence | Complexity |
|---|---|---|---|---|
| Policy documents | After production incident | None (honor system) | Manual audit trail | Low |
| Code review checklist | At PR review (if reviewed) | Peer pressure | Manual | Low |
| Admission controller (Kyverno/OPA) | At deployment time | Automatic rejection | Automated (PolicyReports) | Medium |
| Shift-left (CI/CD + admission) | At PR time and deployment | Automatic at both stages | Automated | High |

**The deciding factor:**
Admission controller enforcement is the minimum viable security posture
for a production Kubernetes platform. Shift-left integration reduces
developer friction by moving violations from "deployment failure" to
"PR failure."

---

---

# Platform Security Model and Supply Chain

---
id: PE-020
title: Platform Security Model and Supply Chain
category: Platform Engineering
difficulty: ★★☆
interview_weight: critical
seniority: senior
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> A platform security model defines the trust boundaries, attack surfaces,
> and security controls of the internal developer platform. Supply chain
> security focuses on the integrity of the artifacts that flow through the
> platform: container images, Helm charts, and Terraform modules. At
> minimum: sign all platform artifacts, enforce signature verification at
> deployment time, and never allow unverified external dependencies to
> reach production.

**3 minutes (Senior):**
> Platform security has two distinct problems. The platform's own security
> posture: who can access what in the platform, how is the platform's
> control plane secured, and what is the blast radius of a platform
> compromise. And supply chain security: the integrity of artifacts that
> flow through the platform from source to production.
>
> The platform's own security posture is about trust boundaries. The
> platform has elevated privileges - the platform team can modify cluster-
> wide configurations, install admission webhooks, and access all namespaces.
> This privilege must be protected: MFA for platform engineer access,
> audit logging for all cluster-admin operations, segregation of duties
> (platform engineers cannot approve their own changes to production), and
> break-glass procedures for emergency access that trigger alerting.
>
> Supply chain security in a Kubernetes-based platform addresses the
> question: how do you know that the container image deployed in production
> is the same image that passed CI/CD security scanning? The answer is
> artifact signing and verification. Every container image signed with
> Cosign (using the organization's signing key). The platform's admission
> policy (via Kyverno or Gatekeeper) verifies the signature before allowing
> any image to be scheduled. An unsigned image never reaches production,
> even if someone has Kubernetes credentials to deploy it.

**Framework:** PLATFORM TRUST BOUNDARIES -> ARTIFACT SIGNING ->
SIGNATURE VERIFICATION -> RUNTIME SECURITY

*Adapting up:* Staff adds: "Supply chain security in 2024 is no longer
optional. The SolarWinds and Log4Shell incidents demonstrated that
compromised build pipelines and dependencies can affect thousands of
organizations. SLSA (Supply-chain Levels for Software Artifacts) is the
framework I use to evaluate supply chain posture: SLSA Level 1 (source
control), Level 2 (CI/CD build provenance), Level 3 (hermetic build,
non-falsifiable provenance), Level 4 (two-party review, hermetic). Most
organizations are at Level 1-2; Level 3+ is the target for critical
platform components."

*Adapting down:* Junior: "Platform security is about making sure only the
right people can change the platform, and supply chain security is about
making sure the container images running in production are the ones that
were built and scanned in CI - not something tampered with after build.
Cosign is a tool that signs container images with a cryptographic signature
that Kubernetes can verify before scheduling the container."

**Blank Mind Recovery:**

**(1) Restate:** "Platform Security Model and Supply Chain - securing the
platform itself and the artifacts that flow through it."

**(2) First principles:** "Security is about trust: who do you trust, what
do you trust them with, and how do you verify that trust? The platform
security model defines these trust boundaries explicitly."

**(3) Bridge:** "Supply chain security is like a chain of custody for
digital artifacts. A signed package with a verified signature proves the
package came from the trusted publisher and wasn't modified in transit
or at rest."

---

### 📘 Concept Explanation

**What it is:**
Platform security model defines the trust boundaries, access controls,
and security controls that protect the platform's own infrastructure.
Supply chain security (SSCS) addresses the integrity of software
artifacts (container images, Helm charts, Terraform modules) from
source to production, using signing, verification, and provenance
attestation.

**The problem it solves:**
Platforms have elevated privileges - they manage clusters, install
admission webhooks, provision cloud resources. A compromised platform
is a compromised platform for ALL teams using it. Supply chain attacks
(SolarWinds, Log4Shell) demonstrated that attackers target build pipelines
and dependencies rather than application code directly. Platform security
and supply chain security together address these elevated risk surfaces.

**How it works:**

```
PLATFORM SECURITY ARCHITECTURE

TRUST BOUNDARIES:

External world
  |
  v
[Source Control]    --> audit trail of all code changes
  |
  v
[CI/CD Pipeline]    --> builds, scans, signs artifacts
  |                     (controlled environment - no external network)
  v
[Artifact Registry] --> stores signed images + attestations
  |
  v
[Kubernetes API]    --> admission controllers verify signatures
  |
  v
[Production pods]   --> only signed, scanned images run here

ACCESS CONTROLS:

Platform Engineer access:
  - MFA required for all cluster access
  - Just-in-time (JIT) access for production cluster-admin
  - All cluster-admin operations audited to immutable log
  - No shared service accounts - each engineer has individual credentials

Platform team CI/CD access:
  - GitOps (ArgoCD) as the only deployment path to production
  - Service accounts with minimum required permissions
  - No permanent cluster-admin credentials in CI/CD pipelines

Break-glass access:
  - Emergency cluster-admin credentials in sealed secret management
  - Access triggers real-time alerting to security team
  - All actions audited; post-incident review required

SUPPLY CHAIN SECURITY:

1. BUILD (CI/CD):
   Source commit
   --> Docker build (pinned base images)
   --> Vulnerability scan (Trivy, Grype)
   --> Fail if critical/high CVEs found
   --> Sign image with Cosign (keyless or key-based)
   --> Generate SBOM (Software Bill of Materials)
   --> Attach attestation to image

2. STORE (Registry):
   Signed image pushed to OCI registry
   Registry enforces: only signed images accepted
   Image retention policy: keep last N builds per branch

3. DEPLOY (Admission control):
   Team applies Deployment YAML
   --> Kyverno policy verifies image signature
   --> Verifies SBOM attestation is present
   --> Verifies vulnerability scan passed
   --> ALLOW if all verifications pass
   --> DENY if any verification fails

4. RUNTIME (Falco):
   Running pod
   --> Falco monitors syscalls
   --> Alert: unexpected network connection from container
   --> Alert: container executing shell (/bin/sh)
   --> Alert: container writing to /etc
```

**The key insight:**
Supply chain security is a chain - it is only as strong as its weakest
link. Signing images in CI is useless if the registry allows unsigned
image pushes (attackers bypass CI). Signature verification at admission
is useless if someone can apply patches to the Kyverno policies themselves.
The chain must be complete: controlled builds, protected registry, verified
deployment, monitored runtime.

**When to implement:**
From the first production deployment. Supply chain security that is
retrofitted to an existing platform is significantly harder than built-in
from the start.

---

### 💻 Code Example

**Example 1: BAD vs GOOD - no supply chain security vs. Cosign signing**

```bash
# BAD: no supply chain security
# Anyone with push access to the registry can push
# any image with any name:tag
docker build -t registry.company.com/payments-api:v1 .
docker push registry.company.com/payments-api:v1
# No verification: attacker can push
# registry.company.com/payments-api:v1 with malicious code
# after CI, before deployment. No one would know.
```

```bash
# GOOD: Cosign keyless signing in CI/CD
# Step 1: build and push image
docker build -t registry.company.com/payments-api:v1 .
docker push registry.company.com/payments-api:v1

# Step 2: sign with Cosign (keyless using OIDC - no key management)
# Runs in CI/CD with OIDC token from GitHub Actions / Tekton
cosign sign \
  --yes \
  registry.company.com/payments-api:v1

# Step 3: attach SBOM attestation
syft registry.company.com/payments-api:v1 \
  -o cyclonedx-json | \
cosign attest \
  --yes \
  --predicate /dev/stdin \
  --type cyclonedx \
  registry.company.com/payments-api:v1

# Step 4: Kyverno policy verifies signature before scheduling
```

```yaml
# Kyverno ClusterPolicy: verify image signature
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-image-signature
    match:
      any:
      - resources:
          kinds: [Pod]
          namespaceSelector:
            matchLabels:
              environment: production
    verifyImages:
    - imageReferences:
      - "registry.company.com/*"
      attestors:
      - entries:
        - keyless:
            subject: "https://github.com/company/*"
            issuer: "https://token.actions.githubusercontent.com"
      attestations:
      - predicateType: "https://cyclonedx.org/bom"
        attestors:
        - entries:
          - keyless:
              subject: "https://github.com/company/*"
              issuer: "https://token.actions.githubusercontent.com"
```

> **Code walkthrough:** The BAD pattern relies on access controls to the
> registry as the only security mechanism - if the registry is compromised
> or a credential is leaked, an attacker can push arbitrary images. The
> GOOD pattern uses Cosign keyless signing: the CI/CD pipeline signs the
> image with an OIDC token tied to the specific GitHub Actions workflow
> that built it. The Kyverno policy verifies that signature before
> scheduling any production pod. An attacker who somehow pushes an unsigned
> image to the registry still cannot deploy it - the admission controller
> rejects it. The supply chain attack surface is reduced to: compromise
> the GitHub Actions workflow itself (much harder than compromising registry
> credentials).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Platform security is about protecting the platform itself and the
> software that runs on it. Supply chain security is specifically about
> ensuring that container images in production are the exact same images
> that were built and scanned in CI - not tampered with afterward. Cosign
> is a tool that signs container images with a cryptographic signature,
> and Kyverno can verify that signature before allowing the image to run
> in Kubernetes. Without this, an attacker who compromises a container
> registry could push a malicious image with the right name and tag and
> have it deployed to production.

*Push deeper:* "The SolarWinds attack is the canonical example of supply
chain attack: attackers compromised the build pipeline, not the application
code, and added malicious code that passed through code review and was
deployed by thousands of customers. Supply chain security (SLSA framework)
is the response to this class of attack."

---

**Senior / Staff (5+ years):**
> Platform security has two dimensions that are often conflated. The
> platform's own security posture - who has access to the cluster, how
> is cluster-admin access managed, what is the blast radius of a platform
> team member going rogue or being compromised - this requires just-in-
> time access, audit logging, and GitOps as the only deployment path
> to production.
>
> Supply chain security - are the artifacts flowing through the platform
> the ones we intended to deploy? - this requires Cosign signing in CI,
> SBOM generation, signature verification at admission. The SLSA framework
> provides a maturity model: Level 1 is source control, Level 3 is
> hermetic builds with non-falsifiable provenance. Most organizations are
> at Level 2 (build process is auditable). Getting to Level 3 requires
> hermetic builds (no external network access during build) - a non-trivial
> operational change.

*Push deeper:* "At Staff level: the supply chain security conversation
extends to dependencies. SBOM (Software Bill of Materials) generated from
every build lets you answer 'are we affected by Log4Shell?' in minutes
instead of days. You run a query against your SBOM store: which services
have log4j in their dependency tree, and what version? This is the
production value of SBOMs beyond compliance."

---

### ⚠️ Common Misconceptions

**Misconception: "Image scanning for vulnerabilities is sufficient supply
chain security."**

Vulnerability scanning (Trivy, Grype) detects known CVEs in container
image layers. It does not detect: supply chain attacks (malicious code
injected into the build process), image tampering after build (someone
pushes a malicious image with the same name:tag), or dependency confusion
attacks (malicious package with the same name as an internal package).
Cosign signing + SBOM addresses tampering; dependency scanning + hermetic
builds address injection.

**Misconception: "RBAC is the primary security mechanism for the platform."**

RBAC prevents unauthorized users from performing actions via the Kubernetes
API. It does not prevent: compromised service account credentials used
by attackers, lateral movement within a namespace (pod-to-pod network
traffic), supply chain attacks (malicious image deployed by legitimate
credentials), and container escape to the node (which bypasses RBAC
entirely). RBAC is necessary but not sufficient - it must be combined
with NetworkPolicies, PodSecurityStandards, supply chain verification,
and runtime monitoring.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: Supply chain attack via compromised registry credentials**

Symptom: production workload shows anomalous behavior (unusual network
connections, unexpected processes running). Container image hash does not
match the hash built in CI.

Cause: attacker used leaked registry credentials to push a malicious image
with the expected name:tag, replacing the legitimate image. Or attacker
modified the image after CI signed it (signature verification gap).

Diagnosis:
```bash
# Verify image signature for a running pod
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'
# Get image reference

cosign verify \
  --certificate-identity "https://github.com/company/payments-api/*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  registry.company.com/payments-api:v1
# FAIL if signature is missing or invalid -> image was tampered
```

Prevention: Kyverno admission policy that verifies Cosign signature
before scheduling any production pod. If the policy is in place,
a tampered unsigned image is never scheduled.

**Failure mode: Overly permissive platform team RBAC**

Symptom: during a security audit, auditor discovers that multiple
engineers have permanent cluster-admin access and that there is no
audit trail of who made what changes.

Cause: platform team grew quickly without formalizing access controls.
"We trust each other" is the access control model.

Diagnosis: `kubectl get clusterrolebindings | grep cluster-admin`
to list all cluster-admin role bindings.

Fix: implement just-in-time cluster-admin access (Teleport, Boundary,
or kubectl access proxy with OIDC + time-limited tokens). All cluster-admin
actions audit-logged to immutable storage. No permanent cluster-admin
credentials for human users.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions minimum.

---

#### Q1 - What is SLSA and how does it apply to platform engineering?

SLSA (Supply-chain Levels for Software Artifacts, pronounced "salsa") is
a security framework developed by Google for classifying and improving
supply chain security posture. It defines 4 levels:

**SLSA Level 1 (Provenance):** the build process is documented and produces
a signed provenance document stating what inputs produced what output.
Minimum viable supply chain security. Most CI/CD systems can achieve this.

**SLSA Level 2 (Hosted Build):** the build is run on a hosted service
(GitHub Actions, Cloud Build) that provides a stronger audit trail and
prevents the developer from modifying the build process. The provenance
is signed by the hosted service.

**SLSA Level 3 (Hardened Build):** the build is hermetic (no external
network access during build), the build service is hardened against
tampering, and the provenance cannot be forged. This prevents dependency
confusion attacks (fetching malicious external packages during build).

**SLSA Level 4 (Two-party review):** source code changes require review
and approval by at least two authorized parties. Prevents a single
compromised developer from shipping malicious code.

Platform engineering application:
- Platform's own components (CI/CD tooling, admission controllers): target SLSA 3
- Golden path Helm charts and Crossplane Compositions: target SLSA 2
- Application builds: enforce SLSA 1 (provenance required), incentivize SLSA 2-3

*What separates good from great:* Knowing that SLSA Level 3 (hermetic builds)
is a significant operational change. Hermetic builds require a build
environment with no external network access - all dependencies must be
pre-fetched and available in the build environment. Many organizations
treat this as aspirational and operate at Level 2.

---

#### Q2 - How do you implement least privilege for CI/CD service accounts?

CI/CD service accounts are high-value targets because they have deployment
access. Implementing least privilege:

**Principle: the CI/CD service account should have exactly the permissions
needed for deployment, nothing more.**

For a GitOps-based platform (ArgoCD), the CI/CD pipeline only pushes
to git - it never directly creates Kubernetes resources. The service
account needed: write access to the specific git repository paths that
contain manifests. No Kubernetes credentials required in the pipeline.

```yaml
# ArgoCD service account for a product team's CI/CD
# has write access only to the team's manifest path in git
# ArgoCD service account in Kubernetes has ONLY:
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-application-sync
  namespace: team-payments
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Notably absent: create/delete Namespaces, ClusterRoles,
#                 or any cluster-wide resources
```

For pipelines that require Kubernetes access (not pure GitOps):
- Use Workload Identity (GKE) or IRSA (EKS) instead of stored secrets
- Service accounts are namespace-scoped (not ClusterRole)
- Secrets access: only the specific secrets the pipeline needs (not
  wildcard secret read access)

*What separates good from great:* The GitOps model where CI/CD pipelines
only push to git - never to Kubernetes directly - is the cleanest least-
privilege model for CI/CD. The pipeline has no Kubernetes credentials at
all. ArgoCD reconciles git to cluster. The blast radius of a CI/CD
credential compromise: only the git repository, not Kubernetes.

---

#### Q3 - How do you secure the platform control plane?

The platform control plane includes: Kubernetes API server, etcd,
admission controllers (Gatekeeper, Kyverno), ArgoCD, Vault/secret
management, and the container registry. Securing the control plane:

**API server access:**
- MFA required for all access (cloud provider identity: Google/AWS/Azure)
- Kubernetes audit logging enabled (capture all API server requests)
- Audit logs shipped to immutable storage (attacker cannot delete them)
- kubectl access via OIDC (no permanent kubeconfig credentials)

**etcd security:**
- Encryption at rest enabled (stores all cluster secrets and config)
- Access limited to API server (no direct etcd access for engineers)
- Regular backups with tested restore procedure

**Admission controllers:**
- Gatekeeper/Kyverno with >= 3 replicas and PodDisruptionBudget
- No direct modification of admission controller policies without GitOps PR
- Admission webhook TLS certificates automatically rotated (cert-manager)

**ArgoCD security:**
- ArgoCD admin credentials in Vault (not in etcd)
- SSO-only login for engineers (no local admin passwords)
- ArgoCD projects restrict which git repositories each AppProject can deploy from
- ArgoCD notifications for all sync operations (audit trail)

*What separates good from great:* The hardest-to-detect attack on the
platform control plane is a slow privilege escalation. An attacker with
low-privilege access gradually acquires higher privileges over time.
Continuous audit log analysis (SIEM integration with alerting for
unusual privilege escalation patterns) is the detective control for this
attack class.

---

#### Q4 - How do you handle secrets management in a platform security model?

Secrets management in a platform security model must answer: how are
secrets stored, how do workloads access them, and how are they rotated?

**Platform secrets management architecture:**

Secrets store: HashiCorp Vault (enterprise or open-source) or cloud-native
secret stores (AWS Secrets Manager, GCP Secret Manager). Never Kubernetes
Secrets as the primary store (base64-encoded, etcd-stored, accessible to
anyone with kubectl get secret).

Workload access pattern: External Secrets Operator (ESO) syncs from Vault
to Kubernetes Secrets, per namespace, on a refresh interval. Workloads
consume Kubernetes Secrets (normal pattern). ESO manages the rotation and
sync automatically.

```yaml
# External Secrets Operator - sync from Vault to namespace
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: team-payments
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-cluster-store
    kind: ClusterSecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: payments/database
      property: password
```

Rotation: Vault supports automatic rotation for database credentials
(Vault Dynamic Secrets). Each time a pod starts, it gets a new temporary
database credential. Credentials expire when the pod's Vault lease expires.
No long-lived database passwords.

*What separates good from great:* Vault Dynamic Secrets for database
credentials is the gold standard. Instead of a static password stored
in a Secret, each service gets a short-lived Vault-managed database
credential that is automatically rotated. The blast radius of a leaked
credential: minimal, because it expires after the configured TTL. Most
organizations are still using static passwords - dynamic secrets is an
advanced platform capability that dramatically reduces secret compromise
blast radius.

---

#### Q5 - What is Falco and how does it fit in the platform security model?

Falco is a cloud-native runtime security tool that monitors Linux syscalls
and Kubernetes audit events to detect anomalous behavior in running
containers.

Falco sits at the runtime security layer of the platform security model.
While admission controllers prevent bad configurations from being deployed,
Falco detects bad behavior at runtime - a container that is already running
but doing something unexpected.

**Common Falco rules:**
```yaml
# Falco rule: shell spawned in container
- rule: Terminal shell in container
  desc: Shell opened in container
  condition: >
    spawned_process and container and
    shell_procs and
    proc.tty != 0
  output: >
    Shell spawned in a container (user=%user.name ...
    container=%container.id image=%container.image.repository)
  priority: WARNING

# Falco rule: unexpected outbound network connection
- rule: Unexpected outbound connection
  desc: Container made unexpected outbound connection
  condition: >
    outbound and container and
    not (fd.sport in (80 443 8080 8443))
  output: >
    Unexpected outbound connection from container ...
  priority: WARNING
```

Falco alerts can be sent to: Slack, PagerDuty, Elasticsearch (SIEM),
or a custom webhook for the platform team's incident response.

**Where Falco fits:**
- Admission controllers: prevent bad configurations (preventive)
- Falco: detect bad runtime behavior (detective/responsive)
- Together they provide defense in depth: even if a misconfiguration
  reaches production, Falco detects the anomalous behavior it causes

*What separates good from great:* Falco generates high volumes of
alerts that require tuning to be useful. Out-of-the-box Falco rules
have many false positives in real Kubernetes clusters. The operational
work: tune Falco rules to the baseline behavior of your workloads, then
alert only on genuine deviations from that baseline. Untruned Falco =
alert fatigue = ignored alerts.

---

#### Q6 - How do you respond to a detected supply chain attack?

A supply chain attack in progress: Falco detects that a container is
making unexpected outbound connections to an external IP. Investigation
reveals the container image was not built from the expected source.

**Incident response steps:**

Step 1 - Contain immediately:
```bash
# Scale down the compromised deployment
kubectl scale deployment payments-api --replicas=0 \
  -n team-payments

# Block all network egress from the affected namespace
kubectl apply -f block-all-egress-networkpolicy.yaml \
  -n team-payments
```

Step 2 - Preserve forensics:
```bash
# Capture container state before termination
kubectl exec -n team-payments <pod> -- \
  tar -czf /tmp/forensics.tar.gz /proc /tmp
kubectl cp team-payments/<pod>:/tmp/forensics.tar.gz \
  ./forensics.tar.gz

# Preserve Kubernetes audit logs
kubectl get events -n team-payments \
  --sort-by=.lastTimestamp > events-at-incident.txt
```

Step 3 - Verify image integrity:
```bash
cosign verify \
  --certificate-identity "https://github.com/company/*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  registry.company.com/payments-api:v1.2.3
# Expected result: FAIL (signature missing or invalid)
# Confirms: image was tampered after CI build
```

Step 4 - Root cause analysis:
- When was the malicious image pushed to the registry?
- Who had registry push credentials?
- Was the signing key compromised?

Step 5 - Remediate and harden:
- Revoke compromised credentials
- Rotate signing key if compromised
- Enable Kyverno signature verification if not already enforced
- Conduct incident review and update admission policies

*What separates good from great:* Having a pre-documented incident
response runbook for supply chain attacks so that the first 30 minutes
are not spent on "what do we do?" but on "follow the runbook." Incident
response time-to-contain is measured in minutes for teams with runbooks,
hours for teams without.

---

#### Q7 - What is SBOM and why does it matter for platform security?

SBOM (Software Bill of Materials) is a structured list of all components
(packages, libraries, dependencies) included in a software artifact,
with their versions and known vulnerabilities.

In platform engineering, SBOMs serve three purposes:

**Vulnerability response:** when a critical CVE is disclosed (Log4Shell,
Spring4Shell), you need to know which of your services are affected.
Without SBOMs: scan every container image manually - takes days. With
SBOMs stored per image: query the SBOM store - takes minutes.

```bash
# Query SBOM store for Log4j presence
# Using grype to query from cosign-attached SBOM
cosign verify-attestation \
  --type cyclonedx \
  registry.company.com/payments-api:v1.2.3 | \
  jq '.payload | @base64d | fromjson' | \
  jq '.components[] | select(.name == "log4j-core")'
```

**Compliance evidence:** SOC2, PCI DSS, and emerging regulations (US
Executive Order 14028) require software bills of materials for software
used in certain contexts. SBOM generation in CI satisfies this requirement
automatically.

**License compliance:** SBOMs reveal the open-source licenses of all
dependencies. Legal teams use this to identify GPL-licensed dependencies
in commercial software (potential license compliance issue).

SBOM generation tools: Syft (CNCF, generates CycloneDX or SPDX), Trivy
(also generates SBOMs alongside vulnerability scanning).

*What separates good from great:* The practical value of SBOMs is most
apparent during a CVE emergency. Organizations with SBOMs answer "are
we affected by X?" in minutes. Organizations without SBOMs spend days
scanning every running container. Having been through a CVE emergency
with and without SBOMs is the experience that makes the value visceral.

---

#### Q8 - How do you establish a security baseline for a new Kubernetes cluster?

A security baseline for a new cluster establishes the minimum security
posture before any workloads are deployed.

**Cluster security baseline checklist:**

Infrastructure level:
- Kubernetes version: within N-1 of latest (no unsupported versions)
- API server: audit logging enabled, audit log retention >= 90 days
- etcd: encryption at rest enabled
- Node OS: hardened (CIS benchmark level 1), minimal packages
- Container runtime: containerd (not Docker), no privileged runtime access

Network level:
- NetworkPolicy CNI support: Calico or Cilium (not Flannel)
- Default deny NetworkPolicy applied to all non-system namespaces
- No NodePort services exposed externally (use LoadBalancer or Ingress)
- API server private endpoint (not publicly accessible)

Kubernetes API level:
- PodSecurityAdmission enabled with `restricted` as default for all
  non-system namespaces
- Admission controllers deployed: Gatekeeper or Kyverno with base policies
- RBAC: no wildcard permissions, no `cluster-admin` for non-platform roles
- ServiceAccount tokens: projected service account tokens (bound, short-lived)

Platform level:
- Secret management: External Secrets Operator + Vault integration
- Image registry: only approved registries allowed (admission policy)
- Image signing: Cosign verification policy enabled
- Runtime security: Falco deployed

*What separates good from great:* Having this checklist as code (a
Kubernetes cluster bootstrap automation, not a manual checklist) and
validating it with automated checks (kube-bench for CIS compliance,
Kyverno policy audit for admission control gaps). A cluster that cannot
be provisioned with the security baseline in < 1 hour is a cluster
that will be manually hardened inconsistently.

---

#### Q9 - Describe a platform security incident you have experienced or observed.

*Open question probing real-world experience. A strong answer:*

Context: a production Kubernetes cluster had an admission webhook
(OPA Gatekeeper) that was configured with `failurePolicy: Fail`. The
Gatekeeper deployment had only 1 replica and no PodDisruptionBudget.
During a cluster upgrade, the Gatekeeper pod was evicted for node
maintenance. For approximately 8 minutes, all pod admission requests
failed - HPA could not scale up, rolling deployments were blocked,
and spot nodes that were terminated could not be replaced.

Security implication: the admission webhook was not just a reliability
component - it was the primary security control preventing policy
violations. During those 8 minutes, any deployment would have bypassed
all admission policies.

Detection: Prometheus alert on kube_pod_status_ready for gatekeeper-system
namespace. The alert fired 90 seconds after the pod was evicted.

Remediation: scaled Gatekeeper to 3 replicas, added PodDisruptionBudget
allowing 0 disruptions, added a cluster-level alert for admission webhook
health.

Long-term fix: evaluated switching `failurePolicy` from `Fail` to `Ignore`
for non-critical policies, and ensuring that `Fail` mode is only used for
policies where bypassing the control is a security violation (not just
an operational policy).

Lesson: admission webhooks with `failurePolicy: Fail` are security controls.
They must be operated with the same HA requirements as production services.
A single-replica admission webhook is a single point of failure for both
reliability and security.

*What separates good from great:* Describing both the reliability impact
and the security impact of the incident. Admission webhook failures are
often treated as reliability incidents (deployments failing), but they
are also security incidents (policies bypassed). The dual nature of
admission webhooks - reliability component AND security control - is the
insight this question is probing for.

---

### ⚖️ Comparison Table

| Security Layer | What It Prevents | What It Does NOT Prevent | Tool(s) |
|---|---|---|---|
| RBAC | Unauthorized API operations | Compromised credentials, container escape | Kubernetes RBAC |
| NetworkPolicy | Lateral network movement | Node-level network (hostNetwork) | Calico, Cilium |
| PodSecurityStandards | Privilege escalation via pod spec | Runtime behavior of allowed pods | Kubernetes PSA |
| Admission policies (Gatekeeper/Kyverno) | Misconfigured deployments | Post-admission runtime behavior | OPA, Kyverno |
| Image signing (Cosign) | Tampered images reaching production | Vulnerabilities in original image | Cosign + Rekor |
| Vulnerability scanning (Trivy) | Known CVEs in container images | Zero-days, supply chain injection | Trivy, Grype |
| Runtime security (Falco) | Detected anomalous runtime behavior | Prevention (only detection) | Falco |

**The deciding factor:**
Defense in depth requires all layers. A security posture that has only
RBAC + Admission policies but no supply chain verification + runtime
monitoring has significant gaps at the post-deployment layer.
