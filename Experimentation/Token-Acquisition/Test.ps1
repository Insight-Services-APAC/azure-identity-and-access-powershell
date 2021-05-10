using namespace Microsoft.Open.Azure.AD.CommonLibrary

$ErrorActionPreference = 'Stop'

# Credit to https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory = $true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}

function Send-MSGraphPatchRequest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $GraphUrl,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [PSCustomObject] $Body,
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [String] $AccessToken
    )
    process {
        if ([string]::IsNullOrEmpty($AccessToken)) {
            # Use the Azure AD PS provided token
            Get-AzureADMSAdministrativeUnit -Top 1 | Out-Null # Just to ensure we have a graph.microsoft.com token (not just a graph.windows.net one)
            $graphToken = [AzureSession]::TokenCache.ReadItems() | `
                Where-Object { $_.Resource -eq 'https://graph.microsoft.com' } | Select-Object AccessToken
            if ($null -eq $graphToken) {
                throw "The Graph Access token is not available!"
            }
            $AccessToken = $graphToken.AccessToken
        }
     
        $graphRequest = @{
            Uri     = $GraphUrl
            Headers = @{
                'Authorization' = "Bearer $AccessToken"
                'Content-type'  = 'application/json'
            }
            Body    = $Body
            Method  = 'PATCH'
        }

        try {
            Invoke-RestMethod @graphRequest
        }
        catch {
            $respStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($respStream)
            $errorBody = $reader.ReadToEnd() | ConvertFrom-Json | Select-Object -ExpandProperty error
            $errorCode = $errorBody | Select-Object -ExpandProperty code
            $errorMessage = $errorBody | Select-Object -ExpandProperty message
            throw "$errorCode`n$errorMessage"
        }
        
    }
}


$Body = @{
    "onPremisesImmutableId" = ''
} | ConvertTo-Json

$graphUrl = 'https://graph.microsoft.com/beta/users/username@chrisdymond.onmicrosoft.com'

Send-MSGraphPatchRequest $graphUrl $body

return

# 1b730954-1685-4b74-9bfd-dac224a7b894 [AzureAD PowerShell]
# Agreement.Read.All
# Agreement.ReadWrite.All
# AgreementAcceptance.Read
# AgreementAcceptance.Read.All
# AuditLog.Read.All
# Directory.AccessAsUser.All
# Directory.ReadWrite.All
# Group.ReadWrite.All
# IdentityProvider.ReadWrite.All
# Policy.ReadWrite.TrustFramework
# PrivilegedAccess.ReadWrite.AzureAD
# PrivilegedAccess.ReadWrite.AzureADGroup
# PrivilegedAccess.ReadWrite.AzureResources
# TrustFrameworkKeySet.ReadWrite.All
# User.Invite.All

# 1950a258-227b-4e31-a9cf-717495945fc2 [Az PowerShell] resource manager
# user_impersonation

# 04b07795-8ddb-461a-bbee-02f9e1bf7b46 [Azure CLI]
# AuditLog.Read.All
# Directory.AccessAsUser.All
# Group.ReadWrite.All
# User.ReadWrite.All


$clientid = '1b730954-1685-4b74-9bfd-dac224a7b894'
$redirectUri = 'urn:ietf:wg:oauth:2.0:oob'
$resourceURI = 'https://graph.microsoft.com'
$authority = 'https://login.microsoftonline.com/common'
 
$AadModule = Import-Module -Name AzureADPreview -PassThru
$adal = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
$adalforms = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
$authContext = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority
$platformParameters = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters' -ArgumentList "SelectAccount"
$authResult = $authContext.AcquireTokenAsync($resourceURI, $ClientID, $RedirectUri, $platformParameters)
$accessToken = $authResult.result.AccessToken
$decodedJwt = Parse-JWTtoken($accessToken)
$decodedJwt

Write-Host -ForegroundColor Yellow "---Delegated Scopes---`n"

Write-Host -ForegroundColor Yellow $decodedJwt.scp

