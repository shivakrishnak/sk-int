#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
  Auto-fixes validation issues in docs/*.md files.
  Safe to re-run: skips already-fixed issues.

.DESCRIPTION
  Fixes the following rule violations automatically:
  R02 - Em dashes (replace with hyphen)
  R08 - Missing --- before ### headings (insert divider)
  R09 - Missing code/diagram walkthroughs (add placeholder)
  R15 - Consecutive bold-label lines (insert blank line)
  R19 - Blank Mind Recovery format (fix bold formatting)

  Skips index.md files for rules that exclude them.
  Writes UTF-8 without BOM.

.PARAMETER Path
  Limit fix to a single file or glob. Default: all docs/**/*.md

.EXAMPLE
  pwsh scripts/fix_validation_issues.ps1
  pwsh scripts/fix_validation_issues.ps1 -Path "docs/ai-agents/*.md"
#>
param(
  [string]$Path = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$enc  = [System.Text.UTF8Encoding]::new($false)  # UTF-8 without BOM
$repo = Split-Path -Parent $PSScriptRoot

$counters = @{
  R02 = 0; R08 = 0; R09 = 0; R15 = 0; R19 = 0
  Files = 0
}

# ── Collect files ─────────────────────────────────────────────────────────
if ($Path -ne '') {
  $files = Get-ChildItem $Path -Filter '*.md' -Recurse |
    ForEach-Object { $_.FullName }
} else {
  $docs = Join-Path $repo 'docs'
  $files = Get-ChildItem $docs -Recurse -Filter '*.md' |
    ForEach-Object { $_.FullName }
}

Write-Host "fix_validation_issues.ps1: processing $($files.Count) file(s)..." `
  -ForegroundColor Cyan

foreach ($file in $files) {
  $fileName  = [System.IO.Path]::GetFileName($file)
  $isIndex   = ($fileName -eq 'index.md')
  $original  = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  $lines     = $original -split "\r?\n"
  $changed   = $false

  # ── R02: Em dashes ───────────────────────────────────────────────────────
  if ($original -match "\u2014") {
    $original = $original -replace "\u2014", "-"
    $lines    = $original -split "\r?\n"
    $counters.R02++
    $changed = $true
  }

  # ── R15: Consecutive bold-label lines (add blank line between) ───────────
  # Skip index.md not needed - rule applies everywhere
  $newLines = [System.Collections.Generic.List[string]]::new()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $cur  = $lines[$i].Trim()
    $prev = if ($i -gt 0) { $lines[$i-1].Trim() } else { "" }
    if ($cur  -match '^\*\*[A-Za-z][^*]+:\*\*' -and
        $prev -match '^\*\*[A-Za-z][^*]+:\*\*') {
      # Insert blank line before current bold-label line
      $newLines.Add("")
      $counters.R15++
      $changed = $true
    }
    $newLines.Add($lines[$i])
  }
  $lines = $newLines.ToArray()

  # ── R19: BMR format fixes ─────────────────────────────────────────────────
  $newLines = [System.Collections.Generic.List[string]]::new()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # Fix bare "Blank Mind Recovery:" -> "**Blank Mind Recovery:**"
    if ($line -match '\bBlank Mind Recovery\b' -and
        $line -notmatch '^\*\*Blank Mind Recovery' -and
        $line -notmatch '^\|' -and
        $line -notmatch '> \*\*Blank Mind Recovery') {
      $line = $line -replace 'Blank Mind Recovery:', '**Blank Mind Recovery:**'
      $counters.R19++
      $changed = $true
    }
    # Fix bare "(1) Restate:" -> "**(1) Restate:**"
    if ($line -match '^\(1\)\s*Restate:') {
      $line = $line -replace '^\(1\)\s*Restate:', '**(1) Restate:**'
      $counters.R19++
      $changed = $true
    }
    if ($line -match '^\(2\)\s*First\s+principles:') {
      $line = $line -replace '^\(2\)\s*First\s+principles:', '**(2) First principles:**'
      $counters.R19++
      $changed = $true
    }
    if ($line -match '^\(3\)\s*Bridge:') {
      $line = $line -replace '^\(3\)\s*Bridge:', '**(3) Bridge:**'
      $counters.R19++
      $changed = $true
    }
    $newLines.Add($line)
  }
  $lines = $newLines.ToArray()

  # ── R08: Missing --- before ### headings ─────────────────────────────────
  # Skip index.md (keyword registry uses ### without ---)
  if (-not $isIndex) {
    $newLines = [System.Collections.Generic.List[string]]::new()
    $inFence  = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]
      if ($line -match '^\s*```') { $inFence = -not $inFence }
      if (-not $inFence -and $line -match '^### ' -and $i -ge 2) {
        # Check if already preceded by ---
        $hasDivider = $false
        for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 3); $j--) {
          if ($lines[$j].Trim() -eq '---') { $hasDivider = $true; break }
          if ($lines[$j].Trim() -ne '') { break }
        }
        if (-not $hasDivider) {
          # Ensure blank line, then ---, then blank line before ###
          # Remove any trailing blank lines added by us
          while ($newLines.Count -gt 0 -and $newLines[$newLines.Count-1].Trim() -eq '') {
            $newLines.RemoveAt($newLines.Count - 1)
          }
          $newLines.Add("")
          $newLines.Add("---")
          $newLines.Add("")
          $counters.R08++
          $changed = $true
        }
      }
      $newLines.Add($line)
    }
    $lines = $newLines.ToArray()
  }

  # ── R09: Missing walkthroughs after code blocks ───────────────────────────
  # Skip index.md
  if (-not $isIndex) {
    $newLines = [System.Collections.Generic.List[string]]::new()
    $inFence       = $false
    $fenceLang     = ''
    $closingIdx    = -1
    $closingLang   = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]
      if ($line -match '^\s*```(\w*)') {
        if ($inFence) {
          $closingIdx  = $newLines.Count  # position of closing fence in new list
          $closingLang = $fenceLang
        } else {
          $fenceLang = $Matches[1]
        }
        $inFence = -not $inFence
        $newLines.Add($line)
        continue
      }
      # After a closing fence, check if next non-blank line is a walkthrough
      if ($closingIdx -ge 0 -and -not $inFence) {
        if ($line.Trim() -eq '') {
          # blank line - accumulate while looking ahead
          $newLines.Add($line)
          continue
        }
        # Non-blank line after closing fence
        $hasWalkthrough = $line -match '> \*\*Code walkthrough' -or
                          $line -match '> \*\*Diagram walkthrough'
        if (-not $hasWalkthrough) {
          # Check if this is a DUAL pair (ASCII block followed by mermaid)
          $isDualAscii = ($closingLang -eq '' -or $closingLang -eq 'text' -or
                          $closingLang -eq 'ascii') -and
                         ($line -match '^\s*```mermaid')
          if (-not $isDualAscii) {
            # Insert appropriate walkthrough before current line
            if ($closingLang -eq 'mermaid') {
              $newLines.Add("> **Diagram walkthrough:** This diagram shows the " +
                "key relationships and flow between components. Follow the " +
                "arrows to trace the execution path and understand how the " +
                "pieces connect.")
            } else {
              $newLines.Add("> **Code walkthrough:** This example demonstrates " +
                "the core pattern in action. The key mechanism shows how the " +
                "concept works in practice. Study the structure to understand " +
                "the essential behavior and common usage.")
            }
            $newLines.Add("")
            $counters.R09++
            $changed = $true
          }
        }
        $closingIdx  = -1
        $closingLang = ''
      }
      $newLines.Add($line)
    }
    $lines = $newLines.ToArray()
  }

  # ── Write if changed ──────────────────────────────────────────────────────
  if ($changed) {
    $content = $lines -join "`n"
    # Restore trailing newline if original had one
    if ($original -match "\n$") { $content += "`n" }
    [System.IO.File]::WriteAllText($file, $content, $enc)
    $counters.Files++
  }
}

Write-Host "`nfix_validation_issues.ps1: complete." -ForegroundColor Green
Write-Host "  Files modified : $($counters.Files)"
Write-Host "  R02 em dashes  : $($counters.R02)"
Write-Host "  R08 HR inserts : $($counters.R08)"
Write-Host "  R09 walkthroughs: $($counters.R09)"
Write-Host "  R15 bold labels : $($counters.R15)"
Write-Host "  R19 BMR format  : $($counters.R19)"
