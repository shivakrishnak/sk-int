---
layout: default
title: "AWS - L1 Storage and Networking"
parent: "AWS"
nav_order: 3
permalink: /aws/l1-storage-and-networking/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 7 | [S3 Buckets and Storage Classes](#s3-buckets-and-storage-classes) | ★☆☆ |
| 8 | [VPC Networking in AWS](#vpc-networking-in-aws) | ★☆☆ |
| 9 | [Route 53 and DNS Routing](#route-53-and-dns-routing) | ★☆☆ |

---

# S3 Buckets and Storage Classes

**Interview Weight:** ★☆☆ - Core storage knowledge.
S3 is AWS's object storage service and the most commonly
used AWS service. Understanding buckets, storage classes,
access control, versioning, and cost optimization via
lifecycle policies is expected from any AWS engineer.

---

### 🎯 Model Answer

**30 seconds:**

> S3 stores objects in buckets. Each object is addressed
> by bucket name plus key (a string like a file path).
> Storage classes optimize cost vs retrieval speed:
> Standard (frequent access, highest cost), Standard-IA
> (infrequent access, cheaper storage, retrieval fee),
> Glacier (archival, minutes to hours retrieval, cheapest).
> S3 has 11 nines durability. Buckets are private by
> default; access via IAM policies, bucket policies,
> or pre-signed URLs.

**3 minutes:**

> S3 fundamentals:
>
> Bucket: container for objects. Globally unique name.
> Region-specific (data stays in the region unless
> cross-region replication is configured).
>
> Object: any file. Max size per single PUT: 5GB.
> Files over 100MB: use Multipart Upload. Max object
> size: 5TB.
>
> Key: the address of an object within a bucket.
> Example: `images/2024/photo.jpg`. There are no real
> folders in S3 - the key is just a flat string.
> The console shows slash-separated keys as folders.
>
> Storage classes:
>
> Standard: ~$0.023/GB/month. Millisecond retrieval,
>   no retrieval fee. For: active data accessed frequently.
>
> Standard-IA: ~$0.0125/GB storage + $0.01/GB retrieval.
>   Minimum 30-day storage. For: backups, DR data,
>   accessed < once per month.
>
> Glacier Instant Retrieval: ~$0.004/GB storage.
>   Millisecond retrieval + fee. Min 90 days.
>   For: archives accessed occasionally.
>
> Glacier Flexible Retrieval: minutes to hours.
>   Very cheap storage. For: data not accessed for months.
>
> Glacier Deep Archive: ~$0.001/GB/month. Retrieval 12-48hr.
>   For: 7-year compliance retention.
>
> Lifecycle policies: automatically transition objects
> between classes or delete after N days.

**Blank Mind Recovery:**

**(1) Basics:** "Bucket + key = object. 11 nines durability.
Global unique bucket name."

**(2) Classes:** "Standard (frequent), IA (infrequent +
retrieval fee), Glacier (archive, hours, cheapest)."

**(3) Access:** "Private by default. IAM, bucket policy,
pre-signed URL."

---

### 📘 Concept Explanation

**Storage Class Selection:**

```
CLASS               | COST    | RETRIEVAL | MIN   | USE CASE
--------------------|---------|-----------|-------|------------
Standard            | $$$     | ms        | none  | Active data
Standard-IA         | $$      | ms +fee   | 30d   | Backups
Glacier Instant     | $       | ms +fee   | 90d   | Archive, monthly
Glacier Flexible    | $       | 1-12hr    | 90d   | Yearly archives
Glacier Deep Arc    | $       | 12-48hr   | 180d  | 7yr compliance
Intelligent-Tier    | $$+fee  | auto-tier | none  | Unknown pattern

Per-object fee for Intelligent-Tiering:
  $0.0025/1000 objects/month
  Avoid for many small files (fee exceeds savings)
```

> **Code walkthrough:** This S3 Buckets and Storage Classes example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# Upload to a specific storage class:
aws s3 cp backup.tar.gz \
  s3://my-backups/2024/backup.tar.gz \
  --storage-class STANDARD_IA

# Lifecycle policy - automated cost tiering:
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-backups \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "cost-tiering",
      "Status": "Enabled",
      "Filter": {"Prefix": ""},
      "Transitions": [
        {"Days": 30,   "StorageClass": "STANDARD_IA"},
        {"Days": 90,   "StorageClass": "GLACIER_IR"},
        {"Days": 365,  "StorageClass": "DEEP_ARCHIVE"}
      ],
      "Expiration": {"Days": 2555}
    }]
  }'
# 30d -> Standard-IA (45% storage savings)
# 90d -> Glacier IR (83% savings vs Standard)
# 365d -> Deep Archive (95% savings vs Standard)
# 2555d (7yr) -> deleted

# Pre-signed URL (time-limited download, no public access):
aws s3 presign s3://my-bucket/report.pdf \
  --expires-in 3600
# Valid 1 hour, no AWS credentials needed by recipient
# Use for: sharing private files with users/partners

# Block all public access (security baseline for all buckets):
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

> **Code walkthrough:** The lifecycle configurationice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> automates the cost optimization pattern: new data
> stays in Standard for 30 days (active access, no
> retrieval fee), then moves to Standard-IA (cheaper
> storage but retrieval fee - acceptable for backups
> accessed rarely), then Glacier IR for occasional
> access, then Deep Archive for compliance retention,
> and finally deleted at 7 years. This automated
> tiering reduces storage costs by 60-80% for backup
> workloads with no manual effort. Pre-signed URLs
> solve the "internal data for external user" pattern:
> the S3 bucket stays private, but a time-limited URL
> lets a user download a specific object for 1 hour.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "S3 stores files as objects in buckets, addressed by
> a key. Different storage classes optimize cost vs
> retrieval: Standard for frequently accessed data,
> Standard-IA for infrequent access at lower storage
> cost but with a retrieval fee, Glacier for long-term
> archival. Lifecycle policies automatically move objects
> between classes. Buckets are private by default with
> access controlled via IAM policies and bucket policies."

---

### ⚠️ Common Misconceptions

**Misconception: "S3 folders are real directories."**

S3 has no directory structure. A key is a flat string:
`images/2024/photo.jpg`. The slashes are part of the
key name, not directory separators. The console displays
slash-prefixed keys as folders for usability, but it
is a UI abstraction. This matters for: batch operations
(you iterate keys with a prefix, not directories),
access policies (prefix-based, not folder-based), and
cost (each object is independent - no folder metadata).

---

### 🚨 Failure Modes and Diagnosis

**Failure: S3 Access Denied despite correct IAM policy**

*Symptom:* `AccessDenied` on GetObject. IAM policy
appears correct. User has S3 read permissions.

*Root cause:* Block Public Access setting or an explicit
Deny in the bucket policy overrides the IAM Allow.
S3 uses deny-override: any explicit Deny wins over
any Allow, regardless of which policy it is in.

*Diagnosis:*
```bash
# Check Block Public Access settings:
aws s3api get-public-access-block --bucket my-bucket

# Check bucket policy for explicit Deny statements:
aws s3api get-bucket-policy --bucket my-bucket \
  | python3 -m json.tool
# Look for: "Effect": "Deny"

# IAM policy simulator:
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/AppRole \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::my-bucket/file.txt
# Returns: allowed/denied + which policy caused it
```

> **Code walkthrough:** This Returns: allowed/denied + which policy caused it example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* Audit bucket policy for unintended Deny statements.
Check Block Public Access settings. Use IAM simulator
to trace the exact deny source.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: storage class ladder conveyed in table.)*

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

**[MID] Q1 - [DEBUGGING] A service using S3 Buckets and Storage Classes is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for S3 Buckets and Storage Classes beyond 'check CloudWatch logs'.

Diagnostic sequence for S3 Buckets and Storage Classes issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For S3 Buckets and Storage Classes specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare S3 Buckets and Storage Classes to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS S3 Buckets and Storage Classes service landscape and can make informed architectural decisions.

S3 Buckets and Storage Classes has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives.

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have).

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using S3 Buckets and Storage Classes for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to S3 Buckets and Storage Classes.

Multi-region architecture for S3 Buckets and Storage Classes: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems.

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance).

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What S3 Buckets and Storage Classes cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* S3 Buckets and Storage Classes cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in S3 Buckets and Storage Classes: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs.

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using S3 Buckets and Storage Classes in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach S3 Buckets and Storage Classes with security as a first-class concern, not an afterthought.

Top security risks for S3 Buckets and Storage Classes: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for S3 Buckets and Storage Classes resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with S3 Buckets and Storage Classes: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for S3 Buckets and Storage Classes configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads.

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving S3 Buckets and Storage Classes that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world S3 Buckets and Storage Classes experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes).

Strong answers include: specific S3 Buckets and Storage Classes service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient S3 Buckets and Storage Classes architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for S3 Buckets and Storage Classes peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency).

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled.

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# VPC Networking in AWS

**Interview Weight:** ★☆☆ - Core networking knowledge.
A VPC (Virtual Private Cloud) is your isolated network
in AWS. Understanding VPC structure (subnets, route tables,
internet gateway, NAT gateway), security controls
(security groups vs NACLs), and the public/private
subnet pattern is expected for any AWS engineer.

---

### 🎯 Model Answer

**30 seconds:**

> A VPC is a virtual network in AWS. You define a CIDR
> block (e.g., 10.0.0.0/16) and subdivide into subnets
> across Availability Zones. Public subnets have a route
> to an Internet Gateway (reachable from internet).
> Private subnets route outbound traffic through a NAT
> Gateway (can call internet, cannot be reached from
> internet). Security groups (stateful firewall at
> instance level) and NACLs (stateless, subnet level)
> control traffic.

**3 minutes:**

> VPC structure:
>
> CIDR: 10.0.0.0/16 = 65,536 IP addresses. AWS reserves
> 5 per subnet. Plan for growth: /16 for VPC, /24 for
> subnets.
>
> Subnets: each in one AZ. Public = has route to IGW.
> Private = has route to NAT Gateway. Best practice:
> 1 public + 1 private per AZ (3 AZs = 6 subnets min).
>
> Internet Gateway (IGW): attached to VPC. Allows
> bi-directional internet traffic for resources with
> public IPs.
>
> NAT Gateway: deployed in public subnet. Private
> resources route outbound traffic through NAT. External
> traffic CANNOT initiate connections through NAT.
> Cost: ~$0.045/hour per AZ + $0.045/GB.
>
> Route tables: public subnet has 0.0.0.0/0 -> IGW.
> Private subnet has 0.0.0.0/0 -> NAT Gateway.
>
> Security Groups: stateful. Allow inbound port 443 =
> response traffic is automatically allowed. Default:
> all inbound denied, all outbound allowed.
>
> NACLs: stateless. Must explicitly allow both inbound
> AND outbound for each connection. First matching rule
> wins. Default: allow all.

**Blank Mind Recovery:**

**(1) Structure:** "VPC -> Subnets (per AZ) -> Route table
-> IGW (public) or NAT (private, outbound only)."

**(2) SG:** "Stateful, instance level. Response auto-allowed."

**(3) NACL:** "Stateless, subnet level. Must allow both
directions explicitly."

---

### 📘 Concept Explanation

**Standard 3-AZ VPC Layout:**

```
VPC: 10.0.0.0/16
              IGW
               |
    +----------+-----------+
    |                      |
AZ-1a (Public 10.0.1.0/24) AZ-1b (Public 10.0.2.0/24)
  NAT GW  ALB               NAT GW  ALB

AZ-1a (Private 10.0.11.0/24) AZ-1b (Private 10.0.12.0/24)
  EC2/ECS/RDS                  EC2/ECS/RDS
  Route: -> NAT GW(1a)         Route: -> NAT GW(1b)

Traffic flow (outbound from private):
  EC2 -> NAT GW -> IGW -> Internet
  Internet CANNOT initiate inbound through NAT
```

> **Code walkthrough:** This VPC Networking in AWS example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# Create VPC:
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[
    {Key=Name,Value=prod-vpc}]'

# Create public and private subnets:
aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[
    {Key=Name,Value=public-1a}]'

aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[
    {Key=Name,Value=private-1a}]'

# Create and attach Internet Gateway:
IGW=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW --vpc-id vpc-12345678

# Public route table (add 0.0.0.0/0 -> IGW):
RT_PUB=$(aws ec2 create-route-table \
  --vpc-id vpc-12345678 \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route \
  --route-table-id $RT_PUB \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW
aws ec2 associate-route-table \
  --route-table-id $RT_PUB --subnet-id subnet-pub-1a

# Security group referencing another SG (best practice):
# Allow app to receive traffic only from ALB SG:
aws ec2 authorize-security-group-ingress \
  --group-id sg-app \
  --protocol tcp --port 8080 \
  --source-group sg-alb
# sg-alb = only the ALB can reach the app on 8080
# NOT a CIDR range - tighter and environment-agnostic
```

> **Code walkthrough:** The sequence for a public subnet:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> create the subnet, create an internet gateway, attach
> it to the VPC, create a route table with a default route
> to the IGW, then associate the route table with the subnet.
> Without the route table step, the subnet has no internet
> connectivity even with an IGW attached. The security group
> rule using `--source-group sg-alb` is the zero-trust
> internal pattern: instead of allowing any IP in the VPC
> CIDR (10.0.0.0/16) to reach the app tier, only instances
> in the ALB security group can. This prevents lateral
> movement if any other instance in the VPC is compromised.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "A VPC is a virtual network I control in AWS. I define
> the IP range, create subnets in different Availability
> Zones, and configure routing. Public subnets have a
> route to an Internet Gateway for internet access.
> Private subnets use a NAT Gateway for outbound internet
> access but are not reachable from the internet.
> Security groups are stateful firewalls on each instance;
> NACLs are stateless firewalls at the subnet level."

---

### ⚠️ Common Misconceptions

**Misconception: "Security groups and NACLs do the same thing."**

Security groups are stateful: if you allow inbound
port 443, the response packets are automatically allowed
outbound without a separate rule. NACLs are stateless:
you must add explicit rules for BOTH the inbound port
AND the outbound ephemeral ports (1024-65535 for the
response). Forgetting the outbound NACL rule is the
most common VPC connectivity bug. In practice: use
security groups as the primary security control (simpler,
stateful). Use NACLs only for subnet-wide deny rules
(blocking malicious IP ranges, compliance requirements).

---

### 🚨 Failure Modes and Diagnosis

**Failure: EC2 in private subnet cannot reach internet**

*Symptom:* Application cannot download packages, call
external APIs. Connection timeouts. Inbound traffic
from users works fine.

*Root cause candidates:*
1. No NAT Gateway in the VPC
2. Private subnet route table missing 0.0.0.0/0 -> NAT
3. NAT Gateway in wrong subnet (private instead of public)
4. Security group blocking outbound traffic (uncommon
   since default allows all outbound)

*Diagnosis:*
```bash
# Check private subnet route table:
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,
             Values=subnet-private-1a" \
  --query 'RouteTables[0].Routes'
# Look for: DestinationCidrBlock=0.0.0.0/0,
#           NatGatewayId=nat-xxx
# If missing: add it

# Check NAT Gateway state and subnet:
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=vpc-12345678" \
  --query 'NatGateways[].{
    Id:NatGatewayId, State:State, Subnet:SubnetId
  }'
# State must be "available"
# Subnet must be a PUBLIC subnet (has IGW route)

# Test connectivity from instance (via SSM):
aws ssm start-session --target i-1234567890abcdef0
# curl -v https://api.example.com
```

> **Code walkthrough:** This curl -v https://api.example.com example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* NAT Gateway must be in PUBLIC subnet (has route
to IGW). Private subnet route table must have
0.0.0.0/0 -> NAT Gateway ID.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: VPC layout in ASCII above.)*

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

**[MID] Q1 - [DEBUGGING] A service using VPC Networking in AWS is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for VPC Networking in AWS beyond 'check CloudWatch logs'.

Diagnostic sequence for VPC Networking in AWS issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For VPC Networking in AWS specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare VPC Networking in AWS to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS VPC Networking in AWS service landscape and can make informed architectural decisions.

VPC Networking in AWS has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (curl -v https://api.example.co, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (curl -v https://api.example.co, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using VPC Networking in AWS for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to VPC Networking in AWS.

Multi-region architecture for VPC Networking in AWS: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (curl -v https://api.example.co, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (curl -v https://api.example.co, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What VPC Networking in AWS cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* VPC Networking in AWS cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in VPC Networking in AWS: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (curl -v https://api.example.co, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using VPC Networking in AWS in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach VPC Networking in AWS with security as a first-class concern, not an afterthought.

Top security risks for VPC Networking in AWS: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for VPC Networking in AWS resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with VPC Networking in AWS: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for VPC Networking in AWS configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (curl -v https://api.example.co, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving VPC Networking in AWS that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world VPC Networking in AWS experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (curl -v https://api.example.co, Q6)

Strong answers include: specific VPC Networking in AWS service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient VPC Networking in AWS architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for VPC Networking in AWS peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (curl -v https://api.example.co, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (curl -v https://api.example.co, Q7)

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# Route 53 and DNS Routing

**Interview Weight:** ★☆☆ - DNS foundation.
Route 53 is AWS's DNS and traffic routing service.
Understanding record types, routing policies, health
checks, and integration with AWS services (ALB, CloudFront)
is foundational for any production AWS setup.

---

### 🎯 Model Answer

**30 seconds:**

> Route 53 is AWS's DNS service. You create hosted zones
> per domain, then add records: A (IP address), ALIAS
> (points to AWS resource, works at zone apex, free queries),
> CNAME (points to another hostname, not usable at zone apex).
> Routing policies: Simple (one target), Weighted (A/B
> canary), Latency (nearest region), Failover (active-passive
> DR), Geolocation (route by user country). Health checks
> monitor endpoints and remove unhealthy targets.

**3 minutes:**

> Route 53 hosted zones:
>
> Public: resolves from anywhere on the internet.
> Private: resolves only within associated VPCs.
>   Use for: internal service discovery (api.internal).
> Cost: $0.50/zone/month.
>
> Record types:
>
> A record: hostname -> IPv4. The most common type.
>
> ALIAS: hostname -> AWS resource (ALB, CloudFront,
>   API Gateway, S3 website). Works at zone apex
>   (example.com). Free: no per-query charge for
>   AWS targets. EvaluateTargetHealth: auto-remove
>   unhealthy target from DNS.
>
> CNAME: hostname -> another hostname. Cannot be
>   used at zone apex (DNS spec forbids). Per-query
>   billing.
>
> Routing policies:
>
> Simple: single target. No health check integration.
>
> Weighted: assign weights to multiple records.
>   Weight 90 + weight 10 = 90%/10% split.
>   Use for: canary deployments.
>
> Latency: routes to region with lowest latency.
>   Use for: multi-region active-active.
>
> Failover: primary/secondary. Primary gets traffic.
>   If health check fails: secondary receives traffic.
>   Use for: active-passive DR.
>
> Geolocation: route by user country/continent.
>   Use for: data residency compliance.

**Blank Mind Recovery:**

**(1) Records:** "A (IP), ALIAS (AWS resource, free, zone apex),
CNAME (hostname, not zone apex)."

**(2) Policies:** "Simple, Weighted (A/B), Latency
(nearest), Failover (DR), Geolocation."

**(3) Rule:** "ALIAS over CNAME for AWS resources.
Works at apex. Free queries."

---

### 📘 Concept Explanation

**ALIAS vs CNAME:**

```
Zone apex (example.com):
  CNAME: NOT ALLOWED (DNS RFC forbids)
  ALIAS: ALLOWED (AWS extension, resolves like A record)

Subdomain (api.example.com):
  CNAME to any hostname: allowed
  ALIAS to AWS resource: allowed (preferred - free)

Query cost:
  ALIAS to AWS resource: FREE (no per-query charge)
  CNAME: $0.40/million queries

EvaluateTargetHealth (ALIAS only):
  If the ALB has no healthy targets:
  Route 53 removes it from DNS responses
  Combine with Failover policy for auto-DR
```

> **Code walkthrough:** This Route 53 and DNS Routing example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# Create hosted zone:
aws route53 create-hosted-zone \
  --name example.com \
  --caller-reference $(date +%s)

# ALIAS record at zone apex (CNAME not allowed here):
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "my-alb.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
# HostedZoneId Z35SXDOTRQ7X7K = fixed zone ID for
# ALBs in us-east-1 (different per service/region)
# EvaluateTargetHealth=true: auto-removes unhealthy ALB

# Weighted routing for canary deploy (90/10 split):
# Add PRIMARY with Weight=90 and CANARY with Weight=10
# Total weight: any positive integers, ratio matters
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.example.com",
        "Type": "A",
        "SetIdentifier": "primary-v1",
        "Weight": 90,
        "AliasTarget": {
          "HostedZoneId": "...",
          "DNSName": "prod-alb.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
# Add a second record with SetIdentifier=canary-v2,
# Weight=10, pointing to the new ALB for canary traffic
```

> **Code walkthrough:** The ALIAS record uses the ALB'sice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> own hosted zone ID (not your Route 53 zone ID). Each
> AWS service type has a fixed hosted zone ID per region.
> For ALBs in us-east-1 it is always Z35SXDOTRQ7X7K.
> This is a hard-coded constant, not dynamically resolved.
> `EvaluateTargetHealth: true` links Route 53 to the
> ALB's own health check: if the ALB has no healthy
> backend targets, Route 53 treats the ALB itself as
> unhealthy and stops returning it in DNS responses.
> The weighted routing example shows DNS-level canary:
> 10% of DNS resolvers get the canary ALB. Because DNS
> TTL causes client caching, the split is approximate.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Route 53 is AWS's DNS service. I create a hosted zone
> for my domain and add DNS records. ALIAS records point
> to AWS resources like ALBs and work at the domain apex
> (unlike CNAME which cannot). Routing policies let me
> do weighted routing for canary releases (90/10 split),
> latency routing to serve from the nearest region, and
> failover routing for disaster recovery with health checks
> monitoring the primary endpoint."

---

### ⚠️ Common Misconceptions

**Misconception: "CNAME and ALIAS are interchangeable;
use whichever you prefer."**

CNAME cannot be used at the zone apex (the root domain
like example.com). The DNS specification forbids it
because it would conflict with SOA and NS records.
ALIAS is an AWS-proprietary extension that resolves
to an IP like an A record but with a hostname target.
Beyond the zone apex restriction: ALIAS queries to
AWS services are free; CNAME queries are billed. Always
prefer ALIAS when the target is an AWS resource.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Route 53 failover not triggering after
primary goes down**

*Symptom:* Primary ALB unhealthy. Failover record exists.
Users still hitting primary and getting errors.

*Root cause candidates:*
1. Health check not attached to PRIMARY record
2. DNS TTL too long (clients cached old record)
3. Health check pointing to wrong endpoint
4. 90-second delay before health check fires 3 times

*Diagnosis:*
```bash
# Check health check status (must show unhealthy):
aws route53 get-health-check-status \
  --health-check-id <id> \
  --query 'HealthCheckObservations[].StatusReport.Status'

# Check PRIMARY record has health check attached:
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --query 'ResourceRecordSets[?Failover==`PRIMARY`].{
    Name:Name, HCId:HealthCheckId
  }'
# HealthCheckId MUST be set - if null, failover never triggers

# Check TTL and current DNS resolution:
dig api.example.com
# TTL in response: if 300 seconds, clients wait 5 minutes
# For failover: TTL should be 60 seconds
```

> **Code walkthrough:** This For failover: TTL should be 60 seconds example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* Set TTL=60 on failover records. Attach health
check to PRIMARY record. Verify health check endpoint
path and port match the actual service.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: routing policies conveyed in text.)*

---

### 🎯 Interview Deep-Dive

---

**[MID] Q1 - [DEBUGGING] A service using Route 53 and DNS Routing is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for Route 53 and DNS Routing beyond 'check CloudWatch logs'.

Diagnostic sequence for Route 53 and DNS Routing issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For Route 53 and DNS Routing specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare Route 53 and DNS Routing to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS Route 53 and DNS Routing service landscape and can make informed architectural decisions.

Route 53 and DNS Routing has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (For failover: TTL should be 60, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (For failover: TTL should be 60, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using Route 53 and DNS Routing for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to Route 53 and DNS Routing.

Multi-region architecture for Route 53 and DNS Routing: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (For failover: TTL should be 60, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (For failover: TTL should be 60, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What Route 53 and DNS Routing cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* Route 53 and DNS Routing cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in Route 53 and DNS Routing: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (For failover: TTL should be 60, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using Route 53 and DNS Routing in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach Route 53 and DNS Routing with security as a first-class concern, not an afterthought.

Top security risks for Route 53 and DNS Routing: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for Route 53 and DNS Routing resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with Route 53 and DNS Routing: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for Route 53 and DNS Routing configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (For failover: TTL should be 60, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving Route 53 and DNS Routing that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world Route 53 and DNS Routing experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (For failover: TTL should be 60, Q6)

Strong answers include: specific Route 53 and DNS Routing service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient Route 53 and DNS Routing architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for Route 53 and DNS Routing peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (For failover: TTL should be 60, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (For failover: TTL should be 60, Q7)

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

#### CONCEPT 1 (S3): Explain S3 storage classes and when to use each.

**Storage classes from most to least expensive:**

Standard: ~$0.023/GB/month. No retrieval fee. Millisecond
access. Use for: active data accessed multiple times
per month (user uploads, app assets, ML training data).

Standard-IA: ~$0.0125/GB + $0.01/GB retrieval. 30-day
minimum storage. Use for: backups, logs, disaster
recovery data accessed < once per month.

Glacier Instant Retrieval: ~$0.004/GB + retrieval fee.
Millisecond access. 90-day minimum. Use for: archives
accessed occasionally (quarterly) but needing instant
retrieval when accessed.

Glacier Flexible: ~$0.0036/GB. Retrieval: 1-12 hours.
Use for: data rarely accessed (< once per year), retrieval
latency acceptable.

Glacier Deep Archive: ~$0.001/GB. Retrieval 12-48 hours.
Use for: 7-year regulatory archives.

Intelligent-Tiering: $0.0025/1000 objects/month monitoring
+ storage based on tier. Automatically moves between
Standard and IA. Use for: unknown or variable access
patterns. Avoid for: many small objects (monitoring
fee per object can exceed tier savings).

**Lifecycle pattern for backup/archive:**

```
New -> Standard (30 days, frequent access)
30d -> Standard-IA (save 45% on storage)
90d -> Glacier Instant (save 83%)
365d -> Deep Archive (save 95%)
2555d -> Delete (7-year compliance complete)
```

> **Code walkthrough:** This For failover: TTL should be 60 seconds example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

*What separates good from great:* The minimum storage
duration charges (30 days for IA, 90 days for Glacier)
prevent cost surprises: uploading a file to Glacier and
deleting it the next day still incurs 90 days of Glacier
storage charges. Also knowing Intelligent-Tiering is
counterproductive for many small objects shows nuanced
understanding.

---

#### CONCEPT 2 (VPC): Security groups vs NACLs: differences and when to use each?

**Security Groups (instance/ENI level):**

Stateful: tracks connection state. Allow inbound port 80
= return traffic is automatically allowed. No need for
an explicit outbound rule for responses.

Evaluated: all rules together (OR logic). Most permissive
matching rule wins.

Default: deny all inbound, allow all outbound.

Can reference other SGs as source: use `sg-alb` as source
to allow only ALB traffic to app tier (not any IP in VPC).

Cannot have explicit DENY rules.

**NACLs (subnet level):**

Stateless: no connection tracking. Must allow BOTH
inbound and outbound explicitly. Allow port 443 inbound
AND allow ports 1024-65535 outbound (ephemeral response
ports).

Rules evaluated in order (lowest number first). First
match wins. Explicit DENY available.

Default: allow all (rule 100: allow all traffic).

**Comparison:**

```
Feature        | Security Group   | NACL
---------------|------------------|------------------
Statefulness   | Stateful         | Stateless
Level          | Instance/ENI     | Subnet
Rule logic     | All rules (OR)   | First match
Default        | Deny all inbound | Allow all
Deny rules     | No               | Yes
SG reference   | Yes              | No (CIDR only)
```

> **Code walkthrough:** This For failover: TTL should be 60 seconds example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

**When to use NACLs:** Subnet-wide deny rules. Example:
block an entire malicious IP range immediately across
all instances in a subnet without modifying individual
security groups. Compliance requirements for explicit
subnet-level deny.

*What separates good from great:* "Security groups
cannot have explicit deny rules" is the limitation that
makes NACLs necessary for subnet-level blocking. Most
production environments never need NACLs because SGs
provide sufficient control, but knowing when NACLs are
the right tool shows architecture depth.

---

#### DEBUGGING 1 (Route 53): Route 53 failover is not triggering after primary goes down. How do you debug?

**Systematic approach:**

Step 1: Verify health check is failing:
```bash
aws route53 get-health-check-status \
  --health-check-id <health-check-id>
# Must show all 3 checkers reporting FAILURE
# Route 53 uses multiple global checkers
# All must agree: unhealthy
```

> **Code walkthrough:** This All must agree: unhealthy example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Step 2: Verify health check is attached to PRIMARY record:
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --query 'ResourceRecordSets[?Failover!=null].{
    Name:Name, Type:Type, Failover:Failover,
    HealthCheckId:HealthCheckId
  }'
# If PRIMARY record has no HealthCheckId: failover never triggers
# The health check ID MUST be on the PRIMARY record
```

> **Code walkthrough:** This The health check ID MUST be on the PRIMARY record example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Step 3: Check DNS TTL and client-side caching:
```bash
dig api.example.com
# TTL in ANSWER section: e.g., 300 = clients cache 5 min
# Failover may have triggered at DNS level
# But clients cached the old A record
# Low TTL (60s) required for failover records
```

> **Code walkthrough:** This Low TTL (60s) required for failover records example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Step 4: Test from multiple DNS resolvers:
```bash
dig api.example.com @8.8.8.8  # Google
dig api.example.com @1.1.1.1  # Cloudflare
# If both return new IP: failover worked, issue is client cache
# If returning old IP: Route 53 has not updated
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

Root cause analysis matrix:

Failover never triggered: health check not on PRIMARY record.
Failover too slow: TTL 300s, clients cached for 5 minutes.
Health check failed but no failover: SECONDARY record missing.
Intermittent: health check interval 30s, needs 3 failures =
  90-second minimum latency before failover.

*What separates good from great:* The distinction between
"Route 53 has not updated DNS" vs "Route 53 updated
but clients cached old result" is the most commonly
confused issue. Using `dig @8.8.8.8` bypasses local
DNS caching to test what Route 53 is actually serving.

---

#### TRADE-OFF 1 (VPC): NAT Gateway vs VPC Endpoints for private subnet to AWS services access.

**Scenario:** EC2 in private subnet needs to access S3
and DynamoDB, plus call external REST APIs.

**Option 1: NAT Gateway only**

Private subnet -> NAT Gateway -> IGW -> Internet.
All traffic (S3, DynamoDB, external APIs) goes through NAT.

Cost: $0.045/hour per AZ + $0.045/GB processed.
For 3 AZs: $97/month just for NAT gateways.
Plus: $0.045/GB for ALL data (including S3 writes).

Performance: NAT adds ~1-5ms latency. Traffic leaves
AWS network to internet then back to S3/DynamoDB
(unless using AWS backbone routing, which NAT does use
but with extra hop).

**Option 2: VPC Gateway Endpoints (free) + NAT for rest**

S3 and DynamoDB: VPC Gateway Endpoints (free).
- Route table entry: S3/DynamoDB prefix lists -> vpce
- Traffic stays on AWS network
- No NAT processing fee for S3/DynamoDB traffic
- Endpoint is free

External APIs: NAT Gateway.
- Only external (non-AWS) traffic uses NAT
- NAT cost reduced to only external API data transfer

Cost comparison:
- S3 writes: 100GB/month via NAT = $4.50/month
- S3 writes: 100GB/month via Gateway Endpoint = FREE
- At 1TB/month S3 traffic: NAT = $45 vs Endpoint = $0
- Gateway Endpoint cost: $0

**Decision:**

Always add S3 and DynamoDB VPC Gateway Endpoints when
private subnets need those services. Cost = zero.
Savings = all S3/DynamoDB NAT processing fees.
Use Interface Endpoints (paid, $0.01/hr per AZ) for
other AWS services (Secrets Manager, ECR, SSM) when
they are high volume enough to justify cost.

*What separates good from great:* Most engineers know
NAT Gateway. Few have calculated that for S3-heavy
workloads, the Gateway Endpoint saves tens to hundreds
of dollars per month at essentially zero effort. This
is a concrete cost optimization that belongs in the
architecture from day one.

---

#### BEHAVIORAL 1: Tell me about a time you debugged a VPC or networking issue in production.

**STAR:**

**Situation:** After migrating the application stack to
new EC2 instances in a newly created VPC, the application
worked but intermittently failed to read secrets from
AWS Secrets Manager (~10% of requests).

**Task:** Diagnose the intermittent connectivity issue.

**Analysis:**

Initial hypothesis: Secrets Manager call failing due
to rate limiting. Checked CloudWatch metrics for
Secrets Manager - no throttling errors.

Second hypothesis: network connectivity issue.
The application was in a private subnet. Secrets Manager
is an AWS service not in the VPC.

Checked route table for the private subnet:
- Had 0.0.0.0/0 -> NAT Gateway (correct)
- NAT Gateway was in the public subnet (correct)
- Route to IGW existed (correct)

The 10% failure rate suggested intermittent, not complete
failure. Checked NAT Gateway metrics: there were periodic
spikes in NAT Gateway connection tracking table usage
approaching limits.

Root cause: The application was creating a new Secrets
Manager SDK client on every request (not caching the
client). Each call created a new HTTPS connection through
NAT Gateway. At peak: hundreds of concurrent connections
through NAT Gateway, approaching connection tracking limits.

**Fix:**

1. Changed application to initialize Secrets Manager client
   as a static/singleton (one client reused across requests).
2. Added in-memory caching for secrets with 5-minute TTL
   (avoid calling Secrets Manager on every request).
3. Added Secrets Manager VPC Interface Endpoint
   (traffic no longer goes through NAT Gateway at all).

**Result:** Intermittent failures eliminated. Secrets
Manager calls reduced from hundreds per second to
1 per 5 minutes per instance.

*What separates good from great:* The diagnosis through
NAT Gateway connection tracking limits (not the first
obvious hypothesis of rate limiting) and the three-layer
fix (client singleton, caching, VPC endpoint) shows
production-level debugging and defense-in-depth thinking.

---

#### SCENARIO 1: Design S3 storage for user uploads with 7-year retention and compliance requirements.

**Requirements:**
- Users upload files directly to S3
- Frequently accessed in first 30 days
- Rarely accessed after 6 months
- 7-year retention for regulatory compliance
- Cannot be deleted (compliance - immutable)

**Design:**

```
Bucket: company-user-uploads
  Region: us-east-1 (primary)
  Block Public Access: all 4 settings enabled

Security:
  Bucket Policy: allow access from app role only
  Encryption: SSE-S3 (or SSE-KMS for audit trail)
  Object Lock: COMPLIANCE mode, 7 years
    -> Even root account cannot delete during 7 years
    -> Satisfies regulatory immutability requirement

Lifecycle Policy:
  0-30d: Standard (active access)
  30-90d: Standard-IA (access drops off)
  90-365d: Glacier Instant Retrieval (occasional)
  365-2555d: Glacier Deep Archive (compliance hold)
  Day 2556: Delete (7-year period complete)

Upload pattern:
  App generates pre-signed PUT URL
  User uploads directly to S3 (bypasses app servers)
  App never proxies the file content
  Benefit: no bandwidth cost on app servers,
           no app tier scaling bottleneck for uploads

Download pattern:
  App generates pre-signed GET URL (1-hour TTL)
  User downloads directly from S3
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

*What separates good from great:* Object Lock in
COMPLIANCE mode (not GOVERNANCE mode) is the regulatory
compliance guarantee. GOVERNANCE mode can be overridden
by an admin; COMPLIANCE mode cannot be overridden by
anyone, including root. Pre-signed URL for direct upload
(not proxied) is the production-scale pattern.

---

#### SCENARIO 2: A service in private subnet needs to call external APIs and write to S3 at high volume. Design networking.

**Given:** Lambda functions in a VPC private subnet.
High S3 write volume (100GB/day). Moderate external
API calls (10GB/day).

**Architecture:**

S3 access: VPC Gateway Endpoint (free):
```
Private subnet route table:
  10.0.0.0/16    -> local
  pl-63a5400a    -> vpce-s3-xxxxx  (S3 Gateway Endpoint)
  0.0.0.0/0      -> nat-xxxxx      (all other traffic)

S3 traffic bypasses NAT entirely.
100GB/day * $0.045/GB NAT fee saved = $4.50/day = $135/month
Gateway Endpoint cost: $0
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

External API access: NAT Gateway:
```
Only non-S3 internet traffic uses NAT.
10GB/day * $0.045 = $0.45/day = $13.50/month
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Security enhancement:
```
Bucket policy restricts to VPC Endpoint:
  aws:SourceVpce = vpce-s3-xxxxx
  Effect: Deny if not from VPC Endpoint
  Prevents any S3 access from outside the VPC
  (even with valid credentials)
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Monitoring:
```
VPC Flow Logs: capture accepted/rejected traffic
  Stored in S3 or CloudWatch Logs
  Useful for diagnosing connectivity issues
```

> **Code walkthrough:** This If returning old IP: Route 53 has not updated example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

**Cost comparison (monthly):**

NAT only for everything:
  100GB S3 + 10GB external = 110GB * $0.045 = $5/day
  + NAT Gateway 3 AZs: $97/month
  Total: ~$247/month

With S3 Gateway Endpoint:
  10GB external only through NAT = $0.45/day = $13.50/month
  + NAT Gateway 3 AZs: $97/month
  Total: ~$110/month

Savings: ~55% reduction in networking costs.

*What separates good from great:* The actual monthly
cost comparison ($247 vs $110) makes this a business
decision, not just a technical preference. Gateway
Endpoints are zero-effort, zero-cost additions that
should be in every VPC from day one for S3 and DynamoDB.

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



