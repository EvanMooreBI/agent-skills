[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
$skillRoot=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $skillRoot 'scripts/RegimentalFireAndFury.psm1') -Force
Import-Module (Join-Path $skillRoot 'scripts/RffArtifacts.psm1') -Force
$module=Get-Module RegimentalFireAndFury
& $module {Set-Item -Path Function:script:Get-SecureIndex -Value {param([int]$Maximum) 0}}
$force={ [ordered]@{division=@{};brigades=@(1..5|ForEach-Object{@{type=$(if($_ -le 3){'Infantry'}else{'Cavalry'});regimentNames=@();regimentCommanders=@()}});independent=@{infantry=2;cavalry=2;artillery=2;unitNames=@();unitCommanders=@()};divisionArtillery=@{batteryNames=@();batteryCommanders=@()}} }
$maximum=[ordered]@{theatre='Western';period='Late War';mountainHowitzerEligible=$false;forces=[ordered]@{USA=(& $force);CSA=(& $force)}}
$cavalry=[ordered]@{theatre='Eastern';period='Mid War';mountainHowitzerEligible=$false;forces=@{USA=@{division=@{};brigades=@();independent=@{infantry=0;cavalry=61;artillery=0;unitNames=@();unitCommanders=@()};divisionArtillery=@{batteryNames=@();batteryCommanders=@()}}}}
foreach($entry in ([ordered]@{'maximum-both-sides'=$maximum;'sixty-one-independent-cavalry'=$cavalry}).GetEnumerator()){
    $folder=Join-Path $OutputDirectory $entry.Key
    if(Test-Path -LiteralPath $folder){throw "Test output already exists: $folder"}
    $request=$entry.Value|ConvertTo-Json -Depth 20|ConvertFrom-Json
    $model=New-RegimentalFireAndFuryArmy $request $skillRoot -TestMode -TestRollSequence (1..20000|ForEach-Object{10})
    $build=Invoke-RffArtifactBuild $model $request $folder (Find-RffBrowser)
    "FIXTURE|$($entry.Key)|PASS|pages=$($build.Pages) labels=$($build.Labels)"
}
