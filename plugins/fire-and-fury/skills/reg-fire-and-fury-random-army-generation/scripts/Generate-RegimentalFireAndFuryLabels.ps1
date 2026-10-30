<#
.SYNOPSIS
Generate Regimental Fire and Fury labels and a CSV generation log.
.DESCRIPTION
Render 24 x 25 mm labels directly to a combined PDF. Preserve the existing
Regimental rules and request choices. Excel is not required.
.PARAMETER RequestPath
Path to the confirmed UTF-8 request JSON.
.PARAMETER OutputDirectory
Existing destination directory. Defaults to the user's Downloads folder.
.EXAMPLE
pwsh -NoProfile -File ./Generate-RegimentalFireAndFuryLabels.ps1 -RequestPath ./request.json -OutputDirectory C:/Labels
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RequestPath,[string]$OutputDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RegimentalFireAndFury.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'RffArtifacts.psm1') -Force
$skillRoot=Split-Path $PSScriptRoot -Parent
$RequestPath=[IO.Path]::GetFullPath($RequestPath)
if(-not(Test-Path -LiteralPath $RequestPath -PathType Leaf)){throw "Request JSON not found: $RequestPath"}
if(-not $OutputDirectory){$OutputDirectory=Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'}
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if(-not(Test-Path -LiteralPath $OutputDirectory -PathType Container)){throw "Output directory not found: $OutputDirectory"}
$baseName="Regimental Fire and Fury Unit Labels $(Get-Date -Format yyyy-MM-dd)"
$pdfTarget=Join-Path $OutputDirectory "$baseName.pdf"
$csvTarget=Join-Path $OutputDirectory "$baseName - Generation Log.csv"
foreach($path in $pdfTarget,$csvTarget){if(Test-Path -LiteralPath $path){throw "Refusing to overwrite existing output: $path"}}
foreach($command in 'node','python'){[void](Get-Command $command -ErrorAction Stop)}
$browser=Find-RffBrowser
& python -c 'import pymupdf'
if($LASTEXITCODE -ne 0){throw 'Python with PyMuPDF is required.'}
$request=Get-Content -LiteralPath $RequestPath -Raw -Encoding utf8|ConvertFrom-Json
$temporaryDirectory=Join-Path ([IO.Path]::GetTempPath()) ('rff-labels-'+[guid]::NewGuid().ToString('N'))
try {
    $model=New-RegimentalFireAndFuryArmy -Request $request -SkillRoot $skillRoot
    $build=Invoke-RffArtifactBuild -Model $model -Request $request -Directory $temporaryDirectory -Browser $browser
    Publish-RffArtifacts -PdfSource $build.Pdf -PdfTarget $pdfTarget -CsvSource $build.Csv -CsvTarget $csvTarget
    $batteries=@($model.Divisions.Brigades.Units|Where-Object Arm -eq 'Artillery')
    [pscustomobject]@{PdfPath=$pdfTarget;GenerationLogPath=$csvTarget;Period=$model.Period;Theatre=$model.Theatre;Sides=($model.Divisions.Side -join ', ');PdfPages=$build.Pages;Labels=$build.Labels;ActualBrigades=@($model.Divisions.Brigades|Where-Object IsActual).Count;Regiments=@($model.Divisions.Brigades.Units|Where-Object Arm -ne 'Artillery').Count;Batteries=$batteries.Count;ArtilleryGunLabels=[int](($batteries|Measure-Object Guns -Sum).Sum);LogRecords=$build.LogRecords;FallbackNamesUsed=$model.FallbackNamesUsed}|Format-List
} finally {
    if(Test-Path -LiteralPath $temporaryDirectory){
        $resolved=(Resolve-Path -LiteralPath $temporaryDirectory).Path
        $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if(-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'rff-labels-*'){throw 'Unexpected temporary cleanup path.'}
        [IO.Directory]::Delete($resolved,$true)
    }
}
