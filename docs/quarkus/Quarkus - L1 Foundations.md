---
layout: default
title: "Quarkus - L1 Foundations"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 2
permalink: /quarkus/l1-foundations/
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

> **Code walkthrough:** @ApplicationScoped creates a
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
but without the CDI proxy overhead."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | CDI scopes, @Inject, @Produces |
| Senior | 6 min | Proxy model, @ApplicationScoped vs @Singleton, observers |

---

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
config for local development."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Dev Mode, live reload, Dev Services |
| Senior | 6 min | Class loader model, Dev Services architecture, Continuous Testing |

---

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

Customization:
```properties
# application.properties
%test.quarkus.datasource.devservices.image-name=
  postgres:16
%test.quarkus.datasource.devservices.port=5433
```

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

> **Code walkthrough:** @ConfigProperty injects a single
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
@ConfigProperty fields for complex config."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @ConfigProperty, profiles |
| Senior | 6 min | @ConfigMapping, build-time vs runtime, secrets management |

---

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

Option 3: AWS Secrets Manager:
```properties
quarkus.vault.url is replaced by
quarkus.amazon.secretsmanager.*
```

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
for native image builds."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Adding extensions, BOM usage |
| Senior | 6 min | Extension dual-artifact, deployment vs runtime, native image |

---

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

Step 4: Include generated config in native build:
```
src/main/resources/META-INF/native-image/
  reflect-config.json
  resource-config.json
```

Step 5: For initialization issues:
```properties
# application.properties
quarkus.native.additional-build-args=
  --initialize-at-run-time=com.problematic.Class
```

*What separates good from great:* Tracing agent as
the automated way to discover reflection needs.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Extension model, BOM, extension categories. |
| Hiring Manager | Rich extension ecosystem for productivity. |
| Bar Raiser | Deployment vs runtime artifact, adding libraries without extensions. |
| Peer Engineer | "Used tracing agent for a library without an extension. Generated reflect-config.json in 20 minutes." |
