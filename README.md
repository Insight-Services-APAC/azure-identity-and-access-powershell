# Overview

This solution aims to provide an extended set of cmdlets for managing Identity & Access (IA) across Azure AD and Exchange Online.

It intends to supplement the existing (Microsoft provided) AzureADPreview and ExchangeOnlineManagement cmdlets.

This library is a work in progress.

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

  - Getting all recipients and their current mailbox size (where applicable)
  - Get all recipients with the @tenant.onmicrosoft.com smtp address

## [Azure AD](AzureAD/README.md)

- Users

- Groups
  - Getting a list of all groups in your organisation
