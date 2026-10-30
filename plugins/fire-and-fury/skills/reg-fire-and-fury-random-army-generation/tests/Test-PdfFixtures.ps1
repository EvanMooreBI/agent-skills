[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory,[string]$RealNameDataPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
$skillRoot=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $skillRoot 'scripts/RegimentalFireAndFury.psm1') -Force
Import-Module (Join-Path $skillRoot 'scripts/RffArtifacts.psm1') -Force
. (Join-Path $PSScriptRoot 'Fixtures.ps1')
. (Join-Path $PSScriptRoot 'RealNameFixtures.ps1')
$module=Get-Module RegimentalFireAndFury
# Deterministic name choice exists only in this test module scope.
& $module { Set-Item -Path Function:script:Get-SecureIndex -Value {param([int]$Maximum) 0} }
$browser=Find-RffBrowser
$golden=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/golden-armies.json') -Raw -Encoding utf8|ConvertFrom-Json -AsHashtable
# Real-name data is the optional local resource real-name-label-data.
if(-not $RealNameDataPath){
    $skillName=Split-Path $skillRoot -Leaf
    $roots=@()
    if($env:AGENT_SKILLS_LOCAL){$roots+=Join-Path $env:AGENT_SKILLS_LOCAL "$skillName/real-name-label-data"}
    $roots+=Join-Path ([Environment]::GetFolderPath('UserProfile')) ".agent-skills/local/$skillName/real-name-label-data"
    $RealNameDataPath=@($roots|Where-Object{Test-Path -LiteralPath $_ -PathType Container}|ForEach-Object{Get-ChildItem -LiteralPath $_ -Filter '*.csv' -File|Sort-Object Name}|Select-Object -First 1|ForEach-Object FullName)|Select-Object -First 1
}
$realFixtures=@{}
if($RealNameDataPath){
    $RealNameDataPath=(Resolve-Path -LiteralPath $RealNameDataPath -ErrorAction Stop).Path
    $realFixtures=Get-RffRealNameFixtures $RealNameDataPath
}else{
    "FIXTURE|real-names|SKIP|no real-name-label-data CSV; pass -RealNameDataPath or add the local resource"
}
$reports=[System.Collections.Generic.List[object]]::new()
foreach($entry in $fixtures.GetEnumerator()){
    $name=$entry.Key;$request=$entry.Value
    $model=New-RegimentalFireAndFuryArmy $request $skillRoot -TestMode -TestRollSequence (1..12000|ForEach-Object{(($_-1)%10)+1})
    $projection=$model|Select-Object Version,Theatre,Period,Year,Divisions,RollLog,FallbackNamesUsed
    $actual=$projection|ConvertTo-Json -Depth 40 -Compress
    $expected=$golden[$name]|ConvertTo-Json -Depth 40 -Compress
    if($actual -cne $expected){throw "Golden army/roll/name parity changed: $name"}
    $directory=Join-Path $OutputDirectory $name
    if(Test-Path -LiteralPath $directory){throw "Test output already exists: $directory"}
    $build=Invoke-RffArtifactBuild $model $request $directory $browser
    $reports.Add([pscustomobject]@{Fixture=$name;Pages=$build.Pages;Labels=$build.Labels;Records=$build.LogRecords;Golden='PASS'})
    "FIXTURE|$name|PASS|pages=$($build.Pages) labels=$($build.Labels)"
}
foreach($case in @('empty-side','text-fitting')){
    $request=Get-Content -LiteralPath (Join-Path $PSScriptRoot "fixtures/$case.json") -Raw -Encoding utf8|ConvertFrom-Json
    $model=New-RegimentalFireAndFuryArmy $request $skillRoot -TestMode -TestRollSequence (1..12000|ForEach-Object{10})
    $build=Invoke-RffArtifactBuild $model $request (Join-Path $OutputDirectory $case) $browser
    $reports.Add([pscustomobject]@{Fixture=$case;Pages=$build.Pages;Labels=$build.Labels;Records=$build.LogRecords;Golden='Additional regression'})
    "FIXTURE|$case|PASS|pages=$($build.Pages) labels=$($build.Labels)"
}
foreach($entry in $realFixtures.GetEnumerator()){
    $request=$entry.Value.Request|ConvertTo-Json -Depth 30|ConvertFrom-Json
    $model=New-RegimentalFireAndFuryArmy $request $skillRoot -TestMode -TestRollSequence $entry.Value.Rolls
    if($model.FallbackNamesUsed){throw "Real-name fixture used a generated fallback: $($entry.Key)"}
    $directory=Join-Path $OutputDirectory $entry.Key
    if(Test-Path -LiteralPath $directory){throw "Test output already exists: $directory"}
    $build=Invoke-RffArtifactBuild $model $request $directory $browser
    Copy-Item -LiteralPath $RealNameDataPath -Destination (Join-Path $directory 'real-name-source.csv') -ErrorAction Stop
    $source=[ordered]@{path=$RealNameDataPath;sha256=(Get-FileHash -LiteralPath $RealNameDataPath -Algorithm SHA256).Hash;purpose='Historical names only; organization and ratings use the existing random-army rules.'}
    $source|ConvertTo-Json|Out-File -LiteralPath (Join-Path $directory 'real-name-provenance.json') -Encoding utf8
    $reports.Add([pscustomobject]@{Fixture=$entry.Key;Pages=$build.Pages;Labels=$build.Labels;Records=$build.LogRecords;Golden='Maintained real-name CSV'})
    "FIXTURE|$($entry.Key)|PASS|pages=$($build.Pages) labels=$($build.Labels)"
}
$reports|ConvertTo-Json -Depth 5|Out-File -LiteralPath (Join-Path $OutputDirectory 'suite-results.json') -Encoding utf8
if($realFixtures.Count){
    & python -B (Join-Path $PSScriptRoot 'test-real-name-fixtures.py') $OutputDirectory
    if($LASTEXITCODE -ne 0){throw 'Real-name source reconciliation failed.'}
}
"FIXTURE-SUMMARY|PASS|$($reports.Count) PDFs and CSVs"
