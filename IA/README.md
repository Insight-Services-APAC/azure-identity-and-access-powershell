# Overview

This solution aims to provide an extended set of cmdlets for managing Identity & Access (IA) across Azure AD and Exchange Online.

It intends to supplement the Microsoft AzureADPreview and ExchangeOnlineManagement cmdlets.

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

## Exchange Online

- Recipients

  - Get All | and their current size (where a mailbox)
  - Get All | with an @tenant.onmicrosoft.com address

## Azure AD

- Users
- Groups
