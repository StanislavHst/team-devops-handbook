$ErrorActionPreference = "Stop"

$repositoryRoot = git rev-parse --show-toplevel 2>$null
if (-not $repositoryRoot) {
    throw "Run this script inside the Git repository."
}

$hookPath = Join-Path $repositoryRoot ".githooks\commit-msg"
if (-not (Test-Path -LiteralPath $hookPath)) {
    throw "Hook was not found: $hookPath"
}

$shellCommand = Get-Command sh -ErrorAction SilentlyContinue
if ($shellCommand) {
    $shell = $shellCommand.Source
}
else {
    $gitExecutable = (Get-Command git -ErrorAction Stop).Source
    $gitRoot = Split-Path (Split-Path $gitExecutable -Parent) -Parent
    $shellCandidates = @(
        (Join-Path $gitRoot "bin\sh.exe"),
        (Join-Path $gitRoot "usr\bin\sh.exe")
    )
    $shell = $shellCandidates |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}

if (-not $shell) {
    throw "Git shell was not found. Install Git for Windows or add sh to PATH."
}
$cases = @(
    @{ Message = "docs(branching): explain review workflow"; Expected = 0 },
    @{ Message = "feat(changelog): generate history report"; Expected = 0 },
    @{ Message = "fix"; Expected = 1 },
    @{ Message = "wip"; Expected = 1 },
    @{ Message = "Added files."; Expected = 1 }
)

$failed = 0

foreach ($case in $cases) {
    $temporaryMessage = New-TemporaryFile
    try {
        $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText(
            $temporaryMessage,
            $case.Message + [Environment]::NewLine,
            $utf8WithoutBom
        )
        & $shell $hookPath $temporaryMessage 2>$null
        $actual = $LASTEXITCODE

        if ($actual -eq $case.Expected) {
            Write-Host "PASS: '$($case.Message)' -> $actual"
        }
        else {
            Write-Host "FAIL: '$($case.Message)' -> expected $($case.Expected), got $actual"
            $failed++
        }
    }
    finally {
        Remove-Item -LiteralPath $temporaryMessage -Force
    }
}

if ($failed -gt 0) {
    throw "$failed commit message test(s) failed."
}

Write-Host "All commit message tests passed."
