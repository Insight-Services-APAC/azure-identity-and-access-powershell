# Introduction

To better manage the onboarding of B2B users, Azure has introduced a feature allowing user self-service sign-up. This feature, currently in Preview, utilises 'User Flows' to formalise and automate a custom onboarding process.

A User Flow is essentially a sequence of onboarding steps. Once these steps are satisfied, the external user is permitted into the tenant as a B2B user automatically. 

# Self Service Sign Up Steps

A high-level overview of these steps is outlined here:

![alt text](images/cdymond-azure-b2b-self-service-sign-up.png 'B2B Self-Service Sign-Up Flow')

1. An External User accesses a Self-Registration Application that permits self-service sign-up.
2. They choose to create an account at the login page.
3. The 'After Sign-In' API connector receives their UPN suffix and basic information from their home tenant.
4. If permitted by the API connector they are directed to the in-built B2B registration form.
   - This form is composed of attributes as defined by the user flow.
5. At the registration form the user supplies additional data as required by the user flow.
6. The 'Before Creation' API Connector then checks and validates this input.
7. If successfully validated a B2B account is created in the tenant.

# Guests

Guests can enter a tenant in a number of ways depending upon the tenant's collaboration settings. For instance, they may be invited via the Portal or SharePoint etc.

To get an overview of all the existing B2B accounts in your tenant run the cmdlet outlined below.

## Get All

```powershell
$users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true
```

This will return an array of all the B2B User objects.

## Get Specific Attributes

You may also find the following list of attributes useful in assessing your B2B users:

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

**Note** - That in this example I have used a Select-Object statement and expanded an extension property and included it in the resulting set.

## Get B2B Domains

Retrive a list of B2B user domains currently in your tenant

```powershell
    <#
    .SYNOPSIS
        Retrieving a count of B2B user domains.

        @Author: Chris Dymond | Insight 2021
    .DESCRIPTION
    #>
using namespace System.Collections.Generic
$Users = Get-AzureADUser -Filter "userType eq 'Guest'" -All $true
[Dictionary[String, Int32]] $B2BDomains = [Dictionary[String, Int32]]::new()
foreach ($User in $Users) {
    # Mail is not always populated
    # UPN will be used to ascertain the host tenant
    # chris.dymond_something.com.au#EXT#@x.onmicrosoft.com
    # chris_dymond_something.com.au#EXT#@x.onmicrosoft.com
    $UserPrincipalName = $User.UserPrincipalName
    $B2BDomain = ($UserPrincipalName.Split('#')[0].Split('_')[$UserPrincipalName.Split('#')[0].Split('_').Count - 1]).ToLower()
    if ($null -eq $B2BDomains[$B2BDomain]) {
        $B2BDomains.Add($B2BDomain, 1)
        
    } else {
        $B2BDomains[$B2BDomain] = $B2BDomains[$B2BDomain] + 1
    }
}
$B2BDomains.GetEnumerator() | Sort-Object | Export-CSV "B2B_Domains.csv" -NoTypeInformation
```

# Sign In Logs

As well as looking at the users themselves, sign-in logs can be a great way of establishing B2B user inactivity.

## Get For A Specific User

```powershell
function Get-LastSignInByUserPrincipalName {
    <#
    .SYNOPSIS
        Get the last successful login date of an Azure user.
        This will be returned in local time.
        @Author: Chris Dymond | Insight 2021
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([DateTime])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $UserPrincipalName
    )
    process {
        # This code returns only the last successful event.
        $LastSignIn = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'" `
         | Where-Object {$_.Status.ErrorCode -eq 0} | Select-Object -First 1
        [DateTime]::ParseExact($LastSignIn.CreatedDateTime, "yyyy-MM-ddTHH:mm:ssZ", $null)
    }
}
```

Where **objectId** is the target user's objectId.

**Note** - There is a 30-day history limit for Azure AD Premium P1/P2
(extension to this is possible through the use of a storage account)

# Extension Attributes

AD extension attributes include both custom B2B attributes defined for the User Flow and others added to your tenant's schema.

## Get All

```powershell
Get-AzureADApplication | Get-AzureADApplicationExtensionProperty
```

**Note** - These will be presented in the form: extension**appId**_ExtensionPropertyName_

The **appId** corresponds to an app registration clientId that holds the extended schema. Every tenant will have its own clientId.
