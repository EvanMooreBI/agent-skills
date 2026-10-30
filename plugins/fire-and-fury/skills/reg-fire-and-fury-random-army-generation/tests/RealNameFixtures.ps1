function Get-RffRealNameFixtures {
    param([Parameter(Mandatory)][string]$SourcePath)
    $rows=@(Import-Csv -LiteralPath $SourcePath -Encoding utf8 -ErrorAction Stop)
    if(-not $rows.Count){throw 'The real-name source CSV is empty.'}
    foreach($column in 'Label_ID','Faction','Label_Type','Unit_Type','Commander','Unit_Name'){
        if(-not $rows[0].PSObject.Properties[$column]){throw "Missing real-name source column: $column"}
    }
    if(@($rows.Label_ID|Sort-Object -Unique).Count -ne $rows.Count){throw 'Duplicate real-name source Label_ID.'}
    foreach($row in $rows){
        if($row.Faction -notin @('USA','CSA') -or [string]::IsNullOrWhiteSpace($row.Unit_Name)){
            throw "Invalid real-name source row: $($row.Label_ID)"
        }
    }
    function SourceRows([string]$Side,[string]$Type,[string]$Commander=''){
        $selected=@($rows|Where-Object { $_.Faction -eq $Side -and $_.Unit_Type -eq $Type -and $_.Label_Type -ne 'Leader' -and (-not $Commander -or $_.Commander -eq $Commander) })
        if(-not $selected.Count){throw "No real-name rows for $Side $Type $Commander"}
        return $selected
    }
    function Leader([string]$Side,[string]$Commander){
        $leader=@($rows|Where-Object { $_.Faction -eq $Side -and $_.Label_Type -eq 'Leader' -and $_.Commander -eq $Commander })
        if($leader.Count -ne 1){throw "Expected one source leader: $Side $Commander"}
        return $leader[0]
    }
    function Brigade([string]$Side,[string]$Type,[string]$Commander){
        $leader=Leader $Side $Commander
        [ordered]@{type=$Type;commander=$leader.Commander;talent='Able';regimentNames=@((SourceRows $Side $Type $Commander).Unit_Name);regimentCommanders=@()}
    }
    function Batteries([string]$Side){
        $seen=@{}
        foreach($row in (SourceRows $Side 'Artillery')){
            $commander=($row.Unit_Name -split '\s+')[-1]
            if(-not $seen.ContainsKey($commander)){$seen[$commander]=$true;$row}
        }
    }
    function Independent([string]$Side,[string]$Commander){
        $inf=@(SourceRows $Side 'Infantry'|Select-Object -First 2)
        $cav=@(SourceRows $Side 'Cavalry'|Select-Object -First 2)
        $guns=@(Batteries $Side|Select-Object -First 2)
        [ordered]@{infantry=$inf.Count;cavalry=$cav.Count;artillery=$guns.Count;commander=(Leader $Side $Commander).Commander;talent='Able';unitNames=@(($inf+$cav+$guns).Unit_Name);unitCommanders=@()}
    }
    $empty=[ordered]@{infantry=0;cavalry=0;artillery=0;unitNames=@();unitCommanders=@()}
    $usaDivision=Leader 'USA' 'Davis'
    $assigned=[ordered]@{theatre='Western';period='Mid War';mountainHowitzerEligible=$false;forces=[ordered]@{
        USA=[ordered]@{division=@{name=$usaDivision.Unit_Name;commander=$usaDivision.Commander;talent='Able'};brigades=@((Brigade 'USA' 'Infantry' 'Carlin'),(Brigade 'USA' 'Cavalry' 'Wilder'));independent=$empty;divisionArtillery=@{commander=(Leader 'USA' 'Mendenhall').Commander;talent='Able';batteryNames=@((Batteries 'USA').Unit_Name);batteryCommanders=@('Woodbury','Lilly','Bradley')}}
        CSA=[ordered]@{division=@{commander=(Leader 'CSA' 'Robertson').Commander;talent='Able'};brigades=@((Brigade 'CSA' 'Infantry' 'Gregg'));independent=$empty;divisionArtillery=@{commander=(Leader 'CSA' 'Benning').Commander;talent='Able';batteryNames=@((SourceRows 'CSA' 'Artillery').Unit_Name);batteryCommanders=@('Bledsoe')}}
    }}
    $unassigned=[ordered]@{theatre='Western';period='Mid War';mountainHowitzerEligible=$false;forces=[ordered]@{
        USA=[ordered]@{division=@{name=$usaDivision.Unit_Name;commander=$usaDivision.Commander;talent='Able'};brigades=@();independent=(Independent 'USA' 'Mendenhall');divisionArtillery=@{}}
        CSA=[ordered]@{division=@{commander=(Leader 'CSA' 'Robertson').Commander;talent='Able'};brigades=@();independent=(Independent 'CSA' 'Trigg');divisionArtillery=@{}}
    }}
    $assigned.forces.USA.brigades[0].regimentCommanders=@('Heg','Wood','Buell','Harker')
    $assigned.forces.USA.brigades[1].regimentCommanders=@('Barnes','Estep','Livingston')
    $assigned.forces.CSA.brigades[0].regimentCommanders=@('Trigg','Culpeper','Everett')
    $unassigned.forces.USA.independent.unitCommanders=@('Carlin','Heg','Wilder','Wood','Woodbury','Lilly')
    $unassigned.forces.CSA.independent.unitCommanders=@('Benning','Gregg','Everett','Bledsoe','Culpeper')
    $commanders=@($rows|Where-Object Label_Type -eq 'Leader'|ForEach-Object Commander)+@($rows|Where-Object Label_Type -eq 'Gun'|ForEach-Object {($_.Unit_Name -split '\s+')[-1]})
    foreach($force in @($assigned.forces.USA,$assigned.forces.CSA,$unassigned.forces.USA,$unassigned.forces.CSA)){
        $names=@($force.division.commander)+@($force.brigades|ForEach-Object {$_.commander;$_.regimentCommanders})
        if($force.independent.Contains('commander')){$names+=@($force.independent.commander)+@($force.independent.unitCommanders)}
        if($force.divisionArtillery.ContainsKey('commander')){$names+=@($force.divisionArtillery.commander)+@($force.divisionArtillery.batteryCommanders)}
        foreach($name in $names){if($name -notin $commanders){throw "Commander missing from real-name CSV: $name"}}
    }
    # These are name/layout fixtures, not historical orders of battle. Existing
    # rules still generate every rating, weapon, gun count and Brave Colonel.
    [ordered]@{
        # Table 1, ten Brave Colonel rolls, Table 3 for each side, then ratings.
        'real-names-assigned'=@{Request=$assigned;Rolls=(@(4,1,1)+@(1..10|ForEach-Object{10})+@(10,1)+@(1..12000|ForEach-Object{10}))}
        'real-names-unassigned'=@{Request=$unassigned;Rolls=@(1..12000|ForEach-Object{10})}
    }
}
