# Shared helpers for the lab scripts. Dot-source it: . "$PSScriptRoot/LabHelpers.ps1"

# Version 1 catches typos in variable names. Later versions also throw on
# $null.Property and @().Property, which Graph SDK results hit constantly
# (for example a group with no members yet).
Set-StrictMode -Version 1.0

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
# Anything written here may contain secrets or tenant data; it is git-ignored.
$script:OutDir = Join-Path $script:RepoRoot 'out'

function Connect-LabGraph {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph with the given delegated scopes, reusing the
    current session when it already has them.
    #>
    param([Parameter(Mandatory)][string[]]$Scopes)

    $ctx = Get-MgContext
    if ($ctx) {
        $missing = $Scopes | Where-Object { $_ -notin $ctx.Scopes }
        if (-not $missing) { return }
        Write-Verbose "Reconnecting to add scopes: $($missing -join ', ')"
    }
    Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
}

function Get-LabGraphCollection {
    <#
    .SYNOPSIS
    GETs a Graph collection and follows @odata.nextLink until every page is read.
    #>
    param([Parameter(Mandatory)][string]$Uri)

    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType Hashtable
        foreach ($v in $page['value']) { $items.Add($v) }
        $next = $page['@odata.nextLink']
    }
    # Callers must wrap the call in @(): PowerShell unrolls a one-item result
    # into a bare hashtable, whose .Count is its number of keys.
    return $items
}

function Get-LabGroupByName {
    param([Parameter(Mandatory)][string]$DisplayName)

    $escaped = $DisplayName.Replace("'", "''")
    $found = @(Get-MgGroup -Filter "displayName eq '$escaped'" -All)
    if ($found.Count -gt 1) { throw "More than one group is named '$DisplayName'." }
    return $found | Select-Object -First 1
}

function New-LabPassword {
    <#
    .SYNOPSIS
    Returns a random password from a cryptographic RNG. Excludes look-alike
    characters so it can be typed from a printout.
    #>
    param([ValidateRange(16, 256)][int]$Length = 24)

    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower = 'abcdefghijkmnopqrstuvwxyz'
    $digit = '23456789'
    $symbol = '!@#$%^&*-_=+?'
    $all = $upper + $lower + $digit + $symbol
    $rng = [System.Security.Cryptography.RandomNumberGenerator]

    # One of each class guarantees Entra ID complexity rules are met.
    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $upper, $lower, $digit, $symbol) { $chars.Add($set[$rng::GetInt32($set.Length)]) }
    while ($chars.Count -lt $Length) { $chars.Add($all[$rng::GetInt32($all.Length)]) }

    # Fisher-Yates shuffle so the guaranteed characters are not always first.
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = $rng::GetInt32($i + 1)
        $chars[$i], $chars[$j] = $chars[$j], $chars[$i]
    }
    return -join $chars
}

function Write-LabLog {
    <#
    .SYNOPSIS
    Writes a timestamped line to the console and, when -LogFile is set, to that
    file. Timestamps are UTC so they line up with Entra and AWS audit logs.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$LogFile
    )
    $line = '{0:yyyy-MM-ddTHH:mm:ssZ}  {1}' -f [DateTime]::UtcNow, $Message
    Write-Host $line
    if ($LogFile) { Add-Content -Path $LogFile -Value $line }
}

function Initialize-LabOutDir {
    if (-not (Test-Path $script:OutDir)) { New-Item -ItemType Directory -Path $script:OutDir | Out-Null }
    return $script:OutDir
}
