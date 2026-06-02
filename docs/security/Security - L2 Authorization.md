---
layout: default
title: "Security - L2 Authorization"
parent: "Security"
nav_order: 5
permalink: /security/l2-authorization/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [RBAC vs ABAC: Access Control Patterns](#rbac-vs-abac-access-control-patterns) | critical |
| 2 | [API Security: Rate Limiting and Abuse Prevention](#api-security-rate-limiting-and-abuse-prevention) | high |

---

# RBAC vs ABAC: Access Control Patterns

---
id: SEC-012
title: "RBAC vs ABAC: Access Control Patterns"
category: Security
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: mid
tags: #security, #rbac, #abac, #authorization, #access-control
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> RBAC (Role-Based Access Control) assigns permissions to roles and assigns roles to
> users - a user can do what their roles allow. ABAC (Attribute-Based Access Control)
> evaluates policies against attributes of the subject (user), resource, action, and
> environment. RBAC is simpler; ABAC is more expressive but more complex.

**3 minutes (Senior):**
> RBAC is a predefined permission matrix: roles hold permissions, users get roles,
> authorization is a lookup. Easy to understand and audit. The weakness appears at
> scale with role explosion: 500 resources with different access needs per context
> creates hundreds of roles. RBAC cannot express "doctors can view only their own
> patients" without patient-specific roles or code outside RBAC. ABAC evaluates
> policies dynamically: "user.department=Cardiology AND resource.owner=user.id AND
> action=READ AND time.hour BETWEEN 6 AND 22." Fine-grained access without role
> explosion. Cost: harder to audit, debugging requires reasoning through attribute
> values at request time. Most production systems use a hybrid: RBAC for coarse-grained
> control, ABAC with roles as attributes for fine-grained rules.

**Framework:** RBAC (roles → permissions) → ABAC (policy + attributes → decision) → HYBRID → AUDIT

**Blank Mind Recovery:**

**(1) Restate:** "Authorization asks: can this subject perform this action on this resource?"

**(2) First principles:** "RBAC answers by looking up fixed role assignments. ABAC
answers by evaluating a policy against any available attributes."

**(3) Bridge:** "RBAC is a building keycard system - card type X opens doors A and B.
ABAC is a smart lock checking badge, time, department, and room classification."

---

### 📘 Concept Explanation

**What it is:**
RBAC assigns permissions to roles, roles to users, and evaluates: does the user have
a role with this permission? ABAC evaluates policies against subject, resource, action,
and environment attributes to make access decisions.

**The problem it solves:**
Applications need to answer "can this user do this thing?" at runtime. The challenge
is expressing complex business rules in a manageable, auditable way. RBAC solves simple
cases; ABAC handles complex, context-dependent access.

**How it works:**

```
RBAC MODEL:
  user:alice  -> DOCTOR   -> READ_PATIENT
  user:bob    -> NURSE    -> READ_PATIENT
  user:carol  -> ADMIN    -> MANAGE_USERS

  Check: alice READ_PATIENT?
    alice.roles contains DOCTOR
    DOCTOR has READ_PATIENT -> ALLOW

RBAC WEAKNESS:
  Alice can only read HER patients?
  Cannot express without application code
  outside RBAC, or per-patient roles
```

```
ABAC MODEL:
  Policy:
    subject.role=DOCTOR
    AND resource.assigned_doctor=subject.id
    AND env.time BETWEEN 06:00 AND 22:00

  alice reads P1 (assigned_doctor=alice) -> ALLOW
  alice reads P2 (assigned_doctor=bob)   -> DENY
```

> **Code walkthrough:** (1) WHAT IT SHOWS: ABAC evaluating access dynamically using subject, resource, and environment attributes rather than a static role-permission matrix. (2) KEY MECHANISM: the policy engine evaluates a predicate combining user attributes (role, id), resource attributes (assigned_doctor), and environment (time range); the decision changes as attributes change without any role reassignment. (3) WHY IT MATTERS: RBAC cannot express "only the assigned doctor" without per-patient roles, which explodes at scale; one ABAC policy handles all patients regardless of how many exist. (4) WHAT BREAKS: ABAC requires the policy engine to receive accurate attribute values; if user.id in the JWT is stale (user profile updated), ABAC grants based on outdated data. (5) TAKEAWAY: ABAC shifts the access problem from "manage role assignments" to "maintain accurate attributes"; attribute freshness is the operational concern to manage.

**The key insight:**
RBAC roles are the most natural mental model for developers and business users.
ABAC is powerful but requires a policy engine and clear attribute definitions.
The hybrid approach: roles as one attribute among many in ABAC policies.

**When to use it:**
RBAC: most web apps with manageable permission types. ABAC: regulated industries
with fine-grained requirements (healthcare, finance). Hybrid: enterprise apps needing both.

**When NOT to use it:**
Do not build your own engine for complex requirements - use OPA, Casbin, AWS Cedar.
Do not use RBAC for ownership-based access ("only owner can edit") - use ReBAC.

**Alternatives:**
- ReBAC - Google Zanzibar graph model; "user has relation to resource"
- DAC - resource owners grant access; personal storage
- MAC - security labels; military clearance
- PBAC - explicit policy documents; OPA, AWS Cedar

---

### 💻 Code Example

```java
// RBAC: centralized role-permission check
@Component
public class RbacAuthorizationService {
    private static final Map<String, Set<String>> ROLES =
        Map.of(
            "ADMIN", Set.of(
                "users:read", "users:write",
                "reports:read", "system:configure"),
            "MANAGER", Set.of(
                "users:read", "reports:read",
                "reports:write"),
            "EMPLOYEE", Set.of("reports:read")
        );

    public boolean hasPermission(
            User user, String permission) {
        return user.getRoles().stream()
            .anyMatch(role ->
                ROLES.getOrDefault(role, Set.of())
                     .contains(permission));
    }
}

// BAD: Role checks scattered in every controller
@GetMapping("/admin/users")
public List<User> listUsersBad(Principal p) {
    // Duplicated everywhere, hard to audit
    if (!user.getRoles().contains("ADMIN")) {
        throw new ForbiddenException();
    }
    return userService.listAll();
}

// GOOD: Centralized annotation-based authorization
@PreAuthorize("hasPermission('users:read')")
@GetMapping("/admin/users")
public List<User> listUsersGood() {
    return userService.listAll();
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the contrast between scattered role checks in every controller versus centralized permission-based authorization via annotations. (2) KEY MECHANISM: `@PreAuthorize("hasPermission('users:read')")` delegates to one central service; the annotation uses a semantic permission name, not a role name. (3) WHY IT MATTERS: centralized logic can be audited, tested, and changed in one place; scattered checks create sprawl where adding a new role requires updating dozens of sites. (4) WHAT BREAKS: `@PreAuthorize("hasRole('ADMIN')")` tight-couples logic to role names - if the role is renamed, every annotation must be updated; semantic permission names decouple this. (5) TAKEAWAY: separate authorization policy (role-permission matrix) from enforcement (annotations); change the policy without touching business code.

```java
// ABAC: Attribute-based policy evaluation
public class AbacAuthorizationService {
    public boolean canAccessDocument(
            User subject, Document resource,
            String action) {
        boolean sameDeptOrAdmin =
            subject.getDepartment()
                   .equals(resource.getDepartment())
            || resource.getOwnerId()
                       .equals(subject.getId())
            || "ADMIN".equals(subject.getDepartment());

        boolean sufficient =
            subject.getClearanceLevel()
            >= resource.getClassification();

        LocalTime now = LocalTime.now();
        boolean withinHours =
            now.isAfter(LocalTime.of(6, 0))
            && now.isBefore(LocalTime.of(22, 0));

        return "READ".equals(action)
            ? (sameDeptOrAdmin && sufficient
               && withinHours)
            : (resource.getOwnerId()
                       .equals(subject.getId())
               && sufficient);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: ABAC policy combining subject attributes (department, clearance), resource attributes (department, classification, owner), and environment (time of day) into one dynamic access decision. (2) KEY MECHANISM: the decision changes dynamically as attributes change - user clearance is upgraded, time passes - without any role assignment changes. (3) WHY IT MATTERS: expressing this in RBAC requires dozens of roles (Finance-L1-Read, Finance-L2-Read, HR-L1-Read...) causing role explosion; one ABAC policy handles all combinations. (4) WHAT BREAKS: policies are hard to audit - implement access decision logging recording all attribute values and the outcome; "DENIED: clearance=2, required=3" makes debugging immediate. (5) TAKEAWAY: externalize attribute fetching so the policy receives pre-fetched values; the policy engine should not fetch from databases itself.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> RBAC assigns permissions to roles and roles to users. Check: does the user have a
> role with the required permission? Simple and auditable. ABAC evaluates policies
> using attributes of the user, resource, and environment. More expressive but more
> complex. Most applications start with RBAC and add ABAC for specific complex cases.

---

**Senior / Staff (5+ years):**
> I start with RBAC (product managers understand it) and introduce ABAC where role
> explosion occurs. The staff question is whether to implement authorization as a
> centralized service using OPA (Open Policy Agent): services query a sidecar with
> a JSON context document and get ALLOW/DENY. Centralized policies in Git, deployed
> independently of service code, with a consistent audit log. Trade-off: sidecar
> latency (< 1ms via Unix socket). For complex multi-tenant access requirements
> I evaluate ReBAC (SpiceDB/OpenFGA) - graph-based models express ownership and
> sharing hierarchies naturally without role explosion or complex ABAC policies.

---

### ⚠️ Common Misconceptions

**Misconception 1: RBAC prevents privilege escalation by design.**

RBAC limits what roles can do, not whether role assignments are correct. A user who
can modify their own role assignments escalates to any role. Role assignment must
itself be authorized and audited.

**Misconception 2: ABAC is always better because it is more expressive.**

ABAC's expressiveness comes with complexity: harder to audit, debugging requires
attribute tracing, policy interactions cause unexpected results. RBAC is simple,
auditable, and sufficient for most applications. Use ABAC only where RBAC fails.

**Misconception 3: UI-layer authorization is a security control.**

Hiding buttons in the UI is UX, not security. Attackers call the API directly,
bypassing all UI checks. Backend authorization is the security control.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Role explosion makes RBAC unmaintainable.**

Symptom: hundreds of roles; adding one resource type requires many new roles.
Diagnosis: if roles outnumber users, role explosion has occurred.
Fix: introduce ABAC for the dimensions causing explosion.

**Failure Mode 2: Missing authorization on a new endpoint (IDOR).**

Symptom: new endpoint returns data for any user ignoring their permissions.
Diagnosis: audit all endpoints for authorization annotations; use Semgrep rules for
missing `@PreAuthorize`. Test user A's token against user B's resources.
Fix: "deny by default" - require explicit authorization on every endpoint.

**Failure Mode 3: Stale permissions after role change.**

Symptom: demoted user still performs restricted actions; their JWT carries old roles.
Diagnosis: check if role changes invalidate existing tokens.
Fix: short-lived tokens (15 min) bound the staleness window; for immediate revocation
check roles from database at authorization time.

---

### ⚖️ Comparison Table

| Aspect | RBAC | ABAC | ReBAC |
|---|---|---|---|
| **Model** | User → Role → Permission | Policy (attributes) | User → Relation → Resource |
| **Expressiveness** | Limited | High | High |
| **Complexity** | Low | High | Medium |
| **Auditability** | High | Medium | Medium |
| **Role explosion** | Risk | None | None |
| **Best for** | Most web apps | Regulated/fine-grained | Ownership/hierarchy |
| **Tools** | Spring Security | OPA, AWS Cedar | SpiceDB, OpenFGA |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Authorization as a service covered in L4/L5 entries.)*

---

### 📊 Diagram

*(Omit: RBAC and ABAC ASCII diagrams in Concept Explanation contrast the models.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Role explosion, ABAC vs RBAC |
| Mechanism | 2 | OPA, ReBAC |
| Debugging | 2 | Missing auth, stale permissions |
| Trade-off | 2 | Model selection, centralization |
| Behavioral | 1 | Multi-tenant design |

---

**[MID] Q1 (Definition): What is role explosion and how do you fix it?**

Role explosion is the proliferation of RBAC roles until role management negates
the simplicity benefit.

Example: document system with 10 departments, 5 document types, 4 access levels.
Naive RBAC: Finance-Invoice-Read, Finance-Invoice-Write, HR-Invoice-Read... 200 roles.
Adding one department requires 20 new roles. Users need multiple roles. Role assignment
becomes a full-time job.

Root cause: RBAC encoding multi-dimensional access control into role names.

Fixes:

ABAC for variable dimensions: assign users department roles; use ABAC policies for
document type and access level. One policy handles all combinations.

Hierarchical RBAC: define base roles (Reader, Writer) and scope roles (Finance, HR)
independently. Users have both; the combination determines access.

Policy engine (OPA): `users with department=X can READ document type=Y` - no roles
for this dimension.

*What separates good from great:* Recognizing explosion before it becomes entrenched.
Roles named `Department-DocumentType-AccessLevel` are ABAC trying to be RBAC. Stop
and redesign at that moment.

---

**[MID] Q2 (Definition): When would you choose ABAC over RBAC?**

Choose ABAC when access depends on dynamic attributes that RBAC cannot express without
role explosion.

Concrete triggers:

Time-sensitive: "Lab results accessible only 6am-10pm." RBAC has no time concept.
ABAC environment attribute handles naturally.

Multi-tenancy: "Users see only their tenant's data." Per-tenant roles explode for
hundreds of tenants. ABAC: `user.tenantId == resource.tenantId`.

Ownership: "Creators can edit their own documents." Per-creator-per-document roles
are impossible at scale. ABAC: `user.id == resource.ownerId`.

Classification: "Clearance >= classification required." ABAC: `user.clearance >= resource.classification`.

When RBAC is sufficient: "which type of user can use which feature" with simple,
static permission matrices.

*What separates good from great:* The hybrid recommendation. Start with RBAC; add
ABAC where role explosion occurs. Roles become attributes in ABAC policies. Most
production systems are hybrid.

---

**[SENIOR] Q3 (Mechanism): How does OPA integrate with microservices for authorization?**

OPA is a general-purpose policy engine evaluating Rego policies. Each service has an
OPA sidecar. Before serving a request, the service sends a JSON context to OPA: user
attributes, resource, action, environment. OPA returns ALLOW or DENY.

Rego policy example:
```
allow {
  input.action == "read"
  input.user.department == input.resource.department
  input.user.clearance >= input.resource.classification
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: an OPA Rego policy combining department matching, clearance level, and an implicit action check using `input.*` attributes from the service-provided context document. (2) KEY MECHANISM: OPA evaluates Rego rules as logical predicates; `allow` is true only when all conditions are simultaneously true; the service sends a JSON input document and OPA returns the evaluation result in < 1ms via a local sidecar. (3) WHY IT MATTERS: policies live in Git, are versioned, and deployed independently of service code; policy changes do not require service redeployment or restarts. (4) WHAT BREAKS: if the service assembles the input document incorrectly (wrong attribute name, missing claim), OPA evaluates with incomplete context and may grant or deny unexpectedly; input document schema validation catches this early. (5) TAKEAWAY: treat the input document as the OPA API surface - version it, validate it, and test it with OPA's built-in test framework before deploying.

Benefits: policies in Git, versioned, deployed independently of service code.
All services share the same policy engine. Policy changes don't require redeployment.
Built-in test tooling. Every decision auditable.

Latency: local Unix socket sidecar < 1ms. Centralized OPA over network: 1-10ms.

*What separates good from great:* Input document assembly is the service's responsibility -
OPA evaluates only what it receives. Stale JWT claims produce incorrect decisions for
high-security operations; fetch current attributes from the database for those checks.

---

**[SENIOR] Q4 (Trade-off): How do you balance authorization centralization vs distribution?**

Centralized authorization service: single audit log, consistent policies, one change
point. Risk: single point of failure on every request path.

Distributed (each service has its own logic): no network dependency, fast in-process.
Risk: policy duplication, drift between services.

OPA sidecar is the pragmatic middle: policies centralized (Git, deployed uniformly),
evaluation distributed (each service queries its local sidecar). Consistent policies
without centralized availability dependency.

The attribute freshness problem: fine-grained ABAC needs attributes from multiple
services. Options: (1) fetch before auth check, (2) pre-load to shared Redis, (3)
event-driven cache invalidation on attribute changes.

*What separates good from great:* Identifying acceptable staleness window. Short-lived
JWTs (15 min) already bound role claim staleness. For clearance-level changes (immediate
effect required), check the database directly for the authorization-critical attribute.

---

**[SENIOR] Q5 (Debugging): How do you debug "why was access denied" for an ABAC policy?**

ABAC denials are hard to debug because "403 Forbidden" reveals nothing about which
condition failed.

Step 1 - Get the context: user, resource, action, timestamp. Reproduce the exact request.

Step 2 - Check user attributes: query the current database values (clearance, department).
Compare to JWT claims - are they in sync?

Step 3 - Check resource attributes: owner, department, classification.

Step 4 - Trace the policy: if using OPA, `opa eval` with `--explain full` shows which
conditions matched and which failed with their values.

Step 5 - Check environment: time of day, region, IP range.

Proactive improvement: structured denial logging that records all attribute values and
the failing condition. "DENIED: user.clearance=2, resource.classification=3" makes
debugging immediate. Internal only - do not expose detail to callers (information
disclosure risk).

*What separates good from great:* Decision tracing logs with the full input document
and the specific failing predicate. This turns a 30-minute debug session into a
30-second log lookup.

---

**[SENIOR] Q6 (Mechanism): Explain ReBAC and when it solves problems RBAC/ABAC cannot.**

ReBAC defines access via relationships between users and resources as a directed graph.
Google Zanzibar (2019) describes how Drive and Docs handle sharing.

Tuples: `(alice, owner, doc:123)`, `(team:eng, viewer, doc:123)`, `(alice, member, team:eng)`.

Access rules: "can read if owner, OR direct viewer, OR member of a viewer team."
Graph traversal evaluates these rules by following relationship edges.

Naturally expresses:
- Hierarchical inheritance: folder.viewer → all files.viewer
- Team-based: member of team:eng inherits team permissions
- Ownership chains: owner > editor > viewer

RBAC cannot express hierarchical inheritance without explicit per-resource assignment.
ABAC can but requires complex multi-resource lookups. ReBAC expresses these naturally.

Best for: Google Docs sharing (specific user, specific resource), folder permission
cascades, multi-level group delegation.

Open source: SpiceDB (Authzed), OpenFGA (CNCF), Permify.

*What separates good from great:* The Zanzibar consistency challenge. Eventually
consistent replicas may not reflect a recent share grant. Zanzibar uses "zookies"
(consistency tokens) to ensure the access check reads post-grant state. For most
applications, eventual consistency is fine; for security-critical checks, pass the
consistency token from the write to the subsequent read.

---

**[STAFF] Q7 (Trade-off): How do you design authorization for a multi-tenant SaaS?**

Two dimensions: tenant isolation (users in A cannot access B's data) and within-tenant
authorization (role-based within the tenant).

Tenant isolation is a security invariant - must hold regardless of other decisions.
Implementation: `tenantId` in every authenticated JWT claim. Authorization layer
validates `user.tenantId == resource.tenantId` before business logic. Use PostgreSQL
row-level security as a second layer - automatically filters queries to current tenant,
catching developer oversights on new queries.

Within-tenant: RBAC scoped to tenant. Tenant A's Admin is separate from B's Admin.
JWT: `{"sub": "alice", "tenant": "acme", "roles": ["admin"]}`. Authorization always
includes tenant context in the check.

Data model: explicitly store `tenant_id` on every entity as a direct column. Never
infer tenant from a relationship chain - direct denormalization is safer.

Super-admin for customer support: explicit `support` role with tenant-override.
Every cross-tenant access logged with support ticket ID. Requires approval, time-limited,
generates an alert.

*What separates good from great:* Treating tenant isolation as defense-in-depth:
API layer (JWT claims), business logic layer (service check), and data layer (RLS).
Three independent controls mean a single bug does not cause cross-tenant exposure.

---

**[SENIOR] Q8 (Debugging): Security scanner finds an endpoint returning any user's
data ignoring permissions. What is this and how do you fix it?**

This is Insecure Direct Object Reference (IDOR) - broken object-level authorization,
OWASP API Security Top 10 #1.

Root cause: the endpoint retrieves a resource by ID from the request without verifying
the authenticated user is authorized for that specific instance. Authentication is
checked (valid JWT) but instance-level authorization is missing.

```java
// VULNERABLE: no ownership check
@GetMapping("/documents/{id}")
public Document get(@PathVariable Long id) {
    return documentRepo.findById(id)
        .orElseThrow(NotFoundException::new);
}

// FIXED: verify access to this specific instance
@GetMapping("/documents/{id}")
@PreAuthorize(
    "@docAuthz.canRead(#id, principal)")
public Document get(@PathVariable Long id) {
    return documentRepo.findById(id)
        .orElseThrow(NotFoundException::new);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the contrast between an IDOR-vulnerable endpoint and a properly secured one using instance-level authorization via a SpEL expression in `@PreAuthorize`. (2) KEY MECHANISM: `@PreAuthorize("@docAuthz.canRead(#id, principal)")` calls a Spring bean method before the handler executes; the bean fetches the document, checks the authenticated user's relationship to that specific instance, and returns true or false. (3) WHY IT MATTERS: IDOR is OWASP API Top 10 #1 - it means user A's valid token can retrieve user B's resource by changing the ID; authentication is present but authorization is missing at the instance level. (4) WHAT BREAKS: role-only checks (`hasRole('USER')`) catch nothing here - both users have valid tokens and valid roles; only instance-level checks prevent IDOR. (5) TAKEAWAY: every endpoint accepting a resource ID must verify the authenticated user's authorization for that specific instance, not just their general role.

`docAuthz.canRead` checks the specific document's authorization, not a general role.

Systematic fix: audit all endpoints taking a resource ID parameter. Verify each has
instance-level authorization. Use UUIDs to make enumeration harder (not a substitute
for authorization, but raises attack cost).

*What separates good from great:* Writing authorization tests: does user A's token
allow access to user B's resources? This test class catches IDOR before the scanner.

---

---

# API Security: Rate Limiting and Abuse Prevention

---
id: SEC-013
title: "API Security: Rate Limiting and Abuse Prevention"
category: Security
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #security, #rate-limiting, #api-security, #abuse-prevention
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Rate limiting restricts how many requests a client can make per time window.
> It protects APIs from abuse (credential stuffing, scraping, DoS) and prevents
> overload. Common algorithms: fixed window (simple), sliding window (prevents
> boundary burst), token bucket (allows controlled bursts). Apply limits at multiple
> levels: per-IP, per-user, per-API-key, with stricter limits on sensitive endpoints.

**3 minutes (Senior):**
> The identifier is the critical security design decision. For credential stuffing,
> IP limiting fails against botnets - limit by username instead. For scraping, limit
> by API key. For DoS, limit by IP at the gateway before the application. Token bucket
> (AWS API Gateway, most cloud products) allows bursts up to capacity then refills at
> a fixed rate - appropriate for legitimate clients that batch requests. Sliding window
> prevents gaming the fixed-window reset by using a rolling time window. For distributed
> services, state must be in Redis - any local in-process counter is bypassed by
> horizontal scaling. The 429 response must include `Retry-After` so clients know
> when to retry rather than causing a retry storm.

**Framework:** THREAT → IDENTIFIER (who to limit) → ALGORITHM → REDIS (distributed state) → 429 + Retry-After

**Blank Mind Recovery:**

**(1) Restate:** "Rate limiting prevents API abuse by capping request velocity."

**(2) First principles:** "Without limits, one client can make unlimited requests -
crashing the service, trying millions of passwords, or harvesting all data."

**(3) Bridge:** "A bank limiting ATM withdrawals to $500/day: doesn't stop legitimate
use, but prevents draining an account with a stolen card."

---

### 📘 Concept Explanation

**What it is:**
Rate limiting enforces a maximum number of requests per client per time window.
API abuse prevention combines rate limiting with bot detection, authentication event
monitoring, and anomaly detection.

**The problem it solves:**
Without limits: bots try millions of credentials against login; scrapers harvest the
database; buggy clients accidentally DDoS. Rate limits cap request velocity per client.

**How it works:**

```
RATE LIMITING ALGORITHMS:

  FIXED WINDOW:
  Limit: 100 req/minute
  Reset at window boundary
  WEAKNESS: 100 at 0:59 + 100 at 1:01
            = 200 in 2 seconds

  SLIDING WINDOW:
  Count requests in [now-60s, now]
  Prevents boundary burst

  TOKEN BUCKET:
  Capacity: 100 tokens
  Refill: 10 tokens/second
  Burst: up to capacity allowed
  Sustained: 10 req/sec

  LEAKY BUCKET:
  Fixed output rate, no burst
```

```
IDENTIFIERS (choose by threat model):
  Per-username:  defeats credential stuffing botnets
  Per-API-key:   enforces business tier quotas
  Per-user:      authenticated user; best default
  Per-IP:        anonymous/pre-auth traffic only
  Global:        service-wide ceiling
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the rate limiting identifier hierarchy ordered from most targeted (per-username) to most general (global ceiling). (2) KEY MECHANISM: each identifier targets a different attack type - per-username catches credential stuffing regardless of IP count; per-API-key enforces business quotas; per-IP catches volumetric anonymous attacks; global is the circuit breaker of last resort. (3) WHY IT MATTERS: choosing the wrong identifier defeats the purpose - IP limiting fails against botnets; username limiting may cause lockout-as-DoS if hard lockout is used; each identifier has a specific threat model. (4) WHAT BREAKS: using only per-IP limiting for login endpoints allows credential stuffing with one attempt per IP across a botnet of 100,000 IPs; the account is compromised before the IP limit applies. (5) TAKEAWAY: match the rate limit identifier to the threat model of the endpoint; login needs per-account; API quotas need per-key; anonymous endpoints need per-IP.

**The key insight:**
The identifier determines which attacks are prevented. IP limits are defeated by
botnets and proxies. Per-account limits defeat distributed credential stuffing
regardless of IP count.

**When to use it:**
All public APIs. Login endpoints: per-account limits (5 per 15 min). Public APIs:
per-API-key quotas. Admin APIs: strict per-user limits.

**When NOT to use it:**
Health check endpoints. Internal service-to-service calls. Do not use hard lockout -
use progressive challenges (CAPTCHA) to avoid lockout-as-DoS.

**Alternatives:**
- CAPTCHA - human verification for high-risk actions
- Circuit breaker - protects from downstream failures (not abuse)
- Bot fingerprinting - behavioral analysis beyond request rate
- Queue-based throttling - accept all, process at max rate

---

### 💻 Code Example

```java
// Distributed rate limiting: Bucket4j + Redis
// Works correctly across all service instances

@Component
public class RateLimitingFilter
        extends OncePerRequestFilter {
    private final RateLimiterRegistry registry;

    @Override
    protected void doFilterInternal(
            HttpServletRequest req,
            HttpServletResponse res,
            FilterChain chain)
            throws ServletException, IOException {
        String key = resolveKey(req);
        RateLimitConfig cfg =
            getConfig(req.getRequestURI());

        RateLimiter limiter = registry.rateLimiter(key,
            () -> RateLimiterConfig.custom()
                .limitRefreshPeriod(cfg.getWindow())
                .limitForPeriod(cfg.getLimit())
                .timeoutDuration(Duration.ZERO)
                .build());

        if (limiter.acquirePermission()) {
            res.setHeader("X-RateLimit-Limit",
                String.valueOf(cfg.getLimit()));
            chain.doFilter(req, res);
        } else {
            res.setStatus(429);
            res.setHeader("Retry-After",
                String.valueOf(cfg.getRetryAfterSecs()));
            res.setHeader("X-RateLimit-Remaining", "0");
            res.getWriter().write(
                "{\"error\":\"rate_limit_exceeded\"}");
        }
    }

    private String resolveKey(HttpServletRequest req) {
        Authentication auth = SecurityContextHolder
            .getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()
                && !"anonymousUser".equals(
                    auth.getPrincipal())) {
            return "user:" + auth.getName();
        }
        return "ip:" + getClientIp(req);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: distributed rate limiting using authenticated user ID as the primary key (falling back to IP for anonymous requests) with per-endpoint configurations. (2) KEY MECHANISM: Bucket4j with Redis backend shares state across all service instances; a local in-process counter would allow N times the limit with N instances behind a load balancer. (3) WHY IT MATTERS: using user ID as the key for authenticated endpoints prevents botnet bypass - even with rotating IPs, the user's account is the throttled unit. (4) WHAT BREAKS: omitting `Retry-After` from 429 causes retry-logic clients to immediately retry, amplifying load rather than backing off. (5) TAKEAWAY: authenticate first, then apply user-level limits; IP-level limits are last resort for anonymous/pre-auth traffic.

```java
// Account-level login rate limiting
@Service
public class LoginRateLimiter {
    private final RedisTemplate<String, Integer> redis;
    private static final int MAX_ATTEMPTS = 5;
    private static final int WINDOW_SECS = 900;

    // BAD: IP-based only - trivially bypassed by botnet
    public boolean isAllowedBad(String clientIp) {
        String key = "login:ip:" + clientIp;
        Integer count = redis.opsForValue().get(key);
        return count == null || count < MAX_ATTEMPTS;
    }

    // GOOD: Account-based - defeats distributed attack
    public boolean isAllowedByAccount(String username) {
        String key = "login:account:" + username;
        Long count =
            redis.opsForValue().increment(key);
        if (count == 1) {
            redis.expire(key,
                WINDOW_SECS, TimeUnit.SECONDS);
        }
        return count <= MAX_ATTEMPTS;
    }

    public void recordSuccess(String username) {
        // Clear counter on successful authentication
        redis.delete("login:account:" + username);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: account-based vs IP-based rate limiting for credential stuffing, demonstrating why the identifier is the critical design decision. (2) KEY MECHANISM: `login:account:username` increments regardless of source IP; a botnet with 10,000 IPs making one attempt each against alice's account counts as 10,000 against alice, triggering the limit after 5. (3) WHY IT MATTERS: credential stuffing uses one attempt per IP to avoid IP limits; per-account limits reduce a 1M-credential attack to 5 attempts per account regardless of infrastructure. (4) WHAT BREAKS: hard lockout (block, require admin unlock) enables lockout-as-DoS - attacker locks out any known account; use CAPTCHA after N failures instead of hard lockout. (5) TAKEAWAY: match the limiting key to the threat - per-account for credential stuffing, per-IP for volumetric pre-auth, per-API-key for scraping.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Rate limiting counts requests per time window and returns 429 when exceeded. Protects
> against DoS, credential stuffing, and scraping. Use Redis for shared state across
> multiple server instances. Always include `Retry-After` in 429 responses.

---

**Senior / Staff (5+ years):**
> Multi-layer defense: gateway-level IP limiting rejects volumetric attacks before
> the application. Application-level user-based limits enforce quotas. Login uses
> account-level limits to defeat distributed botnets. Design tension: hard account
> lockout creates a DoS vector - CAPTCHA after N failures avoids lockout while
> blocking automation. For sustained attacks: adaptive rate limiting detects attack
> signatures (high 401 rates, non-existent account probing), dynamically tightens
> limits for suspect traffic while maintaining normal limits for clean sources.

---

### ⚠️ Common Misconceptions

**Misconception 1: IP-based rate limiting stops credential stuffing.**

Botnets use hundreds of thousands of IPs. One request per IP, 100,000 IPs = 100,000
attempts against one account with no IP hitting the limit. Per-account limits are
the correct defense for login endpoints.

**Misconception 2: Rate limiting replaces DDoS protection.**

Volumetric DDoS (millions of RPS) overwhelms rate limiting infrastructure before
reaching the application. DDoS requires network-layer mitigation (Cloudflare, AWS
Shield). Rate limiting handles API abuse; DDoS protection handles network floods. Both needed.

**Misconception 3: In-process rate limiting works when horizontally scaled.**

Local counters per instance: with 10 instances and 100 req/min limit, effective limit
is 1000 req/min (10x intended). Redis shared state is required to enforce the intended
limit across the cluster.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Rate limiting at application layer only.**

Symptom: 429s returned but CPU still maxed - all requests reach the application.
Diagnosis: check where limiting is enforced.
Fix: gateway-level limiting rejects before application code; rejected requests consume
minimal resources.

**Failure Mode 2: Retry-After header missing.**

Symptom: after 429, retry-logic clients immediately retry, no recovery.
Diagnosis: check 429 responses for `Retry-After` header.
Fix: add `Retry-After: N` and `X-RateLimit-Reset` (Unix timestamp) to all 429s.

**Failure Mode 3: Legitimate enterprise customers throttled.**

Symptom: enterprise automation (batch imports, CI pipelines) hitting rate limits.
Diagnosis: check which keys are hitting limits and their usage patterns.
Fix: tiered rate limits per API key; enterprise tier gets higher limits (1000 req/min
vs 100 for standard).

---

### ⚖️ Comparison Table

| Algorithm | Burst | Accuracy | Memory | Best For |
|---|---|---|---|---|
| **Fixed Window** | High at boundary | Low | Very low | Simple counters |
| **Sliding Window Log** | No | High | High | Exact enforcement |
| **Sliding Window Counter** | Minimal | Good | Low | Production balance |
| **Token Bucket** | Yes (up to capacity) | Good | Low | API quotas |
| **Leaky Bucket** | No (strict) | High | Low | Output smoothing |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Full API abuse prevention at scale covered in L4/L5 entries.)*

---

### 📊 Diagram

*(Omit: rate limiting algorithm ASCII diagrams in Concept Explanation illustrate the key patterns.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Algorithms, identifiers |
| Mechanism | 1 | Redis distributed state |
| Debugging | 2 | False positives, in-process failure |
| Trade-off | 2 | Algorithm selection, hard lockout |
| Behavioral | 1 | Production design |
| Scenario | 1 | Credential stuffing |

---

**[MID] Q1 (Definition): What are the trade-offs between fixed window and token bucket?**

Fixed window divides time into intervals and counts requests per interval, resetting
at the boundary. Simple: atomic increment with TTL.

Boundary burst problem: with 100 req/min limit, a client sends 100 at 0:59 and 100
at 1:00 - 200 requests in 2 seconds. Acceptable for most APIs; problematic for
login, payment, safety-critical endpoints.

Sliding window (counter approximation): `estimate = prev * ((window - elapsed) / window) + cur`.
Approximation, but eliminates boundary burst with only two counters.

Token bucket: fills at a fixed rate up to capacity. Each request consumes a token;
empty bucket = reject. Allows bursts up to capacity; sustained rate capped at refill
rate. Standard algorithm for AWS API Gateway, Stripe, most CDN rate limiters.

Leaky bucket: queues requests, processes at fixed output rate. No bursting. For
smoothing output to downstream services that cannot handle bursts.

Decision: quota with acceptable bursting (SDK init, batch) - token bucket. Strict
constant rate (real-time payments) - leaky bucket or sliding window.

*What separates good from great:* Quantifying the burst impact. Token bucket capacity
100, refill 10/sec: first second allows 100-request burst. Acceptable depends on
the downstream's burst tolerance - know the downstream's capacity before choosing.

---

**[MID] Q2 (Mechanism): Why must rate limiting state be in Redis for a scaled service?**

Local in-memory counters are per-instance. With 5 instances and 100 req/min limit:
each allows 100, effective limit is 500 req/min (5x intended). Load balancing
distributes evenly, each instance sees only 1/5 of traffic.

Redis provides: atomic INCR (no race conditions), TTL (auto-expiry), < 1ms latency,
HA options.

Atomic Lua script:
```lua
local cur = redis.call('INCR', KEYS[1])
if cur == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[2])
end
return cur <= tonumber(ARGV[1]) and 1 or 0
```

> **Code walkthrough:** (1) WHAT IT SHOWS: an atomic Redis Lua script for rate limiting that combines INCR, EXPIRE, and the limit check in a single atomic operation. (2) KEY MECHANISM: Redis executes Lua scripts atomically using a single-threaded event loop; the entire script runs without interruption from other commands; INCR+EXPIRE in two separate commands has a race where the TTL is never set if the process dies between them. (3) WHY IT MATTERS: without atomicity, two concurrent requests both increment to 1, both set EXPIRE, and the second EXPIRE resets the window; the counter TTL is extended on every request instead of expiring after the original window. (4) WHAT BREAKS: `MULTI/EXEC` (Redis transactions) does not retry on key contention like Lua does; for simple incr+expire, the Lua script is simpler and more reliable. (5) TAKEAWAY: use Lua scripts for Redis operations that must be atomic across multiple commands; the script approach is standard in production rate limiters.

Without atomicity: two concurrent requests both increment to 1, both call EXPIRE,
the second EXPIRE resets the TTL window. The Lua script executes atomically.

*What separates good from great:* Fail-open vs fail-closed when Redis is unavailable.
Fail open (allow all during outage) risks abuse; fail closed (block all) means service
outage when the rate limiter is down. Practical: fail open with monitoring and alerting.

---

**[SENIOR] Q3 (Scenario): Login endpoint under credential stuffing. Defense in depth.**

Layer 1 - Per-account rate limiting: 5-10 failed attempts per 15-min window per
username. Botnet with 100,000 IPs still limited to 5 attempts per account.

Layer 2 - CAPTCHA after N failures: prevents lockout-as-DoS. After 3 failures require
CAPTCHA - automation cannot solve it; legitimate users can.

Layer 3 - MFA: even with matching password, second factor prevents account takeover.

Layer 4 - Bot fingerprinting: user-agent patterns, absent browser fingerprints
(cookies, JavaScript execution timing). Challenge bot-like requests.

Layer 5 - Breach database check: integrate HaveIBeenPwned. If submitted password
appears in breach databases, prompt reset before login - even if it matches.

Layer 6 - Monitoring: alert on high failed attempts against non-existent usernames
(enumeration), unusual geographic patterns.

*What separates good from great:* MFA eliminates the threat class; everything else
is damage control. Credential stuffing succeeds because of password reuse. Rate
limiting reduces success rates; MFA makes matching passwords irrelevant.

---

**[SENIOR] Q4 (Trade-off): Rate limiting vs circuit breaking - when do you use each?**

Rate limiting is client-protection: limits how fast one client calls the API.
Protects the server from client overload. Excess: 429 - client expected to back off.

Circuit breaking is service-protection: when a downstream is failing or slow, fast-fail
calls to prevent cascading timeouts. Protects the caller from dependency failures.

Use rate limiting: client abuse prevention, quotas, credential stuffing, fair use.

Use circuit breaking: dependency failures, cascading timeout prevention, graceful
degradation.

Both needed: rate limiting prevents overloading your service from clients; circuit
breaking prevents your service being taken down by failing dependencies. They address
different problems from different directions.

Interaction: circuit-open fast-fails may trigger retry logic that hits upstream rate
limits. Distinguish circuit-state failures from real service calls in rate limit counters.

*What separates good from great:* The interaction effect - circuit-open fast-fails
count against rate limits if the caller retries. This can exhaust legitimate quota.
Rate limits should not penalize clients for downstream failures they cannot control.

---

**[SENIOR] Q5 (Debugging): Enterprise customers getting 429s after deploying rate limiting.**

Diagnosis: confirm legitimate requests (valid API keys, expected usage patterns), not
a misidentified attack. Check which limit tier is being hit.

Solutions:

Tiered rate limits by API key: enterprise keys get higher limits (1000 req/min vs 100
standard). Rate limiter reads tier from key metadata.

Endpoint-specific limits: bulk import legitimately bursts; login never should. Per-endpoint
configs, not a single global limit.

Async processing: accept bulk imports to a queue, process at controlled rate. Client
gets a job ID and polls. Eliminates submission rate limit.

Add headers to all responses: `X-RateLimit-Limit`, `X-RateLimit-Remaining`,
`X-RateLimit-Reset`. Clients implement proactive backoff before hitting 429.

*What separates good from great:* Involving sales/CS in defining enterprise limits.
They know which customers have legitimate high-volume patterns. Security defines the
tiering framework; account managers assign tiers with an approval workflow.

---

**[STAFF] Q6 (Deep Dive): Design adaptive rate limiting for an active attack.**

Adaptive rate limiting tightens limits for suspected attack traffic while maintaining
normal limits for legitimate users.

Key insight: attack traffic and legitimate traffic have different signatures. Attacks:
high error rates (401, 404 for non-existent accounts), bot user-agents, requests to
probe endpoints.

Architecture:

Signal collection: compute suspicion score per client from error rate ratio, user-agent
patterns, non-existent account probe rate.

Adaptive tiers:
- Clean (low score): normal limits
- Suspect (medium score): 50% limits + CAPTCHA challenges
- Blocked (high score): block or heavily throttle

Transitions: Clean → Suspect when score exceeds threshold over 5 minutes.
Suspect → Blocked on continued high score. Suspect → Clean when score drops and
stays low (hysteresis required).

Protecting legitimate users: authenticated users with clean account history maintain
normal limits regardless of IP suspicion score. IP reputation affects only anonymous traffic.

Hysteresis: down-transition threshold lower than up-transition. Without hysteresis,
clients oscillate between tiers every few requests.

*What separates good from great:* Define the false positive SLA before building:
"< 0.1% of legitimate requests incorrectly throttled." This sets threshold sensitivity
and determines how conservative suspicion scoring must be. An aggressive adaptive
system that blocks 5% of legitimate users causes more damage than it prevents.

---

**[MID] Q7 (Definition): What does a 429 response MUST include and why?**

A 429 Too Many Requests response is only half the answer. Without `Retry-After`,
it is useless to well-behaved clients: they have no idea when to retry and immediately
retry, creating a retry storm that amplifies the load exactly when the server is
already throttled.

Required headers on every 429:
- `Retry-After: <seconds>` or `Retry-After: <HTTP-date>` - RFC 7231 standard;
  indicates when the client may resume.
- `X-RateLimit-Limit: <N>` - the limit for this endpoint.
- `X-RateLimit-Remaining: 0` - confirms exhaustion.
- `X-RateLimit-Reset: <unix-timestamp>` - when the window resets.

Why it matters for security: without `Retry-After`, clients implement exponential
backoff heuristics that may back off too slowly (amplifying load) or too aggressively
(masking legitimate traffic). A well-formed 429 converts a retry storm into a polite
queue.

Semantic precision: 429 is specifically "too many requests" (the client exceeded its
quota). Use 503 for service-wide overload where rate limiting is not the cause - the
`Retry-After` semantic is the same, but 429 tells clients it is their own limit, not
a server problem.

*What separates good from great:* Distinguishing between per-endpoint and global-quota
429s. A client receiving a 429 from `/login` should not back off from `/products`. Rate
limiting headers scoped to the endpoint help clients make per-endpoint retry decisions.

---

**[SENIOR] Q8 (Mechanism): How do you prevent rate limit key forgery in user-based limiting?**

User-based rate limiting uses an authenticated identity as the key (user ID from JWT
or session). The vulnerability: if the key extraction is weak, attackers forge or
rotate keys to bypass limits.

Attack vector 1 - Unauthenticated key: rate limiting applied after authentication
check but the authentication fails silently. If a malformed JWT returns a null
principal and the code does `String key = principal != null ? principal.getId() : "anonymous"`,
all unauthenticated traffic shares one bucket.

Attack vector 2 - API key in query string: `?api_key=attacker_key` - the attacker
rotates to new keys (stolen from other accounts) to reset the bucket.

Attack vector 3 - IP spoofing via header injection: `X-Forwarded-For` spoofing.
If rate limiting uses `request.getHeader("X-Forwarded-For")` directly, an attacker
adds this header from their own client and cycles through IP addresses.

Defenses:
- Extract key from the validated JWT claim (server-signed, unforged).
- Reject unauthenticated requests at the gateway before rate limiting.
- For IP-based limits, use `getRemoteAddr()` from the direct TCP connection, not
  from X-Forwarded-For unless the proxy sets it (and strip attacker-supplied values).
- API keys: rate limit by both API key AND account ID to prevent stolen-key rotation.

*What separates good from great:* The fail-safe principle: if key extraction fails
(JWT parse error, missing claim), fail closed (reject or rate-limit as anonymous),
never bypass the limit.

---

**[SENIOR] Q9 (Trade-off): Rate limiting at the gateway vs at the application - what does each layer protect and when is both needed?**

Gateway rate limiting (Nginx, AWS API Gateway, Cloudflare): enforces limits before
any application code runs. Protects the application layer entirely from volumetric
attack traffic. Low overhead: no application CPU consumed by rejected requests.
Limitation: coarse-grained; typically per-IP or per-API-key; cannot apply
business logic (e.g., different limits based on account subscription tier).

Application rate limiting (Bucket4j, Spring filters): understands business context;
applies per-user limits, per-endpoint policies, tier-based quotas. Can access
authenticated identity from the JWT or session. Limitation: request reaches the
application before being rejected; application CPU consumed even for throttled requests.

Defense in depth requires both:

Layer 1 (gateway): reject volumetric attacks at the edge - no application cost.
Limit: 1000 req/min per IP (before auth).
Layer 2 (application): enforce business quotas by authenticated user.
Limit: standard tier 100 req/min, enterprise 1000 req/min.
Layer 3 (application): endpoint-specific sensitive limits.
Limit: login 5 attempts/15 min per account.

When only gateway is enough: public API without business-tier differentiation,
purely anonymous traffic.
When only application works: tier-based quotas, account-level credential protection.
When both required: production API with both volumetric and business threats.

*What separates good from great:* Accounting for gateway bypass. If the application
is reachable directly (no strict gateway enforcement), the gateway limit can be
bypassed. Application-level limits must function standalone; gateway limits are an
optimization layer, not the sole defense.
