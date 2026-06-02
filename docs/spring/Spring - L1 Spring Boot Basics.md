---
layout: default
title: "Spring - L1 Spring Boot Basics"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 3
permalink: /spring/l1-spring-boot-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L1 Spring Boot Basics](#spring---l1-spring-boot-basics) | medium |
| 2 | [Spring Boot Auto-configuration](#spring-boot-auto-configuration) | medium |
| 3 | [@SpringBootApplication](#springbootapplication) | medium |
| 4 | [Embedded Server](#embedded-server) | medium |

---

# Spring Boot Auto-configuration

---
id: SPR-007
title: Spring Boot Auto-configuration
category: Spring
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #spring-boot, #auto-configuration, #conditional, #starter
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - auto-configuration is what makes Spring Boot
different from Spring Framework. Every Spring Boot interview covers this.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Boot auto-configuration automatically configures your application
> based on what is on your classpath. If you add spring-boot-starter-data-jpa,
> Boot detects Hibernate and creates a DataSource, EntityManagerFactory, and
> transaction manager with sensible defaults - without you writing a single
> line of configuration. You only override what you want to customise.

**3 minutes (Senior):**
> Auto-configuration is implemented as @Configuration classes annotated with
> @Conditional variants. For example, HibernateJpaAutoConfiguration is only
> activated when HibernateEntityManagerFactory is on the classpath AND no
> custom EntityManagerFactory bean is defined. This conditional logic is what
> makes auto-configuration non-invasive: your explicit @Bean definitions always
> take precedence over auto-configured beans.
>
> At startup, Spring Boot reads a list of auto-configuration candidates from
> META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
> (Boot 2.7+). Each candidate class is evaluated for its @Conditional conditions.
> Only those matching all conditions are applied. This is pure Spring - just
> @Configuration classes with conditions. No magic.
>
> The trade-off: convenience at the cost of predictability. When auto-
> configuration activates something you did not expect, debugging requires
> understanding conditions. Spring Boot's --debug flag and /actuator/conditions
> endpoint show exactly which configurations fired and why - this is the
> essential diagnostic tool.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - discuss creating custom auto-configuration for internal
libraries: how to write @ConditionalOnMissingBean checks to allow user override,
and the ordering implications of @AutoConfigureBefore/@AutoConfigureAfter.

*Adapting down:* Junior - "Boot looks at what libraries you have added and
automatically sets everything up. You don't have to write configuration code
for common setups - Boot guesses sensible defaults."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Boot auto-configuration - what
problem it solves and how it works."

**(2) First principles:** "Every application needs infrastructure setup: data
sources, serializers, security configs. Writing these for every project is
boilerplate. Auto-configuration is that boilerplate, pre-written and
conditionally applied."

**(3) Bridge:** "This is like convention-over-configuration in Rails or
sensible defaults in Kotlin. Spring Boot reads the situation (your classpath)
and makes reasonable decisions."

---

### 📘 Concept Explanation

**What it is:**
Auto-configuration is Spring Boot's mechanism to automatically configure Spring
beans based on classpath contents, existing beans, and property values. It
eliminates the boilerplate configuration code required in plain Spring Framework.

**The problem it solves:**
Every Spring application needed the same boilerplate: create a DataSource, wrap
it in an EntityManagerFactory, add a TransactionManager, create a JdbcTemplate,
configure Jackson ObjectMapper. This was hundreds of lines of XML or @Bean methods
repeated in every project. Auto-configuration provides all of this from a single
starter dependency, overrideable where needed.

**How it works:**

```
Spring Boot startup - auto-config activation:

1. SpringApplication reads AutoConfiguration.imports
   (~100+ auto-config classes listed)

2. For each class, Spring evaluates @Conditional:

   @ConditionalOnClass(DataSource.class)
     -> only if DataSource is on classpath

   @ConditionalOnMissingBean(DataSource.class)
     -> only if YOU haven't defined a DataSource bean

   @ConditionalOnProperty("spring.datasource.url")
     -> only if property is set

3. Conditions all pass? -> @Configuration class activates
   -> its @Bean methods create beans

4. Your explicit @Bean always wins
   (ConditionalOnMissingBean ensures this)
```

> **Code walkthrough:** This Spring Boot Auto-configuration example demonstrates a key concept in practice using Spring annotation. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
@ConditionalOnMissingBean is the override mechanism. Auto-configuration always
checks if you have already defined a bean before creating one. Your explicit
configuration always wins over auto-configuration. This makes Boot both
convenient (does the right thing by default) and overrideable (you can
always take control).

**When to use it:**
- Default: rely on auto-configuration for all standard Spring Boot features
- You should rarely need to write @Bean configuration for standard Spring
  features - if you are, check if auto-configuration already handles it

**When NOT to use it:**
- When the default auto-configuration conflicts with your requirements
- When you need explicit control over object creation order or configuration
- Exclude specific auto-configurations that conflict: spring.autoconfigure.exclude

**Alternatives:**
- Spring Framework without Boot: full manual @Bean configuration
- Quarkus/Micronaut: compile-time configuration instead of runtime conditionals

**First-principles derivation:**
Any framework that wants to "just work" needs a way to configure itself based
on available libraries. Runtime classpath detection (isClassPresent) + Spring's
@Conditional mechanism is the cleanest solution: evaluate conditions at startup,
activate matching configurations, allow user override via ConditionalOnMissing.

---

### 💻 Code Example

```java
// What auto-configuration replaces (manual Spring Framework config)
@Configuration
public class ManualDataConfig {
    // You had to write ALL of this before Boot:
    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://localhost/mydb");
        ds.setUsername("user");
        ds.setPassword("pass");
        return ds;
    }
    @Bean
    public LocalContainerEntityManagerFactoryBean emf(
            DataSource ds) { /* ... */ }
    @Bean
    public PlatformTransactionManager txManager(
            EntityManagerFactory emf) { /* ... */ }
}
```

> **Code walkthrough:** This is all the boilerplate Spring Boot auto-ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> configuration eliminates. With spring-boot-starter-data-jpa and
> application.properties containing spring.datasource.url, Boot creates
> all of this automatically. The developer adds the starter and writes
> the properties - nothing more.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// GOOD: Spring Boot auto-configuration in action
// application.properties:
// spring.datasource.url=jdbc:postgresql://localhost/mydb
// spring.datasource.username=user
// spring.datasource.password=pass
// spring.jpa.hibernate.ddl-auto=validate

// That is all you need. Boot auto-configures:
// - HikariCP DataSource (connection pool)
// - Hibernate EntityManagerFactory
// - JpaTransactionManager
// - Spring Data repositories

// Override one piece: provide your own DataSource bean
@Configuration
public class CustomDataConfig {
    @Bean  // This overrides auto-configured DataSource
    public DataSource dataSource() {
        // Your custom DataSource setup
        HikariDataSource ds = new HikariDataSource();
        ds.setMaximumPoolSize(50); // custom pool size
        ds.setJdbcUrl(
            "jdbc:postgresql://primary-db/mydb");
        return ds;
    }
    // Boot auto-configures everything else that needs
    // a DataSource - using your custom one
}
```

> **Code walkthrough:** Auto-configuration in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> is all that's needed for a working database connection. The custom DataSource
> @Bean shows the override mechanism - Boot's @ConditionalOnMissingBean
> checks if a DataSource bean already exists. Since you defined one, Boot's
> auto-configured DataSource is skipped. Boot then auto-configures the
> EntityManagerFactory using your DataSource.

```java
// Diagnosing auto-configuration: what fired and why
// Run: java -jar app.jar --debug
// Output includes:
// ============================
// CONDITIONS EVALUATION REPORT
// ============================
// Positive matches:
//  HibernateJpaAutoConfiguration
//   - @ConditionalOnClass Hibernate found
//   - @ConditionalOnMissingBean no EntityManagerFactory
// Negative matches:
//  MongoAutoConfiguration
//   - @ConditionalOnClass MongoDB driver NOT found

// Or at runtime via Actuator:
// GET /actuator/conditions
```

> **Code walkthrough:** The --debug flag is the essential auto-configurationice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> diagnostic tool. It prints every auto-configuration class that was
> evaluated, whether it matched, and exactly which condition passed or failed.
> When auto-configuration does something unexpected (or fails to activate
> something you expected), this report is the first place to look.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Boot auto-configuration automatically sets up your application based
> on what libraries you have added. Add the JPA starter and Spring Boot
> creates a database connection and repository support automatically. You
> configure it via application.properties. If you need to customise something,
> define your own @Bean and Spring Boot's default is skipped.

*Push deeper:* Explain the @ConditionalOnMissingBean mechanism - Boot only
auto-configures things you have not already configured yourself.

---

**Senior / Staff (5+ years):**
> Auto-configuration is implemented as @Configuration classes with @Conditional
> annotations evaluated at startup. Each auto-configuration candidate is listed
> in AutoConfiguration.imports and evaluated in order. The key design invariant
> is that user configuration always wins over auto-configuration via
> @ConditionalOnMissingBean. When debugging, --debug mode or /actuator/conditions
> shows exactly which conditions passed and failed for every auto-configuration.
> Creating custom auto-configuration for internal libraries follows the same
> pattern: write a @Configuration class, add appropriate @Conditional checks,
> and register it in your starter's AutoConfiguration.imports file.

*Push deeper:* Ordering: @AutoConfigureBefore and @AutoConfigureAfter control
the order auto-configurations apply. Important when one auto-config creates a
bean that another depends on. Also discuss: Spring Boot 3 AOT (Ahead-of-Time)
compilation pre-processes conditions at build time, generating bean definitions
without runtime classpath scanning. This is how GraalVM native images work with
Spring Boot.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Auto-configuration is magic you cannot control."**
Every auto-configuration class is readable Java code in the spring-boot-
autoconfigure jar. You can read exactly what it does, which conditions activate
it, and how to override it. The /actuator/conditions endpoint and --debug flag
make the decision-making fully visible.

**Misconception 2: "You cannot turn off specific auto-configurations."**
You can exclude any auto-configuration via:
- @SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})
- spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.
  jdbc.DataSourceAutoConfiguration

**Misconception 3: "Auto-configuration means you don't need to understand
what is being configured."**
In production, you need to understand what auto-configuration created to
debug issues, tune performance, and understand security implications.
Relying on auto-configuration without understanding it leads to security
misconfigurations and performance problems.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Auto-configuration not activating expected beans**
Symptom: Expected bean (DataSource, EntityManagerFactory) not created.
Cause: @Conditional check failed - likely missing classpath dependency or
conflicting bean definition.
Diagnosis: Run with --debug to see the Conditions Evaluation Report.
Check if the required class is on classpath (wrong dependency version,
excluded transitive, etc.).

**Failure 2: Conflicting auto-configurations**
Symptom: Two auto-configurations both try to create the same bean type.
Cause: Two starters that provide the same functionality included simultaneously.
Diagnosis: /actuator/conditions shows both firing; Spring throws
NoUniqueBeanDefinitionException.
Fix: Exclude one auto-configuration explicitly.

**Failure 3: Property placeholder not resolved**
Symptom: Bean created with ${...} literal instead of actual value.
Cause: Auto-configuration ran before PropertySourcesPlaceholderConfigurer,
or the property file is not on the classpath.
Fix: Ensure application.properties is in src/main/resources; check property
key spelling.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is Spring Boot auto-configuration?**

beans based on classpath content, existing beans, and property values.
Implementation: @Configuration classes annotated with @Conditional variants
(@ConditionalOnClass, @ConditionalOnMissingBean, @ConditionalOnProperty etc.)
listed in META-INF/spring/AutoConfiguration.imports.

At startup, Spring Boot reads this list, evaluates conditions for each, and
activates only those where all conditions pass. The result: sensible defaults
for common setups with no configuration code required.

*What separates good from great:* Auto-configuration is not unique to Spring Boot
- it is just Spring's @Configuration + @Conditional mechanism used systematically.
Every Spring Framework application could implement the same pattern. Boot just
provides 100+ pre-written configurations and the framework to discover them.

---

**[JUNIOR] Q2 - [CONCEPTUAL] How does Spring Boot auto-configuration know what to configure?**

Two mechanisms work together:

1. **Classpath detection**: @ConditionalOnClass checks if a specific class is
   present. If spring-boot-starter-web is included, Spring MVC and Tomcat
   classes are present, so WebMvcAutoConfiguration activates.

2. **Bean absence check**: @ConditionalOnMissingBean ensures auto-configuration
   only activates when you haven't defined a conflicting bean. If you define
   your own DataSource, DataSourceAutoConfiguration is skipped.

The discovery mechanism: SpringFactoriesLoader reads
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
from all JARs on the classpath. This file lists auto-configuration class names.
Spring Boot 3 changed from spring.factories to this dedicated file for clarity.

*What separates good from great:* The SpringFactoriesLoader mechanism is also
used for ApplicationListeners, ApplicationContextInitializers, and FailureAnalyzers.
Understanding this mechanism explains how third-party libraries plug into Spring
Boot without any registration code in your application.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How do you override or disable auto-configuration?**

Three ways:

1. **Define your own bean** (implicit override):
   Spring Boot's @ConditionalOnMissingBean checks for an existing bean before
   auto-configuring. Define a @Bean of the same type - auto-config skips.

2. **Explicit exclude**:
   ```java
   @SpringBootApplication(exclude = {
       DataSourceAutoConfiguration.class
   })
   ```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

   Or in application.properties:
   `spring.autoconfigure.exclude=...DataSourceAutoConfiguration`

3. **Conditional properties**:
   Many auto-configurations check @ConditionalOnProperty.
   Setting the right property can enable or disable them.

*What separates good from great:* When excluding auto-configuration, you take
responsibility for providing the beans it would have created. Excluding
DataSourceAutoConfiguration without providing your own DataSource will cause
NoSuchBeanDefinitionException when anything tries to inject a DataSource.

---

**[MID] Q4 - [DEBUGGING] How do you debug which auto-configurations are active?**

Three methods:

1. **--debug flag**: `java -jar app.jar --debug` or `spring.main.debug=true`.
   Prints the CONDITIONS EVALUATION REPORT showing positive matches (activated),
   negative matches (not activated and why), and unconditional classes.

2. **/actuator/conditions endpoint**: Same report as /actuator/conditions.
   Requires spring-boot-starter-actuator and exposure configuration.

3. **@SpringBootTest(properties = "logging.level.root=DEBUG")**: In tests,
   activate debug logging to see condition evaluation in test output.

Reading the conditions report: "Positive matches" shows what fired. "Negative
matches" shows what did not and which condition failed. Mostly you read the
negative matches to find why something expected did not activate.

*What separates good from great:* The conditions report is not just for
debugging - it is useful for security audits. Check which auto-configurations
are active in a production build to ensure no unexpected feature is enabled.

---

**[MID] Q5 - [CONCEPTUAL] What is the difference between @ConditionalOnClass and @ConditionalOnMissingClass?**

@ConditionalOnClass(X.class): configuration activates only if class X IS on
the classpath. Used to tie auto-configuration to library presence.

@ConditionalOnMissingClass("com.example.X"): configuration activates only if
class X is NOT on the classpath. Note: the parameter is a String to avoid
compilation failure when the class is absent - you cannot reference a class
in a @ConditionalOnClass annotation if the class might not compile.

Common pattern: provide a default implementation that is replaced when a
specific library is present:
```java
@ConditionalOnMissingClass("com.fasterxml.jackson.databind.ObjectMapper")
class FallbackSerializerConfig { ... }

@ConditionalOnClass(ObjectMapper.class)
class JacksonSerializerConfig { ... }
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Both annotations use String form when there
is a risk the class might not be on the classpath during compilation of the
auto-configuration module itself. The condition evaluation happens at runtime
where the class is either present or not.

---

**[MID] Q6 - [CONCEPTUAL] What is a Spring Boot starter and how does it relate to auto-configuration?**

A starter is a convenience POM that:
1. Pulls in the right set of transitive dependencies for a feature
2. Includes (directly or transitively) the spring-boot-autoconfigure artifact
   which contains the auto-configuration classes

Example: spring-boot-starter-web includes:
- spring-webmvc (Spring MVC classes)
- spring-boot-starter-tomcat (embedded Tomcat)
- jackson-databind (JSON serialization)
- hibernate-validator (bean validation)
- spring-boot-autoconfigure (contains WebMvcAutoConfiguration etc.)

The starter handles dependency management; auto-configuration handles bean
creation. They are complementary: the starter puts the right classes on the
classpath; auto-configuration detects those classes and creates the beans.

*What separates good from great:* Custom starters for internal libraries follow
the same pattern. Create a -autoconfigure module with the auto-configuration
class (registered in AutoConfiguration.imports) and a -starter module with
the dependency on your library and the -autoconfigure module. Teams consuming
your library get auto-configuration for free.

---

**[SENIOR] Q7 - [CONCEPTUAL] What are the performance implications of auto-configuration?**

Auto-configuration has two startup costs:

1. **Classpath scanning**: Spring Boot reads AutoConfiguration.imports from
   all JARs, evaluates conditions for each class. With ~130 auto-configuration
   candidates and their conditional checks, this adds 50-200ms to startup.

2. **Bean creation**: Each activated auto-configuration creates beans, which
   have their own initialization cost.

Optimizations:
- `spring.jmx.enabled=false`: disable JMX if not needed (saves 50ms)
- `spring.data.jpa.repositories.bootstrap-mode=lazy`: lazy repository bootstrap
- Exclude unused auto-configurations explicitly
- Spring Boot 3 AOT: pre-processes conditions at build time, generating source
  for beans instead of runtime reflection. Dramatically reduces startup time
  for GraalVM native images.
- @SpringBootApplication(proxyBeanMethods = false): faster context creation
  when inter-@Bean method calls are not needed.

*What separates good from great:* Spring Boot 3 AOT compilation is the future
of Boot performance. It moves condition evaluation and bean definition generation
to build time, producing a pre-computed bean factory that starts without
classpath scanning. This is what enables fast cold starts in serverless and
sub-100ms startup in GraalVM native images.

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


# @SpringBootApplication

---
id: SPR-008
title: "@SpringBootApplication"
category: Spring
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #spring-boot, #annotation, #component-scan, #auto-configuration
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - "What does @SpringBootApplication do?" is a
standard warm-up question in Spring Boot interviews.

---

### 🎯 Model Answer

**30 seconds:**
> @SpringBootApplication is a convenience annotation that combines three
> annotations: @Configuration (marks the class as a source of bean definitions),
> @EnableAutoConfiguration (activates Spring Boot auto-configuration), and
> @ComponentScan (scans the current package and sub-packages for @Component
> classes). It is the single annotation needed to bootstrap a Spring Boot
> application.

**3 minutes (Senior):**
> @SpringBootApplication is a meta-annotation - it does not add any logic
> itself but aggregates three annotations that configure different aspects of
> the application context.
>
> @Configuration makes the class a source of @Bean definitions - you can add
> @Bean methods directly to your Application class, though this is discouraged
> for cleanliness.
>
> @EnableAutoConfiguration tells Spring Boot to start adding beans based on
> classpath settings, other beans, and various property settings. It imports
> the AutoConfigurationImportSelector which reads the AutoConfiguration.imports
> file and processes all auto-configuration candidates.
>
> @ComponentScan without arguments scans the package of the annotated class
> and all sub-packages. This is why placing your main class in the root package
> is the Spring Boot convention - it ensures all your @Component, @Service,
> @Repository, @Controller classes are discovered.
>
> The important implication: the placement of your Application class matters.
> Classes in parent packages of the application main class are NOT scanned.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers discuss the scanBasePackages attribute for
multi-module projects, and proxyBeanMethods = false optimization.

*Adapting down:* Junior - "@SpringBootApplication is the one annotation that
starts your Spring Boot application. It tells Spring to scan for components
and set up everything automatically."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking what @SpringBootApplication does - it is
really three annotations combined."

**(2) First principles:** "Any Spring Boot app needs three things: a place to
define beans (@Configuration), the auto-config activation (@EnableAutoConfig),
and component discovery (@ComponentScan)."

**(3) Bridge:** "Think of it as the main() of Spring configuration. Just as
main() is the entry point for Java, @SpringBootApplication is the entry point
for Spring configuration."

---

### 📘 Concept Explanation

**What it is:**
@SpringBootApplication is a composed annotation (meta-annotation) that combines
@Configuration, @EnableAutoConfiguration, and @ComponentScan with their typical
defaults into a single convenient annotation.

**The problem it solves:**
Every Spring Boot application needed the same three annotations. Combining them
into one reduces boilerplate and makes the intent clear: this is a Spring Boot
application main class.

**How it works:**

```java
// What @SpringBootApplication expands to:
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Configuration
@EnableAutoConfiguration
@ComponentScan
public @interface SpringBootApplication {
    // Delegates to @ComponentScan
    String[] scanBasePackages() default {};
    Class<?>[] scanBasePackageClasses() default {};
    // Delegates to @EnableAutoConfiguration
    Class<?>[] exclude() default {};
    // Delegates to @Configuration
    boolean proxyBeanMethods() default true;
}
```

> **Code walkthrough:** This @SpringBootApplication example demonstrates contract definition using Spring annotation. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

**The key insight:**
The class annotated with @SpringBootApplication defines the component scan
root. Every @Component class in the same package OR any sub-package is
discovered automatically. Packages ABOVE the main class package are not
scanned. This placement convention is why Spring Boot starter projects
always put Application.java in the root package.

**When to use it:**
- The main class of every Spring Boot application
- Never on other classes - one per application entry point

**When NOT to use it:**
- Never on internal classes that are not the application entry point
- In multi-module Maven projects where services are in separate modules,
  configure scanBasePackages explicitly

**Alternatives:**
- Use the three individual annotations when you need different component scan
  configuration than the defaults
- @SpringBootConfiguration + @EnableAutoConfiguration + @ComponentScan

**First-principles derivation:**
@SpringBootApplication exists purely to reduce repetitive annotation overhead.
It has no logic itself; it is a shortcut for three separate annotations. Any
Spring Boot application could work identically with the three separate
annotations - @SpringBootApplication just makes it cleaner.

---

### 💻 Code Example

```java
// Standard Spring Boot application - minimal
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
// This single class + annotation does:
// 1. Creates and refreshes the ApplicationContext
// 2. Enables auto-configuration (reads classpath)
// 3. Scans com.example.* and sub-packages for components
// 4. Starts embedded Tomcat (if spring-webmvc on classpath)
```

> **Code walkthrough:** The minimal Spring Boot application. @SpringBootApplication
> combines all configuration. SpringApplication.run() creates the context, runs
> the refresh, starts the embedded server, and returns. The five lines of code
> bootstrap a complete web application - everything else comes from auto-config
> and component scanning.

```java
// Customising scan scope and excluding auto-configs
@SpringBootApplication(
    scanBasePackages = {
        "com.example.orders",
        "com.example.payments"
    },
    exclude = {
        DataSourceAutoConfiguration.class,
        SecurityAutoConfiguration.class
    }
)
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    // Optional: @Bean methods can go here
    // (prefer separate @Configuration classes)
    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
```

> **Code walkthrough:** scanBasePackages explicitly specifies which packagesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to scan - useful for multi-module projects where your code is not in the
> same package hierarchy as the main class. exclude removes specific auto-
> configurations - here, DataSourceAutoConfiguration is excluded for a service
> that doesn't use a database, preventing startup failure when no JDBC URL
> is configured.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> @SpringBootApplication is the main annotation in Spring Boot. It combines
> three annotations: @Configuration (this class can define beans), @EnableAutoConfiguration
> (activate Spring Boot's automatic setup), and @ComponentScan (find all @Service
> and @Component classes in this package and sub-packages). Every Spring Boot
> app has exactly one class with this annotation.

*Push deeper:* Explain that the placement of the class with @SpringBootApplication
matters because @ComponentScan scans from that package downward.

---

**Senior / Staff (5+ years):**
> @SpringBootApplication is a composed annotation - it has no behaviour itself
> but combines @Configuration, @EnableAutoConfiguration, and @ComponentScan.
> The placement of the annotated class defines the component scan root.
> @EnableAutoConfiguration triggers the AutoConfigurationImportSelector which
> processes AutoConfiguration.imports at context startup. The proxyBeanMethods
> = false attribute disables CGLIB proxying of @Bean methods when inter-method
> calls are not needed - this can reduce startup time in large applications by
> skipping CGLIB subclass generation.

*Push deeper:* In Spring Boot 3 with AOT, the Application class itself is
processed at build time. The SpringApplication.run() call in GraalVM native
images uses pre-generated bean definitions rather than runtime classpath scanning,
making the placement of @SpringBootApplication even more important for build-time
analysis.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Classes in parent packages are automatically scanned."**
@ComponentScan only scans the annotated class's package and sub-packages. If
your Application class is in com.example and a component is in com.util, it
will NOT be discovered unless you configure scanBasePackages.

**Misconception 2: "You should add all your @Bean methods to the Application class."**
The Application class should be lean - just the main method and @SpringBootApplication.
Create separate @Configuration classes for @Bean definitions. Keeps the
codebase organised and the main class readable.

**Misconception 3: "@SpringBootApplication must be on the class with main()."**
You can put @SpringBootApplication on any class. Spring Boot conventions put
it on the main class for clarity, but it is not enforced. The class passed to
SpringApplication.run() is the source of primary configuration.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Beans not discovered - NoSuchBeanDefinitionException**
Symptom: @Service class not found when injected.
Cause: Class is in a package not under the @SpringBootApplication class package.
Diagnosis: Check the package name of the unfound class vs Application class.
Fix: Move the Application class to a root package above all component packages,
or use scanBasePackages to include the missing package.

**Failure 2: Circular application context start**
Symptom: Application starts twice in tests.
Cause: Two @SpringBootApplication classes on the test classpath both get
loaded as context configurations.
Fix: Ensure there is only one @SpringBootApplication class per module.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What three annotations does @SpringBootApplication combine?**

1. @Configuration: the annotated class is a source of @Bean definitions.
   Spring processes it with ConfigurationClassPostProcessor.

2. @EnableAutoConfiguration: activates Spring Boot's auto-configuration
   mechanism. Imports AutoConfigurationImportSelector which reads
   AutoConfiguration.imports and processes all matching @Configuration candidates.

3. @ComponentScan: scans the annotated class's package and all sub-packages
   for @Component-annotated classes and registers them as bean definitions.

Each can be used independently when you need to configure them differently
from @SpringBootApplication's defaults.

*What separates good from great:* @SpringBootApplication is itself annotated
with @SpringBootConfiguration (not @Configuration directly). @SpringBootConfiguration
extends @Configuration and adds the TestAutoConfigurationExcludeFilter - used
by @SpringBootTest to avoid scanning test configurations in production code.

---

**[JUNIOR] Q2 - [CONCEPTUAL] Why does the placement of the Application class matter?**

@ComponentScan (included in @SpringBootApplication) scans the package of the
annotated class and all its sub-packages. If Application.java is in
com.example.order, Spring scans com.example.order.** but NOT com.example.payment.

Spring Boot convention: place Application.java in the root package
(com.example, not com.example.order) so all modules are scanned:
```
com.example.Application     <- root package
com.example.order.*         <- scanned
com.example.payment.*       <- scanned
com.example.user.*          <- scanned
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Violating this convention causes NoSuchBeanDefinitionException for components
in packages not under the application root.

*What separates good from great:* In multi-module Maven projects, the
Application class may be in a different module than some components. Use
scanBasePackages or create a configuration class with @ComponentScan in
the relevant module.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What is the difference between @SpringBootApplication and @SpringBootTest?**

@SpringBootApplication is used in production code to mark the main entry point.
@SpringBootTest is a test annotation that creates a full Spring application
context for integration tests.

@SpringBootTest finds the @SpringBootApplication class automatically (searches
upward from the test class's package) and uses it to configure the test context.
It can start the full embedded server (webEnvironment = RANDOM_PORT) or create
just the context without a server.

*What separates good from great:* @SpringBootTest is expensive - it creates the
full context including auto-configuration. For unit tests, use @ExtendWith(Mock
itoExtension.class) without Spring. For slice tests (just MVC, just data layer),
use @WebMvcTest, @DataJpaTest, @JsonTest etc. These start only the relevant
slice of auto-configuration, making tests faster.

---

**[MID] Q4 - [CONCEPTUAL] What is proxyBeanMethods = false in @SpringBootApplication?**

By default, @Configuration classes are subclassed by CGLIB. This ensures that
@Bean methods called from other @Bean methods return the singleton bean (not
a new instance). CGLIB subclassing adds startup overhead.

proxyBeanMethods = false skips CGLIB subclassing. @Bean methods are treated
as regular factory methods - inter-method calls create new instances rather
than returning singletons.

Use false when:
- None of your @Bean methods call other @Bean methods in the same class
- You want faster context startup (skips CGLIB proxy generation)
- You are building a GraalVM native image (CGLIB proxies have restrictions)

Use true (default) when:
- You have inter-@Bean method calls that should return singletons

Spring Boot uses proxyBeanMethods = false in its own internal auto-configuration
classes for performance.

*What separates good from great:* @SpringBootApplication itself sets
proxyBeanMethods = false in recent Spring Boot versions. This means adding
@Bean methods to your Application class where one @Bean method calls another
may not work as expected - the called @Bean creates a new instance each time.

---

**[MID] Q5 - [CONCEPTUAL] How do you scan multiple packages with @SpringBootApplication?**

Use the scanBasePackages attribute:
```java
@SpringBootApplication(
    scanBasePackages = {
        "com.example.orders",
        "com.example.shared",
        "com.thirdparty.components"
    }
)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Or use scanBasePackageClasses for type-safe references:
```java
@SpringBootApplication(
    scanBasePackageClasses = {
        OrderService.class,     // scans com.example.orders
        SharedConfig.class      // scans com.example.shared
    }
)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

scanBasePackageClasses is safer: it is not affected by package rename
refactoring since it references a class in the package.

*What separates good from great:* If the packages you need to scan are in
a different Maven module, the better pattern is to have a @Configuration
class in that module with its own @ComponentScan, and import it with @Import
or include it in AutoConfiguration.imports. This keeps the configuration
local to the module it belongs to.

---

**[MID] Q6 - [CONCEPTUAL] Can you have multiple @SpringBootApplication classes?**

You can have multiple classes annotated with @SpringBootApplication but you
should only run one at a time. Each call to SpringApplication.run() creates
a new ApplicationContext starting from that class as the configuration root.

In a multi-module project, each module may have its own @SpringBootApplication
for testing purposes. Spring's test framework finds the nearest
@SpringBootApplication class when loading test contexts.

The rule: one @SpringBootApplication per deployed unit (per JVM process).
Multiple per codebase for testing is fine.

*What separates good from great:* Spring Boot test caching uses the combination
of @SpringBootApplication class + test annotations as the context cache key.
Two tests using the same @SpringBootApplication class share a cached context.
Tests with different configurations get different contexts.

---

**[SENIOR] Q7 - [CONCEPTUAL] What is the difference between @SpringBootApplication and @SpringBootConfiguration?**

@SpringBootConfiguration is a specialization of @Configuration with:
- @Configuration behaviour: the class is a bean definition source
- TestAutoConfigurationExcludeFilter: prevents test @Configuration classes
  from being loaded in the production context

@SpringBootApplication includes @SpringBootConfiguration (not plain @Configuration).
This means:
- @SpringBootTest finds @SpringBootApplication classes by looking for
  @SpringBootConfiguration on the classpath
- Test @Configuration classes in your test sources are excluded from the
  production context

You rarely use @SpringBootConfiguration directly. It is present because
@SpringBootApplication is a composed annotation and needs @Configuration
behaviour - it uses @SpringBootConfiguration to get the TestConfiguration
exclusion too.

*What separates good from great:* The exclusion of test configurations
(TestAutoConfigurationExcludeFilter) prevents accidentally loading test
@Configuration or test @Bean definitions into the production context.
This matters in build systems where production and test classes are on
the same classpath during compilation.

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


# Embedded Server

---
id: SPR-009
title: Embedded Server
category: Spring
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #spring-boot, #embedded-server, #tomcat, #jetty, #undertow
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - demonstrates understanding of what makes Spring
Boot deployments different from traditional Java web applications.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Boot embeds a web server (Tomcat by default) directly inside your
> application JAR. This means your application is a self-contained executable
> jar - you run it with `java -jar app.jar` and it starts its own web server
> internally. No separate Tomcat installation required, no WAR file deployment
> to an application server. This is what enables containerized microservice
> deployments.

**3 minutes (Senior):**
> Traditional Java web development required deploying a WAR file to an
> application server (Tomcat, JBoss, WebSphere). The server was separately
> installed, configured, and managed. Multiple applications shared one server.
> This model worked but complicated local development, CI/CD, and independent
> scaling.
>
> Spring Boot changed this by embedding the server inside the application.
> spring-boot-starter-web pulls in Tomcat as a dependency, and Boot's
> WebMvcAutoConfiguration configures and starts it as part of the application
> context refresh. The result is a single fat JAR: your application code,
> Spring Framework, Spring Boot, Tomcat, and all dependencies in one
> self-contained artifact.
>
> You can switch to Jetty or Undertow by excluding Tomcat and adding the
> appropriate starter. Netty is used for reactive applications
> (spring-boot-starter-webflux).
>
> The trade-off: embedded servers are simpler to deploy but give up the
> multi-tenant server features (shared thread pools, centralised management)
> of standalone servers. For microservices running in containers, this is
> the right trade-off.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers discuss embedded server tuning (Tomcat thread
pool, connection limits), graceful shutdown configuration, and the production
considerations of fat JARs vs layered JARs for Docker.

*Adapting down:* Junior - "Spring Boot includes a web server inside your
application. You just run the jar file and your app is available on the web.
No separate server setup needed."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Boot's embedded server - why
Spring Boot apps run without an external Tomcat."

**(2) First principles:** "A web application needs something to receive HTTP
connections and dispatch them to your code. Traditionally that was a
separately installed server. Spring Boot includes that server inside the
application itself."

**(3) Bridge:** "It is like the difference between a restaurant (traditional
server - a dedicated place) and a food truck (embedded server - the
kitchen travels with the food)."

---

### 📘 Concept Explanation

**What it is:**
Spring Boot embeds a servlet container (Tomcat by default) or reactive server
(Netty for WebFlux) directly in the application. The server starts as a regular
Spring bean when the application context refreshes - no separate server
installation required.

**The problem it solves:**
Traditional WAR deployment required a separately installed and configured
application server. This created operational complexity: server upgrades were
separate from application upgrades, configuration was split between the server
and the application, local development required a running server, and scaling
meant managing server instances separately from application instances.
Embedded servers solve all of this: the application IS the server.

**How it works:**

```
Traditional WAR deployment:
  [Tomcat Installation]
      |
      |-- webapps/
          |-- myapp.war  <- your application deployed here
              |-- WEB-INF/web.xml
              |-- WEB-INF/classes/
              |-- WEB-INF/lib/ (your dependencies, NOT Tomcat)

Spring Boot fat JAR:
  myapp.jar  <- self-contained executable
      |-- org/springframework/boot/loader/ (Spring Boot Loader)
      |-- BOOT-INF/classes/ (your compiled classes)
      |-- BOOT-INF/lib/     (ALL dependencies including Tomcat)
      |-- META-INF/MANIFEST.MF (Main-Class: Loader)

Running: java -jar myapp.jar
  -> Spring Boot Loader extracts nested JARs
  -> SpringApplication.run() creates ApplicationContext
  -> EmbeddedWebServerFactoryCustomizerAutoConfiguration
     creates TomcatServletWebServerFactory
  -> Tomcat starts, binds to port 8080
  -> DispatcherServlet registered
  -> Application ready
```

> **Code walkthrough:** This Embedded Server example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The embedded server is just another bean in the ApplicationContext. It starts
during the onRefresh() phase of context refresh. This means the server lifecycle
is tied to the application context lifecycle - when the context closes, the
server stops. This tight coupling enables graceful shutdown.

**When to use it:**
- All Spring Boot microservices (this is the default)
- Containerised deployments in Docker/Kubernetes
- Applications that need to own their entire runtime stack

**When NOT to use it:**
- Shared application servers required for enterprise licensing or centralised
  management (WebSphere, JBoss in enterprise settings)
- When WAR deployment to an existing server is mandated by operations
  (Spring Boot supports WAR deployment by extending SpringBootServletInitializer)

**Alternatives:**
- Tomcat (default): battle-tested, widely used, good documentation
- Jetty: lighter than Tomcat; better for WebSocket-heavy applications
- Undertow: lowest memory footprint; good for high-concurrency
- Netty: for reactive/WebFlux applications

**First-principles derivation:**
A self-contained deployment unit is simpler to reason about, deploy, and scale
than one requiring an external runtime. Docker reinforced this - containers work
best when the application is self-contained. Spring Boot's embedded server is
the Java implementation of the single-container-per-process deployment model.

---

### 💻 Code Example

```java
// Customising embedded server via application.properties
// server.port=8080 (default)
// server.port=0    (random port - useful in tests)
// server.servlet.context-path=/api
// server.tomcat.max-threads=200
// server.tomcat.accept-count=100
// server.tomcat.connection-timeout=5000ms
// server.compression.enabled=true
// server.compression.mime-types=application/json
```

> **Code walkthrough:** The most common embedded server configuration is doneice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> via properties. No Java code needed. server.port=0 is especially useful in
> integration tests - each test gets a random available port, preventing port
> conflicts when tests run in parallel.

```java
// Programmatic server customisation via bean
@Configuration
public class ServerConfig {

    // Customize Tomcat with a WebServerFactoryCustomizer
    @Bean
    public WebServerFactoryCustomizer<TomcatServletWebServerFactory>
            tomcatCustomizer() {
        return factory -> {
            // Enable HTTP/2
            factory.addConnectorCustomizers(connector -> {
                connector.setProperty("maxKeepAliveRequests",
                    "100");
            });
            // Set max connections
            factory.setMaxConnections(1000);
        };
    }
}
```

> **Code walkthrough:** For configuration not available via properties,ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> WebServerFactoryCustomizer provides programmatic access to the server
> factory before it creates the server. This is how you enable HTTP/2,
> set SSL configuration, or tune connection pool settings beyond what
> properties expose. The customizer runs after property binding, so it
> can supplement property-based configuration.

```java
// Switching from Tomcat to Jetty
// pom.xml:
// <dependency>
//   <groupId>org.springframework.boot</groupId>
//   <artifactId>spring-boot-starter-web</artifactId>
//   <exclusions>
//     <exclusion>
//       <groupId>org.springframework.boot</groupId>
//       <artifactId>spring-boot-starter-tomcat</artifactId>
//     </exclusion>
//   </exclusions>
// </dependency>
// <dependency>
//   <groupId>org.springframework.boot</groupId>
//   <artifactId>spring-boot-starter-jetty</artifactId>
// </dependency>

// That is all - no code changes required
// Spring Boot auto-configuration detects Jetty on classpath
// and configures JettyServletWebServerFactory instead
```

> **Code walkthrough:** Server switching is a dependency change, not a codeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> change. Boot's auto-configuration detects which server factory is available
> and uses it. This demonstrates the power of the auto-configuration model:
> switching a fundamental infrastructure component requires zero application
> code changes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Boot embeds a web server (Tomcat by default) inside your application.
> When you run `java -jar app.jar`, Tomcat starts as part of your application
> and listens on port 8080. You do not need to install or configure Tomcat
> separately. This makes deployment simple: copy one JAR file and run it.
> You can configure the port and other server settings in application.properties.

*Push deeper:* Explain WAR vs JAR deployment: JAR is the Spring Boot default
(embedded server); WAR is the traditional approach for external servers.

---

**Senior / Staff (5+ years):**
> The embedded server is a bean in the ApplicationContext, started during
> context refresh. This means the server lifecycle is coupled to the context
> lifecycle - graceful shutdown closes the context before stopping the server,
> allowing in-flight requests to complete. The fat JAR includes all dependencies
> (including the server). For Docker deployments, layered JARs (Spring Boot
> Layertools) separate dependencies from application code so Docker layer caching
> works correctly - the large dependency layer is cached and only the small
> application layer is rebuilt on code changes.

*Push deeper:* Graceful shutdown: server.shutdown=graceful (Boot 2.3+) combined
with the Kubernetes readiness probe ensures the service is removed from load
balancer rotation before the server stops accepting new connections. The default
graceful shutdown timeout is 30 seconds.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Embedded server is only for development."**
Embedded servers are production-grade. Netflix, Spotify, and virtually every
company using Spring Boot microservices runs embedded Tomcat/Jetty/Undertow
in production. The embedded server is not a development shortcut.

**Misconception 2: "You cannot deploy Spring Boot as a WAR."**
You can deploy to an external server by extending SpringBootServletInitializer
and packaging as WAR. This is useful for organisations that mandate external
application servers for licensing or management reasons.

**Misconception 3: "The embedded server has less capability than standalone Tomcat."**
The embedded Tomcat is the same Tomcat codebase. All Tomcat features are
available via configuration. The difference is operational: embedded means
one Tomcat per application; standalone means multiple applications per Tomcat.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Port already in use**
Symptom: "Web server failed to start. Port 8080 was already in use."
Cause: Another process is listening on the configured port.
Diagnosis: `netstat -an | findstr 8080` (Windows) or `lsof -i:8080` (Linux).
Fix: Change server.port in application.properties, or kill the conflicting
process.

**Failure 2: Context path confusion**
Symptom: Requests to /api/users return 404 when you expect them to work.
Cause: server.servlet.context-path=/api is set, but client is not including
the context path.
Fix: Ensure clients include the context path, or remove it if not needed.

**Failure 3: Thread pool exhaustion under load**
Symptom: Requests hang or time out under high load; /actuator/metrics shows
tomcat.threads.busy at maximum.
Cause: Default Tomcat max-threads is 200. At high concurrency all threads
are busy.
Fix: Tune server.tomcat.max-threads, or switch to reactive (WebFlux + Netty)
for I/O-bound applications.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is an embedded server in Spring Boot?**

An embedded server is a servlet container (Tomcat, Jetty, Undertow) or
reactive server (Netty) bundled inside the Spring Boot application JAR and
started programmatically as part of the ApplicationContext refresh.

The result: a self-contained executable JAR that includes the application,
all dependencies, AND the server. Running `java -jar app.jar` starts both
the application and the server simultaneously.

This is the default Spring Boot deployment model - no separate server
installation required.

*What separates good from great:* The embedded server is started in
onRefresh() of AnnotationConfigServletWebServerApplicationContext. The
EmbeddedWebServerFactoryCustomizerAutoConfiguration creates the appropriate
server factory based on classpath detection. The server starts before
ContextRefreshedEvent fires, so by the time your application listener
receives that event, the server is already accepting connections.

---

**[JUNIOR] Q2 - [CONCEPTUAL] How do you change the default Tomcat server to Jetty?**

Exclude Tomcat starter, add Jetty starter in pom.xml:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jetty</artifactId>
</dependency>
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Zero code changes required. Spring Boot's auto-configuration detects
JettyServletWebServerFactory on the classpath and uses it.

When to use Jetty: higher throughput for WebSocket-heavy applications;
slightly lower memory footprint than Tomcat.

*What separates good from great:* Undertow (Red Hat's server) is the lowest
footprint option and handles very high concurrency well. Used by Red Hat
internally. The performance difference between Tomcat, Jetty, and Undertow
is small for most applications - choose based on operational familiarity.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How does graceful shutdown work in Spring Boot?**

Graceful shutdown (Spring Boot 2.3+):
Configure: `server.shutdown=graceful` in application.properties.

When a SIGTERM is received:
1. Kubernetes/load balancer readiness probe starts failing (application sets
   readiness to DOWN).
2. Load balancer stops routing new requests to the pod.
3. Spring Boot waits for in-flight requests to complete (default 30 sec timeout).
4. After all requests complete (or timeout), the context closes and server stops.
5. Process exits.

Configuration:
```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The Kubernetes deployment spec should set
terminationGracePeriodSeconds longer than the Spring Boot shutdown timeout.
If Kubernetes kills the pod before Spring Boot finishes, you still get abrupt
termination. A common production mistake is setting Spring Boot graceful shutdown
to 60s but Kubernetes terminationGracePeriodSeconds to 30s.

---

**[MID] Q4 - [CONCEPTUAL] What is the difference between a fat JAR and a WAR?**

**Fat JAR** (Spring Boot default):
- Self-contained executable JAR with all dependencies including embedded server
- Run with: `java -jar app.jar`
- Includes: your code + all JARs (Spring, Tomcat, etc.) + Spring Boot Loader
- For Docker: one file, one command, no external dependencies

**WAR** (traditional deployment):
- Web Application Archive without embedded server
- Deploy to an external Tomcat/JBoss/WebSphere
- Server is NOT included - must be installed separately
- For WAR: extend SpringBootServletInitializer, set packaging to war

When to use WAR: enterprise environments requiring centralised application
server management, server-level SSL termination, or shared resources across
applications on one server.

*What separates good from great:* Layered JARs (Spring Boot 2.3+) split the
fat JAR into layers: dependencies (rarely changes), Spring Boot loader, snapshot
dependencies, application code. Docker layers cache each layer separately -
only the application code layer is rebuilt on code changes, making Docker builds
much faster.

---

**[MID] Q5 - [CONCEPTUAL] How do you configure Tomcat connection pool and thread settings?**

```properties
# Thread pool
server.tomcat.threads.max=200       # default 200
server.tomcat.threads.min-spare=10  # default 10

# Connection settings
server.tomcat.accept-count=100  # queue depth when all threads busy
server.tomcat.max-connections=8192  # total connections
server.tomcat.connection-timeout=20000  # ms

# Compression
server.compression.enabled=true
server.compression.min-response-size=2048
```

> **Code walkthrough:** This Compression example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Choosing max-threads: a general rule is CPU-count * 2 for CPU-bound work;
for I/O-bound work (database calls, HTTP calls) you can go much higher
(200-500) since threads spend most time waiting.

*What separates good from great:* Virtual threads (Spring Boot 3.2+ with
Java 21+): `spring.threads.virtual.enabled=true` enables virtual threads
for Tomcat. Virtual threads are extremely cheap so max-threads is no longer
the limiting factor - you can handle tens of thousands of concurrent requests
without tuning. This is a paradigm shift for thread-per-request servlet model.

---

**[SENIOR] Q6 - [MECHANISM] How do you add HTTPS to a Spring Boot embedded server?**

Configure SSL in application.properties:
```properties
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.jks
server.ssl.key-store-password=secret
server.ssl.key-store-type=JKS
server.ssl.key-alias=myapp
server.port=8443
```

> **Code walkthrough:** This Compression example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

For production, prefer externally managed SSL (load balancer, Kubernetes
ingress controller) over application-managed SSL. Terminating SSL at the
load balancer is the standard pattern - the application sees plain HTTP
internally.

*What separates good from great:* If you need both HTTP and HTTPS, Spring
Boot only supports one port natively. For dual ports, configure a second
connector programmatically via WebServerFactoryCustomizer. For redirecting
HTTP to HTTPS, a filter (ChannelProcessingFilter) is the standard approach.

---

**[SENIOR] Q7 - [MECHANISM] What is the Spring Boot fat JAR structure?**

```
app.jar
|-- META-INF/
|   |-- MANIFEST.MF  (Main-Class: JarLauncher)
|-- BOOT-INF/
|   |-- classes/    <- your compiled .class files
|   |-- lib/        <- all dependency JARs (including Tomcat)
|   |   |-- tomcat-embed-core-10.x.jar
|   |   |-- spring-web-6.x.jar
|   |   |-- ... (hundreds of JARs)
|   |-- classpath.idx  (ordered list for class loading)
|   |-- layers.idx     (layered JAR metadata)
|-- org/
    |-- springframework/boot/loader/
        |-- JarLauncher.class  <- Boot's custom class loader
        |-- LaunchedURLClassLoader.class
```

> **Code walkthrough:** This Compression example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

JarLauncher is the real Main-Class. It sets up a custom classloader that
can load classes from nested JARs (JARs inside the fat JAR), then calls
your Application.main().

*What separates good from great:* The Spring Boot Loader solves a
fundamental Java problem: the standard JVM cannot load classes from JARs
nested inside JARs. Boot's custom classloader makes this work without
exploding the JAR at startup, which was the older approach. Understanding
this explains why Spring Boot apps are immediately runnable with java -jar.

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



