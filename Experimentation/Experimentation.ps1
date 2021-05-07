Import-Module ..\IA.psd1 -Force

# On-Prem User Mailboxes
Write-Host -ForegroundColor Yellow 'Getting all users synced from on-premise with mailboxes...' -NoNewline
$OnPremUsersWithMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $true }
Write-Host -ForegroundColor Yellow "Done! ($($OnPremUsersWithMailboxes.Count) objects were returned)"
$FileName = "Ids_USR_Prem_and_MBX_$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
Write-Host -ForegroundColor Yellow "Exporting to $Filename..." -NoNewline
$OnPremUsersWithMailboxes | ForEach-Object {
    $_ | Select-Object ObjectId
} | Export-Csv $FileName -NoTypeInformation
Write-Host -ForegroundColor Yellow 'Done!'

# Cloud User Mailboxes
Write-Host -ForegroundColor Yellow 'Getting all cloud-only users with mailboxes...' -NoNewline
$CloudOnlyUsersWithMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $false }
Write-Host -ForegroundColor Yellow "Done! ($($CloudOnlyUsersWithMailboxes.Count) objects were returned)"
$FileName = "Ids_USR_Cloud_and_MBX_$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
Write-Host -ForegroundColor Yellow "Exporting to $Filename..." -NoNewline
$CloudOnlyUsersWithMailboxes | ForEach-Object {
    $_ | Select-Object ObjectId
} | Export-Csv $FileName -NoTypeInformation
Write-Host -ForegroundColor Yellow 'Done!'

# Cloud Exchange Resource Mailboxes
Write-Host -ForegroundColor Yellow 'Getting all cloud-only exchange resource mailboxes...' -NoNewline
$CloudOnlyExchangeResourceMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $false }
Write-Host -ForegroundColor Yellow "Done! ($($CloudOnlyExchangeResourceMailboxes.Count) objects were returned)"
$FileName = "Ids_RES_Cloud_MBX_$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
Write-Host -ForegroundColor Yellow "Exporting to $Filename..." -NoNewline
$CloudOnlyExchangeResourceMailboxes | ForEach-Object {
    $_ | Select-Object ObjectId
} | Export-Csv $FileName -NoTypeInformation
Write-Host -ForegroundColor Yellow 'Done!'

# On-Prem Exchange Resource Mailboxes
Write-Host -ForegroundColor Yellow 'Getting all on-prem exchange resource mailboxes...' -NoNewline
$OnPremExchangeResourceMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'Exchange' -and $_.OnPremisesSyncEnabled -eq $true }
Write-Host -ForegroundColor Yellow "Done! ($($OnPremExchangeResourceMailboxes.Count) objects were returned)"
$FileName = "Ids_RES_Prem_MBX_$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
Write-Host -ForegroundColor Yellow "Exporting to $Filename..." -NoNewline
$OnPremExchangeResourceMailboxes | ForEach-Object {
    $_ | Select-Object ObjectId
} | Export-Csv $FileName -NoTypeInformation
Write-Host -ForegroundColor Yellow 'Done!'