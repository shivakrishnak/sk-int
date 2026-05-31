---
layout: default
title: "Micronaut - L2 Core"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 3
permalink: /micronaut/l2-core/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Compile-Time Dependency Injection](#compile-time-dependency-injection) | critical |
| 2 | [Micronaut AOP and Interceptors](#micronaut-aop-and-interceptors) | medium |
| 3 | [Micronaut Bean Scopes and Lifecycle](#micronaut-bean-scopes-and-lifecycle) | medium |
| 4 | [Micronaut Environment and Property Sources](#micronaut-environment-and-property-sources) | medium |
| 5 | [Micronaut Annotation Processing Pipeline](#micronaut-annotation-processing-pipeline) | medium |

---

# Compile-Time Dependency Injection

**Interview Weight:** critical - Compile-time DI is
Micronaut's defining characteristic. Every Micronaut
interview will probe this mechanism.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut uses Java annotation processing (APT) at
> compile time to generate BeanDefinition classes for
> every @Singleton, @Prototype, or scoped bean.
> These generated classes encode the dependency graph,
> constructor arguments, and lifecycle methods. At
> runtime, Micronaut loads these pre-built definitions
> instead of scanning classpath or using reflection.
> No classpath scanning. No reflection on the startup
> critical path.

**3 minutes (Senior):**

> Compile-time DI mechanics:
>
> Step 1: Annotation processing during javac/kotlinc
>   BeanDefinitionInjectProcessor runs for every class
>   annotated with @Singleton, @Bean, @Inject, etc.
>   Generates: OrderServiceBeanDefinition.java in
>   target/generated-sources/
>
> Step 2: Generated class structure
>   class OrderServiceBeanDefinition
>       extends AbstractBeanDefinition<OrderService> {
>     // Pre-computed metadata:
>     // - Constructor arguments (types, qualifiers)
>     // - Injection points (fields, methods)
>     // - Lifecycle methods (@PostConstruct)
>     // - Scope (Singleton, Prototype)
>     // - @Requires conditions
>   }
>
> Step 3: Runtime loading
>   ApplicationContext finds all BeanDefinition
>   classes on the classpath (normal class loading,
>   no scanning for annotations).
>   Creates the bean graph from the pre-built definitions.
>
> Result: startup O(n) where n = number of bean
>   definitions. No annotation analysis. No proxy
>   generation. Just definition loading.
>
> Native image advantage:
>   The generated code contains no reflection.
>   GraalVM native-image sees only normal Java classes.
>   No reflection configuration files needed for
>   core DI.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Micronaut's
compile-time dependency injection works mechanically."

**(2) First principles:** "DI requires two things:
knowing what beans exist and how to wire them. Spring
discovers this at runtime. Micronaut computes it at
compile time."

**(3) Bridge:** "Compile-time DI is like a shipping
warehouse that pre-assembles packages before orders
arrive. Spring assembles each package when the order
arrives (runtime). Micronaut assembles all packages
during the day (compile time) and ships instantly
when the order arrives."

---

### 💻 Code Example

```java
// Source code
@Singleton
public class OrderService {
    private final OrderRepository repository;
    private final NotificationService notif;

    public OrderService(
            OrderRepository repository,
            NotificationService notif) {
        this.repository = repository;
        this.notif = notif;
    }
}

// Generated at compile time by APT
// (in target/generated-sources/annotations)
// Simplified representation:
public class $OrderServiceDefinition
        extends AbstractBeanDefinition<OrderService> {

    // Generated constructor metadata
    private static final AbstractBeanDefinition
            .ConstructorInjectionPoint CONSTRUCTOR =
        new ConstructorInjectionPoint(
            OrderService.class,
            // Argument 1:
            DefaultArgument.of(
                OrderRepository.class, "repository"),
            // Argument 2:
            DefaultArgument.of(
                NotificationService.class, "notif")
        );

    @Override
    protected OrderService doBuild(
            BeanResolutionContext ctx,
            BeanContext context,
            BeanDefinition<OrderService> definition) {
        // Generated wiring - no reflection!
        return new OrderService(
            ctx.getBean(OrderRepository.class),
            ctx.getBean(NotificationService.class)
        );
    }
}
```

> **Code walkthrough:** The BeanDefinitionInjectProcessor
> reads @Singleton on OrderService and generates the
> $OrderServiceDefinition class. This class contains
> pre-computed constructor argument types. The doBuild()
> method is generated Java code: new OrderService(...)
> with the resolved dependencies. No reflection in
> doBuild() - it's a direct Java constructor call.
> At runtime, the ApplicationContext calls doBuild()
> to create the bean. No classpath scanning needed.

---

### ⚖️ Comparison Table

| Aspect | Micronaut (AOT) | Spring (Runtime) |
|---|---|---|
| DI resolution timing | Compile time | Runtime |
| Classpath scanning | No | Yes |
| Proxy generation | No (for DI) | CGLIB/JDK proxy |
| Reflection in DI | No | Yes |
| Startup cost | O(n) definitions load | O(n*m) scan + proxy |
| Native image | No config needed | Spring AOT config needed |
| Dynamic beans | Limited | Full support |

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut generates BeanDefinition classes
during compilation. These are loaded at startup instead
of scanning for annotations at runtime."

**Senior:** "The generated BeanDefinition contains
no reflection - it's compiled Java code calling the
constructor directly. This is why GraalVM native-image
works without reflection configuration for Micronaut
beans. The trade-off: you can't register beans
dynamically at runtime."

**Staff:** "Compile-time DI has an architectural
consequence: your application's bean graph is fixed
at compile time. This is a constraint for plugin
architectures but a safety net for most applications.
Unexpected bean wiring errors surface at compile time
or startup, not in production."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Generated classes, BeanDefinition structure, native image |
| Staff | 10 min | Trade-offs, dynamic bean limits, architectural consequences |

---

**[SENIOR] Q1 - How can you inspect the compile-time
generated BeanDefinition classes?**

*Why they ask:* Debugging and deep understanding.

Generated classes are in:
```
target/generated-sources/annotations/
  (Maven, Java source generation)

build/generated/sources/annotationProcessor/
  (Gradle)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

They have the format: `$TypeName$DefinitionClass.java`
or compiled as `$TypeName$Definition.class`.

To inspect:
```bash
# Find generated definition files:
find target -name "*Definition*.class" | head -20

# Decompile with javap:
javap -p -c \
  target/classes/\
  io/example/$OrderService$Definition.class
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

The decompiled output shows:
- Which constructor is used
- Argument types and qualifiers
- @Requires conditions as if/else in the code
- @PostConstruct method reference

Useful when debugging: "Why is the wrong implementation
injected?" - check the generated definition class.

*What separates good from great:* Knowing WHERE to
look when DI doesn't behave as expected.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | APT generation, BeanDefinition structure. |
| Hiring Manager | Compile-time DI = fewer runtime surprises. |
| Bar Raiser | Generated class structure, native image implication, dynamic bean trade-off. |
| Peer Engineer | "I look at the generated $Definition class when Micronaut injects the wrong bean. Usually a missing @Qualifier." |

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


# Micronaut AOP and Interceptors

**Interview Weight:** medium - AOP in Micronaut is
compile-time, making it more predictable but less
dynamic than Spring AOP.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut AOP uses compile-time interceptors, not
> runtime CGLIB proxies. Create a custom annotation
> and annotate an interceptor class with @Around or
> @InterceptorBean. At compile time, Micronaut wraps
> the annotated methods with the interceptor code.
> Standard use cases: @Transactional (built-in),
> @Cacheable (built-in), custom audit logging,
> circuit breaker. No proxy class at runtime - the
> wrappers are generated source code.

**3 minutes (Senior):**

> AOP without proxies:
>
> Spring AOP: creates CGLIB subclass at runtime.
>   Target method is overridden; interceptors run.
>   Cannot intercept private or final methods.
>   Creates a new proxy class per intercepted bean.
>
> Micronaut AOP: uses introduction advice.
>   At compile time: generates wrapper code around
>   the target method.
>   The interceptor runs in the generated wrapper.
>   No new proxy class (the original class is unchanged).
>   Can intercept any method visible to the annotation.
>
> Custom interceptor pattern:
>   1. Create annotation: @AuditLog
>   2. Create interceptor:
>      @Singleton @InterceptorBean(AuditLog.class)
>      class AuditLogInterceptor
>          implements MethodInterceptor<Object,Object> {
>        @Override
>        public Object intercept(MethodInvocationContext) {
>          // pre-execution
>          Object result = ctx.proceed();
>          // post-execution
>          return result;
>        }
>      }
>   3. Apply: @AuditLog on method or class
>
> Built-in interceptors:
>   @Transactional: transaction management
>   @Cacheable/@CachePut/@CacheInvalidate: caching
>   @Retryable: retry with backoff
>   @CircuitBreaker: circuit breaker

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about aspect-oriented
programming in Micronaut - how to add cross-cutting
concerns without modifying business logic."

**(2) First principles:** "AOP = inject code before/after
methods. Spring does this with runtime proxies. Micronaut
does this with compile-time code generation."

**(3) Bridge:** "Micronaut AOP is generated code, not
runtime magic. The result is the same: @Transactional
wraps your method in a transaction. The mechanism is
compile-time code, not a runtime CGLIB class."

---

### 💻 Code Example

```java
// Custom AOP annotation
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
@Around   // Tells Micronaut this is an AOP annotation
public @interface AuditLog {
    String action() default "";
}

// Interceptor
@Singleton
@InterceptorBean(AuditLog.class)
public class AuditLogInterceptor
        implements MethodInterceptor<Object, Object> {

    private final AuditRepository auditRepo;

    AuditLogInterceptor(AuditRepository auditRepo) {
        this.auditRepo = auditRepo;
    }

    @Override
    public Object intercept(
            MethodInvocationContext<Object, Object> ctx) {

        String methodName = ctx.getMethodName();
        String action = ctx.getAnnotationMetadata()
            .stringValue(AuditLog.class, "action")
            .orElse(methodName);

        try {
            Object result = ctx.proceed();
            auditRepo.logSuccess(action,
                ctx.getParameterValues());
            return result;
        } catch (Exception e) {
            auditRepo.logFailure(action, e);
            throw e;
        }
    }
}

// Usage
@Singleton
public class OrderService {

    @AuditLog(action = "CREATE_ORDER")
    public Order createOrder(CreateOrderRequest req) {
        // Compile time: wrapped with AuditLogInterceptor
        // AuditLog fires before and after this method
        return orderRepository.save(
            Order.from(req));
    }
}
```

> **Code walkthrough:** @Around marks the custom
> annotation as an AOP trigger. @InterceptorBean links
> the interceptor to the annotation. At compile time,
> Micronaut sees @AuditLog on createOrder() and generates
> code that calls AuditLogInterceptor.intercept() around
> the method body. ctx.proceed() calls the original
> method. Unlike Spring AOP, no CGLIB proxy class is
> created at runtime.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut AOP uses annotations on methods
and interceptor classes. @Transactional and @Cacheable
are built-in interceptors. Custom interceptors implement
MethodInterceptor."

**Senior:** "Micronaut AOP generates the interceptor
wrapper at compile time - no runtime proxy. This means
AOP works on any method (not just public, not limited
to Spring proxy rules). The trade-off: you can't add
AOP to a class at runtime."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Compile-time interceptors vs Spring CGLIB, custom interceptors |
| Staff | 8 min | AOP limitations, Introduction advice, comparison |

---

**[SENIOR] Q1 - Can Micronaut AOP intercept calls
within the same class (self-invocation)?**

*Why they ask:* The Spring AOP self-invocation gotcha
is famous. Does Micronaut have the same problem?

Spring AOP problem: method A calls method B in the same
class. If B has @Transactional, the call goes directly
(not through the proxy). No transaction.

Micronaut AOP: compile-time interceptors are woven
into the class itself (introduction advice), not an
external proxy class. Therefore: self-invocation DOES
go through the interceptor.

Example:
```java
@Singleton
public class OrderService {
    public void processAndShip(Long id) {
        this.createShipment(id); // self-call
    }

    @AuditLog(action = "SHIP")
    public void createShipment(Long id) {
        // In Micronaut: AuditLogInterceptor fires
        // even on self-invocation
        // In Spring: @AuditLog would NOT fire
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This is a significant advantage over Spring's proxy-based
model. No need for self-injection (injecting yourself
as a Spring bean to get proxy behavior).

*What separates good from great:* Self-invocation works
in Micronaut because of compile-time (not proxy-based)
AOP.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Around, MethodInterceptor, compile-time weaving. |
| Hiring Manager | AOP for cross-cutting concerns without boilerplate. |
| Bar Raiser | Self-invocation works in Micronaut, comparison to Spring proxy limitation. |
| Peer Engineer | "Migrated from Spring to Micronaut. Fixed a silent @Transactional self-invocation bug we'd had for years." |

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


# Micronaut Bean Scopes and Lifecycle

**Interview Weight:** medium - Bean scopes control
instance creation and lifecycle. Tested to verify
understanding of scope choices and lifecycle hooks.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut bean scopes: @Singleton (one instance per
> ApplicationContext), @Prototype (new instance per
> injection point), @RequestScope (one per HTTP request).
> Lifecycle: @PostConstruct method runs after all
> dependencies injected; @PreDestroy runs on context
> shutdown. @Singleton beans are created eagerly by
> default unless marked @Lazy.

**3 minutes (Senior):**

> Scopes:
>
> @Singleton:
>   One instance per ApplicationContext.
>   Thread-safe access required if mutable state.
>   Created at startup (eager by default).
>
> @Prototype:
>   New instance per injection point.
>   Not cached; each injection creates a new bean.
>   Use for stateful, non-thread-safe objects.
>
> @RequestScope:
>   One instance per HTTP request.
>   Bound to the request context.
>   Cleaned up after response sent.
>   Use for: request-scoped security context,
>     per-request caching.
>
> @Refreshable:
>   Singleton that can be refreshed via
>   RefreshEvent. Config changes trigger refresh.
>
> @Context:
>   Same as @Singleton but initialized very early
>   in the ApplicationContext lifecycle.
>   Use for infrastructure beans.
>
> @Infrastructure:
>   Internal Micronaut beans. Not used in application.
>
> Lifecycle hooks:
>   @PostConstruct: initialization after injection.
>   @PreDestroy: cleanup before context shutdown.
>   ApplicationEventListener<StartupEvent>: alternative
>   to @PostConstruct for startup tasks.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut's
bean scopes - how many instances are created and
when they are created and destroyed."

**(2) First principles:** "Scope = the lifetime of
a bean instance. Singleton = shared. Prototype = each
gets its own. Request = scoped to one request."

**(3) Bridge:** "Bean scopes are like hotel room policies:
Singleton = the mayor always uses room 1. Prototype =
new room for every guest. RequestScope = room assigned
for your stay, released on checkout."

---

### 💻 Code Example

```java
// @Singleton: shared across the app
@Singleton
public class OrderService {
    // One instance, thread-safe required for state
    private final OrderRepository repository;
    OrderService(OrderRepository repository) {
        this.repository = repository;
    }
}

// @Prototype: new instance per injection
@Prototype
public class RequestContextBuilder {
    private final List<String> trace =
        new ArrayList<>();  // Safe: new instance each time

    public RequestContextBuilder add(String step) {
        trace.add(step);
        return this;
    }
}

// @RequestScope: per HTTP request
@RequestScope
public class AuditContext {
    private String requestId;
    private String userId;
    // Holds per-request audit state
    // Cleaned up automatically after response
}

// Lifecycle hooks
@Singleton
public class ConnectionPool {
    @Inject
    DataSourceConfig config;

    @PostConstruct
    public void initialize() {
        // Called after all dependencies injected
        // Safe to use config here
        pool = createPool(config.getUrl());
    }

    @PreDestroy
    public void shutdown() {
        // Called on ApplicationContext.close()
        pool.close();
        log.info("Connection pool closed");
    }
}

// @Lazy: defers creation until first use
@Singleton
@Lazy
public class ExpensiveAnalyticsEngine {
    // Not created at startup
    // Created on first injection
}
```

> **Code walkthrough:** @Prototype on RequestContextBuilder
> means each injection point creates a new instance
> with a fresh trace list - safe for per-request accumulation.
> @RequestScope on AuditContext binds the instance
> to the HTTP request lifecycle. @PostConstruct fires
> after @Inject resolves all dependencies - safe to
> use injected config. @Lazy defers expensive initialization
> to first use, keeping startup faster.

---

### 🎓 Answers by Seniority

**Junior:** "@Singleton shares one instance. @Prototype
creates a new instance per injection. @RequestScope
creates one per HTTP request. @PostConstruct runs
after injection."

**Senior:** "@Prototype is underused. Use it when a
bean needs fresh mutable state per caller. @RequestScope
is ideal for per-request security or tracing context.
@Lazy for expensive beans not needed at startup."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Singleton, Prototype, PostConstruct |
| Senior | 6 min | RequestScope, Lazy, Refreshable |

---

**[SENIOR] Q1 - What happens if a @Singleton bean
injects a @Prototype bean?**

*Why they ask:* Scope mismatch is a common bug.

If a @Singleton injects a @Prototype via constructor
injection: the @Prototype is resolved once at
construction time. The same instance is used forever.
The @Prototype is effectively a Singleton in this context.

The @Prototype is NOT re-created per use of the Singleton.

Fix options:
1. Inject Provider<PrototypeBean>: calling provider.get()
   creates a new instance each time.
2. Inject ApplicationContext and look up the bean each time.
3. Reconsider if @Prototype is really needed for this dependency.

```java
@Singleton
public class OrderProcessor {
    // BAD: shared instance despite @Prototype
    private final RequestContextBuilder builder;
    OrderProcessor(
            RequestContextBuilder builder) {
        this.builder = builder;
        // builder created once at startup
    }

    // GOOD: Provider re-creates per call
    private final Provider<RequestContextBuilder>
        builderProvider;
    OrderProcessor(
            Provider<RequestContextBuilder> p) {
        this.builderProvider = p;
    }
    public void process() {
        RequestContextBuilder ctx =
            builderProvider.get(); // new instance
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Provider<T> as the
idiomatic fix for scope mismatch.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Scope definitions, lifecycle hooks. |
| Hiring Manager | Bean lifecycle determines how your services behave. |
| Bar Raiser | Scope mismatch bug, Provider<T> fix, @RequestScope lifecycle. |
| Peer Engineer | "Singleton injecting Prototype is a silent bug. Added @Prototype but it never re-created. Provider fixed it." |

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


# Micronaut Environment and Property Sources

**Interview Weight:** medium - Environment-driven
configuration is essential for production deployments.
Tested for environment activation and property source
hierarchy.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut environments are activated via
> -Dmicronaut.environments=production or the
> MICRONAUT_ENVIRONMENTS environment variable. Active
> environments cause environment-specific config files
> to be loaded: application-production.yml overrides
> application.yml. Multiple environments can be active
> simultaneously. @Requires(env = "production") enables
> beans only in specific environments. Property sources
> can be extended (Consul, AWS Secrets Manager) via
> plugins.

**3 minutes (Senior):**

> Environment system:
>
> Built-in environments (auto-detected):
> - "cloud": detected on cloud providers
>   (ECS, GCE, Kubernetes - reads metadata endpoints)
> - "ec2": Amazon EC2
> - "gcp": Google Cloud
> - "k8s": Kubernetes (pod metadata available)
> - "test": Micronaut test (set by @MicronautTest)
>
> Custom environments:
> - -Dmicronaut.environments=production,feature-x
> - or: MICRONAUT_ENVIRONMENTS=production,feature-x
>
> Property source priority (highest first):
> 1. System properties
> 2. Environment variables
> 3. application-{env}.yml (per active environment)
> 4. application.yml
> 5. application.properties (fallback)
>
> Distributed configuration:
> - micronaut-consul: loads config from Consul KV store
> - micronaut-aws-secrets-manager: AWS Secrets Manager
> - micronaut-kubernetes: Kubernetes ConfigMaps/Secrets
> - All distributed sources override local files
>
> @Requires(env = ...):
> @Requires(env = {"cloud", "k8s"}): active on cloud/k8s
> @Requires(notEnv = "test"): excludes from test

**Blank Mind Recovery:**

environment system - how environment-specific configuration
works."

**(2) First principles:** "Applications run in multiple
environments (dev, staging, prod). Config must differ.
Environments provide the override mechanism."

**(3) Bridge:** "Micronaut environments are like project
profiles: a base config (application.yml) and
environment-specific overlays (application-production.yml).
Micronaut also auto-detects cloud environments."

---

### 🎓 Answers by Seniority

**Junior:** "Set -Dmicronaut.environments=production
and Micronaut loads application-production.yml on
top of application.yml. Use @Requires(env=...) to
activate beans only in certain environments."

**Senior:** "Micronaut auto-detects cloud environments
(Kubernetes, EC2, GCP) by querying metadata endpoints.
This is useful for @Requires(env='k8s'): activate
Kubernetes-specific service discovery only in k8s.
Distributed config (Consul, AWS Secrets Manager)
integrates as a property source that overrides local
YAML."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Environment activation, config overlay |
| Senior | 6 min | Auto-detected environments, distributed config, @Requires(env) |

---

**[SENIOR] Q1 - How does Micronaut load Kubernetes
secrets safely?**

*Why they ask:* Production Kubernetes deployment concern.

Micronaut Kubernetes integration:
```yaml
# pom.xml / build.gradle
# micronaut-kubernetes dependency
```

```yaml
# application.yml
micronaut:
  config-client:
    enabled: true

kubernetes:
  client:
    namespace: production
    config-maps:
      enabled: true
      paths:
        - /config/app-config
    secrets:
      enabled: true
      paths:
        - /secrets/db-password
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Kubernetes mounts secrets as files or env vars.
Micronaut reads them as property sources.

For secrets:
1. Mount secret as an environment variable
   (Kubernetes Secret → env var).
2. Micronaut reads the env var as a normal property.
3. Never log property values that may be secrets.

@Requires(env = "k8s") ensures Kubernetes-specific
config (service discovery via DNS) only activates
in the Kubernetes environment.

*What separates good from great:* Env var mounting
over file mounting (env vars are ephemeral and not
stored on disk in the container).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Environment activation, property source hierarchy. |
| Hiring Manager | Environment-specific config = clean deployment. |
| Bar Raiser | Auto-detected environments, distributed config, Kubernetes secrets. |
| Peer Engineer | "We use @Requires(env='k8s') for all Kubernetes-specific beans. Clean separation." |

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


# Micronaut Annotation Processing Pipeline

**Interview Weight:** medium - Understanding the
annotation processing pipeline is essential for
advanced Micronaut development and debugging.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut uses Java Annotation Processing (JSR 269)
> to generate code at compile time. When javac/kotlinc
> processes source files, Micronaut's annotation
> processors (BeanDefinitionInjectProcessor, etc.) scan
> for Micronaut annotations and generate BeanDefinition,
> interceptor wrapper, HTTP route binding, and
> configuration binding classes. These generated classes
> are compiled and included in the JAR. At runtime,
> no annotation processing occurs.

**3 minutes (Senior):**

> Key annotation processors:
>
> BeanDefinitionInjectProcessor:
>   @Singleton, @Prototype, @Bean →
>   Generates BeanDefinition classes.
>
> AopProxyWriter:
>   @Around, @Transactional, @Cacheable →
>   Generates AOP wrapper code.
>   (No CGLIB; generates source code instead)
>
> HttpServerRouteGenerator:
>   @Controller, @Get, @Post →
>   Generates route binding code.
>   Route matching is compiled code (faster).
>
> ConfigurationPropertiesProcessor:
>   @ConfigurationProperties →
>   Generates property binding code.
>   No reflection for config binding.
>
> TypeElementVisitor:
>   Extension point: implement custom annotation
>   processors that integrate with Micronaut's APT.
>
> Build tool integration:
>   Maven: micronaut-inject-java in annotationProcessorPaths
>   Gradle: annotationProcessor("io.micronaut:micronaut-inject-java")
>
> Incremental annotation processing:
>   Micronaut 3+ supports incremental APT.
>   Only reprocesses changed classes.
>   Reduces compile time for large projects.

**Blank Mind Recovery:**

compile-time code generation works under the hood."

**(2) First principles:** "Annotation processing is
a Java compiler plugin that reads source code and
generates additional source files before compilation
completes."

**(3) Bridge:** "Micronaut's annotation processing
is like a code generator that reads your annotations
and writes the plumbing code you'd otherwise have to
write manually - DI wiring, AOP wrappers, HTTP routes."

---

### 💻 Code Example

```java
// Source: your code
@Singleton
public class OrderService {
    private final OrderRepository repo;
    OrderService(OrderRepository repo) {
        this.repo = repo;
    }
}

// Generated (simplified): target/generated-sources/
// File: $OrderService$Definition.java

@Generated("io.micronaut.annotation.processing..."
           + ".BeanDefinitionInjectProcessor")
public class $OrderService$Definition
    extends AbstractInitializableBeanDefinition<
        OrderService>
    implements BeanFactory<OrderService> {

    // Pre-computed constructor argument metadata
    private static final AbstractInitializableBeanDefinition
        .MethodOrFieldReference CONSTRUCTOR =
        new AbstractInitializableBeanDefinition
            .MethodReference(
                OrderService.class,
                "<init>",
                new Argument[] {
                    Argument.of(
                        OrderRepository.class,
                        "repo")
                }
            );

    @Override
    public OrderService build(
            BeanResolutionContext context,
            BeanContext beanContext,
            BeanDefinition<OrderService> definition) {
        // Direct constructor call - no reflection
        return new OrderService(
            (OrderRepository) super.getBeanForConstructorArgument(
                context, beanContext, 0, null)
        );
    }
}
```

> **Code walkthrough:** The generated $OrderService$Definition
> encodes the constructor signature as metadata objects
> (not String-based reflection). The build() method
> calls new OrderService(...) directly - a compiled Java
> constructor call. super.getBeanForConstructorArgument()
> resolves the OrderRepository dependency by looking
> it up in the BeanContext. No java.lang.reflect.Constructor.newInstance()
> anywhere in this path.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut's annotation processors run
during compilation and generate classes that describe
each bean. At runtime these classes are loaded instead
of scanning for annotations."

**Senior:** "During annotation processing, Micronaut
emits a BeanDefinition class with a build() method that
calls the constructor directly via compiled bytecode.
For AOP, a separate $Intercepted subclass wraps the
original with generated interceptor dispatch calls.
GraalVM native-image sees only regular Java classes
with no reflection registration needed."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | APT processors, generated class structure |
| Staff | 10 min | Custom TypeElementVisitor, incremental processing |

---

**[STAFF] Q1 - How would you write a custom Micronaut
annotation processor to enforce a coding rule?**

*Why they ask:* Extension point knowledge for advanced use.

Use TypeElementVisitor:
```java
@SupportedAnnotationTypes("io.example.*")
public class NoSpringAnnotationVisitor
        implements TypeElementVisitor<Object,Object> {

    @Override
    public void visitClass(
            ClassElement element,
            VisitorContext context) {

        // Check if class uses @Autowired (Spring)
        if (element.hasAnnotation(
                "org.springframework.beans.factory"
                + ".annotation.Autowired")) {
            context.fail(
                "Use @Inject instead of @Autowired",
                element);
            // Compile error!
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Register in META-INF/services/
io.micronaut.core.annotation.Generated (SPI).

This runs at compile time and fails the build if
@Autowired is used - enforcing the team's migration
from Spring to Micronaut.

Other uses:
- Verify @ConfigurationProperties classes have @Validated
- Check @Controller return types are DTOs (not entities)
- Enforce naming conventions on bean classes

*What separates good from great:* TypeElementVisitor
as a compile-time linting tool for team conventions.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | APT processors list, generated class structure. |
| Hiring Manager | Compile-time code generation = fewer runtime errors. |
| Bar Raiser | TypeElementVisitor for custom rules, incremental APT. |
| Peer Engineer | "I wrote a TypeElementVisitor that fails the build if @Entity is returned from @Controller. Zero security leaks." |

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



