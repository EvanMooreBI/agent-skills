<#
.SYNOPSIS
    Builds one zip per skill in dist/, for upload to Claude (claude.ai and Cowork).

.DESCRIPTION
    Each zip holds a single top-level folder named after the skill, with SKILL.md
    inside it. Python caches are left out.
#>
[CmdletBinding()]
param([string]$OutputPath = (Join-Path $PSScriptRoot '../dist'))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$staging = Join-Path ([IO.Path]::GetTempPath()) ("agent-skills-zip-" + [guid]::NewGuid())
try {
    foreach ($skillMd in Get-ChildItem -Path (Join-Path $repoRoot 'plugins/*/skills/*/SKILL.md') -File) {
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
}
finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
