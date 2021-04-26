# Azure AD

## Licenses

### Get-IAAzureADLicensesAsList

Presents the current licensing for the tenant.

```powershell
<#
    .SYNOPSIS
    Returns the Azure AD licensing summary, including a friendly licensing name per SkuID (where available)

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
```

### Get-IAAzureADLicensesWithUsersAsList

Returns the Azure AD licenses as they apply to users.
Licenses are grouped by their enabled features.

```powershell
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
```

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
