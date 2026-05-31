---
layout: default
title: "Spring - L6 Framework Internals"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 16
permalink: /spring/l6-framework-internals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L6 Framework Internals](#spring---l6-framework-internals) | medium |
| 2 | [Spring Framework Design Patterns](#spring-framework-design-patterns) | medium |
| 3 | [Custom Spring Boot Starter Design](#custom-spring-boot-starter-design) | medium |

---

# Spring Framework Design Patterns

---
id: SPR-028
title: Spring Framework Design Patterns
category: Spring
difficulty: ★★☆
interview_weight: medium
asked_at: Senior/Staff
seniority: senior
tags: #spring-patterns, #proxy, #template-method, #factory, #observer
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Spring is a design pattern showcase. The core patterns: Proxy (AOP, transactions,
> lazy injection), Factory (BeanFactory, ApplicationContext, FactoryBean),
> Template Method (JdbcTemplate, RestTemplate, TransactionTemplate), Observer
> (ApplicationEvent/ApplicationListener), Decorator (BeanPostProcessor wrapping
> beans), and Singleton (singleton-scoped beans). Understanding these patterns
> explains why Spring behaves the way it does at runtime.

**3 minutes:**
> Spring's architecture is built on five primary design patterns working together:
>
> Proxy Pattern is Spring's most pervasive pattern. @Transactional creates a
> CGLIB proxy that wraps the target bean. The proxy intercepts method calls and
> wraps them in a transaction. AOP advice is also proxy-based. @Lazy injection
> creates a proxy that delays real bean creation. @Scope("session") creates a
> scoped proxy. The same mechanism: a proxy object standing in front of the real
> object.
>
> Factory Pattern pervades bean creation. BeanFactory is the root factory
> interface. ApplicationContext extends it. FactoryBean<T> is the factory
> pattern inside the DI container: a bean whose getObject() creates another
> bean. @Bean methods on @Configuration classes are factories. AbstractBeanFactory
> orchestrates all creation.
>
> Template Method in the data access layer: JdbcTemplate defines the algorithm
> (acquire connection, execute, handle results, release connection) and delegates
> variable parts (SQL, result mapping) to lambdas. TransactionTemplate similarly.
> AbstractApplicationContext.refresh() is a template method with 12 steps.
>
> Observer Pattern: ApplicationEvent + ApplicationListener. Spring publishes
> ContextRefreshedEvent, ContextStartedEvent, ContextClosedEvent. @EventListener
> on any component method. @TransactionalEventListener participates in transaction
> lifecycle.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking which software design patterns are used
in the Spring Framework implementation itself."

**(2) First principles:** "Spring is a framework that manages objects and their
interactions. The fundamental patterns for object management: how to create
objects (Factory), how to wire them together (DI), how to intercept their methods
(Proxy), how to define algorithms with variable steps (Template Method), how to
notify interested parties of events (Observer)."

**(3) Bridge:** "Spring is like a city infrastructure: Factory = construction
company (builds objects), Proxy = building security desk (intercepts all visitors
before they reach the occupant), Template Method = building permit process
(fixed steps with variable content), Observer = emergency broadcast system
(events sent to all registered listeners)."

---

### 📘 Concept Explanation

**What it is:**
The Spring Framework's implementation uses classic Gang-of-Four design patterns
extensively. Understanding which patterns are used and where explains Spring's
behavior, limitations, and best practices.

**Primary patterns in Spring:**

```
Pattern             Spring Usage
------------------------------------------------
Proxy               AOP, @Transactional, @Scope,
                    @Lazy, @Async, @Cacheable
Factory             BeanFactory, ApplicationContext,
                    FactoryBean, @Bean methods
Template Method     JdbcTemplate, RestTemplate,
                    TransactionTemplate, refresh()
Observer/Event      ApplicationEvent/Listener,
                    @EventListener, Spring Security
Decorator           BeanPostProcessor chain,
                    HandlerInterceptor chain
Singleton           Default bean scope
Strategy            AuthenticationProvider chain,
                    MappingJackson2HttpMessageConverter
Adapter             HandlerAdapter, MessageConverter
Composite           ApplicationContext hierarchy
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The Proxy Pattern in depth:**

```
How @Transactional creates a proxy:

1. Component scan finds @Service OrderService
2. BeanPostProcessor (AnnotationAwareAspectJAutoProxy)
   checks: does OrderService have @Transactional methods?
3. YES: create CGLIB subclass of OrderService
   -> OrderService$$SpringCGLIB$$0 extends OrderService
   -> Override ALL methods with transaction advice
4. Register proxy (not original) as the bean

Call flow:
  Caller -> OrderService$$SpringCGLIB$$0.placeOrder()
              -> TransactionInterceptor.invoke()
                 -> DataSourceTransactionManager.begin()
                 -> OrderService.placeOrder() (actual)
                 -> DataSourceTransactionManager.commit()

Proxy limitations:
  1. Proxy wraps EXTERNAL calls only
     -> internal this.method() bypasses proxy
  2. final methods cannot be proxied (CGLIB)
     -> add @Transactional to final -> SILENT IGNORE
  3. JDK proxy requires interface
     -> CGLIB proxy works without interface
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The Template Method Pattern in depth:**

```java
// JdbcTemplate uses Template Method:
// Fixed algorithm:
//   1. Get connection
//   2. Create statement
//   3. Execute query (VARIABLE STEP - your lambda)
//   4. Map results (VARIABLE STEP - your RowMapper)
//   5. Release resources

// JdbcTemplate internals (simplified):
public <T> T execute(String sql,
                     PreparedStatementCallback<T> action)
    throws DataAccessException {
    Connection con = DataSourceUtils.getConnection(
        getDataSource());
    PreparedStatement ps = null;
    try {
        ps = con.prepareStatement(sql);
        // YOUR CODE runs here:
        T result = action.doInPreparedStatement(ps);
        handleWarnings(ps);
        return result;
    } catch (SQLException ex) {
        // Exception translation (DataAccessException)
        throw translateException(..., ex);
    } finally {
        // ALWAYS releases resources
        JdbcUtils.closeStatement(ps);
        DataSourceUtils.releaseConnection(con, ds);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The Observer Pattern in depth:**

```java
// Publishing events:
@Service
public class OrderService {
    private final ApplicationEventPublisher publisher;

    // Constructor injection
    public OrderService(
            ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    public Order placeOrder(OrderRequest req) {
        Order order = createOrder(req);
        // Fire event - observers handle async/sync
        publisher.publishEvent(
            new OrderPlacedEvent(this, order));
        return order;
    }
}

// Observing events:
@Component
public class InventoryService {

    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        reserveInventory(event.getOrder());
    }
}

// Transactional event (fires AFTER commit):
@Component
public class NotificationService {

    @TransactionalEventListener(
        phase = TransactionPhase.AFTER_COMMIT)
    public void onOrderCommitted(OrderPlacedEvent ev) {
        // Only fires if transaction committed
        sendEmail(ev.getOrder().getCustomerEmail());
    }
}
```

> **Code walkthrough:** @TransactionalEventListener solves a classic race condition.
> If you send an email inside the transaction, and the transaction rolls back,
> the email was sent for a non-existent order. @TransactionalEventListener with
> AFTER_COMMIT delays the handler until the transaction has successfully committed.
> The event is stored in a buffer during the transaction and processed afterward.
> BEFORE_COMMIT fires inside the transaction (last chance to abort). AFTER_ROLLBACK
> fires for cleanup on failure.

---

### 💻 Code Example

```java
// BAD: not understanding proxy creates self-call problem
@Service
public class OrderService {

    @Transactional  // creates proxy
    public void processOrder(OrderRequest req) {
        validateOrder(req);  // calls internal method
        saveOrder(req);
    }

    @Transactional(
        propagation = Propagation.REQUIRES_NEW)
    public void saveOrder(OrderRequest req) {
        // PROBLEM: this.saveOrder() bypasses proxy!
        // REQUIRES_NEW never starts new transaction
        // saveOrder runs in outer transaction
        orderRepository.save(req.toOrder());
    }
}

// GOOD: use self-injection or split into two beans
@Service
public class OrderService {

    // Self-inject to go through proxy
    @Autowired
    private OrderService self;

    @Transactional
    public void processOrder(OrderRequest req) {
        validateOrder(req);
        // Goes through proxy -> REQUIRES_NEW works
        self.saveOrder(req);
    }

    @Transactional(
        propagation = Propagation.REQUIRES_NEW)
    public void saveOrder(OrderRequest req) {
        orderRepository.save(req.toOrder());
    }
}

// BEST: extract to separate bean (cleaner)
@Service
public class OrderService {
    private final OrderPersistenceService persistSvc;

    @Transactional
    public void processOrder(OrderRequest req) {
        validateOrder(req);
        // Different bean -> goes through proxy
        persistSvc.saveOrder(req);
    }
}

@Service
public class OrderPersistenceService {

    @Transactional(
        propagation = Propagation.REQUIRES_NEW)
    public void saveOrder(OrderRequest req) {
        orderRepository.save(req.toOrder());
    }
}
```

> **Code walkthrough:** The self-call problem is Spring's most common Proxy pattern
> pitfall. When a @Transactional method calls another @Transactional method in
> the same class with this.method(), it bypasses the CGLIB proxy. The JVM calls
> the real method directly, no transaction intercept occurs. The self-injection
> workaround (inject the proxy of yourself) works but is architecturally awkward.
> The best design: if you need REQUIRES_NEW, that's a signal the behavior belongs
> in a separate service. The clean solution - separate beans - also makes the
> code more testable and better expresses domain boundaries.

```java
// FactoryBean pattern in Spring

// BAD: complex initialization logic in @Bean
@Configuration
public class AppConfig {

    @Bean
    public SomeComplexObject complexObject() {
        // Mixing creation logic with configuration
        SomeComplexObject obj = new SomeComplexObject();
        obj.setStep1(...);
        obj.setStep2(...);
        return obj;
    }
}

// GOOD: FactoryBean encapsulates creation
public class SomeComplexObjectFactory
        implements FactoryBean<SomeComplexObject> {

    @Override
    public SomeComplexObject getObject() throws Exception {
        SomeComplexObject obj = new SomeComplexObject();
        obj.setStep1(...);
        obj.setStep2(...);
        obj.initialize();  // lifecycle method
        return obj;
    }

    @Override
    public Class<?> getObjectType() {
        return SomeComplexObject.class;
    }

    @Override
    public boolean isSingleton() {
        return true;  // create once, share
    }
}

@Configuration
public class AppConfig {
    @Bean
    public SomeComplexObjectFactory complexObjectFactory() {
        return new SomeComplexObjectFactory();
    }
    // Spring calls getObject() to get
    // SomeComplexObject for injection
}
```

> **Code walkthrough:** FactoryBean is a factory inside the factory. Spring
> recognizes beans that implement FactoryBean<T>. When you inject SomeComplexObject,
> Spring calls getObject() on the factory. To inject the factory itself (not the
> product), prefix the name with &: applicationContext.getBean("&complexObjectFactory").
> FactoryBean is used extensively in Spring's own infrastructure: SqlSessionFactoryBean
> (MyBatis), LocalContainerEntityManagerFactoryBean (JPA), and many others.
> It's the canonical pattern for complex object creation with lifecycle management.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring uses several design patterns. The most important ones: Proxy (for
> transactions and AOP), Factory (for creating and managing beans), and Template
> Method (for JdbcTemplate, RestTemplate). When you use @Transactional, Spring
> creates a proxy object that intercepts your method call and handles the
> transaction. This is why calling @Transactional methods within the same class
> doesn't work - you bypass the proxy.

**Senior / Staff (5+ years):**
> Understanding Spring's patterns explains production issues. Three critical
> ones: (1) Proxy - every @Transactional, @Cacheable, @Async, @Scope creates
> a proxy. Self-calls bypass it. Final methods can't be proxied. CGLIB subclassing
> means your class can't be final. (2) Template Method - JdbcTemplate.execute()
> is why exceptions are translated to DataAccessException hierarchy even though
> you wrote plain JDBC. The algorithm (connection management) is fixed; only
> your SQL/mapping varies. (3) Observer - @TransactionalEventListener fires
> AFTER_COMMIT by design; this prevents sending notifications for rolled-back
> transactions. These patterns explain behavior that seems magical without
> knowing the mechanism.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring Proxy is only for AOP."**
Spring uses proxies for: @Transactional, @Cacheable, @Async, @Scope("session"),
@Lazy, @Retryable, and custom AOP. All create the same type of CGLIB/JDK proxy
infrastructure. The proxy chain can include multiple interceptors stacked.

**Misconception 2: "FactoryBean is rarely used."**
Spring's own infrastructure uses FactoryBean extensively: EntityManagerFactoryBean,
DataSourceFactoryBean, SqlSessionFactoryBean, JndiObjectFactoryBean. If you
configure JPA with Spring XML config or write a custom integration library,
FactoryBean is the canonical extension point.

**Misconception 3: "@EventListener is always synchronous."**
By default: yes, synchronous in the same thread. With @Async on the listener,
it becomes asynchronous (runs in task executor thread pool). @TransactionalEventListener
delays execution (post-commit) but is still synchronous unless also @Async.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: @Transactional self-call silently ignored**
Symptom: @Transactional(propagation=REQUIRES_NEW) inside the same class
doesn't start a new transaction. Or @Cacheable on an internal method doesn't cache.
Cause: self-call bypasses proxy.
Diagnosis: Add logging to the interceptor or check the actual transaction status
in the method body: TransactionSynchronizationManager.isActualTransactionActive().
Fix: Separate bean, or self-injection.

**Failure 2: final class/method breaks CGLIB proxy**
Symptom: "Cannot subclass final class..." during ApplicationContext refresh.
Or: @Transactional silently does nothing (no warning if final method with CGLIB).
Cause: CGLIB creates a subclass. Final class/method can't be overridden.
Fix: Remove final from the class/method, or use @Transactional only on
implementation classes (not final by default).

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - Why does Spring default to CGLIB over JDK proxies?

JDK proxies require the target class to implement an interface:
```java
// JDK proxy only works with interface
interface OrderService { void placeOrder(); }
@Service
class OrderServiceImpl implements OrderService { }
// Proxy type: JDK proxy (implements OrderService interface)

// Without interface: JDK proxy impossible
@Service
class OrderService { void placeOrder(); }
// Pre-Spring 5.2: TargetClass proxy (CGLIB)
// Post-Spring 5.2: CGLIB by default even with interface
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Spring Boot 2.0+ defaults: `spring.aop.proxy-target-class=true` (CGLIB).
Reasons for CGLIB default:
1. Simpler: no interface required, works on any class
2. Consistent: same proxy type whether interface exists or not
3. Performance: CGLIB marginally faster than JDK proxy (modern JVMs minimize gap)

CGLIB limitations: can't proxy final class/method. Constructor injection
works normally (CGLIB subclass calls super constructor).

*What separates good from great:* The switch to CGLIB-by-default in Spring Boot 2.0
broke code that assumed the proxy implemented specific interfaces. If you were
casting a bean to its interface type: fine. If casting to the concrete class type
via the interface proxy: ClassCastException. The rule: inject by interface type
when possible, or understand that CGLIB proxy IS a subclass of the concrete class.

---

#### Q2 - How does BeanPostProcessor relate to the Decorator pattern?

BeanPostProcessor wraps beans after initialization:
```java
@Component
public class PerformanceBeanPostProcessor
        implements BeanPostProcessor {

    @Override
    public Object postProcessAfterInitialization(
            Object bean, String beanName) {
        // Decorator: wrap beans that have @Monitored
        if (hasMonitoredAnnotation(bean)) {
            return Proxy.newProxyInstance(
                bean.getClass().getClassLoader(),
                bean.getClass().getInterfaces(),
                new TimingInvocationHandler(bean));
        }
        return bean;  // no decoration
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

BeanPostProcessor chain = Decorator chain:
- AutowiredAnnotationBeanPostProcessor: injects @Autowired fields
- AnnotationAwareAspectJAutoProxyCreator: creates AOP proxies
- PersistenceExceptionTranslationPostProcessor: translates JPA exceptions
- AsyncAnnotationBeanPostProcessor: proxies @Async methods

Each wraps the previous output. The bean you receive at injection time
has been through all registered BeanPostProcessors.

*What separates good from great:* BeanPostProcessors must be careful about
eager initialization. If a BeanPostProcessor injects a dependency that itself
needs to be post-processed, you get circular dependency issues during context
refresh. The warning: "Bean '...' is not eligible for getting processed by
all BeanPostProcessors" - this means a bean was created before all
BeanPostProcessors were ready, so it missed some processing (like AOP proxy
creation - you might have no @Transactional on that bean).

---

#### Q3 - How does ApplicationEvent vs direct method call compare?

```java
// Direct method call:
@Service
public class OrderService {
    private final InventoryService inventory;
    private final NotificationService notification;
    private final AuditService audit;

    public void placeOrder(OrderRequest req) {
        Order order = createOrder(req);
        inventory.reserve(order);     // direct coupling
        notification.notify(order);   // direct coupling
        audit.log(order);             // direct coupling
    }
}
// Problems: OrderService knows about 3 other services
// Adding new step = modifying OrderService
// Testing = mock all 3 services

// ApplicationEvent approach:
@Service
public class OrderService {
    private final ApplicationEventPublisher events;

    public void placeOrder(OrderRequest req) {
        Order order = createOrder(req);
        events.publishEvent(
            new OrderPlacedEvent(this, order));
        // OrderService knows ZERO about who handles event
    }
}
// Benefits: OrderService decoupled from handlers
// Adding new step = new @EventListener (no OrderService change)
// Testing = mock just ApplicationEventPublisher
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Trade-offs:
- Event: loose coupling, hard to trace execution flow
- Direct call: tight coupling, easy to trace, easy to test
- Use events for cross-cutting concerns (audit, notification)
- Use direct calls for core business logic

*What separates good from great:* Events create traceability challenges.
When an OrderPlacedEvent fires, which listeners ran? In what order? Did any fail?
Spring's event system is synchronous by default (all listeners complete before
publishEvent returns). If a listener throws, it propagates to the publisher.
For production: add ApplicationEventListener with @Async and error handling.
Spring's event system does NOT provide delivery guarantees - if the service
crashes between publishEvent and listener execution, the event is lost.
For guaranteed delivery: use Spring Cloud Stream / Kafka.

---

#### Q4 - How does the Template Method pattern prevent resource leaks in JdbcTemplate?

JdbcTemplate owns the resource lifecycle:
```java
// Without JdbcTemplate (Template Method approach):
// YOUR code must handle every failure path
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;
try {
    con = dataSource.getConnection();
    ps = con.prepareStatement(sql);
    ps.setLong(1, customerId);
    rs = ps.executeQuery();
    // ... your code
} catch (SQLException ex) {
    throw new RuntimeException(ex);
} finally {
    // YOU must close in correct order
    // YOU must not throw from finally
    if (rs != null) try { rs.close(); }
        catch (SQLException ignored) {}
    if (ps != null) try { ps.close(); }
        catch (SQLException ignored) {}
    if (con != null) try { con.close(); }
        catch (SQLException ignored) {}
}

// With JdbcTemplate: YOU write only the variable parts
jdbcTemplate.query(sql, ps -> {
    ps.setLong(1, customerId);
}, (rs, row) -> {
    return mapRow(rs);
});
// Connection, Statement, ResultSet: always closed
// Even if YOUR lambda throws an exception
// The template method pattern guarantees cleanup
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* JdbcTemplate's guarantee comes from the
try/finally structure in its template methods. The connection is acquired
INSIDE the template, not passed in. This means the template owns the lifecycle.
When combined with Spring's transaction management, DataSourceUtils.getConnection()
returns the transaction-bound connection - so if a transaction is active,
JdbcTemplate participates in it. When the template calls
DataSourceUtils.releaseConnection(), it doesn't close the connection if
it's bound to a transaction - just returns it to the transaction context.
The template method pattern + transaction binding = correct JDBC behavior
with zero boilerplate.

---

#### Q5 - What is the Strategy pattern in Spring Security?

Spring Security uses Strategy extensively:

```java
// AuthenticationProvider Strategy:
// Multiple providers, Spring tries each until one succeeds

@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(
            AuthenticationManagerBuilder auth) throws Exception {
        auth
            // Strategy 1: in-memory (testing)
            .inMemoryAuthentication()
                .withUser("admin").password("...").roles("ADMIN")
            .and()
            // Strategy 2: database
            .userDetailsService(userDetailsService)
            .passwordEncoder(passwordEncoder)
            .and()
            // Strategy 3: LDAP
            .ldapAuthentication()
                .userDnPatterns("uid={0},ou=people")
                .contextSource().url("ldap://...");
    }
}

// AuthenticationManager tries providers in order:
// 1. InMemoryUserDetailsManager - found? return Authentication
// 2. DaoAuthenticationProvider - found? return Authentication
// 3. LdapAuthenticationProvider - found? return Authentication
// None found: throw BadCredentialsException

// Custom AuthenticationProvider (custom auth mechanism):
@Component
public class ApiKeyAuthenticationProvider
        implements AuthenticationProvider {

    @Override
    public Authentication authenticate(
            Authentication auth) {
        String apiKey = auth.getCredentials().toString();
        if (validApiKeys.contains(apiKey)) {
            return new UsernamePasswordAuthenticationToken(
                apiKey, apiKey, List.of(
                    new SimpleGrantedAuthority("ROLE_API")));
        }
        return null;  // try next provider
    }

    @Override
    public boolean supports(Class<?> auth) {
        return ApiKeyAuthenticationToken.class
            .isAssignableFrom(auth);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The Strategy pattern in AuthenticationProvider
enables pluggable authentication without modifying the framework. The Chain of
Responsibility pattern works alongside it: ProviderManager iterates through all
providers and returns the first successful authentication. Each provider checks
supports() first (type matching Strategy) before attempting authentication. This
means JWT authentication, API key authentication, and database authentication
can coexist in the same application - requests carry different authentication
types and reach the correct provider transparently.

---

#### Q6 - How does Spring's Composite pattern work in ApplicationContext hierarchy?

```
ApplicationContext can have a parent:

  ParentContext (Root)
    Contains: shared beans (repositories, services)
    Accessible to: child contexts

  ChildContext (WebApplicationContext)
    Contains: controllers, view resolvers, MVC beans
    Can access: beans from parent by delegation
    Parent cannot access: child beans

Lookup order:
  1. Check ChildContext
  2. Not found? Delegate to ParentContext

Example: two web apps sharing same service layer:
  RootContext: ServiceA, ServiceB, DataSource
  WebContext1 (API): ApiController -> ServiceA
  WebContext2 (Admin): AdminController -> ServiceB
  Both controllers can use both services.
  Services can't inject controllers (wrong direction).
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

In Spring Boot, single ApplicationContext is common.
Multiple contexts: Spring MVC test (WebApplicationContext),
Spring Cloud Gateway, multi-tenant applications.

*What separates good from great:* ApplicationContext hierarchy creates visibility
rules. Child can see parent beans; parent cannot see child beans. @Transactional
beans registered in the child context that use a TransactionManager from the
parent context work correctly (child accesses parent's TransactionManager).
But @Transactional in root context that needs beans from child context fails
(parent can't see child). This was a common confusion in Spring MVC apps:
@Transactional in the web context didn't work if the TransactionManager was
in the root context - the @Transactional proxy was in the web context but used
the root context's TransactionManager. Solution: keep all @Transactional beans
in the root context.

---

#### Q7 - How does Spring use the Observer pattern for lifecycle events?

Spring publishes lifecycle events throughout the ApplicationContext lifecycle:

```java
// Built-in lifecycle events (in order):
@Component
public class LifecycleListener {

    // 1. Before context is refreshed (beans not ready)
    @EventListener
    public void onContextStarting(
            ApplicationStartingEvent event) { }

    // 2. Environment prepared
    @EventListener
    public void onEnvPrepared(
            ApplicationEnvironmentPreparedEvent event) { }

    // 3. Context created but beans not refreshed
    @EventListener
    public void onContextPrepared(
            ApplicationContextInitializedEvent event) { }

    // 4. After refresh - beans ready
    // Most useful: beans are created and wired
    @EventListener
    public void onContextRefreshed(
            ContextRefreshedEvent event) { }

    // 5. Application is ready
    @EventListener
    public void onReady(ApplicationReadyEvent event) {
        // Use this instead of ContextRefreshedEvent
        // for post-startup tasks (avoids test issues)
    }

    // 6. Context closing
    @EventListener
    public void onContextClosing(ContextClosedEvent event) {
        // Cleanup, unregister from external services
    }
}

// Alternative: @PostConstruct and @PreDestroy
// These are bean lifecycle callbacks, not context events
// @PostConstruct: after dependency injection complete
// @PreDestroy: before bean is destroyed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* ContextRefreshedEvent vs ApplicationReadyEvent:
Both fire after the context is ready. The difference: ContextRefreshedEvent fires
on EVERY refresh, including @RefreshScope refreshes. ApplicationReadyEvent fires
once at application startup. Using ContextRefreshedEvent for "run this once at startup"
logic will re-run the logic on every @RefreshScope refresh. Use ApplicationReadyEvent
or CommandLineRunner/ApplicationRunner for post-startup initialization.

---

#### Q8 - How does the Adapter pattern work in Spring MVC?

Spring MVC uses HandlerAdapter to support multiple controller styles:

```java
// HandlerAdapter decides HOW to call the controller:
// 1. RequestMappingHandlerAdapter (for @RequestMapping)
// 2. SimpleControllerHandlerAdapter (for legacy Controller interface)
// 3. HttpRequestHandlerAdapter (for HttpRequestHandler)

// Spring MVC dispatch:
DispatcherServlet.doDispatch() {
    HandlerExecutionChain handler = 
        getHandler(request);  // HandlerMapping finds controller

    HandlerAdapter ha = 
        getHandlerAdapter(handler.getHandler());
    // HandlerAdapter: adapts controller to uniform interface

    ModelAndView mv = 
        ha.handle(request, response, handler);
    // Each adapter KNOWS how to call its handler type:
    // RequestMappingHandlerAdapter: reflects on method,
    //   resolves @RequestParam, @RequestBody, etc.
    //   calls the method, converts return value
}

// Adapter pattern: DispatcherServlet uses one interface
//   (HandlerAdapter.handle())
// But handlers come in many types (@RestController,
//   legacy Controller, HttpRequestHandler, RouterFunction)
// Each adapter translates its handler to
//   the uniform handle() call
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* HandlerAdapter is also where @RequestParam,
@PathVariable, @RequestBody resolution happens. RequestMappingHandlerAdapter
delegates argument resolution to HandlerMethodArgumentResolver chain and return
value handling to HandlerMethodReturnValueHandler chain. Both are Strategy patterns.
When you register a custom @RequestBody converter or a custom HandlerMethodArgumentResolver,
you're extending these Strategy chains. Understanding this chain explains why
adding @EnableWebMvc resets all auto-configured message converters - it creates
a fresh adapter with empty converter lists.

---

#### Q9 - How would you implement a custom Spring scope using the Scope SPI?

```java
// Custom scope: "tenant" scope - one bean per tenant ID

@Component
public class TenantScope implements Scope {

    // Storage: tenant ID -> bean name -> bean instance
    private final ConcurrentHashMap<String,
        ConcurrentHashMap<String, Object>>
            tenantBeans = new ConcurrentHashMap<>();

    @Override
    public Object get(String name,
                      ObjectFactory<?> objectFactory) {
        String tenantId = TenantContext.currentTenant();
        return tenantBeans
            .computeIfAbsent(tenantId, 
                k -> new ConcurrentHashMap<>())
            .computeIfAbsent(name, 
                k -> objectFactory.getObject());
    }

    @Override
    public Object remove(String name) {
        String tenantId = TenantContext.currentTenant();
        Map<String, Object> beans = 
            tenantBeans.get(tenantId);
        return beans != null ? beans.remove(name) : null;
    }

    @Override
    public void registerDestructionCallback(
            String name, Runnable callback) {
        // Call when tenant session ends
    }

    // getConversationId: ID for this scope instance
    @Override
    public String getConversationId() {
        return TenantContext.currentTenant();
    }
}

// Register the scope:
@Configuration
public class TenantScopeConfig {
    @Bean
    public static CustomScopeConfigurer
            tenantScopeConfigurer() {
        CustomScopeConfigurer config = 
            new CustomScopeConfigurer();
        config.addScope("tenant", new TenantScope());
        return config;
    }
}

// Use the scope:
@Component
@Scope("tenant")
public class TenantDataCache {
    private final Map<String, Object> cache
        = new HashMap<>();
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Custom scopes are powerful but require careful
lifecycle management. The TenantScope above leaks memory: if tenantBeans is never
cleaned up, beans accumulate. Production implementation: use weak references or
explicit cleanup (call remove() when tenant session ends). The scope SPI also
powers Spring's built-in scopes: singleton (cached in DefaultSingletonBeanRegistry),
prototype (never cached - new instance every time), request, session, application.
Understanding the Scope SPI shows that these are not special framework features
but just registered Scope implementations - you can replace them.

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


# Custom Spring Boot Starter Design

---
id: SPR-029
title: Custom Spring Boot Starter Design
category: Spring
difficulty: ★★☆
interview_weight: medium
asked_at: Senior/Staff
seniority: senior
tags: #spring-boot-starter, #auto-configuration, #spring-factories
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> A Spring Boot Starter is a Maven dependency that brings in auto-configuration.
> It has two parts: a starter POM (manages dependencies) and an auto-configure
> jar (contains @Configuration classes + spring.factories or META-INF/spring/
> for registration). When your starter is on the classpath, Spring Boot's
> @EnableAutoConfiguration picks up the @Configuration classes and creates
> beans conditionally (@ConditionalOnMissingBean, @ConditionalOnClass).

**3 minutes:**
> Custom starters follow a naming convention: {name}-spring-boot-starter for
> third-party, spring-boot-starter-{name} for official Spring starters. Typically
> two modules: {name}-spring-boot-autoconfigure (the configuration classes and
> conditions) and {name}-spring-boot-starter (just a POM that depends on
> autoconfigure and any needed transitive dependencies).
>
> Auto-configuration registration (Spring Boot 2.7+):
> META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
> file, listing fully-qualified class names. Older approach:
> META-INF/spring.factories with org.springframework.boot.autoconfigure.EnableAutoConfiguration.
>
> @ConditionalOnClass: only activate if a class is on classpath (e.g., only create
> DataSource bean if Hikari is on classpath). @ConditionalOnMissingBean: only create
> bean if user hasn't already created one (respects user's override). @ConditionalOnProperty:
> only activate based on property. These conditions enable zero-effort setup:
> add the starter, it configures itself.
>
> Testing: use @ImportAutoConfiguration to import just your auto-configuration
> in tests, not the full SpringBootTest context.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how to create a custom Spring Boot Starter that
other applications can include as a dependency to get auto-configured beans."

**(2) First principles:** "Auto-configuration is convention over configuration:
if X is on the classpath, create Y. A starter bundles: (1) the dependencies you
need, (2) the auto-configuration class that creates beans based on what's available,
(3) registration so Spring Boot finds the auto-configuration class."

**(3) Bridge:** "A starter is like a franchise kit. The franchisor (starter author)
provides a complete setup guide (@Configuration class) and a list of required
equipment (@Dependencies). Any new franchise (application) just installs the kit
(adds starter dependency) and the business runs. Customizations are allowed
(properties, @ConditionalOnMissingBean) but the basics just work."

---

### 📘 Concept Explanation

**What it is:**
A Spring Boot Starter is a reusable, auto-configuring library that integrates
seamlessly into Spring Boot applications. It uses Spring Boot's auto-configuration
mechanism to create beans when certain conditions are met.

**Starter structure:**

```
my-thing-spring-boot-starter/          (BOM / POM only)
  pom.xml
    <dependencies>
      <dependency>my-thing-spring-boot-autoconfigure</dependency>
      <dependency>my-thing-core</dependency>  (the actual library)
    </dependencies>

my-thing-spring-boot-autoconfigure/    (the meat)
  pom.xml
  src/main/java/
    com/example/mythingauto/
      MyThingAutoConfiguration.java    (@AutoConfiguration)
      MyThingProperties.java           (@ConfigurationProperties)
      MyThingClient.java               (the bean being configured)
  src/main/resources/
    META-INF/spring/
      org.springframework.boot.autoconfigure.AutoConfiguration.imports
        (Spring Boot 2.7+)
    # OR (legacy, Spring Boot < 2.7)
    META-INF/spring.factories

Conditional logic:
  @ConditionalOnClass: MyThingClient on classpath?
  @ConditionalOnMissingBean: user already created one?
  @ConditionalOnProperty: enabled=true in properties?
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Conditional annotations:**

```
@ConditionalOnClass({SomeClass.class})
  -> beans created only if SomeClass is on classpath
  -> use case: don't configure Hikari if it's not present

@ConditionalOnMissingBean(MyThingClient.class)
  -> bean created only if user hasn't configured one
  -> use case: provide default, allow override

@ConditionalOnProperty(
    prefix = "my-thing",
    name = "enabled",
    havingValue = "true",
    matchIfMissing = true)
  -> bean created if property is true (default: create)

@ConditionalOnWebApplication
  -> only in web application context

@ConditionalOnExpression("${my-thing.mode} == 'async'")
  -> SpEL-based condition (avoid if possible - hard to test)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// Complete custom starter example: HTTP client starter

// 1. @ConfigurationProperties for user config
@ConfigurationProperties(prefix = "mycompany.http-client")
@Validated
public class HttpClientProperties {

    /** Base URL for the HTTP client. Required. */
    @NotBlank
    private String baseUrl;

    /** Connection timeout in milliseconds. */
    private int connectTimeoutMs = 5000;

    /** Read timeout in milliseconds. */
    private int readTimeoutMs = 30_000;

    // getters and setters...
}
```

```java
// 2. The @AutoConfiguration class
@AutoConfiguration                         // Spring Boot 2.7+
@ConditionalOnClass(OkHttpClient.class)    // OkHttp on classpath?
@EnableConfigurationProperties(
    HttpClientProperties.class)
public class HttpClientAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean              // respect user override
    public OkHttpClient okHttpClient(
            HttpClientProperties props) {
        return new OkHttpClient.Builder()
            .connectTimeout(
                props.getConnectTimeoutMs(),
                TimeUnit.MILLISECONDS)
            .readTimeout(
                props.getReadTimeoutMs(),
                TimeUnit.MILLISECONDS)
            .build();
    }

    @Bean
    @ConditionalOnMissingBean
    @ConditionalOnBean(OkHttpClient.class)
    public HttpClientFacade httpClientFacade(
            OkHttpClient client,
            HttpClientProperties props) {
        return new HttpClientFacade(
            client, props.getBaseUrl());
    }
}
```

```
# 3. Registration file (Spring Boot 2.7+)
# src/main/resources/META-INF/spring/
# org.springframework.boot.autoconfigure.AutoConfiguration.imports

com.mycompany.autoconfigure.HttpClientAutoConfiguration
```

```java
// 4. Test the auto-configuration in isolation
@SpringBootTest
@ImportAutoConfiguration(
    HttpClientAutoConfiguration.class)
class HttpClientAutoConfigurationTest {

    @Autowired(required = false)
    HttpClientFacade facade;

    @Test
    void configuresClientWhenPropertiesPresent() {
        assertThat(facade).isNotNull();
    }

    @Test
    void respectsUserOverride() {
        // TODO: use ApplicationContextRunner for this
    }
}

// Better: ApplicationContextRunner for unit testing
class HttpClientAutoConfigTest {

    private final ApplicationContextRunner runner =
        new ApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(
                HttpClientAutoConfiguration.class));

    @Test
    void defaultClientCreated() {
        runner.withPropertyValues(
            "mycompany.http-client.base-url=http://api")
            .run(ctx -> {
                assertThat(ctx).hasSingleBean(
                    HttpClientFacade.class);
                assertThat(ctx).hasSingleBean(
                    OkHttpClient.class);
            });
    }

    @Test
    void userBeanTakesPriority() {
        runner
            .withBean(OkHttpClient.class,
                OkHttpClient::new)  // user-provided
            .withPropertyValues(
                "mycompany.http-client.base-url=http://api")
            .run(ctx -> {
                // Only 1 OkHttpClient (user's)
                assertThat(ctx).hasSingleBean(
                    OkHttpClient.class);
            });
    }

    @Test
    void disabledWhenOkHttpNotOnClasspath() {
        // Exclude OkHttpClient to simulate absence
        runner.withClassLoader(
            new FilteredClassLoader(OkHttpClient.class))
            .run(ctx -> {
                assertThat(ctx).doesNotHaveBean(
                    HttpClientFacade.class);
            });
    }
}
```

> **Code walkthrough:** ApplicationContextRunner is the recommended way to test
> auto-configuration. It creates lightweight ApplicationContext instances with
> specific configuration applied. withConfiguration() adds auto-configurations.
> withPropertyValues() sets properties. withBean() adds pre-existing beans
> (simulating user-created beans). FilteredClassLoader simulates a class not
> being on the classpath (for @ConditionalOnClass testing). The runner's run()
> method provides the ApplicationContext inside a lambda for assertions. This
> approach tests each condition path independently without requiring a full
> Spring Boot application.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A Spring Boot Starter is a library you can add to your project that automatically
> sets up beans for you. For example, spring-boot-starter-data-jpa automatically
> creates EntityManagerFactory and TransactionManager. To create a custom starter,
> you make a @Configuration class with @Bean methods and @ConditionalOnMissingBean
> annotations, then register it so Spring Boot finds it automatically. The
> registration is in META-INF/spring/...AutoConfiguration.imports.

**Senior / Staff (5+ years):**
> Custom starters require careful conditional logic to avoid conflicting with
> user-provided beans. @ConditionalOnMissingBean is the courtesy annotation:
> "I'll create this bean unless you already have one." @ConditionalOnClass
> prevents activation when the required library isn't present (avoids
> ClassNotFoundException on optional dependencies). Testing: ApplicationContextRunner
> is faster than @SpringBootTest because it doesn't start a full context.
> Test each conditional path separately: class present/absent, bean present/absent,
> property enabled/disabled. Also: @EnableConfigurationProperties + @Validated
> on properties class gives you early failure with descriptive errors when required
> properties are missing.

---

### ⚠️ Common Misconceptions

**Misconception 1: "spring.factories is the correct registration file."**
spring.factories was correct until Spring Boot 2.6. In Spring Boot 2.7,
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
was introduced. spring.factories still works (backward compatible) but is deprecated.
For new starters: use the .imports file. The annotation also changed: @Configuration
+ EnableAutoConfiguration handling -> @AutoConfiguration (which implies @Configuration).

**Misconception 2: "@ConditionalOnMissingBean checks type by default."**
By default, @ConditionalOnMissingBean checks the bean type (return type of @Bean
method). If user has registered ANY bean of that type, the auto-configuration
bean is skipped. If user registers a subtype, it still matches. Edge case: if
user registers via @Bean in a @Configuration AFTER the auto-configuration, the
condition may have already been evaluated. Order matters: @AutoConfiguration
classes run after @Configuration by default.

**Misconception 3: "Adding the starter dependency is the same as the auto-configuration running."**
The auto-configuration runs only when the registered class is activated. If
@ConditionalOnClass is used and the required class is not on the classpath, the
auto-configuration class does nothing. The registration always loads the class name,
but the conditions gate whether beans are created. The class itself may not be
instantiable if required dependencies are absent.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Auto-configuration not running**
Symptom: Beans from starter are not created. Application behaves as if starter
is absent.
Diagnosis:
- Check if registration file exists and correct class name is in it
- Check class path (right module included?)
- Check @ConditionalOn* conditions: add --debug flag to Spring Boot
  -> CONDITIONS EVALUATION REPORT section shows why each auto-configuration
     was matched or NOT matched

**Failure 2: @ConditionalOnMissingBean does not respect user override**
Symptom: Both user's bean and auto-configuration bean are created, causing
"expected single bean, found 2" errors.
Cause: condition evaluated before user's @Configuration was processed.
Fix: Use @AutoConfigureAfter(UserConfig.class) or order your autoconfiguration
to run after user @Configuration classes.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - What is the difference between a starter and an auto-configuration module?

The starter is a convenience POM only. The auto-configure module is the code.

```
spring-boot-starter-data-jpa (starter)
  -> spring-boot-autoconfigure (JPA AutoConfig inside)
  -> spring-data-jpa
  -> hibernate-core
  -> jakarta.persistence-api

spring-boot-autoconfigure (auto-configure)
  -> JpaRepositoriesAutoConfiguration.class
  -> HibernateJpaAutoConfiguration.class
  -> (all other auto-configurations)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

You can depend directly on spring-boot-autoconfigure if you only want
the auto-configuration without the starter's dependency management.
This is useful when you want explicit control over JPA library versions.

*What separates good from great:* spring-boot-autoconfigure contains ALL
Spring Boot auto-configurations in a single jar. Each is conditionally activated.
This is why you don't need a separate jar per feature: the conditions (like
@ConditionalOnClass(JpaRepository.class)) gate activation. Custom starters
follow the same pattern: one autoconfigure module (the library), one starter
module (the POM). When creating an internal company starter, both modules
are needed only if different teams need to depend on just the autoconfigure
logic. For internal use: a single module with both auto-config classes and
POM is usually sufficient.

---

#### Q2 - How do @AutoConfigureBefore and @AutoConfigureAfter work?

Auto-configurations can declare ordering relative to each other:

```java
@AutoConfiguration
@AutoConfigureAfter(DataSourceAutoConfiguration.class)
@ConditionalOnBean(DataSource.class)
public class JdbcTemplateAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

JdbcTemplateAutoConfiguration runs AFTER DataSourceAutoConfiguration
because it needs the DataSource bean to be available.

@AutoConfigureBefore: I must run before this other configuration.
@AutoConfigureAfter: I must run after this other configuration.

These control ordering within the auto-configuration phase.
User @Configuration classes always run before auto-configurations.

*What separates good from great:* @AutoConfigureAfter is a declaration of intent,
not a hard guarantee. If DataSourceAutoConfiguration is excluded
(spring.autoconfigure.exclude), JdbcTemplateAutoConfiguration still runs
(after nothing). The @ConditionalOnBean(DataSource.class) check prevents
JdbcTemplate creation if DataSource is absent. Best practice: combine ordering
(@AutoConfigureAfter) with conditional bean checks (@ConditionalOnBean) for
robustness.

---

#### Q3 - How does @ConfigurationProperties binding work in starters?

```java
// Properties class:
@ConfigurationProperties(prefix = "mycompany.service")
public class ServiceProperties {
    private String endpoint = "http://default";
    private int timeout = 5000;
    private Retry retry = new Retry();

    public static class Retry {
        private int maxAttempts = 3;
        private long backoffMs = 1000;
        // getters, setters
    }
    // getters, setters
}

// Registration in auto-configuration:
@AutoConfiguration
@EnableConfigurationProperties(ServiceProperties.class)
public class ServiceAutoConfiguration {

    @Bean
    public ServiceClient client(ServiceProperties props) {
        return new ServiceClient(
            props.getEndpoint(),
            props.getTimeout(),
            props.getRetry().getMaxAttempts());
    }
}

// User's application.properties:
mycompany.service.endpoint=http://prod-api
mycompany.service.retry.max-attempts=5
# mycompany.service.timeout: not set, uses default 5000
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Metadata generation (IDE autocompletion):
```xml
<!-- In autoconfigure module pom.xml: -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Generates META-INF/spring-configuration-metadata.json at compile time.
IDE reads this for autocompletion in application.properties.

*What separates good from great:* @ConfigurationProperties vs @Value for
starters: always prefer @ConfigurationProperties. It provides type-safe binding,
supports nested objects, has JSR-303 validation support (@Validated + @NotBlank),
and generates metadata for IDE support. @Value properties are validated lazily
(at bean creation time). @ConfigurationProperties with @Validated fails eagerly
at context refresh if a required property is missing. For production starters,
@Validated on the properties class + @NotBlank/@Min/@Max constraints makes
misconfiguration an explicit error with a clear message rather than a NullPointerException
deep in your library code.

---

#### Q4 - How do you exclude an auto-configuration?

Three approaches:
```java
// 1. @SpringBootApplication(exclude)
@SpringBootApplication(exclude = {
    DataSourceAutoConfiguration.class,
    HibernateJpaAutoConfiguration.class
})
public class MyApplication { }

// 2. application.properties
spring.autoconfigure.exclude=\
  org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration

// 3. Test-level exclusion
@SpringBootTest
@ImportAutoConfiguration(exclude = {
    DataSourceAutoConfiguration.class
})
class MyTest { }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Use case for exclusion:
- Test environments (exclude DataSource, use in-memory or mock)
- Multiple DataSource configurations (exclude default, define custom)
- Conflicting auto-configurations (two starters provide same bean)

*What separates good from great:* The right response to two starters that both
auto-configure the same bean type is @ConditionalOnMissingBean in both starters.
If one auto-configuration creates the bean first, the second finds it present
and skips. If you need deterministic ordering: add @AutoConfigureAfter or
@AutoConfigureBefore. Only use exclude when you definitively want NO auto-configuration
for a feature - like disabling DataSource entirely in a batch job that uses
direct JNDI lookup.

---

#### Q5 - How does Spring Boot actuator integrate with custom starters?

Custom beans can contribute to health, info, and metrics:

```java
// Custom health indicator:
@Component
@ConditionalOnEnabledHealthIndicator("my-service")
public class MyServiceHealthIndicator
        implements HealthIndicator {

    private final MyServiceClient client;

    @Override
    public Health health() {
        try {
            boolean alive = client.ping();
            return alive
                ? Health.up()
                    .withDetail("status", "reachable")
                    .build()
                : Health.down()
                    .withDetail("status", "unreachable")
                    .build();
        } catch (Exception ex) {
            return Health.down(ex).build();
        }
    }
}

// In auto-configuration:
@AutoConfiguration
@ConditionalOnClass(HealthIndicator.class)
// Only if actuator is on classpath
public class MyServiceAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public MyServiceClient myServiceClient(
            MyServiceProperties props) {
        return new MyServiceClient(props.getEndpoint());
    }

    @Bean
    @ConditionalOnBean(MyServiceClient.class)
    @ConditionalOnEnabledHealthIndicator("my-service")
    public MyServiceHealthIndicator healthIndicator(
            MyServiceClient client) {
        return new MyServiceHealthIndicator(client);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* @ConditionalOnClass(HealthIndicator.class)
ensures the health indicator only activates when actuator is on the classpath.
If actuator is excluded, no HealthIndicator bean is created. This is the
"optional dependency" pattern: your starter works without actuator, but adds
health monitoring when actuator is present. Similarly for metrics: add
@ConditionalOnClass(MeterRegistry.class) to gate metrics beans on Micrometer
presence. The result: adding spring-boot-starter-actuator to an application using
your starter automatically enables health monitoring without any user configuration.

---

#### Q6 - What happens to auto-configuration ordering in Spring Boot 3?

Spring Boot 3 changes:
1. Registration: META-INF/spring.factories deprecated (still works but logs warning)
   New: META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
2. @Configuration -> @AutoConfiguration: new annotation, more explicit
   @AutoConfiguration = @Configuration + special auto-config semantics
   Should be used only for auto-configuration classes (not user @Configuration)
3. Ordering: @AutoConfigureBefore/@AutoConfigureAfter attributes on @AutoConfiguration
   annotation itself (not separate annotations):
   ```java
   @AutoConfiguration(after = DataSourceAutoConfiguration.class)
   public class JdbcTemplateAutoConfiguration { }
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

4. Probing: Spring Boot 3 uses DeferredImportSelector with different
   ordering guarantees. @AutoConfiguration classes are processed as a group
   AFTER all regular @Configuration classes.

*What separates good from great:* Migrating from Spring Boot 2 to 3: if your
starter uses spring.factories, migration is: (1) create the .imports file,
(2) change @Configuration to @AutoConfiguration on auto-config classes. The
spring.factories file still works in Spring Boot 3 for now (backward compat)
but will be removed in a future version. For new starters targeting Spring Boot 3+:
use only the new mechanism. For starters targeting both 2.x and 3.x: include
both files. Spring Boot picks the .imports file if present; falls back to
spring.factories.

---

#### Q7 - How do you test that @ConditionalOnMissingBean respects user config?

```java
// ApplicationContextRunner test for user override:
class ServiceAutoConfigTest {

    private final ApplicationContextRunner runner =
        new ApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(
                ServiceAutoConfiguration.class))
            .withPropertyValues(
                "mycompany.service.endpoint=http://api");

    @Test
    void usesUserBeanWhenPresent() {
        MyServiceClient userBean = 
            mock(MyServiceClient.class);

        runner
            .withBean(MyServiceClient.class,
                () -> userBean)  // user-provided
            .run(ctx -> {
                // Still only 1 bean (user's)
                assertThat(ctx)
                    .hasSingleBean(MyServiceClient.class);
                // It's the user's bean, not auto-configured
                assertThat(ctx.getBean(
                    MyServiceClient.class))
                    .isSameAs(userBean);
            });
    }

    @Test
    void autoConfiguresWhenNoUserBean() {
        runner.run(ctx -> {
            assertThat(ctx)
                .hasSingleBean(MyServiceClient.class);
            // Not the mock - auto-configured
            assertThat(ctx.getBean(
                MyServiceClient.class))
                .isNotNull()
                .isNotInstanceOf(Mockito.class);
        });
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The ApplicationContextRunner.withBean() method
adds a bean as if the user had declared it in their @Configuration. This accurately
tests that @ConditionalOnMissingBean fires correctly. Key edge case: what if the
user provides a SUBTYPE? @ConditionalOnMissingBean checks by type, so a subtype
matches. Test this explicitly if your library's users might reasonably extend
your bean types. Also test the property-conditional paths: what if endpoint
is not set? The @Validated properties class should throw a descriptive error
(BindValidationException) rather than letting the null propagate to the
constructor.

---

#### Q8 - How do you add configuration metadata for IDE support?

```xml
<!-- In autoconfigure pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Generated at compile time:
META-INF/spring-configuration-metadata.json

For additional hints not auto-generated:
```json
// src/main/resources/META-INF/
// additional-spring-configuration-metadata.json
{
    "properties": [{
        "name": "mycompany.service.mode",
        "type": "java.lang.String",
        "description": "Operation mode (sync or async).",
        "defaultValue": "sync"
    }],
    "hints": [{
        "name": "mycompany.service.mode",
        "values": [
            {"value": "sync",
             "description": "Synchronous mode."},
            {"value": "async",
             "description": "Asynchronous mode."}
        ]
    }]
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Result in IDE: typing mycompany.service. in application.properties
shows autocomplete for all properties with descriptions and types.

*What separates good from great:* Configuration metadata is a quality signal
for users of your starter. Without it: users must read source code to discover
properties. With it: IDE completion works exactly like spring.datasource.url
or spring.security.oauth2.*. Include descriptions that tell the user what the
property does, not just what it is. For enums: add hints with value/description
pairs for each valid enum value. The additional-spring-configuration-metadata.json
lets you add metadata for properties that the annotation processor can't infer
(system properties, dynamic keys, third-party properties your starter bridges).

---

#### Q9 - How would you design a multi-module starter for an internal service client?

```
mycompany-service-spring-boot-starter/
  mycompany-service-client/            (core library, no Spring)
    MyServiceClient.java
    MyServiceConfig.java               (POJO, no Spring)
    MyServiceException.java

  mycompany-service-spring-boot-autoconfigure/  (Spring integration)
    MyServiceAutoConfiguration.java
    MyServiceProperties.java           (@ConfigurationProperties)
    MyServiceHealthIndicator.java      (actuator integration)
    src/main/resources/
      META-INF/spring/
        ...AutoConfiguration.imports

  mycompany-service-spring-boot-starter/        (POM)
    pom.xml
      -> mycompany-service-client
      -> mycompany-service-spring-boot-autoconfigure
      -> spring-boot-starter (baseline)

  mycompany-service-spring-boot-test/  (test utilities)
    MyServiceMockServer.java           (WireMock-based mock)
    @AutoConfigureMyServiceMock.java   (test auto-config)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Test starter:
```java
// Service tests auto-configure a mock server
@SpringBootTest
@AutoConfigureMyServiceMock
class OrderServiceTest {
    // MyServiceClient is auto-replaced with mock
    @Autowired
    MyServiceMockServer mockServer;

    @Test
    void orderPlacedCallsMyService() {
        mockServer.stubFor(post("/orders")
            .willReturn(ok()));
        // test OrderService which calls MyService
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The test module is the underrated part of a
good internal starter. Production code using the starter needs test support.
Without a test module: every team writes their own WireMock stubs or Mockito mocks.
With a test module: @AutoConfigureMyServiceMock provides a standardized mock
that all teams use. This ensures tests use a consistent mock that matches the
real service contract. The test module depends on the autoconfigure module
(to understand the beans) and WireMock (for HTTP mocking), but NOT on test
scope - it's a compile dependency for test code.

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



