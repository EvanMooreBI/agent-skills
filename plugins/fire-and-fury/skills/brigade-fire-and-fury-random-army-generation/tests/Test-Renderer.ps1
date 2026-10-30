[CmdletBinding()]
# SourceRoot is the maintained Google Sheets apps-script folder. Without it, only the recorded hashes are checked.
param([string]$SourceRoot,[string]$TablesPath)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skillRoot=Split-Path $PSScriptRoot -Parent
$sourceRoot = if ($SourceRoot) { (Resolve-Path -LiteralPath $SourceRoot -ErrorAction Stop).Path } else { $null }
if (-not $TablesPath) { $TablesPath = Join-Path $PSScriptRoot 'fixtures/synthetic-tables' }

function Assert-True([bool]$Condition,[string]$Name){if(-not $Condition){throw "Assertion failed: $Name"}}
function Assert-Near([double]$Actual,[double]$Expected,[double]$Tolerance,[string]$Name){if([math]::Abs($Actual-$Expected) -gt $Tolerance){throw "Assertion failed: $Name actual=$Actual expected=$Expected tolerance=$Tolerance"}}
function Invoke-LocalRenderer([object]$RenderData,[string]$Prefix){
    $temp=Join-Path ([IO.Path]::GetTempPath()) ($Prefix+'-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temp)|Out-Null
    $input=Join-Path $temp 'input.json';$html=Join-Path $temp 'out.html';$manifest=Join-Path $temp 'manifest.json'
    [IO.File]::WriteAllText($input,($RenderData|ConvertTo-Json -Depth 20))
    & node (Join-Path $skillRoot 'scripts/render-labels.js') $input $html $manifest | Out-Host
    if($LASTEXITCODE -ne 0){throw 'Node renderer failed.'}
    [pscustomobject]@{Directory=$temp;Html=$html;Manifest=$manifest}
}
function Get-FirstLabelLayout([string]$Content,[string]$Role,[int]$RowCount){
    $label=[regex]::Match($Content,"(?s)<g class=`"label`" data-label-role=`"$([regex]::Escape($Role))`" data-text-row-count=`"$RowCount`"[^>]*>(?<body>.*?)</g>")
    Assert-True $label.Success "layout-$Role-$RowCount-row-label-exists"
    $top=[double]([regex]::Match($label.Groups['body'].Value,'<rect x="[^"]+" y="(?<y>[^"]+)"').Groups['y'].Value)
    $baselines=@([regex]::Matches($label.Groups['body'].Value,'<text data-text-row="[^"]+" x="[^"]+" y="(?<y>[^"]+)"')|ForEach-Object{[double]$_.Groups['y'].Value})
    Assert-True ($baselines.Count -eq $RowCount) "layout-$Role-$RowCount-row-count"
    [pscustomobject]@{Top=$top;Baselines=$baselines}
}
function Get-ExpectedFirstBaseline([int]$RowCount){
    $height=25*72/25.4
    $divider=.28*$height
    $lowerBand=$height-$divider
    $padded=$lowerBand-5-5
    $usable=[math]::Min($lowerBand*.9,$padded)
    $bandTop=$divider+5+($padded-$usable)/2
    $textBlock=9+(($RowCount-1)*14)
    $bandTop+(($usable-$textBlock)/2)+(9*.75)
}

function Get-LfHash([string]$Path){
    $text=[IO.File]::ReadAllText($Path).Replace("`r`n","`n")
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))
}
$provenance=Get-Content -LiteralPath (Join-Path $skillRoot 'references/source-provenance.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($name in 'Code.gs','LabelPdf.html'){
    $bundled=(Get-FileHash -Algorithm SHA256 (Join-Path $skillRoot "assets/$name")).Hash
    $recorded=@($provenance.labelRenderer.files|Where-Object name -eq $name)
    Assert-True ($recorded.Count -eq 1 -and $bundled -eq $recorded[0].sha256) "bundled-original-bytes-$name"
    if (-not $sourceRoot) { "TEST|renderer-parity-$name|SKIP|no -SourceRoot; originalSha256=$bundled"; continue }
    $canonicalBundled=Get-LfHash (Join-Path $skillRoot "assets/$name")
    $canonicalSource=Get-LfHash (Join-Path $sourceRoot $name)
    Assert-True ($canonicalBundled -eq $canonicalSource) "renderer-parity-$name"
    "TEST|renderer-parity-$name|PASS|originalSha256=$bundled canonicalLfSha256=$canonicalSource"
}

Import-Module (Join-Path $skillRoot 'scripts/BrigadeFireAndFury.psm1') -Force
Set-BffTablesPath $TablesPath
$request=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-mid-war.json') -Raw|ConvertFrom-Json
$model=New-BffArmy $request $skillRoot -TestMode -TestRollSequence (1..1000|ForEach-Object{(($_-1)%10)+1})
$render=Invoke-LocalRenderer $model.RenderData 'bff-render-test'
try{
    $data=Get-Content $render.Manifest -Raw|ConvertFrom-Json
    $content=Get-Content $render.Html -Raw
    Assert-True ($data.pageCount -ge 2) 'random-page-count'
    Assert-True ($data.rendererMode -eq 'local-24mm-by-25mm') 'random-renderer-mode'
    Assert-True ($data.textFittingMode -eq 'browser-measured-shrink-only') 'random-text-fitting-mode'
    Assert-Near $data.labelWidthPt (24*72/25.4) 0.001 'random-label-width'
    Assert-Near $data.labelHeightPt (25*72/25.4) 0.001 'random-label-height'
    Assert-True ($data.labelWidthMm -eq 24 -and $data.labelHeightMm -eq 25 -and $data.labelCount -gt 0) 'random-manifest-geometry'
    Assert-Near $data.textRowBaselineGapPt 14 0.001 'random-text-row-baseline-gap'
    Assert-Near $data.lowerTextTopPaddingPt 5 0.001 'random-lower-text-top-padding'
    Assert-Near $data.lowerTextBottomPaddingPt 5 0.001 'random-lower-text-bottom-padding'
    Assert-Near $data.lowerTextUsageLimit .9 0.001 'random-lower-text-usage-limit'
    Assert-True ($data.lowerTextUsableHeightPt -le (($data.labelHeightPt-$data.dividerYPt)*$data.lowerTextUsageLimit)+.001) 'random-lower-text-usage-cap'
    $brigadeLayout=Get-FirstLabelLayout $content 'brigade' 3
    Assert-Near ($brigadeLayout.Baselines[1]-$brigadeLayout.Baselines[0]) 14 0.001 'random-three-row-first-gap'
    Assert-Near ($brigadeLayout.Baselines[2]-$brigadeLayout.Baselines[1]) 14 0.001 'random-three-row-second-gap'
    Assert-Near ($brigadeLayout.Baselines[0]-$brigadeLayout.Top) (Get-ExpectedFirstBaseline 3) 0.001 'random-three-row-centered'
    Assert-True ($content -match 'USA - Eastern - Mid War' -and $content -match 'CSA - Eastern - Mid War' -and $content -match '>Dismounted ') 'random-rendered-content'
    "TEST|renderer-output|PASS|pages=$($data.pageCount) labels=$($data.labelCount)"
}finally{if(Test-Path $render.Directory){Remove-Item $render.Directory -Recurse -Force}}

$fixedRequest=Get-Content (Join-Path $PSScriptRoot 'fixtures/request-fixed-historical.json') -Raw|ConvertFrom-Json
$fixedModel=New-BffFixedRoster $fixedRequest $skillRoot
$render=Invoke-LocalRenderer $fixedModel.RenderData 'bff-fixed-render-test'
try{
    $data=Get-Content $render.Manifest -Raw|ConvertFrom-Json
    $content=Get-Content $render.Html -Raw
    $usaStandalone=$content.IndexOf('Unassigned units')
    $csaHeader=$content.IndexOf('CSA - Eastern - Mid War')
    Assert-True ($data.pageCount -eq 2 -and $data.labelCount -eq 52 -and $data.standaloneArtilleryCount -eq 9) 'fixed-manifest-counts'
    Assert-True ($content -match '>K/1st NY</text>' -and $content -notmatch 'Bailey' -and $content -match 'Reese \(AL\)') 'fixed-artillery-content'
    Assert-True ($usaStandalone -ge 0 -and $csaHeader -gt $usaStandalone) 'fixed-side-order'
    Assert-True ([regex]::Matches($content,'data-corps-key="USA--usa-xii"').Count -eq 1) 'fixed-xii-one-corps-label'
    Assert-True ([regex]::Matches($content,'data-corps-key="USA--usa-xi"').Count -eq 1) 'fixed-xi-one-corps-label'
    Assert-True ([regex]::Matches($content,'data-corps-key="CSA--csa-second"').Count -eq 1) 'fixed-csa-one-corps-label'
    Assert-True ([regex]::Matches($content,'data-division-key=').Count -eq 7) 'fixed-one-division-label-per-division'
    Assert-True ($content -match '<text[^>]+data-min-font-size="7"[^>]*>Schimmelfennig</text>') 'fixed-long-name-allows-browser-fitting'
    $corpsLayout=Get-FirstLabelLayout $content 'corps' 1
    Assert-Near ($corpsLayout.Baselines[0]-$corpsLayout.Top) (Get-ExpectedFirstBaseline 1) 0.001 'fixed-one-row-corps-centered'
    $standalonePage=$content
    Assert-True ($content -notmatch 'data-page-kind="standalone-artillery"' -and $content -match 'Unassigned units') 'fixed-connected-unassigned-group'
    Assert-True ($standalonePage.Length -gt 0) 'fixed-standalone-page-exists'
    $standaloneLayout=Get-FirstLabelLayout $standalonePage 'artillery' 2
    Assert-Near ($standaloneLayout.Baselines[1]-$standaloneLayout.Baselines[0]) 14 0.001 'fixed-two-row-standalone-gap'
    Assert-Near ($standaloneLayout.Baselines[0]-$standaloneLayout.Top) (Get-ExpectedFirstBaseline 2) 0.001 'fixed-two-row-standalone-centered'
    "TEST|fixed-renderer-output|PASS|pages=$($data.pageCount) labels=$($data.labelCount)"
}finally{if(Test-Path $render.Directory){Remove-Item $render.Directory -Recurse -Force}}

$leaderRequest=$fixedRequest|ConvertTo-Json -Depth 20|ConvertFrom-Json
foreach($collection in 'corps','divisions','brigades'){
    $leaderRequest.$collection[0]|Add-Member -NotePropertyName exceptionalLeader -NotePropertyValue $true
}
$leaderModel=New-BffFixedRoster $leaderRequest $skillRoot
$render=Invoke-LocalRenderer $leaderModel.RenderData 'bff-exceptional-render-test'
try{
    $data=Get-Content $render.Manifest -Raw|ConvertFrom-Json
    $content=Get-Content $render.Html -Raw
    Assert-True ($data.labelCount -eq 52 -and $data.standaloneArtilleryCount -eq 9) 'exceptional-label-counts-unchanged'
    Assert-True ($content -match 'data-label-role="corps" data-text-row-count="2"') 'exceptional-corps-has-marker-row'
    Assert-True ($content -match '>E</text>' -and $content -match '>Williams E</text>' -and $content -match '>Knipe E</text>') 'exceptional-markers-all-command-levels'
    Assert-True ($content -notmatch '>Howard E</text>' -and $content -notmatch '>Geary E</text>' -and $content -notmatch '>Ross E</text>') 'omitted-exceptional-flags-render-without-markers'
    "TEST|exceptional-renderer-output|PASS|pages=$($data.pageCount) labels=$($data.labelCount)"
}finally{if(Test-Path $render.Directory){Remove-Item $render.Directory -Recurse -Force}}

$continuation=Get-Content (Join-Path $PSScriptRoot 'fixtures/render-continuation.json') -Raw|ConvertFrom-Json
$render=Invoke-LocalRenderer $continuation 'bff-continuation-render-test'
try{
    $content=Get-Content $render.Html -Raw
    $usaPages=@([regex]::Matches($content,'(?s)<svg[^>]*>.*?</svg>')|ForEach-Object{$_.Value}|Where-Object{$_ -match 'USA - Eastern - Mid War'})
    Assert-True ($usaPages.Count -eq 2) 'continuation-usa-page-count'
    Assert-True (@($usaPages|Where-Object{[regex]::Matches($_,'data-corps-key="USA--USA Test Corps"').Count -eq 1}).Count -eq 2) 'continuation-one-corps-label-per-page'
    "TEST|renderer-continuation|PASS|usaPages=$($usaPages.Count)"
}finally{if(Test-Path $render.Directory){Remove-Item $render.Directory -Recurse -Force}}
