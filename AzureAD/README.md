# Azure AD

## Users

### Get-IAAzureADUsers

Returns a list of all users in Azure AD. A flag denotes those synchronsied from on-premise.

```powershell
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
    Get-IAAzureADUsers

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
```

## Groups

### Get-IAAzureADGroups

Returns a list of all groups in Azure AD. A flag denotes those synchronsied from on-premise.

```powershell
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
```
