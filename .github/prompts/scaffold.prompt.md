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

## ⛔ CONFIRMED FAILURES - NON-NEGOTIABLE HARD RULES

<!-- Gate 1 is also in interview.instructions.md (auto-loads for docs/spec/scripts). -->
<!-- Retained here as a safety net for cold invocations where the instructions file may not yet be loaded. -->

They are permanently prohibited. Violation = file is REJECTED, not written.

**FAILURE 1 - Spec not read:** NEVER generate any entry without first reading
`spec/interview_content_generator.md` in full in the current session. Generating
from memory or conversation summaries produces wrong headers. ALWAYS read the spec.

### GATE 1 - SPEC MUST BE READ BEFORE ANY GENERATION (Fixes Failure 1)

**RULE:** Before generating ANY entry, read `spec/interview_content_generator.md` in full.

Generating from memory, conversation summaries, or abbreviated notes is PROHIBITED.
The spec defines exact section IDs, exact `###` headers, exact emoji, mandatory
subsections, and TYPE-specific adaptations that cannot be reproduced from memory.
Any entry generated without reading the spec WILL contain wrong headers and MUST be
regenerated from scratch.

**ENFORCEMENT:** If the model has not confirmed reading `spec/interview_content_generator.md`
in the current session since the last context reset, it MUST read it before writing
any file. No exceptions. This is the first step of every generation workflow.

---

# Interview Scaffold Generator (optional)

> **Scaffolding is optional.** The `/interview` agent and
> `@generate-entries` prompt read keywords directly from
> frontmatter and generate content without scaffolding. Use this
> only to preview file structure before generating content.

Run the scaffold generator to create `[FILL:...]` stub files for an
interview topic. The scaffold pre-builds all 8 Option C sections per keyword
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

After scaffolding, use `@generate-entries` to
generate real content for each keyword.

Alternatively, skip scaffolding entirely and use the agent or prompts
directly - they read keywords from frontmatter and generate content
without needing scaffold stubs.

## Notes

- Python path: `$env:USERPROFILE\.local\bin\python3.14.exe`
- Always use `pwsh` (PowerShell 7+)
- The scaffold script reads keyword lists from `docs/<topic>/index.md`
- If index.md doesn't exist, scaffold will fail - create it first
