# Identity and Access (IA) - Additional cmdlets for Azure AD
# Author: Chris Dymond
# Date: 24-04-2021

using namespace System.Collections.Generic
using namespace Microsoft.Open.Azure.AD.CommonLibrary
using namespace Microsoft.Open.AzureAD.Model
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


function Assert-ExchangeOnlineConnected {
    $sessions = Get-PSSession | Select-Object -Property State, Name
    $isConnected = (@($sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
    If ($isConnected -ne $True) {
        Get-PSSession | Remove-PSSession
        Connect-ExchangeOnline
    }
}

function GetLicenseAsDictionaryKey([PSCustomObject] $AssignedLicense) {
    # Licenses are either fully enabled or have some service plan features disabled
    # This function just generates a key to represent a distinct license and the features disabled
    $licenseIndexKey = $AssignedLicense.SkuId
    if ($AssignedLicense.DisabledPlans) {
        $licenseIndexKey += ' DisabledPlans'
        $AssignedLicense.DisabledPlans = $AssignedLicense.DisabledPlans | Sort-Object
        $AssignedLicense.DisabledPLans | ForEach-Object { $LicenseIndexKey += ';' + $_ }
    }
    $licenseIndexKey
}

# Exported member functions

class IALicenseGroup {
    [string]$LicenseName
    [string]$SkuPartNumber
    [int]$DisabledPlanCount
    [List[string]] $DisabledPlanNames = [List[string]]::new()
    [int]$UserCount
    [List[string]] $Users = [List[string]]::new()
}

function Get-IAAzureADLicensesWithUsersAsList {
    <#
    .SYNOPSIS
    Returns the Azure AD license information as it applies to users. 
  
    .DESCRIPTION
    Licenses are grouped by their enabled plan features and provide a list of affected users. 
    This is useful when determining how many license plan feature variations are in play.
    
    .EXAMPLE
    Get-IAAzureADLicensesWithUsersAsList

    LicenseName       : Microsoft 365 E3
    SkuPartNumber     : SPE_E3
    DisabledPlanCount : 18
    DisabledPlanNames : {Azure Active Directory Premium P1, Azure Information Protection Premium P1, Azure Rights Management, Cloud App Security Discovery...}
    UserCount         : 1
    Users             : {chris.dymond1@domain.com}

    LicenseName       : Microsoft 365 E3
    SkuPartNumber     : SPE_E3
    DisabledPlanCount : 8
    DisabledPlanNames : {Azure Rights Management, Microsoft Azure Multi-Factor Authentication, Office for the web, Power Apps for Office 365...}
    UserCount         : 2
    Users             : {chris.dymond2@domain.com, chris.dymond3@domain.com}

    LicenseName       : Microsoft Power Automate Free
    SkuPartNumber     : FLOW_FREE
    DisabledPlanCount : 0
    DisabledPlanNames :
    UserCount         : 3
    Users             : {chris.dymond1@domain.com, chris.dymond2@domain.com, chris.dymond3@domain.com}

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([List[IALicenseGroup]])]
    param
    (

    )
    process {
        Assert-AzureADConnected
        $importedSkuIdFriendlyNames = Import-Csv ([System.IO.Path]::Combine($PSScriptRoot, 'resources\SkuIdFriendlyNames.csv'))
        $friendlyLicenseNamesDictionary = [Dictionary[string, string]]::new()
        $importedSkuIdFriendlyNames | ForEach-Object {
            $friendlyLicenseNamesDictionary.Add($_.SkuId, $_.SkuIdFriendlyName)
        }
        $importedPlanIdFriendlyNames = Import-Csv ([System.IO.Path]::Combine($PSScriptRoot, 'resources\PlanIdFriendlyNames.csv'))
        $friendlyPlanNamesDictionary = [Dictionary[string, string]]::new()
        $importedPlanIdFriendlyNames | ForEach-Object {
            $friendlyPlanNamesDictionary.Add($_.PlanId, $_.PlanIdFriendlyName)
        }
        $iaLicenseGroupDictionary = [Dictionary[string, IALicenseGroup]]::new()
        $licensedUsers = [Dictionary[string, DirectoryObject]]::new()
        Get-AzureAdUser -All $true | ForEach-Object {
            $licensed = $False
            For ($i = 0; $i -le ($_.AssignedLicenses | Measure-Object).Count ; $i++) {
                If ( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed = $true } 
            }
            If ($licensed -eq $true) {
                $licensedUsers.Add($_.UserPrincipalName, $_)
                foreach ($assignedLicense in $_.AssignedLicenses) {
                    $licenseWithDisabledPlansKey = GetLicenseAsDictionaryKey($assignedLicense)
                    if ($iaLicenseGroupDictionary.ContainsKey($licenseWithDisabledPlansKey)) {
                        $currentCount = $iaLicenseGroupDictionary[$licenseWithDisabledPlansKey].UserCount
                        $iaLicenseGroupDictionary[$licenseWithDisabledPlansKey].UserCount = $currentCount + 1;
                        $iaLicenseGroupDictionary[$licenseWithDisabledPlansKey].Users.Add($_.UserPrincipalName)
                    }
                    else {
                        $disabledPlanNames = [List[string]]::new()
                        if ($assignedLicense.DisabledPlans) {
                            $assignedLicense.DisabledPlans = $AssignedLicense.DisabledPlans | Sort-Object
                            $assignedLicense.DisabledPlans | ForEach-Object {
                                if ($friendlyPlanNamesDictionary.ContainsKey($_)) {
                                    $disabledPlanNames.Add($friendlyPlanNamesDictionary[$_])
                                }
                                else {
                                    $disabledPlanNames.Add($_)
                                }
                            }
                        }
                        $iaLicenseGroup = [IALicenseGroup]::new()
                        $iaLicenseGroup.DisabledPlanNames = $disabledPlanNames | Sort-Object
                        $iaLicenseGroup.DisabledPlanCount = $disabledPlanNames.Count
                        $iaLicenseGroup.UserCount = 1
                        if ($friendlyLicenseNamesDictionary.ContainsKey($assignedLicense.SkuId)) {
                            $iaLicenseGroup.LicenseName = $friendlyLicenseNamesDictionary[$assignedLicense.SkuId]
                        }
                        $skuPartNumber = Get-IAAzureADLicensesAsList | Where-Object { $_.SkuId -eq $AssignedLicense.SkuId } | Select-Object -ExpandProperty SkuPartNumber
                        $iaLicenseGroup.SkuPartNumber = $skuPartNumber
                        $iaLicenseGroup.Users.Add($_.UserPrincipalName)
                        $iaLicenseGroupDictionary.Add($licenseWithDisabledPlansKey, $iaLicenseGroup)
                    }
                }
            } 
        }
        $licensesWithUsersAsList = $iaLicenseGroupDictionary.GetEnumerator() | ForEach-Object {
            $_.Value | Select-Object LicenseName, SkuPartNumber, DisabledPlanCount, DisabledPlanNames, UserCount, Users
        }
        # CSV formatting - TODO: this will become a Parameter switch 
        # $licensesWithUsersAsList = $iaLicenseGroupDictionary.GetEnumerator() | ForEach-Object {
        #     $_.Value | Select-Object LicenseName, DisabledPlanCount, `
        #     @{name = "DisabledPlans"; expression = { $_.DisabledPlanNames -join ', ' } }, `
        #         UserCount, `
        #     @{name = "Users"; expression = { $_.Users -join ', ' } }
        # }
        $licensesWithUsersAsList
    }
}
Export-ModuleMember -Function Get-IAAzureADLicensesWithUsersAsList

function Get-IAAzureADLicensesAsList {
    <#
    .SYNOPSIS
    Returns the Azure AD license alllocation, including a friendly licensing name (where available) 
  
    .DESCRIPTION
    Shows the SkuId, SkuPartNumber, FriendlyLicenseName, Total, Assigned, Available, Suspended and Warning counts
    
    .EXAMPLE
    Get-IAAzureADLicensesAsList

    SkuId               : 05e9a617-0261-4cee-bb44-138d3ef5d965
    SkuPartNumber       : SPE_E3
    FriendlyLicenseName : Microsoft 365 E3
    Total               : 62
    Assigned            : 60
    Available           : 2
    Suspended           : 0
    Warning             : 0
    
    SkuId               : f30db892-07e9-47e9-837c-80727f46fd3d
    SkuPartNumber       : FLOW_FREE
    FriendlyLicenseName : Microsoft Power Automate Free
    Total               : 10000
    Assigned            : 10
    Available           : 9990
    Suspended           : 0
    Warning             : 0

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([List[PSCustomObject]])]
    param
    (

    )
    process {
        Assert-AzureADConnected
        $importedSkuIdFriendlyNames = Import-Csv ([System.IO.Path]::Combine($PSScriptRoot, "resources\SkuIdFriendlyNames.csv"))
        $friendlyLicenseNamesDictionary = [Dictionary[string, string]]::new()
        $importedSkuIdFriendlyNames | ForEach-Object {
            $friendlyLicenseNamesDictionary.Add($_.SkuId, $_.SkuIdFriendlyName)
        }
        $licenses = Get-AzureADSubscribedSku | Select-Object -Property Sku*, `
        @{N = 'FriendlyLicenseName'; E = { '' } }, `
        @{N = 'Total'; E = { $_.PrepaidUnits.'Enabled' } }, `
        @{N = 'Assigned'; E = { $_.ConsumedUnits } }, `
        @{N = 'Available'; E = { $_.PrepaidUnits.'Enabled' - $_.ConsumedUnits } }, `
        @{N = 'Suspended'; E = { $_.PrepaidUnits.'Suspended' } }, `
        @{N = 'Warning'; E = { $_.PrepaidUnits.'Warning' } }

        $licenses | ForEach-Object {
            if ($friendlyLicenseNamesDictionary.ContainsKey($_.SkuId)) {
                $_.FriendlyLicenseName = $friendlyLicenseNamesDictionary[$_.SkuID]
            }
        }
        $licenses
    }
}
Export-ModuleMember -Function Get-IAAzureADLicensesAsList

function Get-IAAzureADUserLastSignInAsDateTime {
    <#
    .SYNOPSIS
    Returns the last successful sign-in for a user (converted to local time). 

    Note that without a logging solution you are only looking at the last 30 days.
   
    .DESCRIPTION
    Last successful cloud sign-in of a user (up to 30 days)
    
    .EXAMPLE
    Get-IAAzureADUserLastSignInAsDateTime 'chris.dymond@domain.com'

    Sunday, 25 April 2021 3:34:34 PM

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([DateTime])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $UserPrincipalName
    )
    process {
        # Results are returned in order of most recent activity
        # This filter returns only the last successful event.
        $Filter = "userPrincipalName eq '$UserPrincipalName' and status/errorCode eq 0"
        $LastSignIn = Get-AzureADAuditSignInLogs -Filter $Filter | Select-Object -First 1
        if ($null -eq $LastSignIn) {
            Throw "The UserPrincipalName: '$UserPrincipalName' did not return a successful sign-in."
        }
        [DateTime]::ParseExact($LastSignIn.CreatedDateTime, "yyyy-MM-ddTHH:mm:ssZ", $null)
    }
}
Export-ModuleMember -Function Get-IAAzureADUserLastSignInAsDateTime

function Get-IAAzureADGuestUserDomainsAsDictionary {
    <#
    .SYNOPSIS
    Returns the number of Guest (B2B) domains in the tenant.
   
    .DESCRIPTION
    Guests counts are group according to domain. 
    ie. where there are are two B2B users with user1@domain.com and user2@domain.com they will appear
    as a count of '2' under domain.com
    
    .EXAMPLE
    Get-IAAzureADGuestUserDomainsAsDictionary

    Key                 Value
    ---                 -----
    chrisdymond.org         1
    chris.org              10
    chris.net              13
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([Dictionary[String, Int32]])]
    param
    (

    )
    process {
        Assert-AzureADConnected
        $users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true
        $b2bDomains = [Dictionary[String, Int32]]::new()
        foreach ($user in $users) {
            # Mail is not always populated
            # UPN will be used to ascertain the host tenant
            # chris.dymond_something.com.au#EXT#@x.onmicrosoft.com
            # chris_dymond_something.com.au#EXT#@x.onmicrosoft.com
            $userPrincipalName = $user.UserPrincipalName
            $b2bDomain = ($userPrincipalName.Split('#')[0].Split('_')[$userPrincipalName.Split('#')[0].Split('_').Count - 1]).ToLower()
            if ($b2bDomains.ContainsKey($b2bDomain)) {
                $b2bDomains[$b2bDomain]++
            }
            else {
                $b2bDomains.Add($b2bDomain, 1)
            }
        }
        $b2bDomains.GetEnumerator() | Sort-Object
    }
}
Export-ModuleMember -Function Get-IAAzureADGuestUserDomainsAsDictionary

class IAUser {
    [string]$UserPrincipalName
    [string]$Enabled
    [string]$Mail
    [string]$UserType
    [string]$RecipientType
    [string]$OnPremisesSyncEnabled = $true
}

function Get-IAAzureADUsersAsList {
    <#
    .SYNOPSIS
    Provides a complete list of user accounts in the tenant.
    The results are tagged with a UserType.
    
    UserTypes include: User, B2B and Exchange objects.
    
    .DESCRIPTION
    Users that are attached to another mailbox type (not a 'user' mailbox) have their UserType adjusted to 'Exchange'
    This makes a clear distinction from a person and a role or resource account in Exchange Online.
    UPNs, Enabled state, Mail, UserType, MailboxType and a flag for on-premise synchronisation are included. 
    
    .EXAMPLE
    Get-IAAzureADUsersAsList

    UserPrincipalName     : chris.dymond@domain.com
    Enabled               : True
    Mail                  : chris.dymond@domain.com
    UserType              : User
    RecipientType         : UserMailbox
    OnPremisesSyncEnabled : True

    UserPrincipalName     : BoardRoom@chrisdymond.onmicrosoft.com
    Enabled               : True
    Mail                  : BoardRoom@domain.com
    UserType              : Exchange
    RecipientType         : RoomMailbox
    OnPremisesSyncEnabled : False

    
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([List[IAUser]])]
    param
    (

    )
    process {
        Assert-AzureADConnected
        Assert-ExchangeOnlineConnected
        $iaUsersList = [List[IAUser]]::new()
        $azureADUsers = Get-AzureADUser -All $True
        $mailboxAccounts = Get-EXOMailbox -ResultSize Unlimited
        $azureADUsers | ForEach-Object {
            $iaUser = [IAUser]::new()
            $iaUser.UserPrincipalName = $_.UserPrincipalName
            $iaUser.Enabled = $_.AccountEnabled
            $iaUser.Mail = $_.Mail
            switch ($_.UserType) {
                "Member" { $iaUser.UserType = "User"; break }
                "Guest" { $iaUser.UserType = "B2B"; break }
                Default { throw "Unhandled UserType" }
            }
            $mailbox = [Linq.Enumerable]::FirstOrDefault([Linq.Enumerable]::Where($mailboxAccounts, `
                        [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
                ))
            if ($mailbox) {
                $iaUser.RecipientType = $mailbox.RecipientTypeDetails
                if ($iaUSer.RecipientType -ne 'RemoteUserMailbox' -or 'UserMailbox') {
                    $iaUser.UserType = 'Exchange Resource'
                }
            }
            if ($_.DirSyncEnabled -ne $true) {
                $iaUser.OnPremisesSyncEnabled = $false
            }
            $iaUsersList.Add($iaUser)
        }
        $iaUsersList | Sort-Object DisplayName
    }
}
Export-ModuleMember -Function Get-IAAzureADUsersAsList

class IAGroup {
    [string]$DisplayName
    [string]$Mail
    [string]$Type
    [string]$OnPremisesSyncEnabled
    [string]$Owners
}

function Get-IAAzureADGroupsAsList {
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
Export-ModuleMember -Function Get-IAAzureADGroupsAsList
