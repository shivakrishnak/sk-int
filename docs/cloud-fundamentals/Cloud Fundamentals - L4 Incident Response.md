---
layout: default
title: "Cloud Fundamentals - L4 Incident Response"
parent: "Cloud Fundamentals"
nav_order: 11
permalink: /cloud-fundamentals/l4-incident-response/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 23 | [Cloud Incident Response and Forensics](#cloud-incident-response-and-forensics) | ★★★ |

---

# Cloud Incident Response and Forensics

**Interview Weight:** ★★★ - Required at senior/staff level.
Incident response in the cloud differs fundamentally from
on-prem: ephemeral compute, immutable infrastructure,
and API-driven forensics require cloud-native IR procedures.

---

### 🎯 Model Answer

**30 seconds:**

> Cloud IR follows Detect, Contain, Investigate, Remediate.
> Cloud-specific: isolate via Security Groups (not unplugging).
> Preserve forensics: EBS snapshot, CloudTrail logs, VPC
> Flow Logs before terminating. Containment: detach IAM role,
> revoke active sessions (TokenIssueTime), isolate SG.
> Immutable infrastructure: terminate compromised instance,
> deploy from known-good image. Never just restart.

**3 minutes:**

> Cloud IR phases:
>
> Detect:
> - GuardDuty: ML-based threat detection (credential
>   exfiltration, crypto mining, C2 communications)
> - CloudWatch anomaly detection on API error rates
> - Security Hub aggregates findings from all tools
> - CloudTrail: all API calls (search for anomalous patterns)
>
> Contain:
> - Isolate Security Group: remove all inbound/outbound,
>   add only forensics analyst SG access
> - Revoke IAM session: deny all for tokens before a timestamp
> - Disable compromised IAM user (no delete - preserve audit)
> - Snapshot EBS volumes: forensic copy before shutdown
>
> Investigate:
> - Forensics instance: same AZ, attach snapshot as secondary
> - CloudTrail: what API calls did the compromised identity make?
> - VPC Flow Logs: what IPs did the instance communicate with?
>
> Remediate:
> - Terminate compromised instance (immutable infrastructure)
> - Rotate all credentials the compromised role could have accessed
> - Patch the vulnerability that allowed initial access
> - Deploy new instance from known-good image

**Blank Mind Recovery:**

**(1) IR phases:** "Detect (GuardDuty) -> Contain (isolate SG,
revoke IAM) -> Investigate (CloudTrail, Flow Logs, snapshot)
-> Remediate (terminate, redeploy, rotate)."

**(2) Key cloud difference:** "Don't reboot - snapshot.
Don't firewall at OS level - use SG isolation.
Don't fix in place - redeploy from clean image."

**(3) Forensic evidence:** "CloudTrail (API calls),
VPC Flow Logs (network), EBS snapshot (disk)."

---

### 📘 Concept Explanation

**Evidence Sources in Cloud IR:**

```
CLOUDTRAIL:
  Who: User/Role ARN, access key ID
  What: API action (RunInstances, GetSecretValue, etc)
  Where: Source IP address
  When: Timestamp (microsecond precision)
  Retention: 90 days in CloudTrail, archive to S3 longer
  Gap: no data payload. GetObject logged, not contents.
  Gap: data events (S3, Lambda) must be explicitly enabled.

VPC FLOW LOGS:
  Network-level: srcAddr, dstAddr, ports, bytes, ACCEPT/REJECT
  Gap: payload not captured (headers only)
  Gap: no application-level data

EBS SNAPSHOT:
  Full filesystem at point-in-time
  Attach to forensics instance: /var/log, bash_history, cron
  Must be created BEFORE terminating the instance

SSM SESSION MANAGER LOGS:
  Every command in SSM sessions -> S3 or CloudWatch Logs
  Gap: SSH sessions (not through SSM) not captured
```

**Isolation Without Termination:**

```
WRONG: Immediately terminate compromised instance
  Evidence lost (memory, process state)
  Cannot determine what data was exfiltrated

CORRECT ORDER:
  1. Snapshot all EBS volumes (preserve evidence)
  2. Apply isolation Security Group (no rules = no traffic)
  3. Revoke IAM sessions (TokenIssueTime condition)
  4. Investigate: attach snapshot to forensics EC2
  5. Terminate only after investigation complete

ISOLATION SG:
  Create new SG with zero rules (no inbound, no outbound)
  Apply to compromised ENI - replaces all existing SGs
  Instance quarantined but running
  SSM agent still accessible via VPC endpoint (if configured)
```

---

### 💻 Code Example

```python
import boto3
import json
from datetime import datetime, timezone

# AUTOMATED INCIDENT RESPONSE
# Lambda triggered by GuardDuty -> EventBridge

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    iam = boto3.client('iam')
    sns = boto3.client('sns')

    finding = event['detail']
    severity = finding['severity']

    if severity < 7.0:
        return  # Low severity: log only

    resource = finding.get('resource', {})
    instance_id = resource.get(
        'instanceDetails', {}
    ).get('instanceId')
    role_name = None

    if 'accessKeyDetails' in resource:
        access_key = resource['accessKeyDetails']['accessKeyId']
        response = iam.get_access_key_last_used(
            AccessKeyId=access_key
        )
        role_name = response['UserName']

    snapshots_created = []

    # STEP 1: Snapshot EBS volumes (before isolation)
    if instance_id:
        instance = ec2.describe_instances(
            InstanceIds=[instance_id]
        )['Reservations'][0]['Instances'][0]

        for mapping in instance.get('BlockDeviceMappings', []):
            volume_id = mapping['Ebs']['VolumeId']
            snap = ec2.create_snapshot(
                VolumeId=volume_id,
                Description=f"INCIDENT-FORENSICS-{instance_id}",
                TagSpecifications=[{
                    'ResourceType': 'snapshot',
                    'Tags': [{
                        'Key': 'Purpose',
                        'Value': 'ForensicCapture'
                    }]
                }]
            )
            snapshots_created.append(snap['SnapshotId'])

        # STEP 2: Create isolation SG (no rules)
        vpc_id = instance['NetworkInterfaces'][0]['VpcId']
        isolation_sg = ec2.create_security_group(
            GroupName=f"ISOLATION-{instance_id}",
            Description="Incident isolation - no traffic",
            VpcId=vpc_id
        )
        isolation_sg_id = isolation_sg['GroupId']
        # Note: default SG has no rules = no traffic

        # STEP 3: Apply isolation SG to all ENIs
        for eni in instance.get('NetworkInterfaces', []):
            ec2.modify_network_interface_attribute(
                NetworkInterfaceId=eni['NetworkInterfaceId'],
                Groups=[isolation_sg_id]
                # Replaces ALL security groups with isolation SG
            )

        ec2.create_tags(
            Resources=[instance_id],
            Tags=[
                {'Key': 'IncidentStatus', 'Value': 'ISOLATED'},
                {'Key': 'DoNotTerminate', 'Value': 'true'}
            ]
        )

    # STEP 4: Revoke IAM sessions
    if role_name:
        revoke_time = datetime.now(timezone.utc).strftime(
            '%Y-%m-%dT%H:%M:%SZ'
        )
        iam.put_role_policy(
            RoleName=role_name,
            PolicyName='IncidentRevoke-DO-NOT-DELETE',
            PolicyDocument=json.dumps({
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Deny",
                    "Action": "*",
                    "Resource": "*",
                    "Condition": {
                        "DateLessThan": {
                            "aws:TokenIssueTime": revoke_time
                        }
                    }
                    # Denies ALL calls from tokens issued before now
                    # Future tokens (new tasks) work normally
                }]
            })
        )

    # STEP 5: Notify IR team
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:IncidentAlerts',
        Message=json.dumps({
            'severity': severity,
            'instance_id': instance_id,
            'role_affected': role_name,
            'snapshots': snapshots_created,
            'actions_taken': [
                'ebs_snapshot', 'sg_isolation', 'iam_revoke'
            ],
            'next_steps': [
                'Attach snapshot to forensics instance',
                'Search CloudTrail for compromised role API calls',
                'Analyze VPC Flow Logs for C2 communication'
            ]
        }),
        Subject=f'Cloud Incident - Severity {severity}'
    )
    return {'statusCode': 200}
```

> **Code walkthrough:** The ordering is critical: EBS snapshots
> are taken BEFORE the isolation SG is applied. If you isolate
> first and the instance needs to be restarted for any reason,
> you may lose forensic evidence. The isolation SG is created
> with no rules - no inbound, no outbound, completely dark.
> `modify_network_interface_attribute` replaces ALL security
> groups on the ENI with just the isolation SG: no matter how
> many SGs were applied before, the instance is now in a
> quarantine group. The IAM revocation uses the `aws:TokenIssueTime`
> condition: all active STS tokens issued before `revoke_time`
> are denied on their next API call. New tokens issued after
> redeployment will work normally - this is the correct pattern
> for revoking compromised role sessions without blocking
> future legitimate use.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Cloud incident response follows Detect, Contain,
> Investigate, Remediate. Detection comes from GuardDuty.
> Containment means isolating the instance by changing its
> Security Group to block all traffic, and revoking the IAM
> role's active sessions. Before terminating anything: take
> EBS snapshots for forensic investigation. After investigation:
> terminate and redeploy from a clean image - never try to
> clean a compromised instance in place."

---

**Senior / Staff:**

> "Cloud IR has one fundamental difference from on-prem:
> everything is API-driven and ephemeral. Forensic evidence
> lives in CloudTrail (API calls), VPC Flow Logs (network),
> and EBS snapshots (disk). The correct containment sequence:
> snapshot first, then isolate SG, then revoke IAM sessions.
> The IAM session revocation using TokenIssueTime is the most
> effective tool: it invalidates ALL active sessions while
> allowing new sessions for legitimate workloads redeployed
> after the incident. The root cause for credential exfiltration
> is almost always SSRF (in-app) or supply chain (compromised
> image). SSRF is blocked by IMDSv2 enforcement. Supply chain
> by image digest pinning and ECR scanning. Neither requires
> complex fixes - the architectural decisions matter more than
> the IR response speed."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Terminate the compromised instance
immediately."**

Immediate termination destroys forensic evidence (memory,
process state, disk artifacts). The correct sequence:
snapshot EBS, isolate via SG, then investigate. Terminate
only after evidence is preserved. Exception: active
ransomware encrypting data where every second increases
damage scope.

**Misconception 2: "GuardDuty prevents incidents."**

GuardDuty detects threats. It does not prevent them.
GuardDuty is a detection control, not a prevention control.
A GuardDuty finding means an incident is likely already
in progress. The prevention controls are Security Groups,
IAM least privilege, WAF, and application-level defenses.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: CloudTrail data events not enabled**

*Symptom:* Post-incident investigation cannot determine
which S3 objects were accessed. CloudTrail shows management
events only (bucket created/deleted) but not object-level
access (GetObject, PutObject).

*Prevention:*
```bash
aws cloudtrail put-event-selectors \
  --trail-name production-trail \
  --event-selectors '[{
    "ReadWriteType": "All",
    "IncludeManagementEvents": true,
    "DataResources": [{
      "Type": "AWS::S3::Object",
      "Values": ["arn:aws:s3:::sensitive-bucket/"]
    }]
  }]'
# Cost: ~$0.10 per 100,000 events - budget accordingly
```

---

**Failure 2: Automated response creates false-positive outage**

*Symptom:* GuardDuty false positive triggers automated
isolation of a production RDS instance. Database isolated,
app is down.

*Prevention:* Never auto-isolate databases or managed services.
Automate only for: EC2 instances, ECS tasks (compute tier).
Require human confirmation for: RDS, ElastiCache, DynamoDB.
Add an exclusion list to automated response Lambda:
check resource type before executing containment.

---

### ⚖️ Comparison Table

| IR Phase | Tool | Data Provided | Gap |
|----------|------|--------------|-----|
| Detection | GuardDuty | Threat finding + context | ML false positives |
| API forensics | CloudTrail | API calls, who/what/where | No data payload |
| Network forensics | VPC Flow Logs | Headers, src/dst/bytes | No payload content |
| Disk forensics | EBS Snapshot | Full filesystem | Static point-in-time |
| App forensics | CloudWatch Logs | Application events | Retention must be set |
| Session audit | SSM Session Mgr | All commands | SSM-only sessions |

---

### 🏛️ System Design

**Automated Cloud IR Pipeline:**

```
DETECTION TIER:
  GuardDuty (all accounts) -> Security Account (delegated admin)
  CloudTrail -> CloudWatch Logs -> metric filters
  Security Hub aggregates GuardDuty, Config, Inspector, Macie

EVENT ROUTING (Security Account EventBridge):
  Severity >= 7.0: Containment Lambda (auto-respond)
  Severity 4-7: Alert Lambda (notify + ticket only)
  Severity < 4: CloudWatch Logs (audit only)

CONTAINMENT LAMBDA (< 60 seconds from detection):
  Cross-account assume role in target account
  Snapshot EBS -> Apply isolation SG -> Revoke IAM sessions
  Never auto-isolate: RDS, ElastiCache, DynamoDB

FORENSICS ACCOUNT (separate AWS account):
  Snapshot shared to Forensics Account
  Auto-launch forensics EC2 with analysis tools
  Attacker in prod account cannot interfere

REMEDIATION:
  After investigation: terminate instance, rotate credentials
  Patch vulnerability, deploy from clean AMI
  Update GuardDuty/WAF rules with new IOCs
  Post-incident review -> preventive controls update
```

```mermaid
flowchart TB
    GD[GuardDuty\nAll Accounts] -->|aggregated| SA[Security Account]
    SA -->|HIGH severity| EB[EventBridge Rule]
    EB --> L1[Lambda\nEnrichment]
    L1 --> L2[Lambda\nContainment]
    L2 --> SNAP[EBS Snapshot]
    L2 --> ISO[Isolation SG]
    L2 --> IAM[Revoke IAM]
    L2 --> SNS[SNS Alert\n+ Jira Ticket]
    SNAP -->|cross-account| FA[Forensics Account\nForensics EC2]
```

> **Diagram walkthrough:** GuardDuty findings from all
> 20 accounts aggregate to the Security Account's delegated
> administrator. High-severity findings trigger a two-Lambda
> pipeline: enrichment (which team, production vs dev,
> data sensitivity) then containment. The containment Lambda
> uses cross-account IAM roles to act in the target account.
> Forensic snapshots are shared to the separate Forensics
> Account - isolated from production so the attacker cannot
> interfere with the investigation. The SNS notification
> creates both a human alert and a Jira P1 ticket with the
> runbook steps.

---

### 🎯 Interview Deep-Dive

> **Timing:** 5-7 minutes per question. Full structured answers.

| Type | Questions |
|------|-----------|
| CONCEPT | 2 |
| DEBUGGING | 2 |
| TRADE-OFF | 2 |
| DESIGN | 2 |
| BEHAVIORAL | 2 |
| SCENARIO | 2 |

---

#### CONCEPT 1: What evidence sources exist in cloud IR and what are their limitations?

**CloudTrail:** Every AWS API call: identity ARN, source IP,
action, resource, timestamp. Available 90 days via console,
indefinite via S3. Limitation: no data payload (GetObject
logged, not contents). Data events (S3, Lambda) must be
explicitly enabled - not on by default. 15-minute delivery
delay to CloudWatch Logs. Cost: data events generate high
volume, budget accordingly.

**VPC Flow Logs:** Network connection metadata: src/dst IP,
port, protocol, bytes, ACCEPT/REJECT. Limitation: no packet
payload. Does not capture inter-container traffic within
a task. Logging interval default 10 minutes (reducible to
1 minute). Does not show what data was transferred.

**CloudWatch Logs:** Application-level events. Quality depends
on what the application logs. Limitation: retention must
be configured (not infinite by default). Not guaranteed
to capture security-relevant events unless developers
instrument for them.

**EBS Snapshot:** Full disk state: filesystem, logs,
bash history, cron, SSH keys. Limitation: point-in-time.
Does not capture process memory or active network state.
Must be created before instance termination.

**SSM Session Manager Logs:** Every command in SSM sessions.
Limitation: only captures SSM sessions - SSH access is
not logged.

*What separates good from great:* CloudTrail's data events
being opt-in (and the cost implication) is the key
operational detail most candidates miss. Knowing what
evidence is available BEFORE an incident (S3 lifecycle
retention, VPC Flow Logs enabled) is the difference
between effective and ineffective investigation.

---

#### CONCEPT 2: What is MTTD vs MTTR and how does cloud architecture affect both?

**MTTD - Mean Time To Detect:** Average time from incident
start to detection. GuardDuty detection: minutes for known
patterns, hours for novel. VPC Flow Log aggregation adds
1-10 minutes. Shorter MTTD = less attacker dwell time.

**MTTR - Mean Time To Respond/Recover:**
- MTTR-Contain: detection to attacker stopped
- MTTR-Recover: containment to service restored

**Cloud architecture reduces MTTR-Recover dramatically:**

Immutable infrastructure + AMIs: terminate compromised
instance, launch replacement from clean AMI = 5 minutes.
Traditional server: manual OS cleaning = 4-8 hours.

Stateless application tier: instance replacement is safe
(no state lost). Data on managed services (RDS, S3).
If instance is stateful: replacement requires data migration.

Automation: pre-configured runbooks, pre-tested AMIs,
Infrastructure as Code for redeployment. Manual steps
during incident under pressure = slow and error-prone.

**The compounding relationship:**

MTTD 2 hours * data exfiltration rate 100 GB/hr = 200 GB at risk.
MTTD 5 minutes: 8 GB at risk. Same attacker, same rate.
Improving MTTD from 2 hours to 5 minutes: 96% damage reduction.

*What separates good from great:* Connecting stateless
architecture as both an HA and IR benefit shows systems
thinking. The MTTD damage calculation makes the business
case for investing in detection speed.

---

#### DEBUGGING 1: GuardDuty triggers "Recon:EC2/PortProbeUnprotectedPort." How do you triage and respond?

**Step 1: Retrieve finding details:**
```bash
aws guardduty get-findings \
  --detector-id <id> --finding-ids <id> \
  --query 'Findings[].{
    Severity:Severity,
    Port:Service.Action.NetworkConnectionAction.LocalPortDetails.Port,
    RemoteIP:Service.Action.NetworkConnectionAction.RemoteIpDetails.IpAddressV4
  }'
```

**Step 2: Understand the finding:** GuardDuty detected an
EC2 instance has an open port reachable from the internet
AND it was probed from a known-bad IP. Severity: LOW.
Port scanning is common internet noise. Does NOT mean
compromise.

**Step 3: Check the Security Group:**
```bash
aws ec2 describe-instances \
  --instance-ids <id> \
  --query 'Reservations[].Instances[].SecurityGroups'
# Find which SG allows the probed port from 0.0.0.0/0
```

**Triage decision:**
- Port 80/443 on public web tier: expected. Confirm WAF in front.
- Port 8080 (admin UI) exposed publicly: remove SG rule immediately.
  Check access logs for successful external auth attempts.
- Port 22 (SSH): never public. Remove and enable SSM Session Manager.

**Response for unintentional exposure:**
Remove SG rule. Check CloudTrail and application logs for
successful access from external IPs. If no successful access:
remediate SG, document, add Config rule for continuous monitoring.

*What separates good from great:* Treating PortProbe as
LOW severity informational rather than a confirmed breach
shows calibrated judgment. The important investigation is
whether any request on that port SUCCEEDED before detection.

---

#### DEBUGGING 2: CloudTrail shows API calls from an IAM role at 3 AM. No deployment or job is scheduled. How do you triage?

**Step 1: Retrieve the events:**
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=role-name \
  --start-time "2024-01-15T03:00:00Z" \
  --end-time "2024-01-15T04:00:00Z" | \
jq '.Events[] | {
  time: .EventTime,
  event: .EventName,
  source_ip: .SourceIPAddress,
  user_agent: (.CloudTrailEvent | fromjson | .userAgent),
  region: (.CloudTrailEvent | fromjson | .awsRegion)
}'
```

**Step 2: Analyze source IP and user agent:**

Legitimate automated process:
- Source IP: VPC NAT Gateway IP (internal)
- User agent: `boto3/1.x` or `aws-sdk-java/2.x`
- Region: matches deployment region
- Actions: normal CRUD for the service

Suspicious indicators:
- Source IP: external/residential IP
- User agent: `python-requests/2.x` (custom script, not SDK)
- Region: unexpected (us-west-2 from a us-east-1 service)
- Actions: enumeration (ListBuckets, ListRoles, DescribeInstances)

**Step 3: Baseline comparison:**
```bash
# Is 3 AM normal for this role?
aws logs insights query \
  --log-group-name CloudTrail/API \
  --query-string '
    fields @timestamp, eventName, sourceIPAddress
    | filter userIdentity.arn like /role-name/
    | stats count(*) by bin(1h)
  '
# Compare the 3 AM spike to typical hours
```

*What separates good from great:* User agent analysis is
an underused signal. Legitimate AWS SDKs report standard
user agent strings. Generic HTTP clients suggest a custom
or attacker tool. The baseline comparison (is 3 AM normal
for this role?) is the key question: a scheduled backup
job always runs at 3 AM and is legitimate.

---

#### TRADE-OFF 1: What are the risks of over-automating incident response?

**Case for automation:** MTTD-to-containment in seconds
vs human response in 15+ minutes. GuardDuty + Lambda +
EventBridge achieves automated containment before most
humans are even notified.

**Risk 1: False positive induced outage.** GuardDuty false
positive triggers automated isolation of a production
database. Database down, customers cannot transact.
Automation-induced outage worse than the false threat.

*Mitigation:* Never automate isolation for databases,
caches, managed services. Automate only for compute (EC2,
ECS tasks). Require human approval for critical resources.

**Risk 2: Attacker-induced DoS.** Sophisticated attacker
deliberately triggers GuardDuty findings on critical
instances. Automation isolates them. Automation becomes
the attack vector for availability attacks.

*Mitigation:* Rate limit automated responses. Alert on
high-volume automation activity itself as anomaly.

**Risk 3: Novel attack evasion.** GuardDuty targets known
patterns. Novel techniques evade detection. Over-reliance
on automated IR creates false confidence that unknown
attacks will also be detected and contained.

**Recommended balance:**
- Automate: evidence preservation (snapshots), session
  revocation, dev/staging isolation, notifications
- Human-in-loop: production isolation, database actions,
  account-level changes
- Review: all automated actions auditable with manual override

*What separates good from great:* The false-positive-induced
outage scenario shows systems thinking: optimizing one
metric (IR speed) can degrade another (availability).
The attacker-induced DoS angle shows adversarial thinking.

---

#### TRADE-OFF 2: Forensics account vs in-place investigation.

**In-place (within production account):**
- Faster setup: no snapshot sharing required
- Risk: if attacker still has CloudTrail access, they see
  investigator activity and can cover tracks
- Risk: investigator blast radius shares account with
  compromised resources (an error affects production)
- Risk: attacker may modify logs during investigation

**Forensics account (separate AWS account):**
- Snapshot shared cross-account: EC2 has no production access
- Attacker in prod cannot see or interfere with forensics account
  (separate account = separate IAM trust boundary)
- Investigator mistakes cannot affect production
- Requires: pre-configured account, pre-provisioned
  cross-account sharing permissions, forensic tools deployed

**Cost:** Snapshot sharing adds 5-10 minutes setup time.
Requires pre-provisioned account (not ad-hoc during incident).

**Recommendation:**
- Regulated environments (financial, healthcare): forensics
  account required (audit evidence: separation of investigation
  environment from compromised environment)
- Smaller orgs: forensics-in-place with dedicated read-only
  forensics IAM role, monitored via separate CloudTrail filter

*What separates good from great:* "Attacker can see
investigation activity" angle shows understanding that
the attacker may retain access during IR. Pre-provisioning
as a prerequisite (not set up during incident) reflects
operational experience.

---

#### DESIGN 1: Design a GuardDuty + automated response pipeline for a 20-account AWS Organization.

**Architecture layers:**

Detection: GuardDuty in all accounts, delegated admin =
Security Account. Single pane of glass: all findings
aggregated to Security Account console.

Event routing (Security Account EventBridge):
- Severity >= 7: Containment Lambda
- Severity 4-7: Alert Lambda (notify + ticket)
- Severity < 4: CloudWatch Logs (audit)

Enrichment Lambda: look up resource owner via tagging
convention, determine prod vs dev, data sensitivity tier.

Containment Lambda (cross-account): assume role in target
account, execute: snapshot + isolation SG + IAM revocation.
Never auto-contain: RDS, ElastiCache, DynamoDB (require
human approval).

Forensics: share snapshot to Forensics Account.
Auto-launch EC2 with forensic tools. IR team notified
with workspace URL.

Audit: all automated actions in CloudTrail (Security Account).
Weekly MTTD/MTTR metrics report. Monthly false positive rate review.

*What separates good from great:* Organization-level
GuardDuty delegation is the correct AWS multi-account pattern.
The never-auto-contain list for databases shows operational
maturity. Pre-launched forensics workspace reduces MTTR-Investigate.

---

#### DESIGN 2: How would you implement cloud security posture management for a multi-account AWS Organization?

**CSPM definition:** Continuous visibility into misconfigurations,
policy violations, and compliance gaps.

**AWS-native CSPM stack:**

AWS Config (per account, aggregated): 130+ managed rules
(encrypted EBS, MFA enabled, S3 bucket policies, open SG ports).
Custom Lambda rules for org-specific checks.
Config aggregator in Security Account: single compliance view.

Security Hub (per account, aggregated): enables AWS FSBP
(Foundational Security Best Practices), CIS Foundations,
PCI DSS (if applicable). Score: 0-100% compliance posture.
Aggregates Config + GuardDuty + Inspector + Macie findings.

Inspector v2: continuous CVE scanning for EC2 + ECR + Lambda.
Aggregates to Security Hub.

Macie: PII detection in S3. Alerts on unencrypted sensitive data.

Alert-to-remediation pipeline:
Config violation -> Security Hub -> EventBridge -> Lambda
remediation (auto-fix for simple cases) or SNS + Jira.

Preventive controls (not just detective):
- SCPs in Organizations: prevent violations before they occur
- CloudFormation Guard: validate IaC templates pre-deploy
- Checkov: scan Terraform before `terraform apply`

Prevention is more powerful than detection + remediation.

*What separates good from great:* The preventive controls
(SCP, IaC scanning) distinguish mature architecture.
CSPM that only detects violations is reactive. Blocking
violations at the IaC layer is a fundamentally superior
security posture.

---

#### BEHAVIORAL 1: Describe a time you responded to a cloud security incident.

**STAR format:**

**Situation:** GuardDuty alert at 2 AM: "UnauthorizedAccess:
IAMUser/TorIPCaller" - IAM credentials used from a Tor exit node.

**Task:** Contain, determine impact, prevent recurrence.

**Action:** Immediately disabled the IAM access key
(not deleted - preserve audit trail). CloudTrail review:
credentials used for 3 hours before detection.
Actions included ListBuckets, GetObject on customer data
bucket (PII), and DescribeDBInstances.

Snapshotted associated EC2 instance EBS volumes. Isolated
via isolation Security Group. Escalated to CISO and legal
(PII accessed = potential breach notification requirement).

Root cause: access key was in a public GitHub repository -
committed by a developer 6 months earlier. GitHub secret
scanning flagged it but the alert email went to an
unmonitored alias.

**Result:** Contained in 20 minutes. 15 customer PII records
accessed (determined from CloudTrail GetObject calls).
Breach notification filed. Remediation: GitHub Advanced Security
enabled for all repos, pre-commit hooks for credential detection,
SCP added to deny IAM user creation (force SSO only), ALL
long-term credentials rotated, migration to IRSA started.

*What separates good from great:* The root cause remediation
(SCP denying IAM user creation) addresses the class of
vulnerability. Migration to task roles eliminates the
credential exfiltration attack surface entirely.

---

#### BEHAVIORAL 2: How do you balance thorough investigation with the need to restore services quickly?

**The tension:** Thorough investigation preserves compromised
instance (process memory, network state, disk context).
Service restoration requires cleaning or replacing the instance.

**Resolution via immutable infrastructure:**

Cloud's snapshot + redeploy pattern resolves most of this:
- Snapshot EBS volume: ~30 seconds
- Redeploy from clean AMI: ~5 minutes
- Service restored. Forensic evidence preserved in snapshot
  for asynchronous investigation (no time pressure).

**Specific example:** Payment processing service compromised.
Business required sub-15-minute recovery. Actions:
1. Snapshot EBS volumes (< 1 minute)
2. Launch replacement from last known-good AMI
3. Reattach data volumes (stateless app tier - no state lost)
4. Service restored in 7 minutes

Parallel: forensics team mounted the snapshot in forensics
account. Investigation took 4 hours - found the vector
without any pressure to rush.

**Enabling condition:** All application tiers were stateless
(data on RDS and S3, not on EC2 instance). Instance
replacement was safe without data loss.

Statelessness is both an HA and a security architectural decision.

*What separates good from great:* Pre-incident architectural
decisions (stateless tiers) enabling fast IR is the key insight.
The snapshot-then-redeploy pattern is the operational answer.
Together they show an engineer who designs for failure proactively.

---

#### SCENARIO 1: GuardDuty triggers "InstanceCredentialExfiltration.OutsideAWS" - an ECS task's credentials used from external IP. What do you do?

**Immediate containment (first 5 minutes):**

```bash
# 1. Identify the role from the GuardDuty finding
# 2. Revoke all active sessions:
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
# Denies all calls from tokens issued before this time
# New deployments get new tokens: work normally
```

**Investigation (next 30 minutes):**
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=role \
  --start-time "2024-01-14T00:00:00Z" | \
jq '.Events[] | {time: .EventTime, event: .EventName, ip: .SourceIPAddress}'
# What did the attacker do with the credentials?
```

**Root cause - two vectors:**

1. SSRF in application: attacker sent request to app,
   app forwarded to `169.254.170.2/v2/credentials/`
   (ECS credential endpoint), credentials returned.
   Fix: enforce IMDSv2 (requires PUT token, SSRF GET fails).
   Block requests to 169.254.x.x at application WAF layer.

2. Malicious container (supply chain): compromised base
   image or dependency exfiltrated credentials.
   Fix: ECR image scanning, pin base image digest,
   SBOM for all images.

**Remediation:** Rotate all credentials the role could
access. Rebuild/redeploy container from known-good image.
Deploy IMDSv2 enforcement at launch template level.

*What separates good from great:* The `TokenIssueTime`
revocation pattern is the AWS-documented method for revoking
active role sessions. Identifying both SSRF and supply chain
as root cause vectors shows operational depth.

---

#### SCENARIO 2: Former employee's AWS credentials may be leaked. They left 3 months ago. What do you do?

**Step 1: Immediate credential revocation:**
```bash
# Find all credentials:
aws iam list-access-keys --user-name former-employee
# Deactivate (not delete - preserve audit trail):
aws iam update-access-key \
  --user-name former-employee \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --status Inactive
# Check/remove console access:
aws iam delete-login-profile --user-name former-employee
```

**Step 2: 3-month CloudTrail lookback:**
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,Value=former-employee \
  --start-time "3 months ago" \
  --end-time "now"
# Identify: any external IPs? Any bulk data access?
# Any DescribeInstances / ListBuckets (enumeration)?
```

**Step 3: Scope the "leaked" scenario:**
If credentials were in a public GitHub repo:
- GitHub API shows when file was committed
- Cross-reference with CloudTrail for access from non-corporate
  IPs AFTER that commit date
- Any GetObject / S3 sync patterns suggest data exfiltration

**Step 4: Impact assessment:**
What permissions did this user have?
What data was accessible? (review IAM policies)
Cross-reference with breach notification requirements (PII?).

**Step 5: Process fix:**
Root cause: why were credentials still active 3 months after departure?
Offboarding process failure.

Remediation: automated offboarding checklist enforced via
ITSM integration. IAM user deactivation on last day of
employment. SCP: deny IAM user creation organization-wide
(force SSO, no static credentials). Regular access review
for service accounts.

*What separates good from great:* Deactivate vs delete
(preserve audit trail) is the correct operational choice.
The 3-month CloudTrail investigation is thorough. The process
fix (automated offboarding, SCP denying IAM users) addresses
the root cause: process gap, not just the individual incident.

---
