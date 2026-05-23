---
layout: default
title: "Spring - Security"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 7
permalink: /interview/spring/security/
topic: Spring
subtopic: Security
keywords:
  - Spring Security Architecture
  - Authentication and Authorization
  - JWT and Stateless Security
  - OAuth2 and OpenID Connect
  - Method-Level Security
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Spring Security Architecture](#spring-security-architecture)
- [Authentication and Authorization](#authentication-and-authorization)
- [JWT and Stateless Security](#jwt-and-stateless-security)
- [OAuth2 and OpenID Connect](#oauth2-and-openid-connect)
- [Method-Level Security](#method-level-security)

# Spring Security Architecture

**TL;DR** - Spring Security is a filter-chain-based framework that intercepts every HTTP request through a series of `SecurityFilterChain` filters - handling authentication (who are you?), authorization (what can you do?), CSRF protection, session management, and more - before the request reaches your controller.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every controller checks authentication and authorization manually. Session management is hand-coded. CSRF tokens are implemented per form. Password hashing uses inconsistent algorithms. Security logic is scattered across the entire codebase.

**THE BREAKING POINT:**
A new endpoint is deployed without authentication checks. An attacker discovers it. The team realizes there is no centralized security enforcement - every developer must remember to add auth checks to every endpoint.

**THE INVENTION MOMENT:**
"This is exactly why Spring Security was created."

**EVOLUTION:**
Manual servlet filters -> Acegi Security (2003) -> Spring Security 2.0 (namespace config, 2008) -> Spring Security 3.0 (Spring 3 integration) -> Java config (3.2) -> SecurityFilterChain DSL (Spring Security 5.7+) -> Spring Security 6.0 (Jakarta, authorizeHttpRequests).

---

### 📘 Textbook Definition

Spring Security is a framework that provides authentication, authorization, and protection against common exploits. It integrates into the Servlet API via a `DelegatingFilterProxy` that delegates to a `FilterChainProxy` containing one or more `SecurityFilterChain` instances. Each chain is an ordered list of security filters (authentication, authorization, CSRF, session management, etc.) that process requests before they reach the DispatcherServlet. Security configuration is now done via a `SecurityFilterChain` bean using the `HttpSecurity` DSL.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
A chain of servlet filters that authenticate, authorize, and protect every request before it reaches your controller.

**One analogy:**

> Airport security checkpoints. Before you board (reach the controller), you pass through identity check (authentication), boarding pass verification (authorization), luggage scanning (CSRF/XSS protection), and customs (additional filters). Each checkpoint is independent and can deny entry.

**One insight:**
Spring Security is "secure by default" - adding the dependency locks down ALL endpoints. You explicitly open up public endpoints, not the other way around. This is the correct security posture.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Security filters run BEFORE DispatcherServlet. Controllers never see unauthenticated requests (unless explicitly allowed).
2. Authentication and authorization are separate concerns. Authentication = identity. Authorization = permissions.
3. The `SecurityContext` (holding the authenticated principal) is thread-local. It is set after authentication and available everywhere in the request thread.

**THE TRADE-OFFS:**

**Gain:** Centralized, declarative security. Secure by default.

**Cost:** Complex filter chain is hard to debug. Steep learning curve for customization.

---

### 🧠 Mental Model / Analogy

> Spring Security is like a building's access control system. The front door (DelegatingFilterProxy) routes you to the security desk (FilterChainProxy). The security desk checks your ID (authentication filter) and your badge (authorization filter). Different wings have different access rules (SecurityFilterChain per URL pattern). Once verified, you get a visitor badge (SecurityContext) that follows you everywhere.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
A security framework that automatically checks if users are logged in and have permission to access each URL.

**Level 2 - How to use it (junior):**

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain chain(
            HttpSecurity http)
            throws Exception {
        return http
            .authorizeHttpRequests(a -> a
                .requestMatchers(
                    "/public/**")
                .permitAll()
                .requestMatchers(
                    "/admin/**")
                .hasRole("ADMIN")
                .anyRequest()
                .authenticated())
            .formLogin(
                Customizer.withDefaults())
            .build();
    }

    @Bean
    public PasswordEncoder encoder() {
        return new BCryptPasswordEncoder();
    }
}
```

**Level 3 - How it works (mid-level):**

Filter chain order:

```
  HTTP Request
       |
  DelegatingFilterProxy
  (servlet filter registered in web.xml
   or auto-config)
       |
  FilterChainProxy
  (selects SecurityFilterChain by URL)
       |
  SecurityFilterChain filters (order):
    1. SecurityContextPersistenceFilter
    2. CsrfFilter
    3. LogoutFilter
    4. UsernamePasswordAuthFilter
    5. BasicAuthenticationFilter
    6. BearerTokenAuthFilter (OAuth2)
    7. ExceptionTranslationFilter
    8. AuthorizationFilter
       |
  DispatcherServlet (if authorized)
```

SecurityContext flow:

```
  Authentication filter validates
  credentials
       |
  Creates Authentication object
  (UserDetails + authorities)
       |
  Stores in SecurityContextHolder
  (ThreadLocal)
       |
  AuthorizationFilter checks
  authorities against URL rules
       |
  Controller: SecurityContextHolder
  .getContext().getAuthentication()
```

**Level 4 - Mastery (senior/staff+):**

Multiple filter chains:

```java
@Bean
@Order(1)
SecurityFilterChain apiChain(
        HttpSecurity http)
        throws Exception {
    return http
        .securityMatcher("/api/**")
        .authorizeHttpRequests(a -> a
            .anyRequest().authenticated())
        .oauth2ResourceServer(o -> o
            .jwt(Customizer.withDefaults()))
        .sessionManagement(s -> s
            .sessionCreationPolicy(
                STATELESS))
        .csrf(c -> c.disable())
        .build();
}

@Bean
@Order(2)
SecurityFilterChain webChain(
        HttpSecurity http)
        throws Exception {
    return http
        .authorizeHttpRequests(a -> a
            .requestMatchers("/login")
            .permitAll()
            .anyRequest().authenticated())
        .formLogin(
            Customizer.withDefaults())
        .build();
}
```

Custom authentication filter:

```java
public class ApiKeyFilter
        extends OncePerRequestFilter {
    protected void doFilterInternal(
            HttpServletRequest req,
            HttpServletResponse res,
            FilterChain chain)
            throws Exception {
        String key =
            req.getHeader("X-API-Key");
        if (apiKeyService.isValid(key)) {
            var auth =
                new ApiKeyAuthentication(
                    key, authorities);
            SecurityContextHolder
                .getContext()
                .setAuthentication(auth);
        }
        chain.doFilter(req, res);
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Configure Spring Security with `HttpSecurity`."

**A Staff says:** "I design separate `SecurityFilterChain` beans for API (stateless, JWT) and web (stateful, form login). I customize the filter chain by inserting custom filters at specific positions. I understand that security filters run outside DispatcherServlet, so `@ControllerAdvice` does not catch security exceptions - I configure `AuthenticationEntryPoint` and `AccessDeniedHandler` instead."

---

### ⚙️ How It Works

```
  Request: GET /api/users
       |
  DelegatingFilterProxy
       |
  FilterChainProxy: match /api/**
  -> select API SecurityFilterChain
       |
  BearerTokenAuthFilter:
    Extract JWT from Authorization
    header, validate, create
    Authentication object
       |
  AuthorizationFilter:
    Check if authenticated user
    has required authority
       |
  Pass: -> DispatcherServlet
  Fail: -> 403 Forbidden
```

---

### 💻 Code Example

**BAD manual auth check vs GOOD declarative:**

```java
// BAD - manual auth in every endpoint
@GetMapping("/admin/users")
public List<User> getUsers(
        HttpServletRequest req) {
    String token = req.getHeader(
        "Authorization");
    if (!authService.isAdmin(token)) {
        throw new ForbiddenException();
    }
    return userService.findAll();
}

// GOOD - declarative security
@GetMapping("/admin/users")
public List<User> getUsers() {
    return userService.findAll();
    // Security enforced by filter chain:
    // .requestMatchers("/admin/**")
    //     .hasRole("ADMIN")
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Filter-chain-based security framework for authentication and authorization.

**KEY INSIGHT:** Secure by default - lock down everything, then open specific paths.

**ANTI-PATTERN:** Manual auth checks in controllers. Disabling CSRF without understanding why.

**ONE-LINER:** "Filter chain authenticates and authorizes before DispatcherServlet."

**TRIGGER PHRASE:** "SecurityFilterChain, secure by default."

**If you remember only 3 things:**

1. Filter chain runs before DispatcherServlet - not controller-level
2. Secure by default - permit explicitly, not deny explicitly
3. SecurityContext is ThreadLocal - set by auth filter, read anywhere

---

### ⚠️ Common Misconceptions

| #   | Misconception                                   | Reality                                                                            |
| --- | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| 1   | "Security is controller-level"                  | Filter chain runs before DispatcherServlet. Controllers never see unauth requests. |
| 2   | "@ControllerAdvice catches security exceptions" | No. Security filters are outside DispatcherServlet. Use AuthenticationEntryPoint.  |
| 3   | "Disabling CSRF is always fine for APIs"        | Only safe for stateless (token-based) APIs. Session-based APIs need CSRF.          |
| 4   | "Spring Security is just authentication"        | Also: CSRF, CORS, session fixation, clickjacking, and more.                        |

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: How does Spring Security work?**

**Answer:**
It is a chain of servlet filters that intercept every HTTP request before it reaches the controller. Key filters: authentication (validate credentials), authorization (check permissions), CSRF (prevent cross-site request forgery). Configuration uses `SecurityFilterChain` bean with `HttpSecurity` DSL. Secure by default - all endpoints require authentication unless explicitly opened.

---

**Q2 [MID]: How would you configure different security for API and web endpoints?**

**Answer:**
Create two `SecurityFilterChain` beans with `@Order`:

1. API chain (`/api/**`): `@Order(1)`, stateless, JWT/OAuth2, CSRF disabled, returns 401/403 JSON
2. Web chain (everything else): `@Order(2)`, stateful, form login, CSRF enabled, redirects to login page

Each chain has its own authentication mechanism, session policy, and error handling. The `securityMatcher()` determines which chain handles which URLs.

---

**Q3 [SENIOR]: Why can't @ControllerAdvice handle Spring Security exceptions?**

**Answer:**
Spring Security filters run before DispatcherServlet in the servlet filter chain. `@ControllerAdvice` only catches exceptions thrown inside DispatcherServlet (controller methods). Security exceptions (401, 403) are thrown in the filter chain, outside DispatcherServlet scope.

Solution: configure `AuthenticationEntryPoint` (for 401) and `AccessDeniedHandler` (for 403) in the security config:

```java
http.exceptionHandling(e -> e
    .authenticationEntryPoint(
        (req, res, ex) -> {
            res.setStatus(401);
            res.getWriter().write(
                "{\"error\":\"Unauth\"}");
        })
    .accessDeniedHandler(
        (req, res, ex) -> {
            res.setStatus(403);
            res.getWriter().write(
                "{\"error\":\"Denied\"}");
        }));
```

---

### 🔗 Related Keywords

**Prerequisites:** Servlet Filters, DispatcherServlet

**Builds on:** Authentication and Authorization, JWT

**Alternatives:** Apache Shiro, Jakarta Security

---

---

# Authentication and Authorization

**TL;DR** - Authentication verifies identity ("who are you?") via credentials, while authorization checks permissions ("what can you do?") via roles and authorities - Spring Security separates these concerns with `AuthenticationManager` for identity verification and `AuthorizationManager` for access decisions.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Authentication and authorization are mixed together: `if (user.password == input && user.role == "ADMIN")`. Adding a new auth method (LDAP, OAuth) requires rewriting authorization logic. Permission checks are scattered and inconsistent.

**THE INVENTION MOMENT:**
"This is exactly why Authentication and Authorization were separated."

---

### 📘 Textbook Definition

Authentication is the process of verifying a user's identity, typically through credentials (username/password), tokens (JWT), or external providers (OAuth2). Authorization is the process of determining if an authenticated user has permission to perform an action, based on roles (`ROLE_ADMIN`) or authorities (`user:read`). Spring Security uses `AuthenticationManager` (with `AuthenticationProvider` chain) for authentication and `AuthorizationManager` (formerly `AccessDecisionManager`) for authorization.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Authentication = proving who you are; authorization = proving what you can do. Spring separates them completely.

**One analogy:**

> A concert. Authentication is showing your ID at the gate (proving identity). Authorization is your ticket type (VIP gets backstage, general admission gets the floor). You can be authenticated (valid ID) but not authorized (no VIP ticket).

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use it (junior):**

```java
@Bean
public UserDetailsService users() {
    UserDetails admin = User.builder()
        .username("admin")
        .password(encoder()
            .encode("password"))
        .roles("ADMIN", "USER")
        .build();

    UserDetails user = User.builder()
        .username("user")
        .password(encoder()
            .encode("password"))
        .roles("USER")
        .build();

    return new InMemoryUserDetailsManager(
        admin, user);
}
```

Custom `UserDetailsService` with database:

```java
@Service
public class DbUserDetailsService
        implements UserDetailsService {
    private final UserRepository repo;

    public UserDetails loadUserByUsername(
            String username) {
        AppUser user = repo
            .findByUsername(username)
            .orElseThrow(() ->
                new UsernameNotFoundException(
                    username));
        return User.builder()
            .username(user.getUsername())
            .password(user.getPassword())
            .authorities(
                user.getAuthorities())
            .build();
    }
}
```

**Level 3 - How it works (mid-level):**

Authentication flow:

```
  Login request (username + password)
       |
  UsernamePasswordAuthFilter
  creates UsernamePasswordAuthToken
       |
  AuthenticationManager delegates to
  AuthenticationProviders:
       |
  DaoAuthenticationProvider:
    1. UserDetailsService
       .loadUserByUsername()
    2. PasswordEncoder.matches()
    3. Success: return Authentication
       with UserDetails + authorities
    4. Fail: throw
       BadCredentialsException
       |
  SecurityContextHolder stores
  Authentication (ThreadLocal)
```

Roles vs Authorities:

| Concept        | Format        | Example                   |
| -------------- | ------------- | ------------------------- |
| Role           | ROLE\_ prefix | ROLE_ADMIN                |
| Authority      | No prefix     | user:read                 |
| hasRole()      | Adds ROLE\_   | hasRole("ADMIN")          |
| hasAuthority() | Exact match   | hasAuthority("user:read") |

**Level 4 - Mastery (senior/staff+):**

Fine-grained authority model:

```java
// URL-level authorization
http.authorizeHttpRequests(a -> a
    .requestMatchers(GET, "/api/users")
    .hasAuthority("user:read")
    .requestMatchers(POST, "/api/users")
    .hasAuthority("user:write")
    .requestMatchers("/api/admin/**")
    .hasRole("ADMIN"));

// Method-level authorization
@PreAuthorize(
    "hasAuthority('user:delete')")
public void deleteUser(Long id) { }

// Dynamic authorization
@PreAuthorize(
    "#userId == authentication.principal.id"
    + " or hasRole('ADMIN')")
public User getUser(
        @Param("userId") Long userId) { }
```

Custom AuthenticationProvider:

```java
@Component
public class LdapAuthProvider
        implements AuthenticationProvider {
    public Authentication authenticate(
            Authentication auth) {
        String username =
            auth.getName();
        String password = auth
            .getCredentials().toString();
        if (ldap.verify(
                username, password)) {
            return new
                UsernamePasswordAuthToken(
                    username, null,
                    ldap.getAuthorities(
                        username));
        }
        throw new
            BadCredentialsException(
                "LDAP auth failed");
    }
    public boolean supports(
            Class<?> auth) {
        return auth.equals(
            UsernamePasswordAuthToken
            .class);
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `hasRole()` for authorization."

**A Staff says:** "I design a permission model: roles group authorities, authorities map to operations (resource:action). URL-level authorization for coarse access, method-level `@PreAuthorize` for fine-grained. Custom `PermissionEvaluator` for domain-object-level security (can user X edit project Y?)."

---

### 💻 Code Example

**BAD mixed auth/authz vs GOOD separated:**

```java
// BAD - mixed in controller
@GetMapping("/users/{id}")
public User get(@PathVariable Long id,
        HttpServletRequest req) {
    String token =
        req.getHeader("Authorization");
    User caller = authService
        .authenticate(token);
    if (!caller.isAdmin()
            && !caller.getId().equals(id)) {
        throw new ForbiddenException();
    }
    return userService.findById(id);
}

// GOOD - separated via Spring Security
@GetMapping("/users/{id}")
@PreAuthorize(
    "#id == authentication.principal.id"
    + " or hasRole('ADMIN')")
public User get(@PathVariable Long id) {
    return userService.findById(id);
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Authentication = identity verification. Authorization = permission checking.

**KEY INSIGHT:** Roles group authorities. Use fine-grained authorities for real apps.

**ANTI-PATTERN:** Checking roles in business logic. Mixing auth and authz.

**ONE-LINER:** "AuthN = who, AuthZ = what. Spring separates them with Manager interfaces."

**TRIGGER PHRASE:** "UserDetailsService for auth, authorities for authz."

**If you remember only 3 things:**

1. Authentication = identity (AuthenticationManager)
2. Authorization = permissions (AuthorizationManager)
3. UserDetailsService loads user + authorities from your data store

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is the difference between authentication and authorization?**

**Answer:**
Authentication: proving WHO you are (username/password, JWT, OAuth). Result: `Authentication` object with identity and authorities.

Authorization: checking WHAT you can do. Based on authorities/roles from the `Authentication` object. Enforced at URL level (`authorizeHttpRequests`) and method level (`@PreAuthorize`).

Analogy: Authentication is showing your ID at the door. Authorization is checking if your ticket allows VIP access.

---

**Q2 [SENIOR]: Design an authorization model for a multi-tenant SaaS platform.**

**Answer:**
Three-layer model:

1. **Roles:** ADMIN, MANAGER, USER (per tenant)
2. **Authorities:** resource:action (project:read, project:write, billing:manage)
3. **Domain-level:** Custom `PermissionEvaluator` checking if user belongs to tenant and has authority on specific resource

```java
@PreAuthorize(
    "hasPermission(#projectId,"
    + " 'project', 'write')")
public void updateProject(
        Long projectId, ProjectDto dto) {}
```

PermissionEvaluator checks: user.tenantId == project.tenantId AND user has project:write authority. Tenant isolation is enforced at the security layer, not in business logic.

---

### 🔗 Related Keywords

**Prerequisites:** Spring Security Architecture, Servlet Filters

**Builds on:** JWT, OAuth2

**Alternatives:** Apache Shiro, Keycloak

---

---

# JWT and Stateless Security

**TL;DR** - JSON Web Tokens (JWT) enable stateless authentication by encoding user identity and authorities into a signed token sent with each request - eliminating server-side session storage and enabling horizontal scaling, at the cost of token revocation complexity.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Server stores session data in memory for every logged-in user. Scaling to 10 servers requires sticky sessions or shared session store (Redis). Load balancers must route users to the same server. Session replication adds latency and complexity.

**THE BREAKING POINT:**
The application scales to 20 instances behind a load balancer. Sticky sessions cause uneven load. Session replication slows down authentication. A server restart logs out thousands of users.

**THE INVENTION MOMENT:**
"This is exactly why JWT-based stateless authentication was created."

---

### 📘 Textbook Definition

A JWT is a compact, URL-safe token consisting of three Base64URL-encoded parts: Header (algorithm, type), Payload (claims: sub, exp, iat, roles), and Signature (HMAC or RSA). The server creates the token at login, the client sends it in the `Authorization: Bearer <token>` header on each request, and the server validates the signature and expiration without any server-side state. Spring Security's `oauth2-resource-server` module provides built-in JWT validation via `BearerTokenAuthenticationFilter`.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
The server signs a token at login; the client sends it on every request; the server verifies the signature without storing any session.

**One analogy:**

> A stamped wristband at a music festival. At entry (login), you get a wristband with your name and access level stamped on it (JWT payload). At every stage (request), security checks the wristband stamp (signature verification). No central database of wristbands needed. But if your wristband is stolen, security cannot revoke just yours until it expires.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use it (junior):**

JWT structure:

```
eyJhbGciOiJSUzI1NiJ9.     <- Header
eyJzdWIiOiJqb2huIiwiZ...    <- Payload
SflKxwRJSMeKKF2QT4fw...    <- Signature

Header:  {"alg":"RS256","typ":"JWT"}
Payload: {
  "sub": "john",
  "roles": ["USER", "ADMIN"],
  "iat": 1700000000,
  "exp": 1700003600
}
Signature: RS256(header + payload,
  privateKey)
```

Spring Security config:

```java
@Bean
SecurityFilterChain api(
        HttpSecurity http)
        throws Exception {
    return http
        .authorizeHttpRequests(a -> a
            .anyRequest().authenticated())
        .oauth2ResourceServer(o -> o
            .jwt(Customizer.withDefaults()))
        .sessionManagement(s -> s
            .sessionCreationPolicy(
                STATELESS))
        .csrf(c -> c.disable())
        .build();
}
```

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.example
            .com
          # or jwk-set-uri for JWKS
```

**Level 3 - How it works (mid-level):**

```
  Login: POST /auth/login
  {username, password}
       |
  AuthService validates credentials
       |
  Create JWT:
    Header: {"alg":"RS256"}
    Payload: {sub, roles, exp, iat}
    Sign with private key
       |
  Return token to client
       |
  Client stores token (memory, not
  localStorage for XSS safety)
       |
  Subsequent request:
  Authorization: Bearer <token>
       |
  BearerTokenAuthFilter:
    1. Extract token from header
    2. Decode and verify signature
    3. Check expiration
    4. Create Authentication object
       with authorities from claims
    5. Store in SecurityContext
       |
  AuthorizationFilter: check perms
```

**Level 4 - Mastery (senior/staff+):**

Access + Refresh token pattern:

```
  Login: returns both tokens
    access_token: short-lived (15min)
    refresh_token: long-lived (7 days)
       |
  Client uses access_token for API
       |
  Access token expires:
    Client sends refresh_token
    to /auth/refresh
       |
  Server validates refresh_token
  (check not revoked in DB)
       |
  Issues new access_token
  (optionally new refresh_token)
```

Custom JWT claims to authorities:

```java
@Bean
JwtAuthenticationConverter
        jwtAuthConverter() {
    var converter =
        new JwtAuthenticationConverter();
    converter
        .setJwtGrantedAuthoritiesConverter(
            jwt -> {
        var roles = jwt.getClaimAsStringList(
            "roles");
        return roles.stream()
            .map(r -> new SimpleGrantedAuthority(
                "ROLE_" + r))
            .collect(Collectors.toList());
    });
    return converter;
}
```

Token revocation strategies:

| Strategy               | Trade-off                |
| ---------------------- | ------------------------ |
| Short expiry (15min)   | Simple but 15min window  |
| Blocklist (Redis)      | Immediate but adds state |
| Token versioning       | Per-user revocation      |
| Refresh token rotation | Detect token theft       |

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JWT for stateless authentication."

**A Staff says:** "I use short-lived access tokens (15 min) with refresh token rotation. Access tokens are validated by signature only (stateless). Refresh tokens are stored in the database for revocation. I use RS256 (asymmetric) so resource servers validate without knowing the signing key. Custom claims map to authorities via `JwtAuthenticationConverter`."

---

### 💻 Code Example

**BAD storing JWT in localStorage vs GOOD httpOnly cookie:**

```java
// BAD - JWT in localStorage (XSS risk)
// JavaScript can access it:
// localStorage.getItem('token')
// XSS attack steals the token

// GOOD - JWT in httpOnly cookie
@PostMapping("/auth/login")
public ResponseEntity<Void> login(
        @RequestBody LoginReq req,
        HttpServletResponse res) {
    String token =
        authService.authenticate(req);
    ResponseCookie cookie =
        ResponseCookie.from("token", token)
        .httpOnly(true)   // No JS access
        .secure(true)     // HTTPS only
        .sameSite("Strict")
        .maxAge(Duration.ofMinutes(15))
        .path("/")
        .build();
    res.addHeader("Set-Cookie",
        cookie.toString());
    return ResponseEntity.ok().build();
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Signed tokens encoding identity and authorities for stateless authentication.

**KEY INSIGHT:** Stateless = no server-side session. Trade-off: revocation is hard.

**ANTI-PATTERN:** Storing JWT in localStorage (XSS). Using HMAC when asymmetric is needed.

**ONE-LINER:** "Short access token + refresh token rotation = secure stateless auth."

**TRIGGER PHRASE:** "RS256, short expiry, refresh rotation."

**If you remember only 3 things:**

1. JWT = Header.Payload.Signature (signed, not encrypted)
2. Short-lived access token (15 min) + refresh token for renewal
3. RS256 (asymmetric) for multi-service; token in httpOnly cookie, not localStorage

---

### ⚠️ Common Misconceptions

| #   | Misconception               | Reality                                                                             |
| --- | --------------------------- | ----------------------------------------------------------------------------------- |
| 1   | "JWT is encrypted"          | Only signed. Payload is Base64-encoded (readable). Use JWE for encryption.          |
| 2   | "JWT eliminates all state"  | Refresh token revocation needs DB/Redis. Fully stateless = 15min revocation delay.  |
| 3   | "Store JWT in localStorage" | XSS can steal it. Use httpOnly cookie with SameSite and Secure flags.               |
| 4   | "Long-lived JWT is fine"    | Long-lived tokens mean long compromise windows. Use short access + refresh pattern. |

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does JWT authentication work in Spring Security?**

**Answer:**

1. Client sends `Authorization: Bearer <token>`
2. `BearerTokenAuthenticationFilter` extracts and decodes the token
3. Verifies signature (RS256/HS256) and expiration
4. Extracts claims (sub, roles) into `Authentication` object
5. Stores in `SecurityContext` for the request

Config: `oauth2ResourceServer(o -> o.jwt(...))` with `issuer-uri` pointing to the auth server. Session policy = STATELESS. CSRF disabled (token-based auth is immune to CSRF).

---

**Q2 [SENIOR]: Design a JWT-based auth system for microservices.**

**Answer:**

- **Auth service:** Issues JWT (RS256 private key). Manages refresh tokens in DB.
- **Resource servers:** Validate JWT signature (public key via JWKS endpoint). No DB call.
- **Access token:** 15-minute expiry. Claims: sub, roles, tenantId.
- **Refresh token:** 7-day expiry, stored in DB, rotated on use (detect theft).
- **Token storage:** httpOnly/Secure/SameSite cookie for web. In-memory for mobile.
- **Revocation:** Refresh token revocation in DB. Access token blocklist in Redis for immediate revocation (optional trade-off vs pure stateless).
- **Key rotation:** JWKS endpoint serves multiple keys. Old key valid until all tokens expire.

---

### 🔗 Related Keywords

**Prerequisites:** Spring Security Architecture, HTTP Headers

**Builds on:** OAuth2 and OpenID Connect

**Alternatives:** Session-based auth, SAML, API Keys

---

---

# OAuth2 and OpenID Connect

**TL;DR** - OAuth2 is a delegation framework ("allow App X to access my data on Service Y") and OpenID Connect (OIDC) adds an identity layer on top ("also tell App X who I am"). Spring Security supports both as a client (login with Google) and as a resource server (validate access tokens).

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
To integrate with Google, you ask users for their Google password. Your app stores it, uses it to call Google APIs. If your app is compromised, all Google passwords are leaked. Users cannot revoke access without changing their password.

**THE INVENTION MOMENT:**
"This is exactly why OAuth2 was created."

---

### 📘 Textbook Definition

OAuth2 is an authorization framework (RFC 6749) that allows a third-party application to obtain limited access to an HTTP service on behalf of a resource owner. It defines four grant types: Authorization Code (web apps), Client Credentials (machine-to-machine), Resource Owner Password (legacy), and Device Code (IoT). OpenID Connect (OIDC) is an identity layer built on OAuth2 that adds an ID Token (JWT) containing user identity claims (sub, email, name). Spring Security's `spring-boot-starter-oauth2-client` handles the OAuth2/OIDC client flow; `spring-boot-starter-oauth2-resource-server` handles JWT token validation.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
OAuth2 = "let this app access my stuff without my password." OIDC = "and also tell the app who I am."

**One analogy:**

> Hotel key card. OAuth2: the front desk (authorization server) gives you a key card (access token) for your room (resource). You never give the maid (client app) the master key (password). OIDC: the key card also has your name and room number printed on it (ID token with identity claims).

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use it (junior):**

Login with Google:

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: ${GOOGLE_ID}
            client-secret: ${GOOGLE_SECRET}
            scope: openid, email, profile
```

Spring auto-configures `/oauth2/authorization/google` login URL.

**Level 3 - How it works (mid-level):**

Authorization Code flow:

```
  User clicks "Login with Google"
       |
  1. Redirect to Google:
  /authorize?client_id=X
  &redirect_uri=Y&scope=openid
  &response_type=code&state=Z
       |
  2. User logs in at Google
  Consents to requested scopes
       |
  3. Google redirects to callback:
  /callback?code=AUTH_CODE&state=Z
       |
  4. Backend exchanges code for tokens:
  POST /token
  {code, client_id, client_secret}
       |
  5. Google returns:
  {access_token, id_token,
   refresh_token}
       |
  6. Backend validates id_token (JWT)
  Extracts user identity
       |
  7. Creates session / issues JWT
```

Key concepts:

| Term                 | Meaning                           |
| -------------------- | --------------------------------- |
| Authorization Server | Issues tokens (Google, Keycloak)  |
| Resource Server      | Validates tokens (your API)       |
| Client               | Your app (web, mobile)            |
| Access Token         | Grants API access (opaque or JWT) |
| ID Token             | Contains user identity (JWT)      |
| Refresh Token        | Renews access token               |
| Scope                | Permissions requested             |

**Level 4 - Mastery (senior/staff+):**

Resource server (validate tokens):

```java
@Bean
SecurityFilterChain api(
        HttpSecurity http)
        throws Exception {
    return http
        .oauth2ResourceServer(o -> o
            .jwt(j -> j
                .jwtAuthenticationConverter(
                    jwtAuthConverter())))
        .build();
}
```

Client Credentials (machine-to-machine):

```java
@Bean
WebClient webClient(
        OAuth2AuthorizedClientManager
        manager) {
    var filter =
        new ServletOAuth2AuthorizedClient
        ExchangeFilterFunction(manager);
    return WebClient.builder()
        .apply(filter.oauth2Configuration())
        .build();
}
// WebClient auto-attaches access token
// for service-to-service calls
```

Spring Authorization Server (custom auth server):

```java
@Bean
RegisteredClientRepository clients() {
    RegisteredClient client =
        RegisteredClient
        .withId(UUID.randomUUID()
            .toString())
        .clientId("my-client")
        .clientSecret(encoder().encode(
            "secret"))
        .authorizationGrantType(
            AUTHORIZATION_CODE)
        .redirectUri(
            "http://localhost:8080"
            + "/callback")
        .scope(OidcScopes.OPENID)
        .build();
    return new InMemoryRegisteredClient
        Repository(client);
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use OAuth2 for social login."

**A Staff says:** "I design the auth architecture: Keycloak as the central authorization server, Authorization Code + PKCE for web/mobile clients, Client Credentials for service-to-service, and JWT validation at each resource server via JWKS endpoint. Token scopes map to fine-grained authorities. Refresh token rotation detects token theft."

---

### 💻 Code Example

**BAD storing user password vs GOOD OAuth2 delegation:**

```java
// BAD - storing third-party credentials
public void syncCalendar(
        String googleUser,
        String googlePassword) {
    // NEVER DO THIS!
    googleApi.login(
        googleUser, googlePassword);
}

// GOOD - OAuth2 delegation
public void syncCalendar(
        @AuthenticationPrincipal
        OidcUser user) {
    String accessToken = user
        .getIdToken().getTokenValue();
    // Access Google API with token
    // User never shared their password
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** OAuth2 = delegated authorization. OIDC = identity layer on top.

**KEY INSIGHT:** OAuth2 is for authorization (access), OIDC is for authentication (identity).

**ANTI-PATTERN:** Using Resource Owner Password grant. Storing third-party passwords.

**ONE-LINER:** "Authorization Code + PKCE for users. Client Credentials for services."

**TRIGGER PHRASE:** "OAuth2 for delegation, OIDC for identity."

**If you remember only 3 things:**

1. OAuth2 = authorization (access token). OIDC = authentication (ID token).
2. Authorization Code + PKCE is the recommended flow for all clients.
3. Resource server validates JWT via JWKS endpoint - no shared secret needed.

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Explain the OAuth2 Authorization Code flow.**

**Answer:**

1. Client redirects user to authorization server (`/authorize`)
2. User authenticates and consents to scopes
3. Auth server redirects back with authorization code
4. Client exchanges code for tokens (POST `/token` with code + client_secret)
5. Auth server returns access_token, id_token, refresh_token
6. Client uses access_token for API calls

PKCE extension: client generates code_verifier and code_challenge. Eliminates need for client_secret (safe for mobile/SPA).

---

**Q2 [SENIOR]: Design OAuth2 architecture for a microservices platform.**

**Answer:**

- **Authorization Server:** Keycloak (or Spring Authorization Server) - central identity management
- **Web client:** Authorization Code + PKCE. BFF (Backend for Frontend) holds tokens.
- **Mobile client:** Authorization Code + PKCE. Tokens in secure storage.
- **Service-to-service:** Client Credentials grant. Short-lived tokens.
- **Resource servers:** Validate JWT via Keycloak JWKS endpoint. No shared secrets.
- **Token claims:** sub, roles, tenantId, permissions -> mapped to Spring authorities
- **Token lifecycle:** Access (15 min), Refresh (7 days, rotated), ID (for client identity display)

---

### 🔗 Related Keywords

**Prerequisites:** HTTP, JWT, Spring Security Architecture

**Builds on:** Method-Level Security (authorities from token claims)

**Alternatives:** SAML (enterprise SSO), API Keys (simple machine auth)

---

---

# Method-Level Security

**TL;DR** - `@PreAuthorize`, `@PostAuthorize`, and `@Secured` annotations enforce authorization at the method level - checking roles, authorities, or SpEL expressions before or after method execution, providing fine-grained access control beyond URL patterns.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
URL-level security (`/admin/**` requires ADMIN) is too coarse. A single endpoint may need different permissions based on business logic: users can view their own profile but only admins can view others. URL patterns cannot express "user can only edit their own resource."

**THE INVENTION MOMENT:**
"This is exactly why method-level security annotations were created."

---

### 📘 Textbook Definition

Method-level security uses AOP proxies to enforce authorization on individual methods. `@PreAuthorize` evaluates a SpEL expression before method execution. `@PostAuthorize` evaluates after execution (can inspect return value). `@Secured` checks roles (no SpEL). `@PreFilter`/`@PostFilter` filter collections. Enabled via `@EnableMethodSecurity` on a configuration class.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`@PreAuthorize` checks permissions before a method runs, using SpEL expressions that can reference method parameters, authentication, and custom beans.

**One analogy:**

> Security guards at individual office doors. URL security is the building entrance (coarse). Method security is a guard at each office (fine-grained) who checks not just your badge but also whether you belong to this department or own this document.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use it (junior):**

```java
@Configuration
@EnableMethodSecurity
public class SecurityConfig { }

@Service
public class UserService {
    @PreAuthorize("hasRole('ADMIN')")
    public List<User> findAll() {
        return repo.findAll();
    }

    @PreAuthorize(
        "#id == authentication.principal.id"
        + " or hasRole('ADMIN')")
    public User findById(Long id) {
        return repo.findById(id)
            .orElseThrow();
    }

    @PostAuthorize(
        "returnObject.owner"
        + " == authentication.name")
    public Document getDocument(
            Long docId) {
        return docRepo.findById(docId)
            .orElseThrow();
    }
}
```

**Level 3 - How it works (mid-level):**

| Annotation     | When   | SpEL | Use Case                 |
| -------------- | ------ | ---- | ------------------------ |
| @PreAuthorize  | Before | Yes  | Check before execution   |
| @PostAuthorize | After  | Yes  | Check return value       |
| @Secured       | Before | No   | Simple role check        |
| @PreFilter     | Before | Yes  | Filter input collection  |
| @PostFilter    | After  | Yes  | Filter output collection |

```java
// Filter output: only return user's
// own orders
@PostFilter(
    "filterObject.userId"
    + " == authentication.principal.id")
public List<Order> findOrders() {
    return orderRepo.findAll();
}
```

**Level 4 - Mastery (senior/staff+):**

Custom PermissionEvaluator:

```java
@Component
public class CustomPermEvaluator
        implements PermissionEvaluator {
    public boolean hasPermission(
            Authentication auth,
            Object target,
            Object permission) {
        if (target instanceof Project p) {
            String perm =
                (String) permission;
            Long userId =
                ((AppUser) auth
                    .getPrincipal())
                    .getId();
            return membershipRepo
                .hasPermission(
                    userId,
                    p.getId(), perm);
        }
        return false;
    }
    // ... serializable version
}

// Usage:
@PreAuthorize(
    "hasPermission(#project,"
    + " 'EDIT')")
public void update(Project project) { }
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@PreAuthorize` with role checks."

**A Staff says:** "I implement a custom `PermissionEvaluator` for domain-object-level authorization (can user X edit project Y?). URL security handles coarse access. Method security handles fine-grained business rules. SpEL expressions reference method parameters and authentication for dynamic authorization."

---

### 💻 Code Example

**BAD manual permission check vs GOOD @PreAuthorize:**

```java
// BAD - manual check in service
public User getProfile(Long userId) {
    Long callerId = SecurityContextHolder
        .getContext().getAuthentication()
        .getPrincipal().getId();
    if (!callerId.equals(userId)
            && !isAdmin()) {
        throw new AccessDeniedException(
            "Not allowed");
    }
    return repo.findById(userId)
        .orElseThrow();
}

// GOOD - declarative with SpEL
@PreAuthorize(
    "#userId == authentication"
    + ".principal.id"
    + " or hasRole('ADMIN')")
public User getProfile(Long userId) {
    return repo.findById(userId)
        .orElseThrow();
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** AOP-based method-level authorization with SpEL expressions.

**KEY INSIGHT:** Fine-grained access control beyond URL patterns. Can reference method params.

**ANTI-PATTERN:** Manual SecurityContext checks in service methods.

**ONE-LINER:** "@PreAuthorize with SpEL = fine-grained authz at method level."

**TRIGGER PHRASE:** "Method security, PermissionEvaluator."

**If you remember only 3 things:**

1. @PreAuthorize with SpEL for dynamic authorization
2. Custom PermissionEvaluator for domain-object security
3. AOP proxy - same self-invocation trap as @Transactional

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: What is the difference between URL-level and method-level security?**

**Answer:**
URL-level: coarse-grained. `/admin/**` requires ADMIN role. Applied in `SecurityFilterChain`. Good for broad access patterns.

Method-level: fine-grained. `@PreAuthorize` on individual methods. Can reference method parameters (`#userId`), return values (`returnObject`), and authentication details. Good for business rules: "users can only view their own data."

Use both together: URL security as the first gate, method security for business-level authorization.

---

**Q2 [SENIOR]: How would you implement "users can only edit their own projects" authorization?**

**Answer:**
Custom `PermissionEvaluator`:

1. Register a `PermissionEvaluator` bean that checks project membership in the database
2. Use `@PreAuthorize("hasPermission(#projectId, 'Project', 'EDIT')")` on service methods
3. The evaluator queries: does userId have EDIT permission on projectId?

This separates authorization logic from business logic. The service method focuses on the operation; the evaluator handles the access decision.

For performance: cache permission lookups (user-project pairs change infrequently).

---

### 🔗 Related Keywords

**Prerequisites:** Spring Security Architecture, Authentication and Authorization

**Builds on:** AOP (proxy-based interception)

**Alternatives:** URL-level authorizeHttpRequests (coarser)
