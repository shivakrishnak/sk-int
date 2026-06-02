---
layout: default
title: "Quarkus - L1 Foundations"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 2
permalink: /quarkus/l1-foundations/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus CDI Bean Model](#quarkus-cdi-bean-model) | foundational |
| 2 | [Quarkus Dev Mode and Live Coding](#quarkus-dev-mode-and-live-coding) | medium |
| 3 | [Quarkus Configuration System](#quarkus-configuration-system) | medium |
| 4 | [Quarkus Extensions Ecosystem](#quarkus-extensions-ecosystem) | medium |

---

# Quarkus CDI Bean Model

**Interview Weight:** foundational - CDI is the core
of Quarkus DI. Every Quarkus developer must know this.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus uses CDI 4.0 (Jakarta Contexts and Dependency
> Injection) implemented by ArC (Augmented Runtime
> Container). Beans are annotated with scope annotations:
> @ApplicationScoped (singleton), @RequestScoped
> (per-request), @Dependent (default, scope of injector).
> @Inject for injection points. @Produces for factory
> methods. CDI beans are processed at build time by ArC.
> No reflection for DI at runtime - generated code instead.

**3 minutes (Senior):**

> CDI scopes in Quarkus:
>
> @ApplicationScoped:
>   One instance per application.
>   Backed by a CDI proxy (unlike Micronaut @Singleton).
>   Thread-safe access required for mutable state.
>   Lazy by default (proxy created, bean activated on first use).
>
> @Singleton:
>   Micronaut/Spring-style singleton.
>   No CDI proxy. Direct reference.
>   NOT the same as @ApplicationScoped (subtle).
>   Eager: created at startup.
>
> @RequestScoped:
>   One instance per HTTP request (or CDI request context).
>   Created at request start, destroyed at request end.
>
> @SessionScoped:
>   One per HTTP session.
>   Requires serializable bean.
>
> @Dependent:
>   Default scope.
>   Instance lifetime = injector lifetime.
>   Injected into @Singleton: lives as long as Singleton.
>
> @Produces + @ApplicationScoped:
>   Factory method pattern for beans you don't own.
>   @Produces DataSource dataSource(@ConfigProperty...) {}
>
> Qualifiers:
>   @Named("primary"), custom @Qualifier annotations.
>   @Default: default implementation.
>   @Alternative: secondary implementation, needs @Priority.
>
> Observers:
>   void onStartup(@Observes StartupEvent ev)
>   Event handling without explicit registration.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus dependency
injection - how beans are defined and injected."

**(2) First principles:** "DI = components declare what
they need; the framework provides it. CDI = the Jakarta
standard for this in Java."

**(3) Bridge:** "Quarkus CDI is Spring @Component and
@Autowired with Jakarta standard names. @ApplicationScoped
≈ @Component (singleton), @Inject = @Autowired."

---

### 💻 Code Example

```java
// Application-scoped bean (singleton equivalent)
@ApplicationScoped
public class OrderService {

    @Inject
    OrderRepository repository;

    @Inject
    @Named("primary")  // Qualifier
    NotificationService notificationService;

    public Order createOrder(
            CreateOrderRequest req) {
        Order order = repository.persist(
            Order.from(req));
        notificationService.notify(
            "ORDER_CREATED", order.getId());
        return order;
    }
}

// Producer: create beans you don't own
@ApplicationScoped
public class DataSourceProducer {

    @ConfigProperty(name = "db.url")
    String dbUrl;

    @Produces
    @ApplicationScoped
    DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(dbUrl);
        config.setMaximumPoolSize(10);
        return new HikariDataSource(config);
    }
}

// @RequestScoped for per-request state
@RequestScoped
public class RequestContext {
    private String requestId;
    private String userId;
    private String tenantId;
    // Injected into services to share per-request data
    // Destroyed after request completes
}

// Observer: startup event
@ApplicationScoped
public class AppLifecycle {

    void onStart(@Observes StartupEvent ev) {
        Log.info("Application starting");
    }

    void onStop(@Observes ShutdownEvent ev) {
        Log.info("Application stopping");
    }
}

// @Singleton vs @ApplicationScoped
@Singleton
public class ConfigCache {
    // Direct reference, no proxy
    // Created at startup (eager)
    private final Map<String, String> cache =
        new ConcurrentHashMap<>();
}

@ApplicationScoped
public class OrderProcessor {
    // CDI proxy created at startup
    // Actual bean created on first use (lazy)
    // Proxy allows: scope management, interceptors
}
```

> **Code walkthrough:** @ApplicationScoped creates aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> CDI proxy at build time - the actual bean instance
> is created lazily on first method call. @Inject fields
> are resolved at build time by ArC (no reflection at
> runtime). @Produces with @ApplicationScoped creates
> a factory method - the DataSource is managed by CDI,
> allowing injection elsewhere. @Singleton is eager (no
> proxy) and directly used. @Observer void onStart()
> fires on the CDI StartupEvent without registration.

---

### 🎓 Answers by Seniority

**Junior:** "@ApplicationScoped for singleton-like beans.
@Inject to inject. @RequestScoped for per-request beans.
@Produces for factory methods."

**Senior:** "The @ApplicationScoped proxy is subtle:
the injected reference is always the proxy, not the
actual bean. Calling methods on the proxy goes through
the scope check. For @Singleton (no proxy), the reference
is direct. This affects interceptors: @ApplicationScoped
supports all interceptors; @Singleton does too via ArC


---

### 📘 Concept Explanation

**What it is:** Quarkus uses CDI (Contexts and Dependency Injection) as its
bean model - the Jakarta EE standard for dependency injection. Unlike Spring,
which scans every class and uses CGLIB proxies at runtime, Quarkus CDI (via
ArC, its build-time CDI implementation) discovers beans at build time, generates
proxy classes ahead of time, and validates injection points before deployment.

**Mechanism:** ArC processes CDI annotations at build time:
1. Jandex discovers all classes annotated with CDI scope annotations.
2. ArC validates injection points - `@Inject` fields, constructors, methods.
3. Proxy classes are generated for normal-scoped beans (`@ApplicationScoped`,
   `@RequestScoped`) - these proxies delegate to the contextual instance.
4. `@Singleton` beans are NOT proxied - they are the instance directly.
At JVM startup, no scanning occurs. ArC simply initializes the pre-built wiring.

**Trade-off:**

**Positive:** Build-time validation catches injection errors before runtime.
Zero startup reflection overhead. Beans are instantiated lazily by default.

**Negative:** Beans must be CDI-discoverable (in a bean archive). Dynamic
bean registration (Guice modules, Spring @Configuration factories) is restricted.

**Production Reality:** Build-time injection validation catches misconfiguration
in CI rather than production. A missing `@ApplicationScoped` fails the build,
not a production request.

**Decision:** Use `@ApplicationScoped` for most beans (one instance per app,
proxied, supports all CDI features). Use `@Singleton` only when proxy overhead
is measurable and CDI events/interceptors are not needed on that bean.

---

### ⚠️ Common Misconceptions

**Misconception 1: @Singleton and @ApplicationScoped are equivalent**
**Reality:** Both create one instance per application, but differ in proxying.
`@ApplicationScoped` creates a CDI proxy - calls go through it, enabling lazy
instantiation, CDI events, and interceptors. `@Singleton` is a direct reference
with no proxy - slightly faster but cannot be lazily initialized and does not
support all CDI interceptor types in the same way.

**Misconception 2: Any class in the classpath is a CDI bean**
**Reality:** Only classes in a CDI bean archive (containing `beans.xml` or
using the default discovery mode) with a valid CDI scope annotation are beans.
In Quarkus, `application.properties` can filter which packages are scanned via
`quarkus.arc.include-patterns` / `quarkus.arc.exclude-patterns`.

**Misconception 3: @Inject works on static fields**
**Reality:** CDI injection does NOT work on static fields. Injection only works
on instance fields, constructor parameters, and initializer method parameters
of CDI-managed beans. Static field injection is a Spring-only pattern (and even
there it requires workarounds).

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: UnsatisfiedResolutionException at startup**
**Symptom:** Application fails to start with `UnsatisfiedResolutionException:
Unsatisfied dependency for type X with qualifiers [@Default]`.
**Diagnosis:** The bean type X has no discovered CDI bean. Check: (1) class has
a scope annotation, (2) class is in a scanned package, (3) no `beans.xml`
exclusion. Use Quarkus Dev UI `/q/arc/beans` to list all discovered beans.
**Fix:** Add `@ApplicationScoped` (or appropriate scope) to the bean class.

**Failure 2: AmbiguousResolutionException for multiple implementations**
**Symptom:** `AmbiguousResolutionException: Ambiguous dependencies for type X` -
two beans implement the same interface without qualification.
**Diagnosis:** Multiple classes implement the injected type with no distinguishing
qualifier. Use `./mvnw quarkus:dev` -> Dev UI -> Arc Inspector to see competing
beans.
**Fix:** Add `@Named("beanA")` / `@Named("beanB")` to implementations and
`@Named("beanA")` at the injection point, or use custom CDI `@Qualifier`
annotations.

but without the CDI proxy overhead."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | CDI scopes, @Inject, @Produces |
| Senior | 6 min | Proxy model, @ApplicationScoped vs @Singleton, observers |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus CDI Bean Model starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus CDI Bean Model-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last.

For Quarkus CDI Bean Model specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation.

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus CDI Bean Model? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus CDI Bean Model, not just the benefits.

Quarkus CDI Bean Model is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance.

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity.

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q10 - [ARCHITECTURE] How does Quarkus CDI Bean Model fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus CDI Bean Model in a real production system, not just in isolation.

Quarkus CDI Bean Model in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus CDI Bean Model typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion).

*What separates good from great:* Recognizing that architectural decisions made for Quarkus CDI Bean Model affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q11 - [PRODUCTION] What Quarkus CDI Bean Model configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus CDI Bean Model.

Critical pre-production checklist for Quarkus CDI Bean Model: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents.

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured.

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q12 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus CDI Bean Model resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus CDI Bean Model knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome).

Strong answers for Quarkus CDI Bean Model include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus CDI Bean Model actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus CDI Bean Model in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus CDI Bean Model starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus CDI Bean Model-related issues. (Quarkus CDI Bean Model, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus CDI Bean Model, Q2)

For Quarkus CDI Bean Model specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus CDI Bean Model, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus CDI Bean Model, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus CDI Bean Model? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus CDI Bean Model, not just the benefits. (Quarkus CDI Bean Model, Q3)

Quarkus CDI Bean Model is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus CDI Bean Model, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus CDI Bean Model, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus CDI Bean Model, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus CDI Bean Model fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus CDI Bean Model in a real production system, not just in isolation. (Quarkus CDI Bean Model, Q4)

Quarkus CDI Bean Model in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability). (Quarkus CDI Bean Model, Q4)

Architectural enablements: Quarkus CDI Bean Model typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden. (Quarkus CDI Bean Model, Q4)

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus CDI Bean Model, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus CDI Bean Model affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus CDI Bean Model configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus CDI Bean Model. (Quarkus CDI Bean Model, Q5)

Critical pre-production checklist for Quarkus CDI Bean Model: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs). (Quarkus CDI Bean Model, Q5)

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus CDI Bean Model, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus CDI Bean Model, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus CDI Bean Model resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus CDI Bean Model knowledge under pressure, and whether you learn from production experience. (Quarkus CDI Bean Model, Q6)

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus CDI Bean Model, Q6)

Strong answers for Quarkus CDI Bean Model include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus CDI Bean Model actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence. (Quarkus CDI Bean Model, Q6)

If you have not used Quarkus CDI Bean Model in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts. (Quarkus CDI Bean Model, Q6)

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus CDI Bean Model handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus CDI Bean Model at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus CDI Bean Model is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes.

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern).

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[SENIOR] Q1 - What is the CDI proxy and why does
@ApplicationScoped use one?**

*Why they ask:* Deep understanding of CDI model.

The CDI proxy is a generated subclass:
```java
// Quarkus ArC generates (simplified):
// OrderService_CDIProxy extends OrderService
class OrderService_CDIProxy
        extends OrderService {

    @Override
    public Order createOrder(
            CreateOrderRequest req) {
        // Get the contextual instance
        OrderService instance =
            Arc.container()
               .select(OrderService.class)
               .get();
        // Delegate to actual instance
        return instance.createOrder(req);
    }
}
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

Why the proxy?
1. Scope management: the proxy can return different
   instances for different scopes. For @RequestScoped:
   proxy delegates to the request-specific instance.
2. Interceptors: the proxy wraps method calls with
   @Transactional, @Logged, etc.
3. Lazy activation: proxy created eagerly; bean activated
   lazily on first call.

Cost of the proxy: one extra method call per bean method.
Negligible in production (single indirection).

When no proxy is needed:
- @Dependent: direct reference to a new instance
- @Singleton: Quarkus uses direct reference (no proxy)
- @Unremovable: prevents bean from being removed by ArC

*What separates good from great:* CDI proxy as a
concrete generated class, not magic.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | CDI scopes, @Produces, observers. |
| Hiring Manager | DI foundation for Quarkus. |
| Bar Raiser | CDI proxy model, @ApplicationScoped vs @Singleton, ArC build-time generation. |
| Peer Engineer | "Had a null pointer through the CDI proxy. The bean wasn't activated. Added @Unremovable." |

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


# Quarkus Dev Mode and Live Coding

**Interview Weight:** medium - Dev Mode is Quarkus's
developer experience differentiator. Tested to show
understanding of the development workflow.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Dev Mode (quarkus dev or mvn quarkus:dev)
> enables live coding: changes to Java source, resources,
> and configuration are reflected immediately on the
> next HTTP request without a full restart. Quarkus
> re-augments and hot-reloads changed classes. Dev
> Services: Quarkus automatically starts Docker containers
> for databases (PostgreSQL, MySQL), Kafka, Redis, and
> other infrastructure during development - no manual
> configuration required.

**3 minutes (Senior):**

> How live reload works:
>
> Dev Mode starts two class loaders:
>   - Base class loader: Quarkus framework classes
>   - Dev class loader: application classes
>
> On every HTTP request (or test trigger):
>   Quarkus checks if source files have changed.
>   If changed: recompile changed classes.
>   Re-run augmentation for changed classes only.
>   Hot swap: replace Dev class loader instances.
>   Request continues with new code.
>
> What triggers reload:
>   - Java source changes
>   - application.properties changes
>   - Static resources changes
>   - test class changes (Continuous Testing)
>
> Dev Services:
>   Quarkus detects missing datasource config.
>   Automatically starts PostgreSQL (Testcontainers).
>   Injects JDBC URL, username, password into config.
>   Works for: PostgreSQL, MySQL, MariaDB, MongoDB,
>     Kafka, Redis, Keycloak, Elastic, Vault.
>
> Continuous Testing:
>   Tests run automatically on code change.
>   Press 'r' in Dev Mode terminal to run tests.
>   Failed tests highlighted immediately.
>   Test-driven development without manual test runs.
>
> Dev UI:
>   http://localhost:8080/q/dev
>   Extension-specific dashboards.
>   CDI bean listing, REST endpoint listing.
>   Config editor, OpenAPI UI.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus Dev Mode -
the developer experience features for rapid iteration."

**(2) First principles:** "Developer feedback loop: change
code → verify change. Faster feedback = faster development."

**(3) Bridge:** "Quarkus Dev Mode is like Spring Boot
DevTools on steroids: live reload + automatic Docker
services + continuous testing in one command."

---

### 🎓 Answers by Seniority

**Junior:** "quarkus dev starts the app with live
reload. Change Java code, refresh the browser - changes
are live. Dev Services auto-start Docker containers."

**Senior:** "Dev Mode's dual class loader model enables
hot reload without full restart - only changed classes
are recompiled and hot-swapped. Dev Services use
Testcontainers under the hood: the same Docker images
used in development are used in @QuarkusTest with
@DevServicesConfig. Configuration is shared. Zero


---

### 📘 Concept Explanation

**What it is:** Quarkus Dev Mode is the primary development workflow: run
`./mvnw quarkus:dev` and the application watches source files, auto-compiles
changes, and restarts the affected components in <1 second - without a full JVM
restart. Dev Services additionally auto-start required infrastructure (PostgreSQL,
Kafka, Redis) as Docker containers configured automatically.

**Mechanism:** Dev Mode runs a background file watcher that monitors
`src/main/java`, `src/main/resources`, and `pom.xml`. When a change is detected:
1. Quarkus triggers a partial rebuild (only changed compilation units).
2. Changed classes are reloaded via a custom ClassLoader.
3. CDI beans impacted by changed classes are re-initialized.
4. The next HTTP request (or after `r` key press) triggers the reload.
Dev Services use Testcontainers to start infrastructure and auto-inject
connection URLs into `application.properties`.

**Trade-off:**

**Positive:** Sub-second feedback cycle eliminates the restart-wait bottleneck.
Dev Services eliminate "works on my machine" infrastructure differences.

**Negative:** Dev Mode adds memory overhead (file watchers, Testcontainers).
Very deep changes (CDI metamodel changes, config schema changes) still require
a full restart.

**Production Reality:** Dev Services use the same Docker image as production
infrastructure - reducing environment drift. A team that runs with Dev Services
in CI also gets identical dev/CI/production environments.

**Decision:** Use Dev Mode for all Quarkus development. Enable
`quarkus.live-reload.instrumentation=true` for method-body hot reload.
Set `quarkus.devservices.enabled=false` when real infrastructure is preferred.

---

### ⚠️ Common Misconceptions

**Misconception 1: Dev Mode is only for local development**
**Reality:** Quarkus Dev Mode can also run in CI for integration tests
(`./mvnw quarkus:dev -Dquarkus.test.continuous-testing=enabled`). Continuous
Testing mode runs tests automatically after each code change, providing instant
test feedback in the same session.

**Misconception 2: Dev Services require manual Docker configuration**
**Reality:** Dev Services use Testcontainers and require NO manual Docker
configuration. They detect which Quarkus datasource/messaging extensions are
present and start matching containers automatically. The only requirement is
Docker daemon running.

**Misconception 3: All changes trigger a full application restart in Dev Mode**
**Reality:** Quarkus performs INCREMENTAL reload - only the changed class and
its dependents are reloaded. A full restart only occurs when CDI metamodel
changes (scope annotations added/removed) or configuration schema changes.
Method body changes with `quarkus.live-reload.instrumentation=true` do not
even reload the class.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Dev Mode not picking up changes**
**Symptom:** Code changes not reflected in running application after save.
Application continues serving old behavior.
**Diagnosis:** Check console for compilation errors. Check if changed file is
in a watched directory (`src/main/java`, `src/main/resources`). Press `r` in
Dev Mode console to force manual reload trigger.
**Fix:** For persistent issues: `quarkus.live-reload.instrumentation=true` in
`application.properties`. For CDI metamodel changes: full restart required
(Ctrl+C, re-run `quarkus:dev`).

**Failure 2: Dev Services container fails to start**
**Symptom:** Application fails at startup with `DevServicesResultBuildItem:
container failed to start` or Testcontainers Docker error.
**Diagnosis:** Check Docker daemon is running (`docker ps`). Check if the
required image can be pulled (`docker pull postgres:14`). Check network
policies that might block container-to-container communication.
**Fix:** Set `quarkus.datasource.devservices.image-name=postgres:14` to pin
a specific image. Set `quarkus.devservices.enabled=false` and configure
real datasource URLs for environments without Docker.

config for local development."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Dev Mode, live reload, Dev Services |
| Senior | 6 min | Class loader model, Dev Services architecture, Continuous Testing |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus Dev Mode and Live Coding starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Dev Mode and Live Coding-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Dev Mode and Live Codi, Q8)

For Quarkus Dev Mode and Live Coding specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Dev Mode and Live Codi, Q8)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus Dev Mode and Live Coding? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Dev Mode and Live Coding, not just the benefits.

Quarkus Dev Mode and Live Coding is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Dev Mode and Live Codi, Q9)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Dev Mode and Live Codi, Q9)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Dev Mode and Live Coding starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Dev Mode and Live Coding-related issues. (Quarkus Dev Mode and Live Codi, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Dev Mode and Live Codi, Q2)

For Quarkus Dev Mode and Live Coding specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Dev Mode and Live Codi, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Dev Mode and Live Codi, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Dev Mode and Live Coding? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Dev Mode and Live Coding, not just the benefits. (Quarkus Dev Mode and Live Codi, Q3)

Quarkus Dev Mode and Live Coding is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Dev Mode and Live Codi, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Dev Mode and Live Codi, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Dev Mode and Live Codi, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Dev Mode and Live Coding fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Dev Mode and Live Coding in a real production system, not just in isolation.

Quarkus Dev Mode and Live Coding in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Dev Mode and Live Coding typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Dev Mode and Live Codi, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Dev Mode and Live Coding affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Dev Mode and Live Coding configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Dev Mode and Live Coding.

Critical pre-production checklist for Quarkus Dev Mode and Live Coding: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Dev Mode and Live Codi, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Dev Mode and Live Codi, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Dev Mode and Live Coding resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Dev Mode and Live Coding knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Dev Mode and Live Codi, Q6)

Strong answers for Quarkus Dev Mode and Live Coding include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Dev Mode and Live Coding actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Dev Mode and Live Coding in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Dev Mode and Live Coding handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Dev Mode and Live Coding at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Dev Mode and Live Coding is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Dev Mode and Live Codi, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Dev Mode and Live Codi, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[SENIOR] Q1 - How do Dev Services work in
@QuarkusTest for integration tests?**

*Why they ask:* Understanding test infrastructure.

When running @QuarkusTest with no datasource configured:
1. Quarkus detects missing datasource config.
2. Dev Services starts a PostgreSQL Testcontainer.
3. Injects the JDBC URL into application.properties.
4. Tests run against a real PostgreSQL container.
5. Container is shared across tests in the same JVM.

This means: no separate Docker Compose file needed
for tests. The database starts automatically.

```java
@QuarkusTest
class OrderServiceTest {

    @Inject
    OrderService orderService;

    // No @container annotations needed!
    // Dev Services started a real PostgreSQL
    @Test
    void testCreateOrder() {
        // Uses real PostgreSQL from Dev Services
        Order order = orderService.create(
            new CreateOrderRequest(
                1L, BigDecimal.TEN));
        assertNotNull(order.getId());
    }
}
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

Customization:
```properties
# application.properties
%test.quarkus.datasource.devservices.image-name=
  postgres:16
%test.quarkus.datasource.devservices.port=5433
```

> **Code walkthrough:** This application.properties example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Benefit: tests use the same database version as
production (configure image name to match prod version).

*What separates good from great:* Dev Services shared
across the test JVM - one container for all tests,
not one per test class.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Live reload mechanism, Dev Services. |
| Hiring Manager | Dev Mode accelerates development. |
| Bar Raiser | Class loader model, Dev Services Testcontainers, Continuous Testing. |
| Peer Engineer | "Dev Services saved our team 2 hours of Docker setup. quarkus dev just works." |

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


# Quarkus Configuration System

**Interview Weight:** medium - Configuration is
essential. Tested for property sources, profiles,
and runtime vs build-time config.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus uses MicroProfile Config: properties from
> application.properties, environment variables, system
> properties, and custom sources. Profiles: %dev,
> %test, %prod prefixes override properties per profile.
> Active profile set via quarkus.profile property or
> QUARKUS_PROFILE env var. @ConfigProperty injects
> typed values. Build-time vs runtime properties:
> some Quarkus properties are locked at build time
> (network.ssl.enabled) - runtime changes require rebuild.

**3 minutes (Senior):**

> Property source priority (highest first):
>
> 1. System properties (-Dkey=value)
> 2. Environment variables (MY_PROPERTY=value)
> 3. .env file (Dev Mode only)
> 4. application.properties
> 5. Extension default values
>
> Profile-specific properties:
>   %dev.quarkus.log.level=DEBUG  (dev profile only)
>   %prod.quarkus.datasource.url=${DB_URL}
>   %test.quarkus.datasource.url=jdbc:postgresql://...
>
> Multiple config files:
>   application.properties: base
>   application-{profile}.properties: profile override
>
> @ConfigProperty injection:
>   @ConfigProperty(name="app.max-orders",
>                   defaultValue="100")
>   int maxOrders;
>
>   @ConfigProperty(name="app.db.password")
>   Optional<String> dbPassword;
>
> @ConfigMapping (POJO binding):
>   @ConfigMapping(prefix="app.order")
>   interface OrderConfig {
>     int maxPerCustomer();
>     Duration timeout();
>   }
>
> Build-time vs runtime properties:
>   Build-time locked: quarkus.native.*, quarkus.ssl.*
>   Runtime changeable: quarkus.log.*, application props
>   Dev Mode: all properties runtime.
>   Native image: build-time locked cannot change.
>
> Secrets:
>   quarkus-smallrye-config-jasypt (encrypt in file)
>   HashiCorp Vault: quarkus-vault extension
>   AWS Secrets Manager: quarkus-amazon-secrets-manager

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how configuration
works in Quarkus - how to define and inject properties."

**(2) First principles:** "Applications need externalized
configuration. Different environments (dev, test, prod)
need different values."

**(3) Bridge:** "Quarkus config is Spring @Value +
@ConfigurationProperties but using the MicroProfile
Config standard with explicit profile notation."

---

### 💻 Code Example

```java
// application.properties
// app.order.max-per-customer=50
// app.order.timeout=30s
// app.notification.enabled=true
// %prod.app.notification.url=${NOTIF_URL}
// %dev.quarkus.log.level=DEBUG

// Simple @ConfigProperty
@ApplicationScoped
public class OrderService {

    @ConfigProperty(
        name = "app.order.max-per-customer",
        defaultValue = "50")
    int maxOrdersPerCustomer;

    @ConfigProperty(
        name = "app.notification.enabled",
        defaultValue = "true")
    boolean notificationEnabled;

    public Order createOrder(
            CreateOrderRequest req) {
        long existing = countOrders(
            req.getCustomerId());
        if (existing >= maxOrdersPerCustomer) {
            throw new OrderLimitException(
                maxOrdersPerCustomer);
        }
        // ...
    }
}

// @ConfigMapping for typed config groups
@ConfigMapping(prefix = "app.order")
public interface OrderConfig {
    int maxPerCustomer();  // app.order.max-per-customer
    Duration timeout();    // app.order.timeout
    Map<String, String> labels();
    Optional<String> featureFlag();
}

// Inject and use
@ApplicationScoped
public class OrderProcessor {

    @Inject
    OrderConfig orderConfig;

    public void processOrder(Order order) {
        Duration timeout = orderConfig.timeout();
        if (orderConfig.featureFlag()
                .isPresent()) {
            // Feature flag behavior
        }
    }
}

// Runtime config update (Dev Mode only)
// PUT http://localhost:8080/q/dev-ui/config
// { "name": "app.order.max-per-customer",
//   "value": "100" }
// Takes effect on next request (no restart)
```

> **Code walkthrough:** @ConfigProperty injects a singleice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> property with an optional default. @ConfigMapping binds
> an entire prefix (app.order.*) to an interface - type
> conversion is automatic (Duration, Optional, Map).
> Profile-specific overrides (%prod.app.notification.url)
> only apply in the prod profile. The %dev.quarkus.log.level
> change is profile-specific and never leaks to production.

---

### 🎓 Answers by Seniority

**Junior:** "@ConfigProperty injects values from
application.properties. Profile prefixes (%dev., %prod.)
override for specific environments."

**Senior:** "Build-time vs runtime properties are
critical for native image: Quarkus native image locks
in build-time properties. Changing quarkus.ssl.native
in production requires a rebuild. Use @ConfigMapping
for grouped configuration - much cleaner than individual


---

### 📘 Concept Explanation

**What it is:** Quarkus uses MicroProfile Config as its configuration API,
with `application.properties` as the primary source. Configuration values are
injected via `@ConfigProperty`, validated at build time, and support multiple
sources with priority ordering: environment variables > system properties >
`application.properties` > `application-{profile}.properties`.

**Mechanism:** Quarkus Config is processed during augmentation:
1. All `@ConfigProperty` injection points are discovered at build time.
2. Missing required configuration fails the BUILD, not runtime.
3. Profile-specific files (`application-prod.properties`) are merged based
   on the active `quarkus.profile` (default: `dev` in dev mode, `prod` in jar).
4. Config sources are prioritized: ENV (300) > System Props (400) > Properties
   file (100). Custom `ConfigSource` implementations can override all.
5. `@ConfigMapping` groups related properties into a typed interface.

**Trade-off:**

**Positive:** Build-time validation catches missing config before deployment.
Type-safe `@ConfigMapping` interfaces prevent key-typo bugs.

**Negative:** Dynamic runtime config changes (without restart) require
`@io.smallrye.config.ConfigMapping` with runtime reload support, which is
more complex to set up.

**Production Reality:** The ENV variable override priority is critical for
Kubernetes: `application.properties` provides defaults, Kubernetes ConfigMap
environment variables override them per environment. No code changes needed
between dev/staging/production.

**Decision:** Use `@ConfigProperty` for simple single values. Use
`@ConfigMapping` for groups of related config (database settings, feature flags,
third-party API config). Always provide default values for optional config.

---

### ⚠️ Common Misconceptions

**Misconception 1: application.properties is read at runtime only**
**Reality:** Quarkus reads and validates `application.properties` during the
BUILD (augmentation phase). Missing required `@ConfigProperty` values with no
default cause BUILD FAILURE, not runtime exceptions. This is a key safety feature
over Spring Boot, which fails at runtime for missing required config.

**Misconception 2: Environment variables override all config sources**
**Reality:** Environment variables have priority 300 in MicroProfile Config.
System properties have priority 400 (HIGHER than ENV). However, in practice,
system properties are rarely set in containers. The effective priority from
highest to lowest in Kubernetes: system properties > ENV (ConfigMap/Secret) >
application.properties defaults.

**Misconception 3: @ConfigProperty injection works in any class**
**Reality:** `@ConfigProperty` injection only works in CDI-managed beans
(classes with CDI scope annotations). Plain Java classes or static contexts
cannot use `@ConfigProperty`. Use `ConfigProvider.getConfig().getValue()` for
programmatic access outside CDI context.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Missing required config fails build**
**Symptom:** `BUILD FAILURE: Property [config.key] is required but not found`
during `mvn package` or `quarkus:dev` startup.
**Diagnosis:** The `@ConfigProperty(name="config.key")` has no default and no
value in any config source. This is intentional - Quarkus fails fast at build
time.
**Fix:** Add `defaultValue` to `@ConfigProperty`, or add the key to
`application.properties`. For environment-specific values, add a
`%prod.config.key=value` profile override.

**Failure 2: Config not loading from environment variable**
**Symptom:** Config property value remains the properties file default even
though an environment variable is set.
**Diagnosis:** Environment variable naming convention: dots become underscores,
lowercase becomes uppercase. `quarkus.datasource.url` -> `QUARKUS_DATASOURCE_URL`.
Check `docker run -e QUARKUS_DATASOURCE_URL=...` or Kubernetes ConfigMap key.
**Fix:** Ensure ENV variable follows the MicroProfile Config naming convention.
Verify with `System.getenv("QUARKUS_DATASOURCE_URL")` in a test endpoint.

@ConfigProperty fields for complex config."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @ConfigProperty, profiles |
| Senior | 6 min | @ConfigMapping, build-time vs runtime, secrets management |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus Configuration System starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Configuration System-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Configuration System, Q8)

For Quarkus Configuration System specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Configuration System, Q8)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus Configuration System? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Configuration System, not just the benefits.

Quarkus Configuration System is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Configuration System, Q9)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Configuration System, Q9)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Configuration System starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Configuration System-related issues. (Quarkus Configuration System, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Configuration System, Q2)

For Quarkus Configuration System specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Configuration System, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Configuration System, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Configuration System? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Configuration System, not just the benefits. (Quarkus Configuration System, Q3)

Quarkus Configuration System is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Configuration System, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Configuration System, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Configuration System, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Configuration System fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Configuration System in a real production system, not just in isolation.

Quarkus Configuration System in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Configuration System typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Configuration System, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Configuration System affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Configuration System configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Configuration System.

Critical pre-production checklist for Quarkus Configuration System: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Configuration System, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Configuration System, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Configuration System resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Configuration System knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Configuration System, Q6)

Strong answers for Quarkus Configuration System include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Configuration System actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Configuration System in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Configuration System handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Configuration System at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Configuration System is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Configuration System, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Configuration System, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[SENIOR] Q1 - How do you handle secrets in Quarkus
native image deployed on Kubernetes?**

*Why they ask:* Production security concern.

Option 1: Kubernetes Secrets as environment variables:
```yaml
# Kubernetes deployment
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secrets
        key: password
```

```properties
# application.properties
quarkus.datasource.password=${DB_PASSWORD}
```

> **Code walkthrough:** This application.properties example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Quarkus resolves ${DB_PASSWORD} at runtime from env var.
Works in native image: runtime config resolution.

Option 2: HashiCorp Vault:
```properties
# application.properties
quarkus.vault.url=https://vault:8200
quarkus.vault.authentication.kubernetes.role=app
# quarkus.datasource.password resolved from Vault
# at startup
```

> **Code walkthrough:** This at startup example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Option 3: AWS Secrets Manager:
```properties
quarkus.vault.url is replaced by
quarkus.amazon.secretsmanager.*
```

> **Code walkthrough:** This at startup example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Security rule: never put secrets in
application.properties in version control.
${ENV_VAR} references are safe - actual values
in Kubernetes Secrets or Vault.

*What separates good from great:* Kubernetes Secret
env var mounting is the most common, simplest, and
least privileged approach.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @ConfigProperty, @ConfigMapping, profiles. |
| Hiring Manager | Clean environment-specific configuration. |
| Bar Raiser | Build-time vs runtime properties, secrets management, native image configuration. |
| Peer Engineer | "All secrets as Kubernetes Secrets mapped to env vars. application.properties references them as ${ENV_VAR}." |

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


# Quarkus Extensions Ecosystem

**Interview Weight:** medium - Extensions are central
to Quarkus. Tested for understanding the extension
model and adding/managing extensions.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus extensions are Maven/Gradle dependencies that
> include both runtime code AND build-time augmentation
> processing. Each extension registers CDI beans, native
> image configuration, and DevServices. Add extensions
> with: quarkus add extension --extensions=hibernate-orm-panache
> or add the Maven/Gradle dependency. Extensions are
> versioned with the Quarkus BOM - use the BOM to
> avoid version conflicts.

**3 minutes (Senior):**

> Extension categories:
>
> Core:
>   quarkus-arc: CDI implementation
>   quarkus-resteasy-reactive: JAX-RS HTTP
>   quarkus-smallrye-config: MicroProfile Config
>
> Data:
>   quarkus-hibernate-orm-panache: JPA + Panache
>   quarkus-hibernate-reactive-panache: reactive JPA
>   quarkus-jdbc-postgresql: JDBC driver
>   quarkus-reactive-pg-client: reactive PostgreSQL
>   quarkus-flyway: schema migration
>
> Messaging:
>   quarkus-smallrye-reactive-messaging-kafka: Kafka
>   quarkus-smallrye-reactive-messaging-amqp: AMQP
>
> Cloud:
>   quarkus-amazon-lambda: AWS Lambda
>   quarkus-amazon-ses, sns, sqs: AWS services
>   quarkus-kubernetes: Kubernetes YAML generation
>   quarkus-container-image-docker: Docker image build
>
> Observability:
>   quarkus-smallrye-health: MicroProfile Health
>   quarkus-micrometer: Micrometer metrics
>   quarkus-opentelemetry: distributed tracing
>
> Security:
>   quarkus-smallrye-jwt: JWT validation
>   quarkus-oidc: OpenID Connect / OAuth2
>   quarkus-elytron-security-properties-file:
>     local user database
>
> Extension versioning:
>   Use Quarkus BOM (import quarkus-bom).
>   Never specify extension versions individually.
>   BOM ensures compatible extension versions.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus extensions -
how third-party libraries integrate with Quarkus."

**(2) First principles:** "Every library needs framework-
specific integration. Extensions are that integration
layer for Quarkus."

**(3) Bridge:** "Quarkus extensions are like Spring
Boot starters but with build-time processing in addition
to auto-configuration."

---

### 🎓 Answers by Seniority

**Junior:** "Add extensions with quarkus add extension
or as Maven dependencies. Use the Quarkus BOM to avoid
version conflicts."

**Senior:** "Extensions are dual-artifact: runtime JAR
and deployment JAR. The deployment JAR contains the
BuildStep processors that run during augmentation. The
runtime JAR is what's in the final application. When
a library doesn't have a Quarkus extension: it works
at runtime but you must provide native image configuration
manually. Choose extensions over plain library dependencies


---

### 📘 Concept Explanation

**What it is:** Quarkus extensions are the integration layer between third-party
libraries and the Quarkus build-time augmentation framework. Each extension has
a `deployment` module (build-time processors) and a `runtime` module (the actual
library integration). Extensions register reflection, resources, and native image
configuration so that Quarkus applications work correctly in both JVM and native
modes.

**Mechanism:** An extension's `deployment` module contains `@BuildStep`
processors that:
1. Detect the presence of the library on the classpath via
   `ExtensionSslNativeSupportBuildItem` or `FeatureBuildItem`.
2. Register reflection classes for the library via `ReflectiveClassBuildItem`.
3. Register native image resources via `NativeImageResourceBuildItem`.
4. Configure the library at build time (JDBC driver registration, Hibernate
   entity enhancement, Jackson module registration).
The `runtime` module contains only the library API and runtime adapters - it is
what goes into the deployed JAR.

**Trade-off:**

**Positive:** Extensions make any library native-image compatible without manual
configuration. Extensions also enable Dev Services for their library.

**Negative:** Extensions must exist for a library to be fully supported.
Arbitrary libraries without extensions may work on JVM but fail in native mode.

**Production Reality:** The Quarkus extension catalog (quarkus.io/extensions)
has 600+ extensions. Quarkiverse hosts community extensions for less common
libraries. Before using any library in a Quarkus project, check if an extension
exists - it saves hours of manual `reflect-config.json` maintenance.

**Decision:** Always prefer Quarkus extensions over raw library dependencies.
Use `./mvnw quarkus:list-extensions` to discover available extensions. Use
`./mvnw quarkus:add-extension -Dextensions=<name>` to add them.

---

### ⚠️ Common Misconceptions

**Misconception 1: Any Maven dependency works in Quarkus native builds**
**Reality:** Libraries using reflection, dynamic proxies, or runtime class
generation require explicit native image configuration. Without a Quarkus
extension or manual `reflect-config.json` entries, these libraries will fail
in native mode. JVM mode may work, but native mode requires complete reflection
registration.

**Misconception 2: Extensions are just Maven wrappers**
**Reality:** Extensions are sophisticated build-time processors that transform
library initialization from runtime to build time. A Quarkus Hibernate ORM
extension, for example, generates entity enhancer bytecode at build time,
registers all entity classes for reflection, and pre-initializes the session
factory wiring - none of which happens with raw Hibernate on classpath.

**Misconception 3: Quarkiverse extensions are experimental and unsafe**
**Reality:** Quarkiverse is the official community extension repository
governed by the Quarkus team. Many Quarkiverse extensions are production-quality
and used by thousands of applications. Check the extension's GitHub stars,
last commit date, and issue tracker activity before using in production.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Extension not found by quarkus:add-extension**
**Symptom:** `./mvnw quarkus:add-extension -Dextensions=my-lib` returns
"Extension not found: my-lib".
**Diagnosis:** The extension name may differ from the library name. Use
`./mvnw quarkus:list-extensions | grep my-lib` or search quarkus.io/extensions.
Check if it is a Quarkiverse extension (artifact ID starts with
`quarkiverse-`).
**Fix:** Use the full artifact ID: `quarkus:add-extension
-Dextensions=io.quarkiverse.mylib:quarkus-mylib`. Or add the Maven dependency
manually and check if a Quarkus extension exists in Quarkiverse.

**Failure 2: Extension version incompatible with Quarkus platform BOM**
**Symptom:** Build fails with conflicting dependency versions or
`NoSuchMethodError` at runtime after adding a new extension.
**Diagnosis:** The extension version conflicts with the Quarkus BOM version.
Run `./mvnw dependency:tree -Dincludes=io.quarkiverse` to find version conflicts.
**Fix:** Add the Quarkus BOM as `<dependencyManagement>` import first, then add
the extension without a version. Quarkiverse extensions aligned with a Quarkus
release are version-managed by the Quarkus BOM.

for native image builds."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Adding extensions, BOM usage |
| Senior | 6 min | Extension dual-artifact, deployment vs runtime, native image |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus Extensions Ecosystem starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Extensions Ecosystem-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Extensions Ecosystem, Q8)

For Quarkus Extensions Ecosystem specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Extensions Ecosystem, Q8)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus Extensions Ecosystem? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Extensions Ecosystem, not just the benefits.

Quarkus Extensions Ecosystem is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Extensions Ecosystem, Q9)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Extensions Ecosystem, Q9)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Extensions Ecosystem starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Extensions Ecosystem-related issues. (Quarkus Extensions Ecosystem, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Extensions Ecosystem, Q2)

For Quarkus Extensions Ecosystem specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Extensions Ecosystem, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Extensions Ecosystem, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Extensions Ecosystem? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Extensions Ecosystem, not just the benefits. (Quarkus Extensions Ecosystem, Q3)

Quarkus Extensions Ecosystem is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Extensions Ecosystem, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Extensions Ecosystem, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Extensions Ecosystem, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Extensions Ecosystem fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Extensions Ecosystem in a real production system, not just in isolation.

Quarkus Extensions Ecosystem in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Extensions Ecosystem typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Extensions Ecosystem, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Extensions Ecosystem affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Extensions Ecosystem configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Extensions Ecosystem.

Critical pre-production checklist for Quarkus Extensions Ecosystem: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Extensions Ecosystem, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Extensions Ecosystem, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Extensions Ecosystem resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Extensions Ecosystem knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Extensions Ecosystem, Q6)

Strong answers for Quarkus Extensions Ecosystem include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Extensions Ecosystem actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Extensions Ecosystem in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Extensions Ecosystem handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Extensions Ecosystem at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Extensions Ecosystem is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Extensions Ecosystem, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Extensions Ecosystem, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[SENIOR] Q1 - How do you add a library that
doesn't have a Quarkus extension?**

*Why they ask:* Real-world scenario with incomplete extension ecosystem.

Step 1: Add the library as a normal dependency:
```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>my-library</artifactId>
    <version>1.0.0</version>
</dependency>
```

> **Code walkthrough:** This concept example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Step 2: Test in JVM mode first. Libraries work in
JVM mode even without Quarkus extension.

Step 3: For native image - identify reflection usage:
```bash
# Run with tracing agent to capture reflections
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image \
  -jar target/app-runner.jar

# Run integration tests to exercise the library
# Agent captures reflect-config.json
```

> **Code walkthrough:** This Agent captures reflect-config.json example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Step 4: Include generated config in native build:
```
src/main/resources/META-INF/native-image/
  reflect-config.json
  resource-config.json
```

> **Code walkthrough:** This Agent captures reflect-config.json example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Step 5: For initialization issues:
```properties
# application.properties
quarkus.native.additional-build-args=
  --initialize-at-run-time=com.problematic.Class
```

> **Code walkthrough:** This application.properties example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

*What separates good from great:* Tracing agent as
the automated way to discover reflection needs.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Extension model, BOM, extension categories. |
| Hiring Manager | Rich extension ecosystem for productivity. |
| Bar Raiser | Deployment vs runtime artifact, adding libraries without extensions. |
| Peer Engineer | "Used tracing agent for a library without an extension. Generated reflect-config.json in 20 minutes." |

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



