[CmdletBinding()]
param(
    # Folder that holds the generator tables. Defaults to the local resource folder.
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BrigadeFireAndFury.psm1') -Force
if (-not $Path) { $Path = Get-BffTablesPath }
$Path = [System.IO.Path]::GetFullPath($Path)
$failures = @(Test-BffTables -Path $Path)
if ($failures.Count) {
    "TABLES|FAIL|$($failures.Count) problem(s) in $Path"
    $failures | ForEach-Object { "PROBLEM|$_" }
    exit 1
}
"TABLES|PASS|$Path"
