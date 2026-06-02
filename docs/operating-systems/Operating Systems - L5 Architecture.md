---
layout: default
title: "Operating Systems - L5 Architecture"
parent: "Operating Systems"
nav_order: 14
permalink: /operating-systems/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [OS-Level Performance Tuning for Production Systems](#os-level-performance-tuning-for-production-systems) | critical |

---

# OS-Level Performance Tuning for Production Systems

🎯 Interview Weight: Critical - Production OS tuning, kernel parameter selection, and CPU/memory/IO performance analysis appear in Staff/Principal and SRE interviews. Understanding why the default Linux kernel configuration is wrong for database servers, and what to change and why, is a distinguishing skill.

---

## 📋 Quick Reference

**One-line definition:** OS-level performance tuning is the systematic process of matching kernel scheduler, memory management, I/O subsystem, and network stack parameters to the workload's access patterns and resource demands - trading one resource (CPU cycles, memory, latency) for another based on explicit workload requirements.

**Difficulty:** ★★★ | **Asked at:** Senior-Staff | **Seniority:** Staff-Principal

---

### 🎯 Model Answer

**30 seconds:**
> OS-level tuning is about removing the mismatch between Linux's default configuration (optimized for interactive desktop use) and production server workloads. The three biggest gains: (1) CPU scheduler tuning - increasing `vm.dirty_ratio` and `vm.dirty_background_ratio` for write-heavy workloads prevents I/O stalls caused by sudden dirty page flushing. (2) Memory tuning - setting `vm.swappiness=0` for databases, disabling THP for Redis and MongoDB, configuring huge pages for PostgreSQL. (3) Network stack tuning - increasing socket buffer sizes, TCP backlog, and enabling TCP BBR for throughput-sensitive services. Every parameter change needs a measurement before and after - not intuition.

**3 minutes (Senior):**
> I think of OS tuning as matching the kernel's assumptions about workload type to the actual workload. The kernel's defaults are conservative and reasonable for a workload mix. Production servers are specialized. The process: measure baseline (the bottleneck), change one variable, measure again, commit if improved.
>
> The most impactful production tuning I've applied: for a write-heavy Kafka broker, the default dirty page flushing (vm.dirty_ratio=20%, triggered at 20% of RAM dirty) caused periodic I/O stalls - the kernel would halt all writes while flushing 40GB of dirty pages. Tuning vm.dirty_background_ratio=5 (start background flush earlier) and vm.dirty_ratio=10 (hard limit lower, more frequent smaller flushes) eliminated the stalls at the cost of more frequent disk writes. For a PostgreSQL database, the scheduler default (CFS with 100ms quantum) allowed background processes to steal CPU from query execution. Setting `kernel.sched_min_granularity_ns` to 2ms and `kernel.sched_wakeup_granularity_ns` to 3ms reduced query latency variance. For a high-connection Redis: setting `net.core.somaxconn=65535` and `tcp_max_syn_backlog=65535` prevented connection drops under load spikes.
>
> The principle: every tuning parameter has a cost. Increasing socket buffer sizes uses more memory per connection. Disabling THP eliminates compaction latency but reduces TLB reach. The tradeoff documentation in the commit message is as important as the change itself.

**Framework:** MEASURE → HYPOTHESIZE → TUNE → VERIFY

*Adapting up:* NUMA topology tuning, CPU pinning (isolcpus), interrupt affinity, real-time scheduling (SCHED_FIFO), io_uring vs epoll vs select comparison, eBPF for production profiling.

*Adapting down:* WHY defaults are wrong for servers + the three biggest parameters that matter for most workloads.

**Blank Mind Recovery:**

**(1) Restate:** "OS performance tuning - let me think about what the major subsystems are and where each one has defaults that don't match server workloads."

**(2) First principles:** "A computer has four resources: CPU, memory, disk I/O, and network. Linux manages each with default policies tuned for interactive desktop use. Server workloads have different patterns - sustained high throughput, low latency, large memory footprints. Tuning is matching the policy to the pattern."

**(3) Bridge:** "Every tuning parameter is a knob that trades one resource for another. Increasing I/O buffer sizes (dirty_ratio) reduces flushing frequency but uses more memory for dirty pages. This is the same trade-off as increasing any cache: more buffer = fewer flushes = more stall risk when the buffer fills."

---

### 📘 Concept Explanation

**What it is:**
OS-level performance tuning is the configuration of Linux kernel parameters (via sysctl, /sys/block, cpufreq, numactl, and process-level settings) to match the kernel's scheduling, memory management, I/O, and network behaviors to the access patterns of a specific application workload.

**The problem it solves:**
Linux's default configuration optimizes for the average case: a mix of interactive tasks, background services, and moderate I/O. Production servers are specialized: a database server needs predictable low latency and large memory pages; a web server needs high connection count throughput; a real-time service needs guaranteed CPU time. Default settings cause unnecessary stalls, wasted CPU cycles, and suboptimal memory usage for each specialized workload.

**How it works:**

The key tunable subsystems and their parameters:

```
CPU Subsystem
  /proc/sys/kernel/sched_min_granularity_ns  (default 750000 = 0.75ms)
    - Minimum time a process runs before preemption
    - Lower = more responsive; higher = less context switch overhead
    - Server tuning: 2ms-4ms for batch/latency balance

  /proc/sys/kernel/sched_migration_cost_ns  (default 500000 = 0.5ms)
    - How long to keep a task on its current CPU
    - Higher = fewer migrations but worse NUMA locality
    - NUMA servers: set to 5ms to improve cache reuse

Memory Subsystem
  /proc/sys/vm/swappiness  (default 60)
    - How aggressively to swap anonymous pages to disk
    - 0 = only swap when out of memory (not never)
    - Database servers: 1 (not 0, due to old kernel bug)

  /proc/sys/vm/dirty_background_ratio  (default 10%)
    - % of RAM at which background dirty page writeback starts
    - Write-heavy servers: 5% (flush earlier, avoid stalls)

  /proc/sys/vm/dirty_ratio  (default 20%)
    - % of RAM dirty pages at which writes stall
    - Write-heavy servers: 10% (lower hard limit, smaller stalls)

I/O Subsystem
  /sys/block/{dev}/queue/scheduler
    - none (no reordering), mq-deadline, kyber, bfq
    - SSD/NVMe: none; HDD: mq-deadline or bfq

Network Subsystem
  /proc/sys/net/core/somaxconn (default 128)
    - Maximum listen queue (backlog) per socket
    - High-connection servers: 65535

  /proc/sys/net/ipv4/tcp_rmem, tcp_wmem
    - TCP receive/send buffer sizes [min, default, max]
    - High-throughput: [4096, 87380, 16777216]
```

> **Diagram walkthrough:** This shows the four kernel subsystems with their most production-critical tuning parameters. The CPU section controls scheduling granularity - how long a process holds the CPU and how much migration costs. The Memory section controls the dirty page lifecycle - when the kernel starts writing dirty pages to disk and when it blocks writers entirely. The I/O section selects the I/O scheduler algorithm. The Network section controls connection queuing and buffer sizing. The key relationship: these parameters interact - increasing dirty_ratio allows more dirty memory but increases the risk of a sudden large flush stall; the trade-off is lower write variance versus larger peak stall size. The edge case: parameters that make sense on a dedicated server can harm a containerized environment where multiple containers share the same kernel parameters (sysctl settings are mostly per-host, not per-container). The senior insight: every parameter change should be accompanied by a measured before/after comparison using the same workload; intuition about what "should" help is often wrong.

**The key insight:**
OS tuning is a trade-off space, not a list of "right" settings. Every parameter that improves one metric degrades another. The tuning process: identify the constraint (CPU? memory bandwidth? I/O throughput? latency?), change the parameter most likely to affect that constraint, measure both the target metric and the metric you're trading away, accept only if both metrics meet requirements.

**When to tune aggressively:**
- Dedicated bare-metal servers with single workload type
- Workload is well-characterized with stable access patterns
- Performance gap is measurable and significant (>10% improvement possible)
- Rollback is possible (infrastructure-as-code, tested parameter rollback)

**When NOT to tune aggressively:**
- Shared Kubernetes nodes (sysctl changes affect all pods)
- Unknown/variable workloads (tuning for one workload may harm another)
- When the bottleneck is application-level (database query optimization gives 100x, kernel tuning gives 5%)
- Without measurement (premature optimization based on folklore)

**Alternatives:**
- Hardware upgrade (more RAM eliminates swapping, NVMe eliminates I/O scheduler relevance)
- Application-level tuning (connection pooling, query optimization, batching)
- Container resource limits (cgroup memory and CPU limits as soft tuning)
- eBPF-based dynamic analysis to identify bottleneck before tuning

**First-principles derivation:**
The kernel's default parameters balance responsiveness and throughput for a general workload. A server workload breaks one or more of the assumptions behind the defaults. For example, swappiness=60 assumes swapping is acceptable when memory is under pressure - reasonable for an interactive desktop. For a database, swapping buffer pool pages to disk causes query latency to spike from 1ms to 100ms - categorically unacceptable. Setting swappiness=1 is not "turning off swapping" (that's swappiness=0, which has a kernel bug in some versions), it's "make the kernel extremely reluctant to swap" which matches the database requirement. Every tuning decision follows this pattern: identify the default assumption, identify where the workload violates it, choose the parameter that fixes the mismatch, verify with measurement.

---

### 💻 Code Example

**BAD: No tuning, database stalls under write load**

```bash
# BAD: Default dirty page settings cause stalls
# on a write-heavy PostgreSQL server.
# Default: dirty_background_ratio=10%, dirty_ratio=20%
# With 64GB RAM: background flush starts at 6.4GB dirty,
# hard stall at 12.8GB dirty.
# A write burst filling 12.8GB dirty pages causes ALL
# writes to stall while the kernel flushes to disk.

# Symptom visible in dmesg:
# [12345.678] INFO: task postgres:1234 blocked for more
#             than 120 seconds.

# Observable via iostat during the stall:
# iostat -x 1
# Device: %util  w_await  wMB/s
# nvme0n1  100%    850ms   250
# (100% utilization, 850ms write latency = PostgreSQL stall)

# Default settings (check with):
sysctl vm.dirty_background_ratio vm.dirty_ratio
# vm.dirty_background_ratio = 10  <- too late to start flush
# vm.dirty_ratio = 20              <- too large, stall when hit
```

> **Code walkthrough:** This shows the symptoms of un-tuned dirty page settings under write load. The default dirty_ratio=20% means the kernel allows 20% of RAM (12.8GB on a 64GB system) to accumulate as dirty (modified) pages before triggering blocking flushes. On a write-heavy PostgreSQL server, write spikes can fill this buffer quickly, at which point all write operations stall until the kernel reduces dirty pages below the threshold. The iostat output shows the characteristic signature: 100% device utilization combined with 850ms write latency, which is far above normal NVMe latency (100-200 microseconds). The dmesg message confirms it: PostgreSQL tasks blocked for over 120 seconds.

**GOOD: Tuned parameters with measurement and documentation**

```bash
#!/bin/bash
# GOOD: Systematic tuning script for a PostgreSQL server
# with 64GB RAM and NVMe SSD.
# Measure before and after: use pgbench for baseline.

# 1. Measure baseline
pgbench -c 50 -j 4 -T 60 benchdb > before_tuning.txt

# 2. Apply tuning (persistent via /etc/sysctl.d/)
cat > /etc/sysctl.d/99-postgres-tuning.conf << 'EOF'
# Memory: flush dirty pages earlier and in smaller batches
# Start background flush at 5% of RAM (3.2GB on 64GB)
vm.dirty_background_ratio = 5
# Hard stall threshold at 10% (6.4GB on 64GB)
vm.dirty_ratio = 10

# Disable swap for PostgreSQL buffer pool
# (use 1, not 0: kernel bug in swappiness=0 on some versions)
vm.swappiness = 1

# Huge pages for PostgreSQL shared_buffers
# (PostgreSQL uses shmget() which is eligible for huge pages)
# Set to enough huge pages for shared_buffers=16GB
# 16GB / 2MB = 8192 huge pages
vm.nr_hugepages = 8192

# Keep inode and dentry cache in memory longer
# (PostgreSQL's sequential scans benefit from FS metadata cache)
vm.vfs_cache_pressure = 50
EOF

# 3. Apply without reboot
sysctl --system

# 4. I/O scheduler: NVMe doesn't need reordering
echo none > /sys/block/nvme0n1/queue/scheduler

# 5. CPU: reduce context switch overhead for batch workload
cat >> /etc/sysctl.d/99-postgres-tuning.conf << 'EOF'
# 4ms minimum before preemption (reduce scheduler overhead)
kernel.sched_min_granularity_ns = 4000000
# 5ms migration cost (keep tasks on same CPU for cache reuse)
kernel.sched_migration_cost_ns = 5000000
EOF
sysctl --system

# 6. Measure after
pgbench -c 50 -j 4 -T 60 benchdb > after_tuning.txt
diff before_tuning.txt after_tuning.txt
```

> **Code walkthrough:** This shows the systematic tuning approach with before/after measurement. dirty_background_ratio drops from 10% to 5%: this starts the kernel's background writeback daemon (pdflush/kworker) earlier, writing dirty pages continuously rather than waiting for a large accumulation. dirty_ratio drops from 20% to 10%: the hard stall threshold is lower, but stalls are smaller (less dirty data to flush) and less frequent (background flush keeps the dirty pool smaller). swappiness=1 (not 0) is the documented safe value to maximize swap aversion without triggering a kernel bug present in some 2.6.x versions where swappiness=0 could cause OOM despite available swap. The huge page calculation (shared_buffers/2MB = page count) is important: over-allocating huge pages causes other workloads to fail to get memory. The I/O scheduler change to `none` for NVMe removes the kernel's I/O reordering layer, which was designed for HDD seek optimization and adds latency overhead for NVMe drives that handle their own queue management.

**eBPF production profiling script**

```bash
#!/bin/bash
# Profile where time is spent without instrumentation
# overhead. bpftrace is 1-5% CPU overhead in production.

# Find slow system calls (> 10ms threshold)
bpftrace -e '
  tracepoint:syscalls:sys_enter_* { @start[tid] = nsecs; }
  tracepoint:syscalls:sys_exit_* {
    $delta = nsecs - @start[tid];
    if ($delta > 10000000) {  /* 10ms in nanoseconds */
      printf("SLOW SYSCALL: %s pid=%d took %dms\n",
        probe, pid, $delta/1000000);
    }
    delete(@start[tid]);
  }
' 2>/dev/null &

# Profile CPU scheduler latency (time waiting to run)
bpftrace -e '
  tracepoint:sched:sched_wakeup { @wakeup[args->pid] = nsecs; }
  tracepoint:sched:sched_switch {
    $prev_pid = args->prev_pid;
    if (@wakeup[$prev_pid]) {
      $lat = nsecs - @wakeup[$prev_pid];
      @sched_lat = hist($lat);
      delete(@wakeup[$prev_pid]);
    }
  }
  interval:s:10 { print(@sched_lat); clear(@sched_lat); }
'
```

> **Code walkthrough:** These two bpftrace scripts show production-safe performance diagnosis. The first script uses syscall tracepoints to find system calls that take more than 10ms - these are candidates for investigation (disk I/O stalls, lock contention, huge page allocation delays). The production safety: tracepoints have ~200 nanoseconds overhead each; at 100K syscalls/second, that's 20ms CPU overhead per second - about 2% overhead on a 1-core equivalent. The second script measures scheduler latency: the time between a thread being woken up and actually getting CPU time. High scheduler latency (>1ms) indicates CPU over-subscription or suboptimal scheduling policy. The histogram output shows the distribution of scheduler delays, revealing whether the problem is occasional long delays (P99 issue) or systematic (P50 issue), which drives different tuning responses.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The most important OS-level tuning parameters for a server are: (1) `vm.swappiness=1` for database servers to prevent swapping. (2) `vm.dirty_background_ratio` and `vm.dirty_ratio` reduced for write-heavy workloads. (3) `net.core.somaxconn=65535` for high-connection services. (4) Disable Transparent Huge Pages (`echo never > /sys/kernel/mm/transparent_hugepage/enabled`) for Redis, MongoDB. (5) Use `none` I/O scheduler for NVMe, `mq-deadline` for HDD. The universal rule: measure before and after. sysctl changes are safe to revert: `sysctl -w vm.swappiness=60` restores the default immediately.

*Push deeper:* What is vm.dirty_background_ratio and dirty_ratio, and why do you want to lower them for write-heavy workloads? Many junior engineers know to change these but don't understand the stall mechanism.

---

**Senior / Staff (5+ years):**
> At senior level, OS tuning requires understanding the mechanism behind each parameter to choose the right values for the specific workload. For CPU scheduling: the default CFS quantum (100ms) is too long for interactive services - `sched_min_granularity_ns=2ms` and `sched_latency_ns=12ms` give better latency at the cost of more context switches. For databases: `sched_migration_cost_ns=5ms` keeps query threads on the same CPU core, improving L3 cache reuse for hot buffer pool pages. For NUMA systems: `numactl --cpunodebind=0 --membind=0 postgres` forces PostgreSQL to use only NUMA node 0's CPU and memory, eliminating cross-NUMA memory access latency for the database. For network: enabling TCP BBR congestion control (`net.ipv4.tcp_congestion_control=bbr`) on services with WAN connections improves throughput by 2-10x compared to CUBIC on paths with moderate packet loss. For I/O: `readahead` tuning via `blockdev --setra 8192 /dev/nvme0n1` enables 4MB read-ahead for sequential scan workloads (PostgreSQL VACUUM, Kafka log reads), eliminating per-request I/O overhead for sequential patterns.

*Push deeper:* NUMA-aware memory allocation in the kernel - `numastat -p <PID>` shows the per-NUMA memory distribution; high foreign memory means NUMA locality is broken and tuning numad or using numactl is needed.

---

### ⚠️ Common Misconceptions

**Misconception 1: "vm.swappiness=0 disables swapping"**

`vm.swappiness=0` does NOT disable swapping on Linux kernels before 3.5. On older kernels, `swappiness=0` means "don't swap unless absolutely necessary" but the kernel can still swap under OOM conditions. On Linux 3.5+, `swappiness=0` means "never swap unless OOM." The recommended setting for databases is `swappiness=1` rather than `0`: this ensures the kernel has a valid (non-zero) metric for its swapping decisions while still being extremely reluctant to swap. The actual behavior also depends on cgroups: in a container environment, the effective swappiness is determined by the cgroup's memory.swappiness setting, not the global sysctl.

**Misconception 2: "Disabling THP always improves performance"**

Transparent Huge Pages with the `madvise` setting (not `always`) allows applications to opt into huge pages for specific regions. For workloads with large sequential working sets (Elasticsearch, Kafka), THP `madvise` + explicit `madvise(MADV_HUGEPAGE)` calls can improve TLB hit rate by 512x. Disabling THP entirely sacrifices this for all workloads on the system. The correct recommendation: set THP to `madvise` (not `always` and not `never`), then let each application opt in or out with madvise() calls. MongoDB and Redis should call `madvise(MADV_NOHUGEPAGE)` on their memory regions to avoid khugepaged compaction latency.

**Misconception 3: "I/O scheduler choice matters most for NVMe"**

For NVMe SSDs with hardware queuing (NVMe supports 64K command queues), the Linux I/O scheduler adds no value and small overhead. The correct setting is `none` (no scheduling). For SATA SSDs, `mq-deadline` or `none` are both reasonable. For HDDs, the scheduler matters significantly: `mq-deadline` prevents starvation, `bfq` (Budget Fair Queueing) provides better latency fairness. Engineers sometimes apply HDD tuning recommendations to NVMe systems - measuring before/after would catch this, but the folklore spreads without measurement.

**Misconception 4: "More CPU cores always helps under load"**

Adding CPU cores helps CPU-bound workloads. I/O-bound workloads (most databases at moderate load) see diminishing returns from additional cores because the bottleneck is disk throughput, not CPU. For a PostgreSQL server handling 10K queries/second with 50ms I/O wait per query, adding cores just means more threads waiting for the same I/O. The correct diagnosis: measure CPU utilization breakdown (`top` showing %wa for I/O wait), then tune I/O first (faster storage, I/O scheduler, dirty page settings) before adding CPU.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: OOM Killer Terminates Critical Processes**

Symptom: `dmesg | grep "Out of memory"` shows kernel killing processes; production service dies unexpectedly; `oom_kill_process` or `oom_score_adj` appears in logs.

Cause: total committed memory (all processes' virtual address spaces) exceeds `vm.overcommit_ratio` × physical RAM + swap. Or the system is configured with overcommit disabled (`vm.overcommit_memory=2`) and an allocation fails.

Diagnosis:
```bash
# Check OOM configuration
sysctl vm.overcommit_memory vm.overcommit_ratio

# See what the OOM killer would target next
cat /proc/<critical-pid>/oom_score  # higher = more likely killed
cat /proc/<critical-pid>/oom_score_adj  # adjustment (-1000 to 1000)

# Check current memory usage
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Cached|Buffers"

# Who is using memory?
ps aux --sort=-%mem | head -20
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix: set `echo -1000 > /proc/<critical-pid>/oom_score_adj` to protect critical processes from OOM killing (requires root). Long-term: reduce memory footprint (reduce JVM heap, PostgreSQL shared_buffers, Redis maxmemory), add swap as a safety buffer, or add RAM.

**Failure 2: Disk Write Stalls from Dirty Page Flood**

Symptom: application write latency spikes from <1ms to >100ms for 10-30 seconds periodically; `iostat -x 1` shows 100% disk utilization with high write latency; timestamps correlate with the dirty page flush trigger.

Cause: dirty_ratio threshold hit. The kernel has accumulated dirty_ratio (default 20%) of RAM as dirty pages, and all write calls now block until dirty pages drop below dirty_background_ratio.

Diagnosis:
```bash
# Real-time dirty page monitoring
while true; do
  grep "Dirty:" /proc/meminfo
  sleep 1
done
# Watch for Dirty: value approaching
# (total_ram * dirty_ratio / 100)

# Check current thresholds
sysctl vm.dirty_background_ratio vm.dirty_ratio \
  vm.dirty_background_bytes vm.dirty_bytes
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix: lower dirty_background_ratio (start flushing earlier) and dirty_ratio (reduce maximum dirty accumulation), ensure writeback throughput matches write rate (if disk is too slow, dirty pages accumulate regardless of tuning).

**Failure 3: CPU Soft Lockup from Scheduler Starvation**

Symptom: `dmesg | grep "soft lockup"` shows CPU soft lockup warnings; some threads get no CPU time for seconds while others run; application p99 latency spikes correlate with soft lockup messages.

Cause: a CPU-intensive thread holds the CPU beyond the soft lockup threshold (default 20 seconds). CFS can allow this if the thread's priority is high (negative nice value) and no other eligible tasks compete. Also triggered by CPU-bound kernel threads (kworker, ksoftirqd) under heavy I/O.

Diagnosis:
```bash
# Check for soft lockup in recent dmesg
dmesg -T | grep -E "soft lockup|RCU stall|hung_task"

# Find CPU-intensive threads
top -H -p <PID>  # -H shows thread view
# Look for threads with high %CPU sustained over minutes

# Check scheduler statistics
cat /proc/schedstat
# or per-process:
cat /proc/<PID>/schedstat
# format: [cpu_time, wait_time, timeslices]
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix: set `kernel.sched_rt_runtime_us = -1` only if real-time tasks are needed (dangerous - RT tasks can starve others). Better: `nice` or `chrt` to reduce priority of CPU-hungry non-critical threads. Use cgroups CPU limits to cap background work.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | Dirty page lifecycle, swappiness, scheduler |
| Debugging | 3 | OOM, dirty stalls, scheduler starvation |
| Trade-off | 3 | THP trade-offs, network buffer sizing, sysctl conflicts |
| Behavioral | 1 | Production tuning story |
| Design | 2 | Tuning strategy, multi-workload system |

---

**[JUNIOR] Q1 - [MECHANISM] What is vm.swappiness and what value should you set for a database server?**

vm.swappiness is a kernel parameter (0-200 on Linux 3.5+, 0-100 on older kernels) that controls the relative weight the kernel gives to swapping anonymous pages (process heap, stack) versus dropping page cache (file read buffers). A higher value means more aggressive swapping; lower means the kernel prefers to drop page cache first. For a database server: set swappiness to 1 (not 0). The reasoning: databases like PostgreSQL and MySQL manage their own buffer pools (shared_buffers, innodb_buffer_pool_size). If these buffer pools get swapped to disk, query latency spikes from 1ms to 100ms - a 100x degradation. Setting swappiness=1 makes the kernel extremely reluctant to swap while still having a valid non-zero metric for its internal calculations (swappiness=0 has a documented kernel bug in versions before 3.5 that could cause OOM despite available swap). The database's own memory allocations (query plans, sort buffers, connection state) should stay in RAM at all costs. Page cache, which holds recently accessed disk files, is more expendable - the database manages its own file cache. With swappiness=1, the kernel drops page cache aggressively before touching anonymous pages.

*What separates good from great:* The reason for swappiness=1 rather than swappiness=0 (the kernel bug), and explaining that databases manage their own caches so page cache eviction is acceptable but anonymous page swapping is catastrophic.

---

**[JUNIOR] Q2 - [MECHANISM] What is the difference between vm.dirty_background_ratio and vm.dirty_ratio?**

Both control dirty page writeback but at different thresholds. vm.dirty_background_ratio (default 10%): when the percentage of RAM occupied by dirty (modified, not yet written to disk) pages exceeds this value, the kernel's background writeback thread starts flushing dirty pages to disk. This happens transparently while the application continues writing. vm.dirty_ratio (default 20%): when dirty pages reach this percentage of RAM, ALL writes by ALL processes stall until dirty pages drop below the background ratio. This is the "hard stop." The stall exists to prevent unbounded dirty page accumulation. The problem with defaults on a write-heavy server: with 64GB RAM, the stall triggers at 12.8GB of dirty pages (20%). If the disk can write 500MB/s, flushing 12.8GB takes 25 seconds - 25 seconds of zero write progress for every application on the system. Recommended tuning for write-heavy servers: dirty_background_ratio=5 (start flushing at 3.2GB, keeping the pipeline active), dirty_ratio=10 (hard stall at 6.4GB, smaller and shorter stalls). The trade-off: more frequent disk writes (slightly higher write IOPS) in exchange for smaller, shorter stalls (better latency consistency).

*What separates good from great:* The stall duration calculation (dirty_ratio × RAM / disk_write_throughput = stall duration), making the trade-off concrete rather than abstract.

---

**[MID] Q3 - [TRADE-OFF] When should you disable Transparent Huge Pages and when should you leave it enabled?**

Disable THP (echo `never` or `madvise` > enabled) for: Redis and Memcached - THP compaction (khugepaged moving pages to form 2MB huge pages) causes multi-millisecond stalls, which appear as latency spikes in p99/p999 percentiles. MongoDB - same issue; official documentation recommends disabling THP. Any latency-sensitive service where p99 stalls > 1ms are unacceptable and the application doesn't use large contiguous memory regions. Leave THP enabled (or set to `madvise`) for: JVM with large heaps (>8GB) - huge pages reduce TLB miss rate significantly for GC heap traversal; configure the JVM to use madvise explicitly on its heap region. Elasticsearch - uses memory-mapped files for index segments; huge pages on the mmap'd regions reduce TLB pressure. PostgreSQL with large shared_buffers - use explicit huge pages (vm.nr_hugepages setting) rather than THP to avoid compaction behavior. The nuanced recommendation: never set THP to `always` (the `always` setting causes compaction on all anonymous memory including regions that don't benefit). Set to `madvise` and let applications opt in with `madvise(addr, len, MADV_HUGEPAGE)` or opt out with `madvise(addr, len, MADV_NOHUGEPAGE)`. This gives per-application control without the `always` setting's compaction storms.

*What separates good from great:* The specific recommendation of `madvise` mode (not just `never`), the application-level madvise() opt-in mechanism, and the distinction between explicit huge pages (PostgreSQL) versus THP compaction (bad for latency).

---

**[MID] Q4 - [DEBUGGING] A production service shows p99 latency spikes of 30 seconds every 4 hours. CPU is below 30% during spikes. What is your investigation approach?**

30-second spikes every 4 hours with low CPU strongly suggest disk I/O stall from dirty page flush - the period could correlate with cron jobs, log rotation, or dirty page accumulation cycles. Investigation sequence: Step 1 - check dirty page activity during the next spike: `watch -n1 "grep Dirty: /proc/meminfo"`. If Dirty: value drops suddenly from a large number to near zero exactly when the latency spike starts, it's a dirty page flush. Step 2 - correlate with iostat: `iostat -x 1` during the spike. 100% disk utilization + high write latency = disk flush stall. Step 3 - check what triggers the 4-hour cycle: `crontab -l` for cron jobs, `systemctl list-timers` for systemd timers, `atq` for at jobs. Step 4 - check write volume: `iotop -a -o -b` shows per-process I/O accumulation. The 4-hour period may indicate a write rate that fills dirty_ratio exactly in that time window. Calculation: if dirty_ratio=20% × 64GB RAM = 12.8GB, and the service writes 3.2GB/hour, dirty pages hit the threshold in exactly 4 hours. Fix: lower dirty_background_ratio (start flushing earlier, preventing accumulation) and ensure background flush throughput matches write rate. Also check if a cron job is running every 4 hours that generates burst writes.

*What separates good from great:* The calculation (dirty_ratio × RAM / write_rate = period) that directly explains the 4-hour cycle, the cron/systemd timer check (an alternative trigger), and the iostat + /proc/meminfo correlation methodology.

---

**[SENIOR] Q5 - [MECHANISM] How does the Linux CFS scheduler work and what parameters affect query latency on a database server?**

CFS (Completely Fair Scheduler) maintains a per-CPU run queue sorted by "virtual runtime" - the amount of CPU time each process has received, normalized by its nice/cgroup weight. The process with the smallest virtual runtime (the "most deserving") runs next. On each scheduler tick and on blocking/waking events, CFS checks if the current process should be preempted. Key parameter interactions for database latency: `sched_latency_ns` (default 24ms) is the target period over which CFS guarantees every runnable task gets at least one turn. With 8 threads competing, each gets 3ms per 24ms period. `sched_min_granularity_ns` (default 750us) is the minimum time a task runs before preemption. On a database server with many competing threads (connection threads, background workers, OS threads), reducing `sched_latency_ns` to 8ms and `sched_min_granularity_ns` to 2ms reduces the maximum scheduling latency from 24ms to 8ms - cutting tail latency caused by scheduler delays. The cost: more context switches, higher scheduler overhead (typically 1-2% CPU). `sched_migration_cost_ns` (default 500us) controls how long the scheduler waits before migrating a task to another CPU for better load balancing. For databases where hot data lives in L3 cache, a task migrating CPUs may find its hot data in the wrong cache. Setting `sched_migration_cost_ns=5ms` reduces migrations and improves cache locality at the cost of slightly less optimal load balancing.

*What separates good from great:* The virtual runtime fairness mechanism (not just "round robin"), the calculation of per-thread scheduling quantum (sched_latency_ns / thread_count), and the cache locality trade-off for sched_migration_cost_ns.

---

**[SENIOR] Q6 - [TRADE-OFF] Compare TCP BBR vs CUBIC congestion control for a microservices environment.**

CUBIC (Linux default): uses packet loss as the congestion signal. Increases window aggressively, backs off 30% on loss. On datacenter networks with 0.001% packet loss and 100Gbps switches, CUBIC works well - loss is rare and the back-off is quick. On networks with consistent latency (10Gbps LAN, 1ms RTT), CUBIC achieves near-maximum throughput. TCP BBR (Bottleneck Bandwidth and RTT): uses bandwidth and RTT measurements instead of packet loss as congestion signals. Maintains a model of the network's bottleneck bandwidth and RTT, controls sending rate based on the model. For microservices on LAN: CUBIC is usually sufficient; BBR provides marginal improvement (<5% throughput increase). BBR shines on: (1) WAN connections with >1% packet loss (bufferbloat scenarios) where BBR achieves 2-10x CUBIC throughput. (2) High-bandwidth-delay-product paths (cloud region-to-region, edge to origin). (3) Environments with shallow buffers (network hardware configured for low-latency switching). For microservices that stay within a datacenter: keep CUBIC. For services with WAN traffic (inter-region replication, edge-origin CDN): switch to BBR. Enable: `sysctl net.ipv4.tcp_congestion_control=bbr; modprobe tcp_bbr`. The risk: BBR can be "greedy" on shared links with competing CUBIC flows, potentially causing unfairness - measure actual throughput sharing, don't assume.

*What separates good from great:* The specific use case differentiation (LAN vs WAN, loss rate matters), the fairness risk (BBR vs CUBIC flows on shared links), and the module load requirement (`modprobe tcp_bbr`).

---

**[SENIOR] Q7 - [DEBUGGING] How would you use eBPF/bpftrace to diagnose why a service has high p99 latency without impacting production performance?**

eBPF is safe for production because it runs programs in a kernel-verified sandbox: the kernel verifies that eBPF programs cannot loop infinitely, access invalid memory, or crash the kernel. Overhead is typically 1-5% per observed event. Four-step latency investigation using bpftrace: Step 1 - Identify whether latency is in user-space or kernel: `bpftrace -e 'tracepoint:syscalls:sys_enter_read { @enter[tid]=nsecs; } tracepoint:syscalls:sys_exit_read { @lat[comm] = hist(nsecs - @enter[tid]); delete(@enter[tid]); } interval:s:30 { print(@lat); }' `. This shows read() latency distribution per process name. Step 2 - If high kernel time is found: `offcputime-bpftrace.bt <PID>` shows where the process is blocked waiting for the kernel (I/O, locks, page faults). Step 3 - If lock contention suspected: `bpftrace -e 'uprobe:/lib/libc.so.6:pthread_mutex_lock { @start[tid]=nsecs; } uretprobe:/lib/libc.so.6:pthread_mutex_lock { @lock_lat = hist(nsecs - @start[tid]); delete(@start[tid]); } interval:s:10 { print(@lock_lat); }' ` shows mutex acquisition latency. Step 4 - Scheduler latency: the sched_wakeup/sched_switch tracepoints measure how long a runnable thread waits before getting CPU. Production safety: use `interval:s:N` to print summaries rather than per-event `printf()` - per-event printing at high event rates generates too much output and increases overhead.

*What separates good from great:* The four-step escalation (syscall latency → off-CPU time → lock contention → scheduler latency), the production safety consideration (histogram intervals vs per-event print), and the specific bpftrace programs rather than vague "use eBPF."

---

**[SENIOR] Q8 - [BEHAVIORAL] Describe a production performance investigation where OS-level tuning made a significant difference.**

At a streaming data company, a Kafka broker cluster handling 1GB/s sustained writes showed periodic latency spikes: every 15 minutes, producer latency jumped from 2ms to 400ms for 8-10 seconds, then recovered. CPU was 25%, network was 60% utilized - neither was the bottleneck. Investigation: I started monitoring `/proc/meminfo` Dirty: value with 1-second granularity. The pattern was clear: Dirty: would grow from 0 to 24GB (20% of 120GB RAM) over 15 minutes, then suddenly start dropping as the kernel hit dirty_ratio and stalled all writes. The flush took 8-10 seconds because the SSDs could sustain 3GB/s but they were also being hit by Kafka's own log segment rolling (compaction runs every 15 minutes by default - matching the period). The two write streams combined to 3GB/s flush, taking 8 seconds to clear 24GB. Fix in two parts: (1) Changed dirty_background_ratio from 10% to 3% and dirty_ratio from 20% to 8%. This started background flush at 3.6GB and hard-stopped at 9.6GB (not 24GB), making flushes smaller and more frequent. (2) Adjusted Kafka's log.roll.ms from 900000 (15 min) to 1800000 (30 min) to decouple the compaction cycle from the dirty page cycle. Result: latency spikes dropped from 400ms p99 to 15ms p99 (still slightly elevated during flush but not service-impacting), and the 8-10 second stalls disappeared entirely.

*What separates good from great:* The specific measurement methodology (1-second /proc/meminfo polling), the root cause analysis connecting the 15-minute Kafka compaction cycle to the dirty page accumulation period, and the two-part fix (OS tuning + application configuration).

---

**[STAFF] Q9 - [DESIGN] How would you tune a Linux system that runs both a latency-sensitive API service and a throughput-optimized batch processing job on the same machine?**

This is a "noisy neighbor" problem at the OS level, requiring isolation without separate hardware. Four-axis solution: (1) CPU isolation: use cgroups v2 with `cpu.weight` to allocate 80% of CPU shares to the API service and 20% to the batch job during business hours. Use `cpuset` to dedicate specific CPU cores to the API service, preventing batch from stealing cycles: `cgexec -g cpuset:api_service my_api`. For stronger isolation: `isolcpus=4-7` kernel boot parameter removes cores 4-7 from the scheduler, then pin the API service exclusively: `taskset -c 4-7 my_api`. (2) Memory isolation: cgroups v2 `memory.high` sets a soft limit (batch job gets OOM-killed first) and `memory.low` protects the API service's memory from reclaim. (3) I/O isolation: cgroups v2 `io.weight` or `io.max` to cap the batch job's I/O bandwidth: `echo "8:0 rbps=104857600" > /sys/fs/cgroup/batch/io.max` (100MB/s limit). (4) NUMA affinity: if the machine has multiple NUMA nodes, pin each workload to separate nodes: `numactl --cpunodebind=0 --membind=0 api_service` and `numactl --cpunodebind=1 --membind=1 batch_job`. This eliminates cross-NUMA memory contention. Monitoring: `cgroupstats` and cgroup v2 `cpu.stat`, `memory.stat`, `io.stat` provide per-cgroup resource usage. Alert on `memory.pressure` events for the API service cgroup - these indicate the batch job is starving it of memory.

*What separates good from great:* The four-axis solution (CPU, memory, I/O, NUMA), the specific cgroups v2 parameters (not just "use cgroups"), the isolcpus kernel parameter for hard isolation, and the monitoring strategy (cgroup pressure events).

---

**[STAFF] Q10 - [MECHANISM] Explain how NUMA affects OS scheduling decisions and what tuning you would apply to a 4-socket database server.**

On a 4-socket NUMA system, each socket has its own memory controller with 3.5x the bandwidth to local memory (DRAM on its socket) versus remote memory (DRAM on other sockets via the interconnect). The kernel's NUMA scheduler attempts to keep threads on the NUMA node where their working data lives. The NUMA autobalancing mechanism (enabled by default, `kernel.numa_balancing=1`): periodically scans process memory mappings, marks pages as inaccessible (using PTE tricks), waits for page faults, and migrates pages toward the socket where they're accessed. This is lightweight automatic balancing but has overhead from the page migration itself and the fault-induced TLB flushes. Tuning for a 4-socket database: (1) Disable automatic NUMA balancing: `sysctl kernel.numa_balancing=0` for PostgreSQL/Oracle - these databases control their own memory layouts and NUMA autobalancing creates unnecessary page migrations and TLB shootdowns. (2) Pin the database to specific NUMA nodes: for PostgreSQL with a 200GB working set on a 4-socket machine with 50GB/socket, use NUMA nodes 0-1 (100GB total) for the shared_buffers and pin PostgreSQL processes to those nodes via numactl. (3) Set `vm.zone_reclaim_mode=0` (default since Linux 3.12) to allow cross-NUMA memory allocation rather than reclaiming pages from local NUMA (which causes process slowdown) to avoid remote NUMA allocation - zone_reclaim was a notorious performance regression source. (4) Monitor: `numastat -p <PID>` shows per-socket memory distribution; `numastat` shows miss rates (remote accesses). A high "Numa_miss" to "Numa_hit" ratio indicates poor locality.

*What separates good from great:* The zone_reclaim_mode history (was a notorious bug in early Linux, now disabled by default but still configured wrong by old documentation), the NUMA autobalancing trade-off (helpful for diverse workloads, harmful for databases with controlled layouts), and the specific numastat commands.

---

**[STAFF] Q11 - [TRADE-OFF] How do CPU frequency scaling settings affect database performance, and what should you configure in production?**

CPU frequency scaling (cpufreq) governs on CPU manufacturers vary from P-states (Intel) to frequency levels to let the CPU run at lower clock rates to save power. Three governors: `powersave` (minimum frequency, maximum power savings), `ondemand` (ramp up on load, ramp down quickly), `performance` (maximum frequency always). Database impact: (1) Frequency ramp-up latency: `ondemand` takes 20-100ms to ramp from 1.2GHz to 3.6GHz after detecting load. During that ramp, CPU-intensive queries are 2-3x slower. (2) Frequency variance adds latency jitter: a query that takes 5ms at 3.6GHz takes 15ms at 1.2GHz. P99 latency reflects the worst-case frequency, not the average. For production databases: set governor to `performance` on all cores: `echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`. This disables frequency scaling entirely, giving consistent maximum clock speed. Power cost: 15-30W per core additional at maximum frequency. On a 48-core machine, the cost is 720W-1440W additional - significant but justified for latency-sensitive production. The modern alternative: recent Intel CPUs (Skylake and newer) support Hardware P-State (HWP) where the hardware manages frequency transitions in microseconds, faster than the OS governor. For these CPUs, `cpupower frequency-set -g powersave --related` with HWP enabled achieves near-`performance` governor latency with lower power draw.

*What separates good from great:* The frequency ramp-up latency quantification (20-100ms), the cost calculation (720W-1440W for full performance governor), and the HWP (Hardware P-State) as a power-efficient alternative.

---

**[STAFF] Q12 - [DESIGN] Design a capacity planning model for OS-level resources that tells you when to scale a database server before performance degrades.**

A capacity planning model needs four resource dimensions with predictive thresholds. (1) Memory pressure model: metric = `(MemTotal - MemAvailable) / MemTotal` sampled every 60 seconds. Threshold: >80% = scale within 30 days, >90% = scale within 7 days, >95% = emergency scale. Add memory pressure events from `/proc/pressure/memory`: any sustained stall time (full or some) above 5% means active memory contention. (2) CPU saturation model: metric = per-CPU run queue length via `sar -q` or `/proc/schedstat`. Threshold: average run queue > 2 (2 processes waiting per core) for >5 minutes = CPU contention. Formula: `effective_cpu_count = cpu_count / (1 + run_queue_length)`. (3) Dirty page risk model: metric = `Dirty: / MemTotal` from `/proc/meminfo` trend. If the dirty ratio reaches 80% of `vm.dirty_ratio` (i.e., 16% of RAM on default settings), writes will stall soon. Alert on trend: if the dirty ratio is growing at a rate that will reach the threshold within 60 seconds, trigger investigation. (4) I/O saturation model: from `iostat -x`, `%util` > 90% sustained for 5 minutes means the storage device is saturated. `w_await` (write await time) > 2× baseline is an earlier warning signal. Predictive scaling trigger: any single dimension reaching "scale within 7 days" threshold + 2 weeks of data showing monotonic growth = automated scaling recommendation. The monitoring stack: Prometheus with node_exporter (collects all these metrics), recording rules for trend calculations, Grafana dashboards, PagerDuty alerts for threshold breaches.

*What separates good from great:* The pressure events from `/proc/pressure/` (PSI - Pressure Stall Information, added in Linux 4.20) as an early warning metric, the effective CPU count formula for queue-length-based capacity estimation, and the distinction between static threshold alerts and trend-based predictive alerts.

---

### ⚖️ Comparison Table

| Parameter | Default | Write-Heavy Server | Latency-Sensitive DB | Explanation |
|---|---|---|---|---|
| vm.dirty_background_ratio | 10% | 3-5% | 3% | Start flushing earlier |
| vm.dirty_ratio | 20% | 8-10% | 5-8% | Smaller stall window |
| vm.swappiness | 60 | 1 | 1 | Prevent page swap |
| THP | madvise/always | madvise | madvise | App-controlled |
| I/O scheduler (NVMe) | mq-deadline | none | none | NVMe doesn't need reorder |
| net.core.somaxconn | 128 | 65535 | 4096 | Match connection rate |
| CPU governor | ondemand | performance | performance | No frequency jitter |

**The deciding factor:** The most impactful single change for most servers is `vm.dirty_background_ratio` and `vm.dirty_ratio` reduction - it eliminates the most common class of production write stalls. Second most impactful for database servers is `vm.swappiness=1` - prevents the catastrophic latency spike when buffer pool pages are swapped to disk.

---

### 🏛️ System Design

**Where OS-level performance tuning appears in system design:**
- Production database setup procedures and runbooks
- Kubernetes node tuning for DaemonSets (applies sysctl to all pods)
- Cloud VM instance selection and configuration
- SRE incident response (diagnosing unexplained latency spikes)
- Platform engineering (base AMI/image configuration for all services)

**Example question:** "Your company is setting up a new PostgreSQL cluster on bare-metal servers (128GB RAM, 24-core, dual NVMe RAID). What OS-level configuration would you apply before the first production query runs?"

**6-step framework answer:**

Step 1 CLARIFY - What is the expected workload (OLTP vs OLAP vs mixed)? What is the p99 latency target? What is write throughput? Any multi-tenant usage?

Step 2 ESTIMATE - At 128GB RAM and dual NVMe RAID: default dirty_ratio=20% = 25.6GB dirty pages = potential 8-second stall if 3GB/s disk speed. Huge pages for 40GB shared_buffers = 40GB / 2MB = 20,480 pages.

Step 3 DESIGN - Mandatory changes: vm.dirty_background_ratio=3, vm.dirty_ratio=8 (stall at 10.2GB, flush duration 3 seconds max); vm.swappiness=1; vm.nr_hugepages=20480 (explicit huge pages for shared_buffers); I/O scheduler=none for NVMe; cpufreq governor=performance.

Step 4 DEEP DIVE - NUMA tuning: 24-core server is likely single-socket, but verify with `numactl -H`. If single NUMA node, NUMA tuning is irrelevant. If two sockets: pin PostgreSQL to one NUMA node and pin the RAID controller IRQs to the same socket.

Step 5 ALTS - Alternative: run PostgreSQL in a container with Kubernetes. Use sysctl DaemonSet to apply kernel parameters. Use cgroups v2 to protect PostgreSQL from noisy neighbors. More complex but enables standardized base image.

Step 6 EVOLVE - At 10x write volume: single server is I/O-bound. Add read replicas to offload read traffic. Partition write-heavy tables across multiple servers. OS tuning per server remains the same; the architecture change handles the scale increase.

---

### 📊 Diagram

The OS performance tuning decision tree for server workloads:

```
Measure Baseline (before any tuning)
  |
  v
Identify Bottleneck Resource
  |
  +-- CPU-bound? ---> Scheduler tuning
  |    (high %sys,    sched_min_granularity_ns
  |     low %iowait)  sched_migration_cost_ns
  |                   cpufreq -> performance
  |
  +-- Memory-bound? -> Memory tuning
  |    (high page      vm.swappiness=1
  |     faults,        vm.nr_hugepages
  |     swap usage)    THP -> madvise
  |
  +-- IO-bound? ----> IO tuning
  |    (high %iowait   vm.dirty_*_ratio
  |     high w_await)  io_scheduler
  |                    readahead
  |
  +-- Network-bound? -> Network tuning
       (high          net.core.somaxconn
        connection    tcp_rmem/wmem
        drops)        tcp_congestion_control

Measure After -> Compare -> Commit or Revert
```

> **Diagram walkthrough:** This shows the four-path tuning decision tree rooted at bottleneck identification. The critical first node is "Measure Baseline" - tuning without measurement is guesswork. Each path leads to the specific kernel parameters relevant to that resource dimension: CPU scheduling parameters for CPU-bound work, memory management parameters for memory pressure, dirty page and I/O scheduler parameters for I/O bottlenecks, and network stack parameters for connection-limited services. The key relationship: each path is exclusive in terms of priority - fix the primary bottleneck first, because fixing a secondary bottleneck when the primary is not addressed produces no measurable improvement. The edge case: a workload that appears CPU-bound may actually be I/O-bound with high iowait masking as %user CPU - check `%iowait` separately from `%user`. The senior insight: the final node (measure after, compare, commit or revert) is non-negotiable - without this verification, you're not tuning, you're guessing.

The following Mermaid diagram shows the dirty page lifecycle and flush triggering:

```mermaid
flowchart TD
    AppWrite[Application write()] --> DirtyPage[Page marked dirty\nin page cache]
    DirtyPage --> Counter[Dirty page counter\nincrements]
    Counter --> BgCheck{Dirty >\ndirty_background_ratio?}
    BgCheck -->|No| Continue[Application continues]
    BgCheck -->|Yes| BgFlush[Background writeback\nkworker starts flushing]
    BgFlush --> Continue
    Counter --> HardCheck{Dirty >\ndirty_ratio?}
    HardCheck -->|No| Continue
    HardCheck -->|Yes| Stall[ALL writes stall\nuntil dirty < background_ratio]
    Stall --> FlushDone[Kernel flushes to disk\nat max disk speed]
    FlushDone --> Resume[Writes resume]
    style Stall fill:#f66,stroke:#900
    style BgFlush fill:#9f9,stroke:#090
```

> **Diagram walkthrough:** This flow chart shows the dirty page lifecycle with two key thresholds. Normal write path (left): every write() marks pages dirty and increments the dirty counter. Below dirty_background_ratio, no background flushing occurs. Above dirty_background_ratio (green path), the kernel starts a background writeback thread that continuously flushes pages without stalling the application. The critical red path: above dirty_ratio, ALL application writes stall until the dirty count drops below dirty_background_ratio - a double threshold requirement that ensures the background flush gets ahead of the write stream. The key relationship: the gap between dirty_background_ratio (10%) and dirty_ratio (20%) determines the stall window size; narrowing this gap (5% vs 8%) reduces stall magnitude. The edge case: if the disk cannot flush at the rate applications are writing, dirty pages will oscillate at the dirty_ratio threshold, causing permanent write stalls - this means the storage is undersized for the write workload, and no amount of parameter tuning will fix it. The senior insight: the background flush (green) is the design; the stall (red) is the safety valve. Tuning should maximize background flush time and minimize stall time.
