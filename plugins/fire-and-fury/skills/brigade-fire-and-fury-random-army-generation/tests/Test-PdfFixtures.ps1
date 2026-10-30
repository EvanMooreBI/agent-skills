[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$BaselineDirectory,
    [switch]$CaptureBaseline,
    [string]$TablesPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $OutputDirectory) { throw "Output already exists: $OutputDirectory" }
$skillRoot = Split-Path $PSScriptRoot -Parent
if (-not $TablesPath) { $TablesPath = Join-Path $PSScriptRoot 'fixtures/synthetic-tables' }
Import-Module (Join-Path $skillRoot 'scripts/BrigadeFireAndFury.psm1') -Force
Set-BffTablesPath $TablesPath
# Names are deterministic only in this test process. Production code is untouched.
& (Get-Module BrigadeFireAndFury) { Set-Item Function:script:Get-BffSecureIndex { param([int]$Maximum) 0 } }
$rolls = @(1..1000 | ForEach-Object { (($_ - 1) % 10) + 1 })
function Save-Fixture([string]$Name, [object]$Request, [object]$Model) {
    $directory = Join-Path $OutputDirectory $Name
    [void][IO.Directory]::CreateDirectory($directory)
    foreach ($item in @(@('request.json', $Request), @('model.json', $Model))) {
        [IO.File]::WriteAllText((Join-Path $directory $item[0]), ($item[1] | ConvertTo-Json -Depth 40), [Text.UTF8Encoding]::new($false))
    }
}
foreach ($period in @(@('Early War',1861), @('Mid War',1863), @('Late War',1865))) {
    foreach ($theater in 'Eastern','Western') {
        $request = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $request.period.value = $period[0]; $request.year = $period[1]; $request.theater.value = $theater
        $model = New-BffArmy $request $skillRoot -TestMode -TestRollSequence $rolls
        Save-Fixture (($period[0] -replace ' War','').ToLowerInvariant() + '-' + $theater.ToLowerInvariant()) $request $model
    }
}
foreach ($case in 'historical','exceptional','text-fitting') {
    $request = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($case -eq 'exceptional') {
        foreach ($collection in 'corps','divisions','brigades') { $request.$collection[0] | Add-Member exceptionalLeader $true }
    }
    if ($case -eq 'text-fitting') {
        $request.divisions[0].commander='Ricketts'; $request.divisions[1].commander='Hatch'
        $request.brigades[0].name='iiiiiiiiiiii'; $request.brigades[1].name='WWWWWWWWWWWW'; $request.brigades[2].name='MMMMMMM'
    }
    Save-Fixture $case $request (New-BffFixedRoster $request $skillRoot)
}
foreach ($case in 'unassigned-only','standalone-only','mixed-unassigned') {
    $request = Get-Content -LiteralPath (Join-Path $PSScriptRoot "fixtures/request-$case.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    Save-Fixture $case $request (New-BffFixedRoster $request $skillRoot)
}
$arguments = @('-B', (Join-Path $PSScriptRoot 'build_pdf_fixtures.py'), $OutputDirectory)
if ($CaptureBaseline) { $arguments += '--capture-baseline' }
if ($BaselineDirectory) { $arguments += @('--baseline-directory', [IO.Path]::GetFullPath($BaselineDirectory)) }
& python @arguments
if ($LASTEXITCODE -ne 0) { throw 'Retained PDF fixtures failed.' }
