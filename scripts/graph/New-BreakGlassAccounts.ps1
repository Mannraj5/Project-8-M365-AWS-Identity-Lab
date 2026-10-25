#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.Governance
<#
.SYNOPSIS
Phase 1: creates two cloud-only emergency access (break-glass) accounts with a
permanent Global Administrator assignment and adds them to SG-BreakGlass.

.DESCRIPTION
Passwords are shown ONCE on screen and never written to disk. Record each one
offline (for example split across two sealed envelopes in a safe), then
register a FIDO2 security key or passkey for each account before you rely on it:
Microsoft enforces MFA on admin portal sign-ins, so a password alone will not
get you in during an emergency.

Run New-LabGroups.ps1 first so SG-BreakGlass exists.

.EXAMPLE
./New-BreakGlassAccounts.ps1 -Domain harbourlinelab.onmicrosoft.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidatePattern('\.onmicrosoft\.com$')][string]$Domain,
    [string[]]$AccountNames = @('bg-emergency-01', 'bg-emergency-02')
)

. "$PSScriptRoot/LabHelpers.ps1"

$GlobalAdminRoleId = '62e90394-69f5-4237-9190-012177145e10'

Connect-LabGraph -Scopes @('User.ReadWrite.All', 'GroupMember.ReadWrite.All', 'RoleManagement.ReadWrite.Directory')

$bgGroup = Get-LabGroupByName 'SG-BreakGlass'
if (-not $bgGroup) { throw 'SG-BreakGlass does not exist. Run New-LabGroups.ps1 first.' }

foreach ($name in $AccountNames) {
    $upn = "$name@$Domain"
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue

    if ($user) {
        Write-Host "SKIP   create $upn (already exists)"
    } elseif ($PSCmdlet.ShouldProcess($upn, 'Create break-glass account')) {
        $password = New-LabPassword -Length 40
        $user = New-MgUser -AccountEnabled -DisplayName "Emergency Access $($name[-2..-1] -join '')" `
            -UserPrincipalName $upn -MailNickname $name `
            -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $false } `
            -ErrorAction Stop
        Write-Host "CREATE $upn"
        Write-Host "       Password (shown once, record it offline now): $password" -ForegroundColor Yellow
        Read-Host  '       Press Enter once recorded' | Out-Null
        Clear-Host
    }
    if (-not $user) { continue }

    $members = (Get-MgGroupMember -GroupId $bgGroup.Id -All).Id
    if ($members -notcontains $user.Id -and $PSCmdlet.ShouldProcess($upn, 'Add to SG-BreakGlass')) {
        New-MgGroupMember -GroupId $bgGroup.Id -DirectoryObjectId $user.Id
        Write-Host "MEMBER $upn -> SG-BreakGlass"
    }

    $existing = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($user.Id)' and roleDefinitionId eq '$GlobalAdminRoleId'"
    if (-not $existing -and $PSCmdlet.ShouldProcess($upn, 'Assign permanent Global Administrator')) {
        New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $user.Id -RoleDefinitionId $GlobalAdminRoleId -DirectoryScopeId '/' | Out-Null
        Write-Host "ROLE   $upn -> Global Administrator (permanent)"
    }
}

Write-Host "`nNext: sign in as each account, register a FIDO2 key or passkey, and create the sign-in alert (docs/runbooks/break-glass.md)."
