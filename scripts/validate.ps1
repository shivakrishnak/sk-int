#requires -Version 7.0
<#
.SYNOPSIS
  Validate staged or specified docs/*.md files against the SK Interview rules.

.DESCRIPTION
  Validator invoked by the pre-commit hook and by CI.
  Rule definitions live in scripts/file_validation_rules.ps1 (14 rules):
    R01 No BOM
    R02 No em dashes
    R03 No [TODO:/[FILL: stub markers in completed files
    R04 frontmatter version: 1 (not 3 - historical bug, now enforced)
    R05 No @fill-content refs (prompt deleted; use @generate-entries)
    R06 Code lines max 70 chars
    R07 ASCII diagram lines max 59 chars
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
  [string[]]$Path
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

foreach ($file in $files) {
  $errs = @(Invoke-FileValidation -FilePath $file)
  if ($errs.Count -gt 0) {
    Write-Host "FAIL: $file" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host "  - $_" }
    $exitCode = 1
  }
}

if ($exitCode -eq 0) {
  Write-Host 'validate.ps1: all checks passed.' -ForegroundColor Green
}

exit $exitCode
