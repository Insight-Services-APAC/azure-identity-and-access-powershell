using namespace System.Collections.Generic

# Debug version. until ready to be moved to IA .psm1
# Task: finding created apps with AAD integration and getting relevant informaiton
# Chris Dymond

class IAAppServicePrincipal {
    # App Specific
    [string]$ObjectId
    [string]$AppId
    [bool]$AccountEnabled
    [string]$DisplayName
    [string]$AuthenticationType
    [string]$PublisherName
    [string]$ServicePrincipalType
    [List[string]]$AssignedUserPrincipalNames = [List[string]]::new()
    [List[string]]$AssignedGroups = [List[string]]::new()
    [List[string]]$AssignedPrincipalTypes = [List[string]]::new()
    [List[string]]$ReplyUrls = [List[string]]::new()
    [List[string]]$Tags = [List[String]]::new()
    [List[string]]$IdentifierUris = [List[String]]::new()
    [string]$SignInAudience
    
}

function Get-IAAzureADCreatedServicePrincipals() {
    $iaServicePrincipalList = [List[IAAppServicePrincipal]]::new()
    Get-AzureADServicePrincipal -All $true | Where-Object { $_.Tags -contains "WindowsAzureActiveDirectoryIntegratedApp" } | ForEach-Object {
        $iaAppServicePrincipal = [IAAppServicePrincipal]::new()
        $iaAppServicePrincipal.ObjectId = $_.ObjectId
        $iaAppServicePrincipal.AppId = $_.AppId
        $iaAppServicePrincipal.AccountEnabled = $_.AccountEnabled
        $iaAppServicePrincipal.ServicePrincipalType = $_.ServicePrincipalType
        $iaAppServicePrincipal.DisplayName = $_.DisplayName
        $iaAppServicePrincipal.PublisherName = $_.PublisherName
        $iaAppServicePrincipal.ReplyUrls = $_.ReplyUrls
        $iaAppServicePrincipal.Tags = $_.Tags

        if ($_.Tags -contains 'WindowsAzureActiveDirectoryGalleryApplicationNonPrimaryV1' -or `
                $_.Tags -contains 'WindowsAzureActiveDirectoryCustomSingleSignOnApplication') {
            $iaAppServicePrincipal.AuthenticationType = 'SAML'
        }
        else {
            $iaAppServicePrincipal.AuthenticationType = 'OAuth'
        }

        $tenantApp = Get-AzureADApplication -Filter "AppId eq '$($_.AppId)'"
        if ($tenantApp) {
            $iaAppServicePrincipal.IdentifierUris = $tenantApp.IdentifierUris
            $iaAppServicePrincipal.SignInAudience = $tenantApp.SignInAudience
        }

        $ServiceAppRoleAssignment = $_ | Get-AzureADServiceAppRoleAssignment 

        $UserPrincipals = $ServiceAppRoleAssignment | Where-Object { $_.PrincipalType -eq 'User' } | Select-Object PrincipalId
        $UserPrincipalNames = [List[string]]::new()
        $UserPrincipals | ForEach-Object {
            $UserPrincipalName = Get-AzureADUser -ObjectId $_.PrincipalId | Select-Object -ExpandProperty UserPrincipalName
            $UserPrincipalNames.Add($UserPrincipalName)
        }
        $iaAppServicePrincipal.AssignedUserPrincipalNames = $UserPrincipalNames 
        $iaAppServicePrincipal.AssignedGroups = ($ServiceAppRoleAssignment | Where-Object { $_.PrincipalType -ne 'User' } | Select-Object -Unique -ExpandProperty PrincipalDisplayName )
        $iaAppServicePrincipal.AssignedPrincipalTypes = ($ServiceAppRoleAssignment | Select-Object -Unique -ExpandProperty PrincipalType)
        $iaServicePrincipalList.Add($iaAppServicePrincipal)
    }
    $iaServicePrincipalList
}

Get-IAAzureADCreatedServicePrincipals