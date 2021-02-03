# Introduction

This repository intends to be a technical reference for managing aspects of Azure’s Identity and Access Management via PowerShell.

It will primarily focus upon code snippets and examples showcasing commonly required queries across both Azure and On-Premise AD.

@author Chris Dymond | Insight 2021

# Azure AD
- [B2B User Self Service Sign-Up](azure/b2b-user/README.md)
  - [Retrieving Extension Attributes](azure/b2b-user/README.md#extension-attributes)
  - [Getting B2B Accounts](azure/b2b-user/README.md#guests)
  - [Getting Sign-In Logs](azure/b2b-user/README.md#sign-in-logs)

- [User](azure/user/README.md)
  - [Creating a cloud user account](azure/user/README.md#creating-a-cloud-user-account)

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
  - [Removing apostrophes and spacing](on-premise/user/README.md#ConvertTo-StringWithoutApostropheOrSpace)
  - [Finding an available username](on-premise/user/README.md#New-Username)
  - [Generating a complex password](on-premise/user/README.md#New-ComplexPassword)
  - [Getting an available email address](on-premise/user/README.md#New-Mail)

