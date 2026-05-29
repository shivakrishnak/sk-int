---
layout: default
title: "Spring - L4 OAuth2 and JWT Security"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 12
permalink: /spring/l4-oauth2-and-jwt-security/
---

# Spring - L4 OAuth2 and JWT Security

---

# Spring Security OAuth2 and JWT

---
id: SPR-024
title: Spring Security OAuth2 and JWT
category: Spring
difficulty: ★★★
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #spring-security, #oauth2, #jwt, #oidc, #resource-server
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — OAuth2/JWT is the standard auth pattern for
microservices. Senior interviews probe resource server configuration,
token validation, and multi-tenant setups.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Security OAuth2 Resource Server validates incoming JWTs. You configure
> it with spring-boot-starter-oauth2-resource-server. The key configuration:
> spring.security.oauth2.resourceserver.jwt.issuer-uri points to your identity
> provider's discovery endpoint. Spring auto-configures JWT decoder, signature
> verification (JWKS), and populates SecurityContext with claims as authorities.

**3 minutes (Senior):**
> OAuth2 has two distinct roles: Authorization Server (issues tokens) and
> Resource Server (accepts tokens). Spring Security acts as a Resource Server
> in microservices. When a JWT arrives, Spring's BearerTokenAuthenticationFilter
> extracts the Bearer token, passes it to JwtAuthenticationProvider which uses
> NimbusJwtDecoder to decode and validate: signature (via JWKS endpoint), expiry,
> issuer, audience.
>
> The decoded JWT claims are converted to GrantedAuthority list by
> JwtGrantedAuthoritiesConverter. By default, it maps the "scope" claim to
> SCOPE_xxx authorities and ignores other claims. For role-based access (roles
> in custom claims), you configure a custom JwtAuthenticationConverter.
>
> Spring Authorization Server (Spring Security 6+) is the first-party option
> for building an Authorization Server. It supports OIDC discovery endpoint,
> PKCE for SPAs, and client credentials flow. For production, most teams use
> Keycloak or Auth0 as the authorization server and Spring Security as the
> resource server.

**Framework:** WHAT -> WHY -> HOW -> DEPTH -> PRODUCTION

*Adapting up:* Staff - multi-tenant resource servers (different JWKS per tenant),
token exchange (service-to-service with sub claims), opaque tokens vs JWT trade-offs,
Spring Security's OAuth2 client for service-to-service calls.

*Adapting down:* Mid - "OAuth2 is how your API verifies that a request comes
from a legitimately authenticated user. A JWT is a signed token that the user
received from an authorization server, and Spring verifies the signature and
expiry before trusting it."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about using Spring Security to protect APIs
with OAuth2/JWT authentication."

**(2) First principles:** "Microservices can't maintain sessions. Each service
must independently verify the caller's identity from just the request. A JWT
is a self-contained, signed token that carries identity claims - the service
verifies the signature without calling the auth server on every request."

**(3) Bridge:** "A JWT is like a digitally signed letter of introduction from
the embassy (authorization server). The recipient (resource server) can verify
the embassy's signature without calling the embassy - the signature is the proof.
Expiry is the 'valid until' date on the letter."

---

### 📘 Concept Explanation

**What it is:**
Spring Security OAuth2 Resource Server is the Spring Security module for protecting
REST APIs using OAuth2 access tokens (JWT or opaque). It integrates with external
Identity Providers (Keycloak, Auth0, Okta, Azure AD) or Spring Authorization Server.

**The problem it solves:**
Microservices need stateless authentication. Session-based auth doesn't work
across services. JWTs carry claims and are cryptographically signed - any service
with the public key can verify them independently without server-side state.

**How it works:**

```
OAuth2/JWT authentication flow:

Client (browser/mobile/service)
  |
  | 1. Authenticate with Auth Server
  v
Authorization Server (Keycloak/Auth0/Spring Auth Server)
  | 2. Returns access_token (JWT)
  v
Client stores JWT

  | 3. HTTP request + Authorization: Bearer {jwt}
  v
Spring Boot Resource Server
  |
  v
BearerTokenAuthenticationFilter (Phase 11 of filter chain)
  - Extracts "Bearer " token from Authorization header
  - Creates BearerTokenAuthenticationToken (unauthenticated)
  - Passes to AuthenticationManager
  |
  v
JwtAuthenticationProvider
  - Receives BearerTokenAuthenticationToken
  - Delegates to JwtDecoder (NimbusJwtDecoder)
  - Validates:
    1. Signature: fetches JWKS from issuer
       GET {issuer}/.well-known/jwks.json
       Verifies JWT signature with matching JWK
    2. Expiry: exp claim > current time
    3. Not-before: nbf claim
    4. Issuer: iss claim matches configured issuer
    5. Audience: aud claim (if configured)
  - Converts claims to Authentication object
  |
  v
JwtAuthenticationConverter
  - Maps JWT claims to GrantedAuthority list
  - Default: "scope" claim -> SCOPE_xxx
  - Custom: "roles" claim -> ROLE_xxx
  |
  v
SecurityContext populated with JwtAuthenticationToken
  - principal: Jwt object (raw claims accessible)
  - authorities: converted from claims
  |
  v
Controller receives request
  - Access principal: @AuthenticationPrincipal Jwt jwt
  - Access claims: jwt.getClaimAsString("email")
  - Authorization rules: hasAuthority("SCOPE_read")

JWKS caching:
  NimbusJwtDecoder caches JWKS keys (10 min default)
  On unknown kid (key rotation): refetches JWKS
  Automatic key rotation support built-in
```

**The key insight:**
Spring Security's resource server performs all validation locally using cached
JWKS keys. There is NO call to the authorization server per request. This is
JWT's key performance advantage: validation is O(1) per request with just
a cryptographic signature check. The only network call is JWKS refresh (periodic
or on key rotation).

**When to use it:**
- All microservices that accept user requests from clients
- Service-to-service calls where the downstream service must verify the caller's identity
- Multi-tenant SaaS applications (different issuers per tenant)

**When NOT to use it:**
- Long-lived tokens for user sessions (use OIDC session + short JWT)
- When you need to revoke tokens immediately (use opaque tokens + token introspection)
- Internal service-to-service calls in a fully trusted network (mTLS may be simpler)

**Alternatives:**
- Opaque tokens + token introspection: immediate revocation, but per-request
  network call to auth server
- mTLS (Mutual TLS): client certificates instead of bearer tokens

---

### 💻 Code Example

```java
// Resource server configuration
@Configuration
@EnableWebSecurity
public class ResourceServerConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        return http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s
                .sessionCreationPolicy(
                    SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/actuator/health").permitAll()
                .requestMatchers(
                    HttpMethod.GET, "/api/products/**")
                    .hasAuthority("SCOPE_products:read")
                .requestMatchers(
                    "/api/admin/**")
                    .hasRole("ADMIN")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(
                        jwtConverter())))
            .build();
    }

    @Bean
    public JwtAuthenticationConverter jwtConverter() {
        JwtGrantedAuthoritiesConverter authConverter =
            new JwtGrantedAuthoritiesConverter();
        // Map "roles" claim (Keycloak standard) to ROLE_
        authConverter.setAuthoritiesClaimName("roles");
        authConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter jwtConverter =
            new JwtAuthenticationConverter();
        jwtConverter.setJwtGrantedAuthoritiesConverter(
            authConverter);
        return jwtConverter;
    }
}
```

```properties
# application.properties
# JWT issuer URI - Spring auto-discovers JWKS from:
# {issuer-uri}/.well-known/openid-configuration
spring.security.oauth2.resourceserver.jwt
  .issuer-uri=https://auth.example.com/realms/myapp

# Or specify JWKS URI directly (no OIDC discovery)
# spring.security.oauth2.resourceserver.jwt
#   .jwk-set-uri=https://auth.example.com/.well-known/jwks.json
```

> **Code walkthrough:** The oauth2ResourceServer().jwt() configuration enables
> JWT authentication. Spring auto-configures NimbusJwtDecoder using the issuer-uri's
> OIDC discovery endpoint. The jwtConverter overrides the default scope-based
> authority mapping to use Keycloak's "roles" claim instead. hasAuthority("SCOPE_products:read")
> checks exact authority string. hasRole("ADMIN") checks for "ROLE_ADMIN" authority.
> STATELESS session ensures no session is created.

```java
// Custom JWT validation (additional claims)
@Bean
public JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withJwkSetUri(jwksUri)
        .build();

    // Add custom validators in addition to defaults
    OAuth2TokenValidator<Jwt> audienceValidator =
        token -> {
            List<String> audiences = token
                .getAudience();
            if (audiences.contains("order-service")) {
                return OAuth2TokenValidatorResult
                    .success();
            }
            return OAuth2TokenValidatorResult.failure(
                new OAuth2Error("invalid_token",
                    "Wrong audience", null));
        };

    OAuth2TokenValidator<Jwt> validator =
        new DelegatingOAuth2TokenValidator<>(
            JwtValidators.createDefault(),
            audienceValidator);

    decoder.setJwtValidator(validator);
    return decoder;
}

// Accessing JWT claims in controller
@RestController
public class OrderController {

    @GetMapping("/api/orders")
    public List<Order> getOrders(
            // @AuthenticationPrincipal injects the JWT
            @AuthenticationPrincipal Jwt jwt) {

        String userId = jwt.getSubject(); // "sub" claim
        String email = jwt.getClaimAsString("email");
        List<String> roles = jwt
            .getClaimAsStringList("roles");

        log.info("User {} ({}) accessed orders. "
            + "Roles: {}", userId, email, roles);

        return orderService.getOrdersForUser(userId);
    }
}
```

> **Code walkthrough:** Custom JwtDecoder adds audience validation on top of
> Spring's defaults (signature, expiry, issuer). The audience claim "aud" specifies
> which services the token is intended for - validating it prevents token reuse
> across services (if token for service-A is stolen, it should not work for
> service-B). DelegatingOAuth2TokenValidator combines validators with AND logic.
> @AuthenticationPrincipal Jwt injects the decoded JWT directly - no SecurityContextHolder
> boilerplate needed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Security OAuth2 Resource Server makes your API accept JWTs from an
> identity provider like Keycloak or Auth0. You add spring-boot-starter-oauth2-resource-server
> and configure the issuer-uri. Spring auto-configures JWT validation: signature
> check, expiry, issuer. The JWT claims become the user's authorities for
> authorization rules.

*Push deeper:* Where does Spring get the public key to verify the JWT signature?
(JWKS endpoint from the issuer's OIDC discovery)

---

**Senior / Staff (5+ years):**
> Spring Security resource server validates JWTs via NimbusJwtDecoder. The
> JWKS endpoint is discovered from the issuer-uri's OIDC discovery document
> (issuer/.well-known/openid-configuration). Keys are cached and refreshed on
> rotation (unknown kid triggers JWKS re-fetch). Authority extraction is
> configurable: JwtGrantedAuthoritiesConverter maps claims to authorities
> (default: scope claim; override for roles claim in Keycloak).
>
> Production considerations:
> - Audience validation: prevent token reuse across services (aud claim)
> - Clock skew: add 30s tolerance for clock differences between services
> - Token introspection for immediate revocation (vs JWT which is valid until expiry)
> - Multi-tenant: JwtIssuerAuthenticationManagerResolver selects decoder based
>   on iss claim - supports multiple identity providers

*Push deeper:* Service-to-service calls: use spring-security-oauth2-client with
client-credentials grant. The service authenticates with the auth server using
client_id/client_secret and gets a service token. Spring Boot auto-configures
a WebClient with OAuth2ClientHttpRequestInterceptor to automatically add tokens.

---

### ⚠️ Common Misconceptions

**Misconception 1: "JWT is encrypted."**
JWT (JSON Web Token) is digitally SIGNED, not encrypted. The payload is
base64-encoded and readable by anyone. Do not put sensitive data (passwords,
PII beyond what's needed) in JWT claims. JWE (JSON Web Encryption) is the
encrypted variant - much less common.

**Misconception 2: "Revoking a JWT is instant."**
JWT validation is stateless - the issuer does not track issued tokens.
Revocation requires the resource server to check a blocklist (Token Introspection
or custom endpoint). Without introspection, a stolen JWT remains valid until
its exp claim. This is why JWT expiry should be short (15 minutes) with refresh
tokens for session extension.

**Misconception 3: "The Spring resource server calls the auth server on every request."**
Spring caches JWKS keys locally and validates JWTs using the cached public key.
There is no network call per request. The only calls are: initial JWKS fetch,
periodic refresh (every 10 minutes by default), and immediate refresh on
unknown key ID (when the auth server rotates keys).

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: 401 Unauthorized on valid JWT**
Symptom: Valid JWT from your auth server gets 401 from Spring resource server.
Diagnoses:
A - Issuer mismatch: JWT "iss" claim doesn't match spring.security.oauth2
.resourceserver.jwt.issuer-uri.
B - Audience mismatch: JWT "aud" claim doesn't include expected value.
C - Clock skew: server clocks differ by more than JWT tolerance.
D - JWKS fetch failed at startup: NimbusJwtDecoder couldn't reach issuer-uri.
Diagnosis: Enable spring.security.debug=true and check startup logs for
JWKS fetch success.

**Failure 2: Wrong authorities (403 on authorized user)**
Symptom: User has the correct role but gets 403 Forbidden.
Cause: JwtGrantedAuthoritiesConverter using wrong claim name or prefix.
Diagnosis: Add debug logging, log jwt.getClaims() in a @ControllerAdvice,
compare claim names with hasRole()/hasAuthority() calls.
Fix: Configure JwtAuthenticationConverter with correct authoritiesClaimName
and authorityPrefix.

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

#### Q1 - How does NimbusJwtDecoder verify a JWT?

NimbusJwtDecoder (from Nimbus JOSE + JWT library) performs:

1. Parse JWT structure: header.payload.signature (base64url decoded)

2. Read header: algorithm (alg), key ID (kid)

3. Fetch matching public key:
   - Check local JWKS cache for matching kid
   - If not found: refresh JWKS from configured endpoint
   - If still not found: throw JwtException

4. Verify signature:
   - Use public key (RS256: RSA, ES256: EC, HS256: HMAC)
   - Signature = base64url(sign(header + "." + payload))
   - Verify: signature valid with public key

5. Verify claims:
   - exp (expiry): must be in future
   - nbf (not before): if present, must be in past
   - iss (issuer): must match configured issuer-uri
   - Custom validators (aud, etc.): if configured

6. Return Jwt object with parsed claims

The JWKS cache is essential for performance. Spring's default NimbusJwtDecoder
uses an in-memory cache with a 10-minute TTL. On key rotation (new kid in JWT),
it immediately re-fetches JWKS once before rejecting.

*What separates good from great:* The security implication of kid mismatch
retry: an attacker could craft a JWT with a fake kid, causing the resource
server to re-fetch JWKS on every request (DoS via JWKS endpoint exhaustion).
Spring's NimbusJwtDecoder limits JWKS re-fetches. Configure the JWT key ID
consistently with your auth server. In Keycloak, the kid rotates with key
rotation. A misconfigured auth server constantly rotating keys will cause
cascading JWKS re-fetches.

---

#### Q2 - How do you configure multi-tenant JWT validation?

Multi-tenant: different tenants may use different identity providers (or
different Keycloak realms). The JWT "iss" claim identifies the issuer.

```java
@Bean
JwtIssuerAuthenticationManagerResolver
    authManagerResolver() {

    // Map issuer URLs to AuthenticationManagers
    Map<String, AuthenticationManager> issuers =
        Map.of(
            "https://keycloak.example.com/realms/tenant1",
            createAuthManager(
                "https://keycloak.example.com/realms/tenant1"),
            "https://auth0.example.com/",
            createAuthManager(
                "https://auth0.example.com/")
        );

    return new JwtIssuerAuthenticationManagerResolver(
        issuers::get);
}

private AuthenticationManager createAuthManager(
        String issuerUri) {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withIssuerLocation(issuerUri)
        .build();
    JwtAuthenticationProvider provider =
        new JwtAuthenticationProvider(decoder);
    provider.setJwtAuthenticationConverter(
        jwtConverter());
    return provider::authenticate;
}

// In SecurityFilterChain:
.oauth2ResourceServer(oauth2 -> oauth2
    .authenticationManagerResolver(
        authManagerResolver()))
```

Dynamic multi-tenant (tenants added at runtime):
```java
@Bean
JwtIssuerAuthenticationManagerResolver
    authManagerResolver(TenantService tenantService) {

    // Lazy loading - creates AuthenticationManager
    // for any issuer the first time it's seen
    return new JwtIssuerAuthenticationManagerResolver(
        issuer -> {
            if (!tenantService.isKnownIssuer(issuer)) {
                throw new JwtException(
                    "Unknown issuer: " + issuer);
            }
            // Returns cached or creates new
            return tenantService
                .getAuthManager(issuer);
        });
}
```

*What separates good from great:* The JwtIssuerAuthenticationManagerResolver
reads the "iss" claim WITHOUT validating the JWT (to know which decoder to use).
This is safe because the full validation (signature, expiry) happens after
the correct decoder is selected. However, it creates an opportunity for issuer
spoofing to cause DoS via exhausting unknown issuer creation. Always validate
the issuer against a known allowlist before creating an AuthenticationManager.

---

#### Q3 - How do you handle JWT expiry and clock skew?

JWT expiry (exp claim) validation:

Default: NimbusJwtDecoder checks exp > currentTime.
Clock skew: servers may have slightly different system clocks. A JWT with
exp=T issued by server A may appear expired on server B if B's clock is
30 seconds ahead.

Adding clock skew tolerance:
```java
@Bean
JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withJwkSetUri(jwksUri).build();

    OAuth2TokenValidator<Jwt> withClockSkew =
        new DelegatingOAuth2TokenValidator<>(
            JwtValidators.createDefaultWithIssuer(issuerUri),
            new JwtTimestampValidator(
                Duration.ofSeconds(60))); // 60s tolerance

    decoder.setJwtValidator(withClockSkew);
    return decoder;
}
```

Short-lived JWTs + refresh tokens pattern:
- Access token: 15 minutes (exp)
- Refresh token: 24 hours or user session length
- On 401 from resource server: client uses refresh token
  to get new access token from auth server

Clock synchronization:
- Use NTP (Network Time Protocol) in all servers
- Target < 1 second difference between servers
- Add clock skew tolerance of 30-60 seconds as buffer

*What separates good from great:* The right JWT expiry depends on the threat
model. Very short expiry (5 minutes) with refresh tokens limits the window
of stolen token abuse. Very long expiry (hours) simplifies client code but
extends the attack window. Standard recommendation: 15-minute access tokens,
24-hour refresh tokens (revocable at the auth server). In Kubernetes, ensure
all pods use the same NTP server.

---

#### Q4 - How does Spring OAuth2 client handle service-to-service authentication?

For service-to-service calls (no user context, service authenticates itself):

Client credentials OAuth2 flow:
1. Service authenticates with auth server using client_id + client_secret
2. Auth server issues an access token
3. Service uses token in outgoing HTTP calls

Spring configuration:
```java
// application.properties
spring.security.oauth2.client.registration
  .order-service.client-id=order-service
spring.security.oauth2.client.registration
  .order-service.client-secret=${CLIENT_SECRET}
spring.security.oauth2.client.registration
  .order-service.authorization-grant-type=\
    client_credentials
spring.security.oauth2.client.registration
  .order-service.scope=inventory:read
spring.security.oauth2.client.provider
  .order-service.token-uri=\
    https://auth.example.com/oauth/token

// WebClient with auto token injection
@Bean
WebClient inventoryClient(
        OAuth2AuthorizedClientManager clientManager) {
    ServletOAuth2AuthorizedClientExchangeFilterFunction filter =
        new ServletOAuth2AuthorizedClientExchangeFilterFunction(
            clientManager);
    filter.setDefaultClientRegistrationId("order-service");
    return WebClient.builder()
        .baseUrl("https://inventory-service")
        .apply(filter.oauth2Configuration())
        .build();
}
```

The OAuth2AuthorizedClientManager automatically:
1. Checks for a cached token for "order-service" client
2. If expired or missing: requests a new one using client credentials
3. Injects the token into the outgoing request

*What separates good from great:* Token caching is critical for service-to-service
performance. Without caching, every outgoing HTTP call would request a new token
from the auth server - O(N) auth server calls for N service calls. Spring's
OAuth2AuthorizedClientService caches tokens in-memory by default. For multi-pod
deployments, use a distributed cache (Redis) for the authorized client service
to share tokens across pods: implement OAuth2AuthorizedClientService using
RedisTemplate.

---

#### Q5 - What is the difference between JWT and opaque tokens?

**JWT (JSON Web Token)**:
- Self-contained: claims encoded in token body
- Stateless validation: verify signature locally
- No network call per request
- Cannot be revoked before expiry
- Claims visible (base64 decoded)
- Size: 200-2000 bytes (claims embedded)

**Opaque token**:
- Opaque reference: token is just an ID
- Stateful validation: must call token introspection endpoint
- Network call per request (or cache with TTL)
- Immediately revocable: delete from auth server DB
- Claims hidden: only auth server knows what token represents
- Size: 32-64 bytes (random ID)

Token introspection (RFC 7662):
```
POST /oauth/introspect
Authorization: Basic {service credentials}
token={opaque_token}

Response: {
  "active": true,
  "sub": "user123",
  "scope": "read write",
  "exp": 1700000000
}
```

Spring configuration for opaque tokens:
```java
.oauth2ResourceServer(oauth2 -> oauth2
    .opaqueToken(opaque -> opaque
        .introspectionUri(
            "https://auth.example.com/introspect")
        .introspectionClientCredentials(
            "resource-server-id",
            "resource-server-secret")));
```

*What separates good from great:* The trade-off is revocability vs performance.
For most microservice APIs, JWT is the right choice: stateless, fast, scales
to high throughput without auth server load. For financial transactions or
security-sensitive operations where immediate token revocation is required
(password change, fraud detection), opaque tokens with short introspection
cache (30 seconds) provide the best of both: fast most of the time, revocable
within the cache TTL.

---

#### Q6 - How do you implement token propagation in microservices?

Token propagation: when Service A receives a JWT from a client, it propagates
the same JWT to downstream Service B.

Pattern 1 - Forward the incoming token:
```java
@Configuration
public class WebClientConfig {

    @Bean
    WebClient downstreamClient(
            ClientHttpRequestInterceptor tokenRelay) {
        return WebClient.builder()
            .defaultHeader(...)
            .build();
    }
}

// TokenRelayGatewayFilterFactory (Spring Cloud Gateway)
// Or manually extract + forward:
@RestController
public class OrderController {

    @GetMapping("/api/orders/{id}/inventory")
    public Inventory getInventory(
            @PathVariable Long id,
            @RequestHeader("Authorization") String token) {
        // Forward the same token
        return inventoryClient
            .get()
            .uri("/api/inventory/{orderId}", id)
            .header("Authorization", token)
            .retrieve()
            .bodyToMono(Inventory.class)
            .block();
    }
}
```

Pattern 2 - Token exchange (RFC 8693):
Service A exchanges the user JWT for a service-scoped JWT:
```
POST /token
grant_type=urn:ietf:params:oauth:grant-type:token-exchange
subject_token={user_jwt}
subject_token_type=urn:ietf:params:oauth:token-type:jwt
requested_token_type=urn:ietf:params:oauth:token-type:jwt
audience=inventory-service
```
Returns a new JWT scoped for inventory-service with user's identity.

*What separates good from great:* Token propagation creates a security coupling:
every downstream service gets the full user JWT with all its claims and scopes.
If Service B doesn't need the user's email or profile data, it's unnecessary
exposure. Token exchange (RFC 8693) allows creating a downscoped token: the
user's identity is preserved (sub claim) but scopes and claims are limited to
what Service B needs. This is the principle of least privilege applied to token propagation.

---

#### Q7 - How do you test OAuth2-protected endpoints?

Spring Security Test provides @WithMockUser which works for basic auth but
not JWT. For JWT, use SecurityMockMvcRequestPostProcessors:

```java
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {

    @Autowired MockMvc mockMvc;

    @Test
    void getOrdersReturns200WhenAuthenticated()
            throws Exception {
        mockMvc.perform(
            get("/api/orders")
            .with(jwt()
                .authorities(
                    new SimpleGrantedAuthority(
                        "SCOPE_orders:read"))
                .jwt(j -> j
                    .subject("user123")
                    .claim("email", "test@example.com")))
            )
            .andExpect(status().isOk());
    }

    @Test
    void getOrdersReturns403WhenWrongScope()
            throws Exception {
        mockMvc.perform(
            get("/api/orders")
            .with(jwt()
                .authorities(
                    new SimpleGrantedAuthority(
                        "SCOPE_other:read")))
            )
            .andExpect(status().isForbidden());
    }
}
```

The jwt() post-processor creates a JwtAuthenticationToken without actual
JWT validation - no issuer-uri or JWKS needed in tests.

*What separates good from great:* The jwt() post-processor is from
spring-security-test. It populates the SecurityContext directly without
going through the JWT filter. This means tests run fast (no HTTP calls to
auth server) and work in CI without an auth server. For integration tests
that test the full JWT validation path, use Testcontainers to run a real
Keycloak instance and issue real JWTs.

---

#### Q8 - How do you extract custom JWT claims for authorization?

Standard JWT claims (sub, iss, aud, exp, scope) are handled by Spring
Security. Custom claims need custom extraction:

```java
// Custom authority extractor from nested Keycloak claim
// Keycloak puts realm roles in:
// {"realm_access": {"roles": ["ADMIN", "USER"]}}
@Bean
JwtAuthenticationConverter keycloakJwtConverter() {
    JwtGrantedAuthoritiesConverter converter =
        new JwtGrantedAuthoritiesConverter() {

            @Override
            public Collection<GrantedAuthority>
                    convert(Jwt jwt) {
                // Extract from nested claim
                Map<String, Object> realmAccess =
                    jwt.getClaimAsMap("realm_access");
                if (realmAccess == null) return List.of();

                @SuppressWarnings("unchecked")
                List<String> roles = (List<String>)
                    realmAccess.get("roles");
                if (roles == null) return List.of();

                return roles.stream()
                    .map(role -> new SimpleGrantedAuthority(
                        "ROLE_" + role.toUpperCase()))
                    .collect(Collectors.toList());
            }
        };

    JwtAuthenticationConverter jwtConverter =
        new JwtAuthenticationConverter();
    jwtConverter.setJwtGrantedAuthoritiesConverter(
        converter);
    return jwtConverter;
}
```

Accessing claims in controllers:
```java
// Method 1: @AuthenticationPrincipal Jwt
public ResponseEntity<?> resource(
        @AuthenticationPrincipal Jwt jwt) {
    String tenantId = jwt.getClaimAsString("tenant_id");
}

// Method 2: SecurityContextHolder
Jwt jwt = (Jwt) SecurityContextHolder.getContext()
    .getAuthentication().getPrincipal();
```

*What separates good from great:* Different identity providers use different
claim structures for roles. Auth0 uses "https://{namespace}/roles" custom claims.
Keycloak uses "realm_access.roles". AWS Cognito uses "cognito:groups". The
JwtGrantedAuthoritiesConverter must match your specific provider's structure.
Centralizing this in a configuration bean and testing it with all expected
claim formats prevents authorization bugs when switching providers.

---

#### Q9 - What are the security risks of JWT and how do you mitigate them?

Risk 1: Algorithm confusion attacks (alg=none / RS256 vs HS256 confusion)
Attack: Attacker crafts token with alg=none (no signature) or switches from
RS256 to HS256 using the server's public key as the HMAC secret.
Mitigation: NimbusJwtDecoder explicitly configures allowed algorithms.
NEVER use the HS256 algorithm with a public key. Configure allowedAlgorithms
explicitly, not "any".

Risk 2: JWT secret leakage (for HMAC-signed JWTs)
Attack: If the signing secret is exposed, attacker can forge any JWT.
Mitigation: Use asymmetric signing (RS256, ES256). The public key can be
shared freely. The private key (on the auth server) never leaves the server.

Risk 3: Token theft (stolen access token)
Attack: Attacker captures a valid JWT and uses it.
Mitigation: Short expiry (15 minutes). HTTPS only. Sender-constrained tokens
(DPoP - Demonstration of Proof of Possession) bind the token to the client's
private key.

Risk 4: Audience bypass (token replay across services)
Attack: Token issued for Service A used against Service B.
Mitigation: Validate "aud" claim in every resource server. Each service
expects its own name in the aud claim.

Risk 5: Overprivileged tokens
Attack: Token with excessive scopes used for privilege escalation.
Mitigation: Minimum scope principle. Request only needed scopes. Validate
scopes in every endpoint with specific scope requirements.

*What separates good from great:* DPoP (RFC 9449) is the modern mitigation
for token theft. The client proves possession of a private key on every request
by including a DPoP proof header. Even if an attacker steals the JWT, they cannot
use it without the client's private key. Spring Security 6.2+ supports DPoP.
This is becoming the standard for high-security financial APIs.

---

#### Q10 - How do you handle token refresh in a resource server context?

Resource servers don't handle token refresh - that's the client's responsibility.
Resource servers only validate the access token they receive.

Client-side refresh flow:
1. Client stores: access_token (15 min) + refresh_token (24h)
2. API call with access_token
3. Resource server returns 401 (token expired)
4. Client sends refresh_token to auth server's /token endpoint:
   POST /token
   grant_type=refresh_token
   refresh_token={refresh_token}
   client_id={client_id}
5. Auth server returns new access_token (+ possibly new refresh_token)
6. Client retries original request with new access_token

Resource server configuration to return proper 401:
```java
.oauth2ResourceServer(oauth2 -> oauth2
    .jwt(Customizer.withDefaults())
    .authenticationEntryPoint((req, res, ex) -> {
        res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        res.setHeader("WWW-Authenticate",
            "Bearer error=\"invalid_token\", "
            + "error_description=\"Token expired\"");
        res.getWriter().write(
            "{\"error\":\"token_expired\"}");
    }));
```

Proactive refresh (client side): refresh the token 30 seconds BEFORE expiry
to avoid the 401-then-retry latency on API calls.

*What separates good from great:* Silent token refresh in SPAs: the access
token is in-memory (not localStorage - XSS risk), the refresh token is in an
httpOnly cookie (not accessible to JavaScript - CSRF protected). When the access
token expires, an iframe makes a silent refresh request using the cookie. This
is the Auth0/Keycloak-recommended pattern for SPAs that balances security
(no token in localStorage) with UX (no visible login prompts).

---

#### Q11 - How does Spring Authorization Server work?

Spring Authorization Server (spring-authorization-server) is Spring's own
implementation of an OAuth2 Authorization Server:

```java
@Configuration
@Import(OAuth2AuthorizationServerConfiguration.class)
public class AuthorizationServerConfig {

    @Bean
    public RegisteredClientRepository registeredClientRepository() {
        RegisteredClient client = RegisteredClient
            .withId(UUID.randomUUID().toString())
            .clientId("order-service")
            .clientSecret(passwordEncoder()
                .encode("secret"))
            .clientAuthenticationMethod(
                ClientAuthenticationMethod
                    .CLIENT_SECRET_BASIC)
            .authorizationGrantType(
                AuthorizationGrantType.AUTHORIZATION_CODE)
            .authorizationGrantType(
                AuthorizationGrantType.REFRESH_TOKEN)
            .authorizationGrantType(
                AuthorizationGrantType.CLIENT_CREDENTIALS)
            .redirectUri(
                "https://app.example.com/callback")
            .scope(OidcScopes.OPENID)
            .scope("orders:read")
            .build();

        return new InMemoryRegisteredClientRepository(client);
    }

    @Bean
    public JWKSource<SecurityContext> jwkSource() {
        RSAKey rsaKey = Jwks.generateRsa();
        return new ImmutableJWKSet<>(
            new JWKSet(rsaKey));
    }
}
```

Features:
- Authorization Code flow (with PKCE for SPAs)
- Client Credentials flow (service-to-service)
- OIDC Discovery endpoint
- Token endpoint
- JWKS endpoint
- Token revocation
- Token introspection

*What separates good from great:* For production, Spring Authorization Server
is a solid choice for teams that need full control and want to stay in the
Spring ecosystem. It requires more setup than managed services (Keycloak, Auth0,
Okta) but eliminates external vendor dependency. The trade-off: Keycloak/Auth0
provide user management UI, social login, MFA out of the box. Spring Authorization
Server is a building block - you implement user management yourself. Choose based
on whether you need maximum control vs faster time to production.

---

#### Q12 - How do you implement a stateless microservice session using JWT?

Traditional sessions are server-side (session ID in cookie, session data in server
memory). JWT-based "sessions" are stateless:

```
JWT payload carries session state:
{
  "sub": "user123",        // user ID
  "email": "u@example.com",
  "roles": ["USER"],
  "tenant_id": "acme",     // multi-tenant
  "iat": 1700000000,       // issued at
  "exp": 1700000900,       // expires (15 min)
  "jti": "unique-token-id" // JWT ID (for revocation)
}
```

Stateless session lifecycle:
1. User logs in -> auth server issues JWT
2. Client stores JWT in-memory (SPA) or auth cookie (SSR)
3. Each request: JWT in Authorization header
4. Resource server validates JWT, extracts claims
5. Claims used for authorization and user context
6. No server-side session storage

Logout in stateless JWT:
- True stateless: client deletes token (server cannot know)
- Short expiry: token expires in 15 minutes anyway
- Revocation list: store jti in Redis, check on each request
  (adds state but enables immediate logout)

*What separates good from great:* The "truly stateless" JWT model doesn't support
real logout (cannot force all devices to log out). Production systems use a hybrid:
short-lived JWTs (15 min) + revocation check against Redis for security-critical
events (password change, account compromise). The revocation check is O(1) Redis
lookup per request - acceptable overhead for security. For regular logout (user
clicking logout), just expire the client-side token - don't add server-side state.
