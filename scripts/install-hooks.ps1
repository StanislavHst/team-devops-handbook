$ErrorActionPreference = "Stop"

$repositoryRoot = git rev-parse --show-toplevel 2>$null
if (-not $repositoryRoot) {
    throw "Run this script inside the Git repository."
}

$hookPath = Join-Path $repositoryRoot ".githooks"
if (-not (Test-Path -LiteralPath $hookPath)) {
    throw "Versioned hooks directory was not found: $hookPath"
}

git config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure core.hooksPath."
}

$configuredPath = git config --get core.hooksPath
Write-Host "Git hooks path configured: $configuredPath"
