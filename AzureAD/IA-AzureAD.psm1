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


function Assert-ExchangeOnlineConnected {
    $sessions = Get-PSSession | Select-Object -Property State, Name
    $isConnected = (@($sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
    If ($isConnected -ne $True) {
        Get-PSSession | Remove-PSSession
        Connect-ExchangeOnline
    }
}

# Exported member functions

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
