Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('bff-text-fitting-' + [guid]::NewGuid().ToString('N'))
try {
    [void][IO.Directory]::CreateDirectory($temp)
    $request = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $request.divisions[0].commander = 'Ricketts'
    $request.divisions[1].commander = 'Hatch'
    $request.brigades[0].name = 'iiiiiiiiiiii'
    $request.brigades[1].name = 'WWWWWWWWWWWW'
    $requestPath = Join-Path $temp 'request.json'
    [IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    & pwsh -NoProfile -File (Join-Path $skillRoot 'scripts/Generate-BrigadeFireAndFuryLabels.ps1') -RequestPath $requestPath -OutputDirectory $temp
    if ($LASTEXITCODE -ne 0) { throw 'Text-fitting fixture generation failed.' }
    $pdf = @(Get-ChildItem -LiteralPath $temp -Recurse -File -Filter '*.pdf')
    if ($pdf.Count -ne 1) { throw 'Expected one text-fitting fixture PDF.' }
    & python (Join-Path $PSScriptRoot 'verify_text_fitting.py') $pdf[0].FullName
    if ($LASTEXITCODE -ne 0) { throw 'PDF text-fitting regression failed.' }
} finally {
    if (Test-Path -LiteralPath $temp) {
        $resolved = (Resolve-Path -LiteralPath $temp).Path
        if ($resolved -ne $temp -or -not $resolved.StartsWith([IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected text-fitting test cleanup path.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
