<#
.SYNOPSIS
    Builds individual skill ZIPs plus the complete Career Workbench repository bundle.

.DESCRIPTION
    Each zip holds a single top-level folder named after the skill, with SKILL.md
    inside it. Python caches are left out. The default repo target permits Claude
    Code fields. Select portable for claude.ai/Cowork uploads; incompatible fields
    are rejected, never stripped.

    Career Workbench's dependent skills ship together. Its committed combined
    repository-install archive replaces individual career skill ZIPs.
#>
[CmdletBinding()]
param(
    [string]$OutputPath,
    [ValidateSet('repo', 'portable')][string]$Target = 'repo'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot 'dist'
}
# Validate every input before creating an output directory or archive.
& python -B (Join-Path $repoRoot 'tools/validate_repo.py') --root $repoRoot --target $Target
if ($LASTEXITCODE -ne 0) {
    throw "Skill ZIP validation failed for target '$Target'; no archives were built."
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$staging = Join-Path ([IO.Path]::GetTempPath()) ("agent-skills-zip-" + [guid]::NewGuid())
try {
    foreach ($skillMd in Get-ChildItem -Path (Join-Path $repoRoot 'plugins/*/skills/*/SKILL.md') -File) {
        if ($skillMd.Directory.Parent.Parent.Name -eq 'job-search') { continue }
        $name = $skillMd.Directory.Name
        $copy = Join-Path $staging $name
        New-Item -ItemType Directory -Path $copy -Force | Out-Null
        Get-ChildItem -LiteralPath $skillMd.Directory.FullName -Force | Where-Object Name -ne '__pycache__' |
            Copy-Item -Destination $copy -Recurse -Force
        Get-ChildItem -LiteralPath $copy -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force
        $zip = Join-Path $OutputPath "$name.zip"
        Compress-Archive -Path $copy -DestinationPath $zip -Force
        Write-Host "Built $zip"
    }
    if (Test-Path -LiteralPath (Join-Path $repoRoot 'plugins/job-search')) {
        # Validation above has already checked the committed all-sibling archive.
        Copy-Item -LiteralPath (Join-Path $repoRoot 'bundles/career-workbench.zip') -Destination (Join-Path $OutputPath 'career-workbench.zip') -Force
        Write-Host 'Included the complete Career Workbench repository-install bundle (not a single-skill upload).'
    }
}
finally {
    $resolvedStaging = [IO.Path]::GetFullPath($staging)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not $resolvedStaging.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not ([IO.Path]::GetFileName($resolvedStaging)).StartsWith('agent-skills-zip-')) {
        throw "Refusing cleanup outside the task staging directory: $resolvedStaging"
    }
    if (Test-Path -LiteralPath $resolvedStaging) { Remove-Item -LiteralPath $resolvedStaging -Recurse -Force }
}
