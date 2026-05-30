---
layout: default
title: "Platform Engineering - L3 Platform Design Decisions"
parent: "Platform Engineering"
nav_order: 9
permalink: /platform-engineering/l3-platform-design-decisions/
render_with_liquid: false
---

# Platform Engineering - L3 Platform Design Decisions

## Keywords in This File

| # | Keyword | Weight |
|---|---|---|
| 1 | [Build vs Buy Platform Decisions](#build-vs-buy-platform-decisions) | critical |
| 2 | [Platform API Design and Contracts](#platform-api-design-and-contracts) | high |

---

# Build vs Buy Platform Decisions

---
id: PE-017
title: Build vs Buy Platform Decisions
category: Platform Engineering
difficulty: ★★☆
interview_weight: critical
seniority: senior
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Build vs Buy for platform engineering is a total cost of ownership
> decision, not a capability decision. You build when no open-source or
> commercial option fits your operational constraints, or when the platform
> capability is a genuine competitive differentiator. You buy (adopt open
> source or commercial) for everything else. The default should be buy -
> the burden of proof is on building.

**3 minutes (Senior):**
> The build vs buy decision in platform engineering is poorly framed when
> it focuses on features. The right framing is: what is the total cost of
> ownership (TCO) of each option, and does the delta justify building?
>
> Build costs are systematically underestimated. The initial build is
> typically 20-30% of the total lifetime cost. The remaining 70-80% is:
> maintenance (security patches, dependency upgrades), operational support
> (on-call, incident response), documentation, user training, and feature
> iteration to match the roadmap of the open-source alternatives you chose
> not to use. Building a custom CI/CD system instead of adopting GitHub
> Actions or Tekton means you are now maintaining a CI/CD system in
> perpetuity alongside your actual platform work.
>
> The open-source alternative to "buy" is "adopt with contributions."
> Most platform tooling (ArgoCD, Backstage, Crossplane, Tekton) is open
> source and free to use. The cost is not license fees but integration
> effort, upgrade management, and occasionally contributing fixes upstream.
> This is almost always lower cost than building from scratch.
>
> The cases where building is justified: (1) no existing tool meets the
> operational constraints (performance, security, regulatory requirements),
> (2) the platform capability is a genuine competitive differentiator
> that justifies engineering investment as a core product (rare in platform
> engineering), (3) the organizational context makes adoption of external
> tooling impossible (air-gapped environments, regulatory restrictions on
> external dependencies).

**Framework:** ADOPT OPEN SOURCE (default) ->
EXTEND WITH CONTRIBUTION -> BUILD CUSTOM (last resort)

*Adapting up:* Staff adds: "The hidden cost of build is talent: when you
build a custom platform component, you need engineers who understand it
deeply for on-call and incident response. When that engineer leaves, the
knowledge leaves with them. Open-source tools have documentation,
communities, Stack Overflow threads, and a talent pool of engineers who
know them. The organizational resilience of open-source tools exceeds
custom builds in almost every case."

*Adapting down:* Junior: "Build vs Buy is about deciding whether to create
platform tooling from scratch or use existing tools (like ArgoCD for
deployments, Backstage for developer portal). The short answer: use
existing tools unless they genuinely cannot meet your needs. Building
custom tools takes years to reach the maturity of established open-source
projects."

**Blank Mind Recovery:**

**(1) Restate:** "Build vs Buy platform decisions - how to decide when to
create custom platform tooling vs. adopting existing solutions."

**(2) First principles:** "Platform tooling has two phases: initial build
and ongoing maintenance. Build costs are the minority; maintenance costs
are the majority. Any decision to build custom must account for both."

**(3) Bridge:** "Think about why companies use PostgreSQL instead of
building their own database: the feature set, reliability, and community
support of PostgreSQL would take decades to replicate. Platform tooling
decisions follow the same logic."

---

### 📘 Concept Explanation

**What it is:**
The Build vs Buy decision in platform engineering is the framework for
deciding whether to create custom platform tooling from scratch, adopt
open-source solutions, procure commercial tools, or some combination.
The framework applies to: CI/CD systems, Kubernetes management tools,
developer portals, secret management, observability stacks, policy
enforcement, and cloud resource provisioning.

**The problem it solves:**
Platform engineers frequently overestimate the value of custom solutions
and underestimate the cost of building and maintaining them. The Build vs
Buy framework forces explicit consideration of total cost of ownership,
organizational capability, and competitive differentiation before committing
to a build path.

**How it works:**

```
BUILD VS BUY DECISION FRAMEWORK

Step 1: Define the capability requirement
  What does the platform need to do?
  What are the non-negotiable constraints?
  (performance, security, regulatory, integration)

Step 2: Survey the landscape
  Open source options: list candidates
  Commercial options: list candidates
  Evaluate against non-negotiable constraints

Step 3: TCO comparison

  BUILD TCO:
  Initial build:        3-6 months engineering time
  Feature parity with   ongoing (will never fully match
  OSS alternatives:     a project with 100 contributors)
  Maintenance:          ~40% of initial effort per year
  On-call burden:       permanent (custom systems = custom incidents)
  Documentation:        100% platform team responsibility
  Talent dependency:    knowledge leaves when engineers leave

  ADOPT (OSS) TCO:
  Integration:          2-4 weeks engineering time
  Upgrade management:   2-4x per year, typically 1-2 days each
  Community support:    Stack Overflow, GitHub issues, Slack
  Documentation:        OSS project docs + internal customization notes
  Talent pool:          engineers who know ArgoCD/Backstage exist externally

  COMMERCIAL TCO:
  License cost:         per seat, per cluster, or usage-based
  Integration:          typically lower than OSS (vendor support)
  Upgrade:              vendor-managed (can have breaking changes)
  Vendor lock-in:       migration cost if vendor changes

Step 4: Decision criteria

  DEFAULT: Adopt OSS
    - Covers 80%+ of requirements
    - Active community (commits in last 30 days)
    - Production references from similar organizations
    - CNCF graduated/incubating status (for K8s-adjacent tools)

  BUY COMMERCIAL when:
    - OSS requires more engineering than commercial integration
    - Compliance requires vendor support contracts
    - Total engineering cost of OSS adoption > license cost

  BUILD when:
    - No OSS/commercial option meets non-negotiable constraints
    - Platform capability is a genuine competitive differentiator
    - Regulatory/security constraints prohibit external dependencies

Step 5: Build exit criteria
  If you decide to build, define the exit conditions:
  - When will you deprecate the custom solution?
  - What OSS alternative would you migrate to if it matures?
  - What is the maximum investment before you stop and adopt OSS?
```

**The key insight:**
Open source is not free - it has integration, maintenance, and upgrade
costs. But those costs are almost always lower than building from scratch
because the core development and testing is done by the community. The
build decision should be made only when the integration/adaptation cost
of an existing tool exceeds the build cost over a 3-year TCO horizon.

**When to build:**
1. Internal compliance prevents using external dependencies
2. Performance requirements that no OSS tool meets
3. The capability is a genuine product differentiator (rare)

**When to adopt open source:**
Everything else. The default answer is: adopt, contribute upstream when
needed, wrap with internal tooling for organizational fit.

**When to buy commercial:**
When the OSS adoption effort + ongoing maintenance > license cost, AND
the organizational budget is there. Common cases: observability (Datadog
vs. self-hosted Prometheus stack), developer portals (Cortex vs. self-hosted
Backstage), secret management (HashiCorp Vault Enterprise vs. open-source).

---

### 💻 Code Example

**Example: BAD vs GOOD - building a custom deployment controller**

```python
# BAD: Building a custom deployment orchestration tool
# "We need something simpler than ArgoCD"
# 2 engineers, 3 months to build, then:

class CustomDeployOrchestrator:
    """
    Custom deployment controller built 'for simplicity'.
    Problems after 12 months in production:
    - No RBAC (ArgoCD has full RBAC model built in)
    - No drift detection (ArgoCD detects config drift)
    - No sync waves (ordering complex deployments is hard)
    - No health checks (ArgoCD has CRD health checks)
    - No rollback (ArgoCD has one-click rollback)
    - On-call burden falls entirely on platform team
    - 4 critical bugs found in first 3 months
    Total cost: 6 engineer-months to build, 2 engineer-months/year
    maintenance, 3 production incidents in year 1.
    ArgoCD integration: 2 weeks, free, 0 custom code to maintain.
    """
    def deploy(self, manifest, namespace):
        # 500 lines of custom code that reinvents ArgoCD poorly
        pass
```

```yaml
# GOOD: Adopt ArgoCD (OSS, CNCF graduated)
# 2 weeks of integration work, then:

# ArgoCD Application CRD - the only custom code needed
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payments-api
  namespace: argocd
spec:
  project: team-payments
  source:
    repoURL: https://github.com/company/gitops
    targetRevision: HEAD
    path: apps/payments-api
  destination:
    server: https://kubernetes.default.svc
    namespace: team-payments
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=false
# Gained for free: drift detection, RBAC, sync waves,
# health checks, rollback UI, audit trail, multi-cluster.
```

> **Code walkthrough:** The BAD pattern builds custom deployment
> orchestration that reinvents a fraction of ArgoCD's capabilities.
> The custom code introduces novel bugs, requires platform team
> expertise for all on-call scenarios, and falls further behind the
> open-source alternative every month as ArgoCD gains features.
> The GOOD pattern adopts ArgoCD with a simple Application CRD.
> The integration took 2 weeks; the platform team gets RBAC, drift
> detection, sync waves, health checks, and rollback UI for free,
> maintained by the ArgoCD community.

**Example: Build vs Buy evaluation template**

```markdown
Platform Capability: Developer Portal

Requirement: self-service service catalog + software templates
  + docs as code + TechDocs integration

Options evaluated:
1. Backstage (OSS, CNCF)
   Integration cost: 3-4 weeks
   Ongoing: quarterly upgrades (4h each), plugin maintenance
   Community: 22,000 GitHub stars, 1,000+ contributors
   Decision: ADOPT

2. Cortex (Commercial)
   License cost: $X/seat/month
   Integration: 1-2 weeks (hosted SaaS)
   Vendor lock-in: migration to OSS would require data export
   Decision: EVALUATE if Backstage integration > budget for Cortex

3. Custom portal (Build)
   Initial build: 4-6 months
   Feature parity with Backstage: never achievable
   Ongoing maintenance: 1 engineer dedicated
   Decision: REJECT

Chosen option: Backstage OSS
Rationale: Backstage is CNCF-graduated, has full feature set we need,
integration cost 3-4 weeks, ongoing maintenance is manageable, and
the talent pool of Backstage-experienced engineers is growing.
```

> **Code walkthrough:** The evaluation template forces explicit
> comparison across integration cost, ongoing maintenance cost, talent
> availability, and vendor risk for each option. Building a custom
> portal was rejected not because it is technically infeasible but
> because the 4-6 month build cost + perpetual 1 FTE maintenance cost
> cannot be justified when Backstage provides the same functionality with
> 3-4 weeks of integration effort. The OSS adoption path wins on TCO.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Build vs Buy in platform engineering is about deciding whether to create
> custom tooling or use existing open-source or commercial tools. The strong
> default is to use existing tools: ArgoCD for deployments, Backstage for
> developer portal, Prometheus for monitoring. Building custom alternatives
> requires years to reach the same maturity and puts ongoing maintenance
> burden on the platform team indefinitely.

*Push deeper:* "The key insight is that open-source tools like ArgoCD or
Backstage are maintained by hundreds of contributors and used by thousands
of organizations. Any custom tool we build starts from zero and is maintained
only by us. The TCO calculation almost always favors adoption."

---

**Senior / Staff (5+ years):**
> Build vs Buy is a TCO decision with a strong prior toward adoption. I
> frame it as three questions: (1) Does any open-source or commercial tool
> meet our non-negotiable requirements? If yes, adopt it. (2) Is the
> integration and maintenance cost of the best OSS option justified vs.
> commercial, accounting for long-term support costs? (3) Is there a genuine
> organizational constraint (regulatory, security) that prevents adoption
> of any external dependency? Only if the answer to (3) is yes do I seriously
> consider building.
>
> The anti-pattern I've seen most: "we'll build something simple and extend
> it later." Simple platform tools grow into complex platform tools because
> the requirements always expand. The "simple" custom CI/CD system becomes
> a full-featured CI/CD system maintained by the platform team forever. I
> have never seen a custom platform tool stay simple.

*Push deeper:* "At Staff level: the build vs buy decision has an
organizational resilience dimension. Custom tools create key-person
dependencies - the engineer who built the custom deployment system is
the only one who can debug its production incidents. Open-source tools
have a community, documentation, and a talent pool. When evaluating build,
I explicitly ask: what happens when the primary builder leaves the team?"

---

### ⚠️ Common Misconceptions

**Misconception: "Open source is free."**

Open-source tools have zero license cost but non-zero operational cost.
Upgrading Kubernetes-adjacent tools (cert-manager, Gatekeeper, ArgoCD)
requires testing compatibility with each Kubernetes release, applying
CRD migrations, and validating behavior changes in new versions. Estimate
2-4 upgrade cycles per year, 1-2 days each, per major component. This
is the real cost of open source adoption.

**Misconception: "Building gives us full control."**

Full control over source code also means full responsibility for all bugs,
all security vulnerabilities, all performance issues, and all missing
features. Open-source tools have the community discovering and fixing bugs
for you. Custom tools have only your team. Control is real but comes at
the cost of exclusive ownership of all problems.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: "NIH syndrome" (Not Invented Here)**

Symptom: Platform team rebuilds capabilities that mature open-source
tools already provide. "We need something simpler/more customized/that
we understand completely."

Cause: engineering bias toward building (more interesting work) vs.
integrating (less glamorous). Underestimation of long-term maintenance cost.

Diagnosis:
- List custom platform components vs. OSS alternatives
- For each custom component: estimate build cost, maintenance cost per year,
  and feature gap vs. the best OSS alternative
- If maintenance cost > 2 engineer-months/year per component: this is
  toil disguised as engineering

Fix: deprecate custom components in favor of OSS alternatives. Plan migration
with a 3-6 month runway. The migration pain is real but temporary; the
ongoing maintenance cost avoidance is permanent.

**Failure mode: Commercial tool vendor lock-in**

Symptom: Platform team discovers that migrating away from a commercial
tool would cost 6+ months of engineering effort because the tool's APIs
are proprietary and all platform tooling depends on them.

Cause: adopted a commercial tool without defining exit criteria or
building an abstraction layer.

Prevention: for any commercial tool adopted, define at adoption time:
(1) the migration path to an OSS alternative, (2) the data export format,
(3) the maximum acceptable migration cost if the vendor increases prices
or changes terms.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions minimum.

---

#### Q1 - How do you evaluate a new platform tool for adoption?

Evaluation framework:

**Phase 1 - Fit Assessment (1-2 days):**
Does the tool meet non-negotiable requirements? Run a spike:
install, configure, and attempt the target use case. Not a deep dive -
just enough to know if it could work.

**Phase 2 - Production Readiness Assessment:**
- Maturity: project age, release frequency, CNCF status
- Adoption: GitHub stars, production references from similar orgs
- Community health: response time to issues, active maintainers
- Operational requirements: HA setup, backup/restore, upgrade path

**Phase 3 - Integration Cost Estimate:**
- Time to integrate with existing platform (estimate in person-days)
- CRD/API compatibility with current Kubernetes version
- Existing knowledge on the platform team (vs. learning curve)

**Phase 4 - Ongoing Cost Estimate:**
- Upgrade frequency and complexity
- Operational overhead (stateful components require more ops than stateless)
- Documentation and runbook creation time

**Phase 5 - Decision:**
Adopt if: Phase 2 passes all critical criteria AND Phase 3 + Phase 4
cost is less than building a comparable capability in-house over 3 years.

*What separates good from great:* Phase 2 (production readiness assessment)
is the most important and most often skipped. Platform teams that adopt
tools without checking project health end up with abandoned tools that they
still need to maintain. The CNCF project lifecycle (sandbox/incubating/
graduated) is a useful health proxy for Kubernetes-adjacent tools.

---

#### Q2 - How do you handle a platform capability that requires a custom build?

When a build decision is justified, the process matters:

Step 1 - Minimize scope ruthlessly: build the minimum viable platform
capability, not the full vision. The most dangerous build decision is
one with an ambitious feature roadmap.

Step 2 - Define the exit conditions up front:
- If an OSS tool matures to cover this capability within X months,
  we will migrate to it
- If the custom tool requires > Y engineer-months/year to maintain,
  we will re-evaluate
- The custom tool has a maximum lifetime of Z years before replacement

Step 3 - Design for replaceability: use interfaces and abstractions
that allow swapping the custom implementation for an OSS alternative
without changing the consumer API.

Step 4 - Document obsessively: custom tools have no external documentation,
so internal docs are the only safety net for on-call engineers and new
team members.

Step 5 - Measure TCO continuously: quarterly review of actual maintenance
time vs. estimate. When maintenance time exceeds the threshold, trigger
the exit criteria review.

*What separates good from great:* Defining exit conditions at build time
is the most important discipline. Without exit conditions, custom tools
live forever - no one wants to own the migration to OSS, so the custom
tool accumulates technical debt indefinitely. Exit conditions make the
migration decision mechanical rather than political.

---

#### Q3 - What are the CNCF project maturity levels and why do they matter?

CNCF (Cloud Native Computing Foundation) manages a portfolio of open-
source cloud-native projects and applies a maturity classification:

**Sandbox:** early-stage project with a promising use case. Not yet
production-ready. Adopt for experimentation only. CNCF has provided
initial funding but not vetted for production.

**Incubating:** project has demonstrated usage in production, active
community, clear governance. Can be adopted with eyes open about
potential breaking changes. Kubernetes-adjacent tools at Incubating:
Flux, OpenTelemetry Operator.

**Graduated:** project has demonstrated long-term stability, broad
adoption, active community, defined governance. Equivalent to "production
recommended." Examples: Kubernetes, Prometheus, ArgoCD, Fluentd, Jaeger,
Envoy, Helm, Harbor, OPA.

**Archived:** project is no longer actively maintained. Do not adopt;
migrate away if currently using.

Why CNCF maturity matters for platform decisions:
- Graduated status is a vendor-independent quality signal
- CNCF projects have an agreed governance model (prevents single-vendor
  capture)
- CNCF projects typically have a clear path for security disclosures
- When presenting platform tool choices to security teams or auditors,
  CNCF graduation is a useful trust signal

*What separates good from great:* Knowing the CNCF project list well
enough to cite graduation status for the tools you recommend. "I chose
ArgoCD because it is CNCF Graduated, has 15,000+ GitHub stars, 500+
contributors, and is used in production by hundreds of enterprises" is
a more credible recommendation than "I chose ArgoCD because it looked
good on GitHub."

---

#### Q4 - How do you handle the "build to understand" use case?

Sometimes the argument for building is: "we need to understand the problem
deeply before adopting an OSS solution." This is a legitimate learning
objective but has a trap: the prototype becomes the production system.

The correct process for "build to understand":

1. Time-box the spike: 1-2 weeks, not months. Build the minimum
   to understand the problem. Do not optimize for production quality.

2. Document learnings, not code: the output of the spike is a decision
   document, not a deployable artifact.

3. Evaluate OSS with the learnings: use the spike learnings to make a
   better OSS evaluation. What constraints did you discover? Which OSS
   tools would handle them?

4. Delete the spike code: if you built something during the spike,
   delete it. It is not production code. Do not let it accidentally
   become the production solution.

The trap to avoid: "we understand the problem well now, so our custom
solution is better than OSS." This is almost never true - the spike
code is unbattled, undocumented, and missing years of production
hardening that the OSS alternatives have.

*What separates good from great:* Having seen (or caught) the pattern
where a 2-week spike becomes the production solution through inertia.
"We already built it" is not a good reason to use it over a more mature
OSS alternative. The sunk cost fallacy in platform engineering causes
more long-term suffering than almost any other decision failure.

---

#### Q5 - How do you evaluate whether to self-host an OSS tool vs. use a managed service?

For most OSS platform tools, the choice is: self-host (run in your own
Kubernetes cluster) vs. use a managed/SaaS version.

**Self-hosting cost:**
- Initial deployment: 1-3 days
- HA configuration: 1-2 days (stateful components require more)
- Upgrade management: 2-4x per year, 1-2 days each
- On-call burden: you are responsible for availability
- Backup/restore: you must design and test this
- Scaling: you must manage compute costs

**Managed service cost:**
- Integration: 1-3 days
- Upgrades: vendor-managed (still may require application changes)
- On-call: vendor-managed (you get SLA support)
- Cost: usage or seat-based pricing

**Decision criteria:**

Choose self-hosted when:
- Data sovereignty requirements prevent cloud-managed services
- Customization requirements exceed what managed service supports
- Scale makes managed service cost prohibitive
- Organization has strong Kubernetes operational capability already

Choose managed service when:
- Platform team bandwidth is the bottleneck (not budget)
- The managed service has adequate data residency and compliance certs
- Time-to-value is critical (managed service is faster to stand up)

*What separates good from great:* The honest answer for most mid-sized
organizations: managed services are worth the cost for stateful platform
components (observability, secret management, developer portals) because
the operational overhead of running HA stateful services on Kubernetes
is significant. The cost analysis is: managed service price vs.
[platform engineer fully-loaded cost] * [hours/year operating and
upgrading self-hosted]. For small platform teams, managed services
often win on that math.

---

#### Q6 - How do you manage the platform tool upgrade lifecycle?

Platform tool upgrades are a significant source of platform team toil if
not managed systematically.

**Upgrade management framework:**

1. Track versions: maintain an inventory of all platform tools, their
   current versions, and the latest available versions. Automate this
   with Renovate or Dependabot for Helm charts.

2. Upgrade cadence policy: define acceptable version lag. For security-
   critical components (cert-manager, Gatekeeper): N-1 at most (always
   within one minor version of latest). For less critical components:
   N-2 or quarterly upgrades acceptable.

3. Testing pipeline: every tool upgrade should be tested in a staging
   cluster before production. The staging cluster should mirror the
   production cluster configuration (same Kubernetes version, same CRDs).

4. Breaking change communication: for upgrades that require application
   team changes (API version changes, behavior changes), communicate
   4-6 weeks before the upgrade with the specific action required.

5. Rollback procedure: for every tool upgrade, define the rollback
   procedure before starting. CRD upgrades are the hardest to roll back
   (some CRD changes are one-way). Test rollback in staging.

*What separates good from great:* Having automated the version tracking
and having a tested staging pipeline for upgrades. Teams that do not
have staging clusters for platform upgrades discover breaking changes in
production. The cost of a staging cluster is almost always justified by
catching even one breaking change before production.

---

#### Q7 - How do you handle platform tool deprecation?

Platform tool deprecation is the most neglected phase of the platform
tool lifecycle.

**Deprecation framework:**

Step 1 - Announce with timeline: 3 months minimum before end-of-support.
Communicate the replacement tool, migration path, and support cutoff date.

Step 2 - Provide migration tooling: don't just announce - build or provide
tooling that makes migration straightforward. If migrating from Kustomize
to Helm, provide a migration script or template converter.

Step 3 - Identify blockers: which teams have custom configurations or
integrations that prevent straightforward migration? Work with them first
(they are the long tail that usually holds up deprecation).

Step 4 - Set a hard end-of-support date: after this date, the platform
team will not respond to incidents related to the deprecated tool. This
is the forcing function for migration.

Step 5 - Enforce: when the date arrives, enforce. Platform teams that
extend deadlines indefinitely teach product teams that deadlines are
optional, which makes all future migrations harder.

*What separates good from great:* Setting and enforcing the hard
end-of-support date is the most organizationally difficult step. It
requires leadership support and a commitment to the timeline that does
not bend for individual team blockers. Teams that have lived through a
deprecation that was extended 3 times understand why the hard date
matters: the extension cost is paid in loss of platform team credibility.

---

#### Q8 - When should you contribute to an open-source tool vs. forking it?

Platform teams sometimes discover that an OSS tool almost meets their
needs but requires changes. The options: contribute upstream, fork, or
work around.

**Contribute upstream when:**
- The change is generally useful (other users would benefit)
- The upstream project accepts external contributions
- The change is small enough to be merged in < 3 months
  (larger changes often sit in review indefinitely)
- The organizational overhead of the contribution process is acceptable

**Work around when:**
- The change would not be accepted upstream (too opinionated)
- The workaround is simple (configuration, wrapper script)
- The workaround has low maintenance overhead

**Fork when (last resort):**
- Critical organizational requirement that upstream will never support
- The fork is planned and maintained with the same rigor as a custom build
  (owned code, upgrade management, security patches)
- Exit criteria defined: what would trigger migration back to upstream?

The fork anti-pattern: fork because the upstream PR takes too long,
then never keep the fork in sync with upstream. The fork accumulates
drift, loses upstream bug fixes and security patches, and eventually
becomes unmaintainable. Forking without a maintenance discipline is
worse than not forking.

*What separates good from great:* Having contributed to an upstream OSS
project (even a small contribution) and understanding the process -
maintainer review latency, contribution guidelines, the political dynamics
of getting a non-trivial change accepted. This experience shapes how you
evaluate the "contribute upstream" option in a build vs buy decision.

---

#### Q9 - Describe a build vs buy decision you made that turned out well or poorly.

*This is an open question probing real-world experience. A strong answer:*

Situation: the platform team needed a developer portal to provide service
catalog, software templates, and technical documentation hosting for 35
engineering teams. We evaluated three options: build a custom portal using
React + a backend API, adopt Backstage (OSS), or use Cortex (commercial).

Build analysis: building a comparable portal would require 4-6 months
of initial development, would perpetually lag behind Backstage's
plugin ecosystem, and would require 1 dedicated engineer for maintenance.
The risk: we would build the features we thought teams needed, not the
features they actually needed.

Backstage OSS analysis: 3-4 weeks of integration to get the core catalog
and TechDocs working. Plugin ecosystem covers most requirements. Upgrade
cadence: quarterly, 1-2 days each. Risk: Backstage has a steep learning
curve and the upgrade process changed significantly between major versions.

Decision: adopted Backstage.

What went well: the self-service catalog was live in 4 weeks, TechDocs
integration reduced documentation fragmentation, software templates
reduced new service setup from 2 days to 20 minutes. 35 teams adopted
within 6 months.

What went poorly: Backstage v1.0 to v1.1 upgrade was a breaking change
that required 3 days of migration work we had not budgeted. Backstage's
customization model (React plugins) required frontend engineering
experience that the platform team did not have. Hired a frontend engineer
for 3 months to build critical internal plugins.

Lessons: adoption of a complex OSS tool (Backstage is a full React app)
requires skills you may not have on the platform team. Budget for the
skills gap at adoption time, not after encountering it.

*What separates good from great:* Describing what went poorly as well as
what went well. Platform engineering decisions rarely go perfectly. The
ability to describe the failure modes of a decision you made, what you
learned, and what you would do differently - this is the engineering
maturity signal the question is probing for.

---

### ⚖️ Comparison Table

| Option | Upfront Cost | Ongoing Cost | Feature Richness | Vendor Risk | When to Choose |
|---|---|---|---|---|---|
| Build custom | High (3-6 months) | High (perpetual maintenance) | Starts low, grows slowly | None | Only if OSS/commercial cannot meet constraints |
| Adopt OSS | Low (2-4 weeks) | Medium (upgrade management) | High immediately | Low (open source) | Default - covers most cases |
| Commercial SaaS | Low (1-2 weeks) | High (license cost) | High immediately | High (vendor dependency) | When OSS ops cost > license cost |
| Fork OSS | Medium (fork + maintain) | High (must track upstream) | High then diverges | Medium | Last resort when upstream won't accept needed change |

**The deciding factor:**
Adopt OSS is the default; build is the last resort. The burden of proof
is on building, not on adopting. Any build decision must explicitly justify
why no OSS option meets the requirements.

---

---

# Platform API Design and Contracts

---
id: PE-018
title: Platform API Design and Contracts
category: Platform Engineering
difficulty: ★★☆
interview_weight: high
seniority: senior
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Platform API design is the design of the interfaces through which
> Stream-Aligned teams interact with the platform - Kubernetes CRDs,
> Backstage scaffolding templates, Helm chart APIs, Crossplane Compositions.
> Good platform APIs have three properties: they are stable (Stream-Aligned
> teams can rely on them not changing unexpectedly), discoverable (teams
> can find and understand them without asking the platform team), and
> opinionated (they encode platform defaults so teams get the right thing
> without having to know the right thing).

**3 minutes (Senior):**
> Platform APIs are the primary interface between the Platform team and
> Stream-Aligned teams. Unlike external-facing product APIs, platform APIs
> have captive consumers - your colleagues who cannot easily switch to a
> competitor. This makes bad platform API design especially damaging:
> teams are stuck with it regardless of how frustrating it is.
>
> The three properties of a good platform API: Stability means that once
> teams build on a platform API, it does not break them unexpectedly.
> This requires versioning (v1alpha1, v1beta1, v1), deprecation policies
> (minimum 3 months notice before breaking changes), and backward
> compatibility within a version. Discoverability means that teams can
> find the API, understand what it does, and use it correctly without
> asking the platform team. This requires documentation, examples, and
> ideally a developer portal (Backstage software catalog) that surfaces
> the API. Opinionatedness means the API encodes the platform's defaults
> so that the correct choice is the easy choice. A platform API that
> exposes 50 configuration knobs is not opinionated; it has just moved
> the complexity from the platform team to the consumer.
>
> The Kubernetes-native platform uses CRDs as the primary platform API
> surface. A `Database` CRD that accepts only `spec.size`, `spec.engine`,
> and `spec.storageGB` is opinionated: all other properties (HA, encryption,
> backup, networking) are handled by the platform. The consumer makes only
> the decisions they should make; the platform handles the rest.

**Framework:** STABLE -> DISCOVERABLE -> OPINIONATED ->
VERSIONED -> DOCUMENTED

*Adapting up:* Staff adds: "Platform API design has a political dimension.
Opinionated APIs that remove configuration choices from teams create
resistance from teams who want that control. The staff-level skill:
distinguishing between configuration choices that genuinely matter to
teams (expose them) and configuration choices that the platform should
have a single correct answer for (hide them). Getting this wrong in
either direction hurts adoption."

*Adapting down:* Junior: "Platform APIs are the interfaces that product
teams use to interact with the platform. Think of them like the API of
a library: they should be simple to use correctly, hard to use incorrectly,
and stable so you don't have to change your code every time the platform
team ships updates."

**Blank Mind Recovery:**

**(1) Restate:** "Platform API design and contracts - designing the interfaces
between the platform team and Stream-Aligned teams."

**(2) First principles:** "An API is a contract between two parties. Platform
APIs are contracts between the platform team (who builds the platform) and
product teams (who build products using the platform). Good contracts are
clear, stable, and mutually beneficial."

**(3) Bridge:** "AWS SDK is a great example of a platform API: you call
`create_bucket()` without needing to understand S3 internals. The platform
(S3) handles all the complexity. Platform engineering tries to do this
for internal infrastructure."

---

### 📘 Concept Explanation

**What it is:**
Platform API design and contracts cover the design of interfaces through
which Stream-Aligned teams interact with the platform. In a Kubernetes-
based platform, these interfaces are: Custom Resource Definitions (CRDs),
Helm chart `values.yaml` schemas, Crossplane Compositions, Backstage
software templates, and GitHub Actions reusable workflow inputs.

**The problem it solves:**
Without intentional API design, platform tools expose their full
complexity to consumers. Product teams must understand the full
configuration surface of Kubernetes Deployments, Services, Ingresses,
HorizontalPodAutoscalers, PodDisruptionBudgets, and ResourceQuotas to
deploy a service. With intentional platform API design, the API hides
this complexity and exposes only the decisions that vary per service.

**How it works:**

```
PLATFORM API DESIGN PRINCIPLES

PRINCIPLE 1: Minimize the decision surface
  BAD: expose all 50 Kubernetes Deployment spec fields
  GOOD: expose only the fields that vary per service:
    - image: the container image to deploy
    - port: the port the service listens on
    - replicas: min/max for HPA
    - resources.tier: small/medium/large (maps to CPU/memory preset)
    - ingress.host: optional, if service needs an ingress

PRINCIPLE 2: Encode defaults as opinionated choices
  BAD: require consumer to specify resource limits manually
  GOOD: provide tiers (small/medium/large) that map to pre-validated
        resource requests/limits combinations

PRINCIPLE 3: Make the wrong thing difficult
  BAD: expose `securityContext.privileged` field to consumers
  GOOD: omit the field from the CRD spec entirely; enforce via
        OPA Gatekeeper independently of the API

PRINCIPLE 4: Version the API
  v1alpha1: experimental, may break without notice
  v1beta1:  stable interface, deprecation notice before breaking changes
  v1:       stable, backward compatible within major version,
            minimum 6 months deprecation notice

PRINCIPLE 5: Document with examples
  Every API field should have:
  - description: what it does
  - type: the expected type
  - default: the default value if not specified
  - example: a realistic example value
  - constraints: valid values or ranges

KUBERNETES CRD AS PLATFORM API EXAMPLE:

# Platform-designed Service CRD
# (not raw Kubernetes, not a catch-all abstraction)
apiVersion: platform.company.com/v1beta1
kind: Service
spec:
  image: string          # container image:tag
  port: integer          # main container port
  replicas:
    min: integer         # minimum replicas (default: 2)
    max: integer         # maximum replicas (default: 10)
  resources:
    tier: enum           # small|medium|large (required)
  ingress:               # optional block
    host: string         # hostname for ingress rule
  slo:
    availability: float  # 0.999|0.9999 (default: 0.999)
    # platform sets PodDisruptionBudget based on this
```

**The key insight:**
Platform API surface area is a liability, not an asset. Every configuration
field exposed to consumers is a field consumers must understand, must not
misuse, and that the platform must support forever. The goal is to
minimize the API surface to exactly the decisions that vary per service.

**When to expose a configuration field:**
When the correct value genuinely varies per service and there is no
correct default. Port number varies (different services use different
ports). Container image varies (different services deploy different images).

**When to hide a configuration field:**
When the platform has a correct answer that applies in all cases, or
when the tradeoffs require platform expertise to navigate. Resource
limits, health check configuration, PodDisruptionBudget, NetworkPolicy,
PodSecurityContext - these have correct platform defaults. Exposing
them requires consumers to have platform expertise.

---

### 💻 Code Example

**Example 1: BAD vs GOOD - over-exposed vs opinionated CRD**

```yaml
# BAD: passthrough CRD that exposes raw Kubernetes fields
# This is not an API; it's a wrapper with extra steps
apiVersion: platform.company.com/v1alpha1
kind: Service
spec:
  deployment:            # raw Deployment spec passthrough
    replicas: 3
    template:
      spec:
        containers:
        - name: app
          image: myapp:v1
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "1000m"
              memory: "512Mi"
  # Product teams must now know Kubernetes resource syntax
  # The CRD provides no value over raw kubectl apply
```

```yaml
# GOOD: opinionated CRD that hides Kubernetes complexity
# Product teams only specify what varies
apiVersion: platform.company.com/v1beta1
kind: Service
metadata:
  name: payments-api
  namespace: team-payments
spec:
  image: myapp:v1
  port: 8080
  replicas:
    min: 2     # platform sets HPA with sensible defaults
    max: 10
  resources:
    tier: medium   # platform maps: cpu 250m-1000m, mem 256Mi-512Mi
  ingress:
    host: payments.company.com
  slo:
    availability: 0.999  # platform sets PDB to allow 1 unavailable
```

> **Code walkthrough:** The BAD pattern is a passthrough CRD that
> requires product teams to know Kubernetes resource syntax, HPA
> configuration, and limit ratios. It provides no cognitive load
> reduction over raw kubectl. The GOOD pattern is opinionated: product
> teams specify only image, port, scale bounds, resource tier, and SLO.
> The platform CRD controller translates these into the correct Kubernetes
> resources with validated defaults. The result: a product engineer can
> deploy a production-grade service without knowing what a resource limit
> is or how HPA works.

**Example 2: CRD versioning and deprecation**

```yaml
# v1alpha1: initial experimental API (internal only)
# API shape may change between releases
apiVersion: platform.company.com/v1alpha1
kind: Database

---
# v1beta1: stable interface with deprecation commitments
# Breaking changes require 3 months deprecation notice
# spec fields added in v1beta1:
# - spec.backup.schedule (new optional field)
# - spec.storageGB validation (previously unvalidated)
apiVersion: platform.company.com/v1beta1
kind: Database
spec:
  engine: postgres
  size: medium
  storageGB: 100      # validated: must be 20-2000
  backup:
    schedule: "0 2 * * *"  # new optional field

---
# Migration from v1alpha1 to v1beta1:
# - kubectl convert handles field mapping
# - Platform team provides migration script:
#   kubectl get databases -A \
#     -o jsonpath='{.items[*].metadata.name}' | \
#     xargs -I{} kubectl annotate database {} \
#     platform.company.com/migrated-to-v1beta1=true
```

> **Code walkthrough:** CRD versioning follows Kubernetes API conventions:
> v1alpha1 for experimental (may break), v1beta1 for stable interface
> with deprecation commitments. The v1beta1 version adds fields and adds
> validation to an existing field - both are backward compatible changes.
> When breaking changes are required (removing or renaming a required
> field), the platform team creates a v2 of the API and provides a
> migration path, allowing teams to migrate on their own schedule before
> v1 is deprecated.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Platform APIs are the interfaces product teams use to deploy services,
> provision databases, and configure observability through the platform.
> In a Kubernetes-based platform, these are often CRDs (Custom Resource
> Definitions) - think of them as custom Kubernetes objects with
> simplified fields. Good platform APIs hide Kubernetes complexity and
> expose only the fields that matter to the product team: image, port,
> scale bounds, and resource tier.

*Push deeper:* "The key principle: expose only the decisions that vary
per service. Everything else should be a platform default. If the platform
has a correct answer for a configuration choice, that choice should not
be exposed to product teams."

---

**Senior / Staff (5+ years):**
> Platform API design is the interface contract between the Platform team
> and Stream-Aligned teams. The three properties I design for: stability
> (versioning, deprecation policy), discoverability (documentation in
> Backstage catalog, examples for every field), and opinionatedness
> (the API surface should only include decisions that genuinely vary per
> service; everything else is a platform default enforced by the controller).
>
> The hardest part: deciding what to expose vs. hide. Exposing too much
> (passthrough CRD) provides no cognitive load reduction. Hiding too much
> (overly opinionated) blocks legitimate use cases and drives teams to
> work around the platform. I use this heuristic: if 80%+ of services
> would set a field to the same value, it should be a platform default,
> not an exposed field.

*Push deeper:* "At Staff: platform API versioning is the biggest operational
challenge. CRDs must be versioned following Kubernetes API conventions
(v1alpha1 -> v1beta1 -> v1). CRD version upgrades require serving multiple
versions simultaneously via conversion webhooks during the migration
period. This is operationally complex - plan for it at design time, not
after you have 50 clusters with v1alpha1 CRDs installed."

---

### ⚠️ Common Misconceptions

**Misconception: "Opinionated APIs reduce team flexibility."**

Opinionated APIs reduce the flexibility to make bad choices. A team that
cannot set `privileged: true` in a pod cannot accidentally create a
security vulnerability. A team that must use resource tiers (small/medium/
large) cannot accidentally set memory limits that cause OOMKilled. The
limitation is on bad choices; good choices that the platform team has
already made are still accessible - they are the defaults.

**Misconception: "CRD versioning is just for Kubernetes; our internal
CRDs don't need it."**

All platform APIs need versioning because consumers build automation on
top of them. A CI/CD pipeline that creates `Database` objects via the
platform API will break if that API changes without warning. CRD versioning
(v1alpha1, v1beta1, v1) and deprecation policies are not bureaucracy -
they are what distinguishes a reliable platform API from a "use at your
own risk" interface.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: Overly abstract API that loses required information**

Symptom: Product teams encounter situations where the platform API
cannot express their requirements. They submit "exception requests" or
work around the platform API by applying raw Kubernetes YAML alongside
the platform CRD.

Cause: the platform API was designed too opinionated, hiding configuration
that legitimately varies across teams. Common examples: all services
assume stateless workloads, but one team runs a stateful service that
needs persistent volumes; all services use the same ingress config, but
one team needs custom TLS certificates.

Diagnosis: count "exception requests" and raw Kubernetes YAML applied
alongside platform CRDs. Categorize by type. When any category exceeds
10% of total deployments: the API is missing a legitimate configuration
surface.

Fix: add the missing field to the CRD spec (as an optional field with
a sensible default). This is API evolution, not breakage.

**Failure mode: Platform API breaking change in production**

Symptom: stream-aligned team's CI/CD pipeline fails after a platform
team deploys a CRD update. Error: "field X is no longer valid."

Cause: CRD update removed or renamed a field without going through the
deprecation process (announce, wait, remove).

Diagnosis: compare current CRD spec against previous version; find
removed or renamed fields; identify all consumers using those fields.

Fix: restore the deprecated field temporarily, announce the deprecation
formally, provide migration tooling, wait 3 months, then remove.

Prevention: follow CRD versioning conventions; never remove fields from
a stable (v1beta1+) CRD version without a new CRD version.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions minimum.

---

#### Q1 - How do you design a CRD for a platform API?

CRD design process:

Step 1 - Identify the consumer use cases: what do product teams actually
need to specify? Interview 3-5 teams before writing a single line of spec.

Step 2 - Identify platform-owned decisions: what does the platform know
the correct answer for, regardless of the specific service? These become
hidden defaults, not CRD fields.

Step 3 - Design the minimal CRD schema with validation:
- All fields should have clear descriptions
- All fields should have documented valid values and constraints
- Required fields should be truly required (not convenience fields)
- Optional fields should have sensible defaults

Step 4 - Write the status sub-resource: the CRD should report the actual
state of the resource it manages (not just the desired state). Product
teams need to know if their `Database` CRD has been successfully
provisioned or is in an error state.

Step 5 - Version the CRD from the start: start with `v1alpha1` explicitly.
Plan the graduation criteria for `v1beta1` (stable interface with 3 months
deprecation window).

Step 6 - Write the controller: the CRD spec is the API; the controller
is the implementation. The controller translates the simple CRD spec into
the full Kubernetes and cloud resources the platform manages.

*What separates good from great:* Starting with user interviews (Step 1)
before designing the CRD spec. Platform APIs designed without user
research encode the platform team's assumptions about what teams need,
not what teams actually need. The CRD fields that product teams are
surprised by (why do I have to specify this?) are the ones where the
platform team assumed incorrectly.

---

#### Q2 - How do you handle backward compatibility for platform APIs?

Backward compatibility rules for platform CRDs (following Kubernetes API
conventions):

**Backward compatible changes (can be made to existing version):**
- Adding a new optional field with a sensible default
- Adding a new enum value to an existing enum field
- Adding a new status field
- Relaxing validation constraints (allowing more values)

**Breaking changes (require a new API version):**
- Removing a field
- Renaming a field
- Changing the type of a field
- Tightening validation constraints (allowing fewer values)
- Changing the semantics of a field (same name, different behavior)

For breaking changes:
1. Create a new API version (v1alpha1 -> v1beta1, or v1beta1 -> v1)
2. Implement a conversion webhook that translates between versions
3. Serve both versions simultaneously during the migration period
4. Announce the deprecation of the old version
5. Provide migration documentation and tooling
6. Wait the minimum deprecation period (3 months for v1beta1, 6 months
   for v1)
7. Remove the old version

*What separates good from great:* Understanding that CRD conversion
webhooks are operationally complex - they run as a webhook in the
cluster and must be highly available. A conversion webhook failure
blocks all CRD operations. Design conversion webhooks with the same
HA requirements as admission webhooks.

---

#### Q3 - How do you document a platform API?

Platform API documentation must serve two audiences: self-service discovery
(teams should be able to find and start using the API without talking to
the platform team) and deep reference (teams should be able to find answers
to edge cases without talking to the platform team).

**Documentation layers:**

Layer 1 - Backstage catalog entry: the platform API should be listed in
the Backstage software catalog with a one-paragraph description, status
(stable/experimental), owner (platform team sub-team), and link to full
documentation.

Layer 2 - Getting started guide: a tutorial that walks from "I need a
database" to "I have a provisioned database with connection credentials"
in fewer than 15 minutes. Realistic examples, not toy examples.

Layer 3 - Reference documentation: every CRD field documented with
description, type, default, valid values, and examples. Generated from
the CRD schema using tools like `crd-ref-docs`.

Layer 4 - Runbook section: common error states and how to diagnose them.
"My Database is stuck in Pending state - here is how to diagnose why."

Documentation completeness test: can a new engineer at the organization
use the platform API to provision a production-grade service without
talking to anyone on the platform team? If no: documentation is incomplete.

*What separates good from great:* Layer 4 (runbook section) is the most
valuable and most often omitted. When a product team's CRD object is
in an error state, they need to be able to diagnose it themselves without
paging the platform team. Runbook documentation in the API docs is what
enables self-service incident response.

---

#### Q4 - How do you measure the quality of a platform API?

Platform API quality is measured by consumer behavior, not by the
platform team's assessment.

**Adoption metrics:**
- Coverage: % of services deployed via platform API vs. raw Kubernetes
  (target: > 90% for mature platform)
- Adoption trend: new services deploying via platform API from day 1
  (vs. starting with raw Kubernetes and migrating later)

**Friction metrics:**
- Time-to-first-deploy: how long from "I want to deploy a new service"
  to successful production deployment using the platform API (target < 1 hour)
- Error rate: % of deployments that fail due to platform API confusion or
  misconfiguration (target < 5%)
- Support ticket volume: tickets from teams confused about the platform API
  (target: decreasing over time as API matures)

**Stability metrics:**
- Breaking change frequency: number of API breaking changes per year
  (target: 0 for v1 APIs, < 2 for v1beta1 APIs)
- Migration completion rate: % of teams that complete API migrations within
  the deprecation window (target: 100%)

*What separates good from great:* Tracking time-to-first-deploy is the
most powerful quality metric because it integrates all aspects of API
quality: discoverability, documentation, error messages, and the API's
expressiveness. A platform API that takes 4 hours to produce a first
successful deployment has a quality problem even if the platform team
thinks the API is well-designed.

---

#### Q5 - How do you handle platform API migration when consumers break?

When a platform API breaking change is unavoidable and some consumers
have not migrated before the deadline:

Step 1 - Impact assessment: identify all consumers still using the old API.
Classify by criticality (production services, CI/CD pipelines, cronjobs).

Step 2 - Outreach: for critical consumers, direct outreach to the team -
not just a ticket, but a synchronous conversation. Understand what is
blocking migration.

Step 3 - Migration assistance: for teams blocked on technical issues,
pair with them to complete the migration. Do not do it for them (creates
dependency), but provide hands-on assistance.

Step 4 - Extension for legitimate blockers: for teams that have a genuine
technical blocker (not organizational inertia), consider a 2-4 week
extension. Do not extend for more than one cycle.

Step 5 - Hard cutover: after extensions are exhausted, remove the old
API version. For services that did not migrate: they will break. The
platform team should have a runbook for emergency migration at this point.

The critical discipline: breaking services that did not migrate is
unpleasant but necessary. Platform teams that never enforce API deprecation
teach teams that deprecations are optional. The cost of one controlled
outage is less than the cost of maintaining deprecated APIs indefinitely.

*What separates good from great:* Having executed a platform API
deprecation that broke at least one service that did not migrate in time,
and managing the incident response professionally - apologizing for the
disruption while maintaining the policy. This is the most difficult
leadership moment in platform API lifecycle management.

---

#### Q6 - What is the role of schema validation in platform API design?

Schema validation in Kubernetes CRDs is enforced via OpenAPI v3 schemas
embedded in the CRD spec. Schema validation serves two purposes:
preventing invalid configurations from being applied, and providing clear
error messages to consumers.

**Validation best practices:**

Validate at admission (not at reconciliation): errors should be returned
to the consumer immediately when they apply the CRD object, not after
the controller tries to process it and fails.

```yaml
# CRD schema validation example
spec:
  properties:
    resources:
      properties:
        tier:
          type: string
          enum: ["small", "medium", "large"]
          description: "Resource tier for this service.
            small: 100m CPU / 128Mi memory.
            medium: 250m CPU / 256Mi memory.
            large: 1000m CPU / 1Gi memory."
    replicas:
      properties:
        min:
          type: integer
          minimum: 1
          maximum: 50
        max:
          type: integer
          minimum: 1
          maximum: 100
  x-kubernetes-validations:
  - rule: "self.replicas.min <= self.replicas.max"
    message: "replicas.min must be <= replicas.max"
```

CEL (Common Expression Language) validation (Kubernetes 1.25+):
Kubernetes now supports CEL expressions for cross-field validation
(e.g., min <= max). Use CEL for constraints that span multiple fields.

*What separates good from great:* Error messages in schema validation
should tell the consumer what they did wrong AND what to do instead.
"Invalid value for field tier" is a poor error message. "Invalid tier
value 'xlarge'. Valid values: small, medium, large. See docs at
https://platform.company.com/docs/service-crd#resources.tier" is
a good error message that enables self-service correction.

---

#### Q7 - How do you design platform APIs for multi-cluster environments?

Multi-cluster platforms have an additional API challenge: clusters are
not identical (different regions, different purposes, different compliance
tiers). Platform APIs must allow consumers to specify cluster context
without requiring them to know cluster internals.

**Design patterns:**

Pattern 1 - Cluster label selector (for flexible targeting):
```yaml
spec:
  placement:
    matchLabels:
      cluster.platform.company.com/tier: production
      cluster.platform.company.com/region: us-east-1
```
Consumers specify what they need (production tier, us-east-1 region);
the platform finds the matching cluster.

Pattern 2 - Named environments (for simpler use cases):
```yaml
spec:
  environment: production  # maps to cluster selection policy
```
The platform maps environment names to cluster selection logic.
Teams do not know cluster names; they know environments.

Pattern 3 - Explicit cluster (for advanced cases only):
```yaml
spec:
  cluster: prod-us-east-1-cluster-03
```
Only for use cases where the specific cluster matters (compliance
isolation, data residency). Not for general use.

The principle: abstract cluster selection from consumers. Consumers
should specify requirements (production, us-east-1) not addresses
(cluster-03). Platform routing handles the rest.

*What separates good from great:* Multi-cluster platform APIs must
handle the failure mode where no cluster matches the requirements. The
error should tell the consumer why no cluster was found ("no production
cluster available in us-east-1; available regions: us-west-2, eu-west-1")
not just "placement failed." Error messages that enable self-service
diagnosis are the difference between a 5-minute fix and a support ticket.

---

#### Q8 - How do you handle API discovery in a large platform?

API discovery is the problem of how a product engineer knows what platform
APIs exist and how to use them.

**Discovery mechanisms:**

Backstage Software Catalog: every platform API registered as an API
entity in Backstage with description, documentation link, and owner.
Teams discover platform APIs through the same catalog they use to
discover internal services.

kubectl discovery (for CRDs):
```bash
# List all platform CRDs
kubectl get crd -l platform.company.com/managed=true \
  -o custom-columns=NAME:.metadata.name,\
  VERSION:.spec.versions[0].name,\
  SCOPE:.spec.scope

# Describe the API schema
kubectl explain database.spec --recursive
```

CRD-generated documentation: tools like `crd-ref-docs` can generate
Markdown documentation from CRD OpenAPI schemas. This documentation
can be served in Backstage TechDocs or a standalone static site.

New service onboarding: when a team creates a new service, the
platform team (or onboarding automation) presents the available
platform APIs and guides the team to the relevant ones for their
use case.

*What separates good from great:* API discoverability is often neglected
until teams complain that they don't know what the platform offers. The
Backstage catalog entry is the minimum; the getting-started guide is what
makes the discovery actionable. A catalog entry that links to a getting-
started guide that produces a working deployment in 15 minutes turns
discovery into adoption.

---

#### Q9 - Describe a platform API design decision that taught you something important.

*Open question probing real-world experience. A strong answer:*

Context: designed a `Service` CRD for a Kubernetes-based platform.
Initial design exposed `spec.resources.requests.cpu` and
`spec.resources.limits.cpu` as explicit fields - we thought teams should
have control over their resource allocation.

What happened: 60% of teams set CPU limits incorrectly. The most common
mistake: setting limits much lower than requests (invalid - Kubernetes
requires limits >= requests). Second most common: setting limits to 100m
(default assumed for all services), causing CPU throttling on any service
under load. The platform team received 15+ support tickets per month
about CPU throttling.

The lesson: CPU resource configuration requires understanding of CFS
throttling, burst vs. sustained CPU usage, and the difference between
requests (scheduling) and limits (hard cap). Most product engineers
do not have this knowledge and should not need to.

The fix: replaced `resources.requests.cpu` and `resources.limits.cpu`
with `resources.tier` (small/medium/large), where each tier maps to a
pre-validated, production-tested combination of requests and limits.
CPU throttling tickets dropped to near zero.

What I learned: the correct API design question is not "what information
does the platform need?" but "what information should product teams be
responsible for?" CPU configuration requires platform expertise. Exposing
it puts platform expertise requirements on product teams. The tier-based
approach makes the correct choice the easy choice.

*What separates good from great:* The willingness to admit that an
initial API design was wrong, describe the specific failure mode it
caused, and explain the design decision that fixed it. This reveals
the learning process that produces good platform API design over time.

---

### ⚖️ Comparison Table

| API Design Approach | Cognitive Load on Consumer | Platform Control | Flexibility | Example |
|---|---|---|---|---|
| Passthrough (raw K8s) | Very High | None | Maximum | Raw kubectl apply |
| Thin wrapper CRD | High | Low | High | CRD with same fields as Deployment |
| Opinionated CRD with tiers | Low | High | Medium | Service CRD with resource tiers |
| Black box (no knobs) | Very Low | Complete | Minimum | "Deploy app" with no config options |

**The deciding factor:**
Target "opinionated CRD with tiers" - enough abstraction to remove
expertise requirements, enough flexibility to handle legitimate variation.
Black box APIs fail when legitimate edge cases arise; thin wrapper APIs
fail to reduce cognitive load.
