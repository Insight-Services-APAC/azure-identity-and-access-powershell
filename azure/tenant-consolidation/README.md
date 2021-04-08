# Tenant Consolidation

## Finding Foreign Service Principals
Foreign service principals are those that have been created by Administrators of the tenant.

```powershell
Get-AzureADServicePrincipal -All $true | `
    Where-Object PublisherName -ne 'Microsoft Services' | `
    Select-Object  DisplayName, PublisherName, ServicePrincipalType, AppId | `
    Sort-Object DisplayName
```
