Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-PathExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Expected path not found: $Path"
    }
}

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillRoot = Join-Path $ProjectRoot "skills\code-health-review-harness"
$TmpRoot = Join-Path $ProjectRoot ".tmp"
$SmokeRoot = Join-Path $ProjectRoot ".tmp\smoke"
$ReportsRoot = Join-Path $ProjectRoot ".tmp\smoke-reports"
$FakeReportsRoot = Join-Path $ProjectRoot "code-health-reports"
$FakeReportsSession = Join-Path $FakeReportsRoot "smoke-ignore-test"
$TmpRemoved = $false

Push-Location $ProjectRoot
try {
    if (Test-Path $SmokeRoot) { Remove-Item -Path $SmokeRoot -Recurse -Force }
    if (Test-Path $ReportsRoot) { Remove-Item -Path $ReportsRoot -Recurse -Force }
    if (Test-Path $FakeReportsSession) { Remove-Item -Path $FakeReportsSession -Recurse -Force }

    New-Item -ItemType Directory -Path $SmokeRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $FakeReportsSession -Force | Out-Null
    Set-Content -Path (Join-Path $FakeReportsSession "package.json") -Value '{"scripts":{"test":"should-not-be-detected"}}' -Encoding UTF8

    & (Join-Path $ProjectRoot "scripts\verify-project.ps1")

    $SkillContent = Get-Content -Path (Join-Path $SkillRoot "SKILL.md") -Raw -Encoding UTF8
    Assert-Condition -Condition ($SkillContent -match [regex]::Escape("short Chinese prompts")) -Message "SKILL.md should retain short-trigger support wording."
    Assert-Condition -Condition ($SkillContent -match [regex]::Escape("chat-only output")) -Message "SKILL.md should retain chat-only output opt-out wording."

    $UsageContent = Get-Content -Path (Join-Path $ProjectRoot "docs\usage.md") -Raw -Encoding UTF8
    Assert-Condition -Condition ($UsageContent -match [regex]::Escape("Short trigger prompts")) -Message "docs/usage.md should document short trigger prompts."
    Assert-Condition -Condition ($UsageContent -match [regex]::Escape("chat-only output")) -Message "docs/usage.md should document the chat-only opt-out phrase."

    & (Join-Path $SkillRoot "scripts\new-review-session.ps1") -RepoPath $ProjectRoot -OutputRoot ".tmp\smoke-reports" -SessionName "smoke-session" -Force
    $SessionPath = Join-Path $ReportsRoot "smoke-session"
    foreach ($Artifact in @("metadata.json", "review-report.md", "findings.json", "iteration-plan.md", "verification-matrix.md", "command-log.md", "artifacts")) {
        Assert-PathExists -Path (Join-Path $SessionPath $Artifact)
    }

    & (Join-Path $SkillRoot "scripts\collect-repo-facts.ps1") -RepoPath $ProjectRoot -OutputPath ".tmp\smoke\facts.json"
    Assert-PathExists -Path (Join-Path $SmokeRoot "facts.json")
    $Facts = Get-Content -Path (Join-Path $SmokeRoot "facts.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $ManifestText = (@($Facts.manifests) -join "`n")
    Assert-Condition -Condition ($ManifestText -notmatch "code-health-reports") -Message "collect-repo-facts should ignore code-health-reports."

    $AbsoluteFactsPath = Join-Path $SmokeRoot "facts-absolute.json"
    & (Join-Path $SkillRoot "scripts\collect-repo-facts.ps1") -RepoPath $ProjectRoot -OutputPath $AbsoluteFactsPath
    Assert-PathExists -Path $AbsoluteFactsPath
    $AbsoluteFacts = Get-Content -Path $AbsoluteFactsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Condition -Condition ($AbsoluteFacts.repoPath -eq $ProjectRoot) -Message "collect-repo-facts should support absolute OutputPath."

    $PreviousSmokeFlag = $env:CODE_HEALTH_HARNESS_SMOKE_RUNNING
    $env:CODE_HEALTH_HARNESS_SMOKE_RUNNING = "1"
    try {
        $SafeChecksJson = & (Join-Path $SkillRoot "scripts\run-safe-checks.ps1") -RepoPath $ProjectRoot
        $SafeChecks = $SafeChecksJson | ConvertFrom-Json
        Assert-Condition -Condition ($SafeChecks.repoPath -eq $ProjectRoot) -Message "run-safe-checks returned an unexpected repoPath."
        $VerifyResult = @($SafeChecks.results) | Where-Object { $_.label -eq "powershell:verify-project" } | Select-Object -First 1
        Assert-Condition -Condition ($null -ne $VerifyResult -and $VerifyResult.status -eq "passed") -Message "run-safe-checks should discover and pass verify-project.ps1."
    }
    finally {
        if ($null -eq $PreviousSmokeFlag) {
            Remove-Item Env:CODE_HEALTH_HARNESS_SMOKE_RUNNING -ErrorAction SilentlyContinue
        }
        else {
            $env:CODE_HEALTH_HARNESS_SMOKE_RUNNING = $PreviousSmokeFlag
        }
    }

    & (Join-Path $SkillRoot "scripts\summarize-review-history.ps1") -ReportsRoot $ReportsRoot -OutputPath ".tmp\smoke\history.md"
    Assert-PathExists -Path (Join-Path $SmokeRoot "history.md")

    & (Join-Path $SkillRoot "scripts\summarize-review-history.ps1") -ReportsRoot (Join-Path $ProjectRoot ".tmp\missing-reports") -OutputPath ".tmp\smoke\empty-history.md"
    Assert-PathExists -Path (Join-Path $SmokeRoot "empty-history.md")

    Write-Host "Harness smoke test passed."
}
finally {
    Pop-Location
    if (Test-Path $SmokeRoot) { Remove-Item -Path $SmokeRoot -Recurse -Force }
    if (Test-Path $ReportsRoot) { Remove-Item -Path $ReportsRoot -Recurse -Force }
    if (Test-Path $FakeReportsSession) { Remove-Item -Path $FakeReportsSession -Recurse -Force }
    if ((Test-Path $FakeReportsRoot) -and -not (Get-ChildItem -Path $FakeReportsRoot -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -Path $FakeReportsRoot -Force
    }
    if ((Test-Path $TmpRoot) -and -not (Get-ChildItem -Path $TmpRoot -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -Path $TmpRoot -Force
    }
    $TmpRemoved = -not (Test-Path $TmpRoot)
}

Assert-Condition -Condition $TmpRemoved -Message "smoke test should remove the empty .tmp parent directory."
