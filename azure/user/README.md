# Introduction

This area intends to be a reference for managing cloud users.

# Creating a cloud user account

```powershell
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "[Required]"
$DisplayName = "[Required]"
$MailNickName = "[Required]"
$UserPrincipalName = "[Required]@[Required].onmicrosoft.com"
$NewAzureADUserParams = @{
    DisplayName       = $DisplayName
    UserPrincipalName = $UserPrincipalName
    PasswordProfile   = $PasswordProfile
    MailNickName      = $MailNickName
    AccountEnabled    = $true
    ShowInAddressList = $false # null is the equivalent of true
    #ImmutableId      = $[Optional]
}
New-AzureADUser @NewAzureADUserParams
```

# Last Sign In

Retrive the last sign-in datetime.

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

**Note** - There is a 30-day sign-in history limit for Azure AD Premium P1/P2
