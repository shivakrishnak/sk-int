#!/usr/bin/env pwsh
# scripts/add_keyword_nav.ps1
# Adds "## Keywords in This File" navigation table to every content file
# under docs/ that does not already have one.
# Usage:  pwsh scripts/add_keyword_nav.ps1
# Safe to re-run: skips files that already contain the nav block.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$enc = [System.Text.UTF8Encoding]::new($false) # UTF-8 without BOM

# ── Anchor generation (matches kramdown/Jekyll rules) ──────────────────────
function Get-KramdownAnchor([string]$heading) {
    $t = $heading -replace '^#+\s*', ''   # strip leading # chars
    $t = $t.ToLower()
    $t = $t -replace '\s', '-'            # each space -> hyphen
    $t = $t -replace '[^a-z0-9\-]', ''   # remove all other chars
    # NOTE: consecutive hyphens are preserved (kramdown does not collapse)
    return $t.Trim('-')
}

# ── Extract difficulty label from Interview Weight line ────────────────────
function Get-Difficulty([string]$iwLine) {
    if ($iwLine -match '\*\*Interview Weight:\*\*\s*([\w\-]+)') {
        return $matches[1].ToLower()
    }
    return 'medium'
}

# ── Process one file ────────────────────────────────────────────────────────
function Add-KeywordNav([string]$filePath) {
    $name = Split-Path $filePath -Leaf
    $lines = [System.IO.File]::ReadAllLines($filePath)

    # Skip index files
    if ($name -eq 'index.md') { return }

    # Find end of frontmatter (second ---)
    $fmEnd = -1; $dashCount = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            $dashCount++
            if ($dashCount -ge 2) { $fmEnd = $i; break }
        }
    }
    if ($fmEnd -lt 0) {
        Write-Host "SKIP (no frontmatter): $name" -ForegroundColor DarkGray
        return
    }

    # Skip if nav block already exists in first 30 lines after frontmatter
    $limit = [Math]::Min($fmEnd + 31, $lines.Count)
    for ($i = $fmEnd + 1; $i -lt $limit; $i++) {
        if ($lines[$i] -match '^## Keywords in This File') {
            Write-Host "SKIP (already has nav): $name" -ForegroundColor DarkGray
            return
        }
    }

    # Extract H1 keywords + difficulty (skip code blocks)
    $keywords    = [System.Collections.Generic.List[string]]::new()
    $difficulties = @{}
    $inFence     = $false
    $lastKw      = $null

    for ($i = $fmEnd + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ($line -match '^# (.+)') {
            $lastKw = $matches[1].Trim()
            $keywords.Add($lastKw) | Out-Null
        }
        if ($lastKw -and
            $line -match 'Interview Weight' -and
            (-not $difficulties.ContainsKey($lastKw))) {
            $difficulties[$lastKw] = Get-Difficulty $line
        }
    }

    if ($keywords.Count -eq 0) {
        Write-Host "SKIP (no H1 keywords): $name" -ForegroundColor Yellow
        return
    }

    # Build navigation table lines
    $nav = [System.Collections.Generic.List[string]]::new()
    $nav.Add('## Keywords in This File')
    $nav.Add('{: .no_toc }')
    $nav.Add('')
    $nav.Add('| # | Keyword | Weight |')
    $nav.Add('|---|---|---|')
    for ($n = 0; $n -lt $keywords.Count; $n++) {
        $kw     = $keywords[$n]
        $anchor = Get-KramdownAnchor $kw
        $diff   = if ($difficulties.ContainsKey($kw)) {
                      $difficulties[$kw]
                  } else { 'medium' }
        $nav.Add("| $($n+1) | [$kw](#$anchor) | $diff |")
    }
    $nav.Add('')
    $nav.Add('---')
    $nav.Add('')

    # Assemble new file: frontmatter + blank + nav block + content
    $newLines = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $lines[0..$fmEnd]) { $newLines.Add($l) }
    $newLines.Add('')
    foreach ($l in $nav) { $newLines.Add($l) }

    # Skip blank lines immediately after frontmatter in original content
    $start = $fmEnd + 1
    while ($start -lt $lines.Count -and $lines[$start].Trim() -eq '') {
        $start++
    }
    if ($start -lt $lines.Count) {
        foreach ($l in $lines[$start..($lines.Count - 1)]) { $newLines.Add($l) }
    }

    # Write UTF-8 without BOM
    [System.IO.File]::WriteAllLines($filePath, $newLines, $enc)
    Write-Host ("UPDATED: $name  [$($keywords.Count) keywords: " +
                "$($keywords -join ', ')]") -ForegroundColor Green
}

# ── Main ────────────────────────────────────────────────────────────────────
$docsPath = Join-Path $PSScriptRoot '..' 'docs'
$files    = Get-ChildItem $docsPath -Recurse -Filter '*.md' |
            Where-Object { $_.Name -ne 'index.md' } |
            Sort-Object FullName

$updated = 0; $skipped = 0
foreach ($f in $files) {
    $before = $updated
    Add-KeywordNav $f.FullName
    if ($updated -gt $before) { } # counted inside function indirectly
    # recount by checking output - just track totals via files
}

Write-Host ''
Write-Host "Done. Processed $($files.Count) files." -ForegroundColor Cyan
