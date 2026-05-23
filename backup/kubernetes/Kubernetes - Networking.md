---
layout: default
title: "Kubernetes - Networking"
parent: "Kubernetes"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/kubernetes/networking/
topic: Kubernetes
subtopic: Networking
keywords:
  - Kubernetes Networking
  - Service
  - Ingress
  - Network Policy
  - DNS in Kubernetes
  - Service Mesh
difficulty_range: hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Kubernetes Networking](#kubernetes-networking)
- [Service](#service)
- [Ingress](#ingress)
- [Network Policy](#network-policy)
- [DNS in Kubernetes](#dns-in-kubernetes)
- [Service Mesh](#service-mesh)

# Kubernetes Networking

**TL;DR** - Kubernetes networking follows a flat model where every pod gets a unique IP, all pods can reach all other pods without NAT, and Services/Ingress provide stable endpoints and external access.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Containers on different nodes can't communicate. Pod IPs are ephemeral and unpredictable. External traffic has no way in. Without a networking model, your distributed system is just isolated containers.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes defined its networking model."
---

### 📘 Textbook Definition

Kubernetes networking implements a flat network model with three fundamental requirements: (1) every pod gets a unique IP, (2) all pods can communicate with all other pods without NAT, (3) the IP a pod sees itself as is the same IP others use to reach it. This is implemented by CNI (Container Network Interface) plugins.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Every pod gets an IP, every pod can reach every other pod - flat and simple.

**One analogy:**

> K8s networking is like a corporate phone system. Every employee (pod) gets a direct extension (IP). Anyone can call anyone else directly (pod-to-pod). The receptionist (Service) provides a stable main number that routes to any available employee. The building address (Ingress) is how outsiders reach the company.

**One insight:**
The flat networking model means NO NAT between pods. Pod A on Node 1 reaches Pod B on Node 2 directly by IP. This simplifies application networking - no port mapping, no address translation. The complexity is pushed to the CNI plugin (Calico, Cilium, Flannel).
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
K8s Networking Model:

Node 1 (10.0.1.1)              Node 2 (10.0.2.1)
+-----------------------+       +-----------------------+
| Pod A: 10.244.1.5    |       | Pod C: 10.244.2.3    |
| Pod B: 10.244.1.6    |       | Pod D: 10.244.2.4    |
+-----------+-----------+       +-----------+-----------+
            |                               |
            +---------- Overlay/BGP --------+
            (Calico, Cilium, Flannel, etc.)

Pod A (10.244.1.5) -> Pod C (10.244.2.3)
  Direct communication, no NAT, no port mapping

Four networking problems K8s solves:
  1. Container-to-Container: localhost (same pod)
  2. Pod-to-Pod: flat network (CNI plugin)
  3. Pod-to-Service: kube-proxy (iptables/IPVS)
  4. External-to-Service: Ingress/LoadBalancer
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Flat network: every pod gets a unique cluster-wide IP, all pods reach all pods without NAT
2. CNI plugins implement the actual networking (Calico=BGP/eBPF, Cilium=eBPF, Flannel=VXLAN overlay)
3. Services provide stable endpoints; Ingress provides external HTTP routing; Network Policies provide firewall rules

**Interview one-liner:**
"Kubernetes mandates a flat network where every pod gets a unique IP reachable by all other pods without NAT - implemented by CNI plugins (Calico, Cilium), with Services for stable internal endpoints, Ingress for external HTTP routing, and Network Policies for microsegmentation."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Kubernetes Networking. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Compare Calico, Cilium, and Flannel. How do you choose a CNI?**

_Why they ask:_ Tests practical infrastructure decision-making.

**Answer:**
| Feature | Flannel | Calico | Cilium |
|---------|---------|--------|--------|
| Complexity | Low | Medium | High |
| Performance | Good (VXLAN) | Best (BGP, no overlay) | Best (eBPF) |
| Network Policy | No | Yes (L3/L4) | Yes (L3/L4/L7) |
| Observability | Basic | Good | Best (Hubble) |
| Use case | Dev/small clusters | Production standard | Large/advanced |

Decision:

- **Flannel**: development, small clusters, simplicity priority
- **Calico**: production standard, need Network Policies, proven at scale
- **Cilium**: advanced requirements (L7 policies, service mesh replacement, eBPF observability)
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Service

**TL;DR** - A Kubernetes Service provides a stable network endpoint (ClusterIP, NodePort, or LoadBalancer) that load-balances traffic to a dynamic set of pods selected by labels, decoupling clients from pod lifecycle.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Pod IPs change on every restart. Your frontend hardcodes `10.244.1.5:8080` to reach the backend. Backend pod restarts with IP `10.244.2.3`. Frontend breaks. With 10 backend replicas, which IP do you use? How do you load balance?

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes Services were created."
---

### 📘 Textbook Definition

A Kubernetes Service is an abstraction that defines a logical set of Pods (determined by a label selector) and a policy for accessing them - providing a stable virtual IP (ClusterIP), DNS name, and load balancing across the set of matching pods.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A Service is a stable name and IP that routes traffic to whichever pods match its selector.

**One analogy:**

> A Service is like a phone number for a department (not a person). You call "customer service" (Service IP/DNS). The phone system (kube-proxy) routes to any available agent (pod). Agents come and go, but the phone number stays the same.

**One insight:**
Services select pods by LABELS. Any pod with matching labels gets traffic, regardless of which Deployment created it. This is powerful (canary deployments) but also dangerous (mislabeled pods accidentally join a service).
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
# ClusterIP Service (internal)
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80         # Service port
      targetPort: 8080 # Container port
      protocol: TCP

# NodePort (external via node IP)
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080  # Every node opens this port

# LoadBalancer (cloud LB provisioned)
spec:
  type: LoadBalancer
  # Cloud controller creates ELB/ALB/NLB
```

```
Service types:
  ClusterIP:    Internal only (default)
                10.96.0.100:80 -> pods
  NodePort:     Every node opens a port
                <NodeIP>:30080 -> pods
  LoadBalancer: Cloud LB -> NodePort -> pods
                my-lb.amazonaws.com:80 -> pods
  Headless:     No ClusterIP (clusterIP: None)
                DNS returns pod IPs directly
                (for StatefulSets, client-side LB)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```bash
# Create service
kubectl expose deployment backend --port=80 \
  --target-port=8080 --type=ClusterIP

# Get service details
kubectl get svc backend
# NAME      TYPE        CLUSTER-IP     PORT(S)
# backend   ClusterIP   10.96.0.100   80/TCP

# DNS name (from any pod in cluster):
# backend.default.svc.cluster.local
# Or just: backend (same namespace)

# Check endpoints (which pods have traffic)
kubectl get endpoints backend
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. ClusterIP (internal), NodePort (all nodes), LoadBalancer (cloud LB) - choose based on access pattern
2. Services select pods by LABEL, not by Deployment name - matching labels = gets traffic
3. DNS: `<service>.<namespace>.svc.cluster.local` - usually just `<service>` within same namespace

**Interview one-liner:**
"A Service provides a stable ClusterIP and DNS name that load-balances to pods matching its label selector via kube-proxy (iptables/IPVS) - decoupling clients from ephemeral pod IPs and enabling service discovery through CoreDNS."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Service. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: When do you use ClusterIP vs NodePort vs LoadBalancer vs Ingress?**

_Why they ask:_ Tests practical architecture decisions.

**Answer:**
| Type | Scope | Use Case |
|------|-------|----------|
| ClusterIP | Internal only | Service-to-service communication |
| NodePort | External (basic) | Development, non-cloud environments |
| LoadBalancer | External (cloud) | Single service needing external access |
| Ingress | External (HTTP) | Multiple services, path/host routing |

Decision:

- **Internal microservice**: ClusterIP (always)
- **Single external service**: LoadBalancer (simple, gets own IP/DNS)
- **Multiple HTTP services on one domain**: Ingress (path-based routing, TLS termination, one LB for many services)
- **On-premises/bare-metal**: MetalLB + Ingress or NodePort + external LB

Cost consideration: Each LoadBalancer Service creates a cloud LB ($20-50/month). With 20 services, that's $400-1000/month just for LBs. Ingress uses ONE LB for all services ($20-50 total + Ingress controller).
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Ingress

**TL;DR** - Ingress provides HTTP/HTTPS routing from external traffic to internal Services based on hostnames and paths, acting as a reverse proxy/load balancer controlled by Kubernetes resources.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Each service needing external access requires its own LoadBalancer (expensive). No path-based routing (api.example.com/users vs api.example.com/products going to different services). No TLS termination at cluster level.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes Ingress was created."
---

### 📘 Textbook Definition

An Ingress is a Kubernetes API object that manages external HTTP/HTTPS access to services within a cluster, providing URL-based routing, TLS termination, and name-based virtual hosting. It requires an Ingress Controller (nginx, Traefik, ALB) to implement the actual routing.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: tls-secret
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /users
            pathType: Prefix
            backend:
              service:
                name: user-service
                port:
                  number: 80
          - path: /products
            pathType: Prefix
            backend:
              service:
                name: product-service
                port:
                  number: 80
```

```
Traffic flow:
  Client -> DNS -> LoadBalancer (cloud)
    -> Ingress Controller (nginx/traefik pod)
      -> Routing by host/path
        -> /users   -> user-service -> user pods
        -> /products -> product-service -> product pods

  One LB for ALL services (vs one per service)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Ingress = HTTP routing rules. Ingress Controller = actual reverse proxy implementing those rules (nginx, Traefik, ALB)
2. One Ingress can route to many services (path-based: /api/\*, host-based: api.example.com)
3. Handles TLS termination centrally - one cert managed in one place instead of per-service

**Interview one-liner:**
"Ingress provides declarative HTTP routing (host/path-based) from external traffic to internal Services, implemented by an Ingress Controller like nginx or ALB - enabling TLS termination, virtual hosting, and one load balancer for many services instead of one per service."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Ingress. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Network Policy

**TL;DR** - Network Policies are Kubernetes firewall rules that control pod-to-pod and pod-to-external traffic at L3/L4, implementing microsegmentation and zero-trust networking within the cluster.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
By default, every pod can reach every other pod in the cluster. A compromised frontend pod can directly access the database, admin services, and other namespaces. Lateral movement is trivial.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes Network Policies were created."
---

### 📘 Textbook Definition

A NetworkPolicy is a Kubernetes resource that specifies how groups of pods are allowed to communicate with each other and with other network endpoints. By default all traffic is allowed; once a NetworkPolicy selects a pod, only traffic explicitly allowed by policies is permitted.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
# Only allow traffic from frontend to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080

---
# Default deny all ingress in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {} # All pods
  policyTypes:
    - Ingress
  # No ingress rules = deny all
```

```
Default (no policy):    All traffic allowed
With default-deny:      Nothing allowed
Add specific policies:  Only listed traffic allowed

Example architecture:
  [internet] -> [frontend] -> [backend] -> [database]
                     |              |            |
  Policy: allow     Policy: allow  Policy: allow
  from internet     from frontend  from backend only
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Default K8s = allow all traffic. Network Policies add restrictions (deny by default, allow specific)
2. Requires CNI that supports Network Policy (Calico, Cilium - NOT Flannel alone)
3. Best practice: default-deny all in namespace, then explicitly allow required communication paths

**Interview one-liner:**
"Network Policies implement microsegmentation - by default K8s allows all pod-to-pod traffic, so I apply default-deny policies per namespace and explicitly whitelist required communication paths, enforced by CNI plugins like Calico or Cilium."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Network Policy. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# DNS in Kubernetes

**TL;DR** - CoreDNS provides service discovery in Kubernetes by resolving Service names to ClusterIPs and pod hostnames to pod IPs, with predictable naming conventions for all cluster resources.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Pods would need to know the ClusterIP of every service they communicate with. ClusterIPs are assigned randomly. Configuration becomes fragile and requires updates on every service recreation.
---

### 📘 Textbook Definition

Kubernetes DNS (CoreDNS) automatically creates DNS records for Services and Pods. Services get `<service>.<namespace>.svc.cluster.local` A records resolving to ClusterIP. Pods get `<pod-ip-dashed>.<namespace>.pod.cluster.local` records.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
DNS resolution patterns:

Services:
  backend                              # Same namespace
  backend.production                   # Cross-namespace
  backend.production.svc.cluster.local # FQDN

Headless Services (clusterIP: None):
  postgres-0.postgres-headless.db.svc.cluster.local
  postgres-1.postgres-headless.db.svc.cluster.local
  (Returns individual pod IPs, not ClusterIP)

Pod DNS:
  10-244-1-5.default.pod.cluster.local

How it works:
  Pod /etc/resolv.conf:
    nameserver 10.96.0.10  (CoreDNS Service IP)
    search default.svc.cluster.local svc.cluster.local
    ndots: 5

  App calls "backend" -> resolv.conf adds search domains
    -> tries backend.default.svc.cluster.local
      -> CoreDNS resolves to 10.96.0.100 (ClusterIP)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Service DNS: `<service>.<namespace>.svc.cluster.local` - within same namespace, just `<service>` works
2. Headless services (clusterIP: None) return individual pod IPs - used for StatefulSet discovery
3. `ndots: 5` means any name with fewer than 5 dots gets search domains appended - can cause slow lookups for external domains (fix: use FQDN with trailing dot)

**Interview one-liner:**
"CoreDNS provides automatic service discovery - Services resolve to ClusterIPs, headless Services resolve to individual pod IPs for StatefulSets, with search domain configuration enabling short names within namespaces while FQDN is used for cross-namespace and external resolution."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for DNS in Kubernetes. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Service Mesh

**TL;DR** - A service mesh (Istio, Linkerd) provides infrastructure-level networking features - mTLS, traffic management, observability, and policy enforcement - via sidecar proxies without application code changes.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every microservice implements its own retry logic, circuit breaking, mutual TLS, distributed tracing, and traffic splitting. This logic is duplicated across 50 services in 3 languages, inconsistently implemented, and impossible to manage centrally.

**THE INVENTION MOMENT:**
"This is exactly why service meshes were created."
---

### 📘 Textbook Definition

A service mesh is a dedicated infrastructure layer for managing service-to-service communication, typically implemented as a network of sidecar proxies (data plane) controlled by a central management component (control plane), providing mTLS, load balancing, observability, traffic management, and policy enforcement transparently.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Service Mesh Architecture:

Control Plane (istiod / linkerd-control):
  - Certificate authority (mTLS certs)
  - Configuration distribution
  - Policy management

Data Plane (Envoy/linkerd-proxy sidecars):
+-------------------------------+
| Pod                           |
| +-------+   +-------+        |
| |  App  |<->| Proxy | <-- sidecar
| | :8080 |   | :15001|        |
| +-------+   +---+---+        |
+------------------+------------+
                   |
        mTLS encrypted traffic
                   |
+------------------+------------+
| Pod                           |
| +-------+   +-------+        |
| |  App  |<->| Proxy |        |
| | :8080 |   | :15001|        |
| +-------+   +-------+        |
+-------------------------------+

Features:
  mTLS:           Automatic encryption between all services
  Observability:  Request metrics, traces, access logs
  Traffic mgmt:   Canary, A/B, circuit breaking, retries
  Policy:         Rate limiting, authorization rules
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Service mesh = sidecar proxies (data plane) + central management (control plane) for transparent networking features
2. Key value: mTLS everywhere without app changes, distributed tracing, traffic splitting for canary deploys
3. Cost: resource overhead (~50MB RAM per sidecar), added complexity, operational burden. Evaluate if you actually need it.

**Interview one-liner:**
"A service mesh provides infrastructure-level mTLS, traffic management (canary, circuit breaking), and observability (golden signals, distributed traces) via sidecar proxies - transparently added without application code changes, but with meaningful resource and operational overhead that must be justified."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Service Mesh. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: When does a team actually need a service mesh? When is it over-engineering?**

_Why they ask:_ Tests practical judgment, not just technical knowledge.

**Answer:**
Need a service mesh when:

- **Security mandate**: mTLS everywhere required by compliance (PCI, SOC2)
- **50+ services**: observability complexity warrants centralized solution
- **Multi-language**: can't implement consistent retry/circuit-breaking in 5 languages
- **Advanced traffic management**: canary deployments, traffic mirroring, fault injection for chaos engineering

Over-engineering when:

- **< 10 services**: library-based approach (Resilience4j) is simpler
- **Single language**: one shared library handles all cross-cutting concerns
- **No mTLS requirement**: network policies + internal trust model suffices
- **Small team**: operational overhead of mesh exceeds the benefit

The evolution: Istio ambient mesh (2023) removes per-pod sidecars for L4, using per-node proxies. This reduces overhead by 90% and makes the "when to adopt" threshold lower. The future is mesh capabilities without sidecar tax.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
