---
layout: default
title: "AWS - L1 Compute"
parent: "AWS"
nav_order: 2
permalink: /aws/l1-compute/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 4 | [EC2 Instance Types and Lifecycle](#ec2-instance-types-and-lifecycle) | ★☆☆ |
| 5 | [ECS and Fargate](#ecs-and-fargate) | ★☆☆ |
| 6 | [AWS Lambda Fundamentals](#aws-lambda-fundamentals) | ★☆☆ |

---

# EC2 Instance Types and Lifecycle

**Interview Weight:** ★☆☆ - Core compute knowledge.
EC2 is the foundation of AWS compute. Understanding
instance families, the lifecycle, pricing models, and
Auto Scaling fundamentals is essential for any AWS role.

---

### 🎯 Model Answer

**30 seconds:**

> EC2 provides virtual machines on AWS. Instance types
> are organized into families: M (general purpose),
> C (compute optimized), R (memory optimized), T
> (burstable), G/P (GPU). The lifecycle: pending
> (starting), running (active, billed), stopping,
> stopped (EBS preserved, no compute billing), terminated
> (deleted). Pricing: On-Demand (flexible, full price),
> Reserved (1-3 year, 40-60% discount), Spot
> (interrupts, 70-90% discount).

**3 minutes:**

> Instance family selection:
>
> T family (t3, t4g): burstable. Accumulates CPU credits
> when idle, burns them during busy periods. Cheap.
> Good for: dev/test, low-traffic web servers.
> Avoid for: sustained CPU workloads - credits deplete
> and CPU is throttled to the baseline level.
>
> M family (m6i, m6g): general purpose. Balanced CPU/RAM.
> The default choice. m6g = Graviton3 ARM (10-20% better
> price-performance vs Intel).
>
> C family (c6i, c7g): compute optimized. High CPU/RAM
> ratio. Good for: batch processing, video encoding.
>
> R family (r6i, r6g): memory optimized. High RAM/CPU
> ratio. Good for: in-memory databases, analytics.
>
> Lifecycle states:
>
> pending: instance starting, not yet accessible.
> running: active, billed per second (min 1 minute).
> stopping: graceful shutdown in progress.
> stopped: off. EBS volumes preserved. No compute charge
>   (EBS storage still billed).
> terminated: instance and root EBS deleted. Irreversible.
>
> Pricing:
>
> On-Demand: full price, no commitment. Use for new
>   workloads, burst capacity.
>
> Reserved Instance: 1 or 3-year term. 40-60% discount.
>   Use for stable baseline workloads.
>
> Spot: spare capacity, 2-minute interruption notice.
>   70-90% discount. Use for batch, CI/CD, fault-tolerant.

**Blank Mind Recovery:**

**(1) Families:** "T (burstable), M (general), C (compute),
R (memory), G/P (GPU)."

**(2) Lifecycle:** "Pending -> Running (billed) ->
Stopped (EBS persists, compute free) -> Terminated."

**(3) Pricing:** "On-Demand (flexible), Reserved (40-60%
off, committed), Spot (70-90% off, interruptible)."

---

### 📘 Concept Explanation

**Instance Selection Matrix:**

```
FAMILY  | vCPU:RAM | USE CASE
--------|----------|----------------------------------
t3/t4g  | varies   | Burstable, dev/test, low traffic
        |          | Throttles when credits depleted
m6i/m6g | 1:4      | General purpose - default choice
c6i/c7g | 1:2      | Compute: batch, encoding, ML infer
r6i/r6g | 1:8      | Memory: analytics, in-memory cache
x2gd    | 1:16     | Extreme memory: SAP HANA
i4i     | 1:4      | NVMe SSD: high IOPS databases
p4d/g5  | GPU      | ML training/inference

Graviton (ARM, g-suffix):
  m6g vs m6i: 10-40% better price-performance
  20% cheaper than equivalent x86 instance
  Use when: software is ARM-compatible (Java, Python, Go)
  Avoid when: x86-only binaries
```

> **Code walkthrough:** This EC2 Instance Types and Lifecycle example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# Check instance types in a family:
aws ec2 describe-instance-types \
  --filters "Name=instance-type,Values=m6g.*" \
  --query 'InstanceTypes[].{
    Type:InstanceType,
    vCPU:VCpuInfo.DefaultVCpus,
    MemGB:MemoryInfo.SizeInMiB
  }' --output table

# Stop vs terminate (know the difference):
# STOP: instance off, EBS preserved, can restart
aws ec2 stop-instances \
  --instance-ids i-1234567890abcdef0

# TERMINATE: instance deleted, EBS deleted by default
# IRREVERSIBLE - no recovery after terminated
aws ec2 terminate-instances \
  --instance-ids i-1234567890abcdef0

# Check CPU credit balance (T-series):
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUCreditBalance \
  --dimensions Name=InstanceId,Value=i-1234567890 \
  --period 300 --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%FT%TZ) \
  --end-time $(date -u +%FT%TZ) \
  --query 'sort_by(Datapoints,&Timestamp)[-1].Average'
# If approaching 0: T-series CPU will be throttled
# Solution: upgrade to M-series or enable T3 Unlimited
```

> **Code walkthrough:** The `describe-instance-types` callice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> shows the memory:vCPU ratio for the m6g family - useful
> for selecting the right size. The critical distinction
> between stop and terminate is highlighted: stopping
> preserves all data on the EBS volume and allows restart;
> terminating deletes the root volume by default and is
> irreversible. The CPU credit balance check is the
> early warning for T-series throttling: when the balance
> reaches zero, the instance is throttled to its baseline
> performance (typically 20-40% of peak). Monitoring this
> prevents unexpected production slowdowns when a
> development workload was silently consuming credits.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "EC2 provides virtual machines. There are different
> instance families: T for burstable low-traffic workloads,
> M for general purpose, C for CPU-intensive work, R for
> memory-intensive workloads. The lifecycle goes from
> pending to running (when billed) to stopped (compute
> billing stops, but EBS storage is still billed) to
> terminated (everything deleted). For savings, we use
> Reserved Instances for stable workloads for 40-60%
> discount."

---

### ⚠️ Common Misconceptions

**Misconception: "Stopped instances don't cost anything."**

A stopped EC2 instance is not billed for compute.
But EBS volumes remain attached and are billed at
$0.08-0.10/GB-month (gp3). A stopped instance with
a 100GB root volume costs $8-10/month in storage.
For long-term stopped instances: take an AMI snapshot,
terminate the instance, then relaunch from AMI when needed.
AMI storage in S3 costs < $1/month for 100GB.

---

### 🚨 Failure Modes and Diagnosis

**Failure: T-series instance CPU throttled in production**

*Symptom:* Application response time spikes at peak
hours. CPU shows 100% but throughput drops.
CloudWatch CPUCreditBalance metric = 0.

*Root cause:* T3 instance depleted CPU credits. CPU
limited to baseline (typically 20-30% of peak).

*Fix:* Move to M-series (no burstable limit). Or enable
T3 Unlimited mode - automatically purchases additional
credits when depleted ($0.05/vCPU-hour). Warning:
Unlimited mode can cost more than M-series during
sustained high CPU.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: lifecycle is linear, conveyed in text.)*

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



---

### 🎯 Interview Deep-Dive

---

**[MID] Q1 - [DEBUGGING] A service using EC2 Instance Types and Lifecycle is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for EC2 Instance Types and Lifecycle beyond 'check CloudWatch logs'.

Diagnostic sequence for EC2 Instance Types and Lifecycle issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For EC2 Instance Types and Lifecycle specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare EC2 Instance Types and Lifecycle to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS EC2 Instance Types and Lifecycle service landscape and can make informed architectural decisions.

EC2 Instance Types and Lifecycle has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives.

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have).

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using EC2 Instance Types and Lifecycle for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to EC2 Instance Types and Lifecycle.

Multi-region architecture for EC2 Instance Types and Lifecycle: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems.

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance).

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What EC2 Instance Types and Lifecycle cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* EC2 Instance Types and Lifecycle cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in EC2 Instance Types and Lifecycle: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs.

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using EC2 Instance Types and Lifecycle in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach EC2 Instance Types and Lifecycle with security as a first-class concern, not an afterthought.

Top security risks for EC2 Instance Types and Lifecycle: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for EC2 Instance Types and Lifecycle resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with EC2 Instance Types and Lifecycle: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for EC2 Instance Types and Lifecycle configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads.

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving EC2 Instance Types and Lifecycle that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world EC2 Instance Types and Lifecycle experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes).

Strong answers include: specific EC2 Instance Types and Lifecycle service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient EC2 Instance Types and Lifecycle architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for EC2 Instance Types and Lifecycle peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency).

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled.

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# ECS and Fargate

**Interview Weight:** ★☆☆ - Container orchestration.
ECS (Elastic Container Service) runs Docker containers
on AWS. Fargate removes the need to manage EC2 instances
for containers. Understanding the ECS model (clusters,
services, tasks) and the Fargate vs EC2 launch type
trade-off is expected for backend engineers on AWS.

---

### 🎯 Model Answer

**30 seconds:**

> ECS runs Docker containers on AWS. Two launch types:
> EC2 (you manage underlying instances) and Fargate
> (AWS manages compute, you define CPU/memory per task).
> Key concepts: Cluster (compute pool), Task Definition
> (container blueprint - image, CPU, memory, ports),
> Service (maintains N running tasks, handles rolling
> deploys). Fargate is the right default for most teams:
> no EC2 to manage, auto-scaling, pay per task.

**3 minutes:**

> ECS components:
>
> Cluster: the container for ECS resources. Can use
> EC2 or Fargate within the same cluster.
>
> Task Definition: the blueprint. Defines Docker image,
> CPU/memory, port mappings, environment variables,
> IAM task role, and log configuration. Versioned.
>
> Task: a running instance of a Task Definition.
> Fargate tasks each get their own ENI (Elastic Network
> Interface). Security groups apply at the task level.
>
> Service: manages N running tasks. Restarts failed tasks.
> Integrates with ALB for traffic routing. Performs
> rolling deployments with health checks between steps.
>
> Fargate vs EC2 launch type:
>
> Fargate: no EC2 instances to manage. Pay per vCPU/GB-hour
> of task usage. Scales per task, no pre-provisioned
> capacity. Higher per-unit cost vs On-Demand EC2.
> Good for: variable workloads, small teams, microservices.
>
> EC2 launch type: you manage EC2 instances in the cluster.
> More control (custom AMI, GPU, higher density, Reserved
> Instance savings). Lower per-unit cost.
> Good for: steady-state high-traffic workloads, GPU tasks.

**Blank Mind Recovery:**

**(1) Components:** "Cluster -> Service -> Task.
Task Definition = blueprint (image, CPU, memory, IAM role)."

**(2) Launch types:** "Fargate (no EC2, simpler),
EC2 (more control, cheaper at scale with Reserved)."

**(3) Deployment:** "Rolling update: new tasks start,
health checked, old tasks stop."

---

### 📘 Concept Explanation

**ECS Component Hierarchy:**

```
Cluster (prod-cluster):
  Service (api-service):
    Task Definition: api:v3 (image, 0.5 vCPU, 1GB)
    Desired Count: 4
    ALB Target Group: api-tg
    Running Tasks:
      Task 1: ENI 10.0.1.5, running, healthy
      Task 2: ENI 10.0.2.7, running, healthy
      Task 3: ENI 10.0.1.9, running, healthy
      Task 4: ENI 10.0.2.3, running, healthy

  Service (worker-service):
    Task Definition: worker:v2 (0.25 vCPU, 512MB)
    Desired Count: 2
    No ALB (pulls from SQS queue)
    Running Tasks:
      Task 1: running
      Task 2: running

Fargate: AWS manages EC2 invisibly.
  Each task has its own ENI (no port conflicts).
  Security groups at task level (not instance level).
```

> **Code walkthrough:** This ECS and Fargate example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# Register a Task Definition:
aws ecs register-task-definition \
  --family api-service \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 512 \
  --memory 1024 \
  --execution-role-arn arn:aws:iam::123456789012:role/ecsExecRole \
  --task-role-arn arn:aws:iam::123456789012:role/appRole \
  --container-definitions '[{
    "name": "api",
    "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:v3",
    "portMappings": [{"containerPort": 8080}],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/api",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "api"
      }
    },
    "secrets": [{
      "name": "DB_PASSWORD",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password"
    }]
  }]'

# Rolling deploy to new version:
aws ecs update-service \
  --cluster prod-cluster \
  --service api-service \
  --task-definition api-service:4 \
  --deployment-configuration '{
    "deploymentCircuitBreaker":{
      "enable": true,
      "rollback": true
    },
    "minimumHealthyPercent": 100,
    "maximumPercent": 200
  }'
# minimumHealthyPercent=100: never remove old tasks
#   until new tasks are healthy
# maximumPercent=200: temporarily run 2x tasks
# deploymentCircuitBreaker rollback=true: auto-revert
#   if new tasks fail health checks

# Check deployment status:
aws ecs describe-services \
  --cluster prod-cluster --services api-service \
  --query 'services[0].{
    Desired:desiredCount,
    Running:runningCount,
    Pending:pendingCount,
    Deployments:deployments[].{
      Status:status,
      Running:runningCount,
      Desired:desiredCount
    }
  }'
```

> **Code walkthrough:** The Task Definition has twoice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> distinct IAM roles: `execution-role` (used by ECS to
> pull the container image from ECR and write logs to
> CloudWatch) and `task-role` (used by the application
> code inside the container to call other AWS services).
> The `secrets` field injects the DB_PASSWORD at task
> startup from Secrets Manager - no credentials in the
> image or environment variables stored in plaintext.
> The update-service uses `deploymentCircuitBreaker`
> with `rollback: true`: if new tasks fail ALB health
> checks within 10 minutes, ECS automatically reverts
> to the previous task definition version.
> `minimumHealthyPercent: 100` ensures full capacity
> is maintained throughout the deployment.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "ECS runs Docker containers on AWS. I define a Task
> Definition with the container image, CPU, and memory,
> then create a Service that keeps N tasks running.
> With Fargate, I don't manage EC2 instances - AWS
> handles the underlying compute. Rolling deployments
> replace tasks one by one with health checks between
> each step, keeping the service available."

---

### ⚠️ Common Misconceptions

**Misconception: "Fargate is always more expensive
than EC2 launch type."**

Fargate has higher per-unit cost than On-Demand EC2.
But the full cost comparison must include EC2 management
overhead: patching cluster AMIs, ECS agent upgrades,
handling cluster capacity (under-provisioned = tasks
cannot start, over-provisioned = idle EC2 charges).
For teams without dedicated infrastructure engineers,
the hidden cost of EC2 cluster management (engineer
time) often exceeds the Fargate per-unit premium.
Fargate Spot narrows the cost gap further (same
70-90% discount as EC2 Spot, with Fargate simplicity).

---

### 🚨 Failure Modes and Diagnosis

**Failure: ECS service stuck - tasks not starting**

*Symptom:* Deployment stalls. Tasks remain in PENDING.
Service events: "unable to place a task because no
container instance met all of its requirements."

*Root cause (Fargate):* Task CPU/memory request exceeds
Fargate limits (max 16 vCPU, 120GB).

*Root cause (EC2 launch type):* Cluster instances
are fully utilized. No available CPU/memory.

*Detection:*
```bash
aws ecs describe-services \
  --cluster prod-cluster --services my-service \
  --query 'services[0].events[-5:]'
# Service events: exact failure reason

# For EC2 launch type: check cluster capacity:
aws ecs describe-clusters \
  --clusters prod-cluster \
  --include STATISTICS
```

> **Code walkthrough:** This For EC2 launch type: check cluster capacity: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* Fargate = reduce task size. EC2 = add cluster
instances or migrate to Fargate for automatic scaling.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: component hierarchy in text above.)*

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



---

### 🎯 Interview Deep-Dive

---

**[MID] Q1 - [DEBUGGING] A service using ECS and Fargate is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for ECS and Fargate beyond 'check CloudWatch logs'.

Diagnostic sequence for ECS and Fargate issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For ECS and Fargate specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare ECS and Fargate to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS ECS and Fargate service landscape and can make informed architectural decisions.

ECS and Fargate has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (For EC2 launch type: check clu, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (For EC2 launch type: check clu, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using ECS and Fargate for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to ECS and Fargate.

Multi-region architecture for ECS and Fargate: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (For EC2 launch type: check clu, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (For EC2 launch type: check clu, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What ECS and Fargate cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* ECS and Fargate cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in ECS and Fargate: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (For EC2 launch type: check clu, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using ECS and Fargate in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach ECS and Fargate with security as a first-class concern, not an afterthought.

Top security risks for ECS and Fargate: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for ECS and Fargate resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with ECS and Fargate: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for ECS and Fargate configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (For EC2 launch type: check clu, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving ECS and Fargate that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world ECS and Fargate experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (For EC2 launch type: check clu, Q6)

Strong answers include: specific ECS and Fargate service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient ECS and Fargate architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for ECS and Fargate peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (For EC2 launch type: check clu, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (For EC2 launch type: check clu, Q7)

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# AWS Lambda Fundamentals

**Interview Weight:** ★☆☆ - Serverless foundation.
Lambda is AWS's serverless compute. Understanding the
event model, execution environment lifecycle, cold
starts, concurrency limits, and when to use vs avoid
Lambda is foundational for modern AWS architecture.

---

### 🎯 Model Answer

**30 seconds:**

> Lambda runs code in response to events without managing
> servers. You deploy a function, define a trigger
> (API Gateway, SQS, S3 event, EventBridge), and Lambda
> runs your handler. Billing: per invocation plus per
> 100ms of execution time multiplied by memory size.
> Key constraint: 15-minute maximum. Cold start: first
> invocation takes longer (Java JVM = 1-3s). Good for
> event-driven, short-lived work. Not for long-running
> sustained throughput.

**3 minutes:**

> Lambda execution model:
>
> 1. Event source triggers Lambda.
> 2. Lambda service finds or creates an execution environment
>    (micro-VM running your code).
> 3. If new environment: cold start (init phase).
> 4. Handler function is called with the event.
> 5. Response returned. Environment may be reused
>    (warm) for subsequent invocations.
>
> Cold start phases:
> - Download code (zip: fast, container: slower)
> - Initialize runtime (JVM: 500ms-2s, Python: < 200ms)
> - Run top-level init code (DB connections, config)
> Total: 100ms (Python) to 3s (Java/JVM)
>
> Warm invocations: init phase skipped. Overhead < 10ms.
> Global variables persist across warm invocations.
>
> Memory and CPU: CPU scales proportionally with memory.
> 128MB = 0.125 vCPU. 1024MB = 1 vCPU. Max: 10240MB.
> Higher memory can reduce cost if it reduces duration
> (cost = GB-seconds = memory * duration).
>
> Concurrency: default 1,000 concurrent executions
> per account per region. Burst limit: 3,000 in the first
> minute, then +500/minute. Use Reserved Concurrency
> to cap a function.

**Blank Mind Recovery:**

**(1) Model:** "Event triggers function. Cold start on
new environment. Warm reuses existing environment."

**(2) Constraints:** "15 min max. 10GB max memory.
1,000 concurrent default per region."

**(3) Use when:** "Event-driven, < 15 min, spiky traffic.
Avoid: sustained throughput, long-running."

---

### 📘 Concept Explanation

**Execution Environment Lifecycle:**

```
COLD START (new environment):
  Init phase:
    1. Download function code or container image
    2. Start runtime:
       Python/Node.js: 100-500ms
       Java (JVM): 1,000-3,000ms
       Java (SnapStart): 200-400ms (JVM snapshot)
       Go: 100-300ms
    3. Run static/global initialization code
       (DB connection pool, config loading)
  Invoke phase:
    4. Call handler with event payload

WARM (reusing existing environment):
  Invoke phase only
  Init code is NOT repeated
  Global variables from previous invocation PERSIST
  Overhead: < 10ms

CRITICAL PATTERN:
  Initialize DB connections in global scope
  (outside the handler).
  They are reused on warm invocations.
  NOT re-created on every request.
  Result: only 1 connection per Lambda environment,
  not 1 connection per invocation.
```

> **Code walkthrough:** This AWS Lambda Fundamentals example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```java
// BAD: Connection inside handler - recreated every call
public class Handler
    implements RequestHandler<SQSEvent, Void> {

    @Override
    public Void handleRequest(SQSEvent event, Context ctx) {
        // Opens new DB connection per invocation.
        // At 1000 concurrent lambdas = 1000 connections.
        // Adds 50-200ms per call.
        try (Connection conn = DriverManager.getConnection(
                System.getenv("DB_URL"))) {
            // ... process
        }
        return null;
    }
}
```

> **Code walkthrough:** This AWS Lambda Fundamentals example demonstrates Java runtime behavior. **KEY MECHANISM:** the JVM executes this via bytecode interpretation and JIT compilation of hot paths. **WHY IT MATTERS:** incorrect usage causes subtle concurrency bugs or memory leaks under load. **TAKEAWAY: understand the object lifecycle and threading model before using this API.**

```java
// GOOD: Connection initialized in static scope
// (once per execution environment, reused across warm invocations)
public class Handler
    implements RequestHandler<SQSEvent, Void> {

    // Initialized ONCE during cold start init phase.
    // Reused for all warm invocations.
    private static final DataSource DATA_SOURCE =
        buildDataSource();

    private static DataSource buildDataSource() {
        HikariConfig cfg = new HikariConfig();
        // RDS Proxy: pools Lambda connections at scale
        cfg.setJdbcUrl(System.getenv("DB_PROXY_URL"));
        cfg.setUsername(System.getenv("DB_USER"));
        // IAM token auth - no hardcoded password
        cfg.setPassword(generateRdsIamToken());
        cfg.setMaximumPoolSize(1); // 1 per Lambda env
        return new HikariDataSource(cfg);
    }

    @Override
    public Void handleRequest(SQSEvent event, Context ctx) {
        try (Connection conn = DATA_SOURCE.getConnection()) {
            // Uses pooled connection from static DataSource.
            // No TCP handshake on warm invocations.
        }
        return null;
    }
}
```

> **Code walkthrough:** The BAD pattern creates a newice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> database TCP connection on every Lambda invocation.
> At 1,000 concurrent Lambda invocations, this opens
> 1,000 simultaneous connections to RDS, which can
> exhaust the database's `max_connections`. The GOOD
> pattern initializes the DataSource in a static field:
> it executes during the cold start init phase and is
> reused for all warm invocations in the same execution
> environment. `MaximumPoolSize=1` is correct because
> each Lambda execution environment handles exactly one
> invocation at a time (single-threaded). The RDS Proxy
> URL routes through AWS RDS Proxy which multiplexes
> many Lambda connections into fewer actual RDS connections,
> solving the connection pool exhaustion at scale.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Lambda runs code in response to events without managing
> servers. I write a handler function, deploy it as a JAR
> or Docker image, configure a trigger (API Gateway,
> SQS, S3), and Lambda invokes my function. I pay per
> invocation and per millisecond of runtime. The 15-minute
> execution limit is the main constraint. Cold starts are
> slower because the runtime has to initialize first."

---

### ⚠️ Common Misconceptions

**Misconception: "Lambda scales infinitely without limits."**

Lambda's default concurrent execution limit is 1,000
per account per region. The burst scaling limit means
Lambda cannot go from 0 to 10,000 concurrent executions
in 1 second - it grows at +500/minute after the initial
3,000 burst. At scale: request quota increases, set
Reserved Concurrency on critical functions, and use
throttling/circuit breakers to protect downstream
services (RDS, external APIs) from Lambda's fast
scale-out.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Lambda exhausting RDS connections**

*Symptom:* DB error at high Lambda concurrency:
`FATAL: remaining connection slots reserved for
non-replication superuser connections`.

*Root cause:* Each Lambda environment holds 1 connection.
1,000 concurrent Lambdas = 1,000 connections. RDS
db.t3.medium max_connections ~100. Limit exceeded.

*Fix:*
```bash
# Add RDS Proxy between Lambda and RDS:
aws rds create-db-proxy \
  --db-proxy-name prod-proxy \
  --engine-family POSTGRESQL \
  --auth '[{
    "AuthScheme": "SECRETS",
    "SecretArn": "arn:aws:secretsmanager:...",
    "IAMAuth": "ENABLED"
  }]' \
  --role-arn arn:aws:iam::...:role/RDSProxyRole \
  --vpc-subnet-ids subnet-a subnet-b
# Lambda -> RDS Proxy (1000 connections)
# RDS Proxy -> RDS (multiplexed to ~50 connections)

# Or cap Lambda concurrency:
aws lambda put-function-concurrency \
  --function-name process-orders \
  --reserved-concurrent-executions 50
# Max 50 concurrent = max 50 connections to RDS
```

> **Code walkthrough:** This Max 50 concurrent = max 50 connections to RDS example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: execution lifecycle conveyed in text above.)*

---

### 🎯 Interview Deep-Dive

---

**[MID] Q1 - [DEBUGGING] A service using AWS Lambda Fundamentals is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Lambda Fundamentals beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Lambda Fundamentals issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Lambda Fundamentals specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Lambda Fundamentals to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Lambda Fundamentals service landscape and can make informed architectural decisions.

AWS Lambda Fundamentals has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (Max 50 concurrent = max 50 con, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (Max 50 concurrent = max 50 con, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Lambda Fundamentals for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Lambda Fundamentals.

Multi-region architecture for AWS Lambda Fundamentals: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (Max 50 concurrent = max 50 con, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (Max 50 concurrent = max 50 con, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Lambda Fundamentals cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Lambda Fundamentals cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Lambda Fundamentals: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (Max 50 concurrent = max 50 con, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Lambda Fundamentals in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Lambda Fundamentals with security as a first-class concern, not an afterthought.

Top security risks for AWS Lambda Fundamentals: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Lambda Fundamentals resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Lambda Fundamentals: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Lambda Fundamentals configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (Max 50 concurrent = max 50 con, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Lambda Fundamentals that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Lambda Fundamentals experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (Max 50 concurrent = max 50 con, Q6)

Strong answers include: specific AWS Lambda Fundamentals service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Lambda Fundamentals architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Lambda Fundamentals peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (Max 50 concurrent = max 50 con, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (Max 50 concurrent = max 50 con, Q7)

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.

> **Timing:** 4-5 minutes per question for ★☆☆ keywords.

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 1 |
| TRADE-OFF | 1 |
| BEHAVIORAL | 1 |
| SCENARIO | 2 |

> Note: Three keywords share this Deep-Dive section.

---

#### CONCEPT 1 (EC2): Instance families and pricing models. When do you use each?

**Instance families:**

T-series (t3, t4g): burstable. Earns CPU credits at
baseline CPU utilization rate. Burns credits during
peaks. When credits reach zero, CPU is hard-limited
to the baseline (20-30% of peak for t3.medium).
Use for: dev/test, low-traffic services, batch with
variable load. Avoid for: sustained CPU workloads.

M-series (m6i, m6g): general purpose. Best default.
If you cannot identify a specific requirement, use M-series.
m6g (Graviton ARM): 10-20% better price-performance,
20% cheaper. Use when code is ARM-compatible (Java, Python,
Go, Node.js all compile fine for ARM).

C-series: high vCPU:RAM. Use for CPU-intensive batch
jobs, video encoding, ML inference.

R-series: high RAM:vCPU. Use for large in-memory datasets,
analytics, cache servers.

**Pricing models:**

On-Demand: full list price. Per-second billing (minimum
1 minute). Use for: new workloads before you have
3+ months of usage data to justify a Reserved commitment.
Burst capacity. Short-lived jobs.

Reserved Instance (1 or 3 year): 40-60% discount.
Convertible RIs allow instance type changes.
Use for: production workloads running steadily 24/7
for known periods. Do NOT commit until you have
usage history.

Savings Plans: commit to $ per hour (not specific
instance type). More flexible than RI. Covers EC2,
Fargate, and Lambda. Use when instance type may change
but spend is predictable.

Spot: spare capacity, 70-90% discount, 2-minute
interruption notice. Use for: batch processing, CI/CD
runners, stateless workers with checkpointing.
Never for production services that cannot tolerate
interruption.

*What separates good from great:* "Do NOT commit to
Reserved Instances until you have 3+ months of baseline
data" prevents costly miscommitments. The Savings Plans
flexibility vs RI specificity comparison shows up-to-date
knowledge.

---

#### CONCEPT 2 (Lambda): What is a Lambda cold start and what are the mitigation strategies?

**Cold start definition:** Lambda creates a new execution
environment when no warm environment is available.

Phases:
- Code download (zip: 50ms, container: 500ms-2s)
- Runtime init: Python 50-200ms, Node.js 100-300ms,
  Java (JVM) 500ms-2,000ms
- Static init code: DB connection setup, config load

Total cold start by language:
- Python/Go: 100-500ms (acceptable for most use cases)
- Java JVM: 1,000-3,000ms (problematic for APIs with
  < 1s SLA)
- Java SnapStart: 200-400ms (JVM snapshot, AWS-native)
- Java GraalVM native: 100-300ms (compiled binary)

**Mitigation options (ordered by effectiveness):**

1. Use Python/Go/Node.js instead of Java (if feasible):
   eliminates JVM startup. Not always possible.

2. Java SnapStart: enable on Lambda function.
   Lambda takes a JVM snapshot after init and restores it.
   Reduces Java cold start to 200-400ms. No code change.

3. Reduce package size: smaller zip/image = faster download.
   Remove unused dependencies. Use Lambda layers for
   shared dependencies.

4. Keep init code lean: move expensive operations
   (ML model loading) to lazy initialization.
   Init code runs on every cold start.

5. Provisioned Concurrency: pre-initialize N environments.
   Zero cold starts for those environments.
   Cost: billed continuously at normal rate.
   Use for: SLA-sensitive APIs where first-request
   latency must be < 200ms.

6. Scheduled ping: EventBridge rule every 5 minutes
   invokes the function. Keeps 1 environment warm.
   Cost: ~$0/month. Only prevents cold starts for
   single-concurrency traffic.

*What separates good from great:* SnapStart as the
recommended Java cold start solution (not necessarily
Provisioned Concurrency) shows current knowledge.
SnapStart is free; Provisioned Concurrency has a cost.

---

#### DEBUGGING 1 (ECS): ECS tasks are failing health checks and the service is not stabilizing. How do you diagnose?

**Step 1: Check service events:**
```bash
aws ecs describe-services \
  --cluster prod-cluster --services api-service \
  --query 'services[0].events[-10:]'
# Common events to look for:
# "task failed ELB health checks" = app not responding
# "essential container exited" = container crashed
# "unable to pull secrets" = Secrets Manager permission
```

> **Code walkthrough:** This "unable to pull secrets" = Secrets Manager permission example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Step 2: Get stopped task exit codes:**
```bash
# List stopped tasks:
aws ecs list-tasks --cluster prod-cluster \
  --service-name api-service --desired-status STOPPED

# Get exit code from a stopped task:
aws ecs describe-tasks \
  --cluster prod-cluster --tasks <task-arn> \
  --query 'tasks[0].containers[0].{
    ExitCode:exitCode,
    Reason:reason
  }'
# ExitCode 137 = OOM killed (increase memory in task def)
# ExitCode 1 = application error (check logs)
# ExitCode 0 = clean exit (health check path mismatch)
```

> **Code walkthrough:** This ExitCode 0 = clean exit (health check path mismatch) example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Step 3: Check application logs:**
```bash
aws logs tail /ecs/api-service --follow
# Look for startup errors, missing env vars,
# database connection failures
```

> **Code walkthrough:** This database connection failures example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Step 4: Check ALB health check config:**
```bash
aws elbv2 describe-target-groups \
  --query 'TargetGroups[?TargetGroupName==`api-tg`].{
    Protocol:Protocol,
    Port:Port,
    HealthCheckPath:HealthCheckPath,
    HealthCheckPort:HealthCheckPort
  }'
# If health check path returns non-200: tasks fail health check
# Common: health check on /health but app serves on /api/health
```

> **Code walkthrough:** This Common: health check on /health but app serves on /api/health example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*What separates good from great:* ExitCode 137 = OOM
is specific knowledge. The health check path mismatch
(configured on wrong path) is the most common ECS
health check failure that is not a code bug.

---

#### TRADE-OFF 1 (Lambda vs ECS): How do you choose between Lambda and ECS for a new service?

**Primary decision dimensions:**

Duration: Lambda hard limit 15 minutes. If the function
can run longer: must use ECS/EC2. Video processing (hours)
= ECS. HTTP API handler (200ms) = Lambda candidate.

Traffic pattern: Lambda scales instantly from 0 to 1,000
concurrent (burst limit). ECS task startup: 30-120 seconds.
For traffic that spikes immediately without warm-up:
Lambda handles better. For steady-state traffic:
ECS is always warm.

Cost at scale: Lambda is cheapest at low/variable volume.
ECS (Fargate) is cheaper at sustained high throughput.
Break-even example: function at 500ms/1GB, 50K/day invocations:
Lambda: 50K * 0.5s * 1GB * $0.0000166667/GB-sec
= ~$0.42/day. Fargate: 1 task 24/7 = ~$1.18/day.
Lambda wins at this volume. At 500K/day: Lambda $4.20/day
vs Fargate $1.18/day. Fargate wins.

Cold start tolerance: API with < 200ms P99 latency SLA
and Java runtime = Lambda cold start is a problem.
Use ECS (always warm) or SnapStart + Provisioned Concurrency.

Container size: Lambda max: 50MB zip / 10GB container.
Large ML models or large dependency sets = ECS.

**Summary decision:**
Lambda: event-driven, < 15 min, spiky/variable traffic,
small package, any runtime cold start acceptable.
ECS: sustained high throughput, long-running, large binaries,
strict latency SLA (always warm), GPU workloads.

*What separates good from great:* The break-even cost
calculation at specific invocation volumes makes the
decision quantitative rather than preference-based.

---

#### BEHAVIORAL 1: Tell me about a time you chose between Lambda and ECS for a workload.

**STAR:**

**Situation:** Order processing service. Expected load:
5,000 orders/day average, 20x spikes during promotions.
Processing time: 2-5 seconds per order.
Stack: Java 17.

**Task:** Choose compute platform.

**Analysis:**

Lambda cost: 5,000 * 3.5s avg * 0.5GB
= 8,750 GB-sec/day = $0.15/day = $4.50/month.
Cold start concern: Java JVM = 1-3s. Promotion spike
would have 20x traffic hitting cold environments.

ECS Fargate: 1 task 24/7 = $18/month.
Scale to 0 at night (8 hours): $12/month.
No cold start.

Java SnapStart evaluation: reduces Lambda cold start
from 2s to 350ms. Acceptable for async order processing
(not a synchronous user-facing API). SQS integration
means cold start affects first-in-batch processing,
not user response time.

Decision: Lambda with SnapStart.
Cost: $4.50/month vs $12-18/month ECS.
Cold start: 350ms with SnapStart (acceptable for async).
Auto-scales to 500 concurrent during promotions.

**Result:** Lambda with SnapStart deployed. P99 processing
time: 4.8 seconds. Monthly cost: $5. Zero operational
overhead (no cluster management).

*What separates good from great:* The explicit acknowledgment
that cold start is "acceptable for async processing but
would not be for synchronous user-facing API" shows
calibrated judgment, not a blanket "Lambda is better."

---

#### SCENARIO 1: An ECS service needs zero-downtime deployment. How do you implement it?

**Mechanism:**

Zero-downtime requires: new version is healthy before
old version receives no more traffic.

**ECS rolling deploy with circuit breaker:**

```bash
aws ecs update-service \
  --cluster prod-cluster \
  --service api-service \
  --task-definition api-service:4 \
  --deployment-configuration '{
    "deploymentCircuitBreaker": {
      "enable": true,
      "rollback": true
    },
    "minimumHealthyPercent": 100,
    "maximumPercent": 200
  }'
```

> **Code walkthrough:** This Common: health check on /health but app serves on /api/health example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

`minimumHealthyPercent: 100` = ECS will not stop any
old tasks until new tasks pass health checks and come up.
During deploy: temporarily runs 2x tasks (old + new).
`deploymentCircuitBreaker rollback: true` = if new tasks
fail health checks, ECS reverts to previous version.

**Blue-green alternative (CodeDeploy + ALB):**

```
ALB listener -> 100% to Blue (v1 target group)
CodeDeploy:
  1. Launch new tasks (v2) in Green target group
  2. Wait for health checks
  3. Shift 10% traffic to Green (canary)
  4. Monitor 5 minutes
  5. Shift 100% traffic to Green
  6. Drain Blue (wait for in-flight requests)
  7. Stop Blue tasks
Rollback: shift 100% back to Blue in < 30 seconds
```

> **Code walkthrough:** This Common: health check on /health but app serves on /api/health example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

*What separates good from great:* The blue-green with
canary (10% traffic first) is the production-safe pattern
for business-critical services. Not all deploys need
canary; for routine changes, rolling deploy is sufficient.
Knowing when to use each shows engineering judgment.

---

#### SCENARIO 2: Lambda functions processing SQS messages are falling behind. Queue depth is growing. How do you fix?

**Diagnosis:**

```bash
# Check queue depth:
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/.../orders \
  --attribute-names ApproximateNumberOfMessages,
    ApproximateNumberOfMessagesNotVisible

# Check Lambda concurrency:
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name ConcurrentExecutions \
  --dimensions Name=FunctionName,Value=process-orders \
  --period 60 --statistics Maximum ...

# Check throttles:
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=process-orders \
  --period 60 --statistics Sum ...
```

> **Code walkthrough:** This Check throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Common causes and fixes:**

1. Lambda at concurrency limit (1,000 default):
   - Fix: request limit increase
   - Or: reduce per-message processing time

2. Batch size = 1 (one Lambda invocation per message):
   ```bash
   aws lambda update-event-source-mapping \
     --uuid <mapping-uuid> \
     --batch-size 10
   # Lambda now processes 10 messages per invocation
   # 10x throughput at same Lambda concurrency
   ```

> **Code walkthrough:** This Check throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

3. Processing duration too long:
   - Check Lambda Duration P99 metric
   - If > 5s: profile the bottleneck
   - Add read-through caching if DB calls are slow

4. Downstream throttling (RDS, external API):
   - Lambda scales fast, downstream may not
   - Add RDS Proxy for database connections
   - Add circuit breaker for external APIs
   - Or: reduce reserved concurrency to cap Lambda

*What separates good from great:* Batch size as the
first lever before adding concurrency shows understanding
of how Lambda SQS integration scales. Each Lambda
invocation processes N messages from the same function
execution, multiplying throughput without increasing
concurrency.

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



