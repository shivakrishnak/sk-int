#requires -Version 7.0
<#
.SYNOPSIS
  Validation rule functions for SK Interview docs/*.md files.
  Imported by validate.ps1. Can also be run standalone.

.DESCRIPTION
  Each exported function validates one rule class.
  Returns an array of [string] error messages (empty = pass).
  Encode all files UTF-8 NoBOM before calling.

  Rules encoded from:
  - .github/instructions/interview.instructions.md (formatting rules)
  - .github/copilot-instructions.md (workspace shared rules)
  - /memories/repo/content-generation.md (learned from sessions)
  - SPEC_VERSION = 1 (interview_content_generator.md)
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────────────────
# RULE R01 - No BOM
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoBOM {
  param([string]$FilePath)
  $bytes = [System.IO.File]::ReadAllBytes($FilePath)
  if ($bytes.Length -ge 3 -and
      $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    return "R01 BOM: file has UTF-8 BOM - must be UTF-8 without BOM"
  }
  return $null
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R02 - No em dashes
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoEmDash {
  param([string]$FilePath, [string[]]$Lines)
  $hits = $Lines | Select-String -Pattern '—' -SimpleMatch
  if ($hits) {
    return ($hits | ForEach-Object {
      "R02 EM-DASH: line $($_.LineNumber): $($_.Line.Trim())"
    })
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R03 - No stub markers in completed files
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoStubMarkers {
  param([string[]]$Lines)
  $hits = $Lines | Select-String -Pattern '\[TODO:|^\[FILL:' -SimpleMatch
  if ($hits) {
    return ($hits | ForEach-Object {
      "R03 STUB: line $($_.LineNumber): unfilled marker: $($_.Line.Trim())"
    })
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R04 - version: 1 (not version: 3 or any other value)
# Lesson: version: 3 was an old bug in interview.instructions.md (fixed).
# Canonical value is version: 1 matching SPEC_VERSION constant.
# ─────────────────────────────────────────────────────────────────────────────
function Test-FrontmatterVersion {
  param([string[]]$Lines)
  $errs = @()
  # Only check files that have frontmatter
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $versionLine = $Lines | Select-String -Pattern '^version:\s*\d' |
                   Select-Object -First 1
  if ($versionLine) {
    if ($versionLine.Line -notmatch '^version:\s*1\s*$') {
      $errs += "R04 VERSION: frontmatter 'version:' must be 1 " +
               "(found: $($versionLine.Line.Trim())). " +
               "SPEC_VERSION=1 is canonical."
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R05 - No @fill-content references (prompt deleted; use @generate-entries)
# Lesson M8: fill-content.prompt.md was merged into generate-entries and deleted.
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoFillContentRef {
  param([string[]]$Lines)
  $hits = $Lines | Select-String -Pattern '@fill-content|fill-content\.prompt' -SimpleMatch
  if ($hits) {
    return ($hits | ForEach-Object {
      "R05 STALE-REF: line $($_.LineNumber): '@fill-content' no longer " +
      "exists - use '@generate-entries' instead: $($_.Line.Trim())"
    })
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R06 - Code lines max 70 characters
# ─────────────────────────────────────────────────────────────────────────────
function Test-CodeLineLength {
  param([string[]]$Lines)
  $errs = @()
  $inFence = $false
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
    if ($inFence -and $line.Length -gt 70) {
      $errs += "R06 CODE-LEN: line $($i+1) is $($line.Length) chars " +
               "(max 70 in code blocks): $($line.Substring(0,[Math]::Min(60,$line.Length)))..."
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R07 - ASCII diagrams max 59 characters wide
# Detects lines inside ```
# block that look like ASCII art (contain box-drawing or +/-/| chars)
# ─────────────────────────────────────────────────────────────────────────────
function Test-AsciiDiagramWidth {
  param([string[]]$Lines)
  $errs = @()
  $inFence = $false
  $fenceLang = ''
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*```(\w*)') {
      if (-not $inFence) { $fenceLang = $Matches[1] }
      $inFence = -not $inFence
      continue
    }
    # Only check unlabelled fences or ones explicitly named 'text'/'ascii'
    if ($inFence -and ($fenceLang -eq '' -or $fenceLang -eq 'text' -or
                        $fenceLang -eq 'ascii') -and $line.Length -gt 59) {
      if ($line -match '[+\-|<>─│┌┐└┘┬┴├┤┼←→↑↓]') {
        $errs += "R07 ASCII-WIDTH: line $($i+1) is $($line.Length) chars " +
                 "(max 59 for ASCII diagrams)"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R08 - Every ### heading preceded by --- (with blank lines)
# ─────────────────────────────────────────────────────────────────────────────
function Test-H3PrecededByHR {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 2; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^### ') {
      # Look back for '---' within 3 lines (blank lines may intervene)
      $found = $false
      for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 3); $j--) {
        if ($Lines[$j].Trim() -eq '---') { $found = $true; break }
        if ($Lines[$j].Trim() -ne '') { break }  # non-blank non-HR = fail
      }
      if (-not $found) {
        $errs += "R08 H3-HR: line $($i+1): '###' heading not preceded by '---': $($Lines[$i].Trim())"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R09 - Code walkthrough after code blocks
# Every closing ``` in a content file should be followed (within 3 lines)
# by > **Code walkthrough:** text.
# Lesson P5: this rule was missing from all spec files (now added).
# ─────────────────────────────────────────────────────────────────────────────
function Test-CodeWalkthrough {
  param([string[]]$Lines, [string]$FilePath)
  # Skip index.md files - they have code blocks in frontmatter examples
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  $errs = @()
  $inFence = $false
  $closingLineNum = -1
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*```') {
      if ($inFence) {
        # This is a closing fence
        $closingLineNum = $i
      }
      $inFence = -not $inFence
    }
    if ($closingLineNum -gt 0 -and -not $inFence) {
      # Check within next 3 lines for Code walkthrough
      $found = $false
      $end = [Math]::Min($Lines.Count - 1, $closingLineNum + 4)
      for ($k = $closingLineNum + 1; $k -le $end; $k++) {
        if ($Lines[$k] -match '> \*\*Code walkthrough') { $found = $true; break }
        if ($Lines[$k] -match '^\s*```') { break }  # another fence starts
      }
      if (-not $found) {
        $errs += "R09 WALKTHROUGH: line $($closingLineNum+1): code block not " +
                 "followed by '> **Code walkthrough:**' within 3 lines"
      }
      $closingLineNum = -1
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R10 - DUAL diagram format: every ```mermaid block must be preceded
# by a plain code block (ASCII diagram) within 30 lines.
# ─────────────────────────────────────────────────────────────────────────────
function Test-DualDiagramFormat {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*```mermaid') {
      # Search backward up to 30 lines for an ASCII diagram block
      $found = $false
      for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 30); $j--) {
        if ($Lines[$j] -match '^\s*```\s*$' -or
            $Lines[$j] -match '^\s*```text' -or
            $Lines[$j] -match '^\s*```ascii') {
          $found = $true; break
        }
      }
      if (-not $found) {
        $errs += "R10 DUAL-DIAGRAM: line $($i+1): mermaid block not preceded " +
                 "by ASCII diagram block within 30 lines"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R11 - BAD pattern before GOOD pattern in code examples
# Each file with code examples should have BAD before GOOD.
# Heuristic: if a GOOD block appears, a BAD block must appear before it
# in the same section (within 40 lines).
# ─────────────────────────────────────────────────────────────────────────────
function Test-BadBeforeGood {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '//\s*GOOD|#\s*GOOD|<!--\s*GOOD') {
      $found = $false
      for ($j = [Math]::Max(0, $i - 40); $j -lt $i; $j++) {
        if ($Lines[$j] -match '//\s*BAD|#\s*BAD|<!--\s*BAD') {
          $found = $true; break
        }
      }
      if (-not $found) {
        $errs += "R11 BAD-BEFORE-GOOD: line $($i+1): GOOD pattern found " +
                 "without BAD pattern in preceding 40 lines"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R12 - Interview Deep-Dive minimum question count
# Files with Interview Deep-Dive section must have enough questions.
# Counts lines matching "^[0-9]+\." or "^\*\*Q[0-9]" in Deep-Dive sections.
# Minimum: 7 (easy), 9 (medium), 12 (hard) - checked per-section.
# ─────────────────────────────────────────────────────────────────────────────
function Test-DeepDiveQuestionCount {
  param([string[]]$Lines, [string]$FilePath)
  # Skip index.md
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  $errs = @()
  $inDeepDive = $false
  $qCount = 0
  $sectionStart = 0
  $keywordDifficulty = 'easy'  # default
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^### 🎯 Interview Deep-Dive') {
      $inDeepDive = $true
      $qCount = 0
      $sectionStart = $i + 1
      continue
    }
    if ($inDeepDive) {
      # End of section = next H3 that is not part of Deep-Dive,
      # or next H1/H2, or end of file
      if ($line -match '^### ' -or $line -match '^## ' -or $line -match '^# ') {
        # Evaluate count
        $minQ = if ($keywordDifficulty -eq 'hard') { 12 }
                elseif ($keywordDifficulty -eq 'medium') { 9 }
                else { 7 }
        if ($qCount -lt $minQ) {
          $errs += "R12 DEEP-DIVE-QS: Interview Deep-Dive at line $sectionStart " +
                   "has $qCount questions (min $minQ for $keywordDifficulty)"
        }
        $inDeepDive = $false
      }
      # Count question lines - look for **Q or numbered bold questions
      if ($line -match '^\*\*\[' -or $line -match '^\d+\.\s+\*\*\[') {
        $qCount++
      }
    }
    # Detect difficulty from surrounding context
    if ($line -match 'difficulty.*hard|★★★') { $keywordDifficulty = 'hard' }
    elseif ($line -match 'difficulty.*medium|★★☆') { $keywordDifficulty = 'medium' }
    elseif ($line -match 'difficulty.*easy|★☆☆') { $keywordDifficulty = 'easy' }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R13 - No "19 sections" / "19-section" language in spec files
# Lesson M7: The 19 CGR items are content RULES, not output headings.
# The correct phrase is "8 Option C sections".
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoNineteenSections {
  param([string[]]$Lines)
  $hits = $Lines | Select-String -Pattern '19 sections?|19-section' -SimpleMatch
  if ($hits) {
    return ($hits | ForEach-Object {
      "R13 STALE-LANG: line $($_.LineNumber): '19 sections' is wrong - " +
      "use '8 Option C sections': $($_.Line.Trim())"
    })
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R14 - Old file naming patterns must not appear in spec/instruction files
# Lesson M6: 'Foundations.md' (L0+L1 combined) and
#            'Architecture and Strategy.md' are the OLD naming convention.
# Correct: L0 Orientation.md, L1 Foundations.md, L5 Architecture.md
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoOldFileNaming {
  param([string[]]$Lines, [string]$FilePath)
  # Only check spec and instruction files, not docs content
  if ($FilePath -match '\\docs\\') { return @() }
  $errs = @()
  $oldPatterns = @(
    'Architecture and Strategy\.md',
    'Getting Started\.md'
    # Note: "Foundations.md" alone is fine (L1 Foundations.md uses it)
    # The old pattern was a STANDALONE Foundations.md combining L0+L1
  )
  foreach ($pattern in $oldPatterns) {
    $hits = $Lines | Select-String -Pattern $pattern
    if ($hits) {
      $errs += ($hits | ForEach-Object {
        "R14 OLD-NAMING: line $($_.LineNumber): stale file name pattern " +
        "'$pattern' - use L0/L1/L5/META naming: $($_.Line.Trim())"
      })
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RUNNER - invoke all rules against a file
# ─────────────────────────────────────────────────────────────────────────────
function Invoke-FileValidation {
  param([string]$FilePath)
  $lines = [System.IO.File]::ReadAllLines($FilePath)
  $errs = @()
  $errs += Test-NoBOM          -FilePath $FilePath
  $errs += Test-NoEmDash       -FilePath $FilePath -Lines $lines
  $errs += Test-NoStubMarkers  -Lines $lines
  $errs += Test-FrontmatterVersion -Lines $lines
  $errs += Test-NoFillContentRef   -Lines $lines
  $errs += Test-CodeLineLength     -Lines $lines
  $errs += Test-AsciiDiagramWidth  -Lines $lines
  $errs += Test-H3PrecededByHR     -Lines $lines
  $errs += Test-CodeWalkthrough    -Lines $lines -FilePath $FilePath
  $errs += Test-DualDiagramFormat  -Lines $lines
  $errs += Test-BadBeforeGood      -Lines $lines
  $errs += Test-DeepDiveQuestionCount -Lines $lines -FilePath $FilePath
  # Spec/instruction files only:
  if ($FilePath -match '\.(github|spec)\\') {
    $errs += Test-NoNineteenSections -Lines $lines
    $errs += Test-NoOldFileNaming    -Lines $lines -FilePath $FilePath
  }
  return $errs | Where-Object { $_ }
}

# ─────────────────────────────────────────────────────────────────────────────
# STANDALONE MODE - run against a single file if called directly
# ─────────────────────────────────────────────────────────────────────────────
if ($MyInvocation.InvocationName -ne '.') {
  param([string]$File)
  if ($File) {
    $errs = Invoke-FileValidation -FilePath $File
    if ($errs) {
      $errs | ForEach-Object { Write-Host $_ -ForegroundColor Red }
      exit 1
    }
    Write-Host "PASS: $File" -ForegroundColor Green
    exit 0
  }
}

Export-ModuleMember -Function Invoke-FileValidation, Test-NoBOM,
  Test-NoEmDash, Test-NoStubMarkers, Test-FrontmatterVersion,
  Test-NoFillContentRef, Test-CodeLineLength, Test-AsciiDiagramWidth,
  Test-H3PrecededByHR, Test-CodeWalkthrough, Test-DualDiagramFormat,
  Test-BadBeforeGood, Test-DeepDiveQuestionCount,
  Test-NoNineteenSections, Test-NoOldFileNaming
