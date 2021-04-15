using namespace Microsoft.Open.Azure.AD.CommonLibrary
using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"

# To be refactored- this is too disorganised at the moment.
#
# This code gets all licenses in a tenant and groups these by features turned on (plans enabled) per user

try {
    Get-AzureADCurrentSessionInfo | Out-Null
}
catch [AadNeedAuthenticationException] {
    Connect-AzureAD
}

$ImportedSkuIdFriendlyNames = Import-Csv .\SkuId_Friendly_Names.csv
$SkuFriendlyNames = [System.Collections.Generic.Dictionary[string, string]]::new()

foreach ($ImportedSkuIdFriendlyNames in $ImportedSkuIdFriendlyNames) {
    $SkuFriendlyNames.Add($ImportedSkuIdFriendlyNames.SkuId, $ImportedSkuIdFriendlyNames.SkuIdFriendlyName)
}

$ImportedPlanIdFriendlyNames = Import-Csv .\PlanId_Friendly_Names.csv
$PlanFriendlyNames = [System.Collections.Generic.Dictionary[string, string]]::new()

foreach ($ImportedPlanIdFriendlyName in $ImportedPlanIdFriendlyNames) {
    $PlanFriendlyNames.Add($ImportedPlanIdFriendlyName.PlanId, $ImportedPlanIdFriendlyName.PlanIdFriendlyName)
}

$Licenses = Get-AzureADSubscribedSku | Select-Object -Property Sku*, `
@{N = 'SkuFriendlyName'; E = { '' } }, `
@{N = 'Total'; E = { $_.PrepaidUnits.'Enabled' } }, `
@{N = 'Assigned'; E = { $_.ConsumedUnits } }, `
@{N = 'Available'; E = { $_.PrepaidUnits.'Enabled' - $_.ConsumedUnits } }, `
@{N = 'Suspended'; E = { $_.PrepaidUnits.'Suspended' } }, `
@{N = 'Warning'; E = { $_.PrepaidUnits.'Warning' } }

foreach ($License in $Licenses) {
    $SkuFriendlyName = $null
    if ($SkuFriendlyNames.TryGetValue($License.SkuId, [ref] $SkuFriendlyName) -eq $false) {
        #Write-Output "Message`t`t: There is no Friendly Name for this SKU"
        #$License
    }
    else {
        $License.SkuFriendlyName = $SkuFriendlyName
    }
}

$Licenses

class LicensingGroup {
    [string]$SkuFriendlyName
    [string]$SkuPartNumber
    [int]$DisabledPlanCount
    [List[string]] $DisabledPlanNames = [List[string]]::new()
    [int]$UserCount
    [List[string]] $Users = [List[string]]::new()
}

function GetLicenseWithDisabledPlans([Microsoft.Open.AzureAD.Model.DirectoryObject] $User) {
    # Licenses are either fully enabled or have some service features disabled
    # This function just generates a key to represent features enabled on a a user for a particular license
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
                

                        # $DisabledPlanName = $_.AssignedPlans | Where-Object { $_.ServicePlanId -eq $DisabledPlanId } | Select-Object Service

                        # $DisabledPlanNames.Add($DisabledPlanName.Service)
                    }
                }
                $LicensingGroup = [LicensingGroup]::new()
                $LicensingGroup.DisabledPlanNames = $DisabledPlanNames | Sort-Object
                $LicensingGroup.DisabledPlanCount = $DisabledPlanNames.Count
                $LicensingGroup.UserCount = 1
                $SkuFriendlyName = $null
                if ($SkuFriendlyNames.TryGetValue($License.SkuId, [ref] $SkuFriendlyName) -eq $true) {
                    $LicensingGroup.SkuFriendlyName = $SkuFriendlyName
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

foreach ($Key in $LicenseGroupings.Keys) {
    ConvertTo-Json($LicenseGroupings[$Key])
}

