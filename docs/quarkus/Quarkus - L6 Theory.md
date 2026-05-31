---
layout: default
title: "Quarkus - L6 Theory"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 9
permalink: /quarkus/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Build-Time Augmentation Theory](#build-time-augmentation-theory) | hard |
| 2 | [MicroProfile Specification](#microprofile-specification) | hard |

---

# Build-Time Augmentation Theory

**Interview Weight:** hard - Theory separates staff
engineers from senior. Tested for Principal/Architect
candidates.

---

### 🎯 Model Answer

**30 seconds:**

> Build-time augmentation is the architectural principle
> behind Quarkus: move everything possible from runtime
> to compile time. Framework metadata (CDI graphs,
> REST routes, JPA metamodels) is computed once at
> build and serialized into the artifact. At runtime,
> the application restores the pre-computed state
> instead of recomputing it. This is the fundamental
> reason for Quarkus's startup speed and native image
> compatibility.

**3 minutes (Senior):**

> Augmentation theory:
>
> Traditional Java framework (Spring) lifecycle:
>   1. Load JARs
>   2. Scan classpath for annotations
>   3. Create BeanDefinition objects
>   4. Validate dependency graph
>   5. Instantiate beans
>   6. Inject dependencies
>   7. Post-process
>   8. Ready
>   Steps 1-7: repeated on every startup.
>   Cost: seconds to minutes for large applications.
>
> Quarkus augmentation lifecycle:
>   Build time (once):
>     1. Load JARs
>     2. Scan classpath (Jandex)
>     3. Create BeanInfo objects
>     4. Validate dependency graph
>     5. Generate Java code for beans, proxies, dispatch
>     6. Compile generated code
>     7. Create augmented JAR
>   Runtime (every startup):
>     1. Load augmented JAR
>     2. Execute pre-generated init code
>     3. Ready
>   Runtime cost: <500ms for most apps.
>
> Information theory perspective:
>   Framework metadata has two components:
>   - Static: depends only on code structure (stable).
>   - Dynamic: depends on runtime state (changes).
>   Augmentation moves static computation to build.
>   Runtime handles only dynamic state.
>
>   Examples of static metadata:
>   - Which classes are CDI beans
>   - Injection point types
>   - REST route dispatch table
>   - JPA column mapping
>
>   Examples of dynamic metadata:
>   - Actual bean instances
>   - Connection pool state
>   - Request-scoped data

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the theoretical
basis for Quarkus's build-time approach."

**(2) First principles:** "Framework startup work =
static (code-dependent) + dynamic (data-dependent).
Static work can be done once and cached."

**(3) Bridge:** "Augmentation is ahead-of-time compilation
applied to the framework layer, not just the code."

---

### 💻 Code Example

```java
// Understanding augmentation output

// What exists BEFORE augmentation:
// Source code with annotations
@ApplicationScoped
public class OrderService {

    @Inject
    OrderRepository repository;

    @Transactional
    public Order createOrder(
            CreateOrderRequest req) {
        return repository.save(
            Order.from(req));
    }
}

// What Quarkus GENERATES during augmentation:

// 1. Bean descriptor (resolves DI at build time)
// OrderService_Bean.java (simplified):
public final class OrderService_Bean
        implements InjectableBean<OrderService> {

    // Dependency reference resolved at BUILD TIME
    private final OrderRepository_Bean repoBeanRef;

    @Override
    public OrderService create(
            CreationalContext<OrderService> ctx) {
        OrderService instance =
            new OrderService();
        // DIRECT FIELD ASSIGNMENT - no reflection
        instance.repository =
            repoBeanRef.get(ctx);
        return instance;
    }
}

// 2. Proxy (scope management)
// OrderService_ClientProxy.java:
public final class OrderService_ClientProxy
        extends OrderService {

    @Override
    public Order createOrder(
            CreateOrderRequest req) {
        // Get the contextual instance
        OrderService delegate =
            (OrderService) Arc.container()
                .getActiveContext(
                    ApplicationScoped.class)
                .get(OrderService_Bean.INSTANCE);
        return delegate.createOrder(req);
    }
}

// 3. Subclass for interceptors
// OrderService_Subclass.java:
public final class OrderService_Subclass
        extends OrderService {

    @Override
    public Order createOrder(
            CreateOrderRequest req) {
        // Interceptor chain compiled in
        TransactionInterceptor txInterceptor =
            Arc.container()
               .instance(
                   TransactionInterceptor.class)
               .get();

        InvocationContext ctx =
            new InvocationContextImpl(
                super::createOrder,
                req);
        return (Order) txInterceptor.intercept(ctx);
    }
}

// What this achieves:
// - ZERO reflection at runtime
// - ZERO classpath scanning at startup
// - ZERO dynamic proxy generation
// - Pre-compiled interceptor chain
// - Startup: restore state (no recompute)
```

> **Code walkthrough:** The generated _Bean class resolves
> the OrderRepository injection at build time and stores
> a direct reference. At runtime, creating OrderService
> does a direct field assignment - no reflection.
> The _ClientProxy overrides each method to resolve the
> scope-appropriate instance. The _Subclass bakes the
> interceptor chain into the method directly - no dynamic
> proxy generation at startup. Together, these three
> generated classes represent all the framework work
> that Spring does at runtime, moved to build time.

---

### ⚖️ Comparison Table

| Phase | Spring | Quarkus |
|---|---|---|
| Classpath scan | Startup | Build time |
| Bean graph | Startup | Build time |
| Proxy generation | Startup | Build time |
| Validation | Startup | Build time |
| Bean instantiation | First use (lazy) | First use (lazy) |
| Config resolution | Runtime | Runtime (unless locked) |
| Result | Slow startup, flexible | Fast startup, less dynamic |

---

### 🎓 Answers by Seniority

**Staff:** "Augmentation is the separation of static
and dynamic computation. Static = what's known from
source code (annotation structure, injection points,
bean types). Dynamic = what requires runtime data
(actual bean instances, connection state). Quarkus
eliminates the startup cost of recomputing static
information on every restart."

**Principal:** "Augmentation is an instance of the
partial evaluation principle from programming language
theory: given a program with fixed and variable inputs,
partially evaluate (specialize) the fixed inputs at
compile time, producing a specialized program for
the variable inputs. Framework code = fixed (from
annotations). Application logic = variable (from data).
Quarkus partially evaluates the framework at build time."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 8 min | Augmentation theory, static vs dynamic, generated code |
| Principal | 14 min | Partial evaluation, trade-offs, future directions |

---

**[PRINCIPAL] Q1 - What are the fundamental
trade-offs of build-time augmentation?**

*Why they ask:* Architectural wisdom.

Benefit: static computation done once.
Cost 1: dynamism is restricted.

Spring allows:
```java
// Dynamic bean registration at runtime
context.getBeanFactory()
    .registerSingleton("myBean", new MyBean());
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Quarkus does not: beans must be declared at build time.
Dynamic plugins, hot-swap without restart: hard.

Cost 2: build time increases.
Augmentation adds 5-15 seconds to build.
For CI/CD with 100 builds/day: 8-25 minutes overhead.
Mitigation: incremental build support in Dev Mode.

Cost 3: extensibility requires build-step knowledge.
Adding a new framework integration: must write a
@BuildStep processor.
Spring: just add a @Configuration class.
Quarkus: must understand augmentation API.

Cost 4: reflection must be declared.
Dynamic class loading: forbidden in native image.
Third-party libraries without Quarkus extension:
require manual reflect-config.json.

Trade-off summary:
Static world: predictable, fast, limited dynamism.
Dynamic world: flexible, slow to start, harder to compile.

Quarkus bet: most enterprise apps are static by nature.
Nobody needs to register beans at runtime in production.
The dynamism is in the data, not the code structure.

*What separates good from great:* "Dynamic plugins are
the exception, not the rule, in enterprise Java."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Generated code, build phases. |
| Hiring Manager | Build-time advantage for cloud-native. |
| Bar Raiser | Static vs dynamic trade-off, partial evaluation theory. |
| Principal | "Augmentation is partial evaluation of framework at build time. Not a new idea - GHC does this for Haskell typeclasses." |

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


# MicroProfile Specification

**Interview Weight:** hard - MicroProfile is the
specification foundation. Tested for understanding
of standards vs implementations.

---

### 🎯 Model Answer

**30 seconds:**

> MicroProfile is an Eclipse Foundation specification
> for cloud-native microservices in Java, complementing
> Jakarta EE. Quarkus implements MicroProfile via SmallRye
> implementations. Key specs: Config (externalized config),
> Health (readiness/liveness), Metrics (Micrometer),
> Fault Tolerance (retry/circuit breaker), JWT (authentication),
> OpenAPI (API documentation), REST Client (type-safe HTTP).
> Each spec is implemented by a library (SmallRye Config,
> SmallRye Fault Tolerance, etc.).

**3 minutes (Senior):**

> MicroProfile specification set:
>
> Core (all microservices):
>   Config (4.0): property sources, @ConfigProperty.
>   Health (4.0): /q/health, HealthCheck, probes.
>   Metrics (5.0): Micrometer integration, /q/metrics.
>   JWT Auth (2.1): @RolesAllowed, JsonWebToken.
>
> Resilience:
>   Fault Tolerance (4.0): @Retry, @CircuitBreaker,
>     @Bulkhead, @Timeout, @Fallback.
>
> Communication:
>   REST Client (3.0): @RegisterRestClient, @PathParam.
>   OpenAPI (3.1): @OpenAPIDefinition, Swagger UI.
>
> Observability:
>   Telemetry (1.1): OpenTelemetry integration.
>
> MicroProfile vs Jakarta EE:
>   Jakarta EE: full enterprise Java spec.
>     Servlet, JPA, EJB, CDI, JAX-RS.
>   MicroProfile: adds cloud-native concerns.
>     Config, health, resilience, JWT.
>   Quarkus: implements both.
>     CDI via ArC, JAX-RS via RESTEasy,
>     MP Config via SmallRye Config.
>
> Spec versioning:
>   MicroProfile 7.0: latest (2024).
>   Each spec has independent versioning.
>   Quarkus lists supported spec versions.
>
> SmallRye implementations:
>   SmallRye Config: quarkus-config
>   SmallRye Health: quarkus-smallrye-health
>   SmallRye Fault Tolerance: quarkus-smallrye-fault-tolerance
>   SmallRye JWT: quarkus-smallrye-jwt
>   SmallRye Metrics: quarkus-micrometer-registry-prometheus

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about MicroProfile -
the specification that Quarkus implements."

**(2) First principles:** "Specification = contract between
API author and implementor. Multiple frameworks implement
the same spec."

**(3) Bridge:** "MicroProfile is to microservices what
Jakarta EE is to enterprise Java - a committee-defined
standard with multiple implementations."

---

### 💻 Code Example

```java
// MicroProfile APIs in Quarkus: specification-standard code
// This code would work in any MicroProfile implementation
// (OpenLiberty, Payara, Helidon, Quarkus)

// MP Config (spec: org.eclipse.microprofile.config)
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class OrderService {
    @ConfigProperty(name = "order.max-items",
                    defaultValue = "50")
    int maxItems;
    // Same annotation: OpenLiberty, Quarkus, Payara
}

// MP Health (spec: org.eclipse.microprofile.health)
import org.eclipse.microprofile.health.*;

@Readiness
@ApplicationScoped
public class DatabaseReadiness
        implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse
            .named("database")
            .status(isDatabaseReachable())
            .build();
    }

    private boolean isDatabaseReachable() { ... }
}
// Same code works on any MP 4.0+ implementation

// MP Fault Tolerance (spec: org.eclipse.microprofile.faulttolerance)
import org.eclipse.microprofile.faulttolerance.*;

@ApplicationScoped
public class InventoryService {

    @Retry(maxRetries = 3, delay = 500)
    @CircuitBreaker(requestVolumeThreshold = 20)
    @Fallback(fallbackMethod = "fallbackItem")
    public InventoryItem findItem(Long id) {
        return client.getItem(id);
    }

    InventoryItem fallbackItem(Long id) {
        return InventoryItem.unknown(id);
    }
}
// Same code, different runtime: runs on any MP FT impl

// MP JWT Auth (spec: org.eclipse.microprofile.jwt)
import org.eclipse.microprofile.jwt.JsonWebToken;

@Path("/orders")
@ApplicationScoped
public class OrderResource {

    @Inject
    JsonWebToken jwt;

    @GET
    @RolesAllowed("customer")
    public List<Order> myOrders() {
        String subject = jwt.getSubject();
        // subject = user ID from JWT
        return orderService
            .findByCustomer(subject);
    }
}

// MP REST Client (spec: org.eclipse.microprofile.rest.client)
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@RegisterRestClient(configKey = "inventory")
public interface InventoryClient {

    @GET
    @Path("/items/{id}")
    InventoryItem getItem(@PathParam("id") Long id);
}
// Register: mp.rest.client.scope=Singleton
// URL: inventory/mp-rest/url=http://inventory:8080
```

> **Code walkthrough:** All imports are from the
> org.eclipse.microprofile.* packages - the specification
> API, not any specific implementation. The same code
> compiles and runs identically on OpenLiberty, Payara,
> Quarkus, and Helidon. Quarkus provides the runtime
> through SmallRye libraries. This portability is the
> MicroProfile value proposition: write once, run on
> any compliant runtime.

---

### ⚖️ Comparison Table

| Standard | Package | Implementation | Quarkus Extension |
|---|---|---|---|
| MP Config | microprofile.config | SmallRye Config | quarkus-smallrye-config |
| MP Health | microprofile.health | SmallRye Health | quarkus-smallrye-health |
| MP Fault Tolerance | microprofile.faulttolerance | SmallRye FT | quarkus-smallrye-fault-tolerance |
| MP JWT | microprofile.jwt | SmallRye JWT | quarkus-smallrye-jwt |
| MP REST Client | microprofile.rest.client | RESTEasy Client | quarkus-rest-client |
| MP Metrics | microprofile.metrics | Micrometer | quarkus-micrometer |

---

### 🎓 Answers by Seniority

**Senior:** "MicroProfile is the Eclipse specification.
Quarkus implements it via SmallRye. Using MP API imports
(org.eclipse.microprofile.*) gives portability across
runtimes. Quarkus adds extensions beyond MP: Panache,
ArC, Vert.x."

**Staff:** "MicroProfile is the standardization layer
that prevents framework lock-in. In theory: write MP
code, switch from Quarkus to OpenLiberty. In practice:
Quarkus-specific features (Panache, ArC, build-time
processing) create soft lock-in. The trade-off is worth
it for the performance benefits."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | MP specs, SmallRye, portable code |
| Staff | 10 min | MP vs Jakarta EE, portability trade-off, spec evolution |

---

**[STAFF] Q1 - Is MicroProfile portability
meaningful in practice?**

*Why they ask:* Critical thinking about standards.

Theoretical portability: write org.eclipse.microprofile.* code,
run on any compliant runtime.

Practical reality:

Layer 1 (portable): MP Config, Health, Fault Tolerance,
JWT. These specs are tight, implementations compatible.
A simple microservice using only these APIs IS portable.

Layer 2 (framework-specific): Data access, HTTP server,
security configuration. Quarkus uses Panache/RESTEasy.
OpenLiberty uses JPA/CXF. Different APIs, same MP specs.
Migration requires rewriting the non-MP code.

Layer 3 (vendor extension): Quarkus Dev Mode, native image,
build-time augmentation. Zero portability. Quarkus-specific.

Real portability scenario:
10% of code (MP APIs): portable.
60% of code (HTTP, persistence, config): needs rewrite.
30% of code (business logic): portable (pure Java).

Historical analog: J2EE promised portability in 2000.
Most apps had JBoss-specific features. Migrating was
still expensive. MicroProfile portability has the same
practical limits.

Value of MicroProfile portability:
Not "switch runtimes for free" but "don't learn new
resilience/config APIs for each framework."

*What separates good from great:* Honest assessment
of portability limits vs theoretical promise.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | MP spec list, SmallRye implementations. |
| Hiring Manager | Standard APIs for vendor neutrality. |
| Bar Raiser | Portability reality, MP vs Jakarta EE boundary. |
| Principal | "MicroProfile portability works at the API call site, not at the integration layer. Same limit as J2EE portability." |

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



