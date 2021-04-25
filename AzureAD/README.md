# Azure AD

## Users

### Get-IAAzureADUsersAsList

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
```

### Get-IAAzureADGuestUserDomainsAsDictionary

Returns a dictionary summation of Guests in Azure AD grouped by their domain.

```powershell
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
```

### Get-IAAzureADUserLastSignInAsDateTime

Returns the last successful date/time of an Azure log on.

```powershell
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
```

## Groups

### Get-IAAzureADGroupsAsList

Returns a list of all groups in Azure AD. A flag denotes those synchronsied from on-premise.

```powershell
    <#
    .SYNOPSIS
    Returns a list of all groups in Azure AD.

    .DESCRIPTION
    Returns the Display Name, Mail (if present), Type (Microsoft 365, Security or Distribution),
    whether the group is synchronised from on-premise and a list of group owners (where defined in Azure)

    .EXAMPLE
    Get-IAAzureADGroupsAsList

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
