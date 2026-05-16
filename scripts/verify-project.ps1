Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillName = "code-health-review-harness"
$SkillRoot = Join-Path $ProjectRoot "skills\$SkillName"

$RequiredFiles = @(
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "docs\usage.md",
    "docs\architecture.md",
    "docs\maintenance.md",
    "docs\roadmap.md",
    "docs\github-repo-checklist.md",
    "scripts\install-user-skill.ps1",
    "scripts\verify-project.ps1",
    "skills\$SkillName\SKILL.md",
    "skills\$SkillName\references\review-dimensions.md",
    "skills\$SkillName\references\report-template.md",
    "skills\$SkillName\references\evidence-rules.md",
    "skills\$SkillName\references\tooling-playbook.md",
    "skills\$SkillName\references\skill-resource-map.md",
    "skills\$SkillName\scripts\collect-repo-facts.ps1",
    "skills\$SkillName\scripts\run-safe-checks.ps1",
    ".github\PULL_REQUEST_TEMPLATE.md",
    ".github\ISSUE_TEMPLATE\bug_report.md",
    ".github\ISSUE_TEMPLATE\feature_request.md",
    ".github\workflows\validate.yml"
)

$Missing = @()
foreach ($RelativePath in $RequiredFiles) {
    $Path = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path $Path)) {
        $Missing += $RelativePath
    }
}

if ($Missing.Count -gt 0) {
    Write-Error "Missing required files:`n$($Missing -join "`n")"
}

$SkillFile = Join-Path $SkillRoot "SKILL.md"
$SkillContent = Get-Content -Path $SkillFile -Raw -Encoding UTF8
if ($SkillContent -notmatch "(?ms)^---\s*.*?name:\s*code-health-review-harness\s*.*?---") {
    throw "SKILL.md frontmatter must contain name: code-health-review-harness"
}

if ($SkillContent -notmatch "description:") {
    throw "SKILL.md frontmatter must contain description"
}

Write-Host "Project verification passed: $ProjectRoot"
