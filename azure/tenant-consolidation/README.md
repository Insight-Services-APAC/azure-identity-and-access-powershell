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
