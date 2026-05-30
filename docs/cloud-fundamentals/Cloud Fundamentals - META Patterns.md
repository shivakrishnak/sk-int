---
layout: default
title: "Cloud Fundamentals - META Patterns"
parent: "Cloud Fundamentals"
nav_order: 15
permalink: /cloud-fundamentals/meta-patterns/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 27 | [Cloud Anti-Patterns](#cloud-anti-patterns) | ★☆☆ |
| 28 | [Cloud Decision Framework](#cloud-decision-framework) | ★☆☆ |
| 29 | [Vendor Lock-in Risk Management](#vendor-lock-in-risk-management) | ★☆☆ |

---

# Cloud Anti-Patterns

**Interview Weight:** ★☆☆ - Recognition and avoidance.
Knowing what NOT to do separates engineers who have
operated cloud systems from those who have only read
about them. Cloud anti-patterns appear in every production
environment.

---

### 🎯 Model Answer

**30 seconds:**

> Cloud anti-patterns are common mistakes that seem
> reasonable but cause cost, reliability, or security
> problems. The top ones: "lift and shift and forget"
> (EC2 instead of managed services, no optimization),
> "snowflake instances" (manually configured servers
> that can't be reproduced), "public by default" (S3
> public ACL, open security groups), and "single region
> single AZ" (no resilience). Recognizing these patterns
> early prevents expensive fixes later.

**3 minutes:**

> The most costly cloud anti-patterns in production:
>
> 1. Lift-and-shift without optimization: migrate to EC2
>    but never right-size or use Reserved Instances.
>    Result: 2-3x the cost of equivalent on-prem.
>    Cloud is only cheaper when you use it correctly.
>
> 2. Snowflake infrastructure: manually SSH into EC2 and
>    configure. No IaC. Cannot reproduce. When the instance
>    fails, the configuration is lost. Fix: Terraform all
>    infrastructure from day one.
>
> 3. Single point of failure: one EC2 in one AZ.
>    That AZ goes down: application is down.
>    Cost to fix: minimal (ALB + Auto Scaling Group = $20/month).
>    Risk avoided: AZ failures happen multiple times per year
>    per region.
>
> 4. Credentials in code: AWS access keys hardcoded in
>    application code or config files committed to git.
>    This is OWASP A07:2021 (Identification and Authentication
>    Failures). GitHub bots find leaked credentials within
>    minutes. Fix: IAM roles, never static keys in code.
>
> 5. No tagging strategy: resources without Owner, Env,
>    or Cost-Center tags. Cannot do cost allocation.
>    Cannot identify orphaned resources.
>    Cannot enforce access controls by environment.

**Blank Mind Recovery:**

**(1) Top 5:** "Lift+shift no optimization, snowflake instances,
single AZ, credentials in code, no tagging."

**(2) Most dangerous:** "Credentials in code - security.
Single AZ - reliability. No optimization - cost."

---

### 📘 Concept Explanation

**Pattern Identification Quick Reference:**

```
ANTI-PATTERN 1: Lift-Shift-Forget
  Signal: EC2 instances all running at < 20% CPU
  Signal: No Reserved Instances on 1+ year old workloads
  Signal: "It's basically the same cost as on-prem"
  Fix: Compute Optimizer recommendations + Reserved Instances

ANTI-PATTERN 2: Snowflake Instance
  Signal: "Only Bob knows how to configure that server"
  Signal: "We can't terminate that instance - it has things on it"
  Signal: No launch template, AMI, or IaC for that server
  Fix: document via reverse-engineering (create AMI as backup)
    then replace with IaC-defined Auto Scaling Group

ANTI-PATTERN 3: Pets not Cattle
  Related to snowflake: treating servers as irreplaceable
  pets rather than replaceable cattle.
  Cloud-native design: any instance can be terminated
  and auto-replaced without impact.
  Signal: deployments that SSH into running instances
    and modify files in-place
  Fix: immutable infrastructure - replace, don't modify

ANTI-PATTERN 4: Credentials in Code
  Signal: `AWS_ACCESS_KEY_ID = "AKIA..."` in config file
  Signal: .env file committed to repository
  Signal: IAM user (not role) for EC2/ECS workloads
  Fix: IAM instance profiles for EC2, task roles for ECS,
    Secrets Manager for third-party credentials
  Verify: `git secrets --scan` or `trufflehog` on repo history

ANTI-PATTERN 5: No Cost Visibility
  Signal: End of month "surprise" AWS bill
  Signal: Cannot answer "which team owns this $5,000 resource?"
  Signal: S3 bucket with 10TB, unknown owner, not queried in months
  Fix: tagging + AWS Cost Explorer + AWS Budgets alerts
```

---

### 💻 Code Example

```bash
# BAD: Manual EC2 configuration (snowflake)
ssh ec2-user@<ip>
sudo yum install -y java-17-openjdk
sudo mkdir /opt/app
sudo scp app.jar ec2-user@<ip>:/opt/app/
# Edit /etc/systemd/system/app.service manually
# This instance is now a snowflake. Cannot reproduce.
```

```terraform
# GOOD: IaC-defined, reproducible infrastructure
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
    # IAM role: no static credentials needed
  }

  # No SSH: all config in user_data
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y java-17-openjdk
    mkdir -p /opt/app
    aws s3 cp s3://my-artifacts/app.jar /opt/app/
    cat > /etc/systemd/system/app.service <<SVC
    [Unit]
    Description=App Service
    [Service]
    ExecStart=/usr/bin/java -jar /opt/app/app.jar
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SVC
    systemctl enable app && systemctl start app
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "app-server"
      Env        = "prod"
      Owner      = "platform-team"
      CostCenter = "engineering"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  min_size = 2
  max_size = 10
  # Spans multiple AZs: no single-AZ SPOF
  vpc_zone_identifier = var.private_subnet_ids
  launch_template {
    id = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

> **Code walkthrough:** The BAD pattern manually SSH into
> an instance and configures it in place - this is the
> "snowflake" anti-pattern. The instance is now unique
> and irreplaceable. Any configuration change requires
> SSHing in again. If the instance is terminated, the
> configuration is lost. The GOOD pattern uses a Launch
> Template with user_data for all configuration: the
> instance bootstraps itself from S3 artifacts. The
> Auto Scaling Group spans multiple AZs eliminating the
> single-AZ SPOF. The IAM instance profile eliminates
> the need for static credentials. The mandatory tags
> (Env, Owner, CostCenter) enable cost allocation.
> Any instance in this group can be terminated and
> auto-replaced with identical configuration in < 3 minutes.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Cloud anti-patterns are common mistakes. The main ones
> I watch for are: credentials hardcoded in code (use
> IAM roles instead), resources in a single availability
> zone (use multiple AZs for resilience), and instances
> configured manually without infrastructure-as-code
> (use Terraform so the configuration is reproducible)."

---

**Senior / Staff:**

> "Anti-patterns can be grouped by impact area. Cost:
> lift-and-shift without optimization, no Reserved
> Instances for stable workloads. Reliability: single
> AZ, single region for critical workloads, no circuit
> breakers between services. Security: static credentials
> in code or environment variables when IAM roles are
> available, overly permissive IAM policies (admin everywhere),
> publicly accessible resources. Operability: snowflake
> instances (cannot be reproduced), no observability
> baseline (what does normal look like?), no tagging
> (cannot do cost allocation or impact analysis). In a
> code review or architecture review, I look for these
> patterns actively - they're the difference between
> a system that works in the demo and a system that
> runs reliably in production for years."

---

### ⚠️ Common Misconceptions

**Misconception: "Cloud is inherently more secure than
on-prem because AWS has advanced security."**

The Shared Responsibility Model: AWS secures the cloud
infrastructure. You secure what runs IN the cloud.
Credentials in code, public S3 buckets, open security
groups, unused IAM admin users - these are all customer
responsibility. The cloud does not prevent these; it
just provides the tools to fix them. More data breaches
are caused by misconfigured cloud resources (Capital One,
Uber, Twitter) than by cloud provider failures.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Open S3 bucket exposes customer data**

*Symptom:* Security team alerts that an S3 bucket
containing PII is publicly readable. Data has been
accessed by external IPs.

*Root cause:* S3 bucket created with
`aws s3api put-bucket-acl --acl public-read` or
S3 Block Public Access was disabled.

*Detection:*
```bash
# Audit all S3 buckets for public access:
aws s3api list-buckets --query 'Buckets[].Name' \
  --output text | tr '\t' '\n' | while read bucket; do
  result=$(aws s3api get-public-access-block \
    --bucket "$bucket" \
    --query 'PublicAccessBlockConfiguration' \
    --output json 2>/dev/null)
  if echo "$result" | grep -q '"false"'; then
    echo "WARN: $bucket has public access settings disabled"
  fi
done

# AWS Config rule catches this automatically:
aws configservice put-config-rule \
  --config-rule '{"ConfigRuleName":"s3-bucket-public-read-prohibited",
  "Source":{"Owner":"AWS","SourceIdentifier":
  "S3_BUCKET_PUBLIC_READ_PROHIBITED"}}'
```

*Fix:* Enable S3 Block Public Access at account level.
No bucket in the account can be made public.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ - anti-pattern list. Comparison table
not applicable.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword. System design not required.)*

---

### 📊 Diagram

*(Omit: concept is a pattern list, not a system flow.)*

---

---

# Cloud Decision Framework

**Interview Weight:** ★☆☆ - Mental model for cloud choices.
Having a structured decision process for cloud architecture
questions separates engineers who reason from principles
from those who guess.

---

### 🎯 Model Answer

**30 seconds:**

> Cloud decisions should follow four dimensions: build
> vs buy (managed service vs self-managed), optimize for
> cost vs performance vs reliability (pick two), which
> pricing model (on-demand vs reserved vs spot), and
> which cloud service type (IaaS vs PaaS vs SaaS vs FaaS).
> For most decisions, prefer managed services (buy) over
> self-operating (build), unless the managed service
> cannot meet a specific requirement.

**3 minutes:**

> Structured decision framework for cloud architecture:
>
> Dimension 1 - Build vs Buy:
> Should you use a managed service (RDS, Lambda, MSK)
> or self-operate (PostgreSQL on EC2, self-managed Kafka)?
> Default: managed service unless:
> - Cost difference > 3x and you have dedicated ops capacity
> - Specific configuration not available in managed service
> - Regulatory requirement to control all infrastructure
> - Migration is impractical (existing deep integration)
>
> Dimension 2 - CAP-like trade-off:
> Cost vs Performance vs Reliability: you get two.
> Cheap + performant = low resilience (single instance)
> Performant + reliable = expensive (Multi-AZ, reserved)
> Cheap + reliable = lower performance (spot, multi-region
>   with longer latency)
>
> Dimension 3 - Pricing model:
> On-demand: maximum flexibility, maximum cost. Use for
>   unknown/new workloads, burst traffic.
> Reserved: 40-60% discount, 1-3 year commitment. Use for
>   stable baseline workloads.
> Spot: 70-90% discount, can be interrupted. Use for
>   batch jobs, CI/CD, stateless compute.
>
> Dimension 4 - Managed to serverless spectrum:
> IaaS (EC2): most control, most ops
> PaaS (Elastic Beanstalk, App Engine): moderate
> FaaS (Lambda): event-driven, per-invocation cost
> SaaS (managed databases, queues): zero ops

**Blank Mind Recovery:**

**(1) Default:** "Managed service unless there's a specific
reason not to. RDS over PostgreSQL on EC2."

**(2) Pricing:** "On-demand = new. Reserved = stable.
Spot = interruptible."

**(3) Trade-off:** "Cost vs Performance vs Reliability:
pick two."

---

### 📘 Concept Explanation

**The Managed Service Decision Tree:**

```
Should I use a managed service?

Start:
  Is there an AWS managed service for this component?
  (RDS for PostgreSQL, MSK for Kafka, ElastiCache for Redis)

  Yes -> What is the managed service limitation?
    No limitation -> USE MANAGED SERVICE

    Limitations to check:
    a) Cost: managed is > 3x self-managed?
       Yes, AND you have dedicated DBA/ops capacity?
       -> Evaluate self-managed
       No (or no ops capacity) -> managed service

    b) Config: need a specific config managed doesn't offer?
       (Aurora: no tablespace support, parameter limits)
       Yes, required for correctness -> self-managed
       No, or workaround exists -> managed service

    c) Regulatory: must control all infrastructure?
       (some government contracts, some financial regulations)
       Yes -> dedicated tenancy or self-managed
       No -> managed service

  No managed service -> self-managed (no choice)

EXAMPLES:
  PostgreSQL workload -> RDS Aurora PostgreSQL
    (unless specific PostgreSQL extensions not supported)
  Kafka workload -> Amazon MSK
    (unless 10x MSK cost vs self-managed EC2 Kafka,
    which only makes sense at > 1TB/day scale)
  Redis workload -> ElastiCache Redis
    (unless need Redis modules: RedisSearch, RedisGraph)
```

---

### 💻 Code Example

```python
# DECISION FRAMEWORK: Cost model for managed vs self-managed
# Example: RDS PostgreSQL vs EC2 PostgreSQL

# Self-managed EC2 PostgreSQL (single primary):
ec2_cost_per_month = {
    'compute': 350,   # m6g.xlarge On-Demand
    'ebs_storage': 60,  # 500GB gp3
    'ebs_iops': 0,    # gp3 includes 3000 IOPS
    'backup_storage': 30,  # 500GB S3 for pg_dump
    'dba_hours': 800,  # 10 hrs/month * $80/hr
    'downtime_risk': 200,  # Risk-adjusted SLA penalty
}
total_self_managed = sum(ec2_cost_per_month.values())
# = $1,440/month

# RDS PostgreSQL Multi-AZ (same spec, managed):
rds_cost_per_month = {
    'instance': 580,  # db.m6g.xlarge Multi-AZ On-Demand
    'storage': 115,   # 500GB gp3 * 2 (Multi-AZ)
    'backup': 0,      # 100% DB size free for backup
    'dba_hours': 160,  # 2 hrs/month (minor config only)
    'downtime_risk': 20,  # SLA 99.95%, auto-failover
}
total_rds = sum(rds_cost_per_month.values())
# = $875/month

# RDS is CHEAPER when DBA time is accounted for:
savings = total_self_managed - total_rds
print(f"RDS saves: ${savings}/month = ${savings*12}/year")
# RDS saves: $565/month = $6,780/year

# Decision rule:
ratio = total_self_managed / total_rds
if ratio > 3:
    print("Self-managed may be worth evaluating")
elif ratio > 1:
    print("Managed service: cheaper and less operational burden")
else:
    print("Managed service: even if slightly more expensive, "
          "ops savings justify it")
# Output: Managed service: cheaper and less operational burden
```

> **Code walkthrough:** The cost model makes the build-vs-buy
> decision quantitative. The key insight is that DBA time
> dominates: 10 hours/month of skilled DBA time at $80/hour
> equals $800/month - more than the difference between
> EC2 and RDS compute costs. The risk-adjusted downtime
> cost reflects that single-AZ EC2 PostgreSQL fails when
> the AZ fails (no auto-failover), while RDS Multi-AZ
> automatically fails over in 30-60 seconds. The result
> shows RDS is cheaper even without considering the value
> of engineer time spent on operations. The 3x rule (only
> evaluate self-managed if self-managed is > 3x cheaper)
> means that for most workloads, the managed service is
> the correct default.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "When choosing between cloud services, I default to
> managed services because they reduce operational overhead.
> For pricing, I use on-demand for new workloads until
> I know the baseline, then switch to Reserved Instances
> for consistent savings. For the IaaS vs PaaS vs FaaS
> choice: use the highest level of abstraction that meets
> your requirements, because higher abstraction means less
> you have to manage."

---

**Senior / Staff:**

> "Cloud decisions should be driven by explicit criteria
> rather than defaults or preferences. For managed vs
> self-managed: model the total cost including engineering
> time, not just compute cost. For pricing model: Reserved
> Instances for stable workloads, Savings Plans for flexible
> compute, Spot for interruptible workloads. The trade-off
> framework I use is cost/performance/reliability: being
> explicit about which you're optimizing for prevents
> architecture debates that are really values mismatches.
> For service selection: highest managed abstraction that
> meets requirements, because operational overhead compounds
> - every self-managed service you add is another thing
> your team must operate, monitor, and upgrade."

---

### ⚠️ Common Misconceptions

**Misconception: "Managed services are always more expensive
than self-managing."**

This is only true when you count compute cost and ignore
engineer time. RDS costs more per compute-hour than EC2,
but PostgreSQL on EC2 requires patching, backup management,
HA configuration, failover testing, and performance tuning.
Fully loaded, managed services are typically cheaper
for teams of < 20 engineers who cannot justify a dedicated
database operations function.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Wrong pricing model causes budget overrun**

*Symptom:* AWS bill for EC2 is 5x the estimate.
A new application was launched and auto-scaled
to 50 instances due to unexpected traffic.
All On-Demand. Estimate was based on 5 instances.

*Root cause:* No Auto Scaling Group max size. No AWS
Budget alert. On-Demand for a workload that could use
Spot (it was a stateless batch processor).

*Prevention:*
```bash
# Always set a max size on Auto Scaling Groups:
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name myapp-asg \
  --max-size 20  # hard cap

# Set AWS Budget alert:
aws budgets create-budget \
  --account-id <account> \
  --budget '{"BudgetName":"ec2-monthly",
    "BudgetLimit":{"Amount":"500","Unit":"USD"},
    "TimeUnit":"MONTHLY","BudgetType":"COST",
    "CostFilters":{"Service":["Amazon Elastic Compute Cloud"]}}'
```

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ - decision framework. No direct comparison
table applies.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: decision framework is textual, not a system
flow diagram.)*

---

---

# Vendor Lock-in Risk Management

**Interview Weight:** ★☆☆ - Risk awareness and mitigation.
Every cloud architecture decision has a lock-in component.
Understanding the spectrum from high to low lock-in and
how to mitigate where it matters is foundational knowledge
for anyone making cloud architecture decisions.

---

### 🎯 Model Answer

**30 seconds:**

> Vendor lock-in risk is the cost of switching providers
> if you need to. All cloud services have some lock-in;
> the question is whether it matters. Proprietary APIs
> (DynamoDB, Lambda) are high lock-in. Open protocols
> (S3-compatible storage, PostgreSQL) are low lock-in.
> Mitigation: use open standards at the data layer
> (Parquet, PostgreSQL protocol), containerize workloads,
> avoid deeply proprietary features unless their value
> justifies the switching cost.

**3 minutes:**

> Lock-in spectrum (low to high):
>
> Compute: EC2 is low lock-in (run any OS/app, standard VMs).
>   Lambda is high lock-in (invocation model, 15-min limit,
>   cold start characteristics, SDK required).
>   ECS/Kubernetes: medium (Kubernetes is portable,
>   but ECS is AWS-specific).
>
> Storage: S3 is medium lock-in. S3 API is a de facto
>   standard (MinIO, Wasabi, Backblaze B2, GCS all support
>   S3-compatible API). Data egress cost is the real lock-in.
>   DynamoDB is high lock-in: no portable protocol,
>   no open-source equivalent.
>
> Database: RDS PostgreSQL is low lock-in (standard SQL,
>   standard protocol). Aurora is medium lock-in (mostly
>   compatible but Aurora-specific features). DynamoDB is
>   high lock-in. Aurora Global Database patterns may not
>   map to other providers.
>
> Queuing: SQS is medium lock-in (simple protocol but
>   AWS-specific). Kafka/MSK is low lock-in (standard
>   Kafka protocol).
>
> Mitigation strategy:
>   - Accept high lock-in when the service provides
>     significant value (DynamoDB's performance profile
>     is worth the lock-in for certain use cases)
>   - Use open standards at the data layer:
>     Parquet over proprietary formats
>     PostgreSQL over DynamoDB where possible
>   - Containerize compute: Docker images run anywhere
>   - Parameterize configuration: database URLs in
>     environment variables (not hardcoded)
>   - Avoid provider-specific orchestration: Kubernetes
>     over ECS when portability matters

**Blank Mind Recovery:**

**(1) Spectrum:** "Compute: EC2 low, Lambda high.
Storage: S3 medium, DynamoDB high.
Database: PostgreSQL low, DynamoDB high."

**(2) Mitigation:** "Open data formats (Parquet), open
protocols (PostgreSQL), containers for compute."

**(3) Key question:** "Does the lock-in value justify
the switching cost? DynamoDB performance = often yes."

---

### 📘 Concept Explanation

**Lock-in Taxonomy:**

```
DIMENSION 1: DATA LOCK-IN (hardest to escape)
  High: Proprietary binary format, no export API
  Medium: Standard format but large volume (egress cost)
  Low: Open format, open protocol, easy export

  Examples:
  - DynamoDB: no SQL, no standard export (JSON only)
              switching requires full application rewrite
  - S3: standard object storage, S3 API widely supported,
        but 10PB at $0.09/GB egress = $900,000 to leave
  - RDS PostgreSQL: standard SQL, pg_dump works anywhere
                    move to Azure Database for PostgreSQL:
                    connection string change only

DIMENSION 2: API LOCK-IN (moderate effort to escape)
  High: AWS SDK calls throughout application code
  Medium: application uses SDK but through abstraction
  Low: standard protocol (JDBC, S3 API, SMTP)

  Examples:
  - Lambda: aws-lambda-java-core dependency,
            handler signature, context object
  - SQS: aws-java-sdk-sqs calls
         (vs RabbitMQ client: AMQP protocol, portable)
  - JDBC to RDS: standard JDBC - no AWS dependency in code

DIMENSION 3: OPERATIONAL LOCK-IN (easiest to escape)
  High: AWS-specific deployment pipeline, IAM policies,
        CloudWatch alarms
  Medium: Terraform (provider plugins are AWS-specific
          but Terraform itself is portable)
  Low: standard OS, standard config management

  Operations are usually the easiest to rewrite -
  the deployment scripts change, but the application
  code doesn't.
```

---

### 💻 Code Example

```java
// BAD: High lock-in - AWS SDK calls throughout service layer
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

@Service
public class OrderService {
    private final SqsClient sqs;

    public void submitOrder(Order order) {
        // AWS-specific API throughout business logic:
        SendMessageRequest req = SendMessageRequest.builder()
            .queueUrl(queueUrl)
            .messageBody(serialize(order))
            .build();
        sqs.sendMessage(req);  // AWS SDK call in service
    }
}
// Any test or migration requires AWS SDK or mocking it.
// Cannot run locally without AWS credentials or LocalStack.
```

```java
// GOOD: Low lock-in - abstraction isolates provider
public interface MessagePublisher {
    void publish(String topic, String payload);
}

// AWS SQS implementation:
@Component
@ConditionalOnProperty(name="messaging.provider", havingValue="sqs")
public class SqsMessagePublisher implements MessagePublisher {
    private final SqsClient sqs;

    @Override
    public void publish(String topic, String payload) {
        sqs.sendMessage(SendMessageRequest.builder()
            .queueUrl(topic)
            .messageBody(payload)
            .build());
    }
}

// Local/test implementation:
@Component
@ConditionalOnProperty(name="messaging.provider", havingValue="local")
public class InMemoryMessagePublisher implements MessagePublisher {
    // Test-friendly: no AWS dependency
    private final List<String> messages = new ArrayList<>();

    @Override
    public void publish(String topic, String payload) {
        messages.add(payload);
    }
}

// Business logic uses interface only:
@Service
public class OrderService {
    private final MessagePublisher publisher;

    public void submitOrder(Order order) {
        publisher.publish("orders", serialize(order));
        // No AWS dependency in business logic
    }
}
```

> **Code walkthrough:** The BAD pattern couples the SQS
> SDK directly into the business service. Tests require
> an AWS connection or LocalStack. Switching to another
> queue (GCP Pub/Sub, RabbitMQ) requires modifying the
> business service. The GOOD pattern introduces a MessagePublisher
> interface: the business service depends on the interface,
> not the AWS SDK. The SqsMessagePublisher is the AWS
> implementation, selected by `messaging.provider=sqs`
> in configuration. The InMemoryMessagePublisher is the
> test/local implementation. To switch from SQS to GCP
> Pub/Sub: implement GcpPubSubMessagePublisher, change
> one config property. The business service and tests
> change zero lines. This is low lock-in at the API layer.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Vendor lock-in is the risk that an application becomes
> too dependent on one provider's specific APIs or services,
> making it hard to switch. I try to mitigate it by using
> standard interfaces: JDBC for databases (not SDK-specific
> calls), interfaces and dependency injection for external
> services so I can swap implementations, and open file
> formats for data. But I also accept that some lock-in
> is fine - using RDS is some lock-in, but the value
> of a managed database is usually worth it."

---

### ⚠️ Common Misconceptions

**Misconception: "Avoiding all cloud vendor lock-in
is a good architectural goal."**

Zero lock-in means operating everything yourself: your
own database clusters, your own message queues, your
own load balancers. This trades provider lock-in for
operational complexity. Managed services exist specifically
to eliminate operational overhead. Accepting lock-in
for high-value managed services (DynamoDB, Aurora,
Lambda) is a rational trade-off. The goal is not zero
lock-in but appropriate lock-in: high lock-in is fine
when the service value is high and migration probability
is low.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application cannot be tested locally due
to AWS SDK dependencies throughout**

*Symptom:* Unit tests require `@SpringBootTest` with
AWS credentials or LocalStack. Developer feedback loop
is slow: must mock AWS at the SDK level for every test.
New developers cannot run tests without configuring
AWS access.

*Root cause:* AWS SDK calls directly in service classes
rather than isolated behind interfaces.

*Diagnosis:*
```bash
# Count AWS SDK dependencies in business logic:
grep -r "import software.amazon.awssdk" \
  src/main/java --include="*.java" \
  | grep -v "config\|configuration\|adapter\|infrastructure" \
  | wc -l
# Any result > 0 = AWS calls in business logic (anti-pattern)
```

*Fix:* Introduce service interfaces (MessagePublisher,
ObjectStorage) at the application boundary. Move AWS
implementations to an infrastructure package.
Business logic depends on interfaces only.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword. Comparison table not required.)*

---

### 🏛️ System Design

*(Omit: non-★★★ keyword.)*

---

### 📊 Diagram

*(Omit: concept is a risk management pattern, not a
system flow.)*

---

### 🎯 Interview Deep-Dive

> **Timing:** 4-6 minutes per question for ★☆☆ keywords.

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 1 |
| TRADE-OFF | 1 |
| BEHAVIORAL | 1 |
| SCENARIO | 2 |

> Note: Three keywords share this Deep-Dive section.
> Question minimums per ★☆☆ = 7. This section covers
> all three META keywords collectively: Cloud Anti-Patterns,
> Cloud Decision Framework, and Vendor Lock-in Risk Management.

---

#### CONCEPT 1 (Anti-Patterns): What are the top cloud anti-patterns and how do you detect them in a production environment?

The five most costly anti-patterns and their signals:

**1. Lift-shift without optimization:**
Signal: Compute Optimizer shows > 30% of instances are
over-provisioned. Reserved Instance coverage is < 20%
on 1+ year old workloads. Monthly bill is not declining
despite no new workloads.
Detection: `aws compute-optimizer get-ec2-instance-recommendations`
Fix: right-size per recommendations, then buy Reserved Instances.

**2. Snowflake instances:**
Signal: no launch template exists for an EC2 instance.
The instance has been running for 2+ years without replacement.
SSH sessions in CloudTrail for configuration changes.
Detection: `aws ec2 describe-instances --query "Reservations[].Instances[?!Tags[?Key=='aws:cloudformation:stack-name']].[InstanceId,LaunchTime]"` - instances not managed by CloudFormation or Auto Scaling.
Fix: create an AMI (snapshot), define a launch template,
replace with Auto Scaling Group.

**3. Credentials in code:**
Signal: IAM users created for application workloads.
Access keys in environment variables or config files.
Detection: `git log --all | git grep -i "AKIA"` (finds leaked access keys in git history).
AWS: `aws iam list-users --query 'Users[].UserName'` - application users should not exist.
Fix: IAM roles for all AWS compute. Secrets Manager for third-party credentials.

**4. Single AZ workloads:**
Signal: Load balancer has targets in only one AZ.
RDS is single-AZ. Auto Scaling Group has one subnet.
Detection: `aws elbv2 describe-target-groups` + `aws elbv2 describe-target-health` - check AZ distribution.
Fix: Add a second AZ. ELB automatically load-balances across AZs.

**5. No tagging:**
Signal: Cost Explorer shows untagged resources as a
significant percentage. `aws resourcegroupstaggingapi get-resources --tag-filters Key=Env` returns many results with no Env tag.
Fix: Enable AWS Config rule `required-tags`. Deny resource
creation without required tags via SCP.

*What separates good from great:* The detection commands
(not just the description) show that the candidate can
actually find these patterns in a real AWS account,
not just describe them theoretically.

---

#### CONCEPT 2 (Decision Framework): How do you decide between Lambda and ECS/EKS for a new workload?

**Decision dimensions:**

Duration: Lambda maximum 15 minutes. If the job runs
longer, ECS/EKS. Example: video processing (hours) = ECS.
API request handling (milliseconds) = Lambda candidate.

Concurrency: Lambda auto-scales to 1,000 concurrent
by default (1,000 simultaneous invocations).
ECS: scales based on CPU/memory, typically minutes
for new task launch. If you need to handle 1,000
simultaneous requests that spike in seconds: Lambda
wins.

State: Lambda is stateless between invocations.
Any state must be external (S3, DynamoDB, ElastiCache).
ECS containers can hold state within the container
lifetime (connection pools, in-memory cache).

Cost model:
Lambda: $0.20 per 1 million requests + $0.0000166667
per GB-second. At low volume: very cheap. At high
sustained throughput: more expensive than reserved ECS.
ECS Fargate: $0.04048/vCPU-hour + $0.004445/GB-hour.
Break-even: ~500ms average Lambda duration at high
concurrency = approximately same as ECS Reserved.

Container startup: Lambda cold start 100-3000ms.
ECS task startup: 30-120 seconds. For real-time
APIs: Lambda cold start is the constraint.
For batch workloads: ECS startup time is irrelevant.

**Decision rule:**

Event-driven, < 15 min, spiky traffic, low sustained volume
-> Lambda

Long-running, sustained high throughput, stateful,
complex dependencies, large binary
-> ECS/EKS

*What separates good from great:* The cost break-even
calculation is the engineering answer. Lambda is not
always cheaper. Sustained high-throughput workloads
cost more on Lambda than reserved ECS.

---

#### DEBUGGING 1 (Decision Framework): Your Lambda function costs $5,000/month and is invoked 100 million times per month. Is this normal? How do you optimize?

**Calculate expected cost:**

100M invocations/month * $0.20 per million = $20
That's $20 in request cost. The $5,000 is duration cost.

Duration cost: $5,000 / $0.0000166667 per GB-second
= 300,000,000 GB-seconds
100M invocations = 3 GB-seconds average per invocation
= 3,000ms at 1GB memory

**Diagnosis:** Lambda functions taking 3 seconds average.

**Root cause investigation:**
```bash
# CloudWatch Insights query:
fields @timestamp, @requestId, @duration, @memorySize
| filter @duration > 1000
| stats avg(@duration), p95(@duration), p99(@duration)
| sort @timestamp desc
# Look for: cold starts, external API calls, DB connections

# Check cold start percentage:
fields @timestamp, @initDuration
| filter ispresent(@initDuration)
| stats count() as cold_starts
# High cold starts: consider provisioned concurrency
```

**Optimization options:**

1. **Reduce duration:** if function calls an external
   API or database, reduce that latency. Connection
   pooling outside the handler (module level in Python,
   static in Java = persists across invocations if same container).

2. **Right-size memory:** Lambda CPU scales with memory.
   If increasing memory from 512MB to 1024MB reduces
   duration from 3s to 1.5s: same cost per invocation,
   but often duration drops more than proportionally.

3. **Consider ECS:** 100M invocations/month at 3s average
   = 300,000 CPU-seconds/month = 83 CPU-hours/month.
   1 ECS Fargate task (1 vCPU): $0.04048 * 24 * 30 = $29/month.
   Same throughput on ECS: ~3 tasks = $90/month.
   Lambda: $5,000/month. ECS is 55x cheaper for this pattern.

*What separates good from great:* The reverse calculation
(from cost to GB-seconds to average duration) is the
diagnostic path. The ECS comparison at the end shows
the decision framework applied: Lambda is wrong for
sustained high-throughput 3-second workloads.

---

#### TRADE-OFF 1 (Vendor Lock-in): When is it worth accepting high vendor lock-in? Give a concrete example.

**The case for accepting lock-in:**

DynamoDB example:
- Performance: single-digit millisecond read/write at
  any scale, guaranteed. No self-managed NoSQL achieves
  this without significant operations investment.
- Operations: zero DBA overhead. AWS handles sharding,
  replication, failover, compaction, backups.
- Lock-in level: very high (proprietary API, no portable
  protocol, no compatible alternatives).

Is it worth it? For a use case requiring:
- < 5ms latency at 100,000 TPS
- Zero operational overhead for the database
- Automatic scaling from 0 to 1M TPS

Answer: yes. The performance and operational profile
is so differentiated that no portable alternative
provides equivalent value. Cassandra can get close
but requires dedicated operations. MongoDB Atlas
is portable but has higher latency and cost at scale.

**Quantify the decision:**

Lock-in cost = P(migration) * migration cost
= 0.05 (5% chance) * $500,000 (migration project)
= $25,000 expected lock-in cost

DynamoDB value = operational savings + performance SLA
= $50,000/year (avoided DBA) + $100,000 (SLA value)
= $150,000/year

Decision: $150,000/year value > $25,000 expected lock-in cost.
Accept the lock-in.

**When to reject lock-in:**

Proprietary ETL format (AWS Glue proprietary job scripts):
- Performance benefit: minimal vs open alternatives (Spark)
- Migration cost: rewrite all ETL jobs (weeks)
- Value: low (AWS Glue vs self-hosted Spark: similar performance)
Decision: use standard Apache Spark on EMR. Lower lock-in,
same performance, portable to any Spark environment.

*What separates good from great:* The quantified expected-value
calculation makes this a principled engineering decision
rather than a feeling. DynamoDB lock-in is worth it; ETL
format lock-in is not - the asymmetry is the key insight.

---

#### BEHAVIORAL 1: Tell me about a time you identified and resolved a cloud anti-pattern before it became a critical incident.

**STAR:**

**Situation:** During an architecture review of a 6-month
old microservices deployment, I noticed that all 12
services were using hardcoded connection strings to
an RDS database with a static IAM user (access key
stored as an ECS environment variable).

**Task:** Identify the full scope of the security risk
and remediate without application downtime.

**Action:**

Step 1: Scope audit. Used CloudTrail to find all access
key usage patterns. Key was used from ECS tasks in
the last 30 days - confirmed active use.

Step 2: Secret rotation plan. Created a new RDS user
with identical permissions. Stored in Secrets Manager.
Modified ECS task definitions to use Secrets Manager
injection (no environment variable).

Step 3: Rolling deployment across all 12 services.
Updated task definitions service by service. Each
service got new task definition pointing to Secrets
Manager. Zero downtime: ECS rolling update replaced
old tasks with new ones.

Step 4: Deactivated old access key after 7-day monitoring
period (confirmed no usage in CloudTrail).

**Result:** Eliminated the long-lived static credential.
Access is now short-lived (IAM role tokens rotated
every 15 minutes). Secrets Manager auto-rotation
configured for the RDS password every 30 days.
Added AWS Config rule to alert on new IAM access key
creation for any application identity.

*What separates good from great:* The 7-day monitoring
period before deactivating the old key (confirming no
remaining usage in CloudTrail) is the production-safe
approach. Immediately deleting credentials before
confirming all services have been migrated is a common
cause of outages during security remediations.

---

#### SCENARIO 1: A team proposes using 15 different AWS services for a new application including some highly proprietary ones (DynamoDB, Kinesis, Step Functions). How do you evaluate this proposal?

**Framework for the review:**

Step 1: Classify each service by lock-in and value:

```
Service Lock-in Assessment:
  DynamoDB: HIGH lock-in
    Value: does this app need < 5ms at 10K+ TPS?
    If yes: accept lock-in (DynamoDB is differentiated)
    If no: use RDS PostgreSQL (lower lock-in, simpler ops)

  Kinesis: MEDIUM lock-in (Kafka-compatible APIs available)
    Value: does this app need AWS-integrated streaming?
    Alternative: MSK (Kafka on AWS) - more portable protocol
    Decision: if already AWS-native: Kinesis. If portability
    matters: MSK.

  Step Functions: HIGH lock-in (proprietary state machine DSL)
    Value: does this app need complex workflow orchestration?
    If workflow has > 10 steps with branching: Step Functions
    value is high.
    If simple pipeline: Lambda chaining or ECS is sufficient.

  EC2, S3, RDS: LOW-MEDIUM lock-in
    No concerns.
```

Step 2: Check for over-engineering:

15 services for a new application is potentially over-complex.
Each service adds operational surface area, monitoring,
IAM policies, debugging complexity.
Questions to ask: "Could this be simplified?"
Step Functions + Lambda + DynamoDB + Kinesis for a CRUD
app is over-engineered. RDS + ECS covers 80% of use cases.

Step 3: Team capability:

Does the team have operational experience with DynamoDB
and Step Functions? If not: onboarding cost is high.
Start with familiar services, add proprietary ones
when the team has demonstrated need.

Recommendation: accept DynamoDB if latency profile requires it.
Prefer MSK over Kinesis for portability. Re-evaluate
Step Functions (may be simpler with standard Lambda chaining).
Reduce to 10-12 services.

*What separates good from great:* The question "could this
be simplified?" applied to a 15-service proposal shows
engineering judgment. Complexity is not sophistication.
Fewer services with clear responsibility is better architecture.

---

#### SCENARIO 2: Your company's cloud bill increases 200% in one month. No new workloads were deployed. How do you diagnose?

**Step 1: High-level cost breakdown:**

```bash
# AWS Cost Explorer: top 5 services by spend change
aws ce get-cost-and-usage \
  --time-period Start=2024-11-01,End=2024-12-01 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups | sort_by(@, &Metrics.UnblendedCost.Amount)[-5:]'
```

Identify which service increased. Common culprits:

**Data Transfer:** S3 egress or inter-region transfer.
Cause: new integration that copies data cross-region.
Check: S3 → Request metrics, egress bytes.

**EC2:** Auto Scaling scaled up unexpectedly.
Cause: memory leak causing high CPU, triggering scale-out.
Instances never scaled back in (scale-in policy too conservative).
Check: Auto Scaling activity log.

**RDS:** Multi-AZ enabled on a large instance accidentally.
Multi-AZ doubles instance cost.
Check: RDS console - Multi-AZ column.

**NAT Gateway:** high data processing bytes.
Cause: EC2 instances in private subnet connecting to
the internet for every request (missing VPC endpoint).
If querying S3 from EC2 in private subnet without
VPC endpoint: traffic routes through NAT Gateway.
$0.045/GB * high volume = significant cost.
Fix: add S3 VPC endpoint (free) -> traffic stays within VPC.

**Step 2: Verify no unauthorized access:**

If data transfer increase: check CloudTrail for
unusual API calls. Check S3 access logs for unexpected
source IPs. Check for compromised IAM credentials.

**Step 3: Prevention:**

AWS Budgets with 10% month-over-month anomaly alert.
AWS Cost Anomaly Detection (ML-based, automatic):
```bash
aws ce create-anomaly-monitor \
  --anomaly-monitor MonitorType=DIMENSIONAL,MonitorName=services
aws ce create-anomaly-subscription \
  --anomaly-subscription MonitorArnList=<arn> \
    Threshold=100,Frequency=DAILY,SubscriberList='[
    {"Address":"ops@company.com","Type":"EMAIL"}]' \
    SubscriptionName=daily-anomaly-alert
```

*What separates good from great:* The NAT Gateway to S3
anti-pattern (VPC endpoint fixes it for free) is the
non-obvious production cost leak that experienced cloud
engineers know. Most candidates would focus on EC2
or RDS without knowing this pattern.

---
