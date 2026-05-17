param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$OutputPath = ""
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
    $Ignored = @(
        "\.git\",
        "\code-health-reports\",
        "\node_modules\",
        "\.venv\",
        "\venv\",
        "\dist\",
        "\build\",
        "\coverage\",
        "\htmlcov\",
        "\.pytest_cache\",
        "\.tmp\",
        "\tmp\"
    )

    foreach ($Part in $Ignored) {
        if ($Normalized.IndexOf($Part, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }
    return $false
}

function Resolve-InputPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Invoke-GitText {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $GitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $GitCommand) {
        return $null
    }

    $StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $StartInfo.FileName = $GitCommand.Source
    $StartInfo.WorkingDirectory = $WorkingDirectory
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.CreateNoWindow = $true
    $StartInfo.Arguments = (($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_.Replace('"', '\"')) + '"'
        }
        else {
            $_
        }
    }) -join ' ')

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    $StandardOutput = $Process.StandardOutput.ReadToEnd()
    $null = $Process.StandardError.ReadToEnd()
    $Process.WaitForExit()

    if ($Process.ExitCode -ne 0) {
        return $null
    }

    return $StandardOutput.Trim()
}

$Root = (Resolve-Path (Resolve-InputPath -Path $RepoPath)).Path
$AllFiles = Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $Relative = Get-RelativePath -BasePath $Root -FullPath $_.FullName
    if (-not (Test-IgnoredPath -RelativePath $Relative)) {
        [PSCustomObject]@{
            RelativePath = $Relative
            FullName = $_.FullName
            Extension = if ($_.Extension) { $_.Extension.ToLowerInvariant() } else { "[none]" }
            Length = $_.Length
        }
    }
}

$ManifestPatterns = @(
    "package.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "package-lock.json",
    "pyproject.toml",
    "requirements.txt",
    "poetry.lock",
    "Pipfile",
    "Dockerfile",
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
    "tsconfig.json",
    "vite.config.ts",
    "vite.config.js",
    "pytest.ini"
)

$Manifests = $AllFiles | Where-Object {
    $Name = Split-Path $_.RelativePath -Leaf
    $ManifestPatterns -contains $Name
} | Select-Object -ExpandProperty RelativePath

$WorkflowFiles = $AllFiles | Where-Object {
    $_.RelativePath -match "^\.github\\workflows\\.+\.(yml|yaml)$"
} | Select-Object -ExpandProperty RelativePath

$DocFiles = $AllFiles | Where-Object {
    $_.RelativePath -match "(^|\\)(README|HANDOVER|CHANGELOG|CONTRIBUTING|SECURITY|LICENSE)(\.[^\\]+)?$" -or $_.RelativePath -match "^(docs|plans)\\"
} | Select-Object -First 80 -ExpandProperty RelativePath

$TestFiles = $AllFiles | Where-Object {
    $_.RelativePath -match "(^|\\)(tests?|__tests__)\\" -or $_.RelativePath -match "(test|spec)\.(ts|tsx|js|jsx|py)$"
} | Select-Object -First 120 -ExpandProperty RelativePath

$PackageScripts = @()
$PackageJsonFiles = $AllFiles | Where-Object { (Split-Path $_.RelativePath -Leaf) -eq "package.json" }
foreach ($PackageFile in $PackageJsonFiles) {
    try {
        $Json = Get-Content -Path $PackageFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $ScriptNames = @()
        if ($Json.PSObject.Properties.Name -contains "scripts" -and $null -ne $Json.scripts) {
            $ScriptNames = $Json.scripts.PSObject.Properties.Name
        }
        $PackageScripts += [PSCustomObject]@{
            packageJson = $PackageFile.RelativePath
            scripts = $ScriptNames
        }
    }
    catch {
        $PackageScripts += [PSCustomObject]@{
            packageJson = $PackageFile.RelativePath
            scripts = @()
            error = $_.Exception.Message
        }
    }
}

$ExtensionSummary = $AllFiles |
    Group-Object Extension |
    Sort-Object Count -Descending |
    Select-Object -First 25 @{Name="extension"; Expression={$_.Name}}, Count

$Facts = [PSCustomObject]@{
    repoPath = $Root
    collectedAt = (Get-Date).ToString("s")
    git = [PSCustomObject]@{
        branch = Invoke-GitText -Arguments @("branch", "--show-current") -WorkingDirectory $Root
        statusShort = Invoke-GitText -Arguments @("status", "--short") -WorkingDirectory $Root
        diffStat = Invoke-GitText -Arguments @("diff", "--stat") -WorkingDirectory $Root
    }
    fileCount = @($AllFiles).Count
    extensionSummary = @($ExtensionSummary)
    manifests = @($Manifests)
    workflows = @($WorkflowFiles)
    docs = @($DocFiles)
    tests = @($TestFiles)
    packageScripts = @($PackageScripts)
}

$JsonOutput = $Facts | ConvertTo-Json -Depth 8

if ($OutputPath) {
    $OutputFullPath = Resolve-InputPath -Path $OutputPath
    $OutputDirectory = Split-Path -Parent $OutputFullPath
    if ($OutputDirectory -and -not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    }
    Set-Content -Path $OutputFullPath -Value $JsonOutput -Encoding UTF8
    Write-Host "Wrote repo facts to: $OutputFullPath"
}
else {
    $JsonOutput
}
