---
layout: default
title: "REST API - L3 Performance"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 7
permalink: /rest-api/l3-performance/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [HTTP Caching for REST APIs](#http-caching-for-rest-apis) | medium |
| 2 | [Rate Limiting and Throttling Design](#rate-limiting-and-throttling-design) | medium |

---

# HTTP Caching for REST APIs

---

### 🎯 Model Answer

**30 seconds:**
> HTTP caching allows REST API responses to be stored and reused without making a new server request. The two mechanisms are: freshness (Cache-Control headers telling caches how long to store the response) and validation (ETags/Last-Modified headers allowing conditional requests that return 304 Not Modified when the resource hasn't changed). Caching dramatically reduces server load and improves client latency.

**3 minutes:**
> HTTP caching operates at multiple layers: the browser cache, CDN edge nodes, and reverse proxies. Each layer can cache responses and serve them without hitting the origin API server. The Cache-Control header is the primary caching directive. `Cache-Control: max-age=300` tells caches to store the response for 5 minutes and serve it without revalidating. `Cache-Control: no-cache` tells caches to always revalidate with the server before serving (the server can return 304 Not Modified with no body, which is still faster than the full response). `Cache-Control: no-store` means never cache - for sensitive data. `Cache-Control: private` means only the browser can cache - not CDNs or shared proxies. `Cache-Control: public` means any cache can store this. The validation mechanism uses ETags (fingerprints) and Last-Modified timestamps. The server sends `ETag: "v3-abc123"` with the response. The browser stores it. On the next request, the browser sends `If-None-Match: "v3-abc123"`. The server checks if the ETag still matches: same = 304 Not Modified (empty body, saves bandwidth). Different = 200 OK with new ETag and full body. The 304 response is fast because: the server still executes the request handler but can return early without serializing the response body. For REST APIs: GET and HEAD responses are cacheable by default. POST, PUT, DELETE are not cacheable. Cache-Control headers on POST responses can enable caching but are rarely used.

**Blank Mind Recovery:**
**(1) Restate:** "HTTP caching - storing API responses to avoid repeated server calls."
**(2) First principles:** "If the data hasn't changed, why fetch it again? Cache until it might change (max-age) or check if it changed (ETags)."
**(3) Bridge:** "Like a library checkout system. Fresh books (max-age) don't need to be returned for a while. Conditional checkout (ETag) - bring back the old book, if there's a new edition you'll get it, otherwise take back your old one."

---

### 📘 Concept Explanation

**What it is:**
HTTP caching is a mechanism for storing API responses at various layers of the network stack (browser, CDN, proxy) and serving them from cache without making new origin server requests when the cached response is still valid.

**The problem it solves:**
Without caching, every client request hits the origin server. For read-heavy APIs (product catalog, user profile, configuration), the same data is fetched thousands of times per second. Caching reduces origin server load (fewer requests), improves client latency (response from CDN edge is faster than from origin), and reduces bandwidth costs.

**How it works:**
```
HTTP Caching Layers:

Browser -> CDN Edge -> Reverse Proxy -> Origin

First request (no cache):
Browser -> CDN -> Origin -> 200 OK with:
  Cache-Control: public, max-age=300
  ETag: "abc123"
CDN stores response. Browser stores response.

Second request (within 5 minutes):
Browser serves from local cache. CDN never hit.

After 5 minutes (max-age expired):
Browser -> CDN -> (CDN has fresh cache)
CDN serves from cache. Origin never hit.

After CDN cache expires:
Browser -> CDN -> Origin (with ETag)
  If-None-Match: "abc123"
Origin checks: unchanged = 304 No Content
CDN updates TTL. Browser updates cache.

If resource changed:
Origin returns 200 with new ETag: "def456"
CDN and browser update their caches.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
`no-cache` does NOT mean "don't cache." It means "cache but always revalidate before serving." `no-store` means "don't cache." This naming confusion causes many misconfigured APIs. `no-cache` is actually useful for authenticated resources where you want cache efficiency (304 No Modified saves bandwidth) but always want the server to confirm currency.

**When to use it:**
Public read-only resources with low change frequency: product catalog, static config, user profiles (with appropriate max-age). High-traffic read endpoints where CDN offloading is critical.

**When NOT to use it:**
Authenticated per-user data should use `Cache-Control: private`. Sensitive data (account balance, personal information) should use `no-store`. Endpoints with real-time requirements (stock prices, live inventory) need low max-age or no-cache.

**Alternatives:**
- Application-level cache (Redis, Memcached): cache in your application code, not HTTP layer. More control but requires cache invalidation logic.
- CDN cache rules: configure caching at the CDN without Cache-Control headers. Less explicit, harder to reason about.

**First-principles derivation:**
Caching is valuable when: the cost of fetching is higher than the cost of checking if the cached version is still valid, AND the data doesn't change between every request. HTTP caching was designed into the protocol from the beginning because the web's scalability depends on caching. REST reuses HTTP's caching model, which is why stateless design (same URL = same representation) is important - stateful responses can't be cached.

---

### 💻 Code Example

```java
// Spring Boot HTTP caching implementation

@RestController
@RequestMapping("/products")
public class ProductController {

  private final ProductService productService;

  // Cache-Control for public read resource
  @GetMapping("/{id}")
  public ResponseEntity<Product> getProduct(
      @PathVariable Long id,
      @RequestHeader(
          value = "If-None-Match",
          required = false) String ifNoneMatch) {

    Product product = productService.findById(id);

    // Generate ETag from content hash or version
    String etag = "\"" + product.getVersion() + "\"";

    // Conditional request: resource unchanged
    if (etag.equals(ifNoneMatch)) {
      return ResponseEntity.status(
              HttpStatus.NOT_MODIFIED)
          .eTag(etag)
          .build();
    }

    return ResponseEntity.ok()
        // Public cache, 5-minute freshness
        .cacheControl(
            CacheControl.maxAge(5, TimeUnit.MINUTES)
                .cachePublic())
        .eTag(etag)
        .body(product);
  }

  // No caching for user-specific sensitive data
  @GetMapping("/{id}/pricing")
  public ResponseEntity<Pricing> getPricing(
      @PathVariable Long id,
      @AuthenticationPrincipal UserPrincipal user) {

    Pricing pricing = productService
        .getUserPricing(id, user.getId());

    return ResponseEntity.ok()
        // Private: only browser, not CDN
        .cacheControl(
            CacheControl.maxAge(1, TimeUnit.MINUTES)
                .cachePrivate())
        .body(pricing);
  }

  // No caching for real-time inventory
  @GetMapping("/{id}/inventory")
  public ResponseEntity<Inventory> getInventory(
      @PathVariable Long id) {

    Inventory inv = productService.getInventory(id);

    return ResponseEntity.ok()
        .cacheControl(CacheControl.noStore())
        .body(inv);
  }
}
```

> **Code walkthrough:** Three caching strategies for three scenarios: (1) Product details - public max-age=300 with ETag validation. Any CDN or browser can cache for 5 minutes. ETag enables 304 responses when unchanged (saves bandwidth even after max-age expires). (2) User-specific pricing - private max-age=60. Only the browser can cache. CDN must not cache per-user pricing. (3) Real-time inventory - no-store. Never cached anywhere. Always fetches fresh data from the server.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "HTTP caching reduces server load by storing responses. The Cache-Control header controls how long responses are cached: `max-age=300` for 5 minutes. ETags are fingerprints for conditional requests - the client sends the ETag on the next request and gets a 304 Not Modified if nothing changed. I use `Cache-Control: public` for public data that any CDN can cache, and `Cache-Control: private` for user-specific data that only the browser should cache."

**Senior / Staff:** "HTTP caching strategy is a performance architecture decision. The CDN offload calculation: if a product page API has 10,000 req/s and 90% of requests are for the same 1,000 products cached for 5 minutes, the CDN handles 9,000 req/s. Origin sees 1,000 req/s (10x reduction). Setting correct Cache-Control is critical: public resources mistakenly set to no-cache lose all CDN offload. Private resources mistakenly set to public would expose one user's data to another user's browser cache on a shared computer. The validation design: ETags from content hash are compute-intensive to generate (hash the JSON response). ETags from version numbers are cheap (increment on write). Version numbers are the practical choice for most resources. Cache invalidation strategy: if you can tolerate eventual consistency (product images, catalog data): max-age. If you need immediate propagation (inventory, pricing changes): ETags with no-cache. For cache busting: CDN cache tag invalidation (tag all product-123 responses, invalidate by tag on product update) - available in CloudFront, Fastly, and Cloudflare."

---

### ⚠️ Common Misconceptions

**Misconception:** "Cache-Control: no-cache means the response is never cached."
Reality: `Cache-Control: no-cache` means the response CAN be stored in cache but MUST be revalidated with the server before serving. The cached response is only used if the server confirms it's still valid (via 304 Not Modified). This is actually quite useful: the browser stores the response and the ETag. On the next request, the browser sends `If-None-Match` and the server returns 304 (empty body) if unchanged. This saves the full response bandwidth while ensuring freshness. To PREVENT caching entirely: use `Cache-Control: no-store`. The complete breakdown: `max-age=0` - store but immediately stale, revalidate every time. `no-cache` - store but revalidate every time (same as max-age=0 in practice). `no-store` - don't store at all. `must-revalidate` - if stale, must revalidate before serving (even if network is unavailable; return 504 rather than serve stale). These distinctions matter when configuring CDNs.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Users seeing stale data after an update**

Symptoms: Users update their profile photo. The new photo doesn't appear immediately. After refreshing multiple times over 5 minutes, the new photo appears. Some users on different browsers or devices see the new photo immediately, others don't.

Root cause: The profile photo URL is cached in the CDN with a 5-minute max-age. After the update, the CDN serves the old photo until the cache TTL expires. Different users see different data based on when their CDN edge node's cache expires.

Diagnosis: Check the response headers for the profile photo endpoint: `curl -I /users/123/photo`. Look at `Cache-Control`, `Age` (how old the cached response is), and `X-Cache` (hit or miss).

Fix: Multiple options: (1) CDN cache invalidation on update: when a user updates their photo, call the CDN's invalidation API to immediately purge the cached response for that user's photo URL. (2) URL busting: append a version or hash to the photo URL: `/users/123/photo?v=abc123`. The new URL after update is always uncached. (3) Use no-store for frequently updated user content. (4) Reduce max-age to a lower value (30 seconds instead of 5 minutes). The trade-off: lower max-age = more origin requests = higher server load.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Mechanism | 3 min | 2 |
| Comparison | 2 min | 1 |
| Design | 3 min | 2 |
| Debugging | 3 min | 1 |
| Trade-off | 2 min | 1 |
| Security | 2 min | 1 |

#### Q1 - "Explain the difference between Cache-Control max-age, no-cache, and no-store."
> "Three distinct caching behaviors: `max-age=N`: store the response for N seconds. Serve from cache without contacting the server for N seconds. After N seconds: revalidate (send If-None-Match, may get 304). `no-cache`: store the response but NEVER serve without revalidation. Every time the client needs this resource: contact the server. Server returns 304 (empty body) if unchanged, 200 with new data if changed. No-cache still saves bandwidth (304 has no body) but adds a round trip. `no-store`: never store the response anywhere. Every request hits the origin. No browser cache, no CDN cache, no proxy cache. The practical use cases: `max-age=300`: product catalog, help articles, configuration data. Changes infrequently, 5-minute stale is acceptable. `no-cache`: user profile data. Always verify with the server (304 if unchanged). Never serve stale profile data. But save bandwidth when unchanged. `no-store`: financial statements, account balance, sensitive personal data. Never cache anywhere - not even in browser temp files. Combinations: `Cache-Control: no-cache, no-store, must-revalidate` is belt-and-suspenders for maximally sensitive data. `Cache-Control: public, max-age=86400` for static public resources (images, CSS, JS)."

*What separates good from great:* "The clarification that no-cache 'stores but revalidates every time' while no-store 'never stores' is the precise HTTP spec distinction. Most candidates confuse these, and the confusion leads to misconfigured APIs either serving stale sensitive data or missing CDN offload benefits."

---

#### Q2 - "How do ETags work and when are they better than max-age?"
> "ETags are entity tags - fingerprints of a response's content. Server generates an ETag from the response body (content hash) or a version number. Server sends `ETag: \"v3-abc123\"` with every cacheable response. Browser stores the ETag. On next request: `If-None-Match: \"v3-abc123\"`. Server compares current ETag: same = 304 Not Modified (no body). Changed = 200 OK with new ETag. ETags are better than max-age for: resources that change infrequently but unpredictably. With max-age, you must choose a TTL: too short = unnecessary server requests. Too long = clients see stale data. ETags solve both: the browser revalidates every time (no guessing the TTL), but if unchanged, the 304 has no body (bandwidth savings). The combination: use both. `Cache-Control: public, max-age=300` + `ETag: "abc"`. For 5 minutes: serve from cache without revalidating. After 5 minutes: send If-None-Match. If unchanged: 304 and reset 5-minute window. The 304 path: generates the ETag, compares it, returns empty body. Much cheaper than full serialization. Especially valuable for large response bodies (paginated lists, report data). 304 for a 2MB response is essentially free."

*What separates good from great:* "The 'use both' recommendation (max-age + ETag) and the explanation of how they combine (serve from cache within max-age, revalidate with ETag after max-age expires) shows you understand the complete caching strategy, not just individual headers."

---

#### Q3 - "Design a caching strategy for a product catalog API that updates frequently."
> "Product catalog with frequent updates: the challenge is balancing freshness (users see current prices/stock) with performance (CDN offload). Data characteristics: product names/descriptions: change rarely (hours/days). Product prices: change frequently (minutes/hours for flash sales). Stock levels: change constantly (seconds for popular items). Caching strategy by data type: Product details (name, description, images): `Cache-Control: public, max-age=3600` + ETag. CDN caches for 1 hour. Use CDN cache tags to invalidate when a product is edited (tag each response with the product ID, invalidate by tag on update). Product pricing: `Cache-Control: private, max-age=60` - only browser cache, 60 seconds. Or `no-cache` with ETag for always-current pricing. Stock levels: `Cache-Control: no-store` - real-time inventory must not be cached. Practical implementation: separate endpoint `/products/{id}` (cacheable product info) from `/products/{id}/inventory` (non-cacheable stock). Client fetches both; renders from cached product info + fresh inventory data. CDN cache invalidation on write: when a product is updated, publish a `ProductUpdated` event. A consumer calls the CDN API to invalidate all cached responses tagged with `product-{id}`."

*What separates good from great:* "Splitting the product endpoint (cacheable) from the inventory endpoint (non-cacheable) and the CDN cache tag invalidation pattern (invalidate by product ID tag on update) are the production caching design decisions."

---

#### Q4 - "A CDN is serving stale API responses after you deployed new data. How do you fix it immediately?"
> "Immediate fix for stale CDN cache: CDN purge/invalidation API. Most CDNs support programmatic cache invalidation. CloudFront: `create-invalidation --distribution-id --paths '/*'` or specific paths. Cloudflare: `POST /zones/{zone_id}/purge_cache` with specific URLs or cache tags. Fastly: PURGE request to the specific URL. Immediate: `curl -X PURGE https://api.mysite.com/products/123`. This is the emergency break-glass option - use for urgent corrections (wrong price, recalled product). Medium-term fix: implement CDN cache tag invalidation as part of your write path. When a product is updated: (1) write to DB, (2) publish ProductUpdated event, (3) event handler calls CDN purge API for `product-{id}` cache tag. This automated invalidation runs within seconds of the write. Long-term fix: review max-age values. If stale data causes incidents, max-age may be too high. Reduce it at the cost of more origin requests. Prevention: use cache-busted URLs for resources that change (content hash in URL: `/products/abc123`). When the content changes, the URL changes (new hash). No invalidation needed - the old URL is now dead, clients get new URL from API responses."

*What separates good from great:* "Knowing the specific CDN purge API commands (CloudFront create-invalidation, Cloudflare POST /purge_cache, Fastly PURGE) shows you've done CDN cache invalidation in production, not just read about it."

---

#### Q5 - "How does caching affect REST API security?"
> "Three caching security concerns: (1) Private data in shared caches. User-specific data (profile, account) cached in a CDN is served to all users requesting the same URL. Ensure `Cache-Control: private` on all user-specific responses. A common mistake: forgetting to set private on a newly added personalization feature. The CDN caches the first user's personalized response and serves it to everyone. (2) Security headers must also be cached correctly. `Strict-Transport-Security` (HSTS) must reach the browser. If a CDN strips HSTS headers: first visit may not enforce HTTPS. Set `Cache-Control: no-store` for security-sensitive responses, or configure the CDN to pass through security headers. (3) Cache poisoning attacks. If the CDN uses a URL as the cache key and an attacker can influence the URL (Host header injection, URL manipulation): attacker serves malicious cached responses to legitimate users. Mitigation: normalize cache keys at the CDN. Validate the Host header at the origin. Never use unvalidated user input in cache keys. The `Vary` header creates additional cache dimensions: `Vary: Accept-Language` means the CDN caches separate responses per language. An attacker who can control the Accept-Language header can fill CDN cache with invalid entries (cache DOS)."

*What separates good from great:* "The cache poisoning attack vector (controlling cache keys to serve malicious cached responses) and the Vary header cache DOS are sophisticated security considerations that show you've thought through the complete caching threat model."

---

#### Q6 - "How does HTTP caching interact with REST API versioning?"
> "API versioning and caching interact at the cache key. For URI versioning (`/v1/users` vs `/v2/users`): different URLs = different cache keys. CDN caches v1 and v2 separately. Safe: updating v2 doesn't affect v1 cache. For header versioning (Accept: application/vnd.myapp.v2+json): same URL, different version in header. CDN caches by URL only by default. The cache key problem: CDN may serve v1 response to a v2 request (or vice versa). Fix: add `Vary: Accept` to responses so the CDN includes the Accept header in the cache key. Performance cost: Vary: Accept reduces cache hit rate (separate entries per Accept value). Most CDNs handle Vary headers, but efficiency decreases. The correct approach: prefer URI versioning for CDN-fronted APIs. URI versioning is cache-friendly by design. Header versioning requires explicit CDN Vary configuration and reduces cache efficiency. When sunsetting old versions: purge the old version's CDN cache after sunset. Old URLs still cached in CDN will return stale 'version not supported' responses until the CDN entries expire."

*What separates good from great:* "The Vary: Accept requirement for header versioned APIs and the cache efficiency reduction are the production CDN concerns that connect API versioning and HTTP caching in a way most candidates don't connect."

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


# Rate Limiting and Throttling Design

---

### 🎯 Model Answer

**30 seconds:**
> Rate limiting restricts how many requests a client can make in a time window to protect the API from abuse and overload. Common algorithms are token bucket (allows bursting), leaky bucket (smooth constant rate), and fixed window counters (simple but subject to boundary spikes). Rate limiting headers (X-RateLimit-Remaining, Retry-After) communicate current quota to clients.

**3 minutes:**
> Rate limiting serves two purposes: preventing abuse (a client flooding the API with requests, either maliciously or by bug) and ensuring fairness (one client can't consume all capacity at the expense of others). The token bucket algorithm is the most practical: each client has a bucket that fills with tokens at a constant rate (100 tokens/minute). Each request consumes one token. When the bucket is empty: reject with 429 Too Many Requests. Clients can burst (use saved tokens quickly) up to bucket capacity, but the sustained rate is bounded. The fixed window approach: count requests in a 60-second window. Simple to implement but subject to boundary attacks: a client can make 100 requests in the last second of one window and 100 in the first second of the next - 200 requests in 2 seconds without being rate limited. Sliding window solves this by tracking request timestamps: `count of requests in the last 60 seconds` (not since the last minute mark). More accurate but requires storing per-request timestamps. Implementation: use Redis for the rate limit state (atomic increment commands, fast, TTL for window expiry). GCRA (Generic Cell Rate Algorithm) is the algorithm used by Stripe and many others: represents the rate limit as a virtual queue. One Redis command per request. At the API level: rate limit by API key for server-to-server clients. Rate limit by JWT subject for user-facing APIs. Rate limit by IP for unauthenticated access. Multiple tiers: free tier (100 req/min), paid tier (1000 req/min), partner tier (unlimited with fair use).

**Blank Mind Recovery:**
**(1) Restate:** "Rate limiting - restricting how many API calls a client can make."
**(2) First principles:** "If one client can send unlimited requests, they can take down the service. Rate limiting caps each client's share."
**(3) Bridge:** "Like a water tap with a pressure regulator. The tap (API) can handle N liters/second total. Each user gets a fair share. One user can't flood the system."

---

### 📘 Concept Explanation

**What it is:**
Rate limiting (throttling) is the enforcement of a maximum number of API requests a client can make within a time window. It protects the API from intentional abuse, accidental bugs, and ensures equitable access across all clients.

**The problem it solves:**
Without rate limiting: a buggy client in an infinite retry loop sends 10,000 requests per second, taking down the API. A malicious client probes endpoints or scrapes data. A viral moment causes 100x traffic spike beyond capacity. Rate limiting bounds the blast radius of any single client.

**How it works:**
```
Token Bucket Algorithm:

Each client: tokens = min(capacity, tokens +
                          rate * elapsed_time)

On request:
  if tokens >= 1:
    tokens -= 1
    process request
  else:
    reject with 429 Too Many Requests

Capacity: 100 tokens (burst allowance)
Rate: 10 tokens/second (sustained rate)

Client can burst 100 requests immediately.
Then sustained at 10/second.

Redis implementation (GCRA):
  SET key:timestamp = now + delay
  if timestamp > now: reject (too fast)
  else: allow, update timestamp

Rate limit headers in response:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 42
  X-RateLimit-Reset: 1716912000 (unix timestamp)
  
  On 429:
  Retry-After: 30  (seconds to wait)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
Rate limiting enforced BEFORE heavy processing (at the API gateway level) is vastly more effective than rate limiting inside the application. If the application must process a request to check the rate limit, the expensive work is already done. Gateway-level rate limiting (checked with a Redis lookup before the request reaches application code) protects the application from even executing the handler.

**When to use it:**
Every public API needs rate limiting. Internal service-to-service APIs should also have rate limiting to prevent cascading failures from misbehaving clients.

**When NOT to use it:**
Internal health-check endpoints shouldn't be rate limited (they defeat the purpose of health checks). Internal readiness probes from Kubernetes should not be rate limited.

**Alternatives:**
- Circuit breaker (Resilience4j): protects the caller from a failing downstream. Rate limiting protects the server from excessive clients. Complementary, not alternatives.
- API gateway quotas: product-level quotas distinct from per-request rate limits (monthly API call quota vs per-minute burst limit).

**First-principles derivation:**
Any shared resource with finite capacity needs access control. Rate limiting is the shared-resource allocation mechanism for APIs. The algorithm choice determines the traffic shaping behavior: token bucket shapes traffic by allowing bursts (real-world clients have bursty access patterns). Leaky bucket enforces a constant rate (useful for downstream systems that can't handle bursts).

---

### 💻 Code Example

```java
// Spring Boot rate limiting with Bucket4j + Redis

@Component
public class RateLimitingFilter
    extends OncePerRequestFilter {

  private final RateLimiterService rateLimiter;

  @Override
  protected void doFilterInternal(
      HttpServletRequest request,
      HttpServletResponse response,
      FilterChain chain)
      throws ServletException, IOException {

    String clientId = extractClientId(request);
    RateLimitResult result =
        rateLimiter.tryConsume(clientId);

    // Always add rate limit headers
    response.setHeader("X-RateLimit-Limit",
        String.valueOf(result.getLimit()));
    response.setHeader("X-RateLimit-Remaining",
        String.valueOf(result.getRemaining()));
    response.setHeader("X-RateLimit-Reset",
        String.valueOf(result.getResetAt()));

    if (!result.isAllowed()) {
      response.setStatus(429);
      response.setHeader("Retry-After",
          String.valueOf(
              result.getRetryAfterSeconds()));
      response.setContentType(
          "application/problem+json");
      response.getWriter().write(
          "{\"type\":\"/errors/rate-limited\","
          + "\"title\":\"Too Many Requests\","
          + "\"status\":429,"
          + "\"detail\":\"Rate limit exceeded. "
          + "Retry after "
          + result.getRetryAfterSeconds()
          + " seconds.\"}");
      return;
    }

    chain.doFilter(request, response);
  }

  private String extractClientId(
      HttpServletRequest request) {
    // Prefer API key over JWT over IP
    String apiKey = request.getHeader(
        "X-API-Key");
    if (apiKey != null) return "key:" + apiKey;

    String auth = request.getHeader(
        "Authorization");
    if (auth != null && auth.startsWith(
        "Bearer ")) {
      return "user:" + jwtService.extractSub(
          auth.substring(7));
    }

    // Fallback: rate limit by IP
    return "ip:" + getClientIp(request);
  }
}
```

> **Code walkthrough:** The filter adds rate limit headers (X-RateLimit-Limit, Remaining, Reset) to EVERY response - not just 429 responses. This allows clients to monitor their quota and slow down proactively before hitting the limit. The clientId extraction prefers API key > JWT subject > IP (in that order). An API key ties the rate limit to the application. A JWT subject ties it to the user. IP-based rate limiting is the fallback for unauthenticated requests but is less accurate behind NAT. The 429 response uses Problem Details format with a Retry-After header.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Rate limiting prevents clients from making too many requests. When a client exceeds the limit, the API returns 429 Too Many Requests. I use Redis to track request counts per client. The client knows their limit from X-RateLimit-Remaining headers and knows how long to wait from Retry-After. Rate limiting is usually implemented in a filter before the business logic runs."

**Senior / Staff:** "Rate limiting has multiple design dimensions: algorithm (token bucket for bursty workloads, fixed window for simple, sliding window for precise), scope (per-API-key, per-user, per-endpoint, per-IP), tier (free vs paid vs partner quotas), and enforcement point (API gateway vs application filter). The production consideration I always make explicit: rate limiting must be concurrency-safe. `GET count, count+1, SET count+1` is a race condition. Two concurrent requests both read count=99, both increment to 100, both set - the actual count is 100 but two requests were allowed at the limit boundary. Use atomic Redis commands: `INCR` (atomic increment) or Lua scripts for multi-step operations. Redis cluster: rate limit keys are single-node operations. If the key hashes to a different shard, the shard-based counters are independent. For distributed rate limiting across a Redis cluster: use RedisTimeSeries or a rate limiting library (Bucket4j, Resilience4j) that handles distribution. At staff level: rate limiting strategy balances two failure modes. Too strict: legitimate clients get throttled, business impact. Too loose: the API goes down from overload, ALL clients are affected. The calibration: measure P99 client behavior in production, set limits at 5-10x normal maximum to allow for spikes while blocking runaway clients."

---

### ⚠️ Common Misconceptions

**Misconception:** "Rate limiting by IP address is reliable for preventing abuse."
Reality: IP-based rate limiting fails in multiple scenarios. Corporate users: thousands of employees behind a single corporate NAT IP. All of them share one IP, so the entire company hits the rate limit if one employee makes excessive requests. IPv6: clients may change IPv6 addresses frequently. Mobile users: IP changes with each network switch (WiFi to cellular). Rate limiting by IP is useful ONLY as a fallback for unauthenticated access where no better identifier is available. For authenticated APIs: rate limit by API key or JWT subject. For multi-tenant APIs: rate limit by tenant/account. The composite identifier approach: rate limit by `{account-id}:{endpoint}` - the account has an overall limit, but also per-endpoint limits to prevent one endpoint from consuming the entire account quota. The IP-based limit is layered on top as DDoS protection (a specific IP hammering the API at network level) but not as the primary access control mechanism.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Rate limiting is not working - a client is sending 10,000 req/s despite 100 req/min limit**

Symptoms: An API key is making requests far above its configured limit. The rate limit counter in Redis shows the correct count but requests are still succeeding. 429 responses are not being returned.

Root cause: The rate limiting filter is configured with `@Order(100)` but the authentication filter is at `@Order(1)`. Requests that fail authentication (401) never reach the rate limiting filter. But requests that SUCCEED authentication reach the rate limiting filter - however, a bypass path (a different servlet path matching) is not hitting the filter chain at all.

Diagnosis: Check if the rogue requests are hitting a specific endpoint. `grep 'api-key-abc' /var/log/api-access.log | awk '{print $7}' | sort | uniq` - which endpoints are the requests hitting? If they're hitting a path not covered by the filter's URL pattern, the filter isn't applied. Check the filter's `urlPattern` configuration.

Fix: Ensure the rate limiting filter covers ALL paths. Use `/**` pattern. Check that the filter is applied at the correct order in the filter chain. For Spring Security: register the rate limiting filter before `SecurityContextPersistenceFilter` or at the beginning of the chain.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Comparison | 3 min | 2 |
| Mechanism | 3 min | 1 |
| Design | 3 min | 2 |
| Debugging | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Behavioral | 2 min | 1 |

#### Q1 - "Compare token bucket, leaky bucket, and fixed window algorithms."
> "Fixed window: count requests in the current time window (e.g., the current minute). Simple Redis INCR with TTL. The problem: the boundary. At 11:59:59 a client sends 100 requests (fills the window). At 12:00:01 a new window starts, they send 100 more. 200 requests in 2 seconds. The window boundary allows bursting at 2x the rate limit. Sliding window: track exact request timestamps. Count requests in the last 60 seconds (not since the last minute mark). More accurate, no boundary vulnerability. Cost: must store timestamps for all requests in the window. Expensive for high request rates. Token bucket: a virtual bucket fills with tokens at a fixed rate (10/second). Each request consumes one token. Empty bucket = reject. Full bucket = can burst. The bucket has a maximum capacity (the burst limit). Burst until full, then sustained at fill rate. Practical for real-world clients who have bursty patterns. Leaky bucket: requests flow in at any rate but flow out at a fixed constant rate. Excess requests queue or are dropped. Enforces a strictly constant outflow rate. Better for backends that need smooth constant load (downstream services). The recommendation: token bucket for client-facing APIs (allows bursting, fair to legitimate clients). Leaky bucket for protecting downstream systems (smooth constant rate)."

*What separates good from great:* "The boundary attack (200 requests in 2 seconds with fixed window) and the use case distinction (token bucket for client-facing, leaky bucket for downstream protection) shows understanding of both the algorithms' weaknesses and their appropriate use cases."

---

#### Q2 - "How do you implement distributed rate limiting across multiple API server instances?"
> "Centralized counter: Redis is the standard distributed rate limiting store. All API server instances share a Redis rate limit store. Atomic Redis operations: `INCR` for fixed window (INCR returns new count; compare to limit; if over limit, reject). `SETEX` to set the TTL for the window. Bucket4j or Resilience4j with Redis backend: libraries handle the distributed case with Lua scripts ensuring atomic check-and-increment. The Redis Lua script approach: `local count = redis.call('INCR', key); if count == 1 then redis.call('EXPIRE', key, 60) end; if count > limit then return 0 else return 1 end`. Runs atomically (no race conditions). The failure mode: Redis goes down. Options: fail open (allow all requests, no rate limiting - service could be overwhelmed), fail closed (reject all requests - service unavailable), or use a local in-memory fallback counter (approximate rate limiting without cross-instance coordination). My recommendation: fail open but alert. When Redis is down, accept requests at a reduced local rate limit (per-instance local counter) to maintain service while alerting on the degraded rate limiting. This balances availability against protection. For Redis HA: use Redis Sentinel or Redis Cluster. Rate limiting keys are small and numerous - this is a good Redis Cluster use case."

*What separates good from great:* "The Redis Lua script for atomic check-and-increment and the fail-open/fail-closed decision (with the recommendation to fail open with local fallback) shows production distributed rate limiting implementation experience."

---

#### Q3 - "How do you design rate limit tiers for different client types?"
> "Multi-tier rate limiting: different limits for different client classifications. Tiers: unauthenticated (IP-based): 10 req/min. Safeguard against scraping, DDoS. Free API key: 100 req/min, 10K req/day. Basic registered clients. Paid API key: 1,000 req/min, 1M req/day. Paying customers. Partner API key: 10,000 req/min, unlimited daily. Contract-based partners. Internal services: unlimited (or very high, for DoS protection from bugs). The tier is stored in the API key record (or JWT claim). On each request: look up the tier, apply the corresponding bucket configuration. Implementation: `Tier tier = apiKeyService.getTier(apiKey); BucketConfiguration config = tierConfig.get(tier); Bucket bucket = buckets.computeIfAbsent(apiKey, k -> Bucket4j.builder().addLimit(config).build());`. The key design: per-endpoint limits in addition to global limits. A data export endpoint (heavy) might have 10 req/hour even for paid tier. A simple read endpoint might have 10,000 req/min. Per-endpoint limits prevent one heavyweight endpoint from consuming the entire quota. Return tier information in headers: `X-RateLimit-Tier: paid`, `X-RateLimit-Limit: 1000`. Clients know their tier and plan accordingly."

*What separates good from great:* "Per-endpoint limits in addition to global tier limits (export endpoints get very low limits regardless of tier) is the production design that prevents resource exhaustion from heavy operations."

---

#### Q4 - "A client reports they're being rate limited despite sending very few requests. What do you investigate?"
> "False positive rate limiting investigation: (1) Shared client ID: the client is behind a shared API key or IP being used by many other processes. The rate limit counter is for the API key, not just their process. Check if the API key is shared by multiple services or environments (staging and production sharing a key). (2) Clock synchronization: the rate limit window reset time is based on server clock. If the client's retry logic is based on client clock (Retry-After), and client and server clocks are skewed, the client may retry before the server has reset the window. Check if the 429 Retry-After value matches the actual reset time. (3) Header not being read: the client's rate limit code may not be reading X-RateLimit-Remaining. They're unaware they're approaching the limit and send a burst of requests. (4) Request fan-out: one 'logical request' in the client triggers multiple API calls (the UI component loads user + preferences + notifications simultaneously). The client thinks they made 1 request; the server counted 3. Check if there are multiple concurrent requests per user action. (5) Rate limit key collision: if rate limit keys are generated from a hash of the API key and the hash has collisions - two different keys map to the same rate limit bucket. Check the key generation logic."

*What separates good from great:* "The request fan-out scenario (one UI action triggers multiple API calls) is the production debugging insight. Clients who think in 'user actions' but APIs that count individual HTTP requests have a constant mismatch in how 'usage' is perceived."

---

#### Q5 - "How should clients implement retry logic for rate-limited requests?"
> "Client-side rate limit handling: (1) Read X-RateLimit-Remaining on every response (not just 429). When remaining < 10%: voluntarily add delay before next request. Proactive throttling prevents hitting the limit. (2) On 429: stop immediately. Do NOT retry immediately (this is the mistake: receive 429, immediately retry, get 429, immediately retry - hammering the server). (3) Read Retry-After header: `Retry-After: 30` means wait 30 seconds. Honor this value exactly. (4) After waiting: resume at a reduced rate. If you were sending 100 req/s when you hit the limit, resume at 50 req/s. The server told you 100/s was too fast. (5) Exponential backoff for repeated 429s: if you hit the limit again after waiting: wait 30s, then 60s, then 120s. Don't lock at 30s. (6) Circuit breaker for rate limiting: if 50% of requests in the last 30 seconds were 429, open the circuit and wait 60 seconds before trying again. The anti-pattern: `while (429) { Thread.sleep(1000); retry(); }`. This creates retry storms if many clients synchronize on the same Retry-After reset time. Add jitter: `Thread.sleep(retryAfter * 1000 + random(500))`."

*What separates good from great:* "The jitter recommendation (adding random delay to Retry-After waits) prevents the thundering herd problem where all clients reset at the exact same time and spike the origin simultaneously."

---

#### Q6 - "How do you handle rate limiting gracefully in a mobile app?"
> "Mobile-specific rate limiting considerations: (1) Background sync: mobile apps often sync data in background. Rate limit the sync frequency in the app code before it reaches the API. Respect sync intervals (15-30 min for non-critical data). (2) Token pre-fetching: when the app starts, request rate limit status and cache it locally. Use remaining budget information to schedule subsequent requests. (3) Offline-first: design the app to function offline. Sync when connected. This naturally reduces request frequency. Rate limit of 100/min is trivial for an offline-first app. (4) Push notifications over polling: instead of polling 'are there new messages?' every 30 seconds: receive a push notification when a new message arrives. One FCM/APNs push is free. Thousands of API polls per hour is expensive and rate-limited. (5) Batch requests where possible: instead of 10 separate GET /product/{id} calls: one GET /products?ids=1,2,3,4,5,6,7,8,9,10. Reduces request count by 10x. (6) Exponential backoff library: use existing battle-tested libraries (Android's `java.net.HttpURLConnection` has retry support, iOS `URLSession` with `URLSessionConfiguration.timeoutIntervalForRequest`). Don't roll your own retry logic - it's complex to get right."

*What separates good from great:* "Push notifications over polling as a rate limit reduction strategy is the architectural solution that eliminates the polling problem rather than just managing it. Batch requests as a 10x request reduction is a practical API design optimization."

---

### ⚖️ Comparison Table

| Algorithm | Burst Handling | Boundary Safety | Implementation | Best For |
|---|---|---|---|---|
| Fixed Window | Allows 2x burst at boundary | Vulnerable | Simple (Redis INCR) | Simple quota enforcement |
| Sliding Window | No burst | Safe | Complex (timestamp list) | Precise rate enforcement |
| Token Bucket | Yes (configurable burst) | Safe | Moderate (Bucket4j) | Client-facing APIs |
| Leaky Bucket | No (constant drain) | Safe | Moderate | Protecting downstream |
| GCRA | Minimal burst | Safe | One Redis op | High-performance |

**The deciding factor:** Use token bucket for client-facing APIs (bursting is natural client behavior). Use GCRA for high-throughput services (one Redis operation per request). Use fixed window for simple quota enforcement where boundary spike risk is acceptable.

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



