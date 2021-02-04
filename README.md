# Introduction

This repository intends to be a technical reference for managing aspects of Azure’s Identity and Access Management via PowerShell.

It will primarily focus upon code snippets showcasing common queries for both Azure and On-Premise AD.

@author Chris Dymond | Insight 2021

## Prerequisites

Many of these cmdlets are based upon the AzureADPreview PowerShell Module

```powershell
Install-Module AzureADPreview
Import-Module AzureADPreview
```

# Azure AD

- [B2B](azure/b2b-user/README.md)

  - [Self service sign up | Feature Overview](azure/b2b-user/README.md)
  - [Accounts | Get](azure/b2b-user/README.md#guests)
  - [Partner domains in your tenant | Get](azure/b2b-user/README.md#get-b2b-domains)
  - [Extension attributes | Get](azure/b2b-user/README.md#extension-attributes)
  - [Last Sign-In | Get](azure/b2b-user/README.md#last-sign-in)

- [User](azure/user/README.md)

  - [Account | New](azure/user/README.md#creating-a-cloud-user-account)
  - [Complex password | New](azure/user/README.md#New-ComplexPassword)
  - [Last Sign-In | Get](azure/user/README.md#last-sign-in)

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
