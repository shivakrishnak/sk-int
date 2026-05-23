---
layout: default
title: "Spring - MVC and REST"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 5
permalink: /interview/spring/mvc-and-rest/
topic: Spring
subtopic: MVC and REST
keywords:
  - DispatcherServlet
  - Request Mapping and Handler Methods
  - Exception Handling
  - Content Negotiation
  - Validation
difficulty_range: easy to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [DispatcherServlet](#dispatcherservlet)
- [Request Mapping and Handler Methods](#request-mapping-and-handler-methods)
- [Exception Handling](#exception-handling)
- [Content Negotiation](#content-negotiation)
- [Validation](#validation)

# DispatcherServlet

**TL;DR** - DispatcherServlet is the single front controller that receives every HTTP request in a Spring MVC application, routes it to the correct handler method, and orchestrates the full request processing pipeline - model resolution, view rendering, and exception handling.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every URL requires a separate Servlet registered in `web.xml`. A 50-endpoint API means 50 Servlet mappings. Cross-cutting concerns (logging, auth, content negotiation) are duplicated in every Servlet. Routing logic is scattered across XML configuration.

**THE BREAKING POINT:**
Adding a new endpoint requires editing XML, creating a Servlet class, registering it, and redeploying. Teams cannot agree on consistent request handling because each Servlet has its own approach.

**THE INVENTION MOMENT:**
"This is exactly why DispatcherServlet was created."

**EVOLUTION:**
One Servlet per URL (Servlet API) -> Struts ActionServlet (single controller) -> Spring DispatcherServlet (Front Controller, Spring 1.0) -> annotation-based handlers (`@RequestMapping`, Spring 2.5) -> Boot auto-configuration (zero XML).

---

### 📘 Textbook Definition

`DispatcherServlet` is Spring MVC's implementation of the Front Controller pattern. It is a Servlet registered at `/` that intercepts all incoming HTTP requests and delegates them to the appropriate handler through a pipeline of HandlerMappings (URL to handler resolution), HandlerAdapters (method invocation), ViewResolvers (response rendering), and HandlerExceptionResolvers (error handling). In Spring Boot, it is auto-configured and registered at the root path with no XML required.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
One Servlet receives all requests and routes them to the right `@Controller` method.

**One analogy:**

> An airport control tower. Every flight (HTTP request) communicates with one tower (DispatcherServlet), which directs each plane to the correct gate (handler method), handles delays (exceptions), and manages the runway (response pipeline). Individual gates do not communicate with pilots directly.

**One insight:**
DispatcherServlet does not handle requests itself - it orchestrates. The actual work happens in HandlerMapping (find the handler), HandlerAdapter (invoke it), and ViewResolver (render response). Understanding these three delegates is understanding Spring MVC.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Every HTTP request passes through exactly one DispatcherServlet. There is a single entry point.
2. Handler resolution is pluggable. `HandlerMapping` implementations determine which method handles which URL.
3. The response pipeline (view resolution, content negotiation) is independent of the handler. A controller returns a model; the pipeline renders it.

**DERIVED DESIGN:**
From invariant 1: cross-cutting concerns (logging, auth, CORS) are applied once in the DispatcherServlet pipeline. From invariant 2: you can mix `@RequestMapping`, RouterFunction, and legacy Controller interfaces. From invariant 3: the same handler can return JSON or HTML depending on content negotiation.

**THE TRADE-OFFS:**

**Gain:** Single entry point, consistent pipeline, pluggable components.

**Cost:** All requests go through the same pipeline - performance overhead for simple passthrough use cases.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Web applications need routing, content negotiation, and exception handling.

**Accidental:** The Servlet API contract (init, service, destroy) is an implementation detail hidden by Spring.

---

### 🧠 Mental Model / Analogy

> DispatcherServlet is a hotel front desk. Every guest (request) checks in at the front desk (DispatcherServlet). The desk looks up the room assignment (HandlerMapping), calls the bellhop to escort the guest (HandlerAdapter invokes the handler), and arranges checkout (ViewResolver renders response). If something goes wrong, the desk handles complaints (ExceptionResolver).

- "Front desk" -> DispatcherServlet
- "Room assignment" -> HandlerMapping
- "Bellhop" -> HandlerAdapter
- "Checkout" -> ViewResolver
- "Complaint handling" -> ExceptionResolver

Where this analogy breaks down: Hotels handle guests in parallel; DispatcherServlet uses thread-per-request (or reactive) for concurrency.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A single "traffic controller" for your web app. It receives every request and sends it to the right place, like a receptionist directing visitors to the right office.

**Level 2 - How to use it (junior developer):**

In Spring Boot, you do not configure DispatcherServlet manually. It is auto-configured:

```java
@RestController
public class UserController {
    @GetMapping("/users/{id}")
    public User getUser(
            @PathVariable Long id) {
        return userService.findById(id);
    }
    // DispatcherServlet routes
    // GET /users/42 to this method
}
```

**Level 3 - How it works (mid-level engineer):**

Request processing pipeline:

```
  HTTP Request (GET /users/42)
       |
  DispatcherServlet.doDispatch()
       |
  1. HandlerMapping
     finds @GetMapping("/users/{id}")
     -> UserController.getUser()
       |
  2. HandlerAdapter
     invokes getUser(42)
     (resolves @PathVariable,
      @RequestBody)
       |
  3. Handler returns Object (User)
       |
  4. HttpMessageConverter
     serializes to JSON
     (Jackson ObjectMapper)
       |
  5. Response: 200 OK + JSON body
```

Exception path:

```
  Handler throws exception
       |
  HandlerExceptionResolver chain:
    @ExceptionHandler methods
    -> @ControllerAdvice
    -> DefaultHandlerExceptionResolver
       |
  Error response returned
```

**Level 4 - Mastery (senior/staff+ engineer):**

DispatcherServlet's key strategy interfaces:

| Interface         | Responsibility | Default              |
| ----------------- | -------------- | -------------------- |
| HandlerMapping    | URL -> handler | RequestMappingHM     |
| HandlerAdapter    | Invoke handler | RequestMappingHA     |
| ViewResolver      | Model -> view  | ContentNegotiatingVR |
| ExceptionResolver | Error handling | ExceptionHandlerER   |
| LocaleResolver    | i18n locale    | AcceptHeaderLR       |
| MultipartResolver | File uploads   | StandardServletMR    |

Customizing the pipeline:

```java
@Configuration
public class WebConfig
        implements WebMvcConfigurer {
    @Override
    public void addInterceptors(
            InterceptorRegistry reg) {
        reg.addInterceptor(
            new LoggingInterceptor());
    }

    @Override
    public void configureMessageConverters(
            List<HttpMessageConverter<?>>
            converters) {
        converters.add(
            new MappingJackson2Xml
            HttpMessageConverter());
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "DispatcherServlet routes requests to controllers."

**A Staff says:** "DispatcherServlet is a pipeline of pluggable strategies. I customize HandlerInterceptors for cross-cutting concerns, configure message converters for content negotiation, and understand that `@RestController` returns go through `HttpMessageConverter` while `@Controller` returns go through `ViewResolver` - two completely different paths in the same pipeline."

**The difference:** Staff engineers see DispatcherServlet as a configurable pipeline, not a black box.

**Level 5 - Distinguished (expert thinking):**
DispatcherServlet is the Front Controller pattern (GoF) applied to the Servlet API. The same pattern appears in Ruby on Rails (Action Controller), ASP.NET MVC (RouteHandler), and Express.js (middleware pipeline). Spring WebFlux replaces DispatcherServlet with `DispatcherHandler` for reactive, non-blocking processing. At scale, DispatcherServlet's thread-per-request model limits throughput for I/O-bound workloads - the shift to WebFlux or virtual threads (Java 21) addresses this.

---

### ⚙️ How It Works

```
  Servlet Container (Tomcat)
       |
  Receives HTTP request
       |
  Routes to DispatcherServlet
  (mapped to /)
       |
  doDispatch() method:
       |
  1. getHandler():
     iterate HandlerMappings
     return HandlerExecutionChain
     (handler + interceptors)
       |
  2. getHandlerAdapter():
     find adapter for handler type
       |
  3. applyPreHandle():
     run interceptor.preHandle()
       |
  4. ha.handle():
     adapter invokes handler method
     returns ModelAndView
       |
  5. applyPostHandle():
     run interceptor.postHandle()
       |
  6. processDispatchResult():
     render view or write response
       |
  7. triggerAfterCompletion():
     cleanup,
     interceptor.afterCompletion()
```

For `@RestController`, step 4 uses `RequestMappingHandlerAdapter` which resolves method arguments (`@PathVariable`, `@RequestBody`), invokes the method, and writes the return value via `HttpMessageConverter` (skipping ViewResolver entirely).

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Client -> Tomcat -> Filter Chain
       |
  DispatcherServlet <- HERE
       |
  HandlerMapping -> Handler
  HandlerAdapter -> invoke
  MessageConverter -> JSON response
       |
  Filter Chain -> Tomcat -> Client
```

**FAILURE PATH:**
No handler found -> 404 (if `throwExceptionIfNoHandlerFound=true`, throws `NoHandlerFoundException` catchable in `@ControllerAdvice`). Handler throws -> ExceptionResolver chain -> error response.

**WHAT CHANGES AT SCALE:**
At low traffic: thread-per-request is fine. At high I/O-bound traffic: thread pool exhaustion. Solutions: WebFlux (reactive), virtual threads (Java 21), or async handlers (`DeferredResult`, `Callable`).

---

### 💻 Code Example

**Example 1 - BAD multiple Servlets vs GOOD DispatcherServlet:**

```java
// BAD - one Servlet per endpoint (old)
// web.xml: 50 <servlet-mapping> entries
public class UserServlet
        extends HttpServlet {
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp) {
        // parse path, handle, write JSON
    }
}

// GOOD - one DispatcherServlet, N handlers
@RestController
@RequestMapping("/users")
public class UserController {
    @GetMapping("/{id}")
    public User get(
            @PathVariable Long id) {
        return service.findById(id);
    }
    @PostMapping
    public User create(
            @RequestBody User u) {
        return service.save(u);
    }
}
```

**How to test / verify correctness:**
Use `MockMvc` to test the full DispatcherServlet pipeline without starting a server:

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;
    @Test
    void getsUser() throws Exception {
        mvc.perform(get("/users/1"))
            .andExpect(status().isOk());
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Single front controller Servlet that routes all HTTP requests to handler methods.

**PROBLEM IT SOLVES:** Eliminates per-URL Servlet configuration with a centralized, pluggable pipeline.

**KEY INSIGHT:** DispatcherServlet orchestrates, not executes. Six strategy interfaces do the work.

**USE WHEN:** Every Spring MVC/Boot web application (it is always there).

**AVOID WHEN:** Reactive apps use `DispatcherHandler` instead (WebFlux).

**ANTI-PATTERN:** Bypassing DispatcherServlet with raw Servlet registrations (loses Spring features).

**TRADE-OFF:** Centralized pipeline vs. all-requests-through-one-chokepoint.

**ONE-LINER:** "One Servlet, six strategies, every request."

**KEY NUMBERS:** 7 pipeline steps. 6 pluggable strategies. Thread-per-request model.

**TRIGGER PHRASE:** "Front Controller pattern."

**OPENING SENTENCE:** "DispatcherServlet is the Front Controller that intercepts every HTTP request, delegating to HandlerMapping for routing, HandlerAdapter for invocation, and either HttpMessageConverter (REST) or ViewResolver (MVC) for response rendering."

**If you remember only 3 things:**

1. Front Controller: one Servlet routes all requests
2. Six pluggable strategies: HandlerMapping, HandlerAdapter, ViewResolver, ExceptionResolver, LocaleResolver, MultipartResolver
3. @RestController -> HttpMessageConverter path (no ViewResolver)

**Interview one-liner:**
"DispatcherServlet is the Front Controller. It delegates to HandlerMapping to find the handler, HandlerAdapter to invoke it, and either HttpMessageConverter (REST) or ViewResolver (MVC) for response. Six pluggable strategy interfaces make the pipeline fully customizable."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the 7-step doDispatch pipeline from request to response
2. **DEBUG:** Given a 404 error, determine whether HandlerMapping could not find a match and why
3. **DECIDE:** Choose between `@RestController` (message converter path) and `@Controller` (view resolver path)
4. **BUILD:** Add a custom HandlerInterceptor for request timing and understand where it fits in the pipeline
5. **EXTEND:** Compare DispatcherServlet (thread-per-request) with DispatcherHandler (reactive) and virtual threads

---

### 💡 The Surprising Truth

DispatcherServlet handles both REST APIs and server-side rendered pages through the same pipeline, but they take completely different paths after the handler executes. `@RestController` methods go through `HttpMessageConverter` (Jackson serializes to JSON). `@Controller` methods go through `ViewResolver` (Thymeleaf renders HTML). The divergence point is the `@ResponseBody` annotation (implicit in `@RestController`). Understanding this fork explains many confusing behaviors: why returning a String from `@RestController` gives you a plain text response, not a view name.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                  | Reality                                                                                                         |
| --- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| 1   | "Each controller is a Servlet"                 | One DispatcherServlet handles all controllers. Controllers are POJOs.                                           |
| 2   | "DispatcherServlet processes the request"      | It orchestrates. HandlerMapping, HandlerAdapter, and converters do the work.                                    |
| 3   | "@RestController and @Controller are the same" | @RestController = @Controller + @ResponseBody. Different response pipeline.                                     |
| 4   | "Filters and interceptors are the same"        | Filters are Servlet-level (before DispatcherServlet). Interceptors are Spring-level (inside DispatcherServlet). |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: 404 despite correct @RequestMapping**

**Symptom:** Endpoint returns 404 even though the controller has the mapping.

**Root Cause:** Controller not in component scan base package. Or mapping path does not match (trailing slash, typo).

**Diagnostic:**

```bash
# Enable mapping logging:
logging.level.org.springframework\
  .web.servlet.handler=TRACE
# Shows all registered mappings at
# startup
```

**Fix:**

BAD: Hardcoding a Servlet mapping to bypass DispatcherServlet.

GOOD: Ensure controller is in a scanned package. Check exact path (case-sensitive, no trailing slash mismatch).

**Prevention:** `@WebMvcTest` for each controller catches mapping issues in CI.

**Failure Mode 2: Wrong HttpMessageConverter used**

**Symptom:** Response is XML instead of JSON, or plain text instead of JSON.

**Root Cause:** Accept header mismatch or wrong converter order. Or Jackson not on classpath.

**Diagnostic:**

```bash
curl -H "Accept: application/json" \
  localhost:8080/users/1
# Check Content-Type of response
```

**Fix:**

BAD: Hardcoding `produces = "application/json"` on every method.

GOOD: Ensure Jackson is on classpath (via starter-web). Check converter order.

**Prevention:** starter-web includes Jackson by default.

**Failure Mode 3: Thread pool exhaustion under load**

**Symptom:** Requests time out. Tomcat rejects connections with "Connection refused."

**Root Cause:** All threads blocked on slow downstream calls (DB, external API). Thread-per-request model.

**Diagnostic:**

```bash
# Thread dump shows all threads
# WAITING on downstream:
curl localhost:8080/actuator/threaddump
```

**Fix:**

BAD: Increasing thread pool to 500 (delays the problem).

GOOD: Add timeouts to downstream calls. Use async handlers (`DeferredResult`) or virtual threads for I/O-bound work.

**Prevention:** Set `server.tomcat.threads.max` conservatively and monitor with Actuator metrics.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What is DispatcherServlet and how does it process a request?**

_Why they ask:_ Core Spring MVC understanding.
_Likely follow-up:_ "What is a HandlerMapping?"

**Answer:**
DispatcherServlet is the Front Controller - one Servlet that receives every HTTP request and routes it.

Processing pipeline:

1. **HandlerMapping** finds which method handles the URL
2. **HandlerAdapter** invokes the method (resolves `@PathVariable`, `@RequestBody`)
3. **Handler** executes and returns result
4. **HttpMessageConverter** serializes to JSON (REST) or **ViewResolver** renders HTML (MVC)
5. Response sent to client

All cross-cutting concerns (interceptors, exception handling) are centralized in this pipeline.

In Boot, it is auto-configured at `/` - no XML or registration needed.

_What separates good from great:_ Naming the specific strategy interfaces and explaining the REST vs MVC fork.

---

**Q2 [MID]: What is the difference between a Filter and a HandlerInterceptor?**

_Why they ask:_ Tests understanding of the request processing layers.
_Likely follow-up:_ "When would you use each?"

**Answer:**

| Dimension     | Filter                    | Interceptor              |
| ------------- | ------------------------- | ------------------------ |
| Level         | Servlet API               | Spring MVC               |
| Scope         | All requests              | DispatcherServlet only   |
| Access to     | Raw request/response      | Handler, ModelAndView    |
| Lifecycle     | Before DispatcherServlet  | Inside DispatcherServlet |
| Spring beans? | Via DelegatingFilterProxy | Yes (full DI)            |

Use **Filter** for:

- Security (Spring Security is a Filter chain)
- Request/response wrapping (compression)
- Logging raw HTTP data

Use **Interceptor** for:

- Timing handler execution
- Modifying ModelAndView before rendering
- Handler-specific preconditions

```
Filter.doFilter() ->
  DispatcherServlet ->
    Interceptor.preHandle() ->
      Handler ->
    Interceptor.postHandle() ->
  DispatcherServlet ->
Filter.doFilter() return
```

_What separates good from great:_ The execution order diagram showing filters wrap DispatcherServlet while interceptors are inside it.

---

**Q3 [SENIOR]: How would you handle thread pool exhaustion in a Spring MVC app under high load?**

_Why they ask:_ Tests production problem-solving.
_Likely follow-up:_ "When would you switch to WebFlux?"

**Answer:**
Diagnosis: all Tomcat threads blocked on I/O (downstream calls).

Short-term:

1. Add timeouts to all downstream calls
2. Set Tomcat thread pool appropriately

Medium-term - async handlers:

```java
@GetMapping("/report")
DeferredResult<Report> getReport() {
    var result =
        new DeferredResult<Report>(5000L);
    asyncService.generate(r ->
        result.setResult(r));
    return result;
    // Thread released immediately
}
```

Long-term options:

- Java 21 virtual threads (easiest migration)
- WebFlux for fully reactive pipeline
- API Gateway with rate limiting

Virtual threads are the best migration path - change one config property, keep all existing code.

_What separates good from great:_ Progressive solution and recommending virtual threads over WebFlux rewrite.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- IoC Container and Dependency Injection - DispatcherServlet strategies are DI-managed beans
- Auto-Configuration - DispatcherServlet is auto-configured in Boot

**Builds on this (learn these next):**

- Request Mapping and Handler Methods - how handlers are registered
- Exception Handling - the error path in the pipeline

**Alternatives / Comparisons:**

- Spring WebFlux DispatcherHandler - reactive equivalent (non-blocking)
- Jakarta Servlet API - the underlying spec DispatcherServlet implements

---

---

# Request Mapping and Handler Methods

**TL;DR** - `@RequestMapping` and its shortcuts (`@GetMapping`, `@PostMapping`, etc.) bind HTTP requests to Java methods by URL pattern, HTTP method, headers, and content type - with automatic argument resolution for path variables, query params, and request bodies.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Routing logic lives in `if/else` chains inside a Servlet's `doGet()` method. Path variables require manual `request.getRequestURI().split("/")` parsing. Request body deserialization requires manual `ObjectMapper.readValue()` calls. Type conversion and validation are hand-coded.

**THE BREAKING POINT:**
A 100-endpoint API has a massive `doGet()` method with a giant switch statement on URL patterns. Adding an endpoint means touching a 2000-line file.

**THE INVENTION MOMENT:**
"This is exactly why @RequestMapping was created."

**EVOLUTION:**
Servlet `doGet()`/`doPost()` -> Struts Action mappings (XML) -> Spring `@RequestMapping` (annotation, Spring 2.5) -> shortcut annotations `@GetMapping` etc. (Spring 4.3) -> functional `RouterFunction` (Spring 5).

---

### 📘 Textbook Definition

`@RequestMapping` is a Spring MVC annotation that maps HTTP requests to handler methods based on URL pattern, HTTP method, request parameters, headers, and content type. Shortcut annotations (`@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping`) combine `@RequestMapping` with a specific HTTP method. Handler method arguments are resolved automatically by `HandlerMethodArgumentResolver` implementations: `@PathVariable` for URL segments, `@RequestParam` for query parameters, `@RequestBody` for deserialized request body, `@RequestHeader` for HTTP headers.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Annotate a method with `@GetMapping("/users/{id}")` and Spring routes matching requests to it, automatically converting path variables, query params, and request bodies.

**One analogy:**

> A phone menu system. "Press 1 for Sales" = `@GetMapping("/sales")`. "Press 2 for Support" = `@GetMapping("/support")`. The operator (DispatcherServlet) routes the call; the department (handler method) handles it.

**One insight:**
The argument resolution is the real power. `@PathVariable Long id` converts "42" to a `Long`. `@RequestBody Order order` deserializes JSON to a Java object. `@Valid` triggers validation. All without writing parsing code.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Mapping resolution is deterministic. The most specific mapping wins. `/users/{id}` beats `/users/*`.
2. Argument resolution is pluggable. `HandlerMethodArgumentResolver` implementations handle each annotation type.
3. Return value handling is also pluggable. `HandlerMethodReturnValueHandler` decides how to write the response.

**DERIVED DESIGN:**
From invariant 1: you never have ambiguous routing (Spring fails fast if two mappings conflict). From invariant 2: custom argument resolvers can inject any type (logged-in user, tenant context). From invariant 3: returning `ResponseEntity<T>` gives full control; returning `T` uses defaults.

**THE TRADE-OFFS:**

**Gain:** Declarative routing, type-safe arguments, zero parsing code.

**Cost:** Annotation-heavy code. Complex mapping rules can be hard to debug.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** HTTP APIs need routing, argument parsing, and response serialization.

**Accidental:** Multiple ways to express the same mapping (`@RequestMapping` vs `@GetMapping` vs `RouterFunction`).

---

### 🧠 Mental Model / Analogy

> Handler methods are like labeled mailboxes in an apartment building. The address (URL) identifies the building, the apartment number (path variable) identifies the recipient, and the package type (Content-Type) determines how it is delivered. The mail carrier (DispatcherServlet) reads the label and delivers to the right box.

- "Address" -> URL pattern
- "Apartment number" -> @PathVariable
- "Package type" -> Content-Type / Accept headers
- "Mail carrier" -> DispatcherServlet + HandlerMapping
- "Mailbox label" -> @GetMapping annotation

Where this analogy breaks down: Mailboxes are passive; handler methods actively process and return responses.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Annotations on methods that tell Spring "when someone visits this URL, run this code." Like labeling functions with their web address.

**Level 2 - How to use it (junior developer):**

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public List<User> list() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public User get(
            @PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping
    @ResponseStatus(CREATED)
    public User create(
            @Valid @RequestBody
            CreateUserRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(NO_CONTENT)
    public void delete(
            @PathVariable Long id) {
        service.delete(id);
    }
}
```

**Level 3 - How it works (mid-level engineer):**

Argument resolution:

| Annotation      | Source       | Example                     |
| --------------- | ------------ | --------------------------- |
| @PathVariable   | URL segment  | `/users/{id}` -> `Long id`  |
| @RequestParam   | Query string | `?name=Jo` -> `String name` |
| @RequestBody    | Request body | JSON -> Java object         |
| @RequestHeader  | HTTP header  | `Authorization` -> String   |
| @CookieValue    | Cookie       | Session cookie -> String    |
| @ModelAttribute | Form data    | Form fields -> object       |

Return value handling:

| Return Type            | Behavior                       |
| ---------------------- | ------------------------------ |
| `T` (@RestController)  | Serialize via Jackson          |
| `ResponseEntity<T>`    | Full control (status, headers) |
| `String` (@Controller) | View name for ViewResolver     |
| `void`                 | Status 200, no body            |

**Level 4 - Mastery (senior/staff+ engineer):**

Advanced mapping features:

```java
// Multiple paths
@GetMapping({"/users", "/accounts"})

// Regex path variable
@GetMapping(
    "/files/{name:[a-z]+\\.txt}")

// Headers condition
@GetMapping(value = "/api",
    headers = "X-API-Version=2")

// Params condition
@GetMapping(value = "/search",
    params = "type=advanced")

// Content negotiation
@PostMapping(
    consumes = "application/json",
    produces = "application/json")
```

Custom argument resolver:

```java
@Component
public class CurrentUserResolver
        implements
        HandlerMethodArgumentResolver {

    public boolean supportsParameter(
            MethodParameter p) {
        return p.hasParameterAnnotation(
            CurrentUser.class);
    }

    public Object resolveArgument(
            MethodParameter p,
            ModelAndViewContainer mvc,
            NativeWebRequest req,
            WebDataBinderFactory b) {
        return SecurityContextHolder
            .getContext()
            .getAuthentication()
            .getPrincipal();
    }
}

// Usage:
@GetMapping("/profile")
public Profile get(
        @CurrentUser User user) {
    return profileService.get(user);
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@GetMapping` for GET requests and `@PostMapping` for POST."

**A Staff says:** "I design consistent API contracts: resources are nouns, HTTP methods are verbs, status codes are meaningful. I use custom argument resolvers for cross-cutting concerns (current user, tenant context) and `ResponseEntity` only when I need custom status codes or headers."

**The difference:** Staff engineers design API conventions and custom resolvers.

**Level 5 - Distinguished (expert thinking):**
Request mapping is declarative routing - the same concept appears in Express.js (`app.get('/users/:id')`), Flask (`@app.route`), and ASP.NET (`[HttpGet("{id}")]`). Spring 5 added `RouterFunction` as a functional alternative to annotations, allowing programmatic route definition. At scale, the challenge is not routing but API versioning: URL path (`/v2/users`), header (`X-API-Version`), or content type (`application/vnd.app.v2+json`).

---

### ⚙️ How It Works

```
  @GetMapping("/users/{id}") registered
  at startup by
  RequestMappingHandlerMapping
       |
  Request: GET /users/42
       |
  HandlerMapping matches URL pattern
  to UserController.get(Long)
       |
  HandlerAdapter prepares invocation:
    @PathVariable "id" -> "42"
    ConversionService: "42" -> Long 42
       |
  Method invoked: get(42)
       |
  Return value: User object
       |
  @RestController ->
  HttpMessageConverter (Jackson)
  -> JSON response
```

At startup, `RequestMappingHandlerMapping` scans all `@Controller` classes, finds `@RequestMapping` annotations, and builds a mapping registry. At request time, it matches the incoming URL against this registry.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Client: GET /api/users/42
       |
  DispatcherServlet
       |
  HandlerMapping: match to
  UserController.get(Long)
       |
  Interceptors: preHandle()
       |
  ArgumentResolver:
  @PathVariable "42" -> Long 42
       |
  Handler: get(42) -> User
       |
  ReturnValueHandler:
  Jackson -> {"name":"John",...}
       |
  Response: 200 OK, JSON body
```

**FAILURE PATH:**
No mapping found -> 404. Ambiguous mapping -> `IllegalStateException` at startup. Type conversion fails (`/users/abc` for Long) -> 400.

**WHAT CHANGES AT SCALE:**
At 50 endpoints: straightforward. At 500: naming conventions and consistent error responses become critical. Use `@ControllerAdvice` for consistent error format. Use OpenAPI/Swagger for documentation.

---

### 💻 Code Example

**Example 1 - BAD manual parsing vs GOOD annotations:**

```java
// BAD - manual Servlet parsing
protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp) {
    String path = req.getRequestURI();
    String[] parts = path.split("/");
    Long id = Long.parseLong(parts[2]);
    User user = service.findById(id);
    resp.setContentType(
        "application/json");
    resp.getWriter().write(
        objectMapper
        .writeValueAsString(user));
}

// GOOD - declarative mapping
@GetMapping("/users/{id}")
public User get(
        @PathVariable Long id) {
    return service.findById(id);
}
```

**Example 2 - ResponseEntity for full control:**

```java
@PostMapping("/users")
public ResponseEntity<User> create(
        @Valid @RequestBody
        CreateUserRequest req) {
    User user = service.create(req);
    URI location = URI.create(
        "/users/" + user.getId());
    return ResponseEntity
        .created(location)
        .body(user);
    // 201 Created + Location header
}
```

**How to test / verify correctness:**

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired MockMvc mvc;

    @Test
    void returnsUserById()
            throws Exception {
        mvc.perform(get("/api/users/42"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name")
                .value("John"));
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Annotation-based HTTP routing with automatic argument resolution.

**PROBLEM IT SOLVES:** Eliminates manual URL parsing, body deserialization, and response serialization.

**KEY INSIGHT:** Argument resolvers are the real power - they convert raw HTTP data to typed Java objects.

**USE WHEN:** Every REST endpoint in a Spring MVC application.

**AVOID WHEN:** Highly dynamic routes (use `RouterFunction` instead).

**ANTI-PATTERN:** Using `HttpServletRequest` directly when argument annotations suffice.

**TRADE-OFF:** Declarative convenience vs. annotation-heavy code.

**ONE-LINER:** "@GetMapping + @PathVariable = declarative routing with type-safe arguments."

**KEY NUMBERS:** 6 shortcut annotations. 6+ argument resolvers. Most-specific-wins matching.

**TRIGGER PHRASE:** "Most specific mapping wins."

**OPENING SENTENCE:** "@RequestMapping and its shortcuts bind URLs to handler methods with automatic argument resolution - @PathVariable extracts URL segments, @RequestBody deserializes JSON, and @Valid triggers validation, eliminating all manual HTTP parsing."

**If you remember only 3 things:**

1. @GetMapping/@PostMapping shortcuts > @RequestMapping with method=
2. Argument resolvers: @PathVariable, @RequestParam, @RequestBody, @RequestHeader
3. Custom HandlerMethodArgumentResolver for cross-cutting params

**Interview one-liner:**
"@GetMapping maps URLs to methods. Arguments are resolved automatically: @PathVariable for URL segments, @RequestBody for JSON deserialization, @Valid for validation. Custom argument resolvers inject cross-cutting context. Return values are serialized by HttpMessageConverter."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe how HandlerMapping resolves a URL to a method and how arguments are resolved
2. **DEBUG:** Given "404 on a mapped endpoint," check component scanning, path typos, and TRACE-level logs
3. **DECIDE:** Choose between `ResponseEntity<T>` (custom status/headers) and plain return (default 200)
4. **BUILD:** Create a custom `HandlerMethodArgumentResolver` for `@CurrentUser`
5. **EXTEND:** Compare annotation routing with functional `RouterFunction`

---

### 💡 The Surprising Truth

`@RequestMapping` resolution follows a "most specific wins" rule that can produce surprising results. If you have `@GetMapping("/users/admin")` and `@GetMapping("/users/{id}")`, a request to `/users/admin` matches the literal path, not the path variable. But `/users/admin/settings` would not match either (no `/**` suffix). Understanding the specificity rules - literal segments beat path variables, path variables beat wildcards - prevents routing surprises.

---

### ⚠️ Common Misconceptions

| #   | Misconception                          | Reality                                                                  |
| --- | -------------------------------------- | ------------------------------------------------------------------------ |
| 1   | "@RequestMapping handles only GET"     | Without method attribute, it handles ALL HTTP methods.                   |
| 2   | "@PathVariable must match param name"  | `@PathVariable("id") Long userId` works. Name matching is a convenience. |
| 3   | "Order of controllers matters"         | Spring uses most-specific-match, not first-match.                        |
| 4   | "@RequestParam is required by default" | Yes. Use `required = false` or `Optional<String>` to make it optional.   |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Ambiguous mapping at startup**

**Symptom:** `IllegalStateException: Ambiguous mapping.`

**Root Cause:** Two handler methods map to the same URL + HTTP method.

**Diagnostic:** Error message names both methods.

**Fix:**

BAD: Removing one mapping without understanding intent.

GOOD: Make paths distinct or merge into one controller.

**Prevention:** Review API design before implementation. Use OpenAPI spec.

**Failure Mode 2: 400 Bad Request from type conversion**

**Symptom:** `MethodArgumentTypeMismatchException` - path variable cannot be converted.

**Root Cause:** Client sends `/users/abc` where `Long` is expected.

**Diagnostic:**

```bash
curl -v localhost:8080/users/abc
# 400 + "Failed to convert 'String'
# to 'Long'"
```

**Fix:**

BAD: Catching exception per-endpoint.

GOOD: Handle in `@ControllerAdvice` with a clean 400 response.

**Prevention:** Document API contract. Input validation at the edge.

**Failure Mode 3: @RequestBody null fields**

**Symptom:** JSON deserialized but fields are null despite being in the request.

**Root Cause:** Jackson cannot bind: no default constructor, field name mismatch, or missing getters.

**Diagnostic:**

```java
@PostMapping("/users")
public User create(
        @RequestBody String raw) {
    log.info("Raw: {}", raw);
    // Compare raw JSON with expected
}
```

**Fix:**

BAD: Adding null checks everywhere.

GOOD: Fix the Java class or configure Jackson naming strategy.

**Prevention:** Use records or `@JsonProperty`. Test deserialization separately.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: How do you map an HTTP GET request to a Java method?**

_Why they ask:_ Basic web knowledge.
_Likely follow-up:_ "How do you get the ID from the URL?"

**Answer:**
Use `@GetMapping` on a method in a `@RestController`:

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    @GetMapping("/{id}")
    public User get(
            @PathVariable Long id) {
        return service.findById(id);
    }
}
```

`@PathVariable` extracts `{id}` from the URL and converts it. Other annotations: `@RequestParam` for query strings, `@RequestBody` for JSON body, `@RequestHeader` for headers.

_What separates good from great:_ Listing argument annotations and mentioning `@RestController` = `@Controller` + `@ResponseBody`.

---

**Q2 [MID]: How would you implement API versioning in Spring MVC?**

_Why they ask:_ Tests API design thinking.
_Likely follow-up:_ "Which approach do you prefer?"

**Answer:**
Three approaches:

1. **URL path** (most common):

```java
@RequestMapping("/api/v1/users")
class UserControllerV1 { }
@RequestMapping("/api/v2/users")
class UserControllerV2 { }
```

Pro: Simple, cacheable. Con: URL pollution.

2. **Custom header:**

```java
@GetMapping(value = "/users",
    headers = "X-API-Version=2")
```

Pro: Clean URLs. Con: Not cacheable.

3. **Content type:**

```java
@GetMapping(produces =
    "application/vnd.app.v2+json")
```

Pro: RESTful. Con: Complex client setup.

I prefer URL path for public APIs and header versioning for internal APIs.

_What separates good from great:_ Evaluating trade-offs (caching, discoverability) rather than just listing options.

---

**Q3 [SENIOR]: Design a custom argument resolver for multi-tenant context.**

_Why they ask:_ Tests framework extension skills.
_Likely follow-up:_ "Where does the tenant ID come from?"

**Answer:**

```java
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface TenantContext {}

@Component
public class TenantArgumentResolver
        implements
        HandlerMethodArgumentResolver {

    public boolean supportsParameter(
            MethodParameter p) {
        return p.hasParameterAnnotation(
            TenantContext.class);
    }

    public Object resolveArgument(
            MethodParameter p,
            ModelAndViewContainer mvc,
            NativeWebRequest req,
            WebDataBinderFactory b) {
        String tid = req.getHeader(
            "X-Tenant-ID");
        if (tid == null) {
            throw new ResponseStatus
                Exception(BAD_REQUEST,
                "Missing X-Tenant-ID");
        }
        return tenantService
            .resolve(tid);
    }
}

// Usage:
@GetMapping("/data")
public Data get(
        @TenantContext Tenant tenant) {
    return dataService
        .forTenant(tenant);
}
```

_What separates good from great:_ Error handling in the resolver and mentioning testability.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- DispatcherServlet - the pipeline that invokes handler methods
- IoC Container and DI - controllers are Spring beans

**Builds on this (learn these next):**

- Exception Handling - what happens when handler methods throw
- Validation - `@Valid` on `@RequestBody` triggers bean validation

**Alternatives / Comparisons:**

- RouterFunction (Spring WebFlux) - functional alternative
- JAX-RS (@Path, @GET) - Jakarta EE equivalent annotations

---

---

# Exception Handling

**TL;DR** - Spring MVC provides a layered exception handling strategy: `@ExceptionHandler` for controller-local errors, `@ControllerAdvice` for global error handling, and `ProblemDetail` (RFC 7807) for standardized error responses - turning unstructured stack traces into consistent, client-friendly error payloads.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every controller method wraps business logic in try-catch blocks. Error responses have inconsistent formats: some return `{"error": "..."}`, others return `{"message": "..."}`, and some return raw stack traces. Clients cannot reliably parse errors.

**THE BREAKING POINT:**
The mobile team reports they cannot display error messages because every endpoint returns a different error format. Some return 200 with an error body. Others return 500 with a stack trace.

**THE INVENTION MOMENT:**
"This is exactly why @ControllerAdvice was created."

**EVOLUTION:**
Try-catch in every Servlet -> `HandlerExceptionResolver` (Spring 3.0) -> `@ExceptionHandler` on controllers (Spring 3.0) -> `@ControllerAdvice` global handler (Spring 3.2) -> `ProblemDetail` RFC 7807 (Spring 6 / Boot 3).

---

### 📘 Textbook Definition

Spring MVC exception handling uses a chain of `HandlerExceptionResolver` implementations to convert thrown exceptions into HTTP responses. `@ExceptionHandler` methods on a controller handle exceptions from that controller. `@ControllerAdvice` (or `@RestControllerAdvice`) centralizes exception handling across all controllers. Spring 6 introduced `ProblemDetail` support for RFC 7807 standard error responses with `type`, `title`, `status`, `detail`, and `instance` fields.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Throw exceptions in your controller; `@ControllerAdvice` catches them and returns consistent, structured error responses.

**One analogy:**

> A building's fire alarm system. Each room (controller) does not need its own fire department. A central alarm system (@ControllerAdvice) monitors all rooms, categorizes the fire (exception type), and dispatches the right response (error payload). Specific rooms can have their own sprinklers (@ExceptionHandler) for known issues.

**One insight:**
The most important design decision is the error response format. Use RFC 7807 ProblemDetail - it is a standard that clients can parse generically, and Spring 6+ supports it natively.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Exception handling is a chain. Controller-level `@ExceptionHandler` is checked first, then `@ControllerAdvice`, then default resolvers.
2. `@ControllerAdvice` can be scoped to specific packages or annotations, not just global.
3. The error response format is your API contract. It should be consistent across all endpoints.

**DERIVED DESIGN:**
From invariant 1: specific handlers override general ones. From invariant 2: you can have separate advice for REST APIs vs web pages. From invariant 3: RFC 7807 ProblemDetail provides a standard format.

**THE TRADE-OFFS:**

**Gain:** Clean controllers (no try-catch), consistent error format, centralized error logging.

**Cost:** Exception flow can be hard to trace (where does this exception get handled?).

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Errors happen. Clients need structured error responses.

**Accidental:** The HandlerExceptionResolver chain has 4+ implementations with overlapping responsibilities.

---

### 🧠 Mental Model / Analogy

> Exception handling is like a hospital triage system. Minor injuries (@ExceptionHandler at controller level) are treated locally. Serious cases are escalated to the emergency department (@ControllerAdvice). Every patient gets a standardized medical report (ProblemDetail) regardless of where they were treated.

- "Minor injury" -> Known business exception handled locally
- "Emergency department" -> Global @ControllerAdvice
- "Standardized medical report" -> RFC 7807 ProblemDetail
- "Unknown condition" -> Default exception resolver (500 Internal Server Error)

Where this analogy breaks down: In a hospital, escalation is a process; in Spring, the resolver chain checks handlers in order.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
When something goes wrong in your web app, Spring catches the error and sends a helpful message to the client instead of a raw error. You configure this once for all endpoints.

**Level 2 - How to use it (junior developer):**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(
        ResourceNotFoundException.class)
    @ResponseStatus(NOT_FOUND)
    public ProblemDetail handleNotFound(
            ResourceNotFoundException ex) {
        ProblemDetail pd =
            ProblemDetail.forStatus(404);
        pd.setTitle("Resource Not Found");
        pd.setDetail(ex.getMessage());
        return pd;
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(
        INTERNAL_SERVER_ERROR)
    public ProblemDetail handleAll(
            Exception ex) {
        ProblemDetail pd =
            ProblemDetail.forStatus(500);
        pd.setTitle("Internal Error");
        pd.setDetail(
            "An unexpected error occurred");
        // Never expose stack trace
        log.error("Unhandled", ex);
        return pd;
    }
}
```

**Level 3 - How it works (mid-level engineer):**

Exception resolver chain (order):

```
  Handler throws exception
       |
  1. ExceptionHandlerExceptionResolver
     (checks @ExceptionHandler methods)
     a. Controller-local handlers first
     b. @ControllerAdvice handlers second
       |
  2. ResponseStatusExceptionResolver
     (handles @ResponseStatus on
      exception class)
       |
  3. DefaultHandlerExceptionResolver
     (Spring MVC standard exceptions
      -> 4xx/5xx status codes)
       |
  4. If none handle: Servlet container
     error page (ugly default)
```

RFC 7807 ProblemDetail response:

```json
{
  "type": "https://api.example.com/\
errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with ID 42 not found",
  "instance": "/api/users/42"
}
```

Enable globally:

```yaml
spring:
  mvc:
    problemdetails:
      enabled: true
```

**Level 4 - Mastery (senior/staff+ engineer):**

Scoped controller advice:

```java
// Only handles REST API controllers
@RestControllerAdvice(
    basePackages = "com.app.api")
public class ApiExceptionHandler {
    // Returns ProblemDetail JSON
}

// Only handles web page controllers
@ControllerAdvice(
    basePackages = "com.app.web")
public class WebExceptionHandler {
    // Returns error view (HTML)
}
```

Custom exception hierarchy:

```java
public abstract class BusinessException
        extends RuntimeException {
    abstract int getStatusCode();
    abstract String getErrorCode();
}

public class InsufficientBalanceException
        extends BusinessException {
    int getStatusCode() { return 422; }
    String getErrorCode() {
        return "INSUFFICIENT_BALANCE";
    }
}

@RestControllerAdvice
public class Handler {
    @ExceptionHandler(
        BusinessException.class)
    ProblemDetail handle(
            BusinessException ex) {
        ProblemDetail pd =
            ProblemDetail.forStatus(
                ex.getStatusCode());
        pd.setTitle(ex.getErrorCode());
        pd.setDetail(ex.getMessage());
        pd.setProperty("errorCode",
            ex.getErrorCode());
        return pd;
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@ControllerAdvice` to handle exceptions globally."

**A Staff says:** "I design an exception hierarchy (BusinessException, InfrastructureException) mapped to HTTP status codes, with RFC 7807 ProblemDetail for all error responses, custom error codes for client-side branching, and correlation IDs for tracing errors to logs. I separate API advice from web page advice using scoping."

**The difference:** Staff engineers design the error contract and exception architecture.

**Level 5 - Distinguished (expert thinking):**
Exception handling is part of API contract design. RFC 7807 ProblemDetail is becoming the standard (adopted by Stripe, GitHub, Microsoft Graph). At scale, error responses need: machine-readable error codes (for client branching), correlation IDs (for log tracing), rate limiting metadata (Retry-After header), and i18n-ready detail messages. The `type` URI in ProblemDetail should link to documentation explaining the error and how to fix it.

---

### ⚙️ How It Works

```
  Controller method throws exception
       |
  DispatcherServlet catches it
       |
  Iterates HandlerExceptionResolvers:
       |
  ExceptionHandlerExceptionResolver:
    Check controller's @ExceptionHandler
    Check @ControllerAdvice handlers
    Match by exception type hierarchy
       |
  Match found? -> invoke handler method
  -> return response
       |
  No match? -> next resolver
       |
  DefaultHandlerExceptionResolver:
    Maps Spring exceptions to status
    (MethodArgumentNotValid -> 400)
       |
  No match? -> servlet error page
```

`@ExceptionHandler` methods are matched by exception type. If you have handlers for both `ResourceNotFoundException` and `Exception`, the more specific one wins for `ResourceNotFoundException`. The generic `Exception` handler catches everything else.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Client: GET /users/42
       |
  Controller: throw
  ResourceNotFoundException
       |
  @ControllerAdvice catches <- HERE
       |
  ProblemDetail response:
  404 + JSON error body
       |
  Client: parses standard error
```

**FAILURE PATH:**
No handler matches the exception -> `DefaultHandlerExceptionResolver` maps to 500 -> ugly default error page. Fix: always have a catch-all `@ExceptionHandler(Exception.class)`.

**WHAT CHANGES AT SCALE:**
At 5 endpoints: simple handler is fine. At 500: exception hierarchy + error code registry + correlation IDs + documentation links in error responses. Error monitoring (Sentry, Datadog) integration in the global handler.

---

### 💻 Code Example

**Example 1 - BAD try-catch everywhere vs GOOD @ControllerAdvice:**

```java
// BAD - try-catch in every method
@GetMapping("/{id}")
public ResponseEntity<?> get(
        @PathVariable Long id) {
    try {
        return ResponseEntity.ok(
            service.findById(id));
    } catch (NotFoundException e) {
        return ResponseEntity
            .status(404)
            .body(Map.of(
                "error", e.getMessage()));
    } catch (Exception e) {
        return ResponseEntity
            .status(500)
            .body(Map.of("error",
                "Something went wrong"));
    }
}

// GOOD - clean controller + advice
@GetMapping("/{id}")
public User get(@PathVariable Long id) {
    return service.findById(id);
    // throws NotFoundException
    // -> handled by @ControllerAdvice
}
```

**Example 2 - Complete ProblemDetail handler:**

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(
        BusinessException.class)
    ProblemDetail handleBusiness(
            BusinessException ex,
            HttpServletRequest req) {
        ProblemDetail pd =
            ProblemDetail.forStatus(
                ex.getStatusCode());
        pd.setTitle(ex.getErrorCode());
        pd.setDetail(ex.getMessage());
        pd.setInstance(
            URI.create(
                req.getRequestURI()));
        pd.setProperty("traceId",
            MDC.get("traceId"));
        return pd;
    }

    @ExceptionHandler(
        MethodArgumentNotValidException
        .class)
    ProblemDetail handleValidation(
            MethodArgumentNotValidException
            ex) {
        ProblemDetail pd =
            ProblemDetail.forStatus(400);
        pd.setTitle("Validation Failed");
        List<String> errors = ex
            .getBindingResult()
            .getFieldErrors()
            .stream()
            .map(e -> e.getField()
                + ": "
                + e.getDefaultMessage())
            .toList();
        pd.setProperty("errors", errors);
        return pd;
    }
}
```

**How to test / verify correctness:**

```java
@WebMvcTest
class ExceptionHandlerTest {
    @Autowired MockMvc mvc;

    @Test
    void returns404ForNotFound()
            throws Exception {
        mvc.perform(get("/users/999"))
            .andExpect(status()
                .isNotFound())
            .andExpect(jsonPath("$.title")
                .value(
                "Resource Not Found"));
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Layered exception-to-HTTP-response mapping with consistent error format.

**PROBLEM IT SOLVES:** Eliminates try-catch in controllers and ensures consistent error responses.

**KEY INSIGHT:** RFC 7807 ProblemDetail is the standard. Design error codes for client-side branching.

**USE WHEN:** Every Spring MVC application needs a global exception handler.

**AVOID WHEN:** Never avoid - unhandled exceptions expose stack traces.

**ANTI-PATTERN:** Try-catch in every controller method. Returning 200 with error body.

**TRADE-OFF:** Centralized handling vs. harder-to-trace exception flow.

**ONE-LINER:** "Throw freely in controllers; @ControllerAdvice catches and formats."

**KEY NUMBERS:** 4 resolver chain steps. Controller-local beats global. Specific type beats generic.

**TRIGGER PHRASE:** "RFC 7807 ProblemDetail for all errors."

**OPENING SENTENCE:** "Spring MVC exception handling chains @ExceptionHandler (local) through @ControllerAdvice (global) through DefaultHandlerExceptionResolver, converting exceptions to structured RFC 7807 ProblemDetail responses with consistent error codes, status mapping, and correlation IDs."

**If you remember only 3 things:**

1. @RestControllerAdvice centralizes all error handling
2. RFC 7807 ProblemDetail = standard error format (Spring 6+)
3. Always have a catch-all Exception handler (prevents stack trace leaks)

**Interview one-liner:**
"I use @RestControllerAdvice with RFC 7807 ProblemDetail for all error responses. Exception hierarchy maps to HTTP status codes. Each error has a machine-readable code for client branching and a correlation ID for log tracing. Controller methods stay clean - just throw."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe the exception resolver chain and which handler takes precedence
2. **DEBUG:** Given "stack trace in API response," add a catch-all handler and secure error details
3. **DECIDE:** Choose between `@ResponseStatus` on exception class vs `@ExceptionHandler` in advice
4. **BUILD:** Design an exception hierarchy with error codes, correlation IDs, and ProblemDetail responses
5. **EXTEND:** Integrate error handling with monitoring (Sentry) and tracing (OpenTelemetry)

---

### 💡 The Surprising Truth

Spring Boot's default error handling returns a `WhitelabelErrorPage` (HTML) or a JSON error body depending on the Accept header. But this default handler runs OUTSIDE the DispatcherServlet pipeline - it is a separate `/error` endpoint. This means `@ControllerAdvice` handlers are NOT invoked for errors that occur in Servlet filters (before DispatcherServlet) or for 404s when `throwExceptionIfNoHandlerFound` is false. To handle truly global errors (including filter exceptions), you need a custom `ErrorController` implementation.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                    | Reality                                                                |
| --- | ------------------------------------------------ | ---------------------------------------------------------------------- |
| 1   | "@ControllerAdvice catches everything"           | Only exceptions from controllers. Filter exceptions bypass it.         |
| 2   | "Returning 200 with error body is fine"          | It breaks HTTP semantics. Use proper status codes.                     |
| 3   | "Stack traces in error responses help debugging" | They expose internals. Log server-side, return safe messages.          |
| 4   | "One global handler is enough"                   | Scope advice by package for different response formats (JSON vs HTML). |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Stack trace leaked to client**

**Symptom:** API returns 500 with full Java stack trace.

**Root Cause:** No catch-all `@ExceptionHandler(Exception.class)` in `@ControllerAdvice`.

**Diagnostic:** Send a request that causes an exception and check the response body.

**Fix:**

BAD: Setting `server.error.include-stacktrace=never` (only hides in default error page).

GOOD: Add catch-all `@ExceptionHandler(Exception.class)` that returns ProblemDetail with generic message.

**Prevention:** Security test: assert no response contains Java package names.

**Failure Mode 2: Filter exception not handled by advice**

**Symptom:** Spring Security filter throws, but `@ControllerAdvice` handler is not called.

**Root Cause:** Filters run before DispatcherServlet. The advice chain is inside DispatcherServlet.

**Diagnostic:** Check if the exception occurs in a filter (look at stack trace for `FilterChain`).

**Fix:**

BAD: Adding try-catch in the filter.

GOOD: Implement a custom `AuthenticationEntryPoint` (for security) or custom `ErrorController` for general filter errors.

**Prevention:** Understand the Servlet filter vs DispatcherServlet boundary.

**Failure Mode 3: Wrong handler invoked for exception**

**Symptom:** A specific `NotFoundException` is caught by the generic `Exception` handler instead of the `NotFoundException` handler.

**Root Cause:** `@ControllerAdvice` ordering or the specific handler is in a different advice class with lower priority.

**Diagnostic:** Add logging to each handler to see which one fires.

**Fix:**

BAD: Removing the generic handler.

GOOD: Use `@Order` on `@ControllerAdvice` classes to control priority. More specific advice should have lower order (higher priority).

**Prevention:** Keep all handlers in one `@ControllerAdvice` class when possible.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: How does Spring MVC handle exceptions?**

_Why they ask:_ Core MVC knowledge.
_Likely follow-up:_ "What is @ControllerAdvice?"

**Answer:**
Three layers of exception handling:

1. **@ExceptionHandler on controller** - catches exceptions from that specific controller only
2. **@ControllerAdvice** - global handler for all controllers. Use `@RestControllerAdvice` for REST APIs
3. **DefaultHandlerExceptionResolver** - maps standard Spring exceptions to HTTP status codes (e.g., `MethodArgumentNotValid` -> 400)

Example:

```java
@RestControllerAdvice
class Handler {
    @ExceptionHandler(
        NotFoundException.class)
    @ResponseStatus(NOT_FOUND)
    ProblemDetail handle(
            NotFoundException ex) {
        return ProblemDetail
            .forStatusAndDetail(
                HttpStatus.NOT_FOUND,
                ex.getMessage());
    }
}
```

_What separates good from great:_ Mentioning the chain order and ProblemDetail (RFC 7807).

---

**Q2 [MID]: Design a consistent error response format for a REST API.**

_Why they ask:_ Tests API design skills.
_Likely follow-up:_ "How do you handle validation errors?"

**Answer:**
Use RFC 7807 ProblemDetail (Spring 6+ native support):

```json
{
  "type": "/errors/insufficient-funds",
  "title": "Insufficient Balance",
  "status": 422,
  "detail": "Account has $50, needs $100",
  "instance": "/api/transfers/789",
  "traceId": "abc-123-def",
  "errorCode": "INSUFFICIENT_BALANCE"
}
```

Design principles:

- `status`: HTTP status code (machine-readable)
- `errorCode`: application-specific code for client branching
- `detail`: human-readable message (i18n-ready)
- `traceId`: correlation ID for log tracing
- `type`: URI linking to error documentation

For validation errors, add `errors` array:

```json
{
  "status": 400,
  "title": "Validation Failed",
  "errors": ["name: must not be blank", "email: must be valid"]
}
```

_What separates good from great:_ Error codes for client branching, traceId for observability, and documentation links.

---

**Q3 [SENIOR]: A @ControllerAdvice is not catching a specific exception. Diagnose.**

_Why they ask:_ Tests debugging skills.
_Likely follow-up:_ "How do you handle filter exceptions?"

**Answer:**
Systematic checklist:

1. **Is the exception from a controller or a filter?**
   - Filters run before DispatcherServlet - advice does not catch them
   - Check stack trace for `FilterChain`

2. **Is the advice scoped?**

   ```java
   // This only catches from "com.app.api"
   @RestControllerAdvice(
       basePackages = "com.app.api")
   ```

3. **Is another advice handling it first?**
   - Multiple advice classes: `@Order` controls priority
   - A generic `Exception` handler in another advice may catch first

4. **Is the handler method signature correct?**
   ```java
   // Wrong: parameter type does not
   // match annotation type
   @ExceptionHandler(NotFoundException.class)
   void handle(RuntimeException ex) { }
   ```

Fix: add logging to each handler, check advice scope, verify ordering.

_What separates good from great:_ The filter vs controller distinction and checking advice scoping.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- DispatcherServlet - exception handling is part of the DispatcherServlet pipeline
- Request Mapping - handler methods throw the exceptions that get handled

**Builds on this (learn these next):**

- Validation - validation errors are a common exception type
- Spring Security - security exceptions need custom entry points

**Alternatives / Comparisons:**

- JAX-RS ExceptionMapper - Jakarta EE equivalent of @ControllerAdvice
- Express.js error middleware - Node.js equivalent pattern

---

---

# Content Negotiation

**TL;DR** - Content negotiation lets one endpoint serve multiple response formats (JSON, XML, PDF) by inspecting the client's `Accept` header, URL suffix, or query parameter - decoupling the response format from the controller logic.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You create separate endpoints for each format: `/users/42.json`, `/users/42.xml`, `/users/42.pdf`. Or you accept a `format` parameter and use `if/else` to switch serialization. Every controller duplicates this logic.

**THE BREAKING POINT:**
The same data needs to be served as JSON (web app), XML (legacy SOAP client), and CSV (reporting tool). Three endpoints, three serializers, three sets of tests - for the same data.

**THE INVENTION MOMENT:**
"This is exactly why Content Negotiation was created."

**EVOLUTION:**
One endpoint per format -> manual Accept header parsing -> Spring ContentNegotiatingViewResolver (Spring 3.0) -> HttpMessageConverter selection by Accept header -> configurable strategies (path extension, query param, header).

---

### 📘 Textbook Definition

Content negotiation in Spring MVC is the process of selecting the appropriate response format based on the client's request. The primary mechanism is the HTTP `Accept` header (e.g., `Accept: application/json`). Spring matches the Accept value against `HttpMessageConverter` instances registered in the handler adapter. The first converter that supports both the return type and the requested media type is used. Additional strategies include URL path extension (deprecated), query parameter (`?format=json`), and fixed `produces` attribute on the mapping.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
One endpoint, multiple formats - Spring picks the right serializer based on what the client asks for.

**One analogy:**

> A multilingual customer service agent. The customer says "I speak French" (Accept: application/xml). The agent responds in French. Another says "I speak English" (Accept: application/json). Same agent, same information, different language. The agent (controller) does not change; only the translation (converter) does.

**One insight:**
The controller method returns a Java object. Content negotiation decides how to serialize it. This means adding XML support is just adding a Jackson XML dependency - no controller code changes.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. The controller returns a Java object, not bytes. Serialization is the framework's responsibility.
2. `HttpMessageConverter` selection is based on: (a) return type (can the converter handle it?), (b) media type (does the Accept header match?).
3. If no converter matches the Accept header, Spring returns 406 Not Acceptable.

**DERIVED DESIGN:**
From invariant 1: controllers are format-agnostic. From invariant 2: adding a new format means adding a converter (JAR on classpath). From invariant 3: clients must request a supported format.

**THE TRADE-OFFS:**

**Gain:** One endpoint serves multiple formats. Clean separation of data and representation.

**Cost:** Debugging "wrong format returned" requires understanding converter selection order.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Different clients need different formats. Content negotiation is an HTTP standard.

**Accidental:** Multiple negotiation strategies (header, param, suffix) and their priority configuration.

---

### 🧠 Mental Model / Analogy

> Content negotiation is like a vending machine that dispenses the same product in different packaging. Press the "can" button (Accept: application/json), get a can. Press the "bottle" button (Accept: application/xml), get a bottle. Same product (Java object), different packaging (serialization format). The machine (Spring) picks the packaging based on your button press.

- "Product" -> Java return object
- "Can/bottle" -> JSON/XML serialization
- "Button press" -> Accept header value
- "Vending machine" -> HttpMessageConverter chain

Where this analogy breaks down: Vending machines have physical limits on packaging types; adding a new format to Spring is just adding a JAR.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
When you ask for data from a web server, you can say "give me JSON" or "give me XML." The server sends the same data in whichever format you asked for.

**Level 2 - How to use it (junior developer):**

```java
// JSON works out of the box (Jackson)
@GetMapping("/users/{id}")
public User get(@PathVariable Long id) {
    return service.findById(id);
}
```

```bash
# JSON (default)
curl -H "Accept: application/json" \
  localhost:8080/users/42
# Returns: {"name":"John","age":30}

# XML (add jackson-dataformat-xml)
curl -H "Accept: application/xml" \
  localhost:8080/users/42
# Returns: <User><name>John</name>...
```

Add XML support:

```xml
<dependency>
    <artifactId>
        jackson-dataformat-xml
    </artifactId>
</dependency>
```

**Level 3 - How it works (mid-level engineer):**

Converter selection algorithm:

```
  Return type: User object
  Accept header: application/json
       |
  Iterate HttpMessageConverters:
    1. MappingJackson2HttpMC
       supports User? Yes
       produces application/json? Yes
       -> SELECTED
    2. MappingJackson2XmlHttpMC
       (skipped, JSON matched first)
       |
  Selected converter serializes
  User -> JSON bytes
       |
  Response: Content-Type:
  application/json
```

Key converters (in typical order):

| Converter                | Media Type                        |
| ------------------------ | --------------------------------- |
| MappingJackson2HttpMC    | application/json                  |
| MappingJackson2XmlHttpMC | application/xml                   |
| StringHttpMC             | text/plain                        |
| ByteArrayHttpMC          | application/octet-stream          |
| FormHttpMC               | application/x-www-form-urlencoded |

**Level 4 - Mastery (senior/staff+ engineer):**

Configuring negotiation strategies:

```java
@Configuration
public class WebConfig
        implements WebMvcConfigurer {

    @Override
    public void configureContentNegotiation(
            ContentNegotiationConfigurer c) {
        c.favorParameter(true)
            .parameterName("format")
            .defaultContentType(
                MediaType.APPLICATION_JSON)
            .mediaType("json",
                MediaType.APPLICATION_JSON)
            .mediaType("xml",
                MediaType.APPLICATION_XML);
    }
}
```

```bash
# Now works with query param too:
curl localhost:8080/users/42?format=xml
```

Explicit `produces` for specific endpoints:

```java
@GetMapping(value = "/report",
    produces = "application/pdf")
public byte[] getReport() {
    return pdfGenerator.generate();
}
// Only responds to Accept:
// application/pdf
// Returns 406 for other Accept values
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Spring picks JSON or XML based on the Accept header."

**A Staff says:** "I configure content negotiation with a default media type, explicit converter ordering (JSON first for performance), and `produces` constraints on endpoints that serve specific formats. For API versioning via media types (`application/vnd.company.v2+json`), I register custom media types mapped to the JSON converter."

**The difference:** Staff engineers design the negotiation strategy, not just rely on defaults.

**Level 5 - Distinguished (expert thinking):**
Content negotiation is defined in HTTP/1.1 (RFC 7231 Section 5.3). Beyond `Accept`, HTTP also supports `Accept-Language` (i18n), `Accept-Encoding` (compression), and `Accept-Charset`. In practice, `Accept` is the primary concern. At scale, content negotiation interacts with caching: a `Vary: Accept` header tells CDNs to cache different representations separately.

---

### ⚙️ How It Works

```
  Client sends request:
  Accept: application/json
       |
  DispatcherServlet invokes handler
       |
  Handler returns Java object
       |
  ContentNegotiationManager
  resolves requested media types
  from Accept header
       |
  AbstractMessageConverterMethodProc:
  iterate converters in order
       |
  Find first converter that:
    1. canWrite(returnType)
    2. supports requested mediaType
       |
  Converter.write(object, mediaType,
    outputMessage)
       |
  Response with Content-Type header
```

If no converter matches, `HttpMediaTypeNotAcceptableException` is thrown and the client gets 406 Not Acceptable.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Client: Accept: application/xml
       |
  Handler returns User object
       |
  ContentNegotiation: <- HERE
  requested = application/xml
       |
  Jackson XML converter selected
       |
  User serialized to XML
       |
  Response: Content-Type:
  application/xml
```

**FAILURE PATH:**
Client sends `Accept: application/pdf` but no PDF converter registered -> 406 Not Acceptable. Or: converter registered but cannot serialize the return type -> 500.

**WHAT CHANGES AT SCALE:**
Add `Vary: Accept` response header for CDN-correct caching. Consider API versioning via custom media types. Monitor which formats clients actually use - you may find nobody uses XML and can remove it.

---

### 💻 Code Example

**Example 1 - BAD format parameter vs GOOD Accept header:**

```java
// BAD - manual format switching
@GetMapping("/users/{id}")
public ResponseEntity<?> get(
        @PathVariable Long id,
        @RequestParam String format) {
    User user = service.findById(id);
    if ("xml".equals(format)) {
        return ResponseEntity.ok()
            .contentType(APPLICATION_XML)
            .body(xmlMapper.writeValueAsString(
                user));
    }
    return ResponseEntity.ok()
        .contentType(APPLICATION_JSON)
        .body(jsonMapper.writeValueAsString(
            user));
}

// GOOD - let Spring handle it
@GetMapping("/users/{id}")
public User get(@PathVariable Long id) {
    return service.findById(id);
    // Accept: application/json -> JSON
    // Accept: application/xml -> XML
    // No manual serialization
}
```

**How to test / verify correctness:**

```java
@WebMvcTest
class ContentNegotiationTest {
    @Autowired MockMvc mvc;

    @Test
    void returnsXmlWhenRequested()
            throws Exception {
        mvc.perform(get("/users/1")
                .accept(APPLICATION_XML))
            .andExpect(status().isOk())
            .andExpect(content()
                .contentType(
                    APPLICATION_XML));
    }

    @Test
    void returns406ForUnsupported()
            throws Exception {
        mvc.perform(get("/users/1")
                .accept(
                    MediaType
                    .APPLICATION_PDF))
            .andExpect(status()
                .isNotAcceptable());
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Automatic response format selection based on client's Accept header.

**PROBLEM IT SOLVES:** One endpoint serves JSON, XML, or any format without controller code changes.

**KEY INSIGHT:** Adding a new format = adding a converter JAR. No controller changes.

**USE WHEN:** Multi-format APIs (JSON + XML). API versioning via custom media types.

**AVOID WHEN:** Single-format API (JSON only) - just use the default.

**ANTI-PATTERN:** Manual format switching with if/else in controllers.

**TRADE-OFF:** Format flexibility vs. converter ordering complexity.

**ONE-LINER:** "One controller, many formats - Accept header picks the converter."

**KEY NUMBERS:** 5+ built-in converters. 406 for unsupported format. `Vary: Accept` for caching.

**TRIGGER PHRASE:** "Accept header drives format selection."

**OPENING SENTENCE:** "Content negotiation selects the HttpMessageConverter based on the client's Accept header - returning JSON, XML, or any supported format from the same controller method, with 406 Not Acceptable for unsupported formats."

**If you remember only 3 things:**

1. Accept header -> HttpMessageConverter selection -> serialization
2. Add format support by adding a converter JAR (no code change)
3. 406 Not Acceptable when no converter matches

**Interview one-liner:**
"Content negotiation matches the Accept header against registered HttpMessageConverters. The first converter that supports both the return type and the media type wins. Adding XML support is just adding jackson-dataformat-xml to the classpath. 406 for unsupported formats."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe how `Accept` header maps to `HttpMessageConverter` selection
2. **DEBUG:** Given "wrong format returned," check converter order and Accept header value
3. **DECIDE:** Choose between Accept header, query param, and `produces` for different scenarios
4. **BUILD:** Add a new format (CSV, PDF) by implementing a custom `HttpMessageConverter`
5. **EXTEND:** Use content negotiation for API versioning with custom media types

---

### 💡 The Surprising Truth

If the client sends no `Accept` header (or `Accept: */*`), Spring returns the format produced by the first converter that can handle the return type - which is typically JSON if Jackson is on the classpath. This means the "default" format is determined by classpath order, not configuration. If you add Jackson XML before Jackson JSON (rare but possible via dependency order), XML could become the default. Always set an explicit `defaultContentType` in the `ContentNegotiationConfigurer` to avoid surprises.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                           | Reality                                                                                                   |
| --- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | "You need separate endpoints for JSON and XML"          | One endpoint, different Accept headers.                                                                   |
| 2   | "Content negotiation requires configuration"            | JSON works out of the box with starter-web. XML needs one JAR.                                            |
| 3   | "URL suffix negotiation is recommended"                 | Deprecated since Spring 5.3. Use Accept header or query param.                                            |
| 4   | "produces attribute is the same as content negotiation" | `produces` restricts what an endpoint can return. Content negotiation selects from the available options. |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: 406 Not Acceptable**

**Symptom:** Client gets 406 for a valid endpoint.

**Root Cause:** No `HttpMessageConverter` registered for the requested media type.

**Diagnostic:**

```bash
curl -v -H "Accept: application/xml" \
  localhost:8080/users/1
# 406 = no XML converter
```

**Fix:**

BAD: Catching the 406 and returning JSON anyway.

GOOD: Add the appropriate converter (e.g., jackson-dataformat-xml for XML).

**Prevention:** Document supported media types in API spec.

**Failure Mode 2: XML returned instead of JSON**

**Symptom:** Client expects JSON but gets XML.

**Root Cause:** Jackson XML converter is registered and matches before JSON due to Accept header order.

**Diagnostic:** Check Accept header: `Accept: application/xml, application/json` prefers XML.

**Fix:**

BAD: Removing XML support entirely.

GOOD: Configure default content type to JSON. Or client should send `Accept: application/json` first.

**Prevention:** Set `defaultContentType(MediaType.APPLICATION_JSON)`.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: How does Spring decide between returning JSON vs XML?**

_Why they ask:_ Tests HTTP and Spring MVC understanding.
_Likely follow-up:_ "What if the client sends no Accept header?"

**Answer:**
Spring reads the client's `Accept` header and matches it against registered `HttpMessageConverter` instances.

Process:

1. Client sends `Accept: application/xml`
2. Spring iterates converters in order
3. First converter that supports the return type AND the media type wins
4. That converter serializes the Java object

JSON works by default (Jackson in starter-web). XML needs `jackson-dataformat-xml` on classpath.

No Accept header = `*/*` = first matching converter (usually JSON).

_What separates good from great:_ Explaining the converter selection algorithm and default behavior.

---

**Q2 [MID]: How would you add CSV export support to an existing REST endpoint?**

_Why they ask:_ Tests extensibility understanding.
_Likely follow-up:_ "How does the client request CSV?"

**Answer:**
Create a custom `HttpMessageConverter`:

```java
public class CsvHttpMessageConverter
        extends AbstractHttpMessageConverter
        <List<?>> {
    public CsvHttpMessageConverter() {
        super(new MediaType(
            "text", "csv"));
    }

    protected boolean supports(
            Class<?> clazz) {
        return List.class
            .isAssignableFrom(clazz);
    }

    protected void writeInternal(
            List<?> list,
            HttpOutputMessage output)
            throws IOException {
        // Write CSV using Apache Commons
        // CSV or OpenCSV
        var writer = new OutputStreamWriter(
            output.getBody());
        csvWriter.write(list, writer);
    }
}
```

Register and use:

```bash
curl -H "Accept: text/csv" \
  localhost:8080/users
# Returns CSV format
```

The controller method is unchanged - same `List<User>` return.

_What separates good from great:_ Implementing the converter and showing the controller needs zero changes.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- DispatcherServlet - content negotiation happens in the response phase
- Request Mapping - `produces` attribute constrains content negotiation

**Builds on this (learn these next):**

- HttpMessageConverter - the pluggable serializers that content negotiation selects
- REST API Design - content negotiation is part of HTTP API contract

**Alternatives / Comparisons:**

- GraphQL - client specifies exact fields instead of format negotiation
- gRPC / Protobuf - binary format, no content negotiation needed

---

---

# Validation

**TL;DR** - Spring integrates Jakarta Bean Validation (Hibernate Validator) to validate request data declaratively with annotations like `@NotBlank`, `@Size`, `@Email` on DTOs, triggered by `@Valid` or `@Validated` on controller method parameters - rejecting invalid data at the API boundary before it reaches business logic.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every service method starts with 10 lines of `if (name == null || name.isBlank()) throw new ValidationException(...)`. Validation rules are duplicated between controller, service, and client. Inconsistent error messages. Missed validations lead to corrupt data.

**THE BREAKING POINT:**
A user submits a form with an empty email field. The controller does not check. The service does not check. The database throws `NOT NULL constraint violation`. The client sees a 500 error with a stack trace.

**THE INVENTION MOMENT:**
"This is exactly why Bean Validation was created."

**EVOLUTION:**
Manual if-checks -> custom Validator classes -> JSR 303 Bean Validation 1.0 (2009) -> JSR 349 BV 1.1 (method validation) -> JSR 380 BV 2.0 (Jakarta) -> Spring's `@Validated` (group support).

---

### 📘 Textbook Definition

Spring Validation integrates Jakarta Bean Validation (implemented by Hibernate Validator) into the MVC pipeline. Constraint annotations (`@NotNull`, `@Size`, `@Pattern`, `@Email`, etc.) are placed on DTO fields. Adding `@Valid` or `@Validated` to a `@RequestBody` parameter triggers validation before the handler method executes. Validation failures throw `MethodArgumentNotValidException` (for `@RequestBody`) or `ConstraintViolationException` (for path variables/params), which can be caught in `@ControllerAdvice` to return structured error responses.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Annotate DTO fields with constraints; add `@Valid` to the controller parameter; Spring rejects bad data automatically.

**One analogy:**

> Airport security screening. Every passenger (request) passes through a scanner (validation). The scanner checks for prohibited items (@NotNull, @Size). If anything fails, the passenger is rejected before boarding (entering business logic). The gate agent (controller) never sees invalid passengers.

**One insight:**
Validation should happen at the system boundary (controller), not deep in the service layer. By the time data reaches your business logic, it should already be validated and safe.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Validation constraints are declarative (annotations on fields). No procedural validation code in controllers.
2. `@Valid` triggers validation before the handler method executes. Invalid data never reaches your code.
3. Validation groups allow different constraints for different operations (create vs update).

**DERIVED DESIGN:**
From invariant 1: constraints are visible in the DTO class (self-documenting). From invariant 2: controllers are clean - no validation logic. From invariant 3: a field can be `@NotNull` for create but optional for update.

**THE TRADE-OFFS:**

**Gain:** Declarative, composable, framework-integrated validation. Self-documenting constraints.

**Cost:** Annotation clutter on DTOs. Complex cross-field validation requires custom validators.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Input validation is a security and data integrity requirement.

**Accidental:** Two trigger annotations (`@Valid` vs `@Validated`) with subtle differences.

---

### 🧠 Mental Model / Analogy

> Validation annotations are like quality control stickers on a manufacturing line. Each component (field) must pass its quality check (@NotBlank, @Size) before assembly (business logic). If any check fails, the component is rejected immediately - it never enters the final product.

- "Quality sticker" -> @NotBlank, @Size annotation
- "Manufacturing line" -> Request processing pipeline
- "Assembly" -> Business logic execution
- "Rejected component" -> 400 Bad Request

Where this analogy breaks down: Manufacturing rejects are physical waste; validation rejects are instant HTTP responses.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
You put rules on your data fields: "name cannot be empty," "age must be between 1 and 150." When someone sends bad data, the system automatically rejects it with a clear error message.

**Level 2 - How to use it (junior developer):**

```java
public class CreateUserRequest {
    @NotBlank(
        message = "Name is required")
    @Size(max = 100)
    private String name;

    @Email
    @NotBlank
    private String email;

    @Min(18) @Max(150)
    private int age;
    // getters/setters
}

@PostMapping("/users")
public User create(
        @Valid @RequestBody
        CreateUserRequest req) {
    // req is guaranteed valid here
    return service.create(req);
}
```

**Level 3 - How it works (mid-level engineer):**

`@Valid` vs `@Validated`:

| Feature       | @Valid            | @Validated  |
| ------------- | ----------------- | ----------- |
| Standard      | Jakarta (JSR 380) | Spring      |
| Groups        | No                | Yes         |
| Cascading     | Yes (nested)      | Yes         |
| Method params | Yes               | Yes         |
| Use case      | Simple validation | Group-based |

Validation error handling:

```java
@RestControllerAdvice
class Handler {
    @ExceptionHandler(
        MethodArgumentNotValidException
        .class)
    ProblemDetail handleValidation(
            MethodArgumentNotValidException
            ex) {
        ProblemDetail pd =
            ProblemDetail.forStatus(400);
        pd.setTitle("Validation Failed");
        Map<String, String> errors =
            new HashMap<>();
        ex.getBindingResult()
            .getFieldErrors()
            .forEach(e ->
                errors.put(e.getField(),
                e.getDefaultMessage()));
        pd.setProperty("errors", errors);
        return pd;
    }
}
```

Response:

```json
{
  "status": 400,
  "title": "Validation Failed",
  "errors": {
    "name": "Name is required",
    "email": "must be a valid email"
  }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

Validation groups:

```java
public interface OnCreate {}
public interface OnUpdate {}

public class UserRequest {
    @Null(groups = OnCreate.class)
    @NotNull(groups = OnUpdate.class)
    private Long id;

    @NotBlank(groups = {
        OnCreate.class,
        OnUpdate.class})
    private String name;
}

@PostMapping
public User create(
        @Validated(OnCreate.class)
        @RequestBody UserRequest req) {
    // id must be null for create
}

@PutMapping("/{id}")
public User update(
        @Validated(OnUpdate.class)
        @RequestBody UserRequest req) {
    // id must not be null for update
}
```

Custom constraint:

```java
@Target(FIELD)
@Retention(RUNTIME)
@Constraint(
    validatedBy = NoProfanityValidator
        .class)
public @interface NoProfanity {
    String message() default
        "Contains prohibited words";
    Class<?>[] groups() default {};
    Class<?>[] payload() default {};
}

public class NoProfanityValidator
        implements
        ConstraintValidator<NoProfanity,
        String> {
    public boolean isValid(String val,
            ConstraintValidatorContext c) {
        if (val == null) return true;
        return !profanityFilter
            .contains(val);
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add `@Valid` to the request body and put `@NotBlank` on fields."

**A Staff says:** "I design a validation strategy: constraints on DTOs at the API boundary (never on domain entities), validation groups for create vs update, custom constraints for domain rules, and a global `@ControllerAdvice` that returns structured field-level errors. I validate at the boundary so the service layer never receives invalid data."

**The difference:** Staff engineers design the validation architecture (where, what, how to report).

**Level 5 - Distinguished (expert thinking):**
Bean Validation is an example of the Specification pattern applied at the data level. The same concept exists in every framework: Zod/Yup (TypeScript), Pydantic (Python), Joi (Node.js). Cross-field validation (start date < end date) is the awkward case - it requires class-level constraints which are harder to compose. At scale, validation schemas should be generated from the same source as OpenAPI specs to keep client and server in sync.

---

### ⚙️ How It Works

```
  @Valid @RequestBody UserRequest req
       |
  HandlerAdapter resolves argument:
  Jackson deserializes JSON -> object
       |
  Validator.validate(object) called
  by RequestResponseBodyMethodProcessor
       |
  Hibernate Validator evaluates
  all constraint annotations
       |
  Violations found?
    Yes -> MethodArgumentNotValid
           Exception thrown
    No  -> object passed to handler
       |
  @ControllerAdvice catches exception
  -> 400 + structured error response
```

For `@PathVariable`/`@RequestParam` validation (with `@Validated` on the controller class):

```
  @Min(1) @PathVariable Long id
       |
  MethodValidationPostProcessor
  intercepts method call
       |
  Violation -> ConstraintViolation
  Exception -> 400/500
```

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Client: POST /users
  Body: {"name":"","email":"bad"}
       |
  Jackson deserializes to DTO
       |
  @Valid triggers validation <- HERE
       |
  Violations: name blank, email invalid
       |
  MethodArgumentNotValidException
       |
  @ControllerAdvice -> 400 response
  with field-level errors
       |
  Controller method NEVER executed
```

**FAILURE PATH:**
Missing `@Valid` annotation -> validation is not triggered -> invalid data reaches service -> corrupt data or runtime exception later. This is the #1 validation bug.

**WHAT CHANGES AT SCALE:**
At small scale: simple constraints. At large scale: shared constraint DTOs across services (via shared library), custom constraints for domain rules, validation error localization (i18n), and OpenAPI spec generated from validation annotations.

---

### 💻 Code Example

**Example 1 - BAD manual validation vs GOOD annotations:**

```java
// BAD - manual validation in controller
@PostMapping("/users")
public ResponseEntity<?> create(
        @RequestBody UserRequest req) {
    List<String> errors = new ArrayList<>();
    if (req.getName() == null
            || req.getName().isBlank()) {
        errors.add(
            "Name is required");
    }
    if (req.getEmail() == null
            || !req.getEmail()
            .contains("@")) {
        errors.add(
            "Invalid email");
    }
    if (!errors.isEmpty()) {
        return ResponseEntity
            .badRequest().body(errors);
    }
    return ResponseEntity.ok(
        service.create(req));
}

// GOOD - declarative validation
@PostMapping("/users")
public User create(
        @Valid @RequestBody
        UserRequest req) {
    return service.create(req);
}
// Validation handled by framework
// Errors handled by @ControllerAdvice
```

**Example 2 - Nested object validation:**

```java
public class OrderRequest {
    @NotBlank
    private String customerId;

    @Valid  // Cascading validation!
    @NotEmpty
    private List<@Valid LineItem> items;
}

public class LineItem {
    @NotBlank
    private String productId;
    @Min(1)
    private int quantity;
    @Positive
    private BigDecimal price;
}
```

**How to test / verify correctness:**

```java
@WebMvcTest
class ValidationTest {
    @Autowired MockMvc mvc;

    @Test
    void rejectsBlankName()
            throws Exception {
        String json =
            "{\"name\":\"\","
            + "\"email\":\"bad\"}";
        mvc.perform(post("/users")
                .contentType(
                    APPLICATION_JSON)
                .content(json))
            .andExpect(status()
                .isBadRequest())
            .andExpect(
                jsonPath("$.errors.name")
                .exists());
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Declarative constraint annotations on DTOs with automatic framework-triggered validation.

**PROBLEM IT SOLVES:** Eliminates manual if-check validation code and ensures consistent error responses.

**KEY INSIGHT:** Validate at the boundary (controller). Service layer should never receive invalid data.

**USE WHEN:** Every `@RequestBody` parameter and every user input.

**AVOID WHEN:** Internal service-to-service calls where data is already validated at entry.

**ANTI-PATTERN:** Manual if-checks in controllers. Missing `@Valid` annotation (validation silently skipped).

**TRADE-OFF:** Declarative clarity vs. annotation clutter on DTOs.

**ONE-LINER:** "Annotate fields, add @Valid, get automatic 400 responses for bad data."

**KEY NUMBERS:** 20+ built-in constraints. `@Valid` = Jakarta standard. `@Validated` = Spring (groups).

**TRIGGER PHRASE:** "Validate at the boundary."

**OPENING SENTENCE:** "Spring Validation integrates Jakarta Bean Validation via @Valid/@Validated on controller parameters, triggering constraint evaluation before handler execution - rejecting invalid data with MethodArgumentNotValidException caught by @ControllerAdvice for structured 400 responses."

**If you remember only 3 things:**

1. @Valid on @RequestBody triggers validation. Missing it = silent bypass.
2. @Validated (Spring) supports validation groups. @Valid (Jakarta) does not.
3. Handle MethodArgumentNotValidException in @ControllerAdvice for structured errors.

**Interview one-liner:**
"I put constraint annotations on DTOs and @Valid on the controller parameter. Validation runs before the handler method. MethodArgumentNotValidException is caught by @ControllerAdvice returning field-level errors as RFC 7807 ProblemDetail. I use validation groups for create-vs-update scenarios."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Describe how `@Valid` triggers validation and which exception is thrown
2. **DEBUG:** Given "validation not working," check for missing `@Valid` annotation or wrong exception handler
3. **DECIDE:** Choose between `@Valid` (simple) and `@Validated` (groups) based on requirements
4. **BUILD:** Create a custom constraint annotation with validator for domain-specific rules
5. **EXTEND:** Design a validation strategy with groups, cross-field validation, and i18n error messages

---

### 💡 The Surprising Truth

The most common validation bug is forgetting `@Valid`. Without it, Jakarta Bean Validation annotations are completely ignored - the DTO is deserialized but constraints are never checked. There is no warning, no error, nothing. The invalid data silently passes through to your business logic. This is why code reviews should always check: does every `@RequestBody` have `@Valid`? A second trap: `@Valid` on `@PathVariable`/`@RequestParam` does not work unless you also add `@Validated` on the controller class itself.

---

### ⚖️ Comparison Table

| Dimension        | @Valid                    | @Validated                |
| ---------------- | ------------------------- | ------------------------- |
| Source           | Jakarta (JSR 380)         | Spring Framework          |
| Groups           | Not supported             | Supported                 |
| On @RequestBody  | Yes                       | Yes                       |
| On @PathVariable | Needs @Validated on class | Needs @Validated on class |
| Cascading        | Yes                       | Yes                       |
| Use case         | Simple validation         | Create/update groups      |

**Rapid Decision Tree (30 seconds):**
IF same constraints for all operations -> `@Valid`
ELSE IF different constraints per operation -> `@Validated(Group.class)`
ALSO IF validating @PathVariable/@RequestParam -> add `@Validated` on controller class

---

### ⚠️ Common Misconceptions

| #   | Misconception                                      | Reality                                                                                            |
| --- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| 1   | "Constraints work without @Valid"                  | No. @Valid is required to trigger validation. Without it, constraints are ignored silently.        |
| 2   | "@Valid and @Validated are the same"               | @Validated supports groups. @Valid does not. @Validated on class enables method param validation.  |
| 3   | "Validation annotations go on entities"            | Put them on DTOs at the boundary. Entities should enforce invariants through constructors/methods. |
| 4   | "Custom validation requires a framework extension" | Just create an annotation + ConstraintValidator. Standard Bean Validation SPI.                     |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Validation silently not running**

**Symptom:** Invalid data passes through to service layer. No 400 error.

**Root Cause:** Missing `@Valid` on the `@RequestBody` parameter.

**Diagnostic:**

```java
// Check controller signature:
// WRONG:
public User create(
    @RequestBody UserRequest req)
// RIGHT:
public User create(
    @Valid @RequestBody UserRequest req)
```

**Fix:**

BAD: Adding manual validation in the service.

GOOD: Add `@Valid` to the controller parameter.

**Prevention:** Code review checklist: every `@RequestBody` has `@Valid`.

**Failure Mode 2: ConstraintViolationException instead of MethodArgumentNotValidException**

**Symptom:** Validation fails for `@PathVariable` but the exception is `ConstraintViolationException`, not `MethodArgumentNotValidException`. Your handler does not catch it.

**Root Cause:** `@PathVariable`/`@RequestParam` validation uses a different mechanism (method-level validation) which throws `ConstraintViolationException`.

**Diagnostic:** Check if the failing validation is on a `@RequestBody` field (MANVE) or method param (CVE).

**Fix:**

BAD: Ignoring the different exception type.

GOOD: Add a separate `@ExceptionHandler(ConstraintViolationException.class)` in your `@ControllerAdvice`.

**Prevention:** Handle both exception types in global advice.

**Failure Mode 3: Nested object not validated**

**Symptom:** Top-level fields are validated but nested object fields are not.

**Root Cause:** Missing `@Valid` on the nested field in the parent DTO.

**Diagnostic:**

```java
// WRONG - nested not validated:
public class Order {
    @Valid // <- missing this!
    private Address address;
}
// RIGHT:
public class Order {
    @Valid
    @NotNull
    private Address address;
}
```

**Fix:** Add `@Valid` to nested object fields for cascading validation.

**Prevention:** Always add `@Valid` on nested DTOs. Test nested validation explicitly.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: How do you validate request data in Spring MVC?**

_Why they ask:_ Basic web security knowledge.
_Likely follow-up:_ "What happens when validation fails?"

**Answer:**
Three steps:

1. Add constraint annotations to DTO fields:

```java
public class CreateUserRequest {
    @NotBlank private String name;
    @Email private String email;
    @Min(18) private int age;
}
```

2. Add `@Valid` to the controller parameter:

```java
@PostMapping("/users")
public User create(
        @Valid @RequestBody
        CreateUserRequest req) {
    return service.create(req);
}
```

3. Handle errors in `@ControllerAdvice`:

```java
@ExceptionHandler(
    MethodArgumentNotValidException.class)
ProblemDetail handle(
    MethodArgumentNotValidException ex) {
    // Return field-level errors
}
```

`@Valid` is critical - without it, constraints are silently ignored.

_What separates good from great:_ Emphasizing the silent bypass danger and structured error handling.

---

**Q2 [MID]: @Valid vs @Validated - when do you use each?**

_Why they ask:_ Tests nuanced understanding.
_Likely follow-up:_ "Give an example with groups."

**Answer:**

`@Valid` (Jakarta): simple validation, cascading into nested objects. No group support.

`@Validated` (Spring): supports validation groups for different operations.

Use case: create vs update:

```java
interface OnCreate {}
interface OnUpdate {}

class UserRequest {
    @Null(groups = OnCreate.class)
    @NotNull(groups = OnUpdate.class)
    Long id;

    @NotBlank  // always validated
    String name;
}

@PostMapping
User create(
    @Validated(OnCreate.class)
    @RequestBody UserRequest req) {}

@PutMapping("/{id}")
User update(
    @Validated(OnUpdate.class)
    @RequestBody UserRequest req) {}
```

Also: `@Validated` on the controller class enables `@PathVariable`/`@RequestParam` validation.

_What separates good from great:_ The create/update group example and path variable validation nuance.

---

**Q3 [SENIOR]: Design a validation strategy for a multi-team platform.**

_Why they ask:_ Tests architecture and governance.
_Likely follow-up:_ "How do you handle cross-field validation?"

**Answer:**
Principles:

1. **Validate at the boundary:** DTOs at controllers. Never on domain entities.
2. **Shared constraint library:** Common constraints (`@PhoneNumber`, `@CurrencyCode`) in a shared JAR.
3. **Validation groups:** Standard `OnCreate`/`OnUpdate` interfaces in shared library.
4. **Error format:** All teams return RFC 7807 ProblemDetail with field-level errors via shared `@ControllerAdvice`.

Cross-field validation:

```java
@Target(TYPE)
@Constraint(validatedBy =
    DateRangeValidator.class)
@interface ValidDateRange {}

@ValidDateRange
class BookingRequest {
    LocalDate startDate;
    LocalDate endDate;
    // Validator checks start < end
}
```

OpenAPI integration: generate validation constraints from annotations into the API spec. Clients can validate before sending.

_What separates good from great:_ Shared constraint library and OpenAPI integration for client-side validation.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Request Mapping - `@Valid` is applied to handler method parameters
- Exception Handling - validation errors are caught by `@ControllerAdvice`

**Builds on this (learn these next):**

- Spring Security - authentication/authorization validation
- Testing - MockMvc tests for validation error responses

**Alternatives / Comparisons:**

- Zod/Yup (TypeScript) - schema-based validation for frontend
- Pydantic (Python) - similar annotation-based validation
