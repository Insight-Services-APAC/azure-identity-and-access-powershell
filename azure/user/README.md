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

# New-ComplexPassword

```powershell
function New-ComplexPassword {
    <#
    .SYNOPSIS
        Complex password generation

        @Author: Chris Dymond
    .DESCRIPTION
        Returns a a complex password containing:
            Lower case letters
            Upper case letters
            Numbers
            Special characters
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNull()]
        [Int]
        $PasswordLength,

        # A validation is done here otherwise it may never meet the criteria for upper,lower etc
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateScript( { $_ -lt $PasswordLength - 2 })]
        [Int]
        $NumNonAlphaChars
    )
    process {
        # Using the .NET supplied method with customisations.
        Add-Type -AssemblyName 'System.Web'
        $ValidPassword = $false
        do {
            $GeneratedPassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $NumNonAlphaChars)
            If ($GeneratedPassword -cmatch "(?=.*\d)(?=.*[a-z])(?=.*[A-Z])") {
                $ValidPassword = $True
            }
        } While ($ValidPassword -eq $false)
        $GeneratedPassword
    }
}
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
        @Author: Chris Dymond
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
        # Results are returned in order of most recent activity
        # This code returns only the last successful event.
        $Filter = "userPrincipalName eq '$UserPrincipalName' and status/errorCode eq 0"
        $LastSignIn = Get-AzureADAuditSignInLogs -Filter $Filter| Select-Object -First 1
        [DateTime]::ParseExact($LastSignIn.CreatedDateTime, "yyyy-MM-ddTHH:mm:ssZ", $null)
    }
}
```

**Note** - There is a 30-day sign-in history limit for Azure AD Premium P1/P2
