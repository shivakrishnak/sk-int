---
layout: default
title: "Linux - L1 Shell and Scripting"
parent: "Linux"
nav_order: 3
permalink: /linux/l1-shell-scripting/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 7 | [Shell Basics: Variables, Pipes, and Redirection](#shell-basics-variables-pipes-and-redirection) | ★☆☆ |
| 8 | [Bash Scripting: Loops, Conditions, and Functions](#bash-scripting-loops-conditions-and-functions) | ★☆☆ |
| 9 | [Package Management: apt, yum, and dnf](#package-management-apt-yum-and-dnf) | ★☆☆ |

---

# Shell Basics: Variables, Pipes, and Redirection

**Interview Weight:** Moderate - shell fluency is assumed in backend
and DevOps roles; gaps here signal limited Linux operational experience.

---

### 🎯 Model Answer

**30-second answer:**

"The shell is the command interpreter for Linux. Variables store
values (no spaces around =). Pipes connect command output to the next
command's input. Redirection sends output to files (>) or reads from
files (<). These three mechanisms enable composing simple commands
into powerful data processing pipelines."

**3-minute answer:**

"Shell mechanics form the foundation of Linux automation. Three core
concepts:

Variables: assigned without spaces (`NAME=value`), accessed with `$`
(`echo $NAME`). Environment variables are exported to child processes
(`export PATH`). Special variables: `$?` = last exit code, `$0` =
script name, `$1-$9` = positional arguments, `$@` = all arguments,
`$$` = current PID.

Pipes: `|` connects stdout of one process to stdin of the next.
`ls -la | grep '.log' | wc -l` lists files, filters log files, counts
them. Pipes create concurrent processes - both sides run simultaneously
with a kernel buffer between them.

Redirection: `>` redirects stdout to a file (truncates). `>>` appends.
`2>` redirects stderr. `2>&1` merges stderr into stdout. `< file`
reads stdin from a file. `/dev/null` discards output. `tee` writes to
both a file and stdout simultaneously.

The critical pattern for scripts: `command > /tmp/output.txt 2>&1`
captures both stdout and stderr. `command 2>/dev/null` suppresses
errors when they're expected (like `kill -0 $PID 2>/dev/null`)."

**Blank Mind Recovery:**

"Variables: NAME=value, $NAME. Pipes: | connects stdout to stdin.
Redirection: > file (overwrite), >> (append), 2> (stderr), 2>&1
(merge stderr into stdout), < (read from file). $? = exit code."

---

### 📘 Concept Explanation

**What it is:**

The shell (bash, sh, zsh) is both an interactive command interpreter
and a scripting language. Variables, pipes, and redirection are the
three fundamental mechanisms that make shell scripts composable tools
rather than just command wrappers.

**The problem it solves:**

Without variables, every value must be hardcoded. Without pipes,
programs would need built-in filtering, sorting, and counting. Without
redirection, output goes only to the terminal. These three mechanisms
give every UNIX tool the ability to participate in arbitrarily complex
data processing pipelines.

**How it works:**

Variables:
```bash
NAME="production"        # assignment (no spaces)
echo "$NAME"             # access with $
echo "${NAME}_server"    # curly braces for disambiguation
unset NAME               # remove variable
export PATH="$PATH:/opt/myapp/bin"  # add to env
```

> **Code walkthrough:** curl HTTP testing commands. KEY MECHANISM: `curl -o /dev/null -s -w '%{http_code}'` discards the body and outputs only the status code - perfect for scripted health checks. `curl --resolve host:port:IP` forces DNS resolution to a specific IP for testing backend servers directly. WHY IT MATTERS: curl eliminates browser caching and redirects as confounding variables. WHAT BREAKS: `-k` disables TLS verification - never in production scripts. TAKEAWAY: `curl -o /dev/null -s -w` for scripts; `curl -v` for debugging; use `--max-time` to prevent hanging.

Pipes: The kernel creates a unidirectional byte stream (pipe) between
two processes. The shell sets the left-side process's stdout to the
pipe write end and the right-side's stdin to the pipe read end. Both
processes run concurrently.

Redirection:
```
command >  file     # stdout to file (overwrite)
command >> file     # stdout to file (append)
command 2> file     # stderr to file
command 2>&1        # redirect stderr to where stdout goes
command &> file     # bash: both stdout + stderr to file
command < file      # stdin from file
command <<< "text"  # stdin from here-string
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

**The key insight:**

File descriptors are just numbers: 0 = stdin, 1 = stdout, 2 = stderr.
`2>&1` means "make fd 2 point to the same place as fd 1." The order
matters: `command > file 2>&1` redirects stdout to file, then stderr
to stdout (which is now file). `command 2>&1 > file` redirects stderr
to stdout (the terminal), then stdout to file - stderr still goes to
terminal. This is the most common shell scripting mistake.

**When to use pipes vs subshells:**

Pipes: for streaming data between commands (efficient, parallel).
Subshells `$(command)`: for capturing output as a value.
`count=$(wc -l < access.log)` captures the line count as a variable.

**When NOT to use shell pipes for complex processing:**

Pipelines are fragile with binary data, structured formats (JSON),
or complex error handling. Python or a proper language is appropriate
when logic exceeds 10-15 lines of awk/sed.

**Alternatives:**

Fish shell, zsh: enhanced interactive shells with better completion.
For scripting, Python is more maintainable for complex logic.

**First-principles derivation:**

"Programs need state (variables), composition (pipes), and I/O
flexibility (redirection). Shell provides the minimum viable
implementation of each, enabling combinatorial power from simple tools."

---

### 💻 Code Example

```bash
#!/bin/bash
# Shell variable best practices
DEPLOY_ENV="${1:-production}"    # default value if $1 empty
DB_HOST="${DB_HOST:?DB_HOST required}" # error if unset

# Capture command output
COMMIT_HASH=$(git rev-parse --short HEAD)
FILE_COUNT=$(find /var/log -name "*.log" | wc -l)

echo "Deploying $COMMIT_HASH to $DEPLOY_ENV"
echo "Found $FILE_COUNT log files"

# Exit code handling
if ! systemctl is-active --quiet nginx; then
    echo "nginx is not running" >&2  # write to stderr
    exit 1                           # non-zero = failure
fi
echo "Last command status: $?"       # 0 = success
```

> **Code walkthrough:** `${1:-production}` is parameter expansion with
a default: if `$1` is unset or empty, use "production." KEY MECHANISM:
`${VAR:?message}` triggers a fatal error with the message if VAR is
unset - this is the correct pattern for required script parameters
(faster fail than waiting for a cryptic downstream error). WHY IT
MATTERS: `>&2` in `echo "error" >&2` writes error messages to stderr,
allowing the caller to separate normal output from error output; scripts
that write errors to stdout mix them into pipes and corrupt data.
WHAT BREAKS: using `echo $COMMIT_HASH` without quotes fails if the
value contains spaces or globs; always double-quote variable expansions.
TAKEAWAY: `${VAR:?}` for required variables, `${VAR:-default}` for
optional ones - these two patterns cover 90% of variable validation needs.

```bash
# Pipe patterns with error handling
# Process access log and report top 10 IPs
cat /var/log/nginx/access.log | \
  awk '{print $1}' | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -10

# tee: write to file AND stdout simultaneously
curl -s https://api.internal/health | \
  tee /tmp/health_response.json | \
  jq '.status'
# Output goes to both /tmp/health_response.json and jq

# Redirect both stdout and stderr to a file
{
  echo "Starting deployment"
  my_deploy_command
  echo "Deployment done"
} > /var/log/deploy.log 2>&1
# Braces group multiple commands under one redirection
```

> **Code walkthrough:** Grouping commands in braces `{ ...; }` applies
a single redirection to all commands in the group, avoiding repeating
`>> logfile 2>&1` on every line. KEY MECHANISM: the shell creates one
file descriptor for the group and routes all output through it; this
is more efficient than opening/closing the file for each command.
WHY IT MATTERS: deployment logs should capture both normal output and
error output in sequence; separate stdout and stderr logs make timeline
reconstruction harder during incident analysis. WHAT BREAKS: `(...)` vs
`{...}`: parentheses create a subshell (variables set inside don't
persist); braces run in the current shell (variables persist). TAKEAWAY:
always redirect both stdout and stderr together (`2>&1`) in deployment
and cron scripts to ensure errors are never silently lost.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"Shell variables are assigned without spaces (NAME=value) and accessed
with $NAME. Pipes connect command output to input. Redirection > sends
output to files. The most important pattern I use: `command > log.txt
2>&1` to capture all output including errors into a file."

**Senior/Staff:**

"Shell mechanics have important subtleties that matter in production
scripts. `2>&1` order matters: `cmd > file 2>&1` is correct (stderr
goes to the file), but `cmd 2>&1 > file` sends stderr to the terminal
(a common mistake that loses errors). For monitoring scripts, I always
check `$?` or use `set -e` to fail fast. Pipe exit codes need `set -o
pipefail` - without it, `false | echo ok` exits with 0 because only
the last command's exit code is checked. For process substitution,
`<(command)` creates a named pipe which lets you diff two commands:
`diff <(sort file1) <(sort file2)`. At staff level, I write shell
scripts only for orchestration (calling other tools); any logic
exceeding ~30 lines gets rewritten in Python for testability and
error handling."

---

### ⚠️ Common Misconceptions

**Misconception 1: "2>&1 at the end redirects stderr."**

The order of redirections matters. `command > file 2>&1` first
redirects stdout to file, then redirects stderr to stdout (which is
now file). This is correct. `command 2>&1 > file` redirects stderr
to current stdout (terminal), then stdout to file - stderr still goes
to the terminal. Always put `> file` before `2>&1`.

**Misconception 2: "Pipes are sequential."**

Pipe stages run concurrently. `ps aux | grep java` starts both `ps`
and `grep` simultaneously; `grep` reads `ps`'s output as it's
produced. This is why pipes are efficient - no intermediate temp files.
The implication: if `ps` produces output faster than `grep` processes
it, the kernel buffers it (64KB by default). If the buffer fills, `ps`
blocks until `grep` reads more.

**Misconception 3: "Exit code only matters if you check it."**

Without `set -e`, a script continues after a failing command silently.
`set -e` makes the script exit on any non-zero exit code. Without
`set -o pipefail`, `false | true` exits with 0 because only the last
pipe stage exit code is checked. Production scripts should use
`set -euo pipefail` at the top.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Shell script succeeds but produces wrong output due to silent failures**

```bash
#!/bin/bash
# BAD: no fail-fast settings
get_latest_build() {
    curl -s http://build-server/api/latest
    # If curl fails with network error, returns empty string
    # but exit code is ignored by the caller
}
BUILD=$(get_latest_build)
echo "Deploying build: $BUILD"   # Deploys empty string silently!

# GOOD: fail-fast settings
#!/bin/bash
set -euo pipefail
# -e: exit on error
# -u: error on undefined variables
# -o pipefail: pipe fails if any stage fails

get_latest_build() {
    local result
    result=$(curl --fail --silent http://build-server/api/latest)
    echo "$result"
}
BUILD=$(get_latest_build)  # now exits if curl fails
```

> **Code walkthrough:** `set -euo pipefail` is the production-grade
shell header. KEY MECHANISM: `-e` exits on the first non-zero exit code
from any command (except in conditionals); `-u` causes an error when
referencing an unset variable (catches typos in variable names);
`-o pipefail` makes the exit code of a pipe be the rightmost non-zero
exit code. WHY IT MATTERS: without these settings, shell scripts
silently continue past failures, deploying empty config, writing
corrupted data, or skipping critical steps. WHAT BREAKS: `-e` can
cause unexpected exits in scripts that intentionally use non-zero exit
codes (`grep` returns 1 when no match found); wrap those commands in
`if command; then ...` to handle them explicitly. TAKEAWAY: always
start production scripts with `set -euo pipefail` - this is the single
most impactful shell scripting best practice.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | variables, redirection semantics |
| Debugging | 2 | silent failures, exit codes |
| Trade-off | 3 | shell vs Python, pipe patterns |

---

**[JUNIOR] Q1 - What is the difference between single quotes and double quotes in bash?**

Single quotes preserve the literal value of every character between
the quotes. No variable expansion, no command substitution, no escape
sequences are processed.

Double quotes allow variable expansion (`$VAR`), command substitution
(`$(cmd)`), and escape sequences (`\n`), but suppress word splitting
and glob expansion.

```bash
NAME="world"
echo 'Hello $NAME'    # Hello $NAME (literal)
echo "Hello $NAME"    # Hello world (expanded)

# This matters for filenames with spaces
FILE="my file.txt"
cat $FILE             # Error: cat: my: No such file
cat "$FILE"           # Correct: cat "my file.txt"

# Command substitution
echo 'Today: $(date)'    # Today: $(date) (literal)
echo "Today: $(date)"    # Today: Mon Jan 15 ... (executed)
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Rule of thumb: always double-quote variable expansions unless you
specifically want word splitting (e.g., passing multiple args from
one variable). Use single quotes for string literals with special
characters that should not be expanded.

*What separates good from great:* explaining word splitting - unquoted
`$VAR` that contains spaces splits into multiple arguments, causing
subtle bugs with filenames and paths that "work" until they contain
spaces.

---

**[MID] Q2 - What does set -euo pipefail do and why is it important?**

```bash
set -euo pipefail
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Three flags:
- `-e`: exit immediately if any command returns non-zero exit code
  (except in `if/while` conditions or after `||`)
- `-u`: treat unset variables as errors (prevents silent typos)
- `-o pipefail`: the exit code of a pipeline is the rightmost non-zero
  exit code, not just the last command

Without these, shell scripts continue silently after failures. The
common failure pattern:
```bash
# Without set -e:
fetch_config    # network error, returns empty string
setup_service   # runs with empty config, misconfigures service
start_service   # starts with wrong config
# No error reported - silent misconfiguration
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Important caveats:
- `grep` returns exit code 1 when no lines match - with `-e`, this
  terminates the script. Wrap in: `grep pattern file || true` or
  `if grep pattern file; then ...`
- `find ... -exec cmd` propagates non-zero from the exec even with `-e`
- Subshell failures (`$(cmd)`) still propagate with `-e`

*What separates good from great:* knowing the caveats (grep returning
1 on no match, intentional non-zero exit codes) and how to handle them
without disabling `-e` globally.

---

**[JUNIOR] Q3 - How do you pass arguments to a shell script and validate them?**

```bash
#!/bin/bash
set -euo pipefail

# Script: deploy.sh <environment> <version>
# Usage: ./deploy.sh production 1.2.3

# Argument count check
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <environment> <version>" >&2
    exit 1
fi

ENVIRONMENT="$1"
VERSION="$2"

# Validate environment value
case "$ENVIRONMENT" in
    production|staging|development)
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT" >&2
        echo "Valid: production, staging, development" >&2
        exit 1
        ;;
esac

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format: $VERSION (expected X.Y.Z)" >&2
    exit 1
fi

echo "Deploying version $VERSION to $ENVIRONMENT"
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Key patterns: `$#` is argument count; `$@` is all arguments (quoted);
`$0` is script name. Validation at the top of the script fails fast
before doing any side effects. Error messages go to stderr (`>&2`).
Exit code 1 for usage errors is conventional (2 for misuse).

*What separates good from great:* writing error messages to stderr and
using meaningful exit codes - standard UNIX behavior that allows
callers to detect and handle failures.

---

**[MID] Q4 - What is a here-document and when is it useful?**

A here-document (`<<EOF`) redirects a multi-line string as stdin to
a command without creating a temporary file.

```bash
# Create a config file with variable expansion
cat > /etc/myapp/config.conf <<EOF
# Generated by deploy.sh on $(date)
db_host=${DB_HOST}
db_port=${DB_PORT:-5432}
app_env=${ENVIRONMENT}
EOF

# Send a multi-line email
sendmail admin@example.com <<EOF
Subject: Deployment complete

Deployed version $VERSION to $ENVIRONMENT at $(date).
Commit: $(git rev-parse HEAD)
EOF

# Here-string: single-line version
grep "pattern" <<< "some string to search"

# Quoted heredoc: disable variable expansion
cat > /etc/bash_completion.d/myapp <<'EOF'
# Single quotes prevent $VAR expansion
complete -W "start stop status" myapp
EOF
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

The critical difference: `<<EOF` (unquoted) expands variables and
command substitutions. `<<'EOF'` (quoted) is a literal heredoc with
no expansion - essential when writing scripts that contain `$` in
the content (awk programs, other shell scripts).

*What separates good from great:* the `<<'EOF'` quoting distinction
for generating content that contains shell special characters.

---

**[JUNIOR] Q5 - How do environment variables work and how do they differ from shell variables?**

Shell variables exist only in the current shell process. Environment
variables are shell variables that have been exported and are
inherited by child processes.

```bash
# Shell variable (not inherited by children)
MY_VAR="hello"
bash -c 'echo $MY_VAR'  # (empty - not inherited)

# Environment variable (inherited)
export MY_VAR="hello"
bash -c 'echo $MY_VAR'  # hello

# One-time env for single command
MY_VAR="hello" bash -c 'echo $MY_VAR'   # hello (temporary)
MY_VAR="override" mycommand             # override for one command only

# View environment
env                          # all environment variables
printenv MY_VAR              # specific variable
export -p | grep MY_VAR      # exported variables

# Remove from environment
unset MY_VAR
export -n MY_VAR  # unexport but keep as shell variable
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

Child processes inherit a copy of the parent's environment at fork
time. Modifications in the child do not propagate back to the parent.
This is why `source ./script.sh` (dot command) is needed to modify
the current shell's variables from a script - it runs in the current
shell rather than a subshell.

*What separates good from great:* explaining that `source` (or `.`)
runs the script in the current shell's context - this is how shell
profile files (`.bashrc`, `.profile`) work and why you need `source
~/.bashrc` after editing it.

---

**[MID] Q6 - What is process substitution and when does it help?**

Process substitution (`<(cmd)`) creates a named pipe (FIFO) and makes
the output of a command available as a file path argument.

```bash
# Diff the output of two commands
diff <(ls -1 dir1/ | sort) <(ls -1 dir2/ | sort)
# Shows files in dir1 but not dir2, and vice versa

# Compare live and backup configs
diff <(ssh server1 cat /etc/nginx/nginx.conf) \
     <(cat /etc/nginx/nginx.conf.backup)

# Join log files that need sorting first
join <(sort file1.txt) <(sort file2.txt)

# Real-world: compare deployed vs expected package list
diff <(ssh server "dpkg -l | awk '{print \$2}'") \
     expected_packages.txt
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

Process substitution solves the problem of commands that require
filenames but need to receive command output. Unlike pipes, which
only connect two commands sequentially, process substitution allows
arbitrary command output to be passed as arguments anywhere.

A pipe limitation: `diff` cannot read from stdin for both files
simultaneously. Process substitution gives each command output
its own file descriptor.

*What separates good from great:* the real-world diff use case
(comparing server config vs expected state) - a common infrastructure
validation pattern that process substitution makes elegant.

---

**[JUNIOR] Q7 - How do you safely handle exit codes in a shell script with set -e?**

The challenge with `set -e` is that it treats any non-zero exit code
as fatal, but some commands legitimately return non-zero in normal
operation:
- `grep`: returns 1 when no lines match (not an error)
- `diff`: returns 1 when files differ (not an error)
- `test`: returns 1 for false conditions
- `[ ... ]`: returns 1 for false
- `find ... -exec ... \;`: propagates non-zero from the executed command

Handling patterns:

```bash
set -euo pipefail

# Method 1: || true (suppress non-zero)
grep "pattern" file || true    # continue even if no match

# Method 2: if statement (error is caught in condition)
if grep "error" /var/log/app.log; then
    echo "Errors found" >&2
fi  # no exit even if grep returns 1

# Method 3: local variable assignment
RC=0
grep "pattern" file || RC=$?
if [[ $RC -ne 0 && $RC -ne 1 ]]; then
    echo "grep failed with unexpected error: $RC" >&2
    exit 1
fi

# Method 4: subshell for sections that may fail
(
    set +e    # disable -e locally
    risky_command
    echo $?   # capture result
) || handle_failure
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

The safest production pattern: `set -euo pipefail` at the top,
then use `|| true` only for commands where non-zero is expected
and acceptable, and `if cmd; then...` for commands where you need
to act on both success and failure.

*What separates good from great:* using Method 3 (capture RC) to
distinguish expected non-zero (grep no match = 1) from unexpected
non-zero (grep error = 2) - proper error handling, not just
suppressing all non-zero.

---

---

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*


# Bash Scripting: Loops, Conditions, and Functions

**Interview Weight:** Moderate - automation scripting questions
appear in backend/DevOps roles; expect candidates to write simple
scripts during interviews.

---

### 🎯 Model Answer

**30-second answer:**

"Bash supports for and while loops, if/elif/else conditions using test
brackets [[ ]], and functions defined with function_name() {}. Key
patterns: for iterating over files or arrays; while for reading line
by line or retrying; functions for reusable logic. The test command
[[ ]] handles string, numeric, and file comparisons."

**3-minute answer:**

"Bash control structures follow POSIX shell conventions with some bash
extensions:

Loops: `for item in list; do ... done` iterates over a list or glob.
`for file in /var/log/*.log` iterates over matching files. `while read
line; do ... done < file` reads a file line by line (more efficient
than a for loop for large files). `while true; do ... sleep 5; done`
creates a polling loop.

Conditions: `[[ ]]` (bash test command) supports string comparison
(`==`, `!=`, `=~` for regex), numeric comparison (`-eq`, `-ne`, `-lt`,
`-gt`), and file tests (`-f` file exists, `-d` directory, `-r`
readable, `-z` string empty). Double brackets are preferred over
single `[ ]` in bash scripts because they don't require quoting for
variables.

Functions: defined without keywords: `my_function() { commands; }`.
They receive arguments as `$1`, `$2`. Return values via `echo` (capture
with `$(my_function)`), or exit codes (0=success, 1+=failure).
Functions share the script's variable scope unless `local` is used.

Critical patterns: `local` variables in functions to prevent pollution,
`return` for exit codes, and error handling in every function."

**Blank Mind Recovery:**

"for item in list; while condition; if [[ condition ]]. [[ ]] for
tests: -f file, -d dir, -z empty, -eq numeric equal, == string equal.
Functions: name() { body; }; use local for vars; echo to return values."

---

### 📘 Concept Explanation

**What it is:**

Bash control flow constructs for iteration (for, while, until), branching
(if/elif/else, case), and code organization (functions). These transform
one-liners into maintainable automation scripts.

**The problem it solves:**

Without control flow, every automation task requires writing a new
script for each variation. Loops iterate over files, servers, or
retries. Conditions branch on system state. Functions encapsulate
reusable logic and reduce duplication.

**How it works:**

```bash
# for loop patterns
for file in /var/log/*.log; do
    echo "Processing: $file"
done

for i in $(seq 1 10); do
    echo "Item $i"
done

for server in web01 web02 web03; do
    ssh "$server" 'systemctl status nginx'
done

# while loop patterns
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts

while ! nc -z database 5432; do
    echo "Waiting for database..."
    sleep 2
done

# condition tests
if [[ -f /etc/myapp/config.conf ]]; then
    echo "Config exists"
elif [[ -d /etc/myapp ]]; then
    echo "Dir exists but no config"
else
    echo "Nothing configured"
fi
```

> **Code walkthrough:** Network connectivity test commands. KEY MECHANISM: `nc -zv host port` attempts TCP connect in zero-I/O mode; unlike ping (ICMP), it tests actual TCP reachability through firewalls. WHY IT MATTERS: ICMP is often blocked while TCP services work fine - ping is unreliable for connectivity testing. WHAT BREAKS: `nc -zv host port` timeout can mean firewall DROP (no response) or port not open; `nmap` distinguishes filtered vs closed. TAKEAWAY: use `nc -zv host port` or `curl` for connectivity tests in scripts, never `ping`.

**The key insight:**

In bash, every command has an exit code (0=success, non-zero=failure).
`if` and `while` use exit codes, not true/false values. `if grep
pattern file` is correct bash - it runs grep and branches on whether
grep found a match (exit 0) or not (exit 1). `[[ condition ]]` is
itself a command that returns 0 or 1.

**When to use bash vs Python:**

Bash: orchestration, calling other tools, simple file operations,
fewer than ~30 lines of logic, when the environment may not have Python.
Python: data processing, complex logic, JSON/XML handling, error
handling, unit-testable scripts, anything over ~30 lines.

**When NOT to use bash for complex logic:**

Bash has no exception handling (only exit codes), no data structures
(arrays are weak), limited string processing, and poor Unicode support.
Complex bash scripts become unmaintainable quickly.

**Alternatives:**

Python, Ruby, Go for more complex scripts. Ansible for idempotent
infrastructure automation. Terraform for declarative infrastructure.

**First-principles derivation:**

"Automation scripts need: iteration over resources (loops), branching
based on state (conditions), and code reuse (functions). Bash provides
the minimum viable implementation of each, sufficient for glue scripts
and orchestration."

---

### 💻 Code Example

```bash
#!/bin/bash
set -euo pipefail

# Function with error handling and local variables
log_with_timestamp() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message"
}

wait_for_service() {
    local host="$1"
    local port="$2"
    local max_attempts="${3:-30}"
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            log_with_timestamp "INFO" "$host:$port is ready"
            return 0
        fi
        log_with_timestamp "WARN" \
          "Attempt $attempt/$max_attempts: waiting for $host:$port"
        sleep 2
        ((attempt++))
    done

    log_with_timestamp "ERROR" \
      "Service $host:$port not ready after $max_attempts attempts"
    return 1
}

# Usage
wait_for_service "db.internal" 5432 60 || {
    echo "Database unavailable, aborting deployment" >&2
    exit 1
}
```

> **Code walkthrough:** `local` variables in functions prevent them
from leaking into the script's global scope - `attempt` in the function
does not overwrite any outer variable named `attempt`. KEY MECHANISM:
`return 0` and `return 1` set the function's exit code, allowing callers
to use `if wait_for_service ...; then` or `wait_for_service ... || exit`.
WHY IT MATTERS: without `local`, bash functions that modify variables
like `i`, `count`, or `result` silently corrupt outer loop variables -
a classic bash debugging nightmare. WHAT BREAKS: `((attempt++))` uses
arithmetic evaluation which returns exit code 1 when the result is 0;
with `set -e`, `((count++))` when count=0 exits the script. Use
`((count++)) || true` or `count=$((count + 1))` to be safe. TAKEAWAY:
use `local` for ALL function variables and `return` for exit codes.

```bash
#!/bin/bash
set -euo pipefail

# Array handling and string operations
SERVERS=("web01" "web02" "web03")
FAILED_SERVERS=()

deploy_to_server() {
    local server="$1"
    local version="$2"

    log_with_timestamp "INFO" "Deploying $version to $server"

    if ssh -o ConnectTimeout=5 "$server" \
         "cd /opt/myapp && ./deploy.sh $version"; then
        log_with_timestamp "INFO" "Success: $server"
        return 0
    else
        log_with_timestamp "ERROR" "Failed: $server"
        return 1
    fi
}

VERSION="${1:?Version argument required}"

for server in "${SERVERS[@]}"; do
    if ! deploy_to_server "$server" "$VERSION"; then
        FAILED_SERVERS+=("$server")
    fi
done

if [[ ${#FAILED_SERVERS[@]} -gt 0 ]]; then
    echo "FAILED servers: ${FAILED_SERVERS[*]}" >&2
    exit 1
fi

echo "All servers deployed successfully"
```

> **Code walkthrough:** `"${SERVERS[@]}"` expands the array with each
element properly quoted, handling server names with spaces. KEY MECHANISM:
`FAILED_SERVERS+=("$server")` appends to an array; `${#FAILED_SERVERS[@]}`
is the array length - the `#` operator returns element count. WHY IT
MATTERS: the pattern of collecting failures into an array and reporting
at the end (rather than exiting on first failure) allows partial
deployments to continue and then report all failures together.
WHAT BREAKS: `"${SERVERS[*]}"` (asterisk) joins all elements into one
string; `"${SERVERS[@]}"` (at) expands as separate words - always use
`[@]` in loops. TAKEAWAY: always use `"${ARRAY[@]}"` (with double quotes
and @) when iterating arrays - this is the only form that handles
elements with spaces correctly.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"I use for loops to iterate over files or lists, while loops for
waiting or reading files, and if with [[ ]] for conditions. I can
write functions to reuse code. Key things: use local variables in
functions, use [[ ]] not [ ], and always quote variables."

**Senior/Staff:**

"My bash scripting philosophy: keep scripts simple and fail loudly.
Every production script starts with `set -euo pipefail`. Functions
return exit codes (not string "ok"/"fail") so callers use standard
conditional syntax. I avoid complex bash logic beyond 30 lines and
instead call Python scripts for anything requiring data structures,
JSON processing, or complex error handling. The biggest production
bash anti-pattern I see: scripts that check exit codes inconsistently -
some commands checked, others not. The `set -e` discipline enforces
consistent checking. For retry logic, I write a generic `retry()`
function with exponential backoff that every other function can use,
rather than duplicating while loops."

---

### ⚠️ Common Misconceptions

**Misconception 1: "[ ] and [[ ]] are equivalent."**

Single brackets `[ ]` are the POSIX test command. Double brackets
`[[ ]]` are a bash built-in with additional features: regex matching
with `=~`, no word splitting on unquoted variables, and `&&`/`||`
instead of `-a`/`-o`. In bash scripts, always use `[[ ]]`. The main
case for `[ ]` is writing POSIX sh scripts that must work on minimal
shells (like Alpine's ash).

**Misconception 2: "Functions in bash return strings."**

Bash functions return exit codes (integers 0-255), not strings. To
return a string value, echo it and capture with `$(function_name)`.
The function's exit code is what `if function_name; then` tests.
Mixing these is a common source of bugs: a function that echoes its
return value AND has a non-zero exit code will look like it failed
even though it produced output.

**Misconception 3: "Bash arrays work like Python lists."**

Bash arrays have major limitations: they cannot be exported to child
processes, they cannot be passed to functions (only individual elements
or the array name as a string), and they do not support nested arrays.
For complex data structures in scripts, use Python or JSON with `jq`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Script works interactively but fails in cron**

```bash
# Common cron failures

# Problem 1: PATH is minimal in cron
# Interactive shell PATH:
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:...
# Cron PATH:
# /usr/bin:/bin
# Fix: Set PATH explicitly at top of script
#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin"

# Problem 2: Working directory is not what you expect
# Cron starts in the user's home directory
# Fix: Use absolute paths or cd explicitly
cd /opt/myapp || exit 1

# Problem 3: Environment variables not set
# Fix: Source the profile or set explicitly
# Option A: source environment
source /etc/profile.d/myapp.sh 2>/dev/null || true
# Option B: set explicitly
export DB_HOST="db.internal"
export DB_PORT=5432

# Problem 4: cron output not visible
# Fix: redirect all output
*/5 * * * * /opt/myapp/cleanup.sh >> /var/log/myapp/cron.log 2>&1

# Debug cron issues
# Check cron ran
grep CRON /var/log/syslog | grep cleanup | tail -5
# See cron output
tail -20 /var/log/myapp/cron.log
```

> **Code walkthrough:** Cron jobs run with a minimal, stripped
environment - no PATH additions from `.bashrc`, no user environment
variables, no current directory assumptions. KEY MECHANISM: cron
starts a new shell for each job with only the default environment
from `/etc/environment` and `/etc/cron.d/` SHELL/PATH settings.
WHY IT MATTERS: scripts that work perfectly when run manually often
fail silently in cron because tools like `python3` are in
`/usr/local/bin` which isn't in cron's PATH. WHAT BREAKS: scripts
that use relative paths (`./config.conf`) fail when cron starts in
`/root` or `/home/user` instead of the script directory.
TAKEAWAY: every cron-targeted script should set PATH explicitly at
line 2 (after shebang) and use only absolute paths for files.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | control flow, functions |
| Debugging | 2 | cron issues, variable scope |
| Trade-off | 3 | bash vs Python, loop patterns |

---

**[JUNIOR] Q1 - Write a bash script to check if a list of services are running and restart any that are stopped.**

```bash
#!/bin/bash
set -uo pipefail
# Note: -e removed because systemctl returns non-zero for stopped services

SERVICES=("nginx" "postgresql" "myapp")
RESTARTED=()
FAILED=()

check_and_restart() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        echo "OK: $service is running"
        return 0
    fi

    echo "WARNING: $service is not running, restarting..."
    if systemctl restart "$service"; then
        sleep 2
        if systemctl is-active --quiet "$service"; then
            echo "RECOVERED: $service restarted successfully"
            RESTARTED+=("$service")
            return 0
        fi
    fi

    echo "ERROR: Failed to restart $service" >&2
    FAILED+=("$service")
    return 1
}

for service in "${SERVICES[@]}"; do
    check_and_restart "$service" || true
done

# Report summary
if [[ ${#RESTARTED[@]} -gt 0 ]]; then
    echo "Restarted services: ${RESTARTED[*]}"
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "CRITICAL: Failed services: ${FAILED[*]}" >&2
    exit 1
fi
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Key design decisions: `-e` removed because `systemctl is-active` returns
1 for stopped services (not an error). `|| true` in the loop continues
after failures and collects them. Summary report at end rather than
per-service output.

*What separates good from great:* verifying the service is actually
running after restart (not just that `systemctl restart` succeeded,
which can return 0 even if the service immediately crashes again).

---

**[MID] Q2 - What is the difference between while read and for in iterating file lines?**

```bash
# Method 1: for loop (WRONG for files with spaces)
for line in $(cat /etc/hosts); do
    echo "Line: $line"
done
# PROBLEM: $(cat) expands to words, not lines
# "127.0.0.1 localhost" becomes two separate words

# Method 2: while read (CORRECT for files)
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/hosts
# Reads actual lines, preserving spaces and special chars

# Method 3: for loop with mapfile (array)
mapfile -t lines < /etc/hosts
for line in "${lines[@]}"; do
    echo "Line: $line"
done
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

`IFS=` (empty IFS) prevents leading/trailing whitespace stripping.
`-r` (raw mode) prevents backslash interpretation. Together, they
ensure each line is read exactly as it appears in the file.

The `$(cat file)` inside a for loop fails when: lines contain spaces
(splits mid-line), lines contain glob characters (expand to filenames),
or lines are empty (skipped). `while read` handles all these correctly.

For performance, process substitution with a command: `while IFS= read
-r line; do ...; done < <(grep pattern file)` is more efficient than
creating a temporary file.

*What separates good from great:* knowing `IFS= read -r` as the
canonical correct form and explaining specifically what breaks without
each flag.

---

**[JUNIOR] Q3 - How do you write an idempotent bash script (one that can be run multiple times safely)?**

Idempotency means running the script N times produces the same result
as running it once. Key patterns:

```bash
#!/bin/bash
set -euo pipefail

# Idempotent user creation
if ! id appuser &>/dev/null; then
    useradd --system --no-create-home appuser
    echo "Created user appuser"
else
    echo "User appuser already exists, skipping"
fi

# Idempotent directory creation
mkdir -p /var/lib/myapp    # -p: no error if exists, create parents

# Idempotent file creation (only if not present)
if [[ ! -f /etc/myapp/config.conf ]]; then
    cp /opt/myapp/config.conf.default /etc/myapp/config.conf
    echo "Installed default config"
fi

# Idempotent service enablement
if ! systemctl is-enabled --quiet myapp; then
    systemctl enable myapp
    echo "Enabled myapp service"
fi

# Idempotent line addition to file
LINE="net.ipv4.ip_forward = 1"
if ! grep -qF "$LINE" /etc/sysctl.d/99-myapp.conf 2>/dev/null; then
    echo "$LINE" >> /etc/sysctl.d/99-myapp.conf
fi
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

The pattern is always: check if the desired state already exists,
then only act if it doesn't. This makes the script safe for re-running
during debugging, for Ansible-calling, and for applying the same
script to multiple systems at different states.

*What separates good from great:* using `grep -qF "$LINE" file` to
check if a line already exists before appending it - preventing
duplicate entries on repeated runs.

---

**[MID] Q4 - How do you implement retry logic with exponential backoff in bash?**

```bash
#!/bin/bash

retry_with_backoff() {
    local max_attempts="$1"
    local delay="$2"
    local max_delay="${3:-60}"
    shift 3
    local cmd=("$@")

    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if "${cmd[@]}"; then
            return 0
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            echo "Command failed after $max_attempts attempts: ${cmd[*]}" >&2
            return 1
        fi

        echo "Attempt $attempt failed, retrying in ${delay}s..." >&2
        sleep "$delay"

        # Exponential backoff with cap
        delay=$(( delay * 2 ))
        if [[ $delay -gt $max_delay ]]; then
            delay=$max_delay
        fi

        ((attempt++))
    done
}

# Usage examples
retry_with_backoff 5 2 30 curl --fail http://api.internal/health
retry_with_backoff 10 1 60 nc -z database.internal 5432
```

> **Code walkthrough:** curl HTTP testing commands. KEY MECHANISM: `curl -o /dev/null -s -w '%{http_code}'` discards the body and outputs only the status code - perfect for scripted health checks. `curl --resolve host:port:IP` forces DNS resolution to a specific IP for testing backend servers directly. WHY IT MATTERS: curl eliminates browser caching and redirects as confounding variables. WHAT BREAKS: `-k` disables TLS verification - never in production scripts. TAKEAWAY: `curl -o /dev/null -s -w` for scripts; `curl -v` for debugging; use `--max-time` to prevent hanging.

Key aspects: the function takes the command as an array (`"$@"` after
shifting off the numeric args), which handles commands with spaces in
arguments correctly. Exponential backoff with a cap prevents infinite
growth. `return 0` on success, `return 1` on exhaustion.

*What separates good from great:* using `("$@")` to capture the command
as an array and executing with `"${cmd[@]}"` - this handles commands
with arguments that contain spaces, which is the most common retry
function bug.

---

**[JUNIOR] Q5 - How do you source vs execute a shell script and why does it matter?**

Two ways to run a script:

**Execute (fork + exec):** `./script.sh` or `bash script.sh`
- Creates a new process (fork)
- Runs the script in that new process
- When the script exits, you return to the parent shell
- Variables set in the script do NOT affect the parent shell
- The script DOES NOT need execute permission if run with `bash script.sh`

**Source (. or source):** `. script.sh` or `source script.sh`
- Runs the script's commands in the CURRENT shell process
- Variables set in the script DO affect the current shell
- Changes to environment variables persist after the script completes
- `exit` in a sourced script exits the CURRENT shell (dangerous!)

```bash
# Execute: variables don't persist
./setup_env.sh
echo $DB_HOST   # (empty - not in current shell)

# Source: variables DO persist
source ./setup_env.sh
echo $DB_HOST   # my-db-host (set by the script)

# This is how shell profiles work
~/.bashrc contains: export JAVA_HOME=/opt/java
source ~/.bashrc  # or: . ~/.bashrc
echo $JAVA_HOME  # /opt/java
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Sourcing is required when a script's purpose is to set environment
variables in the calling shell. Profile files (`.bashrc`, `.profile`,
`/etc/profile.d/*.sh`) are always sourced, not executed.

*What separates good from great:* warning that `exit` in a sourced
script exits the current shell - a dangerous pattern that can log
users out or kill the calling script's process.

---

**[MID] Q6 - What are common bash script testing strategies?**

Bash scripts are notoriously hard to test, but several approaches work:

1. **`shellcheck`:** Static analysis tool that catches common mistakes
   (unquoted variables, deprecated constructs, ignored exit codes).
   Run as: `shellcheck myscript.sh`

2. **`bash -n`:** Syntax check without execution:
   `bash -n myscript.sh`

3. **Function extraction + testing:**

```bash
# Source the script to load functions (without running main logic)
# Guard the main execution block:
# at end of script:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"   # only run main when executed directly
fi

# Test file:
source ./deploy.sh          # loads functions
# Now test individual functions:
output=$(deploy_to_server "test-server" "1.0.0")
echo "$output" | grep -q "Deploying" || exit 1
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

4. **`bats` (Bash Automated Testing System):** A TAP-compliant test
   framework for bash:
   ```bash
   @test "deploy function logs version" {
       run deploy_to_server "server" "1.0.0"
       [ "$status" -eq 0 ]
       [[ "$output" == *"1.0.0"* ]]
   }
   ```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

5. **Dry-run mode:** Add a `--dry-run` flag that echoes commands instead
   of running them, enabling safe verification of logic.

*What separates good from great:* knowing `shellcheck` and the
`BASH_SOURCE` guard pattern for making scripts both sourceable for
testing and executable for use.

---

**[JUNIOR] Q7 - How do you write a script that handles signals and does cleanup on exit?**

```bash
#!/bin/bash
set -euo pipefail

# Trap handler: runs on EXIT, INT (Ctrl+C), and TERM (kill)
TMPFILE=""
PID_FILE="/var/run/myapp-deploy.pid"

cleanup() {
    local exit_code=$?
    echo "Cleaning up..." >&2

    # Remove temp files
    [[ -n "$TMPFILE" && -f "$TMPFILE" ]] && rm -f "$TMPFILE"

    # Remove PID file
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"

    # Restore service if deployment failed
    if [[ $exit_code -ne 0 ]]; then
        echo "Deployment failed, initiating rollback..." >&2
        systemctl start myapp-backup 2>/dev/null || true
    fi

    exit $exit_code
}

# Register the trap BEFORE doing any work
trap cleanup EXIT INT TERM

# Create temp file (will be cleaned up)
TMPFILE=$(mktemp /tmp/deploy.XXXXXX)

# Write PID for monitoring
echo $$ > "$PID_FILE"

# Main deployment logic here
download_artifact "$VERSION" > "$TMPFILE"
deploy_artifact "$TMPFILE"
```

> **Code walkthrough:** Process group signal delivery with EXIT trap. KEY MECHANISM: `kill -- -PGID` sends signal to all processes with matching PGID; `trap 'kill -- -$$' EXIT` executes the kill when the shell exits for any reason (normal, SIGTERM, error). WHY IT MATTERS: without this trap, child processes become orphans when the parent shell is killed. WHAT BREAKS: if the script is run as a child of another process, `$$` is the shell's PID which may not be the PGID. TAKEAWAY: `trap 'kill -- -$$' EXIT` is the correct idiom for ensuring child process cleanup in scripts.

`trap cleanup EXIT` runs the cleanup function on any exit (normal,
error, or signal). Trapping both `EXIT` (all exits) and the specific
signals (`INT`, `TERM`) ensures cleanup runs even on `Ctrl+C` or
`kill`. Saving `$?` at the start of cleanup preserves the original
exit code so it can be re-used.

*What separates good from great:* saving `$?` at the start of the
trap function (the trap resets it) and using it to conditionally
trigger rollback - showing understanding of production deployment
failure handling.

---

---

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*


# Package Management: apt, yum, and dnf

**Interview Weight:** Low - operational baseline; expected to be
known; gaps here signal lack of Linux server experience.

---

### 🎯 Model Answer

**30-second answer:**

"apt is the Debian/Ubuntu package manager. yum and dnf are the Red Hat
family managers - dnf replaced yum in RHEL 8+. All three install,
update, and remove software packages with automatic dependency
resolution. The most important production skills: pin package versions
to avoid accidental upgrades, use package holds during stability
windows, and always test package upgrades in staging first."

**3-minute answer:**

"Package managers handle software installation, dependency resolution,
and updates. The three main ecosystems:

apt (Advanced Package Tool) on Debian/Ubuntu: `apt install nginx`,
`apt update` (refreshes repo metadata), `apt upgrade` (upgrades
installed packages). Configuration in `/etc/apt/sources.list.d/`.
Package state in `/var/lib/dpkg/`.

yum/dnf on RHEL/CentOS/Fedora: same concepts, different commands.
`dnf install nginx`, `dnf check-update`, `dnf update`. dnf is the
replacement for yum (better dependency resolution, Python 3). Repos
in `/etc/yum.repos.d/`.

Key production practices:
1. Pin versions: `apt install nginx=1.24.0-1ubuntu1` or `dnf install
   nginx-1.24.0`
2. Hold packages: `apt-mark hold nginx` prevents accidental upgrades
3. Clean metadata: `apt clean` or `dnf clean all` before fresh installs
4. Verify integrity: packages are GPG-signed; adding unsigned repos
   requires `--no-check-certificate` or explicit trust (security risk)
5. `apt-get` vs `apt`: `apt-get` is stable for scripting; `apt` has
   interactive output formatting (progress bars) unsuitable for logs."

**Blank Mind Recovery:**

"apt = Debian/Ubuntu, dnf/yum = Red Hat family. Install, update,
remove with dependency resolution. Pin versions, hold packages, verify
GPG signatures. apt-get for scripts (not apt)."

---

### 📘 Concept Explanation

**What it is:**

A package manager installs, upgrades, configures, and removes software
packages along with their dependencies. Packages are pre-built
archives (`.deb` for Debian, `.rpm` for Red Hat) containing binaries,
libraries, config files, and metadata.

**The problem it solves:**

Without package management, installing software requires: downloading
source, resolving dependencies manually, compiling, installing to
correct paths, and managing upgrades. Package managers automate all
of this and maintain a registry of installed packages.

**How it works:**

1. Metadata refresh: `apt update` or `dnf check-update` fetches the
   package index from configured repositories
2. Dependency resolution: the solver finds all required packages and
   their compatible versions
3. Download: packages are fetched from repository mirrors
4. Signature verification: GPG signature checked against trusted keys
5. Installation: files extracted to correct filesystem locations,
   pre/post-install scripts run
6. Database update: local package database records the installed state

**The key insight:**

Package managers maintain a transaction log. `apt history` and
`dnf history` show exactly what was installed, when, and by whom.
This is essential for incident diagnosis: "what changed before the
service started failing?"

**When to pin package versions:**

Production systems should pin application dependencies (nginx, postgresql)
to specific versions. Automatic minor updates are acceptable for
security patches but risky for major.minor changes that may break
configuration compatibility.

**When NOT to use package managers:**

Container images: use package managers during image build (not at
runtime). For development dependencies, language-specific managers
(pip, npm, maven) are preferred over system packages. For immutable
infrastructure, packages should be baked into the image.

**Alternatives:**

Snap, Flatpak: containerized package managers for desktop apps.
Homebrew: macOS package manager, also runs on Linux.
Nix: functional package manager with reproducible builds.

**First-principles derivation:**

"Distributing software requires: a way to bundle all files and
dependencies, a repository to host bundles, a resolver to find
compatible versions, and a mechanism to verify integrity. Package
managers implement all four."

---

### 💻 Code Example

```bash
# apt (Debian/Ubuntu) - essential operations

# Update package index (ALWAYS before install)
apt-get update

# Install specific version
apt-get install -y nginx=1.24.0-1ubuntu1
# -y: non-interactive (assume yes)

# Hold a package (prevent accidental upgrade)
apt-mark hold nginx
apt-mark showhold    # show held packages

# List available versions
apt-cache policy nginx
# nginx:
#   Installed: 1.24.0-1ubuntu1
#   Candidate: 1.24.0-1ubuntu1
#   Version table:
#  *** 1.24.0-1ubuntu1 500
#         500 http://ubuntu.com/ubuntu jammy/main amd64

# Unattended security upgrades (safe auto-update pattern)
apt-get install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades
```

> **Code walkthrough:** `apt-mark hold nginx` pins the installed version
by marking it as manually held; `apt upgrade` and `apt dist-upgrade`
will skip held packages. KEY MECHANISM: the hold flag is stored in
`/var/lib/dpkg/info/nginx.list`; apt's dependency solver respects it.
WHY IT MATTERS: in a production environment where nginx is configured
specifically, an automatic `apt upgrade` during a security patch window
could upgrade nginx to a version with changed default config, breaking
the service. WHAT BREAKS: `apt-get upgrade` respects holds but
`apt-get full-upgrade` (formerly dist-upgrade) can override them when
resolving conflicts. TAKEAWAY: use `apt-mark hold` for production
services and test package upgrades explicitly in staging rather than
relying on holds as the only protection.

```bash
# dnf (RHEL/CentOS/Fedora) - essential operations

# Update package index and check for updates
dnf check-update

# Install
dnf install -y nginx

# Install specific version
dnf install -y nginx-1.24.0

# Exclude package from updates (equivalent to hold)
dnf install -y nginx --disableexcludes=all
# Or add to /etc/dnf/dnf.conf:
echo "exclude=nginx" >> /etc/dnf/dnf.conf

# Transaction history (critical for incident diagnosis)
dnf history list
# ID  Command                Date and time      Action(s)  Altered
#  5  install nginx          2024-01-15 10:00   Install        3

# Roll back a transaction
dnf history undo 5   # undo transaction ID 5

# Security updates only
dnf update --security

# Download only (no install, for air-gapped systems)
dnf download --downloaddir=/tmp/packages nginx
```

> **Code walkthrough:** `dnf history undo 5` rolls back a specific
transaction (all packages installed/updated in that transaction).
KEY MECHANISM: dnf records every transaction in SQLite at
`/var/lib/dnf/history.sqlite`; the undo command reinstalls previous
versions and removes newly installed packages. WHY IT MATTERS: when
a package upgrade causes a service regression, `dnf history undo`
is faster than manually identifying and downgrading packages.
WHAT BREAKS: if a rollback transaction also rolls back a security
patch, the system may be temporarily vulnerable - document and
immediately re-apply the security fix in isolation. TAKEAWAY:
`dnf history undo` is the fastest production rollback for package
upgrades - know transaction IDs from your deployment logs.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"apt is used on Ubuntu/Debian, dnf (or yum) on Red Hat/CentOS. I use
apt update to refresh package metadata, apt install to install, and
apt upgrade to update. For scripting I use apt-get (not apt) because
it has stable output format. I know you should pin versions in
production to avoid unexpected upgrades."

**Senior/Staff:**

"Package management in production requires discipline. My practices:
pin application packages using apt-mark hold or dnf exclude, use
separate apt sources lists per vendor (in /etc/apt/sources.list.d/)
for auditing and removal, verify GPG keys for all third-party repos
before adding them, and use `unattended-upgrades` only for security
patches (not all upgrades). For incident response, `apt history` or
`dnf history list` is the first place I check when a service starts
failing after a maintenance window - package upgrades are a common
undisclosed cause. In containers, I install packages during the build
step with specific versions pinned, clean the apt/dnf cache (`apt-get
clean && rm -rf /var/lib/apt/lists/*`) to reduce image size, and never
run apt/dnf at container startup (breaks immutable image contract)."

---

### ⚠️ Common Misconceptions

**Misconception 1: "apt and apt-get are interchangeable."**

`apt` is designed for interactive use and has human-friendly output
(progress bars, colored text). `apt-get` has stable, parseable output
designed for scripts. Use `apt-get` in scripts and Dockerfiles. `apt`
output format may change between Ubuntu releases, breaking scripts.

**Misconception 2: "Adding --no-check-certificate to repo setup is safe."**

GPG signature verification is the package manager's only protection
against tampered packages. Adding an unsigned repository or disabling
certificate checks (for HTTPS repos) allows man-in-the-middle package
injection. Never skip signature verification in production.

**Misconception 3: "yum and dnf are different package managers."**

dnf (Dandified YUM) is the successor to yum, with the same repository
format, package format (.rpm), and largely compatible commands. RHEL 8+
and Fedora use dnf by default. `yum` on RHEL 8 is an alias for dnf.
The main differences: dnf has better dependency resolution, Python 3,
and module streams (AppStream).

---

### 🚨 Failure Modes and Diagnosis

**Failure: apt-get install fails with "dpkg was interrupted" error**

```bash
# Symptom:
# dpkg: error: dpkg status database is locked by another process
# E: Sub-process /usr/bin/dpkg returned an error code (1)

# Diagnosis 1: Another apt/dpkg process running?
ps aux | grep -E "apt|dpkg"
lsof /var/lib/dpkg/lock-frontend 2>/dev/null
# java  1234  root -> /var/lib/dpkg/lock-frontend

# Wait for it: apt.systemd.daily is the usual culprit
systemctl status apt-daily.service apt-daily-upgrade.service

# Fix 1: Wait for existing process to complete
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for dpkg lock..."
    sleep 2
done

# Diagnosis 2: Interrupted previous install (no active process)
dpkg --configure -a
# Resumes any interrupted package configuration

# Diagnosis 3: Corrupt package database
# Check for interrupted unpacking
ls /var/lib/dpkg/updates/
dpkg --audit   # show incomplete installs

# Recovery (last resort)
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
dpkg --configure -a
apt-get install -f  # fix broken dependencies
```

> **Code walkthrough:** The lock file at `/var/lib/dpkg/lock-frontend`
prevents concurrent package operations; `fuser` checks if any process
holds it. KEY MECHANISM: the `apt-daily` systemd timer runs package
index refresh and security upgrades; it holds the lock during its work,
causing "locked by another process" errors during deployments. WHY IT
MATTERS: forcing the lock removal (`rm -f /var/lib/dpkg/lock*`) while
a legitimate process holds it can corrupt the package database. WHAT
BREAKS: corrupt dpkg database requires manual recovery which involves
`dpkg --configure -a` and potentially reinstalling affected packages.
TAKEAWAY: in CI/CD pipelines, add `while fuser /var/lib/dpkg/lock-frontend; do sleep 5; done` before `apt-get install` to handle the apt-daily race.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | package formats, dependency resolution |
| Debugging | 2 | lock errors, dependency conflicts |
| Trade-off | 3 | pinning, security updates |

---

**[JUNIOR] Q1 - How do you add a third-party repository securely and what are the risks?**

```bash
# Secure third-party repo setup (apt example: Docker)

# Step 1: Download and store the GPG key (NEW recommended method)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Step 2: Add repo with signed-by pointing to the key
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

# Step 3: Update and install
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify the installed package is signed by the expected key
dpkg -l docker-ce | grep ^ii
apt-key list  # DEPRECATED but shows all trusted keys
```

> **Code walkthrough:** curl HTTP testing commands. KEY MECHANISM: `curl -o /dev/null -s -w '%{http_code}'` discards the body and outputs only the status code - perfect for scripted health checks. `curl --resolve host:port:IP` forces DNS resolution to a specific IP for testing backend servers directly. WHY IT MATTERS: curl eliminates browser caching and redirects as confounding variables. WHAT BREAKS: `-k` disables TLS verification - never in production scripts. TAKEAWAY: `curl -o /dev/null -s -w` for scripts; `curl -v` for debugging; use `--max-time` to prevent hanging.

Risks of third-party repos:
1. **Supply chain attack:** A compromised repo can push malicious
   packages to all subscribers. The 2024 `xz-utils` backdoor was
   distributed through a trusted maintainer, not a compromised repo.
2. **Dependency pinning:** Third-party packages may conflict with
   OS packages or pull in unvetted dependencies.
3. **Key rotation:** If a repo key is compromised or rotated, installs
   fail until the key is updated.

Best practice: use the `signed-by` directive (newer method) rather
than `apt-key add` (deprecated). Audit all third-party repos annually
and remove any that are no longer used.

*What separates good from great:* mentioning the `signed-by` directive
as the current secure method (replacing deprecated `apt-key add`) and
explaining why supply chain risk exists beyond just "use HTTPS."

---

**[MID] Q2 - How do you handle dependency conflicts during package installation?**

Dependency conflicts occur when packages require incompatible versions
of a shared dependency.

```bash
# View current dependency conflict
apt-get install python3-mypackage
# python3-mypackage : Depends: python3-requests (>= 2.28)
#  but 2.25.1-1ubuntu1 is to be installed

# Investigate the conflict
apt-cache depends python3-mypackage
apt-cache rdepends python3-requests  # what else requires it?

# Option 1: Update the conflicting package
apt-get install python3-requests  # upgrade to latest available

# Option 2: Install from a different source (PPA, pip)
# Risk: bypasses package manager dependency tracking

# Option 3: Use a virtual environment (Python-specific)
python3 -m venv /opt/myapp/venv
/opt/myapp/venv/bin/pip install requests==2.28

# For RPM conflicts
dnf provides python3-requests  # find package providing it
dnf deplist python3-mypackage  # show all dependencies
dnf install python3-mypackage  # dnf auto-resolves better than yum
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

The modern approach for Python packages: never install application-
specific Python packages via system package manager. Use virtual
environments or containers to isolate Python dependencies entirely.
System Python packages are for OS-level tooling, not application
dependencies.

*What separates good from great:* recommending virtual environments as
the architectural solution rather than dependency conflict resolution
at the OS level - showing awareness that system package managers and
application dependency managers serve different purposes.

---

**[JUNIOR] Q3 - How do you automate security-only updates while avoiding breaking changes?**

```bash
# Ubuntu: unattended-upgrades for security only
cat /etc/apt/apt.conf.d/50unattended-upgrades | \
  grep -A5 "Allowed-Origins"
# "${distro_id}:${distro_codename}-security";
# Uncomment: "${distro_id}ESMApps:${distro_codename}-apps-security";

# Configure automatic security update schedule
cat /etc/apt/apt.conf.d/20auto-upgrades
# APT::Periodic::Update-Package-Lists "1";
# APT::Periodic::Unattended-Upgrade "1";

# RHEL: dnf-automatic for security only
dnf install -y dnf-automatic
# Configure /etc/dnf/automatic.conf:
# [commands]
# upgrade_type = security  <- security patches only
# apply_updates = yes

systemctl enable --now dnf-automatic-install.timer

# Verify which updates are security-related
dnf check-update --security
# Shows only security updates (CVE-tagged packages)

# Test upgrades: preview without applying
apt-get --dry-run upgrade
dnf upgrade --assumeno
```

> **Code walkthrough:** systemd timer and service unit management. KEY MECHANISM: `systemctl list-timers` shows next activation and elapsed time since last run; `journalctl -u` provides searchable historical output for every run. WHY IT MATTERS: unlike cron (email only), systemd captures all output to journald for structured querying. WHAT BREAKS: forgetting `daemon-reload` after creating new unit files means systemd uses the old (missing) unit definition. TAKEAWAY: `systemctl enable --now service.timer` enables at boot and starts immediately; always follow unit file creation with `daemon-reload`.

The critical distinction: security updates (patching known CVEs) are
lower risk than feature updates (new major.minor versions). Security
updates are typically backport patches against the current version,
not version upgrades. Automating security updates reduces the mean
time to patch while avoiding the instability of feature updates.

Caution: even security patches can break behavior (nginx TLS cipher
list changes, OpenSSL API deprecations). Review security changelog
before automating. Test in staging with unattended-upgrades in dry-run
mode for 2 weeks before enabling auto-apply in production.

*What separates good from great:* distinguishing security backport
patches (low risk) from version upgrades (higher risk) and recommending
the staging validation period before enabling auto-apply.

---

**[MID] Q4 - What is the difference between apt update, apt upgrade, and apt dist-upgrade?**

These three commands have distinct effects that matter for production:

`apt-get update`: Refreshes the local package index cache from configured
repositories. Downloads metadata only - installs nothing. Must be run
before installing or upgrading packages to see current versions.

`apt-get upgrade`: Upgrades all installed packages to the latest
available version in the refreshed index. Does NOT remove any packages
or install new dependencies. If upgrading a package requires adding
new dependencies or removing existing ones, the package is skipped.

`apt-get dist-upgrade` (also `apt-get full-upgrade`): Same as upgrade
but also handles changing dependencies. It will install new packages
and remove existing ones if needed to satisfy the upgraded packages'
dependencies. This is required for major OS releases and for packages
that change their dependency structure.

For production safety:
- `apt-get update`: safe to run anytime (metadata only)
- `apt-get upgrade`: safe for security patches, risky for major updates
- `apt-get dist-upgrade`: NOT for production automation; reserved for
  planned OS upgrades with full staging validation

In CI/CD pipelines that build Docker images, the correct sequence is:
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      specific-package=1.2.3-1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

> **Code walkthrough:** Package manager commands for Debian/Red Hat families. KEY MECHANISM: `apt install` (Debian) resolves dependencies from configured repositories and applies them atomically; `dnf` (RHEL 8+) is the next-generation yum with better dependency resolution. WHY IT MATTERS: `apt-get upgrade` (all packages) vs `apt-get install --only-upgrade PKG` (specific) - full upgrades on production servers can break running services. WHAT BREAKS: mixing packages from different distributions causes unsatisfied dependencies that corrupt the package database. TAKEAWAY: always test `apt upgrade` in staging before production; pin critical packages with `apt-mark hold PACKAGE`.

*What separates good from great:* knowing that `dist-upgrade` can
remove packages (and that this could break a running service) and
explicitly recommending against automating it.

---

**[JUNIOR] Q5 - How do you install packages in a Dockerfile efficiently and securely?**

```dockerfile
# BAD: separate RUN commands create multiple layers
# BAD: no version pinning
# BAD: no cache cleanup
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y postgresql-client

# GOOD: single RUN, pinned versions, cache cleaned
FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nginx=1.24.0-1ubuntu1 \
      postgresql-client-14=14.10-0ubuntu0.22.04.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# Best: multi-stage with minimal runtime image
FROM ubuntu:22.04 AS builder
RUN apt-get update && apt-get install -y build-essential
COPY . .
RUN make install

FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bin/myapp /usr/local/bin/
```

> **Code walkthrough:** Chaining all apt operations in a single RUN
creates one Docker layer; separate RUN commands create separate layers
that cannot be combined in the final image. KEY MECHANISM:
`--no-install-recommends` skips optional recommended packages, reducing
image size by 30-70%; `apt-get clean` removes downloaded .deb files;
`rm -rf /var/lib/apt/lists/*` removes the package index cache.
WHY IT MATTERS: a typical nginx install without cleanup in a Docker
layer adds ~150MB of cache that serves no runtime purpose. WHAT BREAKS:
combining apt operations in one RUN and then doing `apt-get clean` in a
separate RUN does NOT reduce image size - the cache was already committed
to a layer. TAKEAWAY: always combine apt update + install + clean in a
single RUN and include `rm -rf /var/lib/apt/lists/*` to minimize layer
size.

*What separates good from great:* explaining why combining into one RUN
is required for cache cleanup to reduce image size (not just a style
preference) and mentioning `--no-install-recommends`.

---

**[MID] Q6 - How do you diagnose why a package installation fails with a dependency error?**

```bash
# Symptom: dependency error during install
apt-get install mypackage
# The following packages have unmet dependencies:
#  mypackage : Depends: libssl1.1 (>= 1.1.0) but it is not installable

# Step 1: identify what provides the dependency
apt-cache show libssl1.1 | grep Version
# Not available in Ubuntu 22.04 (replaced by libssl3)

# Step 2: check what alternatives are available
apt-cache search "libssl"
# libssl3 - Secure Sockets Layer toolkit - shared libraries
# libssl1.0.0 - not available

# Step 3: check if the package has a different version for this OS
apt-cache policy mypackage
# Candidate: (none) - not available for this Ubuntu version

# Step 4: find the correct package for this distro
# Check the vendor's repo for Ubuntu 22.04 (Jammy) specific build

# Step 5: if using an older package on a newer OS
# Download the dependency manually (temporary workaround)
curl -fsSL http://security.ubuntu.com/ubuntu/pool/main/o/openssl/\
libssl1.1_1.1.1f-1ubuntu2_amd64.deb -O
dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
# WARNING: manually installed packages bypass security updates

# For RPM:
dnf provides libssl.so.1.1
dnf install compat-openssl11   # compatibility shim
```

> **Code walkthrough:** curl HTTP testing commands. KEY MECHANISM: `curl -o /dev/null -s -w '%{http_code}'` discards the body and outputs only the status code - perfect for scripted health checks. `curl --resolve host:port:IP` forces DNS resolution to a specific IP for testing backend servers directly. WHY IT MATTERS: curl eliminates browser caching and redirects as confounding variables. WHAT BREAKS: `-k` disables TLS verification - never in production scripts. TAKEAWAY: `curl -o /dev/null -s -w` for scripts; `curl -v` for debugging; use `--max-time` to prevent hanging.

The fundamental issue is often trying to install a package built for
an older OS version on a newer OS where the old library is replaced.
The correct solution is to use a package built for the target OS, not
to downgrade the system library.

*What separates good from great:* recognizing that manually installing
old library versions to satisfy dependencies creates security risks
(the old version won't receive security updates) and recommending the
proper solution (use a package built for the target OS).

---

**[JUNIOR] Q7 - What is the difference between apt and dpkg and when do you use each?**

`dpkg` is the low-level package tool that installs, configures, and
removes individual `.deb` packages. It does NOT handle dependencies -
if a dependency is missing, dpkg installs the package anyway but marks
it as "broken."

`apt` is the high-level tool built on top of dpkg that adds dependency
resolution, repository management, and metadata handling. `apt install`
resolves all dependencies, downloads them, and passes them all to dpkg
in the correct order.

Use cases for dpkg directly:
- `dpkg -l`: list all installed packages (fast, no network)
- `dpkg -L package`: list files installed by a package
- `dpkg -S /path/to/file`: which package owns this file?
- `dpkg -i ./manual_download.deb`: install a local .deb file
  (use with caution - dependencies must be manually satisfied)
- `dpkg --audit`: find packages in broken state
- `dpkg --configure -a`: configure any unconfigured packages (post-crash recovery)

```bash
# Find which package provides a command
dpkg -S $(which nginx)
# nginx: /usr/sbin/nginx

# List all files from a package
dpkg -L nginx | grep "^/etc"
# /etc/nginx/nginx.conf
# /etc/nginx/sites-available/default

# Check package status
dpkg -s nginx | grep Status
# Status: install ok installed
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

*What separates good from great:* knowing `dpkg -S $(which cmd)` to
find which package owns a binary - essential when a command behaves
unexpectedly and you need to identify its version and package origin.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*

