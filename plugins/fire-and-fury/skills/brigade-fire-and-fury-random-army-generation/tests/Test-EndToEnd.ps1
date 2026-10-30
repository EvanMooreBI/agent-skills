[CmdletBinding()]
# The default tables are invented test data. Pass -TablesPath to use your own generator tables.
param([string]$TablesPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skillRoot=Split-Path $PSScriptRoot -Parent
if(-not $TablesPath){$TablesPath=Join-Path $PSScriptRoot 'fixtures/synthetic-tables'}
$temp=Join-Path ([IO.Path]::GetTempPath()) ('bff-e2e-'+[guid]::NewGuid().ToString('N'))
try{
    [IO.Directory]::CreateDirectory($temp)|Out-Null
    & pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -OutputDirectory $temp -TablesPath $TablesPath
    if($LASTEXITCODE -ne 0){throw 'Public generator failed.'}
    $pdf=@(Get-ChildItem $temp -Filter '*.pdf');$csv=@(Get-ChildItem $temp -Filter '*.csv')
    if($pdf.Count -ne 1 -or $csv.Count -ne 1){throw "Expected one PDF and one CSV; found $($pdf.Count) and $($csv.Count)."}
    $rows=@(Import-Csv $csv[0].FullName)
    if($rows.Count -lt 50){throw 'Generation log is unexpectedly short.'}
    if(-not($rows|Where-Object{$_.RecordType -eq 'Validation' -and $_.Step -eq 'PDF'})){throw 'PDF validation record is missing.'}
    if(-not($rows|Where-Object{$_.RecordType -eq 'BalanceDecision'})){throw 'Balance decision is missing.'}
    $collisionFailed=$false
    try{& pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -OutputDirectory $temp -TablesPath $TablesPath;if($LASTEXITCODE -ne 0){$collisionFailed=$true}}catch{$collisionFailed=$true}
    if(-not $collisionFailed){throw 'Existing output collision was not rejected.'}
    if(@(Get-ChildItem $temp -Filter '*.pdf').Count -ne 1 -or @(Get-ChildItem $temp -Filter '*.csv').Count -ne 1){throw 'Collision handling changed published files.'}
    "TEST|end-to-end|PASS|pdf=$($pdf[0].Length) logRows=$($rows.Count)"

    $noTables=Join-Path $temp 'no-tables';$noTablesOutput=Join-Path $temp 'no-tables-output'
    [void][IO.Directory]::CreateDirectory($noTables);[void][IO.Directory]::CreateDirectory($noTablesOutput)
    $message=& pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -OutputDirectory $noTablesOutput -TablesPath $noTables 2>&1
    if($LASTEXITCODE -eq 0){throw 'A random run without generator tables did not fail.'}
    if(($message -join ' ') -notmatch "Set up your rulebook tables"){throw "Missing-tables message does not point to setup: $($message -join ' ')"}
    if(@(Get-ChildItem -LiteralPath $noTablesOutput).Count -ne 0){throw 'A failed random run published files.'}
    "TEST|random-without-tables-stops-with-setup-message|PASS"

    $fixedOutput=Join-Path $temp 'fixed-output';[IO.Directory]::CreateDirectory($fixedOutput)|Out-Null
    & pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -OutputDirectory $fixedOutput
    if($LASTEXITCODE -ne 0){throw 'Fixed-roster public generator failed.'}
    $delivery=@(Get-ChildItem -LiteralPath $fixedOutput -Directory)
    if($delivery.Count -ne 1){throw "Expected one fixed-roster delivery folder; found $($delivery.Count)."}
    $fixedPdf=@(Get-ChildItem -LiteralPath $delivery[0].FullName -Filter '*.pdf');$fixedManifest=@(Get-ChildItem -LiteralPath $delivery[0].FullName -Filter '*.json')
    if($fixedPdf.Count -ne 1 -or $fixedManifest.Count -ne 1){throw 'Fixed-roster delivery is missing its PDF or normalized manifest.'}
    $manifest=Get-Content -LiteralPath $fixedManifest[0].FullName -Raw|ConvertFrom-Json
    if(@($manifest.brigades).Count -ne 22 -or @($manifest.standaloneArtillery).Count -ne 9 -or $manifest.divisions[0].name -ne '1st Division'){throw 'Fixed-roster manifest content is invalid.'}
    "TEST|fixed-end-to-end|PASS|pdf=$($fixedPdf[0].Length) brigades=$(@($manifest.brigades).Count) standalone=$(@($manifest.standaloneArtillery).Count)"

    $leaderRequest=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -Raw|ConvertFrom-Json
    foreach($collection in 'corps','divisions','brigades'){
        $leaderRequest.$collection[0]|Add-Member -NotePropertyName exceptionalLeader -NotePropertyValue $true
    }
    $leaderRequestPath=Join-Path $temp 'exceptional-request.json'
    [IO.File]::WriteAllText($leaderRequestPath,($leaderRequest|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
    $leaderOutput=Join-Path $temp 'exceptional-output';[IO.Directory]::CreateDirectory($leaderOutput)|Out-Null
    & pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath $leaderRequestPath -OutputDirectory $leaderOutput
    if($LASTEXITCODE -ne 0){throw 'Exceptional fixed-roster public generator failed.'}
    $leaderDelivery=@(Get-ChildItem -LiteralPath $leaderOutput -Directory)
    if($leaderDelivery.Count -ne 1){throw 'Expected one exceptional fixed-roster delivery folder.'}
    $leaderManifests=@(Get-ChildItem -LiteralPath $leaderDelivery[0].FullName -Filter '*.json')
    if($leaderManifests.Count -ne 1){throw 'Expected one exceptional fixed-roster manifest.'}
    $leaderManifest=Get-Content -LiteralPath $leaderManifests[0].FullName -Raw|ConvertFrom-Json
    foreach($collection in 'corps','divisions','brigades'){
        if(-not $leaderManifest.$collection[0].exceptionalLeader -or $leaderManifest.$collection[1].exceptionalLeader){throw "Exceptional leader values changed in $collection."}
    }
    "TEST|exceptional-fixed-end-to-end|PASS|corps=True divisions=True brigades=True omitted=False"
    foreach($case in 'unassigned-only','standalone-only','mixed-unassigned') {
        $caseOutput=Join-Path $temp $case;[void][IO.Directory]::CreateDirectory($caseOutput)
        & pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath (Join-Path $PSScriptRoot "fixtures/request-$case.json") -OutputDirectory $caseOutput
        if($LASTEXITCODE -ne 0){throw "Public $case generation failed"}
        $casePdf=@(Get-ChildItem -LiteralPath $caseOutput -Recurse -Filter '*.pdf');$caseJson=@(Get-ChildItem -LiteralPath $caseOutput -Recurse -Filter '*.json')
        if($casePdf.Count -ne 1 -or $caseJson.Count -ne 1){throw "Incomplete $case delivery"}
        $normalized=Get-Content -LiteralPath $caseJson[0].FullName -Raw|ConvertFrom-Json
        if($case -eq 'standalone-only') {if(@($normalized.standaloneArtillery).Count -ne 2){throw 'Standalone-only records changed'}}
        elseif(@($normalized.unassignedBrigades).Count -lt 4){throw 'Unassigned brigade records missing'}
        "TEST|public-$case|PASS"
    }
}finally{if(Test-Path $temp){Remove-Item $temp -Recurse -Force}}
