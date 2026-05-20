---
layout: default
title: "Spring - Testing"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 9
permalink: /interview/spring/testing/
topic: Spring
subtopic: Testing
keywords:
  - Spring Boot Test Slices
  - MockMvc and Web Layer Testing
  - Testcontainers Integration
  - Mocking with Mockito in Spring
  - Integration vs Unit Testing Strategy
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Spring Boot Test Slices](#spring-boot-test-slices)
- [MockMvc and Web Layer Testing](#mockmvc-and-web-layer-testing)
- [Testcontainers Integration](#testcontainers-integration)
- [Mocking with Mockito in Spring](#mocking-with-mockito-in-spring)
- [Integration vs Unit Testing Strategy](#integration-vs-unit-testing-strategy)

# Spring Boot Test Slices

**TL;DR** - Test slices (`@WebMvcTest`, `@DataJpaTest`, `@JsonTest`, etc.) load only the part of the Spring context needed for a specific layer - making tests 10-50x faster than `@SpringBootTest` by avoiding loading the entire application context.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every test uses `@SpringBootTest` which loads the entire application context: all beans, database connections, message brokers, external service clients. A simple controller test takes 30 seconds to start because it initializes Hibernate, Redis, Kafka, and 500 beans.

**THE BREAKING POINT:**
The test suite has 2000 tests. Each `@SpringBootTest` class takes 30 seconds to start. Total CI time: 45 minutes. Developers stop running tests locally.

**THE INVENTION MOMENT:**
"This is exactly why test slices were created."

---

### 📘 Textbook Definition

Spring Boot test slices are specialized test annotations that auto-configure only a slice of the application context. `@WebMvcTest` loads controllers, filters, and web-related beans. `@DataJpaTest` loads repositories, EntityManager, and an embedded database. `@JsonTest` loads JSON serialization/deserialization. Each slice excludes everything else, dramatically reducing startup time and test isolation.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Test only the layer you care about by loading only that layer's beans.

**One analogy:**

> Testing a car. `@SpringBootTest` starts the entire car (engine, transmission, AC, radio) just to test the windshield wipers. `@WebMvcTest` only powers the wiper system. Faster, focused, and you know exactly what broke.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
Specialized test annotations that load only part of your app for faster, focused testing.

**Level 2 - How to use it (junior):**

| Slice           | What loads             | Use for            |
| --------------- | ---------------------- | ------------------ |
| @WebMvcTest     | Controllers, filters   | REST endpoints     |
| @DataJpaTest    | Repos, EntityManager   | JPA queries        |
| @JsonTest       | Jackson ObjectMapper   | JSON serialization |
| @RestClientTest | RestTemplate/WebClient | HTTP client        |
| @SpringBootTest | Everything             | Full integration   |

```java
// Controller test - fast (< 2 seconds)
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean UserService service;

    @Test
    void returnsUser() throws Exception {
        when(service.findById(1L))
            .thenReturn(
                new User(1L, "John"));

        mvc.perform(get("/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name")
                .value("John"));
    }
}
```

**Level 3 - How it works (mid-level):**

`@WebMvcTest` auto-configures:

- `MockMvc` (test MVC without HTTP)
- `@Controller` beans (specified or all)
- `@ControllerAdvice`, `@JsonComponent`
- Security filters (if spring-security on classpath)
- Message converters, `WebMvcConfigurer`

`@WebMvcTest` does NOT load:

- `@Service`, `@Repository`, `@Component`
- Database configuration
- External service clients

```java
// Repository test - uses embedded DB
@DataJpaTest
class UserRepositoryTest {
    @Autowired UserRepository repo;
    @Autowired TestEntityManager em;

    @Test
    void findsByEmail() {
        em.persist(
            new User("John",
                "john@test.com"));
        em.flush();

        Optional<User> found =
            repo.findByEmail(
                "john@test.com");
        assertThat(found).isPresent();
        assertThat(found.get().getName())
            .isEqualTo("John");
    }
}
```

`@DataJpaTest` auto-configures:

- `@Repository` beans
- Embedded H2/HSQL database
- `TestEntityManager`
- Flyway/Liquibase migrations
- Rolls back transactions after each test

**Level 4 - Mastery (senior/staff+):**

Custom slice with additional beans:

```java
@WebMvcTest(UserController.class)
@Import(CustomSecurityConfig.class)
class SecuredControllerTest {
    // Loads security config
    // that @WebMvcTest excludes
}
```

Context caching:

```
  Test classes sharing the same
  configuration reuse the context.

  @WebMvcTest(UserController.class)
  -> context 1 (cached)

  @WebMvcTest(OrderController.class)
  -> context 2 (new, different slice)

  @WebMvcTest(UserController.class)
  -> context 1 (reused from cache)
```

Polluting the cache:

```java
// BAD - @MockitoBean pollutes context
// Each unique mock set = new context
@WebMvcTest(UserController.class)
class Test1 {
    @MockitoBean UserService svc; // ctx A
}
@WebMvcTest(UserController.class)
class Test2 {
    @MockitoBean UserService svc;
    @MockitoBean AuditService audit; // ctx B
}
// Two contexts loaded! Slow!
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@WebMvcTest` for controller tests."

**A Staff says:** "I design the test strategy: `@WebMvcTest` for controllers (mock services), `@DataJpaTest` for repositories (embedded DB or Testcontainers), plain JUnit for services (no Spring context). I minimize context pollution by keeping mock sets consistent across test classes. CI runs sliced tests first (fast feedback), then full integration tests."

---

### 💻 Code Example

**BAD @SpringBootTest for controller vs GOOD @WebMvcTest:**

```java
// BAD - loads everything for controller
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {
    @Autowired MockMvc mvc;
    // Loads DB, Kafka, Redis, 500 beans
    // Takes 30 seconds to start
}

// GOOD - loads only web layer
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean UserService service;
    // Loads controller + web config only
    // Takes 2 seconds to start
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Layer-specific test annotations that load minimal Spring context.

**KEY INSIGHT:** @WebMvcTest = web layer. @DataJpaTest = data layer. No overlap.

**ANTI-PATTERN:** @SpringBootTest for everything. @MockitoBean proliferation (context pollution).

**ONE-LINER:** "Test slices = fast, focused, layer-specific tests."

**TRIGGER PHRASE:** "Slice the context, not the quality."

**If you remember only 3 things:**

1. @WebMvcTest for controllers, @DataJpaTest for repos, plain JUnit for services
2. Test slices are 10-50x faster than @SpringBootTest
3. Context caching: consistent mock sets across test classes

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is @WebMvcTest and when do you use it?**

**Answer:**
`@WebMvcTest` loads only the web layer: controllers, filters, advice, converters. Services and repositories are NOT loaded - you mock them with `@MockitoBean`. Use it for testing REST endpoints: request mapping, validation, serialization, error handling. 10-50x faster than `@SpringBootTest` because it skips DB, message brokers, etc.

---

**Q2 [SENIOR]: How do you optimize Spring test suite execution time?**

**Answer:**

1. **Test slices:** @WebMvcTest, @DataJpaTest instead of @SpringBootTest (10-50x faster)
2. **Context caching:** Keep mock sets consistent across test classes (shared context)
3. **Plain JUnit for services:** No Spring context needed for pure logic
4. **Testcontainers with reuse:** One container per CI run, not per test class
5. **Parallel execution:** JUnit 5 parallel with `@Execution(CONCURRENT)` for independent tests
6. **CI pipeline:** Sliced tests first (fail fast), integration tests second

---

### 🔗 Related Keywords

**Prerequisites:** IoC Container, Spring Boot Auto-Configuration

**Builds on:** MockMvc, Testcontainers, Mockito

**Alternatives:** Arquillian (Jakarta EE), manual context config

---

---

# MockMvc and Web Layer Testing

**TL;DR** - MockMvc simulates HTTP requests against your Spring MVC controllers without starting an HTTP server - testing the full request processing pipeline (filters, controllers, advice, serialization) in-process with sub-second startup.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
To test a controller, you start the full application with an embedded server, make HTTP requests with RestTemplate, and assert on responses. Startup takes 30 seconds. Debugging requires network tracing. Port conflicts in CI.

---

### 📘 Textbook Definition

MockMvc is a Spring Test framework class that performs requests against the DispatcherServlet without starting an HTTP server. It processes the entire Spring MVC pipeline: filters, handler mapping, controller invocation, exception handling, content negotiation, and response serialization. Results are asserted using `ResultMatcher` DSL: `status()`, `content()`, `jsonPath()`, `header()`.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Test your REST endpoints in-process by sending mock HTTP requests through the full MVC pipeline, without starting a real server.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean UserService service;

    @Test
    void getUser() throws Exception {
        when(service.findById(1L))
            .thenReturn(
                new User(1L, "John",
                    "john@test.com"));

        mvc.perform(get("/users/1")
                .accept(APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name")
                .value("John"))
            .andExpect(jsonPath("$.email")
                .value("john@test.com"));
    }

    @Test
    void createUser() throws Exception {
        String json = """
            {"name":"John",
             "email":"john@test.com"}""";

        mvc.perform(post("/users")
                .contentType(
                    APPLICATION_JSON)
                .content(json))
            .andExpect(status()
                .isCreated())
            .andExpect(header()
                .exists("Location"));
    }

    @Test
    void returns400ForInvalidInput()
            throws Exception {
        String json =
            "{\"name\":\"\",\"email\":\"\"}";

        mvc.perform(post("/users")
                .contentType(
                    APPLICATION_JSON)
                .content(json))
            .andExpect(status()
                .isBadRequest())
            .andExpect(jsonPath(
                "$.errors.name")
                .exists());
    }
}
```

**Level 3 - How it works (mid-level):**

```
  mvc.perform(get("/users/1"))
       |
  MockHttpServletRequest created
       |
  Passed to DispatcherServlet
  (in-process, no HTTP)
       |
  Full MVC pipeline:
    Filter chain (incl. security)
    Handler mapping
    Handler adapter
    Controller invocation
    Exception handling
    Content negotiation
    HttpMessageConverter
       |
  MockHttpServletResponse captured
       |
  ResultMatchers assert on response
```

**Level 4 - Mastery (senior/staff+):**

Testing with security:

```java
@WebMvcTest(AdminController.class)
class AdminControllerTest {
    @Autowired MockMvc mvc;

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanAccess()
            throws Exception {
        mvc.perform(get("/admin/users"))
            .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    void userGetsForbidden()
            throws Exception {
        mvc.perform(get("/admin/users"))
            .andExpect(status()
                .isForbidden());
    }

    @Test
    void unauthenticatedGets401()
            throws Exception {
        mvc.perform(get("/admin/users"))
            .andExpect(status()
                .isUnauthorized());
    }
}
```

Testing file upload:

```java
@Test
void uploadsFile() throws Exception {
    MockMultipartFile file =
        new MockMultipartFile(
            "file", "test.csv",
            "text/csv",
            "name,age\nJohn,30".getBytes());

    mvc.perform(multipart("/upload")
            .file(file))
        .andExpect(status().isOk());
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** In-process MVC testing without HTTP server.

**KEY INSIGHT:** Full MVC pipeline (filters, controllers, advice, converters) without network.

**ANTI-PATTERN:** Starting full server for controller tests. Not testing error paths.

**ONE-LINER:** "MockMvc = HTTP simulation through full MVC pipeline."

**If you remember only 3 things:**

1. No HTTP server needed - tests run in-process
2. Full pipeline: filters -> controller -> advice -> serialization
3. Assert with status(), jsonPath(), header(), content()

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is MockMvc and how is it different from RestTemplate?**

**Answer:**
MockMvc: tests the MVC pipeline in-process without starting an HTTP server. Faster (no network). Tests the full pipeline (filters, controllers, advice, serialization).

RestTemplate / WebTestClient: makes real HTTP requests to a running server. Tests the complete stack including the HTTP layer. Slower (requires server startup).

Use MockMvc with `@WebMvcTest` for unit-level controller tests. Use WebTestClient with `@SpringBootTest(webEnvironment = RANDOM_PORT)` for full integration tests.

---

**Q2 [MID]: How do you test security rules with MockMvc?**

**Answer:**
Use `@WithMockUser` to simulate authenticated users:

- `@WithMockUser(roles = "ADMIN")` - test admin access
- `@WithMockUser(roles = "USER")` - test restricted access
- No annotation = unauthenticated (test 401)

For JWT-based security, use `SecurityMockMvcRequestPostProcessors`:

```java
mvc.perform(get("/api/data")
    .with(jwt().authorities(
        new SimpleGrantedAuthority(
            "ROLE_ADMIN"))))
    .andExpect(status().isOk());
```

---

### 🔗 Related Keywords

**Prerequisites:** Spring MVC, DispatcherServlet

**Builds on:** Spring Boot Test Slices, Spring Security

**Alternatives:** WebTestClient (reactive + full stack), RestAssured

---

---

# Testcontainers Integration

**TL;DR** - Testcontainers launches real Docker containers (PostgreSQL, Redis, Kafka) during tests, replacing unreliable mocks and embedded databases with production-identical infrastructure - ensuring your tests verify actual database queries, not H2 approximations.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Tests use H2 embedded database. A query uses PostgreSQL-specific features (`jsonb`, window functions, `ON CONFLICT`). H2 does not support them. Tests pass, production fails. The team adds H2 compatibility mode - but it is still not PostgreSQL.

**THE BREAKING POINT:**
A JSONB query works in H2 compatibility mode but silently returns wrong results. The bug reaches production. The team realizes embedded databases are not reliable for testing.

**THE INVENTION MOMENT:**
"This is exactly why Testcontainers was created."

---

### 📘 Textbook Definition

Testcontainers is a Java library that manages Docker containers within JUnit tests. It provides modules for databases (PostgreSQL, MySQL, MongoDB), message brokers (Kafka, RabbitMQ), caches (Redis), and other services. Spring Boot 3.1+ includes first-class Testcontainers support via `@ServiceConnection` which auto-configures the `DataSource`, `RedisConnectionFactory`, etc. from the container's dynamic port.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Run real PostgreSQL/Redis/Kafka in Docker during tests - no mocks, no embedded fakes, production-identical behavior.

**One analogy:**

> Testing with a stunt double vs the real actor. H2 is the stunt double - looks similar but does not perform identically. Testcontainers brings the real actor (PostgreSQL) to the set (test). Same performance, same behavior, same results.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

Spring Boot 3.1+ with `@ServiceConnection`:

```java
@SpringBootTest
@Testcontainers
class UserRepositoryIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> pg =
        new PostgreSQLContainer<>(
            "postgres:16-alpine");

    @Autowired
    UserRepository repo;

    @Test
    void savesAndFindsUser() {
        User saved = repo.save(
            new User("John",
                "john@test.com"));
        Optional<User> found =
            repo.findById(saved.getId());
        assertThat(found).isPresent();
    }
}
```

`@ServiceConnection` automatically sets `spring.datasource.url`, `username`, and `password` from the container.

**Level 3 - How it works (mid-level):**

```
  @Testcontainers JUnit extension
       |
  Before all tests:
    Start Docker container (postgres:16)
    Wait for readiness check
    Expose random port
       |
  @ServiceConnection:
    Read container host + port
    Configure DataSource automatically
       |
  Tests run against real PostgreSQL
       |
  After all tests:
    Stop and remove container
```

Multiple containers:

```java
@Container
@ServiceConnection
static PostgreSQLContainer<?> pg =
    new PostgreSQLContainer<>(
        "postgres:16-alpine");

@Container
@ServiceConnection
static GenericContainer<?> redis =
    new GenericContainer<>(
        "redis:7-alpine")
    .withExposedPorts(6379);

@Container
@ServiceConnection
static KafkaContainer kafka =
    new KafkaContainer(
        DockerImageName.parse(
            "confluentinc/"
            + "cp-kafka:7.5.0"));
```

**Level 4 - Mastery (senior/staff+):**

Reusable containers for CI speed:

```java
// Singleton pattern - one container
// shared across all test classes
abstract class BaseIT {
    static final PostgreSQLContainer<?> PG;
    static {
        PG = new PostgreSQLContainer<>(
            "postgres:16-alpine")
            .withReuse(true);
        PG.start();
    }

    @DynamicPropertySource
    static void props(
            DynamicPropertyRegistry r) {
        r.add("spring.datasource.url",
            PG::getJdbcUrl);
        r.add("spring.datasource.username",
            PG::getUsername);
        r.add("spring.datasource.password",
            PG::getPassword);
    }
}
```

Spring Boot 3.1 `TestApplication` for dev:

```java
// Run app locally with containers
@TestConfiguration(
    proxyBeanMethods = false)
public class TestApp {
    @Bean
    @ServiceConnection
    PostgreSQLContainer<?> pg() {
        return new PostgreSQLContainer<>(
            "postgres:16-alpine");
    }

    public static void main(String[] a) {
        SpringApplication
            .from(App::main)
            .with(TestApp.class)
            .run(a);
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Testcontainers instead of H2."

**A Staff says:** "I use a singleton container pattern for CI speed (one PostgreSQL container shared across all integration test classes). `@ServiceConnection` for auto-configuration. `@DynamicPropertySource` as fallback. Testcontainers for dev environment too (TestApplication). Database migrations (Flyway) run against the container just like production."

---

### 💻 Code Example

**BAD H2 compatibility vs GOOD Testcontainers:**

```java
// BAD - H2 pretending to be PostgreSQL
@DataJpaTest
@AutoConfigureTestDatabase(
    replace = NONE)
@TestPropertySource(properties = {
    "spring.datasource.url="
    + "jdbc:h2:mem:test;"
    + "MODE=PostgreSQL"
})
class UserRepoTest {
    // H2 does not support jsonb,
    // partial indexes, or
    // ON CONFLICT correctly
}

// GOOD - real PostgreSQL
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(
    replace = NONE)
class UserRepoTest {
    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> pg =
        new PostgreSQLContainer<>(
            "postgres:16-alpine");
    // Real PostgreSQL behavior
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Real Docker containers (DB, Redis, Kafka) in tests.

**KEY INSIGHT:** H2 is not PostgreSQL. Test against real infrastructure.

**ANTI-PATTERN:** Using H2 compatibility mode for DB-specific features.

**ONE-LINER:** "Testcontainers = real infra in tests. No fakes."

**TRIGGER PHRASE:** "Real database, Testcontainers, @ServiceConnection."

**If you remember only 3 things:**

1. `@ServiceConnection` auto-configures DataSource from container
2. Singleton pattern: one container shared across test classes
3. Test the same DB you run in production (PostgreSQL, not H2)

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Why use Testcontainers instead of H2?**

**Answer:**
H2 in compatibility mode does not match real database behavior. PostgreSQL-specific features (jsonb, window functions, ON CONFLICT, partial indexes) either fail or return wrong results in H2.

Testcontainers runs the REAL database in Docker. Tests verify actual SQL execution, including migrations (Flyway), indexes, and DB-specific functions. `@ServiceConnection` in Spring Boot 3.1+ auto-configures everything. Singleton pattern keeps CI fast.

---

**Q2 [SENIOR]: Design a test infrastructure strategy using Testcontainers.**

**Answer:**

- **Unit tests:** Plain JUnit + Mockito. No containers. No Spring.
- **Slice tests:** `@DataJpaTest` + Testcontainers PostgreSQL (singleton). `@WebMvcTest` + MockMvc (no containers).
- **Integration tests:** `@SpringBootTest` + Testcontainers (PostgreSQL, Redis, Kafka).
- **CI optimization:** Singleton containers (shared per test run). Docker layer caching. Parallel test execution.
- **Local dev:** `TestApplication` class with Testcontainers for running the app locally without installing DB/Redis.

---

### 🔗 Related Keywords

**Prerequisites:** Docker, Spring Boot Test Slices

**Builds on:** Spring Data JPA, Integration Testing

**Alternatives:** Embedded H2 (simpler but less accurate), WireMock (HTTP services)

---

---

# Mocking with Mockito in Spring

**TL;DR** - `@MockitoBean` (Spring Boot 3.4+) and `@MockBean` (legacy) replace real beans with Mockito mocks in the Spring context, letting you test one layer in isolation by controlling dependencies' behavior with `when().thenReturn()`.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
To test a controller, you need real services, real repositories, a real database. A bug in the repository layer causes controller tests to fail. Tests are coupled to layers they are not testing.

---

### 📘 Textbook Definition

`@MockitoBean` (Spring Boot 3.4+, replacing deprecated `@MockBean`) creates a Mockito mock and registers it in the Spring application context, replacing the real bean. `@SpyBean` / `@MockitoSpyBean` wraps the real bean with a spy (real methods execute unless stubbed). These annotations enable isolated layer testing: mock the dependencies, test the target.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Replace real Spring beans with Mockito mocks to test one layer without its dependencies.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean UserService service;

    @Test
    void returnsUser() throws Exception {
        when(service.findById(1L))
            .thenReturn(
                new User(1L, "John"));

        mvc.perform(get("/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name")
                .value("John"));
    }

    @Test
    void returns404WhenNotFound()
            throws Exception {
        when(service.findById(99L))
            .thenThrow(
                new NotFoundException(
                    "Not found"));

        mvc.perform(get("/users/99"))
            .andExpect(status()
                .isNotFound());
    }
}
```

**Level 3 - How it works (mid-level):**

Mock vs Spy:

| Feature      | @MockitoBean          | @MockitoSpyBean       |
| ------------ | --------------------- | --------------------- |
| Real methods | No (returns null/0)   | Yes (real execution)  |
| Stubbing     | Required for behavior | Optional override     |
| Use case     | Replace dependency    | Verify + partial mock |
| Context      | Replaces real bean    | Wraps real bean       |

```java
// Spy example - verify audit was called
@SpringBootTest
class OrderServiceTest {
    @Autowired OrderService service;
    @MockitoSpyBean AuditService audit;

    @Test
    void logsAuditOnOrder() {
        service.placeOrder(new OrderReq());
        verify(audit).log(
            eq("ORDER_PLACED"),
            any());
    }
}
```

**Level 4 - Mastery (senior/staff+):**

Context pollution warning:

```java
// Each unique @MockitoBean set creates
// a new Spring context.
// These two classes cannot share context:

@WebMvcTest(UserController.class)
class Test1 {
    @MockitoBean UserService svc;
}

@WebMvcTest(UserController.class)
class Test2 {
    @MockitoBean UserService svc;
    @MockitoBean AuditService audit;
    // Different mock set = new context!
}
```

Fix: standardize mock sets across tests or use base classes.

**When NOT to mock:**

- Database queries (use Testcontainers)
- JSON serialization (use @JsonTest)
- HTTP clients (use WireMock)
- Business logic (test the real code)

**The Senior-to-Staff Leap:**

**A Senior says:** "Mock dependencies with `@MockitoBean`."

**A Staff says:** "I mock at boundaries: controllers mock services, services use real logic with mocked external clients. I never mock repositories - I test them with Testcontainers. I keep mock sets consistent to maximize context caching. I use `verify()` sparingly - test behavior, not implementation."

---

### 💻 Code Example

**BAD over-mocking vs GOOD targeted mocking:**

```java
// BAD - mocking everything
@SpringBootTest
class OrderTest {
    @MockitoBean OrderRepository repo;
    @MockitoBean UserRepository userRepo;
    @MockitoBean PaymentGateway payment;
    @MockitoBean EmailService email;
    // Mocking 4 things - testing nothing

// GOOD - mock only the boundary
@SpringBootTest
class OrderTest {
    @Autowired OrderService service;
    @MockitoBean PaymentGateway payment;
    // Real repos with Testcontainers
    // Real service logic
    // Only external system is mocked
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Replace Spring beans with Mockito mocks for isolated testing.

**KEY INSIGHT:** Mock at boundaries, not internals. Test real code.

**ANTI-PATTERN:** Mocking everything (tests nothing). Different mock sets per class (context pollution).

**ONE-LINER:** "@MockitoBean replaces bean in context. when().thenReturn() controls it."

**If you remember only 3 things:**

1. @MockitoBean replaces, @MockitoSpyBean wraps the real bean
2. Mock external dependencies, not internal logic
3. Consistent mock sets = shared context = faster tests

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: When should you use @MockitoBean vs real beans?**

**Answer:**
Mock: external services (payment gateway, email), cross-layer dependencies in slice tests (@WebMvcTest mocks services).

Real beans: business logic, repositories (with Testcontainers), serialization. The goal is to test real behavior, not mock scaffolding.

Rule: mock at the boundary of what you are testing. Controller test mocks services. Integration test mocks only external systems.

---

### 🔗 Related Keywords

**Prerequisites:** Mockito, Spring IoC

**Builds on:** Spring Boot Test Slices, MockMvc

**Alternatives:** WireMock (HTTP mocks), Testcontainers (real infra)

---

---

# Integration vs Unit Testing Strategy

**TL;DR** - A balanced Spring test strategy combines fast unit tests (plain JUnit, no Spring) for business logic, slice tests (@WebMvcTest, @DataJpaTest) for framework integration, and full integration tests (@SpringBootTest + Testcontainers) for end-to-end flows - following the testing pyramid with clear boundaries.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
All tests are `@SpringBootTest`. Every test loads the full context. Suite takes 45 minutes. Developers skip tests. Or all tests are pure unit tests with mocks - passing tests but missing integration bugs.

---

### 📘 Textbook Definition

The testing pyramid suggests many fast unit tests at the base, fewer integration tests in the middle, and minimal end-to-end tests at the top. In Spring: unit tests use JUnit + Mockito (no Spring context), slice tests use `@WebMvcTest`/`@DataJpaTest` (partial context), and integration tests use `@SpringBootTest` (full context). Each level trades speed for confidence.

---

### ⚖️ Comparison Table

| Level       | Annotation      | Speed | Confidence        | What to test               |
| ----------- | --------------- | ----- | ----------------- | -------------------------- |
| Unit        | None (JUnit)    | < 1ms | Low (logic only)  | Business logic, algorithms |
| Slice       | @WebMvcTest     | < 2s  | Medium (layer)    | Controllers, repos         |
| Integration | @SpringBootTest | 5-30s | High (full stack) | E2E flows, config          |

---

### 📶 Gradual Depth

**Level 2 - Strategy overview:**

```
        /  E2E  \       <- Few, slow
       / Integr. \      <- @SpringBootTest
      /  Slices    \    <- @WebMvcTest, etc.
     /   Unit Tests  \  <- JUnit + Mockito
    ==================  <- Many, fast
```

**Level 3 - What to test where:**

```
  Unit (no Spring):
    - Service business logic
    - Utility classes
    - Mappers / converters
    - Validation logic

  Slice (@WebMvcTest):
    - Request mapping correct?
    - Validation works?
    - Error handling format?
    - Security rules enforced?

  Slice (@DataJpaTest + Testcontainers):
    - Derived queries correct?
    - Custom @Query correct?
    - Pagination works?

  Integration (@SpringBootTest):
    - Full request -> DB -> response
    - Transaction boundaries correct
    - Configuration loads properly
    - Multiple beans wire correctly
```

**Level 4 - Mastery (senior/staff+):**

Test strategy for a microservice:

```
  Tests: 200 total
    Unit:        120 (60%) < 10 seconds
    Slice:        50 (25%) < 60 seconds
    Integration:  25 (12%) < 120 seconds
    E2E:           5 (3%)  < 60 seconds

  Total CI time: < 5 minutes
```

CI pipeline:

```
  Stage 1: Unit tests (parallel)
    -> Fast feedback (< 10s)
  Stage 2: Slice tests
    -> Layer confidence (< 60s)
  Stage 3: Integration tests
    -> Full confidence (< 2min)
  Stage 4: E2E smoke tests
    -> Deployment validation
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Write unit tests and integration tests."

**A Staff says:** "I design the test pyramid: 60% unit (plain JUnit for business logic), 25% slice (framework integration per layer), 12% integration (full flows with Testcontainers), 3% E2E (contract/smoke). I optimize CI with parallel execution, context caching, and singleton Testcontainers. Target: < 5 min total CI test time."

---

### 💻 Code Example

**Three-level testing:**

```java
// 1. Unit test (no Spring, fast)
class PricingServiceTest {
    PricingService service =
        new PricingService(
            new InMemoryProductRepo());

    @Test
    void appliesDiscount() {
        BigDecimal price =
            service.calculate(
                "PROD-1", "SUMMER20");
        assertThat(price)
            .isEqualByComparingTo("80.00");
    }
}

// 2. Slice test (partial Spring)
@WebMvcTest(PricingController.class)
class PricingControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean PricingService service;

    @Test
    void returnsPrice() throws Exception {
        when(service.calculate(any(), any()))
            .thenReturn(
                new BigDecimal("80.00"));
        mvc.perform(get("/price/PROD-1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.price")
                .value(80.00));
    }
}

// 3. Integration test (full stack)
@SpringBootTest(
    webEnvironment = RANDOM_PORT)
@Testcontainers
class PricingIT {
    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> pg =
        new PostgreSQLContainer<>(
            "postgres:16-alpine");

    @Autowired TestRestTemplate rest;

    @Test
    void fullFlow() {
        var resp = rest.getForEntity(
            "/price/PROD-1",
            PriceResponse.class);
        assertThat(resp.getStatusCode())
            .isEqualTo(HttpStatus.OK);
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Layered testing strategy: unit -> slice -> integration -> E2E.

**KEY INSIGHT:** Right test at the right level. Fast tests for logic, slow tests for integration.

**ANTI-PATTERN:** All @SpringBootTest (slow). All unit tests (misses integration bugs).

**ONE-LINER:** "60% unit, 25% slice, 12% integration, 3% E2E."

**TRIGGER PHRASE:** "Testing pyramid, right test at right level."

**If you remember only 3 things:**

1. Unit tests (no Spring) for business logic - fast, many
2. Slice tests for framework integration - focused, medium
3. Integration tests for end-to-end - thorough, few

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Describe your testing strategy for a Spring Boot microservice.**

**Answer:**
Testing pyramid:

1. **Unit (60%):** Plain JUnit + Mockito. Business logic, services, mappers. No Spring context. < 1ms each.
2. **Slice (25%):** `@WebMvcTest` for controllers, `@DataJpaTest` + Testcontainers for repos. 2-5s each.
3. **Integration (12%):** `@SpringBootTest` + Testcontainers. Full flows: request -> service -> DB -> response. 10-30s each.
4. **E2E (3%):** Smoke tests against deployed service. Contract tests with Pact.

Target CI time: < 5 minutes.

---

### 🔗 Related Keywords

**Prerequisites:** JUnit 5, Mockito

**Builds on:** All previous testing keywords

**Related:** Test Pyramid, CI/CD, Code Coverage
