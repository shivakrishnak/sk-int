---
layout: default
title: "Micronaut - L6 Theory"
parent: "Micronaut"
nav_order: 9
permalink: /micronaut/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Compile-Time DI and AOT Processing Theory](#compile-time-di-and-aot-processing-theory) | critical |
| 2 | [Reactive Streams Specification](#reactive-streams-specification) | high |

---

# Compile-Time DI and AOT Processing Theory

**Interview Weight:** critical - The theoretical
underpinning of Micronaut. Staff/principal-level
question. Tests deep understanding of why compile-time
matters beyond just "it's faster."

---

### 🎯 Model Answer

**30 seconds:**

> Compile-time DI implements the Inversion of Control
> principle without runtime reflection by using Java
> Annotation Processing (JSR 269) to generate concrete
> BeanDefinition classes during javac execution. The
> generated code encodes the dependency graph as Java
> bytecode - a static structure known at build time.
> AOT (Ahead-of-Time) processing is the general pattern:
> move computation from runtime to build time to reduce
> startup cost and enable native compilation.

**3 minutes (Staff):**

> The theoretical basis:
>
> JSR 269 (Pluggable Annotation Processing API):
>   Annotation processors are compiler plugins.
>   Called by javac before bytecode generation.
>   Read source elements (TypeElement, MethodElement).
>   Emit new source files, which are then compiled.
>   Round processing: each round may produce new
>   source elements for the next round.
>
> The Dependency Injection problem:
>   Traditional DI (Spring) defers to runtime:
>   "I don't know what to inject until the app starts."
>   Uses reflection: Class.forName(), getAnnotation(),
>   getDeclaredConstructors().
>   Cost: startup scanning + ClassLoader + proxy creation.
>
>   Compile-time DI (Micronaut) states:
>   "The bean graph is deterministic from the source."
>   Annotation processor computes the graph at build time.
>   Emits a BeanDefinition per bean: a class that
>   constructs the bean and resolves its dependencies
>   via direct code (no reflection).
>
> AOT in the JVM ecosystem:
>   Micronaut (2018): DI and HTTP routing AOT.
>   Spring AOT (Spring Boot 3): similar approach added
>     to Spring to support GraalVM native image.
>   Quarkus (2019): build-time augmentation (CDI AOT).
>   All converging on the same insight:
>     "Runtime reflection is the enemy of native images."
>
> Closed-world assumption:
>   AOT requires all types to be known at build time.
>   No dynamic class loading after compilation.
>   This is the trade-off: flexibility vs speed.
>   Plugin architectures (load JARs at runtime): impossible
>   without reflection configuration.
>
> GraalVM SubstrateVM:
>   Runs AOT-compiled Java as native code.
>   No JIT compiler at runtime.
>   No classpath: all needed classes compiled in.
>   Static analysis determines reachable code.
>   Points-to analysis: which types are reachable?
>   Everything not reachable = excluded (smaller binary).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the theory behind
compile-time DI - why it works and what it enables."

**(2) First principles:** "Computation at build time is
cheaper than computation at runtime, because build time
is paid once; runtime cost is paid per request."

**(3) Bridge:** "Compile-time DI is like a restaurant
that preps all ingredients before service. Runtime
DI is like a restaurant that preps ingredients when
each order arrives. Both produce the same dish, but
the compile-time prep doesn't delay the customer."

---

### 💻 Code Example

```java
// Annotation Processor: generates BeanDefinition
// Simplified BeanDefinitionInjectProcessor

@SupportedAnnotationTypes({
    "io.micronaut.context.annotation.Singleton",
    "jakarta.inject.Singleton"
})
public class BeanDefinitionInjectProcessor
        extends AbstractProcessor {

    @Override
    public boolean process(
            Set<? extends TypeElement> annotations,
            RoundEnvironment roundEnv) {

        // For each @Singleton class
        for (TypeElement annotation : annotations) {
            Set<? extends Element> elements =
                roundEnv.getElementsAnnotatedWith(
                    annotation);

            for (Element element : elements) {
                TypeElement classElement =
                    (TypeElement) element;
                // Generate BeanDefinition source
                generateBeanDefinition(classElement);
            }
        }
        return true;
    }

    private void generateBeanDefinition(
            TypeElement classElement) {

        // Determine constructor to use
        ExecutableElement constructor =
            findInjectableConstructor(classElement);

        // Build source code for the definition
        JavaFileObject fileObject =
            processingEnv.getFiler()
                .createSourceFile(
                    classElement.getSimpleName()
                    + "$Definition");

        // Write generated class:
        // - Constructor metadata
        // - build() method with new ClassName(...)
        // - Lifecycle methods (@PostConstruct ref)
        // - Scope annotation
        writeDefinitionClass(
            fileObject, classElement, constructor);
    }
}

// The generated class (what actually runs at startup)
// OrderService$Definition.java
public final class OrderService$Definition
        extends AbstractInitializableBeanDefinition<
            OrderService> {

    // Metadata computed at compile time
    private static final Argument<?>[] CONSTRUCTOR_ARGS
        = new Argument[] {
            Argument.of(
                OrderRepository.class,
                "repository")
        };

    @Override
    protected OrderService doBuild(
            BeanResolutionContext ctx,
            BeanContext context,
            BeanDefinition<OrderService> def) {

        // Direct Java call - no reflection
        return new OrderService(
            (OrderRepository) super
                .getBeanForConstructorArgument(
                    ctx, context, 0, null)
        );
        // getBeanForConstructorArgument resolves
        // OrderRepository from the BeanContext
        // using pre-computed type info (no reflection)
    }
}
```

> **Code walkthrough:** The BeanDefinitionInjectProcessorice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> is a JSR 269 annotation processor that runs inside
> javac. For each @Singleton class, it generates a
> $Definition class. The generated class stores the
> constructor argument types as Argument<?> metadata
> (not String class names). doBuild() calls the
> constructor directly - a compiled Java call in the
> generated bytecode. No Class.forName(), no
> getDeclaredConstructors(), no newInstance() anywhere
> in the critical path.

---

### 📘 Concept Explanation

**What it is:**

Compile-Time DI and Ahead-of-Time (AOT) Processing is the
theoretical framework explaining why moving work from runtime
to compile time provides structural advantages for cloud-
native applications.

**The core insight:**

Runtime processing (reflection, classpath scanning, dynamic
proxy generation) trades CPU time at application startup
for developer convenience (no explicit registration). For
long-running monoliths, this is a good trade: you pay the
cost once at startup. For cloud-native services with
many restarts, scaling events, and Lambda cold starts, the
startup cost is paid FREQUENTLY. AOT pre-pays this cost
at build time.

**AOT processing spectrum:**
```
Runtime end                              Compile-time end
Reflection → Spring Boot → Micronaut/Quarkus → GraalVM native
```

> **Diagram walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Each step rightward: faster startup, lower memory, less
flexibility, more explicit configuration.

**Theoretical model (CWA - Closed World Assumption):**

AOT compilation requires knowing ALL types at compile time.
GraalVM native extends this: ALL reachable code must be
traceable statically. Reflection breaks CWA because the
class loaded by name at runtime is unknown at compile time.
Micronaut avoids reflection in its own framework code but
cannot prevent application code from using it.

**Why it matters:**

Understanding CWA explains why some patterns (reflection,
dynamic proxies, runtime bytecode generation) are incompatible
with native image, while others (static dispatch, final
classes, fixed type hierarchies) are optimal for AOT.

---

### 🎓 Answers by Seniority

**Staff:** "JSR 269 annotation processing is the
mechanism. The generated BeanDefinition contains
the dependency graph as compiled Java code. This is
why GraalVM SubstrateVM can analyze the code
statically - there's no reflective call to hide
the type dependencies. Spring's AOT mode (Spring Boot 3+)
adds the same approach retroactively to maintain
GraalVM compatibility."

**Principal:** "The theoretical insight is that DI
is a compile-time concern for 95% of applications.
Micronaut treats the 5% dynamic cases (plugin systems,
dynamic bean registration) as advanced/opt-in.
Spring treats the 5% dynamic cases as the default,
paying the reflection cost for every application.
Both approaches are correct for their design philosophy."

---

### ⚠️ Common Misconceptions

**Misconception 1: AOT processing is a new idea
invented by Micronaut or Quarkus.**

AOT compilation has existed since the 1990s. GCJ (GNU Compiler
for Java) compiled Java to native in 2001. Android uses
ART (Android Runtime) with AOT since Android 5. .NET has
had AOT compilation for Xamarin and later all .NET platforms.
Micronaut and Quarkus are APPLYING AOT principles specifically
to server-side Java microservices - the innovation is in
making it practical and developer-friendly within the Java
ecosystem, not in the concept itself.

**Misconception 2: Compile-time processing eliminates
the need for runtime configuration.**

AOT processes STRUCTURE (which beans exist, how they wire).
It cannot process VALUES (database URLs, feature flag states,
external API endpoints). Runtime configuration is still
needed and is first-class in both Micronaut and Quarkus.
The compile-time/runtime boundary is: structure at compile
time, values at runtime. This is analogous to compiled
programs: the code is fixed at compile time, but accepts
different inputs at runtime.

**Misconception 3: AOT frameworks are harder to debug
than reflection-based frameworks.**

AOT frameworks generate explicit code that is actually
EASIER to debug in some ways: the generated `BeanDefinition`
files are readable Java/Kotlin code showing exactly how
beans are constructed and wired. With reflection-based
Spring, bean wiring is opaque at runtime. However, AOT
frameworks have COMPILE-TIME errors that can be complex
(APT errors pointing to generated code) rather than
runtime errors with more obvious stack traces.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: AOT violation pattern: generic class
instantiation via reflection breaks after framework upgrade.**

Symptom: application works on Micronaut 3.x but fails on
4.x with `ClassCastException` or `ClassNotFoundException`
for generic type parameters. Root cause: AOT frameworks
occasionally tighten CWA enforcement between versions;
code that relied on reflection or dynamic type instantiation
that happened to work in one version fails when the analysis
is stricter. Diagnosis: read the migration guide for the
upgraded version; look for deprecation warnings related to
reflection use. Fix: replace reflection with explicit type
registration; use `@Introspected` for classes requiring
runtime introspection.

**Failure Mode 2: Build time doubles after adding a new
module because APT processes the entire transitive closure.**

Symptom: adding a module with many annotated classes
significantly increases build time for all dependent modules.
Root cause: AOT annotation processing compiles ALL annotated
classes in scope; adding a large module extends the APT scope.
Diagnosis: profile with `./gradlew compileJava --profile`;
identify which APT processor is slow. Fix: separate large
shared modules into feature modules with explicit exports;
use Gradle modular builds with strict API visibility.

**Failure Mode 3: Annotation processor generates
incorrect code due to compiler incremental compilation bug.**

Symptom: application behaves incorrectly after a partial
recompile; full clean build works but incremental build
produces wrong behavior. Root cause: incremental compilation
left stale generated files from before a refactoring; new
source and old generated files are inconsistent. Diagnosis:
reproducible only after incremental build; clean build fixes
it. Fix: run `./gradlew clean build` to clear the incremental
state; report to the APT implementation issue tracker;
as a workaround, add `./gradlew clean` to CI before each build.

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
|---|----------|---------------------------------------------------------------|
| Staff| 10 min| JSR 269, BeanDefinition structure, AOT theory|
| Principal| 15 min| GraalVM points-to analysis, closed-world, ecosystem converg

---

**[PRINCIPAL] Q1 - Why are Spring, Quarkus, and
Micronaut all converging on AOT compilation?**

*Why they ask:* Ecosystem-level thinking.

The convergence is driven by two forces:

Force 1: GraalVM native image adoption.
Cloud providers (AWS Lambda, Google Cloud Run) charge
for startup time and memory. Native image reduces
both by 5-10x. Frameworks that don't support native
image lose adoption in serverless contexts.

Force 2: Kubernetes density optimization.
500MB JVM per pod vs 50MB native per pod = 10x more
pods per node = 10x better hardware utilization.

Spring's response (Spring Boot 3.0, 2022):
Spring AOT: a build-time processing step that generates
BeanDefinition sources before compilation. Less complete
than Micronaut's approach (Spring still supports
full runtime reflection) but sufficient for GraalVM.

Quarkus's response (2019):
Build-time CDI augmentation. CDI beans analyzed at
build time. Extension model for framework integrations.
Similar philosophy to Micronaut.

The difference:
- Micronaut: AOT-first (designed from the start)
- Quarkus: AOT-first (designed from the start)
- Spring: runtime-first + AOT bolted on

Implication: Spring AOT works for ~80% of Spring apps.
The remaining 20% (dynamic bean registration, CGLIB
proxies, complex SpEL) require configuration.
Micronaut and Quarkus: 95%+ of apps work without
AOT configuration.

*What separates good from great:* Understanding the
market forces (Lambda pricing, Kubernetes density)
that drove the AOT convergence.

| Interviewer Type| Emphasis|
|----------------|------------------------------------------------------------|
| Technical Panel| JSR 269 mechanics, BeanDefinition structure.|
| Hiring Manager| Theory that explains Micronaut's startup advantage.|
| Bar Raiser| Closed-world assumption, GraalVM points-to, AOT convergence.|
| Principal| Ecosystem forces, Spring AOT vs native-first frameworks.|

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


# Reactive Streams Specification

**Interview Weight:** high - Reactive programming
theory is required for senior/staff-level Micronaut
interviews, especially for non-blocking service design.

---

### 🎯 Model Answer

**30 seconds:**

> The Reactive Streams specification (JDK 9 Flow API)
> defines four interfaces: Publisher, Subscriber,
> Subscription, and Processor. The key contract:
> Subscriber signals demand via Subscription.request(n).
> Publisher only emits up to n items. This is backpressure:
> the consumer controls the rate. Project Reactor (Mono/Flux)
> and RxJava implement this specification. Micronaut
> supports both. The spec exists to allow interoperability
> between reactive libraries.

**3 minutes (Staff):**

> Reactive Streams interfaces:
>
> Publisher<T>:
>   subscribe(Subscriber<T>): attaches subscriber.
>   Emits items to subscriber when demanded.
>
> Subscriber<T>:
>   onSubscribe(Subscription s): called after subscribe.
>     MUST call s.request(n) to receive items.
>   onNext(T item): item delivered.
>   onError(Throwable): terminal, no more items.
>   onComplete(): terminal, no more items.
>
> Subscription:
>   request(long n): demand n more items.
>   cancel(): cancel subscription.
>
> Processor<T,R>: both Publisher and Subscriber.
>   Transforms a stream (map, filter, flatMap).
>
> Backpressure contract:
>   Publisher MUST NOT emit more items than requested.
>   Subscriber controls the flow rate.
>   Without backpressure: publisher overwhelms subscriber
>     (buffer overflow, OOM).
>
> Reactive Streams in JDK 9:
>   java.util.concurrent.Flow: same 4 interfaces.
>   Naming: Flow.Publisher, Flow.Subscriber, etc.
>
> Implementation interoperability:
>   Reactor → RxJava: Flux.from(flowable)
>   RxJava → Reactor: Mono.fromPublisher(single)
>   Any Publisher<T> is interoperable via the spec.
>
> Cold vs hot publishers:
>   Cold: starts emitting when subscribed.
>     Mono.just(), Flux.fromIterable()
>     Each subscriber gets all items.
>   Hot: emits regardless of subscribers.
>     Kafka topic, WebSocket, stock price feed.
>     Late subscribers miss past items.
>   Micronaut HTTP: cold publisher per request.
>   Micronaut Kafka consumer: hot publisher.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the theory of
reactive streams - the specification behind Mono and Flux."

**(2) First principles:** "Data flow = producer sends,
consumer receives. Problem: producer faster than consumer.
Solution: consumer controls the rate (backpressure)."

**(3) Bridge:** "Reactive Streams is the interface
contract. Reactor and RxJava are implementations.
Like JDBC is the interface; PostgreSQL driver is the
implementation."

---

### 💻 Code Example

```java
// Manual Reactive Streams implementation
// (Educational: understand the spec contract)
public class NumberPublisher
        implements Publisher<Integer> {

    private final int count;

    NumberPublisher(int count) {
        this.count = count;
    }

    @Override
    public void subscribe(
            Subscriber<? super Integer> subscriber) {
        // Create subscription and hand to subscriber
        subscriber.onSubscribe(
            new NumberSubscription(
                subscriber, count));
    }
}

class NumberSubscription
        implements Subscription {

    private final Subscriber<? super Integer>
        subscriber;
    private final int max;
    private int current = 0;
    private volatile boolean cancelled = false;

    NumberSubscription(
            Subscriber<? super Integer> subscriber,
            int max) {
        this.subscriber = subscriber;
        this.max = max;
    }

    @Override
    public void request(long n) {
        if (cancelled) return;

        // Emit up to n items (or until done)
        long emit = Math.min(n, max - current);
        for (int i = 0; i < emit; i++) {
            if (cancelled) return;
            subscriber.onNext(current++);
        }
        if (current >= max) {
            subscriber.onComplete();
        }
    }

    @Override
    public void cancel() {
        cancelled = true;
    }
}

// How Flux uses the spec internally:
Flux<Integer> numbers = Flux.fromIterable(
    List.of(1, 2, 3, 4, 5));

// Subscription with demand control:
numbers
    .onBackpressureBuffer(10)  // Buffer if consumer slow
    .subscribe(
        item -> {
            // Consumer controls: processes one at a time
            processItem(item);
        },
        error -> log.error("Error", error),
        () -> log.info("Complete")
    );

// flatMap: concurrent subscription (unbounded by default)
Flux.range(1, 100)
    .flatMap(id ->
        // Each flatMap creates a new subscription
        orderService.findById(id)
            .subscribeOn(Schedulers.boundedElastic()),
        10  // concurrency = 10 at a time (backpressure)
    )
    .subscribe(System.out::println);
```

> **Code walkthrough:** NumberPublisher implements theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Reactive Streams contract precisely: onSubscribe() hands
> a Subscription to the Subscriber. The Subscription.request(n)
> method controls how many items to emit - the consumer
> drives the pace. The Flux.flatMap(concurrency=10) example
> shows how Reactor implements downstream backpressure:
> only 10 inner streams active concurrently, preventing
> the outer stream from overwhelming the inner.

---

### 📘 Concept Explanation

**What it is:**

Reactive Streams is a JVM standard specification (JSR-166,
JDK 9+ `java.util.concurrent.Flow`) for asynchronous stream
processing with non-blocking backpressure. It defines the
contracts that reactive libraries (Project Reactor, RxJava)
implement and that Micronaut's reactive HTTP integrations use.

**How it works:**

Four interfaces:
1. `Publisher<T>`: source of data; emits items to Subscribers
2. `Subscriber<T>`: consumes data; requests items via Subscription
3. `Subscription`: represents the link between Publisher and Subscriber;
   `request(n)` applies backpressure (request n items)
4. `Processor<T,R>`: both Publisher and Subscriber (transform)

Backpressure mechanism: the Subscriber calls `subscription.request(n)`,
signaling it can handle `n` more items. The Publisher emits
AT MOST `n` items. If the Subscriber processes items slowly,
it requests fewer, slowing the Publisher. This prevents
memory overflow from overwhelmed consumers.

In practice: developers use higher-level libraries:
- Project Reactor: `Mono<T>` (0 or 1 item), `Flux<T>` (0-N items)
- RxJava 3: `Single<T>`, `Observable<T>`, `Flowable<T>`
Both implement Reactive Streams and are interoperable.

**Why it matters:**

Reactive Streams enables non-blocking I/O without manual
callback hell. The specification ensures library
interoperability - Micronaut can accept either Reactor or
RxJava types in controller return types.

---

### 🎓 Answers by Seniority

**Staff:** "The key insight of Reactive Streams: the
subscriber signals demand (pull model) rather than the
publisher pushing. This prevents the publisher from
overwhelming the subscriber. Cold publishers (database
queries) create new resources per subscription.
Hot publishers (Kafka topics) share a single source.
Understanding this distinction prevents bugs when
subscribing to a cold publisher multiple times."

**Principal:** "The Reactive Streams spec was a
collaborative effort (Netflix, Pivotal, Twitter, etc.)
to establish interoperability between reactive libraries.
JDK 9 incorporated the spec as java.util.concurrent.Flow.
The practical impact: Micronaut can accept a Reactor
Mono from a service and pass it to an RxJava subscriber
without conversion because both implement the same spec."

---

### ⚠️ Common Misconceptions

**Misconception 1: Reactive programming is always
faster than synchronous programming.**

Reactive programming enables CONCURRENCY without threads.
This is faster under high I/O-bound concurrency. For CPU-
bound operations (data processing, computation), reactive
adds scheduling overhead without concurrency benefit. For
single-request latency on a lightly loaded system,
synchronous blocking code is simpler and equally fast.
Reactive shines when: thousands of concurrent I/O-bound
requests, streaming large datasets, or composing multiple
async operations in parallel.

**Misconception 2: RxJava and Project Reactor are
interchangeable because both implement Reactive Streams.**

Both implement the Reactive Streams spec at the `Publisher`
interface level, enabling interoperability. But their APIs,
semantics, and performance characteristics differ. Project
Reactor is used natively in Spring WebFlux and Micronaut;
it is optimized for the Spring/Micronaut ecosystem. RxJava
has richer operator sets from its Android history. Mixing
them in one project adds dependency weight. Choose one and
use the conversion operators (`Flux.from(rxObservable)`)
only when bridging third-party APIs.

**Misconception 3: Backpressure is handled automatically
and developers need not think about it.**

Libraries like Project Reactor implement backpressure at
the API level, but application code must be designed to
PARTICIPATE in backpressure. Code that buffers
(`bufferUntil`, `collect`) can override backpressure and
cause memory issues. Operators that ignore demand (`create()`
with `BUFFER` overflow strategy) accumulate items. Database
result streaming (`Flux<Row>`) applies backpressure to the
DB cursor only if the reactive pipeline respects demand.
Understand which operators propagate vs break backpressure.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Hot observable receives no items
because subscriber subscribes too late.**

Symptom: subscriber misses events because they were published
before subscription was established. Root cause: hot observables
(EventBus, WebSocket streams, system event sources) emit
items regardless of subscriber presence. Subscribers joining
late miss prior items. Diagnosis: check if the publisher
is hot (emitting before subscribe) or cold (emitting only
on subscribe). Fix: use `replay()` or `cache()` operators
to replay recent items to late subscribers; use cold
observables (created per subscription) for on-demand data.

**Failure Mode 2: Reactive pipeline silently drops items
due to missing error handling operator.**

Symptom: some items appear missing from processing without
any error log. Root cause: an operator in the pipeline emits
an error; without `onErrorContinue` or `onErrorResume`,
the entire stream terminates. Items after the error are
never processed. Diagnosis: add `.doOnError(log::error)` to
the pipeline to make errors visible. Fix: add explicit error
handling: `.onErrorResume(e -> Mono.empty())` to skip errors,
`.onErrorReturn(defaultValue)` for fallback, or
`.retry(3)` for transient errors.

**Failure Mode 3: flatMap concurrency unbounded causes
OOM due to too many parallel subscriptions.**

Symptom: memory usage spikes when processing a large stream
through `flatMap`; heap exhausted by in-flight subscriptions.
Root cause: `Flux.flatMap(item -> processAsync(item))`
subscribes to ALL inner publishers concurrently (unbounded
default). For 10,000 items, 10,000 parallel subscriptions
exist simultaneously. Diagnosis: heap dump shows thousands
of `Mono` objects. Fix: limit concurrency: `flatMap(item ->
processAsync(item), 10)` to process at most 10 items
concurrently; use `concatMap` for sequential processing;
use `flatMapSequential` for ordered parallel processing.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Reactive Streams interfaces, backpressure, cold vs hot |
| Principal | 15 min | Spec history, interoperability, demand model theory |

---

**[STAFF] Q1 - What is the difference between cold
and hot publishers and when does it matter in Micronaut?**

*Why they ask:* Subtle reactive programming concept
with real bugs when misunderstood.

Cold publisher: starts execution when subscribed.
Each subscriber gets a fresh sequence.
```java
Mono<Order> orderMono = orderRepo.findById(1L);
// No DB query yet

orderMono.subscribe(o -> log.info("Subscriber1: {}",o));
// DB query executed

orderMono.subscribe(o -> log.info("Subscriber2: {}",o));
// SECOND DB query executed (new subscription = new query)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Bug: a Mono that represents an HTTP request.
If subscribed twice: two HTTP calls made.

Hot publisher: emits regardless of subscribers.
Late subscribers miss past events.
```java
// Kafka Flux is hot
Flux<Message> kafkaMessages = ...; // Started receiving

// Late subscriber
Flux.defer(() -> kafkaMessages)
    .subscribe(m -> process(m));
// Misses messages that arrived before subscribe
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Rule of thumb:
- Repository methods: cold (safe to subscribe once)
- Kafka/RabbitMQ/WebSocket: hot (manage replay separately)
- @Get controller return: cold (one sub per request)

Defense: avoid subscribing to the same Mono/Flux twice.
Use .cache() to share a single subscription:
```java
Mono<Order> cached = orderRepo.findById(1L).cache();
// One DB query, result shared to all subscribers
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Identifying the
double-subscription bug and .cache() as the fix.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Reactive Streams interfaces, backpressure contract. |
| Hiring Manager | Reactive theory enables non-blocking scalable services. |
| Bar Raiser | Cold vs hot, double-subscription bug, .cache() fix, JDK Flow API. |
| Principal | Spec design rationale, interoperability between libraries. |

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



