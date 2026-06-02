#requires -Version 7.0
<#
.SYNOPSIS
  Validate staged or specified docs/*.md files against the SK Interview rules.

.DESCRIPTION
  Validator invoked by the pre-commit hook and by CI.
  Rule definitions live in scripts/file_validation_rules.ps1 (29 rules):
    R01 No BOM
    R02 No em dashes
    R03 No [TODO:/[FILL: stub markers in completed files
    R04 frontmatter version: 1 (not 3 - historical bug, now enforced)
    R05 No @fill-content refs (prompt deleted; use @generate-entries)
    R06 Code lines max 100 chars
    R07 ASCII diagram lines max 80 chars
    R08 Every ### heading preceded by ---
    R09 Code walkthrough after every code block
    R10 DUAL diagram format (ASCII block before every mermaid block)
    R11 BAD pattern before GOOD in code examples
    R12 Interview Deep-Dive min question count (7/9/12 by difficulty)
    R13 No '19 sections' language in spec files (correct: 8 Option C)
    R14 No old file naming patterns in spec files
    R15 Consecutive bold-label lines separated by blank line
    R16 No real-looking secret strings (AWS, Stripe, GitHub PAT, Google API)
    R17 QRC box-drawing characters form proper closed boxes
    R18 No verbatim paragraph duplication within a file
    R19 Blank Mind Recovery block format (bold labels, separate paragraphs)
    R20 Keyword navigation block present within 30 lines after frontmatter
    R21 ALL 10 sections present per keyword (NON-NEGOTIABLE):
        Model Answer, Concept Explanation, Code Example, Answers by Seniority,
        Common Misconceptions, Failure Modes and Diagnosis, Interview Deep-Dive,
        Comparison Table, System Design, Diagram.
        Conditional sections need explicit OMIT note if not applicable.
        HARD STOP if any section header missing.
    R22 render_with_liquid: false required in every content file frontmatter
        (prevents Liquid parsing of {{ }} and {% %} in code examples)
    R23 No duplicate YAML frontmatter keys (undefined Jekyll/Psych behaviour)
    R24 parent: value must match topic index.md title: exactly
        (prevents orphaned pages with no sidebar entry)
    R25 YAML unsafe tag values - bare @, *, ? in YAML sequences
        (YAML 1.1 reserved chars trigger Ruby Psych parse error)
    R26 Required frontmatter fields present
        Content files: layout, title, parent, nav_order, permalink,
                       render_with_liquid
        Topic index.md: title, nav_order, has_children (NO parent allowed)
    R27 No generic placeholder walkthrough text
        (boilerplate from R09 fix script must be replaced with real explanation)
    R28 Liquid-prone patterns in code blocks must be wrapped with
        {% raw %} / {% endraw %} tags outside the fence
        (Jekyll's Liquid PARSER scans content BEFORE checking
         render_with_liquid: false - unprotected {{ }} or {% %} triggers
         Liquid Exceptions / build failures)
    R29 Jekyll config must use installed gem theme, not remote_theme
        (_config.yml must use 'theme: just-the-docs' not 'remote_theme:';
         Gemfile must not list jekyll-remote-theme;
         remote_theme requires network download and fails locally when
         SSL certificates are missing or GitHub is unreachable)

.PARAMETER FileList
  Path to a text file containing one staged file path per line. Used by
  the pre-commit hook. When omitted, validates all docs/**/*.md files.

.PARAMETER Path
  Direct list of files to validate. Mutually exclusive with -FileList.

.EXAMPLE
  pwsh -File scripts/validate.ps1
  pwsh -File scripts/validate.ps1 -FileList staged.txt
  pwsh -File scripts/validate.ps1 -Path docs/java/Java-Basics.md
#>
[CmdletBinding()]
param(
  [string]$FileList,
  [string[]]$Path,
  [string[]]$IgnoreRules = @()   # e.g. -IgnoreRules R12 to suppress R12 failures
)

$ErrorActionPreference = 'Stop'
$exitCode = 0

# Resolve target files
$files = @()
if ($FileList -and (Test-Path $FileList)) {
  $files = Get-Content $FileList | Where-Object { $_ -and (Test-Path $_) }
}
elseif ($Path) {
  $files = $Path | Where-Object { Test-Path $_ }
}
else {
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $docs = Join-Path $repoRoot 'docs'
  if (Test-Path $docs) {
    $files = Get-ChildItem -Path $docs -Recurse -Filter '*.md' |
      ForEach-Object { $_.FullName }
  }
}

if (-not $files -or $files.Count -eq 0) {
  Write-Host 'validate.ps1: no files to check.' -ForegroundColor DarkGray
  exit 0
}

Write-Host "validate.ps1: checking $($files.Count) file(s)..." `
  -ForegroundColor Cyan

# Load rule functions
$rulesScript = Join-Path $PSScriptRoot 'file_validation_rules.ps1'
if (-not (Test-Path $rulesScript)) {
  Write-Host "ERROR: file_validation_rules.ps1 not found at $rulesScript" `
    -ForegroundColor Red
  exit 1
}
. $rulesScript

# R29 - Project-level Jekyll config check (run once, not per-file)
$repoRootForCfg = Split-Path -Parent $PSScriptRoot
$r29Errs = @(Test-JekyllConfig -RepoRoot $repoRootForCfg)
$r29Ignore = $ignoreList = @(@($IgnoreRules) |
  ForEach-Object { $_ -split '[\s,]+' } | Where-Object { $_ -and $_.Trim() })
if ($r29Ignore.Length -gt 0) {
  $pat = ($r29Ignore | ForEach-Object { [regex]::Escape($_.Trim()) }) -join '|'
  $r29Errs = @($r29Errs | Where-Object { $_ -notmatch "\b($pat)\b" })
}
if ($r29Errs.Length -gt 0) {
  Write-Host "FAIL: _config.yml / Gemfile (project config)" -ForegroundColor Red
  $r29Errs | ForEach-Object { Write-Host "  - $_" }
  $exitCode = 1
}

foreach ($file in $files) {
  $errs = @(Invoke-FileValidation -FilePath $file)
  # Filter out ignored rules (supports comma-separated string or array)
  $ignoreList = @(@($IgnoreRules) | ForEach-Object { $_ -split '[\s,]+' } |
    Where-Object { $_ -and $_.Trim() })
  if ($ignoreList.Length -gt 0) {
    $pattern = ($ignoreList | ForEach-Object { [regex]::Escape($_.Trim()) }) -join '|'
    $errs = @($errs | Where-Object { $_ -notmatch "\b($pattern)\b" })
  }
  if ($errs.Length -gt 0) {
    Write-Host "FAIL: $file" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host "  - $_" }
    $exitCode = 1
  }
}

if ($exitCode -eq 0) {
  Write-Host 'validate.ps1: all checks passed.' -ForegroundColor Green
}

exit $exitCode
