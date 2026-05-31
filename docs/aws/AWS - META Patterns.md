---
layout: default
title: "AWS - META Patterns"
parent: "AWS"
nav_order: 17
permalink: /aws/meta-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 31 | [AWS Anti-Patterns and Common Mistakes](#aws-anti-patterns-and-common-mistakes) | ★☆☆ |
| 32 | [AWS Interview Preparation Strategy](#aws-interview-preparation-strategy) | ★☆☆ |
| 33 | [Reading AWS Architecture Diagrams](#reading-aws-architecture-diagrams) | ★☆☆ |

---

# AWS Anti-Patterns and Common Mistakes

**Interview Weight:** ★☆☆ - Awareness and judgment.
Knowing what NOT to do on AWS is as important as
knowing the right services. Anti-patterns represent
common mistakes that experienced engineers have made
in production. Naming and explaining anti-patterns
in an interview signals production experience and
mature judgment.

---

### 🎯 Model Answer

**30 seconds:**

> Common AWS anti-patterns fall into three categories:
> security (hardcoded credentials, over-permissive IAM,
> no encryption), cost (Dev running 24/7, over-provisioned
> instances, no Reserved Instances), and architecture
> (monolith Lambda, single-AZ, no health checks, ignoring
> quotas). The most dangerous: IAM users with access keys
> in code (credentials leaked to GitHub, attackers spin
> up cryptocurrency miners within minutes). Use IAM roles,
> not access keys, for any service running on AWS.

**3 minutes:**

> Security anti-patterns:
>
> Hardcoded credentials: never put AWS access keys in
> application code or environment variables. Use IAM roles
> (EC2 instance profile, ECS task role, Lambda execution role).
> GitHub secret scanning finds exposed keys within minutes.
>
> Overly permissive IAM: `Action: "*"`, `Resource: "*"`.
> Follows least-privilege: only actions the service needs.
> If Lambda only reads from one S3 bucket: grant S3 GetObject
> on that bucket ARN only. Not S3 full access.
>
> Cost anti-patterns:
>
> No right-sizing: default instance sizes used in production.
> Compute Optimizer analyzes usage and recommends sizes.
> Typical savings: 30-40% after right-sizing.
>
> No Reserved Instances for predictable workloads:
> On-Demand is 3-4x more expensive than Reserved (1-year).
> Dev/test running 24/7: schedule Stop/Start. Dev DB off nights.
>
> Architecture anti-patterns:
>
> Single-AZ deployment: one AZ failure takes down the service.
> Always deploy across at least 2 AZs.
>
> Missing health checks: ALB routes to unhealthy instances.
> Health check must validate app health (DB connectivity),
> not just HTTP 200 from a static page.

**Blank Mind Recovery:**

**(1) Security:** "No hardcoded keys. Use IAM roles.
Least-privilege IAM. Encrypt at rest and in transit."

**(2) Cost:** "Right-size instances. Reserved for predictable.
Turn off dev/test nights and weekends."

**(3) Architecture:** "Multi-AZ. Health checks validate app.
No single points of failure."

---

### 📘 Concept Explanation

**Anti-pattern categories:**

```
Security Anti-Patterns:
  1. Hardcoded credentials in code/config
     Risk: GitHub leak -> AWS account compromise
     Fix: IAM roles, Secrets Manager

  2. Overly permissive IAM ("* on *")
     Risk: compromised role = full account access
     Fix: least-privilege, specific resource ARNs

  3. Public S3 buckets for everything
     Risk: customer data exposed to internet
     Fix: block public access, presigned URLs

  4. HTTP instead of HTTPS
     Risk: data in transit intercepted
     Fix: ACM + ALB SSL termination, HSTS

  5. IMDSv1 on EC2 (SSRF vulnerability)
     Risk: app-level SSRF steals IAM credentials
     Fix: require IMDSv2 (HTTP token required)

Cost Anti-Patterns:
  1. Dev/test running 24/7
     Fix: Lambda to stop/start non-prod on schedule
  2. Over-provisioned instances
     Fix: Compute Optimizer + right-sizing
  3. On-Demand for predictable workloads
     Fix: Reserved Instances or Savings Plans
  4. Orphaned resources (old EBS, snapshots, EIPs)
     Fix: AWS Cost Explorer + cleanup automation

Architecture Anti-Patterns:
  1. Single-AZ deployment
     Fix: deploy across min 2 AZs, use Multi-AZ services
  2. Missing health checks on ALB
     Fix: health check validates DB, not static response
  3. Lambda for everything (monolith Lambda)
     Fix: Lambda for events; Fargate for APIs
  4. No error handling / dead letter queues
     Fix: DLQ on SQS, Lambda destinations
  5. Ignoring service quotas
     Fix: monitor usage, request increases proactively
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```python
# BAD: Hardcoded AWS credentials (most dangerous anti-pattern)
import boto3

# This will be committed to git, scanned by GitHub,
# and used by attackers within minutes:
aws_access_key = 'AKIA_YOUR_KEY_EXAMPLE'
aws_secret_key = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'

s3 = boto3.client(
    's3',
    aws_access_key_id=aws_access_key,
    aws_secret_access_key=aws_secret_key
)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```python
# GOOD: IAM role (no credentials in code)
import boto3

# When running on EC2/ECS/Lambda: SDK automatically
# reads credentials from instance metadata / task role.
# No credentials in code. No risk of key exposure.

s3 = boto3.client('s3')  # Uses IAM role automatically
response = s3.get_object(Bucket='my-bucket', Key='file.txt')
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```python
# BAD: Overly permissive IAM role (IAM policy as JSON)
# This Lambda has FULL AWS access. If compromised:
# attacker has full account access.
{
    "Statement": [{
        "Effect": "Allow",
        "Action": "*",
        "Resource": "*"
    }]
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```json
// GOOD: Least-privilege IAM (only what Lambda needs)
// Lambda that only reads from one S3 bucket and sends SQS:
{
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:GetObject"],
            "Resource": "arn:aws:s3:::my-specific-bucket/*"
        },
        {
            "Effect": "Allow",
            "Action": ["sqs:SendMessage"],
            "Resource": "arn:aws:sqs:us-east-1:123:my-queue"
        }
    ]
}
```

> **Code walkthrough:** The hardcoded credentials BAD
> pattern is the most dangerous anti-pattern in AWS.
> Git scanning bots (Trufflehog, GitLeaks, GitHub
> Secret Scanning) find exposed credentials within
> minutes of a push. Once found: attackers create IAM
> users, spin up GPU instances for crypto mining, and
> exfiltrate data. A typical Bitcoin mining bill from
> an exposed key: $10,000+ in 24 hours. The GOOD pattern
> uses IAM roles: the SDK reads credentials from the
> instance metadata service automatically. No secret
> to expose. The least-privilege IAM policy limits the
> blast radius: if the Lambda is compromised, the attacker
> can only read from one specific S3 bucket - not the
> entire account.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "The most common AWS mistake I see is hardcoded
> credentials - putting AWS access keys directly in code
> or environment variables. The fix is always IAM roles:
> EC2 instances use instance profiles, Lambda functions
> use execution roles. Another common mistake is forgetting
> health checks on the load balancer - ALB will route
> traffic to crashed instances if the health check is
> not properly configured."

**Senior / Staff:**

> "Anti-patterns cluster by organizational maturity.
>
> Early-stage mistakes: hardcoded credentials, single-AZ,
> no backups. These get fixed after the first incident.
>
> Mid-stage mistakes: Lambda for everything (monolith
> Lambda functions doing too much), ignoring quotas until
> they're hit, no right-sizing, On-Demand everywhere.
>
> Mature-stage mistakes: SCP gaps (not all accounts
> have security baselines), no cost attribution tagging,
> manual runbooks instead of automated remediation,
> security findings accumulating in Security Hub without
> a triage process.
>
> The most expensive anti-pattern at scale:
> No Savings Plans or Reserved Instances for stable workloads.
> On-Demand vs Reserved (1-year, no upfront): 40% more expensive.
> $100K/month compute bill * 40% = $40K/month wasted.
> $480K/year of pure overhead that Compute Optimizer
> would flag in the first week.
>
> The most dangerous anti-pattern: no CloudTrail.
> Without CloudTrail: impossible to audit who did what
> or investigate a security incident. CloudTrail is $2/month
> for the management events trail. It should be non-negotiable
> from day 1."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Security groups are sufficient security."**

Security groups are network-layer controls (Layer 4).
They control which IP addresses and ports can reach
a resource. They do not control: what API actions an
IAM identity can perform (IAM controls that), whether
data is encrypted (KMS controls that), or whether an
attacker with stolen IAM credentials can perform actions
from outside the VPC (IAM credentials work from anywhere,
not just inside the VPC). Defense-in-depth requires:
network controls (security groups) + identity controls
(IAM) + data controls (encryption) + detective controls
(GuardDuty, CloudTrail).

**Misconception 2: "Dev/test environments do not need
security controls."**

Dev/test environments contain:
- Real production-like data for testing (customer PII,
  order data)
- IAM credentials with similar permissions to production
- Code and infrastructure that, if compromised, can
  be used as a pivot into production

Dev/test must have: GuardDuty enabled, CloudTrail on,
no hardcoded credentials, least-privilege IAM. The
reduced requirement: less restrictive SCPs (allow
experimentation), lower redundancy (single-AZ acceptable),
and auto-shutdown schedules for cost.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Exposed AWS credentials cause account compromise**

*Symptom:* Unusual IAM activity. CloudTrail shows API
calls from unfamiliar IP addresses. New IAM users created.
EC2 instances launched in regions you do not use.
AWS billing alert fires: $5,000 in 1 hour.

*Diagnosis:*
```bash
# Immediately check for unauthorized IAM activity:
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateUser \
  --start-time $(date -d '2 hours ago' +%s)
# Any CreateUser events you did not make: compromised

# Check for running instances in all regions:
for region in $(aws ec2 describe-regions --query 'Regions[*].RegionName' -o text); do
  count=$(aws ec2 describe-instances --region $region \
    --query 'Reservations[*].Instances[*].InstanceId' -o text | wc -w)
  if [ "$count" -gt "0" ]; then
    echo "$region: $count instances"
  fi
done
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Immediate response:*
```bash
# Step 1: Deactivate the exposed access key:
aws iam update-access-key \
  --access-key-id AKIA_YOUR_KEY_EXAMPLE \
  --status Inactive

# Step 2: Delete unauthorized IAM users:
aws iam delete-user --user-name unauthorized-user-xxxxx

# Step 3: Terminate unauthorized instances:
aws ec2 terminate-instances \
  --instance-ids i-xxxxx --region us-west-2

# Step 4: Rotate all credentials
# Step 5: File AWS support case for billing adjustment
# AWS often credits billing for proven compromises
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### ⚖️ Comparison Table

*(Omit: anti-patterns are best understood as a checklist,
not a comparison of alternatives)*

---

### 📊 Diagram

*(Omit: anti-patterns are categorical, not a flow diagram)*

---

### 🎯 Interview Deep-Dive

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 2 |
| TRADE-OFF | 1 |
| BEHAVIORAL | 1 |
| SCENARIO | 1 |

---

#### CONCEPT 1: What are the top five AWS security anti-patterns?

1. **Hardcoded credentials:**
   Access keys in code, environment variables, config files.
   Fix: IAM roles everywhere. Secrets Manager for external credentials.

2. **Overly permissive IAM:**
   `Action: "*"`, `Resource: "*"`. Violates least privilege.
   Fix: specific actions on specific resources. Use IAM Access Analyzer.

3. **Public S3 buckets:**
   S3 blocks public access should be enabled on all accounts.
   Fix: Block Public Access at account level via Organizations SCP.

4. **IMDSv1 on EC2:**
   IMDSv1 allows any process on the EC2 to retrieve IAM credentials.
   SSRF vulnerability: web app can be tricked to request
   `http://169.254.169.254/latest/meta-data/iam/security-credentials/role`.
   Fix: IMDSv2 requires a session token (HTTP PUT request first).
   Prevents SSRF from stealing credentials via GET.

5. **No encryption at rest:**
   Unencrypted S3 buckets, unencrypted EBS volumes, unencrypted RDS.
   Fix: Enable default encryption on S3, encrypt EBS by default,
   Aurora/RDS encryption enabled at creation.

*What separates good from great:* IMDSv2 is the hidden
protection that most engineers do not know. A server-side
request forgery (SSRF) vulnerability in a web application
allows an attacker to make HTTP GET requests from the
server. On EC2 with IMDSv1: `curl http://169.254.169.254/...`
returns IAM credentials. With IMDSv2: the metadata
endpoint requires a token obtained via HTTP PUT (SSRF
via GET cannot get a PUT token). IMDSv2 was designed
specifically to prevent SSRF-based credential theft.

---

#### CONCEPT 2: What are the most expensive AWS cost anti-patterns?

1. **On-Demand pricing for predictable workloads:**
   Reserved Instance or Savings Plans save 40-72%.
   One year, no-upfront RI: 40% savings. Three-year, all-upfront: 72%.
   Compute Savings Plans: flexible (any EC2 family), 66% savings.

2. **Over-provisioned instances:**
   Default to r5.large, never right-size.
   Compute Optimizer recommends appropriate sizes.
   Typical: half the instances are over-provisioned by 50%+.
   Savings: 20-40% after right-sizing.

3. **Dev/test environments running 24/7:**
   Dev Aurora cluster ($0.10/hr) running nights and weekends.
   Stop/start schedule: save 60% (off 60% of the time).
   Lambda function triggered by EventBridge Scheduler.

4. **Unused resources (zombie resources):**
   Old EBS snapshots, unattached EBS volumes, unused EIPs,
   idle NAT Gateways, idle load balancers.
   CloudWatch metrics: ELB RequestCount = 0 for 30 days.
   Cleanup automation: Lambda weekly scan + report.

5. **Data transfer costs ignored:**
   Cross-AZ data transfer: $0.01/GB (bidirectional).
   Internet egress: $0.09/GB.
   At 100TB/month egress: $9,000/month in data transfer alone.
   Fix: CloudFront (reduces origin pulls), S3 Transfer Acceleration,
   VPC endpoints (reduces NAT Gateway costs for S3/DynamoDB).

*What separates good from great:* VPC endpoints for
S3 and DynamoDB are free and eliminate NAT Gateway charges
for these services. Every Lambda or EC2 instance reading
from S3 via a NAT Gateway: $0.045/GB NAT processing
cost + $0.09/GB egress. With a VPC Gateway Endpoint
for S3: $0. At 10TB/month S3 reads from Lambda: $450/month
saved with zero configuration cost (VPC endpoint is free).

---

#### DEBUGGING 1: Cost spike from unknown source. Diagnose.

```bash
# Step 1: Open Cost Explorer by service:
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups | sort_by(@, &Metrics.BlendedCost.Amount) | reverse(@) | [:5]'
# Shows top 5 cost drivers

# Step 2: If EC2 is the culprit:
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{Type:InstanceType,Launch:LaunchTime,ID:InstanceId,Tags:Tags}' \
  | python3 -m json.tool
# Look for: large instance types (p3, r5.8xl) or many instances

# Step 3: If data transfer is the culprit:
# Cost Explorer: filter by Usage Type CONTAINS DataTransfer
# Find: which service, which region, which direction

# Step 4: If mystery resource:
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=CostCenter,Values="" \
  --query 'ResourceTagMappingList[*].ResourceARN'
# Untagged resources (missing cost center tag) = orphaned
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Cost anomaly detection
is AWS's automated cost spike alerting. `aws ce
create-anomaly-monitor + create-anomaly-subscription`:
AWS ML detects unusual spending patterns and alerts.
Threshold: "alert if daily spend increases by 50% vs
same day last week." Catches unexpected costs within
24 hours instead of discovering them at the monthly
billing review.

---

#### DEBUGGING 2: Health check passing but ALB routing to unhealthy instances.

*Symptom:* Application errors. Some requests succeed,
some fail. ALB access logs show 5xx from some targets.
CloudWatch: target health checks show HEALTHY.

*Root cause:* Health check endpoint returns 200 even
when the application is in a degraded state.

Typical bad health check:
```python
@app.route('/health')
def health():
    return {'status': 'ok'}, 200
# Always returns 200, even if DB is down
# ALB: instance is HEALTHY
# Reality: all requests fail because DB is down
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```python
@app.route('/health')
def health():
    try:
        # Check database:
        db.execute('SELECT 1')
        # Check cache:
        cache.ping()
        return {'status': 'ok', 'db': 'ok', 'cache': 'ok'}, 200
    except Exception as e:
        return {'status': 'degraded', 'error': str(e)}, 503
# ALB: 503 = UNHEALTHY, removes instance from rotation
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Health check depth
is a trade-off. Deep health checks that check all
dependencies can cause cascading failures: if a shared
database is slow (not down), all instances return
503, ALB removes all instances, the database is now
unloaded, instances come healthy again, then overload
the DB again. Oscillation. Fix: health check checks
DB availability (can connect), not DB performance
(query latency). Availability check: one ping. Performance
issues: separate metrics/alarms, not health check.

---

#### TRADE-OFF 1: Reserved Instances vs Savings Plans.

**Reserved Instances (RIs):**

Commitment to specific: instance type, region, OS.
r5.large in us-east-1 Linux. 1 or 3 year.
Best price: 72% off on-demand (3-year all-upfront).
Portable: sell on RI Marketplace if you no longer need.
Cons: tied to specific instance type and region.
Instance upgrade (r5 -> r6g): old RIs apply to old type
only. Buy new RIs for new type.

**Savings Plans:**

Commitment to: dollar amount per hour of compute usage.
Compute Savings Plans: apply to any EC2 family, region,
OS, Fargate, Lambda.
EC2 Savings Plans: one family, one region (deeper discount).

Best price: Compute = 66% off. EC2 instance = 72%.
Flexibility: Compute Savings Plans auto-apply as you
change instance types (r5 to r6g: same savings apply).
Cons: no secondary market (cannot sell).

**Decision:**

Active refactoring (moving to Graviton, changing instance types):
Compute Savings Plans. Savings follow you as you change.

Stable, defined instance types (same r5.2xlarge for 3 years):
EC2 Instance Savings Plans or Reserved Instances (same discount).

Mixed (some stable, some changing): Compute Savings
Plans for the changing portion + RIs for the stable.

*What separates good from great:* Savings Plans utilization
vs coverage are two different metrics. Utilization:
are you using the savings commitment you made?
Coverage: what % of eligible compute is covered by
savings plans? Both should be > 80%. If utilization
is low: you over-committed. If coverage is low:
you under-committed and are paying On-Demand for some
compute. Review monthly and adjust annual commitments.

---

#### BEHAVIORAL 1: Describe a mistake you made on AWS and what you learned.

**Situation:**

Early in my career: deployed a new service to production.
No health checks on the ALB. Used On-Demand pricing
(no Reserved Instances). Public S3 bucket for user
uploads (thought it needed to be public for users to view files).

**Incident:**

Week 2 after launch: application crashed silently.
ALB continued routing traffic to the crashed container.
All users saw 502s. ALB showed all targets as HEALTHY
(health check was just a static HTML file returning 200).
On-call page 30 minutes after the crash (when monitoring
detected sustained 502s). Manual investigation: container
was out of memory.

**Post-mortem:**

1. Health check was not testing actual application health.
   Fix: health check that validates DB connectivity.
   ALB would have detected the OOM crash and stopped routing.

2. Container memory limit was too low (512MB for a JVM app).
   Fix: increase memory + add JVM heap metrics.

3. Public S3 bucket: discovered by a security automated scan.
   All objects in the bucket were publicly readable.
   Fix: presigned URLs for user file access.
   S3 block public access enabled. Files now private.

**What I learned:**

"Works in dev" is not "works in production."
Production readiness means: proper health checks,
monitoring before launch, security review, cost review.
Since then: I use a pre-launch checklist.

*What separates good from great:* The public S3
discovery is the most important lesson: security issues
are not always visible until audited. S3 block public
access should be enabled at the account level via
Organizations SCP so that no bucket in any account
can accidentally be made public. This converts a
configuration mistake into an impossible state.
Defense-in-depth: even if a developer tries to make
a bucket public, the SCP prevents it.

---

#### SCENARIO 1: Audit an existing AWS account for common anti-patterns.

**Audit checklist:**

```bash
# Security: Check for public S3 buckets
aws s3api list-buckets --query 'Buckets[*].Name' -o text | \
  tr '\t' '\n' | while read bucket; do
    public=$(aws s3api get-bucket-acl --bucket $bucket \
      --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]')
    if [ -n "$public" ]; then
      echo "PUBLIC BUCKET: $bucket"
    fi
  done

# Security: Check for IAM users with access keys
# (Access keys can be leaked; prefer IAM roles)
aws iam list-users --query 'Users[*].UserName' -o text | \
  tr '\t' '\n' | while read user; do
    keys=$(aws iam list-access-keys --user-name $user \
      --query 'AccessKeyMetadata[?Status==`Active`]')
    if [ -n "$keys" ]; then
      echo "ACTIVE ACCESS KEY: $user"
    fi
  done

# Cost: Check for unattached EBS volumes:
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].{ID:VolumeId,Size:Size,Type:VolumeType}' \
  --output table
# Available = not attached. These are billable waste.

# Cost: Check for old snapshots (no cleanup policy):
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<`2022-01-01`].{ID:SnapshotId,Size:VolumeSize,Date:StartTime}' \
  --output table

# Architecture: Check for single-AZ RDS instances:
aws rds describe-db-instances \
  --query 'DBInstances[?MultiAZ==`false`].{ID:DBInstanceIdentifier,AZ:AvailabilityZone,Engine:Engine}'
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* AWS Config managed
rules automate this audit continuously. Enable:
`s3-bucket-public-access-prohibited`,
`iam-no-inline-policy`, `rds-multi-az-support`,
`ec2-ebs-encryption-by-default`. These rules report
compliance status in real-time. Security Hub aggregates
them. Instead of a quarterly audit script: continuous
compliance with alarms on new violations.

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


# AWS Interview Preparation Strategy

**Interview Weight:** ★☆☆ - Meta-skill for interview readiness.
AWS certifications and hands-on projects demonstrate
cloud competency. Interview preparation requires understanding
which topics are asked at which seniority levels,
how to structure answers (STAR for behavioral, trade-off
reasoning for architecture), and the most common
interview patterns: "design a system on AWS," "debug this
production incident," "compare service A vs service B."

---

### 🎯 Model Answer

**30 seconds:**

> AWS interview preparation has three components: certifications
> (AWS SAA for architecture fundamentals, AWS SAP or DevOps
> Pro for senior/staff), hands-on experience (deploy actual
> architectures on a personal AWS account), and interview
> pattern mastery (system design, service comparison,
> and production debugging scenarios). The most commonly
> tested areas: IAM, VPC networking, Lambda vs containers,
> SQS/SNS/EventBridge, Aurora vs DynamoDB, and
> the Well-Architected Framework five pillars.

**3 minutes:**

> Certification path by seniority:
>
> Junior: AWS Cloud Practitioner (CCP) for breadth.
> Validates you know what AWS does, not how to use it.
>
> Mid-level: AWS Solutions Architect Associate (SAA).
> Core architecture: EC2, S3, RDS, VPC, IAM, ALB, ASG.
> Most important general AWS certification.
>
> Senior: AWS Solutions Architect Professional (SAP).
> Complex multi-account, hybrid, migrations, advanced networking.
> Or: AWS DevOps Engineer Professional (DOP).
>
> Staff/Principal: AWS Specialty certs (Security, Database,
> Machine Learning) demonstrate depth in a domain.
>
> Hands-on practice priorities:
>
> 1. Deploy a 3-tier web application (VPC + ALB + ECS + RDS).
>    Understand every component.
> 2. Set up multi-account structure with Control Tower.
> 3. Implement event-driven architecture (Lambda + SQS + EventBridge).
> 4. Performance test a Lambda function (cold starts, concurrency).
> 5. Debug a network connectivity issue (security groups, NACLs,
>    route tables).

**Blank Mind Recovery:**

**(1) Certifications:** "CCP for cloud basics. SAA for architecture.
SAP for senior. Specialty for domain depth."

**(2) Common interview topics:** "IAM, VPC, Lambda vs containers,
SQS/SNS/EventBridge, Aurora vs DynamoDB, Well-Architected."

**(3) Answer structure:** "STAR for behavioral. Trade-off
reasoning for architecture. Diagnostic flow for debugging."

---

### 📘 Concept Explanation

**AWS interview question types by category:**

```
Type 1: Service comparison
  "When would you use Lambda vs Fargate?"
  "DynamoDB vs Aurora?"
  "SQS vs Kinesis?"
  Answer structure:
    State the core difference (one sentence)
    Trade-offs (2-3 pairs)
    Decision criteria ("use X when...")
    Example from experience or case study

Type 2: System design
  "Design a URL shortener on AWS"
  "Design a real-time notification system"
  "How would you migrate a monolith to microservices on AWS?"
  Answer structure:
    Clarify requirements (scale, SLA, budget)
    Identify components and select services
    Discuss trade-offs (Active-Active vs Active-Passive,
      SQL vs NoSQL, Lambda vs ECS)
    Address failure modes
    Scaling strategy

Type 3: Production debugging
  "Lambda is throttling during traffic spikes. What do you do?"
  "S3 costs are unexpectedly high. Diagnose."
  Answer structure:
    Identify the metric that shows the problem
    Describe the diagnosis steps
    Root cause (specific, not vague)
    Fix (specific action)
    Prevention

Type 4: Architecture review
  "Review this architecture diagram. What would you improve?"
  Answer structure:
    Start with security (always)
    Then reliability (single points of failure)
    Then cost optimization
    Then performance
    Suggest specific improvements with trade-offs
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```python
# Pattern for answering "compare X vs Y" questions:
# Use this mental framework, not memorized feature lists

def compare_services(service_a, service_b, scenario):
    """
    Framework for service comparison answers:
    
    1. Core difference (one sentence):
       SQS: messages consumed by ONE worker.
       Kinesis: same data read by MULTIPLE consumers.
    
    2. When to use A:
       SQS: decoupled task queue (one consumer per task).
       Use case: image processing, order fulfillment.
    
    3. When to use B:
       Kinesis: event streaming, multiple consumers.
       Use case: real-time analytics + storage + alerting.
    
    4. Trade-offs:
       SQS: simpler, at-least-once, no ordering.
       Kinesis: ordered per shard, multi-consumer, costs per shard.
    
    5. Decision criteria:
       One consumer? -> SQS.
       Multiple consumers, ordering, replay? -> Kinesis.
    """
    pass
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```bash
# Study path: hands-on exercises for interview prep

# Week 1: Networking fundamentals
# Deploy: VPC with public/private subnets, NAT Gateway, ALB
# Debug: security group blocking traffic (learn systematically)
# Exercise: deploy EC2 in private subnet, access via ALB

# Week 2: Compute
# Deploy Lambda behind API Gateway
# Deploy ECS Fargate service with ALB
# Compare: cold starts, connection pooling, scaling behavior

# Week 3: Data
# Deploy Aurora Serverless v2 + RDS Proxy
# Deploy DynamoDB with Global Table
# Practice: EXPLAIN queries, Performance Insights

# Week 4: Security + Cost
# Set up AWS Organizations (personal account as root)
# Create 3 accounts, apply SCPs
# Use Cost Explorer, identify optimization opportunities

# Week 5: Mock interviews
# Practice "design a system" questions out loud (record yourself)
# Practice debugging scenarios: what is your first step?
# Practice behavioral: STAR format for past projects
```

> **Code walkthrough:** The comparison framework is
> the mental model, not memorized answers. In an interview,
> the interviewer is testing whether you understand
> the trade-offs, not whether you can recite service
> documentation. Starting with "the core difference
> is..." signals that you understand the fundamental
> distinction. Moving to "use A when... use B when..."
> demonstrates decision judgment. Ending with a specific
> use case from experience or a realistic scenario makes
> the answer concrete and memorable.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "I prepare for AWS interviews by getting certifications
> (SAA for my target level), doing hands-on projects
> (deployed a complete web application with VPC, ECS, RDS,
> and ALB), and practicing common question types. For
> service comparison questions: I describe the core
> difference, then explain the decision criteria. For
> system design: I clarify requirements first, then
> pick services, then explain trade-offs."

**Senior / Staff:**

> "AWS interview preparation at senior level focuses on:
>
> Production experience depth: can you describe debugging
> a real Aurora performance issue, not just list Performance
> Insights features? Production stories are the differentiator.
> Prepare 3-5 STAR stories for debugging, architecture
> decisions, and mistakes made and learned from.
>
> Trade-off reasoning: every architecture decision involves
> trade-offs. Practice stating: 'I chose X over Y because
> [specific reason based on the requirements]. The trade-off
> is [cost/complexity/performance]. I would revisit if
> [specific condition changed].' Vague 'it depends' answers
> fail senior interviews.
>
> Cost awareness: senior engineers are expected to
> know what things cost. Know rough pricing for EC2
> (r6g.large ~$0.28/hr), Lambda ($0.20 per million),
> data transfer ($0.09/GB). Not memorized; approximate.
> Shows production ownership.
>
> Well-Architected pillars: interviewers at top companies
> use WAF as the review structure. Know: Operational
> Excellence (runbooks, game days), Security (IAM, encryption),
> Reliability (Multi-AZ, health checks, DR), Performance
> (right-sizing, caching), Cost (Reserved, Savings Plans),
> Sustainability (Graviton, right-sizing)."

---

### ⚠️ Common Misconceptions

**Misconception 1: "AWS certifications = AWS expertise."**

Certifications validate that you can answer multiple
choice questions about AWS services and architectures.
They do not validate production experience, debugging
skills, or cost management. A senior engineer with
3 years of production AWS experience and no certifications
often demonstrates more depth than a certified engineer
who has not deployed production systems.
Certifications are a baseline signal, not a guarantee.
Complement with hands-on projects and production stories.

**Misconception 2: "You need to know all 200 AWS services."**

Interviewers focus on the 30-40 services that appear
in most production architectures: EC2, ECS/Fargate,
Lambda, S3, RDS/Aurora, DynamoDB, ElastiCache, VPC
(SG, NACL, route tables), IAM, CloudFront, ALB,
SQS, SNS, EventBridge, CloudWatch, X-Ray, CloudTrail,
GuardDuty, Secrets Manager, KMS, Route53. Deep knowledge
of these > surface knowledge of all 200.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Interview answer too vague**

*Problem:* "I'd use a managed service to avoid operational
overhead." This is too vague to demonstrate expertise.

*Fix:* Name the service. State the trade-off.
"I'd use Aurora Serverless v2 for the database because:
the workload is variable (dev/test), Serverless scales
to minimum ACUs when idle (saving 80% vs provisioned),
and failover is < 30 seconds (shared distributed storage).
The trade-off: Serverless costs more per ACU-hour
than provisioned at steady state. For production with
predictable load, I'd switch to provisioned + Reserved
Instance."

**Failure Mode: Over-engineering in system design interview**

*Problem:* Asked to design a simple URL shortener.
Response: "I'd use a microservices architecture with
Kafka for event streaming, separate read and write
services, DynamoDB Global Tables for multi-region
active-active, and a CDN with Lambda@Edge..."

*Fix:* Match architecture complexity to stated requirements.
URL shortener requirements: 1M redirects/day.
Simple correct answer: API Gateway + Lambda + DynamoDB
+ CloudFront. Start simple, then offer to add complexity
if requirements justify it. Interviewers test judgment,
not maximalism.

---

### ⚖️ Comparison Table

*(Omit: interview strategy is a process description,
not a comparison of alternatives)*

---

### 📊 Diagram

*(Omit: interview preparation is a learning path,
not a flow diagram)*

---

### 🎯 Interview Deep-Dive

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 1 |
| TRADE-OFF | 1 |
| BEHAVIORAL | 2 |
| SCENARIO | 1 |

---

#### CONCEPT 1: What are the most commonly tested AWS topics at senior level interviews?

Based on patterns across FAANG, major tech companies,
and consultancies:

**Always tested:**

IAM: roles vs users vs access keys, least privilege,
trust policies, condition keys, assume-role cross-account.

VPC networking: subnets (public/private), routing tables,
security groups vs NACLs, NAT Gateway, VPC peering vs
Transit Gateway, VPC endpoints.

Lambda vs Fargate: decision criteria, cold starts,
connection pooling, scaling, cost model.

SQS/SNS/EventBridge: when to use each, fan-out pattern,
dead letter queues, ordering guarantees.

Aurora vs DynamoDB: access pattern-based selection,
consistency trade-offs, scaling approaches.

**Frequently tested (senior level):**

Multi-region architecture: active-active vs active-passive,
Route53 failover, DynamoDB Global Tables, Aurora Global DB.

Security: GuardDuty, Security Hub, SCPs, IAM policy
evaluation (explicit deny, SCP interaction).

Cost optimization: Savings Plans vs Reserved, right-sizing,
spot instances, data transfer costs.

Well-Architected Framework: six pillars, HRI prioritization.

*What separates good from great:* The "design a system"
question is where senior interviews are won or lost.
The pattern: clarify requirements -> identify components
-> select services with trade-off reasoning -> address
failure modes -> scale considerations. Candidates who
jump to "I'd use Lambda" without clarifying requirements
fail to show engineering judgment. Clarifying questions
signal senior thinking: "What is the expected QPS?
What is the consistency requirement? What is the RTO?"

---

#### CONCEPT 2: How do you structure a "design a system on AWS" answer?

The RTSF framework: Requirements, Trade-offs, Services, Failure modes.

**Step 1: Clarify requirements (2 minutes):**

Non-functional:
- Scale: "How many requests per second at peak?"
- Latency: "What is the p99 latency SLA?"
- Availability: "What is the uptime SLA? 99.9%? 99.99%?"
- Consistency: "Is eventual consistency acceptable?"
- Budget: "Any cost constraints?"

Functional (if not stated):
- "Does this need to handle authentication?"
- "What are the read:write patterns?"

**Step 2: Identify the core architecture pattern:**

Event-driven? Lambda + SQS/EventBridge.
Request-response API? ALB + ECS Fargate.
Real-time streaming? Kinesis + Lambda.
Data processing? Step Functions + Lambda + S3.

**Step 3: Select services with trade-off reasoning:**

"For the database, I'd choose Aurora MySQL because the
access patterns involve complex joins and ad-hoc queries.
DynamoDB would scale better for pure key-value access,
but the reporting requirements justify relational."

**Step 4: Address failure modes:**

"For reliability: Multi-AZ Aurora, ALB health checks,
ECS Service with 3 minimum healthy tasks. For disaster
recovery at this SLA (99.9%): Multi-AZ within one region
is sufficient. A region failure is a < 5-minute MTTD
and < 2-hour MTTR, within the 99.9% budget."

**Step 5: Scaling:**

"At 10x scale: Aurora read replicas absorb read traffic.
Fargate auto-scaling handles compute. At 100x: shard
the database by tenant_id or migrate hot paths to DynamoDB."

*What separates good from great:* Draw the diagram
while explaining. Even in a verbal interview: "Let me
sketch this: [names components while writing]. Here
we have the ALB, behind it ECS Fargate, database is
Aurora Multi-AZ. CloudFront for static assets in front.
This is the basic flow." Visual communication during
system design is the hallmark of experienced architects
who have designed systems on whiteboards before.

---

#### DEBUGGING 1: Walked through an AWS debugging scenario in an interview. How do you structure the answer?

**Framework: MIDA (Metrics, Identify, Diagnose, Action)**

**Scenario: "Lambda functions are timing out during
traffic spikes. What would you do?"**

**Metrics (what does the data show?):**

"I'd start with CloudWatch metrics:
- Lambda Throttles: are invocations being throttled?
- Lambda Duration: are functions running close to timeout?
- Lambda ConcurrentExecutions: are we hitting the account limit?
- SQS Queue Depth: if Lambda consumes SQS, is the queue growing?"

**Identify (what is the specific failure mode?):**

"If Throttles > 0: Lambda is being throttled.
Either account concurrent limit (1,000 default) or
function reserved concurrency is too low.

If Duration near timeout (15,000ms): Lambda is timing out.
The function is running too long - downstream dependency,
database query, or external API is slow.

If ConcurrentExecutions < 1,000: throttling is not the cause.
Then it is the function itself (slow DB query, external API)."

**Diagnose (find the root cause):**

"If duration timeout: X-Ray traces show which segment
is slow. Example: DynamoDB GetItem taking 5 seconds
during spike - provisioned throughput exceeded.
Check DynamoDB ThrottledRequests."

**Action (specific fix):**

"For Lambda throttling: request concurrent execution
increase. For function timeout: fix the downstream
dependency (upgrade DynamoDB to on-demand, add retry
with exponential backoff, add timeout and circuit breaker)."

*What separates good from great:* The best debugging
answers name the exact CloudWatch metric (not just
"check CloudWatch"), state the threshold that indicates
a problem (not just "see if it's high"), and end with
a specific fix (not just "optimize the code").
Specificity = production experience.

---

#### TRADE-OFF 1: AWS SAA vs SAP vs hands-on experience for interviews.

**AWS Solutions Architect Associate (SAA):**

Covers: EC2, S3, RDS, VPC, IAM, ALB, CloudFront.
Level: mid-level architecture. Multiple-choice exam.
Study time: 20-40 hours. Pass rate: ~60%.
Value: baseline signal for architectural awareness.
Not sufficient for: senior/staff engineering roles.

**AWS Solutions Architect Professional (SAP):**

Covers: complex multi-account, hybrid, migrations,
cost optimization at enterprise scale.
Level: senior architecture. Harder exam (longer scenarios).
Study time: 60-100 hours. Pass rate: ~40%.
Value: demonstrates breadth at advanced level.
Not sufficient alone: does not replace production experience.

**Hands-on production experience:**

Deploying, operating, debugging real systems.
Cannot be substituted by any certification.
Interview signals: specific debugging stories, cost numbers,
service quotas encountered, failure modes resolved.

**Combined strategy (recommended for senior roles):**

1. Get SAA (credentialing baseline, shows commitment)
2. Build real projects on personal AWS account
3. Document experiences: debugging stories, architecture
   decisions, cost optimizations (for STAR answers)
4. SAP optional: valuable for enterprises, less important
   for startups. Do it if time allows.

*What separates good from great:* AWS Certified Security
Specialty is undervalued. Security is the most commonly
asked topic at staff+ interviews. The Security specialty
cert covers: IAM deep-dive, KMS, CloudTrail, GuardDuty,
WAF, Shield. 40 hours of study creates deep security
knowledge that manifests in every architecture discussion
as "security-first" instincts. This signals readiness
for principal/staff-level roles.

---

#### BEHAVIORAL 1: Walk through how you prepared for a cloud architecture interview.

**Situation:**

Staff engineer role at a fintech startup. Expected:
multi-account AWS expertise, security architecture,
cost optimization, microservices patterns.

**Preparation:**

Week 1-2: Knowledge gaps assessment.
Created an honest list: strong on compute/Lambda/ECS,
weak on multi-account/Organizations, moderate on networking.

Week 3-4: Fill multi-account gap.
Built a 3-account Organizations structure in personal AWS:
management + prod + dev. Deployed Control Tower.
Read all AWS Security Reference Architecture docs.
Practiced: what SCPs would I apply? Why?

Week 5: Study question patterns.
Found 20 questions from LeetCode-style AWS interview lists.
Answered each out loud (recorded myself). Critiqued answers
for specificity: "too vague - name the service."

Week 6: Cost optimization deep-dive.
Used Cost Explorer on my personal account.
Identified: 3 orphaned EBS volumes, unused Elastic IPs,
dev RDS running 24/7. Fixed all of them.
Built the narrative: "I noticed $45/month waste and eliminated
it by [specific actions]."

Week 7: Mock interviews.
3 mock interviews with peers. Feedback: architecture answers
were good, behavioral answers lacked metrics.
Added metrics to STAR stories: "reduced cost by $40K/year,
reduced latency from 4s to 200ms."

**Outcome:**

Interview: system design (multi-region SaaS), debugging
(production incident), 2 behavioral. Offer received.

*What separates good from great:* The most effective
preparation is building what you plan to talk about.
A 3-account Control Tower setup done in one weekend
creates 5 specific stories: "I learned that SCPs
apply even to the root user when I accidentally locked
myself out of the member account and had to use the
management account to detach the SCP." Real learning
from real mistakes is the answer that makes interviewers
think "this person has been in production."

---

#### BEHAVIORAL 2: How do you stay current with AWS releases and best practices?

**Content sources:**

1. AWS re:Invent recordings (YouTube): 1 hour/week.
   Filter: "re:Invent 2024 + specific service." Watch the deep-dive
   sessions (400-level), not the intro sessions (100-level).
   Deep-dives cover production patterns that blog posts miss.

2. AWS What's New (console + RSS feed): 10 minutes/week.
   Filter for services you use. Identify: what new features
   are relevant to current work? Test in dev account.

3. AWS Architecture Blog: weekly posts on production patterns.
   Case studies from real customer deployments.
   Particular value: cost and performance case studies.

4. The Burning Monk (Yan Cui): Lambda/serverless deep dives.
   Practical production patterns, common mistakes.

5. AWS Weekly Newsletter (Last Week in AWS): aggregated news.

**Active learning:**

Personal AWS account: test any new feature within 1 week
of announcement. New service: deploy a toy version.
This converts "I read about it" to "I've used it."

**Applying to work:**

Monthly team presentation: "here is one new AWS feature
we should adopt and why." Forces synthesizing what was learned
into practical recommendations.

*What separates good from great:* The most valuable
learning source is AWS support cases and documentation.
When something breaks in production: the resolution
process (raise support case, work with AWS engineers,
understand the root cause) produces insights not available
in any blog post. "We had a GuardDuty false positive
because our Lambda was scanning S3 and the data access
patterns matched crypto-mining signatures. AWS support
helped us add a suppression rule with a condition on
the Lambda ARN." That story signals expert-level AWS
experience.

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


# Reading AWS Architecture Diagrams

**Interview Weight:** ★☆☆ - Communication and analysis skill.
AWS architecture diagrams use AWS service icons, connection
arrows representing data flow or API calls, and visual
zones for VPCs, AZs, and accounts. Being able to read
a diagram quickly - identify components, trace data
flows, spot security issues, and suggest improvements
- is a practical skill tested in architecture review
interviews and system design discussions.

---

### 🎯 Model Answer

**30 seconds:**

> Reading AWS diagrams follows a 4-step approach: first,
> identify the boundaries (accounts, VPCs, AZs, regions)
> which define isolation and scope. Second, trace the
> data flows (arrows: solid=synchronous, dashed=async).
> Third, identify security boundaries (public vs private
> subnets, security groups, IAM boundaries). Fourth,
> look for reliability gaps (single points of failure,
> missing health checks, single-AZ deployments).

**3 minutes:**

> Diagram elements to recognize immediately:
>
> VPC boundaries: dashed rectangle containing subnets.
> Public subnet: connected to Internet Gateway.
> Private subnet: connected to NAT Gateway or no internet path.
>
> Load balancers (ALB/NLB): between internet/client and compute.
> Arrow from client -> ALB -> ECS/EC2 means: user request flows.
>
> Database connections: arrows from compute to RDS/DynamoDB.
> If arrow crosses subnet boundary without VPC endpoint: going
> through NAT (costly). VPC endpoint is better.
>
> Multi-AZ indicators: same service icon appearing twice (one per AZ).
> If only one icon for RDS: single-AZ = SPOF.
>
> Security indicators: lock icons, KMS arrows, IAM roles.
> If no security indicators: ask where encryption and IAM are.
>
> Review questions when analyzing a diagram:
> - Where is the single-AZ risk?
> - Where is the public internet exposure?
> - Where are credentials managed?
> - What happens if this component fails?

**Blank Mind Recovery:**

**(1) Identify boundaries:** "Account, VPC, subnet (public/private),
AZ, region. These define isolation."

**(2) Trace flows:** "Solid arrows = sync. Dashed = async.
Follow user request from outside to database."

**(3) Find gaps:** "Single AZ = SPOF. Public subnet with
DB = security issue. No encryption = risk."

---

### 📘 Concept Explanation

**AWS diagram conventions:**

```
Standard AWS Architecture Diagram elements:

Boundaries (drawn as colored rectangles):
  Blue dashed: AWS Region
  Orange solid: VPC
  Green: Public Subnet (has route to IGW)
  Blue: Private Subnet (no direct internet route)
  Purple: Account boundary

Services (AWS icons, color-coded by category):
  Orange: Compute (EC2, Lambda, ECS)
  Red: Database (RDS, Aurora, DynamoDB)
  Green: Storage (S3, EFS)
  Purple: Networking (VPC, ALB, Route53)
  Orange: Management (CloudWatch, CloudTrail)

Connection arrows:
  Solid arrow: synchronous call (request/response)
  Dashed arrow: asynchronous (queue, event, stream)
  No arrow between zones: no direct connectivity

What to look for:
  Route53 -> CloudFront -> ALB: typical CDN + LB chain
  ALB in public subnet -> ECS in private subnet: secure
  ECS -> RDS Proxy -> Aurora: connection pooling
  Lambda -> SQS -> Lambda: async decoupling
  Multi-AZ icon repetition: same service, both AZs

What to question:
  RDS icon without Multi-AZ pair: single-AZ SPOF
  Compute in public subnet: not best practice
  Direct arrow from Lambda to RDS: no connection pooling
  Missing CloudTrail: no audit logging
  No encryption icons: data at rest unencrypted?
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```
# Example: Reading a typical 3-tier diagram

What you see:
  [Internet] 
    |
  [Route53] -> [CloudFront] -> [WAF]
    |
  [ALB] (Public Subnet, us-east-1a + us-east-1b)
    |           |
  [ECS Fargate] [ECS Fargate] (Private Subnet, 2 AZs)
    |
  [RDS Proxy] (Private Subnet)
    |
  [Aurora MySQL Primary] [Aurora MySQL Replica]
  (Private Subnet, Multi-AZ)

What you identify:
  1. Internet traffic: Route53 -> CloudFront (CDN) -> WAF -> ALB
  2. ALB spans 2 AZs (Multi-AZ): high availability
  3. ECS Fargate in private subnets: not internet accessible
  4. RDS Proxy: connection pooling between ECS and Aurora
  5. Aurora Multi-AZ: primary + replica = HA for database

Questions to ask:
  - Where is NAT Gateway? (ECS needs internet for ECR pull)
  - Where is ElastiCache? (no caching layer visible)
  - Is there a VPC endpoint for S3? (cost optimization)
  - How are secrets managed? (Secrets Manager not shown)
  - What is the CloudFront cache TTL for dynamic content?
  - Where is the monitoring? (CloudWatch not shown)
```

> **Code walkthrough:** Reading the diagram top-down
> follows the user request path: DNS resolution (Route53),
> CDN caching (CloudFront), WAF for security filtering,
> load balancing (ALB), compute (ECS), database pooling
> (RDS Proxy), storage (Aurora). Each layer has a
> specific function. Identifying what is missing (NAT
> Gateway for private subnet internet access, ElastiCache
> for caching) demonstrates understanding that architecture
> diagrams are always incomplete - they show the major
> components, not every detail. Good architects ask
> questions about the gaps.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "I read AWS diagrams by first identifying the VPC
> and subnet boundaries (which components have internet
> access), then tracing the request flow from the user
> to the database. I look for multi-AZ deployments
> (same service appearing twice, once per AZ) and
> missing security components like WAF or encryption."

**Senior / Staff:**

> "Architecture diagram review is a structured analysis:
>
> First 30 seconds: understand the scope (single account?
> multi-account? multi-region?). Identify the account
> and VPC boundaries. These define the security and
> blast radius scope.
>
> Next 2 minutes: trace user traffic path. Entry points:
> Route53, CloudFront, API Gateway, Direct Connect,
> VPN. Where does traffic enter the AWS network?
> Where are the public/private subnet boundaries?
> Is the compute in private subnets (correct) or
> public subnets (security concern)?
>
> Security review: where are credentials? (Secrets Manager,
> IAM roles). Where is encryption? (KMS, TLS). Where
> is logging? (CloudTrail, VPC Flow Logs). Where is
> intrusion detection? (GuardDuty, WAF).
>
> Reliability review: every stateful component (database,
> cache): is it Multi-AZ? Every compute tier: is it
> across at least 2 AZs? Every ALB/NLB: is it regional
> (automatically multi-AZ) or behind a single NLB?
>
> Performance review: is there caching (CloudFront, ElastiCache)?
> Are database connections pooled (RDS Proxy)?
>
> Cost review: NAT Gateway vs VPC endpoints for S3/DynamoDB.
> Single vs multiple NAT Gateways per AZ. Over-provisioned
> instance types."

---

### ⚠️ Common Misconceptions

**Misconception 1: "If a diagram has an ALB, it is
automatically Multi-AZ."**

ALB is a regional service and automatically spans
all AZs in a region - so an ALB icon by itself IS
multi-AZ. But the targets behind the ALB (ECS tasks,
EC2 instances) must be deployed in multiple AZs.
An ALB icon pointing to ECS tasks in only ONE subnet
(one AZ) means: the ALB is multi-AZ but the compute
is single-AZ. ALB routes to healthy instances in
available AZs - if all instances are in one AZ:
AZ failure = all instances unavailable.

**Misconception 2: "Dashed arrows always mean optional."**

In AWS diagrams, dashed arrows typically indicate
asynchronous or event-driven connections (SQS, SNS,
EventBridge, Lambda triggers). They are not "optional" -
they are often critical paths. A Lambda triggered by
SQS is a dashed arrow, but the message delivery and
processing is required for the system to function.
Read dashed arrows as "async required" not "optional."

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Missed a critical gap in an architecture
review, which led to a production incident**

*Common gaps missed in diagram reviews:*

1. **NAT Gateway bottleneck:**
   One NAT Gateway for all private subnets.
   High egress traffic: NAT becomes a bottleneck and SPOF.
   Fix: one NAT Gateway per AZ.

2. **Missing CloudFront for API:**
   Diagram shows: users -> ALB -> ECS.
   No CloudFront between users and ALB.
   At global scale: cross-region latency.
   Fix: CloudFront + ALB as origin.

3. **Missing DLQ on Lambda:**
   Diagram: SQS -> Lambda. No Dead Letter Queue shown.
   If Lambda fails repeatedly: message disappears after
   max receive count. Silent data loss.
   Fix: SQS DLQ, Lambda on-failure destination.

4. **No read replicas shown:**
   Aurora icon: one instance. Read-heavy workload.
   No read replicas: all reads go to the writer.
   Aurora can support 15 read replicas: use them.

---

### ⚖️ Comparison Table

*(Omit: diagram reading is a skill, not a comparison)*

---

### 📊 Diagram

*(Omit: describing how to read a diagram with another
diagram is circular - the text explanation above is
more useful)*

---

### 🎯 Interview Deep-Dive

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 1 |
| TRADE-OFF | 1 |
| BEHAVIORAL | 1 |
| SCENARIO | 2 |

---

#### CONCEPT 1: What do you look for first when reviewing an AWS architecture diagram?

I review in a specific order: security, reliability,
cost, performance. Security first because security
issues are the most expensive to fix after deployment.

**Security (first 60 seconds):**

- Are databases in private subnets? (Not publicly accessible)
- Is there a WAF in front of the API? (SQL injection, DDoS)
- How are credentials managed? (Secrets Manager visible?)
- Is there encryption? (KMS icons, HTTPS on connections)
- Is there logging? (CloudTrail, VPC Flow Logs)

**Reliability (next 60 seconds):**

- Is every stateful component (RDS, ElastiCache) Multi-AZ?
- Is compute deployed in at least 2 AZs?
- Are there health checks configured? (ALB target groups)
- Is there a dead letter queue for async processing?
- What happens if this component fails? (Trace each failure)

**Cost (next 30 seconds):**

- Is there a NAT Gateway per AZ (or one shared = bottleneck)?
- Are there VPC endpoints for S3/DynamoDB? (Reduce NAT costs)
- Is there CloudFront caching? (Reduce origin load)
- Are instance types shown? (May be over-provisioned)

**Performance (last 30 seconds):**

- Is there a caching layer (ElastiCache)?
- Is there connection pooling (RDS Proxy)?
- Is the CDN configured? (CloudFront for global users)

*What separates good from great:* The first thing I
note is what is NOT on the diagram. Diagrams show
the happy path. Missing components are often more
important: no DLQ means silent data loss. No CloudTrail
means no audit trail for compliance. No Multi-AZ for
the database means one AZ failure causes full outage.
Experienced architects read the gaps, not just the boxes.

---

#### CONCEPT 2: How do you distinguish a well-designed diagram from a poorly designed one?

**Well-designed architecture diagram:**

Shows:
- Clear boundary layers: internet -> DMZ -> application -> data
- Multi-AZ for all stateful components
- Security controls at each layer (WAF, security groups, KMS)
- Monitoring and logging components (CloudWatch, CloudTrail)
- Data flows labeled with protocols/services
- Clear separation of public and private resources

Feels like: a production architecture that has been
operated at scale.

**Poorly designed diagram:**

Signs:
- Single-AZ for any stateful component
- Compute in public subnets without clear justification
- No logging components (CloudTrail, GuardDuty absent)
- "Magic arrows" between services with no indicated protocol
- No IAM or security indicated
- One region, no DR consideration
- Everything in one account (no blast radius consideration)
- Hardcoded endpoints instead of Route53/service discovery

*What separates good from great:* The hardest-to-read
diagrams are from teams that are still learning AWS.
They often show: everything in one VPC, all resources
in public subnets (because it was easier to set up),
direct RDS connections from many services (no proxy),
and one-region with no DR. The pattern is recognizable.
A kind, useful architecture review: start with the
good (what the diagram does correctly), then prioritize
the most critical improvement (if only one thing to fix:
what is it?), then suggest additional improvements.
"Tear down" reviews are counterproductive.

---

#### DEBUGGING 1: You receive an architecture diagram and are asked to identify the failure points. Walk through.

**Diagram description:**

```
[Internet] -> [ALB] (us-east-1a only) ->
  [EC2 Auto Scaling Group] (us-east-1a only) ->
  [RDS MySQL] (single AZ, us-east-1a) ->
  [S3] (us-east-1)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Analysis:**

Failure point 1: ALB in single AZ.
ALB is normally regional (multi-AZ). If this diagram
shows ALB in one AZ: this is incorrect. ALBs are
automatically multi-AZ when using the regional endpoint.
If it is a legacy setup with a Classic Load Balancer
in one AZ: it is a SPOF. Fix: migrate to ALB.

Failure point 2: EC2 ASG in single AZ.
If all EC2 instances are in us-east-1a only: AZ failure
takes down all compute. Fix: ASG across us-east-1a
and us-east-1b minimum.

Failure point 3: RDS MySQL single AZ.
RDS without Multi-AZ has no standby. AZ failure = database
unavailable until RDS restores on a new instance (hours).
Fix: enable Multi-AZ.

Failure point 4: No NAT Gateway shown.
EC2 in private subnets needs NAT for internet access
(software updates, API calls). Not shown = either
EC2 in public subnets (security risk) or no internet
access (valid if isolated).

*What separates good from great:* Prioritize failure
points by severity. AZ failure (relatively common):
single-AZ RDS is the most critical risk. Security
(RDS in public subnet or no encryption): second priority.
Performance (no ElastiCache): lower priority. Presenting
findings in order of severity shows production judgment.
"If you can only fix one thing: enable Multi-AZ on RDS."

---

#### TRADE-OFF 1: Simple single-page diagram vs detailed multi-page diagram.

**Simple single-page:**

Shows: all major components in one view.
Pros: easy to understand holistically, good for executive
presentation, quick to create.
Cons: hides implementation details, no security
boundaries shown, cannot show all connections.
Use: executive review, high-level design decisions.

**Detailed multi-page (zoomed views per layer):**

Page 1: Network topology (VPCs, subnets, gateways).
Page 2: Application tier (ECS, Lambda, queues).
Page 3: Data tier (databases, caches, S3).
Page 4: Security (IAM, GuardDuty, KMS).

Pros: each layer can be understood in detail,
security and network connections are explicitly shown.
Cons: time-consuming, easy for viewer to get lost,
relationships between pages unclear.
Use: detailed design reviews, runbooks, new engineer onboarding.

*What separates good from great:* The C4 model (Context,
Containers, Components, Code) is a principled approach
to multi-level AWS diagrams. AWS has a C4-equivalent:
Level 1 (account/region), Level 2 (VPC/service), Level 3
(internal service components), Level 4 (code).
Using consistent notation across levels: a staff engineer
can show a board-level view (Level 1) and drill into
a specific service (Level 3) using the same language.

---

#### BEHAVIORAL 1: Describe a time you identified a critical issue in an architecture review.

**STAR:**

**Situation:** New hire at a startup. Architecture review
of the production system before a major product launch.
Diagram: ALB -> ECS Fargate -> RDS Multi-AZ (Aurora).
Looked solid at first glance.

**Discovery:**

Examined more carefully: RDS Proxy not in the diagram.
ECS services: 50 tasks. Each HikariCP pool: 10 connections.
500 connections to Aurora. Aurora r5.large max_connections: 1,365.
At peak (200 tasks): 2,000 connections. Exceeds max.

Also: ECS Auto Scaling policy: CPU > 70% -> add 10 tasks.
Launch event estimated: 5x traffic spike.
From 50 -> 200+ tasks within 10 minutes.
2,000+ connections attempted -> Aurora connection exhaustion.

**Action:**

Raised in the review meeting: "I see a potential
connection exhaustion issue at peak. Can we add RDS Proxy?"

RDS Proxy deployment: 2 hours.
New architecture: ECS -> RDS Proxy -> Aurora.
Connection usage at 200 tasks: 50 (proxy-pooled).

**Outcome:**

Launch: 10x traffic spike. Aurora connections: 47
(RDS Proxy handling 250 ECS task connections -> 47 Aurora connections).
Zero connection errors. Launch successful.

*What separates good from great:* The issue was found
by calculation, not intuition. Max ECS tasks * pool
size > Aurora max_connections is the math. Architecture
review is partially a math exercise: can the numbers
work at peak load? Draw the worst-case scenario. If
the worst case is within safety margins: the design
is sound. If not: identify the specific failure mode
and the specific fix. Calculation-backed findings
are harder to dismiss than gut feelings.

---

#### SCENARIO 1: You are given a diagram of a "serverless" architecture. Walk through your review.

**Diagram:**

```
[API Gateway] -> [Lambda] -> [DynamoDB]
[SQS] -> [Lambda] -> [S3]
[EventBridge] -> [Lambda] -> [SES] (email)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Review:**

**Security:**

- Lambda execution roles: what permissions? If all three
  Lambdas share one role (`AmazonDynamoDBFullAccess`,
  `AmazonS3FullAccess`, `AmazonSESFullAccess`): overly permissive.
  Fix: one role per Lambda, minimum permissions.

- API Gateway authentication: not shown.
  Is there an authorizer? Cognito + JWT or IAM auth?
  Without auth: API is publicly callable.

- DynamoDB: is it encrypted at rest? (Default yes, but verify)
- S3: is it private? (Block public access enabled?)
- SES: is it sending from a verified domain? (DMARC/SPF/DKIM)

**Reliability:**

- Lambda DLQ: if Lambda processing SQS fails:
  messages go to DLQ? Not shown.
  Fix: configure DLQ on SQS or on-failure destination for Lambda.

- EventBridge -> Lambda: if Lambda fails, what happens?
  EventBridge retries 2 times by default.
  After 3 failures: event dropped.
  Fix: add EventBridge dead letter queue (SQS).

- DynamoDB: is point-in-time recovery (PITR) enabled?
  Not shown. For production: PITR should be on.

**Cost:**

- Lambda concurrency: how many concurrent invocations expected?
  If API is high-traffic + SQS is high-volume + EventBridge fires often:
  total concurrency may approach account limit (1,000 default).
  Check: are these in one account? Consider reserved concurrency.

- DynamoDB: on-demand vs provisioned? Not shown.
  For variable traffic: on-demand. For predictable: provisioned.

**Performance:**

- No caching layer. If DynamoDB reads are repetitive:
  DAX (DynamoDB Accelerator) in front of DynamoDB.
  API Gateway caching for repeated identical requests.

*What separates good from great:* Serverless diagrams
often look simple (few boxes, few arrows) but have
complex failure modes because error handling is implicit.
In a monolith: uncaught exception crashes the server
(visible). In serverless: a Lambda that fails silently
(no DLQ, no logging) loses data without any visible
failure. The review of a serverless diagram must
explicitly ask: "What happens when this Lambda fails?
Where does the data go? How does the system recover?"
Every async path must have a failure recovery path.

---

#### SCENARIO 2: Your team is about to present an architecture diagram to a VP. How do you prepare the diagram?

**Audience:** VP of Engineering. Non-technical to moderate
technical. 30-minute review meeting.

**Preparation:**

Step 1: Create two versions.
Executive view (1 page): major components only.
Route53 -> CloudFront -> ALB -> ECS -> Aurora.
No subnet details, no security groups, no IAM.
Shows: user enters here, data is stored here, cost is $X/month.

Technical view (3 pages):
Page 1: Network layout (VPCs, subnets, connectivity).
Page 2: Application + data tier (ECS, Aurora, ElastiCache, RDS Proxy).
Page 3: Security + monitoring (IAM, GuardDuty, CloudTrail, CloudWatch).

Step 2: Prepare the narrative.
What problem does this architecture solve? (Reliability, cost, compliance)
What trade-offs were made? (Cost vs HA: chose warm standby not active-active)
What risks remain? (Vendor lock-in on Aurora, single-region)
What are the next steps?

Step 3: Anticipate questions.
"What happens if AWS goes down?" -> Multi-AZ within region.
  Regional failure: warm standby in us-west-2 (RTO < 5 min).
"How much does this cost?" -> $X/month. Breakdown by service.
"Is customer data safe?" -> Encryption at rest (KMS), IAM controls.

*What separates good from great:* The cost slide is
the most important preparation. VPs ask about cost.
Have the number ready: "$4,800/month at current scale.
At 10x scale: $18,000/month (DB and compute scale linearly).
We have $6K/month of Reserved Instance savings already committed."
Numbers prepared = confidence and operational maturity.

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




