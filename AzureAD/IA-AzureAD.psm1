# Identity and Access (IA) - Additional cmdlets for Azure AD
# Author: Chris Dymond
# Date: 24-04-2021

using namespace System.Collections.Generic
using namespace Microsoft.Open.Azure.AD.CommonLibrary
$ErrorActionPreference = "Stop"

# Private member functions
function Assert-AzureADConnected {
    try {
        Get-AzureADCurrentSessionInfo | Out-Null
    }
    catch [AadNeedAuthenticationException] {
        Connect-AzureAD
    }
}

# Exported member functions

class IAGroup {
    [string]$DisplayName
    [string]$Mail
    [string]$Type
    [string]$OnPremisesSyncEnabled
    [string]$Owners
}

function Get-IAAzureADGroups {
    <#
    .SYNOPSIS
    Returns a list of all groups in Azure AD.
    
    .DESCRIPTION
    Returns the Display Name, Mail (if present), Type (Microsoft 365, Security or Distribution),
    whether the group is synchronised from on-premise and a list of group owners (where defined in Azure)
    
    .EXAMPLE
    Get-IAAzureADGroups

    DisplayName           : Chris' Security Group
    Mail                  :
    Type                  : Security
    OnPremisesSyncEnabled : True
    Owners                :


    DisplayName           : Chris' M365 Group
    Mail                  : ChrisGroup@domain.onmicrosoft.com
    Type                  : Microsoft 365
    OnPremisesSyncEnabled : False
    Owners                : chris.dymond@domain.com
    
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([List[IAGroup]])]
    param
    (

    )
    process {
        Assert-AzureADConnected
        $iaGroupList = [List[IAGroup]]::new()
        $groups = Get-AzureADMSGroup -All $true
        $groups | ForEach-Object {
            #  $_.OnPremisesSyncEnabled can return true or (false or null)
            # This sanitises the result
            $OnPremisesSyncEnabled = $null
            if ($_.OnPremisesSyncEnabled -eq $true) {
                $onPremisesSyncEnabled = $true
            }
            else {
                $onPremisesSyncEnabled = $false
            }
            [IAGroup] $iaGroup = [IAGroup]::new()
            $iaGroup.OnPremisesSyncEnabled = $onPremisesSyncEnabled
            $iaGroup.Owners = (Get-AzureADGroupOwner -ObjectId $_.Id -All $true | Select-Object -ExpandProperty UserPrincipalName) -join ', '
            $iaGroup.DisplayName = $_.DisplayName
            $iaGroup.Mail = $_.Mail
            If ($_.GroupTypes[0] -eq "Unified") {
                $iaGroup.Type = "Microsoft 365"
            }
            elseif ($_.SecurityEnabled  ) {
                $iaGroup.Type = "Security"  
            }
            else {
                $iaGroup.Type = "Distribution"
            }
            $iaGroupList.Add($iaGroup)
        }
        $iaGroupList | Sort-Object Displayname
    }
}
Export-ModuleMember -Function Get-IAAzureADGroups
