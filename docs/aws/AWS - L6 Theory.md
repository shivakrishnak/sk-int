---
layout: default
title: "AWS - L6 Theory"
parent: "AWS"
nav_order: 16
permalink: /aws/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 29 | [AWS Service Quotas and Limits Design](#aws-service-quotas-and-limits-design) | ★★☆ |
| 30 | [AWS Service Selection Frameworks](#aws-service-selection-frameworks) | ★★☆ |

---

# AWS Service Quotas and Limits Design

**Interview Weight:** ★★☆ - Production reliability design.
AWS service quotas (formerly "limits") are hard and soft
ceilings on resource usage per account per region.
Architects must understand quota categories (hard vs
adjustable), design systems to stay within quotas
under load, request increases proactively, and use
multi-account patterns for quota isolation. Ignoring
quotas causes production outages at scale.

---

### 🎯 Model Answer

**30 seconds:**

> AWS service quotas are per-account, per-region ceilings
> on resource usage. Hard quotas cannot be increased.
> Soft/adjustable quotas can be raised via a support
> request. Critical quotas: EC2 vCPU per instance family
> (default 32-96 per account), Lambda concurrent
> executions (1,000 default), SQS messages per second
> (3,000 per queue), API Gateway requests/second
> (10,000 default). Design for quotas: request increases
> before you need them, use multi-account to distribute
> quota consumption, and monitor usage with CloudWatch.

**3 minutes:**

> Common quota surprises in production:
>
> EC2 vCPU quotas: per instance family.
> Launching 100 r5.4xlarge (16 vCPU each) = 1,600 vCPU.
> Default On-Demand R family quota: 32 vCPU.
> Auto Scaling cannot launch more instances when quota hit.
> ASG shows InsufficientCapacity or QuotaExceeded.
>
> Lambda: 1,000 concurrent executions per account per region.
> Event-driven burst: 1,000 Lambda functions simultaneously.
> Beyond 1,000: throttling. Downstream queues back up.
> Increase to 10,000+ via quota request.
>
> CloudFormation stacks: 2,000 per account per region.
> At 200+ microservices with CDK: stacks accumulate.
>
> EIP (Elastic IP): 5 per region default.
> NAT Gateways need EIPs: 5 per AZ quickly exhausted.
>
> Mitigation strategies:
> 1. Quota monitoring: CloudWatch quota usage alarms
>    at 80% threshold (alert before exhaustion)
> 2. Multi-account for quota isolation
>    (each account has its own Lambda 1,000 limit)
> 3. Proactive requests: submit increases 2-4 weeks
>    before planned capacity events (Black Friday, launch)
> 4. Quota increase automation: Terraform or CDK
>    for quota requests as IaC

**Blank Mind Recovery:**

**(1) Quote categories:** "Hard = cannot increase. Soft/adjustable
= request increase via support."

**(2) Critical quotas:** "EC2 vCPU per family, Lambda concurrent
1000, API Gateway 10K req/s, SQS 3000 msg/s, EIP 5 per region."

**(3) Design:** "Monitor at 80%, multi-account for isolation,
request increases proactively before events."

---

### 📘 Concept Explanation

**Quota categories:**

```
Hard quotas:
  Cannot be increased regardless of reason.
  Example: S3 bucket name must be globally unique
  Example: Max S3 object size: 5TB
  Example: Lambda function code + layers: 250MB (unzipped)
  Design around these - no workaround via support

Adjustable (Soft) quotas:
  Default value is conservative (shared-account safety).
  Can be increased by submitting a quota increase request.
  Approval: automatic for small increases, reviewed for large.
  Examples:
    EC2 On-Demand vCPUs per family (32-96 default)
    Lambda concurrent executions (1,000 default)
    API Gateway requests per second (10,000 default)
    VPCs per region (5 default)
    RDS instances per region (40 default)

Quota scope:
  Per account, per region (most quotas)
  Per account, global (some S3 quotas)
  Per resource (S3 bucket policy size: 20KB per bucket)
```

> **Code walkthrough:** This AWS Service Quotas and Limits Design example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```python
# BAD: No quota monitoring or planning
# Launch 200 r5.4xlarge on Black Friday:
# Auto Scaling silently fails at 32 vCPU default
# Customers see errors. Nobody knows why.

import boto3
autoscaling = boto3.client('autoscaling')
# No quota check before peak event planning
autoscaling.update_auto_scaling_group(
    AutoScalingGroupName='prod-asg',
    MaxSize=50  # 50 * 16 vCPU = 800 vCPU. Default: 32.
)
```

> **Code walkthrough:** This No quota check before peak event planning example demonstrates Python runtime behavior. **KEY MECHANISM:** the CPython interpreter executes this via reference counting and GIL coordination. **WHY IT MATTERS:** blocking calls inside async contexts starve the event loop and freeze all coroutines. **TAKEAWAY: match synchronous vs asynchronous context to the I/O model of the operation.**

```python
# GOOD: Check quota before capacity planning events
import boto3

def check_quota_headroom(service_code, quota_code, 
                          planned_usage):
    sq = boto3.client('service-quotas')
    response = sq.get_service_quota(
        ServiceCode=service_code,
        QuotaCode=quota_code
    )
    current_limit = response['Quota']['Value']
    
    # Get current usage from CloudWatch:
    cw = boto3.client('cloudwatch')
    usage_response = cw.get_metric_statistics(
        Namespace='AWS/Usage',
        MetricName='ResourceCount',
        Dimensions=[
            {'Name': 'Type', 'Value': 'Resource'},
            {'Name': 'Resource', 'Value': quota_code},
            {'Name': 'Service', 'Value': service_code},
            {'Name': 'Class', 'Value': 'None'}
        ],
        StartTime='2024-01-01T00:00:00Z',
        EndTime='2024-01-01T01:00:00Z',
        Period=3600,
        Statistics=['Maximum']
    )
    
    current_usage = usage_response['Datapoints'][0]['Maximum']
    headroom = current_limit - current_usage
    
    if planned_usage > headroom:
        print(f"WARNING: Need {planned_usage} but only "
              f"{headroom} available. Request increase.")
        # Submit quota increase request:
        sq.request_service_quota_increase(
            ServiceCode=service_code,
            QuotaCode=quota_code,
            DesiredValue=current_usage + planned_usage * 1.5
        )
    return headroom

# Check EC2 R-family vCPU headroom for 200 instances:
check_quota_headroom(
    'ec2',
    'L-43DA4232',  # On-Demand R instances vCPU
    200 * 16  # 200 r5.4xlarge = 3200 vCPU needed
)
```

> **Code walkthrough:** This Check EC2 R-family vCPU headroom for 200 instances: example demonstrates Python runtime behavior. **KEY MECHANISM:** the CPython interpreter executes this via reference counting and GIL coordination. **WHY IT MATTERS:** blocking calls inside async contexts starve the event loop and freeze all coroutines. **TAKEAWAY: match synchronous vs asynchronous context to the I/O model of the operation.**

```bash
# Monitor quota usage with CloudWatch alarms:
aws cloudwatch put-metric-alarm \
  --alarm-name "Lambda-Concurrent-Executions-80pct" \
  --metric-name ConcurrentExecutions \
  --namespace AWS/Lambda \
  --period 60 \
  --evaluation-periods 5 \
  --threshold 800 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:...:quota-alerts \
  --alarm-description "Lambda concurrent at 80% of 1000 default"

# List all service quotas for a service:
aws service-quotas list-service-quotas \
  --service-code lambda \
  --query 'Quotas[*].{Name:QuotaName,Value:Value,Adjustable:Adjustable}'

# Check applied quota increases:
aws service-quotas list-requested-service-quota-changes-by-service \
  --service-code ec2
```

> **Code walkthrough:** The BAD pattern silently createsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> an Auto Scaling group with `MaxSize=50` for r5.4xlarge
> instances, which requires 800 vCPU. The default quota
> is 32 vCPU for R-family instances. On the peak event:
> ASG attempts to launch instances, receives QuotaExceeded,
> and fails silently from the application's perspective
> (customers see errors). The GOOD pattern queries the
> current quota and current usage, calculates headroom,
> and automatically submits a quota increase request
> if planned usage exceeds headroom. CloudWatch alarms
> at 80% of quota provide advance warning before the
> ceiling is hit.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "AWS quotas are limits on how many resources you can
> create in a single account and region. The defaults
> are conservative. If you need more EC2 instances or
> Lambda functions than the default allows: submit a
> quota increase request in the Service Quotas console.
> I monitor quota usage in CloudWatch to get alerts
> before hitting the limit."

**Senior / Staff:**

> "Quota design is architectural: it affects account
> structure and capacity planning.
>
> Multi-account for quota isolation: Lambda concurrent
> execution quota is 1,000 per account by default.
> With 10 microservices in one account: one microservice
> burst can exhaust the quota for all others.
> With 10 accounts (one per service): each has its own
> 1,000 limit. Blast radius of quota exhaustion is
> contained to one account.
>
> Proactive increase requests: quota increase approval
> takes 1-5 business days for large increases. For
> planned events (product launch, Black Friday): submit
> requests 2-4 weeks ahead. Automate via IaC:
> `aws_servicequotas_service_quota` Terraform resource
> submits the request automatically on `terraform apply`.
>
> Design for quota boundaries, not just current usage:
> If your service can burst to 10x normal during a
> marketing campaign: design for that peak, not the average.
> EC2 Auto Scaling quota: set to 2x the peak ever seen,
> not current max."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Quotas are the same across all
AWS account types."**

AWS Accounts have different default quotas based on
account type and history. New accounts have the most
restrictive defaults (conservative for safety). Accounts
with a billing history and trust score may have higher
defaults. Enterprise support accounts can get faster
quota increase approvals and higher limits. For new
accounts used in production: submit quota increases
on day 1, not when you hit the limit.

**Misconception 2: "API Gateway 10,000 requests/second
is per deployment."**

API Gateway quota of 10,000 requests/second is per
account per region. All APIs in the same account share
this quota. If you have 20 APIs each serving 500 req/s
= 10,000 req/s total: you are at the limit. A burst
on one API can throttle all others. Use separate accounts
for high-traffic APIs, or request a quota increase for
the account.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Auto Scaling failing silently due to
EC2 vCPU quota exhaustion**

*Symptom:* Auto Scaling group not scaling out during
high load. EC2 instances not launching. ALB returning
5xx due to all instances overloaded. Application health
checks failing.

*Diagnosis:*
```bash
# Check Auto Scaling activity:
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name prod-asg \
  --max-items 10
# Look for: StatusCode=Failed,
#   Cause: EC2 Instance Launch Unsuccessful:
#   Your quota allows for 0 more running instance(s)

# Check current EC2 quota:
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A  # Running On-Demand Standard instances

# Check current vCPU usage:
aws ec2 describe-account-attributes \
  --attribute-names max-instances
```

> **Code walkthrough:** This Check current vCPU usage: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix (immediate):*
```bash
# Submit emergency quota increase:
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 1000

# Emergency: use Spot instances (different quota pool):
# Spot vCPU quota is separate from On-Demand quota
# Modify ASG to use Mixed Instances Policy with Spot:
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name prod-asg \
  --mixed-instances-policy '{
    "InstancesDistribution": {
      "OnDemandPercentageAboveBaseCapacity": 0,
      "SpotAllocationStrategy": "capacity-optimized"
    }
  }'
# Spot quota is usually higher and less contested
```

> **Code walkthrough:** This Spot quota is usually higher and less contested example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

---

### ⚖️ Comparison Table

| Quota Type | Example | Default | Adjustable? | Design Impact |
|-----------|---------|---------|-------------|---------------|
| EC2 vCPU (On-Demand) | R-family vCPU | 32-96 | Yes | Multi-account for large fleets |
| Lambda concurrent | All functions | 1,000 | Yes | Account isolation per service |
| API Gateway RPS | All APIs | 10,000 | Yes | Separate accounts for high-traffic APIs |
| S3 buckets | Per account | 100 | Yes | Service mesh, not per-bucket per service |
| VPCs per region | Per account | 5 | Yes | Centralize networking account |
| CloudFormation stacks | Per region | 2,000 | Yes | Nest stacks, CDK stack splitting |
| SQS messages/second | Per queue | 3,000 | Hard (SQS auto-scales) | Partition across queues |

---

### 📊 Diagram

*(Omit: quota design is a procedural/planning concept,
not a flow that benefits from a visual diagram beyond
the table above)*

---

### 🎯 Interview Deep-Dive

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 2 |
| TRADE-OFF | 2 |
| BEHAVIORAL | 1 |
| SCENARIO | 2 |

---

---

**[MID] Q1 - [DEBUGGING] A service using AWS Service Quotas and Limits Design is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Service Quotas and Limits Design beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Service Quotas and Limits Design issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Service Quotas and Limits Design specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Service Quotas and Limits Design to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Service Quotas and Limits Design service landscape and can make informed architectural decisions.

AWS Service Quotas and Limits Design has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives.

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have).

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Service Quotas and Limits Design for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Service Quotas and Limits Design.

Multi-region architecture for AWS Service Quotas and Limits Design: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems.

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance).

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Service Quotas and Limits Design cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Service Quotas and Limits Design cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Service Quotas and Limits Design: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs.

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Service Quotas and Limits Design in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Service Quotas and Limits Design with security as a first-class concern, not an afterthought.

Top security risks for AWS Service Quotas and Limits Design: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Service Quotas and Limits Design resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Service Quotas and Limits Design: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Service Quotas and Limits Design configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads.

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Service Quotas and Limits Design that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Service Quotas and Limits Design experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes).

Strong answers include: specific AWS Service Quotas and Limits Design service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Service Quotas and Limits Design architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Service Quotas and Limits Design peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency).

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled.

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.

---

**[JUNIOR] Q8 - [CONCEPTUAL] Explain AWS Service Quotas and Limits Design to someone who has never used AWS before. What problem does it solve, and when would a startup first need it?**

*Why they ask:* Tests understanding of AWS Service Quotas and Limits Design core value proposition beyond configuration options.

AWS Service Quotas and Limits Design exists because building the equivalent infrastructure yourself requires significant engineering time, ongoing maintenance, and operational expertise. AWS manages the undifferentiated heavy lifting so engineering teams can focus on product differentiation.

For a startup: AWS Service Quotas and Limits Design makes sense when the cost of building or managing the equivalent is higher than the AWS Service Quotas and Limits Design bill. Early stage: use managed services liberally (S3, RDS, SQS) to move fast. Growth stage: optimize selectively where costs are significant and the team has the expertise to self-manage. Mature stage: strategic decisions about build vs. buy for each component.

The mental model: AWS Service Quotas and Limits Design is infrastructure you rent rather than infrastructure you build and maintain. Renting is more expensive per unit but cheaper in total when you factor in engineering time.

*What separates good from great:* Understanding both when to use AWS Service Quotas and Limits Design and when to NOT use it (when it's cheaper or simpler to self-manage).

---

**[STAFF] Q9 - [TRADE-OFF] Your organization is considering moving from AWS Service Quotas and Limits Design to a self-managed equivalent (or vice versa). What is your decision framework and what would trigger the migration?**

*Why they ask:* Tests strategic architectural thinking about AWS Service Quotas and Limits Design managed vs self-managed trade-offs.

Decision framework: (1) Cost crossover - calculate monthly AWS Service Quotas and Limits Design bill vs cost of self-managed (engineering FTE + infrastructure + ops tooling). Self-managed typically wins at very high scale. (2) Differentiation - does managing this infrastructure provide competitive advantage? If no, managed service is better. (3) Team expertise - does the team have deep expertise to operate self-managed reliably? Managed services reduce operational risk.

Triggers for migrating away from AWS Service Quotas and Limits Design: feature limitation blocking a critical requirement, cost exceeding budget with no optimization path, compliance requirement incompatible with managed service model.

Migration risk: any migration of AWS Service Quotas and Limits Design in production requires a rollback plan, traffic cutover strategy (canary or blue-green), and parallel-run period to validate behavior before full cutover.

*What separates good from great:* Doing the TCO analysis in a spreadsheet before the architecture review, not during it.

#### CONCEPT 1: What are the most important AWS service quotas a production engineer should know?

The most impactful quotas are those that cause silent
failures at scale:

**EC2 instance quotas (per instance family):**

Not a single "EC2 limit" - each instance family has
its own vCPU quota. Common:
- Standard (M, T, R, X families): 32-96 vCPU default
- High Memory: separate, often lower
- Spot: higher limits, separate pool from On-Demand

**Lambda concurrent executions (1,000):**

Per account, per region. All Lambda functions share
this pool. Burst capacity: up to 3,000 in some regions,
then 500/minute additional. After burst capacity: throttling.
Reserve concurrency: set minimum reserved concurrency
for critical functions to protect them from noisy neighbors.

**API Gateway (10,000 req/s per account per region):**

Shared across ALL APIs in the account. A burst on one
API throttles others. Default burst: 5,000.

**RDS instances per region (40):**

40 DB instances default. At 1 per microservice (20 services
* 3 environments = 60): exceeds default.

**CloudFormation stacks per region (2,000):**

CDK generates 1+ stacks per service. 200 microservices
* 3 environments = 600+. Plan for this at scale.

**EIP per region (5):**

NAT Gateways require EIP. 3 AZs * 1 NAT = 3 EIPs.
Plus load balancer EIPs: quickly at 5.

*What separates good from great:* The hidden quota:
AWS Systems Manager Parameter Store has a 10,000
standard parameter limit per region. At scale with
one SSM parameter per config key per environment per
service: 200 services * 50 parameters * 3 environments
= 30,000 parameters. Exceeds the limit. Use advanced
parameters (cost extra) or consolidate to JSON blobs.

---

#### CONCEPT 2: How do you design AWS architectures that respect service quotas?

Quota-aware architecture follows four principles:

**Principle 1: Account-per-workload for quota isolation**

Each workload account has its own quota pool. 10 services
in 10 accounts: each has its own 1,000 Lambda concurrent
limit. A traffic spike on service A does not throttle service B.

**Principle 2: Monitor usage, not just limits**

Set CloudWatch alarms at 80% of quota (not 100%).
AWS/Usage namespace has ResourceCount metrics for
most quotas. Alert at 80%: time to request an increase
before hitting the ceiling.

**Principle 3: Request increases proactively**

Before planned events: submit increases 2-4 weeks ahead.
Automate via IaC: Terraform `aws_servicequotas_service_quota`
resource. Include quota requests in the "launch checklist"
for capacity planning.

**Principle 4: Design for quota expansion**

Use patterns that allow distributing across quota pools:
- Partitioned SQS queues (multiple queues) instead of one
- Multiple Lambda functions with reserved concurrency
  allocated strategically
- Multiple API Gateway APIs rather than one monolithic API

*What separates good from great:* Quotas drive multi-account
architecture more than most architects admit. The "one
account per team" vs "one account per service" debate
is often settled by quota math: if a single service
can legitimately need 500 Lambda concurrent executions,
and there are 5 such services, a single account is
already at the 1,000 limit with no headroom for other
services. Separate accounts eliminate the shared-quota
contention problem.

---

#### DEBUGGING 1: Lambda throttling during a traffic spike. Is it quota or code?

*Symptom:* Lambda functions returning `429 TooManyRequests`
during a traffic spike. CloudWatch shows `Throttles` metric
increasing. Some invocations complete, others throttle.

*Distinguish quota throttle vs function throttle:*

```bash
# Check account-level concurrency usage:
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name ConcurrentExecutions \
  --period 60 --statistics Maximum ...
# If near 1000 (default): account quota reached

# Check if specific function has reserved concurrency:
aws lambda get-function-concurrency \
  --function-name my-function
# ReservedConcurrentExecutions: N (if set)
# If set: function is throttled at N, not account limit

# Check function-level throttles:
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=my-function \
  --period 60 --statistics Sum ...
```

> **Code walkthrough:** This Check function-level throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Root cause 1: Account concurrent limit reached*

Fix: request Lambda concurrency increase.
```bash
aws service-quotas request-service-quota-increase \
  --service-code lambda \
  --quota-code L-B99A9384 \
  --desired-value 10000
```

> **Code walkthrough:** This Check function-level throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Root cause 2: Reserved concurrency too low on function*

Fix: increase or remove reserved concurrency:
```bash
aws lambda put-function-concurrency \
  --function-name my-function \
  --reserved-concurrent-executions 500
```

> **Code walkthrough:** This Check function-level throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*What separates good from great:* Lambda reserved
concurrency is a double-edged sword. Setting it too
high wastes quota for other functions. Setting it
too low throttles your critical function. The correct
value: measure the peak concurrent executions over
30 days, add 20% buffer, set as reserved concurrency.
Unreserved functions compete for the remaining pool.
Critical functions (payment processing): set reserved
concurrency. Non-critical functions (batch reports):
leave unreserved.

---

#### DEBUGGING 2: CloudFormation stack creation fails with resource limit exceeded.

*Symptom:* `Error: Limit 2000 was exceeded for
Resource Type: AWS::CloudFormation::Stack`.

*Diagnosis:*
```bash
# Count existing stacks:
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries | length(@)'
# If near 2000: quota reached

# Check for orphaned stacks (old feature flags, unused):
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE \
  --query 'StackSummaries[?LastUpdatedTime < `2023-01-01`]
    .{Name:StackName,Updated:LastUpdatedTime}'
# Old stacks not updated in 2+ years: candidates for deletion
```

> **Code walkthrough:** This Old stacks not updated in 2+ years: candidates for deletion example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:*
```bash
# Option 1: Request quota increase:
aws service-quotas request-service-quota-increase \
  --service-code cloudformation \
  --quota-code L-0485CB21 \
  --desired-value 5000

# Option 2: Delete unused stacks:
aws cloudformation delete-stack --stack-name old-stack-name

# Option 3: Use nested stacks (counts as 1 parent):
# CDK stack splitting: move resources into nested stacks
# NestedStack in CDK reduces top-level stack count
```

> **Code walkthrough:** This NestedStack in CDK reduces top-level stack count example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*What separates good from great:* CDK generates one
CloudFormation stack per `Stack` class. Large CDK
projects can have 500+ stacks before anyone notices
the approaching limit. CDK best practice: use nested
stacks (`NestedStack` class) for logical groupings.
200 services * 3 environments = 600 nested stacks
inside 6 top-level stacks (one per environment tier).
This keeps the top-level stack count low while
preserving logical isolation.

---

#### TRADE-OFF 1: Request quota increase vs refactor for lower quota usage.

**Request increase:**

Fast (1-5 days). Zero code change. Solves the problem now.
Risk: relies on AWS approval (not guaranteed, especially
for extreme values). Does not solve the architectural
inefficiency (if using 900 Lambda concurrent = system
is likely doing something inefficient).

**Refactor for lower quota usage:**

Lambda concurrency optimization:
- Reduce function duration (less concurrent overlap)
- Move high-volume to SQS + Lambda batch processing
  (one invocation processes 10 messages: 10x less concurrency)
- Split to separate account (each has own quota)

EC2 vCPU optimization:
- Right-size instances (fewer large instances vs many small)
- Use ARM (Graviton): separate quota pool than x86

Timeline: weeks. Improves efficiency, reduces cost.

**Decision:**

Request increase AND optimize. The increase is immediate
mitigation. The refactor is the long-term fix that
also reduces cost. Relying solely on quota increases
masks inefficiencies. Treating quota exhaustion as a
bug (not a capacity issue) leads to better architecture.

*What separates good from great:* Lambda concurrent
execution quota exhaustion often indicates batch
processing design issues. If 1,000 Lambda functions
are simultaneously active: each is processing one item.
A queue with 1,000 messages triggers 1,000 Lambda
invocations. With `BatchSize=10` on the SQS event
source: 100 Lambda invocations process 1,000 messages.
10x less concurrency for the same throughput. Quota
exhaustion is a signal to review batch size configuration.

---

#### TRADE-OFF 2: Per-account quota isolation vs operational overhead.

**One account, all services:**

Lambda quota: 1,000 shared. All 20 services compete.
EC2 quota: single pool.

Pros: simple (1 account to manage, bill, review).
Cons: quota contention. One service's burst throttles others.

**One account per service:**

Lambda quota: 1,000 per service. No contention.

Pros: quota isolation, blast radius limited.
Cons: 20 accounts = 20x operational overhead
(IAM, billing, VPC, monitoring all repeated).
Account Factory and Control Tower essential.

**Hybrid: account per team, not per service:**

Team A (5 services) in Team A account.
Team B (5 services) in Team B account.
4 teams = 4 accounts.

Lambda: 4 * 1,000 = 4,000 total vs 20 * 1,000 for full isolation.
Blast radius: team-level, not service-level.

*What separates good from great:* Lambda reserved
concurrency is the tactical answer to quota isolation
within a single account. If full account isolation
is too many accounts: use reserved concurrency to
allocate the 1,000 pool among services. Service A
(critical): 400 reserved. Service B: 300 reserved.
Service C-Z: share the remaining 300 unreserved pool.
Critical services protected; less critical compete
for the remainder. This is quota partitioning within
an account.

---

#### BEHAVIORAL 1: Describe a production incident caused by a quota limit.

**Situation:** E-commerce platform. Product launch event.
Marketing campaign drove 10x normal traffic at midnight.

**Incident timeline:**

T+0: Traffic starts. 5,000 requests/minute -> 50,000/minute.
T+5min: Lambda ThrottledRequests alarm fires.
T+6min: SQS queue depth starts growing (Lambda throttled,
  can't process messages fast enough).
T+8min: Customer-facing order processing times out (10s).
  5% of orders failing.
T+15min: On-call paged.
T+20min: Diagnosis: Lambda ConcurrentExecutions = 997/1,000.
  At limit. Burst capacity not triggering fast enough.

**Root cause:**

Lambda default: 1,000 concurrent. Burst: additional 500/minute.
Traffic spike: 10x in 2 minutes. Lambda could not scale
500/minute fast enough. Hit the account-level ceiling.

**Resolution:**

Immediate: submit quota increase to 5,000 (takes 2 hours
to approve). Meanwhile: scale ECS Fargate workers to
consume SQS queue (Fargate not quota-limited the same way).
Queue drained. Orders processed. Outage: 45 minutes.

**Post-mortem:**

1. All critical services: calculate peak concurrency needed,
   add 20% buffer, submit quota increase proactively.
2. Lambda concurrency CloudWatch alarm at 80%: added.
3. Fallback path: ECS always running (minimal), scales
   to handle SQS when Lambda is throttled.
4. Load testing before every major launch.

*What separates good from great:* The fallback ECS
workers were the actual fix during the incident. The
quota increase arrived after the incident resolved.
For true reliability: design so quota exhaustion degrades
gracefully (ECS fallback processes the queue more slowly)
rather than fails completely (Lambda throttling + queue
backup = total failure). Quotas cannot always be
increased in time for an unexpected event.

---

#### SCENARIO 1: Plan quota strategy for a platform migration from 1 account to 20 accounts.

**Starting state:** 1 account, 15 microservices.
Lambda quota: 1,000 shared. Multiple throttling incidents.
EC2 quota: multiple near-misses during peak.
Target: 20 accounts (one per service) over 6 months.

**Quota strategy per new account:**

```bash
# Script: request quota increases for new accounts
# Run after each account is provisioned:

ACCOUNT_ID=$1
REGION="us-east-1"

# Assume role in new account:
CREDS=$(aws sts assume-role \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/OrgAccessRole" \
  --role-session-name quota-setup)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r .Credentials.SessionToken)

# Lambda concurrency: 5,000 per service (burst safe):
aws service-quotas request-service-quota-increase \
  --service-code lambda --quota-code L-B99A9384 \
  --desired-value 5000

# EC2 Standard vCPU: 200 per service account:
aws service-quotas request-service-quota-increase \
  --service-code ec2 --quota-code L-1216C47A \
  --desired-value 200

# VPCs per region: 10 (vs default 5):
aws service-quotas request-service-quota-increase \
  --service-code vpc --quota-code L-F678F1CE \
  --desired-value 10
```

> **Code walkthrough:** This VPCs per region: 10 (vs default 5): example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*What separates good from great:* Include quota requests
in the Account Factory for Terraform (AFT) customization.
Every new account automatically requests standard
quota increases via a Step Functions pipeline.
No manual quota management. New accounts are production-ready
in 15 minutes (including quota increase requests,
which process asynchronously).

---

#### SCENARIO 2: A microservices platform needs 50,000 Lambda concurrent executions across 50 services.

**Design:**

50 services * 1,000 avg concurrent per service =
50,000 total Lambda concurrent executions needed.

**Option A: 1 account, quota increase to 50,000:**

Submit quota increase to 50,000.
All services in one account.
Pros: simple.
Cons: any service's bug causes cross-service throttling.
Lambda quota spikes are per-account, not per-function.

**Option B: 50 accounts (one per service), each 1,000:**

Default quota: 50 * 1,000 = 50,000 total (no increase needed!).
Pros: full isolation. Default quotas sufficient.
Cons: 50 accounts to manage.

**Option C: 5 accounts, 10 services per account, quota 10,000 each:**

5 * 10,000 = 50,000 total.
Submit 5 quota increase requests to 10,000 each.
Pros: balance of isolation and manageability.
Cons: 10-service blast radius per account.

**Recommendation:**

Option B (50 accounts) via Account Factory.
Default quotas are sufficient - no requests needed.
Cost of multi-account management: automated via Control Tower + AFT.
Blast radius: per-service. No cross-service quota contention.

*What separates good from great:* The "free" quota is
the key insight. 50 accounts * 1,000 default Lambda
concurrency = 50,000 total, achieved without any quota
increase requests. Multi-account architecture literally
multiplies available quota at no cost (no charge per
account). This is a concrete, quantifiable benefit of
account-per-service that often tips the architectural
decision.

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


# AWS Service Selection Frameworks

**Interview Weight:** ★★☆ - Architecture decision-making.
AWS has 200+ services. Architects must have decision
frameworks for choosing between similar services:
compute (Lambda vs Fargate vs EC2), messaging (SQS vs
SNS vs EventBridge vs Kinesis), storage (S3 vs EFS vs
EBS vs FSx), and database (RDS vs DynamoDB vs ElastiCache
vs Redshift). The framework must encode trade-offs,
not just list features.

---

### 🎯 Model Answer

**30 seconds:**

> AWS service selection follows a decision hierarchy:
> managed > semi-managed > self-managed (for operational
> simplicity). Within a category: start with the
> constraints (latency, throughput, consistency, cost)
> and map them to service capabilities. Compute: Lambda
> for event-driven short-duration, Fargate for
> containerized, EC2 for maximum control/GPU/long-running.
> Messaging: SQS for decoupling, SNS for fan-out,
> EventBridge for event routing, Kinesis for ordered
> streaming. Database: DynamoDB for key-value scale,
> RDS/Aurora for relational ACID, ElastiCache for
> sub-millisecond cache.

**3 minutes:**

> Compute selection:
>
> Lambda: event-driven (API calls, S3 events, SQS),
> max 15-minute execution, no server management.
> Limit: 6MB response, cold starts, no persistent state.
>
> Fargate: container workloads without EC2 management.
> Longer running, more memory (120GB), more CPU (16 vCPU).
> Use: API services, batch jobs, workers.
>
> EC2: maximum control. GPU workloads (ML training),
> specialized networking (enhanced), legacy software
> requiring specific OS, long-running processes
> requiring persistent local storage.
>
> Messaging/eventing:
>
> SQS: point-to-point reliable delivery. Worker queue.
> One consumer per message. At-least-once delivery.
> SNS: one-to-many pub/sub. Push to multiple subscribers.
> EventBridge: event routing with content-based rules.
> Connect 150+ SaaS sources. Schema registry.
> Kinesis: ordered, high-throughput streaming. Real-time
> analytics. Multiple consumers reading the same stream.

**Blank Mind Recovery:**

**(1) Compute:** "Lambda=event/short. Fargate=container.
EC2=control/GPU/long-running."

**(2) Messaging:** "SQS=decouple one consumer. SNS=fan-out.
EventBridge=routing/SaaS. Kinesis=ordered streaming."

**(3) Database:** "DynamoDB=key-value/scale. Aurora=relational/ACID.
ElastiCache=sub-ms cache. Redshift=analytics."

---

### 📘 Concept Explanation

**Service selection decision hierarchy:**

```
When selecting any AWS service:

1. What is the access pattern?
   Key-value lookup: DynamoDB
   Relational queries: RDS/Aurora
   Time-series: Timestream
   Graph: Neptune
   Document: DocumentDB or DynamoDB

2. What are the SLA requirements?
   Sub-millisecond: ElastiCache
   Single-digit ms: DynamoDB
   10-100ms: RDS/Aurora
   > 100ms: Acceptable for analytical (Athena, Redshift)

3. What is the write/read ratio?
   Read-heavy (100:1): read replicas or cache
   Write-heavy (1:10): single-writer, replicated reads
   Equal: DynamoDB (scales both independently)

4. Consistency requirements?
   Strongly consistent: RDS/Aurora (single writer)
   Eventually consistent: DynamoDB (default reads)
   No consistency needed: S3, ElastiCache

5. Is the scale predictable?
   Predictable: RDS provisioned + Reserved Instances
   Unpredictable/variable: DynamoDB on-demand or Serverless
   
6. What is the data structure?
   Structured rows/columns: RDS/Aurora
   Semi-structured/JSON: DynamoDB or DocumentDB
   Wide columns: Keyspaces (Cassandra)
   Binary/files: S3
```

> **Code walkthrough:** This AWS Service Selection Frameworks example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```python
# BAD: Using DynamoDB for relational queries
# DynamoDB requires knowing the access pattern upfront
# Ad-hoc relational queries on DynamoDB = full table scan

# "Find all orders where customer.email LIKE '%@company.com'
#  AND status='PENDING' AND total > 1000 AND created last 30d"
# DynamoDB: scan entire table + filter in application
# At 100M orders: 100M reads, $50+ per query, minutes to return

import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('orders')

response = table.scan(  # Full table scan - NEVER do this for filtering
    FilterExpression='status = :s AND total > :t',
    ExpressionAttributeValues={':s': 'PENDING', ':t': Decimal('1000')}
)
```

> **Code walkthrough:** This At 100M orders: 100M reads, $50+ per query, minutes to return example demonstrates Python runtime behavior. **KEY MECHANISM:** the CPython interpreter executes this via reference counting and GIL coordination. **WHY IT MATTERS:** blocking calls inside async contexts starve the event loop and freeze all coroutines. **TAKEAWAY: match synchronous vs asynchronous context to the I/O model of the operation.**

```sql
-- GOOD: Aurora for ad-hoc relational queries
-- OLTP + complex queries = relational database
-- Indexes support the query patterns

-- Schema designed for query patterns:
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    status VARCHAR(20),
    total DECIMAL(10,2),
    created_at TIMESTAMP,
    INDEX idx_status_created (status, created_at),
    INDEX idx_customer (customer_id)
);

-- Query runs efficiently with index:
SELECT o.*, c.email FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE c.email LIKE '%@company.com'
  AND o.status = 'PENDING'
  AND o.total > 1000
  AND o.created_at > NOW() - INTERVAL 30 DAY;
-- Full index usage: status+created_at + customer join
```

> **Code walkthrough:** This At 100M orders: 100M reads, $50+ per query, minutes to return example demonstrates SQL query execution plan. **KEY MECHANISM:** the database planner builds an execution plan from table statistics; sequential scan vs index scan differs by 100x. **WHY IT MATTERS:** SELECT * widens rows increasing I/O; missing WHERE clause on UPDATE/DELETE affects all rows with no undo. **TAKEAWAY: always SELECT only needed columns; use EXPLAIN ANALYZE to verify the execution plan.**

```python
# Service selection in code: choosing between
# SQS, SNS, and EventBridge by use case

import boto3

# SQS: decoupled worker queue (one consumer per message)
# Use case: order processing - one worker processes each order
sqs = boto3.client('sqs')
sqs.send_message(
    QueueUrl='https://sqs.us-east-1.amazonaws.com/.../orders',
    MessageBody=json.dumps({'orderId': 'ORD-123', 'action': 'process'}),
    MessageGroupId='customer-456'  # FIFO: ensures order per customer
)

# SNS: fan-out (multiple consumers of same message)
# Use case: order placed event -> email + analytics + inventory
sns = boto3.client('sns')
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:...:order-events',
    Message=json.dumps({'orderId': 'ORD-123', 'event': 'PLACED'}),
    # Subscribers: email-service, analytics-service, inventory-service
    # All three receive the same message simultaneously
)

# EventBridge: event routing with rules
# Use case: route different event types to different consumers
events = boto3.client('events')
events.put_events(
    Entries=[{
        'Source': 'com.myapp.orders',
        'DetailType': 'OrderStatusChanged',
        'Detail': json.dumps({
            'orderId': 'ORD-123',
            'oldStatus': 'PENDING',
            'newStatus': 'SHIPPED'
        })
    }]
)
# Rules route based on DetailType:
# OrderStatusChanged -> shipping-service Lambda
# OrderPlaced -> email-service + inventory Lambda
# PaymentFailed -> fraud-detection Lambda
```

> **Code walkthrough:** The BAD pattern uses DynamoDBice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> for a relational query (multi-column filtering with
> JOIN-equivalent). DynamoDB's `scan` reads the entire
> table to apply filters. At 100M orders: 100M reads
> at $0.25 per million = $25 just for one query.
> Aurora handles this efficiently with appropriate
> indexes. The messaging pattern demonstrates the
> correct service per use case: SQS for worker queues
> (one consumer per message, at-least-once delivery),
> SNS for fan-out (multiple independent subscribers
> receiving the same message), EventBridge for event
> routing (content-based rules directing events to
> different targets based on event type).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "AWS service selection depends on the use case. For
> serverless compute without managing servers: Lambda
> for short-duration functions, Fargate for containers.
> For databases: DynamoDB for simple key-value at scale,
> RDS for relational data with SQL. For messaging:
> SQS for queuing, SNS for publishing to multiple
> subscribers. The key is matching the service's
> capabilities to the specific access pattern."

**Senior / Staff:**

> "Service selection is a trade-off matrix, not a
> feature comparison. The three axes: operational
> complexity (managed vs self-managed), performance
> characteristics (latency/throughput/consistency),
> and total cost (compute + storage + transfer + operations).
>
> My framework question sequence:
>
> First: what access pattern drives this service?
> (key-value, relational, streaming, event-driven)
>
> Second: what are the SLA requirements?
> (sub-ms: cache required, single-digit ms: DynamoDB,
> 10-100ms: relational, bulk analytics: Redshift)
>
> Third: scale characteristics?
> (predictable: provisioned + Reserved Instance,
> variable: serverless/on-demand)
>
> Fourth: consistency requirements?
> (ACID: Aurora, eventual: DynamoDB, none: S3)
>
> Fifth: what is the cost at target scale?
> (calculate actual cost at 10x, 100x)
>
> The anti-pattern: selecting a service because it is
> new/popular (Lambda for everything, DynamoDB always).
> Lambda is wrong for: database-backed CRUD APIs
> (connection overhead), long-running processes, stateful.
> DynamoDB is wrong for: ad-hoc queries, complex joins,
> strong consistency requirements."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Lambda is always cheaper than EC2."**

Lambda pricing: per invocation + duration (GB-seconds).
For a service processing 10M requests/day at 200ms average,
256MB memory: 10M * 0.2s * 0.25GB = 500,000 GB-seconds.
Cost: $8.33/month.

EC2 t4g.small (2 vCPU, 2GB): $0.0168/hr = $12.10/month.
Fargate (0.25 vCPU, 0.5GB): $0.014/hr = $10.11/month.

At this scale: Lambda is cheaper. At 500M requests/day:
Lambda = $416/month. EC2 t4g.large = $50/month.
Lambda scales linearly with requests. EC2 is fixed cost.
At high, predictable volume: EC2 or Fargate is cheaper.

**Misconception 2: "DynamoDB is more scalable than Aurora."**

DynamoDB scales horizontally (more partitions) for
reads and writes. Aurora scales reads vertically (larger
instances) and horizontally (more replicas).

DynamoDB: 40,000 reads/second per table (can request more).
Aurora: 400K+ reads/second across 15 replicas.

Both scale. DynamoDB advantage: truly unlimited write
scaling (sharding transparent). Aurora advantage:
complex queries without redesigning the data model.
The correct framing: DynamoDB scales writes and simple
lookups without schema constraints. Aurora scales complex
relational workloads with familiar SQL.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Wrong service selection causes production
performance issues**

*Scenario 1: RDS/Aurora for a high-write IoT workload*

IoT devices sending 100,000 readings per second.
Team chose RDS MySQL: familiar, relational.
At 100K writes/second: RDS MySQL overwhelmed.
`max_connections` exhausted. Write latency: 5 seconds.

*Diagnosis:*
- Check RDS WriteIOPS and CPUUtilization metrics
- Check slow query log: `INSERT` statements appearing
- Check `DatabaseConnections` at max

*Better service:* Amazon Kinesis Data Streams (ingestion)
-> Lambda/Firehose (processing) -> Timestream (time-series storage)
or DynamoDB (key-value: deviceId + timestamp).

*Scenario 2: DynamoDB for reporting queries*

Finance team needs: "total sales by category, last 7 days,
top 100 customers by order value."

DynamoDB: requires scan + in-memory aggregation.
Cost at 50M orders: $12.50 per query. 100 queries/day = $1,250/day.

*Better service:* Athena on S3 (orders as Parquet files)
or Redshift Serverless. Ad-hoc analytical queries are
the wrong fit for DynamoDB.

---

### ⚖️ Comparison Table

**Compute:**

| Service | Use Case | Max Duration | Cold Start | Cost Model |
|---------|----------|-------------|-----------|-----------|
| Lambda | Event-driven, short | 15 minutes | 100-500ms | Per invocation |
| Fargate | Container, any duration | Unlimited | 30-60s | Per vCPU/GB-hour |
| EC2 | Control, GPU, long-running | Unlimited | Minutes | Per hour (Reserved: savings) |
| App Runner | Simple web apps | Unlimited | 10-30s | Per vCPU/GB-hour |

**Messaging:**

| Service | Pattern | Ordering | Consumers | Retention |
|---------|---------|----------|-----------|-----------|
| SQS Standard | Worker queue | Best-effort | One | 14 days |
| SQS FIFO | Ordered queue | Strict per group | One | 14 days |
| SNS | Fan-out | No | Many (push) | No storage |
| EventBridge | Event routing | No | Rule-based | No storage |
| Kinesis | Ordered stream | Per shard | Many (read same) | 24h-365d |

---

### 📊 Diagram

*(Omit: service selection is a decision tree, adequately
represented by the Comparison Tables above)*

---

### 🎯 Interview Deep-Dive

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 2 |
| TRADE-OFF | 2 |
| BEHAVIORAL | 1 |
| SCENARIO | 2 |

---

---

---

**[MID] Q8 - [DEBUGGING] A service using AWS Service Selection Frameworks is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Service Selection Frameworks beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Service Selection Frameworks issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Service Selection Frameworks specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q9 - [TRADE-OFF] Compare AWS Service Selection Frameworks to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Service Selection Frameworks service landscape and can make informed architectural decisions.

AWS Service Selection Frameworks has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (PaymentFailed -> fraud-detecti, Q9)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (PaymentFailed -> fraud-detecti, Q9)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

**[MID] Q1 - [DEBUGGING] A service using AWS Service Selection Frameworks is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Service Selection Frameworks beyond 'check CloudWatch logs'. (PaymentFailed -> fraud-detecti, Q1)

Diagnostic sequence for AWS Service Selection Frameworks issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes. (PaymentFailed -> fraud-detecti, Q1)

For AWS Service Selection Frameworks specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue. (PaymentFailed -> fraud-detecti, Q1)

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Service Selection Frameworks to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Service Selection Frameworks service landscape and can make informed architectural decisions. (PaymentFailed -> fraud-detecti, Q2)

AWS Service Selection Frameworks has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads. (PaymentFailed -> fraud-detecti, Q2)

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (PaymentFailed -> fraud-detecti, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (PaymentFailed -> fraud-detecti, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Service Selection Frameworks for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Service Selection Frameworks.

Multi-region architecture for AWS Service Selection Frameworks: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (PaymentFailed -> fraud-detecti, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (PaymentFailed -> fraud-detecti, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Service Selection Frameworks cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Service Selection Frameworks cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Service Selection Frameworks: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (PaymentFailed -> fraud-detecti, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Service Selection Frameworks in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Service Selection Frameworks with security as a first-class concern, not an afterthought.

Top security risks for AWS Service Selection Frameworks: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Service Selection Frameworks resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Service Selection Frameworks: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Service Selection Frameworks configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (PaymentFailed -> fraud-detecti, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Service Selection Frameworks that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Service Selection Frameworks experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (PaymentFailed -> fraud-detecti, Q6)

Strong answers include: specific AWS Service Selection Frameworks service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Service Selection Frameworks architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Service Selection Frameworks peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (PaymentFailed -> fraud-detecti, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (PaymentFailed -> fraud-detecti, Q7)

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.

#### CONCEPT 1: How do you choose between SQS, SNS, EventBridge, and Kinesis?

Each service solves a different messaging problem:

**SQS (Simple Queue Service):**

Point-to-point. One message consumed by one worker.
At-least-once delivery. Messages stay in queue until
consumed. Retry: visibility timeout + dead letter queue.
Backpressure: queue depth increases when producers
outpace consumers. Auto Scaling can scale consumers
based on queue depth.

Use SQS when:
- Decoupling producers and consumers (load leveling)
- Worker pool processing (image resizing, order processing)
- Retry on failure is required
- One consumer per message

**SNS (Simple Notification Service):**

One-to-many. One message pushed to multiple subscribers.
No storage: if subscriber is down, message is lost
(unless fanout to SQS). Subscribers: Lambda, SQS,
HTTP endpoints, email, SMS.

Use SNS when:
- Same event needs to trigger multiple independent systems
- Fan-out pattern: one event -> many consumers simultaneously
- Notifications: email, SMS, push notifications

**EventBridge:**

Event routing with content-based rules. Source generates
events, rules route to targets. 150+ native integrations
(Salesforce, Zendesk, GitHub, etc.). Schema registry.
Replay capability (re-process historical events).

Use EventBridge when:
- Complex event routing (different event types -> different consumers)
- SaaS integration (events from third-party services)
- Event-driven microservices (decouple via schema registry)
- Scheduled events (cron-like triggers)

**Kinesis Data Streams:**

Ordered streaming. Multiple consumers can read the
same stream independently. Shards: each shard = 1MB/s
write, 2MB/s read. Retention: 24h to 365 days.
Consumer: Lambda, Kinesis Data Analytics, custom app.

Use Kinesis when:
- Multiple independent consumers need the same data
- Order matters within a partition key
- Real-time analytics alongside storage
- High throughput (millions of events/second)

**Decision flow:**

One consumer per message? SQS.
Multiple consumers of same message? SNS (push) or Kinesis (pull).
Content-based routing? EventBridge.
SaaS integration? EventBridge.
Ordered streaming + multiple consumers? Kinesis.
Fan-out + decoupled subscribers? SNS -> SQS (fanout pattern).

*What separates good from great:* SNS -> SQS fanout
is the pattern for reliable fan-out. SNS pushes to
multiple SQS queues simultaneously. Each downstream
service has its own SQS queue. If a service is down:
its SQS queue buffers messages. Pure SNS to Lambda:
if Lambda is throttled, SNS drops the message (no buffer).
SNS -> SQS -> Lambda: SQS buffers during Lambda throttling.

---

#### CONCEPT 2: Lambda vs Fargate vs EC2. When do you choose each?

**Lambda:**

Execution model: event triggers a function. Function
runs for up to 15 minutes. No persistent server.
Scales to thousands of concurrent executions automatically.

Choose Lambda when:
- Execution is triggered by events (S3, SQS, API GW)
- Duration is short (< 5 minutes typical)
- Variable or spiky load (Lambda scales from 0 to 1,000 in seconds)
- No server management desired
- Cost optimization for intermittent workloads

Do NOT choose Lambda when:
- Long-running processes (> 15 minutes)
- Requires persistent local state
- Requires large memory (> 10GB) or specific CPU
- Database connection-heavy (use Fargate + HikariCP instead)
- Cold start latency is unacceptable (< 100ms p99 required)
  -> Use Lambda Snapstart (Java) or provisioned concurrency

**Fargate:**

Execution model: container runs continuously. No EC2
to manage. Specify vCPU and memory. Scales based on
load (ECS Service Auto Scaling).

Choose Fargate when:
- Containerized workload (existing Docker image)
- API services with persistent connections (DB pools)
- Longer-running workers (batch processing > 15 minutes)
- Need more resources than Lambda allows (up to 16 vCPU, 120GB)
- No cold start latency (containers are always warm)

**EC2:**

Full virtual machine. You manage OS, patches, scaling.

Choose EC2 when:
- GPU workloads (ML training, rendering): P/G instance families
- Specialized networking (enhanced networking, dedicated tenancy)
- License requirements (Windows per-socket, Oracle per-core)
- Maximum performance with predictable load (Reserved Instances)
- Applications requiring OS-level customization
- Local NVMe SSD required (i3/i4 instances)

*What separates good from great:* Fargate Spot is the
underused pattern. Fargate Spot uses spare capacity at
up to 70% discount vs On-Demand. For fault-tolerant
workloads (batch processing, non-interactive tasks):
run Fargate Spot for 70% of tasks. Fall back to On-Demand
for the remaining 30%. Combine: `FARGATE_SPOT` and
`FARGATE` capacity providers with weights 70/30.
Cost reduction: 40-50% of Fargate costs for batch
workloads with no reliability impact.

---

#### DEBUGGING 1: RDS being used where DynamoDB would be better. How do you identify and migrate?

*Detection signals that RDS might be wrong choice:*

1. Single primary key access pattern dominates:
   ```sql
   -- 95% of queries look like this (key-value):
   SELECT * FROM sessions WHERE session_id = 'abc123';
   ```
> **Code walkthrough:** This concept example demonstrates SQL query execution plan. **KEY MECHANISM:** the database planner builds an execution plan from table statistics; sequential scan vs index scan differs by 100x. **WHY IT MATTERS:** SELECT * widens rows increasing I/O; missing WHERE clause on UPDATE/DELETE affects all rows with no undo. **TAKEAWAY: always SELECT only needed columns; use EXPLAIN ANALYZE to verify the execution plan.**

   If 95% of queries are primary key lookups with no JOIN:
   DynamoDB would be more cost-efficient.

2. Read replica count is high (10+ replicas):
   If you need 10 Aurora read replicas to serve
   read throughput: you are working against the
   relational model. DynamoDB auto-scales reads.

3. Application logic doing what the database should:
   ```python
   # Application doing in-memory join:
   users = db.query("SELECT * FROM users WHERE region = 'US'")
   orders = db.query("SELECT * FROM orders WHERE region = 'US'")
   # Joining 1M users + 5M orders in application memory
   ```
> **Code walkthrough:** This concept example demonstrates Python runtime behavior. **KEY MECHANISM:** the CPython interpreter executes this via reference counting and GIL coordination. **WHY IT MATTERS:** blocking calls inside async contexts starve the event loop and freeze all coroutines. **TAKEAWAY: match synchronous vs asynchronous context to the I/O model of the operation.**

   If the data model can be denormalized: DynamoDB single-table
   design handles this in one query.

*Migration approach:*

Phase 1: Identify access patterns from slow query log.
Categorize: key-value, relational, analytics.

Phase 2: Design DynamoDB single-table model for
key-value access patterns.

Phase 3: Dual-write (write to both RDS and DynamoDB),
validate consistency for 2 weeks.

Phase 4: Cut reads to DynamoDB, monitor for correctness.

Phase 5: Stop RDS writes. Decommission RDS.

*What separates good from great:* The single-table
DynamoDB design requires upfront access pattern definition.
If access patterns change after migration: DynamoDB
requires schema redesign (painful). The correct criterion:
if access patterns are known, stable, and primarily
key-value: DynamoDB. If access patterns evolve with
product needs and ad-hoc queries are common: relational
database is more flexible even at higher cost.

---

#### DEBUGGING 2: SNS fan-out drops messages when downstream Lambda is throttled.

*Symptom:* SNS topic pushes to Lambda. During traffic spike:
Lambda throttles (concurrent limit). SNS retries 3 times
(default), then drops the message. Events lost.

*Diagnosis:*
```bash
# Check SNS delivery failures:
aws cloudwatch get-metric-statistics \
  --namespace AWS/SNS \
  --metric-name NumberOfNotificationsFailed \
  --dimensions Name=TopicName,Value=order-events \
  --period 60 --statistics Sum ...
# Non-zero value = messages are being dropped

# Check Lambda throttles:
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=order-processor \
  --period 60 --statistics Sum ...
```

> **Code walkthrough:** This Check Lambda throttles: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix: SNS -> SQS -> Lambda pattern (buffered fan-out)*

```bash
# Create SQS queue as buffer:
aws sqs create-queue --queue-name order-events-buffer

# Subscribe SQS to SNS (instead of Lambda directly):
aws sns subscribe \
  --topic-arn arn:aws:sns:...:order-events \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:...:order-events-buffer

# Create SQS event source mapping to Lambda:
aws lambda create-event-source-mapping \
  --function-name order-processor \
  --event-source-arn arn:aws:sqs:...:order-events-buffer \
  --batch-size 10 \
  --maximum-batching-window-in-seconds 5
```

> **Code walkthrough:** This Create SQS event source mapping to Lambda: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Now: SNS -> SQS (buffer). Lambda pulls from SQS.
If Lambda throttles: SQS buffers. No messages dropped.
SQS visibility timeout handles retry.
Dead letter queue catches persistent failures.

*What separates good from great:* The SNS -> SQS
pattern also decouples throughput. SNS can send 100K
events/second to SQS. Lambda consumes at its own pace.
Queue depth metric: if growing, scale Lambda (or
increase concurrency). The queue provides backpressure
visibility: queue depth = how far behind the consumer is.

---

#### TRADE-OFF 1: DynamoDB vs Aurora for a product catalog with 10M items.

**Access patterns for product catalog:**

Read-heavy (1,000 reads per write).
Primary access: `GET /products/{id}` (key-value lookup).
Search: full-text search by name, category, price range.
Reporting: total products per category, average price.

**DynamoDB:**

Key-value lookups: exceptional performance, < 10ms.
Search: no built-in. Requires OpenSearch integration
(sync via DynamoDB Streams + Lambda -> OpenSearch).
Reporting: requires DynamoDB Streams + Lambda + S3 + Athena.

Cost at 10M items, 1B reads/month:
On-demand: 1B * $0.25/M = $250/month + storage.
Reserved capacity: 50-75% savings for predictable load.

**Aurora MySQL:**

Key-value lookups: 5-20ms (index on product_id).
Search: FULLTEXT index or LIKE (limited).
Better: Aurora + CloudSearch/OpenSearch integration.
Reporting: native SQL (fast with proper indexes).

Cost at 10M items, 1B reads/month:
Read replicas handle 1B reads. r6g.large * 3 replicas = ~$1,500/month.
But: far simpler SQL reporting, existing team skills.

**Decision:**

Start with Aurora: team knows SQL. Reporting is free
(native SQL). Adds search via OpenSearch when needed.
Migrate to DynamoDB if write throughput exceeds Aurora's
capacity or latency below 10ms becomes a hard requirement.

*What separates good from great:* The operational
complexity of DynamoDB single-table design is the
hidden cost. Designing access patterns, global secondary
indexes, and query patterns requires DynamoDB expertise.
Aurora requires SQL knowledge (universal). For a startup:
Aurora's familiarity reduces engineering time. At
hyperscale: DynamoDB's operational simplicity at
massive scale justifies the upfront design investment.

---

#### TRADE-OFF 2: Kinesis Data Streams vs SQS for event streaming.

**SQS (Standard or FIFO):**

Message consumed once by one consumer.
At-least-once delivery.
Message retention: up to 14 days.
Scale: automatic.
Consumers: pull-based (Lambda or EC2).

Use when: one consumer needs each message.
Worker queue: tasks distributed across workers.

**Kinesis Data Streams:**

Same data readable by multiple independent consumers.
Each consumer reads the full stream independently.
Shard-based throughput: 1MB/s per shard write.
Consumer can replay messages within retention window.
Ordering: guaranteed within partition key.

Use when: multiple systems need the same events.
Real-time analytics + storage + alerting from same stream.

**Concrete example:**

IoT sensor data: temperature readings, 100K/second.

SQS: each reading processed once by one Lambda.
If you need: storage + real-time dashboard + alerting,
publish the same data to 3 different SQS queues (manual fan-out).

Kinesis: one stream. Storage Lambda reads it.
Dashboard Lambda reads it. Alerting Lambda reads it.
All independently, same data. Simpler architecture.

**Cost comparison at 100K events/second:**

Kinesis: 100K * 1KB average = 100MB/s write.
100 shards at $0.015/hr = $1.08/day + $0.014/PUT = $86.4K/day.
Wait: at 100K events/s, SQS is also expensive.
Kinesis charges per shard, not per record.
At high volume: Kinesis pricing better than SQS per-record.

*What separates good from great:* Kinesis Enhanced Fan-Out
is the solution for multiple high-throughput consumers.
Standard Kinesis: 2MB/s per shard shared across consumers.
Enhanced Fan-Out: 2MB/s per shard PER consumer (dedicated).
5 consumers on a 10-shard stream: Enhanced Fan-Out gives
5 * 10 * 2MB/s = 100MB/s total throughput (vs 20MB/s shared).
Cost: $0.015/shard-hour + $0.013/GB (EFO). At scale:
the throughput guarantee is worth the additional cost.

---

#### BEHAVIORAL 1: Describe a time you chose the wrong AWS service and had to migrate.

**STAR:**

**Situation:** Real-time analytics dashboard for a
logistics platform. 10,000 truck GPS updates/minute.
Dashboard showing: active trucks, routes, delays.
Team chose DynamoDB (familiar key-value store).

**Problem (3 months after launch):**

Dashboard query: "Show all trucks that have been
stationary for > 30 minutes AND are currently within
50km of a distribution center."

DynamoDB: no geospatial queries. Required: full table
scan on 100K truck records + in-application geofencing.
Cost: $8/query. Dashboard refreshes every 30 seconds.
Monthly query cost: $8 * 2/minute * 60 * 24 * 30 = $69,120/month.

**Migration:**

Evaluation matrix (built explicitly):
- Query patterns: geospatial, time-series, aggregations
- DynamoDB: fails on all three
- PostgreSQL (RDS): PostGIS extension, time-series via TimescaleDB
- Amazon Timestream: native time-series, no geospatial
- OpenSearch: geospatial + time-series + aggregations

Chose: DynamoDB (for current state, key-value lookup)
+ OpenSearch (for analytics queries).
DynamoDB Streams: on every truck update -> Lambda -> OpenSearch index update.
Dashboard: queries OpenSearch (sub-second, geospatial).
DynamoDB: used only for current truck state (fast key-value).

**Outcome:**

Migration: 3 weeks. No downtime (dual-write pattern).
Query cost: DynamoDB reads (current state) = $0.01/query.
OpenSearch: $0.10/query (analytics).
Total: $0.11/query vs $8.00/query. 98.6% cost reduction.
Dashboard latency: 8 seconds -> 200ms.

*What separates good from great:* The architectural
mistake was not choosing DynamoDB - it was choosing
DynamoDB without fully mapping the access patterns.
The "stationary for 30 minutes within 50km" query
was known before the design was finalized but was
considered an "edge case." It turned out to be the
most frequently used dashboard feature. Access pattern
analysis must include all known queries, weighted by
frequency, before service selection.

---

#### SCENARIO 1: Design the data layer for a real-time ride-sharing application.

**Access patterns:**

1. `GET /drivers/nearby?lat=37&lng=-122&radius=5km`
   10,000/second. Response < 100ms.
2. `GET /rides/{rideId}` - current ride state
   50,000/second.
3. Driver location updates: 100,000/second (GPS ping).
4. Ride history: `GET /riders/{riderId}/history?month=2024-01`
5. Analytics: surge pricing by zone, demand prediction.

**Service mapping:**

Access pattern 1 (nearby drivers):
-> ElastiCache for Redis (GEOADD/GEORADIUS command)
-> Driver updates geospatial index in Redis
-> Query: GEORADIUS lat lng 5km ASC COUNT 20
-> Sub-millisecond, in-memory geospatial

Access pattern 2 (ride state):
-> DynamoDB (primary key = rideId)
-> Single-digit ms. Globally consistent reads for payment.
-> TTL: rides expire after 30 days (auto-delete old records)

Access pattern 3 (driver location updates):
-> Kinesis Data Streams (100K records/s ingestion)
-> Lambda consumer 1: update Redis geospatial index
-> Lambda consumer 2: store in DynamoDB + S3 Parquet

Access pattern 4 (ride history):
-> DynamoDB Global Secondary Index: riderId + created_at
-> Query by riderId partition key + sort by date
-> Or: Athena on S3 Parquet (better for months of data)

Access pattern 5 (analytics):
-> S3 Parquet (from Kinesis Firehose)
-> Athena SQL for ad-hoc analysis
-> Redshift Serverless for repeated BI queries

*What separates good from great:* Redis GEORADIUS
is the correct service for sub-100ms geospatial queries.
DynamoDB has no geospatial index. Aurora PostGIS would
work but adds database load. Redis keeps driver locations
in memory (100K drivers * 16 bytes = 1.6MB - trivially fits).
The polyglot persistence approach (Redis + DynamoDB +
S3/Athena) uses the right tool for each access pattern
instead of forcing one database to serve all patterns.

---

#### SCENARIO 2: A startup is choosing a technology stack for a new B2C SaaS. Recommend services.

**Context:**

10 developers. 0 to 100K users in year 1.
Product: task management SaaS. API + web + mobile.
Requirements: minimize operational overhead, ship fast.

**Recommended stack:**

```
Compute:
  API (Node.js): Fargate + ECS
    Not Lambda: persistent DB connections, faster cold starts
    Not EC2: too much operational overhead
  Background jobs: Lambda (SQS triggers)
  Scheduled tasks: EventBridge Scheduler -> Lambda

Database (primary):
  Aurora Serverless v2 (PostgreSQL)
    0.5 ACU minimum (idle dev: nearly free)
    Scales to 64 ACU on load spikes
    Relational: flexible queries as product evolves
    Not DynamoDB: access patterns will evolve with product

Caching:
  ElastiCache Redis (Serverless)
    Sessions, rate limiting, frequently accessed data
    Serverless: scales with usage, no capacity planning

Storage:
  S3 + CloudFront
    User uploads, attachments, static assets
    CDN for low-latency global delivery

Messaging:
  SQS (standard): async jobs (email sends, notifications)
  EventBridge: service-to-service events

Authentication:
  Amazon Cognito
    Manages users, OAuth, MFA, password reset
    Not custom: saves weeks of auth development

Observability:
  CloudWatch Logs + X-Ray + CloudWatch Container Insights
  Later: move to Datadog when at scale

IaC:
  AWS CDK (TypeScript)
    Type-safe infrastructure, team already knows TypeScript
```

> **Code walkthrough:** This Create SQS event source mapping to Lambda: example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

**Year 1 estimated cost:**

100K users, 10M API calls/month:
- Fargate (2 tasks, r1 vCPU): ~$100/month
- Aurora Serverless (avg 2 ACU): ~$175/month
- ElastiCache Serverless: ~$30/month
- S3 + CloudFront: ~$50/month
- Total: ~$400/month for 100K users

Scales cost-efficiently: Fargate and Aurora scale with
load, not fixed capacity. At 1M users: ~$2,000/month
(linear scale, not exponential).

*What separates good from great:* The Cognito choice
deserves justification. Auth is a security-critical
component where mistakes have outsized consequences.
Cognito handles: OAuth flows, token rotation, MFA,
brute-force protection, password breach detection.
Building this from scratch: 4-6 weeks of senior
engineering time + ongoing security patching.
At 0-100K users: Cognito is free for the first
50K Monthly Active Users. The decision is clear:
use Cognito. Revisit only if hitting Cognito-specific
limitations at >1M users.

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



