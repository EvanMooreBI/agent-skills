[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$skillRoot=Split-Path $PSScriptRoot -Parent
$skillName=Split-Path $skillRoot -Leaf
$provenance=Get-Content -LiteralPath (Join-Path $skillRoot 'references/render-provenance.json') -Raw -Encoding utf8|ConvertFrom-Json
# Text hashes use LF line endings so that Windows and Unix checkouts agree.
function Get-ProtectedHash([string]$Path){
    $bytes=[IO.File]::ReadAllBytes($Path)
    if([IO.Path]::GetExtension($Path) -in '.json','.csv','.md','.js','.ps1','.psm1','.py','.gs','.html'){
        $bytes=[Text.Encoding]::UTF8.GetBytes([Text.Encoding]::UTF8.GetString($bytes).Replace("`r`n","`n"))
    }
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}
$passed=0
foreach($entry in $provenance.protectedReferences.PSObject.Properties){
    if((Get-ProtectedHash (Join-Path $skillRoot $entry.Name)) -ne $entry.Value){throw "Protected reference changed: $($entry.Name)"}
    $passed++
}
# The source workbooks are an optional local resource. Check them only where they exist.
$roots=@()
if($env:AGENT_SKILLS_LOCAL){$roots+=Join-Path $env:AGENT_SKILLS_LOCAL $skillName}
$roots+=Join-Path ([Environment]::GetFolderPath('UserProfile')) ".agent-skills/local/$skillName"
foreach($entry in $provenance.localReferences.PSObject.Properties){
    $found=@($roots|ForEach-Object{Join-Path $_ $entry.Name}|Where-Object{Test-Path -LiteralPath $_ -PathType Leaf})|Select-Object -First 1
    if(-not $found){"TEST|local-reference|SKIP|$($entry.Name) not found locally";continue}
    if((Get-ProtectedHash $found) -ne $entry.Value){throw "Local reference changed: $found"}
    $passed++
}
$engine=[IO.File]::ReadAllText((Join-Path $skillRoot 'scripts/RegimentalFireAndFury.psm1')).Replace("`r`n","`n")
$prefix=$engine.Substring(0,$engine.IndexOf('function Get-UnitEffectiveness'))
$bytes=[Text.Encoding]::UTF8.GetBytes($prefix)
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
if($hash -cne $provenance.generationPrefixLfSha256){throw 'Original generation and naming code changed.'}
$passed++
$brigade=Join-Path (Split-Path $skillRoot -Parent) 'brigade-fire-and-fury-random-army-generation'
if(Test-Path -LiteralPath $brigade){
    foreach($entry in $provenance.brigadeTechnicalReference.PSObject.Properties){
        if((Get-ProtectedHash (Join-Path $brigade $entry.Name)) -ne $entry.Value){throw "Brigade reference changed since this port: $($entry.Name)"}
        $passed++
    }
}
"TEST-SUMMARY|PASS|$passed protected source checks"
