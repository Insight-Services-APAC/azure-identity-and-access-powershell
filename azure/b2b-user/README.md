# Introduction

To better manage the onboarding of B2B users, Azure has recently introduced a feature allowing self-service sign-up. This feature, currently in Preview, utilises 'user flows' to define the onboarding process.

A user flow is sequence of onboarding steps at the end of which a B2B account is created in the target tenant.

# Azure B2B Self-Service Sign-Up Steps

![alt text](images/cdymond-azure-b2b-self-service-sign-up.png 'B2B Self-Service Sign-Up Flow')

The sequence of steps as outlined are:

1. An External User accessing a Self-Registration Application that permits self-service sign-up.
2. They choose to create an account when presented at the login page.
3. The 'After Sign-In' API connector receives their UPN suffix and basic information.
4. If permitted they are directed to the in-built B2B registration form.
5. At the registration form additional data is provided by the user (as defined by selected attributes)
6. The 'Before Creation' API Connector checks and validates the input.
7. If successfully validated a resulting B2B account is created in the target tenant.

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

  - **Note** - Invitation / SelfServiceSignup / Null

- userState
- userStateChangedOn
- refreshTokensValidFromDateTime

  - **Note** - Not all token requests ask for refresh tokens, as such this cannot be relied upon soley for checking inactivity.

- showInAddressList
- userPrincipalName
- displayName
- givenName
- surname
- jobTitle

```powershell
$Users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true `
| Select-Object -Property @{
    N = 'CreatedDateTime'; `
    E = { $_.ExtensionProperty["createdDateTime"] }
    }, `
    objectId, mail, `
    creationType, userState, userStateChangedOn, `
    refreshTokensValidFromDateTime, showInAddressList, `
    usageLocation, userPrincipalName, displayName, `
    givenName, surname, jobTitle
```

**Note** - That in this example I have used a Select-Object statement and expanded an extension property.

# Extension Attributes

## Get All

This will return all of Azure extension attributes in the schema. If you have created additional custom attributes for the user flow they will appear here together with any other customised attributes.

```powershell
Get-AzureADApplication | Get-AzureADApplicationExtensionProperty
```

**Note** - These will be presented in the form: extension**appId**_ExtensionPropertyName_

Every tenant has an appId corresponding to an app registration that holds the extended schema.

# Sign In Logs

Sign-In Logs are useful for establishing a list of inactive accounts.

## Get For A Specific User

```powershell
$signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '<objectId>'"
```

Where **objectId** is the target user's objectId

**Note** - There is a 30 day history limit for Azure AD Premium P1/P2
(extension to this is possible through the use of a storage account)
