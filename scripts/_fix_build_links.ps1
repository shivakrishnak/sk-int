$docsDir = 'c:\ASK\Mastery\southstar\docs'

# Fix 1: docs/index.md - trailing-slash folder links -> explicit index.md
$mainIndex = Join-Path $docsDir 'index.md'
$content = [System.IO.File]::ReadAllText($mainIndex, [System.Text.Encoding]::UTF8)
foreach ($folder in @('java-language','java-core','java-jvm','java-concurrency','java-performance')) {
    $content = $content.Replace("($folder/)", "($folder/index.md)")
}
[System.IO.File]::WriteAllText($mainIndex, $content, [System.Text.UTF8Encoding]::new($false))
"Fixed folder links: $mainIndex"

# Fix 2: Strip links to missing files in each topic index.md (line-by-line)
$topicIndexFiles = Get-ChildItem $docsDir -Recurse -Filter 'index.md' |
    Where-Object { $_.DirectoryName -ne $docsDir }

$linkRx = [regex]'\[([^\]]+)\]\(([^)]+\.md)\)'

foreach ($indexFile in $topicIndexFiles) {
    $folder = $indexFile.DirectoryName
    $lines  = [System.IO.File]::ReadAllLines($indexFile.FullName, [System.Text.Encoding]::UTF8)
    $changed = $false
    $newLines = foreach ($line in $lines) {
        $newLine = $line
        foreach ($m in $linkRx.Matches($line)) {
            $display    = $m.Groups[1].Value
            $urlEncoded = $m.Groups[2].Value
            $decoded    = [Uri]::UnescapeDataString($urlEncoded)
            $target     = Join-Path $folder $decoded
            if (-not (Test-Path $target)) {
                $newLine = $newLine.Replace($m.Value, $display)
                $changed = $true
            }
        }
        $newLine
    }
    if ($changed) {
        [System.IO.File]::WriteAllLines($indexFile.FullName, $newLines, [System.Text.UTF8Encoding]::new($false))
        "Stripped missing links: $($indexFile.Directory.Name)/index.md"
    } else {
        "  No changes needed: $($indexFile.Directory.Name)/index.md"
    }
}

"Done. Run 'mkdocs build --strict' to verify."
