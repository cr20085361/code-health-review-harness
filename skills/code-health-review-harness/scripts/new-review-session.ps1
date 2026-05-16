param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$OutputRoot = "code-health-reports",
    [string]$SessionName = "",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-Slug {
    param([string]$Value)

    $Lower = $Value.ToLowerInvariant()
    $Slug = [regex]::Replace($Lower, "[^a-z0-9]+", "-").Trim("-")
    if ([string]::IsNullOrWhiteSpace($Slug)) {
        return "repository"
    }
    return $Slug
}

function Write-TemplateFile {
    param(
        [string]$Path,
        [string]$Content,
        [bool]$Overwrite
    )

    if ((Test-Path $Path) -and -not $Overwrite) {
        throw "File already exists: $Path. Re-run with -Force to overwrite template files."
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

$Root = (Resolve-Path $RepoPath).Path
$RepoName = Split-Path $Root -Leaf
$RepoSlug = ConvertTo-Slug -Value $RepoName
$Timestamp = Get-Date -Format "yyyyMMdd-HHmm"

if ([string]::IsNullOrWhiteSpace($SessionName)) {
    $SessionName = "$Timestamp-$RepoSlug"
}

if ([System.IO.Path]::IsPathRooted($OutputRoot)) {
    $ReportsRoot = $OutputRoot
}
else {
    $ReportsRoot = Join-Path $Root $OutputRoot
}

$SessionPath = Join-Path $ReportsRoot $SessionName
$ArtifactsPath = Join-Path $SessionPath "artifacts"
$ReviewId = "CHR-$SessionName"

if ((Test-Path $SessionPath) -and -not $Force) {
    throw "Review session already exists: $SessionPath. Re-run with -Force to overwrite template files."
}

New-Item -ItemType Directory -Path $SessionPath -Force | Out-Null
New-Item -ItemType Directory -Path $ArtifactsPath -Force | Out-Null

$Metadata = [PSCustomObject]@{
    schema_version = "1.0"
    review_id = $ReviewId
    session_name = $SessionName
    repo_name = $RepoName
    repo_path = $Root
    created_at = (Get-Date).ToString("s")
    model = "unspecified"
    tools_used = @()
    command_runner_available = $null
    notes = @()
    artifacts = @(
        "review-report.md",
        "findings.json",
        "iteration-plan.md",
        "verification-matrix.md",
        "command-log.md",
        "artifacts/"
    )
}

$Findings = [PSCustomObject]@{
    schema_version = "1.0"
    review_id = $ReviewId
    repo = $RepoSlug
    created_at = (Get-Date).ToString("s")
    findings = @()
}

$ReviewReport = @"
# Code Health Review Report

Review ID: $ReviewId
Repository: $RepoName
Created: $((Get-Date).ToString("s"))

## Summary

- Health:
- One-line conclusion:
- Biggest strength:
- Biggest risk:
- Top 3 next actions:

## Score Table

| Dimension | Score 0-5 | Confidence | Evidence | Main Deduction |
|---|---:|---|---|---|
| Functional and product fit |  |  |  |  |
| Architecture and modularity |  |  |  |  |
| Backend and API |  |  |  |  |
| Frontend and interaction |  |  |  |  |
| Data, migration and lifecycle |  |  |  |  |
| Security and permissions |  |  |  |  |
| Testing and quality gates |  |  |  |  |
| Performance and capacity |  |  |  |  |
| Operations and delivery |  |  |  |  |
| Supply chain and repository health |  |  |  |  |
| Documentation and maintainability |  |  |  |  |
| Iteration economics |  |  |  |  |

## Strengths


## Findings

Use stable IDs from findings.json.

## P0/P1/P2 Roadmap

Each item must link to at least one Verification ID in verification-matrix.md.

## Commands Run

See command-log.md.

## Unverified Areas


## Human Confirmation Needed


"@

$IterationPlan = @"
# Iteration Plan

Review ID: $ReviewId

## Rules

- Every item must link to one or more Finding IDs.
- Every P0/P1 item must link to one or more Verification IDs.
- Do not close an item until its verification evidence is attached or the risk is explicitly accepted.

## P0

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|

## P1

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|

## P2

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|

"@

$VerificationMatrix = @"
# Verification Matrix

Review ID: $ReviewId

| Verification ID | Related Finding | Priority | Test Type | Target Area | Command/Method | Pass Criteria | Baseline | Target | Evidence Artifact | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|

Allowed Status: pending, running, passed, failed, blocked, accepted-risk. See references/status-taxonomy.md.

"@

$CommandLog = @"
# Command Log

Review ID: $ReviewId

| Command | Working Directory | Exit Code | Result | Evidence Artifact |
|---|---|---:|---|---|

"@

Write-TemplateFile -Path (Join-Path $SessionPath "metadata.json") -Content ($Metadata | ConvertTo-Json -Depth 6) -Overwrite ([bool]$Force)
Write-TemplateFile -Path (Join-Path $SessionPath "findings.json") -Content ($Findings | ConvertTo-Json -Depth 8) -Overwrite ([bool]$Force)
Write-TemplateFile -Path (Join-Path $SessionPath "review-report.md") -Content $ReviewReport -Overwrite ([bool]$Force)
Write-TemplateFile -Path (Join-Path $SessionPath "iteration-plan.md") -Content $IterationPlan -Overwrite ([bool]$Force)
Write-TemplateFile -Path (Join-Path $SessionPath "verification-matrix.md") -Content $VerificationMatrix -Overwrite ([bool]$Force)
Write-TemplateFile -Path (Join-Path $SessionPath "command-log.md") -Content $CommandLog -Overwrite ([bool]$Force)

Write-Host "Created review session: $SessionPath"
Write-Host "Review ID: $ReviewId"
