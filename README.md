# Overview

Hello and welcome,

I am a Cloud Technical Specialist at [Insight](https://au.insight.com/en_AU/home.html).
I have written this repository to provide clear (scenario-based) cmdlets that both extend and demonstrate the use of the 'Azure AD Preview' and 'Exchange Online Management' modules.

Using these prebuilt functions, you will be able to answer common queries related to:

- Licensing
- Exchange Online; and
- Users and Groups

Please note that this module is a work in progress and will change quite often.

# Updates

02-05-21 - Added App Service Principal extraction

27-04-21 - Added license assignment paths

## Backlog

- Custom MS Graph Calls :
  - Read MFA status, to achieve similiar results to MSOnline (msol) cmdlets

Author: Chris Dymond

chris.dymond@insight.com

[https://www.linkedin.com/in/chris-dymond](https://www.linkedin.com/in/chris-dymond)

# Using the IA module

To use any of these cmdlets you must import this module.

```powershell
Import-Module .\IA.psd1
```

As this library will make extensive use of both AzureADPreview and ExchangeManagementOnline, it is a requirement that these two modules are installed.

```powershell
Install-Module AzureADPreview
Install-Module ExchangeOnlineManagement
```

Where a specific feature is not exposed by these modules, a native Graph API call may suffice and be included in the IA module.

# Contents

## Exchange Online

- [Recipients](#recipients)

  - [Get-IAEXORecipientsOnMicrosoftAsList](#get-iaexorecipientsonmicrosoftaslist)
  - [Get-IAEXORecipientsAsDictionary](#get-iaexorecipientsasdictionary)

## Azure AD

- [Licensing](#licensing)

  - [Get-IAAzureADLicensesAsList](#get-iaazureadlicensesaslist)
  - [Get-IAAzureADLicensesWithUsersAsList](#get-iaazureadlicenseswithusersaslist)

- [Users](#users)

  - [Get-IAAzureADUsersAsList](#get-iaazureadusersaslist)
  - [Get-IAAzureADGuestUserDomainsAsDictionary](#get-iaazureadguestuserdomainsasdictionary)
  - [Get-IAAzureADUserLastSignInAsDateTime](#get-iaazureaduserlastsigninasdatetime)

- [Groups](#groups)

  - [Get-IAAzureADGroupsAsList](#get-iaazureadgroupsaslist)

- [Service Principals](#service-principals)

  - [Get-IAAzureADAppServicePrincipals](#get-iaazureadappserviceprincipals)

## Miscellaneous

- [New-IAComplexPassword](#new-iacomplexpassword)

# Exchange Online

## Recipients

### Get-IAEXORecipientsOnMicrosoftAsList

This will retrieve all Exchange Online recipients with the @tenant.onmicrosoft.com proxyAddress

```powershell
  $Results = Get-IAEXORecipientsOnMicrosoftAsList
  $Results
```

```
...
ExternalDirectoryObjectId : ...
Identity                  : Chris Dymond
Alias                     : Chris.Dymond
EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
DisplayName               : Chris Dymond
Name                      : Chris Dymond
PrimarySmtpAddress        : Chris.Dymond@domain.com
RecipientType             : UserMailbox
RecipientTypeDetails      : UserMailbox
ExchangeVersion           : 0.20 (15.0.0.0)
DistinguishedName         : CN=...
OrganizationId            : ...
...
```

### Get-IAEXORecipientsAsDictionary

This will retrieve all Exchange Online recipients and index them by their recipient recipientTypeDetail.

It includes combined size (where applicable)

```powershell
  $Results = Get-IAEXORecipientsAsDictionary
  $Results
```

```
  Key                            Value
  ---                            -----
  UserMailbox                    IARecipients
  RoomMailbox                    IARecipients
  MailUsers                      IARecipients
```

```powershell
  $Results['UserMailbox']
```

```
  CombinedSizeInGB Recipients
  ---------------- ----------
  725.87           {@{ExternalDirectoryObjectId=....
```

```powershell
  $Results['UserMailbox'].Recipients
```

```
...
ExternalDirectoryObjectId :
Identity : Chris Dymond
Alias : Chris.Dymond
EmailAddresses : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
DisplayName : Chris Dymond
Name : Chris Dymond
PrimarySmtpAddress : Chris.Dymond@domain.com
RecipientType : UserMailbox
RecipientTypeDetails : UserMailbox
ExchangeVersion : 0.20 (15.0.0.0)
DistinguishedName : CN=
OrganizationId :
TotalItemSize : 1.243 GB (1,334,578,302 bytes)
TotalItemSizeInGB : 1.24
...
```

# [Azure AD](AzureAD/README.md)

## Licensing

### Get-IAAzureADLicensesAsList

This returns this list of licenses and their current allocation.

A referenced CSV includes the SkuId to Friendly Name conversion.

#### Updates

- Optional parameter
  ` -ExportToCsv:$true`

```powershell
    Get-IAAzureADLicensesAsList
```

```
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
```

### Get-IAAzureADLicensesWithUsersAsList

This cmdlet returns all licensing as it applies to individual accounts. The results will be grouped according to plan features disabled and their assignment path (direct or inherited via group).

#### Updates

- Added license assignment paths via Graph (Direct or inherited)

- Optional parameter
  ` -ExportToCsv:$true`

```powershell
Get-IAAzureADLicensesWithUsersAsList
```

```
    ...
    LicenseName              : Microsoft 365 E3
    SkuPartNumber            : SPE_E3
    DisabledPlanCount        : 8
    DisabledPlanNames        : {Azure Rights Management, Microsoft Azure Multi-Factor Authentication,...}
    DirectAssignmentPath     : False
    InheritedAssignmentPaths : {Some Group - O365, Another Group - O365}
    UserCount                : 1
    Users                    : {chris.dymond@domain.com}

    LicenseName              : Microsoft 365 E3
    SkuPartNumber            : SPE_E3
    DisabledPlanCount        : 18
    DisabledPlanNames        : {Azure Active Directory Premium P1, Azure Information Protection Premium P1,...}
    DirectAssignmentPath     : True
    InheritedAssignmentPaths : {}
    UserCount                : 2
    Users                    : {chris.dymond2@domain.com, chris.dymond3@domain.com}
    ...
```

## Users

### Get-IAAzureADUsersAsList

The standard Get-AzureADUsers cmdlet returns all accounts including shared mailboxes and resources.
This function returns the same set of users but classifies them as either User, B2B or Exchange (short for Exchange Online).

- Optional parameter
  ` -ExportToCsv:$true`

```powershell
    Get-IAAzureADUsersAsList
```

```
    UserPrincipalName     : chris.dymond@domain.com
    Enabled               : True
    Mail                  : chris.dymond@domain.com
    ProxyAddresses        : {}
    UserType              : User
    RecipientType         : UserMailbox
    OnPremisesSyncEnabled : True

    UserPrincipalName     : BoardRoom@chrisdymond.onmicrosoft.com
    Enabled               : True
    Mail                  : BoardRoom@domain.com
    ProxyAddresses        : {}
    UserType              : Exchange
    RecipientType         : RoomMailbox
    OnPremisesSyncEnabled : False
```

### Get-IAAzureADGuestUserDomainsAsDictionary

Returns the count of Guest users by their domain.

```powershell
    Get-IAAzureADGuestUserDomainsAsDictionary
```

```
    Key                 Value
    ---                 -----
    chrisdymond.org         1
    chris.org              10
    chris.net              13
```

### Get-IAAzureADUserLastSignInAsDateTime

Returns the last successful time a user authenticated to Azure.

(Adjusted to local time)

```powershell
    Get-IAAzureADUserLastSignInAsDateTime 'chris.dymond@domain.com'
```

```
    Sunday, 25 April 2021 3:34:34 PM
```

## Groups

### Get-IAAzureADGroupsAsList

This returns a list of all groups. It includes the type: Security, Mail-Enabled Security, Distribution and Microsoft 365. It also includes whether the group is dynamic or is used for licensing.

- Optional parameter
  ` -ExportToCsv:$true`

```powershell
    Get-IAAzureADGroups
```

```
    DisplayName           : Chris' Security Group
    Mail                  :
    ProxyAddresses        : {}
    Type                  : Security, Licensing
    OnPremisesSyncEnabled : True
    Owners                :


    DisplayName           : Chris' M365 Group
    Mail                  : ChrisGroup@domain.onmicrosoft.com
    ProxyAddresses        : {}
    Type                  : Microsoft 365
    OnPremisesSyncEnabled : False
    Owners                : chris.dymond@domain.com
```

## Service Principals

### Get-IAAzureADAppServicePrincipals

Returns a list of all application service principals within the tenant. This includes an authentication type of OAuth/SAML (where available from the tags attribute) as well as user, group and meta data associated with the application.

- Optional parameter
  ` -ExportToCsv:$true`

```powershell
Get-IAAzureADAppServicePrincipals
```

```
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
```

# Miscellaneous

## Password Generation

### New-IAComplexPassword

Generates a randomised complex password.

Without parameters the method will generate a password of 16
characters in length.

There will be;

- At least 1 lower case letter
- At least 1 upper case letter
- At least one number; and
- 6 non-alpha characters.

```powershell
    New-IAComplexPassword
```

```
    {V+y_[=)Ev_T+8fn
```

Length and the number of non-alpha characters may also be defined.

```powershell
    New-IAComplexPassword -PasswordLength 20 -NumNonAlphaChars 10
```

```
    _*j}/QY!=5T/w^ZYD_y@
```
