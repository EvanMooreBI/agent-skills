Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CsvHeaders = @('Sequence','RecordType','Step','Side','FormationId','UnitId','RawRoll','Modifiers','AdjustedRoll','Result','Substitution','SourceTable','Notes')

function New-RffLabelRecord {
    param([string]$Id,[string]$Role,[string[]]$Rows,[string[]]$Kinds,[bool]$Brave=$false)
    $lines = for ($i=0; $i -lt $Rows.Count; $i++) { [ordered]@{text=[string]$Rows[$i];kind=$Kinds[$i]} }
    [ordered]@{id=$Id;role=$Role;rows=@($lines);brave=$Brave}
}

function ConvertTo-RffRenderData {
    param([Parameter(Mandatory)][object]$Model)
    $sides = foreach ($division in $Model.Divisions) {
        $divisionId = "$($division.Side)-DIV1"
        $groups = foreach ($brigade in @($division.Brigades | Sort-Object DisplayOrder)) {
            $labels = foreach ($unit in @($brigade.Units | Sort-Object DisplayOrder)) {
                $label = Get-UnitLabelRows $Model $unit $brigade
                $copies = if ($unit.Arm -eq 'Artillery') { [int]$unit.Guns } else { 1 }
                for ($i=1; $i -le $copies; $i++) {
                    $id = if ($unit.Arm -eq 'Artillery') { "$($unit.Id):gun:$i" } else { $unit.Id }
                    $kinds = if ($unit.Arm -eq 'Artillery') { @('name','name','name','rating') } else { @('name','name','rating') }
                    New-RffLabelRecord $id $unit.Arm.ToLowerInvariant() $label.Rows $kinds $label.Brave
                }
            }
            if (@($labels).Count) {
                [ordered]@{id=$brigade.Id;independent=[bool]$brigade.IsIndependent;label=(New-RffLabelRecord $brigade.Id 'brigade' @($brigade.Name,$brigade.Commander,$brigade.Talent) @('name','name','rating'));units=@($labels)}
            }
        }
        $dismounted = foreach ($brigade in @($division.Brigades | Sort-Object DisplayOrder)) {
            foreach ($unit in @($brigade.Units | Where-Object Arm -eq 'Cavalry' | Sort-Object DisplayOrder)) {
                $label=Get-UnitLabelRows $Model $unit $brigade -Dismounted
                New-RffLabelRecord "$($unit.Id):dismounted" 'dismounted' $label.Rows @('name','name','rating') $label.Brave
            }
        }
        [ordered]@{side=$division.Side;header="$($division.Side) - $($Model.Theatre) - $($Model.Period)";division=(New-RffLabelRecord $divisionId 'division' @($division.Name,$division.Commander,$division.Talent) @('name','name','rating'));groups=@($groups);dismounted=@($dismounted)}
    }
    [ordered]@{version=1;sides=@($sides)}
}

function Add-RffCsvRow {
    param([System.Collections.Generic.List[object]]$Rows,[string]$Type,[string]$Step,[string]$Side='',[string]$FormationId='',[string]$UnitId='',
          [object]$RawRoll='',[string]$Modifiers='',[object]$AdjustedRoll='',[string]$Result='',[string]$Substitution='',[string]$SourceTable='',[string]$Notes='')
    $Rows.Add([pscustomobject][ordered]@{Sequence=$Rows.Count+1;RecordType=$Type;Step=$Step;Side=$Side;FormationId=$FormationId;UnitId=$UnitId;RawRoll=$RawRoll;Modifiers=$Modifiers;AdjustedRoll=$AdjustedRoll;Result=$Result;Substitution=$Substitution;SourceTable=$SourceTable;Notes=$Notes})
}

function New-RffCsvRecords {
    param([Parameter(Mandatory)][object]$Model,[Parameter(Mandatory)][object]$Request)
    $rows=[System.Collections.Generic.List[object]]::new()
    $configuration=[ordered]@{request=$Request;period=$Model.Period;theatre=$Model.Theatre;year=$Model.Year;modelVersion=$Model.Version;csvVersion=1;labelWidthMm=24;labelHeightMm=25;fallbackNamesUsed=$Model.FallbackNamesUsed}
    Add-RffCsvRow -Rows $rows -Type Configuration -Step Request -Result ($configuration|ConvertTo-Json -Depth 30 -Compress) -SourceTable 'RequestPath'
    foreach ($entry in $Model.RollLog) {
        $override=$entry.Modifiers -eq 'Override'
        Add-RffCsvRow -Rows $rows -Type $(if($override){'Override'}else{'Roll'}) -Step $entry.Table -Side $entry.Side -FormationId $entry.FormationId -UnitId $entry.UnitId -RawRoll $(if($override){''}else{$entry.RawRoll}) -Modifiers $entry.Modifiers -AdjustedRoll $(if($override){''}else{$entry.AdjustedRoll}) -Result $entry.Result -Substitution $entry.CapOrSubstitution -SourceTable "army-generation-rules.json:$($entry.Table)" -Notes $entry.NameProvenance
    }
    foreach ($division in $Model.Divisions) {
        $divisionId="$($division.Side)-DIV1"
        $record=[ordered]@{Kind='Division';Side=$division.Side;Id=$divisionId;ParentId='';Name=$division.Name;Commander=$division.Commander;Talent=$division.Talent;Theatre=$division.Theatre;Period=$division.Period;DisplayOrder=0;Notes=$division.Notes;CommanderProvenance=$division.CommanderProvenance}
        Add-RffCsvRow -Rows $rows -Type Formation -Step ROSTER -Side $division.Side -FormationId $divisionId -Result ($record|ConvertTo-Json -Compress) -SourceTable New-RegimentalFireAndFuryArmy
        foreach ($brigade in @($division.Brigades|Sort-Object DisplayOrder)) {
            $record=[ordered]@{Kind='Brigade';Side=$division.Side;Id=$brigade.Id;ParentId=$divisionId;Type=$brigade.Type;Name=$brigade.Name;Commander=$brigade.Commander;Talent=$brigade.Talent;Theatre=$Model.Theatre;Period=$Model.Period;DisplayOrder=$brigade.DisplayOrder;IsActual=$brigade.IsActual;IsIndependent=$brigade.IsIndependent;IsDivisionArtillery=$brigade.IsDivisionArtillery;Notes=$brigade.Notes;CommanderProvenance=$brigade.CommanderProvenance}
            Add-RffCsvRow -Rows $rows -Type Formation -Step ROSTER -Side $division.Side -FormationId $brigade.Id -Result ($record|ConvertTo-Json -Compress) -SourceTable New-RegimentalFireAndFuryArmy
            foreach ($unit in @($brigade.Units|Sort-Object DisplayOrder)) {
                $record=[ordered]@{Side=$division.Side;BrigadeId=$unit.BrigadeId;Id=$unit.Id;Name=$unit.Name;Commander=$unit.Commander;Arm=$unit.Arm;Stands=$unit.Stands;Guns=$unit.Guns;Experience=$unit.Experience;Morale=$unit.Morale;Weapon=$Model.Rules.weapons.($unit.WeaponCode);WeaponCode=$unit.WeaponCode;Effectiveness=(Get-UnitEffectiveness $Model $unit);BraveColonel=$unit.BraveColonel;DisplayOrder=$unit.DisplayOrder;Notes=$unit.Notes;NameProvenance=$unit.NameProvenance;CommanderProvenance=$unit.CommanderProvenance}
                Add-RffCsvRow -Rows $rows -Type Unit -Step ROSTER -Side $division.Side -FormationId $brigade.Id -UnitId $unit.Id -Result ($record|ConvertTo-Json -Compress) -SourceTable New-RegimentalFireAndFuryArmy
            }
        }
    }
    return ,$rows
}

function Publish-RffArtifacts {
    param([Parameter(Mandatory)][string]$PdfSource,[Parameter(Mandatory)][string]$PdfTarget,[Parameter(Mandatory)][string]$CsvSource,[Parameter(Mandatory)][string]$CsvTarget,[scriptblock]$BeforeCsvPublication)
    foreach($path in $PdfTarget,$CsvTarget){if(Test-Path -LiteralPath $path){throw "Refusing to overwrite existing output: $path"}}
    $pdfHash=(Get-FileHash -LiteralPath $PdfSource -Algorithm SHA256).Hash
    # File.Move refuses an overwrite, including a target created after preflight.
    [IO.File]::Move($PdfSource,$PdfTarget)
    try {
        # Internal fault-injection hook, never exposed by the production CLI.
        if($BeforeCsvPublication){& $BeforeCsvPublication}
        [IO.File]::Move($CsvSource,$CsvTarget)
    }
    catch {
        $publicationError=$_
        try {
            # Preserve a replacement created by another writer after our move.
            if((Test-Path -LiteralPath $PdfTarget -PathType Leaf) -and (Get-FileHash -LiteralPath $PdfTarget -Algorithm SHA256).Hash -eq $pdfHash){[IO.File]::Delete($PdfTarget)}
        } catch { Write-Warning "Could not roll back the published PDF: $($_.Exception.Message)" }
        throw $publicationError
    }
}

function Invoke-RffArtifactBuild {
    param([Parameter(Mandatory)][object]$Model,[Parameter(Mandatory)][object]$Request,[Parameter(Mandatory)][string]$Directory,[Parameter(Mandatory)][string]$Browser)
    $scriptRoot=$PSScriptRoot
    $Directory=[IO.Path]::GetFullPath($Directory)
    [void][IO.Directory]::CreateDirectory($Directory)
    $render=Join-Path $Directory 'render-data.json';$resolved=Join-Path $Directory 'resolved-model.json'
    $html=Join-Path $Directory 'labels.html';$manifest=Join-Path $Directory 'render-manifest.json'
    $pdf=Join-Path $Directory 'labels.pdf';$csv=Join-Path $Directory 'generation-log.csv'
    $requestFile=Join-Path $Directory 'request.json'
    [IO.File]::WriteAllText($requestFile,($Request|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($render,((ConvertTo-RffRenderData $Model)|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($resolved,($Model|ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false))
    & node (Join-Path $scriptRoot 'render-labels.js') $render $html $manifest | Out-Host
    if($LASTEXITCODE -ne 0){throw 'Label HTML rendering failed.'}
    $profile=Join-Path $Directory 'browser-profile'
    $arguments=@('--headless=new','--disable-gpu','--disable-extensions','--no-pdf-header-footer',"--user-data-dir=`"$profile`"", "--print-to-pdf=`"$pdf`"",([uri]$html).AbsoluteUri)
    $startOptions=@{FilePath=$Browser;ArgumentList=$arguments;PassThru=$true}
    if($IsWindows){$startOptions.WindowStyle='Hidden'}
    $process=Start-Process @startOptions
    if(-not $process.WaitForExit(30000)){
        $process.Kill($true)
        throw 'The isolated browser did not finish PDF rendering within 30 seconds.'
    }
    if($process.ExitCode -ne 0 -or -not(Test-Path -LiteralPath $pdf)){throw 'Browser PDF rendering failed.'}
    $check=& python (Join-Path $scriptRoot 'validate_pdf.py') $pdf $manifest $resolved (Join-Path $Directory 'previews')
    if($LASTEXITCODE -ne 0){throw "PDF validation failed: $check"}
    $validation=$check|ConvertFrom-Json
    $rows=New-RffCsvRecords $Model $Request
    Add-RffCsvRow -Rows $rows -Type Validation -Step PDF -Result ($validation|ConvertTo-Json -Compress) -SourceTable validate_pdf.py
    Add-RffCsvRow -Rows $rows -Type Validation -Step CSV -Result "Validated $($rows.Count+1) records" -SourceTable validate_csv.py
    $rows|Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
    $csvCheck=& python (Join-Path $scriptRoot 'validate_csv.py') $csv $resolved $requestFile $pdf
    if($LASTEXITCODE -ne 0){throw "CSV validation failed: $csvCheck"}
    [IO.File]::WriteAllText((Join-Path $Directory 'validation.json'),($validation|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
    [pscustomobject]@{Pdf=$pdf;Csv=$csv;Pages=$validation.pages;Labels=$validation.labels;LogRecords=$rows.Count}
}

function Find-RffBrowser {
    $tried=[System.Collections.Generic.List[string]]::new()
    if($env:CHROME_PATH){
        if(Test-Path -LiteralPath $env:CHROME_PATH -PathType Leaf){return $env:CHROME_PATH}
        $tried.Add("CHROME_PATH=$env:CHROME_PATH")
    }
    $names='chrome','google-chrome','google-chrome-stable','chromium','chromium-browser','msedge','microsoft-edge'
    foreach($name in $names){
        $command=Get-Command $name -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if($command){return $command.Source}
    }
    $tried.Add("PATH: $($names -join ', ')")
    $paths=if($IsWindows){
        @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe","${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe","$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe","${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe","$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
    }elseif($IsMacOS){
        @('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome','/Applications/Chromium.app/Contents/MacOS/Chromium','/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge')
    }else{
        @('/usr/bin/google-chrome','/usr/bin/chromium','/usr/bin/chromium-browser','/snap/bin/chromium','/usr/bin/microsoft-edge')
    }
    foreach($path in $paths){if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){return $path}}
    $tried.AddRange([string[]]$paths)
    throw "Chrome, Chromium, or Microsoft Edge is required to render the PDF. Install one, or set CHROME_PATH to its executable. Tried: $($tried -join '; ')"
}

Export-ModuleMember -Function ConvertTo-RffRenderData,New-RffCsvRecords,Publish-RffArtifacts,Invoke-RffArtifactBuild,Find-RffBrowser
