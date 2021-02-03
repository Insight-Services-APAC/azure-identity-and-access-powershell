# Azure Active Directory Connect

## Retrieving the Immutable ID of a cloud user.
Retrieving the ImmutableId of a cloud user.

```powershell
$ImmutableID = Get-AzureADUser -UserPrincipalName $Upn | Select-Object -ExpandProperty ImmutableId
```

## Converting an ImmutableId to a ConsistencyGuid
```powershell
function ConvertFrom-ImmutableIdToConsistencyGuid {
    <#
    .SYNOPSIS
        Immutable ID to Consistency GUID

        @Author: Chris Dymond | Insight 2021
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([GUID])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ImmutableId
    )
    process {
        [GUID][System.Convert]::FromBase64String($ImmutableID)
    }
}
```

## Setting the ImmutableId to the on-premise ConsistencyGuid
```powershell
Set-ADUser –UserPrincipalName $Upn -Replace @{'mS-DS-ConsistencyGuid' = [GUID]$ConsistencyGuid }
```

## Converting a ConsistencyGuid to a ImmutableId
```powershell
function ConvertFrom-ConsistencyGuidToImmutableId {
    <#
    .SYNOPSIS
        Consistency GUID to Immutable ID

        @Author: Chris Dymond | Insight 2021
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [GUID]
        $ConsistencyGuid
    )
    process {
        [System.Convert]::ToBase64String($ConsistencyGuid.ToByteArray())
    }
}
```

## Converting a ImmutableId to a DN
```powershell
    function ConvertFrom-ImmutableIdToDn {
      <#
    .SYNOPSIS
        Converts an Immutable ID to a DN (as displayed in AAD Connect)

        @Author: Chris Dymond | Insight 2021
    .DESCRIPTION
    #>
        [CmdletBinding()]
        [OutputType([string])]
        param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 0)]
            [ValidateScript( { try { $null = [Convert]::FromBase64String($_); $true } catch { $false } })]
            [String]
            $ImmutableId
        )  
        process {
            $encodedValue = ([Text.Encoding]::UTF8).getbytes($ImmutableId)
            $dn = $encodedValue | foreach { ([Convert]::ToString($_, 16)) }
            $dn = $dn -join ''
            "CN={$dn}"
        }     
    }
```