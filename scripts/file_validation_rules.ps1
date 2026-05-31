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
# RULE R06 - Code lines max 100 characters
# Excluded block types (inherently long-line formats where wrapping is impractical):
#   mermaid  - node labels use \n for multi-line text
#   bash/sh/shell/zsh/powershell/ps1/console/terminal/output - shell commands
#   yaml/yml/json/xml/toml/ini/properties/csv/dockerfile/docker - config & data
#   text/output/log  - free-form output
# Threshold raised from 70 to 100 to reflect realistic educational content.
# The 70-char guideline was aspirational; 100 still catches truly unreadable lines.
# ─────────────────────────────────────────────────────────────────────────────
# Block types where long lines are structurally unavoidable:
$script:R06_SKIP_LANGS = [System.Collections.Generic.HashSet[string]]::new(
  [string[]]@('mermaid','bash','sh','shell','zsh','powershell','ps1',
              'console','terminal','output','log',
              'yaml','yml','json','xml','toml','ini','properties','csv',
              'dockerfile','docker','text','plaintext'),
  [System.StringComparer]::OrdinalIgnoreCase)
function Test-CodeLineLength {
  param([string[]]$Lines)
  $errs = @()
  $inFence = $false
  $fenceLang = ''
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*```(\w*)') {
      $lang = $Matches[1]
      if (-not $inFence) {
        $fenceLang = $lang; $inFence = $true    # opening fence
      } elseif ($lang -eq '') {
        $inFence = $false; $fenceLang = ''       # bare ``` closes fence
      }
      # labelled fence (e.g. ```java) inside block = content, not a toggle
      continue
    }
    # Skip block types where long lines are structurally unavoidable
    if ($inFence -and (-not $script:R06_SKIP_LANGS.Contains($fenceLang)) -and $line.Length -gt 100) {
      $errs += "R06 CODE-LEN: line $($i+1) is $($line.Length) chars " +
               "(max 100 in code blocks): $($line.Substring(0,[Math]::Min(80,$line.Length)))..."
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R07 - ASCII diagrams max 80 characters wide
# Detects lines inside ``` (unlabelled / text / ascii) blocks that look like
# ASCII art and are wider than 80 chars (fits standard 80-col terminal).
# Threshold raised from 59 to 80: complex multi-column system diagrams
# legitimately need more than 59 chars to be readable.
# ─────────────────────────────────────────────────────────────────────────────
function Test-AsciiDiagramWidth {
  param([string[]]$Lines)
  $errs = @()
  $inFence = $false
  $fenceLang = ''
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^\s*```(\w*)') {
      $lang = $Matches[1]
      if (-not $inFence) {
        $fenceLang = $lang; $inFence = $true    # opening fence
      } elseif ($lang -eq '') {
        $inFence = $false; $fenceLang = ''       # bare ``` closes fence
      }
      # labelled fence inside block = content, not a toggle
      continue
    }
    # Only check unlabelled fences or ones explicitly named 'text'/'ascii'
    if ($inFence -and ($fenceLang -eq '' -or $fenceLang -eq 'text' -or
                        $fenceLang -eq 'ascii') -and $line.Length -gt 80) {
      if ($line -match '[+\-|<>─│┌┐└┘┬┴├┤┼←→↑↓]') {
        $errs += "R07 ASCII-WIDTH: line $($i+1) is $($line.Length) chars " +
                 "(max 80 for ASCII diagrams)"
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R08 - Every ### heading preceded by --- (with blank lines)
# Code-fence-aware: ### inside ``` blocks are not headings (e.g. markdown
# code examples with ## H2 or ### H3 demo content).
# ─────────────────────────────────────────────────────────────────────────────
function Test-H3PrecededByHR {
  param([string[]]$Lines)
  $errs = @()
  $inFence = $false
  for ($i = 2; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*```(\w*)') {
      $l = $Matches[1]
      if (-not $inFence) { $inFence = $true }         # opening fence
      elseif ($l -eq '') { $inFence = $false }        # bare ``` closes
      # labelled fence inside block = content, skip toggle
      continue
    }
    if (-not $inFence -and $Lines[$i] -match '^### ') {
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
# RULE R09 - Walkthrough after code/diagram blocks
# Every closing ``` should be followed (within 3 lines) by:
#   - '> **Code walkthrough:**'   for regular code blocks
#   - '> **Diagram walkthrough:**' for mermaid blocks or ASCII diagram blocks
# For DUAL diagram pairs (ASCII block immediately followed by mermaid within
# 10 lines), the ASCII block does NOT need its own walkthrough - the shared
# walkthrough after the mermaid block is sufficient per spec.
# Lesson P5: this rule was missing from all spec files (now added).
# ─────────────────────────────────────────────────────────────────────────────
function Test-CodeWalkthrough {
  param([string[]]$Lines, [string]$FilePath)
  # Skip index.md files - they have code blocks in frontmatter examples
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  $errs = @()
  $inFence = $false
  $fenceLang = ''
  $closingLineNum = -1
  $closingLang = ''
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*```(\w*)') {
      $lang = $Matches[1]
      if (-not $inFence) {
        $fenceLang = $lang; $inFence = $true         # opening fence
      } elseif ($lang -eq '') {
        $closingLineNum = $i; $closingLang = $fenceLang
        $inFence = $false                            # bare ``` closes
      }
      # labelled fence inside block = content line, skip toggle
      continue
    }
    if ($closingLineNum -gt 0 -and -not $inFence) {
      # For non-mermaid ASCII blocks: check if a mermaid block follows within
      # 10 lines (DUAL diagram pair). If so, skip - shared walkthrough follows.
      $isDualAscii = $false
      if ($closingLang -eq '' -or $closingLang -eq 'text' -or $closingLang -eq 'ascii') {
        $lookAhead = [Math]::Min($Lines.Count - 1, $closingLineNum + 10)
        for ($m = $closingLineNum + 1; $m -le $lookAhead; $m++) {
          if ($Lines[$m] -match '^\s*```mermaid') { $isDualAscii = $true; break }
          # Stop looking if we hit non-blank prose (not a diagram pair)
          if ($Lines[$m] -notmatch '^\s*$' -and $Lines[$m] -notmatch '^>') { break }
        }
      }
      # For BAD/GOOD code pairs: if this closing fence is immediately followed by
      # another opening fence within 3 lines, skip (shared walkthrough after GOOD).
      $isFirstOfPair = $false
      $pairLook = [Math]::Min($Lines.Count - 1, $closingLineNum + 3)
      for ($m = $closingLineNum + 1; $m -le $pairLook; $m++) {
        if ($Lines[$m] -match '^\s*```\w*') { $isFirstOfPair = $true; break }
        if ($Lines[$m] -notmatch '^\s*$') { break }  # prose before next fence = not a pair
      }
      if (-not $isDualAscii -and -not $isFirstOfPair) {
        # Check within next 3 lines for walkthrough
        $found = $false
        $end = [Math]::Min($Lines.Count - 1, $closingLineNum + 4)
        for ($k = $closingLineNum + 1; $k -le $end; $k++) {
          if ($Lines[$k] -match '> \*\*Code walkthrough' -or
              $Lines[$k] -match '> \*\*Diagram walkthrough') {
            $found = $true; break
          }
          if ($Lines[$k] -match '^\s*```') { break }  # another fence starts
        }
        if (-not $found) {
          $label = if ($closingLang -eq 'mermaid') { 'Diagram' } else { 'Code' }
          $errs += "R09 WALKTHROUGH: line $($closingLineNum+1): $closingLang block " +
                   "not followed by '> **$label walkthrough:**' within 3 lines"
        }
      }
      $closingLineNum = -1
      $closingLang = ''
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
# line." Jekyll/just-the-docs merges consecutive paragraph lines without blank separator.
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
               "with no blank separator. Jekyll merges them: $cur"
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
# as broken visual garbage in Jekyll and are nearly impossible to read.
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
    if ($line -match '^\s*```(\w*)') {
      $l = $Matches[1]
      if (-not $inFence) { $inFence = $true } elseif ($l -eq '') { $inFence = $false }
    }
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
      # For multi-column ASCII diagrams, ┘ may appear mid-line (not just at end).
      # Check that ┘ appears ANYWHERE in the line (handles side-by-side boxes).
      if ($line -notmatch '\u2518') {
        $errs += "R17 QRC-BOX: line ${lineNum}: \u2514 border has no closing \u2518: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
      $inBoxArt    = $false
      $boxOpenLine = -1
    } elseif ($inBoxArt -and $line -match '^\u251c') {
      # ├ divider - only inside confirmed box
      if ($line -notmatch '\u2524') {
        $errs += "R17 QRC-BOX: line ${lineNum}: \u251c divider has no closing \u2524: " +
                 "$($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
      }
    } elseif ($inBoxArt) {
      # Content row must start with │ (allow blank rows)
      # Multi-column diagrams may end with box-drawing chars from another column.
      if ($trimmed -ne '' -and $line -notmatch '^\u2502') {
        $errs += "R17 QRC-BOX: line ${lineNum}: line inside box does not " +
                 "start with \u2502: $($trimmed.Substring(0,[Math]::Min(50,$trimmed.Length)))"
        $inBoxArt = $false  # reset to avoid cascade
      } elseif ($line -match '^\u2502' -and $line -notmatch '[\u2502\u2518\u2510\u2524\u2500]$') {
        $errs += "R17 QRC-BOX: line ${lineNum}: box content line starts " +
                 "with │ but does not end with a box-drawing char: " +
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
    if ($line -match '^\s*```(\w*)') {
      $l = $Matches[1]
      if (-not $inFence) { $inFence = $true } elseif ($l -eq '') { $inFence = $false }
      continue
    }
    if ($inFence) { continue }
    $key = $line.Trim()
    # Only prose lines: length >= 50, not a heading, HR, blank, blockquote,
    # bold-tagged question, or OMIT placeholder (intentional boilerplate)
    if ($key.Length -lt 50) { continue }
    if ($key -match '^#|^---|^\*\*\[|^>') { continue }
    if ($key -match '^\*\(Omit') { continue }          # OMIT placeholders are intentional
    # Structural boilerplate intentionally repeated per-keyword in multi-keyword files:
    if ($key -match '^\*What separates good from great\b') { continue }
    if ($key -match '^\*\*Framework:\*\*\s+WHAT') { continue }
    if ($key -match '^\|\s*Preparation Time\s*\|') { continue }
    if ($key -match 'templates are provided in the Interview Deep-Dive') { continue }
    if ($key -match '^\*\*Interview Weight:\*\*') { continue }
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
# RULE R19 - Blank Mind Recovery block format
# Every keyword's Model Answer must contain a Blank Mind Recovery block.
# The three numbered steps must:
#   1. Use bold labels: **(1) Restate:**, **(2) First principles:**, **(3) Bridge:**
#   2. Each step must be on its own line - not inline with another step
#   3. The heading must use bold: **Blank Mind Recovery:**
#
# Format A (standalone block in Model Answer):
#   **Blank Mind Recovery:**
#   <blank>
#   **(1) Restate:** "..."
#   <blank>
#   **(2) First principles:** "..."
#   <blank>
#   **(3) Bridge:** "..."
#
# Format B (table row in Interview Deep-Dive - L0/L1 compact format):
#   | Blank mind recovery | "short cue" |
#   (lowercase - acceptable, not checked by this rule)
# ─────────────────────────────────────────────────────────────────────────────
function Test-BlankMindRecoveryFormat {
  param([string[]]$Lines)
  $errs = @()
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    # Check bold heading - detect missing ** on standalone BMR heading
    # Skip table-row format (lowercase, starts with |)
    if ($line -match '\bBlank Mind Recovery\b' -and
        $line -notmatch '^\*\*Blank Mind Recovery' -and
        $line -notmatch '^\|' -and
        $line -notmatch '> \*\*Blank Mind Recovery') {
      $errs += "R19 BMR-FORMAT: line $($i+1): 'Blank Mind Recovery' must " +
               "use bold heading - **Blank Mind Recovery:** - not bare text"
    }
    # Check bold labels on numbered steps - detect bare (N) Restate:
    if ($line -match '^\(1\)\s*Restate:|^\(2\)\s*First\s+principles|^\(3\)\s*Bridge:') {
      $snippet = $line.Trim().Substring(0, [Math]::Min(60, $line.Trim().Length))
      $errs += "R19 BMR-FORMAT: line $($i+1): BMR step must be bold - " +
               "e.g. **(1) Restate:** not bare '(1) Restate:': $snippet"
    }
    # Check multiple BMR steps on the same line.
    # Only trigger when BOLD-WRAPPED step labels (**\(N\) ...) appear 2+ times,
    # e.g. "**(1) Restate:** ... **(2) First principles:**" on one line.
    # Bare (1) / (2) in prose must NOT trigger (false positive for numbered lists).
    $boldStepCount = ([regex]::Matches($line, '\*\*\([123]\)\s')).Count
    if ($boldStepCount -gt 1) {
      $snippet = $line.Trim().Substring(0, [Math]::Min(60, $line.Trim().Length))
      $errs += "R19 BMR-FORMAT: line $($i+1): multiple BMR steps on one " +
               "line - each step must be a separate paragraph: $snippet"
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# R20 - KEYWORD NAVIGATION BLOCK
# Every content file must have "## Keywords in This File" within
# the first 30 lines after frontmatter closes.
# Skips index.md files and spec/scripts directories.
# ─────────────────────────────────────────────────────────────────────────────
function Test-KeywordNavBlock {
  param([string[]]$Lines, [string]$FilePath)
  $errs = @()
  if ($FilePath -match '(\\|/)index\.md$') { return $errs }
  if ($FilePath -match '(spec|scripts)[/\\]') { return $errs }
  # Find end of frontmatter
  $fmEnd = -1; $dashes = 0
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') {
      $dashes++
      if ($dashes -ge 2) { $fmEnd = $i; break }
    }
  }
  if ($fmEnd -lt 0) { return $errs }
  # Check first 30 lines after frontmatter for nav block
  $found = $false
  $limit = [Math]::Min($fmEnd + 31, $Lines.Count)
  for ($i = $fmEnd + 1; $i -lt $limit; $i++) {
    if ($Lines[$i] -match '^## Keywords in This File') { $found = $true; break }
  }
  if (-not $found) {
    $name = Split-Path $FilePath -Leaf
    $errs += "R20 KEYWORD-NAV: '$name' missing '## Keywords in This File' " +
             "block within 30 lines after frontmatter"
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R21 - ALL sections presence check (NON-NEGOTIABLE)
# Every keyword block MUST contain ALL 10 Option C section headers.
# Conditional sections are NOT silently omitted - they must appear with
# an explicit OMIT note (e.g. *(Omit: reason)*) when not applicable.
#
# Source: interview.instructions.md Content Structure + spec/interview_content_generator.md
#
# ALL 10 SECTIONS REQUIRED (header must be present in every keyword):
#   ### 🎯 Model Answer           Option C §2 - ALWAYS, no OMIT allowed
#   ### 📘 Concept Explanation    Option C §3 - ALWAYS, no OMIT allowed
#   ### 💻 Code Example           Option C §4 - header always present;
#                                content = code OR explicit OMIT + reason
#   ### 🎓 Answers by Seniority   Option C §5 - ALWAYS, no OMIT allowed
#   ### ⚠️ Common Misconceptions  Option C §6 - ALWAYS, no OMIT allowed
#   ### 🚨 Failure Modes          Option C §7 - ALWAYS, no OMIT allowed
#   ### 🎯 Interview Deep-Dive    Option C §8 - ALWAYS, CAPSTONE, no OMIT
#   ### ⚖️ Comparison Table       Option C §9 - header always present;
#                                content = table OR explicit OMIT for ★☆☆
#   ### 🏛️ System Design          spec §4.9 - header always present;
#                                content = design OR explicit OMIT for non-★★★
#   ### 📊 Diagram                spec §4.10 - header always present;
#                                content = diagram OR explicit OMIT for non-visual
#
# HARD STOP: Any missing section header = file is REJECTED, not written.
# Sections with OMIT content still require their ### header to be present.
# Silent omissions are never acceptable.
# ─────────────────────────────────────────────────────────────────────────────
function Test-MandatorySections {
  param([string[]]$Lines, [string]$FilePath)
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  if ($FilePath -match '(spec|scripts|\.github)[/\\]') { return @() }
  # Skip empty files - they have no keywords to check
  if ($Lines.Count -lt 5) { return @() }

  $errs = @()

  # ALL 10 sections required - header must appear in every keyword block.
  # Conditional sections must have explicit OMIT note if not applicable.
  # Source: interview.instructions.md Content Structure + spec/interview_content_generator.md
  $mandatoryGroups = @(
    @{ name = 'Model Answer (Option C §2)';
       pattern = '^### 🎯 Model Answer' },
    @{ name = 'Concept Explanation (Option C §3)';
       pattern = '^### 📘 Concept Explanation' },
    @{ name = 'Code Example (Option C §4 - OMIT note required if non-programmatic)';
       pattern = '^### 💻 Code Example' },
    @{ name = 'Answers by Seniority (Option C §5)';
       pattern = '^### 🎓 Answers by Seniority' },
    @{ name = 'Common Misconceptions (Option C §6)';
       pattern = '^### ⚠️ Common Misconceptions' },
    @{ name = 'Failure Modes and Diagnosis (Option C §7)';
       pattern = '^### 🚨 Failure Modes' },
    @{ name = 'Interview Deep-Dive (Option C §8 - CAPSTONE)';
       pattern = '^### 🎯 Interview Deep-Dive' },
    @{ name = 'Comparison Table (Option C §9 - OMIT note required for ★☆☆)';
       pattern = '^### ⚖️ Comparison' },
    @{ name = 'System Design (spec §4.9 - OMIT note required for non-★★★)';
       pattern = '^### 🏛️ System Design' },
    @{ name = 'Diagram (spec §4.10 - OMIT note required for non-visual concepts)';
       pattern = '^### 📊 Diagram' }
  )

  # Find end of frontmatter
  $bodyStart = 0
  if ($Lines[0].Trim() -eq '---') {
    for ($i = 1; $i -lt $Lines.Count; $i++) {
      if ($Lines[$i].Trim() -eq '---') { $bodyStart = $i + 1; break }
    }
  }

  # Find keyword boundaries (H1 headings in body, outside code fences)
  $keywordStarts = @()
  $inFence = $false
  for ($i = $bodyStart; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match '^\s*```(\w*)') {
      $l = $Matches[1]
      if (-not $inFence) { $inFence = $true } elseif ($l -eq '') { $inFence = $false }
      continue
    }
    if (-not $inFence -and $Lines[$i] -match '^# [^#]') { $keywordStarts += $i }
  }

  # No keywords found - skip (file may be metadata-only like index)
  if ($keywordStarts.Count -eq 0) { return @() }

  for ($k = 0; $k -lt $keywordStarts.Count; $k++) {
    $start = $keywordStarts[$k]
    $end   = if ($k + 1 -lt $keywordStarts.Count) {
               $keywordStarts[$k + 1] - 1
             } else { $Lines.Count - 1 }
    $block  = $Lines[$start..$end]
    $kwLine = $Lines[$start].Trim()
    # Strip leading # chars to get keyword name
    $kwName = $kwLine -replace '^#+\s*', ''

    foreach ($mg in $mandatoryGroups) {
      $found = $false
      foreach ($bline in $block) {
        if ($bline -match $mg.pattern) { $found = $true; break }
      }
      if (-not $found) {
        $errs += "R21 MISSING-SECTION: keyword '$kwName' " +
                 "(line $($start+1)): mandatory section '$($mg.name)' " +
                 "is missing. HARD STOP: interview.instructions.md " +
                 "Option C requires this in every keyword. " +
                 "Read spec/interview_content_generator.md and regenerate."
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R22 - render_with_liquid: false required in every content file
# Southstar uses render_with_liquid: false as belt-and-suspenders over the
# global _config.yml default. Without it, {{ }} and {% %} in code examples
# (GitHub Actions, Docker inspect, Prometheus, JSX, Angular) cause Liquid
# parse errors when _config.yml default is not in effect.
# Source: copilot-instructions.md "Liquid safety" + interview.instructions.md
# Ported from northstar LIQUID_TAG concept, adapted for southstar convention.
# ─────────────────────────────────────────────────────────────────────────────
function Test-RenderWithLiquidFalse {
  param([string[]]$Lines, [string]$FilePath)
  # Only check content files (not index.md, not spec/scripts)
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  if ($FilePath -match '(spec|scripts)[/\\]') { return @() }
  # Need frontmatter
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $fmEnd = -1
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
  }
  if ($fmEnd -lt 0) { return @() }
  $fm = ($Lines[0..$fmEnd]) -join "`n"
  if ($fm -notmatch 'render_with_liquid:\s*false') {
    return @("R22 LIQUID-SAFETY: missing 'render_with_liquid: false' in " +
             "frontmatter. MANDATORY for all content files to prevent Liquid " +
             "parsing of {{ }} and {% %} in code examples. " +
             "See copilot-instructions.md 'Liquid safety' section.")
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R23 - No duplicate YAML frontmatter keys
# Duplicate YAML keys cause ambiguous behaviour (YAML spec violation).
# Ruby Psych (used by Jekyll/GitHub Pages) may silently ignore the duplicate
# or merge both values in an undefined way. Real case: northstar SEC-010 had
# tier:, folder:, version: each appearing twice AND was missing nav_order as
# a result of the frontmatter confusion.
# Ported from northstar DUPLICATE_YAML_FIELD rule.
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoDuplicateYamlFields {
  param([string[]]$Lines)
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $fmEnd = -1
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
  }
  if ($fmEnd -lt 0) { return @() }
  $errs = @()
  $seenKeys = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
  for ($i = 1; $i -lt $fmEnd; $i++) {
    $keyMatch = [regex]::Match($Lines[$i], '^([a-zA-Z_][a-zA-Z0-9_]*):')
    if ($keyMatch.Success) {
      $key = $keyMatch.Groups[1].Value
      if (-not $seenKeys.Add($key)) {
        $errs += "R23 DUPLICATE-YAML: line $($i+1): duplicate YAML key '$key' " +
                 "in frontmatter - remove one occurrence. Jekyll/Psych behaviour " +
                 "is undefined for duplicate keys."
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R24 - parent: must match topic index.md title: exactly
# The just-the-docs sidebar builds from parent/child relationships.
# If parent: "Java Concurrency" but index.md has title: "Java Concurrency"
# with different quoting or spacing, the page is orphaned (no sidebar entry).
# Catches copy-paste errors when a file is moved to a different topic folder.
# Real case: northstar NET-078 had parent: "Technical Mastery" instead of
# parent: "Networking" after being moved.
# Ported from northstar YAML_PARENT_MISMATCH rule.
# ─────────────────────────────────────────────────────────────────────────────
function Test-YamlParentMatchesIndex {
  param([string[]]$Lines, [string]$FilePath)
  if ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md') { return @() }
  if ($FilePath -match '(spec|scripts)[/\\]') { return @() }
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $fmEnd = -1
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
  }
  if ($fmEnd -lt 0) { return @() }
  $fm = ($Lines[0..$fmEnd]) -join "`n"
  $parentMatch = [regex]::Match($fm, '(?m)^parent:\s*"?([^"\r\n]+)"?')
  if (-not $parentMatch.Success) { return @() }
  $entryParent = $parentMatch.Groups[1].Value.Trim()
  $indexPath = Join-Path (Split-Path $FilePath -Parent) 'index.md'
  if (-not (Test-Path $indexPath)) { return @() }
  $idxLines = [System.IO.File]::ReadAllLines($indexPath)
  $idxFmEnd = -1
  if ($idxLines.Count -gt 0 -and $idxLines[0].Trim() -eq '---') {
    for ($i = 1; $i -lt $idxLines.Count; $i++) {
      if ($idxLines[$i].Trim() -eq '---') { $idxFmEnd = $i; break }
    }
  }
  if ($idxFmEnd -lt 0) { return @() }
  $idxFm = ($idxLines[0..$idxFmEnd]) -join "`n"
  $titleMatch = [regex]::Match($idxFm, '(?m)^title:\s*"?([^"\r\n]+)"?')
  if (-not $titleMatch.Success) { return @() }
  $idxTitle = $titleMatch.Groups[1].Value.Trim()
  if ($entryParent -ne $idxTitle) {
    return @("R24 PARENT-MISMATCH: parent: '$entryParent' does not match " +
             "index.md title: '$idxTitle'. " +
             "Fix: parent: `"$idxTitle`"")
  }
  return @()
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R25 - YAML unsafe tag values (bare @, *, ? in sequences)
# YAML 1.1 (Ruby Psych, used by Jekyll/GitHub Pages) forbids plain scalars
# that begin with @, *, or ? inside frontmatter. Two patterns trigger parse errors:
#   1. Block sequence item:  "  - @Document" or "  - *glob"
#   2. Inline flow sequence: "tags: [foo, *, ?, []]"
# When Psych throws, Jekyll silently drops ALL frontmatter fields. The page
# then appears at site root instead of nested in the sidebar.
# Fix: quote the offending value -> - "@Document" or - "*"
# Real cases: northstar ELS-022 (- @Document), KFK-033 (- @KafkaListener),
# LNX-017 (tags: [*, ?, []]).
# Ported from northstar YAML_UNSAFE_TAG_VALUE rule.
# ─────────────────────────────────────────────────────────────────────────────
function Test-YamlUnsafeTagValues {
  param([string[]]$Lines)
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $fmEnd = -1
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
  }
  if ($fmEnd -lt 0) { return @() }
  $errs = @()
  for ($i = 1; $i -lt $fmEnd; $i++) {
    $fmLine = $Lines[$i]
    # Pattern 1: block sequence item with bare @, *, or ?
    $seqMatch = [regex]::Match($fmLine, "^(\s*-\s+)(['""]?)([@ *?])")
    if ($seqMatch.Success -and $seqMatch.Groups[2].Value -eq '') {
      $badChar = $seqMatch.Groups[3].Value
      $rawVal  = $fmLine.Trim().Substring(2).Trim()
      $errs += "R25 YAML-UNSAFE: line $($i+1): unquoted YAML sequence value " +
               "starts with '$badChar' (reserved in YAML 1.1). Jekyll drops all " +
               "frontmatter -> page at site root. Fix: - `"$rawVal`""
    }
    # Pattern 2: inline flow sequence with bare * or ?
    if ($fmLine -match ':\s*\[') {
      $flowContent = [regex]::Match($fmLine, ':\s*\[(.+)\]').Groups[1].Value
      if ($flowContent -match '(?:(?:^|,)\s*)\*(?:\s*(?:,|\]))' -or
          $flowContent -match '(?:(?:^|,)\s*)\?(?:\s*(?:,|\]))') {
        $errs += "R25 YAML-UNSAFE: line $($i+1): inline flow sequence contains " +
                 "bare '*' or '?' (YAML alias/key indicator). Jekyll drops all " +
                 "frontmatter. Fix: convert to block sequence with quoted values."
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R26 - Required frontmatter fields present
# Every southstar file under docs/ must have the required frontmatter fields.
# Content files require: layout, title, parent, nav_order, permalink,
#   render_with_liquid (enforced separately by R22).
# Topic index files (index.md) require: title, nav_order, has_children.
# Topic index files must NOT have parent, layout, or permalink - adding these
# nests them under another page instead of appearing at root sidebar level.
# Source: interview.instructions.md "File Frontmatter" section.
# Ported from northstar MISSING_FIELD rule, adapted for southstar fields.
# ─────────────────────────────────────────────────────────────────────────────
function Test-RequiredFrontmatterFields {
  param([string[]]$Lines, [string]$FilePath)
  if ($FilePath -match '(spec|scripts)[/\\]') { return @() }
  # docs/index.md (root homepage) - only check it has layout and title
  if ($FilePath -match 'docs[/\\]index\.md$') {
    if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') {
      return @("R26 MISSING-FIELD: docs/index.md missing frontmatter entirely")
    }
    return @()
  }
  if ($Lines.Count -lt 1 -or $Lines[0].Trim() -ne '---') { return @() }
  $fmEnd = -1
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
  }
  if ($fmEnd -lt 0) { return @() }
  $fm = ($Lines[0..$fmEnd]) -join "`n"
  $errs = @()
  $isIndex = ([System.IO.Path]::GetFileName($FilePath) -eq 'index.md')
  if ($isIndex) {
    # Topic index: title, nav_order, has_children required
    # layout and parent must NOT be present (prevents nesting at root)
    foreach ($field in @('title', 'nav_order', 'has_children')) {
      if ($fm -notmatch "(?m)^${field}:") {
        $errs += "R26 MISSING-FIELD: topic index.md missing required field " +
                 "'$field'. Topic index files need: title, nav_order, has_children."
      }
    }
    if ($fm -match '(?m)^parent:') {
      $errs += "R26 MISSING-FIELD: topic index.md MUST NOT have 'parent:' field " +
               "- it causes the topic to nest under another page instead of " +
               "appearing at root sidebar level."
    }
  } else {
    # Content file: layout, title, parent, nav_order, permalink required
    foreach ($field in @('layout', 'title', 'parent', 'nav_order', 'permalink')) {
      if ($fm -notmatch "(?m)^${field}:") {
        $errs += "R26 MISSING-FIELD: content file missing required frontmatter " +
                 "field '$field'. Content files need: layout, title, parent, " +
                 "nav_order, permalink, render_with_liquid."
      }
    }
  }
  return $errs
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE R27 - No generic placeholder walkthrough text
# Code walkthroughs must contain actual code-specific explanation, not the
# generic boilerplate inserted by the R09 fix script.
# The placeholder text "This example demonstrates the core pattern in action.
# The key mechanism shows how the concept works in practice." is never a valid
# walkthrough - it must be replaced with 3-6 sentences explaining what the
# specific code shows, why it works that way, what breaks, and the takeaway.
# ─────────────────────────────────────────────────────────────────────────────
function Test-NoGenericWalkthrough {
  param([string[]]$Lines)
  $errs = @()
  $placeholder = 'This example demonstrates the core pattern in action'
  for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match [regex]::Escape($placeholder)) {
      $errs += "R27 GENERIC-WALKTHROUGH: line $($i+1) has placeholder walkthrough" +
               " text - replace with code-specific explanation (what it shows," +
               " key mechanism, why it matters, what breaks, takeaway)"
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
  # R08 skipped for index.md (keyword registry uses ### without ---)
  if ($FilePath -notmatch '(\\|/)index\.md$') {
    $errs += Test-H3PrecededByHR   -Lines $lines
  }
  $errs += Test-CodeWalkthrough    -Lines $lines -FilePath $FilePath
  $errs += Test-DualDiagramFormat  -Lines $lines
  $errs += Test-BadBeforeGood      -Lines $lines
  $errs += Test-DeepDiveQuestionCount -Lines $lines -FilePath $FilePath
  $errs += Test-BoldLabelBlankSeparator -Lines $lines
  $errs += Test-NoSecrets              -Lines $lines
  $errs += Test-QrcBorderIntegrity     -Lines $lines
  $errs += Test-NoDuplicateLines       -Lines $lines -FilePath $FilePath
  $errs += Test-BlankMindRecoveryFormat -Lines $lines
  # Spec/instruction files only:
  if ($FilePath -match '\.(github|spec)\\') {
    $errs += Test-NoNineteenSections -Lines $lines
    $errs += Test-NoOldFileNaming    -Lines $lines -FilePath $FilePath
  }
  $errs += Test-KeywordNavBlock    -Lines $lines -FilePath $FilePath
  $errs += Test-MandatorySections  -Lines $lines -FilePath $FilePath
  # New rules ported from northstar, customized for southstar:
  $errs += Test-RenderWithLiquidFalse    -Lines $lines -FilePath $FilePath
  $errs += Test-NoDuplicateYamlFields    -Lines $lines
  $errs += Test-YamlParentMatchesIndex   -Lines $lines -FilePath $FilePath
  $errs += Test-YamlUnsafeTagValues      -Lines $lines
  $errs += Test-RequiredFrontmatterFields -Lines $lines -FilePath $FilePath
  $errs += Test-NoGenericWalkthrough     -Lines $lines
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

# Export-ModuleMember removed: file is dot-sourced, not a module.
