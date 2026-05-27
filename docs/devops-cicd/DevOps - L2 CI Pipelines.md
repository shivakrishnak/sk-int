---
layout: default
title: "DevOps - L2 CI Pipelines"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 3
permalink: /devops-cicd/l2-ci-pipelines/
---

# GitHub Actions Pipeline Design

🎯 Interview Weight: very high - GitHub Actions is the dominant
CI/CD platform for most organizations.

---

### 🎯 Model Answer

**30 seconds:**
> GitHub Actions: event-driven CI/CD defined in `.github/workflows/`.
> Key concepts: workflow (YAML file), trigger (push, PR, schedule,
> manual), jobs (parallel or sequential), steps (individual commands),
> runners (GitHub-hosted or self-hosted). Secrets stored in GitHub
> Secrets. Reusable workflows for shared pipeline components.
> Composite actions for reusable step sets.

**3 minutes (Senior):**
> GitHub Actions design patterns:
>
> Trigger configuration:
> `on: push: branches: [main]`: CI on every main push.
> `on: pull_request: branches: [main]`: PR validation.
> `on: workflow_dispatch:`: manual trigger with inputs.
> `on: schedule: cron: '0 2 * * *'`: nightly runs.
>
> Job dependencies:
> `needs: [build, test]`: job only runs after both succeed.
> `if: failure()`: run cleanup job even on failure.
>
> Matrix builds:
> Run tests across multiple Java versions or OS:
> `matrix: java: [17, 21]` -> 2 parallel test jobs.
> Strategy: `fail-fast: false` - don't cancel other jobs
> when one fails (useful for compatibility matrix).
>
> Reusable workflows:
> `.github/workflows/build.yml` with `on: workflow_call`.
> Called from other workflows: `uses: ./.github/workflows/build.yml`.
> Centralizes pipeline logic, reduces duplication.
>
> Security best practices:
> Pin actions to a commit hash (not tag): prevents supply
> chain attacks if a tag is moved.
> `uses: actions/checkout@v4` -> SHA: `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`
> Minimal permissions: `permissions: contents: read`.
> Avoid storing secrets in environment variables if possible;
> use OIDC token exchange (GitHub -> AWS/GCP without static keys).

**Blank Mind Recovery:**

**(1) Restate:** "GitHub Actions: YAML workflows with jobs and steps.
Matrix builds for multi-version. Pin actions to SHA for supply chain security."

---

### 💻 Code Example

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  packages: write      # For Docker push to GHCR

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Setup Java 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: 'maven'   # Cache ~/.m2/repository

      - name: Build and Test
        run: mvn -B clean verify
        env:
          SPRING_PROFILES_ACTIVE: ci

      - name: Upload coverage to Codecov
        if: always()
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  docker-build:
    runs-on: ubuntu-latest
    needs: build-and-test          # Only run if tests pass
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Docker build and push
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.sha }}
            ghcr.io/${{ github.repository }}:latest
          cache-from: |
            type=gha
          cache-to: |
            type=gha,mode=max
```

> **Code walkthrough:** The workflow triggers on push to main
> and PRs. Permissions are minimal (read for code, write only
> for package push). The `cache: 'maven'` caches the local
> Maven repository between runs. Docker build runs only on
> the main branch (not on PRs) to avoid unnecessary registry pushes.
> The action hashes (SHA pinning) prevent supply chain attacks
> where an attacker moves a tag to malicious code.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Workflow structure + job dependencies |
| Senior | 8 min | Matrix builds + reusable workflows + OIDC security |
| Staff | 12 min | Self-hosted runners + supply chain security |

---

---

# Jenkins Pipeline as Code

🎯 Interview Weight: medium-high - Jenkins is still prevalent
in large enterprises. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Jenkins Pipeline as Code: Jenkinsfile defines the pipeline
> using Declarative (recommended) or Scripted pipeline syntax.
> Pipeline stages: checkout, build, test, push, deploy.
> Jenkins shared libraries: reusable pipeline code across projects.
> Blue Ocean (deprecated) or new Jenkins UI for pipeline visualization.
> Key advantage over GitHub Actions: runs on-premises, behind
> corporate firewall, custom agents.

**3 minutes (Senior):**
> Jenkinsfile declarative pipeline:
>
> Declarative syntax: `pipeline { agent {} stages {} }`.
> Strongly typed, easier to validate.
> `agent any`: run on any available agent.
> `agent { docker { image 'maven:3.9-eclipse-temurin-21' } }`:
> run inside a Docker container (clean environment per build).
>
> Shared libraries:
> `@Library('my-pipeline-lib@main') _` at top of Jenkinsfile.
> Library: Groovy code in `vars/` (global variables) and
> `src/` (utility classes) in a separate repo.
> Centralizes: deployment logic, notifications, quality checks.
> Prevents copy-paste of pipeline code across 50 repos.
>
> Jenkins credential management:
> `withCredentials([usernamePassword(credentialsId: 'db-creds',
> usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')]) {}`
> Credentials bound only inside the block, masked in logs.
>
> Jenkins vs GitHub Actions:
> Jenkins: self-hosted, highly customizable, mature plugin ecosystem.
> Build queue, distributed builds, complex pipelines.
> GitHub Actions: cloud-native, simpler YAML, tight GitHub integration.
> Less flexible but less operational overhead.
> Migration path: many enterprises migrating from Jenkins to
> GitHub Actions or GitLab CI for simpler maintenance.

**Blank Mind Recovery:**

**(1) Restate:** "Jenkinsfile: declarative pipeline in code.
Shared libraries = reusable pipeline code. Docker agent = clean builds."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Declarative pipeline structure |
| Senior | 7 min | Shared libraries + Docker agents + credentials |

---

---

# Automated Testing in CI

🎯 Interview Weight: very high - Testing in CI is the primary
quality gate in modern software delivery.

---

### 🎯 Model Answer

**30 seconds:**
> Automated testing in CI: unit tests (fast, no external
> dependencies, run on every commit), integration tests
> (require DB, Kafka, etc. - use Testcontainers or in-memory
> alternatives), E2E tests (full stack, slower, run less
> frequently). Testing pyramid: many unit tests, fewer
> integration tests, few E2E tests. Test coverage: maintain
> or increase, fail CI on significant drop.

**3 minutes (Senior):**
> Testing in CI - practical patterns:
>
> Testcontainers in integration tests:
> `@Container PostgreSQLContainer postgres = new PostgreSQLContainer(...)`
> Real PostgreSQL in a Docker container, started per test class.
> No mocking DB behavior. Tests use the real DB engine.
> CI requirement: Docker daemon available on CI runner.
> GitHub Actions: `services: postgres: image: postgres:16` is
> an alternative (Docker service containers).
>
> Test parallelization:
> JUnit 5: `@Execution(CONCURRENT)` class-level parallel execution.
> Maven Surefire: `<forkCount>4</forkCount>` - 4 JVM processes.
> 40 integration tests, each 3 seconds: sequential = 120s,
> parallel (4 workers) = 30s.
> Caveat: parallel tests must be isolated (different DB schemas
> or containers per test).
>
> Test reliability - no flaky tests policy:
> Track test failure rate per test in a CI dashboard.
> Test fails >2% of runs = flaky. Quarantine immediately.
> Quarantine: `@Disabled("FLAKY-123: race condition in timer test")`
> Fix within 2 days or delete.
>
> Code coverage thresholds:
> JaCoCo plugin: `<minimumLineCoverage>70</minimumLineCoverage>`.
> Fail CI if coverage drops below 70%.
> Better: Codecov ratchet - fail CI if PR reduces coverage
> (not absolute threshold).
>
> Consumer-driven contract tests:
> Pact: API consumer defines expected request/response contracts.
> Provider CI verifies contracts on every build.
> Prevents breaking API changes from reaching production.

**Blank Mind Recovery:**

**(1) Restate:** "Testing pyramid: unit > integration > E2E.
Testcontainers for real DB. Parallel tests. No flaky tests policy."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Test pyramid + Testcontainers |
| Senior | 8 min | Contract tests + parallelization + flaky test policy |

---

---

# Code Quality Gates and Static Analysis

🎯 Interview Weight: high - Quality gates enforce engineering
standards consistently.

---

### 🎯 Model Answer

**30 seconds:**
> Code quality gates: automated checks that block merging or
> deployment if quality thresholds are not met. Tools: SonarQube
> (code smells, duplication, coverage), Checkstyle (code style),
> SpotBugs (bug patterns), PMD (static analysis), OWASP Dependency-Check
> (vulnerability scan). Quality gates make standards objective and
> automated instead of relying on reviewer memory.

**3 minutes (Senior):**
> Quality gate configuration:
>
> SonarQube quality gate (example "Sonar Way"):
> - Code coverage: new code >= 80%
> - Duplicated lines on new code: < 3%
> - Reliability rating on new code: A
> - Security rating on new code: A
> - Maintainability rating on new code: A
> Fail CI if any condition fails.
>
> Checkstyle:
> Enforces Google Java Style or custom team style guide.
> Max line length, naming conventions, import order.
> CI fails on violations. Developers run locally before pushing:
> `mvn checkstyle:check` or IDE Checkstyle plugin.
>
> SpotBugs patterns to catch:
> Null pointer dereference potential.
> SQL injection via string concatenation (not prepared statements).
> Infinite loop risk.
> Resource leak (streams not closed in finally block).
>
> Incremental analysis:
> Run quality checks only on changed files in PRs.
> Full analysis on main branch (slower, more thorough).
> Prevents PRs taking 10 minutes to check unchanged code.
>
> Suppression - anti-pattern:
> `@SuppressWarnings("SpotBugs")` to silence a rule without fixing it.
> Policy: suppressions require a comment explaining why and
> a ticket to fix. Code review must explicitly approve suppressions.

**Blank Mind Recovery:**

**(1) Restate:** "Quality gates: block merge on code quality failures.
SonarQube + Checkstyle + SpotBugs + OWASP vulnerability scan."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Quality gate tools + SonarQube |
| Senior | 7 min | Custom quality gates + incremental analysis + suppression policy |

---

---

# Build Caching and Optimization

🎯 Interview Weight: medium-high - Build speed directly impacts
developer feedback loops and CI costs.

---

### 🎯 Model Answer

**30 seconds:**
> Build caching: reuse artifacts from previous builds to avoid
> redundant work. Cache levels: dependency cache (Maven/Gradle),
> Docker layer cache (BuildKit), test result cache (Gradle build
> cache). Goal: CI feedback in < 5 minutes. Key optimization:
> fail fast (cheapest checks first), parallelize independent jobs,
> use the right runner size (faster CPU = faster Java compilation).

**3 minutes (Senior):**
> Build optimization techniques:
>
> Maven dependency cache:
> GitHub Actions: `cache: 'maven'` key = hash of `pom.xml`.
> Cache hits: download time 5 min -> 5 seconds.
> Cache invalidation: any `pom.xml` change = full re-download.
> CI cost: cached builds use far less network bandwidth.
>
> Docker layer cache (BuildKit):
> Dockerfile layers cached by content hash.
> Key optimization: copy `pom.xml` first, run `mvn dependency:go-offline`
> (download all deps), THEN copy source code.
> Result: source code changes only invalidate the final layer.
> The dependency layer (biggest) is cached.
>
> ```dockerfile
> # Optimized multi-stage Dockerfile for caching
> FROM maven:3.9-eclipse-temurin-21 AS build
>
> WORKDIR /app
>
> # Cache dependencies separately from source
> COPY pom.xml .
> RUN mvn dependency:go-offline -B
>
> # Now copy source (only this layer changes on code change)
> COPY src ./src
> RUN mvn package -DskipTests -B
>
> FROM eclipse-temurin:21-jre
> COPY --from=build /app/target/*.jar app.jar
> ENTRYPOINT ["java", "-jar", "app.jar"]
> ```
>
> Gradle build cache:
> Task-level caching: if inputs haven't changed, reuse output.
> Remote cache: share across all CI agents.
> Cache key: hash of task inputs (source files, config).
>
> Parallel jobs in GitHub Actions:
> Split test suite into N shards.
> Run each shard in a separate job (parallel).
> `test-shard-1`: tests 1-25, `test-shard-2`: tests 26-50.
> Total time: 10 minutes / 4 shards = 2.5 minutes.

**Blank Mind Recovery:**

**(1) Restate:** "Caching: Maven deps, Docker layers, Gradle task output.
Parallelize test shards. Target: CI < 5 minutes."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Maven cache + Docker layer cache |
| Senior | 7 min | Gradle build cache + parallel job sharding |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | GitHub Actions structure + test automation |
| Platform/DevOps | Build optimization + quality gates |
| Bar Raiser | Supply chain security + contract testing |
