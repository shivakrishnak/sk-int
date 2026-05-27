# Contributing to SK Interview

Thanks for your interest. This repo houses an interview-focused technical reference; every keyword entry must reach **masterclass quality** (see `spec/interview_content_generator.md` Section 6). This guide explains how to add content cleanly.

## Prerequisites

- Ruby 3.3+ and Bundler (`gem install bundler`)
- PowerShell 7+ (`pwsh`, never `powershell.exe`)
- Git
- VS Code with the GitHub Copilot Chat extension

## One-time setup

```pwsh
git clone https://github.com/shivakrishnak/sk-int
cd sk-int
bundle install
git config core.hooksPath .githooks
```

## Adding a new topic

The fastest path is through the `/interview` agent in Copilot Chat:

1. Open the workspace in VS Code.
2. In Copilot Chat: `/interview new topic: <Name>` (e.g. `Angular`, `Go`, `Rust`).
3. The agent will:
   - Generate the keyword list covering all knowledge levels (L0-L6 + META)
   - Group keywords into files of 3-5 keywords each
   - Create `docs/<topic>/` with `index.md` and subtopic files
   - Generate full v1.0 content per keyword in batches
4. Review the diff, then commit in batches of **5 created files**.

Manual path (without the agent):

```pwsh
# 1. Scaffold topic skeleton from a dictionary category or keyword list
pwsh -File scripts/generate_topics.ps1 -Topic "Angular"

# 2. Generate content
pwsh -File scripts/generate_content.ps1 -Mode topic -Topic "Angular"
```

See [spec/topics_registry.md](spec/topics_registry.md) for the topic registry and [spec/interview_content_generator.md](spec/interview_content_generator.md) for the full generation spec.

## Style rules (enforced)

These are non-negotiable. The pre-commit hook and CI workflows check them.

- **No em dashes** anywhere - use regular hyphens
- **Code lines max 70 characters**
- **ASCII diagrams max 59 characters wide**
- **Diagrams in DUAL format**: ASCII first (universal fallback), Mermaid below
- **BAD pattern before GOOD pattern** in every code example
- **UTF-8 without BOM**, LF line endings (except `.ps1`)
- **Markdown links**, never raw URLs in prose
- **Bold-label lines** (`**LABEL:** value`) separated by blank lines
- See [.markdownlint.json](.markdownlint.json) for automated rules

## Commit conventions

- **Conventional commits** (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`)
- **Batch of 5 created files** per commit (never single files)
- Only commit files that were **created** (not just modified)
- **Do not `git push`** without review

Example:

```
feat: add interview Angular - batch 1 (Foundations, Components, Directives, Routing, Forms)
```

## Pull request checklist

- [ ] `bundle exec jekyll build` passes
      (or `bundle exec jekyll build --baseurl /sk-int` for local preview)
- [ ] `markdownlint docs/**/*.md spec/**/*.md` passes
- [ ] Every new keyword has all 8 Option C sections
- [ ] Every code example follows BAD-before-GOOD
- [ ] Interview Deep-Dive has the minimum question count (easy=7, medium=9, hard=12)
- [ ] No em dashes, no `c:\ASK\` paths, no BOM

## Reporting issues

Open a GitHub issue with:

- What you tried
- What you expected
- What happened (paste the output)
- Your OS, Ruby version, and `bundle exec jekyll --version`
