#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns
<#
.SYNOPSIS
Phase 2: moves lab Conditional Access policies between report-only, on and off.

.DESCRIPTION
Matches policies by their ID prefix (CA001, CA002, ...). Before switching a
policy to 'enabled' it checks that the policy still excludes SG-BreakGlass.

.EXAMPLE
./Set-LabCAPolicyState.ps1 -Policy CA001 -State enabled -WhatIf
./Set-LabCAPolicyState.ps1 -Policy CA001,CA002 -State enabled
./Set-LabCAPolicyState.ps1 -Policy CA006 -State enabledForReportingButNotEnforced
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidatePattern('^CA\d{3}$')][string[]]$Policy,
    [Parameter(Mandatory)][ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')][string]$State
)

. "$PSScriptRoot/LabHelpers.ps1"

Connect-LabGraph -Scopes @('Policy.ReadWrite.ConditionalAccess', 'Policy.Read.All', 'Group.Read.All')

$breakGlassId = (Get-LabGroupByName 'SG-BreakGlass').Id
if (-not $breakGlassId) { throw 'SG-BreakGlass does not exist.' }

$all = @(Get-LabGraphCollection '/v1.0/identity/conditionalAccess/policies')

foreach ($prefix in $Policy) {
    $match = @($all | Where-Object { $_.displayName -like "$prefix *" })
    if ($match.Count -ne 1) {
        Write-Warning "$prefix matched $($match.Count) policies; skipping."
        continue
    }
    $p = $match[0]
    if ($State -eq 'enabled' -and $p['conditions']['users']['excludeGroups'] -notcontains $breakGlassId) {
        Write-Warning "$($p.displayName) does not exclude SG-BreakGlass; refusing to enable."
        continue
    }
    if ($p.state -eq $State) {
        Write-Host "SKIP   $($p.displayName) already $State"
    } elseif ($PSCmdlet.ShouldProcess($p.displayName, "Set state $($p.state) -> $State")) {
        Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $p.id -State $State -ErrorAction Stop
        Write-LabLog "STATE  $($p.displayName): $($p.state) -> $State"
    }
}
