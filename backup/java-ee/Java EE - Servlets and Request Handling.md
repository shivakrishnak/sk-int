---
layout: default
title: "Java EE - Servlets and Request Handling"
parent: "Java EE"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/java-ee/servlets-and-request-handling/
topic: Java EE
subtopic: Servlets and Request Handling
keywords:
  - Application Servers and Servlet Containers
  - Servlet Lifecycle and Threading Model
  - Filters and Filter Chains
  - Listeners and Servlet Context
  - Request Dispatching and Forwarding
difficulty_range: medium
status: complete
version: 3
---

# Application Servers and Servlet Containers

**TL;DR** - Servlet containers (Tomcat, Jetty) implement only the Servlet/JSP specs while full application servers (WildFly, GlassFish) implement the entire Java EE specification - choosing the right one determines your operational complexity, memory footprint, and available APIs.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You have compiled servlets and JSPs but nowhere to run them. Java SE has no built-in HTTP server that understands the Servlet spec. You would need to write your own HTTP parser, thread pool, classloader, URL mapper, and session manager - essentially building a servlet container from scratch.

**THE BREAKING POINT:**
Teams using custom-built HTTP handling in Java SE discovered they were spending more time on infrastructure than business logic. Each team's implementation had different thread pool behavior, different session timeout semantics, different security models. A bug in one team's HTTP parser was a security vulnerability.

**THE INVENTION MOMENT:**
Standardized servlet containers (Tomcat, 1999) implemented the Servlet spec and nothing more. Full application servers (JBoss, WebLogic, 2000s) implemented the complete Java EE spec. The choice between them defined your project's capability and operational complexity.

**EVOLUTION:**
Apache JServ (1998) -> Tomcat 3.x (first RI, 1999) -> Tomcat 5/6 (Servlet 2.4/2.5) -> Tomcat 7 (Servlet 3.0, async) -> Tomcat 9 (Servlet 4.0, HTTP/2) -> Tomcat 10 (Jakarta namespace) -> Tomcat 11 (Jakarta EE 11, 2024). Full servers: JBoss AS -> WildFly, Sun Java AS -> GlassFish, IBM WebSphere -> Open Liberty.

---

### 📘 Textbook Definition

A servlet container is a runtime component that implements the Servlet and JSP specifications, providing HTTP connection handling, thread pool management, URL mapping, classloader isolation, and the servlet lifecycle contract. A full application server extends this with implementations of EJB, JMS, JTA, JCA, JAAS, and other Java EE specifications. Tomcat and Jetty are servlet containers (web profile). WildFly, GlassFish, and Open Liberty are full application servers (full profile). The distinction determines available APIs and operational characteristics. Spring Boot's embedded server model bundles a servlet container (usually Tomcat) inside the application JAR, inverting the traditional deployment model.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Tomcat runs servlets; WildFly runs servlets plus everything else in Java EE.

**One analogy:**

> A food truck (Tomcat) vs a full restaurant (WildFly). The food truck serves burgers and fries (Servlets, JSP) efficiently with minimal overhead. The restaurant has a full menu (EJB, JMS, JTA), a bar, valet parking, and a function room - but costs more to operate and takes longer to open each morning (startup time). Most customers just want a burger.

**One insight:**
In 2024+, the choice is usually: Tomcat (embedded in Spring Boot) for everything except legacy EJB applications. The full-server vs container distinction matters mainly for understanding legacy systems and making informed migration decisions.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Every application server IS a servlet container plus additional services - the servlet container is the core of every Java web server
2. The more specs a server implements, the more memory and startup time it consumes - complexity has a runtime cost
3. Server configuration (thread pools, datasources, security realms) is server-specific even though the APIs are standard - portability ends at configuration

**DERIVED DESIGN:**
From invariant 1: if you only need Servlets/JPA, Tomcat plus Hibernate bundled in your WAR gives you everything a full server would, with less overhead. From invariant 2: a WildFly instance running a simple REST API wastes 200MB of memory on unused EJB, JMS, and JCA subsystems. From invariant 3: "portable" Java EE applications require server-specific deployment scripts in practice.

**THE TRADE-OFFS:**

**Gain (full server):** All Java EE APIs available out of the box, managed resources (datasources, JMS queues) configured at the server level, clustering and failover built in

**Cost (full server):** 500MB+ memory footprint, 15-30 second startup, complex administration, vendor-specific configuration

**Gain (servlet container):** 50-100MB footprint, 2-5 second startup, simple ops, bundle-what-you-need model

**Cost (servlet container):** Must bundle JPA, connection pooling, etc. yourself; no server-managed resources

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** HTTP handling, thread management, classloader isolation, and lifecycle management are required regardless of server type

**Accidental:** The distinction between "container" and "server" is a spec-governance artifact. In practice, Tomcat + bundled libraries gives you everything WildFly does for 95% of applications.

---

### 🧠 Mental Model / Analogy

> A Swiss Army knife (full app server) vs a chef's knife (servlet container). The Swiss Army knife has 30 tools - bottle opener, saw, screwdriver, blade. The chef's knife has one blade, perfectly balanced. For 90% of cooking tasks, the chef's knife is faster and more precise. You only reach for the Swiss Army knife when you genuinely need the corkscrew (EJB remoting) or the saw (JMS).

- "Chef's knife" -> Tomcat/Jetty (one thing done well)
- "Swiss Army knife" -> WildFly/GlassFish (everything included)
- "The blade" -> Servlet engine (present in both)
- "The corkscrew" -> EJB container (only in full servers)
- "The saw" -> JMS broker (only in full servers)

Where this analogy breaks down: unlike a Swiss Army knife where unused tools add zero overhead, a full application server's unused subsystems still consume memory, startup time, and attack surface.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A servlet container is the software that runs your Java web application. Tomcat is the most popular - it is free, lightweight, and handles web requests. WildFly is a bigger server that can do more (messaging, distributed transactions) but is heavier to run.

**Level 2 - How to use it (junior developer):**
For most new projects: use Spring Boot with embedded Tomcat. You do not install a server separately. `java -jar app.jar` starts Tomcat inside your application.

For traditional deployment: install Tomcat, copy your WAR to `webapps/`, Tomcat auto-deploys it. Configure `server.xml` for ports and thread pools, `context.xml` for datasources.

For legacy Java EE: install WildFly, deploy your EAR/WAR via the admin console or CLI. Configure `standalone.xml` for subsystems.

**Level 3 - How it works (mid-level engineer):**

| Feature    | Tomcat 10   | Jetty 12      | WildFly 30     | Open Liberty |
| ---------- | ----------- | ------------- | -------------- | ------------ |
| Profile    | Web         | Web           | Full           | Full         |
| Startup    | 2-4s        | 1-3s          | 10-25s         | 5-15s        |
| Memory     | 50-150MB    | 40-120MB      | 200-500MB      | 100-300MB    |
| EJB        | No          | No            | Yes            | Yes          |
| JMS        | No          | No            | Yes (ActiveMQ) | Yes          |
| Clustering | Via mod_jk  | Via Hazelcast | Built-in       | Built-in     |
| Admin UI   | Manager app | None (API)    | Full console   | Full console |

Tomcat's architecture: Connector (accepts HTTP) -> Engine -> Host -> Context (your WAR) -> Wrapper (individual servlets). Each WAR gets its own classloader. Thread pool shared across all WARs.

**Level 4 - Production mastery (senior/staff engineer):**
In production, server choice affects operational patterns:

**Tomcat:** Operations teams configure `server.xml` for thread pools (`maxThreads`, `acceptCount`, `connectionTimeout`), `context.xml` for JNDI datasources, and `catalina.properties` for classloader behavior. Monitoring via JMX (MBeans for thread pool, sessions, request processing). Health checks against `/manager/status` (if Manager app is enabled). Log rotation in `catalina.out`. The biggest production issue is Tomcat's default access log format not including response time - add `%D` to the access log pattern.

**WildFly:** Operations teams configure via `standalone.xml` or CLI (`jboss-cli.sh`). Subsystem-based architecture means unused subsystems can be removed to reduce footprint. Clustering via JGroups. Domain mode for managing multiple server instances. The biggest production issue is classloader complexity with JBoss Modules - dependencies between modules must be explicitly declared.

**Spring Boot embedded:** No server configuration files. All configuration in `application.yml`. Server properties prefixed `server.tomcat.*`. Simplest operational model but requires application redeployment for server tuning changes.

**The Senior-to-Staff Leap (what separates them):**

**A Senior says:** "Use Tomcat for web apps, WildFly if you need EJB."

**A Staff says:** "The server choice is an operational decision, not a technical one. Tomcat with bundled libraries gives the same technical capabilities as WildFly but with simpler operations, faster CI/CD, and smaller container images. The only reason to choose WildFly is if you need server-managed resources that operations teams configure independently of application deployment."

**The difference:** Staff engineers frame server choice as an operational architecture decision, considering CI/CD, container image size, and ops team skills.

**Level 5 - Distinguished (expert thinking):**
The application server market's evolution predicts infrastructure trends. In the 2000s, commercial servers (WebLogic, WebSphere) dominated because enterprises trusted vendor support. In the 2010s, open-source servers (Tomcat, WildFly) won because cloud deployment made vendor support less relevant. In the 2020s, embedded servers (Spring Boot) won because containerization made separate server management unnecessary. The pattern: as infrastructure becomes more commoditized, the deployment unit moves from "application ON server" to "application WITH server" to "application IS server." Understanding this trajectory helps predict that the next step - serverless/function-as-a-service - eliminates the server concept entirely.

---

### ⚙️ How It Works

A servlet container's core loop: (1) A connector listens on a port (default 8080). (2) When a TCP connection arrives, the connector hands it to a thread from the executor pool. (3) The thread parses the HTTP request. (4) The engine routes the request to the correct host and context (WAR) based on the URL. (5) The context's classloader is set as the thread's context classloader. (6) The filter chain executes. (7) The servlet's `service()` method is called. (8) The response is written back through the connector. (9) The thread returns to the pool.

```
Port 8080 (Connector)
     |
HTTP/1.1 or HTTP/2 parser
     |
Thread Pool (Executor)    <- HERE
  assigns thread-N
     |
Engine -> Host -> Context
  (URL routing to WAR)
     |
Set WebappClassLoader
  as thread context CL
     |
Filter Chain -> Servlet
     |
Response -> Connector -> Client
     |
Thread-N returns to pool
```

Full application servers add layers: EJB container (manages session bean lifecycle, transaction interception), JMS broker (in-process message queuing), JTA coordinator (distributed transactions), and JCA adapters (legacy system connectors). These run as additional subsystems within the same JVM.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Server starts -> Deploys WAR(s) -> Connector listens -> Request arrives -> Thread assigned -> Context resolved -> Filters -> Servlet -> Response -> Thread released.

**FAILURE PATH:**
Server out of file descriptors (`Too many open files`) -> new connections rejected -> clients see connection refused. JVM heap exhausted by loaded WARs -> `OutOfMemoryError` -> server process crashes. Full server subsystem failure (JMS broker disconnects) -> message processing stops -> cascading backpressure.

**WHAT CHANGES AT SCALE:**
Single Tomcat: 200 threads, ~2,000 rps. Clustered Tomcats behind a load balancer: horizontal scaling to 10,000+ rps. With Docker/Kubernetes: one Tomcat per container, one WAR per container, auto-scaling based on CPU/memory metrics.

---

### 💻 Code Example

**Example - Tomcat configuration (server.xml):**

```xml
<!-- BAD - default config, no tuning -->
<Connector port="8080"
    protocol="HTTP/1.1" />

<!-- GOOD - production tuning -->
<Connector port="8080"
    protocol="org.apache.coyote
        .http11.Http11NioProtocol"
    maxThreads="200"
    minSpareThreads="25"
    acceptCount="100"
    connectionTimeout="5000"
    maxKeepAliveRequests="100"
    compression="on"
    compressibleMimeType=
        "text/html,text/css,
         application/json"
    URIEncoding="UTF-8" />
```

```xml
<!-- JNDI DataSource in context.xml -->
<Resource name="jdbc/mydb"
    auth="Container"
    type="javax.sql.DataSource"
    factory="org.apache.tomcat
        .jdbc.pool.DataSourceFactory"
    maxActive="50"
    maxIdle="10"
    minIdle="5"
    maxWait="10000"
    validationQuery="SELECT 1"
    testOnBorrow="true"
    url="jdbc:postgresql://db:5432/app"
    username="${DB_USER}"
    password="${DB_PASS}" />
```

**How to verify:** Check thread pool via JMX: `jconsole` -> MBeans -> Catalina -> ThreadPool -> `http-nio-8080` -> `currentThreadCount`, `currentThreadsBusy`.

---

### 📌 Quick Reference Card

**WHAT IT IS:** The runtime environment that hosts Java web applications - either a lightweight servlet container or a full Java EE application server.

**PROBLEM IT SOLVES:** Provides HTTP handling, thread management, classloader isolation, and lifecycle management so developers focus on business logic.

**KEY INSIGHT:** Every full application server IS a servlet container plus extras. If you do not need the extras, you are paying for complexity you do not use.

**USE WHEN:** Running any Java web application. The question is which type, not whether to use one.

**AVOID WHEN:** Never avoid it - even Spring Boot embeds a servlet container.

**ANTI-PATTERN:** Using WildFly for a simple REST API that needs only Servlet + JPA (massive overhead for no benefit).

**TRADE-OFF:** Full server (all APIs, complex ops) vs servlet container (minimal APIs, simple ops, bundle what you need).

**ONE-LINER:** "Tomcat for 95% of projects; WildFly only when you genuinely need EJB, JMS, or server-managed resources."

**KEY NUMBERS:** Tomcat: 50-150MB, 2-4s startup, 200 default threads. WildFly: 200-500MB, 10-25s startup, full Java EE.

**TRIGGER PHRASE:** "Servlet container vs full server - choose the lightest sufficient option."

**OPENING SENTENCE:** "The choice between a servlet container like Tomcat and a full application server like WildFly is an operational architecture decision that determines memory footprint, startup time, configuration complexity, and available Java EE APIs."

**If you remember only 3 things:**

1. Tomcat = Servlet/JSP only, lightweight. WildFly = full Java EE, heavyweight.
2. Spring Boot embeds Tomcat - no separate server needed
3. Choose the lightest server that supports the specs your app actually uses

**Interview one-liner:**
"Tomcat and Jetty are servlet containers implementing Servlet/JSP, while WildFly and GlassFish are full application servers implementing the complete Jakarta EE spec - but since Spring Boot embeds Tomcat and bundles JPA, security, and messaging, the full server is rarely justified for new projects."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe the difference between servlet container and full server, with concrete examples of when each is needed
2. **DEBUG:** Diagnose a classloader conflict between a WAR's library and the server's built-in library
3. **DECIDE:** Choose between embedded Tomcat (Spring Boot), standalone Tomcat, and WildFly for a given project based on requirements
4. **BUILD:** Configure Tomcat's thread pool, datasource, and connectors for production use
5. **EXTEND:** Explain how the "application ON server" model evolved to "application WITH embedded server" and predict the next evolution

---

### 💡 The Surprising Truth

Tomcat was never intended to be a production server. It was created as the Reference Implementation (RI) for the Servlet specification - a proof-of-concept to validate the spec. But Tomcat's simplicity, reliability, and performance made it the most widely deployed Java web server in the world. It runs millions of production applications and handles billions of requests daily. The "just a reference implementation" became the industry standard, while the "real" commercial servers (WebLogic, WebSphere) have shrunk to legacy enterprise niches.

---

### ⚖️ Comparison Table

| Dimension | Tomcat          | Jetty                | WildFly        | Open Liberty    | Spring Boot embedded |
| --------- | --------------- | -------------------- | -------------- | --------------- | -------------------- |
| Profile   | Web             | Web                  | Full           | Full (modular)  | Web (configurable)   |
| Startup   | 2-4s            | 1-3s                 | 10-25s         | 5-15s           | 2-5s                 |
| Memory    | 50-150MB        | 40-120MB             | 200-500MB      | 100-300MB       | 80-200MB             |
| Config    | server.xml      | XML/code             | standalone.xml | server.xml      | application.yml      |
| Best for  | Traditional WAR | Embedded/lightweight | Legacy EE      | Cloud-native EE | Modern Java apps     |

**Rapid Decision Tree:**
IF Spring Boot project THEN embedded Tomcat (default).
IF traditional WAR + simple needs THEN standalone Tomcat.
IF lightweight embedded THEN Jetty.
IF legacy EJB/JMS THEN WildFly.
IF cloud-native Jakarta EE THEN Open Liberty.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                | Reality                                                                                                                                            |
| --- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Tomcat cannot do JPA or connection pooling   | Tomcat does not provide JPA, but you bundle Hibernate in your WAR. Tomcat has its own connection pool (tomcat-jdbc) and supports JNDI datasources. |
| 2   | Full application servers are more reliable   | Reliability depends on configuration and monitoring, not server type. A well-tuned Tomcat is more reliable than a misconfigured WildFly.           |
| 3   | Spring Boot does not use a servlet container | Spring Boot embeds Tomcat (or Jetty/Undertow) inside the JAR. It IS a servlet container - just managed by Spring.                                  |
| 4   | You need WildFly for clustering              | Tomcat supports session replication via mod_jk/Hazelcast. Kubernetes services provide load balancing. Clustering is not exclusive to full servers. |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Wrong Tomcat version for Jakarta namespace**

**Symptom:** `ClassNotFoundException: jakarta.servlet.http.HttpServlet` on Tomcat 9 (which provides `javax.servlet`).

**Root Cause:** Application compiled against Jakarta EE 9+ deployed on Tomcat 9 (which only supports `javax.*`). Need Tomcat 10+ for `jakarta.*`.

**Diagnostic:**

```bash
# Check Tomcat version
catalina.sh version
# Tomcat 9 = javax, Tomcat 10+ = jakarta
```

**Fix:**

BAD: Bundling jakarta.servlet-api in WEB-INF/lib on Tomcat 9

GOOD: Upgrade to Tomcat 10+ for jakarta namespace support, or downgrade dependencies to javax namespace

**Prevention:** Document Tomcat version requirement in project README. CI deploys to matching Tomcat version.

**Failure Mode 2: Thread pool starvation under load**

**Symptom:** Application responds slowly, then stops responding. HTTP 503 errors. Tomcat logs: "All threads are currently busy."

**Root Cause:** All 200 threads blocked on slow downstream calls. `acceptCount` queue fills up.

**Diagnostic:**

```bash
# JMX thread pool stats
jconsole -> MBeans -> Catalina
  -> ThreadPool -> http-nio-8080
  -> currentThreadsBusy (should < maxThreads)
# Thread dump
jstack $(pgrep -f catalina) \
  | grep "http-nio" | wc -l
```

**Fix:**

BAD: Increasing maxThreads to 2000 (memory explosion)

GOOD: Set connection timeouts to 5s, use async servlets for slow paths, add circuit breakers for failing backends, scale horizontally

**Prevention:** Alert when `currentThreadsBusy / maxThreads > 0.8`. Set `connectionTimeout` and `keepAliveTimeout` aggressively.

**Failure Mode 3: Memory leak from hot-redeploy**

**Symptom:** `OutOfMemoryError: Metaspace` after several WAR redeploys on running Tomcat.

**Root Cause:** Old WebappClassLoader retained by ThreadLocal, JDBC driver, or logging framework reference. Cannot be garbage collected.

**Diagnostic:**

```bash
# Tomcat leak detection (in catalina.out)
grep "SEVERE.*leak" logs/catalina.out
# Memory analysis
jmap -histo $(pgrep -f catalina) \
  | grep "WebappClassLoader"
```

**Fix:**

BAD: Increasing MaxMetaspaceSize

GOOD: Enable Tomcat's built-in leak prevention (`JreMemoryLeakPreventionListener`), deregister JDBC drivers in `contextDestroyed()`, use Spring Boot embedded to avoid hot-redeploy

**Prevention:** Never hot-redeploy in production. Use rolling deployments with separate container instances.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Trade-off     | 60-120 seconds  | Decision framework   |
| Debugging     | 90-150 seconds  | Systematic diagnosis |

**Q1 [JUNIOR]: What is the difference between Tomcat and WildFly?**

_Why they ask:_ Testing basic knowledge of the Java server landscape.
_Likely follow-up:_ "Which would you choose for a new project?"

**Answer:**
Tomcat is a servlet container - it implements the Servlet and JSP specifications only. It is lightweight (50-150MB memory, 2-4 second startup), simple to configure, and sufficient for most Java web applications.

WildFly (formerly JBoss AS) is a full Java EE application server. It implements everything Tomcat does PLUS EJB (enterprise beans), JMS (messaging), JTA (distributed transactions), JCA (legacy connectors), JAAS (security), and 20+ additional specifications. It is heavier (200-500MB, 10-25 second startup) and more complex to operate.

For a new project, I would choose Tomcat (embedded in Spring Boot) unless the requirements specifically need EJB remoting, server-managed JMS queues, or JTA distributed transactions. In modern architectures, these are usually replaced by Spring beans, Apache Kafka, and Saga patterns respectively.

The key insight: Tomcat + bundled libraries (Hibernate for JPA, HikariCP for connection pooling, Spring Security for auth) gives you equivalent functionality to WildFly with less operational complexity. The full application server adds value only when you need server-managed resources that operations teams configure independently of application code.

_What separates good from great:_ Explaining that Tomcat + bundled libraries matches WildFly's capabilities for most use cases, and identifying the specific scenarios where a full server is genuinely needed.

---

**Q2 [MID]: When would you choose an embedded server (Spring Boot) vs a standalone server?**

_Why they ask:_ Testing architecture decision-making.
_Likely follow-up:_ "What are the downsides of embedded servers?"

**Answer:**
**Choose embedded (Spring Boot) when:**

- Building microservices (one app, one container, one process)
- Using Docker/Kubernetes (executable JAR is the natural deployment unit)
- CI/CD pipelines (single artifact to build, test, deploy)
- Developer productivity (no server install, `java -jar` runs everything)
- You want application code and server config in the same codebase (version-controlled together)

**Choose standalone server when:**

- Multiple WARs share one server (legacy pattern, saves memory via shared classloader)
- Operations team manages server configuration separately from application code (enterprise separation of concerns)
- Using full Java EE specs (EJB, JMS) that require a managed container
- Hot-deploying WARs without server restart (development convenience, not recommended in production)
- Regulatory requirement for certified application server (some industries require Oracle WebLogic or IBM WebSphere)

**The trend is strongly toward embedded.** In Kubernetes, each pod runs one process. The one-server-many-WARs model conflicts with container orchestration's one-process-per-container model. Spring Boot's dominance reflects this architectural shift.

Downsides of embedded: server tuning requires application redeployment (cannot change `maxThreads` without restarting the app). In a standalone server, ops can tune the server without touching application code.

_What separates good from great:_ Acknowledging the trend while explaining the specific scenarios where standalone servers remain justified (not just "use Spring Boot always").

---

**Q3 [SENIOR]: How do you tune Tomcat's thread pool for production?**

_Why they ask:_ Testing production operations knowledge.
_Likely follow-up:_ "How do you decide the right maxThreads value?"

**Answer:**
Tomcat's thread pool is the primary throughput lever. The key parameters in `server.xml`:

**`maxThreads` (default: 200):** Maximum concurrent requests. Size based on: `maxThreads >= target_rps * avg_latency_seconds`. For 2000 rps with 100ms avg latency: 2000 _ 0.1 = 200 threads sufficient. For 200 rps with 1s latency: 200 _ 1 = 200 threads barely sufficient. If backends are slow, you need more threads - but each thread costs ~1MB stack memory.

**`minSpareThreads` (default: 10):** Pre-created threads ready for requests. Set to ~25 for production to avoid thread creation overhead on traffic spikes.

**`acceptCount` (default: 100):** TCP backlog queue when all threads are busy. Requests in this queue wait. If this fills, new connections get TCP RST (connection refused).

**`connectionTimeout` (default: 60000ms):** How long to wait for the first byte of a request. Set to 5000ms in production. 60 seconds is far too generous - slow clients tie up threads.

**My tuning process:**

1. Start with 200 threads (default)
2. Load test with production-like traffic patterns
3. Monitor `currentThreadsBusy` via JMX
4. If threads hit 80% utilization, check WHY: slow backends? CPU saturation?
5. If backends are slow: add timeouts and circuit breakers first, increase threads second
6. If CPU-bound: more threads will not help - optimize code or scale horizontally

The most common mistake is increasing `maxThreads` to "fix" slow response times. This masks the real problem (slow backends, missing connection timeouts) and eventually causes `OutOfMemoryError` from thread stack memory.

_What separates good from great:_ Providing the formula (`threads >= rps * latency`), the JMX monitoring approach, and warning against the "more threads = faster" misconception.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Servlet Fundamentals - what the container actually manages
- Web Application Structure - how WARs are deployed to the server
- Why Java EE Exists - the spec model that servers implement

**Builds on this (learn these next):**

- Servlet Container Tuning - deep dive into production configuration
- Application Server Diagnostics - monitoring and troubleshooting
- Servlet Lifecycle and Threading Model - how the container manages servlets

**Alternatives / Comparisons:**

- Spring Boot embedded Tomcat - the modern alternative to standalone servers
- Node.js / Express - non-Java alternative with event-loop model
- Netty - low-level async server, basis for reactive frameworks

---

---

# Servlet Lifecycle and Threading Model

**TL;DR** - The servlet container creates one instance per servlet, calls `init()` once, then dispatches concurrent requests to `service()` on multiple threads simultaneously - making every servlet a concurrent program where instance fields are shared mutable state.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without a defined lifecycle, developers would not know when to initialize resources (database connections, caches), when to release them, or how many instances exist. Without a defined threading model, developers would not know whether their servlet code needs to be thread-safe (it does) or whether each request gets its own instance (it does not).

**THE BREAKING POINT:**
Early web application bugs almost always involved either: (1) resource leaks because initialization and cleanup were not managed, or (2) data corruption because developers assumed one instance per request (like CGI) when the container actually shared one instance across all requests.

**THE INVENTION MOMENT:**
The Servlet specification formalized both concerns: a clear lifecycle (`init` -> `service` -> `destroy`) and a clear threading model (one instance, many threads). This made the rules explicit: initialize once, clean up once, and your request handling code must be thread-safe.

**EVOLUTION:**
Servlet 1.0 (basic lifecycle, 1997) -> Servlet 2.3 (lifecycle events via listeners, 2001) -> Servlet 3.0 (async processing - `startAsync()`, 2009) -> Servlet 3.1 (non-blocking I/O - `ReadListener`/`WriteListener`, 2013) -> Virtual threads (Project Loom, Java 21+, potentially millions of concurrent servlets).

---

### 📘 Textbook Definition

The servlet lifecycle consists of three phases managed by the servlet container: **instantiation and initialization** (container creates one instance per servlet definition and calls `init(ServletConfig)` once), **request handling** (container calls `service(ServletRequest, ServletResponse)` for each incoming request, dispatching to `doGet()`, `doPost()`, etc., with multiple threads calling `service()` concurrently on the same instance), and **destruction** (container calls `destroy()` once before unloading the servlet). The threading model is one-instance-many-threads by default: the container maintains a single servlet instance and allows concurrent access. This means instance variables are shared across all requests and must be handled with thread-safety awareness.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
One instance, many threads, three lifecycle methods: `init()` once, `service()` per request, `destroy()` once.

**One analogy:**

> A bank teller (servlet instance) with one desk (instance) but many phone lines (threads). The teller starts work in the morning (`init()`), answers multiple calls simultaneously on different lines (`service()` on different threads), and closes up at night (`destroy()`). The teller's desk has shared supplies (instance fields) - if two calls need the same notepad at the same time, confusion results (race condition).

**One insight:**
The container's decision to use one instance with many threads (instead of one instance per request) was a performance optimization: creating objects is expensive, and a servlet may have costly initialization. But this optimization traded simplicity for a concurrency requirement that catches every developer who stores request data in instance fields.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. `init()` happens-before any `service()` call - the container guarantees the servlet is fully initialized before handling requests
2. Multiple threads call `service()` concurrently - the container provides NO synchronization between concurrent requests
3. `destroy()` happens-after the last `service()` call returns (or times out) - the container drains in-flight requests before destruction
4. `HttpServletRequest` and `HttpServletResponse` are per-thread - each request thread gets exclusive access to its own request/response pair

**DERIVED DESIGN:**
From invariant 1: expensive setup (DB connections, caches) belongs in `init()`. From invariant 2: instance fields must be immutable, thread-safe, or avoided. From invariant 3: resource cleanup in `destroy()` is reliable for normal shutdown. From invariant 4: request/response objects are your thread-safe workspace.

**THE TRADE-OFFS:**

**Gain:** Memory efficiency (one instance vs thousands), fast request handling (no object creation per request), clear lifecycle for resource management

**Cost:** Thread-safety burden on developers, surprising behavior for beginners who expect per-request instances, debugging difficulty for race conditions

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Managing shared resources efficiently while handling concurrent requests is an inherent challenge

**Accidental:** The single-instance-multi-thread model is a container design choice - frameworks like JAX-RS allow per-request resource instances, and virtual threads may change the calculus entirely

---

### 🧠 Mental Model / Analogy

> An airport security checkpoint (servlet). One checkpoint station (instance) with one X-ray machine (`init()` sets it up once). Multiple travelers (requests) pass through simultaneously on parallel lanes (threads). The X-ray machine is shared - if a traveler leaves a bag on it (instance field), the next traveler's bag collides with it (race condition). Each traveler has their own boarding pass and luggage (request/response objects) - those are private.

- "Security checkpoint" -> servlet instance
- "X-ray machine" -> initialized resource (init)
- "Parallel lanes" -> concurrent threads
- "Boarding pass" -> HttpServletRequest (per-thread)
- "Abandoned bag" -> instance variable (shared state bug)

Where this analogy breaks down: in a real airport, lanes are physically separate. In a servlet, threads share the same memory space - collisions are invisible until data is corrupted.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
When the server starts, it creates your servlet once and sets it up (`init`). For every web request, the server calls your code (`service/doGet/doPost`) - but it can handle many requests at the same time using different threads, all sharing the same servlet object. When the server shuts down, it calls cleanup (`destroy`).

**Level 2 - How to use it (junior developer):**

```java
@WebServlet(
    urlPatterns = "/data",
    loadOnStartup = 1)
public class DataServlet
        extends HttpServlet {
    private DataSource ds; // OK: set once

    @Override
    public void init() throws
            ServletException {
        // Called ONCE at startup
        try {
            ds = (DataSource) new
                InitialContext().lookup(
                "java:comp/env/jdbc/mydb");
        } catch (NamingException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        // Called per request, on many
        // threads concurrently
        // ds is safe: immutable after init
        // Local vars are thread-safe
        String id = req.getParameter("id");
        String json = queryData(ds, id);
        resp.setContentType(
            "application/json");
        resp.getWriter().write(json);
    }

    @Override
    public void destroy() {
        // Called ONCE at shutdown
        // Close resources if needed
    }
}
```

**Level 3 - How it works (mid-level engineer):**
The container maintains a mapping: servlet name -> servlet instance. On first request (or at startup if `loadOnStartup >= 0`), the container: (1) loads the class via the WAR's classloader, (2) calls the no-arg constructor, (3) calls `init(ServletConfig)`. The `ServletConfig` holds init parameters from web.xml or `@WebServlet(initParams)`.

For each request, the container: (1) gets a thread from the pool, (2) creates `HttpServletRequest`/`HttpServletResponse` facades wrapping the raw socket data, (3) calls `service(req, resp)`. `HttpServlet.service()` reads the HTTP method and dispatches to `doGet()`, `doPost()`, `doPut()`, `doDelete()`, `doHead()`, `doOptions()`, or `doTrace()`.

On undeploy/shutdown: (1) container stops routing new requests, (2) waits for in-flight requests to complete (with timeout), (3) calls `destroy()`, (4) sets the servlet reference to null for GC.

**Level 4 - Production mastery (senior/staff engineer):**
The threading model creates specific production patterns:

**Thread-local storage pattern:** When you need per-request state that spans multiple method calls but cannot be passed as parameters (e.g., MDC logging context, user identity), use `ThreadLocal`. But ALWAYS clean it in a `finally` block or filter - thread pool reuse means ThreadLocal values persist across requests.

**`loadOnStartup` tuning:** Set to 1 for critical servlets so `init()` failures are detected at deployment time, not at first request. Without it, a broken JNDI lookup silently waits until the first user hits the servlet.

**Async lifecycle:** `startAsync()` decouples the request from the container thread. The `AsyncContext` has its own lifecycle: `start()` -> processing on custom thread -> `complete()` or `dispatch()`. Timeouts are managed by `AsyncContext.setTimeout()`. If the async operation never completes, the container fires `AsyncListener.onTimeout()`.

**Virtual threads (Java 21+):** With Project Loom, the thread-per-request model becomes viable at massive scale. Tomcat can use virtual threads as its executor - each request gets its own virtual thread (cost: ~few KB, not ~1MB). This makes blocking I/O in servlets acceptable again and potentially obsoletes async servlets for most use cases.

**The Senior-to-Staff Leap (what separates them):**

**A Senior says:** "The servlet lifecycle is init, service, destroy. Service must be thread-safe."

**A Staff says:** "The lifecycle IS the concurrency contract. `init()` happens-before guarantees visibility of initialized fields. The multi-thread `service()` model means the servlet is a concurrency boundary - every field access must be reasoned about. Spring MVC controllers inherit this model because `DispatcherServlet` is a servlet. Understanding the servlet threading model is understanding the threading model of every Java web framework."

**The difference:** Staff engineers see the servlet lifecycle as a formal concurrency contract with happens-before semantics, not just a sequence of method calls.

**Level 5 - Distinguished (expert thinking):**
The one-instance-many-threads model was a pragmatic choice for 1997 hardware: object creation was expensive, memory was scarce, and the model minimized both. Modern JVMs create objects in nanoseconds and have gigabytes of heap. The model's raison d'etre has weakened. Virtual threads (Project Loom) may ultimately enable a one-instance-per-request model with no performance penalty - each request gets a virtual thread that is lightweight enough to be disposable. If this happens, the thread-safety concerns that have defined servlet programming for 25 years become irrelevant. The Servlet spec's next major version may embrace this, changing the foundational assumption of Java web development.

---

### ⚙️ How It Works

The container maintains a `HashMap<String, Servlet>` mapping servlet names to instances. When a request URL matches a pattern, the container looks up the servlet. If the instance does not exist yet, it creates and initializes it (lazy loading unless `loadOnStartup` is set). The container then gets a thread from its `Executor` (thread pool), sets the WAR's classloader as the thread's context classloader, creates request/response facade objects, and calls `instance.service(req, resp)`.

The `HttpServlet.service()` implementation is a method-dispatch switch:

```java
// Simplified HttpServlet.service()
protected void service(
        HttpServletRequest req,
        HttpServletResponse resp) {
    String method = req.getMethod();
    if ("GET".equals(method))
        doGet(req, resp);
    else if ("POST".equals(method))
        doPost(req, resp);
    else if ("PUT".equals(method))
        doPut(req, resp);
    else if ("DELETE".equals(method))
        doDelete(req, resp);
    // ... other methods
    else
        resp.sendError(
            SC_METHOD_NOT_ALLOWED);
}
```

```
Container Startup
  |
loadOnStartup=1 ?
  YES -> new Servlet() + init()  <- HERE
  NO  -> wait for first request
  |
Request arrives
  |
Thread from pool -> service() -> doGet()
  |
(concurrent threads share same instance)
  |
Server Shutdown
  |
Wait for in-flight requests
  |
destroy() -> GC
```

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Server starts -> `loadOnStartup` servlets initialized -> Request arrives -> Thread assigned -> `service()` dispatches to `doGet()`/`doPost()` -> Response written -> Thread released. On shutdown: stop accepting -> drain in-flight -> `destroy()` -> process exits.

**FAILURE PATH:**
`init()` throws `ServletException` -> servlet marked UNAVAILABLE -> all requests to this URL return 503 -> no `destroy()` called (never fully initialized). `service()` throws uncaught exception -> container catches -> sends 500 -> thread released -> servlet instance remains alive (one bad request does not kill the servlet).

**WHAT CHANGES AT SCALE:**
At low traffic: thread pool mostly idle, per-request latency dominates. At high traffic: thread pool saturation, queuing latency dominates. With async servlets: container threads released during I/O, effective concurrency much higher than thread count. With virtual threads: thread pool becomes irrelevant - millions of concurrent virtual threads possible.

---

### 💻 Code Example

**Example - Understanding lifecycle callbacks:**

```java
// BAD - heavy work in doGet()
@WebServlet("/report")
public class ReportServlet
        extends HttpServlet {
    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        // Creating connection pool
        // PER REQUEST - 50ms overhead!
        DataSource ds =
            createConnectionPool();
        String report = generate(ds);
        resp.getWriter().write(report);
        ds.close(); // pool destroyed!
    }
}

// GOOD - init once, use many times
@WebServlet(
    urlPatterns = "/report",
    loadOnStartup = 1)
public class ReportServlet
        extends HttpServlet {
    private DataSource ds; // init once

    @Override
    public void init()
            throws ServletException {
        ds = createConnectionPool();
        // Fail fast at startup
        // if config is wrong
    }

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        // ds is initialized, reused
        String report = generate(ds);
        resp.getWriter().write(report);
    }

    @Override
    public void destroy() {
        if (ds instanceof Closeable) {
            ((Closeable) ds).close();
        }
    }
}
```

**How to verify:** Add logging to `init()`, `doGet()`, `destroy()`. Start the server, make 10 requests. You will see 1 init, 10 doGet, 0 destroy. Stop the server: 1 destroy.

---

### 📌 Quick Reference Card

**WHAT IT IS:** The container's contract for managing servlet instances - one instance, many threads, three lifecycle phases.

**PROBLEM IT SOLVES:** Defines when resources are initialized, when cleanup happens, and how concurrent requests interact with the servlet instance.

**KEY INSIGHT:** The one-instance-many-threads model means servlets are concurrent programs. Instance fields are shared mutable state.

**USE WHEN:** Understanding any Java web framework. Spring MVC, JAX-RS, and Struts all run within this model.

**AVOID WHEN:** Never avoid understanding this - even in Spring Boot, the DispatcherServlet follows this lifecycle.

**ANTI-PATTERN:** Storing per-request data in instance fields. Using `synchronized doGet()` (kills concurrency). Creating expensive resources in `doGet()` instead of `init()`.

**TRADE-OFF:** Memory efficiency (one instance) vs thread-safety burden (concurrent access).

**ONE-LINER:** "init once, serve concurrently, destroy once - the servlet lifecycle IS the Java web concurrency contract."

**KEY NUMBERS:** `init()`: once. `service()`: N times concurrently. `destroy()`: once. Default threads: 200 (Tomcat).

**TRIGGER PHRASE:** "One instance, many threads, happens-before from init to service."

**OPENING SENTENCE:** "The servlet lifecycle - init, service, destroy - is not just a sequence of callbacks but a formal concurrency contract where `init()` happens-before any `service()` call, and multiple threads invoke `service()` concurrently on the same instance."

**If you remember only 3 things:**

1. One instance, many threads - instance fields are shared mutable state
2. `init()` once at startup, `destroy()` once at shutdown, `service()` per request concurrently
3. `HttpServletRequest`/`HttpServletResponse` are per-thread safe - use them for request-scoped data

**Interview one-liner:**
"The servlet container creates one instance and calls service() from multiple threads concurrently - making the lifecycle a concurrency contract where init() provides happens-before visibility, instance fields are shared state, and request/response objects are the thread-safe per-request workspace."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the lifecycle state machine (created -> initialized -> handling requests -> destroyed) with thread interactions
2. **DEBUG:** Diagnose a thread-safety violation where User A sees User B's data due to a shared instance field
3. **DECIDE:** Choose between synchronous, async, and virtual thread models based on workload characteristics
4. **BUILD:** Write a servlet with correct init/destroy resource management and thread-safe request handling
5. **EXTEND:** Explain how Spring MVC controllers, JAX-RS resources, and Struts actions all operate within the servlet lifecycle model

---

### 💡 The Surprising Truth

The `SingleThreadModel` interface existed in the Servlet spec to let developers opt out of thread safety concerns - the container would either synchronize all access or create multiple instances. It was deprecated in Servlet 2.4 and removed because it created a false sense of security. Synchronizing `service()` serialized all requests (destroying throughput). Creating multiple instances did not protect shared external resources (database connections, caches). The spec committee realized that thread-safety cannot be an opt-in feature - it must be a fundamental design concern. This deprecation forced the entire Java web ecosystem to take concurrency seriously.

---

### ⚖️ Comparison Table

| Dimension          | Sync Servlet        | Async Servlet  | Virtual Threads    | Reactive (WebFlux) |
| ------------------ | ------------------- | -------------- | ------------------ | ------------------ |
| Thread per request | 1 (blocked)         | 0 during I/O   | 1 (virtual, cheap) | 0 (event loop)     |
| Max concurrency    | = thread pool       | >> thread pool | millions           | millions           |
| Code complexity    | Simple              | Moderate       | Simple             | High               |
| Blocking I/O       | OK (wastes threads) | Must avoid     | OK (cheap threads) | Must avoid         |
| Best for           | Fast backends       | Slow backends  | General purpose    | Extreme I/O        |

**Rapid Decision Tree:**
IF all backends respond <100ms THEN sync servlets.
IF some backends >500ms THEN async servlets or virtual threads.
IF Java 21+ available THEN virtual threads (simplest).
IF extreme I/O multiplexing needed THEN reactive (WebFlux).

---

### ⚠️ Common Misconceptions

| #   | Misconception                                        | Reality                                                                                                   |
| --- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | Each request creates a new servlet instance          | One instance handles ALL requests. The container reuses the same object.                                  |
| 2   | `HttpServletRequest` is shared between requests      | Each request thread gets its own request/response pair. They are NOT shared.                              |
| 3   | `synchronized doGet()` makes the servlet thread-safe | Technically yes, but it serializes ALL requests - only one request at a time. This destroys throughput.   |
| 4   | Async servlets are always better than sync           | Async adds complexity. For fast backends (<100ms), sync servlets with 200 threads handle 2000 rps easily. |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Race condition in instance field**

**Symptom:** Intermittent data corruption. User sees another user's data. Cannot reproduce reliably.

**Root Cause:** Mutable instance field written by `doGet()` - concurrent threads overwrite each other.

**Diagnostic:**

```bash
# Static analysis for shared state
grep -n "private.*[^final]" \
  *Servlet.java | grep -v "static"
# Thread dump during load test
jstack $(pgrep -f catalina) \
  | grep -B5 "doGet"
```

**Fix:**

BAD: `synchronized(this)` in `doGet()` (serializes all requests)

GOOD: Use local variables, request attributes, or `AtomicReference`/`ConcurrentHashMap` for genuinely shared state

**Prevention:** Code review rule: no mutable non-final instance fields in servlets. SpotBugs `SERVLET_FIELD` detector.

**Failure Mode 2: init() failure goes undetected**

**Symptom:** First request to a servlet returns 503. Subsequent requests also fail. No startup error logged.

**Root Cause:** `loadOnStartup` not set. Lazy init defers `init()` to first request. The `init()` failure is only seen when the first user hits the URL.

**Diagnostic:**

```bash
# Check if loadOnStartup is configured
grep -n "loadOnStartup\|load-on-startup" \
  src/main/java/**/*Servlet.java \
  src/main/webapp/WEB-INF/web.xml
```

**Fix:**

BAD: Catching and swallowing exceptions in `init()` to let the servlet "start"

GOOD: Set `loadOnStartup = 1` so init failures happen at deployment time and are immediately visible

**Prevention:** Set `loadOnStartup = 1` on all production servlets. Monitor deployment health checks.

**Failure Mode 3: ThreadLocal leak across requests**

**Symptom:** Request A's user identity appears in Request B's logging context. Data bleeds between unrelated requests.

**Root Cause:** `ThreadLocal` set in one request but not cleared before the thread returns to the pool. Next request on the same thread inherits the stale value.

**Diagnostic:**

```bash
# Search for ThreadLocal usage
# without corresponding remove()
grep -rn "ThreadLocal" src/
grep -rn "\.remove()" src/
# Count should match or be in finally
```

**Fix:**

BAD: Not using ThreadLocal (sometimes it is necessary for MDC, security context)

GOOD: Always clear ThreadLocal in a `finally` block or a filter's `doFilter()` cleanup

**Prevention:** Use a servlet filter that clears all ThreadLocals in the `finally` block of `doFilter()`. This is exactly what Spring's `RequestContextFilter` does.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Debugging     | 90-150 seconds  | Systematic diagnosis |
| Trade-off     | 60-120 seconds  | Decision framework   |

**Q1 [JUNIOR]: Walk through the servlet lifecycle methods in order.**

_Why they ask:_ Fundamental knowledge test.
_Likely follow-up:_ "What happens if init throws an exception?"

**Answer:**
The servlet lifecycle has three phases:

**Phase 1 - Initialization:** The container creates one instance of the servlet class (calls the no-arg constructor), then calls `init(ServletConfig config)`. This happens either at server startup (if `loadOnStartup` is configured) or when the first request arrives for this servlet's URL. `init()` runs exactly once. This is where you set up expensive resources: database connection pools, caches, configuration loading.

If `init()` throws a `ServletException`, the container marks the servlet as unavailable. All subsequent requests to this URL receive an HTTP 503 (Service Unavailable). The `destroy()` method is NOT called because the servlet was never successfully initialized.

**Phase 2 - Request Handling:** For every incoming HTTP request matching the servlet's URL pattern, the container calls `service(HttpServletRequest, HttpServletResponse)`. The default `HttpServlet.service()` dispatches to `doGet()`, `doPost()`, etc. based on the HTTP method. CRITICAL: multiple threads call `service()` concurrently on the SAME instance. There is no synchronization. Your code must be thread-safe.

**Phase 3 - Destruction:** When the server shuts down or the application is undeployed, the container calls `destroy()` once. Before calling `destroy()`, the container waits for in-flight requests to complete (with a configurable timeout). `destroy()` is where you close connection pools, flush buffers, and release resources.

The lifecycle guarantee: `init()` happens-before any `service()` call. All `service()` calls happen-before `destroy()`. Between those boundaries, `service()` is called concurrently without ordering guarantees.

_What separates good from great:_ Mentioning the happens-before guarantees between lifecycle phases and the 503 behavior when init fails.

---

**Q2 [SENIOR]: How do async servlets change the lifecycle model?**

_Why they ask:_ Testing advanced servlet knowledge.
_Likely follow-up:_ "How does Spring's DeferredResult use this?"

**Answer:**
Async servlets (Servlet 3.0+) add a fourth phase to the lifecycle: the async context.

In traditional servlets, the container thread is held for the entire request. In async mode, the servlet can release the container thread and complete the response later from a different thread.

```java
@Override
protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp) {
    AsyncContext ctx = req.startAsync();
    ctx.setTimeout(30000);
    // Container thread RELEASED here
    executor.submit(() -> {
        // Different thread
        try {
            String data = slowCall();
            ctx.getResponse().getWriter()
                .write(data);
            ctx.complete(); // ends request
        } catch (Exception e) {
            ctx.complete();
        }
    });
    // doGet() returns, thread goes
    // back to the pool
}
```

The lifecycle changes:

1. `doGet()` starts async context and returns immediately
2. Container thread returns to the pool
3. Application thread processes the request asynchronously
4. `AsyncContext.complete()` finalizes the response and tells the container to flush and close

`AsyncListener` provides lifecycle callbacks: `onComplete`, `onTimeout`, `onError`, `onStartAsync`. The container enforces the timeout - if `complete()` is not called within the timeout, `onTimeout()` fires.

Spring MVC leverages this directly. When a controller returns `DeferredResult<T>`, Spring calls `startAsync()`, releases the container thread, and waits for `DeferredResult.setResult()` or `setErrorResult()` on any thread. When the result is set, Spring dispatches back to the servlet container to write the response. `Callable<T>` return type does the same but executes the callable on Spring's task executor.

This is critical for microservice architectures: if your service calls 5 downstream services, each taking 200ms, a sync servlet blocks the container thread for 200ms (sequential) or 200ms (parallel). An async servlet releases the thread immediately and completes when all downstream responses arrive.

_What separates good from great:_ Explaining the `AsyncListener` lifecycle (especially timeout handling), connecting it to Spring's `DeferredResult`, and explaining the microservice concurrency benefit.

---

**Q3 [MID]: What is the happens-before relationship in the servlet lifecycle?**

_Why they ask:_ Testing Java Memory Model knowledge in the servlet context.
_Likely follow-up:_ "Does this mean init() fields are visible without volatile?"

**Answer:**
The Java Memory Model defines "happens-before" as a guarantee that memory writes in one action are visible to reads in another action. The Servlet spec establishes two key happens-before relationships:

**1. `init()` happens-before `service()`:** Any field set in `init()` is guaranteed visible to all threads calling `service()`. This means you do NOT need `volatile` or `synchronized` for fields that are written once in `init()` and only read in `service()`.

```java
public class MyServlet extends HttpServlet {
    private DataSource ds; // Safe!

    public void init() {
        ds = createPool(); // Write
    }

    protected void doGet(...) {
        ds.getConnection(); // Read: sees
        // init()'s write due to HB
    }
}
```

**2. `destroy()` happens-after all `service()` calls:** The container ensures all in-flight `service()` calls complete before `destroy()` runs. Resources can be safely closed in `destroy()`.

**Where you DO need synchronization:** Between concurrent `service()` calls on different threads, there is NO happens-before relationship. If two threads call `doGet()` simultaneously, reads and writes to shared fields are data races unless you use `volatile`, `synchronized`, or `java.util.concurrent` classes.

In practice, this means: set fields in `init()` -> they are safely visible everywhere. Modify fields in `doGet()` -> you have a concurrency problem. This is why the recommended pattern is: initialize everything in `init()`, make instance fields effectively immutable after initialization, and use only local variables and request attributes in `service()`.

_What separates good from great:_ Correctly stating that `init()`-set fields do NOT need `volatile` due to the happens-before guarantee, and contrasting this with the absence of guarantees between concurrent `service()` calls.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Servlet Fundamentals - the basic servlet programming model
- Java threading and concurrency basics - needed to understand the threading model

**Builds on this (learn these next):**

- Asynchronous Servlets - decoupling requests from container threads
- Filters and Filter Chains - components that participate in the request lifecycle
- Session Management and Tracking - state management across the stateless servlet model

**Alternatives / Comparisons:**

- Spring MVC controller lifecycle - singletons that inherit the servlet threading model
- JAX-RS resource lifecycle - can be per-request (`@RequestScoped`) unlike servlets
- Reactive handlers - event-loop model that replaces thread-per-request

---

---

# Filters and Filter Chains

**TL;DR** - Filters are reusable interceptors that wrap around servlets in a chain, processing requests before and responses after the target servlet - enabling cross-cutting concerns like authentication, logging, and compression without modifying servlet code.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every servlet duplicates the same boilerplate: check authentication, log the request, set character encoding, add CORS headers, compress the response. A 20-line business logic servlet grows to 200 lines of infrastructure code. When the authentication logic changes, you update 50 servlets. When you miss one, it becomes a security hole.

**THE BREAKING POINT:**
A team with 80 servlets discovered that 12 of them were missing the new authentication check because the developer forgot to add it. The code review process could not reliably catch these omissions because the auth check was mixed into business logic.

**THE INVENTION MOMENT:**
Servlet Filters (Servlet 2.3, 2001) introduced the interceptor pattern: declare cross-cutting logic once, configure which URL patterns it applies to, and the container automatically invokes it before every matching request. Servlets contain only business logic. Filters contain only infrastructure logic.

**EVOLUTION:**
Servlet 2.3 (basic filters, 2001) -> Servlet 3.0 (`@WebFilter` annotation, `DispatcherType` for forward/include/error, 2009) -> Spring `OncePerRequestFilter` (prevents double-invocation on forwards) -> Spring Security filter chain (15-20 filters for comprehensive security).

---

### 📘 Textbook Definition

A servlet filter is a Java object that implements `javax.servlet.Filter` (or `jakarta.servlet.Filter`) and intercepts requests and responses for a configured set of URL patterns. Filters are organized into a chain by the servlet container: each filter calls `chain.doFilter(request, response)` to pass control to the next filter (or the target servlet). Filters can modify the request (wrapping it), modify the response (wrapping it), short-circuit the chain (returning a response without calling the servlet), or perform pre/post processing (logging, timing). The filter chain order is determined by the order of `<filter-mapping>` elements in `web.xml` or by the container's ordering of `@WebFilter` annotations.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Filters are middleware for servlets - they intercept every request, do cross-cutting work (auth, logging, encoding), and pass control down the chain.

**One analogy:**

> Airport security checkpoints before the gate (servlet). Every passenger (request) passes through metal detector (AuthFilter), ID check (CORSFilter), and baggage scan (EncodingFilter) in order. If any checkpoint rejects the passenger, they never reach the gate. The passenger does not know how many checkpoints exist - they just walk forward. The gate agent (servlet) does not know what security checks happened - they just serve the passenger.

**One insight:**
The filter chain is a pipeline of responsibility. The power is in `chain.doFilter()`: code before it runs on the way IN (pre-processing), code after it runs on the way OUT (post-processing). This single method call creates a symmetric interception pattern.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Filters execute in declaration order on the way in, and reverse order on the way out - the chain is a stack
2. Each filter can modify the request/response or short-circuit the chain - filters are full interceptors, not just observers
3. Filter lifecycle matches the servlet lifecycle - `init()` once, `doFilter()` per request, `destroy()` once
4. Filters apply to URL patterns, not specific servlets - decoupling filter logic from servlet identity

**DERIVED DESIGN:**
From invariant 1: order matters. An authentication filter must come before an authorization filter. A compression filter must come after content generation. From invariant 2: filters can wrap the request/response objects to add functionality (e.g., `HttpServletRequestWrapper` for request modification). From invariant 3: filters can hold initialized resources. From invariant 4: a single filter can protect all URLs matching `/api/*` regardless of which servlets handle them.

**THE TRADE-OFFS:**

**Gain:** Separation of concerns (servlets: business logic, filters: infrastructure), reusability (one filter covers all URLs), consistency (cannot forget to add auth to a new servlet)

**Cost:** Debugging complexity (request passes through 10+ filters before reaching the servlet), performance overhead (each filter adds method calls and potential object wrapping), ordering sensitivity (wrong order = security bypass)

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Cross-cutting concerns exist and must be applied consistently

**Accidental:** The chain pattern forces linear ordering of concerns that may be independent. Some frameworks (like Spring) add complexity with multiple filter chain types (servlet filters, Spring Security filters, Spring MVC interceptors)

---

### 🧠 Mental Model / Analogy

> Russian nesting dolls (matryoshka). The outermost doll (first filter) opens, revealing the next doll (second filter), and so on until you reach the innermost doll (servlet). Each doll's outer half is pre-processing, and the inner half is post-processing. When you close the dolls back up, you execute the post-processing in reverse order.

- "Outermost doll" -> first filter (e.g., logging)
- "Middle dolls" -> security, encoding filters
- "Innermost doll" -> the servlet
- "Opening" -> pre-processing (before `chain.doFilter()`)
- "Closing" -> post-processing (after `chain.doFilter()`)

Where this analogy breaks down: unlike dolls, any filter can prevent the inner dolls from being opened (short-circuit the chain).

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A filter is code that runs before (and after) your web page handler. It can check if the user is logged in, log the request, set the character encoding, or add security headers. You configure filters once, and they automatically apply to all matching URLs.

**Level 2 - How to use it (junior developer):**

```java
@WebFilter(urlPatterns = "/*")
public class LoggingFilter
        implements Filter {
    @Override
    public void doFilter(
            ServletRequest req,
            ServletResponse resp,
            FilterChain chain)
            throws IOException,
            ServletException {
        long start =
            System.currentTimeMillis();
        // PRE-PROCESSING
        HttpServletRequest httpReq =
            (HttpServletRequest) req;
        System.out.println(
            "Request: "
            + httpReq.getRequestURI());

        chain.doFilter(req, resp);
        // POST-PROCESSING
        long elapsed =
            System.currentTimeMillis()
            - start;
        System.out.println(
            "Response: " + elapsed + "ms");
    }
}
```

**Level 3 - How it works (mid-level engineer):**
The container builds a `FilterChain` for each request by matching the request URL against all filter URL patterns (in declaration order). The chain is an ordered list of filters plus the target servlet at the end. Calling `chain.doFilter()` invokes the next element. If the last filter calls `chain.doFilter()`, the servlet's `service()` method executes.

Filter ordering: In `web.xml`, `<filter-mapping>` order determines chain order. With `@WebFilter`, the spec does not guarantee ordering (container-dependent). For guaranteed ordering, use `web.xml` or Spring's `@Order` annotation with `FilterRegistrationBean`.

Request/response wrapping: Filters can wrap the request or response using `HttpServletRequestWrapper` / `HttpServletResponseWrapper`. This enables: (1) adding request attributes, (2) modifying headers, (3) capturing the response body, (4) buffering output for compression.

**Level 4 - Production mastery (senior/staff engineer):**

**Spring Security's filter chain** is the most sophisticated production use. It inserts 15-20 filters into the servlet filter chain via `DelegatingFilterProxy` (a servlet filter that delegates to a Spring-managed bean). Spring Security's `FilterChainProxy` then maintains its own ordered list: `SecurityContextPersistenceFilter`, `CsrfFilter`, `LogoutFilter`, `UsernamePasswordAuthenticationFilter`, `ExceptionTranslationFilter`, `FilterSecurityInterceptor`, and more. Understanding this chain is essential for debugging auth issues.

**The OncePerRequestFilter pattern:** When a filter dispatches a request internally (via `RequestDispatcher.forward()`), servlet filters may execute again for the forwarded request. Spring's `OncePerRequestFilter` uses a request attribute flag to ensure the filter runs only once per request, regardless of dispatches.

**Response buffering for compression:** A `GzipFilter` must capture the entire response body before compressing it. This requires wrapping the response with a `HttpServletResponseWrapper` that buffers `getOutputStream()` / `getWriter()` output, then compressing and writing the buffer in the post-processing phase.

**The Senior-to-Staff Leap (what separates them):**

**A Senior says:** "Filters handle cross-cutting concerns. Put auth in a filter, not in servlets."

**A Staff says:** "The filter chain is the security boundary of the application. Every filter-chain ordering decision is a security decision. I can trace a request through the exact sequence of filters, explain what each one does, and identify where in the chain a security bypass could occur. When debugging Spring Security, I start by logging the filter chain order, not by guessing at configuration."

**The difference:** Staff engineers treat filter chain ordering as a security architecture concern and can mentally trace a request through the entire chain.

**Level 5 - Distinguished (expert thinking):**
The filter chain pattern is the Chain of Responsibility design pattern applied to HTTP request processing. It is identical in concept to: Unix pipes (each command processes and passes data), Express.js middleware (each middleware calls `next()`), ASP.NET middleware pipeline, and gRPC interceptors. Understanding this pattern once unlocks fluency in every web framework. The key insight: the pattern works because the interface is uniform - every filter/middleware sees the same request/response types and calls the same "next" function. This uniformity enables composition of independently developed interceptors.

---

### ⚙️ How It Works

The container builds the filter chain at request time by: (1) matching the request URL against all `<filter-mapping>` patterns, (2) collecting matching filters in declaration order, (3) appending the target servlet at the end. Each `doFilter()` call advances the chain pointer by one position.

```
Client Request
     |
FilterChain[0]: LoggingFilter
  pre: log request
  chain.doFilter()          <- HERE
     |
FilterChain[1]: AuthFilter
  pre: check token
  chain.doFilter()
     |
FilterChain[2]: EncodingFilter
  pre: set UTF-8
  chain.doFilter()
     |
Target Servlet: doGet()
  write response body
     |  (returns)
EncodingFilter post
     |  (returns)
AuthFilter post
     |  (returns)
LoggingFilter post: log time
     |
Client Response
```

Short-circuit example: if `AuthFilter` detects no token, it calls `resp.sendError(401)` and does NOT call `chain.doFilter()`. The encoding filter and servlet never execute.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Request -> Filter1 pre -> Filter2 pre -> Filter3 pre -> Servlet -> Filter3 post -> Filter2 post -> Filter1 post -> Response.

**FAILURE PATH:**
Filter throws exception -> container catches -> sends 500 -> remaining filters and servlet do not execute. Filter calls `sendError(403)` without calling `chain.doFilter()` -> request short-circuited -> servlet never sees the request.

**WHAT CHANGES AT SCALE:**
With 20+ filters per request (Spring Security), the overhead becomes measurable. Each filter adds: one method call, one stack frame, potential request/response wrapper allocation. For high-throughput APIs, minimize filter count for performance-critical paths. Use URL patterns to restrict filters to relevant paths only.

---

### 💻 Code Example

**Example - Authentication filter:**

```java
// BAD - auth check duplicated
// in every servlet
@WebServlet("/api/orders")
public class OrderServlet
        extends HttpServlet {
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        // Duplicated in EVERY servlet
        String token =
            req.getHeader("Authorization");
        if (!isValid(token)) {
            resp.sendError(401);
            return;
        }
        // business logic...
    }
}

// GOOD - single auth filter
@WebFilter(urlPatterns = "/api/*")
public class AuthFilter
        implements Filter {
    @Override
    public void doFilter(
            ServletRequest req,
            ServletResponse resp,
            FilterChain chain)
            throws IOException,
            ServletException {
        HttpServletRequest httpReq =
            (HttpServletRequest) req;
        HttpServletResponse httpResp =
            (HttpServletResponse) resp;
        String token = httpReq.getHeader(
            "Authorization");
        if (token == null
                || !isValid(token)) {
            httpResp.sendError(
                HttpServletResponse
                    .SC_UNAUTHORIZED);
            return; // short-circuit
        }
        req.setAttribute(
            "userId", extractUser(token));
        chain.doFilter(req, resp);
    }
}
```

**How to verify:** Enable Tomcat's debug logging: `org.apache.catalina.core.ApplicationFilterChain` at FINE level. Shows each filter invocation in order.

---

### 📌 Quick Reference Card

**WHAT IT IS:** An interceptor that wraps around servlet execution, processing requests before and responses after the target servlet.

**PROBLEM IT SOLVES:** Eliminates duplicated cross-cutting logic (auth, logging, encoding) across servlets.

**KEY INSIGHT:** `chain.doFilter()` is the pivot point. Code before it is pre-processing; code after it is post-processing. The chain is a stack.

**USE WHEN:** Authentication, authorization, logging, character encoding, CORS headers, response compression, request rate limiting.

**AVOID WHEN:** Business logic that belongs in a specific servlet. Filters are for infrastructure, not features.

**ANTI-PATTERN:** Putting business logic in filters (hard to test, hard to maintain). Using `@WebFilter` ordering (not guaranteed).

**TRADE-OFF:** Clean separation of concerns vs debugging complexity (20+ filters in Spring Security).

**ONE-LINER:** "Filters are the Chain of Responsibility pattern for HTTP - intercept, process, and pass on."

**KEY NUMBERS:** Spring Security: 15-20 filters. Typical app: 5-10 filters. Each adds ~microseconds.

**TRIGGER PHRASE:** "Code before chain.doFilter is pre-processing, code after is post-processing."

**OPENING SENTENCE:** "Servlet filters implement the Chain of Responsibility pattern for HTTP request processing, where each filter can inspect, modify, or short-circuit the request before it reaches the target servlet."

**If you remember only 3 things:**

1. chain.doFilter() is the pivot: pre-processing before, post-processing after
2. Chain order = declaration order (use web.xml for guaranteed ordering)
3. Spring Security IS a filter chain - understanding filters unlocks debugging Spring Security

**Interview one-liner:**
"Servlet filters implement the interceptor pattern as a chain of responsibility, where each filter can pre-process the request, call chain.doFilter() to pass to the next filter or servlet, and then post-process the response - enabling cross-cutting concerns like authentication, logging, and compression without modifying servlet code."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the filter chain execution order (pre in order, post in reverse) with short-circuit behavior
2. **DEBUG:** Trace a request through Spring Security's 15+ filters to find where auth is failing
3. **DECIDE:** Choose between servlet filters, Spring interceptors, and AOP for a given cross-cutting concern
4. **BUILD:** Write a response-wrapping filter (e.g., caching the response body for logging)
5. **EXTEND:** Explain how the filter chain pattern maps to Express middleware, ASP.NET middleware, and gRPC interceptors

---

### 💡 The Surprising Truth

The order of `@WebFilter` annotated filters is not defined by the Servlet specification. The spec says: "The order the container uses in building the chain of filters to be applied for a particular request URI is: first, the `<filter-mapping>` matching filter mappings in the same order that these elements appear in the deployment descriptor [web.xml], and then the `@WebFilter` matching filter mappings." But for multiple `@WebFilter` filters, the relative order is container-implementation-dependent. Tomcat uses class name alphabetical order. Jetty uses a different order. This is why Spring Boot uses `FilterRegistrationBean` with explicit `setOrder()` - because relying on annotation-based ordering is a portability trap.

---

### ⚖️ Comparison Table

| Dimension     | Servlet Filter             | Spring HandlerInterceptor | Spring AOP             | Express Middleware |
| ------------- | -------------------------- | ------------------------- | ---------------------- | ------------------ |
| Scope         | All requests (URL pattern) | Spring MVC only           | Any Spring bean        | All routes         |
| Access        | Raw request/response       | Handler method info       | Method args/return     | req, res, next     |
| Wrapping      | Can wrap req/resp          | Cannot wrap               | Cannot wrap            | Can modify req/res |
| Order control | web.xml / @Order           | @Order                    | @Order / pointcut      | Declaration order  |
| Best for      | Auth, encoding, CORS       | Logging, timing, auth     | Business cross-cutting | All middleware     |

**Rapid Decision Tree:**
IF cross-cutting for ALL requests (including static) THEN servlet filter.
IF cross-cutting for Spring MVC controllers only THEN HandlerInterceptor.
IF cross-cutting for specific business methods THEN Spring AOP.
IF need to wrap request/response objects THEN servlet filter (only option).

---

### ⚠️ Common Misconceptions

| #   | Misconception                               | Reality                                                                                                                           |
| --- | ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `@WebFilter` ordering is guaranteed         | It is NOT. The spec does not define ordering for annotation-based filters. Use web.xml or Spring's `@Order`.                      |
| 2   | Filters only process requests               | Filters process both requests (before `chain.doFilter()`) and responses (after `chain.doFilter()`).                               |
| 3   | A filter exception stops the chain          | Yes, but the exception propagates to the container, which sends a 500. Other filters' post-processing is NOT executed.            |
| 4   | Filters are the same as Spring interceptors | Filters operate at the servlet container level (before Spring). Interceptors operate within Spring MVC (after DispatcherServlet). |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Filter ordering causes security bypass**

**Symptom:** Unauthenticated requests reach protected servlets.

**Root Cause:** Authorization filter runs before authentication filter. Authorization check sees no user and defaults to "allow" instead of "deny."

**Diagnostic:**

```bash
# Log filter chain order
# Add to each filter:
# System.out.println(
#   "Filter: " + getClass().getName());
# Or enable Tomcat debug:
# FINE on ApplicationFilterChain
grep "Filter:" logs/catalina.out
```

**Fix:**

BAD: Adding auth checks to individual servlets as a workaround

GOOD: Fix filter ordering in web.xml: authentication first, then authorization. Default-deny in authorization filter when no user principal exists.

**Prevention:** Document filter chain order in the project wiki. Code review all filter-mapping changes as security-sensitive.

**Failure Mode 2: Filter not executing for forwarded requests**

**Symptom:** After `RequestDispatcher.forward()`, expected filters do not execute for the forwarded URL.

**Root Cause:** Default filter mapping applies only to `REQUEST` dispatch type. Forwarded requests use `FORWARD` dispatch type.

**Diagnostic:**

```xml
<!-- Check web.xml dispatcher type -->
<filter-mapping>
    <filter-name>MyFilter</filter-name>
    <url-pattern>/*</url-pattern>
    <!-- Missing: -->
    <!-- <dispatcher>FORWARD</dispatcher> -->
</filter-mapping>
```

**Fix:**

BAD: Duplicating filter logic in the forwarded servlet

GOOD: Add `<dispatcher>FORWARD</dispatcher>` to the filter-mapping, or use Spring's `OncePerRequestFilter` which handles dispatch types correctly

**Prevention:** Always consider dispatch types when configuring filters. Use `OncePerRequestFilter` in Spring apps.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Debugging     | 90-150 seconds  | Systematic diagnosis |
| Trade-off     | 60-120 seconds  | Decision framework   |

**Q1 [JUNIOR]: What is the difference between a filter and a servlet?**

_Why they ask:_ Testing fundamental understanding of the Servlet API.
_Likely follow-up:_ "Can you give an example of when to use a filter?"

**Answer:**
A servlet and a filter serve fundamentally different purposes in the request processing pipeline:

A **servlet** handles business logic for specific URL patterns. It generates the response content - HTML, JSON, XML. Each servlet is the endpoint for a specific request type. `doGet()` returns product data, `doPost()` creates an order.

A **filter** handles cross-cutting infrastructure concerns. It wraps around the servlet (and other filters) in a chain. It does NOT generate response content - it processes the request/response before and after the servlet. Common uses: authentication (reject unauthorized requests before they reach the servlet), logging (record request timing), character encoding (ensure UTF-8), CORS headers (add `Access-Control-Allow-Origin`), compression (gzip the response body).

The key structural difference: a filter has `chain.doFilter()` which passes control to the next filter or servlet. A servlet is the end of the chain - it generates the response and returns. Filters compose (you can stack 10 filters); servlets do not compose.

In Spring MVC, the `DispatcherServlet` is the only servlet. All controllers are handlers within that servlet. But Spring Security still uses servlet filters to intercept requests before they reach the DispatcherServlet.

_What separates good from great:_ Explaining that filters compose (chain) while servlets are endpoints, and connecting this to Spring MVC's architecture where DispatcherServlet is the only servlet but filters still wrap it.

---

**Q2 [MID]: How does the filter chain execution order work?**

_Why they ask:_ Testing understanding of the interceptor pattern.
_Likely follow-up:_ "What happens if a filter throws an exception?"

**Answer:**
The filter chain follows a stack-based execution model. Imagine three filters (A, B, C) and a servlet:

**On the way in** (pre-processing): A runs first, calls `chain.doFilter()`, B runs, calls `chain.doFilter()`, C runs, calls `chain.doFilter()`, servlet executes.

**On the way out** (post-processing): After the servlet returns, C's code after `chain.doFilter()` runs, then B's post-processing, then A's post-processing.

This is the same as a call stack: A calls B, B calls C, C calls servlet, servlet returns to C, C returns to B, B returns to A.

If filter B throws an exception or calls `resp.sendError(403)` without calling `chain.doFilter()`: filter C and the servlet NEVER execute. Filter A's post-processing runs only if B's exception propagates normally (not if it is caught internally by B). If B throws an uncaught exception, the container catches it and sends a 500 response.

The order is determined by: (1) `<filter-mapping>` order in `web.xml` (guaranteed), (2) for `@WebFilter` annotations, the order is container-implementation-dependent (not specified by the spec). This is why Spring uses `FilterRegistrationBean.setOrder()` for explicit ordering.

The critical ordering decisions: authentication must come before authorization. Compression must come after content generation. Logging should be the outermost filter (to capture total request time including all filter processing).

_What separates good from great:_ Correctly distinguishing that pre-processing is in order and post-processing is in reverse order, and knowing that `@WebFilter` ordering is undefined by the spec.

---

**Q3 [SENIOR]: How would you debug a Spring Security filter chain issue?**

_Why they ask:_ Testing practical debugging of a complex real-world filter chain.
_Likely follow-up:_ "How do you customize the Spring Security filter chain?"

**Answer:**
Spring Security's filter chain is the most common source of auth debugging in Java web applications. My systematic approach:

**Step 1 - Enable debug logging:**

```properties
logging.level.org.springframework
    .security=DEBUG
logging.level.org.springframework
    .security.web.FilterChainProxy=DEBUG
```

This logs every filter invocation and its decision. You will see: "Security filter chain: [WebAsyncManagerIntegrationFilter, SecurityContextPersistenceFilter, HeaderWriterFilter, CsrfFilter, LogoutFilter, UsernamePasswordAuthenticationFilter, ... FilterSecurityInterceptor]"

**Step 2 - Identify which filter rejects the request:** The DEBUG log shows each filter processing the request. When a filter rejects (sends 401/403), you see the exact filter name and reason. Common culprits: `CsrfFilter` (missing CSRF token for POST), `UsernamePasswordAuthenticationFilter` (wrong credentials URL), `FilterSecurityInterceptor` (access rule mismatch).

**Step 3 - Check filter ordering:** Spring Security inserts its filters at specific positions defined by `SecurityProperties.DEFAULT_FILTER_ORDER`. Custom filters added via `addFilterBefore()` / `addFilterAfter()` may be in the wrong position.

**Step 4 - Check multiple filter chains:** `FilterChainProxy` supports multiple `SecurityFilterChain` instances, each matching different URL patterns. A request may match the wrong chain. Use `.securityMatchers()` in Spring Security 6+ to verify which chain matches.

**Step 5 - Common traps:**

- CORS preflight (OPTIONS) blocked by security filters - add `cors()` to security config
- CSRF enabled for REST API (should be disabled for stateless APIs)
- Custom filter added but not in the security filter chain (added as a servlet filter instead of via Spring Security's `addFilter`)

The key insight: Spring Security is NOT a black box. It is an ordered list of filters. Enable DEBUG logging, and you can see exactly what happens to every request.

_What separates good from great:_ Having a systematic multi-step debugging approach, knowing the specific filter names and their roles, and identifying common traps like CORS and CSRF configuration.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Servlet Lifecycle and Threading Model - filters share the same lifecycle
- Web Application Structure - where filter mappings are configured

**Builds on this (learn these next):**

- Java EE Security Model - filters as the security enforcement layer
- Web Application Vulnerabilities - what filters protect against

**Alternatives / Comparisons:**

- Spring HandlerInterceptors - operate within Spring MVC, after filters
- Express.js middleware - same pattern, different language
- ASP.NET middleware pipeline - same chain-of-responsibility pattern

---

---

# Listeners and Servlet Context

**TL;DR** - Servlet listeners are event-driven callbacks that react to lifecycle changes (application start/stop, session create/destroy, request create/destroy) and attribute changes - enabling initialization logic, resource cleanup, and monitoring without coupling to specific servlets.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without listeners, there is no standard place to run code when the application starts (before any servlet handles requests), when a session is created, or when the application shuts down. Developers would put initialization logic in the first servlet's `init()` method - but which servlet loads first? What if the initialization depends on a specific order? What about cleanup when the application stops but no request is active?

**THE BREAKING POINT:**
Applications needed to initialize shared resources (database connection pools, caches, configuration) at application startup and clean them up at shutdown. Putting this in servlet `init()` was fragile: servlets load lazily (unless `loadOnStartup` is set), and no single servlet owns application-wide resources.

**THE INVENTION MOMENT:**
Servlet Listeners (Servlet 2.3, 2001) provided event-driven callbacks tied to the container lifecycle. `ServletContextListener.contextInitialized()` fires exactly once when the application starts - before any servlet or filter. `contextDestroyed()` fires when the application shuts down. Session and request listeners provide the same pattern for their scopes.

**EVOLUTION:**
Servlet 2.3 (context, session, attribute listeners, 2001) -> Servlet 2.4 (request listeners, 2003) -> Servlet 3.0 (`@WebListener` annotation, programmatic listener registration via `ServletContext.addListener()`, 2009) -> Spring's `ContextLoaderListener` (bootstraps the Spring ApplicationContext from a servlet listener).

---

### 📘 Textbook Definition

Servlet listeners are classes that implement one or more listener interfaces from the `javax.servlet` (or `jakarta.servlet`) package. They are registered with the servlet container and receive callbacks when specific events occur. **Context listeners** (`ServletContextListener`) receive application-level events (startup, shutdown). **Session listeners** (`HttpSessionListener`) receive session-level events (create, destroy, attribute changes). **Request listeners** (`ServletRequestListener`) receive request-level events (request created, request destroyed). The `ServletContext` is the application-wide shared object: one per WAR deployment, providing access to init parameters, resource paths, attributes (application-scoped data), and the ability to programmatically register servlets, filters, and listeners (since Servlet 3.0).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Listeners are the observer pattern for servlet lifecycle events - get notified when the app starts, sessions are created, or requests arrive.

**One analogy:**

> Building management systems in an office building. The building has sensors (listeners) for: door opening (request), employee badge-in (session created), badge-out (session destroyed), building power-on (context initialized), and fire alarm (context destroyed). The sensors do not handle the events themselves - they notify the building management system, which decides what to do (turn on lights, update occupancy count, shut down HVAC).

**One insight:**
`ServletContextListener.contextInitialized()` is the TRUE application startup hook - it fires before any servlet or filter loads. Spring's entire ApplicationContext is bootstrapped from this single callback via `ContextLoaderListener`. Understanding listeners is understanding how Spring starts.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. `contextInitialized()` fires before any servlet or filter `init()` - listeners are the first application code to run
2. `contextDestroyed()` fires after all servlets and filters are destroyed - listeners are the last application code to run
3. The `ServletContext` is one-per-WAR - it is the application-scoped singleton
4. Listeners are invoked in registration order (declaration order in web.xml) for startup, and reverse order for shutdown - symmetric lifecycle

**DERIVED DESIGN:**
From invariant 1: application-wide resources (connection pools, caches) should be initialized in a `ServletContextListener`. From invariant 2: cleanup is guaranteed even if no requests are active at shutdown. From invariant 3: `ServletContext.setAttribute()` is the standard way to share objects across servlets. From invariant 4: if listener A initializes something that listener B depends on, declare A first.

**THE TRADE-OFFS:**

**Gain:** Clean lifecycle management, decoupled from servlets, guaranteed ordering, standard mechanism that works across all containers

**Cost:** Another abstraction layer to understand, debug, and maintain. Listeners can fail silently if exceptions are swallowed.

---

### 🧠 Mental Model / Analogy

> A restaurant's opening and closing procedures. The manager (ServletContextListener) arrives first, turns on the lights, fires up the ovens, and checks supplies (contextInitialized). Then the waiters (servlets) start work. During service, a greeter (HttpSessionListener) notes each party that arrives (sessionCreated) and leaves (sessionDestroyed) - tracking table occupancy. At closing, the last customer leaves, waiters finish, and the manager locks up and turns off the ovens (contextDestroyed).

- "Manager" -> ServletContextListener (first in, last out)
- "Greeter" -> HttpSessionListener (tracks sessions)
- "Kitchen supplies" -> resources initialized in contextInitialized()
- "Occupancy count" -> session tracking via listener

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Listeners let you run code when specific things happen in your web application: when the app starts up, when a user session begins, when a request arrives. You register them once, and the server calls your code automatically.

**Level 2 - How to use it (junior developer):**

```java
@WebListener
public class AppStartupListener
        implements ServletContextListener {
    @Override
    public void contextInitialized(
            ServletContextEvent sce) {
        // Runs ONCE at app startup
        // Before any servlet loads
        ServletContext ctx =
            sce.getServletContext();
        DataSource ds = createPool(
            ctx.getInitParameter("db.url"));
        ctx.setAttribute("dataSource", ds);
        System.out.println(
            "App started, pool ready");
    }

    @Override
    public void contextDestroyed(
            ServletContextEvent sce) {
        // Runs ONCE at app shutdown
        DataSource ds = (DataSource)
            sce.getServletContext()
            .getAttribute("dataSource");
        closePool(ds);
        System.out.println(
            "App stopped, pool closed");
    }
}
```

Servlets access the shared resource via:

```java
DataSource ds = (DataSource)
    getServletContext()
    .getAttribute("dataSource");
```

**Level 3 - How it works (mid-level engineer):**
The container maintains a list of registered listeners per type:

| Interface                         | Events                               | Scope                |
| --------------------------------- | ------------------------------------ | -------------------- |
| `ServletContextListener`          | app start/stop                       | Application          |
| `ServletContextAttributeListener` | context attribute add/remove/replace | Application          |
| `HttpSessionListener`             | session create/destroy               | Session              |
| `HttpSessionAttributeListener`    | session attribute add/remove/replace | Session              |
| `HttpSessionBindingListener`      | object bound/unbound to session      | Object               |
| `HttpSessionActivationListener`   | session passivation/activation       | Session (clustering) |
| `ServletRequestListener`          | request create/destroy               | Request              |
| `ServletRequestAttributeListener` | request attribute add/remove/replace | Request              |

`HttpSessionBindingListener` is special: the object itself implements the interface (not registered separately). It gets notified when it is placed into or removed from a session.

**Level 4 - Production mastery (senior/staff engineer):**

**Active session counting** for load monitoring:

```java
@WebListener
public class SessionCounter
        implements HttpSessionListener {
    private final AtomicInteger count =
        new AtomicInteger(0);

    @Override
    public void sessionCreated(
            HttpSessionEvent se) {
        int c = count.incrementAndGet();
        se.getSession()
            .getServletContext()
            .setAttribute(
                "activeSessionCount", c);
    }

    @Override
    public void sessionDestroyed(
            HttpSessionEvent se) {
        count.decrementAndGet();
    }
}
```

**Spring's ContextLoaderListener:** This is the most important production use of `ServletContextListener`. It bootstraps the root Spring `ApplicationContext` from `applicationContext.xml` or `@Configuration` classes. The entire Spring ecosystem (dependency injection, AOP, transaction management) starts from this single listener callback.

**Programmatic registration (Servlet 3.0+):** `ServletContainerInitializer` can register listeners programmatically during startup. Spring Boot uses this via `SpringServletContainerInitializer` to bootstrap without `web.xml`.

**The Senior-to-Staff Leap (what separates them):**

**A Senior says:** "Use a `ServletContextListener` to initialize resources at startup."

**A Staff says:** "The listener lifecycle defines the application's resource dependency graph. `contextInitialized()` is the composition root - the single point where all shared resources are created and wired together. In Spring, this is `ContextLoaderListener`. Understanding that Spring's DI container bootstraps from a single servlet listener callback is essential for debugging startup failures, custom initialization ordering, and understanding what happens before Spring is ready."

**The difference:** Staff engineers see listeners as the composition root of the application, not just a callback mechanism.

**Level 5 - Distinguished (expert thinking):**
The `ServletContext` as an application-scoped container predates Spring's `ApplicationContext` by several years. Spring's DI container is, architecturally, a sophisticated replacement for `ServletContext.setAttribute()`. In Servlet-only applications, the `ServletContext` IS the service locator: resources initialized in listeners are stored as context attributes and retrieved by servlets. Spring replaced this pattern with dependency injection - but the bootstrap mechanism remains: a servlet listener creates the Spring context, which then replaces `setAttribute` with `@Autowired`. Understanding this lineage explains why Spring web applications still require a servlet container to run.

---

### ⚙️ How It Works

The container processes listeners during deployment and shutdown:

```
WAR Deployed
  |
Container reads web.xml / @WebListener
  |
Create listener instances
  |
Call contextInitialized() on each  <- HERE
  ServletContextListener (in order)
  |
Initialize filters (init())
  |
Initialize servlets (init())
  |
Application READY
  |
... requests processed ...
  |
Application SHUTDOWN
  |
Destroy servlets (destroy())
  |
Destroy filters (destroy())
  |
Call contextDestroyed() on each
  ServletContextListener (reverse)
  |
WAR Undeployed
```

For session listeners: `sessionCreated()` fires when `request.getSession()` creates a new session (not when a returning user's existing session is looked up). `sessionDestroyed()` fires when the session times out, is explicitly invalidated via `session.invalidate()`, or the application is undeployed.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
WAR deployed -> `contextInitialized()` (listeners in order) -> filters `init()` -> servlets `init()` -> requests processed -> `sessionCreated()` / `sessionDestroyed()` per session -> shutdown -> servlets `destroy()` -> filters `destroy()` -> `contextDestroyed()` (listeners in reverse).

**FAILURE PATH:**
`contextInitialized()` throws exception -> container may still deploy the app (container-dependent) but the application is in a broken state. Best practice: fail fast and let the deployment fail. In Tomcat, an exception in `contextInitialized()` marks the context as failed.

**WHAT CHANGES AT SCALE:**
Session listeners become critical for monitoring: tracking active session count, detecting session storms (thousands of sessions created per second indicating a bot attack or misconfigured load balancer), and auditing session attribute changes for compliance.

---

### 💻 Code Example

**Example - Application initialization with listeners:**

```java
// BAD - init in servlet (fragile order)
@WebServlet(
    urlPatterns = "/api/*",
    loadOnStartup = 1)
public class ApiServlet
        extends HttpServlet {
    public void init() {
        // What if another servlet
        // needs this pool too?
        DataSource ds = createPool();
        getServletContext()
            .setAttribute("ds", ds);
    }
}

// GOOD - init in listener
// (guaranteed first)
@WebListener
public class AppInitListener
        implements ServletContextListener {
    @Override
    public void contextInitialized(
            ServletContextEvent sce) {
        ServletContext ctx =
            sce.getServletContext();
        // Init params from web.xml
        String dbUrl =
            ctx.getInitParameter("db.url");
        DataSource ds =
            createPool(dbUrl);
        ctx.setAttribute(
            "dataSource", ds);
        // Available to ALL servlets
        // and filters
    }

    @Override
    public void contextDestroyed(
            ServletContextEvent sce) {
        DataSource ds = (DataSource)
            sce.getServletContext()
            .getAttribute("dataSource");
        if (ds != null) {
            closePool(ds);
        }
    }
}
```

**How to verify:** Add logging to `contextInitialized()` and servlet `init()`. Start the server. Listener log appears BEFORE servlet log, confirming the ordering guarantee.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Event-driven callbacks for servlet container lifecycle events (app start/stop, session create/destroy, request create/destroy).

**PROBLEM IT SOLVES:** Provides a standard place for application-wide initialization and cleanup, decoupled from servlets.

**KEY INSIGHT:** `contextInitialized()` is the true application startup hook - it fires before any servlet or filter. Spring bootstraps from this callback.

**USE WHEN:** Application startup/shutdown logic, session monitoring, request auditing, shared resource initialization.

**AVOID WHEN:** Request-level processing (use filters). Business logic (use servlets).

**ANTI-PATTERN:** Initializing resources in servlets instead of listeners. Swallowing exceptions in `contextInitialized()` (hides startup failures).

**TRADE-OFF:** Clean lifecycle management vs another abstraction layer to understand.

**ONE-LINER:** "Listeners are the observer pattern for the servlet container - notified at every lifecycle boundary."

**KEY NUMBERS:** 8 listener interfaces. contextInitialized: once. sessionCreated: once per session.

**TRIGGER PHRASE:** "contextInitialized is the composition root - everything starts here."

**OPENING SENTENCE:** "Servlet listeners provide event-driven callbacks for container lifecycle events, with `ServletContextListener.contextInitialized()` serving as the application's composition root - the first application code to execute, before any filter or servlet."

**If you remember only 3 things:**

1. `contextInitialized()` runs before any servlet or filter - it is the application startup hook
2. Spring's `ContextLoaderListener` bootstraps the entire ApplicationContext from this callback
3. Session listeners enable real-time monitoring of active sessions

**Interview one-liner:**
"Servlet listeners implement the observer pattern for container lifecycle events, with `contextInitialized()` serving as the composition root that fires before any servlet or filter - which is exactly how Spring's `ContextLoaderListener` bootstraps the entire ApplicationContext."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** List all 8 listener interfaces and when each fires
2. **DEBUG:** Diagnose an initialization ordering issue where a servlet's `init()` fails because a listener-initialized resource is not yet available
3. **DECIDE:** Choose between listener initialization and servlet `loadOnStartup` initialization for a shared resource
4. **BUILD:** Implement a session counter with `HttpSessionListener` that exposes active session count via JMX
5. **EXTEND:** Explain how Spring's `ContextLoaderListener` bootstraps the ApplicationContext and how Spring Boot replaces it with `ServletContainerInitializer`

---

### 💡 The Surprising Truth

`HttpSessionBindingListener` is the only listener interface where the object itself (not a separately registered listener) receives the callback. When you put an object implementing `HttpSessionBindingListener` into a session, the container automatically calls `valueBound()`. When it is removed, `valueUnbound()` fires. This was designed for objects that need to manage their own lifecycle when placed in a session - for example, a database connection wrapper that should be closed when the session expires. This self-notifying pattern is unique in the Servlet API and is the basis for Spring's session-scoped bean destruction callbacks.

---

### ⚖️ Comparison Table

| Dimension | ServletContextListener  | @PostConstruct (Spring) | ApplicationRunner (Spring Boot) | CommandLineRunner     |
| --------- | ----------------------- | ----------------------- | ------------------------------- | --------------------- |
| When      | Before servlets/filters | After bean creation     | After context refresh           | After context refresh |
| Scope     | Any servlet container   | Spring only             | Spring Boot only                | Spring Boot only      |
| Access    | ServletContext          | Bean dependencies       | ApplicationArguments            | String[] args         |
| Use for   | Container resources     | Bean init               | App init logic                  | App init logic        |

**Rapid Decision Tree:**
IF pure servlet app THEN `ServletContextListener`.
IF Spring app with shared resource THEN `@PostConstruct` on a `@Bean`.
IF Spring Boot with startup task THEN `ApplicationRunner`.
IF need access to raw command-line args THEN `CommandLineRunner`.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                 | Reality                                                                                                                                       |
| --- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Listeners fire after servlets init                            | Context listeners fire BEFORE any servlet or filter initializes.                                                                              |
| 2   | `HttpSessionListener.sessionCreated()` fires on every request | It fires only when a NEW session is created (first call to `request.getSession()`), not on subsequent requests.                               |
| 3   | You need Spring to bootstrap a web app                        | Pure Servlet API with `@WebListener` provides a complete bootstrap mechanism. Spring's `ContextLoaderListener` IS a `ServletContextListener`. |
| 4   | `contextDestroyed()` may not fire                             | It fires reliably on normal shutdown and undeploy. Only abnormal process kills (kill -9) skip it.                                             |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Listener ordering dependency failure**

**Symptom:** `NullPointerException` in a listener's `contextInitialized()` when accessing a context attribute set by another listener.

**Root Cause:** Listener B depends on a resource initialized by listener A, but B is registered before A.

**Diagnostic:**

```bash
# Check listener order in web.xml
grep -A2 "<listener-class>" \
  WEB-INF/web.xml
# Or in Tomcat logs at startup
grep "listener" logs/catalina.out
```

**Fix:**

BAD: Adding null checks and fallback logic in listener B

GOOD: Ensure listener A is declared before listener B in web.xml. Or combine both into a single listener with explicit ordering.

**Prevention:** Document listener dependencies. Minimize the number of listeners (combine when possible).

**Failure Mode 2: Session listener memory leak**

**Symptom:** Heap grows continuously. Sessions are not being garbage collected even after timeout.

**Root Cause:** `HttpSessionListener.sessionDestroyed()` stores a reference to the session or its attributes in a collection, preventing garbage collection.

**Diagnostic:**

```bash
# Check session count
jconsole -> MBeans -> Catalina
  -> Manager -> /appname
  -> activeSessions
# Heap dump
jmap -dump:live,format=b,file=heap.hprof \
  $(pgrep -f catalina)
```

**Fix:**

BAD: Increasing heap size

GOOD: Review sessionDestroyed() implementation. Ensure it does not retain references to session objects. Use only session ID (String) for tracking, not the session object itself.

**Prevention:** Code review all session listener implementations for reference retention.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Debugging     | 90-150 seconds  | Systematic diagnosis |
| Trade-off     | 60-120 seconds  | Decision framework   |

**Q1 [JUNIOR]: What is a ServletContextListener and why use it?**

_Why they ask:_ Testing knowledge of application lifecycle management.
_Likely follow-up:_ "What is the difference between this and servlet init?"

**Answer:**
A `ServletContextListener` is an interface with two methods: `contextInitialized()` and `contextDestroyed()`. The servlet container calls `contextInitialized()` when the web application starts up (WAR is deployed) and `contextDestroyed()` when it shuts down (WAR is undeployed or server stops).

The key reason to use it: it fires BEFORE any servlet or filter initializes. This makes it the right place for application-wide setup: creating a database connection pool, loading configuration, initializing caches, registering MBeans for JMX monitoring.

The difference from servlet `init()`: servlet `init()` fires when that specific servlet loads (which may be lazy), and it is tied to one servlet. `contextInitialized()` fires once for the entire application, guaranteed to run before anything else.

```java
@WebListener
public class Startup
        implements ServletContextListener {
    public void contextInitialized(
            ServletContextEvent sce) {
        // Runs ONCE, before everything
        DataSource pool = createPool();
        sce.getServletContext()
            .setAttribute("pool", pool);
    }
    public void contextDestroyed(
            ServletContextEvent sce) {
        // Cleanup at shutdown
    }
}
```

In Spring applications, `ContextLoaderListener` is a `ServletContextListener` that creates the Spring `ApplicationContext` in `contextInitialized()`. This single callback bootstraps the entire Spring framework - dependency injection, AOP, transaction management.

_What separates good from great:_ Connecting the listener to Spring's bootstrap mechanism and explaining the ordering guarantee (listeners before servlets/filters).

---

**Q2 [MID]: How does Spring's ContextLoaderListener bootstrap the ApplicationContext?**

_Why they ask:_ Testing understanding of Spring's startup mechanism.
_Likely follow-up:_ "What about Spring Boot - does it use this?"

**Answer:**
Spring's `ContextLoaderListener` implements `ServletContextListener`. When the servlet container calls `contextInitialized()`, the listener:

1. Reads the `contextConfigLocation` context parameter from `web.xml` (or defaults to `/WEB-INF/applicationContext.xml`)
2. Creates a `WebApplicationContext` (typically `XmlWebApplicationContext` or `AnnotationConfigWebApplicationContext`)
3. Loads all bean definitions from the config location
4. Refreshes the context (instantiates singletons, resolves dependencies, processes `@PostConstruct`, etc.)
5. Stores the `ApplicationContext` as a `ServletContext` attribute with key `WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE`

Once stored, any servlet or filter can access the Spring context via `WebApplicationContextUtils.getRequiredWebApplicationContext(servletContext)`.

The `DispatcherServlet` creates a CHILD `ApplicationContext` (for web-specific beans) that inherits from the root context created by `ContextLoaderListener`. This parent-child hierarchy is why service beans defined in the root context are visible to controllers in the dispatcher context but not vice versa.

**Spring Boot changes this model.** Spring Boot uses `SpringServletContainerInitializer` (a `ServletContainerInitializer` SPI, not a listener) to bootstrap. In embedded mode, Spring Boot creates the Tomcat instance programmatically and registers the `DispatcherServlet` directly - no `ContextLoaderListener` or `web.xml` needed. But the concept is identical: the servlet container's startup lifecycle triggers Spring's initialization.

_What separates good from great:_ Explaining the parent-child context hierarchy between ContextLoaderListener's root context and DispatcherServlet's child context, and how Spring Boot replaces the mechanism while preserving the concept.

---

**Q3 [SENIOR]: How would you use listeners for production monitoring?**

_Why they ask:_ Testing practical use of listeners for operational concerns.
_Likely follow-up:_ "How do you detect a session storm?"

**Answer:**
Listeners are powerful production monitoring tools because they fire on every lifecycle boundary without modifying business code.

**Active session monitoring:**
An `HttpSessionListener` tracks active session count. This is critical for capacity planning and anomaly detection. A sudden spike in session creation (session storm) indicates either a bot attack, a misconfigured load balancer creating new sessions on every health check, or a client that is not sending cookies back (every request creates a new session).

I would implement a session counter that increments on `sessionCreated`, decrements on `sessionDestroyed`, and exposes the count via JMX (MBean) and an HTTP endpoint. Alert when the session creation rate exceeds 100/minute (normal user behavior is much lower).

**Request timing and slow-request detection:**
A `ServletRequestListener` captures request start time in `requestInitialized()` and calculates elapsed time in `requestDestroyed()`. Log requests exceeding a threshold (e.g., 5 seconds). This catches slow requests that monitoring tools outside the JVM might miss (they see the response time but not the servlet processing time specifically).

**Application health at startup:**
In `contextInitialized()`, verify all critical resources (database connectivity, external service availability, configuration validity). If any check fails, throw an exception to fail the deployment. Do NOT swallow the exception and let the application start in a broken state. Combine with a health check endpoint that servlets expose for load balancer probes.

**Audit logging:**
`HttpSessionAttributeListener` detects when security-sensitive attributes change (user role upgraded, permission added). This creates an audit trail at the session level without modifying business logic.

The production pattern: listeners for lifecycle monitoring, filters for request-level processing, JMX for metrics exposure, health endpoints for external monitoring. Each tool has its scope - do not use listeners for request-level work (use filters) or filters for lifecycle work (use listeners).

_What separates good from great:_ Providing concrete monitoring patterns (session storms, slow-request detection) with specific thresholds and alert conditions, and clearly delineating when to use listeners vs filters.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Servlet Fundamentals - the basic servlet programming model
- Web Application Structure - where listeners are configured
- Servlet Lifecycle and Threading Model - the lifecycle that listeners observe

**Builds on this (learn these next):**

- JNDI and Resource Management - accessing server-managed resources from listeners
- Session Management and Tracking - session listeners for tracking

**Alternatives / Comparisons:**

- Spring @PostConstruct - bean-level initialization (after listener)
- Spring ApplicationRunner - Spring Boot startup hook
- CDI @Observes - Java EE event system (more flexible than listeners)

---

---

# Request Dispatching and Forwarding

**TL;DR** - `RequestDispatcher` provides two mechanisms for server-side request routing: `forward()` transfers control entirely to another resource (the original response is discarded), while `include()` embeds another resource's output into the current response - both happen server-side without the client knowing.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without request dispatching, a servlet that needs another servlet's or JSP's output has two choices: (1) duplicate the logic, or (2) redirect the client with a 302 response, causing an extra round-trip, a visible URL change, and loss of request attributes. Neither option supports server-side composition of response fragments.

**THE BREAKING POINT:**
The MVC pattern requires a controller servlet to process business logic and then hand off to a JSP for rendering. Without forwarding, the controller would need to generate HTML directly (mixing concerns) or redirect to the JSP (losing request attributes set by the controller). Templating patterns (header, footer, sidebar includes) were impossible without a server-side include mechanism.

**THE INVENTION MOMENT:**
`RequestDispatcher` (Servlet 2.1, 1998) provided two operations: `forward()` for full delegation and `include()` for content embedding. This enabled the Front Controller and MVC patterns: a single servlet processes all requests, sets model data as request attributes, and forwards to JSPs for rendering.

**EVOLUTION:**
Servlet 2.1 (basic forwarding/including, 1998) -> Servlet 2.4 (forward/include dispatch types for filters, 2003) -> Servlet 3.0 (`AsyncContext.dispatch()` for async request completion, 2009) -> Spring MVC `InternalResourceViewResolver` (automates forward to JSP based on view name).

---

### 📘 Textbook Definition

The `RequestDispatcher` interface provides a mechanism for server-side request routing. It is obtained via `ServletContext.getRequestDispatcher(path)` (absolute path) or `ServletRequest.getRequestDispatcher(path)` (relative path). **`forward(request, response)`** transfers the request to another resource (servlet, JSP, or static file) on the server side. The target resource generates the entire response; the original servlet must not have committed the response before forwarding. **`include(request, response)`** embeds the output of another resource into the current response. The including servlet can write before and after the included content. Both operations are invisible to the client - the URL in the browser does not change, and no additional HTTP round-trip occurs.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`forward()` = "you handle this request instead of me." `include()` = "add your output to my response."

**One analogy:**

> A receptionist (controller servlet) at a company. `forward()` is transferring a call: "Let me transfer you to the billing department (JSP)" - the caller does not know they were transferred. `include()` is a conference call: "Let me bring billing on the line to read your balance" - then the receptionist continues the call.

**One insight:**
`forward()` is the mechanism that makes MVC work in Java EE. Without it, the controller pattern (process request -> set attributes -> render view) would require HTTP redirects, losing all request-scoped data.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. `forward()` must happen before the response is committed (no bytes sent to client) - you cannot take back what is already sent
2. `include()` can happen at any point - it simply appends to the current output stream
3. Both operations share the same `HttpServletRequest` and `HttpServletResponse` - request attributes set by the original servlet are visible to the target
4. The client sees no difference - the URL does not change, no additional HTTP request occurs

**DERIVED DESIGN:**
From invariant 1: controller servlets must not write to the response before forwarding. From invariant 2: include is safe for composing page fragments (headers, footers). From invariant 3: request attributes are the data-passing mechanism between controller and view. From invariant 4: server-side dispatching is fundamentally different from `response.sendRedirect()` which triggers a new client request.

**THE TRADE-OFFS:**

**Gain (forward):** Single request-response cycle, preserves request attributes, hides implementation details from client, enables MVC pattern

**Cost (forward):** Cannot forward after writing to response, confusing debugging (URL does not match the resource that generated the response), filter behavior depends on dispatch type configuration

**Gain (include):** Composable output, template-like behavior, reusable page fragments

**Cost (include):** Included resource cannot set response headers or status code (those are already controlled by the including resource)

---

### 🧠 Mental Model / Analogy

> A relay race. `forward()` is handing off the baton: the first runner (controller servlet) passes the baton to the second runner (JSP), who finishes the race (generates the response). The first runner stops running. `include()` is running together: the first runner calls the second runner to run a section of the track alongside them, then the first runner continues to the finish line.

- "Baton handoff" -> forward() transfers full control
- "Running together" -> include() adds to the current output
- "The baton" -> HttpServletRequest with attributes
- "The race" -> the HTTP response being generated
- "Spectators" -> the client (they see one continuous race, not the handoffs)

Where this analogy breaks down: in a real relay, the first runner is done after handoff. In forward(), the first servlet's code after `forward()` still executes (but cannot write to the response).

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
When a servlet needs another page to generate the response, it can either forward the request (let the other page handle everything) or include the other page's output (embed it in the current response). Both happen on the server - the user's browser does not see any of this.

**Level 2 - How to use it (junior developer):**

```java
// Forward: controller -> JSP
@WebServlet("/orders")
public class OrderController
        extends HttpServlet {
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException,
            IOException {
        List<Order> orders =
            orderService.findAll();
        req.setAttribute(
            "orders", orders);
        // Forward to JSP for rendering
        req.getRequestDispatcher(
            "/WEB-INF/views/orders.jsp")
            .forward(req, resp);
        // Do NOT write to resp before
        // this line!
    }
}
```

```java
// Include: embed a header fragment
req.getRequestDispatcher(
    "/WEB-INF/includes/header.jsp")
    .include(req, resp);
// Continue writing the main content
resp.getWriter().write(
    "<h1>Main Content</h1>");
```

**Level 3 - How it works (mid-level engineer):**

**forward() internals:**

1. Container checks if response is committed (bytes sent). If yes: `IllegalStateException`
2. Container clears the response buffer (any uncommitted output is discarded)
3. Container sets special request attributes: `javax.servlet.forward.request_uri`, `javax.servlet.forward.servlet_path`, etc.
4. Container invokes the target resource's `service()` method with the same request/response
5. After the target returns, the response is committed and the forward is complete

**include() internals:**

1. Container sets special request attributes: `javax.servlet.include.request_uri`, etc.
2. Container invokes the target resource's `service()` method
3. The included resource writes to the same output stream
4. After the target returns, the including resource continues

**Key difference with redirect:**

| Aspect             | forward() | sendRedirect()          |
| ------------------ | --------- | ----------------------- |
| HTTP requests      | 1         | 2 (original + redirect) |
| URL changes        | No        | Yes                     |
| Request attributes | Preserved | Lost                    |
| Server-side        | Yes       | No (client round-trip)  |
| Performance        | Better    | Worse (extra request)   |

**Level 4 - Production mastery (senior/staff engineer):**

**The Forward and Filter Trap:** By default, filters configured for `REQUEST` dispatch type do NOT execute for forwarded requests. If a security filter only applies to `REQUEST`, a forward to a protected JSP bypasses the filter. This is a real security vulnerability in poorly configured applications.

Solution: explicitly configure filters for `FORWARD` dispatch type:

```xml
<filter-mapping>
    <filter-name>SecurityFilter</filter-name>
    <url-pattern>/*</url-pattern>
    <dispatcher>REQUEST</dispatcher>
    <dispatcher>FORWARD</dispatcher>
</filter-mapping>
```

**WEB-INF protection pattern:** JSPs placed in `/WEB-INF/views/` cannot be accessed directly by the client (the container blocks direct access to WEB-INF). They can only be reached via `forward()` from a controller. This enforces the MVC pattern: all requests go through the controller.

**Spring MVC's InternalResourceViewResolver:** When a Spring controller returns a view name (e.g., "orders"), the resolver prepends `/WEB-INF/views/` and appends `.jsp`, then forwards to `/WEB-INF/views/orders.jsp`. This is a `RequestDispatcher.forward()` under the hood. Understanding this explains why Spring MVC JSP views must be in WEB-INF and why the URL does not change to the JSP path.

**The Senior-to-Staff Leap (what separates them):**

**A Senior says:** "Use forward for MVC and redirect for POST-redirect-GET."

**A Staff says:** "The dispatching model IS the MVC framework's core mechanism. Spring's `DispatcherServlet` forwards to views. JSF dispatches to facelets. Struts dispatches to action results. Every Java web MVC framework uses `RequestDispatcher` internally. Understanding forward vs redirect vs dispatch is understanding the control flow of any Java web application. The redirect-after-POST pattern (PRG) exists specifically because forward after POST causes duplicate submission on refresh."

**The difference:** Staff engineers connect dispatching to framework internals and can explain why PRG (Post-Redirect-Get) requires redirect (not forward) and when each is appropriate.

**Level 5 - Distinguished (expert thinking):**
The `RequestDispatcher` pattern is server-side routing. It is conceptually identical to Express.js `next()`, Python WSGI middleware chaining, and nginx `proxy_pass`. The forward/include model maps to the broader pattern of request delegation in any web stack. The Java-specific insight is that `forward()` and `include()` operate within the same servlet container instance, meaning they can share request attributes (in-memory state passing) without serialization - a performance advantage over HTTP-based routing between services. This is why the monolithic MVC pattern was efficient: data passing between controller and view was a Java method call, not a network hop.

---

### ⚙️ How It Works

```
Client: GET /orders
     |
Container: matches OrderController
     |
OrderController.doGet()
  - queries database
  - req.setAttribute("orders", list)
  - getRequestDispatcher(
      "/WEB-INF/views/orders.jsp")
      .forward(req, resp)        <- HERE
     |
Container: clears response buffer
  - sets forward attributes
  - invokes orders.jsp
     |
orders.jsp
  - reads req.getAttribute("orders")
  - generates HTML table
  - writes to response
     |
Container: commits response
     |
Client: receives HTML
  (URL still shows /orders)
```

For `include()`:

```
MainServlet.doGet()
  - writes <html><body>
  - include("/header.jsp")
       header.jsp writes <nav>...</nav>
  - writes <h1>Main Content</h1>
  - include("/footer.jsp")
       footer.jsp writes <footer>...</footer>
  - writes </body></html>
```

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW (MVC forward):**
Client GET /orders -> OrderController -> query DB -> set request attributes -> forward to orders.jsp -> JSP reads attributes, generates HTML -> response committed -> client sees HTML.

**FAILURE PATH:**
Controller writes to response before forward -> `IllegalStateException` (response already committed). Forward to non-existent resource -> 404. Included resource throws exception -> including resource's output may be partially written (corrupted response).

**WHAT CHANGES AT SCALE:**
In high-traffic MVC applications, the forward overhead is negligible (it is a method call, not a network hop). The bottleneck is the JSP compilation on first access and the database query in the controller. Modern alternatives (Thymeleaf, REST APIs with JSON) avoid JSP compilation but still use the same forward mechanism internally.

---

### 💻 Code Example

**Example - forward vs redirect:**

```java
// BAD - redirect loses request
// attributes (extra round-trip)
@WebServlet("/process")
public class ProcessServlet
        extends HttpServlet {
    protected void doPost(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        String result = process(req);
        req.setAttribute("result", result);
        // REDIRECT: client makes new
        // request, attributes LOST
        resp.sendRedirect("/result");
    }
}

// GOOD - forward preserves attributes
// (single request-response)
@WebServlet("/process")
public class ProcessServlet
        extends HttpServlet {
    protected void doPost(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException,
            IOException {
        String result = process(req);
        req.setAttribute("result", result);
        // FORWARD: same request,
        // attributes preserved
        req.getRequestDispatcher(
            "/WEB-INF/views/result.jsp")
            .forward(req, resp);
    }
}

// BEST - PRG pattern for POST
// (redirect AFTER processing to
// prevent duplicate submission)
@WebServlet("/process")
public class ProcessServlet
        extends HttpServlet {
    protected void doPost(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws IOException {
        String result = process(req);
        // Store in session for redirect
        req.getSession()
            .setAttribute("result", result);
        // Redirect: prevents re-POST
        // on browser refresh
        resp.sendRedirect("/result");
    }
}
```

**How to verify:** Use browser developer tools Network tab. `forward()`: one request, URL unchanged. `sendRedirect()`: two requests, URL changes.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Server-side request routing - `forward()` delegates entirely, `include()` embeds another resource's output.

**PROBLEM IT SOLVES:** Enables MVC pattern (controller -> view), page composition (header/footer includes), and server-side routing without client round-trips.

**KEY INSIGHT:** `forward()` is the mechanism behind every Java MVC framework. Spring MVC, Struts, and JSF all forward to views internally.

**USE WHEN:** MVC pattern (forward to JSP/view). Page composition (include headers/footers). Server-side routing where URL should not change.

**AVOID WHEN:** After POST (use redirect to prevent duplicate submission). When the client needs to know the final URL. When data must survive a new request (use session or redirect with query params).

**ANTI-PATTERN:** Writing to response before forwarding. Using redirect when forward preserves needed data. Using forward after POST (causes duplicate submission on refresh).

**TRADE-OFF:** forward (fast, preserves data, URL unchanged) vs redirect (extra request, clean URL, prevents re-POST).

**ONE-LINER:** "forward delegates server-side, redirect delegates client-side."

**KEY NUMBERS:** forward: 0 extra HTTP requests. redirect: 1 extra HTTP request. include: 0 extra requests, additive output.

**TRIGGER PHRASE:** "forward for MVC views, redirect for post-redirect-get."

**OPENING SENTENCE:** "RequestDispatcher provides server-side request routing with forward() for full delegation and include() for content embedding - the mechanism underlying every Java MVC framework's controller-to-view handoff."

**If you remember only 3 things:**

1. forward() = server-side, same request, URL unchanged, attributes preserved
2. redirect = client-side, new request, URL changes, attributes lost
3. Use PRG (Post-Redirect-Get) pattern: forward for GET views, redirect after POST

**Interview one-liner:**
"RequestDispatcher.forward() transfers request processing server-side while preserving request attributes and URL, which is the mechanism behind Spring MVC's view resolution - while sendRedirect() triggers a client round-trip, used in the Post-Redirect-Get pattern to prevent duplicate form submissions on refresh."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe the difference between forward, include, and redirect with request lifecycle diagrams
2. **DEBUG:** Diagnose an `IllegalStateException` caused by writing to response before forward
3. **DECIDE:** Choose between forward (MVC view), redirect (PRG after POST), and include (page composition) for a given scenario
4. **BUILD:** Implement a Front Controller pattern with forwarding to multiple JSP views based on URL
5. **EXTEND:** Explain how Spring's InternalResourceViewResolver uses forward() internally and why views must be in WEB-INF

---

### 💡 The Surprising Truth

After `forward()` returns, the code in the calling servlet CONTINUES to execute. Many developers assume `forward()` is like `return` - it is not. Code after `forward()` runs, but cannot write to the response (it is already committed). This causes subtle bugs: cleanup code after `forward()` runs fine, but any attempt to modify the response throws `IllegalStateException`. Best practice: always `return` immediately after `forward()`.

```java
// SUBTLE BUG
req.getRequestDispatcher("/view.jsp")
    .forward(req, resp);
// This code RUNS but cannot
// write to the response
resp.getWriter().write("oops");
// IllegalStateException!
```

---

### ⚖️ Comparison Table

| Dimension          | forward()       | include()        | sendRedirect()  | AsyncContext.dispatch() |
| ------------------ | --------------- | ---------------- | --------------- | ----------------------- |
| HTTP requests      | 1               | 1                | 2               | 1 (async)               |
| URL changes        | No              | No               | Yes             | No                      |
| Request attributes | Preserved       | Preserved        | Lost            | Preserved               |
| Response control   | Target only     | Shared           | New response    | Target only             |
| After POST         | Avoid (re-POST) | OK for fragments | Preferred (PRG) | OK for async            |

**Rapid Decision Tree:**
IF MVC view rendering THEN forward().
IF page fragment composition THEN include().
IF after POST processing THEN sendRedirect() (PRG pattern).
IF completing async request THEN AsyncContext.dispatch().
IF client needs updated URL THEN sendRedirect().

---

### ⚠️ Common Misconceptions

| #   | Misconception                            | Reality                                                                                                              |
| --- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1   | forward() works like return              | Code after forward() still executes. Always add `return` after forward().                                            |
| 2   | forward() changes the URL                | The URL in the browser does NOT change. Only sendRedirect() changes the URL.                                         |
| 3   | include() can set response status        | The included resource cannot change the status code or response headers.                                             |
| 4   | redirect and forward are interchangeable | Redirect loses request attributes, causes an extra HTTP request, and changes the URL. They serve different purposes. |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: IllegalStateException on forward**

**Symptom:** `java.lang.IllegalStateException: Cannot forward after response has been committed`

**Root Cause:** The servlet wrote to the response (or flushed the buffer) before calling `forward()`. Once bytes are sent to the client, the response is committed and cannot be replaced.

**Diagnostic:**

```bash
# Search for output before forward
grep -n "getWriter\|getOutputStream\|flush" \
  *Servlet.java
# Check if JSP compilation added output
# (whitespace before <%@ directive)
```

**Fix:**

BAD: Increasing the response buffer size to delay commit

GOOD: Ensure no output is written before forward(). If using JSP includes that might write output, use `forward()` before any `include()`. Add `return` after `forward()`.

**Prevention:** Code review: any servlet that calls `forward()` must not call `getWriter()` or `getOutputStream()` before the forward.

**Failure Mode 2: Security bypass via direct JSP access**

**Symptom:** Users access JSP files directly via URL, bypassing controller authentication/authorization.

**Root Cause:** JSP files placed in a publicly accessible directory (e.g., `/views/`) instead of `/WEB-INF/views/`. The container serves them directly without going through the controller's security checks.

**Diagnostic:**

```bash
# Check JSP locations
find . -name "*.jsp" \
  | grep -v "WEB-INF"
# These are directly accessible!
```

**Fix:**

BAD: Adding security checks to every JSP

GOOD: Move all JSP files under `/WEB-INF/`. They can only be reached via `forward()` from a controller, which enforces authentication.

**Prevention:** Project convention: all view JSPs in `/WEB-INF/views/`. No JSPs in public directories.

**Failure Mode 3: Duplicate form submission after forward**

**Symptom:** User refreshes the browser after a POST-forward, and the form is re-submitted.

**Root Cause:** The browser remembers the last request was POST. Forward does not change this. Refreshing re-sends the POST.

**Diagnostic:**

```bash
# Check for forward after POST
grep -A5 "doPost" *Servlet.java \
  | grep "forward"
# These should be redirects
```

**Fix:**

BAD: Adding "are you sure?" JavaScript confirmations

GOOD: Use Post-Redirect-Get (PRG) pattern: after POST processing, `sendRedirect()` to a GET URL. Browser refresh now repeats the GET, not the POST.

**Prevention:** Code review rule: `doPost()` methods must end with `sendRedirect()`, never `forward()`.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Trade-off     | 60-120 seconds  | Decision framework   |
| Debugging     | 90-150 seconds  | Systematic diagnosis |

**Q1 [JUNIOR]: What is the difference between forward and redirect?**

_Why they ask:_ One of the most common servlet interview questions.
_Likely follow-up:_ "When would you use each one?"

**Answer:**
`forward()` and `sendRedirect()` both route requests to another resource, but they work fundamentally differently:

**forward() - server-side:** The servlet container internally routes the request to another resource (servlet, JSP, HTML file) on the same server. The client has no idea this happened - the browser URL does not change, and there is only one HTTP request. Request attributes set by the forwarding servlet are available to the target resource. The original request method (GET, POST) is preserved.

**sendRedirect() - client-side:** The server sends an HTTP 302 response telling the browser to make a NEW request to a different URL. The browser makes this second request, which is always a GET. The URL in the browser changes. Two HTTP requests occur. Request attributes from the first request are LOST because it is an entirely new request.

**When to use each:**

- **forward():** MVC pattern. Controller processes logic, sets request attributes, forwards to JSP for rendering. URL stays as `/orders` even though `/WEB-INF/views/orders.jsp` generates the HTML.
- **sendRedirect():** Post-Redirect-Get (PRG) pattern. After processing a form POST, redirect to a GET URL so browser refresh does not re-submit the form. Also used when routing to an external URL or a different web application.

The critical rule: never forward after POST. If a user submits a form and you forward to the result page, refreshing the browser re-submits the form. Always redirect after POST to prevent duplicate submissions.

_What separates good from great:_ Explaining PRG pattern and the duplicate-submission problem with forward-after-POST, not just the technical differences.

---

**Q2 [MID]: How does Spring MVC use RequestDispatcher internally?**

_Why they ask:_ Testing understanding of Spring's view resolution mechanism.
_Likely follow-up:_ "Why must JSP views be in WEB-INF?"

**Answer:**
Spring MVC's entire view-rendering pipeline is built on `RequestDispatcher.forward()`:

1. `DispatcherServlet` receives the request (it IS a servlet, mapped to `/`)
2. The handler adapter calls your `@Controller` method
3. The controller returns a view name (e.g., `"orders"`)
4. `InternalResourceViewResolver` resolves the name by prepending the prefix (e.g., `/WEB-INF/views/`) and appending the suffix (e.g., `.jsp`), producing `/WEB-INF/views/orders.jsp`
5. The resolver creates an `InternalResourceView` which calls `RequestDispatcher.forward(request, response)` to the resolved JSP path
6. The JSP renders using model attributes that Spring placed as request attributes

This is why JSP views MUST be in `/WEB-INF/`: they are not accessed directly by the client. The client requests `/orders`, the controller processes it, and the container forwards to the JSP internally. If the JSP were in a public directory, users could access it directly, bypassing the controller's security checks and seeing an empty page (no model attributes).

The model attributes that you add via `model.addAttribute("orders", orderList)` are placed as request attributes (`request.setAttribute()`) before the forward. This is the bridge between Spring's `Model` abstraction and the Servlet API's `RequestDispatcher` mechanism.

When you return `"redirect:/orders"` (with the `redirect:` prefix), Spring uses `sendRedirect()` instead of `forward()`. This is how Spring supports the PRG pattern. Similarly, `"forward:/other"` explicitly uses forward (though this is the default behavior).

_What separates good from great:_ Connecting model attributes to request attributes, explaining the WEB-INF security requirement, and knowing about the `redirect:` prefix for PRG.

---

**Q3 [SENIOR]: Explain the filter dispatch type interaction with forward.**

_Why they ask:_ Testing knowledge of a common security configuration issue.
_Likely follow-up:_ "Have you seen a security bypass caused by this?"

**Answer:**
This is a subtle and commonly misconfigured aspect of the Servlet specification that has caused real security vulnerabilities.

**The problem:** By default, a filter mapping applies only to `REQUEST` dispatch type. When a servlet forwards to a JSP, the forward operates under the `FORWARD` dispatch type. If a security filter is not configured for `FORWARD`, it does not execute for the forwarded request.

**The attack scenario:** An application has an `AuthFilter` protecting `/admin/*`. A public servlet at `/public/router` can forward to `/admin/dashboard.jsp`. If the AuthFilter only applies to `REQUEST` dispatch type, the forward bypasses it entirely - the user reaches the admin dashboard without authentication.

**The configuration:**

```xml
<!-- VULNERABLE: REQUEST only (default) -->
<filter-mapping>
    <filter-name>AuthFilter</filter-name>
    <url-pattern>/admin/*</url-pattern>
    <!-- default: REQUEST only -->
</filter-mapping>

<!-- SECURE: REQUEST + FORWARD -->
<filter-mapping>
    <filter-name>AuthFilter</filter-name>
    <url-pattern>/admin/*</url-pattern>
    <dispatcher>REQUEST</dispatcher>
    <dispatcher>FORWARD</dispatcher>
</filter-mapping>
```

With `@WebFilter`, use `dispatcherTypes`:

```java
@WebFilter(
    urlPatterns = "/admin/*",
    dispatcherTypes = {
        DispatcherType.REQUEST,
        DispatcherType.FORWARD
    })
```

**The dispatch types:** `REQUEST` (direct client request), `FORWARD` (via `RequestDispatcher.forward()`), `INCLUDE` (via `RequestDispatcher.include()`), `ERROR` (error page dispatch), `ASYNC` (async dispatch via `AsyncContext.dispatch()`).

Spring's `OncePerRequestFilter` handles this differently: it uses a request attribute flag to track whether the filter has already processed this request, regardless of dispatch type. This prevents double-execution on forward while still applying security on the original request.

In Spring Security, the `DelegatingFilterProxy` applies to `REQUEST` and `ASYNC` by default. Forwarded requests within the same application are typically already authorized (the original request was authenticated). But if you have non-Spring servlets that forward to Spring-protected resources, you need to add `FORWARD` to the dispatcher types.

_What separates good from great:_ Providing a concrete attack scenario, showing both vulnerable and secure configurations, and explaining how Spring Security handles this differently from raw servlet filters.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Servlet Fundamentals - the request/response model that dispatching extends
- Filters and Filter Chains - filter behavior changes with dispatch types
- Web Application Structure - WEB-INF protection and resource paths

**Builds on this (learn these next):**

- MVC Pattern with Servlets and JSP - dispatching is the enabling mechanism
- JSP Fundamentals and Lifecycle - the target of most forward operations
- Asynchronous Servlets - AsyncContext.dispatch() as async forward

**Alternatives / Comparisons:**

- Spring MVC view resolution - abstracts forward into view names
- React/Angular routing - client-side routing replaces server-side dispatching
- Server-side includes (SSI) - pre-servlet include mechanism
