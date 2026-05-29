---
layout: default
title: "System Design - L2 Core Patterns"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 3
permalink: /system-design/l2-core-patterns/
---

# System Design - L2 Core Patterns

---

# Load Balancing

---
id: SSD-007
title: Load Balancing
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #load-balancing, #L4, #L7, #algorithms, #health-checks
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> A load balancer distributes incoming requests across multiple servers. L4
> load balancers operate at the TCP/IP level (fast, no content inspection).
> L7 load balancers operate at the HTTP level (can route by URL, header, cookie).
> Common algorithms: round-robin (equal distribution), least connections (route
> to least busy), weighted (prefer faster servers), consistent hashing (same
> key -> same server for session affinity). Health checks remove failed servers
> from the pool automatically.

**3 minutes:**
> Load balancers solve three problems: distribution (spread load evenly),
> availability (route around failures), and scalability (add/remove servers
> without downtime).
>
> L4 vs L7: L4 is a TCP proxy - it sees source IP, destination port, but not
> HTTP content. Very fast (no parsing). Used for: raw TCP services, database
> proxies, simple HTTP where content doesn't matter. L7 is an HTTP proxy -
> it reads the request URL, headers, cookies. Slower (must parse HTTP), but
> enables: URL-based routing (/api -> API cluster, /static -> static file cluster),
> A/B testing, canary deployments, request rewriting.
>
> Load balancer HA: the LB itself must not be a single point of failure.
> Active-passive pair with floating IP (keepalived), or cloud-managed LB
> (AWS ALB auto-scales and is multi-AZ). DNS load balancing (multiple A records)
> provides geographic distribution but not per-request load distribution.

**Blank Mind Recovery:**

**(1) Restate:** "Load balancing means distributing incoming requests across
multiple servers instead of sending all traffic to one."

**(2) First principles:** "If one server can handle 1000 requests/second, and
you have 10 servers: you can handle 10,000 requests/second IF you distribute
requests evenly. The load balancer does the distribution."

**(3) Three decisions:** which algorithm (round-robin for equal, least-connections
for variable request time), which layer (L4 for speed, L7 for smart routing),
how to make the LB itself highly available.

---

### 📘 Concept Explanation

**Load balancing algorithms:**

```
Round Robin:
  Server list: [A, B, C]
  Requests: 1->A, 2->B, 3->C, 4->A, 5->B...
  Good: simple, even distribution when requests are similar duration
  Bad: if requests have very different durations, some servers get
       more "work" even with equal request counts

Weighted Round Robin:
  Server A (8 CPU): weight 4
  Server B (4 CPU): weight 2
  Server C (4 CPU): weight 1
  Distribution: A gets 4/7 = 57%, B gets 2/7 = 29%, C gets 1/7 = 14%
  Good: heterogeneous servers
  Bad: static weights don't reflect real-time load

Least Connections:
  Route to server with fewest active connections
  Good: variable request duration (some requests take 10ms, some 5 sec)
  Bad: requires tracking connection count per server

Least Response Time:
  Route to server with lowest combination of:
  (active connections) + (average response time)
  Good: accurately reflects server health under load
  Bad: more complex state tracking

IP Hash / Consistent Hashing:
  hash(client_IP) % N = server index
  Same client -> same server (session affinity)
  Good: stateful apps without external session store
  Bad: server removal changes all routing (use consistent hashing)
  Better: consistent hashing ring (removal affects only 1/N of traffic)

Random:
  Route to random server
  Surprisingly effective at scale (law of large numbers = even distribution)
  Power of Two Choices: pick 2 random servers, choose less loaded
  -> Better distribution than random or round-robin
```

**L4 vs L7 comparison:**

```
Layer 4 (Transport):
  Sees: source IP, destination IP, port
  Cannot see: HTTP URL, headers, cookies, body
  Operation: TCP proxy (forward raw TCP bytes)
  Speed: fastest (no parsing)
  Use cases: raw TCP, DB proxy, simple HTTP where URL doesn't matter
  Examples: AWS NLB, HAProxy in TCP mode

Layer 7 (Application):
  Sees: HTTP URL, method, headers, body, cookies
  Operation: HTTP proxy (terminate and re-initiate TCP)
  Speed: slower (must parse HTTP headers)
  Use cases: URL routing, A/B testing, canary, header injection,
             SSL termination, request/response rewriting
  Routing examples:
    /api/* -> API servers
    /static/* -> static file servers
    X-Version: 2 header -> v2 servers
    userId hash -> canary (5% to new version)
  Examples: AWS ALB, nginx, HAProxy in HTTP mode, Envoy
```

---

### 💻 Code Example

```
# Nginx L7 load balancer configuration:

upstream api_servers {
    # Round-robin by default
    server api-1:8080 weight=3;  # heavier server
    server api-2:8080 weight=1;
    server api-3:8080 weight=1;

    # Least connections algorithm:
    least_conn;

    # Health check:
    # (nginx plus) health_check interval=5s;

    keepalive 32;  # keep connections to upstream alive
}

upstream static_servers {
    server static-1:8080;
    server static-2:8080;
}

server {
    listen 443 ssl;

    # SSL termination at LB (not at app servers):
    ssl_certificate /etc/nginx/cert.pem;
    ssl_certificate_key /etc/nginx/key.pem;

    # L7 routing by URL path:
    location /api/ {
        proxy_pass http://api_servers;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }

    location /static/ {
        proxy_pass http://static_servers;
        proxy_cache_valid 200 1d;  # cache static at LB
    }

    # Canary routing (5% to v2):
    split_clients "${remote_addr}${request_uri}" $upstream {
        5%   api_servers_v2;
        *    api_servers;
    }
}
```

> **Code walkthrough:** This nginx config shows L7 load balancing in action.
> SSL is terminated at the load balancer - application servers receive plain HTTP,
> offloading crypto processing. URL-based routing sends /api/ requests to
> the API cluster and /static/ requests to static servers. The split_clients
> directive implements canary routing: 5% of traffic (hashed from IP + URI)
> goes to v2. The hash ensures the SAME user consistently gets v2 or v1 (not
> alternating), which is important for A/B test validity. keepalive 32 keeps
> persistent connections to upstream servers, reducing TCP handshake overhead.

```java
// Client-side load balancing with Spring Cloud LoadBalancer
// (alternative to server-side LB for microservices)

@Configuration
public class LoadBalancerConfig {

    @Bean
    @LoadBalancerClient(name = "order-service",
                        configuration = OrderServiceLBConfig.class)
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}

@Configuration
public class OrderServiceLBConfig {

    // Custom load balancing: round-robin with health check
    @Bean
    ReactorLoadBalancer<ServiceInstance>
            orderServiceLoadBalancer(
                Environment env,
                LoadBalancerClientFactory factory) {
        String name = env.getProperty(
            LoadBalancerClientFactory.PROPERTY_NAME);
        return new RoundRobinLoadBalancer(
            factory.getLazyProvider(name,
                ServiceInstanceListSupplier.class), name);
    }
}

// Usage: Spring Cloud resolves "order-service" to an instance
@Service
public class OrderClient {
    private final RestTemplate restTemplate;

    public Order getOrder(Long id) {
        // "order-service" -> ServiceDiscovery -> actual IP:port
        return restTemplate.getForObject(
            "http://order-service/orders/" + id,
            Order.class);
    }
}
```

> **Code walkthrough:** Client-side load balancing moves the LB logic into
> the client. The client holds an instance list (from Eureka/Kubernetes API),
> picks one per request, and calls it directly. No separate LB process. Pros:
> lower latency (no extra hop), richer algorithms possible (consistent hashing,
> zone-aware). Cons: every client needs LB library, instance list can be stale.
> Used by: Netflix Ribbon (deprecated), Spring Cloud LoadBalancer, gRPC's client
> LB. Service meshes (Istio) move this logic to a sidecar proxy, combining
> the benefits of both approaches.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A load balancer sits in front of multiple servers and distributes incoming
> requests among them. The simplest approach: round-robin, which sends request 1
> to server 1, request 2 to server 2, and so on. It also monitors server health
> and stops sending traffic to servers that are down. L7 load balancers can
> route based on the URL - so /api requests go to API servers and /static requests
> go to file servers.

**Senior / Staff:**
> The load balancer is where several cross-cutting concerns live: SSL termination,
> DDoS mitigation, rate limiting, A/B testing, canary routing, request
> authentication. Centralizing these at the LB avoids duplicating them in each
> service. The tradeoff: the LB becomes a critical, complex component. Modern
> practice: separate concerns - use a dedicated API Gateway for auth/rate-limiting,
> service mesh for internal service-to-service routing, CDN for geographic
> distribution. The "load balancer" is actually a stack of L7 components.
> The most important operational concern: making the LB itself HA. A single
> nginx instance is a SPOF. AWS ALB is HA by design. HAProxy + keepalived
> + floating IP for on-premise.

---

### ⚠️ Common Misconceptions

**Misconception: "Load balancing is only for HTTP."**
Load balancers work for any TCP-based protocol: HTTP, HTTPS, MySQL (ProxySQL),
Redis, gRPC, WebSocket, custom TCP. AWS NLB (L4) can load balance raw TCP
connections for any protocol. Database connection poolers (PgBouncer, ProxySQL)
are specialized L4 load balancers for DB connections.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Session stickiness breaks after server removal**
Symptom: users see logged-out state after server removal.
Cause: sticky sessions (user tied to specific server), server removed,
user's server gone.
Fix: externalize session state to Redis. Remove sticky sessions entirely.
Any server handles any user. Load balancer can freely remove/add servers.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How do health checks work in load balancers?

Load balancers use health checks to detect and remove unhealthy servers:

```
Health check types:
  TCP check: open port 8080, close immediately
    -> verifies process is listening
    -> doesn't verify application health

  HTTP check: GET /health -> expect 200 OK
    -> verifies HTTP server responds
    -> can include dependency checks (DB up?)

  Custom script: run command, check exit code
    -> maximum flexibility

AWS ALB health check:
  Protocol: HTTP
  Path: /actuator/health
  Port: 8080
  Healthy threshold: 2 consecutive successes -> healthy
  Unhealthy threshold: 3 consecutive failures -> unhealthy
  Interval: 30 seconds
  Timeout: 5 seconds

Sequence:
  Server fails: stops responding
  LB: sends health check -> timeout (5 sec)
  LB: count = 1/3 failures
  LB: sends health check -> timeout
  LB: count = 2/3 failures
  LB: sends health check -> timeout
  LB: count = 3/3 -> mark UNHEALTHY
  LB: stop sending traffic to this server
  Total time: 3 * 30s = 90 seconds of unhealthy before removed
  In that 90s: ~33% of requests to that server fail
```

*What separates good from great:* The health check endpoint must be designed
carefully. Too shallow (/ping always returns 200): doesn't detect real failures.
Too deep (checks all dependencies): false positives (Kafka is slow -> health
fails -> pod removed from service -> Kafka issue causes cascading pod removals).
Best practice: readiness probe checks: is this instance ready to serve traffic?
(Can connect to DB, can read from critical cache). It does NOT check: are all
my downstream dependencies healthy? Downstream health is those services' concern.

---

#### Q2 - How do you prevent a thundering herd when a server is added back?

When a server returns from failure, adding it back can create a spike:

```
Scenario:
  4 servers, each handling 25% of 10K QPS (2500 QPS each)
  Server 1 fails: LB removes it
  Other 3 servers now handling 3333 QPS each (33% more load)
  Server 1 recovers: LB adds it back
  LB round-robin: immediately sends 25% (2500 QPS) to Server 1
  Server 1 might not be fully warmed up:
    JVM JIT not yet compiled hot paths
    Local caches empty (cold)
    Thread pool queues not warmed up

Slow-start (ramping):
  Server 1 re-added with weight 1 (vs normal weight 10)
  LB sends 1/31 = 3% of traffic initially
  Over 120 seconds, weight increases to 10 (100% normal)
  Nginx: slow_start 120s; on the upstream server entry
  This gives Server 1 time to warm up caches + JIT

Kubernetes readiness probe:
  Pod is added to service only when readiness probe passes
  Spring Boot: /actuator/health in readiness probe
  Add initial warmup: call critical DB queries at startup
    -> JIT compiles hot paths
    -> Connection pool warms up
    -> Then readiness probe starts passing
```

*What separates good from great:* The "cache warming" pattern reduces cold-start
issues. During application startup (before readiness probe passes):
(1) establish DB connection pool connections, (2) pre-fetch configuration,
(3) execute a few representative queries to warm the JIT. After these:
signal readiness. The slow-start at the LB provides a safety net.
Combined: the pod warms itself up AND the LB ramps traffic slowly.
Netflix and other high-traffic sites use this approach routinely.

---

#### Q3 - What is geographic load balancing and how does it work?

Geographic LB routes users to the nearest datacenter:

```
DNS-based geographic load balancing:
  User in US -> DNS query -> myapp.com
  DNS server (Route 53, Cloudflare):
    Sees: query from US IP
    Returns: IP of US datacenter

  User in Asia -> DNS query -> myapp.com
  DNS server:
    Sees: query from Asian IP
    Returns: IP of Asia datacenter

  Benefit: users connect to nearest datacenter
           Reduced latency (continental routing)
  Limitation: DNS TTL (1-5 minutes) means failover is slow
              DNS caching by ISPs may extend this

Anycast routing:
  Multiple datacenters advertise same IP via BGP
  Internet routing: sends packet to topologically nearest datacenter
  AWS Global Accelerator, Cloudflare use anycast
  Failover: near-instant (BGP convergence seconds, not minutes)
  Used for: global services, DDoS mitigation

Active-active multi-region:
  Users write to local region
  Data replicated across regions (async or sync)
  Reads: local region (fast)
  Writes: local + async replication to other regions
  Conflict resolution: vector clocks, last-write-wins, CRDTs
```

*What separates good from great:* Multi-region active-active introduces
cross-region data consistency challenges. If a user in US writes data and
immediately makes a request that routes to the Asia datacenter (DNS failover
or CDN routing), the Asia datacenter may not have the write yet (replication lag).
Solutions: (1) route the same user to the same region (sticky routing), (2)
read-after-write consistency (after write, reads go to same region for N seconds),
(3) replicate writes synchronously (adds latency to writes). Each solution has
trade-offs. This is why many companies are single-region with HA within the region.

---

#### Q4 - How does a load balancer handle WebSocket connections?

WebSocket upgrade requires special handling:

```
WebSocket lifecycle:
  1. HTTP upgrade request:
     GET /ws HTTP/1.1
     Connection: Upgrade
     Upgrade: websocket

  2. HTTP 101 response from server:
     101 Switching Protocols
     Upgrade: websocket

  3. TCP connection keeps open for bidirectional messages

Load balancer requirements:
  - Must forward Upgrade header
  - Must keep TCP connection open (not close after response)
  - Connection tied to one backend server (session affinity)

Nginx WebSocket config:
  location /ws {
      proxy_pass http://websocket_servers;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 3600;  # keep alive for 1 hour
      # Must use IP hash for session affinity:
      # same client -> same websocket server
  }

  upstream websocket_servers {
      ip_hash;  # session affinity (WebSocket is stateful)
      server ws-1:8080;
      server ws-2:8080;
  }

Problem: WebSocket connections are long-lived (stateful)
  Server removal: all connections to that server close
  Client reconnect: LB routes to any available server
  Application: must handle reconnection gracefully
```

*What separates good from great:* WebSocket at scale is harder than HTTP.
Each active connection holds a file descriptor and memory on the server.
100K concurrent WebSocket connections requires careful tuning: OS file descriptor
limits (ulimit -n), kernel socket buffer sizes, application connection management.
Dedicated WebSocket servers (Node.js, Go) often outperform Java for connection-heavy
workloads because they handle I/O more efficiently. The architectural pattern:
separate WebSocket gateway (handles connections only) from application servers
(handles business logic). Gateway maintains connections; communicates with
application servers via Redis pub/sub or message queue.

---

#### Q5 - What is SSL termination and why is it done at the load balancer?

SSL termination: decrypt HTTPS at the LB, pass HTTP to application servers.

```
Without SSL termination:
  Client -> HTTPS -> App Server 1 (has cert + private key)
  Client -> HTTPS -> App Server 2 (has cert + private key)
  Problems:
  - Every app server needs private key (security risk)
  - Every app server does crypto (CPU overhead)
  - Cert renewal: update on every server

With SSL termination at LB:
  Client -> HTTPS -> Load Balancer -> HTTP -> App Server 1
                                           -> App Server 2
  Benefits:
  - Private key on LB only (single place to secure)
  - App servers do no crypto (more CPU for business logic)
  - Cert renewal: update on LB only
  - LB can inspect HTTP traffic (for routing, logging)

Concerns:
  - Internal traffic (LB -> App) is plain HTTP
  - If internal network is untrusted: re-encrypt (TLS re-origination)
  - Most datacenters: internal network trusted, HTTP is OK

TLS re-origination (for sensitive data):
  Client -> HTTPS -> LB -> HTTPS -> App Server
  LB decrypts + inspects + re-encrypts
  Maximum security, more CPU overhead at LB

mTLS (Mutual TLS):
  Both client and server present certificates
  LB passes client cert to app server (via header)
  App server can verify: is this a legitimate service calling me?
  Used in: service mesh (Istio), zero-trust networks
```

*What separates good from great:* Certificate management at scale is an
operational challenge. Let's Encrypt automated cert renewal (certbot) solves
it for single servers. For load balancers: AWS ACM (auto-renews, integrated
with ALB), or cert-manager in Kubernetes (ACME client, stores in Secrets).
The failure mode: cert expiry causes HTTPS to fail for all users with a
browser error. Monitoring: alert when cert expires within 30 days. The SRE
anti-pattern: manually managed certs in an ops team that goes on vacation.
Automate cert renewal; treat a cert expiry as a P1 incident.

---

#### Q6 - How does load balancing work in Kubernetes?

Kubernetes has multiple load balancing layers:

```
Layer 1: ClusterIP Service (internal)
  Kubernetes Service: stable IP + DNS for a set of pods
  kube-proxy (iptables): load balances connections to pods
  Algorithm: random (default), round-robin
  Use: service-to-service communication within cluster

Layer 2: NodePort / LoadBalancer Service (external)
  NodePort: opens port on each node, routes to pods
  LoadBalancer: provisions cloud LB (AWS ALB, GCP GLBN)
  Use: external traffic to cluster

Layer 3: Ingress Controller (L7)
  Ingress: rules for URL-based routing
  Ingress Controller: implements rules (nginx, Traefik, ALB Ingress)
  Use: URL-based routing, SSL termination, multi-service

Layer 4: Service Mesh (L7, sidecar)
  Envoy sidecar next to every pod
  All traffic: pod -> Envoy -> Envoy -> pod
  Provides: mTLS, circuit breaking, observability, retry
  Use: security + reliability for service communication

Example Ingress for URL routing:
  /api/* -> api-service:8080
  /static/* -> static-service:80
  / -> frontend:3000
  Handled by: nginx Ingress Controller
```

*What separates good from great:* The Kubernetes networking stack is
layered and each layer has different failure modes. If pods are healthy
but Service isn't serving traffic: check endpoint slice (is pod IP in
the endpoint list?). If Ingress isn't routing: check IngressClass annotation,
check Ingress controller logs. If cross-namespace service calls fail:
check NetworkPolicy (might be blocking). The observability challenge:
with 3-4 layers of load balancing, a failed request's path is hard to trace.
Distributed tracing (Jaeger, Zipkin) is essential to trace a request from
Ingress through Service Mesh through service to database.

---

#### Q7 - What is the difference between active-passive and active-active load balancer setups?

**Active-Passive (HA pair):**
```
Active LB: handles all traffic
Passive LB: standby, monitors active

If active fails:
  Passive detects failure (heartbeat missing)
  Passive acquires floating IP (ARP announcement)
  Passive becomes active (traffic flows to it)

Failover time: 5-30 seconds (heartbeat interval + ARP)
Configuration: same config on both (synchronized)
Tools: keepalived (VRRP), Pacemaker, AWS ALB (cloud-managed)

Advantage: simple, no split-brain risk
Disadvantage: 50% of capacity idle (passive is standby)
```

**Active-Active:**
```
Both LBs handle traffic
DNS round-robin: half traffic to LB1, half to LB2
If one fails: DNS TTL -> failover (minutes)
Anycast: BGP withdraws route -> failover (seconds)

Advantage: full capacity utilized, faster failover with anycast
Disadvantage: more complex (need shared state or session affinity)
```

*What separates good from great:* Cloud-managed load balancers (AWS ALB, GCP
HTTPS LB) are inherently multi-AZ active-active. You don't design their HA -
the cloud provider does. On-premise: active-passive with keepalived is the
standard. The failure scenario to test: "What happens if the active LB goes
down while handling 10,000 connections?" Keepalived failover drops those
connections; clients must reconnect. For zero-connection-drop failover, you
need BGP anycast routing (connection-less failover) or cloud-managed solutions
that handle it transparently.

---

#### Q8 - How does a load balancer enable canary deployments?

Canary deployment: route small % of traffic to new version, monitor, expand.

```
Nginx weight-based canary:
  upstream myapp {
      server app-v1:8080 weight=95;  # 95% to v1
      server app-v2:8080 weight=5;   # 5% to v2
  }

  # Gradually adjust weights:
  # 5% -> 10% -> 25% -> 50% -> 100% v2

AWS ALB canary (weighted target groups):
  Rule: forward 95% to TG-v1, 5% to TG-v2
  Adjustable via console or API without restart

Kubernetes with Ingress (nginx):
  # Two deployments: app-v1 and app-v2
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "5"
  # 5% to app-v2, 95% to app-v1

Monitoring canary:
  Error rate: canary vs baseline (expect equal or better)
  Latency: P99 canary vs baseline
  Business metrics: conversion rate, user engagement
  Automatic rollback: if error rate > threshold, reduce weight to 0

Sticky canary (same user always gets same version):
  Hash on user ID or cookie
  Important for: behavioral A/B tests (don't want user to see v1 then v2)
  Nginx: consistent hashing on $cookie_user_id
```

*What separates good from great:* Canary deployments require observability
before they're useful. Without proper metrics (error rate by version, latency
by version), you're doing a canary deployment but can't tell if it's safe to
proceed. The deployment pipeline should: (1) deploy at 1%, (2) wait 15 minutes
and check metrics, (3) auto-advance to 10% if metrics healthy, (4) continue
to 100% or auto-rollback if degraded. Progressive delivery tools (Argo Rollouts,
Flagger) automate this. The goal: "deploy fearlessly" because any problem is
caught at 1% traffic before full rollout.

---

#### Q9 - How do you load balance between microservices in a service mesh?

Service mesh (Istio/Linkerd) handles service-to-service load balancing:

```
Without service mesh:
  ServiceA -> HTTP -> ServiceB
  Load balancing: Spring Cloud LoadBalancer
                  (client-side, in ServiceA)
  Problems: each service implements its own LB logic
            no centralized control or observability

With Istio service mesh:
  ServiceA -> Envoy (sidecar) -> Envoy (sidecar) -> ServiceB
  Envoy handles: load balancing, retries, circuit breaking,
                 mTLS, metrics, tracing
  ServiceA code: just calls http://service-b
  Istio control plane (Istiod): pushes configuration to Envoys

Load balancing in Istio:
  Default: round-robin
  Configure via DestinationRule:

  apiVersion: networking.istio.io/v1alpha3
  kind: DestinationRule
  metadata:
    name: order-service
  spec:
    host: order-service
    trafficPolicy:
      loadBalancer:
        simple: LEAST_CONN  # least connections
      connectionPool:
        tcp:
          maxConnections: 100
        http:
          http2MaxRequests: 1000
      outlierDetection:  # circuit breaker
        consecutiveErrors: 5
        interval: 5s
        baseEjectionTime: 30s
```

*What separates good from great:* The outlierDetection in Istio DestinationRule
is passive health checking (circuit breaking at the mesh level). When a pod
returns 5 consecutive 5xx errors within 5 seconds: Istio ejects it from the
load balancing pool for 30 seconds. This is healthchecking without polling -
it uses actual traffic to detect unhealthy pods. Combine with Kubernetes readiness
probes (prevent traffic to pods not yet ready) and Istio outlier detection
(remove pods that are erroring): two-layer health management that handles both
startup failures and runtime degradation.

---

# Caching Strategies

---
id: SSD-008
title: Caching Strategies
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #caching, #redis, #cache-aside, #write-through, #ttl, #invalidation
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Caching stores frequently accessed data in fast storage (memory) to reduce
> database load and latency. Core strategies: cache-aside (application reads
> cache, fetches DB on miss), write-through (write to cache + DB together),
> write-behind (write to cache, async to DB). Cache invalidation is the hard
> problem: stale data causes correctness issues; aggressive invalidation reduces
> hit rate. TTL-based expiry is the simplest mechanism; event-based invalidation
> is most correct but complex.

**3 minutes:**
> Caching improves performance by exploiting temporal locality: recently accessed
> data is likely to be accessed again. The three decisions: WHAT to cache
> (hot, read-heavy, expensive-to-compute data), WHERE to cache (in-process
> for ultra-low latency, distributed cache for consistency across instances),
> and HOW to invalidate (TTL for tolerable staleness, event-driven for strict
> freshness).
>
> Cache-aside (lazy loading) is the most common: app checks cache, on miss
> fetches from DB and populates cache. Simple, but vulnerable to cache stampede
> (many threads on miss). Write-through keeps cache and DB in sync on every write
> (no stale data, but write latency increases). Write-behind (write-back) writes
> to cache first, async to DB - best write performance, risk of data loss.
>
> Redis is the standard distributed cache: single-threaded (no locking),
> sub-millisecond latency, data structures (sorted sets for leaderboards,
> pub/sub for event notifications), persistence (AOF/RDB), clustering.

**Blank Mind Recovery:**

**(1) Restate:** "Caching stores data in fast memory to avoid expensive
database or computation calls."

**(2) First principles:** "DB query: 10ms. RAM lookup: 0.1ms. Cache is 100x faster.
Cache 20% of hot data (Pareto) = 80% of requests served from memory.
DB sees only 20% of original traffic."

**(3) Three questions:** What to cache? Where? How to keep fresh? Answer all three.

---

### 📘 Concept Explanation

**Caching strategies:**

```
Cache-Aside (Lazy Loading):
  Read:
    1. Check cache for key
    2. HIT: return value (fast path)
    3. MISS: query DB, populate cache, return value
  Write:
    1. Write to DB
    2. Invalidate (delete) cache key (or update)

  Pros: only cache what's actually needed
  Cons: cache miss = 3 operations (read cache + read DB + write cache)
        cache stampede on cold start

Write-Through:
  Write:
    1. Write to cache
    2. Write to DB (in same transaction or atomically)
  Read:
    1. Check cache (always fresh, always there for written data)
    2. MISS only for never-written data

  Pros: no stale data, consistent
  Cons: write latency = cache write + DB write
        data may be in cache but never read (wasted cache space)

Write-Behind (Write-Back):
  Write:
    1. Write to cache
    2. Return to client (fast!)
    3. Async: batch writes to DB
  Read:
    1. Check cache

  Pros: fastest writes (async DB write)
  Cons: risk of data loss if cache fails before DB write
        stale reads possible if cache and DB diverge

Read-Through:
  Cache handles the miss automatically:
    On miss: cache fetches from DB (not the application)
    Application just reads from cache
  Cache is between app and DB
  Pros: simpler application code
  Cons: must configure cache with DB fetch logic

Refresh-Ahead:
  Predict cache expiry, pre-fetch data before expiry
  CDN does this for high-traffic assets
  Pros: eliminates cache miss for high-traffic data
  Cons: may pre-fetch unused data (wasted resources)
```

**Cache hierarchy:**

```
Tier 1: In-process cache (Caffeine, Guava Cache)
  Location: JVM heap
  Latency: ~1 microsecond
  Size: limited by JVM heap (typically <1GB useful)
  Consistency: local to one instance only
  Use: very hot data, computation results, config

Tier 2: Distributed cache (Redis, Memcached)
  Location: dedicated cache servers
  Latency: ~500 microseconds (network)
  Size: terabytes possible (Redis Cluster)
  Consistency: shared across all instances
  Use: user sessions, hot DB rows, computed aggregates

Tier 3: CDN (Cloudflare, CloudFront)
  Location: edge, geographically distributed
  Latency: ~10ms (local datacenter)
  Size: petabytes (content-addressed)
  Consistency: TTL-based
  Use: static assets, API responses with max-age

Full caching:
  Browser cache -> CDN -> App in-process -> Redis -> DB
  Each layer reduces load on the next
```

---

### 💻 Code Example

```java
// BAD: no caching (every request hits DB)
@Service
public class ProductService {
    public Product getProduct(Long id) {
        // 20ms DB query on every call
        return productRepository.findById(id).orElseThrow();
    }
}

// GOOD: cache-aside with Redis
@Service
public class ProductService {

    private final ProductRepository repo;
    private final RedisTemplate<String, Product> redis;
    private static final Duration TTL = Duration.ofMinutes(15);

    public Product getProduct(Long id) {
        String key = "product:" + id;

        // 1. Check cache
        Product cached = redis.opsForValue().get(key);
        if (cached != null) {
            return cached;  // fast path: ~0.5ms
        }

        // 2. Cache miss: fetch from DB
        Product product = repo.findById(id).orElseThrow();

        // 3. Populate cache
        redis.opsForValue().set(key, product, TTL);
        return product;  // 20ms on miss, fast on hit
    }

    public Product updateProduct(Long id, ProductDto dto) {
        // Write to DB
        Product updated = repo.save(dto.toEntity(id));
        // Invalidate cache (stale data)
        redis.delete("product:" + id);
        return updated;
    }
}
```

```java
// BETTER: Spring Cache abstraction (@Cacheable)
@Service
public class ProductService {

    @Cacheable(
        value = "products",
        key = "#id",
        unless = "#result == null")
    public Product getProduct(Long id) {
        // Called only on cache miss
        // Cache handles the rest
        return productRepository.findById(id).orElseThrow();
    }

    @CachePut(value = "products", key = "#id")
    public Product updateProduct(Long id, ProductDto dto) {
        // Updates cache with return value
        return productRepository.save(dto.toEntity(id));
    }

    @CacheEvict(value = "products", key = "#id")
    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }
}

// Configuration:
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager(
            RedisConnectionFactory factory) {
        RedisCacheConfiguration config =
            RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(15))
                .serializeValuesWith(
                    RedisSerializationContext
                        .SerializationPair.fromSerializer(
                            new GenericJackson2JsonRedisSerializer()));

        return RedisCacheManager.builder(factory)
            .cacheDefaults(config)
            // Per-cache TTL override
            .withCacheConfiguration("products",
                config.entryTtl(Duration.ofMinutes(30)))
            .build();
    }
}
```

> **Code walkthrough:** @Cacheable intercepts the method call via Spring AOP proxy.
> It generates a cache key (by default: method name + args, or custom key expression).
> On cache hit: returns cached value without calling the method. On miss: calls method,
> caches result, returns it. The unless="#result==null" prevents caching null returns
> (so null represents "not found" consistently, not a cached absence).
> @CachePut always calls the method AND updates cache (for write-through).
> @CacheEvict removes from cache (for invalidation after delete). The per-cache TTL
> configuration shows that different data types need different freshness requirements:
> product catalog (30 min) vs user session (15 min).

```java
// Cache stampede protection (mutex pattern):
@Service
public class ProductService {

    private final RedisTemplate<String, String> redis;
    private final ProductRepository repo;

    public Product getProduct(Long id) {
        String key = "product:" + id;
        String lockKey = "lock:product:" + id;

        // Try cache first
        String cached = redis.opsForValue().get(key);
        if (cached != null) {
            return deserialize(cached, Product.class);
        }

        // Try to acquire lock (SET NX EX = atomic)
        Boolean locked = redis.opsForValue()
            .setIfAbsent(lockKey, "1",
                Duration.ofSeconds(5));

        if (Boolean.TRUE.equals(locked)) {
            try {
                // We have lock: fetch from DB + populate
                Product p = repo.findById(id).orElseThrow();
                redis.opsForValue().set(
                    key, serialize(p),
                    Duration.ofMinutes(15));
                return p;
            } finally {
                redis.delete(lockKey);
            }
        } else {
            // Another thread is fetching: wait and retry
            // (simplified: real impl uses spin with backoff)
            Thread.sleep(50);
            return getProduct(id);  // recursive retry
        }
    }
}
```

> **Code walkthrough:** Cache stampede: when a popular key expires, thousands
> of concurrent requests all miss the cache simultaneously and hit the DB.
> The mutex pattern: one thread acquires a distributed lock (SET NX = set if
> not exists, atomic operation in Redis). Only one thread fetches from DB;
> others wait. The lock TTL (5 seconds) prevents deadlock if the lock holder
> crashes. This pattern is complex; for most cases: short TTL with stampede
> tolerance (brief DB spike acceptable) or refresh-ahead (proactive cache
> refresh before expiry). The mutex pattern is for extremely high-traffic
> keys where even a brief DB spike is unacceptable.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Caching stores data in memory to avoid slow database queries. The most common
> pattern: check the cache first; if not there, fetch from DB and store in cache.
> Use a TTL (Time To Live) to expire stale data automatically. Redis is the
> standard distributed cache: it stores key-value pairs in memory with sub-millisecond
> access time. Spring's @Cacheable annotation makes it easy to add caching
> to any service method.

**Senior / Staff:**
> The hard problem in caching is invalidation. TTL-based expiry is simple but
> accepts staleness for up to TTL seconds. Event-driven invalidation (on write:
> delete cache key) is more accurate but adds coupling. For high-traffic keys:
> cache stampede protection needed (mutex, stale-while-revalidate). For write-heavy
> data: write-through (cache = DB, consistent) or cache-aside with short TTL.
> The production failure mode to know: Redis connection pool exhausted. Default
> Lettuce pool: 8 connections. At 100K QPS, 8 connections to Redis means
> 12,500 requests per connection per second. If each Redis operation takes 1ms:
> max throughput per connection = 1000/sec; 8 connections = 8,000 QPS. Increase
> pool size or use Redis Cluster for higher throughput.

---

### ⚠️ Common Misconceptions

**Misconception: "Cache invalidation is easy - just delete on write."**
Delete-on-write solves single-server invalidation. With distributed cache + multiple
writers: writer 1 invalidates key, writer 2 re-populates with stale data before
writer 1's write reaches DB. Race condition. Solution: CAS (compare-and-swap)
for cache updates, or use the "delete + short TTL" pattern (delete key after write,
set short TTL on re-population to limit stale window). Facebook's TAO uses
lease-based invalidation to handle this at scale.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Cache memory exhaustion (eviction)**
Symptom: Redis memory grows to limit; eviction policy kicks in; cache hit rate drops.
Cause: TTL too long or no TTL (never expire); data grows without bound.
Diagnosis: redis-cli info memory -> maxmemory, used_memory.
  redis-cli info stats -> evicted_keys (if non-zero: evictions happening)
Fix: add TTL to all keys, review maxmemory-policy (allkeys-lru for cache),
     increase Redis memory or add Redis Cluster nodes.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - What cache eviction policies exist and when do you use each?

When cache is full, eviction removes entries to make room:

```
LRU (Least Recently Used):
  Evict entry that was accessed longest ago
  Assumption: recently used = likely to be used again
  Good for: general-purpose cache (hot data stays in)
  Redis: allkeys-lru or volatile-lru

LFU (Least Frequently Used):
  Evict entry that was accessed least often
  Good for: data with predictable access patterns
  Long-lived popular items survive; occasional items evicted
  Redis: allkeys-lfu (Redis 4.0+)

FIFO (First In First Out):
  Evict oldest entry by insertion time
  Good for: data where freshness = value (news, stock prices)
  Bad for: static popular data (gets evicted just because it's old)

Random:
  Evict random entry
  Simple, fast
  Approximate LRU at low cost
  Redis: allkeys-random

TTL-based:
  Evict entries closest to expiry (volatile-ttl)
  Good for: TTL already set on all keys, prefer evicting soon-to-expire

Redis maxmemory-policy options:
  noeviction: return error when full (for DB, not cache)
  allkeys-lru: LRU on all keys (best for pure cache)
  allkeys-lfu: LFU on all keys (for uneven access patterns)
  volatile-lru: LRU only on keys with TTL set
  allkeys-random: random eviction
```

*What separates good from great:* The eviction policy should match the data
access pattern. For a product catalog (popular products are always popular):
LFU keeps the hot products in cache longer. For a news feed (newest items
most accessed, then dropped): TTL-based. For a general session cache:
LRU works well (recently active sessions stay, old sessions evicted).
Monitor evicted_keys in Redis - if evictions are frequent: either cache
capacity is too small or TTLs are too long (entries not expiring before eviction
triggers). The goal: evictions should be near zero in normal operation.

---

#### Q2 - How do you implement a distributed lock with Redis?

Distributed lock: ensures only one process executes a critical section.

```java
// Redis SETNX (SET if Not eXists) pattern:
public boolean acquireLock(String resource,
                            String lockValue,
                            Duration ttl) {
    // Atomic: SET resource lockValue NX EX ttl
    // NX = only set if key doesn't exist
    // EX = expire after ttl seconds
    Boolean result = redis.opsForValue().setIfAbsent(
        "lock:" + resource,
        lockValue,           // unique value (UUID)
        ttl);
    return Boolean.TRUE.equals(result);
}

public void releaseLock(String resource, String lockValue) {
    // Lua script: only delete if value matches (atomic)
    // Prevents releasing another process's lock
    String luaScript =
        "if redis.call('get',KEYS[1]) == ARGV[1] then " +
        "return redis.call('del',KEYS[1]) " +
        "else return 0 end";
    redis.execute(
        new DefaultRedisScript<>(luaScript, Long.class),
        List.of("lock:" + resource),
        lockValue);
}

// Usage:
String lockValue = UUID.randomUUID().toString();
if (acquireLock("payment:order-123", lockValue,
        Duration.ofSeconds(10))) {
    try {
        processPayment(orderId);
    } finally {
        releaseLock("payment:order-123", lockValue);
    }
} else {
    throw new LockNotAcquiredException(
        "Another process is handling this order");
}
```

*What separates good from great:* The Redlock algorithm (multiple Redis instances)
provides stronger lock guarantees in a distributed setting. Single-node Redis lock:
if Redis goes down, all locks are lost (or unavailable). Redlock: lock acquired
on majority of N (odd number) Redis instances. Fails gracefully if < N/2 instances
fail. For most applications: single-node Redis lock is sufficient (Redis is
typically HA with replicas). Redlock is for cases where even brief split-brain
during Redis failover is unacceptable. Martin Kleppmann's critique of Redlock
(2016) is worth reading: distributed locks have subtle correctness issues even
with Redlock.

---

#### Q3 - What is cache warming and when is it necessary?

Cache warming: pre-populating cache before serving traffic.

```
Scenarios requiring warmup:
  1. New server startup (empty cache)
  2. Cache cluster replacement
  3. After cache flush (clearAll or data corruption)
  4. Major data change (bulk price update for Black Friday)

Warming approaches:

1. Lazy warmup (no explicit warming):
   First requests after startup: cache miss -> DB hit
   Cache populates organically as users request data
   Suitable for: non-critical latency, small hot set, gradual traffic increase

2. Pre-warm at startup:
   On application startup (@PostConstruct):
   - Load top N products
   - Load system config
   - Load frequently accessed user data
   Problem: startup takes longer; what is "top N" may be stale

3. Background warmup:
   Start accepting traffic immediately
   Parallel: background job populates cache from DB query
   "Top 1000 products by sales rank last 30 days"
   Problem: initial traffic before warmup = higher DB load

4. Copy-from-prod cache (for cache cluster replacement):
   RDB snapshot of Redis -> load into new Redis cluster
   Zero cold start, but snapshot may be hours old
   Good for: replacing cluster, not individual server

5. CDN warmup:
   Pre-fetch known URLs from CDN edges before launch
   curl --request PURGE (CDN-specific) + re-fetch
   Used for: planned traffic spikes (product launches)
```

*What separates good from great:* Cache warming is most critical for systems
with high cold-start DB load. If a single DB can handle 10x normal load for
a few minutes of warmup: no warming needed. If the DB would fail under cold-start
load: warming is critical. The pattern: start application in "warmup mode" (don't
accept external traffic), populate cache, then switch to "serving mode".
Kubernetes: set readiness probe to fail until warmup completes. This prevents
routing traffic before cache is warm. The warmup duration becomes part of the
pod startup time; optimize it (parallel warmup, incremental) to not slow deployments.

---

#### Q4 - How do you prevent stale reads in a read-through cache?

Stale read: reading from cache after the underlying data changed.

```
Stale read scenarios:

1. Write by Service A, read by Service B (different services):
   Service A updates user email in DB
   Service B reads user email from cache (stale)
   Result: stale email in Service B for TTL duration

2. Write after cache population with long TTL:
   User changes profile photo
   Old photo still in cache for 24 hours

Prevention strategies:

Strategy 1: Short TTL
  TTL = 30 seconds -> stale at most 30 seconds
  High cache miss rate -> more DB load
  Trade-off: staleness budget vs DB load

Strategy 2: On-write invalidation
  Write to DB -> delete cache key
  Next read: miss -> fetch fresh from DB
  Risk: if write succeeds but delete fails:
    - DB has new data, cache has old data
    - Old data served until TTL expires

Strategy 3: Write-through
  Write to cache + DB together (atomically or immediately)
  Cache always current
  Trade-off: write latency = cache write + DB write

Strategy 4: Event-driven invalidation
  DB write -> publishes event to message bus
  All cache nodes subscribe to events -> invalidate on event
  Eventually consistent: event delivery has delay
  More complex but decoupled

Strategy 5: Versioning
  Cache key = "user:42:v5" (includes version number)
  Write: increment version in DB
  Read: fetch version from DB, look up "user:42:v{version}"
  Cache miss forced on every write (version changes key)
  Very accurate but adds read latency (version fetch)
```

*What separates good from great:* The business requirement determines the
staleness budget. Banking: zero staleness (write-through or no cache for
balance). Product catalog: 5-minute staleness acceptable. User profile:
1-minute acceptable. Social feed: 30-second acceptable. There's no single
"correct" cache invalidation strategy - it depends on how stale is "too stale"
for the specific data. Define the staleness budget per data type and choose
the strategy that achieves it at acceptable cost.

---

#### Q5 - How does Redis handle persistence and what are the trade-offs?

Redis persistence options:

```
RDB (Redis Database snapshots):
  Periodic point-in-time snapshots
  Configuration:
    save 900 1   (save if 1+ changes in 900 seconds)
    save 300 10  (save if 10+ changes in 300 seconds)
    save 60 10000 (save if 10K changes in 60 seconds)

  Pros: compact binary file, fast restart (load snapshot)
  Cons: data loss between snapshots (up to 15 minutes)
  Use: cache that can tolerate data loss
       fast restart is important

AOF (Append Only File):
  Log every write operation
  Options:
    appendfsync always   - sync on every write (safest, slowest)
    appendfsync everysec - sync every second (good balance)
    appendfsync no       - let OS decide (fastest, least safe)

  Pros: near-zero data loss (everysec = 1 sec max loss)
  Cons: larger file, slower startup (replay all operations)
  Use: session storage, critical data in Redis

No persistence:
  Restart = empty Redis
  Pros: fastest writes (no disk I/O)
  Cons: restart = cache cold start
  Use: pure cache (DB is source of truth)

RDB + AOF (best of both):
  RDB for fast restart, AOF for durability
  Redis loads from RDB (fast), then replays AOF (recent)
  Recommended for: using Redis as primary store
```

*What separates good from great:* For Redis as a cache: no persistence or RDB
is appropriate (data loss = cold cache, acceptable). For Redis as a primary
data store (user sessions, queues, leaderboards where data can't be lost):
AOF with everysec. The anti-pattern: using Redis as cache with AOF + always
sync. This turns Redis into a synchronous storage engine (every write waits
for disk fsync), defeating the latency advantage. If you need both fast cache
and data persistence: two separate Redis instances (cache instance: no persistence;
session instance: AOF everysec).

---

#### Q6 - How do you cache search results and handle cache invalidation for complex queries?

Caching complex queries is harder than single-entity caching:

```
Simple entity cache:
  Key: product:42
  Invalidate on: product 42 updated

Complex query cache:
  Key: products:category=electronics:price<1000:sort=rating
  Result: list of matching products
  Invalidate on: ANY product in electronics changed?
    -> All electronics query caches must be invalidated
    -> Potentially thousands of cache entries

Approaches:

1. Cache full query result (key = query hash):
  Key: search:{hash("category=electronics&price<1000")}
  TTL: 60 seconds
  Invalidation: by TTL only (too complex to invalidate by entity change)
  Acceptable for: non-critical search freshness

2. Tag-based invalidation:
  Cache entry tagged: ["product:42", "category:electronics"]
  When product 42 changes: invalidate all entries tagged "product:42"
  When electronics category changes: invalidate "category:electronics" tags
  More complex but accurate
  Libraries: Spring Cache + Caffeine (supports tags)

3. Separate search index:
  Elasticsearch has its own index + result cache
  Invalidation: index document on change
  Elasticsearch propagates to search results
  Practical: most search systems use this approach

4. Application-level pagination + entity caching:
  Don't cache full result set
  Cache individual products (product:42 etc)
  Cache only the ID list for popular queries
  Hydrate: fetch each product from entity cache
  Invalidation: only product entities expire (not search results)
```

*What separates good from great:* Tag-based invalidation is elegant but
requires a cache that supports it (Caffeine, Ehcache, some Redis patterns).
The practical answer for most systems: accept TTL-based staleness for search
(60 seconds), cache individual entities for reads, rely on Elasticsearch
for real-time search accuracy. The "cache search results" approach works
for static queries (top products by category) but not for user-specific
dynamic filters. Distinguish the two cases: static query results can be cached;
dynamic per-user results should not be.

---

#### Q7 - How does a CDN cache work differently from an application cache?

CDN cache is HTTP-cache semantics, not application cache:

```
HTTP Cache-Control headers:
  Cache-Control: public, max-age=86400   (1 day)
    -> CDN and browser: cache for 1 day
    -> Serve cached without asking origin

  Cache-Control: no-store
    -> No caching anywhere (sensitive data)

  Cache-Control: private, max-age=300
    -> Only browser caches (not CDN)
    -> User-specific responses

  ETag: "abc123"
  If-None-Match: "abc123"
    -> Conditional request: "send full response only if changed"
    -> 304 Not Modified: use browser cache
    -> 200 OK: new content

CDN cache key:
  Default: URL (https://example.com/product/42)
  Custom vary: Vary: Accept-Language
    -> Different cached version per language
    -> Vary: Cookie -> user-specific (bad! defeats CDN purpose)

CDN cache invalidation:
  Programmatic: CloudFront API, Cloudflare API
  Cost: CloudFront charges for invalidations
  Delay: 1-30 seconds to propagate globally
  Solution: versioned URLs (product-v3.png) never need invalidation
            Content hash URLs: product-a3f7bc.js (deploy hash = different URL)

CDN vs Application cache:
  CDN: between client and origin, no application code changes required
       HTTP headers control behavior, URL-keyed
       Content-type agnostic (HTML, JSON, images, videos)
  App cache: inside application, code changes required
       Key is whatever the application defines
       Can cache non-HTTP artifacts (DB results, computations)
```

*What separates good from great:* The most powerful CDN optimization is
response caching for APIs (not just static files). If your product listing API
returns the same JSON for anonymous users: cache it at the CDN level.
Cache-Control: public, max-age=300 + CDN = 0 origin requests for 5 minutes.
At 100K QPS: 100K requests hit CDN, 0 hit your origin. The configuration:
CDN caches only public (Cache-Control: public) responses. The engineering
discipline: in API design, clearly distinguish public responses (cacheable at CDN)
from private (Cache-Control: private) and uncacheable responses. This discipline
dramatically reduces origin load.

---

#### Q8 - How do you use Redis for rate limiting?

Redis atomic operations enable accurate rate limiting:

```java
// Token bucket rate limiting with Redis
@Component
public class RedisRateLimiter {

    private final RedisTemplate<String, String> redis;

    // Lua script: atomic token bucket check
    private static final String RATE_LIMIT_SCRIPT =
        "local tokens = tonumber(redis.call('get', KEYS[1]) or ARGV[1])\n" +
        "if tokens > 0 then\n" +
        "  redis.call('set', KEYS[1], tokens - 1, 'EX', ARGV[2])\n" +
        "  return 1\n" +
        "else\n" +
        "  return 0\n" +
        "end";

    /**
     * Check and consume rate limit token.
     * Returns true if request allowed.
     */
    public boolean isAllowed(String userId,
                              int maxRequests,
                              int windowSeconds) {
        String key = "ratelimit:" + userId;

        Long allowed = redis.execute(
            new DefaultRedisScript<>(RATE_LIMIT_SCRIPT, Long.class),
            List.of(key),
            String.valueOf(maxRequests),
            String.valueOf(windowSeconds));

        return Long.valueOf(1L).equals(allowed);
    }
}

// Simpler: sliding window with sorted set
public boolean isAllowedSlidingWindow(String userId,
                                       int maxRequests,
                                       int windowSeconds) {
    String key = "rl:sw:" + userId;
    long now = System.currentTimeMillis();
    long windowStart = now - windowSeconds * 1000L;

    // Remove old entries, add current, count all
    redis.execute(connection -> {
        connection.zRemRangeByScore(
            key.getBytes(),
            0, windowStart);
        connection.zAdd(key.getBytes(), now,
            String.valueOf(now).getBytes());
        connection.expire(key.getBytes(), windowSeconds);
        return null;
    }, true);

    Long count = redis.opsForZSet().count(
        key, windowStart, now);
    return count != null && count <= maxRequests;
}
```

*What separates good from great:* Rate limiting has two correctness concerns:
(1) accurate counting under concurrent requests (use Redis atomic ops or Lua scripts),
(2) correct windowing (fixed window allows 2x burst at window boundary; sliding
window is more accurate but more expensive). The Lua script approach ensures
atomicity: check + decrement is one atomic operation. Without atomicity: two
concurrent requests both see tokens > 0, both consume, actual tokens = 0 but
both allowed. The sliding window sorted set is more accurate but uses O(N) memory
per user (one entry per request). For very high rate limits (1000 req/sec per user),
use fixed window or token bucket with approximation.

---

#### Q9 - How do you handle cache failures gracefully?

Cache can fail: connection timeout, Redis OOM, Redis crash.

```java
@Service
public class ProductServiceWithFallback {

    private final RedisTemplate<String, Product> redis;
    private final ProductRepository repo;

    @CircuitBreaker(
        name = "redis",
        fallbackMethod = "getProductFromDB")
    public Product getProduct(Long id) {
        String key = "product:" + id;
        Product cached = redis.opsForValue().get(key);
        if (cached != null) return cached;

        Product p = repo.findById(id).orElseThrow();
        // Redis failure: this throws, circuit breaker catches
        redis.opsForValue().set(key, p, Duration.ofMinutes(15));
        return p;
    }

    // Fallback: bypass cache entirely
    public Product getProductFromDB(Long id, Throwable ex) {
        log.warn("Redis unavailable, fetching from DB: {}",
            ex.getMessage());
        return repo.findById(id).orElseThrow();
    }
}
```

```yaml
# Redis circuit breaker config:
resilience4j:
  circuitbreaker:
    instances:
      redis:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 30s
        # When Redis is down: fail fast to DB
```

*What separates good from great:* The circuit breaker protects against the
"Redis is slow" scenario. Without it: if Redis takes 5 seconds per call
(instead of normal 0.5ms), every request to your service waits 5 seconds.
With circuit breaker: after 50% slow calls, circuit opens and falls through
to DB directly. The DB handles the load. When Redis recovers, circuit closes
and caching resumes. The application is slower (100% DB) but functional.
This is the difference between "cache is a nice-to-have optimization" and
"cache is required for the system to function." Design your system so cache
failure = degraded performance, not system failure.
