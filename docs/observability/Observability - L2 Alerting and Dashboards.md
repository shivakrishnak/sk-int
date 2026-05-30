---
layout: default
title: "Observability - L2 Alerting and Dashboards"
parent: "Observability"
nav_order: 7
permalink: /observability/l2-alerting-and-dashboards/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Alert Design and Routing](#alert-design-and-routing) | critical |
| 2   | [Log Querying and Analysis](#log-querying-and-analysis) | high |

---

# Alert Design and Routing

**TL;DR** - Good alerts fire when users are impacted and require
human action. Bad alerts fire on internal thresholds that have
no SLO basis. The SLO-based burn rate model and AlertManager
routing separate signal from noise.

---

### 🎯 Model Answer

**30 seconds:**
> A good alert fires when users are experiencing an impact, not
> when an internal metric crosses an arbitrary threshold. The
> standard for SLO-based alerting is burn rate: if error budget
> is being consumed 14x faster than normal, page someone immediately.
> AlertManager handles routing: which alert goes to which on-call
> team via PagerDuty, Slack, or email, with deduplication and
> grouping to prevent alert storms.

**3 minutes (Senior):**
> Alert design has two failure modes. Too many alerts (alert
> fatigue): every threshold breach pages someone, most are false
> positives, on-call engineers start ignoring pages. Too few alerts
> (silent failures): the system is broken but no alert fired because
> the threshold was wrong. The solution is symptom-based alerting:
> alert on user-visible symptoms (error rate, latency above SLO)
> not on causes (high CPU, full connection pool). The SLO burn rate
> model is the production-grade approach: instead of "alert if
> error rate > 1%," alert if the 30-day error budget is being
> consumed at a rate that will exhaust it in less than X hours.
> A 14x burn rate over 1 hour consumes 14 hours of budget in
> 1 hour - page immediately. A 2x burn rate means budget is
> exhausted in 15 days instead of 30 - send a ticket but don't
> page. AlertManager routing: alerts carry labels (severity,
> team, service). Routes match labels and forward to the right
> receiver. Critical severity for checkout goes to the checkout
> team PagerDuty. Warning severity for any service goes to
> Slack. All unmatched alerts go to a catch-all Slack channel.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers design the organizational alerting
philosophy: who is in scope, what constitutes a page-worthy
event, how the error budget is governed, and how alert fatigue
is measured and reduced.

*Adapting down:* "An alert is a notification that something needs
human attention. Good alerts page you when users are affected.
Bad alerts page you for things that fix themselves or that do
not require action."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about alert design and routing -
let me walk through how to design effective alerts and how
AlertManager routes them."

**(2) First principles:** "From first principles, an alert should
answer two questions: is this impacting users? and is this
something only a human can fix? If both are yes, page. Otherwise,
do not."

**(3) Bridge:** "Think of fire alarms: a good fire alarm fires for
actual fires (symptoms). A bad fire alarm fires for burnt toast
(causes). The alarm should detect the danger, not the cause."

---

### 📘 Concept Explanation

**What it is:**
Alert design is the practice of defining alerting rules that
fire when user impact occurs and route to the appropriate team
with sufficient context to act. AlertManager is the Prometheus-
native routing layer that deduplicates, groups, and routes alerts.

**The problem it solves:**
Naive threshold-based alerts (CPU > 80%, memory > 70%) fire
constantly for conditions that do not impact users and do not
require action. On-call engineers become desensitized to alerts.
When a critical alert fires, it is buried in noise. Alert
design disciplines ensure every page requires and enables action.

**How it works:**
Alert evaluation pipeline:

```
[Prometheus AlertRule]
  - PromQL expression evaluated every 1 minute
  - for: 5m - must be true for 5 min before firing
  - labels: severity, team, service
  - annotations: summary, description, runbook_url
      |
  Expression evaluates non-empty for 5 min -> FIRING
      |
[AlertManager]
  - Receives alert from Prometheus
  - Deduplication: same alert twice = one notification
  - Grouping: 10 alerts for same service = one page
  - Inhibition: DB down = suppress dependent app alerts
  - Route matching: severity=critical + team=checkout
                 -> checkout PagerDuty
      |
[Receiver]
  PagerDuty, Slack, Email, OpsGenie
```

> **Diagram walkthrough:** Prometheus evaluates alert rules and
> sends fired alerts to AlertManager. AlertManager applies routing
> rules before notifying any human. Deduplication and grouping
> prevent alert storms. Inhibition prevents dependent service
> alerts from firing when the root cause (e.g., database down)
> is already paging.

**The SLO burn rate model:**
Instead of threshold-based alerts, use burn rate:

```
Error budget: 0.1% errors allowed in 30 days
Normal burn rate: 1.0 (budget depletes in 30 days)
Alert threshold: 14x burn rate = budget in ~2 days

Burn rate = observed_error_rate / error_budget_rate
         = observed_error_rate / (1 - SLO_target)

For 99.9% SLO: error_budget_rate = 0.001
If current error_rate = 0.014 (1.4%):
  burn_rate = 0.014 / 0.001 = 14x -> PAGE
```

Multi-window alerting (production standard):
- Fast alert: 14x burn rate over 1 hour (catches fast burns)
- Slow alert: 5x burn rate over 6 hours (catches slow burns)
Both must be true to reduce false positives.

**The key insight:**
Every alert must have a runbook. If you cannot write what the
on-call engineer should DO when this alert fires, you should
not have the alert. Untriageable alerts become noise.

**When to use it:**
SLO-based burn rate alerts for user-facing SLOs. Cause-based
alerts (CPU, memory) for infrastructure capacity planning, not
for paging.

**When NOT to use it:**
Do not create alerts for metrics you cannot act on. Do not
alert on conditions that always resolve without intervention.
Do not duplicate Kubernetes health alerts (pod restarts, OOM)
with application-level alerts for the same condition.

**Alternatives:**
- Synthetic monitoring alerts: run test transactions every
  minute and alert if they fail. Tests end-to-end user journey;
  independent of internal metrics.
- Anomaly detection: alert on deviation from baseline rather
  than fixed threshold. Useful for seasonal traffic patterns.

**First-principles derivation:**
An alert is a human notification that requires action. The cost
of an alert is: engineer wakeup (if night), context switch,
investigation time. The cost of a missed alert is: user impact
duration * user impact scope. Effective alerts minimize both
costs: fire only when action is required (minimizes false wake-
ups) and fire before impact becomes severe (minimizes miss cost).
The burn rate model calibrates this: it fires when budget depletion
is on track to cause SLO breach, early enough to act.

---

### 💻 Code Example

**Example 1: BAD - Cause-based threshold alerts**

```yaml
# BAD: Cause-based alerts with no SLO basis
# These are the classic alert fatigue generators
groups:
  - name: checkout.bad.alerts
    rules:
      # Fires whenever CPU spikes, even briefly
      # High CPU does not mean users are impacted
      - alert: HighCPU
        expr: cpu_usage_percent > 80
        for: 1m
        labels:
          severity: critical  # Pages someone
        annotations:
          summary: "CPU above 80%"
          # No runbook, no context, no action

      # Memory alerts fire during GC frequently
      # GC is normal - this just creates noise
      - alert: HighMemory
        expr: jvm_memory_used > 1073741824  # 1GB
        for: 1m
        labels:
          severity: critical

      # 5xx alerts miss the RATE - one 500 = page
      # but also misses slow 200 responses (SLO breach)
      - alert: Any500Error
        expr: rate(http_requests_total{status="500"}[1m]) > 0
        for: 0s  # Fires immediately!
        labels:
          severity: critical
```

> **Code walkthrough:** The BAD alerts are classic alert anti-
> patterns. The CPU alert fires for brief spikes that are not
> user-impacting (most services handle 80% CPU without user
> visible degradation). The memory alert fires during normal JVM
> GC cycles. The 500 error alert fires on even a single 5xx
> response with no `for` duration, so a single transient error
> pages the on-call engineer. These alerts create alert fatigue
> without providing actionable signal.

**Example 2: GOOD - SLO burn rate alerts with AlertManager routing**

```yaml
# GOOD: SLO-based burn rate alerts + AlertManager routing
# Prometheus alert rules
groups:
  - name: checkout.slo
    rules:
      # Burn rate: fast window (1h) - catches acute failures
      - alert: CheckoutSLOBurnRateFast
        expr: |
          (
            sum(rate(checkout_requests_total{
              status="error"}[1h]))
            / sum(rate(checkout_requests_total[1h]))
          ) / 0.001 > 14
        for: 2m  # Sustained 2 minutes to reduce flapping
        labels:
          severity: critical
          team: checkout
          service: checkout
          slo: checkout_availability
        annotations:
          summary: >-
            Checkout error budget burning at
            {{ $value | humanize }}x - PAGE
          description: >-
            Error rate is consuming 30d error budget
            at {{ $value }}x normal rate.
            Budget exhaustion in ~2 hours at this rate.
          runbook_url: >-
            https://runbooks/checkout-slo-burn

      # Burn rate: slow window (6h) - catches slow burns
      - alert: CheckoutSLOBurnRateSlow
        expr: |
          (
            sum(rate(checkout_requests_total{
              status="error"}[6h]))
            / sum(rate(checkout_requests_total[6h]))
          ) / 0.001 > 5
        for: 10m
        labels:
          severity: warning
          team: checkout
          service: checkout
        annotations:
          summary: >-
            Checkout error budget burning at
            {{ $value | humanize }}x - ticket
          runbook_url: >-
            https://runbooks/checkout-slo-burn

# AlertManager routing configuration
route:
  receiver: default-slack
  group_by: [alertname, service]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    # Critical severity -> PagerDuty for the relevant team
    - match:
        severity: critical
        team: checkout
      receiver: checkout-pagerduty
      # Don't group critical alerts - each is a page
      group_wait: 0s

    # Warning severity -> Slack
    - match:
        severity: warning
      receiver: ops-slack

    # Database alerts -> suppress dependent app alerts
    - match:
        service: database
      receiver: database-pagerduty

# Inhibit app alerts when database is down
inhibit_rules:
  - source_match:
      alertname: DatabaseDown
    target_match:
      team: checkout
    equal: [environment]
```

> **Code walkthrough:** The GOOD alert uses SLO burn rate instead
> of raw error rate. The 14x burn rate threshold means the error
> budget (0.1% errors/30 days) is being consumed fast enough to
> exhaust in about 2 hours. The `for: 2m` prevents flapping
> from brief spikes. The annotation includes a burn rate value
> in the summary (using `$value`), so the on-call engineer sees
> the rate immediately in the PagerDuty notification. The runbook
> URL is mandatory. The AlertManager routing sends critical alerts
> directly to PagerDuty (no grouping delay) and warning alerts
> to Slack. The inhibition rule suppresses checkout alerts when
> a database-down alert fires - the root cause is database, not
> checkout.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Good alerts fire when users are impacted. SLO-based alerts use
> burn rate: if the error budget is being consumed too fast, page.
> Bad alerts fire on internal thresholds (CPU, memory) that may
> not correlate with user impact. AlertManager routes alerts:
> critical alerts go to PagerDuty (for the on-call team), warnings
> go to Slack, and inhibition rules prevent alert storms when a
> common root cause (database down) is already paging.

*Push deeper:* Describe the grouping feature: AlertManager
can group 10 alerts for the same service into one notification,
preventing a 10-service outage from sending 10 separate pages.

---

**Senior / Staff (5+ years):**
> Alert design is an organizational discipline, not just a
> configuration task. I measure alert quality with two metrics:
> alert precision (what fraction of alerts required action) and
> alert recall (what fraction of user-impacting events generated
> an alert). Both should be above 90%. Alert fatigue is measured
> by: how many alerts per week, how many were acted on, and
> on-call engineer survey. I run quarterly alert reviews where
> alerts with < 80% precision are removed or reclassified to
> warning. The SLO burn rate model is the best-practice framework
> because it is calibrated to actual user impact and provides
> a consistent standard across teams.

*Push deeper:* Describe the multi-window multi-burn-rate alerting
pattern (1h/6h windows) and why both windows are needed.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "More alerts = better coverage" | More alerts increase fatigue and reduce response quality. Alert on user-visible symptoms, not all possible causes |
| "A warning alert is harmless" | Warning alerts that cannot be acted on are noise. Every alert (even warning) must have a defined response action |
| "Alerting and dashboards serve the same purpose" | Alerts are for automatic system notification when action is needed. Dashboards are for human-initiated investigation. Never alert from a dashboard |
| "PagerDuty can handle any alert volume" | On-call engineers can handle 3-5 meaningful pages per week. 20+ pages per week is alert fatigue regardless of severity |

---

### ⚖️ Comparison Table

| Alert type | Trigger | Best for | Avoid |
|------------|---------|----------|-------|
| **Burn rate** | SLO budget depletion rate | User-facing services with SLOs | Services without defined SLOs |
| **Threshold** | Metric > fixed value | Absolute limits (disk 90% full) | Replacing SLO-based alerts |
| **Anomaly** | Deviation from baseline | Seasonal traffic patterns | Services with low traffic volume |
| **Synthetic** | Test transaction failure | End-to-end availability | Replacing internal signal |

**When to page vs ticket:**
Page (PagerDuty): burn rate > 14x (budget in < 2 hours), service
completely down. Ticket (Jira): burn rate 2-14x, non-critical
degradation. Inform (Slack): warning-level anomalies.

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Alert storm from single root cause**

Symptom: 30 alerts fire simultaneously during a database outage.
All 15 services that depend on the database are alerting. On-call
engineer receives 30 PagerDuty pages. Cannot determine root cause
from notification volume.

Root cause: No inhibition rules. All service alerts fire
independently when the shared database is down.

Diagnostic:
```bash
# Check AlertManager inhibition configuration
curl http://alertmanager:9093/api/v2/alerts | \
  jq '.[] | {alertname: .labels.alertname,
             inhibited: .status.inhibitedBy}'
# If inhibited is empty for dependent services
# during a DB outage, inhibition is not configured
```

Fix: Add inhibition rule: when DatabaseDown fires, inhibit
all alerts with `team != database` and `equal: [environment]`.

Prevention: Inhibition rules for all shared infrastructure
components as part of the alerting deployment playbook.

---

**Mode 2 - Alert fires but has no runbook**

Symptom: On-call engineer receives an alert for
`CheckoutCacheConnectionPoolSaturated`. There is no runbook.
Engineer spends 45 minutes figuring out what to do.

Root cause: Alert was added without a runbook URL. Engineer
has to investigate from first principles.

Fix: Add runbook_url annotation to all alerts. Alert rule
without runbook_url fails CI validation.

Prevention: CI check: any PrometheusRule CRD that does not
include `runbook_url` in annotations fails the build.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Explain symptom vs cause alerting |
| Design | 3 min | Design alerts for a checkout service |
| Architecture | 90 sec | AlertManager routing and inhibition |
| Debugging | 90 sec | Diagnose alert storm |
| Trade-off | 60 sec | SLO burn rate vs threshold alerts |
| Production | 2 min | Describe reducing alert fatigue |
| Behavioral | 2-3 min | STAR story of an on-call improvement initiative |
| Technical depth | 90 sec | Multi-window multi-burn-rate alerting |
| Scenario | 2 min | Configure AlertManager for 50 services |

---

**Q1 [MID] What is the difference between symptom-based and cause-based alerting?**

*Why they ask:* Core alerting philosophy question.

*Likely follow-up:* Give an example of each for a database connection pool.

Symptom-based alerting fires when users experience impact:
high error rate, latency above SLO, service unavailable.
These are observable from the user's perspective without
knowing the internal cause. Cause-based alerting fires when
an internal condition changes: high CPU, high memory, database
connection pool at 80%. These may or may not correlate with
user impact. The problem with cause-based alerts is that they
fire frequently for conditions that do not impact users (JVM
GC causes memory spikes; high CPU during batch processing
does not affect real-time requests). Alert fatigue results.
For a database connection pool: cause-based alert fires at
80% utilization, which happens routinely during peak traffic
without user impact. Symptom-based alert fires when error rate
increases or latency exceeds threshold - which is what actually
matters. The connection pool utilization is still useful as
a metric on a dashboard for capacity planning, but not as a
paging alert.

*What separates good from great:* Great candidates describe
the "1000 users on the database" analogy - high connection
pool utilization is a capacity concern but not an alert trigger
unless it correlates with latency or errors for users.

---

**Q2 [SENIOR] Explain multi-window multi-burn-rate alerting.**

*Why they ask:* Tests advanced SLO alerting knowledge.

*Likely follow-up:* Why is a single-window burn rate insufficient?

Multi-window multi-burn-rate alerting uses two time windows
and two burn rate thresholds to detect both fast and slow
error budget consumption. The problem with a single window:
a 1-hour window with a 14x burn rate threshold detects acute
failures (14% error rate for 1 hour) but misses slow burns
(2% error rate sustained over 6 hours). A 6-hour window
with a 5x burn rate threshold detects slow burns but is
slow to fire for acute failures (waits 6 hours of data).
The solution is both windows simultaneously: fire a critical
alert when burn rate > 14x over 1 hour (acute failure,
page immediately), and fire a warning alert when burn rate
> 5x over 6 hours (slow burn, create a ticket within 24 hours).
The implementation in Prometheus: two alert rules, one
using rate(...[1h]) and one using rate(...[6h]). The critical
alert has a short `for` (2 minutes) to catch acute failures
quickly. The warning alert has a longer `for` (10 minutes)
to avoid false positives from brief spikes. Together, they
cover 95% of error budget consumption scenarios.

*What separates good from great:* Great candidates describe the
missing 5%: a very slow burn at 1.5x that neither window catches.
This is addressed by a separate monthly budget check (alert if
remaining budget < 50% at the midpoint of the month).

---

**Q3 [SENIOR] How do you reduce alert fatigue in an on-call rotation?**

*Why they ask:* Tests operational excellence thinking.

*Likely follow-up:* How do you measure alert quality?

Alert fatigue is measured by two metrics: alert volume per
week per on-call engineer and alert precision (what fraction
required action). Both must be below a threshold. Target:
< 10 pages per week, > 90% precision. My process for reducing
fatigue: First, audit all alerts in the last 30 days. For each
alert that fired: did the on-call engineer take action? Was
the action meaningful? Alerts with < 50% action rate are
candidates for removal or reclassification to warning. Second,
convert all CPU/memory/disk alerts to capacity planning tickets
(not pages): these are operational concerns for the team, not
incidents requiring immediate response. Third, add inhibition
rules for all shared infrastructure: if the database is down,
suppress all dependent service alerts. Fourth, increase `for`
duration on noisy alerts: if an alert fires for 30 seconds and
resolves, the `for: 5m` prevents it from reaching PagerDuty.
Fifth, deduplicate related alerts: 10 pods restarting = 1 alert,
not 10. After implementing these changes, measure: alerts per
week should drop by 50-80%.

*What separates good from great:* Great candidates describe the
blameless alert post-mortem: after each on-call shift, review
which alerts were false positives and commit to fixing them
before the next shift.

---

**Q4 [JUNIOR] What is an AlertManager inhibition rule?**

*Why they ask:* Tests AlertManager advanced feature knowledge.

*Likely follow-up:* Why is inhibition different from silencing?

An AlertManager inhibition rule suppresses alerts when another
specific alert is firing. It is used to prevent alert storms
when a single root cause generates dependent failures across
multiple services. Example: if the `DatabaseDown` alert is
firing, inhibit all alerts with label `team != database` and
the same environment label. This means if the database goes
down and causes 15 services to report errors, only one alert
fires (DatabaseDown). The 15 service-level alerts are suppressed
because they are consequences of the root cause, not independent
problems. Inhibition is different from silencing: silencing
is manual, temporary suppression by an engineer (e.g., during
a maintenance window). Inhibition is automatic, condition-based
suppression that fires whenever the source alert is active.
Inhibition source alert must exactly match the source_match
labels. The equal field defines which label values must match
between the source and target alerts (e.g., both must have the
same `environment` value so staging inhibitions do not suppress
production alerts).

*What separates good from great:* Great candidates describe the
alert that inhibition should NOT suppress: the DatabaseDown
alert itself, and any infra-level alerts that may indicate the
root cause of the DatabaseDown.

---

**Q5 [MID] What should a good alert annotation include?**

*Why they ask:* Tests alert operational quality.

*Likely follow-up:* What is the minimum information needed to act on an alert?

A good alert annotation includes: summary (one-line description
of what is happening, including the current value), description
(2-3 sentences explaining the impact, what the engineer should
check first, and what normal behavior looks like), runbook_url
(link to the step-by-step runbook for this alert - mandatory),
and dashboard_url (link to the Grafana dashboard showing this
service's health). The summary should include the dynamic
current value: "Checkout SLO burning at 18x" (not just "SLO
alert"). The description should tell the engineer what to do:
"Checkout error rate is at {{ $value | humanize }}% (threshold:
0.1%). Start with the Grafana checkout dashboard, then check
error logs in Loki for the checkout service." Without the
runbook_url, an on-call engineer at 2am has to figure out
the response procedure from scratch - adding MTTR. An alert
without a runbook_url should not be deployed.

*What separates good from great:* Great candidates describe
using template syntax in alert annotations to include the
triggering service, current metric value, and relevant labels
from the alert.

---

**Q6 [SENIOR] How do you design AlertManager routing for 50 microservices?**

*Why they ask:* Tests AlertManager architecture at scale.

*Likely follow-up:* How do you handle a new team joining?

For 50 microservices with multiple teams, the routing hierarchy:
the root route sends all unmatched alerts to a catch-all Slack
channel (no paging). The first-level routes match by severity:
critical routes attempt team-based routing, warning routes to
team Slack channels, info routes to a low-priority channel.
For critical severity, second-level routes match by `team`
label: `team=checkout` routes to the checkout PagerDuty service,
`team=payment` routes to the payment PagerDuty service, and
so on. If no team label matches, critical alerts route to the
platform team (fallback). Each team maintains its own receiver
configuration (PagerDuty integration key, escalation policy)
but the routing topology is centrally managed. For a new team:
they provide a PagerDuty integration key and a Slack channel.
Platform adds their receiver and a routing rule matching
`team=their-team`. Teams label all their AlertRules with
`team=their-team` in the labels block.

*What separates good from great:* Great candidates describe
the self-service pattern: a GitOps workflow where teams submit
a PR to add their receiver to the AlertManager config, reviewed
by the platform team.

---

**Q7 [STAFF] How do you measure the effectiveness of your alerting system?**

*Why they ask:* Tests data-driven operations thinking.

*Likely follow-up:* What does a good on-call health score look like?

I measure alerting effectiveness with four metrics. First, alert
precision: (alerts that required action) / (total alerts). Target
> 90%. Low precision means too many false positives. Second, alert
recall: (user-impacting events that triggered an alert) / (total
user-impacting events). Target > 95%. Low recall means silent
failures. Third, time-to-alert: time between incident start and
first alert. Target < 5 minutes for critical SLO breaches. Fourth,
alert volume: pages per week per on-call engineer. Target < 10.
I collect these by reviewing incident post-mortems (did an alert
fire before user reports?), by tagging alerts with action taken
(PagerDuty has an outcome field), and by weekly on-call surveys
(how many pages, how many were meaningful). I publish a monthly
alerting health report to engineering leadership: precision,
recall, volume, and on-call satisfaction score. Trends in the
wrong direction trigger an alerting review week where the team
dedicates time to fixing noisy alerts.

*What separates good from great:* Great candidates describe
the process for tracking alert precision over time using PagerDuty
API to aggregate alert outcome data.

---

**Q8 [MID] What is the `for` field in a Prometheus alert rule?**

*Why they ask:* Tests alert configuration details.

*Likely follow-up:* What happens if you set `for: 0s`?

The `for` field in a Prometheus alert rule specifies how long
the alerting condition must be continuously true before the
alert fires. An alert rule is in "pending" state while the
condition is true but the `for` duration has not elapsed. It
transitions to "firing" state after the `for` duration. With
`for: 5m`, an alert fires only after the condition has been
true for 5 continuous minutes. If the condition resolves after
3 minutes, the alert returns to "inactive" state without firing.
This prevents transient spikes from causing pages: a 30-second
spike in error rate does not page anyone. Setting `for: 0s`
means the alert fires immediately when the condition is first
true - appropriate only for catastrophic conditions (service
completely down, all endpoints returning 500) where any
duration requires immediate action. For SLO burn rate alerts,
`for: 2m` is appropriate for the fast window (enough to confirm
it is real) and `for: 10m` for the slow window. Too long a
`for` delays alerting for genuine incidents; too short causes
flapping.

*What separates good from great:* Great candidates describe the
`keep_firing_for` field (Prometheus 2.42+) that keeps an alert
firing for a minimum duration after the condition resolves,
preventing rapid alert-and-resolve cycles from being missed.

---

**Q9 [SENIOR] How do you handle on-call for a globally distributed team?**

*Why they ask:* Tests organizational alerting at scale.

*Likely follow-up:* How do you implement follow-the-sun on-call?

For a globally distributed team, follow-the-sun on-call means
routing alerts to the on-call engineer in the time zone that
is currently awake. AlertManager supports time-based routing
with the `time_intervals` feature: define intervals for each
time zone's business hours and route critical alerts to the
appropriate team receiver based on the current time. For example,
US West Coast engineers are primary from 09:00-17:00 PST;
UK engineers are primary from 09:00-17:00 GMT; APAC engineers
cover the remaining window. The AlertManager `routes` block
includes `active_time_intervals` to restrict routes to specific
time windows. During each team's active hours, their PagerDuty
integration receives pages. Outside their window, pages escalate
to the global fallback (a senior engineer who covers the handoff
gaps). The practical challenge is calibration: the transition
windows (30 minutes before and after shift) need overlap to
prevent pages falling through the gap. I implement a 1-hour
overlap where both outgoing and incoming on-call engineers are
active, with a handoff check-in meeting at each transition.

*What separates good from great:* Great candidates describe
the runbook localization challenge: runbooks must work for
engineers who are not the primary team and may have less
context.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with SLO burn rate model and PromQL implementation |
| Hiring Manager | Lead with alert fatigue reduction and its impact on team health |
| Bar Raiser | Lead with multi-window alerting and measuring alerting effectiveness |
| Peer Engineer | Collaborative: "Inhibition rules saved us from 30-page storms during database outages - here is the config" |

---

### 🏛️ System Design

*(Omit: L2 working keyword; system design covered in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the AlertManager pipeline ASCII in Concept Explanation
illustrates the routing flow clearly.)*

---

---

# Log Querying and Analysis

**TL;DR** - LogQL (Loki) and Lucene (Elasticsearch) are the two
primary log query languages for production log analysis. Effective
log querying is the skill that separates a 5-minute incident
resolution from a 45-minute investigation.

---

### 🎯 Model Answer

**30 seconds:**
> Log querying is searching structured log data to answer questions
> during incidents. In Loki, LogQL queries combine a log stream
> selector ({app="checkout"}) with pipeline stages: `| json` to
> parse JSON fields, `| user_id="u-9182"` to filter, `| count_over_time`
> to aggregate. The query `{app="checkout"} | json | level="ERROR"
> | error_type="PaymentException" | count_over_time([5m])` counts
> payment errors in 5-minute windows in one expression.

**3 minutes (Senior):**
> Effective log querying during incidents is a skill that
> compounds over time: the engineer who can write complex LogQL
> queries resolves incidents 3-5x faster than one who can only
> do simple text searches. The key mental model for LogQL: every
> query starts with a stream selector that picks which log streams
> to read (indexed, fast), then applies pipeline stages that filter
> or transform the log lines (unindexed, sequential scan).
> Minimizing the stream selector scope (make it as specific as
> possible) is the performance optimization: `{app="checkout",
> env="prod"}` is 10x faster than `{env="prod"}` because it reads
> one service's logs instead of all services' logs. Pipeline stages
> execute sequentially: JSON parsing, then field filtering, then
> aggregation. Field filtering early in the pipeline reduces the
> volume processed by later stages. For Elasticsearch (ELK stack),
> Lucene queries with the KQL syntax provide similar capability:
> `app:checkout AND level:ERROR AND @timestamp:[now-5m TO now]`.
> The key skill is combining time range, service filter, and field
> filter in one query, then aggregating by the dimension that
> answers the question.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers design log schema conventions
that enable the most common incident queries to be written
in < 30 seconds: standardized field names, event taxonomy,
and structured error context.

*Adapting down:* "Log querying is searching your logs like a
database. Instead of SELECT * FROM logs WHERE app='checkout'
AND level='ERROR', you write `{app='checkout'} | json |
level='ERROR'` in LogQL."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about log querying - let me walk
through LogQL syntax and the workflow for incident investigation."

**(2) First principles:** "From first principles, log data is a
stream of events. To answer a question, you filter the stream
to matching events and aggregate or inspect the results."

**(3) Bridge:** "LogQL is like SQL for logs: the stream selector
is the FROM/WHERE on indexed fields (fast), and the pipeline is
WHERE/GROUP BY on unindexed fields (sequential scan)."

---

### 📘 Concept Explanation

**What it is:**
Log querying is the practice of searching structured log data
to answer operational questions. LogQL (Loki's query language)
and Lucene/KQL (Elasticsearch's query language) are the two
primary languages for production log systems.

**The problem it solves:**
Unstructured log search is slow and fragile (full-text regex).
Structured log query languages with field-based filters enable
precise, fast queries: find all checkout failures for user
u-9182 in the last 15 minutes with a 500ms query instead of
a 30-second regex scan.

**How it works:**
LogQL query structure:

```
{stream selector} | pipeline_stage | pipeline_stage ...

Examples:

# Get all ERROR logs for checkout (last 15 min)
{app="checkout"} | json | level="ERROR"

# Count errors by type in 5-min windows
sum by (error_type) (
  count_over_time(
    {app="checkout"} | json
      | level="ERROR"
      | error_type != "" [5m]
  )
)

# Find all events for a specific user
{app=~"checkout|payment"} | json
  | user_id="u-9182"
  | line_format "{{.event}} {{.duration_ms}}ms"

# Find slow requests (> 1000ms)
{app="checkout"} | json
  | duration_ms > 1000
  | line_format "{{.trace_id}} {{.duration_ms}}ms"
```

Stream selectors use indexed label values (fast).
Pipeline stages operate on log line content (sequential).
Order matters: filter early to reduce pipeline volume.

**The key insight:**
The most valuable log query skill is building a "query ladder"
for an incident: starting with a broad query to confirm the
problem exists, then narrowing to the specific service, then
to the specific event type, then to the specific request, then
to the trace ID. Each step reduces the search space and increases
the diagnostic precision.

**When to use it:**
Log queries are for incident investigation, compliance auditing,
and business analytics from event logs. Daily use during incident
triage.

**When NOT to use it:**
Do not use log queries as the alerting mechanism (use metrics
and Prometheus AlertRules). Do not write queries that scan all
services' logs (`{env="prod"}`) when you know the specific
service - always narrow the stream selector.

**Alternatives:**
- Elasticsearch KQL/Lucene: full-text search capability on top
  of structured fields; powerful for log search but operationally
  complex
- Splunk SPL: powerful enterprise log analytics; high cost
- AWS CloudWatch Insights: managed, AWS-native; query syntax
  is SQL-like but limited compared to LogQL

**First-principles derivation:**
Log systems index label values (app, env, service) for fast
stream selection. They do NOT index all field values inside
log lines - that would require too much storage. Log line
field filtering (| level="ERROR") is a sequential scan of
the selected stream. The performance model: indexed selector
= O(1) stream selection; pipeline filter = O(n) where n is
the number of lines in the selected stream. Minimize n by
making the selector as specific as possible, then apply
filters in decreasing selectivity order (most selective first).

---

### 💻 Code Example

**Example 1: BAD - Inefficient log queries**

```logql
# BAD: overly broad selector + late filtering
# Scans ALL production logs, then filters
{env="prod"}
  | json
  | app="checkout"         # Should be in stream selector
  | level="ERROR"

# BAD: regex on full log line (very slow)
{app="checkout"}
  |~ "PaymentException"    # Regex on full line content
# Better: | json | error_type="PaymentException"

# BAD: no time range specified
# Defaults to last 6 hours - scans gigabytes
{app="checkout"} | json | level="ERROR"
# Always specify: last 15 minutes is usually sufficient
```

> **Code walkthrough:** The first BAD example uses `{env="prod"}`
> as the stream selector, which selects ALL services' logs in
> production. The `app="checkout"` filter is applied as a pipeline
> stage (sequential scan) instead of being in the selector (indexed).
> This is 100x slower than `{app="checkout", env="prod"}`. The
> regex operator `|~` scans the entire log line as a string,
> which is slower than field-based filtering after JSON parsing.
> No time range defaults to the last 6 hours, scanning far more
> data than needed for a recent incident.

**Example 2: GOOD - Efficient incident investigation queries**

```logql
# GOOD: Specific selector + efficient pipeline
# Query 1: Current error rate (last 15 min)
sum by (error_type) (
  count_over_time(
    {app="checkout", env="prod"}
    | json
    | level="ERROR"
    | error_type != "" [5m]
  )
)
# Returns: {"PaymentException": 12, "TimeoutException": 3}
# 3-5 second query time vs 30+ second for broad selector

# Query 2: All logs for a specific trace
{app=~"checkout|payment|inventory", env="prod"}
  | json
  | trace_id="4bf92f3577b34da6a3ce929d0e0e4736"
  | line_format "{{.timestamp}} [{{.app}}] {{.event}}
      {{.duration_ms}}ms"

# Query 3: Top 10 slowest checkout requests
topk(10,
  max by (trace_id) (
    {app="checkout", env="prod"}
    | json
    | duration_ms > 0
    | unwrap duration_ms [5m]
  )
)
# Returns trace IDs with their max duration

# Query 4: Error volume trend over 1 hour
sum (
  count_over_time(
    {app="checkout", env="prod"}
    | json
    | level="ERROR" [5m]
  )
) by (pod)
# Per-pod error rate - useful to spot bad pods
```

> **Code walkthrough:** Query 1 uses a specific stream selector
> ({app="checkout", env="prod"}) and filters level="ERROR" before
> the aggregation. The aggregation by error_type gives a breakdown
> of which error types are occurring, pointing the investigation
> to the right code path. Query 2 uses a multi-service selector
> (app=~"checkout|payment|inventory") to find all logs for a
> specific trace across all services - the cross-service diagnostic
> pattern. Query 3 uses `unwrap` to extract the duration_ms field
> as a numeric value for `topk` aggregation - finding the slowest
> requests. Query 4 adds `by (pod)` to check if errors are spread
> across all pods (systemic) or concentrated in one pod (bad
> deploy or OOM on one instance).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> LogQL queries start with a stream selector in braces that picks
> the log streams by label ({app="checkout"}). Then pipeline stages
> filter and transform: `| json` parses JSON fields, `| level="ERROR"`
> filters to errors, `| count_over_time([5m])` counts events in
> 5-minute windows. The most important optimization is using specific
> stream selectors - the label inside the braces uses an index, so
> `{app="checkout"}` is much faster than `{env="prod"}` when I only
> want checkout logs.

*Push deeper:* Describe the difference between filter expressions
(|= "text") and label filter expressions (| field="value") after
JSON parsing.

---

**Senior / Staff (5+ years):**
> Log querying skill directly impacts incident MTTR. I build a
> query ladder for every service: the 5 most important incident
> queries pre-written in the runbook. During an incident, I start
> with query 1 (current error count by type) which answers "what
> is failing" in 5 seconds. Query 2 shows error volume trend
> (did it just start?). Query 3 finds a representative trace ID.
> Query 4 opens the trace in Jaeger. This workflow gets from
> "alert fired" to "root cause identified" in 5-7 minutes
> instead of 30-45. The runbook includes the specific LogQL for
> each step, parameterized by time range and service.

*Push deeper:* Describe how to use Loki's recording rules
(ruler feature) to pre-compute expensive LogQL aggregations
and convert them to metrics for alerting.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "Full text search is as fast as field-based search" | Regex on full log line content is 10-100x slower than field filter after JSON parsing. Always use `| json | field="value"` not `|~ "value"` |
| "Loki stores all log fields in an index" | Loki only indexes stream labels (app, env). Log line content is not indexed. This is by design for cost - but means pipeline filters are sequential scans |
| "Log queries replace distributed traces" | Logs show what happened; traces show when and in what order across services. Both are needed for production diagnosis |
| "A broader time range is safer during incidents" | A broader time range scans more data, slows queries, and increases noise. Use a 15-minute window initially, expand only if the relevant event is not in that range |

---

### ⚖️ Comparison Table

| Query language | Best for | Syntax style | Backend |
|---------------|----------|-------------|---------|
| **LogQL** | Kubernetes, Grafana-native | Pipeline + label filter | Loki |
| **Lucene/KQL** | Full-text search, ES ecosystem | Query DSL or KQL | Elasticsearch |
| **Splunk SPL** | Enterprise SIEM, complex analytics | SQL-like commands | Splunk |
| **CWL Insights** | AWS-only, managed | SQL-like | CloudWatch |

**When to choose LogQL vs Lucene:**
LogQL for new Kubernetes deployments already using Grafana+Prometheus
(low cost, unified UI). Lucene/Elasticsearch when full-text search
on arbitrary log content is required or the team is already
invested in the ELK stack.

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Query timeout during incident**

Symptom: LogQL query for error investigation times out after
30 seconds. Loki returns "query cancelled". Investigation halted.

Root cause: Query scans too much data - broad stream selector
or large time range during high log volume period.

Diagnostic:
```bash
# Check query stats in Loki API response
curl -s 'http://loki:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={env="prod"}|json|level="ERROR"' \
  --data-urlencode 'limit=1' | jq .stats
# Look for: "ingestersTotalReached": N (N services scanned)
# If N > 5, the selector is too broad
```

Fix: Narrow the stream selector to the specific app and namespace.
Reduce time range to 15 minutes. Move aggregations to a recording
rule (pre-computed) instead of computing at query time.

Prevention: Document query optimization rules in the runbook:
always use app-specific stream selectors, always specify time range.

---

**Mode 2 - Loki logs query returns no results despite events existing**

Symptom: Query for error logs returns empty results. Engineer
concludes no errors occurred. Actually, logs are in the pipeline
but not yet queryable (pipeline latency).

Root cause: Log pipeline latency (15-30 seconds). The error
occurred 15 seconds ago and logs are still in the Fluentbit buffer.

Fix: Wait 30 seconds and retry. Include this note in the runbook:
"Logs from the last 30 seconds may not yet be queryable due to
pipeline latency."

Prevention: Runbook entry: pipeline latency is 15-30 seconds.
Always query from 1 minute before the incident start time.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Explain LogQL stream selector vs pipeline |
| Debugging | 90 sec | Write a query to find the root cause of a checkout failure |
| Comparison | 60 sec | Loki LogQL vs Elasticsearch Lucene |
| Scenario | 2 min | Design the query ladder for a new service |
| Trade-off | 60 sec | Log storage cost vs search capability |
| Production | 2 min | Describe a query optimization you made |
| Behavioral | 2-3 min | STAR story of diagnosing an incident via logs |
| Technical depth | 90 sec | How Loki indexes logs and why it affects query performance |
| Architecture | 90 sec | When to use Loki recording rules |

---

**Q1 [MID] Explain the structure of a LogQL query.**

*Why they ask:* Foundational LogQL knowledge test.

*Likely follow-up:* What is the performance implication of the stream selector?

A LogQL query has two parts: the stream selector and the pipeline.
The stream selector is in curly braces and selects which log
streams to read using indexed label values:
`{app="checkout", env="prod"}`. This uses Loki's label index for
fast stream selection - O(1) lookup regardless of total log volume.
The pipeline is a sequence of stages separated by `|`:
`| json | level="ERROR" | duration_ms > 1000 | line_format "..."`.
Pipeline stages execute sequentially on each log line: `| json`
parses the JSON body into fields, `| level="ERROR"` filters to
lines where the parsed level field equals "ERROR", `| duration_ms > 1000`
filters to lines where duration_ms exceeds 1000 as a number.
Pipeline stages are sequential scans of the selected stream
(unindexed). The performance implication: the stream selector
determines the volume of data processed; the pipeline determines
the filter cost within that data. Making the stream selector
as specific as possible (include app, namespace, env) minimizes
the data the pipeline processes.

*What separates good from great:* Great candidates describe how
Loki's chunk cache works: frequently queried recent data is
served from memory cache; older data requires disk reads.

---

**Q2 [JUNIOR] How do you find all logs for a specific user ID?**

*Why they ask:* Tests practical log query ability.

*Likely follow-up:* How would you search across multiple services?

To find all logs for user u-9182 in the checkout service:
`{app="checkout", env="prod"} | json | user_id="u-9182"`.
The JSON parsing stage makes user_id available as a named field
for exact-match filtering. For a time range: in Grafana's Loki
Explorer, set the time range to the last 15 minutes. Expand
to 1 hour if no results. To search across multiple services:
use a regex on the app label:
`{app=~"checkout|payment|inventory", env="prod"} | json
| user_id="u-9182"`. This returns all logs from the three
services that include user_id=u-9182, showing the full request
journey. Sort by timestamp (ascending) to read the sequence
of events. Look for any ERROR-level entries to identify the
failure point. The trace_id field (if present) lets you jump
from the log entry to the distributed trace in Jaeger/Tempo
for timing context.

*What separates good from great:* Great candidates describe
the `line_format` stage for formatting the output: `| line_format
"{{.timestamp}} [{{.app}}] {{.event}}: {{.error_message}}"` 
produces readable output instead of the raw JSON object.

---

**Q3 [SENIOR] How do you optimize a slow LogQL query?**

*Why they ask:* Tests log query performance engineering.

*Likely follow-up:* What is the maximum recommended query range for real-time investigation?

A slow LogQL query is usually due to one of three causes.
First, broad stream selector: `{env="prod"}` selects all services.
Fix: add app and namespace labels to the selector. Second, large
time range: 24-hour range during incident investigation. Fix:
narrow to 15 minutes for incident triage; expand only if needed.
Third, expensive pipeline expression: regex `|~ ".*PaymentException.*"`
on full log line. Fix: use field-based filter `| json | error_type="PaymentException"`
after JSON parsing. The optimization process: check the query
stats (Loki API returns statistics including bytes processed and
chunks scanned). If chunks > 10,000 for a 15-minute query on
one service, there is a log volume problem. If bytes_processed > 100MB
for a 15-minute window, the stream is too broad. Pre-compute
expensive aggregations as Loki recording rules (the ruler
component): store the result as a Prometheus-compatible metric
that dashboards and alerts can query instantly.

*What separates good from great:* Great candidates describe Loki's
`query_range` API stats response and how to read the "summary"
object to understand query performance.

---

**Q4 [JUNIOR] What is the difference between `|=` and `| json |` in LogQL?**

*Why they ask:* Tests LogQL operator knowledge.

*Likely follow-up:* When is `|=` appropriate over `| json |`?

`|=` is a line filter expression that performs a case-sensitive
substring match on the raw log line string: `{app="checkout"} |= "PaymentException"`. It does not parse the log line - it just
checks if the raw string contains the substring. It is fast for
simple string matching but imprecise: it can match "PaymentException"
in any field, including the message, error type, or stack trace.
`| json | error_type="PaymentException"` first parses the entire
log line as JSON (using the json stage), then applies a field-
based exact match filter to the error_type field specifically.
It is more precise: it only matches log lines where the error_type
JSON field equals exactly "PaymentException", not where the
string appears anywhere in the log line. Use `|=` when: the
search term is unique and unlikely to appear in unintended
fields, or when the logs are not JSON (free-form text logs).
Use `| json | field="value"` when: you want to match a specific
field value exactly, or when the term might appear in multiple
fields and you only want matches in one specific field.

*What separates good from great:* Great candidates describe the
performance difference: `|=` can be applied before JSON parsing
and can filter out log lines early in the pipeline. `| json`
parses every line before the field filter, so `|= "term" | json`
is faster than `| json | message="term"` when the term is unique.

---

**Q5 [SENIOR] How do you query Loki logs to support an SLO measurement?**

*Why they ask:* Tests SLO-native log analytics.

*Likely follow-up:* How is log-based SLO measurement different from metrics-based?

Log-based SLO measurement is an alternative to metrics-based when
structured log events are more reliable than metrics instrumentation.
The LogQL metric query for checkout availability SLO:

```logql
# Error rate from logs
sum(count_over_time(
  {app="checkout", env="prod"}
  | json
  | level="ERROR"
  | event="checkout.failed" [5m]
)) /
sum(count_over_time(
  {app="checkout", env="prod"}
  | json
  | event=~"checkout.complete|checkout.failed" [5m]
))
```

This divides error events by total checkout events (success +
failure) to compute the error rate. The difference from metrics-
based: log-based captures only events that were explicitly logged
(business-level SLO). Metrics-based captures all HTTP responses
(infrastructure-level SLO). Log-based is more precise for business
SLOs (some HTTP 200s may represent business failures; some HTTP 500s
may be expected). The limitation: log-based SLO depends on 100%
of events being logged - if high-volume sampling is applied, the
log-based count underestimates total events.

*What separates good from great:* Great candidates describe using
Loki ruler (recording rules) to evaluate this LogQL expression
on a schedule and expose it as a Prometheus metric for integration
with the standard SLO alerting stack.

---

**Q6 [MID] How do you investigate a specific user's failed checkout?**

*Why they ask:* Tests practical incident investigation workflow.

*Likely follow-up:* How would you identify if it is affecting only one user?

Step 1: Find the error log for the specific checkout:
```logql
{app="checkout", env="prod"}
| json
| user_id="u-9182"
| level="ERROR"
```
This returns the error log lines for that user. Step 2: Extract
the trace_id from the ERROR log line and open it in Jaeger/Tempo
to see the full trace across all services. Step 3: Check if other
users are affected with the same error:
```logql
count by (user_id) (
  count_over_time(
    {app="checkout", env="prod"}
    | json
    | level="ERROR"
    | error_type="PaymentException" [15m]
  )
)
```
If the count shows only user u-9182, it is user-specific (may be
a data issue with their account). If multiple users appear, it
is systemic. Step 4: Check the timeline - when did the first error
for this user occur?
```logql
{app="checkout", env="prod"}
| json
| user_id="u-9182"
| line_format "{{.timestamp}} {{.event}} {{.level}}"
```
Sort ascending to see the full sequence of events.

*What separates good from great:* Great candidates describe checking
whether the user had any recent successful checkouts (to determine
if the failure is new) by removing the `level="ERROR"` filter.

---

**Q7 [STAFF] How do you design a log query library for a team?**

*Why they ask:* Tests knowledge-sharing and team efficiency thinking.

*Likely follow-up:* How do you ensure the queries stay up to date?

A log query library is a set of pre-written, parameterized queries
for the most common incident investigation scenarios, stored in
runbooks and Grafana Explore bookmarks. I design it with three
layers. First, the query ladder: for each service, 5 queries
in escalating specificity order: (1) current error count and type,
(2) error volume trend, (3) find trace_id for a sample error,
(4) full event sequence for a trace_id, (5) per-pod breakdown.
These are parameterized (time range and service are variables).
Second, Grafana Explore bookmarks: each query in the library is
a saved Grafana Explore link. Engineers click the bookmark and
get the query pre-populated, then adjust the time range and service
variable. Third, runbook integration: each alert's runbook includes
the relevant query ladder queries with links to the Grafana bookmarks.
Maintaining currency: queries are reviewed quarterly as part of
the alerting health review, and updated when field names change.
Queries that take > 10 seconds are refactored to use recording
rules or tighter selectors.

*What separates good from great:* Great candidates describe how
to version the query library as a GitOps artifact (Grafana
JSON provisioning) so query updates go through code review.

---

**Q8 [SENIOR] How do Loki recording rules work and when do you use them?**

*Why they ask:* Tests advanced Loki features.

*Likely follow-up:* How are Loki recording rules different from Prometheus recording rules?

Loki recording rules (part of the Loki Ruler component) evaluate
LogQL metric queries on a schedule and write the results as time
series to a Prometheus-compatible backend. They work identically
to Prometheus recording rules, but the source expression is LogQL
instead of PromQL. Example:
```yaml
groups:
  - name: checkout.log.rules
    interval: 1m
    rules:
      - record: job:checkout_errors:rate5m
        expr: |
          sum by (error_type) (
            count_over_time(
              {app="checkout", env="prod"}
              | json | level="ERROR" [5m]
            )
          )
```
This pre-computes the error count by type every minute and stores
it as a Prometheus metric `job:checkout_errors:rate5m`. Dashboards
query the recording rule result (instant, low cost) instead of
re-evaluating the LogQL expression (sequential scan, slow). Use
cases: any LogQL expression used on a dashboard or alert, expensive
aggregations (topk, sum across many labels), SLO calculations
from log events. Difference from Prometheus recording rules: Loki
rules reduce log query cost (sequential scan) to metric query cost
(indexed lookup). Prometheus rules reduce metric query cost (already
cheap) to near-zero.

*What separates good from great:* Great candidates describe the
cardinality concern for Loki recording rules: each unique label
value combination in the result creates a new metric time series.
`sum by (user_id)` would create one series per user - cardinality
explosion.

---

**Q9 [JUNIOR] How do you handle log queries when logs are not yet in Loki?**

*Why they ask:* Tests pipeline latency awareness.

*Likely follow-up:* What is the pipeline latency for your current logging stack?

When logs from the last 15-30 seconds are not yet in Loki, it
is because they are still in the log collection pipeline (Fluentbit
buffering, OTel Collector batching, or Loki ingestion). Handling:
First, wait 30 seconds and retry the query. Second, check if the
issue is ongoing: if the service is still erroring, new logs will
appear within 30-60 seconds. Third, if the query is for events
from > 60 seconds ago and returns no results, investigate the
pipeline health: check Fluentbit queue depth and Loki ingester
status. The runbook note: "Log pipeline latency is 15-30 seconds.
For incident investigation, query from at least 1 minute before
the incident start. If querying for events within the last 60
seconds and getting no results, wait 30 seconds and retry before
concluding no logs exist." In Grafana's Loki data source, the
"Live" tailing feature bypasses pipeline latency for new events:
it streams logs directly from Loki as they are indexed, with
< 5 seconds latency. Use Live tailing to monitor a service in
real time during an active incident.

*What separates good from great:* Great candidates describe how
to use `kubectl logs -f` for real-time log tailing from individual
pods when Loki pipeline latency is too high during a critical
incident.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with LogQL structure and performance optimization |
| Hiring Manager | Lead with the MTTR improvement from fast log queries |
| Bar Raiser | Lead with query ladder design and Loki recording rules |
| Peer Engineer | Collaborative: "Pipeline latency catches everyone during their first incident - here is the runbook note I add to every service" |

---

### 🏛️ System Design

*(Omit: L2 working keyword; system design covered in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the LogQL query structure examples above illustrate
the query model clearly. A separate diagram does not add value
for this L2 working-level concept.)*
