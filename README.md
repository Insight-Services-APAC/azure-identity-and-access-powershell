# Introduction

This repository intends to be a technical reference for managing aspects of Azure’s Identity and Access Management via PowerShell.

It will primarily focus upon code snippets showcasing common queries for both Azure and On-Premise AD.

@author Chris Dymond | Insight 2021

# Azure AD

- [B2B User Self Service Sign-Up Overview](azure/b2b-user/README.md)

  - [B2B accounts | Get](azure/b2b-user/README.md#guests)
  - [B2B extension attributes | Get](azure/b2b-user/README.md#extension-attributes)
  - [B2B sign-in logs | Get](azure/b2b-user/README.md#sign-in-logs)

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
