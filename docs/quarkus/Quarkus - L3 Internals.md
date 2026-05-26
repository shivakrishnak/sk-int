---
layout: default
title: "Quarkus - L3 Internals"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 5
permalink: /quarkus/l3-internals/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus ArC CDI Container Internals](#quarkus-arc-cdi-container-internals) | hard |
| 2 | [Quarkus Build-Time DI Internals](#quarkus-build-time-di-internals) | hard |
| 3 | [Quarkus Continuous Testing](#quarkus-continuous-testing) | medium |
| 4 | [Quarkus Native Build Process](#quarkus-native-build-process) | hard |
| 5 | [Quarkus Extension Development](#quarkus-extension-development) | hard |

---

# Quarkus ArC CDI Container Internals

**Interview Weight:** hard - ArC internals separate
Staff from Senior candidates. Tested for deep Quarkus
understanding.

---

### 🎯 Model Answer

**30 seconds:**

> ArC (Augmented Runtime Container) is Quarkus's CDI
> implementation. Unlike Weld (reference CDI), ArC
> processes bean discovery, injection point validation,
> and proxy generation at build time. No classpath
> scanning at startup. No reflection for injection.
> ArC generates Java source code for each CDI component
> (bean, proxy, interceptor chain) during the Quarkus
> augmentation phase and compiles it into the final JAR.

**3 minutes (Senior):**

> ArC build phases:
>
> 1. Bean Discovery:
>   ArC scans annotated classes at build time.
>   Finds: @ApplicationScoped, @Singleton, @RequestScoped,
>     @Produces, @Inject, @Interceptor, @Decorator.
>   Validates: no unsatisfied injection points,
>     no ambiguous beans without qualifiers.
>   Fails FAST: missing bean = build error, not NPE at runtime.
>
> 2. Code Generation:
>   For each bean: generates [BeanName]_Bean.java.
>     Contains: contextual instance creation,
>     injection point resolution, scope management.
>   For each proxy: generates [BeanName]_ClientProxy.java.
>     Subclass with scope-aware method delegation.
>   For each interceptor chain: generates
>     [BeanName]_Subclass.java.
>     Chain: @Transactional, @Logged, @Retry.
>
> 3. Startup (runtime):
>   Arc.container(): load pre-generated metadata.
>   No scanning. No reflection. Pure generated code.
>   Startup time: microseconds for DI init.
>
> Unused bean removal:
>   ArC detects and removes beans never referenced.
>   Arc.container().beans(): list discovered beans.
>   @Unremovable: prevent removal of specific beans.
>   quarkus.arc.remove-unused-beans=false: disable globally.
>
> Circular dependency detection:
>   Build-time: ArC detects circular dependencies.
>   Runtime circular deps (via method injection): prevented.
>   Build error before deployment.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus CDI
works internally - the ArC build-time processing."

**(2) First principles:** "DI framework needs: discover
beans, validate, create, inject. ArC does first three
at build time, last at runtime."

**(3) Bridge:** "ArC is to Spring's DI what a compiler
is to an interpreter: does the work upfront (build time)
rather than at runtime."

---

### 💻 Code Example

```java
// What ArC generates (simplified)

// For: @ApplicationScoped class OrderService
// ArC generates: OrderService_Bean.java

// ArC-generated bean descriptor (simplified):
public final class OrderService_Bean
        extends InjectableBean<OrderService> {

    // References to injected beans (resolved at build time)
    private final InjectableBean<OrderRepository> repo;
    private final InjectableBean<NotificationService> notif;

    // Constructor injection resolution at build time
    public OrderService_Bean(
            InjectableBean<OrderRepository> repo,
            InjectableBean<NotificationService> notif) {
        this.repo = repo;
        this.notif = notif;
    }

    @Override
    public OrderService create(CreationalContext<OrderService> ctx) {
        OrderService instance = new OrderService();
        // Inject: no reflection, direct field assignment
        instance.repository = repo.get(ctx);
        instance.notificationService = notif.get(ctx);
        return instance;
    }

    @Override
    public Class<OrderService> getBeanClass() {
        return OrderService.class;
    }
}

// For: @ApplicationScoped (proxy needed)
// ArC generates: OrderService_ClientProxy.java

public final class OrderService_ClientProxy
        extends OrderService {

    @Override
    public Order createOrder(CreateOrderRequest req) {
        // Get the contextual instance (lazy, scoped)
        return Arc.container()
            .instance(OrderService.class)
            .get()
            .createOrder(req);
        // One virtual dispatch - no reflection
    }
}

// Interceptor chain for @Transactional
// ArC generates: OrderService_Subclass.java

public final class OrderService_Subclass
        extends OrderService {

    @Override
    @Transactional
    public Order createOrder(CreateOrderRequest req) {
        // ArC wraps with TransactionInterceptor
        InvocationContext ctx = new InvocationContextImpl(
            this, "createOrder",
            new Object[]{req},
            List.of(transactionInterceptor));
        return (Order) ctx.proceed();
    }
}
```

```java
// Debugging ArC: find registered beans
@ApplicationScoped
public class ArcInspector {

    public void inspectBeans() {
        // List all registered beans at runtime
        Arc.container().beanManager()
            .getBeans(Object.class)
            .stream()
            .forEach(bean ->
                log.info("Bean: {} scope: {}",
                    bean.getBeanClass().getSimpleName(),
                    bean.getScope().getSimpleName()));
    }
}

// Prevent ArC from removing a bean
@ApplicationScoped
@Unremovable  // Even if no @Inject references it
public class StartupCacheWarmer {

    void onStart(@Observes StartupEvent ev) {
        // Warms caches at startup
        // ArC would remove this if no one injects it
        // @Unremovable keeps it
    }
}

// Suppress build-time warning for producer
@Singleton
public class LegacyProducer {

    @Produces
    @SuppressWarnings("deprecation")
    @Deprecated
    LegacyService legacyService() {
        return new LegacyService();
    }
}
```

> **Code walkthrough:** ArC generates three classes per
> @ApplicationScoped bean: _Bean (contextual creation),
> _ClientProxy (scope-aware proxy), and _Subclass (interceptor
> chain if any interceptors apply). There is no reflection
> in the generated code - all injection points are resolved
> to direct field assignments. The proxy overrides each
> public method to delegate through the CDI container,
> enabling scope management and lazy initialization.

---

### ⚠️ Common Misconceptions

1. "ArC is Weld with build-time optimization."
   False: ArC is a from-scratch CDI implementation
   for Quarkus. Weld is not used. ArC is intentionally
   not full CDI (no XML configuration, no dynamic beans).

2. "All CDI features work in ArC."
   False: ArC does not support decorators fully, limited
   XML configuration, no dynamic bean registration.
   Intentional: simpler ArC = faster build and startup.

---

### 🎓 Answers by Seniority

**Senior:** "ArC discovers beans at build time, generates
Java source for each, compiles it in. Runtime startup:
zero classpath scanning. Injection errors are build
errors, not runtime NPEs. @Unremovable for beans only
observed by events - ArC considers them unused otherwise."

**Staff:** "ArC's code generation model means native
image compatibility is natural: generated code has no
reflection. Build-time bean validation means immediate
feedback on missing beans. The trade-off: ArC's subset
of CDI catches 99% of use cases, but some advanced
CDI features (decorators, dynamic registration) require
workarounds."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | ArC build phases, generated code, @Unremovable |
| Staff | 12 min | Code generation details, native image alignment, CDI subset |

---

**[STAFF] Q1 - Why does ArC fail faster than Weld
for DI errors?**

*Why they ask:* Understanding the operational benefits
of build-time DI.

Weld (Spring, Jakarta EE) validates injection at startup.
ArC validates at build time.

Timeline comparison:

With Weld/Spring:
1. Developer writes OrderService with missing @Inject
2. Builds JAR (no error)
3. Deploys to K8s (no error)
4. Pod starts, fails with:
   UnsatisfiedResolutionException: No bean found
5. Developer debugs at runtime
6. Fix, rebuild, redeploy
7. Total time: 20 minutes

With ArC:
1. Developer writes OrderService with missing @Inject
2. Runs `quarkus build`
3. Build fails immediately:
   Unsatisfied dependency for type PaymentService
   in: OrderService#paymentService
4. Developer fixes in editor
5. Total time: 10 seconds

Additional build-time validation:
- Ambiguous beans: two implementations, no qualifier
- Circular dependencies
- Invalid interceptor application
- Missing @Produces for complex types

This is why Quarkus startup is ~500ms vs Spring's ~5s:
no injection validation at startup.

*What separates good from great:* Build-time validation
as developer productivity feature, not just performance.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | ArC build phases, code generation, @Unremovable. |
| Hiring Manager | Faster development feedback with build-time validation. |
| Bar Raiser | Generated code details, CDI subset trade-offs. |
| Peer Engineer | "ArC caught a missing bean in our pipeline that would have been a 2am prod incident. Build error. Fixed in 30s." |

---

---

# Quarkus Build-Time DI Internals

**Interview Weight:** hard - Deep internals. Tested
for Staff/Architect candidates building Quarkus extensions.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus build-time DI works through the augmentation
> pipeline: BuildStep processors analyze the classpath
> at build time and generate bytecode or Java sources.
> For CDI (ArC), the BuildStep produces BeanInfo,
> InjectionPointInfo, and generates ClientProxy/Bean
> subclasses. The DeploymentClassLoader loads both
> application classes and deployment processor classes.
> The output: a pre-computed DI graph compiled into
> the application JAR.

**3 minutes (Senior):**

> Build augmentation pipeline:
>
> Phase 1: Bytecode scanning
>   IndexView: Jandex index of all classes.
>   Classes annotated with CDI annotations discovered.
>   AnnotationStore: cross-reference annotations.
>
> Phase 2: Bean registration
>   BeanRegistrationPhase: collect all bean candidates.
>   BeanProcessor.registerBeans(): produce BeanInfo.
>   BeanInfo: class, scope, qualifiers, interceptors.
>
> Phase 3: Validation
>   BeanDeploymentValidator: validate all injection points.
>   Check: all @Inject points have a matching bean.
>   Check: no ambiguous beans.
>   BuildException on failure (build error, not runtime).
>
> Phase 4: Code generation
>   GeneratedBeanBuildItem: trigger Java source generation.
>   BeanGenerator: generates [Bean]_Bean.java.
>   ClientProxyGenerator: generates [Bean]_ClientProxy.java.
>   SubclassGenerator: generates [Bean]_Subclass.java
>     (for intercepted beans).
>
> Phase 5: Compilation
>   Generated sources compiled with application code.
>   Output: fat JAR with all generated code.
>
> Quarkus Extension model:
>   Each extension has Deployment artifacts.
>   Extension BuildSteps: called during augmentation.
>   E.g., HibernateOrmProcessor: scans @Entity classes,
>     generates JPA metamodel, configures Hibernate.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus
processes CDI beans at build time."

**(2) First principles:** "Quarkus moves runtime work
to build time. Build-time = annotation scanning, validation,
code generation."

**(3) Bridge:** "Augmentation is like an ahead-of-time
compiler for the entire application framework layer."

---

### 💻 Code Example

```java
// Writing a Quarkus Extension BuildStep
// (Extension development, not application code)

@BuildSteps  // All @BuildStep methods in this class
public class MyExtensionProcessor {

    @BuildStep
    @Record(ExecutionTime.RUNTIME_INIT)
    public void registerBeans(
            BuildProducer<AdditionalBeanBuildItem>
                additionalBeans,
            MyExtensionConfig config,
            MyExtensionRecorder recorder) {

        // Tell ArC about beans defined in the extension
        additionalBeans.produce(
            AdditionalBeanBuildItem.builder()
                .addBeanClass(MyService.class)
                .setDefaultScope(
                    DotName.createSimple(
                        ApplicationScoped.class
                            .getName()))
                .setUnremovable()
                .build());

        // Register runtime initialization code
        recorder.configure(config.maxConnections());
    }

    @BuildStep
    public void validateConfig(
            MyExtensionConfig config,
            BuildProducer<ValidationErrorBuildItem>
                errors) {
        // Fail build if config is invalid
        if (config.maxConnections() < 1) {
            errors.produce(
                new ValidationErrorBuildItem(
                    new ConfigurationException(
                        "max-connections must be >= 1")));
        }
    }

    @BuildStep
    public NativeImageResourceBuildItem
            nativeResources() {
        // Tell GraalVM to include resource files
        return new NativeImageResourceBuildItem(
            "config/defaults.json");
    }
}

// @Recorder: bridge between build and runtime
@Recorder
public class MyExtensionRecorder {

    public void configure(int maxConnections) {
        // This runs at RUNTIME_INIT (application start)
        // Called with the recorded build-time data
        MyExtensionConfig.MAX_CONNECTIONS =
            maxConnections;
    }
}

// Build-time DI in application: use quarkus.arc.*
// application.properties:
// quarkus.arc.auto-inject-fields=false
//   Requires constructor injection only.
// quarkus.arc.remove-unused-beans=true (default)
//   ArC removes beans nobody injects.
// quarkus.arc.detect-wrong-annotations=true
//   Detect Spring @Component used instead of CDI.
```

> **Code walkthrough:** @BuildStep methods are called
> during augmentation - they have access to the classpath
> and can produce BuildItems that other processors consume.
> AdditionalBeanBuildItem tells ArC to register a bean
> that isn't annotated in the application (extension-provided).
> @Record with ExecutionTime.RUNTIME_INIT records a method
> call to execute at startup - the recorder method runs
> after augmentation when the application starts. This
> is how extension configuration flows from build time
> to runtime.

---

### 🎓 Answers by Seniority

**Senior:** "The augmentation pipeline: scan with Jandex,
register beans, validate injection points, generate code.
Build errors for validation failures - not runtime NPEs.
Extensions contribute BuildSteps to this pipeline."

**Staff:** "The @BuildStep/@Recorder pattern is clever:
the Recorder object captures method calls at build time,
serializes them as bytecode (using Gizmo bytecode library),
and executes them at startup. This allows extension authors
to run startup initialization that 'sees' both build-time
config and runtime config - bridging the two phases."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Augmentation phases, @BuildStep, @Recorder pattern |

---

**[STAFF] Q1 - How does the @Recorder bridge the
gap between build time and runtime in Quarkus?**

*Why they ask:* Core Quarkus extension mechanism.

The problem: at build time, we know config (e.g., pool size = 10).
At runtime, we need to initialize infrastructure (create
the pool with size 10).

The @Recorder solution:
1. Build time: call recorder.initialize(10).
2. Gizmo (bytecode library) serializes this call as
   bytecode into GeneratedInitializerBuildItem.
3. Runtime: the generated bytecode runs recorder.initialize(10).

Why not just run the code at build time?
Resource initialization at build time would be embedded
in the binary:
- Database connections at build time = impossible in CI
- Static final fields would be frozen in native image

The @Recorder bridges by:
- Recording the INTENTION at build time
- Executing the intention at runtime

For native image: RecordableRecorder captures all calls
as serialized objects, replayed during native image startup.

This is what "ahead-of-time" means in Quarkus: not just
native compilation, but pre-computed DI graph + recorded
initialization chain.

*What separates good from great:* The @Recorder as
a deferred execution bridge, not just a configuration holder.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Augmentation pipeline, code generation. |
| Hiring Manager | Extension model enables rich ecosystem. |
| Bar Raiser | @BuildStep, @Recorder, Gizmo, augmentation phases. |
| Peer Engineer | "Wrote an extension with a @BuildStep that scans for @MyAnnotation and @Recorder that registers handlers. 50 lines." |

---

---

# Quarkus Continuous Testing

**Interview Weight:** medium - Continuous Testing is
a developer productivity feature. Shows familiarity
with Quarkus developer experience.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Continuous Testing runs tests automatically
> when code changes in Dev Mode. Press 'r' in the Dev
> Mode terminal to run all tests, or tests run automatically
> on file change. Only changed tests and their dependencies
> are re-run (test impact analysis). Tests run in the
> same JVM as the application - no startup overhead.
> Test results shown in the terminal and Dev UI.

**3 minutes (Senior):**

> Continuous Testing features:
>
> Auto-run on change:
>   Source file saved → Quarkus recompiles.
>   Affected tests detected and run.
>   Results shown inline.
>
> Test impact analysis:
>   Quarkus tracks which source files each test covers.
>   Change OrderService.java:
>     Only OrderServiceTest and OrderIntegrationTest rerun.
>     Not PaymentServiceTest (unrelated).
>
> Keyboard controls (in Dev Mode terminal):
>   r: run all tests
>   e: toggle all test execution
>   b: toggle broken tests only
>   i: toggle test output
>
> @QuarkusTest:
>   Full application context.
>   Dev Services (PostgreSQL, Kafka, etc.) auto-started.
>   Injection works: @Inject in test classes.
>
> @QuarkusIntegrationTest:
>   Runs against running application.
>   Tests the JAR/native binary directly.
>
> @TestProfile:
>   Override config for a test or test class.
>   Different application profile per test.
>
> Mocking:
>   @InjectMock: inject Mockito mock into CDI context.
>   @QuarkusMock: replace a CDI bean with a mock.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus Continuous
Testing - the automatic test execution on code change."

**(2) First principles:** "Faster feedback on code changes
= faster development. Tests reveal breakage."

**(3) Bridge:** "Quarkus Continuous Testing is like
Jest's --watch mode for Java: run affected tests on save."

---

### 💻 Code Example

```java
// @QuarkusTest: full integration test
@QuarkusTest
class OrderServiceTest {

    @Inject
    OrderService orderService;

    @Inject
    OrderRepository orderRepo;

    @Test
    @TestTransaction  // Transaction rolled back after test
    void testCreateOrder() {
        CreateOrderRequest req =
            new CreateOrderRequest(
                1L, BigDecimal.TEN);

        Order created = orderService.create(req);

        assertNotNull(created.getId());
        assertEquals("PENDING", created.getStatus());
        // @TestTransaction rolls back - no cleanup needed
    }

    @Test
    void testListOrders_ReturnsCorrectStatus() {
        given()
            .when()
            .get("/api/v1/orders?status=PENDING")
            .then()
            .statusCode(200)
            .body("size()", greaterThan(0));
    }
}

// Mock a CDI bean in tests
@QuarkusTest
class OrderServiceMockedTest {

    @InjectMock  // Replaces the CDI bean with Mockito mock
    InventoryService inventoryService;

    @Inject
    OrderService orderService;

    @Test
    void testCreateOrder_WhenOutOfStock_Throws() {
        when(inventoryService.checkStock(anyLong()))
            .thenReturn(false);

        assertThrows(
            OutOfStockException.class,
            () -> orderService.create(
                new CreateOrderRequest(1L, BigDecimal.TEN)));
    }
}

// Test profile for specific config
public class IntegrationProfile
        implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
            "app.order.max-per-customer", "3",
            "app.notification.enabled", "false");
    }

    @Override
    public String getConfigProfile() {
        return "integration";
    }
}

@QuarkusTest
@TestProfile(IntegrationProfile.class)
class OrderLimitIntegrationTest {
    // Tests run with max-per-customer=3
    // and notification disabled
}

// @QuarkusIntegrationTest: test the final artifact
@QuarkusIntegrationTest
class OrderNativeIT {
    // Run after `quarkus build -Dquarkus.native.enabled=true`
    // Tests the native binary directly
    // No injection: HTTP requests only

    @Test
    void testHealthEndpoint() {
        given()
            .when()
            .get("/q/health")
            .then()
            .statusCode(200);
    }
}
```

> **Code walkthrough:** @QuarkusTest starts the full
> application with Dev Services (PostgreSQL auto-started).
> @TestTransaction rolls back after each test - no cleanup
> scripts needed. @InjectMock replaces the CDI bean in
> the running application context with a Mockito mock.
> @TestProfile overrides config properties for the test
> class scope. @QuarkusIntegrationTest runs against the
> compiled artifact (JAR or native) - used for the final
> acceptance test before deployment.

---

### 🎓 Answers by Seniority

**Junior:** "@QuarkusTest for integration tests with
full context. Dev Services auto-start the database.
@TestTransaction for automatic rollback."

**Senior:** "@InjectMock for service mocking. @TestProfile
for config-specific test scenarios. Continuous Testing
with test impact analysis: only affected tests rerun
on code change."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | @QuarkusTest, @InjectMock, @TestProfile |

---

**[SENIOR] Q1 - What is the difference between
@QuarkusTest and @QuarkusIntegrationTest?**

*Why they ask:* Understanding test pyramid.

@QuarkusTest:
- Starts Quarkus application in the same JVM as tests.
- Full CDI context: @Inject works in test classes.
- @InjectMock: replace beans with mocks.
- Dev Services: PostgreSQL/Kafka started as Testcontainers.
- Fast startup (no separate process).
- Used for: unit+integration tests during development.

@QuarkusIntegrationTest:
- Tests the compiled artifact (JAR, native binary).
- Separate process: starts the real built artifact.
- No CDI injection in tests.
- Tests via HTTP requests only.
- Tests the same binary that goes to production.
- Used for: final acceptance tests in CI before deploy.

The distinction matters for native image:
@QuarkusTest always runs on JVM. @QuarkusIntegrationTest
runs the native binary. So a test may pass @QuarkusTest
but fail @QuarkusIntegrationTest if the native image
has reflection issues.

```bash
# Run @QuarkusTest (JVM, development)
./mvnw test

# Run @QuarkusIntegrationTest (native binary)
./mvnw verify -Dquarkus.native.enabled=true \
  -Dnative.surefire.skip=false
```

*What separates good from great:* @QuarkusIntegrationTest
catches native image issues that @QuarkusTest misses.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @QuarkusTest features, continuous testing. |
| Hiring Manager | Fast test feedback loop. |
| Bar Raiser | @QuarkusIntegrationTest, native image testing, test impact analysis. |
| Peer Engineer | "@QuarkusIntegrationTest caught a reflection issue in native. Saved us from a prod incident." |

---

---

# Quarkus Native Build Process

**Interview Weight:** hard - Native builds are a core
Quarkus differentiator. Tested for understanding and
troubleshooting native build failures.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus native image builds use GraalVM's native-image
> tool. The build has two phases: Quarkus augmentation
> (build-time processing, generates reflection config,
> resource config) and GraalVM native-image compilation
> (ahead-of-time compilation to machine code). Enable
> with quarkus.native.enabled=true or -Pnative Maven profile.
> The output: a self-contained native binary, ~100ms
> startup, ~50MB resident memory vs JVM's ~300MB.

**3 minutes (Senior):**

> Build process:
>
> 1. Quarkus Augmentation:
>   BuildStep processors run for all extensions.
>   HibernateOrmProcessor: generates JPA metamodel.
>   ResteasyProcessor: generates REST dispatch code.
>   Produces NativeImageReflectionBuildItem
>     (classes needing reflection at runtime).
>   Produces NativeImageResourceBuildItem
>     (resources to include in binary).
>
> 2. Configuration collection:
>   All NativeImage* build items aggregated.
>   reflect-config.json: reflection config.
>   resource-config.json: resources.
>   proxy-config.json: dynamic proxies.
>   serialization-config.json: serializable classes.
>
> 3. GraalVM native-image compilation:
>   Closed-world analysis: reachability from main().
>   Points-to analysis: which code is actually used.
>   Heap snapshotting: static initializers run at build.
>   Machine code generation: architecture-specific.
>   Output: ./target/app-runner (Linux) or .exe (Windows).
>
> Build time: 3-5 minutes (complex apps up to 10 min).
> Binary size: 50-100MB.
> Startup: 50-100ms.
> Memory: 30-60% less than JVM.
>
> Container build:
>   quarkus.native.container-build=true
>   Builds in a Docker container (UBI Linux).
>   Use when host OS ≠ deployment OS.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus native
image build - how to compile to a native binary."

**(2) First principles:** "Native image = no JVM at
runtime. All code compiled ahead-of-time to machine code."

**(3) Bridge:** "Quarkus native build is like Go's
build process: output a single self-contained binary,
no runtime dependencies."

---

### 💻 Code Example

```java
// Register class for reflection in native image
// Option 1: @RegisterForReflection on the class
@RegisterForReflection  // Include in reflect-config
public class OrderDto {
    // This class is created from JSON via reflection
    // (e.g., external library's ObjectMapper)
    private Long id;
    private String status;
}

// Option 2: @RegisterForReflection targets
@RegisterForReflection(targets = {
    ThirdPartyRequest.class,
    ThirdPartyResponse.class
})
// Applied to any class; targets registered, not the host
public class ThirdPartyIntegration {}

// Option 3: In extension BuildStep (automatic for users)
// Extension automatically registers its types
@BuildStep
public ReflectiveClassBuildItem reflectiveClasses() {
    return ReflectiveClassBuildItem
        .builder(MySerializableClass.class)
        .methods(true)
        .fields(true)
        .build();
}

// Include resources in native image
@BuildStep
public NativeImageResourceBuildItem resources() {
    return new NativeImageResourceBuildItem(
        "config/defaults.json",
        "templates/email.html");
}
```

```bash
# Build native image (requires GraalVM installed)
./mvnw package -Pnative

# Container build (builds inside Docker, for Linux target)
./mvnw package -Pnative \
  -Dquarkus.native.container-build=true

# Run native binary
./target/app-1.0-runner

# Check binary startup time
time ./target/app-1.0-runner &
# Started in 0.052s

# Check memory usage
ps aux | grep app-runner
# RSS ~50MB vs JVM ~300MB

# Build native container image
./mvnw package -Pnative \
  -Dquarkus.native.container-build=true \
  -Dquarkus.container-image.build=true
```

> **Code walkthrough:** @RegisterForReflection marks
> a class to be included in the native image's reflect-config.json.
> Without it, classes created reflectively at runtime
> fail with ClassNotFoundError in native image. Extension
> @BuildStep processors automatically register their
> classes. The container build flag (-Dquarkus.native.container-build=true)
> runs GraalVM inside a Docker container, producing a
> Linux binary suitable for Kubernetes deployment.

---

### 🚨 Failure Modes and Diagnosis

**Build failure: "Class not found" in reflect-config:**
```bash
# Symptom: native binary throws at runtime
# Error: Class com.example.Dto not found

# Fix: add @RegisterForReflection to the class
# Or add to BuildStep:
quarkus.native.additional-build-args=\
  -H:ReflectionConfigurationFiles=custom-reflect.json
```

**Build failure: "Static initializer uses runtime data":**
```java
// BAD: static field initialized with runtime data
static final DataSource ds = createDataSource();
// native-image runs this at build time -> fails

// GOOD: initialize lazily
private static DataSource ds;
static DataSource getDs() {
    if (ds == null) ds = createDataSource();
    return ds;
}
// Or defer with --initialize-at-run-time:
// -H:InitializeAtRunTime=com.example.LazyClass
```

---

### 🎓 Answers by Seniority

**Senior:** "Native build: augmentation + GraalVM native-image.
@RegisterForReflection for dynamic class access.
Container build for cross-platform (develop on Mac, deploy
on Linux). Build time ~5 minutes - use JVM mode during
development, native build in CI."

**Staff:** "Native image trade-offs: no JIT means peak
throughput is lower than JVM (10-20%). Benefits: startup,
memory. Perfect for Lambda/FaaS and sidecar containers.
For long-running high-throughput services: JVM with CDS
may be better."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Native build process, @RegisterForReflection, container build |
| Staff | 12 min | Build failures, closed-world constraint, JVM vs native trade-off |

---

**[SENIOR] Q1 - How do you diagnose a
ClassNotFoundException in a Quarkus native binary?**

*Why they ask:* Production native image debugging.

```bash
# Step 1: reproduce in JVM mode first
./mvnw package
java -jar target/app-runner.jar
# If this works: native-specific issue

# Step 2: look for @RegisterForReflection hint
# The stack trace usually shows the class name
# Search the codebase for where it's created
grep -r "Class.forName\|newInstance\|invoke"
# Find reflective access points

# Step 3: add explicit reflection config
@RegisterForReflection(targets = {
    MissingClass.class,
    MissingClass.InnerClass.class
})
public class ReflectionRegistration {}

# Step 4: use tracing agent for systematic discovery
java -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image \
  -jar target/app-runner.jar
# Run integration tests to exercise all code paths
# Generates reflect-config.json automatically

# Step 5: verify in native
./mvnw package -Pnative
./target/app-runner
```

Preventive: run @QuarkusIntegrationTest after every
native build in CI. Catches missing reflection config
before production.

*What separates good from great:* Tracing agent as
systematic approach, not guessing.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Native build, @RegisterForReflection. |
| Hiring Manager | Native image for performance. |
| Bar Raiser | Native build pipeline, ClassNotFoundException diagnosis, container build. |
| Peer Engineer | "Tracing agent found 23 missing classes in one run. Saved a week of trial-and-error." |

---

---

# Quarkus Extension Development

**Interview Weight:** hard - Extension development is
advanced. Tested for Staff candidates contributing
to internal frameworks.

---

### 🎯 Model Answer

**30 seconds:**

> A Quarkus extension has two modules: runtime (application
> code and APIs) and deployment (build-time processing,
> @BuildStep processors). The deployment module depends
> on the runtime module and Quarkus core deployment APIs.
> @BuildStep methods process the Jandex index, validate
> config, produce AdditionalBeans, generate code, and
> configure native image. The @Recorder bridges build
> time to runtime init.

**3 minutes (Senior):**

> Extension module structure:
>
> myextension-parent/
>   myextension/ (runtime module)
>     src/main/java/: CDI beans, APIs, services
>     META-INF/quarkus-extension.yaml: metadata
>   myextension-deployment/ (deployment module)
>     src/main/java/:
>       MyExtensionProcessor.java (@BuildSteps)
>       MyExtensionRecorder.java (@Recorder)
>
> Key BuildItem types:
>
> Produce:
>   AdditionalBeanBuildItem: register CDI beans
>   ReflectiveClassBuildItem: reflection config
>   NativeImageResourceBuildItem: include resources
>   GeneratedBeanBuildItem: generated source
>   GeneratedClassBuildItem: generated bytecode
>   ServiceStartBuildItem: ensure startup order
>
> Consume:
>   CombinedIndexBuildItem: Jandex index (all classes)
>   BeanArchiveIndexBuildItem: bean archive
>   ConfigurationBuildItem: validated config
>   ShutdownContextBuildItem: register shutdown hook
>
> @Recorder usage:
>   @Record(RUNTIME_INIT): runs at startup
>   @Record(STATIC_INIT): runs at static init (earlier)
>   @Record(BUILD_TIME): captured as bytecode, runs in image
>
> Dev UI integration:
>   Implement DevUIWebComponentsBuildItem.
>   Custom dashboard shown at http://localhost:8080/q/dev.
>   Show extension-specific status and actions.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about building a Quarkus
extension - adding custom build-time processing to Quarkus."

**(2) First principles:** "Extension = contribute to
augmentation pipeline. Runtime code + build-time code."

**(3) Bridge:** "Quarkus extension is like a Spring
Boot AutoConfiguration but with build-time code that
processes annotations and generates optimized code."

---

### 💻 Code Example

```java
// Extension deployment module:
// src/main/java/.../deployment/MyExtensionProcessor.java

@BuildSteps
public class MyAuditExtensionProcessor {

    // Step 1: scan for @Audited annotations
    @BuildStep
    public void discoverAuditedBeans(
            CombinedIndexBuildItem combinedIndex,
            BuildProducer<AuditedBeanBuildItem>
                auditedBeans) {

        // Scan Jandex index for @Audited methods
        combinedIndex.getIndex()
            .getAnnotations(DotName.createSimple(
                Audited.class.getName()))
            .forEach(annotation -> {
                MethodInfo method =
                    (MethodInfo) annotation.target();
                auditedBeans.produce(
                    new AuditedBeanBuildItem(
                        method.declaringClass().name(),
                        method.name()));
            });
    }

    // Step 2: generate audit interceptor
    @BuildStep
    @Record(ExecutionTime.RUNTIME_INIT)
    public void registerAuditInterceptor(
            List<AuditedBeanBuildItem> auditedBeans,
            MyAuditRecorder recorder,
            BuildProducer<AdditionalBeanBuildItem>
                additionalBeans) {

        // Register the audit service bean
        additionalBeans.produce(
            AdditionalBeanBuildItem.builder()
                .addBeanClass(AuditService.class)
                .setDefaultScope(DotName.createSimple(
                    ApplicationScoped.class.getName()))
                .setUnremovable()
                .build());

        // Record method registry for runtime
        List<String> methodKeys = auditedBeans.stream()
            .map(b -> b.getClassName() + "#"
                + b.getMethodName())
            .collect(Collectors.toList());

        recorder.registerAuditedMethods(methodKeys);
    }

    // Step 3: validate
    @BuildStep
    public void validate(
            List<AuditedBeanBuildItem> auditedBeans,
            BuildProducer<ValidationErrorBuildItem>
                errors) {
        auditedBeans.forEach(b -> {
            // Validate: @Audited only on CDI beans
            // (check if declaring class is a CDI bean)
        });
    }
}

// Custom BuildItem: data carrier between @BuildSteps
public final class AuditedBeanBuildItem
        extends MultiBuildItem {

    private final String className;
    private final String methodName;

    public AuditedBeanBuildItem(
            String className, String methodName) {
        this.className = className;
        this.methodName = methodName;
    }

    // getters...
}

// @Recorder in runtime module
@Recorder
public class MyAuditRecorder {
    public void registerAuditedMethods(
            List<String> methods) {
        // Runs at RUNTIME_INIT
        AuditRegistry.INSTANCE.register(methods);
    }
}
```

> **Code walkthrough:** @BuildSteps marks a class whose
> methods are @BuildStep processors. discoverAuditedBeans
> scans the Jandex index for @Audited annotations and
> produces AuditedBeanBuildItems (custom BuildItem carrying
> data). registerAuditInterceptor consumes those items,
> registers the AuditService CDI bean, and records the
> method list for runtime via @Recorder. The @Record
> annotation specifies WHEN the recorder method runs:
> RUNTIME_INIT means at application startup.

---

### 🎓 Answers by Seniority

**Staff:** "Extension = runtime module (user-facing API)
+ deployment module (@BuildStep processors). The deployment
module contributes to augmentation: scan annotations,
produce BuildItems, generate code, configure native image.
@Recorder bridges build-time data to runtime initialization."

**Principal:** "Extensions enable zero-overhead abstractions:
all the framework magic happens at build time. Users
pay zero runtime cost for extension features - the
generated code is as if they wrote it by hand. This
is the fundamental Quarkus design principle."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Extension structure, @BuildStep, @Recorder |
| Principal | 15 min | Custom BuildItems, Gizmo code generation, Dev UI |

---

**[STAFF] Q1 - How do you test a Quarkus extension
BuildStep in isolation?**

*Why they ask:* Extension quality assurance.

Quarkus provides QuarkusUnitTest for extension testing:

```java
// Extension deployment test
class MyAuditExtensionTest {

    @RegisterExtension
    static final QuarkusUnitTest config =
        new QuarkusUnitTest()
            .setArchiveProducer(() ->
                ShrinkWrap.create(JavaArchive.class)
                    .addClasses(
                        AuditedOrderService.class,
                        // Test application using extension
                        OrderService.class))
            .withConfigurationResource(
                "application.properties");

    @Inject
    AuditService auditService;

    @Inject
    AuditedOrderService orderService;

    @Test
    void testAuditInterceptorApplied() {
        orderService.createOrder(
            new CreateOrderRequest(...));

        List<AuditEntry> entries =
            auditService.getEntries();
        assertThat(entries).hasSize(1);
        assertThat(entries.get(0).getMethod())
            .isEqualTo("createOrder");
    }
}

// Test build failure scenario
@RegisterExtension
static final QuarkusUnitTest shouldFail =
    new QuarkusUnitTest()
        .setExpectedException(
            BuildException.class)
        .setArchiveProducer(() ->
            ShrinkWrap.create(JavaArchive.class)
                .addClasses(InvalidUsageClass.class));
```

QuarkusUnitTest creates a mini-application with just
the specified classes and verifies the extension behavior
(or expected build failure).

*What separates good from great:* Testing expected build
failures is as important as testing successful builds.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Extension structure, @BuildStep, @Recorder. |
| Hiring Manager | Internal framework extensions. |
| Bar Raiser | Custom BuildItems, QuarkusUnitTest, build failure testing. |
| Peer Engineer | "Built an @Audited extension. QuarkusUnitTest caught a missing BuildItem dependency before it hit CI." |
