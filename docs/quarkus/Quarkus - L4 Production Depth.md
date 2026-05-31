---
layout: default
title: "Quarkus - L4 Production Depth"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 7
permalink: /quarkus/l4-production-depth/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus Native Image Build and Diagnostics](#quarkus-native-image-build-and-diagnostics) | hard |
| 2 | [Quarkus Performance Diagnostics](#quarkus-performance-diagnostics) | hard |
| 3 | [Quarkus Anti-Patterns](#quarkus-anti-patterns) | hard |
| 4 | [Quarkus Security Misconfiguration](#quarkus-security-misconfiguration) | hard |
| 5 | [Quarkus Memory and Startup Optimization](#quarkus-memory-and-startup-optimization) | hard |

---

# Quarkus Native Image Build and Diagnostics

**Interview Weight:** hard - Native image troubleshooting
is a key differentiator for production Quarkus teams.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus native image build failures fall into three
> categories: reflection violations (class not in
> reflect-config), static initializer issues (runtime
> data access at build time), and missing resources.
> Diagnose with: -Dquarkus.native.debug.dump-proxy-classes=true,
> GraalVM tracing agent (runs reflection at JVM mode
> and captures config). Fix: @RegisterForReflection,
> @NativeImageConfig, or --initialize-at-run-time build argument.

**3 minutes (Senior):**

> Native build failure categories:
>
> 1. Reflection violations:
>   Class.forName(), method.invoke() at runtime.
>   Fix: @RegisterForReflection or reflect-config.json.
>   Diagnosis: stack trace shows missing class.
>
> 2. Static initializer violations:
>   Class with static {} block uses runtime services.
>   native-image runs static initializers at build.
>   If they use network, files, or runtime config: fail.
>   Fix: --initialize-at-run-time=com.problematic.Class.
>
> 3. Missing resources:
>   Files loaded from classpath at runtime missing.
>   Fix: NativeImageResourceBuildItem or
>     META-INF/native-image/resource-config.json.
>
> 4. JNI violations:
>   Native library calls in native image.
>   JNI must be registered explicitly.
>   jni-config.json or @RegisterForJni.
>
> 5. Proxy violations:
>   Dynamic java.lang.reflect.Proxy.
>   Fix: proxy-config.json with interface list.
>
> Diagnostic commands:
>
>   # Verbose build (see what's being analyzed)
>   -Dquarkus.native.additional-build-args=
>     -H:+ReportExceptionStackTraces
>
>   # Dashboard with reachability analysis
>   -Dquarkus.native.additional-build-args=
>     -H:+PrintAnalysisCallTree
>
>   # Tracing agent to generate configs automatically
>   java -agentlib:native-image-agent=\
>     config-output-dir=META-INF/native-image \
>     -jar app.jar

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about diagnosing and
fixing native image build failures."

**(2) First principles:** "Native image closed-world:
only reachable code is compiled. Reflection at runtime
breaks the closed-world assumption."

**(3) Bridge:** "Native image diagnosis is like debugging
a compiler error about missing symbols - find what's
used but not declared."

---

### 💻 Code Example

```java
// Common failure pattern and fix

// FAILURE PATTERN 1: Reflection without registration
// Error at runtime: "Type not found: com.example.OrderDto"

// BAD: Jackson uses reflection on OrderDto
// OrderDto not in reflect-config
public class ExternalSerializer {
    public String serialize(Object obj) {
        return objectMapper.writeValueAsString(obj);
        // Fails in native: OrderDto fields not found
    }
}

// GOOD: register for reflection
@RegisterForReflection
public class OrderDto {
    private Long id;
    private String status;
    // Now included in reflect-config
}

// FAILURE PATTERN 2: Static initializer
// Error at build time: "static init failed"

// BAD: reads property in static initializer
public class LegacyService {
    private static final DataSource ds;
    static {
        String url = System.getProperty("db.url");
        // System.getProperty at BUILD TIME = null
        ds = DriverManager.getConnection(url);
        // Fails at build time
    }
}

// GOOD: lazy initialization
public class LegacyService {
    private volatile DataSource ds;
    private DataSource getDs() {
        if (ds == null) {
            synchronized (this) {
                if (ds == null) {
                    ds = createDs();
                }
            }
        }
        return ds;
    }
}

// Or: defer to runtime via config
// quarkus.native.additional-build-args=
//   --initialize-at-run-time=com.legacy.LegacyService

// FAILURE PATTERN 3: Missing resources
// Error: "/config/defaults.json not found"

// Fix: tell native-image to include it
// In src/main/resources/META-INF/native-image/:
// resource-config.json:
// {
//   "resources": {
//     "includes": [{"pattern": "config/.*\\.json"}]
//   }
// }

// Or in Quarkus extension:
@BuildStep
public NativeImageResourceBuildItem resources() {
    return new NativeImageResourceBuildItem(
        "config/defaults.json");
}
```

```bash
# Diagnostic commands

# 1. Verbose native build with exception traces
./mvnw package -Pnative \
  -Dquarkus.native.additional-build-args=\
  -H:+ReportExceptionStackTraces

# 2. Tracing agent: run tests with agent, generates configs
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image \
  -jar target/app-runner.jar

# Then run your integration tests to exercise all paths
# The agent generates:
# reflect-config.json
# resource-config.json
# proxy-config.json
# serialization-config.json

# 3. Build with generated configs
./mvnw package -Pnative
# The configs in META-INF/native-image/ are auto-included

# 4. Heap analysis (for size issues)
./mvnw package -Pnative \
  -Dquarkus.native.additional-build-args=\
  -H:+PrintImageHeapConnectedComponentSizes

# 5. Container build for Linux target
./mvnw package -Pnative \
  -Dquarkus.native.container-build=true
```

> **Code walkthrough:** @RegisterForReflection on OrderDto
> is the most common fix for Jackson serialization issues.
> The static initializer failure happens because native-image
> runs static blocks at build time - a database connection
> at build time fails. The resources fix (resource-config.json)
> tells native-image's closed-world analyzer to include
> the JSON file. The tracing agent is the systematic
> approach: run the application under the agent, exercise
> all code paths, get complete configs automatically.

---

### 🚨 Failure Modes and Diagnosis

**NullPointerException in native at startup:**
```bash
# Check: is it a static init issue?
# -H:+PrintStaticImageHeapRoots shows init chain
# Often: a framework's auto-config class reads props at init

# Fix: defer init
quarkus.native.additional-build-args=\
  --initialize-at-run-time=\
  com.problematic.FrameworkClass
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Binary size too large (>200MB):**
```bash
# Analyze what's included
-H:+PrintAnalysisCallTree
# Look for large reachable class trees
# Often: entire library included due to one class

# Solutions:
# - shade only needed classes
# - quarkus.native.additional-build-args=-H:DeadlockWatchdogInterval=0
# - Profile-guided native (PGO) in GraalVM Enterprise
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎓 Answers by Seniority

**Senior:** "Three failure categories: reflection, static
initializer, missing resources. Tracing agent is the
systematic fix for all three. Run integration tests
under the agent, commit the generated configs."

**Staff:** "Native image build failures are a one-time
setup cost. After the configs are generated and committed,
subsequent builds succeed. The ongoing maintenance:
when adding new libraries. CI should run @QuarkusIntegrationTest
against the native binary on every PR."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Failure categories, @RegisterForReflection, tracing agent |
| Staff | 14 min | Static initializer internals, binary size, container build |

---

**[SENIOR] Q1 - How does the tracing agent help
with native image build failures?**

*Why they ask:* Practical native image workflow.

The tracing agent instruments the JVM to capture every
reflective access during a run:

```bash
# Step 1: Run with agent
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image/com.example/app \
  -jar target/app-runner.jar

# Step 2: Exercise all code paths
# Run integration tests
./mvnw test -Dsurefire.failIfNoSpecifiedTests=false

# Step 3: Agent generates 5 files:
# META-INF/native-image/reflect-config.json
# META-INF/native-image/resource-config.json
# META-INF/native-image/proxy-config.json
# META-INF/native-image/serialization-config.json
# META-INF/native-image/jni-config.json

# Step 4: Build native
./mvnw package -Pnative
# The generated configs are auto-included
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Limitation: agent only captures what's executed in
the test run. If a code path is never tested, its
reflection is not captured. Missing code paths = native
image failure in production.

Best practice:
- 100% integration test coverage before first native build
- Run agent against production traffic (canary) for edge cases

*What separates good from great:* Understanding the
agent's limitation - it only captures what you exercise.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Native image build, tracing agent, failure diagnosis. |
| Hiring Manager | Native image for production. |
| Bar Raiser | Tracing agent workflow, static init internals, container build. |
| Peer Engineer | "Tracing agent reduced native build failures from 8/month to 0. 4-hour setup, permanent fix." |

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


# Quarkus Performance Diagnostics

**Interview Weight:** hard - Performance is a required
topic for Senior+ interviews. Tested for systematic
profiling approach.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus performance diagnostics use: Micrometer metrics
> for request latency and error rates (quarkus-micrometer),
> OpenTelemetry for distributed tracing (span-level timing),
> JVM profiling with async-profiler for CPU hotspots
> and allocation pressure, and GC logs for memory pressure.
> In native mode: perf record for CPU profiling (no JVM
> profiler). Start diagnosis with metrics (P99 latency,
> error rate), drill into traces, profile CPU.

**3 minutes (Senior):**

> Diagnosis stack:
>
> Layer 1: Metrics (Micrometer):
>   http.server.requests: latency by endpoint.
>   http.client.requests: downstream latency.
>   db.query.time: per-query timing.
>   jvm.memory.used: heap usage.
>   Expose at /q/metrics (Prometheus format).
>
> Layer 2: Distributed Tracing (OpenTelemetry):
>   Identify which span is slow.
>   Which DB query? Which downstream call?
>   Add custom spans for suspected hot paths.
>
> Layer 3: CPU Profiling (async-profiler):
>   Attach to running JVM (no restart needed).
>   Flame graph: see CPU hotspots.
>   Allocation profiling: see GC pressure sources.
>
> Layer 4: GC analysis (GC logs):
>   -Xlog:gc*:gc.log
>   Look for: pause times, frequency, heap exhaustion.
>   GC tuning: --gc=G1 vs --gc=Serial (native).
>
> Quarkus-specific metrics:
>   quarkus.http.requests.active: concurrent requests.
>   quarkus.datasource.pool.active: DB pool usage.
>   quarkus.kafka.consumer.lag: Kafka consumer lag.
>
> Hot paths in Quarkus:
>   CDI proxy overhead: small but measurable.
>   JSON serialization: Jackson most common hotspot.
>   DB connection pool exhaustion: increase pool size.
>   Reactive event loop blocking: add @Blocking.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about diagnosing performance
problems in a Quarkus application."

**(2) First principles:** "Performance problem = something
is slow or consuming excessive resources. Measure first,
optimize second."

**(3) Bridge:** "Quarkus performance diagnosis is like
any Java performance work: metrics → traces → profiler.
Tools are different (Micrometer, OpenTelemetry, async-profiler)
but the process is identical."

---

### 💻 Code Example

```java
// Custom Micrometer metric
@ApplicationScoped
public class OrderService {

    @Inject
    MeterRegistry registry;

    // Record custom metrics
    private final Counter ordersCreated;
    private final Timer orderCreationTime;

    public OrderService(MeterRegistry registry) {
        this.ordersCreated = registry.counter(
            "app.orders.created",
            Tags.of("service", "order"));

        this.orderCreationTime = registry.timer(
            "app.orders.creation.time",
            Tags.of("service", "order"));
    }

    @Timed(value = "app.orders.creation.time",
           description = "Time to create order")
    @Counted(value = "app.orders.created",
             description = "Orders created")
    public Order createOrder(
            CreateOrderRequest req) {
        return orderRepo.save(Order.from(req));
    }
}

// Performance diagnosis: query timing
@ApplicationScoped
public class SlowQueryDiagnostics {

    // Find slow queries: enable Hibernate statistics
    // quarkus.hibernate-orm.statistics=true
    // quarkus.hibernate-orm.log.sql=true
    // quarkus.hibernate-orm.log.bind-parameters=true

    public Statistics getHibernateStats() {
        return sessionFactory.getStatistics();
    }

    public void analyzeQueries() {
        Statistics stats =
            sessionFactory.getStatistics();

        log.info("Slow queries (>100ms): {}",
            stats.getQueryExecutionMaxTimeQueryString());
        log.info("Total queries: {}",
            stats.getQueryExecutionCount());

        // Alert: N+1 signature
        // query count >> entity count
    }
}

// Detect event loop blocking (reactive)
// application.properties
// quarkus.vertx.blocked-thread-check-interval=1000
// quarkus.vertx.max-event-loop-execute-time=2000
// Logs warning if event loop blocked > 2s
```

```bash
# Async-profiler: CPU flame graph
# Attach to running Quarkus JVM process
./profiler.sh -d 30 -f flamegraph.html $(pgrep -f app-runner)

# View in browser: flamegraph.html
# Wide bars = hot methods = optimize first

# Allocation profiling (GC pressure)
./profiler.sh -e alloc -d 30 -f alloc.html \
  $(pgrep -f app-runner)

# Micrometer Prometheus scrape
curl http://localhost:8080/q/metrics
# Key metrics:
# http_server_requests_seconds_count{uri="/api/orders"}
# http_server_requests_seconds_bucket{le="0.1"}  (<100ms)
# http_server_requests_seconds_bucket{le="1.0"}  (<1s)
# hikaricp_connections_active  (DB pool usage)

# GC analysis (JVM mode)
java -Xlog:gc*:gc.log \
  -jar target/app-runner.jar

# Analyze with GCViewer or GCEasy
```

> **Code walkthrough:** @Timed and @Counted from Micrometer
> add latency and count metrics to the createOrder method.
> Hibernate statistics expose query execution time and count.
> The N+1 signature: query count >> entity count in Hibernate
> stats (100 queries for 10 orders = N+1). async-profiler
> attaches to the running JVM PID and captures CPU samples
> for 30 seconds - the flame graph shows where CPU time is spent.

---

### 🎓 Answers by Seniority

**Senior:** "Metrics for the what (P99 latency, error rate),
traces for the where (which span is slow), profiler for
the why (CPU hotspot). Start with metrics dashboard,
drill to slow traces, attach profiler when trace shows
a suspicious span."

**Staff:** "Systematic process: establish baseline metrics,
load test under realistic traffic, identify the bottleneck
layer (network, DB, CPU), instrument the hotspot with
custom spans, profile, fix, re-measure. Never optimize
without a measurement before and after."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Metrics, tracing, profiling workflow |
| Staff | 14 min | Systematic approach, reactive performance, GC tuning |

---

**[STAFF] Q1 - How do you diagnose event loop blocking
in a Quarkus reactive application?**

*Why they ask:* Reactive-specific performance issue.

Event loop blocking symptoms:
- P99 latency suddenly high
- All requests slow (not just one endpoint)
- CPU not at 100%
- Quarkus logs: "Thread vertx-eventloop-0 has been
  blocked for 2s"

Diagnosis:
```bash
# Step 1: Check vertx blocked thread logs
grep "has been blocked" app.log
# Shows method that blocked the event loop

# Step 2: Thread dump
kill -3 $(pgrep -f app-runner)
# Look for: io.vertx.core.impl.VertxImpl lambda
# in BLOCKED or TIMED_WAITING state

# Step 3: Async profiler
./profiler.sh -e wall -d 30 \
  -f wall-flamegraph.html $(pgrep -f app-runner)
# -e wall: wall clock (includes blocked time)
# Blocked method appears wide in the flamegraph
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fixes:
1. Identify blocking call (JDBC, file I/O, sleep).
2. Annotate method with @Blocking.
3. Or convert to reactive (PanacheReactiveRepository).

```java
// BAD: blocking JDBC on event loop
@GET
@Path("/{id}")
public Order findById(@PathParam("id") Long id) {
    return Order.findById(id);  // JDBC blocks event loop
}

// GOOD option 1: annotate @Blocking
@GET
@Path("/{id}")
@Blocking  // Move to worker thread pool
public Order findById(@PathParam("id") Long id) {
    return Order.findById(id);
}

// GOOD option 2: reactive
@GET
@Path("/{id}")
public Uni<Order> findById(@PathParam("id") Long id) {
    return orderReactiveRepo.findById(id);
    // Non-blocking reactive query
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Wall-clock profiling
(not CPU) to find blocking - CPU profiler misses blocked
thread time.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Micrometer metrics, profiling tools. |
| Hiring Manager | Performance for production services. |
| Bar Raiser | Event loop blocking diagnosis, wall-clock profiling. |
| Peer Engineer | "async-profiler -e wall found a Thread.sleep() in a library. Added @Blocking. P99 dropped from 3s to 50ms." |

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


# Quarkus Anti-Patterns

**Interview Weight:** hard - Anti-patterns show production
maturity. Tested for Senior/Staff candidates.

---

### 🎯 Model Answer

**30 seconds:**

> Common Quarkus anti-patterns: blocking the event loop
> (calling JDBC without @Blocking in RESTEasy Reactive),
> using @Singleton instead of @ApplicationScoped for
> beans that need interceptors (losing @Transactional),
> mixing blocking and reactive code without thread
> switching, eagerly loading @ApplicationScoped beans
> with @Startup when not needed, and using Spring-style
> patterns (new MyService()) instead of CDI injection.

**3 minutes (Senior):**

> Quarkus anti-patterns:
>
> 1. Event loop blocking (most common):
>   Problem: JDBC/blocking I/O on Vert.x event loop.
>   Symptoms: all requests slow, blocked thread warnings.
>   Fix: @Blocking on REST method or use reactive.
>
> 2. @Singleton for intercepted beans:
>   Problem: @Singleton has no CDI proxy.
>   @Transactional requires interceptor chain.
>   @Singleton + @Transactional: ArC creates proxy anyway.
>   But: @Singleton semantics (eager, no proxy otherwise).
>   Fix: use @ApplicationScoped for beans needing AOP.
>
> 3. Unused dependency injection:
>   Problem: @Inject field never used.
>   ArC includes the unused bean (unless removed).
>   Fix: use @Inject only when needed.
>   Or: Instance<T> for optional dependencies.
>
> 4. Reactive subscription without error handling:
>   Problem: orderService.create(req).subscribe()
>     No onFailure handler.
>   Uncaught reactive failure = silent data loss.
>   Fix: always handle onFailure in reactive chains.
>
> 5. @RequestScoped in @Singleton:
>   Problem: @Singleton is eager, @RequestScoped needs
>     active request context.
>   Injecting @RequestScoped into @Singleton: CDI proxy
>     resolves at runtime per-request.
>   But: accessing the field outside request context
>     = ContextNotActiveException.
>   Fix: use Instance<T> for @RequestScoped in @Singleton.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about common mistakes
when building Quarkus applications."

**(2) First principles:** "Anti-patterns are patterns
that seem correct but cause subtle failures at scale
or under load."

**(3) Bridge:** "Quarkus anti-patterns are the gaps
between Spring developer expectations and Quarkus
reactive/CDI reality."

---

### 💻 Code Example

```java
// ANTI-PATTERN 1: Blocking on event loop
// BAD
@GET
@Path("/slow")
public List<Order> listOrders() {
    // JDBC call on Vert.x event loop thread
    // Blocks the thread for all requests
    return Order.listAll();  // BLOCKING
}

// GOOD option A: annotate @Blocking
@GET
@Path("/orders")
@Blocking
public List<Order> listOrders() {
    return Order.listAll();  // Safe: worker thread
}

// GOOD option B: reactive
@GET
@Path("/orders")
public Uni<List<Order>> listOrders() {
    return orderReactiveRepo.listAll();
}

// ANTI-PATTERN 2: Reactive without error handling
// BAD
@POST
public void createOrder(OrderRequest req) {
    orderService.create(req)
        .subscribe()
        .with(order -> log.info("Created: {}",
            order.getId()));
    // If create() fails: exception silently swallowed
}

// GOOD
@POST
public Uni<Response> createOrder(OrderRequest req) {
    return orderService.create(req)
        .map(o -> Response.status(201)
            .entity(o).build())
        .onFailure()
        .recoverWithItem(e -> {
            log.error("Create failed", e);
            return Response.serverError().build();
        });
    // Framework handles the Uni - proper error propagation
}

// ANTI-PATTERN 3: Spring-style manual instantiation
// BAD - breaks CDI (no injection, no interceptors)
@ApplicationScoped
public class OrderCommandService {
    private final OrderRepository repo =
        new OrderRepositoryImpl();  // CDI bypassed
    // @Transactional on repo methods: not applied
    // @Inject on repo: not resolved
}

// GOOD
@ApplicationScoped
public class OrderCommandService {
    @Inject
    OrderRepository repo;  // CDI-managed, interceptors work
}

// ANTI-PATTERN 4: @ApplicationScoped with
// mutable non-thread-safe field
// BAD
@ApplicationScoped
public class ReportService {
    private List<Report> reports = new ArrayList<>();
    // Shared across all requests
    // ArrayList is not thread-safe
    // Concurrent access = data corruption

    public void addReport(Report r) {
        reports.add(r);  // Race condition
    }
}

// GOOD
@ApplicationScoped
public class ReportService {
    private final List<Report> reports =
        Collections.synchronizedList(
            new ArrayList<>());
    // Or: use ConcurrentHashMap, CopyOnWriteArrayList
    // Or: use @RequestScoped for per-request state
}

// ANTI-PATTERN 5: @Singleton for AOP
// BAD
@Singleton  // No proxy by default
public class PaymentService {
    @Transactional  // Interceptor needs proxy
    public void processPayment(Payment p) {
        // @Transactional applied via ArC subclass
        // Works but subtle: @Singleton is not lazy
        // All @Singleton beans created at startup
        // Slows startup, wastes resources if unused
    }
}

// GOOD
@ApplicationScoped  // Lazy, proxy, AOP-ready
public class PaymentService {
    @Transactional
    public void processPayment(Payment p) { ... }
}
```

> **Code walkthrough:** Anti-pattern 1 shows the classic
> event loop blocking issue in RESTEasy Reactive - the
> @Blocking annotation moves execution to the worker thread
> pool. Anti-pattern 2 demonstrates the silent failure
> mode of .subscribe() without error handling - returning
> a Uni from the controller delegates error handling
> to the framework. Anti-pattern 4 shows why @ApplicationScoped
> beans must use thread-safe data structures for shared
> mutable state. @ApplicationScoped is a singleton but
> accessed concurrently.

---

### 🚨 Failure Modes and Diagnosis

**Silent data loss (anti-pattern 2 in production):**
Symptoms: requests succeed (200), data never saved.
Diagnosis: check logs for swallowed exceptions.
Tool: Micrometer error counter (quarkus.http.requests.errors.total).
Fix: always return Uni from REST methods.

**Random NullPointerException in @Singleton:**
Cause: @RequestScoped bean accessed outside request context.
Diagnosis: ContextNotActiveException in logs.
Fix: Instance<@RequestScoped T> injection.

---

### 🎓 Answers by Seniority

**Senior:** "Most common: blocking the event loop. Second:
reactive without error handling. Third: Spring-style
new() instead of CDI injection. All three are discoverable
in code review."

**Staff:** "The deeper anti-pattern: using reactive
APIs for everything when @Blocking + JDBC is simpler
and sufficient. Reactive complexity without reactive
benefit. For most services: @Blocking JDBC is fine
up to 500 req/s. Reactive matters above 1000 req/s."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Top 5 anti-patterns, diagnosis |
| Staff | 12 min | When reactive hurts, @Singleton vs @ApplicationScoped |

---

**[SENIOR] Q1 - Why is @Singleton sometimes wrong
even though it seems like it should be the default?**

*Why they ask:* Subtle Quarkus CDI semantics.

@Singleton in Quarkus: no CDI proxy, eager creation.
@ApplicationScoped: CDI proxy, lazy creation.

Why @ApplicationScoped is usually better:

1. Lazy: @ApplicationScoped is activated on first use.
   @Singleton created at startup.
   Many @Singleton beans = slow startup.

2. Proxy enables: scope change, interceptors, hot reload
   in Dev Mode (proxy can point to new instance).

3. No proxy edge case with @Singleton:
   If @Singleton bean has @Transactional (needs proxy),
   ArC creates a _Subclass proxy anyway.
   But the reference is to the subclass directly.
   If someone gets the class via reflection: wrong class.

4. CDI spec: @ApplicationScoped is the spec-defined
   singleton. @Singleton is Quarkus-added convenience.

When to use @Singleton:
- Performance-critical beans where proxy overhead matters
- Beans that must be eagerly initialized at startup
- Config cache objects used from @Startup

*What separates good from great:* Understanding that
@ApplicationScoped is the CDI-standard singleton, not
@Singleton.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Event loop blocking, anti-pattern list. |
| Hiring Manager | Production-quality Quarkus development. |
| Bar Raiser | @Singleton vs @ApplicationScoped, reactive error handling. |
| Peer Engineer | "Found 15 @Singleton beans in our codebase with @Transactional. Changed to @ApplicationScoped. No behavioral change, cleaner code." |

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


# Quarkus Security Misconfiguration

**Interview Weight:** hard - Security misconfiguration
is OWASP Top 10 #5. Tested for security-aware candidates.

---

### 🎯 Model Answer

**30 seconds:**

> Common Quarkus security misconfigurations: @PermitAll
> on a class with sensitive child resources (overrides
> child @RolesAllowed), disabled CSRF in web-app mode,
> JWT signature algorithm set to "none", trusting all
> TLS certificates in production (quarkus.tls.trust-all=true),
> and overly broad CORS (quarkus.http.cors.origins=*).
> Diagnosis: security test with unauthorized requests,
> JWT fuzzing, CORS preflight probing.

**3 minutes (Senior):**

> Security misconfigurations:
>
> 1. @PermitAll class overrides @RolesAllowed method:
>   @PermitAll on class → all methods public.
>   @RolesAllowed on individual methods.
>   Result: @RolesAllowed ignored!
>   Fix: @Authenticated at class level, @PermitAll on
>     specific public endpoints.
>
> 2. JWT algorithm = "none":
>   JWT with alg=none accepted by some implementations.
>   A forged JWT with no signature passes validation.
>   Quarkus OIDC default: validates against JWKS.
>   Risk: custom JWT validation code that accepts alg=none.
>   Fix: always verify signature algorithm.
>
> 3. Trust all TLS in production:
>   quarkus.tls.trust-all=true: disables cert validation.
>   Dev convenience setting. NEVER in production.
>   Risk: man-in-the-middle. Service tokens intercepted.
>
> 4. Broad CORS:
>   quarkus.http.cors.origins=*: any origin.
>   For API services (no browser): CORS irrelevant.
>   For web apps: list specific origins.
>
> 5. Exposed management endpoints:
>   /q/dev (Dev UI): contains config, secrets.
>   Accessible in production by default on port 8080.
>   Fix: quarkus.management.enabled=true to move to
>     port 9000, then firewall port 9000 from internet.
>
> 6. Secrets in application.properties:
>   Version-controlled. Git history = secret leak.
>   Fix: ${ENV_VAR} references only. Actual values
>     in Kubernetes Secrets or Vault.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about security misconfigurations
in Quarkus - what can go wrong with the security setup."

**(2) First principles:** "Security misconfiguration =
features that are correct in dev but dangerous in prod."

**(3) Bridge:** "Quarkus security misconfigs are the
same class as Spring Security misconfigs: wrong annotation
semantics, overly permissive settings, dev tools in
production."

---

### 💻 Code Example

```java
// SECURITY BUG: @PermitAll overrides @RolesAllowed

// BAD
@Path("/api/v1/orders")
@PermitAll  // This makes ALL methods public!
public class OrderResource {

    @GET  // Public - intended
    public List<OrderDto> listPublicOrders() { ... }

    @DELETE
    @Path("/{id}")
    @RolesAllowed("admin")  // IGNORED! @PermitAll wins
    public void deleteOrder(
            @PathParam("id") Long id) {
        // Anyone can delete orders!
    }
}

// GOOD
@Path("/api/v1/orders")
@Authenticated  // Require auth for all methods
public class OrderResource {

    @GET
    @PermitAll  // Override: this endpoint is public
    public List<OrderDto> listPublicOrders() { ... }

    @DELETE
    @Path("/{id}")
    @RolesAllowed("admin")  // Only admins
    public void deleteOrder(
            @PathParam("id") Long id) { ... }
}

// SECURITY BUG: trust-all in production
// BAD
// application.properties
// quarkus.tls.trust-all=true  <-- NEVER IN PROD

// GOOD
// %dev.quarkus.tls.trust-all=true  (dev only)
// %test.quarkus.tls.trust-all=true (test only)
// prod: omit entirely (validates certs by default)

// SECURITY BUG: Dev UI accessible in production
// BAD: default port 8080, dev UI accessible
// GET /q/dev → shows config properties, beans, etc.

// GOOD: separate management port
// application.properties
// quarkus.management.enabled=true
// quarkus.management.port=9000
// %prod.quarkus.dev-ui.hosts.allow-list=''
//   (empty = disable in prod)

// SECURITY CHECK: JWT validation
@ApplicationScoped
public class JwtSecurityAudit {

    @Inject
    JsonWebToken jwt;

    public void auditToken() {
        // Check algorithm is not "none"
        String alg =
            jwt.getClaim("alg");
        if ("none".equalsIgnoreCase(alg)) {
            throw new SecurityException(
                "JWT with alg=none rejected");
        }

        // Check expiry
        Long exp = jwt.getClaim("exp");
        if (exp < System.currentTimeMillis() / 1000) {
            throw new SecurityException(
                "Expired JWT");
        }
    }
}
```

```bash
# Security test: check for unauthorized access
# Test @RolesAllowed actually blocks
curl -s -o /dev/null -w "%{http_code}" \
  -X DELETE http://localhost:8080/api/v1/orders/1
# Expected: 401 (no token)
# If 200: @PermitAll bug!

# Test Dev UI not accessible in production
curl http://localhost:8080/q/dev
# Expected: 404 or redirect
# If 200: Dev UI exposed in production!

# Test CORS policy
curl -H "Origin: https://evil.com" \
  -H "Access-Control-Request-Method: DELETE" \
  -X OPTIONS http://localhost:8080/api/v1/orders
# Check Access-Control-Allow-Origin in response
# Should NOT be *
```

> **Code walkthrough:** The @PermitAll/@RolesAllowed bug
> is the most dangerous: @PermitAll on the class wins
> over @RolesAllowed on methods - the delete endpoint
> becomes public. The fix: @Authenticated at class level
> (default is "you must be logged in"), then @PermitAll
> overrides downward for specific public endpoints. The
> trust-all fix uses profile prefixes to ensure it's
> never set in production.

---

### 🎓 Answers by Seniority

**Senior:** "Top three: @PermitAll/@RolesAllowed conflict,
trust-all in production, Dev UI accessible in production.
All discoverable with 5-minute security review."

**Staff:** "Security misconfiguration is a build-time
check opportunity. Quarkus could validate: @PermitAll
class with @RolesAllowed methods = warning. trust-all
in prod profile = error. Dev UI route registered without
management port = warning. None of these are currently
checked. Good candidate for a security-lint extension."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Top misconfigurations, @PermitAll semantics |
| Staff | 12 min | Security extension opportunities, OWASP mapping |

---

**[SENIOR] Q1 - How do you harden a Quarkus service
before production deployment?**

*Why they ask:* Security checklist.

Hardening checklist:

Authentication + Authorization:
- @Authenticated at class level on all resources
- @RolesAllowed on sensitive operations
- No @PermitAll except on intentionally public endpoints
- OIDC configured with quarkus.oidc.application-type=service

Secrets management:
- Zero plaintext secrets in application.properties
- All secrets as ${ENV_VAR} references
- Kubernetes Secrets or Vault for actual values

TLS:
- quarkus.tls.trust-all not set (or %dev only)
- HTTPS for all endpoints
- Mutual TLS for service-to-service (optional)

Management endpoints:
- quarkus.management.enabled=true (port 9000)
- 9000 not exposed externally (firewall/K8s NetworkPolicy)
- %prod.quarkus.dev-ui.hosts.allow-list='' (disable Dev UI)

CORS:
- List specific origins (not *)
- Methods: only what's needed

HTTP:
- quarkus.http.ssl-port=8443 for HTTPS
- HTTP → HTTPS redirect

*What separates good from great:* The complete checklist,
not just "add auth".

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Security misconfigurations, @PermitAll semantics. |
| Hiring Manager | Production-ready secure services. |
| Bar Raiser | Hardening checklist, OWASP alignment. |
| Peer Engineer | "@PermitAll on our order deletion endpoint. Caught in code review. Fixed in 2 lines." |

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


# Quarkus Memory and Startup Optimization

**Interview Weight:** hard - Optimization is a differentiating
topic for cloud-native roles. Tested for concrete techniques.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus startup optimization: move initialization to
> build time (avoid runtime classpath scanning), use
> CDS (Class Data Sharing) for JVM mode, reduce unused
> extensions. Memory optimization: reduce heap size
> (-Xmx), tune GC (G1 for JVM, no GC for short-lived
> Lambda), use native image for extreme cases (50-80%
> memory reduction). Profile first: container startup
> vs application startup, heap vs off-heap.

**3 minutes (Senior):**

> Startup optimization:
>
> JVM mode:
>   CDS (Class Data Sharing): -Xshare:dump + -Xshare:on
>   Saves ~50ms per pod by sharing class metadata.
>   Quarkus built-in: AppCDS included in uber-jar.
>   Unused extensions: remove to reduce classpath.
>   Eager CDI beans: use @Lazy or avoid @Startup.
>
> Native mode:
>   Static initialization at build time.
>   No class loading at startup.
>   Startup: 50-100ms (vs 2-5s JVM).
>
> Memory optimization:
>
> JVM mode:
>   -Xmx: cap heap (256m for small services).
>   -XX:+UseG1GC: G1 for low pause.
>   -XX:MaxRAMPercentage=75: ratio-based heap.
>   Off-heap: direct buffers (Vert.x, Netty).
>   -XX:MaxDirectMemorySize=64m: cap direct memory.
>
> Native mode:
>   RSS: ~50MB for simple services (vs 300MB JVM).
>   --gc=G1 or --gc=epsilon (no GC for short-lived).
>   Native image heap: includes Quarkus pre-initialized state.
>
> Kubernetes resource tuning:
>   request: cpu: 100m, memory: 256Mi
>   limit: cpu: 500m, memory: 512Mi
>   JVM: -Xmx = limit - off-heap (50m buffer).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about optimizing memory
and startup time in Quarkus."

**(2) First principles:** "Startup time = how long until
first request. Memory = resources per pod. Both affect
cost and density."

**(3) Bridge:** "Quarkus optimization levers: remove
unused extensions (instant startup win), CDS (JVM warmup),
native image (maximum startup and memory reduction)."

---

### 💻 Code Example

```bash
# JVM mode optimization

# Option 1: AppCDS (Class Data Sharing)
# Quarkus generates CDS archive during build:
./mvnw package -Dquarkus.jib.cds-enabled=true

# Or: manual CDS generation
# Step 1: Generate class list
java -XX:DumpLoadedClassList=classes.lst \
  -jar target/app-runner.jar
  
# (Run a few requests to warm class loading)
# Ctrl-C

# Step 2: Create shared archive
java -Xshare:dump \
  -XX:SharedClassListFile=classes.lst \
  -XX:SharedArchiveFile=app-cds.jsa \
  -jar target/app-runner.jar

# Step 3: Run with CDS
java -Xshare:on \
  -XX:SharedArchiveFile=app-cds.jsa \
  -jar target/app-runner.jar
# Startup: ~2s -> ~1.5s (25% faster)

# Option 2: Remove unused extensions
./mvnw quarkus:add-extension -Dextensions="health"
# Only add what you need

# Option 3: Memory tuning
java -Xmx256m \
  -XX:MaxDirectMemorySize=64m \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=100 \
  -jar target/app-runner.jar

# Option 4: Kubernetes-aware heap
# Let JVM calculate from container limits:
java -XX:MaxRAMPercentage=75 \
  -jar target/app-runner.jar
# If container limit is 512Mi:
# Heap = 0.75 * 512 = 384MB
```

```java
// Reduce startup: avoid unnecessary @Startup beans
// BAD: heavy initialization at startup
@ApplicationScoped
@Startup  // Forces eager initialization
public class EagerCache {
    // Loads 10MB of cache data at startup
    // Slows every pod cold start
    private final Map<Long, Product> cache =
        loadAllProducts();  // Slow!
}

// GOOD: lazy initialization
@ApplicationScoped
public class LazyCache {
    private Map<Long, Product> cache;

    // Initialize on first use, not at startup
    @PostConstruct
    void init() {
        // Only called when first @Inject resolves
    }

    Map<Long, Product> getCache() {
        if (cache == null) {
            synchronized (this) {
                if (cache == null) {
                    cache = loadAllProducts();
                }
            }
        }
        return cache;
    }
}

// BEST for Lambda/FaaS: native image
// No heap warmup needed
// Binary startup: 50ms
// Memory: 50MB RSS
// ./mvnw package -Pnative
```

> **Code walkthrough:** AppCDS pre-loads class metadata
> into a shared archive file; subsequent JVM startups
> mmap the archive instead of loading class files, saving
> ~500ms. -XX:MaxRAMPercentage=75 is safer than hardcoded
> -Xmx in containers: it calculates heap as 75% of the
> container memory limit, preventing OOM kills when the
> limit changes. The LazyCache pattern avoids @Startup
> eager initialization - the cache loads on first access,
> distributing startup cost across the first few requests.

---

### 🎓 Answers by Seniority

**Senior:** "JVM mode: CDS for startup, -XX:MaxRAMPercentage
for memory, G1 for low pause. Native image: extreme
startup and memory reduction. Remove unused extensions:
immediate startup improvement."

**Staff:** "Memory budget calculation for K8s:
Total container memory = Heap + Off-heap (Netty/Vert.x)
+ JVM overhead (50-100MB). Set -Xmx = limit - 150MB.
For native: RSS grows with concurrent requests (stack
memory); right-size to peak_rss + 20% buffer."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | CDS, -XX:MaxRAMPercentage, native image |
| Staff | 12 min | Memory budget, GC selection, Kubernetes resource tuning |

---

**[STAFF] Q1 - How do you right-size Quarkus JVM
containers in Kubernetes?**

*Why they ask:* Production resource management.

Process:
1. Measure RSS under realistic load.
   Use: kubectl top pods or Prometheus memory metrics.
   Run: load test at expected traffic.
   Record: peak RSS.

2. Calculate memory budget:
   Total RSS = heap + off-heap + JVM overhead
   Typical: heap = 50% of total RSS
   JVM overhead: ~100MB (code cache, metaspace)
   Off-heap: Vert.x/Netty direct buffers ~50MB

3. Set container limits:
   limit = peak_rss * 1.3 (30% buffer)
   request = peak_rss (scheduler hint)

4. Set JVM heap from limit:
   -XX:MaxRAMPercentage=60
   (Lower than 75 to leave room for off-heap)

Example for order service (100 concurrent requests):
   Peak RSS: 350MB
   limit: 450Mi
   request: 350Mi
   -XX:MaxRAMPercentage=60

   450MB * 0.6 = 270MB heap
   450MB - 270MB = 180MB for off-heap + overhead (adequate)

OOM killed? limit too low or off-heap unbounded.
Check: -XX:MaxDirectMemorySize=64m to cap Netty buffers.

*What separates good from great:* Off-heap memory budget
in the calculation, not just heap.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | CDS, memory flags, native image. |
| Hiring Manager | Cost optimization for Kubernetes. |
| Bar Raiser | Memory budget calculation, off-heap, right-sizing. |
| Peer Engineer | "Added -XX:MaxRAMPercentage=60. OOM kills: 3/week → 0. Same containers, proper heap ratio." |

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



