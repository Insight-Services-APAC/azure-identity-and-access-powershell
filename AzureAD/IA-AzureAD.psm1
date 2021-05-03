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

function Get-LicenseAssignmentAsDictionaryKey([PSCustomObject] $AssignedLicense) {
    # Licenses are either fully enabled or have some service plan features disabled
    # This function just generates a key to represent a distinct license and the features disabled
    $licenseIndexKey = $AssignedLicense.SkuId
    if ($AssignedLicense.DisabledPlans) {
        $licenseIndexKey += ' DisabledPlans'
        $AssignedLicense.DisabledPlans = $AssignedLicense.DisabledPlans | Sort-Object
        $AssignedLicense.DisabledPLans | ForEach-Object { $LicenseIndexKey += ';' + $_ }
    }
    if ($AssignedLicense.AppliedByGroups) {
        $licenseIndexKey += ' Groups'
        $AssignedLicense.AppliedByGroups = $AssignedLicense.AppliedByGroups | Sort-Object
        $AssignedLicense.AppliedByGroups | ForEach-Object { $LicenseIndexKey += ';' + $_ }
    }
    if ($AssignedLicense.AppliedDirectly) {
        $licenseIndexKey += ' Direct'
    }
    $licenseIndexKey
}


function Send-MSGraphGetRequest {
    [CmdletBinding()]
    [OutputType([List[PSCustomObject]])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $GraphUrl
    )
    process {
        Get-AzureADMSAdministrativeUnit -Top 1 | Out-Null # Just to ensure we have a graph.microsoft.com token (not just a graph.windows.net one)
        $graphToken = [AzureSession]::TokenCache.ReadItems() | `
            Where-Object { $_.Resource -eq 'https://graph.microsoft.com' } | Select-Object AccessToken
        if ($null -eq $graphToken) {
            throw "The Graph Access token is not available!"
        }
        $graphRequest = @{
            Uri     = $GraphUrl
            Headers = @{
                'Authorization' = "Bearer $($graphToken.AccessToken)" 
            }
            Method  = 'GET'
        }
        $resultList = [List[PSCustomObject]]::new()
        $response = Invoke-RestMethod @graphRequest
        $response.Value | ForEach-Object {
            $resultList.Add($_)
        }
        while ($null -ne $response.'@odata.nextLink') {
            $graphRequest.Uri = $response.'@odata.nextLink' 
            $response = Invoke-RestMethod @graphRequest
            $response.Value | ForEach-Object {
                $resultList.Add($_)
            }   
        }
        $resultList
    }
}

# Exported member functions

function Experimental {
    Assert-AzureADConnected
    # Get the names and ids of groups that have assigned license plans
    $attributesToSelect = @(
        'id'
        'licenseAssignmentStates'
    )
    $selectData = $attributesToSelect -join ','
    $graphUri = 'https://graph.microsoft.com/beta/users?$select=' + $selectData
    Send-MSGraphGetRequest $graphUri | Where-Object { $_.licenseAssignmentStates.Count -gt 0 }
}
Export-ModuleMember -Function Experimental

class IALicenseGroup {
    [string]$LicenseName
    [string]$SkuPartNumber
    [int]$DisabledPlanCount
    [List[string]]$DisabledPlanNames = [List[string]]::new()
    [bool]$DirectAssignmentPath
    [List[string]]$InheritedAssignmentPaths = [List[string]]::new()
    [int]$UserCount
    [List[string]]$Users = [List[string]]::new()
}

function Get-IAAzureADLicensesWithUsersAsList {
    <#
    .SYNOPSIS
    Returns the Azure AD license information as it applies to users. 
  
    .DESCRIPTION
    Licenses are grouped by their enabled plan features and provide a list of affected users. 
    This is useful when determining how many license plan feature variations are in play.
    
    ---Updates---

    -Added license assignment paths via Graph

    -Added optional parameter
    -ExportToCsv $true

    .EXAMPLE
    Get-IAAzureADLicensesWithUsersAsList -ExportToCsv $true

    LicenseName              : Microsoft 365 E3
    SkuPartNumber            : SPE_E3
    DisabledPlanCount        : 8
    DisabledPlanNames        : {Azure Rights Management, Microsoft Azure Multi-Factor Authentication, Office for the web, Power Apps for Office 365...}
    DirectAssignmentPath     : False
    InheritedAssignmentPaths : {Some Group - O365, Another Group - O365}
    UserCount                : 1
    Users                    : {chris.dymond@domain.com}

    LicenseName              : Microsoft 365 E3
    SkuPartNumber            : SPE_E3
    DisabledPlanCount        : 18
    DisabledPlanNames        : {Azure Active Directory Premium P1, Azure Information Protection Premium P1, Azure Rights Management, Cloud App Security Discovery...}
    DirectAssignmentPath     : True
    InheritedAssignmentPaths : {}
    UserCount                : 2
    Users                    : {chris.dymond2@domain.com, chris.dymond3@domain.com}

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([List[IALicenseGroup]])]
    param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [bool] $ExportToCsv = $false
    )
    process {
        Assert-AzureADConnected
        $attributesToSelect = @(
            'id'
            'displayName'
            'assignedLicenses'
        )
        $selectData = $attributesToSelect -join ','
        $graphUri = 'https://graph.microsoft.com/beta/groups?$select=' + $selectData
        $groupsWithAssignedLicenses = Send-MSGraphGetRequest $graphUri | Where-Object { $_.AssignedLicenses.Count -gt 0 }
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
        $licensedUsers = [Dictionary[string, PSCustomObject]]::new()
        $attributesToSelect = @(
            'id'
            'userPrincipalName'
            'licenseAssignmentStates'
            'assignedLicenses'
        )
        $selectData = $attributesToSelect -join ','
        $graphUrl = 'https://graph.microsoft.com/beta/users?$select=' + $selectData
        Send-MSGraphGetRequest $graphUrl | ForEach-Object {
            $licensed = $False
            For ($i = 0; $i -le ($_.AssignedLicenses | Measure-Object).Count ; $i++) {
                If ( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed = $true } 
            }
            If ($licensed -eq $true) {
                $licensedUsers.Add($_.UserPrincipalName, $_)
                
                foreach ($assignedLicense in $_.AssignedLicenses) {
                    $groupAssignedSku = [Linq.Enumerable]::ToList([Linq.Enumerable]::Where($_.licenseAssignmentStates, `
                                [Func[Object, bool]] { param($x); return ($x.SkuId -eq $assignedLicense.SkuId) `
                                    -and ($x.state -eq 'Active') `
                                    -and ($null -ne $x.assignedByGroup) }
                        ))
                    $directAssignedSku = [Linq.Enumerable]::FirstorDefault([Linq.Enumerable]::Where($_.licenseAssignmentStates, `
                                [Func[Object, bool]] { param($x); return ($x.SkuId -eq $assignedLicense.SkuId) `
                                    -and ($x.state -eq 'Active') `
                                    -and ($null -eq $x.assignedByGroup) }
                        ))
    
                    if ($groupAssignedSku) {
                        $appliedGroups = $groupAssignedSku | Select-Object -ExpandProperty assignedByGroup
                        $assignedLicense | Add-Member -NotePropertyName AppliedByGroups -NotePropertyValue $appliedGroups
                    }
    
                    if ($directAssignedSku) {
                        $assignedLicense | Add-Member -NotePropertyName AppliedDirectly -NotePropertyValue $true
                    }
    
                    $licenseWithDisabledPlansKey = Get-LicenseAssignmentAsDictionaryKey($assignedLicense)
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
                        if ($assignedLicense.AppliedDirectly) {
                            $iaLicenseGroup.DirectAssignmentPath = $true
                        }
                        else {
                            $iaLicenseGroup.DirectAssignmentPath = $false
                        }
                        if ($groupAssignedSku) {
                            $groupAssignedSku | ForEach-Object {
                                $groupName = ([Linq.Enumerable]::FirstOrDefault([Linq.Enumerable]::Where($groupsWithAssignedLicenses, `
                                                [Func[Object, bool]] { param($x); return ($x.id -eq $_.assignedByGroup) }
                                        ))  | Select-Object -ExpandProperty displayName)
                                $iaLicenseGroup.InheritedAssignmentPaths.Add($groupName)
                            }
                        }
                        $iaLicenseGroup.Users.Add($_.UserPrincipalName)
                        $iaLicenseGroupDictionary.Add($licenseWithDisabledPlansKey, $iaLicenseGroup)
                    }
                }
            } 
        }
        $licensesWithUsersAsList = $iaLicenseGroupDictionary.GetEnumerator() | ForEach-Object {
            $_.Value | Select-Object LicenseName, SkuPartNumber, DisabledPlanCount, DisabledPlanNames, DirectAssignmentPath, InheritedAssignmentPaths, UserCount, Users
        }

        if ($ExportToCsv) {
            $licensesWithUsersAsList | ForEach-Object {
                $_ | Select-Object LicenseName, DisabledPlanCount, `
                @{name = "DisabledPlans"; expression = { $_.DisabledPlanNames -join ', ' } }, `
                    DirectAssignmentPath, 
                @{name = "InheritedAssignmentPaths"; expression = { $_.InheritedAssignmentPaths -join ', ' } }, `
                    UserCount, `
                @{name = "Users"; expression = { $_.Users -join ', ' } }
            } | Export-Csv "Licenses assigned to users $($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
        }
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

    ---Updates---

    -Added optional parameter
    -ExportToCsv $true

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

    Get-IAAzureADLicensesAsList -ExportToCsv $true

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([List[PSCustomObject]])]
    param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [bool] $ExportToCsv = $false
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
        if ($ExportToCsv) {
            $licenses | Export-Csv "Licenses$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
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
    [List[string]]$ProxyAddresses = [List[string]]::new()
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
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [bool] $ExportToCsv = $false
    )
    process {
        Assert-AzureADConnected
        Assert-ExchangeOnlineConnected
        $iaUsersList = [List[IAUser]]::new()
        $azureADUsers = Get-AzureADUser -All $True
        $exoRecipients = Get-EXORecipient -ResultSize Unlimited -Filter "(RecipientType -eq 'MailUser') -or (RecipientType -eq 'UserMailbox')"
        $azureADUsers | ForEach-Object {
            $iaUser = [IAUser]::new()
            $iaUser.UserPrincipalName = $_.UserPrincipalName
            $iaUser.Enabled = $_.AccountEnabled
            $iaUser.Mail = $_.Mail
            switch ($_.UserType) {
                'Member' { $iaUser.UserType = 'User'; break }
                'Guest' { $iaUser.UserType = 'B2B'; break }
                Default { throw 'Unhandled UserType' }
            }
            $exoRecipient = [Linq.Enumerable]::FirstOrDefault([Linq.Enumerable]::Where($exoRecipients, `
                        [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
                ))
            if ($exoRecipient) {
                $iaUser.Mail = $exoRecipient.PrimarySmtpAddress
                $iaUser.RecipientType = $exoRecipient.RecipientTypeDetails
                $iaUser.ProxyAddresses = $exoRecipient.EmailAddresses
                if ($iaUser.RecipientType -notmatch 'RemoteUserMailbox' -and $iaUser.RecipientType -notmatch 'UserMailbox') {
                    if ($iaUser.UserType -ne 'B2B') { $iaUser.UserType = 'Exchange' }
                }
            }
            if ($null -eq $exoRecipient -and $_.UserType -eq 'Member') { $iaUser.UserType = 'User (No Mailbox)' }
            if ($_.DirSyncEnabled -ne $true) {
                $iaUser.OnPremisesSyncEnabled = $false
            }
            $iaUsersList.Add($iaUser)
        }

        if ($ExportToCsv) {
            $iaUsersList | ForEach-Object {
                $_ | Select-Object UserPrincipalName, Enabled, Mail, `
                @{name = "ProxyAddresses"; expression = { $_.ProxyAddresses -join ', ' } }, `
                    UserType, RecipientType, OnPremisesSyncEnabled
            } | Export-Csv "Users$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
        }

        $iaUsersList | Sort-Object DisplayName
    }
}
Export-ModuleMember -Function Get-IAAzureADUsersAsList

class IAGroup {
    [string]$DisplayName
    [string]$Mail
    [List[string]]$ProxyAddresses = [List[String]]::new()
    [List[string]]$Type = [List[string]]::new()
    [string]$OnPremisesSyncEnabled
    [string]$EXORecipientType
    [string]$EXORecipientTypeDetails
    [List[string]]$Owners = [List[string]]::new()
}

function Get-IAAzureADGroupsAsList {
    <#
    .SYNOPSIS
    Returns a list of all groups in Azure AD.
    
    .DESCRIPTION
    Returns the Display Name, Mail (if present), Type (Microsoft 365, Security, Mail-Enabled Security or Distribution),
    whether the group is synchronised from on-premise and a list of group owners (where defined in Azure)
    It will also include whether the group is used to apply licensing.
    
    Optional parameter
    -ExportToCsv:$true

    .EXAMPLE
    Get-IAAzureADGroups

    DisplayName           : Chris' Security Group
    Mail                  :
    ProxyAddresses        : {}
    Type                  : {Security, Licensing}
    OnPremisesSyncEnabled : True
    Owners                : {}


    DisplayName           : Chris' M365 Group
    Mail                  : ChrisGroup@domain.onmicrosoft.com
    ProxyAddresses        : {}
    Type                  : {Microsoft 365}
    OnPremisesSyncEnabled : False
    Owners                : {chris.dymond@domain.com}
    
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([List[IAGroup]])]
    param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [bool] $ExportToCsv = $false
    )
    process {
        Assert-AzureADConnected
        Assert-ExchangeOnlineConnected

        # Retrieve Group Recipients
        $exoRecipientTypes = @(
            'DynamicDistributionGroup',
            'MailNonUniversalGroup',
            'MailUniversalDistributionGroup',
            'MailUniversalSecurityGroup')
        $exoGroupsFilterTemplate = "(recipientType -eq 'value')"
        $exoGroupsFilter = ''
        for ($i = 0; $i -lt $exoRecipientTypes.Count; $i++) {
            if ($i -eq 0) {
                $exoGroupsFilter = $exoGroupsFilterTemplate.Replace('value', $exoRecipientTypes[$i])
            }
            else {
                $exoGroupsFilter += " -or " + $exoGroupsFilterTemplate.Replace('value', $exoRecipientTypes[$i])
            }
        }
        $exoGroupRecipients = Get-EXORecipient -ResultSize Unlimited -Filter $exoGroupsFilter

        # Get the names and ids of groups that have assigned license plans
        $attributesToSelect = @(
            'id'
            'assignedLicenses'
        )
        $selectData = $attributesToSelect -join ','
        $graphUri = 'https://graph.microsoft.com/beta/groups?$select=' + $selectData
        $licensingGroups = Send-MSGraphGetRequest $graphUri | Where-Object { $_.AssignedLicenses.Count -gt 0 }

        $iaGroupList = [List[IAGroup]]::new()
        $groups = Get-AzureADMSGroup -All $true
        $groups | ForEach-Object {
            $onPremisesSyncEnabled = $false
            if ($_.OnPremisesSyncEnabled -eq $true) {
                $onPremisesSyncEnabled = $true
            }
            [IAGroup] $iaGroup = [IAGroup]::new()
            $iaGroup.OnPremisesSyncEnabled = $onPremisesSyncEnabled
            $iaGroup.Owners = Get-AzureADGroupOwner -ObjectId $_.Id -All $true | Select-Object -ExpandProperty UserPrincipalName
            $iaGroup.DisplayName = $_.DisplayName
            $iaGroup.Mail = $_.Mail
            If ($_.GroupTypes -contains "Unified") {
                $iaGroup.Type.Add("Microsoft 365")
            }
            elseif ($_.SecurityEnabled -and $_.MailEnabled -eq $false  ) {
                $iaGroup.Type.Add("Security")  
            }
            elseif ($_.SecurityEnabled -and $_.MailEnabled ) {
                $iaGroup.Type.Add("Mail-Enabled Security")  
            }
            else {
                $iaGroup.Type.Add("Distribution")
            }
            If ($_.GroupTypes -contains "DynamicMembership") {
                $iaGroup.Type.Add("Dynamic")
            }
            if ($licensingGroups.Id -contains $_.id) {
                $iaGroup.Type.Add("Licensing")
            }

            $exoGroupRecipient = [Linq.Enumerable]::FirstOrDefault([Linq.Enumerable]::Where($exoGroupRecipients, `
                        [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.Id }
                ))
            if ($exoGroupRecipient) {
                $iaGroup.Mail = $exoGroupRecipient.PrimarySmtpAddress
                $iaGroup.ProxyAddresses = $exoGroupRecipient.EmailAddresses
                $iaGroup.EXORecipientType = $exoGroupRecipient.RecipientType
                $iaGroup.EXORecipientTypeDetails = $exoGroupRecipient.RecipientTypeDetails
            }    

            $iaGroupList.Add($iaGroup)
        }
        $iaGroupList | Sort-Object Displayname
        if ($ExportToCsv) {
            $iaGroupList | ForEach-Object {
                $_ | Select-Object DisplayName, Mail, `
                @{name = "ProxyAddresses"; expression = { $_.ProxyAddresses -join ', ' } }, `
                @{name = "Type"; expression = { $_.Type -join ', ' } }, `
                    OnPremisesSyncEnabled, 
                @{name = "Owners"; expression = { $_.Owners -join ', ' } }
            } | Export-Csv "Groups$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
        }
    }
}
Export-ModuleMember -Function Get-IAAzureADGroupsAsList

class IAAppServicePrincipal {
    [string]$ObjectId
    [string]$AppId
    [bool]$AccountEnabled
    [string]$DisplayName
    [string]$AuthenticationType
    [string]$PublisherName
    [string]$ServicePrincipalType
    [List[string]]$AssignedUsers = [List[string]]::new()
    [List[string]]$AssignedGroups = [List[string]]::new()
    [List[string]]$AssignedPrincipalTypes = [List[string]]::new()
    [List[string]]$ReplyUrls = [List[string]]::new()
    [List[string]]$Tags = [List[String]]::new()
    [List[string]]$IdentifierUris = [List[String]]::new()
    [string]$SignInAudience
    
}

function Get-IAAzureADAppServicePrincipals() {
    <#
    .SYNOPSIS
    Returns a list of all Application Service Principals
    
    .DESCRIPTION
    Returns a list of all application service principals within the tenant. This includes authentication type OAuth/SAML
    as well assigned users/groups and other information where an app registration is available.

    -ExportToCsv:$true (optional)

    .EXAMPLE
    Get-IAAzureADAppServicePrincipals

    ...
    ObjectId               : 
    AppId                  : 
    AccountEnabled         : True
    DisplayName            : App Name
    AuthenticationType     : SAML
    PublisherName          : Tenant or Third Party Name
    ServicePrincipalType   : Application
    AssignedUsers          : {chris.dymond@domain.com...}
    AssignedGroups         :
    AssignedPrincipalTypes : {User}
    ReplyUrls              : {https://myapp.domain.com/__login__/saml/}
    Tags                   : {WindowsAzureActiveDirectoryIntegratedApp,
                             WindowsAzureActiveDirectoryGalleryApplicationPrimaryV1}
    IdentifierUris         : {https://myapp.domain.com/__login__/saml/}
    SignInAudience         : AzureADMyOrg
    ...

    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([List[IAUser]])]
    param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [bool] $ExportToCsv = $false
    )
    process {
        Assert-AzureADConnected
        $iaAppServicePrincipalList = [List[IAAppServicePrincipal]]::new()
        Get-AzureADServicePrincipal -All $true | Where-Object { $_.Tags -contains "WindowsAzureActiveDirectoryIntegratedApp" } | ForEach-Object {
            $iaAppServicePrincipal = [IAAppServicePrincipal]::new()
            $iaAppServicePrincipal.ObjectId = $_.ObjectId
            $iaAppServicePrincipal.AppId = $_.AppId
            $iaAppServicePrincipal.AccountEnabled = $_.AccountEnabled
            $iaAppServicePrincipal.ServicePrincipalType = $_.ServicePrincipalType
            $iaAppServicePrincipal.DisplayName = $_.DisplayName
            $iaAppServicePrincipal.PublisherName = $_.PublisherName
            $iaAppServicePrincipal.ReplyUrls = $_.ReplyUrls
            $iaAppServicePrincipal.Tags = $_.Tags

            if ($_.Tags -contains 'WindowsAzureActiveDirectoryGalleryApplicationPrimaryV1' -or `
                    $_.Tags -contains 'WindowsAzureActiveDirectoryCustomSingleSignOnApplication') {
                $iaAppServicePrincipal.AuthenticationType = 'SAML'
            }
            else {
                $iaAppServicePrincipal.AuthenticationType = 'OAuth'
            }

            $tenantApp = Get-AzureADApplication -Filter "AppId eq '$($_.AppId)'"
            if ($tenantApp) {
                $iaAppServicePrincipal.IdentifierUris = $tenantApp.IdentifierUris
                $iaAppServicePrincipal.SignInAudience = $tenantApp.SignInAudience
            }

            $ServiceAppRoleAssignment = $_ | Get-AzureADServiceAppRoleAssignment 

            $UserPrincipals = $ServiceAppRoleAssignment | Where-Object { $_.PrincipalType -eq 'User' } | Select-Object PrincipalId
            $UserPrincipalNames = [List[string]]::new()
            $UserPrincipals | ForEach-Object {
                $UserPrincipalName = Get-AzureADUser -ObjectId $_.PrincipalId | Select-Object -ExpandProperty UserPrincipalName
                $UserPrincipalNames.Add($UserPrincipalName)
            }
            $iaAppServicePrincipal.AssignedUsers = $UserPrincipalNames 
            $iaAppServicePrincipal.AssignedGroups = ($ServiceAppRoleAssignment | Where-Object { $_.PrincipalType -ne 'User' } `
                | Select-Object -Unique -ExpandProperty PrincipalDisplayName )
            $iaAppServicePrincipal.AssignedPrincipalTypes = ($ServiceAppRoleAssignment | Select-Object -Unique -ExpandProperty PrincipalType)
            $iaAppServicePrincipalList.Add($iaAppServicePrincipal)
        }
        if ($ExportToCsv) {
            $iaAppServicePrincipalList | Sort-Object DisplayName | ForEach-Object {
                $_ | Select-Object ObjectId, AppId, DisplayName, AccountEnabled, AuthenticationType, PublisherName, ServicePrincipalType, `
                @{name = "AssignedUsers"; expression = { $_.AssignedUsers -join ', ' } }, `
                @{name = "AssignedGroups"; expression = { $_.AssignedGroups -join ', ' } }, `
                @{name = "AssignedPrincipalTypes"; expression = { $_.AssignedPrincipalTypes -join ', ' } }, `
                @{name = "ReplyUrls"; expression = { $_.ReplyUrls -join ', ' } }, `
                @{name = "IdentifierUris"; expression = { $_.IdentifierUris -join ', ' } }, `
                    SignInAudience, `
                @{name = "Tags"; expression = { $_.Tags -join ', ' } } 
            } | Export-Csv "AppServicePrincipals$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
        }
        $iaAppServicePrincipalList
    }
}
Export-ModuleMember -Function Get-IAAzureADAppServicePrincipals