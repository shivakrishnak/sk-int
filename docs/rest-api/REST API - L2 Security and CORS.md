---
layout: default
title: "REST API - L2 Security and CORS"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 5
permalink: /rest-api/l2-security-and-cors/
render_with_liquid: false
---

# Authentication in REST APIs

---

### 🎯 Model Answer

**30 seconds:**
> REST API authentication verifies that the caller is who they claim to be. The three main mechanisms are API keys (simple, for server-to-server), HTTP Basic Auth (username/password, only for server-to-server over HTTPS), and JWT Bearer tokens (for user-facing APIs). OAuth2 is the authorization framework that issues JWTs and manages token lifecycle for third-party delegated access.

**3 minutes:**
> Authentication is the first security gate every REST API needs. The mechanism choice depends on the client type and trust model. API keys: fixed secrets assigned to a client application. `X-API-Key: sk-prod-abc123`. Simple to implement, no token expiry, easy to revoke. Used for server-to-server communication where the key is stored in a secret manager. The risks: API keys are long-lived and if leaked, valid until explicitly revoked. Must be stored securely (AWS Secrets Manager, not environment variables in source code). JWT Bearer tokens: issued after authentication, short-lived (15 minutes typical). `Authorization: Bearer eyJ0eXAi...`. Self-contained: the JWT payload includes user identity, roles, and expiry. The server verifies the JWT signature cryptographically (no database lookup). JWT enables stateless authentication (any server verifies the token). OAuth2 + OpenID Connect: the standard framework for user-facing and third-party delegation. User authenticates with an identity provider (Google, Okta, Cognito). The IDP issues an access token and ID token. The API validates the token against the IDP's public keys. This separates authentication (who are you?) from your API (what can you access?). For API-to-API: use OAuth2 client credentials flow (client_id + client_secret exchange for access token). For user-facing: OAuth2 authorization code flow with PKCE.

**Blank Mind Recovery:**
**(1) Restate:** "REST authentication - verifying who is calling the API."
**(2) First principles:** "Three questions: Who is the caller? How do they prove it? How long is the proof valid?"
**(3) Bridge:** "API key is a permanent badge. JWT is a time-limited day pass. OAuth2 is the system that issues day passes from a central security desk."

---

### 📘 Concept Explanation

**What it is:**
REST API authentication is the mechanism by which the API verifies the identity of the caller and establishes authorization context for the request. Unlike web session authentication, REST authentication is stateless - each request carries its own credentials.

**The problem it solves:**
REST APIs without authentication are accessible to anyone. Authentication restricts access to authorized clients. Combined with authorization (what the authenticated caller can do), authentication forms the access control foundation.

**How it works:**
```
Authentication Flows:

API Key (server-to-server):
  Client                Server
    | X-API-Key: sk-123   |
    |-------------------->|
    | validate key in DB  |
    | or cache lookup     |
    |<-----------200 OK---|

JWT (user-facing):
  Client                Server
    | POST /login         |
    | {email, password}   |
    |-------------------->|
    | validate credentials|
    | issue JWT           |
    |<----JWT token-------|
    |                     |
    | Authorization:      |
    | Bearer {jwt}        |
    |-------------------->|
    | verify JWT sig      |
    | extract user claims |
    |<-----------200 OK---|

OAuth2 Code Flow (third-party):
  User -> Client -> IDP -> Client -> API
  1. Client redirects user to IDP
  2. User authenticates with IDP
  3. IDP returns authorization code
  4. Client exchanges code for tokens
  5. Client calls API with access token
  6. API validates token with IDP keys
```

**The key insight:**
The authentication mechanism should match the client type. Browser-based clients need OAuth2 flows (user interaction required). Server-to-server clients use API keys or client credential OAuth2 (no user interaction). Mobile apps use OAuth2 with PKCE (no client secret, uses code verifier). Choosing the wrong mechanism creates security vulnerabilities: embedding a client secret in a mobile app leaks the secret to any user who decompiles the app.

**When to use it:**
Every REST API must use authentication. Public read APIs (weather data, public content) may have rate-limited unauthenticated access but should still require API keys for tracking and abuse prevention.

**When NOT to use it:**
Internal health-check endpoints (`/health`, `/ready`) typically bypass authentication. Static file serving doesn't need API authentication.

**Alternatives:**
- mTLS (mutual TLS): certificate-based authentication for service-to-service. Stronger than API keys (no shared secret to leak). More operational complexity.
- HMAC signatures: the client signs the request with a shared secret. Used by AWS API authentication. Prevents replay attacks and message tampering.

**First-principles derivation:**
Any resource with access restrictions needs a mechanism to verify who is requesting it. The verification must be unforgeable (cryptographic signature), time-limited (prevents replay attacks), and revocable (compromise response). JWTs satisfy forgery prevention (signature) and time-limit (exp claim) but require a token blacklist for revocation. API keys satisfy forgery prevention (secret) and revocability (delete from store) but are long-lived. The right choice depends on which properties matter most for the use case.

---

### 💻 Code Example

```java
// BAD: Embedding API key in URL
// GET /api/users?apiKey=sk-prod-abc123
// - Key visible in URL, appears in server logs
// - Key visible in browser history

// GOOD: API key in header
@Component
public class ApiKeyAuthFilter
    extends OncePerRequestFilter {

  private final ApiKeyService apiKeyService;

  @Override
  protected void doFilterInternal(
      HttpServletRequest request,
      HttpServletResponse response,
      FilterChain chain)
      throws ServletException, IOException {

    String apiKey = request.getHeader("X-API-Key");

    if (apiKey == null || apiKey.isBlank()) {
      response.sendError(
          HttpServletResponse.SC_UNAUTHORIZED,
          "API key required");
      return;
    }

    // Validate key (use constant-time comparison)
    ApiClient client =
        apiKeyService.validateKey(apiKey);

    if (client == null) {
      response.sendError(
          HttpServletResponse.SC_UNAUTHORIZED,
          "Invalid API key");
      return;
    }

    // Set authentication context
    SecurityContextHolder.getContext()
        .setAuthentication(
            new ApiKeyAuthentication(client));

    chain.doFilter(request, response);
  }
}

// JWT validation with Spring Security
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Bean
  public SecurityFilterChain filterChain(
      HttpSecurity http) throws Exception {
    return http
        .csrf(csrf -> csrf.disable()) // REST API
        .sessionManagement(session ->
            session.sessionCreationPolicy(
                SessionCreationPolicy.STATELESS))
        .oauth2ResourceServer(oauth2 ->
            oauth2.jwt(Customizer.withDefaults()))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/health").permitAll()
            .requestMatchers("/v1/admin/**")
                .hasRole("ADMIN")
            .anyRequest().authenticated())
        .build();
  }
}
```

> **Code walkthrough:** The BAD pattern puts the API key in the URL - this makes it visible in server logs, browser history, and any proxy that logs URLs. The GOOD pattern reads the key from the `X-API-Key` header. The ApiKeyAuthFilter validates the key using constant-time comparison (prevents timing attacks) and sets the Spring SecurityContext. The SecurityConfig configures JWT validation via `oauth2ResourceServer` - Spring Security automatically validates JWT signatures, expiry, and audience. The session policy is STATELESS (no session created for REST).

---

### 🎓 Answers by Seniority

**Junior / Mid:** "REST APIs use authentication to verify who is making requests. There are three common methods: API keys sent in a header (X-API-Key) for simple cases, JWT tokens sent in Authorization: Bearer for user-facing APIs, and OAuth2 for user login flows and third-party access. I use Spring Security to handle JWT validation - it automatically checks the signature and expiry. Every authenticated endpoint has `.authenticated()` in the security config."

**Senior / Staff:** "Authentication mechanism selection is a security architecture decision. For user-facing APIs: OAuth2 authorization code flow with PKCE. Use an IDP (Okta, Auth0, AWS Cognito) rather than building authentication yourself - auth is a solved problem with many edge cases (MFA, account recovery, breach monitoring). Your API becomes an OAuth2 resource server that validates the IDP-issued token. For service-to-service: OAuth2 client credentials if you're already in an OAuth2 ecosystem. mTLS if security is the primary concern (certificate revocation is faster than token revocation, no shared secret). API keys if simplicity is paramount and you have a good key rotation process. The token validation decision: verify JWT signatures locally (using IDP's public keys cached via JWKS endpoint) for performance, rather than calling the IDP's introspection endpoint per request. JWKS key rotation: cache keys with a 1-hour TTL, retry with fresh keys when signature validation fails (handles key rotation). At staff level: token revocation is the unsolved problem. JWT access tokens are valid until expiry even after logout. The solutions (blacklist, short expiry, token versioning) each have costs. Design the token lifetime based on the security requirements."

---

### ⚠️ Common Misconceptions

**Misconception:** "JWT authentication means my API is secure."
Reality: JWT authentication verifies identity - it does not provide security by itself. Authentication without authorization allows any authenticated user to access any resource. Authorization without proper input validation allows SQL injection regardless of authentication. The OWASP API Security Top 10 issues (broken object-level authorization, broken function-level authorization, mass assignment) all occur in authenticated contexts. JWT is one security layer. The complete picture requires: authentication (JWT/OAuth2), object-level authorization (user can only access their own records), function-level authorization (role-based access for admin functions), input validation (prevent injection), output encoding (prevent leaking sensitive data), and rate limiting (prevent brute force and DoS).

---

### 🚨 Failure Modes and Diagnosis

**Failure: API keys exposed in application logs**

Symptoms: Security audit finds API keys appearing in log files in plain text. APM tool captures HTTP request headers including X-API-Key values. An API key from a production system appears in a log aggregation tool accessible to the ops team.

Root cause: The logging configuration captures full HTTP headers for request logging. The X-API-Key header is not excluded from logging. A common Spring Boot default with request logging interceptors that log all headers.

Diagnosis: Search log files: `grep -r "X-API-Key" /var/log/appname/`. Check APM tool request traces for header values.

Fix: Configure request logging to redact sensitive headers. Spring: configure `CommonsRequestLoggingFilter` to exclude headers or use a custom filter that masks Authorization and X-API-Key values before logging. APM tools: configure Datadog/Dynatrace/New Relic to redact headers matching patterns (Authorization, X-API-Key, Cookie). Rotate all API keys that appeared in logs. Audit who had access to the logs.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Comparison | 3 min | 2 |
| Mechanism | 3 min | 1 |
| Security | 3 min | 2 |
| Debugging | 2 min | 1 |
| Design | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Behavioral | 2 min | 1 |

#### Q1 - "Compare API keys vs JWT tokens for REST API authentication."
> "API keys: fixed secrets assigned to a client. Pros: simple (one header), no expiry complexity, easy to revoke (delete from store), no IDP dependency. Cons: long-lived (if leaked, valid until manually revoked), no built-in user context (requires lookup to associate with a user), no fine-grained permissions in the key itself, key rotation requires client coordination. Use cases: server-to-server integration, developer API keys, internal tool integrations. JWT tokens: short-lived signed tokens with embedded claims. Pros: stateless verification (no DB lookup), carry user context (userId, roles, email), short-lived (15 min typical), standard format (every language has a JWT library). Cons: cannot revoke before expiry without a blacklist, larger payload (500-1500 bytes vs 32-byte key), requires IDP or token issuance infrastructure. Use cases: user-facing APIs, OAuth2 delegated access, microservice authentication. The key difference: API keys are identity for applications. JWTs are identity for users (or services acting on behalf of users). For both: key and token must be stored securely (AWS Secrets Manager, not .env files in repos), transmitted only over HTTPS, and logged with redaction."

*What separates good from great:* "The distinction between API keys as 'application identity' and JWTs as 'user identity' clarifies when to use each. Knowing specific storage mechanisms (AWS Secrets Manager) vs. the vague 'store securely' shows production experience."

---

#### Q2 - "How does OAuth2 client credentials flow work for service-to-service authentication?"
> "Client credentials flow is OAuth2 for machine-to-machine (no user involved). Flow: Service A (client) sends `POST /token` to the IDP with `grant_type=client_credentials`, `client_id=service-a`, `client_secret=secret123`, `scope=service-b:read`. IDP validates the client credentials and returns an access token: `{access_token: 'eyJ...', expires_in: 3600, scope: 'service-b:read'}`. Service A calls Service B's API with `Authorization: Bearer eyJ...`. Service B validates the token's signature (using IDP's public keys from JWKS endpoint) and checks the `scope` claim. Implementation pattern: client caches the access token until it expires (minus 30 seconds buffer for clock drift). When the cached token is expired or near expiry, fetch a new one. This is the token caching responsibility of the client - don't request a new token on every API call (this hits the IDP's rate limits and adds latency). Spring: Spring Security OAuth2 Client handles this automatically. RestTemplate/WebClient with `oauth2Client()` configuration automatically fetches and caches tokens. The security property: each service has its own client_id/secret. If one service is compromised, only its credentials are revoked - other services are unaffected. Better compartmentalization than a shared API key."

*What separates good from great:* "The token caching requirement (don't request a new token per API call) and the Spring Security automatic token management are implementation details that show you've built service-to-service OAuth2 in practice."

---

#### Q3 - "How do you prevent unauthorized access to other users' data (IDOR vulnerabilities)?"
> "IDOR (Insecure Direct Object Reference): authenticated user accesses another user's resource by guessing or modifying the ID. `GET /users/123/orders` - user 456 changes 123 to 456 in the URL and reads user 456's orders. Authentication doesn't prevent this - the request is authenticated. The fix is authorization at the object level. Pattern: always check that the authenticated user has access to the specific object they're requesting. `Long currentUserId = jwtService.extractUserId(token); if (!order.getUserId().equals(currentUserId)) { throw new AccessDeniedException(); }`. In Spring: `@PreAuthorize("authentication.principal.userId == #userId")` at method level. Use Spring Security's `@PostFilter` and `@PostAuthorize` for declarative authorization. The OWASP API Security Top 10 rates Broken Object Level Authorization (BOLA) as the #1 API vulnerability. Most APIs check function access (is this user an admin?) but miss object access (can this admin access this tenant's data?). For multi-tenant systems: always include tenantId in queries: `WHERE tenantId = ? AND orderId = ?`. Never rely on the `orderId` being unguessable - UUIDs are not a security mechanism."

*What separates good from great:* "Using 'BOLA' (OWASP API Security term) and noting that UUIDs are not a security mechanism (they're hard to guess but not a substitute for authorization checks) shows OWASP API Security Top 10 familiarity."

---

#### Q4 - "You receive a report that your API is being accessed by an unauthorized client. What do you investigate?"
> "Investigation steps: (1) Identify the unauthorized access: check access logs for the suspicious client. Filter by IP, User-Agent, API key, or JWT subject. `grep 'X-API-Key: suspicious-key' /var/log/api-access.log`. (2) Determine scope: which endpoints were accessed? Which user data was accessed? When did it start? How much data was accessed? (3) Credential leak path: if an API key was used: where was the key stored? Git history? CI/CD environment variable logs? A compromised team member's machine? `git log --all -- .env` to check if the key was ever committed. Check the CI/CD logs for the key value. (4) Revoke immediately: delete the API key or block the JWT issuer. If JWT: add the compromised token's jti (JWT ID) to a blacklist until expiry. (5) Rotate: issue new credentials. All services using the compromised key must be updated. (6) Determine if data was exfiltrated: check the response sizes for the suspicious requests. Large responses on data listing endpoints indicate exfiltration. Escalation: if PII was accessed, this is a data breach requiring GDPR/CCPA notification. Involve legal and security teams immediately."

*What separates good from great:* "The GDPR/CCPA breach notification requirement shows you know the legal obligations. The git history check for accidentally committed keys is the most common API key leak vector."

---

#### Q5 - "How do you design authentication for a public API that allows both authenticated and unauthenticated access?"
> "Tiered authentication: unauthenticated requests get limited access (reduced rate limits, public data only). Authenticated requests get full access (user-specific data, higher rate limits, additional endpoints). Implementation: Spring Security with `requestMatchers`: `/public/**` permitted all (no auth required). `/v1/**` authenticated (auth required). For endpoints that work in both modes: inject an Optional authentication object. `@AuthenticationPrincipal(errorOnInvalidType = false) UserPrincipal user`. If user is null: return public view of the resource. If user is authenticated: return personalized view. Rate limiting by tier: unauthenticated: 10 req/min per IP (fingerprinted). API key authenticated: 100 req/min. OAuth2 bearer: 1000 req/min per user. The public tier is still identified (by IP) for rate limiting and abuse prevention. Completely anonymous APIs without any IP-based rate limiting are vulnerable to DoS and scraping. For the public tier: use Cloudflare's Bot Management or similar to fingerprint and rate limit anonymous traffic without requiring registration."

*What separates good from great:* "The tiered rate limiting (unauthenticated = 10/min per IP, API key = 100/min, OAuth2 = 1000/min) and the mention of Cloudflare Bot Management for anonymous traffic show production API security architecture experience."

---

#### Q6 - "What is the difference between authentication and authorization in REST APIs?"
> "Authentication: who are you? Verifying identity. JWT validation proves the token was issued by a trusted IDP and hasn't expired. The caller is who they claim to be. Authorization: what can you do? Verifying permissions. After authentication establishes identity, authorization checks if this identity is allowed to perform this action on this resource. REST authorization has three layers: function-level (can this user call this endpoint? - role-based: ADMIN role required for DELETE /users), object-level (can this user access this specific record? - ownership: user 123 can only access their own orders), and field-level (can this user see this field? - sensitivity: only FINANCE role can see salary field). A common mistake: only implementing function-level authorization and missing object-level. The API requires authentication + ADMIN role to call GET /users - but doesn't check that Admin A can only see their own tenant's users, not all tenants' users. Spring Security covers function-level well (`@PreAuthorize("hasRole('ADMIN')")`) but object-level requires custom checks in each service method. Spring Security `@PostAuthorize` can do object-level for returns, but the query itself must filter correctly to avoid loading unauthorized data (then failing the PostAuthorize check after the data was fetched)."

*What separates good from great:* "The three-layer authorization model (function + object + field) and the Spring Security gap for object-level authorization (PostAuthorize loads data then discards it vs. correct filtering at query level) shows deep authorization implementation experience."

---

#### Q7 - "Describe how you'd secure a REST API that handles financial data."
> "Defense-in-depth for financial APIs: (1) Authentication: OAuth2 with a regulated IDP. Short-lived access tokens (15 min), non-expiring refresh tokens stored server-side (not in cookies or localStorage). mTLS for service-to-service. (2) Authorization: object-level authorization on every endpoint (account owners only). Principle of least privilege: tokens carry minimum scopes. `scope: accounts:read` only for read operations. (3) Input validation: reject any unexpected fields (no mass assignment). Validate all numeric inputs for range (no negative balances). Use `BigDecimal` not `double` for financial amounts. (4) Audit logging: log every request with authenticated user, action, resource accessed, IP, timestamp. Immutable audit log (append-only, write once, read many). Financial regulations require 7 years of audit trail. (5) Encryption: TLS 1.2+ for transport. Database encryption at rest. Sensitive fields (account numbers, SSN) encrypted at column level. (6) Rate limiting: aggressive limits on login attempts (lockout after 5 failures). Rate limiting on read endpoints to prevent scraping. (7) PCI-DSS compliance: if handling card data, PCI-DSS requirements apply. Card numbers must be tokenized (never store full PAN). Use a payment gateway (Stripe, Adyen) that handles PCI scope instead of handling card data yourself."

*What separates good from great:* "BigDecimal vs double for financial amounts (floating point precision errors can cause incorrect balance calculations), column-level encryption for sensitive fields, and PCI-DSS tokenization show financial domain security knowledge."

---

---

# CORS and Cross-Origin Requests

---

### 🎯 Model Answer

**30 seconds:**
> CORS (Cross-Origin Resource Sharing) is a browser security mechanism that restricts web pages from making HTTP requests to a different origin (domain/port/protocol) than the page itself. Browsers block cross-origin requests by default. The server allows specific origins by returning CORS headers. REST APIs need CORS configured to allow browser-based clients from different domains to call them.

**3 minutes:**
> CORS exists to prevent malicious websites from using a user's credentials to call other APIs (same-origin policy). Without CORS: a malicious site `evil.com` could make your authenticated browser call `yourbank.com/api/transfer?to=attacker&amount=1000`. The browser would send your bank's session cookie, and the transfer would succeed. CORS prevents this: the bank's server only allows requests from its own web app origin (app.yourbank.com), not from evil.com. When a browser makes a cross-origin request: for "simple" requests (GET, POST with application/x-www-form-urlencoded): the browser makes the request and checks CORS headers on the response. For "non-simple" requests (PUT, DELETE, or POST with Content-Type: application/json): the browser first sends a preflight OPTIONS request to check if the actual request is allowed. The server must respond to the OPTIONS request with CORS headers including Access-Control-Allow-Origin, Access-Control-Allow-Methods, and Access-Control-Allow-Headers. The key headers: `Access-Control-Allow-Origin: https://app.yourbank.com` - which origins are allowed. `Access-Control-Allow-Methods: GET, POST, PUT, DELETE` - which methods are allowed. `Access-Control-Allow-Headers: Authorization, Content-Type` - which headers are allowed. `Access-Control-Allow-Credentials: true` - whether cookies and Authorization headers are sent (requires a specific origin, not *). `Access-Control-Max-Age: 3600` - how long the browser can cache the preflight result.

**Blank Mind Recovery:**
**(1) Restate:** "CORS - browser security mechanism for cross-domain API access."
**(2) First principles:** "Why does it exist? Prevent evil.com from using your credentials to call yourbank.com."
**(3) Bridge:** "Like airport security: different terminals (origins). The airline (server) says which passengers (origins) can board which flights (API calls)."

---

### 📘 Concept Explanation

**What it is:**
CORS is an HTTP header-based mechanism that allows or restricts web browser requests to a server from an origin (domain, protocol, port) different from the server's own origin.

**The problem it solves:**
The browser's same-origin policy blocks all cross-origin requests by default. REST APIs must be accessible from web apps hosted on different origins. CORS is the standard mechanism to safely allow this while preventing unauthorized cross-origin access.

**How it works:**
```
CORS preflight for cross-origin JSON POST:

Browser (origin: app.mysite.com)
  -> API (api.mysite.com)

STEP 1: Browser sends OPTIONS preflight
OPTIONS /api/users HTTP/1.1
Host: api.mysite.com
Origin: https://app.mysite.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type,Authorization

STEP 2: Server responds to preflight
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://app.mysite.com
Access-Control-Allow-Methods: GET,POST,PUT,DELETE
Access-Control-Allow-Headers: Content-Type,Authorization
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 3600

STEP 3: Browser sends actual POST
POST /api/users HTTP/1.1
Host: api.mysite.com
Origin: https://app.mysite.com
Authorization: Bearer eyJ...
Content-Type: application/json
...

STEP 4: Server returns CORS headers on response
HTTP/1.1 201 Created
Access-Control-Allow-Origin: https://app.mysite.com
...
```

**The key insight:**
CORS is a browser security mechanism. Non-browser clients (curl, Postman, server-to-server calls) are not affected by CORS - they don't send OPTIONS preflights and don't check CORS headers. If you can't call an API from a browser but can from curl, CORS is the likely cause. CORS configuration is server-side: the server decides which origins, methods, and headers are allowed.

**When to use it:**
Any REST API called by browser-based clients from a different origin needs CORS configured. This includes SPAs calling a separate API server, and public APIs called from third-party web apps.

**When NOT to use it:**
APIs only called by non-browser clients (mobile apps, servers, scripts) don't need CORS. APIs and frontends on the same origin (same domain, port, protocol) don't need CORS.

**Alternatives:**
- JSONP: legacy cross-origin technique using `<script>` tags. Security issues, GET only, deprecated.
- Reverse proxy: route `/api/` to the API server, `/*` to the frontend. Same origin from the browser's perspective. CORS not needed.

**First-principles derivation:**
Web security is built on the same-origin policy: JavaScript on `evil.com` cannot read responses from `yourbank.com`. Cross-origin requests still happen (the browser sends them) but the JavaScript cannot read the response. CORS extends this by allowing the server to explicitly grant specific origins the ability to read responses. It's a grant of trust, not a lock-down - the default is locked down.

---

### 💻 Code Example

```java
// BAD: Allow all origins with credentials
@Configuration
public class CorsConfigBad {
  @Bean
  public CorsFilter corsFilter() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("*"));
    // BROKEN: allowCredentials=true with * is invalid
    // Browser will REJECT this combination
    config.setAllowCredentials(true);
    config.addAllowedHeader("*");
    config.addAllowedMethod("*");
    UrlBasedCorsConfigurationSource source =
        new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return new CorsFilter(source);
  }
}

// GOOD: Specific origins with environment config
@Configuration
public class CorsConfig {

  @Value("${cors.allowed-origins}")
  private List<String> allowedOrigins;

  @Bean
  public CorsFilter corsFilter() {
    CorsConfiguration config = new CorsConfiguration();
    // Specific origins only (from config, not hardcoded)
    config.setAllowedOrigins(allowedOrigins);
    // Allow credentials (cookies, Authorization header)
    config.setAllowCredentials(true);
    // Only allow needed headers
    config.setAllowedHeaders(List.of(
        "Authorization",
        "Content-Type",
        "X-Request-Id"));
    // Only allow needed methods
    config.setAllowedMethods(List.of(
        "GET", "POST", "PUT", "DELETE", "OPTIONS"));
    // Cache preflight for 1 hour
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source =
        new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return new CorsFilter(source);
  }
}

// application.properties (per environment)
// cors.allowed-origins=https://app.mysite.com
// (staging): cors.allowed-origins=https://staging.mysite.com
// (local): cors.allowed-origins=http://localhost:3000
```

> **Code walkthrough:** The BAD example uses `*` (allow all origins) with `allowCredentials(true)`. This combination is explicitly rejected by browsers - the spec forbids wildcard origin with credentials. The GOOD example uses specific origins from config (environment-specific), restricts allowed headers to only what's needed (principle of least privilege), and sets MaxAge to cache the preflight result for 1 hour (reduces OPTIONS request overhead).

---

### 🎓 Answers by Seniority

**Junior / Mid:** "CORS is a browser security feature that blocks web apps from calling APIs on different domains. My API needs to return CORS headers to allow my frontend to call it. I configure CORS in Spring with a CorsFilter or `@CrossOrigin` annotation. The key headers are Access-Control-Allow-Origin (which domain can access), Access-Control-Allow-Methods (which HTTP methods), and Access-Control-Allow-Headers. For local development I allow localhost:3000, for production I allow the actual frontend domain."

**Senior / Staff:** "CORS is often configured incorrectly in production. The common mistake: `allowedOrigins('*')` with `allowCredentials(true)` - browsers reject this combination. To allow credentials (JWT in Authorization header) you must specify exact origins, not wildcard. The subtle CORS issue: dynamic origin validation where the server echoes the request's Origin back if it's in an allowlist. This is correct but requires careful `Vary: Origin` header on responses. Without `Vary: Origin`, a proxy or CDN may cache a response with `Access-Control-Allow-Origin: app.mysite.com` and serve it to a request from `evil.com`, incorrectly telling that browser the response is allowed. Add `Vary: Origin` when using dynamic origin matching. Another production issue: CORS preflight not going through to the API - the load balancer or API gateway handles OPTIONS requests and returns an empty response without CORS headers. Clients get blocked. Fix: configure the gateway to pass OPTIONS requests through or handle CORS at the gateway level."

---

### ⚠️ Common Misconceptions

**Misconception:** "Adding Access-Control-Allow-Origin: * makes my API insecure because anyone can call it."
Reality: `Access-Control-Allow-Origin: *` only affects browser clients. Any non-browser client (curl, Python requests, Java HttpClient, server-to-server) is completely unaffected by CORS - they don't follow the same-origin policy. If your API is public (intended to be callable from any web app, like a public weather or geocoding API), then `*` is appropriate and doesn't create a security vulnerability. Security for the API itself comes from authentication (API keys, JWT), rate limiting, and authorization - not from CORS. CORS is a browser protection mechanism to prevent one website from exploiting a user's credentials on another website. It's not API access control. A private API (requiring authentication) with `*` CORS is fine if authentication requires a non-cookie credential (like a Bearer token, which is not automatically sent cross-origin). A private API with `*` CORS and cookie-based authentication IS a problem - cookies are sent with `credentials: include`, and a CSRF attack could make authenticated requests.

---

### 🚨 Failure Modes and Diagnosis

**Failure: CORS error in browser but API works fine in Postman**

Symptoms: Browser console shows `Access to XMLHttpRequest at 'https://api.mysite.com/users' from origin 'https://app.mysite.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.` The same request works perfectly in Postman and curl.

Root cause: The server is not returning CORS headers for requests from this origin. Either: CORS is not configured, the request's Origin is not in the allowed list, or the preflight OPTIONS request is being blocked before reaching the application (by a security filter or load balancer).

Diagnosis: Open browser DevTools, Network tab. Find the failing request. Check if there's a preceding OPTIONS request. If no OPTIONS: the request is a "simple" request and CORS is on the actual response. Check the response headers for `Access-Control-Allow-Origin`. If there is an OPTIONS: check the OPTIONS response - it must return 200 or 204 with CORS headers. `curl -X OPTIONS https://api.mysite.com/users -H "Origin: https://app.mysite.com" -v` - check the response headers.

Fix: Add CORS configuration to the server. Ensure the app.mysite.com origin is in the allowed list. If using Spring Security: ensure the CORS filter is registered BEFORE the security filter chain (CorsFilter must run before authentication filters or the OPTIONS preflight will be rejected as unauthenticated).

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Mechanism | 3 min | 1 |
| Comparison | 2 min | 1 |
| Security | 3 min | 2 |
| Debugging | 3 min | 2 |
| Design | 2 min | 1 |
| Behavioral | 2 min | 1 |

#### Q1 - "Explain what happens during a CORS preflight request."
> "A preflight is an automatic OPTIONS request that the browser sends before a 'non-simple' cross-origin request. It asks: 'Is the actual request I want to send allowed from my origin?' Non-simple requests trigger preflights: any method other than GET, HEAD, POST. POST with Content-Type other than application/x-www-form-urlencoded, multipart/form-data, or text/plain. Custom request headers (like Authorization). The preflight: `OPTIONS /api/users` with `Origin: https://app.mysite.com`, `Access-Control-Request-Method: POST`, `Access-Control-Request-Headers: Authorization, Content-Type`. The server must respond with: `Access-Control-Allow-Origin: https://app.mysite.com`, `Access-Control-Allow-Methods: GET, POST, PUT, DELETE`, `Access-Control-Allow-Headers: Authorization, Content-Type`, `Access-Control-Max-Age: 3600`. If the preflight returns anything other than 200 or 204, the browser aborts the actual request. If CORS headers are missing, browser blocks the actual request. MaxAge: the browser caches the preflight result for MaxAge seconds. Default is 5 seconds if not specified. Setting to 3600 (1 hour) reduces OPTIONS request overhead - important for high-traffic APIs where preflights add latency."

*What separates good from great:* "Knowing what makes a request 'non-simple' (the Authorization header or application/json Content-Type trigger preflights) is the detail that explains why API requests always trigger preflights while simple GET requests from forms do not."

---

#### Q2 - "How do you handle CORS in a microservices environment?"
> "In a microservices architecture with an API gateway, CORS should be configured at the gateway, not in each individual service. Reasons: centralized CORS policy (consistent across all services), single place to update when frontend origins change, services don't need CORS knowledge. Configuration: API gateway (Kong, AWS API Gateway, Nginx, Traefik) handles OPTIONS preflights and adds CORS headers before forwarding to services. Services receive and respond to the actual request; CORS headers are added by the gateway on the way back. If services are sometimes called directly (internal dashboards, debugging): they may need CORS too. Use a shared Spring Boot autoconfiguration that all services import. The risk: if services are accessible directly (not only through the gateway), CORS in only the gateway creates a gap. Defense-in-depth: configure CORS at the gateway AND at the service level. The service-level config should be more restrictive (only allow the gateway's internal IP range, or no CORS at all for truly internal services). Gateway handles external CORS. Service-level CORS is a fallback."

*What separates good from great:* "The recommendation to configure CORS at the gateway AND the service level as defense-in-depth (not either/or) and explaining why service-direct access creates a gap shows production microservices architecture experience."

---

#### Q3 - "What CORS configuration is needed for a JWT-based SPA and API?"
> "SPA on https://app.mysite.com calling API on https://api.mysite.com. The SPA uses JWT in the Authorization header. Configuration: `Access-Control-Allow-Origin: https://app.mysite.com` (exact match, not *). `Access-Control-Allow-Credentials: false` (surprisingly). Note: credentials in CORS context means cookies and HTTP authentication (basic auth). JWT in the Authorization header is NOT a credential in the CORS sense - it's an explicit header that the JavaScript sets. You only need `Allow-Credentials: true` if using cookies for authentication. For JWT-Bearer: set `Allow-Credentials: false`, include `Authorization` in `Allow-Headers`. `Access-Control-Allow-Headers: Authorization, Content-Type, X-Request-Id`. `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`. `Access-Control-Max-Age: 3600`. Why specific origin (not *)? The * wildcard has no security value for this case (JWT in header is already per-request authentication), but specific origin shows intentional access policy. For local development: add `http://localhost:3000` to the allowed origins list. Use environment-specific configuration. Never deploy with localhost in the production CORS config."

*What separates good from great:* "The clarification that `Allow-Credentials: false` is correct for JWT-in-header (because CORS credentials = cookies, not JWT) is the nuanced point. Most candidates set `Allow-Credentials: true` unnecessarily for JWT APIs."

---

#### Q4 - "You're getting CORS errors only in production, not in staging. What do you investigate?"
> "Prod-only CORS failures common causes: (1) Different frontend URL: staging frontend is `staging.mysite.com` (allowed). Production frontend is `app.mysite.com` (not in the allowed list). Check the exact origin of the production request vs. the allowed origins list. (2) HTTPS vs HTTP: staging may be HTTP. Production is HTTPS. The origin must include the scheme: `http://staging.mysite.com` != `https://app.mysite.com`. Ensure the production origin includes `https://`. (3) CDN stripping CORS headers: a CDN in front of production is caching the API responses. If the first request was from a same-origin client (no CORS headers needed), that response without CORS headers was cached. Now cross-origin requests receive the cached no-CORS response. Fix: add `Vary: Origin` to API responses so the CDN caches separately per Origin. Or bypass the CDN for API routes. (4) Load balancer handling OPTIONS: a load balancer in production (not in staging) responds to OPTIONS requests with a 200 OK but no CORS headers. The actual application never sees the OPTIONS request. Diagnosis: `curl -X OPTIONS https://api.mysite.com/users -H 'Origin: https://app.mysite.com' -v` - check the response headers. Does it include CORS headers?"

*What separates good from great:* "The CDN caching CORS responses without Vary: Origin is the production-specific failure that staging (without CDN) will never reproduce. This is the answer that shows production CDN experience."

---

#### Q5 - "How does CORS relate to CSRF attacks?"
> "CORS and CSRF protection are complementary browser security mechanisms. Same-origin policy: protects against cross-origin response reading (CORS extends this to allow selected origins). CSRF: protects against cross-origin requests being sent in the first place (using the user's credentials). The confusion: CORS allows cross-origin requests. Doesn't this enable CSRF? No, because: CSRF uses credentials that the browser sends automatically (cookies, HTTP auth). CORS with `Allow-Credentials: false` allows cross-origin requests but without cookies. The attacker can make the request but without the victim's cookies, so it's not authenticated. CSRF protection is still needed for cookie-based authentication APIs even with restrictive CORS: a malicious site from an allowed CORS origin (a subdomain XSS) could make credentialed cross-origin requests. The defense: CSRF tokens for state-changing requests when using cookie auth. CORS properly configured is defense-in-depth for CSRF. For JWT Bearer APIs (not using cookies): CSRF is not applicable. The attacker cannot make the browser send the JWT in the Authorization header - JavaScript must explicitly set it. `Access-Control-Allow-Credentials: false` means the browser won't send cookies, so there's no automatic credential to abuse."

*What separates good from great:* "The point that CSRF tokens are not needed for JWT-Bearer APIs (because the browser doesn't automatically send JWTs - they must be explicitly set by JavaScript) clarifies the relationship between CORS, CSRF tokens, and cookie vs. header authentication."

---

#### Q6 - "What is the security risk of misconfigured CORS?"
> "The primary CORS misconfiguration risks: (1) Origin reflection without validation: server echoes back any Origin value in `Access-Control-Allow-Origin: {request.origin}` without checking against an allowlist. Any origin can make authenticated requests. Attacker creates evil.com, calls your API, gets the authenticated user's data. (2) Wildcard origin with sensitive data: `Access-Control-Allow-Origin: *` is acceptable for public read-only APIs but dangerous if the API returns per-user data. The attacker's page can read the response and extract user data. `*` should only be used for truly public, non-authenticated APIs. (3) Trusted subdomain too broadly: `allowedOrigins = '*.mysite.com'`. If attacker achieves XSS on any subdomain (old.mysite.com, static.mysite.com), they can make credentialed cross-origin requests from that subdomain. Allowlist specific subdomains. (4) Localhost allowed in production: `http://localhost:3000` in production CORS config means any attacker running a local server can access your production API. This shouldn't need explanation but it happens. Testing: check your API's Access-Control-Allow-Origin response header. If it reflects back arbitrary Origins or accepts localhost, it's misconfigured."

*What separates good from great:* "The origin reflection attack (echo-back without validation) is a specific vulnerability class. Knowing that `*.mysite.com` wildcard subdomain matching is risky due to XSS on any subdomain shows you've thought through the complete attack surface."

---

#### Q7 - "How do you test CORS configuration in an API?"
> "Testing CORS: both automated tests and manual verification. Automated tests with MockMvc (Spring): `mockMvc.perform(options('/api/users').header('Origin', 'https://app.mysite.com').header('Access-Control-Request-Method', 'POST').header('Access-Control-Request-Headers', 'Authorization,Content-Type')).andExpect(status().isOk()).andExpect(header().string('Access-Control-Allow-Origin', 'https://app.mysite.com')).andExpect(header().string('Access-Control-Allow-Methods', containsString('POST')))`. Test negative cases: request from disallowed origin should NOT return CORS headers. Manual testing: browser DevTools Network tab - look for OPTIONS requests and check their response headers. curl: `curl -X OPTIONS https://api.mysite.com/users -H 'Origin: https://evil.com' -v` - should NOT return CORS headers. `curl -X OPTIONS https://api.mysite.com/users -H 'Origin: https://app.mysite.com' -v` - SHOULD return CORS headers. Security testing: try origin reflection (`curl -H 'Origin: https://evil.com'`) - should be rejected. Try `null` origin (some browser iframe scenarios) - should be rejected. Try subdomain variant (`evil.mysite.com`) - should be rejected unless explicitly in the allowlist."

*What separates good from great:* "Testing the negative cases (evil.com, null origin, evil.mysite.com) with specific curl commands shows a security-testing mindset. Most candidates only test the happy path."

---

### ⚖️ Comparison Table

| Approach | Browser Only | Credentials Support | Wildcard Origin | Preflight Required |
|---|---|---|---|---|
| CORS Allow-Origin: * | Yes | No (credentials=false only) | Yes | No for simple reqs |
| CORS Allow-Origin: specific | Yes | Yes (credentials=true) | No | Yes for non-simple |
| Same-origin (reverse proxy) | Yes | Yes | N/A - same origin | No |
| No CORS config | Yes | No cross-origin access | N/A | N/A |

**The deciding factor:** Use specific origin + credentials for authenticated SPAs. Use wildcard for truly public read-only APIs. Use reverse proxy to eliminate CORS entirely when feasible.
