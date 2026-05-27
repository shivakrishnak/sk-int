---
layout: default
title: "DevOps - L1 Foundations"
parent: "DevOps and CI/CD"
grand_parent: "SK Interview"
nav_order: 2
permalink: /devops-cicd/l1-foundations/
---

# Git Branching Strategies

🎯 Interview Weight: high - Git workflow choices directly
impact CI/CD velocity.

---

### 🎯 Model Answer

**30 seconds:**
> Git branching strategies: Trunk-Based Development (TBD) -
> everyone commits to main, feature flags hide incomplete work,
> best for high-frequency deployment. Gitflow - develop + release
> branches, for scheduled releases or multi-version products.
> GitHub Flow - feature branches + PR + merge to main + deploy,
> simple and effective for most teams. DORA research recommends
> TBD: correlated with elite performance in all four metrics.

**3 minutes (Senior):**
> Choosing the right strategy:
>
> TBD criteria:
> Team deploys multiple times per day.
> Feature flags infrastructure available (LaunchDarkly, Unleash).
> Team has > 5 developers with strong test coverage.
> CI takes < 10 minutes.
>
> Gitflow criteria:
> Software has multiple supported versions in production simultaneously.
> Releases are scheduled (quarterly, monthly) not continuous.
> Compliance requires release branches for audit purposes.
>
> Feature branch best practices (GitHub Flow / TBD):
> Branch lifetime < 2 days. Long-lived branches = merge conflicts
> and delayed integration.
> PR must: pass CI, have code coverage maintained or improved,
> be peer-reviewed by at least 1 other engineer.
> Squash-merge: keeps main history clean (one commit per feature).
> Merge commit: preserves full development history.
> Rebase: linear history without merge commits.
>
> Commit message convention:
> Conventional commits: `feat: add payment processing`,
> `fix: handle null pointer in order service`,
> `chore: upgrade spring boot to 3.2`.
> Machine-readable: enables automated semantic versioning,
> auto-generated CHANGELOG, and release note generation.
>
> Protected branches:
> `main` branch: require PR + CI pass + 1 reviewer approval.
> No direct push. Prevents accidental force pushes to production.
> CODEOWNERS: specific paths require specific reviewers
> (security team reviews security config changes).

**Blank Mind Recovery:**

**(1) Restate:** "TBD: commit to main daily + feature flags.
Gitflow: scheduled releases. GitHub Flow: PR + merge. < 2 day branches."

---

### 💻 Code Example

```yaml
# GitHub branch protection rules (via GitHub API or Terraform)
branches:
  main:
    protection:
      required_status_checks:
        strict: true
        contexts:
          - "CI / build-and-test"
          - "Security / dependency-scan"
      required_pull_request_reviews:
        required_approving_review_count: 1
        dismiss_stale_reviews: true
        require_code_owner_reviews: true
      enforce_admins: true
      restrictions: null  # No push restrictions (PR required)
```

> **Code walkthrough:** This branch protection configuration
> requires CI to pass (build, test, security scan) before a PR
> can be merged. One approving review is mandatory. `dismiss_stale_reviews`
> ensures reviews are invalidated when new commits are pushed
> (preventing stale approvals from overriding recent changes).
> `require_code_owner_reviews` routes reviews to the right
> experts based on path patterns in CODEOWNERS.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | TBD vs Gitflow + branch protection |
| Senior | 7 min | Feature flags + conventional commits + CODEOWNERS |

---

---

# CI Pipeline Fundamentals

🎯 Interview Weight: very high - CI pipeline design is a daily
engineering activity at most companies.

---

### 🎯 Model Answer

**30 seconds:**
> CI pipeline fundamentals: triggered on every commit or PR,
> runs in order: build -> test -> analyze -> package -> optionally deploy.
> Must be fast (< 10 minutes for PR feedback), reliable (no flaky tests),
> and reproducible (same code = same outcome). Key principle: fail fast -
> run cheapest checks first (compile, unit test) before expensive ones
> (integration tests, security scans).

**3 minutes (Senior):**
> CI pipeline design patterns:
>
> Fail-fast ordering:
> 1. Compile / syntax check (seconds).
> 2. Unit tests (1-3 minutes).
> 3. Static analysis (1-2 minutes, parallel with unit tests).
> 4. Integration tests (3-10 minutes).
> 5. Build Docker image (30 seconds - 3 minutes).
> 6. Container security scan (1-2 minutes).
> Skip expensive steps on compile failure.
>
> Test reliability:
> Flaky tests are the enemy of CI trust.
> Flaky test: passes 95% of the time, fails 5% randomly.
> If 100 tests each 5% flaky: CI fails 99.4% of the time.
> Fix: quarantine flaky tests, fix within 2 days, or delete.
> Track flaky tests in a dashboard (test failure by test name).
>
> Parallelization:
> Shard test suite: `--parallel=4` (4 JVM processes, each
> runs 25% of tests simultaneously). Reduce unit test time
> from 8 minutes to 2 minutes.
> Run unit tests and static analysis in parallel.
> Multi-arch Docker builds in parallel (amd64 + arm64).
>
> Artifact caching:
> Maven/Gradle dependency cache: cache `.m2` or `.gradle`
> between pipeline runs. Save 2-5 minutes on dependency download.
> Docker layer cache: use BuildKit `--cache-from` to reuse
> unchanged image layers. Save 1-3 minutes on image build.
>
> Pipeline secrets:
> NEVER log secrets. NEVER echo environment variables.
> Use CI platform secret management (GitHub Secrets, GitLab
> CI Variables, Jenkins credentials). Rotate regularly.

**Blank Mind Recovery:**

**(1) Restate:** "CI: fail fast, parallelize, cache, no flaky tests.
Cheap checks first. Secrets in CI vault, not in code."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | CI stage ordering + parallelization |
| Senior | 7 min | Flaky test management + Docker layer caching |

---

---

# Artifact Management and Versioning

🎯 Interview Weight: medium-high - Artifact management is a
production CI/CD requirement.

---

### 🎯 Model Answer

**30 seconds:**
> Artifact management: CI builds immutable, versioned artifacts
> (Docker images, JARs) stored in an artifact registry.
> Versioning: semantic versioning (MAJOR.MINOR.PATCH) for
> libraries, or Git SHA + build number for services.
> Immutability: once published, an artifact version never
> changes. Docker image `my-service:abc123def` contains
> exactly the code at that Git commit. This ensures what
> was tested = what was deployed.

**3 minutes (Senior):**
> Artifact lifecycle:
>
> Build: CI compiles, tests, packages -> Docker image + JAR.
> Tagging strategy:
> `my-service:latest` (anti-pattern: not immutable).
> `my-service:1.2.3` (semantic version).
> `my-service:main-abc1234` (branch + git sha - recommended for services).
> `my-service:20240115-1042-abc1234` (date + build number + sha).
>
> Registry:
> Docker Hub: public images. Don't push proprietary images here.
> AWS ECR, GCP Artifact Registry, GitLab Registry: private, integrated
> with cloud IAM.
> Harbor: self-hosted, OSS, Helm charts + Docker images + vulnerability scanning.
>
> Semantic versioning for libraries:
> MAJOR: breaking API change (consumers must update their code).
> MINOR: new backward-compatible feature.
> PATCH: bug fix, backward compatible.
> Pre-release: `1.0.0-SNAPSHOT` (Maven), `1.0.0-beta.1`.
>
> Artifact retention policies:
> Keep: all release versions (forever or 1 year).
> Keep: last 10 builds of main branch.
> Delete: PR builds after 7 days.
> Disk space matters: 1000 Docker images * 200MB = 200GB.

**Blank Mind Recovery:**

**(1) Restate:** "Artifacts: immutable, versioned, stored in registry.
Tag by git SHA for services, semver for libraries. Never use `latest` in prod."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | Artifact types + versioning strategies |
| Senior | 6 min | Registry options + retention + immutability principle |

---

---

# Environment Configuration Management

🎯 Interview Weight: high - Configuration management is the
backbone of safe multi-environment deployments.

---

### 🎯 Model Answer

**30 seconds:**
> Configuration management: application config should be separated
> from the artifact and injected at deploy time (12-factor app,
> factor III). Config types: non-sensitive (database host, feature
> flags, timeout values) in ConfigMaps or environment variables;
> sensitive (passwords, API keys, certificates) in Vault, AWS
> Secrets Manager, or Kubernetes Secrets. Config must be version-controlled,
> reviewed, and environment-specific without duplicating the artifact.

**3 minutes (Senior):**
> Configuration management patterns:
>
> 12-factor app config rule:
> Config = anything that varies between environments.
> DB URL differs between staging and production.
> Log level: DEBUG in staging, INFO in production.
> API keys: test keys in staging, real keys in production.
> All config from environment variables or injected files.
> Never in code or baked into the Docker image.
>
> Kubernetes ConfigMap:
> Non-sensitive config as key-value pairs.
> Mounted as environment variables or volume (config files).
> Updated without rebuilding the image.
> Pitfall: ConfigMap changes do not auto-restart pods.
> Requires rolling restart: `kubectl rollout restart deployment`.
>
> Vault (HashiCorp Vault):
> Secrets with dynamic generation (short-lived DB credentials).
> Vault Agent: sidecar that fetches and refreshes secrets into
> the pod's file system. App reads from file.
> Vault with Kubernetes: `vault auth method kubernetes` -
> pod's ServiceAccount token authorizes Vault access.
> Rotation: DB credentials can be rotated every hour.
> App gets a new password from Vault at each rotation.
>
> External Secrets Operator (ESO):
> Syncs secrets from AWS Secrets Manager / Vault / GCP to
> Kubernetes Secrets automatically.
> SecretStore CR defines the source.
> ExternalSecret CR defines what to fetch and where to put it.
> Config repo: contains ExternalSecret YAML (safe to commit).
> The actual secret value never enters the config repo.

**Blank Mind Recovery:**

**(1) Restate:** "Config: separated from artifact, environment-specific,
injected at deploy. Sensitive config in Vault or AWS Secrets Manager."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | 12-factor app config + ConfigMap vs Secrets |
| Senior | 7 min | Vault dynamic secrets + External Secrets Operator |

---

---

# Build Tools in CI (Maven and Gradle)

🎯 Interview Weight: medium - Build tool proficiency is a
day-to-day Java engineering skill.

---

### 🎯 Model Answer

**30 seconds:**
> Maven: XML-based, convention over configuration, standardized
> lifecycle (validate, compile, test, package, verify, install, deploy).
> Strong ecosystem (Maven Central). Verbose but predictable.
> Gradle: Groovy/Kotlin DSL, flexible, incremental builds
> (only rebuild changed modules), faster than Maven for multi-module
> projects. Used by Android, Gradle Enterprise at scale.
> Spring Boot: supports both. New Spring Boot projects often use
> Gradle. Older enterprise projects use Maven.

**3 minutes (Senior):**
> Build optimization in CI:
>
> Maven caching:
> Cache `~/.m2/repository` between CI runs.
> GitHub Actions: `cache: 'maven'` with key based on `pom.xml` hash.
> Dependency download: 5 minutes -> 30 seconds with cache.
> Parallel builds: `mvn -T 4 clean install` (4 threads).
> Build daemon: `mvn -o` (offline mode after first download).
>
> Gradle caching:
> Gradle build cache: caches task output hashes.
> If source inputs haven't changed: reuse cached task output.
> Gradle configuration cache (beta): skip configuration phase
> on re-runs if build scripts haven't changed.
> Remote build cache: share cache across developer machines
> and CI (Gradle Enterprise). Output from a colleague's build
> reused in your CI run.
>
> Maven wrapper vs Gradle wrapper:
> `./mvnw` / `./gradlew`: ensure correct build tool version
> is used by all developers and CI.
> Version pinned in `maven-wrapper.properties` or
> `gradle-wrapper.properties`. No "works on my machine"
> build tool version issues.
>
> Dependency vulnerability scanning:
> Maven: `org.owasp:dependency-check-maven` plugin.
> Gradle: `dependencyCheck` plugin.
> Scan: checks all dependencies against NVD/CVE database.
> Fail build if CVSS score > 7 (configurable threshold).

**Blank Mind Recovery:**

**(1) Restate:** "Maven: XML + standardized lifecycle. Gradle: DSL +
incremental builds + faster for multi-module. Both need wrapper + caching in CI."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | Maven vs Gradle differences + wrapper |
| Senior | 6 min | Incremental builds + dependency caching + vulnerability scanning |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | CI pipeline design + branching strategy |
| Platform/DevOps | Configuration management + Vault |
| Bar Raiser | Artifact immutability + build optimization |
