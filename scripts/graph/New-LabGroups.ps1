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

.EXAMPLE
./New-LabGroups.ps1 -Domain harbourlinelab.onmicrosoft.com -WhatIf
./New-LabGroups.ps1 -Domain harbourlinelab.onmicrosoft.com -SkuPartNumber SPE_E5
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Domain,
    [string]$GroupsPath = (Join-Path $PSScriptRoot '../../config/groups.json'),
    [string]$CsvPath = (Join-Path $PSScriptRoot '../../data/users.csv'),
    # Run Get-MgSubscribedSku | Select SkuPartNumber to see what the trial gives you.
    [string]$SkuPartNumber = 'SPE_E5',
    [string]$LicensedGroup = 'SG-All-Staff'
)

. "$PSScriptRoot/LabHelpers.ps1"

Connect-LabGraph -Scopes @(
    'Group.ReadWrite.All', 'GroupMember.ReadWrite.All', 'User.Read.All',
    'RoleManagement.ReadWrite.Directory', 'LicenseAssignment.ReadWrite.All', 'Organization.Read.All'
)

$design = Get-Content -Raw -Path $GroupsPath | ConvertFrom-Json

# --- 1. Groups ---------------------------------------------------------------
foreach ($g in $design.groups) {
    if (Get-LabGroupByName $g.displayName) {
        Write-Host "SKIP   $($g.displayName) (already exists)"
        continue
    }
    if (-not $PSCmdlet.ShouldProcess($g.displayName, "Create $($g.type) group")) { continue }

    $params = @{
        DisplayName     = $g.displayName
        Description     = $g.description
        MailEnabled     = $false
        MailNickname    = $g.displayName.ToLower()
        SecurityEnabled = $true
    }
    if ($g.type -eq 'Dynamic') {
        $params.GroupTypes = @('DynamicMembership')
        $params.MembershipRule = $g.membershipRule
        $params.MembershipRuleProcessingState = 'On'
    }
    if ($g.PSObject.Properties['isAssignableToRole'] -and $g.isAssignableToRole) {
        $params.IsAssignableToRole = $true
    }
    New-MgGroup @params -ErrorAction Stop | Out-Null
    Write-Host "CREATE $($g.displayName)"
}

# --- 2. Group-based licensing --------------------------------------------------
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

Write-Host "`nDynamic membership can take several minutes. Check with:"
Write-Host "  Get-MgGroupMember -GroupId (Get-MgGroup -Filter `"displayName eq 'SG-Dept-Dev'`").Id -All"
