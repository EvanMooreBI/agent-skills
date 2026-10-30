Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skillRoot=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $skillRoot 'scripts/RegimentalFireAndFury.psm1') -Force
$rules=Get-RffRules $skillRoot
$script:passed=0
function Assert-True([bool]$Condition,[string]$Name,[string]$Evidence=''){
    if(-not $Condition){throw "FAIL ${Name}: $Evidence"};$script:passed++;"TEST|$Name|PASS|$Evidence"
}
function Assert-Equal($Actual,$Expected,[string]$Name){Assert-True ($Actual -eq $Expected) $Name "actual=$Actual expected=$Expected"}
function New-TestRequest([string]$Json){$Json|ConvertFrom-Json}

# Every direct 1D10 table has exactly ten entries in every context.
foreach($arm in 'Infantry','Cavalry'){
    foreach($period in 'Early War','Mid War','Late War'){foreach($side in 'USA','CSA'){
        Assert-Equal @($rules.table4.$arm.$period.$side).Count 10 "table4-$arm-$period-$side"
    }}
}
foreach($arm in 'Infantry','Cavalry','Artillery'){
    foreach($period in 'Early War','Mid War','Late War'){foreach($side in 'USA','CSA'){
        Assert-Equal @($rules.table5.$arm.$period.$side).Count 10 "table5-$arm-$period-$side"
    }}
    foreach($theatre in 'Eastern','Western'){foreach($period in 'Early War','Mid War','Late War'){foreach($side in 'USA','CSA'){
        Assert-Equal @($rules.table7.$arm.$theatre.$period.$side).Count 10 "table7-$arm-$theatre-$period-$side"
    }}}
}
Assert-Equal (Resolve-Bands $rules.table1.USA.bands -99) 3 'open-ended-low'
Assert-Equal (Resolve-Bands $rules.table1.USA.bands 99) 6 'open-ended-high'
Assert-Equal $rules.table5.Infantry.'Late War'.USA[1] 'Trained' 'normalized-late-usa-roll-2'
Assert-Equal $rules.table6Modifiers.Crack 2 'crack-modifier'

# Historical pools cover every side/theatre/period/role and side/theatre/period/arm bucket.
$commanders=@(Import-Csv (Join-Path $skillRoot 'references/commander-names.csv'));$unitsData=@(Import-Csv (Join-Path $skillRoot 'references/unit-names.csv'))
function Matches-Bucket([string]$Value,[string]$Wanted){$Value -in 'All','Both' -or ($Value -split '\|') -contains $Wanted}
foreach($side in 'USA','CSA'){foreach($theatre in 'Eastern','Western'){foreach($period in 'Early War','Mid War','Late War'){
    foreach($role in 'Division','Brigade','Artillery','Regiment'){
        $coverage=@($commanders|Where-Object{$_.Side -eq $side -and (Matches-Bucket $_.Theatre $theatre) -and (Matches-Bucket $_.Period $period) -and (Matches-Bucket $_.Roles $role)}).Count
        Assert-True ($coverage -gt 0) "historical-commander-$side-$theatre-$period-$role" "rows=$coverage"
    }
    foreach($arm in 'Infantry','Cavalry','Artillery'){
        $coverage=@($unitsData|Where-Object{$_.Side -eq $side -and (Matches-Bucket $_.Theatre $theatre) -and (Matches-Bucket $_.Period $period) -and $_.Arm -eq $arm}).Count
        Assert-True ($coverage -gt 0) "historical-unit-$side-$theatre-$period-$arm" "rows=$coverage"
    }
}}}

$cavalryRequest=New-TestRequest @'
{"theatre":"Eastern","period":"Mid War","mountainHowitzerEligible":false,"forces":{"USA":{"division":{},"brigades":[{"type":"Cavalry","regimentNames":[],"regimentCommanders":[]}],"independent":{"infantry":0,"cavalry":0,"artillery":0,"unitNames":[],"unitCommanders":[]},"divisionArtillery":{"batteryNames":[],"batteryCommanders":[]}}}}
'@
$cavalry=New-RegimentalFireAndFuryArmy $cavalryRequest $skillRoot -TestMode -TestRollSequence (1..300|ForEach-Object{10})
$units=@($cavalry.Divisions.Brigades.Units|Where-Object Arm -eq 'Cavalry')
Assert-Equal $units.Count 6 'table1-high-band-six-regiments'
Assert-Equal @($units|Where-Object BraveColonel).Count 2 'brave-colonel-cap'
Assert-Equal @($units|Where-Object WeaponCode -eq 'RPC').Count 3 'repeater-cap-retains-three'
Assert-Equal @($units|Where-Object WeaponCode -eq 'BLC').Count 3 'repeater-cap-substitutes-breechloader'
Assert-True (@($cavalry.RollLog|Where-Object {$_.Table -eq '6' -and $_.Modifiers -match 'Crack \+2'}).Count -eq $cavalry.Divisions.Brigades.Units.Count) 'crack-plus-two-applied-before-resolution'
$labelRows=Get-UnitLabelRows $cavalry $units[0] $cavalry.Divisions[0].Brigades[0]
Assert-Equal $labelRows.Rows.Count 3 'regiment-retains-three-rows'
Assert-True $labelRows.Brave 'brave-colonel-retained-in-label-data'
Assert-True ($labelRows.Rows[0] -match '^\(.+\)$') 'parent-commander-parentheses'
$dismountedRows=Get-UnitLabelRows $cavalry $units[0] $cavalry.Divisions[0].Brigades[0] -Dismounted
Assert-True ($dismountedRows.Rows[1] -like 'Dismounted *') 'dismounted-label-prefix'
$order=@{'1'=1;'2'=2;'2.1'=3;'3'=4;'3.1'=5;'4'=6;'5'=7;'6'=8;'7'=9;'7*'=10};$numbers=@($cavalry.RollLog|ForEach-Object{$order[$_.Table]})
$sorted=@($numbers|Sort-Object);Assert-True (($numbers -join ',') -eq ($sorted -join ',')) 'global-table-order' ($cavalry.RollLog.Table -join ',')

$oneRequest=New-TestRequest @'
{"theatre":"Eastern","period":"Early War","mountainHowitzerEligible":false,"forces":{"CSA":{"division":{},"brigades":[{"type":"Infantry","regimentNames":[],"regimentCommanders":[]}],"independent":{"infantry":0,"cavalry":0,"artillery":0,"unitNames":[],"unitCommanders":[]},"divisionArtillery":{"batteryNames":[],"batteryCommanders":[]}}}}
'@
$one=New-RegimentalFireAndFuryArmy $oneRequest $skillRoot -TestMode -TestRollSequence (1..300|ForEach-Object{1})
Assert-Equal @($one.Divisions.Brigades.Units|Where-Object Arm -eq 'Artillery').Count 1 'one-brigade-artillery-column'
Assert-True ($one.Divisions.Name -match "'s Division$|s' Division$") 'csa-possessive-division' $one.Divisions.Name
Assert-True (($one.Divisions.Brigades|Where-Object IsActual).Name -match "('s|s')$") 'csa-possessive-brigade' (($one.Divisions.Brigades|Where-Object IsActual).Name)

$heavyRequest=New-TestRequest @'
{"theatre":"Western","period":"Mid War","mountainHowitzerEligible":false,"forces":{"USA":{"division":{},"brigades":[{"type":"Infantry","regimentNames":[],"regimentCommanders":[]}],"independent":{"infantry":0,"cavalry":0,"artillery":1,"unitNames":[],"unitCommanders":[]},"divisionArtillery":{"batteryNames":[],"batteryCommanders":[]}}}}
'@
$heavy=New-RegimentalFireAndFuryArmy $heavyRequest $skillRoot -TestMode -TestRollSequence (1..400|ForEach-Object{10})
$art=@($heavy.Divisions.Brigades.Units|Where-Object Arm -eq 'Artillery')
Assert-Equal @($art|Where-Object WeaponCode -eq 'HR').Count 1 'heavy-rifle-cap-retains-one'
Assert-Equal @($art|Where-Object WeaponCode -eq 'LR').Count ($art.Count-1) 'heavy-rifle-cap-substitution'
Assert-Equal ($heavy.Divisions.Brigades|Where-Object IsActual).Name '1st Brigade' 'usa-numbered-brigade'

$mountainRequest=New-TestRequest @'
{"theatre":"Western","period":"Early War","mountainHowitzerEligible":true,"forces":{"USA":{"division":{},"brigades":[{"type":"Infantry","regimentNames":[],"regimentCommanders":[]}],"independent":{"infantry":0,"cavalry":0,"artillery":0,"unitNames":[],"unitCommanders":[]},"divisionArtillery":{"batteryNames":[],"batteryCommanders":[]}}}}
'@
$mountain=New-RegimentalFireAndFuryArmy $mountainRequest $skillRoot -TestMode -TestRollSequence (1..300|ForEach-Object{1})
Assert-True (@($mountain.Divisions.Brigades.Units|Where-Object {$_.Arm -eq 'Artillery' -and $_.WeaponCode -eq 'MH'}).Count -gt 0) 'mountain-howitzer-substitution'
Assert-True (@($mountain.RollLog|Where-Object Table -eq '7*').Count -gt 0) 'mountain-howitzer-extra-roll-logged'

$overrideRequest=New-TestRequest @'
{"theatre":"Eastern","period":"Mid War","mountainHowitzerEligible":false,"forces":{"USA":{"division":{"name":"Test Division","commander":"Test Commander","talent":"Gallant"},"brigades":[{"type":"Infantry","name":"Test Brigade","commander":"Brigade Tester","talent":"Able","regimentNames":["Test Regiment"],"regimentCommanders":["Colonel Tester"]}],"independent":{"infantry":0,"cavalry":0,"artillery":0,"unitNames":[],"unitCommanders":[]},"divisionArtillery":{"commander":"Chief Tester","talent":"Poor","batteryNames":["Test Battery"],"batteryCommanders":["Captain Tester"]}}}}
'@
$override=New-RegimentalFireAndFuryArmy $overrideRequest $skillRoot -TestMode -TestRollSequence (1..300|ForEach-Object{1})
Assert-Equal $override.Divisions.Name 'Test Division' 'division-name-override'
Assert-Equal ($override.Divisions.Brigades|Where-Object IsActual).Name 'Test Brigade' 'brigade-name-override'
Assert-Equal ($override.Divisions.Brigades|Where-Object IsActual).Units[0].Name 'Test Regiment' 'unit-name-override'
Assert-Equal ($override.Divisions.Brigades|Where-Object IsDivisionArtillery).Units[0].Name 'Test Battery' 'battery-name-override'
Assert-True (@($override.RollLog|Where-Object {$_.Table -eq '2' -and $_.RawRoll -eq 0 -and $_.Modifiers -eq 'Override'}).Count -eq 3) 'talent-overrides-do-not-consume-dice'

$duplicateFailed=$false
try{$bad=($overrideRequest|ConvertTo-Json -Depth 20|ConvertFrom-Json);$bad.forces.USA.brigades[0].commander='Test Commander';[void](New-RegimentalFireAndFuryArmy $bad $skillRoot -TestMode -TestRollSequence (1..300|ForEach-Object{1}))}catch{$duplicateFailed=$_.Exception.Message -match 'Duplicate override'}
Assert-True $duplicateFailed 'duplicate-name-override-rejected'
"TEST-SUMMARY|PASS|$script:passed assertions"
