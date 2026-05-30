---
layout: default
title: "SRE - L3 Capacity Planning"
parent: "SRE"
grand_parent: "SK Interview"
nav_order: 9
permalink: /sre/l3-capacity-planning/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Capacity Planning and Load Forecasting](#capacity-planning-and-load-forecasting) | high |
| 2   | [Performance Degradation and Saturation Analysis](#performance-degradation-and-saturation-analysis) | critical |

---

# Capacity Planning and Load Forecasting

🎯 Interview Weight: high - demonstrates operational maturity;
teams that cannot forecast capacity fail during predictable traffic
spikes, which is one of the most avoidable categories of SRE failure.

---

### 🎯 Model Answer

**30 seconds:**
> Capacity planning is the process of ensuring infrastructure is
> provisioned before demand arrives. SRE capacity planning has three
> parts: load forecasting (predict future demand from historical trends),
> capacity modeling (translate demand into resource requirements), and
> provisioning triggers (automate resource acquisition before saturation).
> The goal is to maintain the headroom that keeps saturation below 80%
> even during peak demand.

**3 minutes (Senior):**
> SRE capacity planning differs from traditional IT capacity planning
> in that it is continuous and data-driven, not annual and intuition-
> driven. The cycle: measure current utilization and demand growth rate,
> model the growth curve (linear, exponential, or seasonal), project
> forward by 3-6 months, provision resources to maintain 80% utilization
> headroom, and set alerts at 70% to trigger the next provisioning cycle.
>
> The load forecasting model selection matters. Most web services have
> a compound growth pattern: long-term linear growth in the user base,
> weekly seasonality (weekday peaks, weekend troughs), and annual seasonality
> (holiday spikes for consumer services, fiscal year patterns for enterprise).
> Using only the long-term growth curve without accounting for seasonality
> produces a service that is fine on average but saturates during every
> holiday.
>
> Decompose the demand signal: trend + seasonality + noise. Forecast
> the trend component, overlay the seasonal multiplier, add headroom
> for noise (unexpected traffic spikes). The resulting forecast drives
> the provisioning schedule.
>
> Capacity planning must account for multiple resource dimensions: CPU,
> memory, network I/O, disk I/O, connection pool limits, queue depth.
> These have different saturation characteristics. A service that is
> provisioned for CPU but not for connection pool limits will fail at
> the database tier long before CPU saturates. The USE method (Utilization,
> Saturation, Errors) for each resource dimension provides the checklist.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about capacity planning and load
forecasting - let me walk through the measurement, modeling, and
provisioning cycle with the common failure modes."

**(2) First principles:** "Infrastructure has a saturation point.
Above 80% utilization for most resources, latency increases non-linearly
(queuing theory: M/M/1 queue). Below 80%, the service is within its
capacity envelope. Capacity planning ensures the service stays below
80% by provisioning ahead of demand."

**(3) Bridge:** "Capacity planning is like water management for a city.
You do not wait for the reservoir to run dry - you track usage trends,
forecast demand growth, and add capacity before it is needed. You also
account for seasonal variation: the summer peak is predictable, so you
plan for it in advance."

---

### 📘 Concept Explanation

**What it is:**
Capacity planning and load forecasting is the process of predicting
future resource demand and ensuring infrastructure is provisioned before
demand arrives. It includes demand modeling, resource utilization
projection, and provisioning trigger automation.

**The problem it solves:**
Without capacity planning, services run at or near saturation because
provisioning is reactive (add capacity when the service is already
slow). Reactive provisioning produces incidents during predictable
traffic spikes.

**How it works:**

```
CAPACITY PLANNING CYCLE
=========================

MEASURE (continuous)
  Per service, per resource dimension (CPU, Memory,
  Network, Disk, Connections):
    current_utilization = used / capacity
    demand_growth_rate = week-over-week % increase
    peak_multiplier = peak_hour / average_hour

FORECAST (monthly)
  3-month demand projection:
    trend_component = time_series_decomposition(
      historical_demand, method="STL"
    )
    seasonal_component = seasonal_multiplier_by_period
    forecast = trend_projection * seasonal_multiplier

CAPACITY MODEL (translate demand to resources)
  For each resource dimension:
    required_capacity = forecast_peak_demand
                       / target_utilization_ceiling
    (target: 0.70 to 0.80)
  Headroom: provision to 60% of capacity at launch
  Alert: at 70% to trigger next provisioning

PROVISIONING (automated)
  Cloud elasticity: auto-scaling groups with predictive
    scaling policies (scale before metrics spike)
  Database: read replica provisioning triggered by
    query volume forecast
  Network: CDN capacity requests submitted 6 weeks
    ahead (provider lead time)

USE METHOD per resource
  Utilization: what fraction of capacity is in use?
  Saturation: is work queuing because capacity full?
  Errors: are requests failing due to capacity limits?
```

**The key insight:**
Most catastrophic capacity failures are predictable in advance. Black
Friday, product launches, viral social media events, fiscal year-end
billing spikes - these are either scheduled or follow observable patterns.
A team that runs capacity reviews monthly and acts on forecasts will
never fail on a predictable spike. Failures happen when capacity
planning is done annually or not at all.

**When to use it:**
Apply capacity planning to all Tier 1 and Tier 2 services on a monthly
review cycle. For services with known seasonality (retail, finance),
run quarterly planning reviews with specific peak provisioning checklists.

**When NOT to use it:**
Tier 3 internal services with low and stable traffic can rely on auto-
scaling without formal capacity planning. The overhead is not justified.

**Alternatives:**
- Pure auto-scaling (reactive): works but has latency in provisioning;
  the scale-up event is triggered during the traffic spike, not before it
- Manual capacity planning (spreadsheets): adequate for predictable growth
  but error-prone and does not account for seasonality automatically
- Cost-based provisioning: provision as cheaply as possible, add when cost
  triggers; produces under-provisioned services

---

### 💻 Code Example

**Example 1: Load forecasting with seasonal decomposition**

```python
# BAD: Capacity planning using only the average
# Does not account for seasonality or peak multiplier.
# Result: service saturates every holiday season.
current_avg = get_average_utilization(last_30_days)
if current_avg > 0.70:
    add_capacity()

# GOOD: Seasonal decomposition with peak projection
import pandas as pd
from statsmodels.tsa.seasonal import STL
import numpy as np

def forecast_capacity_requirement(
    demand_series: pd.Series,
    forecast_horizon_days: int = 90,
    target_utilization: float = 0.70,
    capacity_per_unit: float = 1000.0  # requests/sec
) -> dict:
    """
    Forecast resource requirement using seasonal
    decomposition (STL) + trend projection.

    Args:
        demand_series: daily max requests/sec (last 180d)
        forecast_horizon_days: days to forecast ahead
        target_utilization: max utilization ceiling
        capacity_per_unit: requests/sec per server instance
    """
    # Require at least 2 seasonal cycles of data
    if len(demand_series) < 56:  # 2 * 28 days
        raise ValueError(
            "Need at least 56 days of data for "
            "seasonal decomposition"
        )

    # STL decomposition: trend + seasonal + residual
    stl = STL(
        demand_series,
        period=7,       # weekly seasonality
        seasonal=13,    # 13-week seasonal window
        robust=True     # handle outliers
    )
    result = stl.fit()

    # Project trend component forward
    # Using linear regression on trend component
    trend_values = result.trend.values
    x = np.arange(len(trend_values))
    slope, intercept = np.polyfit(x, trend_values, 1)

    projected_x = np.arange(
        len(trend_values),
        len(trend_values) + forecast_horizon_days
    )
    trend_projection = slope * projected_x + intercept

    # Compute seasonal multiplier for forecast period
    # Use the last full year of seasonal values
    seasonal_window = result.seasonal.values[-365:] \
        if len(result.seasonal) >= 365 \
        else result.seasonal.values
    seasonal_repeat = np.tile(
        seasonal_window[:7],  # weekly pattern
        forecast_horizon_days // 7 + 2
    )[:forecast_horizon_days]

    # Composite forecast: trend + seasonal
    forecast = trend_projection + seasonal_repeat
    peak_forecast = float(np.percentile(forecast, 95))

    # Required capacity
    required_instances = int(
        np.ceil(peak_forecast / capacity_per_unit
                / target_utilization)
    )

    return {
        "forecast_peak_rps": f"{peak_forecast:.0f}",
        "required_instances": required_instances,
        "current_headroom": f"{target_utilization:.0%} util",
        "provision_by": (
            pd.Timestamp.now()
            + pd.Timedelta(days=forecast_horizon_days // 2)
        ).strftime("%Y-%m-%d"),
        "recommendation": (
            f"Provision {required_instances} instances "
            f"by provision_by date to maintain "
            f"{target_utilization:.0%} utilization ceiling "
            f"at {peak_forecast:.0f} rps forecast peak."
        )
    }
```

> **Code walkthrough:** The BAD approach uses only the rolling average
> for capacity decisions, missing seasonality entirely. The GOOD approach
> uses STL (Seasonal and Trend decomposition using Loess) which separates
> the time series into trend (long-term growth), seasonal (weekly pattern),
> and residual components. The trend is projected forward using linear
> regression; the seasonal multiplier is overlaid from the historical
> pattern. The 95th percentile of the composite forecast is the provisioning
> target, ensuring the service can handle expected peaks with the 70%
> utilization ceiling.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Capacity planning starts with measuring current utilization and growth
> rate for each resource dimension (CPU, memory, network, connections).
> Use historical data to project forward 3-6 months. Account for known
> peaks (holidays, product launches). Provision to maintain 70-80% headroom
> at peak. Set an alert at 70% utilization to trigger the next provisioning
> cycle. The failure mode to avoid: planning based on average utilization
> only, missing seasonal peaks.

---

**Senior / Staff (5+ years):**
> The most common capacity planning failure I see is single-dimension
> analysis. Teams analyze CPU and memory but miss connection pool limits,
> database query saturation, or network throughput. A service that is
> provisioned for CPU but hits connection pool saturation will fail when
> traffic increases, even though CPU is fine. The USE method (Utilization,
> Saturation, Errors) for every resource dimension is the checklist that
> prevents this.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Auto-scaling eliminates the need for capacity planning | Auto-scaling reacts after the metric threshold is crossed; the scale-up event takes 2-5 minutes, during which the service is already saturated. Planning provisions ahead of the spike |
| 90% utilization target is efficient | Above 80% utilization, queuing delays increase non-linearly (M/M/1 queue model); 80% is the practical ceiling, not 90% |
| Capacity planning is a one-time annual activity | Demand growth patterns change; monthly reviews catch growth inflections before they cause saturation |
| Cloud infrastructure is infinite | Cloud capacity has regional limits; instances of specific types have availability constraints; large-scale provisioning requires advance lead time with providers |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Seasonal saturation from poor forecasting**

*Symptom:* Service handles normal load fine. During Black Friday,
response times increase from 150ms to 8 seconds. Auto-scaling triggers
but scale-up takes 4 minutes. 60% error rate for 6 minutes before
capacity stabilizes.

*Root cause:* Capacity forecast used annual average, missed holiday
10x multiplier. Auto-scaling was reactive, not predictive.

*Diagnostic:*
```
# Look at the demand during the incident vs normal:
# If incident peak demand / normal average > 3x:
# -> Seasonal event not accounted for in capacity plan
# Check: was there a capacity review before the event?
# Check: was auto-scaling in "predictive mode" or
#        "reactive mode"?
```

*Fix:* Historical peak analysis: find all known peak events (holidays,
product launches, viral events). Build a peak multiplier table:
Black Friday = 8-12x normal, Christmas = 5-8x, New Year = 3-5x.
Provision to handle peak multiplier, not average load. Use predictive
auto-scaling (AWS Predictive Scaling, GKE Vertical Pod Autoscaler)
that scales before the traffic spike.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | USE method, seasonal decomposition, predictive scaling |
| Seniority signal | Junior: names headroom and auto-scaling; Senior: seasonal decomposition, multi-dimension USE |
| Common trap | Claiming auto-scaling is sufficient without predictive scaling |
| Staff differentiator | Multi-cloud capacity negotiation, capacity planning as reliability investment |

---

**Q1 [MID]: How do you ensure a service has enough capacity for
a planned 10x traffic increase for a product launch?**

The planning checklist for a 10x launch:

Six weeks before: run the USE analysis against all resource dimensions
at 10x current peak traffic. Identify the first bottleneck dimension.
For most services, this is either database connections (fixed pool size),
memory (JVM heap sizing), or network bandwidth (CDN throughput).

Four weeks before: provision additional capacity for the bottleneck
dimensions. For database connections: evaluate read replica capacity,
connection pooling configuration, and connection pool limits. For
memory: resize instances or JVM heap. For network: submit CDN capacity
requests (providers need lead time).

Two weeks before: load test at 2x, 5x, and 10x current traffic in
a staging environment that mirrors production topology. Capture the
saturation point: at what load does the service begin queuing? This
reveals second-order bottlenecks the USE analysis missed.

One week before: provision auto-scaling to handle 12x (10x + 20%
safety margin). Enable predictive scaling if available. Set the
scale-up trigger to 50% utilization (not 80%) so scaling has time
to complete before saturation.

Day of launch: monitoring review every 15 minutes. Establish a "hold"
criterion: if error rate exceeds 1%, scale up immediately rather than
waiting for auto-scaling. Have the runbook ready.

*What separates good from great:* Gives a time-sequenced checklist,
identifies database connections as the most common first bottleneck,
and explains the load test -> saturation point discovery step.

---

**Q2 [SENIOR]: BEHAVIORAL: Tell me about a capacity incident where
forecasting failed and what you changed.**

**Situation:** API service for a B2B SaaS platform. Monthly batch
jobs from enterprise customers ran at month-end. January month-end
was also year-end, producing a 4x normal traffic spike. Service
saturated at database connection pool limit (200 connections). Errors
for 35 minutes before emergency connection pool increase.

**Task:** Prevent the same failure for the following month-end.

**Action:** Root cause was two-fold: the capacity plan used monthly
average demand (missed month-end pattern), and the connection pool
limit was set at service initialization without periodic review.

Changes: (1) Added month-end peak to the capacity forecast model:
last business day of month = 3x multiplier, January month-end = 4x.
(2) Implemented a connection pool utilization SLI: alert at 70%
connections used (not just errors). (3) Pre-scaled database read
replicas on the last day of every month automatically via a cron
trigger. (4) Documented the month-end pattern in the runbook.

**Result:** Zero capacity incidents at month-end for the following 6
months. Connection pool utilization peaked at 65% during the next
January year-end.

*What separates good from great:* Identifies the root cause (average-
based forecast missing periodic pattern), describes both the monitoring
and the automation fix (not just the runbook documentation).

---

### ⚖️ Comparison Table

| Forecasting Approach | Accuracy | Complexity | Latency in Provisioning | Best for |
|---|---|---|---|---|
| Seasonal decomposition (STL) | High | Medium | Low (proactive) | Services with clear seasonality |
| Linear trend extrapolation | Medium | Low | Low (proactive) | Stable linear growth, no seasonality |
| Reactive auto-scaling only | Low | Low | High (reactive) | Bursty, unpredictable demand |
| Predictive auto-scaling (AWS/GCP) | Medium-high | Low (managed) | Low (proactive) | Cloud-native services with ML forecasting |
| Manual capacity review | Variable | Low | Medium | Small teams, low-frequency review |

---

### 🏛️ System Design

*(Omit: Capacity Planning is an operational process keyword.
System design for scalable architectures is addressed in the
software-architecture and system-design topics.)*

---

### 📊 Diagram

*(Omit: The capacity planning cycle is adequately described in
the tabular format in the Concept Explanation section.)*

---

---

# Performance Degradation and Saturation Analysis

🎯 Interview Weight: critical - the most common interview question
for SRE and senior infrastructure roles; inability to diagnose
saturation under load is a hard disqualifier.

---

### 🎯 Model Answer

**30 seconds:**
> Saturation analysis identifies which resource is the bottleneck that
> limits system throughput or causes latency to increase under load.
> The USE method (Utilization, Saturation, Errors per resource) provides
> the systematic checklist. For each resource: if utilization is high,
> check saturation (queuing). If saturation is present, the resource
> is the bottleneck. The Little's Law relationship (L = lambda * W)
> connects queue depth to throughput and latency.

**3 minutes (Senior):**
> Performance degradation follows a predictable pattern under load
> due to queuing theory. The M/M/1 queue model explains why latency
> increases non-linearly above 80% utilization: at 70% utilization,
> queue depth is approximately L = 0.7/(1-0.7) = 2.3 requests waiting.
> At 90% utilization: L = 0.9/(1-0.9) = 9 requests waiting. At 95%:
> L = 19. The latency increase is 4x from 70% to 90% utilization, not
> linear. This is why the 80% utilization ceiling is not conservative -
> it is mathematically motivated.
>
> Saturation analysis applies the USE method to every resource dimension.
> Utilization: what fraction of capacity is in use? Saturation: is work
> queuing because the resource cannot keep up? Errors: are requests
> failing due to resource limits?
>
> The most common saturation points that are missed in naive analysis:
> database connection pool limits (not CPU), JVM thread pool exhaustion
> (not heap memory), network file descriptor limits (not bandwidth), and
> GC pause frequency causing latency spikes (not steady-state heap usage).
> These are found by applying USE to each resource dimension, not just
> the obvious ones.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "At scale, saturation analysis must account
for cascading saturation: the primary service saturates at the database
connection pool, the slow database responses cause the HTTP thread pool
to fill up, which causes upstream services' connection pools to fill,
which triggers circuit breakers, which causes cascading failures.
Saturation analysis at scale must trace the propagation path, not just
find the primary bottleneck."

*Adapting down:* Junior: "Saturation means a resource is full and
work is queuing up. To find the saturation point: check CPU, memory,
disk, network bandwidth, and connection pool usage. Whichever one
is high and causing queue buildup is the bottleneck. Fix the bottleneck,
not the symptom."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about performance degradation and
saturation analysis - let me walk through the USE method, the queuing
theory basis for the 80% utilization ceiling, and the common hidden
saturation points."

**(2) First principles:** "Systems saturate when requests arrive faster
than they can be processed. This creates a queue. Queue depth increases
non-linearly above 80% utilization due to M/M/1 queue dynamics. The
analysis task is: which resource is the bottleneck causing queue buildup?"

**(3) Bridge:** "Saturation analysis is like traffic engineering. A
highway that is 70% full flows smoothly. At 85% capacity, small
incidents cause major backups because there is no spare capacity to
absorb them. The USE method is the traffic sensor network that tells
you which highway is approaching capacity before it backs up."

---

### 📘 Concept Explanation

**What it is:**
Performance degradation and saturation analysis is the systematic
process of identifying which resource is the bottleneck causing latency
increases or throughput limitations under load. It uses the USE method
(Utilization, Saturation, Errors) applied to each resource dimension.

**The problem it solves:**
Without systematic analysis, engineers optimize the wrong dimension.
A service that appears to have CPU headroom but is actually saturating
at database connections will not improve with horizontal CPU scaling.

**How it works:**

```
USE METHOD - SYSTEMATIC SATURATION ANALYSIS
=============================================

For each resource dimension:
  1. UTILIZATION: current usage / maximum capacity
     Alert threshold: > 70% sustained
     Saturation threshold: > 80% sustained

  2. SATURATION: is work queuing?
     CPU: run queue depth (vmstat 'r' column)
     Memory: swap usage, page fault rate
     Disk: I/O queue depth (iostat 'avgqu-sz')
     Network: send/recv buffer drops (netstat)
     Database connections: active / max_connections
     Thread pool: waiting threads / total threads

  3. ERRORS: resource limit failures
     Memory: OOM kills (dmesg)
     Files: "too many open files" errors
     Connections: "connection refused"
     Threads: "java.lang.OutOfMemoryError: unable
               to create native thread"

Resource dimensions to check (ordered by frequency
of being the bottleneck in web services):

  Resource          | Key Metric
  ------------------|-----------------------------------
  DB connections    | active/max_connections ratio
  HTTP threads      | active/max threads ratio
  CPU               | load average / core count
  Memory            | heap used / heap max (JVM)
  Network I/O       | bytes_sent / interface capacity
  Disk I/O          | iostat %util > 70%
  File descriptors  | open files / ulimit
  Cache evictions   | eviction rate (Redis/Memcached)

LITTLE'S LAW CONNECTION
  L = lambda * W
  L: average items in system (queue + service)
  lambda: arrival rate (requests/sec)
  W: average time in system (latency)

  Implication: if arrival rate (lambda) increases
  without proportional capacity increase:
    latency (W) increases proportionally
    queue length (L) increases quadratically
  This is the mathematical basis for the 80% ceiling.

M/M/1 QUEUE SATURATION CURVE
  Utilization | Avg queue depth | Relative latency
  50%         | 1.0             | 1.0x (baseline)
  70%         | 2.3             | 2.3x
  80%         | 4.0             | 4.0x
  90%         | 9.0             | 9.0x
  95%         | 19.0            | 19.0x
```

**The key insight:**
Most performance problems are explained by a single bottleneck at one
resource dimension. Finding the bottleneck requires systematic application
of USE across all resource dimensions, not just the obvious ones.
The counter-intuitive bottlenecks (database connection pool, JVM thread
pool, file descriptor limits) are found by applying the checklist, not
by intuition.

**When to use it:**
Apply USE analysis when: latency increases under load without clear CPU
or memory pressure, throughput plateaus below expected levels, or service
errors increase proportionally with traffic.

**When NOT to use it:**
When errors are consistent regardless of load (constant error rate),
the problem is not saturation - it is a functional bug. USE analysis
is specifically for load-induced degradation.

**Alternatives:**
- Flamegraph profiling: identifies CPU hotspots in code execution
  (complements USE, not a replacement)
- APM tools (Datadog, NewRelic): correlate metrics across dimensions
  automatically (USE is the manual methodology)
- Load testing: observes saturation point experimentally rather than
  analytically

**First-principles derivation:**
A resource that receives more requests than it can process builds a
queue. Queue depth increases non-linearly above 80% utilization.
Identifying which resource is building a queue identifies the bottleneck.
Resolving the bottleneck restores linear latency behavior.

---

### 💻 Code Example

**Example 1: Saturation analysis automation script**

```python
#!/usr/bin/env python3
# BAD: Diagnose performance issue by looking at
# the most obvious metric first (CPU).
# If CPU is fine, conclude "no saturation."
# Misses DB connections, threads, FDs.

# GOOD: Systematic USE analysis across all dimensions

import subprocess
import re
from dataclasses import dataclass
from typing import Optional

@dataclass
class ResourceStatus:
    resource: str
    utilization: float      # 0.0 to 1.0
    saturation_signal: str  # "OK", "WARN", "CRIT"
    errors: Optional[str]

def check_system_saturation() -> list[ResourceStatus]:
    """
    Apply USE method to key resource dimensions.
    Returns list of ResourceStatus, sorted by severity.
    """
    results = []

    # 1. CPU - check load average vs core count
    load_out = subprocess.check_output(
        ["uptime"], text=True
    )
    # Parse "load average: 2.34, 2.12, 1.89"
    match = re.search(
        r"load average: ([0-9.]+)", load_out
    )
    if match:
        load_1m = float(match.group(1))
        core_count = int(subprocess.check_output(
            ["nproc"], text=True
        ).strip())
        cpu_util = min(load_1m / core_count, 1.0)
        results.append(ResourceStatus(
            resource="CPU",
            utilization=cpu_util,
            saturation_signal=(
                "CRIT" if cpu_util > 0.9
                else "WARN" if cpu_util > 0.7
                else "OK"
            ),
            errors=None
        ))

    # 2. Memory - check for swap usage
    mem_out = subprocess.check_output(
        ["free", "-b"], text=True
    ).splitlines()
    for line in mem_out:
        if line.startswith("Mem:"):
            parts = line.split()
            mem_util = int(parts[2]) / int(parts[1])
            results.append(ResourceStatus(
                resource="Memory",
                utilization=mem_util,
                saturation_signal=(
                    "CRIT" if mem_util > 0.90
                    else "WARN" if mem_util > 0.80
                    else "OK"
                ),
                errors=None
            ))
        if line.startswith("Swap:"):
            parts = line.split()
            if int(parts[1]) > 0:
                swap_util = int(parts[2]) / int(parts[1])
                if swap_util > 0.1:
                    results[-1].saturation_signal = "CRIT"
                    results[-1].errors = (
                        f"Swap in use: "
                        f"{int(parts[2])/(1024**3):.1f}GB"
                    )

    # 3. File descriptors
    fd_max_out = subprocess.check_output(
        ["cat", "/proc/sys/fs/file-max"], text=True
    ).strip()
    fd_used_out = subprocess.check_output(
        ["cat", "/proc/sys/fs/file-nr"], text=True
    ).strip()
    fd_max = int(fd_max_out)
    fd_used = int(fd_used_out.split()[0])
    results.append(ResourceStatus(
        resource="File Descriptors",
        utilization=fd_used / fd_max,
        saturation_signal=(
            "CRIT" if fd_used / fd_max > 0.90
            else "WARN" if fd_used / fd_max > 0.70
            else "OK"
        ),
        errors=(
            "Near FD limit - check ulimit"
            if fd_used / fd_max > 0.90 else None
        )
    ))

    return sorted(
        results,
        key=lambda r: (
            {"CRIT": 0, "WARN": 1, "OK": 2}
            [r.saturation_signal]
        )
    )
```

> **Code walkthrough:** The BAD approach checks CPU only and concludes
> no saturation if CPU is healthy - missing the most common actual
> bottlenecks (file descriptors, memory swap, database connections).
> The GOOD approach implements the USE method as a checklist across
> CPU, memory, and file descriptors. The output is sorted by severity,
> so the most critical saturation signal appears first. In production,
> this would extend to database connection pool, HTTP thread pool, and
> disk I/O using the same pattern.

**Example 2: Identifying hidden connection pool saturation**

```python
# BAD: Observing "high latency" and scaling up CPU
# (the obvious diagnosis), without checking
# database connection pool exhaustion.

# GOOD: Check the actual bottleneck first

def diagnose_latency_spike(
    service_name: str
) -> dict:
    """
    Systematic bottleneck diagnosis for latency spikes.
    Checks resource dimensions in order of frequency.
    """
    # Step 1: Database connection pool saturation
    # (most common bottleneck in web services)
    db_pool_query = f"""
    SELECT
        count                            AS active,
        max_conn                         AS pool_size,
        ROUND(count::numeric/max_conn, 3) AS utilization
    FROM pg_stat_activity,
         (SELECT setting::int AS max_conn
          FROM pg_settings
          WHERE name = 'max_connections') limits
    WHERE state = 'active'
    AND application_name LIKE '{service_name}%'
    GROUP BY max_conn;
    """
    # If utilization > 0.80: connection pool is the bottleneck
    # Fix: increase pool size, add connection pooler (PgBouncer)
    # or add read replicas

    # Step 2: HTTP thread pool exhaustion (Java services)
    # Check: active_threads / max_threads in app metrics
    # If > 0.80: thread pool is the bottleneck
    # Fix: increase max threads or reduce thread hold time

    # Step 3: GC pause impact
    # Check: JVM GC metrics, stop-the-world pause duration
    # If STW pauses > 500ms: GC pressure causing latency spikes
    # Fix: tune GC, increase heap, reduce allocation rate

    # Step 4: CPU
    # Check: load average vs core count
    # Only fix if steps 1-3 are ruled out

    return {
        "diagnostic_order": [
            "1. DB connection pool (check pg_stat_activity)",
            "2. HTTP thread pool (check app thread metrics)",
            "3. GC pauses (check JVM GC logs)",
            "4. CPU load (check load average vs cores)",
            "5. Memory pressure (check heap, swap)",
            "6. Network (check interface saturation)",
            "7. Disk I/O (check iostat %util)"
        ],
        "note": (
            "Fix the first bottleneck found. "
            "After resolution, re-run diagnosis to find "
            "next bottleneck (there is always another one)."
        )
    }
```

> **Code walkthrough:** The BAD approach scales CPU when observing
> high latency - the intuitive but usually wrong diagnosis for web
> services. The GOOD approach applies a prioritized diagnostic checklist
> with database connection pool at position 1 (most common bottleneck
> in web services), followed by HTTP thread pool, GC pressure, and then
> CPU. The comment in the output captures the key operational insight:
> fix the first bottleneck, then re-run the diagnosis - systems rarely
> have only one bottleneck.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Saturation analysis starts with the USE method: for each resource
> (CPU, memory, network, disk, database connections, thread pools),
> check utilization (how full?), saturation (is work queuing?), and
> errors (are requests failing?). The most common hidden bottleneck
> is the database connection pool - you need to check the active/max
> connections ratio, not just CPU and memory. Latency increases non-
> linearly above 80% utilization due to queuing effects.

---

**Senior / Staff (5+ years):**
> The most important lesson I have learned about saturation analysis:
> the bottleneck is almost never where you expect it. Engineers look at
> CPU first because it is the most visible metric. But in production
> web services, the first bottleneck is usually database connection pool
> limits, HTTP thread pool exhaustion, or GC pause frequency - all of
> which are invisible if you only look at CPU and heap.
>
> I apply the USE method to a checklist of 7 resource dimensions and
> fix them in order. There is always another bottleneck after the
> first one is fixed; real-world services have compound bottlenecks.
> After fixing the database connection pool, you discover the HTTP
> thread pool. After fixing that, you discover the GC pause frequency.
> Saturation analysis is iterative.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| High CPU is always the bottleneck | In web services, the bottleneck is usually DB connections, thread pool, or GC before CPU saturates |
| Linear latency increase under load is normal | Latency should increase sub-linearly up to 80% utilization; above 80% it increases non-linearly due to queuing; linear increase at any load level suggests a different problem (synchronous blocking) |
| The saturation point is fixed | Saturation points shift when code changes, traffic patterns change, or database query patterns change; regular saturation analysis is required |
| More instances always resolve saturation | Horizontal scaling helps with CPU and memory saturation but not with single-threaded bottlenecks (database master, single message queue partition) |
| Saturation only affects performance, not availability | Above saturation, the system transitions from slow to error-rate increase as queues overflow and requests time out; saturation is an availability risk, not just a performance one |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Cascading saturation from a single bottleneck**

*Symptom:* Database response time increases from 20ms to 2 seconds
during a traffic spike. Web service thread pool fills with threads
waiting for database responses. New requests queue in the load balancer.
Load balancer timeout triggers 502 errors. Upstreams hit circuit
breakers. Full service outage even though the database is "just slow."

*Root cause:* Thread pool configured with no timeout on database
calls. Slow database responses held threads indefinitely, exhausting
the pool. One resource dimension's saturation (database connection
wait time) propagated through thread pool saturation to full service
outage.

*Diagnostic:*
```
# Check thread pool status (Java)
curl localhost:8080/actuator/metrics/\
  executor.active

# If active == max, threads are exhausted
# Check what threads are blocked on:
jstack <PID> | grep "WAITING" | head -20
# Likely: threads blocked on DB connection acquire
```

*Fix:* Database connection timeout + thread pool queue limit.
Set connection acquire timeout to 500ms (fail fast rather than block).
Set HTTP thread pool queue depth limit (reject at 2x normal depth).
This converts a slow degradation into a controlled partial failure:
5% error rate instead of full saturation cascade.

*Prevention:* Set timeouts for all I/O operations. Never hold a
thread indefinitely waiting for a downstream resource. Circuit breakers
on database calls break the cascade.

**Failure 2: GC pause masquerading as saturation**

*Symptom:* Service shows periodic latency spikes every 30 seconds.
P99 latency is 3 seconds; P50 is 50ms. No consistent CPU, memory,
or connection pool saturation. Traditional USE analysis shows no
obvious bottleneck.

*Root cause:* JVM full GC pauses every 30 seconds, causing stop-
the-world pauses of 2-3 seconds. All requests during the pause are
queued and released simultaneously, causing a brief post-pause spike.

*Diagnostic:*
```
# Correlate GC pause log with latency spikes:
# GC log enabled with: -Xlog:gc*:gc.log
grep "Pause Full" gc.log | \
  awk '{print $1, $NF}'
# Compare timestamps with latency spike timestamps in
# APM. If they align: GC is the cause.
```

*Fix:* Tune GC for latency: G1GC with MaxGCPauseMillis=200,
increase heap to reduce GC frequency, or migrate to ZGC/Shenandoah
(sub-millisecond pauses). Reduce object allocation rate (profiling
with async-profiler to find allocation hotspots).

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | USE method, M/M/1 queue model, connection pool bottleneck, GC pause diagnosis |
| Seniority signal | Junior: USE method; Senior: M/M/1 math, cascading saturation, GC diagnosis |
| Common trap | Diagnosing CPU first without checking connection pools or thread pools |
| Staff differentiator | Cascading saturation propagation tracing, Little's Law application |

---

**Q1 [MID]: What is the USE method and how do you apply it?**

The USE method (Utilization, Saturation, Errors) is a systematic approach
to performance analysis. For each resource dimension in a system, you
check three things:

Utilization: what percentage of the resource's capacity is currently in
use? High utilization (above 70-80%) is a warning signal. Formula:
utilization = used capacity / total capacity.

Saturation: is work queuing because the resource cannot keep up? A CPU
at 80% utilization may have a run queue of 5 processes waiting. A database
at 80% connection capacity may have 20 queries waiting for a connection.
Saturation signals that the bottleneck is active.

Errors: are requests failing due to resource limits? "Too many open files"
errors indicate file descriptor saturation. "Connection refused" indicates
connection limit saturation. "java.lang.OutOfMemoryError" indicates heap
or native memory saturation.

The application: I maintain a checklist of 7-8 resource dimensions and
apply USE to each one. I start with the most frequently saturating dimensions
for the service type (database connections for web services, memory for
data processing, I/O for storage services). The first dimension showing
both high utilization and saturation is the bottleneck.

*What separates good from great:* Explains all three components with
specific diagnostic commands for each, and gives the prioritization
order by service type.

---

**Q2 [SENIOR]: Why does latency increase non-linearly above 80%
utilization? What is the mathematical basis?**

The M/M/1 queue model describes a single-server queue with Poisson arrivals
and exponential service times. The average queue length is:

L = rho / (1 - rho)

Where rho is the server utilization (requests / capacity). Substituting:
- At rho = 0.5: L = 0.5 / 0.5 = 1.0 requests in queue
- At rho = 0.7: L = 0.7 / 0.3 = 2.3 requests in queue
- At rho = 0.8: L = 0.8 / 0.2 = 4.0 requests in queue
- At rho = 0.9: L = 0.9 / 0.1 = 9.0 requests in queue

Little's Law connects queue length to latency: L = lambda * W.
If arrival rate (lambda) is constant, latency (W) increases proportionally
to L. So from 70% to 90% utilization, average queue length increases from
2.3 to 9.0 - latency increases 4x for a 20% utilization increase.

This is why 80% is the practical ceiling: above 80%, small utilization
increases produce large latency increases. The relationship is not linear -
it is hyperbolic, approaching infinity at 100% utilization.

In practice, real systems have multiple servers (M/M/N queue), but the
fundamental non-linear behavior holds. The 80% ceiling is not conservative;
it is derived from queuing theory.

*What separates good from great:* Gives the actual M/M/1 formula,
calculates specific queue depths at different utilization levels, and
explains why the ceiling is 80% from first principles.

---

**Q3 [SENIOR]: BEHAVIORAL: Walk me through diagnosing a production
latency incident where the root cause was not immediately obvious.**

**Situation:** Payment service p99 latency spiked from 300ms to 8 seconds
starting at 14:32. Error rate remained low (0.3%). CPU was at 45%.
No obvious infrastructure events.

**Diagnostic process:**
Step 1: CPU and memory - both fine. Memory at 60%, CPU at 45%.
Step 2: Database connection pool - `pg_stat_activity` showed 198/200
connections active. 15 queries in "idle in transaction" state for > 5
minutes. Connection pool at 99% utilization.

**Root cause:** A database migration script was running in a long
transaction, holding connections open for > 10 minutes. This exhausted
the connection pool; new payment requests queued waiting for a connection,
causing the latency spike.

**Immediate fix:** `SELECT pg_terminate_backend(pid)` for the stuck
migration process. Connection pool returned to 40% utilization; latency
immediately returned to 250ms.

**Permanent fix:** Database migrations are never run in transactions that
hold connections open for > 30 seconds. The migration was redesigned to
operate in small batches with explicit transaction commits.

**Result:** Zero "idle in transaction" saturation events in the following
6 months.

*What separates good from great:* Uses the USE method in sequence (CPU
first, then connection pool), identifies the exact root cause (idle-in-
transaction connections), describes both the immediate fix and the permanent
fix.

---

**Q4 [STAFF]: How do you analyze saturation in a distributed system
where the bottleneck propagates across multiple services?**

Cascading saturation in distributed systems is harder to diagnose
because the observable symptom (errors in the upstream service) is
several hops away from the root cause (saturation in a downstream
dependency).

The diagnostic approach: trace the propagation chain backward from
symptom to root cause.

Step 1: identify the primary symptom - which service is showing errors
or latency spikes? This is the entry point.

Step 2: for the primary service, apply USE to find the saturating
resource. If the service has a dependency (database, cache, message
queue), check the dependency's health immediately.

Step 3: if the dependency is healthy, the saturation is local to the
primary service. If the dependency shows saturation, the root cause
is in the dependency, not the primary service.

Step 4: repeat steps 2-3 for each dependency in the chain until the
root cause is found (the resource that would be fine if traffic
decreased to normal).

The key diagnostic signal: if reducing traffic to the primary service
would fix the problem (auto-scaling would help), the primary service
is the bottleneck. If reducing traffic to the primary service would
not fix the dependency's saturation (the dependency is globally shared
and other services are also consuming it), the bottleneck is in the
shared dependency.

Tools: distributed tracing (Jaeger, Zipkin) shows the latency
contribution of each hop. The hop with the highest latency is the
bottleneck or is blocked waiting for a downstream bottleneck.

*What separates good from great:* Describes the backward-tracing
methodology, distinguishes local bottleneck from shared dependency
bottleneck, and identifies distributed tracing as the enabling tool.

---

**Q5 [STAFF]: How do you design alerting for saturation that fires
before users are impacted?**

The key insight from the M/M/1 model: latency begins increasing
noticeably above 70% utilization. By the time the SLO breach fires
(user-visible latency degradation), utilization may already be above
85% and the service is in a non-linear degradation phase.

Saturation alerting must fire before user impact, which means alerting
on the leading indicator (utilization approaching the threshold) rather
than the lagging indicator (latency breaching the SLO).

Three-layer saturation alerting:

Layer 1 (informational, no paging): utilization > 60% sustained for
15 minutes. Logged, tracked, visible in dashboards. No on-call page.
This is the "plan your capacity response" signal.

Layer 2 (team notification, not on-call): utilization > 75% sustained
for 10 minutes. Posts to team Slack channel. On-call aware but not
paged. If this fires, the next capacity review is triggered immediately.

Layer 3 (on-call page): utilization > 85% sustained for 5 minutes.
This is near the saturation cliff; user-visible latency degradation
is imminent. On-call investigates and applies emergency capacity.

The correlation: when Layer 3 fires, the golden signals alerts (latency
SLO breach) should not have fired yet. If they have already fired,
Layer 3 threshold is too high.

*What separates good from great:* Gives three alerting layers with
specific thresholds, explains the leading/lagging indicator relationship,
and includes the validation check (Layer 3 should fire before SLO breach).

---

### ⚖️ Comparison Table

| Analysis Method | Coverage | Diagnostic Time | Automation | Best for |
|---|---|---|---|---|
| USE Method (manual) | Comprehensive (all dimensions) | 30-60 min | None | Systematic bottleneck discovery |
| APM tools (Datadog, NewRelic) | High (multi-dimension, correlated) | 5-15 min | Auto-correlation | Fast diagnosis with existing tooling |
| Distributed tracing (Jaeger) | Latency per hop | 10-30 min | None | Distributed system bottleneck tracing |
| Flamegraph (CPU profiling) | CPU hotspots only | 15-30 min | None | Code-level CPU optimization |
| Load testing | Saturation point discovery | Hours | None | Pre-production bottleneck discovery |

---

### 🏛️ System Design

*(Omit: Performance Degradation and Saturation Analysis is a
diagnostic methodology keyword. System design for observability
platforms is addressed in the L4 Production Diagnostics file.)*

---

### 📊 Diagram

```
M/M/1 SATURATION CURVE
=========================
Utilization | Queue depth | Latency multiplier
50%         | 1.0         | 1.0x
70%         | 2.3         | 2.3x
80%         | 4.0         | 4.0x
90%         | 9.0         | 9.0x
95%         | 19.0        | 19.0x

        Latency
        ^
        |                     /
 19x    |                    /
        |                   /
  9x    |                  /
        |                /
  4x    |              /
  2x    |          /
  1x    |______/____________
        0  50% 70% 80% 90% 100% Utilization
              ^    ^
              |    |
           "OK"  DANGER ZONE
```

```mermaid
xychart-beta
    title "M/M/1 Queue: Latency Multiplier vs Utilization"
    x-axis [50%, 60%, 70%, 80%, 85%, 90%, 95%]
    y-axis "Latency multiplier (x baseline)" 0 --> 20
    line [1.0, 1.5, 2.3, 4.0, 6.7, 9.0, 19.0]
```

> **Diagram walkthrough:** The M/M/1 saturation curve shows why the
> 80% utilization ceiling is not conservative. From 50% to 70%, latency
> increases moderately (1x to 2.3x). From 70% to 90%, it increases
> from 2.3x to 9x - a 4x increase for a 20% utilization increase. Above
> 90%, the curve approaches vertical. The "danger zone" begins at 80%
> where small utilization increases produce large latency impacts. This
> is the mathematical justification for capacity headroom and the USE
> method's focus on resources above 70% utilization.

---

### Field Q&A

**Production Failures:**

1. A Java service experiences periodic latency spikes every 2 minutes.
   CPU is at 35%. Memory is at 70% heap usage. What should you check?
   > First check: full GC pauses. JVM GC log (enable with
   > -Xlog:gc*:gc.log). If full GC fires every 2 minutes with stop-
   > the-world pauses of > 500ms, this is the cause. 70% heap usage
   > is high enough that GC frequency increases. Fix: increase heap to
   > reduce GC frequency, switch to G1GC with pause target, or use ZGC
   > for sub-millisecond pauses. Profile allocation rate with async-
   > profiler to find the allocation hotspot causing the pressure.

2. A web service shows 99% success rate and 150ms p50 latency.
   p99 latency is 12 seconds. What resource is most likely saturating?
   > The bimodal latency distribution (low p50, very high p99) is
   > characteristic of thread pool exhaustion or connection pool
   > exhaustion where some requests wait a long time for a resource
   > to become available. Check: HTTP thread pool active/max ratio,
   > database connection pool active/max ratio. If either is above
   > 80%, that is the bottleneck. The low p50 means most requests
   > are served quickly from available threads/connections; the high
   > p99 means the unlucky requests that arrive when the pool is full
   > wait for a resource to free up.

3. A service was scaled from 10 to 50 instances to handle a traffic
   spike. Throughput increased only 20% despite 5x instances.
   What is the likely bottleneck?
   > A single shared resource that does not scale with instances is
   > the bottleneck - most likely the database. Adding web service
   > instances increases the number of clients hitting the database,
   > but if the database connection limit (max_connections) or query
   > throughput is the bottleneck, adding more instances just moves
   > the contention to the database. Check: database active connections,
   > query wait time, and database CPU. If the database is saturated,
   > horizontal scaling of web instances does not help. Fix: add read
   > replicas, implement connection pooling (PgBouncer), or scale the
   > database instance.

---

**Candidate Mistakes:**

1. "I would add more CPU to fix the latency problem."

   **What NOT to say:** Do not prescribe CPU scaling as the default fix
   for latency issues.

   **Say instead:** "Adding CPU might not fix the latency. The USE method
   tells us to diagnose before prescribing. For web services, the most
   common latency bottleneck is database connection pool exhaustion, not
   CPU. I would check database connection utilization, HTTP thread pool
   utilization, and GC pause frequency before adding CPU. If CPU is the
   actual bottleneck (USE analysis confirms), then horizontal scaling is
   correct."

2. "A service at 85% CPU is fine for production."

   **What NOT to say:** Do not treat 85% CPU as acceptable headroom.

   **Say instead:** "At 85% CPU utilization, the system is in the non-linear
   latency region of the M/M/1 queue model. A traffic spike of 10% would
   push utilization to 93%, causing queue depth to increase from ~6 to 14
   concurrent tasks waiting - latency would roughly double. 80% is the
   practical ceiling. At 85%, I would treat it as a saturation alert that
   requires immediate capacity action."

3. "Saturation analysis is only needed when there is an incident."

   **What NOT to say:** Do not limit saturation analysis to reactive use.

   **Say instead:** "Saturation analysis should be part of regular capacity
   reviews and load testing, not just incident response. Monthly USE analysis
   across all resource dimensions identifies resources approaching the 70%
   warning threshold before they cause incidents. Load testing finds the
   saturation point before production traffic reaches it. Reactive saturation
   analysis during incidents is 4-10 hours too late."

4. "I would increase the thread pool size to fix thread pool exhaustion."

   **What NOT to say:** Do not treat thread pool expansion as the fix
   for thread pool exhaustion.

   **Say instead:** "Thread pool exhaustion is usually a symptom, not
   the root cause. If threads are blocking on a downstream dependency
   (database, external API), adding more threads just adds more blocked
   threads. The fix is to find what threads are blocked on and fix that
   dependency. Adding threads temporarily increases capacity before the
   next block, but it does not address the root cause."

---

**Questions to Ask the Interviewer:**

1. "Does the team use a systematic method like USE or RED for diagnosing
   performance issues, or is the approach more ad hoc?"

2. "What is the most common bottleneck resource you see in production -
   CPU, memory, database connections, or something else?"

3. "How does the team detect saturation before users notice - through
   leading indicator alerts or SLO breach alerts?"

4. "What load testing tooling is used to discover saturation points
   before production traffic reaches them?"
