---
layout: default
title: "Spring - L3 Profiles and Advanced Config"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 9
permalink: /spring/l3-profiles-and-advanced-config/
render_with_liquid: false
---

# Spring - L3 Profiles and Advanced Config

---

# Spring Profiles

---
id: SPR-020
title: Spring Profiles
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring-profiles, #environment, #configuration, #multi-env
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — environment-specific configuration is a fundamental
DevOps/Spring topic. Kubernetes, CI/CD, and microservice interview questions
frequently touch profiles.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Profiles allow different configurations for different environments
> (dev, test, prod). You activate a profile with spring.profiles.active=prod.
> Profile-specific property files like application-prod.properties override base
> application.properties. Beans can be restricted to specific profiles with
> @Profile("prod"). Spring Boot also supports profile groups to activate multiple
> related profiles together.

**3 minutes (Senior):**
> Profiles solve the environment isolation problem: the same application runs in
> dev (H2 database, debug logging, mock external services) and production (RDS,
> INFO logging, real external services). The mechanism: Spring maintains a set of
> active profiles. @Profile("prod") beans are only instantiated when "prod" is
> active. application-{profile}.properties files are loaded and override
> application.properties when the named profile is active.
>
> Loading order matters: application.properties is loaded first, then
> application-{profile}.properties files are loaded and override. The last one
> wins if multiple profiles are active. Profile-specific files always override
> the base file.
>
> In Spring Boot 2.4+, the profiles property changed to spring.config.activate.on-profile
> for YAML files. Spring Boot also introduced profile groups: activating "prod"
> can automatically activate "prod-db", "prod-security", "prod-monitoring" as a
> group.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - Kubernetes deployment uses SPRING_PROFILES_ACTIVE env var.
Spring Cloud Config Server can activate profiles externally. Multi-document YAML
with profile conditions.

*Adapting down:* Junior - "Profiles are like different settings files for
different environments. You tell Spring 'use the prod profile' and it loads
your prod settings."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Profiles - how Spring manages
different configurations for different environments."

**(2) First principles:** "The same code must work in development, testing, and
production but with different infrastructure (databases, queues, external services).
Profiles separate that environment-specific configuration from the code."

**(3) Bridge:** "Profiles are like costume changes for your application. The actor
(code) is the same; only the costume (configuration) changes per scene (environment)."

---

### 📘 Concept Explanation

**What it is:**
Spring Profiles are named groups of configuration that are conditionally activated.
When a profile is active, profile-specific beans and property files are loaded
in addition to the default configuration.

**The problem it solves:**
Different environments need different settings: database URLs, log levels, feature
flags, mock vs real services. Without profiles, you either hardcode environment
checks in code (bad) or maintain separate codebases (worse). Profiles centralize
environment differences in configuration, not code.

**How it works:**

```
Profile loading order (Spring Boot):

1. application.properties (always loaded)
2. application-{profile1}.properties
   (if profile1 is active - overrides step 1)
3. application-{profile2}.properties
   (if profile2 is active - overrides step 2)

Later files override earlier files for same key.
Profile-specific files ALWAYS override base file.

Activation methods (by priority - highest first):
  1. spring.profiles.active in application.properties
  2. SPRING_PROFILES_ACTIVE env var (CI/CD, Kubernetes)
  3. -Dspring.profiles.active=prod JVM arg
  4. SpringApplication.setAdditionalProfiles()

@Profile bean activation:
  @Profile("prod") - only when "prod" is active
  @Profile("!prod") - when "prod" is NOT active
  @Profile("dev | test") - when dev OR test is active
  @Profile("dev & cloud") - when dev AND cloud are active

Profile groups (Spring Boot 2.4+):
  spring.profiles.group.prod=\
    prod-db,prod-security,prod-monitoring
  Activating "prod" also activates all three.

Multi-document YAML (Spring Boot 2.4+):
  ---
  server.port: 8080
  ---
  spring.config.activate.on-profile: prod
  server.port: 80
  database.url: prod-db-host:5432/mydb

Profile-aware @Bean:
  @Configuration
  public class DataSourceConfig {

    @Bean
    @Profile("dev")
    public DataSource devDataSource() {
      return new EmbeddedDatabaseBuilder()
        .setType(H2)
        .build();
    }

    @Bean
    @Profile("prod")
    public DataSource prodDataSource() {
      // RDS connection with pooling
    }
  }
```

**The key insight:**
The most important profile is "default" - it is active when NO other profiles
are active. application-default.properties is loaded in this case. This prevents
running in production with the wrong environment: if someone forgets to set
SPRING_PROFILES_ACTIVE, they get "default" (which you make safe/dev-like),
not accidental prod settings mixed with dev settings.

**When to use it:**
- All applications that deploy to multiple environments
- Feature flags (activating experimental features in staging only)
- Local vs CI vs production infrastructure differences

**When NOT to use it:**
- Do not put secrets in profile-specific properties files - use Vault or
  Kubernetes secrets
- Do not use profiles for feature flags that change at runtime - profiles
  are set at startup time

**Alternatives:**
- Environment variables only: simpler but no Bean-level activation
- Spring Cloud Config: externalized configuration with profile support
- Kubernetes ConfigMaps: inject configuration as environment variables

---

### 💻 Code Example

```java
// dev profile: MockPaymentService replaces real one
@Service
@Profile("dev")
public class MockPaymentService
        implements PaymentService {

    @Override
    public PaymentResult charge(String customerId,
            BigDecimal amount) {
        log.info("MOCK payment: {} -> {}",
            customerId, amount);
        return PaymentResult.success("mock-tx-id");
    }
}

// prod profile: real Stripe integration
@Service
@Profile("prod")
public class StripePaymentService
        implements PaymentService {

    private final StripeClient stripeClient;

    @Override
    public PaymentResult charge(String customerId,
            BigDecimal amount) {
        return stripeClient.createCharge(
            customerId, amount);
    }
}
```

> **Code walkthrough:** Both services implement the same interface. The
> dependency injection target (PaymentService) is the same in the business code.
> Spring loads only the bean matching the active profile. In dev, payments are
> mocked (no real charges, no Stripe dependency). In prod, the real Stripe bean
> is injected. The business code has no environment checks - it just uses
> PaymentService. This is the clean way to swap infrastructure per environment.

```properties
# application.properties (base config)
spring.application.name=order-service
logging.level.root=INFO

# application-dev.properties (dev overrides)
spring.datasource.url=jdbc:h2:mem:devdb
spring.datasource.driver-class-name=\
  org.h2.Driver
spring.jpa.hibernate.ddl-auto=create-drop
logging.level.com.example=DEBUG
payment.service.mock=true

# application-prod.properties (prod overrides)
spring.datasource.url=\
  jdbc:postgresql://${DB_HOST:localhost}/orders
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASS}
spring.jpa.hibernate.ddl-auto=validate
logging.level.root=WARN
payment.service.mock=false
```

> **Code walkthrough:** Base application.properties has defaults that work safely.
> application-dev.properties uses H2 in-memory (no external DB needed), enables
> DDL creation (schema auto-created), and sets DEBUG logging. application-prod.properties
> reads credentials from environment variables (${DB_USER}, ${DB_PASS}) - NEVER
> hardcode production credentials in properties files. DDL is validate-only (no
> schema modification in prod). This pattern fails safely: missing SPRING_PROFILES_ACTIVE
> activates "default", which inherits the base config.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Profiles let you have different settings for different environments.
> You create application-dev.properties for dev settings and application-prod.properties
> for prod settings. Set spring.profiles.active=prod (or env var
> SPRING_PROFILES_ACTIVE=prod) and Spring loads that file. The @Profile annotation
> on beans makes them only load in specific environments.

*Push deeper:* What happens if you forget to set spring.profiles.active? What
is the "default" profile?

---

**Senior / Staff (5+ years):**
> Profiles separate environment concerns from code. Key points: profile-specific
> property files override base properties; @Profile works with SpEL (!, |, &);
> Spring Boot 2.4+ introduced profile groups (one profile activates many); prefer
> SPRING_PROFILES_ACTIVE env var in containers over JVM args; never put secrets
> in profile-specific files - use vault/secrets manager and reference via
> ${ENV_VAR}. For Kubernetes: inject SPRING_PROFILES_ACTIVE in the Deployment
> spec. For CI/CD: set in pipeline environment variables. Multi-document YAML with
> spring.config.activate.on-profile allows single-file multi-environment config.

*Push deeper:* Spring Boot 2.4 introduced a change: spring.profiles and
spring.profiles.include no longer work in profile-specific documents. Use
spring.config.activate.on-profile instead. This breaking change caused upgrade issues.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Profile-specific files override everything in base file."**
Profile-specific files override the same keys. Keys that only exist in
application.properties remain active even when a profile-specific file is loaded.
Properties stack - they are not replaced wholesale.

**Misconception 2: "@Profile is checked at autowire time."**
@Profile is checked at BeanDefinition registration time during context refresh.
Beans are not even registered (not just not instantiated) when their profile
doesn't match. This means @Autowired on a @Profile bean will fail with
NoSuchBeanDefinitionException if the profile is not active.

**Misconception 3: "You can only have one active profile."**
Multiple profiles can be active simultaneously: SPRING_PROFILES_ACTIVE=prod,monitoring,featureX.
Profile-specific files for all active profiles are loaded. This is useful for
cross-cutting concerns: "prod" activates production infrastructure; "monitoring"
activates additional observability; "featureX" activates a feature flag.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Wrong environment loaded in production**
Symptom: Application connects to dev database in production.
Cause: SPRING_PROFILES_ACTIVE not set in deployment; defaults to "default" profile
which inherits dev-like settings from base application.properties.
Fix: Explicitly set SPRING_PROFILES_ACTIVE in all deployment targets. Add
validation that fails startup if environment-specific required properties are missing.

**Failure 2: Bean not found with @Profile**
Symptom: NoSuchBeanDefinitionException for a bean with @Profile annotation.
Cause: The required profile is not active in the current environment.
Diagnosis: Print active profiles at startup (already logged by Spring Boot at INFO
level). Check spring.profiles.active setting.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - What is the default profile and when does it activate?

The "default" profile activates when NO other profiles are active.
application-default.properties is loaded for this profile.

Use it to make the application safe to run without any profile configuration:
- default profile: H2 in-memory database, mock external services, DEBUG logging
- Developers can run the app without setting any env vars

If any profile IS active, the default profile is NOT active. This is important:
if you add config to application-default.properties and activate "local" profile,
default config no longer loads. Avoid putting critical defaults in application-default.properties
that you also need in other profiles.

*What separates good from great:* Spring Boot logs active profiles at startup:
"The following profiles are active: prod". This is your first debugging step
when profile configuration seems wrong. If it shows "No active profile set,
falling back to 1 default profile: default", no profiles were set.

---

#### Q2 - How does @Profile interact with @Conditional?

@Profile is implemented as @Conditional(ProfileCondition.class). This means:
- @Profile and @Conditional can be combined
- @Conditional is more powerful (can check any condition: classpath, bean
  existence, property value, environment)

```java
// @Profile is syntactic sugar for:
@Conditional(ProfileCondition.class)
public @interface Profile { ... }

// More complex: active only in prod
// AND when property is set
@Bean
@Profile("prod")
@ConditionalOnProperty(
    name = "feature.cache.enabled",
    havingValue = "true")
public CacheService cacheService() { ... }
```

@ConditionalOnProperty is the most commonly combined annotation. This enables
feature flags that work across environments.

*What separates good from great:* Spring Security's SecurityAutoConfiguration
uses @Conditional extensively. Understanding @Conditional is key to
understanding how Spring Boot auto-configuration works. Every auto-configuration
class is a @Configuration with @Conditional guards.

---

#### Q3 - How do you activate profiles in different environments?

Priority order (highest wins, lower is overridden):

1. Command-line argument: `java -jar app.jar
   --spring.profiles.active=prod`

2. JVM system property: `java -Dspring.profiles.active=prod -jar app.jar`

3. Environment variable: `SPRING_PROFILES_ACTIVE=prod`
   (Spring Boot converts _ to . so this maps to spring.profiles.active)

4. In application.properties: `spring.profiles.active=dev`
   (lowest priority - gets overridden by env var)

5. Programmatic: `SpringApplication.setAdditionalProfiles("prod")`

Kubernetes deployment:
```yaml
env:
  - name: SPRING_PROFILES_ACTIVE
    value: prod
```

Docker Compose:
```yaml
environment:
  - SPRING_PROFILES_ACTIVE=dev
```

*What separates good from great:* SPRING_PROFILES_ACTIVE (env var) is the
best choice for containers: it works across Docker, Kubernetes, and CI/CD
without modifying the JAR. JVM args require modifying the entry point command.
Properties file activation is for development defaults only (overridable by env).

---

#### Q4 - How do profile groups work in Spring Boot 2.4+?

Profile groups allow one profile activation to trigger multiple related profiles:

```properties
# application.properties
spring.profiles.group.prod=\
  prod-db,prod-security,prod-observability
spring.profiles.group.dev=\
  dev-db,dev-mocks
```

When `SPRING_PROFILES_ACTIVE=prod`:
- prod profile is active
- prod-db, prod-security, prod-observability are also activated
- application-prod-db.properties, application-prod-security.properties, etc. are loaded

Use case: separate concerns. prod-db owns database config. prod-security owns
security config. prod-observability owns metrics/tracing config. Each can be
managed by different teams.

*What separates good from great:* Profile groups replace the old
spring.profiles.include which had confusing semantics. spring.profiles.include
was profile-scoped (could only be used inside a profile-specific document).
Groups are centrally defined in base config and easier to reason about.

---

#### Q5 - What changed in Spring Boot 2.4 regarding profile loading?

Spring Boot 2.4 introduced significant changes to config file loading:

**Breaking changes:**
1. Multi-document YAML: spring.profiles changed to
   `spring.config.activate.on-profile`
2. spring.profiles.include no longer works in profile-specific YAML documents
3. Profile-specific files have higher precedence than multi-document properties

Before (Spring Boot < 2.4):
```yaml
server.port: 8080
---
spring.profiles: prod
server.port: 80
```

After (Spring Boot 2.4+):
```yaml
server.port: 8080
---
spring.config.activate.on-profile: prod
server.port: 80
```

Migration: add spring.config.use-legacy-processing=true to restore old behavior
during migration.

*What separates good from great:* Spring Boot 2.4's config changes were the
most controversial Spring Boot release change in years. Many teams hit upgrade
failures. The spring.config.use-legacy-processing flag was added specifically
for migration. Knowing this exists - and why it was needed - signals production
experience.

---

#### Q6 - How do you test with Spring Profiles?

@ActiveProfiles in tests activates specific profiles:

```java
@SpringBootTest
@ActiveProfiles("test")
class OrderServiceIntegrationTest {
    // Loads application-test.properties
    // Activates @Profile("test") beans
}
```

```java
// application-test.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.jpa.hibernate.ddl-auto=create-drop
payment.service.mock=true
```

Profile-specific test beans:
```java
@TestConfiguration
public class TestServiceConfig {

    @Bean
    @Primary
    @Profile("test")
    public PaymentService mockPaymentService() {
        return Mockito.mock(PaymentService.class);
    }
}
```

*What separates good from great:* @Primary ensures the mock bean wins over
any non-mock bean for the same type in tests. Combining @TestConfiguration
(only loaded in tests) with @Profile("test") and @Primary is the pattern for
replacing production beans in integration tests without modifying production code.

---

#### Q7 - Can properties be set in profiles using environment variables?

Yes - profile-specific properties can reference environment variables:

```properties
# application-prod.properties
spring.datasource.url=\
  jdbc:postgresql://${DB_HOST}/orders
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASS}

# Fallback with default:
spring.datasource.url=\
  jdbc:postgresql://${DB_HOST:localhost}/orders
```

Property placeholder resolution: Spring resolves ${VARIABLE_NAME} from:
1. System properties
2. Environment variables
3. application.properties

This pattern separates structure (in properties files, committed to git) from
secrets (in environment variables, injected at runtime by CI/CD or secrets manager).

*What separates good from great:* The ${VAR:default} syntax provides a local
development default. DB_HOST defaults to localhost if not set. This lets
developers run without setting all env vars. Production sets all variables
explicitly. Never commit actual secrets to properties files - only the ${VAR}
placeholder syntax.

---

#### Q8 - How do Spring Cloud Config and profiles interact?

Spring Cloud Config Server adds a remote source for profile-specific properties:

Application with spring-cloud-starter-config fetches:
1. {app}-{profile}.properties from Config Server
2. {app}.properties from Config Server
3. Local application-{profile}.properties (override)
4. Local application.properties (lowest)

Config Server reads from Git, S3, Vault, or local filesystem.
Properties from Config Server are treated as higher priority than local files.

```yaml
# bootstrap.yml (loaded before application context)
spring:
  application:
    name: order-service
  config:
    import: "configserver:http://config-server:8888"
  profiles:
    active: prod
```

*What separates good from great:* Spring Cloud Config enables runtime
configuration refresh: change a property in Git, push, and running applications
can pick up the change via /actuator/refresh (with @RefreshScope on beans that
use the property). This is how feature flags can change without restarts in
microservice architectures.

---

#### Q9 - How do you verify which profile is active in a running application?

Multiple ways:

1. Startup logs (Spring Boot always logs at INFO):
   `The following profiles are active: prod`

2. Inject Environment and check:
   ```java
   @Autowired Environment env;
   String[] profiles = env.getActiveProfiles();
   ```

3. /actuator/env endpoint:
   Returns all environment properties including
   activeProfiles array

4. /actuator/info with management.info.env.enabled=true:
   Can expose active profiles as info

5. Programmatically in @Profile-annotated beans:
   The absence of a bean (NoSuchBeanDefinitionException
   or Optional.empty()) tells you that profile is inactive

*What separates good from great:* In Kubernetes, verifying active profile
is part of deployment validation. A pod that starts successfully but with
the wrong profile will use wrong infrastructure silently. Add a startup
log message from your own code that logs the active profiles and key
configuration values (sanitized - no secrets) as a deployment sanity check.

---

# Conditional Beans and @ConditionalOnX

---
id: SPR-021
title: Conditional Beans and @ConditionalOnX
category: Spring
difficulty: ★★☆
interview_weight: medium
asked_at: Mid/Senior
seniority: mid
tags: #spring-conditional, #auto-configuration, #conditionals, #spring-boot
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Medium-High — understanding @Conditional is key to
understanding Spring Boot auto-configuration and writing custom starters.

---

### 🎯 Model Answer

**30 seconds:**
> @ConditionalOnX annotations control whether a Spring bean is registered
> based on runtime conditions: classpath presence, existing beans, property
> values, or Java version. @ConditionalOnMissingBean allows your custom bean
> to override a default. This is the mechanism behind all Spring Boot
> auto-configuration: auto-configs only activate when their conditions are met.

**3 minutes (Senior):**
> @Conditional is the foundation of Spring Boot's auto-configuration system.
> Every Spring Boot auto-configuration class is annotated with @Conditional
> guards. When spring-boot-autoconfigure scans for configurations,
> @Conditional annotations determine whether each configuration class is
> processed.
>
> The most important ones: @ConditionalOnMissingBean activates a bean ONLY if
> no bean of that type exists yet. This allows Spring Boot's defaults to be
> overridden by user-defined beans. @ConditionalOnClass activates ONLY if
> a class is on the classpath. @ConditionalOnProperty activates based on
> property values. @ConditionalOnWebApplication activates only in web contexts.
>
> The order matters: @ConditionalOnMissingBean checks the existing bean
> definitions at the time the auto-configuration is processed. Auto-configurations
> are processed after user @Configuration classes. This ordering guarantee
> ensures user beans override auto-configured defaults.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - custom @Conditional implementations, custom auto-configuration
for library design, spring.factories / imports registration in Spring Boot 3.

*Adapting down:* Junior - "Spring Boot uses conditional annotations to decide
whether to create default beans. If you create your own bean of the same type,
Spring Boot backs off and uses yours instead."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about @ConditionalOnX - the conditional bean
registration mechanism in Spring Boot."

**(2) First principles:** "Spring Boot provides default infrastructure beans
(DataSource, MessageConverter, etc.) but must allow applications to override
them. Conditional annotations enable 'provide a default only if the user
hasn't provided one'."

**(3) Bridge:** "Conditional beans are like a smart buffet. If you brought
your own dish, the chef skips that station. If you didn't, the chef provides
a default. @ConditionalOnMissingBean is the 'did the guest bring this dish?'
check."

---

### 📘 Concept Explanation

**What it is:**
@Conditional and its Spring Boot specializations (@ConditionalOnX) are
annotations that make Spring bean registration conditional. A bean is only
registered when its conditions are satisfied at context startup.

**The problem it solves:**
Spring Boot must provide sensible defaults that work without configuration, yet
allow customization without modifying defaults. Without conditions, auto-configured
beans would conflict with user-defined beans. With conditions, auto-config backs
off when user code provides the same bean type.

**How it works:**

```
@Conditional resolution process:

1. Spring scans @Configuration classes
2. For each @Bean or @Configuration with @Conditional:
   a. Instantiate the Condition class
   b. Call Condition.matches(context, metadata)
   c. If true: register the bean definition
   d. If false: skip (bean not registered)

Built-in Spring Boot conditions:

@ConditionalOnClass(HikariDataSource.class)
  -> True if HikariCP is on classpath
  -> Used to activate HikariCP auto-config

@ConditionalOnMissingClass("com.example.X")
  -> True if class is NOT on classpath

@ConditionalOnBean(DataSource.class)
  -> True if a DataSource bean already exists
  -> Used to activate JPA only if DB is configured

@ConditionalOnMissingBean(DataSource.class)
  -> True if NO DataSource bean exists
  -> Used to provide default DataSource

@ConditionalOnProperty(
    name = "feature.cache.enabled",
    havingValue = "true",
    matchIfMissing = false)
  -> True if property equals "true"
  -> matchIfMissing=true means "enable by default"

@ConditionalOnWebApplication
  -> True in Servlet or Reactive web context

@ConditionalOnExpression("${x.enabled:false}")
  -> SpEL expression condition (flexible but slow)

@ConditionalOnResource(
    resources = "classpath:myconfig.xml")
  -> True if resource exists on classpath

Auto-configuration ordering:
  1. User @Configuration classes processed
  2. Auto-configuration classes processed (after user)
  3. @ConditionalOnMissingBean checks see user beans
  -> User beans take precedence over auto-config beans

Auto-configuration registration:
  Spring Boot 2.x: META-INF/spring.factories
    org.springframework.boot.autoconfigure
      .EnableAutoConfiguration=\
      com.example.MyAutoConfig

  Spring Boot 3.x: META-INF/spring/
    org.springframework.boot.autoconfigure
      .AutoConfiguration.imports
```

**The key insight:**
@ConditionalOnMissingBean is the key to Spring Boot's extensibility. The
autoconfigure module says "create DataSource only if no DataSource exists".
You create a DataSource @Bean in your application config. The autoconfigure
module detects it and backs off. This is the "opinionated defaults, easily
overridden" pattern.

**When to use it:**
- Custom Spring Boot starters: provide default beans that users can override
- Feature flags in application code via @ConditionalOnProperty
- Test configurations: @ConditionalOnMissingBean with @TestConfiguration

**When NOT to use it:**
- Do not use @ConditionalOnExpression for simple property checks - use
  @ConditionalOnProperty (faster)
- Do not use @Conditional for runtime feature flags - use them at startup
  configuration time only

**Alternatives:**
- @Profile: simpler for environment-based conditions
- Runtime feature flags: LaunchDarkly, Unleash (runtime, not startup)

---

### 💻 Code Example

```java
// Custom auto-configuration that can be overridden
@Configuration
@ConditionalOnClass(CacheManager.class)
@ConditionalOnMissingBean(CacheManager.class)
public class DefaultCacheAutoConfiguration {

    @Bean
    @ConditionalOnProperty(
        name = "cache.type",
        havingValue = "simple",
        matchIfMissing = true)  // default to simple
    public CacheManager simpleCacheManager() {
        return new SimpleCacheManager();
    }

    @Bean
    @ConditionalOnProperty(
        name = "cache.type",
        havingValue = "redis")
    @ConditionalOnClass(
        name = "org.springframework.data"
            + ".redis.cache.RedisCacheManager")
    public CacheManager redisCacheManager(
            RedisConnectionFactory factory) {
        return RedisCacheManager
            .builder(factory).build();
    }
}
```

> **Code walkthrough:** @ConditionalOnClass(CacheManager.class) means "only process
> this config if a CacheManager class exists on classpath". @ConditionalOnMissingBean
> means "only provide this bean if the application hasn't already defined a
> CacheManager". The property condition selects between simple and Redis
> implementations. matchIfMissing=true makes simple the default when no cache.type
> is set. If the user defines their own CacheManager @Bean, this entire
> configuration class is skipped.

```java
// Custom @Conditional for complex conditions
public class OnProductionEnvironment
        implements Condition {

    @Override
    public boolean matches(
            ConditionContext context,
            AnnotatedTypeMetadata metadata) {
        Environment env = context.getEnvironment();
        // Check both profile AND environment variable
        return Arrays.asList(
                env.getActiveProfiles())
            .contains("prod")
            && env.getProperty("PROD_VERIFIED",
               "false").equals("true");
    }
}

@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Conditional(OnProductionEnvironment.class)
public @interface ConditionalOnProduction { }

// Usage:
@Bean
@ConditionalOnProduction
public AuditService productionAuditService() {
    return new RealAuditService(auditDb);
}
```

> **Code walkthrough:** Custom Condition implementations enable conditions that
> don't fit the built-in @ConditionalOnX annotations. ConditionContext provides
> access to BeanFactory, ClassLoader, ResourceLoader, and Environment. The custom
> @ConditionalOnProduction meta-annotation wraps the condition for reuse. The
> condition checks both active profiles AND an environment variable - useful for
> preventing accidental prod bean activation in staging (profile=prod but
> PROD_VERIFIED not set).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> @ConditionalOnX annotations make Spring beans conditional. The most common
> ones: @ConditionalOnMissingBean (only create if this type doesn't already exist
> - used to let you override Spring Boot defaults), @ConditionalOnProperty
> (only create if a property is set to a value), @ConditionalOnClass (only create
> if a class is on the classpath). Spring Boot uses these internally so it can
> provide defaults without conflicting with your code.

*Push deeper:* Why is the ordering of user code vs auto-configuration important
for @ConditionalOnMissingBean to work correctly?

---

**Senior / Staff (5+ years):**
> @Conditional is the extensibility mechanism behind all Spring Boot auto-configuration.
> Key insight: auto-configurations are processed AFTER user @Configuration classes,
> so @ConditionalOnMissingBean sees user beans and correctly backs off. For custom
> starters: register your AutoConfiguration class in
> META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
> (Spring Boot 3) or META-INF/spring.factories (Spring Boot 2). Use @AutoConfiguration
> annotation (Spring Boot 3) instead of plain @Configuration. Use @AutoConfigureBefore/
> @AutoConfigureAfter for ordering dependencies between auto-configurations.

*Push deeper:* Spring Boot 3 dropped spring.factories for auto-configuration
registration in favor of the new imports file. Libraries that still use
spring.factories continue to work via a compatibility bridge, but new libraries
should use the new format. @ImportAutoConfiguration is used in tests to explicitly
import auto-configurations.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@ConditionalOnMissingBean always prevents conflicts."**
@ConditionalOnMissingBean is evaluated at the time the auto-configuration
class is processed. If two auto-configurations both have @ConditionalOnMissingBean
for the same type and both run before the other, one will win and the other will
back off. Ordering matters - use @AutoConfigureBefore/@AutoConfigureAfter.

**Misconception 2: "You can use @ConditionalOnProperty for runtime toggles."**
@Conditional is evaluated once at application startup during context refresh.
The condition result is permanent for the lifetime of the ApplicationContext.
For runtime feature toggling, use feature flag libraries or conditional logic
in the bean implementation, not @Conditional annotations.

**Misconception 3: "@ConditionalOnClass checks if the class can be instantiated."**
@ConditionalOnClass only checks if the class is present on the classpath (Class.forName
succeeds). The class might be on the classpath but fail to instantiate at runtime.
The condition checks presence, not functionality.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Auto-configuration not backing off (bean conflict)**
Symptom: NoUniqueBeanDefinitionException or wrong bean being injected.
Cause: User bean and auto-configured bean both registered.
Diagnosis: Check /actuator/conditions - negativeMatches should show
ConditionalOnMissingBean if user bean was found. positiveMatches shows
what auto-config fired.
Fix: Ensure user @Bean returns same type as auto-configured bean;
add @Primary if intentional coexistence.

**Failure 2: @ConditionalOnProperty not matching**
Symptom: Bean not registered even though property is set.
Cause: Property value doesn't exactly match havingValue (case-sensitive by default).
Diagnosis: Check /actuator/conditions negativeMatches - it shows the condition
that failed. Check /actuator/env for the actual property value.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How does Spring Boot auto-configuration use @Conditional internally?

Every Spring Boot auto-configuration class is a @Configuration annotated with
one or more @Conditional guards:

```java
// From spring-boot-autoconfigure source
@Configuration(proxyBeanMethods = false)
@ConditionalOnClass({DataSource.class,
    EmbeddedDatabaseType.class})
@ConditionalOnMissingBean(type = {
    "io.r2dbc.spi.ConnectionFactory"})
@EnableConfigurationProperties(DataSourceProperties.class)
@Import({DataSourcePoolMetadataProvidersConfiguration.class,
    DataSourceCheckpointRestoreConfiguration.class})
public class DataSourceAutoConfiguration {
    ...
    @ConditionalOnMissingBean(DataSource.class)
    @ConditionalOnSingleCandidate(EmbeddedDatabaseType.class)
    static class EmbeddedDatabaseConfiguration { ... }
}
```

DataSourceAutoConfiguration only activates if:
1. DataSource class is on classpath (JPA dependency pulls it in)
2. No reactive R2DBC ConnectionFactory exists
3. Within it, embedded database config only if no DataSource bean already exists

*What separates good from great:* Reading Spring Boot auto-configuration source
code is the best way to understand how Spring Boot works. The source is readable
and the conditions tell the exact story of why something activates. Start with
DataSourceAutoConfiguration, JacksonAutoConfiguration, or WebMvcAutoConfiguration.

---

#### Q2 - What is the difference between @ConditionalOnBean and @ConditionalOnMissingBean?

@ConditionalOnBean - "register me only IF this bean exists":
- Use case: your bean depends on another (optional) bean being available
- Example: SecurityAuditService - only create if AuditRepository bean exists

@ConditionalOnMissingBean - "register me only IF this bean does NOT exist":
- Use case: provide a default that can be overridden
- Example: provide default CacheManager only if no CacheManager is defined

Order sensitivity: both are sensitive to evaluation order.
@ConditionalOnMissingBean works correctly for auto-configuration because Spring
Boot processes user @Configuration before auto-configuration classes.

*What separates good from great:* The common mistake: placing @ConditionalOnBean
on a bean that both depends on another bean AND is in the same configuration class.
Bean ordering within a single @Configuration class is not guaranteed. The condition
may be evaluated before the depended-on bean is registered. Use separate
@Configuration classes with @AutoConfigureAfter to establish ordering.

---

#### Q3 - How do you create a custom auto-configuration?

Three files needed:

1. Auto-configuration class:
```java
@AutoConfiguration  // Spring Boot 3+
@ConditionalOnClass(MyLibraryClient.class)
@EnableConfigurationProperties(MyLibraryProperties.class)
public class MyLibraryAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public MyLibraryClient myLibraryClient(
            MyLibraryProperties props) {
        return new MyLibraryClient(
            props.getEndpoint(),
            props.getApiKey());
    }
}
```

2. Properties class:
```java
@ConfigurationProperties(prefix = "my.library")
public class MyLibraryProperties {
    private String endpoint;
    private String apiKey;
    // getters + setters
}
```

3. Registration file (Spring Boot 3):
`META-INF/spring/org.springframework.boot
.autoconfigure.AutoConfiguration.imports`:
```
com.example.MyLibraryAutoConfiguration
```

*What separates good from great:* @AutoConfiguration (Spring Boot 3) adds
proxyBeanMethods=false by default (avoids CGLIB proxy overhead) and registers
the class for deferred loading. @AutoConfigureBefore/@AutoConfigureAfter control
ordering between auto-configurations. Adding @AutoConfigureOrder provides numeric
ordering within the same level.

---

#### Q4 - How do you debug why an auto-configuration did or did not activate?

Three methods:

1. /actuator/conditions endpoint (production-safe):
   GET /actuator/conditions
   -> positiveMatches: activated configurations + reasons
   -> negativeMatches: not-activated + which condition failed

2. Debug flag (development):
   java -jar app.jar --debug
   OR debug=true in application.properties
   Prints the full Conditions Evaluation Report to console at startup.

3. ConditionEvaluationReport bean:
```java
@Autowired
ConditionEvaluationReport report;

report.getConditionAndOutcomesBySource()
    .forEach((src, outcomes) ->
        log.info("{}: {}", src, outcomes));
```

*What separates good from great:* The conditions report shows not just IF a
configuration activated, but WHY or WHY NOT. "Did not match: @ConditionalOnMissingBean
(types: javax.sql.DataSource; SearchStrategy: all) found beans: dataSource" tells
you exactly which bean caused the condition to fail and what type it was.

---

#### Q5 - How does @ConditionalOnProperty work with matchIfMissing?

@ConditionalOnProperty with matchIfMissing controls behavior when the property
is absent:

```java
// Only activate if property equals "true"
// If property is absent: NOT activated (default)
@ConditionalOnProperty(
    name = "feature.advanced.enabled",
    havingValue = "true")
public class AdvancedFeatureConfig { ... }

// Activate by default unless explicitly disabled
// If property is absent: ACTIVATED
// Only deactivated if: feature.cache.enabled=false
@ConditionalOnProperty(
    name = "feature.cache.enabled",
    havingValue = "true",
    matchIfMissing = true)
public class DefaultCacheConfig { ... }
```

matchIfMissing=true = "opt-out" feature (active unless you turn it off)
matchIfMissing=false = "opt-in" feature (inactive unless you turn it on)

*What separates good from great:* Spring Boot's own auto-configurations
use both patterns. matchIfMissing=true is used for features that should be
active by default (HikariCP connection pool). matchIfMissing=false is used
for optional features (H2 console: spring.h2.console.enabled=true is required
explicitly). Choosing the right default is a UX decision for library authors.

---

#### Q6 - What is @ConditionalOnWebApplication and when does it matter?

@ConditionalOnWebApplication activates only when the application context is
a web application context:

```java
@ConditionalOnWebApplication(
    type = ConditionalOnWebApplication.Type.SERVLET)
public class MvcAutoConfiguration { ... }

@ConditionalOnWebApplication(
    type = ConditionalOnWebApplication.Type.REACTIVE)
public class WebFluxAutoConfiguration { ... }
```

Types:
- SERVLET: traditional Spring MVC / Tomcat
- REACTIVE: Spring WebFlux / Netty
- ANY: either type

This prevents web-specific beans from loading in:
- Batch applications (no web context)
- CLI applications with SpringApplicationBuilder
- Non-web components of a larger system

*What separates good from great:* Spring Boot detects the web application
type automatically by checking classpath: DispatcherServlet = Servlet, 
DispatcherHandler = Reactive, neither = non-web. You can override with
spring.main.web-application-type=none to disable web context even if
web dependencies are on the classpath.

---

#### Q7 - How do @ConditionalOnX annotations interact when multiple are present?

Multiple @ConditionalOnX annotations on a single class/method are AND-combined.
All conditions must be true for the bean to register:

```java
@Bean
@ConditionalOnClass(RedisCacheManager.class)
@ConditionalOnMissingBean(CacheManager.class)
@ConditionalOnProperty(
    name = "spring.cache.type",
    havingValue = "redis")
public CacheManager redisCacheManager(...) { ... }
```

All three must be true:
- RedisCacheManager on classpath
- No CacheManager already defined
- spring.cache.type=redis

For OR logic, use @ConditionalOnExpression with SpEL:
```java
@ConditionalOnExpression(
    "${feature.redis.enabled:false} || "
    + "${feature.cache.type:'none'}"
    + " == 'redis'")
```

Or implement a custom Condition:
```java
@Conditional(RedisOrHazelcastCondition.class)
```

*What separates good from great:* @AnyNestedCondition and @AllNestedConditions
are meta-conditions that allow composing conditions with OR and AND logic
using nested condition classes. This is cleaner than SpEL for complex conditions
and testable as plain Java.

---

#### Q8 - How do you override a Spring Boot auto-configured bean?

Three patterns:

Pattern 1 - Define the same type (most common):
```java
// Spring Boot provides a default DataSource.
// You define one -> Boot backs off via
// @ConditionalOnMissingBean(DataSource.class)
@Bean
public DataSource dataSource() {
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl(customUrl);
    return new HikariDataSource(config);
}
```

Pattern 2 - Exclude auto-configuration explicitly:
```java
@SpringBootApplication(exclude = {
    DataSourceAutoConfiguration.class
})
```

Pattern 3 - Use application.properties overrides:
```properties
# Many auto-configs expose properties to
# customize behavior without full override
spring.datasource.hikari.maximum-pool-size=50
spring.datasource.hikari.minimum-idle=10
```

*What separates good from great:* Excluding auto-configuration should be a
last resort. It breaks the intent of auto-configuration and requires you to
configure everything manually. Prefer defining a bean of the same type (triggers
@ConditionalOnMissingBean) or using the exposed configuration properties. If
a Spring Boot auto-configuration doesn't have a property for what you need,
the right approach is to check if there is a property that was added in a newer
version - auto-configurations evolve with each Spring Boot release.

---

#### Q9 - How do you write unit tests for @Conditional configurations?

Test auto-configuration with ApplicationContextRunner:

```java
class MyAutoConfigurationTest {

    private final ApplicationContextRunner contextRunner =
        new ApplicationContextRunner()
            .withConfiguration(
                AutoConfigurations.of(
                    MyAutoConfiguration.class));

    @Test
    void backsOffWhenBeanAlreadyDefined() {
        contextRunner
            .withUserConfiguration(
                UserProvidedConfig.class)
            .run(ctx -> {
                assertThat(ctx)
                    .hasSingleBean(MyService.class);
                assertThat(ctx)
                    .getBean(MyService.class)
                    .isInstanceOf(CustomMyService.class);
            });
    }

    @Test
    void providesDefaultWhenNoUserBean() {
        contextRunner
            .run(ctx -> {
                assertThat(ctx)
                    .hasSingleBean(MyService.class);
                assertThat(ctx)
                    .getBean(MyService.class)
                    .isInstanceOf(DefaultMyService.class);
            });
    }

    @Configuration
    static class UserProvidedConfig {
        @Bean public MyService myService() {
            return new CustomMyService();
        }
    }
}
```

*What separates good from great:* ApplicationContextRunner is the correct
testing tool for auto-configurations. It creates a lightweight application
context without starting a full Spring Boot application. withPropertyValues(),
withClassLoader(), withSystemProperties() let you control the condition inputs.
The fluent assertions from assertThat(ctx) are specific to context content.
This is the testing pattern used by Spring Boot's own test suite.
