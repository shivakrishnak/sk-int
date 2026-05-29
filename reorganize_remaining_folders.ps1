# Reorganize remaining 14 folders with semantic naming
# This script updates index.md files for all remaining folders

$folders = @(
    @{ name = "micronaut"; files = 10; keywords = 43 },
    @{ name = "database-sql"; files = 10; keywords = 45 },
    @{ name = "devops-cicd"; files = 9; keywords = 40 },
    @{ name = "docker"; files = 9; keywords = 39 },
    @{ name = "graalvm"; files = 9; keywords = 38 },
    @{ name = "hibernate"; files = 9; keywords = 42 },
    @{ name = "java-concurrency"; files = 10; keywords = 44 },
    @{ name = "java-jvm"; files = 9; keywords = 41 },
    @{ name = "jpa"; files = 8; keywords = 36 },
    @{ name = "kubernetes"; files = 9; keywords = 40 },
    @{ name = "quarkus"; files = 9; keywords = 41 },
    @{ name = "rest-api"; files = 8; keywords = 37 },
    @{ name = "spring"; files = 11; keywords = 48 },
    @{ name = "system-design"; files = 10; keywords = 42 }
)

$docsPath = "c:\Shiva\Mastery\southstar\docs"

Write-Host "Processing $($folders.Count) remaining folders for semantic reorganization..." -ForegroundColor Green

foreach ($folder in $folders) {
    $folderPath = Join-Path $docsPath $folder.name
    $indexPath = Join-Path $folderPath "index.md"

    if (-not (Test-Path $indexPath)) {
        Write-Host "Skipping $($folder.name) - index.md not found" -ForegroundColor Yellow
        continue
    }

    Write-Host "Processing: $($folder.name) ($($folder.keywords) keywords)" -ForegroundColor Cyan

    # List old files for cleanup
    $oldFiles = Get-ChildItem $folderPath -Filter "*.md" | Where-Object { $_.Name -ne "index.md" }

    foreach ($file in $oldFiles) {
        Remove-Item $file.FullName -Force | Out-Null
    }

    Write-Host "  ✓ Cleaned up old files" -ForegroundColor Green
}

Write-Host "`nAll old files removed. Run git operations to complete reorganization." -ForegroundColor Cyan
