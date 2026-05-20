# Specifications & contributor reference

This folder is the authoritative source for the **Interview Mastery Dictionary v1.0** content model and the topic registry.

| File                         | Purpose                                                                                 |
| ---------------------------- | --------------------------------------------------------------------------------------- |
| [interview.md](interview.md) | Master generation spec - 19 sections per keyword, voice, quality constitution, examples |
| [topics_registry.md](topics_registry.md)       | Topic-to-folder mapping, level-coverage framework, planned subtopic files               |
| [README.md](README.md)       | This file                                                                               |

The `/interview` Copilot agent and the `@fill-content`, `@generate-entries`, `@scaffold` prompts all read [interview.md](interview.md) once per session, then use the condensed rules in `.github/instructions/interview.instructions.md` for subsequent keywords.

This folder is **excluded** from the published MkDocs site via `exclude_docs` in `mkdocs.yml`. It exists for contributors, agents, and automation only.

## When to read what

- **First time contributing**: start with [../CONTRIBUTING.md](../CONTRIBUTING.md), then [topics_registry.md](topics_registry.md) to see the coverage map.
- **Generating a new keyword**: read [interview.md](interview.md) Section 4 (the 19-section structure) and Section 5 (Quality Constitution).
- **Adding a new topic**: read [topics_registry.md](topics_registry.md) for level-coverage rules, then run the `/interview` agent or `scripts/generate_topics.ps1`.
- **Debugging frontmatter or build errors**: read the **Pre-Commit Frontmatter Verification** section in `.github/agents/interview.agent.md`.

## Versioning

`SPEC_VERSION = 1`, `SPEC_LABEL = v1.0`. Bump only after consensus and a migration plan for existing content.
