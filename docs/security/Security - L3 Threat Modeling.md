---
layout: default
title: "Security - L3 Threat Modeling"
parent: "Security"
nav_order: 7
permalink: /security/l3-threat-modeling/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Threat Modeling with STRIDE](#threat-modeling-with-stride) | high |
| 2 | [Security Anti-patterns: Homegrown Auth and Over-trust](#security-anti-patterns-homegrown-auth-and-over-trust) | high |

---

# Threat Modeling with STRIDE

---
id: SEC-016
title: "Threat Modeling with STRIDE"
category: Security
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: senior
tags: #security, #threat-modeling, #stride, #security-design
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Threat modeling is the process of identifying what can go wrong with a system
> before building it. STRIDE is a mnemonic for six threat categories: Spoofing,
> Tampering, Repudiation, Information Disclosure, Denial of Service, and Elevation
> of Privilege. Apply it to each component and data flow in your system diagram.
> For each threat, identify a mitigation.

**3 minutes (Senior):**
> STRIDE works by taking a system data-flow diagram (DFD) and asking "what can an
> attacker do to each element?" Spoofing: can they pretend to be a legitimate user
> or service? Mitigate with authentication. Tampering: can they modify data? Mitigate
> with integrity controls (HMAC, signatures). Repudiation: can they deny their actions?
> Mitigate with audit logs. Information Disclosure: can they read private data?
> Mitigate with encryption, access control. Denial of Service: can they disrupt
> availability? Mitigate with rate limiting, redundancy. Elevation of Privilege: can
> they gain more access than authorized? Mitigate with authorization and least privilege.
> The output of a threat model is a list of threats and mitigations - not a pass/fail
> score. STRIDE is most useful at design time; DREAD adds scoring but is controversial
> because it is subjective.

**Framework:** DFD → STRIDE each element → threat list → mitigation → residual risk

**Blank Mind Recovery:**

**(1) Restate:** "Threat modeling asks: what can go wrong with this design?
What could an attacker do? STRIDE gives a structured way to answer."

**(2) First principles:** "Security problems are not random - they follow patterns.
STRIDE names those patterns so you don't miss any during design review."

**(3) Bridge:** "STRIDE is like a pre-flight checklist for a pilot - each item
represents a known failure category; the checklist ensures you systematically
check every category rather than relying on memory."

---

### 📘 Concept Explanation

**What it is:**
Threat modeling is a structured process for identifying security threats during the
design phase. STRIDE (Microsoft) is a threat categorization framework. Each category
maps to a violated security property and a canonical mitigation strategy.

**The problem it solves:**
Ad-hoc security review misses entire categories of threats. A team focused on
authentication might forget about denial of service or audit logging. STRIDE provides
a systematic checklist ensuring coverage of all six threat categories.

**How it works:**

```
STRIDE THREAT CATEGORIES:

S - SPOOFING (violates: Authentication)
    Threat: attacker impersonates a user or service
    Mitigations: MFA, mutual TLS, JWT validation,
                 API key authentication

T - TAMPERING (violates: Integrity)
    Threat: attacker modifies data in transit/at rest
    Mitigations: HMAC, digital signatures,
                 HTTPS/TLS, AES-GCM

R - REPUDIATION (violates: Non-repudiation)
    Threat: user/attacker denies performing an action
    Mitigations: audit logs, digital signatures,
                 immutable log storage (WORM)

I - INFORMATION DISCLOSURE (violates: Confidentiality)
    Threat: attacker reads private data
    Mitigations: encryption, access control,
                 minimal error messages, least privilege

D - DENIAL OF SERVICE (violates: Availability)
    Threat: attacker prevents legitimate access
    Mitigations: rate limiting, circuit breakers,
                 redundancy, DDoS mitigation

E - ELEVATION OF PRIVILEGE (violates: Authorization)
    Threat: attacker gains access beyond authorization
    Mitigations: authorization checks, least privilege,
                 input validation, secure defaults
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the STRIDE mnemonic mapped to violated security properties and concrete mitigations. (2) KEY MECHANISM: each STRIDE category corresponds to one CIA/AAA property violation; knowing the category immediately suggests the mitigation family; S→Authentication, T→Integrity, R→Non-repudiation, I→Confidentiality, D→Availability, E→Authorization. (3) WHY IT MATTERS: teams that skip threat modeling miss whole categories - a team might have perfect authentication (S mitigated) but no rate limiting (D vulnerability). (4) WHAT BREAKS: applying STRIDE at the wrong granularity - per-system is too coarse (misses component-level threats); per-line-of-code is too fine; per-component and per-data-flow is the right level. (5) TAKEAWAY: draw the data-flow diagram first; apply STRIDE to each component (process, data store, external entity) and each data flow; document threats and mitigations.

**The key insight:**
Threat modeling is a conversation, not a checklist. The goal is to surface threats
the team has not considered before building. A 2-hour whiteboard session with STRIDE
before any code is written finds more threats than a pen test after launch.

**When to use it:**
New features with security implications. System integrations (new external service).
Any component handling authentication, authorization, or sensitive data. Annual
re-review of existing systems.

**When NOT to use it:**
STRIDE alone cannot capture all threat intelligence (zero-days, supply chain).
Supplement with threat intelligence feeds and OWASP-specific checklists.

**Alternatives:**
- PASTA (Process for Attack Simulation and Threat Analysis): attacker-centric
- LINDDUN: privacy-specific (STRIDE analog for GDPR)
- MITRE ATT&CK: tactical-level attack patterns library
- Attack Trees: hierarchical decomposition of attack goals

---

### 💻 Code Example

```java
// Threat modeling output drives security requirements

// STRIDE analysis of PaymentService.process():
// S: Spoofing - caller must be authenticated merchant
// T: Tampering - amount cannot be modified in transit
// R: Repudiation - every transaction logged with actor
// I: Info Disclosure - card data encrypted; not logged
// D: DoS - rate limited per merchant; idempotency key
// E: EoP - merchants can only access their own orders

@Service
public class PaymentService {
    private final AuditLog auditLog;
    private final RateLimiter rateLimiter;

    // S: authenticated merchant (JWT validated by gateway)
    @PreAuthorize("hasRole('MERCHANT')")
    // T: amount in signed JWT - cannot be tampered
    // I: card data validated by Stripe (never touches us)
    // D: rate limited per merchant
    public PaymentResult process(
            @Valid PaymentRequest req,
            Authentication auth) {

        // Rate limit check (D: DoS prevention)
        rateLimiter.check(auth.getName());

        // E: verify merchant owns this order
        if (!orderService.belongsTo(
                req.getOrderId(), auth.getName())) {
            throw new ForbiddenException();
        }

        // R: audit log with actor and full context
        auditLog.record(AuditEvent.builder()
            .actor(auth.getName())
            .action("payment.process")
            .resourceId(req.getOrderId())
            .amount(req.getAmount())
            .build());

        return paymentGateway.charge(req);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: STRIDE analysis comments driving specific security controls in the code - each STRIDE threat translates to at least one concrete implementation. (2) KEY MECHANISM: the STRIDE comments document the threat-to-mitigation mapping inline; reviewers can verify each threat is addressed; new threats discovered in review get controls added. (3) WHY IT MATTERS: without STRIDE analysis, developers add security controls reactively based on what they remember; the STRIDE comments make the threat model visible in the code where enforcement happens. (4) WHAT BREAKS: threat model in a separate document not referenced during code review; code and threat model drift apart; STRIDE comments in code keep them synchronized. (5) TAKEAWAY: document the threat model as comments on the security boundary (service class, method, API controller); reviewers verify mitigations are present; new contributors understand the security intent.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> STRIDE stands for Spoofing, Tampering, Repudiation, Information Disclosure, Denial
> of Service, Elevation of Privilege. It's a checklist for security threats. Draw your
> system diagram and ask "can an attacker do any of these six things to each component?"
> Each category points to a mitigation: authentication for spoofing, audit logs for
> repudiation, rate limiting for DoS.

---

**Senior / Staff (5+ years):**
> The value of STRIDE is at the whiteboard before code is written. A 2-hour threat
> modeling session finds architectural flaws - missing authentication between internal
> services (S), no audit log for financial transactions (R), shared database access
> without row-level isolation (E) - that are expensive to retrofit. My process: draw
> the DFD (processes, data stores, external entities, data flows with trust boundaries);
> apply STRIDE per element; for each threat: assign a risk rating (likelihood × impact);
> identify the mitigation; assign an owner. The output drives security requirements.
> At the staff level: I also apply STRIDE to the threat model's own attack surface -
> can someone spoof the threat modeling process by providing false information about
> system scope? That leads to threat modeling governance.

---

### ⚠️ Common Misconceptions

**Misconception 1: Threat modeling is only for security teams.**

The engineer building the feature understands it best and should own the threat
model. Security teams facilitate and review, not dictate. A threat model done by
security-only (without the engineers) misses implementation-level threats.

**Misconception 2: STRIDE produces a pass/fail security score.**

STRIDE produces a list of threats and mitigations. There is no passing grade.
Every system has residual risk; the goal is to make conscious decisions about which
risks are accepted (with rationale) vs which are mitigated. The output is a threat
register, not a compliance certificate.

**Misconception 3: Threat modeling is only for new systems.**

Existing systems benefit from annual threat model reviews as the threat landscape
evolves. A system secure in 2020 may face new threats from changed attacker
capabilities, new integrations, or new data it now handles.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Threat model produced but not acted on.**

Symptom: threat model document exists but identified mitigations never implemented.
Diagnosis: check if threat model outputs are tracked as requirements or tickets.
Fix: threat model findings go into the backlog as P1/P2 items; security review
blocks release if high-severity threats are unmitigated.

**Failure Mode 2: Threat model scope too narrow (missing trust boundaries).**

Symptom: internal service-to-service communication not modeled; attacker reaching
a compromised internal service exploits assumed trust.
Diagnosis: DFD does not show trust boundaries between internal components.
Fix: model every network hop as a potential attacker pivot; do not assume internal
services are trusted; apply mTLS and authorization even between internal services.

**Failure Mode 3: Threat model not updated after significant changes.**

Symptom: new integrations or data flows added without STRIDE analysis; new attack
surface introduced without mitigation.
Fix: require threat model update for any change that: adds a new external integration,
changes authentication/authorization flow, adds a new data type, or crosses a trust boundary.

---

### ⚖️ Comparison Table

| Method | Focus | Output | Best For |
|---|---|---|---|
| **STRIDE** | Threat categorization | Threat/mitigation list | Design review |
| **PASTA** | Attacker simulation | Attack scenarios | Risk-driven design |
| **LINDDUN** | Privacy threats | Privacy risk register | GDPR compliance |
| **ATT&CK** | Tactical attacks | TTPs mapped to detections | SOC/detection engineering |
| **Attack Trees** | Attack decomposition | Hierarchical attack paths | Complex targeted attacks |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Zero-trust architecture threat modeling covered in L5 entries.)*

---

### 📊 Diagram

*(Omit: STRIDE table in Concept Explanation provides the full visual structure.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | STRIDE categories, DFD |
| Mechanism | 2 | Process, threat rating |
| Application | 2 | Login design, microservices |
| Trade-off | 2 | STRIDE vs PASTA, scope choices |
| Behavioral | 1 | Running a session |

---

**[MID] Q1 (Definition): What does each letter of STRIDE stand for and what security property does it violate?**

STRIDE is a mnemonic covering six threat categories:

S - Spoofing: attacker impersonates a legitimate user, service, or process.
Violates: Authentication. An attacker claims to be alice@company.com to gain unauthorized
access. Mitigation: strong authentication (MFA, JWT validation, mTLS).

T - Tampering: attacker modifies data in transit or at rest without authorization.
Violates: Integrity. An attacker modifies a financial transaction amount.
Mitigation: HMAC, digital signatures, TLS, AES-GCM (authenticated encryption).

R - Repudiation: attacker or malicious user denies performing an action.
Violates: Non-repudiation. A user denies placing a fraudulent order.
Mitigation: audit logs with actor, timestamp, and action; signed logs; digital signatures on transactions.

I - Information Disclosure: attacker reads private data they should not see.
Violates: Confidentiality. An attacker reads another user's medical records.
Mitigation: encryption at rest and in transit, access control, minimal error messages.

D - Denial of Service: attacker prevents legitimate users from accessing the service.
Violates: Availability. An attacker floods the login endpoint with 10M requests.
Mitigation: rate limiting, circuit breakers, DDoS mitigation infrastructure.

E - Elevation of Privilege: attacker gains access or capabilities beyond authorization.
Violates: Authorization. A regular user accesses admin functionality.
Mitigation: authorization checks on every request, least-privilege design, input validation.

*What separates good from great:* Immediately connecting each category to the CIA/AAA
triad. Every security requirement maps to one of these categories; using STRIDE at
design time ensures no security property is overlooked.

---

**[MID] Q2 (Definition): What is a data-flow diagram and how does it drive STRIDE analysis?**

A data-flow diagram (DFD) for threat modeling depicts how data moves through a system,
who the actors are, and where trust boundaries exist.

DFD elements:
- External entities: users, external services, partners (outside trust boundary)
- Processes: application components that transform data
- Data stores: databases, caches, file systems, queues
- Data flows: arrows showing data movement between elements
- Trust boundaries: lines separating zones of different trust (internet / DMZ / internal)

STRIDE is applied to each element:
- Processes: S, T, R, I, D, E (all six apply)
- Data stores: T, R, I, D (tampering, repudiation, disclosure, DoS)
- Data flows: S, T, I (spoofing, tampering, disclosure)
- External entities: S, R (they can claim false identity and deny actions)

The trust boundary is the most important element: every data flow crossing a trust
boundary requires an explicit threat analysis because those are the points where an
external attacker enters.

*What separates good from great:* Drawing the DFD with threat boundaries exposes
architectural assumptions - "we trust all internal services" is a trust boundary
assumption that, when made explicit, immediately generates S and E threats for internal
service impersonation and privilege escalation.

---

**[SENIOR] Q3 (Mechanism): How do you prioritize threats from a STRIDE analysis?**

After listing threats, prioritization decides what to mitigate immediately vs accept.

DREAD scoring (historical, now considered too subjective):
D - Damage potential, R - Reproducibility, E - Exploitability, A - Affected users,
D - Discoverability. Score each 0-10, average. Higher = higher priority.

Modern approach - risk matrix: Likelihood × Impact.

Likelihood factors: is the attack path exposed (internet vs internal)? Does it require
authentication? Does it require special knowledge or tools? Is there an existing
exploit for this class?

Impact factors: what data is affected (PII, financial, health)?
How many users are affected? What is the business impact (regulatory, reputational)?
Is it reversible (data can be restored) or irreversible (exfiltrated data)?

Categorize into: Critical (mitigate before launch), High (mitigate within sprint),
Medium (track in backlog), Low/Informational (document and accept).

*What separates good from great:* The "accepted risk" discipline. Not all threats
are cost-effective to mitigate. A theoretical attack requiring physical access to
an internal data center may be accepted with compensating controls (camera, badge).
Document the acceptance: what the threat is, why it is accepted, what compensating
control exists, and who approved it.

---

**[SENIOR] Q4 (Application): Apply STRIDE to a user login endpoint.**

Data flow: browser → load balancer → login-service → auth-db.

Spoofing threats:
- Attacker submits valid credentials stolen from another service (credential stuffing).
  Mitigation: per-account rate limiting, MFA, breach password check.
- Attacker spoofs the login service to harvest credentials.
  Mitigation: HTTPS certificate pinning in native apps.

Tampering threats:
- Attacker intercepts and modifies password in transit.
  Mitigation: TLS in transit; HTTPS enforced with HSTS.
- Attacker modifies the session token after issuance.
  Mitigation: signed JWT or session token tied to server-side record.

Repudiation threats:
- User denies logging in from a new device.
  Mitigation: login audit log with IP, device fingerprint, timestamp.

Information Disclosure:
- Error messages reveal whether username exists.
  Mitigation: identical response for invalid username and wrong password.
- Session token leaked via Referer header.
  Mitigation: Referrer-Policy: same-origin header.

Denial of Service:
- Flood of login requests exhausts authentication service.
  Mitigation: rate limiting at gateway; per-account limits.

Elevation of Privilege:
- Attacker redirects OAuth flow to their domain after successful auth.
  Mitigation: strict redirect_uri allowlist; state parameter CSRF protection.

*What separates good from great:* Applying STRIDE to the redirect flow, not just the
login form. OAuth redirect_uri attacks (open redirects, code injection) are E threats
that are frequently missed when teams focus only on the credential submission.

---

**[SENIOR] Q5 (Application): How do you apply STRIDE to internal microservices?**

Common mistake: internal services are implicitly trusted, so no STRIDE analysis.
This breaks when one service is compromised and used as a pivot.

Apply STRIDE to every inter-service call:

Spoofing: can a compromised service claim to be a different service?
Mitigation: mTLS for service-to-service authentication; JWT with service-specific audience claim.

Tampering: can a compromised network component modify inter-service requests?
Mitigation: TLS encryption on internal network; message signing for critical operations.

Repudiation: if service A charges service B for an action, can A deny it later?
Mitigation: distributed tracing with correlation IDs; structured audit logs.

Information Disclosure: does service A need all the data it receives from B?
Mitigation: data minimization - service A should not send PII to service B unless
service B explicitly needs it.

Denial of Service: can a flood of calls from service A overwhelm service B?
Mitigation: inter-service rate limiting and circuit breaking.

Elevation of Privilege: can service A call an admin endpoint of service B?
Mitigation: service-level RBAC; service B checks the calling service's identity
and permissions before executing privileged operations.

*What separates good from great:* Blast-radius analysis. If service A is compromised,
what is the maximum damage it can cause? By applying STRIDE to inter-service calls,
you discover that a compromised notification service (low-privilege) should not have
read access to the payments service (high-privilege). Least-privilege between services
limits blast radius.

---

**[SENIOR] Q6 (Mechanism): What is the difference between STRIDE and ATT&CK?**

STRIDE is a design-time threat categorization: it asks "what categories of threats
apply to this design?" and drives security requirements. Applied during architecture
review, before code is written.

MITRE ATT&CK is a tactical knowledge base of adversary behaviors observed in real
attacks. Organized as: Initial Access → Execution → Persistence → Privilege Escalation
→ Defense Evasion → Credential Access → Discovery → Lateral Movement → Collection
→ Exfiltration → Command and Control.

ATT&CK is used by:
- Red teams: which TTPs should we simulate in this engagement?
- Blue teams: which ATT&CK techniques are our detections covering?
- Threat intelligence: what TTPs is the APT group targeting our industry using?

They complement each other. STRIDE threat modeling identifies "there is an elevation
of privilege threat via SSRF." ATT&CK provides the specific technique (T1590 - Gather
Victim Network Information via server-side request forgery) and the concrete detection
signals (outbound requests from server to internal IP ranges). STRIDE finds the
category; ATT&CK refines to the technique and detection.

*What separates good from great:* Using ATT&CK to make STRIDE mitigations concrete.
For each STRIDE threat, look up the relevant ATT&CK technique and use it to define
specific detection rules and alerting thresholds.

---

**[SENIOR] Q7 (Trade-off): When should you use STRIDE vs PASTA?**

STRIDE is component-centric: for each component in the DFD, ask which of the six
threat categories apply. Simple to apply, well-known, good for developer-led sessions.

PASTA (Process for Attack Simulation and Threat Analysis) is attacker-centric: it
models the attacker's goals, builds attack trees, and maps to business risk. Seven stages:
define business objectives, define technical scope, application decomposition, threat analysis,
vulnerability analysis, attack modeling, risk analysis.

Choose STRIDE when:
- Development team is driving the threat model
- Design-time review; building security requirements
- Team is new to threat modeling; STRIDE has lower learning curve
- Agile/sprint-based work; need to complete in 2-4 hours

Choose PASTA when:
- Risk-based, attacker-goal-driven analysis needed
- Compliance requirement for formal threat documentation
- External audit expects structured risk quantification
- Sufficient time and expertise available (PASTA is a multi-day process)

In practice: most teams use STRIDE for regular feature reviews and PASTA for
annual system-wide security assessments.

*What separates good from great:* Recognizing that no single methodology covers
everything. STRIDE + OWASP Top 10 checklist + MITRE ATT&CK together provide systematic
coverage from different angles: design-time categories, common web vulnerabilities,
and real-world attack techniques.

---

**[SENIOR] Q8 (Trade-off): How do you handle threats you cannot mitigate due to cost or technical constraint?**

Not every threat can be mitigated. Budget constraints, technical limitations, and
business priorities mean some threats are accepted.

Accepted risk process:

1. Document the threat explicitly: what the threat is, the attack path, estimated
   probability, and potential impact.

2. Define compensating controls: even if the primary mitigation is unavailable, can
   you reduce likelihood or impact? Example: cannot implement MFA for a legacy system;
   compensating control is network isolation (only reachable from corporate VPN).

3. Get explicit risk acceptance: a named risk owner (CISO, VP Engineering, product
   owner) reviews and accepts in writing. Verbal acceptance does not count.

4. Set a review date: accepted risks must be reviewed periodically. A risk accepted
   because the technical solution did not exist may be revisable in 6 months.

5. Enter in a risk register: tracked alongside all other open risks; visible to
   leadership; auditors can verify the risk management process.

What is not acceptable:
- Implicit acceptance (nobody decided; threat was just not addressed)
- Permanent acceptance without review date
- Risk acceptance by people without authority to accept

*What separates good from great:* Understanding that risk acceptance is a business
decision, not a security decision. Security identifies and characterizes the risk;
the business decides whether to accept it. Security's job is to ensure the decision
is informed and documented, not to make the business accept every risk.

---

**[STAFF] Q9 (Behavioral): Walk me through how you would run a threat modeling session for a new checkout feature.**

Preparation (1 week before): invite the engineer building the feature, the product
owner, and a security reviewer. Ask the engineer to prepare a data-flow diagram: what
are the inputs, what systems are involved, where is data stored, what external services
are called?

Session structure (2-3 hours):

Open (15 min): scope the session. What specific scenario are we modeling? "User
completing a checkout: add to cart through payment confirmation." Out of scope for
this session: account management, fulfillment.

DFD walkthrough (30 min): engineer walks through the DFD. Identify trust boundaries.
Note: "browser → API gateway" is one trust boundary; "API gateway → payment-service"
is another; "payment-service → Stripe" is a third.

STRIDE per element (90 min): take each process, data store, data flow, and external
entity. For each: ask each STRIDE letter. Document every threat identified.

Prioritize (20 min): for each threat, assign likelihood and impact.
High likelihood + high impact = critical. Mark each: mitigate now, track in backlog, accept.

Assign owners (5 min): every critical and high item gets an owner and a due date.

Output: threat register document (threats, mitigations, owners, due dates) in the
team's wiki. Link from the PR that implements the feature. Update when significant
changes occur.

*What separates good from great:* Running the session as a conversation, not a
documentation exercise. The goal is to surface threats nobody had considered. When
the session is dominated by writing rather than thinking, it has become a compliance
checkbox. The most valuable output is the two or three threats the engineer had not
considered before the session.

---

---

# Security Anti-patterns: Homegrown Auth and Over-trust

---
id: SEC-017
title: "Security Anti-patterns: Homegrown Auth and Over-trust"
category: Security
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #security, #anti-patterns, #authentication, #authorization
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Homegrown authentication is the #1 security anti-pattern: building your own login
> system, session management, or JWT library instead of using mature battle-tested
> frameworks. Over-trust is the second: assuming internal services, headers, or
> initial input validation is sufficient for authorization decisions later in the
> code. Both lead to preventable breaches.

**3 minutes (Senior):**
> Homegrown auth fails because security is subtle: timing attacks in password
> comparison, weak token generation, predictable session IDs, JWT algorithm confusion
> - these require deep expertise to avoid. Spring Security, Auth0, and Cognito
> have had thousands of security experts and real-world attack experience applied
> to them. Over-trust manifests as: trusting `X-User-ID` headers from the calling
> service without verifying them, trusting input validation from a previous layer,
> trusting that a JWT was validated by a downstream service. Defense in depth means
> re-validating at every trust boundary. The fix for both: use established frameworks
> and libraries, and apply "never trust, always verify" at every layer.

**Framework:** Pattern → Symptom → Root cause → Correct approach

**Blank Mind Recovery:**

**(1) Restate:** "The worst security anti-patterns are building auth from scratch
and assuming someone else already validated input."

**(2) First principles:** "Authentication and authorization are solved problems.
Re-solving them introduces bugs. Trust propagated from one layer must be re-verified
at the next."

**(3) Bridge:** "Homegrown auth is like building your own airplane instead of buying
one. Over-trust is like a nightclub bouncer who checks ID at the door but trusts
anyone already inside."

---

### 📘 Concept Explanation

**What it is:**
Security anti-patterns are recurring implementation choices that introduce vulnerabilities.
Homegrown authentication builds custom implementations of well-solved security primitives.
Over-trust propagates unverified assumptions from one security layer to another.

**The problem it solves:**
Identifying these patterns allows teams to replace them before breaches occur. Both
are common in large codebases and difficult to find via standard code review.

**How it works (anti-patterns):**

```
HOMEGROWN AUTH ANTI-PATTERNS:

  BAD: Custom password hashing
    sha256(password + "salt123")
    GPU: 10B guesses/sec -> cracked in minutes

  BAD: Custom session token generation
    token = username + timestamp.toString()
    Predictable -> session hijacking

  BAD: Custom JWT validation
    jwt.split(".")[1] -> base64decode -> read claims
    Missing: signature verification!

  BAD: Homegrown role system in application code
    if (user.role == "admin") { ... }
    Scattered everywhere, no central policy,
    easy to miss one endpoint

  CORRECT: Use established frameworks:
    - Passwords: Argon2id via Spring Security
    - Sessions: Spring Session (Redis-backed)
    - JWT: Nimbus-JOSE or Auth0 java-jwt
    - Authorization: Spring Security @PreAuthorize
    - Identity: Keycloak, Auth0, AWS Cognito
```

> **Code walkthrough:** (1) WHAT IT SHOWS: four homegrown auth anti-patterns and their specific failure modes. (2) KEY MECHANISM: each anti-pattern attempts to re-implement a security primitive with subtly wrong assumptions; timing attacks in string comparison, predictable tokens, missing JWT signature verification - each is a known vulnerability class. (3) WHY IT MATTERS: established frameworks are built by security experts who have encountered and fixed these failure modes; rolling your own means re-discovering each vulnerability through your own breach. (4) WHAT BREAKS: custom JWT decode without verification trusts claims without proof - the most dangerous form is skipping signature verification entirely, accepting any payload. (5) TAKEAWAY: the correct framework for authentication exists and is well-maintained; using it is not laziness, it is risk management.

```
OVER-TRUST ANTI-PATTERNS:

  BAD: Trusting X-User-ID header
    // Service B receives from service A:
    String userId = request.getHeader("X-User-Id");
    // If attacker reaches service B directly,
    // they set any X-User-Id they want -> IDOR

  BAD: Trusting previous layer's validation
    // Controller validated input, service trusts it:
    void processPayment(String accountId) {
        // assumes accountId was validated upstream
        // SQL injection possible if controller skipped
        db.query("SELECT * WHERE id="+accountId);
    }

  BAD: Trusting internal network location
    // "Only internal services can reach this port"
    // No authentication required on port 8080
    // One compromised service = full access

  CORRECT: Verify at every layer
    - Inter-service: mTLS + JWT with audience claim
    - Input: validate at the function boundary
    - Authorization: check at the resource access point
```

> **Code walkthrough:** (1) WHAT IT SHOWS: three over-trust anti-patterns where each layer assumes another layer already handled security. (2) KEY MECHANISM: each trust chain has a single point of failure; if any upstream validation is bypassed or incorrect, all downstream code runs with false assumptions about the safety of the input. (3) WHY IT MATTERS: a compromised internal service can set any X-User-ID header, making IDOR trivial across the entire microservice mesh; defense-in-depth requires re-validation at each trust boundary. (4) WHAT BREAKS: service B validating that X-User-ID is a valid UUID satisfies nobody - validation without authentication means the header content is still attacker-controlled; the source of the header must be authenticated. (5) TAKEAWAY: validate inputs at the function boundary where they are used; authenticate callers at every service boundary regardless of network location.

**The key insight:**
Both anti-patterns stem from the same root cause: optimizing for development speed
over security. "It's too complex to add authentication between internal services."
"Our JWT library validates it, we just need to decode." The cost of a breach is
always higher than the cost of doing it right.

**When to use it:**
Always avoid these patterns. They arise under time pressure or with developers
unfamiliar with security requirements.

**Alternatives:**
- Homegrown auth → Auth0, Keycloak, AWS Cognito (identity providers)
- Custom JWT validation → Nimbus-JOSE, Auth0 jwt library (comprehensive validation)
- Over-trust → mTLS, service mesh (Istio), OPA sidecar for authorization

---

### 💻 Code Example

```java
// BAD: Homegrown password reset token
// Predictable token -> account takeover
public String generateResetTokenBad(String email) {
    // BAD: MD5 of email + timestamp is brute-forceable
    String token = DigestUtils.md5Hex(
        email + System.currentTimeMillis());
    resetTokens.put(token, email);
    return token;
}

// GOOD: Cryptographically secure token
public String generateResetToken(String email) {
    byte[] bytes = new byte[32];
    new SecureRandom().nextBytes(bytes);
    // URL-safe Base64, 256 bits of entropy
    String token = Base64.getUrlEncoder()
        .withoutPadding()
        .encodeToString(bytes);
    // Store hash of token, not token itself
    String tokenHash = DigestUtils.sha256Hex(token);
    resetTokens.put(tokenHash, email);
    return token;  // only returned once, never stored
}

public boolean validateResetToken(
        String token, String email) {
    String tokenHash = DigestUtils.sha256Hex(token);
    String storedEmail = resetTokens.get(tokenHash);
    // Constant-time comparison prevents timing attack
    return storedEmail != null
        && MessageDigest.isEqual(
            storedEmail.getBytes(),
            email.getBytes())
        && resetTokens.remove(tokenHash) != null;
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: homegrown password reset token generation (predictable, weak) vs cryptographically secure token generation with correct storage (hashed) and comparison (constant-time). (2) KEY MECHANISM: `SecureRandom` provides 256 bits of entropy making the token infeasible to brute-force; storing the SHA-256 hash prevents the token from being extracted if the token store is compromised; constant-time comparison prevents timing attacks where an attacker infers whether they have the correct prefix. (3) WHY IT MATTERS: predictable tokens (MD5 of email + timestamp) can be brute-forced in minutes; if tokens are stored in plaintext, a database breach allows attackers to generate password resets for all users. (4) WHAT BREAKS: single-use enforcement via `resetTokens.remove` in the validate method; if the removal fails, the token can be used multiple times. (5) TAKEAWAY: reset tokens need 256+ bits of entropy; store only the hash; use constant-time comparison; single-use with expiry.

```java
// BAD: Over-trust - X-Forwarded-User header
@GetMapping("/account/{id}")
public Account getAccountBad(
        @PathVariable Long id,
        HttpServletRequest request) {
    // BAD: trusts header that any caller can forge
    String userId = request.getHeader(
        "X-Forwarded-User");
    // Attacker sets header to any user ID -> IDOR
    return accountService.getForUser(id, userId);
}

// GOOD: Extract identity from validated JWT
@GetMapping("/account/{id}")
public Account getAccountGood(
        @PathVariable Long id,
        // Authentication extracted from validated JWT
        // by Spring Security filter chain
        Authentication auth) {
    String userId = auth.getName();
    // userId is from signed JWT - cannot be forged
    if (!accountService.belongsTo(id, userId)) {
        throw new ResponseStatusException(
            HttpStatus.FORBIDDEN);
    }
    return accountService.findById(id);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the over-trust anti-pattern (trusting a forwarded header) versus the correct pattern (extracting identity from the validated JWT in the Authentication object). (2) KEY MECHANISM: Spring Security's JWT filter validates the token signature, expiry, and claims before the request reaches the controller; `auth.getName()` returns the subject from a cryptographically verified token, not an attacker-controllable header. (3) WHY IT MATTERS: headers can be set by any HTTP client; a gateway that strips and replaces X-Forwarded-User works only until an attacker bypasses the gateway or the gateway has a misconfiguration. (4) WHAT BREAKS: trusting `auth.getName()` without checking that the authenticated user is authorized for the specific resource ID - authentication (who are you) and authorization (are you allowed this resource) are separate checks. (5) TAKEAWAY: identity must come from a cryptographically verified source (JWT, mTLS client certificate); HTTP headers are data, not proof of identity.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Homegrown authentication means building your own login system or JWT handling
> instead of using established libraries. This is dangerous because security has subtle
> edge cases. Over-trust means assuming a previous layer already handled security.
> Fix: use Spring Security for authentication; validate inputs at the boundary where
> they are used; get user identity from JWT, not from headers.

---

**Senior / Staff (5+ years):**
> Homegrown auth is most dangerous as a gradual accumulation. It starts with "we'll
> just decode the JWT ourselves" and grows into custom token issuance and custom
> session management. The fix is to use an identity provider (Keycloak, Auth0,
> Cognito) and treat it as an external service - your application is an OAuth2
> resource server, not an auth server. For over-trust: in a microservices architecture,
> I enforce mTLS between all services and use OPA sidecars for authorization decisions.
> The service mesh (Istio/Linkerd) provides identity at the network level; every service
> knows exactly which other service is calling it.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Our network is private, so we don't need auth between services."**

Network perimeters are not security boundaries. One compromised service or a misconfigured
firewall rule provides access to the entire internal network. Zero-trust principles:
authenticate every service call regardless of network location; never trust based on
IP address or network segment.

**Misconception 2: "We use HTTPS, so our tokens are safe."**

HTTPS protects data in transit between client and server. Once the token is issued,
HTTPS is irrelevant: a token stored in localStorage is XSS-exposed; a token in
a URL is logged in server access logs; a token in a long-lived cookie is CSRF-exposed.
Token security requires proper storage, scope, and lifetime management.

**Misconception 3: "We validate inputs at the API boundary, so inner layers can trust them."**

Input validation at the boundary prevents specific attack payloads from entering.
Authorization must still be verified at the resource access point: whether the
validated, legitimate input is authorized for the authenticated user. These are
separate concerns. A valid API request from an authenticated user may still be
unauthorized for a specific resource.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: JWT decoded but not verified.**

Symptom: endpoint accepts any JWT payload regardless of signature validity.
Diagnosis: Search for `base64.decode(jwt.split(".")[1])` without subsequent signature
verification. Or `alg: none` accepted.
Fix: use a JWT library; provide the public key for verification; never accept alg:none;
use strongly typed key objects to prevent algorithm confusion.

**Failure Mode 2: Custom session token using predictable data.**

Symptom: session tokens enumerable or predictable; session fixation possible.
Diagnosis: analyze token structure; check entropy; test if tokens follow a sequence.
Fix: use `SecureRandom` with at minimum 128 bits of entropy; store the hash, not
the token; set short expiry.

**Failure Mode 3: Service-to-service call with forged identity header.**

Symptom: internal service B accepts caller identity from HTTP header without verifying
caller identity.
Diagnosis: trace where `X-User-ID`, `X-Internal-Service`, or similar headers are set
and consumed; verify that consumers authenticate the source before trusting the header.
Fix: mutual TLS between services; identity propagated via signed JWT with service audience;
strip all custom identity headers at the ingress gateway before passing to services.

---

### ⚖️ Comparison Table

| Anti-pattern | Attack vector | Impact | Correct approach |
|---|---|---|---|
| **Custom password hash** | GPU brute force on breach | All passwords cracked | Argon2id / bcrypt |
| **Predictable session token** | Session hijacking | Account takeover | SecureRandom 256-bit |
| **JWT without verification** | Token forgery | Authentication bypass | Library with key type enforcement |
| **Trusting X-User-ID** | Header injection IDOR | Any user's data | JWT identity from Spring Security |
| **No inter-service auth** | Lateral movement | Full internal access | mTLS + JWT audience |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Zero-trust service mesh architecture covered in L5 entries.)*

---

### 📊 Diagram

*(Omit: ASCII code blocks in Concept Explanation illustrate both anti-patterns explicitly.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Homegrown auth risks, over-trust |
| Mechanism | 2 | Token security, trust chains |
| Scenario | 2 | Code review, service mesh |
| Trade-off | 2 | Framework vs custom, convenience vs security |
| Behavioral | 1 | Security culture |

---

**[MID] Q1 (Definition): Why is homegrown authentication dangerous? Give three specific examples.**

Homegrown authentication re-implements security primitives that require deep expertise
to implement correctly. The danger is that mistakes are subtle and not visible in
normal testing.

Example 1 - Custom password hashing: using SHA-256 or MD5 instead of bcrypt/Argon2.
Symptom: database breach results in rapid password cracking. Root cause: fast hashes
allow 10 billion guesses per second on a GPU. Correct: Argon2id with memory-hard parameters.

Example 2 - Predictable session tokens: using sequential numbers, timestamps, or
MD5(username+timestamp). Symptom: attacker enumerates valid sessions by brute-force.
Root cause: insufficient entropy makes the token guessable. Correct: 256 bits from
SecureRandom, URL-safe Base64 encoded.

Example 3 - Custom JWT parsing without verification: splitting the JWT and JSON-decoding
the payload to read claims without verifying the signature. Symptom: attacker creates
an arbitrary JWT with admin claims and the application accepts it. Root cause: the
signature was never checked. Correct: use a JWT library that requires a signing key
and verifies by default.

*What separates good from great:* The fourth example that is less obvious: custom
role check propagation. `if (user.role == "admin")` scattered across hundreds of
endpoints. An admin endpoint added by a new developer that forgets the check. Role
checks in code are the most subtle homegrown auth pattern.

---

**[SENIOR] Q2 (Mechanism): What is the algorithm confusion attack in JWT and how do you prevent it?**

JWT headers specify the algorithm. A server configured for RS256 (asymmetric, public
key verification) can be confused if an attacker crafts an HS256 token (symmetric,
HMAC) and uses the RS256 public key as the HMAC secret.

Attack: the RS256 public key is public. The attacker crafts a JWT with `"alg": "HS256"`.
They sign it with HMAC-SHA256 using the public key as the secret. A vulnerable validator
that dynamically selects the algorithm from the token header and has access to the
public key (for HMAC as a byte array) verifies it successfully.

Why it works: the validator accepts the HS256 signature because it verifies correctly
with the public key as the HMAC secret. The attacker can create arbitrary payloads.

Prevention:
1. Use strongly typed key objects: pass a `java.security.PublicKey` to the JWT library.
   The type system prevents it from being used as an HMAC secret (different types).
2. Hard-code the expected algorithm: `JWTVerifier.build(Algorithm.RSA256(publicKey))`
   - ignore the algorithm in the token header.
3. Use a JWT library with algorithm confusion prevention built in (Nimbus-JOSE, jjwt 0.11+).

*What separates good from great:* Understanding the second variant. If the library
accepts both `Algorithm.RSA256` and `Algorithm.HS256` based on the token header,
an attacker creates HS256 tokens. Fix: accept only the specific algorithm expected
from the specific issuer; validate issuer before algorithm.

---

**[SENIOR] Q3 (Mechanism): How does over-trust manifest in microservice architectures?**

Over-trust in microservices appears when services propagate identity and trust claims
as HTTP headers without cryptographic verification.

Pattern 1 - Identity header propagation: gateway authenticates the user, strips
credentials, and sets `X-User-ID: alice`. Internal services trust this header. Attack:
a service that is directly reachable (misconfigured firewall, service mesh gap) receives
a request with `X-User-ID: admin`.

Pattern 2 - Service identity claims: service A calls service B with
`X-Calling-Service: payment-service`. Service B grants elevated privileges to
`payment-service`. Attack: any service can send this header; there is no verification
that the caller IS the payment service.

Pattern 3 - Validated flag propagation: gateway sets `X-Input-Validated: true` after
running input validation. Internal services skip validation when this flag is set.
Attack: direct call to internal service sets the flag.

Correct pattern: service-to-service identity via mTLS (client certificate identifies
the caller) or JWT with `aud: specific-service` claim, signed by the issuer the
recipient trusts. The identity is in the signed certificate or token; it cannot be forged by headers.

*What separates good from great:* The service mesh solution. Istio/Linkerd injects
a sidecar that terminates mTLS and provides the caller's service account identity as
an authenticated fact. The application receives the identity without managing TLS or
JWT directly. Zero-trust networking with zero application changes.

---

**[SENIOR] Q4 (Scenario): You are reviewing a PR that adds a new admin endpoint. What security checks do you perform?**

A new admin endpoint is high risk: typically has elevated permissions and may expose
powerful operations. Security review covers authentication, authorization, input
handling, audit, and rate limiting.

Authentication: is the endpoint protected by authentication? Check for
`@PreAuthorize`, `@Secured`, or equivalent. Test: access the endpoint without a
token - expect 401.

Authorization: is the caller authorized for the admin action specifically? Role check
(`hasRole('ADMIN')`)? Or better, permission check (`hasPermission('users:manage')`)
that allows the role to change without code changes?

Object-level authorization: if the endpoint takes an ID parameter, is there a check
that the admin is authorized for that specific object? Even admins may have scoped
access in multi-tenant systems.

Input validation: is the input annotated with `@Valid`? Are all string inputs validated
for type, length, and content? Specifically for admin endpoints: are bulk operation
limits enforced (e.g., max 100 items in a batch delete)?

Audit log: every admin operation must be logged with actor, action, target, timestamp.
Admins are the primary repudiation risk; audit logs are the mitigation.

Rate limiting: admin endpoints are high-value targets. They should have their own
rate limiting (stricter than standard APIs) to prevent enumeration and brute-force.

*What separates good from great:* Testing the negative path. Call the endpoint as a
non-admin authenticated user. Expect 403, not 404 or 500. A 404 from an admin
endpoint may be information disclosure (confirming the endpoint exists to an attacker).

---

**[SENIOR] Q5 (Trade-off): When is it acceptable to build a custom authentication component?**

Almost never for the core authentication flow. Identity providers (Auth0, Keycloak,
Cognito, Okta) are purpose-built for authentication and have years of security
hardening, compliance certifications, and active security maintenance. Building a
competing system from scratch is never justified for standard authentication.

Acceptable customization:
- Custom claims in JWT (using standard issuer infrastructure)
- Custom MFA flows (adding a step to a standard flow)
- Custom user attributes and profile management
- Custom login UI (federation back to standard token issuance)

Not acceptable:
- Custom token generation and signing
- Custom password hashing
- Custom session management
- Custom JWT validation library

The test: "Has this been reviewed by security researchers? Has it handled a large-scale
breach attempt and been found sound?" Established libraries pass this test. Custom
code never does by definition.

*What separates good from great:* The nuance for regulated industries. Healthcare
and finance may have specific requirements (FIPS 140-2 validated modules, specific
algorithm restrictions) that standard libraries satisfy. The path is to find a
compliant library, not to build one.

---

**[SENIOR] Q6 (Scenario): A developer says adding mTLS between internal services is too complex. How do you respond?**

Acknowledge the complexity, then reframe the cost-benefit.

The cost of over-trust: one compromised service in the mesh can spoof identity for any
other service. In a breach scenario, an attacker who compromises the notification
service can impersonate the payment service if there is no inter-service authentication.
The blast radius is the entire internal network.

The tools that reduce complexity:
1. Service mesh (Istio, Linkerd): the sidecar handles mTLS termination automatically.
   Services see plaintext on localhost. Zero code changes in the application.
   Istio policy: `PeerAuthentication { mtls: STRICT }` enables mTLS for the namespace.

2. Kubernetes SPIFFE/SPIRE: workload identity based on Kubernetes service accounts.
   Certificates rotated automatically. No manual certificate management.

3. JWT service-to-service: services include a short-lived JWT (5 min) with
   `aud: target-service` in outgoing calls. More code than a service mesh but
   no infrastructure dependency.

The developer's real concern is usually operational: certificate rotation, debugging,
performance. Address each:
- Rotation: automatic with a service mesh.
- Debugging: service mesh has built-in mTLS debug tooling.
- Performance: TLS session resumption and modern hardware make TLS overhead < 1ms.

*What separates good from great:* Leading with the service mesh option. The developer
objection is about application-level TLS complexity; a service mesh makes it an
infrastructure concern, not an application concern. The developer's concern is valid
for application-layer mTLS; it is not valid when the infrastructure provides it.

---

**[MID] Q7 (Trade-off): What is the difference between authentication and authorization, and where should each be enforced?**

Authentication answers "who are you?" - verifying the identity of the requester.
Authorization answers "are you allowed to do this?" - verifying the requester has
permission for the specific action on the specific resource.

They are separate concerns enforced at different layers:

Authentication enforcement:
- Network gateway/load balancer: validates JWT signature, checks expiry, checks issuer
- Spring Security filter chain: extracts identity into Authentication object
- Any request without valid credentials → 401 (Unauthorized)

Authorization enforcement:
- Method level: `@PreAuthorize("hasRole('ADMIN')")` on service methods
- Resource level: check that the authenticated user owns or has permission for
  the specific resource ID (instance-level authorization)
- Data level: row-level security in PostgreSQL; tenant isolation
- Any authenticated request without authorization → 403 (Forbidden)

Common mistake: checking authentication in one place and assuming authorization.
An authenticated request from a regular user to an admin endpoint is authenticated
but not authorized.

*What separates good from great:* The distinction between 401 and 403. Return 401
when the request has no credentials or invalid credentials (authentication failure).
Return 403 when credentials are valid but the action is not permitted (authorization
failure). Returning 404 for security through obscurity is an anti-pattern; 403
should be returned for endpoints that exist but the user cannot access.

---

**[SENIOR] Q8 (Mechanism): What is a timing attack in authentication and how do you prevent it?**

A timing attack exploits the time difference in string comparison to infer whether
a guess was partially correct. In naive string comparison, `"wrong"` vs `"correct"`
returns different execution times based on how many characters match before the
first mismatch.

Example: token comparison with `equals()`:
```java
// BAD: early-exit comparison leaks timing info
if (token.equals(storedToken)) { ... }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the BAD pattern - Java's `String.equals()` performs an early-exit comparison and returns as soon as the first character mismatch is found. (2) KEY MECHANISM: execution time varies with how many characters match before the first difference; an attacker sends thousands of tokens and measures response times to statistically infer the correct token prefix. (3) WHY IT MATTERS: this attack is practical against tokens with fixed prefixes or predictable structure, and has been demonstrated against HMAC-based systems. (4) WHAT BREAKS: the attack requires many requests and statistical analysis, but it works even through network jitter given enough samples. (5) TAKEAWAY: never use `equals()` for security token comparison; use constant-time comparison.

If the stored token is `"abc...xyz"`, an attacker sending tokens that start with
`"a"` gets a slightly longer response time than tokens starting with `"z"` (more
characters matched before mismatch). With enough trials, the attacker narrows down
the token value.

Prevention: constant-time comparison that always compares all bytes:

```java
// GOOD: MessageDigest.isEqual is constant-time
import java.security.MessageDigest;

boolean safe = MessageDigest.isEqual(
    token.getBytes(StandardCharsets.UTF_8),
    storedToken.getBytes(StandardCharsets.UTF_8));
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the GOOD pattern - `MessageDigest.isEqual` is a constant-time comparison that always iterates both arrays to their full length regardless of where a mismatch occurs. (2) KEY MECHANISM: the implementation uses bitwise OR to accumulate differences without short-circuiting; the result is the same whether the first byte matches or all bytes match, making execution time independent of input similarity. (3) WHY IT MATTERS: eliminates timing side-channel; even under statistical analysis with thousands of samples, no information about the token value is leaked. (4) WHAT BREAKS: comparing strings of different lengths always fails in constant time (both lengths are checked but no byte comparison is meaningful); ensure tokens are always the same length. (5) TAKEAWAY: `MessageDigest.isEqual` is the standard Java utility for constant-time comparison; use it for all security token, HMAC, and API key comparisons.

`MessageDigest.isEqual` always processes both arrays to their full length regardless
of where a mismatch occurs.

Applications: password comparison (use bcrypt which handles this internally), HMAC
comparison, API key validation, reset token validation.

*What separates good from great:* Knowing that timing attacks are practical at
network scale. Naively, network jitter would mask the microsecond differences.
But with enough samples (thousands of requests) and statistical analysis, the signal
is extractable even through network noise. The defense is cheap (one API call change);
the attack is real and documented.

---

**[STAFF] Q9 (Behavioral): You discover that your company's internal APIs have no authentication between services. How do you address it?**

This is a systemic remediation, not a single bug fix. Approach: assess, plan, execute
incrementally.

Assessment: map all internal service calls. Which services communicate with which?
What data flows over unauthenticated channels? What is the blast radius if one service
is compromised today?

Risk prioritization: identify the highest-risk pairs. Payment service ↔ billing
service: critical (financial data). Notification service ↔ user service: high (PII).
Internal metrics service ↔ any: low (non-sensitive). Focus remediation effort on
critical and high.

Incremental plan:
Phase 1 (2-4 weeks): deploy a service mesh (Istio) in permissive mode. mTLS
available but not enforced. Monitor and catalog all inter-service traffic.
Phase 2 (4-8 weeks): enable mTLS strict mode for critical service pairs. Test
thoroughly before widening scope.
Phase 3 (2-3 months): mTLS strict across all internal services.

Parallel track: identify and fix the highest-risk over-trust patterns (X-User-ID
headers) simultaneously with infrastructure work.

Communication: present the risk assessment to leadership with blast-radius analysis.
Frame as technical debt with quantifiable risk exposure. The decision to prioritize
is a business decision; security provides the risk characterization.

*What separates good from great:* Using the audit log gap as evidence. "We have no
way to know if an internal service was compromised last month because we have no
inter-service authentication or audit logs." The inability to detect past compromise
is a compelling argument for urgency that resonates beyond technical teams.
