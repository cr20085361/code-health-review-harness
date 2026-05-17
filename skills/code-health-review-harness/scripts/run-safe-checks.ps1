param(
    [string]$RepoPath = (Get-Location).Path,
    [switch]$IncludeAudit,
    [switch]$IncludeDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$FullPath
    )

    $BaseFull = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $TargetFull = [System.IO.Path]::GetFullPath($FullPath)
    $BaseUri = New-Object System.Uri($BaseFull)
    $TargetUri = New-Object System.Uri($TargetFull)
    return [System.Uri]::UnescapeDataString($BaseUri.MakeRelativeUri($TargetUri).ToString()).Replace('/', '\')
}

function Test-IgnoredPath {
    param([string]$RelativePath)

    $Normalized = "\$RelativePath\"
    foreach ($Part in @("\.git\", "\code-health-reports\", "\node_modules\", "\.venv\", "\venv\", "\dist\", "\build\", "\coverage\", "\htmlcov\", "\.pytest_cache\", "\.tmp\", "\tmp\")) {
        if ($Normalized.IndexOf($Part, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }
    return $false
}

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [string]$Label
    )

    $Result = [ordered]@{
        label = $Label
        command = ($Command + " " + ($Arguments -join " ")).Trim()
        workingDirectory = $WorkingDirectory
        startedAt = (Get-Date).ToString("s")
        exitCode = $null
        durationSeconds = $null
        status = "not-run"
        outputTail = ""
    }

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        $Result.status = "skipped"
        $Result.outputTail = "Command not found: $Command"
        return [PSCustomObject]$Result
    }

    Push-Location $WorkingDirectory
    try {
        $Started = Get-Date
        $Output = & $Command @Arguments 2>&1 | Out-String
        $ExitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        $Duration = (Get-Date) - $Started
        $Result.exitCode = $ExitCode
        $Result.durationSeconds = [Math]::Round($Duration.TotalSeconds, 2)
        $Result.status = if ($ExitCode -eq 0) { "passed" } else { "failed" }
        if ($Output.Length -gt 5000) {
            $Result.outputTail = $Output.Substring($Output.Length - 5000)
        }
        else {
            $Result.outputTail = $Output
        }
    }
    catch {
        $Duration = (Get-Date) - $Started
        $Result.durationSeconds = [Math]::Round($Duration.TotalSeconds, 2)
        $Result.status = "error"
        $Result.outputTail = $_.Exception.Message
    }
    finally {
        Pop-Location
    }

    return [PSCustomObject]$Result
}

function Get-PackageManager {
    param([string]$Directory)

    if (Test-Path (Join-Path $Directory "pnpm-lock.yaml")) { return "pnpm" }
    if (Test-Path (Join-Path $Directory "yarn.lock")) { return "yarn" }
    return "npm"
}

function Get-RunArguments {
    param(
        [string]$PackageManager,
        [string]$ScriptName
    )

    if ($PackageManager -eq "yarn") { return @($ScriptName) }
    return @("run", $ScriptName)
}

function Get-PowerShellCommand {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { return "pwsh" }
    if (Get-Command powershell -ErrorAction SilentlyContinue) { return "powershell" }
    return $null
}

function Get-PowerShellArguments {
    param(
        [string]$PowerShellCommand,
        [string]$ScriptPath
    )

    if ($PowerShellCommand -eq "powershell") {
        return @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    }

    return @("-NoProfile", "-File", $ScriptPath)
}

$Root = (Resolve-Path $RepoPath).Path
$Results = @()

$PackageJsonFiles = Get-ChildItem -Path $Root -Recurse -Filter package.json -File -ErrorAction SilentlyContinue | Where-Object {
    $Relative = Get-RelativePath -BasePath $Root -FullPath $_.FullName
    -not (Test-IgnoredPath -RelativePath $Relative)
}

foreach ($PackageJson in $PackageJsonFiles) {
    $Directory = Split-Path -Parent $PackageJson.FullName
    $PackageManager = Get-PackageManager -Directory $Directory
    $Json = $null
    try {
        $Json = Get-Content -Path $PackageJson.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $Results += [PSCustomObject]@{
            label = "parse package.json"
            command = "read package.json"
            workingDirectory = $Directory
            exitCode = 1
            durationSeconds = 0
            status = "failed"
            outputTail = $_.Exception.Message
        }
        continue
    }

    $ScriptNames = @()
    if ($Json.PSObject.Properties.Name -contains "scripts" -and $null -ne $Json.scripts) {
        $ScriptNames = $Json.scripts.PSObject.Properties.Name
    }

    foreach ($ScriptName in @("typecheck", "lint", "test", "build")) {
        if ($ScriptNames -contains $ScriptName) {
            $Results += Invoke-SafeCommand -Command $PackageManager -Arguments (Get-RunArguments -PackageManager $PackageManager -ScriptName $ScriptName) -WorkingDirectory $Directory -Label "package:$ScriptName"
        }
    }

    if ($IncludeAudit -and $PackageManager -eq "npm" -and (Test-Path (Join-Path $Directory "package-lock.json"))) {
        $Results += Invoke-SafeCommand -Command "npm" -Arguments @("audit", "--json") -WorkingDirectory $Directory -Label "package:audit"
    }
}

$PowerShellValidationScripts = @()
$VerifyProjectScript = Join-Path $Root "scripts\verify-project.ps1"
if (Test-Path $VerifyProjectScript) {
    $PowerShellValidationScripts += [PSCustomObject]@{
        label = "powershell:verify-project"
        path = $VerifyProjectScript
    }
}

$SmokeScript = Join-Path $Root "scripts\test-harness-smoke.ps1"
if (Test-Path $SmokeScript) {
    if ($env:CODE_HEALTH_HARNESS_SMOKE_RUNNING -eq "1") {
        $Results += [PSCustomObject]@{
            label = "powershell:test-harness-smoke"
            command = $SmokeScript
            workingDirectory = $Root
            exitCode = $null
            durationSeconds = 0
            status = "skipped"
            outputTail = "Skipped while smoke test is already running to avoid recursive execution."
        }
    }
    else {
        $PowerShellValidationScripts += [PSCustomObject]@{
            label = "powershell:test-harness-smoke"
            path = $SmokeScript
        }
    }
}

if ($PowerShellValidationScripts.Count -gt 0) {
    $PowerShellCommand = Get-PowerShellCommand
    if ($null -eq $PowerShellCommand) {
        foreach ($Script in $PowerShellValidationScripts) {
            $Results += [PSCustomObject]@{
                label = $Script.label
                command = $Script.path
                workingDirectory = $Root
                exitCode = $null
                durationSeconds = 0
                status = "skipped"
                outputTail = "PowerShell command not found: pwsh/powershell"
            }
        }
    }
    else {
        foreach ($Script in $PowerShellValidationScripts) {
            $Results += Invoke-SafeCommand -Command $PowerShellCommand -Arguments (Get-PowerShellArguments -PowerShellCommand $PowerShellCommand -ScriptPath $Script.path) -WorkingDirectory $Root -Label $Script.label
        }
    }
}

$PythonTestCandidates = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $Relative = Get-RelativePath -BasePath $Root -FullPath $_.FullName
    (-not (Test-IgnoredPath -RelativePath $Relative)) -and ($Relative -match "(^|\\)(tests?|__tests__)\\" -or $Relative -match "test_.*\.py$|.*_test\.py$")
} | Select-Object -First 1

if ($PythonTestCandidates) {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $Results += Invoke-SafeCommand -Command "python" -Arguments @("-m", "pytest") -WorkingDirectory $Root -Label "python:pytest"
    }
    elseif (Get-Command pytest -ErrorAction SilentlyContinue) {
        $Results += Invoke-SafeCommand -Command "pytest" -Arguments @() -WorkingDirectory $Root -Label "python:pytest"
    }
    else {
        $Results += [PSCustomObject]@{
            label = "python:pytest"
            command = "python -m pytest"
            workingDirectory = $Root
            exitCode = $null
            durationSeconds = 0
            status = "skipped"
            outputTail = "Python or pytest not found."
        }
    }
}

if ($IncludeDocker) {
    $ComposeFile = Get-ChildItem -Path $Root -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml") } | Select-Object -First 1
    if ($ComposeFile) {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            $Results += Invoke-SafeCommand -Command "docker" -Arguments @("compose", "config") -WorkingDirectory $Root -Label "docker:compose-config"
        }
        elseif (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            $Results += Invoke-SafeCommand -Command "docker-compose" -Arguments @("config") -WorkingDirectory $Root -Label "docker:compose-config"
        }
        else {
            $Results += [PSCustomObject]@{
                label = "docker:compose-config"
                command = "docker compose config"
                workingDirectory = $Root
                exitCode = $null
                durationSeconds = 0
                status = "skipped"
                outputTail = "Docker command not found."
            }
        }
    }
}

[PSCustomObject]@{
    repoPath = $Root
    ranAt = (Get-Date).ToString("s")
    includeAudit = [bool]$IncludeAudit
    includeDocker = [bool]$IncludeDocker
    results = $Results
} | ConvertTo-Json -Depth 8
