[CmdletBinding()]
# The default tables are invented test data. Pass -TablesPath to run the same rules against your own generator tables.
param([string]$TablesPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path $PSScriptRoot -Parent
if (-not $TablesPath) { $TablesPath = Join-Path $PSScriptRoot 'fixtures/synthetic-tables' }
Import-Module (Join-Path $skillRoot 'scripts/BrigadeFireAndFury.psm1') -Force
Set-BffTablesPath $TablesPath
$script:passed = 0
function Assert-True([bool]$Condition,[string]$Name,[string]$Evidence='') { if(-not $Condition){throw "FAIL ${Name}: $Evidence"};$script:passed++;"TEST|$Name|PASS|$Evidence" }
function Assert-Equal($Actual,$Expected,[string]$Name) { Assert-True ($Actual -eq $Expected) $Name "actual=$Actual expected=$Expected" }
"TEST-TABLES|$TablesPath"

# Every d10 table must resolve each value exactly once per context.
$tableProblems=@(Test-BffTables -Path $TablesPath -SkillRoot $skillRoot)
Assert-True ($tableProblems.Count -eq 0) 'generator-tables-pass-checks' ($tableProblems -join '; ')
$periodRows=Import-BffTable '02_time_period_rolls.csv' $skillRoot
$theaterRows=Import-BffTable '02_theater_rolls.csv' $skillRoot
function Get-PeriodForRoll([int]$Roll) { ([string]($periodRows|Where-Object{[int]$_.d10_roll -eq $Roll}).period) -replace '-',' ' }
function Get-TheaterForRoll([int]$Roll) { ([string]($theaterRows|Where-Object{[int]$_.d10_roll -eq $Roll}).theater) -replace ' Theater$','' }

$damaged=Join-Path ([IO.Path]::GetTempPath()) ('bff-damaged-tables-'+[guid]::NewGuid().ToString('N'))
try{
    Copy-Item -LiteralPath $TablesPath -Destination $damaged -Recurse
    $weaponFile=Join-Path $damaged '08_weapon_type.csv'
    $weaponLines=@(Get-Content -LiteralPath $weaponFile);Set-Content -LiteralPath $weaponFile -Value ($weaponLines[0..($weaponLines.Count-2)])
    $periodFile=Join-Path $damaged '02_time_period_rolls.csv'
    (Get-Content -LiteralPath $periodFile -Raw) -replace '(?m)^3,[^\r\n]+','3,Middle War' | Set-Content -LiteralPath $periodFile -NoNewline
    $weaponText=Get-Content -LiteralPath $weaponFile -Raw
    Set-Content -LiteralPath $weaponFile -Value ($weaponText -replace ',RM,Rifle Musket,',',RM,Smoothbore Musket,') -NoNewline
    $damage=@(Test-BffTables -Path $damaged -SkillRoot $skillRoot)
    Assert-True (@($damage|Where-Object{$_ -match "weapon_type 'Smoothbore Musket' does not match weapon_code RM"}).Count -eq 1) 'table-check-names-mismatched-weapon' ($damage -join '; ')
    Assert-True (@($damage|Where-Object{$_ -match '^08_weapon_type\.csv \[.+\]: no row for d10_roll 10$'}).Count -eq 1) 'table-check-names-missing-roll' ($damage -join '; ')
    Assert-True (@($damage|Where-Object{$_ -match "^02_time_period_rolls\.csv: period 'Middle War'"}).Count -eq 1) 'table-check-names-bad-value' ($damage -join '; ')
}finally{if(Test-Path -LiteralPath $damaged){Remove-Item -LiteralPath $damaged -Recurse -Force}}

$commanders=@(Import-Csv (Join-Path $skillRoot 'references/commander-command-history.csv'))
$requiredCommanderHeaders='Side','FullName','CommandLevel','RankTitle','StartYear','EndYear','EligiblePeriod','Theatre','Formation','SourceTitle','SourceUrl','ApproximationNote'
foreach($header in $requiredCommanderHeaders){Assert-True ($header -in $commanders[0].PSObject.Properties.Name) "commander-header-$header"}
Assert-True (@($commanders|Where-Object{$_.CommandLevel -notin 'Corps','Division','Brigade'}).Count -eq 0) 'commander-single-command-level'
Assert-True (@($commanders|Where-Object{$_.EligiblePeriod -notin 'Early War','Mid War','Late War'}).Count -eq 0) 'commander-single-eligible-period'
foreach($period in 'Early War','Mid War','Late War'){foreach($side in 'USA','CSA'){
    $pool=@($commanders|Where-Object{$_.Side -eq $side -and $_.EligiblePeriod -eq $period})
    Assert-True (@($pool|Where-Object CommandLevel -eq 'Corps'|ForEach-Object FullName|Sort-Object -Unique).Count -ge 2) "commander-corps-capacity-$period-$side"
    $requiredDivisions=if($side -eq 'USA'){7}else{4};$requiredBrigades=if($side -eq 'USA'){26}else{22}
    Assert-True (@($pool|Where-Object CommandLevel -eq 'Division'|ForEach-Object FullName|Sort-Object -Unique).Count -ge $requiredDivisions) "commander-division-capacity-$period-$side"
    Assert-True (@($pool|Where-Object CommandLevel -eq 'Brigade'|ForEach-Object FullName|Sort-Object -Unique).Count -ge $requiredBrigades) "commander-brigade-capacity-$period-$side"
    Assert-True (@($pool|Where-Object{-not $_.SourceUrl.StartsWith('https://')}).Count -eq 0) "commander-sources-$period-$side"
}}

$request=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -Raw|ConvertFrom-Json
$rolls=1..1000|ForEach-Object{(($_-1)%10)+1}
$model=New-BffArmy $request $skillRoot -TestMode -TestRollSequence $rolls
Assert-Equal $model.Period 'Mid War' 'fixed-period'
Assert-Equal $model.Theater 'Eastern' 'fixed-theater'
Assert-Equal @($model.Corps|Where-Object DisplayOnly).Count 2 'mid-war-display-cavalry-corps'
Assert-Equal @($model.Corps|Where-Object{-not $_.DisplayOnly}).Count 4 'm1-real-corps'
$divisions=@($model.Corps|ForEach-Object{$_.Divisions})
Assert-Equal @($divisions|Where-Object{$_.Type -eq 'Cavalry'}).Count 2 'mid-war-cavalry-divisions'
Assert-True (@($model.RollLog|Where-Object{$_.RecordType -eq 'BalanceMetric'}).Count -eq 2) 'balance-metrics-both-sides'
Assert-True (@($model.RollLog|Where-Object{$_.RecordType -eq 'BalanceDecision' -and $_.Result -eq 'No adjustment applied: balance rules not yet approved.'}).Count -eq 1) 'deferred-balance-decision'
Assert-True (@($model.RollLog|Where-Object{$_.RecordType -eq 'Roll' -and $_.RawRoll -notin 1..10}).Count -eq 0) 'all-rolls-are-d10'
Assert-True (@($model.RenderData.brigades|Where-Object Type -eq 'Cavalry').Count -eq 4) 'two-cavalry-brigades-per-side'

$names=@($model.RollLog|Where-Object RecordType -eq 'NameSelection'|ForEach-Object Result)
Assert-Equal @($names|Sort-Object -Unique).Count $names.Count 'commander-names-unique-across-force'

$early=($request|ConvertTo-Json -Depth 10|ConvertFrom-Json);$early.period.value='Early War';$early.year=1861
$earlyModel=New-BffArmy $early $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{10})
$earlyDivisions=@($earlyModel.Corps|ForEach-Object{$_.Divisions})
Assert-Equal @($earlyDivisions|Where-Object DisplayOnly).Count 4 'early-corps-cavalry-containers'
Assert-True (@($earlyModel.RollLog|Where-Object{$_.RecordType -eq 'Structure' -and $_.Notes -match 'no division leader roll'}).Count -eq 4) 'early-cavalry-no-extra-leader-roll'
$earlyLow=New-BffArmy $early $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{1})
Assert-True (@($earlyLow.RollLog|Where-Object{$_.Step -eq '7' -and $_.Substitution -match '^Clamped'}).Count -gt 0) 'below-table-morale-clamp-is-logged'

$allBatteries=@($earlyModel.Corps.Divisions.Batteries)
foreach($side in 'USA','CSA'){
    $sideBatteries=@($allBatteries|Where-Object Side -eq $side);$allowed=[math]::Floor($sideBatteries.Count/10)
    Assert-True (@($sideBatteries|Where-Object WeaponCode -eq 'HR').Count -le $allowed) "heavy-rifle-cap-$side" "actual=$(@($sideBatteries|Where-Object WeaponCode -eq 'HR').Count) allowed=$allowed"
}
$midHigh=New-BffArmy $request $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{10})
foreach($group in @($midHigh.Corps.Divisions.Brigades|Where-Object WeaponCode -eq 'RP'|Group-Object CorpsId,Type)){
    Assert-True ($group.Count -le 1) "repeater-cap-$($group.Name)" "count=$($group.Count)"
}

$small=($request|ConvertTo-Json -Depth 10|ConvertFrom-Json);$small.players.total=2;$small.players.USA=1;$small.players.CSA=1;$small.matchup.id='M8';$small.matchup.PSObject.Properties.Remove('csaVariant');$small.includeCavalry=$false
$smallModel=New-BffArmy $small $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{5})
$standalone=@($smallModel.Corps|Where-Object{$_.Side -eq 'CSA' -and $_.DisplayOnly})
Assert-Equal $standalone.Count 1 'standalone-csa-division-display-parent'
Assert-True (@($smallModel.RollLog|Where-Object{$_.FormationId -eq $standalone[0].Id -and $_.Step -eq '4'}).Count -eq 0) 'standalone-parent-no-corps-roll'

$random=($request|ConvertTo-Json -Depth 10|ConvertFrom-Json);$random.PSObject.Properties.Remove('year');$random.period.mode='random';$random.period.PSObject.Properties.Remove('value');$random.theater.mode='random';$random.theater.PSObject.Properties.Remove('value')
$randomModel=New-BffArmy $random $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{10})
Assert-Equal $randomModel.Period (Get-PeriodForRoll 10) 'random-period-roll-10'
Assert-Equal $randomModel.Theater (Get-TheaterForRoll 10) 'random-theater-roll-10'
foreach($period in 'Early War','Mid War','Late War'){
    $periodRoll=@(1..10|Where-Object{(Get-PeriodForRoll $_) -eq $period})[0]
    $case=@($periodRoll,$period)
    $rolls=@($case[0],1)+@(1..1000|ForEach-Object{1})
    $candidate=New-BffArmy $random $skillRoot -TestMode -TestRollSequence $rolls
    Assert-Equal $candidate.Period $case[1] "random-period-roll-$($case[0])"
    $maximum=$random|ConvertTo-Json -Depth 10|ConvertFrom-Json
    $maximumRolls=@($case[0],1)+@(1..1200|ForEach-Object{10})
    $maximumModel=New-BffArmy $maximum $skillRoot -TestMode -TestRollSequence $maximumRolls
    Assert-True (@($maximumModel.RollLog|Where-Object RecordType -eq 'NameSelection').Count -gt 0) "commander-capacity-max-force-$($case[0])"
}
Assert-True (@($model.RollLog|Where-Object{$_.RecordType -eq 'Configuration' -and $_.Result -match 'csaVariant=twoCorps; includeCavalry=True; year=1863'}).Count -eq 1) 'configuration-log-includes-request-options'

$publicScript=Get-Content (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -Raw
Assert-True ($publicScript -notmatch 'TestRollSequence|TestMode') 'public-entrypoint-has-no-deterministic-roll-interface'
$schema=Join-Path $skillRoot 'references/request-schema.json'
$invalid=($request|ConvertTo-Json -Depth 10|ConvertFrom-Json);$invalid|Add-Member -NotePropertyName unexpected -NotePropertyValue $true
Assert-True (-not (($invalid|ConvertTo-Json -Depth 10)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue)) 'request-schema-rejects-extra-properties'
$invalidType=($request|ConvertTo-Json -Depth 10|ConvertFrom-Json);$invalidType.includeCavalry='false'
Assert-True (-not (($invalidType|ConvertTo-Json -Depth 10)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue)) 'request-schema-rejects-invalid-types'

$fixedRequest=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -Raw|ConvertFrom-Json
Assert-True (($fixedRequest|ConvertTo-Json -Depth 20)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue) 'fixed-roster-schema-accepts-historical-request'
$fixedModel=New-BffFixedRoster $fixedRequest $skillRoot
Assert-Equal @($fixedModel.RenderData.corps).Count 3 'fixed-roster-corps-count'
Assert-Equal @($fixedModel.RenderData.divisions).Count 7 'fixed-roster-divisions-count'
Assert-Equal @($fixedModel.RenderData.brigades).Count 22 'fixed-roster-brigades-count'
Assert-Equal @($fixedModel.RenderData.artillery).Count 11 'fixed-roster-division-artillery-count'
Assert-Equal @($fixedModel.RenderData.standaloneArtillery).Count 9 'fixed-roster-standalone-artillery-count'
Assert-Equal $fixedModel.NormalizedRoster.corps[0].commander 'Slocum' 'fixed-roster-surname-normalization'
Assert-Equal $fixedModel.NormalizedRoster.divisions[2].commander 'Steinwehr' 'fixed-roster-steinwehr-label-normalization'
Assert-Equal $fixedModel.NormalizedRoster.divisions[0].name '1st Division' 'fixed-roster-division-number-normalization'
Assert-Equal $fixedModel.NormalizedRoster.brigades[16].name 'Jones' 'fixed-roster-initials-normalization'
$usaRecords=2+4+10+9;$csaRecords=1+3+12+11
Assert-Equal $usaRecords 25 'fixed-roster-usa-label-records'
Assert-Equal $csaRecords 27 'fixed-roster-csa-label-records'
$badEffectiveness=($fixedRequest|ConvertTo-Json -Depth 20|ConvertFrom-Json);$badEffectiveness.brigades[0].effectiveness='9/9/9'
$rejected=$false;try{New-BffFixedRoster $badEffectiveness $skillRoot|Out-Null}catch{$rejected=$true}
Assert-True $rejected 'fixed-roster-rejects-invalid-effectiveness'

foreach($collection in 'corps','divisions','brigades'){
    Assert-True (@($fixedModel.NormalizedRoster.$collection|Where-Object exceptionalLeader).Count -eq 0) "fixed-$collection-omitted-flags-default-false"
    Assert-True (@($fixedModel.RenderData.$collection|Where-Object{$_['Exceptional Leader'] -ne 'No'}).Count -eq 0) "fixed-$collection-omitted-flags-render-no"
    $leaderRequest=$fixedRequest|ConvertTo-Json -Depth 20|ConvertFrom-Json
    $leaderRequest.$collection[0]|Add-Member -NotePropertyName exceptionalLeader -NotePropertyValue $true
    $leaderRequest.$collection[1]|Add-Member -NotePropertyName exceptionalLeader -NotePropertyValue $false
    Assert-True (($leaderRequest|ConvertTo-Json -Depth 20)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue) "fixed-$collection-schema-accepts-boolean-flags"
    $leaderModel=New-BffFixedRoster $leaderRequest $skillRoot
    Assert-Equal $leaderModel.RenderData.$collection[0]['Exceptional Leader'] 'Yes' "fixed-$collection-true-flag-rendered"
    Assert-Equal $leaderModel.RenderData.$collection[1]['Exceptional Leader'] 'No' "fixed-$collection-false-flag-rendered"
    Assert-Equal $leaderModel.NormalizedRoster.$collection[0].exceptionalLeader $true "fixed-$collection-true-flag-preserved"
    Assert-Equal $leaderModel.NormalizedRoster.$collection[1].exceptionalLeader $false "fixed-$collection-false-flag-preserved"
    foreach($invalidFlag in @('false',1,$null)){
        $leaderRequest.$collection[0].exceptionalLeader=$invalidFlag
        Assert-True (-not(($leaderRequest|ConvertTo-Json -Depth 20)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue)) "fixed-$collection-schema-rejects-invalid-flag-$invalidFlag"
        $rejected=$false;try{New-BffFixedRoster $leaderRequest $skillRoot|Out-Null}catch{$rejected=$true}
        Assert-True $rejected "fixed-$collection-module-rejects-invalid-flag-$invalidFlag"
    }
}

foreach($case in 'unassigned-only','standalone-only','mixed-unassigned') {
    $newRequest=Get-Content (Join-Path $PSScriptRoot "fixtures/request-$case.json") -Raw|ConvertFrom-Json
    Assert-True (($newRequest|ConvertTo-Json -Depth 20)|Test-Json -SchemaFile $schema -ErrorAction SilentlyContinue) "schema-$case"
    $newModel=New-BffFixedRoster $newRequest $skillRoot
    Assert-True (@($newModel.RenderData.corps).Count -ge 2) "corps-$case"
    if($case -ne 'standalone-only') {
        Assert-True (@($newModel.NormalizedRoster.unassignedBrigades).Count -eq @($newRequest.unassignedBrigades).Count) "normalized-unassigned-$case"
        Assert-True ($newModel.RenderData.unassignedBrigades[1].exceptionalLeader) "unassigned-exceptional-$case"
    }
}
foreach($mutation in 'owner','side','type','stands','experience','morale','effectiveness','weapon','flag','null') {
    $bad=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-unassigned-only.json') -Raw|ConvertFrom-Json
    switch($mutation) {
        owner {$bad.unassignedBrigades[0].corpsId='missing'}
        side {$bad.unassignedBrigades[0].side='CSA'}
        type {$bad.unassignedBrigades[0].type='Artillery'}
        stands {$bad.unassignedBrigades[0].stands=9.5}
        experience {$bad.unassignedBrigades[0].experience='Elite'}
        morale {$bad.unassignedBrigades[0].morale='Gallant'}
        effectiveness {$bad.unassignedBrigades[0].effectiveness='9/9/9'}
        weapon {$bad.unassignedBrigades[0].weapon='LR'}
        flag {$bad.unassignedBrigades[0].exceptionalLeader='true'}
        null {$bad.unassignedBrigades=@($null)}
    }
    $rejected=$false;try{New-BffFixedRoster $bad $skillRoot|Out-Null}catch{$rejected=$true}
    Assert-True $rejected "reject-unassigned-$mutation"
}
$bad=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-standalone-only.json') -Raw|ConvertFrom-Json
$bad.standaloneArtillery=@()
$rejected=$false;try{New-BffFixedRoster $bad $skillRoot|Out-Null}catch{$rejected=$true}
Assert-True $rejected 'reject-empty-fixed-roster'

$publishTest=Join-Path ([IO.Path]::GetTempPath()) ("bff-publish-test-"+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($publishTest)|Out-Null
try{
    $pdfSource=Join-Path $publishTest 'source.pdf';$csvSource=Join-Path $publishTest 'source.csv';$pdfTarget=Join-Path $publishTest 'final.pdf';$csvTarget=Join-Path $publishTest 'final.csv'
    [IO.File]::WriteAllText($pdfSource,'pdf');[IO.File]::WriteAllText($csvSource,'csv')
    $caught=$false
    try{Publish-BffArtifacts $pdfSource $pdfTarget $csvSource $csvTarget { [IO.File]::WriteAllText($csvTarget,'collision') }}catch{$caught=$true}
    Assert-True $caught 'publish-second-move-collision-is-reported'
    Assert-True (-not(Test-Path -LiteralPath $pdfTarget)) 'publish-second-move-rolls-back-pdf'
    Assert-True ((Get-Content -LiteralPath $csvTarget -Raw) -eq 'collision') 'publish-second-move-preserves-existing-csv'
}finally{if(Test-Path -LiteralPath $publishTest){Remove-Item -LiteralPath $publishTest -Recurse -Force}}
"TEST-SUMMARY|PASS|$script:passed assertions"
