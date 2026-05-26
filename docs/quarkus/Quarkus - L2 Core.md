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

> **Code walkthrough:** @Named qualifiers disambiguate
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
@Produces with @Disposes is the correct CDI pattern for
resources that need cleanup."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Scope semantics, @Produces, @Disposes |
| Staff | 8 min | @Dependent scope, Instance<T>, @ActivateRequestContext |

---

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

> **Code walkthrough:** findById returns Uni<Response>
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
or annotate @Blocking. Mutiny Uni is Reactor Mono with
different API."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Reactive vs classic, Uni/Multi, @Blocking |
| Staff | 10 min | Event loop model, backpressure, SSE streaming |

---

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

> **Code walkthrough:** The composition on findItem:
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
500ms exactly, they all hit the downstream at the same
time."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Annotation semantics, composition order |
| Staff | 12 min | Circuit breaker state machine, bulkhead design |

---

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

> **Code walkthrough:** The liveness check returns UP
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
Kubernetes configurations. Both must be configured in
the Deployment spec.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Health endpoint types, basic implementation |
| Senior | 8 min | Liveness/readiness separation, Micrometer metrics |

---

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

> **Code walkthrough:** Dev Services completely eliminate
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
| Local install | Install scripts | Always running | Always available |
| Testcontainers manual | Java setup code | Per-test | Per-test |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Dev Services concept, how to enable |
| Senior | 7 min | Testcontainers internals, shared containers, config |

---

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
