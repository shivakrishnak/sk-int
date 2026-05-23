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
  - northstar/_config/file_validation_rules.ps1 (ported: NO_SECRETS, BOLD_LABEL_NO_BLANK,
    QRC_BORDER_BROKEN, HIGH_REPETITION, github_pat_ secret pattern;
    LineNumber bug fix for Select-String on piped arrays;
    R12 difficulty detection fix: 'difficulty.*medium' -> 'Interview Weight.*medium';
    R12 inter-keyword bleed fix: reset $keywordDifficulty at each H1 separator)

  Known validator bug (fixed here):
  Do NOT use Select-String.LineNumber on piped string arrays - it always
  returns 1. Use a for-loop with explicit index to get correct 1-based line
  numbers. (Documented in northstar validator.)
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
# NOTE: Select-String.LineNumber is always 1 when piping a string array.
# Use a for-loop for correct 1-based line numbers.
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoEmDash {
  param([string]$FilePath, [string[]]$Lines)
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match "\u2014") {
      $errs += "R02 EM-DASH: line $($i+1): $($Lines[$i].Trim())"
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R03 - No stub markers in completed files
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoStubMarkers {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '\[TODO:|\[FILL:') {
      $errs += "R03 STUB: line $($i+1): unfilled marker: $($Lines[$i].Trim())"
    }
  }
  return $errs
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
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '@fill-content|fill-content\.prompt') {
      $errs += "R05 STALE-REF: line $($i+1): '@fill-content' no longer " +
               "exists - use '@generate-entries' instead: $($Lines[$i].Trim())"
    }
  }
  return $errs
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
# Counts lines starting with **[LEVEL] (e.g. **[JUNIOR] Q1 - ...)
# Minimum: 7 (easy), 9 (medium), 12 (hard) - checked per-section.
#
# Bug fix: old detection used 'difficulty.*medium' but actual format is
# '**Interview Weight:** medium'. Now detects 'Interview Weight.*medium'
# or 'Interview Weight.*hard' / 'Interview Weight.*easy'.
# Also resets $keywordDifficulty = 'easy' at each new H1 (keyword separator)
# so difficulty from kw1 does not bleed into kw2.
# ─────────────────────────────────────────────────────────────────────────────
function Test-DeepDiveQuestionCount {
  param([string[]]$Lines, [string]$FilePath)
  # Skip index.md
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  $errs = @()
  $inDeepDive = $false
  $qCount = 0
  $sectionStart = 0
  $keywordDifficulty = 'easy'  # default; reset at each H1 separator
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    # Reset difficulty at each new keyword (H1 separator)
    if ($line -match '^# ') {
      $keywordDifficulty = 'easy'
    }
    if ($line -match '^### 🎯 Interview Deep-Dive') {
      $inDeepDive = $true
      $qCount = 0
      $sectionStart = $i + 1
      continue
    }
    if ($inDeepDive) {
      # End of section = next ### or H1/H2, or end of file
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
      # Count question lines: **[LEVEL] Q... format
      if ($line -match '^\*\*\[' -or $line -match '^\d+\.\s+\*\*\[') {
        $qCount++
      }
    }
    # Detect difficulty from 'Interview Weight:' line (actual content format)
    # or from legacy 'difficulty:' frontmatter pattern.
    # Priority: hard > medium > easy (checked in order)
    if ($line -match 'Interview Weight.*\bhard\b|difficulty.*hard|★★★') {
      $keywordDifficulty = 'hard'
    } elseif ($line -match 'Interview Weight.*\bmedium\b|difficulty.*medium|★★☆') {
      $keywordDifficulty = 'medium'
    } elseif ($line -match 'Interview Weight.*\beasy\b|difficulty.*easy|★☆☆') {
      $keywordDifficulty = 'easy'
    }
  }
  # Flush final section if file ended inside Deep-Dive
  if ($inDeepDive) {
    $minQ = if ($keywordDifficulty -eq 'hard') { 12 }
            elseif ($keywordDifficulty -eq 'medium') { 9 }
            else { 7 }
    if ($qCount -lt $minQ) {
      $errs += "R12 DEEP-DIVE-QS: Interview Deep-Dive at line $sectionStart " +
               "has $qCount questions (min $minQ for $keywordDifficulty)"
    }
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
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '19 sections?|19-section') {
      $errs += "R13 STALE-LANG: line $($i+1): '19 sections' is wrong - " +
               "use '8 Option C sections': $($Lines[$i].Trim())"
    }
  }
  return $errs
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
    for ($i = 0; $i -lt $Lines.Count; $i++) {
      if ($Lines[$i] -match $pattern) {
        $errs += "R14 OLD-NAMING: line $($i+1): stale file name pattern " +
                 "'$pattern' - use L0/L1/L5/META naming: $($Lines[$i].Trim())"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R15 - Consecutive bold-label lines must be separated by a blank line
# Ported from northstar BOLD_LABEL_NO_BLANK rule.
# Spec: "Bold-label lines (**LABEL:** value) must each be separated by a blank
# line." MkDocs merges consecutive paragraph lines without blank separator.
# IMPORTANT: check body[$i-1] directly (NOT a prevTrimmed variable) - two
# bold-labels separated by a blank line must NOT fire.
# ─────────────────────────────────────────────────────────────────────────────
function Test-BoldLabelBlankSeparator {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    $cur  = $Lines[$i].Trim()
    $prev = $Lines[$i - 1].Trim()
    if ($cur  -match '^\*\*[A-Za-z][^*]+:\*\*' -and
        $prev -match '^\*\*[A-Za-z][^*]+:\*\*') {
      $errs += "R15 BOLD-LABEL: line $($i+1): consecutive **LABEL:** lines " +
               "with no blank separator. MkDocs merges them: $cur"
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R16 - No real-looking secret strings
# Ported from northstar NO_SECRETS rule.
# GitHub secret scanning blocks git push on files matching known secret patterns
# even in educational/example code. Checked inside AND outside code fences.
# Safe placeholders (break scanner regex):
#   AKIA_YOUR_KEY_EXAMPLE   sk_live_YOUR_KEY_HERE
#   ghp_YOUR_GITHUB_TOKEN   AIza_YOUR_GOOGLE_API_KEY
# Real case: northstar SEC-046 had AKIAIOSFODNN7EXAMPLE (AWS docs example)
# which matched the AWS scanner pattern and blocked git push.
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoSecrets {
  param([string[]]$Lines)
  $errs = @()
  $secretPatterns = @(
    @{ re = 'AKIA[A-Z0-9]{16,}';              name = 'AWS Access Key ID (AKIA...)' },
    @{ re = 'sk_live_[0-9a-zA-Z]{24,}';       name = 'Stripe live key (sk_live_...)' },
    @{ re = 'ghp_[a-zA-Z0-9]{36,}';           name = 'GitHub PAT (ghp_...)' },
    @{ re = 'github_pat_[a-zA-Z0-9_]{82,}';   name = 'GitHub fine-grained PAT' },
    @{ re = 'AIza[0-9A-Za-z_-]{35}';          name = 'Google API key (AIza...)' }
  )
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    foreach ($sp in $secretPatterns) {
      if ($Lines[$i] -cmatch $sp.re) {
        $snippet = $Lines[$i].Trim()
        $errs += "R16 SECRET: line $($i+1): $($sp.name) pattern detected - " +
                 "replace with safe placeholder (e.g. AKIA_YOUR_KEY_EXAMPLE): " +
                 "$($snippet.Substring(0,[Math]::Min(60,$snippet.Length)))"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R17 - QRC box-drawing characters form proper closed boxes
# Ported from northstar QRC_BORDER_BROKEN rule.
# ASCII Quick Reference Card boxes use ┌┐└┘├┤│. Malformed boxes render
# as broken visual garbage in MkDocs and are nearly impossible to read.
#
# IMPORTANT FALSE-POSITIVE GUARD:
# ASCII file-tree diagrams use ├── and └── (tree branches) which look like
# box chars but are NOT QRC borders. Only enter box-detection mode when a
# valid top border ┌...┐ is found. ├ and └ checks ONLY apply inside a real box.
#
# Checks:
#   ┌...┐  top border - activates box detection; must end with ┐
#   └...┘  bottom border - closes box detection; must end with ┘
#   ├...┤  divider row - only inside box; must end with ┤
#   │...│  content lines - only inside box; must start AND end with │
#   Every ┌ must have a matching └ before end of fence
# ─────────────────────────────────────────────────────────────────────────────
function Test-QrcBorderIntegrity {
  param([string[]]$Lines)
  $errs = @()
  $inBoxArt  = $false
  $boxOpenLine = -1
  $inFence   = $false
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line    = $Lines[$i]
    $trimmed = $line.Trim()
    $lineNum = $i + 1
    # Track code fences - boxes can appear inside or outside fences
    if ($line -match '^\s*```') { $inFence = -not $inFence }
    if ($line -match '^\u250c' -and $line -match '\u2510$') {
      # ┌...┐ valid top border
      if ($inBoxArt) {
        $errs += "R17 QRC-BOX: line ${lineNum}: new \u250c opened before " +
                 "previous box at line $boxOpenLine was closed with └"
      }
      $inBoxArt    = $true
      $boxOpenLine = $lineNum
    } elseif ($line -match '^\u250c' -and $line -notmatch '\u2510$') {
      # ┌ without matching ┐
      if ($inBoxArt) {
        $errs += "R17 QRC-BOX: line ${lineNum}: \u250c border does not end with \u2510: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
      # else: likely a tree root line outside a box - ignore
    } elseif ($inBoxArt -and $line -match '^\u2514') {
      # └ bottom border - only inside confirmed box
      if ($line -notmatch '\u2518$') {
        $errs += "R17 QRC-BOX: line ${lineNum}: \u2514 border does not end with \u2518: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
      $inBoxArt    = $false
      $boxOpenLine = -1
    } elseif ($inBoxArt -and $line -match '^\u251c') {
      # ├ divider - only inside confirmed box
      if ($line -notmatch '\u2524$') {
        $errs += "R17 QRC-BOX: line ${lineNum}: \u251c divider does not end with \u2524: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
    } elseif ($inBoxArt) {
      # Content row must start and end with │ (allow blank rows)
      if ($trimmed -ne '' -and $line -notmatch '^\u2502') {
        $errs += "R17 QRC-BOX: line ${lineNum}: line inside box does not " +
                 "start with \u2502: $($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
        $inBoxArt = $false  # reset to avoid cascade
      } elseif ($line -match '^\u2502' -and $line -notmatch '\u2502$') {
        $errs += "R17 QRC-BOX: line ${lineNum}: box content line starts " +
                 "with │ but does not end with │: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
    }
  }
  # Unclosed box at end of file
  if ($inBoxArt) {
    $errs += "R17 QRC-BOX: box opened at line $boxOpenLine was never " +
             "closed with └...┘"
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R18 - No verbatim paragraph duplication within a file
# Ported from northstar HIGH_REPETITION rule (v6.0 opt-in; always-on here).
# Detects 50+ character lines that appear verbatim 2+ times in the same file.
# Real causes: copy-paste of boilerplate between keywords; accidental duplicate
# section rendering. One error per file to avoid flooding.
# Exclusions: code fence lines, short lines, separator lines (---)
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoDuplicateLines {
  param([string[]]$Lines, [string]$FilePath)
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  $errs = @()
  $inFence = $false
  $seen    = [System.Collections.Generic.Dictionary[string,int]]::new(
               [System.StringComparer]::Ordinal)
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
    if ($inFence) { continue }
    $key = $line.Trim()
    # Only prose lines: length >= 50, not a heading, HR, or blank
    if ($key.Length -lt 50) { continue }
    if ($key -match '^#|^---|^\*\*\[|^>') { continue }
    if ($seen.ContainsKey($key)) {
      $errs += "R18 DUPLICATE: line $($i+1): verbatim duplicate of line " +
               "$($seen[$key]+1): $($key.Substring(0,[Math]::Min(60,$key.Length)))..."
      break  # one warning per file is enough
    }
    $seen[$key] = $i
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
  $errs += Test-BoldLabelBlankSeparator -Lines $lines
  $errs += Test-NoSecrets              -Lines $lines
  $errs += Test-QrcBorderIntegrity     -Lines $lines
  $errs += Test-NoDuplicateLines       -Lines $lines -FilePath $FilePath
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
  Test-BoldLabelBlankSeparator, Test-NoSecrets,
  Test-QrcBorderIntegrity, Test-NoDuplicateLines,
  Test-NoNineteenSections, Test-NoOldFileNaming
