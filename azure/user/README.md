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
