---
layout: default
title: "Spring - META Patterns"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 17
permalink: /spring/meta-patterns/
render_with_liquid: false
---

# Spring - META Patterns

---

# IoC Container as Dependency Graph Mental Model

---
id: SPR-030
title: IoC Container as Dependency Graph Mental Model
category: Spring
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid/Senior
seniority: mid
tags: #spring-mental-model, #ioc, #dependency-graph, #transferable
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> The Spring IoC container is a directed acyclic graph of objects. Each bean
> is a node; each dependency is a directed edge. The container resolves the graph
> at startup by topological sort - beans with no dependencies are created first,
> then beans that depend on them, until all beans are created. This mental model
> explains circular dependency errors (cycles in the graph), lazy initialization
> (defer node creation), and why the container startup order is deterministic.

**3 minutes:**
> A dependency graph is a DAG (Directed Acyclic Graph) where nodes are beans
> and edges go from dependent to dependency. UserController -> UserService ->
> UserRepository -> DataSource. The container does topological sort: DataSource
> first (no deps), then UserRepository, then UserService, then UserController.
> Circular dependencies (A -> B -> A) create a cycle in the graph. Cycles are
> impossible to topologically sort (which comes first?), so Spring throws
> BeanCurrentlyInCreationException.
>
> With setter injection, cycles CAN be resolved: Spring creates bean A (empty),
> creates bean B (empty), injects A into B (A is now "complete enough"),
> injects B into A. The cycle is broken because the bean exists before being
> fully initialized. But this is a design smell: a real circular dependency
> usually signals the two beans should be one or there's a domain modeling error.
>
> Prototype scope breaks the graph assumption: a prototype-scoped bean is not
> a node in the graph - it's a factory. Requesting a prototype creates a new
> object every time. Injecting a prototype into a singleton is a common mistake
> (the singleton holds one reference to the first prototype instance, which
> defeats the purpose of prototype scope).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking me to explain the mental model of thinking
about Spring beans as a graph of dependencies."

**(2) First principles:** "Any system where objects need other objects creates
a dependency structure. A graph is the natural representation: objects as nodes,
dependencies as edges. The container's job is to construct all nodes in an
order that satisfies all edges."

**(3) Bridge:** "The dependency graph is like a recipe book where some recipes
depend on sauces from other recipes. You can't make Beef Bourguignon before
you make the red wine reduction it needs. The recipe order is a topological sort.
Circular recipes (sauce A needs sauce B which needs sauce A) are impossible to
make - just like circular Spring bean dependencies."

---

### 📘 Concept Explanation

**What it is:**
A mental model that maps the Spring IoC container's operation to a well-known
computer science concept: the directed acyclic graph. Using this model makes
Spring behavior predictable.

**The model in full:**

```
Spring IoC = DAG construction algorithm:

Nodes: beans (singleton instances)
Edges: dependency relationships (A needs B)
Direction: from dependent to dependency

Example:
  OrderController
    -> OrderService
         -> OrderRepository
              -> DataSource (HikariPool)
         -> PaymentService
              -> PaymentGatewayClient
                   -> HttpClient

Graph (edges point to dependencies):
  OrderController -> OrderService
  OrderService -> OrderRepository
  OrderService -> PaymentService
  OrderRepository -> DataSource
  PaymentService -> PaymentGatewayClient
  PaymentGatewayClient -> HttpClient

Topological sort (construction order):
  1. HttpClient           (no dependencies)
  2. DataSource           (no dependencies)
  3. PaymentGatewayClient (needs HttpClient - ready)
  4. OrderRepository      (needs DataSource - ready)
  5. PaymentService       (needs PaymentGatewayClient - ready)
  6. OrderService         (needs Repo + PaymentSvc - ready)
  7. OrderController      (needs OrderService - ready)

What breaks the DAG:
  Cycle: A -> B -> A (topological sort impossible)
  -> BeanCurrentlyInCreationException

  Diamond dependency (not a problem):
  A -> B and A -> C and B -> D and C -> D
  -> D created once (singleton), shared by B and C
  -> This is fine! Just means D is created before B and C.
```

**Why this model matters:**

```
Q: Why does Spring fail with BeanCurrentlyInCreationException?
A: Graph has a cycle. Constructor injection (most common cause):
   Spring creates OrderService -> needs InvoiceService
   Spring creates InvoiceService -> needs OrderService
   OrderService not yet created -> CYCLE DETECTED

Q: Why does @Lazy fix circular dependencies?
A: @Lazy inserts a proxy node instead of the real bean.
   OrderService -> lazy proxy of InvoiceService (created immediately)
   Proxy node breaks the cycle (proxy has no deps)
   Real InvoiceService created only when proxy is first called

Q: Why does prototype scope injection into singleton not refresh?
A: Singleton is a node created ONCE.
   Its dependencies (edges) are resolved ONCE at creation.
   Prototype dependency = edge to "always create new node"
   But the singleton's constructor ran once and stored the reference.
   The reference never updates.
   Fix: inject ApplicationContext and getBean() each time,
        or use ObjectProvider<T>, or @Lookup injection.
```

---

### 💻 Code Example

```java
// BAD: circular dependency (graph cycle)
@Service
public class OrderService {
    // Constructor injection creates cycle
    public OrderService(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }
}

@Service
public class InvoiceService {
    // Constructor injection creates cycle
    public InvoiceService(OrderService orderService) {
        this.orderService = orderService;
    }
}
// Error: BeanCurrentlyInCreationException
// The graph has a cycle: OrderService <-> InvoiceService

// GOOD: break cycle by extracting shared dependency
@Service
public class OrderService {
    // Extract shared logic to separate bean
    public OrderService(OrderEventPublisher events) {
        this.events = events;
    }
    public void placeOrder(Order order) {
        // OrderService no longer depends on InvoiceService
        events.orderPlaced(order);
    }
}

@Service
public class InvoiceService {
    // InvoiceService listens to events, doesn't call OrderService
    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        createInvoice(event.getOrder());
    }
}
// No cycle: OrderService -> OrderEventPublisher
//           InvoiceService depends on event system
// The dependency graph is now a proper DAG
```

> **Code walkthrough:** Circular dependency is almost always a domain model
> problem disguised as a technical error. OrderService needing InvoiceService
> AND InvoiceService needing OrderService means they are too tightly coupled.
> The fix: identify what each service ACTUALLY needs from the other.
> Usually it's just notification ("an order was placed"). An event publisher
> breaks the cycle: OrderService fires events, InvoiceService listens.
> Neither depends on the other. The dependency graph becomes a DAG again.

```java
// BAD: prototype dependency in singleton (stale reference)
@Service
public class ReportService {
    private final ReportContext ctx;  // prototype bean

    public ReportService(ReportContext ctx) {
        // ctx is ONE instance, created at injection time
        // Subsequent calls reuse same stale ctx
        this.ctx = ctx;
    }
}

// GOOD: use ObjectProvider to get fresh instance
@Service
public class ReportService {
    private final ObjectProvider<ReportContext> ctxProvider;

    public ReportService(
            ObjectProvider<ReportContext> ctxProvider) {
        this.ctxProvider = ctxProvider;
    }

    public Report generate(ReportRequest req) {
        // New ReportContext for each report generation
        ReportContext ctx = ctxProvider.getObject();
        return ctx.generate(req);
    }
}
```

> **Code walkthrough:** ObjectProvider<T> is Spring's lazy-resolution proxy
> for dependencies. For prototype beans: getObject() creates a new instance
> each call. For optional beans: getIfAvailable() returns null instead of
> throwing NoSuchBeanDefinitionException. ObjectProvider is the type-safe
> alternative to ApplicationContext.getBean(). The prototype bean is "connected"
> to the singleton via the ObjectProvider edge in the dependency graph, but
> the edge is a factory edge (creates new nodes), not a reference edge
> (shares existing nodes).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Think of Spring beans like a recipe book. OrderService is a recipe that needs
> ingredients from other recipes (UserService, Repository). Spring figures out
> which order to make everything so all ingredients are ready when needed.
> If recipe A needs recipe B and recipe B needs recipe A, that's impossible -
> Spring throws an error about circular dependencies.

**Senior / Staff:**
> The DAG mental model explains multiple Spring behaviors with one framework.
> Circular deps = cycle detection. Startup order = topological sort.
> Singleton = shared node. Prototype = factory edge, not node. @Lazy = deferred
> node. BeanFactory.getBean() = node lookup. @DependsOn = artificial edge
> (no actual dependency, but enforces ordering). @PostConstruct = node initialization
> hook after all edges are wired. Understanding the graph makes debugging
> startup issues faster: look for cycles (BeanCurrentlyInCreationException),
> missing nodes (NoSuchBeanDefinitionException), and timing issues (bean needed
> before BeanPostProcessor that creates it is ready).

---

### ⚠️ Common Misconceptions

**Misconception: "Setter injection fixes circular dependencies properly."**
Setter injection allows circular dependencies by letting Spring create beans
in an incomplete state. A->B cycle with setters: Spring creates A (no deps yet),
creates B (needs A, A exists but no setters called yet, B gets reference to
incomplete A), then calls A's setter with B. The cycle "resolves" but A was
injected into B in a partially-initialized state. This is risky: if A uses B
in its @PostConstruct, and B uses A in its constructor, the A reference in B is
still incomplete. Fix cycles by redesigning, not by switching injection type.

---

### 🚨 Failure Modes and Diagnosis

**Failure: BeanCurrentlyInCreationException**
Symptom: Stack trace showing circular reference.
Diagnosis: Spring Boot 2.6+ will print the cycle:
  "orderService -> invoiceService -> orderService"
Fix: break the cycle by extracting shared logic, using events, or
  (last resort) @Lazy on one side to defer one bean's initialization.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - Why does Spring fail on circular constructor injection but not setter injection?

Constructor injection: to construct A, you need B. To construct B, you need A.
Neither can be constructed - deadlock. Spring detects: "I am currently creating
A and trying to create A again" -> BeanCurrentlyInCreationException.

Setter injection: Spring constructs A (no args needed), constructs B (no args
needed), calls A.setB(b), calls B.setA(a). The objects exist before any setter
is called. Spring's SingletonBeanRegistry.getSingleton() has an "early exposure"
mechanism: partially constructed singletons are accessible via the singletonFactories
map. When B needs A during B's construction, Spring finds A's "early" reference
(partially constructed) and provides it.

This is why constructor injection is PREFERRED - it makes circular dependencies
impossible (a good constraint). With setter injection, cycles silently work but
produce potentially-broken objects.

*What separates good from great:* Spring Boot 2.6 made circular dependency
detection for ALL injection types throw by default, not just constructor injection.
Setting spring.main.allow-circular-references=true re-enables the old behavior.
The change was intentional: setter injection circular dependencies were always
risky, and the default should push developers to fix the underlying design problem
rather than rely on a framework workaround.

---

#### Q2 - What is @DependsOn and when should you use it?

@DependsOn creates an artificial ordering edge in the dependency graph:

```java
@Service
@DependsOn("databaseInitializer")
public class ProductCatalogService {
    // ProductCatalogService must initialize AFTER
    // databaseInitializer, even though it doesn't
    // directly depend on it.
}

@Component("databaseInitializer")
public class DatabaseInitializer {
    @PostConstruct
    public void initialize() {
        // Run schema migrations, seed data
        // Must complete before ProductCatalogService starts
    }
}
```

Use cases:
- Database initialization before service startup
- External system registration before bean that uses it
- Schema migration (Flyway/Liquibase) before JPA beans

In the DAG: @DependsOn adds an edge without a direct dependency.
It says "I need you to exist before me" without injecting you.

*What separates good from great:* @DependsOn is a design smell if used
for business logic. It's legitimate for infrastructure initialization ordering.
Flyway is automatically detected by Spring Boot and auto-configured to run
before JPA (via @AutoConfigureBefore). If you're hand-rolling the same pattern
with @DependsOn, consider whether a library like Flyway handles it better.
For custom initialization, @EventListener(ContextRefreshedEvent.class) provides
a hook AFTER all beans are initialized - often the right solution instead of
artificially ordering bean creation.

---

#### Q3 - How does Spring resolve multiple beans of the same type?

```java
// Multiple Payment strategies:
@Service("stripePayment")
public class StripePaymentService implements PaymentService {}

@Service("paypalPayment")
public class PayPalPaymentService implements PaymentService {}

// Injection options:
@Service
public class CheckoutService {

    // Option 1: @Qualifier
    @Autowired
    @Qualifier("stripePayment")
    private PaymentService paymentService;

    // Option 2: inject all into List
    @Autowired
    private List<PaymentService> allPaymentServices;

    // Option 3: inject into Map (name -> bean)
    @Autowired
    private Map<String, PaymentService> paymentServices;
    // paymentServices.get("stripePayment")

    // Option 4: @Primary on one implementation
    // @Primary marks Stripe as default
}
```

Graph perspective: multiple nodes implement the same interface.
When an edge points to the interface type, Spring must choose which node.
Resolution order: @Primary > @Qualifier > type matching.

*What separates good from great:* Injecting a Map<String, PaymentService>
is the pattern for pluggable strategy selection. The map key is the bean name.
This supports adding new PaymentService implementations without modifying
CheckoutService (Open-Closed Principle). The caller looks up by strategy name:
paymentServices.get(user.getPreferredPaymentMethod()). This is the Strategy
pattern + DI: new strategies are just new @Service beans, automatically
included in the map. No factory class, no if-else chain.

---

#### Q4 - How does the graph model explain @Scope("prototype") behavior?

Prototype beans break the "one node per type" assumption:

```
Singleton bean A
  -> Prototype bean B

In graph terms:
  A is a node (created once)
  B is a factory (creates new node each time)
  But A stores a REFERENCE to ONE instance of B
  (from the time A was created)

  This means:
  A.getB() always returns the SAME B instance
  Even though B is prototype scope
  The factory was called ONCE (at A creation)
  After that, A holds a direct reference, bypasses factory

Fix: A stores a factory (ObjectProvider<B>), not a B
  A.createB() calls provider.getObject() each time
  Each call creates a new B instance
  This is what "prototype" actually means
```

*What separates good from great:* @Scope("prototype") on a bean used by
a singleton is a code smell without ObjectProvider. The IDE and compiler don't
warn you - the injection "works" but creates a singleton-behaving prototype.
Inspecting the running application: you'll see one B instance, not many.
The @Scope Javadoc specifically says: "each injection point gets its own instance
only when it is a prototype-to-prototype injection or when using ObjectProvider."
Prototype scope is mostly useful for stateful beans (like a ReportContext that
holds report-generation state) where you truly need a fresh instance per operation.

---

#### Q5 - What is the difference between BeanFactory and ApplicationContext in graph terms?

BeanFactory: the basic graph. Nodes are beans, edges are dependencies.
getBean() resolves nodes on demand (lazy).

ApplicationContext: extends BeanFactory. Pre-instantiates all singleton nodes
(eager creation at refresh() time). Adds:
- Event publishing (ApplicationEventPublisher)
- Message source (MessageSource)
- Resource loading (ResourceLoader)
- BeanPostProcessor application (decorates nodes)

Graph metaphor:
- BeanFactory = lazy graph (nodes created on first access)
- ApplicationContext = eager graph (all singleton nodes created at startup)

The ApplicationContext.refresh() method is where the graph is "realized":
all singleton beans created, all edges (dependencies) resolved, all
BeanPostProcessors applied.

*What separates good from great:* BeanFactory's lazy creation means errors
surface late (at first getBean() call, not at startup). ApplicationContext's
eager creation means errors at startup (fail-fast). In production: ApplicationContext
is always preferred. BeanFactory is used in testing (lightweight, selective
bean creation) or very embedded environments. The "prefer constructor injection"
advice connects to this: constructor injection failures happen at bean creation
time (caught at startup with ApplicationContext). Field injection failures happen
at first use (runtime error, harder to diagnose).

---

#### Q6 - How does Spring's graph model relate to modulith and microservices architecture?

The dependency graph idea scales beyond a single application:

```
Single application (Spring ApplicationContext):
  Node = Bean, Edge = @Autowired dependency
  Rule: no cycles

Spring Modulith (single JVM, multiple modules):
  Node = Module (@ApplicationModule package)
  Edge = cross-module dependency
  Rule: no cycles (enforced by Modulith)
  ArchUnit checks: Module A -> Module B, but B !-> A

Microservices (distributed):
  Node = Service, Edge = HTTP/event dependency
  Rule: cycles cause cascading failures
  Tool: Strangler fig for migration,
        circuit breakers for resilience

The mental model transfers:
  Cycle in beans -> BeanCurrentlyInCreationException
  Cycle in modules -> circular package import
  Cycle in services -> infinite retry loops,
                       deployment ordering deadlock
```

*What separates good from great:* The DAG constraint is not Spring-specific.
Every well-designed system at any level of abstraction should be a DAG.
Layered architecture (Controller -> Service -> Repository) is a DAG.
Hexagonal architecture (Adapters -> Application -> Domain) is a DAG.
Package-by-layer enforces a DAG by convention. Spring Modulith enforces it
for application modules by code analysis. Microservices architectures that
violate the DAG property (service A can't deploy without service B and vice versa)
have the same cycle problem Spring throws errors for, just with harder-to-diagnose
symptoms (deployment deadlocks, cascading failures).

---

#### Q7 - How does the dependency graph mental model help during code reviews?

```
Code review checklist using the DAG model:

1. Does this new @Autowired create a cycle?
   PR adds: OrderService -> InvoiceService
   Existing: InvoiceService -> OrderService? (check)
   If yes: cycle introduced, reject PR

2. Is this prototype bean injected into a singleton?
   @Scope("prototype") dependency in constructor?
   -> Check: is it wrapped in ObjectProvider?
   -> If direct field injection: flag it

3. Does this service depend on a layer below it?
   New Controller -> Repository (bypasses Service)?
   -> Flag: violates layering (DAG would allow it,
            architecture doesn't)

4. Is this bean in the right context?
   @Transactional bean in WebApplicationContext?
   -> Flag: TransactionManager is in root context

Mental model value:
  Reading code, you can visualize the subgraph
  introduced by a PR and check for violations
  before running any tests.
```

*What separates good from great:* The graph mental model makes code review
faster and more objective. "This creates a circular dependency" is a concrete
observation, not a style preference. "This prototype is effectively a singleton"
is verifiable from the code structure. Tools like ArchUnit can automate these
checks: forbidden dependencies between packages, no cyclic dependencies between
modules, layer enforcement. The mental model drives what rules to encode.
A team that internalizes the DAG model naturally writes code that's easier to
maintain, test, and extend.

---

# Convention Over Configuration Transfer

---
id: SPR-031
title: Convention Over Configuration Transfer
category: Spring
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid/Senior
seniority: mid
tags: #spring-meta, #convention, #auto-configuration, #transferable
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Convention Over Configuration (CoC) means the framework does the right thing
> by default without you explicitly requesting it. Spring Boot applies this:
> DataSource auto-configured if spring.datasource.url is set, Tomcat started
> if spring-boot-starter-web is on classpath, JPA repositories enabled if
> spring-data-jpa is present. You only configure when you deviate from the
> convention. This principle transfers to every framework and API you design.

**3 minutes:**
> CoC originated with Ruby on Rails. Spring Boot adopted it aggressively.
> The Spring Boot auto-configuration system is CoC in code: @ConditionalOnClass,
> @ConditionalOnMissingBean, @ConditionalOnProperty. The convention: "if you
> have this on classpath, you probably want this bean." The escape hatch:
> "if you've already created this bean, I'll skip mine" (@ConditionalOnMissingBean).
>
> The principle transfers: when designing any API or system, ask "what would
> the user want 80% of the time?" and make that the default. Make deviating
> from the default explicit. Spring Data convention: repository methods named
> findByEmail parse to SELECT...WHERE email=? without SQL. Convention: method
> name is the query. The user only writes custom @Query when the convention
> can't express the query.
>
> The anti-pattern: over-configuration. XML Spring configuration required
> explicit wiring for every bean. 100 beans = 100 XML entries. CoC eliminates
> the 90% that follow standard patterns and forces explicitness only for
> the 10% that don't.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking me to explain the Convention Over Configuration
principle as applied in Spring Boot and how the thinking transfers to other contexts."

**(2) First principles:** "Configuration is a form of specification. If the
developer has to specify everything, development is slow and configuration
files are large. Conventions define standard behavior. Defaults should be
the most common case. Explicit configuration should only be needed for deviation."

**(3) Bridge:** "CoC is like a new employee handbook that says 'do X unless
told otherwise.' The employee (framework) follows the handbook (convention)
without being told each time. When the manager (developer) wants something
different, they say so explicitly. Without a handbook: the manager specifies
every action for every situation - exhausting and error-prone."

---

### 📘 Concept Explanation

**What it is:**
Convention Over Configuration is a software design philosophy that reduces the
number of decisions developers must make by providing sensible defaults, requiring
explicit configuration only when departing from the convention.

**CoC in Spring Boot:**

```
Convention: "If spring-boot-starter-web is on classpath,
             start an embedded Tomcat on port 8080."
Override:   "server.port=9090" (explicit deviation)

Convention: "If DataSource is configured,
             create JdbcTemplate and DataSourceTransactionManager."
Override:   Define your own @Bean JdbcTemplate

Convention: "Repository interface named findByEmail(String email)
             generates SELECT * FROM user WHERE email=?"
Override:   @Query("SELECT u FROM User u WHERE u.email = ?1")

Convention: "application.properties / application.yml
             is the primary configuration file."
Override:   spring.config.name=custom-config

Convention: "@SpringBootApplication scans current package
             and all sub-packages for components."
Override:   @ComponentScan(basePackages = "com.other")
```

**When CoC breaks down (and how to detect it):**

```
1. Convention produces wrong result
   Symptom: unexpected behavior at startup
   Diagnosis: check auto-configuration report
   (--debug flag or actuator /actuator/conditions)

2. Convention conflicts with requirement
   Example: multiple DataSources needed
   Spring's convention: auto-configure ONE DataSource
   Fix: exclude DataSourceAutoConfiguration, define both manually

3. Convention obscures what is happening
   New developer can't understand why something works
   without understanding the convention
   Fix: add documentation, use @Import explicitly to make it visible
```

---

### 💻 Code Example

```java
// BAD: fighting conventions with explicit config
@SpringBootApplication
@ComponentScan("com.myapp")    // already the convention
@EnableAutoConfiguration       // already done by @SpringBootApplication
@Configuration                 // already implied by @SpringBootApplication
public class App {

    @Bean                      // auto-configured by spring-boot-starter-web
    public DispatcherServlet dispatcherServlet() {
        return new DispatcherServlet();
    }

    @Bean                      // auto-configured by spring.datasource.*
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl(env.getProperty("spring.datasource.url"));
        return ds;
    }
}

// GOOD: let conventions work
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
// DataSource auto-configured from application.properties
// DispatcherServlet auto-configured
// Port 8080 by default
// Only override what needs overriding
```

> **Code walkthrough:** The BAD example re-creates what Spring Boot provides
> for free. @SpringBootApplication = @Configuration + @EnableAutoConfiguration
> + @ComponentScan. The DataSource bean re-implements what HikariDataSourceAutoConfiguration
> already does. The DispatcherServlet bean recreates what DispatcherServletAutoConfiguration
> provides. This is "convention fighting" - working against the framework
> instead of with it. Result: more code, more configuration to maintain,
> and the auto-configuration report shows your beans displacing the default ones
> (exactly what @ConditionalOnMissingBean was designed for).

```java
// Applying CoC to your own API design:

// BAD: require explicit configuration for common case
public class HttpClient {
    // User must specify everything
    public HttpClient(String baseUrl, int timeoutMs,
                      boolean followRedirects,
                      boolean compressionEnabled,
                      int maxConnections, ...) { }
}

// Usage: verbose, error-prone
new HttpClient("http://api", 5000, true, true, 10, ...);

// GOOD: convention with builder (deviation is explicit)
public class HttpClient {
    // Conventions (sensible defaults)
    private int timeoutMs = 5000;
    private boolean followRedirects = true;
    private boolean compressionEnabled = true;
    private int maxConnections = 10;

    // Only required: the URL (no sensible default)
    private final String baseUrl;

    // Builder for explicit overrides
    public static Builder builder(String baseUrl) {
        return new Builder(baseUrl);
    }

    public static class Builder {
        // setters for deviation only
        public Builder timeout(int ms) { ... return this; }
        public Builder noRedirects() { ... return this; }
        public HttpClient build() { ... }
    }
}

// Usage: minimal for common case
HttpClient client = HttpClient
    .builder("http://api").build();
// Override only when needed:
HttpClient slow = HttpClient.builder("http://slow-api")
    .timeout(30_000).build();
```

> **Code walkthrough:** The Builder pattern is CoC in API design. The required
> parameter (baseUrl) must be explicit. Optional parameters have sensible defaults
> and are ONLY specified when the user deviates from convention. This is how
> Spring Boot's builders work (SpringApplicationBuilder, WebClient.Builder).
> The principle: "Make the right thing easy, make the wrong thing hard, and
> make deviation explicit." The BAD example makes all decisions require explicit
> specification. The GOOD example requires explicitness only for deviations.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Convention Over Configuration means Spring Boot sets up standard things
> automatically. If you add spring-boot-starter-web to your project, you get
> a running web server without any configuration. If you add a DataSource
> URL in application.properties, Spring creates the connection pool for you.
> You only add configuration when you need something different from the standard.
> It's about reducing boilerplate.

**Senior / Staff:**
> CoC is a design principle that transfers beyond Spring. When designing libraries
> or services: identify the 80% case and make it require zero configuration.
> The remaining 20% (deviation from convention) should be explicit. Applied to
> system design: use well-known defaults (port 443 for HTTPS, port 80 for HTTP,
> Redis cache keys by class+method+args). Applied to team workflow: naming
> conventions for branches (feature/, fix/, release/) eliminate decisions.
> The anti-pattern: over-configuration (requiring everything to be specified)
> slows teams, creates large config files, and makes onboarding hard. Spring Boot
> made Java web development competitive with Rails/Django by applying CoC to
> a traditionally verbose ecosystem.

---

### ⚠️ Common Misconceptions

**Misconception: "CoC means no configuration."**
CoC means LESS configuration, not zero. When your needs match the convention,
you write no configuration. When you deviate, you write explicit configuration
just for the deviation. Spring Boot has thousands of configuration properties
for deviations. The goal: one property to change one thing, not a complete
application description from scratch.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Auto-configuration does unexpected thing**
Symptom: A bean you didn't ask for is in your context, or a bean
you expect is missing.
Diagnosis: Enable auto-configuration report:
  java -jar myapp.jar --debug
  OR spring.autoconfigure.report.enable=true
Report shows: POSITIVE MATCHES (what was auto-configured), NEGATIVE MATCHES
(what was NOT configured and why), UNCONDITIONAL (always configured).
Fix: exclude specific auto-configuration, or provide your own bean to displace it.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - How does Spring Boot's auto-configuration report help debug unexpected behavior?

```bash
# Start with debug flag to see auto-configuration report
java -jar myapp.jar --debug

# Or in application.properties:
debug=true
```

Report sections:
1. POSITIVE MATCHES: auto-configurations that ran and WHY
   ```
   JdbcTemplateAutoConfiguration matched:
     @ConditionalOnClass DataSource (present)
     @ConditionalOnBean DataSource (yes, HikariCP)
   ```
2. NEGATIVE MATCHES: auto-configurations that did NOT run and WHY
   ```
   MongoAutoConfiguration did NOT match:
     @ConditionalOnClass MongoClient
     (MongoClient not on classpath)
   ```
3. EXCLUSIONS: auto-configurations explicitly excluded
4. UNCONDITIONAL: always run

Use case: "Why is my DataSource misconfigured?"
Check the report: HikariCP matched, found which property source provided the URL.

*What separates good from great:* The auto-configuration report is also
accessible via Actuator: GET /actuator/conditions. This is useful in production
to verify which conditions are active. Combine with /actuator/env to see
property sources and which values won. For CI/CD: run with --debug and parse
the report in integration tests to assert specific auto-configurations
are active (ensures the right starters are present).

---

#### Q2 - How does CoC apply to Spring Data repository method naming?

Spring Data derives queries from method names:

```java
// Convention: method name IS the query specification
interface UserRepository extends JpaRepository<User, Long> {
    // Convention: findBy + FieldName + [Condition]
    Optional<User> findByEmail(String email);
    // -> SELECT u FROM User u WHERE u.email = ?1

    List<User> findByLastNameAndActive(
        String lastName, boolean active);
    // -> WHERE last_name = ? AND active = ?

    List<User> findByCreatedAtAfterOrderByLastNameAsc(
        LocalDateTime after);
    // -> WHERE created_at > ? ORDER BY last_name ASC

    // Deviation: use @Query when method name can't express it
    @Query("SELECT u FROM User u WHERE " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', ?1, '%'))")
    List<User> findByEmailContainingIgnoreCase(String partial);
}
```

The convention: method name vocabulary includes:
- findBy, countBy, existsBy, deleteBy (operation)
- And, Or (conjunction)
- LessThan, GreaterThan, Between (range)
- Containing, StartingWith, EndingWith (String)
- OrderBy, Asc, Desc (sorting)
- First, Top (limiting)

*What separates good from great:* The Spring Data naming convention is
powerful but has limits: complex queries, subqueries, functions, native SQL.
@Query provides escape hatch. The "convention first, explicit when needed"
pattern is exactly CoC. When you find yourself writing overly long method names
(findByLastNameAndFirstNameAndEmailAndCreatedAtAfterAndActive...), switch to
@Query - it's more readable and maintainable. Method name queries are excellent
for simple lookups. @Query is the right tool for complex queries.

---

#### Q3 - How does Spring Boot's externalized configuration follow CoC?

Spring Boot defines a property loading order (convention):

```
Priority (highest first):
1. Command-line arguments (--server.port=9090)
2. System environment variables (SERVER_PORT=9090)
3. System properties (-Dserver.port=9090)
4. application-{profile}.properties (src/main/resources)
5. application.properties (src/main/resources)
6. @ConfigurationProperties defaults
7. @Value default values

Convention: application.properties is primary
Deviation: spring.config.location=file:/opt/myapp/config/
           -> use this path instead of classpath

Convention: profile-specific override (application-prod.yml)
Deviation: SPRING_CONFIG_NAME=custom-name
```

CoC in action: the app works correctly in different environments
(dev/staging/prod) by convention. Dev: application-dev.properties in classpath.
Prod: APPLICATION_ENV=prod (env var sets profile). No startup scripts
specifying 50 properties - the convention handles it.

*What separates good from great:* The 12-Factor App methodology (factor 3:
Config) aligns with Spring Boot's externalized configuration: environment-specific
config via environment variables, not hard-coded files. Spring Boot's convention
supports this: SPRING_DATASOURCE_URL (env var) overrides spring.datasource.url
(property file). Kubernetes secret -> env var -> Spring Boot property:
the secret is mounted without changing Spring Boot code. CoC enables this
transparency: the developer writes application.properties for local dev,
and the same app reads from env vars in production, by convention.

---

#### Q4 - Where does CoC break down and how do you handle it?

CoC limitations:

**1. Non-standard project structure:**
Default: @SpringBootApplication scans its own package and sub-packages.
If entities are in a different package (legacy code structure):
Spring Data JPA doesn't find them.
Fix: @EntityScan("com.legacy.domain"), @EnableJpaRepositories("com.legacy.repos")

**2. Multiple implementations of same type:**
Convention: ONE DataSource. Two DataSources = no convention.
Fix: @Primary on one DataSource, @Qualifier on injection points.
Or: exclude auto-configuration, configure both manually.

**3. Non-standard naming:**
Convention: application.properties. Legacy: myapp.properties.
Fix: spring.config.name=myapp

**4. Test-specific behavior:**
Convention: full auto-configuration. Tests want lightweight context.
Fix: @WebMvcTest (only web layer), @DataJpaTest (only JPA layer).
Spring Boot provides "slice" test annotations that override conventions
for specific test scenarios.

*What separates good from great:* Understanding WHERE CoC breaks helps
you decide how much convention to follow. Brownfield projects (legacy code)
often can't fully adopt conventions without large refactors. The strategy:
adopt conventions incrementally. Add @SpringBootApplication to the main class
(CoC for component scanning), then migrate to convention-based property files,
then convention-based repository naming. Each step reduces configuration
without requiring a full rewrite.

---

#### Q5 - How does the CoC principle apply to Kubernetes resource naming?

Kubernetes also uses conventions:

```yaml
# Convention: Service name matches Deployment name
# -> DNS: service-name.namespace.svc.cluster.local
apiVersion: v1
kind: Service
metadata:
  name: order-service  # matches Deployment name
spec:
  selector:
    app: order-service  # matches pod label

# Spring Cloud Kubernetes convention:
# spring.application.name=order-service
# -> reads ConfigMap named "order-service"
# -> discovers Service named "order-service"
# Convention eliminates need to specify which ConfigMap
# and which Service to connect to.

# Override (deviation from convention):
spring.cloud.kubernetes.config.sources[0].name=\
  my-custom-configmap  # explicit name
```

Deviation when needed:
- Shared ConfigMap between services
- Service name != application name
- Multi-namespace configuration

*What separates good from great:* Kubernetes naming conventions enable
GitOps automation. If all resources follow consistent naming (order-service
for Deployment, Service, and ConfigMap), ArgoCD or Flux can apply resources
in the right order and verify reconciliation without custom scripting.
Deviating from naming conventions introduces operational complexity:
scripts need to track which resource name maps to which application.
The discipline: only deviate from naming conventions when required, document
the deviation, and automate the deviation handling.

---

#### Q6 - How does CoC interact with security (can it create security gaps)?

CoC can create security gaps if the convention is "open by default":

```java
// Spring Security default (before Boot):
// "deny all" was the convention
// -> explicit permit rules required

// Spring Boot 1.x auto-configuration:
// Permitted /h2-console by default
// -> if forgetting to remove in production: exposed DB console

// Spring Boot 2.x corrected:
// /h2-console requires explicit enablement
// spring.h2.console.enabled=true (default: false in prod)

// Actuator endpoints convention change:
// Boot 1.x: all endpoints exposed by default
// Boot 2.x: only /health and /info exposed by default
// Override: management.endpoints.web.exposure.include=*
// (explicit deviation, now intentional)
```

Security CoC principles:
- Default: secure (deny by default)
- Insecure features require explicit enablement
- @EnableWebSecurity / Spring Security's default secures all endpoints
- Deviations (permit specific paths) must be explicit

*What separates good from great:* The Spring Security shift from "permit by
default" to "deny by default" (Spring Security 6 / Spring Boot 3) is the
CoC security principle applied correctly. The correct default for security:
everything is locked down. Explicit rules OPEN things. This is "secure by
default" - a CoC that defaults to safety. The anti-pattern (seen in legacy
Spring Security config): permitAll() on /** as a starting point, then
adding deny rules. This means forgetting a deny rule leaves something exposed.
The secure-by-default convention means forgetting to add a permit rule
only prevents access - much safer failure mode.

---

#### Q7 - What is the transferable insight from CoC to team and process design?

CoC as a team process principle:

```
Code Review CoC:
  Convention: all PRs require review + CI passing
  Deviation: hotfix directly to main (explicit, documented)
  NOT: "PRs usually require review" (inconsistent)

Branching CoC:
  Convention: feature/ prefix for feature branches
  Deviation: experimental/ prefix (explicit label)

Testing CoC:
  Convention: tests in same module, naming *Test.java
  Deviation: integration tests in separate module (explicit)

Configuration as Code CoC:
  Convention: Terraform state in S3, naming by env
  Deviation: legacy manual config (explicitly documented,
             migration ticket created)

Documentation CoC:
  Convention: README.md at repo root covers: what, why, how to run
  Deviation: larger docs in /docs folder (README points to it)
```

The principle: define the 80% case as the convention.
Make deviations visible, intentional, and documented.
Reduce decision fatigue for routine situations.
Reserve decision-making energy for genuine deviations.

*What separates good from great:* Conway's Law + CoC: teams that communicate
frequently (same team) can establish conventions quickly. Teams that communicate
infrequently (different organizations) need explicit interfaces. Well-defined
conventions within a team reduce communication overhead: "PR follows the
convention" means the reviewer can focus on logic, not process. The RFC
(Request for Comments) pattern for breaking conventions: large deviations
go through a lightweight review process before implementation. Small deviations
follow the convention naturally. This is how mature engineering organizations
balance autonomy (follow conventions independently) with alignment (explicit
deviations vetted by team).

---

# Proxy Pattern as Universal Spring Mechanism

---
id: SPR-032
title: Proxy Pattern as Universal Spring Mechanism
category: Spring
difficulty: ★☆☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #spring-meta, #proxy, #cglib, #aop, #transferable
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Spring uses the Proxy pattern for almost every cross-cutting concern: transactions,
> caching, security, async, retry, and lazy loading. A proxy wraps a bean and
> intercepts method calls to add behavior without modifying the target class.
> Spring creates CGLIB subclass proxies by default. The consequence: anything
> Spring "adds" to your class without you writing code is a proxy. This explains
> the self-call problem, the final-method limitation, and why @Transactional
> on a private method silently does nothing.

**3 minutes:**
> The Proxy pattern: an object (the proxy) stands in front of another object
> (the target). The proxy intercepts calls and can add behavior before or after
> delegating to the target. Spring's proxy mechanism: when you annotate a bean
> with @Transactional, Spring creates a CGLIB subclass that overrides all
> public methods. Each override wraps the real method call in transaction logic.
> The proxy is registered as the bean; the original target is inside it.
>
> The same mechanism powers every Spring cross-cutting annotation:
> @Cacheable creates a proxy that checks the cache before calling the method.
> @Async creates a proxy that submits the method to a thread pool.
> @Secured creates a proxy that checks authorization before the call.
> @Retryable creates a proxy that retries on exception.
>
> The universal proxy mechanism has three constraints: (1) self-calls bypass
> the proxy (internal this.method() hits the real class, not the proxy), (2)
> final methods can't be overridden by CGLIB, (3) private methods can't be
> proxied (they're not in the interface contract). These three constraints
> explain 90% of "Spring annotation X not working" bugs.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking me to explain how Spring's Proxy pattern
works as the universal mechanism underlying transactions, caching, async, etc."

**(2) First principles:** "When you want to add behavior to a method without
modifying the method, you use a wrapper (proxy). The proxy intercepts the call,
does something, then passes the call through. This is how Spring adds transactions,
caching, security to your methods without you writing that code."

**(3) Bridge:** "Spring proxy is like a hotel concierge in front of every room.
When you knock on a room (call a method), the concierge checks your booking
(authorization), opens the door (starts transaction), delivers your message
(calls the real method), then cleans up (commits/rolls back transaction).
You interact with the concierge (proxy), not the room directly. Self-call
is like knocking from inside the room - you bypass the concierge entirely."

---

### 📘 Concept Explanation

**What it is:**
The Proxy pattern creates an object that controls access to another object,
allowing behavior to be added transparently. In Spring, CGLIB (Code Generation
Library) creates runtime subclasses that override methods with interceptor logic.

**Proxy creation mechanism:**

```
Without Spring (your class):
  class OrderService {
    void placeOrder(OrderRequest req) {
      // your business logic
    }
  }

With @Transactional (CGLIB proxy):
  // Spring generates at runtime:
  class OrderService$$SpringCGLIB$$0 extends OrderService {
    void placeOrder(OrderRequest req) {
      // Interceptor chain:
      TransactionInterceptor.invoke() {
        // 1. Check if transaction needed
        // 2. Get/create transaction
        // 3. Call REAL placeOrder (super.placeOrder)
        // 4. Commit or rollback
      }
    }
  }
  // Spring registers OrderService$$SpringCGLIB$$0 as the bean
  // YOU inject OrderService, but you get the proxy

Proxy chain (multiple annotations):
  @Async + @Transactional + @Cacheable on same method:
    -> Three interceptors stacked:
    CachingInterceptor {
      AsyncInterceptor {
        TransactionInterceptor {
          // real method
        }
      }
    }
```

**The self-call problem (the most asked interview topic):**

```
public class OrderService {

  @Transactional
  public void processOrder(Order order) {
    saveOrder(order);    // PROBLEM: internal call
  }

  @Transactional(propagation = REQUIRES_NEW)
  public void saveOrder(Order order) {
    // Does NOT run in new transaction!
    // this.saveOrder() bypasses proxy
    // The outer transaction is used instead
  }
}

Call flow WITH problem:
  Caller
    -> OrderService$$CGLIB.processOrder()  [proxy]
    -> TransactionInterceptor.invoke()     [starts TX]
    -> OrderService.processOrder()         [real]
    -> this.saveOrder()                    [THIS = real obj]
    -> OrderService.saveOrder()            [real, NO PROXY]
    -> No transaction intercept            [PROBLEM]

Call flow FIXED (separate bean):
  Caller
    -> OrderService$$CGLIB.processOrder()  [proxy]
    -> TransactionInterceptor.invoke()     [starts TX]
    -> OrderService.processOrder()         [real]
    -> orderSaver.saveOrder()              [via proxy]
    -> OrderSaver$$CGLIB.saveOrder()       [proxy]
    -> TransactionInterceptor.invoke()     [REQUIRES_NEW TX]
    -> OrderSaver.saveOrder()              [real]
```

---

### 💻 Code Example

```java
// Demonstrating all proxy limitations in one class

// BAD: ALL three proxy anti-patterns
@Service
public class PaymentService {

    @Transactional  // proxy created
    public void processPayment(Payment p) {
        // Anti-pattern 1: self-call bypasses proxy
        chargeCard(p);  // @Transactional ignored!

        // Anti-pattern 2: @Async self-call
        sendReceipt(p); // @Async ignored!
    }

    @Transactional(propagation = REQUIRES_NEW)
    private void chargeCard(Payment p) {
        // Anti-pattern 3: private + @Transactional
        // CGLIB can't proxy private methods
        // @Transactional SILENTLY IGNORED
        cardProcessor.charge(p);
    }

    @Async
    private void sendReceipt(Payment p) {
        // private @Async: also silently ignored
        emailService.sendReceipt(p.getEmail());
    }
}

// GOOD: all three fixed
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final CardChargeService cardCharge;  // separate bean
    private final ReceiptService receipt;         // separate bean

    @Transactional
    public void processPayment(Payment p) {
        // Goes through CardChargeService proxy
        cardCharge.chargeCard(p);   // REQUIRES_NEW works
        // Goes through ReceiptService proxy
        receipt.sendReceipt(p);     // @Async works
    }
}

@Service
public class CardChargeService {

    @Transactional(propagation = REQUIRES_NEW)
    public void chargeCard(Payment p) {
        // public method -> proxy can override
        // REQUIRES_NEW -> separate transaction
        cardProcessor.charge(p);
    }
}

@Service
public class ReceiptService {

    @Async  // public method -> works
    public void sendReceipt(Payment p) {
        emailService.sendReceipt(p.getEmail());
    }
}
```

> **Code walkthrough:** The BAD example has all three proxy anti-patterns:
> self-call (processPayment calling its own methods), private method with
> @Transactional (silently ignored), private @Async (also silently ignored).
> The GOOD example fixes all three by extracting each piece of behavior into
> its own @Service. Each service has its own proxy. Calls go through the proxy.
> Cross-cutting concerns (transactions, async) work correctly. The key rule:
> if you need @Transactional, @Async, or @Cacheable behavior, the annotated
> method must be: (1) public, (2) on a different bean than the caller,
> (3) called through the Spring proxy (injected bean reference, not this).

```java
// Verifying whether a call goes through the proxy:
@Service
public class DebugService {

    @Autowired
    private DebugService self;  // inject the proxy

    @Transactional
    public void transactionalMethod() {
        // Is this call in a transaction?
        boolean txActive = TransactionSynchronizationManager
            .isActualTransactionActive();
        System.out.println("TX active: " + txActive); // true

        // Call via proxy:
        self.checkTransaction(); // goes through proxy -> true
        // Self-call:
        checkTransaction();     // bypasses proxy -> false
    }

    @Transactional
    public void checkTransaction() {
        boolean txActive = TransactionSynchronizationManager
            .isActualTransactionActive();
        System.out.println("TX active: " + txActive);
    }
}
```

> **Code walkthrough:** This demonstrates the difference between a proxied call
> (self.checkTransaction() via injected self reference) and a bypassed call
> (checkTransaction() via this). TransactionSynchronizationManager.isActualTransactionActive()
> is the diagnostic tool: it returns true only if a Spring-managed transaction
> is active in the current thread. Self-injection (injecting yourself via @Autowired)
> is sometimes used in production code to go through the proxy, but it's cleaner
> to extract the method to a separate bean. The self-injection approach signals
> a design problem that should be refactored.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Spring uses proxy objects to add behavior like transactions and caching without
> changing your code. When you annotate a method with @Transactional, Spring
> creates a wrapper (proxy) around your class. When someone calls your method,
> they're actually calling the proxy. The proxy starts a transaction, calls your
> real method, then commits or rolls back. The important limitation: if your
> method calls another method in the same class, it bypasses the proxy, so
> @Transactional on the internal method doesn't work.

**Senior / Staff:**
> The proxy mechanism is the single most important thing to understand about
> Spring's runtime behavior. Three constraints determine when annotations don't work:
> self-call (bypasses proxy), private method (can't be overridden), final class/method
> (can't be subclassed by CGLIB). When debugging "annotation X not working":
> check these three conditions first. Also: @Transactional on a class means all
> public methods are proxied - but the class can't be final. @EnableCaching,
> @EnableAsync, @EnableTransactionManagement each register their own BeanPostProcessor
> that creates the proxy. If the BeanPostProcessor registers AFTER the bean was
> created (ordering issue), the bean has no proxy for that annotation - a subtle
> startup ordering bug.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@Transactional on private method throws an error."**
No error is thrown. @Transactional on a private method is SILENTLY IGNORED.
This is the danger: you think you have transaction protection but you don't.
The only way to detect it: TransactionSynchronizationManager.isActualTransactionActive()
inside the method, or an integration test that verifies rollback behavior.

**Misconception 2: "JDK proxy and CGLIB proxy behave differently in my code."**
From your code's perspective: both are transparent. The difference is CGLIB
subclasses the concrete class; JDK proxy implements the interface. Both intercept
the same calls. The practical difference: CGLIB requires non-final class/methods;
JDK proxy requires an interface. Spring Boot 2+ defaults to CGLIB for consistency.

---

### 🚨 Failure Modes and Diagnosis

**Failure: @Transactional method not rolling back**
Symptom: exception thrown in transactional method, but data still committed.
Causes:
1. Self-call: method called from within same class
2. Exception is checked exception (Spring only rolls back RuntimeException by default)
3. Exception caught before it reaches the proxy
4. @Transactional on private method

Diagnosis:
```java
// Add to method:
System.out.println("TX: " +
  TransactionSynchronizationManager.isActualTransactionActive());
// If false: no transaction active -> proxy bypassed
```

Fix: ensure public method, separate bean, runtime exception.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - How does CGLIB create a proxy at runtime?

CGLIB (Code Generation Library) uses ASM to generate bytecode at runtime:

```
1. BeanPostProcessor detects @Transactional bean: OrderService
2. CGLIB.create():
   a. Read OrderService.class bytecode
   b. Generate new class: OrderService$$SpringCGLIB$$0
      extends OrderService {
        @Override public void placeOrder(req) {
          // Generated bytecode for interceptor chain
        }
      }
   c. Load generated class into JVM
   d. Instantiate OrderService$$SpringCGLIB$$0

3. Register OrderService$$SpringCGLIB$$0 as bean "orderService"
4. The real OrderService is inside the proxy as "target"

What CGLIB cannot generate:
  - Override of final methods (compiler forbids)
  - Override of private methods (not in API)
  - Subclass of final class (forbidden)
```

In Spring Boot 3 with Java 17+: CGLIB requires the module (--add-opens
or explicit module-info) to access private fields if needed for proxying.
Spring Boot 3 uses Objenesis to create proxy instances without calling
the constructor (avoids null constructor arg issues).

*What separates good from great:* CGLIB proxies are generated ONCE per class
(cached) and instantiated on demand. The class generation cost is paid once
at context refresh. Method interception cost is very small (a few nanoseconds
per call for the proxy indirection). Performance concern about Spring proxies
is almost always unfounded in practice - the business logic dominates. For
truly hot paths (millions of calls/second), removing the proxy by inlining
the transactional logic saves nanoseconds but introduces correctness risks.
Measure first.

---

#### Q2 - When would you use JDK proxy instead of CGLIB?

JDK proxy: implements interfaces, does not subclass:

```java
// JDK proxy requires interface:
interface OrderService { void placeOrder(Order o); }

@Service
class OrderServiceImpl implements OrderService { ... }

// JDK proxy: proxy implements OrderService interface
// OrderServiceProxy implements OrderService {
//   delegate: OrderServiceImpl
// }

// Force JDK proxy in Spring Boot:
spring.aop.proxy-target-class=false
```

When to use JDK proxy:
- Code that heavily uses interface types (mocking frameworks)
- Module system (Java 9+) has restricted access to concrete classes
- You need to proxy a class that cannot be subclassed (final third-party)

JDK proxy limitation: if you try to cast to concrete type:
```java
OrderService service = context.getBean(OrderService.class);
// This works:
service.placeOrder(order);
// This FAILS with JDK proxy (ClassCastException):
((OrderServiceImpl) service).implOnlyMethod();
// Because proxy IS NOT OrderServiceImpl, just implements OrderService
```

*What separates good from great:* The move to CGLIB-by-default in Spring Boot 2
was driven by a common ClassCastException pattern. Teams would inject by
interface but cast to implementation internally. With JDK proxy, this failed
at runtime. With CGLIB, it works (the proxy IS a subclass of the implementation).
The tradeoff: CGLIB prevents final classes/methods. JDK proxy prevents casting
to implementation. CGLIB is safer for typical Spring development patterns.
For library code that you don't control: use interfaces, don't cast to
implementation, and you're compatible with both proxy types.

---

#### Q3 - How does the proxy know which interceptors to chain?

Spring uses AdvisedSupport and MethodInterceptor chain:

```java
// ProxyFactory builds the proxy with advisors:
ProxyFactory factory = new ProxyFactory();
factory.setTarget(orderService);  // the real bean
factory.addAdvice(transactionInterceptor);
factory.addAdvice(cachingInterceptor);
factory.addAdvice(securityInterceptor);
Object proxy = factory.getProxy();

// At method call time:
// ReflectiveMethodInvocation.proceed():
// 1. interceptors[0].invoke() -> transactionInterceptor
//    -> interceptors[1].invoke() -> cachingInterceptor
//       -> interceptors[2].invoke() -> securityInterceptor
//          -> Method.invoke() -> real method
//       <- return value
//    <- cache result
// <- commit transaction
```

Interceptor ordering matters:
- Transaction should wrap Caching (transaction THEN check cache)
- Security should run BEFORE Transaction (deny before starting transaction)
- Default ordering: Security -> Transaction -> Caching (inside out)

Control ordering:
```java
@Order(1) // lower = higher priority (outer proxy)
@Aspect
public class SecurityAspect { ... }

@Order(2)
@Aspect
public class TransactionAspect { ... }
```

*What separates good from great:* The ordering of interceptors matters for
correctness, not just performance. If caching wraps transaction: the cache
check happens inside the transaction (acquires connection unnecessarily for
cache hits). If transaction wraps caching: the connection is held open while
waiting for the cache (holds connection longer than needed). Correct order:
security first (avoid unnecessary work for unauthorized), then caching (return
cached without transaction), then transaction (begin/commit for cache misses).
Spring's default ordering puts Spring Security before Spring Transaction,
which is correct. Custom aspects need @Order to control their position.

---

#### Q4 - How does @Async work as a proxy?

@Async creates a proxy that submits the method call to an executor:

```java
@Service
public class EmailService {

    @Async("emailExecutor")  // run in email thread pool
    public Future<Void> sendEmail(String to, String body) {
        // This runs in a separate thread
        emailClient.send(to, body);
        return CompletableFuture.completedFuture(null);
    }
}

// What the proxy does:
// EmailService$$CGLIB:
//   Future<Void> sendEmail(to, body) {
//     Callable<Future<Void>> task = () ->
//       realEmailService.sendEmail(to, body);
//     return taskExecutor.submit(task);
//   }

// Caller:
CompletableFuture<Void> future = emailService.sendEmail(to, body);
// Returns immediately - email sent in background

// To enable @Async:
@SpringBootApplication
@EnableAsync
public class App { }
```

@Async return types:
- void: fire and forget (caller can't check completion)
- Future<T>: caller can call .get() to wait
- CompletableFuture<T>: caller can chain callbacks

*What separates good from great:* @Async error handling is tricky with void
return type. If the async method throws, the exception is eaten silently.
To handle errors: implement AsyncUncaughtExceptionHandler:
```java
@Configuration
@EnableAsync
public class AsyncConfig implements AsyncConfigurer {
    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) ->
            log.error("Async error in " + method.getName(), ex);
    }
}
```
With CompletableFuture return: exceptions are available via exceptionally()
or handle() on the future. For production: always configure an exception handler
for @Async methods to prevent silent failures.

---

#### Q5 - How does the proxy relate to Spring AOP pointcuts?

A pointcut defines WHICH methods get proxied:

```java
// Aspect: defines pointcut + advice
@Aspect
@Component
public class LoggingAspect {

    // Pointcut: all methods in service package
    @Pointcut("execution(* com.myapp.service.*.*(..))")
    public void serviceMethod() {}

    // Advice: what to do at the pointcut
    @Around("serviceMethod()")
    public Object logExecution(
            ProceedingJoinPoint jp) throws Throwable {
        long start = System.currentTimeMillis();
        try {
            return jp.proceed();  // call real method
        } finally {
            long ms = System.currentTimeMillis() - start;
            log.info("{} took {}ms",
                jp.getSignature().getName(), ms);
        }
    }
}
```

Proxy creation: Spring scans @Aspect beans, finds pointcuts, and for each
bean whose methods match a pointcut: creates a proxy wrapping that bean
with the advice as an interceptor.

Pointcut types:
- execution(): method signature matching
- @annotation(): method has specific annotation
- within(): class is in package
- bean(): specific bean name
- @within(): class has annotation

*What separates good from great:* Broad pointcuts (all methods in all classes)
create proxies for EVERY bean in the context. This adds proxy creation cost
at startup and proxy interception cost at runtime. Be specific: target
exact packages or use @annotation pointcuts (only methods with specific
annotations get the proxy). @Transactional works this way: only beans with
@Transactional get a proxy. If you have an aspect with execution(* *.*(..)),
EVERY method in EVERY bean is proxied - including Spring's own infrastructure
beans - which creates unexpected behavior and performance degradation.

---

#### Q6 - How does @Cacheable use the proxy pattern?

@Cacheable wraps method calls with cache lookup:

```java
@Service
public class ProductService {

    @Cacheable(value = "products",
               key = "#id",
               condition = "#id > 0",
               unless = "#result == null")
    public Product findById(Long id) {
        // Expensive: DB query
        return productRepository.findById(id).orElse(null);
    }

    @CachePut(value = "products", key = "#product.id")
    public Product update(Product product) {
        // Updates cache after saving
        return productRepository.save(product);
    }

    @CacheEvict(value = "products", key = "#id")
    public void delete(Long id) {
        // Removes from cache before deleting
        productRepository.deleteById(id);
    }
}

// What the CachingInterceptor does:
// findById(Long id):
//   1. key = "products::42" (cache name + key)
//   2. Check cache: cacheManager.getCache("products").get(42)
//   3. Cache HIT: return cached Product (skip DB call)
//   4. Cache MISS: call real findById(42), store in cache, return
```

@Cacheable also has the self-call problem:
```java
@Service
public class OrderService {
    @Cacheable("orders")
    public Order findOrder(Long id) { ... }

    public List<Order> findAll(List<Long> ids) {
        return ids.stream()
            // SELF-CALL: cache bypass!
            .map(id -> findOrder(id))
            .collect(toList());
    }
}
```

*What separates good from great:* Cache eviction strategy is where most caching
bugs originate. @CacheEvict removes stale entries but has a race condition:
between the CacheEvict and the next CacheFind, another thread may get a stale
value. @CachePut updates the cache after writes, ensuring consistency.
In distributed caching (Redis), cache consistency requires either:
write-through (@CachePut), time-based expiry (TTL), or explicit eviction on
write with a short TTL for safety. The proxy handles the mechanics;
the developer is responsible for eviction strategy correctness.

---

#### Q7 - How do you create a custom annotation backed by an AOP proxy?

```java
// 1. Define the annotation
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimit {
    int maxCallsPerSecond() default 10;
}

// 2. Create the aspect
@Aspect
@Component
public class RateLimitAspect {

    private final ConcurrentHashMap<String, RateLimiter>
        limiters = new ConcurrentHashMap<>();

    // Pointcut: any method with @RateLimit
    @Around("@annotation(rateLimit)")
    public Object enforce(
            ProceedingJoinPoint jp,
            RateLimit rateLimit) throws Throwable {
        String key = jp.getSignature().toShortString();
        RateLimiter limiter = limiters.computeIfAbsent(key,
            k -> RateLimiter.create(
                rateLimit.maxCallsPerSecond()));

        if (!limiter.tryAcquire()) {
            throw new TooManyRequestsException(
                "Rate limit exceeded for " + key);
        }
        return jp.proceed();  // call real method
    }
}

// 3. Use the annotation:
@RestController
public class SearchController {

    @GetMapping("/search")
    @RateLimit(maxCallsPerSecond = 5)
    public List<Result> search(@RequestParam String q) {
        return searchService.search(q);
    }
}

// Spring automatically creates a proxy for SearchController
// The proxy includes the RateLimitAspect interceptor
// No other configuration needed (aspect + @EnableAspectJAutoProxy)
```

> **Code walkthrough:** @annotation(rateLimit) in the pointcut binds the
> annotation instance to the parameter. This lets the advice read the annotation's
> values (maxCallsPerSecond). The RateLimiter (from Guava or Resilience4j) is
> stored per method signature so different methods have independent rate limits.
> tryAcquire() is non-blocking: it returns false immediately if the rate is exceeded
> rather than blocking until a token is available. The TooManyRequestsException
> propagates through the proxy to the caller (which should translate to HTTP 429
> in the controller error handler). This pattern is exactly how @RateLimiter in
> Resilience4j Spring Boot starter works.

*What separates good from great:* Custom AOP annotations are a powerful abstraction
but have the same proxy limitations as @Transactional: self-call bypass, private
method limitation. When creating a custom annotation like @RateLimit, document
these limitations explicitly. Also document that @RateLimit only works when
the annotated class is a Spring bean (proxy creation happens in IoC container).
Calling a @RateLimit-annotated method on a new-operator-created object has no
proxy - the annotation is ignored. This is the contract users of your annotation
must understand.
