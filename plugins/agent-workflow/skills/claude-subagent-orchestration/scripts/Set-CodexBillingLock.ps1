#Requires -Version 5.1
<#
.SYNOPSIS
Locks every Codex client on this computer to one way of paying.

.DESCRIPTION
Writes %ProgramData%\OpenAI\Codex\requirements.toml with
allowed_login_methods = ["chatgpt"] or ["api"]. Codex reads this machine
requirements file before it loads credentials.

- chatgpt: Codex ignores CODEX_API_KEY and treats an API-key sign-in as signed
  out, so no Codex run can use API billing.
- api: Codex accepts only an API key and treats a ChatGPT sign-in as signed
  out, so every Codex run bills the OpenAI API per token.

The script also makes the OpenAI and OpenAI\Codex folders and the file
writable only by Administrators and SYSTEM. Users, and any agent running
without elevation, can read the file but cannot change or delete it.

Without -Check, run this script from an elevated PowerShell.

.PARAMETER Mode
chatgpt (the default) or api. The claude-subagent-orchestration wrapper,
codex_guard.py, bills Claude's Codex runs to the API only when this file locks
Codex to api.

.PARAMETER Check
Report which mode the file locks and whether its permissions are correct.
Changes nothing and needs no elevation. With -Mode, also require that mode.
Exits 0 when everything is correct, otherwise 1.

.EXAMPLE
pwsh -File .\Set-CodexBillingLock.ps1 -Check

.EXAMPLE
pwsh -File .\Set-CodexBillingLock.ps1 -Mode chatgpt -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('chatgpt', 'api')]
    [string]$Mode = 'chatgpt',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
# Read here: inside a function, $PSBoundParameters holds that function's own parameters.
$modeGiven = $PSBoundParameters.ContainsKey('Mode')

$root = Join-Path $env:ProgramData 'OpenAI'
$folder = Join-Path $root 'Codex'
$file = Join-Path $folder 'requirements.toml'
$modeNames = @{ chatgpt = 'ChatGPT sign-in'; api = 'API-key sign-in' }
$expected = "allowed_login_methods = [""$Mode""]`n"
# A file this script wrote for either mode may be rewritten; any other file is merged by hand.
$ownContent = @('chatgpt', 'api') | ForEach-Object { "allowed_login_methods = [""$_""]`n" }

# Well-known SIDs, so the script works in any Windows display language.
$systemSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18'
$adminsSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'
$usersSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-545'
$trustedSids = @($systemSid.Value, $adminsSid.Value)

$writeRights = [System.Security.AccessControl.FileSystemRights]'WriteData, AppendData, WriteExtendedAttributes, WriteAttributes, Delete, DeleteSubdirectoriesAndFiles, ChangePermissions, TakeOwnership'

function Get-PathProblem {
    # A non-administrator can create folders in ProgramData, so a path could be
    # a junction to another folder, or a folder someone else created first.
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        return "$Path is a junction or link"
    }
    $acl = Get-Acl -LiteralPath $Path
    $owner = (New-Object System.Security.Principal.NTAccount $acl.Owner).Translate([System.Security.Principal.SecurityIdentifier]).Value
    if ($trustedSids -notcontains $owner) {
        return "$Path is owned by $($acl.Owner), not Administrators or SYSTEM"
    }
    return $null
}

function Get-ContentProblem {
    # Other requirements may stay in the file. The login restriction must be a
    # top-level key, set once, to exactly ["<mode>"]. TOML keys are
    # case-sensitive, so the matches are too.
    param([string]$Text, [string]$For = $Mode)
    $lines = @($Text -split "`r?`n")
    $settings = @(for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -cmatch '^\s*allowed_login_methods\s*=') { $i }
    })
    if ($settings.Count -ne 1) {
        return "allowed_login_methods must be set exactly once, not $($settings.Count) times"
    }
    $line = $lines[$settings[0]]
    # TOML allows either quote style. A value spread over several lines is refused.
    if ($line -cnotmatch ('^\s*allowed_login_methods\s*=\s*\[\s*(?:"' + $For + '"|''' + $For + ''')\s*,?\s*\]\s*(#.*)?$')) {
        return "allowed_login_methods must be [""$For""], found: $($line.Trim())"
    }
    for ($i = 0; $i -lt $settings[0]; $i++) {
        if ($lines[$i] -match '^\s*\[') {
            return 'allowed_login_methods must come before the first [table] header'
        }
    }
    return $null
}

function Get-Problems {
    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($path in @($root, $folder, $file)) {
        if (Test-Path -LiteralPath $path) {
            $problem = Get-PathProblem -Path $path
            if ($problem) { $problems.Add($problem) }
        }
    }
    if ($problems.Count -ne 0) { return $problems }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $problems.Add("missing: $file")
        return $problems
    }
    $text = [System.IO.File]::ReadAllText($file)
    $locked = @('chatgpt', 'api') | Where-Object { -not (Get-ContentProblem -Text $text -For $_) }
    if ($modeGiven -or -not $locked) {
        $contentProblem = Get-ContentProblem -Text $text
        if ($contentProblem) { $problems.Add("${file}: $contentProblem") }
    }
    $extra = @(Get-ChildItem -LiteralPath $folder -Force | Where-Object { $_.Name -ne 'requirements.toml' })
    foreach ($item in $extra) { $problems.Add("unexpected item in ${folder}: $($item.Name)") }
    foreach ($path in @($root, $folder, $file)) {
        $acl = Get-Acl -LiteralPath $path
        foreach ($rule in $acl.Access) {
            if ($rule.AccessControlType -ne 'Allow') { continue }
            $sid = $rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
            if ($trustedSids -contains $sid) { continue }
            # 0x50000000 is GENERIC_ALL or GENERIC_WRITE, which Get-Acl shows only as a number.
            if ((([long]$rule.FileSystemRights) -band ([long]$writeRights -bor 0x50000000)) -ne 0) {
                $problems.Add("$($rule.IdentityReference) can write to $path ($($rule.FileSystemRights))")
            }
        }
    }
    return $problems
}

function Set-LockedAcl {
    param([string]$Path, [bool]$IsFolder)
    $acl = Get-Acl -LiteralPath $Path
    $acl.SetOwner($adminsSid)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
    if ($IsFolder) {
        $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    } else {
        $inherit = [System.Security.AccessControl.InheritanceFlags]::None
    }
    $none = [System.Security.AccessControl.PropagationFlags]::None
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule $systemSid, 'FullControl', $inherit, $none, 'Allow'))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule $adminsSid, 'FullControl', $inherit, $none, 'Allow'))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule $usersSid, 'ReadAndExecute', $inherit, $none, 'Allow'))
    Set-Acl -LiteralPath $Path -AclObject $acl
}

function Get-LockedMode {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $null }
    $text = [System.IO.File]::ReadAllText($file)
    return @('chatgpt', 'api') | Where-Object { -not (Get-ContentProblem -Text $text -For $_) } | Select-Object -First 1
}

if ($Check) {
    $problems = @(Get-Problems)
    if ($problems.Count -eq 0) {
        $locked = Get-LockedMode
        Write-Output "OK: $file allows only $($modeNames[$locked]) ($locked), and only Administrators and SYSTEM can change it."
        exit 0
    }
    $problems | ForEach-Object { Write-Output "PROBLEM: $_" }
    exit 1
}

$principal = New-Object System.Security.Principal.WindowsPrincipal ([System.Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $WhatIfPreference -and -not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run this script from an elevated PowerShell (Run as Administrator), or use -Check.'
}

function Assert-SafePath {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $problem = Get-PathProblem -Path $Path
        if ($problem) {
            Write-Error "$problem. Inspect it, delete it if you did not create it, then run this script again."
        }
    }
}

foreach ($path in @($root, $folder, $file)) { Assert-SafePath -Path $path }

$keepContent = $false
if (Test-Path -LiteralPath $file -PathType Leaf) {
    $current = [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n")
    $contentProblem = Get-ContentProblem -Text $current
    if ($contentProblem -and $ownContent -notcontains $current) {
        Write-Error "$file already exists with other settings ($contentProblem). Add allowed_login_methods = [""$Mode""] near the top by hand, then run this script again."
    }
    $keepContent = -not $contentProblem
}

if ($PSCmdlet.ShouldProcess($file, "Write allowed_login_methods = [""$Mode""] and lock the permissions")) {
    # Lock each folder before creating the next one inside it. A folder that
    # already exists must be owned by Administrators or SYSTEM, which a user
    # cannot delete or replace. A missing folder is created with New-Item and
    # no existence check in between: New-Item fails if someone else created
    # the folder first.
    foreach ($path in @($root, $folder)) {
        if (Test-Path -LiteralPath $path) {
            Assert-SafePath -Path $path
        } else {
            New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
            if ((Get-Item -LiteralPath $path -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Error "$path is a junction or link. Delete it, then run this script again."
            }
        }
        Set-LockedAcl -Path $path -IsFolder $true
        Assert-SafePath -Path $path
    }
    Assert-SafePath -Path $file
    if (-not $keepContent) {
        # UTF-8 without a byte order mark, which TOML parsers expect.
        [System.IO.File]::WriteAllText($file, $expected, (New-Object System.Text.UTF8Encoding $false))
    }
    Set-LockedAcl -Path $file -IsFolder $false

    $problems = @(Get-Problems)
    if ($problems.Count -ne 0) {
        $problems | ForEach-Object { Write-Output "PROBLEM: $_" }
        exit 1
    }
    Write-Output "Done: $file allows only $($modeNames[$Mode]). Run 'codex login status' in your own terminal, and sign in again if it does not show the matching method."
}
