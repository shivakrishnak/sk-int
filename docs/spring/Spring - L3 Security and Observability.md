---
layout: default
title: "Spring - L3 Security and Observability"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 8
permalink: /spring/l3-security-and-observability/
---

# Spring - L3 Security and Observability

---

# Spring Security Filter Chain

---
id: SPR-018
title: Spring Security Filter Chain
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #spring-security, #filter-chain, #authentication, #authorization
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — Spring Security is in most Spring Boot applications.
Understanding the filter chain architecture is essential for configuration and debugging.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Security is implemented as a chain of Servlet Filters. The
> DelegatingFilterProxy bridges the Servlet container and Spring context.
> Inside, FilterChainProxy holds a list of SecurityFilterChain instances,
> each with a list of filters. The filters run in a fixed order: authentication
> first, then authorization. You configure security by defining a
> SecurityFilterChain @Bean with HttpSecurity.

**3 minutes (Senior):**
> The architecture has two levels. At the Servlet level, DelegatingFilterProxy
> is registered as a filter named "springSecurityFilterChain". It delegates
> to the FilterChainProxy Spring bean. FilterChainProxy holds one or more
> SecurityFilterChain beans (ordered by @Order). For each request, it finds
> the first SecurityFilterChain whose requestMatcher matches and runs its
> filters.
>
> The filter order within a chain is fixed by the framework. Key filters:
> SecurityContextPersistenceFilter loads SecurityContext from session.
> UsernamePasswordAuthenticationFilter handles form login. BasicAuthenticationFilter
> handles HTTP Basic. BearerTokenAuthenticationFilter handles JWT. FilterSecurityInterceptor
> (or AuthorizationFilter in Spring Security 6) checks authorization.
>
> Authentication and Authorization are separate concerns. Authentication
> establishes WHO the caller is (populates SecurityContext). Authorization
> decides WHAT they can do (checks SecurityContext against rules).

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - custom authentication providers, OAuth2 resource server
configuration, method security with @PreAuthorize and SpEL expressions.

*Adapting down:* Junior - "Spring Security adds security checks before every
HTTP request via filters. It first checks who you are (authentication), then
what you're allowed to do (authorization)."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how Spring Security processes security for
incoming HTTP requests."

**(2) First principles:** "Every request needs to be authenticated and authorized.
Using filters to intercept requests before they reach controllers is the right
place for security - it applies to all endpoints uniformly."

**(3) Bridge:** "The security filter chain is like airport security: first
you show your passport (authentication), then they check your boarding pass
(authorization). All passengers (requests) go through the same checkpoints."

---

### 📘 Concept Explanation

**What it is:**
Spring Security implements HTTP security as a chain of Servlet Filters that
intercept requests before they reach the DispatcherServlet. This ensures all
requests are authenticated and authorized regardless of the controller they
target.

**The problem it solves:**
HTTP security (authentication, authorization, CSRF protection, session management)
applies to all requests. Implementing it in each controller would be repetitive
and easy to forget. Filters intercept ALL requests at the infrastructure layer,
before business logic runs.

**How it works:**

```
Spring Security - Filter Chain Architecture:

Servlet Container
  |
  v
DelegatingFilterProxy (Servlet filter)
  - registered in web.xml / auto-configured by Boot
  - delegates to "springSecurityFilterChain" Spring bean
  |
  v
FilterChainProxy (Spring bean)
  - holds multiple SecurityFilterChain beans
  - matches first SecurityFilterChain whose path matches
  - runs its filter list
  |
  v
SecurityFilterChain (your @Bean configuration)
  - requestMatcher: which paths this chain covers
  - filterList: ordered list of Security Filters

Key filters (in order):
  1. SecurityContextHolderFilter
     - loads SecurityContext into holder
  2. UsernamePasswordAuthenticationFilter
     - handles POST /login form submission
  3. BasicAuthenticationFilter
     - handles Authorization: Basic header
  4. BearerTokenAuthenticationFilter
     - handles Authorization: Bearer JWT
  5. ExceptionTranslationFilter
     - catches AccessDeniedException
     - sends 401/403 response
  6. AuthorizationFilter
     - checks SecurityContext against rules
     - throws AccessDeniedException if denied

SecurityContext:
  - ThreadLocal storage for Authentication object
  - Authentication = principal + authorities + credentials
  - SecurityContextHolder.getContext().getAuthentication()

Authentication flow:
  Request arrives
    -> AuthenticationFilter extracts credentials
    -> Creates Authentication token (unauthenticated)
    -> Passes to AuthenticationManager
    -> AuthenticationManager delegates to
       AuthenticationProvider(s)
    -> Provider verifies (database, LDAP, OAuth2 token)
    -> Returns authenticated Authentication
    -> Stored in SecurityContext

Authorization flow:
  After authentication
    -> AuthorizationFilter checks SecurityContext
    -> Applies HttpSecurity rules
       (antMatchers, hasRole, hasAuthority)
    -> @PreAuthorize/@PostAuthorize for method security
```

**The key insight:**
Spring Security runs BEFORE DispatcherServlet - in the Servlet filter layer.
This means security decisions happen before Spring MVC routing, AOP, and
your controller code. If security denies access, the request never reaches
the controller. This is why @Transactional annotations on controllers don't
protect against unauthorized access - security runs at a lower layer.

**When to use it:**
- All Spring Boot web applications that need authentication/authorization
- JWT-based REST API authentication
- Form-based login for web applications
- OAuth2/OIDC integration

**When NOT to use it:**
- Do not implement custom authentication logic when standard providers exist
- Do not roll your own JWT parsing - use spring-security-oauth2-resource-server

**Alternatives:**
- Spring Security OAuth2: for OAuth2/OIDC integration (built on top)
- API Gateway authentication: handle in gateway, pass trusted headers to services

**First-principles derivation:**
HTTP security is a cross-cutting concern that must apply to all requests. Servlet
Filters are the right architectural point: they intercept all HTTP traffic before
it reaches any application code. The filter chain pattern allows ordering security
concerns and making them composable.

---

### 💻 Code Example

```java
// Basic SecurityFilterChain configuration
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        http
            // Disable CSRF for REST APIs
            // (CSRF attacks require browsers/sessions)
            .csrf(AbstractHttpConfigurer::disable)
            // Stateless - no session
            .sessionManagement(session -> session
                .sessionCreationPolicy(
                    SessionCreationPolicy.STATELESS))
            // Authorization rules
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET,
                    "/api/products/**").hasRole("USER")
                .requestMatchers("/api/admin/**")
                    .hasRole("ADMIN")
                .anyRequest().authenticated())
            // JWT authentication filter
            .addFilterBefore(
                jwtAuthenticationFilter(),
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public JwtAuthenticationFilter
            jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(
            jwtService, userDetailsService);
    }
}
```

> **Code walkthrough:** The SecurityFilterChain bean defines all security rules.
> csrf.disable() is correct for stateless REST APIs - CSRF is only relevant for
> browser sessions. STATELESS session policy ensures Spring Security never creates
> an HTTP session. requestMatchers rules are evaluated in order - more specific
> before generic. anyRequest().authenticated() is the catch-all requiring auth.
> The JWT filter is added before the standard auth filter.

```java
// Custom JWT authentication filter
@Component
public class JwtAuthenticationFilter
        extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader(
            "Authorization");
        if (authHeader == null ||
                !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return; // no JWT - continue (may be rejected later)
        }

        String jwt = authHeader.substring(7);
        try {
            String username = jwtService.extractUsername(jwt);
            if (username != null &&
                    SecurityContextHolder.getContext()
                        .getAuthentication() == null) {

                UserDetails user = userDetailsService
                    .loadUserByUsername(username);

                if (jwtService.isTokenValid(jwt, user)) {
                    // Create auth token and store in context
                    UsernamePasswordAuthenticationToken auth =
                        new UsernamePasswordAuthenticationToken(
                            user, null,
                            user.getAuthorities());
                    auth.setDetails(
                        new WebAuthenticationDetailsSource()
                            .buildDetails(request));
                    SecurityContextHolder.getContext()
                        .setAuthentication(auth);
                }
            }
        } catch (JwtException e) {
            log.warn("Invalid JWT: {}", e.getMessage());
            // Continue without setting auth -
            // authorization filter will reject
        }
        filterChain.doFilter(request, response);
    }
}
```

> **Code walkthrough:** OncePerRequestFilter ensures the filter runs exactly
> once per request. The filter extracts the JWT, validates it, and populates
> SecurityContext. Critically: the filter does NOT return early on invalid JWT
> for protected endpoints - it continues to filterChain.doFilter(). The
> authorization rules in SecurityFilterChain handle rejection (401). The filter
> also catches JwtException to prevent error stack traces reaching the client
> (information leakage prevention).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Security works through Servlet Filters that intercept requests before
> they reach controllers. The filters authenticate (verify who you are) and
> authorize (check what you can do) each request. You configure security with
> a SecurityFilterChain @Bean using HttpSecurity to define which URLs need
> authentication, which roles are required, and how users log in.

*Push deeper:* Explain the difference between authentication (identity verification)
and authorization (access control), and where each happens in the filter chain.

---

**Senior / Staff (5+ years):**
> Spring Security is a Servlet Filter chain. DelegatingFilterProxy bridges
> Servlet and Spring. FilterChainProxy holds SecurityFilterChain beans, selecting
> the first matching chain per request. Authentication filters (JWT, Basic, Form)
> populate SecurityContext. AuthorizationFilter enforces rules. Method security
> (@PreAuthorize) runs as AOP on service layer. Key insight: SecurityContext is
> ThreadLocal - it is cleared after each request. For async processing, use
> DelegatingSecurityContextExecutor to propagate the context to async threads.

*Push deeper:* Spring Security 6 replaced FilterSecurityInterceptor with
AuthorizationFilter (authorizationManager-based API). @EnableMethodSecurity
replaces @EnableGlobalMethodSecurity. The new API is more extensible and
supports composable AuthorizationManager implementations.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring Security can be disabled with one annotation."**
Spring Security filters intercept ALL requests. Excluding the auto-configuration
(SecurityAutoConfiguration.class) disables Spring Security entirely. Disabling
only specific filters requires careful configuration of the filter chain.

**Misconception 2: "@PreAuthorize is checked by Spring Security filters."**
@PreAuthorize is method security - it runs as AOP on Spring beans, AFTER the
request reaches the service layer. It is not part of the Servlet filter chain.
Both layers provide authorization but at different points.

**Misconception 3: "CSRF must always be disabled for REST APIs."**
CSRF attacks are relevant only for browser-based requests where cookies carry
session tokens. Stateless JWT-based APIs without session cookies are not
vulnerable to CSRF. Disabling CSRF for stateful session-based APIs (even REST
ones called from browsers) is a vulnerability.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: 403 Forbidden on valid request**
Symptom: User is authenticated but gets 403 on an endpoint.
Cause: Missing role/authority, wrong hasRole vs hasAuthority format
(hasRole("ADMIN") matches ROLE_ADMIN authority; hasAuthority("ADMIN") matches
exact "ADMIN").
Diagnosis: Debug security with spring.security.debug=true; check
Authentication.getAuthorities() value.

**Failure 2: SecurityContext empty in async thread**
Symptom: NullPointerException when accessing SecurityContextHolder in an @Async
method.
Cause: SecurityContext is ThreadLocal - not inherited by async threads.
Fix: Use DelegatingSecurityContextExecutor or configure
SecurityContextHolder to use InheritableThreadLocal mode.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How does Spring Security integrate with Spring Boot?

Spring Boot auto-configures Spring Security via SecurityAutoConfiguration.
When spring-boot-starter-security is on the classpath:

1. SecurityAutoConfiguration imports SpringBootWebSecurityConfiguration
2. A default SecurityFilterChain bean is created (form login, HTTP Basic enabled)
3. A default user with random password is created (printed at startup)
4. All endpoints require authentication

To override: define your own SecurityFilterChain @Bean. Your bean replaces
the auto-configured default.

*What separates good from great:* Spring Boot 2.7+ changed SecurityFilterChain
to use the component model (no need to extend WebSecurityConfigurerAdapter).
WebSecurityConfigurerAdapter is deprecated. Modern configuration is done
by defining @Bean SecurityFilterChain(HttpSecurity) methods.

---

#### Q2 - What is the SecurityContext and how is it stored?

SecurityContext holds the Authentication for the current request.
Storage: ThreadLocal (default) via SecurityContextHolder.

For each request:
1. SecurityContextHolderFilter loads SecurityContext from session (if any)
2. Authentication filter populates SecurityContext
3. Business logic reads from SecurityContextHolder.getContext()
4. SecurityContextHolderFilter saves context to session (if stateful) and
   clears the ThreadLocal

SecurityContextHolder strategies:
- MODE_THREADLOCAL (default): ThreadLocal per thread
- MODE_INHERITABLETHREADLOCAL: inherited by child threads
- MODE_GLOBAL: single global context (testing only)

*What separates good from great:* For reactive (WebFlux) applications,
SecurityContext is stored in Reactor context, not ThreadLocal. Never use
SecurityContextHolder in reactive code - use ReactiveSecurityContextHolder instead.

---

#### Q3 - What is the difference between hasRole() and hasAuthority()?

**hasRole("ADMIN")**:
- Checks for an authority with "ROLE_" prefix: "ROLE_ADMIN"
- Spring Security's convention: roles are stored with ROLE_ prefix
- Users loaded with UserDetailsService should have authority "ROLE_ADMIN"

**hasAuthority("ADMIN")**:
- Checks for an authority matching exactly: "ADMIN"
- No prefix convention

This causes a common bug: user has authority "ROLE_ADMIN" but access rule
uses hasRole("ROLE_ADMIN") which checks for "ROLE_ROLE_ADMIN" - access denied.

Rule: use hasRole("X") for roles, grant authorities as "ROLE_X".
Or use hasAuthority() exclusively with exact authority strings.

*What separates good from great:* Spring Security 6 simplified this by making
hasRole() and hasAuthority() more explicit. When using JWT claims for roles,
you typically store them without prefix and use hasAuthority(). Configure the
JwtAuthenticationConverter to extract claims correctly.

---

#### Q4 - How does Spring Security handle authentication?

Authentication flow:

1. AuthenticationFilter extracts credentials from request
   (JWT Bearer header, Basic Auth header, form data)

2. Creates unauthenticated Authentication token
   (e.g., UsernamePasswordAuthenticationToken with credentials but not authenticated)

3. Passes to AuthenticationManager (usually ProviderManager)

4. ProviderManager iterates AuthenticationProvider list
   - DaoAuthenticationProvider: loads UserDetails, verifies password
   - JwtAuthenticationProvider: validates JWT
   - LdapAuthenticationProvider: verifies against LDAP

5. Provider returns authenticated Authentication
   (with principal, credentials, authorities, isAuthenticated=true)

6. Authenticated Authentication stored in SecurityContext

Custom AuthenticationProvider:
```java
@Component
public class ApiKeyAuthProvider
        implements AuthenticationProvider {
    @Override
    public Authentication authenticate(
            Authentication auth) throws AuthenticationException {
        String apiKey = auth.getCredentials().toString();
        ApiKeyUser user = apiKeyService.lookup(apiKey);
        if (user == null) throw new BadCredentialsException(
            "Invalid API key");
        return new UsernamePasswordAuthenticationToken(
            user, null, user.getAuthorities());
    }

    @Override
    public boolean supports(Class<?> authType) {
        return ApiKeyAuthenticationToken.class
            .isAssignableFrom(authType);
    }
}
```

*What separates good from great:* AuthenticationProvider.supports() allows
multiple providers to coexist for different authentication types. ProviderManager
iterates providers, calling authenticate() only on those where supports() returns
true. This is how JWT + Basic + API key can all work in the same application.

---

#### Q5 - What is the difference between authentication and authorization in Spring Security?

**Authentication** - WHO are you?
- Verifies identity
- Runs in authentication filters (before DispatcherServlet)
- Result: populated SecurityContext with authenticated principal
- Failure: 401 Unauthorized

**Authorization** - WHAT are you allowed to do?
- Checks permission based on identity
- Runs in AuthorizationFilter (Servlet layer) or AOP (@PreAuthorize, @PostAuthorize)
- HttpSecurity rules: URL-level authorization
- @PreAuthorize: method-level authorization
- Failure: 403 Forbidden

Order: authentication always before authorization. Authorization reads from
SecurityContext which authentication populated.

*What separates good from great:* Having both URL-level and method-level
authorization is defense in depth. URL-level catches requests early (no
controller code runs). Method-level catches direct service calls not going
through the HTTP layer (batch jobs, event listeners).

---

#### Q6 - How do you configure multiple SecurityFilterChain beans?

Multiple SecurityFilterChain beans allow different security configurations
for different URL patterns:

```java
@Bean
@Order(1)  // checked first
public SecurityFilterChain apiSecurity(
        HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/**")  // only for /api/**
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(s -> s.sessionCreationPolicy(
            SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a -> a
            .anyRequest().authenticated())
        .oauth2ResourceServer(
            c -> c.jwt(Customizer.withDefaults()))
        .build();
}

@Bean
@Order(2)  // checked second (lower priority)
public SecurityFilterChain webSecurity(
        HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/**")  // all other URLs
        .csrf(Customizer.withDefaults())
        .formLogin(Customizer.withDefaults())
        .build();
}
```

FilterChainProxy checks chains in @Order order. First matching chain handles
the request. API routes use JWT (stateless). Web routes use form login (session).

*What separates good from great:* Spring Security 6 moved from
antMatcher/mvcMatcher to requestMatcher. securityMatcher() accepts
RequestMatcher instances. Using Spring MVC's MvcRequestMatcher (vs AntPathRequestMatcher)
ensures the matcher uses the same path matching as your controllers - preventing
bypass via path variation.

---

#### Q7 - How does CSRF protection work and when should you disable it?

CSRF (Cross-Site Request Forgery) attacks trick authenticated browser users into
making malicious requests using their session cookies.

Spring Security's CSRF protection:
1. Generates a CSRF token stored in the session
2. Requires the token in a header or form field for state-changing requests
   (POST, PUT, DELETE, PATCH)
3. Requests without the token get 403 Forbidden

When to DISABLE CSRF:
- Stateless REST APIs (JWT in Authorization header, no session cookies)
- When clients are not browsers (mobile apps, other backends)
- When your frontend sends the CSRF token in the request (Angular, React with
  Spring Security CSRF support)

When to KEEP CSRF enabled:
- Traditional web applications using session cookies
- Any endpoint called from a browser where cookies carry the session

```java
// Disable for stateless API
.csrf(AbstractHttpConfigurer::disable)

// Or disable only for specific paths
.csrf(csrf -> csrf
    .ignoringRequestMatchers("/api/webhooks/**"))
```

*What separates good from great:* SameSite cookie attribute provides additional
CSRF protection at the browser level. Setting session cookie to SameSite=Strict
prevents cross-site requests from including the cookie at all. This is a defense-
in-depth approach: CSRF tokens + SameSite cookie together.

---

#### Q8 - How do you implement @PreAuthorize method security?

@PreAuthorize checks authorization before the method executes:

```java
@Configuration
@EnableMethodSecurity  // enables @PreAuthorize
public class MethodSecurityConfig {}

@Service
public class OrderService {

    @PreAuthorize("hasRole('USER')")
    public List<Order> getMyOrders(String userId) {
        return orderRepository.findByUserId(userId);
    }

    // SpEL with parameters
    @PreAuthorize("hasRole('ADMIN') or " +
                  "#userId == authentication.name")
    public Order getOrder(Long orderId, String userId) {
        return orderRepository.findById(orderId)...;
    }

    @PostAuthorize("returnObject.userId == " +
                   "authentication.name")
    public Order getOrderById(Long id) {
        // method runs, then return value is checked
        return orderRepository.findById(id)...;
    }
}
```

@PreAuthorize evaluates SpEL: `authentication.name`, `principal.username`,
`hasRole()`, `hasAuthority()`, method parameters (#paramName).

*What separates good from great:* @PreAuthorize uses Spring AOP (BeanPostProcessor).
This means: only works on Spring beans, not on new-created objects; self-invocation
bypasses it; must be on public methods (CGLIB). For fine-grained data-level
authorization, consider a domain-object security framework (ACL module).

---

#### Q9 - How do you debug Spring Security issues?

Enable security debug logging:
```properties
logging.level.org.springframework.security=DEBUG
# Or only filter chain decisions:
logging.level.org.springframework.security.web=DEBUG
```

This logs:
- Which SecurityFilterChain matched the request
- Which filters ran and in what order
- Authentication decisions and their reasoning
- Authorization decisions

Spring Security's built-in debug mode:
```java
@EnableWebSecurity(debug = true)
```
This logs request details and filter invocations at DEBUG level.

Key things to look for in debug output:
1. "Security filter chain: [" ... "]" - which chain matched
2. "An Authentication object was found" - authentication succeeded
3. "Voter ... voted ..." - authorization decision
4. "Access is denied" - what rule blocked access

*What separates good from great:* The most common debug step is checking what
authorities are on the Authentication object:
```java
Authentication auth = SecurityContextHolder.getContext()
    .getAuthentication();
log.debug("Authorities: {}", auth.getAuthorities());
```
If the authority list doesn't match your hasRole/hasAuthority checks,
that's your bug.

---

# Spring Boot Actuator

---
id: SPR-019
title: Spring Boot Actuator
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring-boot, #actuator, #health, #metrics, #observability
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — every production Spring Boot application uses
Actuator. Interview questions cover health checks, Kubernetes integration,
and Micrometer metrics.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Boot Actuator provides production-ready endpoints for monitoring and
> managing applications. The key endpoints are: /actuator/health (liveness and
> readiness for Kubernetes), /actuator/metrics (application metrics via
> Micrometer), /actuator/info (application info), and /actuator/conditions
> (which auto-configurations fired). You configure which endpoints are enabled
> and exposed via application.properties.

**3 minutes (Senior):**
> Actuator endpoints serve three categories of operational needs. Health
> indicators compose into an aggregated health status (UP/DOWN). In Kubernetes,
> liveness and readiness are separate probes: liveness checks if the application
> should be restarted (OutOfMemoryError, deadlock), readiness checks if it
> should receive traffic (dependencies available, warm-up complete). Spring Boot
> 2.3+ exposes these as separate health groups.
>
> Metrics are exposed via Micrometer - a metrics facade that works with multiple
> backends: Prometheus, Datadog, CloudWatch, New Relic. @Timed, Counter, Gauge,
> DistributionSummary are the Micrometer types. Spring Boot auto-instruments
> JVM, HTTP server, database, and cache metrics out of the box.
>
> Security: the actuator endpoints are on the same server port by default but
> should be secured. In production, either restrict via Spring Security (require
> ADMIN role) or run actuator on a separate management port not exposed externally.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - custom HealthIndicator for external dependencies,
custom Micrometer meters for business metrics, distributed tracing with Micrometer
Tracing (formerly Sleuth).

*Adapting down:* Junior - "Actuator adds /health and /metrics URLs to your app.
/health tells Kubernetes if your app is running. /metrics shows performance data."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Boot Actuator - the operational
monitoring and management endpoints."

**(2) First principles:** "A production application needs visibility: is it healthy?
Is it performing well? How many requests per second? Actuator provides all of this
without you writing any code."

**(3) Bridge:** "Actuator is like the cockpit instruments in an airplane.
The /health endpoint is the engine status light. /metrics is the speedometer
and altimeter. You need these to fly safely."

---

### 📘 Concept Explanation

**What it is:**
Spring Boot Actuator provides built-in HTTP endpoints for production operational
concerns: health checks, metrics, application info, configuration diagnostics,
thread dumps, heap dumps, and more.

**The problem it solves:**
Production applications need health checking, metrics collection, and operational
visibility. Without Actuator, each team writes their own /health endpoint and
metrics integration. Actuator provides these as standardized, auto-configured
endpoints.

**How it works:**

```
Actuator endpoint architecture:

spring-boot-starter-actuator
  |
  v
ManagementContextAutoConfiguration
  - creates a sub-context for management endpoints
  - can be on separate port (management.server.port)

Endpoint discovery:
  - All @Endpoint beans discovered
  - Built-in endpoints: health, info, metrics, env,
    beans, conditions, loggers, threaddump, heapdump,
    scheduledtasks, httptrace, auditevents

Endpoint activation:
  management.endpoints.enabled-by-default=true
  management.endpoint.health.enabled=true
  management.endpoint.shutdown.enabled=false

Endpoint exposure (what is accessible via HTTP):
  management.endpoints.web.exposure.include=health,info
  management.endpoints.web.exposure.include=*  (all)

Health endpoint:
  HealthEndpoint
    -> CompositeHealthContributor
         -> DiskSpaceHealthIndicator (disk space)
         -> DataSourceHealthIndicator (database)
         -> RedisHealthIndicator (Redis if present)
         -> Custom HealthIndicator beans
    -> Aggregates: all UP -> UP; any DOWN -> DOWN

Kubernetes health groups (Spring Boot 2.3+):
  /actuator/health/liveness
    -> LivenessStateHealthIndicator
    -> Custom LivenessProbeHealthIndicator
  /actuator/health/readiness
    -> ReadinessStateHealthIndicator
    -> Custom ReadinessProbeHealthIndicator

Metrics (Micrometer):
  MeterRegistry (bound to Prometheus/Datadog/etc)
    -> JvmMetrics (heap, GC, threads)
    -> TomcatMetrics (connections, threads)
    -> HikariMetrics (connection pool)
    -> Custom meters (@Timed, Counter, Gauge)
  /actuator/metrics
  /actuator/metrics/http.server.requests
```

**The key insight:**
Liveness vs Readiness is the critical distinction for Kubernetes. Liveness
failing means "restart me, I'm broken internally". Readiness failing means
"remove me from the load balancer, I can't serve traffic right now (but may be
able to later)". Getting this wrong in Kubernetes causes restart loops (misusing
liveness) or serving traffic during startup (misusing readiness).

**When to use it:**
- All production Spring Boot applications - mandatory
- Kubernetes health probes: use health/liveness and health/readiness
- Prometheus scraping: expose /actuator/prometheus
- Operational debugging: /actuator/conditions, /actuator/beans, /actuator/env

**When NOT to use it:**
- Do not expose all endpoints publicly - restrict to management network
- Do not use /actuator/shutdown in production without auth (it shuts down the app)

**Alternatives:**
- Custom /health endpoint: more work with no benefit over Actuator
- Manual metrics: reinventing Micrometer

**First-principles derivation:**
Every production system needs visibility. A black-box application cannot be
operated reliably. Actuator provides the minimum operational interface as a
standardized, auto-configured set of endpoints, making Spring Boot applications
operationally ready without additional implementation.

---

### 💻 Code Example

```java
// application.properties - Actuator configuration
// Expose all endpoints (restrict via Security in production)
// management.endpoints.web.exposure.include=*

// Production: expose only health and info publicly
// management.endpoints.web.exposure.include=health,info

// Separate port for management (not externally exposed)
// management.server.port=8081

// Kubernetes health probes (Spring Boot 2.3+)
// management.endpoint.health.probes.enabled=true
// management.health.livenessstate.enabled=true
// management.health.readinessstate.enabled=true
```

```java
// Custom HealthIndicator for external dependency
@Component
public class PaymentServiceHealthIndicator
        implements HealthIndicator {

    private final PaymentServiceClient client;

    public PaymentServiceHealthIndicator(
            PaymentServiceClient client) {
        this.client = client;
    }

    @Override
    public Health health() {
        try {
            long start = System.currentTimeMillis();
            client.ping(); // lightweight health check call
            long latency = System.currentTimeMillis() - start;
            return Health.up()
                .withDetail("latencyMs", latency)
                .withDetail("status", "reachable")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .withDetail("status", "unreachable")
                .build();
        }
    }
}
```

> **Code walkthrough:** Custom HealthIndicator adds the payment service health
> to the aggregated /actuator/health response. If the payment service is DOWN,
> the application's overall health becomes DOWN (if it is a readiness indicator)
> or reports degraded state. The withDetail fields appear in the health response
> for operators to diagnose issues. Important: the ping() call should be
> lightweight - a simple connectivity check, not a full API call.

```java
// Custom Micrometer metrics
@Service
public class OrderService {

    private final Counter orderCreatedCounter;
    private final Counter orderFailedCounter;
    private final DistributionSummary orderAmountSummary;
    private final Timer orderProcessingTimer;

    public OrderService(MeterRegistry meterRegistry) {
        this.orderCreatedCounter = Counter
            .builder("orders.created")
            .description("Total orders created")
            .tag("app", "order-service")
            .register(meterRegistry);

        this.orderFailedCounter = Counter
            .builder("orders.failed")
            .register(meterRegistry);

        this.orderAmountSummary = DistributionSummary
            .builder("orders.amount")
            .baseUnit("dollars")
            .register(meterRegistry);

        this.orderProcessingTimer = Timer
            .builder("orders.processing.time")
            .register(meterRegistry);
    }

    public Order createOrder(OrderRequest req) {
        return orderProcessingTimer.record(() -> {
            try {
                Order order = doCreateOrder(req);
                orderCreatedCounter.increment();
                orderAmountSummary.record(
                    req.getTotal().doubleValue());
                return order;
            } catch (Exception e) {
                orderFailedCounter.increment();
                throw e;
            }
        });
    }
}
```

> **Code walkthrough:** Micrometer metrics are registered in the constructor
> and recorded in business methods. Counter tracks events (orders created/failed).
> DistributionSummary tracks value distribution (order amounts - min, max, mean,
> percentiles). Timer measures latency. All metrics are automatically exported to
> the configured backend (Prometheus, Datadog, etc.) without any export code in
> the service. Tags enable filtering in dashboards: `app="order-service"`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Actuator adds operational endpoints to Spring Boot apps. /health shows if
> the app is running (used by Kubernetes). /metrics shows performance data.
> /info shows application information. You enable/expose endpoints in
> application.properties. Always secure actuator endpoints in production -
> they can expose sensitive information.

*Push deeper:* Explain the difference between liveness and readiness probes
and why mixing them up causes Kubernetes restart loops.

---

**Senior / Staff (5+ years):**
> Actuator is the operational interface for Spring Boot applications. Key design
> decisions: separate management port from application port for security (never
> expose management endpoints on the public-facing port). Liveness vs readiness
> is critical for Kubernetes: liveness failing triggers pod restart (use for
> unrecoverable states: OOM, deadlock); readiness failing removes from load balancer
> without restarting (use for startup not-ready, dependency unavailable). Custom
> HealthIndicators for external dependencies should fail-fast with clear details
> and should not throw exceptions (catch and return DOWN with details). Micrometer
> is the standard for metrics - it abstracts the backend so you can switch from
> Prometheus to Datadog without changing code.

*Push deeper:* Micrometer Tracing (formerly Spring Cloud Sleuth) adds distributed
tracing with TraceId/SpanId propagation. Spring Boot 3 includes Micrometer Tracing
out of the box. Integration with Zipkin or Jaeger for trace visualization is
one configuration change.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Exposing all actuator endpoints is fine in development."**
/actuator/env exposes environment variables (including secrets). /actuator/heapdump
provides a heap dump (may contain sensitive data). /actuator/loggers allows
changing log levels at runtime. Development habits become production habits -
secure actuator endpoints from the start.

**Misconception 2: "Liveness DOWN means the application will not restart."**
In Kubernetes, a failing liveness probe triggers pod restart. If you mark
business-level issues (external service unavailable) as liveness failures,
you will cause restart loops - the app restarts but the external service is
still unavailable. Liveness should ONLY fail for unrecoverable internal states.

**Misconception 3: "/actuator/health down means the application is broken."**
DOWN health means any health indicator returned DOWN. A DOWN payment service
health indicator causes the whole /actuator/health to show DOWN. This is why
readiness (traffic routing) and liveness (restart) must be separate groups.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Kubernetes restart loop**
Symptom: Pod keeps restarting in CrashLoopBackOff; logs show the app starting
and stopping repeatedly.
Cause: Liveness probe mapped to an external dependency health check. The external
dependency is unavailable, liveness fails, Kubernetes restarts, repeat.
Fix: Move external dependency checks to readiness probe. Liveness should only
fail for unrecoverable states (OOM, deadlock, corrupted state).

**Failure 2: Metrics not showing in Prometheus**
Symptom: /actuator/prometheus returns empty or only JVM metrics.
Cause: Micrometer Prometheus dependency not on classpath, or actuator prometheus
endpoint not exposed.
Fix: Add micrometer-registry-prometheus dependency; add
management.endpoints.web.exposure.include=prometheus.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - What is Spring Boot Actuator and why do you use it?

Actuator provides production-ready operational endpoints for Spring Boot applications:
- Health checking (Kubernetes probes, monitoring systems)
- Metrics collection (JVM, HTTP, database, custom business metrics)
- Application diagnostics (/conditions, /beans, /env)
- Log level management (/loggers)
- Thread and heap dumps for debugging

Why use it: it provides the operational visibility every production application
needs, auto-configured with zero code. Replacing Actuator manually would require
implementing health endpoints, Prometheus integration, thread dump endpoints etc.

*What separates good from great:* Actuator uses the same MVC/WebFlux
infrastructure as your application. Its endpoints are regular Spring MVC
endpoints registered on a separate path (/actuator). This means Spring Security
can protect them normally.

---

#### Q2 - What is the difference between liveness and readiness in Kubernetes probes?

**Liveness probe** - should the container be restarted?
- Failing liveness: Kubernetes kills and restarts the container
- Use for: unrecoverable internal states (deadlock, OOM, corrupted state)
- Spring Boot endpoint: /actuator/health/liveness
- DO NOT include external dependency checks - will cause restart loop

**Readiness probe** - should the container receive traffic?
- Failing readiness: Kubernetes removes the container from the Service load balancer
- Container continues running - can recover and become ready
- Use for: startup warm-up, temporary dependency unavailability
- Spring Boot endpoint: /actuator/health/readiness
- INCLUDE external dependency checks here

Configure in application.properties:
```properties
management.endpoint.health.probes.enabled=true
management.health.livenessstate.enabled=true
management.health.readinessstate.enabled=true
```

*What separates good from great:* Custom ReadinessHealthIndicators allow
programmatic readiness control:
```java
ApplicationAvailability.setReadinessState(
    ReadinessState.REFUSING_TRAFFIC);
```
This is how graceful shutdown works - the app signals not-ready before
the server stops accepting connections.

---

#### Q3 - How do you secure Actuator endpoints?

Option 1 - Separate management port (best for production):
```properties
management.server.port=8081  # not exposed externally
```
No authentication needed - the port is only accessible internally.

Option 2 - Spring Security rules:
```java
@Bean
public SecurityFilterChain actuatorSecurity(
        HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/actuator/**")
        .authorizeHttpRequests(a -> a
            .requestMatchers("/actuator/health",
                "/actuator/info").permitAll()
            .anyRequest().hasRole("ADMIN"))
        .httpBasic(Customizer.withDefaults())
        .build();
}
```

Option 3 - Expose only safe endpoints:
```properties
management.endpoints.web.exposure.include=health,info
```
Minimize attack surface by only exposing needed endpoints.

*What separates good from great:* Production best practice: management port
on an internal network + Spring Security requiring ADMIN role. Defense in depth:
even if someone reaches the management port, they need valid credentials.

---

#### Q4 - How do you create a custom HealthIndicator?

Implement HealthIndicator and return Health.up() or Health.down() with details:

```java
@Component
public class ExternalServiceHealthIndicator
        implements HealthIndicator {

    private final ExternalServiceClient client;

    @Override
    public Health health() {
        try {
            // Lightweight connectivity check
            ResponseEntity<Void> response =
                client.ping();
            return Health.up()
                .withDetail("status",
                    response.getStatusCode())
                .build();
        } catch (Exception e) {
            return Health.down(e)
                .withDetail("error",
                    e.getMessage())
                .build();
        }
    }
}
```

For Kubernetes readiness (not liveness):
Implement ReadinessHealthIndicator to contribute only to /health/readiness.

*What separates good from great:* HealthIndicator.health() is called on every
health check request. Ensure it is fast (< 1 second) to avoid delaying
Kubernetes probes. For expensive checks, add caching: cache the result for
10 seconds. If the check itself fails with an exception after 5 seconds,
Kubernetes readiness timeout may fire before the check returns.

---

#### Q5 - What is Micrometer and how does it integrate with Actuator?

Micrometer is a metrics facade - a vendor-neutral API for recording metrics
that delegates to backend-specific implementations.

Supported backends: Prometheus, Datadog, New Relic, CloudWatch, Graphite,
Influx, Wavefront, and more.

Spring Boot auto-configures a MeterRegistry based on what's on the classpath.
Auto-instrumented metrics:
- JVM: heap, GC, threads, classes (JvmMetrics)
- HTTP server: request count, duration, errors (WebMvcMetrics)
- Database: HikariCP pool metrics (HikariMetrics)
- Cache: hit/miss/size (CacheMetrics)

Access in code:
```java
@Autowired MeterRegistry registry;

Counter.builder("my.counter").register(registry)
       .increment();
Gauge.builder("queue.size", queue, Queue::size)
     .register(registry);
```

*What separates good from great:* Micrometer's global registry
(Metrics.globalRegistry) allows recording metrics without injecting MeterRegistry.
But injecting MeterRegistry is cleaner and testable. For high-throughput code,
pre-build meters at construction time rather than looking them up by name on
each call - meter lookup is not free.

---

#### Q6 - How do you expose custom application info via Actuator?

/actuator/info exposes application information. Contribute via InfoContributor:

```java
@Component
public class AppInfoContributor
        implements InfoContributor {

    @Override
    public void contribute(Info.Builder builder) {
        builder.withDetail("app", Map.of(
            "name", "Order Service",
            "version", "2.1.0",
            "buildTime", Instant.now().toString()
        ));
    }
}
```

Or via application.properties:
```properties
management.info.env.enabled=true
info.app.name=Order Service
info.app.version=@project.version@  # Maven placeholder
info.app.description=Handles order processing
```

Git info (via spring-boot-maven-plugin):
```properties
management.info.git.enabled=true
management.info.git.mode=full  # includes branch, commit hash
```

*What separates good from great:* Including git commit hash in /actuator/info
is a crucial production practice. When an incident occurs, you immediately know
which commit is deployed. spring-boot-maven-plugin generates git.properties with
branch, commit ID, commit time, and dirty flag. Enable it with a few config lines.

---

#### Q7 - How do you use /actuator/loggers to change log levels at runtime?

/actuator/loggers lists current log levels. POST to change them:

```
# Get all loggers
GET /actuator/loggers

# Get specific logger
GET /actuator/loggers/com.example.orders

# Change to DEBUG at runtime (no restart!)
POST /actuator/loggers/com.example.orders
Content-Type: application/json
{"configuredLevel": "DEBUG"}

# Reset to default
POST /actuator/loggers/com.example.orders
{"configuredLevel": null}
```

This is critical for production debugging: enable DEBUG logging for a specific
package without restarting the application. After debugging, reset to INFO.

*What separates good from great:* Log level changes via /actuator/loggers are
in-memory only and lost on restart. For persistent changes in production, use
Spring Cloud Config Server which can push configuration changes to running
applications via /actuator/refresh (with @RefreshScope on the beans).

---

#### Q8 - What does /actuator/conditions show?

/actuator/conditions shows the Conditions Evaluation Report - exactly what
/debug output shows at startup, but accessible at runtime.

Response includes:
- **positiveMatches**: auto-configurations that fired, and which conditions matched
- **negativeMatches**: auto-configurations that did NOT fire, and which condition failed
- **unconditionalClasses**: classes loaded without conditions

Use cases:
- Verify that expected auto-configuration activated
- Debug why an expected auto-configuration did not fire
- Security audit: check what features are enabled in production

Example debug:
"Why doesn't my application use my custom DataSource?"
-> Check positiveMatches for DataSourceAutoConfiguration
-> ConditionalOnMissingBean: says a DataSource bean already exists (your bean)
-> Confirms your custom bean is being used

*What separates good from great:* /actuator/conditions is the most useful
debugging endpoint for Spring Boot issues. Before reading Spring Boot source
code to understand why something is or isn't configured, check /actuator/conditions.

---

#### Q9 - How do you add timing metrics to business methods with Micrometer?

Option 1 - @Timed annotation (requires AspectJ or Micrometer's aspect):
```java
@Service
public class OrderService {
    @Timed(value = "orders.create",
           description = "Order creation time",
           percentiles = {0.5, 0.95, 0.99})
    public Order createOrder(OrderRequest req) { ... }
}
```

Option 2 - Manual Timer (more control):
```java
@Service
public class OrderService {
    private final Timer createTimer;

    public OrderService(MeterRegistry registry) {
        this.createTimer = Timer
            .builder("orders.create")
            .tag("type", "manual")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(registry);
    }

    public Order createOrder(OrderRequest req) {
        return createTimer.record(
            () -> doCreateOrder(req));
    }
}
```

Option 3 - LongTaskTimer for long-running operations:
```java
LongTaskTimer batchTimer = LongTaskTimer
    .builder("batch.processing.active")
    .register(registry);

// Shows how long current batches have been running
batchTimer.record(() -> runBatch(items));
```

*What separates good from great:* Percentile metrics (p50, p95, p99) require
client-side aggregation (publishPercentiles) which uses more memory, or server-
side aggregation in Prometheus (publishPercentileHistogram). For Prometheus,
use publishPercentileHistogram=true and let Prometheus calculate percentiles with
histogram_quantile(). This scales better than pre-computing percentiles in-process.
