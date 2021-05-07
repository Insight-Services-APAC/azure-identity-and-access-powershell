Import-Module ..\IA.psd1 -Force

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
        if ($null -eq $ObjectList) { return }
        $FileName += " $($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
        Write-Host -ForegroundColor Yellow "Exporting collection $Filename ($($ObjectList.Count) objects)..."
        $ObjectList | ForEach-Object {
            $_ | Select-Object ObjectId
        } | Export-Csv $FileName -NoTypeInformation
    }
    
}

Write-Host -ForegroundColor Yellow "Target: $(Get-AzureADCurrentSessionInfo | Select-Object -ExpandProperty TenantDomain)"
Write-Host

## Azure Accounts ##
Write-Host -ForegroundColor Yellow 'Getting all Azure AD accounts...' -NoNewline
$Accounts = Get-IAAzureADUsersAsList
Write-Host -ForegroundColor Yellow "completed ($($Accounts.Count) objects)"
Write-Host

# On-Prem users with mailboxes
$OnPremUsersWithMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Users MBX" $OnPremUsersWithMailboxes

# On-Prem users with no mailboxes
$OnPremUsersWithNoMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User (No Mailbox)' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Users No MBX" $OnPremUsersWithNoMailboxes

# Cloud users with mailboxes
$CloudOnlyUsersWithMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Users MBX" $CloudOnlyUsersWithMailboxes

# Cloud users with no Mailbox
$CloudOnlyUsersWithNoMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User (No Mailbox)' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Users No MBX" $CloudOnlyUsersWithNoMailboxes

# Cloud exchange resource mailboxes
$CloudOnlyExchangeResourceMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Resources MBX" $CloudOnlyExchangeResourceMailboxes

# On-Prem exchange resource mailboxes
$OnPremExchangeResourceMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Resources MBX" $OnPremExchangeResourceMailboxes

## Azure Groups ##
Write-Host
Write-Host -ForegroundColor Yellow 'Getting all Azure AD groups...' -NoNewline
$AllGroups = Get-IAAzureADGroupsAsList
Write-Host -ForegroundColor Yellow "completed ($($AllGroups.Count) objects)"
Write-Host

# Microsoft 365 Groups (cloud is implicit)
$Microsoft365Groups = $AllGroups | Where-Object { $_.Type -contains 'Microsoft 365' }
ProcessResult "AAD Groups M365" $Microsoft365Groups

# Cloud Security
$CloudSecurityGroups = $AllGroups | Where-Object { $_.Type -contains 'Security' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Groups SEC" $CloudSecurityGroups

# On-Prem Security
$CloudSecurityGroups = $AllGroups | Where-Object { $_.Type -contains 'Security' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Groups SEC" $CloudSecurityGroups

# Cloud Mail-Enabled Security
$CloudMailEnabledSecurity = $AllGroups | Where-Object { $_.Type -contains 'Mail-Enabled Security' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Groups MESEC" $CloudMailEnabledSecurity

# On-Prem Mail-Enabled Security
$CloudMailEnabledSecurity = $AllGroups | Where-Object { $_.Type -contains 'Mail-Enabled Security' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Groups MESEC" $CloudMailEnabledSecurity

# Cloud Distribution
$CloudDistribution = $AllGroups | Where-Object { $_.Type -contains 'Distribution' -and $_.OnPremisesSyncEnabled -eq $false }
ProcessResult "AAD Groups DIST" $CloudDistribution

# On-Prem Distribution
$CloudDistribution = $AllGroups | Where-Object { $_.Type -contains 'Distribution' -and $_.OnPremisesSyncEnabled -eq $true }
ProcessResult "AD Groups DIST" $CloudDistribution

Write-Host
Write-Host -ForegroundColor Yellow "All tasks completed."
