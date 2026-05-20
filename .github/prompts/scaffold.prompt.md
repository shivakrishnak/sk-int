---
mode: agent
description: "Run interview scaffold generator for a topic - creates [FILL:...] stub files (optional - not required for content generation)"
tools:
  - run_in_terminal
  - read_file
  - list_dir
  - file_search
---

> **Version Registry** - `SPEC_VERSION` = **1** | `SPEC_LABEL` = **v1.0**

# Interview Scaffold Generator (optional)

> **Scaffolding is optional.** The `/interview` agent and
> `@generate-entries` prompt read keywords directly from
> frontmatter and generate content without scaffolding. Use this
> only to preview file structure before generating content.

Run the scaffold generator to create `[FILL:...]` stub files for an
interview topic. The scaffold pre-builds all 19 sections per keyword
with placeholder markers.

## Usage

**Target topic:** `${input:topic:Topic name (e.g. java, hibernate, react)}`

## Workflow

1. Check `spec/topics_registry.md` for the topic's folder and status
2. Verify the topic folder exists under `docs/`
3. Run the scaffold generator:

```pwsh
& "$env:USERPROFILE\.local\bin\python3.14.exe" scripts/scaffold_topic.py ${input:topic}
```

4. Verify generated files:
   - List all `.md` files in the topic folder
   - Confirm each file has `[FILL:...]` stubs
   - Count total keywords scaffolded

5. Update `spec/topics_registry.md` status to `scaffolded`

## Post-Scaffold

After scaffolding, use `@generate-entries` or `@fill-content` to
generate real content for each keyword.

Alternatively, skip scaffolding entirely and use the agent or prompts
directly - they read keywords from frontmatter and generate content
without needing scaffold stubs.

## Notes

- Python path: `$env:USERPROFILE\.local\bin\python3.14.exe`
- Always use `pwsh` (PowerShell 7+)
- The scaffold script reads keyword lists from `docs/<topic>/index.md`
- If index.md doesn't exist, scaffold will fail - create it first
