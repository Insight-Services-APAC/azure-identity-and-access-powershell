# Introduction

This repository intends to be a technical reference for managing aspects of Azure’s Identity and Access Management via PowerShell.

It will primarily focus upon code snippets showcasing common queries for both Azure and On-Premise AD.

Note that many of these cmdlets are based upon the AzureADPreview PowerShell Module

```powershell
Install-Module AzureADPreview

Import-Module AzureADPreview
```

@author Chris Dymond | Insight 2021

# Azure AD

- [B2B](azure/b2b-user/README.md)

  - [Self Service Sign Up Steps](azure/b2b-user/README.md#self-service-sign-up-steps)
  - [Accounts | Get](azure/b2b-user/README.md#guests)
  - [Extension attributes | Get](azure/b2b-user/README.md#extension-attributes)
  - [Sign-in logs | Get](azure/b2b-user/README.md#sign-in-logs)

- [User](azure/user/README.md)

  - [Account | New](azure/user/README.md#creating-a-cloud-user-account)

- Group (pending)

- Licensing

  - [SKU friendly names](azure/licensing/README.md#licensing-sku-friendly-names)

- Tenant Consolidation (pending)

- [Azure AD Connect](azure/adc/README.md) (in progress)

  - Immutable Ids and Consistency Guids

- Azure AD Connect cloud sync (pending)

- Exchange Online - EXO (pending)

# On-Premise AD

- [User](on-premise/user/README.md)
  - [Sanitised String | ConvertTo](on-premise/user/README.md#ConvertTo-StringWithoutApostropheOrSpace)
  - [Username | New](on-premise/user/README.md#New-Username)
  - [Complex password | New](on-premise/user/README.md#New-ComplexPassword)
  - [Email address | New ](on-premise/user/README.md#New-Mail)
