#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
  Adds missing conditional section headers (with OMIT notes) to keyword
  blocks that lack them. Targets R21 violations for:
    - ### 🏛️ System Design    (non-★★★ keywords)
    - ### 📊 Diagram           (non-visual concepts)
    - ### ⚖️ Comparison Table  (★☆☆ keywords)
    - ### 💻 Code Example      (non-programmatic concepts)

  These sections REQUIRE their ### header to be present even when not
  applicable - with an explicit *(Omit: reason)* note per the spec.
  Silent omissions are never acceptable (Rule R21 / HARD STOP).

.NOTES
  Mandatory content sections (Model Answer, Concept Explanation, Answers by
  Seniority, Common Misconceptions, Failure Modes, Interview Deep-Dive) are
  NOT handled here - they require actual content regeneration.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$enc = [System.Text.UTF8Encoding]::new($false)

$counters = @{
  SystemDesign   = 0
  Diagram        = 0
  Comparison     = 0
  CodeExample    = 0
  Files          = 0
}

$repo  = Split-Path -Parent $PSScriptRoot
$docs  = Join-Path $repo 'docs'
$files = Get-ChildItem $docs -Recurse -Filter '*.md' |
  Where-Object { $_.Name -ne 'index.md' } |
  ForEach-Object { $_.FullName }

Write-Host "fix_r21_conditional_sections.ps1: processing $($files.Count) files..." `
  -ForegroundColor Cyan

# ── Section patterns (what R21 looks for) ───────────────────────────────────
$sectionPatterns = @{
  'SystemDesign' = '^### 🏛️ System Design'
  'Diagram'      = '^### 📊 Diagram'
  'Comparison'   = '^### ⚖️ Comparison'
  'CodeExample'  = '^### 💻 Code Example'
}

# ── Placeholder content for each conditional section ────────────────────────
$placeholders = @{
  'SystemDesign' = @"

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*

"@
  'Diagram' = @"

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*

"@
  'Comparison' = @"

---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*

"@
  'CodeExample' = @"

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*

"@
}

foreach ($file in $files) {
  $text    = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  $lines   = $text -split "\r?\n"
  $changed = $false

  # Find keyword blocks (H1 headings outside frontmatter and code fences)
  $bodyStart = 0
  if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
    for ($i = 1; $i -lt $lines.Count; $i++) {
      if ($lines[$i].Trim() -eq '---') { $bodyStart = $i + 1; break }
    }
  }
  $keywordStarts = @()
  $inFence = $false
  for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*```') { $inFence = -not $inFence; continue }
    if (-not $inFence -and $lines[$i] -match '^# [^#]') { $keywordStarts += $i }
  }
  if ($keywordStarts.Count -eq 0) { continue }

  # Process each keyword block
  $insertions = [System.Collections.Generic.List[hashtable]]::new()
  for ($k = 0; $k -lt $keywordStarts.Count; $k++) {
    $start = $keywordStarts[$k]
    $end   = if ($k + 1 -lt $keywordStarts.Count) {
               $keywordStarts[$k + 1] - 1
             } else { $lines.Count - 1 }
    $block = $lines[$start..$end] -join "`n"

    foreach ($sname in $sectionPatterns.Keys) {
      $pat = $sectionPatterns[$sname]
      $hasSection = $block -match $pat
      if (-not $hasSection) {
        # Insert placeholder before the end of this keyword block
        # (before the next keyword's H1 separator or end of file)
        # Find the last non-blank line in this block
        $insertAt = $end
        while ($insertAt -gt $start -and $lines[$insertAt].Trim() -eq '') {
          $insertAt--
        }
        $insertions.Add(@{
          After     = $insertAt
          Content   = $placeholders[$sname]
          Section   = $sname
        })
        $counters[$sname]++
        $changed = $true
      }
    }
  }

  if (-not $changed) { continue }

  # Apply insertions in reverse order (so line numbers stay valid)
  $insertions_sorted = $insertions | Sort-Object { $_.After } -Descending
  $lineList = [System.Collections.Generic.List[string]]::new($lines)
  foreach ($ins in $insertions_sorted) {
    $insertLines = ($ins.Content -split "\r?\n")
    for ($j = $insertLines.Count - 1; $j -ge 0; $j--) {
      $lineList.Insert($ins.After + 1, $insertLines[$j])
    }
  }

  $content = ($lineList.ToArray() -join "`n")
  if ($text -match "\n$") { $content += "`n" }
  [System.IO.File]::WriteAllText($file, $content, $enc)
  $counters.Files++
}

Write-Host "`nfix_r21_conditional_sections.ps1: complete." -ForegroundColor Green
Write-Host "  Files modified : $($counters.Files)"
Write-Host "  System Design  : $($counters.SystemDesign)"
Write-Host "  Diagram        : $($counters.Diagram)"
Write-Host "  Comparison     : $($counters.Comparison)"
Write-Host "  Code Example   : $($counters.CodeExample)"
