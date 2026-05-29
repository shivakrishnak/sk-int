---
layout: default
title: "Design Patterns - L4 Security Patterns"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 14
permalink: /design-patterns/l4-security-patterns/
---

# Security Design Patterns

---
id: DP-029
title: Security Design Patterns
category: Design Patterns
difficulty: ★★★
interview_weight: critical
asked_at: Senior/Staff
seniority: senior
tags: #design-patterns, #security, #owasp, #proxy, #interceptor, #jwt, #spring-security
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Security design patterns solve recurring security problems with proven
> structural solutions. The five most critical for Java/Spring applications:
> (1) Security Proxy - intercept all access to apply authorization checks.
> (2) Interceptor/Filter Chain - chain of security checks (authentication,
> rate limiting, CSRF, CORS) before a request reaches the application.
> (3) Secure Factory - validate inputs before creating objects.
> (4) Token-based Identity - JWT/OAuth2 for stateless authentication.
> (5) Immutable Value Object - prevent accidental state mutation in security-
> sensitive objects (credentials, permissions).

**3 minutes (Senior):**
> The most impactful security patterns in Spring Boot: The Filter Chain
> (Spring Security's `SecurityFilterChain`) is a Chain of Responsibility
> for security. Each filter handles one concern: JWT extraction,
> authentication, CORS validation, CSRF protection, rate limiting. Filters
> are ordered - authentication must happen before authorization. The Proxy
> pattern is at the core of method-level security (`@PreAuthorize`):
> Spring wraps service methods in proxies that check permissions before
> invocation. The Decorator pattern is used by encryption utilities -
> `CipherInputStream` wraps any `InputStream` adding transparent encryption.
>
> The most dangerous anti-pattern in security: adding security checks
> inside business logic. `if (user.isAdmin()) { ... }` scattered through
> service methods is fragile - add a new entry point and the check is
> missed. Cross-cutting security (using AOP/Filter Chain) ensures no
> entry point is unprotected.
>
> From OWASP Top 10 perspective: the Interceptor Chain prevents Broken
> Access Control (#1 OWASP 2021). Input validation patterns prevent
> Injection (#3). Token patterns with proper validation prevent
> Authentication failures (#7). The key: security must be structural,
> not conditional.

**Blank Mind Recovery:**

**(1) Restate:** "Security design patterns - recurring structural solutions
for authentication, authorization, validation, and secure communication."

**(2) First principles:** "Security must be structural, not conditional.
Structural: every request passes through a validation chain.
Conditional: 'if admin' checks in business logic that can be missed."

**(3) Bridge:** "Like airport security: you do not add security checks
inside each shop. A mandatory checkpoint before entry screens everyone.
The shop owners trust that anyone who reached their shop has passed the
checkpoint. That checkpoint is the SecurityFilterChain."

---

### 📘 Concept Explanation

**The five core security patterns:**

**1. Security Proxy (Authorization Gate)**

A Proxy that enforces access control before delegating to the real
object. Spring Security implements this via AOP proxies (`@PreAuthorize`,
`@Secured`). Every call to a secured method goes through the proxy,
which checks permissions before proceeding.

```
Caller -> [Security Proxy] -> Real Method
                |
                |-- Loads SecurityContext
                |-- Evaluates permission expression
                |-- Throws AccessDeniedException if denied
                |-- Proceeds if permitted
```

**2. Interceptor / Filter Chain (Defense in Depth)**

A Chain of Responsibility for security concerns. Each filter has one
responsibility. Ordered such that: authentication establishes identity
first, then authorization checks permissions against the identity.

```
Request -> [JWT Filter] -> [AuthnFilter] -> [CORSFilter]
        -> [CSRFFilter] -> [RateLimitFilter]
        -> [Controller]
```

**3. Secure Factory (Input Validation)**

Validate all inputs at the point of object creation. The factory
(Builder or static factory) rejects invalid inputs before an object
is created. Invalid objects cannot exist.

**4. Token-based Identity (Stateless Authentication)**

Use signed, self-contained tokens (JWT) instead of server-side sessions.
The server does not store session state. Every request includes the
token. The server validates the token signature and extracts claims.
No shared state between server instances.

**5. Immutable Value Object (Safe Credential Representation)**

Security-sensitive data (credentials, tokens, permissions) are immutable.
Once created, they cannot be modified. This prevents accidental or
malicious modification of security state during a request.

**OWASP Top 10 to Pattern Mapping:**

| OWASP Threat | Pattern | Mechanism |
|---|---|---|
| Broken Access Control | Security Proxy + Filter Chain | Check at every entry point |
| Cryptographic Failures | Immutable + Secure Builder | Prevent weak algorithm choices |
| Injection | Secure Factory + Validator | Reject invalid input at creation |
| Insecure Design | Defense-in-Depth Chain | Structural security, not conditional |
| Auth Failures | Token-based Identity | Stateless, signed tokens |
| Security Misconfiguration | Secure Default Pattern | Deny-by-default, explicit allow |

---

### 💻 Code Example

```java
// PATTERN 1: Security Proxy with Spring AOP
// Spring Security applies a proxy around every @Service bean
// with @PreAuthorize annotations.
// The proxy intercepts method calls, checks permissions.

@Service
public class OrderService {

    @PreAuthorize("hasPermission(#orderId, 'ORDER', 'READ')")
    public Order getOrder(Long orderId) {
        // This code runs ONLY if permission check passes
        // No security code here - the proxy handles it
        return orderRepository.findById(orderId)
            .orElseThrow(OrderNotFoundException::new);
    }

    @PreAuthorize("hasRole('ADMIN') or "
        + "hasPermission(#order, 'ORDER', 'WRITE')")
    public Order updateOrder(Order order) {
        return orderRepository.save(order);
    }
}

// Custom PermissionEvaluator for complex rules
@Component
public class OrderPermissionEvaluator
        implements PermissionEvaluator {

    @Override
    public boolean hasPermission(Authentication auth,
            Object targetDomainObject, Object permission) {
        if (targetDomainObject instanceof Order order) {
            // Check if authenticated user owns this order
            return order.getUserId()
                .equals(auth.getName());
        }
        return false;
    }

    @Override
    public boolean hasPermission(Authentication auth,
            Serializable targetId, String targetType,
            Object permission) {
        if ("ORDER".equals(targetType)) {
            Order order = orderRepository
                .findById((Long) targetId)
                .orElse(null);
            if (order == null) return false;
            return order.getUserId()
                .equals(auth.getName());
        }
        return false;
    }
}
```

> **Code walkthrough:** `@PreAuthorize` is applied via a Spring AOP
> proxy. The expression `hasPermission(#orderId, 'ORDER', 'READ')` is
> evaluated by Spring's `PermissionEvaluator`. The custom evaluator
> fetches the order and checks that the authenticated user (from
> `Authentication`) owns it. No security code in `OrderService`. The
> proxy enforces: `AccessDeniedException` for unauthorized calls,
> transparent proceed for authorized calls.

```java
// PATTERN 2: Filter Chain for JWT Authentication
// Every request passes through these filters before reaching controllers
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http) throws Exception {
        return http
            // Disable session (stateless JWT)
            .sessionManagement(s -> s
                .sessionCreationPolicy(STATELESS))
            // CORS: allow only configured origins
            .cors(cors -> cors.configurationSource(
                corsConfigurationSource()))
            // CSRF: disabled for stateless REST APIs
            // (CSRF protection is for session-based apps)
            .csrf(AbstractHttpConfigurer::disable)
            // Authorization rules
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET,
                    "/api/public/**").permitAll()
                .anyRequest().authenticated())
            // Add JWT filter before standard auth filter
            .addFilterBefore(
                jwtAuthFilter,
                UsernamePasswordAuthenticationFilter.class)
            .build();
    }
}

// JWT extraction and validation filter
@Component
public class JwtAuthFilter
        extends OncePerRequestFilter {

    private final JwtValidator jwtValidator;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain)
            throws ServletException, IOException {

        String authHeader =
            request.getHeader("Authorization");
        if (authHeader == null
                || !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);
        try {
            String username =
                jwtValidator.extractUsername(token);
            // Only set if not already authenticated
            if (username != null
                    && SecurityContextHolder.getContext()
                        .getAuthentication() == null) {
                UserDetails userDetails =
                    userDetailsService
                        .loadUserByUsername(username);
                if (jwtValidator.isValid(
                        token, userDetails)) {
                    UsernamePasswordAuthenticationToken
                        authToken =
                            new UsernamePasswordAuthenticationToken(
                                userDetails, null,
                                userDetails.getAuthorities());
                    authToken.setDetails(
                        new WebAuthenticationDetailsSource()
                            .buildDetails(request));
                    SecurityContextHolder.getContext()
                        .setAuthentication(authToken);
                }
            }
        } catch (JwtException e) {
            // Invalid token: do not set authentication
            // Request will fail authorization checks
            log.warn("Invalid JWT token: {}", e.getMessage());
        }

        chain.doFilter(request, response);
    }
}
```

> **Code walkthrough:** `JwtAuthFilter` runs on every request before
> Spring Security's authentication processing. It extracts the Bearer
> token, validates it with `JwtValidator`, loads `UserDetails`, and sets
> the `Authentication` in `SecurityContextHolder`. If invalid: log and
> continue (the request will fail authorization). Never throw from the
> filter - let the downstream `ExceptionTranslationFilter` handle it with
> a proper 401 response. The filter returns `STATELESS` session policy:
> no `HttpSession` is created; every request must include a valid JWT.

```java
// PATTERN 3: Secure Factory with validation
// BAD: Object created without validation
public class ApiKey {
    private final String key;
    public ApiKey(String key) {
        this.key = key; // accepts any string, even empty
    }
}

// GOOD: Secure factory rejects invalid inputs at creation
public final class ApiKey {
    private static final Pattern VALID_KEY =
        Pattern.compile("^[A-Za-z0-9_-]{32,64}$");

    private final String value;

    private ApiKey(String value) {
        this.value = value;
    }

    public static ApiKey of(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                "API key cannot be null or blank");
        }
        if (!VALID_KEY.matcher(value).matches()) {
            throw new IllegalArgumentException(
                "Invalid API key format");
        }
        return new ApiKey(value);
    }

    // Prevent key exposure in logs
    @Override
    public String toString() {
        return "ApiKey[***]";
    }

    public String getValue() { return value; }

    // Immutable: no setters
}
```

> **Code walkthrough:** `ApiKey.of(value)` validates format before
> construction. Invalid API keys cannot exist as `ApiKey` objects - they
> are rejected at the boundary. The class is `final` (cannot be subclassed
> to bypass validation). `toString()` returns `"ApiKey[***]"` preventing
> accidental key logging. No setters: once created, the key value cannot
> change. This is the Secure Factory + Immutable Value Object combination.

```java
// PATTERN 4: Secure-Default configuration
// BAD: Explicit allow-list forgotten; all endpoints open
http.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/public/**").permitAll()
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    // Forgot: .anyRequest().authenticated()
    // All other endpoints are OPEN!
);

// GOOD: Deny-by-default - last rule denies everything
http.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/public/**").permitAll()
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated() // catch-all: deny if no rule
);

// Even better: denyAll() as the catch-all
http.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/public/**").permitAll()
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    .requestMatchers("/api/user/**").hasAnyRole(
        "USER", "ADMIN")
    .anyRequest().denyAll() // explicitly deny unknowns
);
```

> **Code walkthrough:** Security defaults should be the most restrictive
> option. `anyRequest().authenticated()` means all unmatched requests
> require authentication. `anyRequest().denyAll()` is stricter - unmatched
> requests are rejected even with valid credentials (they must be explicitly
> allowed). The BAD version forgets the catch-all: new endpoints are
> automatically open to the public. The GOOD version: new endpoints are
> automatically closed until explicitly opened. Fail-secure design.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Security patterns are proven structural solutions for security problems.
> In Spring Boot: the filter chain handles authentication and authorization
> before requests reach controllers. `@PreAuthorize` uses AOP proxies to
> check permissions before method execution. The key principle: security
> should be structural (applied to all requests via the chain) not
> conditional (if-checks inside business logic). Conditional checks are
> missed when new entry points are added.

---

**Senior / Staff (5+ years):**
> The most impactful security design decision in a Spring Boot application:
> where to place authorization. Three options: (1) Controller layer -
> early rejection, but requires auth logic in each controller. (2) Service
> layer with `@PreAuthorize` - centralized, but has the self-invocation
> limitation. (3) Filter chain - applies to all requests regardless of
> entry point. Defense-in-depth uses all three: filter chain for coarse-
> grained rules (authenticated user required), `@PreAuthorize` for resource-
> level rules (user owns this resource), and explicit checks in code for
> business-level rules (user has remaining quota).
>
> The OWASP Broken Access Control category (#1 in 2021) is addressed
> architecturally: deny-by-default in the filter chain, explicit allow-list
> for each endpoint, principle of least privilege for each role. Patterns
> enforce this: the Secure Default pattern makes every endpoint closed
> until explicitly opened, eliminating the "we forgot to secure endpoint X"
> failure mode.

---

### 🏛️ System Design

**Scenario: Design security for a multi-tenant SaaS API**

Requirements: 10,000 tenants, each with their own users and data.
Tenant A's data must never be accessible to Tenant B's users, even
if they share the same API endpoints.

**Security layers:**

```
Request
  |
  v
[1. Rate Limit Filter]
  - Per-tenant, per-endpoint rate limits
  - Redis: key = "rate:{tenantId}:{endpoint}"
  |
  v
[2. JWT Auth Filter]
  - Extract and validate JWT
  - Set Authentication in SecurityContext
  - JWT claims include: userId, tenantId, roles
  |
  v
[3. Tenant Isolation Filter]
  - Extract tenantId from JWT claims
  - Set in TenantContext (ThreadLocal)
  - Validate tenant is active (cache + DB)
  |
  v
[4. Spring Security Authorization]
  - .anyRequest().authenticated()
  - Method-level @PreAuthorize for fine-grained
  |
  v
[5. Tenant Data Filter (Hibernate)]
  - @FilterDef + @Filter on entities
  - Every query automatically adds
    WHERE tenant_id = :currentTenantId
  |
  v
Controller -> Service -> Repository
```

**Tenant isolation at data layer:**

```java
// Hibernate tenant filter applied to ALL queries
@FilterDef(name = "tenantFilter",
    parameters = @ParamDef(
        name = "tenantId", type = Long.class))
@Filter(name = "tenantFilter",
    condition = "tenant_id = :tenantId")
@Entity
public class Order {
    @Column(name = "tenant_id")
    private Long tenantId;
    // ...
}

// Enable filter on every request
@Component
public class TenantFilterAspect {
    @Before("execution(* com.example.repository.*.*(..))")
    public void enableFilter(JoinPoint jp) {
        Session session = entityManager.unwrap(Session.class);
        session.enableFilter("tenantFilter")
            .setParameter("tenantId",
                TenantContext.getCurrentTenantId());
    }
}
```

**Trade-offs:**

- Database-level tenant filtering: hardest to bypass, adds query complexity.
- Application-level filtering: simpler, but can be bypassed if a developer
  forgets to add the filter to a new query.
- Separate database per tenant: maximum isolation, high cost for 10,000 tenants.

---

### 📊 Diagram

```
Spring Security Filter Chain

Request
  |
  +-> [ExceptionTranslationFilter] <--+
  |   (catch 403/401, return JSON)    |
  |                                   |
  +-> [JwtAuthFilter] ----------------+
  |   (extract JWT, set auth context) | throws
  |                                   |
  +-> [SessionMgmtFilter]             |
  |   (stateless: no session)         |
  |                                   |
  +-> [FilterSecurityInterceptor]     |
  |   (check URL authorization rules) |
  |                                   |
  +-> DispatcherServlet               |
  |                                   |
  +-> [Security Proxy on Service]-----+
      (@PreAuthorize check)
```

```mermaid
flowchart TD
    A[Incoming Request] --> B[Rate Limit Filter]
    B -->|Limit exceeded| E1[429 Too Many Requests]
    B -->|OK| C[JWT Auth Filter]
    C -->|Invalid/missing token| E2[401 Unauthorized]
    C -->|Valid| D[Tenant Context Filter]
    D -->|Tenant inactive| E3[403 Forbidden]
    D -->|OK| F[URL Authorization]
    F -->|Access denied| E4[403 Forbidden]
    F -->|OK| G[Controller]
    G --> H[Service Layer]
    H --> I{Security Proxy}
    I -->|@PreAuthorize failed| E5[403 Forbidden]
    I -->|OK| J[Repository]
    J --> K[Tenant-Filtered Query]
    K --> L[Response]
```

> **Diagram walkthrough:** The flowchart shows defense-in-depth:
> four separate checkpoints before business logic executes. Rate limiting
> is outermost (protects infrastructure). JWT validation establishes
> identity. Tenant context ensures data isolation at the application layer.
> URL authorization enforces coarse-grained rules. Service-level proxies
> enforce resource-level rules. Each layer has one responsibility and
> fails fast with an appropriate HTTP status code. An attacker must bypass
> all five layers to reach the data.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Disabling CSRF is always wrong"**

Reality: CSRF attacks exploit session cookies sent automatically by browsers.
For stateless REST APIs that use JWT in the `Authorization` header (not
cookies), CSRF is not applicable. The browser cannot forge a request with
a JWT in the `Authorization` header. Disabling CSRF for JWT-based stateless
APIs is correct. Disabling CSRF for session-based web applications is a
security vulnerability.

**Misconception 2: "@PreAuthorize is enough; no need for filter chain rules"**

Reality: `@PreAuthorize` has the self-invocation limitation and only
applies to Spring-managed beans. The filter chain applies to every HTTP
request regardless of how the controller is called. Defense-in-depth:
filter chain for URL-level rules + `@PreAuthorize` for method-level rules.

**Misconception 3: "JWT tokens cannot be revoked"**

Reality: Standard JWT cannot be revoked without server state. But:
(1) short expiry (15 minutes) + refresh token pattern minimizes the
window. (2) JWT blacklist in Redis: store revoked JTI (JWT ID) claims.
Check on every request. O(1) lookup. TTL matches JWT expiry (auto-clean).
(3) Version claim: user has a token version in the database. JWT includes
the version at issuance. If DB version > JWT version: token is revoked
(password change, logout-all).

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Authorization bypass via unprotected endpoint**

Symptom: sensitive data accessible without authentication.

Diagnosis: check the `SecurityFilterChain` `authorizeHttpRequests` rules.
Is there a `permitAll()` that is too broad? Does the chain have a missing
`anyRequest().authenticated()` catch-all?

```bash
# Enable Spring Security debug logging
logging.level.org.springframework.security=DEBUG
# Every request shows which rules matched:
# "Checking authorization for [GET /api/orders] with matcher..."
# "Granting access to /api/orders"
```

**Failure 2: JWT validation not rejecting expired tokens**

Symptom: API accepts expired JWTs.

Diagnosis: check the JWT validator's clock skew setting. A misconfigured
large clock skew (e.g., `allowedClockSkewSeconds=3600`) means tokens
expired up to 1 hour ago are still accepted.

```java
// Check the JWT validator configuration
Jwts.parserBuilder()
    .setSigningKey(signingKey)
    .setAllowedClockSkewSeconds(60) // max 60 seconds skew
    .build()
    .parseClaimsJws(token); // throws ExpiredJwtException if expired
```

**Failure 3: Tenant data leak (wrong tenant_id in context)**

Symptom: Tenant B's records appear in Tenant A's responses.

Diagnosis: `TenantContext` uses `ThreadLocal`. Check for thread pool
reuse without clearing the context. Async methods that do not propagate
the `TenantContext`. Thread pool tasks that start without initializing
the tenant context.

```java
// Always clear after request
@Component
public class TenantContextFilter implements Filter {
    public void doFilter(...) throws IOException, ServletException {
        try {
            TenantContext.setCurrentTenantId(extractTenantId(request));
            chain.doFilter(request, response);
        } finally {
            TenantContext.clear(); // critical: prevents thread reuse leak
        }
    }
}
```

**Failure 4: Mass assignment vulnerability**

Symptom: users can modify fields they should not (e.g., setting their
own `isAdmin` flag via JSON deserialization).

Diagnosis: DTOs with `@JsonProperty` on all fields including sensitive ones.

```java
// BAD: Any field in the JSON is accepted
public class UserUpdateRequest {
    private String name;
    private String email;
    private boolean admin; // user can set this!
}

// GOOD: DTO has only fields users can set
public class UserUpdateRequest {
    private String name;
    private String email;
    // No isAdmin field: Jackson cannot bind it
}
// Alternatively: @JsonIgnoreProperties(ignoreUnknown=true)
// on the DTO class, and use @JsonIgnore on admin field
```

---

### 🎯 Interview Deep-Dive

| Format | Time | Goal |
|---|---|---|
| 30-second definition | 0-30s | Structural patterns for auth/authz/validation |
| 3-minute explanation | 30s-3m | Filter chain, proxy, secure factory, OWASP |
| Deep questions | 3m+ | Mechanisms, production impact, trade-offs |

**Minimum 12 questions for ★★★:**

---

**Q1 (DEFINITION): What are security design patterns? Name the top 3 for
a Spring Boot REST API.**

A: Security design patterns are proven structural solutions for recurring
security problems. They are patterns in the GoF sense - recurring structural
solutions - but applied specifically to security concerns. Top 3 for Spring
Boot REST: (1) Filter Chain (Chain of Responsibility) - Spring Security's
`SecurityFilterChain` is a chain of security filters each responsible for
one security concern. Defense-in-depth through layered checks. (2) Security
Proxy (`@PreAuthorize` via AOP) - a proxy around service methods that
checks permissions before delegating to the real method. (3) Token-based
Identity (JWT) - stateless authentication via signed tokens. Every request
carries credentials; no server session state.

*What separates good from great:* Recognizing that Spring Security is
an implementation of multiple security patterns working together - not
just "security configuration." The filter chain is Chain of Responsibility.
Method security is Proxy. UserDetails is the Identity aggregate.
The overall framework combines 5+ patterns.

---

**Q2 (MECHANISM): How does Spring Security's filter chain work internally?
What is `DelegatingFilterProxy`?**

A: Spring Security integrates with the servlet container through
`DelegatingFilterProxy`. This is a standard `javax.servlet.Filter` registered
with the servlet container. When a request arrives, `DelegatingFilterProxy`
delegates to a Spring bean named `springSecurityFilterChain` (a `FilterChainProxy`).
`FilterChainProxy` holds a list of `SecurityFilterChain` beans, each
containing an ordered list of security filters. For each request,
`FilterChainProxy` finds the first `SecurityFilterChain` whose
`RequestMatcher` matches the request, then executes that chain's filters
in order.

This design allows: (1) Spring-managed beans as servlet filters (they
get DI). (2) Multiple filter chains for different URL patterns
(e.g., a different chain for `/api/v1/**` and `/admin/**`).
(3) Conditional filter chain selection per request.

The `DelegatingFilterProxy` bridge is necessary because the servlet
container initializes filters before the Spring context, so a direct
reference to a Spring bean is not possible at that time.

*What separates good from great:* Knowing that you can have multiple
`SecurityFilterChain` beans ordered by `@Order`. The first one whose
`requestMatcher` matches is used. This allows different security rules
for different URL patterns without complex if/else in one configuration.

---

**Q3 (FAILURE): Explain the OWASP Broken Access Control vulnerability and
how security patterns prevent it.**

A: Broken Access Control (#1 OWASP 2021) occurs when access control
checks are inconsistent, missing, or bypassable. Common manifestations:
(1) A new endpoint is added without security configuration - all users
can access it. (2) A user modifies a URL parameter to access another
user's resource (`/orders/123` -> `/orders/124`). (3) A function that
is "hidden in the UI" but not protected on the API.

Prevention through patterns: (1) Secure Default (deny-by-default):
`anyRequest().denyAll()` in the filter chain catches any new endpoint that
lacks explicit security rules. Without this, forgetting to add a rule
means the endpoint is open. (2) Security Proxy with object-level checks:
`@PreAuthorize("hasPermission(#orderId, 'ORDER', 'READ')")` verifies the
authenticated user has rights to the specific resource, not just the
resource type. Prevents IDOR (Insecure Direct Object Reference). (3)
Security tests: integration tests with different user roles asserting
403 for unauthorized access - catches regressions before deployment.

*What separates good from great:* Object-level authorization (checking
ownership, not just role) is the specific gap that causes Broken Access
Control. `hasRole('USER')` is insufficient: any user can access any other
user's order. `hasPermission(#orderId, 'ORDER', 'READ')` checks that THIS
user can access THIS specific order.

---

**Q4 (MECHANISM): How does JWT validation work? What must be validated?**

A: A JWT has three parts: Header (algorithm + token type), Payload (claims:
subject, expiry, issued-at, custom claims), Signature. Validation steps:
(1) Signature verification: the server re-computes the HMAC-SHA256 (or
RSA signature) of `base64(header).base64(payload)` using the secret key.
If it does not match the token's signature: tampered token, reject.
(2) Expiry check (`exp` claim): if `currentTime > exp`: expired token, reject.
(3) Not-before check (`nbf` claim): if `currentTime < nbf`: token not yet
valid, reject. (4) Issuer check (`iss` claim): if issuer does not match
expected value: foreign token, reject. (5) Audience check (`aud` claim):
if this service is not in the audience: token not intended for this service,
reject. All five checks are mandatory. Many implementations skip issuer
and audience checks, allowing token confusion attacks (a valid token for
service A is accepted by service B).

Algorithm selection: use asymmetric (RS256, ES256) for multi-service
environments where multiple services validate tokens but only the auth
server issues them. Use symmetric (HS256) only for single-service
environments. Never use `alg: none` (disabled by default in all modern
libraries but was a historical vulnerability).

*What separates good from great:* The "alg confusion" attack: an old JWT
library allowed the `alg` header to be changed by the attacker. Changing
from RS256 to HS256 and signing with the public key (which is not secret)
created valid-appearing tokens. Modern libraries like `jjwt` and `nimbus`
reject algorithm confusion by requiring the algorithm to be specified
at the server, not read from the token.

---

**Q5 (PRODUCTION): A security audit found JWTs stored in localStorage.
What is the risk and fix?**

A: `localStorage` is accessible to JavaScript, including any script loaded
on the page (first-party, third-party, CDN scripts). An XSS attack can
read all `localStorage` values including JWT tokens. The attacker can then
make API calls on behalf of the user from a different origin (the token
is not tied to origin).

Risk level: high if XSS is possible anywhere on the site. One vulnerable
input field (in any part of the application, including marketing pages)
can expose all JWTs.

Fix options: (1) `HttpOnly` + `Secure` cookies: the browser sends the
cookie automatically but JavaScript cannot read it. XSS cannot steal
the token (but CSRF must be re-enabled for cookie-based auth).
(2) Memory storage (React state, Vuex): token lives in JavaScript memory.
XSS within the same page context can still read it, but it does not
survive page reload (lower risk window). (3) Service Worker storage:
token stored in a Service Worker context, not accessible to page scripts.
Complex but secure.

The pragmatic approach: `HttpOnly Secure` cookies for the refresh token
(long-lived). Short-lived access JWT (15 minutes) in memory. CSRF token
for cookie-protected endpoints.

*What separates good from great:* Knowing that `HttpOnly` cookies prevent
XSS token theft but introduce CSRF risk. The combination of `HttpOnly`
cookie + CSRF token + short JWT expiry + token refresh is the current
industry practice. No single storage option is perfect; the combination
minimizes the attack surface.

---

**Q6 (DEBUGGING): A user reports they are logged out unexpectedly. How do
you diagnose?**

A: Likely causes: (1) JWT expiry: the token has expired. Check the token's
`exp` claim. (2) Token blacklisted: the user changed their password or
explicitly logged out from all devices. Check the blacklist/version store.
(3) Clock skew: the client and server clocks differ; the server's clock
is ahead. JWT appears expired to server but valid to client. (4) Refresh
token expiry: the refresh token (longer-lived) has expired; user must
re-authenticate. (5) Session invalidation: if a `sessionManagement` is
configured incorrectly, sessions may be invalidated.

Diagnosis:
```bash
# Decode the JWT (header + payload are base64, not encrypted)
echo "<jwt_payload>" | base64 -d | python3 -m json.tool
# Check: exp (expiry), iat (issued at), nbf (not before)

# Check server logs for 401 responses
# Filter: grep "401" access.log | grep "userId=123"

# Check token validation code for clock skew tolerance
# jjwt: setAllowedClockSkewSeconds should be 60-300s

# Check if token blacklist is aggressively populated
# Redis: SMEMBERS token:blacklist | wc -l
```

*What separates good from great:* Differentiating between "token expired"
(expected behavior) and "token blacklisted" (server-side action). Both
produce 401 but have different root causes. Log the rejection reason in
the JWT filter: `log.debug("Token rejected: {}", rejectionReason)`.

---

**Q7 (TRADE-OFF): Stateless JWT vs stateful session - when to use each?**

A: JWT (stateless): no server-side state. Every request is self-contained.
Scales horizontally with zero session synchronization. No sticky sessions
needed. Token cannot be revoked without additional infrastructure
(blacklist). All claims travel with every request (larger headers).
Suitable: high-scale APIs, microservices where any instance handles
any request, mobile apps.

Stateful session: server stores session state (Redis or in-memory).
Session ID in cookie is small (vs JWT). Instant revocation: delete the
session from Redis. Session can store arbitrary server-side state. Requires
session synchronization for horizontal scaling (Redis or sticky sessions).
Suitable: web applications with complex session state, admin panels where
revocation speed matters, applications using CSRF protection.

Hybrid: short-lived JWT access tokens (15 minutes) + long-lived refresh
token (30 days) stored in HttpOnly cookie. Revocation: invalidate the
refresh token (server-side check). Access token expires quickly without
needing a blacklist. Refresh endpoint is rate-limited.

*What separates good from great:* Understanding that "stateless JWT" is
not truly stateless if you implement revocation via a blacklist - you
have server state again. The question becomes: is it cheaper to maintain
a blacklist (O(1) lookup, Redis) or maintain full sessions (larger storage,
session sync). For large user bases (10M+): Redis blacklist of revoked
tokens is smaller than 10M active sessions.

---

**Q8 (SECURITY): What is SQL injection and how do security patterns prevent it?**

A: SQL injection occurs when untrusted input is concatenated into SQL strings,
allowing an attacker to alter the query structure. The attacker can: extract
all data, bypass authentication, modify data, delete tables.

Prevention through patterns: (1) Parameterized queries (Secure Factory
for queries): use `PreparedStatement` with `?` placeholders. The database
treats the parameter as data, never SQL. Spring's `JdbcTemplate`,
Hibernate, and JPA all use prepared statements by default. (2) Input
validation (Secure Factory for inputs): validate and whitelist inputs
before they reach the query layer. Do not blacklist SQL keywords - attackers
use encoding variations. (3) ORM (Structural prevention): Hibernate and
JPA generate parameterized queries. Raw `@NativeQuery` with string
concatenation bypasses this protection.

```java
// VULNERABLE: string concatenation
String query = "SELECT * FROM users WHERE name = '"
    + username + "'";
// Input: "admin'--" -> bypasses password check

// SAFE: parameterized query
String query = "SELECT * FROM users WHERE name = ?";
preparedStatement.setString(1, username);
// Input "admin'--" is treated as a literal string
```

*What separates good from great:* Knowing that Hibernate protects against
SQL injection for JPQL queries by default, but `@NativeQuery` with string
building is not protected. `@Query(value = "SELECT * FROM users WHERE name = '"
+ name + "'", nativeQuery = true)` in a Spring Data repository is a SQL
injection vulnerability even in a Hibernate application.

---

**Q9 (ARCHITECTURE): Design the authorization model for a multi-role
SaaS application.**

A: Three tiers: (1) Coarse-grained: URL-level rules in `SecurityFilterChain`.
Public endpoints, authenticated endpoints, admin endpoints. Rejects
completely unauthorized requests before they reach the application.
(2) Role-based: `@PreAuthorize("hasRole('ADMIN')")` on service methods.
Role: ADMIN, MANAGER, USER, READ_ONLY. Controls which operations are
allowed by role type. (3) Resource-level: `@PreAuthorize("hasPermission(#id, 'Order', 'READ')")`.
Custom `PermissionEvaluator` checks ownership, team membership, or ACL.

ACL model for complex permissions:
```
User U -> has Role R -> Role R has Permission P on Resource R-Type
  or
User U -> has direct ACL entry for Resource ID
```

Spring Security ACL module: stores ACL entries in the database
(`acl_object_identity`, `acl_entry`). `@PostAuthorize` filters query
results to owned objects. Suitable for document management, CRM systems.

*What separates good from great:* Knowing the trade-off between RBAC
(Role-Based Access Control) and ABAC (Attribute-Based Access Control).
RBAC: simple (roles), coarse (all orders or no orders). ABAC: complex
(user attribute + resource attribute + environment condition), fine-grained
(own orders, or orders in own department, or orders before a date).
Most SaaS applications need a hybrid: RBAC for operation types, ABAC
for resource ownership.

---

**Q10 (FAILURE): Describe a security misconfig where Spring Security's
`permitAll()` created a vulnerability.**

A: A common pattern: configuring `permitAll()` for actuator health endpoints
but accidentally including sensitive actuator endpoints.

```java
// VULNERABLE: broad permitAll includes sensitive endpoints
http.authorizeHttpRequests(authz -> authz
    .requestMatchers("/actuator/**").permitAll() // too broad
    .anyRequest().authenticated());

// Sensitive: /actuator/env (environment variables, secrets!)
// /actuator/heapdump (heap dump with passwords in memory)
// /actuator/loggers (change log levels at runtime)
// All exposed without authentication.
```

Fix:
```java
// Precise: only health and info are public
http.authorizeHttpRequests(authz -> authz
    .requestMatchers("/actuator/health",
        "/actuator/info").permitAll()
    .requestMatchers("/actuator/**").hasRole("MONITORING")
    .anyRequest().authenticated());
```

This vulnerability exposed environment variables (database passwords,
API keys) to any internet user through `/actuator/env`. Exploited in
real incidents. OWASP 2021 #5: Security Misconfiguration.

*What separates good from great:* Knowing which Spring Boot Actuator
endpoints are sensitive. `env`, `heapdump`, `threaddump`, `conditions`,
and `configprops` contain sensitive data. `health` and `info` are safe.
Security reviews should explicitly check actuator endpoint exposure.

---

**Q11 (SCALE): How does JWT validation scale to 100,000 requests per second?**

A: JWT validation is CPU-bound (cryptographic signature verification).
At 100,000 rps with RS256: 100,000 RSA verifications per second. RSA-256
verification: ~0.1ms on modern hardware. 100,000 * 0.1ms = 10,000ms of
CPU work per second. With 8 cores: 10,000/8 = 1,250ms of CPU per core per
second. CPU bound but manageable on modern multi-core hardware.

Optimization: (1) HMAC-SHA256 (symmetric, HS256) is 50-100x faster than
RSA verification. If you control both issuer and verifier: use HS256.
(2) Cache validated tokens: for 15-minute tokens, a 15-minute TTL cache
keyed by token hash avoids re-validating the same token on every request.
Use `Caffeine` (in-process) or Redis (distributed). Cache invalidation:
TTL-based (token expires naturally). Size: 100,000 active tokens * ~2KB
per entry = 200MB cache. Manageable. (3) Algorithm selection: ES256
(ECDSA with P-256) is faster than RS256 for verification while maintaining
asymmetric key benefits.

*What separates good from great:* The cache trade-off: a cached valid
token that was subsequently revoked (user logged out) is still accepted
until the cache entry expires. For a 15-minute token cache, revocation
is delayed by up to 15 minutes. This is acceptable for most applications.
For immediate revocation: combine cache with a Redis blacklist check.
Cache hit: valid token, not in blacklist = accept. Cache hit: valid token,
in blacklist = reject. Cache miss: validate from scratch, then cache.

---

**Q12 (BEHAVIORAL): Walk through your security review process for a new
Spring Boot microservice.**

A: A systematic security review: (1) Authentication: is the service
protected by JWT or mutual TLS? Are all endpoints authenticated except
explicitly public ones? Check the `SecurityFilterChain` for `anyRequest().authenticated()`.
(2) Authorization: are role-based rules defined per endpoint? Are object-
level ownership checks implemented for user-scoped resources?
Check `@PreAuthorize` on service methods, confirm `PermissionEvaluator`
is custom and tested. (3) Input validation: are all DTOs validated with
`@Valid`? Are SQL queries parameterized (no string concatenation)?
Are file uploads validated for type and size? (4) Actuator security:
are actuator endpoints protected? Is `heapdump` and `env` blocked?
(5) Dependency audit: run `mvn dependency:check` or Dependabot. No
OWASP CVE in dependencies. (6) Secret management: no secrets in code,
properties files, or environment variables logged in startup. Secrets
from Vault or AWS Secrets Manager. (7) Security test coverage: is there
a test that confirms unauthorized users receive 403 for every protected
endpoint? Does the CI pipeline include a security test suite?

Automated checks: OWASP Dependency Check plugin in Maven/Gradle for
CVE scanning. SAST (Static Application Security Testing) with SpotBugs
and FindSecBugs. Dynamic security scanning with OWASP ZAP in the CI pipeline.

*What separates good from great:* Security reviews are checklists, but
the most impactful items are architectural: deny-by-default (not forgettable),
object-level authorization (not role-only), and no secrets in code (not
patchable after a breach). Checklists catch configuration errors; architecture
prevents categories of vulnerability.
