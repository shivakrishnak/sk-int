<#
.SYNOPSIS
    Interview Mastery Dictionary - Content Generation Script
.DESCRIPTION
    Generates interview mastery content using INTERVIEW_PROMPT.md spec.
    Operates in multiple modes: single file, full topic, from dictionary
    tier, new topic creation, and subtopic addition.

    Uses spec/topics_registry.md (keyword rubric in spec/topics_registry.md)
    via @generate-entries (or scripts/generate_topics.ps1) for keyword
    discovery when creating new topics or scanning dictionary categories.

    DESIGN CONSIDERATIONS:
    - For new topics without an index.md, uses
      spec/topics_registry.md to generate keywords, applies
      folder/file rules, then generates content.
    - For topics like Angular that do not exist, analyses where
      the topic belongs, generates keywords via
      spec/topics_registry.md, creates folders/files, and
      generates content.
    - For new subtopics (e.g., React Hooks) where the main topic
      exists, creates the file in the existing folder, generates
      keywords via spec/topics_registry.md, and generates
      content.
    - For existing dictionary categories (e.g., JVM, JCC), scans
      the southstar index.md, analyses keywords, checks for new
      folder/file opportunities, and generates content.

    ALWAYS use pwsh (PowerShell 7+) to run this script:
      pwsh -ExecutionPolicy Bypass -File scripts/generate_content.ps1

    REFERENCES:
    - spec/topics_registry.md: Master keyword generation spec
    - @generate-entries (or scripts/generate_topics.ps1): Prompt file
      for category/tier keyword processing
    - spec/interview.md: Content generation spec
    - scripts/generate_topics.ps1: Keyword scaffolding

.PARAMETER Mode
    Operation mode:
      file    - Generate a single sub-topic file
      topic   - Generate all files for a topic folder
      tier    - Scan dictionary tier and generate interview content
      new     - Create a brand-new topic from scratch
      subtopic - Add a new sub-topic file to an existing topic
.PARAMETER Topic
    Topic name (e.g., "Java", "Spring", "Kubernetes")
.PARAMETER File
    Sub-topic file name without .md (e.g., "Collections", "Core and IoC")
    Required for Mode=file and Mode=subtopic
.PARAMETER Tier
    Dictionary tier folder (e.g., "tier-3-java")
    Required for Mode=tier
.PARAMETER BatchSize
    Number of keywords to generate per batch (default: 3)
.PARAMETER DryRun
    If set, shows what would be generated without writing files
.EXAMPLE
    pwsh -File generate-content.ps1 -Mode file -Topic Java -File "Collections"
.EXAMPLE
    pwsh -File generate-content.ps1 -Mode topic -Topic Java
.EXAMPLE
    pwsh -File generate-content.ps1 -Mode tier -Tier tier-3-java
.EXAMPLE
    pwsh -File generate-content.ps1 -Mode new -Topic Angular
.EXAMPLE
    pwsh -File generate-content.ps1 -Mode subtopic -Topic React -File "Hooks"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("file", "topic", "tier", "new", "subtopic")]
    [string]$Mode,

    [Parameter()]
    [string]$Topic,

    [Parameter()]
    [string]$File,

    [Parameter()]
    [string]$Tier,

    [Parameter()]
    [int]$BatchSize = 3,

    [Parameter()]
    [switch]$DryRun
)

# - Constants ----------------------------------------------
$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DocsRoot      = Join-Path $WorkspaceRoot "docs"
$SpecDir       = Join-Path $WorkspaceRoot "spec"
$PromptFile    = Join-Path $SpecDir "interview.md"
$RegistryFile  = Join-Path $SpecDir "topics_registry.md"
$Utf8NoBom     = [System.Text.UTF8Encoding]::new($false)
# - Version Registry (update when spec versions change) ----
$LatestInterviewVersion = "v3.0"  # spec/interview.md current version

# - Validation ---------------------------------------------
if (-not (Test-Path $PromptFile)) {
    Write-Error "spec/interview.md not found at: $PromptFile"
    exit 1
}

if ($Mode -in @("file", "topic", "subtopic") -and -not $Topic) {
    Write-Error "Parameter -Topic is required for Mode=$Mode"
    exit 1
}

if ($Mode -in @("file", "subtopic") -and -not $File) {
    Write-Error "Parameter -File is required for Mode=$Mode"
    exit 1
}

if ($Mode -eq "tier" -and -not $Tier) {
    Write-Error "Parameter -Tier is required for Mode=tier"
    exit 1
}

if ($Mode -eq "new" -and -not $Topic) {
    Write-Error "Parameter -Topic is required for Mode=new"
    exit 1
}

# ── Helper Functions ───────────────────────────────────────

function Get-TopicFolder {
    param([string]$TopicName)
    $slug = $TopicName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', ''
    return $slug
}

function Get-TopicPath {
    param([string]$TopicName)
    $folder = Get-TopicFolder $TopicName
    return Join-Path $DocsRoot $folder
}

function Get-SubtopicFileName {
    param([string]$TopicName, [string]$SubtopicName)
    return "$TopicName - $SubtopicName.md"
}

function Test-FileHasContent {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $content = [System.IO.File]::ReadAllText($FilePath, $Utf8NoBom)
    # Check if file has more than just frontmatter (stub detection)
    $lines = $content -split "`n"
    $contentLines = $lines | Where-Object {
        $_ -notmatch '^\s*$' -and
        $_ -notmatch '^---' -and
        $_ -notmatch '^(title|topic|subtopic|keywords|difficulty_range|status|version|  - ):'
    }
    return ($contentLines.Count -gt 5)
}

function Write-SafeFile {
    param(
        [string]$Path,
        [string]$Content
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)

    # Verify encoding
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        Write-Warning "BOM detected in $Path - this should not happen"
    }
}

function Read-IndexKeywords {
    param([string]$IndexPath)
    if (-not (Test-Path $IndexPath)) { return @() }
    $content = [System.IO.File]::ReadAllText($IndexPath, $Utf8NoBom)
    $keywords = @()
    foreach ($line in ($content -split "`n")) {
        if ($line -match '^\|\s*([^|]+)\s*\|\s*(\d+)\s*\|\s*([^|]+)\s*\|') {
            $fileName = $Matches[1].Trim()
            if ($fileName -ne "File" -and $fileName -ne "---") {
                $keywords += @{
                    File = $fileName
                    Count = [int]$Matches[2]
                    Description = $Matches[3].Trim()
                }
            }
        }
    }
    return $keywords
}

function Read-DictionaryIndex {
    param([string]$CategoryFolder)
    $indexPath = Join-Path $CategoryFolder "index.md"
    if (-not (Test-Path $indexPath)) { return @() }
    $content = [System.IO.File]::ReadAllText($indexPath, $Utf8NoBom)
    $entries = @()
    foreach ($line in ($content -split "`n")) {
        if ($line -match '^\|\s*([A-Z]{3}-\d{3})\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|') {
            $entries += @{
                Id = $Matches[1].Trim()
                Title = $Matches[2].Trim()
                Difficulty = $Matches[3].Trim()
            }
        }
    }
    return $entries
}

function New-StubFile {
    param(
        [string]$TopicName,
        [string]$SubtopicName,
        [string[]]$Keywords,
        [string]$DifficultyRange = "mixed",
        [int]$NavOrder = 0
    )
    $topicPath = Get-TopicPath $TopicName
    $fileName = Get-SubtopicFileName $TopicName $SubtopicName
    $filePath = Join-Path $topicPath $fileName

    if (Test-Path $filePath) {
        Write-Host "  SKIP (exists): $fileName" -ForegroundColor Yellow
        return $filePath
    }

    # Calculate nav_order from existing files if not specified
    if ($NavOrder -eq 0) {
        $existingFiles = Get-ChildItem -Path $topicPath -Filter "*.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "index.md" }
        $NavOrder = $existingFiles.Count + 1
    }

    $topicSlug = Get-TopicFolder $TopicName
    $subtopicSlug = $SubtopicName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', ''

    $kwYaml = ($Keywords | ForEach-Object { "  - $_" }) -join "`n"
    $stub = @"
---
title: "$TopicName - $SubtopicName"
topic: $TopicName
subtopic: $SubtopicName
keywords:
$kwYaml
difficulty_range: $DifficultyRange
status: draft
version: 0
---

# $TopicName - $SubtopicName

> Content generation pending. Run scripts/generate_content.ps1 to populate.

"@

    Write-SafeFile -Path $filePath -Content $stub
    Write-Host "  CREATED stub: $fileName" -ForegroundColor Green
    return $filePath
}

function Update-TopicIndex {
    param([string]$TopicName)
    $topicPath = Get-TopicPath $TopicName
    $indexPath = Join-Path $topicPath "index.md"

    $files = Get-ChildItem -Path $topicPath -Filter "*.md" |
        Where-Object { $_.Name -ne "index.md" } |
        Sort-Object Name

    $rows = @()
    $totalKeywords = 0
    foreach ($f in $files) {
        $content = [System.IO.File]::ReadAllText($f.FullName, $Utf8NoBom)
        $kwCount = 0
        $desc = ""
        foreach ($line in ($content -split "`n")) {
            if ($line -match '^\s+- (.+)$' -and $content.IndexOf("keywords:") -lt $content.IndexOf($line)) {
                # Rough count - lines under keywords: array
            }
            if ($line -match '^keywords:') {
                # Start counting
                $inKw = $true
            }
        }
        # Simpler approach: count keywords from frontmatter
        if ($content -match '(?s)keywords:\s*\n((?:\s+- [^\n]+\n?)+)') {
            $kwLines = $Matches[1] -split "`n" |
                Where-Object { $_ -match '^\s+- ' }
            $kwCount = $kwLines.Count
        }
        $totalKeywords += $kwCount

        # Extract subtopic for description
        if ($content -match 'subtopic:\s*(.+)') {
            $desc = $Matches[1].Trim()
        }

        $rows += "| $($f.Name) | $kwCount | $desc |"
    }

    # Calculate nav_order for this topic index (used only in description metadata)
    $existingTopics = Get-ChildItem -Path $DocsRoot -Directory |
        Sort-Object Name
    $topicNavOrder = 1
    for ($idx = 0; $idx -lt $existingTopics.Count; $idx++) {
        if ($existingTopics[$idx].Name -eq (Get-TopicFolder $TopicName)) {
            $topicNavOrder = $idx + 1
            break
        }
    }

    $topicSlug = Get-TopicFolder $TopicName

    $indexContent = @"
---
title: "$TopicName"
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

    Write-SafeFile -Path $indexPath -Content $indexContent
    Write-Host "  UPDATED index: $TopicName/index.md ($($files.Count) files, $totalKeywords keywords)" -ForegroundColor Cyan
}

function Build-GenerationPrompt {
    param(
        [string]$TopicName,
        [string]$SubtopicName,
        [string[]]$Keywords,
        [int]$BatchStart = 0,
        [int]$BatchEnd = -1
    )

    if ($BatchEnd -lt 0) { $BatchEnd = $Keywords.Count - 1 }
    $batchKeywords = $Keywords[$BatchStart..$BatchEnd]

    $kwList = ($batchKeywords | ForEach-Object { "      - $_" }) -join "`n"

    $prompt = @"
Generate interview mastery content following spec/interview.md $LatestInterviewVersion exactly.

SPEC REFERENCES:
- Content spec: spec/interview.md
- Keyword spec: spec/topics_registry.md
- Keyword prompt: @generate-entries (or scripts/generate_topics.ps1)

    Topic:    $TopicName
    Subtopic: $SubtopicName
    File:     $(Get-SubtopicFileName $TopicName $SubtopicName)
    Keywords (batch $($BatchStart + 1) to $($BatchEnd + 1) of $($Keywords.Count)):
$kwList

Rules:
- Follow the complete skeleton from Section 6 of spec/interview.md
- Each keyword gets all 19 required sections
- Interview Deep-Dive: question count scales by difficulty (easy: 7, medium: 9, hard: 12)
- Answers must show learning progression and demonstrate depth
- BAD pattern before GOOD pattern in all code examples
- Code lines max 70 chars, ASCII diagrams max 59 chars wide
- Every ### preceded by --- with blank lines
- Separate keywords with double horizontal rules (--- then ---)
- Section headers use emoji per spec (no emoji in YAML frontmatter)
- Production-grade examples, not toy code
- UTF-8 without BOM

Generate ONLY the content for the keywords listed above.
Do not include YAML frontmatter (it will be prepended separately).
Start directly with the first keyword's # title.
"@

    return $prompt
}

# ── Tier-to-Topic Mapping ─────────────────────────────────

$TierTopicMap = @{
    "JVM" = @{ Topic = "Java"; Subtopics = @("JVM Internals", "Garbage Collection") }
    "JLG" = @{ Topic = "Java"; Subtopics = @("Basics", "Collections", "Exceptions and IO", "Java 8 Features", "Java 11 to 17", "Java 21 and Beyond") }
    "JCC" = @{ Topic = "Java Concurrency"; Subtopics = @("Thread Basics", "Synchronization", "Concurrent Collections", "Virtual Threads") }
    "SPR" = @{ Topic = "Spring"; Subtopics = @("Core and IoC", "Annotations", "Boot", "MVC and REST", "Data and JPA", "Security", "Cloud") }
    "JPH" = @{ Topic = "Hibernate"; Subtopics = @("Basics", "Relationships", "Performance") }
    "DBF" = @{ Topic = "SQL and Databases"; Subtopics = @("Fundamentals", "Joins and Relationships", "Performance", "Transactions", "Architecture") }
    "NDB" = @{ Topic = "SQL and Databases"; Subtopics = @("NoSQL Patterns") }
    "CTR" = @{ Topic = "Containers"; Subtopics = @("Docker Basics", "Docker Advanced", "Container Security") }
    "K8S" = @{ Topic = "Kubernetes"; Subtopics = @("Core Resources", "Networking", "Storage and State", "Security and RBAC", "Operations") }
    "DST" = @{ Topic = "System Design"; Subtopics = @("Fundamentals", "Data at Scale") }
    "MSV" = @{ Topic = "System Design"; Subtopics = @("Microservices") }
    "SYD" = @{ Topic = "System Design"; Subtopics = @("Case Studies") }
    "SAP" = @{ Topic = "System Design"; Subtopics = @("Patterns") }
    "SEC" = @{ Topic = "Security"; Subtopics = @("Web Security", "Authentication") }
    "IAM" = @{ Topic = "Security"; Subtopics = @("Authorization and IAM") }
    "CRY" = @{ Topic = "Security"; Subtopics = @("Cryptography") }
    "RCT" = @{ Topic = "React"; Subtopics = @("Basics", "Hooks and State", "Performance", "Testing") }
    "DSA" = @{ Topic = "Data Structures and Algorithms"; Subtopics = @("Arrays and Strings", "Trees and Graphs", "Sorting and Searching", "Dynamic Programming") }
    "CCH" = @{ Topic = "Caching"; Subtopics = @("Fundamentals", "Redis and Memcached", "CDN and Edge") }
    "MSG" = @{ Topic = "Messaging"; Subtopics = @("Fundamentals", "Kafka", "Event-Driven Architecture") }
    "CCD" = @{ Topic = "CI/CD and DevOps"; Subtopics = @("Pipelines", "Strategies") }
    "GIT" = @{ Topic = "CI/CD and DevOps"; Subtopics = @("Git Fundamentals", "Branching Strategies") }
    "OBS" = @{ Topic = "CI/CD and DevOps"; Subtopics = @("Observability", "SRE Practices") }
    "AIF" = @{ Topic = "AI and RAG"; Subtopics = @("AI Foundations") }
    "LLM" = @{ Topic = "AI and RAG"; Subtopics = @("LLMs and Prompt Engineering") }
    "RAG" = @{ Topic = "AI and RAG"; Subtopics = @("RAG Fundamentals", "Agents", "LLMOps") }
    "DPT" = @{ Topic = "Design Patterns"; Subtopics = @("Creational", "Structural", "Behavioral", "SOLID", "Anti-Patterns") }
    "ASY" = @{ Topic = "Async and Background Processing"; Subtopics = @("Fundamentals", "Message Brokers", "Patterns", "Orchestration", "Observability") }
}

# ── Mode Handlers ──────────────────────────────────────────

function Invoke-FileMode {
    Write-Host "`n=== GENERATE SINGLE FILE ===" -ForegroundColor Magenta
    Write-Host "Topic:    $Topic"
    Write-Host "Subtopic: $File"

    $topicPath = Get-TopicPath $Topic
    $fileName = Get-SubtopicFileName $Topic $File
    $filePath = Join-Path $topicPath $fileName

    # Check if file exists and has content
    if (Test-FileHasContent $filePath) {
        Write-Host "File already has content: $fileName" -ForegroundColor Yellow
        Write-Host "Use -Force to regenerate (not implemented - delete file first)"
        return
    }

    # Read keywords from existing stub or index
    $keywords = @()
    if (Test-Path $filePath) {
        $content = [System.IO.File]::ReadAllText($filePath, $Utf8NoBom)
        if ($content -match '(?s)keywords:\s*\n((?:\s+- [^\n]+\n?)+)') {
            $keywords = ($Matches[1] -split "`n" |
                Where-Object { $_ -match '^\s+- (.+)$' } |
                ForEach-Object { $Matches[1].Trim() })
        }
    }

    if ($keywords.Count -eq 0) {
        Write-Error "No keywords found in $fileName. Create stub first or add keywords to frontmatter."
        return
    }

    Write-Host "Keywords to generate ($($keywords.Count)):" -ForegroundColor Cyan
    $keywords | ForEach-Object { Write-Host "  - $_" }

    # Generate in batches
    $totalBatches = [Math]::Ceiling($keywords.Count / $BatchSize)
    Write-Host "`nBatch plan: $totalBatches batches of $BatchSize keywords" -ForegroundColor Cyan

    for ($i = 0; $i -lt $keywords.Count; $i += $BatchSize) {
        $batchEnd = [Math]::Min($i + $BatchSize - 1, $keywords.Count - 1)
        $batchNum = [Math]::Floor($i / $BatchSize) + 1

        Write-Host "`n--- Batch $batchNum/$totalBatches (keywords $($i+1)-$($batchEnd+1)) ---" -ForegroundColor Yellow

        $prompt = Build-GenerationPrompt `
            -TopicName $Topic `
            -SubtopicName $File `
            -Keywords $keywords `
            -BatchStart $i `
            -BatchEnd $batchEnd

        if ($DryRun) {
            Write-Host "[DRY RUN] Would generate with prompt:" -ForegroundColor DarkGray
            Write-Host $prompt -ForegroundColor DarkGray
        } else {
            # Output the prompt for the AI to process
            Write-Host "`n┌─────────────────────────────────────────┐" -ForegroundColor Green
            Write-Host "│ COPY PROMPT BELOW TO AI ASSISTANT       │" -ForegroundColor Green
            Write-Host "└─────────────────────────────────────────┘" -ForegroundColor Green
            Write-Host ""
            Write-Host $prompt
            Write-Host ""
            Write-Host "┌─────────────────────────────────────────┐" -ForegroundColor Green
            Write-Host "│ END OF PROMPT                           │" -ForegroundColor Green
            Write-Host "└─────────────────────────────────────────┘" -ForegroundColor Green

            Write-Host "`nAfter AI generates content:" -ForegroundColor Cyan
            Write-Host "  1. Save output to: $filePath"
            Write-Host "  2. Prepend YAML frontmatter if not present"
            Write-Host "  3. Verify encoding: UTF-8 without BOM"
        }
    }

    Write-Host "`n=== DONE ===" -ForegroundColor Magenta
}

function Invoke-TopicMode {
    Write-Host "`n=== GENERATE FULL TOPIC: $Topic ===" -ForegroundColor Magenta

    $topicPath = Get-TopicPath $Topic
    if (-not (Test-Path $topicPath)) {
        Write-Error "Topic folder not found: $topicPath. Use Mode=new to create it."
        return
    }

    $files = Get-ChildItem -Path $topicPath -Filter "*.md" |
        Where-Object { $_.Name -ne "index.md" } |
        Sort-Object Name

    if ($files.Count -eq 0) {
        Write-Error "No sub-topic files found in $topicPath. Run generate-keywords.ps1 first."
        return
    }

    Write-Host "Files to process ($($files.Count)):" -ForegroundColor Cyan
    $fileStatus = @()
    foreach ($f in $files) {
        $hasContent = Test-FileHasContent $f.FullName
        $status = if ($hasContent) { "COMPLETE" } else { "PENDING" }
        $color = if ($hasContent) { "Green" } else { "Yellow" }
        Write-Host "  [$status] $($f.Name)" -ForegroundColor $color
        $fileStatus += @{ Name = $f.Name; HasContent = $hasContent; Path = $f.FullName }
    }

    $pending = $fileStatus | Where-Object { -not $_.HasContent }
    if ($pending.Count -eq 0) {
        Write-Host "`nAll files already have content!" -ForegroundColor Green
        return
    }

    Write-Host "`n$($pending.Count) files pending generation" -ForegroundColor Yellow

    foreach ($pf in $pending) {
        # Extract subtopic from filename: "Topic - Subtopic.md" -> "Subtopic"
        $subtopic = $pf.Name -replace "^$([regex]::Escape($Topic))\s*-\s*", "" -replace "\.md$", ""
        Write-Host "`n>>> Processing: $($pf.Name) <<<" -ForegroundColor Magenta

        # Delegate to file mode logic
        $script:File = $subtopic
        Invoke-FileMode
    }

    # Update index after all files processed
    Update-TopicIndex -TopicName $Topic
    Write-Host "`n=== TOPIC COMPLETE: $Topic ===" -ForegroundColor Magenta
}

function Invoke-TierMode {
    Write-Error "Mode 'tier' is not supported in this repository. Southstar is content-only with no dictionary. Use Mode=new, topic, subtopic, or file instead."
    exit 2
}

function Invoke-TierMode-Legacy {

    $tierPath = Join-Path $DictionaryRoot $Tier
    if (-not (Test-Path $tierPath)) {
        Write-Error "Dictionary tier not found: $tierPath"
        return
    }

    $categories = Get-ChildItem -Path $tierPath -Directory | Sort-Object Name
    Write-Host "Categories found ($($categories.Count)):" -ForegroundColor Cyan

    $topicsToGenerate = @{}
    foreach ($cat in $categories) {
        $code = ($cat.Name -split '-')[0]
        Write-Host "  $code - $($cat.Name)" -ForegroundColor White

        if ($TierTopicMap.ContainsKey($code)) {
            $mapping = $TierTopicMap[$code]
            $topicName = $mapping.Topic

            # Read dictionary keywords
            $entries = Read-DictionaryIndex $cat.FullName
            Write-Host "    -> Maps to: $topicName ($($entries.Count) keywords)" -ForegroundColor Cyan

            if (-not $topicsToGenerate.ContainsKey($topicName)) {
                $topicsToGenerate[$topicName] = @{
                    Subtopics = @()
                    Keywords = @()
                }
            }
            $topicsToGenerate[$topicName].Subtopics += $mapping.Subtopics
            $topicsToGenerate[$topicName].Keywords += $entries
        } else {
            Write-Host "    -> No mapping found (add to TierTopicMap)" -ForegroundColor Yellow
        }
    }

    Write-Host "`n--- Generation Plan ---" -ForegroundColor Yellow
    foreach ($entry in $topicsToGenerate.GetEnumerator()) {
        $t = $entry.Key
        $info = $entry.Value
        Write-Host "  Topic: $t" -ForegroundColor White
        Write-Host "    Subtopics: $($info.Subtopics -join ', ')"
        Write-Host "    Keywords: $($info.Keywords.Count)"

        if (-not $DryRun) {
            # Create topic folder and stubs
            $topicPath = Get-TopicPath $t
            if (-not (Test-Path $topicPath)) {
                New-Item -ItemType Directory -Path $topicPath -Force | Out-Null
                Write-Host "    CREATED folder: $topicPath" -ForegroundColor Green
            }

            $uniqueSubtopics = $info.Subtopics | Select-Object -Unique
            $allKeywords = $info.Keywords | Select-Object -ExpandProperty Title
            $chunkSize = [Math]::Ceiling($allKeywords.Count / [Math]::Max(1, $uniqueSubtopics.Count))
            $kwIndex = 0
            $navOrd = 0

            foreach ($st in $uniqueSubtopics) {
                $navOrd++
                # Distribute keywords evenly across subtopics
                $end = [Math]::Min($kwIndex + $chunkSize - 1, $allKeywords.Count - 1)
                if ($kwIndex -le $end) {
                    $stKeywords = $allKeywords[$kwIndex..$end]
                } else {
                    $stKeywords = @("(Add keywords here)")
                }
                $kwIndex = $end + 1
                New-StubFile -TopicName $t -SubtopicName $st -Keywords $stKeywords -NavOrder $navOrd
            }

            Update-TopicIndex -TopicName $t
        }
    }

    if ($DryRun) {
        Write-Host "`n[DRY RUN] No files written" -ForegroundColor DarkGray
    }

    Write-Host "`n=== TIER SCAN COMPLETE ===" -ForegroundColor Magenta
}

function Invoke-NewMode {
    Write-Host "`n=== CREATE NEW TOPIC: $Topic ===" -ForegroundColor Magenta

    $topicPath = Get-TopicPath $Topic
    if (Test-Path $topicPath) {
        Write-Host "Topic folder already exists: $topicPath" -ForegroundColor Yellow
        Write-Host "Use Mode=topic to generate content for existing topic"
        return
    }

    Write-Host "Use generate_topics.ps1 (or @generate-entries) to plan the keyword list." -ForegroundColor Yellow
    Write-Host "  Spec: spec/topics_registry.md" -ForegroundColor Cyan
    Write-Host "  Prompt: @generate-entries (or scripts/generate_topics.ps1)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/generate_topics.ps1 -Topic '$Topic'"

    if (-not $DryRun) {
        # Create folder structure
        New-Item -ItemType Directory -Path $topicPath -Force | Out-Null
        Write-Host "CREATED folder: $topicPath" -ForegroundColor Green

        # Create minimal index
        $topicSlug = Get-TopicFolder $Topic
        $existingTopics = Get-ChildItem -Path $DocsRoot -Directory
        $navOrder = $existingTopics.Count + 1

        $indexContent = @"
---
title: "$Topic"
description: Interview mastery content for $Topic
keywords_count: 0
files_count: 0
---

# $Topic

Interview mastery content for $Topic.

| File | Keywords | Description |
|------|----------|-------------|
"@
        $indexPath = Join-Path $topicPath "index.md"
        Write-SafeFile -Path $indexPath -Content $indexContent
        Write-Host "CREATED index: $Topic/index.md" -ForegroundColor Green

        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "  1. Run generate-keywords.ps1 to populate keyword list"
        Write-Host "  2. Review and group keywords into sub-topic files"
        Write-Host "  3. Run generate-content.ps1 -Mode topic -Topic '$Topic'"
    }

    Write-Host "`n=== NEW TOPIC CREATED ===" -ForegroundColor Magenta
}

function Invoke-SubtopicMode {
    Write-Host "`n=== ADD SUBTOPIC: $Topic / $File ===" -ForegroundColor Magenta

    $topicPath = Get-TopicPath $Topic
    if (-not (Test-Path $topicPath)) {
        Write-Error "Topic folder not found: $topicPath. Use Mode=new to create it first."
        return
    }

    $fileName = Get-SubtopicFileName $Topic $File
    $filePath = Join-Path $topicPath $fileName

    if (Test-Path $filePath) {
        Write-Host "File already exists: $fileName" -ForegroundColor Yellow
        if (Test-FileHasContent $filePath) {
            Write-Host "File already has content. Delete it first to regenerate."
            return
        }
        Write-Host "File is a stub - ready for content generation."
    }

    Write-Host "`nTo create this subtopic:" -ForegroundColor Cyan
    Write-Host "  1. Add keywords to generate-keywords.ps1 output or manually"
    Write-Host "  2. Run: pwsh -File generate-content.ps1 -Mode file -Topic '$Topic' -File '$File'"
    Write-Host "`nOr provide keywords now to create a stub:"
    Write-Host "  Example keywords for '$File':"
    Write-Host "    - Keyword 1"
    Write-Host "    - Keyword 2"
    Write-Host "    - Keyword 3"

    if (-not $DryRun) {
        # Create stub with placeholder keywords
        $stubKeywords = @("(Add keywords here)")
        New-StubFile -TopicName $Topic -SubtopicName $File -Keywords $stubKeywords
        Update-TopicIndex -TopicName $Topic
    }

    Write-Host "`n=== SUBTOPIC SCAFFOLDED ===" -ForegroundColor Magenta
}

# ── Main Execution ─────────────────────────────────────────

Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Interview Mastery - Content Generator    ║" -ForegroundColor Cyan
Write-Host "║  Mode: $($Mode.PadRight(36))║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN MODE - no files will be written]" -ForegroundColor DarkGray
}

switch ($Mode) {
    "file"     { Invoke-FileMode }
    "topic"    { Invoke-TopicMode }
    "tier"     { Invoke-TierMode }
    "new"      { Invoke-NewMode }
    "subtopic" { Invoke-SubtopicMode }
}
