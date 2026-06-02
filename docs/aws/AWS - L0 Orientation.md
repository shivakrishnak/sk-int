---
layout: default
title: "AWS - L0 Orientation"
parent: "AWS"
nav_order: 1
permalink: /aws/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [AWS Ecosystem Overview](#aws-ecosystem-overview) | ★☆☆ |
| 2 | [AWS Account and Organization Structure](#aws-account-and-organization-structure) | ★☆☆ |
| 3 | [AWS Global Infrastructure](#aws-global-infrastructure) | ★☆☆ |

---

# AWS Ecosystem Overview

**Interview Weight:** ★☆☆ - Orientation level.
Every AWS interview starts from an understanding of
what AWS is, how many services it has, and how to
navigate its ecosystem. Engineers who can articulate
the ecosystem map and the major service families
signal they understand the breadth of what they are
working with.

---

### 🎯 Model Answer

**30 seconds:**

> AWS is the dominant public cloud with over 200
> services spanning compute, storage, databases,
> networking, AI/ML, security, and analytics.
> The major service families: EC2 (virtual machines),
> S3 (object storage), RDS/DynamoDB (databases),
> Lambda (serverless), VPC (networking), IAM (security),
> CloudWatch (monitoring). AWS follows the Shared
> Responsibility Model: AWS secures the infrastructure,
> you secure your workloads on it.

**3 minutes:**

> AWS ecosystem organized by service family:
>
> Compute: EC2 (VMs), Lambda (serverless, event-driven),
> ECS/Fargate (containers), EKS (Kubernetes),
> Elastic Beanstalk (PaaS).
>
> Storage: S3 (object, 11 nines durability), EBS
> (block storage for EC2), EFS (shared NFS), Glacier
> (archival).
>
> Databases: RDS (managed relational - PostgreSQL,
> MySQL, Oracle, SQL Server), Aurora (cloud-native
> relational, 5x faster than MySQL), DynamoDB (NoSQL,
> millisecond latency), ElastiCache (in-memory cache,
> Redis/Memcached), Redshift (data warehouse),
> OpenSearch (search/analytics).
>
> Networking: VPC (virtual private cloud), Route 53
> (DNS), CloudFront (CDN), ELB/ALB/NLB (load balancers),
> Direct Connect (private on-prem connection),
> API Gateway (REST/WebSocket API management).
>
> Security: IAM (identity and access management),
> GuardDuty (threat detection), Security Hub (central
> security dashboard), WAF (web application firewall),
> KMS (key management), Secrets Manager.
>
> Messaging: SQS (queues), SNS (pub/sub topics),
> EventBridge (event bus), Kinesis (streaming data),
> MSK (managed Kafka).
>
> DevOps/IaC: CloudFormation, CDK, CodePipeline,
> CodeBuild, CodeDeploy, ECR (container registry).
>
> Observability: CloudWatch (metrics, logs, alarms),
> X-Ray (distributed tracing), CloudTrail (API audit).
>
> The principle for choosing: prefer managed services
> (RDS over PostgreSQL on EC2) because they reduce
> operational overhead. AWS services integrate tightly:
> IAM roles work across all services, CloudWatch
> monitors everything, VPCs provide network isolation.

**Blank Mind Recovery:**

**(1) Families:** "Compute (EC2, Lambda, ECS), Storage
(S3, EBS), Databases (RDS, DynamoDB), Networking (VPC,
Route 53), Security (IAM, GuardDuty), Messaging (SQS, SNS)."

**(2) Selection principle:** "Highest managed abstraction
that meets requirements. RDS over self-managed PostgreSQL."

**(3) Integration:** "IAM across all services. CloudWatch
monitors everything. VPC isolates everything."

---

### 📘 Concept Explanation

**AWS Service Map:**

```
CATEGORY       | SERVICE           | PURPOSE
---------------|-------------------|---------------------------
Compute        | EC2               | Virtual machines
               | Lambda            | Serverless functions
               | ECS               | Container orchestration
               | Fargate           | Serverless containers
               | EKS               | Managed Kubernetes
---------------|-------------------|---------------------------
Storage        | S3                | Object storage
               | EBS               | Block storage (EC2)
               | EFS               | Shared file system
               | Glacier           | Archive storage
---------------|-------------------|---------------------------
Database       | RDS               | Managed relational DB
               | Aurora            | Cloud-native relational
               | DynamoDB          | NoSQL, < 10ms
               | ElastiCache       | In-memory (Redis)
               | Redshift          | Data warehouse
               | OpenSearch        | Search + analytics
---------------|-------------------|---------------------------
Networking     | VPC               | Isolated network
               | Route 53          | DNS + routing
               | ELB/ALB/NLB       | Load balancers
               | CloudFront        | CDN
               | API Gateway       | API management
               | Direct Connect    | Private on-prem link
---------------|-------------------|---------------------------
Security       | IAM               | Identity, access
               | GuardDuty         | Threat detection
               | KMS               | Encryption keys
               | Secrets Manager   | Credential storage
               | WAF               | Web app firewall
               | Security Hub      | Security dashboard
---------------|-------------------|---------------------------
Messaging      | SQS               | Queue (pull-based)
               | SNS               | Topic (push-based)
               | EventBridge       | Event bus + routing
               | Kinesis           | Real-time streaming
               | MSK               | Managed Kafka
---------------|-------------------|---------------------------
DevOps/IaC     | CloudFormation    | Infrastructure-as-Code
               | CDK               | IaC in Python/Java/TS
               | CodePipeline      | CI/CD pipeline
               | ECR               | Container registry
---------------|-------------------|---------------------------
Observability  | CloudWatch        | Metrics, logs, alarms
               | X-Ray             | Distributed tracing
               | CloudTrail        | API audit log
```

> **Code walkthrough:** This AWS Ecosystem Overview example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# AWS CLI: navigate the ecosystem
# Check what account and identity you are using:
aws sts get-caller-identity
# Output: Account, UserID, ARN - confirms credentials

# Check what region is configured:
aws configure get region

# List EC2 instances (compute):
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].{
    Id:InstanceId,Type:InstanceType,
    State:State.Name,
    Name:Tags[?Key==`Name`]|[0].Value
  }' --output table

# List S3 buckets (storage):
aws s3 ls

# List RDS databases:
aws rds describe-db-instances \
  --query 'DBInstances[].{
    ID:DBInstanceIdentifier,
    Engine:Engine,
    Size:DBInstanceClass,
    Status:DBInstanceStatus
  }' --output table

# Check current IAM identity type:
aws iam get-user 2>/dev/null || \
  echo "Using IAM role (no static user)"
```

> **Code walkthrough:** `aws sts get-caller-identity`ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> is the first command to run in any AWS environment:
> it confirms which account number and which identity
> (role or user ARN) is active. This prevents operating
> on the wrong account. The subsequent commands show how
> a single CLI tool spans every service family: EC2 for
> compute, S3 for storage, RDS for databases. The
> `--query` JMESPath expressions filter the verbose JSON
> responses to only relevant fields. The `2>/dev/null || echo`
> pattern handles the case where the current identity is
> an IAM role (not user) without throwing an error, since
> `get-user` only applies to IAM users, not roles.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "AWS is Amazon's cloud platform with over 200 services.
> The main ones I use are: EC2 for virtual machines,
> S3 for storing files and objects, RDS for managed
> databases, Lambda for serverless functions, and VPC
> for networking. IAM controls who can access what.
> CloudWatch monitors everything with metrics and logs."

---

**Senior / Staff:**

> "When navigating the AWS ecosystem, I organize services
> by problem domain. Compute: EC2 for long-running
> workloads needing OS-level control, Lambda for
> event-driven functions under 15 minutes, ECS/Fargate
> for containers without managing the cluster. Storage:
> S3 as the default for any unstructured data (11 nines
> durability exceeds any on-prem storage), EBS for
> database volumes on EC2, EFS for shared config across
> instances. Databases: RDS for relational (PostgreSQL/MySQL),
> Aurora when you need higher performance or Global
> Database, DynamoDB for high-throughput NoSQL. The
> ecosystem's power comes from integration: IAM roles
> let Lambda read from S3 and write to DynamoDB without
> any credentials in code. EventBridge lets services
> communicate without knowing about each other. Design
> for the integrations, not just the individual services."

---

### ⚠️ Common Misconceptions

**Misconception: "More AWS services = better architecture."**

Using many AWS services increases complexity, cost, and
the attack surface. A well-architected application often
uses 5-10 services well rather than 20 services shallowly.
SQS + Lambda + RDS + S3 + VPC can handle the vast majority
of web application patterns. Add services when they solve
a specific, identified problem - not for completeness or
to appear sophisticated.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service limit (quota) hit in production**

*Symptom:* Deployments fail. Lambda creates rejected.
EC2 instances cannot be launched.
Error: `LimitExceededException`.

*Root cause:* AWS accounts have default service limits.
New accounts: EC2 On-Demand limit = 32 vCPUs.
Lambda concurrent executions: 1,000 by default.

*Detection:*
```bash
# Check current EC2 vCPU limit:
aws service-quotas list-service-quotas \
  --service-code ec2 \
  --query 'Quotas[?contains(QuotaName,`On-Demand`)]
    .{Name:QuotaName,Value:Value}'

# Request increase:
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 200
```

> **Code walkthrough:** This Request increase: example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Prevention:* Request quota increases before they
are needed. Set up Service Quotas CloudWatch alarms
to alert at 80% of limit utilization.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: service table above serves as the ecosystem map.)*

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

**[MID] Q1 - [DEBUGGING] A service using AWS Ecosystem Overview is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Ecosystem Overview beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Ecosystem Overview issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Ecosystem Overview specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Ecosystem Overview to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Ecosystem Overview service landscape and can make informed architectural decisions.

AWS Ecosystem Overview has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives.

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have).

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Ecosystem Overview for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Ecosystem Overview.

Multi-region architecture for AWS Ecosystem Overview: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems.

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance).

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Ecosystem Overview cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Ecosystem Overview cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Ecosystem Overview: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs.

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Ecosystem Overview in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Ecosystem Overview with security as a first-class concern, not an afterthought.

Top security risks for AWS Ecosystem Overview: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Ecosystem Overview resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Ecosystem Overview: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Ecosystem Overview configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads.

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Ecosystem Overview that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Ecosystem Overview experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes).

Strong answers include: specific AWS Ecosystem Overview service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Ecosystem Overview architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Ecosystem Overview peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency).

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled.

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# AWS Account and Organization Structure

**Interview Weight:** ★☆☆ - Foundation knowledge.
Every AWS deployment lives inside an account, and
most production environments use multiple accounts.
Understanding how to organize accounts, why you need
multiple accounts, and what AWS Organizations provides
is expected knowledge for anyone operating AWS at
a non-trivial scale.

---

### 🎯 Model Answer

**30 seconds:**

> An AWS account is the fundamental isolation boundary:
> resources in different accounts are completely isolated
> by default (separate VPCs, separate IAM, separate
> billing). AWS Organizations lets you manage multiple
> accounts centrally: enforce policies via Service
> Control Policies (SCPs), consolidate billing, and
> share services across accounts. The standard pattern:
> separate accounts for dev, staging, production, and
> security.

**3 minutes:**

> Single account vs multi-account:
>
> Single account (bad for production): all environments
> in one account. A mistake in dev can affect prod.
> IAM policies must differentiate envs (error-prone).
> All costs in one bill (no allocation by team/project).
> Security: a compromised credential has access
> to everything.
>
> Multi-account (AWS recommended pattern):
>
> Production account: production only. Strict IAM.
> Minimal number of people with access.
>
> Dev/test accounts: developers have broad access.
> Experimentation is safe - no prod blast radius.
>
> Security account: GuardDuty delegated admin,
> Security Hub aggregation, CloudTrail log archive.
> Write-only from workload accounts (logs go in,
> cannot be deleted by a compromised workload account).
>
> Management/Root account: billing, Organizations root.
> No workloads. Minimal access. MFA required always.
>
> AWS Organizations:
> - Hierarchy: Root -> Organizational Units (OUs) -> Accounts
> - Service Control Policies (SCPs): guardrails on entire OUs.
>   Example: deny all non-approved regions.
> - Consolidated billing: all accounts in one bill.
>   Volume discounts apply across the organization.
> - Control Tower: AWS managed service to set up
>   Organizations with pre-configured best practices
>   (Log Archive account, Audit account, baseline SCPs).

**Blank Mind Recovery:**

**(1) Isolation:** "Each account is completely isolated.
Separate VPC, IAM, billing."

**(2) Multi-account:** "Management (billing only), security
(logs), production, dev/test."

**(3) Organizations:** "SCP = guardrails on what is
allowed. Consolidated billing. Control Tower = automated
setup."

---

### 📘 Concept Explanation

**Account Hierarchy Pattern:**

```
Root (Management Account):
  - AWS Organizations root
  - Billing and cost management
  - Control Tower setup
  - No workloads, no data
  - Access: break-glass only (MFA required)

  Security OU:
    Security Account:
      - GuardDuty master account
      - Security Hub aggregation
      - Access Analyzer
    Log Archive Account:
      - S3 buckets for CloudTrail, Config, VPC flow logs
      - Write-only access from all other accounts
      - Immutable (S3 Object Lock)

  Infrastructure OU:
    Networking Account:
      - Transit Gateway
      - Direct Connect
      - Shared VPCs (Resource Access Manager)

  Workloads OU:
    Dev OU:
      - dev-account (broad developer access)
      - sandbox-account (experimentation)
    Staging OU:
      - staging-account (production-like constraints)
    Prod OU:
      - prod-account-app1 (one account per domain)
      - prod-account-app2
```

> **Code walkthrough:** This AWS Account and Organization Structure example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

**SCP Example (restrict regions):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "route53:*",
        "sts:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "eu-west-1"
          ]
        }
      }
    }
  ]
}
```

> **Code walkthrough:** This AWS Account and Organization Structure example demonstrates JSON serialization structure. **KEY MECHANISM:** the JSON parser builds an object tree requiring strict syntax with no trailing commas. **WHY IT MATTERS:** a single syntax error in a JSON config file causes the entire application to fail to start. **TAKEAWAY: always validate JSON config with a linter before deploying.**

This SCP prevents workloads in the OU from creating
resources outside the approved regions. IAM, Route 53,
and STS are excluded because they are global services.

---

### 💻 Code Example

```bash
# List all accounts in the Organization:
aws organizations list-accounts \
  --query 'Accounts[].{Name:Name,Id:Id,Status:Status}' \
  --output table

# List SCPs on an OU:
aws organizations list-policies-for-target \
  --target-id ou-xxxx-yyyyyyy \
  --filter SERVICE_CONTROL_POLICY \
  --query 'Policies[].{Name:Name,Description:Description}'

# Cross-account role assumption (CI/CD deploy pattern):
# CI/CD runs in account 111111111111
# Deploy target is account 222222222222
aws sts assume-role \
  --role-arn "arn:aws:iam::222222222222:role/DeployRole" \
  --role-session-name "deploy-$(date +%s)" \
  --query 'Credentials.{
    AccessKeyId:AccessKeyId,
    SecretAccessKey:SecretAccessKey,
    SessionToken:SessionToken
  }' --output json
# Short-lived credentials: expire in 1 hour by default
# Trust policy on DeployRole: only allow CI account
# No static credentials needed in CI/CD
```

> **Code walkthrough:** The Organizations list-accountsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> call provides a central inventory of all accounts -
> useful for auditing and automation. The SCP list shows
> what guardrails are in force for an OU. The
> `assume-role` call shows the standard CI/CD cross-account
> pattern: the pipeline in the CI account assumes a role
> in the production account to deploy. The returned
> credentials are temporary (session tokens expire in
> 1 hour by default). The trust policy on DeployRole
> limits which principals can assume it, so even if
> the CI account is compromised, the attacker can only
> perform what DeployRole allows in production. No static
> access keys in the CI/CD environment.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "An AWS account is the basic container for all
> resources. For production environments, best practice
> is to use multiple accounts: separate accounts for dev,
> staging, and production. This prevents a dev mistake
> from affecting production. AWS Organizations lets you
> manage all accounts centrally, with Service Control
> Policies to enforce rules, like restricting which
> regions can be used."

---

### ⚠️ Common Misconceptions

**Misconception: "IAM policies are sufficient isolation
between environments."**

IAM policies can isolate access, but resources in the
same account share billing, service limits (quotas),
and can communicate if policies are misconfigured.
Account-level isolation provides blast radius containment
that IAM cannot. A developer with misconfigured
permissions in the dev environment of a single-account
setup could affect production data if the IAM policies
are wrong. Separate accounts make that impossible at
the infrastructure level.

---

### 🚨 Failure Modes and Diagnosis

**Failure: SCP blocks a needed action in production**

*Symptom:* Deployment fails with `AccessDeniedException`
despite the IAM role having the correct permissions.
Error message references SCP.

*Root cause:* SCP at OU level explicitly denies the
action. SCPs AND IAM permissions are both required:
if SCP denies, IAM allow is overridden. This is the
AND logic of AWS permission evaluation.

*Diagnosis:*
```bash
# Find which SCPs apply to the account:
ACCOUNT_ID=$(aws sts get-caller-identity --query Account
  --output text)
# Get parent OU:
aws organizations list-parents \
  --child-id $ACCOUNT_ID
# List SCPs on the parent:
aws organizations list-policies-for-target \
  --target-id <ou-id> \
  --filter SERVICE_CONTROL_POLICY
# Review each SCP for Deny statements
```

> **Code walkthrough:** This Review each SCP for Deny statements example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* Modify the SCP to allow the action for this
specific account using a `Condition` on
`aws:PrincipalAccount`. Or move the account to an OU
without the restrictive SCP.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: hierarchy is conveyed in the text tree above.)*

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

**[MID] Q1 - [DEBUGGING] A service using AWS Account and Organization Structure is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Account and Organization Structure beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Account and Organization Structure issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Account and Organization Structure specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Account and Organization Structure to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Account and Organization Structure service landscape and can make informed architectural decisions.

AWS Account and Organization Structure has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (Review each SCP for Deny state, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (Review each SCP for Deny state, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Account and Organization Structure for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Account and Organization Structure.

Multi-region architecture for AWS Account and Organization Structure: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (Review each SCP for Deny state, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (Review each SCP for Deny state, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Account and Organization Structure cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Account and Organization Structure cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Account and Organization Structure: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (Review each SCP for Deny state, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Account and Organization Structure in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Account and Organization Structure with security as a first-class concern, not an afterthought.

Top security risks for AWS Account and Organization Structure: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Account and Organization Structure resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Account and Organization Structure: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Account and Organization Structure configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (Review each SCP for Deny state, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Account and Organization Structure that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Account and Organization Structure experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (Review each SCP for Deny state, Q6)

Strong answers include: specific AWS Account and Organization Structure service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Account and Organization Structure architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Account and Organization Structure peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (Review each SCP for Deny state, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (Review each SCP for Deny state, Q7)

*What separates good from great:* Running a gameday exercise (inject synthetic traffic, fail components) 2 weeks before peak events rather than hoping the architecture holds.
# AWS Global Infrastructure

**Interview Weight:** ★☆☆ - Geography and availability.
Understanding AWS regions, Availability Zones, and
edge locations is required for any architecture discussion
about reliability, latency, and compliance. Every
architectural decision about where to run a workload
depends on this foundation.

---

### 🎯 Model Answer

**30 seconds:**

> AWS operates in 33 geographic Regions worldwide.
> Each Region contains 2-6 Availability Zones (AZs) -
> physically separate data centers with independent
> power, cooling, and networking. AZ failure is the
> primary design event: architect for multi-AZ within
> a region. Regions are separate for compliance and
> latency. Edge locations (400+) are CloudFront CDN
> points of presence for low-latency content delivery.

**3 minutes:**

> Three infrastructure levels:
>
> Region: geographic area with multiple AZs.
> Examples: us-east-1 (N. Virginia), eu-west-1 (Ireland),
> ap-southeast-1 (Singapore). Choosing a region:
>
> 1. Data residency: where must data legally live?
>    (GDPR = EU region, financial data = may require
>    specific region)
>
> 2. Latency: where are your users?
>    (Asian users: ap-southeast-1, US users: us-east-1)
>
> 3. Service availability: not all services are in all
>    regions. New services launch in us-east-1 first.
>
> 4. Cost: regions have slightly different pricing.
>    us-east-1 is typically the lowest cost.
>
> Availability Zone (AZ): one or more data centers
> in a region, physically 10-100 km apart. Independent
> power and networking. Latency between AZs: < 1ms.
>
> Multi-AZ architecture: run instances in 2+ AZs.
> If one AZ fails, traffic routes to the other.
> Most AWS managed services (RDS Multi-AZ, ELB, ECS)
> automatically span AZs.
>
> AZ names: us-east-1a, us-east-1b, us-east-1c.
> These are shuffled per account: your us-east-1a
> is not the same physical AZ as another account's
> us-east-1a. This distributes load across AZs.
>
> Edge Locations: CloudFront CDN (400+ globally).
> User request goes to nearest edge location.
> Cached content served from edge (< 20ms for most users).
> Also used for: Route 53 (DNS), Shield (DDoS), WAF.

**Blank Mind Recovery:**

**(1) Levels:** "Region (geography) -> AZ (data center
cluster, < 1ms apart) -> Edge Location (CDN)."

**(2) Choosing region:** "Data residency law, user
proximity, service availability, cost."

**(3) Multi-AZ:** "Standard resilience pattern.
AZ failure is the primary design event."

---

### 📘 Concept Explanation

**Infrastructure Hierarchy:**

```
REGION (us-east-1, eu-west-1, ap-southeast-1 ...):
  Geographic boundary for data residency.
  Completely isolated from other regions by default.
  Not all services in all regions.
  Choosing region: compliance > latency > cost.

  AZ (us-east-1a, us-east-1b, us-east-1c):
    1-3 data centers, physically separate location.
    < 1ms round-trip between AZs in same region.
    Independent power, cooling, networking.
    Design principle: run in 2+ AZs always.
    AZ names are randomized per account (load distribution).
    AZ IDs (use1-az1) are stable across accounts.

  EDGE LOCATIONS (400+ globally):
    CloudFront CDN cache (static content).
    Route 53 anycast DNS.
    Shield DDoS protection.
    < 20ms for most users globally.

GLOBAL SERVICES (no region selection):
  IAM, Route 53, CloudFront, WAF (at edge),
  Organizations, Support.

REGIONAL SERVICES (choose region):
  EC2, S3, RDS, Lambda, VPC, SQS, etc.

ZONAL SERVICES (choose AZ):
  EBS volumes, EC2 instances.
  (S3, SQS, Lambda are regional, not zonal)
```

> **Code walkthrough:** This AWS Global Infrastructure example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

---

### 💻 Code Example

```bash
# List all AWS regions:
aws ec2 describe-regions \
  --query 'Regions[].{Region:RegionName}' \
  --output table

# List AZs in current region:
aws ec2 describe-availability-zones \
  --query 'AvailabilityZones[].{
    Name:ZoneName,
    State:State,
    ZoneId:ZoneId
  }' --output table
# ZoneId is stable across accounts.
# Use ZoneId when coordinating with other accounts
# (your us-east-1a may not equal another account's).

# Check current region of a specific resource:
# EBS volumes are AZ-specific - check placement:
aws ec2 describe-volumes \
  --query 'Volumes[].{
    Id:VolumeId,
    AZ:AvailabilityZone,
    Size:Size,
    State:State
  }' --output table

# CloudFront: test edge vs origin behavior:
curl -I https://d123456789.cloudfront.net/test.jpg \
  2>/dev/null | grep -i "x-cache"
# x-cache: Hit from cloudfront = edge served
# x-cache: Miss from cloudfront = origin fetched
```

> **Code walkthrough:** `describe-availability-zones`ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> shows both zone name (us-east-1a) and zone ID (use1-az1).
> Zone names are randomized per account: two accounts'
> us-east-1a point to different physical data centers.
> Zone IDs are stable identifiers and must be used when
> coordinating with other accounts (e.g., shared VPC
> via Resource Access Manager). EBS volumes are zone-
> specific: if the EC2 instance and EBS volume are in
> different AZs, they cannot be attached. The CloudFront
> cache check shows the two response states: "Hit" means
> the edge served content (fast), "Miss" means the request
> went all the way to the origin server (adds 50-200ms
> round-trip to the region).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "AWS has 33 Regions worldwide, each with multiple
> Availability Zones - separate data centers in the same
> geographic area. For resilience, we always deploy across
> multiple AZs so that if one data center has an issue,
> the application keeps running. For low latency globally,
> CloudFront edge locations serve cached content from
> 400+ points of presence, much closer to users than
> the region itself."

---

### ⚠️ Common Misconceptions

**Misconception: "Multi-AZ and multi-region mean
the same thing."**

Multi-AZ: resources in 2+ AZs within the same region.
Protects against AZ-level failures (power, networking).
Latency between AZs: < 1ms. Synchronous replication
is practical. RDS Multi-AZ, ELB, Auto Scaling Groups
use this automatically.

Multi-region: resources in 2+ geographic regions.
Protects against region-level failures (rare) and
serves global users with lower latency. Cross-region
replication is asynchronous (latency too high for
synchronous). Significantly more complex and expensive
than multi-AZ.

For most workloads: multi-AZ is sufficient. Multi-region
adds significant complexity only justified for global
applications or extreme resilience requirements.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application down when AZ fails - all
instances in one AZ**

*Symptom:* EC2 instances in us-east-1a become unreachable.
Application unavailable.

*Root cause:* All instances in a single AZ.
No multi-AZ deployment.

*Detection:*
```bash
# Check AZ distribution of running instances:
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{
    Id:InstanceId,
    AZ:Placement.AvailabilityZone
  }' --output table
# All same AZ = single-AZ risk
```

> **Code walkthrough:** This All same AZ = single-AZ risk example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

*Fix:* Move to Auto Scaling Group spanning 2+ AZs.
ALB automatically routes to healthy instances in
available AZs. For RDS: enable Multi-AZ (automated
failover in 30-60 seconds).

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: geographic map not practical in ASCII.)*

---

### 🎯 Interview Deep-Dive

---

**[MID] Q1 - [DEBUGGING] A service using AWS Global Infrastructure is behaving unexpectedly in production with no obvious errors in application logs. What AWS-native diagnostic tools do you use and in what order?**

*Why they ask:* Tests systematic AWS debugging for AWS Global Infrastructure beyond 'check CloudWatch logs'.

Diagnostic sequence for AWS Global Infrastructure issues: (1) CloudWatch Metrics - check service-specific metrics (throttling, error counts, latency percentiles). (2) CloudWatch Logs Insights - query for error patterns across the time window of the issue. (3) X-Ray traces - identify which service component has elevated latency or error rate. (4) CloudTrail - verify no unintended API calls or permission changes.

For AWS Global Infrastructure specifically: check the service console for visible warnings (throttling indicators, capacity limits). Enable AWS Config to audit configuration drift. Use CloudWatch Contributor Insights to identify traffic patterns causing the issue.

*What separates good from great:* Setting up CloudWatch Alarms BEFORE issues occur, so you get notified rather than discovering issues from customer complaints.

---

**[MID] Q2 - [TRADE-OFF] Compare AWS Global Infrastructure to its main alternatives in AWS (or outside AWS). When is each the right choice?**

*Why they ask:* Tests whether you understand the AWS AWS Global Infrastructure service landscape and can make informed architectural decisions.

AWS Global Infrastructure has specific strengths optimized for certain use cases: managed operational burden (AWS handles patching, scaling, HA), native AWS integration (IAM, VPC, CloudWatch), and pay-per-use cost model for variable workloads.

Weaknesses vs alternatives: vendor lock-in (migrating away requires significant refactoring), pricing at scale (managed services often cost more than self-managed at high volume), and less configuration flexibility than self-managed alternatives. (All same AZ = single-AZ risk, Q2)

Decision factors: team operational capacity (high ops burden teams benefit more from managed services), workload variability (bursty workloads benefit from pay-per-use), and compliance requirements (some industries require specific certifications that only certain services have). (All same AZ = single-AZ risk, Q2)

*What separates good from great:* Doing the cost math: managed service TCO includes reduced engineering time but higher per-unit cost. Calculate the crossover point.

---

**[SENIOR] Q3 - [ARCHITECTURE] How do you architect a production system using AWS Global Infrastructure for high availability across multiple AWS regions? What are the consistency trade-offs?**

*Why they ask:* Tests multi-region architecture knowledge and understanding of CAP theorem applied to AWS Global Infrastructure.

Multi-region architecture for AWS Global Infrastructure: active-active (both regions serve traffic - requires conflict resolution for write conflicts) vs active-passive (one region serves traffic, the other is warm standby - simpler but higher RTO/RPO). Most services start with active-passive due to lower complexity.

Consistency trade-offs: cross-region replication introduces replication lag (typically 1-5 seconds for most AWS services). During that window, a read from the secondary region may return stale data. This is acceptable for read-heavy workloads but problematic for financial or inventory systems. (All same AZ = single-AZ risk, Q3)

AWS Route 53 for traffic routing: latency-based routing (sends users to closest healthy region), health-check-based failover (automatically redirects if primary region fails), and geolocation routing (data residency compliance). (All same AZ = single-AZ risk, Q3)

*What separates good from great:* Testing the failover scenario with actual traffic before it's needed in production (gameday exercises).

---

**[SENIOR] Q4 - [PRODUCTION] What AWS Global Infrastructure cost optimizations should every production deployment implement? What are the common cost waste patterns you've seen?**

*Why they ask:* AWS Global Infrastructure cost awareness is a production engineering skill, not just a finance concern.

Common cost waste patterns in AWS Global Infrastructure: over-provisioned capacity (right-size based on measured p95 utilization, not peak), unused resources (orphaned volumes, forgotten dev environments, idle NAT gateways at $0.045/hr), and suboptimal pricing model (On-Demand for steady-state workloads that qualify for Reserved Instances or Savings Plans).

Cost optimization checklist: (1) Enable AWS Cost Anomaly Detection to catch unexpected spend. (2) Tag all resources for cost attribution by team and service. (3) Use AWS Compute Optimizer or Trusted Advisor recommendations for right-sizing. (4) Evaluate data transfer costs - moving data between regions or AZs has non-trivial costs. (All same AZ = single-AZ risk, Q4)

*What separates good from great:* Reviewing AWS Cost Explorer weekly as part of the team's operational practice, not quarterly during budget reviews.

---

**[SENIOR] Q5 - [SECURITY] What are the top security risks when using AWS Global Infrastructure in production? Which AWS security services mitigate them?**

*Why they ask:* Tests whether you approach AWS Global Infrastructure with security as a first-class concern, not an afterthought.

Top security risks for AWS Global Infrastructure: overly permissive IAM roles (principle of least privilege violated - use IAM Access Analyzer to detect), unencrypted data at rest or in transit (enable KMS encryption for AWS Global Infrastructure resources), and public access misconfiguration (S3 buckets, RDS instances, Elasticsearch clusters accidentally made public).

AWS security services to use with AWS Global Infrastructure: GuardDuty (threat detection - unusual API calls, credential compromise), Security Hub (consolidated security findings), Config Rules (automated compliance checks for AWS Global Infrastructure configurations), Macie (sensitive data detection in storage).

IAM policy pattern: start with deny-all, add specific allows for what the service needs. Never use AdministratorAccess or wildcard resource ARNs in production service roles. Use IAM Roles for service accounts (IRSA) for Kubernetes workloads. (All same AZ = single-AZ risk, Q5)

*What separates good from great:* Running AWS Security Hub findings review as part of the weekly engineering ritual, not just during audits.

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production incident involving AWS Global Infrastructure that you managed or contributed to resolving. What was the root cause, how was it fixed, and what did you change afterward?**

*Why they ask:* Tests real-world AWS Global Infrastructure experience and learning mindset under production pressure.

Use the STAR format: Situation (what service, what impact, what time), Task (your role in the incident), Action (specific diagnostic steps and fixes), Result (resolution time, business impact, post-incident changes). (All same AZ = single-AZ risk, Q6)

Strong answers include: specific AWS Global Infrastructure service metrics that indicated the problem, which AWS console or CLI commands were used for diagnosis, what the root cause was (not just symptoms), and what monitoring or process change prevented recurrence. Common strong examples: throttling from hitting API limits without exponential backoff, IAM permission boundary blocking a needed action at 2am, or a network ACL change breaking cross-service communication.

*What separates good from great:* Writing a post-incident review (5-whys or fishbone) and sharing it with the team vs. just fixing the symptom and moving on.

---

**[STAFF] Q7 - [SYSTEM DESIGN] Design a resilient AWS Global Infrastructure architecture that handles 10x normal traffic during peak events (Black Friday, product launch). What preparation steps do you take in advance?**

*Why they ask:* Tests load planning and capacity management for AWS Global Infrastructure peak events.

Pre-peak preparation: (1) Load test at 2x expected peak (test 20,000 RPS if expecting 10,000 peak) to find bottlenecks before traffic arrives. (2) Pre-warm: AWS ELB, Lambda cold starts, CloudFront edge locations. Request pre-warming from AWS if using services that don't auto-scale instantly. (3) Review Service Quotas and request increases 2-4 weeks in advance (EC2 limits, API Gateway rate limits, Lambda concurrency). (All same AZ = single-AZ risk, Q7)

Architecture for 10x spikes: queuing to absorb bursts (SQS queue + workers decouples request rate from processing rate), aggressive caching at CDN layer (CloudFront with long TTL for static assets, API Gateway caching for stable responses), and autoscaling with predictive scaling enabled. (All same AZ = single-AZ risk, Q7)

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

#### CONCEPT 1 (Ecosystem): What are the primary service categories in AWS and how do you decide which service to use?

**Seven primary categories and selection logic:**

Compute: EC2 (VMs, full control), Lambda (serverless,
event-driven, < 15 min), ECS/Fargate (containers without
cluster management), EKS (Kubernetes if already native).
Decision: Lambda for event-driven under 15 minutes.
ECS/Fargate for containers without Kubernetes complexity.
EC2 when you need specific OS or hardware. EKS when
you are already Kubernetes-native.

Storage: S3 (object, any file type, 11 nines durability),
EBS (block, EC2 only, high IOPS), EFS (shared NFS
across instances). Decision: S3 for most unstructured
data. EBS for databases on EC2. EFS for shared config
or code storage across multiple instances.

Databases: RDS/Aurora (SQL), DynamoDB (NoSQL, < 10ms),
ElastiCache (cache), Redshift (analytics). Decision:
RDS for structured data with transactions. DynamoDB
for high-throughput NoSQL at millisecond latency.
ElastiCache to reduce database read load. Redshift
for analytical queries over large datasets.

Networking: VPC (always, isolate everything), ALB
(HTTP routing, path-based), NLB (TCP, lower latency),
CloudFront (CDN, static content). Decision: ALB for
web apps with routing rules. NLB for TCP/UDP workloads.

Security: IAM (always), KMS (encryption), Secrets
Manager (credentials), GuardDuty (threat monitoring),
WAF (web protection). Not optional in production.

Messaging: SQS (decoupled worker queue), SNS (fan-out
broadcast), EventBridge (event routing with rules),
Kinesis (real-time streaming). Decision: SQS for
worker queues. SNS for broadcast to multiple subscribers.
EventBridge for complex routing conditions. Kinesis
for high-throughput real-time stream processing.

Selection heuristic: use the highest managed abstraction
that meets requirements. RDS > PostgreSQL on EC2.
Lambda > ECS for simple event handlers. Fargate > EC2
when custom AMIs are not needed.

*What separates good from great:* The selection heuristic
as a principle - not a case-by-case answer for every
service - is the architectural thinking expected at
senior level. "Highest managed abstraction" prevents
both over-engineering and under-engineering.

---

#### CONCEPT 2 (Global Infrastructure): Why does AZ architecture matter and how does it affect application design?

**Why AZs matter:**

AZ-level failures are the primary cloud availability
event. Power grid issues, networking problems, hardware
failures in one data center happen multiple times per
year per region. AWS publishes AZ-level incident reports
regularly. Region-level failures are rare. Design for
AZ failure: it is the operational reality.

**AZ impact on design:**

Stateless compute: Auto Scaling Group across 2+ AZs.
ALB health checks route around the failed AZ automatically.
No application code changes needed.

Stateful compute - databases: RDS Multi-AZ uses
synchronous replication to a standby in a different AZ.
Automatic failover in 30-60 seconds. Same connection
endpoint - no code change required. ElastiCache Multi-AZ
for cache.

Session state: store in ElastiCache or DynamoDB, not
in-memory. If one EC2 instance fails, the session
is preserved in Redis. The next request from the same
user hits a different instance but reads the same session.

Persistent storage: EBS volumes are AZ-specific.
If EC2 in us-east-1a fails, the EBS volume in
us-east-1a is also unavailable. Use S3 (regional, not
AZ-specific) or EFS (multi-AZ) for data that must
survive an AZ failure.

Cost consideration: cross-AZ data transfer costs
$0.01/GB. ALB and RDS Multi-AZ automatically transfer
data cross-AZ. At 100TB/month cross-AZ: $1,000/month.
Mitigate: enable cross-zone load balancing to distribute
evenly, reducing unnecessary cross-AZ transfers.

*What separates good from great:* The cross-AZ data
transfer cost ($0.01/GB) is the production detail.
Most architecture discussions treat AZ distribution
as free. At scale, cross-AZ transfer is a visible
cost line item.

---

#### DEBUGGING 1 (Account Structure): Cross-account S3 access fails with AccessDenied. How do you diagnose?

**The two-policy requirement:**

Cross-account S3 access requires BOTH:
1. IAM role in the source account must allow S3 access
2. S3 bucket policy in the target account must allow
   the source account

Both must grant access. Either missing = AccessDenied.

**Step 1: Check the source IAM policy:**
```bash
# Check the role's attached policies:
aws iam list-attached-role-policies \
  --role-name AppRole
# Then get each policy document and check for
# s3:GetObject on the target bucket ARN
```

> **Code walkthrough:** This s3:GetObject on the target bucket ARN example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Step 2: Check the S3 bucket policy:**
```bash
# Run from the account that owns the bucket:
aws s3api get-bucket-policy \
  --bucket cross-account-bucket \
  --query 'Policy' \
  --output text | python -m json.tool
# Look for Principal: arn:aws:iam::<source-account>:*
# or specific role ARN
```

> **Code walkthrough:** This or specific role ARN example demonstrates shell execution behavior. **KEY MECHANISM:** the shell executes each command in a subprocess, passing exit codes between pipeline stages. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting, breaking argument boundaries silently. **TAKEAWAY: always quote variables and use set -euo pipefail to catch all failures.**

**Step 3: Check SCP if Organizations is in use:**

If both IAM and bucket policy are correct: check
whether an SCP on the source account's OU explicitly
denies S3 access to cross-account resources. SCPs
override IAM allows.

Check SCP hierarchy for `Deny` on `s3:GetObject`
or `s3:*` with conditions that restrict cross-account.

*What separates good from great:* The two-policy
requirement is the key diagnostic insight. Developers
who check only their own IAM policy will be stuck.
The SCP layer as a third possibility shows knowledge
of the full AWS permission evaluation chain:
SCP AND (identity policy OR resource policy).

---

#### TRADE-OFF 1 (Account Structure): When should a startup use single account vs multi-account?

**Single account:**

Simpler setup: one billing view, one IAM namespace,
no cross-account role assumptions.

Appropriate for: early-stage startup with < 5 engineers,
POC or prototype, research project.

Risks: blast radius across all environments. Dev mistake
can affect production data. Service quotas shared (dev
experiments consume production quotas). Cost allocation
by team/project is difficult.

**Multi-account:**

More complex: separate console logins, cross-account
role assumptions, separate billing.

Appropriate for: any production workload with compliance
requirements, teams with > 5 engineers, environments
needing clear cost allocation.

Benefit: complete environment isolation. Security
incident in dev = no prod impact. Separate service
quotas (dev experiments don't consume prod limits).
Per-team cost allocation automatic via account.

**The tipping point:**

Not "when you get big" but "when you have production."
The Control Tower setup cost: ~1 day of work.
The risk reduction: permanent. The cost of a production
incident caused by a dev-to-prod blast radius (via
shared account) vastly exceeds a one-day setup cost.

Even for a 3-person startup: management + dev + prod
accounts is the right starting point. The operational
overhead is near-zero once set up.

*What separates good from great:* The concrete tipping
point ("when you have production") gives a clear answer.
Not "it depends" - but a specific event that triggers
the decision.

---

#### BEHAVIORAL 1: How would you set up AWS for a new startup expected to grow to 50 engineers in a year?

**Day 1 - Account structure (before any workloads):**

Set up AWS Organizations before any workloads. Retrofitting
Organizations into an existing single account at 20
engineers is painful work (migrating resources, re-doing
IAM, explaining why billing needs to be restructured).
Do it day 1 at negligible cost.

Control Tower: 2-3 hours to configure a compliant
multi-account structure with Log Archive, Audit accounts,
and baseline SCPs. Use this rather than manual setup.

Initial accounts: Management (billing only), Security
(audit logs), Dev, Prod.

**Day 1 - Identity:**

IAM Identity Center (SSO) federated to Google Workspace
or GitHub. Developers use SSO - no individual IAM users.
Not doing this day 1 means retrofitting when there are
20 IAM users and 50 access keys to deactivate.

Permission sets: ReadOnly (all devs in prod), Developer
(full access in dev account), Admin (on-call only,
MFA required).

**First production workload (month 2-3):**

Prod account: minimal IAM access. CI/CD assumes role
in prod to deploy. No developer has direct console
access to prod (except break-glass with MFA).

**Month 12 with 50 engineers:**

No restructuring needed. Add product accounts as
teams grow. Cost Explorer shows cost per team via
account. Security is isolated. SCPs enforce guardrails.

*What separates good from great:* "Day 1, before
workloads" for both Organizations and SSO is the
operational wisdom. The cost of correct setup on
day 1 is near-zero. The cost of retrofitting at
50 engineers is weeks of work and significant
operational disruption.

---

#### SCENARIO 1: Choose an AWS region for a new application serving European customers with GDPR requirements.

**Factor 1: GDPR data residency (primary):**

GDPR requires personal data of EU citizens to be
processed and stored within the EU or countries with
adequate protection. AWS EU regions:
eu-west-1 (Ireland), eu-west-2 (London, adequate),
eu-west-3 (Paris), eu-central-1 (Frankfurt),
eu-south-1 (Milan), eu-north-1 (Stockholm).

All satisfy GDPR residency requirements.

**Factor 2: Service availability:**

Not all AWS services are available in all EU regions.
eu-west-1 (Ireland) and eu-central-1 (Frankfurt) have
the broadest service coverage. Verify the specific
services needed before committing to a less-covered
region.

**Factor 3: User latency:**

eu-central-1 (Frankfurt): < 20ms from Germany, < 30ms
from most of continental Europe.
eu-west-1 (Ireland): < 20ms from UK/Ireland, < 40ms
from Southern Europe.

If users are primarily in Germany/France/Eastern Europe:
eu-central-1. If primarily UK/Ireland: eu-west-1 or
eu-west-2.

**Factor 4: Cost:**

eu-west-1 is typically the lowest cost EU region.
eu-central-1 is 5-10% more expensive for most services.

**Recommendation:**

Primary: eu-central-1 (Frankfurt). Best service coverage,
central geography, lowest cross-continental latency.
DR region: eu-west-1 (Ireland). Separate power grid,
different geographic risk, still EU-resident.

*What separates good from great:* The DR pair recommendation
(Frankfurt primary, Ireland secondary) with the rationale
(separate power grid, different geographic risk, still
EU-compliant) is the production architecture answer.

---

#### SCENARIO 2: Your company's application in us-east-1 needs to serve customers in Asia with < 100ms latency. What do you recommend?

**The latency reality:**

us-east-1 (N. Virginia) to Singapore: ~200ms round-trip.
us-east-1 to Tokyo: ~180ms round-trip.
Both exceed the 100ms requirement. Need infrastructure
in Asia.

**Option A - CloudFront (edge caching):**

For static content and cacheable API responses:
CloudFront edge locations in Singapore, Tokyo,
Hong Kong, Mumbai, Sydney.
Latency: < 30ms for cache hits.
Content must be cacheable: static assets, images,
read-heavy API responses with `Cache-Control` headers.
Not applicable for writes or personalized data.

**Option B - API in an Asian region:**

Deploy API and database to ap-southeast-1 (Singapore)
or ap-northeast-1 (Tokyo) in addition to us-east-1.

Data strategy: if data can be replicated, use Aurora
Global Database (< 1 second replication lag).
Read from local region (< 10ms). Write to primary
region (us-east-1), replicated to Asia.

If data must be local for regulatory reasons: separate
data stores per region (no cross-region sync of user
data, which may trigger data export compliance issues).

**Option C - Route 53 latency routing:**

Route users to the nearest region automatically:
```
Route 53 record: api.example.com
  Latency record -> us-east-1 ALB (for US users)
  Latency record -> ap-southeast-1 ALB (for Asian users)
```
> **Code walkthrough:** This or specific role ARN example demonstrates the concept in a production context. **KEY MECHANISM:** the runtime processes these instructions with the specific semantics of this API. **WHY IT MATTERS:** applying this pattern incorrectly causes subtle production failures under load. **TAKEAWAY: understand the execution model and failure modes before using this in production.**

Users in Singapore get ap-southeast-1 automatically.
Health checks: failover to us-east-1 if Asia region
is unhealthy.

**Recommendation:**

CloudFront for static content (immediate, no new region).
API in ap-southeast-1 for dynamic content.
Aurora Global Database with read replica in ap-southeast-1.
Route 53 latency routing to direct users automatically.

*What separates good from great:* Distinguishing between
cacheable (CloudFront sufficient) and non-cacheable
(regional deployment needed) content is the architectural
insight. Not all latency problems need a new region -
some are solved by caching at the edge.

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



