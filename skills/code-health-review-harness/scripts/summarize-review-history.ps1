param(
    [string]$ReportsRoot = (Join-Path (Get-Location).Path "code-health-reports"),
    [string]$OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Count {
    param(
        [hashtable]$Table,
        [string]$Key
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        $Key = "unknown"
    }
    if ($Table.ContainsKey($Key)) {
        $Table[$Key] = $Table[$Key] + 1
    }
    else {
        $Table[$Key] = 1
    }
}

function Format-CountTable {
    param(
        [string]$Title,
        [hashtable]$Table
    )

    $Lines = @()
    $Lines += "## $Title"
    $Lines += ""
    $Lines += "| Value | Count |"
    $Lines += "|---|---:|"
    foreach ($Key in ($Table.Keys | Sort-Object)) {
        $Lines += "| $Key | $($Table[$Key]) |"
    }
    if ($Table.Count -eq 0) {
        $Lines += "| none | 0 |"
    }
    $Lines += ""
    return $Lines
}

function Read-VerificationRows {
    param([string]$Path)

    $Rows = @()
    if (-not (Test-Path $Path)) {
        return $Rows
    }

    $Lines = Get-Content -Path $Path -Encoding UTF8
    foreach ($Line in $Lines) {
        $Trimmed = $Line.Trim()
        if ($Trimmed -notmatch "^\|\s*VER-") {
            continue
        }
        $Cells = $Trimmed.Trim("|").Split("|") | ForEach-Object { $_.Trim() }
        if ($Cells.Count -lt 12) {
            continue
        }
        $Rows += [PSCustomObject]@{
            id = $Cells[0]
            related_finding = $Cells[1]
            priority = $Cells[2]
            test_type = $Cells[3]
            target_area = $Cells[4]
            status = $Cells[11]
            source = $Path
        }
    }
    return $Rows
}

function Resolve-InputPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

$ReportsRootFullPath = Resolve-InputPath -Path $ReportsRoot
if (Test-Path $ReportsRootFullPath) {
    $Root = (Resolve-Path $ReportsRootFullPath).Path
}
else {
    $Root = $ReportsRootFullPath
}
$FindingFiles = @(Get-ChildItem -Path $Root -Recurse -Filter findings.json -File -ErrorAction SilentlyContinue)

$Findings = @()
$VerificationRows = @()

foreach ($File in $FindingFiles) {
    try {
        $Json = Get-Content -Path $File.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $ReviewId = if ($Json.PSObject.Properties.Name -contains "review_id") { $Json.review_id } else { Split-Path (Split-Path $File.FullName -Parent) -Leaf }
        if ($Json.PSObject.Properties.Name -contains "findings" -and $null -ne $Json.findings) {
            foreach ($Finding in @($Json.findings)) {
                $Findings += [PSCustomObject]@{
                    id = if ($Finding.PSObject.Properties.Name -contains "id") { $Finding.id } else { "unknown" }
                    review_id = $ReviewId
                    severity = if ($Finding.PSObject.Properties.Name -contains "severity") { $Finding.severity } else { "unknown" }
                    dimension = if ($Finding.PSObject.Properties.Name -contains "dimension") { $Finding.dimension } else { "unknown" }
                    title = if ($Finding.PSObject.Properties.Name -contains "title") { $Finding.title } else { "" }
                    status = if ($Finding.PSObject.Properties.Name -contains "status") { $Finding.status } else { "unknown" }
                    source = $File.FullName
                }
            }
        }

        $SessionDirectory = Split-Path $File.FullName -Parent
        $VerificationRows += Read-VerificationRows -Path (Join-Path $SessionDirectory "verification-matrix.md")
    }
    catch {
        $Findings += [PSCustomObject]@{
            id = "parse-error"
            review_id = Split-Path (Split-Path $File.FullName -Parent) -Leaf
            severity = "unknown"
            dimension = "unknown"
            title = $_.Exception.Message
            status = "parse-error"
            source = $File.FullName
        }
    }
}

$StatusCounts = @{}
$SeverityCounts = @{}
$DimensionCounts = @{}
$VerificationStatusCounts = @{}

foreach ($Finding in $Findings) {
    Add-Count -Table $StatusCounts -Key $Finding.status
    Add-Count -Table $SeverityCounts -Key $Finding.severity
    Add-Count -Table $DimensionCounts -Key $Finding.dimension
}

foreach ($Row in $VerificationRows) {
    Add-Count -Table $VerificationStatusCounts -Key $Row.status
}

$Lines = @()
$Lines += "# Code Health Review History Summary"
$Lines += ""
$Lines += "Reports root: $Root"
$Lines += "Generated: $((Get-Date).ToString("s"))"
$Lines += "Finding files: $($FindingFiles.Count)"
$Lines += "Findings: $($Findings.Count)"
$Lines += "Verification rows: $($VerificationRows.Count)"
$Lines += ""
$Lines += Format-CountTable -Title "Findings By Status" -Table $StatusCounts
$Lines += Format-CountTable -Title "Findings By Severity" -Table $SeverityCounts
$Lines += Format-CountTable -Title "Findings By Dimension" -Table $DimensionCounts
$Lines += Format-CountTable -Title "Verification By Status" -Table $VerificationStatusCounts

$Lines += "## Latest Findings"
$Lines += ""
$Lines += "| Finding ID | Review ID | Severity | Status | Dimension | Title |"
$Lines += "|---|---|---|---|---|---|"
foreach ($Finding in ($Findings | Select-Object -Last 80)) {
    $Title = ($Finding.title -replace "\|", "/")
    $Dimension = ($Finding.dimension -replace "\|", "/")
    $Lines += "| $($Finding.id) | $($Finding.review_id) | $($Finding.severity) | $($Finding.status) | $Dimension | $Title |"
}
if ($Findings.Count -eq 0) {
    $Lines += "| none | none | none | none | none | No findings found. |"
}

$Summary = $Lines -join [Environment]::NewLine

if ($OutputPath) {
    $OutputFullPath = Resolve-InputPath -Path $OutputPath
    $OutputDirectory = Split-Path -Parent $OutputFullPath
    if ($OutputDirectory -and -not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    }
    Set-Content -Path $OutputFullPath -Value $Summary -Encoding UTF8
    Write-Host "Wrote history summary: $OutputFullPath"
}
else {
    $Summary
}
