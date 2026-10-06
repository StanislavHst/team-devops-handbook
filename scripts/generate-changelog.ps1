$ErrorActionPreference = "Stop"

$repositoryRoot = git rev-parse --show-toplevel 2>$null
if (-not $repositoryRoot) {
    throw "Run this script inside the Git repository."
}

$groups = [ordered]@{
    feat     = [System.Collections.Generic.List[string]]::new()
    fix      = [System.Collections.Generic.List[string]]::new()
    docs     = [System.Collections.Generic.List[string]]::new()
    chore    = [System.Collections.Generic.List[string]]::new()
    refactor = [System.Collections.Generic.List[string]]::new()
    test     = [System.Collections.Generic.List[string]]::new()
    ci       = [System.Collections.Generic.List[string]]::new()
    build    = [System.Collections.Generic.List[string]]::new()
    other    = [System.Collections.Generic.List[string]]::new()
}

$titles = [ordered]@{
    feat     = "Features"
    fix      = "Fixes"
    docs     = "Documentation"
    chore    = "Maintenance"
    refactor = "Refactoring"
    test     = "Tests"
    ci       = "Continuous integration"
    build    = "Build"
    other    = "Other changes"
}

$messages = @(git log --pretty=format:"%s")
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read Git history."
}

foreach ($message in $messages) {
    if ($message -match '^(feat|fix|docs|chore|refactor|test|ci|build)(\([^)]+\))?:\s+(.+)$') {
        $groups[$Matches[1]].Add($message)
    }
    elseif ($message -notmatch '^Merge ') {
        $groups.other.Add($message)
    }
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Changelog")
$lines.Add("")
$lines.Add("This file is generated automatically from Git commit messages.")
$lines.Add("")

foreach ($key in $groups.Keys) {
    if ($groups[$key].Count -eq 0) {
        continue
    }

    $lines.Add("## $($titles[$key])")
    $lines.Add("")

    foreach ($entry in $groups[$key]) {
        $lines.Add("- $entry")
    }

    $lines.Add("")
}

if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq "") {
    $lines.RemoveAt($lines.Count - 1)
}

$outputPath = Join-Path $repositoryRoot "CHANGELOG.md"
$lines | Set-Content -LiteralPath $outputPath -Encoding utf8
Write-Host "CHANGELOG generated: $outputPath"
