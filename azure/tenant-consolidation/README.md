# Tenant Consolidation

## Finding Foreign Service Principals
Foreign service principals are those that have been created by Administrators of the tenant.

```powershell
Get-AzureADServicePrincipal -All $true | `
    Where-Object PublisherName -ne 'Microsoft Services' | `
    Select-Object  DisplayName, PublisherName, ServicePrincipalType, AppId | `
    Sort-Object DisplayName
```

## Finding Orphaned Applications
These will not be in the foreign service principals results.

Essentially reporting on those applications found to be missing service principals.

```powershell
$ServicePrincipalObjects = Get-AzureADServicePrincipal -All $true | `
    Where-Object PublisherName -ne 'Microsoft Services' | `
    Select-Object  DisplayName, PublisherName, ServicePrincipalType, AppId | `
    Sort-Object DisplayName

$ServicePrincipals = [System.Collections.Generic.Dictionary[string, object]]::new()

ForEach ($ServicePrincipalObject in $ServicePrincipalObjects) {
    $ServicePrincipals.Add($ServicePrincipalObject.AppId, $ServicePrincipalObject)
}

$ApplicationObjects = Get-AzureADApplication -All $true | `
    Select-Object  DisplayName, AppId | `
    Sort-Object DisplayName

ForEach ($ApplicationObject in $ApplicationObjects) {
    $ServicePrincipal = $null
    if ($ServicePrincipals.TryGetValue($ApplicationObject.AppId, [ref] $ServicePrincipal) -eq $false) {
        Write-Host "Orphaned Application"
        Write-Host "AppId: $($ApplicationObject.AppId)"
        Write-Host "DisplayName: $($ApplicationObject.DisplayName)"
    }
}
```

## Scenario: Joining a new local account to a pre-existing cloud account
Assuming the local account is not in scope of AAD Connect (yet) or has sync paused it will not have an assigned consistency GUID.

```powershell
$User = Get-ADUser -Identity <Identity> -Properties 'mS-DS-ConsistencyGuid'
Set-ADUser -Identity $User -Replace @{ "ms-Ds-ConsistencyGuid" = $User.ObjectGUID.ToByteArray() }
```

Set the value to the ImmutableId of the counterpart cloud account.
Add the local account to the scope of AAD Connect or re-enable sync.
On sync the the local account will join to the Cloud Account and will become DirSync enabled.
The UPN must be manually changed (if different to the local counterpart).

## Scenario: Joining a cloud only account to a pre-existing on-premise AD account
Set the ImmutableId to the consistency GUID.
Bring the local account into the scope of AAD Connect
On sync the the local account will join to the Cloud Account and will become DirSync enabled.
The UPN must be manually changed (if different to the local counterpart).

```powershell
Set-AzureADUser -ObjectId <UPN or ObjectId> -ImmutableId "<ImmutableId>"
```

