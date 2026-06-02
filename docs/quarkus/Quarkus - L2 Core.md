---
layout: default
title: "Quarkus - L2 Core"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 3
permalink: /quarkus/l2-core/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus CDI Scopes and Producers](#quarkus-cdi-scopes-and-producers) | medium |
| 2 | [Quarkus RESTEasy Reactive](#quarkus-resteasy-reactive) | high |
| 3 | [Quarkus Fault Tolerance SmallRye](#quarkus-fault-tolerance-smallrye) | high |
| 4 | [Quarkus Health and Metrics](#quarkus-health-and-metrics) | working |
| 5 | [Quarkus Dev Services](#quarkus-dev-services) | working |

---

# Quarkus CDI Scopes and Producers

**Interview Weight:** medium - CDI scopes and producers
are used in every Quarkus application. Tested for
understanding scope semantics and factory patterns.

---

### 🎯 Model Answer

**30 seconds:**

> CDI scopes define bean instance lifetime. @ApplicationScoped
> is the singleton equivalent with a CDI proxy wrapper.
> @RequestScoped binds to the active request context.
> @Dependent uses the lifetime of its injector. @Produces
> creates beans from factory methods - essential for
> beans you don't own (third-party classes) or beans
> requiring programmatic construction. Qualifiers like
> @Named disambiguate multiple implementations.

**3 minutes (Senior):**

> Scope semantics in depth:
>
> @ApplicationScoped:
>   Backed by a CDI proxy (subclass).
>   Actual instance created lazily on first method call.
>   Proxy always injected; never null.
>   Destroyed on application shutdown.
>
> @Singleton:
>   No proxy (direct reference).
>   Created eagerly at startup.
>   Slightly faster method calls (no proxy hop).
>   Cannot be passivated.
>
> @RequestScoped:
>   Created per HTTP request (or CDI request context).
>   Must activate request context for non-HTTP code.
>   @ActivateRequestContext: activates for a method.
>
> @Dependent:
>   Each injection point gets a fresh instance.
>   Destroyed with the injector bean.
>   Use for: objects with mutable state, non-thread-safe.
>
> @SessionScoped:
>   Per HTTP session. Must be serializable.
>   Use for: user-specific session state.
>
> @Produces:
>   Any method annotated @Produces returns a bean.
>   The return type becomes the bean type.
>   The method's scope annotation = bean's scope.
>   @Disposes: cleanup when @Produces bean is destroyed.
>
> @Qualifier:
>   Custom annotation to disambiguate same-type beans.
>   @Named("primary"), @Named("secondary").
>   Or: custom @Qualifier annotation with attributes.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about bean scopes and
factory methods in Quarkus CDI."

**(2) First principles:** "Scope = how long an instance
lives and how many exist. Producer = how to create
instances that aren't annotated beans."

**(3) Bridge:** "CDI scopes are like object lifetime
policies: Application = singleton, Request = per-request,
Dependent = per-injection."

---

### 💻 Code Example

```java
// Application scoped with qualifier
@ApplicationScoped
@Named("primary")
public class PrimaryNotificationService
        implements NotificationService {
    public void notify(String msg) {
        // Email notification
    }
}

@ApplicationScoped
@Named("sms")
public class SmsNotificationService
        implements NotificationService {
    public void notify(String msg) {
        // SMS notification
    }
}

// Inject specific implementation via qualifier
@ApplicationScoped
public class OrderService {

    @Inject
    @Named("primary")
    NotificationService notification;
    // Gets PrimaryNotificationService
}

// @Produces: factory for third-party beans
@ApplicationScoped
public class ConnectionPoolProducer {

    @ConfigProperty(name="db.jdbc-url")
    String jdbcUrl;

    @ConfigProperty(name="db.pool-size",
                    defaultValue="10")
    int poolSize;

    @Produces
    @ApplicationScoped  // Singleton pool
    DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(jdbcUrl);
        config.setMaximumPoolSize(poolSize);
        return new HikariDataSource(config);
    }

    // Cleanup when @ApplicationScoped pool is destroyed
    void disposeDataSource(
            @Disposes DataSource ds) {
        ((HikariDataSource) ds).close();
    }
}

// @Produces with qualifier
@ApplicationScoped
public class HttpClientProducer {

    @Produces
    @ApplicationScoped
    @Named("orders")  // qualifier
    RestClient ordersClient(
            @ConfigProperty(
                name="services.orders.url")
            String url) {
        return RestClient.newBuilder()
            .baseUri(URI.create(url))
            .build();
    }
}

// @RequestScoped for per-request state
@RequestScoped
public class RequestContext {
    private String traceId =
        UUID.randomUUID().toString();
    private String userId;
    private String tenantId;

    // Available throughout the request
    // Auto-destroyed when request completes
}

// Activate request context programmatically
@ApplicationScoped
public class BackgroundJobService {

    @Inject
    Instance<RequestContext> requestContextInstance;

    @ActivateRequestContext  // Creates request context
    public void runJob(String jobId) {
        // requestContextInstance.get() returns
        // a fresh RequestContext for this method call
        RequestContext ctx =
            requestContextInstance.get();
        ctx.setTraceId(jobId);
        processJob(jobId, ctx);
    }
}
```

> **Code walkthrough:** @Named qualifiers disambiguateice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> two NotificationService implementations - the injection
> point chooses via @Named("primary"). @Produces on
> dataSource() creates a HikariDataSource managed by CDI:
> CDI handles its lifecycle, @Disposes handles cleanup.
> @RequestScoped RequestContext is automatically destroyed
> at request end. @ActivateRequestContext on runJob()
> creates a CDI request context for the method execution,
> enabling @RequestScoped beans inside.

---

### 🎓 Answers by Seniority

**Junior:** "@ApplicationScoped for singleton beans.
@RequestScoped for per-request. @Produces for factory
methods. @Named to select between implementations."

**Senior:** "@ApplicationScoped vs @Singleton: the CDI
proxy in @ApplicationScoped adds interceptor support
and lazy initialization. @Singleton is direct and faster.


---

### 📘 Concept Explanation

**What it is:** CDI scopes define the lifecycle and visibility of bean instances.
Quarkus (via ArC) supports: `@ApplicationScoped` (one instance per app),
`@RequestScoped` (one per HTTP request), `@SessionScoped` (one per HTTP session),
`@Singleton` (one per app, no proxy), and `@Dependent` (new instance per
injection point). Producers (`@Produces`) enable creating beans from non-CDI
types (third-party objects, computed values).

**Mechanism:** ArC generates a proxy class for each normal-scoped bean
(`@ApplicationScoped`, `@RequestScoped`). The proxy intercepts all method calls
and delegates to the contextual instance from the appropriate CDI context.
`@Produces` methods are `BuildStep`-discovered at build time and generate
synthetic beans. `@Disposes` methods register cleanup callbacks triggered when
the scope context is destroyed.

**Trade-off:**

**Positive:** Scope lifecycle guarantees correctness - `@RequestScoped` beans
are always fresh per request, preventing cross-request data leakage.

**Negative:** CDI proxy creation adds one indirection per method call on
normal-scoped beans. For hot-path beans, `@Singleton` avoids this overhead.

**Production Reality:** `@RequestScoped` beans with mutable state are critical
for correctness in concurrent applications. Using `@ApplicationScoped` with
mutable state without synchronization causes race conditions.

**Decision:** Default to `@ApplicationScoped` for stateless services. Use
`@RequestScoped` for beans holding per-request state (user context, transaction
context). Use `@Produces` when creating instances of third-party types that
cannot be annotated (like `ObjectMapper`, `DataSource`).

---

### ⚠️ Common Misconceptions

**Misconception 1: @ApplicationScoped and @Singleton are the same**
**Reality:** Both create one instance per application but with critical
differences. `@ApplicationScoped` creates a CDI proxy that supports lazy
initialization, interceptors, decorators, and CDI events. `@Singleton` is a
direct reference with no proxy - faster access but cannot be lazily initialized
and has limited interceptor support. For most beans, use `@ApplicationScoped`.

**Misconception 2: @RequestScoped works in background threads**
**Reality:** `@RequestScoped` beans are tied to an active CDI RequestContext.
Background threads (scheduled jobs, async tasks) do NOT have an active request
context unless explicitly activated with `@ActivateRequestContext` on the method
or manually via `Arc.container().requestContext().activate()`.

**Misconception 3: @Produces methods create new instances every time**
**Reality:** `@Produces` method scope is determined by the producer's own scope
annotation. A `@Produces @ApplicationScoped` method is called ONCE and the result
is shared. A `@Produces @Dependent` method is called once per injection point.
Without a scope annotation, `@Dependent` is the default.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: NullPointerException from @RequestScoped bean in async code**
**Symptom:** `ContextNotActiveException: RequestContext is not active` or NPE
when accessing a `@RequestScoped` bean from a background thread, CompletableFuture,
or Vert.x event handler.
**Diagnosis:** The calling thread has no active CDI request context. Confirm
with `Arc.container().requestContext().isActive()`.
**Fix:** Annotate the async method with `@ActivateRequestContext`. Or use
`Arc.container().requestContext().activate()` / `.terminate()` for manual
context management in async boundaries.

**Failure 2: Memory leak from @Dependent beans not disposed**
**Symptom:** Memory grows over time. Heap dump shows many instances of a
`@Dependent`-scoped bean accumulating.
**Diagnosis:** `@Dependent` beans injected into `@Singleton` beans are created
once per injection and NEVER destroyed (the singleton never goes out of scope).
Check injection points where `@Dependent` beans are injected into singletons.
**Fix:** Change the injected bean scope to `@ApplicationScoped`, or use
`Instance<T>` for programmatic bean lookup with explicit `destroy()` calls.

@Produces with @Disposes is the correct CDI pattern for
resources that need cleanup."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Scope semantics, @Produces, @Disposes |
| Staff | 8 min | @Dependent scope, Instance<T>, @ActivateRequestContext |

---

---

---

**[MID] Q8 - [DEBUGGING] Production service using Quarkus CDI Scopes and Producers starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus CDI Scopes and Producers-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last.

For Quarkus CDI Scopes and Producers specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation.

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q9 - [TRADE-OFF] What are the key trade-offs of Quarkus CDI Scopes and Producers? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus CDI Scopes and Producers, not just the benefits.

Quarkus CDI Scopes and Producers is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance.

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity.

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[MID] Q2 - [DEBUGGING] Production service using Quarkus CDI Scopes and Producers starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus CDI Scopes and Producers-related issues. (Quarkus CDI Scopes and Produce, Q2)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus CDI Scopes and Produce, Q2)

For Quarkus CDI Scopes and Producers specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus CDI Scopes and Produce, Q2)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus CDI Scopes and Produce, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus CDI Scopes and Producers? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus CDI Scopes and Producers, not just the benefits. (Quarkus CDI Scopes and Produce, Q3)

Quarkus CDI Scopes and Producers is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus CDI Scopes and Produce, Q3)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus CDI Scopes and Produce, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus CDI Scopes and Produce, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus CDI Scopes and Producers fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus CDI Scopes and Producers in a real production system, not just in isolation.

Quarkus CDI Scopes and Producers in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus CDI Scopes and Producers typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion).

*What separates good from great:* Recognizing that architectural decisions made for Quarkus CDI Scopes and Producers affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus CDI Scopes and Producers configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus CDI Scopes and Producers.

Critical pre-production checklist for Quarkus CDI Scopes and Producers: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents.

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured.

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus CDI Scopes and Producers resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus CDI Scopes and Producers knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome).

Strong answers for Quarkus CDI Scopes and Producers include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus CDI Scopes and Producers actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus CDI Scopes and Producers in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus CDI Scopes and Producers handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus CDI Scopes and Producers at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus CDI Scopes and Producers is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes.

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern).

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

**[SENIOR] Q1 - When should you use Instance<T>
instead of direct @Inject?**

*Why they ask:* Dynamic bean resolution pattern.

Direct @Inject: injected at startup. Fixed reference.
Cannot be null (unless @Dependent or not found).

Instance<T>: programmatic bean resolution at runtime.
Can list all implementations. Can resolve with qualifiers.

Use cases for Instance<T>:
1. Optional beans: Instance.isResolvable()
2. Multiple implementations: Instance.iterator()
3. Programmatic qualifier selection
4. Avoiding circular dependencies

```java
@ApplicationScoped
public class NotificationRouter {

    @Inject
    @Any  // Inject all implementations
    Instance<NotificationService> allServices;

    public void notifyAll(String message) {
        // Iterate all NotificationService beans
        for (NotificationService svc : allServices) {
            try {
                svc.notify(message);
            } catch (Exception e) {
                log.warn("Notification failed", e);
            }
        }
    }

    public void notifyByChannel(
            String channel,
            String message) {
        // Select by qualifier at runtime
        Instance<NotificationService> selected =
            allServices.select(
                new Named.Literal(channel));
        if (selected.isResolvable()) {
            selected.get().notify(message);
        }
    }
}
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

*What separates good from great:* Instance<T> with
@Any for discovering all implementations dynamically.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | CDI scopes, @Produces, qualifiers. |
| Hiring Manager | CDI for flexible service composition. |
| Bar Raiser | Instance<T>, @ActivateRequestContext, @Disposes cleanup. |
| Peer Engineer | "Instance<T> with @Any let us add new notification channels without modifying the router." |

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


# Quarkus RESTEasy Reactive

**Interview Weight:** high - RESTEasy Reactive is
the primary HTTP layer in Quarkus. Tested for route
annotations, reactive return types, and performance.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus RESTEasy Reactive uses Vert.x's event loop
> for non-blocking HTTP. Standard JAX-RS annotations:
> @Path, @GET, @POST, @QueryParam, @PathParam. Return
> types: plain objects (marshaled to JSON), Uni<T>
> (SmallRye Mutiny - async single), Multi<T> (stream).
> I/O endpoints must be non-blocking (return Uni/Multi
> or annotate @Blocking). Validation: @Valid on @RequestBody.
> Exception mapping: @ServerExceptionMapper.

**3 minutes (Senior):**

> RESTEasy Reactive vs Classic:
>
> Classic: executes on worker thread pool.
>   Blocking JDBC safe by default.
>   Throughput limited by thread pool size.
>
> Reactive: executes on Vert.x event loop.
>   Non-blocking: return Uni<T>/Multi<T>.
>   Blocking code MUST be annotated @Blocking.
>   Higher throughput for I/O-bound workloads.
>
> Reactive types (Mutiny):
>   Uni<T>: single async result (Mono equivalent).
>   Multi<T>: stream of async results (Flux equivalent).
>   Multi.createFrom().emitter(): hot stream.
>
> Content negotiation:
>   @Produces(MediaType.APPLICATION_JSON): default.
>   @Produces(MediaType.TEXT_EVENT_STREAM): SSE.
>   @Produces(MediaType.APPLICATION_NDJSON): streaming JSON.
>
> Parameter binding:
>   @PathParam: URL path variable
>   @QueryParam: query string parameter
>   @HeaderParam: request header
>   @CookieParam: cookie value
>   @BeanParam: POJO aggregating multiple params
>   @RequestBody or method body param: request body
>
> Exception handling:
>   @ServerExceptionMapper: maps exceptions to responses.
>   Global: on a class.
>   Local: on an endpoint class (overrides global).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus's HTTP
layer - how to define REST endpoints."

**(2) First principles:** "REST API = URL + HTTP method
→ handler. Parameters from URL, query, body, headers."

**(3) Bridge:** "RESTEasy Reactive is Spring @RestController +
WebFlux combined, using JAX-RS annotations instead
of Spring @GetMapping."

---

### 💻 Code Example

```java
@Path("/api/v1/orders")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OrderResource {

    @Inject
    OrderService orderService;

    // Non-blocking: returns Uni<T>
    @GET
    @Path("/{id:\\d+}")
    public Uni<Response> findById(
            @PathParam("id") Long id,
            @QueryParam("customerId") Long customerId) {
        return orderService.findById(id, customerId)
            .onItem()
            .transform(order ->
                Response.ok(OrderDto.from(order))
                    .build())
            .onFailure(NotFoundException.class)
            .recoverWithItem(
                Response.status(404).build());
    }

    // Paged list
    @GET
    public Uni<List<OrderDto>> list(
            @QueryParam("status")
                @DefaultValue("PENDING") String status,
            @QueryParam("page")
                @DefaultValue("0") int page,
            @QueryParam("size")
                @DefaultValue("20") int size) {
        return orderService.list(status, page, size)
            .map(OrderDto::from)
            .collect()
            .asList();
    }

    // Create: returns 201 Created
    @POST
    @ResponseStatus(201)
    public Uni<OrderDto> create(
            @Valid @RequestBody
            CreateOrderRequest request) {
        return orderService.create(request)
            .map(OrderDto::from);
    }

    // Streaming: Server-Sent Events
    @GET
    @Path("/stream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @SseElementType(MediaType.APPLICATION_JSON)
    public Multi<OrderDto> streamOrders() {
        return orderService.streamNewOrders()
            .map(OrderDto::from);
    }

    // Blocking: JDBC endpoint
    @GET
    @Path("/report")
    @Blocking  // Runs on worker thread
    public ReportDto getReport(
            @QueryParam("date") LocalDate date) {
        // Blocking JDBC call safe here
        return reportService.generate(date);
    }

    // Exception mapper (local)
    @ServerExceptionMapper
    public Response handleValidationException(
            ConstraintViolationException ex) {
        return Response.status(400)
            .entity(ValidationError.from(ex))
            .build();
    }
}
```

> **Code walkthrough:** findById returns Uni<Response>ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> for non-blocking execution. .onFailure(NotFoundException.class)
> .recoverWithItem() handles the 404 case reactively
> without try-catch. @Blocking on getReport() moves
> execution to the worker thread pool - the event loop
> delegates and continues with other requests. The
> streaming endpoint uses Multi<T> with SERVER_SENT_EVENTS
> content type - each emitted item is sent as an SSE event.

---

### ⚖️ Comparison Table

| Feature | RESTEasy Reactive | Spring WebFlux |
|---|---|---|
| HTTP annotations | JAX-RS (@GET, @Path) | Spring (@GetMapping, @PostMapping) |
| Reactive type | Mutiny Uni/Multi | Reactor Mono/Flux |
| Event loop | Vert.x | Netty |
| Non-blocking default | Yes (event loop) | Yes |
| Blocking annotation | @Blocking | Schedulers.boundedElastic() |
| JSON | Jackson/JSONB | Jackson |
| SSE | @SseElementType | MediaType.TEXT_EVENT_STREAM |

---

### 🎓 Answers by Seniority

**Junior:** "@Path, @GET, @POST for routes. Return Uni<T>
for async. @PathParam, @QueryParam for parameters."

**Senior:** "RESTEasy Reactive runs on the Vert.x event
loop. Blocking I/O without @Blocking starves the event
loop. For JDBC: either use Reactive JDBC (R2DBC-style)


---

### 📘 Concept Explanation

**What it is:** RESTEasy Reactive is Quarkus's JAX-RS implementation built on
the Vert.x reactive event loop. Unlike traditional RESTEasy (which blocks a
thread per request), RESTEasy Reactive processes HTTP requests on the Vert.x
I/O thread and returns `Uni<T>` or `Multi<T>` for non-blocking responses. It
supports both reactive and blocking code via annotations.

**Mechanism:** Each incoming HTTP request is dispatched to the Vert.x event loop
thread. If the endpoint method returns a `Uni<T>` (Mutiny), RESTEasy Reactive
subscribes to it non-blocking. If the method is annotated `@Blocking`, RESTEasy
Reactive dispatches execution to a worker thread pool. Route matching, parameter
binding, and response serialization are all pre-computed at build time by the
RESTEasy Reactive extension.

**Trade-off:**

**Positive:** Eliminates thread-per-request overhead. One event loop thread can
serve thousands of concurrent requests with non-blocking I/O.

**Negative:** Blocking code on event loop threads blocks all requests serviced
by that thread. Reactive programming model (Mutiny) has a steeper learning
curve than synchronous JAX-RS.

**Production Reality:** A RESTEasy Reactive service with Hibernate Reactive
(fully non-blocking) can serve 10-50x more concurrent requests per CPU than
traditional blocking JAX-RS with the same response time SLA.

**Decision:** Use RESTEasy Reactive for new Quarkus applications. Use
`@Blocking` for endpoints with blocking I/O (JDBC, file I/O) until fully
reactive stack is available. Return `Uni<T>` for async endpoints.

---

### ⚠️ Common Misconceptions

**Misconception 1: @Path methods must return Uni/Multi to be reactive**
**Reality:** RESTEasy Reactive supports BOTH reactive (Uni/Multi return) and
blocking (synchronous return with @Blocking) endpoints on the same application.
A synchronous method without @Blocking on a RESTEasy Reactive route is executed
on the event loop - fine for CPU-only work, but MUST NOT block.

**Misconception 2: RESTEasy Reactive and classic RESTEasy are interchangeable**
**Reality:** RESTEasy Reactive uses different provider and filter interfaces.
`ContainerRequestFilter` is replaced by `ResteasyReactiveContainerRequestFilter`.
Exception mappers are the same interface but behavior differs. Existing RESTEasy
providers must be tested for compatibility when migrating.

**Misconception 3: All RESTEasy Reactive endpoints run on Vert.x I/O threads**
**Reality:** Endpoints returning `Uni<T>` or `Multi<T>` run on the I/O thread
initially but subscribe asynchronously. Endpoints annotated `@Blocking` or
synchronous endpoints run on the worker thread pool. The I/O thread only
dispatches the request; actual processing may occur elsewhere.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Blocking operation on I/O thread - all requests stall**
**Symptom:** Quarkus logs `You have attempted to do a blocking operation on an
I/O thread` and all requests to the service time out.
**Diagnosis:** A RESTEasy Reactive endpoint calls a blocking operation (JDBC,
`Thread.sleep`, blocking HTTP client) on the Vert.x event loop thread.
**Fix:** Annotate the endpoint method with `@Blocking` to dispatch to worker
thread pool. Or migrate the blocking I/O to reactive (Hibernate Reactive,
Mutiny-based HTTP client).

**Failure 2: Uni subscription never completes - request hangs forever**
**Symptom:** HTTP requests to reactive endpoints never return. No error logged.

**Diagnosis:** The `Uni<T>` returned by the endpoint never emits an item or
failure. Check if the reactive chain has an unsubscribed upstream (a `Uni` that
depends on an external trigger that never fires).
**Fix:** Add a timeout: `.ifNoItem().after(Duration.ofSeconds(10)).fail()`.
Check all async operations in the chain have completion handlers.

or annotate @Blocking. Mutiny Uni is Reactor Mono with
different API."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Reactive vs classic, Uni/Multi, @Blocking |
| Staff | 10 min | Event loop model, backpressure, SSE streaming |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus RESTEasy Reactive starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus RESTEasy Reactive-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus RESTEasy Reactive, Q2)

For Quarkus RESTEasy Reactive specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus RESTEasy Reactive, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus RESTEasy Reactive? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus RESTEasy Reactive, not just the benefits.

Quarkus RESTEasy Reactive is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus RESTEasy Reactive, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus RESTEasy Reactive, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus RESTEasy Reactive fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus RESTEasy Reactive in a real production system, not just in isolation.

Quarkus RESTEasy Reactive in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus RESTEasy Reactive typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus RESTEasy Reactive, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus RESTEasy Reactive affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus RESTEasy Reactive configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus RESTEasy Reactive.

Critical pre-production checklist for Quarkus RESTEasy Reactive: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus RESTEasy Reactive, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus RESTEasy Reactive, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus RESTEasy Reactive resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus RESTEasy Reactive knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus RESTEasy Reactive, Q6)

Strong answers for Quarkus RESTEasy Reactive include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus RESTEasy Reactive actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus RESTEasy Reactive in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus RESTEasy Reactive handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus RESTEasy Reactive at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus RESTEasy Reactive is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus RESTEasy Reactive, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus RESTEasy Reactive, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus RESTEasy Reactive to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply.

Start with the problem: what existed before Quarkus RESTEasy Reactive and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus RESTEasy Reactive: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus RESTEasy Reactive and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus RESTEasy Reactive at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus RESTEasy Reactive beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus RESTEasy Reactive expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus RESTEasy Reactive, coordinated upgrade windows. (2) Internal shared library for common Quarkus RESTEasy Reactive configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus RESTEasy Reactive extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus RESTEasy Reactive from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus RESTEasy Reactive correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load).

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?).

Testing strategy for Quarkus RESTEasy Reactive: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus RESTEasy Reactive starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus RESTEasy Reactive-related issues. (Quarkus RESTEasy Reactive, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus RESTEasy Reactive, Q11)

For Quarkus RESTEasy Reactive specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus RESTEasy Reactive, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus RESTEasy Reactive, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus RESTEasy Reactive? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus RESTEasy Reactive, not just the benefits. (Quarkus RESTEasy Reactive, Q12)

Quarkus RESTEasy Reactive is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus RESTEasy Reactive, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus RESTEasy Reactive, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus RESTEasy Reactive, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - How do you migrate a Spring
@RestController to RESTEasy Reactive?**

*Why they ask:* Migration scenario.

Annotation mapping:
```java
// Spring                    Quarkus RESTEasy Reactive
// @RestController           @Path on class
// @GetMapping("/orders")    @GET + @Path("/orders")
// @PostMapping              @POST
// @PutMapping               @PUT
// @DeleteMapping            @DELETE
// @RequestBody              method body param
// @PathVariable             @PathParam
// @RequestParam             @QueryParam
// @ResponseStatus(201)      @ResponseStatus(201)
// ResponseEntity<T>         Response or Uni<Response>
// @ExceptionHandler         @ServerExceptionMapper

// Spring controller:
@RestController
@RequestMapping("/orders")
public class OrderController {
    @GetMapping("/{id}")
    public ResponseEntity<OrderDto> findById(
            @PathVariable Long id) {
        return orderService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}

// Quarkus equivalent:
@Path("/orders")
@Produces(MediaType.APPLICATION_JSON)
public class OrderResource {
    @GET
    @Path("/{id}")
    public Uni<Response> findById(
            @PathParam("id") Long id) {
        return orderService.findById(id)
            .map(o -> Response.ok(o).build())
            .onFailure(NotFoundException.class)
            .recoverWithItem(
                Response.status(404).build());
    }
}
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

Key difference: error handling. Spring uses Optional
mapped to ResponseEntity. Quarkus uses Mutiny's
.onFailure() chain.

*What separates good from great:* Mutiny's .onFailure()
pattern replaces Spring's try-catch or Optional handling.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | JAX-RS annotations, Uni/Multi, @Blocking. |
| Hiring Manager | REST APIs with Quarkus. |
| Bar Raiser | Event loop model, @Blocking consequences, SSE streaming. |
| Peer Engineer | "Migration took 1 day. Annotation mapping is almost 1:1. The Mutiny reactive chain took a week to get comfortable with." |

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


# Quarkus Fault Tolerance SmallRye

**Interview Weight:** high - Fault tolerance is critical
for production microservices. Tested for the SmallRye
implementation of MicroProfile Fault Tolerance.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus uses SmallRye Fault Tolerance (MicroProfile
> spec) for resilience patterns: @Retry (retry on failure
> with backoff), @Timeout (abort slow calls), @CircuitBreaker
> (prevent cascading failures), @Bulkhead (limit concurrency),
> @Fallback (provide alternative on failure). These
> annotations compose: @Retry + @CircuitBreaker + @Fallback
> on the same method. Applied via CDI interceptors at
> build time (no runtime proxy generation).

**3 minutes (Senior):**

> SmallRye annotations:
>
> @Timeout(500):
>   Abort operation after 500ms.
>   Throws TimeoutException if exceeded.
>   For reactive: set timeout on the Uni.
>
> @Retry(maxRetries=3, delay=500,
>         delayUnit=MILLIS, jitter=100):
>   Retry up to 3 times.
>   500ms base delay + random jitter (100ms).
>   Jitter prevents thundering herd on retry.
>   abortOn: don't retry on specific exceptions.
>   retryOn: only retry these exceptions.
>
> @CircuitBreaker(
>   requestVolumeThreshold=20,
>   failureRatio=0.5,
>   delay=30000):
>   After 20 requests with 50% failure rate:
>   circuit opens for 30 seconds.
>   Requests immediately fail (fast fail).
>   Half-open: 1 probe request to test recovery.
>
> @Bulkhead(value=5, waitingTaskQueue=10):
>   Max 5 concurrent executions.
>   Up to 10 queued. Beyond: BulkheadException.
>
> @Fallback(fallbackMethod="fallbackFindOrder"):
>   If method fails after @Retry: call fallback.
>   Fallback: same return type, same parameters.
>   Fallback class via value=MyFallback.class.
>
> Composition order (important):
>   Fault Tolerance spec defines execution order:
>   Fallback → CircuitBreaker → Bulkhead → Timeout → Retry
>   (outermost to innermost)
>   Retry runs inside CB and Bulkhead.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about fault tolerance
in Quarkus - resilience patterns for service-to-service calls."

**(2) First principles:** "Distributed systems fail
partially. Resilience patterns handle partial failures
gracefully."

**(3) Bridge:** "SmallRye Fault Tolerance annotations
are like annotations on your service method that automatically
handle failures - no boilerplate Hystrix/Resilience4j code."

---

### 💻 Code Example

```java
// Resilient HTTP client
@ApplicationScoped
public class InventoryService {

    @Inject
    @RestClient
    InventoryClient inventoryClient;

    @Retry(
        maxRetries = 3,
        delay = 500,
        delayUnit = ChronoUnit.MILLIS,
        jitter = 100,
        retryOn = {ConnectException.class,
                   TimeoutException.class},
        abortOn = {AuthenticationException.class})
    @CircuitBreaker(
        requestVolumeThreshold = 20,
        failureRatio = 0.5,
        delay = 30,
        delayUnit = ChronoUnit.SECONDS)
    @Timeout(3000)
    @Fallback(fallbackMethod = "fallbackFindItem")
    public InventoryItem findItem(Long productId) {
        return inventoryClient.getItem(productId);
    }

    // Fallback: same signature
    InventoryItem fallbackFindItem(Long productId) {
        // Return cached data or default
        return cache.getOrDefault(
            "product:" + productId,
            InventoryItem.outOfStock());
    }
}

// @Bulkhead: limit concurrent DB connections
@ApplicationScoped
public class HeavyReportService {

    @Bulkhead(
        value = 3,            // Max 3 concurrent
        waitingTaskQueue = 5) // Queue up to 5
    @Timeout(30000)           // 30s per report
    public Report generateHeavyReport(
            ReportConfig config) {
        // CPU-intensive report generation
        // Max 3 running simultaneously
        return reportGenerator.generate(config);
    }
}

// Fallback class pattern
@ApplicationScoped
public class OrderServiceFallback
        implements OrderServiceAPI {

    @Override
    public Uni<Order> findById(Long id) {
        // Circuit open: return empty or cached
        return Uni.createFrom()
            .failure(
                new ServiceUnavailableException(
                    "Order service unavailable"));
        // Caller receives 503
    }
}

// CDI alternative: @AlternativePriority
@Fallback(value = OrderServiceFallback.class)
@CircuitBreaker(requestVolumeThreshold = 10)
@Retry(maxRetries = 2)
@Timeout(2000)
public Uni<Order> findOrder(Long id) {
    return orderClient.findById(id);
}
```

> **Code walkthrough:** The composition on findItem:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Timeout fires if the call takes >3s. Retry retries
> only on network errors (not auth errors). CircuitBreaker
> trips after 50% failure rate in 20 requests - subsequent
> calls fail immediately for 30 seconds without calling
> the inventory service. Fallback fires when all retries
> are exhausted or the circuit is open. @Bulkhead on
> generateHeavyReport limits simultaneous report generation
> to 3 - prevents a report storm from exhausting resources.

---

### 🎓 Answers by Seniority

**Junior:** "@Retry retries failed calls. @CircuitBreaker
opens after too many failures. @Fallback provides an
alternative. Annotations compose on the same method."

**Senior:** "Annotation composition order matters: Fallback
wraps CircuitBreaker wraps Bulkhead wraps Timeout wraps
Retry. Retry runs inside the circuit breaker: retries
count toward the circuit breaker's failure ratio. jitter
prevents thundering herd: if 100 services retry at


---

### 📘 Concept Explanation

**What it is:** Quarkus Fault Tolerance is implemented by SmallRye Fault
Tolerance, the MicroProfile Fault Tolerance spec implementation. It provides
declarative resilience patterns via annotations: `@Retry`, `@Timeout`,
`@CircuitBreaker`, `@Bulkhead`, `@Fallback`, and `@RateLimit`. These intercept
method calls and apply resilience logic transparently.

**Mechanism:** SmallRye Fault Tolerance uses CDI interceptors activated at
build time. When a method annotated with `@Retry` is called:
1. ArC routes the call through the generated fault tolerance interceptor.
2. The interceptor applies retry logic: catches exceptions matching
   `retryOn`, waits `delay` ms (with optional jitter), retries up to `maxRetries`.
3. `@CircuitBreaker` tracks success/failure ratios in a sliding window and
   opens the circuit after `failureRatio` threshold is exceeded.
4. `@Fallback` defines a method called when all retries/circuit-open fail.
State is maintained in memory per interceptor instance.

**Trade-off:**

**Positive:** Declarative resilience with zero boilerplate. Integrates with
Micrometer for circuit breaker state metrics.

**Negative:** Fault tolerance interceptors add call overhead. Retry without
jitter causes thundering herd on downstream services recovering from outage.

**Production Reality:** Circuit breakers prevent cascading failure. Without
a circuit breaker on a slow downstream service, all threads fill with waiting
requests, causing memory pressure and eventual OOM on the caller service.

**Decision:** Use `@Retry` with `jitter` for idempotent operations. Use
`@CircuitBreaker` for all calls to external services. Use `@Timeout` to bound
ALL external calls. Use `@Fallback` for graceful degradation with cached/default
data.

---

### ⚠️ Common Misconceptions

**Misconception 1: @Retry retries on all exceptions by default**
**Reality:** `@Retry` retries on `Exception` by default, but this includes ALL
checked and unchecked exceptions. For HTTP clients, you typically only want to
retry on transient errors (5xx, timeouts) not on client errors (4xx). Configure
`retryOn = {IOException.class, TimeoutException.class}` and `abortOn = {}`
explicitly.

**Misconception 2: Circuit breakers trip immediately on first failure**
**Reality:** Circuit breakers use a rolling window. By default, the circuit
opens after the `failureRatio` (50%) is exceeded within a `requestVolumeThreshold`
(minimum request count, default 20). A single failure does NOT open the circuit.
The minimum 20 requests requirement means low-traffic services may never open
their circuit breaker even with 100% failure rate.

**Misconception 3: @Fallback is always called when a method fails**
**Reality:** `@Fallback` is called when the PRIMARY strategy (after all retries,
after circuit breaker decision) fails. If `@Retry` succeeds on attempt 3,
fallback is NOT called. Fallback is the LAST resort, not an always-on alternative.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Thundering herd after circuit closes**
**Symptom:** After a downstream service recovers, all callers simultaneously
retry causing another overload spike.
**Diagnosis:** `@Retry` with fixed `delay` (no `jitter`) causes all retrying
callers to retry at the same moment after the delay period.
**Fix:** Add `jitter` to `@Retry`: `@Retry(delay=500, jitter=250)` spreads
retries across a 250-750ms window. This is CRITICAL for production retry logic.

**Failure 2: CircuitBreaker never opens despite failures**
**Symptom:** Downstream is down but requests keep going through and failing.
Circuit breaker metrics show "closed" state permanently.
**Diagnosis:** `requestVolumeThreshold` (default 20) not reached - the service
has fewer than 20 requests in the rolling window. Check Micrometer metrics
`ft.circuitbreaker.calls.total` for call counts.
**Fix:** Lower `requestVolumeThreshold` for low-traffic services:
`@CircuitBreaker(requestVolumeThreshold=5, failureRatio=0.5)`.

500ms exactly, they all hit the downstream at the same
time."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Annotation semantics, composition order |
| Staff | 12 min | Circuit breaker state machine, bulkhead design |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Fault Tolerance SmallRye starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Fault Tolerance SmallRye-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Fault Tolerance SmallR, Q2)

For Quarkus Fault Tolerance SmallRye specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Fault Tolerance SmallR, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Fault Tolerance SmallRye? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Fault Tolerance SmallRye, not just the benefits.

Quarkus Fault Tolerance SmallRye is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Fault Tolerance SmallR, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Fault Tolerance SmallR, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Fault Tolerance SmallRye fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Fault Tolerance SmallRye in a real production system, not just in isolation.

Quarkus Fault Tolerance SmallRye in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Fault Tolerance SmallRye typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Fault Tolerance SmallR, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Fault Tolerance SmallRye affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Fault Tolerance SmallRye configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Fault Tolerance SmallRye.

Critical pre-production checklist for Quarkus Fault Tolerance SmallRye: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Fault Tolerance SmallR, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Fault Tolerance SmallR, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Fault Tolerance SmallRye resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Fault Tolerance SmallRye knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Fault Tolerance SmallR, Q6)

Strong answers for Quarkus Fault Tolerance SmallRye include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Fault Tolerance SmallRye actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Fault Tolerance SmallRye in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Fault Tolerance SmallRye handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Fault Tolerance SmallRye at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Fault Tolerance SmallRye is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Fault Tolerance SmallR, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Fault Tolerance SmallR, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Fault Tolerance SmallRye to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (Quarkus Fault Tolerance SmallR, Q8)

Start with the problem: what existed before Quarkus Fault Tolerance SmallRye and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Fault Tolerance SmallRye: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Fault Tolerance SmallRye and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Fault Tolerance SmallRye at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Fault Tolerance SmallRye beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Fault Tolerance SmallRye expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Fault Tolerance SmallRye, coordinated upgrade windows. (2) Internal shared library for common Quarkus Fault Tolerance SmallRye configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Fault Tolerance SmallRye extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Fault Tolerance SmallRye from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Fault Tolerance SmallRye correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (Quarkus Fault Tolerance SmallR, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (Quarkus Fault Tolerance SmallR, Q10)

Testing strategy for Quarkus Fault Tolerance SmallRye: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Fault Tolerance SmallRye starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Fault Tolerance SmallRye-related issues. (Quarkus Fault Tolerance SmallR, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Fault Tolerance SmallR, Q11)

For Quarkus Fault Tolerance SmallRye specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Fault Tolerance SmallR, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Fault Tolerance SmallR, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Fault Tolerance SmallRye? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Fault Tolerance SmallRye, not just the benefits. (Quarkus Fault Tolerance SmallR, Q12)

Quarkus Fault Tolerance SmallRye is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Fault Tolerance SmallR, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Fault Tolerance SmallR, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Fault Tolerance SmallR, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - What is the circuit breaker state
machine and what triggers each state transition?**

*Why they ask:* Production understanding of circuit breakers.

States:
1. CLOSED: normal operation. Requests go through.
   Track: success/failure ratio in a rolling window.

2. OPEN: circuit tripped. Requests fail immediately.
   Triggered: when failureRatio exceeded in the
   requestVolumeThreshold window.
   Example: @CircuitBreaker(requestVolumeThreshold=20,
   failureRatio=0.5) → opens when 10/20 requests fail.

3. HALF-OPEN: probe state.
   Triggered: after delay period (default 5000ms).
   One request allowed through.
   If success: CLOSED.
   If failure: back to OPEN.

Configuration mapping:
```java
@CircuitBreaker(
    requestVolumeThreshold = 20,  // Rolling window size
    failureRatio = 0.5,           // 50% failure rate to open
    delay = 30000,                // 30s in OPEN state
    successThreshold = 2)         // 2 successes to close
                                  // from HALF-OPEN
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

Metrics: SmallRye exposes Micrometer metrics:
- ft.{method}.circuitbreaker.state: open/closed/half-open
- ft.{method}.circuitbreaker.opened.total: open count

Alert: if circuit opens in production → page the on-call.

*What separates good from great:* HALF-OPEN probe
mechanism and successThreshold configuration.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Retry, @CircuitBreaker, @Fallback, @Bulkhead. |
| Hiring Manager | Resilient service-to-service communication. |
| Bar Raiser | Composition order, jitter, circuit breaker state machine. |
| Peer Engineer | "Added jitter to @Retry. Retry storms on our payments service dropped to zero." |

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


# Quarkus Health and Metrics

**Interview Weight:** working knowledge - Health and
metrics are mandatory for Kubernetes-native services.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus SmallRye Health provides three health endpoints:
> liveness (/q/health/live), readiness (/q/health/ready),
> and startup (/q/health/started). Each maps to a Kubernetes
> probe type. Implement HealthCheck and annotate with
> @Liveness, @Readiness, or @Startup. Micrometer integration
> provides metrics at /q/metrics in Prometheus format.
> Key: readiness should fail until the application is
> truly ready to serve traffic (database connected, warm
> caches). Liveness should fail only when the application
> is stuck and needs a restart.

**3 minutes (Senior):**

> Health check types:
>
> Liveness probe (Kubernetes: restart if down):
>   Intent: "Is the application alive?"
>   Fail: application is deadlocked or permanently broken.
>   Don't fail: transient database outage (would restart
>     too eagerly, causing cascade failure).
>
> Readiness probe (Kubernetes: withhold traffic):
>   Intent: "Can the application serve requests?"
>   Fail: database not connected, cache not warm,
>     downstream service unavailable.
>   Don't fail: startup (use startup probe for that).
>
> Startup probe (Kubernetes: wait for startup):
>   Intent: "Has the application finished initializing?"
>   Fail: application not yet ready.
>   Once passed: Kubernetes switches to liveness/readiness.
>   Useful for: slow-start applications.
>
> Metrics with Micrometer:
>   @Counted: count method invocations.
>   @Timed: time method executions.
>   MeterRegistry injection: custom metrics.
>   /q/metrics: Prometheus-format endpoint.
>   Scraping: configure Prometheus to scrape.
>
> Architecture decision:
>   Liveness + readiness separation prevents cascade restart:
>   If database goes down → readiness fails → traffic removed.
>   Application stays alive → when DB recovers → readiness passes.
>   Without separation: liveness fails → Kubernetes restarts →
>     restart won't help (DB still down) → restart loop.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about health checks and
metrics in Quarkus."

**(2) First principles:** "Three probes, three intents:
alive, ready, starting. Fail the right probe."

**(3) Bridge:** "Health probes are the app's contract with
Kubernetes: 'here's how to know when I need help.'"

---

### 💻 Code Example

```java
// Health checks: correct separation

// LIVENESS: only fail for non-recoverable failures
@Liveness
@ApplicationScoped
public class ApplicationLivenessCheck
        implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        // Only fail if application is truly broken
        // (deadlock, OOM approaching, etc.)
        // NOT for: database timeout (transient)
        return HealthCheckResponse.up("application");
    }
}

// READINESS: fail if app can't serve requests
@Readiness
@ApplicationScoped
public class ReadinessCheck
        implements HealthCheck {

    @Inject
    DataSource dataSource;

    @Inject
    KafkaHealthIndicator kafkaHealth;

    @Override
    public HealthCheckResponse call() {
        boolean dbOk = checkDatabase();
        boolean kafkaOk = kafkaHealth.isConnected();

        return HealthCheckResponse
            .named("readiness")
            .status(dbOk && kafkaOk)
            .withData("database", dbOk)
            .withData("kafka", kafkaOk)
            .build();
    }

    private boolean checkDatabase() {
        try (Connection c = dataSource.getConnection()) {
            return c.isValid(1);  // 1s timeout
        } catch (SQLException e) {
            return false;
        }
    }
}

// STARTUP: delay traffic until ready
@Startup
@ApplicationScoped
public class StartupCheck
        implements HealthCheck {

    @Inject
    CacheWarmer cacheWarmer;

    @Override
    public HealthCheckResponse call() {
        boolean cacheReady = cacheWarmer.isWarmed();
        // Once true: Kubernetes never calls this again
        // (switches to liveness + readiness)
        return HealthCheckResponse
            .named("startup")
            .status(cacheReady)
            .withData("cache", cacheReady)
            .build();
    }
}

// METRICS: Micrometer
@ApplicationScoped
public class OrderService {

    @Inject
    MeterRegistry registry;

    private Counter orderCounter;
    private Timer orderTimer;

    @PostConstruct
    void init() {
        orderCounter = Counter.builder("orders.created")
            .tag("env", "prod")
            .description("Orders created")
            .register(registry);

        orderTimer = Timer.builder("orders.duration")
            .description("Order processing time")
            .register(registry);
    }

    public Order createOrder(CreateOrderRequest req) {
        return orderTimer.record(() -> {
            Order order = processOrder(req);
            orderCounter.increment();
            return order;
        });
    }
}

// application.properties
// quarkus.smallrye-health.ui.enable=true
// quarkus.micrometer.export.prometheus.enabled=true
```

> **Code walkthrough:** The liveness check returns UPice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> unconditionally - only override if the application is
> truly stuck. The readiness check verifies database and
> Kafka: if either is down, Kubernetes stops sending traffic
> while the application stays alive. The startup check
> uses cache warm state: the application won't receive
> traffic until the cache is ready (preventing cold-start
> latency spikes on first requests).

---

### 🎓 Answers by Seniority

**Junior:** "Quarkus has three health endpoints: /q/health/live,
/q/health/ready, /q/health/started. Implement HealthCheck
and annotate with @Liveness, @Readiness, or @Startup."

**Senior:** "Liveness/readiness separation is critical:
readiness should fail when the app can't serve (DB down).
Liveness should only fail when the app needs a restart.
Conflating them causes restart loops during transient outages."

---

### ⚖️ Comparison Table

| Probe | Kubernetes Action | Fail Condition |
|---|---|---|
| Liveness | Restart pod | App deadlocked, unrecoverable |
| Readiness | Remove from load balancer | DB down, dependency unavailable |
| Startup | Wait before liveness/readiness | App not initialized yet |

---

### ⚠️ Common Misconceptions

**"Liveness should check all dependencies."**
False. Liveness checks lead to pod restarts. External
dependency failure → pod restart → pod restart again →
restart storm. Only readiness should check external deps.

**"@Readiness automatically covers @Liveness."**
False. They are separate probes checked by separate


---

### 📘 Concept Explanation

**What it is:** Quarkus implements MicroProfile Health for readiness/liveness
probes and MicroProfile Metrics (via Micrometer) for observability. Health
endpoints at `/q/health`, `/q/health/live`, and `/q/health/ready` return JSON
status for Kubernetes probe integration. Metrics are exposed at `/q/metrics`
in Prometheus format.

**Mechanism:** Health checks are CDI beans implementing `HealthCheck` interface
and annotated with `@Liveness` or `@Readiness`. At startup, Quarkus scans for
all health check beans and registers them. On probe request, all registered
checks execute and results are aggregated into an overall `UP`/`DOWN` status.
Micrometer integrates with the Vert.x metrics registry. Extension-provided
meters (JDBC pool size, REST request counts, JVM memory) are auto-registered
by their extensions.

**Trade-off:**

**Positive:** MicroProfile Health provides a standard interface - same bean works
with any Kubernetes health probe or any health check dashboard.

**Negative:** Health check endpoint performs real checks on each call (DB ping,
cache ping). Too many expensive checks can make Kubernetes probes themselves slow.

**Production Reality:** Kubernetes kills pods that fail liveness probes. A
liveness probe that checks database connectivity kills pods during DB maintenance
windows - causing mass restarts. Liveness should ONLY check application-internal
health (deadlocks, heap), not external dependencies.

**Decision:** Liveness probe = check app internal state only. Readiness probe =
check all dependencies (DB, cache, downstream services). Use `@Readiness` for
dependency checks and `@Liveness` for internal checks.

---

### ⚠️ Common Misconceptions

**Misconception 1: Liveness and readiness probes should check the same things**
**Reality:** They serve different Kubernetes purposes. Liveness probe failure
causes a pod RESTART - only use it for unrecoverable internal states (deadlock,
infinite loop). Readiness probe failure removes the pod from load balancer
rotation without restarting it - use it for temporary unavailability (DB down,
warmup). Checking database in liveness causes mass restarts during DB maintenance.

**Misconception 2: Quarkus automatically knows when it is ready**
**Reality:** Quarkus provides a default readiness check for its built-in services
(datasource, Kafka, etc.), but custom application state (warmup cache loaded,
ML model loaded) requires a custom `@Readiness HealthCheck` bean. The pod is
technically `UP` at startup, but if your application needs warmup, a readiness
check gates traffic until warmup completes.

**Misconception 3: Micrometer metrics require separate configuration**
**Reality:** `quarkus-micrometer` with a registry extension (e.g.,
`quarkus-micrometer-registry-prometheus`) auto-registers JVM, system, and
extension metrics with ZERO configuration. Just add the extension and metrics
are available at `/q/metrics`. Custom metrics use `@Inject MeterRegistry`.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Kubernetes mass pod restart during database maintenance**
**Symptom:** All pods restart during planned DB maintenance window. Application
logs show `HealthCheckException: Database is not available`.
**Diagnosis:** Liveness probe is checking database connectivity (via a custom
`@Liveness HealthCheck` that pings DB). Kubernetes interprets DB down as app
unhealthy and restarts all pods.
**Fix:** Move DB connectivity check to `@Readiness`. Liveness should only
check internal app state. `@Readiness` failure removes pod from load balancer
but does NOT restart it.

**Failure 2: Health endpoint times out under load**
**Symptom:** Kubernetes health probe times out. `kubectl describe pod` shows
`Liveness probe failed: HTTP probe failed with statuscode: 000`.
**Diagnosis:** Health check performs expensive DB queries or external calls that
time out under load. The probe timeout (default 1s in Kubernetes) is too short.
**Fix:** Make health checks lightweight (ping query: `SELECT 1`, not full query).
Increase Kubernetes probe `timeoutSeconds`. Or implement caching in the
HealthCheck bean with `@ApplicationScoped` to cache the last result for 10s.

Kubernetes configurations. Both must be configured in
the Deployment spec.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Health endpoint types, basic implementation |
| Senior | 8 min | Liveness/readiness separation, Micrometer metrics |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Health and Metrics starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Health and Metrics-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Health and Metrics, Q2)

For Quarkus Health and Metrics specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Health and Metrics, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Health and Metrics? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Health and Metrics, not just the benefits.

Quarkus Health and Metrics is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Health and Metrics, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Health and Metrics, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Health and Metrics fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Health and Metrics in a real production system, not just in isolation.

Quarkus Health and Metrics in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Health and Metrics typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (Quarkus Health and Metrics, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Health and Metrics affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Health and Metrics configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Health and Metrics.

Critical pre-production checklist for Quarkus Health and Metrics: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (Quarkus Health and Metrics, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (Quarkus Health and Metrics, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Health and Metrics resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Health and Metrics knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (Quarkus Health and Metrics, Q6)

Strong answers for Quarkus Health and Metrics include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Health and Metrics actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Health and Metrics in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Health and Metrics handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Health and Metrics at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Health and Metrics is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (Quarkus Health and Metrics, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (Quarkus Health and Metrics, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Health and Metrics to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (Quarkus Health and Metrics, Q8)

Start with the problem: what existed before Quarkus Health and Metrics and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Health and Metrics: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Health and Metrics and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Health and Metrics at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Health and Metrics beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Health and Metrics expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Health and Metrics, coordinated upgrade windows. (2) Internal shared library for common Quarkus Health and Metrics configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Health and Metrics extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Health and Metrics from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Health and Metrics correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (Quarkus Health and Metrics, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (Quarkus Health and Metrics, Q10)

Testing strategy for Quarkus Health and Metrics: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Health and Metrics starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Health and Metrics-related issues. (Quarkus Health and Metrics, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (Quarkus Health and Metrics, Q11)

For Quarkus Health and Metrics specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (Quarkus Health and Metrics, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (Quarkus Health and Metrics, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Health and Metrics? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Health and Metrics, not just the benefits. (Quarkus Health and Metrics, Q12)

Quarkus Health and Metrics is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (Quarkus Health and Metrics, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (Quarkus Health and Metrics, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (Quarkus Health and Metrics, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - What is the danger of putting
database health in the liveness probe?**

*Why they ask:* Common production mistake.

Scenario: production database goes down.

With DB check in liveness:
1. DB down.
2. Liveness probe fails.
3. Kubernetes: restart all pods.
4. Pods restart: still can't connect (DB still down).
5. Pods keep failing liveness.
6. Kubernetes: restart loop.
7. Result: ALL pods down + restart overhead.
8. DB recovers: pods still restarting.
9. Recovery time: 5-10 minutes.

With DB check in readiness only:
1. DB down.
2. Readiness probe fails.
3. Kubernetes: remove pods from load balancer.
4. Pods: still running, not receiving traffic.
5. DB recovers: readiness passes.
6. Kubernetes: return pods to load balancer.
7. Recovery time: <30 seconds.

The rule: never check external dependencies in liveness.
Liveness = "is this process healthy?"
Readiness = "can this process serve requests?"

*What separates good from great:* "We had a 20-minute
outage from this exact mistake. DB went down, pods
restarted, DB came back but pods were still restarting.
Now liveness is unconditional for all our services."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Liveness, @Readiness, @Startup, HealthCheck. |
| Hiring Manager | Kubernetes-native operations. |
| Bar Raiser | Probe separation, restart storm prevention. |
| Peer Engineer | "Put DB check in liveness once. Never again. 20-minute outage. Readiness only for external deps." |

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


# Quarkus Dev Services

**Interview Weight:** working knowledge - Dev Services
are a major Quarkus productivity feature. Tested for
developer experience knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Dev Services automatically starts Docker containers
> for development and test dependencies (PostgreSQL, MySQL,
> MongoDB, Kafka, Redis, Keycloak, Elasticsearch) when
> no configuration is provided. No Docker Compose files
> needed. Powered by Testcontainers. Activates for %dev
> and %test profiles. Shared across multiple services if
> running simultaneously. Configure via quarkus.datasource.devservices.*
> or disable per-service if you have a real instance running.

**3 minutes (Senior):**

> Dev Services architecture:
>
> Trigger: no quarkus.datasource.jdbc.url configured in %dev profile.
>   Quarkus: automatically starts PostgreSQL container.
>   Injects: JDBC URL, username, password into config.
>   Application: connects to container-managed database.
>
> Powered by Testcontainers:
>   Each Dev Service: a Testcontainers container.
>   Lifecycle: started on quarkus:dev, stopped on exit.
>   Same container: reused across warm reloads.
>   @QuarkusTest: same Dev Services containers (shared lifecycle).
>
> Supported Dev Services (Quarkus 3.x):
>   Databases: PostgreSQL, MySQL, MariaDB, DB2, Oracle, MSSQL.
>   Messaging: Kafka, Pulsar, AMQP (Artemis).
>   Cache: Redis, Infinispan.
>   Security: Keycloak, OIDC (dev mode only).
>   Search: Elasticsearch, OpenSearch.
>   Analytics: MongoDB.
>
> Configuration options:
>   quarkus.datasource.devservices.image-name=postgres:16
>   quarkus.datasource.devservices.enabled=true/false
>   quarkus.datasource.devservices.port=5432
>   quarkus.kafka.devservices.image-name=confluentinc/cp-kafka:7.5
>
> Shared containers:
>   Multiple Quarkus apps in dev mode: share containers.
>   Coordination: Testcontainers RYUK (container lifecycle).
>   Config: quarkus.datasource.devservices.shared=true.
>
> Compose bridge:
>   Docker Compose services: exposed to Quarkus Dev Services.
>   compose.yaml in project root → Dev Services detects.
>   Useful: complex setups needing custom configuration.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus Dev Services
and how they work."

**(2) First principles:** "Quarkus detects missing config →
starts container → injects config. No Docker Compose needed."

**(3) Bridge:** "Dev Services are the Quarkus answer to
'why do I need a Docker Compose file just to develop locally?'"

---

### 💻 Code Example

```properties
# Dev Services: what happens when you DON'T configure

# application.properties (nothing configured for datasource)
# quarkus.datasource.db-kind=postgresql
# (no jdbc.url → Dev Services auto-starts PostgreSQL)

# Quarkus dev mode output:
# 2024-01-01 10:00:00 INFO  [org.tes.DockerClientFactory]
#   Docker host: tcp://localhost:2376
# 2024-01-01 10:00:02 INFO  [io.quarkus.devs.postgres]
#   Dev Services for PostgreSQL started
#   Container id: abc123, listening on:
#   jdbc:postgresql://localhost:55432/postgres
# 2024-01-01 10:00:03 INFO  [io.quarkus.runtime]
#   Quarkus 3.x started in 1.2s

# Container: PostgreSQL started automatically
# Config injected: quarkus.datasource.jdbc.url=...
# You: didn't configure anything
```

```java
// Dev Services with custom image
// application.properties:
// %dev.quarkus.datasource.devservices.image-name=\
//   postgres:16-alpine
// %dev.quarkus.kafka.devservices.image-name=\
//   confluentinc/cp-kafka:7.5

// Integration tests use same Dev Services
@QuarkusTest
class OrderRepositoryTest {

    @Inject
    OrderRepository repo;

    // PostgreSQL: same Dev Services container
    // No setup/teardown needed
    @Test
    void shouldCreateOrder() {
        Order o = new Order("CREATED", BigDecimal.TEN);
        repo.persist(o);
        assertNotNull(o.getId());
    }
}
// @QuarkusIntegrationTest: uses native binary
// Still uses Dev Services (Testcontainers)

// DISABLE: when you have a real instance
// application.properties:
// %dev.quarkus.datasource.devservices.enabled=false
// %dev.quarkus.datasource.jdbc.url=\
//   jdbc:postgresql://localhost:5432/mydb

// SHARED containers (multiple Quarkus services)
// Service A and Service B both in dev mode
// Both use PostgreSQL Dev Service
// %dev.quarkus.datasource.devservices.shared=true
// Result: same container shared
// DB is shared: useful for testing service interaction

// KAFKA Dev Service
// No kafka config → Quarkus starts Kafka container
// application.properties (no kafka config needed):
// quarkus.kafka.devservices.port=9092
// (optional: override port)

// Channel setup:
@Channel("orders-out")
MutinyEmitter<OrderEvent> emitter;
// Kafka Dev Service: Quarkus creates topic auto
```

> **Code walkthrough:** Dev Services completely eliminateice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Docker Compose for development: Quarkus detects missing
> config and starts containers automatically. The @QuarkusTest
> annotation reuses the same Dev Services containers already
> running for dev mode, so tests don't pay container startup
> cost. The shared=true option enables multi-service development
> with shared infrastructure.

---

### 🎓 Answers by Seniority

**Junior:** "Dev Services automatically start Docker containers
for databases, Kafka, Redis, etc. in dev mode. No Docker Compose
needed. Add quarkus-devservices dependencies and remove
the manual infrastructure setup."

**Senior:** "Dev Services use Testcontainers: same container
reused across warm reloads and test runs (fast). For custom
images: override via devservices.image-name. For production-like
testing: disable and use a real instance. For multi-service:
shared=true."

---

### ⚖️ Comparison Table

| Approach | Setup | Container | Tests |
|---|---|---|---|
| Dev Services | None | Auto-started | Shared |
| Docker Compose | compose.yaml | Manual start | Separate |


---

### 📘 Concept Explanation

**What it is:** Quarkus Dev Services automatically starts required infrastructure
(PostgreSQL, MySQL, Kafka, Redis, Elasticsearch, etc.) as Docker containers when
running in Dev Mode or testing, with zero configuration. Dev Services detect
which Quarkus extensions are present (e.g., `quarkus-jdbc-postgresql`) and start
a matching container with auto-configured connection URLs injected into the
application.

**Mechanism:** Each extension with Dev Services support has a
`DevServicesProcessor` that:
1. Detects if the extension is present AND no explicit datasource URL is
   configured (e.g., `quarkus.datasource.jdbc.url` not set).
2. Uses Testcontainers to start a Docker container for the service.
3. Auto-injects the container's connection URL into the config as a
   `BuildItem`, overriding any default placeholders.
4. Reuses containers across restarts (by image+config hash) to avoid slow
   cold starts in dev mode.

**Trade-off:**

**Positive:** Zero-configuration infrastructure for development and testing.
Eliminates "works on my machine" database version mismatches.

**Negative:** Requires Docker daemon. First-time container pull can be slow.
Non-trivial infrastructure (multi-broker Kafka, clustered Redis) may not match
production topology.

**Production Reality:** Dev Services use the same Docker image tag as production
by default (configurable via `quarkus.datasource.devservices.image-name`). This
means dev environment uses the same PostgreSQL version as production - critical
for catching version-specific SQL behavior differences.

**Decision:** Use Dev Services for all local development and CI integration
tests. Pin `devservices.image-name` to the exact production version. Disable
Dev Services (`quarkus.devservices.enabled=false`) only when connecting to a
shared team infrastructure or when the Docker overhead is not acceptable.

---

### ⚠️ Common Misconceptions

**Misconception 1: Dev Services only work in dev mode**
**Reality:** Dev Services ALSO work during `./mvnw test` for integration tests.
Quarkus@QuarkusTest and `@QuarkusIntegrationTest` automatically start Dev
Services for required infrastructure, making tests hermetic without any manual
`@ClassRule` or `@BeforeAll` Docker setup.

**Misconception 2: Dev Services always start a new container per run**
**Reality:** Quarkus Dev Services use container REUSE by default when
`quarkus.test.container.reuse.required=true` (or via Testcontainers reuse flag
in `~/.testcontainers.properties`). The same container is reused across dev mode
restarts and test runs for the same image+config combination, making subsequent
starts instant.

**Misconception 3: Dev Services require Testcontainers license**
**Reality:** Dev Services use the open-source Testcontainers library (Apache
2.0 license). Testcontainers Cloud (paid) is a separate product for CI
environments without Docker. Standard Dev Services only require a local Docker
daemon.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Dev Services fail to start - Docker not available**
**Symptom:** `DevServicesDatasourceProcessor: Could not start devservice for
database. Docker is not available`.
**Diagnosis:** Docker daemon is not running or not accessible. On Windows/Mac:
Docker Desktop may not be started. On Linux: user may not be in `docker` group.
**Fix:** Start Docker Desktop. On Linux: `sudo usermod -aG docker $USER && newgrp
docker`. Alternative: set `quarkus.devservices.enabled=false` and configure a
real datasource URL for environments without Docker.

**Failure 2: Different Dev Services container version than production**
**Symptom:** SQL syntax works in dev/test but fails in production (different
PostgreSQL/MySQL version). Or vice versa.
**Diagnosis:** Dev Services default image may differ from production version.
Check `quarkus.datasource.devservices.image-name` in `application.properties`.
**Fix:** Pin Dev Services to the exact production image:
`quarkus.datasource.devservices.image-name=postgres:15.3`. Keep this in sync
with the Kubernetes deployment image tag.

| Local install | Install scripts | Always running | Always available |
| Testcontainers manual | Java setup code | Per-test | Per-test |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Dev Services concept, how to enable |
| Senior | 7 min | Testcontainers internals, shared containers, config |

---

---

**[MID] Q2 - [DEBUGGING] Production service using Quarkus Dev Services starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Dev Services-related issues.

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (You: didn't configure anything, Q2)

For Quarkus Dev Services specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence.

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (You: didn't configure anything, Q2)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q3 - [TRADE-OFF] What are the key trade-offs of Quarkus Dev Services? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Dev Services, not just the benefits.

Quarkus Dev Services is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not.

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (You: didn't configure anything, Q3)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (You: didn't configure anything, Q3)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

---

**[SENIOR] Q4 - [ARCHITECTURE] How does Quarkus Dev Services fit into a cloud-native microservices architecture? What architectural decisions does it constrain or enable?**

*Why they ask:* Tests whether you can reason about Quarkus Dev Services in a real production system, not just in isolation.

Quarkus Dev Services in a microservices architecture affects: service boundaries (what belongs in the same service vs separate), communication patterns (synchronous vs asynchronous), data management (shared vs service-owned data), and operational concerns (deployment, scaling, observability).

Architectural enablements: Quarkus Dev Services typically makes certain cross-cutting concerns easier (auth, observability, config management) when the ecosystem around it is adopted consistently. The constraint is that partial adoption creates dual maintenance burden.

Integration with Kubernetes: health probes (liveness vs readiness distinction is critical), resource requests/limits (size based on measured usage not estimates), graceful shutdown (SIGTERM handling, in-flight request completion). (You: didn't configure anything, Q4)

*What separates good from great:* Recognizing that architectural decisions made for Quarkus Dev Services affect the entire service mesh, not just the service using it.

---

**[SENIOR] Q5 - [PRODUCTION] What Quarkus Dev Services configurations are most critical to validate before go-live in production? What happens if you miss them?**

*Why they ask:* Tests production readiness awareness - distinguishing nice-to-have from must-have for Quarkus Dev Services.

Critical pre-production checklist for Quarkus Dev Services: resource limits (memory and CPU sized to measured p99 not averages), connection pool sizes (database, HTTP client, message broker connections - undersized pools are the most common production incident cause), timeout values (request timeout, connection timeout, idle timeout aligned with upstream SLAs).

Health check configuration: liveness probe should not check external dependencies (causes cascading restarts), readiness probe SHOULD check critical dependencies (prevents premature traffic routing). This distinction saves on-call engineers hours of debugging during incidents. (You: didn't configure anything, Q5)

Logging and observability: structured JSON logging enabled, correlation IDs propagated, metrics endpoint accessible to Prometheus, distributed tracing configured. (You: didn't configure anything, Q5)

*What separates good from great:* Having a written runbook of the go-live checklist with owner and verification step for each item, rather than relying on individual memory.

---

**[SENIOR] Q6 - [BEHAVIORAL] Tell me about a specific situation where your knowledge of Quarkus Dev Services resolved a production problem or prevented a significant issue. What was the context, what did you discover, and what was the outcome?**

*Why they ask:* Tests real-world application of Quarkus Dev Services knowledge under pressure, and whether you learn from production experience.

Structure using STAR: Situation (what was the system and the problem), Task (your responsibility), Action (specific technical steps you took), Result (measurable outcome). (You: didn't configure anything, Q6)

Strong answers for Quarkus Dev Services include: specific configuration changes made and why, the diagnostic tool or technique that led to the root cause, a non-obvious insight about how Quarkus Dev Services actually behaves vs. how you expected it to behave, and a process change (monitoring, runbook, test) added afterward to prevent recurrence.

If you have not used Quarkus Dev Services in production: describe a deliberate investigation you conducted - a proof of concept, a failure mode you tested, or a performance benchmark you ran. Intellectual curiosity counts.

*What separates good from great:* Specific numbers and a clear before/after comparison. 'Latency dropped from 400ms to 50ms' is more credible than 'performance improved greatly'.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a production system where Quarkus Dev Services handles peak load of 10,000 requests/second with 99.9% availability SLA. What does your architecture look like and what are the failure modes?**

*Why they ask:* Tests whether you understand Quarkus Dev Services at scale and can anticipate failure modes before they happen.

At 10,000 RPS: single-instance Quarkus Dev Services is not sufficient; horizontal scaling with load balancer is required. Calculate the required replica count: target_rps / (single_instance_rps * safety_factor). Add 20% headroom for autoscaling lag.

99.9% availability = 8.7 hours downtime/year = ~43 minutes/month. This requires: multi-AZ deployment (no single AZ brings down the service), rolling deployments (zero-downtime updates), circuit breakers (prevent cascade failures from downstream service degradation), and queue buffering for traffic spikes. (You: didn't configure anything, Q7)

Failure modes at scale: connection pool exhaustion (add monitoring alert at 80% pool utilization), GC pressure in JVM mode (profile allocation rate under load), rate limiting on upstream dependencies (implement bulkhead pattern). (You: didn't configure anything, Q7)

*What separates good from great:* Calculating the math (replica count, pool size, timeout values) rather than describing the architecture qualitatively.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain Quarkus Dev Services to a new team member with 1 year of experience. What mental model helps, and what misconceptions do developers typically have about it?**

*Why they ask:* Tests depth of understanding - if you can teach it clearly, you understand it deeply. (You: didn't configure anything, Q8)

Start with the problem: what existed before Quarkus Dev Services and what problem did it solve? This gives the 'why' that makes the 'what' and 'how' memorable. The best mental model is an analogy from everyday experience that maps to the core mechanism.

Common misconceptions developers have about Quarkus Dev Services: assuming it works like a more familiar technology, not understanding which layer it operates at, underestimating configuration requirements, or treating it as a drop-in replacement for something similar when there are behavioral differences.

The key insight that separates understanding from memorization: the design principle behind Quarkus Dev Services and why its creators made that specific design choice. Understanding the design intent lets you predict behavior in edge cases without needing to look it up.

*What separates good from great:* Using a concrete example from the team's actual codebase rather than abstract documentation language.

---

**[STAFF] Q9 - [TRADE-OFF] What are the long-term organizational and maintenance implications of adopting Quarkus Dev Services at scale across a large engineering team? What governance would you establish?**

*Why they ask:* Tests strategic thinking about Quarkus Dev Services beyond the immediate technical decision.

Long-term implications: skill investment (hiring, training, onboarding time increases when Quarkus Dev Services expertise is required), dependency risk (version upgrades, security patches, end-of-life planning), and ecosystem lock-in (how hard is it to migrate away if a better solution emerges?).

Governance to establish: (1) Standardized version policy - all services use the same major version of Quarkus Dev Services, coordinated upgrade windows. (2) Internal shared library for common Quarkus Dev Services configuration patterns, reducing per-team setup time. (3) Metrics baseline - track startup time, memory usage, and error rate per service, alerting on regression.

Decision framework: build vs. adopt - for each Quarkus Dev Services extension or configuration, evaluate: does this provide strategic differentiation, or is it commodity infrastructure that a managed service handles better?

*What separates good from great:* Quantifying the total cost of ownership including engineering hours, not just infrastructure costs.

---

**[SENIOR] Q10 - [HANDS-ON] Walk me through implementing Quarkus Dev Services from scratch in a new service. What are the non-obvious configuration choices that most engineers miss on first implementation?**

*Why they ask:* Tests practical hands-on knowledge - can you actually implement Quarkus Dev Services correctly, not just describe it?

The obvious steps (add dependency, basic configuration) are documented. The non-obvious choices that affect production behavior: timeout configuration (many engineers use defaults that are too long or too short for their use case), retry policies (retrying non-idempotent operations causes duplicate side effects), and resource sizing (defaults are for development, not production load). (You: didn't configure anything, Q10)

Security checklist that is often deferred until too late: secrets management (environment variables vs secrets manager), TLS configuration (hostname verification, certificate rotation), and authorization boundaries (which callers are allowed?). (You: didn't configure anything, Q10)

Testing strategy for Quarkus Dev Services: unit tests with mocked dependencies, integration tests with testcontainers or embedded instances, and a smoke test that validates the specific non-obvious configuration choices were applied correctly.

*What separates good from great:* Having a personal implementation checklist that encodes lessons from previous mistakes.

---

**[MID] Q11 - [DEBUGGING] Production service using Quarkus Dev Services starts logging errors after a deployment. No code changes were made. What is your diagnostic approach and what do you check first?**

*Why they ask:* Tests systematic debugging over guesswork for Quarkus Dev Services-related issues. (You: didn't configure anything, Q11)

Start by checking deployment artifacts: was configuration changed even if code was not? Diff the deployed config against the previous version. Check error logs for stack traces - the first exception in the chain is the root cause, not the last. (You: didn't configure anything, Q11)

For Quarkus Dev Services specifically: verify that all required dependencies and configuration properties are present. Check if the runtime environment (JVM flags, resource limits, external service endpoints) changed between deployments. Enable DEBUG logging temporarily to see detailed initialization sequence. (You: didn't configure anything, Q11)

Use health check endpoints to distinguish between startup failure (readiness probe failing) vs runtime failure (liveness probe failing after successful start). Correlate error timestamps with infrastructure events: pod restarts, autoscaling events, downstream service degradation. (You: didn't configure anything, Q11)

*What separates good from great:* Building a timeline of events (deployment time, first error time, scale events) before touching any configuration.

---

**[MID] Q12 - [TRADE-OFF] What are the key trade-offs of Quarkus Dev Services? In what scenarios would you recommend an alternative, and why?**

*Why they ask:* Evaluates architectural judgment and whether you understand the limitations of Quarkus Dev Services, not just the benefits. (You: didn't configure anything, Q12)

Quarkus Dev Services is optimized for specific use cases with clear advantages and constraints. The advantages justify adoption when those use cases apply; the constraints become blockers when they do not. (You: didn't configure anything, Q12)

Key trade-offs: performance vs. operational complexity, developer productivity vs. runtime flexibility, standard APIs vs. vendor-specific features. Each trade-off has a cost in team skill investment, migration risk, and ongoing maintenance. (You: didn't configure anything, Q12)

Recommend alternatives when: the team's existing expertise makes the learning curve ROI negative, when a specific feature requirement is better served by a competing solution, or when the scale of the problem does not justify the added complexity. (You: didn't configure anything, Q12)

*What separates good from great:* Quantifying the trade-off - actual latency numbers, memory difference, or developer hours saved - instead of citing qualitative claims.

**[SENIOR] Q1 - How do Dev Services integrate
with @QuarkusTest vs @QuarkusIntegrationTest?**

*Why they ask:* Test mode differences.

@QuarkusTest (JVM mode tests):
- Starts Quarkus app in-process.
- Dev Services: started alongside (same JVM).
- Container lifecycle: same as dev mode.
- Speed: fast (containers already running).

@QuarkusIntegrationTest (native or JVM binary tests):
- Starts the built binary (native or JVM JAR).
- Dev Services: started by the test process (different JVM).
- Container lifecycle: per test class run.
- Speed: slower (containers started per test class).

Practical difference:
```java
// @QuarkusTest: fast, in-process
@QuarkusTest
class FastUnitTest {
    @Inject
    OrderService service;  // Real injection
    // PostgreSQL: Dev Services started once for all @QuarkusTests
    // Run: milliseconds per test
}

// @QuarkusIntegrationTest: integration test against binary
@QuarkusIntegrationTest
class NativeIntegrationTest {
    // No @Inject: tests via HTTP (RestAssured)
    // PostgreSQL: Dev Services started per test class
    // Run: 5-10s startup per test class
    @Test
    void shouldCreateOrderViHttp() {
        given()
            .body("""{"status":"NEW","amount":100}""")
            .contentType(ContentType.JSON)
        .when()
            .post("/orders")
        .then()
            .statusCode(201);
    }
}
```

> **Code walkthrough:** This concept example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

When to use which:
- @QuarkusTest: business logic, unit-like, fast.
- @QuarkusIntegrationTest: native compatibility, end-to-end.

*What separates good from great:* @QuarkusIntegrationTest
against native binary: this is the native CI gate.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Dev Services config, supported services. |
| Hiring Manager | Developer productivity. |
| Bar Raiser | Testcontainers internals, shared containers. |
| Peer Engineer | "Removed Docker Compose (600 lines). Dev Services + Quarkus. Local setup: git clone + quarkus:dev. Done." |

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



