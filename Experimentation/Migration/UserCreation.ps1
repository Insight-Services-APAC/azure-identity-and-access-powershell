using namespace System.Collections.Generic
Import-Module ..\..\IA.psd1 -Force

$ErrorActionPreference = 'Stop'

$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = New-IAComplexPassword
$passwordProfile.ForceChangePasswordNextLogin = $false
$extensionProperties = [Dictionary[string, string]]::new()
$extensionProperties.Add('employeeId', 'test')
$params = @{
    AccountEnabled    = $true
    DisplayName       = 'Test User'
    PasswordProfile   = $passwordProfile
    MailNickName      = 'TUser'
    UserPrincipalname = 'tuser@chrisdymond.onmicrosoft.com'
    ExtensionProperty = $extensionProperties

}
$createdUser = New-AzureADUser @params

# $createdUser | Set-AzureADUserExtension -ExtensionName 'employeeId' -ExtensionValue 'test'

$createdUser.ObjectId
$createdUser.UserPrincipalName
