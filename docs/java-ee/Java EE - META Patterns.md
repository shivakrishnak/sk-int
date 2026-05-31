---
layout: default
title: "Java EE - META Patterns"
parent: "Java EE"
nav_order: 16
permalink: /java-ee/meta-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 29 | [Enterprise Java Anti-Patterns](#enterprise-java-anti-patterns) | ★☆☆ |
| 30 | [Debugging Enterprise Java Applications](#debugging-enterprise-java-applications) | ★☆☆ |
| 31 | [Reading Legacy Java EE Code](#reading-legacy-java-ee-code) | ★☆☆ |

---

# Enterprise Java Anti-Patterns

**Interview Weight:** ★☆☆ - Recognition and avoidance.
Anti-patterns in enterprise Java are recurring solutions
that seem correct at first but cause maintenance,
performance, or reliability problems. Recognizing them
in legacy code and knowing the correct alternative
demonstrates senior-level judgment.

---

### 🎯 Model Answer

**30 seconds:**

> The most damaging enterprise Java anti-patterns:
> God Service (one EJB doing everything),
> Service Locator (manual JNDI lookup instead of injection),
> Entity as DTO (passing JPA entities across layers),
> Anemic Domain Model (entities with no behavior),
> and Transaction Scope Leak (entity manager used outside
> its transaction boundary). Each creates a class of
> bugs that are hard to diagnose without knowing the pattern.

**3 minutes:**

> Key anti-patterns and their symptoms:
>
> God Service (God EJB):
> - EJB with 50+ methods spanning multiple business domains
> - Causes: merge conflicts (everyone edits it), untestable,
>   coupling between unrelated concepts
> - Fix: split by bounded context (DDD)
>
> Service Locator:
> - Manual JNDI lookup inside EJBs instead of @Inject
> - Example: ctx.lookup("java:global/app/OrderRepository")
> - Causes: invisible dependencies, hard to test, tight coupling
> - Fix: use CDI @Inject for everything in the container
>
> Open Session in View (Hibernate anti-pattern):
> - Hibernate session left open across HTTP request/response cycle
> - Lazy-loading works in view layer but connection held too long
> - Causes: connection pool exhaustion under load
> - Fix: fetch required data before returning from service layer
>
> Entity as DTO:
> - JPA entity passed to web layer / serialized to JSON directly
> - Causes: unintended lazy load triggers, security exposure
>   of internal fields, tight coupling of DB schema to API
> - Fix: explicit DTOs with mapper (MapStruct)
>
> Stateful EJB for request scope:
> - @Stateful EJB used where @Stateless or CDI @RequestScoped fits
> - Causes: passivation overhead, memory pressure, session affinity
> - Fix: use @Stateless for stateless operations,
>   CDI @RequestScoped for request state

**Blank Mind Recovery:**

**(1) Anti-patterns list:** "God Service, Service Locator,
Open Session in View, Entity as DTO, Stateful EJB misuse."

**(2) Common symptom:** "Most anti-patterns show as:
hard to test, connection pool exhaustion, or hidden coupling."

**(3) Fix theme:** "CDI injection over JNDI. Explicit DTOs
over entity reuse. Lean scopes over heavyweight EJB."

---

### 📘 Concept Explanation

**Why Anti-Patterns Persist in Enterprise Java:**

Enterprise Java (EJB 2.x era) required verbose patterns
that became ingrained. EJB 3.0 and CDI simplified the
programming model, but legacy codebases carry old patterns
forward by copy-paste.

Anti-patterns map to eras:
- EJB 2.x era: Service Locator (no injection), Entity Bean
  (CMP - Container Managed Persistence, now gone)
- EJB 3.x era: Stateful EJB overuse, God Service
- JPA era: Open Session in View, Entity as DTO
- Modern: distributed monolith (microservices as anti-pattern)

---

### 💻 Code Example

```java
// ANTI-PATTERN 1: Service Locator
// BAD - manual JNDI lookup:
@Stateless
public class OrderServiceBad {

    public void createOrder(CreateOrderRequest req) {
        try {
            // Manual JNDI lookup - anti-pattern:
            InitialContext ctx = new InitialContext();
            // Hard-coded JNDI name, invisible dependency,
            // cannot be mocked in unit tests:
            InventoryService inventory =
                (InventoryService) ctx.lookup(
                    "java:global/myapp/InventoryService"
                );
            inventory.reduce(req);
        } catch (NamingException e) {
            throw new RuntimeException(e);
        }
    }
}

// GOOD - CDI injection:
@Stateless
public class OrderServiceGood {

    @Inject  // Container resolves at deploy time
    private InventoryService inventory;
    // Visible dependency, mockable in tests,
    // compile-time safe

    public void createOrder(CreateOrderRequest req) {
        inventory.reduce(req);  // Simple, clean
    }
}


// ANTI-PATTERN 2: Open Session in View
// BAD - Hibernate session open during view rendering:
// (typical in JSF or JAX-RS with lazy collections)
@Entity
public class Order {
    @OneToMany(fetch = FetchType.LAZY)  // lazy!
    private List<OrderItem> items;
    // getter...
}

// Service returns entity without fetching items:
@Stateless
public class OrderServiceBad {
    @PersistenceContext EntityManager em;

    public Order findById(Long id) {
        return em.find(Order.class, id);
        // items are NOT loaded here
    }
}

// JAX-RS layer tries to serialize items AFTER TX commits:
// This triggers lazy load OUTSIDE transaction ->
// LazyInitializationException!

// GOOD - fetch what you need:
@Stateless
public class OrderServiceGood {
    @PersistenceContext EntityManager em;

    public Order findById(Long id) {
        return em.createQuery(
            "SELECT o FROM Order o " +
            "LEFT JOIN FETCH o.items " +
            "WHERE o.id = :id", Order.class
        ).setParameter("id", id)
         .getSingleResult();
        // items are loaded within TX
    }
}


// ANTI-PATTERN 3: Entity as DTO
// BAD - return JPA entity from JAX-RS:
@GET
@Path("/{id}")
public Order getOrderBad(@PathParam("id") Long id) {
    return orderService.findById(id); // JPA entity!
    // Problems:
    // 1. Serializes ALL fields (including internal ones)
    // 2. May trigger lazy loads during serialization
    // 3. API contract tied to DB schema
    // 4. Cannot evolve DB without breaking API
}

// GOOD - explicit DTO:
@GET
@Path("/{id}")
public OrderDTO getOrderGood(@PathParam("id") Long id) {
    Order order = orderService.findById(id);
    // Explicit mapping (or MapStruct):
    return new OrderDTO(
        order.getId(),
        order.getStatus().name(),
        order.getTotal(),
        order.getItems().stream()
            .map(i -> new OrderItemDTO(
                i.getProductId(),
                i.getQuantity(),
                i.getPrice()
            )).collect(Collectors.toList())
    );
    // Only expose what the API contract needs
}
```

> **Code walkthrough:** The Service Locator comparison shows
> the hidden cost of JNDI: ctx.lookup returns Object, requiring
> unchecked cast; the JNDI name is a string constant that
> fails at runtime not compile time; and the InitialContext
> cannot be easily mocked. CDI @Inject resolves the dependency
> at deploy time with type safety. The Open Session in View
> anti-pattern causes LazyInitializationException: the Hibernate
> session is closed when the transaction commits (in the service
> layer), but the JAX-RS serializer tries to access lazy
> collections after. JOIN FETCH in the query loads everything
> needed while the transaction is active. The Entity as DTO
> pattern leaks internal state and creates API-DB coupling:
> adding a password field to the User entity would immediately
> expose it in the REST API if entities are returned directly.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Common enterprise Java anti-patterns I watch for:
> returning JPA entities directly from REST endpoints
> (use DTOs instead), using @Stateful EJB when the operation
> is stateless (use @Stateless), and manual JNDI lookups
> instead of @Inject. In code reviews I look for lazy
> loading issues: if an entity with lazy collections is
> returned from a service and serialized after the transaction
> ends, you get LazyInitializationException in production."

---

**Senior / Staff:**

> "The most insidious enterprise Java anti-patterns are
> the ones that work in dev and fail in production: Open
> Session in View works fine with H2 in-memory DB but
> causes connection pool exhaustion in production under load
> because Hibernate sessions hold connections. God Service
> works fine for a 5-person team but becomes a merge conflict
> bottleneck at 20 people. Anti-patterns are often solutions
> that optimize for speed now at the cost of maintenance later.
> My approach in code review: flag any method that does JNDI
> lookup, any JAX-RS endpoint returning a @Entity-annotated
> class, and any EJB with more than 10 public methods.
> These are near-certain anti-patterns."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Using @Stateful EJB is always wrong."**

@Stateful EJB has a legitimate use case: multi-step
business processes where state must survive multiple
client calls within a session. Shopping cart, multi-page
wizard, workflow state. The anti-pattern is using
@Stateful EJB for single-request operations or to share
state across users. CDI @SessionScoped is often a better
alternative for user-session state because it integrates
with the HTTP session lifecycle more naturally.

**Misconception 2: "JNDI lookup is always a Service Locator."**

JNDI lookup is required when integrating with legacy systems,
external resources (JMS connection factories, DataSources),
and when the CDI container is not available (e.g., in a
static utility or a thread that the container doesn't manage).
The Service Locator anti-pattern is the use of JNDI
inside managed beans where CDI injection would work.
There are legitimate uses of JNDI lookups at the boundary
of the container.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: LazyInitializationException in production**

*Symptom:* `org.hibernate.LazyInitializationException:
failed to lazily initialize a collection of role: Order.items`
Appears in REST response serialization, not in DB query.

*Diagnosis:*
```bash
# Find stack trace - it points to serialization, not service:
# jackson.databind.ser... -> Order.getItems() ->
# HibernateProxy.initialize -> LazyInitializationException

# Check: does Order.items have FetchType.LAZY?
grep -rn "FetchType.LAZY\|@OneToMany\|@ManyToMany" src/
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Add JOIN FETCH to query, or use @EntityGraph to
define fetch strategy per use case.

---

**Failure 2: Connection pool exhaustion from Open Session**

*Symptom:* Application slows gradually under load.
Timeouts acquiring DB connections. Thread dump shows
many threads waiting for connection.

*Diagnosis:*
```bash
# Check Hibernate statistics (enable in persistence.xml):
# hibernate.generate_statistics=true
# Look for: connections.obtained >> connections.released

# Or DataSource pool stats:
# HikariCP exposes: /actuator/metrics/hikaricp.connections.active
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | N+1, LazyInitializationException, connection pool exhaustion |
| Trade-off | 1 | Eager vs. lazy loading trade-offs |
| Failure Mode | 2 | Diagnosing pool exhaustion, N+1 in production |
| Debugging | 1 | Reading Hibernate statistics output |
| Behavioral | 1 | Fixing legacy code with multiple anti-patterns |

**Q1. What is the N+1 select problem and how do you detect
and fix it in a Jakarta EE application?**

N+1: loading a list of N entities, then for each entity executing
a separate query to load a related association. Total queries: 1 + N.
At N=1000, this is 1001 queries instead of 1-2 with a JOIN.

Detection:
```java
// Enable Hibernate statistics:
// In persistence.xml:
<property name="hibernate.generate_statistics" value="true"/>
// Or programmatically:
SessionFactory sf = em.unwrap(SessionFactory.class);
Statistics stats = sf.getStatistics();
stats.setStatisticsEnabled(true);

// After the operation:
long queryCount = stats.getQueryExecutionCount();
// If queryCount >> expected: N+1 is happening

// In Quarkus/Spring: enable Hibernate SQL logging:
// quarkus.hibernate-orm.log.sql=true
// Shows every SQL statement with parameters
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix:
```java
// OPTION 1: JOIN FETCH in JPQL
@NamedQuery(
  name = "Order.withItems",
  query = "SELECT o FROM Order o JOIN FETCH o.items WHERE o.id = :id"
)
// Generates single query with JOIN

// OPTION 2: Entity Graph
@EntityGraph(attributePaths = {"items", "items.product"})
Optional<Order> findById(Long id);

// OPTION 3: Batch size (reduces to 1 + N/batchSize queries)
@OneToMany
@BatchSize(size = 20)
private List<OrderItem> items;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Knowing that JOIN FETCH and
`@EntityGraph` solve N+1 but can cause a different problem:
Cartesian product explosion when fetching multiple collection
associations simultaneously. Fetching `order.items` AND
`order.documents` in one JOIN creates rows * rows. Use multiple
queries or `@BatchSize` for multiple collections.

---

**Q2. What causes `LazyInitializationException` in Hibernate
and what are the three canonical fixes?**

Cause: a persistent entity with `FetchType.LAZY` association is
accessed after the JPA persistence context (EntityManager) has been
closed. Hibernate cannot proxy-initialize the association because
there is no active session.

Typical pattern:
```java
// Transaction boundary closes EntityManager:
@Transactional
public Order loadOrder(Long id) {
    return orderRepo.findById(id).orElseThrow();
}
// EntityManager closed when @Transactional method returns

// Later, in a controller or serialiser:
order.getItems().size(); // CRASH: LazyInitializationException
// No active session to load items
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix 1 - Eager fetch within transaction:
```java
@Transactional
public Order loadOrderWithItems(Long id) {
    Order o = orderRepo.findById(id).orElseThrow();
    Hibernate.initialize(o.getItems()); // force load while in session
    return o;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix 2 - DTO projection (no proxy, pure data):
```java
@Query("SELECT new OrderDTO(o.id, o.status, i.id, i.quantity) "
     + "FROM Order o JOIN o.items i WHERE o.id = :id")
List<OrderDTO> findOrderProjection(@Param("id") Long id);
// DTO has no associations, no proxy, no LazyInitializationException
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix 3 - `spring.jpa.open-in-view=false` (anti-fix warning):
Open Session in View keeps EntityManager open for the entire
HTTP request. Appears to fix LazyInitializationException but hides
the N+1 problem and keeps DB connections open for the full
request lifecycle. Disable it and fix the actual fetch strategy.

*What separates good from great:* Recommending DTO projections as
the production-correct fix. They are faster (no proxy overhead,
no hibernate-loaded graph), explicit about what data is fetched,
and completely immune to LazyInitializationException.

---

**Q3. What is connection pool exhaustion in a Java EE app and
how do you prevent it?**

Pool exhaustion: all connections in the pool are acquired but not
released. New requests wait (then timeout) because no connection
is available. Usually caused by: connection not closed after use,
transaction not committed/rolled back, long-running queries holding
connections for minutes.

Detection:
```bash
# HikariCP metrics (if Spring Boot Actuator enabled):
curl localhost:8080/actuator/metrics/hikaricp.connections.active
# active = connections in use
# pending = threads waiting for a connection
# If pending > 0: pool exhaustion in progress

# WildFly datasource pool stats:
/subsystem=datasources/data-source=ExampleDS:read-resource(include-runtime=true)
# Look for: ActiveCount == MaxPoolSize, WaitCount > 0
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Prevention:
```java
// ALWAYS close in finally (or use try-with-resources):
try (Connection conn = dataSource.getConnection()) {
    // use connection
} // auto-closes

// In EJB/CDI: @Transactional handles close automatically
// DANGER: calling non-transactional code that opens EntityManager
// without @Transactional = connection not returned to pool

// Set connection timeout to get fast failure instead of hanging:
// HikariCP:
hikari.connectionTimeout=3000 // 3s wait, then fail fast
hikari.maxLifetime=1800000   // 30min max age, prevents stale connections
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The distinction between pool
exhaustion (active == max) and pool leak (active grows over time,
never decreases even at low load). Pool leak means connections are
being acquired and not released. Pool exhaustion can happen on
legitimate high load. Different root causes, different fixes.

---

**Q4. What is EJB over-use (over-EJB-ification) and what are
the symptoms?**

Over-EJB-ification: using EJBs (typically `@Stateless`) for every
object in the application, treating EJB as a service wrapper for
any logic, not just infrastructure services.

Symptoms:
- 50+ EJB classes in a medium-sized application
- EJBs that contain no infrastructure logic (no transaction,
  no security, no pooling need)
- EJB injection chains: EJB-A injects EJB-B injects EJB-C...
  for simple business logic
- Slow local tests (EJB deployment required for unit test)
- Complex XML deployment descriptors listing every EJB

Root cause: Java EE 2.x patterns propagated into modern code.
In EE 2.x, EJB was required for transactions. In Jakarta EE,
`@Transactional` works on any CDI bean. EJB is now needed only
for: pooling (Stateless bean pool), `@Schedule`, `@Asynchronous
(legacy)`, and remote invocation (RMI/IIOP - rare in modern apps).

Fix direction: replace `@Stateless` with `@ApplicationScoped` or
`@RequestScoped` CDI beans. Keep `@Transactional`. Remove EJB
where CDI provides equivalent.

*What separates good from great:* Knowing the remaining legitimate
EJB use cases. `@MessageDriven` beans (MDB) are the canonical
EJB use case in 2024 - they integrate with JMS queues and have
no CDI equivalent in the full Jakarta EE spec.

---

**Q5. DEBUGGING: Your application is running out of database
connections at production load. How do you diagnose
systematically?**

Step 1: Confirm pool exhaustion (not other cause):
```bash
# Check error message:
# HikariCP: "Connection is not available, request timed out after Xms"
# WildFly: "javax.resource.ResourceException: No ManagedConnections"
# These confirm pool exhaustion (not connectivity)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 2: Check pool metrics during the incident:
```bash
# Spring Boot Actuator:
curl /actuator/metrics/hikaricp.connections.active
curl /actuator/metrics/hikaricp.connections.pending
# active = pool_max: exhausted
# pending > 0: confirmed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 3: Find which code holds connections longest:
```bash
# Enable Hikari connection leak detection:
hikari.leakDetectionThreshold=10000 # 10s - logs stack trace
# Log output:
# "Connection leak detection triggered for <stacktrace>"
# Stack trace shows exactly where the connection was acquired
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 4: Thread dump to see what active transactions are doing:
```bash
jstack <pid> | grep -A 20 "jdbc"
# Or in WildFly CLI:
/core-service=management/service=management-operations:read-resource
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The leak detection threshold.
Setting it to 2x the expected maximum query time catches connections
held longer than expected. A connection acquired 10s ago during a
normal query cycle is a leak candidate. This catches the problem
before the pool is fully exhausted.

---

**Q6. What is the anemic domain model anti-pattern and when
does it appear in Java EE applications?**

Anemic domain model: domain entities (JPA Entities) contain only
fields and getters/setters. All business logic lives in `@Stateless`
Service EJBs. The entity is a data container, not an object.

Symptoms:
```java
// ANEMIC: entity has no behaviour
@Entity
public class Order {
    private String status;
    // Only getters/setters...
}

// ANEMIC: all logic in service
@Stateless
public class OrderService {
    public void cancelOrder(Order order) {
        if (!order.getStatus().equals("PENDING")) {
            throw new IllegalStateException();
        }
        order.setStatus("CANCELLED");
        // ... 50 more lines of business logic
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Problems: business rules scattered across services, duplicated
checks, entity invariants not enforced by the entity itself.

Fix direction (rich domain model):
```java
@Entity
public class Order {
    private String status;
    // Behaviour on the entity:
    public void cancel() {
        if (!status.equals("PENDING"))
            throw new IllegalStateException();
        this.status = "CANCELLED";
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Knowing when anemic is acceptable.
For report-only queries and data transfer, anemic DTOs (not entities)
are correct by design. The anti-pattern is specifically applying the
anemic pattern to domain entities that SHOULD enforce business rules.

---

**Q7. What is the TRADE-OFF between `FetchType.EAGER` and
`FetchType.LAZY` and when should you use each?**

| Dimension | EAGER | LAZY |
|---|---|---|
| LazyInitializationException | Never | Common if misused |
| N+1 risk | None (loaded with parent) | Yes, if accessed in loop |
| Memory usage | High (always loads graph) | Lower (loads on demand) |
| Unnecessary data | Loaded even when not needed | Not loaded until accessed |
| Query complexity | JOIN on every load | Simple primary key loads |

Decision:
- `FetchType.EAGER`: `@ManyToOne` pointing to frequently-accessed
  parent entities with low data volume (User.department - you almost
  always need the department).
- `FetchType.LAZY`: `@OneToMany` collections (Order.items - you
  often list orders without needing all items). Always the safer
  default for collections.

JPA default: `@ManyToOne` defaults to EAGER. `@OneToMany` defaults
to LAZY. The defaults make sense for typical access patterns.

*What separates good from great:* Knowing that Hibernate's
implementation of EAGER does not always use a JOIN. Hibernate may
execute a separate SELECT even for EAGER associations depending on
the query origin. The only guarantee of a JOIN is `JOIN FETCH`
explicitly in the JPQL query.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - comparison table not applicable for
a list of anti-patterns where each has its own trade-offs.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword - anti-patterns meta knowledge,
no system design applicable.)*

---

### 📊 Diagram

*(Omit: Enterprise Java anti-patterns are code patterns,
not visual flows. No diagram applicable.)*

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


# Debugging Enterprise Java Applications

**Interview Weight:** ★☆☆ - Foundational diagnostic skill.
Knowing how to diagnose issues in Java EE application
servers is essential for any developer working in
enterprise Java. The tools and commands are different
from simple Spring Boot debugging.

---

### 🎯 Model Answer

**30 seconds:**

> Enterprise Java debugging uses three layers: application
> logs (CDI/EJB, exceptions), application server logs (WildFly
> server.log for deployment errors, transaction logs),
> and JVM diagnostics (thread dumps, heap dumps, GC logs).
> For production issues: start with logs, escalate to thread
> dumps for stuck threads, heap dumps for OutOfMemoryError,
> and flight recorder for intermittent issues.

**3 minutes:**

> Debugging workflow:
>
> Level 1 - Application logs:
> - Set logging to DEBUG for specific packages
> - WildFly: `standalone/log/server.log`
> - Filter by timestamp, exception type, correlation ID
>
> Level 2 - Application server diagnostics:
> - WildFly: Management CLI for live server state
>   `deployment info`, `transaction info`, `datasource statistics`
> - JBoss CLI: `/deployment=myapp.war:read-attribute(name=status)`
>
> Level 3 - JVM diagnostics:
> - Thread dump: `jstack <pid>` or kill -3
>   Look for: BLOCKED threads (lock contention),
>   threads WAITING on connection pool
> - Heap dump: `jmap -dump:format=b,file=heap.hprof <pid>`
>   Analyze in VisualVM or Eclipse Memory Analyzer (MAT)
>
> Level 4 - Remote debugging:
> - WildFly: add --debug 8787 to startup
> - Suspend: add suspend=y to wait for debugger attachment
> - IDE: Remote Java Application debug configuration
>
> Common issues and first diagnosis step:
> - OutOfMemoryError: heap dump + MAT dominator tree
> - Transaction timeout: server.log for "Transaction timed out"
> - DeploymentException: server.log + `--debug` deployment
> - ClassNotFoundException: classloader analysis

**Blank Mind Recovery:**

**(1) Layers:** "App logs -> server logs -> JVM diagnostics
(thread dump, heap dump) -> remote debugger."

**(2) Fastest first:** "99% of issues are in app logs.
Start there, escalate only if needed."

**(3) Key commands:** "jstack for threads, jmap for heap,
WildFly CLI for server state."

---

### 📘 Concept Explanation

**WildFly Log Architecture:**

```
src/main/resources/META-INF/
  persistence.xml  (JPA config)

WildFly runtime logs:
  standalone/log/server.log  (all server events)
  standalone/log/audit.log   (security events)

Application log config (standalone.xml):
  <subsystem xmlns="urn:jboss:logging">
    <root-logger>
      <level name="INFO"/>
    </root-logger>
    <logger category="com.example.order">
      <level name="DEBUG"/>
    </logger>
  </subsystem>

Or at runtime via CLI (no restart needed):
  /subsystem=logging/logger=com.example:add
  /subsystem=logging/logger=com.example:
    write-attribute(name=level,value=DEBUG)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```bash
# ----- LEVEL 1: APPLICATION LOGS -----

# Tail WildFly server log:
tail -f standalone/log/server.log

# Filter for specific app package errors:
grep "com.example.order" standalone/log/server.log \
  | grep -E "ERROR|WARN" | tail -50

# Filter for specific transaction:
grep "correlationId=abc123" standalone/log/server.log


# ----- LEVEL 2: WILDFLY CLI DIAGNOSTICS -----

# Connect to WildFly management CLI:
bin/jboss-cli.sh --connect

# Check deployment status:
deployment info --name=myapp.ear

# Check datasource statistics:
/subsystem=datasources/data-source=ExampleDS:
  read-attribute(name=statistics-enabled)
# Enable stats (if not enabled):
/subsystem=datasources/data-source=ExampleDS:
  write-attribute(name=statistics-enabled,value=true)
# Get pool stats:
/subsystem=datasources/data-source=ExampleDS/statistics=pool:
  read-resource(include-runtime=true)
# Look for: ActiveCount, AvailableCount, TimedOut

# Check active transactions:
/subsystem=transactions:read-attribute(
  name=number-of-inflight-transactions
)


# ----- LEVEL 3: JVM DIAGNOSTICS -----

# Find WildFly PID:
jps -l | grep "jboss\|wildfly"

# Thread dump (shows all threads and their state):
jstack <pid> > thread_dump.txt

# Analyze thread dump:
grep -A 5 "BLOCKED\|waiting to lock" thread_dump.txt
# BLOCKED = lock contention (deadlock risk)
# "waiting to lock <0x...>" = what lock

# Heap histogram (no heap dump needed):
jmap -histo:live <pid> | head -30
# Shows: instances, bytes, class name
# Largest classes by byte count = memory suspects

# Full heap dump (larger file, needed for MAT analysis):
jmap -dump:format=b,file=/tmp/heap_$(date +%s).hprof <pid>
# WARN: pauses JVM (potentially minutes for large heaps)

# Heap analysis with Eclipse MAT:
# Open heap.hprof in MAT -> Leak Suspects Report
# Dominator tree: shows what holds most memory


# ----- LEVEL 4: REMOTE DEBUGGING -----

# Start WildFly with debug enabled (port 8787):
# Edit standalone.conf:
# JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,
#   address=*:8787,server=y,suspend=n"
# suspend=n: server starts without waiting for debugger
# suspend=y: server waits for debugger (for startup issues)

# Or launch directly:
bin/standalone.sh --debug 8787

# IDE Remote Debug (IntelliJ IDEA):
# Run -> Edit Configurations -> Remote JVM Debug
# Host: server-hostname, Port: 8787
# Set breakpoints -> Connect -> Debug as normal


# ----- TRANSACTION DEBUGGING -----

# Enable transaction trace logging:
/subsystem=logging/logger=com.arjuna.ats:add
/subsystem=logging/logger=com.arjuna.ats:
  write-attribute(name=level,value=TRACE)

# Transaction timeout diagnostic:
grep "ARJUNA016051\|Transaction timed out" \
  standalone/log/server.log
# ARJUNA016051 = transaction timeout code
# Shows: which TX timed out, duration, thread


# ----- CDI/EJB INJECTION DEBUG -----

# CDI deployment descriptor (checks CDI is active):
# WildFly: check META-INF/beans.xml is present
# Missing beans.xml = CDI not enabled for archive

# EJB not found error:
grep "WFLYEJB\|EJBException\|NoSuchEJBException" \
  standalone/log/server.log

# Check deployed EJBs:
bin/jboss-cli.sh --connect --command=\
  "/deployment=myapp.ear/subdeployment=ejb.jar/
  subsystem=ejb3:read-resource(recursive=true)"
```

> **Code walkthrough:** The diagnostic progression mirrors
> real incident response: start with log grepping (seconds),
> escalate to CLI statistics (minutes), then JVM tools (longer).
> The WildFly CLI datasource statistics command is critical for
> diagnosing connection pool exhaustion: ActiveCount near
> AvailableCount = pool is full = incoming requests will timeout.
> The thread dump analysis target is "BLOCKED" threads: a thread
> blocked on a lock it cannot acquire. If multiple threads are
> blocked on the same lock, it may be a deadlock. jmap -histo
> is safe for production (reads heap without dumping the full
> file); jmap -dump pauses the JVM and should be used carefully.
> Remote debugging with suspend=y is essential for debugging
> deployment failures that happen during CDI initialization.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "For debugging Java EE applications, I start with the
> application server log (WildFly standalone/log/server.log).
> Most errors are logged there. For production issues like
> OutOfMemoryError or thread deadlocks, I use jstack for
> thread dumps and jmap for heap dumps, then analyze in
> VisualVM or Eclipse MAT. For remote debugging I add the
> JDWP agent to the server startup and connect from the IDE."

---

**Senior / Staff:**

> "Enterprise Java debugging requires knowing three layers.
> Application logs tell you what the business logic did.
> Application server logs tell you what the container did
> (deployment, transactions, security). JVM diagnostics
> tell you what the JVM is doing (GC, threads, memory).
> WildFly's CLI is particularly useful for live production
> diagnosis without restarts: I can enable DEBUG logging for
> specific packages, check datasource pool stats, and query
> inflight transaction count in real time. For intermittent
> issues that don't reproduce under debugger, Java Flight
> Recorder is the right tool: it records JVM state continuously
> with < 1% overhead, and you can dump the last 60 seconds
> of state when an incident occurs."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Adding TRACE logging is always safe."**

TRACE logging in production can cause: (1) log volume
so high that disk fills up (2) log writes contend on
I/O and slow the application (3) sensitive data (passwords,
tokens) written to log files. For production trace logging,
use: sampling (log 1 in 100 requests), async log appender,
and ensure log files are not accessible to unauthorized users.
Always revert TRACE logging after diagnosis.

**Misconception 2: "A thread dump is enough to diagnose all
concurrency issues."**

Thread dumps capture one instant. Intermittent deadlocks
or race conditions may not be visible in a single dump.
Take 3-5 thread dumps 10 seconds apart and compare. If
the same threads are BLOCKED across dumps: deadlock.
If they're progressing: transient contention. Java Flight
Recorder captures all lock events over time, which is
more complete for diagnosing intermittent concurrency issues.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: DeploymentException - CDI ambiguous dependency**

*Symptom:* Application fails to deploy with:
`WELD-001409: Ambiguous dependencies for type X`

*Diagnosis:*
```bash
grep "WELD-001409\|Ambiguous" \
  standalone/log/server.log
# Shows: which type has multiple candidates
# and which beans are the candidates
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Add @Qualifier to disambiguate, or use @Alternative
to select specific implementation.

---

**Failure 2: ClassLoader hell - ClassNotFoundException
after deployment**

*Symptom:* `ClassNotFoundException: com.example.MyClass`
even though the class is in the JAR.

*Root cause:* WildFly module isolation. Class is deployed
in one module (EAR lib) but loaded by different classloader.

*Diagnosis:*
```bash
# Enable classloader debugging:
# JAVA_OPTS="${JAVA_OPTS} -verbose:class"
# Grep for the class not found:
grep "com.example.MyClass" server.log

# Check module dependencies in jboss-deployment-structure.xml
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | Thread dump reading, WildFly CLI, heap analysis |
| Trade-off | 1 | Thread dump vs heap dump timing |
| Failure Mode | 2 | Server hang diagnosis, memory leak detection |
| Debugging | 2 | jstack workflow, jcmd heap histogram |

**Q1. How do you take a thread dump from WildFly and what
do you look for in the output?**

```bash
# Method 1: jstack (attaches to JVM process)
jps   # find WildFly PID, e.g. 12345
jstack 12345 > thread-dump.txt

# Method 2: WildFly management CLI
/core-service=platform-mbean/type=threading:dump-all-threads(
    locked-monitors=true, locked-synchronizers=true)

# Method 3: kill -3 (SIGQUIT) - writes to stdout/log
kill -3 12345  # WildFly must be started with console output
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

What to look for:
- **BLOCKED threads**: waiting to acquire a monitor held by
  another thread. Multiple BLOCKED threads on the same object
  = lock contention. 2 threads each holding the other's lock
  = deadlock (Java reports this explicitly: "Java-level deadlock").
- **Threads in TIMED_WAITING**: expected (sleep, wait with timeout).
- **Threads all WAITING on same lock**: serialisation bottleneck.
- **Thread count growing**: thread leak (new threads created,
  not returned to pool).

Key thread name patterns in WildFly:
- `default task-N`: EJB/CDI managed executor threads
- `EJB default pool-N`: EJB async method threads
- `pool-N-thread-M`: JMS, timer, and scheduled threads

*What separates good from great:* Knowing to take 3 thread dumps
10 seconds apart. A thread BLOCKED in only one snapshot may be
stransient. A thread BLOCKED in all three snapshots is genuinely
stuck. This eliminates false positives from timing coincidences.

---

**Q2. What is the WildFly management CLI and what can you
diagnose with it without restarting the server?**

```bash
# Connect to WildFly CLI:
$JBOSS_HOME/bin/jboss-cli.sh --connect

# Key diagnostic commands:
# 1. Check datasource connection pool:
/subsystem=datasources/data-source=ExampleDS/statistics=pool:read-resource(include-runtime=true)
# Shows: ActiveCount, AvailableCount, MaxUsedCount, WaitCount, TimedOut

# 2. Check active transactions:
/subsystem=transactions:read-attribute(name=number-of-inflight-transactions)
# Growing = transactions not completing

# 3. List deployed applications:
deployment-info

# 4. View recent server errors:
/subsystem=logging/log-file=server.log:read-log-file(
    lines=100, skip=0, tail=true)

# 5. Enable statistics at runtime (without restart):
/subsystem=datasources/data-source=ExampleDS:
  write-attribute(name=statistics-enabled, value=true)

# 6. Reload config changes (without restart):
reload
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `statistics-enabled=true`
command is runtime-changeable. You can enable pool statistics
during an incident without a server restart, gather the data,
then disable to reduce overhead. Most engineers assume statistics
require a restart.

---

**Q3. How do you read Hibernate SQL statistics and what do
the key numbers mean?**

```java
// Enable Hibernate statistics:
// persistence.xml:
<property name="hibernate.generate_statistics" value="true"/>
// Quarkus: quarkus.hibernate-orm.statistics=true

// Read at runtime:
SessionFactory sf = entityManager.unwrap(SessionFactory.class);
Statistics stats = sf.getStatistics();

// Key counters:
stats.getQueryExecutionCount()     // total JPQL/SQL executions
stats.getQueryExecutionMaxTime()   // slowest query (ms)
stats.getQueryExecutionMaxTimeQueryString() // which query
stats.getEntityLoadCount()         // entity instances loaded
stats.getCollectionLoadCount()     // collection loads
stats.getSecondLevelCacheHitCount() // L2 cache hits
stats.getSecondLevelCacheMissCount() // L2 cache misses
stats.getConnectCount()            // DB connections obtained
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

N+1 detection: `queryExecutionCount >> expectedCount`.
If loading 20 orders produces 200 query executions = N+1 on items.

Cache diagnosis: `cacheHitCount / (cacheHitCount + cacheMissCount)`.
Hit rate < 50% on a read-heavy entity = cache too small or
cache key collisions.

*What separates good from great:* Exporting statistics to Micrometer/
Prometheus and setting alerts. One-time manual reads catch the problem
after the fact. Continuous export catches it during gradual regression.

---

**Q4. What is the difference between a heap histogram and a
full heap dump, and when do you use each?**

Heap histogram (`jcmd <pid> GC.heap_info` or `jmap -histo <pid>`):
- Lists all classes with instance count and total bytes
- Takes < 1 second, minimal pause
- Shows WHAT is taking memory (class names, counts)
- Does NOT show object references or why objects are retained
- Use for: quick check of memory distribution, initial triage

Full heap dump (`jcmd <pid> GC.heap_dump filename.hprof`):
- Complete snapshot of all live objects and references
- File size = heap size (can be GB), significant GC pause (seconds)
- Required for: finding WHAT is holding a reference to the
  large objects (the retention path)
- Use for: confirmed memory leak investigation, OOM post-mortem

Workflow:
```bash
# Step 1: quick histogram to confirm candidate class:
jcmd <pid> GC.heap_info
# Output: 12345678 bytes: [B (byte array) - suspicious if growing

# Step 2: only if histogram is inconclusive, take full dump:
jcmd <pid> GC.heap_dump /tmp/heap.hprof
# Analyse with Eclipse MAT or VisualVM
# MAT: Leak Suspects Report identifies retention path automatically
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Always starting with the histogram.
A full heap dump on a 4GB heap causes a multi-second GC pause that
may trigger a health check failure and pod restart. The histogram
answers 80% of memory questions without the risk.

---

**Q5. DEBUGGING: Your WildFly server handles requests but
responds very slowly. How do you diagnose systematically?**

Step 1: Thread dump (is the slowness CPU or waiting?):
```bash
jstack <pid> | grep -c "RUNNABLE"
# High RUNNABLE count during slowness = CPU bottleneck
# All TIMED_WAITING or WAITING = threads blocked on I/O or locks
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 2: If threads BLOCKED (lock contention):
```bash
# Find the lock owner:
jstack <pid> | grep -A 5 "BLOCKED"
# "waiting to lock <0x...>" shows the monitor address
# Search for that address to find the owner thread and what it is doing
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 3: If threads WAITING on datasource:
```bash
# Check pool stats (without restart):
/subsystem=datasources/data-source=ExampleDS/statistics=pool:
    read-resource(include-runtime=true)
# WaitCount > 0 = pool exhaustion causing slowness
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Step 4: If no thread contention, check GC:
```bash
jstat -gcutil <pid> 1000 10  # GC stats every 1s, 10 samples
# FGC (full GC) count growing: GC overhead is the bottleneck
# Time in GC > 5% of elapsed time: memory tuning needed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The sequencing. Most engineers
check database first. Thread dumps are faster and tell you whether
the bottleneck is CPU, locks, I/O, or GC before you look at
any application-level data.

---

**Q6. How do you enable remote debugging for a WildFly-deployed
application?**

```bash
# Option 1: Modify standalone.conf (persistent):
# Add to JAVA_OPTS:
JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,\
  address=*:8787,server=y,suspend=n"

# suspend=n: server starts immediately (use for attach-on-demand)
# suspend=y: server waits for debugger to connect at startup
#            (use for debugging startup failures)

# Option 2: Environment variable (Kubernetes/container):
JAVA_OPTS_EXTRA="-agentlib:jdwp=transport=dt_socket,\
  address=*:8787,server=y,suspend=n"

# Option 3: WildFly CLI (no restart needed in some versions):
/core-service=platform-mbean/type=runtime:
  get-system-properties  # check if already set
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

IntelliJ IDEA remote debug config:
- Run -> Edit Configurations -> Remote JVM Debug
- Host: `server-hostname`, Port: `8787`
- Debugger mode: Attach to remote JVM

Security consideration: JDWP exposes full JVM control. Never
enable it on a public network interface. Use an SSH tunnel:
```bash
ssh -L 8787:localhost:8787 server-host
# Connect IDEA to localhost:8787 - tunnelled to server
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The SSH tunnel pattern. Exposing
JDWP directly to the network is a critical security vulnerability
(full JVM code execution, memory read). Always tunnel in production.

---

**Q7. What transaction timeout diagnostic information appears
in WildFly logs and how do you use it?**

```bash
# WildFly transaction timeout log pattern:
ARJUNA016051: Transaction JBossTS... has timed out after 60 seconds
ARJUNA016039: No XAResourceRecord found for transaction <ID>

# The ARJUNA codes map to Narayana transaction manager:
# ARJUNA016051 = transaction timeout
# ARJUNA016039 = XA resource not found during recovery
# ARJUNA012095 = application exception causing rollback

# Extract timing information:
grep "ARJUNA016051" server.log | awk '{print $1, $2, $NF}'
# Shows: timestamp, transaction ID, timeout duration
# If duration < configured timeout: check for explicit rollbackOnly
# If duration == configured timeout: operation genuinely timed out

# Find which thread/operation timed out:
grep -A 10 "ARJUNA016051" server.log
# Usually followed by stack trace showing the slow operation
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Tuning transaction timeout:
```xml
<!-- In standalone.xml -->
<subsystem xmlns="urn:jboss:domain:transactions:6.0">
    <coordinator-environment default-timeout="120"/>
    <!-- 120s default; per-bean override via @TransactionTimeout -->
</subsystem>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Knowing ARJUNA error codes.
A search for `ARJUNA016051` immediately identifies transaction
timeouts in logs. Operations teams without this knowledge grep
for `ERROR` and miss timeout events that log at WARN level.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - debugging commands comparison
is context-specific. No comparison table applicable.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword - debugging practices, no system
design applicable.)*

---

### 📊 Diagram

*(Omit: debugging workflow is a decision tree better
described in prose. No diagram applicable.)*

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


# Reading Legacy Java EE Code

**Interview Weight:** ★☆☆ - Practical navigation skill.
Any engineer joining an organization with existing Java EE
code must be able to read and understand it quickly.
This meta-skill covers EJB annotations, deployment descriptors,
and the mental models needed to trace execution flow.

---

### 🎯 Model Answer

**30 seconds:**

> Reading legacy Java EE code: start at the entry point
> (servlet or JAX-RS resource), follow @Inject and @EJB
> annotations to find dependencies, check persistence.xml
> for data source, and check jboss-deployment-structure.xml
> or application.xml for module structure. EJB 2.x code
> (pre-2006) uses XML descriptors (ejb-jar.xml); EJB 3.x+
> uses annotations. Transaction boundaries are usually
> at the @Stateless EJB method level.

**3 minutes:**

> Orientation checklist for legacy Java EE codebase:
>
> 1. Identify the entry points:
>    - Servlets (web.xml or @WebServlet)
>    - JAX-RS resources (@Path)
>    - MDB (Message-Driven Beans) - @MessageDriven
>    - EJB timers (@Schedule)
>
> 2. Find the service layer:
>    - @Stateless EJBs = stateless services
>    - @Stateful EJBs = multi-step flows
>    - CDI @ApplicationScoped = singletons
>    - @Inject and @EJB annotations show wiring
>
> 3. Find the persistence layer:
>    - @PersistenceContext EntityManager - JPA
>    - persistence.xml - datasource binding
>    - Named queries: @NamedQuery on entities
>
> 4. Understand transactions:
>    - Default: @TransactionAttribute(REQUIRED)
>    - All @Stateless EJB methods are transactional by default
>    - @TransactionAttribute(NOT_SUPPORTED) = no TX
>
> 5. Security:
>    - @RolesAllowed on EJB methods
>    - web.xml <security-constraint> for URL patterns
>
> 6. EJB 2.x signs (very old code):
>    - classes extend javax.ejb.SessionBean
>    - ejb-jar.xml with <ejb-class>, <home>, <remote>
>    - ejbCreate() methods

**Blank Mind Recovery:**

**(1) Reading order:** "Entry point (Servlet/@Path) -> Service
(@Stateless/@EJB) -> Repository (@PersistenceContext) -> DB."

**(2) Key files:** "persistence.xml, web.xml, ejb-jar.xml
(old), jboss-deployment-structure.xml (WildFly-specific)."

**(3) Transaction default:** "Every @Stateless EJB method
is transactional by default (REQUIRED). Assume TX unless
@TransactionAttribute says otherwise."

---

### 📘 Concept Explanation

**EJB Annotation Reading Guide:**

```
EJBTYPE ANNOTATIONS:
  @Stateless   = no conversational state, pooled
  @Stateful    = maintains state per client session
  @Singleton   = one instance per JVM, @Lock on methods
  @MessageDriven = async, triggered by JMS message

DEPENDENCY INJECTION:
  @Inject      = CDI injection (any CDI bean)
  @EJB         = EJB injection (injects EJB proxy)
  @Resource    = resource injection (DataSource, JMS)
  @PersistenceContext = inject EntityManager (JPA)

TRANSACTION:
  @TransactionAttribute(REQUIRED)     = join or start TX
  @TransactionAttribute(REQUIRES_NEW) = always new TX
  @TransactionAttribute(NOT_SUPPORTED) = suspend TX
  @TransactionAttribute(NEVER)        = fail if TX active

LIFECYCLE:
  @PostConstruct = called after injection, before use
  @PreDestroy    = called before bean is destroyed

SECURITY:
  @RolesAllowed({"USER","ADMIN"}) = restrict access
  @PermitAll = anyone can call
  @DenyAll   = no one can call

SCHEDULING:
  @Schedule(hour="0", minute="0", second="0")
  = runs at midnight daily
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// READING A LEGACY EJB SERVICE: annotated guide

// This annotation identifies it as a pooled, stateless EJB
// Container creates a pool of instances (default: 10-20)
@Stateless

// These two tell you: this service can be called:
// 1. from within the same JVM (Local)
// 2. from remote EJB clients (Remote) - old pattern
@Local(OrderServiceLocal.class)
@Remote(OrderServiceRemote.class)

public class OrderServiceEjb
        implements OrderServiceLocal,
                   OrderServiceRemote {

    // EntityManager scoped to this EJB's transaction
    // @PersistenceContext identifies the JPA data source
    // (unitName matches persistence.xml unit name)
    @PersistenceContext(unitName = "OrderPU")
    private EntityManager em;

    // CDI injection - any bean with @ApplicationScoped, etc.
    @Inject
    private OrderValidator validator;

    // EJB injection - injects an EJB proxy (not direct ref)
    @EJB
    private InventoryServiceLocal inventory;

    // Default: @TransactionAttribute(REQUIRED)
    // This method runs in a transaction (joins or starts one)
    public Order createOrder(CreateOrderRequest req) {
        validator.validate(req);   // CDI bean call
        inventory.check(req);      // EJB proxy call
        Order order = new Order(req);
        em.persist(order);         // JPA, within TX
        return order;
        // TX commits when method returns (if no exception)
    }

    // @TransactionAttribute(REQUIRES_NEW):
    // This creates its OWN transaction, separate from the caller's
    // Use: audit log that must commit even if main TX rolls back
    @TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
    public void auditLog(String message) {
        em.persist(new AuditLog(message));
        // Commits separately from any outer TX
    }

    // @TransactionAttribute(NOT_SUPPORTED):
    // No transaction for this method
    // Use: read-only queries where you don't want TX overhead
    @TransactionAttribute(
        TransactionAttributeType.NOT_SUPPORTED
    )
    public List<Order> findAllOrders() {
        return em.createQuery(
            "SELECT o FROM Order o", Order.class
        ).getResultList();
    }

    // @Schedule: runs as a timer
    // Runs every day at 1:00 AM
    @Schedule(hour = "1", minute = "0",
              second = "0", persistent = false)
    public void cleanupOldOrders() {
        em.createQuery(
            "DELETE FROM Order o WHERE o.createdAt < :date"
        ).setParameter("date",
            LocalDate.now().minusDays(90)
        ).executeUpdate();
    }
}


// READING PERSISTENCE.XML:
// Located at: src/main/resources/META-INF/persistence.xml
/*
<persistence>
  <persistence-unit name="OrderPU">
    <!-- jta-data-source: JNDI name of the DataSource
         configured in WildFly's standalone.xml -->
    <jta-data-source>java:jboss/datasources/OrderDS</jta-data-source>

    <!-- List of entity classes (or use auto-scan) -->
    <class>com.example.Order</class>

    <properties>
      <!-- Hibernate schema validation (prod: validate) -->
      <property name="hibernate.hbm2ddl.auto"
                value="validate"/>
      <!-- Show SQL in logs (dev only!) -->
      <property name="hibernate.show_sql" value="true"/>
    </properties>
  </persistence-unit>
</persistence>
*/


// READING JBOSS-DEPLOYMENT-STRUCTURE.XML (WildFly):
// Located at: META-INF/jboss-deployment-structure.xml
// or WEB-INF/jboss-deployment-structure.xml
/*
<jboss-deployment-structure>
  <deployment>
    <!-- Add module dependencies: -->
    <dependencies>
      <!-- Allow access to WildFly's built-in modules: -->
      <module name="org.postgresql"/>

      <!-- Exclude a module WildFly auto-loads: -->
      <exclusions>
        <module name="com.sun.xml.bind"/>
      </exclusions>
    </dependencies>
  </deployment>
</jboss-deployment-structure>
*/
```

> **Code walkthrough:** The annotated EJB code shows how to
> read transaction boundaries: @Stateless + no annotation =
> REQUIRED = transactional by default. Every method in a
> @Stateless EJB joins a transaction unless explicitly overridden.
> The three @TransactionAttribute examples show the three most
> common transaction patterns: REQUIRED (default, join or start),
> REQUIRES_NEW (audit log pattern - always its own TX), and
> NOT_SUPPORTED (read-only reporting - no TX overhead). The
> @Schedule method shows how EJB timers work: the container
> invokes this method on the schedule, in a transaction.
> The persistence.xml jta-data-source reference connects to
> a DataSource defined in WildFly's standalone.xml - if you
> see a JNDI name mismatch between these files, the application
> will fail to start.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "When reading legacy Java EE code, I start by finding
> the web entry point in web.xml or by looking for @WebServlet
> and @Path annotations. Then I trace @EJB and @Inject
> annotations to find the service layer. @Stateless EJBs
> are the business logic layer, @PersistenceContext shows
> where JPA is used. persistence.xml tells me the data source
> and database configuration."

---

**Senior / Staff:**

> "Reading legacy Java EE code requires understanding the
> container model: you're reading a program where the container
> (WildFly) calls into your code at specific points, not a
> program you control end-to-end. Key mental model shifts:
> transactions begin and end at EJB method boundaries (not
> code blocks), dependency injection happens before any @PostConstruct,
> and lazy loading only works inside a transaction. When I
> encounter an unfamiliar codebase, I first read persistence.xml
> (data model) and web.xml or @Path annotations (API surface),
> then trace one end-to-end request through @EJB injection
> chains. I also check for EJB 2.x signs: if classes extend
> SessionBean and there are ejb-jar.xml descriptors, the code
> is 15+ years old and some modern patterns (CDI injection,
> @Stateless annotations) may not be available."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Legacy Java EE code cannot be tested."**

Legacy @Stateless EJBs can be tested with Mockito by
mocking @Inject dependencies and injecting them manually
(using setter injection or reflection). The EJB is a POJO
outside the container. Arquillian provides in-container
testing if you need CDI/EJB lifecycle semantics. The
difficulty of testing is not inherent to Java EE - it's
a consequence of tight coupling and Service Locator patterns.
Well-structured @Stateless EJBs with @Inject dependencies
are straightforward to unit test.

**Misconception 2: "ejb-jar.xml is required for EJB 3.x apps."**

ejb-jar.xml is optional in EJB 3.x+. All configuration
is available via annotations. ejb-jar.xml may be present
as an override mechanism: XML configuration overrides
annotation configuration. If you find conflicting settings
between annotations and XML descriptors, XML wins.
Legacy applications may have both for backward compatibility.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: EJB injection fails with NullPointerException**

*Symptom:* @EJB or @Inject field is null at runtime.
NPE when the injected field is first used.

*Root cause:* Bean was created with new instead of through
the container. Injection only works for container-managed
instances.

*Diagnosis:*
```bash
# Check if object was instantiated with 'new':
grep -rn "new OrderService\|new.*ServiceEjb" src/
# Any 'new' on an @Stateless/@Inject bean = injection skipped
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Always obtain managed beans through @Inject or @EJB.
Never use new on CDI beans or EJBs.

---

**Failure 2: Missing beans.xml disables CDI**

*Symptom:* @Inject fields are null. CDI events not fired.
@ApplicationScoped beans behave as prototypes (new instance each time).

*Root cause:* CDI requires beans.xml in META-INF (for JAR)
or WEB-INF (for WAR) to activate CDI for that archive.
Without it, CDI is disabled (in some containers).

*Fix:*
```xml
<!-- src/main/resources/META-INF/beans.xml (minimal): -->
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="https://jakarta.ee/xml/ns/jakartaee"
       version="3.0"
       bean-discovery-mode="all">
</beans>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | Transaction boundaries, EJB scope identification |
| Trade-off | 1 | App-managed vs container-managed JPA |
| Failure Mode | 2 | @EJB null injection, transaction not propagating |
| Debugging | 2 | Transaction log tracing, CDI activation |

**Q1. How do you identify transaction boundaries in legacy
Java EE code without running it?**

Transaction boundary markers in legacy code:

1. `@Stateless` + any public method = `Required` transaction by default
   (creates new transaction if none present, joins if one exists)

2. `@TransactionAttribute(REQUIRES_NEW)` = always creates a new,
   independent transaction (see method to find the boundary)

3. `UserTransaction.begin()/commit()/rollback()` = explicit
   application-managed transaction boundary

4. `@Transactional` (CDI) = same semantics as EJB transaction
   attributes, applied to CDI beans

5. Deployment descriptor `ejb-jar.xml` with `<container-transaction>`
   entries = XML-configured transaction attributes (older pattern)

Detecting implicit rollback-only:
```java
// Legacy code that silently marks transaction for rollback:
public void processOrder(Order order) {
    // ...
    context.setRollbackOnly(); // hidden in nested helper
}
// Caller does not know transaction was marked for rollback.
// Commit attempt produces: javax.ejb.EJBException
// Wrapped: javax.transaction.RollbackException
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Knowing that `@Stateless` without
any `@TransactionAttribute` annotation defaults to `REQUIRED` on ALL
public methods. Private and protected methods do not participate in
the container transaction. This means a `@Stateless` bean calling
its own private method does not get a transaction for that method.

---

**Q2. What is the significance of `@Stateless`, `@Stateful`, and
`@Singleton` EJBs in legacy code and when does each pattern
indicate a design concern?**

- **`@Stateless`**: pooled, no per-client state, most common. Correct
  use: service layer with transaction/security requirements.
  Design concern: `@Stateless` with instance variables that change
  per-request = data corruption under load (pooled instances are
  shared across calls, not per-thread).

- **`@Stateful`**: one instance per client, maintains conversation
  state. Correct use: multi-step wizard flows. Design concern:
  common source of memory leaks if `@Remove` method never called.
  Look for: `@Stateful` + no `@Remove` method = leak.

- **`@Singleton`**: one instance per application, accessed by all
  threads. Correct use: application-scope caches, startup tasks
  (`@Startup`). Design concern: `@Singleton` without
  `@ConcurrencyManagement(CONTAINER)` or `@Lock` = race conditions.

*What separates good from great:* The `@Stateful` memory leak is
the most impactful legacy bug. `@Stateful` beans held indefinitely
(client never triggers `@Remove` method) are only cleaned up by
passivation timeout (typically 30 minutes). Under load, this causes
steadily growing memory.

---

**Q3. How do you determine if CDI is enabled for a deployment
archive in legacy code?**

CDI enablement rules by Jakarta EE version:

- **Jakarta EE 8 and earlier (WARs)**: CDI enabled ONLY if
  `META-INF/beans.xml` or `WEB-INF/beans.xml` is present.
  Absent = no CDI injection.

- **Jakarta EE 9+ (default bean discovery)**: CDI is enabled by
  default for annotated classes in beans with implicit archives.
  beans.xml is optional but controls discovery mode.

- **Explicit `beans.xml` with `bean-discovery-mode`**:
  - `all`: all classes are CDI beans (legacy default)
  - `annotated`: only classes with CDI scope annotations
  - `none`: CDI disabled entirely

Diagnosis:
```bash
# Check archive for beans.xml:
jar tf legacy-app.war | grep beans.xml

# WildFly: CDI not enabled warning in server.log:
# "WFLYEJB0481: No CDI deployment context" (CDI not active)
# or "WELD-000042: Possible deployment problem:
#   WELD-001408" (CDI startup issue)

# In WildFly CLI: check CDI subsystem:
/subsystem=weld:read-resource
# require-bean-descriptor=true: requires beans.xml (EE 6 mode)
# require-bean-descriptor=false: implicit activation (EE 7+)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `require-bean-descriptor`
WildFly subsystem setting. If enabled (legacy WildFly config),
beans.xml is required even on EE 7+ deployments. New engineers
often add beans.xml as cargo-cult without understanding this
server-level setting controls whether it is actually required.

---

**Q4. What are common patterns for dependency injection in
legacy Java EE code predating CDI?**

Pre-CDI injection patterns (Java EE 2.x - 5.x era):

1. **JNDI lookup**: explicit manual lookup, still found in
   legacy code:
   ```java
   InitialContext ctx = new InitialContext();
   DataSource ds = (DataSource) ctx.lookup(
       "java:/comp/env/jdbc/MyDS");
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. **`@EJB` annotation**: EJB-to-EJB injection (predates CDI `@Inject`):
   ```java
   @Stateless
   public class OrderService {
       @EJB // EJB reference injection, not CDI
       private PaymentService paymentService;
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. **`@Resource` annotation**: resource injection (DataSource,
   Queue, Topic, Environment entries):
   ```java
   @Resource(name = "jdbc/MyDS")
   private DataSource dataSource;
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

4. **ServiceLocator pattern**: factory class performing JNDI lookup,
   used to inject dependencies in non-EJB classes:
   ```java
   PaymentService ps = ServiceLocator.getInstance(PaymentService.class);
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Knowing that `@EJB` and `@Inject`
have different semantics for local EJB lookup. `@EJB` looks up by
interface in the local JNDI tree. `@Inject` uses CDI's type-safe
resolution. In legacy code, `@EJB` on a `@Stateful` bean gives you
a per-client-session instance; CDI `@Inject` of the same interface
requires a proper CDI scope annotation.

---

**Q5. DEBUGGING: A `@EJB` injection is silently returning null
at runtime. How do you diagnose?**

Causes (in order of frequency):

1. **Object instantiated with `new` instead of container injection**:
   ```java
   // BUG: instantiated manually, @EJB never processed
   OrderService svc = new OrderService();
   svc.paymentService; // null - container never injected it
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. **EJB not deployed**: the target EJB failed to deploy (deployment
   error, missing dependency), JNDI lookup returns null without
   throwing.

3. **Interface mismatch**: the injection point uses the wrong
   interface type (remote vs. local).

Diagnosis:
```bash
# 1. Check if the EJB is deployed:
java:global/app-name/module-name/OrderService!com.example.OrderServiceLocal
# In WildFly CLI:
/deployment=my-app.war/subsystem=ejb3:read-resource(include-runtime=true)

# 2. Enable EJB injection debug logging:
# WildFly log category:
com.arjuna=DEBUG
org.jboss.as.ejb3=DEBUG
# Shows: injection resolution, JNDI lookup targets

# 3. Check for 'new' instantiation in codebase:
grep -rn 'new OrderService' src/
# Any 'new' on an EJB class = container injection bypassed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `new` anti-pattern detection.
`grep -rn 'new .*Service\|new .*Repository\|new .*EJB'` in the
codebase catches all cases where container beans are instantiated
manually. In large legacy codebases, this is common in utility
methods and test setup code.

---

**Q6. How do you distinguish application-managed JPA from
container-managed JPA in legacy code?**

Container-managed JPA:
```java
@Stateless
public class OrderRepository {
    @PersistenceContext  // container creates/closes EntityManager
    private EntityManager em;
    // em is bound to the transaction lifecycle
    // no need to close - container manages
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Application-managed JPA:
```java
@Stateless
public class LegacyReportService {
    @PersistenceUnit  // inject EntityManagerFactory
    private EntityManagerFactory emf;

    public List<Report> runReport() {
        EntityManager em = emf.createEntityManager();
        try {
            em.getTransaction().begin();  // manual transaction
            List<Report> results = em.createQuery(
                "...", Report.class).getResultList();
            em.getTransaction().commit();
            return results;
        } finally {
            em.close();  // must close manually
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Warning signs for application-managed JPA:
- `@PersistenceUnit` (not `@PersistenceContext`) in EJB code
- `em.getTransaction().begin()` in EJB (usually wrong - EJB
  has container-managed transaction, using both is a bug)
- Missing `em.close()` in finally = connection leak

*What separates good from great:* Knowing that application-managed
JPA inside a container-managed transaction context (EJB) is almost
always a bug. The container transaction and the application-managed
transaction are independent. Writes in the application-managed
transaction will NOT be rolled back if the container transaction
rolls back.

---

**Q7. What are the warning signs that legacy Java EE code is not
properly managing resources?**

Resource leak patterns (static analysis checklist):

1. **No `finally` around JDBC code**: `Connection`, `Statement`,
   `ResultSet` not closed if exception occurs.

2. **`@Stateful` without `@Remove`**: stateful session beans that
   are never explicitly removed leak server memory.

3. **Application-managed EntityManager not closed**: `emf.create
   EntityManager()` without `em.close()` in finally.

4. **JMS Session/Connection not closed**: `connection.createSession()`
   without corresponding close in finally.

5. **Timer not cancelled**: `@Schedule` or programmatic `TimerService`
   timer not cancelled when bean is destroyed.

6. **Thread not shutdown**: `new Thread().start()` in EJB (violates
   EJB spec - EJBs must not create unmanaged threads). Thread lives
   beyond EJB lifecycle.

Audit command:
```bash
# Find unclosed JDBC patterns:
grep -n 'createConnection\|getConnection' src/ -r |
  xargs -I{} sh -c 'grep -L "finally" $(echo {} | cut -d: -f1)'
# Files with getConnection but no 'finally' block = leak suspect
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The unmanaged thread pattern
(item 6) is both a resource leak AND a specification violation.
EJBs that create threads via `new Thread()` bypass the container's
thread management. These threads survive undeploy/redeploy, hold
class references that prevent GC, and run without transaction or
security context.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - reading code is a skill, not a
technology with alternatives. No comparison table applicable.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword - code reading meta-skill, no system
design applicable.)*

---

### 📊 Diagram

*(Omit: code navigation is a procedural skill better
described with code examples. No diagram applicable.)*

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



