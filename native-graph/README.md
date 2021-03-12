# Native Graph Calls

An example of a native Graph API call without using dependant libraries. 

```powershell
$ErrorActionPreference = "Stop"

# Calling Microsoft Graph with Application Credentials
# Directory.Read.All (Type: Application)

$DirectoryID = "<TenantId>"
$ClientID = "<App ID>"
$ClientSecret = "<App Secret>"
$GrantType = 'client_credentials'

$OAuthUri = "https://login.microsoftonline.com/$DirectoryID/oauth2/v2.0/token"
$Body = @{
    client_id     = $ClientID
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $ClientSecret
    grant_type    = $GrantType
}
$TokenResult = Invoke-RestMethod -Uri $OAuthUri -Method POST -ContentType "application/x-www-form-urlencoded" -Body $Body
$Token = $TokenResult.access_token

$AttributesToSelect = @(
    "id"
    "userPrincipalName"
    "mail"
)

$SelectData = $AttributesToSelect -join ","
$GraphUri = 'https://graph.microsoft.com/v1.0/users?$select=' + $SelectData

$Results = Invoke-RestMethod -Method GET -Uri $GraphUri -Headers @{Authorization = "Bearer $Token" }
$MoreResults = $true
while ($MoreResults) {
    foreach ($Result in $Results.value) {
        Write-Output $Result
    }
    if ($null -ne $query.'@odata.nextLink') {
        $Results = Invoke-RestMethod -Method GET -Uri $Results.'@odata.nextLink' -Headers @{Authorization = "Bearer $Token" }
    }
    else {
        $MoreResults = $false
    }
}
```
