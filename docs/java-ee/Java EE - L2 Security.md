---
layout: default
title: "Java EE - L2 Security"
parent: "Java EE"
nav_order: 6
permalink: /java-ee/l2-security/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 14 | [Java EE Security Annotations](#java-ee-security-annotations) | ★★☆ |
| 15 | [JAAS Authentication](#jaas-authentication) | ★★☆ |

---

# Java EE Security Annotations

**Interview Weight:** ★★☆ - Working. Jakarta Security
annotations are the primary tool for declarative
authorization in Java EE. Every developer must know
how to apply and test them correctly.

---

### 🎯 Model Answer

**30 seconds:**

> Jakarta EE security annotations declare access control
> on EJB methods and JAX-RS resources. `@RolesAllowed`
> restricts access to named roles. `@PermitAll` allows
> any caller. `@DenyAll` blocks all access. `@RunAs`
> executes the component under a different security
> identity. The container enforces these using the
> SecurityContext set by the authentication mechanism
> (JWT filter, form-based login, Jakarta Security
> @HttpAuthenticationMechanism).

**3 minutes:**

> Jakarta EE security annotations work at two levels:
>
> Class-level (default for all methods):
> ```java
> @Path("/admin")
> @RolesAllowed("ADMIN")  // all methods require ADMIN
> public class AdminResource { ... }
> ```
>
> Method-level (overrides class-level):
> ```java
> @Path("/products")
> @PermitAll  // default: all methods open
> public class ProductResource {
>     @GET public Response list() {...}   // open
>
>     @POST
>     @RolesAllowed("CATALOG_MANAGER")   // requires role
>     public Response create(...) {...}
>
>     @DELETE
>     @DenyAll  // no one can call this
>     public Response deleteAll() {...}
> }
> ```
>
> Enforcement flow:
> 1. Auth mechanism populates SecurityContext with Principal + roles
> 2. Container checks SecurityContext.isUserInRole(role)
>    against @RolesAllowed before the method is called
> 3. Role check fails: 403 Forbidden (JAX-RS) or
>    EJBAccessException (EJB)
>
> `@RunAs("REPORT_SERVICE")`: makes all EJB calls from
> this component appear to come from the named role.
> Used for scheduled batch jobs that need elevated permissions.

**Blank Mind Recovery:**

**(1) Restate:** "@RolesAllowed = named roles. @PermitAll = everyone.
@DenyAll = nobody. @RunAs = run as different role."

**(2) First principles:** "Authorization = who can do what.
Annotations declare the policy; container enforces it."

**(3) Bridge:** "Spring equivalent: @PreAuthorize('hasRole(...)')
or @Secured('ROLE_ADMIN'). Jakarta EE uses simpler
names without the 'ROLE_' prefix."

---

### 📘 Concept Explanation

**What it is:**

Jakarta EE security annotations declaratively attach
authorization rules to components. The container checks
them at invocation time.

**The problem it solves:**

Without annotations: each method must manually check
the security context and throw exceptions:
```java
// Without annotations (error-prone, scattered)
public Order create(Order order) {
    if (!ctx.isCallerInRole("MANAGER")) {
        throw new ForbiddenException("Denied");
    }
    // business logic
}

// With annotations (clean)
@RolesAllowed("MANAGER")
public Order create(Order order) {
    // business logic only
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**@RolesAllowed with multiple roles (OR logic):**

```java
// Any one of the listed roles grants access
@RolesAllowed({"CUSTOMER", "ADMIN"})
public Response getOrder(@PathParam("id") Long id) {
    // CUSTOMER or ADMIN can call this
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Programmatic check alongside annotation:**

```java
@GET
@Path("/{id}")
@RolesAllowed({"CUSTOMER", "ADMIN"})
public Response getOrder(
    @PathParam("id") Long id,
    @Context SecurityContext sc
) {
    // Container already checked role via @RolesAllowed
    // Additional fine-grained check:
    if (sc.isUserInRole("ADMIN")) {
        // Admin sees all orders
        return Response.ok(adminService.findById(id)).build();
    }
    // Customer sees only their own orders
    String user = sc.getUserPrincipal().getName();
    return orderService.findByIdForUser(id, user)
        .map(o -> Response.ok(o).build())
        .orElse(Response.status(403).build());
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// Production: layered security annotations

@Path("/orders")
@RequestScoped
@Produces(MediaType.APPLICATION_JSON)
public class OrderResource {

    @Inject private OrderService orderService;

    // Public browse: no authentication required
    @GET
    @PermitAll
    public Response list(
        @QueryParam("status") String status
    ) {
        return Response.ok(
            orderService.findPublic(status)
        ).build();
    }

    // Role check: CUSTOMER or ADMIN
    @GET
    @Path("/{id}")
    @RolesAllowed({"CUSTOMER", "ADMIN"})
    public Response getOrder(
        @PathParam("id") Long id,
        @Context SecurityContext sc
    ) {
        String user = sc.getUserPrincipal().getName();
        if (sc.isUserInRole("ADMIN")) {
            return Response.ok(
                orderService.findById(id)
            ).build();
        }
        return orderService.findByIdForUser(id, user)
            .map(o -> Response.ok(o).build())
            .orElse(Response.status(403).build());
    }

    // Only CUSTOMER
    @POST
    @RolesAllowed("CUSTOMER")
    public Response create(
        @Valid CreateOrderRequest req,
        @Context SecurityContext sc
    ) {
        String user = sc.getUserPrincipal().getName();
        Order order = orderService.create(req, user);
        return Response.status(201).entity(order).build();
    }

    // Admin only
    @DELETE
    @Path("/{id}")
    @RolesAllowed("ADMIN")
    public Response cancel(@PathParam("id") Long id) {
        orderService.cancel(id);
        return Response.noContent().build();
    }

    // Kill switch: nobody can call this
    @DELETE
    @DenyAll
    public Response deleteAll() {
        return Response.status(403).build();
    }
}

// @RunAs: scheduled job runs as privileged role
@Singleton
@RunAs("REPORT_SERVICE")
public class ScheduledReports {

    @Inject private AdminReportService adminReports;

    @Schedule(hour = "2", minute = "0",
              persistent = false)
    public void nightlyReport() {
        // This method and all EJB calls it makes
        // are executed as "REPORT_SERVICE"
        // adminReports.generate() has @RolesAllowed("REPORT_SERVICE")
        adminReports.generate();
    }
}

// EJB service with @DeclareRoles
@Stateless
@DeclareRoles({"ADMIN", "CUSTOMER", "REPORT_SERVICE"})
public class OrderService {

    @RolesAllowed("ADMIN")
    public void deleteAll() { /* admin only */ }

    @RolesAllowed({"ADMIN", "CUSTOMER"})
    public java.util.Optional<Order> findById(Long id) {
        return java.util.Optional.empty();
    }

    @PermitAll
    public java.util.List<Order> findPublic(String s) {
        return java.util.Collections.emptyList();
    }

    // For programmatic checks inside a method:
    @Resource
    private SessionContext ctx;

    @PermitAll
    public void someMethod() {
        if (ctx.isCallerInRole("ADMIN")) {
            // extra behavior for admins
        }
    }
}
```

> **Code walkthrough:** Three layers of security annotation
> usage in a production pattern. The `OrderResource`
> shows mixed annotation levels: `@PermitAll` on list
> allows unauthenticated browsing; `getOrder` with
> `@RolesAllowed({"CUSTOMER", "ADMIN"})` allows either
> role (OR logic). Inside `getOrder`, the programmatic
> `sc.isUserInRole("ADMIN")` adds fine-grained business
> logic: admins see all, customers see only their own.
> `@DenyAll` on `deleteAll()` is a deliberate kill switch -
> nobody can call it until the annotation is removed.
> `@RunAs` on `ScheduledReports` is the privilege elevation
> pattern: the server's scheduler runs as no role, but
> `@RunAs("REPORT_SERVICE")` makes all downstream EJB
> calls appear to come from that role. `@DeclareRoles`
> on the service declares what roles the bean references
> programmatically via `isCallerInRole()`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "@RolesAllowed restricts a method to users with the
> specified role. @PermitAll allows everyone. @DenyAll
> blocks everyone. The container checks the caller's
> SecurityContext against the annotation and throws
> an exception (403 or EJBAccessException) if the role
> check fails. Use @Context SecurityContext for programmatic
> role checks inside the method."

---

**Senior / Staff:**

> "The annotation model is declarative and auditable:
> a code review shows exactly which roles access which
> endpoints. The limitation: it's RBAC only. 'CUSTOMER
> can only access their own orders' cannot be expressed
> purely with annotations - that needs programmatic checks
> or an ABAC policy engine. For complex authorization
> (ownership, multi-tenant, ABAC), use OPA called from
> a JAX-RS ContainerRequestFilter or CDI interceptor.
> The annotations handle 90% of cases; programmatic
> handles the rest. Also: always include a negative test
> that verifies unauthorized users get 403, not just
> that authorized users get 200."

---

### ⚠️ Common Misconceptions

**Misconception: "@RolesAllowed automatically returns
401 for unauthenticated users."**

`@RolesAllowed` checks roles, not authentication status.
For unauthenticated users (no Principal), many
containers return 403 (Forbidden), not 401 (Unauthorized).
The correct HTTP response for unauthenticated requests
is 401 with a `WWW-Authenticate` header. A
`ContainerRequestFilter` with `@Priority(AUTHENTICATION)`
should check for missing credentials and return 401
before the resource method is called. The 401 vs 403
distinction matters: 401 tells the client "authenticate
first"; 403 tells the client "authenticated but no
permission". Clients that auto-retry on 401 will loop
forever on 403.

---

### 🚨 Failure Modes and Diagnosis

**Failure: @RolesAllowed ignored - all calls succeed**

*Symptom:* Users with no roles can call methods
annotated @RolesAllowed("ADMIN"). No 403 is returned.

*Root cause:*
1. JAX-RS role-based security not enabled
   (RESTEasy: `resteasy.role.based.security=true` missing)
2. SecurityContext not populated (auth filter not running)
3. @PermitAll at class level overrides method @RolesAllowed
   in some JAX-RS implementations

*Diagnosis:*
```bash
# Test with no credentials - should get 401 or 403:
curl -v http://localhost:8080/api/admin/users

# Test with wrong role - should get 403:
curl -v -H "Authorization: Bearer <customer-token>" \
  http://localhost:8080/api/admin/users

# If both return 200: authorization is not working
# Check if auth filter is registered:
grep -r "ContainerRequestFilter\|@Provider" \
  src/main/java/
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```xml
<!-- web.xml: enable role-based security for RESTEasy -->
<context-param>
  <param-name>
    resteasy.role.based.security
  </param-name>
  <param-value>true</param-value>
</context-param>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| @RolesAllowed vs @PermitAll vs @DenyAll | 2-3 min |
| 401 vs 403 semantics | 2-3 min |
| Programmatic security checks | 2-3 min |
| @RunAs use case | 3 min |
| SecurityContext population | 3-4 min |
| @DeclareRoles purpose | 2 min |
| RBAC vs ABAC | 3 min |
| Testing secured endpoints | 3 min |
| Security misconfiguration risks | 3-4 min |

---

**[MID] Q1 - What is the difference between
401 and 403 HTTP status codes?**

*Why they ask:* HTTP security semantics.

401 Unauthorized: the request lacks valid authentication.
"I don't know who you are - authenticate first."
MUST include `WWW-Authenticate` header per HTTP spec.

403 Forbidden: authenticated but lacking permission.
"I know who you are, and you're not allowed."

```java
@Provider
@Priority(Priorities.AUTHENTICATION)
public class AuthFilter implements ContainerRequestFilter {
    @Override
    public void filter(ContainerRequestContext ctx) {
        String auth = ctx.getHeaderString("Authorization");
        if (auth == null) {
            // No credentials: 401 with WWW-Authenticate
            ctx.abortWith(Response.status(401)
                .header("WWW-Authenticate",
                    "Bearer realm=\"api\"")
                .entity(Map.of("error",
                    "Authentication required"))
                .build());
            return;
        }
        // Invalid token: also 401
        // Authenticated but wrong role: 403 (from @RolesAllowed)
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Some APIs return 404 (Not Found) for unauthorized access to sensitive resources: this avoids revealing the endpoint exists to unauthenticated attackers. The trade-off: developer experience vs security. For internal APIs, use 401/403 correctly. For public APIs with sensitive resources, consider 404."

---

**[MID] Q2 - How does @RolesAllowed work differently
on EJBs vs JAX-RS resources?**

*Why they ask:* Container enforcement details.

On EJB:
- Container intercepts at the proxy layer
- Checks JAAS/Elytron security context for role
- Throws `EJBAccessException` if check fails
- Works for both local and remote EJB calls

On JAX-RS (RESTEasy):
- Runtime checks `@RolesAllowed` via SecurityContext
- Returns 403 if check fails
- Requires explicit enable: `resteasy.role.based.security=true`
  in web.xml (NOT required for EJB)

Without `resteasy.role.based.security=true`:
```
@RolesAllowed("ADMIN") on JAX-RS resource method
-> annotation is SILENTLY IGNORED
-> all callers get 200 regardless of role
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This is a common security misconfiguration in JAX-RS
applications on WildFly/RESTEasy.

*What separates good from great:* "The silent ignore behavior is dangerous: the application appears to work correctly in development (where everyone has admin roles) but is fully open in production. Always include a negative test: verify a caller WITHOUT the required role gets 403."

---

**[MID] Q3 - How do you test @RolesAllowed endpoints?**

*Why they ask:* Security testing approach.

Two test approaches:

Integration test (preferred):
```java
@QuarkusTest
class OrderResourceSecurityTest {
    @Test
    void adminCanDeleteOrder() {
        given()
            .auth().oauth2(getAdminToken())
        .when()
            .delete("/api/orders/1")
        .then()
            .statusCode(204);
    }

    @Test
    void customerCannotDeleteOrder() {
        given()
            .auth().oauth2(getCustomerToken())
        .when()
            .delete("/api/orders/1")
        .then()
            .statusCode(403); // VERIFY NEGATIVE CASE
    }

    @Test
    void unauthenticatedGets401() {
        given()
        .when()
            .delete("/api/orders/1")
        .then()
            .statusCode(401); // VERIFY NO CREDENTIALS
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Unit test with mocked SecurityContext:
```java
@Test
void adminSeesAllOrders() {
    SecurityContext sc = mock(SecurityContext.class);
    when(sc.isUserInRole("ADMIN")).thenReturn(true);
    when(sc.getUserPrincipal()).thenReturn(() -> "admin");

    Response resp = resource.getOrder(42L, sc);
    assertEquals(200, resp.getStatus());
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "The negative test is mandatory. Without it, you verify the happy path but not the access control. Automated security scanners (OWASP ZAP) will catch missing authentication checks, but only if they're in the test scope."

---

**[MID] Q4 - How does method-level annotation
relate to class-level annotation?**

*Why they ask:* Annotation precedence.

Method-level annotations override class-level:

```java
@Path("/orders")
@RolesAllowed("ADMIN")  // class-level default
public class OrderResource {

    @GET  // inherits @RolesAllowed("ADMIN")
    public Response list() { ... }

    @POST
    @RolesAllowed("MANAGER")  // overrides class-level
    public Response create() { ... }

    @DELETE
    @PermitAll  // overrides: anyone can delete?! Bug!
    public Response delete() { ... }

    @GET
    @Path("/internal")
    @DenyAll  // overrides: completely blocked
    public Response internalOnly() { ... }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Rule: the most specific annotation wins.
Method-level > Class-level.

Common bug: class-level @PermitAll with method-level
@RolesAllowed may not work as expected in all
JAX-RS implementations. Test explicitly.

*What separates good from great:* "I prefer to be explicit at the method level rather than relying on class-level defaults. Class-level @RolesAllowed with method-level overrides means a new method added to the class needs a specific override - if someone adds a method without an annotation, it silently inherits the class-level rule. Explicit method annotations are self-documenting and harder to accidentally misconfigure."

---

**[SENIOR] Q5 - How does Jakarta Security differ
from traditional JAAS security domains?**

*Why they ask:* Modern vs legacy security APIs.

Traditional JAAS: server-configured security domains,
LoginModules, no CDI injection.

Jakarta Security (Jakarta EE 8+): CDI-based, portable,
annotation-driven:

```java
// Jakarta Security: define auth mechanism (CDI bean)
@ApplicationScoped
public class JwtAuthMechanism
        implements HttpAuthenticationMechanism {

    @Inject JwtValidator validator; // CDI injection!
    @Inject UserRepository users;

    @Override
    public AuthenticationStatus validateRequest(
        HttpServletRequest req,
        HttpServletResponse resp,
        HttpMessageContext ctx
    ) {
        String token = extractToken(req);
        if (token == null)
            return ctx.responseUnauthorized();
        try {
            JwtClaims claims = validator.validate(token);
            return ctx.notifyContainerAboutLogin(
                claims.getSubject(),
                new HashSet<>(claims.getRoles())
            );
        } catch (Exception e) {
            return ctx.responseUnauthorized();
        }
    }
}

// Define identity store (validates credentials)
@ApplicationScoped
@DatabaseIdentityStoreDefinition(
    dataSourceLookup = "java:/app/UserDS",
    callerQuery = "SELECT pwd FROM users WHERE name=?",
    groupsQuery = "SELECT role FROM user_roles WHERE name=?"
)
public class AppConfig { }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

JAAS LoginModule cannot use CDI injection.
Jakarta Security @HttpAuthenticationMechanism can.

*What separates good from great:* "For new Jakarta EE 8+ applications, always use Jakarta Security. The main remaining JAAS use case: you need the app server's security domain to be shared across multiple applications (deployed as separate WARs under one EAR). Jakarta Security is per-application."

---

**[SENIOR] Q6 - How do you implement RBAC vs ABAC?**

*Why they ask:* Authorization model design.

RBAC (Role-Based Access Control): access determined by roles.
Expressible with @RolesAllowed.

ABAC (Attribute-Based Access Control): access determined
by user, resource, and environment attributes.
Cannot be expressed with @RolesAllowed alone.

ABAC example: "user can only modify orders they own":
```java
@Provider
@Priority(Priorities.AUTHORIZATION)
@Owned  // @NameBinding - applies to @Owned endpoints
public class OwnershipFilter
        implements ContainerRequestFilter {

    @Context SecurityContext sc;
    @Inject OrderRepository orders;

    @Override
    public void filter(ContainerRequestContext ctx) {
        String id = ctx.getUriInfo()
            .getPathParameters().getFirst("id");
        if (id == null) return;

        String caller = sc.getUserPrincipal().getName();
        boolean isAdmin = sc.isUserInRole("ADMIN");
        if (isAdmin) return; // admins bypass ownership

        Order order = orders.findById(Long.parseLong(id));
        if (order == null ||
                !caller.equals(order.getOwner())) {
            ctx.abortWith(Response.status(403).build());
        }
    }
}

// Apply to specific resource method
@PUT
@Path("/{id}")
@Owned  // triggers OwnershipFilter
@RolesAllowed({"CUSTOMER", "ADMIN"})
public Response update(
    @PathParam("id") Long id,
    UpdateRequest req
) { ... }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

For complex ABAC (multi-tenant, time-based, geo-based):
use OPA (Open Policy Agent) or similar policy engine.

*What separates good from great:* "OPA decouples policy from code: security team writes Rego policies, developers call the OPA API. Policy changes don't require code deployment. The JAX-RS filter is just an OPA client that passes request context (user, method, path, resource attributes) and gets allow/deny back."

---

**[SENIOR] Q7 - What are the most common Jakarta
EE security misconfigurations?**

*Why they ask:* Security hardening knowledge.

Top misconfigurations:

1. `@RolesAllowed` not enforced on JAX-RS (RESTEasy):
   Missing `resteasy.role.based.security=true` in web.xml.
   All callers get access. Silent failure.

2. JWT validation skipping signature or expiration:
   ```java
   // BAD: only decodes, no verification
   JwtClaims claims = JwtClaims.parse(token);
   // Attacker creates any token they want

   // GOOD: full validation
   JwtConsumer jwtConsumer = new JwtConsumerBuilder()
       .setVerificationKey(publicKey)
       .setRequireExpirationTime()
       .setExpectedAudience("my-api")
       .setExpectedIssuer("https://auth.example.com")
       .build();
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. 401 response missing `WWW-Authenticate` header.
   Clients that follow the HTTP spec won't retry auth.

4. `@RunAs` with overly broad roles:
   `@RunAs("ADMIN")` on a scheduled job means the
   job can call any admin endpoint. Use specific
   purpose-built roles.

5. No negative test: only testing happy path.
   No test that verifies 403 for unauthorized users.

*What separates good from great:* "The silent @RolesAllowed misconfiguration is the most dangerous. Automated security testing (OWASP ZAP in CI pipeline) catches it: it tests each endpoint without credentials and with wrong-role credentials, flagging 200 responses where 401/403 is expected."

---

**[SENIOR] Q8 - How do you implement JWT-based
authentication in Jakarta EE?**

*Why they ask:* Modern auth implementation.

JWT ContainerRequestFilter:
```java
@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthFilter implements ContainerRequestFilter {

    @Inject JwtValidator jwtValidator;

    private static final Set<String> PUBLIC = Set.of(
        "/auth/login", "/health", "/metrics"
    );

    @Override
    public void filter(ContainerRequestContext ctx) {
        String path = ctx.getUriInfo().getPath();
        if (PUBLIC.stream().anyMatch(path::startsWith))
            return;

        String auth = ctx.getHeaderString("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            ctx.abortWith(Response.status(401)
                .header("WWW-Authenticate",
                    "Bearer realm=\"api\"")
                .build());
            return;
        }

        String token = auth.substring(7);
        try {
            JwtClaims claims = jwtValidator.validate(token);
            String subject = claims.getSubject();
            Set<String> roles = Set.copyOf(
                claims.getRoles()
            );
            // Set SecurityContext for @RolesAllowed checks
            ctx.setSecurityContext(new SecurityContext() {
                public Principal getUserPrincipal() {
                    return () -> subject;
                }
                public boolean isUserInRole(String role) {
                    return roles.contains(role);
                }
                public boolean isSecure() { return true; }
                public String getAuthenticationScheme() {
                    return "Bearer";
                }
            });
        } catch (Exception e) {
            ctx.abortWith(Response.status(401)
                .entity(Map.of("error",
                    "Invalid or expired token"))
                .build());
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

JWT validation must check:
- Signature (with correct public key)
- Expiration (exp claim)
- Audience (aud claim - for this API only)
- Issuer (iss claim)

*What separates good from great:* "Skipping audience validation enables token confusion attacks: a JWT issued for service A is reused for service B. Both have the same issuer and signing key, so the signature is valid - but the token was not intended for service B. setExpectedAudience('service-b-api') prevents this."

---

**[SENIOR] Q9 - How do you audit security events
in Jakarta EE?**

*Why they ask:* Security observability requirements.

Security events to capture:
- Auth failures (401): failed login attempt
- Auth errors (403): privilege escalation attempt
- Sensitive operations: payment, data export, role change

```java
@Provider
@Priority(Priorities.AUTHENTICATION + 50)
public class SecurityAuditFilter
        implements ContainerRequestFilter,
                   ContainerResponseFilter {

    @Inject AuditService auditService;

    @Override
    public void filter(ContainerRequestContext req) {
        req.setProperty("req.start",
            System.currentTimeMillis());
    }

    @Override
    public void filter(
        ContainerRequestContext req,
        ContainerResponseContext resp
    ) {
        int status = resp.getStatus();
        if (status == 401 || status == 403) {
            Principal p = req.getSecurityContext()
                .getUserPrincipal();
            auditService.log(AuditEvent.of(
                status == 401 ? "AUTH_FAILURE" :
                                "AUTHZ_FAILURE",
                p != null ? p.getName() : "anonymous",
                req.getMethod() + " " +
                    req.getUriInfo().getPath(),
                req.getHeaderString("X-Forwarded-For")
            ));
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Audit log mandatory fields:
- Who (user identity or "anonymous")
- What (method + path)
- When (UTC timestamp)
- From where (IP, X-Forwarded-For)
- Result (HTTP status)
- Correlation ID

*What separates good from great:* "Audit logs must be written to an append-only store separate from application logs. Application logs can be rotated, deleted, or modified. Audit logs are evidence. Never log credentials, tokens, or PII in audit logs."

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# JAAS Authentication

**Interview Weight:** ★★☆ - Working. JAAS is the
underlying authentication framework in Java EE.
Understanding LoginModules, Subjects, Principals,
and the two-phase commit is required for implementing
custom authentication and debugging auth failures.

---

### 🎯 Model Answer

**30 seconds:**

> JAAS (Java Authentication and Authorization Service)
> is Java's pluggable authentication framework. A
> `LoginModule` verifies credentials and populates
> a `Subject` with Principals. The `LoginContext`
> orchestrates a chain of LoginModules using control
> flags (REQUIRED, SUFFICIENT, OPTIONAL, REQUISITE).
> The two-phase commit (login then commit) ensures
> atomicity: Principals are only added to the Subject
> if all REQUIRED modules succeed.

**3 minutes:**

> JAAS key concepts:
>
> - **Subject**: the authenticated entity. Contains
>   Principals (identities) and credentials.
> - **Principal**: a named identity (username, role,
>   LDAP group DN).
> - **LoginModule**: performs actual authentication.
>   Configurable without code changes.
> - **LoginContext**: orchestrates the chain.
>
> Two-phase commit:
> 1. `login()`: each module validates credentials.
>    Records result but doesn't modify Subject.
> 2. `commit()`: all REQUIRED modules succeeded
>    -> each module adds Principals to Subject.
>    `abort()`: any REQUIRED module failed
>    -> all modules clear temp state; Subject unchanged.
>
> Control flags:
> - REQUIRED: must succeed; chain continues regardless
> - REQUISITE: must succeed; chain stops immediately on failure
> - SUFFICIENT: if success, chain stops and overall succeeds
> - OPTIONAL: doesn't affect overall outcome

**Blank Mind Recovery:**

**(1) Restate:** "Subject = authenticated entity. Principal = identity.
LoginModule = verifier. REQUIRED/OPTIONAL/SUFFICIENT = flags.
Two phases: login() then commit()."

**(2) First principles:** "Pluggable authentication: swap the
auth mechanism without changing application code.
Two-phase ensures atomicity: no partial Principal sets."

**(3) Bridge:** "Similar to Spring Security's AuthenticationProvider
chain. Each provider tries to authenticate;
control flags determine how failures propagate."

---

### 📘 Concept Explanation

**What it is:**

JAAS separates authentication policy (which LoginModules
to use, with what control flags) from authentication
mechanism (how each module validates credentials).

**The problem it solves:**

Hard-coded authentication is not portable: check username/
password against a database is specific to that database
schema. JAAS allows swapping authentication backend
(database -> LDAP -> custom) via configuration, not code.

**Two-phase commit guarantees atomicity:**

```
Phase 1: login() calls

  Module 1 (REQUIRED): validates password -> OK
    Stores: username, roles in temp variables
    Returns: true (does NOT add to Subject yet)

  Module 2 (OPTIONAL): validates LDAP groups -> OK
    Stores: additional groups in temp variables
    Returns: true

All REQUIRED modules succeeded:

Phase 2: commit() calls

  Module 1: commit()
    Moves: username, roles -> Subject.getPrincipals()
  Module 2: commit()
    Moves: additional groups -> Subject.getPrincipals()

Subject now has all Principals from all modules.

If Module 2 had FAILED (but is OPTIONAL):
  Overall auth still succeeds
  Module 2: abort() -> clears temp variables
  Module 1: commit() -> adds its Principals
  Subject has Module 1's Principals only (no LDAP groups)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// Custom LoginModule: JWT validation

public class JwtLoginModule implements LoginModule {

    private Subject subject;
    private CallbackHandler callbackHandler;
    private String jwtToken;
    private final List<Principal> principals =
        new ArrayList<>();
    private boolean loginOk = false;

    @Override
    public void initialize(
        Subject subject,
        CallbackHandler callbackHandler,
        Map<String, ?> sharedState,
        Map<String, ?> options
    ) {
        this.subject = subject;
        this.callbackHandler = callbackHandler;
    }

    @Override
    public boolean login() throws LoginException {
        // Request token via PasswordCallback
        PasswordCallback pc =
            new PasswordCallback("Bearer Token:", false);
        try {
            callbackHandler.handle(new Callback[]{pc});
        } catch (Exception e) {
            throw new LoginException(
                "Callback failed: " + e.getMessage()
            );
        }

        jwtToken = new String(pc.getPassword());
        pc.clearPassword(); // clear from memory immediately

        try {
            validateToken(jwtToken); // throws if invalid
        } catch (Exception e) {
            throw new FailedLoginException(
                "Invalid token: " + e.getMessage()
            );
        }

        loginOk = true;
        return true;
        // Note: Subject NOT modified yet (two-phase)
    }

    @Override
    public boolean commit() throws LoginException {
        if (!loginOk) return false;

        // Now add Principals to Subject
        String sub = extractSubject(jwtToken);
        List<String> roles = extractRoles(jwtToken);

        principals.add(new CallerPrincipal(sub));
        roles.stream()
            .map(RolePrincipal::new)
            .forEach(principals::add);

        subject.getPrincipals().addAll(principals);
        return true;
    }

    @Override
    public boolean abort() throws LoginException {
        // login() called but overall chain failed
        loginOk = false;
        principals.clear();
        jwtToken = null; // clear sensitive data
        return true;
    }

    @Override
    public boolean logout() throws LoginException {
        subject.getPrincipals().removeAll(principals);
        principals.clear();
        return true;
    }

    private void validateToken(String token)
            throws Exception {
        // In production: use Nimbus JOSE+JWT or similar
        // Check: signature, expiration, audience, issuer
        if (token == null || token.length() < 10) {
            throw new IllegalArgumentException(
                "Token too short"
            );
        }
    }

    private String extractSubject(String t) {
        return "user@example.com"; // parse from JWT
    }

    private List<String> extractRoles(String t) {
        return List.of("CUSTOMER"); // parse from JWT claims
    }
}

// Standalone JAAS usage (for testing):
void demonstrateJaasLogin() throws LoginException {
    Subject subject = new Subject();

    // CallbackHandler provides credentials
    CallbackHandler handler = callbacks -> {
        for (Callback cb : callbacks) {
            if (cb instanceof PasswordCallback) {
                ((PasswordCallback) cb).setPassword(
                    "eyJhbGciOiJSUzI1NiJ9...".toCharArray()
                );
            }
        }
    };

    // Configuration: use JwtLoginModule as REQUIRED
    LoginContext lc = new LoginContext(
        "JwtRealm", subject, handler
    );
    lc.login(); // runs login() then commit()

    // Subject now has Principals
    subject.getPrincipals().forEach(p ->
        System.out.println("Principal: " + p.getName())
    );
}
```

> **Code walkthrough:** A JAAS LoginModule for JWT
> validation showing the two-phase commit protocol in
> full detail. The `login()` method validates the token
> but does NOT modify the Subject - it only sets
> `loginOk = true` and stores parsed data in `principals`
> (a temporary list). The `commit()` method transfers
> those temporary Principals into the Subject. If any
> REQUIRED module in the chain fails and `abort()` is
> called, `principals.clear()` ensures the temp state
> is discarded and the Subject remains unchanged.
> `pc.clearPassword()` in login() zeros the password
> array immediately after use - JWT tokens in memory
> are a security risk if heap dumps are taken.
> The `validateToken()` stub must check: signature,
> expiration (`exp`), audience (`aud`), and issuer (`iss`).
> Skipping any of these is a security vulnerability.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "JAAS is Java's authentication framework. A LoginModule
> validates credentials and adds Principals (user identity,
> roles) to a Subject. Multiple LoginModules are chained
> with control flags (REQUIRED, OPTIONAL, SUFFICIENT).
> The two-phase commit ensures the Subject is only modified
> if all REQUIRED modules succeed. In Java EE app servers,
> security domains are configured with LoginModules
> that authenticate against databases, LDAP, or custom stores."

---

**Senior / Staff:**

> "JAAS is intentionally pluggable: swap the authentication
> backend via configuration without changing application
> code. The two-phase commit is the key design: login()
> votes, commit() applies. This ensures no partial Principal
> sets if a module in the chain fails. The limitation:
> JAAS LoginModules cannot use CDI injection (they're
> initialized before CDI). For new Jakarta EE 8+ applications,
> Jakarta Security @HttpAuthenticationMechanism is the
> right API: CDI-based, injectable, testable. JAAS is
> how the underlying app server mechanisms work internally,
> and understanding it is essential for debugging auth
> failures in legacy WildFly/JBoss applications."

---

### ⚠️ Common Misconceptions

**Misconception: "REQUIRED means authentication fails
immediately if this module fails."**

`REQUIRED` means the module's result is required for
overall success, but authentication continues executing
all other modules in the chain regardless of this
module's result. The overall outcome is evaluated
after all modules run. `REQUISITE` is the flag that
stops the chain immediately on failure. The distinction
matters when modules have side effects: with REQUIRED,
all modules run (and log) even on failure; with REQUISITE,
only modules before the failing one run.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JAAS authentication always fails despite
correct credentials**

*Symptom:* All login attempts return 401. FailedLoginException
even with known good credentials.

*Root cause:*
1. Password hash mismatch: application hashes with
   bcrypt; LoginModule hashes with MD5.
2. Username case sensitivity: stored as lowercase;
   user entered mixed case.
3. JNDI datasource lookup fails in LoginModule options.
4. Security domain misconfiguration.

*Diagnosis:*
```bash
# Enable JAAS debug logging (WildFly):
/subsystem=logging/logger=org.jboss.security\
:add(level=TRACE)

# Check exact error in logs:
grep "FailedLoginException\|password\|LoginModule" \
  standalone/log/server.log | tail -50

# Test database query manually:
SELECT password FROM users WHERE username = 'testuser';
# Then verify the hash matches what LoginModule computes
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Match the password hashing algorithm between
the LoginModule (`hashAlgorithm` option) and the
user registration flow. Test with a known hash:
create a test user via the application, extract the
stored hash, and verify the LoginModule produces
the same hash for the same input password.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| JAAS two-phase commit | 3-4 min |
| Control flags semantics | 3-4 min |
| Custom LoginModule implementation | 4-5 min |
| Subject and Principal | 2-3 min |
| JAAS vs Jakarta Security | 3-4 min |
| CallbackHandler pattern | 2-3 min |
| Security domain configuration | 2-3 min |
| JAAS debugging | 3 min |
| Security risks in LoginModules | 3-4 min |

---

**[MID] Q1 - What is the purpose of the two-phase
commit in JAAS?**

*Why they ask:* Protocol understanding.

Phase 1 (login): each module validates credentials
and records its result, but doesn't modify the Subject.

Phase 2 (commit or abort):
- All REQUIRED modules succeeded: `commit()` on all
  -> each module adds Principals to Subject
- Any REQUIRED module failed: `abort()` on all
  -> all modules clear temp state; Subject unchanged

Without two phases: Module 1 adds Principal A.
Module 2 fails. Subject has partial state - authenticated
as "A" but missing roles from Module 2. The abort
phase prevents this.

```
1. login() on Module 1: password valid -> true
2. login() on Module 2: LDAP group check -> FAIL

-> abort() called on all modules
-> Module 1 clears: principals list, loginOk flag
-> Subject: unmodified (no Principals added)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "The key implementation requirement: modules must store Principals in a temporary list during login() and only move them to Subject.getPrincipals() in commit(). Modules that add directly to Subject during login() break the protocol and create inconsistent state when abort() is called."

---

**[MID] Q2 - What are the four JAAS control flags?**

*Why they ask:* JAAS configuration knowledge.

REQUIRED:
- Must succeed for overall auth to succeed
- Chain continues to all other modules regardless
- Common for core auth modules

REQUISITE:
- Must succeed; chain STOPS immediately on failure
- Use when immediate abort on failure is needed
  (e.g., account lock check - no point checking password)

SUFFICIENT:
- If SUCCESS: chain stops, overall auth succeeds
- If FAIL: continue to other modules
- Use for alternative auth methods
  (JWT token OR username/password)

OPTIONAL:
- Result doesn't affect overall outcome
  (unless ALL modules are OPTIONAL and all fail)
- Use for supplemental enrichment (add extra roles)

```
Security domain chain:
  Module 1: AccountLock (REQUISITE)
  -> account locked? abort immediately
  Module 2: PasswordCheck (REQUIRED)
  -> must validate credentials
  Module 3: LdapGroups (OPTIONAL)
  -> add extra groups if available, OK if not
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "SUFFICIENT enables fallback authentication: try JWT first (SUFFICIENT) - if valid, skip password check. If absent, fall through to username/password (REQUIRED). The client only sends one type of credential; the chain handles both. This is how enterprise SSO + local auth coexistence works."

---

**[MID] Q3 - What is a CallbackHandler and why
does JAAS use it?**

*Why they ask:* JAAS decoupling design.

CallbackHandler decouples the LoginModule from the
credential source. The LoginModule requests what
it needs via Callback objects; the handler provides them.

```java
// LoginModule requests credentials:
NameCallback nc = new NameCallback("username:");
PasswordCallback pc =
    new PasswordCallback("password:", false);
callbackHandler.handle(new Callback[]{nc, pc});
String username = nc.getName();
char[] password = pc.getPassword();

// CallbackHandler in web context:
public class FormCallbackHandler
        implements CallbackHandler {
    private final String username;
    private final char[] password;

    FormCallbackHandler(String u, String p) {
        this.username = u;
        this.password = p.toCharArray();
    }

    @Override
    public void handle(Callback[] callbacks)
            throws UnsupportedCallbackException {
        for (Callback cb : callbacks) {
            if (cb instanceof NameCallback)
                ((NameCallback) cb).setName(username);
            else if (cb instanceof PasswordCallback)
                ((PasswordCallback) cb)
                    .setPassword(password);
            else throw new UnsupportedCallbackException(
                cb, "Not supported"
            );
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

The same DatabaseLoginModule works with:
- HTTP form login (FormCallbackHandler)
- Command line (TextCallbackHandler)
- Tests (MockCallbackHandler)
No code changes to the LoginModule.

*What separates good from great:* "CallbackHandler separation is why JAAS LoginModules don't import any javax.servlet classes. They can run in any context (servlet, command-line, batch). The server implements the CallbackHandler that sources credentials from the current HTTP request."

---

**[SENIOR] Q4 - How does an app server use JAAS
internally?**

*Why they ask:* Server integration understanding.

WildFly Elytron (modern) flow:
```
HTTP Request with credentials
    |
    v
Undertow web layer
    |
    v
HTTP Authentication Factory (Elytron)
  - Reads Authorization header
  - Creates CallbackHandler with credentials
    |
    v
Security Domain
  - Calls configured Security Realm
    |
    v
Security Realm (database, LDAP, filesystem)
  - Validates credentials
  - Returns identity attributes
    |
    v
SecurityIdentity (Elytron's Subject equivalent)
  - Contains CallerPrincipal + roles
    |
    v
SecurityContext in JAX-RS/EJB request
  - @RolesAllowed checks against SecurityIdentity roles
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Legacy JAAS (PicketBox in WildFly < 12):
- Security domain configured in standalone.xml
- Login modules configured per domain
- Application declares domain in jboss-web.xml

*What separates good from great:* "WildFly 12+ migrated from JAAS PicketBox to Elytron. Elytron has a cleaner API but the same conceptual model: security realm = credential store, security domain = auth policy. Legacy JAAS apps can still use the 'legacy-security' subsystem, but Elytron is the recommended path."

---

**[SENIOR] Q5 - When would you use a custom
LoginModule vs Jakarta Security?**

*Why they ask:* Technology choice reasoning.

Custom LoginModule: use when authentication must
happen at the server level (shared across applications,
server-managed sessions, legacy security domain).

Jakarta Security @HttpAuthenticationMechanism: use
for new per-application authentication in CDI context.

Key differences:

| Aspect | JAAS LoginModule | Jakarta Security |
|---|---|---|
| CDI injection | No | Yes |
| Scope | Server/domain | Per-application |
| Portability | Server-specific | Portable (EE 8+) |
| Testability | Difficult | CDI bean, mockable |
| Configuration | XML/properties | Annotations + CDI |

```java
// Jakarta Security: CDI injection works
@ApplicationScoped
public class MyAuthMechanism
        implements HttpAuthenticationMechanism {
    @Inject UserRepository userRepo; // CDI injection!
    @Inject JwtService jwt;

    @Override
    public AuthenticationStatus validateRequest(...) {
        // Use injected services
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "The CDI injection difference is decisive. A JAAS LoginModule needs a JNDI lookup to get a DataSource. A Jakarta Security @IdentityStore can inject @PersistenceContext or @Inject any CDI bean. For any new development on Jakarta EE 8+, Jakarta Security is the right API."

---

**[SENIOR] Q6 - What security risks exist in
custom JAAS LoginModules?**

*Why they ask:* Security code review.

Top risks:

1. Credentials left in memory (String passwords):
   ```java
   // BAD: String immutable, stays in heap
   private String password = new String(pc.getPassword());

   // GOOD: char array, zero out after use
   char[] pwd = pc.getPassword();
   try {
       // use pwd
   } finally {
       pc.clearPassword();
       java.util.Arrays.fill(pwd, '\0');
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. SQL injection in credential validation:
   ```java
   // BAD: string concat
   "SELECT pwd FROM users WHERE name='" + username + "'";

   // GOOD: prepared statement
   ps.setString(1, username);
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. Timing attacks in comparison:
   ```java
   // BAD: short-circuits on first mismatch
   if (!storedHash.equals(computedHash)) {...}

   // GOOD: constant time
   if (!MessageDigest.isEqual(
       storedHash.getBytes(), computedHash.getBytes())) {...}
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

4. Logging credentials:
   ```java
   // BAD
   log.debug("Login attempt: " + username +
       " password: " + password);
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Timing attacks are real: if the LoginModule returns faster for non-existent users (username lookup returns null immediately) than for wrong passwords (username found, hash computed, comparison runs), an attacker measures response times to enumerate valid usernames. Use constant-time comparison and normalize response time."

---

**[SENIOR] Q7 - How do you debug JAAS auth failures?**

*Why they ask:* Production debugging.

Debugging steps:

1. Enable JAAS debug output:
   ```bash
   # Java system property (stdout output):
   java -Djava.security.debug=logincontext,configfile

   # WildFly: server log (preferred in production):
   /subsystem=logging/logger=org.jboss.security\
   :write-attribute(name=level,value=TRACE)
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Test LoginModule in isolation:
   ```java
   @Test
   void testDatabaseLoginModule() throws Exception {
       Subject subject = new Subject();
       CallbackHandler handler = callbacks -> {
           for (Callback cb : callbacks) {
               if (cb instanceof NameCallback)
                   ((NameCallback)cb).setName("testuser");
               else if (cb instanceof PasswordCallback)
                   ((PasswordCallback)cb)
                       .setPassword("testpass".toCharArray());
           }
       };
       LoginContext lc = new LoginContext(
           "TestDomain", subject, handler,
           buildTestConfig()
       );
       assertDoesNotThrow(() -> lc.login());
       assertTrue(subject.getPrincipals().stream()
           .anyMatch(p -> "testuser".equals(p.getName())));
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. Verify database hash directly:
   ```sql
   -- Check stored hash for test user:
   SELECT password FROM users WHERE username = 'testuser';
   -- Manually compute hash and compare
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "-Djava.security.debug=all outputs to stdout, not the server log. In production-like setups where stdout is redirected or discarded, use the server's logging configuration instead. The WildFly CLI approach writes to server.log where you can grep."

---

**[SENIOR] Q8 - How does JAAS role mapping work
in WildFly?**

*Why they ask:* Server configuration knowledge.

JAAS Principals are raw (LDAP DN, database group name).
Jakarta EE roles are application-level names.
Role mapping connects them:

```xml
<!-- jboss-web.xml -->
<jboss-web>
  <security-domain>app-domain</security-domain>
  <security-role-ref>
    <!-- App role -> LDAP group or DB role name -->
    <role-name>ADMIN</role-name>
    <role-link>cn=app-admins,dc=example,dc=com</role-link>
  </security-role-ref>
  <security-role-ref>
    <role-name>CUSTOMER</role-name>
    <role-link>app-customers</role-link>
  </security-role-ref>
</jboss-web>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Elytron (modern): role decoder maps identity attributes:
```xml
<simple-role-decoder name="groups-decoder"
  attribute="groups"/>
<!-- Identity's 'groups' attribute is used directly as roles -->
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Benefits: application code uses "ADMIN" (logical name);
infrastructure uses LDAP group names. When LDAP group
names change, only the mapping changes.

*What separates good from great:* "Role mapping is an architectural boundary: the application declares the logical security model (ADMIN, CUSTOMER, MANAGER). The operations team manages LDAP groups (their naming convention). Mapping in jboss-web.xml or Elytron configuration is the translation layer. Putting LDAP group names directly in @RolesAllowed couples the application to LDAP structure."

---

**[SENIOR] Q9 - What is the relationship between
JAAS Subject, Principal, and Jakarta EE SecurityContext?**

*Why they ask:* Auth model integration.

JAAS model:
- Subject: authenticated entity with multiple Principals
- Principal: one identity (username, role, group DN)
- Subject can have multiple Principals simultaneously

Jakarta EE model:
- SecurityContext: request-scoped view of the authenticated entity
- `getUserPrincipal()`: returns the caller Principal
- `isUserInRole(role)`: checks if caller has role

The app server bridges them:
1. JAAS LoginModule populates Subject with Principals
2. App server reads Subject's Principals
3. Creates SecurityContext based on Principal mapping
4. `isUserInRole("ADMIN")` checks if Subject has
   a Principal named "ADMIN" (or mapped to it)

```java
// Inside a JAX-RS resource:
@Context SecurityContext sc;

sc.getUserPrincipal().getName();  // username Principal
sc.isUserInRole("ADMIN");         // role Principal check

// Equivalent to JAAS:
subject.getPrincipals().stream()
    .anyMatch(p -> "admin".equals(p.getName()));
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "A Subject can have a CallerPrincipal (identity) and RolePrincipal (roles) as separate Principal instances. The difference matters: getUserPrincipal() returns the CallerPrincipal (username); isUserInRole() checks RolePrincipals. Some LoginModule implementations add roles as Principals with class RolePrincipal; the app server knows which Principal types represent roles via configuration."

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



