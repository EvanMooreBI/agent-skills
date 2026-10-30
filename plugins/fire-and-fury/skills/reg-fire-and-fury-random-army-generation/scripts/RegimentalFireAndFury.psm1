Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RffRules {
    param([string]$SkillRoot = (Split-Path $PSScriptRoot -Parent))
    Get-Content (Join-Path $SkillRoot 'references/army-generation-rules.json') -Raw | ConvertFrom-Json
}

function Get-SecureIndex([int]$Maximum) {
    if ($Maximum -le 0) { throw 'Random selection requires a non-empty pool.' }
    [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($Maximum)
}

function New-RollProvider {
    param([int[]]$TestRollSequence, [switch]$TestMode)
    if ($TestRollSequence -and -not $TestMode) { throw 'TestRollSequence is available only with TestMode.' }
    $state = [pscustomobject]@{ Values = @($TestRollSequence); Index = 0; TestMode = [bool]$TestMode }
    return {
        if ($state.TestMode -and $state.Values.Count -gt 0) {
            if ($state.Index -ge $state.Values.Count) { throw "The deterministic test roll stream was exhausted at roll $($state.Index + 1)." }
            $value = [int]$state.Values[$state.Index]
            $state.Index++
            if ($value -lt 1 -or $value -gt 10) { throw "Test roll $value is outside 1-10." }
            return $value
        }
        [System.Security.Cryptography.RandomNumberGenerator]::GetInt32(1, 11)
    }.GetNewClosure()
}

function Resolve-Bands {
    param([object[]]$Bands, [int]$AdjustedRoll)
    foreach ($band in $Bands) {
        if ($AdjustedRoll -le [int]$band[0]) { return $band[1] }
    }
    return $Bands[-1][1]
}

function Get-Ordinal([int]$Number) {
    if (($Number % 100) -in 11,12,13) { return "${Number}th" }
    switch ($Number % 10) { 1 { "${Number}st" } 2 { "${Number}nd" } 3 { "${Number}rd" } default { "${Number}th" } }
}

function Get-Surname([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $Name }
    return ($Name.Trim() -split '\s+')[-1]
}

function Get-Possessive([string]$Name) {
    $surname = Get-Surname $Name
    if ($surname.EndsWith('s')) { return "$surname'" }
    return "$surname's"
}

function Get-OptionalAt([object[]]$Values, [int]$Index) {
    if ($null -eq $Values -or $Index -lt 0 -or $Index -ge $Values.Count) { return $null }
    return $Values[$Index]
}

function Get-OptionalProperty([object]$Object,[string]$Name) {
    if($null -eq $Object -or -not $Object.psobject.Properties[$Name]){return $null}
    return $Object.$Name
}

function Reserve-UniqueName([hashtable]$Used,[string]$Value,[string]$Side) {
    if([string]::IsNullOrWhiteSpace($Value)){return}
    $key=$Value.ToLowerInvariant()
    if($Used.ContainsKey($key)){throw "Duplicate name '$Value' within $Side."}
    $Used[$key]=$true
}

function Test-Match([string]$Value, [string]$Wanted) {
    $Value -eq 'All' -or $Value -eq 'Both' -or ($Value -split '\|') -contains $Wanted
}

function Select-HistoricalName {
    param(
        [object[]]$Rows, [string]$Side, [string]$Theatre, [string]$Period,
        [string]$Role, [string]$Arm, [hashtable]$Used, [string]$ValueColumn,
        [string]$Fallback, [string]$Override
    )
    if (-not [string]::IsNullOrWhiteSpace($Override)) {
        if ($Used.ContainsKey($Override.ToLowerInvariant())) { throw "Duplicate override '$Override' within $Side." }
        $Used[$Override.ToLowerInvariant()] = $true
        return [pscustomobject]@{ Value=$Override; Provenance='User override'; IsFallback=$false }
    }
    $pool = @($Rows | Where-Object {
        $rolesValue = if ($_.psobject.Properties['Roles']) { [string]$_.Roles } else { '' }
        $armsValue = if ($_.psobject.Properties['Arms']) { [string]$_.Arms } elseif ($_.psobject.Properties['Arm']) { [string]$_.Arm } else { '' }
        $_.Side -eq $Side -and (Test-Match $_.Theatre $Theatre) -and (Test-Match $_.Period $Period) -and
        ((-not $Role) -or (Test-Match $rolesValue $Role)) -and ((-not $Arm) -or (Test-Match $armsValue $Arm)) -and
        -not $Used.ContainsKey(([string]$_.$ValueColumn).ToLowerInvariant())
    })
    if ($pool.Count -gt 0) {
        $row = $pool[(Get-SecureIndex $pool.Count)]
        $value = [string]$row.$ValueColumn
        $Used[$value.ToLowerInvariant()] = $true
        return [pscustomobject]@{ Value=$value; Provenance="Historical: $($row.Battle), $($row.SourceUrl)"; IsFallback=$false }
    }
    $candidate = $Fallback
    $suffix = 2
    while ($Used.ContainsKey($candidate.ToLowerInvariant())) { $candidate = "$Fallback $suffix"; $suffix++ }
    $Used[$candidate.ToLowerInvariant()] = $true
    return [pscustomobject]@{ Value=$candidate; Provenance='Generated period-style fallback'; IsFallback=$true }
}

function Add-RollLog {
    param([System.Collections.ArrayList]$Log, [string]$Table, [string]$Side, [string]$FormationId,
          [string]$UnitId, [int]$Raw, [string]$Modifiers, [int]$Adjusted, [string]$Result,
          [string]$Cap='', [string]$Naming='')
    $row = [pscustomobject]@{
        Sequence=$Log.Count + 1; Table=$Table; Side=$Side; FormationId=$FormationId; UnitId=$UnitId
        RawRoll=$Raw; Modifiers=$Modifiers; AdjustedRoll=$Adjusted; Result=$Result
        CapOrSubstitution=$Cap; NameProvenance=$Naming
    }
    [void]$Log.Add($row)
    return $row
}

function Assert-RffRequest {
    param([object]$Request)
    if ($Request.theatre -notin 'Eastern','Western') { throw 'theatre must be Eastern or Western.' }
    $periodValue=if($Request.psobject.Properties['period']){$Request.period}else{$null};$yearValue=if($Request.psobject.Properties['year']){$Request.year}else{$null}
    if (-not $periodValue -and -not $yearValue) { throw 'Provide period or year.' }
    if ($periodValue -and $periodValue -notin 'Early War','Mid War','Late War') { throw 'period must be Early War, Mid War, or Late War.' }
    if ($yearValue -and ([int]$yearValue -lt 1861 -or [int]$yearValue -gt 1865)) { throw 'year must be 1861 through 1865.' }
    if (-not $Request.forces) { throw 'forces must contain USA and/or CSA.' }
    $sides = @($Request.forces.psobject.Properties.Name)
    if ($sides.Count -eq 0 -or @($sides | Where-Object { $_ -notin 'USA','CSA' }).Count -gt 0) { throw 'forces may contain only USA and CSA.' }
    $total = 0
    foreach ($side in $sides) {
        $force = $Request.forces.$side
        $brigades = @($force.brigades)
        if ($brigades.Count -gt 5) { throw "$side may have at most five actual brigades." }
        foreach ($brigade in $brigades) {
            if ($brigade.type -notin 'Infantry','Cavalry') { throw "$side brigade type must be Infantry or Cavalry." }
        }
        $independent = $force.independent
        foreach ($field in 'infantry','cavalry','artillery') {
            if ($independent -and [int]$independent.$field -lt 0) { throw "$side independent $field count cannot be negative." }
            if ($independent) { $total += [int]$independent.$field }
        }
        $total += $brigades.Count
    }
    if ($total -eq 0) { throw 'Request at least one brigade or independent unit.' }
}

function New-RegimentalFireAndFuryArmy {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Request, [string]$SkillRoot = (Split-Path $PSScriptRoot -Parent),
          [switch]$TestMode, [int[]]$TestRollSequence)

    Assert-RffRequest $Request
    $rules = Get-RffRules $SkillRoot
    $requestPeriod=if($Request.psobject.Properties['period']){$Request.period}else{$null};$requestYear=if($Request.psobject.Properties['year']){$Request.year}else{$null}
    $period = if ($requestPeriod) { [string]$requestPeriod } else { [string]$rules.periods.([string]$requestYear) }
    if ($requestPeriod -and $requestYear -and [string]$rules.periods.([string]$requestYear) -ne $period) { throw 'year and period disagree.' }
    $theatre = [string]$Request.theatre
    $roll = New-RollProvider -TestMode:$TestMode -TestRollSequence $TestRollSequence
    $log = [System.Collections.ArrayList]::new()
    $commanderRows = @(Import-Csv (Join-Path $SkillRoot 'references/commander-names.csv'))
    $unitRows = @(Import-Csv (Join-Path $SkillRoot 'references/unit-names.csv'))
    $divisions = [System.Collections.ArrayList]::new()
    $usedNames = @{ USA=@{}; CSA=@{} }
    $fallbackUsed = $false

    foreach ($side in 'USA','CSA') {
        if (-not $Request.forces.psobject.Properties[$side]) { continue }
        $force = $Request.forces.$side
        $used = $usedNames[$side]
        $ind=Get-OptionalProperty $force 'independent'
        $actualArms=@(@($force.brigades)|ForEach-Object{$_.type}|Select-Object -Unique)
        $divisionArm=if($actualArms.Count -eq 1){[string]$actualArms[0]}elseif($actualArms.Count -gt 1){'Infantry'}elseif($ind -and [int]$ind.infantry -gt 0){'Infantry'}elseif($ind -and [int]$ind.cavalry -gt 0){'Cavalry'}else{'Artillery'}
        $divisionObject=Get-OptionalProperty $force 'division'
        $divisionOverride = [string](Get-OptionalProperty $divisionObject 'commander')
        $divisionCommander = Select-HistoricalName $commanderRows $side $theatre $period 'Division' $divisionArm $used 'FullName' $(if($side -eq 'USA'){'Edwin Mercer'}else{'Cyrus Beauregard'}) $divisionOverride
        $fallbackUsed = $fallbackUsed -or $divisionCommander.IsFallback
        $divisionNameOverride=Get-OptionalProperty $divisionObject 'name'
        $divisionName = if ($divisionNameOverride) { [string]$divisionNameOverride } elseif ($side -eq 'USA') { '1st Division' } else { "$(Get-Possessive $divisionCommander.Value) Division" }
        Reserve-UniqueName $used $divisionName $side
        $division = [pscustomobject]@{
            Side=$side; Name=$divisionName; Commander=$divisionCommander.Value; CommanderProvenance=$divisionCommander.Provenance
            Talent=[string](Get-OptionalProperty $divisionObject 'talent'); Theatre=$theatre; Period=$period
            Brigades=[System.Collections.ArrayList]::new(); Notes=if($divisionCommander.IsFallback){'Fallback commander generated.'}else{''}
        }
        [void]$divisions.Add($division)
        $actualIndex = 0
        foreach ($brigadeRequest in @($force.brigades)) {
            $actualIndex++
            $id = "$side-B$actualIndex"
            $commander = Select-HistoricalName $commanderRows $side $theatre $period 'Brigade' ([string]$brigadeRequest.type) $used 'FullName' $(if($side -eq 'USA'){"Arthur Campbell $actualIndex"}else{"Caleb Beauregard $actualIndex"}) ([string](Get-OptionalProperty $brigadeRequest 'commander'))
            $fallbackUsed = $fallbackUsed -or $commander.IsFallback
            $brigadeNameOverride=Get-OptionalProperty $brigadeRequest 'name'
            $name = if ($brigadeNameOverride) { [string]$brigadeNameOverride } elseif ($side -eq 'USA') { "$(Get-Ordinal $actualIndex) Brigade" } else { Get-Possessive $commander.Value }
            Reserve-UniqueName $used $name $side
            [void]$division.Brigades.Add([pscustomobject]@{
                Id=$id; Type=[string]$brigadeRequest.type; Name=$name; Commander=$commander.Value; CommanderProvenance=$commander.Provenance
                Talent=[string](Get-OptionalProperty $brigadeRequest 'talent'); DisplayOrder=$actualIndex; IsActual=$true; IsIndependent=$false; IsDivisionArtillery=$false
                Units=[System.Collections.ArrayList]::new(); Request=$brigadeRequest; Notes=if($commander.IsFallback){'Fallback commander generated.'}else{''}
            })
        }
        $indCount = if($ind){[int]$ind.infantry + [int]$ind.cavalry + [int]$ind.artillery}else{0}
        if ($indCount -gt 0) {
            Reserve-UniqueName $used 'Independent Units' $side
            $independentArm=if([int]$ind.infantry -gt 0){'Infantry'}elseif([int]$ind.cavalry -gt 0){'Cavalry'}else{'Artillery'}
            $commander = Select-HistoricalName $commanderRows $side $theatre $period 'Brigade' $independentArm $used 'FullName' $(if($side -eq 'USA'){'Nathaniel Cole'}else{'Lucius Talbot'}) ([string](Get-OptionalProperty $ind 'commander'))
            $fallbackUsed = $fallbackUsed -or $commander.IsFallback
            [void]$division.Brigades.Add([pscustomobject]@{
                Id="$side-IU1"; Type='Independent'; Name='Independent Units'; Commander=$commander.Value; CommanderProvenance=$commander.Provenance
                Talent=[string](Get-OptionalProperty $ind 'talent'); DisplayOrder=90; IsActual=$false; IsIndependent=$true; IsDivisionArtillery=$false
                Units=[System.Collections.ArrayList]::new(); Request=$ind; Notes=if($commander.IsFallback){'Fallback commander generated.'}else{''}
            })
        }
        if (@($force.brigades).Count -gt 0) {
            Reserve-UniqueName $used 'Division Artillery' $side
            $da = Get-OptionalProperty $force 'divisionArtillery'
            $commander = Select-HistoricalName $commanderRows $side $theatre $period 'Artillery' 'Artillery' $used 'FullName' $(if($side -eq 'USA'){'Silas Porter'}else{'Augustus Pegram'}) ([string](Get-OptionalProperty $da 'commander'))
            $fallbackUsed = $fallbackUsed -or $commander.IsFallback
            [void]$division.Brigades.Add([pscustomobject]@{
                Id="$side-DA1"; Type='Artillery'; Name='Division Artillery'; Commander=$commander.Value; CommanderProvenance=$commander.Provenance
                Talent=[string](Get-OptionalProperty $da 'talent'); DisplayOrder=99; IsActual=$false; IsIndependent=$false; IsDivisionArtillery=$true
                Units=[System.Collections.ArrayList]::new(); Request=$da; Notes=if($commander.IsFallback){'Fallback commander generated.'}else{''}
            })
        }
    }

    # Table 1: regiment count for actual brigades.
    foreach ($division in $divisions) {
        foreach ($brigade in @($division.Brigades | Where-Object IsActual | Sort-Object DisplayOrder)) {
            $raw = & $roll
            $modifier = if ($theatre -eq 'Western') { [int]$rules.table1.($division.Side).westernModifier } else { 0 }
            $adjusted = $raw + $modifier
            $count = [int](Resolve-Bands $rules.table1.($division.Side).bands $adjusted)
            [void](Add-RollLog $log '1' $division.Side $brigade.Id '' $raw $(if($modifier){"Western $modifier"}else{'None'}) $adjusted "$count regiments" '' $brigade.CommanderProvenance)
            $brigade | Add-Member RegimentCount $count
        }
    }

    # Construct infantry/cavalry unit records now that Table 1 is resolved.
    foreach ($division in $divisions) {
        $unitOrder = 0
        foreach ($brigade in @($division.Brigades | Sort-Object DisplayOrder)) {
            $unitSpecs = [System.Collections.ArrayList]::new()
            if ($brigade.IsActual) {
                $regimentNames=@(Get-OptionalProperty $brigade.Request 'regimentNames'); $regimentCommanders=@(Get-OptionalProperty $brigade.Request 'regimentCommanders')
                for ($i=0; $i -lt $brigade.RegimentCount; $i++) { [void]$unitSpecs.Add([pscustomobject]@{ Arm=$brigade.Type; NameOverride=(Get-OptionalAt $regimentNames $i); CommanderOverride=(Get-OptionalAt $regimentCommanders $i) }) }
            } elseif ($brigade.IsIndependent) {
                $names=@(Get-OptionalProperty $brigade.Request 'unitNames'); $commanders=@(Get-OptionalProperty $brigade.Request 'unitCommanders'); $cursor=0
                foreach ($arm in 'Infantry','Cavalry','Artillery') {
                    $field=$arm.ToLowerInvariant(); for($i=0;$i -lt [int]$brigade.Request.$field;$i++) {
                        [void]$unitSpecs.Add([pscustomobject]@{ Arm=$arm; NameOverride=(Get-OptionalAt $names $cursor); CommanderOverride=(Get-OptionalAt $commanders $cursor) }); $cursor++
                    }
                }
            }
            $local=0
            foreach ($spec in $unitSpecs) {
                $local++; $unitOrder++
                $prefix = if($spec.Arm -eq 'Artillery'){'A'}elseif($spec.Arm -eq 'Cavalry'){'C'}else{'R'}
                $id = "$($brigade.Id)-$prefix$local"
                $fallbackName = if($spec.Arm -eq 'Artillery'){"$(if($division.Side -eq 'USA'){'Federal'}else{'Confederate'}) Battery $local"}else{"$(Get-Ordinal (20+$unitOrder)) $(if($division.Side -eq 'USA'){'Volunteer'}else{'State'}) $($spec.Arm)"}
                $name = Select-HistoricalName $unitRows $division.Side $theatre $period '' $spec.Arm $usedNames[$division.Side] 'Designation' $fallbackName ([string]$spec.NameOverride)
                $commanderRole=if($spec.Arm -eq 'Artillery'){'Battery'}else{'Regiment'}
                $unitCommander = Select-HistoricalName $commanderRows $division.Side $theatre $period $commanderRole $spec.Arm $usedNames[$division.Side] 'FullName' $(if($division.Side -eq 'USA'){"Henry Abbott $unitOrder"}else{"Thomas Garnett $unitOrder"}) ([string]$spec.CommanderOverride)
                $fallbackUsed = $fallbackUsed -or $name.IsFallback -or $unitCommander.IsFallback
                [void]$brigade.Units.Add([pscustomobject]@{
                    Id=$id; BrigadeId=$brigade.Id; Name=$name.Value; Commander=$unitCommander.Value; Arm=$spec.Arm; DisplayOrder=$unitOrder
                    NameProvenance=$name.Provenance; CommanderProvenance=$unitCommander.Provenance; Stands=$null; Guns=$null; Experience=''; Morale=''; WeaponCode=''; BraveColonel=$false
                    Notes=if($name.IsFallback -or $unitCommander.IsFallback){'Fallback name generated.'}else{''}
                })
            }
        }
    }

    # Table 2: division, actual brigade, division artillery, then independent leaders, USA before CSA.
    foreach ($division in $divisions) {
        $leaders = @([pscustomobject]@{ Id="$($division.Side)-DIV1"; Target=$division; Provenance=$division.CommanderProvenance }) +
                   @($division.Brigades | Where-Object IsActual | Sort-Object DisplayOrder | ForEach-Object { [pscustomobject]@{Id=$_.Id;Target=$_;Provenance=$_.CommanderProvenance} }) +
                   @($division.Brigades | Where-Object IsDivisionArtillery | ForEach-Object { [pscustomobject]@{Id=$_.Id;Target=$_;Provenance=$_.CommanderProvenance} }) +
                   @($division.Brigades | Where-Object IsIndependent | ForEach-Object { [pscustomobject]@{Id=$_.Id;Target=$_;Provenance=$_.CommanderProvenance} })
        foreach ($leader in $leaders) {
            if ($leader.Target.Talent) {
                [void](Add-RollLog $log '2' $division.Side $leader.Id '' 0 'Override' 0 ([string]$leader.Target.Talent) '' $leader.Provenance)
            } else {
                $raw=&$roll; $talent=[string](Resolve-Bands $rules.table2.$period.($division.Side) $raw); $leader.Target.Talent=$talent
                [void](Add-RollLog $log '2' $division.Side $leader.Id '' $raw 'None' $raw $talent '' $leader.Provenance)
            }
        }
    }

    # Table 2.1: Brave Colonels, capped per actual or pseudo-brigade.
    foreach ($division in $divisions) { foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)) {
        $braveCount=0
        foreach($unit in @($brigade.Units | Where-Object { $_.Arm -in 'Infantry','Cavalry' } | Sort-Object DisplayOrder)) {
            $raw=&$roll; $isBrave=($raw -eq [int]$rules.table2_1.braveColonelRoll); $cap=''
            if($isBrave -and $braveCount -ge [int]$rules.table2_1.capPerBrigade){$isBrave=$false;$cap='Brave Colonel cap: result removed'}
            if($isBrave){$braveCount++}; $unit.BraveColonel=$isBrave
            [void](Add-RollLog $log '2.1' $division.Side $brigade.Id $unit.Id $raw 'None' $raw $(if($isBrave){'Brave Colonel'}else{'No Brave Colonel'}) $cap $unit.CommanderProvenance)
        }
    }}

    # Table 3: generated division artillery battery count.
    foreach($division in $divisions){
        $actualCount=@($division.Brigades | Where-Object IsActual).Count
        if($actualCount -eq 0){continue}
        $raw=&$roll; $batteryCount=[int](Resolve-Bands $rules.table3.([string]$actualCount) $raw)
        [void](Add-RollLog $log '3' $division.Side "$($division.Side)-DIV1" '' $raw "Actual brigades: $actualCount" $raw "$batteryCount batteries")
        $da=$division.Brigades | Where-Object IsDivisionArtillery
        $overNames=@(Get-OptionalProperty $da.Request 'batteryNames'); $overCommanders=@(Get-OptionalProperty $da.Request 'batteryCommanders')
        for($i=0;$i -lt $batteryCount;$i++){
            $n=$i+1; $name=Select-HistoricalName $unitRows $division.Side $theatre $period '' 'Artillery' $usedNames[$division.Side] 'Designation' $(if($division.Side -eq 'USA'){"Battery $([char](64+$n)), U.S. Artillery"}else{"Virginia Battery $n"}) ([string](Get-OptionalAt $overNames $i))
            $cmd=Select-HistoricalName $commanderRows $division.Side $theatre $period 'Battery' 'Artillery' $usedNames[$division.Side] 'FullName' $(if($division.Side -eq 'USA'){"Ezra Matthews $n"}else{"Edmund Cabell $n"}) ([string](Get-OptionalAt $overCommanders $i))
            $fallbackUsed=$fallbackUsed -or $name.IsFallback -or $cmd.IsFallback
            [void]$da.Units.Add([pscustomobject]@{Id="$($da.Id)-A$n";BrigadeId=$da.Id;Name=$name.Value;Commander=$cmd.Value;Arm='Artillery';DisplayOrder=$n;NameProvenance=$name.Provenance;CommanderProvenance=$cmd.Provenance;Stands=$null;Guns=$null;Experience='';Morale='';WeaponCode='';BraveColonel=$false;Notes=if($name.IsFallback -or $cmd.IsFallback){'Fallback name generated.'}else{''}})
        }
    }

    # Table 3.1: every generated or independent battery.
    foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)) { foreach($unit in @($brigade.Units | Where-Object {$_.Arm -eq 'Artillery'} | Sort-Object DisplayOrder)) {
        $raw=&$roll; $guns=[int](Resolve-Bands $rules.table3_1.($division.Side) $raw); $unit.Guns=$guns
        [void](Add-RollLog $log '3.1' $division.Side $brigade.Id $unit.Id $raw 'None' $raw "$guns guns" '' $unit.NameProvenance)
    }}}

    # Table 4: infantry and cavalry stand strength.
    foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)){ foreach($unit in @($brigade.Units | Where-Object {$_.Arm -in 'Infantry','Cavalry'} | Sort-Object DisplayOrder)){
        $raw=&$roll; $stands=[int]$rules.table4.($unit.Arm).$period.($division.Side)[$raw-1]; $unit.Stands=$stands
        [void](Add-RollLog $log '4' $division.Side $brigade.Id $unit.Id $raw 'None' $raw "$stands stands")
    }}}

    # Table 5: experience for all regiments and batteries.
    foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)){ foreach($unit in @($brigade.Units | Sort-Object DisplayOrder)){
        $raw=&$roll; $experience=[string]$rules.table5.($unit.Arm).$period.($division.Side)[$raw-1]; $unit.Experience=$experience
        [void](Add-RollLog $log '5' $division.Side $brigade.Id $unit.Id $raw 'None' $raw $experience)
    }}}

    # Table 6: morale, after all applicable modifiers.
    foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)){ foreach($unit in @($brigade.Units | Sort-Object DisplayOrder)){
        $raw=&$roll; $mods=[System.Collections.Generic.List[string]]::new(); $delta=0
        if($unit.Experience -eq 'Crack'){$delta+=2;$mods.Add('Crack +2')} elseif($unit.Experience -eq 'Veteran'){$delta+=1;$mods.Add('Veteran +1')}
        if($division.Side -eq 'CSA' -and $theatre -eq 'Eastern'){$delta+=1;$mods.Add('Eastern CSA +1')}
        if($division.Side -eq 'USA' -and $theatre -eq 'Western' -and $period -eq 'Late War'){$delta+=1;$mods.Add('Late Western USA +1')}
        if($division.Side -eq 'USA' -and $unit.Arm -eq 'Cavalry' -and $period -eq 'Early War'){$delta-=1;$mods.Add('Early USA Cavalry -1')}
        $adjusted=$raw+$delta; $morale=[string](Resolve-Bands $rules.table6.$period.($division.Side) $adjusted); $unit.Morale=$morale
        [void](Add-RollLog $log '6' $division.Side $brigade.Id $unit.Id $raw $(if($mods.Count){$mods -join '; '}else{'None'}) $adjusted $morale)
    }}}

    # Table 7: weapons for all units, then optional Mountain Howitzer checks and side caps.
    $table7Rows=@{}
    foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)){ foreach($unit in @($brigade.Units | Sort-Object DisplayOrder)){
        $raw=&$roll; $code=[string]$rules.table7.($unit.Arm).$theatre.$period.($division.Side)[$raw-1]; $unit.WeaponCode=$code
        $table7Rows[$unit.Id]=Add-RollLog $log '7' $division.Side $brigade.Id $unit.Id $raw 'None' $raw "$code - $($rules.weapons.$code)"
    }}}
    if([bool](Get-OptionalProperty $Request 'mountainHowitzerEligible') -and $theatre -eq 'Western' -and $period -in 'Early War','Mid War'){
        foreach($division in $divisions){ foreach($brigade in @($division.Brigades | Sort-Object DisplayOrder)){ foreach($unit in @($brigade.Units | Where-Object {$_.Arm -eq 'Artillery' -and $_.WeaponCode -eq 'LH'} | Sort-Object DisplayOrder)){
            $raw=&$roll; if($raw -eq 1){$unit.WeaponCode='MH';$result='Mountain Howitzer substituted'}else{$result='Light Howitzer retained'}
            [void](Add-RollLog $log '7*' $division.Side $brigade.Id $unit.Id $raw 'Mountain Howitzer eligibility' $raw $result)
        }}}
    }
    foreach($division in $divisions){
        $repeater=0; $heavy=0
        foreach($brigade in @($division.Brigades|Sort-Object DisplayOrder)){foreach($unit in @($brigade.Units|Sort-Object DisplayOrder)){
            if($unit.WeaponCode -eq 'RPC'){$repeater++;if($repeater -gt [int]$rules.caps.repeatersPerSide){$replacement=if($unit.Arm -eq 'Cavalry'){'BLC'}else{'RM'};$unit.WeaponCode=$replacement;$table7Rows[$unit.Id].CapOrSubstitution="Repeater cap: substituted $replacement"}}
            if($unit.WeaponCode -eq 'HR'){$heavy++;if($heavy -gt [int]$rules.caps.heavyRiflesPerSide){$unit.WeaponCode='LR';$table7Rows[$unit.Id].CapOrSubstitution='Heavy Rifle cap: substituted LR'}}
        }}
    }

    [pscustomobject]@{ Version='1.0.0'; Theatre=$theatre; Period=$period; Year=$requestYear; Divisions=$divisions; RollLog=$log; Rules=$rules; FallbackNamesUsed=$fallbackUsed }
}

function Get-UnitEffectiveness([object]$Model,[object]$Unit) {
    if($Unit.Arm -eq 'Artillery'){return "$($Unit.Guns) guns"}
    return [string]$Model.Rules.effectiveness.([string]$Unit.Stands).($Unit.Morale)
}

function Get-UnitLabelRows([object]$Model,[object]$Unit,[object]$Brigade,[switch]$Dismounted) {
    $name=if($Dismounted){"Dismounted $($Unit.Name)"}else{$Unit.Name}
    $exp=[string]$Model.Rules.experienceCodes.($Unit.Experience)
    $eff=Get-UnitEffectiveness $Model $Unit
    $rows=if($Unit.Arm -eq 'Artillery'){@("($($Brigade.Commander))",$name,$Unit.Commander,"$exp $($Unit.WeaponCode)")}else{@("($($Brigade.Commander))",$name,"$exp $eff $($Unit.WeaponCode)")}
    [pscustomobject]@{Rows=$rows;Brave=[bool]$Unit.BraveColonel}
}

Export-ModuleMember -Function Get-RffRules,Resolve-Bands,New-RegimentalFireAndFuryArmy,Get-UnitEffectiveness,Get-UnitLabelRows
