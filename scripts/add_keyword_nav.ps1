#!/usr/bin/env pwsh
# scripts/add_keyword_nav.ps1
# Adds frontmatter (if missing) and "## Keywords in This File" navigation
# table to every content file under docs/ that does not already have one.
# Usage:  pwsh scripts/add_keyword_nav.ps1
# Safe to re-run: skips files that already contain the nav block.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$enc = [System.Text.UTF8Encoding]::new($false) # UTF-8 without BOM

# ── Topic parent titles (from index.md frontmatter) ────────────────────────
$script:TopicTitles = @{}

function Initialize-TopicTitles {
    $docsPath = Join-Path $PSScriptRoot '..' 'docs'
    Get-ChildItem $docsPath -Directory | ForEach-Object {
        $idx = Join-Path $_.FullName 'index.md'
        if (Test-Path $idx) {
            $m = Select-String -Path $idx -Pattern '^title:\s*"?(.+?)"?\s*$' |
                 Select-Object -First 1
            if ($m) {
                $script:TopicTitles[$_.Name] = $m.Matches.Groups[1].Value
            }
        }
    }
}

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

# ── Generate nav_order from filename level band ────────────────────────────
function Get-NavOrder([string]$fileName) {
    if ($fileName -match 'L0') { return 1 }
    if ($fileName -match 'L1') { return 2 }
    if ($fileName -match 'L2.*Creational|L2.*Synch|L2.*Queries|L2.*Map|L2.*Core|L2.*HTTP|L2.*Object|L2.*Functional|L2.*Collections$|L2.*Garbage|L2.*Profiling|L2.*Native|L2.*Polyglot|L2.*Caching|L2.*Relationship|L2.*Data(?!$)|L2.*Boot') { return 3 }
    if ($fileName -match 'L2') { return 4 }
    if ($fileName -match 'L3.*Enterprise|L3.*Thread|L3.*Async|L3.*Internal|L3.*Type|L3.*Modern|L3.*Class|L3.*GC|L3.*CPU|L3.*Memory|L3.*Integration|L3.*Advanced|L3.*Transaction|L3.*Spring|L3.*MVC|L3.*Cloud|L3.*Reactive|L3.*Data') { return 5 }
    if ($fileName -match 'L3') { return 6 }
    if ($fileName -match 'L4') { return 7 }
    if ($fileName -match 'L5') { return 8 }
    if ($fileName -match 'L6') { return 9 }
    if ($fileName -match 'META') { return 10 }
    return 5
}

# ── Generate permalink slug from filename ──────────────────────────────────
function Get-Permalink([string]$folderName, [string]$fileName) {
    $base = $fileName -replace '\.md$', ''
    # Remove topic prefix (e.g., "Design Patterns - " or "GraalVM - ")
    if ($base -match '^.+?\s-\s(.+)$') {
        $slug = $matches[1]
    } else {
        $slug = $base
    }
    $slug = $slug.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', ''
    return "/$folderName/$slug/"
}

# ── Generate frontmatter for a file that lacks it ──────────────────────────
function New-Frontmatter([string]$folderName, [string]$fileName) {
    $base = $fileName -replace '\.md$', ''
    $parent = if ($script:TopicTitles.ContainsKey($folderName)) {
        $script:TopicTitles[$folderName]
    } else { $folderName }
    $navOrder = Get-NavOrder $fileName
    $permalink = Get-Permalink $folderName $fileName

    $fm = @(
        '---'
        "layout: default"
        "title: `"$base`""
        "parent: `"$parent`""
        "grand_parent: `"SK Interview`""
        "nav_order: $navOrder"
        "permalink: $permalink"
        '---'
    )
    return $fm
}

# ── Process one file ────────────────────────────────────────────────────────
function Add-KeywordNav([string]$filePath) {
    $name = Split-Path $filePath -Leaf
    $lines = [System.IO.File]::ReadAllLines($filePath)
    $folderName = Split-Path (Split-Path $filePath -Parent) -Leaf

    # Skip index files
    if ($name -eq 'index.md') { return }

    # Find end of frontmatter (second ---)
    $fmEnd = -1; $dashCount = 0
    $hasFrontmatter = $false
    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') {
                $dashCount++
                if ($dashCount -ge 2) { $fmEnd = $i; $hasFrontmatter = $true; break }
            }
        }
    }

    # Skip if nav block already exists
    $searchStart = if ($hasFrontmatter) { $fmEnd + 1 } else { 0 }
    $limit = [Math]::Min($searchStart + 31, $lines.Count)
    for ($i = $searchStart; $i -lt $limit; $i++) {
        if ($lines[$i] -match '^## Keywords in This File') {
            Write-Host "SKIP (already has nav): $name" -ForegroundColor DarkGray
            return
        }
    }

    # Determine content start (after frontmatter or from line 0)
    $contentStart = if ($hasFrontmatter) { $fmEnd + 1 } else { 0 }

    # Extract H1 keywords + difficulty from content (skip code blocks)
    $keywords    = [System.Collections.Generic.List[string]]::new()
    $difficulties = @{}
    $inFence     = $false
    $lastKw      = $null

    for ($i = $contentStart; $i -lt $lines.Count; $i++) {
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

    # Assemble new file
    $newLines = [System.Collections.Generic.List[string]]::new()

    if ($hasFrontmatter) {
        # Keep existing frontmatter
        foreach ($l in $lines[0..$fmEnd]) { $newLines.Add($l) }
    } else {
        # Generate frontmatter
        $fm = New-Frontmatter $folderName $name
        foreach ($l in $fm) { $newLines.Add($l) }
    }

    $newLines.Add('')
    foreach ($l in $nav) { $newLines.Add($l) }

    # Skip blank lines immediately after frontmatter/start in original content
    $start = $contentStart
    while ($start -lt $lines.Count -and $lines[$start].Trim() -eq '') {
        $start++
    }
    if ($start -lt $lines.Count) {
        foreach ($l in $lines[$start..($lines.Count - 1)]) { $newLines.Add($l) }
    }

    # Write UTF-8 without BOM
    [System.IO.File]::WriteAllLines($filePath, $newLines, $enc)
    Write-Host ("UPDATED: $name  [$($keywords.Count) keywords]") -ForegroundColor Green
    $script:updatedCount++
}

# ── Main ────────────────────────────────────────────────────────────────────
Initialize-TopicTitles
$docsPath = Join-Path $PSScriptRoot '..' 'docs'
$files    = Get-ChildItem $docsPath -Recurse -Filter '*.md' |
            Where-Object { $_.Name -ne 'index.md' } |
            Sort-Object FullName

$script:updatedCount = 0
foreach ($f in $files) {
    Add-KeywordNav $f.FullName
}

Write-Host ''
Write-Host "Done. Updated $($script:updatedCount) files." -ForegroundColor Cyan
Write-Host "Done. Processed $($files.Count) files." -ForegroundColor Cyan
