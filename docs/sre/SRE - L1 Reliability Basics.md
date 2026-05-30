---
layout: default
title: "SRE - L1 Reliability Basics"
parent: "SRE"
grand_parent: "SK Interview"
nav_order: 4
permalink: /sre/l1-reliability-basics/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Error Budget](#error-budget) | critical |
| 2   | [Toil - Definition, Measurement, and Reduction](#toil---definition-measurement-and-reduction) | critical |
| 3   | [Availability and Reliability Fundamentals](#availability-and-reliability-fundamentals) | high |

---

# Error Budget

🎯 Interview Weight: critical - the defining mechanism of SRE;
your ability to explain it demonstrates whether you understand
SRE as an organizational tool, not just a monitoring system.

---

### 🎯 Model Answer

**30 seconds:**
> An error budget is the allowed failure space derived from an SLO.
> If the SLO is 99.9% availability over 30 days, the error budget is
> 0.1% of that period - approximately 43 minutes of allowed downtime.
> The budget is spent by incidents, risky deployments, and planned
> maintenance. When it runs out, new feature deployments should be
> frozen until the budget resets or reliability improves. This
> converts reliability from a moral debate into a quantitative rule.

**3 minutes (Senior):**
> The error budget is the mechanism that makes the SLO operationally
> useful. Without it, an SLO is just a metric - it tells you whether
> you are meeting a target but does not tell you what to do. The
> error budget answers "what do we do when we are spending reliability?"
>
> The error budget creates a shared incentive structure between product
> and SRE. When the budget is healthy, product teams deploy fast -
> they have budget to spend on deployment risk. When the budget is
> exhausted, deployments freeze until reliability is restored. Both
> sides agree on this rule in advance. This removes the politics from
> the reliability-velocity negotiation.
>
> There are two ways an error budget is consumed: unplanned (incidents,
> deployment failures, unexpected degradations) and planned (maintenance
> windows, risky migrations, large rollouts). Both count against the
> budget. The budget forces the team to be deliberate about risk.
>
> The error budget policy is the organizational artifact that gives
> the budget teeth. It specifies: what triggers a budget review
> (e.g., >50% consumed in first half of month), what triggers a
> deployment freeze (budget exhausted), and what the escalation path
> is if product management needs to deploy despite an exhausted
> budget. Without the policy, the budget is a dashboard metric
> with no action attached.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "Burn rate alerting is how the error
budget becomes a real-time operational tool, not just a monthly
reporting metric. A 14x burn rate means the budget will be exhausted
in 2 days at the current degradation rate. This gives the SRE team
a quantitative urgency signal that drives the incident response."

*Adapting down:* Junior: "The error budget is the maximum amount
of unreliability you are allowed in a given period. If your SLO is
99.9%, your error budget is 0.1% - about 43 minutes per month of
allowed downtime. When that budget is used up by incidents, you
should stop deploying new features and focus on reliability until
the next period starts."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about error budgets - let me explain
what they are and why they are the central organizing mechanism of SRE."

**(2) First principles:** "From first principles: if 100% reliability
is impossible, how much failure is acceptable? The error budget
answers this: the acceptable failure rate is (1 - SLO target), and
that rate represents a finite budget that can be spent on deployment
risk, incidents, and maintenance."

**(3) Bridge:** "An error budget is like a monthly expense budget.
Your company has a monthly budget for expenses. When it is healthy,
you can spend on new initiatives. When it is exhausted, you stop
spending until next month. The SRE error budget is a monthly budget
for reliability risk: healthy budget means deploy fast, exhausted
budget means stop deploying and fix reliability."

---

### 📘 Concept Explanation

**What it is:**
The error budget is the allowed failure rate derived from the SLO
target. It represents the quantitative amount of unreliability the
service is permitted to exhibit in a given measurement window without
breaching its SLO. The error budget is calculated as: Error Budget =
(1 - SLO target) * measurement window.

**The problem it solves:**
Before error budgets, the product-reliability trade-off was resolved
informally, by politics, or by incident. When product wanted to
deploy fast and reliability suffered, there was no objective rule
to invoke. An exhausted error budget is an objective, pre-agreed
rule: the budget is gone, deployments freeze. No politics required.

**How it works:**

```
ERROR BUDGET MECHANICS
======================

CALCULATION
  SLO target: 99.9%
  Error budget: 1 - 0.999 = 0.001 (0.1%)
  Window: 30 days = 43,200 minutes
  Budget: 43,200 * 0.001 = 43.2 min/month

CONSUMPTION TRACKING
  Budget consumed (%) =
    (SLO - actual SLI) / (1 - SLO) * 100

  Example:
    SLO: 99.9%, Actual SLI: 99.85%
    Consumed = (0.001 - 0.0015) / 0.001 * 100
             = 0.0005 / 0.001 * 100 = 50%
    50% of error budget consumed

BURN RATE
  Burn rate = actual failure rate / allowed failure rate
  Example: 1.5% actual failures, 0.1% allowed
    Burn rate = 1.5% / 0.1% = 15x
    At 15x burn rate: budget exhausted in 2 days

ERROR BUDGET POLICY (typical)
  Budget > 50% remaining: all deployments allowed
  Budget 10%-50% remaining: careful deployments only
  Budget < 10%: freeze new deployments
  Budget exhausted: emergency freeze + reliability sprint
  Exception: VP-level approval required to override

BUDGET RESET OPTIONS
  Calendar month: budget resets on 1st of month
    Risk: "reset race" (deploy aggressively after reset)
  Rolling 28-day: budget never resets
    Benefit: consistent incentives, no reset race
```

**The key insight:**
The error budget is not a technical tool - it is an organizational
negotiation instrument. Its power comes from being agreed upon in
advance. When the budget is exhausted and the SRE invokes the
deployment freeze, they are not making a judgment call - they are
executing a pre-agreed policy. This removes the SRE from the position
of "reliability police" and positions them as a policy executor.

**When to use it:**
For every service with a defined SLO. The error budget policy should
be agreed upon between SRE, product, and engineering management
before the service goes into production with SLOs, not after the
first incident.

**When NOT to use it:**
Error budgets require SLOs to be meaningful. Without a well-defined
SLO that reflects real user requirements and historical achievable
performance, the error budget will either be perpetually exhausted
(SLO too tight) or never consumed (SLO too loose). The budget
mechanism is only useful when the SLO is correctly set.

**Alternatives:**
- Deployment frequency limits (arbitrary, not reliability-based)
- Change advisory board (CAB) reviews - bureaucratic, not quantitative
- Informal reliability reviews without objective criteria

**First-principles derivation:**
If reliability cannot be 100% and costs something to achieve, then
reliability is a resource to be budgeted. The error budget converts
the SLO's implied allowed failure rate into an explicit, trackable
resource. When that resource is depleted, the team must choose between
spending the resource (accepting a breach) or stopping deployment
activity that would deplete it further.

---

### 💻 Code Example

**Example 1: Error budget remaining - Prometheus recording rule**

```yaml
# BAD: no recording rules - recomputing 28-day
# queries in every dashboard causes timeout
# and high Prometheus load.

# GOOD: recording rule for error budget tracking
# In prometheus/rules/error_budget.yml:
groups:
  - name: slo.error_budget
    interval: 1m
    rules:
      # 28-day SLI (recomputed every minute)
      - record: sli:availability:28d
        expr: |
          (
            increase(
              http_requests_total{status=~"2.."}[28d]
            )
          )
          /
          (
            increase(http_requests_total[28d])
          )

      # Error budget remaining (0-1 scale)
      # SLO target: 0.999
      - record: error_budget:remaining:28d
        expr: |
          1 - (
            (1 - sli:availability:28d)
            /
            (1 - 0.999)
          )
```

> **Code walkthrough:** The BAD approach recomputes 28-day range
> queries on every dashboard load, which is expensive and slow.
> The GOOD approach uses recording rules that Prometheus pre-computes
> every minute. `sli:availability:28d` stores the rolling SLI.
> `error_budget:remaining:28d` stores the fraction of budget
> remaining as a 0-1 value: 1.0 = full budget, 0.0 = exhausted,
> negative = budget overrun. Dashboards and alerts query these
> recorded metrics instead of raw counters, making them fast and
> consistent.

**Example 2: Error budget burn rate alert**

```yaml
# Burn rate alerting for error budget
# Critical: budget exhausted in ~2 days (page urgently)
# Warning: budget exhausted in ~5 days (page soon)

groups:
  - name: error_budget_burn_rate
    rules:
      # Fast burn: high urgency
      - alert: ErrorBudgetFastBurn
        expr: |
          (
            error_burn_rate:1h > 14.4
            AND
            error_burn_rate:5m > 14.4
          )
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: >
            Error budget burning fast -
            exhausted in {{ $value | humanizeDuration }}
          runbook: https://wiki/runbooks/slo-breach

      # Slow burn: lower urgency
      - alert: ErrorBudgetSlowBurn
        expr: |
          (
            error_burn_rate:6h > 6
            AND
            error_burn_rate:1h > 6
          )
        for: 15m
        labels:
          severity: warning
```

> **Code walkthrough:** Burn rate alerting detects how fast the
> error budget is being consumed relative to the allowed rate.
> 14.4x burn rate means the budget would be exhausted in 2 days
> (30 days / 14.4 = 2.08 days). The dual-window check (1h AND 5m
> for fast burn; 6h AND 1h for slow burn) confirms the burn is
> sustained, not a transient spike. The `for: 2m` clause prevents
> alerting on momentary spikes. This replaces naive threshold
> alerting with a budget-consumption model that is proportional
> to business impact.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The error budget is the amount of failure a service is allowed
> in a given period, derived from the SLO. If the SLO is 99.9%
> over 30 days, the error budget is 0.1% - about 43 minutes of
> downtime. The budget is spent by incidents and risky deployments.
> When it runs out, new deployments should stop until reliability
> is restored or the period resets. The error budget turns reliability
> from a moral discussion into a quantitative policy.

*Push deeper:* Explain burn rate - how fast the budget is being
consumed relative to the allowed rate. A 5x burn rate means the
budget will be exhausted in 6 days (30/5), not 30. Burn rate is
how error budgets drive real-time operational decisions.

---

**Senior / Staff (5+ years):**
> The most important thing about error budgets is the policy, not
> the measurement. The measurement is straightforward: (1 - SLO) *
> window = budget. The policy is the hard part: what triggers a
> deployment freeze, who can override it, what the escalation path
> is. Without the policy, the error budget dashboard just shows
> a number that nobody acts on.
>
> I have seen organizations where the error budget is exhausted
> every single month and nothing changes. Product teams deploy
> anyway because there is no enforced policy. The budget becomes
> a lagging indicator that confirms everyone already knows the
> service is unreliable. The policy is what makes the budget a
> decision-making tool.

*Push deeper:* Staff angle: "Error budget negotiation is the most
valuable organizational skill for senior SREs. When product management
says 'we must deploy this week even though the budget is exhausted,'
the SRE does not refuse - they say 'we can make an exception with
VP approval and an explicit acceptance of the budget overrun risk,
documented in the incident register.' This preserves the integrity
of the system while accommodating genuine business needs."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| An exhausted error budget means the service is broken | An exhausted budget means reliability was below the SLO target; the service may still be functional, just not meeting its reliability commitment |
| The error budget resets automatically and teams can be aggressive after a reset | Calendar-month reset is a valid approach but creates incentive problems; rolling 28-day windows prevent reset-race behavior |
| Error budgets only track downtime | Error budgets track all SLO violations - latency, error rate, and availability; any SLI that contributes to SLO compliance burns the budget |
| A deployment freeze is the only response to an exhausted budget | The error budget policy should have a range of responses from heightened caution to full freeze, with an explicit exception path for business-critical deployments |
| Error budgets mean developers cannot deploy during incidents | Error budgets are a pre-agreed policy; during active incidents, the response is incident management, not deployment policy enforcement |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Error budget perpetually exhausted**

*Symptom:* Error budget reaches 0% in the first week of every
month. Deployment freezes are constant. Team is demoralized.
No meaningful work can be shipped.

*Root cause:* SLO is aspirational - set above current system
capability. The error budget is consumed by normal system variance,
not exceptional incidents.

*Diagnostic:*
```promql
# Check 90-day historical SLI trend
avg_over_time(
  (increase(http_requests_total{status=~"2.."}[28d])
  / increase(http_requests_total[28d]))[90d:1d]
)
# If consistently below SLO target: SLO is too tight
# Compare: target vs. rolling average
```

*Fix:* Reset SLO to be slightly better than the 90-day historical
average. Establish the baseline. Create a roadmap to tighten the
SLO quarterly as reliability improvements are made.

*Prevention:* Set initial SLOs based on historical performance
data. Never set SLOs based on aspirational targets or what
"sounds good."

**Failure 2: Error budget policy not enforced**

*Symptom:* Budget is exhausted regularly. Deployments continue
anyway. Product team learns to ignore budget signals. The error
budget becomes a vanity metric.

*Root cause:* Error budget policy exists on paper but has no
enforcement mechanism. SRE team has no authority to halt deploys.
Management does not back the policy.

*Diagnostic:*
```
Ask: "When was the last time a deployment was halted
because the error budget was exhausted?"
If answer is "never" or "I don't remember":
  Policy is not enforced.
Check: does the error budget dashboard have
any automated deployment gate integration?
If no: budget is advisory, not operational.
```

*Fix:* Implement automated deployment gates that check error
budget remaining before allowing production deployments. Require
VP-level approval to override. Report budget status to engineering
VP monthly.

*Prevention:* Before implementing SLOs, establish the error budget
policy with VP-level sign-off. The policy must have teeth (automated
gates) not just documentation.

**Failure 3: Single large incident exhausts entire annual budget**

*Symptom:* A major incident (e.g., 4-hour complete outage) exhausts
the entire monthly error budget in a single event. All deployments
are frozen for the rest of the month even though the underlying
issue is fixed.

*Root cause:* The error budget treats all failures equally, but
a single catastrophic incident should be handled differently from
chronic low-level unreliability.

*Diagnostic:*
```
Check: what fraction of total budget consumption
came from a single incident?
If > 80% from one incident: the budget has been
"poisoned" - the remaining month's deployments are
constrained by a single historical event, not
current system state.
```

*Fix:* The error budget policy should distinguish catastrophic
incidents (single events consuming >50% of budget) from chronic
unreliability. After a catastrophic incident with a known root
cause that is fixed, a reliability sprint review can unlock
deployments before the budget naturally resets.

*Prevention:* Add an "incident override" clause to the error
budget policy: after a catastrophic incident with a documented
root cause fix and post-incident reliability verification, the
SRE lead and engineering VP can jointly unlock the deployment
gate for the remainder of the month.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Error budget mechanics, policy, burn rate, organizational use |
| Seniority signal | Junior: defines budget; Senior: explains policy and organizational use |
| Common trap | Describing budget as purely technical without the policy dimension |
| Staff differentiator | Error budget negotiation, policy enforcement, burn rate alerting |

---

**Q1 [JUNIOR]: What is an error budget and how is it calculated?**

*Why they ask:* Fundamental SRE concept check. The answer reveals
whether the candidate understands the budget as a derived quantity.

*Likely follow-up:* "How does the error budget drive deployment
decisions?"

An error budget is the allowed failure space derived from the SLO.
Calculation: Error Budget = (1 - SLO target) * measurement window.

For a service with 99.9% SLO over 30 days: Error Budget = 0.001 *
30 days = 0.001 * 43,200 minutes = 43.2 minutes of allowed downtime.

The budget is tracked as a percentage remaining. If the service has
experienced 21.6 minutes of downtime so far this month, 50% of the
budget is consumed.

When the budget is healthy (>50% remaining), product teams can
deploy freely. When it is exhausted (0% remaining), the error budget
policy triggers a deployment freeze until the budget resets or the
SRE team certifies reliability improvements are in place.

*What separates good from great:* Most candidates define budget as
"allowed downtime." Great candidates explain the percentage-remaining
tracking, the calculation from SLO target, and how budget health
drives deployment decisions.

---

**Q2 [JUNIOR]: What happens when the error budget is exhausted?**

*Why they ask:* Tests whether the candidate understands the
operational consequence of budget exhaustion.

*Likely follow-up:* "Who has the authority to override a
deployment freeze?"

When the error budget is exhausted, the error budget policy activates.
The typical response cascade: first, a "soft freeze" - no new feature
deployments, only emergency bug fixes. Second, if exhaustion continues,
a "hard freeze" - no deployments of any kind except emergency patches.
Third, the SRE team prioritizes the highest-impact reliability
improvements from the backlog.

The policy should also specify the override path. If the business
genuinely needs to deploy despite an exhausted budget (a critical
customer commitment, a security patch), the decision is escalated
to VP-level, the override is documented explicitly, and the SRE
lead formally accepts the budget overrun risk on behalf of the
engineering organization.

The key point: budget exhaustion is not a permanent state. It resets
at the end of the measurement window. A calendar-month window resets
on the 1st. A rolling 28-day window slowly recovers as old incidents
fall out of the window.

*What separates good from great:* Most candidates say "deployments
stop." Great candidates describe the response cascade, the exception
path, and the recovery mechanism.

---

**Q3 [MID]: What is burn rate and why is it a better signal
than budget remaining?**

*Why they ask:* Tests whether the candidate understands the
predictive dimension of error budget management.

*Likely follow-up:* "What burn rate would you use as a
'page urgently' threshold?"

Budget remaining is a backward-looking metric: it tells you how
much of the budget has been consumed. Burn rate is a forward-looking
metric: it tells you how fast the budget is being consumed relative
to the normal rate.

Burn rate = actual failure rate / allowed failure rate.
At a 1x burn rate, the service is consuming budget at exactly the
rate implied by the SLO - it will use all its budget by the end of
the 30-day window. At a 6x burn rate, the budget will be exhausted
in 5 days (30/6). At a 14.4x burn rate, the budget will be exhausted
in 2 days.

Burn rate is a better operational signal because it reflects urgency.
A service with 80% budget remaining and a 10x burn rate will exhaust
its budget in 8 days - it needs immediate attention. A service with
20% budget remaining and a 0.5x burn rate will still have budget
remaining at month end - less urgent.

The SRE workbook recommends a 14.4x burn rate as the "page urgently"
threshold (budget exhausted in ~2 days), and a 6x burn rate as the
"page soon" threshold (budget exhausted in ~5 days).

*What separates good from great:* Most candidates know budget
remaining but not burn rate. Great candidates explain burn rate
as a forward-looking signal, give the specific thresholds, and
explain why the urgency model is more actionable than percentage
remaining.

---

**Q4 [MID]: How do planned maintenance windows affect the
error budget?**

*Why they ask:* Real operational scenario testing whether the
candidate has thought through scheduled maintenance.

*Likely follow-up:* "How do you communicate planned maintenance
to users to minimize SLA impact?"

By default, planned maintenance windows count against the error
budget just like unplanned outages. If a database maintenance window
takes the service offline for 30 minutes, 30 minutes of the error
budget is consumed.

Organizations handle this in several ways. The simplest: plan
maintenance windows to be within normal error budget. If the SLO
allows 43 minutes per month of downtime, schedule maintenance of
30 minutes or less and accept that it consumes most of the budget.

A more sophisticated approach: exclude planned maintenance from
the SLI measurement window (annotate maintenance events, filter
them from the SLI denominator). This preserves the error budget
for unplanned incidents but requires the SLA to explicitly exclude
planned maintenance from the uptime commitment.

The best approach is zero-downtime maintenance: design database
migrations, deployments, and infrastructure changes to execute
without downtime. This eliminates the maintenance window problem.

For the SLA: most SLAs explicitly exclude pre-announced maintenance
windows from the uptime calculation. Customers are notified in
advance (usually 48-72 hours), and the maintenance is not counted
against the SLA.

*What separates good from great:* Most candidates say maintenance
counts against the budget. Great candidates describe the three
approaches (absorb within budget, exclude with SLA carve-out,
zero-downtime design) and recommend based on context.

---

**Q5 [SENIOR]: How do you implement an error budget policy that
product management actually respects?**

*Why they ask:* Organizational effectiveness question testing
whether the candidate can create policy that has real consequences.

*Likely follow-up:* "What do you do when a VP overrides the
policy 'just this once'?"

Three elements make an error budget policy respected rather than
ignored: executive sponsorship, automated enforcement, and
transparent reporting.

Executive sponsorship: the error budget policy must be agreed upon
at VP level before it is ever invoked. When the SRE says "the budget
is exhausted," they are not making a new argument - they are invoking
a rule the VP already agreed to. Getting this agreement requires
showing historical data: "Services that deploy without respecting
error budgets have 3x the incident rate of services that do. This
is the cost we are agreeing to accept."

Automated enforcement: integrate the error budget check into the
deployment pipeline. A deployment to production requires a passing
error budget check as a prerequisite. Manual overrides require VP
approval, which creates a paper trail and raises the bar for
exceptions.

Transparent reporting: publish error budget status in engineering
all-hands, VP staff meetings, and on-call dashboards. When the
budget is exhausted and the whole organization knows it, the pressure
to honor the policy increases.

When a VP overrides "just this once": document the override in the
incident register, note the error budget state at the time, and
report the outcome in the next quarterly reliability review. If
the deployment causes an incident after the override, the data
speaks for itself.

*What separates good from great:* Most candidates describe error
budget policy as a technical concern. Great candidates describe
the three organizational elements (sponsorship, automation,
transparency) and give a specific approach for handling executive
overrides.

---

**Q6 [SENIOR]: How does the error budget change the relationship
between SRE and product management?**

*Why they ask:* Organizational dynamics question testing understanding
of how error budgets shift incentives.

*Likely follow-up:* "Can the error budget create conflict between
SRE and product teams?"

Before error budgets, SRE's relationship with product was implicitly
adversarial: SRE wanted stability, product wanted velocity, and
incidents resolved the tension (usually in favor of whoever had
the most organizational power). This was exhausting and political.

After error budgets, the relationship changes to a partnership model
with a shared objective. Both SRE and product share the error budget.
When the budget is healthy, both win: product ships features, SRE
demonstrates reliability. When the budget is exhausted, the
responsibility shifts to product to make reliability investments
(because their deployments burned the budget) before shipping new
features.

The conflict can still emerge, but it is now a policy conflict
rather than a values conflict. "The error budget says we should
freeze deployments" is a policy argument with an objective basis.
"We think stability is more important than features" is a values
argument that product will always resist.

The key cultural shift: error budgets make reliability a shared
responsibility. Product teams that deploy recklessly exhaust their
own budget and lose their own ability to deploy. This aligns
incentives in a way that purely SRE-owned reliability never achieves.

*What separates good from great:* Most candidates describe the
budget as an SRE tool. Great candidates describe the incentive
alignment it creates for product teams and explain why it converts
adversarial reliability politics into a shared policy framework.

---

**Q7 [STAFF]: How do you design an error budget program for a
portfolio of 100 microservices with varying criticalities?**

*Why they ask:* Staff-level scale question testing whether the
candidate can manage reliability programs at portfolio scale.

*Likely follow-up:* "How do you prioritize error budget investment
across a portfolio?"

For a 100-service portfolio, individual error budget management
is not scalable. The design must be tiered and systematic.

Tier 1 (critical, customer-facing): define SLOs and error budgets
with explicit policies for the top 10-15 services. These services
get dedicated SRE attention, burn rate alerting, and enforced
deployment gates. Error budget status is reported weekly.

Tier 2 (important, internal-facing): define SLOs for the top
30-40 services, with automated error budget tracking and alerting.
Deployment gates are softer (warning, not block). Error budget
status is reviewed monthly.

Tier 3 (supporting services): standardized SLOs via the enabling
platform template. Product teams are responsible for their own
error budget monitoring. SRE provides tooling and consulting but
not direct ownership.

Investment prioritization: the services with the highest error
budget consumption relative to their tier's SLO get the most
reliability investment. A tier-2 service consuming budget at the
same rate as a tier-1 service should be escalated to tier-1
treatment or have its SLO loosened.

The enabling platform provides the baseline: standard SLO dashboards,
burn rate alerting, and deployment gate checks available to all
100 services via the platform. Tiered manual engagement sits on
top of this foundation.

*What separates good from great:* Most candidates describe error
budgets per-service. Great candidates design a tiered system that
scales to portfolio size, describe the enabling platform foundation,
and give a specific investment prioritization framework.

---

---

# Toil - Definition, Measurement, and Reduction

🎯 Interview Weight: critical - the fundamental SRE concept
distinguishing SRE from traditional operations; demonstrates
whether you have internalized the engineering mandate.

---

### 🎯 Model Answer

**30 seconds:**
> Toil is manual, repetitive, automatable work that grows linearly
> with production system scale. It is the opposite of engineering
> work - it has no enduring value and scales up as the system grows.
> SRE defines a 50% toil cap: if more than half of an SRE's time is
> toil, the team is growing linearly with systems and the organization
> must either automate, reduce system scope, or add headcount.

**3 minutes (Senior):**
> The Google SRE book's definition of toil has six components: it is
> manual, repetitive, automatable, tactical (reactive), has no
> enduring value, and scales linearly with service growth. All six
> must apply. A creative analysis of a new failure mode is not toil,
> even if it is manual and time-consuming - it produces enduring
> knowledge. A weekly deployment that could be automated but is not
> is toil - it is manual, repetitive, automatable, and grows as more
> services are deployed.
>
> The 50% toil cap is both a health metric and an organizational rule.
> As a health metric: if toil exceeds 50%, the SRE team is growing
> linearly with systems, which is exactly the problem SRE was invented
> to solve. As an organizational rule: if toil exceeds 50% for two
> consecutive quarters, the response is not "hire more SREs" but "fix
> the toil sources or return systems to the development teams."
>
> Measuring toil requires making it visible. The simplest approach:
> ask each SRE to classify every interruption (on-call alert, ticket,
> manual task) as toil or engineering work. Track the ratio weekly.
> A more sophisticated approach: use JIRA labels or similar tags to
> categorize work items as "toil" vs. "engineering" and report the
> ratio monthly.
>
> Reducing toil requires identifying the highest-toil sources and
> automating them systematically. The rule: if the same manual action
> is taken more than twice, automate it. The automation does not
> need to be perfect - even a partially automated solution that
> reduces a 30-minute manual task to a 5-minute review is a 6x
> improvement.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "The most valuable toil reduction projects
are not the ones that eliminate the most work hours, but the ones
that eliminate the on-call interruptions that break deep work. An
alert that wakes an SRE at 3 AM for a self-resolving condition costs
more than its 15-minute resolution time - it costs half a day of
productivity recovery. Toil that fragments engineering time is more
harmful than toil that is predictable and schedulable."

*Adapting down:* Junior: "Toil is repetitive work that you could
automate but haven't yet. Examples: manually restarting a service
that crashes on a known pattern, manually approving access requests
that should be self-service, manually running scripts that could
be part of a CI/CD pipeline. SRE rule: if you do the same manual
thing more than twice, automate it."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about toil - let me walk through
the definition, why the 50% cap matters, and how to measure and
reduce it."

**(2) First principles:** "From first principles: if operations
work requires humans to execute it repeatedly, it scales linearly
with the system. SRE solves the linear scaling problem by automating
repetitive work. Toil is the name for the work that needs to be
automated. If toil is not measured, it cannot be reduced."

**(3) Bridge:** "Toil is like administrative overhead in knowledge
work. A researcher who spends 80% of their time on grant paperwork
and scheduling is not doing research. An SRE who spends 80% of their
time on manual ops is not doing reliability engineering. The 50%
cap ensures SREs have enough time to engineer solutions, not just
operate systems."

---

### 📘 Concept Explanation

**What it is:**
Toil is the SRE term for a specific type of operational work that
is manual, repetitive, automatable, tactical (reactive rather than
strategic), has no enduring value, and scales linearly with service
growth. Toil is the antithesis of engineering work and represents
the primary constraint on SRE team effectiveness.

**The problem it solves:**
Without a formal definition of toil and a measurement framework,
operations teams grow linearly with the systems they support - the
original problem SRE was designed to solve. By naming, measuring,
and capping toil, SRE teams can maintain sub-linear growth: more
systems, same or smaller team, because automation absorbs the
additional work.

**How it works:**

```
TOIL IDENTIFICATION CRITERIA
=============================

ALL SIX MUST APPLY:
  Manual:        requires human execution, not code
  Repetitive:    done more than once in the same way
  Automatable:   could be replaced with software
  Tactical:      reactive, not forward-looking
  No enduring value: doing it again next week
  Linear scaling: grows with system count/traffic

EXAMPLES
  Toil (all 6 apply):
    - Restarting crashed pods manually
    - Processing access request tickets
    - Manually rotating SSL certificates
    - Running deployment scripts step-by-step
    - Silencing the same noisy alert each week

  Not Toil (fails one or more criteria):
    - Diagnosing a new failure mode (has enduring value)
    - On-call incident response (tactical but not all 6)
    - Postmortem writing (enduring value)
    - Architecture review (strategic, not tactical)

TOIL MEASUREMENT
  Simple: manual logging
    SRE logs each 30-min block as toil or engineering
    Weekly: toil hours / total hours = toil ratio

  Better: ticket/alert categorization
    Label each Jira ticket, PagerDuty alert:
      "toil" or "engineering"
    Monthly report: toil label % of total

  Best: automated tagging
    Alert labels: "toil" on alerts that fire
    repeatedly without automation in place
    Dashboard: toil alerts / total alerts

50% CAP RULE
  >50% toil for 1 quarter: yellow - investigate
  >50% toil for 2 quarters: red - escalate
  Responses (in order):
    1. Automate highest-toil sources
    2. Return high-toil systems to dev teams
    3. Hire additional SREs (last resort)
```

**The key insight:**
The 50% toil cap forces an organizational conversation that would
never happen without it. Without measurement, toil is invisible
and normalized. With measurement, it becomes a quantitative
organizational health indicator that can drive investment in
automation and appropriate system scope decisions.

**When to use it:**
Toil measurement is appropriate for any SRE team. Even without
formal SLOs, tracking the toil ratio reveals whether the team is
scaling sub-linearly (good) or linearly (problem). It is the
earliest signal of organizational dysfunction in SRE programs.

**When NOT to use it:**
Do not apply the toil framework to work that is inherently manual
and valuable, such as deep incident analysis, capacity planning
for novel workloads, or stakeholder communication. These are not
automatable and have enduring value - they are engineering work.

**Alternatives:**
- DORA metrics (deployment frequency, lead time, change failure rate, MTTR)
- Interrupt-driven work tracking (Basecamp-style)
- Sprint velocity tracking

**First-principles derivation:**
SRE teams scale sub-linearly with systems because they automate
manual work. The toil framework measures the degree to which this
automation is happening. High toil = not automating = linear growth.
Low toil = automating = sub-linear growth. The 50% cap is the
boundary between "sustainable SRE model" and "operations team with
SRE title."

---

### 💻 Code Example

**Example 1: Toil automation - certificate rotation**

```python
# BAD: manual certificate rotation procedure
# (classic toil - repetitive, manual, automatable)
# Step 1: Log into bastion host
# Step 2: ssh to each service host
# Step 3: run certbot renew
# Step 4: restart nginx
# Step 5: verify certificate date
# Step 6: update ticket
# Time: 45 minutes per service, 12 services = 9 hours

# GOOD: automated certificate rotation with cert-manager
# in Kubernetes (eliminate the toil entirely)
# cert-manager automatically handles renewal and rotation

# cert-manager Certificate resource (applied once):
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-tls
  namespace: production
spec:
  secretName: api-tls-secret
  duration: 2160h # 90 days
  renewBefore: 720h # renew 30 days before expiry
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - api.example.com
```

> **Code walkthrough:** The BAD approach is classic toil - a 9-hour
> monthly manual process across 12 services. The GOOD approach
> eliminates the toil entirely using cert-manager: the Kubernetes
> operator automatically detects certificates within 30 days of
> expiry and renews them without human intervention. This is the
> SRE principle of applying software engineering to operations -
> the 9 hours of monthly toil becomes 0 hours after a one-time
> configuration investment.

**Example 2: Toil measurement script**

```python
#!/usr/bin/env python3
# Toil measurement via PagerDuty alert categorization
# BAD: no toil tracking - team has no visibility
# into whether they are above the 50% cap

# GOOD: automated toil tagging from alert history
import requests
from datetime import datetime, timedelta

PAGERDUTY_API_KEY = "pd_api_key"  # from environment
TOIL_ALERT_PATTERNS = [
    "CertificateExpiringSoon",
    "ManualRestartRequired",
    "DiskSpaceHigh",      # auto-remediated but noisy
    "ScheduledMaintenance",
]

def get_alerts_last_30_days():
    headers = {
        "Authorization": f"Token token={PAGERDUTY_API_KEY}",
        "Accept": "application/vnd.pagerduty+json;version=2"
    }
    since = (datetime.now() - timedelta(days=30)).isoformat()
    response = requests.get(
        "https://api.pagerduty.com/incidents",
        headers=headers,
        params={"since": since, "limit": 500}
    )
    return response.json()["incidents"]

def classify_toil(alerts):
    toil_count = 0
    total = len(alerts)
    for alert in alerts:
        title = alert.get("title", "")
        if any(p in title for p in TOIL_ALERT_PATTERNS):
            toil_count += 1
    return toil_count, total, toil_count/total

toil, total, ratio = classify_toil(get_alerts_last_30_days())
print(f"Toil alerts: {toil}/{total} = {ratio:.1%}")
print(f"Status: {'ABOVE CAP' if ratio > 0.5 else 'OK'}")
```

> **Code walkthrough:** This script categorizes PagerDuty alerts
> as toil or engineering based on known patterns. The BAD state
> is having no measurement at all, which makes the 50% cap
> unenforced by default. The GOOD approach runs monthly and
> produces a toil ratio. When the ratio exceeds 50%, the team
> knows to investigate which alert categories are driving toil
> and prioritize automation for those categories. The script is
> a starting point - in production, add more sophisticated
> pattern matching and integration with the team's SLO dashboard.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Toil is manual, repetitive, automatable work that grows with
> the production system. Examples: manually restarting crashed
> services, processing access tickets, rotating certificates by
> hand. The SRE 50% rule: if more than half of an SRE's time is
> toil, the team must automate the top toil sources or return
> some systems to development teams. Toil is measured by classifying
> each task (alert response, ticket, manual operation) as toil
> or engineering work, then tracking the ratio.

*Push deeper:* Explain the six criteria that distinguish toil from
other valuable work. Postmortem writing is not toil (has enduring
value). Diagnosing a new failure mode is not toil (produces knowledge).
Only work that is manual, repetitive, automatable, tactical, valueless,
and linear-scaling counts as toil.

---

**Senior / Staff (5+ years):**
> The most important thing about toil reduction is that it requires
> making toil visible first. Most SRE teams underestimate their
> toil ratio by 20-30% because they do not track it systematically.
> When I join a new SRE team, the first thing I do is run a two-week
> toil measurement sprint: every SRE logs each interruption and
> classifies it as toil or engineering. The results always surprise.
>
> The highest-leverage toil reduction projects are not the ones
> that take the most time to execute, but the ones that fragment
> deep engineering work. A 3 AM on-call page for a self-resolving
> condition costs more than its 15-minute resolution - it costs the
> next morning's engineering productivity. Those "low-impact, high-
> frequency" alerts are the highest-priority toil to eliminate.

*Push deeper:* Staff angle: "The toil cap is an organizational
forcing function, not just a team health metric. When I present
'toil exceeds 50%' data to engineering leadership, the question
it forces is: are we staffing an SRE team (sub-linear scaling
through automation) or a traditional ops team (linear scaling
through headcount)? That question can only be answered with data."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| All manual work is toil | Manual work with enduring value (postmortems, novel incident investigation, architecture reviews) is not toil - toil requires all six criteria |
| The 50% toil cap means SREs should do no operations | SREs should do operations work; the cap means at least 50% of time must be engineering work that improves the system, not just operating it |
| Toil is bad and should be eliminated entirely | Some toil is irreducible; the goal is to manage it below 50% and continuously reduce it, not achieve 0% |
| On-call response is always toil | On-call response for novel incidents that generates learning and system improvement is not toil; only repetitive, automatable on-call responses are toil |
| Automating toil is always worth doing | Toil reduction projects have a cost-benefit ratio; eliminating 5 minutes per month of toil with a 2-month engineering project is not worth doing |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Toil unmeasured, team grows linearly**

*Symptom:* SRE team headcount grows every year. Each new service
added requires "one more SRE." Engineers are always busy but nothing
seems to improve. On-call burden remains constant per engineer
regardless of team size.

*Root cause:* Toil is not measured and therefore not managed.
Headcount is added as the naive solution to operational load.
The organization is paying for a traditional ops team at SRE
salaries.

*Diagnostic:*
```
Measure toil ratio immediately:
  Ask each SRE: last 5 working days, what fraction
  of your time was spent on repetitive manual work
  vs. engineering projects?
  Average the responses.

If answer > 50%: team is above the toil cap.
If answer "I don't know": toil is not measured
  and the problem is invisible.
```

*Fix:* Implement toil tracking immediately. Identify the three
highest-toil sources. Build automation for the top source within
one quarter. Report progress monthly.

*Prevention:* Require every new SRE hire justification to include
a toil analysis. If toil drives the hire, the investment should
go to automation first.

**Failure 2: Alert fatigue from unautomated toil alerts**

*Symptom:* On-call SREs receive 50-100 alerts per week. Most
require the same response: check the dashboard, confirm it resolved,
acknowledge the alert. Response time degrades. Engineers use
noise-canceling headphones during business hours. On-call is
dreaded.

*Root cause:* Alerts that fire repeatedly for known self-resolving
conditions have not been automated or suppressed. Each alert is
treated as a ticket to close rather than a signal to eliminate.

*Diagnostic:*
```bash
# Check top recurring alerts (Prometheus example):
# In AlertManager, review:
sum by (alertname) (
  ALERTS{alertstate="firing"}
)[7d]
# Or: count alert history in PagerDuty
# by alertname, last 30 days
# Top 5 recurring = top toil candidates
```

*Fix:* For each recurring alert, ask: (a) does it require human
action? If no: suppress or auto-resolve. (b) Does it always require
the same action? If yes: automate the remediation. (c) Is the
underlying issue fixable? If yes: fix the root cause.

*Prevention:* Every alert that fires more than 3 times in a month
for the same reason without a human action should be reviewed in
the weekly on-call retrospective.

**Failure 3: Toil reduction projects deprioritized for features**

*Symptom:* The team acknowledges toil is above 50%. Automation
projects are on the backlog. But every sprint, feature work or
urgent bugs take priority. Toil automation never gets done.
The toil ratio stays above 50%.

*Root cause:* Toil automation has no organizational advocate or
protected time. It competes directly with feature work in the
same planning process.

*Fix:* Protect 20% of each sprint for reliability and toil
automation work. This is non-negotiable: it is the SRE equivalent
of tech debt repayment. If this allocation is consistently
violated, escalate to engineering management.

*Prevention:* In sprint planning, explicitly allocate one SRE
team member per sprint to toil reduction projects only. Track
this allocation as a metric in the team's quarterly reliability
report.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Toil definition, 6 criteria, 50% cap, measurement, reduction |
| Seniority signal | Junior: defines toil; Senior: explains measurement and organizational use |
| Common trap | Calling all manual work toil (missing the 6-criterion definition) |
| Staff differentiator | Toil as organizational forcing function, visibility-first approach |

---

**Q1 [JUNIOR]: What is toil and how does SRE define it?**

*Why they ask:* SRE vocabulary check. The 6-criterion definition
reveals depth of understanding.

*Likely follow-up:* "Give me three examples of toil on an SRE team."

Toil is operational work that is manual, repetitive, automatable,
tactical (reactive), has no enduring value, and scales linearly
with service growth. All six criteria must apply.

Examples: manually restarting a service that crashes on a known
pattern (manual, repetitive, automatable, scales with services),
processing access request tickets that could be self-service
(manual, repetitive, automatable), responding to a noisy alert
that always self-resolves (manual, repetitive, automatable, no
value since the human action is "acknowledge").

Not toil: investigating a new production failure mode (enduring
value - produces knowledge that improves the system), writing a
postmortem (enduring value), capacity planning for a new architecture
(strategic, not tactical).

The key criterion is "automatable" - there must be a way to replace
the human action with software. If the work requires judgment that
cannot currently be codified, it is not toil even if it is repetitive.

*What separates good from great:* Most candidates say "repetitive
work." Great candidates give all six criteria and explain which
ones distinguish toil from valuable manual work.

---

**Q2 [MID]: How does an SRE team measure its toil ratio?**

*Why they ask:* Practical measurement question. Most candidates
know what toil is but have not measured it.

*Likely follow-up:* "What do you do when the measurement reveals
toil is above 50%?"

The simplest approach: ask each SRE to log every 30-minute block
as "toil" or "engineering" for two weeks. Calculate the average
ratio across the team. This is imprecise but fast and produces
immediately useful data.

A more systematic approach: categorize work items in the ticket
system. Label each PagerDuty incident, Jira ticket, and manual
task as "toil" or "engineering." Run a monthly report: (toil
label count) / (total items). This requires a consistent labeling
discipline.

The most automated approach: identify toil alert patterns (known
self-resolving conditions, known automated remediation needed) and
tag them in the alerting system. Run a monthly dashboard: (toil-
tagged alerts) / (total alerts).

When measurement reveals toil above 50%: identify the three highest-
toil sources by volume and time cost. Create automation projects for
each in the backlog. Prioritize the highest-time-cost source first.
Report progress monthly.

*What separates good from great:* Most candidates describe logging
time. Great candidates give the systematic alert-categorization
approach and describe what to do with the data.

---

**Q3 [MID]: What is the difference between on-call response
and toil?**

*Why they ask:* Common confusion - not all on-call work is toil.
The distinction reveals nuanced understanding.

*Likely follow-up:* "Can incident response become toil?"

On-call incident response is not automatically toil. The test:
does this response meet all six toil criteria? Many on-call responses
do not. Investigating a novel failure mode produces enduring knowledge
(eliminates the "no enduring value" criterion). A complex incident
requiring judgment is not automatable (eliminates the "automatable"
criterion).

However, incident response can become toil when the response is
identical every time: acknowledge alert, restart service, close
ticket. If the same alert fires weekly and the response is always
"restart the service," it meets all six toil criteria: manual,
repetitive, automatable, tactical, no enduring value (it will happen
again next week), and linear with the number of services.

The production diagnosis: when on-call SREs describe their work as
"we get paged, we restart things, it gets better" - that is toil
masquerading as incident response.

The fix: for any on-call response pattern that repeats more than
three times with the same action, create a runbook automation project.
The goal is not to eliminate on-call, but to ensure on-call responses
require genuine engineering judgment, not just procedure execution.

*What separates good from great:* Most candidates separate on-call
and toil as distinct categories. Great candidates explain when on-
call becomes toil (the identical-response pattern) and the fix.

---

**Q4 [SENIOR]: How do you prioritize which toil to automate first?**

*Why they ask:* Decision framework question testing analytical
approach to toil reduction.

*Likely follow-up:* "What is the ROI calculation for a toil
automation project?"

I prioritize toil reduction using three dimensions: impact per
occurrence (high = pages at 3 AM, low = schedulable ticket),
frequency per month (high = daily, low = monthly), and automation
complexity (low = simple script, high = complex orchestration).

The highest-priority toil: high impact * high frequency * low
automation complexity. A self-resolving alert that wakes on-call
engineers every night but requires a 2-line auto-remediation script
is the highest-ROI toil reduction project.

The ROI calculation: (time cost per occurrence * frequency per
month * 12 months) / automation investment. An alert that takes
30 minutes to respond to, fires 4 times per month, has a 2-week
automation investment: (0.5h * 4 * 12) / (80h) = 24h saved / 80h
invested = 0.3x annual ROI. This is breakeven in 40 months - low
priority. An alert that takes 1 hour to respond to, fires 10 times
per month: (1h * 10 * 12) / (40h) = 120h / 40h = 3x annual ROI.
High priority.

The non-quantifiable dimension: on-call interruption quality of
life. An alert that wakes engineers at night costs far more than
its resolution time in productivity, morale, and retention. I add
a 3x multiplier to off-hours toil in the prioritization.

*What separates good from great:* Most candidates say "automate
the most common things first." Great candidates give a ROI
framework with specific dimensions and explain the off-hours
multiplier.

---

**Q5 [SENIOR]: How does the 50% toil cap affect SRE hiring
decisions?**

*Why they ask:* Organizational design question testing whether
the candidate understands the toil cap as a management tool.

*Likely follow-up:* "How do you tell the difference between
'we need another SRE' and 'we have a toil problem'?"

The 50% toil cap transforms hiring decisions. In a traditional ops
model, adding a service means adding headcount - a linear relationship.
In the SRE model, adding a service should be absorbed by automation,
meaning headcount growth is sub-linear.

When a team requests additional SRE headcount, the first question
is: what is the current toil ratio? If the toil ratio is below 50%,
the team has engineering capacity they are not fully using - adding
headcount to a team with 30% toil is wrong; the right investment
is in the engineering projects that are not getting done.

If the toil ratio is above 50%, the cause matters. If toil comes
from high-toil systems that are not improving, the right response
is to return those systems to development teams, not to hire. If
toil comes from genuinely irreducible operations work (security
compliance, human judgment required), then headcount may be
justified.

"We need another SRE" is justified when: toil ratio is below 50%
(team is healthy, growth is from system complexity), or when
the irreducible operations work genuinely requires more headcount
than automation can absorb.

"We have a toil problem" is the diagnosis when: ratio is above 50%
for two consecutive quarters, the highest-toil sources are
automatable but not automated, and headcount additions consistently
fail to reduce the on-call burden per engineer.

*What separates good from great:* Most candidates describe toil
as something to manage. Great candidates connect it to the hiring
decision framework and describe the "automate first, hire second"
principle.

---

**Q6 [STAFF]: How does a Platform Engineering approach help
reduce toil across an organization, not just within the SRE team?**

*Why they ask:* Staff-level organizational scale question connecting
toil reduction to platform strategy.

*Likely follow-up:* "What is the difference between reducing SRE
toil and reducing developer toil?"

Platform Engineering addresses toil at an organizational scale by
encoding best practices into the developer platform so that teams
do not generate toil in the first place.

Traditional toil reduction: the SRE team automates repetitive tasks
they have to do for specific services. This scales to the number
of services the SRE team owns.

Platform Engineering approach: the platform team builds self-service
tooling that eliminates the category of toil for all teams. Instead
of SRE automating certificate rotation for the services they own,
the platform provides cert-manager (or equivalent) as a standard
component: all services on the platform get automated certificate
rotation without SRE involvement.

Developer toil is the complement: if developers need to file an
SRE ticket to deploy a new environment, debug a production issue,
or configure monitoring, that is developer toil generated by the
SRE team's processes. Platform Engineering reduces both SRE toil
and developer toil simultaneously.

The metric for platform toil reduction: "golden path adoption rate"
- the fraction of teams using the standard platform for each
capability. When 90% of teams use cert-manager for certificate
management, the toil associated with manual certificate management
is eliminated for 90% of services without any per-service automation.

*What separates good from great:* Most candidates describe SRE
toil reduction at the team level. Great candidates describe the
platform multiplier - how encoding toil elimination into the
platform eliminates it for all services simultaneously.

---

**Q7 [STAFF]: How do you prevent the toil metric from being
gamed in an organizational performance context?**

*Why they ask:* Organizational integrity question for staff
candidates building reliability programs.

*Likely follow-up:* "What are the failure modes of using toil
reduction as an OKR?"

When toil ratio becomes an OKR or performance metric, two gaming
patterns emerge:

The first: reclassifying toil as "engineering work" to improve
the number. If on-call responses are relabeled as "operational
analysis" or "production debugging," the toil ratio drops without
any actual reduction in toil. The solution: audit the classification
with a third-party review (engineering manager spot-checking
classifications) and use outcome-based validation (did on-call
burden per engineer actually decrease?).

The second: eliminating easy-to-measure toil while ignoring harder
toil. Teams automate low-complexity alerts (improving the count-
based metric) while leaving the highest-impact but harder-to-
automate toil untouched. The solution: track both count-based
toil ratio and time-based toil ratio. Time-based measurement is
harder to game because it requires actually reducing high-duration
toil.

My recommendation: use toil ratio as a health indicator and leading
predictor, not as an OKR. The outcome OKRs should be: on-call burden
per engineer per week (target: < 5 hours), number of toil automation
projects shipped per quarter (target: 2-3), and SRE team attrition
rate (high attrition is a reliable toil problem signal). These
are harder to game and more directly tied to organizational health.

*What separates good from great:* Most candidates describe toil
measurement positively. Great candidates describe the gaming risks
and propose a measurement framework that resists gaming by using
outcome-based validation.

---

---

# Availability and Reliability Fundamentals

🎯 Interview Weight: high - foundational concepts that underpin
all SRE practice; mastery of the mathematics prevents the most
common SLO calculation errors in interviews.

---

### 🎯 Model Answer

**30 seconds:**
> Availability is the fraction of time a service is operational
> and accessible to users. Reliability is the broader concept
> capturing whether a system performs its intended function over
> time. In SRE, availability is typically measured as a ratio of
> successful operations to total operations (request-based), or
> as uptime fraction over a measurement window (time-based).
> "Nines" - 99%, 99.9%, 99.99% - are a shorthand for availability
> levels with dramatically different downtime allowances.

**3 minutes (Senior):**
> Availability and reliability are related but distinct. Availability
> is a point-in-time or time-window measurement: what fraction of
> the time was the service accessible? Reliability is a broader
> behavioral property: does the system consistently do what it is
> supposed to do, including correct behavior, not just uptime?
>
> In SRE practice, availability is typically measured in two ways:
> time-based and request-based. Time-based availability = (uptime /
> total time). Request-based availability = (successful requests /
> total requests). Request-based is preferred in modern services
> because it accounts for partial degradation: a service might be
> running but serving 10% error rates, which time-based measurement
> would call "available" but request-based would correctly identify
> as degraded.
>
> The "nines" shorthand is intuitive but the actual downtime
> differences are dramatic. Going from 99% to 99.9% is not a 0.9%
> improvement - it is a 10x reduction in allowed downtime (87.6 hours
> per year vs. 8.76 hours). Going from 99.9% to 99.99% is another
> 10x (8.76 hours vs. 52.6 minutes). Each additional nine multiplies
> the engineering cost while reducing the allowed downtime by 10x.
>
> The system availability for services with dependencies is the
> product of component availabilities. If Service A depends on
> Services B and C, and each has 99.9% availability, the composite
> availability is 0.999 * 0.999 = 99.8%. This "SLO tax" means complex
> microservices architectures cannot achieve the same availability
> as monolithic services with fewer dependencies.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "The availability-reliability distinction
is important at the architecture level. A service can be 99.99%
available but unreliable if it returns incorrect results for some
requests. Correctness failures are often harder to detect than
availability failures and are not captured by standard SLI
measurements."

*Adapting down:* Junior: "Availability is the percentage of time
a service is working. 99.9% availability means 8.76 hours of
allowed downtime per year. 99.99% means 52.6 minutes per year.
The key insight: each additional nine is 10x harder to achieve
and 10x less downtime allowed."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about availability and reliability
fundamentals - let me walk through the definitions, the nines math,
and how they connect to SLO design."

**(2) First principles:** "From first principles, a service is
'available' when it can fulfill user requests. Availability is the
fraction of time (or requests) when this is true. Reliability is
the broader question: does the service consistently fulfill requests
correctly? Both are needed for a complete reliability picture."

**(3) Bridge:** "Availability is like a store's open hours.
A store that is 99.9% available (hours: open) is closed for 8.76
hours per year. Reliability is like whether the store has what
you need when you walk in. A store can be open all year (available)
but consistently out of stock (unreliable)."

---

### 📘 Concept Explanation

**What it is:**
Availability is the quantitative measure of a service's ability to
fulfill requests during a measurement window. Reliability encompasses
availability but also includes correctness, consistency, and
appropriate performance under stress. In SRE, "availability" is
typically used specifically for the fraction of time or requests
that the service is operational, while "reliability" is the broader
property that SLOs are designed to measure.

**The problem it solves:**
Without a quantitative definition of availability, reliability
discussions are subjective. "The service was down" vs. "the service
was slow" vs. "the service returned errors" all represent different
failure modes that a quantitative availability measurement captures.

**How it works:**

```
AVAILABILITY MODELS
===================

TIME-BASED AVAILABILITY
  A = MTTF / (MTTF + MTTR)
  MTTF = Mean Time To Failure
  MTTR = Mean Time To Repair

  Example:
    System fails every 100 hours (MTTF = 100h)
    Takes 1 hour to repair (MTTR = 1h)
    A = 100 / (100 + 1) = 99.01%

REQUEST-BASED AVAILABILITY (preferred for SLOs)
  A = successful requests / total requests
  Captures partial degradation
  Time-based misses: 10% error rate but running

NINES TABLE
  Level   Avail    Down/Year  Down/Month Down/Week
  99%     2 nines  87.6h      7.3h       1.68h
  99.5%   2.5      43.8h      3.65h      50 min
  99.9%   3 nines  8.76h      43.8 min   10.1 min
  99.95%  3.5      4.38h      21.9 min   5.04 min
  99.99%  4 nines  52.6 min   4.38 min   1.01 min
  99.999% 5 nines  5.26 min   26.3 sec   6.05 sec

COMPOSITE AVAILABILITY (dependencies)
  If A depends on B and C:
  A_composite = A_A * A_B * A_C (independent failures)
  Example:
    A = 99.9%, B = 99.9%, C = 99.9%
    Composite = 0.999^3 = 99.7%

MTTR AND AVAILABILITY
  Availability = MTTF / (MTTF + MTTR)
  Doubling MTTF has diminishing returns at high availability
  Halving MTTR improves availability linearly at high availability
  SRE insight: faster incident detection and resolution
    improves availability more efficiently than
    preventing all failures.
```

**The key insight:**
The nines math reveals that each additional nine is exponentially
harder to achieve. Going from 99% to 99.9% requires 10x reduction
in downtime. Going from 99.9% to 99.99% requires another 10x.
This means the engineering investment for five nines is not 1.67x
more than for three nines - it is potentially 100x more. Understanding
this math is essential for setting realistic SLOs.

**When to use it:**
These fundamentals apply whenever designing SLOs, evaluating
infrastructure architectures, or having reliability investment
conversations with stakeholders. The MTTF/MTTR model is particularly
useful for comparing the cost-effectiveness of prevention (increasing
MTTF) vs. response (decreasing MTTR).

**When NOT to use it:**
The time-based availability model is inappropriate for modern
microservices where partial degradation is common and the binary
up/down model does not capture the user experience. Use request-
based availability (SLI ratio) for SLOs.

**Alternatives:**
- DORA metrics (MTTR, change failure rate, deployment frequency)
- Apdex score (weighted availability + performance index)
- P99 latency as the availability proxy for latency-sensitive services

**First-principles derivation:**
A service is available when it can fulfill a user request. The
fraction of time (or requests) when it is available is availability.
This fraction depends on how often it fails (MTTF) and how long
each failure lasts (MTTR). The goal of SRE reliability engineering
is to maximize MTTF (through redundancy, chaos engineering, better
software) and minimize MTTR (through better monitoring, faster
diagnosis, automated remediation).

---

### 💻 Code Example

**Example 1: Composite availability calculation**

```python
# Availability calculator for microservices
# BAD: assuming service availability equals component max
# (wrong - composite availability is multiplicative)

service_a_avail = 0.999  # 99.9%
service_b_avail = 0.999  # 99.9%
service_c_avail = 0.999  # 99.9%

# WRONG: assuming additive or equal to weakest link
wrong_composite = min(
    service_a_avail, service_b_avail, service_c_avail
)
print(f"Wrong: {wrong_composite:.3%}")
# Prints: Wrong: 99.900% (overestimates availability)

# GOOD: multiplicative model for independent failures
correct_composite = (
    service_a_avail
    * service_b_avail
    * service_c_avail
)
print(f"Correct: {correct_composite:.3%}")
# Prints: Correct: 99.700% (0.2% lower than any component)

# Design implication:
# To achieve 99.9% end-to-end:
# Each of 3 components must achieve:
import math
target = 0.999
n_components = 3
required_per_component = target ** (1/n_components)
print(f"Required per component: {required_per_component:.5%}")
# Required per component: 99.96668%
```

> **Code walkthrough:** The BAD approach uses `min()` which takes
> the weakest component's availability as the composite - this
> overestimates composite availability. The GOOD approach multiplies
> component availabilities: three 99.9% components produce 99.7%
> composite availability, 0.2% below any individual component.
> The key insight from the last calculation: to achieve 99.9% end-
> to-end across 3 independent components, each component must achieve
> 99.967% - significantly stricter than the system-level target. This
> is the "SLO tax" that SRE teams must account for when designing
> microservices SLOs.

**Example 2: MTTF/MTTR availability calculation**

```python
# MTTF/MTTR availability model
# Shows the relative value of prevention vs. response

def availability(mttf_hours, mttr_hours):
    """Time-based availability from MTTF and MTTR."""
    return mttf_hours / (mttf_hours + mttr_hours)

# Current state: fails every 100 hours, 2h MTTR
current = availability(mttf_hours=100, mttr_hours=2)
print(f"Current: {current:.4%}")
# Current: 98.0392%

# Option A: reduce failures (double MTTF = 200h)
# Engineering investment: major reliability project
option_a = availability(mttf_hours=200, mttr_hours=2)
print(f"Option A (2x MTTF): {option_a:.4%}")
# Option A (2x MTTF): 99.0099%

# Option B: reduce recovery time (halve MTTR = 1h)
# Engineering investment: better runbooks + monitoring
option_b = availability(mttf_hours=100, mttr_hours=1)
print(f"Option B (0.5x MTTR): {option_b:.4%}")
# Option B (0.5x MTTR): 99.0099%

# INSIGHT: both produce the same improvement
# At low MTTR, further reduction has more impact:
option_b2 = availability(mttf_hours=100, mttr_hours=0.25)
print(f"Option B2 (0.25h MTTR): {option_b2:.4%}")
# Option B2 (0.25h MTTR): 99.7506%
# Better MTTR gives more availability than better MTTF
```

> **Code walkthrough:** This model reveals a critical SRE insight:
> at high availability levels, reducing MTTR (faster recovery) is
> more effective than increasing MTTF (preventing failures). Options A
> and B produce identical availability improvement, but further MTTR
> reduction (0.25h) gives substantially better results than further
> MTTF improvement. This is why SRE invests heavily in monitoring,
> alerting, runbooks, and automated remediation - all MTTR reducers.
> Faster detection and recovery is often more efficient than
> preventing every failure.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Availability is the percentage of time (or requests) that a
> service works correctly. The "nines" shorthand: 99.9% means
> 8.76 hours of downtime per year; 99.99% means 52 minutes. Each
> additional nine is 10x harder to achieve and allows 10x less
> downtime. Reliability is broader: availability plus correctness
> plus performance. In SRE, we set SLOs based on availability
> (fraction of good requests) because it directly measures what
> users experience.

*Push deeper:* Explain composite availability: if a service depends
on two components each with 99.9% availability, the service can
only achieve 0.999 * 0.999 = 99.8% availability at best.

---

**Senior / Staff (5+ years):**
> The most important insight from availability theory for SRE
> practice is the MTTF/MTTR trade-off. The formula A = MTTF /
> (MTTF + MTTR) shows that at high availability levels, reducing
> MTTR (faster recovery) improves availability faster than increasing
> MTTF (fewer failures). This is why SRE invests heavily in
> monitoring, alerting, and runbooks: not to prevent every failure,
> but to minimize how long each failure lasts.
>
> At 99.9% availability, an MTTR reduction from 2 hours to 30
> minutes has a larger availability impact than doubling the mean
> time between failures. This insight drives architecture decisions:
> invest in redundancy and fast failover rather than trying to make
> components fail never.

*Push deeper:* Staff angle: "The composite availability calculation
is the quantitative basis for microservices SLO design. If you want
a user-facing service to achieve 99.9%, and it has 10 dependencies,
each dependency must achieve 99.99% (0.999^(1/10) = 0.9999). This
is the hidden cost of microservices architecture that SRE teams
must surface in architecture reviews."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| "Five nines" (99.999%) is the gold standard for all services | Five nines requires 5 minutes of allowed downtime per year and costs exponentially more than four nines; most services do not justify this investment |
| Availability and reliability are synonyms | Availability is one component of reliability; a service can be highly available but unreliable if it returns incorrect results or behaves inconsistently |
| Time-based availability is the best measure | Request-based availability captures partial degradation that time-based measurement misses; a service can be running but serving errors, which time-based calls "available" |
| Each additional nine is proportionally harder | Each additional nine is 10x harder because it requires 10x less downtime; the engineering cost grows exponentially |
| A service with better components always has better availability | Composite availability is the product of component availabilities; more components with more dependencies can lower composite availability even when each component is excellent |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Availability goal set at five nines without
business justification**

*Symptom:* Engineering team is spending enormous effort on
redundancy and fail-safes to achieve 99.999% availability for
an internal analytics dashboard. The dashboard is used for
weekly business reviews. On-call SREs are paged for < 1 minute
outages.

*Root cause:* Five nines was set as an organizational prestige
target, not based on actual business requirements. 5 minutes of
downtime per year is more stringent than the business actually
needs.

*Diagnostic:*
```
Ask the business stakeholder:
  "If the analytics dashboard is unavailable for
  30 minutes during business hours, what is the
  impact?"
  If answer is "I would refresh the page later":
    99% (87h downtime/year) is more than adequate.
  If answer is "We cannot run the weekly review
  meeting without it":
    99.9% (8.76h/year) is appropriate.
  Five nines requires: never down for > 5 min/year.
```

*Fix:* Re-baseline the SLO against actual business requirements.
Present the nines table with downtime equivalents to stakeholders.
Let business impact determine the SLO, not engineering aspiration.

*Prevention:* Before setting any SLO, ask: "What is the cost to
the business of one hour of downtime? One day?" Map the answer
to the nines table.

**Failure 2: Treating availability as binary - up or down**

*Symptom:* System is reported as "available" because HTTP responses
are being returned. However, 30% of responses are 500 errors and
response times are 10x normal. Users are complaining. Operations
team says "the service is up."

*Root cause:* Time-based availability measurement (service process
running = available) is being used instead of request-based
availability (successful requests / total requests).

*Diagnostic:*
```promql
# Time-based check (binary - wrong for this issue):
up{job="web-service"}
# Returns: 1 (running)

# Request-based availability SLI (correct):
sum(rate(http_requests_total{status=~"2.."}[5m]))
/ sum(rate(http_requests_total[5m]))
# Returns: 0.70 (70% availability - critically degraded)
```

*Fix:* Replace time-based monitoring with request-based SLI
monitoring. The service is "available" only when the SLI is above
the SLO threshold, not when the process is running.

*Prevention:* Define "available" as a request-based SLI ratio
in the SLO document. Make it explicit that process health != service health.

**Failure 3: Composite availability not accounted for in SLO design**

*Symptom:* A user-facing service achieves 99.9% availability when
measured in isolation, but users report significantly more failures.
Detailed analysis shows the service calls five dependencies in the
critical path, each with 99.9% availability.

*Root cause:* The SLO was set based on the service's own component
availability, not accounting for dependency failures that affect
the user experience.

*Diagnostic:*
```python
# Calculate composite availability
# Service + 5 dependencies, all at 99.9%
composite = 0.999 ** 6  # service + 5 deps
print(f"{composite:.3%}")
# Prints: 99.401% - actual user-visible availability
# SLO was 99.9% but users see 99.4%
```

*Fix:* Map the full dependency graph for the SLO measurement.
Either measure the composite (user-visible) availability as the
SLI, or require each dependency to achieve a stricter SLO
(99.967% per component to achieve 99.9% composite with 5 deps).

*Prevention:* In production readiness reviews, require the service
team to list all synchronous dependencies and compute the composite
availability. The SLO must be achievable given the dependency
availability budget.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | Nines math, MTTF/MTTR, composite availability, request vs time-based |
| Seniority signal | Junior: knows the nines; Senior: explains composite and MTTF/MTTR |
| Common trap | Treating time-based availability as equivalent to request-based |
| Staff differentiator | Composite availability design implications for microservices SLO |

---

**Q1 [JUNIOR]: What does 99.9% availability mean in practical
downtime terms?**

*Why they ask:* Mathematical literacy check. The nines are
shorthand every SRE must be able to convert.

*Likely follow-up:* "What is the difference between 99.9%
and 99.99%?"

99.9% availability means 0.1% of the time is allowed for downtime.
In practical terms:
- Per year: 0.001 * 8,760 hours = 8.76 hours of allowed downtime
- Per month (30 days): 0.001 * 43,200 minutes = 43.2 minutes
- Per week: 0.001 * 10,080 minutes = 10.1 minutes

The difference between 99.9% and 99.99% is dramatic:
- 99.99%: 52.6 minutes per year, 4.38 minutes per month
- Difference: 99.9% allows 10x more downtime than 99.99%

This 10x relationship holds at every nine boundary. Going from
two nines (99%) to three nines (99.9%) is also a 10x downtime
reduction (87.6h -> 8.76h). This is why each additional nine
is exponentially harder and more expensive to achieve.

*What separates good from great:* Most candidates know the nines
values. Great candidates explain the 10x relationship between
each nine and spontaneously mention the engineering cost implication.

---

**Q2 [JUNIOR]: What is the difference between availability
and reliability?**

*Why they ask:* Vocabulary precision check. The distinction
matters for SLO design.

*Likely follow-up:* "How would you measure reliability in a
way that availability doesn't capture?"

Availability is a specific, measurable property: the fraction of
time (or requests) that a service is accessible and responsive.
Reliability is a broader property that encompasses availability
but also includes correctness (does the service return the right
answer?), consistency (does it behave the same way every time?),
and resilience (does it continue to function under stress or
partial failure?).

A service can be highly available but unreliable. Example: a
recommendation service that is always up but returns random
recommendations instead of relevant ones has 100% availability
but zero reliability from a functional perspective. A financial
calculation service that returns incorrect results 5% of the time
is available but unreliable.

In SRE practice, we primarily measure availability through SLIs.
Reliability in the fuller sense includes data correctness testing,
chaos engineering, and functional validation that go beyond uptime
monitoring.

*What separates good from great:* Most candidates use availability
and reliability interchangeably. Great candidates give the correctness
example and explain why functional reliability requires different
measurement than availability.

---

**Q3 [MID]: How does the MTTF/MTTR model help prioritize
reliability investments?**

*Why they ask:* Mathematical reliability engineering question
testing whether the candidate can apply theory to investment decisions.

*Likely follow-up:* "Which is more valuable: preventing failures
or recovering faster?"

The MTTF/MTTR model expresses availability as: A = MTTF /
(MTTF + MTTR). This shows that availability improves when MTTF
increases (fewer failures) or MTTR decreases (faster recovery).

The investment implication: at high availability levels, MTTR
reduction has more impact per unit of investment than MTTF improvement.
Consider a service at 99% availability (MTTF=99h, MTTR=1h):

Doubling MTTF (major reliability investment): A = 198/(198+1) = 99.5%
Halving MTTR (monitoring + runbook improvement): A = 99/(99+0.5) = 99.5%

Both produce the same result, but halving MTTR is typically easier
(runbook improvements, faster alerting, automated remediation) than
doubling MTTF (fundamental reliability engineering). At very high
MTTR fractions, MTTR reduction dominates.

Practical guidance: invest in monitoring, alerting, and automated
remediation first (MTTR reduction). These are high-ROI, fast to
implement. Invest in architectural reliability (redundancy, graceful
degradation) second (MTTF improvement). These take longer and cost
more.

*What separates good from great:* Most candidates focus on preventing
failures. Great candidates apply the MTTF/MTTR model mathematically
and explain why MTTR reduction is typically the more efficient
investment at high availability levels.

---

**Q4 [SENIOR]: How does composite availability affect SLO design
in a microservices architecture?**

*Why they ask:* Architecture-level availability math that staff
candidates must know for system design decisions.

*Likely follow-up:* "What is the maximum availability a service
can achieve with 10 dependencies, each at 99.9%?"

In a microservices architecture where Service A calls B, C, D
synchronously, the composite availability is the product of
all availabilities (assuming independent failures):
Composite = A_A * A_B * A_C * A_D

With 10 dependencies each at 99.9%: 0.999^10 = 99.005%

This is the maximum availability the user-facing service can achieve,
regardless of how reliable Service A itself is. This has two SLO
design implications:

First, the system SLO must account for dependency availability.
An SLO of 99.9% for a service with 10 dependencies each at 99.9%
is mathematically unachievable. The honest SLO ceiling is ~99%.

Second, the dependency SLOs must be set tighter than the system
SLO. To achieve 99.9% composite with 10 dependencies, each must
achieve: 0.999^(1/10) = 99.99%.

The practical responses: reduce synchronous dependencies (async
calls break the multiplication chain), implement graceful degradation
(avoid returning errors when non-critical dependencies fail), and
set upstream SLOs that account for the composite budget.

*What separates good from great:* Most candidates know dependencies
affect availability. Great candidates compute the composite
mathematically and derive the required per-dependency SLO.

---

**Q5 [SENIOR]: What is the difference between time-based and
request-based availability, and when is each appropriate?**

*Why they ask:* SLI measurement design question. The choice of
measurement model affects what failures the SLO captures.

*Likely follow-up:* "Can a service be time-available but
request-unavailable at the same time?"

Time-based availability: (time service is "up" / total time). "Up"
is typically defined as the service process running and responding
to health checks. Simple to measure, but coarse: a service that
is running but returning 30% errors is "100% available" by this
measure.

Request-based availability: (successful requests / total requests).
"Successful" is defined by the SLI (typically 2xx HTTP responses).
Captures partial degradation: a service with 30% error rate has
70% request-based availability even while running.

Yes, they can diverge: a service can be time-available (running,
passing health checks) while being request-unavailable (high error
rate, serving degraded responses).

Time-based is appropriate for infrastructure components where
binary up/down is the relevant failure mode (database servers,
load balancers, network appliances). Request-based is appropriate
for application services where partial degradation is a real failure
mode that users experience.

For SLOs, request-based availability is almost always preferred
because it captures what users experience. Time-based monitoring
is appropriate for infrastructure health checks, not SLI measurement.

*What separates good from great:* Most candidates use time-based
availability as the default. Great candidates describe the divergence
scenario, explain why request-based is preferred for application
SLOs, and give the specific use case where time-based is appropriate.

---

**Q6 [STAFF]: How do you design availability targets for a
multi-region active-active deployment?**

*Why they ask:* Staff-level architecture question connecting
availability math to real deployment patterns.

*Likely follow-up:* "What availability is theoretically achievable
with three independent regions?"

Multi-region active-active increases composite availability by
parallelizing failure modes. Instead of the multiplicative model
(series failures), a multi-region system uses the complementary
model: the system fails only when all regions fail simultaneously.

If each region has availability A, and regions fail independently,
the multi-region availability is:
A_composite = 1 - (1 - A)^n

For three regions each at 99.9%:
A_composite = 1 - (0.001)^3 = 1 - 0.000000001 = 99.9999999%

This is the theoretical maximum - real deployments have shared
failure modes (DNS, global load balancer, third-party services)
that prevent full independence. A realistic estimate: three regions
at 99.9% produce ~99.99% composite availability (accounting for
5-10% correlated failure probability).

The design implications: for services requiring 99.99%+ availability,
multi-region active-active is the primary architectural lever.
The cost: 3x infrastructure, complex distributed consistency,
and much harder operational burden for the SRE team.

The SRE's role in this design: validate the independence assumption
(do regions share a common database? a global CDN? a cloud provider
control plane?), model the realistic composite with correlation,
and help the team decide if the availability target justifies
the operational complexity.

*What separates good from great:* Most candidates describe multi-
region as "highly available." Great candidates model the availability
mathematically, account for correlated failures, and describe the
trade-off between availability improvement and operational complexity.

---

**Q7 [STAFF]: How do partial availability and graceful degradation
change the availability calculation?**

*Why they ask:* Nuanced reliability engineering question for staff
candidates designing resilient systems.

*Likely follow-up:* "How do you define an SLI for a service with
graceful degradation?"

Graceful degradation breaks the binary available/unavailable model.
A recommendation service that returns generic "popular items" when
its ML model is unavailable is partially available - users get
a response, but not the full-quality response they expect.

This creates two types of availability: functional availability
(fraction of requests that return any response) and quality
availability (fraction of requests that return a full-quality
response). Most availability measurement captures only functional
availability.

For SLO design with graceful degradation: define the SLI to match
the quality level users expect. If users find generic recommendations
acceptable, the SLI is functional availability (returned a response).
If users expect personalized recommendations, the SLI is quality
availability (returned a personalized response). The choice determines
what the error budget measures and what triggers the SLO alert.

The composite availability math changes with graceful degradation:
the service no longer propagates its dependency's unavailability
to the user. If the ML model is unavailable but the service can
degrade gracefully, the service's functional availability is decoupled
from the model's availability. Graceful degradation is therefore
an architectural technique for improving composite availability.

*What separates good from great:* Most candidates treat availability
as binary. Great candidates describe the functional vs. quality
availability distinction, explain how to define SLIs for degraded
modes, and explain how graceful degradation improves composite
availability by breaking the dependency failure propagation chain.
