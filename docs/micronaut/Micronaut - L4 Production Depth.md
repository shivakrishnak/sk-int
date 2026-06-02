---
layout: default
title: "Micronaut - L4 Production Depth"
parent: "Micronaut"
nav_order: 7
permalink: /micronaut/l4-production-depth/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut GraalVM Native Image Build](#micronaut-graalvm-native-image-build) | critical |
| 2 | [Micronaut Startup Performance Tuning](#micronaut-startup-performance-tuning) | high |
| 3 | [Micronaut Anti-Patterns](#micronaut-anti-patterns) | high |
| 4 | [Micronaut Production Diagnostics](#micronaut-production-diagnostics) | critical |

---

# Micronaut GraalVM Native Image Build

**Interview Weight:** critical - Native image is
Micronaut's flagship feature. Every Micronaut interview
will probe native image build, trade-offs, and diagnosis.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut supports GraalVM native image out of the
> box because compile-time DI generates no reflection.
> Build with: ./mvnw package -Dpackaging=native-image
> (Maven) or ./gradlew nativeCompile (Gradle). Result:
> a single native executable. Cold start: <100ms.
> Memory: 50-80% less than JVM. Trade-offs: no dynamic
> class loading, build time 3-10 minutes, no JIT
> optimization at runtime, some libraries need
> reflection config.

**3 minutes (Senior):**

> What works without configuration:
>
> Micronaut DI: no reflection (generated code)
> Micronaut HTTP server: compile-time routes
> Micronaut Data JDBC/JPA: compile-time repositories
> Micronaut Security: compile-time filters
>
> What needs configuration:
>
> Jackson JSON: reflection config for serialized types
>   OR use micronaut-serde (compile-time serialization)
> Third-party libraries: if they use reflection
>   Add reflect-config.json for those classes
> Dynamic class loading: impossible in native image
>   Must be known at build time (closed-world assumption)
>
> Build command:
>   Maven: ./mvnw package -Dpackaging=native-image
>   Gradle: ./gradlew nativeCompile
>   Docker: FROM ghcr.io/graalvm/native-image
>
> GraalVM tracing agent:
>   Run app with: -agentlib:native-image-agent
>   Captures reflection/resource/proxy usage
>   Generates reflect-config.json, resource-config.json
>   Include in native image build
>
> Dockerfile for production:
>   Multi-stage: build in GraalVM container,
>   run in distroless/scratch
>   Final image: 10-50MB (vs 200-500MB JVM Docker)
>
> Profile-guided optimization (PGO):
>   Collect profiles during benchmark run
>   Feed profiles into native-image build
>   Improves runtime performance (partially compensates
>   for no JIT)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about building a
Micronaut native image - compiling to a standalone
executable."

**(2) First principles:** "Native image = ahead-of-time
compilation of Java to native binary. No JVM at runtime.
Fast start, low memory."

**(3) Bridge:** "Native image is Go-speed startup for
Java. Micronaut's compile-time DI means most of the
app is already native-image-friendly without config."

---

### 💻 Code Example

```dockerfile
# Multi-stage Dockerfile for Micronaut native
FROM ghcr.io/graalvm/native-image:21 AS build

WORKDIR /app

COPY . .

# Build native executable
RUN ./mvnw package -Dpackaging=native-image \
    -Dmicronaut.aot.enabled=true \
    --no-transfer-progress

# Final stage: minimal base image
FROM debian:bookworm-slim

WORKDIR /app

# Copy only the native executable
COPY --from=build /app/target/application .

# Create non-root user
RUN useradd -r -u 1001 appuser
USER appuser

EXPOSE 8080

ENTRYPOINT ["./application"]
```

```xml
<!-- Maven native image plugin (pom.xml) -->
<plugin>
  <groupId>org.graalvm.buildtools</groupId>
  <artifactId>native-maven-plugin</artifactId>
  <configuration>
    <buildArgs>
      <!-- Include all reflective types -->
      <buildArg>
        --initialize-at-build-time=
          com.example.config
      </buildArg>
      <!-- Resources to include -->
      <buildArg>
        -H:IncludeResources=
          application.yml
      </buildArg>
      <!-- Diagnostic: dump native image heap -->
      <buildArg>
        -H:+PrintAnalysisCallTree
      </buildArg>
    </buildArgs>
  </configuration>
</plugin>
```

```bash
# Using GraalVM tracing agent to generate config
# Step 1: run tests with tracing agent
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/META-INF/\
  native-image \
  -jar target/application.jar

# Step 2: run integration tests to capture
# all reflection, resources, proxies

# Step 3: build native image
# (uses generated configs automatically)
./mvnw package -Dpackaging=native-image
```

> **Code walkthrough:** The multi-stage Dockerfileice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> builds in the GraalVM container (3-10 min build
> time) and copies only the native executable to a
> minimal Debian image. The final image has no JVM,
> no JDK - just the executable. The tracing agent
> runs the application normally to capture all
> reflection/resource accesses and writes them to
> reflect-config.json and resource-config.json.
> These are automatically included in the build.

---

### ⚖️ Comparison Table

| Aspect | JVM Mode | Native Image |
|---|---|---|
| Cold start | 1-5 seconds | <100ms |
| Memory (RSS) | 200-500MB | 50-100MB |
| Peak throughput | Higher (JIT) | Lower (AOT) |
| Build time | Seconds | 3-10 minutes |
| Dynamic class loading | Yes | No |
| Reflection | Yes | Config needed |
| Lambda cost | Higher (idle JVM) | Lower (start/stop) |

---

### 🚨 Failure Modes and Diagnosis

**Symptoms and Fixes:**

1. "ReflectiveOperationException at runtime":
   - Class not registered for reflection.
   - Fix: run tracing agent or add to reflect-config.json.
   - Prevention: use micronaut-serde instead of Jackson
     for JSON serialization.

2. "Class initialization failed":
   - Static initializer runs at build time, fails.
   - Fix: --initialize-at-run-time=com.problematic.Class
   - Diagnosis: --trace-class-initialization

3. Native image build OOM (out of memory):
   - Build needs 6-8GB RAM.
   - Fix: export MAVEN_OPTS="-Xmx8g" before build.

4. "Resource not found" in native image:
   - Resource not included in native image.
   - Fix: add to resource-config.json or use
     -H:IncludeResources pattern.

---

### 📘 Concept Explanation

**What it is:**

Micronaut GraalVM Native Image Build is the process of
compiling a Micronaut application into a standalone native
executable using GraalVM's ahead-of-time (AOT) compiler.
The result: no JVM required at runtime, sub-100ms startup,
minimal memory footprint.

**How it works:**

Build process:
1. Standard Micronaut build (`javac` + APT)
2. GraalVM's `native-image` tool performs static analysis
   (points-to analysis) of all code reachable from the
   application entry point
3. All reachable code is compiled to native machine code
4. Result: a platform-specific binary (`./myapp`)

Micronaut's APT generates GraalVM hints (`reflect-config.json`,
`resource-config.json`) for its own runtime requirements.
Custom hints needed for libraries not pre-configured.

Runtime: the binary starts the Micronaut application
directly without JVM initialization. Startup: 20-100ms.
Memory: 30-80MB for a typical REST service.

**Why it matters:**

Lambda cold start from 2-8s (JVM) to <100ms (native).
Kubernetes pod density: 10 pods in memory budget of 2 pods
JVM. Cloud cost reduction for memory-billed deployments.

---

### 🎓 Answers by Seniority

**Junior:** "Build with -Dpackaging=native-image. Result
is a native executable. Startup <100ms. Needs GraalVM."

**Senior:** "Dynamic class loading and arbitrary
reflection are impossible in native image. Libraries
that use reflection (Jackson, some JDBC drivers) need
reflect-config.json. The tracing agent generates this
automatically by recording runtime reflection calls.
Use micronaut-serde instead of Jackson to eliminate
reflection from JSON processing."

**Staff:** "Native image trade-offs at scale: startup
speed enables Lambda and serverless. Lower memory
means more pods per node. Lower peak throughput is
acceptable for most microservices (network/DB latency
dominates, not CPU throughput). For compute-intensive
services (ML inference, heavy calculation): JVM with
JIT is faster at sustained throughput."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut native image builds work
out-of-the-box for all dependencies.**

Micronaut includes GraalVM hints for its own core components
(HTTP, DI, serialization). Third-party libraries that use
reflection, dynamic class loading, JNI, or serialization
may require additional configuration. Libraries without
GraalVM support (no `reflect-config.json` or `@ReflectiveAccess`)
need manual reflection configuration. Before committing to
native image deployment, verify all dependencies with a
test native build.

**Misconception 2: Native image provides the same peak
throughput as JVM + JIT.**

JVM JIT compiles hot code paths adaptively based on
runtime profiling - generating highly optimized machine code
for actual usage patterns. Native AOT compiles all code at
build time without runtime profiling. Result: native image
has better COLD throughput but JVM+JIT may have higher
PEAK throughput for CPU-intensive workloads after warmup.
Native is superior for: cold start, memory efficiency,
unpredictable traffic. JVM+JIT is superior for: sustained
high-throughput CPU workloads, complex optimization opportunities.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Build process, reflection config, tracing agent |
| Staff | 14 min | JVM vs native trade-offs, PGO, production configuration |

---

**[SENIOR] Q1 - How do you handle Jackson
deserialization in Micronaut native image?**

*Why they ask:* Jackson reflection is the most common
native image failure.

Option 1: Micronaut Serialization (preferred):
```java
// Replace Jackson with compile-time serialization
// pom.xml: micronaut-serde-jackson dependency
// (NOT micronaut-jackson-databind)
@Serdeable  // Generates serde code at compile time
public class OrderDto {
    private Long id;
    private String status;
    private BigDecimal total;
    // No reflection needed for serialization
}
```

> **Code walkthrough:** This (uses generated configs automatically) example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Option 2: @ReflectiveAccess for Jackson:
```java
@ReflectiveAccess  // Generates reflect-config entry
public class OrderDto {
    // Jackson can reflect on this class
    // In native image
}
```

> **Code walkthrough:** This (uses generated configs automatically) example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Option 3: reflect-config.json:
```json
[{
    "name": "io.example.dto.OrderDto",
    "allDeclaredConstructors": true,
    "allDeclaredFields": true,
    "allDeclaredMethods": true
}]
```

> **Code walkthrough:** This (uses generated configs automatically) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Recommendation: use micronaut-serde-jackson.
It generates serialization code at compile time,
removes reflection requirement, and is faster at
runtime than reflection-based Jackson.

*What separates good from great:* micronaut-serde
as the proactive solution vs reflect-config.json
as a reactive patch.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Build command, Dockerfile, reflection handling. |
| Hiring Manager | Native image = Lambda-friendly, container-efficient. |
| Bar Raiser | Jackson reflection, micronaut-serde, PGO, JVM vs native trade-off. |
| Peer Engineer | "Switched to micronaut-serde. Build without reflection config. Native image build errors dropped from 12 to 0." |

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


# Micronaut Startup Performance Tuning

**Interview Weight:** high - Startup time is the
Micronaut differentiator. Tested for what slows startup
and how to diagnose and fix it.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut startup is fast because there is no classpath
> scanning. Main costs: loading BeanDefinition classes,
> resolving the bean dependency graph, executing
> @PostConstruct methods, establishing DB connections,
> loading Flyway migrations. Diagnose with startup
> timeline: -Dmicronaut.bean.introspection.trace or
> startup tracing. Optimize: @Lazy for non-essential
> beans, connection pool sizing, Flyway baseline for
> production, async startup tasks.

**3 minutes (Senior):**

> Startup phases and costs:
>
> 1. JVM class loading (200-500ms):
>    JVM loads all classes in the JAR.
>    Reduce: minimize dependencies, shade only what
>    you need.
>
> 2. Bean definition loading (50-200ms for 500 beans):
>    Load BeanDefinition classes into ApplicationContext.
>    Compile-time generation means this is just
>    class loading (no reflection).
>
> 3. Eager singletons initialization (variable):
>    All @Singleton beans created at startup.
>    @PostConstruct methods run here.
>    Problem: expensive @PostConstruct blocks startup.
>    Fix: @Lazy on non-critical beans, or async init.
>
> 4. DataSource initialization (100-500ms):
>    Connection pool established.
>    Fix: minimize pool initial size for fast startup.
>    hikari.minimum-idle=2 vs maximum-pool-size=20.
>
> 5. Flyway/Liquibase migration (50-5000ms+):
>    Schema migration at startup.
>    Fix: run Flyway as pre-deploy step, not at startup.
>    Or: Flyway baseline for existing schemas.
>
> 6. HTTP server bind (50-100ms):
>    Netty binds to the port.
>
> Diagnostic tools:
>   -Dmicronaut.startup.tracing=true: bean-level timing
>   Micronaut Micrometer: startup metrics
>   JVM startup flags: -verbose:class for class loading

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about making Micronaut
start faster - understanding and fixing startup bottlenecks."

**(2) First principles:** "Startup = JVM + app initialization.
Each phase has a cost. Measure, identify the biggest
cost, optimize it."

**(3) Bridge:** "Micronaut startup is like a restaurant
opening: tables set (beans init), kitchen stocked (DB pool),
doors open (HTTP server). @Lazy means you don't stock
every ingredient before opening."

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: blocking startup with expensive init
@Singleton
public class MLModelLoader {
    private final Model model;

    @PostConstruct  // Runs at startup
    public void init() {
        // Loads 500MB model from S3
        // Blocks startup for 10-30 seconds!
        this.model = s3Client.loadModel(
            "s3://models/fraud-detection-v3");
    }
}

// GOOD: async init - app starts, loads in background
@Singleton
@Lazy  // Not created until first use
public class MLModelLoader {
    private volatile Model model;
    private final CompletableFuture<Model> loading;

    MLModelLoader(S3ModelClient s3Client) {
        // Start loading asynchronously
        this.loading = CompletableFuture
            .supplyAsync(() ->
                s3Client.loadModel(
                    "s3://models/fraud-detection-v3")
            );
    }

    public Model getModel() {
        return loading.join();
        // Blocks only when actually needed
        // App is already accepting traffic
    }
}

// application.yml: startup-optimized config
// datasources:
//   default:
//     minimum-idle: 2       # Don't pre-warm all 20
//     maximum-pool-size: 20
//     connection-timeout: 5000
// flyway:
//   enabled: false          # Run as pre-deploy job
//   # OR:
//   baseline-on-migrate: true  # Faster for existing DB

// Lazy evaluation for non-critical beans
@Singleton
@Lazy  // Only created when first injected
public class ReportingEngine {
    // Not needed at startup
    // Created on first report request
}

// Async startup event
@Singleton
public class CacheWarmer
        implements ApplicationEventListener<
            ServiceReadyEvent> {

    @Override
    public void onApplicationEvent(
            ServiceReadyEvent event) {
        // Runs AFTER startup completes
        // Cache warming doesn't block startup
        CompletableFuture.runAsync(
            this::warmFrequentlyAccessedData);
    }
}
```

> **Code walkthrough:** The BAD case puts a 30-secondice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> model load in @PostConstruct - the HTTP server doesn't
> start until this completes. @Lazy on the GOOD version
> defers creation until first use. CompletableFuture
> starts loading immediately (app is warm when needed)
> but doesn't block startup. ServiceReadyEvent fires
> after the HTTP server is bound - safe for cache warming
> without delaying readiness.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Startup Performance Tuning is the practice of
analyzing and optimizing the time from JVM start to
"ready to serve traffic" for a Micronaut application.

**How it works:**

Key startup phases and tuning knobs:

1. **JVM startup**: JVM itself takes 50-200ms. Reduce with
   GraalVM native (eliminates JVM start) or class data sharing
   (CDS, AppCDS reduces JVM startup).

2. **Bean initialization**: Micronaut loads pre-built
   `BeanDefinition` classes. Profiling: enable startup tracing
   with `micronaut.startup.tracing=true` to see per-bean time.

3. **@PostConstruct / @Context initialization**: beans with
   startup work (DB warmup, cache load) add to startup time.
   Profile with startup tracing; consider deferring non-
   critical work to background tasks.

4. **Embedded server bind**: Netty binding takes 5-50ms.
   Reduce with `micronaut.server.worker-threads` tuning.

5. **Application events**: `ApplicationStartedEvent` listeners
   run synchronously. Move heavy initialization to async events.

Metrics: measure startup from JVM launch to first request
serviced successfully. Use `time java -jar app.jar & until
curl http://localhost:8080/health; do sleep 0.1; done`.

**Why it matters:**

Sub-500ms startup enables Lambda cold starts within budget,
rapid Kubernetes scale-out, and faster CI feedback.

---

### 🎓 Answers by Seniority

**Junior:** "@Lazy defers bean creation. @PostConstruct
blocking operations slow startup. Configure minimum
idle pool connections small."

**Senior:** "The three biggest startup killers: expensive
@PostConstruct (fix: @Lazy + async), Flyway running
migrations at startup (fix: pre-deploy step), connection
pool pre-warming too many connections (fix: minimum-idle=2).
ServiceReadyEvent for tasks that can run after startup."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's startup is always
sub-200ms regardless of application size.**

Micronaut eliminates framework overhead (scanning, proxy
generation) but does NOT eliminate application-specific
startup work: loading database connection pools, reading
configuration from remote sources (Consul, Vault), warming
application-level caches, running `@PostConstruct` methods.
A Micronaut application that connects to 3 databases and
pre-warms 2 caches may take 2-3 seconds to start. The
framework overhead is minimal; the application overhead
is what remains.

**Misconception 2: Enabling lazy initialization
globally accelerates startup.**

`micronaut.eager-init: false` delays bean initialization
to first use. This REDUCES startup time but INCREASES
first-request latency significantly (all beans initialized
on first request). For Lambda functions: cold start is
just moved to first request, which may have a latency SLO.
For Kubernetes: the readiness probe may pass before the
application is warmed, directing traffic to a cold pod.
Lazy initialization is appropriate when some beans are
rarely used and their startup cost is not worth paying upfront.

**Misconception 3: Increasing JVM heap size improves
startup performance.**

Larger heap sizes actually INCREASE startup time because:
the JVM must commit (or reserve) more virtual memory at
startup, GC initialization is more expensive for large heaps,
and initial heap allocation overhead is proportional to size.
Startup performance benefits from SMALLER initial heap with
sufficient max heap. Use `-Xms` = minimum needed at startup
(typically 32-64MB), `-Xmx` = maximum for steady state.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Application passes readiness probe
before all @PostConstruct work completes.**

Symptom: first requests after pod startup fail because
cache/initialization is not complete; health probe shows
UP but responses are incorrect. Root cause: Kubernetes
readiness probe hits `/health` while `@PostConstruct`
methods are still running in background threads.
Diagnosis: add timestamps to `@PostConstruct` logging;
compare to first request timestamps. Fix: move initialization
to an `ApplicationStartedEvent` listener and mark the
application as ready only after all initialization completes;
implement a custom readiness indicator that checks
initialization state.

**Failure Mode 2: Startup time increases linearly with
each new bean added to the application.**

Symptom: startup time grows from 300ms to 2s as the
application adds more beans and features, exceeding Lambda
cold start budgets. Root cause: each additional `@Context`
or early-init singleton adds its initialization time to
the critical path. Diagnosis: enable startup timing logging
to identify expensive initializers. Fix: profile with
`-Dmicronaut.startup.tracing=true`; defer non-critical
initialization to background tasks after startup; use
`@Context` only for truly infrastructure-critical beans.

**Failure Mode 3: JVM class loading overhead dominates
startup in containerized environments.**

Symptom: startup is fast locally but slow in containers
(600ms+ instead of 200ms). Root cause: containers often
have slower disk I/O than local SSDs; class loading from
JAR files is I/O-intensive. Diagnosis: compare startup
times inside and outside container. Fix: enable JVM Class
Data Sharing (`-Xshare:on`) with AppCDS to reduce class
loading time; use fat-JAR (`./gradlew shadowJar`) to reduce
JAR file count; consider GraalVM native image which
eliminates class loading entirely.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Startup phases, @Lazy, @PostConstruct, Flyway |
| Staff | 10 min | Native image startup, k8s readiness, startup budget |

---

**[SENIOR] Q1 - How do you set a startup time budget
for a Kubernetes pod?**

*Why they ask:* Production Kubernetes configuration.

The budget is determined by the readiness probe:
```yaml
readinessProbe:
  httpGet:
    path: /health/readiness
    port: 8080
  initialDelaySeconds: 10   # Wait 10s before first check
  periodSeconds: 3           # Check every 3s
  failureThreshold: 5        # Fail after 5 consecutive failures
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration patice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Total budget = initialDelaySeconds + (periodSeconds * failureThreshold)
= 10 + (3 * 5) = 25 seconds

If app doesn't pass readiness within 25 seconds:
Kubernetes marks pod as failed, controller recreates it.

For Micronaut JVM: budget 15-30 seconds is usually
sufficient. For native: budget 5-10 seconds.

To measure: log startup time in ServiceReadyEvent.
If startup consistently takes 20s: either extend
budget or optimize startup.

*What separates good from great:* Calculating the
actual budget from probe configuration (not just
"initialDelaySeconds is the startup time").

| Interviewer Type| Emphasis|
|-----------|------------------------------------------------------------------|
| Technical Panel| @Lazy, startup phases, @PostConstruct.|
| Hiring Manager| Startup speed = faster deployments.|
| Bar Raiser| Startup budget, readiness probe math, Flyway strategy, async init.
| Peer Engineer| "Moved Flyway to a k8s init container. Startup time: 12s → 3s."

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


# Micronaut Anti-Patterns

**Interview Weight:** high - Anti-patterns tested to
verify production experience. Knowing what not to do
separates senior from junior.

---

### 🎯 Model Answer

**30 seconds:**

> Top Micronaut anti-patterns: (1) Blocking Netty event
> loop - JDBC without @Blocking kills throughput.
> (2) Spring-style @Autowired field injection - use
> constructor injection. (3) Overusing @Prototype
> instead of @RequestScope or stateless @Singleton.
> (4) Giant controllers with business logic - controllers
> should delegate to services. (5) Not using
> micronaut-serde for native image - Jackson without
> serde requires reflection config.

**3 minutes (Senior):**

> Pattern 1: Blocking the event loop:
>   @Get on JDBC without @Blocking.
>   Event loop thread blocks. Concurrency collapses.
>   Symptom: throughput drops under moderate load.
>   Fix: @Blocking annotation, or reactive + R2DBC.
>
> Pattern 2: Disabling AOT:
>   Some teams set micronaut.aot.enabled=false
>   because a library "doesn't work with AOT."
>   This defeats the purpose of Micronaut.
>   Fix: identify and fix the library integration.
>
> Pattern 3: Using Spring-style XML/annotation config:
>   Micronaut DI is not Spring. @Configuration +
>   @Bean exist but the DI model differs.
>   @Factory + @Bean is correct Micronaut idiom.
>   Don't assume Spring behavior.
>
> Pattern 4: Large @MicronautTest for unit tests:
>   @MicronautTest starts full ApplicationContext.
>   Use for integration tests only.
>   For unit tests: instantiate the class directly
>   (constructor injection makes this easy).
>
> Pattern 5: Ignoring compile-time validation:
>   Micronaut reports DI errors at compile time.
>   Some teams suppress warnings and discover
>   failures only in production.
>   Fix: treat compile-time DI errors as build failures.
>
> Pattern 6: Storing mutable state in @Singleton:
>   @Singleton shared across all requests.
>   Mutable state without synchronization = data races.
>   Fix: stateless @Singleton (inject dependencies only),
>   or @RequestScope for per-request state.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about common mistakes
in Micronaut applications - what to avoid."

**(2) First principles:** "Anti-patterns emerge when
developers apply patterns from other frameworks without
understanding Micronaut's different model."

**(3) Bridge:** "Most Micronaut anti-patterns come
from Spring habits: field injection, event loop blocking,
and using @MicronautTest for unit tests."

---

### 💻 Code Example

```java
// ANTI-PATTERN 1: Blocking event loop
@Controller("/orders")
public class OrderController {
    @Get("/{id}")
    public OrderDto findById(Long id) {
        // JDBC on Netty event loop!
        return repo.findById(id)  // BLOCKS!
            .map(OrderDto::from)
            .orElseThrow();
    }
}

// FIXED: @Blocking annotation
@Controller("/orders")
public class OrderController {
    @Get("/{id}")
    @Blocking  // Offloads to worker thread
    public OrderDto findById(Long id) {
        return repo.findById(id)
            .map(OrderDto::from)
            .orElseThrow();
    }
}

// ANTI-PATTERN 2: Field injection
@Singleton
public class OrderService {
    @Inject  // Field injection
    private OrderRepository repo;
    // Difficult to test: can't pass mock via constructor
    // Not immutable
    // Hides dependencies
}

// FIXED: Constructor injection
@Singleton
public class OrderService {
    private final OrderRepository repo;
    // Immutable, easy to test
    OrderService(OrderRepository repo) {
        this.repo = repo;
    }
}

// ANTI-PATTERN 3: Mutable @Singleton state
@Singleton
public class RequestCounter {
    private int count = 0;  // SHARED MUTABLE STATE!

    public int increment() {
        count++;  // Data race in concurrent access!
        return count;
    }
}

// FIXED: AtomicInteger or @RequestScope
@Singleton
public class RequestCounter {
    private final AtomicLong count =
        new AtomicLong(0);

    public long increment() {
        return count.incrementAndGet();  // Thread-safe
    }
}

// ANTI-PATTERN 4: @MicronautTest for unit test
@MicronautTest  // Starts full context for unit test!
class OrderServiceTest {
    @Inject
    OrderService service;

    // Overkill: 5 second startup for a unit test
}

// FIXED: constructor instantiation for unit test
class OrderServiceTest {
    OrderRepository mockRepo =
        Mockito.mock(OrderRepository.class);
    OrderService service =
        new OrderService(mockRepo);

    // Instantaneous. No context needed.
}
```

> **Code walkthrough:** The event loop anti-patternice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> is the most performance-damaging - a single blocked
> event loop thread prevents all other requests from
> being processed. @Blocking is the minimal fix.
> Field injection hides dependencies and breaks testability.
> Constructor injection enables `new OrderService(mock)`
> in tests. AtomicLong fixes the shared mutable state
> race condition.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Anti-Patterns are implementation patterns that
superficially work but undermine Micronaut's performance,
compile-time guarantees, or maintainability. Recognizing
these patterns is essential for production-quality Micronaut
code.

**Key anti-patterns:**

1. **Reflection-based instantiation inside beans**: calling
   `Class.forName()` or `Method.invoke()` bypasses Micronaut's
   DI model and breaks native image.

2. **ApplicationContext.getBean() scattered throughout
   service code**: service locator pattern creates hidden
   dependencies, makes testing harder, and bypasses
   compile-time injection.

3. **@Singleton on stateful request-scoped objects**: objects
   that should hold per-request state (user session, request
   tracking) in singletons create shared mutable state race
   conditions.

4. **Blocking I/O on Netty event loop threads**: JDBC calls,
   synchronous HTTP, `Thread.sleep()` in request handlers
   without `@ExecuteOn` block the event loop.

5. **@ConfigurationProperties with mutable public fields**:
   allows configuration mutation at runtime, breaking
   immutability expectations.

6. **Fat service beans doing everything**: large singleton
   services with 50+ methods violate single responsibility
   and make compile-time wiring complex.

**Why it matters:**

Anti-patterns accumulate technical debt that manifests as:
performance degradation, flaky tests, native image
incompatibility, and difficult-to-diagnose production issues.

---

### 🎓 Answers by Seniority

**Junior:** "Don't use field injection. Don't block
the event loop without @Blocking. Use @MicronautTest
only for integration tests."

**Senior:** "The most production-damaging anti-pattern:
blocking the Netty event loop with JDBC. Symptom:
throughput degrades as concurrency increases, even
if individual requests are fast. Diagnosis: high
thread contention on Netty worker threads in jstack."

---

### ⚠️ Common Misconceptions

**Misconception 1: If it works in development and tests,
it's not an anti-pattern.**

Many Micronaut anti-patterns are invisible in development
and low-traffic testing: blocking I/O only causes starvation
under load, shared mutable state only races under concurrency,
reflection breaks only in native image, service locator
anti-pattern only hurts when teams grow and tests become
fragile. Anti-patterns are FUTURE FAILURE MODES, not present
bugs. Code review with anti-pattern awareness prevents them
from reaching production at scale.

**Misconception 2: ApplicationContext.getBean() is
acceptable for dynamic bean resolution.**

Spring developers are familiar with `applicationContext.
getBean(Class.class)` for dynamic resolution. In Micronaut,
this WORKS but is an anti-pattern: it creates service locator
coupling (impossible to know dependencies from constructor
signature), breaks constructor injection testing (cannot mock),
and bypasses compile-time analysis (native image may not
include the resolved type). Prefer `Provider<T>` injection
for delayed initialization or `BeanContext.findBean()`
only when truly dynamic resolution is unavoidable.

**Misconception 3: Using @Singleton for all beans is
safe because Micronaut manages thread safety.**

Micronaut manages SCOPE (one instance) not THREAD SAFETY
(synchronization). A `@Singleton` with mutable fields
accessed by concurrent requests IS a data race unless
properly synchronized. Micronaut never adds synchronization
automatically. The rule: `@Singleton` beans MUST be
effectively immutable (fields set in constructor, never
changed) or explicitly thread-safe (synchronized, volatile,
Atomic*, ConcurrentHashMap).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Race condition in @Singleton bean
causes intermittent data corruption under load.**

Symptom: application works under low load but produces
corrupted results (wrong user data, incorrect calculations)
under concurrent requests. Root cause: `@Singleton` bean
has a mutable instance field (HashMap, counter, object state)
modified by request handlers without synchronization. One
thread reads while another writes. Diagnosis: reproduce
with concurrency testing (Gatling, JMeter); add logging to
show which thread reads/writes the shared field. Fix: make
fields immutable (set in constructor, no setters); use
`ConcurrentHashMap`, `AtomicLong`, or `volatile` for
legitimately shared mutable state.

**Failure Mode 2: "ApplicationContext.getBean() works
in tests but fails in native image build."**

Symptom: unit tests pass, JVM runs work, but native image
build fails or runtime crashes with "No bean of type [X]."
Root cause: `getBean(SomeClass.class)` used in service code;
GraalVM's static analysis does not trace which classes will
be passed to `getBean()` at runtime and excludes them.
Diagnosis: check native build output for missing class
warnings. Fix: replace dynamic `getBean()` with constructor
injection; or pre-declare the type in GraalVM configuration.

**Failure Mode 3: Blocking database call in reactive
controller causes cascading timeout under load.**

Symptom: under modest load (50 RPS), requests start timing
out; Netty thread dump shows JDBC blocking. Root cause:
controller uses `@Inject JdbcRepository repo` and calls
`repo.findById(id)` (blocking) directly in a Netty handler
without `@ExecuteOn(TaskExecutors.IO)`. Each blocked request
ties up one Netty worker thread. With 8 workers: 8
concurrent blocking calls saturate all threads. Diagnosis:
thread dump shows all Netty workers in BLOCKED state. Fix:
add `@ExecuteOn(TaskExecutors.IO)` to the blocking method;
or switch to reactive R2DBC repository.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Event loop blocking, field injection, mutable state |
| Staff | 12 min | AOT disabling, design anti-patterns, migration anti-patterns |

---

**[SENIOR] Q1 - How do you diagnose event loop
blocking in a Micronaut service?**

*Why they ask:* Production performance diagnosis.

Symptoms:
- Throughput drops under load (50+ concurrent requests)
- P99 latency spikes disproportionately
- Simple endpoints become slow
- Response time increases linearly with concurrency

Diagnosis:
```bash
# Step 1: Take thread dump under load
jstack <pid> > thread-dump.txt

# Step 2: Look for Netty event loop threads
grep -A 20 "nioEventLoopGroup" thread-dump.txt

# BLOCKED event loop indicates the problem:
# "nioEventLoopGroup-3-2" #25 ...
#   java.lang.Thread.State: WAITING
#     at sun.misc.Unsafe.park(...)
#     at java.util.concurrent.locks.LockSupport.park
#     at ...JdbcTemplate...execute  # JDBC on event loop!
```

> **Code walkthrough:** This at ...JdbcTemplate...execute  # JDBC on event loop!ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Metrics:
- Micronaut Micrometer: event loop thread state
- io.netty.eventloop.* metrics in Prometheus
- executor.active threads spiking to max

Fix and verify:
1. Add @Blocking to blocking endpoints
2. Re-run load test
3. Event loop threads should show RUNNABLE (not WAITING)
4. Throughput should recover

*What separates good from great:* Thread dump analysis
identifying Netty event loop threads blocked in JDBC.

| Interviewer Type| Emphasis|
|---|--------------------------------------------------------------------------|
| Technical Panel| Anti-patterns list, BAD vs GOOD patterns.|
| Hiring Manager| Knowing what NOT to do = fewer production incidents.|
| Bar Raiser| Event loop diagnosis, jstack analysis, mutable singleton state.|
| Peer Engineer| "Thread dump showed all Netty event loops in JDBC wait. Added @

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


# Micronaut Production Diagnostics

**Interview Weight:** critical - Diagnosing production
issues is the ultimate senior skill. Tested for
specific commands, metrics, and diagnosis workflows.

---

### 🎯 Model Answer

**30 seconds:**

> Production Micronaut diagnostics: /health for
> liveness/readiness, /metrics for counters/gauges/timers,
> /env for configuration verification, /beans for
> loaded bean definitions. Enable Micrometer Prometheus
> for metrics scraping. Distributed tracing with
> OpenTelemetry for request flow. For JVM analysis:
> jstack, jmap, async-profiler for CPU/allocation
> profiling.

**3 minutes (Senior):**

> Management endpoints (enable in production carefully):
>
> /health: UP/DOWN with configured detail visibility.
>   Use AUTHENTICATED for security.
>
> /metrics: Micrometer registry.
>   Custom metrics: @Timed, @Counted, MeterRegistry.
>   Prometheus: /prometheus endpoint for scraping.
>
> /env: shows all properties and their sources.
>   Sensitive: disable or restrict in production.
>   Use: verify which config file is active.
>
> /beans: all loaded BeanDefinition classes.
>   Use: verify expected beans are present.
>   Detect: missing beans, wrong implementation loaded.
>
> /loggers: change log levels at runtime.
>   PUT /loggers/io.example.service to DEBUG.
>   No restart required.
>   Use: debug production issues without redeployment.
>
> /refresh: refresh @Refreshable beans.
>   Use with distributed config (Consul, AWS SSM).
>   Config change → POST /refresh → beans reloaded.
>
> Diagnosis workflow:
>
> High latency:
>   1. /metrics → check timer percentiles
>   2. Distributed tracing → find slow span
>   3. /loggers → enable DEBUG for suspect service
>   4. jstack if still unclear (event loop blocking?)
>
> Memory leak:
>   1. /metrics → JVM memory, GC metrics
>   2. jmap -dump for heap analysis
>   3. MAT (Eclipse Memory Analyzer) for leak roots
>
> Missing bean / wrong impl injected:
>   1. /beans → verify bean is loaded
>   2. Check generated $Definition class
>   3. Check @Requires conditions

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about diagnosing
problems in production Micronaut services."

**(2) First principles:** "Diagnosis = observe → hypothesize →
test. Management endpoints give observation data.
Logs + traces give request-level detail."

**(3) Bridge:** "Micronaut management endpoints are
Spring Actuator equivalents: /health, /metrics, /loggers."

---

### 💻 Code Example

```bash
# Verify configuration at runtime
curl -s http://service:8080/env | jq '.'
# Shows all active property sources and values
# Confirms: which application.yml is loaded
# Confirms: environment variable overrides active

# Check all loaded beans
curl -s http://service:8080/beans | \
  jq '.beans[].type' | sort
# Find: is MyCustomBean loaded?
# Find: which implementation of OrderRepository?

# Change log level at runtime (no restart)
curl -X POST http://service:8080/loggers/io.example \
  -H "Content-Type: application/json" \
  -d '{"configuredLevel": "DEBUG"}'

# Check Prometheus metrics
curl http://service:8080/prometheus | \
  grep "order_created_total"
# Verify: counter incrementing

# OpenTelemetry trace for slow request
# In Jaeger UI: search by service + operation
# Find: which span is taking 2 seconds?

# Thread dump for event loop analysis
jstack $(pgrep -f "application.jar") \
  > /tmp/thread-dump.txt
grep -B2 -A20 "nioEventLoopGroup" \
  /tmp/thread-dump.txt

# Async profiler for CPU hotspots
./profiler.sh -d 30 -f /tmp/profile.html \
  $(pgrep -f "application.jar")
# Opens in browser: flame graph of CPU usage
# Find: which method is consuming CPU?

# Heap dump for memory leak diagnosis
jmap -dump:format=b,file=/tmp/heap.hprof \
  $(pgrep -f "application.jar")
# Open in Eclipse MAT
# Find: what objects are accumulating?
```

> **Code walkthrough:** The /env endpoint revealsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> which property source provided each value - essential
> for "why is the config wrong in production?" diagnosis.
> The /loggers POST enables DEBUG for a package at
> runtime without restart - see log messages immediately.
> Async profiler's flame graph shows CPU time per method
> as a visual stack. Thread dumps reveal event loop
> state under load.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Production Diagnostics is the practice of
instrumenting, observing, and troubleshooting Micronaut
applications in production using built-in and third-party
tools.

**How it works:**

Key diagnostic tools and techniques:

1. **Thread dumps**: `jstack <PID>` or `kill -3 <PID>`.
   Look for: Netty workers BLOCKED (blocking I/O), executor
   queues full (backpressure failure), deadlocks.

2. **Heap dumps**: `jmap -dump:format=b,file=heap.hprof <PID>`.
   Analyze with Eclipse Memory Analyzer (MAT) for: bean
   memory leaks, large collections, retained strings.

3. **Micronaut Management endpoints** (`/health`, `/metrics`,
   `/env`) for runtime state inspection.

4. **Distributed tracing** (OpenTelemetry/Zipkin) for
   cross-service latency analysis.

5. **Micrometer metrics**: JVM metrics (`jvm.memory.*`,
   `jvm.threads.*`), HTTP metrics (`http.server.requests`),
   custom gauges and counters.

6. **Structured logging**: JSON logs with trace ID, request
   ID, bean context for log correlation.

**Diagnostic commands:**

```bash
# Check health with details
curl http://app:8080/health?details=true

# Get all active metrics
curl http://app:8080/metrics

# JVM thread dump
jstack $(pgrep -f "myapp.jar")
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

**Why it matters:**

Production issues are diagnosed by observation, not by
reading code. Proper instrumentation enables root cause
identification within minutes.

---

### 🎓 Answers by Seniority

**Junior:** "/health for health status. /metrics for
Micrometer metrics. /loggers to change log levels
at runtime."

**Senior:** "For latency: start with Prometheus metrics
(percentiles), drill into distributed traces (find
the slow span), enable DEBUG logging for suspect code,
jstack if event loop blocking is suspected. For memory:
/metrics JVM memory trend, then heap dump to MAT."

**Staff:** "Observability trilogy: metrics (what is
happening), tracing (where in the request flow), logs
(why it happened). Each answers a different question.
Production diagnostics require all three. Missing
one dimension means slower diagnosis."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's fast startup means it
has no runtime performance monitoring needs.**

Startup performance is only ONE aspect of production
health. Micronaut services still need monitoring for:
steady-state memory growth (slow leaks), gradual latency
degradation (GC pressure, queue buildup), error rate spikes
(failed dependencies), and connection pool exhaustion
(too many concurrent requests). Startup speed is irrelevant
to these production runtime characteristics.

**Misconception 2: The /health endpoint accurately
reflects the application's ability to serve traffic.**

Health indicators report what they are programmed to check.
A health endpoint that only checks database connectivity
reports UP even when: the application is in an infinite
retry loop, CPU is at 100% due to a bug, all background
threads are deadlocked, or a key external API is down.
Design health indicators to check the CRITICAL PATH of
your application, not just technical connectivity.

**Misconception 3: Micrometer metrics auto-instrumentation
covers all performance dimensions.**

Micrometer auto-instruments JVM memory, threads, and HTTP
requests. It does NOT automatically instrument: business
metrics (order count, conversion rate), custom async
processing queues, external API call latency, and
application-specific state. Add custom Micrometer gauges
(`MeterRegistry.gauge()`) for domain-specific metrics that
matter for your SLOs.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Memory leak causes gradual OOM over
24-48 hours of production traffic.**

Symptom: heap usage slowly increases over hours; eventually
JVM crashes with `OutOfMemoryError`. Root cause: accumulated
references: Micronaut event listeners not deregistered,
large caches without eviction, reactive publishers not
completing (holding data in memory). Diagnosis: take heap
dumps at 1h, 4h, 8h intervals; compare object counts in
MAT to identify growing object types. Fix: check for
subscriptions without cancellation; configure cache maximum
size; review event listener lifecycle.

**Failure Mode 2: GC pause causes latency spikes visible
as P99 latency cliff.**

Symptom: P50/P95 latency is acceptable but P99 latency
spikes to 2-5 seconds at regular intervals. Root cause:
JVM G1GC or ZGC pause pausing all application threads.
Diagnosis: enable GC logging (`-Xlog:gc*:file=gc.log`);
correlate GC pause events with latency spike timestamps.
Fix: tune GC: increase young gen size, switch to ZGC
(sub-millisecond pauses for Micronaut services), or
reduce object allocation rate by pooling and reusing objects.

**Failure Mode 3: Production issue obscured by missing
correlation ID in logs across service calls.**

Symptom: investigating a production bug requires manually
correlating log entries across 5 services by timestamp
and guessing which requests belong together. Root cause:
no distributed trace ID or correlation ID propagated in
service call headers and included in log MDC. Diagnosis:
try to correlate logs for one user's failed request across
services using only timestamps. Fix: enable Micronaut
tracing propagation; configure Logback to include `traceId`
from MDC in all log lines; add correlation ID as a
structured field in logs.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Management endpoints, metrics, tracing, jstack |
| Staff | 14 min | Diagnosis workflows, /loggers, async profiler, heap analysis |

---

**[SENIOR] Q1 - Walk through diagnosing a memory
leak in a production Micronaut service.**

*Why they ask:* Production war story - proves real experience.

Step 1: Detect from metrics:
```bash
# Prometheus query: JVM heap used
jvm_memory_used_bytes{area="heap"}
# Growing over time: memory leak
# Stable: GC is working, not a leak
```

> **Code walkthrough:** This Stable: GC is working, not a leak example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Step 2: Identify the generation leaking:
```bash
# Old generation growing = retention issue
jvm_memory_used_bytes{id="G1 Old Gen"}
# Not decreasing after GC = something is being retained
```

> **Code walkthrough:** This Not decreasing after GC = something is being retained example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Step 3: Take heap dump when symptoms peak:
```bash
jmap -dump:format=b,file=/tmp/heap.hprof \
  $(pgrep -f "application.jar")
```

> **Code walkthrough:** This Not decreasing after GC = something is being retained example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Step 4: Analyze with Eclipse MAT:
- Open heap dump → Leak Suspects report
- Look for: large object arrays, large maps
- Common leaks:
  - Cache without eviction policy
  - Session/request context not cleaned up
  - Static collections accumulating entries
  - @RequestScope beans not being destroyed

Step 5: Fix and verify:
- Add eviction to cache (size/time limit)
- Ensure @PreDestroy runs for @RequestScope
- Check Micronaut cache configuration
- Re-run: verify heap stabilizes

*What separates good from great:* Starting with
metrics (detect trend early) rather than waiting for
OOM, and using MAT leak suspects report directly.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Management endpoints, /loggers, /beans. |
| Hiring Manager | Can you diagnose production issues? |
| Bar Raiser | Complete diagnosis workflow, async profiler, heap analysis, Prometheus queries. |
| Peer Engineer | "Found the leak in 20 minutes: a static Map in a tenant context was never cleared. MAT pointed directly to it." |

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



