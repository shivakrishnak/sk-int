---
layout: default
title: "Quarkus - L3 Internals"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 5
permalink: /quarkus/l3-internals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus ArC CDI Container Internals](#quarkus-arc-cdi-container-internals) | hard |
| 2 | [Quarkus Build-Time DI Internals](#quarkus-build-time-di-internals) | hard |
| 3 | [Quarkus Continuous Testing](#quarkus-continuous-testing) | medium |
| 4 | [Quarkus Native Build Process](#quarkus-native-build-process) | hard |
| 5 | [Quarkus Extension Development](#quarkus-extension-development) | hard |

---

# Quarkus ArC CDI Container Internals

**Interview Weight:** hard - ArC internals separate
Staff from Senior candidates. Tested for deep Quarkus
understanding.

---

### 🎯 Model Answer

**30 seconds:**

> ArC (Augmented Runtime Container) is Quarkus's CDI
> implementation. Unlike Weld (reference CDI), ArC
> processes bean discovery, injection point validation,
> and proxy generation at build time. No classpath
> scanning at startup. No reflection for injection.
> ArC generates Java source code for each CDI component
> (bean, proxy, interceptor chain) during the Quarkus
> augmentation phase and compiles it into the final JAR.

**3 minutes (Senior):**

> ArC build phases:
>
> 1. Bean Discovery:
>   ArC scans annotated classes at build time.
>   Finds: @ApplicationScoped, @Singleton, @RequestScoped,
>     @Produces, @Inject, @Interceptor, @Decorator.
>   Validates: no unsatisfied injection points,
>     no ambiguous beans without qualifiers.
>   Fails FAST: missing bean = build error, not NPE at runtime.
>
> 2. Code Generation:
>   For each bean: generates [BeanName]_Bean.java.
>     Contains: contextual instance creation,
>     injection point resolution, scope management.
>   For each proxy: generates [BeanName]_ClientProxy.java.
>     Subclass with scope-aware method delegation.
>   For each interceptor chain: generates
>     [BeanName]_Subclass.java.
>     Chain: @Transactional, @Logged, @Retry.
>
> 3. Startup (runtime):
>   Arc.container(): load pre-generated metadata.
>   No scanning. No reflection. Pure generated code.
>   Startup time: microseconds for DI init.
>
> Unused bean removal:
>   ArC detects and removes beans never referenced.
>   Arc.container().beans(): list discovered beans.
>   @Unremovable: prevent removal of specific beans.
>   quarkus.arc.remove-unused-beans=false: disable globally.
>
> Circular dependency detection:
>   Build-time: ArC detects circular dependencies.
>   Runtime circular deps (via method injection): prevented.
>   Build error before deployment.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus CDI
works internally - the ArC build-time processing."

**(2) First principles:** "DI framework needs: discover
beans, validate, create, inject. ArC does first three
at build time, last at runtime."

**(3) Bridge:** "ArC is to Spring's DI what a compiler
is to an interpreter: does the work upfront (build time)
rather than at runtime."

---

### 💻 Code Example

```java
// What ArC generates (simplified)

// For: @ApplicationScoped class OrderService
// ArC generates: OrderService_Bean.java

// ArC-generated bean descriptor (simplified):
public final class OrderService_Bean
        extends InjectableBean<OrderService> {

    // References to injected beans (resolved at build time)
    private final InjectableBean<OrderRepository> repo;
    private final InjectableBean<NotificationService> notif;

    // Constructor injection resolution at build time
    public OrderService_Bean(
            InjectableBean<OrderRepository> repo,
            InjectableBean<NotificationService> notif) {
        this.repo = repo;
        this.notif = notif;
    }

    @Override
    public OrderService create(CreationalContext<OrderService> ctx) {
        OrderService instance = new OrderService();
        // Inject: no reflection, direct field assignment
        instance.repository = repo.get(ctx);
        instance.notificationService = notif.get(ctx);
        return instance;
    }

    @Override
    public Class<OrderService> getBeanClass() {
        return OrderService.class;
    }
}

// For: @ApplicationScoped (proxy needed)
// ArC generates: OrderService_ClientProxy.java

public final class OrderService_ClientProxy
        extends OrderService {

    @Override
    public Order createOrder(CreateOrderRequest req) {
        // Get the contextual instance (lazy, scoped)
        return Arc.container()
            .instance(OrderService.class)
            .get()
            .createOrder(req);
        // One virtual dispatch - no reflection
    }
}

// Interceptor chain for @Transactional
// ArC generates: OrderService_Subclass.java

public final class OrderService_Subclass
        extends OrderService {

    @Override
    @Transactional
    public Order createOrder(CreateOrderRequest req) {
        // ArC wraps with TransactionInterceptor
        InvocationContext ctx = new InvocationContextImpl(
            this, "createOrder",
            new Object[]{req},
            List.of(transactionInterceptor));
        return (Order) ctx.proceed();
    }
}
```

```java
// Debugging ArC: find registered beans
@ApplicationScoped
public class ArcInspector {

    public void inspectBeans() {
        // List all registered beans at runtime
        Arc.container().beanManager()
            .getBeans(Object.class)
            .stream()
            .forEach(bean ->
                log.info("Bean: {} scope: {}",
                    bean.getBeanClass().getSimpleName(),
                    bean.getScope().getSimpleName()));
    }
}

// Prevent ArC from removing a bean
@ApplicationScoped
@Unremovable  // Even if no @Inject references it
public class StartupCacheWarmer {

    void onStart(@Observes StartupEvent ev) {
        // Warms caches at startup
        // ArC would remove this if no one injects it
        // @Unremovable keeps it
    }
}

// Suppress build-time warning for producer
@Singleton
public class LegacyProducer {

    @Produces
    @SuppressWarnings("deprecation")
    @Deprecated
    LegacyService legacyService() {
        return new LegacyService();
    }
}
```

> **Code walkthrough:** ArC generates three classes perice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> @ApplicationScoped bean: _Bean (contextual creation),
> _ClientProxy (scope-aware proxy), and _Subclass (interceptor
> chain if any interceptors apply). There is no reflection
> in the generated code - all injection points are resolved
> to direct field assignments. The proxy overrides each
> public method to delegate through the CDI container,
> enabling scope management and lazy initialization.

---

### ⚠️ Common Misconceptions

1. "ArC is Weld with build-time optimization."
   False: ArC is a from-scratch CDI implementation
   for Quarkus. Weld is not used. ArC is intentionally
   not full CDI (no XML configuration, no dynamic beans).

2. "All CDI features work in ArC."
   False: ArC does not support decorators fully, limited
   XML configuration, no dynamic bean registration.
   Intentional: simpler ArC = faster build and startup.

---

### 🎓 Answers by Seniority

**Senior:** "ArC discovers beans at build time, generates
Java source for each, compiles it in. Runtime startup:
zero classpath scanning. Injection errors are build
errors, not runtime NPEs. @Unremovable for beans only
observed by events - ArC considers them unused otherwise."

**Staff:** "ArC's code generation model means native
image compatibility is natural: generated code has no
reflection. Build-time bean validation means immediate
feedback on missing beans. The trade-off: ArC's subset
of CDI catches 99% of use cases, but some advanced


---

### 📘 Concept Explanation

**What it is:** ArC (Adaptive Runtime CDI) is Quarkus's build-time CDI
implementation. Unlike standard CDI containers (Weld, OpenWebBeans) that
discover beans and generate proxies at JVM startup via runtime reflection, ArC
performs all CDI processing at build time and generates concrete Java source
code for beans, proxies, and injection points.

**Mechanism:** ArC's augmentation pipeline:
1. `BeanDeploymentValidatorBuildItem` collects all bean classes via Jandex.
2. `BeanConfiguratorBuildItem` and `SyntheticBeanBuildItem` allow extensions
   to register programmatic beans.
3. ArC generates concrete proxy source code (not CGLIB bytecode) for each
   normal-scoped bean - e.g., `UserService_ClientProxy.java`.
4. Injection points are validated: missing beans, ambiguous matches, and
   type mismatches are BUILD FAILURES.
5. At JVM startup: ArC simply instantiates the pre-generated proxies with
   their pre-computed injection resolutions.

**Trade-off:**

**Positive:** Build-time injection validation eliminates an entire class of
production runtime `NullPointerException` and `UnsatisfiedDependencyException`.

**Negative:** Programmatic CDI features requiring runtime introspection
(dynamic bean registration after startup, runtime `BeanManager.getBeans()` for
arbitrary types) require different patterns or build-time registration.

**Production Reality:** The "build fails" vs "production fails" trade-off is
asymmetric: build failures are caught in CI; runtime failures affect users.
ArC's build-time validation provides production-grade safety for the DI layer.

**Decision:** Use ArC's `@BuildStep` SyntheticBean API for programmatic bean
registration. Use `Instance<T>` for dynamic bean lookup at runtime.

---

### ⚠️ Common Misconceptions

**Misconception 1: ArC is a full CDI 4.0 container**
**Reality:** ArC implements a SUBSET of CDI. Specifically, conversation scope
(`@ConversationScoped`) is not supported. `BeanManager` programmatic lookup is
supported but dynamic `getBeans(Type...)` calls may not reflect all
programmatically-registered beans. Check Quarkus CDI Reference for the exact
supported feature set before relying on advanced CDI features.

**Misconception 2: ArC proxy generation is the same as CGLIB proxies**
**Reality:** ArC generates READABLE Java source code proxies (not CGLIB bytecode
manipulation). ArC proxies extend the bean class directly (like a subclass), not
a separate interface. This means bean classes must not be `final` - a `final`
`@ApplicationScoped` class cannot be proxied and causes a build error.

**Misconception 3: ArC cannot support dynamic CDI features**
**Reality:** ArC supports `SyntheticBeanBuildItem` for registering beans
programmatically at build time, `ObserverMethodConfigurator` for event
observation, and `@LookupIfProperty` for conditional bean availability. These
cover most use cases that require dynamic CDI features in other containers.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Final class causes CDI proxy build failure**
**Symptom:** `BUILD FAILURE: Bean class X is final. CDI normal scoped beans
must not be final.` Cannot proxy a final class.
**Diagnosis:** `@ApplicationScoped` or `@RequestScoped` annotated class is
declared `final`.
**Fix:** Remove `final` from the class declaration. Or change scope to
`@Singleton` which does not require proxying (no proxy overhead). In Kotlin:
Kotlin classes are `final` by default - use `open` modifier or the
`all-open` compiler plugin.

**Failure 2: AmbiguousResolutionException - multiple beans for same type**
**Symptom:** `BUILD FAILURE: AmbiguousResolutionException: Ambiguous dependencies
for type [T] and qualifiers [@Default]`.
**Diagnosis:** Two beans of the same type without qualifying annotations exist.

**Fix:** Add `@Named` or custom `@Qualifier` to distinguish implementations. Or
add `@Priority` if ordering is needed. Or mark one implementation with
`@DefaultBean` to make it the default.

CDI features (decorators, dynamic registration) require
workarounds."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | ArC build phases, generated code, @Unremovable |
| Staff | 12 min | Code generation details, native image alignment, CDI subset |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus ArC CDI Container Internals starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus ArC CDI Container Internals-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last.

For Quarkus ArC CDI Container Internals specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation.

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus ArC CDI Container Internals? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus ArC CDI Container Internals, not just the benefits.

Quarkus ArC CDI Container Internals is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance.

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity.

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q10 - [ARCHITECTURE] How does Quarkus ArC CDI Container Internals fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus ArC CDI Container Internals in a real production system, not just in isolation.

Quarkus ArC CDI Container Internals in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus ArC CDI Container Internals typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion).

*What separates good from great:* Recognizing that architectural decisions made for Quarkus ArC CDI Container Internals affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q11 - [PRODUCTION] What Quarkus ArC CDI Container Internals configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus ArC CDI Container Internals.

Critical pre-production checklist for Quarkus ArC CDI Container Internals: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents.

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured.

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q12 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus ArC CDI Container Internals resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus ArC CDI Container Internals knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome).

Strong answers for Quarkus ArC CDI Container Internals include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus ArC CDI Container Internals actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus ArC CDI Container Internals in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus ArC CDI Container Internals starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus ArC CDI Container Internals-related issues. (Quarkus ArC CDI Container Inte, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus ArC CDI Container Inte, Q2)

For Quarkus ArC CDI Container Internals specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus ArC CDI Container Inte, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus ArC CDI Container Inte, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus ArC CDI Container Internals? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus ArC CDI Container Internals, not just the benefits. (Quarkus ArC CDI Container Inte, Q3)

Quarkus ArC CDI Container Internals is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus ArC CDI Container Inte, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus ArC CDI Container Inte, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus ArC CDI Container Inte, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus ArC CDI Container Internals fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus ArC CDI Container Internals in a real production system, not just in isolation. (Quarkus ArC CDI Container Inte, Q4)

Quarkus ArC CDI Container Internals in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability). (Quarkus ArC CDI Container Inte, Q4)

Architectural enablements: Quarkus ArC CDI Container Internals typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden. (Quarkus ArC CDI Container Inte, Q4)

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus ArC CDI Container Inte, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus ArC CDI Container Internals affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus ArC CDI Container Internals configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus ArC CDI Container Internals. (Quarkus ArC CDI Container Inte, Q5)

Critical pre-production checklist for Quarkus ArC CDI Container Internals: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs). (Quarkus ArC CDI Container Inte, Q5)

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus ArC CDI Container Inte, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus ArC CDI Container Inte, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus ArC CDI Container Internals resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus ArC CDI Container Internals knowledge under pressure, and whether you learn from production experience. (Quarkus ArC CDI Container Inte, Q6)

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus ArC CDI Container Inte, Q6)

Strong answers for Quarkus ArC CDI Container Internals include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus ArC CDI Container Internals actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence. (Quarkus ArC CDI Container Inte, Q6)

If you have not used Quarkus ArC CDI Container Internals in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts. (Quarkus ArC CDI Container Inte, Q6)

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus ArC CDI Container Internals handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus ArC CDI Container Internals at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus ArC CDI Container Internals is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes.

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern).

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[STAFF] Q1 - Why does ArC fail faster than Weld
for DI errors?**

*Why they ask:* Understanding the operational benefits
of build-time DI.

Weld (Spring, Jakarta EE) validates injection at startup.
ArC validates at build time.

Timeline comparison:

With Weld/Spring:
1. Developer writes OrderService with missing @Inject
2. Builds JAR (no error)
3. Deploys to K8s (no error)
4. Pod starts, fails with:
   UnsatisfiedResolutionException: No bean found
5. Developer debugs at runtime
6. Fix, rebuild, redeploy
7. Total time: 20 minutes

With ArC:
2. Runs `quarkus build`
3. Build fails immediately:
   Unsatisfied dependency for type PaymentService
   in: OrderService#paymentService
4. Developer fixes in editor
5. Total time: 10 seconds

Additional build-time validation:
- Ambiguous beans: two implementations, no qualifier
- Circular dependencies
- Invalid interceptor application
- Missing @Produces for complex types

This is why Quarkus startup is ~500ms vs Spring's ~5s:
no injection validation at startup.

*What separates good from great:* Build-time validation
as developer productivity feature, not just performance.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | ArC build phases, code generation, @Unremovable. |
| Hiring Manager | Faster development feedback with build-time validation. |
| Bar Raiser | Generated code details, CDI subset trade-offs. |
| Peer Engineer | "ArC caught a missing bean in our pipeline that would have been a 2am prod incident. Build error. Fixed in 30s." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Quarkus Build-Time DI Internals

**Interview Weight:** hard - Deep internals. Tested
for Staff/Architect candidates building Quarkus extensions.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus build-time DI works through the augmentation
> pipeline: BuildStep processors analyze the classpath
> at build time and generate bytecode or Java sources.
> For CDI (ArC), the BuildStep produces BeanInfo,
> InjectionPointInfo, and generates ClientProxy/Bean
> subclasses. The DeploymentClassLoader loads both
> application classes and deployment processor classes.
> The output: a pre-computed DI graph compiled into
> the application JAR.

**3 minutes (Senior):**

> Build augmentation pipeline:
>
> Phase 1: Bytecode scanning
>   IndexView: Jandex index of all classes.
>   Classes annotated with CDI annotations discovered.
>   AnnotationStore: cross-reference annotations.
>
> Phase 2: Bean registration
>   BeanRegistrationPhase: collect all bean candidates.
>   BeanProcessor.registerBeans(): produce BeanInfo.
>   BeanInfo: class, scope, qualifiers, interceptors.
>
> Phase 3: Validation
>   BeanDeploymentValidator: validate all injection points.
>   Check: all @Inject points have a matching bean.
>   Check: no ambiguous beans.
>   BuildException on failure (build error, not runtime).
>
> Phase 4: Code generation
>   GeneratedBeanBuildItem: trigger Java source generation.
>   BeanGenerator: generates [Bean]_Bean.java.
>   ClientProxyGenerator: generates [Bean]_ClientProxy.java.
>   SubclassGenerator: generates [Bean]_Subclass.java
>     (for intercepted beans).
>
> Phase 5: Compilation
>   Generated sources compiled with application code.
>   Output: fat JAR with all generated code.
>
> Quarkus Extension model:
>   Each extension has Deployment artifacts.
>   Extension BuildSteps: called during augmentation.
>   E.g., HibernateOrmProcessor: scans @Entity classes,
>     generates JPA metamodel, configures Hibernate.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus
processes CDI beans at build time."

**(2) First principles:** "Quarkus moves runtime work
to build time. Build-time = annotation scanning, validation,
code generation."

**(3) Bridge:** "Augmentation is like an ahead-of-time
compiler for the entire application framework layer."

---

### 💻 Code Example

```java
// Writing a Quarkus Extension BuildStep
// (Extension development, not application code)

@BuildSteps  // All @BuildStep methods in this class
public class MyExtensionProcessor {

    @BuildStep
    @Record(ExecutionTime.RUNTIME_INIT)
    public void registerBeans(
            BuildProducer<AdditionalBeanBuildItem>
                additionalBeans,
            MyExtensionConfig config,
            MyExtensionRecorder recorder) {

        // Tell ArC about beans defined in the extension
        additionalBeans.produce(
            AdditionalBeanBuildItem.builder()
                .addBeanClass(MyService.class)
                .setDefaultScope(
                    DotName.createSimple(
                        ApplicationScoped.class
                            .getName()))
                .setUnremovable()
                .build());

        // Register runtime initialization code
        recorder.configure(config.maxConnections());
    }

    @BuildStep
    public void validateConfig(
            MyExtensionConfig config,
            BuildProducer<ValidationErrorBuildItem>
                errors) {
        // Fail build if config is invalid
        if (config.maxConnections() < 1) {
            errors.produce(
                new ValidationErrorBuildItem(
                    new ConfigurationException(
                        "max-connections must be >= 1")));
        }
    }

    @BuildStep
    public NativeImageResourceBuildItem
            nativeResources() {
        // Tell GraalVM to include resource files
        return new NativeImageResourceBuildItem(
            "config/defaults.json");
    }
}

// @Recorder: bridge between build and runtime
@Recorder
public class MyExtensionRecorder {

    public void configure(int maxConnections) {
        // This runs at RUNTIME_INIT (application start)
        // Called with the recorded build-time data
        MyExtensionConfig.MAX_CONNECTIONS =
            maxConnections;
    }
}

// Build-time DI in application: use quarkus.arc.*
// application.properties:
// quarkus.arc.auto-inject-fields=false
//   Requires constructor injection only.
// quarkus.arc.remove-unused-beans=true (default)
//   ArC removes beans nobody injects.
// quarkus.arc.detect-wrong-annotations=true
//   Detect Spring @Component used instead of CDI.
```

> **Code walkthrough:** @BuildStep methods are calledice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> during augmentation - they have access to the classpath
> and can produce BuildItems that other processors consume.
> AdditionalBeanBuildItem tells ArC to register a bean
> that isn't annotated in the application (extension-provided).
> @Record with ExecutionTime.RUNTIME_INIT records a method
> call to execute at startup - the recorder method runs
> after augmentation when the application starts. This
> is how extension configuration flows from build time
> to runtime.

---

### 🎓 Answers by Seniority

**Senior:** "The augmentation pipeline: scan with Jandex,
register beans, validate injection points, generate code.
Build errors for validation failures - not runtime NPEs.
Extensions contribute BuildSteps to this pipeline."

**Staff:** "The @BuildStep/@Recorder pattern is clever:
the Recorder object captures method calls at build time,
serializes them as bytecode (using Gizmo bytecode library),
and executes them at startup. This allows extension authors


---

### 📘 Concept Explanation

**What it is:** Quarkus build-time DI internals refers to how extensions
participate in the augmentation pipeline to register beans, transform bytecode,
and record startup logic. The core mechanism uses `@BuildStep` methods that
produce and consume `BuildItem` types - a type-safe pipeline where order is
determined by data dependencies.

**Mechanism:** The Quarkus build pipeline works as:
1. `@BuildStep` methods in extension `Processor` classes declare their
   inputs (via method parameters) and outputs (via return type or `BuildProducer`).
2. Quarkus constructs a DAG of build steps based on `BuildItem` dependencies.
3. Steps execute in topological order (parallelized where possible).
4. `@Record(STATIC_INIT)` records code to be called at static JVM initialization.
5. `@Record(RUNTIME_INIT)` records code deferred to JVM startup phase.
The recorder pattern allows build-time code to "record" method calls that
execute at runtime, bridging build-time config (available during augmentation)
with runtime initialization (DB URLs, port numbers).

**Trade-off:**

**Positive:** Parallel build step execution. Clear extension boundaries.
Type-safe `BuildItem` pipeline prevents incorrect step ordering.

**Negative:** Complex extension development API. The `@Record` pattern requires
understanding the two-phase init model. Debugging augmentation failures requires
`quarkus.log.level=DEBUG` and reading `BuildItem` pipelines.

**Production Reality:** Understanding the STATIC_INIT vs RUNTIME_INIT distinction
is critical for extension authors. Config values available at STATIC_INIT phase
are build-time-only values. Config values that depend on environment (DB URL,
secrets) must be deferred to RUNTIME_INIT.

**Decision:** When writing Quarkus extensions: use `@BuildStep` + `@Record` for
all framework initialization. Never call framework setup code directly at build
time without recording - it runs in the build JVM, not the application JVM.

---

### ⚠️ Common Misconceptions

**Misconception 1: @BuildStep methods run at application startup**
**Reality:** `@BuildStep` methods run during the BUILD phase (Maven/Gradle build),
NOT at application startup. They run in the build tool JVM. The code generated or
recorded during build steps is what executes at application startup.

**Misconception 2: All Quarkus configuration is available at build time**
**Reality:** Only values from the DEFAULT config sources (application.properties
in the artifact, build-time system properties) are available during augmentation.
Runtime config (environment variables in Kubernetes, secrets) is NOT available
at build time. Extensions must use `@Record(RUNTIME_INIT)` for config that
depends on environment.

**Misconception 3: BuildItem types are shared between different extensions**
**Reality:** `BuildItem` types must be explicitly exported by the producing
extension and imported by the consuming extension. Undeclared cross-extension
dependencies cause build failures. The `ExtensionSslNativeSupportBuildItem` and
`FeatureBuildItem` are the standard cross-extension communication mechanisms.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Recorded runtime initializer fails with NullPointerException**
**Symptom:** Application starts but immediately fails with NPE in the startup
recorder code. Stack trace shows a generated recorder class.
**Diagnosis:** A `@Record(RUNTIME_INIT)` method captured a build-time value that
is null at runtime (e.g., a config value not available during build). The NPE
is in the recorded/replayed code, not the original build step.
**Fix:** Check if the config value should be deferred to `RUNTIME_INIT` using
`RuntimeValue<T>`. Use `@ConfigRoot(phase = ConfigPhase.RUN_TIME)` for runtime
config groups.

**Failure 2: BuildStep not executing - missing BuildItem dependency**
**Symptom:** Extension feature not applied. Build step silently skipped.

**Diagnosis:** Build step has an unsatisfied `BuildItem` parameter dependency.
Enable `quarkus.log.level=DEBUG` during build to see which steps execute.
Check if the required `BuildItem` producer step is in the classpath.
**Fix:** Verify the extension producing the required `BuildItem` is in the
project's dependency closure. Add missing extension or declare optional
`BuildItem` parameter with `@Weak`.

to run startup initialization that 'sees' both build-time
config and runtime config - bridging the two phases."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Augmentation phases, @BuildStep, @Recorder pattern |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Build-Time DI Internals starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Build-Time DI Internals-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Build-Time DI Internal, Q2)

For Quarkus Build-Time DI Internals specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Build-Time DI Internal, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Build-Time DI Internals? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Build-Time DI Internals, not just the benefits.

Quarkus Build-Time DI Internals is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Build-Time DI Internal, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Build-Time DI Internal, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Build-Time DI Internals fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Build-Time DI Internals in a real production system, not just in isolation.

Quarkus Build-Time DI Internals in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Build-Time DI Internals typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Build-Time DI Internal, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Build-Time DI Internals affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Build-Time DI Internals configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Build-Time DI Internals.

Critical pre-production checklist for Quarkus Build-Time DI Internals: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Build-Time DI Internal, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Build-Time DI Internal, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Build-Time DI Internals resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Build-Time DI Internals knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Build-Time DI Internal, Q6)

Strong answers for Quarkus Build-Time DI Internals include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Build-Time DI Internals actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Build-Time DI Internals in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Build-Time DI Internals handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Build-Time DI Internals at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Build-Time DI Internals is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Build-Time DI Internal, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Build-Time DI Internal, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Build-Time DI Internals to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply.

Start with the problem: what existed before Quarkus Build-Time DI Internals and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Build-Time DI Internals: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Build-Time DI Internals and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Build-Time DI Internals at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Build-Time DI Internals beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Build-Time DI Internals expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Build-Time DI Internals, coordinated upgrade windows. (2) Internal shared library for common Quarkus Build-Time DI Internals configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Build-Time DI Internals extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Build-Time DI Internals from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Build-Time DI Internals correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load).

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?).

Testing strategy for Quarkus Build-Time DI Internals: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Build-Time DI Internals starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Build-Time DI Internals-related issues. (Quarkus Build-Time DI Internal, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Build-Time DI Internal, Q11)

For Quarkus Build-Time DI Internals specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Build-Time DI Internal, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Build-Time DI Internal, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Build-Time DI Internals? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Build-Time DI Internals, not just the benefits. (Quarkus Build-Time DI Internal, Q12)

Quarkus Build-Time DI Internals is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Build-Time DI Internal, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Build-Time DI Internal, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Build-Time DI Internal, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[STAFF] Q1 - How does the @Recorder bridge the
gap between build time and runtime in Quarkus?**

*Why they ask:* Core Quarkus extension mechanism.

The problem: at build time, we know config (e.g., pool size = 10).
At runtime, we need to initialize infrastructure (create
the pool with size 10).

The @Recorder solution:
1. Build time: call recorder.initialize(10).
2. Gizmo (bytecode library) serializes this call as
   bytecode into GeneratedInitializerBuildItem.
3. Runtime: the generated bytecode runs recorder.initialize(10).

Why not just run the code at build time?
Resource initialization at build time would be embedded
in the binary:
- Database connections at build time = impossible in CI
- Static final fields would be frozen in native image

The @Recorder bridges by:
- Recording the INTENTION at build time
- Executing the intention at runtime

For native image: RecordableRecorder captures all calls
as serialized objects, replayed during native image startup.

This is what "ahead-of-time" means in Quarkus: not just
native compilation, but pre-computed DI graph + recorded
initialization chain.

*What separates good from great:* The @Recorder as
a deferred execution bridge, not just a configuration holder.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Augmentation pipeline, code generation. |
| Hiring Manager | Extension model enables rich ecosystem. |
| Bar Raiser | @BuildStep, @Recorder, Gizmo, augmentation phases. |
| Peer Engineer | "Wrote an extension with a @BuildStep that scans for @MyAnnotation and @Recorder that registers handlers. 50 lines." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Quarkus Continuous Testing

**Interview Weight:** medium - Continuous Testing is
a developer productivity feature. Shows familiarity
with Quarkus developer experience.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Continuous Testing runs tests automatically
> when code changes in Dev Mode. Press 'r' in the Dev
> Mode terminal to run all tests, or tests run automatically
> on file change. Only changed tests and their dependencies
> are re-run (test impact analysis). Tests run in the
> same JVM as the application - no startup overhead.
> Test results shown in the terminal and Dev UI.

**3 minutes (Senior):**

> Continuous Testing features:
>
> Auto-run on change:
>   Source file saved → Quarkus recompiles.
>   Affected tests detected and run.
>   Results shown inline.
>
> Test impact analysis:
>   Quarkus tracks which source files each test covers.
>   Change OrderService.java:
>     Only OrderServiceTest and OrderIntegrationTest rerun.
>     Not PaymentServiceTest (unrelated).
>
> Keyboard controls (in Dev Mode terminal):
>   r: run all tests
>   e: toggle all test execution
>   b: toggle broken tests only
>   i: toggle test output
>
> @QuarkusTest:
>   Full application context.
>   Dev Services (PostgreSQL, Kafka, etc.) auto-started.
>   Injection works: @Inject in test classes.
>
> @QuarkusIntegrationTest:
>   Runs against running application.
>   Tests the JAR/native binary directly.
>
> @TestProfile:
>   Override config for a test or test class.
>   Different application profile per test.
>
> Mocking:
>   @InjectMock: inject Mockito mock into CDI context.
>   @QuarkusMock: replace a CDI bean with a mock.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus Continuous
Testing - the automatic test execution on code change."

**(2) First principles:** "Faster feedback on code changes
= faster development. Tests reveal breakage."

**(3) Bridge:** "Quarkus Continuous Testing is like
Jest's --watch mode for Java: run affected tests on save."

---

### 💻 Code Example

```java
// @QuarkusTest: full integration test
@QuarkusTest
class OrderServiceTest {

    @Inject
    OrderService orderService;

    @Inject
    OrderRepository orderRepo;

    @Test
    @TestTransaction  // Transaction rolled back after test
    void testCreateOrder() {
        CreateOrderRequest req =
            new CreateOrderRequest(
                1L, BigDecimal.TEN);

        Order created = orderService.create(req);

        assertNotNull(created.getId());
        assertEquals("PENDING", created.getStatus());
        // @TestTransaction rolls back - no cleanup needed
    }

    @Test
    void testListOrders_ReturnsCorrectStatus() {
        given()
            .when()
            .get("/api/v1/orders?status=PENDING")
            .then()
            .statusCode(200)
            .body("size()", greaterThan(0));
    }
}

// Mock a CDI bean in tests
@QuarkusTest
class OrderServiceMockedTest {

    @InjectMock  // Replaces the CDI bean with Mockito mock
    InventoryService inventoryService;

    @Inject
    OrderService orderService;

    @Test
    void testCreateOrder_WhenOutOfStock_Throws() {
        when(inventoryService.checkStock(anyLong()))
            .thenReturn(false);

        assertThrows(
            OutOfStockException.class,
            () -> orderService.create(
                new CreateOrderRequest(1L, BigDecimal.TEN)));
    }
}

// Test profile for specific config
public class IntegrationProfile
        implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
            "app.order.max-per-customer", "3",
            "app.notification.enabled", "false");
    }

    @Override
    public String getConfigProfile() {
        return "integration";
    }
}

@QuarkusTest
@TestProfile(IntegrationProfile.class)
class OrderLimitIntegrationTest {
    // Tests run with max-per-customer=3
    // and notification disabled
}

// @QuarkusIntegrationTest: test the final artifact
@QuarkusIntegrationTest
class OrderNativeIT {
    // Run after `quarkus build -Dquarkus.native.enabled=true`
    // Tests the native binary directly
    // No injection: HTTP requests only

    @Test
    void testHealthEndpoint() {
        given()
            .when()
            .get("/q/health")
            .then()
            .statusCode(200);
    }
}
```

> **Code walkthrough:** @QuarkusTest starts the fullice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> application with Dev Services (PostgreSQL auto-started).
> @TestTransaction rolls back after each test - no cleanup
> scripts needed. @InjectMock replaces the CDI bean in
> the running application context with a Mockito mock.
> @TestProfile overrides config properties for the test
> class scope. @QuarkusIntegrationTest runs against the
> compiled artifact (JAR or native) - used for the final
> acceptance test before deployment.

---

### 🎓 Answers by Seniority

**Junior:** "@QuarkusTest for integration tests with
full context. Dev Services auto-start the database.
@TestTransaction for automatic rollback."

**Senior:** "@InjectMock for service mocking. @TestProfile
for config-specific test scenarios. Continuous Testing


---

### 📘 Concept Explanation

**What it is:** Quarkus Continuous Testing (CT) runs tests automatically in
dev mode whenever code changes, using test impact analysis to run only tests
affected by the changed code. It integrates with the Quarkus live coding
infrastructure so tests run in the same JVM as the running application, sharing
the same ArC context and Dev Services.

**Mechanism:** When a class changes in dev mode:
1. Quarkus determines which test classes depend on the changed class via
   class dependency analysis.
2. Only the impacted test classes are compiled and re-executed.
3. Results appear in the console (pass/fail counts) and the Dev UI at
   `/q/dev-ui/continuous-testing`.
4. Tests use `@QuarkusTest` which starts the application context once per
   JVM and keeps it running between test method executions - no application
   restart per test class.

**Trade-off:**

**Positive:** Instant test feedback without manual test runs. Test results
appear within 1-3 seconds of code changes. Reduces context switching.

**Negative:** CT runs in-process - a poorly written test can affect other tests
or the dev mode application. CT may not catch issues that only appear in a fresh
JVM start.

**Production Reality:** Continuous Testing shifts testing left to the code
writing phase. Teams using CT consistently catch regressions before committing,
reducing CI pipeline failures by 30-50% in practice.

**Decision:** Enable CT with `quarkus.test.continuous-testing=enabled` for all
Quarkus projects with `@QuarkusTest` test suites. Disable CT
(`quarkus.test.continuous-testing=disabled`) for projects with slow integration
tests that would degrade the dev mode experience.

---

### ⚠️ Common Misconceptions

**Misconception 1: Continuous Testing requires a separate process**
**Reality:** CT runs INSIDE the dev mode JVM, sharing the same ArC application
context. Tests execute in the same JVM that serves HTTP requests. This is
faster than a separate test JVM but means test isolation is weaker (shared
application state between tests).

**Misconception 2: All tests run on every code change**
**Reality:** Quarkus CT uses test impact analysis to identify which tests depend
on the changed class. Only affected tests rerun. This makes CT practical even
for large test suites - a change to a utility class only reruns tests that import
that class.

**Misconception 3: Continuous Testing replaces CI test runs**
**Reality:** CT uses a running dev mode context (Dev Services, dev configuration).
CI runs use a clean environment, fresh JVM, and production-like config. CT catches
development-phase regressions; CI catches environment-sensitive issues. Both are
necessary.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Tests pass in CT but fail in CI**
**Symptom:** All tests green in dev mode CT but same tests fail in
`./mvnw verify` or CI.
**Diagnosis:** CT shares the already-started dev mode application context.
CI starts a fresh JVM. Differences: startup order, resource initialization,
Dev Services vs real infrastructure, leftover state from previous test.
**Fix:** Check for test ordering dependencies (test B depends on state from
test A). Add `@TestTransaction` to reset DB state. Verify CI uses the same
database image version as Dev Services.

**Failure 2: CT not detecting changes in some files**
**Symptom:** Code change made but CT does not rerun affected tests.

**Diagnosis:** Files outside `src/main/java` and `src/test/java` (e.g., SQL
migration files, `application.properties`) may not trigger CT. CT impact
analysis covers Java class dependencies only.
**Fix:** Press `r` in dev console to force full test rerun. For resource file
changes, a manual full test run (`./mvnw test`) is required.

with test impact analysis: only affected tests rerun
on code change."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | @QuarkusTest, @InjectMock, @TestProfile |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Continuous Testing starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Continuous Testing-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Continuous Testing, Q2)

For Quarkus Continuous Testing specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Continuous Testing, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Continuous Testing? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Continuous Testing, not just the benefits.

Quarkus Continuous Testing is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Continuous Testing, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Continuous Testing, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Continuous Testing fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Continuous Testing in a real production system, not just in isolation.

Quarkus Continuous Testing in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Continuous Testing typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Continuous Testing, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Continuous Testing affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Continuous Testing configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Continuous Testing.

Critical pre-production checklist for Quarkus Continuous Testing: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Continuous Testing, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Continuous Testing, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Continuous Testing resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Continuous Testing knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Continuous Testing, Q6)

Strong answers for Quarkus Continuous Testing include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Continuous Testing actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Continuous Testing in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Continuous Testing handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Continuous Testing at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Continuous Testing is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Continuous Testing, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Continuous Testing, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Continuous Testing to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (Quarkus Continuous Testing, Q8)

Start with the problem: what existed before Quarkus Continuous Testing and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Continuous Testing: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Continuous Testing and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Continuous Testing at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Continuous Testing beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Continuous Testing expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Continuous Testing, coordinated upgrade windows. (2) Internal shared library for common Quarkus Continuous Testing configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Continuous Testing extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Continuous Testing from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Continuous Testing correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (Quarkus Continuous Testing, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (Quarkus Continuous Testing, Q10)

Testing strategy for Quarkus Continuous Testing: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Continuous Testing starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Continuous Testing-related issues. (Quarkus Continuous Testing, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Continuous Testing, Q11)

For Quarkus Continuous Testing specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Continuous Testing, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Continuous Testing, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Continuous Testing? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Continuous Testing, not just the benefits. (Quarkus Continuous Testing, Q12)

Quarkus Continuous Testing is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Continuous Testing, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Continuous Testing, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Continuous Testing, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - What is the difference between
@QuarkusTest and @QuarkusIntegrationTest?**

*Why they ask:* Understanding test pyramid.

@QuarkusTest:
- Starts Quarkus application in the same JVM as tests.
- Full CDI context: @Inject works in test classes.
- @InjectMock: replace beans with mocks.
- Dev Services: PostgreSQL/Kafka started as Testcontainers.
- Fast startup (no separate process).
- Used for: unit+integration tests during development.

@QuarkusIntegrationTest:
- Tests the compiled artifact (JAR, native binary).
- Separate process: starts the real built artifact.
- No CDI injection in tests.
- Tests via HTTP requests only.
- Tests the same binary that goes to production.
- Used for: final acceptance tests in CI before deploy.

The distinction matters for native image:
@QuarkusTest always runs on JVM. @QuarkusIntegrationTest
runs the native binary. So a test may pass @QuarkusTest
but fail @QuarkusIntegrationTest if the native image
has reflection issues.

```bash
# Run @QuarkusTest (JVM, development)
./mvnw test

# Run @QuarkusIntegrationTest (native binary)
./mvnw verify -Dquarkus.native.enabled=true \
  -Dnative.surefire.skip=false
```

> **Code walkthrough:** This Run @QuarkusIntegrationTest (native binary) example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*What separates good from great:* @QuarkusIntegrationTest
catches native image issues that @QuarkusTest misses.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @QuarkusTest features, continuous testing. |
| Hiring Manager | Fast test feedback loop. |
| Bar Raiser | @QuarkusIntegrationTest, native image testing, test impact analysis. |
| Peer Engineer | "@QuarkusIntegrationTest caught a reflection issue in native. Saved us from a prod incident." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Quarkus Native Build Process

**Interview Weight:** hard - Native builds are a core
Quarkus differentiator. Tested for understanding and
troubleshooting native build failures.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus native image builds use GraalVM's native-image
> tool. The build has two phases: Quarkus augmentation
> (build-time processing, generates reflection config,
> resource config) and GraalVM native-image compilation
> (ahead-of-time compilation to machine code). Enable
> with quarkus.native.enabled=true or -Pnative Maven profile.
> The output: a self-contained native binary, ~100ms
> startup, ~50MB resident memory vs JVM's ~300MB.

**3 minutes (Senior):**

> Build process:
>
> 1. Quarkus Augmentation:
>   BuildStep processors run for all extensions.
>   HibernateOrmProcessor: generates JPA metamodel.
>   ResteasyProcessor: generates REST dispatch code.
>   Produces NativeImageReflectionBuildItem
>     (classes needing reflection at runtime).
>   Produces NativeImageResourceBuildItem
>     (resources to include in binary).
>
> 2. Configuration collection:
>   All NativeImage* build items aggregated.
>   reflect-config.json: reflection config.
>   resource-config.json: resources.
>   proxy-config.json: dynamic proxies.
>   serialization-config.json: serializable classes.
>
> 3. GraalVM native-image compilation:
>   Closed-world analysis: reachability from main().
>   Points-to analysis: which code is actually used.
>   Heap snapshotting: static initializers run at build.
>   Machine code generation: architecture-specific.
>   Output: ./target/app-runner (Linux) or .exe (Windows).
>
> Build time: 3-5 minutes (complex apps up to 10 min).
> Binary size: 50-100MB.
> Startup: 50-100ms.
> Memory: 30-60% less than JVM.
>
> Container build:
>   quarkus.native.container-build=true
>   Builds in a Docker container (UBI Linux).
>   Use when host OS ≠ deployment OS.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus native
image build - how to compile to a native binary."

**(2) First principles:** "Native image = no JVM at
runtime. All code compiled ahead-of-time to machine code."

**(3) Bridge:** "Quarkus native build is like Go's
build process: output a single self-contained binary,
no runtime dependencies."

---

### 💻 Code Example

```java
// Register class for reflection in native image
// Option 1: @RegisterForReflection on the class
@RegisterForReflection  // Include in reflect-config
public class OrderDto {
    // This class is created from JSON via reflection
    // (e.g., external library's ObjectMapper)
    private Long id;
    private String status;
}

// Option 2: @RegisterForReflection targets
@RegisterForReflection(targets = {
    ThirdPartyRequest.class,
    ThirdPartyResponse.class
})
// Applied to any class; targets registered, not the host
public class ThirdPartyIntegration {}

// Option 3: In extension BuildStep (automatic for users)
// Extension automatically registers its types
@BuildStep
public ReflectiveClassBuildItem reflectiveClasses() {
    return ReflectiveClassBuildItem
        .builder(MySerializableClass.class)
        .methods(true)
        .fields(true)
        .build();
}

// Include resources in native image
@BuildStep
public NativeImageResourceBuildItem resources() {
    return new NativeImageResourceBuildItem(
        "config/defaults.json",
        "templates/email.html");
}
```

```bash
# Build native image (requires GraalVM installed)
./mvnw package -Pnative

# Container build (builds inside Docker, for Linux target)
./mvnw package -Pnative \
  -Dquarkus.native.container-build=true

# Run native binary
./target/app-1.0-runner

# Check binary startup time
time ./target/app-1.0-runner &
# Started in 0.052s

# Check memory usage
ps aux | grep app-runner
# RSS ~50MB vs JVM ~300MB

# Build native container image
./mvnw package -Pnative \
  -Dquarkus.native.container-build=true \
  -Dquarkus.container-image.build=true
```

> **Code walkthrough:** @RegisterForReflection marksice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a class to be included in the native image's reflect-config.json.
> Without it, classes created reflectively at runtime
> fail with ClassNotFoundError in native image. Extension
> @BuildStep processors automatically register their
> classes. The container build flag (-Dquarkus.native.container-build=true)
> runs GraalVM inside a Docker container, producing a
> Linux binary suitable for Kubernetes deployment.

---

### 🚨 Failure Modes and Diagnosis

**Build failure: "Class not found" in reflect-config:**
```bash
# Symptom: native binary throws at runtime
# Error: Class com.example.Dto not found

# Fix: add @RegisterForReflection to the class
# Or add to BuildStep:
quarkus.native.additional-build-args=\
  -H:ReflectionConfigurationFiles=custom-reflect.json
```

> **Code walkthrough:** This Or add to BuildStep: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Build failure: "Static initializer uses runtime data":**
```java
// BAD: static field initialized with runtime data
static final DataSource ds = createDataSource();
// native-image runs this at build time -> fails

// GOOD: initialize lazily
private static DataSource ds;
static DataSource getDs() {
    if (ds == null) ds = createDataSource();
    return ds;
}
// Or defer with --initialize-at-run-time:
// -H:InitializeAtRunTime=com.example.LazyClass
```

> **Code walkthrough:** This Or add to BuildStep: example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

---

### 🎓 Answers by Seniority

**Senior:** "Native build: augmentation + GraalVM native-image.
@RegisterForReflection for dynamic class access.
Container build for cross-platform (develop on Mac, deploy
on Linux). Build time ~5 minutes - use JVM mode during
development, native build in CI."

**Staff:** "Native image trade-offs: no JIT means peak
throughput is lower than JVM (10-20%). Benefits: startup,
memory. Perfect for Lambda/FaaS and sidecar containers.


---

### 📘 Concept Explanation

**What it is:** Quarkus native image build uses GraalVM's `native-image` compiler
to compile the entire application (JVM bytecode + all libraries) into a
standalone platform-native executable. The resulting binary has no JVM runtime
dependency, starts in <100ms, and uses 50-100MB RSS vs 300-500MB for JVM mode.

**Mechanism:** GraalVM native image build process:
1. Quarkus augmentation runs first, generating all `reflect-config.json`,
   `resource-config.json`, and proxy classes needed for native compatibility.
2. GraalVM performs closed-world analysis: it traces all reachable code from
   the entry point and includes only reachable code in the binary.
3. Ahead-of-time (AOT) compilation converts reachable JVM bytecode to native
   machine code for the target platform.
4. The binary includes a minimal substrate VM (SubstrateVM) instead of a
   full JVM - enough runtime for GC and thread management.

**Trade-off:**

**Positive:** 50-100x faster startup, 3-5x lower memory at rest.
No JVM installation required in container image.

**Negative:** 5-20 minute build time. Closed-world assumption breaks dynamic
classloading. Lower throughput for CPU-intensive workloads vs JIT-compiled JVM.

**Production Reality:** The 5-20 minute native build is only justified when
startup time or memory density is critical. For most microservices, JVM Quarkus
provides sufficient improvement over Spring Boot at much shorter build times.

**Decision:** Use native image for: serverless functions (cold start SLA < 1s),
extreme memory constraints (<100MB required), or edge deployments. Use JVM mode
for: standard microservices, frequent deployments requiring fast builds, or
CPU-intensive computation.

---

### ⚠️ Common Misconceptions

**Misconception 1: Native image eliminates the JVM entirely**
**Reality:** Native image replaces the JVM JIT compiler and classloader with
SubstrateVM - a minimal runtime that provides GC, thread scheduling, and signal
handling. The binary is NOT bare-metal C code. It still has a runtime, just a
much smaller and faster-starting one.

**Misconception 2: Native image builds on macOS/Windows produce production binaries**
**Reality:** Native image produces binaries for the BUILD platform by default.
macOS builds produce macOS binaries, not Linux binaries. Production containers
need Linux x86_64 binaries. Use the Docker container build:
`./mvnw package -Pnative -Dquarkus.native.container-build=true`.

**Misconception 3: Any JVM library works in Quarkus native image**
**Reality:** Libraries using runtime reflection, dynamic class loading, or
runtime bytecode generation (CGLIB, Java proxies) require explicit configuration.
Quarkus extensions handle this for supported libraries. Unsupported libraries
may work in JVM mode but fail native builds without manual `reflect-config.json`
entries.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Native binary ClassNotFoundException at runtime**
**Symptom:** Works in JVM mode, throws `ClassNotFoundException` or
`NoClassDefFoundError` in native for a specific class.
**Diagnosis:** The class was excluded by closed-world analysis (not reachable)
or needs reflection registration. Check `target/native-image.log` and
`target/reports/used_reflection.json`.
**Fix:** Add `@RegisterForReflection(targets = MyClass.class)` or add to
`META-INF/native-image/reflect-config.json`. For Jackson: annotate DTOs with
`@RegisterForReflection`.

**Failure 2: Native build fails with out-of-memory error**
**Symptom:** GraalVM native image build fails with `java.lang.OutOfMemoryError`
or killed by the OS OOM killer during the build.
**Diagnosis:** GraalVM native image requires 4-8GB RAM for most applications.
Build running in a constrained CI environment (2GB limit) will fail.
**Fix:** Set `quarkus.native.native-image-xmx=8g` in `application.properties`
or increase CI runner memory to 8GB+. For Docker builds, set Docker memory limit
to 8GB: `quarkus.native.container-runtime-options=-m 8g`.

For long-running high-throughput services: JVM with CDS
may be better."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Native build process, @RegisterForReflection, container build |
| Staff | 12 min | Build failures, closed-world constraint, JVM vs native trade-off |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Native Build Process starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Native Build Process-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Or add to BuildStep:, Q2)

For Quarkus Native Build Process specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Or add to BuildStep:, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Native Build Process? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Native Build Process, not just the benefits.

Quarkus Native Build Process is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Or add to BuildStep:, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Or add to BuildStep:, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Native Build Process fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Native Build Process in a real production system, not just in isolation.

Quarkus Native Build Process in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Native Build Process typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Or add to BuildStep:, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Native Build Process affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Native Build Process configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Native Build Process.

Critical pre-production checklist for Quarkus Native Build Process: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Or add to BuildStep:, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Or add to BuildStep:, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Native Build Process resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Native Build Process knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Or add to BuildStep:, Q6)

Strong answers for Quarkus Native Build Process include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Native Build Process actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Native Build Process in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Native Build Process handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Native Build Process at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Native Build Process is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Or add to BuildStep:, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Or add to BuildStep:, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Native Build Process to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (Or add to BuildStep:, Q8)

Start with the problem: what existed before Quarkus Native Build Process and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Native Build Process: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Native Build Process and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Native Build Process at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Native Build Process beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Native Build Process expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Native Build Process, coordinated upgrade windows. (2) Internal shared library for common Quarkus Native Build Process configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Native Build Process extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Native Build Process from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Native Build Process correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (Or add to BuildStep:, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (Or add to BuildStep:, Q10)

Testing strategy for Quarkus Native Build Process: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Native Build Process starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Native Build Process-related issues. (Or add to BuildStep:, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Or add to BuildStep:, Q11)

For Quarkus Native Build Process specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Or add to BuildStep:, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Or add to BuildStep:, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Native Build Process? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Native Build Process, not just the benefits. (Or add to BuildStep:, Q12)

Quarkus Native Build Process is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Or add to BuildStep:, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Or add to BuildStep:, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Or add to BuildStep:, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - How do you diagnose a
ClassNotFoundException in a Quarkus native binary?**

*Why they ask:* Production native image debugging.

```bash
# Step 1: reproduce in JVM mode first
./mvnw package
java -jar target/app-runner.jar
# If this works: native-specific issue

# Step 2: look for @RegisterForReflection hint
# The stack trace usually shows the class name
# Search the codebase for where it's created
grep -r "Class.forName\|newInstance\|invoke"
# Find reflective access points

# Step 3: add explicit reflection config
@RegisterForReflection(targets = {
    MissingClass.class,
    MissingClass.InnerClass.class
})
public class ReflectionRegistration {}

# Step 4: use tracing agent for systematic discovery
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image \
  -jar target/app-runner.jar
# Run integration tests to exercise all code paths
# Generates reflect-config.json automatically

# Step 5: verify in native
./mvnw package -Pnative
./target/app-runner
```

> **Code walkthrough:** This Step 5: verify in native example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Preventive: run @QuarkusIntegrationTest after every
native build in CI. Catches missing reflection config
before production.

*What separates good from great:* Tracing agent as
systematic approach, not guessing.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Native build, @RegisterForReflection. |
| Hiring Manager | Native image for performance. |
| Bar Raiser | Native build pipeline, ClassNotFoundException diagnosis, container build. |
| Peer Engineer | "Tracing agent found 23 missing classes in one run. Saved a week of trial-and-error." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Quarkus Extension Development

**Interview Weight:** hard - Extension development is
advanced. Tested for Staff candidates contributing
to internal frameworks.

---

### 🎯 Model Answer

**30 seconds:**

> A Quarkus extension has two modules: runtime (application
> code and APIs) and deployment (build-time processing,
> @BuildStep processors). The deployment module depends
> on the runtime module and Quarkus core deployment APIs.
> @BuildStep methods process the Jandex index, validate
> config, produce AdditionalBeans, generate code, and
> configure native image. The @Recorder bridges build
> time to runtime init.

**3 minutes (Senior):**

> Extension module structure:
>
> myextension-parent/
>   myextension/ (runtime module)
>     src/main/java/: CDI beans, APIs, services
>     META-INF/quarkus-extension.yaml: metadata
>   myextension-deployment/ (deployment module)
>     src/main/java/:
>       MyExtensionProcessor.java (@BuildSteps)
>       MyExtensionRecorder.java (@Recorder)
>
> Key BuildItem types:
>
> Produce:
>   AdditionalBeanBuildItem: register CDI beans
>   ReflectiveClassBuildItem: reflection config
>   NativeImageResourceBuildItem: include resources
>   GeneratedBeanBuildItem: generated source
>   GeneratedClassBuildItem: generated bytecode
>   ServiceStartBuildItem: ensure startup order
>
> Consume:
>   CombinedIndexBuildItem: Jandex index (all classes)
>   BeanArchiveIndexBuildItem: bean archive
>   ConfigurationBuildItem: validated config
>   ShutdownContextBuildItem: register shutdown hook
>
> @Recorder usage:
>   @Record(RUNTIME_INIT): runs at startup
>   @Record(STATIC_INIT): runs at static init (earlier)
>   @Record(BUILD_TIME): captured as bytecode, runs in image
>
> Dev UI integration:
>   Implement DevUIWebComponentsBuildItem.
>   Custom dashboard shown at http://localhost:8080/q/dev.
>   Show extension-specific status and actions.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about building a Quarkus
extension - adding custom build-time processing to Quarkus."

**(2) First principles:** "Extension = contribute to
augmentation pipeline. Runtime code + build-time code."

**(3) Bridge:** "Quarkus extension is like a Spring
Boot AutoConfiguration but with build-time code that
processes annotations and generates optimized code."

---

### 💻 Code Example

```java
// Extension deployment module:
// src/main/java/.../deployment/MyExtensionProcessor.java

@BuildSteps
public class MyAuditExtensionProcessor {

    // Step 1: scan for @Audited annotations
    @BuildStep
    public void discoverAuditedBeans(
            CombinedIndexBuildItem combinedIndex,
            BuildProducer<AuditedBeanBuildItem>
                auditedBeans) {

        // Scan Jandex index for @Audited methods
        combinedIndex.getIndex()
            .getAnnotations(DotName.createSimple(
                Audited.class.getName()))
            .forEach(annotation -> {
                MethodInfo method =
                    (MethodInfo) annotation.target();
                auditedBeans.produce(
                    new AuditedBeanBuildItem(
                        method.declaringClass().name(),
                        method.name()));
            });
    }

    // Step 2: generate audit interceptor
    @BuildStep
    @Record(ExecutionTime.RUNTIME_INIT)
    public void registerAuditInterceptor(
            List<AuditedBeanBuildItem> auditedBeans,
            MyAuditRecorder recorder,
            BuildProducer<AdditionalBeanBuildItem>
                additionalBeans) {

        // Register the audit service bean
        additionalBeans.produce(
            AdditionalBeanBuildItem.builder()
                .addBeanClass(AuditService.class)
                .setDefaultScope(DotName.createSimple(
                    ApplicationScoped.class.getName()))
                .setUnremovable()
                .build());

        // Record method registry for runtime
        List<String> methodKeys = auditedBeans.stream()
            .map(b -> b.getClassName() + "#"
                + b.getMethodName())
            .collect(Collectors.toList());

        recorder.registerAuditedMethods(methodKeys);
    }

    // Step 3: validate
    @BuildStep
    public void validate(
            List<AuditedBeanBuildItem> auditedBeans,
            BuildProducer<ValidationErrorBuildItem>
                errors) {
        auditedBeans.forEach(b -> {
            // Validate: @Audited only on CDI beans
            // (check if declaring class is a CDI bean)
        });
    }
}

// Custom BuildItem: data carrier between @BuildSteps
public final class AuditedBeanBuildItem
        extends MultiBuildItem {

    private final String className;
    private final String methodName;

    public AuditedBeanBuildItem(
            String className, String methodName) {
        this.className = className;
        this.methodName = methodName;
    }

    // getters...
}

// @Recorder in runtime module
@Recorder
public class MyAuditRecorder {
    public void registerAuditedMethods(
            List<String> methods) {
        // Runs at RUNTIME_INIT
        AuditRegistry.INSTANCE.register(methods);
    }
}
```

> **Code walkthrough:** @BuildSteps marks a class whoseice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> methods are @BuildStep processors. discoverAuditedBeans
> scans the Jandex index for @Audited annotations and
> produces AuditedBeanBuildItems (custom BuildItem carrying
> data). registerAuditInterceptor consumes those items,
> registers the AuditService CDI bean, and records the
> method list for runtime via @Recorder. The @Record
> annotation specifies WHEN the recorder method runs:
> RUNTIME_INIT means at application startup.

---

### 🎓 Answers by Seniority

**Staff:** "Extension = runtime module (user-facing API)
+ deployment module (@BuildStep processors). The deployment
module contributes to augmentation: scan annotations,
produce BuildItems, generate code, configure native image.
@Recorder bridges build-time data to runtime initialization."

**Principal:** "Extensions enable zero-overhead abstractions:
all the framework magic happens at build time. Users
pay zero runtime cost for extension features - the


---

### 📘 Concept Explanation

**What it is:** Quarkus extension development is the process of creating a
new integration between a third-party library and the Quarkus build-time
augmentation framework. An extension consists of two modules: `runtime` (the
library API and runtime adapters, deployed with the application) and `deployment`
(the `@BuildStep` processors that run only during augmentation, not deployed).

**Mechanism:** An extension deployment module contains:
1. `@BuildStep` methods that consume `BuildItem`s from the Quarkus pipeline
   and produce new `BuildItem`s (feature registration, reflection config,
   native image resources).
2. `@Recorder`-annotated classes that record method calls to execute at
   STATIC_INIT or RUNTIME_INIT phase.
3. `BeanArchiveIndexBuildItem` consumers that discover annotated classes.
4. `NativeImageResourceBuildItem` to include resources in native builds.
The `quarkus-extension-maven-plugin` scaffolds the two-module structure and
generates the extension descriptor.

**Trade-off:**

**Positive:** Extensions make any library native-image compatible without
end-user configuration. Extensions enable Dev Services for their library.

**Negative:** Extension development requires deep understanding of the
build pipeline, `BuildItem` API, and native image constraints. The API has
a steep learning curve.

**Production Reality:** Most engineers never write extensions - they use them.
Extension development is for library authors and platform teams integrating
company-internal libraries with Quarkus. Understanding extension internals is
valuable for debugging build failures and contributing to Quarkiverse.

**Decision:** Write an extension when: integrating a company-internal library
with Quarkus for native image support, contributing to Quarkiverse for a popular
library without existing extension, or creating a reusable build-time processor
for code generation across projects.

---

### ⚠️ Common Misconceptions

**Misconception 1: Extension deployment code runs in the application JVM**
**Reality:** Deployment module code runs ONLY in the build tool JVM (Maven/Gradle
during `mvn package`). The deployment JAR is excluded from the final application
artifact. Only the runtime module is deployed. Attempting to use deployment
classes in application code causes `ClassNotFoundException`.

**Misconception 2: Extensions must be in a separate Maven project**
**Reality:** Extension deployment code can live in the same Maven project as the
application using a `deployment` submodule pattern. This is useful for
project-specific code generation, custom build-time validation, or
application-specific synthetic beans.

**Misconception 3: All BuildItems must be created from scratch**
**Reality:** Quarkus provides 200+ built-in `BuildItem` types that extensions
can consume and produce. `ReflectiveClassBuildItem` registers classes for
reflection, `NativeImageResourceBuildItem` includes resources, `FeatureBuildItem`
registers the extension feature name. Extensions build on top of these foundations.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Extension deployment JAR included in runtime artifact**
**Symptom:** Application artifact is unexpectedly large. Startup is slower than
expected. Classes from deployment module accessible at runtime.
**Diagnosis:** Deployment module dependency declared as `compile` scope instead
of `provided` in the runtime module. Check `mvn dependency:tree` for unexpected
deployment module inclusion.
**Fix:** In the runtime module's pom.xml, declare deployment module as
`<scope>provided</scope>`. The `quarkus-extension-maven-plugin` scaffolded
projects do this correctly. Verify with `jar tf target/app.jar | grep deployment`.

**Failure 2: @BuildStep not called during augmentation**
**Symptom:** Extension feature not applied. Build processor methods silently
skipped. Expected `BuildItem` not available to downstream steps.
**Diagnosis:** Build step has an unfulfilled required input `BuildItem`.
Enable `quarkus.log.level=DEBUG` to see step execution. Check if the extension
is listed in `META-INF/quarkus-extension.yaml`.
**Fix:** Verify `META-INF/quarkus-extension.yaml` is present in the deployment
module with correct extension metadata. Ensure the deployment module is a
transitive dependency (via BOM or direct reference).

generated code is as if they wrote it by hand. This
is the fundamental Quarkus design principle."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Extension structure, @BuildStep, @Recorder |
| Principal | 15 min | Custom BuildItems, Gizmo code generation, Dev UI |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Extension Development starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Extension Development-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Extension Development, Q2)

For Quarkus Extension Development specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Extension Development, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Extension Development? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Extension Development, not just the benefits.

Quarkus Extension Development is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Extension Development, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Extension Development, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Extension Development fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Extension Development in a real production system, not just in isolation.

Quarkus Extension Development in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Extension Development typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Extension Development, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Extension Development affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Extension Development configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Extension Development.

Critical pre-production checklist for Quarkus Extension Development: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Extension Development, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Extension Development, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Extension Development resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Extension Development knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Extension Development, Q6)

Strong answers for Quarkus Extension Development include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Extension Development actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Extension Development in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Extension Development handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Extension Development at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Extension Development is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Extension Development, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Extension Development, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Extension Development to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (Quarkus Extension Development, Q8)

Start with the problem: what existed before Quarkus Extension Development and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Extension Development: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Extension Development and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Extension Development at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Extension Development beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Extension Development expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Extension Development, coordinated upgrade windows. (2) Internal shared library for common Quarkus Extension Development configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Extension Development extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Extension Development from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Extension Development correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (Quarkus Extension Development, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (Quarkus Extension Development, Q10)

Testing strategy for Quarkus Extension Development: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Extension Development starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Extension Development-related issues. (Quarkus Extension Development, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Extension Development, Q11)

For Quarkus Extension Development specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Extension Development, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Extension Development, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Extension Development? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Extension Development, not just the benefits. (Quarkus Extension Development, Q12)

Quarkus Extension Development is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Extension Development, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Extension Development, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Extension Development, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[STAFF] Q1 - How do you test a Quarkus extension
BuildStep in isolation?**

*Why they ask:* Extension quality assurance.

Quarkus provides QuarkusUnitTest for extension testing:

```java
// Extension deployment test
class MyAuditExtensionTest {

    @RegisterExtension
    static final QuarkusUnitTest config =
        new QuarkusUnitTest()
            .setArchiveProducer(() ->
                ShrinkWrap.create(JavaArchive.class)
                    .addClasses(
                        AuditedOrderService.class,
                        // Test application using extension
                        OrderService.class))
            .withConfigurationResource(
                "application.properties");

    @Inject
    AuditService auditService;

    @Inject
    AuditedOrderService orderService;

    @Test
    void testAuditInterceptorApplied() {
        orderService.createOrder(
            new CreateOrderRequest(...));

        List<AuditEntry> entries =
            auditService.getEntries();
        assertThat(entries).hasSize(1);
        assertThat(entries.get(0).getMethod())
            .isEqualTo("createOrder");
    }
}

// Test build failure scenario
@RegisterExtension
static final QuarkusUnitTest shouldFail =
    new QuarkusUnitTest()
        .setExpectedException(
            BuildException.class)
        .setArchiveProducer(() ->
            ShrinkWrap.create(JavaArchive.class)
                .addClasses(InvalidUsageClass.class));
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

QuarkusUnitTest creates a mini-application with just
the specified classes and verifies the extension behavior
(or expected build failure).

*What separates good from great:* Testing expected build
failures is as important as testing successful builds.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Extension structure, @BuildStep, @Recorder. |
| Hiring Manager | Internal framework extensions. |
| Bar Raiser | Custom BuildItems, QuarkusUnitTest, build failure testing. |
| Peer Engineer | "Built an @Audited extension. QuarkusUnitTest caught a missing BuildItem dependency before it hit CI." |

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



