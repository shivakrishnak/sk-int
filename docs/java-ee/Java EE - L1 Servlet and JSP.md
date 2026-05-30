---
layout: default
title: "Java EE - L1 Servlet and JSP"
parent: "Java EE"
nav_order: 2
permalink: /java-ee/l1-servlet-and-jsp/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 4 | [Servlet Lifecycle](#servlet-lifecycle) | ★☆☆ |
| 5 | [HTTP Request and Response Handling](#http-request-and-response-handling) | ★☆☆ |
| 6 | [JSP and JSTL](#jsp-and-jstl) | ★☆☆ |

---

# Servlet Lifecycle

**Interview Weight:** ★☆☆ - Foundational. Every
Java web framework is built on the Servlet API.
Understanding the lifecycle explains initialization,
thread safety, and destroy-time cleanup.

---

### 🎯 Model Answer

**30 seconds:**

> A Servlet has three lifecycle phases: init() (called
> once when the servlet is first loaded), service()
> (called for every HTTP request - concurrently by
> multiple threads), and destroy() (called once when
> the servlet is unloaded). The critical interview
> point: service() is called concurrently by multiple
> threads, so instance variables on a Servlet must
> be thread-safe or avoided entirely.

**3 minutes:**

> The Servlet lifecycle is managed by the Servlet
> container (Tomcat, Undertow, Jetty):
>
> 1. Loading: container loads the Servlet class and
>    creates a single instance. Timing: either on
>    first request or at startup (if loadOnStartup > 0).
>
> 2. init(ServletConfig): called once after instantiation.
>    Use for: expensive one-time setup, loading config.
>    Throws UnavailableException to signal not ready.
>
> 3. service(ServletRequest, ServletResponse): called
>    for every request by a thread-pool thread.
>    HttpServlet routes to doGet(), doPost(), etc.
>    This method is called concurrently.
>
> 4. destroy(): called once on shutdown or redeploy.
>    Use for closing resources.
>
> Thread safety: one Servlet instance handles all
> requests. Instance variables are shared across
> all concurrent calls to service(). Classic mistake:
> storing request-specific state in an instance variable.
> Rule: keep instance variables immutable; all
> request-scoped state goes on the stack or in
> the request object.

**Blank Mind Recovery:**

**(1) Restate:** "init() once, service() per request
(concurrent), destroy() once. Instance variables
shared - must be thread-safe."

**(2) First principles:** "Container creates one servlet
instance for efficiency. Multiple threads call it
concurrently. Instance variables = shared state = race condition."

**(3) Bridge:** "Same as a Spring @Controller - built
on Servlets with the same thread safety rules."

---

### 📘 Concept Explanation

**What it is:**

A Servlet is a Java class that the container manages
to handle HTTP requests. The lifecycle defines when
the container creates, initializes, uses, and destroys
the Servlet instance.

**The problem it solves:**

HTTP is stateless; Java is object-oriented. The
Servlet lifecycle bridges this: one long-lived Java
object handles many short-lived HTTP requests efficiently,
with explicit hooks for initialization and cleanup.

**Lifecycle phases:**

```
SERVLET LIFECYCLE:

Container startup or first request
         |
         v
  [Servlet Class Loaded]
         |
         v
  [new Servlet()]  <- single instance per mapping
         |
         v
  [init(ServletConfig)]  <- once, may throw UnavailableException
         |
  HTTP Request ---> [service(req, resp)] <- thread 1
  HTTP Request ---> [service(req, resp)] <- thread 2
  HTTP Request ---> [service(req, resp)] <- thread N
         |
  Container shutdown / redeploy
         |
         v
  [destroy()]  <- once
```

**Thread safety:**

```java
// BAD: instance variable holds request state
public class BadServlet extends HttpServlet {
    private String userName; // RACE CONDITION

    @Override
    protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException {
        userName = req.getParameter("user");
        // Another thread may overwrite userName here
        resp.getWriter().write("Hello " + userName);
    }
}

// GOOD: local variable (stack) holds request state
public class GoodServlet extends HttpServlet {
    // Only immutable or thread-safe fields
    private final DataSource ds; // safe - injected once
    private final String appName; // safe - immutable

    @Override
    protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException {
        String user = req.getParameter("user");
        resp.getWriter().write("Hello " + user);
    }
}
```

**loadOnStartup:**

```java
@WebServlet(urlPatterns="/api/*", loadOnStartup=1)
public class ApiServlet extends HttpServlet {
    // loadOnStartup > 0 -> init() at deploy time
    // Default (-1) = lazy init on first request
}
```

**Key insight:**

The Servlet container is thread-safe regarding
lifecycle management, but the Servlet itself is
NOT automatically thread-safe. Developer must treat
instance variables as concurrently accessible.

---

### 💻 Code Example

```java
// Production-realistic Servlet with correct lifecycle
import jakarta.servlet.ServletConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicLong;

@WebServlet(
    urlPatterns = "/api/health",
    loadOnStartup = 1
)
public class HealthServlet extends HttpServlet {

    // OK: set once in init(), never changed
    private String version;
    // OK: thread-safe counter
    private final AtomicLong requestCount
        = new AtomicLong();

    @Override
    public void init(ServletConfig config)
            throws jakarta.servlet.ServletException {
        super.init(config); // always call super
        version = config.getInitParameter("app.version");
        if (version == null) version = "unknown";
    }

    @Override
    protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException {
        long count = requestCount.incrementAndGet();
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().printf(
            "{\"status\":\"UP\",\"version\":\"%s\"," +
            "\"requests\":%d}%n",
            version, count
        );
    }

    @Override
    public void destroy() {
        super.destroy(); // always call super
    }
}

// Servlet Filter: runs before/after every servlet
@jakarta.servlet.annotation.WebFilter("/*")
public class RequestLoggingFilter
        implements jakarta.servlet.Filter {

    @Override
    public void doFilter(
        jakarta.servlet.ServletRequest request,
        jakarta.servlet.ServletResponse response,
        jakarta.servlet.FilterChain chain
    ) throws IOException,
             jakarta.servlet.ServletException {
        jakarta.servlet.http.HttpServletRequest req =
            (jakarta.servlet.http.HttpServletRequest)
            request;
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(request, response);
        } finally {
            long elapsed =
                System.currentTimeMillis() - start;
            System.out.printf(
                "%s %s %dms%n",
                req.getMethod(),
                req.getRequestURI(),
                elapsed
            );
        }
    }
}
```

> **Code walkthrough:** The `HealthServlet` shows the
> correct lifecycle pattern. `version` is set once in
> `init()` and never modified - safe for concurrent
> access because writes happen before any `service()`
> call. `requestCount` uses `AtomicLong` - the only
> safe way to maintain a shared counter without explicit
> synchronization. The `doGet` method uses only local
> variables for request-specific data. The filter
> wraps every request in timing logic: `chain.doFilter()`
> inside `try/finally` ensures timing is recorded
> even when the downstream servlet throws. Setting
> `initParameter` via `@WebServlet` or web.xml
> provides environment-specific configuration without
> code changes.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "A Servlet's lifecycle has three phases: init()
> runs once when loaded for one-time setup. service()
> runs for every HTTP request and routes to doGet(),
> doPost(), etc. destroy() runs once on unload for
> cleanup. The key thread safety point: service()
> runs concurrently so instance variables must be
> thread-safe. All request-specific data should be
> in local variables, not instance variables."

---

**Senior / Staff:**

> "The Servlet lifecycle is the foundation of all
> Java web frameworks. Spring @Controllers and JAX-RS
> resources are backed by a single instance handling
> concurrent requests - the same thread safety rules
> apply. The production issue I've seen most: request
> state leaking into instance variables, causing
> intermittent bugs that only appear under load.
> ThreadLocal is a common workaround but creates
> memory leaks in app servers if not cleaned up
> in a finally block - I've seen Metaspace exhaustion
> from ThreadLocals in filters that weren't cleared."

---

### ⚠️ Common Misconceptions

**Misconception: "A new Servlet instance is created
for each request."**

The Servlet container creates one instance per
Servlet mapping and reuses it for all requests.
Multiple threads call `service()` on the same instance
concurrently. There is no per-request instance creation.
The `SingleThreadModel` interface existed in Servlet
2.x to request per-thread semantics, but was deprecated
in Servlet 2.4 and removed. The correct model:
one instance, many concurrent callers, all mutable
state must be thread-safe.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Intermittent garbled responses under load**

*Symptom:* Under concurrent load, user A gets user B's
data or responses contain mixed content from different requests.

*Root cause:* Instance variable on Servlet holds
request-specific state modified by concurrent threads.

*Diagnosis:*
```bash
# Identify suspect fields: any non-final, non-thread-safe
# instance variable modified in doGet/doPost is a race

# Reproduce with load test
jmeter -n -t test.jmx -l results.jtl
# Or: k6 run script.js

# Take thread dump under load to see concurrent service() calls
jstack <pid> | grep -A 5 "doGet\|doPost\|service"
```

*Fix:* Move the state to a local variable or the
`HttpServletRequest` attribute map.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Servlet lifecycle phases | 2-3 min |
| Thread safety in Servlets | 3-4 min |
| Filter chain pattern | 2-3 min |
| init-param vs context-param | 2 min |
| loadOnStartup behavior | 2 min |
| Async Servlet (3.0+) | 3-4 min |
| Servlet vs Spring @Controller | 2-3 min |

---

**[MID] Q1 - What is the difference between init-param
and context-param?**

*Why they ask:* Configuration basics.

`init-param` (or `@WebInitParam`): specific to one
Servlet. Accessible via `getInitParameter()`.
Use for Servlet-specific settings.

`context-param` (web.xml): available to all Servlets
and Filters in the web app.
Accessible via `getServletContext().getInitParameter()`.
Use for application-wide settings.

```java
// In init():
String servletParam = getInitParameter("timeout");
String appParam = getServletContext()
    .getInitParameter("app.env");
```

`context-param` is how Spring DispatcherServlet
finds the Spring application context config path.

*What separates good from great:* "context-param is also how web.xml configures Spring's ContextLoaderListener: it sets contextConfigLocation to point to the Spring XML or annotated config class. That's the entire Spring-on-Servlet bootstrap mechanism."

---

**[MID] Q2 - What is async Servlet support and
when do you need it?**

*Why they ask:* Modern Servlet features.

Problem: a Servlet thread is held for the full
request duration. If the request waits 5 seconds
for a slow database call, that thread is blocked.
With a small thread pool and many slow requests:
thread starvation.

Async Servlet (Servlet 3.0+):
```java
@WebServlet(urlPatterns="/async", asyncSupported=true)
public class AsyncServlet extends HttpServlet {

    private final ExecutorService pool =
        Executors.newFixedThreadPool(10);

    @Override
    protected void doGet(
        HttpServletRequest req,
        HttpServletResponse resp
    ) {
        AsyncContext ctx = req.startAsync();
        ctx.setTimeout(30_000);
        pool.submit(() -> {
            try {
                // Long-running work - no thread blocked
                Thread.sleep(2000);
                ctx.getResponse().getWriter()
                    .write("done");
            } catch (Exception e) {
                // handle error
            } finally {
                ctx.complete(); // release async context
            }
        });
        // Servlet thread released here immediately
    }
}
```

When to use: long-polling, server-sent events,
slow external service calls. Modern alternative:
JAX-RS `@Suspended AsyncResponse` or reactive.

*What separates good from great:* "Async Servlet is the foundation for server-sent events (SSE) and WebSocket upgrades in JAX-RS and Spring MVC. For most cases, the higher-level abstractions are cleaner than raw AsyncContext."

---

**[MID] Q3 - How does the Servlet Filter chain work?**

*Why they ask:* Cross-cutting concerns in Java EE.

Filters intercept requests before the Servlet and
responses after:

```
Request -> Filter1 -> Filter2 -> Servlet
                               -> Filter2 -> Filter1 -> Response
```

Each filter calls `chain.doFilter()` to pass control
forward. Not calling it short-circuits (used for
auth failures: return 401 without proceeding).

Order: determined by url-pattern matching and web.xml
declaration order. For deterministic ordering, declare
in web.xml or use `FilterRegistration` API.

Use cases: authentication, CORS headers, request logging,
gzip compression, request/response wrapping.

*What separates good from great:* "Spring's security filter chain is built on this mechanism. `OncePerRequestFilter` ensures a filter runs exactly once even on internal forwards. Without it, a filter could execute twice on a forwarded request - a subtle but real issue with security filters."

---

**[MID] Q4 - What is a Servlet Context?**

*Why they ask:* Web application scope concept.

`ServletContext` represents the entire web application.
One instance per deployed WAR.

Provides:
- Application-wide init parameters (context-param)
- Attribute storage shared across all servlets/filters
- Resource access: `context.getResourceAsStream("/WEB-INF/config.xml")`
- Dynamic Servlet/Filter registration at startup
- Logging via `context.log()`

`ServletContextListener`:
```java
@WebListener
public class AppStartupListener
        implements jakarta.servlet.ServletContextListener {
    @Override
    public void contextInitialized(
        jakarta.servlet.ServletContextEvent evt
    ) {
        DatabasePool.init(); // global resources
    }
    @Override
    public void contextDestroyed(
        jakarta.servlet.ServletContextEvent evt
    ) {
        DatabasePool.shutdown();
    }
}
```

Spring's ApplicationContext is stored as a
ServletContext attribute - that is how Spring MVC
finds the Spring context.

*What separates good from great:* "ServletContext attributes are application scope: all servlets share the same Map. A common production bug: storing a mutable non-thread-safe object as a context attribute and then modifying it concurrently from multiple servlets."

---

**[MID] Q5 - What happens when a Servlet throws
an unchecked exception?**

*Why they ask:* Error handling fundamentals.

Uncaught exception from doGet(): container catches
it, sends 500 response (or redirects to error page
configured in web.xml).

Error pages (web.xml):
```xml
<error-page>
  <error-code>404</error-code>
  <location>/error/404.html</location>
</error-page>
<error-page>
  <exception-type>
    java.lang.RuntimeException
  </exception-type>
  <location>/error/500</location>
</error-page>
```

In JAX-RS: `ExceptionMapper<T>` maps exceptions
to HTTP responses. In Spring MVC: `@ControllerAdvice`.

*What separates good from great:* "Always configure error pages to return a clean JSON or HTML response. The default container error page includes a stack trace - that leaks internal structure to attackers. A 500 response body should never contain class names or file paths in production."

---

**[MID] Q6 - How does session management work
in the Servlet API?**

*Why they ask:* Web state management.

`HttpSession`: server-side session storage.
```java
HttpSession session = request.getSession(true);
session.setAttribute("user", userObject);
session.setMaxInactiveInterval(1800); // 30 min
```

Mechanism: container generates JSESSIONID cookie
(or URL param if cookies disabled). Maps ID to
in-memory session object.

Problems at scale:
- Sessions in-memory per server: sticky sessions needed
- Session replication: Infinispan (WildFly), Redis

Modern alternative: JWT-based stateless tokens.
No server-side state; scales horizontally without
sticky sessions or replication.

*What separates good from great:* "In cloud deployments with auto-scaling, HttpSession is an anti-pattern. When pods scale down, sessions are lost. JWT or Redis-backed sessions are the cloud-native answer. I'd also always call session.invalidate() on logout to prevent session fixation attacks."

---

**[MID] Q7 - What is the role of web.xml today?**

*Why they ask:* Modern Servlet configuration.

Since Servlet 3.0, annotations replaced most web.xml
config. Still needed for:
- Error page mapping (`<error-page>`)
- Security constraints and login-config
- Welcome file list
- Overriding annotations per environment
- Servlet mapping order control (deterministic filter order)

Empty `web.xml`: optional in Servlet 3.0+. Some
frameworks require it to activate behavior.
Spring Boot: no web.xml at all.

When to use: environment-specific config overrides.
Ship a base app with annotated config; override
specific settings per environment via web.xml.
Prefer environment variables for new projects.

*What separates good from great:* "The one thing I always put in web.xml even for new projects: security constraints that enforce HTTPS for all URLs (`<transport-guarantee>CONFIDENTIAL</transport-guarantee>`). Annotations can express this too, but web.xml makes it clearly visible as a security policy."

---

---

# HTTP Request and Response Handling

**Interview Weight:** ★☆☆ - Foundational. Understanding
how the Servlet API exposes HTTP request and response
is required for any Java web development interview.

---

### 🎯 Model Answer

**30 seconds:**

> `HttpServletRequest` provides access to all request
> data: method, URI, headers, query parameters, body.
> `HttpServletResponse` provides the response writer
> and status code. In JAX-RS (the modern approach),
> these are abstracted: annotate parameters with
> `@PathParam`, `@QueryParam`, `@HeaderParam` and
> the framework populates them. Response is built
> with `Response.ok(entity).build()`. Critical detail:
> response headers must be set BEFORE writing the
> body - once the body starts, headers are committed.

**3 minutes:**

> The HTTP request/response model in Java EE has
> two layers: the raw Servlet API and the higher-level
> JAX-RS abstraction.
>
> HttpServletRequest exposes:
> - Request line: getMethod(), getRequestURI(), getQueryString()
> - Headers: getHeader("Content-Type")
> - Parameters: getParameter("name") - query string + form body
> - Body: getInputStream() (binary) or getReader() (text)
> - Session: getSession()
> - Authentication: getUserPrincipal(), isUserInRole()
>
> HttpServletResponse exposes:
> - Status: setStatus(200) or sendError(404)
> - Headers: setHeader("Content-Type", "application/json")
> - Body: getOutputStream() or getWriter()
>
> JAX-RS simplifies parameter access:
> ```java
> @GET @Path("/{id}")
> public User getUser(
>     @PathParam("id") Long id,
>     @QueryParam("format") String fmt,
>     @Context HttpServletRequest req) {...}
> ```
>
> Non-obvious detail: getParameter() reads both query
> string AND form body. If you call getInputStream()
> first, form parameters may no longer be readable
> because the stream was consumed.

**Blank Mind Recovery:**

**(1) Restate:** "HttpServletRequest = method, URL, headers,
params, body. HttpServletResponse = status, headers, body.
JAX-RS abstracts these with annotations."

**(2) First principles:** "HTTP has request line, headers,
body. Response has status, headers, body. Servlet API is
a Java interface to these."

**(3) Bridge:** "Same as Node.js req/res objects or
Python Flask's request/response, but typed Java."

---

### 📘 Concept Explanation

**What it is:**

`HttpServletRequest` and `HttpServletResponse` are
Java objects representing an HTTP request and response.
The container creates them for each request and
passes them to the Servlet.

**The problem it solves:**

Raw HTTP is a text protocol. The Servlet API provides
a typed Java interface: get a header as a String,
get parameters by name, write JSON via a Writer.

**Request access methods:**

```
getMethod()          -> "GET", "POST", etc.
getRequestURI()      -> "/api/users/42"
getContextPath()     -> "/myapp"
getQueryString()     -> "page=1&size=20"
getParameter("key")  -> query param or form field
getHeader("name")    -> "application/json"
getCookies()         -> Cookie[]
getInputStream()     -> raw body bytes (consume once)
getReader()          -> body as BufferedReader
getSession()         -> HttpSession
getAttribute("key")  -> request-scoped attribute
getUserPrincipal()   -> authenticated user
```

**JAX-RS parameter annotations:**

```java
@GET
@Path("/users/{id}/orders")
public List<Order> getOrders(
    @PathParam("id")     Long userId,
    @QueryParam("page")  int page,
    @QueryParam("size")  int size,
    @HeaderParam("X-Request-ID") String reqId,
    @CookieParam("session") String cookie,
    @Context UriInfo uriInfo
) { ... }
```

---

### 💻 Code Example

```java
// Raw Servlet approach
@WebServlet("/echo")
public class EchoServlet extends HttpServlet {

    @Override
    protected void doPost(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException {
        // Read method and URL
        String method = req.getMethod();
        String uri = req.getRequestURI();

        // Read query parameter (safe default)
        String name = req.getParameter("name");

        // Read body (once - stream is consumed)
        StringBuilder body = new StringBuilder();
        try (java.io.BufferedReader reader =
                req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
        }

        // Set headers BEFORE writing body
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control",
            "no-store, no-cache");
        resp.getWriter().printf(
            "{\"method\":\"%s\",\"uri\":\"%s\"," +
            "\"name\":\"%s\",\"bodyLen\":%d}%n",
            method, uri,
            name != null ? name : "",
            body.length()
        );
    }
}

// JAX-RS equivalent (preferred in new code)
@Path("/echo")
@Stateless
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EchoResource {

    @POST
    public Response echo(
        @QueryParam("name") String name,
        Map<String, Object> body,
        @Context UriInfo uriInfo,
        @Context HttpHeaders headers
    ) {
        return Response.ok(Map.of(
            "uri", uriInfo.getRequestUri().toString(),
            "name", name != null ? name : "",
            "contentType",
                headers.getMediaType().toString()
        )).build();
    }
}
```

> **Code walkthrough:** The raw Servlet shows the
> full request-reading pattern. `getReader()` in a
> `try-with-resources` consumes the body exactly once -
> a second call returns an empty stream. Response headers
> must be set BEFORE calling `getWriter()` because once
> writing starts, the HTTP response headers are committed
> and any subsequent `setHeader()` calls are silently
> ignored. The JAX-RS version shows the clean abstraction:
> `@QueryParam` extracts query string values, the
> `Map<String, Object>` body parameter is automatically
> deserialized from JSON by Jackson, and `Response.ok()`
> builds the response without directly accessing the
> low-level response object. The framework handles
> header commitment safely.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "HttpServletRequest gives you everything about the
> HTTP request: method, URL, headers, query parameters,
> and the body. HttpServletResponse lets you set the
> status code, headers, and write the body. In JAX-RS,
> you use @PathParam, @QueryParam, @HeaderParam
> annotations and the framework extracts values from
> the request. Response is built with Response.ok()."

---

**Senior / Staff:**

> "The critical production detail: response headers
> must be set before writing the response body. Once
> you write to the OutputStream or Writer, the headers
> are committed - any subsequent setHeader() is silently
> ignored. This causes subtle bugs where CORS or
> Cache-Control headers don't appear in responses.
> Also: getParameter() reads both query string and
> form body - if you call getInputStream() first,
> form parameters may become unavailable. In JAX-RS,
> the Response builder avoids these issues by not
> committing anything until the resource method returns."

---

### ⚠️ Common Misconceptions

**Misconception: "getParameter() reads only query string parameters."**

`HttpServletRequest.getParameter()` reads parameters
from both the query string AND the request body
if the body is `application/x-www-form-urlencoded`.
A POST form submission's fields are accessible
via `getParameter()` even though they're in the body.
The conflict: if you call `getInputStream()` to
read a JSON body first, the stream is consumed and
subsequent `getParameter()` calls for form fields
may return null. Choose one: `getParameter()` for
form data OR `getInputStream()`/`getReader()` for
raw body. Not both.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Response headers not appearing despite being set in code**

*Symptom:* CORS or Cache-Control headers are set
in the code but don't appear in the actual HTTP response.

*Root cause:* Headers set after the response is
committed (after writing to getWriter() / getOutputStream()),
or set in a Filter after chain.doFilter().

*Diagnosis:*
```java
// Check if response is committed
if (!response.isCommitted()) {
    response.setHeader("X-Custom", "value");
} else {
    log.warn("Response committed - header not set");
}
```

*Fix:* Set all headers before writing any output.
In Filters, set headers BEFORE calling chain.doFilter().

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| HttpServletRequest key methods | 2-3 min |
| getParameter vs getInputStream conflict | 3 min |
| Response header committed issue | 2-3 min |
| JAX-RS vs raw Servlet | 2-3 min |
| Content negotiation | 2-3 min |
| Multipart file upload | 2-3 min |
| Request forwarding vs redirect | 2-3 min |

---

**[MID] Q1 - What is the difference between forward
and redirect in Servlets?**

*Why they ask:* Server-side navigation.

Forward (server-side):
```java
RequestDispatcher rd =
    req.getRequestDispatcher("/WEB-INF/views/result.jsp");
rd.forward(req, resp);
```
- Server-side: client never knows it happened
- URL in browser stays the same
- Request attributes are preserved
- One HTTP round trip

Redirect (client-side):
```java
resp.sendRedirect("/login?error=true");
```
- Container sends 302 + Location header
- Browser makes a new request
- URL changes in browser
- Request attributes NOT preserved
- Two HTTP round trips

Post-Redirect-Get (PRG): use redirect after POST to
prevent form resubmission on refresh (F5). Without it,
refreshing the results page resubmits the form.

*What separates good from great:* "PRG is the pattern that prevents duplicate purchases on e-commerce sites. POST /checkout -> process -> redirect to /confirmation. Refreshing /confirmation doesn't re-submit the order. Every form POST that creates data should use PRG."

---

**[MID] Q2 - How do you handle multipart file
uploads in Servlets?**

*Why they ask:* Common practical scenario.

Servlet 3.0+ has built-in multipart support:
```java
@WebServlet("/upload")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,   // 1MB in memory
    maxFileSize = 1024 * 1024 * 10,    // 10MB per file
    maxRequestSize = 1024 * 1024 * 50  // 50MB total
)
public class UploadServlet extends HttpServlet {
    @Override
    protected void doPost(
        HttpServletRequest req,
        HttpServletResponse resp
    ) throws IOException,
             jakarta.servlet.ServletException {
        jakarta.servlet.http.Part part =
            req.getPart("file");
        String fileName = part.getSubmittedFileName();
        // Validate file type by content, not extension
        try (java.io.InputStream is =
                part.getInputStream()) {
            java.nio.file.Files.copy(
                is,
                java.nio.file.Path.of(
                    "/uploads/" + fileName
                ),
                java.nio.file.StandardCopyOption
                    .REPLACE_EXISTING
            );
        }
        resp.sendRedirect("/success");
    }
}
```

Security: validate file type by content (magic bytes),
not extension. A file named photo.jpg containing a
script can cause server-side injection.

*What separates good from great:* "Two security controls for file upload: (1) validate MIME type by reading the first bytes (magic numbers), not trusting the filename extension. (2) Store uploads outside the web root - files in WEB-INF or a separate directory cannot be executed via HTTP."

---

**[MID] Q3 - What is content negotiation in JAX-RS?**

*Why they ask:* JAX-RS media type handling.

The client signals accepted formats via the Accept header;
JAX-RS picks the best match.

```java
@GET
@Path("/users/{id}")
@Produces({
    MediaType.APPLICATION_JSON,
    MediaType.APPLICATION_XML
})
public User getUser(@PathParam("id") Long id) {
    return userService.find(id);
}
```

- `Accept: application/json` -> JSON
- `Accept: application/xml` -> XML
- `Accept: text/html` -> 406 Not Acceptable

MessageBodyWriter implementations perform serialization:
Jackson for JSON, JAXB for XML.

*What separates good from great:* "A common production bug: @Produces(APPLICATION_JSON) on an endpoint but Jackson is missing from the classpath. The response is 500 instead of JSON, and the error is misleading: 'MessageBodyWriter not found.' Always verify JAX-RS provider registration in integration tests."

---

**[MID] Q4 - How do you handle CORS in a JAX-RS API?**

*Why they ask:* Practical API security.

CORS is enforced by browsers for cross-domain requests.
The server must respond with correct headers.

```java
@Provider
public class CorsFilter
        implements ContainerResponseFilter {
    // allowlist - never use * for auth endpoints
    private static final Set<String> ALLOWED =
        Set.of(
            "https://app.example.com",
            "https://admin.example.com"
        );

    @Override
    public void filter(
        ContainerRequestContext req,
        ContainerResponseContext resp
    ) {
        String origin = req.getHeaderString("Origin");
        if (origin != null && ALLOWED.contains(origin)) {
            resp.getHeaders().add(
                "Access-Control-Allow-Origin", origin
            );
            resp.getHeaders().add(
                "Access-Control-Allow-Methods",
                "GET, POST, PUT, DELETE, OPTIONS"
            );
            resp.getHeaders().add(
                "Access-Control-Allow-Headers",
                "Content-Type, Authorization"
            );
        }
    }
}

// Handle preflight OPTIONS requests
@OPTIONS
@Path("{any: .*}")
public Response preflight() {
    return Response.ok().build();
}
```

*What separates good from great:* "Never use Access-Control-Allow-Origin: * for endpoints that use cookies or Authorization headers - browsers reject it with credentials anyway. Always use an explicit allowlist. Wildcard CORS signals a security misunderstanding to reviewers."

---

**[MID] Q5 - How does the Servlet getParameter
vs getInputStream conflict work?**

*Why they ask:* Subtle Servlet API behavior.

`getParameter()` reads parameters from query string
AND form body (`application/x-www-form-urlencoded`).
Internally, when form parameters are read, the
body InputStream is consumed.

Conflict:
```java
// BAD: reads body as stream first, then tries form params
public void doPost(HttpServletRequest req, ...) {
    InputStream is = req.getInputStream(); // consumes body
    // Below returns null even for form POSTs:
    String name = req.getParameter("name"); // BROKEN
}

// GOOD: choose ONE approach based on Content-Type
public void doPost(HttpServletRequest req, ...) {
    String contentType = req.getContentType();
    if (contentType != null &&
        contentType.contains("application/json")) {
        // JSON: use getReader()
        String json = req.getReader().lines()
            .collect(Collectors.joining());
    } else {
        // Form: use getParameter()
        String name = req.getParameter("name");
    }
}
```

JAX-RS avoids this entirely by selecting the right
MessageBodyReader based on Content-Type.

*What separates good from great:* "This conflict is why JAX-RS is preferred over raw Servlets for REST APIs. JAX-RS MessageBodyReaders handle the Content-Type-appropriate deserialization, and you never touch getInputStream() directly."

---

**[MID] Q6 - How do you set and read cookies
in the Servlet API?**

*Why they ask:* Session/cookie management.

Reading cookies:
```java
Cookie[] cookies = req.getCookies();
if (cookies != null) {
    for (Cookie c : cookies) {
        if ("session".equals(c.getName())) {
            String sessionToken = c.getValue();
        }
    }
}
```

Writing cookies:
```java
Cookie cookie = new Cookie("session", tokenValue);
cookie.setHttpOnly(true);    // no JS access - XSS protection
cookie.setSecure(true);      // HTTPS only
cookie.setPath("/");         // available to all paths
cookie.setMaxAge(3600);      // 1 hour; -1 = session cookie
// SameSite via header (Cookie API lacks direct support)
resp.setHeader("Set-Cookie",
    "session=" + tokenValue +
    "; Path=/; HttpOnly; Secure; SameSite=Strict"
);
```

*What separates good from great:* "The Servlet Cookie API doesn't have a SameSite attribute method - you must set it via the raw Set-Cookie header string. Always set HttpOnly=true (prevents JS from reading the cookie, blocking cookie theft via XSS) and Secure=true (HTTPS only). SameSite=Strict prevents CSRF for session cookies."

---

**[MID] Q7 - What is request forwarding and
how does it differ from include?**

*Why they ask:* Servlet request dispatching.

Forward:
- Control transferred to target resource
- Target generates the complete response
- Current response buffer is cleared
- After forward(), caller must not write to response
```java
req.getRequestDispatcher("/WEB-INF/result.jsp")
   .forward(req, resp);
// Do NOT write to resp after this
```

Include:
- Target resource output is embedded in current response
- Caller can write before and after include
- Used for: header/footer JSP fragments
```java
resp.getWriter().write("<header>");
req.getRequestDispatcher("/header.jsp")
   .include(req, resp);
resp.getWriter().write("</header>");
```

Key difference: forward transfers control completely;
include merges output.

*What separates good from great:* "Include is the server-side equivalent of SSI (Server-Side Includes). It's useful for JSP page composition but has the same response commitment problems: once include writes to the response, headers may be committed. For modern web apps, template composition (Thymeleaf fragments) is cleaner."

---

---

# JSP and JSTL

**Interview Weight:** ★☆☆ - Foundational. JSP is
largely superseded by React and Thymeleaf, but
knowledge is required for maintaining legacy Java EE
web applications. The XSS security rules are universally
applicable.

---

### 🎯 Model Answer

**30 seconds:**

> JSP (JavaServer Pages) is a template language that
> generates HTML with embedded Java. The container
> compiles it to a Servlet. JSTL (JSP Standard Tag Library)
> provides tags that replace Java scriptlets: `<c:forEach>`
> for loops, `<c:if>` for conditionals, `<c:out>` for
> safe output. The critical security rule: always use
> `<c:out>` to output user data - it HTML-escapes the
> value and prevents XSS. Never use `<%= %>` scriptlets
> for user-controlled data.

**3 minutes:**

> JSP's compile-to-Servlet model means a JSP page
> is syntactic sugar over a Servlet. At deployment,
> the container converts JSP to a Java Servlet class.
>
> Three ways to embed Java in JSP:
> 1. Scriptlets `<% java code %>`: old, deprecated.
>    Java mixed with HTML - untestable, unmaintainable.
> 2. Expressions `<%= value %>`: prints a value.
>    NOT HTML-escaped - XSS if value is user input.
> 3. EL (Expression Language) `${variable}`: modern,
>    accesses request/session/application attributes.
>    Preferred but also NOT automatically escaped.
>
> JSTL standard tags:
> - `<c:out value="${user.name}"/>` - HTML-escaped output
> - `<c:forEach items="${list}" var="item">` - loops
> - `<c:if test="${user.admin}">` - conditionals
> - `<c:url value="/path"/>` - URL encoding
>
> Modern alternatives: Thymeleaf (HTML-native templates,
> testable without server), React/Angular (SPA + REST API).
>
> JSP is only appropriate for: legacy app maintenance
> and simple admin UIs in Java EE applications.

**Blank Mind Recovery:**

**(1) Restate:** "JSP = HTML + Java, compiled to Servlet.
JSTL = standard tags for loops/conditionals/output.
c:out prevents XSS."

**(2) First principles:** "Server renders HTML using data.
Security concern: user data in HTML must be escaped
to prevent script injection."

**(3) Bridge:** "Like PHP's <?php ?> or Python's Jinja2 -
server-side template. Same XSS rules apply everywhere."

---

### 📘 Concept Explanation

**What it is:**

JSP is a text-based document mixing HTML and Java.
The container compiles it to a Servlet class.
JSTL provides XML-like tags implementing common
logic patterns without Java scriptlets.

**The problem it solves:**

Pure Servlets generate HTML via `out.println()` -
readable by Java developers but not web designers.
JSP inverts this: write HTML with embedded logic.
JSTL further cleans by replacing scriptlets with tags.

**JSP processing:**

```
JSP file (page.jsp)
  |
  v
JSP compiler (deploy time or first request)
  |
  v
Generated Servlet Java class
  |
  v
Compiled .class file
  |
  v
Container executes (one instance, many threads)
  |
  v
HTML output sent to client
```

**Implicit objects in every JSP:**

```
request     - HttpServletRequest
response    - HttpServletResponse
session     - HttpSession
application - ServletContext
out         - JspWriter
pageContext - PageContext
```

**EL scope search order:**

`${name}` searches: pageScope -> requestScope ->
sessionScope -> applicationScope. First match wins.

---

### 💻 Code Example

```jsp
<%--
  BAD: Scriptlets + unescaped output = XSS
--%>
<%@ page language="java" %>
<html><body>
  Hello <%=request.getParameter("name")%>
  <%-- If name = <script>alert(1)</script>
       the browser executes it --%>
</body></html>

<%--
  GOOD: JSTL + EL + c:out for safe output
--%>
<%@ page language="java"
   contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c"
   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt"
   uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
  <title><c:out value="${product.name}"/></title>
</head>
<body>

<%-- Safe output: HTML-escapes the value --%>
<h1>Welcome, <c:out value="${user.displayName}"/></h1>

<%-- Loop over list set by Servlet --%>
<c:if test="${not empty products}">
  <ul>
    <c:forEach items="${products}" var="product"
               varStatus="status">
      <li>
        <c:out value="${status.index + 1}"/>.
        <c:out value="${product.name}"/> -
        <fmt:formatNumber value="${product.price}"
                          type="currency"/>
        <c:if test="${product.onSale}">
          <span class="badge">SALE</span>
        </c:if>
      </li>
    </c:forEach>
  </ul>
</c:if>

<%-- URL encoding prevents param injection --%>
<a href="<c:url value='/products'>
  <c:param name='category' value='${category}'/>
</c:url>">Browse</a>

</body>
</html>
```

> **Code walkthrough:** The BAD example shows the
> classic XSS vulnerability: `<%=request.getParameter("name")%>`
> outputs raw user input into HTML without escaping.
> If the parameter contains `<script>alert(1)</script>`,
> the browser executes it. The GOOD example replaces
> all scriptlets with JSTL. `<c:out>` HTML-escapes:
> `<script>` becomes `&lt;script&gt;`. `<c:forEach>`
> provides loops with `varStatus` for the current
> index (0-based; add 1 for display). `<fmt:formatNumber
> type="currency">` formats money by locale. `<c:url>`
> with `<c:param>` URL-encodes the link parameter -
> important for category names containing spaces or
> special characters. Scriptlets are absent entirely:
> all logic is in JSTL tags.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "JSP is a template language that generates HTML
> with Java code embedded. The container compiles it
> to a Servlet. JSTL provides standard tags: c:forEach
> for loops, c:if for conditionals, c:out for safe
> output. Security rule: always use c:out for user
> data - it HTML-escapes the value and prevents XSS.
> Scriptlets (Java in <% %>) are deprecated and should
> never be used."

---

**Senior / Staff:**

> "JSP has two serious maintenance problems: testability
> and separation of concerns. JSP with JSTL is still
> basically untestable without a Servlet container.
> Thymeleaf solves this: templates are valid HTML
> that can be opened in a browser or tested with
> HtmlUnit without a server. The 'natural HTML' property
> means front-end developers can work with templates
> without Java setup. For new projects I'd always
> choose Thymeleaf, or better, a single-page app with
> a REST API. JSP is legacy maintenance work."

---

### ⚠️ Common Misconceptions

**Misconception: "EL expressions (${value}) in JSP
automatically prevent XSS."**

EL expressions do NOT HTML-escape output. `${user.name}`
outputs the raw string value directly into HTML.
If the value contains `<script>alert(1)</script>`,
the script executes in the browser. The safe display
mechanism is `<c:out value="${user.name}"/>`, which
calls HTML escaping. Mental model: `${...}` is a
value lookup; `<c:out>` is the safe output tag.
They are NOT equivalent, despite looking similar.
The mistake of using `${...}` thinking it's safe is
one of the most common XSS vulnerabilities in legacy
Java EE web applications.

---

### 🚨 Failure Modes and Diagnosis

**Failure: 500 error on JSP after migrating to Jakarta EE 9+**

*Symptom:* JSP renders 500 with ClassNotFoundException
for `javax.servlet.jsp.jstl.*` after migration to
Jakarta EE 9+.

*Root cause:* JSTL 1.x uses the `javax.*` namespace.
Jakarta EE 9+ requires JSTL 3.x with `jakarta.*`.

*Fix:*
```xml
<!-- Remove old JSTL -->
<!-- javax.servlet:jstl:1.2 -->

<!-- Add jakarta JSTL -->
<dependency>
  <groupId>jakarta.servlet.jsp.jstl</groupId>
  <artifactId>
    jakarta.servlet.jsp.jstl-api
  </artifactId>
  <version>3.0.0</version>
</dependency>
<dependency>
  <groupId>org.glassfish.web</groupId>
  <artifactId>
    jakarta.servlet.jsp.jstl
  </artifactId>
  <version>3.0.1</version>
</dependency>
```

Update taglib URI:
```jsp
<%-- Old --%>
<%@ taglib prefix="c"
  uri="http://java.sun.com/jsp/jstl/core" %>

<%-- New (Jakarta EE 9+) --%>
<%@ taglib prefix="c"
  uri="jakarta.tags.core" %>
```

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| JSP lifecycle | 2-3 min |
| Preventing XSS in JSP | 3-4 min |
| JSTL vs scriptlets | 2-3 min |
| EL scope resolution | 2 min |
| JSP vs Thymeleaf | 2-3 min |
| Custom JSP tags | 2-3 min |
| JSP include mechanisms | 2 min |

---

**[MID] Q1 - How does EL scope resolution work?**

*Why they ask:* JSP variable resolution.

`${name}` searches scopes in order:
1. pageScope (page-local only)
2. requestScope (set by Servlet via `setAttribute()`)
3. sessionScope (user session)
4. applicationScope (whole app)

First match wins. Use explicit scope for clarity:
```jsp
${requestScope.user}     <%-- request attribute --%>
${sessionScope.cart}     <%-- session attribute --%>
${applicationScope.cfg}  <%-- app-wide attribute --%>
```

Servlet sets request attributes before forwarding:
```java
// Servlet
request.setAttribute("products", list);
request.getRequestDispatcher(
    "/WEB-INF/views/list.jsp"
).forward(request, response);
```

Anti-pattern: putting data in session scope to avoid
passing through request. This bloats sessions and
causes stale data on back-button navigation.

*What separates good from great:* "The anti-pattern of storing everything in session scope to make it accessible in JSP is a common legacy code smell. Session attributes live until invalidated or timeout. I'd always ask: does this data need to survive across multiple requests, or is it page-specific? If page-specific: request scope."

---

**[MID] Q2 - What are JSTL function tags?**

*Why they ask:* JSTL completeness.

JSTL functions (fn: prefix):
```jsp
<%@ taglib prefix="fn"
  uri="http://java.sun.com/jsp/jstl/functions" %>

${fn:length(list)}            <%-- list/string size --%>
${fn:toUpperCase(str)}
${fn:contains(str, "foo")}
${fn:escapeXml(userInput)}    <%-- like c:out --%>
${fn:substring(str, 0, 10)}
${fn:replace(str, "old", "new")}
```

Key: `fn:escapeXml()` is equivalent to `<c:out>`
for inline EL expressions.

Better practice: do string logic in the Java layer
before passing to JSP. JSP should only display data,
not process it.

*What separates good from great:* "Using fn:replace or fn:substring in JSP is a code smell - it means business logic crept into the view layer. If I see complex fn: usage in a JSP, I'd move that logic to the Servlet or CDI bean."

---

**[MID] Q3 - How do you prevent XSS in JSP?**

*Why they ask:* Security fundamentals.

Primary defense: `<c:out>` for all user-controlled data:
```jsp
<%-- NEVER: raw EL or scriptlet --%>
Hello ${user.name}
Hello <%=user.getName()%>

<%-- ALWAYS: c:out for user data --%>
Hello <c:out value="${user.name}"/>
```

Or `fn:escapeXml()` inline:
```jsp
Hello ${fn:escapeXml(user.name)}
```

JavaScript context (different escaping needed):
```jsp
<%-- WRONG: HTML escaping != JS escaping --%>
var name = "${user.name}";

<%-- Use OWASP Java Encoder for JS context --%>
var name = "${e:forJavaScript(user.name)}";
```

Defense in depth: Content-Security-Policy header,
output encoding library (OWASP Java Encoder).

*What separates good from great:* "HTML context and JavaScript context require different escaping functions. &lt; prevents HTML injection but doesn't prevent JavaScript injection in inline <script> blocks. OWASP Java Encoder has forJavaScript(), forHtml(), forCssString(), and forUriComponent() - use the right one for the context."

---

**[MID] Q4 - What is a JSP tagfile and how is
it different from a custom tag handler?**

*Why they ask:* Modern JSP practices.

Tagfile: JSP fragment in WEB-INF/tags/, used as
a custom tag without writing Java:

```jsp
<%-- WEB-INF/tags/alert.tag --%>
<%@ attribute name="type" required="false" %>
<%@ attribute name="message" required="true" %>
<div class="alert alert-${empty type ?
  'info' : type}">
  <c:out value="${message}"/>
</div>
```

```jsp
<%-- In JSP page --%>
<%@ taglib prefix="app" tagdir="/WEB-INF/tags" %>
<app:alert type="warning"
  message="${validationError}"/>
```

Custom tag handler: requires a Java class implementing
`SimpleTagSupport` or `TagSupport`, plus a TLD file.
Used when the tag needs Java logic that JSTL can't express.

Tagfiles are preferred: no Java class, no TLD,
pure JSP syntax, maintainable by non-Java developers.

*What separates good from great:* "Tagfiles are the JSP equivalent of React components. Any UI pattern repeated more than twice belongs in a tagfile. The overhead is negligible and it keeps JSP pages clean."

---

**[MID] Q5 - What is the difference between include
directive and jsp:include?**

*Why they ask:* JSP composition.

Include directive (compile-time):
```jsp
<%@ include file="header.jsp" %>
```
- Merged before compilation into one Servlet
- Static: changes require recompilation
- Shares variables with parent

`<jsp:include>` (runtime):
```jsp
<jsp:include page="header.jsp">
  <jsp:param name="title" value="${title}"/>
</jsp:include>
```
- Separate request at runtime
- Can pass parameters
- Target can be any URL (Servlet, JSP, HTML)

Tagfiles (preferred modern approach): reusable
JSP fragments with typed parameters. No variable
naming conflicts, encapsulated.

*What separates good from great:* "The include directive is a compile-time text merge - it creates one big Servlet class. Variable name collisions between the parent and included file cause compilation errors. Tagfiles solve this by being separate compilation units with their own scope."

---

**[MID] Q6 - Why is Thymeleaf preferred over JSP
for new Jakarta EE projects?**

*Why they ask:* Technology selection.

Thymeleaf advantages:
1. Natural HTML: templates are valid HTML, browsable
   without a server. JSP requires a container.
2. Testable: works with HtmlUnit or Thymeleaf's
   standalone engine, no container needed.
3. No scriptlets: no escape hatch for Java code
   in the view. Clean separation enforced.
4. Spring Boot integration: first-class support;
   no WAR deployment needed.
5. Escaping by default: `th:text="${user.name}"`
   HTML-escapes automatically (unlike JSP EL).
6. Active development: Thymeleaf 3.x; JSP is
   in maintenance mode.

```html
<!-- Thymeleaf: valid HTML without server -->
<html xmlns:th="http://www.thymeleaf.org">
<body>
  <h1 th:text="${user.name}">Placeholder</h1>
  <ul th:each="p : ${products}">
    <li th:text="${p.name}">Product</li>
  </ul>
</body>
</html>
```

*What separates good from great:* "Thymeleaf's automatic escaping in th:text is the security win over JSP: you have to explicitly use th:utext (unescaped) to output raw HTML. In JSP you have to remember to use c:out. Safe-by-default vs safe-if-you-remember."

---

**[MID] Q7 - What happens when a JSP page is
modified in a running application?**

*Why they ask:* Deployment and hot reload behavior.

JSP files are checked for modification on each request
(in development mode). If modified: the container
recompiles the JSP to a Servlet class.

Development server (Tomcat with `development="true"`
for the JSP servlet):
- Modification check on every request
- Automatic recompile and reload on change
- No server restart needed for JSP changes

Production servers: disable JSP recompilation check
(`checkInterval=0`). Pre-compile JSPs at build time
with the `jspc` Maven plugin for production.

Pre-compilation advantages:
- No recompile cost on first request
- Compilation errors caught at build time
- Smaller attack surface (no .jsp files needed on server)

```xml
<!-- Maven: pre-compile JSPs at build time -->
<plugin>
  <groupId>org.apache.sling</groupId>
  <artifactId>jspc-maven-plugin</artifactId>
  <executions>
    <execution>
      <goals><goal>jspc</goal></goals>
    </execution>
  </executions>
</plugin>
```

*What separates good from great:* "Pre-compiling JSPs at build time is a production best practice: it catches syntax errors before deployment and eliminates the first-request compilation delay. It also removes the need for the jsp compiler on the production server - a minor security improvement."
