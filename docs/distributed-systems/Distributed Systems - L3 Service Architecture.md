---
layout: default
title: "Distributed Systems - L3 Service Architecture"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 10
permalink: /distributed-systems/l3-service-architecture/
---

# Service Discovery

**TL;DR:** Service discovery allows services to find each other's
network addresses dynamically without hardcoded IPs. Two variants:
client-side discovery (client queries a registry and selects an
instance) and server-side discovery (load balancer queries the
registry and routes). Tools: Netflix Eureka, Consul, Kubernetes
DNS/kube-proxy. Enables dynamic scaling and health-checked routing.

---

### 🎯 Model Answer

**30 seconds:**
> Service discovery allows services to locate each other without
> hardcoded IP addresses. A service registry (Consul, Eureka,
> Kubernetes) maintains a list of healthy instances for each service.
> Clients query the registry to find where to send requests.
> This enables dynamic scaling (new instances register automatically),
> and health-checked routing (unhealthy instances are removed from
> the registry).

**3 minutes:**
> In a static environment, services have fixed IP addresses and
> you configure those in properties files. In a dynamic cloud
> environment (containers, auto-scaling), service instances come
> and go. An instance might be at `10.0.0.5:8080` now and
> `10.0.1.12:8080` after a restart. Hardcoding addresses means
> every scale event requires a configuration change and redeployment.
>
> Service discovery solves this: each service instance registers
> itself with a central registry on startup (providing its IP,
> port, and health check endpoint). On shutdown or health check
> failure, the registry removes the instance. Clients look up
> the registry to get current healthy instances.
>
> Two patterns: client-side discovery (the client itself queries
> the registry - Eureka/Ribbon approach). Server-side discovery
> (the client sends to a load balancer, which queries the registry
> - Kubernetes approach with kube-proxy and Service objects).
> Server-side is simpler for clients (clients do not know about
> the registry) but requires a load balancer in the path.

**Blank Mind Recovery:**

**(1) Restate:** "Service discovery - dynamically finding service
instances by querying a registry instead of hardcoded addresses."

**(2) First principles:** "In a static world: know the address
in advance. In a dynamic world (containers, auto-scaling):
addresses change. Need a central directory that always has the
current healthy addresses. That is the registry."

**(3) Bridge:** "Like using a phone book instead of memorizing
everyone's phone number. The phone book (registry) is always
current. You look up the number (address) at call time.
When someone moves (instance restarts), the phone book is updated."

---

### 📘 Concept Explanation

**What it is:**
A mechanism for services to dynamically locate and connect to
other services by querying a registry of available service
instances, rather than using static configuration.

**The problem it solves:**
In dynamic cloud environments, service instances are ephemeral
(containers start and stop, auto-scaling adds and removes instances).
Static IP/port configuration becomes stale immediately. Service
discovery provides a real-time directory of available instances.

**Client-side discovery (Eureka/Ribbon):**

```
Service B Instance 1 (10.0.0.5:8080)
Service B Instance 2 (10.0.0.6:8080)
Service B Instance 3 (10.0.0.7:8080)
         ↕ heartbeat every 30s
[Eureka Registry]
    - ServiceB: [{10.0.0.5:8080, healthy},
                 {10.0.0.6:8080, healthy},
                 {10.0.0.7:8080, unhealthy}]
         ↑ cache lookup every 30s
[Service A]
  1. Look up "ServiceB" in local Eureka cache
  2. Get list: [10.0.0.5:8080, 10.0.0.6:8080]
     (10.0.0.7 excluded as unhealthy)
  3. Ribbon client-side load balances → pick one
  4. Call 10.0.0.5:8080/orders
```

**Server-side discovery (Kubernetes DNS + Service):**

```
[ServiceB Kubernetes Service: "orderservice"]
  → ClusterIP: 10.96.0.100 (virtual, stable)
  → kube-proxy routes to pods:
       10.0.0.5:8080 (pod 1, healthy)
       10.0.0.6:8080 (pod 2, healthy)

[Service A]
  1. DNS lookup: "orderservice.default.svc.cluster.local"
  2. Gets 10.96.0.100 (stable ClusterIP)
  3. kube-proxy handles routing to healthy pod
  
Service A only knows "orderservice" - never the pod IPs.
Kubernetes DNS updates automatically on pod changes.
```

**Health checking:**

```
Registry health check types:
1. HTTP: GET /health → 200 OK = healthy
2. TCP: connection accepted = healthy
3. TTL: instance must re-register every N seconds
   (if silent → assumed dead → deregistered)
4. gRPC: implements grpc.health.v1.Health service
```

**Deregistration strategies:**

```
Graceful: instance sends deregister request on shutdown
  (SIGTERM → deregister → wait for in-flight requests → exit)

Failure: health check fails → TTL expires → registry removes
  (typically 30-90 second lag)
```

**The key insight:**
Service discovery is a consistency problem: the registry's view
of healthy instances can lag reality by the health check interval.
A newly dead instance may still be in the registry for 30-90 seconds.
Client-side retries and circuit breakers handle this lag.

**When to use it:**
- All microservices in dynamic cloud environments
- Auto-scaling groups
- Containerized workloads (Kubernetes native)
- Any system where service instances change frequently

**When NOT to use it:**
- Static on-premise environments with stable IPs
- Single-service systems with no peer services

**Alternatives:**
- DNS-based: simple, works with any client
- Load balancer (HAProxy, ELB): hides discovery behind a stable endpoint
- Service mesh: handles discovery at the proxy layer

**First-principles derivation:**
"A service needs the other's address to connect. In a static world:
configure it at deployment. In a dynamic world: the address changes
faster than deployment cycles. Solution: query a registry at
connection time. The registry is the authoritative source of
current addresses."

---

### 💻 Code Example

```java
// SERVICE DISCOVERY WITH SPRING CLOUD EUREKA

// BAD: hardcoded service address
@Service
public class OrderClient {
    private final RestTemplate restTemplate;
    // BAD: hardcoded IP - breaks on any deployment change
    private static final String PAYMENT_URL =
        "http://10.0.0.5:8080/payments";

    public PaymentResult charge(Payment payment) {
        return restTemplate.postForObject(
            PAYMENT_URL, payment, PaymentResult.class);
    }
}

// GOOD: Eureka-based service discovery with
// load-balanced client
@Configuration
public class ServiceConfig {
    @Bean
    @LoadBalanced  // enables service name resolution
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}

@Service
public class OrderClient {
    private final RestTemplate restTemplate;

    public PaymentResult charge(Payment payment) {
        // "payment-service" is the registered name in Eureka
        // @LoadBalanced intercepts and resolves to a
        // healthy instance IP via Eureka cache
        // Round-robin (or configured) load balancing
        return restTemplate.postForObject(
            "http://payment-service/payments",
            payment, PaymentResult.class);
    }
}

// With Spring Cloud OpenFeign (cleaner):
@FeignClient(name = "payment-service")
public interface PaymentServiceClient {
    @PostMapping("/payments")
    PaymentResult charge(Payment payment);
    // Discovery + load balancing + retry
    // all handled by Feign + Eureka client
}
```

> **Code walkthrough:** The BAD pattern hardcodes the payment
> service IP. When the service restarts with a new IP (container
> scaling event), this code breaks. The GOOD pattern uses Spring
> Cloud's `@LoadBalanced` RestTemplate. The URL uses the service
> name (`payment-service`) instead of an IP. Spring Cloud Ribbon
> (or Spring Cloud LoadBalancer) resolves the name by querying
> the local Eureka cache and selecting a healthy instance using
> round-robin load balancing. The Feign client version is the
> most concise: the interface declares what the service provides,
> and Feign handles discovery, load balancing, and marshaling
> automatically.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Service discovery lets services find each other dynamically.
> A registry (Eureka, Consul, Kubernetes DNS) tracks healthy
> instances. Clients look up the registry instead of using
> hardcoded IPs. Two patterns: client-side (client queries
> the registry) and server-side (load balancer queries, client
> uses stable address).

---

**Senior / Staff:**
> In production I prefer server-side discovery (Kubernetes Service
> objects) because clients do not need a discovery library.
> The Kubernetes service virtual IP is stable; kube-proxy handles
> routing to healthy pods. For cross-cluster discovery: Consul
> with service mesh handles discovery across Kubernetes clusters.
> The key operational concern: health check interval vs. deployment
> speed. If health checks run every 30 seconds and deregistration
> requires 3 failed checks (90 seconds), a failed pod may still
> receive traffic for 90 seconds after failure. Configure pod
> readiness probes + preStop hooks to ensure graceful deregistration
> before traffic stops.

---

### ⚠️ Common Misconceptions

**"Service discovery eliminates the need for load balancing"**

Reality: service discovery provides the list of available instances.
Load balancing decides which instance to use. They are separate
concerns. Client-side discovery (Eureka) still requires a
client-side load balancer (Ribbon/Spring Cloud LoadBalancer) to
select among the returned instances. Server-side discovery often
combines both (Kubernetes Service object = discovery + load
balancing in one).

**"Registering with a health check endpoint means the service
is always routing to healthy instances"**

Reality: health check results are cached for the health check
interval. A newly degraded service may still receive traffic
for up to the health check interval + deregistration delay
(typically 30-90 seconds). This is why clients need circuit
breakers and retries - to handle stale registry state.

---

### ⚖️ Comparison Table

| Method | Discovery | LB | Client Complexity | Use When |
|---|---|---|---|---|
| Eureka + Ribbon | Client-side | Client-side | High | Spring Cloud microservices |
| Consul | Either | Either | Medium | Multi-platform |
| K8s DNS + Service | Server-side | kube-proxy | None | Kubernetes |
| Service Mesh | Server-side | Proxy | None | Multi-service, policy-heavy |
| HAProxy/Nginx | Server-side | Server-side | None | Simple, stable |

**The deciding factor:** Are you on Kubernetes? Use Kubernetes
services. Multi-platform or legacy? Use Consul. Spring-only
ecosystem? Eureka. Need advanced traffic policies? Service mesh.

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: After a deployment, some requests are still being routed
to the old (terminating) pod instances, causing errors.
How do you prevent this?

A: The Kubernetes pod is terminating but still in the Endpoints
list for a brief period. Clients send requests to a pod that
is no longer serving. Fix: (1) Add a `preStop` hook with a sleep
(e.g., 5-10 seconds) in the pod spec. This delays the container's
shutdown, giving kube-proxy time to update the iptables rules
and remove the pod from the Endpoints list. (2) Configure
`terminationGracePeriodSeconds` to be longer than the `preStop`
sleep + the maximum request duration. (3) Use
`readinessProbe` to ensure pods only receive traffic when ready.
On SIGTERM, the pod should fail its readiness probe first (before
termination begins), triggering removal from the Endpoints list.

#### Candidate Mistakes

Q: How does Kubernetes Service discovery work?

**What NOT to say:** "There is a service registry that all
services call."

**Say instead:** "Kubernetes has a Service object (not a registry
per se) that provides a stable virtual IP and DNS name. When you
create a Service in Kubernetes, kube-proxy on each node programs
iptables (or IPVS) rules to forward traffic from the Service's
ClusterIP to any healthy pod that matches the Service's selector.
The Pod's IP is registered in the Endpoints object. CoreDNS
resolves the service name (e.g., `orderservice.default.svc.cluster.local`)
to the ClusterIP. So service discovery in Kubernetes is: DNS
lookup → ClusterIP → kube-proxy → pod. The client never needs
a discovery library or a registry API call."

---

---

# Service Mesh and Sidecar Pattern

**TL;DR:** A service mesh moves network concerns (mutual TLS,
load balancing, circuit breaking, distributed tracing, retries)
out of application code and into a sidecar proxy deployed alongside
each service instance. Istio uses Envoy as the sidecar proxy.
The mesh provides: policy-based traffic management, automatic
mTLS between services, and unified observability without changing
application code. Trade-off: significant operational complexity.

---

### 🎯 Model Answer

**30 seconds:**
> A service mesh intercepts all inter-service traffic through
> sidecar proxies. The proxies handle: mutual TLS, load balancing,
> circuit breaking, retries, and distributed tracing - without
> any changes to the application code. The control plane (Istio's
> istiod) configures the proxies. The result: consistent security
> and observability policies across all services without library
> dependencies.

**3 minutes:**
> In a microservices architecture, every service needs the same
> resilience capabilities: circuit breakers, retries, timeouts,
> load balancing, distributed tracing. Without a service mesh:
> each service must implement these in its own code (Resilience4j,
> Brave, etc.), or use a shared library. This adds library
> dependency coupling and requires each team to implement and
> maintain resilience logic.
>
> A service mesh offloads this to infrastructure. Each pod has
> a sidecar proxy (Envoy in Istio). Kubernetes injects the sidecar
> automatically (MutatingWebhookConfiguration). All inbound and
> outbound traffic from the pod passes through the sidecar.
> The sidecar applies the configured policies: enforce mTLS,
> inject tracing headers, apply circuit breaker, retry on 503.
>
> The control plane (Istio's istiod) pushes configurations to all
> proxies. A `DestinationRule` configures load balancing strategy.
> A `VirtualService` configures traffic routing (canary deploy:
> 90% to v1, 10% to v2). Circuit breaker, retry, and timeout
> policies are configured in YAML, not code.

**Blank Mind Recovery:**

**(1) Restate:** "Service mesh - a layer of sidecar proxies that
handle networking (mTLS, load balancing, tracing) for all services,
without changing application code."

**(2) First principles:** "Every service needs the same network
capabilities. Adding them to each service separately creates
library coupling and code duplication. A sidecar proxy collocated
with each service handles all network concerns at the infrastructure
level - orthogonal to application logic."

**(3) Bridge:** "Like adding power steering to every car type
separately vs. designing a standard power steering module that
fits all cars. The sidecar is the standard module - the same
proxy works for all services."

---

### 📘 Concept Explanation

**What it is:**
An infrastructure layer that provides inter-service communication
capabilities (security, observability, traffic management) via
sidecar proxies deployed alongside each service instance, managed
by a centralized control plane.

**The problem it solves:**
Each microservice reinventing resilience (circuit breakers, retries,
timeouts, mTLS, distributed tracing) creates a maintenance burden
and library coupling. A service mesh centralizes these concerns
at the infrastructure layer.

**Service mesh architecture:**

```
Data Plane:
  [Service A container] + [Envoy sidecar] = pod
  [Service B container] + [Envoy sidecar] = pod
  All traffic: container → Envoy → Envoy → container

Control Plane (istiod):
  - Pushes TLS certificates to all Envoy sidecars
  - Pushes traffic policies (routing rules,
    circuit breaker config, retry config)
  - Receives telemetry from Envoy (for Prometheus)

Traffic flow:
  Service A requests Service B:
  A container → Envoy (A's sidecar)
    → mTLS encrypted connection
  → Envoy (B's sidecar)
    → B container
  
  Envoy (A's sidecar) handles:
    - Service discovery (via control plane)
    - Load balancing
    - Circuit breaking
    - Retry logic
    - Distributed trace header injection
    - Outbound mTLS certificate
  
  Envoy (B's sidecar) handles:
    - Inbound mTLS termination
    - Authorization policy enforcement
    - Metrics collection
```

**Key capabilities:**

```
Traffic Management:
  VirtualService: route 10% to v2, 90% to v1
  DestinationRule: load balancing, circuit breaker
  Retry: 3 retries on 503, 5s per attempt timeout

Security:
  PeerAuthentication: require mTLS on all pods
  AuthorizationPolicy: allow-list per service
  Certificate rotation: automatic (workload identity)

Observability:
  Automatic tracing: inject trace headers
  Metrics: request rate, error rate, P99 latency
    per service-pair (without any app code change)
  Distributed tracing: Jaeger/Zipkin export
```

**Sidecar injection:**

```yaml
# Automatically inject Envoy sidecar into all pods
# in the "production" namespace:
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled
# Every new pod gets Envoy as a sidecar automatically
# No changes to application Deployment manifests
```

**The key insight:**
The service mesh trades operational simplicity for architectural
consistency. Installing Istio on Kubernetes is not trivial (control
plane components, custom resource definitions, certificate
management). But once in place, adding a new service to the mesh
requires zero code changes - just deploy the service in the
mesh-enabled namespace.

**When to use it:**
- 10+ services with cross-cutting network concerns
- Need to enforce mTLS company-wide without code changes
- Multiple language/framework stacks (polyglot)
- Need canary deployments and traffic splitting
- Zero-trust security requirement

**When NOT to use it:**
- Small number of services (3-5): the operational overhead
  is not worth it
- Simple network requirements handled by a library
- Teams without Kubernetes operations expertise
- Latency-critical paths where sidecar overhead (~2-5ms)
  is unacceptable

**Alternatives:**
- Library-based: Resilience4j + Spring Cloud (simpler, less infra)
- Nginx/HAProxy ingress: handles external traffic policies
- AWS App Mesh: managed service mesh (reduces ops complexity)

**First-principles derivation:**
"Cross-cutting concerns (logging, tracing, security) that apply
to all services are best handled at a horizontal infrastructure
layer, not implemented repeatedly in each service. The sidecar
proxy is the network-level AOP (aspect-oriented programming):
intercept all calls and apply cross-cutting policies."

---

### 💻 Code Example

```java
// SERVICE MESH COMPARISON: CODE-LEVEL VS MESH

// WITHOUT service mesh: circuit breaker in code
@Service
public class OrderService {
    private final CircuitBreaker cb;
    private final WebClient paymentClient;
    private final Tracer tracer;  // for tracing
    // Each service must: configure circuit breaker,
    // inject tracer, handle retries, configure timeouts
    // All code just to call another service safely.

    public PaymentResult charge(Payment p) {
        Span span = tracer.nextSpan()
            .name("payment.charge").start();
        return CircuitBreaker.decorateSupplier(cb,
            () -> paymentClient.post()
                .uri("/payments")
                .header("X-B3-TraceId",
                    span.context().traceIdString())
                .bodyValue(p)
                .retrieve()
                .bodyToMono(PaymentResult.class)
                .block()
        ).get();
    }
}

// WITH service mesh (Istio): clean application code
@Service
public class OrderService {
    private final WebClient paymentClient;
    // NO circuit breaker code - handled by Envoy
    // NO tracing code - Envoy injects headers
    // NO retry code - configured in VirtualService

    public PaymentResult charge(Payment p) {
        // Pure business logic - infrastructure
        // concerns handled by the mesh
        return paymentClient.post()
            .uri("http://payment-service/payments")
            .bodyValue(p)
            .retrieve()
            .bodyToMono(PaymentResult.class)
            .block();
    }
}
```

```yaml
# Mesh policy (YAML - NOT code) handles resilience:
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: payment-service
spec:
  hosts:
  - payment-service
  http:
  - timeout: 3s
    retries:
      attempts: 3
      perTryTimeout: 1s
      retryOn: "5xx,gateway-error,connect-failure"
    route:
    - destination:
        host: payment-service
        subset: v1
      weight: 90
    - destination:
        host: payment-service
        subset: v2
      weight: 10  # canary: 10% to v2
```

> **Code walkthrough:** The without-mesh version must import and
> configure Resilience4j, set up OpenTracing, inject trace headers
> manually, and handle retries in code. This is roughly 30 lines
> of infrastructure code for every service call. The with-mesh
> version is 8 lines of pure business logic - the Envoy sidecar
> handles circuit breaking, retry, and distributed tracing
> transparently. The VirtualService YAML configures the mesh
> policy: 3-second total timeout, 3 retries (1s each), 90/10
> canary traffic split. Changing the canary weight requires only
> updating the YAML and applying it - no code change, no
> redeployment.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A service mesh deploys a sidecar proxy (Envoy) next to each
> service. All traffic passes through the proxy. The proxy handles
> mTLS, retries, circuit breaking, and distributed tracing -
> without application code changes. Istio is the most popular
> service mesh. Configured via VirtualService and DestinationRule
> Kubernetes custom resources.

---

**Senior / Staff:**
> I recommend a service mesh for polyglot environments (Java,
> Python, Go services) where maintaining the same resilience
> library configuration across all languages is impractical.
> The key operational concern: the sidecar adds ~2-5ms latency
> per hop. In a 10-hop chain, this is 20-50ms added latency.
> Profile before adopting. Also: Istio's control plane is complex
> to operate. Consider AWS App Mesh (managed) or Linkerd (simpler)
> before Istio. For security (mTLS): the mesh is excellent.
> For resilience: Resilience4j in code often provides better
> observability (Spring Actuator exposes CB state directly).

---

### ⚠️ Common Misconceptions

**"A service mesh eliminates the need for application-level
resilience patterns"**

Reality: the service mesh handles transport-level failures
(connection refused, HTTP 5xx). Business-level failures (payment
declined, inventory insufficient) are not visible to the mesh
and must be handled in application code. Additionally, the mesh's
circuit breaker and retries apply to all calls equally. Application
code may need more nuanced handling (e.g., do not retry a payment
charge, even on 5xx, because of potential duplicate charges).
The mesh and application-level resilience are complementary.

**"Adding a service mesh is free - just deploy Istio"**

Reality: Istio adds 6+ control plane components (istiod, ingress/egress
gateways, Prometheus, Kiali, Jaeger). Each pod gets a sidecar
that consumes additional CPU and memory (typically 50-100m CPU,
50-100Mi memory per pod). At 100 pods: 5-10 CPUs and 5-10GB
memory for the mesh infrastructure. Additionally: troubleshooting
network issues becomes more complex (is it the application or
the Envoy proxy?).

---

### ⚖️ Comparison Table

| Concern | Library | Service Mesh | K8s Ingress |
|---|---|---|---|
| mTLS | Manual | Automatic | Partial (ingress only) |
| Retries | Code | Policy YAML | Config only |
| Circuit breaker | Code | Policy YAML | No |
| Distributed tracing | Code | Automatic | Partial |
| Canary deploy | Feature flags | Traffic split YAML | Limited |
| Latency overhead | Minimal | ~2-5ms per hop | Minimal |
| Operations complexity | Low | High | Low |

**The deciding factor:** Is the team operating Kubernetes and
comfortable with CRDs? Do you have polyglot services? Do you
need automatic mTLS enforcement? If yes to all: service mesh.
If not: start with a library approach.

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: After enabling Istio, latency for your critical checkout path
increased from P99 50ms to P99 230ms. What is causing this
and how do you investigate?

A: The Envoy sidecar is adding latency at each hop. In a
checkout path that calls 5 services, 5 pairs of sidecars
(inbound + outbound) add latency. Investigation: (1) Use
Jaeger to view the distributed trace for a slow checkout request.
The trace will show time spent at each sidecar. (2) Check Envoy
metrics: `envoy_cluster_upstream_cx_connect_ms` (connection
time), `envoy_http_downstream_rq_time` (request time). (3) Check
if mTLS handshake time is contributing (certificate validation
takes time for cold connections). Fix: (1) Enable connection
pooling in DestinationRule to reuse mTLS connections. (2) Check
if the mesh is doing unnecessary retries or following unnecessary
policy chains. (3) For latency-critical paths: consider bypassing
the mesh for specific service pairs (DestinationRule with
`trafficPolicy.portLevelSettings` to disable mTLS for specific
ports). Long-term: if the latency is unacceptable, consider
reducing the service hop count (fewer services in the checkout
path).

#### Candidate Mistakes

Q: What is the difference between a service mesh and an API Gateway?

**What NOT to say:** "They are the same thing - both route traffic."

**Say instead:** "An API Gateway handles NORTH-SOUTH traffic:
external clients (browsers, mobile apps) to internal services.
It handles authentication, rate limiting, and URL routing for
external traffic. A service mesh handles EAST-WEST traffic:
service-to-service communication within the cluster. It handles
mTLS between services, load balancing between service instances,
and policy enforcement for internal calls. They are complementary:
the API Gateway is at the perimeter; the service mesh is in the
interior. A common setup: API Gateway (Kong, AWS API Gateway)
for external traffic, Istio service mesh for internal traffic.
Some tools (Istio's Ingress Gateway) overlap these concerns."

### 🚨 Failure Modes and Diagnosis

**Stale registry entries causing routing to dead instances:**

Symptom: periodic connection refused or HTTP 503 errors, even
though the service has healthy instances. Errors self-resolve
within 30-90 seconds.

Cause: the registry has not yet removed a recently failed instance.
The health check interval + deregistration delay means dead
instances stay in the registry for 30-90 seconds.

Diagnosis: check the registry for instances with recent health
check failures. Compare registry entries with actual running
instances (`kubectl get pods` vs. Eureka registered instances).

Fix: (1) Add client-side retry logic (retry on connection refused).
(2) Reduce health check interval and increase health check
sensitivity (fail after 1 missed check, not 3). (3) Implement
pod preStop lifecycle hook: before pod terminates, deregister
from Eureka and wait for in-flight requests to complete.

**Split-brain in registry clusters:**

Symptom: different callers are discovering different sets of
instances; some callers route to instances that others do not see.

Cause: network partition in the registry cluster (Eureka, Consul).
Registry nodes cannot agree on which instances are registered.

Diagnosis: check registry cluster health. Query each registry
node's instance list independently and compare.

Fix: Eureka has an explicit "self-preservation" mode that retains
registered instances when the registry loses > 15% of expected
heartbeats - to prevent mass deregistration during network issues.
This can cause stale entries during genuine outages. Configure
appropriately: disable self-preservation in dev, tune aggressively
in production. For Kubernetes: kube-proxy + etcd handles this
natively with Kubernetes' own consistency guarantees.

---

### 🏛️ System Design

*(Omit: service discovery is a component within a larger service
architecture. Full system design incorporating service discovery
is covered in L3 Service Architecture (this file), L5 Global Scale,
and L5 Migration Strategy files.)*

---

### 📊 Diagram

*(Omit: service discovery flow is described in the Concept
Explanation pseudocode for both client-side and server-side
variants. The Kubernetes DNS-based discovery flow is visually
self-explanatory from the description.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): Explain the difference between client-side
and server-side service discovery. What are the responsibilities
of each side?**

Client-side discovery: the client application contains a registry
client library. On startup, it downloads and caches the registry.
When making a service call, it queries its local cache for
healthy instances of the target service and applies client-side
load balancing (round-robin, least-connections) to select one.
Netflix Eureka + Ribbon is the classic implementation.

Responsibilities: the client code must include the discovery
library. The client manages cache staleness (periodic refresh).
The client implements load balancing. The client handles retries
when a selected instance is unavailable.

Server-side discovery: the client sends requests to a stable
address (VIP, DNS name, load balancer). A router/load balancer
queries the service registry and routes to a healthy instance.
Kubernetes Service + kube-proxy, AWS Elastic Load Balancer,
and HAProxy are examples.

Responsibilities: the client knows nothing about instances.
The load balancer/proxy handles discovery and routing. The
registry integration is in the infrastructure, not application code.

*What separates good from great:* Great candidates identify the
trade-off: "Client-side: the client has more control (custom
load balancing, affinity rules) but is more complex. Server-side:
simpler clients, but the load balancer is a potential SPOF and
must be highly available itself."

---

**Q2 (Conceptual): How does Kubernetes DNS-based service
discovery work? What does `kubectl get svc` show?**

Kubernetes DNS works as follows:

When you create a Service object (`kubectl apply -f service.yaml`),
Kubernetes allocates a stable ClusterIP (virtual IP) for the service.
CoreDNS (the cluster DNS) creates a DNS A record for the service:
`{service-name}.{namespace}.svc.cluster.local → ClusterIP`.

When a pod in the cluster resolves `orderservice.default.svc.cluster.local`:
CoreDNS returns the ClusterIP. The pod sends traffic to the ClusterIP.
kube-proxy (running on every node) intercepts the traffic to
the ClusterIP and forwards it to one of the pods in the service's
Endpoints list (healthy pods matching the service's selector).

`kubectl get svc` shows:
- NAME: the service name
- TYPE: ClusterIP (internal), NodePort, LoadBalancer, ExternalName
- CLUSTER-IP: the stable virtual IP
- EXTERNAL-IP: for LoadBalancer type, the cloud provider's external IP
- PORT(S): port mapping
- ENDPOINTS (visible with `kubectl get endpoints`): the actual pod IPs

*What separates good from great:* Great candidates distinguish
between the Service's ClusterIP (stable) and the pod IPs (ephemeral).
"The ClusterIP is a virtual IP - it has no interface on any node.
kube-proxy manages the iptables/IPVS rules that redirect traffic
from the ClusterIP to actual pod IPs. When pods die and new ones
start, kube-proxy updates the rules automatically."

---

**Q3 (Conceptual): What is a service registry's role in
health checking, and what is the difference between push-based
and pull-based health checking?**

The registry's health checking determines which registered
instances are currently healthy and eligible to receive traffic.

Pull-based health checking (Consul, Kubernetes readiness probes):
The registry periodically polls the registered instance's health
endpoint. HTTP GET → /health → 200 OK = healthy. The registry
initiates the check. If the instance is behind a firewall that
allows outbound but not inbound: pull-based does not work.

Push-based health checking (Eureka TTL heartbeat):
The instance sends periodic heartbeat messages to the registry.
`Alive at 10:00:00. Alive at 10:00:30. Alive at 10:01:00.`
If no heartbeat is received for > TTL: the instance is considered
dead and deregistered. The instance initiates the check.

Trade-off:
Pull-based: registry knows the health immediately (it initiates
the check). More accurate for detecting degraded responses (not
just "is the port open" but "does the health endpoint return OK").
Push-based: simpler for the instance (just send a heartbeat).
Works even when the registry cannot reach the instance. But: a
crashed instance cannot send heartbeats - deregistration waits
for TTL expiry.

*What separates good from great:* The TTL expiry delay insight.
"In Eureka with a 30-second heartbeat TTL: a crashed instance
may stay in the registry for up to 30 seconds (until the TTL
expires). Clients need retries to handle routing to a dead
instance during this window."

---

**Q4 (Trade-off): When would you choose Consul over Kubernetes
native service discovery?**

Kubernetes native service discovery (CoreDNS + Service objects)
is ideal when:
- All services are on a single Kubernetes cluster
- The environment is homogeneous (Kubernetes everywhere)
- The team is comfortable with Kubernetes operators

Consul is better when:
- Services span multiple Kubernetes clusters (multi-cluster)
- Some services are on VMs or bare metal (not on Kubernetes)
- You need cross-datacenter service discovery
- You need additional features: key-value store, distributed locks,
  health check with Consul health protocol
- You have existing Consul infrastructure from pre-Kubernetes era

Multi-cluster Kubernetes: Kubernetes itself does not natively
support cross-cluster service discovery. You must add a tool
(Istio federation, Consul Connect, or Submariner). Consul's
multi-datacenter federation is mature and well-tested.

*What separates good from great:* Stating that in a pure
Kubernetes environment, native tools are preferred (less to
operate). Consul is the right choice when heterogeneous
infrastructure (VMs + Kubernetes) exists.

---

**Q5 (Trade-off): What happens if the service registry becomes
unavailable? How should clients handle this?**

If the registry is unavailable:

Client-side discovery (Eureka): the client's local cache still
has the last-known instance list. The client can continue
routing to the cached instances. Eureka's self-preservation mode
explicitly prevents mass deregistration when registry nodes
cannot communicate. Clients degrade gracefully until the registry
recovers. New instances cannot register (they are invisible to
clients), but existing healthy instances continue to serve traffic.

Server-side discovery (Kubernetes kube-proxy): kube-proxy caches
iptables rules. If the etcd backend (Kubernetes control plane)
is unavailable, kube-proxy continues routing based on its
last-known iptables rules. Existing services continue working.
New pods or services cannot be programmed into kube-proxy until
etcd recovers.

The key design principle: service discovery should be in the
data path (routing traffic) only with a local cache, never
requiring a live query on every request. The registry is a
slow-path infrastructure component, not a fast-path component.

*What separates good from great:* The critical distinction.
"A service discovery lookup should NOT block the request. It
should return from a local cache. The cache is refreshed
asynchronously. A registry outage degrades the cache staleness
but does not stop traffic. This is the availability property
that makes Eureka, Consul, and Kubernetes viable in production."

---

**Q6 (Debugging): Service A is failing to connect to Service B.
Service B has 5 running instances. The error is
"Connection refused" on every request. How do you debug?**

Step 1: verify Service B instances are running:
`kubectl get pods -l app=service-b` - all 5 pods Running?

Step 2: verify the Kubernetes Service Endpoints:
`kubectl get endpoints service-b` - are pod IPs listed?
If not: Service selector does not match pod labels.

Step 3: test connectivity from Service A's pod:
`kubectl exec -it service-a-pod -- curl http://service-b/health`
If this works: Service B is reachable from within the cluster.

Step 4: check if Service B pods are passing readiness probes:
`kubectl describe pod service-b-pod-xxx` - check readiness
probe status. Pods failing readiness probes are removed from
Endpoints.

Step 5: check Network Policies: a NetworkPolicy might be blocking
Service A → Service B traffic.

Step 6: check if Service B is listening on the correct port:
`kubectl exec -it service-b-pod -- netstat -tlnp`.

Root causes in order of frequency:
1. Readiness probe failing (pod not in Endpoints)
2. Label selector mismatch (Service selector ≠ pod labels)
3. NetworkPolicy blocking traffic
4. Application not listening on declared port

*What separates good from great:* Starting with `kubectl get
endpoints` - this is the single most useful diagnostic. If the
Endpoints object is empty, no pods are healthy. If it has pods,
the issue is network-level (policies, firewalls).

---

**Q7 (Debugging): After a rolling deployment, some requests to
Service B are returning stale responses (from the old version).
Traffic continues to old pods even after new pods are ready.
How do you investigate?**

Old pods are still in the Endpoints list and receiving traffic.
Investigation:

1. Check pod status: `kubectl get pods -l app=service-b`.
   Are old pods in Terminating state? How long have they been
   terminating?

2. Check if old pods have graceful termination configured:
   `terminationGracePeriodSeconds`. If this is very long (300s),
   old pods serve traffic for up to 5 minutes after replacement.

3. Check if old pods' readiness probes are still passing:
   if the old pods are still "Ready," they remain in the
   Endpoints list and receive traffic.

4. Check the rolling deployment strategy: `maxSurge` and
   `maxUnavailable` - if set to allow old pods to run while
   new pods start, both versions receive traffic during the
   transition.

Fix: in the pod's preStop lifecycle hook, add a sleep or
deregister to allow kube-proxy to update routing rules before
termination begins. Ensure old pods fail their readiness probes
before the deployment proceeds (automated canary testing).

*What separates good from great:* Identifying the graceful
termination gap. "The `terminationGracePeriodSeconds` is how
long the pod waits before being force-killed. During this time,
if the pod is still Ready, it continues to receive traffic. A
preStop hook that fails the readiness probe first (removes the
pod from Endpoints) is the correct solution."

---

**Q8 (Behavioral): Tell me about a time you debugged a
service discovery issue in production.**

*(Personalize from experience.)*

Example structure: "We had a deployment where 10% of requests
to Service B were failing with 503. Service B had 10 pods,
all showing Running. The issue: two of the 10 pods were recently
rescheduled to new nodes and their readiness probes were
still in the initial delay period (30 seconds). During this
window, kube-proxy was still routing to these not-yet-ready
pods because the old pods (on those IPs) had just terminated
and the new pods had not yet passed readiness. Fixed by: (1)
setting `initialDelaySeconds` correctly to match actual startup
time, (2) adding `minReadySeconds` to the Deployment so new
pods must be ready for 10 seconds before the old ones terminate."

---

**Q9 (Scale): How does service discovery scale with hundreds
of services and thousands of instances?**

The scale challenge: with 200 services and 100 instances each
(20,000 pods), the registry must handle:
- 20,000 heartbeats per 30-second interval = ~667/second
- 20,000 health check queries per interval
- Client-side cache containing 20,000 entries, refreshed per service

Kubernetes scales well: etcd handles tens of thousands of
watch events efficiently. CoreDNS is designed for thousands
of resolutions per second (horizontally scalable).

Eureka at scale: each client caches the FULL registry. At 20,000
instances, each client's cache is significant. The Eureka server
must serve the full registry to every client on refresh. This
is a known Eureka scaling bottleneck. Mitigation: use
AWS Service Discovery (managed), Consul (more efficient client
updates via blocking queries), or migrate to Kubernetes-native.

Consul at scale: Consul uses the Raft consensus protocol in the
backend. The raft cluster (3-5 nodes) can handle thousands of
service registrations and queries efficiently. The xDS protocol
(used by Envoy/service mesh) provides streaming updates - clients
subscribe to changes rather than polling, reducing load at scale.

*What separates good from great:* The xDS protocol insight.
"Polling-based discovery does not scale well because every
client polls independently. Streaming-based discovery (xDS,
used by Envoy and Istio) pushes updates only when the state
changes. At 10,000 instances, there may be only 100 state
changes per minute - 100 pushes instead of 10,000 polls."

---

---

### 🚨 Failure Modes and Diagnosis

*(For Service Mesh and Sidecar Pattern)*

**mTLS certificate expiry causing service communication failures:**

Symptom: sudden increase in TLS handshake failures across
multiple service pairs. Error: `CERTIFICATE_VERIFY_FAILED` or
`PEER_NOT_AUTHENTICATED`.

Cause: workload certificates expired. Istio rotates certificates
every 24 hours by default, but if istiod is unavailable during
rotation, certificates expire.

Diagnosis: `openssl s_client -connect service-b-ip:port` to
inspect the certificate expiry. Check istiod logs for certificate
rotation errors.

Fix: restart istiod to trigger certificate re-issuance. For
immediate mitigation: temporarily disable mTLS for the affected
service pair (`PeerAuthentication` with `PERMISSIVE` mode).
Prevention: monitor certificate expiry, alert on < 1 hour remaining.

**Envoy sidecar causing unexpected request failures:**

Symptom: requests failing with HTTP 503 or connection errors
that do not correspond to any application-level error.

Cause: Envoy is applying a circuit breaker or retry policy that
is more aggressive than intended.

Diagnosis: `kubectl exec -it pod -- pilot-agent request GET stats`
to dump Envoy metrics. Look for `cx_overflow` (circuit breaker
open), `rq_retry` (retries in progress), `upstream_rq_5xx` (5xx
from upstream). These show whether Envoy is the one generating
the errors.

Fix: check DestinationRule for the target service. Reduce
`trafficPolicy.connectionPool.http.http1MaxPendingRequests`
if it is too low. Check `outlierDetection` settings - if they
are too aggressive, Envoy may be ejecting healthy endpoints.

---

### 🏛️ System Design

*(Omit: service mesh configuration is an infrastructure concern
within a microservices system. Full system design using service
mesh is covered in the L5 Global Scale and L5 Partition
Tolerance files which address multi-region architectures.)*

---

### 📊 Diagram

*(Omit: the service mesh data plane / control plane architecture
is described in the Concept Explanation. Visual diagrams are
available in the Istio official documentation and do not add
value over the textual description here.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): Explain the data plane and control plane
separation in a service mesh. What does each component do?**

Data plane: the collection of all Envoy sidecar proxies deployed
alongside each service. The data plane handles the ACTUAL traffic
flow: forwarding requests, applying policies, encrypting with
mTLS, collecting metrics, injecting trace headers. Each Envoy
is stateful (has cached routing rules and TLS certificates) and
can operate independently if the control plane becomes unavailable.

Control plane (Istio's istiod): the centralized component that
configures all Envoy proxies. It: (1) distributes routing
configurations (VirtualService rules, DestinationRule settings)
to Envoy via the xDS protocol. (2) Issues TLS certificates to
all workloads (SPIFFE/SVID identity). (3) Provides service
discovery information to Envoy. (4) Converts Istio custom
resources (VirtualService, DestinationRule) into Envoy configuration.

The separation enables resilience: if istiod crashes, existing
traffic continues flowing (Envoy uses its cached config). New
config changes cannot be applied, but the current config
remains operational.

*What separates good from great:* The resilience implication.
"A common misconception: if istiod is down, the mesh stops working.
Wrong. istiod is a configuration distribution system, not a
traffic forwarding system. Traffic flows through Envoy (data plane)
regardless of istiod availability. Only config changes are blocked."

---

**Q2 (Conceptual): What is the xDS protocol used by Istio and
Envoy? Why does it matter for service mesh scale?**

xDS is a family of discovery services used by the Istio control
plane to push configurations to Envoy proxies:
- LDS (Listener Discovery Service): listeners on ports
- RDS (Route Discovery Service): HTTP routing rules
- CDS (Cluster Discovery Service): upstream service clusters
- EDS (Endpoint Discovery Service): IP addresses of instances

Instead of Envoy polling the control plane periodically:
xDS uses a streaming gRPC connection. Envoy subscribes to
configuration changes. istiod pushes updates only when the
configuration changes. This is a push model.

Why it matters for scale: at 10,000 Envoy sidecars, a polling
model would require 10,000 × polling_interval queries per second.
With xDS streaming: 10,000 open gRPC streams. Updates are pushed
only when something changes (new deployment, policy update).
The control plane sends each update once; all 10,000 Envoys
receive it via their streaming connection.

*What separates good from great:* Connecting xDS to the Envoy
architectural philosophy. "Envoy was designed from the start
for dynamic configuration via xDS. This is fundamentally different
from Nginx or HAProxy which require config file reload. Envoy
can update routing rules in milliseconds without restart."

---

**Q3 (Conceptual): How does Istio implement mutual TLS without
any application code changes?**

Istio uses SPIFFE (Secure Production Identity Framework for
Everyone) to provide workload identity:

1. istiod acts as a certificate authority (CA).
2. When a pod is created, the Envoy sidecar requests a
   certificate from istiod. The certificate contains a SPIFFE
   URI encoding the pod's identity:
   `spiffe://cluster.local/ns/default/sa/orderservice`.
3. istiod validates the request (Kubernetes Service Account
   token) and issues a short-lived certificate (default: 24h).
4. When Service A's Envoy connects to Service B's Envoy:
   it presents its certificate. Service B's Envoy validates
   the certificate. Both verify: "Is this the identity I expect
   to talk to?"
5. All of this happens at the Envoy-to-Envoy level. The
   application container never sees the TLS layer.

The application container sends plain HTTP. Envoy intercepts
the traffic, wraps it in mTLS, sends to the peer Envoy, which
unwraps mTLS and delivers plain HTTP to the destination container.

*What separates good from great:* The SPIFFE identity model.
"The application does not need to manage TLS certificates.
Envoy handles certificate acquisition, rotation, and verification.
The workload identity is derived from the Kubernetes Service
Account - no secrets to manage."

---

**Q4 (Trade-off): What are the production trade-offs of using
Istio vs. using a library like Resilience4j for resilience?**

Istio advantages:
- Polyglot: works for any language without library changes
- Centralized policy: one YAML change affects all services
  simultaneously (e.g., global timeout change)
- Automatic mTLS: security without code
- Automatic distributed tracing: no code instrumentation needed
- Canary deployment: traffic split without feature flags

Resilience4j advantages:
- Per-service control: each service configures its own circuit
  breaker based on its specific needs
- Better observability: Spring Actuator exposes CB state as
  a named metric; Istio's Envoy CB state requires Envoy stats
  query
- No sidecar latency overhead: direct call, no proxy
- Simpler debugging: is it the app or the proxy?
- Retry semantics: application can decide NOT to retry
  a specific type of request (payment charges); Istio
  retries all 503s uniformly

Recommendation: use Istio for mTLS (zero-code security) and
observability (distributed tracing). Use Resilience4j for
application-specific resilience (nuanced retry and CB logic).

*What separates good from great:* The "don't retry payment charges"
insight. "Istio's retry policy is coarse: retry on 503. An
application that charges a payment card should NOT retry on 503
- the charge might have succeeded but the response was lost.
Application-level code can make this nuanced decision; Istio cannot."

---

**Q5 (Trade-off): When would you choose Linkerd over Istio?**

Linkerd advantages over Istio:
- Simpler: Linkerd's control plane has fewer components (one
  binary: `linkerd-control-plane`). Istio has 6+ components.
- Lower resource usage: Linkerd's proxy (written in Rust) uses
  significantly less CPU and memory than Envoy.
- Faster installation and simpler configuration: no CRDs required
  for basic operation; defaults are sensible.
- Better multi-tenancy: Linkerd policies are more intuitive.

Istio advantages over Linkerd:
- More features: advanced traffic management (header-based routing,
  fault injection, traffic mirroring), gateway functionality
- Envoy is more mature and extensible (WASM plugins)
- Larger ecosystem: more third-party integrations

Choose Linkerd when: operational simplicity is paramount,
resource efficiency matters (high pod density), the team is not
a dedicated platform team (Linkerd is more approachable).

Choose Istio when: advanced traffic management features are
needed, the team has Kubernetes platform expertise, the
ecosystem integrations (Envoy WASM, external tooling) are important.

*What separates good from great:* Knowing that Linkerd uses a
Rust-based proxy (not Envoy). "Linkerd's proxy was purpose-built
for simplicity. Envoy is a general-purpose proxy with much more
capability but also much more complexity to configure."

---

**Q6 (Debugging): Envoy sidecar injection is not happening
for new pods in the 'production' namespace. How do you
investigate?**

Envoy injection requires the namespace to be labeled for injection
AND the pod to not opt out.

Step 1: check namespace label:
`kubectl get namespace production --show-labels`
Expected: `istio-injection=enabled`. If missing: add the label.

Step 2: check if the `MutatingWebhookConfiguration` is healthy:
`kubectl get mutatingwebhookconfigurations istio-sidecar-injector`
Check the `clientConfig.service.namespace` - does it point to
the correct Istio namespace? Check the webhook's `namespaceSelector`
- does it match the `istio-injection=enabled` label?

Step 3: check istiod logs for injection errors:
`kubectl logs -n istio-system deploy/istiod`

Step 4: check if the pod has the opt-out annotation:
`sidecar.istio.io/inject: "false"` - this disables injection
for specific pods.

Step 5: check Kubernetes admission webhook connectivity:
the API server must reach the istiod webhook service. If istiod
pods are down or the service is unavailable: injection fails.

Root cause ordering: missing namespace label (most common),
istiod down, webhook misconfigured.

*What separates good from great:* Knowing that Kubernetes admission
webhooks are synchronous: every pod creation waits for the webhook
response. If istiod is unavailable, pod creation fails (if
`failurePolicy: Fail`) or proceeds without injection (if
`failurePolicy: Ignore`). This is a critical availability
consideration for the mesh control plane.

---

**Q7 (Debugging): After an Istio upgrade, services are seeing
50x traffic increase in latency. How do you isolate whether
the issue is in the application or in Envoy?**

Isolate by comparing latency with and without Envoy:

1. **Check Envoy stats:** `kubectl exec pod -c istio-proxy --
   pilot-agent request GET stats | grep downstream_rq_time`.
   This shows time from Envoy receiving the request to sending
   the response. Compare to known baseline.

2. **Check the Envoy access log:**
   `kubectl logs pod -c istio-proxy`
   Look at `duration` field in the JSON access logs.
   If Envoy's logged duration is high: the delay is in Envoy
   (waiting for upstream). If Envoy's duration is normal but
   the application reports high latency: the delay is after
   Envoy (in the application container).

3. **Check for changed outlier detection settings:** the Istio
   upgrade may have changed default DestinationRule settings.
   A tighter outlier detection policy might be ejecting healthy
   endpoints, reducing the available pool and increasing load
   on remaining endpoints.

4. **Check for changed connection pool settings:**
   if `http.http1MaxPendingRequests` was reduced in defaults,
   more requests queue in Envoy.

Fix: review the Istio upgrade release notes for changed defaults.
Override the affected settings in DestinationRule to match
pre-upgrade behavior.

*What separates good from great:* Knowing the `istio-proxy`
container's stats endpoint. "Every Envoy sidecar exposes a
stats endpoint. It is the primary debugging tool for service
mesh issues - far more useful than application logs when
the issue is at the proxy level."

---

**Q8 (Behavioral): Tell me about a challenge you faced when
adopting a service mesh (or similar infrastructure layer).**

*(Personalize from experience.)*

Example structure: "When we adopted Istio, our payment service
saw occasional 504 errors. Investigation revealed that Istio's
default retry policy was retrying on 503 errors. Our payment
provider sometimes returns 503 temporarily. Istio retried these
and the payment was processed twice. We fixed this by adding an
explicit VirtualService that disabled retries for the payment
service route. The lesson: service mesh defaults are designed
for stateless services. For services with side effects (payments,
emails), review and explicitly configure the retry policy to be
conservative."

---

**Q9 (Scale): How does a service mesh perform at 500 services
and 10,000 instances?**

Control plane scaling at this size:
- istiod manages 10,000 Envoy sidecar connections via xDS
- Each xDS stream holds the connection open and receives push
  updates. istiod's memory usage is dominated by the number
  of active xDS streams.
- At 10,000 streams: istiod needs ~10GB memory (roughly
  1MB per stream for configuration state). Deploy istiod
  with adequate resources.

Data plane overhead:
- 10,000 Envoy sidecars, each processing service-to-service
  traffic at ~2-5ms latency added per hop
- Envoy's resource usage: ~100m CPU, 100Mi memory per sidecar
  = ~1,000 CPUs and 1TB memory for the entire fleet

Optimization for scale:
1. Sidecar scope configuration: by default, Envoy knows about
   ALL services in the cluster (receives all CDS/EDS updates).
   At 500 services, this is a large config. Use `Sidecar`
   resource to limit each service's Envoy to only know about
   the services it actually calls.

2. Split the mesh: separate large namespaces into separate
   Istio installations with cross-mesh federation.

3. Control plane horizontal scaling: run multiple istiod
   replicas. Envoys connect to any istiod replica.

*What separates good from great:* The `Sidecar` scope optimization
is an expert-level insight. "Without Sidecar scope, every Envoy
downloads configuration for all 500 services. With Sidecar scope,
each Envoy only downloads config for the 5-10 services it calls.
This reduces control plane load by 98% at large scale."
