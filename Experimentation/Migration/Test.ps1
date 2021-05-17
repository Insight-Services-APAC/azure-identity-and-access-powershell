Import-Module ..\..\IA.psd1 -Force

$ErrorActionPreference = 'Stop'

function ProcessResult {
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string] $FileName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [PSCustomObject] $ObjectList
    )
    process {
        if ($null -eq $ObjectList) {
            Write-Host -Background Magenta "`t> $FileName (0 objects) -- csv output skipped"
            return 
        }
        $FileName += " $($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss'))"
        $OutFileName = $FileName + '.csv'
        Write-Host -ForegroundColor Yellow "`t> $OutFileName ($($ObjectList.Count) objects)"
        $ObjectList | ForEach-Object {
            $_ | Select-Object ObjectId
        } | Export-Csv $OutFileName -NoTypeInformation
        # Backup the full object list
        $OutFileName = $FileName + '.json'
        $ObjectList | ConvertTo-Json | Out-File $OutFileName
    }
    
}

# AAD GRP DIST
# AAD GRP M365
# AAD GRP MESEC
# AAD GRP SEC
# AAD RES MBX
# AAD USR MBX
# AAD USR No MBX
# AD GRP DIST
# AD GRP MESEC
# AD GRP SEC
# AD RES MBX
# AD USR MBX
# AD USR No MBX

# Remove existing CSVs in the current path
Get-ChildItem *.csv | ForEach-Object { Remove-Item -Path $_.FullName }
Get-ChildItem *.json | ForEach-Object { Remove-Item -Path $_.FullName }


# Pilot

## Azure Accounts ##
Write-Host -ForegroundColor Yellow "Fetching all Azure AD accounts`n"
$Accounts = Get-IAAzureADUsersAsList
$TenantDomain = Get-AzureADCurrentSessionInfo | Select-Object -ExpandProperty TenantDomain
Write-Host -ForegroundColor Yellow "`t> $TenantDomain returned $($Accounts.Count) account objects`n"

$GuestCount = ($Accounts | Where-Object { $_.Type -eq 'B2B' }).Count

Write-Host -ForegroundColor Yellow "Exporting accounts (excluding $GuestCount B2B objects)`n"

$CloudOnlyExchangeResourceMailboxes = $Accounts  | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD RES MBX" $CloudOnlyExchangeResourceMailboxes

$CloudOnlyUsersWithMailboxes = $Accounts  | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD USR MBX" $CloudOnlyUsersWithMailboxes

$CloudOnlyUsersWithNoMailboxes = $Accounts  | Where-Object { $_.Type -eq 'User (No Mailbox)' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD USR No MBX" $CloudOnlyUsersWithNoMailboxes

$OnPremExchangeResourceMailboxes = $Accounts | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD RES MBX" $OnPremExchangeResourceMailboxes

$OnPremUsersWithMailboxes = $Accounts | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD USR MBX" $OnPremUsersWithMailboxes

$OnPremUsersWithNoMailboxes = $Accounts  | Where-Object { $_.Type -eq 'User (No Mailbox)' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD USR No MBX" $OnPremUsersWithNoMailboxes


## Azure Groups ##
Write-Host -ForegroundColor Yellow "`nFetching all Azure AD groups`n"
$AllGroups = Get-IAAzureADGroupsAsList
Write-Host -ForegroundColor Yellow "`t> $TenantDomain returned $($AllGroups.Count) group objects`n"

Write-Host -ForegroundColor Yellow "Exporting groups`n"

$CloudDistribution = $AllGroups | Where-Object { $_.Type -contains 'Distribution' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD GRP DIST" $CloudDistribution

# Microsoft 365 Groups (cloud is implicit)
$Microsoft365Groups = $AllGroups | Where-Object { $_.Type -contains 'Microsoft 365' }
ProcessResult "AAD GRP M365" $Microsoft365Groups

$CloudMailEnabledSecurity = $AllGroups | Where-Object { $_.Type -contains 'Mail-Enabled Security' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD GRP MESEC" $CloudMailEnabledSecurity

$CloudSecurityGroups = $AllGroups | Where-Object { $_.Type -contains 'Security' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD GRP SEC" $CloudSecurityGroups

$OnPremDistribution = $AllGroups | Where-Object { $_.Type -contains 'Distribution' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD GRP DIST" $OnPremDistribution

$OnPremMailEnabledSecurity = $AllGroups | Where-Object { $_.Type -contains 'Mail-Enabled Security' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD GRP MESEC" $OnPremMailEnabledSecurity

$OnPremSecurityGroups = $AllGroups | Where-Object { $_.Type -contains 'Security' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD GRP SEC" $OnPremSecurityGroups

Write-Host -ForegroundColor Yellow "`nAll tasks have completed successfully."
