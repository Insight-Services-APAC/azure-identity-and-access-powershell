# Introduction

This area intends to be a reference for the Azure B2B Self-Service Sign-Up User Flow. This, currently Preview feature, allows permitted Guests to onboard themselves into an Azure AD Tenant.

# Azure B2B Self-Service Sign-Up Steps

![alt text](images/cdymond-azure-b2b-self-service-sign-up.png 'B2B Self-Service Sign-Up Flow')

The sequence of steps are outlined below:

1. An External User accesses a Self-Registration Application that permits self-service sign-up.
2. They choose to create an account when prsented with the login windows.
3. A 'After Sign-In' API connector checks their UPN suffix
4. If permitted they are directed to the registration form.
5. At the registration form additional data is provided by the user.
6. The 'Before Creation' API Connector checks and validates the input.
7. If successfully validated a resulting B2B account is created in the target tenant.

# B2B Azure AD & Office 365 PowerShell Snippets

A series of PowerShell snippets I have found useful for managing B2B users.

Note that these cmdlets are based upon the AzureADPreview PowerShell Module

```powershell
Install-Module AzureADPreview

Import-Module AzureADPreview
```

[Retrieving Extension Attributes](#extension-attributes)

[Retrieving Guest Accounts (B2B)](#guests)

[Getting Sign-In Logs](#sign-in-logs)

Where required, append the following to create an output csv:

```powershell
| Export-CsV -NoTypeInformation -Path "output.csv"
```

# Extension Attributes

## Get All

This will return all Azure extension attributes in the schema.

```powershell
Get-AzureADApplication | Get-AzureADApplicationExtensionProperty
```

**Note** - These will be presented in the form: extension**appId**_ExtensionPropertyName_

Every tenant has an appId corresponding to an app registration that holds the extended schema.

# Guests

## Get All

```powershell
$users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true
```

## Get Specific Attributes

- createdDateTime
- objectId
- mail
- creationType

  **Note** - Invitation / SelfServiceSignup / Null

- userState
- userStateChangedOn
- refreshTokensValidFromDateTime

  **Note** - Not all token requests ask for refresh tokens, as such this cannot be relied upon soley for checking inactivity.

- showInAddressList
- userPrincipalName
- displayName
- givenName
- surname
- jobTitle

```powershell
$users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true | Select-Object -Property @{N='CreatedDateTime';E={$_.ExtensionProperty["createdDateTime"]}},  objectId, mail, creationType, userState, userStateChangedOn, refreshTokensValidFromDateTime, showInAddressList, usageLocation, userPrincipalName, displayName, givenName, surname, jobTitle
```

**Note** - That in this example I have used a select-object statement and expanded an extension property.

# Sign In Logs

Sign-In Logs are useful for establishing a list of stale accounts.

## Get For A Specific User

```powershell
$signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '<objectId>'"
```

Where **objectId** is the target user's objectId

**Note** - There is a 30 day history limit for Azure AD Premium P1/P2
(extension to this is possible through the use of a storage account)
