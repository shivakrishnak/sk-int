<#
.SYNOPSIS
    Interview Mastery Dictionary - Keyword Generator & Folder Scaffolding
.DESCRIPTION
    Generates keyword lists for interview topics, groups them into
    sub-topic files, and creates folder/index/stub structure.

    Uses spec/topics_registry.md (keyword rubric in spec/topics_registry.md)
    as the master specification for all keyword generation. The prompt
    file at @generate-entries (or scripts/generate_topics.ps1) orchestrates
    this process for dictionary categories and tiers.

    Supports four flows:
    1. New topic from scratch (generates keywords via
       spec/topics_registry.md v1.0 spec)
    2. New topic from existing dictionary category
    3. Add subtopic to existing topic
    4. Scan existing dictionary category to find new
       sub-topic opportunities

    DESIGN CONSIDERATIONS:
    - For new topics without an index.md, use
      spec/topics_registry.md to generate a comprehensive
      keyword list, then apply folder/file rules and generate
      file content.
    - For topics like Angular that do not exist yet, analyse
      where the topic belongs (which tier/category), generate
      keywords via spec/topics_registry.md, create folders
      and files, and generate content.
    - For new subtopics (e.g., React Hooks) where the main
      topic already exists, create the file in the existing
      topic folder, apply file rules, generate keywords via
      spec/topics_registry.md, and generate content.
    - For existing dictionary categories (e.g., JVM, JCC),
      scan the southstar index.md, analyse keywords, check
      for new folder/file opportunities, and generate content.

    ALWAYS use pwsh (PowerShell 7+):
      pwsh -ExecutionPolicy Bypass -File scripts/generate_topics.ps1

    REFERENCES:
    - spec/topics_registry.md: Master keyword generation spec
    - @generate-entries (or scripts/generate_topics.ps1): Prompt file
      for category/tier keyword processing
    - spec/interview.md: Content generation spec

.PARAMETER Topic
    Topic name (e.g., "Java", "Angular", "Kubernetes")
.PARAMETER FromDictionary
    Dictionary category code(s) to source keywords from (e.g., "JLG", "JVM,JLG")
.PARAMETER Subtopic
    Add a new subtopic file to an existing topic
.PARAMETER Keywords
    Comma-separated list of keywords for a new subtopic
.PARAMETER DryRun
    Preview what would be created without writing files
.EXAMPLE
    pwsh -File generate-keywords.ps1 -Topic Java -FromDictionary "JVM,JLG"
.EXAMPLE
    pwsh -File generate-keywords.ps1 -Topic Angular
.EXAMPLE
    pwsh -File generate-keywords.ps1 -Topic React -Subtopic "Hooks" -Keywords "useState,useEffect,useContext,useReducer,useMemo,useCallback,useRef,Custom Hooks"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Topic,

    [Parameter()]
    [string]$FromDictionary,

    [Parameter()]
    [string]$Subtopic,

    [Parameter()]
    [string]$Keywords,

    [Parameter()]
    [switch]$DryRun
)

# - Constants ----------------------------------------------
$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DocsRoot = Join-Path $WorkspaceRoot "docs"
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
# - Version Registry (update when spec versions change) ----
$LatestInterviewVersion = "v1.0"  # spec/interview.md current version

# ── Helper Functions ───────────────────────────────────────

function Get-TopicFolder {
    param([string]$TopicName)
    return ($TopicName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', '')
}

function Get-TopicPath {
    param([string]$TopicName)
    return Join-Path $DocsRoot (Get-TopicFolder $TopicName)
}

function Write-SafeFile {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Read-DictionaryIndex {
    param([string]$CategoryPath)
    $indexPath = Join-Path $CategoryPath "index.md"
    if (-not (Test-Path $indexPath)) { return @() }
    $content = [System.IO.File]::ReadAllText($indexPath, $Utf8NoBom)
    $entries = @()
    foreach ($line in ($content -split "`n")) {
        if ($line -match '^\|\s*([A-Z]{3}-\d{3})\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|') {
            $diff = $Matches[3].Trim()
            $level = switch -Regex ($diff) {
                '^\x{2605}\x{2606}\x{2606}' { "easy" }
                '^\x{2605}\x{2605}\x{2606}' { "medium" }
                '^\x{2605}\x{2605}\x{2605}' { "hard" }
                default { "mixed" }
            }
            $entries += @{
                Id         = $Matches[1].Trim()
                Title      = $Matches[2].Trim()
                Difficulty = $level
                RawDiff    = $diff
            }
        }
    }
    return $entries
}

function Find-DictionaryCategory {
    param([string]$TopicName)
    return @()  # Southstar is content-only - no dictionary lookup.
}

function Find-DictionaryCategory-Legacy {
    param([string]$TopicName)
    $search = $TopicName.ToLower() -replace '\s+', '-'
    $allCats = Get-ChildItem -Path $DictionaryRoot -Recurse -Directory |
        Where-Object { $_.Name -match '^[A-Z]{3}-' }

    $matches = $allCats | Where-Object {
        $folderSearch = $_.Name.ToLower()
        $folderSearch -like "*$search*" -or
        $folderSearch -like "*$($TopicName.ToLower().Replace(' ', ''))*"
    }
    return $matches
}

function Group-KeywordsIntoSubtopics {
    <#
    .SYNOPSIS
        Intelligently groups keywords into sub-topic files.
        Uses difficulty level and keyword name patterns to create
        logical groupings of 5-15 keywords per file.
    #>
    param(
        [string]$TopicName,
        [array]$AllKeywords
    )

    if ($AllKeywords.Count -le 15) {
        # Small category - one file
        return @{
            "Fundamentals" = $AllKeywords
        }
    }

    # Group by difficulty as baseline
    $easy = $AllKeywords | Where-Object { $_.Difficulty -eq "easy" }
    $medium = $AllKeywords | Where-Object { $_.Difficulty -eq "medium" }
    $hard = $AllKeywords | Where-Object { $_.Difficulty -eq "hard" }

    $groups = @{}

    # Easy keywords -> "Basics" or "Fundamentals"
    if ($easy.Count -gt 0) {
        if ($easy.Count -le 15) {
            $groups["Basics"] = $easy
        } else {
            # Split large easy group into chunks
            $chunkSize = [Math]::Ceiling($easy.Count / 2)
            $groups["Basics"] = $easy[0..($chunkSize - 1)]
            $groups["Core Concepts"] = $easy[$chunkSize..($easy.Count - 1)]
        }
    }

    # Medium keywords -> split if needed
    if ($medium.Count -gt 0) {
        if ($medium.Count -le 15) {
            $groups["Intermediate"] = $medium
        } else {
            $chunkSize = [Math]::Ceiling($medium.Count / 2)
            $groups["Intermediate"] = $medium[0..($chunkSize - 1)]
            $groups["Working Patterns"] = $medium[$chunkSize..($medium.Count - 1)]
        }
    }

    # Hard keywords -> "Advanced" or "Deep Dive"
    if ($hard.Count -gt 0) {
        if ($hard.Count -le 15) {
            $groups["Advanced"] = $hard
        } else {
            $chunkSize = [Math]::Ceiling($hard.Count / 2)
            $groups["Advanced"] = $hard[0..($chunkSize - 1)]
            $groups["Architecture and Internals"] = $hard[$chunkSize..($hard.Count - 1)]
        }
    }

    # Handle ungrouped (mixed/unknown difficulty)
    $mixed = $AllKeywords | Where-Object { $_.Difficulty -eq "mixed" }
    if ($mixed.Count -gt 0) {
        $groups["Additional Topics"] = $mixed
    }

    return $groups
}

function New-SubtopicStub {
    param(
        [string]$TopicName,
        [string]$SubtopicName,
        [array]$KeywordEntries,
        [string]$DifficultyRange = "mixed"
    )
    $topicPath = Get-TopicPath $TopicName
    $fileName = "$TopicName - $SubtopicName.md"
    $filePath = Join-Path $topicPath $fileName

    if (Test-Path $filePath) {
        Write-Host "  SKIP (exists): $fileName" -ForegroundColor Yellow
        return
    }

    $kwNames = $KeywordEntries | ForEach-Object {
        if ($_ -is [hashtable]) { $_.Title } else { "$_" }
    }
    $kwYaml = ($kwNames | ForEach-Object { "  - $_" }) -join "`n"

    # Determine difficulty range
    if ($KeywordEntries[0] -is [hashtable]) {
        $diffs = $KeywordEntries | Select-Object -ExpandProperty Difficulty -Unique
        if ($diffs.Count -eq 1) { $DifficultyRange = $diffs[0] }
        else { $DifficultyRange = "mixed" }
    }

    $stub = @"
---
title: $TopicName - $SubtopicName
topic: $TopicName
subtopic: $SubtopicName
keywords:
$kwYaml
difficulty_range: $DifficultyRange
status: draft
version: 0
---

# $TopicName - $SubtopicName

> Content generation pending. Run generate-content.ps1 to populate.

"@

    if (-not $DryRun) {
        Write-SafeFile -Path $filePath -Content $stub
    }
    Write-Host "  CREATED stub: $fileName ($($kwNames.Count) keywords)" -ForegroundColor Green
}

function Update-TopicIndex {
    param([string]$TopicName)
    $topicPath = Get-TopicPath $TopicName
    $indexPath = Join-Path $topicPath "index.md"

    $files = Get-ChildItem -Path $topicPath -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "index.md" } |
        Sort-Object Name

    $rows = @()
    $totalKeywords = 0
    foreach ($f in $files) {
        $content = [System.IO.File]::ReadAllText($f.FullName, $Utf8NoBom)
        $kwCount = 0
        if ($content -match '(?s)keywords:\s*\n((?:\s+- [^\n]+\n?)+)') {
            $kwLines = $Matches[1] -split "`n" |
                Where-Object { $_ -match '^\s+- ' }
            $kwCount = $kwLines.Count
        }
        $totalKeywords += $kwCount

        $desc = ""
        if ($content -match 'subtopic:\s*(.+)') {
            $desc = $Matches[1].Trim()
        }
        $rows += "| $($f.Name) | $kwCount | $desc |"
    }

    $indexContent = @"
---
title: $TopicName
description: Interview mastery content for $TopicName
keywords_count: $totalKeywords
files_count: $($files.Count)
---

# $TopicName

Interview mastery content for $TopicName - complete knowledge, zero to mastery.

| File | Keywords | Description |
|------|----------|-------------|
$($rows -join "`n")
"@

    if (-not $DryRun) {
        Write-SafeFile -Path $indexPath -Content $indexContent
    }
    Write-Host "  INDEX: $TopicName ($($files.Count) files, $totalKeywords keywords)" -ForegroundColor Cyan
}

# ── Main Logic ─────────────────────────────────────────────

Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Interview Mastery - Keyword Generator    ║" -ForegroundColor Cyan
Write-Host "║  Topic: $($Topic.PadRight(34))║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN MODE]" -ForegroundColor DarkGray
}

$topicPath = Get-TopicPath $Topic

# ── Flow 1: Add subtopic to existing topic ─────────────────
if ($Subtopic) {
    Write-Host "`n=== ADD SUBTOPIC: $Subtopic ===" -ForegroundColor Magenta

    if (-not (Test-Path $topicPath)) {
        Write-Error "Topic folder not found: $topicPath. Create the topic first."
        return
    }

    if (-not $Keywords) {
        Write-Host "`nProvide keywords with -Keywords parameter:" -ForegroundColor Yellow
        Write-Host "  -Keywords 'Keyword1,Keyword2,Keyword3'"
        Write-Host "`nOr use AI to generate keywords:" -ForegroundColor Yellow
        Write-Host "`nSPEC: Apply spec/topics_registry.md"
        Write-Host "PROMPT: @generate-entries (or scripts/generate_topics.ps1)"
        Write-Host ""
        Write-Host @"

Generate a keyword list for interview mastery:
  Topic: $Topic
  Subtopic: $Subtopic

Spec reference: spec/topics_registry.md

Requirements:
- 5-15 keywords covering the subtopic comprehensively
- Order: foundational concepts first, advanced last
- Each keyword should be a distinct, teachable concept
- Focus on interview-relevant knowledge
- Include both theoretical and practical concepts
- Include decision framework keywords (Rule 17)
- Include deliberate practice keywords (Rule 18)
- Include interview readiness keywords (Rule 22)

Output format (one keyword per line):
  - Keyword Name
"@
        return
    }

    $kwList = $Keywords -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $kwEntries = $kwList | ForEach-Object { @{ Title = $_; Difficulty = "mixed" } }

    New-SubtopicStub -TopicName $Topic -SubtopicName $Subtopic -KeywordEntries $kwEntries
    Update-TopicIndex -TopicName $Topic

    Write-Host "`n=== SUBTOPIC ADDED ===" -ForegroundColor Magenta
    Write-Host "Next: pwsh -File generate-content.ps1 -Mode file -Topic '$Topic' -File '$Subtopic'"
    return
}

# - Flow 2: From dictionary category (DISABLED in southstar) --
if ($FromDictionary) {
    Write-Error "-FromDictionary is not supported in this repository. Southstar is content-only with no dictionary folder. Generate keywords directly or via @generate-entries."
    exit 2
}

# ── Flow 3: New topic (no dictionary source) ──────────────
Write-Host "`n=== NEW TOPIC: $Topic ===" -ForegroundColor Magenta

# Check for existing dictionary match
$dictMatch = Find-DictionaryCategory $Topic
if ($dictMatch) {
    $codes = ($dictMatch | ForEach-Object { ($_.Name -split '-')[0] }) -join ','
    Write-Host "Found matching dictionary categories: $codes" -ForegroundColor Cyan
    Write-Host "Consider running with -FromDictionary '$codes'" -ForegroundColor Yellow
    Write-Host ""
}

if (Test-Path $topicPath) {
    Write-Host "Topic folder already exists: $(Get-TopicFolder $Topic)/" -ForegroundColor Yellow
    Write-Host "Existing files:" -ForegroundColor White
    Get-ChildItem -Path $topicPath -Filter "*.md" |
        ForEach-Object { Write-Host "  $($_.Name)" }
    Write-Host ""
}

# Output AI prompt for keyword generation
Write-Host "┌─────────────────────────────────────────────┐" -ForegroundColor Green
Write-Host "│ USE THIS PROMPT TO GENERATE KEYWORDS        │" -ForegroundColor Green
Write-Host "│ Spec: spec/topics_registry.md                         │" -ForegroundColor Green
Write-Host "│ Prompt: .github/prompts/generate-keywords    │" -ForegroundColor Green
Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Green
Write-Host ""

$kwPrompt = @"
Generate a comprehensive keyword list for interview mastery on: $Topic

SPEC REFERENCE: Apply spec/topics_registry.md (Category
Keyword Generator rubric) for keyword generation. Use
@generate-entries (or scripts/generate_topics.ps1) for the full
generation workflow.

DESIGN CONSIDERATIONS:
- Analyse where this topic belongs in the tier structure
  (tier-1 through tier-9) and place it accordingly
- Generate keywords covering all applicable knowledge levels:
  L0 (Orientation) through L5 (Creator) + META
- Apply the level-coverage rubric and mandatory keyword types from spec/topics_registry.md
- Use all 12 output components from Section 3
- Run all 17 quality checks from Section 4

Requirements:
1. Cover the topic from zero to god-level mastery
2. Include 30-80 keywords depending on topic breadth
3. Order: foundational -> intermediate -> advanced -> architecture
4. Each keyword is a distinct, teachable concept
5. Focus on what interviewers actually ask about
6. Include both theoretical concepts and practical skills
7. Cover: fundamentals, patterns, internals, debugging,
   performance, architecture, production concerns
8. Include decision framework keywords per level (Rule 17)
9. Include deliberate practice keywords per level (Rule 18)
10. Include interview readiness keywords at every level (Rule 22)

Group keywords into sub-topic files (5-15 keywords each):
- Group related concepts together
- Each group should be self-sufficient
- Name groups clearly: "$Topic - [Subtopic Name]"

Output format:

## $Topic - Basics
- Keyword 1
- Keyword 2
...

## $Topic - [Next Subtopic]
- Keyword N
...

After generating, run:
  pwsh -File scripts/generate_topics.ps1 \`
    -Topic '$Topic' -Subtopic '[Name]' \`
    -Keywords 'Keyword1,Keyword2,Keyword3'

Repeat for each sub-topic group.
"@

Write-Host $kwPrompt

Write-Host ""
Write-Host "┌─────────────────────────────────────────────┐" -ForegroundColor Green
Write-Host "│ END OF PROMPT                               │" -ForegroundColor Green
Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Green

# Create empty folder if not dry run
if (-not $DryRun -and -not (Test-Path $topicPath)) {
    New-Item -ItemType Directory -Path $topicPath -Force | Out-Null
    Write-Host "`nCREATED folder: $(Get-TopicFolder $Topic)/" -ForegroundColor Green

    # Create empty index
    $indexContent = @"
---
title: $Topic
description: Interview mastery content for $Topic
keywords_count: 0
files_count: 0
---

# $Topic

Interview mastery content for $Topic - complete knowledge, zero to mastery.

| File | Keywords | Description |
|------|----------|-------------|
"@
    $indexPath = Join-Path $topicPath "index.md"
    Write-SafeFile -Path $indexPath -Content $indexContent
    Write-Host "CREATED index: $Topic/index.md" -ForegroundColor Green
}

Write-Host "`n=== TOPIC SCAFFOLDED ===" -ForegroundColor Magenta
