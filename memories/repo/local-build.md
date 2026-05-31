# Local Jekyll Build (Windows - Ruby 3.4.9)

## Prerequisites
- Ruby 3.4.9 at `C:\Tools\ruby34` (RubyInstaller, ucrt64)
- MSYS2 at `C:\Tools\ruby34\msys64` with gcc + make installed
- Mozilla CA bundle: `cacert.pem` at workspace root (download from curl.se/ca/cacert.pem)

## Build command (WORKING)
```pwsh
$env:PATH = "C:\Tools\ruby34\bin;C:\Tools\ruby34\msys64\ucrt64\bin;C:\Tools\ruby34\msys64\usr\bin;" + $env:PATH
$env:SSL_CERT_FILE = "C:\Shiva\Mastery\southstar\cacert.pem"
Set-Location "C:\Shiva\Mastery\southstar"
bundle exec ruby C:\Tools\ruby34\bin\jekyll build --config _config.yml 2>&1 | Tee-Object "build.log"
# Check for real errors (not deprecation warnings):
Get-Content build.log | Select-String "error|Error|Exception" | Where-Object { $_ -notmatch "DEPRECATION" }
```

## CRITICAL: Do NOT use `bundle exec jekyll build`
The `jekyll.bat` wrapper loses output in PowerShell pipes. Use `bundle exec ruby ... jekyll` directly.

## Known warnings (non-actionable)
- Sass DEPRECATION WARNINGs from just-the-docs theme SCSS (`@import`, `darken()`, `map-get()`)
- These are in the remote theme code we don't control - ignore them
- Build exit code 0 = success despite warnings

## Bundler local config
`.bundle/config` contains `BUNDLE_FORCE_RUBY_PLATFORM: false` - DO NOT commit.

## Files NOT to commit (all in .gitignore)
- `cacert.pem` - local SSL cert workaround
- `.bundle/` - local bundler config
- `build.log` - build output capture
- `bundle_install.log` - install log
- `_tmp_kw.md` - content generation temp file
- `_site/` - build output

## Git state (as of last successful build)
- Last pushed: `1b73ac2` (fix: re-enable Liquid for assets/)
- Local unpushed: `8a3ac9c` (chore: gitignore local build env files)
- Build time: ~135 seconds
