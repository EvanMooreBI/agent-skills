[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $OutputDirectory){throw "Test directory already exists: $OutputDirectory"}
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$skillRoot=Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $skillRoot 'scripts/RffArtifacts.psm1') -Force
$generator=Join-Path $skillRoot 'scripts/Generate-RegimentalFireAndFuryLabels.ps1'
$request=Join-Path $PSScriptRoot 'fixtures/text-fitting.json'
$passed=0
function Assert-Test([bool]$Condition,[string]$Name){if(-not $Condition){throw "FAIL $Name"};$script:passed++;"TEST|$Name|PASS"}
$public=Join-Path $OutputDirectory 'public';[void][IO.Directory]::CreateDirectory($public)
& pwsh -NoProfile -File $generator -RequestPath $request -OutputDirectory $public | Out-Host
Assert-Test ($LASTEXITCODE -eq 0) 'public-production-entrypoint'
$files=@(Get-ChildItem -LiteralPath $public -File)
Assert-Test ($files.Count -eq 2 -and @($files|Where-Object Extension -eq '.pdf').Count -eq 1 -and @($files|Where-Object Extension -eq '.csv').Count -eq 1) 'exactly-one-combined-pdf-and-csv'
$hashes=@($files|Get-FileHash -Algorithm SHA256)
$collision=@(& pwsh -NoProfile -File $generator -RequestPath $request -OutputDirectory $public 2>&1)
Assert-Test ($LASTEXITCODE -ne 0 -and ($collision -join ' ') -match 'Refusing to overwrite') 'collision-fails'
Assert-Test (($hashes.Hash -join ',') -eq ((@($files|Get-FileHash -Algorithm SHA256)).Hash -join ',')) 'collision-preserves-files'
$transaction=Join-Path $OutputDirectory 'transaction';[void][IO.Directory]::CreateDirectory($transaction)
$pdf=Join-Path $transaction 'source.pdf';$csv=Join-Path $transaction 'source.csv'
$pdfTarget=Join-Path $transaction 'target.pdf';$csvTarget=Join-Path $transaction 'target.csv'
[IO.File]::WriteAllText($pdf,'pdf');[IO.File]::WriteAllText($csv,'csv')
$race={ [IO.File]::WriteAllText($csvTarget,'racing file') }.GetNewClosure()
$failed=$false
try{Publish-RffArtifacts $pdf $pdfTarget $csv $csvTarget -BeforeCsvPublication $race}catch{$failed=$true}
Assert-Test $failed 'second-publication-failure-reported'
Assert-Test (-not(Test-Path -LiteralPath $pdfTarget)) 'second-publication-rolls-back-own-pdf'
Assert-Test ((Get-Content -LiteralPath $csvTarget -Raw) -eq 'racing file') 'racing-file-preserved'
$replacement=Join-Path $OutputDirectory 'replacement';[void][IO.Directory]::CreateDirectory($replacement)
$pdf=Join-Path $replacement 'source.pdf';$csv=Join-Path $replacement 'source.csv'
$pdfTarget=Join-Path $replacement 'target.pdf';$csvTarget=Join-Path $replacement 'target.csv'
[IO.File]::WriteAllText($pdf,'our pdf');[IO.File]::WriteAllText($csv,'our csv')
$race={ [IO.File]::WriteAllText($pdfTarget,'replacement pdf');[IO.File]::WriteAllText($csvTarget,'replacement csv') }.GetNewClosure()
$failed=$false
try{Publish-RffArtifacts $pdf $pdfTarget $csv $csvTarget -BeforeCsvPublication $race}catch{$failed=$true}
Assert-Test ($failed -and (Get-Content -LiteralPath $pdfTarget -Raw) -eq 'replacement pdf') 'rollback-preserves-replaced-pdf'
Assert-Test ((Get-Content -LiteralPath $csvTarget -Raw) -eq 'replacement csv') 'rollback-preserves-replaced-csv'
$withoutTools=Join-Path $OutputDirectory 'without-tools';[void][IO.Directory]::CreateDirectory($withoutTools)
$pwsh=(Get-Command pwsh).Source;$originalPath=$env:PATH
try {
    $env:PATH=Join-Path $OutputDirectory 'nonexistent-path'
    $missing=@(& $pwsh -NoProfile -File $generator -RequestPath $request -OutputDirectory $withoutTools 2>&1)
    $missingExit=$LASTEXITCODE
} finally {$env:PATH=$originalPath}
Assert-Test ($missingExit -ne 0) 'missing-dependency-fails'
Assert-Test (@(Get-ChildItem -LiteralPath $withoutTools -File).Count -eq 0) 'missing-dependency-publishes-nothing'
$command=Get-Command $generator
Assert-Test (-not($command.Parameters.ContainsKey('TestMode') -or $command.Parameters.ContainsKey('TestRollSequence') -or $command.Parameters.ContainsKey('Seed'))) 'no-public-test-controls'
"TEST-SUMMARY|PASS|$passed end-to-end assertions"
