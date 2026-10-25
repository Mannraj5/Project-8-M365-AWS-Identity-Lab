#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication
<#
.SYNOPSIS
Phase 2 evidence: exports every Conditional Access policy and named location to
JSON with tenant-specific IDs replaced by readable placeholders, ready to commit.

.DESCRIPTION
Group and named-location IDs become {{group:<name>}} / {{location:<name>}}, the
same format New-LabCAPolicies.ps1 reads, so an export can be re-imported into a
fresh tenant. Individual user IDs become {{user:redacted}}. Read-only metadata
(id, createdDateTime, modifiedDateTime, templateId) is dropped.

Role template IDs (includeRoles) are global constants, not tenant data, and are
kept as-is.

.EXAMPLE
./Export-LabCAPolicies.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot '../../config/conditional-access/exported')
)

. "$PSScriptRoot/LabHelpers.ps1"

Connect-LabGraph -Scopes @('Policy.Read.All', 'Group.Read.All')

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

$policies = @(Get-LabGraphCollection '/v1.0/identity/conditionalAccess/policies')
$locations = @(Get-LabGraphCollection '/v1.0/identity/conditionalAccess/namedLocations')

# Map every ID we can name back to a placeholder.
$names = @{}
foreach ($l in $locations) { $names[$l.id] = "{{location:$($l.displayName)}}" }
# Indexers rather than dot access: optional keys can be absent, and StrictMode
# throws on a missing property.
$groupIds = $policies | ForEach-Object {
    $_['conditions']['users']['includeGroups']
    $_['conditions']['users']['excludeGroups']
} | Where-Object { $_ } | Sort-Object -Unique
foreach ($id in $groupIds) {
    $g = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id`?`$select=displayName" -OutputType Hashtable
    $names[$id] = "{{group:$($g.displayName)}}"
}

function ConvertTo-Placeholder([object[]]$Ids, [switch]$IsUser) {
    foreach ($id in $Ids) {
        if ($names.ContainsKey($id)) { $names[$id] }
        elseif ($IsUser -and $id -match '^[0-9a-f-]{36}$') { '{{user:redacted}}' }
        else { $id }   # 'All', 'None', 'GuestsOrExternalUsers', 'AllTrusted', etc.
    }
}

$drop = 'id', 'createdDateTime', 'modifiedDateTime', 'templateId', '@odata.context'

foreach ($p in $policies) {
    foreach ($k in $drop) { $p.Remove($k) }
    $u = $p['conditions']['users']
    foreach ($k in 'includeGroups', 'excludeGroups') { if ($u[$k]) { $u[$k] = @(ConvertTo-Placeholder $u[$k]) } }
    foreach ($k in 'includeUsers', 'excludeUsers') { if ($u[$k]) { $u[$k] = @(ConvertTo-Placeholder $u[$k] -IsUser) } }
    $loc = $p['conditions']['locations']
    if ($loc) {
        foreach ($k in 'includeLocations', 'excludeLocations') { if ($loc[$k]) { $loc[$k] = @(ConvertTo-Placeholder $loc[$k]) } }
    }

    $fileName = ($p.displayName -replace '[^A-Za-z0-9]+', '-').Trim('-') + '.json'
    $p | ConvertTo-Json -Depth 20 | Set-Content -Path (Join-Path $OutputDir $fileName) -Encoding utf8NoBOM
    Write-Host "EXPORT $($p.displayName) [$($p.state)] -> $fileName"
}

$locationsOut = foreach ($l in $locations) {
    foreach ($k in $drop) { $l.Remove($k) }
    $l
}
@{ namedLocations = @($locationsOut) } | ConvertTo-Json -Depth 10 |
    Set-Content -Path (Join-Path $OutputDir 'named-locations.json') -Encoding utf8NoBOM

Write-Host "`nExported $($policies.Count) policies and $($locations.Count) named locations to $OutputDir"
Write-Host 'Check the diff for anything tenant-specific before you commit.'
