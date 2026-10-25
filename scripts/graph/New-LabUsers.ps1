#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users
<#
.SYNOPSIS
Phase 1: bulk-creates the fictional Harbourline Advisory staff from data/users.csv.

.DESCRIPTION
Each user gets a random temporary password and must change it at first sign-in.
Passwords are written to out/initial-passwords-<timestamp>.csv, which is
git-ignored. Delete that file once the test users have signed in.

Licences are NOT assigned here: SG-All-Staff carries the licence (group-based
licensing), so a user is licensed by having a department. See New-LabGroups.ps1.

Existing users are skipped, so the script is safe to re-run.

.EXAMPLE
./New-LabUsers.ps1 -Domain harbourlinelab.onmicrosoft.com -WhatIf
./New-LabUsers.ps1 -Domain harbourlinelab.onmicrosoft.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z0-9.-]+\.[a-z]{2,}$')][string]$Domain,
    [string]$CsvPath = (Join-Path $PSScriptRoot '../../data/users.csv'),
    # Required before a licence can be assigned.
    [string]$UsageLocation = 'AU'
)

. "$PSScriptRoot/LabHelpers.ps1"

$users = Import-Csv -Path $CsvPath
Connect-LabGraph -Scopes 'User.ReadWrite.All'

$outFile = Join-Path (Initialize-LabOutDir) ('initial-passwords-{0:yyyyMMdd-HHmmss}.csv' -f (Get-Date))
$created = [System.Collections.Generic.List[object]]::new()
$skipped = 0

foreach ($u in $users) {
    $upn = "$($u.MailNickname)@$Domain"
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "SKIP   $upn (already exists)"
        $skipped++
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($upn, 'Create user')) { continue }

    $password = New-LabPassword
    $params = @{
        AccountEnabled    = $true
        DisplayName       = "$($u.GivenName) $($u.Surname)"
        GivenName         = $u.GivenName
        Surname           = $u.Surname
        MailNickname      = $u.MailNickname
        UserPrincipalName = $upn
        Department        = $u.Department
        JobTitle          = $u.JobTitle
        UsageLocation     = $UsageLocation
        PasswordProfile   = @{ Password = $password; ForceChangePasswordNextSignIn = $true }
    }
    $new = New-MgUser @params -ErrorAction Stop
    Write-Host "CREATE $upn ($($u.Department))"
    $created.Add([pscustomobject]@{ UserPrincipalName = $upn; ObjectId = $new.Id; TemporaryPassword = $password })
}

if ($created.Count -gt 0) {
    $created | Export-Csv -Path $outFile -NoTypeInformation
    Write-Warning "Temporary passwords written to $outFile. It is git-ignored; delete it after first sign-in."
}
Write-Host "Done: $($created.Count) created, $skipped already existed."
