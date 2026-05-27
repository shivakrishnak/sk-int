---
layout: default
title: "REST API - L2 Security and Performance"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 4
permalink: /rest-api/l2-security-performance/
---

# Rate Limiting and Throttling

🎯 Interview Weight: high - Rate limiting protects APIs from
abuse and ensures fair use. Tested in system design and senior
backend interviews.

---

### 🎯 Model Answer

**30 seconds:**
> Rate limiting controls how many requests a client can make in a
> time window. Common algorithms: fixed window (simple, burst
> vulnerable), sliding window (smooth), token bucket (allows bursts
> up to a limit), leaky bucket (constant output rate). Return 429
> Too Many Requests with `Retry-After` header when the limit is
> exceeded.

**3 minutes (Senior):**
> Rate limiting serves three purposes: (1) Protect the service from
> overload (DoS/DDoS), (2) Ensure fair usage among clients, (3) Enforce
> business tier limits (free tier = 100 req/day, paid = 10,000).
>
> Algorithms compared:
>
> Fixed window: count requests in a fixed interval (e.g., per minute).
> Simple. Vulnerability: a burst of requests at the end of one window
> and the start of the next can double the effective rate (2x the
> limit in a 1-second span around the window boundary).
>
> Sliding window log: store the timestamp of each request; count
> how many are within the window. Accurate, no burst vulnerability.
> Memory-intensive (stores all timestamps).
>
> Sliding window counter: hybrid of fixed window with proportional
> counting from the previous window. Approximate but memory-efficient.
>
> Token bucket: each client has a bucket with capacity N tokens.
> Requests consume tokens; tokens refill at rate R per second.
> Allows bursts up to N. Most common for API rate limiting.
> Used by Stripe, GitHub.
>
> Leaky bucket: requests queue; processed at constant rate. No
> bursts. Good for downstream protection (constant rate to a backend).
>
> Implementation: rate limit at the API gateway (single enforcement
> point). State in Redis (atomic INCR, EXPIRE). Headers:
> `X-RateLimit-Limit: 100`, `X-RateLimit-Remaining: 42`,
> `X-RateLimit-Reset: 1705123456` (epoch time when limit resets),
> `Retry-After: 30` (seconds until retry).
>
> Distribute limits by: IP (anonymous), API key (authenticated user),
> user ID (per-account), or endpoint (some endpoints are more
> expensive than others).

**Blank Mind Recovery:**

**(1) Restate:** "How to limit how many requests a client can make
to prevent overload and ensure fair use."

**(2) First principles:** "Resources are finite. A server can handle
N requests per second. A single client should not be able to consume
all N. Rate limiting shares capacity fairly."

**(3) Bridge:** "Like a highway on-ramp metering light: one car
per green light. No matter how fast you drive up, the entrance rate
is controlled."

---

### 📘 Concept Explanation

**Token bucket algorithm:**

```
Bucket capacity: 100 tokens
Refill rate: 10 tokens/second

Request arrives:
  Has token? -> consume 1, allow request
  Empty?     -> reject with 429

State:
  tokens = min(capacity, tokens + (elapsed * rate))
```

**Redis implementation (atomic):**

```
LUA SCRIPT (atomic):
  current = GET rate:key
  if current > limit: return DENIED
  else:
    INCR rate:key
    EXPIRE rate:key 60
    return ALLOWED
```

---

### 💻 Code Example

**GOOD - Token bucket with Redis + Spring:**

```java
// Token bucket rate limiter with Redis
@Component
public class TokenBucketRateLimiter {

    private final RedisTemplate<String, Long> redis;

    // Returns: allowed=true, remaining tokens, reset time
    public RateLimitResult tryConsume(
        String clientId,
        int capacity,
        Duration refillPeriod
    ) {
        String key = "ratelimit:" + clientId;
        long now = Instant.now().getEpochSecond();
        long windowSeconds = refillPeriod.toSeconds();

        // Atomic Lua script: check and decrement
        Long remaining = redis.execute(
            new DefaultRedisScript<>(RATE_LIMIT_SCRIPT, Long.class),
            List.of(key),
            String.valueOf(capacity),
            String.valueOf(windowSeconds),
            String.valueOf(now)
        );

        if (remaining == null || remaining < 0) {
            // Get reset time from Redis TTL
            Long ttl = redis.getExpire(key, TimeUnit.SECONDS);
            long resetAt = now + (ttl != null ? ttl : windowSeconds);
            return RateLimitResult.denied(0, resetAt);
        }

        return RateLimitResult.allowed(
            remaining.intValue(),
            now + windowSeconds
        );
    }

    // Atomic Lua: check limit, increment, set expiry
    private static final String RATE_LIMIT_SCRIPT = """
        local key = KEYS[1]
        local capacity = tonumber(ARGV[1])
        local window = tonumber(ARGV[2])
        local current = redis.call('GET', key)
        if current and tonumber(current) >= capacity then
            return -1
        end
        local count = redis.call('INCR', key)
        if count == 1 then
            redis.call('EXPIRE', key, window)
        end
        return capacity - count
        """;
}

// Spring interceptor for rate limit headers
@Component
public class RateLimitInterceptor
    implements HandlerInterceptor {

    private final TokenBucketRateLimiter rateLimiter;

    @Override
    public boolean preHandle(
        HttpServletRequest request,
        HttpServletResponse response,
        Object handler
    ) throws Exception {
        String clientId = resolveClientId(request);
        RateLimitResult result =
            rateLimiter.tryConsume(clientId, 100, Duration.ofMinutes(1));

        // Always set rate limit headers
        response.setHeader(
            "X-RateLimit-Limit", "100"
        );
        response.setHeader(
            "X-RateLimit-Remaining",
            String.valueOf(result.remaining())
        );
        response.setHeader(
            "X-RateLimit-Reset",
            String.valueOf(result.resetAt())
        );

        if (!result.allowed()) {
            response.setHeader(
                "Retry-After",
                String.valueOf(
                    result.resetAt() -
                    Instant.now().getEpochSecond()
                )
            );
            response.sendError(
                HttpServletResponse.SC_TOO_MANY_REQUESTS
            );
            return false;
        }
        return true;
    }

    private String resolveClientId(HttpServletRequest req) {
        // Use API key if authenticated, else IP
        String apiKey = req.getHeader("X-API-Key");
        return apiKey != null
            ? "apikey:" + apiKey
            : "ip:" + req.getRemoteAddr();
    }
}
```

> **Code walkthrough:** The Lua script executes atomically in Redis,
> preventing race conditions where two concurrent requests both
> see a count below the limit and both get allowed. The script
> checks the current count, increments, and sets the expiry in
> one atomic operation. The interceptor resolves the client identity:
> authenticated clients are rate-limited by API key (so one
> customer cannot abuse multiple IPs), anonymous clients by IP.
> The `X-RateLimit-Remaining` and `X-RateLimit-Reset` headers are
> always set so clients can implement exponential backoff. The
> `Retry-After` header on 429 responses tells clients exactly
> how long to wait.

---

### ⚖️ Comparison Table

| Algorithm | Burst Handling | Memory | Accuracy | Best For |
|-----------|---------------|--------|----------|---------|
| Fixed Window | Burst at boundary | Low | Approximate | Simple limits |
| Sliding Window Log | No burst | High | Exact | Strict limits |
| Token Bucket | Allows burst up to N | Low | Approximate | API endpoints |
| Leaky Bucket | No burst | Low | Exact | Backend protection |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Rate limiting returns 429 when a client exceeds the request
> limit. Use `Retry-After` header to tell clients when to retry.
> Implement at API gateway level. Store limit counters in Redis
> for distributed enforcement.

---

**Senior / Staff (5+ years):**
> Rate limiting design at scale: limit by API key (not IP) for
> authenticated endpoints - IPs are shared (NAT, corporate proxies)
> so IP limits penalize legitimate users. Use different limits for
> different endpoints - a `GET /products` listing is cheap; a
> `POST /reports` generation is expensive. Implement graduated
> response: 429 with a `Retry-After` for temporary overload,
> but actual API key suspension for persistent abuse patterns.
> Monitor the 429 rate - a spike usually means a client bug
> (retry loop without backoff), not necessarily abuse.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | 429 + Retry-After + what rate limiting is |
| Mid | 4 min | Algorithms + Redis implementation |
| Senior | 6 min | Algorithm selection + distributed enforcement + monitoring |

---

---

# HTTP Caching and ETags

🎯 Interview Weight: high - Caching is fundamental to API
performance. ETags enable conditional requests that reduce bandwidth.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP caching allows intermediate proxies and clients to store
> responses. `Cache-Control` controls caching behavior. `ETag`
> is a version identifier. Conditional requests with
> `If-None-Match: <etag>` let the server return 304 Not Modified
> (with no body) if the resource has not changed, saving bandwidth.

**3 minutes (Senior):**
> HTTP caching layers: browser cache, service worker, CDN/reverse
> proxy (Nginx, Cloudflare), API gateway cache, application-level
> cache (Redis).
>
> Cache-Control directives:
> - `max-age=N`: cache for N seconds
> - `public`: CDN can cache (multiple users share this content)
> - `private`: only browser should cache (user-specific data)
> - `no-cache`: do not serve from cache without revalidating with server
> - `no-store`: never store in any cache (sensitive data)
> - `must-revalidate`: if stale, MUST revalidate before serving
> - `immutable`: content never changes (versioned assets: `v1.2.3.js`)
>
> ETags: the server returns `ETag: "abc123"` (a hash or version ID).
> On next request, client sends `If-None-Match: "abc123"`. Server
> compares: if unchanged, returns 304 (empty body, just headers).
> If changed, returns 200 with new body and new ETag.
>
> Last-Modified / If-Modified-Since: similar but timestamp-based.
> ETags are preferred (more precise, no clock sync issues).
>
> Conditional PUT for optimistic locking: client sends
> `If-Match: "abc123"`. If the server's ETag does not match
> (another client modified the resource), returns 412 Precondition
> Failed. This prevents lost updates in concurrent edit scenarios.
>
> CDN vs application cache: CDN handles static/near-static content
> (product catalog). Application cache (Redis) handles dynamic
> data with complex invalidation rules.

**Blank Mind Recovery:**

**(1) Restate:** "How HTTP caching works and how ETags prevent
re-downloading unchanged content."

**(2) First principles:** "Bandwidth and round trips are expensive.
Caching trades staleness risk for performance gain. ETags make
this trade explicit - the client asks 'is this still fresh?'"

---

### 💻 Code Example

**GOOD - ETags and conditional requests:**

```java
@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    // ETags for conditional GET
    @GetMapping("/{productId}")
    public ResponseEntity<ProductResponse> getProduct(
        @PathVariable String productId,
        @RequestHeader(
            value = "If-None-Match",
            required = false
        ) String ifNoneMatch
    ) {
        Product product = productService.findById(productId);
        String etag = generateEtag(product);

        // Client has current version: 304 No Content
        if (etag.equals(ifNoneMatch)) {
            return ResponseEntity.status(304)
                .eTag(etag)
                .build();
        }

        return ResponseEntity.ok()
            .eTag(etag)
            .cacheControl(
                CacheControl
                    .maxAge(Duration.ofMinutes(5))
                    .cachePublic()
            )
            .body(ProductResponse.from(product));
    }

    // Conditional PUT for optimistic locking
    @PutMapping("/{productId}")
    public ResponseEntity<ProductResponse> updateProduct(
        @PathVariable String productId,
        @RequestBody @Valid UpdateProductRequest request,
        @RequestHeader(
            value = "If-Match",
            required = false
        ) String ifMatch
    ) {
        Product current = productService.findById(productId);
        String currentEtag = generateEtag(current);

        // If-Match required for writes (optimistic lock)
        if (ifMatch == null) {
            return ResponseEntity.status(428)
                .build(); // 428 Precondition Required
        }

        // Concurrent modification detected
        if (!currentEtag.equals(ifMatch)) {
            return ResponseEntity.status(412)
                .build(); // 412 Precondition Failed
        }

        Product updated = productService.update(
            productId, request
        );
        return ResponseEntity.ok()
            .eTag(generateEtag(updated))
            .body(ProductResponse.from(updated));
    }

    // Stable ETag from version field (incremented on every write)
    private String generateEtag(Product product) {
        return '"' + product.getVersion().toString() + '"';
    }
}
```

> **Code walkthrough:** The `getProduct` endpoint checks `If-None-Match`
> and returns 304 if the ETag matches (no body, saves bandwidth).
> The ETag is generated from the product's `version` field (a database
> optimistic lock counter) - this is stable and cheap (no content
> hashing required). The `updateProduct` endpoint requires `If-Match`
> (returns 428 Precondition Required if absent) and returns 412
> Precondition Failed if another client modified the product since
> the client last fetched it. This implements HTTP-native optimistic
> locking - two clients editing the same product: the second one
> to PUT gets 412 and must re-fetch before retrying.

---

### ⚖️ Comparison Table

| Cache-Control | Use Case | CDN Caches? |
|---------------|----------|------------|
| `max-age=0, must-revalidate` | Real-time, accuracy needed | No |
| `max-age=60, public` | Near-real-time (product prices) | Yes |
| `max-age=3600, public` | Stable public data (catalog) | Yes |
| `max-age=86400, immutable` | Static assets (CDN) | Yes |
| `private, no-cache` | Per-user data (account) | No |
| `no-store` | Sensitive (payment data) | No |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `Cache-Control` header controls how long responses are cached.
> `ETag` is a resource version identifier. The client sends
> `If-None-Match: <etag>` on subsequent requests; the server returns
> 304 Not Modified if unchanged.

---

**Senior / Staff (5+ years):**
> In one project, adding `Cache-Control: max-age=300, public` to
> the product catalog API reduced origin server requests by 85%.
> The CDN served 85% of catalog requests from cache. This is
> operational amplification: the API team's 1-hour work reduced
> infrastructure costs and latency for millions of users. The key
> design decision: separate endpoints for user-specific data (private,
> no-cache) and public catalog data (public, max-age=300). Mixing
> them on the same endpoint prevents effective CDN caching.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Cache-Control + ETag basics |
| Mid | 4 min | 304 Not Modified + conditional PUT |
| Senior | 6 min | CDN strategy + cache invalidation |

---

---

# CORS Configuration

🎯 Interview Weight: medium - CORS errors are common for API
developers. Interviewers test understanding of why CORS exists
and how to configure it correctly.

---

### 🎯 Model Answer

**30 seconds:**
> CORS (Cross-Origin Resource Sharing) is a browser security mechanism
> that restricts JavaScript in one origin from making requests to a
> different origin. The browser sends an `Origin` header; the server
> responds with `Access-Control-Allow-Origin`. A preflight
> OPTIONS request is sent before non-simple requests to check
> permissions.

**3 minutes (Senior):**
> Same-origin policy: browsers only allow JavaScript to make requests
> to the same origin (protocol + domain + port). `https://app.example.com`
> cannot call `https://api.example.com` without CORS headers.
>
> CORS is enforced by the browser, not the server. A non-browser
> client (curl, Postman, server-to-server) ignores CORS entirely.
>
> Simple requests (no preflight): GET/HEAD/POST with standard headers
> and `application/x-www-form-urlencoded`, `multipart/form-data`,
> or `text/plain` content type.
>
> Non-simple requests (preflight required): PUT, PATCH, DELETE,
> or POST with `application/json`, or any custom header.
> The browser automatically sends `OPTIONS` preflight with
> `Access-Control-Request-Method` and `Access-Control-Request-Headers`.
> The server must respond with `Access-Control-Allow-Methods`,
> `Access-Control-Allow-Headers`, `Access-Control-Allow-Origin`,
> and `Access-Control-Max-Age` (preflight cache duration).
>
> Credentials (cookies, Authorization header): require
> `Access-Control-Allow-Credentials: true` AND `Access-Control-Allow-Origin`
> cannot be `*` (must be explicit origin). This is the most common
> CORS misconfiguration.
>
> Security risk: `Access-Control-Allow-Origin: *` is safe for public
> APIs (no credentials). For authenticated APIs with cookies,
> wildcard is dangerous (allows any site to make authenticated
> requests as the user). Always validate the `Origin` header against
> an allowlist.

**Blank Mind Recovery:**

**(1) Restate:** "CORS controls which websites can make API calls
from their JavaScript code."

**(2) First principles:** "Browsers enforce same-origin policy to
prevent CSRF. CORS is the controlled exception that lets known,
trusted domains make cross-origin calls."

---

### 💻 Code Example

**BAD - Wildcard CORS with credentials:**

```java
// BAD: Wildcard origin with credentials is rejected by browsers
// AND is a security vulnerability
@CrossOrigin(origins = "*",
    allowCredentials = "true") // browsers reject this combination
@GetMapping("/api/account")
public AccountResponse getAccount() { ... }
```

**GOOD - Secure CORS configuration:**

```java
// GOOD: Explicit origin allowlist, validated at startup
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    // Loaded from application properties
    @Value("${api.cors.allowed-origins}")
    private List<String> allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
            .allowedOrigins(allowedOrigins.toArray(new String[0]))
            // Allowlist: validate this list in tests
            // ["https://app.example.com",
            //  "https://admin.example.com"]
            .allowedMethods(
                "GET", "POST", "PUT", "PATCH", "DELETE",
                "OPTIONS"
            )
            .allowedHeaders(
                "Authorization",
                "Content-Type",
                "X-Request-ID"
            )
            .allowCredentials(true) // OK: explicit origins only
            .maxAge(3600); // Preflight cache: 1 hour
    }
}

// For APIs that support multiple environments,
// validate Origins against a database/config store
@Component
public class DynamicCorsFilter extends OncePerRequestFilter {

    private final ApiKeyRepository apiKeyRepo;

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain chain
    ) throws ServletException, IOException {
        String origin = request.getHeader("Origin");
        String apiKey = request.getHeader("X-API-Key");

        if (origin != null && apiKey != null) {
            // Validate origin for this API key from database
            boolean allowed = apiKeyRepo
                .isOriginAllowed(apiKey, origin);

            if (allowed) {
                response.setHeader(
                    "Access-Control-Allow-Origin", origin
                );
                response.setHeader(
                    "Vary", "Origin" // Important for caching
                );
                response.setHeader(
                    "Access-Control-Allow-Credentials", "true"
                );
            }
        }
        chain.doFilter(request, response);
    }
}
```

> **Code walkthrough:** The BAD example uses `*` with credentials -
> browsers actively reject this combination (CORS spec forbids it).
> It is also a security vulnerability: any website could make
> authenticated requests as the user. The static GOOD example uses
> an explicit origin list from application properties. The `Vary:
> Origin` header is critical: without it, a CDN may serve the
> CORS-approved response to a client from a different origin, breaking
> their CORS check. The dynamic example shows per-API-key CORS
> configuration - useful for B2B APIs where each client has a
> registered set of allowed origins stored in the database.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> CORS is a browser security mechanism that restricts cross-origin
> JavaScript requests. Configure `Access-Control-Allow-Origin` to
> the specific origins your frontend runs on. Never use `*` with
> credentials. Add `OPTIONS` to allowed methods for preflight.

---

**Senior / Staff (5+ years):**
> The most common CORS production bug: developers set `*` in development,
> it works, but production requires `allowCredentials: true` for
> JWT cookie auth, which requires an explicit origin. The fix breaks
> 10 subdomains the team forgot were using the API. The lesson: define
> the origin allowlist in configuration at project start, not as
> an afterthought.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What CORS is + Allow-Origin header |
| Mid | 4 min | Preflight flow + credentials restriction |
| Senior | 5 min | Security implications + dynamic origin config |

---

---

# API Authentication Patterns

🎯 Interview Weight: very high - Authentication is a mandatory
topic for any backend interview. OAuth 2.0 + JWT is the industry
standard.

---

### 🎯 Model Answer

**30 seconds:**
> REST APIs authenticate using API keys (service-to-service),
> JWT Bearer tokens (stateless user auth), OAuth 2.0 (delegated
> authorization), or Basic Auth (deprecated, HTTPS only). JWT is
> the dominant pattern for user-facing APIs: the server issues a
> signed token; the client sends it in every request; the server
> validates the signature without a database lookup.

**3 minutes (Senior):**
> Authentication patterns compared:
>
> API Key (in header `X-API-Key: <key>`): simple, for service-to-service.
> Key must be stored securely (hashed in database, like a password).
> Rate limit by key. No expiry built-in (revocation requires database
> check). Suitable for M2M APIs.
>
> JWT (JSON Web Token): three parts: header.payload.signature.
> Server signs with a private key; client stores the token; server
> validates the signature on every request (no database lookup =
> stateless). Payload contains claims: `sub` (user ID), `exp`
> (expiry), `roles`. Short expiry (15-60 minutes) + refresh tokens
> (24 hours) is the standard pattern.
>
> OAuth 2.0: authorization framework for delegated access.
> Authorization Code Flow (for user-facing web/mobile apps),
> Client Credentials Flow (for M2M). Produces access tokens
> (short-lived JWT or opaque token) and optionally refresh tokens.
>
> Session cookies: server stores session in Redis, sends session
> ID as HttpOnly cookie. Stateful. Requires Redis for distributed
> systems. Vulnerable to CSRF (must use CSRF tokens or SameSite
> cookie attribute).
>
> Security requirements for all patterns: HTTPS only (never HTTP
> for auth), short-lived tokens with refresh, rotate secrets
> regularly, log authentication failures (rate limit auth attempts).

**Blank Mind Recovery:**

**(1) Restate:** "How to authenticate API clients - confirming
who they are."

**(2) First principles:** "The client proves identity with a
credential. The server verifies the credential. The credential
must be secret, expirable, and revocable."

---

### 💻 Code Example

**GOOD - JWT validation in Spring Security:**

```java
// JWT authentication filter
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtValidator jwtValidator;

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain chain
    ) throws ServletException, IOException {
        String authHeader =
            request.getHeader("Authorization");

        if (authHeader == null ||
            !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {
            Claims claims = jwtValidator.validate(token);

            // Set authentication in security context
            UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(
                    claims.getSubject(),  // userId
                    null,
                    extractAuthorities(claims)
                );
            auth.setDetails(
                new WebAuthenticationDetailsSource()
                    .buildDetails(request)
            );
            SecurityContextHolder.getContext()
                .setAuthentication(auth);
        } catch (ExpiredJwtException e) {
            // 401 with specific error code for client handling
            response.setStatus(401);
            response.setContentType("application/json");
            response.getWriter().write("""
                {"error": "TOKEN_EXPIRED",
                 "message": "Access token expired"}
                """);
            return;
        } catch (JwtException e) {
            response.setStatus(401);
            response.setContentType("application/json");
            response.getWriter().write("""
                {"error": "INVALID_TOKEN",
                 "message": "Invalid access token"}
                """);
            return;
        }

        chain.doFilter(request, response);
    }
}

// JWT validator using public key (asymmetric RS256)
@Component
public class JwtValidator {

    private final JWKSet jwkSet;  // JWKS endpoint

    public Claims validate(String token) {
        // Verify signature using RS256 public key
        // (private key is on auth server only)
        return Jwts.parserBuilder()
            .setSigningKeyResolver(jwkSet.resolver())
            .build()
            .parseClaimsJws(token)
            .getBody();
    }
}
```

> **Code walkthrough:** The JWT filter extracts the Bearer token,
> validates the signature and expiry, and sets the Spring Security
> context. Distinguishing `TOKEN_EXPIRED` from `INVALID_TOKEN` in
> the 401 response is important: clients receiving `TOKEN_EXPIRED`
> should use the refresh token to get a new access token automatically.
> `INVALID_TOKEN` means the token is corrupt or from the wrong
> issuer and should trigger re-login. Using RS256 (asymmetric):
> the auth server signs with a private key; resource servers
> validate with the public key from the JWKS endpoint. Resource
> servers never need the private key - minimizing the blast radius
> of a key compromise.

---

### ⚖️ Comparison Table

| Pattern | Stateless | Revocable | Best For | Expiry |
|---------|-----------|-----------|---------|--------|
| API Key | No* | Yes (DB check) | M2M, services | Never (manual) |
| JWT (HS256) | Yes | Hard | Internal services | 15-60 min |
| JWT (RS256) | Yes | Hard | Multi-service | 15-60 min |
| OAuth 2.0 | Depends | Yes | User-facing | Configurable |
| Session Cookie | No | Yes (Redis) | Web apps | Session/TTL |

*API key validation doesn't store state per request, but revocation
requires a DB lookup on every request.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JWT Bearer tokens are the standard for user auth. The client
> sends `Authorization: Bearer <token>` with every request. The
> server validates the signature without a database lookup.
> Tokens expire (typically 15-60 minutes); refresh tokens extend
> the session.

---

**Senior / Staff (5+ years):**
> JWT revocation is the hardest problem in stateless auth. A
> compromised token is valid until expiry. Mitigations: short
> expiry (15 minutes), refresh token rotation (single-use refresh
> tokens prevent replay), and a "token blacklist" in Redis for
> immediate revocation (but this makes auth stateful again).
> The design decision: how quickly must revocation take effect?
> For most apps, 15-minute expiry is acceptable. For payment/healthcare
> apps, a 30-second token check against a Redis blacklist is
> worth the added statefulness.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | JWT structure + Bearer token pattern |
| Mid | 4 min | OAuth 2.0 flows + JWT vs session |
| Senior | 7 min | Revocation + key rotation + RS256 vs HS256 |

---

---

# Input Validation and Sanitization

🎯 Interview Weight: very high (security) - Input validation is
OWASP Top 10 critical. Injection vulnerabilities begin with missing
validation.

---

### 🎯 Model Answer

**30 seconds:**
> Input validation verifies that input conforms to expected format,
> type, and constraints. Sanitization removes or encodes dangerous
> characters. Always validate at the API boundary (controller layer)
> before any processing. Never trust client input. Validation prevents
> injection attacks (SQL, XSS, command injection).

**3 minutes (Senior):**
> Defense layers for input:
>
> Layer 1 - Type and format validation: is the email a valid email?
> Is the integer in range? Is the string within max length?
> Use Bean Validation (`@NotNull`, `@Email`, `@Size`, `@Min`, `@Max`).
> Return 422 Unprocessable Entity with field-level error details.
>
> Layer 2 - Business validation: is this order ID valid for this
> customer? Can this coupon be applied to this cart? Service-layer
> validation.
>
> Layer 3 - Injection prevention: SQL injection (use parameterized
> queries ALWAYS - never string concatenation). NoSQL injection
> (validate input used in MongoDB queries). XSS (encode HTML in
> output if serving HTML). Command injection (never pass user input
> to shell commands). Path traversal (validate file paths, no `../`).
>
> Layer 4 - Size limits: request body size limit (prevent memory
> exhaustion). String length limits (prevent oversized inputs that
> cause slow regex or DB storage issues). Array size limits (prevent
> N+1 loop bombs).
>
> Most critical OWASP risks from missing validation:
> A03 Injection (SQL, XSS, command), A01 Broken Access Control
> (object-level authorization must be validated), A04 Insecure
> Design (missing rate limits + size limits).

**Blank Mind Recovery:**

**(1) Restate:** "How to validate and sanitize API input to prevent
injection attacks and ensure data integrity."

**(2) First principles:** "Never trust client input. Validate format,
type, size, and business constraints at the boundary. Use parameterized
queries to prevent injection."

---

### 💻 Code Example

**BAD - No validation, SQL injection vulnerable:**

```java
// BAD: String concatenation in query = SQL injection
@GetMapping("/api/products")
public List<Product> search(@RequestParam String name) {
    // CRITICAL: SQL injection vulnerability
    String sql = "SELECT * FROM products " +
        "WHERE name LIKE '%" + name + "%'";
    // Input: name=" OR 1=1 --
    // Result: returns ALL products
    return jdbc.query(sql, productRowMapper);
}
```

**GOOD - Bean Validation + parameterized queries:**

```java
// GOOD: Validated input + parameterized queries

@RestController
@RequestMapping("/api/v1/products")
@Validated  // Enables method-level validation
public class ProductController {

    @GetMapping
    public Page<ProductSummary> searchProducts(
        @RequestParam
        @Size(min = 1, max = 100,
            message = "Query must be 1-100 chars")
        @Pattern(regexp = "^[a-zA-Z0-9 _-]+$",
            message = "Invalid characters in search query")
        String q,

        @RequestParam(defaultValue = "0")
        @Min(0) int page,

        @RequestParam(defaultValue = "20")
        @Min(1) @Max(100) int size
    ) {
        return productService.search(q, page, size);
    }
}

// DTO validation for POST body
public record CreateProductRequest(
    @NotBlank(message = "Name is required")
    @Size(max = 200, message = "Name too long (max 200)")
    String name,

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01",
        message = "Price must be positive")
    @Digits(integer = 8, fraction = 2,
        message = "Invalid price format")
    BigDecimal price,

    @NotBlank
    @Size(max = 2000, message = "Description too long")
    // Sanitize HTML to prevent XSS if displayed in browser
    @SafeHtml  // OWASP HTML Sanitizer annotation
    String description
) {}

// Repository using parameterized query (NEVER string concat)
@Repository
public class ProductRepository {

    public Page<Product> search(
        String query, Pageable pageable
    ) {
        // Named parameter: no SQL injection possible
        return entityManager.createQuery("""
            SELECT p FROM Product p
            WHERE LOWER(p.name) LIKE LOWER(:pattern)
            """, Product.class)
            .setParameter("pattern", "%" + query + "%")
            .getResultList();
        // JPA escapes special chars in named parameters
    }
}
```

> **Code walkthrough:** The BAD example concatenates user input
> directly into SQL. Input `" OR 1=1 --` returns all products.
> Input `"; DROP TABLE products; --` could delete the table on
> a vulnerable database setup. The GOOD example uses three defenses:
> (1) `@Pattern` annotation restricts input to safe characters,
> (2) `@Size` enforces length limits, (3) JPA named parameters
> (`LIKE :pattern`) prevent SQL injection regardless of content.
> The `@SafeHtml` annotation sanitizes HTML from the description
> field, preventing stored XSS when product descriptions are
> displayed in a browser. `BigDecimal` for price with `@Digits`
> prevents float precision issues and validates the format.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Always validate input with Bean Validation (`@NotNull`, `@Size`,
> `@Email`, etc.). Return 422 for validation failures with field
> error details. Use parameterized queries - NEVER string concatenation
> in SQL.

---

**Senior / Staff (5+ years):**
> Validation at the API boundary is necessary but not sufficient.
> Object-level authorization is equally critical: after validating
> that `orderId` is a valid UUID, you must also verify that this
> order belongs to the authenticated user (not just that it exists).
> Missing object-level authorization (IDOR - Insecure Direct Object
> Reference) is OWASP A01 and one of the most common API vulnerabilities
> in production. Every `findById` in a controller must be followed
> by an ownership check.

---

### ⚠️ Common Misconceptions

**"Frontend validation is enough":** Frontend validation is for
user experience (immediate feedback). Backend validation is for
security. Any client can bypass frontend validation via curl,
Postman, or browser developer tools. Always validate on the server.

---

### 🚨 Failure Modes and Diagnosis

**Failure: SQL injection via unvalidated input** - User input
is concatenated into a SQL query. Diagnosis: test with input
`' OR 1=1 --` in every search endpoint. If you get unexpected
results or errors, the endpoint is vulnerable. Fix: use
parameterized queries everywhere. Automated fix: enable
a static analysis tool (SpotBugs SQL injection detector,
SonarQube security rules) in the build pipeline.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Bean Validation + 422 response |
| Mid | 4 min | Injection types + parameterized queries |
| Senior | 6 min | IDOR + defense layers + security testing |

---

**[TRADE-OFF] How do you balance strict input validation with
backward compatibility as your API evolves?** `[SENIOR]`

*Why they ask:* Tests understanding of the tension between
security (strict validation) and API evolution (tolerant reader).

*Likely follow-up:* "What do you do when existing clients send
data you no longer accept?"

Two principles in tension: (1) Postel's Law (tolerant reader):
be liberal in what you accept. Ignore unknown fields, accept
multiple date formats. This enables forward compatibility.
(2) Strict validation for security: reject anything unexpected.
Strict schemas prevent injection. Reconciliation: apply strict
validation for security-critical fields (IDs, financial amounts,
email addresses, file paths) and tolerant validation for
content fields (descriptions, metadata). Specifically: unknown
JSON fields in requests should be IGNORED (not rejected) -
this allows clients to send new fields the server does not yet
support without breaking. Content validation (HTML sanitization,
pattern matching) should be strict. Length limits should be
enforced with generosity (a max of 2,000 chars on a description
is security-adequate; 200 chars might reject legitimate content).
For breaking validation changes: version the endpoint or add
the new validation only to new fields.

*What separates good from great:* Postel's Law and the
specific distinction between security-critical fields (strict)
vs content fields (tolerant).

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Security Engineer | OWASP Top 10 + injection prevention |
| Technical Panel | Bean Validation + defense layers |
| Bar Raiser | IDOR + validation as security architecture |
