#Requires -Version 7.2
<#
.SYNOPSIS
Phase 0 acceptance check: PowerShell 7, Microsoft Graph SDK and AWS CLI are
installed, and (with -Connect) Connect-MgGraph works.

.EXAMPLE
./Test-LabPrereqs.ps1
./Test-LabPrereqs.ps1 -Connect
#>
[CmdletBinding()]
param([switch]$Connect)

. "$PSScriptRoot/LabHelpers.ps1"

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Check, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail })
}

Add-Result -Check 'PowerShell 7.2+' -Pass ($PSVersionTable.PSVersion -ge [version]'7.2') -Detail "$($PSVersionTable.PSVersion)"

$graph = Get-Module -ListAvailable Microsoft.Graph.Authentication | Sort-Object Version -Descending | Select-Object -First 1
Add-Result -Check 'Microsoft Graph SDK' -Pass ([bool]$graph) -Detail $(if ($graph) { "v$($graph.Version)" } else { 'Install-Module Microsoft.Graph -Scope CurrentUser' })

$aws = Get-Command aws -ErrorAction SilentlyContinue
$awsVersion = if ($aws) { (& aws --version 2>&1) -join ' ' } else { 'Install AWS CLI v2' }
Add-Result -Check 'AWS CLI v2' -Pass ([bool]$aws -and $awsVersion -match 'aws-cli/2\.') -Detail $awsVersion

if ($Connect) {
    try {
        Connect-LabGraph -Scopes 'User.Read'
        $ctx = Get-MgContext
        # Only the domain suffix of the account is shown, so the output can go in evidence.
        $who = ($ctx.Account -replace '^[^@]+', '***')
        Add-Result -Check 'Connect-MgGraph' -Pass $true -Detail "Signed in as $who"
    } catch {
        Add-Result -Check 'Connect-MgGraph' -Pass $false -Detail $_.Exception.Message
    }
}

$results | Format-Table -AutoSize
if ($results.Result -contains 'FAIL') { exit 1 }
