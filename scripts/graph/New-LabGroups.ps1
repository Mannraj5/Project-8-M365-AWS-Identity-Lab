#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Groups, Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement
<#
.SYNOPSIS
Phase 1: creates the groups in config/groups.json, assigns the licence to
SG-All-Staff, and adds AWS group members from data/users.csv.

.DESCRIPTION
- Dynamic groups are created with rule processing On. Membership can take a
  few minutes to evaluate after users are created.
- Role-assignable groups (SG-Admins-PIM, SG-BreakGlass) can only be created by
  a Privileged Role Administrator or Global Administrator, and their membership
  can only be changed by those roles, which protects the CA exclusion group.
- Existing groups are skipped, so the script is safe to re-run.

-FreeTier (tenant on Microsoft Entra ID Free, no P1):
- Dynamic groups are created as ordinary assigned groups instead, and the
  script keeps them in sync with each user's department, using the
  freeTierDepartments list in groups.json in place of the rule. Re-run it
  after a joiner, mover or leaver to add and remove members.
- Groups are not made role-assignable (that needs P1), and licensing is
  skipped (Free has no licences to assign).

.EXAMPLE
./New-LabGroups.ps1 -Domain harbourlinelab.onmicrosoft.com -WhatIf
./New-LabGroups.ps1 -Domain harbourlinelab.onmicrosoft.com -SkuPartNumber SPE_E5
./New-LabGroups.ps1 -Domain harbourlinelab.onmicrosoft.com -FreeTier
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Domain,
    [string]$GroupsPath = (Join-Path $PSScriptRoot '../../config/groups.json'),
    [string]$CsvPath = (Join-Path $PSScriptRoot '../../data/users.csv'),
    # Run Get-MgSubscribedSku | Select SkuPartNumber to see what the trial gives you.
    [string]$SkuPartNumber = 'SPE_E5',
    [string]$LicensedGroup = 'SG-All-Staff',
    # Tenant is on Entra ID Free: no dynamic or role-assignable groups, no licensing.
    [switch]$FreeTier
)

. "$PSScriptRoot/LabHelpers.ps1"

$scopes = @('Group.ReadWrite.All', 'GroupMember.ReadWrite.All', 'User.Read.All')
if (-not $FreeTier) {
    $scopes += 'RoleManagement.ReadWrite.Directory', 'LicenseAssignment.ReadWrite.All', 'Organization.Read.All'
}
Connect-LabGraph -Scopes $scopes

$design = Get-Content -Raw -Path $GroupsPath | ConvertFrom-Json

# --- 1. Groups ---------------------------------------------------------------
foreach ($g in $design.groups) {
    if (Get-LabGroupByName $g.displayName) {
        Write-Host "SKIP   $($g.displayName) (already exists)"
        continue
    }
    $kind = if ($FreeTier -and $g.type -eq 'Dynamic') { 'Assigned (Free tier)' } else { $g.type }
    if (-not $PSCmdlet.ShouldProcess($g.displayName, "Create $kind group")) { continue }

    $params = @{
        DisplayName     = $g.displayName
        Description     = $g.description
        MailEnabled     = $false
        MailNickname    = $g.displayName.ToLower()
        SecurityEnabled = $true
    }
    if ($g.type -eq 'Dynamic' -and -not $FreeTier) {
        $params.GroupTypes = @('DynamicMembership')
        $params.MembershipRule = $g.membershipRule
        $params.MembershipRuleProcessingState = 'On'
    }
    if ($g.PSObject.Properties['isAssignableToRole'] -and $g.isAssignableToRole -and -not $FreeTier) {
        $params.IsAssignableToRole = $true
    }
    New-MgGroup @params -ErrorAction Stop | Out-Null
    Write-Host "CREATE $($g.displayName)$(if ($FreeTier -and $g.type -eq 'Dynamic') { ' (assigned: Free tier)' })"
}

# --- 1b. Free tier: keep department groups in sync, as a dynamic rule would ---
if ($FreeTier) {
    # Same conditions as the dynamic rules: enabled member accounts with a department.
    $allUsers = @(Get-MgUser -All -Property 'id,userPrincipalName,department,accountEnabled,userType')
    $staff = @($allUsers | Where-Object { $_.AccountEnabled -and $_.UserType -eq 'Member' -and $_.Department })
    $upnById = @{}
    foreach ($u in $allUsers) { $upnById[$u.Id] = $u.UserPrincipalName }

    foreach ($g in $design.groups | Where-Object { $_.PSObject.Properties['freeTierDepartments'] }) {
        $group = Get-LabGroupByName $g.displayName
        if (-not $group) {
            Write-Warning "$($g.displayName) does not exist yet (expected under -WhatIf)."
            continue
        }
        $want = @($staff | Where-Object { $_.Department -in $g.freeTierDepartments })
        $have = @(Get-MgGroupMember -GroupId $group.Id -All)

        foreach ($u in $want | Where-Object { $_.Id -notin $have.Id }) {
            if ($PSCmdlet.ShouldProcess("$($u.UserPrincipalName) -> $($g.displayName)", 'Add member')) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $u.Id
                Write-Host "MEMBER $($u.UserPrincipalName) -> $($g.displayName)"
            }
        }
        foreach ($m in $have | Where-Object { $_.Id -notin $want.Id }) {
            $who = if ($upnById[$m.Id]) { $upnById[$m.Id] } else { $m.Id }
            if ($PSCmdlet.ShouldProcess("$who from $($g.displayName)", 'Remove member')) {
                Remove-MgGroupMemberDirectoryObjectByRef -GroupId $group.Id -DirectoryObjectId $m.Id
                Write-Host "REMOVE $who from $($g.displayName) (department or account no longer matches)"
            }
        }
    }
}

# --- 2. Group-based licensing --------------------------------------------------
if ($FreeTier) {
    Write-Host 'SKIP   licensing (Entra ID Free has no licences to assign)'
} else {
    $sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq $SkuPartNumber
    $licensed = Get-LabGroupByName $LicensedGroup
    if ($licensed) {
        # assignedLicenses is not in the default property set.
        $licensed = Get-MgGroup -GroupId $licensed.Id -Property 'id,displayName,assignedLicenses'
    }
    if (-not $sku) {
        $available = (Get-MgSubscribedSku -All).SkuPartNumber -join ', '
        Write-Warning "SKU '$SkuPartNumber' not found. Available: $available. Re-run with -SkuPartNumber."
    } elseif (-not $licensed) {
        Write-Warning "$LicensedGroup does not exist yet (expected under -WhatIf)."
    } elseif ($licensed.AssignedLicenses.SkuId -contains $sku.SkuId) {
        Write-Host "SKIP   licence $SkuPartNumber already on $LicensedGroup"
    } elseif ($PSCmdlet.ShouldProcess($LicensedGroup, "Assign licence $SkuPartNumber")) {
        Set-MgGroupLicense -GroupId $licensed.Id -AddLicenses @(@{ SkuId = $sku.SkuId }) -RemoveLicenses @() | Out-Null
        Write-Host "LICENCE $SkuPartNumber -> $LicensedGroup"
    }
}

# --- 3. AWS group membership (assigned, so removal is a deliberate act) ------
foreach ($u in Import-Csv -Path $CsvPath | Where-Object AwsGroup) {
    $upn = "$($u.MailNickname)@$Domain"
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    $group = Get-LabGroupByName $u.AwsGroup
    if (-not $user -or -not $group) {
        Write-Warning "Cannot add $upn to $($u.AwsGroup): user or group missing."
        continue
    }
    $members = (Get-MgGroupMember -GroupId $group.Id -All).Id
    if ($members -contains $user.Id) {
        Write-Host "SKIP   $upn already in $($u.AwsGroup)"
    } elseif ($PSCmdlet.ShouldProcess("$upn -> $($u.AwsGroup)", 'Add member')) {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
        Write-Host "MEMBER $upn -> $($u.AwsGroup)"
    }
}

if ($FreeTier) {
    Write-Host "`nFree tier: department groups are synced by this script. Re-run it after any joiner, mover or leaver."
} else {
    Write-Host "`nDynamic membership can take several minutes. Check with:"
    Write-Host "  Get-MgGroupMember -GroupId (Get-MgGroup -Filter `"displayName eq 'SG-Dept-Dev'`").Id -All"
}
