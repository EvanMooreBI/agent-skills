Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BffSkillRoot { Split-Path $PSScriptRoot -Parent }

# The rulebook's generator tables are a local resource; only the effectiveness table ships with the skill.
$script:BffSkillName = 'brigade-fire-and-fury-random-army-generation'
$script:BffBundledTables = @('07_brigade_effectiveness_table.csv')
$script:BffTablesPathOverride = $null

function Set-BffTablesPath {
    param([string]$Path)
    $script:BffTablesPathOverride = if ($Path) { [System.IO.Path]::GetFullPath($Path) } else { $null }
}

function Get-BffTablesPathCandidates {
    if ($script:BffTablesPathOverride) { return @($script:BffTablesPathOverride) }
    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($env:AGENT_SKILLS_LOCAL) { $candidates.Add((Join-Path $env:AGENT_SKILLS_LOCAL "$script:BffSkillName/generator-tables")) }
    $candidates.Add((Join-Path ([Environment]::GetFolderPath('UserProfile')) ".agent-skills/local/$script:BffSkillName/generator-tables"))
    @($candidates)
}

function Get-BffTablesPath {
    $candidates = @(Get-BffTablesPathCandidates)
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate '01_force_balance_matchups.csv') -PathType Leaf) { return $candidate }
    }
    throw ("Random armies need the Brigade generator tables, which are not bundled. Looked in: $($candidates -join '; '). " +
        "Follow 'Set up your rulebook tables' in SKILL.md to create them from photos of the rulebook pages. Fixed-roster labels work without them.")
}

function Import-BffTable {
    param([Parameter(Mandatory)][string]$Name, [string]$SkillRoot = (Get-BffSkillRoot))
    $path = if ($Name -in $script:BffBundledTables) { Join-Path $SkillRoot "references/tables/$Name" } else { Join-Path (Get-BffTablesPath) $Name }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Brigade table not found: $path. Run scripts/Test-BrigadeTables.ps1 to check the table folder." }
    @(Import-Csv -LiteralPath $path)
}

function New-BffRollProvider {
    param([int[]]$Values, [switch]$TestMode)
    if ($Values -and -not $TestMode) { throw 'Deterministic rolls require TestMode.' }
    $state = [pscustomobject]@{ Values = @($Values); Index = 0; TestMode = [bool]$TestMode }
    return {
        if ($state.TestMode) {
            if ($state.Index -ge $state.Values.Count) { throw "The test roll stream ended before roll $($state.Index + 1)." }
            $value = [int]$state.Values[$state.Index]
            $state.Index++
            if ($value -lt 1 -or $value -gt 10) { throw "Test roll $value is outside 1-10." }
            return $value
        }
        [System.Security.Cryptography.RandomNumberGenerator]::GetInt32(1, 11)
    }.GetNewClosure()
}

function Get-BffSecureIndex {
    param([Parameter(Mandatory)][int]$Maximum)
    if ($Maximum -lt 1) { throw 'A random selection pool is empty.' }
    [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($Maximum)
}

function Get-BffProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object -or -not $Object.PSObject.Properties[$Name]) { return $null }
    $Object.$Name
}

function Add-BffLog {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.ArrayList]$Log,
        [Parameter(Mandatory)][string]$RecordType,
        [Parameter(Mandatory)][string]$Step,
        [string]$Side = '', [string]$FormationId = '', [string]$UnitId = '',
        [object]$RawRoll = '', [string]$Modifiers = '', [object]$AdjustedRoll = '',
        [string]$Result = '', [string]$Substitution = '', [string]$SourceTable = '', [string]$Notes = ''
    )
    [void]$Log.Add([pscustomobject]@{
        Sequence = $Log.Count + 1
        RecordType = $RecordType
        Step = $Step
        Side = $Side
        FormationId = $FormationId
        UnitId = $UnitId
        RawRoll = $RawRoll
        Modifiers = $Modifiers
        AdjustedRoll = $AdjustedRoll
        Result = $Result
        Substitution = $Substitution
        SourceTable = $SourceTable
        Notes = $Notes
    })
}

function Test-BffPlayerSpec {
    param([int]$Count, [string]$Spec)
    if ($Spec -match '^(\d+)-(\d+)$') { return $Count -ge [int]$Matches[1] -and $Count -le [int]$Matches[2] }
    if ($Spec -match '^(\d+) or (\d+)$') { return $Count -in [int]$Matches[1], [int]$Matches[2] }
    $Count -eq [int]$Spec
}

function Get-BffPeriodForYear {
    param([int]$Year)
    switch ($Year) {
        1861 { 'Early War' }
        1862 { $null }
        1863 { 'Mid War' }
        1864 { $null }
        1865 { 'Late War' }
        default { $null }
    }
}

function ConvertTo-BffPublicPeriod {
    param([Parameter(Mandatory)][string]$Period)
    if ($Period -eq 'Mid-War') { return 'Mid War' }
    $Period
}

function ConvertTo-BffTablePeriod {
    param([Parameter(Mandatory)][string]$Period)
    if ($Period -eq 'Mid War') { return 'Mid-War' }
    $Period
}

function Assert-BffRequest {
    param([Parameter(Mandatory)][object]$Request, [string]$SkillRoot = (Get-BffSkillRoot))
    foreach ($name in 'players','matchup','period','theater','includeCavalry') {
        if (-not $Request.PSObject.Properties[$name]) { throw "Request is missing '$name'." }
    }
    $total = [int]$Request.players.total
    $usa = [int]$Request.players.USA
    $csa = [int]$Request.players.CSA
    if ($total -lt 2 -or $total -gt 10 -or $usa -lt 1 -or $csa -lt 1 -or $usa + $csa -ne $total) {
        throw 'players must total 2-10, include both sides, and equal USA + CSA.'
    }
    $match = @(Import-BffTable '01_force_balance_matchups.csv' $SkillRoot | Where-Object matchup_id -eq ([string]$Request.matchup.id))
    if ($match.Count -ne 1) { throw 'matchup.id must be M1 through M8.' }
    if (-not (Test-BffPlayerSpec $usa $match[0].usa_players) -or -not (Test-BffPlayerSpec $csa $match[0].csa_players)) {
        throw "Player split USA=$usa, CSA=$csa is not valid for $($match[0].matchup_id)."
    }
    $variant = [string](Get-BffProperty $Request.matchup 'csaVariant')
    if ($match[0].matchup_id -in 'M1','M2') {
        if ($variant -notin 'twoCorps','oneCorps') { throw 'M1 and M2 require csaVariant twoCorps or oneCorps.' }
    } elseif ($variant) { throw 'csaVariant is valid only for M1 or M2.' }
    foreach ($item in @(@('period', @('Early War','Mid War','Late War')), @('theater', @('Eastern','Western')))) {
        $name = $item[0]; $allowed = $item[1]; $choice = $Request.$name
        if ($choice.mode -notin 'fixed','random') { throw "$name.mode must be fixed or random." }
        $value = [string](Get-BffProperty $choice 'value')
        if ($choice.mode -eq 'fixed' -and $value -notin $allowed) { throw "$name.value is required and invalid." }
        if ($choice.mode -eq 'random' -and $value) { throw "$name.value must be omitted in random mode." }
    }
    $yearValue = Get-BffProperty $Request 'year'
    if ($null -ne $yearValue) {
        $year = [int]$yearValue
        if ($year -lt 1861 -or $year -gt 1865) { throw 'year must be 1861 through 1865.' }
        if ($Request.period.mode -ne 'fixed') { throw 'year requires a fixed period.' }
        $known = Get-BffPeriodForYear $year
        if ($known -and $known -ne $Request.period.value) { throw 'year and period are incompatible.' }
        if ($year -eq 1862 -and $Request.period.value -notin 'Early War','Mid War') { throw '1862 is compatible only with Early War or Mid War.' }
        if ($year -eq 1864 -and $Request.period.value -notin 'Mid War','Late War') { throw '1864 is compatible only with Mid War or Late War.' }
    }
}

function Get-BffCommandStructure {
    param([string]$MatchupId, [string]$CsaVariant)
    $map = @{
        M1 = @{ USA = @(3,3); CSA = if ($CsaVariant -eq 'twoCorps') { @(2,2) } else { @(4) } }
        M2 = @{ USA = @(3,2); CSA = if ($CsaVariant -eq 'twoCorps') { @(2,2) } else { @(4) } }
        M3 = @{ USA = @(3,2); CSA = @(3) }
        M4 = @{ USA = @(2,2); CSA = @(3) }
        M5 = @{ USA = @(2,2); CSA = @(2) }
        M6 = @{ USA = @(3); CSA = @(2) }
        M7 = @{ USA = @(3); CSA = @(1) }
        M8 = @{ USA = @(2); CSA = @(1) }
    }
    $map[$MatchupId]
}

function Get-BffOrdinal {
    param([int]$Number)
    if (($Number % 100) -in 11,12,13) { return "${Number}th" }
    switch ($Number % 10) { 1 { "${Number}st" } 2 { "${Number}nd" } 3 { "${Number}rd" } default { "${Number}th" } }
}

function Get-BffSurname {
    param([string]$Name)
    $value = $Name.Trim() -replace '^(?i:(Maj\.?|Brig\.?|Lt\.?)\s+Gen\.?|Gen\.?)\s+', ''
    $parts = @($value -split '\s+' | Where-Object { $_ })
    if (-not $parts.Count) { throw 'A commander name is required.' }
    $particleIndex = -1
    for ($index = 0; $index -lt $parts.Count - 1; $index++) {
        if ($parts[$index].TrimEnd('.').ToLowerInvariant() -in 'von','van','de','del','da','di','la','le','du','st') {
            $particleIndex = $index
        }
    }
    if ($particleIndex -ge 0) { return ($parts[$particleIndex..($parts.Count - 1)] -join ' ') }
    $parts[-1]
}

function Get-BffFixedExperience {
    param([string]$Value)
    $map = @{ Crk = 'Crack'; Vet = 'Veteran'; Exp = 'Experienced'; Grn = 'Green' }
    if (-not $map.ContainsKey($Value)) { throw "Fixed roster experience '$Value' is invalid." }
    $map[$Value]
}

function Get-BffFixedWeapon {
    param([string]$Value, [switch]$Artillery)
    $map = @{
        RM = 'Rifle Musket'; MM = 'Mixed Muskets'; RC = 'Rifle & Carbine'; RP = 'Repeater'; BL = 'Breechloader'; SM = 'Smoothbore Musket'; SH = 'Shotgun & Hunting Rifle'
        FG = 'Fortress Gun'; SG = 'Siege Gun'; NG = 'Naval Gun'; HR = 'Heavy Rifle'; LR = 'Light Rifle'; RN = 'Rifle & Napoleon'; RS = 'Rifle & Smoothbore'; NP = 'Napoleon'; SB = 'Smoothbore'
    }
    $allowed = if ($Artillery) { 'FG','SG','NG','HR','LR','RN','RS','NP','SB' } else { 'RM','MM','RC','RP','BL','SM','SH' }
    if ($Value -notin $allowed) { throw "Fixed roster weapon '$Value' is not valid for $(if ($Artillery) { 'artillery' } else { 'brigades' })." }
    $map[$Value]
}

function Get-BffFixedDivisionName {
    param([string]$Value)
    $map = @{ First = '1st'; Second = '2nd'; Third = '3rd'; Fourth = '4th'; Fifth = '5th' }
    $trimmed = $Value.Trim()
    if ($trimmed -match '^(First|Second|Third|Fourth|Fifth)\s+Division$') { return "$($map[$Matches[1]]) Division" }
    $trimmed
}

function Get-BffFixedEffectiveness {
    param([int]$Stands, [string]$Morale, [string]$SkillRoot)
    $row = @(Import-BffTable '07_brigade_effectiveness_table.csv' $SkillRoot | Where-Object { [int]$_.starting_stands -eq $Stands })
    if ($row.Count -ne 1 -or $Morale -notin 'Spirited','Reliable','Unreliable','Dispirited') { throw "No effectiveness value exists for $Stands $Morale." }
    $row[0].$Morale
}

function Get-BffFixedExceptionalLeader {
    param([object]$Entry)
    if (-not $Entry.PSObject.Properties['exceptionalLeader']) { return $false }
    if ($Entry.exceptionalLeader -isnot [bool]) { throw 'Fixed roster exceptionalLeader must be a boolean when supplied.' }
    $Entry.exceptionalLeader
}

function Get-BffUnassignedBrigades {
    param([object]$Request)
    $property = $Request.PSObject.Properties['unassignedBrigades']
    if ($property) { @($property.Value) }
}

function Assert-BffUnassignedBrigade {
    param([object]$Entry, [hashtable]$CorpsById, [string]$SkillRoot)
    if ($Entry.side -notin 'USA','CSA' -or -not $CorpsById.ContainsKey($Entry.corpsId) -or $CorpsById[$Entry.corpsId].side -ne $Entry.side) { throw 'Unassigned brigade requires a matching corpsId and side.' }
    if ([string]::IsNullOrWhiteSpace($Entry.name) -or $Entry.type -notin 'Infantry','Cavalry' -or $Entry.stands -ne [int]$Entry.stands -or [int]$Entry.stands -lt 2 -or [int]$Entry.stands -gt 25) { throw 'Unassigned brigade requires name, valid type and 2-25 whole stands.' }
    [void](Get-BffFixedExperience $Entry.experience); [void](Get-BffFixedWeapon $Entry.weapon)
    [void](Get-BffFixedExceptionalLeader $Entry)
    if ($Entry.effectiveness -ne (Get-BffFixedEffectiveness ([int]$Entry.stands) $Entry.morale $SkillRoot)) { throw 'Unassigned brigade effectiveness does not match its strength and morale.' }
}

function Assert-BffFixedRoster {
    param([Parameter(Mandatory)][object]$Request, [string]$SkillRoot = (Get-BffSkillRoot))
    if ($Request.mode -ne 'fixedRoster') { throw 'Fixed roster requests must set mode to fixedRoster.' }
    if ($Request.period -notin 'Early War','Mid War','Late War') { throw 'Fixed roster period is invalid.' }
    if ($Request.theater -notin 'Eastern','Western') { throw 'Fixed roster theater is invalid.' }
    $corps = @($Request.corps); $divisions = @($Request.divisions); $brigades = @($Request.brigades); $artillery = @($Request.artillery); $standalone = @($Request.standaloneArtillery)
    $unassigned = @(Get-BffUnassignedBrigades $Request)
    foreach ($entry in @($corps + $divisions + $brigades + $artillery + $standalone + $unassigned)) { if ($null -eq $entry) { throw 'Fixed roster arrays cannot contain null entries.' } }
    foreach ($entry in @($corps + $divisions + $brigades)) { [void](Get-BffFixedExceptionalLeader $entry) }
    $corpsById = @{}
    foreach ($entry in $corps) {
        if ([string]::IsNullOrWhiteSpace($entry.id) -or $entry.side -notin 'USA','CSA' -or [string]::IsNullOrWhiteSpace($entry.commander)) { throw 'Each fixed-roster corps requires id, USA or CSA side, and commander.' }
        if ($corpsById.ContainsKey($entry.id)) { throw "Fixed roster Corps id '$($entry.id)' is duplicated." }
        $corpsById[$entry.id] = $entry
    }
    $divisionById = @{}
    foreach ($entry in $divisions) {
        if ([string]::IsNullOrWhiteSpace($entry.id) -or -not $corpsById.ContainsKey($entry.corpsId) -or $entry.side -ne $corpsById[$entry.corpsId].side -or [string]::IsNullOrWhiteSpace($entry.commander)) { throw 'Each fixed-roster division requires a unique id, matching corpsId and side, and commander.' }
        if ($divisionById.ContainsKey($entry.id)) { throw "Fixed roster Division id '$($entry.id)' is duplicated." }
        $divisionById[$entry.id] = $entry
    }
    foreach ($entry in $brigades) {
        if (-not $divisionById.ContainsKey($entry.divisionId) -or $entry.type -notin 'Infantry','Cavalry' -or [int]$entry.stands -lt 2 -or [int]$entry.stands -gt 25 -or $entry.morale -notin 'Spirited','Reliable','Unreliable','Dispirited') { throw 'Each fixed-roster brigade requires a matching divisionId, valid type, 2-25 stands, and morale.' }
        [void](Get-BffFixedExperience $entry.experience); [void](Get-BffFixedWeapon $entry.weapon)
        $expected = Get-BffFixedEffectiveness ([int]$entry.stands) $entry.morale $SkillRoot
        if ($entry.effectiveness -ne $expected) { throw "Fixed roster brigade '$($entry.name)' has effectiveness '$($entry.effectiveness)'; expected '$expected'." }
    }
    foreach ($entry in $artillery) {
        if (-not $divisionById.ContainsKey($entry.divisionId)) { throw "Fixed roster artillery '$($entry.name)' does not match a division." }
        [void](Get-BffFixedExperience $entry.experience); [void](Get-BffFixedWeapon $entry.weapon -Artillery)
    }
    foreach ($entry in $standalone) {
        if ($entry.side -notin 'USA','CSA' -or -not $corpsById.ContainsKey($entry.corpsId) -or $corpsById[$entry.corpsId].side -ne $entry.side) { throw "Standalone artillery '$($entry.name)' requires a matching corpsId and side." }
        [void](Get-BffFixedExperience $entry.experience); [void](Get-BffFixedWeapon $entry.weapon -Artillery)
    }
    foreach ($entry in $unassigned) { Assert-BffUnassignedBrigade $entry $corpsById $SkillRoot }
    if (-not ($brigades.Count + $artillery.Count + $standalone.Count + $unassigned.Count)) { throw 'Fixed roster requires at least one unit.' }
}

function New-BffFixedRoster {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Request, [string]$SkillRoot = (Get-BffSkillRoot))
    Assert-BffFixedRoster $Request $SkillRoot
    $corps = [System.Collections.ArrayList]::new(); $divisions = [System.Collections.ArrayList]::new(); $brigades = [System.Collections.ArrayList]::new(); $artillery = [System.Collections.ArrayList]::new(); $standalone = [System.Collections.ArrayList]::new()
    $normalizedCorps = [System.Collections.ArrayList]::new(); $normalizedDivisions = [System.Collections.ArrayList]::new(); $normalizedBrigades = [System.Collections.ArrayList]::new(); $normalizedArtillery = [System.Collections.ArrayList]::new(); $normalizedStandalone = [System.Collections.ArrayList]::new()
    foreach ($entry in @($Request.corps)) {
        $commander = Get-BffSurname $entry.commander
        $exceptional = Get-BffFixedExceptionalLeader $entry
        [void]$corps.Add([ordered]@{ Side = $entry.side; 'Corps Name' = $entry.id; 'Corps Commander' = $commander; 'Exceptional Leader' = if ($exceptional) { 'Yes' } else { 'No' }; Theatre = $Request.theater; Period = $Request.period; 'User Notes' = '' })
        [void]$normalizedCorps.Add([ordered]@{ id = $entry.id; side = $entry.side; name = $entry.name; commander = $commander; exceptionalLeader = $exceptional })
    }
    foreach ($entry in @($Request.divisions)) {
        $commander = Get-BffSurname $entry.commander; $displayName = Get-BffFixedDivisionName $entry.name
        $exceptional = Get-BffFixedExceptionalLeader $entry
        [void]$divisions.Add([ordered]@{ 'Corps Name' = $entry.corpsId; 'Division Name' = $entry.id; Commander = $commander; 'Exceptional Leader' = if ($exceptional) { 'Yes' } else { 'No' }; Side = $entry.side; Notes = '' })
        [void]$normalizedDivisions.Add([ordered]@{ id = $entry.id; corpsId = $entry.corpsId; side = $entry.side; name = $displayName; commander = $commander; exceptionalLeader = $exceptional })
    }
    foreach ($entry in @($Request.brigades)) {
        $experience = Get-BffFixedExperience $entry.experience; $weapon = Get-BffFixedWeapon $entry.weapon; $name = Get-BffSurname $entry.name
        $exceptional = Get-BffFixedExceptionalLeader $entry
        [void]$brigades.Add([ordered]@{ 'Division Name' = $entry.divisionId; 'Brigade Name' = $name; Type = $entry.type; Stands = [int]$entry.stands; Experience = $experience; Morale = $entry.morale; Weapon = $weapon; 'Exceptional Leader' = if ($exceptional) { 'Yes' } else { 'No' }; Notes = '' })
        [void]$normalizedBrigades.Add([ordered]@{ divisionId = $entry.divisionId; name = $name; type = $entry.type; stands = [int]$entry.stands; experience = $entry.experience; morale = $entry.morale; effectiveness = $entry.effectiveness; weapon = $entry.weapon; exceptionalLeader = $exceptional })
    }
    foreach ($entry in @($Request.artillery)) {
        $experience = Get-BffFixedExperience $entry.experience; $weapon = Get-BffFixedWeapon $entry.weapon -Artillery
        [void]$artillery.Add([ordered]@{ 'Division Name' = $entry.divisionId; 'Battery Name' = $entry.name.Trim(); Experience = $experience; Weapon = $weapon; Notes = '' })
        [void]$normalizedArtillery.Add([ordered]@{ divisionId = $entry.divisionId; name = $entry.name.Trim(); experience = $entry.experience; weapon = $entry.weapon })
    }
    foreach ($entry in @($Request.standaloneArtillery)) {
        $experience = Get-BffFixedExperience $entry.experience; $weapon = Get-BffFixedWeapon $entry.weapon -Artillery
        [void]$standalone.Add([ordered]@{ side = $entry.side; corpsId = $entry.corpsId; name = $entry.name.Trim(); experience = $experience; weapon = $weapon })
        [void]$normalizedStandalone.Add([ordered]@{ side = $entry.side; corpsId = $entry.corpsId; name = $entry.name.Trim(); experience = $entry.experience; weapon = $entry.weapon })
    }
    $result = [pscustomobject]@{
        Period = $Request.period; Theater = $Request.theater
        RenderData = [ordered]@{ corps = @($corps); divisions = @($divisions); brigades = @($brigades); artillery = @($artillery); standaloneArtillery = @($standalone) }
        NormalizedRoster = [ordered]@{ mode = 'fixedRoster'; period = $Request.period; theater = $Request.theater; corps = @($normalizedCorps); divisions = @($normalizedDivisions); brigades = @($normalizedBrigades); artillery = @($normalizedArtillery); standaloneArtillery = @($normalizedStandalone) }
    }
    if ($Request.PSObject.Properties['unassignedBrigades']) {
        $renderUnassigned = @(); $normalizedUnassigned = @()
        foreach ($entry in @(Get-BffUnassignedBrigades $Request)) {
            $name = Get-BffSurname $entry.name; $exceptional = Get-BffFixedExceptionalLeader $entry
            $normalizedUnassigned += [ordered]@{side=$entry.side;corpsId=$entry.corpsId;name=$name;type=$entry.type;stands=[int]$entry.stands;experience=$entry.experience;morale=$entry.morale;effectiveness=$entry.effectiveness;weapon=$entry.weapon;exceptionalLeader=$exceptional}
            $renderUnassigned += [ordered]@{side=$entry.side;corpsId=$entry.corpsId;name=$name;type=$entry.type;stands=[int]$entry.stands;experience=(Get-BffFixedExperience $entry.experience);morale=$entry.morale;effectiveness=$entry.effectiveness;weapon=(Get-BffFixedWeapon $entry.weapon);exceptionalLeader=$exceptional}
        }
        $result.RenderData['unassignedBrigades'] = @($renderUnassigned)
        $result.NormalizedRoster['unassignedBrigades'] = @($normalizedUnassigned)
    }
    $result
}

function Get-BffPossessive {
    param([string]$Name)
    $surname = Get-BffSurname $Name
    if ($surname.EndsWith('s')) { return "$surname'" }
    "$surname's"
}

function Get-BffUniquePossessiveName {
    param([string]$FullName,[string]$Suffix,[hashtable]$Used)
    $base = "$(Get-BffPossessive $FullName) $Suffix"
    $key = $base.ToLowerInvariant()
    if (-not $Used.ContainsKey($key)) { $Used[$key]=$true; return [pscustomobject]@{Name=$base;Collision=$false} }
    $possessive = if ($FullName.EndsWith('s')) { "$FullName'" } else { "$FullName's" }
    $candidate = "$possessive $Suffix"; $number=2
    while ($Used.ContainsKey($candidate.ToLowerInvariant())) { $candidate="$possessive $Suffix $number";$number++ }
    $Used[$candidate.ToLowerInvariant()]=$true
    [pscustomobject]@{Name=$candidate;Collision=$true}
}

function Select-BffCommander {
    param(
        [object[]]$Rows, [string]$Side, [string]$Level, [string]$Period,
        [string]$Theater, [hashtable]$Used,
        [System.Collections.ArrayList]$Log, [string]$FormationId
    )
    # Period is the historical-name selection key.  A user-supplied year remains
    # scenario context because this source set contains dated battle snapshots,
    # not a complete day-by-day command chronology.
    $eligible = @($Rows | Where-Object {
        $_.Side -eq $Side -and $_.CommandLevel -eq $Level -and
        $_.EligiblePeriod -eq $Period -and
        -not $Used.ContainsKey($_.FullName.ToLowerInvariant())
    })
    $exact = @($eligible | Where-Object { $_.Theatre -eq $Theater })
    $pool = if ($exact.Count) { $exact } else { $eligible }
    if (-not $pool.Count) { throw "Historical commander pool exhausted for $Side $Level, $Period, $Theater." }
    $row = $pool[(Get-BffSecureIndex $pool.Count)]
    $Used[$row.FullName.ToLowerInvariant()] = $true
    $fallbackParts=[System.Collections.Generic.List[string]]::new()
    if(-not $exact.Count){[void]$fallbackParts.Add('Cross-theater historical fallback')}
    $fallback=$fallbackParts -join '; '
    $sourceNote="$($row.SourceTitle); $($row.SourceUrl)"
    if($row.ApproximationNote){$sourceNote += "; $($row.ApproximationNote)"}
    Add-BffLog $Log 'NameSelection' '4' $Side $FormationId '' '' '' '' $row.FullName $fallback 'commander-command-history.csv' $sourceNote
    $row
}

function Find-BffRowByRoll {
    param([object[]]$Rows, [scriptblock]$Filter, [int]$Roll)
    $result = @($Rows | Where-Object $Filter | Where-Object { [int]$_.d10_roll -eq $Roll })
    if ($result.Count -ne 1) { throw "Expected one table result for roll $Roll, found $($result.Count)." }
    $result[0]
}

function New-BffCorpsObject {
    param([string]$Id, [string]$Side, [bool]$DisplayOnly)
    [pscustomobject]@{ Id=$Id; Side=$Side; Name=''; Commander=''; Exceptional=$false; DisplayOnly=$DisplayOnly; Divisions=[System.Collections.ArrayList]::new() }
}

function New-BffDivisionObject {
    param([string]$Id, [string]$Side, [string]$CorpsId, [string]$Type, [bool]$DisplayOnly)
    [pscustomobject]@{ Id=$Id; Side=$Side; CorpsId=$CorpsId; Type=$Type; Name=''; Commander=''; Exceptional=$false; DisplayOnly=$DisplayOnly; Brigades=[System.Collections.ArrayList]::new(); Batteries=[System.Collections.ArrayList]::new() }
}

function New-BffBrigadeObject {
    param([string]$Id, [string]$Side, [string]$CorpsId, [string]$DivisionId, [string]$Type)
    [pscustomobject]@{ Id=$Id; Side=$Side; CorpsId=$CorpsId; DivisionId=$DivisionId; Type=$Type; Name=''; Commander=''; Exceptional=$false; Stands=0; Experience=''; Morale=''; Effectiveness=''; WeaponCode=''; Weapon='' }
}

function New-BffBatteryObject {
    param([string]$Id, [string]$Side, [string]$CorpsId, [string]$DivisionId, [bool]$Horse)
    [pscustomobject]@{ Id=$Id; Side=$Side; CorpsId=$CorpsId; DivisionId=$DivisionId; Type='Artillery'; Name=''; Experience=''; WeaponCode=''; Weapon=''; Horse=$Horse }
}

function Get-BffBalanceSummary {
    param([object[]]$Corps, [string]$Side)
    $sideCorps=@($Corps|Where-Object Side -eq $Side);$divisions=@($sideCorps|ForEach-Object{$_.Divisions});$brigades=@($divisions|ForEach-Object{$_.Brigades});$batteries=@($divisions|ForEach-Object{$_.Batteries})
    $infantry=@($brigades|Where-Object Type -eq 'Infantry');$cavalry=@($brigades|Where-Object Type -eq 'Cavalry')
    $infantryStands=if($infantry.Count){($infantry|Measure-Object -Property Stands -Sum).Sum}else{0}
    $cavalryStands=if($cavalry.Count){($cavalry|Measure-Object -Property Stands -Sum).Sum}else{0}
    "realCorps=$(@($sideCorps|Where-Object{-not $_.DisplayOnly}).Count); displayCorps=$(@($sideCorps|Where-Object DisplayOnly).Count); realDivisions=$(@($divisions|Where-Object{-not $_.DisplayOnly}).Count); displayDivisions=$(@($divisions|Where-Object DisplayOnly).Count); infantryBrigades=$($infantry.Count); infantryStands=$infantryStands; cavalryBrigades=$($cavalry.Count); cavalryStands=$cavalryStands; batteries=$($batteries.Count); exceptionalLeaders=$(@($sideCorps|Where-Object Exceptional).Count + @($divisions|Where-Object Exceptional).Count + @($brigades|Where-Object Exceptional).Count); experience=$((@($brigades)+@($batteries)|Group-Object Experience|ForEach-Object{"$($_.Name):$($_.Count)"}) -join '|'); morale=$(($brigades|Group-Object Morale|ForEach-Object{"$($_.Name):$($_.Count)"}) -join '|'); weapons=$((@($brigades)+@($batteries)|Group-Object WeaponCode|ForEach-Object{"$($_.Name):$($_.Count)"}) -join '|')"
}

function Publish-BffArtifacts {
    param(
        [Parameter(Mandatory)][string]$PdfSource,
        [Parameter(Mandatory)][string]$PdfTarget,
        [Parameter(Mandatory)][string]$CsvSource,
        [Parameter(Mandatory)][string]$CsvTarget,
        [scriptblock]$BeforeCsvMove
    )
    foreach($target in $PdfTarget,$CsvTarget){if(Test-Path -LiteralPath $target){throw "Refusing to overwrite existing output: $target"}}
    [System.IO.File]::Move($PdfSource,$PdfTarget,$false)
    try {
        if($BeforeCsvMove){& $BeforeCsvMove}
        [System.IO.File]::Move($CsvSource,$CsvTarget,$false)
    } catch {
        if(Test-Path -LiteralPath $PdfTarget){Remove-Item -LiteralPath $PdfTarget -Force}
        throw
    }
}

function New-BffArmy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Request,
        [string]$SkillRoot = (Get-BffSkillRoot),
        [switch]$TestMode,
        [int[]]$TestRollSequence
    )
    Assert-BffRequest $Request $SkillRoot
    $roll = New-BffRollProvider $TestRollSequence -TestMode:$TestMode
    $log = [System.Collections.ArrayList]::new()
    $periodRows = Import-BffTable '02_time_period_rolls.csv' $SkillRoot
    $theaterRows = Import-BffTable '02_theater_rolls.csv' $SkillRoot
    $brigadeCountRows = Import-BffTable '03_brigades_per_division.csv' $SkillRoot
    $batteryCountRows = Import-BffTable '03_batteries_per_division.csv' $SkillRoot
    $exceptionalRows = Import-BffTable '04_exceptional_leader_rolls.csv' $SkillRoot
    $strengthRows = Import-BffTable '05_brigade_strength.csv' $SkillRoot
    $experienceRows = Import-BffTable '06_experience_rating.csv' $SkillRoot
    $moraleRows = Import-BffTable '07_morale_rating_ranges.csv' $SkillRoot
    $effectivenessRows = Import-BffTable '07_brigade_effectiveness_table.csv' $SkillRoot
    $weaponRows = Import-BffTable '08_weapon_type.csv' $SkillRoot
    $commanderRows = @(Import-Csv -LiteralPath (Join-Path $SkillRoot 'references/commander-command-history.csv'))

    if ($Request.period.mode -eq 'random') {
        $r = & $roll; $period = ConvertTo-BffPublicPeriod (Find-BffRowByRoll $periodRows { $true } $r).period
        Add-BffLog $log 'Roll' '2' '' '' '' $r '' $r $period '' '02_time_period_rolls.csv'
    } else {
        $period = [string]$Request.period.value
        Add-BffLog $log 'Configuration' '2' '' '' '' '' 'User selection' '' $period '' 'request.json'
    }
    if ($Request.theater.mode -eq 'random') {
        $r = & $roll; $theaterSource = (Find-BffRowByRoll $theaterRows { $true } $r).theater
        $theater = $theaterSource -replace ' Theater$',''
        Add-BffLog $log 'Roll' '2' '' '' '' $r '' $r $theater '' '02_theater_rolls.csv'
    } else {
        $theater = [string]$Request.theater.value
        Add-BffLog $log 'Configuration' '2' '' '' '' '' 'User selection' '' $theater '' 'request.json'
    }
    $sourcePeriod = ConvertTo-BffTablePeriod $period
    $sourceTheater = "$theater Theater"
    $yearRaw = Get-BffProperty $Request 'year'
    $year = if ($null -ne $yearRaw) { [int]$yearRaw } else { $null }
    $variant = [string](Get-BffProperty $Request.matchup 'csaVariant')
    $yearValue = if ($null -eq $year) { 'none' } else { $year }
    Add-BffLog $log 'Configuration' '1' '' '' '' '' '' '' "Players=$($Request.players.total); USA=$($Request.players.USA); CSA=$($Request.players.CSA); Matchup=$($Request.matchup.id); csaVariant=$variant; includeCavalry=$([bool]$Request.includeCavalry); year=$yearValue" '' 'request.json'
    Add-BffLog $log 'HouseRule' '7' '' '' '' '' '' '' 'Clamp below-table morale to lowest printed band' 'Approved house rule' 'balance-policy.md'
    Add-BffLog $log 'HouseRule' '8' '' '' '' '' '' '' 'Repeater cap: one infantry RP and one cavalry RP per corps' 'Approved house rule' '08_weapon_constraints.csv'
    Add-BffLog $log 'HouseRule' '8' '' '' '' '' '' '' 'Heavy Rifle cap: floor(total side battery stands / 10)' 'Approved house rule' '08_weapon_constraints.csv'

    $structure = Get-BffCommandStructure ([string]$Request.matchup.id) ([string](Get-BffProperty $Request.matchup 'csaVariant'))
    $corps = [System.Collections.ArrayList]::new()
    $divisionSerial = @{ USA=0; CSA=0 }
    foreach ($side in 'USA','CSA') {
        $corpsIndex = 0
        foreach ($divisionCount in @($structure[$side])) {
            $corpsIndex++
            $corpsId = "$side-C$corpsIndex"
            $standaloneDivision = $side -eq 'CSA' -and $Request.matchup.id -in 'M7','M8'
            $corpsObject = New-BffCorpsObject $corpsId $side $standaloneDivision
            if($standaloneDivision){
                $corpsObject.Name='CSA Independent Division';$corpsObject.Commander='Independent Division'
                Add-BffLog $log 'Structure' '1' $side $corpsId '' '' '' '' 'Display-only parent for source command structure: 1 division' '' '01_force_balance_matchups.csv' 'No corps commander and no corps leader roll.'
            }
            [void]$corps.Add($corpsObject)
            for ($d = 1; $d -le [int]$divisionCount; $d++) {
                $divisionSerial[$side]++
                $divisionId = "$side-D$($divisionSerial[$side])"
                $division = New-BffDivisionObject $divisionId $side $corpsId 'Infantry' $false
                $brigadeRoll = & $roll
                $brigadeRow = Find-BffRowByRoll $brigadeCountRows { $_.side -eq $side } $brigadeRoll
                $brigadeCount = [int]$brigadeRow.brigades_in_division
                Add-BffLog $log 'Roll' '3A' $side $divisionId '' $brigadeRoll '' $brigadeRoll "$brigadeCount brigades" '' '03_brigades_per_division.csv'
                $batteryRoll = & $roll
                $batteryRow = Find-BffRowByRoll $batteryCountRows { [int]$_.brigades_in_division -eq $brigadeCount } $batteryRoll
                $batteryCount = [int]$batteryRow.batteries_in_division
                Add-BffLog $log 'Roll' '3B' $side $divisionId '' $batteryRoll "brigades=$brigadeCount" $batteryRoll "$batteryCount batteries" '' '03_batteries_per_division.csv'
                for ($b=1; $b -le $brigadeCount; $b++) {
                    [void]$division.Brigades.Add((New-BffBrigadeObject "$divisionId-B$b" $side $corpsId $divisionId 'Infantry'))
                }
                for ($a=1; $a -le $batteryCount; $a++) {
                    [void]$division.Batteries.Add((New-BffBatteryObject "$divisionId-A$a" $side $corpsId $divisionId $false))
                }
                [void]$corpsObject.Divisions.Add($division)
            }
        }
    }

    if ([bool]$Request.includeCavalry) {
        if ($period -eq 'Early War') {
            foreach ($c in @($corps | Where-Object { -not $_.DisplayOnly })) {
                $divisionId = "$($c.Id)-CAV"
                $division = New-BffDivisionObject $divisionId $c.Side $c.Id 'Cavalry' $true
                $division.Commander = 'Corps Cavalry'
                [void]$division.Brigades.Add((New-BffBrigadeObject "$divisionId-B1" $c.Side $c.Id $divisionId 'Cavalry'))
                [void]$c.Divisions.Add($division)
                Add-BffLog $log 'Structure' '1' $c.Side $divisionId '' '' '' '' 'Display-only Corps Cavalry division; one cavalry brigade' '' 'Rulebook generator steps' 'No division commander and no division leader roll.'
            }
        } else {
            foreach ($side in 'USA','CSA') {
                $corpsId = "$side-CAV"
                $c = New-BffCorpsObject $corpsId $side $true
                $c.Name = "$side Independent Cavalry"
                $c.Commander = 'Independent Cavalry'
                $divisionSerial[$side]++
                $divisionId = "$side-D$($divisionSerial[$side])-CAV"
                $division = New-BffDivisionObject $divisionId $side $corpsId 'Cavalry' $false
                for ($b=1; $b -le 2; $b++) {
                    [void]$division.Brigades.Add((New-BffBrigadeObject "$divisionId-B$b" $side $corpsId $divisionId 'Cavalry'))
                }
                $horseBattery = New-BffBatteryObject "$divisionId-A1" $side $corpsId $divisionId $true
                $horseBattery.Name = 'Horse Battery'
                [void]$division.Batteries.Add($horseBattery)
                [void]$c.Divisions.Add($division); [void]$corps.Add($c)
                Add-BffLog $log 'Structure' '1' $side $corpsId '' '' '' '' 'Display-only Independent Cavalry corps; real two-brigade cavalry division and one horse battery' '' 'Rulebook generator steps' 'No corps commander and no corps leader roll.'
            }
        }
    }

    $usedNames = @{ USA=@{}; CSA=@{} }
    $usedFormationNames = @{}
    foreach ($side in 'USA','CSA') {
        $sideCorps = @($corps | Where-Object Side -eq $side)
        $realCorpsIndex = 0; $sideDivisionIndex = 0
        foreach ($c in $sideCorps) {
            if (-not $c.DisplayOnly) {
                $realCorpsIndex++
                $c.Name = "$side $(Get-BffOrdinal $realCorpsIndex) Corps"
                $person = Select-BffCommander $commanderRows $side 'Corps' $period $theater $usedNames[$side] $log $c.Id
                $c.Commander = $person.FullName
            }
            foreach ($d in $c.Divisions) {
                if (-not $d.DisplayOnly) {
                    $sideDivisionIndex++
                    $person = Select-BffCommander $commanderRows $side 'Division' $period $theater $usedNames[$side] $log $d.Id
                    $d.Commander = $person.FullName
                    if ($d.Type -eq 'Cavalry') { $d.Name = "$side $(Get-BffOrdinal $sideDivisionIndex) Cavalry Division" }
                    elseif ($side -eq 'USA') { $d.Name = "$side $(Get-BffOrdinal $sideDivisionIndex) Division" }
                    else {
                        $unique = Get-BffUniquePossessiveName $person.FullName 'Division' $usedFormationNames
                        $d.Name = $unique.Name
                        if($unique.Collision){Add-BffLog $log 'NamingRule' '4' $side $d.Id '' '' '' '' $d.Name 'Disambiguated Confederate possessive collision' 'commander-command-history.csv'}
                    }
                } elseif (-not $d.Name) {
                    $d.Name = "$($c.Name) Corps Cavalry"
                }
                $brigadeIndex = 0
                foreach ($b in $d.Brigades) {
                    $brigadeIndex++
                    $person = Select-BffCommander $commanderRows $side 'Brigade' $period $theater $usedNames[$side] $log $b.Id
                    $b.Commander = $person.FullName
                    if($side -eq 'USA'){$b.Name="$(Get-BffOrdinal $brigadeIndex) Brigade"}
                    else{
                        $unique=Get-BffUniquePossessiveName $person.FullName 'Brigade' $usedFormationNames
                        $b.Name=$unique.Name
                        if($unique.Collision){Add-BffLog $log 'NamingRule' '4' $side $d.Id $b.Id '' '' '' $b.Name 'Disambiguated Confederate possessive collision' 'commander-command-history.csv'}
                    }
                }
                $batteryIndex = 0
                foreach ($a in $d.Batteries) {
                    $batteryIndex++
                    if (-not $a.Name) { $a.Name = "Battery $batteryIndex" }
                }
            }
        }
    }

    foreach ($c in $corps) {
        if (-not $c.DisplayOnly) {
            $r=&$roll; $row=Find-BffRowByRoll $exceptionalRows { $_.period -eq $sourcePeriod -and $_.side -eq $c.Side } $r
            $c.Exceptional=[System.Convert]::ToBoolean($row.exceptional_leader)
            Add-BffLog $log 'Roll' '4' $c.Side $c.Id '' $r '' $r "Exceptional=$($c.Exceptional)" '' '04_exceptional_leader_rolls.csv'
        }
        foreach ($d in $c.Divisions) {
            if (-not $d.DisplayOnly) {
                $r=&$roll; $row=Find-BffRowByRoll $exceptionalRows { $_.period -eq $sourcePeriod -and $_.side -eq $d.Side } $r
                $d.Exceptional=[System.Convert]::ToBoolean($row.exceptional_leader)
                Add-BffLog $log 'Roll' '4' $d.Side $d.Id '' $r '' $r "Exceptional=$($d.Exceptional)" '' '04_exceptional_leader_rolls.csv'
            }
            foreach ($b in $d.Brigades) {
                $r=&$roll; $row=Find-BffRowByRoll $exceptionalRows { $_.period -eq $sourcePeriod -and $_.side -eq $b.Side } $r
                $b.Exceptional=[System.Convert]::ToBoolean($row.exceptional_leader)
                Add-BffLog $log 'Roll' '4' $b.Side $d.Id $b.Id $r '' $r "Exceptional=$($b.Exceptional)" '' '04_exceptional_leader_rolls.csv'
            }
        }
    }

    $allDivisions = @($corps | ForEach-Object { $_.Divisions })
    $allBrigades = @($allDivisions | ForEach-Object { $_.Brigades })
    $allBatteries = @($allDivisions | ForEach-Object { $_.Batteries })
    foreach ($b in $allBrigades) {
        $r=&$roll; $row=Find-BffRowByRoll $strengthRows { $_.unit_type -eq $b.Type -and $_.period -eq $sourcePeriod -and $_.side -eq $b.Side } $r
        $b.Stands=[int]$row.stands_in_brigade
        Add-BffLog $log 'Roll' '5' $b.Side $b.DivisionId $b.Id $r '' $r "$($b.Stands) stands" '' '05_brigade_strength.csv'
    }
    foreach ($unit in @($allBrigades) + @($allBatteries)) {
        $r=&$roll; $modifier=if($unit.Type -eq 'Infantry' -and $unit.Stands -ge 12){-2}else{0}; $adjusted=$r+$modifier
        $row=@($experienceRows|Where-Object{$_.unit_type -eq $unit.Type -and $_.period -eq $sourcePeriod -and $_.side -eq $unit.Side -and [int]$_.modified_roll -eq $adjusted})
        if($row.Count -ne 1){throw "Experience lookup failed for $($unit.Id), adjusted roll $adjusted."}
        $unit.Experience=$row[0].experience_rating
        Add-BffLog $log 'Roll' '6' $unit.Side $unit.DivisionId $unit.Id $r $(if($modifier){'Large infantry brigade -2'}else{'None'}) $adjusted $unit.Experience '' '06_experience_rating.csv'
    }
    $experienceModifier=@{Crack=2;Veteran=1;Experienced=0;Green=-1}
    foreach($b in $allBrigades){
        $r=&$roll; $parts=[System.Collections.Generic.List[string]]::new(); $modifier=[int]$experienceModifier[$b.Experience]; [void]$parts.Add("$($b.Experience) $modifier")
        if($b.Side -eq 'CSA' -and $theater -eq 'Eastern'){$modifier++;[void]$parts.Add('Eastern CSA +1')}
        if($b.Side -eq 'USA' -and $theater -eq 'Western' -and $period -eq 'Late War'){$modifier++;[void]$parts.Add('Late Western USA +1')}
        if($b.Side -eq 'USA' -and $b.Type -eq 'Cavalry' -and $period -eq 'Early War'){$modifier--;[void]$parts.Add('Early USA cavalry -1')}
        $adjusted=$r+$modifier
        $available=@($moraleRows|Where-Object{$_.period -eq $sourcePeriod -and $_.side -eq $b.Side -and $_.available -eq 'true'})
        $row=@($available|Where-Object{[int]$_.modified_roll_min -le $adjusted -and (($_.open_ended_above -eq 'true') -or $adjusted -le [int]$_.modified_roll_max)})
        $sub=''
        if(-not $row.Count){$lowest=$available|Sort-Object {[int]$_.modified_roll_min}|Select-Object -First 1;$row=@($lowest);$sub="Clamped $adjusted to lowest printed band $($lowest.modified_roll_min)"}
        if($row.Count -ne 1){throw "Morale lookup failed for $($b.Id), adjusted roll $adjusted."}
        $b.Morale=$row[0].morale_rating
        $effect=@($effectivenessRows|Where-Object{[int]$_.starting_stands -eq $b.Stands})
        if($effect.Count -ne 1){throw "Effectiveness lookup failed for $($b.Id)."}
        $b.Effectiveness=[string]$effect[0].$($b.Morale)
        Add-BffLog $log 'Roll' '7' $b.Side $b.DivisionId $b.Id $r ($parts -join '; ') $adjusted "$($b.Morale); $($b.Effectiveness)" $sub '07_morale_rating_ranges.csv; 07_brigade_effectiveness_table.csv'
    }
    $sideBatteryCounts=@{USA=@($allBatteries|Where-Object Side -eq 'USA').Count;CSA=@($allBatteries|Where-Object Side -eq 'CSA').Count}
    $hrUsed=@{USA=0;CSA=0}; $rpUsed=@{}
    foreach($unit in @($allBrigades)+@($allBatteries)){
        $r=&$roll; $row=Find-BffRowByRoll $weaponRows { $_.unit_type -eq $unit.Type -and $_.theater -eq $sourceTheater -and $_.period -eq $sourcePeriod -and $_.side -eq $unit.Side } $r
        $code=$row.weapon_code; $weapon=$row.weapon_type; $sub=''
        if($code -eq 'RP'){
            $key="$($unit.CorpsId)|$($unit.Type)"
            if($rpUsed[$key]){$replacement=if($unit.Type -eq 'Infantry'){'RM'}else{'BL'};$replacementRow=$weaponRows|Where-Object{$_.weapon_code -eq $replacement}|Select-Object -First 1;$code=$replacement;$weapon=$replacementRow.weapon_type;$sub="RP cap reached for $key; substituted $replacement"}else{$rpUsed[$key]=$true}
        }
        if($code -eq 'HR'){
            $limit=[math]::Floor($sideBatteryCounts[$unit.Side]/10)
            if($hrUsed[$unit.Side] -ge $limit){$replacementRow=$weaponRows|Where-Object{$_.weapon_code -eq 'LR'}|Select-Object -First 1;$code='LR';$weapon=$replacementRow.weapon_type;$sub="HR cap $limit reached for $($unit.Side); substituted LR"}else{$hrUsed[$unit.Side]++}
        }
        $unit.WeaponCode=$code;$unit.Weapon=$weapon
        Add-BffLog $log 'Roll' '8' $unit.Side $unit.DivisionId $unit.Id $r '' $r "$code - $weapon" $sub '08_weapon_type.csv; 08_weapon_constraints.csv'
    }

    foreach($side in 'USA','CSA'){
        Add-BffLog $log 'BalanceMetric' 'Review' $side '' '' '' '' '' (Get-BffBalanceSummary $corps $side) '' 'balance-policy.md'
    }
    Add-BffLog $log 'BalanceDecision' 'Review' '' '' '' '' '' '' 'No adjustment applied: balance rules not yet approved.' 'Deferred improvement' 'balance-policy.md'

    $renderCorps=[System.Collections.ArrayList]::new();$renderDivisions=[System.Collections.ArrayList]::new();$renderBrigades=[System.Collections.ArrayList]::new();$renderArtillery=[System.Collections.ArrayList]::new()
    foreach($c in $corps){
        [void]$renderCorps.Add([ordered]@{Side=$c.Side;'Corps Name'=$c.Name;'Corps Commander'=$c.Commander;'Exceptional Leader'=if($c.Exceptional){'Yes'}else{'No'};Theatre=$theater;Period=$period;'User Notes'=if($c.DisplayOnly){'Display-only container'}else{''}})
        foreach($d in $c.Divisions){
            [void]$renderDivisions.Add([ordered]@{'Corps Name'=$c.Name;'Division Name'=$d.Name;Commander=$d.Commander;'Exceptional Leader'=if($d.Exceptional){'Yes'}else{'No'};Side=$d.Side;Notes=if($d.DisplayOnly){'Display-only container'}else{''}})
            foreach($b in $d.Brigades){[void]$renderBrigades.Add([ordered]@{'Division Name'=$d.Name;'Brigade Name'=$b.Name;Type=$b.Type;Stands=$b.Stands;Experience=$b.Experience;Morale=$b.Morale;Weapon=$b.Weapon;'Exceptional Leader'=if($b.Exceptional){'Yes'}else{'No'};Notes=''})}
            foreach($a in $d.Batteries){[void]$renderArtillery.Add([ordered]@{'Division Name'=$d.Name;'Battery Name'=$a.Name;Experience=$a.Experience;Weapon=$a.Weapon;Notes=if($a.Horse){'Horse battery'}else{''}})}
        }
    }
    [pscustomobject]@{
        Period=$period; Theater=$theater; Year=$year; Corps=$corps; RollLog=$log
        RenderData=[ordered]@{corps=@($renderCorps);divisions=@($renderDivisions);brigades=@($renderBrigades);artillery=@($renderArtillery)}
    }
}

function Test-BffTables {
    param([string]$Path = (Get-BffTablesPath), [string]$SkillRoot = (Get-BffSkillRoot))
    $failures = [System.Collections.Generic.List[string]]::new()
    $periods = 'Early War','Mid-War','Late War'; $sides = 'USA','CSA'; $theaters = 'Eastern Theater','Western Theater'
    $d10 = 1..10
    $columns = [ordered]@{
        '01_force_balance_matchups.csv' = 'matchup_id','usa_players','usa_command','csa_players','csa_command'
        '02_time_period_rolls.csv' = 'd10_roll','period'
        '02_theater_rolls.csv' = 'd10_roll','theater'
        '03_brigades_per_division.csv' = 'side','d10_roll','brigades_in_division'
        '03_batteries_per_division.csv' = 'brigades_in_division','d10_roll','batteries_in_division'
        '04_exceptional_leader_rolls.csv' = 'period','side','d10_roll','exceptional_leader'
        '05_brigade_strength.csv' = 'unit_type','period','side','d10_roll','stands_in_brigade'
        '06_experience_rating.csv' = 'unit_type','period','side','modified_roll','experience_rating'
        '07_morale_rating_ranges.csv' = 'period','side','morale_rating','modified_roll_min','modified_roll_max','open_ended_above','available'
        '08_weapon_type.csv' = 'unit_type','theater','period','side','d10_roll','weapon_code','weapon_type','special_limit_applies'
    }
    $tables = @{}
    foreach ($name in $columns.Keys) {
        $file = Join-Path $Path $name
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { $failures.Add("${name}: file is missing from $Path"); continue }
        $rows = @(Import-Csv -LiteralPath $file)
        if (-not $rows.Count) { $failures.Add("${name}: no data rows"); continue }
        $missing = @($columns[$name] | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name })
        if ($missing.Count) { $failures.Add("${name}: missing column(s) $($missing -join ', ')"); continue }
        $tables[$name] = $rows
    }
    $isInt = { param($Value) [string]$Value -match '^-?\d+$' }
    $coverage = {
        param([string]$Table, [object[]]$Rows, [string]$Context, [string]$Column, [int[]]$Expected)
        foreach ($row in $Rows) { if (-not (& $isInt $row.$Column)) { $failures.Add("${Table} [$Context]: $Column '$($row.$Column)' is not a whole number") } }
        $found = @($Rows | Where-Object { & $isInt $_.$Column } | ForEach-Object { [int]$_.$Column })
        foreach ($roll in $Expected) {
            $count = @($found | Where-Object { $_ -eq $roll }).Count
            if ($count -eq 0) { $failures.Add("${Table} [$Context]: no row for $Column $roll") }
            elseif ($count -gt 1) { $failures.Add("${Table} [$Context]: $count rows for $Column $roll") }
        }
        foreach ($extra in @($found | Where-Object { $_ -notin $Expected } | Sort-Object -Unique)) { $failures.Add("${Table} [$Context]: unexpected $Column $extra") }
    }
    $allowed = {
        param([string]$Table, [object[]]$Rows, [string]$Column, [string[]]$Values)
        foreach ($bad in @($Rows | Where-Object { [string]$_.$Column -cnotin $Values } | ForEach-Object { [string]$_.$Column } | Sort-Object -Unique)) {
            $failures.Add("${Table}: $Column '$bad' is not one of $($Values -join ', ')")
        }
    }

    $name = '01_force_balance_matchups.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]
        foreach ($id in 1..8 | ForEach-Object { "M$_" }) {
            $count = @($rows | Where-Object matchup_id -eq $id).Count
            if ($count -ne 1) { $failures.Add("${name}: expected one row for $id, found $count") }
        }
        & $allowed $name $rows 'matchup_id' @(1..8 | ForEach-Object { "M$_" })
        foreach ($row in $rows) { foreach ($column in 'usa_players','csa_players') {
            if ([string]$row.$column -notmatch '^\d+(-\d+| or \d+)?$') { $failures.Add("${name} [$($row.matchup_id)]: $column '$($row.$column)' must look like 3, 2-4, or 2 or 3") }
        } }
    }
    $name = '02_time_period_rolls.csv'
    if ($tables[$name]) { & $coverage $name $tables[$name] 'all' 'd10_roll' $d10; & $allowed $name $tables[$name] 'period' $periods }
    $name = '02_theater_rolls.csv'
    if ($tables[$name]) { & $coverage $name $tables[$name] 'all' 'd10_roll' $d10; & $allowed $name $tables[$name] 'theater' $theaters }
    $brigadeCounts = @()
    $name = '03_brigades_per_division.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]; & $allowed $name $rows 'side' $sides
        foreach ($side in $sides) { & $coverage $name @($rows | Where-Object side -eq $side) $side 'd10_roll' $d10 }
        foreach ($row in $rows) { if (-not (& $isInt $row.brigades_in_division) -or [int]$row.brigades_in_division -lt 1) { $failures.Add("${name} [$($row.side) roll $($row.d10_roll)]: brigades_in_division '$($row.brigades_in_division)' must be a whole number of at least 1") } }
        $brigadeCounts = @($rows | Where-Object { & $isInt $_.brigades_in_division } | ForEach-Object { [int]$_.brigades_in_division } | Sort-Object -Unique)
    }
    $name = '03_batteries_per_division.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]
        foreach ($count in $brigadeCounts) { & $coverage $name @($rows | Where-Object brigades_in_division -eq ([string]$count)) "$count brigades" 'd10_roll' $d10 }
        foreach ($row in $rows) { if (-not (& $isInt $row.batteries_in_division) -or [int]$row.batteries_in_division -lt 0) { $failures.Add("${name} [$($row.brigades_in_division) brigades roll $($row.d10_roll)]: batteries_in_division '$($row.batteries_in_division)' must be a whole number") } }
    }
    $name = '04_exceptional_leader_rolls.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]; & $allowed $name $rows 'exceptional_leader' @('true','false')
        foreach ($period in $periods) { foreach ($side in $sides) { & $coverage $name @($rows | Where-Object { $_.period -eq $period -and $_.side -eq $side }) "$period $side" 'd10_roll' $d10 } }
    }
    $effectivenessRows = @(Import-Csv -LiteralPath (Join-Path $SkillRoot 'references/tables/07_brigade_effectiveness_table.csv'))
    $stands = @($effectivenessRows | ForEach-Object { [int]$_.starting_stands })
    $name = '05_brigade_strength.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]
        foreach ($type in 'Infantry','Cavalry') { foreach ($period in $periods) { foreach ($side in $sides) {
            & $coverage $name @($rows | Where-Object { $_.unit_type -eq $type -and $_.period -eq $period -and $_.side -eq $side }) "$type $period $side" 'd10_roll' $d10
        } } }
        foreach ($row in $rows) { if (-not (& $isInt $row.stands_in_brigade) -or [int]$row.stands_in_brigade -notin $stands) { $failures.Add("${name} [$($row.unit_type) $($row.period) $($row.side) roll $($row.d10_roll)]: stands_in_brigade '$($row.stands_in_brigade)' is outside the effectiveness table") } }
    }
    $name = '06_experience_rating.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]; & $allowed $name $rows 'experience_rating' @('Crack','Veteran','Experienced','Green')
        foreach ($type in 'Infantry','Cavalry','Artillery') { foreach ($period in $periods) { foreach ($side in $sides) {
            $expected = if ($type -eq 'Infantry') { -1..10 } else { $d10 }
            & $coverage $name @($rows | Where-Object { $_.unit_type -eq $type -and $_.period -eq $period -and $_.side -eq $side }) "$type $period $side" 'modified_roll' $expected
        } } }
    }
    $name = '07_morale_rating_ranges.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]
        & $allowed $name $rows 'morale_rating' @('Spirited','Reliable','Unreliable','Dispirited')
        & $allowed $name $rows 'available' @('true','false'); & $allowed $name $rows 'open_ended_above' @('true','false')
        foreach ($period in $periods) { foreach ($side in $sides) {
            $context = "$period $side"; $group = @($rows | Where-Object { $_.period -eq $period -and $_.side -eq $side })
            foreach ($rating in 'Spirited','Reliable','Unreliable','Dispirited') {
                $count = @($group | Where-Object morale_rating -eq $rating).Count
                if ($count -ne 1) { $failures.Add("${name} [$context]: expected one $rating row, found $count") }
            }
            $bands = @($group | Where-Object available -eq 'true' | Sort-Object { if (& $isInt $_.modified_roll_min) { [int]$_.modified_roll_min } else { 0 } })
            if (-not $bands.Count) { $failures.Add("${name} [$context]: no available morale bands"); continue }
            for ($i = 0; $i -lt $bands.Count; $i++) {
                $band = $bands[$i]; $last = $i -eq $bands.Count - 1
                if (-not (& $isInt $band.modified_roll_min)) { $failures.Add("${name} [$context $($band.morale_rating)]: modified_roll_min is not a whole number"); continue }
                if ($last) {
                    if ($band.open_ended_above -ne 'true') { $failures.Add("${name} [$context]: the highest band ($($band.morale_rating)) must be open-ended") }
                } else {
                    if ($band.open_ended_above -eq 'true') { $failures.Add("${name} [$context $($band.morale_rating)]: only the highest band can be open-ended") }
                    if (-not (& $isInt $band.modified_roll_max)) { $failures.Add("${name} [$context $($band.morale_rating)]: modified_roll_max is not a whole number"); continue }
                    $next = $bands[$i + 1]
                    if ((& $isInt $next.modified_roll_min) -and [int]$next.modified_roll_min -ne [int]$band.modified_roll_max + 1) {
                        $failures.Add("${name} [$context]: $($band.morale_rating) ends at $($band.modified_roll_max) but $($next.morale_rating) starts at $($next.modified_roll_min)")
                    }
                }
            }
        } }
    }
    $name = '08_weapon_type.csv'
    if ($tables[$name]) {
        $rows = $tables[$name]
        $codes = @{ Infantry = 'SM','MM','RM','RP'; Cavalry = 'SH','RC','BL','RP'; Artillery = 'SB','NP','RS','RN','LR','HR' }
        foreach ($type in 'Infantry','Cavalry','Artillery') {
            $typeRows = @($rows | Where-Object unit_type -eq $type)
            & $allowed "$name [$type]" $typeRows 'weapon_code' $codes[$type]
            foreach ($theater in $theaters) { foreach ($period in $periods) { foreach ($side in $sides) {
                & $coverage $name @($typeRows | Where-Object { $_.theater -eq $theater -and $_.period -eq $period -and $_.side -eq $side }) "$type $theater $period $side" 'd10_roll' $d10
            } } }
        }
        # The renderer prints the abbreviation it maps from weapon_type, so each name must match its code.
        $code = Get-Content -LiteralPath (Join-Path $SkillRoot 'assets/Code.gs') -Raw
        $block = [regex]::Match($code, '(?s)\bweapon:\s*\{(?<body>.*?)\}').Groups['body'].Value
        $rendererCodes = @{}
        foreach ($match in [regex]::Matches($block, '(?m)^\s*"?(?<name>[^":]+?)"?\s*:\s*"(?<code>[A-Z]+)"')) { $rendererCodes[$match.Groups['name'].Value] = $match.Groups['code'].Value }
        foreach ($group in @($rows | Group-Object weapon_code, weapon_type)) {
            $sample = $group.Group[0]
            if ($rendererCodes[[string]$sample.weapon_type] -cne [string]$sample.weapon_code) {
                $failures.Add("${name}: weapon_type '$($sample.weapon_type)' does not match weapon_code $($sample.weapon_code); the labels would print $(if ($rendererCodes[[string]$sample.weapon_type]) { $rendererCodes[[string]$sample.weapon_type] } else { 'nothing' })")
            }
        }
        foreach ($code in 'RM','BL','LR') { if (-not @($rows | Where-Object weapon_code -eq $code).Count) { $failures.Add("${name}: weapon_code $code must appear at least once because cap substitutions use it") } }
    }
    @($failures)
}

function Find-BffBrowser {
    $tried = [System.Collections.Generic.List[string]]::new()
    if ($env:CHROME_PATH) {
        if (Test-Path -LiteralPath $env:CHROME_PATH -PathType Leaf) { return $env:CHROME_PATH }
        $tried.Add("CHROME_PATH=$env:CHROME_PATH")
    }
    $names = 'chrome','google-chrome','google-chrome-stable','chromium','chromium-browser','msedge','microsoft-edge'
    foreach ($name in $names) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { return $command.Source }
    }
    $tried.Add("PATH: $($names -join ', ')")
    $paths = if ($IsWindows) {
        @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
          "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
          "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
    } elseif ($IsMacOS) {
        @('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/Applications/Chromium.app/Contents/MacOS/Chromium',
          '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge')
    } else {
        @('/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser', '/snap/bin/chromium', '/usr/bin/microsoft-edge')
    }
    foreach ($path in $paths) { if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) { return $path } }
    $tried.AddRange([string[]]$paths)
    throw "Chrome, Chromium, or Microsoft Edge is required to render the PDF. Install one, or set CHROME_PATH to its executable. Tried: $($tried -join '; ')"
}

Export-ModuleMember -Function Set-BffTablesPath,Get-BffTablesPath,Test-BffTables,Find-BffBrowser,Import-BffTable,New-BffRollProvider,Assert-BffRequest,Assert-BffFixedRoster,Get-BffCommandStructure,Add-BffLog,New-BffArmy,New-BffFixedRoster,Publish-BffArtifacts
