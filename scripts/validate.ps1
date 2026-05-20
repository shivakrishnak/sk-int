#requires -Version 7.0
<#
.SYNOPSIS
  Validate staged or specified docs/*.md files against the SK Interview rules.

.DESCRIPTION
  Stub validator invoked by the pre-commit hook and by CI.
  Currently performs a smoke check: file exists, starts at byte 0,
  is UTF-8 (no BOM), and contains no em dashes.

  TODO (planned checks - mirror legacy file_validation_rules.ps1):
    - YAML frontmatter presence and required fields (when used)
    - Line length: max 70 chars for code, max 59 for ASCII diagrams
    - DUAL diagram format (ASCII + Mermaid)
    - BAD-before-GOOD pattern in code examples
    - Bold-label lines separated by blank lines
    - Interview Deep-Dive minimum question count (7/9/12)
    - No "[TODO:" or "[FILL:" markers in completed files
    - All `# KEYWORD` headings match `keywords:` list (if frontmatter)

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

foreach ($file in $files) {
  $errors = @()

  # BOM check
  $bytes = [System.IO.File]::ReadAllBytes($file)
  if ($bytes.Length -ge 3 -and
      $bytes[0] -eq 0xEF -and
      $bytes[1] -eq 0xBB -and
      $bytes[2] -eq 0xBF) {
    $errors += 'UTF-8 BOM detected (file must start without BOM)'
  }

  # Em-dash check
  $content = [System.IO.File]::ReadAllText($file)
  if ($content -match [char]0x2014) {
    $errors += 'Em dash (U+2014) found - use regular hyphens only'
  }

  if ($errors.Count -gt 0) {
    Write-Host "FAIL: $file" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  - $e" }
    $exitCode = 1
  }
}

if ($exitCode -eq 0) {
  Write-Host 'validate.ps1: all checks passed.' -ForegroundColor Green
}

exit $exitCode
