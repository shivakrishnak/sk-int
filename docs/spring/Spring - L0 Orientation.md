---
layout: default
title: "Spring - L0 Orientation"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 1
permalink: /spring/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L0 Orientation](#spring---l0-orientation) | medium |
| 2 | [Spring Framework Overview](#spring-framework-overview) | medium |
| 3 | [Spring vs EJB - The Simplicity Revolution](#spring-vs-ejb---the-simplicity-revolution) | medium |
| 4 | [Spring Ecosystem Map](#spring-ecosystem-map) | medium |

---

# Spring Framework Overview

---
id: SPR-001
title: Spring Framework Overview
category: Spring
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #spring, #java, #framework, #dependency-injection, #ioc
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - the first question in every Spring interview.
Sets the foundation for all follow-up questions on DI, beans, and Boot.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Framework is an open-source Java application framework built around
> Inversion of Control and Dependency Injection. It solves the problem of
> wiring together complex Java applications without tight coupling between
> components. Instead of objects creating their own dependencies, Spring
> creates and injects them - making code testable, modular, and loosely
> coupled.

**3 minutes (Senior):**
> Spring was born in 2002 when Rod Johnson published "Expert One-on-One J2EE
> Design and Development" and demonstrated that enterprise Java did not need
> the bloat of EJBs. The core insight was simple: if you invert who controls
> object creation, handing that responsibility to a container, then your
> business code depends on abstractions instead of implementations.
>
> Today Spring is a family of projects centred on Spring Framework (the core
> container) and Spring Boot (opinionated auto-configuration on top of it).
> The container manages a registry of objects called beans - it creates them,
> wires their dependencies, and manages their lifecycle. Your code expresses
> what it needs via annotations or XML; Spring figures out how to satisfy
> those needs at startup.
>
> The trade-off Spring makes is startup-time configuration in exchange for
> runtime flexibility and testability. The non-obvious insight is that Spring
> is not magic - it is a very sophisticated object factory built on Java
> reflection and proxies. Everything Spring does, you could do manually; Spring
> just removes the boilerplate.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Senior/Staff should connect to architectural decisions - when
Spring's proxy-based AOP is the right choice vs compile-time weaving, and
the cost of classpath scanning at scale.

*Adapting down:* Junior - "Spring wires your Java objects together so you
don't have to write new SomeService() everywhere."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Spring Framework - let me think
through what problem it exists to solve."

**(2) First principles:** "From first principles, as a Java application grows,
objects need to find and use other objects. Hard-coding those relationships
creates tight coupling that makes testing and change painful. You need
something to manage those relationships externally."

**(3) Bridge:** "This reminds me of the Factory pattern. Spring is essentially
a factory for all your application objects, but configured declaratively
rather than coded by hand."

---

### 📘 Concept Explanation

**What it is:**
Spring Framework is a comprehensive Java application framework providing
Inversion of Control (IoC), Dependency Injection (DI), AOP, data access,
web MVC, and integration abstractions - all centred around a lightweight
bean container.

**The problem it solves:**
Before Spring, enterprise Java meant EJBs - heavy, server-dependent
components that required deployment to an application server just to run
a test. Business logic tangled with infrastructure concerns. Objects created
their own dependencies, making unit testing nearly impossible. Spring solved
this by separating the "what" (your business code) from the "how" (wiring
and infrastructure), and doing so with pure POJOs running in any JVM.

**How it works:**

```
Your Application Code
        |
        | (declares needs via @Autowired / constructor args)
        v
  ApplicationContext  <-- "The Spring Container"
        |
        |-- reads config (annotations, @Configuration, XML)
        |-- creates bean instances in dependency order
        |-- injects dependencies into each bean
        |-- manages lifecycle (init, use, destroy)
        v
  Ready-to-use wired application
```

> **Code walkthrough:** This Spring Framework Overview example demonstrates a key concept in practice using Spring annotation. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

1. You annotate classes with @Component, @Service, @Repository, etc.
2. Spring scans the classpath and registers these as bean definitions.
3. At startup, Spring creates instances in dependency order, injecting
   each bean's required collaborators.
4. The ApplicationContext holds all live bean instances and serves them
   when requested.
5. When the application shuts down, Spring calls destroy methods on beans.

**The key insight:**
Spring is a directed graph of objects. Your annotations declare the edges
(dependencies); Spring builds the graph at startup. All the "magic" is
just Java reflection calling constructors and setters at the right time.
Understanding this makes every Spring mystery solvable.

**When to use it:**
- Any Java back-end application with multiple interacting components
- Enterprise Java applications requiring transaction management, security,
  and data access
- Microservices (via Spring Boot) where convention-over-configuration
  reduces boilerplate
- Applications requiring comprehensive test support with DI

**When NOT to use it:**
- Tiny scripts or utilities where a framework adds more overhead than value
- Latency-critical applications where startup time or reflection overhead
  is unacceptable (consider Quarkus or Micronaut instead)
- Teams already using Jakarta EE/CDI who do not need Spring's ecosystem

**Alternatives:**
- Quarkus -> compile-time DI with GraalVM native image support; faster
  startup; smaller memory footprint; build-time over runtime
- Micronaut -> also compile-time DI; AOT compilation; no reflection at
  runtime; good for serverless
- Jakarta EE / CDI -> standards-based DI inside application servers;
  less opinionated; more portable across vendors
- Guice (Google) -> lightweight DI only; no web, data, or AOP; pure
  Java configuration

**First-principles derivation:**
Given: Java objects need collaborators to do work. If each object creates
its own collaborators (new SomeDependency()), you cannot swap implementations
for testing and every change ripples. The only alternative is external
supply - either a factory, a service locator, or a container that injects.
A container that manages the full object graph from a single configuration
source is the cleanest answer - which is exactly Spring's IoC container.

---

### 💻 Code Example

```java
// BAD: Tight coupling - service creates its own dependency
public class OrderService {
    // Cannot test without a real PaymentService
    private PaymentService paymentService
        = new PaymentService();

    public void placeOrder(Order order) {
        paymentService.charge(order);
    }
}
```

> **Code walkthrough:** This shows the problem Spring solves. OrderServiceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> hard-codes new PaymentService(), making it impossible to inject a mock in
> tests. Any change to PaymentService's constructor breaks every caller.
> Tight coupling is the exact pain Spring was designed to eliminate.

```java
// GOOD: Spring DI - dependencies declared, not created
@Service
public class OrderService {
    private final PaymentService paymentService;

    // Spring injects the PaymentService at construction time
    public OrderService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    public void placeOrder(Order order) {
        paymentService.charge(order);
    }
}

@Service
public class PaymentService {
    public void charge(Order order) { /* ... */ }
}
```

> **Code walkthrough:** @Service marks both classes as Spring beans. Springice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> detects that OrderService needs a PaymentService, finds the bean in its
> registry, and injects it at construction time. In tests, you can pass a
> mock PaymentService directly - no Spring container needed. Constructor
> injection is the preferred style: dependencies are final and explicit.

```java
// Spring Boot entry point
@SpringBootApplication  // @Configuration + @EnableAutoConfiguration
                        // + @ComponentScan combined
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

// Unit test - no Spring context needed
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock PaymentService paymentService;
    @InjectMocks OrderService orderService;

    @Test
    void chargesPaymentOnOrder() {
        orderService.placeOrder(new Order());
        verify(paymentService).charge(any());
    }
}
```

> **Code walkthrough:** @SpringBootApplication triggers component scanningice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> of the current package and sub-packages. The test shows why constructor
> injection is preferred - Mockito creates the service with a mock dependency
> without starting a Spring context at all. Tests run fast and in complete
> isolation, which is the entire point of dependency injection.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Framework is an open-source Java framework that handles dependency
> injection - wiring objects together - so your business code stays clean
> and testable. You annotate classes with @Service or @Component, Spring
> creates them and injects what they need. Spring Boot adds auto-configuration
> so you spend no time on boilerplate setup.

*Push deeper:* Explain that Spring's container is called the
ApplicationContext, it holds all your beans, and dependency injection
makes unit testing easy because you can replace real beans with mocks.

---

**Senior / Staff (5+ years):**
> Spring is an IoC container that manages object creation and wiring for
> Java applications. The core mechanism is a bean registry populated at
> startup via classpath scanning and @Configuration classes. Every Spring
> feature - AOP, transactions, security, data - is implemented via bean
> post-processors and proxy objects sitting between the container and your
> code. The non-obvious thing is that almost all Spring behaviour is
> implemented in terms of BeanPostProcessor and BeanFactoryPostProcessor -
> understanding these two interfaces unlocks every mystery.

*Push deeper:* Discuss the Spring Context refresh lifecycle phases
(BeanDefinition loading, post-processing, singleton instantiation, init
callbacks). At scale, classpath scanning over large JARs creates startup
latency - Spring Boot's layered JARs and AOT compilation (Spring Boot 3+)
address this.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring is too heavy/magical."**
Spring is Java reflection at its core. Every bean creation is a reflected
constructor call. Every AOP proxy is a subclass generated at runtime. It
feels magical until you understand the proxy mechanism - then it is
completely predictable.

**Misconception 2: "Spring Boot and Spring Framework are the same thing."**
Spring Framework is the core IoC container (circa 2002). Spring Boot
(2014) is an opinionated layer on top that adds auto-configuration,
embedded servers, and production-ready defaults. Boot uses Framework;
Framework does not require Boot.

**Misconception 3: "You need XML to configure Spring."**
XML was the original configuration style (pre-2010). Since Spring 3.0,
@Configuration Java classes are the idiomatic approach. Spring Boot makes
XML rare to non-existent in modern applications.

**Misconception 4: "@Autowired is required for DI to work."**
Constructor injection works without @Autowired when there is exactly one
constructor (Spring 4.3+). Explicit @Autowired is only needed with field
injection or multiple constructors. Constructor injection is preferred
because it makes dependencies explicit and enables final fields.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: NoSuchBeanDefinitionException**
Symptom: Application fails at startup with "No qualifying bean of type X."
Cause: The required bean is not in the Spring context - class not annotated,
not in the scan path, or a conditional excluded it.
Diagnosis: Check component scan base packages. Run
`context.getBeanDefinitionNames()` to list all registered beans.
Fix: Add @Component/@Service to the class, or add @Bean to a
@Configuration class.

**Failure 2: BeanCurrentlyInCreationException (Circular Dependency)**
Symptom: "The dependencies of some of the beans form a cycle."
Cause: Bean A depends on Bean B, Bean B depends on Bean A - constructor
injection deadlocks.
Diagnosis: Spring prints the full cycle in the exception message.
Fix: Break the cycle by extracting a third collaborator, or use setter
injection with @Lazy on one side.

**Failure 3: Field injection null in tests**
Symptom: @Autowired field is null in a unit test outside Spring context.
Cause: Field injection requires Spring's reflection. Plain `new MyService()`
does not trigger this.
Fix: Switch to constructor injection - the dependency is set via the
constructor regardless of how the object is created.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions, 60-90 seconds each.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is Inversion of Control and why does it matter?**

IoC is the design principle where control of object creation and lifecycle
is inverted - instead of your code calling `new` to create dependencies,
an external container creates them and gives them to you.

It matters for three reasons. First, testability: when dependencies are
injected, you can replace them with mocks in tests. Second, flexibility:
you can swap implementations without changing callers. Third, decoupling:
your business code depends on abstractions (interfaces), not concrete
implementations.

The Hollywood Principle captures it: "Don't call us, we'll call you."
Your objects don't go fetch their dependencies - the container delivers them.

*What separates good from great:* Great answers connect IoC to the SOLID
principles - specifically Dependency Inversion (D in SOLID). IoC is the
runtime mechanism that enables the Dependency Inversion Principle at the
architectural level.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is the difference between BeanFactory and ApplicationContext?**

BeanFactory is the base Spring container - it lazily creates beans on first
request and provides core DI functionality. ApplicationContext extends
BeanFactory and adds: eager singleton instantiation at startup, event
publishing, internationalization (MessageSource), AOP auto-proxy creation,
and @PostConstruct / @PreDestroy lifecycle callbacks.

In practice, you always use ApplicationContext. BeanFactory is the
interface you program against; ApplicationContext is what you run.

*What separates good from great:* Spring Boot uses
AnnotationConfigServletWebServerApplicationContext for web applications
and AnnotationConfigApplicationContext for non-web. The choice is made
automatically by SpringApplication based on classpath detection.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What happens if you define two beans of the same type?**

Spring throws NoUniqueBeanDefinitionException at the injection point.

Resolution strategies:
1. @Primary on one bean - marks it as the default choice
2. @Qualifier("beanName") at the injection point - selects by name
3. @Profile to activate different beans in different environments

*What separates good from great:* @Primary creates implicit coupling -
any code injecting that type gets the primary bean. @Qualifier is more
explicit and safer in large codebases.

---

**[MID] Q4 - [CONCEPTUAL] How does Spring Boot differ from Spring Framework?**

Spring Framework provides the IoC container, DI, AOP, MVC, data access,
and all core abstractions. It requires explicit configuration.

Spring Boot adds opinionated auto-configuration: it detects what is on
your classpath and automatically configures beans with sensible defaults.
Boot also provides the parent POM with curated dependency versions so
you do not fight dependency conflicts.

Relationship: Boot = Framework + Auto-config + Embedded server + Actuator.

*What separates good from great:* Auto-configuration is just @Configuration
classes annotated with @ConditionalOnClass, @ConditionalOnMissingBean -
there is no magic. Spring Boot's auto-configuration source is readable
and override-able.

---

**[MID] Q5 - [CONCEPTUAL] What is the Spring bean lifecycle?**

The lifecycle phases in order:
1. Instantiation: Spring calls the constructor.
2. Dependency injection: injects @Autowired fields/methods.
3. Aware callbacks: BeanNameAware, ApplicationContextAware if implemented.
4. BeanPostProcessor.postProcessBeforeInitialization() for all BPPs.
5. @PostConstruct (or InitializingBean.afterPropertiesSet()).
6. Custom init-method if specified.
7. BeanPostProcessor.postProcessAfterInitialization() - AOP proxies created here.
8. Bean is ready for use.
9. @PreDestroy on shutdown (or DisposableBean.destroy()).
10. Custom destroy-method if specified.

*What separates good from great:* AOP proxy creation happens in step 7
(postProcessAfterInitialization). This is why @Transactional and @Async
do not work when you call a method on `this` inside the same bean - you
are bypassing the proxy.

---

**[MID] Q6 - [TRADE-OFF] Why is constructor injection preferred over field injection?**

Three concrete reasons:
1. Immutability: constructor-injected dependencies can be `final`.
2. Testability: create with `new MyService(mockDep)` - no Spring needed.
3. Mandatory dependencies visible: constructor signature documents what
   is required.

Field injection (@Autowired on fields) requires Spring to set private
fields via reflection after construction - the object exists in an invalid
state between construction and injection.

*What separates good from great:* Circular dependency detection. Constructor
injection causes Spring to fail fast at startup with a clear cycle error.
Field/setter injection silently defers wiring and can hide cycles.

---

**[SENIOR] Q7 - [CONCEPTUAL] What is the difference between @Component, @Service,**
       @Repository, and @Controller?

All four are specializations of @Component - functionally identical for
bean registration. The difference is semantic and enables framework features:

- @Component: generic stereotype for any Spring-managed bean
- @Service: marks business logic layer; no extra behaviour in core Spring
- @Repository: marks data access layer; activates persistence exception
  translation (wraps JPA/JDBC exceptions into DataAccessException hierarchy)
- @Controller: marks MVC controller; enables dispatcher servlet routing
- @RestController: @Controller + @ResponseBody

*What separates good from great:* @Repository's exception translation is
real Spring behaviour - it wraps vendor-specific exceptions into Spring's
DataAccessException hierarchy, making your service layer independent of the
data access technology.

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


# Spring vs EJB - The Simplicity Revolution

---
id: SPR-002
title: Spring vs EJB - The Simplicity Revolution
category: Spring
difficulty: ★☆☆
interview_weight: medium
asked_at: All
seniority: all
tags: #spring, #ejb, #j2ee, #history, #architecture
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Medium - asked to test historical context and
understanding of WHY Spring exists, not just what it does.

---

### 🎯 Model Answer

**30 seconds:**
> Spring was created as a direct reaction to EJB complexity. EJBs required
> classes to extend framework types, could only run inside expensive
> application servers, and made unit testing nearly impossible. Spring proved
> you could build enterprise Java with plain Java objects (POJOs) and a
> lightweight container, with tests that run in milliseconds instead of
> minutes.

**3 minutes (Senior):**
> In the early 2000s, the official answer to enterprise Java was EJB 2.x.
> To write a session bean you had to implement multiple interfaces, create
> deployment descriptors, and deploy to WebSphere or JBoss just to run a
> test. The build-deploy-test cycle took minutes. The framework owned your
> objects - you could not test them in isolation.
>
> Rod Johnson's 2002 book showed a different path: pure POJOs, a lightweight
> container running inside a plain JVM. You could test any bean with
> `new MyBean(mockDep)` without deploying anywhere. Spring's proposition was:
> enterprise features (transactions, data access) do not require framework
> inheritance.
>
> EJB 3.0 (2006) adopted Spring's ideas - annotations instead of XML, POJOs
> instead of interface inheritance. But by then Spring had the momentum. Spring
> Boot (2014) took this further: zero configuration for common cases, embedded
> servers, and a developer experience that made Spring the default Java
> back-end stack.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers should connect this to "invasiveness" - the
degree to which a framework forces you to extend its types. Non-invasive
frameworks (Spring, CDI) vs invasive ones (early EJBs) is a design decision
with long-term testability and portability implications.

*Adapting down:* Junior - "Before Spring, Java enterprise code was very
complicated to write and test. Spring made it simple by using plain objects
instead of framework-specific classes."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about why Spring was created versus the
existing EJB approach."

**(2) First principles:** "Any framework faces a key question: does it make
you extend its types, or does it work with plain objects? Frameworks that
own your objects are hard to test."

**(3) Bridge:** "This is the same trade-off as ORM frameworks. Hibernate works
with plain POJOs annotated after the fact; older ORMs required you to extend
their base Entity class."

---

### 📘 Concept Explanation

**What it is:**
The historical contrast between Enterprise JavaBeans (EJBs) - the J2EE
standard approach - and Spring's POJO-based alternative that revolutionised
Java enterprise development by proving non-invasive frameworks were viable.

**The problem it solves:**
EJB 2.x imposed enormous complexity: multiple interface implementations, XML
deployment descriptors, container-managed everything, and mandatory application
server deployment. The cost: slow test cycles, heavy vendor lock-in, and
objects so tangled with framework code that business logic was buried.
Spring's answer was radical simplicity: a framework that works with ordinary
Java objects instead of demanding you extend its classes.

**How it works:**

```
EJB 2.x (invasive):
  Your Bean
    extends SessionBean      <- must extend framework class
    implements EJBObject     <- must implement
    implements EJBHome       <- must implement
    + ejb-jar.xml descriptor <- XML required
    + deploy to AppServer    <- to run ANY test

Spring (non-invasive):
  Your Bean (plain Java class)
    @Service                 <- just one annotation
    constructor(deps)        <- plain constructor
    // test: new MyBean(mock) <- no container needed
```

> **Code walkthrough:** This The Simplicity Revolution example demonstrates a key concept in practice using Spring annotation. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

1. EJBs required framework interface inheritance.
2. EJB tests required deploying to an application server.
3. Spring worked with any POJO - your classes stayed clean.
4. Spring tests ran in-process in milliseconds.
5. EJB 3.0 (2006) adopted Spring's ideas but too late to recapture momentum.

**The key insight:**
"Invasiveness" - how much a framework pollutes your domain objects - is one
of the most important architectural properties of any framework choice. A
non-invasive framework preserves your ability to test, refactor, and reason
about your code independently of the framework.

**When to use it (context):**
Use this historical context to explain why Spring's design decisions
(POJO-first, proxy-based AOP, annotation-driven config) look the way they do.

**When NOT to use it:**
Jakarta EE (the modern standard after Oracle's transfer to Eclipse Foundation)
is a valid alternative. In environments requiring strict standards compliance
(financial, government), Jakarta EE may be preferred.

**Alternatives:**
- Jakarta EE / CDI -> modern standard; POJO-based; comparable to Spring
- Quarkus -> built on Jakarta EE CDI; compile-time DI; native image
- Micronaut -> compile-time; no reflection; lightweight

**First-principles derivation:**
Any framework must hook into your code. The hook can be inheritance (invasive),
reflection (non-invasive, runtime), or compile-time processing (non-invasive,
build-time). Spring chose reflection in 2002 - the only viable non-invasive
approach on Java 1.4. Modern frameworks (Quarkus, Micronaut) moved to
compile-time processing to eliminate the reflection overhead.

---

### 💻 Code Example

```java
// EJB 2.x style (historical - illustrates the problem)
public class OrderBeanEJB2 implements SessionBean {
    private SessionContext ctx;

    // Framework-mandated lifecycle callbacks - 4 empty methods
    public void ejbCreate() {}
    public void ejbRemove() {}
    public void ejbActivate() {}
    public void ejbPassivate() {}
    public void setSessionContext(SessionContext ctx) {
        this.ctx = ctx;
    }
    // Actual business logic buried under boilerplate
    public void placeOrder(String orderId) { /* ... */ }
}
// Also requires: ejb-jar.xml + deployment to AppServer to test
```

> **Code walkthrough:** This is the EJB 2.x pain Spring eliminated. Everyice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> business method is surrounded by framework lifecycle callbacks with nothing
> to do with business logic. The class cannot be instantiated without an EJB
> container. This is "invasive framework" - the framework's concerns leak
> directly into domain objects, making testing outside the container
> impossible.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// GOOD: Spring equivalent - pure POJO with one annotation
@Service
public class OrderService {
    private final PaymentGateway paymentGateway;

    public OrderService(PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }

    // Pure business logic - zero framework boilerplate
    public void placeOrder(String orderId) {
        paymentGateway.charge(orderId);
    }
}

// Unit test - no server, no container, instant
class OrderServiceTest {
    @Test void placesOrder() {
        var mock = mock(PaymentGateway.class);
        // Plain new - no Spring context at all
        var svc = new OrderService(mock);
        svc.placeOrder("order-1");
        verify(mock).charge("order-1");
    }
}
```

> **Code walkthrough:** The Spring service is a plain Java class with oneice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> annotation. The test creates it with `new` and a mock. No container, no
> server, no deployment. This millisecond test cycle was the killer feature
> of Spring in 2003 and remains its core value today. The business logic is
> completely visible without framework noise.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Before Spring, enterprise Java used EJBs which required complex framework
> inheritance and deploying to expensive servers just to run a test. Spring
> replaced that with plain Java classes and annotations. You write your
> business logic as a normal Java class, add @Service, and Spring handles
> the wiring. Tests run instantly without any server.

*Push deeper:* Explain "POJO-based development" means unit tests run in
milliseconds rather than minutes with full deployment.

---

**Senior / Staff (5+ years):**
> The EJB vs Spring story is about framework invasiveness. EJBs required
> your domain objects to extend framework types, tying business logic to the
> framework. Spring used reflection to work with plain objects, leaving your
> domain model framework-free. The proxy mechanism - Spring wraps your beans
> in generated subclasses to intercept method calls - is the elegant runtime
> implementation of non-invasion. EJB 3.0 copied this but by then Spring had
> won.

*Push deeper:* Discuss the trade-offs of proxy-based AOP vs compile-time
weaving (AspectJ). Proxies only intercept external method calls; AspectJ
intercepts every call including internal ones. This matters for @Transactional
and @Async - both silently fail on self-invocation due to proxy bypass.

---

### ⚠️ Common Misconceptions

**Misconception 1: "EJBs are dead."**
Modern Jakarta EE (post-Oracle transfer to Eclipse Foundation) has CDI that
is genuinely competitive with Spring. Many financial and government systems
run on Jakarta EE. "EJBs are dead" is a Spring echo chamber view.

**Misconception 2: "Annotations are the same invasiveness as EJB inheritance."**
Spring annotations can be removed from your source code without breaking core
business logic (unlike EJB extends/implements). You can use @Bean factory
methods to register POJOs that have zero Spring annotations. Annotations are
metadata, not behaviour.

**Misconception 3: "Spring replaced EJBs completely."**
Spring is more popular in modern Greenfield development. EJBs (in Jakarta EE
form) remain heavily used in enterprise environments requiring strict standards
compliance or deployed on WebSphere/JBoss.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Accidentally writing EJB-style Spring code**
Symptom: Spring services extend abstract base classes or implement Spring-
specific interfaces throughout the codebase.
Cause: Developer learned Spring through old EJB habits.
Fix: Spring beans should implement your own domain interfaces, not Spring
interfaces. Use @PostConstruct instead of InitializingBean; @PreDestroy
instead of DisposableBean.

**Failure 2: Confusing Spring and Jakarta EE annotations**
Symptom: @javax.ejb.Stateless used in a Spring application.
Cause: Mixed tutorial sources or team members from different backgrounds.
Fix: In Spring applications, use Spring/@jakarta.persistence annotations.
In Jakarta EE, use CDI (@ApplicationScoped), not Spring annotations.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

**[JUNIOR] Q1 - [HANDS-ON] Why was Spring created?**

Rod Johnson published "Expert One-on-One J2EE Design and Development" in
2002 demonstrating that enterprise features (transactions, data access) could
be implemented with plain Java objects in a lightweight container - no EJB
container required. The core problem with EJB 2.x was invasiveness: your
classes had to extend framework base classes, making them impossible to test
outside the container. Spring proved you could have enterprise capability
without framework inheritance. The test cycle dropped from minutes to
milliseconds, and the developer community adopted it rapidly.

*What separates good from great:* Name the book and the year. Mention that
Rod Johnson also co-founded Interface21 (later SpringSource, acquired by
VMware in 2009). This chain shows Spring was a deliberate architectural
argument, not accidental success.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What does "non-invasive framework" mean?**

A non-invasive framework does not require your business classes to extend its
types or implement its interfaces. Your domain objects stay framework-free;
the framework hooks in from the outside via reflection, annotations, or code
generation.

Spring is non-invasive because you can take any @Service class, strip the
@Service annotation, and the class is still a perfectly valid Java object.
Compare EJB 2.x where removing extends SessionBean breaks everything.

The practical benefit: domain objects can be tested as plain Java, used in
non-Spring contexts, and their logic is readable without framework knowledge.

*What separates good from great:* Note that annotations still create some
coupling. True zero-coupling uses XML config or @Bean factory methods in
@Configuration classes. For domain model objects (entities, value objects),
Spring enforces no coupling at all.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How did Spring influence the EJB 3.0 specification?**

EJB 3.0 (JSR-220, 2006) directly adopted Spring's ideas: POJOs with
annotations instead of interface inheritance, dependency injection via @EJB
and (later) @Inject, JPA replacing CMP entity beans. The spec authors
acknowledged Spring had demonstrated the right approach.

By the time EJB 3.0 shipped, Spring had four years of adoption momentum and
a richer ecosystem. EJB 3.0 was better than EJB 2.x but could not displace
Spring's installed base.

*What separates good from great:* CDI (JSR-299, 2009) was the Jakarta EE
answer to Spring's DI. CDI is excellent - type-safe, producer methods,
interceptors - but Spring's ecosystem (Boot, Data, Security, Cloud) is what
keeps Spring dominant.

---

**[MID] Q4 - [CONCEPTUAL] What is the POJO principle in Spring development?**

POJO (Plain Old Java Object) means a class that does not extend any framework
class and implements no framework interface beyond what the domain requires. In
Spring, your business services, repositories, and domain models should all be
POJOs.

The POJO principle has three consequences:
1. Unit tests create business objects with plain new and mock dependencies.
2. The class can be understood without framework documentation.
3. Migrating frameworks requires changing configuration, not rewriting
   business logic.

Modern Spring reinforces this: prefer @PostConstruct over InitializingBean,
@PreDestroy over DisposableBean, constructor injection over BeanFactoryAware.

*What separates good from great:* Entities in JPA are POJOs. Spring Data
repositories are interfaces. Neither has framework base classes - the
architecture is working as intended.

---

**[MID] Q5 - [TRADE-OFF] What is the key trade-off of Spring's proxy-based approach?**

Spring implements AOP (and therefore @Transactional, @Async, @Cacheable) by
wrapping beans in proxy objects - JDK dynamic proxies for interfaces or CGLIB
subclass proxies for concrete classes.

The trade-off: this only intercepts calls from outside the bean. When method A
calls method B in the same bean, the call goes directly to the target object,
bypassing the proxy. This means:

- Calling @Transactional from within the same class does NOT start a transaction
- Calling @Async from within the same class does NOT run asynchronously
- @Cacheable on an internal method does NOT cache

This is the most common Spring production bug and the most common interview
trap question.

*What separates good from great:* Solutions are: self-inject the bean with
@Lazy to break the circular dependency, or refactor so the cross-cutting
method is on a separate bean. For @Transactional, use TransactionTemplate
programmatically as another option.

---

**[MID] Q6 - [TRADE-OFF] When would you NOT choose Spring?**

Three legitimate scenarios:

1. Native image / serverless cold starts: Spring's classpath scanning takes
   seconds. Quarkus or Micronaut compile-time DI are better for latency-
   sensitive serverless. Spring Boot 3+ native image support is improving.

2. Tiny utilities and scripts: Spring startup overhead is not worth it for
   a CLI tool running 100ms.

3. Jakarta EE-mandated environments: some enterprises mandate Jakarta EE
   containers (WebSphere, WildFly) for compliance reasons.

*What separates good from great:* "Spring is always the answer" is a red
flag showing lack of trade-off thinking. Mentioning the trade-offs shows
engineering judgment.

---

**[SENIOR] Q7 - [ARCHITECTURE] What is Spring's module structure?**

Spring Framework modules:
- spring-core: IoC container, DI, utilities
- spring-beans: Bean definitions and BeanFactory
- spring-context: ApplicationContext, events, i18n
- spring-aop: Proxy-based AOP
- spring-web / spring-webmvc: HTTP and MVC
- spring-webflux: Reactive web (Project Reactor)
- spring-data: Repository abstractions
- spring-security: Authentication and authorization
- spring-tx: Transaction management
- spring-test: TestContext framework, MockMvc

Spring Boot auto-configures whichever modules are on the classpath. The
spring-boot-starter-* POMs are the practical mechanism for module selection.
The Spring Boot BOM prevents version conflicts.

*What separates good from great:* A microservice can use spring-web +
spring-tx without pulling in spring-security or spring-batch. Modular
design means you include only what you need.

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


# Spring Ecosystem Map

---
id: SPR-003
title: Spring Ecosystem Map
category: Spring
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #spring, #ecosystem, #spring-boot, #spring-cloud, #spring-security
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - interviewers use ecosystem questions to gauge
breadth of Spring experience and which parts of the stack you have used.

---

### 🎯 Model Answer

**30 seconds:**
> The Spring ecosystem has a layered structure: Spring Framework is the
> foundation IoC container, Spring Boot adds auto-configuration and embedded
> servers on top, and a family of Spring projects (Security, Data, Cloud,
> Batch, Integration) adds domain-specific capabilities. In most modern
> applications you use Spring Boot as the platform and pull in whichever
> Spring project modules you need.

**3 minutes (Senior):**
> Spring started as a single framework but evolved into an ecosystem of
> projects managed under the spring.io umbrella.
>
> At the base, Spring Framework provides the IoC container, AOP, MVC,
> WebFlux, and transaction management.
>
> Spring Boot is an opinionated starter layer - it auto-configures whatever
> is on your classpath, embeds a web server, and provides production-ready
> defaults. For 90% of applications, Boot is where you start.
>
> Domain-specific projects extend Boot: Spring Data adds repository
> abstractions over JPA, MongoDB, Redis. Spring Security provides auth.
> Spring Cloud adds service discovery, distributed config, circuit breakers
> for microservices. Spring Batch handles bulk data processing.
>
> The integration point between projects is always BeanDefinitions - each
> project contributes beans to the shared context. Understanding this makes
> debugging auto-configuration conflicts straightforward.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers should map the ecosystem to architectural
choices: Spring Cloud vs Kubernetes for service discovery, Spring Security
vs API gateway for auth, Spring Data vs plain JPA for repository patterns.

*Adapting down:* Junior - "Spring Framework is the engine, Spring Boot is
the car with everything preconfigured, and Cloud/Data/Security are
add-on packages."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Spring project ecosystem and how
the different Spring projects relate to each other."

**(2) First principles:** "A framework ecosystem grows when the core is so
solid that additional projects build on the same abstractions. Spring
Framework's IoC container is the stable base; every other Spring project
is an extension of the bean container."

**(3) Bridge:** "This is like the Linux kernel story - the kernel (Spring
Framework) is the stable base; distributions (Spring Boot) add opinions;
applications (Spring Data, Security) add domain features."

---

### 📘 Concept Explanation

**What it is:**
The Spring ecosystem is a family of open-source projects centred on Spring
Framework, all sharing the same IoC container, testing support, and
dependency management via Spring Boot BOM.

**The problem it solves:**
Enterprise applications need more than DI - data access, security, messaging,
batch processing, service coordination. Instead of integrating disparate
third-party libraries manually, Spring projects provide opinionated,
auto-configurable modules that work together out of the box.

**How it works:**

```
spring.io Ecosystem Layers
──────────────────────────────────────────────────
Layer 3 - Domain Projects:
  Spring Data   | Spring Security | Spring Batch
  Spring Cloud  | Spring Integration | GraphQL

Layer 2 - Platform:
  Spring Boot (auto-config + embedded server)
  Spring Boot BOM (dependency management)
  Spring Boot Actuator (observability)

Layer 1 - Foundation:
  Spring Framework
    Core Container (IoC, DI, AOP)
    Web (MVC, WebFlux)
    Data Access (JDBC, ORM, Tx)
    Test (TestContext, MockMvc)
──────────────────────────────────────────────────
```

> **Code walkthrough:** This Spring Ecosystem Map example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The Spring Boot BOM (Bill of Materials) is the glue. It provides curated
compatible dependency versions for every Spring project and their transitive
dependencies. This is why Spring Boot applications rarely have dependency
version conflicts - the BOM handles it.

**When to use it:**
- Enterprise Java applications requiring multiple concerns (web + data +
  security + observability) solved consistently
- Microservices needing service discovery, config, circuit breakers
- Applications requiring standardised repository patterns across data stores

**When NOT to use it:**
- Applications where one Spring project's opinionated defaults conflict with
  organizational standards
- Teams without Spring expertise where auto-configuration magic causes
  confusion rather than productivity
- Minimal-dependency microservices where the full ecosystem is overhead

**Alternatives:**
- Quarkus + extensions -> compile-time config; smaller footprint; native image
- Micronaut + modules -> compile-time; similar structure
- Jakarta EE + MicroProfile -> standards-based; portable across vendors

**First-principles derivation:**
Once a community adopts a DI container, every library integration becomes an
auto-configuration module: "if JDBC driver is on classpath, create a
DataSource bean." The ecosystem grew by applying this pattern repeatedly.
@ConditionalOnClass/@ConditionalOnMissingBean is the mechanism that makes
every Spring project auto-configurable.

---

### 💻 Code Example

```java
// Spring Boot app using 4 ecosystem projects
// Starters in pom.xml:
// spring-boot-starter-web (MVC + Tomcat)
// spring-boot-starter-data-jpa (Data + Hibernate)
// spring-boot-starter-security (Security)
// spring-boot-starter-actuator (observability)

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

// Spring Data JPA - interface only, no implementation
public interface OrderRepository
    extends JpaRepository<Order, Long> {
    List<Order> findByCustomerId(Long customerId);
}

// Spring MVC - plain class, no framework extension
@RestController
@RequestMapping("/orders")
public class OrderController {
    private final OrderRepository repo;
    OrderController(OrderRepository repo) {
        this.repo = repo;
    }
    @GetMapping("/{id}")
    public Order get(@PathVariable Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND));
    }
}

// Spring Security - method-level authorization
@Service
public class OrderService {
    @PreAuthorize(
        "hasRole('ADMIN') or "
        + "#customerId == authentication.name")
    public List<Order> getOrders(String customerId) {
        // business logic here
        return List.of();
    }
}
```

> **Code walkthrough:** Four Spring ecosystem projects work together withoutice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> explicit wiring code. Spring Data creates an OrderRepository implementation
> at runtime. Boot auto-configures a DataSource and EntityManagerFactory.
> Spring Security activates @PreAuthorize processing. Spring MVC routes HTTP
> to controllers. The developer writes only business logic - zero
> infrastructure configuration required.

```java
// Spring Cloud: service discovery + circuit breaker
@SpringBootApplication
@EnableDiscoveryClient  // registers with Eureka/Consul
public class OrderServiceApp {
    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApp.class, args);
    }
}

// Resilience4j circuit breaker via Spring Cloud
@Service
public class PaymentClient {
    @CircuitBreaker(name = "payment",
        fallbackMethod = "fallback")
    public PaymentResult charge(Order order) {
        return restTemplate.postForObject(
            "http://payment-service/charge",
            order, PaymentResult.class);
    }

    public PaymentResult fallback(
            Order o, Throwable t) {
        return PaymentResult.deferred(o.getId());
    }
}
```

> **Code walkthrough:** Spring Cloud adds microservice cross-cutting concerns.
> @EnableDiscoveryClient registers the service with a service registry.
> The circuit breaker prevents cascade failures when payment-service is down.
> The fallback method returns a deferred result instead of failing. All of
> this is convention-based - switching from Eureka to Consul requires only
> a dependency swap.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring starts with Spring Framework (IoC container), Spring Boot (auto-
> configures everything), and domain projects like Spring Data (database
> access), Spring Security (auth), and Spring Cloud (microservices). When
> you create a Spring Boot project, you add starters for whichever domain
> projects you need and Boot wires them together automatically.

*Push deeper:* Mention spring.io/projects as the reference for all active
Spring projects and their lifecycle status (active, maintenance, EOL).

---

**Senior / Staff (5+ years):**
> The Spring ecosystem is a layered DI platform. Spring Framework provides
> the container; Spring Boot provides the auto-configuration layer; Spring
> Data, Security, Cloud etc. provide domain auto-configurations on top. The
> integration point is always BeanDefinitions - each project contributes
> beans to the shared context. The operational key is the Spring Boot
> Conditions Report (/actuator/conditions or --debug flag) which shows
> exactly which auto-configurations fired and why. At scale, the challenge
> is auto-configuration conflicts and startup time - Spring Boot 3's AOT
> compilation generates bean definitions at build time, reducing reflection
> and enabling GraalVM native image.

*Push deeper:* The trend in Kubernetes environments is toward dropping
Spring Cloud service discovery (Eureka) in favour of native Kubernetes
DNS. Spring Cloud's remaining value is circuit breaker (Resilience4j),
distributed tracing, and centralized config for non-Kubernetes deployments.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring = Spring Boot."**
Spring Framework (the IoC container) is separate from Spring Boot (the
auto-configuration layer). You can use Spring Framework without Boot - just
with more manual configuration. Boot is an opinionated starter; Framework
is the engine.

**Misconception 2: "Spring Cloud is required for microservices."**
Spring Cloud adds value for microservice cross-cutting concerns. But
Kubernetes provides service discovery and config maps natively. Many teams
deploy Spring Boot microservices to Kubernetes without Spring Cloud at all,
using the platform's native capabilities instead.

**Misconception 3: "Spring Data replaces knowing SQL."**
Spring Data's repository abstractions eliminate boilerplate. But generated
queries from method names can produce inefficient SQL. Senior engineers read
the actual SQL (spring.jpa.show-sql=true) and use @Query for complex cases.
Spring Data makes simple cases trivial; complex data access still requires
SQL knowledge.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Auto-configuration activating unexpectedly**
Symptom: A bean or feature is active that you did not configure.
Cause: A transitive dependency brought a Spring Boot starter that auto-
configures something.
Diagnosis: Run with --debug flag or check /actuator/conditions endpoint.
Fix: Add spring.autoconfigure.exclude=X.class in properties, or
@SpringBootTest(excludeAutoConfiguration = {X.class}) in tests.

**Failure 2: Spring Cloud vs Kubernetes service discovery conflict**
Symptom: Services registered in Eureka but Kubernetes DNS also resolves
service names, causing split-brain routing.
Fix: Choose one: disable Spring Cloud discovery (spring.cloud.discovery.
enabled=false) when running in Kubernetes.

**Failure 3: Spring Data N+1 query problem**
Symptom: Fetching a list of 100 Orders generates 101 SQL queries (one for
list, one per Order for its related entity).
Cause: @OneToMany with LAZY loading, accessing the lazy collection outside
a transaction.
Diagnosis: Enable SQL logging, count queries per request.
Fix: Use fetch joins in @Query, or @EntityGraph on the repository method.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

**[JUNIOR] Q1 - [BEHAVIORAL] Name the main Spring projects and what each does.**

Core four every Spring developer needs:
- Spring Framework: IoC container, AOP, MVC, WebFlux, JDBC template
- Spring Boot: auto-configuration, embedded servers, starter POMs, Actuator
- Spring Security: authentication, authorization, OAuth2, CSRF, CORS
- Spring Data: repository abstraction over JPA, MongoDB, Redis, Elasticsearch

Important for microservices:
- Spring Cloud: config server, service discovery, circuit breakers, API gateway
- Spring Batch: bulk data processing with jobs, steps, readers/writers
- Spring Integration: enterprise integration patterns (message channels,
  adapters, transformers)

*What separates good from great:* Mention the spring.io/projects lifecycle
column - active vs maintenance vs community. Spring Cloud Netflix (Eureka,
Ribbon, Hystrix) is in maintenance mode; prefer Spring Cloud LoadBalancer
and Resilience4j circuit breaker.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is a Spring Boot starter and how does it work?**

A starter is a POM dependency that:
1. Pulls in the transitive dependencies needed for a feature
2. Provides auto-configuration classes that activate when those dependencies
   are on the classpath

Example: spring-boot-starter-web pulls in Spring MVC, Tomcat, Jackson, and
Hibernate Validator. The associated auto-configuration activates a
DispatcherServlet, ObjectMapper bean, and default error handling.

Under the hood: auto-configurations are listed in
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
(Spring Boot 2.7+). Boot reads this file and registers those as @Configuration
candidates at startup.

*What separates good from great:* Creating a custom starter involves the same
pattern: create a module with your auto-configuration class, register it in the
imports file, and add appropriate @Conditional annotations.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What does /actuator provide?**

Spring Boot Actuator exposes production-ready operational endpoints:
- /actuator/health: liveness and readiness probes (used by Kubernetes)
- /actuator/metrics: application metrics (integrates with Micrometer)
- /actuator/conditions: which auto-configurations fired and why
- /actuator/env: resolved property values (secure this endpoint)
- /actuator/beans: all Spring beans in context
- /actuator/mappings: all @RequestMapping routes
- /actuator/threaddump: current thread state

Security best practice: expose only /health and /info publicly; require
authentication for all others.

*What separates good from great:* /actuator/health has health indicators
contributed by each auto-configured component (DataSource, Redis, Kafka).
Custom health indicators let you add domain-specific checks. Kubernetes
uses /actuator/health/liveness vs /actuator/health/readiness for distinct
probe types.

---

**[MID] Q4 - [CONCEPTUAL] How does Spring Data simplify data access?**

Spring Data provides repository interfaces with generated implementations.
You declare the interface and method names; Spring Data generates JPQL/SQL
at startup. Example: findByNameContainingIgnoreCase("spring") generates a
LIKE query automatically.

Spring Data generates a proxy implementing the interface - no boilerplate
DAO required. Key abstractions: CrudRepository (basic CRUD), JpaRepository
(adds pagination, flush, batch operations).

*What separates good from great:* Spring Data projections - you declare a
result interface with only the columns you need, and Spring Data generates
SELECT with only those columns. Crucial for performance when you only need
2 columns out of 20.

---

**[MID] Q5 - [CONCEPTUAL] What is Spring Cloud and when do you need it?**

Spring Cloud provides microservice cross-cutting concerns not in Spring Boot:
- Config Server: centralized configuration management
- Eureka: service registration and discovery
- Spring Cloud Gateway: API gateway with routing and rate limiting
- Circuit Breaker (Resilience4j): prevent cascade failures
- Distributed tracing: Micrometer Tracing + Zipkin/Tempo

When you need it: multiple Spring Boot microservices needing to discover each
other and handle partial failures - when NOT running in Kubernetes.

When you do NOT need it: in Kubernetes, which provides service discovery (DNS),
config management (ConfigMaps/Secrets). Many teams use only Spring Boot on
Kubernetes and skip Spring Cloud for discovery/config entirely.

*What separates good from great:* Spring Cloud's main remaining value in
Kubernetes is circuit breaker (Resilience4j) and distributed tracing - not
service discovery or config management which Kubernetes handles natively.

---

**[MID] Q6 - [ARCHITECTURE] How does Spring Security integrate with the ecosystem?**

Spring Security integrates at the MVC/WebFlux layer via a filter chain
(servlet filters for MVC, WebFilter for WebFlux). Every incoming request
passes through the security filter chain before reaching controllers.

Auto-configuration (activated by spring-boot-starter-security) sets up basic
auth, CSRF protection, session management, and a form login page by default.
You override by defining a SecurityFilterChain @Bean.

Integration with other Spring projects:
- Spring Session: replaces HttpSession with distributed session store (Redis)
  without code changes
- Spring OAuth2: client, resource server, and authorization server support
- Spring Data: @PreAuthorize can reference Spring Data predicates

*What separates good from great:* Spring Security's method-level security
(@PreAuthorize) uses Spring EL evaluated by a SpEL-based aspect. This is
why method security does not work on @Bean methods in @Configuration classes -
proxies are not applied there.

---

**[SENIOR] Q7 - [CONCEPTUAL] What changed in Spring Boot 3 / Spring Framework 6?**

Spring Boot 3 (November 2022) - key changes:
1. Java 17 minimum required.
2. Migrated from javax.* to jakarta.* package names (Jakarta EE 10).
   Any code using javax.servlet.*, javax.persistence.* must be updated.
3. Hibernate 6 required (also migrated to Jakarta).
4. GraalVM native image support via Spring AOT (ahead-of-time compilation).
5. Observability improvements: Micrometer Tracing replaces Sleuth.
6. Virtual threads (Project Loom) support via Spring MVC thread-per-request
   model with virtual threads (Spring Boot 3.2+).

Practical migration impact: package rename is the biggest breaking change.
Third-party libraries must support Jakarta EE 10 to work with Boot 3.

*What separates good from great:* The jakarta.* migration means Spring and
Jakarta EE now share the same package namespace, making interop and future
migration between Spring and Jakarta EE easier. Spring Boot 3's AOT
compilation generates bean definitions at build time, reducing startup
reflection and enabling smaller native images.

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



