---
layout: default
title: "Java EE - L0 Orientation"
parent: "Java EE"
nav_order: 1
permalink: /java-ee/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Java EE and Jakarta EE History](#java-ee-and-jakarta-ee-history) | ★☆☆ |
| 2 | [Java EE Architecture Overview](#java-ee-architecture-overview) | ★☆☆ |
| 3 | [Application Server Ecosystem](#application-server-ecosystem) | ★☆☆ |

---

# Java EE and Jakarta EE History

**Interview Weight:** ★☆☆ - Orientation. Any engineer
working with enterprise Java or maintaining legacy
systems must understand why Java EE exists and
what Jakarta EE means. The name change trips up
many candidates.

---

### 🎯 Model Answer

**30 seconds:**

> Java EE (Java Platform, Enterprise Edition) was
> Sun Microsystems' specification for building
> multi-tier enterprise applications on Java. It
> defined standard APIs - Servlets, EJB, JPA, CDI,
> JAX-RS - that application servers implement. In
> 2017, Oracle donated the specification to the
> Eclipse Foundation, where it was renamed Jakarta EE.
> The functional change is minimal: the package names
> shifted from javax.* to jakarta.* in Jakarta EE 9,
> but the APIs are conceptually the same.

**3 minutes:**

> Java EE has been the enterprise Java standard for
> over 20 years, but its history explains a lot
> about why the ecosystem looks the way it does today.
>
> Sun Microsystems launched J2EE in 1999 as a response
> to the complexity of building distributed, transactional
> enterprise applications on Java. The idea was a
> vendor-neutral specification: any compliant application
> server (WebSphere, WebLogic, JBoss, GlassFish)
> would run the same code. This worked well for
> portability but created complexity - EJB 2.x
> required XML deployment descriptors and home/remote
> interfaces that were notoriously verbose.
>
> The specification evolved significantly: EJB 3.0
> introduced annotations, CDI replaced Spring-like
> dependency injection, and JAX-RS standardized REST.
> Java EE 6 and 7 were well-regarded specifications
> that competed seriously with Spring.
>
> Oracle acquired Sun in 2010. Development slowed.
> The Spring ecosystem (which doesn't require a full
> app server) overtook Java EE in adoption. In 2017,
> Oracle donated Java EE to the Eclipse Foundation.
> The Foundation needed a new name because Oracle
> kept the "javax" trademark - hence Jakarta EE.
>
> The critical migration breaking point: Jakarta EE 9
> changed the package namespace from `javax.*` to
> `jakarta.*`. This is a compile-time change that
> requires libraries and code to migrate. Jakarta EE 10
> added modern features. Jakarta EE 11 (2024+) targets
> Java 21 and virtual threads.
>
> The non-obvious insight: many production enterprise
> Java applications still run Java EE 7 or 8 on
> WildFly or WebLogic. "Legacy Java EE" is not a
> small category - it's a large fraction of enterprise
> Java workloads.

**Blank Mind Recovery:**

**(1) Restate:** "Java EE = enterprise Java specification.
Jakarta EE = same thing, new name, javax became jakarta."

**(2) First principles:** "Enterprise apps need transactions,
security, distributed components. Java EE standardized
these as vendor-neutral specs that any app server implements."

**(3) Bridge:** "Like JDBC standardizes database access
so you can swap MySQL for Postgres: Java EE standardizes
app server APIs so you can (theoretically) swap WildFly
for WebLogic."

---

### 📘 Concept Explanation

**What it is:**

Java EE (now Jakarta EE) is a collection of Java
specifications that define standard APIs for enterprise
application concerns: web tier (Servlets, JSP, JSF),
business tier (EJB, CDI), data tier (JPA), services
(JAX-RS, JAX-WS), and cross-cutting concerns
(Bean Validation, JTA, JAAS).

**The problem it solves:**

Without a standard: every app server vendor would
create proprietary APIs. Applications would be
locked to one vendor. Enterprise concerns (transactions,
security, messaging) would need to be re-implemented
per project. Java EE provided a common language
across vendors and projects.

**Name and version timeline:**

```
1999: J2EE 1.2 (Java 2 Platform, Enterprise Edition)
2003: J2EE 1.4 (EJB 2.x - verbose, XML-heavy)
2006: Java EE 5 (EJB 3.0 - annotations, JPA 1.0)
2009: Java EE 6 (CDI, JAX-RS, Servlet 3.0)
2013: Java EE 7 (WebSockets, Batch, Concurrency)
2017: Java EE 8 (Java EE final Oracle version)
2017: Donated to Eclipse Foundation
2019: Jakarta EE 8 (same APIs, new governance)
2020: Jakarta EE 9 (javax.* -> jakarta.* rename)
2022: Jakarta EE 10 (modern features, Java 11+)
2024: Jakarta EE 11 (Java 21, virtual threads)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The javax to jakarta migration:**

```java
// Java EE / Jakarta EE 8 and before:
import javax.servlet.http.HttpServlet;
import javax.persistence.Entity;
import javax.inject.Inject;

// Jakarta EE 9+:
import jakarta.servlet.http.HttpServlet;
import jakarta.persistence.Entity;
import jakarta.inject.Inject;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This is a search-and-replace migration, but it
requires all dependencies to also be on Jakarta EE 9+.
Libraries like Hibernate 6+ support jakarta; older
versions use javax.

**Key insight:**

Java EE is a specification, not an implementation.
The implementations are application servers. This
is why "Which app server?" is always a relevant
question for Java EE code.

---

### 💻 Code Example

```java
// BEFORE: Java EE 7/8 style (javax namespace)
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/orders")
@Stateless
public class OrderResource {

    @PersistenceContext
    private EntityManager em;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Order> getOrders() {
        return em.createQuery(
            "SELECT o FROM Order o",
            Order.class
        ).getResultList();
    }
}

// AFTER: Jakarta EE 9+ style (jakarta namespace)
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/orders")
@Stateless
public class OrderResource {

    @PersistenceContext
    private EntityManager em;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Order> getOrders() {
        return em.createQuery(
            "SELECT o FROM Order o",
            Order.class
        ).getResultList();
    }
}
```

> **Code walkthrough:** The only change between Java EE
> and Jakarta EE 9+ is the package prefix: `javax`
> becomes `jakarta`. The annotations, classes, and
> methods are identical. This means a migration tool
> (like the Eclipse Transformer or IntelliJ's Jakarta
> EE migration) can automate the rename. The practical
> risk is in transitive dependencies: if a library
> your code depends on still uses `javax.*`, you
> have a classpath conflict that breaks at runtime.
> Spring Boot 3.x migrated to `jakarta.*` (Jakarta
> EE 9+), making Spring Boot 3+ incompatible with
> javax-based libraries.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Java EE is the enterprise Java specification that
> defines standard APIs for building multi-tier applications:
> Servlets for web, EJB for business logic, JPA for
> persistence, CDI for dependency injection, JAX-RS
> for REST. Jakarta EE is the same spec under the
> Eclipse Foundation after Oracle donated it. The
> main practical difference is package names - Jakarta
> EE 9 renamed javax.* to jakarta.*, which is a
> breaking change for dependencies."

*Push deeper:* Explain the J2EE to Java EE 5 evolution:
EJB 2.x required XML descriptors and home interfaces;
EJB 3.0 replaced them with annotations. CDI (context
and dependency injection) came in Java EE 6 as a
full DI framework that competes with Spring.

---

**Senior / Staff:**

> "The Jakarta EE history matters because it explains
> the fractured state of enterprise Java today. Oracle's
> slowdown of Java EE (while Spring surged) created
> a situation where many large enterprises are running
> 10-year-old Java EE 6 or 7 code on WildFly or
> WebLogic. When they need to migrate, they face
> both the javax-to-jakarta namespace change and
> a decision about whether to stay on Jakarta EE
> or move to Spring Boot or Quarkus. The specification
> model (app server implements the spec) was correct
> in theory but created bloated runtimes and slow
> startup times that cloud deployments punish. That
> is why MicroProfile and Quarkus exist: Jakarta EE
> semantics on lightweight, cloud-native runtimes."

*Push deeper:* The political history: Oracle delayed
Jakarta EE 9 for years while arguing about the jakarta
namespace. This accelerated MicroProfile adoption
and validated Spring Boot's approach of avoiding
app server dependencies entirely. A Staff engineer
who lived through this understands why the enterprise
Java ecosystem is fragmented.

---

### ⚠️ Common Misconceptions

**Misconception: "Jakarta EE and Java EE are completely
different things."**

Jakarta EE is the direct continuation of Java EE
under new governance. The APIs are functionally identical;
only the package namespace changed in Jakarta EE 9
(javax.* to jakarta.*). Code written for Java EE 8
compiles against Jakarta EE 8 without changes.
Jakarta EE 9 requires the namespace migration, but
it is a mechanical change, not an architectural rewrite.
Calling them "completely different" misleads teams
into thinking a larger rewrite is needed.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ClassNotFoundException after migrating to Spring Boot 3.x**

*Symptom:* Application throws `ClassNotFoundException`
or `NoSuchMethodError` for `javax.persistence.*` or
`javax.servlet.*` after upgrading to Spring Boot 3.x.

*Root cause:* Spring Boot 3.x requires Jakarta EE 9+
(jakarta namespace). A library that your code depends
on still ships the old javax-namespace version.
Both javax and jakarta versions of the same class
exist on the classpath.

*Diagnosis:*
```bash
# Find all jars that still include javax.persistence
mvn dependency:tree | grep -i hibernate
# Look for Hibernate 5.x (javax) vs 6.x (jakarta)

# Or check the classpath directly:
jar tf ~/.m2/repository/org/hibernate/hibernate-core/\
5.6.15.Final/hibernate-core-5.6.15.Final.jar \
| grep "javax/persistence"
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Upgrade all JPA/Servlet dependencies to
versions that support jakarta namespace:
- Hibernate: 5.x -> 6.x
- EclipseLink: 2.x -> 4.x
- Tomcat: 9.x -> 10.x (for jakarta.servlet)

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| What is Jakarta EE vs Java EE? | 2-3 min |
| Explain the javax to jakarta migration | 2-3 min |
| Java EE vs Spring: which to choose? | 3-4 min |
| Why did Java EE lose market share to Spring? | 2-3 min |
| What is MicroProfile? | 2-3 min |
| Debugging: ClassNotFoundException after migration | 2-3 min |
| History of Java EE specifications | 2 min |

---

**[MID] Q1 - What is the difference between
Java EE and Jakarta EE?**

*Why they ask:* Baseline understanding of enterprise Java history.

Java EE: Java Platform, Enterprise Edition. Collection of
specifications maintained by Oracle, with implementations
by app server vendors (WildFly, WebLogic, GlassFish,
Liberty). The package namespace is javax.*.

Jakarta EE: The same specifications, donated by Oracle
to the Eclipse Foundation in 2017. The Foundation
needed a new name because Oracle owns the "javax"
trademark. The brand changed to Jakarta EE.

Functional equivalence: Jakarta EE 8 is equivalent
to Java EE 8 (same namespace, just new governance).
Jakarta EE 9 introduced the namespace change:
all javax.* packages became jakarta.*. This is
a one-time breaking change that requires dependencies
to migrate.

*What separates good from great:* "The governance change matters more than the API change. Oracle's slow pace was hurting enterprise Java; the Eclipse Foundation model is more open. The jakarta namespace change forced a big bang migration but ended the dependency on Oracle's timeline."

---

**[MID] Q2 - Why did Spring become more popular
than Java EE?**

*Why they ask:* Understanding of ecosystem dynamics.

Spring succeeded because it solved Java EE's biggest
pain points without requiring a full app server:

1. EJB 2.x complexity: home interfaces, XML deployment
   descriptors, required container (no unit testing without server).
   Spring offered POJO-based DI in 2003.

2. Fast startup: Spring applications (embedded Tomcat)
   start in 2-10 seconds. Java EE app servers take 30-120 seconds.

3. No vendor lock-in: Spring works on any JVM.
   Java EE code works on compliant servers, but
   real apps accumulate vendor-specific config.

4. Testing: Spring beans are plain Java objects,
   easily unit-tested. EJB 2.x required container-managed lifecycle.

5. Iteration speed: Oracle's Java EE specification
   cycle was 2-4 years. Spring released constantly.

Java EE caught up with EJB 3.0 + CDI (Java EE 6),
but Spring had won the mindshare by then.

*What separates good from great:* "Spring didn't win on technical merit alone - it won on developer experience. EJB 3.0 with annotations was technically similar to Spring, but Spring already owned the ecosystem."

---

**[MID] Q3 - What is MicroProfile and how does
it relate to Jakarta EE?**

*Why they ask:* Modern enterprise Java awareness.

MicroProfile is a specification for microservices
built on Jakarta EE technologies. Created in 2016
by Red Hat, IBM, Tomitribe, and others - outside
Oracle's control.

MicroProfile adds cloud-native APIs that Jakarta EE
lacked:
- Health: /health endpoint for readiness/liveness probes
- Metrics: /metrics endpoint for Prometheus scraping
- OpenAPI: automatic API documentation
- Config: externalized configuration (like Spring @Value)
- Fault Tolerance: @Retry, @CircuitBreaker, @Timeout
- JWT Propagation: JWT-based authentication

MicroProfile implementations:
- Quarkus (Red Hat): compile to native with GraalVM
- Open Liberty (IBM): traditional + cloud-native
- Helidon (Oracle): lightweight MicroProfile server
- Payara Micro: GlassFish descendant

Relationship to Jakarta EE: MicroProfile runs on
top of Jakarta EE APIs (CDI, JAX-RS, JSON-P).
Quarkus uses Hibernate for JPA, RESTEasy for JAX-RS,
and adds MicroProfile on top.

*What separates good from great:* "MicroProfile is why enterprise Java survived cloud-native. If Jakarta EE alone was the option, most enterprises would have migrated to Spring Boot. MicroProfile + Quarkus gave Jakarta EE semantics with cloud-native performance."

---

**[SENIOR] Q4 - How does the javax to jakarta
migration work in practice?**

*Why they ask:* Real-world migration experience.

The migration has three components:

1. Source code: replace all `import javax.*` with
   `import jakarta.*`. Tools: Eclipse Transformer,
   OpenRewrite recipes, IntelliJ's Jakarta EE migration.

2. Library dependencies: every library using javax
   namespace needs a jakarta-compatible version.
   - Hibernate: 5.x (javax) -> 6.x (jakarta)
   - Spring Boot: 2.x (javax) -> 3.x (jakarta)
   - Tomcat: 9.x (javax.servlet) -> 10.x (jakarta.servlet)

3. Build tooling: some Maven plugins and test
   frameworks also have jakarta-compatible versions.

The migration can be done by:
(a) Big-bang: migrate everything at once.
    High risk, high coordination effort.
(b) Using the Eclipse Transformer to rewrite
    bytecode at deploy time (bridge solution).
(c) Incremental module-by-module using Java 9 modules.

Real risk: transitive dependencies. A library you
use may depend on another library that hasn't
migrated yet. The dependency tree must be fully
jakarta-compatible. This is the hardest part.

*What separates good from great:* "The javax-to-jakarta migration is straightforward mechanically. The hard part is the dependency tree: one unmigrated transitive dependency blocks the whole application. I'd start by auditing the dependency tree for known unmigrated libraries before writing a single line of code."

---

**[MID] Q5 - What happens to a Java EE 7 application
running on an old WildFly version when the organization
decides to containerize?**

*Why they ask:* Practical migration scenario.

Options for containerizing legacy Java EE:

Option 1: Lift and shift - package the app server
in a Docker container.
```dockerfile
FROM jboss/wildfly:26.0.0.Final
COPY my-app.war /opt/jboss/wildfly/standalone/\
deployments/
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Pros: minimal code change. Cons: heavy image (500MB+),
slow startup (45-90 seconds), doesn't fit 12-factor.

Option 2: Migrate to a lighter Jakarta EE server
(Open Liberty, Payara Micro). Smaller image, faster start.

Option 3: Migrate to Quarkus. Rewrite to use Quarkus
extensions for CDI, JAX-RS, JPA. Compile to native
for 50ms start, 50MB image.

Option 4: Migrate to Spring Boot. Larger rewrite but
largest ecosystem and hiring pool.

Decision factors: team Java EE expertise, timeline,
need for native compilation, existing library dependencies.

*What separates good from great:* "Lift-and-shift is valid as a first step - it removes the on-prem hardware dependency without rewriting code. Plan the modernization in phases: containerize first, optimize image and startup second, migrate framework third."

---

**[MID] Q6 - What is the CDI specification and
how does it differ from Spring DI?**

*Why they ask:* Core Java EE concept.

CDI (Contexts and Dependency Injection) is the
Java EE standard for dependency injection. Defined
in JSR 299 (Java EE 6), now part of Jakarta EE.

CDI vs Spring DI:

Same core: both use injection points (@Inject),
both support scopes (per-request, per-session,
singleton), both allow qualifiers to select among
implementations.

Key differences:
- CDI uses `@Inject` (standard); Spring originally
  used `@Autowired` (proprietary), now supports @Inject too.
- CDI has `@Produces` for factory methods;
  Spring uses `@Bean` in `@Configuration` classes.
- CDI scopes are tied to HTTP context (RequestScoped,
  SessionScoped); Spring has additional scopes
  (prototype, custom).
- CDI extensions use `Extension` SPI;
  Spring uses `BeanPostProcessor`.

CDI is the standard; Spring's annotations are a
superset. Code using only `@Inject` (JSR-330) is
portable between CDI and Spring.

*What separates good from great:* "CDI and Spring DI are conceptually the same. The practical difference is ecosystem: Spring has broader auto-configuration and starter support. CDI in an app server is excellent but requires more manual configuration."

---

**[MID] Q7 - Why do some organizations still run
Java EE 7 in production today (2026)?**

*Why they ask:* Production reality awareness.

Reasons Java EE 7 (released 2013) persists in 2026:

1. Working software doesn't get rewritten without ROI:
   if the app generates revenue and is stable, the
   business case for migration is hard to make.

2. Certification dependencies: some financial and
   healthcare systems are certified on specific
   platform versions. Changing the platform requires
   re-certification.

3. App server contracts: large enterprises have
   paid WebLogic or WebSphere support contracts.
   Migration means exiting expensive contracts.

4. Skills shortage: teams that built the system
   may have left. The institutional knowledge needed
   to safely migrate doesn't exist.

5. Size: large monolithic Java EE apps can have
   millions of lines of code. Rewriting is a
   multi-year project.

What moves organizations to migrate: end of support
(Oracle WebLogic 12c EOL), Java 8 EOL, security
vulnerabilities in old app server versions.

*What separates good from great:* "Legacy Java EE is not a technical failure - it's a business success. The apps work. The migration question is 'what's the cost of staying vs moving?' I'd start with the security risk: old app server versions accumulate CVEs. That's the business case."

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


# Java EE Architecture Overview

**Interview Weight:** ★☆☆ - Orientation. Understanding
the multi-tier Java EE architecture is required
context for any Java EE or legacy enterprise Java
interview question.

---

### 🎯 Model Answer

**30 seconds:**

> Java EE organizes enterprise applications into
> three tiers: the web tier (Servlets, JSP, JSF)
> handles HTTP; the business tier (EJB, CDI) handles
> business logic and transactions; the data tier
> (JPA, JTA) handles persistence. An application
> server provides all the container services these
> tiers rely on: dependency injection, transaction
> management, security, connection pooling, and
> thread management. Your code is just POJOs annotated
> with Java EE annotations - the container does the work.

**3 minutes:**

> Java EE's architecture follows a multi-tier
> model that separates concerns by layer:
>
> Web Tier: HTTP entry points.
> - Servlet: Java class that handles HTTP request/response.
>   The foundation of all Java web frameworks.
> - JSP (JavaServer Pages): HTML template with embedded Java.
>   Generates dynamic HTML.
> - JSF (JavaServer Faces): component-based UI framework.
>   Used in heavy enterprise CRUD apps.
>
> Business Tier: Business logic and transactions.
> - EJB (Enterprise JavaBeans): managed components
>   with container-provided transaction management,
>   security, concurrency, and pooling.
> - CDI (Contexts and Dependency Injection):
>   lightweight, annotation-driven DI container.
>
> Data Tier: Persistence.
> - JPA (Java Persistence API): ORM specification.
>   Hibernate and EclipseLink are common implementations.
> - JTA (Java Transaction API): distributed transaction
>   management. Critical when one transaction spans
>   multiple data sources.
>
> Cross-cutting:
> - Bean Validation: constraint annotations on POJOs.
> - JAAS: authentication and authorization.
> - JAX-RS: RESTful web services.
>
> The application server (WildFly, WebLogic, Liberty)
> implements all these specifications. It provides
> the container that manages EJB lifecycle, CDI
> injection, JPA entity manager lifecycle, and
> JTA transactions. Your application just uses
> the annotations; the container wires everything.
>
> The key insight: Java EE is "convention over
> configuration via containers." The container
> assumes responsibility for complex infrastructure
> (transaction demarcation, security checks) based
> on annotations. Spring Boot does the same thing
> but without requiring a full app server.

**Blank Mind Recovery:**

**(1) Restate:** "Three tiers: web (Servlets/JSP),
business (EJB/CDI), data (JPA/JTA). App server runs
the container that provides all services."

**(2) First principles:** "Enterprise apps need HTTP,
transactions, security, persistence. Separate concerns
into layers; app server handles the plumbing."

**(3) Bridge:** "Like Spring Boot's layers but with a heavier
runtime. @Controller = Servlet, @Service = EJB/CDI,
@Repository = JPA repository."

---

### 📘 Concept Explanation

**What it is:**

Java EE defines a multi-tier application architecture
where an application server provides container services
(lifecycle, DI, transactions, security) to application
components annotated with Java EE APIs.

**The problem it solves:**

Enterprise applications need many non-business concerns:
HTTP handling, connection pooling, transaction management,
authentication, authorization. Without a platform,
each application team must implement all of these
from scratch, inconsistently. Java EE standardizes
them into container-provided services.

**Layer breakdown:**

```
JAVA EE APPLICATION TIERS:

+----------------------------------+
|  Client Tier                     |
|  Browser / REST client / SOAP    |
+----------------------------------+
           |  HTTP / HTTPS
+----------------------------------+
|  Web Tier                        |
|  Servlet  JSP  JSF  JAX-RS       |
|  Filters  Listeners              |
+----------------------------------+
           |  CDI injection
+----------------------------------+
|  Business Tier                   |
|  EJB (Stateless/Stateful/Singleton)
|  CDI Beans  Message-Driven Beans |
|  JTA Transactions                |
+----------------------------------+
           |  EntityManager
+----------------------------------+
|  Data Tier                       |
|  JPA  JDBC  JCA Connectors       |
|  Database  Message Queue         |
+----------------------------------+

All tiers run inside the Application Server container.
Container services: DI, transactions, security,
pooling, lifecycle, interceptors.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Container services:**

- **Dependency Injection:** `@Inject` - container
  resolves dependencies between components.
- **Transaction Management:** `@Transactional` on EJB
  methods - container begins/commits/rolls back.
- **Security:** `@RolesAllowed` - container checks
  identity before invoking method.
- **Pooling:** EJB container maintains a pool of
  stateless session bean instances.
- **Lifecycle management:** container controls when
  beans are created, destroyed, passivated.

**Key insight:**

The application server is a "big" runtime that
provides everything. Contrast with Spring Boot
(smaller embedded server, optional dependencies).
The trade-off: Java EE app servers are production-proven
and highly capable but have heavy footprints and
slow startup. Cloud deployments punish both.

---

### 💻 Code Example

```java
// Typical Java EE web application structure:

// 1. Servlet (web tier) - handles HTTP
@WebServlet("/api/products")
public class ProductServlet extends HttpServlet {

    // Container injects the CDI bean
    @Inject
    private ProductService productService;

    @Override
    protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException {
        List<Product> products = productService.findAll();
        // Serialize to JSON and write to response
        resp.setContentType("application/json");
        // ... (in practice use JAX-RS instead)
    }
}

// 2. CDI/EJB Service (business tier)
@Stateless  // EJB - container manages transaction
public class ProductService {

    @PersistenceContext
    private EntityManager em; // container-injected

    // Container starts a transaction for this method
    // by default (REQUIRED propagation)
    public List<Product> findAll() {
        return em.createQuery(
            "SELECT p FROM Product p",
            Product.class
        ).getResultList();
    }

    @TransactionAttribute(
        TransactionAttributeType.REQUIRES_NEW
    )
    public void save(Product product) {
        em.persist(product); // included in new txn
    }
}

// 3. JPA Entity (data tier)
@Entity
@Table(name = "products")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull          // Bean Validation
    @Size(max = 255)  // Bean Validation
    private String name;

    private BigDecimal price;

    // getters/setters omitted
}

// 4. JAX-RS (preferred web tier for REST)
@Path("/products")
@Stateless  // or @RequestScoped CDI bean
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ProductResource {

    @Inject
    private ProductService productService;

    @GET
    public List<Product> getAll() {
        return productService.findAll();
    }

    @POST
    @Valid // triggers Bean Validation on @RequestBody
    public Response create(Product product) {
        productService.save(product);
        return Response.status(Response.Status.CREATED)
            .entity(product).build();
    }
}
```

> **Code walkthrough:** The four layers of a typical
> Java EE application. The `@WebServlet` shows direct
> HTTP handling - rarely used directly now that JAX-RS
> is standard. `@Stateless` on `ProductService` makes
> it an EJB with container-managed transactions: every
> method call is automatically wrapped in a transaction
> (REQUIRED by default). `@PersistenceContext` is injected
> by the container; you don't create or close the
> EntityManager. The `@Entity` class with Bean Validation
> constraints shows the data tier: `@NotNull` and
> `@Size` are checked automatically at the persistence
> layer and by JAX-RS when `@Valid` is present.
> The JAX-RS `ProductResource` is the modern approach:
> cleaner than raw Servlets, returns Java objects
> that are automatically serialized to JSON.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Java EE has three tiers: web tier for HTTP (Servlets,
> JAX-RS), business tier for logic and transactions
> (EJB, CDI), and data tier for persistence (JPA).
> The application server provides container services
> that make all the tiers work: dependency injection,
> transactions, security, and connection pooling.
> You write annotated POJOs and the container handles
> the infrastructure."

---

**Senior / Staff:**

> "The key design principle in Java EE is inversion
> of control at the container level. You declare
> intent with annotations: @Transactional means
> 'the container manages the transaction boundaries
> for this method.' @RolesAllowed means 'the container
> enforces authorization before invoking this.'
> This is powerful for consistent cross-cutting
> concerns but creates a tight coupling to the
> container at runtime.
>
> The production concern I always raise: Java EE
> apps are hard to test without a container. Embedded
> containers like Arquillian or WildFly Embedded
> exist, but they're heavier than a Spring Boot
> test context. Spring won partly on testability.
> Quarkus improves on this significantly: fast test
> startup with @QuarkusTest."

---

### ⚠️ Common Misconceptions

**Misconception: "EJB and CDI are the same thing."**

EJB (Enterprise JavaBeans) and CDI (Contexts and
Dependency Injection) are related but distinct
specifications. EJB provides component model features:
instance pooling (Stateless Session Beans maintain
a pool for performance), remote invocation (EJBs
can be called over RMI/IIOP), timer services, and
container-managed transactions. CDI is specifically
a dependency injection and lifecycle management
specification - it does not have pooling, remote
invocation, or timers. Modern Java EE applications
use CDI beans for most components and reach for
EJB specifically when they need pooling, @Asynchronous,
or @Schedule. JAX-RS resources can be CDI beans
(@RequestScoped) or EJBs (@Stateless); both work
but have different lifecycle implications.

---

### 🚨 Failure Modes and Diagnosis

**Failure: EJB transaction not rolling back on unchecked exception**

*Symptom:* Data is partially persisted after an
unchecked exception in an EJB method. Expected
rollback did not occur.

*Root cause:* EJB container rolls back on unchecked
(RuntimeException) exceptions by default. But if
the exception is caught and swallowed within the EJB,
the container never sees it and commits the transaction.

*Diagnosis:*
```java
// BAD: exception swallowed, transaction commits
@Stateless
public class OrderService {
    @Inject
    private PaymentService payment;

    @Inject
    private InventoryService inventory;

    public void placeOrder(Order order) {
        payment.charge(order);  // persists payment
        try {
            inventory.reserve(order); // might fail
        } catch (Exception e) {
            // SWALLOWED - transaction still commits!
            log.error("Inventory failed", e);
        }
        // transaction commits with payment but no inventory
    }
}

// GOOD: let exceptions propagate OR mark rollback
public void placeOrder(Order order) {
    payment.charge(order);
    inventory.reserve(order); // let exception propagate
    // OR:
    try {
        inventory.reserve(order);
    } catch (Exception e) {
        // Force rollback explicitly
        sessionContext.setRollbackOnly();
        throw new RuntimeException(
            "Order failed", e
        );
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Either let exceptions propagate from EJB
methods (the container sees them and rolls back),
or explicitly call `sessionContext.setRollbackOnly()`
before catching.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Java EE three-tier architecture | 2-3 min |
| Role of the application server | 2-3 min |
| Container-managed vs bean-managed transactions | 3-4 min |
| EJB vs CDI beans | 3-4 min |
| Testing Java EE applications | 2-3 min |
| EJB transaction rollback rules | 3-4 min |
| Java EE vs Spring Boot architecture | 3-4 min |

---

**[MID] Q1 - What does "container-managed" mean
in Java EE?**

*Why they ask:* Core Java EE concept.

"Container-managed" means the application server container
handles a concern on behalf of your code, based on
annotations or deployment descriptors.

Container-managed transactions (CMT):
The EJB container starts, commits, or rolls back
a transaction based on the @TransactionAttribute
annotation. Your code does not call
`userTransaction.begin()` or `commit()`.

Container-managed persistence (for EJBs):
`@PersistenceContext EntityManager em` - the container
creates and injects the EntityManager, associates
it with the current transaction, and flushes/closes it.

Container-managed security:
`@RolesAllowed({"admin"})` - the container checks
the caller's role before invoking the method. If
not in the role: `javax.ejb.AccessLocalException`.

Contrast with "bean-managed transactions" (BMT):
Your EJB injects `UserTransaction` and calls
`begin()`, `commit()`, `rollback()` explicitly.
Required when you need fine-grained control over
transaction boundaries.

*What separates good from great:* "Container-managed is the default and correct choice for 90% of cases. You reach for bean-managed transactions when you need a transaction to span multiple EJB methods (CMT starts a new context per method), or when you need very fine-grained rollback control."

---

**[MID] Q2 - How does @Stateless differ from @Stateful?**

*Why they ask:* EJB types.

@Stateless Session Bean:
- No conversational state between method calls
- Container maintains a pool of instances
- Any instance can serve any client
- Good for: service methods, JPA queries, REST resources
- Analogy: thread pool workers

@Stateful Session Bean:
- Maintains state for a specific client across calls
- One instance per client session
- Container passivates to disk if inactive
- Good for: multi-step workflows, shopping cart
- Risk: memory bloat if many sessions are active

@Singleton:
- One instance for the whole application
- Container manages concurrent access
- Good for: application-wide cache, startup initialization
- @Startup: init on deployment

Modern practice: Most things that were @Stateful
in Java EE 5/6 are now implemented with @RequestScoped
CDI beans + explicit state in the request body (REST
is stateless). @Stateful is rare in new applications.

*What separates good from great:* "@Stateful is a session affinity problem waiting to happen at scale. One instance per client means the load balancer must route a client to the same server that holds their SFSB instance - sticky sessions. Avoiding @Stateful in favor of stateless services + client-side state is the cloud-native pattern."

---

**[SENIOR] Q3 - How does JTA transaction management work?**

*Why they ask:* Core enterprise Java infrastructure.

JTA (Java Transaction API) is the standard for
distributed transactions in Java EE. It extends
JDBC transactions to cover multiple resources
(multiple databases, JMS queues) in a single atomic operation.

Two-phase commit protocol (2PC):
Phase 1 (Prepare): Transaction Manager sends prepare
message to all participating resources (XA datasources).
Each resource votes yes or no.
Phase 2 (Commit/Rollback): If all voted yes, TM sends
commit. If any voted no, TM sends rollback to all.

Components:
- Transaction Manager: part of the app server.
  Coordinates 2PC across resources.
- XA DataSource: JDBC datasource that supports 2PC.
  (Regular DataSource does not participate in JTA.)
- UserTransaction: the API for programmatic JTA in BMT EJBs.

When JTA is critical:
Transfer from Bank A's database to Bank B's database
in one atomic operation. Without JTA: partial commits
are possible (debit succeeds, credit fails).

Cost: JTA 2PC is expensive - multiple round trips
to all resources, locking until 2PC completes.
Modern architectures avoid distributed transactions
by using event sourcing, sagas, or idempotent retry.

*What separates good from great:* "In distributed systems, I avoid JTA 2PC because the locking overhead is severe and the two-phase commit protocol has edge cases (prepared but coordinator crashes = in-doubt transaction). The saga pattern with compensating transactions is more resilient."

---

**[MID] Q4 - When would you use EJB vs a CDI bean?**

*Why they ask:* EE component selection.

Use EJB (@Stateless, @Stateful, @Singleton) when you need:
- Container-managed transactions (the main reason)
- @Asynchronous method execution
- @Schedule timer methods
- Remote EJB invocation (over RMI/IIOP)
- Instance pooling for stateless operations

Use CDI bean when you need:
- Plain dependency injection without EJB overhead
- Custom scopes (beyond request/session/app)
- CDI events (@Observes for loose coupling)
- Producer methods (@Produces for flexible bean creation)
- The component is not doing transaction management

Modern practice: CDI beans for everything; add @Stateless
only to methods that need container-managed transactions.
In Jakarta EE 10+, @Transactional works on CDI beans
(via CDI interceptors), reducing the need for EJB
just for transactions.

*What separates good from great:* "In a new Jakarta EE 10+ project, I'd use CDI beans with @Transactional everywhere and avoid EJB entirely except for @Asynchronous and @Schedule. The @Transactional CDI interceptor gives the same transaction management without the EJB overhead."

---

**[MID] Q5 - How does Bean Validation integrate
with JAX-RS?**

*Why they ask:* Jakarta EE integration.

Bean Validation integrates automatically with JAX-RS
when `@Valid` is present on a parameter:

```java
@POST
@Path("/users")
public Response createUser(
    @Valid User user  // triggers validation
) {
    // user.name, user.email, user.age all validated
    // before this code runs
    return Response.status(201).entity(user).build();
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

If validation fails: JAX-RS returns 400 Bad Request
with validation error details (in the default implementation).
You can customize the error response with an
`ExceptionMapper<ConstraintViolationException>`.

Validation annotations (on the entity):
```java
@Entity
public class User {
    @NotBlank
    @Size(max = 100)
    private String name;

    @Email
    @NotNull
    private String email;

    @Min(18) @Max(150)
    private int age;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Validation groups: run different constraints for
create vs update operations.

*What separates good from great:* "The common mistake: relying on only @Valid at the JAX-RS layer and not at the service layer. If the service method is called from anywhere other than JAX-RS (e.g., a JMS listener), there's no validation. Put validation at the service layer too with `@Valid` on parameters and use @ValidateOnExecution."

---

**[SENIOR] Q6 - How do you test Java EE components
without a full application server?**

*Why they ask:* Testing strategy.

Three approaches:

1. Arquillian: integration testing framework that
   deploys a micro-deployment to an embedded/managed
   app server. Tests run inside the container.
   Realistic but slow (server startup).

2. CDI SE (standalone CDI): CDI can run outside
   an app server since CDI 2.0. For unit testing
   CDI beans:
   ```java
   try (SeContainer container = SeContainerInitializer
       .newInstance().initialize()) {
       ProductService svc = container.select(
           ProductService.class
       ).get();
       // test svc
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. Mockito + @Inject injection: test CDI beans
   as plain Java objects, mock injected dependencies:
   ```java
   // In test - no container, manual injection
   ProductService svc = new ProductService();
   svc.em = mock(EntityManager.class); // reflect or package-private
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

4. Quarkus @QuarkusTest: if migrating to Quarkus,
   tests start in 1-2 seconds. The best testing
   experience in the Jakarta EE ecosystem.

*What separates good from great:* "The hardest part of testing Java EE is the EntityManager. It's container-injected and tied to JTA transactions. I unit test business logic by mocking the EntityManager. For integration tests, I use Arquillian with an in-memory H2 database and let the container wire everything."

---

**[MID] Q7 - What is the Java EE deployment descriptor
and when do you still need it?**

*Why they ask:* Historical context + practical knowledge.

Deployment descriptors are XML files that configure
Java EE components:
- `web.xml`: web application config (Servlet 2.x style)
- `ejb-jar.xml`: EJB configuration
- `persistence.xml`: JPA persistence unit config
- `beans.xml`: CDI activation (required pre-CDI 4.0)

Since Java EE 5, annotations replaced most XML.
You still need XML when:

1. `persistence.xml`: always required for JPA. Defines
   the persistence unit, data source JNDI name,
   and JPA provider-specific properties.
   ```xml
   <persistence-unit name="myPU">
     <jta-data-source>java:/MyDS</jta-data-source>
     <properties>
       <property name="hibernate.hbm2ddl.auto"
                 value="validate"/>
     </properties>
   </persistence-unit>
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. `beans.xml`: in older versions of CDI (pre-4.0),
   an empty `beans.xml` was required to activate
   CDI scanning for a module.

3. Overriding annotations: deployment descriptor
   values override annotations, useful for
   environment-specific configuration.

4. Security constraints that cannot be expressed
   in annotations (complex URL patterns).

*What separates good from great:* "persistence.xml is the one XML file that will never go away in Jakarta EE - it's the correct place for environment-specific JPA configuration. I use it to configure the data source JNDI name and validation mode, while keeping entity mappings in annotations."

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


# Application Server Ecosystem

**Interview Weight:** ★☆☆ - Orientation. Engineers
maintaining or evaluating enterprise Java systems
need to distinguish between the major application
servers and understand when each is appropriate.

---

### 🎯 Model Answer

**30 seconds:**

> The major Java EE/Jakarta EE application servers
> are WildFly (Red Hat, open source), Open Liberty
> (IBM, open source), GlassFish/Payara (Eclipse Foundation/
> Payara, open source), and the commercial offerings
> WebLogic (Oracle) and WebSphere Traditional/Liberty
> (IBM). WildFly is the dominant open-source choice
> for new projects; WebLogic and WebSphere are dominant
> in enterprises with existing commercial licenses.
> Quarkus has emerged as the cloud-native Jakarta EE
> runtime for new microservices.

**3 minutes:**

> The application server landscape divides into
> legacy commercial, open source, and cloud-native:
>
> **Legacy commercial** (existing enterprise contracts):
> - Oracle WebLogic: dominant in financial services
>   and Oracle-stack shops. WebLogic 14c supports
>   Jakarta EE 8.
> - IBM WebSphere Traditional: dominant in healthcare,
>   banking. Heavy but proven.
> - IBM WebSphere Liberty/Open Liberty: the modern IBM
>   option - lightweight, fast startup, Jakarta EE 10.
>
> **Open source Jakarta EE servers:**
> - WildFly: Red Hat's fully certified Jakarta EE server.
>   Fast, actively developed. Basis for JBoss EAP
>   (the commercial version).
> - GlassFish: Eclipse Foundation's reference implementation.
>   Good for testing spec compliance; less popular in production.
> - Payara Server: commercial-supported fork of GlassFish.
>   Good for organizations needing support without Oracle/IBM.
>
> **Cloud-native Jakarta EE runtimes:**
> - Quarkus: compile-time CDI, GraalVM native compilation.
>   Not a traditional app server; no WAR deployment.
>   Jakarta EE semantics with 50ms startup.
> - Open Liberty: also supports cloud-native packaging.
>   Docker-friendly.
> - Helidon: Oracle's microservices runtime using MicroProfile.
>
> **The key insight:** For new microservices, Quarkus
> or Open Liberty. For existing Java EE 7/8 migrations,
> WildFly or Payara. For legacy WebLogic/WebSphere:
> evaluate the business case before migrating.

**Blank Mind Recovery:**

**(1) Restate:** "Commercial: WebLogic, WebSphere.
Open source: WildFly, GlassFish/Payara, Liberty.
Cloud-native: Quarkus, Helidon."

**(2) First principles:** "An app server implements
the Jakarta EE specs. Pick based on: existing license,
cloud requirements, team expertise, and startup time requirements."

**(3) Bridge:** "Like picking a servlet container (Tomcat, Jetty, Undertow)
but for the full enterprise stack."

---

### 📘 Concept Explanation

**What it is:**

An application server is a runtime environment that
implements the Jakarta EE specifications, providing
container services (DI, transactions, security,
pooling) for enterprise applications.

**The problem it solves:**

Enterprises need a production-grade, spec-compliant
runtime that handles all enterprise concerns consistently.
Application servers provide this, plus management
tooling, clustering, high availability, and commercial support.

**Comparison of major servers:**

```
APPLICATION SERVER COMPARISON:

Server          | Vendor       | License    | Startup | EE Cert
----------------+--------------+------------+---------+--------
WildFly 31      | Red Hat      | LGPL       | 8-15s   | JEE 10
JBoss EAP 8     | Red Hat      | Commercial | 8-15s   | JEE 10
Open Liberty    | IBM          | Apache 2   | 2-5s    | JEE 10
WebSphere Trad  | IBM          | Commercial | 60-120s | JEE 8
WebSphere Lib   | IBM          | Commercial | 2-5s    | JEE 10
WebLogic 14c    | Oracle       | Commercial | 30-60s  | JEE 8
Payara Server   | Payara       | CDDL/Comm  | 10-20s  | JEE 10
GlassFish 7     | Eclipse Fdn  | EPL        | 10-15s  | JEE 10
Quarkus 3       | Red Hat      | Apache 2   | 1-2s    | Partial*
Helidon 4       | Oracle       | Apache 2   | 1-3s    | MP 6

* Quarkus supports most Jakarta EE APIs via extensions
  but is not a traditional full-profile certified server.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Deployment models:**

Traditional (WAR/EAR):
```
my-app.war deployed to:
  WildFly/standalone/deployments/
  or via management console
  or via WildFly CLI (jboss-cli.sh)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Quarkus (uber-jar or native):
```
./mvnw package -Pnative
./target/my-app-runner  # 50ms startup, 50MB RSS
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Key insight:**

Application server choice is often decided by organizational
contracts and existing expertise, not technical merit.
New projects should strongly consider Quarkus or
Spring Boot. Existing Java EE apps on WebLogic/WebSphere
stay for financial and risk reasons.

---

### 💻 Code Example

```xml
<!-- WildFly standalone.xml: datasource configuration -->
<subsystem xmlns="urn:jboss:domain:datasources:6.0">
  <datasources>
    <datasource jndi-name="java:/MyDS"
                pool-name="MyDS"
                enabled="true">
      <connection-url>
        jdbc:postgresql://localhost:5432/mydb
      </connection-url>
      <driver>postgresql</driver>
      <security>
        <user-name>myuser</user-name>
        <password>mypassword</password>
      </security>
      <pool>
        <min-pool-size>5</min-pool-size>
        <max-pool-size>20</max-pool-size>
        <idle-timeout-minutes>5</idle-timeout-minutes>
      </pool>
      <validation>
        <valid-connection-checker
          class-name="org.jboss.jca.adapters.jdbc
.extensions.postgres.PostgreSQLValidConnectionChecker"/>
        <check-valid-connection-sql>
          SELECT 1
        </check-valid-connection-sql>
      </validation>
    </datasource>
  </datasources>
</subsystem>

<!-- persistence.xml references the JNDI datasource -->
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```xml
<!-- Open Liberty server.xml equivalent -->
<server>
  <featureManager>
    <feature>jakartaee-10.0</feature>
    <feature>microProfile-6.1</feature>
  </featureManager>

  <dataSource id="MyDS" jndiName="java:/MyDS">
    <jdbcDriver libraryRef="postgresLib"/>
    <properties.postgresql
      databaseName="mydb"
      serverName="localhost"
      portNumber="5432"
      user="myuser"
      password="mypassword"/>
    <connectionManager
      minPoolSize="5"
      maxPoolSize="20"/>
  </dataSource>
</server>
```

> **Code walkthrough:** Two equivalent datasource
> configurations for WildFly and Open Liberty. Both
> register the datasource at the JNDI name `java:/MyDS`,
> which is what `persistence.xml` references. WildFly
> uses XML subsystem configuration; Open Liberty uses
> its simpler `server.xml` format. Both configure
> connection pool sizes and validation queries.
> The validation SQL (`SELECT 1`) ensures the pool
> removes stale connections - critical for databases
> that close idle connections after a timeout. Open
> Liberty's `server.xml` is significantly more concise
> and is why many teams prefer it over WildFly's
> verbose subsystem XML.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "The main Java EE application servers are WildFly
> (open source, Red Hat), Open Liberty (IBM), and
> the commercial ones WebLogic (Oracle) and WebSphere
> (IBM). WildFly is the most popular choice for new
> open-source Java EE projects. For cloud-native
> new projects, Quarkus uses Jakarta EE APIs but
> compiles much faster and starts in milliseconds."

---

**Senior / Staff:**

> "Application server choice is usually not a
> technical decision - it's a political and financial
> one. WebLogic persists in banking because Oracle
> support contracts and certifications are already
> paid for. WebSphere persists in healthcare for
> the same reason. The technical choice is clear:
> WildFly or Open Liberty for traditional app server
> deployments; Quarkus for anything new.
>
> The production concern I always raise: application
> server startup time. WildFly at 8-15 seconds and
> WebLogic at 30-60 seconds are not Kubernetes-friendly.
> Rolling deployments with 60-second startup means
> 60 seconds of degraded capacity. This is why Quarkus
> (1-2 seconds, or 50ms native) is compelling for
> containerized deployments."

---

### ⚠️ Common Misconceptions

**Misconception: "You need a full Java EE application
server to use JPA."**

JPA is a specification that can run outside a full
application server. Hibernate (a JPA implementation)
works standalone with a `LocalEntityManagerFactoryBean`
(in Spring) or by creating an `EntityManagerFactory`
directly from `Persistence.createEntityManagerFactory()`.
The application server provides `@PersistenceContext`
injection and JTA-managed transactions; standalone
Hibernate provides `EntityManagerFactory` + resource-local
transactions. Spring Data JPA is the dominant
standalone JPA usage pattern. You only need a full
Java EE server if you want JTA (distributed transactions)
or EJB container-managed persistence context lifecycle.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application deploys on WildFly but fails
with ClassNotFoundException for a library**

*Symptom:* WAR deploys successfully but throws
`ClassNotFoundException` for a class that exists
in a JAR inside WEB-INF/lib.

*Root cause:* WildFly uses a modular classloading
system (JBoss Modules). The app server classloader
hierarchy may conflict with libraries bundled in
the WAR. Common with logging frameworks, XML parsers,
and database drivers.

*Diagnosis:*
```bash
# Check WildFly server log for classloader issues:
grep -i "classloader\|ClassNotFoundException" \
  standalone/log/server.log

# Check module visibility configuration
cat WEB-INF/jboss-deployment-structure.xml

# Check which classloader loaded a class:
# Add to application code (debug only):
System.out.println(
    SomeClass.class.getClassLoader()
);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```xml
<!-- WEB-INF/jboss-deployment-structure.xml -->
<jboss-deployment-structure>
  <deployment>
    <exclusions>
      <!-- Exclude WildFly's built-in version -->
      <module name="org.slf4j"/>
    </exclusions>
    <local-last>false</local-last>
  </deployment>
</jboss-deployment-structure>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Or: use `<local-last>false</local-last>` to prefer
app server modules, or set it to `true` to prefer
the WAR's own libraries.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Major application servers comparison | 3-4 min |
| WildFly vs Quarkus for new project | 3-4 min |
| Why use Quarkus over WildFly? | 2-3 min |
| Application server startup time problem | 2-3 min |
| Classloading in WildFly | 3-4 min |
| Migrating from WebLogic to Open Liberty | 3-4 min |
| WebLogic vs WildFly in enterprise | 2-3 min |

---

**[MID] Q1 - How do you choose between WildFly
and Quarkus for a new Java EE project?**

*Why they ask:* Modern platform selection.

WildFly: full Jakarta EE server, traditional deployment
model (WAR/EAR), large ecosystem, well-documented.
Choose when: team knows Java EE deeply, need full
Jakarta EE profile (EJB remoting, clustering), existing
WildFly deployment infrastructure.

Quarkus: compile-time CDI, native compilation, cloud-native.
Choose when: deploying to Kubernetes, need fast startup
(auto-scaling), writing microservices, need GraalVM native.

Practical differences:
- Startup: WildFly 8-15s; Quarkus JVM 1-2s; native 50ms
- Memory: WildFly 200-300MB RSS; Quarkus native 50MB RSS
- Deployment: WildFly WAR; Quarkus uber-jar or native binary
- Testing: both support integration testing; Quarkus @QuarkusTest starts faster
- Extensions: Quarkus extensions replace WildFly subsystems

For new microservices in 2026: Quarkus is the clear winner on cloud efficiency. For applications that need the full Jakarta EE profile (EJB clustering, JCA connectors) or teams migrating from WildFly: stay on WildFly.

*What separates good from great:* "Quarkus is not a drop-in replacement for WildFly. Quarkus requires build-time extensions; if a library isn't supported by a Quarkus extension, you can't use it. WildFly is more permissive but heavier."

---

**[MID] Q2 - What is GraalVM native image and
why does Quarkus use it?**

*Why they ask:* Modern Java cloud deployment.

GraalVM native image: compiles Java bytecode to
a standalone native binary at build time. The result
is an executable that starts without a JVM.

Advantages:
- Startup: milliseconds (JVM = seconds)
- Memory footprint: 50-100MB vs 200-300MB for JVM
- No JVM needed in the container

Quarkus uses native image via its compile-time DI.
Traditional Java EE uses reflection heavily (for DI,
JPA, etc.) at runtime - incompatible with native image.
Quarkus moves this work to build time:
- CDI beans wired at compile time
- JPA entity mapping processed at compile time
- Startup-time initialization done at build time

Constraint: native image cannot load new classes
at runtime. Dynamic class loading (common in Java EE
apps) is not supported without GraalVM configuration.
Quarkus extensions pre-configure the reflection
registries needed.

*What separates good from great:* "GraalVM native is a deployment optimization, not a programming model change. The code looks the same. The trade-off: build time increases significantly (5-10 minutes vs 30 seconds for JVM). Development uses JVM mode; production can use native. Quarkus dev mode uses JVM."

---

**[SENIOR] Q3 - How does classloading work in
WildFly and why does it cause issues?**

*Why they ask:* Production WildFly knowledge.

WildFly uses JBoss Modules, a hierarchy of classloaders:

```
WildFly Module System:
  System modules: JDK + WildFly core
    |
    v
  Subsystem modules: ee, ejb3, jpa, webservices, etc.
    |
    v
  Deployment classloader: your WAR/EAR
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Each module has explicit dependencies on other modules.
A deployment can see only the modules it explicitly
or implicitly imports.

Issues arise when:
1. Library in WEB-INF/lib conflicts with a WildFly
   module (same class, different versions).
2. Library uses reflection to load classes by name
   (Class.forName) that are in a different classloader.
3. EAR with multiple WARs: each WAR has its own classloader;
   shared classes must go in the EAR's lib/.

Control via `jboss-deployment-structure.xml`:
- Exclude conflicting modules
- Add dependencies on WildFly modules
- Control parent-last vs parent-first loading

*What separates good from great:* "The most common classloader issue: logging frameworks. WildFly ships its own JBoss Logging module. If your app also bundles SLF4J or Log4j2, you get classloader conflicts. The fix: exclude the WildFly module and use your own, or rely on WildFly's logging subsystem."

---

**[SENIOR] Q4 - What is the migration path from
WebLogic to WildFly or Open Liberty?**

*Why they ask:* Enterprise migration experience.

WebLogic-to-WildFly migration steps:

1. Code assessment: scan for WebLogic-specific APIs
   (com.bea.*, weblogic.*). These must be replaced.

2. Deployment descriptor translation:
   - `weblogic.xml` (WebLogic-specific) -> not needed
   - `weblogic-ejb-jar.xml` -> not needed
   - JNDI names may differ

3. Datasource reconfiguration: WebLogic datasources
   are configured in the admin console; WildFly uses
   CLI or XML.

4. Security realm migration: WebLogic security realm
   -> JAAS login module in WildFly.

5. EJB clustering: WebLogic has proprietary clustering;
   WildFly uses JBoss clustering (Infinispan, JGroups).

Tools: OpenRewrite has migration recipes. Migrate3
(Intellij plugin) identifies WebLogic-specific code.

Biggest risk: EJB remote calls (RMI/IIOP).
WebLogic's IIOP implementation is proprietary.
Migrating remote EJBs to REST or JMS is required
before moving off WebLogic in many cases.

*What separates good from great:* "The hardest part of WebLogic migration is the EJB remote call inventory. If internal systems call the application via RMI/IIOP, those callers must also change. That's often outside your team's control. I'd inventory and replace remote EJB interfaces with REST before attempting the server migration."

---

**[MID] Q5 - How do you containerize a WildFly application?**

*Why they ask:* Practical deployment modernization.

Basic containerization:
```dockerfile
FROM quay.io/wildfly/wildfly:31.0.0.Final-jdk21
COPY target/myapp.war /opt/jboss/wildfly/standalone/\
deployments/
EXPOSE 8080
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

But this is "lift and shift" - startup is still 15s,
image is 500MB. Improvements:

1. WildFly bootable JAR (Galleon layers):
   Package only the WildFly subsystems you use.
   Result: smaller image, faster startup.
   ```xml
   <plugin>
     <groupId>org.wildfly.plugins</groupId>
     <artifactId>wildfly-jar-maven-plugin</artifactId>
     <configuration>
       <feature-pack-location>
         wildfly@maven(org.jboss.universe:...)
       </feature-pack-location>
       <layers>
         <layer>jpa</layer>
         <layer>jaxrs</layer>
         <layer>cdi</layer>
       </layers>
     </configuration>
   </plugin>
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Environment-based datasource config:
   Pass JNDI datasource URL as environment variable.
   Don't hard-code database credentials.

3. Health and readiness probes:
   WildFly exposes /health (via MicroProfile Health)
   for Kubernetes liveness/readiness.

*What separates good from great:* "The Galleon layers approach is the right way to containerize WildFly - it reduces the image from 500MB to 100-150MB by including only the subsystems you use. Combined with a multi-stage build to compile the WAR, you get a production-grade image."

---

**[MID] Q6 - What is the difference between
JBoss EAP and WildFly?**

*Why they ask:* Common enterprise question.

WildFly: upstream open-source project. Community-supported.
Frequent releases. Used for development and evaluation.

JBoss EAP (Enterprise Application Platform):
Red Hat's commercial, supported product based on WildFly.
Differences:
- Red Hat support subscription required
- Longer support cycles (N years of maintenance)
- Stability: tested over longer period
- Certified with RHEL, OpenShift, SAP
- Security patches provided proactively by Red Hat

EAP major versions lag behind WildFly:
- EAP 8.0 = based on WildFly 27/28
- Usually 1-2 WildFly release cycles behind

When to use EAP vs WildFly:
- Production enterprise: EAP (support contract)
- Development/testing: WildFly
- Open-source project: WildFly

*What separates good from great:* "The EAP/WildFly distinction is identical to RHEL/Fedora. WildFly is the community innovation; EAP is the enterprise-stabilized fork with long-term support. If a customer requires Red Hat-certified deployments, EAP is the answer."

---

**[SENIOR] Q7 - How do you configure high availability
clustering in WildFly?**

*Why they ask:* Production enterprise Java experience.

WildFly HA clustering uses two technologies:
- JGroups: cluster member discovery and communication
- Infinispan: distributed cache (shared sessions, entity caching)

Two clustering modes:

1. WildFly domain mode:
   - Domain controller manages multiple host controllers
   - Consistent configuration across all nodes
   - Suitable for on-prem traditional deployments

2. Standalone instances + load balancer:
   - Each node runs standalone mode
   - Load balancer (HAProxy, mod_cluster) distributes requests
   - Simpler; used in cloud deployments

HTTP session replication:
```xml
<!-- In standalone-ha.xml, sessions replicated via
     Infinispan distributed cache -->
<subsystem xmlns="urn:jboss:domain:distributable-web:3.0">
  <infinispan-session-management
    name="distributable"
    cache-container="web">
    <primary-owner-routing/>
  </infinispan-session-management>
</subsystem>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Modern alternative: store sessions in Redis or
the client (JWT). Avoid container-managed session
replication: it's complex and the failure modes
are hard to debug.

*What separates good from great:* "I'd avoid WildFly domain mode in Kubernetes - it's designed for on-prem bare metal with a fixed cluster size. In k8s, standalone + load balancer + stateless applications is simpler and more reliable. If sessions are needed, Redis > Infinispan replication."

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



