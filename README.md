# Overview

This solution aims to provide an extended set of cmdlets for managing Identity & Access (IA) across Azure AD and Exchange Online.

It intends to supplement the existing Microsoft AzureADPreview and ExchangeOnlineManagement Modules.

This module is a work in progress.

## Backlog

- Custom MS Graph Calls :
  - Read MFA status, to achieve similiar results to MSOnline (msol) cmdlets

@author Chris Dymond chris.dymond@insight.com

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

# Use Cases

## [Exchange Online](EXO/README.md)

- Recipients

  - [Retrieve all (includes size where a mailbox)](/EXO/README.md#Get-IAEXORecipientsAsDictionary)
  - [Retrieve all utilising the @tenant.onmicrosoft.com smtp address (proxyAddress)](/EXO/README.md#Get-IAEXORecipientsOnMicrosoftAsList)

## [Azure AD](AzureAD/README.md)

- Users

  - [Retrieve all (includes a UserType classification; User, Exchange, B2B)](/AzureAD/README.md#Get-IAAzureADUsersAsList)
  - [Retrieve all B2B domains in the tenant as well as their user count](/AzureAD/README.md#Get-IAAzureADGuestUserDomainsAsDictionary)
  - [Get the date and time of last successful sign in](/AzureAD/README.md#Get-IAAzureADUserLastSignInAsDateTime)

- Groups
  - [Retrieve all (includes a GroupType classifcation; Security, Distribution or M365)](/AzureAD/README.md#Get-IAAzureADGroupsAsList)
