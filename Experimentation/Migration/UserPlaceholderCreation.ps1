using namespace System.Collections.Generic
using namespace Microsoft.Open.Azure.AD.CommonLibrary
Import-Module ..\..\IA.psd1 -Force

$ErrorActionPreference = 'Stop'

$accounts = Get-Content '.\AD USR MBX 20210517T110708.json' | ConvertFrom-Json

$azureAD = Connect-AzureAD

$title = 'User Account Placeholders'
$question = "Do you want to create on-premises placeholder accounts in $($azureAD.TenantDomain)?"
$choices = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host -ForegroundColor Yellow "Creating placeholder accounts`n"
    $accounts | ForEach-Object {
        if ( $null -eq (Get-AzureADUser -Filter "displayName eq 'zz$($_.ObjectId)'")) {
            $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
            $passwordProfile.Password = New-IAComplexPassword
            $passwordProfile.ForceChangePasswordNextLogin = $false
            $params = @{
                AccountEnabled    = $true
                DisplayName       = "zz$($_.ObjectId)"
                PasswordProfile   = $passwordProfile
                MailNickName      = $_.MailNickName
                UserPrincipalName = ($_.UserPrincipalName.Split('@')[0] + '@' + $azureAD.TenantDomain)
                ExtensionProperty = $extensionProperties
                ShowInAddressList = $false # default is $null
                UsageLocation     = 'AU'
                ImmutableId       = $_.ImmutableId
            
            }
            $createdUser = New-AzureADUser @params
            Write-Host -ForegroundColor Yellow "`t> $($_.UserPrincipalName) placeholder account created."
            # Source ID to Destination ID
            Add-Content 'PlaceholderAccountMappings.txt' "$($_.ObjectId),$($createdUser.ObjectId)"
        }
        else {
            Write-Host -ForegroundColor Yellow "`t> $($_.UserPrincipalName) already has a placeholder account."
        }
    }


}
else {
    return
}

