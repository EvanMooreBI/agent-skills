[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RequestPath,
    [string]$OutputDirectory,
    # Folder that holds the generator tables. Defaults to the local resource folder.
    [string]$TablesPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path $PSScriptRoot -Parent
$requestPathFull = [System.IO.Path]::GetFullPath($RequestPath)
if (-not (Test-Path -LiteralPath $requestPathFull -PathType Leaf)) { throw "Request JSON not found: $requestPathFull" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads' }
$outputDirectoryFull = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not (Test-Path -LiteralPath $outputDirectoryFull -PathType Container)) { throw "Output directory not found: $outputDirectoryFull" }

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("bff-labels-" + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($temporaryDirectory)
try {
    Import-Module (Join-Path $PSScriptRoot 'BrigadeFireAndFury.psm1') -Force
    if ($TablesPath) { Set-BffTablesPath $TablesPath }
    $requestJson = Get-Content -LiteralPath $requestPathFull -Raw -Encoding UTF8
    $schemaPath = Join-Path $skillRoot 'references/request-schema.json'
    if (-not ($requestJson | Test-Json -SchemaFile $schemaPath)) { throw 'Request JSON does not match references/request-schema.json.' }
    $request = $requestJson | ConvertFrom-Json
    $isFixedRoster = $request.PSObject.Properties['mode'] -and [string]$request.mode -eq 'fixedRoster'
    if (-not $isFixedRoster) {
        $tableProblems = @(Test-BffTables -Path (Get-BffTablesPath) -SkillRoot $skillRoot)
        if ($tableProblems.Count) { throw "The generator tables at $(Get-BffTablesPath) have $($tableProblems.Count) problem(s). Run scripts/Test-BrigadeTables.ps1 for the list. First: $($tableProblems[0])" }
    }
    $model = if ($isFixedRoster) { New-BffFixedRoster -Request $request -SkillRoot $skillRoot } else { New-BffArmy -Request $request -SkillRoot $skillRoot }
    $baseName = if ($isFixedRoster) { "Brigade Fire and Fury Fixed Unit Labels $(Get-Date -Format 'yyyy-MM-dd-HHmmss')" } else { "Brigade Fire and Fury Unit Labels $(Get-Date -Format 'yyyy-MM-dd')" }
    $deliveryDirectory = if ($isFixedRoster) { Join-Path $outputDirectoryFull $baseName } else { $outputDirectoryFull }
    $supplementName = if ($isFixedRoster) { "$baseName - Normalized Roster.json" } else { "$baseName - Generation Log.csv" }
    $pdfTarget = Join-Path $deliveryDirectory "$baseName.pdf"
    $supplementTarget = Join-Path $deliveryDirectory $supplementName
    if ($isFixedRoster -and (Test-Path -LiteralPath $deliveryDirectory)) { throw "Refusing to overwrite existing output: $deliveryDirectory" }
    foreach ($target in $pdfTarget,$supplementTarget) { if (Test-Path -LiteralPath $target) { throw "Refusing to overwrite existing output: $target" } }

    $renderJson = Join-Path $temporaryDirectory 'render-data.json'
    $htmlPath = Join-Path $temporaryDirectory 'labels.html'
    $manifestPath = Join-Path $temporaryDirectory 'render-manifest.json'
    $pdfPath = Join-Path $temporaryDirectory "$baseName.pdf"
    $supplementPath = Join-Path $temporaryDirectory $supplementName
    $previewDirectory = Join-Path $temporaryDirectory 'previews'
    [System.IO.File]::WriteAllText($renderJson, ($model.RenderData | ConvertTo-Json -Depth 20), [System.Text.UTF8Encoding]::new($false))

    & node (Join-Path $PSScriptRoot 'render-labels.js') $renderJson $htmlPath $manifestPath
    if ($LASTEXITCODE -ne 0) { throw "Label HTML rendering failed with exit code $LASTEXITCODE." }
    $browser = Find-BffBrowser
    $profileDirectory = Join-Path $temporaryDirectory 'browser-profile'
    $htmlUri = ([uri]$htmlPath).AbsoluteUri
    $arguments = @(
        '--headless=new', '--disable-gpu', '--no-pdf-header-footer', '--disable-extensions',
        "--user-data-dir=`"$profileDirectory`"", "--print-to-pdf=`"$pdfPath`"", $htmlUri
    )
    $startOptions = @{ FilePath = $browser; ArgumentList = $arguments; Wait = $true; PassThru = $true }
    if ($IsWindows) { $startOptions.WindowStyle = 'Hidden' }
    $process = Start-Process @startOptions
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $pdfPath)) { throw "Browser PDF rendering failed with exit code $($process.ExitCode)." }

    $validationJson = & python (Join-Path $PSScriptRoot 'validate_pdf.py') $pdfPath $manifestPath $previewDirectory
    if ($LASTEXITCODE -ne 0) { throw "PDF validation failed with exit code $LASTEXITCODE." }
    $validationLine = @($validationJson | Where-Object { $_ -match '^\s*\{' }) | Select-Object -Last 1
    if (-not $validationLine) { throw "PDF validator did not return its JSON result: $($validationJson -join ' ')" }
    $validation = $validationLine | ConvertFrom-Json
    if ($isFixedRoster) {
        [System.IO.File]::WriteAllText($supplementPath, ($model.NormalizedRoster | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        $manifest = Get-Content -LiteralPath $supplementPath -Raw | ConvertFrom-Json
        $unassignedCount = if ($manifest.PSObject.Properties['unassignedBrigades']) { @($manifest.unassignedBrigades).Count } else { 0 }
        if (@($manifest.corps).Count -lt 1 -or (@($manifest.brigades).Count + @($manifest.artillery).Count + @($manifest.standaloneArtillery).Count + $unassignedCount) -lt 1) { throw 'Normalized roster manifest validation failed.' }
    } else {
        Add-BffLog -Log $model.RollLog -RecordType 'Validation' -Step 'PDF' -Result "Validated $($validation.pages) landscape Letter pages; $($validation.bytes) bytes" -SourceTable 'validate_pdf.py' -Notes 'All pages were rasterized for inspection.'
        Add-BffLog -Log $model.RollLog -RecordType 'Validation' -Step 'CSV' -Result "Validated $($model.RollLog.Count + 1) log records before export" -SourceTable 'Generate-BrigadeFireAndFuryLabels.ps1'
        $model.RollLog | Export-Csv -LiteralPath $supplementPath -NoTypeInformation -Encoding utf8
        $csvRows = @(Import-Csv -LiteralPath $supplementPath)
        $requiredHeaders = 'Sequence','RecordType','Step','Side','FormationId','UnitId','RawRoll','Modifiers','AdjustedRoll','Result','Substitution','SourceTable','Notes'
        $headers = @($csvRows[0].PSObject.Properties.Name)
        if ($csvRows.Count -ne $model.RollLog.Count -or ($requiredHeaders | Where-Object { $_ -notin $headers })) { throw 'CSV validation failed.' }
    }

    if ($isFixedRoster) { [void][System.IO.Directory]::CreateDirectory($deliveryDirectory) }
    Publish-BffArtifacts -PdfSource $pdfPath -PdfTarget $pdfTarget -CsvSource $supplementPath -CsvTarget $supplementTarget
    $result = [ordered]@{ PdfPath = (Resolve-Path -LiteralPath $pdfTarget).Path; Period = $model.Period; Theater = $model.Theater; PdfPages = $validation.pages }
    if ($isFixedRoster) { $result.NormalizedRosterPath = (Resolve-Path -LiteralPath $supplementTarget).Path; $result.Generation = 'Fixed roster; no rolls, substitutions, or balance adjustment applied' }
    else { $result.GenerationLogPath = (Resolve-Path -LiteralPath $supplementTarget).Path; $result.LogRecords = $model.RollLog.Count; $result.BalanceAdjustment = 'None; rules not yet approved' }
    [pscustomobject]$result | Format-List
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
