---
layout: default
title: "Cloud AWS - Compute and Networking"
parent: "Cloud AWS"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/cloud-aws/compute-and-networking/
topic: Cloud AWS
subtopic: Compute and Networking
keywords:
  - EC2
  - Lambda
  - ECS and EKS
  - ALB and NLB
  - Route 53
  - API Gateway
difficulty_range: medium-hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [EC2](#ec2)
- [Lambda](#lambda)
- [ECS and EKS](#ecs-and-eks)
- [ALB and NLB](#alb-and-nlb)
- [Route 53](#route-53)
- [API Gateway](#api-gateway)

# EC2

**TL;DR** - EC2 (Elastic Compute Cloud) provides resizable virtual machines in the cloud with multiple instance types optimized for different workloads, pricing models (On-Demand, Reserved, Spot), and integration with Auto Scaling for elastic capacity.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Need a server? Submit a purchase order, wait 6 weeks for hardware, rack it, install OS, configure networking. Need more capacity for a sale? Too late. Need less after? You're paying for idle hardware.
---

### 📘 Textbook Definition

Amazon EC2 provides scalable computing capacity as virtual machine instances with configurable CPU, memory, storage, and networking. Instances are launched from AMIs (Amazon Machine Images) in specific AZs, with Auto Scaling Groups managing fleet size based on demand.
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
EC2 instance families:
  General Purpose (t3, m6i): Balanced compute/memory
  Compute Optimized (c6i):   CPU-intensive (batch, ML)
  Memory Optimized (r6i):    Large datasets (caches, DB)
  Storage Optimized (i3):    High sequential I/O
  Accelerated (p4d, g5):     GPU (ML training, graphics)

Pricing models:
  On-Demand:  Pay per second, no commitment
              Use for: unpredictable, short-term, spiky
  Reserved:   1-3 year commitment, 40-72% discount
              Use for: steady-state baseline load
  Savings Plan: Flexible commitment, similar discount
              Use for: flexible across instance types
  Spot:       Up to 90% discount, can be interrupted
              Use for: fault-tolerant (batch, CI, stateless)

Auto Scaling Group (ASG):
  - Maintains desired capacity (self-healing)
  - Scales based on metrics (CPU, custom)
  - Spans multiple AZs (high availability)
  - Mixed instances (On-Demand + Spot)
  - Launch Template defines instance configuration
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

1. Instance types: t3 (general/burstable), c6i (compute), r6i (memory), i3 (storage), p4d (GPU). Choose based on workload bottleneck.
2. Cost optimization: Reserved/Savings Plans for baseline (40-72% savings) + Spot for fault-tolerant (up to 90%) + On-Demand for unpredictable.
3. Auto Scaling Group across AZs = HA + elastic. Define min/max/desired. Scale on CloudWatch alarms (CPU, custom metrics).

**Interview one-liner:**
"I use EC2 with ASGs spanning AZs for high availability, mixed pricing (Reserved for baseline, Spot for fault-tolerant workloads via capacity-optimized allocation), right-sized instance types based on workload profile, and Launch Templates with user data for immutable infrastructure."
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

[TODO: Include if 2+ named alternatives exist for EC2. Otherwise remove this section.]
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

# Lambda

**TL;DR** - AWS Lambda runs code without provisioning servers - you pay only for compute time consumed (per millisecond), with automatic scaling from zero to thousands of concurrent executions, triggered by events from 200+ AWS services.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A function that runs 100 times per day still needs an EC2 instance running 24/7. You pay for 86,400 seconds of idle time to execute 100 seconds of work. Managing the server, patching OS, scaling - all for a simple function.
---

### 📘 Textbook Definition

AWS Lambda is a serverless compute service that runs code in response to events (HTTP requests, S3 uploads, DynamoDB streams, SQS messages) without server management. It automatically scales (0 to thousands of instances), charges per millisecond of execution, and supports multiple runtimes (Java, Python, Node.js, Go, .NET).
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
Lambda execution model:
  Event source -> Lambda service -> Your function
    - Cold start: Init runtime + your code (~100ms-2s)
    - Warm start: Reuse existing container (~1-5ms)
    - Auto-scales: One instance per concurrent request
    - Max: 1000 concurrent (default, can increase)

Lambda configuration:
  Memory:    128 MB - 10,240 MB (CPU scales with memory)
  Timeout:   Max 15 minutes
  Package:   50 MB zipped, 250 MB unzipped (or container)
  Trigger:   API GW, S3, SQS, EventBridge, DynamoDB Streams

When to use Lambda:
  YES: Event-driven processing, APIs (< 15 min),
       glue logic, scheduled tasks, data transformation
  NO:  Long-running processes, stateful apps,
       high-throughput low-latency (cold starts matter),
       WebSockets (use API GW WebSocket + Lambda)

Cost example:
  1M requests/month, 200ms avg, 256MB memory:
  Compute: 1M * 0.2s * 256MB = $0.83
  Requests: 1M * $0.20/1M = $0.20
  Total: ~$1.03/month (vs ~$30/month smallest EC2)
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

1. Pay only for execution time (ms) - zero cost at zero traffic. Auto-scales from 0 to thousands. No server management.
2. Cold starts: 100ms-2s for first invocation (Java worst, Python/Node best). Mitigate with Provisioned Concurrency for latency-sensitive workloads.
3. Constraints: 15-min max timeout, 10GB max memory, 6MB sync response payload. Architect around these limits.

**Interview one-liner:**
"Lambda provides event-driven serverless compute at millisecond billing granularity - I use it for API backends (API Gateway + Lambda), event processing (S3/SQS/EventBridge triggers), and scheduled tasks, with Provisioned Concurrency for latency-sensitive paths and understanding cold-start characteristics per runtime."
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

[TODO: Include if 2+ named alternatives exist for Lambda. Otherwise remove this section.]
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

# ECS and EKS

**TL;DR** - ECS (Elastic Container Service) is AWS's native container orchestrator (simpler, tighter AWS integration), while EKS (Elastic Kubernetes Service) provides managed Kubernetes (portable, larger ecosystem) - both run containers on EC2 or Fargate (serverless).
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Running containers in production requires orchestration: scheduling, health checks, scaling, networking, service discovery. Building this yourself on EC2 is complex, error-prone, and a full-time job for a platform team.
---

### 📘 Textbook Definition

**ECS**: AWS-native container orchestration service that manages container lifecycle on EC2 instances or Fargate (serverless), using Tasks (container definitions) and Services (desired state management). **EKS**: Managed Kubernetes control plane service with AWS-managed etcd, API server, and controller manager, running worker nodes on EC2 or Fargate.
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
ECS vs EKS decision:
  | Factor         | ECS                | EKS               |
  |----------------|--------------------|--------------------|
  | Complexity     | Simpler            | More complex       |
  | AWS integration| Native (deep)      | Good (add-ons)     |
  | Portability    | AWS-only           | Multi-cloud K8s    |
  | Ecosystem      | AWS-specific       | Huge K8s ecosystem |
  | Team skills    | AWS-focused        | K8s-experienced    |
  | IAM            | Task role (native) | IRSA (more setup)  |
  | Networking     | awsvpc mode        | VPC CNI            |
  | Cost           | No control plane $ | $0.10/hr/cluster   |

Choose ECS when:
  - Team is AWS-only, no K8s experience
  - Simpler workloads, fewer cross-cutting concerns
  - Want fastest path to running containers
  - Deep AWS service integration is priority

Choose EKS when:
  - Multi-cloud or hybrid strategy
  - Team has Kubernetes expertise
  - Need K8s ecosystem (Helm, operators, custom CRDs)
  - Complex platform needs (service mesh, GitOps)

Compute options (both ECS and EKS):
  EC2:     You manage nodes, more control, cheaper
  Fargate: Serverless, no nodes to manage, per-pod pricing
           Higher per-unit cost but zero ops overhead
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

1. ECS = simpler, AWS-native, no control plane cost, deep IAM integration. EKS = Kubernetes ecosystem, portable, more flexible, $0.10/hr/cluster.
2. Both support Fargate (serverless - no node management) and EC2 (you manage nodes but cheaper and more control).
3. Decision: AWS-only + simple -> ECS. Multi-cloud or K8s ecosystem needed -> EKS. Both are production-ready.

**Interview one-liner:**
"I choose ECS for simpler AWS-native workloads with deep service integration (Task IAM roles, native LB), and EKS when we need Kubernetes portability, ecosystem tools (Helm, ArgoCD, operators), or complex platform needs - using Fargate for dev/small workloads and EC2 for cost-optimized production."
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

[TODO: Include if 2+ named alternatives exist for ECS and EKS. Otherwise remove this section.]
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

# ALB and NLB

**TL;DR** - ALB (Application Load Balancer) operates at Layer 7 (HTTP) providing path/host routing, WebSocket support, and WAF integration. NLB (Network Load Balancer) operates at Layer 4 (TCP/UDP) providing ultra-low latency and millions of requests per second.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
External traffic needs to reach your backend instances. Without a load balancer: no distribution across instances, no health checks, no SSL termination, no routing by URL path or hostname.
---

### 📘 Textbook Definition

**ALB**: Layer 7 (HTTP/HTTPS) load balancer that routes requests based on content (host headers, URL paths, HTTP methods, query strings) to target groups, supporting sticky sessions, WebSockets, and gRPC. **NLB**: Layer 4 (TCP/UDP/TLS) load balancer optimized for extreme performance with static IPs, source IP preservation, and millions of requests per second at ultra-low latency.
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
ALB vs NLB:
  | Feature       | ALB (Layer 7)      | NLB (Layer 4)     |
  |---------------|--------------------|--------------------|
  | Protocol      | HTTP, HTTPS, gRPC  | TCP, UDP, TLS      |
  | Routing       | Path, host, header | Port-based only    |
  | Latency       | ~ms added          | ~microseconds      |
  | Static IP     | No (use Global Acc)| Yes                |
  | WebSocket     | Yes                | Yes (TCP)          |
  | WAF           | Yes (integrates)   | No                 |
  | SSL/TLS       | Termination        | Termination or pass|
  | Cost          | ~$22/month + LCU   | ~$22/month + NLCU  |

Use ALB when:
  - HTTP/HTTPS traffic
  - Need path-based routing (/api/* -> service A)
  - Need host-based routing (api.example.com vs web.*)
  - WAF integration required
  - WebSocket or gRPC

Use NLB when:
  - TCP/UDP protocol (not HTTP)
  - Need static IP or Elastic IP
  - Ultra-low latency critical
  - Need to preserve source IP
  - Extremely high throughput (millions rps)
  - gRPC or HTTP/2 without ALB overhead

ALB routing example:
  api.example.com/users/* -> Users service (TG)
  api.example.com/orders/* -> Orders service (TG)
  web.example.com/* -> Frontend (TG)
  Default: 404 fixed response
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

1. ALB = Layer 7 (HTTP), content-based routing, WAF integration. NLB = Layer 4 (TCP), ultra-low latency, static IPs, extreme throughput.
2. Use ALB for web apps/APIs (90% of use cases). Use NLB for non-HTTP protocols, static IPs, or when you need microsecond latency.
3. ALB + WAF for security. NLB + PrivateLink for exposing services to other accounts. Both integrate with Auto Scaling Groups and ECS/EKS.

**Interview one-liner:**
"ALB for HTTP workloads with path/host routing, WAF integration, and WebSocket support - NLB for TCP/UDP protocols, static IPs, or extreme performance requirements. I use ALB for APIs and web apps (95% of cases) with target group health checks driving auto-scaling."
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

[TODO: Include if 2+ named alternatives exist for ALB and NLB. Otherwise remove this section.]
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

# Route 53

**TL;DR** - Route 53 is AWS's DNS service providing domain registration, DNS resolution, and health-check-based routing policies (weighted, failover, geolocation, latency-based) for high-availability architectures and global traffic management.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
DNS is a single point of failure. Traditional DNS can't route based on health, geography, or latency. Failover requires manual DNS changes (with TTL propagation delays). No integration between DNS and cloud infrastructure health.
---

### 📘 Textbook Definition

Amazon Route 53 is a highly available and scalable DNS web service providing three main functions: domain registration, DNS resolution (translating names to IPs), and health checking with traffic routing policies that direct users to optimal endpoints based on latency, geography, weights, or endpoint health.
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
Route 53 routing policies:
  Simple:       One record, one endpoint (basic)
  Weighted:     Split traffic by percentage (canary)
                90% -> v1, 10% -> v2
  Latency:      Route to lowest-latency region
                US user -> us-east-1, EU -> eu-west-1
  Failover:     Primary/secondary with health check
                Primary healthy -> use primary
                Primary unhealthy -> failover to secondary
  Geolocation:  Route by user's country/continent
                EU users -> EU servers (data residency)
  Multi-value:  Return multiple healthy IPs (simple LB)

Health checks:
  HTTP/HTTPS/TCP check on endpoint
  If unhealthy -> remove from DNS responses
  Can check: endpoint, other health checks (calculated),
             CloudWatch alarm state

Alias records (AWS-specific):
  Route traffic to AWS resources without extra hop:
  example.com -> ALB DNS name (no CNAME at zone apex!)
  Alias works at zone apex. CNAME doesn't.
  Free (no query charges for alias to AWS resources)
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

1. Routing policies: Weighted (canary), Failover (DR), Latency (global performance), Geolocation (compliance). Each solves a different problem.
2. Alias records: point zone apex (example.com) to AWS resources (ALB, CloudFront, S3). Free queries. Use instead of CNAME.
3. Health checks drive failover: Route 53 checks endpoint health -> removes unhealthy from DNS -> automatic failover to secondary.

**Interview one-liner:**
"Route 53 provides DNS-level traffic management - I use latency-based routing for global users, failover routing with health checks for DR, weighted routing for canary deployments, and alias records at zone apex for AWS resource integration without extra DNS hops."
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

[TODO: Include if 2+ named alternatives exist for Route 53. Otherwise remove this section.]
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

# API Gateway

**TL;DR** - AWS API Gateway is a managed service for creating, publishing, and managing APIs at scale - handling authentication, throttling, caching, request transformation, and routing to Lambda, HTTP backends, or AWS services without managing infrastructure.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every API needs: rate limiting, authentication, request validation, CORS, caching, monitoring, documentation, versioning. Building this in each microservice duplicates effort and creates inconsistency.
---

### 📘 Textbook Definition

Amazon API Gateway is a fully managed service for creating and managing REST, HTTP, and WebSocket APIs at any scale. It handles request routing, authorization (IAM, Cognito, Lambda authorizers), throttling, caching, request/response transformation, and integrates with Lambda, HTTP endpoints, and AWS services.
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
API Gateway types:
  REST API:  Full-featured (caching, WAF, transforms)
             Higher cost, more features
  HTTP API:  Simpler, cheaper (40%), faster
             JWT auth, OIDC, simpler routing
  WebSocket: Bidirectional real-time communication

Request flow:
  Client -> API GW -> Authorizer (Lambda/Cognito/IAM)
    -> Request validation (JSON schema)
      -> Integration (Lambda/HTTP/AWS service)
        -> Response transformation
          -> Client

Key features:
  - Usage plans + API keys (rate limiting per client)
  - Request/response transformation (mapping templates)
  - Caching (reduce backend calls)
  - Custom domain + TLS certificates
  - Canary deployments (route % to new stage)
  - OpenAPI/Swagger import/export
  - WAF integration (REST API only)

API Gateway + Lambda pattern:
  GET /users -> Lambda: listUsers
  POST /users -> Lambda: createUser
  GET /users/{id} -> Lambda: getUser
  (Each route maps to a Lambda function or single handler)
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

1. REST API (full-featured, expensive) vs HTTP API (simpler, 40% cheaper, good enough for most Lambda backends). Choose HTTP API for new projects unless you need caching/WAF/transforms.
2. Authorization options: IAM (AWS services), Cognito (user pools), Lambda authorizer (custom logic). JWT is built into HTTP API.
3. Throttling: 10,000 requests/second default (account-level). Usage plans let you set per-client rate limits with API keys.

**Interview one-liner:**
"API Gateway provides managed API infrastructure - I use HTTP APIs for Lambda backends (lower cost, JWT auth), REST APIs when needing caching/WAF/transforms, Lambda authorizers for custom auth logic, and usage plans for per-client rate limiting."
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

[TODO: Include if 2+ named alternatives exist for API Gateway. Otherwise remove this section.]
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
