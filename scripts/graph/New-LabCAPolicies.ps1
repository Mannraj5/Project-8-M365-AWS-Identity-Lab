#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Groups, Microsoft.Graph.Identity.SignIns
<#
.SYNOPSIS
Phase 2: creates the named locations and Conditional Access policies in
config/conditional-access/, always in report-only mode.

.DESCRIPTION
Policy files reference tenant objects by name, not ID, so they can be committed
safely and reused in another tenant:
  {{group:SG-BreakGlass}}     -> object ID of that group
  {{location:NL-Australia}}   -> ID of that named location
The script refuses to create a policy if any placeholder cannot be resolved,
and refuses any policy that does not exclude SG-BreakGlass, because a policy
without that exclusion can lock every admin out of the tenant.

Policies whose displayName already exists are skipped. Turn a policy on only
after reviewing its report-only results: Set-LabCAPolicyState.ps1.

.EXAMPLE
./New-LabCAPolicies.ps1 -WhatIf
./New-LabCAPolicies.ps1
./New-LabCAPolicies.ps1 -Include CA001,CA002
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PolicyDir = (Join-Path $PSScriptRoot '../../config/conditional-access'),
    # Policy ID prefixes to create, e.g. CA001. Default: all.
    [string[]]$Include
)

. "$PSScriptRoot/LabHelpers.ps1"

Connect-LabGraph -Scopes @('Policy.ReadWrite.ConditionalAccess', 'Policy.Read.All', 'Group.Read.All', 'Application.Read.All')

# --- 1. Named locations ------------------------------------------------------
$locationIds = @{}
$existingLocations = @(Get-LabGraphCollection '/v1.0/identity/conditionalAccess/namedLocations')
foreach ($loc in $existingLocations) { $locationIds[$loc.displayName] = $loc.id }

$locFile = Join-Path $PolicyDir 'named-locations.json'
foreach ($loc in (Get-Content -Raw $locFile | ConvertFrom-Json -AsHashtable).namedLocations) {
    if ($locationIds.ContainsKey($loc.displayName)) {
        Write-Host "SKIP   location $($loc.displayName) (already exists)"
    } elseif ($PSCmdlet.ShouldProcess($loc.displayName, 'Create named location')) {
        $new = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $loc -ErrorAction Stop
        $locationIds[$loc.displayName] = $new.Id
        Write-Host "CREATE location $($loc.displayName)"
    }
}

# --- 2. Policies -------------------------------------------------------------
$existingPolicies = @(Get-LabGraphCollection '/v1.0/identity/conditionalAccess/policies').displayName
$breakGlass = Get-LabGroupByName 'SG-BreakGlass'
if (-not $breakGlass) { throw 'SG-BreakGlass does not exist. Run New-LabGroups.ps1 first.' }

$files = Get-ChildItem -Path $PolicyDir -Filter 'CA*.json' | Sort-Object Name
if ($Include) { $files = $files | Where-Object { $n = $_.Name; $Include | Where-Object { $n.StartsWith($_) } } }

foreach ($file in $files) {
    $raw = Get-Content -Raw $file.FullName
    $unresolved = [System.Collections.Generic.List[string]]::new()

    $resolved = [regex]::Replace($raw, '\{\{(group|location):([^}]+)\}\}', {
            param($m)
            $kind, $name = $m.Groups[1].Value, $m.Groups[2].Value
            $id = if ($kind -eq 'group') { (Get-LabGroupByName $name).Id } else { $locationIds[$name] }
            if (-not $id) { $unresolved.Add($m.Value); return $m.Value }
            return $id
        })

    $policy = $resolved | ConvertFrom-Json -AsHashtable
    $name = $policy.displayName

    if ($unresolved.Count) {
        Write-Warning "SKIP   $name : cannot resolve $($unresolved -join ', ')"
        continue
    }
    if ($policy['conditions']['users']['excludeGroups'] -notcontains $breakGlass.Id) {
        Write-Warning "SKIP   $name : does not exclude SG-BreakGlass"
        continue
    }
    if ($existingPolicies -contains $name) {
        Write-Host "SKIP   $name (already exists)"
        continue
    }

    # Whatever the file says, new policies start in report-only.
    $policy.state = 'enabledForReportingButNotEnforced'

    if ($PSCmdlet.ShouldProcess($name, 'Create Conditional Access policy (report-only)')) {
        New-MgIdentityConditionalAccessPolicy -BodyParameter $policy -ErrorAction Stop | Out-Null
        Write-Host "CREATE $name [report-only]"
    }
}

Write-Host "`nReview Entra admin center > Sign-in logs > Report-only tab before enforcing."
