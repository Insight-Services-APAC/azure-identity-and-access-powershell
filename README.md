# Introduction

This repository intends to be a technical reference for managing aspects of Azure’s Identity and Access Management via PowerShell.

It will primarily be a showcase for common PowerShell queries for both Azure and On-Premise AD with some functions grouped into modules where applicable.

@author Chris Dymond chris.dymond@insight.com

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

  - [Account | New](azure/user/README.md#Creating-a-cloud-user-account)
  - [Complex password | New](azure/user/README.md#New-ComplexPassword)
  - [Last Sign-In | Get](azure/user/README.md#last-sign-in)

- Group (pending)

- Licensing

  - [Tenant licenses | Get](azure/licensing/README.md#get-tenant-licensing-details)

- Tenant Consolidation (pending)

- [Azure AD Connect](azure/adc/README.md) (in progress)
  
    **Working with Anchors**
  - [Retrieving the ImmutableId of a cloud user](azure/adc#Retrieving-the-ImmutableId-of-a-cloud-user)
  - [Converting the ImmutableId to a ConsistencyGuid](azure/adc#Converting-the-ImmutableId-to-a-ConsistencyGuid)
  - [Setting the ImmutableId to the ConsistencyGuid](azure/adc#Setting-the-ImmutableId-to-the-ConsistencyGuid)
  - [Converting the ConsistencyGuid to a ImmutableId](azure/adc#Converting-the-ConsistencyGuid-to-a-ImmutableId)
  - [Converting the ImmutableId to a DN](azure/adc#Converting-the-ImmutableId-to-a-DN)

- Azure AD Connect cloud sync (pending)

- Exchange Online - EXO (pending)

- Conditional Access (pending)

# On-Premise AD

- Discovery (pending)

- [User](on-premise/user/README.md)
  - [Sanitised String | ConvertTo](on-premise/user/README.md#ConvertTo-StringWithoutApostropheOrSpace)
  - [Username | New](on-premise/user/README.md#New-Username)
  - [Complex password | New](on-premise/user/README.md#New-ComplexPassword)
  - [Email address | New ](on-premise/user/README.md#New-Mail)
