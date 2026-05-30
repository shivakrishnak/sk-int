---
layout: default
title: "Cloud Fundamentals - L4 Network Security"
parent: "Cloud Fundamentals"
nav_order: 10
permalink: /cloud-fundamentals/l4-network-security/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 22 | [Cloud Network Security and Zero Trust](#cloud-network-security-and-zero-trust) | ★★★ |

---

# Cloud Network Security and Zero Trust

**Interview Weight:** ★★★ - Senior/Staff security architecture.
Zero Trust is the dominant security model for modern cloud
deployments. Understanding the full model - network isolation,
identity-based access, workload identity, and east-west
traffic controls - is required for staff-level cloud discussions.

---

### 🎯 Model Answer

**30 seconds:**

> Zero Trust rejects "trust the network": assume breach,
> verify every request explicitly. In the cloud: Security
> Groups (stateful, per-instance), NACLs (stateless, per-subnet),
> AWS PrivateLink (no internet exposure), Service Mesh
> (mTLS, east-west), VPC endpoints (AWS service traffic
> stays internal). Every workload has an identity. No implicit
> trust based on network location.

**3 minutes:**

> Traditional perimeter model: firewall at the edge,
> trust all internal traffic. When attacker breaches perimeter:
> lateral movement is unrestricted.
>
> Zero Trust principles:
> 1. Verify explicitly: authenticate and authorize every
>    request using identity, not network location
> 2. Least privilege access: minimum required permissions,
>    time-bound, for the specific resource
> 3. Assume breach: design controls that limit blast radius
>    assuming a workload is compromised
>
> Cloud implementation layers:
>
> Layer 1 - Network segmentation:
> - Security Groups: stateful, per-ENI, allow-only
> - NACLs: stateless, per-subnet, allow + deny
> - VPC isolation: separate VPCs for prod/dev/infra
> - PrivateLink: expose services without internet or VPC peering
>
> Layer 2 - Workload identity:
> - EC2 instance roles, ECS task roles, Lambda execution roles
> - IRSA (IAM Roles for Service Accounts) in EKS
> - No long-term credentials: temporary STS tokens
>
> Layer 3 - Service-to-service authentication (east-west):
> - Service Mesh (AWS App Mesh, Istio): mTLS between services
> - Every service gets a certificate (SPIFFE standard)
> - Authentication: verify certificate before accepting request
> - Authorization: explicit allow policies per service pair
>
> Layer 4 - Data plane:
> - Encryption in transit: TLS 1.2+ everywhere, prefer TLS 1.3
> - Encryption at rest: KMS-managed keys, rotation enabled
> - No secrets in env vars: AWS Secrets Manager, SSM

**Blank Mind Recovery:**

**(1) Zero Trust core:** "Verify every request. No implicit
network trust. Minimum privilege. Assume breach."

**(2) Layers:** "SG (per instance), NACL (per subnet),
VPC isolation, workload identity (task roles), mTLS (east-west)."

**(3) Common gap:** "East-west traffic is unencrypted
by default. Service mesh or mTLS is needed for Zero Trust
inside the cluster."

---

### 📘 Concept Explanation

**Security Groups vs NACLs:**

```
SECURITY GROUP (preferred for most use cases):
  - Attached to: ENI (network interface) = per instance/pod
  - State: STATEFUL (return traffic auto-allowed)
  - Rules: ALLOW only (no explicit deny)
  - Evaluation: ALL rules evaluated, most permissive wins
  - Reference: can reference another SG as source
    (e.g. "allow from app-sg" - no IP management)

NACL (network ACL):
  - Attached to: subnet (all traffic in/out of subnet)
  - State: STATELESS (must allow BOTH directions explicitly)
  - Rules: ALLOW and DENY (numbered, lowest wins)
  - Evaluation: rules processed in numerical order (stop at match)
  - Use: coarse-grained block (deny known-malicious CIDRs)

COMMON MISTAKE with NACL:
  BAD: Allow inbound TCP 443 from 0.0.0.0/0
       Forget: allow outbound ephemeral ports 1024-65535
       Result: request arrives, response packet DENIED
       Symptom: browser hangs, connection timeout
```

**Workload Identity - No Static Credentials:**

```
WRONG PATTERN:
  ECS task definition:
    environment:
      - AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      - AWS_SECRET_ACCESS_KEY: wJalrXUtn/...
  Problem: rotate? Audit access? Rotate on engineer departure?
  Static credentials in env vars = exfiltration risk

CORRECT PATTERN:
  ECS task definition:
    taskRoleArn: arn:aws:iam::123456789012:role/TaskRole
  SDK auto-retrieves temporary credentials from IMDS:
    http://169.254.170.2/v2/credentials/{container-id}
    TTL: 6 hours, auto-rotated
  IAM policy on role: ONLY the specific S3 bucket, ONLY Put
  Permissions are auditable via CloudTrail
  Zero static credentials = zero exfiltration risk of long-lived keys
```

**East-West Zero Trust (Service Mesh):**

```
WITHOUT SERVICE MESH:
  Service A -> Service B (port 8080, HTTP, no auth)
  If A is compromised: attacker can call ANY service
  If B is compromised: any service can call it

WITH mTLS (Service Mesh - Istio/App Mesh):
  Each service gets certificate: service-a.cluster.local
  Service A -> Service B:
    1. A presents cert (proves identity: service-a)
    2. B presents cert (proves identity: service-b)
    3. Istio authorization policy:
       ALLOW source: service-a TO service-b path: /api/*
    4. Request accepted only if BOTH certs valid
       AND authorization policy allows this pair
  If A is compromised: cert is valid but policy restricts
    attacker to only the specific endpoints A is allowed to call
  Blast radius: contained to service A's authorization scope
```

---

### 💻 Code Example

```hcl
# SECURITY GROUPS: Zero Trust network model

# Only allow what is explicitly needed:
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Public HTTPS only
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP -> 301 redirect
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    # Accept ONLY from ALB security group - not from any IP
    # Zero Trust: even within VPC, must come from known source
  }
  # NO public ingress - not even port 22
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    # ONLY application tier can reach database
    # Even if bastion host is compromised: can't reach RDS
  }
  # Zero egress from RDS - databases don't initiate connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # Some RDS versions need outbound for DNS - review
  }
}


# VPC ENDPOINT: PrivateLink for AWS services
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  # App calls secretsmanager.us-east-1.amazonaws.com
  # DNS resolves to private IP within VPC
  # Traffic NEVER leaves AWS network
  # No NAT Gateway needed. No public endpoint exposure.
}


# IAM: Zero Trust workload identity
resource "aws_iam_role" "app_task" {
  name = "app-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
        }
      }
      # Confused deputy prevention: constrain to THIS account
    }]
  })
}

resource "aws_iam_role_policy" "app_task" {
  role = aws_iam_role.app_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
        # Specific bucket + object operations ONLY
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn
        # Specific secret ONLY
      }
    ]
  })
}
```

```yaml
# ISTIO: mTLS authorization policy (Kubernetes/EKS)
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend-to-api
  namespace: production
spec:
  selector:
    matchLabels:
      app: api-service
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
          - "cluster.local/ns/production/sa/frontend-sa"
        # ONLY the frontend's service account can call api-service
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/v1/*"]
        # ONLY these HTTP methods and path prefix
---
# PeerAuthentication: require mTLS for all services
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
    # All service-to-service communication must use mTLS
    # Plain HTTP between services: REJECTED
```

> **Code walkthrough:** Three concentric security layers.
> The Security Groups use SG-to-SG references: `app-sg`
> accepts only traffic from `alb-sg` (not IP-based, so
> it works even as ALB IPs change). `rds-sg` accepts only
> from `app-sg`. This creates a strict three-tier model:
> even if an attacker reaches the VPC via a different path,
> they cannot reach the database because their traffic
> comes from an SG that is not `app-sg`. The VPC endpoint
> for Secrets Manager makes secrets retrieval internal-only:
> the private_dns_enabled flag makes the standard SDK endpoint
> resolve to the private IP, so app code needs no changes.
> The IAM role's confused-deputy prevention conditions ensure
> the role can only be assumed by ECS tasks in this specific
> account - preventing cross-account confused deputy attacks.
> The Istio policy creates Zero Trust east-west: `api-service`
> rejects all requests except those from `frontend-sa`'s
> service account, verified via mTLS certificate.
> Any compromised service can only make calls allowed by
> its policy - lateral movement is blocked at the authorization
> layer.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Zero Trust means every request must be authenticated
> and authorized, even inside the network. Security Groups
> control traffic to and from each instance. In AWS, each
> service should have an IAM role with only the permissions
> it needs - no static credentials, no shared credentials.
> VPC endpoints keep AWS service traffic private. The key
> idea: don't assume traffic is safe because it's inside
> the VPC."

---

**Senior / Staff:**

> "Zero Trust requires solving three distinct problems.
> Network segmentation: Security Groups with SG-to-SG rules
> (not CIDR-based) create service-tier isolation that is
> immune to IP rotation. Workload identity: every ECS task,
> EKS pod, and Lambda function has an IAM role. No static
> credentials. Every action is attributable in CloudTrail.
> East-west authentication: by default, service-to-service
> traffic inside a VPC or cluster is unencrypted and
> unauthenticated. mTLS (via service mesh) is required for
> true Zero Trust. The often-missed threat: confused deputy
> attack on IAM. When service B accepts requests from service A
> and calls AWS APIs on A's behalf, B should verify the
> caller's identity before acting. Conditions in the IAM
> trust policy (aws:SourceArn, aws:SourceAccount) prevent
> unauthorized cross-service privilege escalation."

---

### ⚠️ Common Misconceptions

**Misconception 1: "VPC = secure network. Internal
traffic is safe."**

VPC provides network isolation from the internet, not
security between services within the VPC. An attacker who
compromises one service in the VPC can reach any other
service on any port unless Security Groups explicitly
deny it. Zero Trust requires explicit allow-listing
between every service pair. The Security Group default
for a new VPC allows all outbound: a compromised instance
can reach any IP in the VPC.

**Misconception 2: "Security Groups and NACLs are
equivalent - use either one."**

Security Groups are stateful (return traffic implicit),
reference-aware (allow by SG ID), and per-instance.
NACLs are stateless (must explicitly allow both directions),
subnet-level (coarser), and evaluated in order. Security
Groups are the primary control for most workloads.
NACLs are useful for explicit DENY rules (blocking
known-bad IP ranges) that Security Groups cannot do.
They are complementary, not alternatives.

**Misconception 3: "mTLS between services is unnecessary
overhead."**

At low request rates, mTLS overhead is microseconds.
The value is not performance - it is identity. Without
mTLS: a compromised service can impersonate any other
service. With mTLS + authorization policies: a compromised
service can only call what its certificate and policy allow.
This limits blast radius from any single service compromise.
The overhead is worth it at any non-trivial security posture.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Security Group allows too-broad access**

*Symptom:* Security audit reveals database SG allows
port 5432 from `0.0.0.0/0` (added as "temporary" fix).

*Diagnosis:*
```bash
# Find overly permissive SG rules:
aws ec2 describe-security-groups \
  --query 'SecurityGroups[].{
    GroupId:GroupId,
    GroupName:GroupName,
    Rules:IpPermissions[?
      IpRanges[?CidrIp==`0.0.0.0/0`] ||
      Ipv6Ranges[?CidrIpv6==`::/0`]
    ]}' \
  --output json | \
  python3 -c "import json,sys; \
    [print(sg['GroupId'], sg['GroupName']) \
    for sg in json.load(sys.stdin) if sg['Rules']]"
```

*Fix:* Replace CIDR source with SG reference.
Enable AWS Config Rule `restricted-ssh` and
`restricted-common-ports` for continuous monitoring.

---

**Failure 2: IMDS v1 accessible - SSRF to credential theft**

*Symptom:* Security researcher reports SSRF vulnerability
in application. Attacker could retrieve IAM credentials
from http://169.254.169.254/latest/meta-data/iam/security-credentials/

*Root cause:* Application has SSRF vulnerability AND
EC2 instance uses IMDSv1 (no token required). Attacker
uses app to retrieve temporary IAM credentials for
the instance role.

*Diagnosis:*
```bash
# Check IMDS version:
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].{
    ID:InstanceId,
    IMDSv2:MetadataOptions.HttpTokens
  }' \
  --output table
# "optional" = vulnerable to SSRF. Must be "required".
```

*Fix:*
```bash
# Enforce IMDSv2 on all instances:
aws ec2 modify-instance-metadata-options \
  --instance-id i-1234567890abcdef0 \
  --http-tokens required \
  --http-endpoint enabled
# IMDSv2 requires PUT request for token first
# Simple GET (SSRF) cannot get the token -> can't get creds
```

---

**Failure 3: Lambda function in VPC has no internet access**

*Symptom:* Lambda function deployed in VPC cannot call
external HTTPS endpoints. Returns connection timeout.

*Root cause:* Lambda in VPC uses subnet's route table.
Private subnet routes internet through NAT Gateway.
Lambda VPC config uses subnet without NAT GW access.

*Diagnosis:*
```bash
# Check Lambda VPC config:
aws lambda get-function-configuration \
  --function-name my-function \
  --query 'VpcConfig'
# Shows SubnetIds and SecurityGroupIds

# Check if subnets have NAT Gateway route:
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-xxx" \
  --query 'RouteTables[].Routes'
```

*Fix:* Use private subnets with NAT Gateway access.
Or use VPC endpoints for AWS service calls (no NAT needed).
Do not put Lambda in public subnet: ENI in public subnet
does not auto-assign public IP for Lambda functions.

---

### ⚖️ Comparison Table

| Control | Level | Stateful | Deny Rules | Scope | Use For |
|---------|-------|---------|-----------|-------|---------|
| Security Group | Instance/ENI | Yes | No | Per ENI | Primary access control |
| NACL | Subnet | No | Yes | Per subnet | Coarse block/deny |
| VPC Endpoint | VPC | N/A | N/A | Per service | Private AWS API access |
| PrivateLink | VPC | N/A | N/A | Per service | Private B2B services |
| mTLS/Service Mesh | Service | Yes | Yes | East-west | Service identity |
| WAF | Application | No | Yes | Per ALB/CF | HTTP threat protection |
| Shield | Network | N/A | N/A | Account | DDoS protection |

---

### 🏛️ System Design

**Zero Trust Cloud Architecture:**

```
PERIMETER LAYER:
  Internet -> Route 53 -> CloudFront + WAF
    WAF: rate limits, SQL injection, XSS blocks
    Shield Advanced: DDoS protection
    TLS termination: ACM cert, TLS 1.2+ enforced

NETWORK LAYER:
  [Public Subnets]: ALB, NAT GW (no app workloads)
  [Private Subnets - App]: ECS tasks, Security Group: ALB only
  [Private Subnets - Data]: RDS, Redis, Security Group: App only
  
  VPC Endpoints:
    S3, DynamoDB (Gateway - free)
    ECR, Secrets Manager, SSM, KMS (Interface - private DNS)

IDENTITY LAYER:
  Every workload: IAM Role (ECS Task Role, Lambda Role, EKS IRSA)
  Human access: IAM Identity Center (SSO), no IAM users
  No long-lived credentials anywhere

EAST-WEST LAYER (EKS/Service Mesh):
  All services: mTLS (Istio PeerAuthentication STRICT)
  All service pairs: explicit AuthorizationPolicy ALLOW rules
  Default: DENY all east-west traffic without policy

DATA LAYER:
  All data at rest: KMS CMK with key rotation enabled
  All data in transit: TLS 1.2+ (enforce in policy)
  Secrets: Secrets Manager (rotation enabled)
  No plaintext secrets in env vars, no plain S3 buckets

OBSERVABILITY:
  CloudTrail: all API calls logged to S3 + CloudWatch Logs
  VPC Flow Logs: all accept/reject traffic
  GuardDuty: threat detection (ML-based anomaly detection)
  AWS Config: continuous compliance monitoring
  Security Hub: aggregated findings
```

```mermaid
flowchart TB
    I[Internet] --> CF[CloudFront + WAF]
    CF --> ALB[ALB\nPublic Subnet]
    ALB -->|SG: from ALB-SG| APP[ECS Tasks\nPrivate Subnet\nTask Role - IAM]
    APP -->|SG: from App-SG| DB[RDS Multi-AZ\nData Subnet]
    APP -->|VPC Endpoint| SM[Secrets Manager]
    APP -->|VPC Endpoint| S3[S3 Bucket]
    APP -.->|mTLS| SVC2[Service B\nmTLS + AuthzPolicy]
    GT[GuardDuty\nConfig\nCloudTrail] -.->|monitors all| APP
```

> **Diagram walkthrough:** Defense in depth through concentric
> security rings. CloudFront with WAF filters malicious HTTP
> patterns before traffic reaches the VPC. The ALB in the
> public subnet terminates TLS and forwards to ECS tasks.
> ECS tasks have NO public access - Security Group allows
> only traffic from ALB's SG. The data tier is similarly
> isolated: RDS SG allows only from App SG. VPC endpoints
> mean AWS service calls (Secrets Manager, S3) never leave
> the AWS network. The ECS task role provides identity-based
> access to AWS APIs: no credentials in env vars. The dotted
> lines to GuardDuty and CloudTrail represent passive monitoring:
> every API call, every network flow, and every security finding
> is captured continuously. GuardDuty ML models detect anomalous
> patterns like unusual API calls or coin mining behavior
> without any rule configuration.

---

### 🎯 Interview Deep-Dive

> **Timing guide:** budget 5-7 minutes per question.
> Full answers show depth. Responses that stop at the
> definition level fail staff-level screens.

| Type | Questions |
|------|-----------|
| CONCEPT | 3 |
| DEBUGGING | 2 |
| TRADE-OFF | 2 |
| DESIGN | 2 |
| BEHAVIORAL | 2 |
| SCENARIO | 1 |

---

#### CONCEPT 1: What is the difference between Zero Trust and perimeter security, and why does the perimeter model fail in the cloud?

Perimeter security assumes: traffic inside the network is trusted,
traffic outside is untrusted. Defend the edge (firewall, VPN).
Inside = safe zone.

Three reasons this fails in the cloud:

**1. No fixed perimeter.** Cloud resources span multiple VPCs,
regions, accounts, SaaS, and partner APIs. The "network boundary"
is not meaningful when your application calls 15 external APIs,
deploys to 3 regions, and is accessed by remote employees.

**2. Lateral movement after breach.** When an attacker compromises
one workload (via app vulnerability, credential theft, supply chain),
the perimeter model gives them unrestricted access to everything
inside. All internal services accept traffic from other internal
services. The VPC becomes an unrestricted internal network.

**3. Insider threats.** A compromised identity (employee, service
account) is already inside the perimeter. Network controls provide
no defense against a legitimate-looking but malicious actor.

Zero Trust addresses all three: every request is authenticated
(identity, not network), every access is authorized (explicit
policy, not implicit trust), and access is scoped to the minimum
required (blast radius control). In the cloud: Security Groups
implement microsegmentation (not broad CIDR rules), IAM roles
implement workload identity (not shared credentials), and mTLS
implements service authentication (not implicit VPC trust).

The operational shift: Zero Trust requires continuous verification
overhead. The trade-off is explicit access control records
(CloudTrail), auditable authorization policies, and contained
blast radius when compromise occurs.

*What separates good from great:* Great answers explain WHY the
perimeter model fails (not just that it does) and connect each
Zero Trust principle to a specific cloud mechanism with a concrete
example. The blast radius point is the key insight: Zero Trust
does not prevent breaches, it contains them.

---

#### CONCEPT 2: How do Security Groups and NACLs work? When would you use each?

**Security Groups:**

Stateful: when you allow inbound TCP 443, the return traffic
(client receiving response) is automatically allowed.
No explicit outbound rule needed for responses.

Per-ENI: each EC2 instance, ECS task, Lambda, and RDS instance
has a security group attached to its network interface.
Changes take effect immediately without restart.

Allow-only: you cannot create explicit DENY rules.
Traffic not matched by any allow rule is implicitly denied.

SG references: source can be another security group ID
rather than a CIDR block. Example: allow port 5432
from `app-sg`. This means any ENI with `app-sg` attached
can reach this port. IP-address agnostic: works as
instances scale, change IPs, or are replaced.

**NACLs:**

Stateless: you must explicitly allow BOTH inbound and outbound
traffic for a connection. For TCP: allow inbound 443 AND
outbound ephemeral ports 1024-65535 (client's return port).
Missing the ephemeral port rule is a very common mistake.

Per-subnet: applies to ALL traffic entering and leaving
the subnet. Does not distinguish between instances.

Numbered rules, lowest wins: rule 100 ALLOW 10.0.0.0/8,
rule 200 DENY all. Traffic from 10.x matches rule 100 first.

Can DENY: unlike Security Groups, NACLs can have explicit
DENY rules. This is their primary advantage.

**When to use each:**

Security Groups: primary control for all service-to-service
access. Always use SG-to-SG references for clarity
and IP-independence.

NACLs: supplementary control for explicit DENY rules.
Examples: block traffic from known-malicious IP ranges,
block a specific compromised CIDR during an incident,
create coarse subnet-level isolation rules. NACLs
are NOT a substitute for Security Groups - they work
at different granularity.

Default VPC configuration: default NACL allows all traffic.
New custom VPC: all traffic denied by default until you
create Security Group rules. This is why custom VPCs
are more secure by default than the default VPC.

*What separates good from great:* Great answers explain
the stateful vs stateless distinction with a concrete
ephemeral port example. Most candidates miss the NACL
stateless gotcha.

---

#### CONCEPT 3: What is the confused deputy problem in IAM and how do you prevent it?

The confused deputy problem occurs when a service (deputy)
has permissions it should not use on behalf of a caller.

**Cloud example: cross-service assumed roles.**

Service A calls service B with a request. Service B
needs to make an AWS API call and uses its own IAM role.
An attacker creates their own account and tricks service B
into making an AWS API call that uses service B's role
but benefits the attacker's data.

**Lambda confused deputy (real scenario):**

Your Lambda function (with an IAM role) is invoked by
multiple AWS services. Attacker controls service C
and invokes your Lambda to read files from account X's S3.
Lambda uses its role (which has S3 access). Attacker
benefits from Lambda's permissions.

**Prevention: IAM condition keys:**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole",
    "Condition": {
      "StringEquals": {
        "aws:SourceAccount": "123456789012"
      },
      "ArnLike": {
        "aws:SourceArn": "arn:aws:lambda:us-east-1:123456789012:function:*"
      }
    }
  }]
}
```

`aws:SourceAccount` and `aws:SourceArn` constrain the role
assumption to only your account's Lambda functions.
Cross-account invocations from attacker accounts are rejected.

**Real-world impact:** In 2021, a confused deputy vulnerability
in AWS CloudFormation allowed cross-account privilege escalation.
AWS patched by adding SourceAccount conditions. Always add
these conditions when a service assumes a role.

*What separates good from great:* Great answers understand
this is a class of vulnerability (not just a single scenario)
and can explain the precise mechanism: B has permissions,
A tricks B to use them, A benefits. The prevention via
condition keys shows practical remediation knowledge.

---

#### DEBUGGING 1: Users report intermittent connection failures to your application. The ALB health checks pass. ECS tasks are healthy. What Zero Trust / network misconfiguration could cause this?

**Systematic diagnosis:**

```bash
# 1. Check VPC Flow Logs for REJECT patterns:
aws logs filter-log-events \
  --log-group-name /vpc/flow-logs \
  --filter-pattern '"REJECT"' \
  --start-time $(date -d '1 hour ago' +%s%3N) | \
  jq '.events[].message' | head -20
# Look for REJECT on the target ports (8080, etc)

# 2. Find the source/dest of REJECTS:
# Pattern: [version, account, eni, src, dst, srcport, dstport, proto,
#           packets, bytes, start, end, action, log-status]
# action = REJECT = Security Group or NACL denied
```

**Common root causes (with Zero Trust context):**

**NACL stateless - missing ephemeral ports:**
Client initiates from ephemeral port (e.g., 54321).
ALB responds. NACL outbound rule allows 443 outbound
but not 1024-65535. Response packets: REJECT.
*Fix:* Add outbound NACL rule: allow TCP 1024-65535 outbound.

**Security Group missing return traffic (not common - SGs are stateful,
but custom AMI with iptables can override):**
Check if custom iptables rules on the instance conflict
with Security Group stateful tracking.

**Intermittent but not all requests:**
Asymmetric routing: some instances have correct SG,
others in the same ASG have old SG (from a Terraform
apply that didn't fully propagate). Check:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=app-asg" \
  --query 'Reservations[].Instances[].{
    ID:InstanceId, SG:SecurityGroups[].GroupId}'
```

**ALB idle timeout vs ECS connection pool:**
ALB closes idle connections after 60 seconds.
If connection pool holds connections longer, requests
on stale connections get TCP RST from ALB. Not a SG issue
but mimics it. Fix: `IdleConnectionTimeout=30s` in pool.

*What separates good from great:* Candidates who jump
directly to Flow Logs show operational experience.
The NACL stateless ephemeral port answer is the single
most common real-world cause of this symptom.

---

#### DEBUGGING 2: Your application is logging AWS API errors: "Access Denied (s3:GetObject). The execution role of the Lambda does not have the permission." But the IAM policy clearly has s3:GetObject. What are the possible causes?

**Possible causes (systematic):**

**1. Resource mismatch (most common):**

```bash
# Check the actual resource ARN in the error vs policy:
aws lambda get-function-configuration \
  --function-name my-fn \
  --query 'Role'
# Get role ARN, then:
aws iam get-role-policy \
  --role-name my-fn-role \
  --policy-name inline-policy
# Look at Resource - is it exact bucket ARN or wildcard?
# Common: policy allows arn:aws:s3:::bucket-name
# But access denied: role needs arn:aws:s3:::bucket-name/*
# (bucket-level permission vs object-level permission)
```

**2. S3 Bucket Policy DENY overrides IAM ALLOW:**

S3 evaluates: bucket policy + IAM policy. If bucket policy
has explicit DENY, it overrides IAM ALLOW.

```bash
aws s3api get-bucket-policy --bucket my-bucket
# Look for explicit Deny statements
# Common: Deny if not from specific VPC endpoint
# If Lambda is NOT in VPC or uses wrong endpoint: denied
```

**3. KMS key policy if object is encrypted:**

Even if Lambda has s3:GetObject, if object is encrypted
with a CMK and Lambda's role is not in the key policy,
decryption fails: "Access Denied".

```bash
aws kms get-key-policy --key-id <key-id> --policy-name default
# Check Lambda role ARN is in the key users list
```

**4. SCP (Service Control Policy) denying at org level:**

If account is in an AWS Organization, SCP can deny
actions that IAM allows. The error looks the same.

```bash
aws organizations describe-effective-policy \
  --policy-type SERVICE_CONTROL_POLICY
# Check for Deny statements on S3
```

*What separates good from great:* The KMS decryption failure
manifesting as S3 Access Denied is the most-missed cause.
The SCP investigation shows understanding of AWS organizations
and layered policy evaluation. Great answers list all four
causes with the diagnostic command for each.

---

#### TRADE-OFF 1: Service Mesh / mTLS adds complexity. Under what conditions is it worth the operational cost?

**The cost of mTLS:**

Control plane (Istio istiod or AWS App Mesh): additional
deployment, management, potential single point of failure.
Sidecar proxy (Envoy): additional container per pod,
CPU and memory overhead (~50-100MB RAM, ~0.5% CPU per sidecar).
Certificate management: SPIFFE/SPIRE or Istio CA rotation.
Debugging: mTLS failures are harder to debug than plain HTTP.
Operational expertise: service mesh adds significant complexity.
Migration: retrofitting existing services requires sidecar
injection and potential code changes.

**When mTLS is worth it:**

1. **Regulatory compliance** (PCI DSS, HIPAA, SOC2 Type II):
   requires encryption in transit everywhere including internal.
   mTLS satisfies this with audit evidence (cert logs).

2. **Multi-tenant workloads**: services from different tenants
   or teams sharing a cluster. Without mTLS, any compromised
   service can call any other service.

3. **High-value data**: financial transactions, PII processing.
   Blast radius containment is worth the overhead.

4. **Mature platform team**: mTLS adds complexity that an
   immature team will misconfigure or struggle to debug.
   Without a platform team managing it: risk of incorrectly
   configured policies that break traffic.

**When mTLS is NOT worth it:**

- Small team (< 5 engineers): operational burden outweighs benefit
- Single-tenant, low-risk workloads: overhead not justified
- Monolith or 2-service architecture: point-to-point TLS
  with client cert validation simpler than full mesh

**Alternative with lower complexity:**
- Application-level authentication: JWT tokens between services,
  validated at each service. Lower overhead than sidecar proxy.
  Weaker: no transport-level encryption, more app code.

*What separates good from great:* Great answers quantify
the overhead (RAM, CPU per sidecar), identify the organizational
precondition (platform team), and offer the alternative
(JWT) for teams not ready for mesh.

---

#### TRADE-OFF 2: Private subnets + NAT Gateway vs VPC endpoints. How do you decide which AWS services should use VPC endpoints?

**The base cost analysis:**

NAT Gateway:
- $0.045/GB processed + $0.045/hr per gateway
- High-volume services (ECR pulls, S3 access): hundreds $/month
- All traffic goes to internet and back (even to AWS services)
- Performance: single hop through AWS backbone

VPC Endpoint (Interface):
- $0.01/hr per endpoint per AZ + $0.01/GB
- ECR: 1 endpoint = $7.20/month/AZ. At 3 AZs: $21.60/month.
- Traffic stays within AWS network
- Private DNS enabled: no code changes, SDK uses same endpoint

VPC Endpoint (Gateway):
- Free (no hourly charge, no data charge)
- Available for: S3, DynamoDB only
- Always use: zero reason not to

**Decision framework:**

Gateway endpoints (S3, DynamoDB): ALWAYS use. Free.

Interface endpoints (ECR, Secrets Manager, SSM, KMS, etc.):

Calculate monthly savings:
- NAT Gateway data cost = volume_GB * $0.045
- Endpoint cost = $7.20/AZ/service
- Break-even: volume_GB = 7.20/0.045 = ~160 GB/service/AZ
- If > 160 GB/month through NAT for this service: endpoint saves money

Priority order (highest value first):
1. ECR: Docker image pulls are large (1-2 GB/image) * frequent task starts
2. S3 (Gateway - free regardless)
3. Secrets Manager: every Lambda cold start fetches secrets
4. SSM Parameter Store: config fetches on start
5. CloudWatch Logs: high-volume logging
6. KMS: encryption calls in crypto-heavy services

Additional benefit beyond cost: security.
Interface endpoints reduce attack surface: traffic never
reaches internet. If NAT Gateway is compromised or if
DNS is spoofed, traffic to public AWS endpoints is at risk.
VPC endpoints eliminate this attack vector.

*What separates good from great:* The break-even calculation
(160 GB/service/AZ) is the engineering answer. Staff-level
candidates extend to the security benefit and prioritize
by value, not just by cost.

---

#### DESIGN 1: Design the security architecture for a multi-account AWS Organization hosting a B2C fintech application. What layers would you implement?

**Account structure (account separation is the
strongest isolation boundary in AWS):**

```
Management Account: billing, organization root, SCPs only
                    (NO workloads)
Security Account:   CloudTrail aggregation, GuardDuty master,
                    Security Hub aggregation, SIEM
Shared Services:    DNS, VPC Transit Gateway, ECR registry,
                    CI/CD (CodePipeline/GitHub)
Log Archive:        All log storage (S3 + CloudTrail).
                    Write-only for workload accounts.
Sandbox:            Developer experimentation
                    (SCPs restrict: no public resources)
Dev Account:        Non-prod workloads
Staging Account:    Production-like, limited data
Production Account: Production workloads, most restrictive SCPs
```

**SCP guardrails (always-enforced, override IAM):**

- Deny disabling CloudTrail in any account
- Deny disabling GuardDuty in any account
- Deny creation of public S3 buckets except CDN account
- Restrict which AWS regions can be used (reduce attack surface)
- Deny creation of IAM users (force Identity Center / SSO)
- Require MFA for console access

**Network layer:**

Production VPC: 3 AZs, private subnets only for workloads.
AWS Transit Gateway: connects accounts with strict route tables.
Centralized egress through inspection VPC (AWS Network Firewall
or third-party). Ingress: CloudFront + WAF.

**Identity layer:**

IAM Identity Center (SSO): federated to corporate IdP (Azure AD).
No long-lived IAM users. Session duration: 1-8 hours.
Break-glass account: emergency access, triggers PagerDuty,
requires two approvals.

**Data layer:**

KMS Customer Managed Keys: one CMK per data classification
(PII, financial, general). Key policy: only production role
can use PII key. Automated key rotation.
S3 Block Public Access: enabled at organization level.
RDS: encrypted, Multi-AZ, no public endpoint.

**Monitoring:**

GuardDuty: threat detection in all accounts, aggregated to
Security Account.
CloudTrail: API logs in all accounts, stored in Log Archive.
AWS Config: compliance rules for all accounts
(Security Hub standards: CIS, PCI DSS).
Security Hub: aggregated findings, automated remediation
Lambda for some findings.

*What separates good from great:* Account-level isolation
is the architectural answer to Zero Trust at the AWS level.
SCPs are more powerful than IAM because they cannot be
overridden by any IAM policy. The Log Archive + Security
Account pattern is the canonical enterprise AWS security design.

---

#### DESIGN 2: Your EKS cluster serves 50 microservices. How do you implement Zero Trust between services?

**Four layers for EKS Zero Trust:**

**Layer 1: Network (Kubernetes NetworkPolicy):**

```yaml
# Default deny all:
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  # No ingress/egress rules: deny all
```

Then add explicit allow policies for each service pair.
Requires CNI that supports NetworkPolicy (Calico, VPC CNI
with network policy support, Cilium).

**Layer 2: mTLS (Istio):**

Enforce mTLS at transport layer. Certificate per workload
identity (SPIFFE SVID). AuthorizationPolicy defines
which service can call which endpoint.

**Layer 3: IRSA (IAM Roles for Service Accounts):**

Each service account gets its own IAM role with minimum
required AWS permissions. Service A's pod cannot assume
Service B's role. AWS API calls are attributable per service.

```bash
eksctl create iamserviceaccount \
  --name payment-service \
  --namespace production \
  --cluster prod-cluster \
  --attach-policy-arn arn:aws:iam::123:policy/PaymentPolicy \
  --approve
# IRSA uses OIDC to bind K8s service account to IAM role
# Only pods with this service account can assume the role
```

**Layer 4: Secrets (External Secrets Operator + Secrets Manager):**

No secrets in pod env vars. External Secrets Operator
syncs from Secrets Manager to K8s Secrets at runtime.
Rotation: Secrets Manager rotates automatically,
ESO syncs changes to pods.

**Operational reality at 50 services:**

Manual AuthorizationPolicy maintenance scales poorly.
Use a service catalog to track dependencies (who calls whom).
Tools: Kiali (Istio visualization), identify undeclared
connections (policy violations), auto-generate policies
from observed traffic (permissive mode first, then enforce).

*What separates good from great:* The four-layer answer
(NetworkPolicy + mTLS + IRSA + secrets) covers every
attack surface. The operational scaling point (policy
management for 50 services requires automation) shows
real-world implementation experience beyond the textbook.

---

#### BEHAVIORAL 1: Describe a time you identified a security misconfiguration in a production cloud environment. What was it, how did you find it, and what did you do?

**Structured response (STAR):**

**Situation:** During a quarterly security review of our
e-commerce platform, I was auditing VPC Security Group rules
using AWS Config and Security Hub findings.

**Task:** Find and remediate any Security Groups that allowed
overly permissive access, which could increase blast radius
in case of application compromise.

**Action:** I ran a Security Hub check on `restricted-ssh`
and `vpc-sg-open-only-to-authorized-ports` compliance rules.
Found two Security Groups with port 0-65535 open to
`0.0.0.0/0` - one on the application tier, one on an
internal ETL server that "needed to reach several services."

I traced the history in CloudTrail: an engineer had added
the rule 6 months earlier to "temporarily" fix a connectivity
issue and never reverted. I used VPC Flow Logs to analyze
actual traffic patterns over the prior 30 days. The actual
required ports: 5432 (Postgres), 6379 (Redis), 8080 (API).
I replaced the wildcard rule with three specific SG-to-SG
rules, tested connectivity, and confirmed no service impact.

For the application tier SG: it had `0.0.0.0/0` on port 443.
This was intentional (public-facing HTTPS), so I verified
the WAF and Shield configuration upstream and confirmed
the ALB SG was the appropriate boundary.

**Result:** Reduced attack surface significantly. Added
AWS Config rule to alert on SG rules with `/0` sources
to prevent recurrence. Created a runbook for connectivity
debugging that guides engineers to specific port rules
rather than wildcard rules.

*What separates good from great:* The use of Flow Logs
to determine minimum required ports shows data-driven
security hardening rather than guesswork. The follow-up
preventive control (Config alert) shows systems-thinking.

---

#### BEHAVIORAL 2: How do you balance security controls with developer velocity? Give a specific example of a trade-off you made.

**Structured response:**

**Context:** We were implementing VPC endpoints for all AWS
service traffic as part of a Zero Trust initiative.
The original plan required all developers to update
their local test configurations to use private endpoints.
This would require every developer to run tests against
a VPC-connected environment (no local mocking).

**Trade-off:** Full Zero Trust purity (every AWS call through
private endpoint, even in dev) vs developer productivity
(local testing with AWS SDK without VPC connectivity).

**Decision:** We implemented three separate policies by
environment:

- Production: interface VPC endpoints mandatory, public
  endpoint disabled in bucket policies
- Staging: same as production (required for compliance testing)
- Development accounts: VPC endpoints optional, public
  endpoints allowed with IP restriction to office/VPN CIDRs
- Local development: AWS CLI/SDK with named profiles,
  no VPC requirement, localstack for offline testing

The additional guardrail: SCPs blocked public resource
creation in staging/production. Developers could still
test locally freely, but any deployment to staging/prod
went through VPC endpoints automatically via Terraform.

**Result:** No security regression in production. Developer
productivity unaffected for local workflows. Compliance
auditors accepted the environment-tiered approach because
production and staging were fully locked down.

*What separates good from great:* Environment-tiered
security (not uniform) is the pragmatic answer. The key
insight: production security posture is non-negotiable;
developer experience can be flexible. SCPs as the enforcement
mechanism (not just policy) shows operational sophistication.

---

#### SCENARIO 1: GuardDuty triggers "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS." An ECS task's temporary credentials were used from an external IP. What do you do?

**Incident Response (step by step):**

**Immediate containment (first 5 minutes):**

```bash
# 1. Identify the compromised task role:
# GuardDuty finding includes: roleArn, EC2 sourceIPAddress

# 2. Revoke all active sessions for this role IMMEDIATELY:
aws iam put-role-policy \
  --role-name compromised-task-role \
  --policy-name DenyAll \
  --policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Deny",
      "Action":"*",
      "Resource":"*",
      "Condition":{
        "DateLessThan":{
          "aws:TokenIssueTime":"2024-01-15T00:00:00Z"
        }
      }
    }]
  }'
# Denies ALL calls from tokens issued before this time
# Future tokens still work (for legitimate tasks after relaunch)
```

**Investigation (next 30 minutes):**

```bash
# 3. Analyze what the external caller did:
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=compromised-role \
  --start-time "2024-01-15T00:00:00Z" | \
  jq '.Events[] | {time: .EventTime, event: .EventName, source: .SourceIPAddress}'

# 4. Find the ECS task that was compromised:
# GuardDuty finding includes instanceId
# Find task on that instance:
aws ecs list-tasks --cluster prod-cluster \
  --container-instance <container-instance-id>
```

**Root cause analysis:**

How did credentials leave the container? Two vectors:

1. **SSRF vulnerability in application:** attacker sent
   request to app, app forwarded to
   `169.254.170.2/v2/credentials/<task-id>` (ECS credential endpoint),
   returned credentials in response.
   *Fix:* IMDSv2 enforcement. Application-level SSRF filtering.
   Validate and block requests to 169.254.x.x.

2. **Malicious code in container (supply chain):**
   Compromised base image or dependency.
   *Fix:* ECR image scanning. Pin base image digest.
   SBOM for all images.

**Remediation:**

- Rotate any database passwords, API keys the compromised
  role could have accessed
- Rebuild and redeploy the compromised container from
  known-good image
- Add VPC endpoint for ECS credentials endpoint to restrict
  SSRF (credentials endpoint is not reachable via VPC endpoint,
  but application WAF rules can block internal IP requests)
- Deploy IMDSv2 enforcement at launch template level

*What separates good from great:* The immediate session
revocation via `TokenIssueTime` condition is the critical
operational knowledge - this is AWS's documented method
for revoking active role sessions. Identifying both SSRF
and supply chain as root cause vectors shows depth.
The preventive controls (IMDSv2, ECR scanning) close the gap.

---
