# GraalVM Polyglot Context API

**Interview Weight:** medium - Polyglot API is a GraalVM
differentiator. Tested for breadth of knowledge and use
case awareness.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM Polyglot API allows Java programs to embed and
> execute other languages (JavaScript, Python, Ruby) within
> the same JVM process. The main entry point is the
> Context class: create a context, evaluate source code,
> pass Java objects to the guest language, and read back
> results. Use cases: rule engines using JavaScript,
> Python for ML inference, scripting hooks for end-user
> customization. Security: sandbox guest code with restricted
> privileges to prevent escape from the Context.

**3 minutes (Senior):**

> Core API components:
>
> Context:
>   Execution environment for a guest language.
>   Manages: thread safety, resource limits, access controls.
>   One context per isolation unit.
>   Not thread-safe: use one context per thread or synchronize.
>
> Source:
>   Guest language code (string, file, URL, reader).
>   Immutable once created.
>   Cached: compiled once, evaluate many times.
>
> Value:
>   Cross-language value wrapper.
>   Java-to-guest: automatic for primitives, strings.
>   Guest-to-Java: Value.as(Type.class) to convert.
>
> PolyglotException:
>   All guest exceptions wrapped in PolyglotException.
>   Access: getMessage(), getGuestObject(), isHostException().
>
> Access control:
>   hostClassLookupAllowed(false): guest can't load Java classes.
>   allowAllAccess(false): restrictive sandbox.
>   allowIO(false): no file I/O from guest.
>   allowCreateThread(false): no new threads from guest.
>
> Use cases:
>   JavaScript rule engine (business logic):
>     Rules defined by business team, not developers.
>     Java provides data, JS computes result.
>   Python ML inference:
>     GraalPy calls NumPy/SciPy from Java.
>     Tight integration: no HTTP overhead.
>   Scripting hooks:
>     Users customize app behavior via scripts.
>     Sandbox: cannot access Java internals.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the GraalVM API
for running other languages from Java."

**(2) First principles:** "Context = execution sandbox.
Value = cross-language value. Execute + interact."

**(3) Bridge:** "Polyglot Context is like running JavaScript
in Node.js but from within the JVM process."

---

### 💻 Code Example

```java
// BASIC: run JavaScript from Java

import org.graalvm.polyglot.*;

// Simple evaluation
try (Context ctx = Context.create()) {
    Value result = ctx.eval("js",
        "1 + 1");
    System.out.println(result.asInt()); // 2
}

// PRACTICAL: JavaScript rule engine
@ApplicationScoped
public class PricingRuleEngine {

    // Pre-compile rules (expensive)
    private final Source discountRule;

    public PricingRuleEngine() {
        this.discountRule = Source.newBuilder("js",
            // Language: JavaScript
            """
            (function(order) {
              let discount = 0;
              if (order.total > 1000) {
                discount += 0.10;  // 10% for large orders
              }
              if (order.tier === 'VIP') {
                discount += 0.05;  // 5% for VIP
              }
              return Math.min(discount, 0.20);
            })
            """,
            "discount-rule.js").build();
    }

    // Per-request: create isolated context
    public double computeDiscount(Order order) {
        // Context per request: thread-safe isolation
        try (Context ctx = Context.newBuilder("js")
                .allowHostAccess(
                    HostAccess.newBuilder()
                        // Allow: read order fields
                        .allowPublicAccess(true)
                        .build())
                .build()) {

            // Evaluate: gets the function
            Value discountFn = ctx.eval(discountRule);

            // Pass Java object to JavaScript
            Value result = discountFn.execute(order);

            return result.asDouble();
        }
    }
}

// Order class: fields accessible to JS via HostAccess
public class Order {
    public double total;     // order.total in JS
    public String tier;      // order.tier in JS
    public String id;
}

// BAD: Reuse context across threads
// Context is NOT thread-safe
// BAD:
private final Context sharedCtx =
    Context.create("js");  // WRONG
// Multiple threads call sharedCtx.eval() → race condition

// GOOD: Context per thread (ThreadLocal) or per request
private final ThreadLocal<Context> contextThreadLocal =
    ThreadLocal.withInitial(() ->
        Context.newBuilder("js")
            .allowAllAccess(false)
            .build());
```

> **Code walkthrough:** The PricingRuleEngine pre-compiles
> the Source (expensive: parse + compile) once in the
> constructor, then creates a new Context per request for
> isolation and thread safety. The HostAccess builder controls
> what Java objects are accessible from JavaScript: allowPublicAccess
> allows reading public fields. Order.total and Order.tier
> are accessible as order.total and order.tier in JavaScript.
> Context is AutoCloseable: use try-with-resources to ensure cleanup.

---

### 🎓 Answers by Seniority

**Junior:** "GraalVM Context API lets you run JavaScript or
Python from Java. Create a context, eval code, get a Value
back. Context must be closed after use."

**Senior:** "Context thread-safety is the main pitfall: one
context per thread or per request. Pre-compile Source objects
once. Use HostAccess to control what Java objects guest code
can access - important for security."

---

### ⚖️ Comparison Table

| Approach | Startup Cost | Thread-Safe | Isolation | Use Case |
|---|---|---|---|---|
| Shared Context | Low | No | None | Single-threaded tools |
| Context per request | Medium | Yes | High | Web services |
| ThreadLocal Context | Medium | Yes | Medium | High-throughput services |
| Separate JVM process | High | N/A | Complete | Untrusted user code |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Context creation, eval, Value |
| Senior | 8 min | Thread safety, HostAccess, use cases |

---

**[SENIOR] Q1 - What are the performance
characteristics of polyglot Context creation?**

*Why they ask:* Practical performance concerns.

Context creation cost:
- New Context: ~2-5ms (language initialization).
- First eval of Source: ~10-50ms (parse + compile).
- Subsequent eval of cached Source: ~0.1ms.

Optimization: separate context creation from Source evaluation.

```java
@ApplicationScoped
public class PolyglotService {

    // Engine: shared JIT state, context templates
    // One engine per application
    private static final Engine ENGINE =
        Engine.create();

    // Pre-compiled sources (shared across contexts)
    private final Map<String, Source> sourceCache =
        new ConcurrentHashMap<>();

    // Pool of contexts (amortize creation cost)
    private final BlockingQueue<Context> pool =
        new LinkedBlockingQueue<>();

    @PostConstruct
    void warmPool() {
        for (int i = 0; i < 10; i++) {
            pool.offer(buildContext());
        }
    }

    private Context buildContext() {
        return Context.newBuilder("js")
            .engine(ENGINE)  // Shared engine!
            .allowAllAccess(false)
            .build();
    }

    public Value eval(String langId, String code,
            Object... args) throws InterruptedException {
        Context ctx = pool.take();
        try {
            Source src = sourceCache
                .computeIfAbsent(code,
                    k -> Source.create(langId, k));
            Value fn = ctx.eval(src);
            return fn.execute(args);
        } finally {
            ctx.resetLimits();
            pool.offer(ctx);
        }
    }
}
```

Shared Engine:
- Engine holds the Graal JIT compiler state.
- Multiple contexts sharing an engine: JIT code shared.
- Context per request + shared engine: best of both.

Benchmark (typical):
- First eval (cold): 50ms.
- Subsequent eval (engine warm): 0.5ms.
- Context pool: eliminates 2-5ms creation per request.

*What separates good from great:* Shared Engine + pooled
contexts + pre-compiled Sources eliminates most overhead.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Context API, Source, Value. |
| Hiring Manager | Polyglot use cases. |
| Bar Raiser | Thread safety, Engine sharing, context pooling. |
| Peer Engineer | "Rule engine: 50ms per call (new context). After: shared engine + pool. 0.8ms per call. 60x improvement." |

---

---

# Running JavaScript on GraalVM

**Interview Weight:** medium - GraalJS is the primary
polyglot use case. Tests practical knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM includes GraalJS, an ES2024-compliant JavaScript
> engine. From Java: use the Polyglot Context API to evaluate
> JavaScript. From the command line: graalvm's node command
> (Node.js-compatible). GraalJS runs JavaScript significantly
> faster than Nashorn (removed from JDK 15). Common use
> cases from Java: JSON transformations, business rule
> evaluation, template rendering, user-defined scripts.
> Compatible with most Node.js modules via the node
> compatibility mode.

**3 minutes (Senior):**

> GraalJS deployment modes:
>
> 1. Embedded in Java (Polyglot API):
>    Context.eval("js", jsCode).
>    Pass Java objects to JS via HostAccess.
>    Get results back as Value.
>
> 2. Standalone JavaScript runtime:
>    $GRAALVM_HOME/bin/js (engine: GraalJS).
>    $GRAALVM_HOME/bin/node (Node.js compatibility).
>    Node.js module system, npm packages.
>
> 3. Native image with JS:
>    Polyglot native image: include JS engine in binary.
>    Build flag: --language:js.
>    Larger binary (~20MB more), but JS supported.
>
> Java-JavaScript interop:
>   Java → JS: primitives, strings, Java objects via HostAccess.
>   JS → Java: Value.as(String.class), Value.asInt(), etc.
>   Collections: JS arrays ↔ Java List (automatic).
>   Maps: JS objects ↔ Java Map (via ProxyObject).
>
> ES2024 feature support:
>   async/await: yes (but no event loop in Context).
>   Modules (import/export): yes (with module setting).
>   Promise: yes (but callbacks required from Java).
>   TypeScript: no (transpile first with tsc).
>
> Performance vs Nashorn (JDK 11):
>   Warm throughput: GraalJS 5-10x faster.
>   Memory: similar.
>   ECMAScript support: GraalJS ES2024 vs Nashorn ES5.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how GraalVM runs
JavaScript and how to use it from Java."

**(2) First principles:** "GraalJS = full JS engine + JVM
integration. Run JS, pass data, get results."

**(3) Bridge:** "GraalJS is like Node.js embedded in the JVM:
full JS runtime, bidirectional Java-JS data exchange."

---

### 💻 Code Example

```java
// PRACTICAL: JSON transformation using JavaScript
@ApplicationScoped
public class JsonTransformService {

    private final Source transformScript;

    public JsonTransformService() {
        // Pre-compile once
        this.transformScript = Source.newBuilder(
            "js",
            """
            (function(inputJson) {
              const data = JSON.parse(inputJson);
              return JSON.stringify({
                id: data.orderId,
                amount: data.totalAmount,
                status: data.orderStatus.toLowerCase(),
                items: data.lineItems.map(item => ({
                  sku: item.productSku,
                  qty: item.quantity
                }))
              });
            })
            """,
            "transform.js").build();
    }

    public String transform(String inputJson) {
        try (Context ctx = Context.create("js")) {
            Value fn = ctx.eval(transformScript);
            Value result = fn.execute(inputJson);
            return result.asString();
        }
    }
}

// PRACTICAL: User-defined business rule
// Rules written by business team, stored in DB
@ApplicationScoped
public class UserRuleEngine {

    @Inject
    RuleRepository ruleRepo;

    public boolean evaluate(
            String ruleId, Order order) {
        String ruleCode = ruleRepo
            .findById(ruleId).code();

        try (Context ctx = Context.newBuilder("js")
                .allowHostAccess(
                    HostAccess.EXPLICIT)
                .build()) {

            // Evaluate rule function from DB
            Value ruleFn = ctx.eval("js", ruleCode);

            // Pass order data as map (not Java object)
            // Safer: no Java class exposure
            Map<String, Object> orderData = Map.of(
                "total", order.getTotal(),
                "tier", order.getTier(),
                "itemCount", order.getItems().size()
            );

            Value result = ruleFn.execute(
                ctx.asValue(orderData));
            return result.asBoolean();
        }
    }
}

// BAD: execute untrusted code without sandbox
// User provides rule code → can access Java internals
// WRONG:
try (Context ctx = Context.newBuilder("js")
        .allowAllAccess(true)  // DANGEROUS
        .build()) {
    ctx.eval("js", userProvidedCode);
    // User can: Java.type('java.lang.Runtime')
    //   .getRuntime().exec('rm -rf /')
}

// GOOD: restrictive sandbox for user code
try (Context ctx = Context.newBuilder("js")
        .allowAllAccess(false)
        .allowHostAccess(HostAccess.NONE)
        .allowIO(IOAccess.NONE)
        .allowCreateThread(false)
        .build()) {
    ctx.eval("js", userProvidedCode);
    // Cannot: access Java classes
    // Cannot: file I/O
    // Cannot: create threads
}
```

> **Code walkthrough:** The JSON transformation example
> uses JavaScript's JSON.parse/stringify, which is
> standard and fast. The UserRuleEngine passes order
> data as a Map (not a Java Order object) to avoid
> exposing the Java class to the sandbox. The BAD/GOOD
> sandbox comparison shows the critical difference:
> allowAllAccess(true) allows Java.type() calls which
> can execute OS commands.

---

### 🎓 Answers by Seniority

**Junior:** "GraalJS runs JavaScript from Java via Context.eval.
Pre-compile Source for performance. Use sandbox (allowAllAccess=false)
for user-provided code."

**Senior:** "GraalJS is 5-10x faster than Nashorn and supports
ES2024. Practical use: rules stored in database, evaluated
at runtime. Pass data as Map not Java objects to minimize
sandbox exposure."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 4 min | Context.eval, Value, interop basics |
| Senior | 7 min | Sandbox, HostAccess, security, use cases |

---

**[SENIOR] Q1 - How do you prevent JavaScript
code from escaping the sandbox?**

*Why they ask:* Security-critical for user code execution.

Sandbox escape vectors:
1. Java.type() - access Java classes
2. Reflection via Java.type('java.lang.reflect.Method')
3. File I/O via Java.type('java.io.FileWriter')
4. Thread creation via Java.type('java.lang.Thread')

Prevention:
```java
Context ctx = Context.newBuilder("js")
    // Core restrictions
    .allowAllAccess(false)      // Disable all by default
    .allowHostAccess(           // Explicit host access
        HostAccess.newBuilder()
            // No Java type access from JS
            .allowPublicAccess(false)
            // No constructors from JS
            .allowAllImplementations(false)
            .build())
    .allowIO(IOAccess.NONE)         // No file access
    .allowCreateThread(false)       // No new threads
    .allowCreateProcess(false)      // No process exec
    .allowEnvironmentAccess(        // No env vars
        EnvironmentAccess.NONE)
    // Resource limits
    .option("js.ecmascript-version", "2023")
    .build();

// Execution limits (prevent infinite loops)
ctx.setResourceLimits(ResourceLimits.newBuilder()
    .statementLimit(100_000, null)  // Max 100k statements
    .build());
```

Testing the sandbox:
```javascript
// These should throw PolyglotException in sandbox:
Java.type('java.lang.Runtime')  // Blocked
Packages.java.lang.Thread       // Blocked
new java.io.FileReader('/')      // Blocked
```

```java
// Test sandbox is restrictive
@Test
void testSandboxPreventsJavaAccess() {
    try (Context ctx = buildSandboxedContext()) {
        assertThrows(PolyglotException.class, () ->
            ctx.eval("js",
                "Java.type('java.lang.Runtime')")
        );
    }
}
```

*What separates good from great:* Sandbox testing is as
important as production tests - explicitly verify that
Java.type() is blocked.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Context API, eval, Value. |
| Hiring Manager | JavaScript rule engine use case. |
| Bar Raiser | Sandbox security, escape vectors, resource limits. |
| Security Engineer | "allowAllAccess=true with user code = RCE. Sandbox escape test must be in the test suite." |

---

---

# GraalPy and TruffleRuby on GraalVM

**Interview Weight:** medium - Awareness of GraalVM
polyglot languages beyond JavaScript.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM includes implementations of Python (GraalPy,
> formerly GraalVM Python), Ruby (TruffleRuby), and R (FastR)
> via the Truffle framework. GraalPy can run CPython-compatible
> Python code with access to Python packages (NumPy, SciPy,
> Pandas) via a compatibility layer. TruffleRuby runs
> MRI-compatible Ruby code at JVM speeds. Both integrate
> with Java via the Polyglot Context API. Production readiness:
> GraalPy is production-ready for pure Python; C extensions
> (CPython API) have partial support.

**3 minutes (Senior):**

> GraalPy (Python on GraalVM):
>
> Compatibility:
>   CPython 3.10+ semantics.
>   Pure Python packages: mostly compatible.
>   C extensions (ctypes, cffi): partial support.
>   NumPy: supported via HPy or native reimplementation.
>
> Use cases from Java:
>   ML inference: load scikit-learn model, predict in Java.
>   Data processing: Pandas transformations from Java app.
>   Scripting: Python scripts as configuration hooks.
>
> From Java API:
>   Same Polyglot Context API.
>   ctx.eval("python", pythonCode).
>   or ctx.eval("python", source).
>
> TruffleRuby:
>
> Compatibility: MRI 3.x compatible.
> Pure Ruby: near-full compatibility.
> C extensions: most major gems supported via C API.
>
> Performance: 3-5x faster than MRI Ruby (JIT via Truffle).
>
> FastR (R on GraalVM):
>
> Status: community-supported, not primary product.
> Compatibility: R 3.x.
> Use case: statistical computation from Java.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Python and Ruby
support on GraalVM."

**(2) First principles:** "GraalVM uses Truffle: one interpreter
per language. All languages share JIT and JVM integration."

**(3) Bridge:** "GraalPy is like Jython but with Python 3,
better compatibility, and JIT performance."

---

### 💻 Code Example

```java
// GraalPy: Python ML inference from Java
@ApplicationScoped
public class PythonMLService {

    public double predict(double[] features) {
        // Build Python model inference script
        // Model loaded from pickle file at startup
        try (Context ctx = Context.newBuilder("python")
                .allowAllAccess(false)
                .allowIO(IOAccess.ALL)  // Need file access
                .allowCreateThread(false)
                .build()) {

            // Load Python ML model
            ctx.eval("python",
                """
                import pickle
                with open('model.pkl', 'rb') as f:
                    model = pickle.load(f)
                """);

            // Pass Java array → Python list
            Value pythonFeatures = ctx.eval("python",
                features.length + " * [0.0]");
            for (int i = 0; i < features.length; i++) {
                pythonFeatures.setArrayElement(
                    i, features[i]);
            }

            // Run inference
            ctx.getBindings("python")
               .putMember("features", pythonFeatures);
            Value prediction = ctx.eval("python",
                "model.predict([features])[0]");

            return prediction.asDouble();
        }
    }
}

// ALTERNATIVE: Use Python subprocess (simpler, more robust)
// For complex Python integration: subprocess is often better
// than polyglot due to C extension compatibility
@ApplicationScoped
public class PythonMLServiceAlt {

    // Separate Python process: no GraalVM dependency
    public double predict(double[] features)
            throws Exception {
        String featuresJson = Arrays.toString(features);
        ProcessBuilder pb = new ProcessBuilder(
            "python3", "predict.py", featuresJson);
        pb.redirectErrorStream(true);

        Process p = pb.start();
        String output = new String(
            p.getInputStream().readAllBytes());
        p.waitFor();

        return Double.parseDouble(output.trim());
    }
}
// Trade-off: subprocess = process overhead (~50ms)
// Polyglot = less overhead but more complexity
```

> **Code walkthrough:** The GraalPy example shows array
> interop: Java double[] is passed element-by-element to
> a Python list. The bindings API (ctx.getBindings("python").putMember)
> injects Java values as Python variables. The subprocess
> alternative shows the practical trade-off: for complex
> Python with C extensions, a separate Python process is
> often more reliable than embedded GraalPy.

---

### 🎓 Answers by Seniority

**Junior:** "GraalVM can run Python and Ruby. Use Context.eval('python', ...)
or Context.eval('ruby', ...). Same API as JavaScript."

**Senior:** "GraalPy is the most production-ready non-JS language.
For pure Python: works well. For NumPy/scikit-learn: mostly works.
For C extensions with complex CPython internals: test first.
Alternative: subprocess to a Python interpreter for full compatibility."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | GraalPy, TruffleRuby, basic usage |
| Senior | 6 min | Production readiness, C extensions, alternatives |

---

**[SENIOR] Q1 - When would you choose GraalPy
over a separate Python service?**

*Why they ask:* Architecture decision with trade-offs.

GraalPy (embedded) advantages:
- No network hop: in-process function call.
- Shared memory: pass large arrays without serialization.
- Simplified deployment: one binary.

Separate Python service advantages:
- Full CPython: all C extensions work (scikit, TF, PyTorch).
- Independent scaling: Python service scales separately.
- Language team ownership: Python team manages the service.
- Operational simplicity: standard Python deployment.

Decision criteria:
| Criterion | Choose GraalPy | Choose Separate Service |
|---|---|---|
| Python code | Pure Python | Heavy C extensions |
| Data size | Large (avoid serialization) | Small |
| Latency | Ultra-low (<1ms) | >10ms acceptable |
| Team | Same team | Separate Python team |
| Deployment | Single binary | Microservices OK |

Practical recommendation:
- Proof of concept: GraalPy (fast to experiment).
- Production ML with TensorFlow/PyTorch: separate service.
- Simple rule evaluation in Python: GraalPy.
- Data pipeline with Pandas: benchmark both.

*What separates good from great:* The answer considers
team ownership and operational complexity, not just technical merits.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | GraalPy API, C extension support. |
| Hiring Manager | When to use polyglot vs microservices. |
| Bar Raiser | Production readiness, architecture decision. |
| Peer Engineer | "Used GraalPy for pricing rules. Worked great. Tried TF inference via GraalPy: hit C API limits. Moved to gRPC Python service." |

---

---

# Polyglot Security Sandbox

**Interview Weight:** hard - Security is a Staff-level
concern. Sandbox configuration and attack vectors are
tested for production deployment.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM polyglot sandbox prevents guest language code
> from accessing the Java host environment beyond what's
> explicitly allowed. The three attack surfaces: host class
> access (Java.type()), host object manipulation (calling
> methods on passed Java objects), and resource access
> (file I/O, network, environment variables). Configure:
> Context.newBuilder with allowAllAccess(false), HostAccess.NONE
> or restrictive HostAccess, IOAccess.NONE. Test: explicitly
> verify that Java.type() and file I/O throw PolyglotException
> in tests.

**3 minutes (Senior):**

> Sandbox attack vectors:
>
> 1. Host class access:
>    Java.type('java.lang.Runtime').getRuntime().exec('...')
>    Controlled by: allowHostAccess.allowPublicAccess().
>    Block: HostAccess.newBuilder().allowPublicAccess(false).
>
> 2. Host object method calls:
>    Guest code calls methods on passed Java objects.
>    Example: order.getClass().getClassLoader().loadClass('...')
>    Controlled by: HostAccess method allowlist.
>    Block: use @HostAccess.Export on allowed methods only.
>
> 3. File I/O:
>    fs = Java.type('java.io.FileWriter')
>    Controlled by: allowIO(IOAccess.NONE).
>
> 4. Network access:
>    Currently: JS cannot easily access network without
>    Java interop (blocked by HostAccess).
>    Future: check each GraalVM release notes.
>
> 5. CPU exhaustion (infinite loop):
>    Guest code: while(true) {}
>    Controlled by: ResourceLimits.statementLimit().
>    Block: set statement limit per context.
>
> 6. Memory exhaustion:
>    Guest allocates huge arrays.
>    Controlled by: JVM heap limit (-Xmx).
>    Native: GraalVM 23+ adds heap limit options.
>
> Defense in depth:
>   1. allowAllAccess(false): deny-all default.
>   2. Explicit HostAccess allowlist.
>   3. IOAccess.NONE.
>   4. ResourceLimits for CPU.
>   5. JVM -Xmx for memory.
>   6. Test: attack tests in the test suite.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to secure guest
language code from accessing the Java host."

**(2) First principles:** "Sandbox = default-deny. Explicitly
allow only what's needed."

**(3) Bridge:** "Polyglot sandbox is like a Docker container:
isolated environment with explicit capability grants."

---

### 💻 Code Example

```java
// SECURE: Full sandbox configuration
public Context buildSecureSandbox() {
    return Context.newBuilder("js")
        // Deny all by default (most important setting)
        .allowAllAccess(false)
        // Explicit host access (deny all)
        .allowHostAccess(HostAccess.NONE)
        // No file I/O from guest
        .allowIO(IOAccess.NONE)
        // No new threads from guest
        .allowCreateThread(false)
        // No process creation
        .allowCreateProcess(false)
        // No environment variable access
        .allowEnvironmentAccess(
            EnvironmentAccess.NONE)
        // No native library loading
        .allowNativeAccess(false)
        // JS version (no exotic features)
        .option("js.ecmascript-version", "2023")
        .build();
}

// SECURE: Pass Java objects with allowlist
// Only expose methods needed by guest code
public class OrderFacade {

    private final Order order;  // Actual order

    public OrderFacade(Order order) {
        this.order = order;
    }

    // @HostAccess.Export: only this method accessible
    @HostAccess.Export
    public double getTotal() {
        return order.getTotal();
        // Guest cannot call: order.getClass()
        // Guest cannot call: order.setTotal()
        // Guest can only: facade.getTotal()
    }

    @HostAccess.Export
    public String getTier() {
        return order.getTier();
    }
    // Note: no setters exposed
    // Note: no getClass(), hashCode(), etc.
}

// Context with object allowlist
HostAccess hostAccess = HostAccess.newBuilder()
    .allowAccessAnnotatedBy(HostAccess.Export.class)
    .build();

Context ctx = Context.newBuilder("js")
    .allowAllAccess(false)
    .allowHostAccess(hostAccess)
    .allowIO(IOAccess.NONE)
    .allowCreateThread(false)
    .build();

// Resource limits: prevent infinite loops
ResourceLimits limits = ResourceLimits
    .newBuilder()
    .statementLimit(1_000_000, null)  // 1M statements
    .build();
ctx.setResourceLimits(limits);

// Pass safe facade, not real order
ctx.getBindings("js").putMember(
    "order",
    ctx.asValue(new OrderFacade(realOrder)));

Value result = ctx.eval("js", userScript);

// TESTING: Verify sandbox restrictions
@Test
void testSandboxBlocksJavaAccess() {
    try (Context ctx = buildSecureSandbox()) {
        // Should throw: Java.type not allowed
        assertThrows(PolyglotException.class,
            () -> ctx.eval("js",
                "Java.type('java.lang.Runtime')"));

        // Should throw: file system access
        assertThrows(PolyglotException.class,
            () -> ctx.eval("js",
                "const f = java.io.FileReader; f"));

        // Should succeed: pure computation
        Value result = ctx.eval("js", "1 + 1");
        assertEquals(2, result.asInt());
    }
}
```

> **Code walkthrough:** The OrderFacade facade pattern
> is the critical security pattern: wrap the real Java
> object in a facade that only exposes @HostAccess.Export
> annotated methods. Guest code gets the facade, not the
> real object. This prevents reflection attacks like
> order.getClass().getClassLoader(). ResourceLimits prevents
> CPU exhaustion. The test suite verifies that Java.type()
> is blocked - this test must be in CI.

---

### 🎓 Answers by Seniority

**Senior:** "allowAllAccess(false) + HostAccess.NONE is the
starting point. Then add only what's needed: @HostAccess.Export
on specific methods. Add ResourceLimits for CPU. Write tests
that verify Java.type() is blocked."

**Staff:** "Sandbox is defense in depth: GraalVM sandbox
controls access, JVM memory limits control allocation,
timeout/circuit breaker controls execution time. Monitor:
PolyglotException rate, context creation rate, memory usage.
Sandbox failures should alert, not silently fail."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Sandbox configuration, attack vectors |
| Staff | 12 min | Defense in depth, monitoring, facade pattern |

---

**[STAFF] Q1 - How do you monitor and alert
on polyglot sandbox violations in production?**

*Why they ask:* Production operations for security.

Sandbox violation monitoring:
```java
@ApplicationScoped
public class SandboxMetrics {

    @Inject
    MeterRegistry registry;

    private final Counter violationCounter;

    public SandboxMetrics(MeterRegistry registry) {
        this.violationCounter = Counter.builder(
            "polyglot.sandbox.violations")
            .tag("language", "js")
            .description(
                "Guest code sandbox violations")
            .register(registry);
    }

    public Value safeEval(Context ctx,
            String code, String scriptId) {
        try {
            return ctx.eval("js", code);
        } catch (PolyglotException e) {
            if (e.isGuestException()) {
                // Guest threw an exception: normal
                throw new RuleEvaluationException(
                    scriptId, e.getMessage());
            }
            // Host violation: security event
            violationCounter.increment();
            log.warn("Sandbox violation. script={} " +
                "message={}", scriptId,
                e.getMessage());
            // Alert: security team notification
            securityAlerter.sandboxViolation(
                scriptId, e.getMessage());
            throw new SecurityException(
                "Sandbox violation: " + scriptId);
        }
    }
}
```

Alert criteria:
- Any violation: notify security team within 5 minutes.
- Violation rate >1/hour: P1 incident.
- Same script ID violating repeatedly: block the script.

Audit logging:
- Log all script IDs evaluated (not the code itself).
- Log: user who submitted the script.
- Log: time, duration, result (not content).
- Retention: 90 days minimum (compliance).

*What separates good from great:* Every sandbox violation
is a security event. Treat it as an intrusion attempt.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | HostAccess, IOAccess, ResourceLimits. |
| Hiring Manager | Security-aware polyglot deployment. |
| Bar Raiser | Facade pattern, defense in depth. |
| Security Engineer | "Sandbox violation = security alert. Every violation needs a ticket. Why did user code try to access Java.type?" |
