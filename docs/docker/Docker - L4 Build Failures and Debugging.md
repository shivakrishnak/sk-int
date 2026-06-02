---
layout: default
title: "Docker - L4 Build Failures and Debugging"
parent: "Docker"
nav_order: 12
permalink: /docker/l4-build-failures-and-debugging/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker - L4 Build Failures and Debugging](#docker---l4-build-failures-and-debugging) | medium |

---

# Docker - L4 Build Failures and Debugging

## Docker Build Failures and Debugging

---

### 🎯 Model Answer

**30 seconds:**
> Docker build failures: categorized by phase. Context phase: build
> context too large or `.dockerignore` misconfigured. Pull phase:
> registry authentication, rate limiting, or network connectivity.
> Instruction phase: `RUN` command fails, package not found, permission
> denied, or cache corruption. Multi-stage: wrong `--from` name,
> missing artifact. BuildKit: secret or cache mount misconfiguration.
> Debug approach: `--progress=plain` for full output, `--target` to
> isolate stages, `docker run --entrypoint sh` to inspect intermediate
> state.

**3 minutes (Senior):**
> Systematic build failure diagnosis: (1) **`--progress=plain`**: without
> it, BuildKit shows condensed output that hides error details. With
> it: every instruction is shown with its full stdout/stderr. Failed
> `RUN apt-get install -y missing-package` shows: "E: Unable to locate
> package missing-package". (2) **Isolate with `--target`**: for a
> multi-stage build failure in the `builder` stage: `docker build
> --target builder .` builds only up to that stage. Faster iterations
> when debugging one stage. (3) **Inspect intermediate state**: when
> a `RUN` command fails: Docker caches all previous layers. Run the
> container from the last successful layer to inspect state: `docker
> run --rm -it --entrypoint sh <image-up-to-failed-step>`. Explore
> the filesystem, test the failing command manually. (4) **Cache
> issues**: stale cache causes subtle failures (package index cached,
> then package removed from repository). `--no-cache` forces full
> rebuild. (5) **BuildKit debugging**: `DOCKER_BUILDKIT=0 docker build`
> falls back to legacy builder (useful to isolate BuildKit-specific issues).
> `--secret` failures: verify the secret file exists and path is
> correct. (6) **Platform issues**: building for the wrong architecture.
> `--platform linux/amd64` on Apple Silicon (arm64) host: cross-compile.
> Missing `QEMU` emulation: `apt-get` may fail during emulation.

**Blank Mind Recovery:**

**(1) Restate:** "Add --progress=plain first (see full output). Then
--no-cache (rule out stale cache). Then --target (isolate stage).
Then docker run --entrypoint sh on the image-to-date (interactive
debug). For platform issues: --platform flag + QEMU. For registry
issues: docker login first."

**(2) First principles:** "A build is a sequence of instructions.
Each instruction can fail for a different reason. Isolate the failing
instruction. Run it manually in an interactive shell. Now it's just
a debugging problem, not a Docker problem."

**(3) Bridge:** "Build debugging is like debugging a recipe in a
new kitchen. --progress=plain: the full recipe with steps visible.
--target: prepare only up to the soup course. docker run --entrypoint
sh: walk into the kitchen at that point and look around before
adding the next ingredient."

---

### 📘 Concept Explanation

**Build context, registry failures, RUN failures, cache corruption, platform:**

```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```
COMMON BUILD FAILURE CATEGORIES:

  1. BUILD CONTEXT FAILURES:
  
  # Error: "error checking context: can't stat '/path/to/file'"
  # Cause: .dockerignore refers to a path that can't be statted.
  # Or: build context includes a broken symlink.
  
  # Error: context takes > 5 minutes to send to daemon.
  # Cause: node_modules/, .git/, dist/ included in context.
  # Fix:
  cat > .dockerignore <<'EOF'
  .git/
  node_modules/
  dist/
  .env
  *.log
  coverage/
  EOF
  
  # Check context size:
  docker build . 2>&1 | head -3
  # "Sending build context to Docker daemon  1.23GB"  <- too large

  2. REGISTRY AND PULL FAILURES:
  
  # Error: "pull access denied for myregistry/myapp"
  docker login myregistry.io
  # Provide credentials. Then retry.
  
  # Error: "toomanyrequests: You have reached your pull rate limit"
  # Docker Hub: 100 pulls per 6h (unauthenticated), 200 (authenticated).
  # Fix: authenticate to Docker Hub, or use a pull-through cache.
  # Docker daemon configuration for mirror:
  # /etc/docker/daemon.json:
  {
    "registry-mirrors": ["https://my-dockerhub-mirror.example.com"]
  }
  
  # For CI (GitHub Actions): use ghcr.io or own registry.
  # Or: use Docker Hub auth in CI to get higher rate limits.
  
  # Error: "x509: certificate signed by unknown authority"
  # Cause: private registry with self-signed certificate.
  # Fix: add CA certificate to Docker daemon:
  mkdir -p /etc/docker/certs.d/myregistry.io
  cp myca.crt /etc/docker/certs.d/myregistry.io/ca.crt
  systemctl restart docker

  3. RUN INSTRUCTION FAILURES:
  
  # Error: "E: Unable to locate package libssl-dev"
  # Cause 1: apt-get update not run before install (cached update).
  # Fix: combine update + install in one RUN instruction.
  RUN apt-get update && \
      apt-get install -y --no-install-recommends libssl-dev && \
      rm -rf /var/lib/apt/lists/*
  
  # Cause 2: package name changed between Debian releases.
  # Fix: build with --no-cache to get fresh package index.
  # Or: verify package name in the base image version.
  
  # Error: "npm ERR! code E404 - Not Found"
  # Cause: npm registry network issue, or package version doesn't exist.
  # Cause 2: private npm registry not configured (missing .npmrc).
  
  # Error: "Permission denied" during RUN.
  # Cause: USER was set before a step that requires root.
  # Fix: perform root operations BEFORE switching to USER.
  FROM node:18
  RUN apt-get update && apt-get install -y curl  # root operations first
  USER node                                        # then switch user
  RUN npm ci                                       # then user operations

  4. MULTI-STAGE BUILD FAILURES:
  
  # Error: "failed to get the target platform from stage: unknown stage"
  # Cause: --from target name doesn't match an AS name.
  # BAD:
  FROM maven:3.9 as Builder  # capital B
  FROM eclipse-temurin:17    # 
  COPY --from=builder /app/target ./  # lowercase b - doesn't match!
  
  # GOOD: consistent naming (case-sensitive):
  FROM maven:3.9 AS builder   # AS builder (lowercase)
  FROM eclipse-temurin:17
  COPY --from=builder /app/target ./  # matches exactly
  
  # Error: "COPY --from: file not found"
  # Cause: the file was not generated in the expected path.
  # Debug: build --target builder, then inspect:
  docker build --target builder -t debug-builder .
  docker run --rm debug-builder ls /app/target/
  # Find the actual path of the artifact.

  5. BUILDKIT-SPECIFIC FAILURES:
  
  # Error: "failed to solve with frontend dockerfile.v0:
  #   could not read secret: secret not found"
  # Cause: --secret not provided in build command.
  # Fix:
  docker buildx build \
    --secret id=npmrc,src=.npmrc \
    -t myapp .
  
  # Error: "# syntax = docker/dockerfile:1" must be first line.
  # Cause: BuildKit features (--mount etc.) require the syntax directive.
  # Fix: add as the FIRST line of the Dockerfile:
  # syntax=docker/dockerfile:1
  
  # Cache mount failure: "Error while mounting cache: ..."
  # Usually a permissions issue with the cache directory.
  # Fix: specify uid/gid:
  RUN --mount=type=cache,target=/root/.m2,uid=1000,gid=1000 mvn package

  6. PLATFORM/ARCHITECTURE FAILURES:
  
  # Building for linux/amd64 on Apple Silicon (linux/arm64):
  docker buildx build --platform linux/amd64 -t myapp .
  
  # Error during emulation: "exec format error" or apt-get failures.
  # Cause: QEMU emulation not set up.
  # Fix:
  docker run --privileged --rm tonistiigi/binfmt --install all
  # Installs QEMU binfmt handlers for multi-platform emulation.
  
  # Alternative: use multi-platform build with native runners.
  # GitHub Actions: use multiple runners (amd64 + arm64).

DEBUGGING TECHNIQUES:

  # Technique 1: --progress=plain for full output:
  DOCKER_BUILDKIT=1 docker build --progress=plain . 2>&1 | tee build.log
  # Tee: shows output AND saves to file. Grep the file for errors.
  grep -n "ERROR\|error\|FAIL\|failed" build.log | head -20
  
  # Technique 2: inspect intermediate state:
  # After a build failure: Docker has cached layers up to the failure.
  # Find the last successful image:
  docker image ls --filter dangling=true
  # The most recent intermediate image is what we need.
  docker run --rm -it --entrypoint sh <image-id>
  # Inside: run the failing command manually, see exact error.
  
  # Technique 3: --no-cache to reset cache:
  docker build --no-cache .
  # If this fixes the issue: stale cache was the cause.
  
  # Technique 4: isolate with --target:
  docker build --target test -t debug-test .  # build up to test stage
  docker run --rm debug-test sh -c "ls /app && cat /app/package.json"
  
  # Technique 5: disable BuildKit for comparison:
  DOCKER_BUILDKIT=0 docker build .
  # If this succeeds: BuildKit-specific issue.
  # Check syntax directive and --mount usage.
  
  # Technique 6: verbose networking (for network-dependent RUN):
  docker build --network=host .
  # Uses host networking for all RUN instructions.
  # If this fixes DNS/connectivity issues: container network config problem.
```

> **Code walkthrough:** BAD pattern: This If this fixes DNS/connectivity issues: container network config problem. example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A systematic debugging session for a failingice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> multi-stage Node.js build demonstrates all six techniques.

```bash
# Build failure: "npm ci" fails with "ENOTFOUND registry.npmjs.org"
# Inside a CI environment with restricted network.

# STEP 1: Get full output:
DOCKER_BUILDKIT=1 docker build --progress=plain . 2>&1 | tee build.log
# grep for the exact error:
grep -A5 "ENOTFOUND" build.log
# #10 0.934 npm error ENOTFOUND registry.npmjs.org
# #10 0.934 npm error network This is a problem related to network connectivity.

# STEP 2: Is npm able to reach the registry?
# Enter the base image to test manually:
docker run --rm node:18-alpine sh -c "
  curl -I https://registry.npmjs.org/ 2>&1 | head -5
"
# curl: (6) Could not resolve host: registry.npmjs.org
# DNS issue in the Docker network.

# STEP 3: Check DNS configuration:
docker run --rm node:18-alpine cat /etc/resolv.conf
# nameserver 127.0.0.11  <- Docker embedded DNS (normal)
# If no nameserver or wrong one: Docker DNS is misconfigured.

# STEP 4: Try building with host networking:
docker build --network=host .
# SUCCESS: --network=host bypasses Docker's DNS.
# Root cause: corporate VPN/DNS not visible to Docker's embedded DNS.

# PERMANENT FIX: configure Docker daemon DNS:
# /etc/docker/daemon.json:
cat > /etc/docker/daemon.json <<'EOF'
{
  "dns": ["10.0.0.1", "8.8.8.8"],  # corporate DNS + fallback
  "dns-search": ["company.internal"]
}
EOF
systemctl restart docker
# Now all containers use the correct DNS.
```

> **Code walkthrough:** The debugging follows the systematic approach:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `--progress=plain` reveals the exact error message (network ENOTFOUND).
> Testing the base image interactively confirms DNS resolution fails
> inside Docker's network namespace. `--network=host` bypasses the
> Docker bridge DNS as a diagnostic and confirms the hypothesis. The
> permanent fix: configure the Docker daemon's DNS to include the
> corporate DNS server (which is accessible on the host but not
> automatically available inside Docker's bridge network, especially
> with VPN).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> For any build failure: first add `--progress=plain` to see the
> full output. Then try `--no-cache` to rule out stale cache. For
> permission errors: check that root operations come before the `USER`
> directive. For multi-stage failures: verify `--from` names are
> consistent (case-sensitive).

---

**Senior / Staff (5+ years):**
> The most subtle build failure category: inconsistent behavior between
> local builds (developer machine) and CI builds. Root causes: (1)
> Docker version mismatch (local: 24.x, CI: 20.x). BuildKit features
> not available in older CI Docker. Fix: pin Docker version in CI.
> (2) Architecture mismatch: developer on ARM Mac, CI on AMD64.
> Build succeeds locally (ARM), fails in CI (AMD64) due to arch-specific
> dependencies. Fix: `docker buildx bake --platform linux/amd64` in
> local pre-CI test. (3) Network access: CI network restrictive,
> developer network open. Fix: test with `--no-cache` and `--network=host`
> locally to simulate CI. (4) File permissions: CI runs as root,
> developer as non-root. `COPY` behavior differs for files owned by
> different users. Fix: always use `--chown` in COPY.

---

### ⚠️ Common Misconceptions

**Misconception: "Build failures always produce clear error messages at the point of failure."**
Docker build output (without `--progress=plain`) truncates long
output and shows condensed summaries. A failing `RUN` instruction
may show only `ERROR [builder 4/8]` without the underlying error.
The actual error: buried in the BuildKit log, not shown by default.
`--progress=plain` is essential for build debugging. Additionally:
a `RUN` instruction can fail silently if the command uses a pipe
without `set -o pipefail`. `RUN curl http://example.com | bash`
with a failing curl: bash succeeds (empty input), the `RUN` returns
0 (success). The build continues with a broken installation. The
failure manifests later as a runtime error, not a build error.
Always use `set -eo pipefail` in `RUN` instructions that use pipes:
`RUN set -eo pipefail && curl ... | bash`.

---

### ⚖️ Comparison Table

| Failure Category | Primary Symptom | First Debug Step | Common Root Cause |
|---|---|---|---|
| Build context | Slow context transfer | Check context size | Missing .dockerignore |
| Registry auth | "pull access denied" | docker login | Expired credentials |
| Rate limit | "toomanyrequests" | Check Docker Hub auth | Unauthenticated pulls |
| RUN command | Non-zero exit code | --progress=plain | Stale package cache |
| Multi-stage COPY | "file not found" | --target + inspect | Wrong artifact path |
| BuildKit secret | "secret not found" | Check --secret flag | Missing build arg |
| Platform | "exec format error" | --platform flag | Missing QEMU |

---

### 🏛️ System Design

*(Omit: build failure diagnosis is a toolchain skill, not a system architecture concern.)*

---

### 📊 Diagram

*(Omit: the build debugging flowchart is most effective as the text-based systematic approach above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Build succeeds locally but fails identically every time in CI.**
```
Symptom: CI build fails. Developer machine: succeeds. Every time.
  No code changes. CI error: "ERROR: process '/bin/sh -c npm ci' did
  not complete successfully: exit code: 128"

Differential factors (local vs CI):
  1. Docker version (docker --version).
  2. BuildKit version.
  3. Architecture (local: arm64/Apple Silicon, CI: amd64/Linux).
  4. Network access (DNS, registry, private npm registry).
  5. File permissions (local: developer user, CI: root or CI user).
  6. Cache state (local: warm cache, CI: cold cache).

Diagnosis methodology:
  # Step 1: replicate cold cache locally:
  docker build --no-cache .
  # Does it fail? If yes: cache was masking the issue.
  
  # Step 2: replicate platform:
  docker buildx build --platform linux/amd64 --no-cache .
  # Does it fail? If yes: platform-specific issue.
  
  # Step 3: check CI Docker version:
  # CI log: "Docker version 20.10.12"
  # Local: "Docker version 24.0.6"
  # Incompatibility: BuildKit syntax directive required for v24.
  # Add: # syntax=docker/dockerfile:1 as first line.
  
  # Step 4: check file ownership in CI:
  ls -la package-lock.json   # local: -rw-r--r-- username
  # CI: the git checkout may change permissions. 
  # git config: core.fileMode = false on some CI environments.
  # COPY of executable files loses execute bit.
  # Fix: RUN chmod +x /app/start.sh explicitly.
  
  # Step 5: network test from CI runner:
  # Add to Dockerfile (TEMPORARY, for debugging only):
  RUN curl -v https://registry.npmjs.org/ 2>&1 | head -20
  # Remove after diagnosis.
```

> **Code walkthrough:** This Remove after diagnosis. example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Build failure categories overview | 2 minutes |
| --progress=plain explanation | 1 minute |
| Inspecting intermediate state | 2 minutes |
| Multi-stage COPY failure | 1 minute |
| Registry rate limit | 1 minute |
| apt-get update cache staleness | 2 minutes |
| Local vs CI discrepancy | 3 minutes |
| BuildKit secret failure | 1 minute |
| Platform/architecture failures | 2 minutes |
| DNS failure during build | 2 minutes |
| set -eo pipefail necessity | 1 minute |
| Permission denied in RUN | 1 minute |

---

**Q1 (debugging): A build succeeds first time but fails on the second run with "package has no installation candidate." Explain the root cause and fix.**

A: Classic stale apt cache issue. The Dockerfile has `RUN apt-get update`
as a separate instruction from `RUN apt-get install`. First build:
no cache. Both instructions execute. The apt package index: fresh.
Package found, installed. Build succeeds. First instruction cached.
Second build: `apt-get update` layer is cached (the apt cache layer
is still valid because the instruction didn't change). `apt-get install`:
cache miss (different package list or the Dockerfile changed). apt-get
tries to install against the STALE cached index from the first build.
If the package was added recently or if the base image's package repo
has moved: "package has no installation candidate." Root cause:
`apt-get update` and `apt-get install` MUST be in the same `RUN`
instruction. They share a cache lifecycle. Fix: `RUN apt-get update &&
apt-get install -y --no-install-recommends mypackage && rm -rf
/var/lib/apt/lists/*`. Single instruction: update + install are
atomic from the cache perspective. The `rm` reduces layer size.

*What separates good from great:* The `--no-install-recommends` flag.
Without it: `apt-get` installs "Recommended" packages (docs, optional
tools, language packs) in addition to the requested package. These
can add 50-200MB per `apt-get install` call. For a production image:
install only what the application needs. If specific functionality
is missing: add it explicitly rather than relying on recommendations.
Additionally: `apt-get clean` vs `rm -rf /var/lib/apt/lists/*`.
The `clean` command removes downloaded .deb packages. The `rm -rf`
removes the package index. Both should be in the same `RUN` instruction
to actually reduce the layer size (since Docker layer is a filesystem
snapshot: if you add then delete in the same instruction, the delete
is never in the layer).

---

**Q2 (debugging): How do you debug a failing RUN instruction in a multi-stage Dockerfile where you can't reproduce the failure interactively?**

A: Three techniques. (1) Build to the failing stage with `--target`
and `--no-cache`: `docker build --target builder --no-cache -t
debug-build .`. If the build stops at the failing instruction: there
is a cached layer immediately before it. `docker images -a` or
`docker image ls --filter dangling=true` shows intermediate images.
Run the most recent one: `docker run --rm -it --entrypoint sh <id>`.
Now run the failing command manually with full verbosity: `apt-get install
-v mypackage` or `npm install --verbose`. (2) Add a `RUN echo` before
the failing instruction to print filesystem state: `RUN ls -la /app/
&& cat /etc/os-release && echo "PATH=$PATH"`. This appears in
`--progress=plain` output. Remove after debugging. (3) SSH debug
with BuildKit: add `--ssh default` to the build command. Inside
the build: `RUN --mount=type=ssh ssh-add -l` verifies the SSH agent
is accessible. Then: `docker build --ssh default --progress=plain .`.

*What separates good from great:* Using `docker buildx build
--progress=rawjson` for automated CI log parsing. Raw JSON output
includes vertex IDs, timestamps, and complete stderr for every step.
A CI system can parse this JSON to extract: which instruction failed,
the exact stderr, the duration of each step, and cache hit/miss
status. This enables CI dashboards that track build performance over
time and alert when specific steps regress. "Step 5 (npm install)
now takes 2 minutes instead of 5 seconds: cache miss rate increased."
This is build observability: treating the build pipeline as a monitored
system, not just a pass/fail check.

---

**Q3 (production): How do you prevent build failures caused by upstream dependency changes breaking reproducible builds?**

A: Multi-layer dependency pinning. (1) **Language dependencies**: use
lockfiles. `package-lock.json` (npm: `npm ci`), `Pipfile.lock`
(Python: `pip install --require-hashes`), `pom.xml` with pinned
versions (Maven), `go.sum` (Go). Commit lockfiles. Never skip them.
CI: run `npm ci` (not `npm install`) to enforce the lockfile. (2)
**OS packages**: pin apt versions. `apt-get install -y libssl-dev=3.0.2-0ubuntu1`.
This fails if the exact version is unavailable (which is the goal:
fail explicitly, don't silently install a different version). (3)
**Base image**: pin to digest. `FROM node:18-alpine@sha256:abc123`.
The digest is immutable. The base image never changes under you.
Dependabot/Renovate: weekly PRs to update the digest (with a PR
description: "Updates base image node:18-alpine from sha256:abc to
sha256:def, resolving CVE-2024-1234"). (4) **Build environment**:
pin the Docker version in CI: `docker/setup-buildx-action@v3` with
a specific `buildx-version`. Pin the build runner: GitHub Actions
`ubuntu-22.04` (not `ubuntu-latest` which changes).

*What separates good from great:* Hash verification for scripts
downloaded during build. `RUN curl -fsSL https://example.com/setup.sh
| bash` is never reproducible: the script content can change. Better:
download + verify hash: `RUN curl -fsSL https://example.com/setup.sh
-o setup.sh && echo "abc123 setup.sh" | sha256sum -c - && bash
setup.sh`. Or better still: vendor the script into the repository.
For production builds: every artifact fetched during `docker build`
should be either: in the build context (vendored), from a pinned registry
(digest), or verified via cryptographic hash. Unverified remote
fetches are a supply chain attack vector.

---

**Q4 (trade-off): When should you use `--no-cache` and when is it counterproductive?**

A: `--no-cache` is appropriate: (1) when diagnosing a build failure
suspected to be caused by stale cache (package not found, wrong
version installed); (2) in CI for release builds (ensures the final
release image is truly reproducible from scratch, no hidden cache
state); (3) after base image updates (the digest pin in `FROM` will
invalidate cache anyway, but `--no-cache` guarantees it). It is
counterproductive: (1) for every CI build on every feature branch.
A cold build of a Java application: `mvn package` downloads all
dependencies again: 3-5 minutes. With cache mounts:
`--mount=type=cache,target=/root/.m2`: 20 seconds. The developer
who disables caching for "safety" causes 10x longer CI times for
the entire team. (2) For builds where the cache is genuinely valid:
pinned dependencies, no external state. The cache is an optimization,
not a liability. Strategy: use cache mounts (`--mount=type=cache`)
for dependency directories (npm cache, Maven local repo, pip cache).
These mounts are not part of the image layer cache. They persist
between builds independently. `--no-cache` clears layer cache but
NOT cache mounts. Selectively invalidate: change
`ARG CACHEBUST=$(date +%s)` before a `RUN` to invalidate just that step.

*What separates good from great:* Remote cache for team-wide builds.
`docker buildx build --cache-from type=registry,ref=myregistry/app:cache
--cache-to type=registry,ref=myregistry/app:cache,mode=max .`.
Every CI build populates a shared registry cache. The next build
on a different machine starts from cache. `mode=max` exports
intermediate layer cache, not just the final image. This is the
difference between a 5-second CI build and a 5-minute CI build
for a team of 20 developers. Registry cache is the correct answer
for "how do you cache Docker builds across machines."

---

**Q5 (diagnostic): A Dockerfile fails with "COPY failed: file not found
in build context or excluded by .dockerignore". What is happening?**

A: The file is in the build context directory, but `.dockerignore`
removes it before it reaches the daemon. Check `.dockerignore` for
rules matching the filename. Common cases: (1) `Dockerfile` explicitly
listed in `.dockerignore` (unusual but possible). (2) `COPY target/ .`
fails because `target/` is in `.dockerignore` (correct behavior for
the developer workflow, but the COPY instruction is wrong). Fix:
either remove the exclusion for files genuinely needed in the build,
or restructure the Dockerfile. CI-only files (Dockerfile, Makefile,
scripts): should almost never be COPY-ed into the image. To debug
context contents: temporarily add `RUN find . -type f | sort` as the
first RUN instruction. Review the output in `--progress=plain`. Remove
after debugging. Also: verify context size with `docker build . 2>&1
| head -3` - if context is unexpectedly large, `.dockerignore` is
likely missing important exclusions.

*What separates good from great:* `.dockerignore` negation rules.
The `!` prefix includes files that a previous rule excluded. Order
matters - rules apply sequentially. Example: `node_modules` excludes
all of node_modules. `!node_modules/.bin` then re-includes only
the .bin subdirectory. Use this to include specific files from
otherwise excluded directories without exposing the entire directory.
This is especially useful for monorepos where you want to exclude
most of the repository from the build context but include specific
subdirectories. Check context size before and after `.dockerignore`
changes with `docker build . 2>&1 | grep "Sending build context"`.

---

**Q6 (behavioral): Describe a time you debugged a Docker build failure
that turned out to be a platform or architecture issue.**

A: Structure this answer using the STAR method. Situation: a
microservice built and tested on an M1 MacBook Pro failed identically
every time in CI (AMD64 Linux runners). Task: diagnose why the
same Dockerfile produced different results on different machines.
Action: (1) Compared `docker inspect` architecture output: local
image showed `arm64`, CI image showed `amd64`. (2) Ran
`docker buildx build --platform linux/amd64 --no-cache .` locally
to simulate CI. Same failure: "libssl.so.1.1: cannot open shared
object file." (3) Inspected the base image: `alpine:3` resolved to
Alpine 3.17 on the ARM Mac (the most recent arm64 build). On AMD64
CI: resolved to Alpine 3.16 (the most recent amd64 build at the
time). Different Alpine versions, different libssl versions. (4)
Fixed by pinning the base image to a multi-arch manifest digest:
`FROM alpine:3.18@sha256:<multi-arch-digest>`. Verified with
`docker manifest inspect alpine:3.18` that both architectures
map to the same Alpine version. Result: build and tests pass on
both architectures. Lesson: floating tags (`:3`, `:latest`) without
digest pinning are architecture-unsafe in multi-architecture teams.

*What separates good from great:* Building multi-architecture images
in CI as a gate. `docker buildx bake --platform linux/amd64,linux/arm64`
builds both in parallel (native runners) or sequentially (QEMU).
A build that fails on one platform is caught before deployment.
GitHub Actions ARM64 runners (available since 2024) eliminate QEMU
emulation overhead for native ARM builds. The strategic answer:
treat multi-arch build success as a CI requirement for any team
that uses Apple Silicon developer machines with AMD64 production
deployments.

---

**Q7 (security): A developer baked an API key into a Docker image layer.
The key is no longer in the current image but was in a previous build.
What is the risk and how is it mitigated?**

A: Docker image layers are immutable filesystem snapshots. A secret
in any previous layer - even if a later layer deletes the file - is
permanently in that layer. `docker save myimage > image.tar` then
`tar xf image.tar`: extract all layers. `strings layer.tar | grep -i api_key`
finds the secret. `docker history myimage --no-trunc | grep -i key`
may show the value if it was in a `RUN` or `ARG` instruction. Risk:
anyone with registry pull access can extract the secret. Mitigation:
(1) **Rotate the secret immediately** - this is non-negotiable and
supersedes all other steps. (2) Remove the image from the registry
(tag AND digest): `aws ecr batch-delete-image --image-ids
imageDigest=sha256:...`. (3) Audit CI logs for the key's usage.
(4) Rebuild correctly using BuildKit secrets:
`RUN --mount=type=secret,id=api_key API_KEY=$(cat /run/secrets/api_key)
&& build-command`. The secret mount exists only during that RUN
instruction - not in the layer, not in docker history.

*What separates good from great:* Preventive controls: (1)
`detect-secrets` (Yelp) as a pre-commit hook scans staged files.
(2) `trivy image --security-checks secret myapp:latest` scans ALL
layers for secrets - integrate into CI as a blocking gate. (3)
ECR, GCR, and GitHub Container Registry offer secret scanning in
the registry itself. (4) SBOM generation at build time: tracks
exactly what is in each layer for incident response. Most engineers
implement detection. Great engineers implement prevention +
detection + response automation.

---

**Q8 (debugging): A BuildKit build hangs indefinitely with no progress
output. How do you diagnose and resolve this?**

A: Categorized by phase. (1) **During context upload**: hangs before
any output. Context is too large. Check: `docker build . 2>&1 | head -3`.
If "Sending build context: 5GB": add `node_modules/`, `.git/`, `dist/`
to `.dockerignore`. (2) **During base image pull**: hangs with
"Pulling from ...". Docker Hub rate limit causes silent queuing.
Solution: `docker login` then retry. (3) **During a RUN instruction**:
the `RUN` command waits for interactive input. `apt-get install libssl-dev`
without `-y` waits for user confirmation [Y/n]. Docker build has no
TTY: waits forever. Fix: always use `-y` for apt-get.
(4) **BuildKit daemon stuck or disk full**: `docker system df` shows
build cache usage. If full: `docker builder prune --force`. Restart:
`docker buildx rm default && docker buildx create --use`.
(5) **Network during RUN**: `RUN curl` reaches an unreachable host.
Default TCP timeout: 15 minutes. Add explicit timeouts:
`RUN curl --connect-timeout 5 --max-time 30 ...`.

*What separates good from great:* `--progress=rawjson` for monitoring.
Raw JSON includes `vertexStatus` events showing the exact instruction
executing. In CI: `timeout 600 docker buildx build --progress=rawjson .
2>&1 | tee build.json`. If timeout triggers: parse `build.json` to
identify the last active instruction. `--build-arg
BUILDKIT_STEP_LOG_MAX_SIZE=104857600` removes BuildKit's 64KB per-step
log truncation (critical when a failing RUN produces > 64KB output
and the error is at the end).

---

**Q9 (system): You must reduce Docker build failure rates from 15% to under
2% in a CI/CD system with 1,000 builds/day. What systematic changes do you make?**

A: Measure first, fix by category. (1) **Build failure taxonomy**:
parse CI logs, categorize each failure: registry connectivity, package
resolution, test failure, permission error, platform mismatch, timeout,
cache corruption. Track frequency per category. Start with the highest
frequency. (2) **Registry reliability** (typically #1 cause): deploy
a pull-through cache for Docker Hub (Harbor, ECR Public Gallery mirror,
or Nexus). Prefetch base images nightly. Rate limit errors disappear.
(3) **Dependency pinning**: enforce lockfiles in CI (`npm ci`,
`pip install --require-hashes`). Vendor critical build tools into the
base image. Reduces network-dependent transient failures significantly.
(4) **Build timeout standardization**: set per-step timeouts. A hanging
RUN fails after 5 minutes with a useful error, not after 60 minutes
blocking a runner. (5) **Cache mount optimization**: faster builds
means fewer timeout failures. (6) **Platform standardization**: enforce
`FROM ... @sha256:digest` in all Dockerfiles via CI lint. (7)
**Failure alerting**: P90 build time > 10 minutes triggers a Slack
alert. Single automatic retry for registry-connectivity failures.

*What separates good from great:* Build failure rate as a developer
productivity metric. 15% on 1,000 builds/day = 150 failures/day.
Each failure: 15-30 minutes of developer investigation + retry. That
is 37-75 hours of lost productivity per day across the team. Calculating
this cost justifies significant infrastructure investment (dedicated
build runners, registry replication, monitoring dashboards). Track
failure rate by category and by service: surfaces ownership. "Service
X has a 40% failure rate vs team average of 3%: that service needs
targeted remediation."

---

**Q10 (debugging): A `COPY --from=builder` fails with "file does not exist".
The file clearly exists in the builder stage when run manually. What are the causes?**

A: Five causes. (1) **Stage name case mismatch**: `FROM ... AS Builder`
(capital B) and `COPY --from=builder` (lowercase). Stage names are
case-sensitive. Fix: use consistent lowercase. (2) **Wrong stage number**:
`--from=0` references stage 0. A new `FROM` inserted at the top shifts
all stage numbers. Prefer named stages: `--from=builder`. (3) **Build
command silently failed (exit 0)**: `./gradlew build` catches exceptions
and exits 0 when the build fails. `build/libs/app.jar` is never
created. The `COPY --from=builder build/libs/app.jar .` fails. Fix:
`RUN ./gradlew build && test -f build/libs/app.jar`. The `test -f`
assertion makes the contract explicit. (4) **WORKDIR mismatch**: file
is at `/app/build/` but `COPY --from=builder build/ .` looks for `build/`
relative to the last WORKDIR. Use absolute paths: `COPY --from=builder
/app/build/libs/app.jar ./app.jar`. (5) **Multi-platform build**:
different architectures may produce artifacts in different paths.
`--platform linux/amd64` vs default may cause path differences.
Verify artifact path per platform.

*What separates good from great:* Contract-driven multi-stage builds.
Use `RUN test -f /app/artifact.jar` as the last instruction in
the builder stage. This is an explicit contract: if the artifact
doesn't exist, the builder stage fails with a clear error.
Additionally: `RUN sha256sum /app/artifact.jar > /app/artifact.jar.sha256`
then verify in the runtime stage: `RUN sha256sum -c /app/artifact.jar.sha256`.
This prevents a silent partial build (Gradle exits 0 but JAR is
incomplete) from reaching production.

---

**Q11 (trade-off): When is DOCKER_BUILDKIT=0 (legacy builder) appropriate
vs BuildKit in production builds?**

A: Legacy builder is appropriate only for: (1) compatibility debugging
when isolating a BuildKit-specific bug; (2) Docker versions older than
20.10 where BuildKit is not the default. In all other cases: BuildKit
is superior. BuildKit advantages: parallel stage execution (faster
multi-stage builds), build secrets (never in image layers), cache
mounts (dramatically faster dependency builds), SSH agent forwarding,
per-instruction `--network=none` (security isolation), and multi-platform
builds. The only scenario where legacy is "safer": a Dockerfile with
a `# syntax=...` directive incompatible with the installed BuildKit
version - resolve by updating the syntax reference, not by disabling
BuildKit. Production recommendation: always use BuildKit. Enable
system-wide: `/etc/docker/daemon.json: {"features": {"buildkit": true}}`.
Not needed for Docker 23+ (BuildKit is the default).

*What separates good from great:* BuildKit's distributed registry
caching is a team-wide operational advantage. `--cache-from
type=registry` and `--cache-to type=registry,mode=max`: share build
cache across all CI runners via the registry. Legacy builder: machine-local
cache only. For a team with 20 CI runners: BuildKit distributed cache
means any layer rebuilt by one runner is immediately available to all
others. This reduces P50 build time from 4 minutes (cold) to 20
seconds (cached) for slow dependency layers. Cannot be achieved with
the legacy builder.

---

**Q12 (production): How do you implement comprehensive Docker build
monitoring in a production CI/CD system?**

A: Build monitoring in layers. (1) **Build time tracking**: total build
time and per-layer time from `--progress=rawjson` output. Store in
time-series. Alert when P90 build time increases > 20% week-over-week.
(2) **Failure rate by category**: registry, package, timeout, permission,
platform. Track per-service and system-wide. (3) **Cache hit rate**:
BuildKit raw JSON output includes cache hit/miss per step. Cache miss
on `npm ci` while lockfile hasn't changed: indicates cache eviction
(disk pressure on build runner). (4) **Image size tracking**:
`docker image inspect --format '{{.Size}}'`. Alert when size increases
> 10MB (unintended layer added). (5) **Vulnerability count**: Trivy
scan on every build. Track CRITICAL/HIGH/MEDIUM counts. Block
deployment when CRITICAL count > 0. (6) **Base image freshness**:
alert when digest is > 30 days old (security patches available).
(7) **Build queue depth**: queue > N indicates insufficient runner
capacity. (8) **Runner disk usage**: alert when build cache > 80% of
disk. Schedule: `docker builder prune --keep-storage 20GB --filter
until=24h`.

*What separates good from great:* Correlating build metrics with
deployment outcomes. High build failure rate -> lower deployment
frequency -> larger batch sizes -> higher rollback rates. Presenting
this chain to leadership: "Our 15% build failure rate reduces deployment
frequency by ~20%, increasing average batch size, increasing our
rollback rate from 3% to 12%." This is the business case for build
reliability investment. Tracking mean time to recovery (MTTR) for
build failures separately from MTTR for deployment failures enables
precise attribution and prioritization. Most engineers track failure
counts. Great engineers connect infrastructure metrics to business
outcomes.

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




