param(
    [string]$TargetRoot = "$env:USERPROFILE\.agents\skills",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillName = "code-health-review-harness"
$Source = Join-Path $ProjectRoot "skills\$SkillName"
$Target = Join-Path $TargetRoot $SkillName

if (-not (Test-Path $Source)) {
    throw "Skill source not found: $Source"
}

if ((Test-Path $Target) -and -not $Force) {
    throw "Target already exists: $Target. Re-run with -Force to replace it."
}

if (-not (Test-Path $TargetRoot)) {
    New-Item -ItemType Directory -Path $TargetRoot | Out-Null
}

if (Test-Path $Target) {
    Remove-Item -Path $Target -Recurse -Force
}

Copy-Item -Path $Source -Destination $Target -Recurse

Write-Host "Installed skill to: $Target"
Write-Host "Trigger example: Run a full code health review for this repository."
