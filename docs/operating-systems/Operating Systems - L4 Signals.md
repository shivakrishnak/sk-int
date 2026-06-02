---
layout: default
title: "Operating Systems - L4 Signals"
parent: "Operating Systems"
nav_order: 13
permalink: /operating-systems/l4-signals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Signals, Interrupts, and Exception Handling](#signals-interrupts-and-exception-handling) | critical |

---

# Signals, Interrupts, and Exception Handling

🎯 Interview Weight: Critical - Signal handling, interrupt latency, and exception delivery appear in senior systems, embedded, JVM internals, and reliability engineering interviews. Understanding why SIGKILL cannot be caught, how the JVM uses SIGSEGV for null checks, and why `sa_flags = SA_RESTART` exists requires knowing how the kernel delivers asynchronous events.

---

## 📋 Quick Reference

**One-line definition:** Signals are software-level asynchronous notifications delivered by the kernel to a process; hardware interrupts are CPU-level asynchronous events from peripheral devices; exceptions (traps/faults) are synchronous CPU events triggered by instruction execution. All three converge at the kernel's interrupt descriptor table.

**Difficulty:** ★★★ | **Asked at:** Senior-Staff | **Seniority:** Senior-Staff

---

### 🎯 Model Answer

**30 seconds:**
> Signals, interrupts, and exceptions are the three mechanisms by which the CPU or kernel asynchronously diverts normal program execution. Hardware interrupts come from devices (NIC, disk, timer). Exceptions come from the CPU itself when an instruction fails (SIGSEGV for null deref, SIGFPE for divide-by-zero). Signals are the kernel's abstraction that delivers all of these to user-space programs. The critical distinction is SIGKILL and SIGSTOP cannot be caught or ignored because they are delivered by kernel code that bypasses the user-space signal handler entirely - they directly modify process state.

**3 minutes (Senior):**
> I think of signals as the kernel's message passing system to processes. The three event sources are: (1) hardware interrupts - a peripheral fires an interrupt line, the CPU saves state and calls the kernel's ISR (Interrupt Service Routine). The ISR might wake a process (new data arrived on a socket), which causes a signal eventually but not immediately. (2) CPU exceptions - the CPU itself generates a synchronous fault during instruction execution. A null pointer dereference generates a page fault (exception vector 14 on x86); the kernel's page fault handler checks if it's a legitimate faulting address or a null deref, and sends SIGSEGV to the faulting process. (3) Kill/raise/tgkill - explicit software delivery, where one process or the kernel sends a signal to another.
>
> In production, signals matter in three ways. First, signal safety: signal handlers run asynchronously in the middle of any other operation. Calling malloc() inside a signal handler is undefined behavior (malloc holds internal locks, reentrancy causes deadlock). Only async-signal-safe functions are permitted. Second, interrupted system calls: a signal delivered during a blocking read() causes the syscall to return -1 with errno=EINTR. Libraries that don't check for EINTR and retry are broken in signal-heavy environments. `sa_flags = SA_RESTART` makes the kernel automatically restart most syscalls after signal delivery. Third, JVM use of signals: the HotSpot JVM installs SIGSEGV and SIGBUS handlers to implement NullPointerException. Instead of a null check before every field access (expensive), the JVM lets the CPU generate SIGSEGV on null dereference and converts it to a NullPointerException via the signal handler. This is a hardware-assisted optimization that makes null checks effectively free.

**Framework:** WHAT → HOW DELIVERED → SIGNAL SAFETY → JVM CASE

*Adapting up:* Add real-time signals (SA_SIGINFO, sigqueue), signal masking in multithreaded programs (pthread_sigmask), async-signal-safe function list and why malloc is not on it.

*Adapting down:* WHAT (asynchronous notifications) + three kinds (hardware, software, CPU exception) + why SIGKILL cannot be caught.

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about signals, interrupts, and exceptions - let me think through what problem each one solves."

**(2) First principles:** "Programs need to respond to external events (disk I/O complete, timer fired, another process died) without polling. The mechanism that makes this possible is the interrupt or signal - the hardware or kernel pokes the CPU to stop what it's doing and handle the event."

**(3) Bridge:** "This is like a callback system, but at the hardware level. Signals are the user-space API of that callback system. The asynchronous delivery is what makes them powerful and dangerous - a signal handler runs inside the existing stack frame at a random point in execution, which is why reentrancy matters."

---

### 📘 Concept Explanation

**What it is:**
Signals are integers (1-64 on Linux) that the kernel delivers to a process by: setting a pending bit in the process's task_struct, and then at the next kernel-to-user-space transition (syscall return or interrupt return), checking the pending signals, saving the user-space registers, and jumping to the signal handler before returning to user code.

Hardware interrupts are electrical signals on the CPU's interrupt pins (or MSI on PCIe) that cause the CPU to save state and jump to the kernel's Interrupt Descriptor Table (IDT) entry for that interrupt vector.

Exceptions are CPU-generated events from instruction execution: page faults (vector 14), general protection faults (vector 13), divide-by-zero (vector 0), invalid opcode (vector 6). These are synchronous - they occur at the exact instruction that caused them.

**The problem it solves:**
Without signals and interrupts, programs would need to poll for every event: "is the socket readable? is the timer expired? did a child process exit?" Polling wastes CPU time and introduces latency. The interrupt model lets the hardware notify the kernel (and the kernel notify user processes) with minimal latency, with the CPU idle (or doing other work) until the event arrives.

**How it works:**

Signal delivery lifecycle:

```
Event Source               Kernel                 User Process
-----------                ------                 ------------
Device IRQ     -->  ISR runs, may set        -->  (later, on return)
                    pending signal bit
kill() syscall -->  kernel marks signal      -->  signal handler runs
                    pending in task_struct        at next kernel exit
CPU exception  -->  page_fault_handler runs  -->  signal handler runs
(SIGSEGV)           --> sends SIGSEGV              immediately on
                    to current task               return from fault
```

> **Diagram walkthrough:** This shows the three paths by which events reach user-space signal handlers. Path 1 (Device IRQ): a hardware interrupt fires, the kernel ISR runs in interrupt context, and may mark a signal pending on a sleeping process - that process will see the signal the next time it exits kernel mode. Path 2 (kill syscall): another process calls kill(), the kernel immediately marks the target's pending signal bitmask, and the target sees it at its next kernel exit. Path 3 (CPU exception): the CPU raises an exception synchronously during instruction execution, the kernel exception handler determines what signal to send (SIGSEGV, SIGFPE, etc.), and the signal is delivered immediately on return from the exception handler. The key relationship: all three paths converge at the kernel's "pending signal check" that runs on every kernel-to-user-mode transition. The edge case: if the signal is masked (blocked by sigprocmask), it stays pending in the task_struct until the process unblocks it - then all pending instances are delivered. The senior insight: signal delivery adds one kernel-to-user-mode transition overhead (~1 microsecond on a fast system call path), which is why high-frequency signal delivery (e.g., SIGALRM every millisecond) degrades performance.

x86 CPU exception to signal mapping (partial):
- Vector 0 (divide error) → SIGFPE
- Vector 6 (invalid opcode) → SIGILL
- Vector 11 (segment not present) → SIGBUS
- Vector 13 (GPF) → SIGSEGV
- Vector 14 (page fault) → SIGSEGV or SIGBUS (depending on fault type)

**The key insight:**
SIGKILL and SIGSTOP cannot be caught or ignored because the kernel delivers them by directly modifying process state (task_struct.state = TASK_DEAD for KILL, TASK_STOPPED for STOP) without going through the normal signal handler dispatch. The process's registered handler for SIGKILL (if any) is never called. This is a deliberate design choice: a process that ignores all signals and loops forever would be uncontrollable without an uncatchable termination mechanism.

**When to use signal handlers:**
- Graceful shutdown: SIGTERM handler to flush buffers, close connections, drain queues before exit
- Log rotation: SIGHUP handler to re-open log file descriptors (classic Unix daemon pattern)
- Statistics dump: SIGUSR1 handler to print internal state without interrupting service
- Child reaping: SIGCHLD handler to call waitpid() without blocking (avoids zombie processes)

**When NOT to use signal handlers:**
- As a regular IPC mechanism (use pipes, sockets, or message queues instead - they're buffered and reliable)
- For high-frequency notifications (>1K signals/second causes overhead from context switches)
- To call non-async-signal-safe functions (malloc, printf, most library functions are NOT safe)
- For complex state modification (signal handlers should be minimal - set a flag, then return)

**Alternatives:**
- signalfd(): read signals like file descriptors, integrates with select/epoll, allows calling non-async-signal-safe code in the signal processing context
- sigwait()/sigwaitinfo(): block until a signal arrives, process in the main event loop
- Self-pipe trick: signal handler writes one byte to a pipe, main loop reads the pipe via select/epoll

**First-principles derivation:**
The kernel needs to interrupt a running process asynchronously. Options: (A) polling - process checks a flag before every operation. Too slow and misses events. (B) IPC message queue - requires process to actively read messages. Doesn't work if process is blocked in a syscall. (C) Interrupt the process's execution directly by saving state and redirecting the instruction pointer to a handler - this is what signals do. The tricky part is executing the handler in user-space (not kernel) to avoid privilege issues, so the kernel saves the user-space registers to the user stack and sets the instruction pointer to the signal handler. When the handler returns (via sigreturn() syscall), the kernel restores the original registers. This creates a nested execution context on the user stack.

---

### 💻 Code Example

**BAD: Unsafe signal handler calling non-async-signal-safe functions**

```c
// BAD: malloc and printf are NOT async-signal-safe.
// If SIGTERM arrives while malloc holds its internal
// lock, calling malloc in the handler causes deadlock.
// printf has the same problem with the FILE* lock.

static volatile int should_exit = 0;
static char* cleanup_buffer = NULL;

void bad_signal_handler(int sig) {
    // WRONG: malloc may deadlock if signal arrives
    // during malloc in main thread
    cleanup_buffer = malloc(1024);
    // WRONG: printf is not async-signal-safe
    printf("Signal %d received, cleaning up\n", sig);
    // WRONG: calling complex library functions
    fclose(log_file);
    should_exit = 1;
}

int main() {
    signal(SIGTERM, bad_signal_handler);
    while (!should_exit) {
        // malloc called here; if SIGTERM arrives
        // mid-malloc, bad_signal_handler's malloc
        // call deadlocks on the allocator lock
        process_request();
    }
}
```

> **Code walkthrough:** This shows the async-signal-safe violation pattern. malloc(), printf(), and fclose() all use internal locks (mutex/spinlock). If SIGTERM arrives while the main thread is inside malloc(), the main thread holds the allocator lock. The signal handler then calls malloc() again on the same thread - but the lock is already held by the same thread (which is now paused). On most implementations this results in a deadlock because POSIX mutexes are not recursive. The symptom is the process hanging on SIGTERM - it doesn't exit, it deadlocks. This is a hard bug to reproduce because it's timing-dependent; it happens only when the signal arrives at the exact moment malloc holds its lock.

**GOOD: Minimal safe signal handler with self-pipe pattern**

```c
// GOOD: Signal handler only writes one byte to a pipe.
// write() is async-signal-safe. Main loop handles
// the event in normal (non-signal) context, where
// all library functions are safe.

#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>

static int signal_pipe[2];  // [0]=read, [1]=write

// Only async-signal-safe operations in handler
void safe_signal_handler(int sig) {
    // write() is async-signal-safe
    // one-byte write to pipe won't block (pipe buffer
    // is 64KB; one byte per signal is negligible)
    char byte = (char)sig;
    write(signal_pipe[1], &byte, 1);
    // DO NOT: malloc, printf, fclose, or ANY other
    // non-async-signal-safe function
}

int main() {
    // Create non-blocking pipe
    pipe(signal_pipe);
    fcntl(signal_pipe[1], F_SETFL, O_NONBLOCK);

    struct sigaction sa = {0};
    sa.sa_handler = safe_signal_handler;
    // SA_RESTART: auto-restart interrupted syscalls
    sa.sa_flags = SA_RESTART;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT,  &sa, NULL);

    fd_set rfds;
    while (1) {
        FD_ZERO(&rfds);
        FD_SET(signal_pipe[0], &rfds);
        FD_SET(server_fd, &rfds);

        select(max_fd + 1, &rfds, NULL, NULL, NULL);

        if (FD_ISSET(signal_pipe[0], &rfds)) {
            char sig_byte;
            read(signal_pipe[0], &sig_byte, 1);
            // Handle signal in normal context -
            // malloc, printf, etc. all safe here
            handle_shutdown((int)sig_byte);
        }
        if (FD_ISSET(server_fd, &rfds)) {
            handle_request();
        }
    }
}
```

> **Code walkthrough:** This is the self-pipe trick, the canonical pattern for safe signal handling in event-loop servers. The signal handler does exactly one thing: write a byte (the signal number) to a non-blocking pipe. The main event loop uses select/epoll to watch the read end of that pipe alongside normal I/O. When select() returns with the pipe readable, the main loop reads the signal byte and handles it with full access to all library functions - malloc, logging, complex shutdown logic - because it's no longer in signal handler context. The `SA_RESTART` flag tells the kernel to automatically restart interrupted system calls (read, write, select, accept) after the signal handler returns, which prevents the common bug where server code returns -1/EINTR and doesn't retry. The production consequence: this pattern is how every production server (nginx, Redis, PostgreSQL) handles signals - minimal handler, full processing in event loop.

**JVM null pointer check via SIGSEGV**

```java
// The JVM uses SIGSEGV to implement null checks efficiently
// Instead of emitting: if (obj == null) throw NPE; before
// every field access, HotSpot lets the CPU page-fault on
// the null dereference and converts SIGSEGV to NPE via
// its registered signal handler.

// Java code (compiled by JIT):
public int getField(MyObject obj) {
    return obj.value;  // no explicit null check emitted
}

// JIT-compiled native code (pseudoassembly):
// MOV RAX, [RDI + offset_of_value]  <- one instruction
// If RDI is null (0), this generates a page fault at
// address (offset_of_value) which is in the first page.
// The kernel sends SIGSEGV. HotSpot's SIGSEGV handler
// checks if the faulting address is in the "null region"
// (first 64KB), and if so, throws NullPointerException
// from the current Java stack frame.
```

> **Code walkthrough:** This shows how HotSpot JVM converts a hardware SIGSEGV into a Java NullPointerException without any explicit null check instruction. The JIT compiler emits a direct field access (one load instruction), relying on the fact that null (0) + any field offset is within the first 4KB page, which is never mapped. When the load faults, the JVM's SIGSEGV handler (installed at JVM startup via sigaction) checks whether the faulting address is near zero - if yes, it's a null dereference. The handler then unwinds the Java stack and throws NPE from the appropriate stack frame. The production consequence: this makes null checks free for the common case (non-null), paying only the SIGSEGV overhead for actual null dereferences. The WHAT BREAKS scenario: if something else maps memory at address 0 (via mmap with MAP_FIXED at addr=0, which is possible but unusual), the JVM can no longer distinguish null dereferences from legitimate accesses to page 0, causing incorrect NPE delivery.

**Signal masking in multithreaded server**

```c
// In a multithreaded server, signals are delivered to
// any thread - which one is OS-defined. The pattern:
// mask signals in worker threads, dedicate one thread
// to signal handling via sigwait().

void* worker_thread(void* arg) {
    // Block all signals in worker threads so signals
    // are only handled by the designated signal thread
    sigset_t mask;
    sigfillset(&mask);
    pthread_sigmask(SIG_SETMASK, &mask, NULL);

    // Do real work - never interrupted by signals
    while (1) { process_request(); }
    return NULL;
}

void* signal_thread(void* arg) {
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGTERM);
    sigaddset(&mask, SIGHUP);
    sigaddset(&mask, SIGUSR1);
    pthread_sigmask(SIG_SETMASK, &mask, NULL);

    int sig;
    while (1) {
        // sigwait blocks until one of the masked signals
        // arrives; handles it in normal thread context -
        // malloc, logging, complex logic all safe here
        sigwait(&mask, &sig);
        switch (sig) {
            case SIGTERM: initiate_shutdown(); break;
            case SIGHUP:  reload_config(); break;
            case SIGUSR1: dump_statistics(); break;
        }
    }
    return NULL;
}
```

> **Code walkthrough:** This shows the dedicated signal thread pattern for multi-threaded servers. By masking all signals in worker threads (pthread_sigmask SIG_SETMASK with full mask), signals are never delivered to workers - workers can use blocking I/O and non-async-signal-safe functions without worry. The signal thread unblocks only the signals it wants and calls sigwait(), which atomically waits for a signal and returns it as an integer - no signal handler function, no reentrancy concerns. All signal handling runs as regular code with full library access. This is the pattern used by Java's JVM (HotSpot manages signals this way internally), Go's runtime, and most production servers written in C. The WHAT BREAKS scenario: if the signal thread crashes or exits, signals accumulate as pending in the process. SIGTERM will eventually be delivered to a random worker thread (OS-defined) which has no handler, causing default termination behavior.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Signals are asynchronous notifications from the kernel to a process. Common signals: SIGTERM (graceful shutdown), SIGKILL (force kill, uncatchable), SIGHUP (reload config), SIGUSR1/SIGUSR2 (user-defined). You install a signal handler with sigaction() (preferred) or signal() (deprecated). The main constraints: only call async-signal-safe functions inside signal handlers (essentially just write(), signal(), and a few others). For most use cases, use the self-pipe trick: signal handler writes to a pipe, main loop reads the pipe.

*Push deeper:* What happens when a signal arrives during a blocking read()? Answer: read() returns -1 with errno=EINTR. Code that doesn't check for EINTR and retry is broken. SA_RESTART eliminates this for most syscalls.

---

**Senior / Staff (5+ years):**
> At senior level, signal knowledge maps to four production scenarios. First: signal-safe programming - sigaction with SA_RESTART, self-pipe or signalfd for event-loop integration, never calling malloc/printf/fclose in handlers. Second: multithreaded signal handling - pthread_sigmask to route signals to a dedicated thread, sigwait() for synchronous handling with full library access. Third: signal interaction with JVMs - HotSpot installs SIGSEGV and SIGBUS handlers for null pointer optimization; installing your own handlers with signal() will break the JVM. Use JVM's alternative stack (SIGSTKSZ) if you need to catch SIGSEGV in JNI code. Fourth: SIGCHLD and zombie processes - every forked child must be reaped with waitpid(); SIGCHLD handler calling waitpid(-1, WNOHANG) in a loop is the correct pattern. Installing SIG_IGN for SIGCHLD tells the kernel to auto-reap children without zombie creation (Linux 2.6+ feature).

*Push deeper:* Real-time signals (signals 34-64 on Linux, SIGRTMIN to SIGRTMAX). Unlike standard signals, real-time signals are queued (not coalesced), carry an integer payload (si_value from sigqueue()), and are delivered in order. Used for POSIX AIO completion notification and custom application protocols that need guaranteed delivery.

---

### ⚠️ Common Misconceptions

**Misconception 1: "SIGKILL is delivered via the same mechanism as other signals"**

SIGKILL bypasses the entire signal delivery mechanism. When the kernel sends SIGKILL to a process, it calls complete_signal() which sets a force_sig flag in the task_struct and wakes the process (if blocked in an interruptible wait). The process cannot check for pending signals, run signal handlers, or delay termination. The force flag causes the process to exit at the next kernel-to-user transition, regardless of any installed handler. A signal handler installed for SIGKILL via sigaction() is silently ignored by the kernel - the handler function is never called.

**Misconception 2: "SA_RESTART makes all syscalls restart after signals"**

SA_RESTART causes most but not all syscalls to restart. The syscalls that do NOT restart even with SA_RESTART: select(), pause(), nanosleep(), semwait(), and certain socket operations with timeouts. These return EINTR regardless. The reason: these are "long waits" where the kernel's policy is that a signal should always interrupt them - restarting would negate signal responsiveness. Code using these syscalls MUST handle EINTR and retry explicitly. The POSIX standard explicitly lists which syscalls are SA_RESTART-restartable; the list is shorter than most engineers expect.

**Misconception 3: "Signal handlers run on the same stack as the interrupted code"**

Signal handlers run on the process's normal user stack (the current thread's stack), which is why recursive signal delivery or signal handlers in stack-overflow scenarios are problematic. If a program overflows its stack (SIGSEGV on stack growth), the default signal handler cannot run because it needs stack space. The solution: `sigaltstack()` designates an alternate signal stack (typically SIGSTKSZ bytes, ~8KB) specifically for signal handlers. Crash reporting tools and JVMs configure alternate signal stacks so that stack overflow reports can be generated even after stack exhaustion.

**Misconception 4: "All threads in a process receive a signal"**

Signals sent to a process (kill(pid, sig)) are delivered to exactly one thread, chosen by the kernel (whichever thread is most convenient to interrupt - typically the one not blocking the signal). Signals sent to a specific thread (tgkill(pid, tid, sig)) go to that thread only. pthread_sigmask lets each thread have its own signal mask, enabling the pattern of masking signals in all worker threads so only the dedicated signal thread receives them. A signal ignored in the per-process action (sigaction with SIG_IGN) is ignored for all threads.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Zombie Process Accumulation**

Symptom: `ps aux | grep Z` shows many zombie processes; process table fills up (max ~32K processes on default Linux), causing fork() to fail with EAGAIN.

Cause: parent process forked children without calling waitpid() when SIGCHLD is received. The kernel retains the child's exit status in the process table until the parent calls waitpid() to collect it.

Diagnosis:
```bash
# Count zombie processes
ps aux | awk '$8 == "Z" { count++ } END { print count }'

# Find the parent of zombies
ps -ef | grep defunct | awk '{print $3}' | sort | uniq -c
# The parent PID (column 3) is the process that must call waitpid()
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix options: (1) Install SIGCHLD handler that calls `waitpid(-1, &status, WNOHANG)` in a loop until it returns 0 (all available exit statuses collected). (2) Set `signal(SIGCHLD, SIG_IGN)` - on Linux 2.6+, this tells the kernel to auto-reap children without zombie creation. (3) Use the SA_NOCLDWAIT flag in sigaction() for the same effect.

**Failure 2: EINTR Not Handled - Silent Request Loss**

Symptom: under high signal load (SIGCHLD from many short-lived children, frequent SIGALRM, or SIGUSR1 statistics dump), some requests are silently dropped; TCP connections reset without sending a response.

Cause: code like `n = read(fd, buf, size); if (n < 0) return error;` does not distinguish EINTR from real errors. When a signal interrupts read(), it returns -1 with errno=EINTR, and the code treats it as an unrecoverable error, closing the connection.

Diagnosis:
```bash
# strace shows EINTR returns
strace -e trace=read,write -p <PID> 2>&1 | grep EINTR
# Each "= -1 EINTR" line is a dropped retry

# Check SA_RESTART is set in signal handlers
cat /proc/<PID>/fdinfo/<sigaction_fd>  # limited visibility
# Better: code review - grep the codebase for signal()
# and sigaction() calls, verify SA_RESTART is set
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix: wrap all I/O syscalls in a retry loop:
```c
ssize_t robust_read(int fd, void* buf, size_t count) {
    ssize_t n;
    do { n = read(fd, buf, count); }
    while (n < 0 && errno == EINTR);
    return n;
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Or use SA_RESTART in sigaction() flags - simpler, handles most cases automatically.

**Failure 3: Signal Handler Deadlock**

Symptom: process stops responding after receiving a signal (SIGTERM, SIGUSR1); kill -9 is required; strace shows the process hung in futex or mutex operations.

Cause: non-async-signal-safe function called in signal handler. malloc(), printf(), syslog(), dlsym() all acquire internal locks. If the signal arrives while the main thread holds that lock, the signal handler calls the same function, attempting to acquire the same lock, deadlocking.

Diagnosis:
```bash
# Attach gdb to the hung process
gdb -p <PID>
# In gdb:
(gdb) thread apply all bt
# Look for a thread in __lll_lock_wait (futex)
# with malloc or printf in its backtrace

# Also check with pstack (simpler):
pstack <PID>
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Fix: signal handlers MUST only call async-signal-safe functions. See `man 7 signal-safety` for the complete list. Use the self-pipe trick or signalfd to move signal processing out of the signal handler.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | Signal delivery, SIGKILL, real-time signals |
| Debugging | 3 | Zombie processes, EINTR, handler deadlock |
| Trade-off | 2 | signalfd vs self-pipe, SA_RESTART scope |
| Behavioral | 1 | Production signal debugging story |
| Design | 2 | Graceful shutdown, multi-threaded signal routing |
| JVM-specific | 1 | SIGSEGV-as-null-check |

---

**[JUNIOR] Q1 - [MECHANISM] What is the difference between SIGTERM and SIGKILL? Why does SIGKILL always work?**

SIGTERM (signal 15) is a request for graceful termination. The process receives it, and if it has installed a SIGTERM handler, that handler runs. The handler can flush buffers, close connections, drain work queues, and then call exit(). If no handler is installed, the default action is to terminate the process. SIGKILL (signal 9) is an unconditional termination command. It bypasses the signal handler mechanism entirely. The kernel implements SIGKILL by directly setting the process's state to "being killed" via force_sig(), which prevents any future execution in user space. At the next kernel-to-user transition, the process is killed. There is no path by which a process can catch, ignore, or delay SIGKILL. SIGKILL always works because the kernel makes the decision to terminate without consulting the process. The only cases where SIGKILL appears to not work: (1) processes in uninterruptible sleep (D state in `ps`), waiting on kernel I/O - SIGKILL is delivered when the I/O completes and the process wakes up. (2) zombie processes - already dead, no process to kill, parent must reap. (3) kernel bugs (very rare). Production implication: SIGTERM gives a process time to clean up; SIGKILL does not. The graceful shutdown pattern is: send SIGTERM, wait N seconds, if still alive send SIGKILL. This is exactly what `systemd` does with `TimeoutStopSec` and `KillMode` settings.

*What separates good from great:* The D-state (uninterruptible sleep) explanation - this is why `kill -9` sometimes appears to not work, and understanding that the process is stuck in kernel I/O, not ignoring the signal.

---

**[JUNIOR] Q2 - [MECHANISM] What is a zombie process and how do you prevent them?**

A zombie process is a process that has exited (called exit() or was killed) but whose entry in the kernel's process table has not been removed because its parent has not called waitpid() to collect its exit status. The kernel keeps the process table entry to store the exit code until the parent asks for it. Zombie processes consume a process table entry (one slot in the kernel's pid namespace, default max ~32K) but no CPU or memory. Prevention: the parent must call waitpid() for every child process. Three patterns: (1) blocking waitpid() - parent calls `waitpid(child_pid, &status, 0)` immediately after forking; simple but blocks the parent. (2) SIGCHLD handler - install a handler that calls `waitpid(-1, &status, WNOHANG)` in a loop; reaps children asynchronously as they exit. (3) SIG_IGN for SIGCHLD - `signal(SIGCHLD, SIG_IGN)` tells Linux to auto-reap children without zombie creation (POSIX allows but doesn't require this; Linux 2.6+ implements it). If the parent dies before the child, init (pid 1) inherits the orphaned child and calls waitpid() automatically. The zombie then disappears quickly. Production failure: a web server that forks CGI processes for each request without reaping will accumulate zombies until the process table is full, causing all fork() calls to fail with EAGAIN.

*What separates good from great:* The SIG_IGN option (not just SIGCHLD handler), the orphan → init reparenting (which makes the zombie disappear), and the specific failure mode (process table exhaustion → fork() fails).

---

**[MID] Q3 - [MECHANISM] Why can't you call malloc() inside a signal handler? What CAN you call?**

malloc() is not async-signal-safe because it uses internal locks (a mutex or spinlock) to protect its free-list data structures. If a signal is delivered while the main thread is inside malloc() (holding the malloc lock), and the signal handler calls malloc(), the signal handler tries to acquire the same lock on the same thread. POSIX mutexes are non-recursive by default, so this results in deadlock (the lock is already held, the re-acquisition blocks forever, the main thread never resumes). The same applies to printf() (FILE* buffer lock), syslog() (syslog socket lock), and any function that uses global or thread-local state with mutual exclusion. What IS async-signal-safe: the POSIX standard (POSIX.1-2008 Section 2.4.3) lists ~70 functions. Key ones: write(), read(), open(), close(), kill(), raise(), signal(), sigaction(), sigprocmask(), _exit() (but not exit()), getpid(), getppid(), and most raw syscall wrappers. Functions not on this list are unsafe. The safe pattern for complex signal handling: signal handler does exactly one safe thing (typically `write(pipe_fd, &sig, 1)`) and returns immediately. The main loop reads from the pipe and handles the signal with full library access.

*What separates good from great:* Explaining WHY it's a deadlock (same thread, non-recursive lock) not just "it's not safe," and knowing the self-pipe trick as the practical solution.

---

**[MID] Q4 - [DEBUGGING] Your Go service is occasionally failing to respond to SIGTERM during deployment. What would you investigate?**

Five areas to investigate in order of likelihood. (1) Missing signal handler in the application: verify the Go code uses `signal.Notify(ch, syscall.SIGTERM)` with a goroutine reading from ch. If not, Go's default SIGTERM action is to call `os.Exit(0)` immediately without cleanup. (2) Signal blocked: check if the process is in D state (`ps aux` showing D in state column) - uninterruptible sleep means the kernel queues SIGTERM but it's not delivered until the I/O completes. This can take seconds to minutes. (3) SIGTERM delivered to a thread that doesn't handle it: in Go, the runtime installs its own signal handlers. If external code (CGO) has overridden them with SIG_IGN, SIGTERM is silently ignored. (4) Application shutdown is hung: SIGTERM was received, the shutdown handler started, but it's stuck waiting on a resource (database connection, channel send to a full buffer, or a goroutine that doesn't check for context cancellation). Use `kill -SIGABRT <PID>` to get a stack trace, or enable `GOTRACEBACK=all` in the environment. (5) systemd/Kubernetes timeout too short: the deployment tool sends SIGTERM, waits 30 seconds (default), then sends SIGKILL. If the application needs more than 30 seconds to drain, it gets killed before completion. Fix: increase `terminationGracePeriodSeconds` in Kubernetes pod spec.

*What separates good from great:* The D-state explanation (SIGTERM is queued, not lost), the GOTRACEBACK diagnostic for hung shutdown handlers, and the Kubernetes terminationGracePeriodSeconds setting.

---

**[SENIOR] Q5 - [MECHANISM] How does the JVM use SIGSEGV to implement NullPointerException without per-access null checks?**

This is the "implicit null check" optimization in HotSpot JVM. Instead of emitting an explicit comparison-and-branch before every field access (`if (obj == null) throw new NullPointerException()`), the JIT compiler emits a single load instruction (`MOV RAX, [RDI + field_offset]`). If obj is null (0), then the address accessed is field_offset (e.g., 16 bytes) - within the first 64KB of virtual address space. On Linux, the first page (0x0-0xFFF on 4KB pages, or the first 64KB as a safety margin) is never mapped. The CPU generates a SIGSEGV when it tries to access an unmapped page. HotSpot installs a SIGSEGV handler (via sigaction) at JVM startup. When the handler fires: (1) it reads the faulting instruction pointer, (2) checks the JVM's compiled-method table for a method containing that instruction, (3) if found and the faulting address is in the null region (< 64KB), it identifies this as an implicit null check, (4) redirects execution to a NullPointerException throw path in the compiled method. The net effect: null access costs one SIGSEGV handler invocation (~2-5 microseconds) instead of one branch instruction per access. For the common case (non-null), this is zero cost vs one branch. For actual nulls, it's slower (SIGSEGV is expensive) but nulls are exceptions. Implication for JNI code: if you install your own SIGSEGV handler in a JNI library, you must call the previous handler (stored from sigaction's oldact parameter) for any SIGSEGV that isn't yours, or the JVM's null check mechanism breaks.

*What separates good from great:* The exact mechanism (unmapped first page, faulting address < 64KB), the performance asymmetry (free for non-null, expensive for actual null), and the JNI conflict implication.

---

**[SENIOR] Q6 - [TRADE-OFF] Compare signalfd() vs the self-pipe trick for signal handling in an event-loop server.**

Self-pipe trick: signal handler writes a byte to a pipe, main loop watches the read end with select/epoll. Works on all Unix versions, simple to understand, integrates with any event loop. Limitations: requires two file descriptors (pipe has read+write end), write-in-handler is technically correct but has edge cases if the pipe is full (signal drops). signalfd(): Linux-specific (kernel 2.6.22+). Call `signalfd(-1, &mask, SFD_NONBLOCK)` to get a file descriptor that delivers signal information when read. Read returns a `struct signalfd_siginfo` with signal number, sending PID, sending UID, and payload (for real-time signals). Advantages over self-pipe: single file descriptor, richer signal information (no need for a separate siginfo_t lookup), atomic signal mask and fd creation, the kernel queues signals so no signal can be lost even if the event loop is busy. The critical requirement: you MUST block (pthread_sigmask/sigprocmask) the signals you want to receive via signalfd; if you don't block them, they're delivered via the normal handler mechanism AND the fd, causing double processing. My recommendation: use signalfd on Linux systems for any new server code. Use self-pipe for portable code or when running on macOS/BSD. For Go code, use signal.Notify() which implements signalfd-like behavior in the Go runtime.

*What separates good from great:* The richer signalfd_siginfo structure (useful for diagnosing which process sent the signal), the mandatory sigprocmask requirement (forgotten by most engineers using signalfd for the first time), and the signal queueing advantage.

---

**[SENIOR] Q7 - [DEBUGGING] A multi-threaded C server starts dropping connections after 6 hours of runtime. strace shows read() returning -1 with EINTR. What is happening and how do you fix it?**

The pattern: read() returning -1/EINTR means a signal was delivered while the thread was blocked in read(). After the signal handler returns, the kernel returns EINTR to tell the application "you were interrupted; retry if you want." The fact that it starts after 6 hours suggests a time-based trigger: a scheduled job starts every 6 hours (cron job on the hour, log rotation via SIGHUP, etc.) that sends signals to the server. The signals interrupt worker threads' read() calls. If the code doesn't check for EINTR and retry, it treats the interruption as an error and closes the connection. Investigation: strace -e trace=read -p <worker_thread_pid> - confirm EINTR frequency and timing. Check cron jobs: `crontab -l` and `/etc/cron.*` for jobs running every 6 hours. Check logrotate: `/etc/logrotate.conf` and `/etc/logrotate.d/` for scripts that send SIGHUP at the 6-hour mark. Check SIGCHLD: if a background child process exits every 6 hours and SIGCHLD is not masked in worker threads, each exit generates an EINTR. Fix priority order: (1) Use SA_RESTART in sigaction() for all installed signal handlers - this makes the kernel auto-restart read/write/accept after signal delivery, no code changes needed. (2) Wrap read() in EINTR retry loop where SA_RESTART doesn't apply (select, nanosleep). (3) Mask signals in worker threads with pthread_sigmask and use a dedicated signal thread.

*What separates good from great:* The 6-hour timing analysis (time-based trigger, not random), the specific investigation commands (strace + cron/logrotate checks), and the fix priority order (SA_RESTART first, it's the cheapest fix).

---

**[SENIOR] Q8 - [TRADE-OFF] What is the difference between hardware interrupts and software signals from an OS implementation perspective?**

Hardware interrupts and software signals differ in origin, handling context, and latency guarantees. Hardware interrupts: generated by external devices (NIC, disk, keyboard, timer). The device asserts an interrupt request line (IRQ) or sends an MSI (Message Signaled Interrupt) via PCIe. The CPU checks for pending interrupts at the end of each instruction (for maskable interrupts) and saves its register state, then jumps to the IDT (Interrupt Descriptor Table) entry for the interrupt vector. The IDT handler runs in kernel context (ring 0) with interrupts disabled. The handler must be fast (microseconds) to avoid delaying other hardware events. The kernel then schedules the rest of the work in a bottom-half handler (tasklet, workqueue, or threaded IRQ) to return from interrupt quickly. Software signals: generated by software (kill syscall, CPU exception, page fault). They are not delivered immediately - they are "pending" in the task_struct until the kernel is about to return to user space. Delivery latency can be milliseconds for a heavily loaded system. Signal handlers run in user context (ring 3) with full user-space resources available (stack, memory). Comparison: hardware interrupts have guaranteed maximum latency (nanoseconds to microseconds for real-time systems with CONFIG_PREEMPT_RT), while signal delivery latency is unbounded (depends on scheduler). Hardware IRQ handlers must be async-signal-safe (no sleeping), while signal handlers have the same restriction but for different reasons. Signals are the user-space interface to the kernel's event notification; hardware interrupts are the hardware's interface to the kernel.

*What separates good from great:* The IDT detail (it's a hardware table, not a software data structure), the top-half / bottom-half split in IRQ handling, and the latency difference (IRQs are guaranteed, signals are not).

---

**[SENIOR] Q9 - [BEHAVIORAL] Describe a production incident involving signals that was difficult to diagnose.**

At a company running a C-based trading system, we had a rare hang where the process became unresponsive to SIGTERM (graceful shutdown) about once every two weeks - coinciding with market open (9:30 AM). The process would sit at 0% CPU, responding to nothing, requiring a SIGKILL. Investigation took two weeks because the hang was non-deterministic. Key diagnostic steps: (1) We added a SIGQUIT handler that called `backtrace_symbols_fd()` to dump stack traces to stderr. On the next occurrence, the dump revealed the main thread was blocked in `pthread_mutex_lock()` inside `vsprintf()`. (2) Cross-referencing the SIGTERM handler code, we found it called our logging function which called `vsprintf` to format the shutdown message. (3) The SIGTERM was delivered during a malloc-heavy order processing phase. Our logging function called malloc() inside the signal handler. The signal was arriving during malloc, which held the glibc allocator lock, and our logger called malloc again for string formatting. Deadlock. Root cause: SIGTERM handler called logging function; logging function called malloc; malloc was re-entered, deadlocking on the allocator lock. The market open timing: order volume spikes at 9:30, causing high malloc frequency, which increased the probability of the signal arriving during an active malloc. Fix: replaced the SIGTERM handler with a one-line flag setter (`should_shutdown = 1`), and checked the flag in the main processing loop to perform graceful shutdown in normal context.

*What separates good from great:* The SIGQUIT+backtrace_symbols_fd diagnostic technique, the statistical explanation for the timing correlation, and the minimal fix (one-line flag setter vs complex handler).

---

**[STAFF] Q10 - [DESIGN] Design a graceful shutdown system for a Kubernetes-deployed Java service that handles 100K requests/second with no dropped requests.**

The constraint is zero dropped requests during shutdown with Kubernetes's default 30-second grace period. Architecture: The shutdown sequence must drain in-flight requests, complete queued work, and close connections in the right order. Step 1 - SIGTERM handler: the JVM's ShutdownHook or a dedicated SIGTERM handler (via signal.Notify equivalent in Java 9+ with ProcessHandle, or directly via sun.misc.Signal) marks the service as "draining." All new incoming requests receive 503 status (or the load balancer already removed the pod from rotation after readinessProbe fails). Step 2 - Request drain: maintain an AtomicInteger of in-flight request count. SIGTERM sets a draining flag; the server stops accepting new connections (but keeps existing connections alive) and waits for the counter to reach zero. The maximum drain time should be 80% of terminationGracePeriodSeconds (24 seconds of 30). Step 3 - Connection drain: after all requests complete, send FIN on all client connections (close the HTTP connection or send HTTP/1.1 Connection: close). Step 4 - Background work: thread pools handling async work (Kafka consumers, async DB writes) should check an interrupted flag and complete or checkpoint their current unit of work. Step 5 - Resource cleanup: flush output streams, close DB connection pools, commit any pending transactions. JVM-specific: the JVM installs a SIGSEGV handler for null checks; the ShutdownHook runs before the JVM exits, so all Java code works normally. Kubernetes configuration: set `terminationGracePeriodSeconds: 60` (larger than drain timeout) and configure `preStop` lifecycle hook to sleep 5 seconds before SIGTERM delivery, giving the load balancer time to stop routing to this pod.

*What separates good from great:* The Kubernetes preStop hook timing (LB route removal delay means SIGTERM arrives before LB is done routing - the 5-second sleep addresses this), the 80% of grace period for drain (leaving buffer for cleanup), and the atomic in-flight counter design.

---

**[STAFF] Q11 - [MECHANISM] How does Linux handle real-time signals differently from standard signals, and when would you use them?**

Real-time signals (SIGRTMIN to SIGRTMAX, typically signals 34-64 on Linux) have four differences from standard signals. (1) Queueing: standard signals are not queued - if SIGUSR1 is sent three times before the process handles it, the process receives it once. Real-time signals are queued in a per-process list; three sends = three deliveries in order. (2) Ordering: real-time signals are delivered in numeric order (lower number first). Standard signals have no guaranteed delivery order. (3) Payload: real-time signals carry a 4-byte integer or pointer payload via `sigqueue(pid, signo, sigval)`. The handler receives this in `siginfo_t.si_value`. Standard signals carry no payload. (4) SA_SIGINFO: real-time signal handlers typically use SA_SIGINFO flag to receive the full `siginfo_t` struct (sender PID, UID, payload). When to use: (A) POSIX AIO completion - when an async I/O operation completes, the kernel delivers a real-time signal with the I/O status as payload. (B) Custom notification queues - a producer-consumer system where the producer uses sigqueue() to notify consumers with a work item ID as payload. (C) POSIX timers (timer_create with SIGEV_SIGNAL) - deliver per-timer signals with timer ID in payload, enabling multiple timers in one process. The queueing guarantee is what makes real-time signals safe for notification use cases; standard SIGUSR1 coalescing can cause missed notifications under load.

*What separates good from great:* The queueing behavior difference (standard signals coalesce, real-time signals queue), the POSIX AIO use case, and the timer_create connection.

---

**[STAFF] Q12 - [DESIGN] How would you implement a zero-overhead crash reporting mechanism for a production C++ service that captures full heap and stack state at the moment of SIGSEGV?**

The challenge: SIGSEGV at a null dereference means the process is in an inconsistent state. The heap may be partially modified, malloc locks may be held, the stack is likely intact but abnormal. Zero-overhead means the mechanism adds no latency to the normal path. Architecture: (1) Alternate signal stack: install a dedicated stack for signal handlers via `sigaltstack()`. This allows the SIGSEGV handler to run even if the normal stack is the source of the fault. Size: at least 2 × SIGSTKSZ (16KB) to allow for the handler's own stack usage. (2) Fork-and-inspect: in the SIGSEGV handler, call fork() (fork is async-signal-safe). The forked child has a complete copy of the parent's memory at the moment of the crash (copy-on-write semantics). The child calls an async-signal-safe crash reporter (write-only path to a preallocated file, or a pre-connected socket to a crash reporting service). The parent calls `_exit()` quickly (not exit() which flushes stdio buffers). This approach captures the full heap state without blocking the crashing process for longer than a few milliseconds. (3) Pre-allocated output buffer: because malloc is not safe in signal context, pre-allocate a static buffer at process start (e.g., 1MB static array) for the crash report. The signal handler formats stack frames using `backtrace()` and `backtrace_symbols_fd()` (signal-safe) into the static buffer and writes it to the pre-connected crash socket. (4) Register state: the SA_SIGINFO sigaction flag gives the handler `ucontext_t`, which contains all CPU register values at the moment of fault - the complete machine state. Zero-overhead property: on the normal (non-crashing) path, the only cost is the sigaltstack allocation (once at startup) and the sigaction installation. No checks, no instrumentation in the hot path.

*What separates good from great:* The fork()-and-inspect technique (complete memory capture with copy-on-write, parent exits quickly), the pre-allocated static buffer (no malloc in signal context), and the SA_SIGINFO + ucontext_t for full register state.

---

### ⚖️ Comparison Table

| Mechanism | Delivery | Catchable? | Queue? | Payload | Use Case |
|---|---|---|---|---|---|
| SIGTERM (15) | Async, kernel | Yes | No (coalesces) | None | Graceful shutdown |
| SIGKILL (9) | Force, kernel | No | No | None | Unconditional termination |
| SIGCHLD (17) | On child exit | Yes | No | Exit status via waitpid | Zombie reaping |
| SIGSEGV (11) | CPU exception | Yes | No | Fault address (SA_SIGINFO) | Crash handling, JVM NPE |
| SIGUSR1/2 | Software | Yes | No | None | Custom notifications |
| SIGRTMIN+N | Software | Yes | Yes | 4-byte sigval | Queued notifications, AIO |
| Hardware IRQ | Hardware line | N/A (kernel only) | No | Interrupt vector | Device I/O, timer |

**The deciding factor:** Use standard signals for process lifecycle events (SIGTERM, SIGHUP) where coalescing is acceptable. Use real-time signals when every notification must be received (queued, payload). Use signalfd() on Linux to integrate signal handling into an event loop without async-signal-safe constraints.

---

### 🏛️ System Design

**Where signals and interrupt handling appear in system design:**
- Graceful shutdown in Kubernetes-deployed microservices
- Daemon process log rotation (SIGHUP)
- Parent-child process management in worker-pool servers
- JVM crash reporting and signal handler interop in JNI code
- Real-time systems requiring interrupt latency guarantees

**Example question:** "Design a job processing service that guarantees no job loss during rolling deployment, with 10-second average job processing time."

**6-step framework answer:**

Step 1 CLARIFY - Are jobs idempotent? What is acceptable duplicate processing rate? Is the job queue external (Kafka, SQS) or in-process?

Step 2 ESTIMATE - At 10-second average job time, a rolling deployment that sends SIGTERM must wait at least 10 seconds for in-flight jobs to complete. If each pod processes 50 jobs concurrently, 50 jobs × 10 seconds average = 500 job-seconds in flight per pod.

Step 3 DESIGN - Signal handler marks pod as "draining." Job dispatcher stops pulling new jobs from the queue. AtomicInteger tracks in-flight jobs. When counter reaches zero, call System.exit(0). Kubernetes terminationGracePeriodSeconds = 30 (covers 10s average + buffer). preStop hook sleeps 5 seconds to allow load balancer to drain HTTP traffic.

Step 4 DEEP DIVE - Job checkpoint design: each job writes a "started" marker to a durable store when it begins. If the pod is SIGKILL'd before completion (terminationGracePeriodSeconds expires), the job remains marked "started" but not "completed." A recovery process detects these stale jobs and re-queues them.

Step 5 ALTS - Alternative: use Kafka consumer with manual offset commit. Don't commit offset until job is complete. On SIGTERM, stop polling, complete current jobs, commit offsets, exit. Kafka will re-deliver uncommitted offsets to the next pod. Simpler than checkpoint store but requires idempotent jobs.

Step 6 EVOLVE - At 100x scale: the job queue becomes the bottleneck, not the signal handling. Switch to exactly-once semantics in the message broker (Kafka transactions) to eliminate the duplicate-processing risk entirely.

---

### 📊 Diagram

The signal delivery lifecycle diagram:

```
Signal Sources:
  Hardware IRQ  kill() syscall  CPU Exception
       |              |              |
       v              v              v
  +-----------------------------------------+
  |        Linux Kernel                     |
  |  IDT handler -> softirq/taskqueue       |
  |  kill() handler -> mark pending bit     |
  |  page_fault() -> determine signal type  |
  |                                         |
  |  task_struct.pending_signals bitmask    |
  +-----------+---+-------------------------+
              |
              v (on every kernel->user transition)
  +---------------------+
  | Signal Check:       |
  | blocked? -> pend    |
  | SIG_DFL? -> default |
  | SIG_IGN? -> skip    |
  | handler? -> deliver |
  +---------------------+
              |
              v
  User Stack Frame Manipulation:
    save user registers to stack
    set PC = signal_handler_address
  <user-space runs handler>
  sigreturn() syscall
    restore saved registers
  <user-space continues normally>
```

> **Diagram walkthrough:** This shows the three entry paths into the kernel's signal machinery. Hardware IRQ: device interrupts trigger the IDT handler, which processes the interrupt and may mark a signal pending for a waiting process (e.g., SIGIO for async I/O). kill() syscall: direct software delivery immediately sets the pending bit in the target's task_struct. CPU exception: synchronous hardware exception (page fault, illegal instruction) is converted by the kernel to a signal. All three paths converge at the "pending_signals bitmask" in the task_struct. The signal check runs at every kernel-to-user-space transition; if a signal is pending and not blocked, the kernel sets up a signal frame on the user stack (saving all registers) and redirects execution to the signal handler. When the handler calls sigreturn(), the kernel restores the original registers. The edge case: if the signal is blocked (sigprocmask), it stays in the pending bitmask indefinitely until unblocked. The senior insight: the delivery point is "next kernel exit," not "immediate" - a busy user-space loop with no syscalls will not see signals until it makes a syscall.

The following Mermaid diagram shows the complete signal delivery state machine:

```mermaid
stateDiagram-v2
    [*] --> Generated: kill()/hardware/exception
    Generated --> Pending: marked in task_struct
    Pending --> Blocked: sigprocmask active
    Blocked --> Pending: sigprocmask unblock
    Pending --> Delivered: kernel->user transition
    Delivered --> Default: SIG_DFL (terminate/stop/ignore)
    Delivered --> Ignored: SIG_IGN
    Delivered --> HandlerRun: custom handler installed
    HandlerRun --> UserCode: sigreturn() restores state
    Default --> [*]: process terminated or stopped
    Ignored --> [*]: signal discarded
    UserCode --> [*]: execution resumes
```

> **Diagram walkthrough:** This state diagram traces the complete lifecycle of a signal from generation to final disposition. A signal starts in the Generated state when any source (kill syscall, hardware interrupt, CPU exception) creates it. It moves to Pending when the kernel marks the bit in task_struct. If the process has blocked it with sigprocmask, it waits in the Blocked state until unblocked. At the next kernel-to-user transition, Pending signals are Delivered - the kernel checks disposition. Three outcomes: Default action (most signals default to terminate), Ignored (SIG_IGN), or HandlerRun (custom sigaction handler). HandlerRun concludes with sigreturn() restoring the original user-space state. The key relationship: signals do not interrupt user-space; they interrupt kernel-to-user transitions - a tight user-space loop sees signals only when it makes a syscall. The edge case: SIGKILL skips the Delivered state entirely, moving directly from Generated to process termination via kernel force_sig(). The senior insight: the Blocked state is per-thread (pthread_sigmask), allowing fine-grained control over which thread handles which signals.
