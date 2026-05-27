---
layout: default
title: "Kubernetes - META Patterns"
parent: "Kubernetes"
grand_parent: "SK Interview"
nav_order: 10
permalink: /kubernetes/meta-patterns/
---

# Kubernetes Resource Sizing Framework

🎯 Interview Weight: very high - Resource sizing is the single
most impactful Kubernetes operational decision. Expected at
senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes resource sizing: set requests = what the pod
> normally needs (used for scheduling and QoS), set limits =
> what the pod must never exceed (prevents runaway usage).
> Rule of thumb: requests = P50 usage, limits = P99 usage.
> Java services: right-size JVM heap + budget off-heap memory.
> Never omit requests (pod gets BestEffort QoS, evicted first).
> Never over-provision requests (wastes node capacity).

**3 minutes (Senior):**
> The complete resource sizing framework:
>
> Step 1 - Measure actual usage:
> Run the service under production-representative load.
> Collect: `container_memory_working_set_bytes` and
> `container_cpu_usage_seconds_total` from Prometheus/cAdvisor.
> Key percentiles: P50 (normal), P95 (high load), P99 (spikes).
>
> Step 2 - Set requests:
> CPU requests = P50 CPU usage. Sets the scheduler's view
> of capacity. Does NOT limit CPU (CPU is compressible - pods
> throttled but not killed if they exceed CPU limits).
> Memory requests = P75 memory usage. Sets eviction priority.
>
> Step 3 - Set limits:
> CPU limits = P95-P99. High CPU limits allow bursting without
> throttling. But: too high = CPU starvation for other pods.
> Memory limits = P99 + safety buffer (10-20%).
> Guarantee: memory usage MUST stay below limit or OOMKilled.
> Java: limit = Xmx + Metaspace + DirectMemory + threads + 100MB.
>
> Step 4 - QoS class selection:
> Guaranteed (requests = limits): pod never evicted under
> node pressure. Use for production services.
> Burstable (requests < limits): can burst up to limit.
> Evicted before Guaranteed under pressure. Use for dev/batch.
> BestEffort (no requests/limits): evicted first. Never use
> for production.
>
> Vertical Pod Autoscaler (VPA):
> VPA recommendation mode observes usage and suggests adjustments.
> Review VPA recommendations weekly. Apply manually (NOT in
> Auto mode - auto-evicts pods for resize, causes disruptions).
>
> Sizing gotchas:
> CPU throttling: if CPU limit = 500m but usage spikes to 700m
> for 100ms, the pod is throttled. Latency spikes. Fix: set
> higher CPU limits or remove CPU limits for latency-sensitive
> services (let CPU requests handle scheduling).
> JVM heap resizing: if Xms < Xmx, JVM dynamically resizes
> heap (GC pauses). For predictable memory: set Xms = Xmx.

**Blank Mind Recovery:**

**(1) Restate:** "Requests = P50 usage (for scheduling).
Limits = P99 + buffer (for safety). Guaranteed QoS = requests = limits."

---

### ⚖️ Comparison Table

| QoS Class | Requests | Limits | Eviction Priority | Use Case |
|-----------|----------|--------|------------------|---------|
| Guaranteed | Set | = Requests | Last | Production services |
| Burstable | Set | > Requests | Middle | Dev, non-critical |
| BestEffort | Not set | Not set | First | Never in production |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Requests vs limits + QoS classes |
| Senior | 8 min | Java memory budget + CPU throttling + VPA |
| Staff | 12 min | Production sizing methodology + cost optimization |

---

---

# Kubernetes Troubleshooting Mental Model

🎯 Interview Weight: very high - A structured mental model is
what distinguishes engineers who debug K8s efficiently from
those who thrash. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> The Kubernetes troubleshooting mental model: work top-down
> through the stack. Start at the symptom (user-visible failure),
> then identify which layer is responsible: application layer
> (pod logs, JVM errors), Kubernetes layer (scheduling, probe
> failures, resource limits), networking layer (DNS, service
> endpoints, NetworkPolicy), infrastructure layer (node health,
> storage, cloud provider).

**3 minutes (Senior):**
> Structured Kubernetes troubleshooting:
>
> Layer 1 - Symptom identification:
> - Service returns errors: which errors? 503, 500, timeout?
> - Pod restarts: OOMKilled or crash?
> - Deployment stuck: Pending or rollout not completing?
> - Latency increase: within the pod or in the network path?
>
> Layer 2 - Pod health:
> `kubectl get pods` -> phase, status, age, restarts.
> Status dictionary:
> CrashLoopBackOff: pod crashes on start, K8s backs off retries.
> OOMKilled: memory limit exceeded.
> ImagePullBackOff: cannot pull image (registry credentials).
> Pending: no node can schedule the pod.
> ContainerCreating: waiting for volumes, secrets, configmaps.
> Terminating: stuck deletion (finalizer not removed).
>
> Layer 3 - Events and configuration:
> `kubectl describe pod` - events are the most valuable section.
> Common events:
> "failed to fit in any node" -> resource/affinity issue.
> "Back-off pulling image" -> registry auth failure.
> "Readiness probe failed" -> app not healthy.
> "Container killed" -> OOMKilled.
>
> Layer 4 - Application logs:
> `kubectl logs <pod> --previous` for crashed containers.
> Look for: exception stack traces, configuration errors,
> connection refused (DB, Redis, Kafka not reachable),
> startup failure (environment variable missing).
>
> Layer 5 - Network:
> `kubectl get endpoints <svc>` - is traffic routable?
> `kubectl run debug...` - test DNS and HTTP connectivity.
> Check NetworkPolicy if connectivity fails.
>
> Layer 6 - Node health:
> `kubectl describe node` - check MemoryPressure, DiskPressure,
> PIDPressure conditions.
> `kubectl top nodes` - CPU/memory usage.
> Node issues affect all pods on that node.
>
> Meta-skill: read the events in `kubectl describe` before
> guessing. The events almost always contain the diagnosis.

**Blank Mind Recovery:**

**(1) Restate:** "Debug K8s top-down: symptom -> pod status ->
events -> logs -> network -> node."

---

### 💻 Code Example

```
Kubernetes Troubleshooting Decision Tree

  Service returning 503?
  ├── kubectl get pods → not Running?
  │   ├── Pending → kubectl describe pod (scheduling)
  │   │   ├── "Insufficient cpu/memory" → resize or add nodes
  │   │   ├── "Taint not tolerated" → add toleration
  │   │   └── "No affinity match" → fix node labels
  │   ├── CrashLoopBackOff → kubectl logs --previous
  │   │   ├── OOM / heap error → increase memory limit
  │   │   ├── Config error → check env vars, secrets
  │   │   └── App crash → fix application bug
  │   └── Terminating stuck → check finalizers
  ├── kubectl get endpoints svc → empty?
  │   ├── Labels mismatch → fix selector or pod labels
  │   └── Pods not Ready → fix readiness probe
  └── pods Running, endpoints OK → network issue
      ├── kubectl run dns-test → nslookup fails?
      │   └── CoreDNS down → fix CoreDNS pods
      └── curl fails → check NetworkPolicy
```

> **Diagram walkthrough:** The tree starts at the user-visible
> symptom (503) and branches based on observable facts, not
> guesses. Each node requires one `kubectl` command to decide
> direction. This approach avoids the common anti-pattern of
> randomly checking logs before understanding whether the pod
> is even running. The decision tree is deterministic - every
> K8s service outage can be diagnosed within 3-5 commands
> using this model.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Status dictionary + describe events |
| Senior | 8 min | Full layer model + networking diagnosis |
| Staff | 12 min | Systematic methodology + team coaching |

**[DEBUGGING] Your service is returning 503 errors in production.
How do you diagnose in the next 5 minutes?**
`[SENIOR]`

*Why they ask:* Tests structured debugging under pressure. This
is the most common K8s production scenario.

*Likely follow-up:* "Pods are Running and endpoints are correct,
but still getting 503."

First 60 seconds: establish scope.
`kubectl get pods -n prod` - how many pods are unhealthy?
All pods down = infrastructure issue. Subset of pods = rolling
failure. Zero unhealthy pods = the problem is elsewhere
(network, downstream dependency).

Next 60 seconds: check pod state.
If CrashLoopBackOff: `kubectl logs <pod> --previous`.
If OOMKilled: memory limit too low.
If Pending: check scheduling.

Next 60 seconds: check service routing.
`kubectl get endpoints my-service -n prod`.
If empty: no pods selected (check pod readiness and labels).
If populated: kube-proxy should be routing correctly.

Next 60 seconds: test connectivity.
Port-forward to one pod directly:
`kubectl port-forward <pod> 8080:8080 -n prod`.
`curl localhost:8080/health`.
If this succeeds: the problem is in the service layer or
load balancer, not the pod.
If this fails: pod is not healthy.

Next 60 seconds: check upstream.
Is the problem in an upstream dependency?
`kubectl logs <pod> -n prod --tail=50` - look for connection
refused, timeout to DB, Kafka, Redis.
If DB connection failed: the pod is healthy but its dependencies
are not. The 503 is from the readiness probe correctly
marking the pod as not ready.

*What separates good from great:* The disciplined top-down
approach. Not looking at logs first (common mistake). Establishing
scope (all vs some pods) before diving deep.

---

---

# Container Orchestration Decision Model

🎯 Interview Weight: high - Knowing when to use Kubernetes
vs alternatives demonstrates architectural maturity.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes is the right choice when: you need to run 10+
> microservices, require automated scaling, rolling deployments,
> and self-healing. It is NOT the right choice for: single-service
> applications (use Docker Compose or ECS), serverless workloads
> (use Lambda/Cloud Run), or teams without Kubernetes expertise
> (the operational overhead is significant). The rule: do you
> need orchestration, or do you need a cloud service that does
> it for you?

**3 minutes (Senior):**
> Container orchestration decision framework:
>
> Use Kubernetes when:
> - 10+ microservices with independent deployment cycles.
> - Multi-cloud or on-premises requirement (K8s is portable).
> - Complex traffic routing (A/B testing, canary, circuit breaking).
> - Mixed workload types (stateless services + stateful databases
>   + batch jobs + cron jobs) on shared infrastructure.
> - Team size > 20 engineers (investment in K8s expertise amortizes).
> - Compliance requires container isolation and network policies.
>
> Use ECS / App Engine / Cloud Run instead when:
> - Small microservices footprint (2-5 services).
> - Team is small (< 10 engineers), operational overhead of K8s
>   is not worth it.
> - Single cloud deployment (no multi-cloud requirement).
> - Serverless autoscaling is preferred (scale to zero, instant).
>
> Use Docker Compose when:
> - Local development only.
> - Simple single-server deployments (dev/staging environments).
> - Not a production orchestration tool (no health checks,
>   no cross-node networking).
>
> Managed Kubernetes (EKS, GKE, AKS) vs self-managed:
> Self-managed: full control (air-gapped environments, edge).
> Cost: significant ops time for etcd management, upgrades,
> certificate rotation, node provisioning.
> Managed: control plane is the cloud provider's responsibility.
> Focus on workloads, not cluster infrastructure.
> Verdict: always use managed K8s unless regulations require
> self-managed (e.g., government / classified environments).
>
> K8s simplification options:
> OpenShift: enterprise K8s with opinionated defaults.
> k3s: lightweight K8s for edge and IoT.
> Rancher: multi-cluster management with UI.
>
> The anti-pattern: Kubernetes as a hammer.
> Using K8s for a single monolith that could run on a single
> server (or managed container service) is over-engineering.
> K8s overhead: 3+ nodes, etcd, control plane, CNI plugin,
> monitoring stack - for a service that needs 1 container.

**Blank Mind Recovery:**

**(1) Restate:** "Use K8s for 10+ services, multi-cloud, mixed
workloads. Use managed services for small footprints. Avoid K8s for single apps."

---

### ⚖️ Comparison Table

| Platform | Complexity | Portability | Scale | Cost | Best For |
|----------|-----------|------------|-------|------|---------|
| Docker Compose | Low | Single host | Low | Free | Local dev |
| ECS/Fargate | Low | AWS only | Medium | Low | Small AWS apps |
| Cloud Run | Very low | GCP only | Auto | Low | Stateless functions |
| Kubernetes (Managed) | High | Multi-cloud | High | Medium | Large microservices |
| Kubernetes (Self) | Very high | Any | High | High | Regulated/edge |
| OpenShift | High | Hybrid | High | High | Enterprise |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | When to use K8s vs alternatives |
| Staff | 8 min | TCO analysis + managed vs self-managed |

**[TRADE-OFF] A startup with 3 services asks whether to use
Kubernetes. What do you recommend and why?**
`[SENIOR]`

*Why they ask:* Tests judgment - not just K8s knowledge but
when NOT to use it. Over-engineering is a real risk.

*Likely follow-up:* "What if they say they plan to grow to 50 services in 2 years?"

For a startup with 3 services today: do NOT use Kubernetes.
The cognitive overhead of Kubernetes - managing clusters,
configuring probes, setting resource limits, handling upgrades,
monitoring etcd health - is a significant tax on a small team.
For 3 services, use ECS Fargate (AWS) or Cloud Run (GCP):
managed autoscaling, no cluster to maintain, pay per request.
Lower DevOps overhead = more time building product.

The 2-year growth argument:
"We'll grow to 50 services" is a common justification.
Counter: migration to K8s from ECS/Cloud Run at 50 services
is straightforward (containers are portable). Migration from
a monolith is harder. Start with the platform that matches
today's complexity. Migrate when you have the scale to
justify it.

When to start K8s early for a startup:
If the team already has K8s expertise (no learning curve).
If they need on-premises deployment (ECS/Cloud Run = cloud-only).
If they have strict multi-cloud requirements from day one.
If they have more than 5 services with complex inter-service
traffic routing requirements.

*What separates good from great:* The ability to argue against
Kubernetes when it is not the right tool - not every problem
is a K8s problem.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Resource sizing methodology + troubleshooting model |
| Staff/Principal | Platform decision framework + make vs buy |
| Bar Raiser | Systematic debugging under pressure + architectural judgment |
