---
layout: default
title: "GraalVM - L2 Native Image"
parent: "GraalVM"
grand_parent: "SK Interview"
nav_order: 3
permalink: /graalvm/l2-native-image/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Native Image Closed-World Assumption](#native-image-closed-world-assumption) | hard |
| 2 | [Reflection and Serialization Configuration](#reflection-and-serialization-configuration) | working |
| 3 | [Native Image Resources and File Inclusion](#native-image-resources-and-file-inclusion) | working |
| 4 | [Native Image Startup and Memory Profile](#native-image-startup-and-memory-profile) | working |

---

# Native Image Closed-World Assumption

**Interview Weight:** hard - This is the fundamental
constraint of native image. Every native image failure
traces back to this concept.

---

### 🎯 Model Answer

**30 seconds:**

> The closed-world assumption: all code that may execute
> must be known and reachable at native image build time.
> The build tool performs static analysis starting from
> declared entry points and follows all reachable method
> calls, object allocations, and class loads. Any code
> path that can only be discovered at runtime (dynamic
> class loading, arbitrary reflection, JVM agents) violates
> the closed-world assumption and will fail or require
> explicit configuration.

**3 minutes (Senior):**

> Closed-world consequences:
>
> 1. Dynamic class loading fails:
>    Class.forName("com.example.Foo"): class name is a string.
>    Static analysis: strings are not types.
>    Cannot follow string to class → excluded from binary.
>    Runtime: ClassNotFoundException.
>
>    Fix: register the class, use ServiceLoader,
>      or use @RegisterForReflection.
>
> 2. Reflection limited:
>    field.get(obj): which field? depends on runtime value.
>    Native image cannot include all possible fields.
>    Must declare: "method X uses field Y of class Z."
>
>    Fix: reflect-config.json or @RegisterForReflection.
>
> 3. Java agents incompatible:
>    Agents transform bytecode at runtime (instrument, mock).
>    Bytecode transformation requires the JVM transformation API.
>    Native image: no JVM → no agent support.
>
>    Fix: use build-time instrumentation (Quarkus extensions).
>
> 4. Dynamic proxies limited:
>    CGLIB: generates new class bytecode at runtime.
>    Not possible in native (no bytecode generation).
>    JDK dynamic proxies: supported if interface registered.
>
>    Fix: use interface-based design + build-time proxies.
>
> 5. Static initializer side effects:
>    Not runtime code, but: static {} runs at build time.
>    File I/O, network calls, time-dependent code: fail.
>
>    Fix: @InitializeAtRunTime annotation.
>
> What the closed-world allows:
>   ServiceLoader: classes listed in META-INF/services.
>   CDI injection: beans discovered at build time (ArC).
>   Spring beans (Spring native): registered at build time.
>   Declared reflection: @RegisterForReflection.
>   JDK dynamic proxies: registered in proxy-config.json.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the closed-world
assumption and why it constrains native image behavior."

**(2) First principles:** "AOT compilation: everything compiled
ahead of time. What's not compiled: not present at runtime."

**(3) Bridge:** "Closed-world is the same as C: link-time
inclusion. If not linked in, not available at runtime."

---

### 💻 Code Example

```java
// VIOLATION 1: Dynamic class loading
// BAD: String-based class lookup
public class PluginLoader {
    public Plugin load(String pluginClass) {
        try {
            // Closed-world violation: string is opaque
            return (Plugin) Class
                .forName(pluginClass)
                .getDeclaredConstructor()
                .newInstance();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
// Build: no error (static analysis doesn't catch)
// Runtime: ClassNotFoundException (class not in binary)

// GOOD: ServiceLoader pattern
// META-INF/services/com.example.Plugin:
//   com.example.plugins.EmailPlugin
//   com.example.plugins.SmsPlugin

public class PluginRegistry {
    private final List<Plugin> plugins;

    public PluginRegistry() {
        // ServiceLoader: classes listed in META-INF
        // native-image scans META-INF at build time
        this.plugins = StreamSupport
            .stream(
                ServiceLoader.load(Plugin.class)
                    .spliterator(), false)
            .collect(Collectors.toList());
    }
}

// VIOLATION 2: CGLIB proxy (runtime class generation)
// Spring @Transactional on concrete class: CGLIB proxy
// CGLIB generates a subclass bytecode at runtime
// Not possible in native image

// BAD (in native context)
@Transactional
public class OrderService {
    // Spring creates CGLIB proxy → not compatible
}

// GOOD: interface-based, JDK dynamic proxy
public interface OrderServicePort {
    Order createOrder(CreateOrderRequest req);
}

@ApplicationScoped
@Transactional
public class OrderService
        implements OrderServicePort {
    // Quarkus generates proxy at build time (ArC)
    // JDK dynamic proxy: registered and included
    @Override
    public Order createOrder(
            CreateOrderRequest req) { ... }
}

// VIOLATION 3: Static initializer with runtime side effects
// BAD: network in static init
public class ConfigClient {
    private static final String configServerUrl;
    static {
        // Runs at BUILD TIME in native image
        // Build server ≠ config server address
        configServerUrl = System.getenv(
            "CONFIG_SERVER_URL");
        // getenv at build time: null (not set in CI)
    }
}

// GOOD: runtime initialization
@ApplicationScoped
public class ConfigClient {
    @ConfigProperty(name = "config.server.url")
    String configServerUrl;
    // Injected at runtime from env/config
}

// EXCEPTION: mark class for runtime init
// In application.properties:
// quarkus.native.additional-build-args=\
//   --initialize-at-run-time=\
//   com.thirdparty.StatefulClass
```

> **Code walkthrough:** The ServiceLoader fix is the
> canonical closed-world-compliant plugin pattern: list
> implementations in META-INF/services, native-image
> includes them all. The interface-based proxy fix allows
> Quarkus to generate the proxy at build time (ArC replaces
> CGLIB). The @InitializeAtRunTime approach is a last-resort
> escape hatch for problematic third-party static initializers.

---

### 🎓 Answers by Seniority

**Junior:** "Closed-world: all code must be known at build time.
Dynamic class loading and arbitrary reflection fail. Fix:
declare what you need via annotations or config files."

**Senior:** "The closed-world assumption eliminates an entire
class of JVM patterns: runtime proxies, agents, plugins.
This forces more explicit design. Long-term: the code is
better because of these constraints."

---

### ⚠️ Common Misconceptions

**"If it works in JVM mode it will work in native."**
False. JVM mode has full reflection and class loading.
Native image does not. Always run native-mode tests.

**"Class.forName fails immediately at build."**
False. Build succeeds. The class is simply not included
in the binary. The failure happens at runtime.

**"@RegisterForReflection handles all reflection needs."**
Partial. It handles class-level reflection. JNI,
serialization, and proxy registration need separate config.

---

### 🚨 Failure Modes and Diagnosis

**ClassNotFoundException at startup (native):**
```bash
# Symptom
java.lang.ClassNotFoundException:
  com.mysql.jdbc.Driver

# Diagnosis: driver loaded via reflection
# Check: is there a Class.forName in the code or library?

# Fix: register the driver class
@RegisterForReflection(
    targets = com.mysql.cj.jdbc.Driver.class
)
public class DriverRegistration { }

# Or in reflect-config.json:
# { "name": "com.mysql.cj.jdbc.Driver",
#   "allDeclaredConstructors": true }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Proxy creation failure:**
```bash
# Symptom
UnsatisfiedLinkError or ClassCastException on proxy

# Diagnosis: CGLIB proxy attempted at runtime
# Find: @Transactional on class without interface

# Fix: implement interface
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Closed-world meaning, common violations |
| Senior | 8 min | Violations, patterns, diagnosis |
| Staff | 12 min | Design implications, code quality improvement |

---

**[STAFF] Q1 - How does the closed-world assumption
improve code quality?**

*Why they ask:* Design philosophy.

The closed-world assumption forces explicit design:

1. No implicit reflection:
   ```java
   // JVM: Jackson discovers fields via reflection
   class OrderDto { int id; String status; }
   // Native: you must declare intent
   @RegisterForReflection
   class OrderDto { int id; String status; }
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Result: the annotation documents "this is a DTO."
   Code becomes self-documenting.

2. No hidden dynamic class loading:
   ```java
   // JVM: class loaded dynamically, hard to trace
   Object obj = Class.forName(className).newInstance();
   // Native: compile error equivalent
   // Must use ServiceLoader or explicit types
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Result: all plugin types are listed in META-INF/services.
   Easier to audit what plugins exist.

3. Interface-based design:
   ```java
   // JVM: concrete class with CGLIB proxy
   @Service OrderService { @Transactional void save() }
   // Native: must use interface
   interface OrderPort { void save(); }
   @Service class OrderService implements OrderPort
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Result: dependency inversion. Better testability.

4. No static initialization side effects:
   ```java
   // JVM: static init accesses external resources
   static { db = DriverManager.getConnection(url); }
   // Native: violates closed-world
   // Must: @ApplicationScoped + @Inject DataSource
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Result: lazy initialization, not eager.

The meta-pattern: native image constraints are enforced
quality rules. The code that works in native image is
more explicit, testable, and analyzable.

*What separates good from great:* "Native image constraints
make the code better. I treat closed-world violations
as design feedback, not just technical problems."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Violation types, fixes. |
| Hiring Manager | Native image migration impact. |
| Bar Raiser | Closed-world as quality constraint, design implications. |
| Staff | "Closed-world violations are architecture smells. Each one is a question: why is this dynamic? What could be explicit?" |

---

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


# Reflection and Serialization Configuration

**Interview Weight:** working knowledge - Most
native image build failures involve reflection or serialization.

---

### 🎯 Model Answer

**30 seconds:**

> Reflection configuration tells native-image which classes,
> methods, and fields need runtime reflection. Serialization
> configuration declares classes that use Java serialization.
> Both use JSON config files under META-INF/native-image/
> or annotations. Quarkus extensions handle most of this
> automatically for supported libraries. When using
> third-party libraries: use the native-image tracing agent
> to generate the config files automatically.

**3 minutes (Senior):**

> Config file types:
>
> reflect-config.json:
>   Class-level declarations.
>   Fields/methods/constructors selectable.
>   Example use: Jackson DTOs, JPA entities, enums.
>
> serialization-config.json:
>   Java object serialization (Serializable classes).
>   Required if: session serialization, distributed cache.
>   Format: list of class names + serialization type.
>
> proxy-config.json:
>   JDK dynamic proxy interfaces.
>   Required if: creating proxy with Proxy.newProxyInstance().
>
> resource-config.json:
>   Files included in binary (templates, config files).
>   Pattern-based inclusion.
>
> jni-config.json:
>   Native (C) method declarations.
>   Required if: JNI calls in the code.
>
> Placement options:
>   src/main/resources/META-INF/native-image/ (project-specific)
>   META-INF/native-image/{group-id}/{artifact-id}/ (library-specific)
>   --H:ConfigurationFileDirectories= (command line)
>
> Quarkus auto-registration:
>   @JsonSerialize/@JsonDeserialize → jackson extension registers.
>   @Entity → hibernate extension registers.
>   @Path → REST extension registers parameter types.
>   Remaining DTOs → @RegisterForReflection.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to configure
reflection and serialization for native image."

**(2) First principles:** "Native image needs an explicit manifest
of what needs reflection. JSON config files are that manifest."

**(3) Bridge:** "Reflection config is a type manifest: tell
native-image exactly which classes need reflective access."

---

### 💻 Code Example

```json
// reflect-config.json
// src/main/resources/META-INF/native-image/reflect-config.json
[
  {
    "name": "com.example.OrderDto",
    "allDeclaredConstructors": true,
    "allDeclaredMethods": true,
    "allDeclaredFields": true
  },
  {
    "name": "com.example.PaymentDto",
    "fields": [
      { "name": "amount", "allowWrite": true },
      { "name": "currency", "allowWrite": true }
    ],
    "methods": [
      { "name": "<init>", "parameterTypes": [] }
    ]
  },
  {
    "name": "com.example.OrderStatus",
    "allDeclaredFields": true,
    "allDeclaredMethods": true
  }
]
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```json
// serialization-config.json
// Required if classes implement java.io.Serializable
// and are serialized at runtime
[
  {
    "name": "com.example.SessionData"
  },
  {
    "name": "java.util.ArrayList"
  }
]
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```json
// proxy-config.json
// Required if Proxy.newProxyInstance used
[
  {
    "interfaces": [
      "com.example.OrderRepository",
      "org.springframework.data.jpa.repository.JpaRepository"
    ]
  }
]
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```java
// GOOD: Quarkus annotation approach (simpler)
// Instead of reflect-config.json, use annotations:

@RegisterForReflection(
    targets = {
        OrderDto.class,
        PaymentDto.class,
        OrderStatus.class
    }
)
// Place on any class in the project
public class NativeImageConfig {
    // Empty holder class for reflection registrations
}

// For serialization: Quarkus extension handles
// Hibernate entities and Jackson types automatically
// Manual override: reflect-config.json still supported
```

> **Code walkthrough:** The reflect-config.json format
> is granular: allDeclaredFields registers all fields,
> but you can also list specific fields for minimal binary
> size. The proxy-config.json format specifies the exact
> interface list for each proxy: native-image includes
> the proxy class for these combinations. The @RegisterForReflection
> targets array approach is cleaner for Quarkus projects.

---

### 🎓 Answers by Seniority

**Junior:** "JSON files under META-INF/native-image/ tell
native-image what needs reflection. Quarkus handles most
of this automatically for known libraries."

**Senior:** "Prefer annotations over JSON config files
for maintainability. Use the tracing agent for third-party
libraries: run with -agentlib:native-image-agent=config-output-dir=./configs,
exercise all paths, copy generated files to META-INF."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Config file types, @RegisterForReflection |
| Senior | 7 min | JSON config format, tracing agent, proxy config |

---

**[SENIOR] Q1 - How do you use the native-image
tracing agent for third-party libraries?**

*Why they ask:* Practical native image migration.

Tracing agent: records all reflection, proxy, serialization,
and resource accesses at runtime.

Workflow:
```bash
# Step 1: Build the JAR (JVM mode)
./mvnw package -DskipTests

# Step 2: Run with tracing agent
java \
  -agentlib:native-image-agent=\
  config-output-dir=src/main/resources/\
  META-INF/native-image \
  -jar target/app.jar

# Step 3: Exercise all code paths
# Run integration tests or manual API calls:
curl http://localhost:8080/orders
curl http://localhost:8080/orders/1
curl -X POST http://localhost:8080/orders \
  -d '{"status":"NEW","amount":100}'

# Step 4: Stop the app
# Config files generated:
# META-INF/native-image/reflect-config.json
# META-INF/native-image/serialization-config.json
# META-INF/native-image/proxy-config.json
# META-INF/native-image/resource-config.json
# META-INF/native-image/jni-config.json

# Step 5: Review and clean up generated files
# Remove JDK internal classes (already included by native-image)
# Keep only application and third-party library classes

# Step 6: Build native image
./mvnw package -Pnative
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Merging multiple runs:
```bash
# Run agent multiple times, merge configs
java -agentlib:native-image-agent=\
  config-merge-dir=src/main/resources/META-INF/native-image \
  -jar target/app.jar
# config-merge-dir: merges with existing config
# Run multiple scenarios, merge all results
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Limitations:
- Only records executed paths.
- Error paths not exercised → not in config.
- Test with unhappy paths too.

*What separates good from great:* The agent is a starting
point, not a complete solution. Exercise ALL code paths
including errors and edge cases.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Config file types, format. |
| Hiring Manager | How to migrate third-party libraries. |
| Bar Raiser | Tracing agent workflow, merging runs, limitations. |
| Peer Engineer | "Used agent on Kafka consumer. Generated 450-line reflect-config. Trimmed to 120 lines removing JDK internals. Native build passed first try." |

---

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


# Native Image Resources and File Inclusion

**Interview Weight:** working knowledge - Resource
inclusion failures are common and easy to overlook.

---

### 🎯 Model Answer

**30 seconds:**

> Files accessed via getResourceAsStream() or ClassLoader.getResources()
> must be explicitly included in the native binary. Native
> image does not automatically include all classpath resources.
> Declare resources via: quarkus.native.resources.includes
> in application.properties, resource-config.json, or the
> @NativeImageResourcePatterns annotation. Common failures:
> SQL files, message templates, JSON config files, certificate
> files, and JDBC driver SQL dialect files.

**3 minutes (Senior):**

> Why resources need explicit inclusion:
>   JVM: classpath is the filesystem. All files reachable.
>   Native image: classpath is compiled into the binary.
>   Not all classpath files included by default.
>   Only what's declared (and some standard files) included.
>
> Auto-included resources (no declaration needed):
>   META-INF/services/* (ServiceLoader)
>   application.properties / application.yaml
>   persistence.xml
>   *.class files (as bytecode for reflection)
>
> Commonly missed resources:
>   SQL migration files (Flyway/Liquibase): must declare.
>   HTML/Mustache/Freemarker templates: must declare.
>   GraphQL schema files: must declare.
>   JDBC dialect SQL files: must declare.
>   Certificate files (.pem, .jks): must declare.
>   Static content (images, CSS, JS): must declare.
>
> Declaration methods:
>   application.properties:
>     quarkus.native.resources.includes=templates/**,*.sql
>   resource-config.json:
>     { "resources": [{"pattern": "db/migration/.*\\.sql"}] }
>   @NativeImageResourcePatterns (Quarkus):
>     @NativeImageResourcePatterns("db/migration/.*\\.sql")
>
> Pattern format: Java regex (not glob).
>   *.sql does NOT work: use .*\\.sql.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to include
files in the native image binary so they can be accessed
at runtime."

**(2) First principles:** "Native binary is self-contained.
Files must be embedded in the binary, not on a classpath."

**(3) Bridge:** "Resource inclusion is like bundling files
into a ZIP: explicit list of what to include."

---

### 💻 Code Example

```properties
# application.properties - resource inclusion
# Pattern: Java regex (NOT glob)

# Include all SQL migration files (Flyway)
quarkus.native.resources.includes=\
  db/migration/.*\\.sql

# Include Mustache templates
quarkus.native.resources.includes=\
  templates/.*\\.mustache

# Include multiple patterns (comma-separated)
quarkus.native.resources.includes=\
  db/migration/.*\\.sql,\
  templates/.*\\.html,\
  certs/.*\\.pem,\
  *.json

# Exclude pattern
quarkus.native.resources.excludes=\
  **/*-test.*
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```json
// resource-config.json
// For non-Quarkus projects or fine-grained control
// src/main/resources/META-INF/native-image/
//   resource-config.json
{
  "resources": [
    {
      "pattern": "db/migration/V.*\\.sql"
    },
    {
      "pattern": "templates/.*"
    },
    {
      "pattern": "certs/server\\.pem"
    }
  ],
  "bundles": [
    {
      "name": "messages"
    }
  ]
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```java
// WRONG: Assume resource auto-included
@ApplicationScoped
public class SqlTemplateLoader {
    public String loadTemplate(String name) {
        // Works in JVM: templates/ on classpath
        // Fails in native: templates/ not declared
        InputStream is = getClass()
            .getResourceAsStream(
                "/templates/" + name + ".sql");
        if (is == null) {
            throw new RuntimeException(
                "Template not found: " + name);
        }
        return new String(is.readAllBytes());
    }
}

// GOOD: Add to application.properties
// quarkus.native.resources.includes=templates/.*\\.sql
// Then the above code works in native
```

> **Code walkthrough:** The application.properties pattern
> uses Java regex not glob: `.*\\.sql` matches any .sql file,
> not `*.sql` (which is a glob). Comma-separated patterns
> in a single property cover multiple directories.
> The resource-config.json bundles section handles
> ResourceBundle (i18n message files) separately from
> classpath resources.

---

### 🎓 Answers by Seniority

**Junior:** "Files needed at runtime must be declared for
native image. Use quarkus.native.resources.includes with
Java regex patterns."

**Senior:** "Most missing resources cause NullPointerExceptions
at runtime (getResourceAsStream returns null), not build
failures. Always test: grep for getResourceAsStream in
code + libraries to find potential missing declarations."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Resource inclusion, properties pattern |
| Senior | 6 min | resource-config.json, common failures, diagnosis |

---

**[SENIOR] Q1 - What resources does Flyway need
to work in native image?**

*Why they ask:* Practical native image scenario.

Flyway requires: SQL migration files at runtime.

```properties
# application.properties
quarkus.native.resources.includes=\
  db/migration/.*\\.sql

# Or, if using Flyway with classpath locations:
quarkus.flyway.locations=classpath:db/migration
# Quarkus Flyway extension handles this automatically
# for the standard location
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Flyway in Quarkus native:
- Quarkus Flyway extension registers SQL files automatically.
- Standard location: db/migration/ - auto-included.
- Custom location: must declare in resources.includes.

Verify resources included in binary:
```bash
# List embedded resources in native binary
strings target/app-runner | grep "db/migration"
# Should show: db/migration/V1__init.sql etc.

# Alternative: test with native-test profile
./mvnw verify -Pnative
# Runs integration tests against native binary
# Flyway migration runs during test startup
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

If Flyway migration fails in native:
```
FlywayException: Found non-empty schema "public" without
  schema history table. Use baseline() or set
  baselineOnMigrate to true
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This is usually not a resource issue, but a Flyway
configuration issue. Distinguish: resource missing
(NullPointerException before migration starts) vs
Flyway logic error (after migration starts).

*What separates good from great:* Resource issues appear
as NullPointerExceptions before the framework even runs;
distinguish from framework errors.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | resource-config.json, patterns. |
| Hiring Manager | Common native failures, how to fix. |
| Bar Raiser | Resource audit strategy, binary inspection. |
| Peer Engineer | "Spent 2hr debugging native startup failure. Cause: missing .sql files in native resources. Fix: one properties line." |

---

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


# Native Image Startup and Memory Profile

**Interview Weight:** working knowledge - Startup and
memory metrics are frequently asked. Tests practical experience.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM native image startup: typically 20-100ms for
> a Quarkus microservice. JVM equivalent: 2-20 seconds.
> Memory (RSS): native typically 50-100MB vs 200-400MB JVM.
> Measurement commands: time ./app-runner (startup),
> /proc/PID/smaps_rollup (Linux RSS). Memory scales with
> heap: add -Xmx to limit heap. Startup time is fixed
> by binary content - cannot be tuned like JVM startup.

**3 minutes (Senior):**

> Startup components (native):
>
> Binary load:
>   OS maps binary into memory.
>   Heap snapshot mapped (not copied!).
>   ~10-20ms.
>
> CDI container resume:
>   Pre-initialized container state restored.
>   Bean instances from heap snapshot activated.
>   ~5-10ms.
>
> Configuration:
>   Properties from env vars / files read.
>   Config injection completed.
>   ~1-5ms.
>
> Framework startup:
>   HTTP server started.
>   Routes registered.
>   ~5-10ms.
>
> Total: 20-50ms typical.
> Quarkus record: 4.2ms (minimal service).
>
> Memory components (native):
>
> Code segment: ~30MB (native machine code).
> Heap snapshot: ~10-20MB (pre-initialized state).
> Runtime heap: 50-200MB (live objects, configurable).
> Thread stacks: ~2MB per thread.
> Native libraries: ~5MB.
>
> RSS vs JVM:
>   JVM RSS: metaspace (50MB) + code cache (50MB) +
>     JIT structures (50MB) + heap + threads.
>   Native RSS: code (30MB) + snapshot (15MB) + heap.
>   Typical saving: 50-70% RSS reduction.
>
> Tuning native memory:
>   Heap max: -Xmx256m (default: 25% of RAM).
>   Heap initial: -Xms64m.
>   GC selection: -H:+UseG1GC (Oracle only).
>   Thread stack: -Xss256k (default 512k).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how fast native
image starts and how much memory it uses."

**(2) First principles:** "No JVM init = instant start.
No JIT = less memory."

**(3) Bridge:** "Native startup is limited by binary loading
speed: mostly I/O bound, not computation."

---

### 💻 Code Example

```bash
# Measure startup time (Linux)
time ./target/app-runner
# Output last line: "Started in 0.043s"
# time output: real 0m0.067s (includes OS startup)

# Measure startup time precisely (Quarkus)
# Quarkus logs: "Installed features: [cdi, rest, ...]"
# Quarkus logs: "Quarkus 3.x.x started in 0.043s"
grep "started in" app.log

# Measure startup latency to first request
curl -o /dev/null -s -w "%{time_total}" \
  http://localhost:8080/q/health/ready
# First request: ~50ms (includes startup + request)

# Measure RSS (Resident Set Size)
# Linux: after app is running and serving requests
PID=$(pgrep app-runner)
cat /proc/$PID/smaps_rollup | grep Rss
# Output: Rss: 78432 kB (78MB)

# Alternative
ps -o pid,rss,vsz -p $PID
# RSS: 78432 kB

# Measure heap usage during load
./target/app-runner \
  -Xms32m -Xmx128m \
  -XX:+PrintGCDetails  # Serial GC verbose output

# JVM equivalent for comparison
java -Xms128m -Xmx256m \
  -XX:+UseG1GC \
  -jar target/app.jar
# Compare RSS: native vs JVM under same load

# Monitor native memory over time
watch -n5 "cat /proc/$PID/smaps_rollup | grep Rss"
# If RSS grows without bound: heap leak
# If RSS stable: expected steady-state
```

> **Code walkthrough:** The /proc/PID/smaps_rollup RSS
> value is the most accurate native memory measure on
> Linux: it includes code, heap, and stack. The -Xmx flag
> works in native image (SubstrateVM honors it). The GC
> details output from Serial GC shows pause time and
> heap occupancy: unlike JVM GC logs, native GC output
> is simpler (Serial GC has fewer options).

---

### 🎓 Answers by Seniority

**Junior:** "Native starts in milliseconds and uses 2-4x
less memory than JVM. Use time command for startup and
/proc/PID/smaps_rollup for RSS."

**Senior:** "In Kubernetes: set memory limits lower for
native. Container with -Xmx128m needs about 150MB limit
(code + heap + native overhead). JVM equivalent needs
400-500MB for similar workload."

---

### ⚖️ Comparison Table

| Metric | Native Image | JVM (Quarkus) | JVM (Spring) |
|---|---|---|---|
| Startup | 50-100ms | 1-2s | 5-15s |
| RSS at idle | 50-80MB | 150-250MB | 250-400MB |
| RSS at load | 100-200MB | 250-400MB | 400-600MB |
| Peak throughput | -10-20% | Baseline | Baseline |
| Build time | 5-10 min | Seconds | Seconds |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Startup time, RSS, basic comparison |
| Senior | 7 min | Memory components, tuning, Kubernetes sizing |

---

**[SENIOR] Q1 - How do you size Kubernetes
resource limits for native image containers?**

*Why they ask:* Production Kubernetes operations.

Native container sizing:

CPU request:
```yaml
resources:
  requests:
    cpu: "100m"    # Native: low idle CPU
  limits:
    cpu: "1000m"   # Allow burst for GC
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Memory request and limit:
```bash
# Determine baseline
# Start native app: ./app-runner
# No load: check RSS
# RSS: ~75MB

# Add GC headroom (2-3x heap max)
# -Xmx128m → GC needs ~384MB headroom
# Conservative: set limit = RSS_idle + (Xmx * 2)
# = 75MB + 256MB = 331MB → round up to 384Mi
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```yaml
resources:
  requests:
    memory: "128Mi"   # Minimum: RSS at idle
  limits:
    memory: "384Mi"   # RSS + GC headroom
env:
  - name: JAVA_OPTS
    value: "-Xms64m -Xmx128m"
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

OOMKilled diagnosis:
```bash
kubectl describe pod app-pod
# Look for: OOMKilled, Exit Code 137
# Last known memory usage before kill:
kubectl top pod app-pod --containers

# Solution: increase memory limit
# Or: reduce -Xmx
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Native vs JVM Kubernetes comparison:
```
Native:
  Request: 128Mi, Limit: 384Mi
  Pods per node (8GB): ~20
  Cost per 1000 RPS: $0.02/hr

JVM (Quarkus):
  Request: 256Mi, Limit: 512Mi
  Pods per node (8GB): ~15
  Cost per 1000 RPS: $0.027/hr

JVM (Spring):
  Request: 512Mi, Limit: 768Mi
  Pods per node (8GB): ~10
  Cost per 1000 RPS: $0.04/hr
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Memory limit is not
just Xmx: add native code size, heap overhead, thread
stacks, and GC working space.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Memory metrics, measurement commands. |
| Hiring Manager | Cost savings from native image. |
| Bar Raiser | Kubernetes sizing, OOMKilled diagnosis. |
| Peer Engineer | "Sized native containers: 50-100% memory reduction. 4 pods per node → 10 pods. Node count: 12 → 5." |

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



