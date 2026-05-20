---
layout: default
title: "Spring - Production and Diagnostics"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 11
permalink: /interview/spring/production-and-diagnostics/
topic: Spring
subtopic: Production and Diagnostics
keywords:
  - Spring Boot Startup Performance Diagnostics
  - Transaction Propagation Failures and Debugging
  - Spring Security Filter Chain Debugging
  - Memory Leaks and ApplicationContext Lifecycle Issues
  - Spring Boot Production Anti-Patterns
difficulty_range: hard
status: in-progress
version: 3
---

# Spring - Production and Diagnostics

L4 Expert keywords for Spring Framework. Production ownership,
failure diagnosis, and the debugging skills that separate senior
engineers from Staff engineers.

---

---

# Spring Boot Startup Performance Diagnostics

**TL;DR** - Diagnose slow Spring Boot startup using the startup
endpoint, conditional evaluation report, bean instantiation
timing, and JFR events to identify which auto-configurations,
bean post-processors, or component scans are consuming time.

---

### The Problem This Solves

A Spring Boot application that started in 8 seconds locally
now takes 45 seconds in production. The team added more
dependencies, more auto-configurations, more component scanning,
and startup time crept up. Nobody noticed because CI never
measured it. Now Kubernetes health checks timeout, pods restart
in loops, and deployments take 20 minutes to roll out across
50 instances.

Slow startup in containerized environments directly impacts:
deployment velocity (rolling updates take longer), autoscaling
responsiveness (new pods can't handle traffic fast enough),
and developer productivity (integration tests that boot the
full context take 30+ seconds each).

---

### Textbook Definition

Spring Boot startup performance diagnostics is the systematic
process of measuring, attributing, and optimizing the time
spent in each phase of application context initialization -
from JVM class loading through bean definition parsing,
conditional evaluation, bean instantiation, dependency
injection, and embedded server startup.

---

### Understand It in 30 Seconds

**One line:** Find which beans/auto-configurations are slow
and either defer them, remove them, or replace them.

**Analogy:** Diagnosing slow startup is like diagnosing why a
restaurant takes 45 minutes to open. Is it the kitchen setup
(bean creation)? The menu printing (component scan)? The
inspection (health checks)? You can't fix "slow" - you fix
the specific phase that's slow.

**Key insight:** 80% of startup time is typically caused by
3-5 beans or auto-configurations. Finding those 3-5 culprits
is the entire problem.

---

### First Principles

Spring Boot startup consists of sequential phases:

1. **JVM bootstrap** - class loading, static initializers
2. **SpringApplication initialization** - environment setup,
   banner, listener notification
3. **Bean definition loading** - component scan + auto-config
   condition evaluation
4. **Bean instantiation** - creating bean instances in
   dependency order
5. **Post-processing** - BeanPostProcessors modify beans
6. **Embedded server start** - Tomcat/Jetty thread pool init
7. **ApplicationRunner** - custom startup code

Each phase can be independently measured and optimized.

---

### Mental Model / Analogy

```
┌────────────────────────────────────────┐
│     Spring Boot Startup Timeline       │
├────────────────────────────────────────┤
│                                        │
│ JVM Load     ████░░░░░░░░░░░ 10%     │
│ Env/Config   ██░░░░░░░░░░░░░  5%     │
│ ComponentScan████████░░░░░░░░ 20%     │
│ AutoConfig   ██████████░░░░░░ 25%     │
│ BeanCreate   ████████████░░░░ 30%  <- │
│ Server Start ████░░░░░░░░░░░ 10%     │
│                                        │
│ <- HERE: Bean creation is usually the  │
│    largest slice. Find the slow beans. │
└────────────────────────────────────────┘
```

---

### How It Works - Five Levels

**Level 1 (Anyone):** Your app is slow to start. You need to
find which parts are taking the most time and speed them up.

**Level 2 (Junior):** Spring Boot has a startup endpoint
(`/actuator/startup`) that records every step of the startup
process with millisecond timing. Enable it with
`spring.application.startup=buffered` and query it after boot.

**Level 3 (Mid):** The startup actuator exposes
`StartupTimeline` with events like
`spring.beans.instantiate` (per bean, with duration),
`spring.context.config-classes.parse`,
`spring.context.beans.post-process`. Sort by duration to find
the top 5 slowest operations. Common culprits: Hibernate
metadata building, connection pool validation, classpath
scanning of large packages, and Flyway/Liquibase migrations.

**Level 4 (Senior/Staff):** Beyond Actuator, use JFR
(Java Flight Recorder) for deep analysis:
`-XX:StartFlightRecording=filename=startup.jfr,duration=60s`.
JFR captures class loading counts (excessive = fat classpath),
thread contention during bean creation, I/O blocking during
config loading, and GC pauses during startup. Combine with
`-Dspring.context.checkpoint=onRefresh` for CRaC
(Coordinated Restore at Checkpoint) to snapshot a warmed-up
context and restore in milliseconds.

**Level 5 (Distinguished):** The fundamental tension in
startup optimization is between eager initialization (fail
fast, predictable behavior) and lazy initialization (fast
start, first-request latency). Spring Boot 3.2+ offers AOT
(Ahead of Time) processing that resolves this: at build time,
generate the bean definitions, condition evaluations, and
proxy classes. Runtime startup skips all reflection-based
scanning. GraalVM native image takes this further - eliminate
the JVM entirely. The trade-off shifts from "startup time vs
runtime flexibility" to "build time vs startup time."

---

### How It Works - Mechanism

**Startup endpoint output structure:**

```
GET /actuator/startup

{
  "timeline": {
    "startTime": "2024-01-15T10:00:00Z",
    "events": [
      {
        "startupStep": {
          "name": "spring.beans.instantiate",
          "tags": [
            {"key":"beanName",
             "value":"entityManagerFactory"}
          ]
        },
        "duration": "PT3.2S"  <- HERE: 3.2s!
      },
      {
        "startupStep": {
          "name": "spring.beans.instantiate",
          "tags": [
            {"key":"beanName",
             "value":"flywayInitializer"}
          ]
        },
        "duration": "PT2.8S"  <- HERE: 2.8s!
      }
    ]
  }
}
```

**Typical slow beans and why:**

| Bean                   | Why Slow                   |
| ---------------------- | -------------------------- |
| entityManagerFactory   | Hibernate metadata scan    |
| dataSource             | Connection pool validation |
| flywayInitializer      | Running migrations         |
| redisConnectionFactory | TCP connect + auth         |
| webServerStartStop     | Thread pool creation       |

---

### Code Example

```java
// BAD: No startup diagnostics, guessing at slowness
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        // No timing, no visibility
        SpringApplication.run(App.class, args);
    }
}

// GOOD: Instrumented startup with timing
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication app =
            new SpringApplication(App.class);
        app.setApplicationStartup(
            new BufferedStartup(2048)
        );
        ConfigurableApplicationContext ctx =
            app.run(args);

        // Log top 10 slowest beans
        ctx.getBean(StartupEndpoint.class)
           .startup()
           .getTimeline()
           .getEvents()
           .stream()
           .sorted(comparing(
               e -> e.getDuration().toMillis(),
               reverseOrder()))
           .limit(10)
           .forEach(e -> log.info(
               "{}ms - {}",
               e.getDuration().toMillis(),
               e.getStartupStep().getName()
           ));
    }
}
```

```yaml
# application.yml - Enable startup endpoint
management:
  endpoint:
    startup:
      enabled: true
  endpoints:
    web:
      exposure:
        include: startup,health,metrics

# Lazy init for faster startup (trade-off:
# first request pays initialization cost)
spring:
  main:
    lazy-initialization: true
```

---

### Quick Reference Card

| Field              | Value                                     |
| ------------------ | ----------------------------------------- |
| Category           | Production Diagnostics                    |
| Startup endpoint   | `/actuator/startup` (buffered mode)       |
| JFR command        | `-XX:StartFlightRecording=filename=s.jfr` |
| Conditional report | `--debug` flag at startup                 |
| Lazy init          | `spring.main.lazy-initialization=true`    |
| AOT mode           | `mvn spring-boot:process-aot`             |
| Native image       | `mvn -Pnative native:compile`             |
| CRaC               | `spring.context.checkpoint=onRefresh`     |
| Typical target     | < 5s for containerized services           |

**3 things to remember:**

1. `/actuator/startup` gives per-bean timing - sort by duration
2. Top culprits: Hibernate metadata, connection pools, migrations
3. AOT/native image eliminates reflection scanning entirely

**One-liner:** "You can't optimize 'slow startup' - you optimize
the specific beans eating your startup budget."

---

### Mastery Checklist

- [ ] DIAGNOSE: Use startup endpoint to find top 5 slowest beans
- [ ] MEASURE: JFR recording of startup with class loading stats
- [ ] OPTIMIZE: Defer non-critical beans with @Lazy or profiles
- [ ] ARCHITECT: Evaluate AOT vs lazy init vs native image
      trade-offs for deployment environment
- [ ] IMPLEMENT: Kubernetes readiness probe that matches actual
      startup time (not arbitrary 30s delay)

---

### Surprising Truth

Spring Boot 3.2's startup endpoint revealed that in many
applications, the single slowest startup step isn't your code -
it's Hibernate scanning every `@Entity` class to build the
metamodel. Applications with 200+ entities spend 5-10 seconds
just in Hibernate initialization. The fix isn't "optimize
Hibernate" - it's "use a persistent second-level metadata
cache" or "split into bounded contexts with fewer entities."

---

### Common Misconceptions

| #   | Misconception                                  | Reality                                                                   | Why It Matters                                              |
| --- | ---------------------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------- |
| 1   | `spring.main.lazy-initialization=true` is free | First request pays the initialization cost; latency spike on first call   | Acceptable for dev, dangerous for prod without warmup       |
| 2   | Native image always means fast startup         | Build takes 5-10 minutes; reflection-heavy code needs hints               | Trade-off is build time + compatibility vs startup speed    |
| 3   | More memory = faster startup                   | Startup is CPU-bound (class loading, reflection); more heap doesn't help  | Give more CPU cores, not more RAM, to speed up startup      |
| 4   | Component scan is the bottleneck               | Usually bean INSTANTIATION (I/O: DB connect, HTTP calls) dwarfs scan time | Don't micro-optimize scan paths; fix slow bean constructors |

---

### Failure Modes and Diagnosis

| Failure Mode                     | Symptom                                           | Diagnostic Command                                        | Fix                                                       |
| -------------------------------- | ------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |
| K8s pod restart loop             | CrashLoopBackOff, OOMKilled during startup        | `kubectl describe pod`; check `initialDelaySeconds`       | Increase startup probe timeout; reduce memory during init |
| Connection pool timeout on start | HikariPool-1 - Connection is not available        | `spring.datasource.hikari.initialization-fail-timeout=-1` | Allow async pool init; use health check for readiness     |
| Hibernate metadata timeout       | `SchemaManagementException` on large entity count | JFR: `jdk.ClassLoad` events during EntityManagerFactory   | Split persistence units; use metadata cache               |
| Flyway blocking startup          | Waiting for advisory lock in clustered deploy     | `SELECT * FROM flyway_schema_history`                     | Use `spring.flyway.enabled=false` + out-of-band migration |

---

### Interview Deep-Dive

**Timing Table:**

| Question | Type         | Difficulty | Time |
| -------- | ------------ | ---------- | ---- |
| Q1       | CONCEPTUAL   | MID        | 90s  |
| Q2       | DEBUGGING    | SENIOR     | 120s |
| Q3       | PRODUCTION   | SENIOR     | 120s |
| Q4       | TRADE-OFF    | STAFF      | 150s |
| Q5       | HANDS-ON     | MID        | 90s  |
| Q6       | ARCHITECTURE | STAFF      | 150s |
| Q7       | DEBUGGING    | SENIOR     | 120s |
| Q8       | PRODUCTION   | SENIOR     | 120s |
| Q9       | TRADE-OFF    | STAFF      | 150s |
| Q10      | BEHAVIORAL   | SENIOR     | 120s |
| Q11      | HANDS-ON     | MID        | 90s  |
| Q12      | ARCHITECTURE | STAFF      | 150s |

**Q1: What are the phases of Spring Boot startup and how do you measure each?** [MID]

Spring Boot startup consists of these measurable phases: (1) JVM bootstrap - class loading, static initializers (~0.5-2s depending on classpath size). Measure with JFR `jdk.ClassLoad` events. (2) SpringApplication initialization - creating the Application object, detecting web type, loading spring.factories. Measured in startup logs at DEBUG level. (3) Environment preparation - loading application.yml, system properties, environment variables, profile resolution. Visible in `PropertySource` ordering via `--debug`. (4) Context refresh - the big phase: component scan (finding bean definitions), auto-configuration condition evaluation, bean instantiation in dependency order, BeanPostProcessor execution. This is where 70-80% of time goes. Measurable via `/actuator/startup`. (5) Embedded server start - Tomcat/Jetty initializes connectors, thread pool, SSL context. (6) ApplicationRunner/CommandLineRunner callbacks - your custom startup code.

The key tool is `BufferedStartup` which records a `StartupTimeline` exposed via `/actuator/startup`. Enable with `spring.application.startup=buffered`. Each event includes name, tags (beanName, etc.), and duration. Sort by duration descending to find the top offenders immediately.

_What separates good from great:_ Know that phases 1-2 are JVM/Spring framework overhead (largely fixed), while phases 3-5 are where YOUR choices matter. Optimizing startup means optimizing bean instantiation - which beans you create, when you create them, and what I/O they perform during init.

**Q2: Your service startup jumped from 8s to 45s after a dependency update. Walk through your diagnostic process.** [SENIOR]

Systematic approach: (1) Bisect the change - if it's one dependency update, rollback and confirm the version is the cause. If multiple changed, bisect. (2) Enable the conditional evaluation report with `--debug` and compare the auto-configuration report before and after. Look for new auto-configurations that matched (new dependency pulled in a starter that auto-configures heavy infrastructure). (3) Enable `/actuator/startup` (BufferedStartup) and query after boot. Sort events by duration. The delta between old and new will show exactly which beans are new and how long they take. (4) If the slow bean is clear (e.g., `elasticsearchClient` taking 30s because it's connecting to a cluster that doesn't exist in dev), fix the connection config or make it lazy. (5) If it's diffuse (many beans each 1-2s slower), use JFR to check: did class loading count increase dramatically? (fat dependency tree). Did GC pauses increase? (more objects during init).

In my experience, the most common cause of sudden startup regression is a transitive dependency pulling in an auto-configuration that eagerly connects to an external service (Redis, Elasticsearch, Kafka) with default timeouts. The service isn't available in the new environment, and the connection attempt blocks for 30s before failing. Fix: exclude the auto-configuration or configure the connection properties.

_What separates good from great:_ Demonstrate that you have a reproducible diagnostic playbook, not ad-hoc guessing. "I don't investigate slow startup - I measure it. The startup endpoint tells me exactly where the time went in under 60 seconds."

**Q3: How do you optimize Spring Boot startup for Kubernetes rolling deployments where 50 pods need to restart?** [SENIOR]

For K8s rolling deployments with 50 pods, startup time directly impacts deployment duration. If each pod takes 45s to become ready and you're rolling 5 at a time, that's 10 batches x 45s = 7.5 minutes minimum. Optimization strategy: (1) Profile-guided lazy initialization - use `spring.main.lazy-initialization=true` with a warmup endpoint that pre-loads critical beans during the readiness probe window. This way startup is fast (beans are lazy) but the pod doesn't receive traffic until warmed up. (2) Connection pool async initialization - set `spring.datasource.hikari.initialization-fail-timeout=-1` so HikariCP doesn't validate connections during startup. The readiness probe checks actual connectivity. (3) Hibernate metadata caching - use `hibernate.cache.use_second_level_cache=true` with a distributed cache (Redis) for the metamodel. Second pod onwards loads cached metadata instead of rebuilding. (4) Parallel bean initialization (Spring 6.2+) - experimental support for initializing independent beans concurrently. Reduces wall-clock time for I/O-heavy bean creation.

For the nuclear option: Spring AOT + GraalVM native image drops startup to 200-500ms. But trade-offs are real: no runtime reflection (breaks some libraries), longer build times (5-10 min), different debugging experience, and you lose JFR/JMX in some configurations. For a 50-pod deployment, native image means full rollout in under 2 minutes.

The Kubernetes configuration must match: use `startupProbe` (not just readiness) with `failureThreshold * periodSeconds > max_startup_time`. Example: `failureThreshold: 30, periodSeconds: 2` gives 60s before K8s kills the pod.

_What separates good from great:_ Frame it as a system-level optimization, not just Spring config. "Fast startup alone doesn't help if your readiness probe lies. I ensure the pod is genuinely ready (connections established, caches warmed) before K8s routes traffic to it."

**Q4: Compare lazy initialization, AOT processing, native images, and CRaC for startup optimization. When would you choose each?** [STAFF]

Four approaches with different trade-off profiles:

**Lazy initialization** (`spring.main.lazy-initialization=true`): Defers bean creation until first use. Startup drops 50-80%. Cost: first request to each bean type pays the initialization penalty. Latency spike on first request. Good for: dev/test environments, services with rarely-used features. Bad for: latency-sensitive production services without warmup strategy.

**AOT processing** (Spring 6+ AOT engine): At build time, evaluates conditions, generates bean definitions as code, eliminates runtime reflection for bean creation. Startup drops 30-50% with full runtime flexibility preserved. Cost: longer build (1-2 min extra), some dynamic features limited (@Profile evaluation happens at build time). Good for: production services that need fast startup but can't go native. Bad for: applications relying heavily on runtime @Conditional logic that changes per deploy.

**GraalVM native image**: Compiles to platform binary. Startup 50-200ms. Tiny memory footprint. Cost: 5-10 minute builds, no runtime reflection without hints, limited monitoring (no JFR in older versions), some libraries incompatible, debugging is different. Good for: serverless/FaaS, CLI tools, scale-to-zero services. Bad for: long-running services where steady-state throughput matters more than startup (JIT > AOT for peak perf).

**CRaC (Coordinated Restore at Checkpoint)**: Takes a snapshot of a fully-warmed JVM (all classes loaded, JIT-compiled, connections established). Restore from checkpoint in 50-100ms with full JIT performance. Cost: checkpoint management (snapshot invalidation when code changes), open file descriptors/sockets must be re-established on restore, security concerns (heap dump contains secrets). Good for: long-running services that need both fast startup AND peak throughput. Bad for: services where secrets management prohibits heap snapshots.

My decision framework: Dev/test → lazy init. Cloud-native microservice → AOT. Serverless → native image. Performance-critical service with fast scaling needs → CRaC.

_What separates good from great:_ Articulate that this isn't just a performance decision - it's an operational one. "Native image means my CI pipeline takes 10 minutes longer per build. For 50 services building 10 times/day, that's 83 hours of compute per day. The startup savings must justify the CI cost."

**Q5: Write a custom Spring Boot startup metric that reports per-phase timing to Prometheus.** [MID]

```java
@Component
@RequiredArgsConstructor
public class StartupMetrics
    implements ApplicationListener<ApplicationReadyEvent> {

    private final MeterRegistry registry;
    private final BufferedStartup startup;

    @Override
    public void onApplicationEvent(
        ApplicationReadyEvent event) {

        Map<String, Long> phaseDurations =
            startup.getBufferedTimeline()
                .getEvents().stream()
                .collect(Collectors.groupingBy(
                    e -> e.getStartupStep().getName(),
                    Collectors.summingLong(
                        e -> e.getDuration().toMillis())
                ));

        phaseDurations.forEach((phase, ms) ->
            registry.gauge(
                "spring.startup.phase.duration.ms",
                Tags.of("phase", phase),
                ms
            )
        );

        // Total startup time
        registry.gauge(
            "spring.startup.total.ms",
            event.getTimeTaken().toMillis()
        );
    }
}
```

This registers gauges per startup phase in Prometheus format (`spring_startup_phase_duration_ms{phase="spring.beans.instantiate"} 3200`). Grafana dashboard then shows startup time trends across deployments, alerting if startup exceeds the SLO.

_What separates good from great:_ Know that `ApplicationReadyEvent` fires AFTER the application is fully initialized and ready to serve traffic. Using `ApplicationStartedEvent` instead would miss post-processor time. The metric captures the full picture.

**Q6: How would you design a startup optimization strategy for an organization running 200+ Spring Boot microservices?** [STAFF]

At 200+ services, individual optimization doesn't scale. I'd implement a platform-level strategy: (1) Observability first - mandate that every service exports startup timing metrics (custom Micrometer gauge for total startup + top-5 bean durations). Dashboard showing p50/p95/p99 startup times across all services. Alert on regression (startup increased >20% from last deploy). (2) Shared starter with defaults - a company-internal Spring Boot starter that sets `spring.main.lazy-initialization=false` (explicit), enables BufferedStartup, configures async connection pool init, and sets Hibernate metadata caching. Teams inherit good defaults without thinking. (3) Startup SLO per tier - tier-1 critical services: <5s. tier-2 standard: <15s. tier-3 batch: <30s. Services violating SLO get flagged in the platform dashboard. (4) AOT pipeline integration - modify the CI template to run `process-aot` in the build phase. All new services get AOT by default. Existing services opt-in with a flag. (5) Native image for candidate services - identify stateless, low-dependency services (health checks, config proxies) as native image candidates. These become the reference implementations.

Governance: startup time is a deployment metric reviewed in architecture council alongside latency p99, error rate, and cost. Services that consistently regress get an "optimization sprint" in the next quarter.

_What separates good from great:_ Frame it as a platform engineering problem, not an application problem. "I don't optimize 200 services individually - I build platform tooling that makes fast startup the default and slow startup visible."

**Q7: A Spring Boot service shows 30s startup in production but 5s locally. Same code, same config. What's different?** [SENIOR]

The most common causes of environment-specific startup slowness: (1) DNS resolution - production resolves hostnames (database, Redis, Kafka) via DNS which may have latency or TTL issues. Locally you use `localhost` or IP addresses. Diagnostic: add `-Dnetworkaddress.cache.ttl=10` and check startup logs for connection attempt timings. (2) Network latency to dependencies - HikariCP validates connections on startup by default. If the database is in a different AZ with 5ms latency and you validate 10 connections, that's 50ms just for the pool. But if the network has packet loss, each validation might timeout at 30s. Diagnostic: `curl -o /dev/null -w "%{time_connect}" http://db-host:5432`. (3) Secrets/config fetching - production loads secrets from Vault/AWS Secrets Manager/Spring Cloud Config. Each fetch is an HTTP call. 20 secrets x 500ms = 10s. Locally, secrets are in application-local.yml. (4) Classpath differences - production Docker image might include APM agents (New Relic, Datadog) that instrument every class load. Agent initialization adds 5-15s. (5) Container CPU throttling - your local machine has 8 cores; the production pod has 500m CPU limit. Class loading is CPU-intensive; half a core means 4x slower.

Diagnostic process: (1) SSH into a production pod and check actual CPU/memory limits. (2) Enable BufferedStartup and compare the phase breakdown. (3) Check for network calls during bean initialization (tcpdump during startup). (4) Check for JVM agents in JAVA_TOOL_OPTIONS.

_What separates good from great:_ Immediately suspect CPU throttling or network I/O rather than code issues. "Same code + different timing = different environment. I check: CPU limits, network latency to deps, agent overhead, and config source latency - in that order."

**Q8: How do you implement graceful shutdown optimization alongside startup optimization?** [SENIOR]

Startup and shutdown are symmetric concerns - both affect deployment velocity. Configuration: `server.shutdown=graceful` enables Tomcat to finish in-flight requests before stopping. `spring.lifecycle.timeout-per-shutdown-phase=30s` caps how long each phase waits. The shutdown sequence is: (1) Stop accepting new requests (return 503 to load balancer health check). (2) Wait for in-flight requests to complete (up to timeout). (3) Close database connections. (4) Flush metrics/logs buffers. (5) Exit.

For Kubernetes: set `preStop` hook with a sleep (e.g., 5s) to allow the load balancer to deregister the pod BEFORE the app starts shutting down. Without this, traffic arrives at a pod that's already draining. The total shutdown budget is: `preStop` (5s) + graceful shutdown (30s) + termination grace period must be > sum of both.

Optimization: implement `SmartLifecycle` beans with explicit `stop()` methods that release resources in parallel rather than sequentially. Default Spring shuts down beans in reverse creation order (sequential). For services with multiple connection pools, parallel shutdown saves 10-20s.

Connecting to startup: if shutdown takes 30s and startup takes 30s, a rolling restart of one pod takes 60s minimum. Optimizing both cuts deployment time in half. Measure both: `spring.shutdown.total.ms` gauge alongside the startup gauge.

_What separates good from great:_ Understand the interaction with Kubernetes: "The pod lifecycle is: preStop → SIGTERM → graceful shutdown → SIGKILL if terminationGracePeriodSeconds exceeded. I configure all four to work together, not independently."

**Q9: When should you NOT optimize startup time? What's the cost of over-optimization?** [STAFF]

Don't optimize startup if: (1) The service restarts rarely (once per deploy, deploy weekly). Saving 30s on weekly restart is 2 minutes/month of saved time vs hours of engineering effort. (2) The service is a singleton (not horizontally scaled). Startup time doesn't affect deployment duration when there's only one instance with a maintenance window. (3) Optimizations sacrifice debuggability - native image loses JFR, CRaC adds operational complexity, lazy init masks startup failures until production traffic arrives. (4) The startup SLO is already met - spending a sprint optimizing from 5s to 3s when K8s gives you 60s is premature optimization.

Cost of over-optimization: Lazy initialization means errors surface at runtime instead of startup (fail-late instead of fail-fast). AOT means some Spring features don't work (dynamic @Conditional, runtime profile switching). Native image means you can't attach async-profiler or use JFR for production debugging. CRaC means managing checkpoint lifecycle and secrets rotation. Each optimization trades runtime capability for startup speed.

My framework: (1) Measure actual deployment impact (how many seconds does slow startup add to total deployment time?). (2) Compare against engineering cost of optimization. (3) If deployment time < 5 minutes for full rollout, startup optimization is probably not the highest-impact work. (4) If deployment time > 15 minutes due to startup, it's blocking engineering velocity and worth investing in.

_What separates good from great:_ Demonstrate cost-benefit thinking: "I once spent a week getting native image working for a service that deployed twice a month. The ROI was negative. I learned to ask 'how often does this matter?' before optimizing."

**Q10: Tell me about a time you diagnosed and fixed a slow-starting Spring Boot service.** [SENIOR]

In a previous role, our payment service startup went from 12s to 55s after we added a new fraud-detection dependency. Kubernetes was killing pods before they became ready, causing a cascading restart loop during deploys.

Diagnosis: (1) I enabled BufferedStartup and found `fraudDetectionClient` bean taking 35s. (2) The fraud SDK initialized by downloading ML model files from S3 on bean creation - a 2MB download that was fast from EC2 but blocked the thread. (3) The SDK had no async initialization option.

Fix (layered approach): (1) Immediate: increased K8s startupProbe timeout from 30s to 90s to stop the restart loop. (2) Short-term: wrapped the fraud client in a `@Lazy` proxy so it initialized on first request, not startup. Added a background @Scheduled task to trigger initialization 5s after ApplicationReadyEvent. (3) Long-term: worked with the fraud team to add a "pre-downloaded model" option where CI bakes the model file into the Docker image. Startup went from 55s → 15s (lazy) → 12s (pre-downloaded model).

Lesson: "The slowest bean is often a third-party SDK doing I/O in its constructor. You can't always fix the SDK, but you can always defer or pre-bake the expensive operation."

_What separates good from great:_ Show the three horizons: immediate mitigation (stop the bleeding), short-term fix (architectural workaround), and long-term solution (root cause elimination). Mention that you communicated the timeline to the team at each stage.

**Q11: How do you write a startup performance regression test?** [MID]

```java
@SpringBootTest
@AutoConfigureObservability
class StartupPerformanceTest {

    @Autowired
    ApplicationContext context;

    @Autowired
    ConfigurableApplicationContext ctx;

    @Test
    void startupCompletesWithinBudget() {
        // Access startup timeline
        BufferedStartup startup = (BufferedStartup)
            ctx.getBean(ApplicationStartup.class);

        Duration total = startup
            .getBufferedTimeline()
            .getEvents().stream()
            .map(StartupTimeline.TimelineEvent
                 ::getDuration)
            .reduce(Duration.ZERO, Duration::plus);

        // Hard cap: startup must be < 10s
        assertThat(total)
            .isLessThan(Duration.ofSeconds(10));

        // No single bean > 3s
        startup.getBufferedTimeline()
            .getEvents().stream()
            .filter(e -> e.getDuration()
                .compareTo(Duration.ofSeconds(3)) > 0)
            .forEach(e -> fail(
                "Slow bean: " +
                e.getStartupStep().getName() +
                " took " + e.getDuration()
            ));
    }
}
```

Run this in CI. If a new dependency adds a slow bean, the test fails immediately rather than discovering it in production 3 weeks later.

_What separates good from great:_ Know that this test should use a realistic profile (not test-only mocks that skip the slow initialization). Mock external network calls but keep bean creation real. Otherwise you're testing a fiction.

**Q12: How does Spring Boot 3.x AOT processing change the startup optimization landscape?** [STAFF]

Spring Boot 3's AOT engine fundamentally changes what happens at startup by shifting work to build time. At build time: (1) All `@Conditional` annotations are evaluated and resolved. The result is code-generated bean definitions that don't need runtime condition checks. (2) All reflection-based operations (component scan, annotation processing) produce generated code that calls constructors directly. (3) Proxy classes are generated at build time, eliminating CGLIB generation at runtime.

At runtime, the ApplicationContext loads pre-generated `BeanDefinition` registrations (plain Java method calls) instead of scanning classpath, parsing annotations, and evaluating conditions. This eliminates the entire "condition evaluation" and "component scan" phases.

Impact: (1) Startup time drops 30-50% without any code changes. (2) The startup profile shifts - bean INSTANTIATION (I/O operations) becomes 90%+ of startup time since reflection overhead is gone. (3) Some patterns break: `@Profile` conditions are frozen at build time (can't switch profiles at deploy time), `@ConditionalOnProperty` requires the property at build time, and reflection-based libraries need GraalVM reachability metadata.

Migration strategy for existing services: (1) Run `mvn spring-boot:process-aot` and check for warnings. (2) Test with AOT mode enabled but JVM (not native) - this catches most issues without the full native image build. (3) Add `RuntimeHints` for any reflection-heavy code. (4) Gradually: start with stateless services that have few dynamic conditions.

_What separates good from great:_ Understand that AOT is a spectrum, not binary. You can use AOT processing (generated bean definitions) without native image (still runs on JVM with JIT). This gives 30-50% startup improvement while preserving JFR, JMX, and all debugging tools.

---

### Related Keywords

**Prerequisites:** What a Spring Application Looks Like,
Spring Boot Project Structure and Conventions

**Builds on:** Bean Lifecycle, Auto-Configuration,
ApplicationContext

**Leads to:** Spring Boot Production Anti-Patterns, Memory
Leaks and ApplicationContext Lifecycle Issues

**Alternatives:** Quarkus dev mode (hot-reload avoids restart),
Micronaut compile-time DI (no reflection at startup)

---

---

# Transaction Propagation Failures and Debugging

**TL;DR** - Transaction propagation defines how methods join or
create transactions. Most failures come from self-invocation
bypassing the proxy, incorrect propagation types, and
checked exceptions not triggering rollback by default.

---

### The Problem This Solves

A developer adds `@Transactional` to a service method, writes
a test, and everything works. In production, data is partially
committed after an exception - the transaction didn't roll back.
Or worse: two methods should run in separate transactions but
share one, so a failure in the second rolls back the first's
valid work.

Transaction propagation bugs are insidious because they're
invisible in happy-path testing. They surface only under
failure conditions in production, causing data corruption that
may not be detected for days.

---

### Textbook Definition

Transaction propagation defines how a transactional method
behaves when called within the context of an existing
transaction. Spring's `@Transactional` annotation supports
seven propagation types (REQUIRED, REQUIRES_NEW, NESTED,
SUPPORTS, NOT_SUPPORTED, MANDATORY, NEVER) that control
whether the method joins, creates, suspends, or rejects
transactions.

---

### Understand It in 30 Seconds

**One line:** Propagation controls what happens when a
@Transactional method calls another @Transactional method.

**Analogy:** Think of transactions as conversations. REQUIRED
means "join the current conversation or start a new one."
REQUIRES_NEW means "excuse me, I need a private conversation."
MANDATORY means "I refuse to talk unless someone started the
conversation already."

**Key insight:** Spring transactions work through proxies. If
you call a method on the same object (self-invocation), the
proxy is bypassed and the @Transactional annotation is ignored.
This is the #1 cause of transaction bugs.

---

### First Principles

Spring's transaction management rests on:

1. **Proxy-based AOP** - @Transactional creates a proxy that
   intercepts method calls to begin/commit/rollback
2. **Thread-local binding** - the current transaction is bound
   to the current thread via TransactionSynchronizationManager
3. **Propagation semantics** - define how nested transactional
   calls interact with the current thread's transaction
4. **Rollback rules** - by default, only unchecked exceptions
   (RuntimeException) trigger rollback; checked exceptions
   commit (Java EE legacy behavior)

---

### Mental Model / Analogy

```
External call → Proxy → Method

 Caller    Proxy          Target
   │         │               │
   │─call──>│               │
   │         │─begin tx─────>│
   │         │               │─execute
   │         │               │─call self()
   │         │               │  <- HERE:
   │         │               │  No proxy!
   │         │               │  @Transactional
   │         │               │  is IGNORED
   │         │<─return───────│
   │         │─commit tx     │
   │<────────│               │
```

---

### How It Works - Five Levels

**Level 1 (Anyone):** When you mark a method with
@Transactional, Spring wraps the database operations in that
method so they either all succeed or all fail together.

**Level 2 (Junior):** The `propagation` attribute controls
nesting. `REQUIRED` (default) joins an existing transaction
or creates one. `REQUIRES_NEW` always creates a new one,
suspending the current. This matters when method A calls
method B and you want B to commit even if A fails.

**Level 3 (Mid):** The proxy mechanism means only external
calls go through the proxy. Self-invocation (calling another
method of the same class) bypasses it entirely. This is why
`this.internalMethod()` ignores @Transactional on
internalMethod. Solutions: inject self-reference, use
`AopContext.currentProxy()`, or extract to a separate bean.

Additionally, `@Transactional` on private methods is silently
ignored (CGLIB proxies can't override private methods). And
checked exceptions (IOException, etc.) do NOT trigger rollback
unless you specify `rollbackFor = Exception.class`.

**Level 4 (Senior/Staff):** Transaction synchronization allows
registering callbacks for before-commit, after-commit, and
after-completion. This is how you implement "send email only
after order is committed" - using
`TransactionSynchronizationManager.registerSynchronization()`.
Spring Events with `@TransactionalEventListener(phase =
AFTER_COMMIT)` provide a declarative alternative.

Debugging propagation issues: enable
`logging.level.org.springframework.transaction=TRACE`. This
logs every transaction begin, join, suspend, commit, and
rollback with the method name and propagation type.

**Level 5 (Distinguished):** The proxy-based transaction model
is fundamentally limited by the Java type system - you can't
intercept calls that don't go through an interface/proxy
boundary. AspectJ compile-time or load-time weaving solves
this by modifying bytecode to include transaction management
in ALL calls, including self-invocation. But this adds build
complexity and makes debugging harder. The real solution is
architectural: if you need transactional boundaries,
make them explicit through separate beans, not annotations
on private methods.

---

### How It Works - Mechanism

**Propagation type behavior:**

```
REQUIRED (default):
  Tx exists? -> join it
  No tx?     -> create new

REQUIRES_NEW:
  Tx exists? -> suspend it, create new
  No tx?     -> create new

NESTED:
  Tx exists? -> create savepoint
  No tx?     -> create new (like REQUIRED)

MANDATORY:
  Tx exists? -> join it
  No tx?     -> throw exception

NOT_SUPPORTED:
  Tx exists? -> suspend it, run without
  No tx?     -> run without

SUPPORTS:
  Tx exists? -> join it
  No tx?     -> run without

NEVER:
  Tx exists? -> throw exception
  No tx?     -> run without
```

**Rollback decision tree:**

```
Exception thrown
  │
  ├── RuntimeException? ──> ROLLBACK
  │
  ├── Error? ──> ROLLBACK
  │
  └── Checked Exception?
       │
       ├── rollbackFor includes it? ──> ROLLBACK
       │
       └── Not specified? ──> COMMIT  <- HERE!
           (This surprises everyone)
```

---

### Code Example

```java
// BAD: Self-invocation bypasses proxy
@Service
public class OrderService {
    @Transactional
    public void createOrder(Order order) {
        orderRepo.save(order);
        // THIS CALL BYPASSES THE PROXY!
        // @Transactional on sendConfirmation
        // is completely ignored
        this.sendConfirmation(order);
    }

    @Transactional(
        propagation = Propagation.REQUIRES_NEW
    )
    public void sendConfirmation(Order order) {
        // Intended: separate transaction
        // Actual: runs in createOrder's tx
        emailRepo.save(new Email(order));
    }
}

// GOOD: Separate beans for separate tx
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepo;
    private final ConfirmationService confirmSvc;

    @Transactional
    public void createOrder(Order order) {
        orderRepo.save(order);
        // External call -> goes through proxy
        confirmSvc.sendConfirmation(order);
    }
}

@Service
public class ConfirmationService {
    @Transactional(
        propagation = Propagation.REQUIRES_NEW
    )
    public void sendConfirmation(Order order) {
        // Runs in its own transaction
        emailRepo.save(new Email(order));
    }
}
```

```java
// BAD: Checked exception doesn't roll back
@Transactional
public void transferMoney(
    Account from, Account to, BigDecimal amt
) throws InsufficientFundsException {
    from.debit(amt);
    accountRepo.save(from);
    if (from.getBalance().compareTo(ZERO) < 0) {
        // Checked exception -> COMMITS!
        // Debit is saved, credit never happens
        throw new InsufficientFundsException();
    }
    to.credit(amt);
    accountRepo.save(to);
}

// GOOD: Explicit rollback for checked exceptions
@Transactional(rollbackFor = Exception.class)
public void transferMoney(
    Account from, Account to, BigDecimal amt
) throws InsufficientFundsException {
    from.debit(amt);
    accountRepo.save(from);
    if (from.getBalance().compareTo(ZERO) < 0) {
        throw new InsufficientFundsException();
    }
    to.credit(amt);
    accountRepo.save(to);
}
```

---

### Quick Reference Card

| Field               | Value                             |
| ------------------- | --------------------------------- |
| Category            | Transaction Management            |
| Default propagation | REQUIRED                          |
| Default rollback    | RuntimeException + Error only     |
| Proxy type          | CGLIB (class) or JDK (interface)  |
| Trace logging       | `o.s.transaction=TRACE`           |
| Self-invocation     | Bypasses proxy - NO transaction   |
| Private methods     | @Transactional silently ignored   |
| Savepoint           | NESTED propagation (JDBC only)    |
| Thread binding      | TransactionSynchronizationManager |

**3 things to remember:**

1. Self-invocation bypasses the proxy - always use separate beans
2. Checked exceptions don't trigger rollback by default
3. `TRACE` logging on `o.s.transaction` shows every tx decision

**One-liner:** "If @Transactional isn't working, it's almost
always self-invocation, checked exceptions, or private methods."

---

### Mastery Checklist

- [ ] EXPLAIN: All 7 propagation types with real use cases
- [ ] DEBUG: Enable TRACE logging and read transaction
      begin/join/commit/rollback decisions
- [ ] REPRODUCE: Create a test showing self-invocation
      bypassing the proxy
- [ ] ARCHITECT: Design a service where REQUIRES_NEW is
      truly necessary (audit logging)
- [ ] DIAGNOSE: Data corruption from mixed propagation types
      in production

---

### Surprising Truth

Spring's default rollback behavior (commit on checked
exceptions) comes from EJB convention, not from any technical
reason. In EJB, checked exceptions represented "business
exceptions" (expected, user-facing) while unchecked exceptions
represented "system exceptions" (unexpected, infrastructure).
Most Spring developers don't know this history and are
surprised when a `throws IOException` in a @Transactional
method commits partially-written data.

---

### Common Misconceptions

| #   | Misconception                                     | Reality                                                                                     | Why It Matters                                                 |
| --- | ------------------------------------------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| 1   | @Transactional on any method enables transactions | Only works on public methods called from outside the class (through proxy)                  | Private/protected/self-invoked methods are ignored             |
| 2   | REQUIRES_NEW always works                         | Self-invocation means REQUIRES_NEW is ignored; must call from external bean                 | The propagation type is irrelevant if the proxy isn't involved |
| 3   | All exceptions trigger rollback                   | Only RuntimeException and Error; checked exceptions COMMIT by default                       | Use `rollbackFor = Exception.class` for safety                 |
| 4   | @Transactional is "free"                          | Each transaction holds a DB connection for its duration; long transactions exhaust the pool | Design transaction boundaries to be as short as possible       |

---

### Failure Modes and Diagnosis

| Failure Mode               | Symptom                                           | Diagnostic Command                                                      | Fix                                                          |
| -------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------ |
| Self-invocation            | @Transactional ignored on internal call           | `logging.level.org.springframework.transaction=TRACE` shows no tx begin | Extract to separate bean                                     |
| Checked exception commits  | Partial data committed after checked exception    | TRACE log shows "Committing" after exception                            | Add `rollbackFor = Exception.class`                          |
| Connection pool exhaustion | "Connection is not available, timeout" under load | `SELECT * FROM pg_stat_activity` shows idle-in-transaction              | Reduce @Transactional scope; don't hold tx during HTTP calls |
| Lost REQUIRES_NEW          | Nested method runs in parent tx instead of new    | TRACE log shows "Participating in existing transaction"                 | Verify call goes through proxy, not self-invocation          |

---

### Interview Deep-Dive

**Timing Table:**

| Question | Type         | Difficulty | Time |
| -------- | ------------ | ---------- | ---- |
| Q1       | CONCEPTUAL   | MID        | 90s  |
| Q2       | DEBUGGING    | SENIOR     | 120s |
| Q3       | PRODUCTION   | SENIOR     | 120s |
| Q4       | TRADE-OFF    | STAFF      | 150s |
| Q5       | DEBUGGING    | SENIOR     | 120s |
| Q6       | HANDS-ON     | MID        | 90s  |
| Q7       | ARCHITECTURE | STAFF      | 150s |
| Q8       | TRADE-OFF    | SENIOR     | 120s |
| Q9       | DEBUGGING    | SENIOR     | 120s |
| Q10      | PRODUCTION   | SENIOR     | 120s |
| Q11      | BEHAVIORAL   | SENIOR     | 120s |
| Q12      | CONCEPTUAL   | MID        | 90s  |

**Q1: Explain the difference between REQUIRED, REQUIRES_NEW, and NESTED propagation with real examples.** [MID]

REQUIRED (default): "Join the party or throw your own." If a transaction exists, join it. If not, create one. Use case: `orderService.createOrder()` calls `inventoryService.reserve()` - both should succeed or fail together. The inventory reservation joins the order's transaction. If either fails, both roll back.

REQUIRES_NEW: "I need my own room." Always creates a new transaction, suspending the current one. Use case: `paymentService.processPayment()` calls `auditService.logAttempt()`. Even if payment fails and rolls back, the audit log must persist (for compliance). Audit runs in its own transaction that commits independently. The suspended outer transaction doesn't see the audit's commit/rollback.

NESTED: "I'll take a savepoint." Creates a savepoint within the current transaction. If the nested operation fails, only the savepoint is rolled back - the outer transaction can catch the exception and continue. Use case: `batchProcessor.processItems()` iterates over 100 items. Each item processes with NESTED propagation. If item #47 fails, its savepoint rolls back, but items 1-46 are still committed when the outer transaction completes. Note: NESTED requires JDBC savepoint support and doesn't work with JTA.

_What separates good from great:_ Provide the real-world motivation for each type, not just the mechanics. "REQUIRED is for things that belong together. REQUIRES_NEW is for things that must survive independently. NESTED is for partial failure in batch processing."

**Q2: A production service has intermittent data corruption where orders are saved but inventory isn't decremented. How do you diagnose?** [SENIOR]

This symptom indicates a transaction boundary issue - the order save and inventory decrement are not in the same transaction. Diagnostic steps: (1) Enable `logging.level.org.springframework.transaction=TRACE` in a staging environment that reproduces the issue. Look for: "Creating new transaction" where you expected "Participating in existing transaction." This reveals if the methods are in separate transactions when they should share one. (2) Check for self-invocation: if `orderService.createOrder()` calls `this.decrementInventory()` and both are @Transactional, the decrement call bypasses the proxy. The order has a transaction (from external call), but decrement has no SEPARATE transaction - it runs in the order's transaction BUT only if it was the SAME object. Wait - in self-invocation, the method still runs within the caller's transaction (because there's no proxy to create a new one), so the real question is: is decrementInventory in a DIFFERENT class that's called without the proxy?

(3) Check propagation types: if inventory uses `REQUIRES_NEW`, it's in its own transaction. If the inventory service throws a checked exception that the order service catches, the inventory transaction rolls back but order commits. (4) Check async: if inventory is `@Async`, it runs in a DIFFERENT thread with NO transaction context (thread-local doesn't propagate). (5) Database-level diagnosis: `SELECT * FROM pg_stat_activity WHERE state = 'idle in transaction'` shows connections holding transactions. Compare timestamps of order INSERT and inventory UPDATE to see if they're in the same transaction ID (`txid_current()`).

_What separates good from great:_ Methodically eliminate causes in order of likelihood: self-invocation → async boundary → wrong propagation → checked exception swallowing. Show that you have a diagnostic playbook, not ad-hoc guessing.

**Q3: How do you prevent long-running transactions from exhausting your connection pool?** [SENIOR]

Long-running transactions are the #1 cause of connection pool exhaustion in Spring applications. Each @Transactional method holds a database connection for its entire duration. If a service method calls an external API (2s latency) inside a transaction, that connection is held idle for 2s while waiting for HTTP response.

Prevention strategy: (1) Keep transactions as short as possible - separate read operations (outside tx) from write operations (inside tx). Use `@Transactional(readOnly = true)` for reads to enable connection routing to read replicas. (2) Never call external services inside a transaction. Pattern: read data → call external service → open transaction → write result → close transaction. (3) Set connection pool timeouts aggressively: `spring.datasource.hikari.connection-timeout=5000` (fail fast rather than queue). `spring.datasource.hikari.maximum-pool-size=20` (bounded). `spring.datasource.hikari.leak-detection-threshold=30000` (log if a connection is held >30s). (4) Monitor: expose HikariCP metrics to Prometheus: `hikaricp_connections_active`, `hikaricp_connections_pending`. Alert when pending > 0 sustained for >30s.

For existing code with long transactions: use `TransactionTemplate` for programmatic control rather than declarative @Transactional. This lets you open the transaction at exactly the right point: `transactionTemplate.execute(status -> { /* only DB writes here */ })`.

_What separates good from great:_ Know the connection-to-transaction lifecycle: "A @Transactional method acquires a connection at the first database operation (lazy), not at method entry. But it holds it until the method exits. Moving non-DB work outside the @Transactional boundary is the single most effective optimization."

**Q4: Compare proxy-based (Spring default) vs AspectJ weaving for transaction management. When is each appropriate?** [STAFF]

Spring proxy-based transactions (default): Method calls go through a JDK dynamic proxy (interface) or CGLIB proxy (class). Pros: no build tool changes, no special JVM agents, easy to understand (proxy is just a wrapper). Cons: self-invocation bypasses the proxy (the fundamental limitation), only works on public methods, requires Spring-managed beans (won't work on `new MyService()`).

AspectJ weaving (compile-time or load-time): Bytecode modification adds transaction management directly into the class. Compile-time weaving modifies .class files during build. Load-time weaving modifies classes as the JVM loads them (via `-javaagent:aspectjweaver.jar`). Pros: self-invocation works, private methods work, works on any object (not just Spring beans). Cons: build complexity (AspectJ compiler plugin), harder debugging (bytecode doesn't match source), IDE support varies, class loading overhead (LTW).

When to choose: Proxy-based for 95% of applications. The self-invocation limitation is easily solved by extracting methods to separate beans - this is actually better design (single responsibility). AspectJ only when: (1) You have a codebase with deep call chains where extracting every transactional method to a separate bean would create hundreds of tiny classes. (2) You need @Transactional on non-Spring objects (rare). (3) You're integrating with a framework that creates objects outside Spring's control.

_What separates good from great:_ Frame the proxy limitation as a design signal, not a technical problem. "When self-invocation matters, it usually means the class has too many responsibilities. The proxy limitation pushes you toward better design."

**Q5: You see "Participating in existing transaction" in TRACE logs when you expected a new transaction. Diagnose.** [SENIOR]

"Participating in existing transaction" means the method's propagation type is REQUIRED (default) and there's already a transaction on the current thread. Diagnosis: (1) Verify the method's @Transactional annotation has `propagation = REQUIRES_NEW`, not REQUIRED. Common mistake: forgetting to change propagation from the default. (2) Check if the @Transactional annotation is actually being processed. If it's on a method in the same class as the caller, self-invocation means the proxy's annotation processing is skipped entirely. In this case, the method runs in whatever transaction context the caller established - the log correctly says "participating." (3) Check interface vs class proxy: if you're using JDK proxies (interface-based) and the @Transactional is on the implementation class (not the interface), some configurations may not pick it up. (4) Check for `@Transactional` at class level overriding method level. Class-level @Transactional applies to ALL public methods; a method-level annotation should override, but verify with TRACE logs.

The fix depends on the cause: wrong propagation → change to REQUIRES_NEW. Self-invocation → extract to separate bean. Class-level override → add explicit method-level annotation.

_What separates good from great:_ Read the FULL TRACE log entry. It includes the transaction manager name, the method being advised, and the existing transaction's name. This tells you exactly where the outer transaction started and which bean is being advised.

**Q6: Write a test that proves self-invocation bypasses @Transactional.** [MID]

```java
@SpringBootTest
@Transactional  // Test-level tx for rollback
class SelfInvocationTest {

    @Autowired OrderService orderService;
    @Autowired JdbcTemplate jdbc;

    @Test
    void selfInvocationBypassesProxy() {
        // createOrder calls this.logAudit()
        // logAudit has REQUIRES_NEW but since
        // it's self-invoked, it shares the tx
        orderService.createOrder(new Order("A"));

        // Force exception in outer method
        assertThatThrownBy(() ->
            orderService
                .createOrderThenFail(new Order("B"))
        ).isInstanceOf(RuntimeException.class);

        // If proxy worked, audit log would
        // survive in separate tx.
        // But self-invocation means audit is
        // in the same tx and rolled back.
        Long auditCount = jdbc.queryForObject(
            "SELECT count(*) FROM audit_log " +
            "WHERE order_ref = 'B'",
            Long.class
        );
        // Audit was rolled back with the order!
        assertThat(auditCount).isZero();
    }
}
```

This test proves that the REQUIRES_NEW propagation on `logAudit()` is ignored because it's called via `this.logAudit()`. The audit entry rolls back with the outer transaction, which shouldn't happen if REQUIRES_NEW worked correctly.

_What separates good from great:_ Know that fixing this test (making audit survive) requires extracting `logAudit()` to a separate bean. The test itself becomes a regression test for the fix.

**Q7: Design a transactional architecture for an order processing system where: order creation must be atomic, payment notification must survive order failure, and audit logging must be permanent regardless of outcome.** [STAFF]

Three transactional boundaries with different propagation needs:

Architecture:

```
OrderFacade.processOrder()
  │
  ├── OrderService.createOrder()
  │     @Transactional (REQUIRED)
  │     - Validate order
  │     - Save order
  │     - Reserve inventory
  │     → All atomic: order + inventory
  │
  ├── AuditService.logOrderEvent()
  │     @Transactional (REQUIRES_NEW)
  │     - Log event regardless of outcome
  │     → Commits independently
  │
  └── @TransactionalEventListener(AFTER_COMMIT)
        PaymentNotificationService.notify()
        - Send payment request
        → Only fires if order committed
```

Key design decisions: (1) OrderFacade is NOT @Transactional - it orchestrates but doesn't own a transaction. This prevents accidentally putting audit and notification inside the order's transaction. (2) AuditService uses REQUIRES_NEW because audit must persist even if the order fails. It's a separate bean to avoid self-invocation issues. (3) Payment notification uses `@TransactionalEventListener(phase = AFTER_COMMIT)` - it only fires after the order transaction successfully commits. If the order rolls back, the event is discarded. This prevents sending payment requests for orders that don't exist.

Error handling: if the audit write fails (unlikely - separate DB concern), it shouldn't affect the order. Catch and log the exception in the facade. If payment notification fails, the order is already committed - use a retry mechanism (Spring Retry or outbox pattern) to ensure eventual delivery.

_What separates good from great:_ Explain WHY the facade is non-transactional. "If I put @Transactional on the facade, everything runs in one transaction. The audit REQUIRES_NEW creates a new one (correct), but the payment notification fires before the outer tx commits (wrong). By keeping the facade non-transactional, I control exactly where each boundary starts."

**Q8: What are the trade-offs of @Transactional at the service layer vs the repository layer?** [SENIOR]

Service-layer transactions (recommended default): @Transactional on service methods that orchestrate multiple repository calls. Pros: transaction boundary matches business operation (order creation = save order + reserve inventory atomically), clear ownership (service owns the transaction), consistent pattern across the team. Cons: longer transactions if the service method does non-DB work (HTTP calls, computations) between repository calls.

Repository-layer transactions: @Transactional on individual repository methods. Pros: shortest possible transactions, each DB operation is independently transactional. Cons: multiple repository calls in a service method are NOT atomic - if the second call fails, the first is already committed. This leads to data inconsistency. Spring Data JPA's default `save()` already has implicit transaction boundaries, so adding @Transactional is redundant.

My recommendation: service-layer @Transactional as the default, with these exceptions: (1) Read-only queries that don't need atomicity: @Transactional(readOnly = true) on the repository or service method for connection routing. (2) Fire-and-forget writes (audit, metrics): REQUIRES_NEW on a dedicated service to isolate from the caller's transaction. (3) Saga-pattern operations (distributed across services): no @Transactional at all; use compensating transactions.

The anti-pattern: @Transactional on BOTH service and repository layers. This creates unnecessary nested transactions where the repository always "participates" in the service's transaction anyway (REQUIRED default). It's redundant and confusing.

_What separates good from great:_ Know that @Transactional(readOnly = true) doesn't just prevent writes - it hints the JDBC driver and database to optimize (no write-ahead log, prefer replica, etc.). It's a performance optimization, not just a safety check.

**Q9: An application throws "Transaction rolled back because it has been marked as rollback-only." What happened?** [SENIOR]

This exception means: (1) An outer method started a transaction. (2) An inner method (REQUIRED propagation) joined that transaction. (3) The inner method threw a RuntimeException. (4) The transaction was marked "rollback-only" by the inner method's proxy. (5) The outer method CAUGHT the exception and tried to continue. (6) When the outer method exits, Spring tries to commit but the transaction is marked rollback-only. Boom: `UnexpectedRollbackException`.

This is the most confusing transaction error because the outer method thinks it handled the error, but the transaction proxy already decided to roll back. The outer method's catch block runs, but the commit at the end fails.

Diagnosis: TRACE logging shows: inner method marks "rollback-only" → outer method catches exception → outer method attempts commit → `UnexpectedRollbackException`. Fix options: (1) If the inner operation should be independent, use REQUIRES_NEW so its rollback doesn't affect the outer transaction. (2) If the inner operation should roll back the whole thing, don't catch the exception in the outer method - let it propagate. (3) If you need to catch the exception AND continue the outer transaction, the inner method shouldn't be @Transactional (remove the annotation, let it run in the outer's transaction without its own proxy marking rollback).

The root cause is almost always: someone added a try-catch around a @Transactional call without understanding that the catch doesn't undo the rollback-only flag.

_What separates good from great:_ Explain the mechanism precisely: "The proxy for the inner bean catches the RuntimeException, calls `TransactionStatus.setRollbackOnly()`, then re-throws. The outer method catches the re-thrown exception, but the rollback-only flag is permanent - no amount of catching can clear it."

**Q10: How do you monitor transaction health in a production Spring application?** [SENIOR]

Transaction monitoring strategy: (1) Connection pool metrics (Micrometer + HikariCP): `hikaricp_connections_active` (how many connections are in-use), `hikaricp_connections_pending` (threads waiting for a connection - this should be zero; any sustained value means pool exhaustion). `hikaricp_connections_usage_seconds` (how long connections are held - long durations indicate large transaction scopes).

(2) Transaction timing: create a custom `TransactionInterceptor` or use Micrometer's `@Timed` annotation on @Transactional methods. Track p50/p95/p99 transaction durations. Alert on p99 > 5s (indicates a method is holding a connection too long).

(3) Database-side monitoring: `SELECT pid, state, query, xact_start, now() - xact_start AS duration FROM pg_stat_activity WHERE state = 'idle in transaction' AND now() - xact_start > interval '10 seconds'`. This shows connections that Spring acquired (transaction started) but is doing non-DB work (HTTP call, computation). These are your "long transaction" culprits.

(4) Rollback monitoring: log every rollback with context (method name, exception type, duration). A spike in rollbacks may indicate an upstream dependency failure (timeouts causing exceptions) or a deployment bug.

Alerts: `hikaricp_connections_pending > 0 for 30s` (critical - pool exhaustion imminent). `transaction_duration_p99 > 5s` (warning - long transactions). `transaction_rollback_rate > 5%` (investigate - something is failing).

_What separates good from great:_ Tie connection pool monitoring to transaction design. "Every spike in `connections_pending` traces back to a @Transactional method that's too wide. The fix is never 'increase pool size' - it's 'shrink the transaction scope.'"

**Q11: Tell me about a time you diagnosed a transaction-related data corruption bug.** [SENIOR]

In production, we found that some orders had a "CONFIRMED" status but no associated payment record. This should be impossible - the order confirmation and payment creation were in the same @Transactional service method.

Investigation: (1) I checked the code: `orderService.confirmOrder()` was @Transactional. It called `this.createPayment()` - self-invocation! The `createPayment()` method had `@Transactional(propagation = REQUIRES_NEW)` because we wanted payment creation to survive even if later steps failed. But self-invocation meant the REQUIRES_NEW was ignored - payment ran in the order's transaction. (2) But wait - if they're in the same transaction, how is only one committed? Further investigation revealed that `createPayment()` threw a checked `PaymentGatewayException` on intermittent gateway failures. Since it's a checked exception, the transaction was NOT marked rollback-only. The outer method caught the exception, logged it, and continued. The order committed as CONFIRMED, but the payment INSERT was rolled back because... wait, it can't be rolled back in the same transaction if the order commits.

(3) Final root cause: the payment was being sent via an @Async event listener that ran in a SEPARATE thread (no transaction context). The async listener created its own transaction, which rolled back on the gateway error. The order's transaction committed independently. The async boundary was the real culprit, not self-invocation.

Fix: Replaced @Async payment creation with a transactional outbox pattern - payment intent is written to the same transaction as the order, and a separate poller processes the outbox.

_What separates good from great:_ Show that the initial hypothesis (self-invocation) was wrong and you kept digging. "The first explanation that fits isn't always correct. I validated each hypothesis with TRACE logs before concluding."

**Q12: What is the difference between declarative (@Transactional) and programmatic (TransactionTemplate) transaction management?** [MID]

Declarative (@Transactional): annotation-based, Spring manages begin/commit/rollback automatically via AOP proxy. Pros: clean code, consistent behavior, less boilerplate. Cons: proxy limitations (self-invocation, public methods only), less control over transaction boundaries, harder to conditionally apply transactions.

Programmatic (TransactionTemplate): explicit code controls transaction boundaries. `transactionTemplate.execute(status -> { /* tx code */ })`. Pros: no proxy required (works for self-invocation), precise control over what's inside the transaction, can conditionally execute transactions, works in any method (private, static). Cons: more verbose, transaction logic mixed with business logic, easier to forget to use.

When to choose: @Transactional for 90% of cases (simple, clean, consistent). TransactionTemplate for: (1) Methods where you need a narrow transaction window inside a larger method (e.g., compute for 2 seconds, then write in a transaction for 50ms). (2) Lambda-based operations where extracting to a separate bean is awkward. (3) Code paths where transaction participation depends on runtime conditions.

You can mix both: use @Transactional on the service method for the overall boundary, and TransactionTemplate inside for specific operations that need different propagation. The TransactionTemplate will use the current TransactionManager and respect propagation settings.

_What separates good from great:_ Know that TransactionTemplate is NOT just a workaround for proxy limitations. It's a design choice for explicit transaction boundaries. "I use @Transactional when the entire method is the transaction. I use TransactionTemplate when only part of the method needs a transaction."

---

### Related Keywords

**Prerequisites:** Transaction Management (Spring Data Access),
Bean Lifecycle, AOP Concepts

**Builds on:** @Transactional basics, ACID properties

**Leads to:** Connection Pooling diagnostics, Spring Boot
Production Anti-Patterns

**Alternatives:** JTA (distributed transactions), Saga pattern
(eventual consistency), programmatic TransactionTemplate

---

---

# Spring Security Filter Chain Debugging

**TL;DR** - Spring Security processes every request through an
ordered chain of servlet filters. Debug by enabling TRACE
logging on `org.springframework.security`, which prints every
filter's decision for every request - match, allow, deny, and
the exact reason.

---

### The Problem This Solves

A developer configures Spring Security, hits an endpoint, and
gets a 403 Forbidden. No useful error message. No indication
of WHICH security check failed. Was it authentication?
Authorization? CORS? CSRF? A missing role? An expired token?
The response body just says "Forbidden" and the developer
starts randomly commenting out security rules until it works.

Security debugging is uniquely difficult because security
frameworks intentionally hide details from the response (to
prevent information leakage to attackers). The information
exists - but only in server-side logs at DEBUG/TRACE level.

---

### Textbook Definition

The Spring Security filter chain is an ordered sequence of
servlet filters registered as a `SecurityFilterChain` bean.
Each filter handles a specific security concern (CORS, CSRF,
authentication, authorization, session management, etc.) and
processes the HTTP request in order. The chain's behavior is
determined by the order of filters, their individual
configuration, and the `SecurityContext` they populate.

---

### Understand It in 30 Seconds

**One line:** Every HTTP request passes through 15+ security
filters in order; TRACE logging shows you which one said "no."

**Analogy:** The filter chain is like airport security. You go
through document check (authentication), baggage scan (CSRF),
boarding pass validation (authorization), and body scan
(request validation) in a fixed order. If any checkpoint
rejects you, you're stopped. Debugging means finding WHICH
checkpoint rejected you and why.

**Key insight:** 403 Forbidden usually means authentication
SUCCEEDED but authorization FAILED. 401 Unauthorized means
authentication itself failed. This distinction eliminates
half the filters from investigation immediately.

---

### First Principles

Spring Security's architecture:

1. **DelegatingFilterProxy** - bridges Servlet container to
   Spring's ApplicationContext (registered in web.xml or auto)
2. **FilterChainProxy** - holds one or more SecurityFilterChain
   instances, delegates to the matching chain
3. **SecurityFilterChain** - ordered list of filters; each
   request matches exactly one chain
4. **SecurityContext** - thread-local container holding the
   authenticated principal (set by auth filters, read by
   authorization filters)
5. **Filter ordering is fixed** - Spring Security has a
   predefined order for all built-in filters; custom filters
   must be inserted at specific positions

---

### Mental Model / Analogy

```
HTTP Request
  │
  v
┌─────────────────────────────────┐
│  DelegatingFilterProxy          │
│  └─ FilterChainProxy            │
│     └─ SecurityFilterChain      │
│        │                        │
│  [DisableEncodeUrlFilter]       │
│  [SecurityContextHolderFilter]  │
│  [CsrfFilter]            <- HERE│
│  [LogoutFilter]                 │
│  [UsernamePasswordAuthFilter]   │
│  [BearerTokenAuthFilter]        │
│  [RequestCacheFilter]           │
│  [AnonymousAuthFilter]          │
│  [SessionManagementFilter]      │
│  [ExceptionTranslationFilter]   │
│  [AuthorizationFilter]    <- HERE│
│                                 │
└─────────────────────────────────┘
  │
  v
Controller (if all filters pass)
```

---

### How It Works - Five Levels

**Level 1 (Anyone):** Every web request goes through a security
checkpoint. If the checkpoint says no, you get an error.
Debugging means finding which checkpoint said no.

**Level 2 (Junior):** Spring Security has ~15 filters that run
in order. The first group handles authentication (who are you?),
the last group handles authorization (are you allowed?).
Enable `logging.level.org.springframework.security=DEBUG` to
see what each filter does for each request.

**Level 3 (Mid):** Each filter has a specific responsibility:
`CsrfFilter` validates CSRF tokens (rejects POST without
token), `BearerTokenAuthenticationFilter` extracts and
validates JWTs, `AuthorizationFilter` checks URL patterns
against granted authorities. TRACE level logging shows
per-filter decisions: "Did not match request" (filter skipped),
"Authenticated" (auth succeeded), "Access denied" (authz
failed). The key diagnostic technique: search TRACE logs for
"Denied" or "Failed" to find the exact filter and reason.

**Level 4 (Senior/Staff):** Multiple `SecurityFilterChain`
beans can exist, each matching different URL patterns.
`FilterChainProxy` selects the FIRST matching chain. This
means ordering matters: a chain matching `/**` registered
before `/api/**` will catch all requests, and the API chain
never executes. Debug with: Actuator `/configprops` shows
security config, and `/beans` shows registered filter chains.

For JWT debugging specifically: `BearerTokenAuthenticationFilter`
extracts the token, `JwtDecoder` validates signature and claims,
and failures log at DEBUG with the exact claim that failed
(expired, wrong issuer, missing scope). Add
`logging.level.org.springframework.security.oauth2=TRACE` for
OAuth2-specific debugging.

**Level 5 (Distinguished):** The filter chain architecture is
the Chain of Responsibility pattern from GoF. Each filter
decides: handle (stop the chain) or pass (call the next
filter). The `ExceptionTranslationFilter` is particularly
important - it sits BEFORE `AuthorizationFilter` and catches
`AccessDeniedException` and `AuthenticationException` to
produce appropriate HTTP responses (403 vs 401). Understanding
this exception flow is critical: the AuthorizationFilter
throws → ExceptionTranslationFilter catches → checks if user
is authenticated → if yes: 403, if no: commence authentication
(redirect to login or 401).

---

### How It Works - Mechanism

**Debugging decision tree:**

```
Got 401 Unauthorized?
  │
  └── Authentication failed
      ├── No token/credentials sent?
      │   -> Check client request headers
      ├── Token expired?
      │   -> TRACE: "Jwt expired at..."
      ├── Token signature invalid?
      │   -> Check JWK source / secret key
      └── Wrong auth mechanism?
          -> Check filter chain has the
             right auth filter registered

Got 403 Forbidden?
  │
  └── Authorization failed
      ├── Missing role/authority?
      │   -> TRACE: "authorities=[X]"
      │   -> Required: "ROLE_Y"
      ├── CSRF token missing?
      │   -> POST/PUT without _csrf
      │   -> Check: CsrfFilter in TRACE
      ├── CORS pre-flight rejected?
      │   -> Check: CorsFilter config
      └── Method security denied?
          -> @PreAuthorize failed
          -> Check SpEL expression
```

**Enabling full diagnostic logging:**

```yaml
logging:
  level:
    org.springframework.security: TRACE
    org.springframework.security.web: TRACE
    org.springframework.security.oauth2: TRACE
```

---

### Code Example

```java
// BAD: Guessing at security config, no debugging
@Bean
SecurityFilterChain security(HttpSecurity http)
    throws Exception {
    return http
        .csrf(c -> c.disable()) // "fixing" 403
        .authorizeHttpRequests(a -> a
            .anyRequest().permitAll() // give up
        )
        .build();
}

// GOOD: Precise configuration with logging
@Bean
SecurityFilterChain apiChain(HttpSecurity http)
    throws Exception {
    return http
        .securityMatcher("/api/**")
        .csrf(c -> c
            .ignoringRequestMatchers("/api/**"))
        .cors(c -> c
            .configurationSource(corsConfig()))
        .authorizeHttpRequests(a -> a
            .requestMatchers("/api/public/**")
                .permitAll()
            .requestMatchers("/api/admin/**")
                .hasRole("ADMIN")
            .anyRequest().authenticated()
        )
        .oauth2ResourceServer(o -> o
            .jwt(j -> j
                .decoder(jwtDecoder())
                .jwtAuthenticationConverter(
                    jwtConverter())
            )
        )
        .exceptionHandling(e -> e
            .authenticationEntryPoint(
                (req, res, ex) -> {
                    log.warn("Auth failed: {}",
                        ex.getMessage());
                    res.sendError(401);
                })
        )
        .build();
}
```

---

### Quick Reference Card

| Field          | Value                                             |
| -------------- | ------------------------------------------------- |
| Category       | Security Diagnostics                              |
| Debug logging  | `o.s.security=TRACE`                              |
| OAuth2 logging | `o.s.security.oauth2=TRACE`                       |
| Filter list    | Actuator `/beans` (FilterChainProxy)              |
| 401 means      | Authentication failed                             |
| 403 means      | Authorization failed (or CSRF/CORS)               |
| Filter order   | Fixed by Spring; custom via addFilterBefore/After |
| CSRF default   | Enabled for state-changing methods                |
| CORS default   | Denied unless explicitly configured               |

**3 things to remember:**

1. 401 = who are you? 403 = you can't do that
2. TRACE logging shows every filter's decision per request
3. CSRF and CORS are the hidden 403 causes everyone forgets

**One-liner:** "Enable TRACE logging on
org.springframework.security and the answer is always in the
logs within 5 seconds."

---

### Mastery Checklist

- [ ] DIAGNOSE: Determine if a 403 is CSRF, CORS, or
      authorization using only TRACE logs
- [ ] CONFIGURE: Build a multi-chain setup (public + API +
      admin) with different auth mechanisms
- [ ] DEBUG: Trace JWT validation failure from token to
      claim-level rejection reason
- [ ] EXPLAIN: The exact filter order and what each does
- [ ] EXTEND: Add a custom filter at the correct position
      in the chain

---

### Surprising Truth

Spring Security's default filter chain has 15+ filters, but
for a stateless JWT API, only about 5 are actually needed.
The rest (session management, form login, remember-me, etc.)
are no-ops that still execute and add microseconds per request.
At 10,000 requests/second, these no-op filters add measurable
overhead. You can build a minimal chain with only the filters
you need using `HttpSecurity.addFilterBefore/After` on a
blank chain, but almost nobody does because the defaults are
"good enough."

---

### Common Misconceptions

| #   | Misconception                            | Reality                                                                        | Why It Matters                                         |
| --- | ---------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------ |
| 1   | 403 always means wrong role              | CSRF failure and CORS rejection also return 403                                | Check CSRF and CORS before investigating roles         |
| 2   | Disabling CSRF fixes the problem         | It masks the problem; CSRF protection exists for a reason                      | For APIs, disable CSRF but configure CORS properly     |
| 3   | Filter chain order doesn't matter        | Order is critical; authentication must run before authorization                | Custom filters in wrong position cause silent failures |
| 4   | Spring Security only affects controllers | Security filters run before ANY servlet processing, including static resources | A misconfigured chain blocks CSS/JS files too          |

---

### Failure Modes and Diagnosis

| Failure Mode        | Symptom                             | Diagnostic Command                  | Fix                                                        |
| ------------------- | ----------------------------------- | ----------------------------------- | ---------------------------------------------------------- |
| CSRF rejection      | 403 on POST/PUT/DELETE from SPA     | TRACE: "Invalid CSRF token"         | Disable CSRF for API endpoints; use CORS instead           |
| CORS pre-flight     | 403 on OPTIONS request              | Browser dev tools: blocked by CORS  | Configure CorsConfigurationSource with allowed origins     |
| JWT expired         | 401 on valid-looking request        | TRACE: "Jwt expired at [timestamp]" | Check client token refresh logic; verify server clock sync |
| Wrong chain matched | Unexpected behavior on specific URL | TRACE: "Trying to match... matched" | Reorder SecurityFilterChain beans; check @Order            |

---

### Interview Deep-Dive

**Timing Table:**

| Question | Type         | Difficulty | Time |
| -------- | ------------ | ---------- | ---- |
| Q1       | DEBUGGING    | MID        | 90s  |
| Q2       | CONCEPTUAL   | MID        | 90s  |
| Q3       | DEBUGGING    | SENIOR     | 120s |
| Q4       | PRODUCTION   | SENIOR     | 120s |
| Q5       | TRADE-OFF    | STAFF      | 150s |
| Q6       | HANDS-ON     | MID        | 90s  |
| Q7       | ARCHITECTURE | STAFF      | 150s |
| Q8       | DEBUGGING    | SENIOR     | 120s |
| Q9       | PRODUCTION   | SENIOR     | 120s |
| Q10      | TRADE-OFF    | SENIOR     | 120s |
| Q11      | BEHAVIORAL   | SENIOR     | 120s |
| Q12      | CONCEPTUAL   | MID        | 90s  |

**Q1: A React SPA makes a POST request to your Spring Boot API and gets 403. GET requests work fine. What's happening?** [MID]

This is almost certainly CSRF. Spring Security enables CSRF protection by default for state-changing HTTP methods (POST, PUT, DELETE, PATCH). GET requests are exempt. The React SPA isn't sending a CSRF token because it's a separate application (not a server-rendered Thymeleaf page that includes the token automatically).

Diagnosis: enable `logging.level.org.springframework.security.web.csrf=TRACE`. You'll see "Invalid CSRF token found" in the logs. The CsrfFilter rejects the request before it reaches the AuthorizationFilter.

For a stateless API (JWT-based, no server sessions), CSRF protection is unnecessary because the attack vector CSRF protects against (browser automatically sending session cookies) doesn't apply when auth is via Bearer tokens. Fix: disable CSRF for the API chain: `.csrf(c -> c.ignoringRequestMatchers("/api/**"))`. But DO configure CORS properly: `.cors(c -> c.configurationSource(corsConfig()))` to prevent unauthorized cross-origin requests.

The common mistake: disabling CSRF globally (including for server-rendered pages) instead of only for the API path. If you have both a Thymeleaf admin panel and a REST API, the admin panel still needs CSRF.

_What separates good from great:_ Explain WHY CSRF isn't needed for token-based APIs. "CSRF exploits the browser's automatic cookie attachment. If your auth is via Authorization header (Bearer token), the browser doesn't automatically attach it - the client must explicitly include it. That eliminates the CSRF attack vector."

**Q2: Explain how Spring Security decides between returning 401 and 403.** [MID]

The decision happens in `ExceptionTranslationFilter`, which catches security exceptions thrown by downstream filters (especially `AuthorizationFilter`). The logic: (1) If `AuthorizationFilter` throws `AccessDeniedException` AND the `SecurityContext` contains an `AnonymousAuthenticationToken` (user is not authenticated), ExceptionTranslationFilter treats it as an authentication problem and invokes the `AuthenticationEntryPoint` which returns 401. (2) If `AuthorizationFilter` throws `AccessDeniedException` AND the `SecurityContext` contains a real authenticated principal, ExceptionTranslationFilter invokes the `AccessDeniedHandler` which returns 403.

In plain English: 401 means "I don't know who you are" (no valid credentials presented). 403 means "I know who you are, but you're not allowed" (valid credentials but insufficient privileges).

Edge cases: (1) An expired JWT results in 401 because the authentication filter fails to authenticate, leaving an anonymous context. (2) A valid JWT with wrong roles results in 403 because authentication succeeds but authorization fails. (3) No Authorization header at all results in 401 (anonymous user trying to access protected resource).

_What separates good from great:_ Know that `ExceptionTranslationFilter` is the decision point, not the individual auth filters. The auth filter populates (or doesn't populate) the SecurityContext; ExceptionTranslationFilter reads the context to decide the response code.

**Q3: Your API returns 403 intermittently - works 80% of the time, fails 20%. Same user, same endpoint, same token. How do you diagnose?** [SENIOR]

Intermittent 403 with identical requests points to infrastructure, not application logic. Systematic diagnosis: (1) Check if you're behind a load balancer with multiple instances. If one instance has stale security configuration (e.g., after a partial deploy), it rejects while others accept. Compare filter chain config across pods: Actuator `/configprops` on each instance. (2) Check for session-based state: if any filter stores state in the HTTP session and you're using sticky sessions, a session failover to a different pod loses the state. For JWT APIs, this shouldn't happen, but check if `SecurityContextRepository` is session-based vs stateless. (3) Check token clock skew: JWT validation includes `exp` (expiry) and `iat` (issued at) claims. If the resource server's clock is 30 seconds ahead of the auth server, tokens appear expired early. If the token has a 5-minute lifetime and the clock skew is 4 minutes, ~20% of requests hit the edge of expiry. Fix: `jwtDecoder.setClockSkew(Duration.ofSeconds(60))`. (4) Check for rate limiting or IP-based blocking: a WAF or API gateway in front of Spring may return 403 independently of Spring Security.

Diagnostic approach: add a response header in a custom filter that includes the instance ID. When the user reports 403, check which instance served the request. Compare TRACE logs across instances.

_What separates good from great:_ Immediately think infrastructure for intermittent issues. "Deterministic 403 = configuration problem. Intermittent 403 = state, clock, or routing problem. I ask about the deployment topology before looking at code."

**Q4: How do you secure a Spring Boot application in production beyond the filter chain?** [SENIOR]

Production security is defense-in-depth beyond just the filter chain: (1) HTTP headers: `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`, `X-Frame-Options: DENY`. Spring Security adds most by default; verify with a security header scanner. (2) TLS termination: ensure the app trusts the proxy's `X-Forwarded-*` headers: `server.forward-headers-strategy=native`. Without this, the app thinks it's HTTP and generates non-HTTPS redirects. (3) Secrets management: never store credentials in application.yml. Use environment variables, Kubernetes secrets, or Spring Cloud Config with encryption. Rotate credentials without restart using `@RefreshScope`. (4) Dependency scanning: `mvn dependency-check:check` (OWASP) to find known CVEs in dependencies. Automate in CI. (5) Actuator lockdown: management endpoints on separate port (`management.server.port=9090`), accessible only from internal network. Expose only `/health` on the main port for load balancer.

(6) Method-level security: `@PreAuthorize` on service methods as a second authorization layer. Even if the URL pattern allows access, method security validates business rules (e.g., user can only view their own orders). (7) SQL injection prevention: always use parameterized queries (JPA handles this); never concatenate user input into queries. (8) Logging: log authentication events (success, failure, token refresh) for audit trail. Never log tokens or passwords.

_What separates good from great:_ Frame security as layers. "The filter chain is ONE layer. Method security is another. Network policy is another. Each layer catches what the previous one missed. I design security so that compromising one layer doesn't compromise the system."

**Q5: Compare session-based vs token-based (JWT) security for a Spring Boot API. When would you choose each?** [STAFF]

Session-based: Server stores auth state in HttpSession (in-memory or Redis). Client receives a session cookie. Pros: revocation is instant (delete the session), no token size in every request, server controls session lifetime, simpler implementation. Cons: requires sticky sessions or shared session store for multiple instances, doesn't work for cross-domain APIs (cookies are domain-bound), stateful server scales less elegantly.

Token-based (JWT): Client receives a signed token containing claims (user ID, roles, expiry). Server validates the signature on each request; no server-side state. Pros: stateless (any instance can validate), works across domains (Authorization header), supports microservice-to-microservice auth (token forwarding), mobile/SPA friendly. Cons: revocation is hard (token is valid until expiry), token size grows with claims (every request carries it), complexity of key management (signing keys, JWKS rotation).

Decision framework: Use sessions for: traditional server-rendered apps (Thymeleaf), admin panels with low traffic, cases requiring instant revocation (banking). Use JWT for: APIs consumed by SPAs/mobile, microservice architectures, distributed systems across domains, high-scale stateless services.

Hybrid approach: short-lived JWTs (5-15 min) + refresh tokens stored server-side (Redis). This gives stateless validation for most requests while enabling revocation via refresh token invalidation. The JWT can't be revoked, but it expires quickly. This is the most common production pattern.

_What separates good from great:_ Address the "JWT revocation problem" proactively. "Pure JWTs can't be revoked. I solve this with short expiry + refresh tokens, or a distributed blocklist checked on each request (adds latency but enables instant revocation for compromised tokens)."

**Q6: Write a custom filter that logs the authenticated user for every request.** [MID]

```java
@Component
public class RequestLoggingFilter
    extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain chain
    ) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder
            .getContext().getAuthentication();

        String user = (auth != null
            && auth.isAuthenticated()
            && !(auth instanceof
                 AnonymousAuthenticationToken))
            ? auth.getName()
            : "anonymous";

        MDC.put("userId", user);
        MDC.put("requestId",
            UUID.randomUUID().toString()
                .substring(0, 8));
        try {
            log.info("[{}] {} {}",
                user,
                request.getMethod(),
                request.getRequestURI());
            chain.doFilter(request, response);
        } finally {
            MDC.remove("userId");
            MDC.remove("requestId");
        }
    }
}

// Register AFTER authentication filters
@Bean
SecurityFilterChain chain(HttpSecurity http)
    throws Exception {
    return http
        .addFilterAfter(
            new RequestLoggingFilter(),
            AuthorizationFilter.class
        )
        // ... other config
        .build();
}
```

Key: the filter must be placed AFTER authentication (so `SecurityContextHolder` is populated) but BEFORE the controller. Using `OncePerRequestFilter` prevents double-execution on forwarded requests. MDC integration means every log line in the request includes the userId.

_What separates good from great:_ Use `OncePerRequestFilter` (not plain `Filter`) and place it correctly in the chain. Know that placing it BEFORE authentication means `auth` is always null.

**Q7: Design a security architecture for an application with three user types: public users (no auth), customers (JWT), and admins (JWT + MFA). Each has different endpoints.** [STAFF]

Three `SecurityFilterChain` beans with `@Order` and distinct matchers:

```java
@Order(1)  // First match wins
@Bean
SecurityFilterChain publicChain(HttpSecurity http)
    throws Exception {
    return http
        .securityMatcher("/public/**", "/health")
        .authorizeHttpRequests(a -> a
            .anyRequest().permitAll())
        .build();
}

@Order(2)
@Bean
SecurityFilterChain adminChain(HttpSecurity http)
    throws Exception {
    return http
        .securityMatcher("/admin/**")
        .oauth2ResourceServer(o -> o.jwt(...))
        .addFilterAfter(
            mfaVerificationFilter(),
            BearerTokenAuthenticationFilter.class
        )
        .authorizeHttpRequests(a -> a
            .anyRequest().hasRole("ADMIN"))
        .build();
}

@Order(3)
@Bean
SecurityFilterChain customerChain(HttpSecurity http)
    throws Exception {
    return http
        .securityMatcher("/api/**")
        .oauth2ResourceServer(o -> o.jwt(...))
        .authorizeHttpRequests(a -> a
            .anyRequest().authenticated())
        .build();
}
```

Architecture decisions: (1) Public chain is first and has NO authentication at all - requests to `/public/**` skip the entire security stack (except basic headers). This is fastest. (2) Admin chain is second and adds an MFA verification filter that checks a custom JWT claim (`mfa_verified: true`) after the standard JWT authentication. If the claim is missing, it returns 403 with a response pointing to the MFA endpoint. (3) Customer chain is last and does standard JWT authentication.

Why this ordering: more specific chains first. If customer chain (`/api/**`) were first, it would catch `/api/admin/**` requests. By putting admin first with `/admin/**`, admin requests get the stricter chain. The public chain could be any order since its matcher is distinct.

_What separates good from great:_ Explain the MFA implementation detail. "MFA isn't a separate authentication step - it's a JWT claim. The auth server issues a token with `mfa_verified: true` only after the user completes MFA. My custom filter just checks this claim. This keeps the resource server stateless."

**Q8: A developer reports that @PreAuthorize annotations are being ignored. What's wrong?** [SENIOR]

Ordered diagnosis: (1) Check if method security is enabled: `@EnableMethodSecurity` must be present on a @Configuration class. Without it, @PreAuthorize is completely ignored (no error, no warning). In Spring Security 6+, it's `@EnableMethodSecurity`; in older versions, `@EnableGlobalMethodSecurity(prePostEnabled = true)`. (2) Check the annotation is on a Spring-managed bean: if the class isn't a Spring component (not @Service, @Component, etc.), method security proxies aren't applied. (3) Self-invocation: same issue as @Transactional. If method A calls `this.methodB()` where methodB has @PreAuthorize, the proxy is bypassed. (4) Check the SpEL expression: `@PreAuthorize("hasRole('ADMIN')")` requires the authority to be `ROLE_ADMIN` (Spring prefixes "ROLE\_" by default). If the JWT contains `"roles": ["admin"]`, you need `hasAuthority('admin')` not `hasRole('admin')`. (5) Check for exception handling: if a global @ControllerAdvice catches `AccessDeniedException` and returns 200 with an error body, it looks like security is "ignored" when it actually fired and was swallowed.

Quick diagnostic: add `logging.level.org.springframework.security.access=TRACE`. This logs every @PreAuthorize evaluation with the expression, the principal's authorities, and the result.

_What separates good from great:_ The #1 cause is missing `@EnableMethodSecurity`. "I always check the annotation first because it's the most common issue and takes 2 seconds to verify. If that's present, I check authorities naming (ROLE\_ prefix confusion) next."

**Q9: How do you handle security in a microservice architecture where services call each other?** [SENIOR]

Service-to-service security patterns: (1) Token propagation: the originating user's JWT is forwarded in the Authorization header from service A to service B. B validates the token independently (shared JWKS endpoint). Pros: end-to-end user identity preserved, B can check user permissions. Cons: token must have sufficient scopes for all downstream services, token expiry must account for total chain duration.

(2) Service accounts: each service has its own OAuth2 client credentials. Service A obtains a token for itself (client_credentials grant) and calls B. B validates A's identity and checks service-level permissions. Pros: clear service identity, independent of user session. Cons: user identity is lost unless explicitly propagated in a custom header.

(3) Mutual TLS (mTLS): services authenticate via X.509 certificates at the transport layer. No application-level token needed. Pros: strong authentication, no token management. Cons: certificate management at scale is complex, doesn't carry user identity.

My production pattern: token propagation for user-initiated requests (preserves user identity for audit/authorization), client_credentials for service-initiated background jobs (no user context), mTLS at the network level via service mesh (Istio) as a defense-in-depth layer. Spring's `OAuth2FeignClient` or `WebClient` with `ServerOAuth2AuthorizedClientExchangeFilterFunction` handles token propagation automatically.

_What separates good from great:_ Address token expiry in chains. "If user token expires while request traverses 5 services, the 4th service gets 401. I set token lifetime to 15 min (longer than any request chain) and validate clock skew tolerance on each service."

**Q10: How do you audit security events in a Spring Boot application?** [SENIOR]

Spring Security publishes application events for security-relevant actions. Implement an `ApplicationListener` or `@EventListener` for: `AuthenticationSuccessEvent` (successful login), `AuthenticationFailureBadCredentialsEvent` (wrong password), `AuthorizationDeniedEvent` (access denied), `SessionCreatedEvent` / `SessionDestroyedEvent`.

Production audit implementation:

```java
@Component
@Slf4j
public class SecurityAuditListener {
    @EventListener
    public void onAuthSuccess(
        AuthenticationSuccessEvent event) {
        log.info("AUTH_SUCCESS user={} ip={}",
            event.getAuthentication().getName(),
            extractIp(event));
    }

    @EventListener
    public void onAuthFailure(
        AbstractAuthenticationFailureEvent e) {
        log.warn("AUTH_FAILURE type={} user={} ip={}",
            e.getClass().getSimpleName(),
            e.getAuthentication().getName(),
            extractIp(e));
    }
}
```

These events are structured logs sent to ELK/Splunk for: (1) Failed login attempt monitoring (brute force detection: >5 failures from same IP in 1 minute → alert). (2) Unusual access patterns (user accessing admin endpoints for the first time → flag for review). (3) Compliance audit trail (who accessed what, when, from where). (4) Token usage analytics (how often tokens are refreshed, how many are expired vs revoked).

For regulatory compliance (SOC2, HIPAA): audit events must include timestamp, user identity, action, resource, source IP, and result. Store in append-only storage with tamper detection.

_What separates good from great:_ Know that security events are synchronous by default. "I process audit events asynchronously (Spring @Async or message queue) to avoid adding latency to the security filter chain. An audit system failure shouldn't cause 500 errors on login."

**Q11: Tell me about a time you debugged a complex Spring Security issue in production.** [SENIOR]

We had a production incident where a specific user group (approximately 200 users from a partner organization) couldn't access the API after a routine Spring Boot upgrade (2.7 to 3.1). All other users worked fine. No code changes to security configuration.

Investigation: (1) Checked TRACE logs for affected users - `AuthorizationFilter` denied with "Access Denied" after successful authentication. The JWT was valid, user was authenticated, but authorization failed. (2) Compared JWT claims between working and non-working users. Partner users had roles as `["partner:read", "partner:write"]` (colon-separated). Internal users had `["ROLE_USER", "ROLE_ADMIN"]`. (3) Root cause: Spring Security 6 (in Boot 3.1) changed the default `GrantedAuthority` handling. The new `JwtGrantedAuthoritiesConverter` uses the `scope` claim by default (prefixed with `SCOPE_`), not the `roles` claim we were using. Our custom `JwtAuthenticationConverter` was still configured for the old API, but the new Security version's `AuthorizationFilter` evaluated authorities differently.

Fix: Updated the `JwtAuthenticationConverter` to explicitly extract the `roles` claim and map authorities. Added an integration test with partner-style JWT tokens to prevent regression. The lesson: upgrade guides for Spring Security are critical reading - security behavior changes are intentional but often subtle.

_What separates good from great:_ Show that you read the Spring Security migration guide BEFORE debugging. "My first step for any post-upgrade issue is checking the migration guide. Spring Security 6 had 40+ breaking changes documented. The authority handling change was listed - I should have caught it in review."

**Q12: What is the ExceptionTranslationFilter and why is it important in the filter chain?** [MID]

ExceptionTranslationFilter sits between the authentication filters and the AuthorizationFilter. Its job is to translate security exceptions into HTTP responses. It catches two types of exceptions: (1) `AuthenticationException` (thrown when authentication fails or is required but missing) - delegates to `AuthenticationEntryPoint` which typically returns 401 or redirects to a login page. (2) `AccessDeniedException` (thrown by AuthorizationFilter when the user lacks permissions) - checks if the current user is anonymous (unauthenticated) → treat as authentication problem (401); if authenticated → delegate to `AccessDeniedHandler` (403).

This is important because without it, security exceptions would bubble up as 500 Internal Server Error (unhandled exceptions). ExceptionTranslationFilter ensures proper HTTP semantics: authentication problems get 401, authorization problems get 403.

The subtle behavior: if an anonymous user hits a protected endpoint, `AuthorizationFilter` throws `AccessDeniedException` (not `AuthenticationException`). ExceptionTranslationFilter checks: "is this user anonymous?" → yes → "then it's really an authentication problem" → invoke entry point (401). This is why anonymous access to protected resources returns 401, not 403.

Custom entry points: for APIs, you typically return a JSON error body: `response.setStatus(401); response.getWriter().write("{\"error\": \"Unauthorized\"}")`. For web apps, you redirect to `/login`.

_What separates good from great:_ Explain the anonymous-to-401 conversion. "Most developers think AccessDeniedException always means 403. ExceptionTranslationFilter's anonymous check is why unauthenticated users get 401 - it re-interprets the exception based on authentication state."

---

### Related Keywords

**Prerequisites:** Security Architecture (Spring Security),
Authentication and Authorization

**Builds on:** Servlet filter lifecycle, HTTP security headers

**Leads to:** JWT and OAuth2/OIDC debugging, Method-Level
Security diagnostics

**Alternatives:** Manual servlet filter security (no framework),
interceptor-based security (less powerful)

---

---

# Memory Leaks and ApplicationContext Lifecycle Issues

**TL;DR** - Spring memory leaks typically come from unclosed
ApplicationContexts in tests, static references to beans,
event listener accumulation, and ThreadLocal values surviving
thread pool reuse. Diagnose with heap dumps, JFR allocation
profiling, and Actuator's `/beans` endpoint.

---

### The Problem This Solves

A Spring Boot service runs fine for days, then OOMKills start.
The heap grows slowly, GC pauses increase, and eventually
Kubernetes restarts the pod. The team increases memory limits
from 512MB to 1GB to 2GB, buying time but not solving the
problem. The root cause is always a reference that prevents
garbage collection - often tied to Spring's ApplicationContext
lifecycle.

Memory leaks in Spring applications are especially tricky
because the ApplicationContext itself holds references to every
bean. If the context isn't closed properly (in tests, in
hot-reload scenarios, or in multi-context setups), the entire
bean graph stays in memory.

---

### Textbook Definition

Spring ApplicationContext lifecycle issues are bugs where
application contexts are created but not properly closed, or
where bean lifecycle callbacks (@PreDestroy, DisposableBean)
are not invoked, leading to resource leaks (memory, threads,
connections, file handles) that accumulate over time and
eventually cause OutOfMemoryError or resource exhaustion.

---

### Understand It in 30 Seconds

**One line:** If you create an ApplicationContext but don't
close it, every bean it holds stays in memory forever.

**Analogy:** An ApplicationContext is like a hotel room. Check
in (create context), stay (use beans), check out (close
context). If you never check out, the room stays occupied -
the towels (thread pools), minibar (connections), and TV
(scheduled tasks) stay allocated. Create 100 contexts without
closing them and the hotel is full.

**Key insight:** In production, you usually have ONE context
that lives forever (no leak). Leaks happen in tests (new
context per test class), hot-reload (old context not fully
closed), and programmatic context creation (forgotten close).

---

### First Principles

Memory management in Spring applications:

1. **ApplicationContext owns all beans** - every singleton bean
   is strongly referenced by the context
2. **Context close triggers cleanup** - @PreDestroy methods,
   thread pool shutdown, connection pool close
3. **GC can't collect** until all references are released -
   one static reference to one bean keeps the entire context
   alive
4. **Thread pools outlive requests** - if a thread holds a
   reference to a bean or context, neither can be collected
5. **Event listeners accumulate** - adding listeners without
   removing them on context close creates unbounded growth

---

### Mental Model / Analogy

```
┌──────────────────────────────────────┐
│  ApplicationContext (LIVE)           │
│                                      │
│  Bean A ──> Bean B ──> Bean C       │
│    │          │          │           │
│    └──> DataSource ──> Pool (10)    │
│    └──> Scheduler ──> Threads (5)   │
│    └──> Cache ──> 500MB entries     │
│                                      │
│  All strongly referenced by context  │
│  GC cannot collect ANY of these     │
└──────────────────────────────────────┘

Context.close() ->
  @PreDestroy on all beans
  DataSource.close() -> pool drained
  Scheduler.shutdown() -> threads stopped
  Cache.clear() -> entries released
  ALL references released -> GC collects
```

---

### How It Works - Five Levels

**Level 1 (Anyone):** Your application slowly uses more and
more memory until it crashes. Something is holding onto objects
that should have been released.

**Level 2 (Junior):** Memory leaks happen when objects can't
be garbage collected because something still references them.
In Spring, the ApplicationContext references all beans. If
the context isn't closed (or a bean isn't properly destroyed),
memory accumulates.

**Level 3 (Mid):** Common Spring-specific leak patterns:
(1) Test contexts: each `@SpringBootTest` class creates a
new ApplicationContext. Without `@DirtiesContext` or proper
caching, stale contexts accumulate during test suites.
(2) ThreadLocal leaks: a filter sets a ThreadLocal value but
doesn't clear it in a finally block. Since Tomcat reuses
threads, the value persists across requests and accumulates
if it references request-scoped data. (3) Event listener
leaks: registering ApplicationEventListeners dynamically
without a corresponding deregistration on context close.

**Level 4 (Senior/Staff):** Advanced leak scenarios:
(1) ClassLoader leaks in hot-deploy: when DevTools reloads
the application, a new ClassLoader is created. If the old
ClassLoader is referenced by a static field, a thread, or a
JVM shutdown hook, the entire old class hierarchy stays in
memory. (2) Caffeine/Guava cache with soft references: the
cache grows until GC pressure forces eviction, but if the
heap is large, GC doesn't trigger until it's nearly full,
causing sudden long pauses. (3) JPA second-level cache
without size limits: every entity ever loaded stays cached
until explicitly evicted.

Diagnosis toolchain: `jmap -dump:live,format=b,file=heap.hprof PID`
for heap dump. Eclipse MAT (Memory Analyzer Tool) to find
retained-size dominator tree. JFR with
`jdk.ObjectAllocationInNewTLAB` event to track allocation
hotspots. `jcmd PID GC.class_stats` for ClassLoader leak
detection.

**Level 5 (Distinguished):** The fundamental issue is that
Spring's IoC container creates a ownership graph that mirrors
the dependency graph. In a microservice with 200+ beans, the
context's retained size can be 50-100MB just for bean
metadata, proxy classes, and AOP infrastructure. This is the
"memory tax" of a rich DI container. Alternatives like
Micronaut and Quarkus reduce this tax by resolving
dependencies at compile time, generating code instead of
reflective proxies, and avoiding runtime metadata storage.

---

### How It Works - Mechanism

**Leak detection flowchart:**

```
OOMKilled or slow GC
  │
  ├── Heap dump: jmap -dump:live,...
  │
  ├── Open in Eclipse MAT
  │   └── Dominator tree -> biggest objects
  │       │
  │       ├── ApplicationContext (test leak)
  │       │   -> Multiple contexts alive
  │       │   -> Fix: @DirtiesContext
  │       │
  │       ├── char[]/String (cache leak)
  │       │   -> Cache unbounded
  │       │   -> Fix: max size config
  │       │
  │       ├── Thread references
  │       │   -> ThreadLocal not cleared
  │       │   -> Fix: finally { tl.remove() }
  │       │
  │       └── ClassLoader (reload leak)
  │           -> DevTools/hot-deploy
  │           -> Fix: remove static refs
  │
  └── JFR allocation profiling
      -> Shows where objects are created
      -> Pinpoints the allocating code path
```

---

### Code Example

```java
// BAD: ThreadLocal leak in servlet filter
@Component
public class TenantFilter
    extends OncePerRequestFilter {

    private static final ThreadLocal<String>
        TENANT = new ThreadLocal<>();

    @Override
    protected void doFilterInternal(
        HttpServletRequest req,
        HttpServletResponse res,
        FilterChain chain
    ) throws ServletException, IOException {
        TENANT.set(req.getHeader("X-Tenant-ID"));
        chain.doFilter(req, res);
        // LEAK! If chain.doFilter throws,
        // TENANT is never cleared.
        // Tomcat reuses this thread; old
        // tenant ID leaks to next request.
        TENANT.remove();
    }
}

// GOOD: Always clear in finally block
@Component
public class TenantFilter
    extends OncePerRequestFilter {

    private static final ThreadLocal<String>
        TENANT = new ThreadLocal<>();

    @Override
    protected void doFilterInternal(
        HttpServletRequest req,
        HttpServletResponse res,
        FilterChain chain
    ) throws ServletException, IOException {
        TENANT.set(req.getHeader("X-Tenant-ID"));
        try {
            chain.doFilter(req, res);
        } finally {
            TENANT.remove(); // ALWAYS clears
        }
    }

    public static String current() {
        return TENANT.get();
    }
}
```

```java
// BAD: Programmatic context never closed
public void processMessage(Message msg) {
    AnnotationConfigApplicationContext ctx =
        new AnnotationConfigApplicationContext(
            ProcessorConfig.class);
    ctx.getBean(Processor.class).process(msg);
    // Context never closed! Every call
    // creates beans, threads, connections
    // that are never released.
}

// GOOD: try-with-resources closes context
public void processMessage(Message msg) {
    try (var ctx =
        new AnnotationConfigApplicationContext(
            ProcessorConfig.class)) {
        ctx.getBean(Processor.class).process(msg);
    } // @PreDestroy, pool close, etc.
}
```

---

### Quick Reference Card

| Field          | Value                                            |
| -------------- | ------------------------------------------------ |
| Category       | Memory Diagnostics                               |
| Heap dump      | `jmap -dump:live,format=b,file=h.hprof PID`      |
| Analyzer       | Eclipse MAT (dominator tree)                     |
| JFR allocation | `jdk.ObjectAllocationInNewTLAB`                  |
| ClassLoader    | `jcmd PID GC.class_stats`                        |
| Actuator       | `/beans` (count), `/metrics` (heap)              |
| Test context   | `@DirtiesContext` or context caching             |
| ThreadLocal    | Always `.remove()` in finally                    |
| Context close  | `try-with-resources` or `registerShutdownHook()` |

**3 things to remember:**

1. ThreadLocal.remove() in finally - always
2. ApplicationContext.close() releases all beans
3. Eclipse MAT dominator tree finds the leak in 5 minutes

**One-liner:** "Most Spring memory leaks are unclosed contexts,
uncleared ThreadLocals, or unbounded caches."

---

### Mastery Checklist

- [ ] DIAGNOSE: Take a heap dump and find the leak using
      Eclipse MAT's dominator tree
- [ ] PREVENT: Audit all ThreadLocal usage for finally-block
      cleanup
- [ ] TEST: Verify @PreDestroy methods are called on
      context shutdown
- [ ] ARCHITECT: Design bounded caches with eviction policies
      for all bean-managed state
- [ ] MONITOR: Set up JFR continuous recording with allocation
      event tracking

---

### Surprising Truth

Spring Boot's test framework caches ApplicationContexts across
test classes by default (if the context configuration is
identical). This is a performance optimization that prevents
creating a new context per test class. But if each test class
has a slightly different configuration (@MockBean on different
beans, different @ActiveProfiles), each gets its OWN cached
context that stays alive for the entire test suite. A project
with 200 test classes and 50 unique context configurations
will have 50 ApplicationContexts in memory simultaneously.
This is why test OOMs are common - and why
`@DirtiesContext` (which destroys the context after the test)
actually reduces memory usage despite seeming wasteful.

---

### Common Misconceptions

| #   | Misconception                            | Reality                                                                               | Why It Matters                                                       |
| --- | ---------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | GC prevents all memory leaks             | GC only collects unreachable objects; strong references prevent collection            | Spring contexts hold strong references to all beans                  |
| 2   | Spring handles all cleanup automatically | Only if context.close() is called; abrupt JVM shutdown may skip @PreDestroy           | External resources (files, connections) leak without proper shutdown |
| 3   | ThreadLocal is cleaned up per request    | Tomcat reuses threads; ThreadLocal persists across requests unless explicitly removed | Data leaks between requests (security risk + memory)                 |
| 4   | Increasing heap size fixes memory leaks  | It delays the OOM; the leak rate stays the same                                       | GC pauses get worse with larger heaps; fix the leak                  |

---

### Failure Modes and Diagnosis

| Failure Mode              | Symptom                                            | Diagnostic Command                                  | Fix                                                    |
| ------------------------- | -------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------ |
| Test context accumulation | OOM during test suite                              | `-Dspring.test.context.cache.maxSize=5` + heap dump | Share context configs; use @DirtiesContext selectively |
| ThreadLocal leak          | Old request data in new requests; slow heap growth | `jmap -dump` → MAT → ThreadLocalMap entries         | `finally { threadLocal.remove(); }`                    |
| ClassLoader leak          | PermGen/Metaspace OOM on redeploy                  | `jcmd PID GC.class_stats` shows duplicate classes   | Remove static references to application classes        |
| Unbounded cache           | Heap grows linearly with traffic                   | `/actuator/metrics/cache.size`                      | Add `maximumSize` and TTL to all caches                |

---

### Interview Deep-Dive

**Timing Table:**

| Question | Type         | Difficulty | Time |
| -------- | ------------ | ---------- | ---- |
| Q1       | DEBUGGING    | SENIOR     | 120s |
| Q2       | CONCEPTUAL   | MID        | 90s  |
| Q3       | PRODUCTION   | SENIOR     | 120s |
| Q4       | TRADE-OFF    | STAFF      | 150s |
| Q5       | DEBUGGING    | SENIOR     | 120s |
| Q6       | HANDS-ON     | MID        | 90s  |
| Q7       | ARCHITECTURE | STAFF      | 150s |
| Q8       | DEBUGGING    | SENIOR     | 120s |
| Q9       | PRODUCTION   | SENIOR     | 120s |
| Q10      | TRADE-OFF    | SENIOR     | 120s |
| Q11      | BEHAVIORAL   | SENIOR     | 120s |
| Q12      | CONCEPTUAL   | MID        | 90s  |

**Q1: A Spring Boot service is OOMKilled every 3 days in production. How do you find the leak?** [SENIOR]

Systematic approach: (1) Confirm it's a leak, not under-provisioning. Check Grafana: is heap usage a sawtooth (normal GC) with a rising baseline (leak), or does it just spike to 100% under load (need more memory)? Rising baseline = leak. (2) Enable heap dump on OOM: `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/`. Wait for the next OOM and grab the dump. (3) If you can't wait: take a heap dump now (`jmap -dump:live,format=b,file=heap.hprof PID`) and another in 24 hours. Compare retained sizes - objects that grew are the suspects. (4) Analyze in Eclipse MAT: open the dump, run "Leak Suspects" report. Check the dominator tree for the largest retained-size objects. Common findings: ConcurrentHashMap$Node (unbounded cache), char[] (String accumulation in a cache or log buffer), byte[] (buffered I/O not released).

(5) For ThreadLocal leaks specifically: MAT → "Group by class" → search for ThreadLocalMap$Entry. If there are thousands of entries with the same value type, a ThreadLocal is leaking. (6) JFR for allocation profiling: start a 1-hour recording with `jdk.ObjectAllocationInNewTLAB` enabled. The allocation flame graph shows which code paths are creating the most objects - the top allocator is usually the leak source.

_What separates good from great:_ Have a diagnostic playbook that doesn't require reproducing the issue. "I don't try to reproduce memory leaks locally. I instrument production with JFR continuous recording and heap-dump-on-OOM. When it happens, I have all the data I need."

**Q2: Explain the ApplicationContext lifecycle and what happens at each phase.** [MID]

The ApplicationContext lifecycle has four major phases: (1) Creation: `new AnnotationConfigApplicationContext()` or `SpringApplication.run()`. At this point, the context object exists but is empty. (2) Refresh: `context.refresh()` is called (automatically by SpringApplication). This is the main phase: bean definitions are loaded from component scan and @Configuration classes, BeanFactoryPostProcessors modify definitions (e.g., PropertySourcesPlaceholderConfigurer resolves ${} placeholders), beans are instantiated in dependency order, BeanPostProcessors run on each bean (e.g., AutowiredAnnotationBeanPostProcessor for @Autowired), @PostConstruct methods execute, InitializingBean.afterPropertiesSet() runs, SmartLifecycle beans are started. (3) Active: the context is ready. Beans serve requests. Events can be published and consumed. (4) Close: `context.close()` or JVM shutdown hook. SmartLifecycle beans are stopped (in reverse order), @PreDestroy methods execute, DisposableBean.destroy() runs, all bean references are released, the context is no longer usable.

The critical detail: if close() is never called (e.g., test creates context but doesn't close), phase 4 never happens. @PreDestroy never fires. Thread pools don't shut down. Connections don't close. Everything stays in memory until the JVM exits.

_What separates good from great:_ Know that `registerShutdownHook()` adds a JVM shutdown hook that calls close() automatically. SpringApplication.run() does this by default. But programmatically created contexts don't - you must call close() yourself or register the hook.

**Q3: How do you prevent memory leaks in a Spring application that processes millions of messages per day?** [SENIOR]

High-throughput applications have unique leak risks because small per-message leaks accumulate fast (1KB leak x 10M messages/day = 10GB/day). Prevention strategy: (1) Bounded everything: every cache, queue, and buffer must have a max size. Caffeine cache: `.maximumSize(10000).expireAfterWrite(Duration.ofMinutes(30))`. Message buffer: bounded BlockingQueue, not unbounded LinkedList. (2) Request-scoped cleanup: every message processing path must clean up in a finally block - ThreadLocals, MDC context, temporary files, input streams. Use try-with-resources for all Closeable objects. (3) Connection pool monitoring: HikariCP's `leakDetectionThreshold` logs a stack trace when a connection isn't returned within N milliseconds. Set it to 30 seconds in production: `spring.datasource.hikari.leak-detection-threshold=30000`.

(4) Periodic heap analysis: JFR continuous recording with 24-hour rotation. Every morning, check allocation summaries for unexpected growth. (5) Test with load: run a 1-hour load test at production throughput. Compare heap before and after. If heap is 100MB higher after 1M messages, there's a leak. (6) Weak references for listener patterns: if your message processor registers listeners dynamically, use WeakReference to allow GC to collect listeners when the registering object is no longer needed.

_What separates good from great:_ Calculate the leak rate. "1KB per message at 10M messages/day is 10GB/day. With a 2GB heap, that's OOM in 5 hours. Always calculate: leak_size x throughput = time_to_OOM."

**Q4: Compare different approaches to managing bean lifecycle in Spring: @PostConstruct/@PreDestroy, InitializingBean/DisposableBean, @Bean(initMethod/destroyMethod), SmartLifecycle.** [STAFF]

Four lifecycle mechanisms with different use cases:

**@PostConstruct/@PreDestroy (JSR-250):** Standard Java annotations. Run after dependency injection (PostConstruct) or before context close (PreDestroy). Pros: standard, readable, no Spring dependency in the bean class. Cons: no ordering control between beans, no guarantee of execution order relative to other lifecycle callbacks.

**InitializingBean/DisposableBean (Spring interface):** Bean implements the interface. `afterPropertiesSet()` runs after all properties set, `destroy()` on context close. Pros: enforced by compiler (can't forget to implement), Spring-aware ordering. Cons: couples the bean to Spring API, less readable than annotations.

**@Bean(initMethod/destroyMethod):** Specified in @Configuration. Pros: no code changes to the bean class (works with third-party classes), method can be named anything. Cons: string-based method names (no compile-time checking), easy to forget to configure.

**SmartLifecycle:** For beans that need ordered startup/shutdown phases. `getPhase()` returns an integer; lower phases start first, stop last. `isRunning()` tracks state. Pros: ordered startup/shutdown, explicit start/stop control, can auto-start. Cons: most complex option, overkill for simple init/destroy.

Decision: @PostConstruct/@PreDestroy for most beans. SmartLifecycle for infrastructure beans that need ordered startup (start message consumers AFTER cache warmup). @Bean(initMethod) for third-party beans you can't annotate. Avoid InitializingBean unless you need Spring-specific ordering guarantees.

_What separates good from great:_ Know the execution order: constructor → @Autowired → @PostConstruct → InitializingBean → @Bean(initMethod). For destruction: @PreDestroy → DisposableBean → @Bean(destroyMethod). SmartLifecycle.stop() runs BEFORE @PreDestroy.

**Q5: A Spring Boot test suite takes 30 minutes and runs out of memory. The same tests pass individually. Diagnose.** [SENIOR]

Test suite OOM with individual pass = context accumulation. Spring's test framework caches ApplicationContexts keyed by context configuration (annotation set, profiles, properties). If 100 test classes each have a slightly different @MockBean set, 100 separate ApplicationContexts are created and cached simultaneously.

Diagnosis: (1) Add `-Dspring.test.context.cache.maxSize=3` and rerun. If it passes (slower but no OOM), the problem is context cache size. (2) Count unique contexts: add `logging.level.org.springframework.test.context.cache=DEBUG`. The log shows "Spring test ApplicationContext cache statistics" with hit/miss counts. A high miss count means many unique contexts. (3) Find the divergent configurations: check which test classes use @MockBean (each unique @MockBean combination creates a new context), @TestPropertySource (different properties = different context), @ActiveProfiles (different profiles = different context).

Fix strategy: (1) Standardize test configurations: create a shared `@TestConfiguration` that all integration tests use. Avoid per-test @MockBean. (2) Use `@MockitoBean` (Spring Boot 3.4+) which reuses contexts better than @MockBean. (3) Group tests by context configuration: tests using the same context config run together, maximizing cache hits. (4) Use `@DirtiesContext` on tests that genuinely need isolated contexts (tells Spring to destroy the context after this test, freeing memory). (5) Nuclear option: `spring.test.context.cache.maxSize=5` limits cached contexts to 5 (older ones are evicted and closed).

_What separates good from great:_ Know the root cause: "@MockBean is the biggest context cache killer. Each unique combination creates a new context. I refactor tests to use a shared base class with common mocks instead of per-test @MockBean."

**Q6: Write a Spring bean that detects and logs its own memory usage periodically.** [MID]

```java
@Component
@Slf4j
public class MemoryMonitor {

    @Scheduled(fixedRate = 60_000)
    public void reportMemory() {
        Runtime rt = Runtime.getRuntime();
        long total = rt.totalMemory();
        long free = rt.freeMemory();
        long used = total - free;
        long max = rt.maxMemory();

        double usedPct = (double) used / max * 100;

        log.info(
            "MEMORY used={}MB total={}MB max={}MB "
            + "pct={:.1f}%",
            used / 1_048_576,
            total / 1_048_576,
            max / 1_048_576,
            usedPct
        );

        if (usedPct > 85) {
            log.warn(
                "MEMORY_HIGH heap at {:.1f}% - "
                + "investigate potential leak",
                usedPct
            );
        }
    }

    @PreDestroy
    public void cleanup() {
        log.info("MemoryMonitor shutting down");
    }
}
```

For production, prefer Micrometer metrics (`jvm_memory_used_bytes`) exported to Prometheus with Grafana alerts. The @Scheduled approach is a quick diagnostic tool, not a replacement for proper monitoring.

_What separates good from great:_ Know that `Runtime.freeMemory()` is misleading - it's free space in the CURRENT heap size, not the maximum. `maxMemory() - totalMemory() + freeMemory()` is the truly available memory. And triggering GC from application code (`System.gc()`) is an anti-pattern that should never be used as a "fix."

**Q7: Design a memory-safe architecture for a Spring application that caches large amounts of data.** [STAFF]

Architecture for cache-heavy Spring applications: (1) Tiered caching: L1 = in-process Caffeine cache (small, fast, bounded by entry count). L2 = Redis/Hazelcast (larger, network hop, bounded by memory policy). L3 = database/source of truth. Spring Cache abstraction with `@Cacheable` supports this: `CacheManager` configured with Caffeine for L1 and RedisTemplate for L2, with a composite cache manager delegating between them.

(2) Memory budget: calculate the cache's memory footprint. If each cached object is 2KB and you cache 100,000 entries, that's 200MB. Set Caffeine's `maximumWeight` (not just `maximumSize`) using a `Weigher` that estimates byte size: `.maximumWeight(200_000_000).weigher((key, val) -> estimateSize(val))`. This prevents "100 entries of 50MB each" from crashing the JVM.

(3) Eviction strategy: `expireAfterWrite` for data that changes (invalidate stale entries). `expireAfterAccess` for LRU behavior (evict unused entries). `refreshAfterWrite` for async refresh (serve stale while loading fresh). Never use `softValues()` in production - it delegates eviction to the GC, causing unpredictable pauses.

(4) Off-heap for large datasets: if the cache needs >1GB, consider off-heap storage (Chronicle Map, MapDB) that doesn't affect GC pauses. The data lives outside the JVM heap in direct memory, managed by the application.

(5) Monitoring: expose Caffeine stats via Micrometer: `cache.gets`, `cache.puts`, `cache.evictions`, `cache.size`. Alert on: eviction rate spikes (cache too small), hit rate drops (cache invalidation too aggressive), size approaching maximum (need to increase or tune).

_What separates good from great:_ Calculate the memory budget explicitly. "I don't guess cache sizes. I profile the average cached object size, multiply by expected cardinality, add 30% overhead for data structures, and set that as the max weight. The cache never exceeds its budget."

**Q8: After upgrading Spring Boot, your application leaks Metaspace memory. What changed?** [SENIOR]

Metaspace leaks in Java indicate ClassLoader or class generation issues. Spring-related causes after an upgrade: (1) CGLIB proxy generation changes: Spring Boot upgrades may change which beans get proxied. More proxied beans = more generated classes in Metaspace. If proxy generation is happening repeatedly (e.g., per-request prototype beans with AOP), Metaspace fills. Diagnostic: `jcmd PID VM.classloader_stats` shows which ClassLoaders hold the most classes. (2) Reflection cache growth: Spring uses reflection extensively; the JVM caches reflection metadata in Metaspace. A new version may trigger reflection on more classes. (3) Groovy/SpEL compilation: if the upgrade changed how SpEL expressions are compiled (interpreted → compiled), each unique expression generates a class. With `@PreAuthorize(SpEL)` on 200 methods, that's 200 generated classes.

Fix: (1) Set Metaspace limits: `-XX:MaxMetaspaceSize=256m` to fail fast instead of growing unbounded. (2) For proxy leaks: check if prototype-scoped beans are proxied (each instance might generate a new class). Convert to singleton where possible. (3) For SpEL: `spring.expression.compiler.mode=OFF` disables SpEL compilation (slower evaluation but no class generation). (4) Monitor: `jvm_classes_loaded_classes_total` metric shows class count over time. If it grows linearly, classes are being generated without unloading.

_What separates good from great:_ Know the difference between heap leaks and Metaspace leaks. "Heap OOM means too many objects. Metaspace OOM means too many classes. The diagnostic tools are different: heap dump for heap, classloader stats for Metaspace."

**Q9: How do you implement proper shutdown in a Spring Boot application to prevent resource leaks?** [SENIOR]

Proper shutdown requires coordinating multiple systems: (1) Graceful HTTP shutdown: `server.shutdown=graceful` with `spring.lifecycle.timeout-per-shutdown-phase=30s`. Tomcat stops accepting new connections, finishes in-flight requests, then shuts down. (2) Message consumer shutdown: if using @KafkaListener or @RabbitListener, implement `SmartLifecycle` on the listener container factory with a phase lower than the web server. Consumers stop BEFORE the web server, preventing "received message but can't process because HTTP server is shutting down" scenarios.

(3) Scheduled task shutdown: `@Scheduled` methods use a `ThreadPoolTaskScheduler` that needs explicit shutdown configuration. Set `spring.task.scheduling.shutdown.await-termination=true` and `spring.task.scheduling.shutdown.await-termination-period=30s`. Without this, scheduled tasks may be interrupted mid-execution. (4) Connection pool drain: HikariCP closes connections on context close, but if a connection is in-use (in a transaction), it waits. Set `spring.datasource.hikari.max-lifetime=1800000` (30 min) to ensure connections are rotated before they become stale.

(5) JVM shutdown hook ordering: Spring registers a shutdown hook that calls `context.close()`. If your application registers its OWN shutdown hook (`Runtime.addShutdownHook`), there's no guaranteed ordering. Move custom cleanup into @PreDestroy methods or SmartLifecycle.stop() to ensure proper ordering.

_What separates good from great:_ Think about shutdown ORDER. "The correct shutdown sequence is: stop accepting work → finish in-progress work → flush outputs (metrics, logs) → close connections → exit. If you close connections before finishing work, in-progress transactions fail."

**Q10: How do you monitor and alert on memory health in a Spring Boot application?** [SENIOR]

Monitoring stack: (1) JVM metrics via Micrometer: `jvm_memory_used_bytes{area="heap"}` (total heap usage), `jvm_memory_used_bytes{area="nonheap"}` (Metaspace + code cache), `jvm_gc_pause_seconds` (GC duration), `jvm_gc_memory_promoted_bytes_total` (old gen growth rate). (2) Application metrics: `hikaricp_connections_active` (connection leaks), `spring_cache_size` (cache growth), `jvm_threads_live_threads` (thread leaks).

Alerts: (1) `jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes > 0.85 for 10m` → WARNING: heap consistently above 85%. (2) Rate of increase in old gen: `rate(jvm_gc_memory_promoted_bytes_total[1h]) > 10MB/min` → WARNING: leak suspected. (3) `jvm_gc_pause_seconds{cause="G1 Evacuation Pause"} > 500ms` → WARNING: GC pauses affecting latency. (4) `jvm_threads_live_threads > 500` → CRITICAL: likely thread leak.

For proactive detection: JFR continuous recording with 7-day retention. `-XX:StartFlightRecording=maxsize=500m,maxage=7d,settings=default`. When an alert fires, the JFR recording contains the complete history of allocations, GC events, and thread activity leading up to the issue. No need to reproduce.

Dashboard layout: heap usage over time (should be sawtooth, not climbing), GC pause distribution, old gen growth rate, thread count, connection pool usage, cache hit rate.

_What separates good from great:_ Alert on the RATE of growth, not just the threshold. "A heap at 80% that's been stable for a week is fine. A heap at 60% that grew from 40% in the last hour is a leak. Rate-based alerts catch leaks before they cause OOM."

**Q11: Tell me about a time you found and fixed a subtle memory leak in a Spring application.** [SENIOR]

We had a multi-tenant SaaS application where each request sets a `TenantContext` via ThreadLocal in a servlet filter. After 2 weeks in production, heap dumps showed millions of `TenantConfig` objects. Each was only 500 bytes, but at 50M requests/day, the accumulation was significant.

Investigation: (1) Eclipse MAT showed `TenantConfig` objects retained by `ThreadLocalMap$Entry` arrays. The ThreadLocal was being set but not always cleared. (2) The filter had a `finally { TenantContext.clear(); }` block, so it should have been cleaning up. (3) Deeper analysis: the filter was registered twice - once via `@Component` (Spring) and once via `@WebFilter` (Servlet). The Spring-registered filter cleared the ThreadLocal. The Servlet-registered filter also set the ThreadLocal but executed AFTER the Spring filter's finally block. So the cleanup happened, then the value was set again by the second registration.

Fix: (1) Removed the `@WebFilter` annotation (kept only the Spring `@Component` registration). (2) Added a safety net: `TenantContext.clear()` also in a `HandlerInterceptor.afterCompletion()` as a second cleanup point. (3) Added a unit test that verifies ThreadLocal is null after the filter chain completes. (4) Added monitoring: a scheduled task that counts ThreadLocalMap entries via reflection (hacky but effective for catching regressions).

_What separates good from great:_ The root cause wasn't "missing cleanup" - it was "duplicate filter registration." Show that you looked past the obvious fix to find the architectural issue. "The finally block was correct. The problem was the filter running twice, and the second execution happened after the first's cleanup."

**Q12: What is @DirtiesContext and when should you use it?** [MID]

`@DirtiesContext` tells Spring's test framework to close and discard the ApplicationContext after the annotated test class (or method) completes. By default, Spring caches contexts across tests to avoid the expense of creating a new one for each class.

When to use it: (1) A test modifies shared state (inserts data into an in-memory database, changes a bean's configuration) that would affect subsequent tests. (2) A test replaces or modifies beans that other tests depend on (e.g., changing a mock's behavior globally). (3) Memory pressure during the test suite - if the suite runs 500 tests and accumulates cached contexts, @DirtiesContext on some classes frees memory by closing their contexts.

When NOT to use it: (1) As a default on every test class. Context creation takes 3-10 seconds; adding that to every class makes the suite slow. (2) When the issue is really test isolation - a test that needs @DirtiesContext because it "dirties" the database should instead be using transactional rollback (`@Transactional` on the test, which rolls back after each test method). (3) When a shared `@TestConfiguration` could make all tests use the same clean context.

The trade-off: @DirtiesContext = correct results + slower tests. Context caching = faster tests + risk of test pollution. The best approach: design tests to NOT dirty the context (use transactional rollback, mock reset, etc.) and use @DirtiesContext only when unavoidable.

_What separates good from great:_ Know that `@DirtiesContext(classMode = AFTER_EACH_TEST_METHOD)` exists for when specific methods dirty the context but others don't. This is more granular than class-level @DirtiesContext and avoids penalizing clean methods.

---

### Related Keywords

**Prerequisites:** Bean Lifecycle, Bean Scopes,
ApplicationContext

**Builds on:** JVM memory management, garbage collection

**Leads to:** Spring Boot Production Anti-Patterns, startup
performance optimization

**Alternatives:** Micronaut compile-time DI (smaller context
footprint), manual resource management (no container)

---

---

# Spring Boot Production Anti-Patterns

**TL;DR** - The most damaging Spring Boot anti-patterns are:
treating Spring Boot defaults as production-ready, putting
business logic in controllers, holding transactions during
external calls, and using @Async without understanding its
thread pool and error semantics.

---

### The Problem This Solves

Spring Boot makes it easy to build applications quickly. Too
easy. Teams ship prototype-quality code to production because
"it works in dev." Then: connection pools exhaust under load,
@Async silently swallows exceptions, actuator endpoints leak
internal state to the internet, and configuration profiles
work backwards (production settings in application.yml, dev
overrides in profiles).

These aren't bugs - they're structural decisions that work at
small scale and break at production scale. Knowing the
anti-patterns before they bite you is the difference between a
smooth launch and a 3AM incident.

---

### Textbook Definition

Spring Boot production anti-patterns are recurring design and
configuration mistakes that appear to work during development
and testing but cause reliability, performance, security, or
maintainability failures under production conditions including
high traffic, concurrent access, partial failures, and hostile
actors.

---

### Understand It in 30 Seconds

**One line:** What works in dev often fails in production - know
the patterns that break under load, failure, or attack.

**Analogy:** Using Spring Boot defaults in production is like
driving a car with factory settings on a race track. The
factory settings are safe for normal roads but wrong for high
performance: wrong tire pressure, wrong gear ratios, wrong
fuel. You need to tune for your environment.

**Key insight:** Every anti-pattern exists because Spring Boot
chose the CONVENIENT default, not the SAFE default. Convenience
wins for getting started; safety wins for staying up.

---

### First Principles

Production anti-patterns violate these principles:

1. **Fail fast** - production systems should detect failures
   immediately, not hours later when symptoms accumulate
2. **Bound everything** - thread pools, connection pools,
   caches, queues must have limits or they grow until OOM
3. **Separate concerns** - controllers handle HTTP, services
   handle logic, repositories handle data; mixing creates
   untestable, unscalable code
4. **Explicit over implicit** - production config should be
   explicit, not rely on framework defaults that change between
   versions
5. **Defense in depth** - security at every layer, not just
   the front door

---

### Mental Model / Analogy

```
┌────────────────────────────────────┐
│  ANTI-PATTERN SEVERITY MATRIX      │
├────────────────────────────────────┤
│                                    │
│  HIGH IMPACT + COMMON:             │
│  ✗ Default thread pools            │
│  ✗ Tx during HTTP calls            │
│  ✗ Exposed actuator endpoints      │
│  ✗ No connection pool tuning       │
│                                    │
│  HIGH IMPACT + SUBTLE:             │
│  ✗ @Async exception swallowing     │
│  ✗ Circular dependencies           │
│  ✗ N+1 queries in JPA              │
│  ✗ @Transactional on reads         │
│                                    │
│  MEDIUM IMPACT + WIDESPREAD:       │
│  ✗ Fat controllers                 │
│  ✗ Catch-all exception handlers    │
│  ✗ Ignoring startup time           │
│  ✗ Missing health checks           │
│                                    │
└────────────────────────────────────┘
```

---

### How It Works - Five Levels

**Level 1 (Anyone):** Some common ways of writing Spring Boot
apps work fine in development but cause problems in production.
Learning these patterns early prevents production incidents.

**Level 2 (Junior):** The most visible anti-patterns:
(1) Fat controllers - business logic in @Controller methods
instead of @Service classes. (2) No error handling - letting
Spring's default white-label error page expose stack traces.
(3) Using H2 in production - in-memory database is only for
testing. (4) Hardcoded configuration - URLs, credentials, and
feature flags in source code instead of externalized config.

**Level 3 (Mid):** Architectural anti-patterns:
(1) Holding database transactions during external HTTP calls.
The @Transactional method calls a REST API, which takes 2
seconds. The database connection is held idle for 2 seconds,
and under load, the connection pool exhausts.
(2) Using @Async with default thread pool (no size limit).
Under load, the default SimpleAsyncTaskExecutor creates a new
thread per call with no bounds, eventually crashing the JVM.
(3) Missing `@Transactional(readOnly = true)` on read
operations. This wastes connection routing opportunities and
prevents Hibernate's dirty-check optimization.
(4) Catching generic Exception everywhere and logging
"something went wrong" without context.

**Level 4 (Senior/Staff):** Production-specific anti-patterns:
(1) Actuator exposed on the public port without security.
`/actuator/env` reveals all config including database URLs;
`/actuator/heapdump` downloads the JVM heap (with secrets in
memory). Fix: separate management port with network-level
access control. (2) Spring Security defaults for APIs: CSRF
enabled (breaks SPA POST requests), session creation ALWAYS
(stateful when JWT should be stateless), permissive CORS.
(3) @Scheduled tasks without distributed locking: in a 5-pod
deployment, the same cron job runs 5 times simultaneously.
Use ShedLock or a database advisory lock. (4) Ignoring Spring
Boot's autoconfiguration report (`--debug`): unnecessary
auto-configurations add startup time and memory overhead. A
service that doesn't use JPA shouldn't have Hibernate on the
classpath.

**Level 5 (Distinguished):** The meta-anti-pattern is treating
Spring Boot as a black box. Teams that don't understand what
auto-configuration creates, what beans exist, and what defaults
are active will be surprised in production. The antidote:
mandate that every team reviews the auto-configuration report
(`--debug`) before the first production deploy. If you can't
explain why each auto-configuration matched, you don't
understand your own application.

---

### How It Works - Mechanism

**Anti-pattern detection checklist:**

```
□ Connection pool sized?
  Default: HikariCP 10 connections
  Production: size = core_count * 2 + spindle
  (typically 20-50 depending on workload)

□ Thread pool bounded?
  @Async default: unbounded!
  Production: ThreadPoolTaskExecutor
  with core=10, max=50, queue=100

□ Actuator secured?
  Default: all endpoints exposed
  Production: management.server.port=9090
  + network policy restricting access

□ Transactions scoped?
  Anti-pattern: @Transactional on controller
  Production: @Transactional on service,
  read-only where applicable

□ Error handling explicit?
  Anti-pattern: default whitelabel page
  Production: @ControllerAdvice with
  structured error responses

□ Profiles correct?
  Anti-pattern: prod config in application.yml
  Production: dev defaults in application.yml,
  prod overrides in application-prod.yml
```

---

### Code Example

```java
// BAD: Every common anti-pattern in one service
@RestController
@Transactional  // On controller! Holds tx for
                // entire request including HTTP call
public class OrderController {

    @Autowired  // Field injection (untestable)
    private OrderRepository repo;

    @PostMapping("/orders")
    public Order create(@RequestBody Order order) {
        // Business logic in controller
        if (order.getTotal().compareTo(
            BigDecimal.valueOf(10000)) > 0) {
            // Call external fraud check INSIDE tx
            // Holds DB connection during HTTP call
            restTemplate.postForObject(
                "http://fraud-service/check",
                order, FraudResult.class);
        }
        return repo.save(order);
    }

    @GetMapping("/orders")
    public List<Order> getAll() {
        return repo.findAll(); // No readOnly
        // Also: returns entities directly
        // (exposes DB schema as API contract)
    }

    @Async  // Uses default unbounded thread pool
    public void sendNotification(Order order) {
        // If this throws, exception is LOST
        emailService.send(order.getEmail(), "...");
    }
}

// GOOD: Production-ready structure
@RestController
@RequiredArgsConstructor  // Constructor injection
public class OrderController {
    private final OrderService orderService;

    @PostMapping("/orders")
    public ResponseEntity<OrderDto> create(
        @Valid @RequestBody CreateOrderRequest req
    ) {
        OrderDto result =
            orderService.createOrder(req);
        return ResponseEntity
            .created(URI.create(
                "/orders/" + result.id()))
            .body(result);
    }
}

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository repo;
    private final FraudCheckClient fraudClient;
    private final NotificationService notifier;

    public OrderDto createOrder(
        CreateOrderRequest req) {
        // Fraud check OUTSIDE transaction
        if (req.total().compareTo(
            BigDecimal.valueOf(10000)) > 0) {
            fraudClient.check(req);
        }
        // Transaction only around DB writes
        Order saved = saveOrder(req);
        // Notification after commit
        notifier.orderCreated(saved);
        return OrderDto.from(saved);
    }

    @Transactional
    protected Order saveOrder(
        CreateOrderRequest req) {
        return repo.save(Order.from(req));
    }
}
```

---

### Quick Reference Card

| Field           | Value                                       |
| --------------- | ------------------------------------------- |
| Category        | Production Readiness                        |
| Pool default    | HikariCP: 10 connections (often too low)    |
| Async default   | SimpleAsyncTaskExecutor (unbounded!)        |
| Actuator risk   | `/env`, `/heapdump` expose secrets          |
| CSRF default    | Enabled (breaks SPA API calls)              |
| Session default | IF_REQUIRED (creates sessions unexpectedly) |
| Error default   | Whitelabel page (exposes internals)         |
| Profile pitfall | Prod config in base application.yml         |

**3 things to remember:**

1. Configure thread pools, connection pools explicitly - defaults are for dev
2. Never hold a @Transactional during external HTTP calls
3. Secure actuator on a separate management port

**One-liner:** "Spring Boot defaults are optimized for getting
started, not for staying up. Production requires explicit
configuration of everything that has a default."

---

### Mastery Checklist

- [ ] AUDIT: Review a service for all anti-patterns listed
      above using the detection checklist
- [ ] CONFIGURE: Set up production-ready HikariCP, async
      thread pool, and actuator security
- [ ] REFACTOR: Extract business logic from controllers to
      services with proper transaction scoping
- [ ] MONITOR: Set alerts for connection pool exhaustion,
      thread count growth, and GC pauses
- [ ] TEACH: Create a team checklist for production readiness
      review before every service launch

---

### Surprising Truth

Spring Boot's `SimpleAsyncTaskExecutor` (the default for
@Async) doesn't even reuse threads. Every @Async call creates
a BRAND NEW thread. At 1000 requests/second, that's 1000
threads created per second. The JVM will eventually throw
`OutOfMemoryError: unable to create new native thread`. This
isn't a bug - it's documented behavior. Spring chose the
simplest possible executor as the default, assuming you'd
configure a proper `ThreadPoolTaskExecutor` for production.
Most teams don't.

---

### Common Misconceptions

| #   | Misconception                                  | Reality                                                                       | Why It Matters                                                     |
| --- | ---------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1   | Spring Boot defaults are production-ready      | Defaults are optimized for development convenience, not production safety     | Every default should be reviewed before production deploy          |
| 2   | @Async is fire-and-forget without consequences | Unhandled async exceptions are silently lost; no bounded thread pool          | Configure AsyncUncaughtExceptionHandler and ThreadPoolTaskExecutor |
| 3   | @Transactional is cheap                        | Each transaction holds a DB connection; wide transactions exhaust pools       | Scope transactions as narrowly as possible                         |
| 4   | More connection pool = more throughput         | Beyond optimal size (2 \* cores + spindle), connections contend and slow down | Profile to find the optimal pool size for your workload            |

---

### Failure Modes and Diagnosis

| Failure Mode               | Symptom                                     | Diagnostic Command                                 | Fix                                                        |
| -------------------------- | ------------------------------------------- | -------------------------------------------------- | ---------------------------------------------------------- |
| Connection pool exhaustion | HikariPool timeout; requests queue          | `hikaricp_connections_pending` metric > 0          | Reduce tx scope; remove HTTP calls from tx; tune pool size |
| Async thread explosion     | OOM: unable to create native thread         | `jvm_threads_live_threads` metric growing linearly | Configure ThreadPoolTaskExecutor with bounded max          |
| Actuator data leak         | Sensitive config visible on public endpoint | `curl /actuator/env` returns secrets               | Move actuator to management port; restrict network access  |
| Scheduled job duplication  | Same cron job runs N times (N = pod count)  | Check DB for duplicate records per schedule        | Use ShedLock or database advisory locking                  |

---

### Interview Deep-Dive

**Timing Table:**

| Question | Type         | Difficulty | Time |
| -------- | ------------ | ---------- | ---- |
| Q1       | CONCEPTUAL   | MID        | 90s  |
| Q2       | DEBUGGING    | SENIOR     | 120s |
| Q3       | PRODUCTION   | SENIOR     | 120s |
| Q4       | TRADE-OFF    | STAFF      | 150s |
| Q5       | DEBUGGING    | SENIOR     | 120s |
| Q6       | HANDS-ON     | MID        | 90s  |
| Q7       | ARCHITECTURE | STAFF      | 150s |
| Q8       | PRODUCTION   | SENIOR     | 120s |
| Q9       | TRADE-OFF    | SENIOR     | 120s |
| Q10      | DEBUGGING    | SENIOR     | 120s |
| Q11      | BEHAVIORAL   | SENIOR     | 120s |
| Q12      | CONCEPTUAL   | MID        | 90s  |

**Q1: What's wrong with putting @Transactional on a controller method?** [MID]

Two fundamental problems: (1) Transaction scope is too wide. The controller handles HTTP deserialization, validation, response building - none of which need a database transaction. The transaction (and its held connection) spans the entire request processing, not just the database operations. If the controller calls an external HTTP service, the transaction holds a database connection idle during the entire network call. At 100 concurrent requests with 2-second external calls, that's 100 connections held idle for 2 seconds - your pool of 20 connections is exhausted, and requests queue.

(2) Architectural violation. Controllers should handle HTTP concerns (routing, input format, response status codes). Services should handle business logic and transaction boundaries. Mixing them creates untestable code - you can't test business logic without simulating HTTP. And you can't change the transaction boundary without modifying the controller.

The correct pattern: controller calls service, service is @Transactional. If the service needs to call an external API and then write to the database, the external call should be OUTSIDE the transaction: `externalResult = httpClient.call(); transactionalService.saveWithResult(externalResult);`.

_What separates good from great:_ Quantify the impact. "With 20 pool connections and 100 concurrent requests holding connections for 2 seconds each, the average wait time is (100/20) \* 2s = 10 seconds per request. Moving @Transactional to the service and reducing connection hold time to 50ms means 20 connections can serve 400 requests/second."

**Q2: A service works fine at 10 requests/second but becomes unresponsive at 100 rps. No errors in logs. What do you look for?** [SENIOR]

No errors + unresponsive = resource exhaustion (not code bugs). Systematic diagnosis: (1) Check thread dumps: `jstack PID` or Actuator `/threaddump`. If most threads are TIMED_WAITING on `HikariPool.getConnection()`, the connection pool is exhausted. If threads are WAITING on a synchronized block, there's lock contention. If threads are RUNNABLE in CPU-intensive code, it's a CPU bottleneck. (2) Check connection pool metrics: `hikaricp_connections_active` = 10 (max), `hikaricp_connections_pending` = 90. The pool is saturated. (3) Find why connections are held so long: enable HikariCP leak detection (`leak-detection-threshold=5000`). This logs a stack trace when a connection is held >5 seconds. Common cause: @Transactional method calling an external service.

(4) Check thread pool sizing: is Tomcat's thread pool large enough? Default is 200, but if each request holds a connection for 1 second and the connection pool is 10, only 10 requests can be active simultaneously. The remaining 90 threads are waiting for connections. Fix: either increase pool size (to match concurrent load) or reduce connection hold time (narrow the transaction scope).

(5) Check for serial bottlenecks: synchronized methods, single-threaded executors, or Redis commands on a single connection can serialize requests even though you have plenty of threads.

_What separates good from great:_ Correlate the metrics. "200 Tomcat threads, 10 HikariCP connections, 100 rps with 100ms per DB operation = max 100 requests/second from the pool. The math says this exact load saturates the pool. It's not a bug - it's under-provisioned."

**Q3: How do you configure @Async properly for production?** [SENIOR]

Step-by-step production @Async configuration: (1) Define a bounded ThreadPoolTaskExecutor:

```java
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean("taskExecutor")
    public TaskExecutor taskExecutor() {
        var executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(50);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("async-");
        executor.setRejectionPolicy(
            new CallerRunsPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(
            true);
        executor.setAwaitTerminationSeconds(30);
        return executor;
    }
}
```

Key decisions: `corePoolSize` = threads always alive (match baseline load). `maxPoolSize` = threads under peak load. `queueCapacity` = buffer between core and max (when queue fills, new threads up to max are created). `CallerRunsPolicy` = when everything is full, the calling thread runs the task (provides backpressure instead of throwing). `waitForTasksToComplete` = graceful shutdown finishes in-flight tasks.

(2) Handle exceptions: implement `AsyncUncaughtExceptionHandler`:

```java
@Override
public AsyncUncaughtExceptionHandler
    getAsyncUncaughtExceptionHandler() {
    return (ex, method, params) ->
        log.error("Async failed: {} - {}",
            method.getName(), ex.getMessage(), ex);
}
```

Without this, exceptions from void @Async methods are silently lost. For Future-returning @Async methods, the caller must call `.get()` to see exceptions.

(3) Monitor: expose executor metrics via Micrometer: `executor_pool_size_threads`, `executor_active_threads`, `executor_queue_remaining`. Alert when queue remaining < 10 (near capacity).

_What separates good from great:_ Explain CallerRunsPolicy as backpressure. "When the pool and queue are full, CallerRunsPolicy runs the task on the HTTP thread. This slows down the incoming request, which naturally reduces load. It's elegant backpressure without losing the task."

**Q4: What's the production-ready configuration checklist for a Spring Boot service before its first deploy?** [STAFF]

Critical configuration checklist:

**Infrastructure:** (1) Connection pool: `hikari.maximum-pool-size` calculated (2 \* CPU cores + spindle count), `connection-timeout=5000` (fail fast), `leak-detection-threshold=30000`. (2) Thread pools: Tomcat `server.tomcat.threads.max=200` (default is fine for most), @Async with bounded ThreadPoolTaskExecutor. (3) JVM: `-Xms` = `-Xmx` (pre-allocate heap, avoid resize pauses), `-XX:+UseG1GC` (default since Java 9), `-XX:+HeapDumpOnOutOfMemoryError`.

**Security:** (1) Actuator on management port: `management.server.port=9090`. Only `/health` on main port. (2) CSRF disabled for APIs, enabled for web UIs. CORS explicitly configured. (3) Spring Security with JWT/OAuth2 for APIs, session for server-rendered UIs. (4) Dependency vulnerability scan in CI (OWASP dependency-check).

**Observability:** (1) Structured JSON logging (not plain text). (2) Micrometer metrics to Prometheus: HTTP latency, JVM memory, GC pauses, connection pool, custom business metrics. (3) Distributed tracing (Micrometer Tracing → Zipkin/Jaeger). (4) Health checks: `/health/liveness` and `/health/readiness` for Kubernetes.

**Reliability:** (1) Graceful shutdown: `server.shutdown=graceful`. (2) Circuit breakers for external dependencies (Resilience4j). (3) Retry policies with exponential backoff for transient failures. (4) Database migrations via Flyway/Liquibase (not JPA auto-DDL). (5) Scheduled jobs with ShedLock for multi-instance safety.

_What separates good from great:_ Present it as a pre-flight checklist, not a wishlist. "I run this checklist for every new service. Items that fail block deployment. Items that are N/A get documented as N/A with reason. Nothing ships without review."

**Q5: @Async methods silently swallow exceptions. A developer lost data because of this. How did it happen and how do you fix it?** [SENIOR]

What happened: a @Async method processes an order fulfillment step. The method throws a NullPointerException due to bad input data. Since the method returns `void`, the exception is logged by Spring's SimpleAsyncUncaughtExceptionHandler (which just logs at ERROR) and the thread returns to the pool. The calling code continues as if fulfillment succeeded because @Async immediately returns. The order shows as "CONFIRMED" but fulfillment never happened. Nobody notices until the customer complains.

Root cause: @Async with void return type has no way to propagate exceptions to the caller. The caller gets a void return (or no return) immediately. The exception happens on a different thread, potentially minutes later.

Fix (multiple layers): (1) Return `CompletableFuture<Void>` instead of void. The caller can `.exceptionally()` or `.get()` to handle failures. (2) Implement `AsyncUncaughtExceptionHandler` that writes failures to a dead-letter queue or database table for later investigation. (3) Don't use @Async for critical business operations. Use a reliable messaging system (Kafka, RabbitMQ) with acknowledgment semantics - the message is only acknowledged when processing completes successfully. (4) For this specific case: use the transactional outbox pattern - write a "fulfillment needed" record in the same transaction as the order, and process it reliably via a poller.

_What separates good from great:_ Distinguish between "@Async for fire-and-forget notifications" (acceptable) and "@Async for critical business operations" (anti-pattern). "The rule: if losing this task means data inconsistency, don't use @Async. Use a message queue with guaranteed delivery."

**Q6: Write a production-ready health check for a Spring Boot application.** [MID]

```java
@Component
public class DownstreamHealthIndicator
    implements HealthIndicator {

    private final WebClient paymentClient;
    private final Duration timeout =
        Duration.ofSeconds(2);

    @Override
    public Health health() {
        try {
            String status = paymentClient
                .get()
                .uri("/health")
                .retrieve()
                .bodyToMono(String.class)
                .block(timeout);

            return Health.up()
                .withDetail("paymentService", "OK")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("paymentService",
                    e.getMessage())
                .build();
        }
    }
}
```

```yaml
# application-prod.yml
management:
  endpoint:
    health:
      show-details: when-authorized
      group:
        liveness:
          include: livenessState
        readiness:
          include:
            - readinessState
            - db
            - downstream
  endpoints:
    web:
      exposure:
        include: health,metrics,info
  server:
    port: 9090
```

Key decisions: (1) Separate liveness from readiness - liveness should ONLY check "is the process alive?" (almost always up). Readiness checks actual dependencies (DB, downstream services). A failing readiness removes the pod from the load balancer without restarting it. (2) Timeout on health checks - a slow dependency shouldn't make the health check slow. (3) `show-details: when-authorized` hides internal details from unauthorized callers.

_What separates good from great:_ Know the K8s implications. "A liveness check that includes DB connectivity causes pod restarts during database maintenance. Liveness should be trivial; readiness should check dependencies. Mixing them causes cascading restarts."

**Q7: Design a production-hardening strategy for an organization transitioning from "it works in dev" to production-grade Spring Boot services.** [STAFF]

Organizational strategy with technical enforcement: (1) Create a "production-ready" Spring Boot starter that teams inherit. This starter auto-configures: bounded thread pools, connection pool sizing based on instance size, structured logging, Micrometer metrics exporter, Actuator on management port, standard error handling. Teams get production defaults by adding one dependency. (2) Build a CI pipeline gate: a "production readiness" scan that checks: are Actuator endpoints secured? Is the connection pool explicitly configured? Does the service have health checks? Are there integration tests? Is there a Dockerfile? Services that fail the gate can't deploy to production.

(3) Create ArchUnit rules that fail the build on anti-patterns: no @Transactional on @Controller classes, no field injection (@Autowired on fields), no @Async without explicit executor name, no `@Scheduled` without ShedLock annotation. (4) Run chaos testing in staging: randomly kill pods, inject network latency to databases, reject random HTTP calls. Services that break get "hardening" sprints. (5) Publish a "production readiness review" template: a 30-item checklist that every service must complete before its first production deploy, signed off by a Staff+ engineer.

Progress tracking: dashboard showing each team's services and their production-readiness score. Monthly review in engineering all-hands. Teams with consistently low scores get platform engineering support.

_What separates good from great:_ Frame it as a platform problem, not an education problem. "I don't teach 200 developers to configure HikariCP correctly. I build a starter that configures it correctly by default. The best anti-pattern prevention is making the right thing the easy thing."

**Q8: How do you handle N+1 query problems in Spring Data JPA?** [SENIOR]

N+1 is the most common JPA performance anti-pattern: loading a parent entity, then lazily loading each child collection individually. A `findAll()` on 100 orders, each with 5 items, generates 1 + 100 = 101 queries instead of 1-2.

Detection: (1) Enable Hibernate statistics: `spring.jpa.properties.hibernate.generate_statistics=true`. Check `queryExecutionCount` - if it's 101 for a list page, you have N+1. (2) Use P6Spy or datasource-proxy to log ALL SQL with timing. Sort by frequency to find the N+1 pattern. (3) Spring Boot Actuator `/metrics` with Hibernate stats exposed via Micrometer.

Fixes (from least to most invasive): (1) `@EntityGraph` on the repository method: `@EntityGraph(attributePaths = {"items"}) List<Order> findAll()`. Generates a single LEFT JOIN query. (2) `JOIN FETCH` in JPQL: `SELECT o FROM Order o JOIN FETCH o.items`. Same result, more explicit. (3) `@BatchSize(size = 50)` on the collection: instead of 1 query per order, loads items in batches of 50 (1 + 2 queries for 100 orders). Less optimal than join fetch but works without changing every query. (4) DTO projections: `SELECT new OrderDto(o.id, o.total) FROM Order o`. Don't load entities at all - load only the fields you need. No lazy loading, no N+1 possibility.

My recommendation: use DTO projections for read operations (no N+1, no managed entities, smaller memory footprint). Use entity graphs for write operations where you need the full entity graph. Never rely on default lazy loading for list endpoints.

_What separates good from great:_ Know that @EntityGraph with multiple collections generates a Cartesian product (100 orders x 5 items x 3 addresses = 1500 rows instead of 100). For multiple collections, use `@BatchSize` or multiple queries instead.

**Q9: Compare using default Spring Boot configuration vs explicit production configuration. What should always be explicit?** [SENIOR]

Always explicit (never rely on defaults): (1) Connection pool size: default 10 is wrong for almost every production workload. Calculate based on: `pool_size = (core_count * 2) + effective_spindle_count`. For a 4-core server with SSD: ~10-12. For high-throughput: 20-30. (2) Thread pool sizes: Tomcat max threads, @Async executor, @Scheduled pool. Each should be sized for expected load. (3) Timeouts: HTTP client timeouts (connect, read, write), database connection timeout, Redis timeout. Zero or infinite defaults mean hung requests never die. (4) Logging format: default single-line logging is unstructured. Production needs JSON with correlation IDs for log aggregation. (5) Security: session management strategy (STATELESS for APIs), CSRF policy, CORS origins. Defaults are for server-rendered apps.

Okay to leave as default: (1) Embedded server choice (Tomcat is fine). (2) Jackson serialization settings (unless you need custom date format). (3) Static resource locations (if not serving static content). (4) Banner display (cosmetic). (5) JMX autoconfig (unless you're monitoring via JMX).

The principle: if a default being wrong would cause an INCIDENT (data loss, security breach, outage), it must be explicit. If it would cause a minor inconvenience, the default is fine.

_What separates good from great:_ Mention that you document WHY each explicit value was chosen. "I don't just set `maximum-pool-size=20`. I add a comment: `# Based on 4 cores, SSD, 100ms avg query time, 200 req/s target`. When someone inherits the service, they know the reasoning."

**Q10: Your team has Spring Boot services that crash with OutOfMemoryError under load. The same service works fine at low traffic. Systematic diagnosis?** [SENIOR]

OOM under load but not at rest = request-correlated memory consumption. Diagnosis: (1) Check if it's heap or non-heap (thread stacks/Metaspace). `java.lang.OutOfMemoryError: Java heap space` = objects. `unable to create new native thread` = threads. `Metaspace` = classes/proxies. (2) For heap OOM under load: enable heap-dump-on-OOM, reproduce with a load test, analyze the dump. Common findings: large request/response bodies buffered in memory (Jackson deserializing a 100MB JSON array into memory), unsized caches growing with each unique request, or per-request objects not being released due to ThreadLocal leaks.

(3) For thread OOM: check `jvm_threads_live_threads` under load. If it grows linearly with requests, something is creating threads (likely SimpleAsyncTaskExecutor or unbounded scheduled tasks). Fix: bounded thread pools. (4) For specific anti-patterns: @Async with default executor (new thread per call), `@RequestBody` with no size limit (attacker sends 1GB JSON body and OOM's the server - configure `spring.servlet.multipart.max-request-size` and `server.tomcat.max-http-form-post-size`), or streaming response using `List<Entity>` instead of `Stream<Entity>` (loads entire result set into heap).

Quick fix while investigating: `-XX:+UseG1GC -XX:MaxGCPauseMillis=200` for better GC behavior under pressure, and configure Tomcat's max-connections and max-threads to reject excess traffic rather than OOM.

_What separates good from great:_ Check for adversarial inputs. "OOM under load might be a DoS attack. A single request with a 500MB JSON body can OOM the service. Always set `server.tomcat.max-http-form-post-size` and request body limits."

**Q11: Tell me about a time you implemented a production-readiness review process for Spring Boot services.** [SENIOR]

At a previous company, we had 30+ Spring Boot services and regular production incidents traced to configuration anti-patterns: exposed actuator endpoints, default connection pools, missing health checks. Each incident was a different team making the same mistake.

Approach: (1) I collected the top 10 incident root causes from the last 6 months. All were configuration issues, not code bugs. (2) Created a "production readiness checklist" - 25 items across infrastructure (pools, timeouts), security (actuator, CORS, auth), observability (metrics, logs, tracing), and reliability (health checks, graceful shutdown, retry policies). (3) Built an automated scanner: a Spring Boot test that runs against the deployed service and checks: is actuator accessible on the main port? Is the connection pool explicitly configured? Does `/health` respond correctly? This test ran in the CI pipeline as a gate.

(4) Created a company-internal Spring Boot starter (`company-spring-boot-starter`) that auto-configured all the "boring but critical" stuff: structured logging, Micrometer exporter, bounded async executor, connection pool defaults based on instance size. Teams that used this starter passed 20 of 25 checks automatically.

Results: incidents from configuration issues dropped 85% in the first quarter. New services reached production readiness in hours instead of weeks. The remaining incidents were all from services that didn't use the company starter.

_What separates good from great:_ Show the metrics. "I tracked incidents-per-service-per-month before and after. The data convinced management to mandate the company starter for all new services."

**Q12: What is the "fat controller" anti-pattern and why is it particularly dangerous in Spring?** [MID]

A "fat controller" is a @Controller or @RestController that contains business logic, data access, validation, transformation, and HTTP concern handling all in one method. It violates single responsibility and creates cascading problems.

Why it's dangerous in Spring specifically: (1) Transaction boundaries become invisible. If the controller is @Transactional, the transaction spans everything including response serialization. If it's NOT @Transactional, database operations run without atomicity. Either way is wrong. (2) Testing requires HTTP simulation. Business logic buried in a controller can only be tested via MockMvc or @SpringBootTest - slow, heavy tests. A service class can be unit tested with simple mocks in milliseconds. (3) AOP doesn't apply as expected. @Cacheable, @Retryable, @Async on controller methods may not work as expected because controller proxying behaves differently (sometimes JDK proxy, sometimes CGLIB). (4) Reusability is zero. If the same business logic is needed from a message consumer or a scheduled job, it can't be reused because it's in a controller method that expects HttpServletRequest.

The refactoring path: extract a method → make it a @Service → inject the service into the controller. The controller should be 3-5 lines: validate input, call service, return response. This is the "thin controller" pattern.

_What separates good from great:_ Mention the testability impact quantitatively. "A fat controller test takes 3 seconds (Spring context + MockMvc). The same logic in a service takes 10ms (plain JUnit + mocks). With 500 tests, that's 25 minutes vs 5 seconds."

---

### Related Keywords

**Prerequisites:** What a Spring Application Looks Like, Spring
Boot Project Structure and Conventions

**Builds on:** All production keyword content in this file

**Leads to:** Architecture decisions (Spring - Architecture
and Strategy)

**Alternatives:** Framework-specific best practices guides
(Quarkus, Micronaut - each has its own anti-patterns)
