using namespace Microsoft.Open.Azure.AD.CommonLibrary
using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"

# To be refactored- this is a little disorganised at the moment.
#
# This code gets all licenses in a tenant and groups them according to their distinct offerings
# If licenses have been allocated ad-hoc with distinct sets of plans enabled/disabled there may be 
# many groupings returned.
#
# Chris Dymond

try {
    Get-AzureADCurrentSessionInfo | Out-Null
}
catch [AadNeedAuthenticationException] {
    Connect-AzureAD
}

$ImportedSkuIdFriendlyNames = Import-Csv .\SkuId_Friendly_Names.csv
$LicenseNames = [System.Collections.Generic.Dictionary[string, string]]::new()

foreach ($ImportedSkuIdFriendlyNames in $ImportedSkuIdFriendlyNames) {
    $LicenseNames.Add($ImportedSkuIdFriendlyNames.SkuId, $ImportedSkuIdFriendlyNames.SkuIdFriendlyName)
}

$ImportedPlanIdFriendlyNames = Import-Csv .\PlanId_Friendly_Names.csv
$PlanFriendlyNames = [System.Collections.Generic.Dictionary[string, string]]::new()

foreach ($ImportedPlanIdFriendlyName in $ImportedPlanIdFriendlyNames) {
    $PlanFriendlyNames.Add($ImportedPlanIdFriendlyName.PlanId, $ImportedPlanIdFriendlyName.PlanIdFriendlyName)
}

$Licenses = Get-AzureADSubscribedSku | Select-Object -Property Sku*, `
@{N = 'LicenseName'; E = { '' } }, `
@{N = 'Total'; E = { $_.PrepaidUnits.'Enabled' } }, `
@{N = 'Assigned'; E = { $_.ConsumedUnits } }, `
@{N = 'Available'; E = { $_.PrepaidUnits.'Enabled' - $_.ConsumedUnits } }, `
@{N = 'Suspended'; E = { $_.PrepaidUnits.'Suspended' } }, `
@{N = 'Warning'; E = { $_.PrepaidUnits.'Warning' } }

foreach ($License in $Licenses) {
    $LicenseName = $null
    if ($LicenseNames.TryGetValue($License.SkuId, [ref] $LicenseName) -eq $false) {
        #Write-Output "Message`t`t: There is no Friendly Name for this SKU"
        #$License
    }
    else {
        $License.LicenseName = $LicenseName
    }
}

Write-Output "`n---Tenant Licensing---"

$Licenses

class LicensingGroup {
    [string]$LicenseName
    [string]$SkuPartNumber
    [int]$DisabledPlanCount
    [List[string]] $DisabledPlanNames = [List[string]]::new()
    [int]$UserCount
    [List[string]] $Users = [List[string]]::new()
}

function GetLicenseWithDisabledPlans([Microsoft.Open.AzureAD.Model.DirectoryObject] $User) {
    # Licenses are either fully enabled or have some service plan features disabled
    # This function just generates a key to represent a distinct license and features disabled
    $LicenseIndexKey = $License.SkuId
    if ($License.DisabledPlans) {
        $LicenseIndexKey += ' DisabledPlans'
        $License.DisabledPlans = $License.DisabledPlans | Sort-Object
        $License.DisabledPLans | ForEach-Object { $LicenseIndexKey += ';' + $_ }
    }
    $LicenseIndexKey
}

$LicenseGroupings = [System.Collections.Generic.Dictionary[string, LicensingGroup]]::new()
$LicensedUsers = [System.Collections.Generic.Dictionary[string, Microsoft.Open.AzureAD.Model.DirectoryObject]]::new()

#Get-AzureAdUser -All $true | Where-Object { ($_.ProxyAddresses -match '@').Count -eq 0 -and ($_.ProxyAddresses -match '@').Count -eq 0 } | ForEach-Object {
#Get-AzureAdUser -All $true | Where-Object { $_.ProxyAddresses -match '@' -or $_.ProxyAddresses -match '@' } | ForEach-Object {
Get-AzureAdUser -All $true | ForEach-Object {
    $licensed = $False
    For ($i = 0; $i -le ($_.AssignedLicenses | Measure-Object).Count ; $i++) {
        If ( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed = $true } 
    }
          
    If ( $licensed -eq $true) {
        $LicensedUsers.Add($_.UserPrincipalName, $_)
        ForEach ($License in $_.AssignedLicenses) {
            $LicenseWithDisabledPlans = GetLicenseWithDisabledPlans($_)
            $existingLicensePattern = $null
            if ($LicenseGroupings.TryGetValue($LicenseWithDisabledPlans, [ref] $existingLicensePattern) -eq $false) {

                [List[string]] $DisabledPlanNames = [List[string]]::new()
                if ($License.DisabledPlans) {
                    $License.DisabledPlans = $License.DisabledPlans | Sort-Object

                    foreach ($DisabledPlanId in $License.DisabledPlans) {

                        $PlanFriendlyName = $null
                        if ($PlanFriendlyNames.TryGetValue($DisabledPlanId, [ref] $PlanFriendlyName) -eq $true) {
                            $DisabledPlanNames.Add($PlanFriendlyName)
                        }
                        else {
                            $DisabledPlanNames.Add($DisabledPlanId)
                        }
                    }
                }
                $LicensingGroup = [LicensingGroup]::new()
                $LicensingGroup.DisabledPlanNames = $DisabledPlanNames | Sort-Object
                $LicensingGroup.DisabledPlanCount = $DisabledPlanNames.Count
                $LicensingGroup.UserCount = 1
                $LicenseName = $null
                if ($LicenseNames.TryGetValue($License.SkuId, [ref] $LicenseName) -eq $true) {
                    $LicensingGroup.LicenseName = $LicenseName
                }

                $SkuPartNumber = $Licenses | Where-Object { $_.SkuId -eq $License.SkuId } | Select-Object -ExpandProperty SkuPartNumber
                $LicensingGroup.SkuPartNumber = $SkuPartNumber
                $LicensingGroup.Users.Add($_.UserPrincipalName)
                
                $LicenseGroupings.Add($LicenseWithDisabledPlans, $LicensingGroup)
            }
            else {
                $CurrentCount = $LicenseGroupings[$LicenseWithDisabledPlans].UserCount
                $LicenseGroupings[$LicenseWithDisabledPlans].UserCount = $CurrentCount + 1
                $LicenseGroupings[$LicenseWithDisabledPlans].Users.Add($_.UserPrincipalName)
            }
        }
    } 
}

$LicensingResults = $LicenseGroupings.GetEnumerator() | ForEach-Object {
    $_.Value | Select-Object LicenseName, DisabledPlanCount, `
    @{name = "DisabledPlans"; expression = { $_.DisabledPlanNames -join ', ' } }, `
        UserCount, `
    @{name = "Users"; expression = { $_.Users -join ', ' } }
}

Write-Output "---Licensing Grouped by Service Plan Features---`n"
$LicensingResults

Write-Output "---Writing to CSV---`n"
$LicensingResults | Export-Csv 'LicensingGrouped.csv' -NoTypeInformation

Write-Output "Done."

function Get-AzureADGroupsWithLicenses {
    
    Get-AzureADMSAdministrativeUnit -Top 1 | Out-Null # Just to ensure we have a graph.microsoft.com token (not just a graph.windows.net)

    $GraphToken = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::TokenCache.ReadItems() | `
        Where-Object { $_.Resource -eq 'https://graph.microsoft.com' } | Select-Object AccessToken
    if ($null -eq $GraphToken) {
        throw "The Graph Access token is not available!"
    }
    $UserRegistrationDetails = @{
        Uri     = 'https://graph.microsoft.com/beta/groups?$filter=startswith(displayName, ''usr'')&$select=id,onPremisesSyncEnabled,displayName,assignedLicenses'
        Headers = @{
            'Authorization' = "Bearer $($GraphToken.AccessToken)" 
        }
        Method  = 'GET'
    }
    Invoke-RestMethod @UserRegistrationDetails
}
