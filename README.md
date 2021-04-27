# Overview

Hello and welcome,

I'm Chris Dymond, a Cloud Technical Specialist with a keen interest in managing aspects of Microsoft Azure via PowerShell.

I've written this repository with the aim to provide scenario-based cmdlets that both extend and enhance the AzureADPreview and ExchangeOnlineManagement modules.

Using this module you'll be able to answer questions like:

- Which of my users currently have licensing applied?
- When was the last sign-in of user 'x'?
- What is the total size of all my Exchange Online mailboxes?
- How many groups do I have, what kind are they and who owns them?

Please note that the 'IA' module, as I'm calling it, is a work in progress.

# Updates

27-04-21 - Added license assignment paths for users via Graph

## Backlog

- Custom MS Graph Calls :
  - Read MFA status, to achieve similiar results to MSOnline (msol) cmdlets

@Author Chris Dymond

chris.dymond@insight.com

https://www.linkedin.com/in/chris-dymond/

# Referencing the IA module

To use any of these cmdlets you must import this module.

```powershell
Import-Module .\IA.psd1
```

As this library will make extensive use of both AzureADPreview and ExchangeManagementOnline it is a requirement that these two modules are also installed or already available.

```powershell
Install-Module AzureADPreview
Install-Module ExchangeOnlineManagement
```

Where a specific feature is not exposed by these modules a native Graph API call may suffice and be included in the IA library.

# Scenario Based

## [Exchange Online](EXO/README.md)

### Recipients

[Get-IAEXORecipientsOnMicrosoftAsList](/EXO/README.md#Get-IAEXORecipientsOnMicrosoftAsList)

This will retrieve all Exchange Online recipients with an @tenant.onmicrosoft.com proxyAddress

```powershell
.EXAMPLE
  $Results = Get-IAEXORecipientsOnMicrosoftAsList
  $Results
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

[Get-IAEXORecipientsAsDictionary](/EXO/README.md#Get-IAEXORecipientsAsDictionary)

This will retrieve all Exchange Online recipients and index them by their recipient recipientTypeDetail.

It includes combined size (where applicable)

```powershell
  $Results = Get-IAEXORecipientsAsDictionary
  $Results

  Key                            Value
  ---                            -----
  UserMailbox                    IARecipients
  RoomMailbox                    IARecipients
  MailUsers                      IARecipients

  $Results['UserMailbox']


  CombinedSizeInGB Recipients
  ---------------- ----------
  725.87           {@{ExternalDirectoryObjectId=....


  $Results['UserMailbox'].Recipients

  ...
  ExternalDirectoryObjectId :
  Identity                  : Chris Dymond
  Alias                     : Chris.Dymond
  EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
  DisplayName               : Chris Dymond
  Name                      : Chris Dymond
  PrimarySmtpAddress        : Chris.Dymond@domain.com
  RecipientType             : UserMailbox
  RecipientTypeDetails      : UserMailbox
  ExchangeVersion           : 0.20 (15.0.0.0)
  DistinguishedName         : CN=
  OrganizationId            :
  TotalItemSize             : 1.243 GB (1,334,578,302 bytes)
  TotalItemSizeInGB         : 1.24
  ...
```
## [Azure AD](AzureAD/README.md)

- Licensing

  - [Retrieve summary; includes friendly license names (where available)](/AzureAD/README.md#Get-IAAzureADLicensesAsList)
  - [Retrieve as it applies to individual accounts](/AzureAD/README.md#Get-IAAzureADLicensesWithUsersAsList)

- Users

  - [Retrieve all (includes a UserType classification; User, Exchange, B2B)](/AzureAD/README.md#Get-IAAzureADUsersAsList)
  - [Retrieve all B2B domains in the tenant as well as their user count](/AzureAD/README.md#Get-IAAzureADGuestUserDomainsAsDictionary)
  - [Get the date and time of the last successful sign in of a user](/AzureAD/README.md#Get-IAAzureADUserLastSignInAsDateTime)

- Groups
  - [Retrieve all (includes a GroupType classifcation; Security, Mail-Enabled Security, Distribution, Microsoft 365, Dynamic, Licensing)](/AzureAD/README.md#Get-IAAzureADGroupsAsList)
