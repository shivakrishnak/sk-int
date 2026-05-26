# Spring Boot Native Image Integration

**Interview Weight:** hard - Spring Boot 3 native support
is a major ecosystem shift. Heavily tested in Senior/Staff interviews.

---

### 🎯 Model Answer

**30 seconds:**

> Spring Boot 3 added first-class GraalVM native image
> support. Key mechanism: AOT (Ahead-of-Time) processing
> at build time via spring-aot-maven-plugin. Spring AOT
> replaces runtime classpath scanning, proxy generation,
> and reflection-based injection with build-time generated
> code. Trade-offs: some Spring features don't work in
> native (legacy CGLIB proxies, certain reflective features),
> and build time is 5-10 minutes vs seconds for JVM.

**3 minutes (Senior):**

> Spring Native architecture:
>
> Spring Boot 3 AOT engine:
>   Runs at build time (Maven/Gradle plugin).
>   Generates: BeanDefinitionRegistrar (explicit bean code).
>   Generates: reflect-config.json (reflection hints).
>   Generates: proxy-config.json (JDK proxy declarations).
>   Result: native-image uses generated code, not classpath scan.
>
> AOT vs JVM Spring behavior:
>   JVM: classpath scan at startup, CGLIB proxies at runtime.
>   AOT: scan at build time, JDK proxies, explicit bean registry.
>
> Native hints system:
>   @NativeHint: custom reflection/resource/proxy registration.
>   RuntimeHintsRegistrar: programmatic hint registration.
>   @ImportRuntimeHints: attach registrar to configuration.
>
> What works in Spring Native:
>   @SpringBootApplication, @Service, @Repository.
>   @Transactional (JDK proxy based).
>   Spring Data JPA (with explicit entity registration).
>   Spring Security.
>   Spring MVC + WebFlux.
>
> What requires extra work:
>   @ConditionalOn*: evaluated at build time only.
>   @Scope("prototype"): mostly works, some edge cases.
>   Legacy CGLIB proxies: require interface-based design.
>   Custom ClassLoader subclasses: not supported.
>
> Build command:
>   ./mvnw spring-boot:build-image (Buildpacks + Paketo)
>   ./mvnw native:compile (direct native binary)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Spring Boot
integrates with GraalVM for native image."

**(2) First principles:** "Spring AOT: shift runtime work
to build time. GraalVM: compile the result."

**(3) Bridge:** "Spring AOT is to Spring as Quarkus augmentation
is to Quarkus: build-time processing to avoid runtime scanning."

---

### 💻 Code Example

```java
// Spring Boot 3 Native: what changes

// 1. pom.xml: add native profile
// <profiles>
//   <profile>
//     <id>native</id>
//     <build>
//       <plugins>
//         <plugin>
//           <groupId>org.graalvm.buildtools</groupId>
//           <artifactId>native-maven-plugin</artifactId>
//           <executions>
//             <execution>
//               <goals><goal>compile-no-fork</goal></goals>
//               <phase>package</phase>
//             </execution>
//           </executions>
//         </plugin>
//       </plugins>
//     </build>
//   </profile>
// </profiles>

// 2. Build native image
// ./mvnw native:compile -Pnative

// 3. Handle CGLIB limitation
// BAD: concrete class with @Transactional (CGLIB)
@Service
@Transactional
public class OrderService {
    // Spring needs CGLIB proxy → not native-compatible
    // (without further config)
}

// GOOD: interface-based (JDK proxy, native-compatible)
public interface OrderServicePort {
    Order createOrder(CreateOrderRequest req);
}

@Service
@Transactional
public class OrderService
        implements OrderServicePort {
    @Override
    public Order createOrder(
            CreateOrderRequest req) { ... }
}

// 4. Register custom reflection needs
@Configuration
@ImportRuntimeHints(OrderHints.class)
public class NativeConfig {}

public class OrderHints
        implements RuntimeHintsRegistrar {

    @Override
    public void registerHints(
            RuntimeHints hints,
            ClassLoader classLoader) {

        // Register DTO classes for reflection
        hints.reflection()
            .registerType(OrderDto.class,
                MemberCategory.INVOKE_DECLARED_METHODS,
                MemberCategory.DECLARED_FIELDS);

        hints.reflection()
            .registerType(PaymentDto.class,
                MemberCategory.INVOKE_DECLARED_METHODS,
                MemberCategory.DECLARED_FIELDS);

        // Register resource patterns
        hints.resources()
            .registerPattern("templates/*.mustache");
    }
}

// 5. Spring Data JPA in native
// Most entities: auto-registered by Spring Data
// Custom queries with reflection: register manually

// @Query with constructor expressions:
@Query("""
    SELECT new com.example.OrderSummary(
        o.id, o.status, o.total)
    FROM Order o WHERE o.status = :status
    """)
List<OrderSummary> findSummariesByStatus(
    @Param("status") String status);

// OrderSummary needs reflection:
@RegisterReflectionForBinding(OrderSummary.class)
// Spring Boot annotation → automatic registration
```

> **Code walkthrough:** The interface-based OrderService
> is required for Spring native: JDK proxies work, CGLIB
> does not. The RuntimeHintsRegistrar is the programmatic
> alternative to @RegisterForReflection - it integrates
> with Spring's AOT processing. The @RegisterReflectionForBinding
> annotation is a Spring shorthand for DTO types used
> in constructor expressions.

---

### 🎓 Answers by Seniority

**Senior:** "Spring Boot 3 AOT: build-time classpath scan,
JDK proxies (not CGLIB). Add native-maven-plugin, use
interfaces, register custom reflection via RuntimeHintsRegistrar.
Build time: 8-12 min. Startup: 100-300ms (slower than Quarkus
due to less Spring-specific heap pre-init)."

**Staff:** "Spring Native vs Quarkus native: Quarkus was
designed for native from the start (build-time augmentation).
Spring AOT is retrofitted - it works but with caveats.
Startup: Quarkus native ~50ms, Spring native ~150-300ms.
For greenfield: Quarkus native. For existing Spring: Spring native."

---

### ⚖️ Comparison Table

| Aspect | Quarkus Native | Spring Native (Boot 3) | Micronaut Native |
|---|---|---|---|
| Startup time | 50-100ms | 150-300ms | 100-200ms |
| Memory (RSS) | 50-80MB | 100-150MB | 70-100MB |
| Build time | 4-8 min | 8-15 min | 5-10 min |
| CGLIB support | N/A (ArC) | No (use JDK proxy) | N/A (compile-time) |
| Native-first design | Yes | Retrofitted (Boot 3) | Yes |
| Spring ecosystem | No | Yes | No |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | AOT engine, RuntimeHints, limitations |
| Staff | 12 min | Spring vs Quarkus native, migration strategy |

---

**[STAFF] Q1 - When would you choose Spring
Native over Quarkus for a new project?**

*Why they ask:* Architecture decision with ecosystem trade-offs.

Choose Spring Native when:
- Existing Spring expertise: team knows Spring deeply.
- Spring ecosystem integration: Spring Cloud, Spring Security OAuth.
- Spring Data repositories: extensive and mature.
- Organizational standard: "everything is Spring here."
- Not on the critical startup path: 300ms is acceptable.

Choose Quarkus native when:
- Performance-critical: startup <100ms required.
- New project: no legacy Spring investment.
- Kubernetes-native: designed for it.
- Extension ecosystem: many Quarkus extensions are native-first.
- Team willing to learn Quarkus CDI.

Decision anti-pattern: choosing Quarkus only for
native image when the team knows Spring deeply.
Result: productivity loss from unfamiliar framework.
Better: Spring Native, accept 2-3x slower startup.

Hybrid strategy:
- New services: Quarkus (native, fast).
- Migrated services: Spring Native (existing code).
- Legacy services: JVM Spring (no migration cost).

*What separates good from great:* "Native image framework
choice depends on team expertise as much as performance."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Spring AOT, RuntimeHints, CGLIB. |
| Hiring Manager | Spring Native adoption decision. |
| Bar Raiser | Spring vs Quarkus native trade-offs. |
| Staff | "We chose Spring Native: existing team of 20 Spring engineers. Startup 200ms. Acceptable. Saved 2 months relearning Quarkus." |

---

---

# Native Image JDBC and Database Drivers

**Interview Weight:** hard - JDBC in native image has
specific requirements. Common production failure point.

---

### 🎯 Model Answer

**30 seconds:**

> JDBC in native image requires explicit configuration:
> JDBC drivers use Class.forName() for loading and ServiceLoader
> for discovery. PostgreSQL, MySQL, and H2 drivers have
> native image support via their own reflect-config files.
> Quarkus and Micronaut extensions handle most JDBC driver
> registration automatically. Issues: SQL dialect files
> (Hibernate), JDBC driver class reflection, and native
> TLS (for SSL connections) require explicit configuration.

**3 minutes (Senior):**

> JDBC driver native image requirements:
>
> 1. Driver class registration:
>    JDBC 4.0: auto-discovery via META-INF/services/java.sql.Driver.
>    META-INF: ServiceLoader, analyzed at build time.
>    Result: modern drivers work without Class.forName.
>
>    Legacy: Class.forName("com.mysql.cj.jdbc.Driver").
>    Fix: @RegisterForReflection(targets=Driver.class).
>
> 2. SQL type classes:
>    Some drivers: internal type classes accessed via reflection.
>    Example: org.postgresql.util.PGobject.
>    Fix: driver's native-image configuration (included in JAR).
>
> 3. TLS support:
>    Database connections over SSL: need SSL provider.
>    Native image: BouncyCastle or JDK SSL provider.
>    Quarkus: built-in SSL support flag.
>    Flag: quarkus.native.enable-https-url-handler=true.
>
> 4. Hibernate SQL dialect files:
>    Hibernate: loads dialect SQL fragments at runtime.
>    File: org/hibernate/dialect/PostgreSQL10Dialect.sql.
>    Must declare in resources.includes.
>    Quarkus Hibernate extension: handles automatically.
>
> 5. Connection pool:
>    Agroal (Quarkus default): native-compatible.
>    HikariCP: native-compatible (5.x+).
>    c3p0, DBCP: test before using.
>
> Driver native image support status:
>   PostgreSQL: full support (native-image metadata in JAR).
>   MySQL: full support (8.x+).
>   MariaDB: full support.
>   Oracle: partial (test each version).
>   H2: full support.
>   SQLite: full support (embedded).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to use JDBC
database connections in GraalVM native image."

**(2) First principles:** "JDBC driver = Java class. Native image
= explicit registration. Driver files = resource inclusion."

**(3) Bridge:** "JDBC native: same rules as any Java library.
Modern drivers include their own native-image config."

---

### 💻 Code Example

```java
// PostgreSQL driver in Quarkus native
// application.properties:
// quarkus.datasource.db-kind=postgresql
// quarkus.datasource.jdbc.url=jdbc:postgresql://db:5432/orders
// quarkus.datasource.username=${DB_USER}
// quarkus.datasource.password=${DB_PASSWORD}

// Quarkus Agroal + PostgreSQL: works out of the box
// Quarkus extension handles:
// - PostgreSQL driver registration
// - Agroal pool configuration
// - Connection SSL (if configured)

// SSL connections
// application.properties:
// quarkus.datasource.jdbc.url=\
//   jdbc:postgresql://db:5432/orders?ssl=true&\
//   sslmode=require&sslrootcert=/certs/ca.pem
// quarkus.native.enable-https-url-handler=true

// Hibernate ORM entities: auto-registered by Quarkus
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue
    private Long id;

    private String status;

    @Column(name = "total_amount")
    private BigDecimal total;
}
// Quarkus Hibernate extension: registers Order for reflection

// PROBLEM: HikariCP in non-Quarkus Spring app
// HikariCP uses reflection for some metrics classes
// Fix: register HikariCP metrics classes

// In RuntimeHintsRegistrar:
hints.reflection()
    .registerType(
        HikariDataSource.class,
        MemberCategory.INVOKE_PUBLIC_METHODS);

// Or: check HikariCP JAR for native-image config:
// HikariCP 5.x: includes META-INF/native-image/
//   com.zaxxer.hikari/native-image.properties

// PROBLEM: Custom TypeHandler (MyBatis)
// MyBatis uses reflection for TypeHandlers
@MappedTypes(OrderStatus.class)
public class OrderStatusTypeHandler
        extends BaseTypeHandler<OrderStatus> {
    // TypeHandler: needs reflection registration
}

// Fix: register all @MappedTypes classes
@RegisterForReflection(
    targets = OrderStatus.class
)
public class TypeHandlerConfig { }

// DIAGNOSIS: JDBC native failure
// Symptom: connection pool fails to create
//   java.lang.ClassNotFoundException: driver class

// Check: which driver class is used
// application.properties:
// quarkus.datasource.jdbc.driver=
//   org.postgresql.Driver  # Explicit class

// If explicit: ensure registered
@RegisterForReflection(
    targets = org.postgresql.Driver.class
)
public class JdbcConfig { }
```

> **Code walkthrough:** Quarkus Agroal + PostgreSQL works
> without manual reflection registration - the Quarkus
> extension handles everything. SSL connections need
> enable-https-url-handler=true: this includes the TLS
> support code in the native binary. The HikariCP and
> MyBatis examples show that third-party integrations
> may need manual registration even when the primary
> driver works.

---

### 🎓 Answers by Seniority

**Senior:** "Modern JDBC drivers (PostgreSQL, MySQL 8.x):
include their own native-image configurations in the JAR.
Quarkus extensions handle driver registration. Issues:
SSL (enable-https-url-handler=true) and custom TypeHandlers.
Always test: run a native integration test against real DB."

**Staff:** "Database connectivity in native image: 95% works
out of the box with Quarkus. The 5%: custom JDBC drivers,
old versions, non-standard connection factories. Strategy:
native CI test with Testcontainers, catch failures before
production."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Driver registration, SSL, Quarkus automatic |
| Staff | 9 min | TypeHandlers, diagnostics, CI strategy |

---

**[SENIOR] Q1 - How do you test JDBC
connectivity in native image CI?**

*Why they ask:* Practical CI/CD for native services.

Testcontainers + Quarkus native test:
```java
// @QuarkusIntegrationTest: runs against native binary
@QuarkusIntegrationTest
@QuarkusTestResource(
    PostgreSQLTestResource.class)
public class OrderRepositoryNativeTest {

    @Inject
    OrderRepository repo;

    @Test
    void testCreateAndFind() {
        Order order = new Order(
            "CREATED", BigDecimal.TEN);
        repo.persist(order);

        Order found = repo.findById(order.getId());
        assertNotNull(found);
        assertEquals("CREATED", found.getStatus());
    }
}

// Resource: starts PostgreSQL container
public class PostgreSQLTestResource
        implements QuarkusTestResourceLifecycleManager {

    static final PostgreSQLContainer<?> DB =
        new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("orders");

    @Override
    public Map<String, String> start() {
        DB.start();
        return Map.of(
            "quarkus.datasource.jdbc.url",
            DB.getJdbcUrl(),
            "quarkus.datasource.username",
            DB.getUsername(),
            "quarkus.datasource.password",
            DB.getPassword());
    }
    // ...
}
```

CI configuration:
```yaml
# .github/workflows/native-test.yml
- name: Build native binary
  run: ./mvnw package -Pnative
    -Dquarkus.native.container-build=true

- name: Run native integration tests
  run: ./mvnw verify -Pnative-test
  # Tests run against native binary with real PostgreSQL
```

*What separates good from great:* Native integration tests
catch reflection and resource issues before production.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | JDBC driver config, Quarkus auto-config. |
| Hiring Manager | JDBC native production readiness. |
| Bar Raiser | SSL, TypeHandlers, Testcontainers CI. |
| Peer Engineer | "Added native CI test with Testcontainers. Found 3 reflection issues. Fixed before merge. Zero native DB failures since." |

---

---

# Native Image Build Failures and Diagnostics

**Interview Weight:** hard - Build failure diagnosis
is practical Staff-level knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> Native image build failures fall into four categories:
> static analysis failures (missing configuration), heap
> initialization failures (static init side effects),
> compilation failures (unsupported bytecode), and linking
> failures (missing C libraries). The most common: class
> not found at runtime (missing reflection config) and
> initialization errors (static init network/file I/O).
> Diagnostic tools: --verbose build output, -H:+PrintAnalysisCallTree,
> and the native-image tracing agent.

**3 minutes (Senior):**

> Build failure taxonomy:
>
> Category 1: Missing reflection configuration (runtime):
>   Symptom: ClassNotFoundException, NoSuchMethodException,
>     InaccessibleObjectException at runtime.
>   Cause: class accessed via reflection, not registered.
>   Build: succeeds (analysis doesn't catch this).
>   Detection: only on first execution of the code path.
>   Fix: @RegisterForReflection or reflect-config.json.
>
> Category 2: Heap initialization failure (build time):
>   Symptom: Build fails with ExceptionInInitializerError.
>   Cause: static {} block has runtime side effects.
>   Build: fails in phase 7 (image creation).
>   Detection: immediately during build.
>   Fix: @InitializeAtRunTime or refactor to CDI.
>
> Category 3: Analysis failure:
>   Symptom: Build fails with "unsupported feature."
>   Cause: CGLIB, Java agents, illegal reflective access.
>   Build: fails in phase 2 (analysis).
>   Fix: migrate away from unsupported feature.
>
> Category 4: Linking failure:
>   Symptom: Build fails with "undefined reference."
>   Cause: missing C library (zlib, glibc).
>   Build: fails in phase 8 (linking).
>   Fix: install missing library or use static linking.
>
> Diagnostic workflow:
>   1. Read the error message: category, class, phase.
>   2. Category 1-2: use tracing agent to find config.
>   3. Category 3: find the unsupported feature, replace.
>   4. Category 4: install library, check build Docker image.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to diagnose
and fix native image build failures."

**(2) First principles:** "Four categories: reflection, init,
analysis, linking. Each has different symptoms and fixes."

**(3) Bridge:** "Native image failures follow a pattern:
the category determines the diagnostic approach."

---

### 💻 Code Example

```bash
# DIAGNOSIS WORKFLOW

# Step 1: Read the build error carefully
./mvnw package -Pnative 2>&1 | tail -50

# Common build-time error (Category 2):
# Error: An error occurred during the native image build.
# Caused by: com.oracle.graal.pointsto.util.
#   AnalysisError: Parsing error in:
#   com.example.Config.<clinit>(Config.java:15)
# Caused by: java.net.ConnectException: Connection refused
# → Static init tried to connect to network
# → Fix: --initialize-at-run-time=com.example.Config

# Step 2: For build failures (Category 2)
./mvnw package -Pnative \
  -Dquarkus.native.additional-build-args=\
  --initialize-at-run-time=com.example.Config

# Step 3: For runtime failures (Category 1)
# Run with tracing agent to find missing config
java -agentlib:native-image-agent=\
  config-output-dir=/tmp/native-configs \
  -jar target/app.jar

# Exercise the failing code path
curl http://localhost:8080/failing/endpoint

# Check generated config
cat /tmp/native-configs/reflect-config.json
# Add new entries to: src/main/resources/
#   META-INF/native-image/reflect-config.json

# Step 4: Analysis trace (find unexpected inclusions)
./mvnw package -Pnative \
  -Dquarkus.native.additional-build-args=\
  -H:+PrintAnalysisCallTree

# View call tree report
cat target/reports/call_tree_*.txt | \
  grep "com.example" | head -100

# Step 5: CGLIB detection (Category 3)
./mvnw package -Pnative 2>&1 | \
  grep -i "cglib\|proxy\|subclass"
# Output: Error: GraalVM does not support CGLIB proxies
# Fix: add interfaces to affected classes

# Step 6: Linking failure (Category 4)
./mvnw package -Pnative 2>&1 | \
  grep "undefined reference"
# Output: undefined reference to `z_stream'
# Fix: sudo apt-get install zlib1g-dev

# Verbose build output (all phases)
./mvnw package -Pnative \
  -Dquarkus.native.additional-build-args=--verbose
# Shows: each phase timing, what's happening
```

```java
// FIXING CATEGORY 1: Missing reflection

// 1. Find the failing class from runtime error:
// java.lang.reflect.InaccessibleObjectException:
//   Unable to make field
//   com.example.PaymentDto.amount accessible
//   Caused by: java.lang.NoSuchFieldException: amount

// 2. Register the class
@RegisterForReflection
public class PaymentDto {
    private BigDecimal amount;  // Now accessible
    private String currency;
}

// FIXING CATEGORY 2: Init failure
// Build error: java.net.ConnectException in
//   com.thirdparty.sdk.ClientInit.<clinit>
// Can't change third-party code

// Fix in application.properties:
// quarkus.native.additional-build-args=\
//   --initialize-at-run-time=\
//   com.thirdparty.sdk.ClientInit

// Verify fix:
./mvnw package -Pnative  // Should succeed
```

> **Code walkthrough:** The four-step diagnostic workflow
> matches category to approach. The tracing agent approach
> (Step 3) is the most reliable for Category 1 failures:
> run the app, hit the failing endpoint, collect the
> generated config. The --initialize-at-run-time flag
> (Step 2) defers problematic static initializers to
> runtime - a last resort for third-party code.

---

### 🎓 Answers by Seniority

**Senior:** "Build failures: four categories, different symptoms.
Runtime ClassNotFoundException: Category 1 - missing reflection
config, use tracing agent. Build ExceptionInInitializerError:
Category 2 - static init side effect, use @InitializeAtRunTime."

**Staff:** "Native image failures require a methodical diagnostic:
identify category from error message, apply category-specific
fix. Tracing agent is the most powerful tool for undiscovered
reflection needs. Add native-mode integration tests to CI
to catch Category 1 issues before production."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Failure categories, tracing agent, @InitializeAtRunTime |
| Staff | 11 min | Full diagnostic workflow, CI strategy |

---

**[STAFF] Q1 - How do you systematically prevent
native image failures in a large codebase?**

*Why they ask:* Engineering discipline for native image.

Systematic prevention strategy:

1. Native CI gate (mandatory):
   - Every PR: build native image.
   - Run native integration tests.
   - Block merge if native fails.
   - Catch issues before main branch.

2. Dependency vetting:
   - New dependency: check for native-image metadata.
   - Check: does JAR contain META-INF/native-image/?
   - Check: GraalVM reachability metadata repository.
     (github.com/oracle/graalvm-reachability-metadata)
   - Add: config for unsupported libraries before merging.

3. Tracing agent in local dev:
   - Developer: run tracing agent locally.
   - Submit: reflection config with feature PR.
   - Review: config changes in code review.

4. Test coverage for native:
   - Minimum: every API endpoint covered in native test.
   - Include: error paths (exception serialization).
   - Include: edge cases (null fields in DTOs).

5. Reflection audit:
   - Weekly/monthly: grep for Class.forName, Field.get,
     Method.invoke in codebase.
   - Review: each occurrence has a reflection config entry.

```bash
# Find reflection usage
grep -r "Class.forName\|getDeclaredField\|getDeclaredMethod" \
  src/main/java/ --include="*.java"

# Find classes without @RegisterForReflection
# (need manual inspection)
```

*What separates good from great:* Native failures are
preventable with discipline. CI gate + tracing agent
+ reflection audit = near-zero production native failures.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Failure categories, diagnostic commands. |
| Hiring Manager | CI strategy for native. |
| Bar Raiser | Systematic prevention, dependency vetting. |
| Staff | "Native CI gate: non-negotiable. Catch reflection issues in PR review, not at 2am prod alert." |
