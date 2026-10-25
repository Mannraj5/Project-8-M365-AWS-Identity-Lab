#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Users.Actions, Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement.Actions
<#
.SYNOPSIS
Phase 3: leaver process for one user. Blocks sign-in, revokes sessions, removes
assigned group memberships and direct licences, and optionally retires their
Intune devices. Writes a timestamped log to out/ for the test evidence.

.DESCRIPTION
Order matters: sign-in is blocked and sessions revoked first, so the person
loses access before anything slower happens.

What happens without this script doing it:
- Group-based licences: SG-All-Staff requires accountEnabled = true, so the
  user drops out of it (and loses the licence) when dynamic membership is
  re-evaluated.
- AWS: removal from SG-AWS-* and the disabled account both flow to IAM Identity
  Center on the next SCIM provisioning cycle (about every 40 minutes).

The account is disabled, not deleted, so mailbox and OneDrive data can be
handed over first. Delete it after the retention period in the runbook.

.EXAMPLE
./Invoke-Leaver.ps1 -UserPrincipalName ella.ruiz@harbourlinelab.onmicrosoft.com -WhatIf
./Invoke-Leaver.ps1 -UserPrincipalName ella.ruiz@harbourlinelab.onmicrosoft.com -RetireDevices
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$UserPrincipalName,
    [switch]$RetireDevices
)

. "$PSScriptRoot/LabHelpers.ps1"

$scopes = @(
    'User.ReadWrite.All', 'GroupMember.ReadWrite.All', 'Group.Read.All',
    'RoleManagement.ReadWrite.Directory', 'LicenseAssignment.ReadWrite.All'
)
if ($RetireDevices) {
    $scopes += 'DeviceManagementManagedDevices.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All'
}
Connect-LabGraph -Scopes $scopes

$user = Get-MgUser -UserId $UserPrincipalName -Property 'id,userPrincipalName,accountEnabled,department' -ErrorAction Stop
$alias = $UserPrincipalName.Split('@')[0]
$log = Join-Path (Initialize-LabOutDir) ('leaver-{0}-{1:yyyyMMdd-HHmmss}.log' -f $alias, (Get-Date))
$start = [DateTime]::UtcNow

Write-LabLog "START  leaver for $alias (department: $($user.Department))" $log

# 1. Block sign-in
if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Block sign-in')) {
    Update-MgUser -UserId $user.Id -AccountEnabled:$false -ErrorAction Stop
    Write-LabLog 'DONE   sign-in blocked (accountEnabled = false)' $log
}

# 2. Revoke refresh tokens and session cookies
if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Revoke sign-in sessions')) {
    Revoke-MgUserSignInSession -UserId $user.Id -ErrorAction Stop | Out-Null
    Write-LabLog 'DONE   sessions revoked' $log
}

# 3. Remove from assigned groups (dynamic groups cannot be edited and follow the account)
$groups = @(Get-LabGraphCollection "/v1.0/users/$($user.Id)/memberOf/microsoft.graph.group?`$select=id,displayName,groupTypes")
foreach ($g in $groups) {
    if ($g.groupTypes -contains 'DynamicMembership') {
        Write-LabLog "INFO   $($g.displayName) is dynamic; membership ends on re-evaluation" $log
        continue
    }
    if ($PSCmdlet.ShouldProcess($g.displayName, "Remove $alias")) {
        Remove-MgGroupMemberDirectoryObjectByRef -GroupId $g.id -DirectoryObjectId $user.Id -ErrorAction Stop
        Write-LabLog "DONE   removed from $($g.displayName)" $log
    }
}

# 4. Remove direct licences (group-based ones go with the group)
$states = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$($user.Id)?`$select=licenseAssignmentStates" -OutputType Hashtable).licenseAssignmentStates
$direct = @($states | Where-Object { -not $_.assignedByGroup } | ForEach-Object { $_.skuId } | Sort-Object -Unique)
if ($direct.Count -and $PSCmdlet.ShouldProcess($UserPrincipalName, "Remove $($direct.Count) direct licence(s)")) {
    Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses $direct -ErrorAction Stop | Out-Null
    Write-LabLog "DONE   removed direct licences: $($direct -join ', ')" $log
} elseif (-not $direct.Count) {
    Write-LabLog 'INFO   no direct licences; group-based licence follows SG-All-Staff' $log
}

# 5. Retire Intune devices (removes company data and management; does not wipe personal data)
if ($RetireDevices) {
    $devices = @(Get-LabGraphCollection "/v1.0/users/$($user.Id)/managedDevices?`$select=id,deviceName,operatingSystem")
    foreach ($d in $devices) {
        if ($PSCmdlet.ShouldProcess($d.deviceName, 'Retire Intune device')) {
            Invoke-MgRetireDeviceManagementManagedDevice -ManagedDeviceId $d.id -ErrorAction Stop
            Write-LabLog "DONE   retire sent to $($d.deviceName) ($($d.operatingSystem))" $log
        }
    }
    if (-not $devices.Count) { Write-LabLog 'INFO   no managed devices' $log }
}

$elapsed = [DateTime]::UtcNow - $start
Write-LabLog ("END    script finished in {0:n0}s. Now test: sign-in as {1} must fail; AWS access ends after next SCIM cycle." -f $elapsed.TotalSeconds, $alias) $log
Write-Host "Log: $log"
